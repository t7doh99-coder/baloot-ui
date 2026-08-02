import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/features/game/domain/baloot_game_controller.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/engines/bot_engine.dart';
import 'package:baloot_game/features/game/domain/managers/bidding_manager.dart';

void main() {
  test('DoubleStatus is preserved when skipping Double Window', () {
    final controller = BalootGameController();
    controller.startNewRound();
    // Force bidding to complete as Hakam
    controller.placeBid(1, BidAction.hakam);
    controller.placeBid(2, BidAction.pass);
    controller.placeBid(3, BidAction.pass);
    controller.placeBid(0, BidAction.pass);
    controller.placeBid(1, BidAction.confirmHakam);
    
    // Now in Double Window
    expect(controller.gamePhase, GamePhase.doubleWindow);
    
    // Seat 2 (defender) calls Double
    controller.callDouble(2, DoubleStatus.doubled);
    expect(controller.roundState.doubleStatus, DoubleStatus.doubled);
    
    // Seat 1 (buyer) calls Triple
    controller.callDouble(1, DoubleStatus.tripled);
    expect(controller.roundState.doubleStatus, DoubleStatus.tripled);
    
    // Seat 2 (defender) skips
    controller.botPlay(2); // this will call skipDoubleWindow if bot decides not to double
    
    // Check if it's playing phase and double status is STILL tripled
    expect(controller.gamePhase, GamePhase.playing);
    expect(controller.roundState.doubleStatus, DoubleStatus.tripled);
  });
}
