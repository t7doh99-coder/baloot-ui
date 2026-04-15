import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/engines/scoring_engine.dart';

void main() {
  const engine = ScoringEngine();

  group('Abnat to scoreboard conversion', () {
    group('Sun formula: round(abnat/10) * 2', () {
      test('88 Abnat → 18 pts (confirmed example)', () {
        expect(engine.abnatToScoreboard(88, GameMode.sun), 18);
      });

      test('42 Abnat → 8 pts (confirmed example)', () {
        expect(engine.abnatToScoreboard(42, GameMode.sun), 8);
      });

      test('65 Abnat → 14 pts', () {
        // 65/10 = 6.5 → rounds to 7 → 7*2 = 14
        expect(engine.abnatToScoreboard(65, GameMode.sun), 14);
      });

      test('Sun round totals = 26 (130 total abnat)', () {
        // 88 → 18, 42 → 8, total = 26
        final a = engine.abnatToScoreboard(88, GameMode.sun);
        final b = engine.abnatToScoreboard(42, GameMode.sun);
        expect(a + b, 26);
      });
    });

    group('Hakam formula: Jawaker rounding (.5 DOWN)', () {
      test('155 Abnat → 15 (15.5 rounds DOWN)', () {
        expect(engine.abnatToScoreboard(155, GameMode.hakam), 15);
      });

      test('156 Abnat → 16 (15.6 rounds UP)', () {
        expect(engine.abnatToScoreboard(156, GameMode.hakam), 16);
      });

      test('150 Abnat → 15 (exact)', () {
        expect(engine.abnatToScoreboard(150, GameMode.hakam), 15);
      });

      test('81 Abnat → 8 (8.1 → 8)', () {
        expect(engine.abnatToScoreboard(81, GameMode.hakam), 8);
      });

      test('85 Abnat → 8 (8.5 rounds DOWN per Jawaker)', () {
        expect(engine.abnatToScoreboard(85, GameMode.hakam), 8);
      });

      test('86 Abnat → 9 (8.6 rounds UP)', () {
        expect(engine.abnatToScoreboard(86, GameMode.hakam), 9);
      });
    });
  });

  group('Khams (buyer loses)', () {
    test('Sun Khams: defender gets 26, buyer gets 0', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 40, // buyer (Team A) failed to exceed 65
        teamBAbnat: 90,
        mode: GameMode.sun,
        buyerTeam: 'A',
        teamATricksCount: 3,
        teamBTricksCount: 5,
      );

      expect(result.isKhams, true);
      expect(result.teamAPoints, 0);
      expect(result.teamBPoints, 26);
      expect(result.winningTeam, 'B');
    });

    test('Hakam Khams: defender gets 16, buyer gets 0', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 70, // buyer (Team A) failed to exceed 81
        teamBAbnat: 92,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 3,
        teamBTricksCount: 5,
      );

      expect(result.isKhams, true);
      expect(result.teamAPoints, 0);
      expect(result.teamBPoints, 16);
    });
  });

  group('Kabout (all-tricks sweep)', () {
    test('Sun Kabout: winner gets 44', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 130,
        teamBAbnat: 0,
        mode: GameMode.sun,
        buyerTeam: 'A',
        teamATricksCount: 8,
        teamBTricksCount: 0,
        isKabout: true,
      );

      expect(result.isKabout, true);
      expect(result.teamAPoints, 44);
      expect(result.teamBPoints, 0);
    });

    test('Hakam Kabout: winner gets 25 (not 44)', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 162,
        teamBAbnat: 0,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 8,
        teamBTricksCount: 0,
        isKabout: true,
      );

      expect(result.isKabout, true);
      expect(result.teamAPoints, 25);
      expect(result.teamBPoints, 0);
    });

    test('Hakam Kabout with Ace buyer card: winner gets 50', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 162,
        teamBAbnat: 0,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 8,
        teamBTricksCount: 0,
        isKabout: true,
        buyerCardIsAce: true,
      );

      expect(result.isKabout, true);
      expect(result.teamAPoints, 50); // 25 × 2
      expect(result.teamBPoints, 0);
      expect(result.reason, 'kabout_ace');
    });

    test('Sun Kabout with Ace buyer card: winner gets 88', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 130,
        teamBAbnat: 0,
        mode: GameMode.sun,
        buyerTeam: 'A',
        teamATricksCount: 8,
        teamBTricksCount: 0,
        isKabout: true,
        buyerCardIsAce: true,
      );

      expect(result.isKabout, true);
      expect(result.teamAPoints, 88); // 44 × 2
      expect(result.teamBPoints, 0);
    });

    test('Hakam Kabout + Double: winner gets 50', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 162,
        teamBAbnat: 0,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 8,
        teamBTricksCount: 0,
        isKabout: true,
        doubleStatus: DoubleStatus.doubled,
      );

      expect(result.isKabout, true);
      expect(result.teamAPoints, 50); // 25 × 2
    });
  });

  group('Double system', () {
    test('Double: winner gets base 32 pts', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 100,
        teamBAbnat: 62,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.doubled,
      );

      expect(result.teamAPoints, 32);
      expect(result.teamBPoints, 0);
    });

    test('Double + Sera: 32 + (2*2) = 36 pts', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 100,
        teamBAbnat: 62,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.doubled,
        projectWinningTeam: 'A',
        teamAProjectScoreboard: 2, // Sera = 2 pts
      );

      expect(result.teamAPoints, 36); // 32 + 2*2
    });

    test('Double + Baloot: Baloot NOT multiplied', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 100,
        teamBAbnat: 62,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.doubled,
        balootPoints: 2,
        balootTeam: 'A',
      );

      expect(result.teamAPoints, 34); // 32 + 2 (Baloot not multiplied)
    });

    test('Triple: base 48 pts (16×3)', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 100,
        teamBAbnat: 62,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.tripled,
      );

      expect(result.teamAPoints, 48);
    });

    test('Four: base 64 pts (16×4)', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 100,
        teamBAbnat: 62,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.four,
      );

      expect(result.teamAPoints, 64);
    });

    test('Triple + Sera: project multiplier capped at ×2', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 100,
        teamBAbnat: 62,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.tripled,
        projectWinningTeam: 'A',
        teamAProjectScoreboard: 2, // Sera = 2 pts
      );

      // 48 (triple base) + 2×2 (project capped at ×2) = 52
      expect(result.teamAPoints, 52);
    });

    test('Tie with double: double caller loses (81 vs 81)', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 81,
        teamBAbnat: 81,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 4,
        teamBTricksCount: 4,
        doubleStatus: DoubleStatus.doubled,
        doubleCallerTeam: 'B', // Team B called double
      );

      // Team B called double and tied → Team B loses
      // So Team A (buyer) wins
      expect(result.winningTeam, 'A');
    });
  });

  group('Normal scoring', () {
    test('Sun normal: both teams get converted points', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 88,
        teamBAbnat: 42,
        mode: GameMode.sun,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
      );

      expect(result.teamAPoints, 18); // round(88/10)*2
      expect(result.teamBPoints, 8); // round(42/10)*2
      expect(result.isKhams, false);
    });
  });

  group('Game end detection', () {
    test('team reaches 152 → game over', () {
      expect(engine.isGameOver(152, 100, DoubleStatus.none), true);
      expect(engine.isGameOver(100, 152, DoubleStatus.none), true);
    });

    test('neither at 152 → not over', () {
      expect(engine.isGameOver(140, 100, DoubleStatus.none), false);
    });

    test('Gahwa → instant game over', () {
      expect(engine.isGameOver(50, 50, DoubleStatus.gahwa), true);
    });

    test('game winner: higher score when both cross 152', () {
      expect(engine.gameWinner(160, 155, DoubleStatus.none), 'A');
      expect(engine.gameWinner(155, 160, DoubleStatus.none), 'B');
    });
  });
}
