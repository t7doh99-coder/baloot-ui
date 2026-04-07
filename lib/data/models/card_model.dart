/// Represents a playing card in the Baloot deck
enum Suit { hearts, diamonds, spades, clubs }

enum Rank { seven, eight, nine, ten, jack, queen, king, ace }

class CardModel {
  final Suit suit;
  final Rank rank;

  const CardModel({
    required this.suit,
    required this.rank,
  });

  /// Point value of the card (Baloot standard scoring)
  int get value {
    switch (rank) {
      case Rank.seven:
        return 0;
      case Rank.eight:
        return 0;
      case Rank.nine:
        return 0;
      case Rank.ten:
        return 10;
      case Rank.jack:
        return 2;
      case Rank.queen:
        return 3;
      case Rank.king:
        return 4;
      case Rank.ace:
        return 11;
    }
  }

  /// Display name for the card
  String get displayName => '${rank.name.toUpperCase()} of ${suit.name}';

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModel && suit == other.suit && rank == other.rank;

  @override
  int get hashCode => Object.hash(suit, rank);
}
