import '../../../../data/models/card_model.dart';
import '../../../../data/models/round_state_model.dart';
import '../managers/turn_manager.dart';
import '../models/qaydha_models.dart';

class QaydhaEngine {
  /// Evaluates a Qaydha challenge and returns the result.
  static QaydhaResult evaluateChallenge({
    required List<TrickResult> history,
    required int challengerIndex,
    required int trickIndex,
    required int accusedSeatIndex,
    required QaydhaViolationType violationType,
    required GameMode gameMode,
    required Suit? trumpSuit,
    required DoubleStatus doubleStatus,
    int? proofCardIndex, // The specific card the challenger pointed out
  }) {
    if (trickIndex < 0 || trickIndex >= history.length) {
      throw ArgumentError('Invalid trick index');
    }

    final trick = history[trickIndex];
    
    // Find the accused player's play in this trick
    final accusedPlayIndex = trick.cards.indexWhere((p) => p.playerIndex == accusedSeatIndex);
    if (accusedPlayIndex == -1) {
      throw ArgumentError('Accused player did not play in this trick');
    }
    
    final accusedPlay = trick.cards[accusedPlayIndex];
    final handSnapshot = trick.handsAtStartOfTrick?[accusedSeatIndex];
    
    if (handSnapshot == null) {
      throw ArgumentError('No hand snapshot found for accused player');
    }

    bool isCorrect = false;

    switch (violationType) {
      case QaydhaViolationType.qate:
        isCorrect = _checkQate(trick, accusedPlayIndex, handSnapshot, proofCardIndex);
        break;
      case QaydhaViolationType.rubFiAlDubl:
        isCorrect = _checkRubFiAlDubl(trick, accusedPlayIndex, doubleStatus, trumpSuit);
        break;
      case QaydhaViolationType.maKabbarBiHakam:
        isCorrect = _checkMaKabbarBiHakam(trick, accusedPlayIndex, handSnapshot, mode: gameMode, trumpSuit: trumpSuit, proofCardIndex: proofCardIndex);
        break;
      case QaydhaViolationType.maDaqBiHakam:
        isCorrect = _checkMaDaqBiHakam(trick, accusedPlayIndex, handSnapshot, mode: gameMode, trumpSuit: trumpSuit, proofCardIndex: proofCardIndex);
        break;
      case QaydhaViolationType.falseEkka:
        isCorrect = _checkFalseEkka(history, trickIndex, accusedPlayIndex, gameMode, trumpSuit);
        break;
    }

    return QaydhaResult(
      challengerIndex: challengerIndex,
      violationType: violationType,
      isCorrect: isCorrect,
      trickIndex: trickIndex,
      accusedCard: accusedPlay.card,
    );
  }

  /// قاطع - Opponent played a different suit when they had cards of the led suit
  /// قاطع - Opponent played a different suit when they had cards of the led suit
  static bool _checkQate(TrickResult trick, int accusedPlayIndex, List<CardModel> hand, int? proofCardIndex) {
    if (accusedPlayIndex == 0) return false; // Can't fail to follow suit if you led
    
    final ledSuit = trick.cards[0].card.suit;
    final playedCard = trick.cards[accusedPlayIndex].card;
    
    // Did they play a different suit?
    if (playedCard.suit == ledSuit) return false;
    
    // Check if the specifically selected proof card proves the violation
    if (proofCardIndex != null && proofCardIndex >= 0 && proofCardIndex < hand.length) {
      final proofCard = hand[proofCardIndex];
      return proofCard.suit == ledSuit;
    }
    
    return false;
  }

  /// ربع في الدبل - Opponent started a trick with a trump card when Double was active
  static bool _checkRubFiAlDubl(TrickResult trick, int accusedPlayIndex, DoubleStatus doubleStatus, Suit? trumpSuit) {
    if (doubleStatus == DoubleStatus.none) return false;
    if (trumpSuit == null) return false; // Only in Hakam
    if (accusedPlayIndex != 0) return false; // Only applies to leading a trick
    
    final playedCard = trick.cards[accusedPlayIndex].card;
    return playedCard.suit == trumpSuit;
  }

