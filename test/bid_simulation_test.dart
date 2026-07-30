// Quick simulation: how often does Hakam get bought in Round 1?
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import '../lib/data/models/card_model.dart';
import '../lib/features/game/domain/engines/bot_engine.dart';
import '../lib/features/game/domain/managers/deck_manager.dart';
import '../lib/features/game/domain/managers/bidding_manager.dart';
import '../lib/data/models/round_state_model.dart';

void main() {
  test('Simulate 1000 deals and count Hakam vs Sun vs Pass-all', () {
    final rng = Random(42);
    final bot = const BotEngine();
    int hakamR1 = 0;
    int sunR1 = 0;
    int sunR2 = 0;
    int secondHakamR2 = 0;
    int allPassCancelled = 0;

    for (int trial = 0; trial < 1000; trial++) {
      final dm = DeckManager(random: rng);
      dm.createDeck();
      dm.shuffle();
      dm.kut();

      final dealer = trial % 4;
      dm.dealInitial(dealer);

      final hands = dm.hands.map((h) => List<CardModel>.from(h)).toList();
      final buyerCard = dm.buyerCard!;

      // Simulate Round 1
      final bm = BiddingManager(dealerIndex: dealer, buyerCard: buyerCard);
      bool resolved = false;

      // Round 1: 4 players bid
      while (!bm.isFinished && bm.phase == BiddingPhase.round1) {
        final seat = bm.currentBidder;
        final decision = bot.decideBid(
          hand: hands[seat],
          buyerCard: buyerCard,
          phase: bm.phase,
          seatIndex: seat,
          dealerIndex: dealer,
          round1HakamBidderSeat: bm.hasActiveHakamBid ? bm.activeRound1HakamSeat : null,
        );
        bm.placeBid(seat, decision.action, secondHakamSuit: decision.secondHakamSuit);
      }

      // Handle Hakam Confirmation
      if (bm.phase == BiddingPhase.hakamConfirmation) {
        final seat = bm.currentBidder;
        final decision = bot.decideBid(
          hand: hands[seat],
          buyerCard: buyerCard,
          phase: bm.phase,
          seatIndex: seat,
          dealerIndex: dealer,
        );
        bm.placeBid(seat, decision.action);
      }

      if (bm.isFinished && bm.result != null) {
        if (bm.result!.mode == GameMode.hakam) hakamR1++;
        if (bm.result!.mode == GameMode.sun) sunR1++;
        continue;
      }

      // Round 2
      while (!bm.isFinished && bm.phase == BiddingPhase.round2) {
        final seat = bm.currentBidder;
        final decision = bot.decideBid(
          hand: hands[seat],
          buyerCard: buyerCard,
          phase: bm.phase,
          seatIndex: seat,
          dealerIndex: dealer,
          round2PendingBid: bm.hasRound2PendingBid,
          round2PendingBuyerSeat: bm.activeRound2PendingBuyerSeat,
          round2PendingMode: bm.activeRound2PendingMode,
          round2PendingTrump: bm.activeRound2PendingTrump,
        );
        bm.placeBid(seat, decision.action, secondHakamSuit: decision.secondHakamSuit);
      }

      // Handle R2 Hakam Confirmation
      if (bm.phase == BiddingPhase.hakamConfirmation) {
        final seat = bm.currentBidder;
        final decision = bot.decideBid(
          hand: hands[seat],
          buyerCard: buyerCard,
          phase: bm.phase,
          seatIndex: seat,
          dealerIndex: dealer,
        );
        bm.placeBid(seat, decision.action);
      }

      if (bm.isFinished && bm.result != null) {
        if (bm.result!.mode == GameMode.sun) sunR2++;
        if (bm.result!.mode == GameMode.hakam) secondHakamR2++;
      } else {
        allPassCancelled++;
      }
    }

    print('=== 1000 Deal Simulation Results ===');
    print('Hakam (R1):        $hakamR1  (${(hakamR1 / 10).toStringAsFixed(1)}%)');
    print('Sun (R1):          $sunR1  (${(sunR1 / 10).toStringAsFixed(1)}%)');
    print('Sun (R2):          $sunR2  (${(sunR2 / 10).toStringAsFixed(1)}%)');
    print('Second Hakam (R2): $secondHakamR2  (${(secondHakamR2 / 10).toStringAsFixed(1)}%)');
    print('All-Pass Cancel:   $allPassCancelled  (${(allPassCancelled / 10).toStringAsFixed(1)}%)');
    print('---');
    print('Total Hakam:       ${hakamR1 + secondHakamR2}  (${((hakamR1 + secondHakamR2) / 10).toStringAsFixed(1)}%)');
    print('Total Sun:         ${sunR1 + sunR2}  (${((sunR1 + sunR2) / 10).toStringAsFixed(1)}%)');
  });
}
