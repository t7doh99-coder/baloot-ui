import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/card_play_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/validators/play_validator.dart';

void main() {
  const validator = PlayValidator();

  group('Rule 1: Follow leading suit', () {
    test('holding leading suit but playing off-suit → suit violation', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.ace), // has hearts
        const CardModel(suit: Suit.spades, rank: Rank.seven),
      ];
      final trick = [
        const CardPlayModel(
          card: CardModel(suit: Suit.hearts, rank: Rank.ten),
          playerIndex: 0,
        ),
      ];

      final result = validator.validate(
        card: const CardModel(suit: Suit.spades, rank: Rank.seven),
        hand: hand,
        currentTrick: trick,
        mode: GameMode.sun,
      );

      expect(result.isValid, false);
      expect(result.violationKind, ViolationKind.suitViolation);
    });

    test('following leading suit → valid', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.ace),
        const CardModel(suit: Suit.spades, rank: Rank.seven),
      ];
      final trick = [
        const CardPlayModel(
          card: CardModel(suit: Suit.hearts, rank: Rank.ten),
          playerIndex: 0,
        ),
      ];

      final result = validator.validate(
        card: const CardModel(suit: Suit.hearts, rank: Rank.ace),
        hand: hand,
        currentTrick: trick,
        mode: GameMode.sun,
      );

      expect(result.isValid, true);
    });

    test('void in leading suit in Sun → any card is valid', () {
      final hand = [
        const CardModel(suit: Suit.spades, rank: Rank.seven),
        const CardModel(suit: Suit.clubs, rank: Rank.king),
      ];
      final trick = [
        const CardPlayModel(
          card: CardModel(suit: Suit.hearts, rank: Rank.ten),
          playerIndex: 0,
        ),
      ];

      final result = validator.validate(
        card: const CardModel(suit: Suit.spades, rank: Rank.seven),
        hand: hand,
        currentTrick: trick,
        mode: GameMode.sun,
      );

      expect(result.isValid, true);
    });
  });

  group('Rule 2: Mandatory cut (Hakam)', () {
    test('void in leading suit, holding trump, not playing trump → cut violation', () {
      final hand = [
        const CardModel(suit: Suit.spades, rank: Rank.jack), // trump
        const CardModel(suit: Suit.clubs, rank: Rank.seven),
      ];
      final trick = [
        const CardPlayModel(
          card: CardModel(suit: Suit.hearts, rank: Rank.ace),
          playerIndex: 0,
        ),
      ];

      final result = validator.validate(
        card: const CardModel(suit: Suit.clubs, rank: Rank.seven),
        hand: hand,
        currentTrick: trick,
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
      );

      expect(result.isValid, false);
      expect(result.violationKind, ViolationKind.cutViolation);
    });

    test('void in both leading suit and trump → any card valid', () {
      final hand = [
        const CardModel(suit: Suit.clubs, rank: Rank.seven),
        const CardModel(suit: Suit.clubs, rank: Rank.eight),
      ];
      final trick = [
        const CardPlayModel(
          card: CardModel(suit: Suit.hearts, rank: Rank.ace),
          playerIndex: 0,
        ),
      ];

      final result = validator.validate(
        card: const CardModel(suit: Suit.clubs, rank: Rank.seven),
        hand: hand,
        currentTrick: trick,
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
      );

      expect(result.isValid, true);
    });
  });

  group('Rule 3: Up-Trump (Hakam)', () {
    test('opponent cut with 9-trump, holding J-trump but playing 7-trump → violation', () {
      final hand = [
        const CardModel(suit: Suit.spades, rank: Rank.jack), // higher trump
        const CardModel(suit: Suit.spades, rank: Rank.seven), // lower trump
      ];
      final trick = [
        const CardPlayModel(
          card: CardModel(suit: Suit.hearts, rank: Rank.ace),
          playerIndex: 0, // Team A leads
        ),
        const CardPlayModel(
          card: CardModel(suit: Suit.spades, rank: Rank.nine), // Team B opponent cuts
          playerIndex: 1,
        ),
      ];

      // Seat 2 (Team A) must play higher trump than opponent seat 1's cut
      final result = validator.validate(
        card: const CardModel(suit: Suit.spades, rank: Rank.seven),
        hand: hand,
        currentTrick: trick,
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        playerSeat: 2,
      );

      expect(result.isValid, false);
      expect(result.violationKind, ViolationKind.upTrumpViolation);
    });

    test('opponent cut with 9-trump, playing J-trump (higher) → valid', () {
      final hand = [
        const CardModel(suit: Suit.spades, rank: Rank.jack),
        const CardModel(suit: Suit.spades, rank: Rank.seven),
      ];
      final trick = [
        const CardPlayModel(
          card: CardModel(suit: Suit.hearts, rank: Rank.ace),
          playerIndex: 0,
        ),
        const CardPlayModel(
          card: CardModel(suit: Suit.spades, rank: Rank.nine),
          playerIndex: 1, // opponent
        ),
      ];

      final result = validator.validate(
        card: const CardModel(suit: Suit.spades, rank: Rank.jack),
        hand: hand,
        currentTrick: trick,
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        playerSeat: 2,
      );

      expect(result.isValid, true);
    });

    test('opponent cut, no higher trump in hand → lower trump is valid', () {
      final hand = [
        const CardModel(suit: Suit.spades, rank: Rank.seven), // only low trump
      ];
      final trick = [
        const CardPlayModel(
          card: CardModel(suit: Suit.hearts, rank: Rank.ace),
          playerIndex: 0,
        ),
        const CardPlayModel(
          card: CardModel(suit: Suit.spades, rank: Rank.jack), // opponent highest trump
          playerIndex: 1,
        ),
      ];

      final result = validator.validate(
        card: const CardModel(suit: Suit.spades, rank: Rank.seven),
        hand: hand,
        currentTrick: trick,
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        playerSeat: 2,
      );

      expect(result.isValid, true);
    });

    test('TEAMMATE cut → up-trump NOT required (only opponent triggers it)', () {
      final hand = [
        const CardModel(suit: Suit.spades, rank: Rank.jack), // higher trump
        const CardModel(suit: Suit.spades, rank: Rank.seven), // lower trump
      ];
      final trick = [
        const CardPlayModel(
          card: CardModel(suit: Suit.hearts, rank: Rank.ace),
          playerIndex: 0, // Team A leads
        ),
        const CardPlayModel(
          card: CardModel(suit: Suit.hearts, rank: Rank.seven),
          playerIndex: 1, // Team B follows
        ),
        const CardPlayModel(
          card: CardModel(suit: Suit.spades, rank: Rank.nine), // Team A teammate cuts
          playerIndex: 2,
        ),
      ];

      // Seat 3 (Team B) — teammate of seat 1 cut at seat 2 (Team A)
      // Wait, seat 2 is Team A. Seat 3 is Team B. Seat 2's cut IS an opponent for seat 3.
      // Let me fix the scenario: seat 0 leads, seat 3 is Team B, teammate is seat 1.
      // If seat 1 (Team B) cuts, seat 3 (also Team B) should NOT need up-trump.
      final trickForTeammate = [
        const CardPlayModel(
          card: CardModel(suit: Suit.hearts, rank: Rank.ace),
          playerIndex: 0, // Team A leads
        ),
        const CardPlayModel(
          card: CardModel(suit: Suit.spades, rank: Rank.nine), // Team B teammate cuts
          playerIndex: 1,
        ),
        const CardPlayModel(
          card: CardModel(suit: Suit.hearts, rank: Rank.seven),
          playerIndex: 2, // Team A follows
        ),
      ];

      // Seat 3 (Team B) — seat 1 (Team B teammate) cut. Up-trump should NOT apply.
      final result = validator.validate(
        card: const CardModel(suit: Suit.spades, rank: Rank.seven), // low trump
        hand: hand,
        currentTrick: trickForTeammate,
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        playerSeat: 3,
      );

      expect(result.isValid, true,
          reason: 'Teammate cut should NOT trigger up-trump');
    });
  });

  group('Closed Play rule', () {
    test('leading with trump while holding other suits in Closed Play → violation', () {
      final hand = [
        const CardModel(suit: Suit.spades, rank: Rank.jack), // trump
        const CardModel(suit: Suit.hearts, rank: Rank.ace), // non-trump
      ];

      final result = validator.validate(
        card: const CardModel(suit: Suit.spades, rank: Rank.jack),
        hand: hand,
        currentTrick: [], // leading
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        doubleStatus: DoubleStatus.doubled,
        isOpenPlay: false,
      );

      expect(result.isValid, false);
      expect(result.violationKind, ViolationKind.closedPlayViolation);
    });

    test('leading with trump when holding only trumps in Closed Play → valid', () {
      final hand = [
        const CardModel(suit: Suit.spades, rank: Rank.jack),
        const CardModel(suit: Suit.spades, rank: Rank.nine),
      ];

      final result = validator.validate(
        card: const CardModel(suit: Suit.spades, rank: Rank.jack),
        hand: hand,
        currentTrick: [],
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        doubleStatus: DoubleStatus.doubled,
        isOpenPlay: false,
      );

      expect(result.isValid, true);
    });

    test('Open Play: leading with trump is always valid', () {
      final hand = [
        const CardModel(suit: Suit.spades, rank: Rank.jack),
        const CardModel(suit: Suit.hearts, rank: Rank.ace),
      ];

      final result = validator.validate(
        card: const CardModel(suit: Suit.spades, rank: Rank.jack),
        hand: hand,
        currentTrick: [],
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        doubleStatus: DoubleStatus.doubled,
        isOpenPlay: true,
      );

      expect(result.isValid, true);
    });
  });

  group('getValidCards (bot helper)', () {
    test('returns only valid plays from hand', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.ace),
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.spades, rank: Rank.king),
      ];
      final trick = [
        const CardPlayModel(
          card: CardModel(suit: Suit.hearts, rank: Rank.ten),
          playerIndex: 0,
        ),
      ];

      final valid = validator.getValidCards(
        hand: hand,
        currentTrick: trick,
        mode: GameMode.sun,
      );

      // Only hearts are valid (must follow suit)
      expect(valid.length, 2);
      expect(valid.every((c) => c.suit == Suit.hearts), true);
    });
  });
}
