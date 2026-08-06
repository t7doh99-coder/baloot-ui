import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/engines/project_detector.dart';
import 'package:baloot_game/features/game/domain/engines/scoring_engine.dart';

void main() {
  const detector = ProjectDetector();
  const scoringEngine = ScoringEngine();

  group('ProjectDetector Audit - Component 1: Detection', () {
    test('1.1 Sera (3 consecutive)', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.ten),
        const CardModel(suit: Suit.hearts, rank: Rank.nine),
        const CardModel(suit: Suit.hearts, rank: Rank.eight),
        const CardModel(suit: Suit.clubs, rank: Rank.king),
        const CardModel(suit: Suit.diamonds, rank: Rank.seven),
      ];
      final projects = detector.detectAll(hand, GameMode.sun);
      expect(projects.length, 1);
      expect(projects.first.type, ProjectType.sera);
      expect(projects.first.highestStrength, 6); // Ten is strength 6
    });

    test('1.2 Fifty (4 consecutive)', () {
      final hand = [
        const CardModel(suit: Suit.spades, rank: Rank.king),
        const CardModel(suit: Suit.spades, rank: Rank.queen),
        const CardModel(suit: Suit.spades, rank: Rank.jack),
        const CardModel(suit: Suit.spades, rank: Rank.ten),
        const CardModel(suit: Suit.diamonds, rank: Rank.seven),
      ];
      final projects = detector.detectAll(hand, GameMode.sun);
      expect(projects.length, 1);
      expect(projects.first.type, ProjectType.fifty);
      expect(projects.first.highestStrength, 5); // King is strength 5
    });

    test('1.3 Hundred (5 consecutive)', () {
      final hand = [
        const CardModel(suit: Suit.diamonds, rank: Rank.ace),
        const CardModel(suit: Suit.diamonds, rank: Rank.king),
        const CardModel(suit: Suit.diamonds, rank: Rank.queen),
        const CardModel(suit: Suit.diamonds, rank: Rank.jack),
        const CardModel(suit: Suit.diamonds, rank: Rank.ten),
      ];
      final projects = detector.detectAll(hand, GameMode.sun);
      expect(projects.length, 1);
      expect(projects.first.type, ProjectType.hundred);
      expect(projects.first.highestStrength, 7); // Ace is strength 7
    });

    test('1.4 Hundred via 4-of-a-kind (Hakam Only)', () {
      final hand = [
        const CardModel(suit: Suit.diamonds, rank: Rank.king),
        const CardModel(suit: Suit.hearts, rank: Rank.king),
        const CardModel(suit: Suit.spades, rank: Rank.king),
        const CardModel(suit: Suit.clubs, rank: Rank.king),
        const CardModel(suit: Suit.clubs, rank: Rank.seven),
      ];
      
      // In this engine, 4-of-a-kind (10/J/Q/K) is currently allowed in Sun as 100.
      final sunProjects = detector.detectAll(hand, GameMode.sun);
      expect(sunProjects.length, 1);
      expect(sunProjects.first.type, ProjectType.hundred);

      // In Hakam, 4 Kings is a 100.
      final hakamProjects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.hearts);
      expect(hakamProjects.length, 1);
      expect(hakamProjects.first.type, ProjectType.hundred);
    });

    test('1.5 Four Hundred (4 Aces - Sun Only)', () {
      final hand = [
        const CardModel(suit: Suit.diamonds, rank: Rank.ace),
        const CardModel(suit: Suit.hearts, rank: Rank.ace),
        const CardModel(suit: Suit.spades, rank: Rank.ace),
        const CardModel(suit: Suit.clubs, rank: Rank.ace),
        const CardModel(suit: Suit.clubs, rank: Rank.seven),
      ];
      
      // In Sun, 4 Aces is 400.
      final sunProjects = detector.detectAll(hand, GameMode.sun);
      expect(sunProjects.length, 1);
      expect(sunProjects.first.type, ProjectType.fourHundred);

      // In Hakam, 4 Aces is just a 100.
      final hakamProjects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.hearts);
      expect(hakamProjects.length, 1);
      expect(hakamProjects.first.type, ProjectType.hundred);
    });

    test('1.6 Baloot (K + Q of Trump)', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.king),
        const CardModel(suit: Suit.hearts, rank: Rank.queen),
        const CardModel(suit: Suit.spades, rank: Rank.eight),
        const CardModel(suit: Suit.clubs, rank: Rank.nine),
        const CardModel(suit: Suit.clubs, rank: Rank.seven),
      ];
      
      // In Sun, Baloot does not exist.
      final sunProjects = detector.detectAll(hand, GameMode.sun);
      expect(sunProjects.isEmpty, true);

      // In Hakam (Trump Hearts), K+Q is Baloot.
      final hakamProjects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.hearts);
      expect(hakamProjects.length, 1);
      expect(hakamProjects.first.type, ProjectType.baloot);
    });
  });

  group('ProjectDetector Audit - Component 2: Scoring Engine & Edge Cases', () {
    test('2.1 Scoring points mapping', () {
      final sera = const DeclaredProject(type: ProjectType.sera, cards: [], playerIndex: 0);
      final fifty = const DeclaredProject(type: ProjectType.fifty, cards: [], playerIndex: 0);
      final hundred = const DeclaredProject(type: ProjectType.hundred, cards: [], playerIndex: 0);
      final baloot = const DeclaredProject(type: ProjectType.baloot, cards: [], playerIndex: 0);
      final fourHundred = const DeclaredProject(type: ProjectType.fourHundred, cards: [], playerIndex: 0);

      // In Sun mode
      expect(sera.getScoreboardPoints(GameMode.sun), 4);
      expect(fifty.getScoreboardPoints(GameMode.sun), 10);
      expect(hundred.getScoreboardPoints(GameMode.sun), 20);
      expect(fourHundred.getScoreboardPoints(GameMode.sun), 40);

      // In Hakam mode
      expect(sera.getScoreboardPoints(GameMode.hakam), 2);
      expect(fifty.getScoreboardPoints(GameMode.hakam), 5);
      expect(hundred.getScoreboardPoints(GameMode.hakam), 10);
      expect(baloot.getScoreboardPoints(GameMode.hakam), 2);
    });
  });
}
