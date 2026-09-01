import '../../../../data/models/card_model.dart';
import '../../../../data/models/card_play_model.dart';

/// Represents the specific type of violation a player is challenging.
enum QaydhaViolationType {
  /// قاطع - Opponent played a different suit when they had cards of the led suit
  qate,
  
  /// ربع في الدبل - Opponent started a trick with a trump card when Double was active
  rubFiAlDubl,
  
  /// ما كبر بحكم - Opponent had a HIGHER trump card but didn't play it
  maKabbarBiHakam,
  
  /// ما دق بحكم - Opponent didn't trump when they had no suit cards but did have trump cards
  maDaqBiHakam,
  
  /// إكة خاطئة - Opponent claimed Ekka but didn't have the highest remaining card in that suit
  falseEkka,
}

/// Represents the final outcome of a Qaydha challenge
class QaydhaResult {
  final int challengerIndex;
  final QaydhaViolationType violationType;
  final bool isCorrect;
  final int trickIndex;
  final CardModel accusedCard;

  const QaydhaResult({
    required this.challengerIndex,
    required this.violationType,
    required this.isCorrect,
    required this.trickIndex,
    required this.accusedCard,
  });
}

/// A snapshot of a player's hand at a specific point in time
class PlayerHandSnapshot {
  final int playerIndex;
  final List<CardModel> cards;

  const PlayerHandSnapshot({
    required this.playerIndex,
    required this.cards,
  });

  factory PlayerHandSnapshot.fromCurrent(int playerIndex, List<CardModel> currentHand) {
    return PlayerHandSnapshot(
      playerIndex: playerIndex,
      cards: List.from(currentHand),
    );
  }
}

