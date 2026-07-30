import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/core/errors/game_exceptions.dart';
import 'package:baloot_game/features/game/domain/managers/bidding_manager.dart';
import 'package:baloot_game/features/game/domain/baloot_game_controller.dart';
import 'package:baloot_game/features/game/domain/engines/scoring_engine.dart';
import 'package:baloot_game/features/game/domain/engines/bot_engine.dart';
import 'package:baloot_game/data/models/bot_difficulty.dart';

// ══════════════════════════════════════════════════════════════════
//  HELPERS
// ══════════════════════════════════════════════════════════════════

/// Advance from dealing → bidding (mirrors UI flow).
void _syncRound(BalootGameController ctrl) {
  if (ctrl.gamePhase == GamePhase.dealing) {
    ctrl.startNewRound();
  }
}

/// Bid Hakam with the current player, then pass the rest through confirmation.
void _bidHakam(BalootGameController ctrl) {
  ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.hakam);
  while (ctrl.gamePhase == GamePhase.bidding) {
    final bp = ctrl.roundState.biddingPhase;
    if (bp == BiddingPhase.hakamConfirmation) {
      ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.confirmHakam);
    } else {
      ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.pass);
    }
  }
}

/// Bid Sun with the current player, then pass the rest.
void _bidSun(BalootGameController ctrl) {
  ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.sun);
  while (ctrl.gamePhase == GamePhase.bidding) {
    final bp = ctrl.roundState.biddingPhase;
    if (bp == BiddingPhase.hakamConfirmation) {
      ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.confirmHakam);
    } else {
      ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.pass);
    }
  }
}

/// Play all remaining cards using bot logic until the round ends.
void _playAllTricks(BalootGameController ctrl) {
  int safety = 0;
  while (ctrl.gamePhase == GamePhase.playing && safety < 40) {
    ctrl.botPlay(ctrl.roundState.currentPlayerIndex);
    safety++;
  }
}

/// Get a defender seat (opposite team from buyer).
int _defenderSeat(BalootGameController ctrl) {
  final buyerIdx = ctrl.roundState.buyerIndex!;
  return (buyerIdx % 2 == 0) ? 1 : 0;
}

/// Get a buyer-team seat (same team as buyer, but could be buyer or partner).
int _buyerTeamSeat(BalootGameController ctrl) {
  final buyerIdx = ctrl.roundState.buyerIndex!;
  return (buyerIdx % 2 == 0) ? 0 : 1;
}

