import '../../../../data/models/card_model.dart';
import '../../../../data/models/round_state_model.dart';

/// Result of scoring a completed round, with full breakdown for overlay UI.
class RoundScoreResult {
  final int teamAPoints; // Scoreboard points awarded
  final int teamBPoints;
  final int teamARawAbnat; // Total Abnat (tricks + ground + projects)
  final int teamBRawAbnat;
  final bool isKhams;
  final bool isKabout;
  final String winningTeam; // 'A' or 'B'
  final String? reason; // 'khams', 'kabout', 'kabout_ace', 'normal'

  // Breakdown fields for Kamelna-style overlay
  final int teamATrickAbnat; // Card points from tricks only (no ground, no projects)
  final int teamBTrickAbnat;
  final String? lastTrickBonusTeam; // 'A', 'B', or null
  final int teamAProjectAbnat;
  final int teamBProjectAbnat;
  final GameMode mode;
  final String buyerTeam;
  final DoubleStatus doubleStatus;

  const RoundScoreResult({
    required this.teamAPoints,
    required this.teamBPoints,
    required this.teamARawAbnat,
    required this.teamBRawAbnat,
    required this.isKhams,
    required this.isKabout,
    required this.winningTeam,
    this.reason,
    this.teamATrickAbnat = 0,
    this.teamBTrickAbnat = 0,
    this.lastTrickBonusTeam,
    this.teamAProjectAbnat = 0,
    this.teamBProjectAbnat = 0,
    this.mode = GameMode.hakam,
    this.buyerTeam = 'A',
    this.doubleStatus = DoubleStatus.none,
  });
}

/// Pure scoring math per BALOOT_RULES.md Section 8.
///
/// Handles:
/// - Raw Abnat -> scoreboard point conversion
/// - Sun formula: round(abnat / 10) * 2
/// - Hakam formula: Jawaker rounding (.5 rounds DOWN)
/// - Khams (buyer loses), Kabout (all-trick sweep)
/// - Double system base values + project multipliers
/// - Game end check (152 points or Gahwa)
class ScoringEngine {
  const ScoringEngine();

  /// Convert raw Abnat to scoreboard points.
  ///
  /// Sun: round(abnat / 10) * 2
  /// Hakam: round(abnat / 10) with Jawaker rounding
  int abnatToScoreboard(int abnat, GameMode mode) {
    if (mode == GameMode.sun) {
      // Kammelna "5 Rule" for Sun:
      // If last digit is < 5: round down (64 -> 12)
      // If last digit is > 5: round up (66 -> 14)
      // If last digit is exactly 5: exact half (65 -> 13)
      if (abnat % 10 == 5) {
        return (abnat ~/ 10) * 2 + 1;
      }
      return (abnat / 10).round() * 2;
    }
    // Hakam: Jawaker rounding -- .5 rounds DOWN, .6+ rounds UP
    return _jawakerRound(abnat / 10);
  }

  /// Jawaker-style rounding: exactly .5 rounds DOWN, .6+ rounds UP.
  /// 15.5 -> 15, 15.6 -> 16
  int _jawakerRound(double value) {
    final fractional = value - value.truncate();
    if ((fractional - 0.5).abs() < 0.0001) {
      return value.truncate(); // .5 rounds DOWN
    }
    return value.round();
  }

