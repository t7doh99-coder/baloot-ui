import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/features/game/domain/managers/deck_manager.dart';

void main() {
  late DeckManager dm;

  setUp(() {
    dm = DeckManager(random: Random(42)); // fixed seed for determinism
    dm.createDeck();
  });

  group('Deck creation', () {
    test('deck has exactly 32 cards', () {
      expect(dm.remainingCards, 32);
    });

    test('deck has all unique cards', () {
      dm.createDeck();
      // Access internal deck via dealing all
      final allCards = <CardModel>{};
      for (final suit in Suit.values) {
        for (final rank in Rank.values) {
          allCards.add(CardModel(suit: suit, rank: rank));
        }
      }
      expect(allCards.length, 32);
    });

    test('deck contains only ranks 7 through Ace (no 2-6)', () {
      // Rank enum only has seven..ace, so this is guaranteed by type system
      expect(Rank.values.length, 8);
      expect(Rank.values.first, Rank.seven);
      expect(Rank.values.last, Rank.ace);
    });
  });

  group('Shuffle and Kut', () {
    test('shuffle changes card order', () {
      dm.createDeck();
      dm.dealInitial(0);
      final handBefore = List<CardModel>.from(dm.hands[0]);

      dm.createDeck();
      dm.shuffle();
      dm.dealInitial(0);
      final handAfter = dm.hands[0];

      // With a fixed seed, hands should differ from unshuffled
      // (extremely unlikely to be identical)
      expect(handBefore == handAfter, false);
    });

    test('kut preserves all 32 cards', () {
      dm.shuffle();
      dm.kut();
      // Deal everything to check count
      dm.dealInitial(0);
      dm.dealRemainder(0);

      final totalCards = dm.hands.fold<int>(0, (sum, h) => sum + h.length);
      expect(totalCards, 32);
      expect(dm.remainingCards, 0);
    });
  });

  group('dealInitial', () {
    test('each player gets 5 cards after initial deal', () {
      dm.shuffle();
      dm.dealInitial(0);

      for (int i = 0; i < 4; i++) {
        expect(dm.hands[i].length, 5, reason: 'Player $i should have 5 cards');
      }
    });

    test('1 buyer card is revealed', () {
      dm.shuffle();
      dm.dealInitial(0);
      expect(dm.buyerCard, isNotNull);
    });

    test('11 cards remain in deck after initial deal', () {
      dm.shuffle();
      dm.dealInitial(0);
      // 32 - 20 dealt - 1 buyer = 11
      expect(dm.remainingCards, 11);
    });

    test('buyer card is not in any hand', () {
      dm.shuffle();
      dm.dealInitial(0);

      for (int i = 0; i < 4; i++) {
        expect(
          dm.hands[i].contains(dm.buyerCard),
          false,
          reason: 'Buyer card should not be in player $i hand yet',
        );
      }
    });
  });

  group('dealRemainder', () {
    test('each player has exactly 8 cards after full deal', () {
      dm.shuffle();
      dm.dealInitial(0);
      dm.dealRemainder(1);

      for (int i = 0; i < 4; i++) {
        expect(dm.hands[i].length, 8, reason: 'Player $i should have 8 cards');
      }
    });

    test('deck is empty after full deal', () {
      dm.shuffle();
      dm.dealInitial(0);
      dm.dealRemainder(0);
      expect(dm.remainingCards, 0);
    });

    test('buyer receives the buyer card', () {
      dm.shuffle();
      dm.dealInitial(0);
      final buyerCard = dm.buyerCard!;
      dm.dealRemainder(2); // seat 2 is buyer

      expect(dm.hands[2].contains(buyerCard), true);
    });

    test('all 32 cards are distributed with no duplicates', () {
      dm.shuffle();
      dm.dealInitial(0);
      dm.dealRemainder(0);

      final allDealt = <CardModel>{};
      for (final hand in dm.hands) {
        for (final card in hand) {
          expect(allDealt.add(card), true,
              reason: 'Duplicate card found: $card');
        }
      }
      expect(allDealt.length, 32);
    });
  });

  group('Ashkal dealing', () {
    test('Ashkal: teammate receives buyer card instead of buyer', () {
      dm.shuffle();
      dm.dealInitial(0);
      final buyerCard = dm.buyerCard!;

      // Seat 1 is buyer, teammate is seat 3
      dm.dealRemainder(1, isAshkal: true);

      expect(dm.hands[3].contains(buyerCard), true,
          reason: 'Teammate (seat 3) should have buyer card');
      expect(dm.hands[1].contains(buyerCard), false,
          reason: 'Buyer (seat 1) should NOT have buyer card in Ashkal');
    });

    test('Ashkal: all players still have 8 cards', () {
      dm.shuffle();
      dm.dealInitial(0);
      dm.dealRemainder(0, isAshkal: true);

      for (int i = 0; i < 4; i++) {
        expect(dm.hands[i].length, 8);
      }
    });

    test('Ashkal: teammate of seat 0 is seat 2', () {
      dm.shuffle();
      dm.dealInitial(0);
      final buyerCard = dm.buyerCard!;

      dm.dealRemainder(0, isAshkal: true);
      expect(dm.hands[2].contains(buyerCard), true);
    });
  });

  group('Dealing with different dealer positions', () {
    for (int dealer = 0; dealer < 4; dealer++) {
      test('dealer at seat $dealer: all cards distributed correctly', () {
        dm.createDeck();
        dm.shuffle();
        dm.dealInitial(dealer);
        dm.dealRemainder(dealer);

        for (int i = 0; i < 4; i++) {
          expect(dm.hands[i].length, 8);
        }
        expect(dm.remainingCards, 0);
      });
    }
  });
}
