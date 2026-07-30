import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/card_play_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/validators/play_validator.dart';

void main() {
  const validator = PlayValidator();

  group('Module C: PlayValidator', () {
    group('C1: Follow Suit', () {
      test('Must follow leading suit when held', () {
        final hand = [
          const CardModel(suit: Suit.hearts, rank: Rank.ace),
          const CardModel(suit: Suit.spades, rank: Rank.seven),
        ];
        final trick = [
          CardPlayModel(card: const CardModel(suit: Suit.hearts, rank: Rank.ten), playerIndex: 1),
        ];
        // Playing spades when holding hearts → violation
        final result = validator.validate(
          card: hand[1],
          hand: hand,
          currentTrick: trick,
          mode: GameMode.hakam,
          trumpSuit: Suit.clubs,
          playerSeat: 0,
        );
        expect(result.isValid, false);
        expect(result.violationKind, ViolationKind.suitViolation);
      });

      test('Playing leading suit is valid', () {
        final hand = [
          const CardModel(suit: Suit.hearts, rank: Rank.ace),
          const CardModel(suit: Suit.spades, rank: Rank.seven),
        ];
        final trick = [
          CardPlayModel(card: const CardModel(suit: Suit.hearts, rank: Rank.ten), playerIndex: 1),
        ];
        final result = validator.validate(
          card: hand[0],
          hand: hand,
          currentTrick: trick,
          mode: GameMode.hakam,
          trumpSuit: Suit.clubs,
          playerSeat: 0,
        );
        expect(result.isValid, true);
      });
    });

    group('C2: Mandatory Cut (Hakam)', () {
      test('Void in leading suit + has trump → MUST play trump', () {
        final hand = [
          const CardModel(suit: Suit.clubs, rank: Rank.jack), // trump
          const CardModel(suit: Suit.diamonds, rank: Rank.seven),
        ];
        final trick = [
          CardPlayModel(card: const CardModel(suit: Suit.hearts, rank: Rank.ten), playerIndex: 1),
        ];
        // Playing diamonds (non-trump) when holding trump → violation
        final result = validator.validate(
          card: hand[1],
          hand: hand,
          currentTrick: trick,
          mode: GameMode.hakam,
          trumpSuit: Suit.clubs,
          playerSeat: 0,
        );
        expect(result.isValid, false);
        expect(result.violationKind, ViolationKind.cutViolation);
      });
    });

    group('C5: Up-Trump Rule', () {
      test('Opponent cut with trump → must play HIGHER trump', () {
        final hand = [
          const CardModel(suit: Suit.clubs, rank: Rank.jack), // trump J (highest)
          const CardModel(suit: Suit.clubs, rank: Rank.seven), // trump 7 (low)
        ];
        final trick = [
          CardPlayModel(card: const CardModel(suit: Suit.hearts, rank: Rank.ten), playerIndex: 1), // lead
          CardPlayModel(card: const CardModel(suit: Suit.clubs, rank: Rank.nine), playerIndex: 2), // opponent cut with 9
        ];
        // Playing 7 of trump when holding J → violation (must play higher)
        final result = validator.validate(
          card: hand[1], // 7 of clubs
          hand: hand,
          currentTrick: trick,
          mode: GameMode.hakam,
          trumpSuit: Suit.clubs,
          playerSeat: 3, // Same team as seat 1 (odd), opponent of seat 2 (even)
        );
        expect(result.isValid, false);
        expect(result.violationKind, ViolationKind.upTrumpViolation);
      });

      test('Cannot overtrump → lower trump OK', () {
        final hand = [
          const CardModel(suit: Suit.clubs, rank: Rank.seven), // trump 7 (low)
        ];
        final trick = [
          CardPlayModel(card: const CardModel(suit: Suit.hearts, rank: Rank.ten), playerIndex: 1), // lead
          CardPlayModel(card: const CardModel(suit: Suit.clubs, rank: Rank.jack), playerIndex: 2), // opponent cut with J (highest)
        ];
        // Only have 7 of trump, opponent played J → can play the 7
        final result = validator.validate(
          card: hand[0],
          hand: hand,
          currentTrick: trick,
          mode: GameMode.hakam,
          trumpSuit: Suit.clubs,
          playerSeat: 3,
        );
        expect(result.isValid, true);
      });
    });

    group('C6: Closed Play Rule', () {
      test('Cannot lead with trump when doubled and holding non-trump', () {
        final hand = [
          const CardModel(suit: Suit.clubs, rank: Rank.jack), // trump
          const CardModel(suit: Suit.hearts, rank: Rank.ace), // non-trump
        ];
        final result = validator.validate(
          card: hand[0], // Leading with trump
          hand: hand,
          currentTrick: [],
          mode: GameMode.hakam,
          trumpSuit: Suit.clubs,
          doubleStatus: DoubleStatus.doubled,
          isOpenPlay: false,
          playerSeat: 0,
        );
        expect(result.isValid, false);
        expect(result.violationKind, ViolationKind.closedPlayViolation);
      });

      test('Only trump in hand → leading trump is fine (Closed Play)', () {
        final hand = [
          const CardModel(suit: Suit.clubs, rank: Rank.jack),
          const CardModel(suit: Suit.clubs, rank: Rank.nine),
        ];
        final result = validator.validate(
          card: hand[0],
          hand: hand,
          currentTrick: [],
          mode: GameMode.hakam,
          trumpSuit: Suit.clubs,
          doubleStatus: DoubleStatus.doubled,
          isOpenPlay: false,
          playerSeat: 0,
        );
        expect(result.isValid, true);
      });
    });

    group('C7: Sun Mode', () {
      test('Void in leading suit in Sun → play ANY card', () {
        final hand = [
          const CardModel(suit: Suit.spades, rank: Rank.seven),
        ];
        final trick = [
          CardPlayModel(card: const CardModel(suit: Suit.hearts, rank: Rank.ace), playerIndex: 1),
        ];
        final result = validator.validate(
          card: hand[0],
          hand: hand,
          currentTrick: trick,
          mode: GameMode.sun,
          playerSeat: 0,
        );
        expect(result.isValid, true);
      });
    });

    group('C8: getValidCards', () {
      test('Returns only valid cards', () {
        final hand = [
          const CardModel(suit: Suit.hearts, rank: Rank.ace),
          const CardModel(suit: Suit.hearts, rank: Rank.king),
          const CardModel(suit: Suit.spades, rank: Rank.seven),
        ];
        final trick = [
          CardPlayModel(card: const CardModel(suit: Suit.hearts, rank: Rank.ten), playerIndex: 1),
        ];
        final valid = validator.getValidCards(
          hand: hand,
          currentTrick: trick,
          mode: GameMode.hakam,
          trumpSuit: Suit.clubs,
          playerSeat: 0,
        );
        // Must follow hearts, so only heart cards valid
        expect(valid.length, 2);
        expect(valid.every((c) => c.suit == Suit.hearts), true);
      });
    });
  });
}
