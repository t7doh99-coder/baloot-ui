import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/engines/project_detector.dart';

void main() {
  const detector = ProjectDetector();

  group('Module E: ProjectDetector', () {
    group('E1: Sera (3 consecutive)', () {
      test('Detected from 7,8,9 same suit', () {
        final hand = [
          const CardModel(suit: Suit.spades, rank: Rank.seven),
          const CardModel(suit: Suit.spades, rank: Rank.eight),
          const CardModel(suit: Suit.spades, rank: Rank.nine),
          const CardModel(suit: Suit.hearts, rank: Rank.ace),
          const CardModel(suit: Suit.hearts, rank: Rank.king),
          const CardModel(suit: Suit.diamonds, rank: Rank.ten),
          const CardModel(suit: Suit.clubs, rank: Rank.jack),
          const CardModel(suit: Suit.clubs, rank: Rank.seven),
        ];
        final projects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.clubs);
        final seras = projects.where((p) => p.type == ProjectType.sera);
        expect(seras.isNotEmpty, true);
      });

      test('NOT detected with gap (7,8,10)', () {
        final hand = [
          const CardModel(suit: Suit.spades, rank: Rank.seven),
          const CardModel(suit: Suit.spades, rank: Rank.eight),
          const CardModel(suit: Suit.spades, rank: Rank.ten),
          const CardModel(suit: Suit.hearts, rank: Rank.ace),
          const CardModel(suit: Suit.hearts, rank: Rank.king),
          const CardModel(suit: Suit.diamonds, rank: Rank.ten),
          const CardModel(suit: Suit.clubs, rank: Rank.jack),
          const CardModel(suit: Suit.clubs, rank: Rank.seven),
        ];
        final projects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.clubs);
        final seras = projects.where((p) => p.type == ProjectType.sera);
        expect(seras.isEmpty, true);
      });
    });

    group('E2: Fifty (4 consecutive)', () {
      test('10-J-Q-K is Fifty (NOT Hundred)', () {
        final hand = [
          const CardModel(suit: Suit.diamonds, rank: Rank.ten),
          const CardModel(suit: Suit.diamonds, rank: Rank.jack),
          const CardModel(suit: Suit.diamonds, rank: Rank.queen),
          const CardModel(suit: Suit.diamonds, rank: Rank.king),
          const CardModel(suit: Suit.hearts, rank: Rank.ace),
          const CardModel(suit: Suit.spades, rank: Rank.seven),
          const CardModel(suit: Suit.clubs, rank: Rank.eight),
          const CardModel(suit: Suit.clubs, rank: Rank.nine),
        ];
        final projects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.clubs);
        final fifties = projects.where((p) => p.type == ProjectType.fifty);
        expect(fifties.isNotEmpty, true);
        // Should NOT be detected as hundred
        final hundreds = projects.where((p) => p.type == ProjectType.hundred);
        expect(hundreds.isEmpty, true);
      });
    });

    group('E3: Hundred (5 consecutive)', () {
      test('5-card run detected as hundred', () {
        final hand = [
          const CardModel(suit: Suit.spades, rank: Rank.seven),
          const CardModel(suit: Suit.spades, rank: Rank.eight),
          const CardModel(suit: Suit.spades, rank: Rank.nine),
          const CardModel(suit: Suit.spades, rank: Rank.ten),
          const CardModel(suit: Suit.spades, rank: Rank.jack),
          const CardModel(suit: Suit.hearts, rank: Rank.ace),
          const CardModel(suit: Suit.clubs, rank: Rank.seven),
          const CardModel(suit: Suit.diamonds, rank: Rank.king),
        ];
        final projects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.clubs);
        final hundreds = projects.where((p) => p.type == ProjectType.hundred);
        expect(hundreds.isNotEmpty, true);
      });
    });

    group('E4: 4-of-a-Kind (Hakam ONLY)', () {
      test('4 Jacks in Hakam = hundred (100, NOT 200)', () {
        final hand = [
          const CardModel(suit: Suit.hearts, rank: Rank.jack),
          const CardModel(suit: Suit.spades, rank: Rank.jack),
          const CardModel(suit: Suit.diamonds, rank: Rank.jack),
          const CardModel(suit: Suit.clubs, rank: Rank.jack),
          const CardModel(suit: Suit.hearts, rank: Rank.ace),
          const CardModel(suit: Suit.spades, rank: Rank.seven),
          const CardModel(suit: Suit.diamonds, rank: Rank.eight),
          const CardModel(suit: Suit.clubs, rank: Rank.nine),
        ];
        final projects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.clubs);
        final hundreds = projects.where((p) => p.type == ProjectType.hundred);
        expect(hundreds.isNotEmpty, true);
        expect(hundreds.first.cards.length, 4);
      });

      test('4 Jacks in Sun → NOT detected', () {
        final hand = [
          const CardModel(suit: Suit.hearts, rank: Rank.jack),
          const CardModel(suit: Suit.spades, rank: Rank.jack),
          const CardModel(suit: Suit.diamonds, rank: Rank.jack),
          const CardModel(suit: Suit.clubs, rank: Rank.jack),
          const CardModel(suit: Suit.hearts, rank: Rank.ace),
          const CardModel(suit: Suit.spades, rank: Rank.seven),
          const CardModel(suit: Suit.diamonds, rank: Rank.eight),
          const CardModel(suit: Suit.clubs, rank: Rank.nine),
        ];
        final projects = detector.detectAll(hand, GameMode.sun);
        final fourOfKind = projects.where((p) =>
            p.type == ProjectType.hundred && p.cards.length == 4 &&
            p.cards.every((c) => c.rank == Rank.jack));
        expect(fourOfKind.isEmpty, true);
      });
    });

    group('E5: Four Aces', () {
      test('4 Aces in Sun = fourHundred', () {
        final hand = [
          const CardModel(suit: Suit.hearts, rank: Rank.ace),
          const CardModel(suit: Suit.spades, rank: Rank.ace),
          const CardModel(suit: Suit.diamonds, rank: Rank.ace),
          const CardModel(suit: Suit.clubs, rank: Rank.ace),
          const CardModel(suit: Suit.hearts, rank: Rank.seven),
          const CardModel(suit: Suit.spades, rank: Rank.seven),
          const CardModel(suit: Suit.diamonds, rank: Rank.seven),
          const CardModel(suit: Suit.clubs, rank: Rank.seven),
        ];
        final projects = detector.detectAll(hand, GameMode.sun);
        final four = projects.where((p) => p.type == ProjectType.fourHundred);
        expect(four.isNotEmpty, true);
      });

      test('4 Aces in Hakam = hundred (100, NOT 400)', () {
        final hand = [
          const CardModel(suit: Suit.hearts, rank: Rank.ace),
          const CardModel(suit: Suit.spades, rank: Rank.ace),
          const CardModel(suit: Suit.diamonds, rank: Rank.ace),
          const CardModel(suit: Suit.clubs, rank: Rank.ace),
          const CardModel(suit: Suit.hearts, rank: Rank.seven),
          const CardModel(suit: Suit.spades, rank: Rank.seven),
          const CardModel(suit: Suit.diamonds, rank: Rank.seven),
          const CardModel(suit: Suit.clubs, rank: Rank.seven),
        ];
        final projects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.clubs);
        final four = projects.where((p) => p.type == ProjectType.fourHundred);
        expect(four.isEmpty, true);
        final hundred = projects.where((p) => p.type == ProjectType.hundred);
        expect(hundred.isNotEmpty, true);
      });
    });

    group('E6: Baloot Detection', () {
      test('K+Q of trump = baloot', () {
        final hand = [
          const CardModel(suit: Suit.clubs, rank: Rank.king),
          const CardModel(suit: Suit.clubs, rank: Rank.queen),
          const CardModel(suit: Suit.hearts, rank: Rank.seven),
          const CardModel(suit: Suit.hearts, rank: Rank.eight),
          const CardModel(suit: Suit.spades, rank: Rank.nine),
          const CardModel(suit: Suit.spades, rank: Rank.ten),
          const CardModel(suit: Suit.diamonds, rank: Rank.jack),
          const CardModel(suit: Suit.diamonds, rank: Rank.ace),
        ];
        final projects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.clubs);
        final baloot = projects.where((p) => p.type == ProjectType.baloot);
        expect(baloot.isNotEmpty, true);
      });

      test('K+Q of non-trump = NOT baloot', () {
        final hand = [
          const CardModel(suit: Suit.hearts, rank: Rank.king),
          const CardModel(suit: Suit.hearts, rank: Rank.queen),
          const CardModel(suit: Suit.clubs, rank: Rank.seven),
          const CardModel(suit: Suit.clubs, rank: Rank.eight),
          const CardModel(suit: Suit.spades, rank: Rank.nine),
          const CardModel(suit: Suit.spades, rank: Rank.ten),
          const CardModel(suit: Suit.diamonds, rank: Rank.jack),
          const CardModel(suit: Suit.diamonds, rank: Rank.ace),
        ];
        final projects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.clubs);
        final baloot = projects.where((p) => p.type == ProjectType.baloot);
        expect(baloot.isEmpty, true);
      });

      test('Sun mode = NO baloot', () {
        final hand = [
          const CardModel(suit: Suit.clubs, rank: Rank.king),
          const CardModel(suit: Suit.clubs, rank: Rank.queen),
          const CardModel(suit: Suit.hearts, rank: Rank.seven),
          const CardModel(suit: Suit.hearts, rank: Rank.eight),
          const CardModel(suit: Suit.spades, rank: Rank.nine),
          const CardModel(suit: Suit.spades, rank: Rank.ten),
          const CardModel(suit: Suit.diamonds, rank: Rank.jack),
          const CardModel(suit: Suit.diamonds, rank: Rank.ace),
        ];
        final projects = detector.detectAll(hand, GameMode.sun);
        final baloot = projects.where((p) => p.type == ProjectType.baloot);
        expect(baloot.isEmpty, true);
      });
    });

    group('E7: Card Overlap Prevention', () {
      test('Max 2 regular projects, no overlap', () {
        // Hand with a Sera AND a separate Sera (no overlap)
        final hand = [
          const CardModel(suit: Suit.hearts, rank: Rank.seven),
          const CardModel(suit: Suit.hearts, rank: Rank.eight),
          const CardModel(suit: Suit.hearts, rank: Rank.nine),
          const CardModel(suit: Suit.spades, rank: Rank.jack),
          const CardModel(suit: Suit.spades, rank: Rank.queen),
          const CardModel(suit: Suit.spades, rank: Rank.king),
          const CardModel(suit: Suit.clubs, rank: Rank.ace),
          const CardModel(suit: Suit.diamonds, rank: Rank.ten),
        ];
        final projects = detector.detectAll(hand, GameMode.hakam, trumpSuit: Suit.clubs);
        final regular = projects.where((p) => p.type != ProjectType.baloot).toList();
        expect(regular.length, 2); // Two non-overlapping Seras
      });
    });

    group('E9: Project Scoreboard Values', () {
      test('Sera values correct', () {
        final sera = DeclaredProject(
          type: ProjectType.sera,
          playerIndex: 0,
          cards: const [
            CardModel(suit: Suit.hearts, rank: Rank.seven),
            CardModel(suit: Suit.hearts, rank: Rank.eight),
            CardModel(suit: Suit.hearts, rank: Rank.nine),
          ],
        );
        expect(sera.getAbnat(GameMode.hakam), 20);
        expect(sera.getScoreboardPoints(GameMode.hakam), 2);
        expect(sera.getScoreboardPoints(GameMode.sun), 4);
      });

      test('Fifty values correct', () {
        final fifty = DeclaredProject(
          type: ProjectType.fifty,
          playerIndex: 0,
          cards: const [
            CardModel(suit: Suit.hearts, rank: Rank.seven),
            CardModel(suit: Suit.hearts, rank: Rank.eight),
            CardModel(suit: Suit.hearts, rank: Rank.nine),
            CardModel(suit: Suit.hearts, rank: Rank.ten),
          ],
        );
        expect(fifty.getAbnat(GameMode.hakam), 50);
        expect(fifty.getScoreboardPoints(GameMode.hakam), 5);
        expect(fifty.getScoreboardPoints(GameMode.sun), 10);
      });

      test('Hundred values correct', () {
        final hundred = DeclaredProject(
          type: ProjectType.hundred,
          playerIndex: 0,
          cards: const [
            CardModel(suit: Suit.hearts, rank: Rank.jack),
            CardModel(suit: Suit.spades, rank: Rank.jack),
            CardModel(suit: Suit.diamonds, rank: Rank.jack),
            CardModel(suit: Suit.clubs, rank: Rank.jack),
          ],
        );
        expect(hundred.getAbnat(GameMode.hakam), 100);
        expect(hundred.getScoreboardPoints(GameMode.hakam), 10);
        expect(hundred.getScoreboardPoints(GameMode.sun), 20);
      });

      test('FourHundred values correct', () {
        final fourH = DeclaredProject(
          type: ProjectType.fourHundred,
          playerIndex: 0,
          cards: const [
            CardModel(suit: Suit.hearts, rank: Rank.ace),
            CardModel(suit: Suit.spades, rank: Rank.ace),
            CardModel(suit: Suit.diamonds, rank: Rank.ace),
            CardModel(suit: Suit.clubs, rank: Rank.ace),
          ],
        );
        expect(fourH.getAbnat(GameMode.sun), 200);
        expect(fourH.getScoreboardPoints(GameMode.sun), 40);
      });
    });
  });
}