  /// Calculate the full round score.
  ///
  /// [teamAAbnat], [teamBAbnat]: raw Abnat from tricks (including last trick bonus).
  /// [teamATricksCount], [teamBTricksCount]: actual trick win counts (for Kabout).
  /// [lastTrickBonusTeam]: which team won the last trick ('A', 'B', or null).
  RoundScoreResult calculateRoundScore({
    required int teamAAbnat,
    required int teamBAbnat,
    required GameMode mode,
    required String buyerTeam,
    required int teamATricksCount,
    required int teamBTricksCount,
    String? lastTrickBonusTeam,
    int teamAProjectAbnat = 0,
    int teamBProjectAbnat = 0,
    int teamAProjectScoreboard = 0,
    int teamBProjectScoreboard = 0,
    int balootPoints = 0,
    String? balootTeam,
    DoubleStatus doubleStatus = DoubleStatus.none,
    bool isKabout = false,
    bool buyerCardIsAce = false,
    String? projectWinningTeam,
    String? doubleCallerTeam,
  }) {
    // teamAAbnat / teamBAbnat are TRICK card points only (including ground).
    // Projects are handled separately via their own scoreboard point values.
    final trickAbnatA = teamAAbnat;
    final trickAbnatB = teamBAbnat;

    // Effective project Abnat (for scoreboard display only — NOT used in math)
    int effectiveProjectA = 0;
    int effectiveProjectB = 0;
    if (projectWinningTeam == 'A') {
      effectiveProjectA = teamAProjectAbnat;
    } else if (projectWinningTeam == 'B') {
      effectiveProjectB = teamBProjectAbnat;
    }

    // Shared breakdown context passed into sub-functions
    RoundScoreResult _withBreakdown(RoundScoreResult base) {
      int finalProjA = effectiveProjectA;
      int finalProjB = effectiveProjectB;

      // Rule 14.4: Stolen projects in Khams.
      // Update breakdown Abnat to match the stolen points logic in _scoreKhams.
      if (base.isKhams) {
        if (buyerTeam == 'A') {
          // Team A (Buyer) projects are stolen by Team B (Defenders)
          finalProjA = 0;
          finalProjB = teamBProjectAbnat + teamAProjectAbnat;
        } else {
          // Team B (Buyer) projects are stolen by Team A (Defenders)
          finalProjB = 0;
          finalProjA = teamAProjectAbnat + teamBProjectAbnat;
        }
      }

      return RoundScoreResult(
        teamAPoints: base.teamAPoints,
        teamBPoints: base.teamBPoints,
        teamARawAbnat: trickAbnatA,
        teamBRawAbnat: trickAbnatB,
        isKhams: base.isKhams,
        isKabout: base.isKabout,
        winningTeam: base.winningTeam,
        reason: base.reason,
        teamATrickAbnat: trickAbnatA,
        teamBTrickAbnat: trickAbnatB,
        lastTrickBonusTeam: lastTrickBonusTeam,
        teamAProjectAbnat: finalProjA,
        teamBProjectAbnat: finalProjB,
        mode: mode,
        buyerTeam: buyerTeam,
        doubleStatus: doubleStatus,
      );
    }

    // --- Kabout check (uses actual trick counts, not Abnat) ---
    if (isKabout) {
      return _withBreakdown(_scoreKabout(
        teamAAbnat: trickAbnatA,
        teamBAbnat: trickAbnatB,
        buyerCardIsAce: buyerCardIsAce,
        teamATricksWon: teamATricksCount,
        teamBTricksWon: teamBTricksCount,
        mode: mode,
        doubleStatus: doubleStatus,
        projectWinningTeam: projectWinningTeam,
        teamAProjectScoreboard: teamAProjectScoreboard,
        teamBProjectScoreboard: teamBProjectScoreboard,
        balootPoints: balootPoints,
        balootTeam: balootTeam,
      ));
    }

    // --- Determine round winner (using TRICK Abnaat only, NOT projects) ---
    // Per Kammelna: Khams is decided by trick card points only.
    // Sun threshold: 65 (out of 130 total trick Abnaat)
    // Hakam threshold: 81 (out of 162 total trick Abnaat)
    final threshold = mode == GameMode.sun ? 65 : 81;
    final buyerTrickAbnat = buyerTeam == 'A' ? trickAbnatA : trickAbnatB;
    final defenderTrickAbnat = buyerTeam == 'A' ? trickAbnatB : trickAbnatA;

    bool buyerWins;
    if (doubleStatus != DoubleStatus.none && buyerTrickAbnat == defenderTrickAbnat) {
      buyerWins = doubleCallerTeam != buyerTeam;
    } else {
      buyerWins = buyerTrickAbnat > threshold;
    }

    // --- Khams (buyer loses) ---
    if (!buyerWins) {
      return _withBreakdown(_scoreKhams(
        mode: mode,
        buyerTeam: buyerTeam,
        teamAAbnat: trickAbnatA,
        teamBAbnat: trickAbnatB,
        doubleStatus: doubleStatus,
        teamAProjectScoreboard: teamAProjectScoreboard,
        teamBProjectScoreboard: teamBProjectScoreboard,
        balootPoints: balootPoints,
        balootTeam: balootTeam,
      ));
    }

    // --- Normal scoring (buyer wins) ---
    return _withBreakdown(_scoreNormal(
      mode: mode,
      buyerTeam: buyerTeam,
      teamAAbnat: trickAbnatA,
      teamBAbnat: trickAbnatB,
      doubleStatus: doubleStatus,
      projectWinningTeam: projectWinningTeam,
      teamAProjectScoreboard: teamAProjectScoreboard,
      teamBProjectScoreboard: teamBProjectScoreboard,
      balootPoints: balootPoints,
      balootTeam: balootTeam,
    ));
  }


