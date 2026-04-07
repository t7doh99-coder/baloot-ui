import '../../../data/models/card_model.dart';
import '../../../data/models/player_model.dart';

/// Abstract contract for the Baloot Game Engine.
/// Phase 2 developer: implement this interface to power the game logic.
abstract class IBalootController {
  /// Initialize a new game round
  void startNewRound();

  /// Deal 8 cards to each of the 4 players
  List<List<CardModel>> dealCards();

  /// Process a player's bid (e.g., Sun, Hokm, Pass)
  void makeBid(PlayerModel player, String bidType);

  /// Play a single card from a player's hand
  void playCard(PlayerModel player, CardModel card);

  /// Evaluate the trick winner based on played cards
  PlayerModel evaluateTrick(List<CardModel> playedCards, Suit? trumpSuit);

  /// Calculate scores at the end of a round
  Map<String, int> calculateScore();

  /// Check if the game has ended (one team reached target score)
  bool isGameOver();

  /// Get the current game state snapshot
  Map<String, dynamic> getGameState();
}
