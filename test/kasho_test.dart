import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/managers/bidding_manager.dart';

void main() {
  test('Kasho test - garbage hand allows Kasho and cancels round', () {
    final manager = BiddingManager(
      dealerIndex: 0,
      buyerCard: CardModel(suit: Suit.hearts, rank: Rank.king),
    );

    // Call placeBid with Kasho. (The check for 7/8/9 is actually in UI before allowing it)
    manager.placeBid(1, BidAction.kasho);
    
    expect(manager.phase, equals(BiddingPhase.cancelled));
    expect(manager.result?.isKasho, equals(true));
    expect(manager.result?.buyerIndex, equals(1));
  });
}