  RoundScoreResult _scoreKabout({
    required int teamAAbnat,
    required int teamBAbnat,
    required bool buyerCardIsAce,
    required int teamATricksWon,
    required int teamBTricksWon,
    required GameMode mode,
    DoubleStatus doubleStatus = DoubleStatus.none,
    String? projectWinningTeam,
    int teamAProjectScoreboard = 0,
    int teamBProjectScoreboard = 0,
    int balootPoints = 0,
    String? balootTeam,
  }) {
    // Client / Jawaker-Kamelna: Sun Kabout = 44 + projects, Hakam Kabout = 25 + projects
    // Ace doubles the Kabout base. Double/Triple/Four multiplies the Kabout base.
    final baseKabout = mode == GameMode.hakam ? 25 : 44;
    final aceMultiplier = buyerCardIsAce ? 2 : 1;
    final doubleMultiplier = _cardDoubleMultiplier(doubleStatus);
    final kaboutPts = baseKabout * aceMultiplier * doubleMultiplier;
    final winnerIsA = teamATricksWon == 8;

    int aPts = winnerIsA ? kaboutPts : 0;
    int bPts = winnerIsA ? 0 : kaboutPts;

    // Project scoreboard points (Abnat conversion is skipped for Kabout; add explicitly)
    if (projectWinningTeam != null) {
      final pm = _projectMultiplier(doubleStatus);
      if (projectWinningTeam == 'A') {
        aPts += teamAProjectScoreboard * pm;
      } else {
        bPts += teamBProjectScoreboard * pm;
      }
    }
    if (balootTeam == 'A') aPts += balootPoints;
    if (balootTeam == 'B') bPts += balootPoints;

    return RoundScoreResult(
      teamAPoints: aPts,
      teamBPoints: bPts,
      teamARawAbnat: teamAAbnat,
      teamBRawAbnat: teamBAbnat,
      isKhams: false,
      isKabout: true,
      winningTeam: winnerIsA ? 'A' : 'B',
      reason: buyerCardIsAce ? 'kabout_ace' : 'kabout',
    );
  }

