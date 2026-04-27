import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/card_play_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';

void main() {
  // Test evaluation logic exactly as it is in TurnManager
  CardPlayModel highestOfSuit(List<CardPlayModel> trick, GameMode mode, Suit? trumpSuit, Suit suit) {
    final suitPlays = trick.where((p) => p.card.suit == suit);
    return suitPlays.reduce((a, b) {
      final aStr = a.card.getStrength(mode: mode, trumpSuit: trumpSuit);
      final bStr = b.card.getStrength(mode: mode, trumpSuit: trumpSuit);
      return aStr >= bStr ? a : b;
    });
  }

  TrickResult evaluateTrick(List<CardPlayModel> trick, GameMode mode, Suit? trumpSuit) {
    final leadingSuit = trick.first.card.suit;
    CardPlayModel winner = trick.first;

    if (mode == GameMode.hakam && trumpSuit != null) {
      final trumpPlays = trick.where((p) => p.card.suit == trumpSuit);
      if (trumpPlays.isNotEmpty) {
        winner = trumpPlays.reduce((a, b) {
          final aStr = a.card.getStrength(mode: GameMode.hakam, trumpSuit: trumpSuit);
          final bStr = b.card.getStrength(mode: GameMode.hakam, trumpSuit: trumpSuit);
          return aStr >= bStr ? a : b;
        });
      } else {
        winner = highestOfSuit(trick, mode, trumpSuit, leadingSuit);
      }
    } else {
      winner = highestOfSuit(trick, mode, trumpSuit, leadingSuit);
    }
    
    return TrickResult(
      winnerIndex: winner.playerIndex,
      cards: trick,
      abnat: 0,
      isLastTrick: false,
      lastTrickBonus: 0,
    );
  }

  // Scenario 1: Sun mode. P0 leads 10 Clubs. P1 A Hearts, P2 K Clubs, P3 7 Clubs.
  // P0 should win because 10 > K > 7, and A Hearts is off-suit.
  final trick1 = [
    CardPlayModel(card: CardModel(suit: Suit.clubs, rank: Rank.ten), playerIndex: 0),
    CardPlayModel(card: CardModel(suit: Suit.hearts, rank: Rank.ace), playerIndex: 1),
    CardPlayModel(card: CardModel(suit: Suit.clubs, rank: Rank.king), playerIndex: 2),
    CardPlayModel(card: CardModel(suit: Suit.clubs, rank: Rank.seven), playerIndex: 3),
  ];
  final r1 = evaluateTrick(trick1, GameMode.sun, null);
  print('Scenario 1 Winner: ${r1.winnerIndex} (Expected 0)');

  // Scenario 2: Hakam Hearts. P2 leads 8 Spades. P3 K Spades, P0 7 Hearts (trump), P1 A Spades.
  // P0 should win because they trumped.
  final trick2 = [
    CardPlayModel(card: CardModel(suit: Suit.spades, rank: Rank.eight), playerIndex: 2),
    CardPlayModel(card: CardModel(suit: Suit.spades, rank: Rank.king), playerIndex: 3),
    CardPlayModel(card: CardModel(suit: Suit.hearts, rank: Rank.seven), playerIndex: 0),
    CardPlayModel(card: CardModel(suit: Suit.spades, rank: Rank.ace), playerIndex: 1),
  ];
  final r2 = evaluateTrick(trick2, GameMode.hakam, Suit.hearts);
  print('Scenario 2 Winner: ${r2.winnerIndex} (Expected 0)');

  // Scenario 3: Sun mode. P1 leads 9 Diamonds. P2 10 Diamonds, P3 A Diamonds, P0 8 Diamonds.
  // P3 should win because A > 10 > 9 > 8.
  final trick3 = [
    CardPlayModel(card: CardModel(suit: Suit.diamonds, rank: Rank.nine), playerIndex: 1),
    CardPlayModel(card: CardModel(suit: Suit.diamonds, rank: Rank.ten), playerIndex: 2),
    CardPlayModel(card: CardModel(suit: Suit.diamonds, rank: Rank.ace), playerIndex: 3),
    CardPlayModel(card: CardModel(suit: Suit.diamonds, rank: Rank.eight), playerIndex: 0),
  ];
  final r3 = evaluateTrick(trick3, GameMode.sun, null);
  print('Scenario 3 Winner: ${r3.winnerIndex} (Expected 3)');
}

class TrickResult {
  final int winnerIndex;
  final List<CardPlayModel> cards;
  final int abnat;
  final bool isLastTrick;
  final int lastTrickBonus;
  TrickResult({required this.winnerIndex, required this.cards, required this.abnat, required this.isLastTrick, required this.lastTrickBonus});
}
