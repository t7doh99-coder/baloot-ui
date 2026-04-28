import '../../../../data/models/card_model.dart';

class SawaProbabilityEngine {
  /// Checks whether the player holds only **master** cards — guaranteed winners
  /// when leading each remaining trick (Kammelna **Sawa يد**).
  ///
  /// When [allHands] is passed (four 8‑card lists), Hakam trump risk uses full info:
  /// a trump can only cut if **not** uniquely held by partner among “others”.
  /// If [allHands] is omitted, Hakam behaves conservatively (any unseen trump ⇒ risk).
  static bool canSawaYad({
    required int playerSeat,
    required List<CardModel> playerHand,
    required List<CardModel> playedCards,
    required GameMode mode,
    required Suit? trumpSuit,
    List<List<CardModel>>? allHands,
  }) {
    if (playerHand.isEmpty) return false;

    final myCards = playerHand.toSet();

    final unplayedOtherCards = <CardModel>{};
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        final c = CardModel(suit: suit, rank: rank);
        if (!playedCards.contains(c) && !myCards.contains(c)) {
          unplayedOtherCards.add(c);
        }
      }
    }

    bool opponentsMayCutNonTrumpLead(CardModel card) {
      if (mode != GameMode.hakam || trumpSuit == null) return false;
      if (card.suit == trumpSuit) return false;

      if (allHands != null && allHands.length == 4) {
        final partnerSeat = (playerSeat + 2) % 4;
        for (final c in unplayedOtherCards) {
          if (c.suit != trumpSuit) continue;
          if (allHands[partnerSeat].contains(c)) continue;
          return true;
        }
        return false;
      }

      for (final c in unplayedOtherCards) {
        if (c.suit == trumpSuit) return true;
      }
      return false;
    }

    for (final card in playerHand) {
      final strength = card.getStrength(mode: mode, trumpSuit: trumpSuit);
      final isTrump = mode == GameMode.hakam && card.suit == trumpSuit;

      if (mode == GameMode.hakam && !isTrump && opponentsMayCutNonTrumpLead(card)) {
        return false;
      }

      final unplayedInSuit = unplayedOtherCards.where((c) => c.suit == card.suit);
      for (final otherCard in unplayedInSuit) {
        final otherStrength = otherCard.getStrength(mode: mode, trumpSuit: trumpSuit);
        if (otherStrength > strength) {
          return false;
        }
      }
    }

    return true;
  }
}
