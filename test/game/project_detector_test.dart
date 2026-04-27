import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/engines/project_detector.dart';

void main() {
  const detector = ProjectDetector();

  group('Sera (3 consecutive same suit)', () {
    test('7,8,9 of hearts → Sera', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.hearts, rank: Rank.eight),
        const CardModel(suit: Suit.hearts, rank: Rank.nine),
        const CardModel(suit: Suit.spades, rank: Rank.ace),
        const CardModel(suit: Suit.clubs, rank: Rank.king),
        const CardModel(suit: Suit.diamonds, rank: Rank.ten),
        const CardModel(suit: Suit.diamonds, rank: Rank.seven),
        const CardModel(suit: Suit.clubs, rank: Rank.eight),
      ];

      final projects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.spades);
      final seras = projects.where((p) => p.type == ProjectType.sera).toList();
      expect(seras.length, 1);
      expect(seras.first.cards.length, 3);
    });

    test('non-consecutive cards → no Sera', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.hearts, rank: Rank.nine), // gap: no 8
        const CardModel(suit: Suit.hearts, rank: Rank.jack),
        const CardModel(suit: Suit.spades, rank: Rank.ace),
        const CardModel(suit: Suit.clubs, rank: Rank.king),
        const CardModel(suit: Suit.diamonds, rank: Rank.ten),
        const CardModel(suit: Suit.diamonds, rank: Rank.seven),
        const CardModel(suit: Suit.clubs, rank: Rank.eight),
      ];

      final projects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.spades);
      expect(projects.where((p) => p.type == ProjectType.sera).length, 0);
    });
  });

  group('Fifty (4 consecutive same suit)', () {
    test('10,J,Q,K of spades → 50', () {
      final hand = [
        const CardModel(suit: Suit.spades, rank: Rank.ten),
        const CardModel(suit: Suit.spades, rank: Rank.jack),
        const CardModel(suit: Suit.spades, rank: Rank.queen),
        const CardModel(suit: Suit.spades, rank: Rank.king),
        const CardModel(suit: Suit.hearts, rank: Rank.ace),
        const CardModel(suit: Suit.clubs, rank: Rank.seven),
        const CardModel(suit: Suit.diamonds, rank: Rank.eight),
        const CardModel(suit: Suit.hearts, rank: Rank.nine),
      ];

      final projects = detector.detectAll(hand, GameMode.sun);
      final hundreds = projects.where((p) => p.type == ProjectType.hundred).toList();
      expect(hundreds.length, greaterThanOrEqualTo(1));
    });
  });

  group('Hundred (100) — Both modes', () {
    test('5 consecutive same suit → 100', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.hearts, rank: Rank.eight),
        const CardModel(suit: Suit.hearts, rank: Rank.nine),
        const CardModel(suit: Suit.hearts, rank: Rank.ten),
        const CardModel(suit: Suit.hearts, rank: Rank.jack),
        const CardModel(suit: Suit.spades, rank: Rank.ace),
        const CardModel(suit: Suit.clubs, rank: Rank.king),
        const CardModel(suit: Suit.diamonds, rank: Rank.queen),
      ];

      final projects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.spades);
      final hundreds = projects.where((p) => p.type == ProjectType.hundred).toList();
      expect(hundreds.length, greaterThanOrEqualTo(1));
    });

    test('4x(10,J,Q,K) same rank → 100', () {
      final hand = [
        const CardModel(suit: Suit.clubs, rank: Rank.ten),
        const CardModel(suit: Suit.clubs, rank: Rank.jack),
        const CardModel(suit: Suit.clubs, rank: Rank.queen),
        const CardModel(suit: Suit.clubs, rank: Rank.king),
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.spades, rank: Rank.eight),
        const CardModel(suit: Suit.diamonds, rank: Rank.nine),
        const CardModel(suit: Suit.hearts, rank: Rank.ace),
      ];

      final projects = detector.detectAll(hand, GameMode.sun);
      final hundreds = projects.where((p) => p.type == ProjectType.hundred).toList();
      expect(hundreds.length, greaterThanOrEqualTo(1));
    });

    test('4 Aces in Hakam → 100 (not 400)', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.ace),
        const CardModel(suit: Suit.spades, rank: Rank.ace),
        const CardModel(suit: Suit.clubs, rank: Rank.ace),
        const CardModel(suit: Suit.diamonds, rank: Rank.ace),
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.spades, rank: Rank.eight),
        const CardModel(suit: Suit.clubs, rank: Rank.nine),
        const CardModel(suit: Suit.diamonds, rank: Rank.ten),
      ];

      final projects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.spades);
      expect(projects.any((p) => p.type == ProjectType.hundred), true);
      expect(projects.any((p) => p.type == ProjectType.fourHundred), false);
    });
  });

  group('Four Hundred (400) — Sun only', () {
    test('4 Aces in Sun → 400', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.ace),
        const CardModel(suit: Suit.spades, rank: Rank.ace),
        const CardModel(suit: Suit.clubs, rank: Rank.ace),
        const CardModel(suit: Suit.diamonds, rank: Rank.ace),
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.spades, rank: Rank.eight),
        const CardModel(suit: Suit.clubs, rank: Rank.nine),
        const CardModel(suit: Suit.diamonds, rank: Rank.ten),
      ];

      final projects = detector.detectAll(hand, GameMode.sun);
      expect(projects.any((p) => p.type == ProjectType.fourHundred), true);
    });

    test('4 Aces NOT available in Hakam for 400', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.ace),
        const CardModel(suit: Suit.spades, rank: Rank.ace),
        const CardModel(suit: Suit.clubs, rank: Rank.ace),
        const CardModel(suit: Suit.diamonds, rank: Rank.ace),
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.spades, rank: Rank.eight),
        const CardModel(suit: Suit.clubs, rank: Rank.nine),
        const CardModel(suit: Suit.diamonds, rank: Rank.ten),
      ];

      final projects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.spades);
      expect(projects.any((p) => p.type == ProjectType.fourHundred), false);
    });
  });

  group('Baloot (K+Q of trump)', () {
    test('K+Q of trump suit → Baloot detected', () {
      final hand = [
        const CardModel(suit: Suit.spades, rank: Rank.king),
        const CardModel(suit: Suit.spades, rank: Rank.queen),
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.hearts, rank: Rank.eight),
        const CardModel(suit: Suit.clubs, rank: Rank.nine),
        const CardModel(suit: Suit.clubs, rank: Rank.ten),
        const CardModel(suit: Suit.diamonds, rank: Rank.jack),
        const CardModel(suit: Suit.diamonds, rank: Rank.ace),
      ];

      final projects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.spades);
      expect(projects.any((p) => p.type == ProjectType.baloot), true);
    });

    test('K+Q of non-trump suit → no Baloot', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.king),
        const CardModel(suit: Suit.hearts, rank: Rank.queen),
        const CardModel(suit: Suit.spades, rank: Rank.seven),
        const CardModel(suit: Suit.spades, rank: Rank.eight),
        const CardModel(suit: Suit.clubs, rank: Rank.nine),
        const CardModel(suit: Suit.clubs, rank: Rank.ten),
        const CardModel(suit: Suit.diamonds, rank: Rank.jack),
        const CardModel(suit: Suit.diamonds, rank: Rank.ace),
      ];

      final projects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.spades);
      expect(projects.any((p) => p.type == ProjectType.baloot), false);
    });

    test('Baloot not detected in Sun mode', () {
      final hand = [
        const CardModel(suit: Suit.spades, rank: Rank.king),
        const CardModel(suit: Suit.spades, rank: Rank.queen),
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.hearts, rank: Rank.eight),
        const CardModel(suit: Suit.clubs, rank: Rank.nine),
        const CardModel(suit: Suit.clubs, rank: Rank.ten),
        const CardModel(suit: Suit.diamonds, rank: Rank.jack),
        const CardModel(suit: Suit.diamonds, rank: Rank.ace),
      ];

      final projects = detector.detectAll(hand, GameMode.sun);
      expect(projects.any((p) => p.type == ProjectType.baloot), false);
    });
  });

  group('Project priority', () {
    test('100 beats 50 in priority', () {
      final teamA = [
        DeclaredProject(
          type: ProjectType.hundred,
          playerIndex: 0,
          cards: const [],
        ),
      ];
      final teamB = [
        DeclaredProject(
          type: ProjectType.fifty,
          playerIndex: 1,
          cards: const [],
        ),
      ];

      final winner = detector.resolveProjectPriority(teamA, teamB, GameMode.sun, null, 0);
      expect(winner, 'A');
    });

    test('same rank → higher card wins', () {
      final teamA = [
        DeclaredProject(
          type: ProjectType.sera,
          playerIndex: 0,
          cards: const [
            CardModel(suit: Suit.hearts, rank: Rank.seven),
            CardModel(suit: Suit.hearts, rank: Rank.eight),
            CardModel(suit: Suit.hearts, rank: Rank.nine),
          ],
        ),
      ];
      final teamB = [
        DeclaredProject(
          type: ProjectType.sera,
          playerIndex: 1,
          cards: const [
            CardModel(suit: Suit.spades, rank: Rank.queen),
            CardModel(suit: Suit.spades, rank: Rank.king),
            CardModel(suit: Suit.spades, rank: Rank.ace),
          ],
        ),
      ];

      final winner = detector.resolveProjectPriority(teamA, teamB, GameMode.sun, null, 0);
      expect(winner, 'B'); // Q,K,A has higher card than 7,8,9
    });

    test('exact tie (rank & card) → Trump wins (Rule 14.1)', () {
      final teamA = [
        DeclaredProject(
          type: ProjectType.sera,
          playerIndex: 2,
          cards: const [
            CardModel(suit: Suit.hearts, rank: Rank.seven),
            CardModel(suit: Suit.hearts, rank: Rank.eight),
            CardModel(suit: Suit.hearts, rank: Rank.nine),
          ],
        ),
      ];
      final teamB = [
        DeclaredProject(
          type: ProjectType.sera,
          playerIndex: 1,
          cards: const [
            CardModel(suit: Suit.spades, rank: Rank.seven),
            CardModel(suit: Suit.spades, rank: Rank.eight),
            CardModel(suit: Suit.spades, rank: Rank.nine),
          ],
        ),
      ];

      // In Hakam mode where Spades is Trump, Team B wins the tie
      final winner = detector.resolveProjectPriority(teamA, teamB, GameMode.hakam, Suit.spades, 0);
      expect(winner, 'B');
    });

    test('exact tie (rank & card & no trump) → Turn order wins (Rule 14.1)', () {
      final teamA = [
        DeclaredProject(
          type: ProjectType.sera,
          playerIndex: 2,
          cards: const [
            CardModel(suit: Suit.hearts, rank: Rank.seven),
            CardModel(suit: Suit.hearts, rank: Rank.eight),
            CardModel(suit: Suit.hearts, rank: Rank.nine),
          ],
        ),
      ];
      final teamB = [
        DeclaredProject(
          type: ProjectType.sera,
          playerIndex: 1,
          cards: const [
            CardModel(suit: Suit.diamonds, rank: Rank.seven),
            CardModel(suit: Suit.diamonds, rank: Rank.eight),
            CardModel(suit: Suit.diamonds, rank: Rank.nine),
          ],
        ),
      ];

      // First leader is 0. Players are 1 and 2.
      // Proximity: 1 is closer to 0 than 2 is. So Player 1 (Team B) wins.
      final winner = detector.resolveProjectPriority(teamA, teamB, GameMode.sun, null, 0);
      expect(winner, 'B');
    });
  });

  group('Max 2 projects per player', () {
    test('only top 2 regular projects kept', () {
      // Hand with multiple sequences
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.hearts, rank: Rank.eight),
        const CardModel(suit: Suit.hearts, rank: Rank.nine),
        const CardModel(suit: Suit.spades, rank: Rank.ten),
        const CardModel(suit: Suit.spades, rank: Rank.jack),
        const CardModel(suit: Suit.spades, rank: Rank.queen),
        const CardModel(suit: Suit.clubs, rank: Rank.king),
        const CardModel(suit: Suit.clubs, rank: Rank.ace),
      ];

      final projects = detector.detectAll(hand, GameMode.sun);
      final regular = projects.where((p) => p.type != ProjectType.baloot).toList();
      expect(regular.length, lessThanOrEqualTo(2));
    });
  });
}
