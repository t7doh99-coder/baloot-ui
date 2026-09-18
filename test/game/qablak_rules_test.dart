import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/managers/bidding_manager.dart';

void main() {
  group('Kammelna Qablak Rules Parity Tests (BiddingManager)', () {
    test('1. Round 1 Sun Buy: Earlier seat can steal via Qablak', () {
      final buyerCard = const CardModel(suit: Suit.diamonds, rank: Rank.ten);
      final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);

      // Bidding starts at dealer+1 = Seat 0.
      expect(bm.currentBidder, 0);

      // Seat 0: pass
      bm.placeBid(0, BidAction.pass);
      
      // Seat 1: pass
      bm.placeBid(1, BidAction.pass);
      
      // Seat 2: Sun
      bm.placeBid(2, BidAction.sun);

      expect(bm.phase, BiddingPhase.qablakIntervention, reason: 'Qablak intervention window should open');
      expect(bm.currentBidder, 0, reason: 'Qablak starts with Seat 0 (lowest priority index)');

      // Seat 0 calls Qablak
      bm.placeBid(0, BidAction.qablak);

      expect(bm.isFinished, true);
      expect(bm.result!.buyerIndex, 0, reason: 'Seat 0 should successfully steal the Sun bid');
      expect(bm.result!.mode, GameMode.sun);
    });

    test('2. Round 1 Sun Buy: Only earlier seats can steal, later seats have no right', () {
      final buyerCard = const CardModel(suit: Suit.diamonds, rank: Rank.ten);
      final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);

      // Seat 0: pass
      bm.placeBid(0, BidAction.pass);
      
      // Seat 1: Sun
      bm.placeBid(1, BidAction.sun);

      expect(bm.phase, BiddingPhase.qablakIntervention, reason: 'Qablak intervention window should open for Seat 0');
      expect(bm.currentBidder, 0);

      // Seat 0 passes
      bm.placeBid(0, BidAction.pass);

      // Window should close because Seat 2 and 3 do not have Qablak rights against Seat 1
      expect(bm.isFinished, true);
      expect(bm.result!.buyerIndex, 1, reason: 'Seat 1 keeps the bid');
    });

    test('3. Round 1 Ashkal Buy: Stolen Ashkal converts to standard Sun', () {
      final buyerCard = const CardModel(suit: Suit.diamonds, rank: Rank.ten);
      final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);

      // Seat 0, 1, 2: pass
      bm.placeBid(0, BidAction.pass);
      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.pass);
      
      // Seat 3 (Dealer): Ashkal
      bm.placeBid(3, BidAction.ashkal);

      expect(bm.phase, BiddingPhase.qablakIntervention);
      
      // Seat 0 passes
      bm.placeBid(0, BidAction.pass);
      
      // Seat 1 calls Qablak
      bm.placeBid(1, BidAction.qablak);

      expect(bm.isFinished, true);
      expect(bm.result!.buyerIndex, 1, reason: 'Seat 1 steals the bid');
      expect(bm.result!.mode, GameMode.sun);
      expect(bm.result!.isAshkal, false, reason: 'Stolen Ashkal becomes standard Sun');
    });

    test('4. Round 2 Qablak is allowed on Aces', () {
      final buyerCard = const CardModel(suit: Suit.diamonds, rank: Rank.ace);
      final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);

      // R1: all pass
      bm.placeBid(0, BidAction.pass);
      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);

      expect(bm.phase, BiddingPhase.round2);

      // R2:
      // Seat 0: pass
      // Seat 1: pass
      // Seat 2: Sun
      bm.placeBid(0, BidAction.pass);
      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.sun);

      expect(bm.phase, BiddingPhase.qablakIntervention, reason: 'Qablak is allowed in R2 because the face-up card is an Ace');
      
      // Seat 0 calls Qablak
      bm.placeBid(0, BidAction.qablak);

      expect(bm.isFinished, true);
      expect(bm.result!.buyerIndex, 0);
    });

    test('5. Round 2 Qablak is NOT allowed on non-Aces', () {
      final buyerCard = const CardModel(suit: Suit.diamonds, rank: Rank.king);
      final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);

      // R1: all pass
      bm.placeBid(0, BidAction.pass);
      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);

      expect(bm.phase, BiddingPhase.round2);

      // R2:
      // Seat 0: pass
      // Seat 1: pass
      // Seat 2: Sun
      bm.placeBid(0, BidAction.pass);
      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.sun);

      expect(bm.phase, BiddingPhase.completed, reason: 'Qablak is NOT allowed in R2 on non-Aces, bid is locked immediately');
      expect(bm.isFinished, true);
      expect(bm.result!.buyerIndex, 2, reason: 'Seat 2 keeps the bid');
    });
  });
}
