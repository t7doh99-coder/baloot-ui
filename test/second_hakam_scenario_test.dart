import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/managers/bidding_manager.dart';
import 'package:baloot_game/features/game/domain/baloot_game_controller.dart';
import 'package:baloot_game/core/errors/game_exceptions.dart';

void main() {
  final buyerCard = const CardModel(suit: Suit.hearts, rank: Rank.nine);

  group('Kammelna Rule: Second Hokom (Hokam Thani) Test Scenarios', () {
    BiddingManager setupRound2({int dealerIndex = 3}) {
      final bm = BiddingManager(dealerIndex: dealerIndex, buyerCard: buyerCard);
      // Round 1: all 4 pass
      final firstBidder = (dealerIndex + 1) % 4;
      for (int i = 0; i < 4; i++) {
        bm.placeBid((firstBidder + i) % 4, BidAction.pass);
      }
      expect(bm.phase, BiddingPhase.round2);
      expect(bm.currentBidder, firstBidder);
      return bm;
    }

    test('Scenario 1: Player bids Second Hokom without suit -> Turn passes -> 3 passes -> Confirmation Phase allows suit selection', () {
      // Dealer is seat 3, so first bidder in R1 & R2 is seat 0 (Human)
      final bm = setupRound2(dealerIndex: 3);
      expect(bm.currentBidder, 0);

      // 1. Player bids secondHakam immediately without passing a suit
      bm.placeBid(0, BidAction.secondHakam);

      // Bid is registered as pending Hokom, turn advances to next player (seat 1)
      expect(bm.hasRound2PendingBid, true);
      expect(bm.activeRound2PendingMode, GameMode.hakam);
      expect(bm.currentBidder, 1);
      expect(bm.phase, BiddingPhase.round2);

      // 2. Next 3 players pass (giving others a chance to say Sun or Wala)
      bm.placeBid(1, BidAction.pass);
      expect(bm.currentBidder, 2);
      bm.placeBid(2, BidAction.pass);
      expect(bm.currentBidder, 3);
      bm.placeBid(3, BidAction.pass);

      // 3. Confirmation Phase reached! Turn returns to buyer (seat 0)
      expect(bm.phase, BiddingPhase.hakamConfirmation);
      expect(bm.currentBidder, 0);
      expect(bm.isRound2Confirmation, true);

      // 4. In Confirmation phase, player finalizes suit (e.g. Spades)
      bm.placeBid(0, BidAction.confirmHakam, secondHakamSuit: Suit.spades);

      // 5. Game successfully locked into Hakam mode with Spades
      expect(bm.isFinished, true);
      expect(bm.result!.mode, GameMode.hakam);
      expect(bm.result!.buyerIndex, 0);
      expect(bm.result!.trumpSuit, Suit.spades);
    });

    test('Scenario 2: Player bids Second Hokom -> Opponent overbids with Sun -> Sun takes precedence', () {
      final bm = setupRound2(dealerIndex: 3);

      // Seat 0 bids secondHakam
      bm.placeBid(0, BidAction.secondHakam);
      expect(bm.currentBidder, 1);

      // Seat 1 overbids with Sun
      bm.placeBid(1, BidAction.sun);

      // In Round 2 (non-Ace buyer card), Sun overrides immediately
      expect(bm.isFinished, true);
      expect(bm.result!.mode, GameMode.sun);
      expect(bm.result!.buyerIndex, 1);
    });

    test('Scenario 3: Second Hokom Confirmation cannot choose the turned-up card suit', () {
      final bm = setupRound2(dealerIndex: 3);
      // Floor card is hearts
      bm.placeBid(0, BidAction.secondHakam);
      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);

      expect(bm.phase, BiddingPhase.hakamConfirmation);
      expect(bm.isRound2Confirmation, true);

      // Attempting to select Hearts (the floor card suit) throws an InvalidBidException
      expect(
        () => bm.placeBid(0, BidAction.confirmHakam, secondHakamSuit: Suit.hearts),
        throwsA(isA<InvalidBidException>()),
      );
    });

    test('Scenario 4: Player bids Second Hokom -> In confirmation phase switches to Sun', () {
      final bm = setupRound2(dealerIndex: 3);
      bm.placeBid(0, BidAction.secondHakam);
      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);

      expect(bm.phase, BiddingPhase.hakamConfirmation);

      // Player switches to Sun during confirmation
      bm.placeBid(0, BidAction.sun);
      expect(bm.isFinished, true);
      expect(bm.result!.mode, GameMode.sun);
      expect(bm.result!.buyerIndex, 0);
    });

    test('Scenario 5: Last player in Round 2 (Dealer) bids Second Hokom -> Other players get a chance to overbid Sun or pass -> Then confirmation', () {
      // Dealer is seat 3. First bidder in R2 is seat 0.
      final bm = setupRound2(dealerIndex: 3);

      // Seats 0, 1, 2 pass initially in Round 2
      bm.placeBid(0, BidAction.pass);
      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.pass);
      expect(bm.currentBidder, 3); // Dealer's turn

      // Dealer bids secondHakam
      bm.placeBid(3, BidAction.secondHakam);

      // Other players get a turn to overbid Sun or pass! Turn advances to seat 0
      expect(bm.phase, BiddingPhase.round2);
      expect(bm.currentBidder, 0);

      // Seats 0, 1, 2 pass dealer's secondHakam
      bm.placeBid(0, BidAction.pass);
      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.pass);

      // Now 3 passes are reached -> Confirmation phase for dealer (seat 3)!
      expect(bm.phase, BiddingPhase.hakamConfirmation);
      expect(bm.currentBidder, 3);
      expect(bm.isRound2Confirmation, true);

      // Dealer picks Diamonds
      bm.placeBid(3, BidAction.confirmHakam, secondHakamSuit: Suit.diamonds);
      expect(bm.isFinished, true);
      expect(bm.result!.mode, GameMode.hakam);
      expect(bm.result!.trumpSuit, Suit.diamonds);
      expect(bm.result!.buyerIndex, 3);
    });

    test('Scenario 6: Full Game Controller Integration with Bot & Human', () {
      final controller = BalootGameController();
      controller.startNewGame(['Human', 'Bot 1', 'Bot 2', 'Bot 3']);
      controller.startNewRound();

      expect(controller.gamePhase, GamePhase.bidding);
      expect(controller.roundState.biddingPhase, BiddingPhase.round1);

      // Let's force all 4 players to pass Round 1
      final dealer = controller.roundState.dealerIndex;
      final firstBidder = (dealer + 1) % 4;

      for (int i = 0; i < 4; i++) {
        final seat = (firstBidder + i) % 4;
        controller.placeBid(seat, BidAction.pass);
      }

      // We should now be in Round 2
      expect(controller.roundState.biddingPhase, BiddingPhase.round2);
      final r2FirstBidder = controller.roundState.currentPlayerIndex;
      expect(r2FirstBidder, firstBidder);

      // Current player places Second Hokom without suit
      controller.placeBid(r2FirstBidder, BidAction.secondHakam);

      // Other 3 players pass
      for (int i = 1; i < 4; i++) {
        final seat = (r2FirstBidder + i) % 4;
        controller.placeBid(seat, BidAction.pass);
      }

      // Controller is now in hakamConfirmation phase and isRound2Confirmation is true
      expect(controller.roundState.biddingPhase, BiddingPhase.hakamConfirmation);
      expect(controller.isRound2Confirmation, true);
      expect(controller.roundState.currentPlayerIndex, r2FirstBidder);

      // Pick any suit different from buyer card
      final buyerSuit = controller.roundState.buyerCard!.suit;
      final validSuit = Suit.values.firstWhere((s) => s != buyerSuit);

      controller.placeBid(r2FirstBidder, BidAction.confirmHakam, secondHakamSuit: validSuit);

      // Should now be in doubleWindow or playing phase with trump set to validSuit
      expect(controller.roundState.activeMode, GameMode.hakam);
      expect(controller.roundState.trumpSuit, validSuit);
      expect(controller.roundState.buyerIndex, r2FirstBidder);
    });
  });
}
