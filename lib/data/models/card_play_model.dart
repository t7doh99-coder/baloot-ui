import 'card_model.dart';

/// A card that has been played, tagged with the player who played it.
class CardPlayModel {
  final CardModel card;
  final int playerIndex; // Seat 0-3

  const CardPlayModel({required this.card, required this.playerIndex});

  @override
  String toString() => 'Play(seat $playerIndex: ${card.displayName})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardPlayModel &&
          card == other.card &&
          playerIndex == other.playerIndex;

  @override
  int get hashCode => Object.hash(card, playerIndex);
}
