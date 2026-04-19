import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/core/errors/game_exceptions.dart';
import 'package:baloot_game/features/game/domain/managers/bidding_manager.dart';

void main() {
  // Dealer at seat 0 → first bidder is seat 1 (dealer's right on screen)
  // Turn order (clockwise on screen): 1 → 2 → 3 → 0
  const buyerCard = CardModel(suit: Suit.hearts, rank: Rank.ten);

  group('Round 1 — Hakam or Pass', () {
    test('player bids Hakam → 3 passes → enters hakamConfirmation', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);

      expect(bm.currentBidder, 1);
      bm.placeBid(1, BidAction.hakam); // seat 1 bids Hakam

      // Remaining 3 players pass
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);
      bm.placeBid(0, BidAction.pass);

      // Now in hakamConfirmation — bidder must confirm or switch
      expect(bm.isFinished, false);
      expect(bm.phase, BiddingPhase.hakamConfirmation);
      expect(bm.currentBidder, 1);

      // Confirm Hakam
      bm.placeBid(1, BidAction.confirmHakam);

      expect(bm.isFinished, true);
      expect(bm.result!.mode, GameMode.hakam);
      expect(bm.result!.buyerIndex, 1);
      expect(bm.result!.trumpSuit, Suit.hearts);
    });

    test('Hakam bid → 3 passes → buyer switches to Sun', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);

      bm.placeBid(1, BidAction.hakam);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);
      bm.placeBid(0, BidAction.pass);

      expect(bm.phase, BiddingPhase.hakamConfirmation);

      // Switch to Sun
      bm.placeBid(1, BidAction.sun);

      expect(bm.isFinished, true);
      expect(bm.result!.mode, GameMode.sun);
      expect(bm.result!.buyerIndex, 1);
      expect(bm.result!.trumpSuit, isNull);
    });

    test('hakamConfirmation — wrong player throws', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);

      bm.placeBid(1, BidAction.hakam);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);
      bm.placeBid(0, BidAction.pass);

      expect(bm.phase, BiddingPhase.hakamConfirmation);

      // Seat 2 (not the bidder) tries to act
      expect(
        () => bm.placeBid(2, BidAction.confirmHakam),
        throwsA(isA<InvalidBidException>()),
      );
    });

    test('hakamConfirmation — invalid action throws', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);

      bm.placeBid(1, BidAction.hakam);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);
      bm.placeBid(0, BidAction.pass);

      expect(bm.phase, BiddingPhase.hakamConfirmation);

      // Pass is not valid during confirmation
      expect(
        () => bm.placeBid(1, BidAction.pass),
        throwsA(isA<InvalidBidException>()),
      );
    });

    test('all pass Round 1 → moves to Round 2', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);

      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);
      bm.placeBid(0, BidAction.pass);

      expect(bm.phase, BiddingPhase.round2);
      expect(bm.isFinished, false);
    });

    test('Sun overrides Hakam in Round 1', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);

      bm.placeBid(1, BidAction.hakam); // seat 1 bids Hakam
      bm.placeBid(2, BidAction.sun); // seat 2 overrides with Sun

      expect(bm.isFinished, true);
      expect(bm.result!.mode, GameMode.sun);
      expect(bm.result!.buyerIndex, 2);
      expect(bm.result!.trumpSuit, isNull);
    });

    test('wrong seat throws InvalidBidException', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);

      expect(
        () => bm.placeBid(0, BidAction.pass), // seat 0, but bidder is seat 1
        throwsA(isA<InvalidBidException>()),
      );
    });

    test('invalid action in Round 1 throws', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);

      expect(
        () => bm.placeBid(1, BidAction.secondHakam, secondHakamSuit: Suit.spades),
        throwsA(isA<InvalidBidException>()),
      );
    });
  });

  group('Round 1 — Sawa', () {
    test('Sawa locks existing Hakam bid and ends immediately', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);

      bm.placeBid(1, BidAction.hakam); // seat 1 bids Hakam
      bm.placeBid(2, BidAction.sawa); // seat 2 calls Sawa

      expect(bm.isFinished, true);
      expect(bm.result!.mode, GameMode.hakam);
      expect(bm.result!.buyerIndex, 1); // original bidder
      expect(bm.result!.trumpSuit, Suit.hearts);
    });

    test('Sawa from Hakam bidder’s partner throws (Jawaker/Kammelna)', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);

      bm.placeBid(1, BidAction.hakam);
      bm.placeBid(2, BidAction.pass); // advance to seat 3 (partner of seat 1)
      expect(
        () => bm.placeBid(3, BidAction.sawa),
        throwsA(isA<InvalidBidException>()),
      );
    });

    test('second Hakam in Round 1 after a Hakam bid throws', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);

      bm.placeBid(1, BidAction.hakam);
      expect(
        () => bm.placeBid(2, BidAction.hakam),
        throwsA(isA<InvalidBidException>()),
      );
    });

    test('Sawa without active bid throws', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);

      expect(
        () => bm.placeBid(1, BidAction.sawa),
        throwsA(isA<InvalidBidException>()),
      );
    });
  });

  group('Round 2 — Sun, Second Hakam, Ashkal, Pass', () {
    BiddingManager toRound2() {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);
      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);
      bm.placeBid(0, BidAction.pass);
      return bm;
    }

    test('Round 2 Sun — 3 passes from others locks Sun for bidder', () {
      final bm = toRound2();

      bm.placeBid(1, BidAction.sun);
      expect(bm.isFinished, false);
      expect(bm.hasRound2PendingBid, true);

      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);
      bm.placeBid(0, BidAction.pass);

      expect(bm.isFinished, true);
      expect(bm.result!.mode, GameMode.sun);
      expect(bm.result!.buyerIndex, 1);
      expect(bm.result!.trumpSuit, isNull);
    });

    test('Round 2 Sun — Sawa locks immediately (original buyer)', () {
      final bm = toRound2();

      bm.placeBid(1, BidAction.sun);
      expect(bm.currentBidder, 2);
      bm.placeBid(2, BidAction.sawa);

      expect(bm.isFinished, true);
      expect(bm.result!.mode, GameMode.sun);
      expect(bm.result!.buyerIndex, 1);
    });

    test('Round 2 Sun — Sawa from bidder’s partner throws', () {
      final bm = toRound2();

      bm.placeBid(1, BidAction.sun);
      bm.placeBid(2, BidAction.pass); // advance to seat 3 (partner of 1)
      expect(
        () => bm.placeBid(3, BidAction.sawa),
        throwsA(isA<InvalidBidException>()),
      );
    });

    test('Round 2 Second Hakam — 3 passes → hakamConfirmation (Visca / apps)', () {
      final bm = toRound2();

      bm.placeBid(1, BidAction.secondHakam, secondHakamSuit: Suit.spades);
      expect(bm.isFinished, false);

      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);
      bm.placeBid(0, BidAction.pass);

      expect(bm.isFinished, false);
      expect(bm.phase, BiddingPhase.hakamConfirmation);
      expect(bm.currentBidder, 1);

      bm.placeBid(1, BidAction.confirmHakam);
      expect(bm.isFinished, true);
      expect(bm.result!.mode, GameMode.hakam);
      expect(bm.result!.trumpSuit, Suit.spades);
      expect(bm.result!.buyerIndex, 1);
    });

    test('Round 2 Second Hakam — 3 passes → buyer switches to Sun', () {
      final bm = toRound2();

      bm.placeBid(1, BidAction.secondHakam, secondHakamSuit: Suit.spades);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);
      bm.placeBid(0, BidAction.pass);

      expect(bm.phase, BiddingPhase.hakamConfirmation);

      bm.placeBid(1, BidAction.sun);
      expect(bm.isFinished, true);
      expect(bm.result!.mode, GameMode.sun);
      expect(bm.result!.buyerIndex, 1);
      expect(bm.result!.trumpSuit, isNull);
    });

    test('Second Hakam with same suit as buyer card throws', () {
      final bm = toRound2();

      expect(
        () => bm.placeBid(1, BidAction.secondHakam,
            secondHakamSuit: Suit.hearts),
        throwsA(isA<InvalidBidException>()),
      );
    });

    test('Second Hakam without specifying suit throws', () {
      final bm = toRound2();

      expect(
        () => bm.placeBid(1, BidAction.secondHakam),
        throwsA(isA<InvalidBidException>()),
      );
    });

    test('all pass both rounds → cancelled', () {
      final bm = toRound2();

      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);
      bm.placeBid(0, BidAction.pass);

      expect(bm.isFinished, true);
      expect(bm.phase, BiddingPhase.cancelled);
      expect(bm.result, isNull);
    });
  });

  group('Ashkal', () {
    test('Dealer (seat 0) can bid Ashkal in Round 1', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);
      // R1 order: 1→2→3→0. Advance to dealer's turn (seat 0).
      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);
      bm.placeBid(0, BidAction.ashkal);

      expect(bm.isFinished, true);
      expect(bm.result!.mode, GameMode.sun);
      expect(bm.result!.isAshkal, true);
      expect(bm.result!.buyerIndex, 0);
    });

    test('Sane (seat 3, dealer LEFT) can bid Ashkal in Round 1', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);
      // R1 order: 1→2→3. Seat 3 is sane = (0+3)%4 = 3.
      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.ashkal); // Sane = dealer(0)'s left = seat 3

      expect(bm.isFinished, true);
      expect(bm.result!.isAshkal, true);
    });

    test('non-dealer/non-sane cannot bid Ashkal in Round 1', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);

      expect(
        () => bm.placeBid(1, BidAction.ashkal),
        throwsA(isA<InvalidBidException>()),
      );
    });

    test('Ashkal is NOT allowed in Round 2 (Jawaker/Kamelna)', () {
      // Advance to Round 2
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);
      for (int i = 0; i < 4; i++) {
        bm.placeBid(bm.currentBidder, BidAction.pass);
      }
      expect(bm.phase, BiddingPhase.round2);

      // Even dealer should not be able to Ashkal in Round 2
      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);
      expect(
        () => bm.placeBid(0, BidAction.ashkal),
        throwsA(isA<InvalidBidException>()),
      );
    });
  });

  group('Turn order verification', () {
    test('dealer at seat 2: bidding starts at seat 3, goes 3→0→1→2', () {
      final bm = BiddingManager(
        dealerIndex: 2,
        buyerCard: buyerCard,
      );

      expect(bm.currentBidder, 3); // dealer's right = (2+1)%4 = 3
      bm.placeBid(3, BidAction.pass);
      expect(bm.currentBidder, 0); // (3+1)%4 = 0
      bm.placeBid(0, BidAction.pass);
      expect(bm.currentBidder, 1); // (0+1)%4 = 1
      bm.placeBid(1, BidAction.pass);
      expect(bm.currentBidder, 2); // (1+1)%4 = 2
    });
  });

  group('Edge cases', () {
    test('bidding after finished throws InvalidMoveException', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: buyerCard);
      bm.placeBid(1, BidAction.sun);

      expect(
        () => bm.placeBid(2, BidAction.pass),
        throwsA(isA<InvalidMoveException>()),
      );
    });
  });
}
