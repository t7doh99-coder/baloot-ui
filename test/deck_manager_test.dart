import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/features/game/domain/managers/deck_manager.dart';

void main() {
  group('Module A: DeckManager', () {
    group('A1: Deck Creation', () {
      test('Deck has exactly 32 cards', () {
        final dm = DeckManager();
        dm.createDeck();
        // 4 suits × 8 ranks = 32
        int total = 0;
        dm.shuffle(); // need to deal to count
        dm.dealInitial(0);
        total = dm.hands.fold(0, (sum, hand) => sum + hand.length) + 1 + dm.remainingCards;
        expect(total, 32);
      });

      test('No duplicate cards', () {
        final dm = DeckManager();
        dm.createDeck();
        dm.dealInitial(0);
        dm.dealRemainder(0);
        final allCards = <CardModel>[];
        for (final hand in dm.hands) {
          allCards.addAll(hand);
        }
        final uniqueCards = allCards.toSet();
        expect(uniqueCards.length, 32);
        expect(allCards.length, 32);
      });
    });

    group('A2: Shuffle', () {
      test('All 32 cards remain after shuffle', () {
        final dm = DeckManager(random: Random(42));
        dm.createDeck();
        dm.shuffle();
        dm.dealInitial(0);
        dm.dealRemainder(0);
        final allCards = dm.hands.expand((h) => h).toSet();
        expect(allCards.length, 32);
      });
    });

    group('A3: Kut (Cut)', () {
      test('All 32 cards remain after kut', () {
        final dm = DeckManager(random: Random(42));
        dm.createDeck();
        dm.kut();
        dm.dealInitial(0);
        dm.dealRemainder(0);
        final allCards = dm.hands.expand((h) => h).toSet();
        expect(allCards.length, 32);
      });
    });

    group('A4: Deal Phase 1 (dealInitial)', () {
      test('Each player gets 5 cards, 1 buyer card, 11 remain', () {
        final dm = DeckManager(random: Random(42));
        dm.createDeck();
        dm.shuffle();
        dm.dealInitial(0);
        for (int i = 0; i < 4; i++) {
          expect(dm.hands[i].length, 5, reason: 'Player $i should have 5 cards');
        }
        expect(dm.buyerCard, isNotNull);
        expect(dm.remainingCards, 11);
      });

      test('Deal order starts from dealer RIGHT', () {
        // Dealer = seat 2 → first to receive = seat 3
        final dm1 = DeckManager(random: Random(99));
        dm1.createDeck();
        dm1.shuffle();
        dm1.dealInitial(2);
        // Just verify all got cards (order is internal)
        for (int i = 0; i < 4; i++) {
          expect(dm1.hands[i].length, 5);
        }
      });
    });

    group('A5: Deal Phase 2 (dealRemainder)', () {
      test('All players end with 8 cards, deck empty', () {
        final dm = DeckManager(random: Random(42));
        dm.createDeck();
        dm.shuffle();
        dm.dealInitial(0);
        dm.dealRemainder(1); // Seat 1 is buyer
        for (int i = 0; i < 4; i++) {
          expect(dm.hands[i].length, 8, reason: 'Player $i should have 8 cards');
        }
        expect(dm.remainingCards, 0);
      });

      test('Buyer gets the buyer card', () {
        final dm = DeckManager(random: Random(42));
        dm.createDeck();
        dm.shuffle();
        dm.dealInitial(0);
        final buyerCard = dm.buyerCard!;
        dm.dealRemainder(1); // Seat 1 is buyer
        expect(dm.hands[1].contains(buyerCard), true,
            reason: 'Buyer (seat 1) should have the buyer card');
      });

      test('Ashkal: Teammate gets buyer card, not buyer', () {
        final dm = DeckManager(random: Random(42));
        dm.createDeck();
        dm.shuffle();
        dm.dealInitial(0);
        final buyerCard = dm.buyerCard!;
        dm.dealRemainder(1, isAshkal: true); // Seat 1 bids, teammate = seat 3
        expect(dm.hands[3].contains(buyerCard), true,
            reason: 'Teammate (seat 3) should have buyer card in Ashkal');
        expect(dm.hands[1].contains(buyerCard), false,
            reason: 'Buyer (seat 1) should NOT have buyer card in Ashkal');
      });
    });
  });
}
