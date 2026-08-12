import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/features/game/domain/managers/bidding_manager.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';

void main() {
  group('Kammelna Bidding Scenarios', () {
    late CardModel standardBuyerCard;
    late CardModel aceBuyerCard;

    setUp(() {
      standardBuyerCard = const CardModel(suit: Suit.hearts, rank: Rank.king);
      aceBuyerCard = const CardModel(suit: Suit.hearts, rank: Rank.ace);
    });

    test('Scenario 1 & 2: Awal - Normal Turn Order & Options per Position', () {
      final manager = BiddingManager(dealerIndex: 0, buyerCard: standardBuyerCard);
      
      // Dealer is 0. Bidding starts with 1 (right of dealer).
      expect(manager.currentBidder, 1);
      
      // Player 1 options (NO ashkal)
      final p1Actions = manager.getAllowedActions(1);
      expect(p1Actions, containsAll([BidAction.sun, BidAction.hakam, BidAction.pass]));
      expect(p1Actions.contains(BidAction.ashkal), false);
      
      manager.placeBid(1, BidAction.pass);
      expect(manager.currentBidder, 2);

      // Player 2 options (NO ashkal)
      final p2Actions = manager.getAllowedActions(2);
      expect(p2Actions, containsAll([BidAction.sun, BidAction.hakam, BidAction.pass]));
      expect(p2Actions.contains(BidAction.ashkal), false);
      
      manager.placeBid(2, BidAction.pass);
      expect(manager.currentBidder, 3);

      // Player 3 (Sane) options (Includes ashkal)
      final p3Actions = manager.getAllowedActions(3);
      expect(p3Actions, containsAll([BidAction.sun, BidAction.hakam, BidAction.ashkal, BidAction.pass]));
      
      manager.placeBid(3, BidAction.pass);
      expect(manager.currentBidder, 0);

      // Dealer options (Includes ashkal)
      final dealerActions = manager.getAllowedActions(0);
      expect(dealerActions, containsAll([BidAction.sun, BidAction.hakam, BidAction.ashkal, BidAction.pass]));
    });

    test('Scenario 3: Awal - Dealer Options After Someone Bids Hakam', () {
      final manager = BiddingManager(dealerIndex: 0, buyerCard: standardBuyerCard);
      
      // Player 1 bids Hakam
      manager.placeBid(1, BidAction.hakam);
      
      // Player 2 must pass or sun
      manager.placeBid(2, BidAction.pass);
      
      // Player 3 (Sane) can override with Hakam, Ashkal, Sun, Pass
      final p3Actions = manager.getAllowedActions(3);
      expect(p3Actions, containsAll([BidAction.sun, BidAction.hakam, BidAction.ashkal, BidAction.pass]));
      manager.placeBid(3, BidAction.pass);
      
      // Dealer can override with Hakam, Ashkal, Sun, Pass
      final dealerActions = manager.getAllowedActions(0);
      expect(dealerActions, containsAll([BidAction.sun, BidAction.hakam, BidAction.ashkal, BidAction.pass]));
    });

    test('Scenario 4 & 5: Awal - Sun Ends Bidding Instantly with Qablak Window (Only Sun allowed)', () {
      final manager = BiddingManager(dealerIndex: 0, buyerCard: standardBuyerCard);
      
      manager.placeBid(1, BidAction.pass);
      
      // Player 2 bids Sun
      manager.placeBid(2, BidAction.sun);
      
      // Phase shifts to Qablak Intervention for Player 1
      expect(manager.phase, BiddingPhase.qablakIntervention);
      expect(manager.currentBidder, 1); // Goes back to player 1
      
      // Player 1 can ONLY steal with Sun (Qablak) or Pass (No Hakam)
      final p1Actions = manager.getAllowedActions(1);
      expect(p1Actions, containsAll([BidAction.qablak, BidAction.sun, BidAction.pass]));
      expect(p1Actions.contains(BidAction.hakam), false);
      
      // Player 1 steals
      manager.placeBid(1, BidAction.qablak);
      
      expect(manager.isFinished, true);
      expect(manager.result!.buyerIndex, 1); // Stolen by 1
      expect(manager.result!.mode, GameMode.sun);
    });

    test('Scenario 6: Thani - Options per Position', () {
      final manager = BiddingManager(dealerIndex: 0, buyerCard: standardBuyerCard);
      
      // Force Round 1 All-Pass
      manager.placeBid(1, BidAction.pass);
      manager.placeBid(2, BidAction.pass);
      manager.placeBid(3, BidAction.pass);
      manager.placeBid(0, BidAction.pass);
      
      expect(manager.phase, BiddingPhase.round2);
      expect(manager.currentBidder, 1);
      
      // Player 1 options (NO ashkal)
      final p1Actions = manager.getAllowedActions(1);
      expect(p1Actions, containsAll([BidAction.sun, BidAction.secondHakam, BidAction.pass]));
      expect(p1Actions.contains(BidAction.ashkal), false);
      
      manager.placeBid(1, BidAction.pass);
      expect(manager.currentBidder, 2);
      manager.placeBid(2, BidAction.pass);
      
      // Player 3 (Sane) options (Includes ashkal)
      final p3Actions = manager.getAllowedActions(3);
      expect(p3Actions, containsAll([BidAction.sun, BidAction.secondHakam, BidAction.ashkal, BidAction.pass]));
      manager.placeBid(3, BidAction.pass);
      
      // Dealer options (Includes ashkal)
      final dealerActions = manager.getAllowedActions(0);
      expect(dealerActions, containsAll([BidAction.sun, BidAction.secondHakam, BidAction.ashkal, BidAction.pass]));
    });

    test('Scenario 7A: Thani - Sun Locks Instantly (No Qablak for non-Ace)', () {
      final manager = BiddingManager(dealerIndex: 0, buyerCard: standardBuyerCard);
      
      // Force Round 1 All-Pass
      manager.placeBid(1, BidAction.pass);
      manager.placeBid(2, BidAction.pass);
      manager.placeBid(3, BidAction.pass);
      manager.placeBid(0, BidAction.pass);
      
      manager.placeBid(1, BidAction.pass);
      
      // Player 2 bids Sun
      manager.placeBid(2, BidAction.sun);
      
      // Should lock instantly! No qablak intervention.
      expect(manager.isFinished, true);
      expect(manager.phase, BiddingPhase.completed);
      expect(manager.result!.buyerIndex, 2);
      expect(manager.result!.mode, GameMode.sun);
    });

    test('Scenario 7B: Thani - Ace Allows Qablak', () {
      final manager = BiddingManager(dealerIndex: 0, buyerCard: aceBuyerCard); // ACE!
      
      // Force Round 1 All-Pass
      manager.placeBid(1, BidAction.pass);
      manager.placeBid(2, BidAction.pass);
      manager.placeBid(3, BidAction.pass);
      manager.placeBid(0, BidAction.pass);
      
      manager.placeBid(1, BidAction.pass);
      
      // Player 2 bids Sun
      manager.placeBid(2, BidAction.sun);
      
      // Phase shifts to Qablak Intervention for Player 1 because face-up card is an Ace
      expect(manager.phase, BiddingPhase.qablakIntervention);
      expect(manager.currentBidder, 1);
    });

    test('Scenario 8: Thani - Second Hakam Needs Confirmation', () {
      final manager = BiddingManager(dealerIndex: 0, buyerCard: standardBuyerCard);
      
      // Force Round 1 All-Pass
      manager.placeBid(1, BidAction.pass);
      manager.placeBid(2, BidAction.pass);
      manager.placeBid(3, BidAction.pass);
      manager.placeBid(0, BidAction.pass);
      
      // Player 1 bids Second Hakam (Diamonds)
      manager.placeBid(1, BidAction.secondHakam, secondHakamSuit: Suit.diamonds);
      
      // Next 3 players pass
      manager.placeBid(2, BidAction.pass);
      manager.placeBid(3, BidAction.pass);
      manager.placeBid(0, BidAction.pass);
      
      // Enters Hakam Confirmation for Player 1
      expect(manager.phase, BiddingPhase.hakamConfirmation);
      expect(manager.currentBidder, 1);
      
      manager.placeBid(1, BidAction.confirmHakam);
      expect(manager.isFinished, true);
      expect(manager.result!.mode, GameMode.hakam);
      expect(manager.result!.trumpSuit, Suit.diamonds);
    });

    test('Scenario 9: All-Pass Cancellation', () {
      final manager = BiddingManager(dealerIndex: 0, buyerCard: standardBuyerCard);
      
      // Round 1 All-Pass
      manager.placeBid(1, BidAction.pass);
      manager.placeBid(2, BidAction.pass);
      manager.placeBid(3, BidAction.pass);
      manager.placeBid(0, BidAction.pass);
      
      // Round 2 All-Pass
      manager.placeBid(1, BidAction.pass);
      manager.placeBid(2, BidAction.pass);
      manager.placeBid(3, BidAction.pass);
      manager.placeBid(0, BidAction.pass);
      
      expect(manager.isFinished, true);
      expect(manager.phase, BiddingPhase.cancelled);
      expect(manager.result, isNull);
    });

    test('Scenario 10: Ashkal Cannot Be Called on an Ace', () {
      final manager = BiddingManager(dealerIndex: 0, buyerCard: aceBuyerCard);
      
      manager.placeBid(1, BidAction.pass);
      manager.placeBid(2, BidAction.pass);
      manager.placeBid(3, BidAction.pass);
      
      // Dealer calls Ashkal on an Ace (illegal)
      manager.placeBid(0, BidAction.ashkal);
      
      // It should trigger normal Sun flow with Qablak queue
      expect(manager.phase, BiddingPhase.qablakIntervention);
      expect(manager.currentBidder, 1);
      
      manager.placeBid(1, BidAction.pass);
      manager.placeBid(2, BidAction.pass);
      manager.placeBid(3, BidAction.pass);
      
      expect(manager.isFinished, true);
      // Result is normal Sun (isAshkal: false) due to penalty conversion
      expect(manager.result!.mode, GameMode.sun);
      expect(manager.result!.isAshkal, false);
    });
  });
}