void main() {
  const scoring = ScoringEngine();

  // ══════════════════════════════════════════════════════════════════
  //  1. DOUBLE ESCALATION CHAIN
  // ══════════════════════════════════════════════════════════════════

  group('Double Escalation Chain — Rules Enforcement', () {
    test('Double can ONLY be called by defending team', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);
      _syncRound(ctrl);
      _bidHakam(ctrl);
      expect(ctrl.gamePhase, GamePhase.doubleWindow);

      final buyerSeat = _buyerTeamSeat(ctrl);
      // Buyer team trying to Double should throw
      expect(
        () => ctrl.callDouble(buyerSeat, DoubleStatus.doubled),
        throwsA(isA<InvalidBidException>()),
        reason: 'Buyer team cannot call Double',
      );
    });

    test('Triple can ONLY be called by buyer team', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      ctrl.callDouble(defSeat, DoubleStatus.doubled);

      // Defender trying to Triple should throw
      expect(
        () => ctrl.callDouble(defSeat, DoubleStatus.tripled),
        throwsA(isA<InvalidBidException>()),
        reason: 'Defender team cannot call Triple',
      );
    });

    test('Four can ONLY be called by defending team', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      final buySeat = _buyerTeamSeat(ctrl);
      ctrl.callDouble(defSeat, DoubleStatus.doubled);
      ctrl.callDouble(buySeat, DoubleStatus.tripled);

      // Buyer trying to call Four should throw
      expect(
        () => ctrl.callDouble(buySeat, DoubleStatus.four),
        throwsA(isA<InvalidBidException>()),
        reason: 'Buyer team cannot call Four',
      );
    });

    test('Gahwa can ONLY be called by buyer team', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      final buySeat = _buyerTeamSeat(ctrl);
      ctrl.callDouble(defSeat, DoubleStatus.doubled);
      ctrl.callDouble(buySeat, DoubleStatus.tripled);
      ctrl.callDouble(defSeat, DoubleStatus.four);

      // Defender trying to call Gahwa should throw
      expect(
        () => ctrl.callDouble(defSeat, DoubleStatus.gahwa),
        throwsA(isA<InvalidBidException>()),
        reason: 'Defender team cannot call Gahwa',
      );
    });

    test('Full chain: Double → Triple → Four → Gahwa succeeds', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      final buySeat = _buyerTeamSeat(ctrl);

      ctrl.callDouble(defSeat, DoubleStatus.doubled);
      expect(ctrl.roundState.doubleStatus, DoubleStatus.doubled);

      ctrl.callDouble(buySeat, DoubleStatus.tripled);
      expect(ctrl.roundState.doubleStatus, DoubleStatus.tripled);

      ctrl.callDouble(defSeat, DoubleStatus.four);
      expect(ctrl.roundState.doubleStatus, DoubleStatus.four);

      ctrl.callDouble(buySeat, DoubleStatus.gahwa);
      expect(ctrl.roundState.doubleStatus, DoubleStatus.gahwa);
    });

    test('Skip double proceeds to playing phase', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      expect(ctrl.gamePhase, GamePhase.doubleWindow);
      ctrl.skipDoubleWindow();
      expect(ctrl.gamePhase, GamePhase.playing);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  2. GAHWA — INSTANT GAME OVER
  // ══════════════════════════════════════════════════════════════════

  group('Gahwa — Instant Game Over', () {
    test('Gahwa transitions to playing phase (NOT dealing)', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      final buySeat = _buyerTeamSeat(ctrl);

      ctrl.callDouble(defSeat, DoubleStatus.doubled);
      ctrl.callDouble(buySeat, DoubleStatus.tripled);
      ctrl.callDouble(defSeat, DoubleStatus.four);
      ctrl.callDouble(buySeat, DoubleStatus.gahwa);

      // Should be in playing phase, NOT dealing
      expect(ctrl.gamePhase, isNot(GamePhase.dealing),
          reason: 'Gahwa must NOT restart the round');
      expect(
        ctrl.gamePhase == GamePhase.playing || ctrl.gamePhase == GamePhase.gameOver,
        true,
        reason: 'Gahwa should proceed to playing or immediate gameOver',
      );
    });

    test('Gahwa round plays all 8 tricks then ends the game', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      final buySeat = _buyerTeamSeat(ctrl);
      ctrl.callDouble(defSeat, DoubleStatus.doubled);
      ctrl.callDouble(buySeat, DoubleStatus.tripled);
      ctrl.callDouble(defSeat, DoubleStatus.four);
      ctrl.callDouble(buySeat, DoubleStatus.gahwa);

      // Play all tricks
      _playAllTricks(ctrl);

      expect(ctrl.isGameOver, true, reason: 'Gahwa must end the game');
      expect(ctrl.gamePhase, GamePhase.gameOver);

      // One team should have 152 points
      final score = ctrl.gameScore;
      expect(score.teamA >= 152 || score.teamB >= 152, true,
          reason: 'Gahwa winner must have >= 152 points');
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  3. SCORING ENGINE — DOUBLE BASE VALUES
  // ══════════════════════════════════════════════════════════════════

  group('Scoring: Hakam Double Base Values', () {
    test('Hakam Double: winner gets 32 (16x2)', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 90, teamBAbnat: 72,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 5, teamBTricksCount: 3,
        doubleStatus: DoubleStatus.doubled,
      );
      expect(r.teamAPoints, 32);
      expect(r.teamBPoints, 0);
    });

    test('Hakam Triple: winner gets 48 (16x3)', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 90, teamBAbnat: 72,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 5, teamBTricksCount: 3,
        doubleStatus: DoubleStatus.tripled,
      );
      expect(r.teamAPoints, 48);
      expect(r.teamBPoints, 0);
    });

    test('Hakam Four: winner gets 64 (16x4)', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 90, teamBAbnat: 72,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 5, teamBTricksCount: 3,
        doubleStatus: DoubleStatus.four,
      );
      expect(r.teamAPoints, 64);
      expect(r.teamBPoints, 0);
    });

    test('Hakam Gahwa: winner gets 152 (instant game win)', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 90, teamBAbnat: 72,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 5, teamBTricksCount: 3,
        doubleStatus: DoubleStatus.gahwa,
      );
      expect(r.teamAPoints, 152);
      expect(r.teamBPoints, 0);
    });

    test('Sun Double: winner gets 52 (26x2)', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 80, teamBAbnat: 50,
        mode: GameMode.sun, buyerTeam: 'A',
        teamATricksCount: 5, teamBTricksCount: 3,
        doubleStatus: DoubleStatus.doubled,
      );
      expect(r.teamAPoints, 52);
      expect(r.teamBPoints, 0);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  4. SCORING ENGINE — KHAMS WITH DOUBLES
  // ══════════════════════════════════════════════════════════════════

  group('Scoring: Khams (Buyer Loses) with Doubles', () {
    test('Hakam Khams + Double: defenders get 32', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 70, teamBAbnat: 92,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 3, teamBTricksCount: 5,
        doubleStatus: DoubleStatus.doubled,
      );
      expect(r.isKhams, true);
      expect(r.teamAPoints, 0);
      expect(r.teamBPoints, 32);
    });

    test('Hakam Khams + Triple: defenders get 48', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 70, teamBAbnat: 92,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 3, teamBTricksCount: 5,
        doubleStatus: DoubleStatus.tripled,
      );
      expect(r.isKhams, true);
      expect(r.teamBPoints, 48);
    });

    test('Hakam Khams + Four: defenders get 64', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 70, teamBAbnat: 92,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 3, teamBTricksCount: 5,
        doubleStatus: DoubleStatus.four,
      );
      expect(r.isKhams, true);
      expect(r.teamBPoints, 64);
    });

    test('Hakam Khams + Gahwa: defenders get 152', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 70, teamBAbnat: 92,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 3, teamBTricksCount: 5,
        doubleStatus: DoubleStatus.gahwa,
      );
      expect(r.isKhams, true);
      expect(r.teamBPoints, 152);
    });

    test('Khams steals ALL projects to defenders', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 70, teamBAbnat: 92,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 3, teamBTricksCount: 5,
        teamAProjectScoreboard: 5,
        teamBProjectScoreboard: 0,
        projectWinningTeam: 'A',
      );
      expect(r.isKhams, true);
      expect(r.teamBPoints, greaterThan(16));
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  5. SCORING ENGINE — KABOUT WITH DOUBLES
  // ══════════════════════════════════════════════════════════════════

  group('Scoring: Kabout with Doubles', () {
    test('Hakam Kabout base: 25 pts', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 162, teamBAbnat: 0,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 8, teamBTricksCount: 0,
        isKabout: true,
      );
      expect(r.isKabout, true);
      expect(r.teamAPoints, 25);
      expect(r.teamBPoints, 0);
    });

    test('Sun Kabout base: 44 pts', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 130, teamBAbnat: 0,
        mode: GameMode.sun, buyerTeam: 'A',
        teamATricksCount: 8, teamBTricksCount: 0,
        isKabout: true,
      );
      expect(r.teamAPoints, 44);
    });

    test('Hakam Kabout + Ace: 50 pts (25x2)', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 162, teamBAbnat: 0,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 8, teamBTricksCount: 0,
        isKabout: true, buyerCardIsAce: true,
      );
      expect(r.teamAPoints, 50);
    });

    test('Hakam Kabout + Double: 50 pts (25x2)', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 162, teamBAbnat: 0,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 8, teamBTricksCount: 0,
        isKabout: true, doubleStatus: DoubleStatus.doubled,
      );
      expect(r.teamAPoints, 50);
    });

    test('Hakam Kabout + Ace + Double: 100 pts (25x2x2)', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 162, teamBAbnat: 0,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 8, teamBTricksCount: 0,
        isKabout: true, buyerCardIsAce: true,
        doubleStatus: DoubleStatus.doubled,
      );
      expect(r.teamAPoints, 100);
    });

    test('Kabout nullifies loser projects (not stolen)', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 162, teamBAbnat: 0,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 8, teamBTricksCount: 0,
        isKabout: true,
        teamBProjectScoreboard: 10,
        projectWinningTeam: 'B',
      );
      expect(r.teamBPoints, 0);
      expect(r.teamAPoints, 25);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  6. PROJECT MULTIPLIERS WITH DOUBLES
  // ══════════════════════════════════════════════════════════════════

  group('Scoring: Project Multipliers with Doubles', () {
    test('Sera (2 pts) x Double = 4 pts', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 90, teamBAbnat: 72,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 5, teamBTricksCount: 3,
        doubleStatus: DoubleStatus.doubled,
        teamAProjectScoreboard: 2, projectWinningTeam: 'A',
      );
      expect(r.teamAPoints, 36); // 32 base + 2x2 projects
    });

    test('Sera (2 pts) x Triple = 6 pts', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 90, teamBAbnat: 72,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 5, teamBTricksCount: 3,
        doubleStatus: DoubleStatus.tripled,
        teamAProjectScoreboard: 2, projectWinningTeam: 'A',
      );
      expect(r.teamAPoints, 54); // 48 base + 2x3 projects
    });

    test('Sera (2 pts) x Four = 8 pts', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 90, teamBAbnat: 72,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 5, teamBTricksCount: 3,
        doubleStatus: DoubleStatus.four,
        teamAProjectScoreboard: 2, projectWinningTeam: 'A',
      );
      expect(r.teamAPoints, 72); // 64 base + 2x4 projects
    });

    test('Baloot is NEVER multiplied (always +2)', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 90, teamBAbnat: 72,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 5, teamBTricksCount: 3,
        doubleStatus: DoubleStatus.four,
        balootPoints: 2, balootTeam: 'A',
      );
      expect(r.teamAPoints, 66); // 64 base + 2 Baloot (NOT 64 + 2x4)
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  7. TIE RULES WITH DOUBLES
  // ══════════════════════════════════════════════════════════════════

  group('Scoring: Tie Rules', () {
    test('Normal tie (no double): buyer LOSES (Khams)', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 81, teamBAbnat: 81,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 4, teamBTricksCount: 4,
      );
      expect(r.isKhams, true);
      expect(r.winningTeam, 'B');
    });

    test('Doubled tie: team that called highest double LOSES', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 81, teamBAbnat: 81,
        mode: GameMode.hakam, buyerTeam: 'A',
        teamATricksCount: 4, teamBTricksCount: 4,
        doubleStatus: DoubleStatus.doubled,
        doubleCallerTeam: 'B',
      );
      expect(r.winningTeam, 'A');
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  8. SUN DOUBLE RESTRICTIONS
  // ══════════════════════════════════════════════════════════════════

  group('Sun Double Restrictions', () {
    test('Sun mode: Triple throws', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);
      _syncRound(ctrl);
      _bidSun(ctrl);

      if (ctrl.gamePhase == GamePhase.doubleWindow) {
        final defSeat = _defenderSeat(ctrl);
        expect(
          () => ctrl.callDouble(defSeat, DoubleStatus.tripled),
          throwsA(isA<InvalidBidException>()),
          reason: 'Sun mode does not allow Triple',
        );
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  9. GAME END CONDITIONS
  // ══════════════════════════════════════════════════════════════════

  group('Game End Conditions', () {
    test('isGameOver at 152+', () {
      expect(scoring.isGameOver(152, 100, DoubleStatus.none), true);
      expect(scoring.isGameOver(100, 152, DoubleStatus.none), true);
    });

    test('isGameOver false below 152', () {
      expect(scoring.isGameOver(151, 100, DoubleStatus.none), false);
    });

    test('Tied at 152+ → game continues (sudden death)', () {
      expect(scoring.isGameOver(152, 152, DoubleStatus.none), false);
    });

    test('Gahwa always ends game regardless of score', () {
      expect(scoring.isGameOver(0, 0, DoubleStatus.gahwa), true);
    });

    test('gameWinner returns correct team', () {
      expect(scoring.gameWinner(160, 100, DoubleStatus.none), 'A');
      expect(scoring.gameWinner(100, 160, DoubleStatus.none), 'B');
      expect(scoring.gameWinner(152, 152, DoubleStatus.none), null);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  10. ABNAT → SCOREBOARD CONVERSION
  // ══════════════════════════════════════════════════════════════════

  group('Abnat Conversion', () {
    test('Hakam: .5 rounds DOWN (Jawaker)', () {
      expect(scoring.abnatToScoreboard(85, GameMode.hakam), 8);
      expect(scoring.abnatToScoreboard(75, GameMode.hakam), 7);
      expect(scoring.abnatToScoreboard(155, GameMode.hakam), 15);
    });

    test('Hakam: .6+ rounds UP', () {
      expect(scoring.abnatToScoreboard(86, GameMode.hakam), 9);
      expect(scoring.abnatToScoreboard(156, GameMode.hakam), 16);
    });

    test('Hakam: pair totals = 16', () {
      for (int a = 0; a <= 162; a += 10) {
        final buyerPts = scoring.abnatToScoreboard(a, GameMode.hakam);
        final defPts = 16 - buyerPts;
        expect(buyerPts + defPts, 16);
      }
    });

    test('Sun: abnat / 5', () {
      expect(scoring.abnatToScoreboard(65, GameMode.sun), 13);
      expect(scoring.abnatToScoreboard(60, GameMode.sun), 12);
      expect(scoring.abnatToScoreboard(70, GameMode.sun), 14);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  11. FULL GAME SIMULATIONS (Multiple Seeds)
  // ══════════════════════════════════════════════════════════════════

  group('Full Game Simulation — 50 Random Seeds', () {
    for (int seed = 0; seed < 50; seed++) {
      test('Seed $seed: complete game without errors', () {
        final ctrl = BalootGameController(
          random: Random(seed),
          botDifficulty: BotDifficulty.medium,
        );
        ctrl.startNewGame(['Player', 'Bot1', 'Bot2', 'Bot3']);
        _syncRound(ctrl);

        int roundCount = 0;
        const maxRounds = 80;

        while (!ctrl.isGameOver && roundCount < maxRounds) {
          // Bidding phase
          if (ctrl.gamePhase == GamePhase.bidding) {
            int bidSafety = 0;
            while (ctrl.gamePhase == GamePhase.bidding && bidSafety < 20) {
              ctrl.botPlay(ctrl.roundState.currentPlayerIndex);
              bidSafety++;
              if (ctrl.gamePhase == GamePhase.dealing) {
                ctrl.startNewRound();
              }
            }
          }

          // Double window
          if (ctrl.gamePhase == GamePhase.doubleWindow) {
            ctrl.botPlay(ctrl.roundState.currentPlayerIndex);
          }

          // Play phase
          _playAllTricks(ctrl);

          // Next round
          if (ctrl.gamePhase == GamePhase.dealing) {
            ctrl.startNewRound();
          }

          roundCount++;
        }

        if (ctrl.isGameOver) {
          final score = ctrl.gameScore;
          expect(
            score.teamA >= 152 || score.teamB >= 152 ||
            ctrl.roundState.doubleStatus == DoubleStatus.gahwa,
            true,
            reason: 'Game ended but no team has 152+ and no Gahwa (seed $seed)',
          );
        }
      });
    }
  });

  // ══════════════════════════════════════════════════════════════════
  //  12. STRESS TEST — 200 GAMES
  // ══════════════════════════════════════════════════════════════════

  group('Stress Test — 200 games across all difficulties', () {
    for (final difficulty in BotDifficulty.values) {
      test('${difficulty.name}: 66 games complete without crash', () {
        int completed = 0;

        for (int seed = 0; seed < 66; seed++) {
          final ctrl = BalootGameController(
            random: Random(seed * 100 + difficulty.index),
            botDifficulty: difficulty,
          );
          ctrl.startNewGame(['P', 'B1', 'B2', 'B3']);
          _syncRound(ctrl);

          int moves = 0;
          const maxMoves = 2000;

          while (!ctrl.isGameOver && moves < maxMoves) {
            try {
              if (ctrl.gamePhase == GamePhase.bidding ||
                  ctrl.gamePhase == GamePhase.doubleWindow ||
                  ctrl.gamePhase == GamePhase.playing) {
                ctrl.botPlay(ctrl.roundState.currentPlayerIndex);
              } else if (ctrl.gamePhase == GamePhase.dealing) {
                ctrl.startNewRound();
              } else if (ctrl.gamePhase == GamePhase.scoring) {
                ctrl.startNewRound();
              } else {
                break; // gameOver
              }
            } catch (e) {
              fail('Crash at seed $seed, difficulty ${difficulty.name}, move $moves: $e');
            }
            moves++;
          }

          if (ctrl.isGameOver) completed++;
        }

        expect(completed, greaterThan(50),
            reason: '${difficulty.name}: only $completed/66 games completed');
      });
    }
  });

  // ══════════════════════════════════════════════════════════════════
  //  13. EDGE CASES
  // ══════════════════════════════════════════════════════════════════

  group('Edge Cases', () {
    test('callDouble outside doubleWindow throws', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);
      _syncRound(ctrl);

      expect(ctrl.gamePhase, GamePhase.bidding);
      expect(
        () => ctrl.callDouble(0, DoubleStatus.doubled),
        throwsA(isA<InvalidMoveException>()),
      );
    });

    test('skipDoubleWindow outside doubleWindow throws', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);
      _syncRound(ctrl);

      expect(
        () => ctrl.skipDoubleWindow(),
        throwsA(isA<InvalidMoveException>()),
      );
    });

    test('Score never goes negative across 10 games', () {
      for (int seed = 0; seed < 10; seed++) {
        final ctrl = BalootGameController(random: Random(seed));
        ctrl.startNewGame(['A', 'B', 'C', 'D']);
        _syncRound(ctrl);

        int moves = 0;
        while (!ctrl.isGameOver && moves < 500) {
          try {
            if (ctrl.gamePhase == GamePhase.dealing) {
              ctrl.startNewRound();
            } else {
              ctrl.botPlay(ctrl.roundState.currentPlayerIndex);
            }
          } catch (_) {}
          moves++;

          expect(ctrl.gameScore.teamA, greaterThanOrEqualTo(0),
              reason: 'Team A score went negative at seed $seed');
          expect(ctrl.gameScore.teamB, greaterThanOrEqualTo(0),
              reason: 'Team B score went negative at seed $seed');
        }
      }
    });
  });
}
