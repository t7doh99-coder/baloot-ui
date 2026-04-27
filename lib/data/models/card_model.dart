enum Suit { hearts, diamonds, spades, clubs }

enum Rank { seven, eight, nine, ten, jack, queen, king, ace }

/// Game modes that affect card values and rankings.
enum GameMode { sun, hakam }

class CardModel {
  final Suit suit;
  final Rank rank;

  const CardModel({required this.suit, required this.rank});

  /// Dynamic point value based on game mode and trump suit.
  ///
  /// In Hakam, trump-suit Jack = 20, trump-suit 9 = 14.
  /// In Sun or non-trump suits, standard values apply.
  int getPointValue({required GameMode mode, Suit? trumpSuit}) {
    if (mode == GameMode.hakam && suit == trumpSuit) {
      return _hakamTrumpPoints[rank]!;
    }
    return _standardPoints[rank]!;
  }

  /// Strength rank for trick comparison (higher = stronger).
  ///
  /// Hakam trump suit uses J>9>A>10>K>Q>8>7.
  /// Sun / non-trump uses A>10>K>Q>J>9>8>7.
  int getStrength({required GameMode mode, Suit? trumpSuit}) {
    if (mode == GameMode.hakam && suit == trumpSuit) {
      return _hakamTrumpStrength[rank]!;
    }
    return _standardStrength[rank]!;
  }

  String get displayName => '${rank.name.toUpperCase()} of ${suit.name}';

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModel && suit == other.suit && rank == other.rank;

  @override
  int get hashCode => Object.hash(suit, rank);

  /// Sorts cards by Suit and then by Rank descending.
  int compareTo(CardModel other) {
    // Suit sorting order as requested: Hearts, Diamonds, Spades, Clubs
    // (Note: This groups Red/Red and Black/Black suits together)
    const suitOrder = {
      Suit.hearts: 0,
      Suit.diamonds: 1,
      Suit.spades: 2,
      Suit.clubs: 3,
    };
    
    int suitCmp = suitOrder[suit]!.compareTo(suitOrder[other.suit]!);
    if (suitCmp != 0) return suitCmp;

    // Rank order for projects (A, K, Q, J, 10, 9, 8, 7)
    // This ensures that sequences like A-K-Q-J-10 (100 project) are always contiguous.
    return other.rank.index.compareTo(rank.index);
  }

  // ── Lookup tables (from BALOOT_RULES.md Section 3) ──

  static const _standardPoints = {
    Rank.seven: 0,
    Rank.eight: 0,
    Rank.nine: 0,
    Rank.ten: 10,
    Rank.jack: 2,
    Rank.queen: 3,
    Rank.king: 4,
    Rank.ace: 11,
  };

  static const _hakamTrumpPoints = {
    Rank.seven: 0,
    Rank.eight: 0,
    Rank.nine: 14,
    Rank.ten: 10,
    Rank.jack: 20,
    Rank.queen: 3,
    Rank.king: 4,
    Rank.ace: 11,
  };

  /// Standard strength: A>10>K>Q>J>9>8>7
  static const _standardStrength = {
    Rank.seven: 0,
    Rank.eight: 1,
    Rank.nine: 2,
    Rank.jack: 3,
    Rank.queen: 4,
    Rank.king: 5,
    Rank.ten: 6,
    Rank.ace: 7,
  };

  /// Hakam trump strength: J>9>A>10>K>Q>8>7
  static const _hakamTrumpStrength = {
    Rank.seven: 0,
    Rank.eight: 1,
    Rank.queen: 2,
    Rank.king: 3,
    Rank.ten: 4,
    Rank.ace: 5,
    Rank.nine: 6,
    Rank.jack: 7,
  };
}
