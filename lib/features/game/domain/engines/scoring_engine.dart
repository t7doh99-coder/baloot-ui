import '../../../../data/models/card_model.dart';
import '../../../../data/models/round_state_model.dart';

/// Result of scoring a completed round.
class RoundScoreResult {
  final int teamAPoints; // Scoreboard points awarded
  final int teamBPoints;
  final int teamARawAbnat;
  final int teamBRawAbnat;
  final bool isKhams; // Buyer's team lost
  final bool isKabout; // One team swept all 8 tricks
  final String winningTeam; // 'A' or 'B'
  final String? reason; // e.g. 'khams', 'kabout', 'normal'

  const RoundScoreResult({
    required this.teamAPoints,
    required this.teamBPoints,
    required this.teamARawAbnat,
    required this.teamBRawAbnat,
    required this.isKhams,
    required this.isKabout,
    required this.winningTeam,
    this.reason,
  });
}

/// Pure scoring math per BALOOT_RULES.md Section 8.
///
/// Handles:
/// - Raw Abnat → scoreboard point conversion
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
      return (abnat / 10).round() * 2;
    }
    // Hakam: Jawaker rounding — .5 rounds DOWN, .6+ rounds UP
    return _jawakerRound(abnat / 10);
  }

  /// Jawaker-style rounding: exactly .5 rounds DOWN, .6+ rounds UP.
  /// 15.5 → 15, 15.6 → 16
  int _jawakerRound(double value) {
    final fractional = value - value.truncate();
    // Use a small epsilon for floating point comparison
    if ((fractional - 0.5).abs() < 0.0001) {
      return value.truncate(); // .5 rounds DOWN
    }
    return value.round(); // standard rounding for everything else
  }

  /// Calculate the full round score.
  ///
  /// [teamAAbnat], [teamBAbnat]: raw Abnat from tricks (including last trick bonus).
  /// [mode]: Sun or Hakam.
  /// [buyerTeam]: 'A' or 'B'.
  /// [teamAProjectAbnat], [teamBProjectAbnat]: Abnat from projects.
  /// [teamAProjectScoreboard], [teamBProjectScoreboard]: scoreboard pts from projects.
  /// [balootPoints]: Baloot scoreboard pts (always 2, immune to doubling).
  /// [balootTeam]: which team has Baloot ('A', 'B', or null).
  /// [doubleStatus]: current double level.
  /// [isKabout]: whether one team swept all 8 tricks.
  /// [buyerCardIsAce]: for Kabout Ace bonus (88 pts).
  /// [projectWinningTeam]: which team's projects count ('A', 'B', or null).
  /// [doubleCallerTeam]: which team called the double (for tie-breaker).
  RoundScoreResult calculateRoundScore({
    required int teamAAbnat,
    required int teamBAbnat,
    required GameMode mode,
    required String buyerTeam,
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
    // Add project Abnat to the winning team
    int aAbnat = teamAAbnat;
    int bAbnat = teamBAbnat;

    if (projectWinningTeam == 'A') {
      aAbnat += teamAProjectAbnat;
    } else if (projectWinningTeam == 'B') {
      bAbnat += teamBProjectAbnat;
    }

    // --- Kabout check ---
    if (isKabout) {
      return _scoreKabout(
        teamAAbnat: aAbnat,
        teamBAbnat: bAbnat,
        buyerCardIsAce: buyerCardIsAce,
        teamATricksWon: aAbnat > 0 ? 8 : 0,
        teamBTricksWon: bAbnat > 0 ? 8 : 0,
      );
    }

    // --- Determine round winner ---
    final threshold = mode == GameMode.sun ? 65 : 81;
    final buyerAbnat = buyerTeam == 'A' ? aAbnat : bAbnat;
    final defenderAbnat = buyerTeam == 'A' ? bAbnat : aAbnat;

    // Double tie-breaker: double caller loses on exact tie
    bool buyerWins;
    if (doubleStatus != DoubleStatus.none && buyerAbnat == defenderAbnat) {
      // Tie with double active → double caller loses
      buyerWins = doubleCallerTeam != buyerTeam;
    } else {
      buyerWins = buyerAbnat > threshold;
    }

    // --- Khams (buyer loses) ---
    if (!buyerWins) {
      return _scoreKhams(
        mode: mode,
        buyerTeam: buyerTeam,
        teamAAbnat: aAbnat,
        teamBAbnat: bAbnat,
        doubleStatus: doubleStatus,
        projectWinningTeam: projectWinningTeam,
        teamAProjectScoreboard: teamAProjectScoreboard,
        teamBProjectScoreboard: teamBProjectScoreboard,
        balootPoints: balootPoints,
        balootTeam: balootTeam,
      );
    }

    // --- Normal scoring (buyer wins) ---
    return _scoreNormal(
      mode: mode,
      buyerTeam: buyerTeam,
      teamAAbnat: aAbnat,
      teamBAbnat: bAbnat,
      doubleStatus: doubleStatus,
      projectWinningTeam: projectWinningTeam,
      teamAProjectScoreboard: teamAProjectScoreboard,
      teamBProjectScoreboard: teamBProjectScoreboard,
      balootPoints: balootPoints,
      balootTeam: balootTeam,
    );
  }

  RoundScoreResult _scoreKabout({
    required int teamAAbnat,
    required int teamBAbnat,
    required bool buyerCardIsAce,
    required int teamATricksWon,
    required int teamBTricksWon,
  }) {
    final kaboutPts = buyerCardIsAce ? 88 : 44;
    final winnerIsA = teamATricksWon == 8;

    return RoundScoreResult(
      teamAPoints: winnerIsA ? kaboutPts : 0,
      teamBPoints: winnerIsA ? 0 : kaboutPts,
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
    String? projectWinningTeam,
    int teamAProjectScoreboard = 0,
    int teamBProjectScoreboard = 0,
    int balootPoints = 0,
    String? balootTeam,
  }) {
    final defenderTeam = buyerTeam == 'A' ? 'B' : 'A';
    int defenderPts;
    int buyerPts = 0;

    if (doubleStatus != DoubleStatus.none) {
      // With double active: defender gets base double value
      defenderPts = _doubleBaseValue(doubleStatus);
    } else {
      defenderPts = mode == GameMode.sun ? 26 : 16;
    }

    // Add project scoreboard points to winning project team
    int aBonus = 0, bBonus = 0;
    if (projectWinningTeam != null) {
      final multiplier = _doubleMultiplier(doubleStatus);
      if (projectWinningTeam == 'A') {
        aBonus = teamAProjectScoreboard * multiplier;
      } else {
        bBonus = teamBProjectScoreboard * multiplier;
      }
    }

    // Baloot (immune to multiplier)
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
      // With double: winner gets base value, loser gets 0
      final basePts = _doubleBaseValue(doubleStatus);
      aPts = buyerTeam == 'A' ? basePts : 0;
      bPts = buyerTeam == 'B' ? basePts : 0;
    } else {
      // Normal: convert Abnat to scoreboard for both teams
      aPts = abnatToScoreboard(teamAAbnat, mode);
      bPts = abnatToScoreboard(teamBAbnat, mode);
    }

    // Add project points
    final multiplier = _doubleMultiplier(doubleStatus);
    if (projectWinningTeam == 'A') {
      aPts += teamAProjectScoreboard * multiplier;
    } else if (projectWinningTeam == 'B') {
      bPts += teamBProjectScoreboard * multiplier;
    }

    // Baloot (always 2, never multiplied)
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

  int _doubleBaseValue(DoubleStatus status) {
    switch (status) {
      case DoubleStatus.none:
        return 0;
      case DoubleStatus.doubled:
        return 32;
      case DoubleStatus.tripled:
        return 40;
      case DoubleStatus.four:
        return 48;
      case DoubleStatus.gahwa:
        return 0; // Gahwa = instant game win, no point value
    }
  }

  int _doubleMultiplier(DoubleStatus status) {
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

  /// Check if the game has ended (152 scoreboard points or Gahwa).
  bool isGameOver(int teamATotal, int teamBTotal, DoubleStatus lastDouble) {
    if (lastDouble == DoubleStatus.gahwa) return true;
    return teamATotal >= 152 || teamBTotal >= 152;
  }

  /// Which team won the game. Returns 'A', 'B', or null if not over.
  String? gameWinner(int teamATotal, int teamBTotal, DoubleStatus lastDouble) {
    if (!isGameOver(teamATotal, teamBTotal, lastDouble)) return null;
    if (lastDouble == DoubleStatus.gahwa) {
      // Gahwa: the team that called it wins (handled externally)
      return null; // caller must determine
    }
    if (teamATotal >= 152 && teamBTotal >= 152) {
      // Both crossed — higher score wins
      return teamATotal >= teamBTotal ? 'A' : 'B';
    }
    if (teamATotal >= 152) return 'A';
    if (teamBTotal >= 152) return 'B';
    return null;
  }
}
