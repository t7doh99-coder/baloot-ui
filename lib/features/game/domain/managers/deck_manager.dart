import 'dart:math';
import '../../../../data/models/card_model.dart';

/// Manages the 32-card Baloot deck: creation, shuffling, Kut (cut),
/// and the two-phase dealing sequence per BALOOT_RULES.md Section 2.
class DeckManager {
  final Random _rng;
  late List<CardModel> _deck;
  late List<List<CardModel>> _hands; // 4 players, index 0-3
  CardModel? _buyerCard;

  DeckManager({Random? random}) : _rng = random ?? Random() {
    _deck = [];
    _hands = List.generate(4, (_) => []);
  }

  /// The revealed buyer card (Mustari). Null before dealInitial().
  CardModel? get buyerCard => _buyerCard;

  /// Current hands for each player (index 0-3).
  List<List<CardModel>> get hands => _hands;

  /// Cards remaining in the deck after dealing phases.
  int get remainingCards => _deck.length;

  /// Build the standard 32-card deck (7 through Ace, 4 suits).
  void createDeck() {
    _deck = [
      for (final suit in Suit.values)
        for (final rank in Rank.values) CardModel(suit: suit, rank: rank),
    ];
    _hands = List.generate(4, (_) => []);
    _buyerCard = null;
  }

  /// Fisher-Yates shuffle.
  void shuffle() {
    for (int i = _deck.length - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      final temp = _deck[i];
      _deck[i] = _deck[j];
      _deck[j] = temp;
    }
  }

  /// Kut (cut): split deck at a random point and swap halves.
  /// Per BALOOT_RULES.md: "Randomized background split."
  void kut() {
    if (_deck.length < 2) return;
    final cutPoint = _rng.nextInt(_deck.length - 1) + 1; // 1 to length-1
    _deck = [..._deck.sublist(cutPoint), ..._deck.sublist(0, cutPoint)];
  }

  /// Phase 1 of dealing per BALOOT_RULES.md Section 2:
  /// 1. Deal 3 cards to each player (counter-clockwise from dealer's right)
  /// 2. Deal 2 cards to each player
  /// 3. Reveal 1 buyer card
  ///
  /// After this: each player has 5 cards, 1 buyer card revealed, 11 remain.
  void dealInitial(int dealerIndex) {
    _hands = List.generate(4, (_) => []);
    _buyerCard = null;

    // Deal to dealer's right first, then continue clockwise on screen
    // (= counter-clockwise at a real table).
    // Screen seats: 0=bottom, 1=right, 2=top, 3=left → +1 = right.
    final order = List.generate(4, (i) => (dealerIndex + 1 + i) % 4);

    // Deal 3 cards to each
    for (final seat in order) {
      for (int i = 0; i < 3; i++) {
        _hands[seat].add(_deck.removeAt(0));
      }
    }

    // Deal 2 more cards to each
    for (final seat in order) {
      for (int i = 0; i < 2; i++) {
        _hands[seat].add(_deck.removeAt(0));
      }
    }

    // Reveal 1 buyer card
    _buyerCard = _deck.removeAt(0);
  }

  /// Phase 2 of dealing after bidding resolves.
  ///
  /// [buyerIndex]: seat of the winning bidder.
  /// [isAshkal]: if true, the buyer's teammate receives the buyer card.
  ///
  /// - Recipient gets buyerCard + 2 more cards from deck (total 3 new = 8 total)
  /// - Other 3 players each get 3 cards from deck (total 3 new = 8 total)
  ///
  /// After this: all players have 8 cards, deck is empty.
  void dealRemainder(int buyerIndex, {bool isAshkal = false}) {
    // Determine who receives the buyer card
    final recipientIndex =
        isAshkal ? _teammateOf(buyerIndex) : buyerIndex;

    final dealOrder = List.generate(4, (i) => (buyerIndex + 1 + i) % 4);

    for (final seat in dealOrder) {
      if (seat == recipientIndex) {
        // Recipient gets buyer card + 2 from deck
        _hands[seat].add(_buyerCard!);
        for (int i = 0; i < 2; i++) {
          _hands[seat].add(_deck.removeAt(0));
        }
      } else {
        // Others get 3 from deck
        for (int i = 0; i < 3; i++) {
          _hands[seat].add(_deck.removeAt(0));
        }
      }
    }
  }

  /// Teammate sits across: seat 0<->2, seat 1<->3.
  int _teammateOf(int seatIndex) => (seatIndex + 2) % 4;
}
