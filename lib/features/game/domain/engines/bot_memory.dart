import 'dart:math';
import '../../../../data/models/card_model.dart';
import '../../../../data/models/bot_difficulty.dart';

// ══════════════════════════════════════════════════════════════════
//  BOT MEMORY SYSTEM
//
//  Tracks cards played and suit voidness per opponent, with accuracy
//  that scales by difficulty:
//
//    Easy   → 0% memory (forgets everything)
//    Medium → 60% trump tracking, 70% void inference
//    Hard   → 95% ALL-card tracking, 90% void inference
//
//  Reset between rounds. Fed by the game controller after every
//  card play via recordCardPlayed().
// ══════════════════════════════════════════════════════════════════

class BotMemory {
  final BotDifficulty difficulty;
  final Random _rng;

  /// Cards the bot has "seen" and remembers.
  final Set<String> _seenCards = {};

  /// Known void suits per seat index → set of suits that seat can't follow.
  final Map<int, Set<Suit>> _knownVoidSuits = {};

  /// Running count of tricks won by each team (even seats = team A, odd = team B).
  int teamATricks = 0;
  int teamBTricks = 0;

  BotMemory({required this.difficulty, Random? random})
      : _rng = random ?? Random();

  /// Record that [card] was played by [seatIndex].
  /// The bot may "forget" based on its accuracy rate.
  void recordCardPlayed(CardModel card, int seatIndex) {
    final remember = _shouldRemember(card);
    if (remember) {
      _seenCards.add(_cardKey(card));
    }
  }

  /// Record that [seatIndex] did NOT follow [leadSuit] — they are void.
  void recordVoidInSuit(int seatIndex, Suit leadSuit) {
    final accuracy = switch (difficulty) {
      BotDifficulty.easy => 0.0,
      BotDifficulty.medium => 0.70,
      BotDifficulty.hard => 0.90,
    };
    if (_rng.nextDouble() < accuracy) {
      _knownVoidSuits.putIfAbsent(seatIndex, () => {}).add(leadSuit);
    }
  }

  /// Record trick winner.
  void recordTrickWinner(int winningSeat) {
    if (winningSeat % 2 == 0) {
      teamATricks++;
    } else {
      teamBTricks++;
    }
  }

  /// Query: has [card] (by suit+rank) been played and does the bot remember?
  bool isCardPlayed(Suit suit, Rank rank) {
    if (difficulty == BotDifficulty.easy) return false; // Easy has no memory
    return _seenCards.contains(_cardKeyRaw(suit, rank));
  }

  /// Query: is [seatIndex] known to be void in [suit]?
  bool isSeatVoidIn(int seatIndex, Suit suit) {
    if (difficulty == BotDifficulty.easy) return false;
    return _knownVoidSuits[seatIndex]?.contains(suit) ?? false;
  }

  /// How many trumps does the bot remember being played?
  int countPlayedTrumps(Suit trumpSuit) {
    if (difficulty == BotDifficulty.easy) return 0;
    int count = 0;
    for (final rank in Rank.values) {
      if (_seenCards.contains(_cardKeyRaw(trumpSuit, rank))) count++;
    }
    return count;
  }

  /// Count tricks won by team of [seatIndex].
  int tricksWonByTeam(int seatIndex) {
    return (seatIndex % 2 == 0) ? teamATricks : teamBTricks;
  }

  /// Count tricks won by opponent team.
  int tricksWonByOpponentTeam(int seatIndex) {
    return (seatIndex % 2 == 0) ? teamBTricks : teamATricks;
  }

  /// Clear all memory (call between rounds).
  void reset() {
    _seenCards.clear();
    _knownVoidSuits.clear();
    teamATricks = 0;
    teamBTricks = 0;
  }

  // ── Private ──

  bool _shouldRemember(CardModel card) {
    switch (difficulty) {
      case BotDifficulty.easy:
        return false; // 0% memory
      case BotDifficulty.medium:
        // 60% chance to remember trump cards only (non-trumps forgotten)
        // We record ALL cards here; the 60% accuracy is applied at recall time
        // by simply storing with 60% probability
        return _rng.nextDouble() < 0.60;
      case BotDifficulty.hard:
        // 95% of ALL cards
        return _rng.nextDouble() < 0.95;
    }
  }

  String _cardKey(CardModel card) => '${card.suit.index}:${card.rank.index}';
  String _cardKeyRaw(Suit suit, Rank rank) => '${suit.index}:${rank.index}';
}