  RoundScoreResult _scoreKhams({
    required GameMode mode,
    required String buyerTeam,
    required int teamAAbnat,
    required int teamBAbnat,
    required DoubleStatus doubleStatus,
    int teamAProjectScoreboard = 0,
    int teamBProjectScoreboard = 0,
    int balootPoints = 0,
    String? balootTeam,
  }) {
    final defenderTeam = buyerTeam == 'A' ? 'B' : 'A';
    int defenderPts;

    if (doubleStatus != DoubleStatus.none) {
      defenderPts = _doubleBaseValue(doubleStatus, mode);
    } else {
      defenderPts = mode == GameMode.sun ? 26 : 16;
    }

    // Project stealing (BALOOT_RULES.md §14.4 — Kammelna):
    // Defenders get Khams base + the *buyer's team's* declared project scoreboard
    // points (not the abstract project-priority winner). Baloot is handled below
    // and is not stolen (exception in same section).
    int aBonus = 0, bBonus = 0;
    final multiplier = _projectMultiplier(doubleStatus);
    
    // Rule 14.4: Defenders get their OWN projects + the STOLEN projects from buyer.
    if (defenderTeam == 'A') {
      aBonus = (teamAProjectScoreboard + teamBProjectScoreboard) * multiplier;
    } else {
      bBonus = (teamBProjectScoreboard + teamAProjectScoreboard) * multiplier;
    }

    if (balootTeam == 'A') aBonus += balootPoints;
    if (balootTeam == 'B') bBonus += balootPoints;

    int aTotal = aBonus;
    int bTotal = bBonus;
    if (defenderTeam == 'A') {
      aTotal += defenderPts;
    } else {
      bTotal += defenderPts;
    }

    return RoundScoreResult(
      teamAPoints: aTotal,
      teamBPoints: bTotal,
      teamARawAbnat: teamAAbnat,
      teamBRawAbnat: teamBAbnat,
      isKhams: true,
      isKabout: false,
      winningTeam: defenderTeam,
      reason: 'khams',
    );
  }

  RoundScoreResult _scoreNormal({
    required GameMode mode,
    required String buyerTeam,
    required int teamAAbnat,
    required int teamBAbnat,
    required DoubleStatus doubleStatus,
    String? projectWinningTeam,
    int teamAProjectScoreboard = 0,
    int teamBProjectScoreboard = 0,
    int balootPoints = 0,
    String? balootTeam,
  }) {
    int aPts, bPts;

    if (doubleStatus != DoubleStatus.none) {
      // With double: winner gets base value, loser gets 0.
      // Project scoreboard pts added separately (Abnat conversion bypassed).
      final basePts = _doubleBaseValue(doubleStatus, mode);
      aPts = buyerTeam == 'A' ? basePts : 0;
      bPts = buyerTeam == 'B' ? basePts : 0;

      final multiplier = _projectMultiplier(doubleStatus);
      if (projectWinningTeam == 'A') {
        aPts += teamAProjectScoreboard * multiplier;
      } else if (projectWinningTeam == 'B') {
        bPts += teamBProjectScoreboard * multiplier;
      }
    } else {
      // No double: convert TRICK Abnaat to scoreboard points.
      // Per Kammelna: Sun always totals 26, Hakam always totals 16.
      // Compute Team A via formula, derive Team B as complement to
      // prevent rounding drift (matches client example: "opponents get 18" = 26−8).
      final modeTotal = mode == GameMode.sun ? 26 : 16;
      aPts = abnatToScoreboard(teamAAbnat, mode);
      bPts = modeTotal - aPts;

      // Add project scoreboard points for the winning team
      if (projectWinningTeam == 'A') {
        aPts += teamAProjectScoreboard;
      } else if (projectWinningTeam == 'B') {
        bPts += teamBProjectScoreboard;
      }
    }



    // Baloot is always 2 pts (never derived from Abnat, immune to doubling)
    if (balootTeam == 'A') aPts += balootPoints;
    if (balootTeam == 'B') bPts += balootPoints;

    return RoundScoreResult(
      teamAPoints: aPts,
      teamBPoints: bPts,
      teamARawAbnat: teamAAbnat,
      teamBRawAbnat: teamBAbnat,
      isKhams: false,
      isKabout: false,
      winningTeam: buyerTeam,
      reason: 'normal',
    );
  }

