import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/features/game/domain/baloot_game_controller.dart';
import 'package:baloot_game/features/game/domain/managers/bidding_manager.dart';

void main() {
  print('Starting Akka test...');
  
  final controller = BalootGameController();
  controller.startNewGame(['A', 'B', 'C', 'D']);
  controller.startNewRound();
  
  // Force Hakam mode (Spades)
  controller.testForceSetMode(GameMode.hakam, Suit.spades, 0); // Assuming such a method exists, wait, it doesn't.
}
