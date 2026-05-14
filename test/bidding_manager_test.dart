import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/managers/bidding_manager.dart';

void main() {
  final buyerCard = const CardModel(suit: Suit.hearts, rank: Rank.nine);

  group('Module B: BiddingManager', () {
    group('B1: Turn Order', () {
      test('First bidder is dealer RIGHT', () {
        final bm = BiddingManager(dealerIndex: 2, buyerCard: buyerCard);
        expect(bm.currentBidder, 3); // (2+1)%4 = 3
      });

      test('First bidder wraps around', () {
        final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);
        expect(bm.currentBidder, 0); // (3+1)%4 = 0
      });
    });

    group('B2: Round 1 — Hakam Bid', () {
      test('Hakam bid recorded', () {
        final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);
        bm.placeBid(0, BidAction.hakam);
        expect(bm.hasActiveHakamBid, true);
        expect(bm.activeRound1HakamSeat, 0);
      });

      test('Only ONE Hakam bid per Round 1', () {
        final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);
        bm.placeBid(0, BidAction.hakam); // Seat 0 bids Hakam
        // Seat 1 tries Hakam → exception
        expect(() => bm.placeBid(1, BidAction.hakam), throwsA(isA<Exception>()));
      });

      test('Hakam + 3 passes → hakamConfirmation', () {
        final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);
        bm.placeBid(0, BidAction.hakam); // Seat 0
        bm.placeBid(1, BidAction.pass); // Seat 1
        bm.placeBid(2, BidAction.pass); // Seat 2
        // Seat 0 is skipped (already bid)
        bm.placeBid(3, BidAction.pass); // Seat 3
        expect(bm.phase, BiddingPhase.hakamConfirmation);
        expect(bm.currentBidder, 0); // Hakam bidder must confirm
      });
    });

    group('B3: Round 1 — Sun Override', () {
      test('Sun bid ends bidding immediately', () {
        final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);
        bm.placeBid(0, BidAction.sun);
        expect(bm.isFinished, true);
        expect(bm.result!.mode, GameMode.sun);
        expect(bm.result!.buyerIndex, 0);
      });

      test('Sun overrides existing Hakam bid', () {
        final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);
        bm.placeBid(0, BidAction.hakam);
        bm.placeBid(1, BidAction.sun); // Sun overrides
        expect(bm.isFinished, true);
        expect(bm.result!.mode, GameMode.sun);
        expect(bm.result!.buyerIndex, 1);
      });
    });

    group('B4: Round 1 — All 4 Pass', () {
      test('All 4 pass → transitions to Round 2', () {
        final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);
        bm.placeBid(0, BidAction.pass);
        bm.placeBid(1, BidAction.pass);
        bm.placeBid(2, BidAction.pass);
        bm.placeBid(3, BidAction.pass);
        expect(bm.phase, BiddingPhase.round2);
        expect(bm.currentBidder, 0); // (3+1)%4 = 0
      });
    });

    group('B5: Ashkal', () {
      test('Dealer can call Ashkal', () {
        final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);
        // First bidder is seat 1. Pass until dealer's turn.
        bm.placeBid(1, BidAction.pass);
        bm.placeBid(2, BidAction.pass);
        bm.placeBid(3, BidAction.pass);
        bm.placeBid(0, BidAction.ashkal); // Dealer
        expect(bm.isFinished, true);
        expect(bm.result!.isAshkal, true);
        expect(bm.result!.mode, GameMode.sun);
      });

      test('Sane can call Ashkal', () {
        // Sane = (dealer+3)%4. Dealer=1 → Sane=0
        final bm = BiddingManager(dealerIndex: 1, buyerCard: buyerCard);
        // First bidder = seat 2
        bm.placeBid(2, BidAction.pass);
        bm.placeBid(3, BidAction.pass);
        bm.placeBid(0, BidAction.ashkal); // Sane
        expect(bm.isFinished, true);
        expect(bm.result!.isAshkal, true);
      });

      test('Non-dealer/non-sane cannot call Ashkal', () {
        // Dealer=0, Sane=(0+3)%4=3. Seat 1 cannot Ashkal.
        final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);
        expect(() => bm.placeBid(1, BidAction.ashkal), throwsA(isA<Exception>()));
      });
    });

    group('B6: Hakam Confirmation', () {
      BiddingManager _setupConfirmation() {
        final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);
        bm.placeBid(0, BidAction.hakam);
        bm.placeBid(1, BidAction.pass);
        bm.placeBid(2, BidAction.pass);
        bm.placeBid(3, BidAction.pass);
        return bm;
      }

      test('Confirm Hakam → mode=hakam, trump=buyerCard.suit', () {
        final bm = _setupConfirmation();
        bm.placeBid(0, BidAction.confirmHakam);
        expect(bm.result!.mode, GameMode.hakam);
        expect(bm.result!.trumpSuit, Suit.hearts);
      });

      test('Switch to Sun during confirmation', () {
        final bm = _setupConfirmation();
        bm.placeBid(0, BidAction.sun);
        expect(bm.result!.mode, GameMode.sun);
      });

      test('Non-bidder cannot act during confirmation', () {
        final bm = _setupConfirmation();
        expect(() => bm.placeBid(1, BidAction.confirmHakam), throwsA(isA<Exception>()));
      });
    });

    group('B7: Round 2 — Sun Bid', () {
      BiddingManager _setupRound2() {
        final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);
        bm.placeBid(0, BidAction.pass);
        bm.placeBid(1, BidAction.pass);
        bm.placeBid(2, BidAction.pass);
        bm.placeBid(3, BidAction.pass);
        return bm;
      }

      test('Sun in R2 + 3 passes → locks Sun (no confirmation)', () {
        final bm = _setupRound2();
        bm.placeBid(0, BidAction.sun);
        bm.placeBid(1, BidAction.pass);
        bm.placeBid(2, BidAction.pass);
        bm.placeBid(3, BidAction.pass);
        expect(bm.isFinished, true);
        expect(bm.result!.mode, GameMode.sun);
        expect(bm.result!.buyerIndex, 0);
      });
    });

    group('B8: Round 2 — Second Hakam', () {
      BiddingManager _setupRound2() {
        final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);
        for (int i = 0; i < 4; i++) bm.placeBid((i) % 4, BidAction.pass);
        return bm;
      }

      test('Second Hakam must differ from buyer card suit', () {
        final bm = _setupRound2();
        expect(
          () => bm.placeBid(0, BidAction.secondHakam, secondHakamSuit: Suit.hearts),
          throwsA(isA<Exception>()),
        );
      });

      test('Second Hakam with valid suit + 3 passes → hakamConfirmation', () {
        final bm = _setupRound2();
        bm.placeBid(0, BidAction.secondHakam, secondHakamSuit: Suit.spades);
        bm.placeBid(1, BidAction.pass);
        bm.placeBid(2, BidAction.pass);
        bm.placeBid(3, BidAction.pass);
        expect(bm.phase, BiddingPhase.hakamConfirmation);
        bm.placeBid(0, BidAction.confirmHakam);
        expect(bm.result!.trumpSuit, Suit.spades); // Not buyer card suit
      });
    });

    group('B11: Round 2 — All 4 Pass (Cancelled)', () {
      test('All 4 pass R2 → cancelled', () {
        final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);
        // R1: all pass
        for (int i = 0; i < 4; i++) bm.placeBid((i) % 4, BidAction.pass);
        // R2: all pass
        for (int i = 0; i < 4; i++) bm.placeBid((i) % 4, BidAction.pass);
        expect(bm.phase, BiddingPhase.cancelled);
        expect(bm.isFinished, true);
        expect(bm.result, isNull);
      });
    });

    group('B12: Edge Cases', () {
      test('Bidding on wrong turn throws exception', () {
        final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);
        // Current bidder is 0, but seat 2 tries to bid
        expect(() => bm.placeBid(2, BidAction.pass), throwsA(isA<Exception>()));
      });
    });
  });
}