  /// ما كبر بحكم - Opponent had a HIGHER trump card but didn't play it
  /// ما كبر بحكم - Opponent had a HIGHER trump card but didn't play it
  static bool _checkMaKabbarBiHakam(TrickResult trick, int accusedPlayIndex, List<CardModel> hand, {required GameMode mode, required Suit? trumpSuit, required int? proofCardIndex}) {
    if (mode != GameMode.hakam || trumpSuit == null) return false;
    if (accusedPlayIndex == 0) return false;
    
    final ledSuit = trick.cards[0].card.suit;
    final playedCard = trick.cards[accusedPlayIndex].card;
    final accusedSeat = trick.cards[accusedPlayIndex].playerIndex;
    
    // Find the highest trump played BEFORE the accused
    CardModel? highestTrumpBefore;
    int? highestTrumpOwner;
    for (int i = 0; i < accusedPlayIndex; i++) {
      final card = trick.cards[i].card;
      if (card.suit == trumpSuit) {
        if (highestTrumpBefore == null || 
            card.getStrength(mode: mode, trumpSuit: trumpSuit) > highestTrumpBefore.getStrength(mode: mode, trumpSuit: trumpSuit)) {
          highestTrumpBefore = card;
          highestTrumpOwner = trick.cards[i].playerIndex;
        }
      }
    }
    
    // If no one played a trump before them, they can't have failed to over-trump
    if (highestTrumpBefore == null) return false;

    // Is the highest trump currently held by the accused player's partner?
    // In Baloot, you are NOT forced to over-trump your own partner.
    final bool isPartnerWinning = highestTrumpOwner != null && (highestTrumpOwner % 2 == accusedSeat % 2);
    if (isPartnerWinning) return false;
    
    // Get the selected proof card
    if (proofCardIndex == null || proofCardIndex < 0 || proofCardIndex >= hand.length) return false;
    final proofCard = hand[proofCardIndex];

    final highestBeforeStrength = highestTrumpBefore.getStrength(mode: mode, trumpSuit: trumpSuit);

    // Did the player play a trump?
    if (playedCard.suit == trumpSuit) {
      final playedStrength = playedCard.getStrength(mode: mode, trumpSuit: trumpSuit);
      
      // They didn't over-trump the opponent. Does the proof card prove they had a higher one?
      if (playedStrength < highestBeforeStrength) {
        return proofCard.suit == trumpSuit && 
               proofCard.getStrength(mode: mode, trumpSuit: trumpSuit) > highestBeforeStrength;
      }
    } else {
      // They played a non-trump.
      // Were they void in the led suit? (If they weren't void, Qate applies)
      final hasLedSuit = hand.any((c) => c.suit == ledSuit);
      if (hasLedSuit) return false;
      
      // They were void. The opponent is winning with a trump.
      // Does the proof card prove they had a HIGHER trump and failed to play it?
      return proofCard.suit == trumpSuit && 
             proofCard.getStrength(mode: mode, trumpSuit: trumpSuit) > highestBeforeStrength;
    }
    
    return false;
  }

