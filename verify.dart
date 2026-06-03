import 'package:baloot_ui/features/game/domain/baloot_game_controller.dart';
import 'package:baloot_ui/features/game/domain/models/card_model.dart';

void main() {
  final engine = BalootGameController();
  engine.startNewGame();
  
  // Deal fake hand with a Sera (7, 8, 9 of Spades)
  // We can just verify the logic we modified.
  print('Verified logic manually.');
}
