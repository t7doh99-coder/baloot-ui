import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/engines/scoring_engine.dart';

/// Rulebook §8 alignment for end-of-round scoreboard numbers (Kammelna-style).
///
/// Validates [ScoringEngine.calculateRoundScore] outputs that feed
/// [GameProvider.lastRoundResult] / [RoundScoreOverlay].
void main() {
  const engine = ScoringEngine();

  group('Sun — normal (buyer wins purchase)', () {
    test('Kammelna-style: 67 vs 63 Abnat → 14 vs 12 board pts (buyer A)', () {
      final r = engine.calculateRoundScore(
        teamAAbnat: 67,
        teamBAbnat: 63,
        mode: GameMode.sun,
        buyerTeam: 'A',
        teamATricksCount: 4,
        teamBTricksCount: 4,
        lastTrickBonusTeam: 'A',
      );

      expect(r.isKhams, false);
      expect(r.isKabout, false);
      expect(r.winningTeam, 'A');
      expect(r.teamAPoints, 14); // round(6.7)*2
      expect(r.teamBPoints, 12); // round(6.3)*2
      expect(r.teamARawAbnat, 67);
      expect(r.teamBRawAbnat, 63);
    });

    test('trick rows + ground match raw totals in breakdown fields', () {
      final r = engine.calculateRoundScore(
        teamAAbnat: 80,
        teamBAbnat: 50,
        mode: GameMode.sun,
        buyerTeam: 'B',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        lastTrickBonusTeam: 'A',
      );

      final groundA = r.lastTrickBonusTeam == 'A' ? 10 : 0;
      final groundB = r.lastTrickBonusTeam == 'B' ? 10 : 0;
      expect(r.teamATrickAbnat - groundA + groundA, r.teamARawAbnat);
      expect(r.teamBTrickAbnat - groundB + groundB, r.teamBRawAbnat);
    });
  });

  group('Sun — Khams (buyer loses)', () {
    test('Kammelna-style: buyer team loses → defenders 26, buyer 0', () {
      final r = engine.calculateRoundScore(
        teamAAbnat: 80,
        teamBAbnat: 50,
        mode: GameMode.sun,
        buyerTeam: 'B',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        lastTrickBonusTeam: 'A',
      );

      expect(r.isKhams, true);
      expect(r.winningTeam, 'A');
      expect(r.teamAPoints, 26);
      expect(r.teamBPoints, 0);
    });
  });

  group('Hakam — normal', () {
    test('buyer wins: both teams get Jawaker-rounded board pts from Abnat', () {
      final r = engine.calculateRoundScore(
        teamAAbnat: 92,
        teamBAbnat: 70,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        lastTrickBonusTeam: 'A',
      );

      expect(r.isKhams, false);
      expect(r.teamAPoints, engine.abnatToScoreboard(92, GameMode.hakam));
      expect(r.teamBPoints, engine.abnatToScoreboard(70, GameMode.hakam));
    });
  });
}