  /// Base round reward when Double is active.
  /// Jawaker/Kamelna: 16 × multiplier (32/48/64).
  int _doubleBaseValue(DoubleStatus status, GameMode mode) {
    if (status == DoubleStatus.none) return 0;
    if (mode == GameMode.sun) {
      // Sun Double is always 52 (26 * 2). No Triple/Four in Sun per Rule 7.1.
      return status == DoubleStatus.doubled ? 52 : 0;
    }
    // Hakam: 16 * multiplier (32/48/64)
    switch (status) {
      case DoubleStatus.doubled:
        return 32;
      case DoubleStatus.tripled:
        return 48;
      case DoubleStatus.four:
        return 64;
      case DoubleStatus.gahwa:
        return 0;
      default:
        return 0;
    }
  }

  /// Project multiplier: capped at ×2 per Jawaker/Kamelna/Tournament rules.
  /// Even in Triple/Four, projects are only doubled, never tripled/quadrupled.
  int _projectMultiplier(DoubleStatus status) {
    switch (status) {
      case DoubleStatus.none:
        return 1;
      case DoubleStatus.doubled:
      case DoubleStatus.tripled:
      case DoubleStatus.four:
        return 2;  // Capped at ×2
      case DoubleStatus.gahwa:
        return 1;
    }
  }

  /// Card point multiplier for Kabout calculation.
  int _cardDoubleMultiplier(DoubleStatus status) {
    switch (status) {
      case DoubleStatus.none:
        return 1;
      case DoubleStatus.doubled:
        return 2;
      case DoubleStatus.tripled:
        return 3;
      case DoubleStatus.four:
        return 4;
      case DoubleStatus.gahwa:
        return 1;
    }
  }

  bool isGameOver(int teamATotal, int teamBTotal, DoubleStatus lastDouble) {
    if (lastDouble == DoubleStatus.gahwa) return true;

    final reachedTarget = teamATotal >= 152 || teamBTotal >= 152;
    if (!reachedTarget) return false;

    // Sudden-Death Tie-Breaker (BALOOT_RULES.md Section 14.3):
    // If exact tie above target score, game continues.
    if (teamATotal == teamBTotal) return false;

    return true;
  }

  String? gameWinner(int teamATotal, int teamBTotal, DoubleStatus lastDouble) {
    if (!isGameOver(teamATotal, teamBTotal, lastDouble)) return null;

    if (lastDouble == DoubleStatus.gahwa) {
      // Caller must determine Gahwa winner based on who called it and if they won
      return null;
    }

    if (teamATotal > teamBTotal) return 'A';
    if (teamBTotal > teamATotal) return 'B';

    return null; // Should be unreachable due to isGameOver tie-check
  }

  /// Calculate score for a Qaid (Violation) penalty.
  /// Per BALOOT_RULES.md Section 14.5:
  /// Award Kabout score (44 Sun / 25 Hakam) + active project points to the winning team.
  RoundScoreResult calculateViolationScore({
    required GameMode mode,
    required String winningTeam,
    required DoubleStatus doubleStatus,
    int teamAProjectScoreboard = 0,
    int teamBProjectScoreboard = 0,
    int balootPoints = 0,
    String? balootTeam,
  }) {
    final baseKabout = mode == GameMode.hakam ? 25 : 44;
    final doubleMultiplier = _cardDoubleMultiplier(doubleStatus);
    final kaboutPts = baseKabout * doubleMultiplier;

    int aPts = winningTeam == 'A' ? kaboutPts : 0;
    int bPts = winningTeam == 'B' ? kaboutPts : 0;

    // Award winning team's projects (multiplied by x2 if doubled)
    final pm = _projectMultiplier(doubleStatus);
    if (winningTeam == 'A') {
      aPts += teamAProjectScoreboard * pm;
    } else {
      bPts += teamBProjectScoreboard * pm;
    }

    if (balootTeam == 'A') aPts += balootPoints;
    if (balootTeam == 'B') bPts += balootPoints;

    return RoundScoreResult(
      teamAPoints: aPts,
      teamBPoints: bPts,
      teamARawAbnat: 0,
      teamBRawAbnat: 0,
      isKhams: false,
      isKabout: true,
      winningTeam: winningTeam,
      reason: 'qaid_penalty',
    );
  }
}