  /// ما دق بحكم - Opponent didn't trump when they had no suit cards but did have trump cards
  static bool _checkMaDaqBiHakam(TrickResult trick, int accusedPlayIndex, List<CardModel> hand, {required GameMode mode, required Suit? trumpSuit, required int? proofCardIndex}) {
    if (mode != GameMode.hakam || trumpSuit == null) return false;
    if (accusedPlayIndex == 0) return false;
    
    final ledSuit = trick.cards[0].card.suit;
    if (ledSuit == trumpSuit) return false; // Led suit is trump; handled by Qate or MaKabbar
    
    final playedCard = trick.cards[accusedPlayIndex].card;
    final accusedSeat = trick.cards[accusedPlayIndex].playerIndex;
    
    // If they played a trump, they didn't commit "Ma Daq" (they did cut)
    if (playedCard.suit == trumpSuit) {
      return false;
    }
    
    // They played an off-suit. Did they have the led suit?
    final hasLedSuit = hand.any((c) => c.suit == ledSuit);
    if (hasLedSuit) return false; // They had the led suit, so it's Qate, not Ma Daq.
    
    // Find who is winning the trick right before the accused player plays
    CardModel? currentWinningCard = trick.cards[0].card;
    int currentWinningSeat = trick.cards[0].playerIndex;
    
    for (int i = 1; i < accusedPlayIndex; i++) {
      final card = trick.cards[i].card;
      final seat = trick.cards[i].playerIndex;
      // Does this card beat the current winning card?
      if (card.suit == trumpSuit && currentWinningCard!.suit != trumpSuit) {
        currentWinningCard = card;
        currentWinningSeat = seat;
      } else if (card.suit == currentWinningCard!.suit) {
        if (card.getStrength(mode: mode, trumpSuit: trumpSuit) > currentWinningCard.getStrength(mode: mode, trumpSuit: trumpSuit)) {
          currentWinningCard = card;
          currentWinningSeat = seat;
        }
      }
    }
    
    // Qabalak Rule: If the partner of the accused player is currently winning the trick, trumping is completely optional.
    final bool isPartnerWinning = (currentWinningSeat % 2 == accusedSeat % 2);
    if (isPartnerWinning) {
      return false; // Exempt from trumping due to Qabalak
    }

    // Partner is not winning.
    // They are void in the led suit. 

    if (proofCardIndex == null || proofCardIndex < 0 || proofCardIndex >= hand.length) return false;
    final proofCard = hand[proofCardIndex];

    // Did someone already cut with a trump?
    if (currentWinningCard!.suit == trumpSuit) {
      // Someone already cut. 
      // If they only have weaker trumps, they are NOT forced to play them (they can discard off-suit).
      // They are only forced to cut if they can OVER-TRUMP.
      final highestBeforeStrength = currentWinningCard.getStrength(mode: mode, trumpSuit: trumpSuit);
      
      // Does the proof card prove they had a HIGHER trump?
      return proofCard.suit == trumpSuit && 
             proofCard.getStrength(mode: mode, trumpSuit: trumpSuit) > highestBeforeStrength;
    } else {
      // No one has cut yet. Since they are void and opponent is winning, they MUST cut if they have ANY trump.
      // Does the proof card prove they had ANY trump?
      return proofCard.suit == trumpSuit;
    }
  }

  /// إكة خاطئة - Opponent claimed Ekka but didn't have the highest remaining card in that suit
  static bool _checkFalseEkka(List<TrickResult> history, int trickIndex, int accusedPlayIndex, GameMode mode, Suit? trumpSuit) {
    if (accusedPlayIndex != 0) return false; // Ekka can only be claimed when leading

    final trick = history[trickIndex];
    final playedCard = trick.cards[0].card;
    final suit = playedCard.suit;

    // Collect all cards of this suit played BEFORE this trick
    final Set<Rank> playedRanks = {};
    for (int i = 0; i < trickIndex; i++) {
      for (final play in history[i].cards) {
        if (play.card.suit == suit) {
          playedRanks.add(play.card.rank);
        }
      }
    }

    // Now, is there any rank of this suit that is stronger than playedCard AND hasn't been played yet?
    final playedCardStrength = playedCard.getStrength(mode: mode, trumpSuit: trumpSuit);

    for (final rank in Rank.values) {
      if (!playedRanks.contains(rank)) {
        final hypotheticalCard = CardModel(suit: suit, rank: rank);
        final strength = hypotheticalCard.getStrength(mode: mode, trumpSuit: trumpSuit);
        if (strength > playedCardStrength) {
          // A stronger card of the same suit is still out there! The Ekka was false!
          return true; // The challenge (Qaydha) is CORRECT.
        }
      }
    }

    // The Ekka was valid.
    return false; // The challenge is INCORRECT.
  }
}
