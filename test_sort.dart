enum Suit { hearts, diamonds, spades, clubs }
enum Rank { seven, eight, nine, ten, jack, queen, king, ace }

class CardModel {
  final Suit suit;
  final Rank rank;

  const CardModel({required this.suit, required this.rank});

  int compareTo(CardModel other) {
    const suitOrder = {
      Suit.hearts: 0,
      Suit.diamonds: 1,
      Suit.spades: 2,
      Suit.clubs: 3,
    };
    int suitCmp = suitOrder[suit]!.compareTo(suitOrder[other.suit]!);
    if (suitCmp != 0) return suitCmp;
    return other.rank.index.compareTo(rank.index);
  }

  @override
  String toString() => '${rank.name}';
}

void main() {
  List<CardModel> cards = [
    const CardModel(suit: Suit.hearts, rank: Rank.ten),
    const CardModel(suit: Suit.hearts, rank: Rank.king),
    const CardModel(suit: Suit.hearts, rank: Rank.ace),
    const CardModel(suit: Suit.hearts, rank: Rank.jack),
    const CardModel(suit: Suit.hearts, rank: Rank.queen),
    const CardModel(suit: Suit.hearts, rank: Rank.nine),
    const CardModel(suit: Suit.hearts, rank: Rank.eight),
    const CardModel(suit: Suit.hearts, rank: Rank.seven),
  ];
  
  cards.sort((a, b) => a.compareTo(b));
  print("Sorted: $cards");
}
