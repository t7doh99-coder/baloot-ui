import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/engines/scoring_engine.dart';

void main() {
  const engine = ScoringEngine();

  group('Phase 1: Hakam Mode - Normal Scoring (Buyer Wins)', () {
    test('1.1 Buyer Wins - No Projects, No Baloot', () {
      // Buyer A gets 85 abnat -> 8.5 -> rounds down to 8. Defender gets 16-8=8.
      final result = engine.calculateRoundScore(
        teamAAbnat: 85,
        teamBAbnat: 77, // 162 - 85 = 77
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
      );
      expect(result.teamAPoints, 8);
      expect(result.teamBPoints, 8);
      expect(result.winningTeam, 'A');
      expect(result.reason, 'normal');
    });

    test('1.2 Buyer Wins + Projects (Winning Team)', () {
      // Buyer A: 85 abnat -> 8 pts. Projects: Sera (2 pts). Total: 10.
      final result = engine.calculateRoundScore(
        teamAAbnat: 85,
        teamBAbnat: 77,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        teamAProjectScoreboard: 2, // Sera
        projectWinningTeam: 'A',
      );
      expect(result.teamAPoints, 10);
      expect(result.teamBPoints, 8);
    });

    test('1.3 Buyer Wins + Baloot (Buyer Has It)', () {
      // Buyer A: 85 abnat -> 8 pts. Baloot -> 2 pts. Total: 10.
      final result = engine.calculateRoundScore(
        teamAAbnat: 85,
        teamBAbnat: 77,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        balootPoints: 2,
        balootTeam: 'A',
      );
      expect(result.teamAPoints, 10);
      expect(result.teamBPoints, 8);
    });

    test('1.4 Buyer Wins + Baloot (Defender Has It)', () {
      // Buyer A needs to win EVEN WITH Defender B having 20 abnat from Baloot.
      // So A needs > 81 points. B has 20 from Baloot.
      // Let's give A: 105 abnat. B: 57 abnat.
      // Total A = 105. Total B = 57 + 20 (Baloot) = 77. A wins.
      final result = engine.calculateRoundScore(
        teamAAbnat: 105,
        teamBAbnat: 57,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        balootPoints: 2,
        balootTeam: 'B',
      );
      // A gets 105/10 = 10.5 -> 10 pts.
      // B gets 16 - 10 = 6 base + 2 Baloot = 8 pts.
      expect(result.teamAPoints, 10);
      expect(result.teamBPoints, 8); // 6 base + 2 Baloot
    });
  });

  group('Phase 2: Hakam Mode - Khams (Buyer Loses)', () {
    test('2.1 Khams - No Projects, No Baloot', () {
      // Buyer A gets 80 abnat -> 8 pts. Defender B gets 82 abnat -> 8 pts.
      // Buyer needs MORE than half. This is Khams!
      final result = engine.calculateRoundScore(
        teamAAbnat: 80,
        teamBAbnat: 82,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 4,
        teamBTricksCount: 4,
      );
      expect(result.isKhams, true);
      expect(result.teamAPoints, 0);
      expect(result.teamBPoints, 16);
      expect(result.winningTeam, 'B');
    });

    test('2.2 Khams - Buyer Had Projects (Stolen)', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 80,
        teamBAbnat: 82,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 4,
        teamBTricksCount: 4,
        teamAProjectScoreboard: 2, // Sera
        projectWinningTeam: 'A',
      );
      // Defender B steals Buyer's 2 points. B gets 16 + 2 = 18.
      expect(result.teamAPoints, 0);
      expect(result.teamBPoints, 18);
    });

    test('2.4 Khams - Buyer Had Baloot -> Transfers to Defender', () {
      // Buyer needs to lose EVEN WITH their 20 abnat from Baloot.
      // Total must be <= 81.
      // Let's give Buyer A: 50 trick abnat + 20 Baloot = 70.
      // Defender B: 112 trick abnat.
      final result = engine.calculateRoundScore(
        teamAAbnat: 50,
        teamBAbnat: 112,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 4,
        teamBTricksCount: 4,
        balootPoints: 2,
        balootTeam: 'A',
      );
      // Buyer A lost, Defender B gets 16 + 2 Baloot = 18.
      expect(result.teamAPoints, 0);
      expect(result.teamBPoints, 18);
    });

    test('2.6 Khams - Tie (Sawa Type 3)', () {
      // Equal abnat. Buyer loses.
      final result = engine.calculateRoundScore(
        teamAAbnat: 81,
        teamBAbnat: 81,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 4,
        teamBTricksCount: 4,
      );
      expect(result.isKhams, true);
      expect(result.teamBPoints, 16);
      expect(result.teamAPoints, 0);
    });

    test('2.7 Khams - Tie with Double Active', () {
      // If defender calls double, defender loses tie. Buyer wins.
      final result = engine.calculateRoundScore(
        teamAAbnat: 81,
        teamBAbnat: 81,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 4,
        teamBTricksCount: 4,
        doubleStatus: DoubleStatus.doubled,
        doubleCallerTeam: 'B', // Defender called
      );
      expect(result.isKhams, false);
      expect(result.winningTeam, 'A'); // Buyer wins tie
      expect(result.teamAPoints, 32); // 16 * 2
      expect(result.teamBPoints, 0);
    });
  });

  group('Phase 3: Hakam Mode - Kabout (All 8 Tricks)', () {
    test('3.1 Buyer Kabout', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 162,
        teamBAbnat: 0,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 8,
        teamBTricksCount: 0,
        isKabout: true,
      );
      expect(result.teamAPoints, 25);
      expect(result.teamBPoints, 0);
    });

    test('3.2 Defender Kabout + Baloot Transfer', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 0,
        teamBAbnat: 162,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 0,
        teamBTricksCount: 8,
        isKabout: true,
        balootPoints: 2,
        balootTeam: 'A', // Buyer had Baloot
      );
      // Defender Kabout: Base=25. Stolen Baloot=2. Total=27.
      expect(result.teamAPoints, 0);
      expect(result.teamBPoints, 27);
    });

    test('3.3 Kabout + Ace Buyer Card', () {
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
      expect(result.teamAPoints, 50); // 25 * 2
    });

    test('3.5 Kabout + Ace + Double', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 162,
        teamBAbnat: 0,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 8,
        teamBTricksCount: 0,
        isKabout: true,
        buyerCardIsAce: true,
        doubleStatus: DoubleStatus.doubled,
      );
      expect(result.teamAPoints, 100); // 25 * 2 * 2
    });
  });

  group('Phase 4: Sun Mode', () {
    test('4.1 Sun - Buyer Wins (abnat / 5 rounding)', () {
      // 65 abnat -> 13
      var result = engine.calculateRoundScore(
        teamAAbnat: 65,
        teamBAbnat: 65,
        mode: GameMode.sun,
        buyerTeam: 'A',
        teamATricksCount: 4,
        teamBTricksCount: 4,
      );
      // Wait, 65 vs 65 is a tie. Tie in Sun without double -> Buyer loses (Khams)
      expect(result.isKhams, true);

      // Let's do a clear win: 70 vs 60
      result = engine.calculateRoundScore(
        teamAAbnat: 70,
        teamBAbnat: 60,
        mode: GameMode.sun,
        buyerTeam: 'A',
        teamATricksCount: 4,
        teamBTricksCount: 4,
      );
      expect(result.isKhams, false);
      expect(result.teamAPoints, 14); // 70 / 5
      expect(result.teamBPoints, 12); // 60 / 5
    });

    test('4.4 Sun - Kabout (Buyer wins all 8)', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 130,
        teamBAbnat: 0,
        mode: GameMode.sun,
        buyerTeam: 'A',
        teamATricksCount: 8,
        teamBTricksCount: 0,
        isKabout: true,
      );
      expect(result.teamAPoints, 44);
    });
  });

  group('Phase 5: Double System', () {
    test('5.1 Hakam Double - Buyer Wins', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 85,
        teamBAbnat: 77,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.doubled,
        teamAProjectScoreboard: 2,
        projectWinningTeam: 'A',
        balootPoints: 2,
        balootTeam: 'A',
      );
      // Base: 16 * 2 = 32
      // Project: 2 * 2 = 4
      // Baloot: 2 (immune to double)
      // Total: 38
      expect(result.teamAPoints, 38);
      expect(result.teamBPoints, 0);
    });

    test('5.4 Hakam Triple - Buyer Loses', () {
      final result = engine.calculateRoundScore(
        teamAAbnat: 77,
        teamBAbnat: 85,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 3,
        teamBTricksCount: 5,
        doubleStatus: DoubleStatus.tripled,
        teamAProjectScoreboard: 2,
        projectWinningTeam: 'A',
      );
      // Defender gets:
      // Base: 16 * 3 = 48
      // Stolen Project: 2 * 3 = 6
      // Total: 54
      expect(result.teamBPoints, 54);
      expect(result.teamAPoints, 0);
    });

    test('5.7 Gahwa', () {
      // Gahwa results in isGameOver = true, score is returned as 0 from normal logic
      // (Winner is decided outside)
      final result = engine.calculateRoundScore(
        teamAAbnat: 85,
        teamBAbnat: 77,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.gahwa,
      );
      expect(result.teamAPoints, 0);
      expect(result.teamBPoints, 0);
      expect(engine.isGameOver(0, 0, DoubleStatus.gahwa), true);
    });

    test('5.10 Sun Double Escalation', () {
      // In Sun, tripled/four should return 0 base value as they are invalid
      final result = engine.calculateRoundScore(
        teamAAbnat: 70,
        teamBAbnat: 60,
        mode: GameMode.sun,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.tripled,
      );
      expect(result.teamAPoints, 0); // Invalid double in sun
    });
  });

  group('Phase 8: Rounding & Totals', () {
    test('8.1 Hakam .5 Rounds DOWN (Jawaker)', () {
      expect(engine.abnatToScoreboard(85, GameMode.hakam), 8);
      expect(engine.abnatToScoreboard(75, GameMode.hakam), 7);
      expect(engine.abnatToScoreboard(86, GameMode.hakam), 9);
    });

    test('8.4 Sun abnat/5 Formula', () {
      expect(engine.abnatToScoreboard(65, GameMode.sun), 13);
      expect(engine.abnatToScoreboard(60, GameMode.sun), 12);
      expect(engine.abnatToScoreboard(70, GameMode.sun), 14);
    });
  });

  group('Phase 9: Qaid (Violation) Penalty', () {
    test('9.1 Violation Baloot Transfer', () {
      // Team B violates. Team A gets Kabout points.
      // Team B had Baloot. It should transfer to Team A.
      final result = engine.calculateViolationScore(
        mode: GameMode.hakam,
        winningTeam: 'A',
        doubleStatus: DoubleStatus.none,
        balootPoints: 2,
        balootTeam: 'B',
      );
      // Kabout base = 25. Baloot = 2. Total = 27.
      expect(result.teamAPoints, 27);
      expect(result.teamBPoints, 0);
    });
  });

  group('Phase 10: Game End Conditions', () {
    test('10.1 Target Score 152', () {
      expect(engine.isGameOver(152, 100, DoubleStatus.none), true);
      expect(engine.isGameOver(151, 100, DoubleStatus.none), false);
    });

    test('10.3 Sudden Death Tie', () {
      expect(engine.isGameOver(152, 152, DoubleStatus.none), false);
      expect(engine.isGameOver(160, 160, DoubleStatus.none), false);
      expect(engine.isGameOver(160, 158, DoubleStatus.none), true);
    });
  });
}
