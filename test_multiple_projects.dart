import 'package:baloot_ui/features/game/domain/baloot_game_controller.dart';
import 'package:baloot_ui/features/game/domain/engines/project_detector.dart';
import 'package:baloot_ui/data/models/card_model.dart';
import 'package:baloot_ui/data/models/round_state_model.dart';

void main() {
  final detector = ProjectDetector();
  
  // Create a hand with exactly 2 Seras (Spades sequence, Hearts sequence)
  final hand = [
    CardModel(suit: Suit.spades, rank: Rank.seven),
    CardModel(suit: Suit.spades, rank: Rank.eight),
    CardModel(suit: Suit.spades, rank: Rank.nine), // Sera 1
    
    CardModel(suit: Suit.hearts, rank: Rank.seven),
    CardModel(suit: Suit.hearts, rank: Rank.eight),
    CardModel(suit: Suit.hearts, rank: Rank.nine), // Sera 2
    
    CardModel(suit: Suit.clubs, rank: Rank.seven),
    CardModel(suit: Suit.clubs, rank: Rank.eight),
  ];
  
  final projects = detector.detectAll(hand, GameMode.sun);
  
  print('Detected Projects:');
  for (final p in projects) {
    print('- ${p.type} (${p.cards.length} cards)');
  }
}
