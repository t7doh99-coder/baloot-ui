import '../../../../data/models/card_model.dart';
import '../../../../data/models/card_play_model.dart';
import '../../../../data/models/round_state_model.dart';

/// Result of validating a card play.
class PlayValidationResult {
  final bool isValid;
  final String? violationMessage;
  final ViolationKind? violationKind;

  const PlayValidationResult.valid()
      : isValid = true,
        violationMessage = null,
        violationKind = null;

  const PlayValidationResult.violation(this.violationKind, this.violationMessage)
      : isValid = false;
}

enum ViolationKind { suitViolation, cutViolation, upTrumpViolation, closedPlayViolation }

/// Pure-function validator for card plays per BALOOT_RULES.md Section 5 & 9.
///
/// Stateless — takes all context as parameters, returns a result.
class PlayValidator {
  const PlayValidator();

  /// Validate whether [card] is a legal play given the current game state.
  ///
  /// [hand]: the player's current cards.
  /// [currentTrick]: cards already played in this trick (may be empty if leading).
  /// [mode]: Sun or Hakam.
  /// [trumpSuit]: the trump suit (null in Sun).
  /// [doubleStatus]: whether a double is active (affects Closed Play rule).
  /// [isOpenPlay]: if false, Closed Play restricts leading with trump.
  PlayValidationResult validate({
    required CardModel card,
    required List<CardModel> hand,
    required List<CardPlayModel> currentTrick,
    required GameMode mode,
    Suit? trumpSuit,
    DoubleStatus doubleStatus = DoubleStatus.none,
    bool isOpenPlay = true,
    int? playerSeat,
  }) {
    // If leading the trick
    if (currentTrick.isEmpty) {
      return _validateLead(
        card: card,
        hand: hand,
        mode: mode,
        trumpSuit: trumpSuit,
        doubleStatus: doubleStatus,
        isOpenPlay: isOpenPlay,
      );
    }

    // Following — must follow leading suit
    final leadingSuit = currentTrick.first.card.suit;
    final hasLeadingSuit = hand.any((c) => c.suit == leadingSuit);

    // Rule 1: Must follow leading suit if held
    if (hasLeadingSuit) {
      if (card.suit != leadingSuit) {
        return PlayValidationResult.violation(
          ViolationKind.suitViolation,
          'Must follow leading suit (${leadingSuit.name}) when holding one.',
        );
      }
      return const PlayValidationResult.valid();
    }

    // Player is void in leading suit
    if (mode == GameMode.sun) {
      // Sun: play any card (cannot win the trick anyway)
      return const PlayValidationResult.valid();
    }

    // Hakam mode — void in leading suit
    final hasTrump = hand.any((c) => c.suit == trumpSuit);

    // Rule 2: Must play trump if holding one (mandatory cut)
    // EXCEPTION (Free Play Rule): If your partner is currently winning the trick, you are not forced to cut.
    if (hasTrump && card.suit != trumpSuit && playerSeat != null) {
      final int currentWinnerSeat = _getCurrentWinnerSeat(
        currentTrick: currentTrick,
        leadingSuit: leadingSuit,
        trumpSuit: trumpSuit,
      );

      final bool partnerIsWinning = currentWinnerSeat >= 0 &&
          (currentWinnerSeat % 2 == playerSeat % 2);

      if (!partnerIsWinning) {
        return PlayValidationResult.violation(
          ViolationKind.cutViolation,
          'Must play trump (${trumpSuit!.name}) when void in leading suit unless partner is winning.',
        );
      }
    }

    // Rule 3: Up-Trump — if an opponent already cut, must play higher trump
    if (card.suit == trumpSuit && playerSeat != null) {
      final upTrumpResult = _checkUpTrump(
        card: card,
        hand: hand,
        currentTrick: currentTrick,
        trumpSuit: trumpSuit!,
        playerSeat: playerSeat,
      );
      if (!upTrumpResult.isValid) return upTrumpResult;
    }

    return const PlayValidationResult.valid();
  }

  /// Validate leading play. Only restriction: Closed Play rule.
  PlayValidationResult _validateLead({
    required CardModel card,
    required List<CardModel> hand,
    required GameMode mode,
    Suit? trumpSuit,
    required DoubleStatus doubleStatus,
    required bool isOpenPlay,
  }) {
    // Closed Play: when Double is active and play is closed,
    // cannot lead with trump if holding any other suit
    if (mode == GameMode.hakam &&
        doubleStatus != DoubleStatus.none &&
        !isOpenPlay &&
        card.suit == trumpSuit) {
      final hasNonTrump = hand.any((c) => c.suit != trumpSuit);
      if (hasNonTrump) {
        return PlayValidationResult.violation(
          ViolationKind.closedPlayViolation,
          'Closed Play: cannot lead with trump while holding other suits.',
        );
      }
    }
    return const PlayValidationResult.valid();
  }

  /// Check Up-Trump rule: if an OPPONENT already played trump in this trick,
  /// the player must play a higher trump if they have one.
  ///
  /// Teammate's cut does NOT trigger up-trump — only opponent's.
  /// Opponents have different seat parity (Team A = even, Team B = odd).
  PlayValidationResult _checkUpTrump({
    required CardModel card,
    required List<CardModel> hand,
    required List<CardPlayModel> currentTrick,
    required Suit trumpSuit,
    required int playerSeat,
  }) {
    final playerIsTeamA = playerSeat % 2 == 0;

    // Find the highest trump played by an OPPONENT (different team) only
    int highestOpponentTrump = -1;
    for (final play in currentTrick) {
      final playIsTeamA = play.playerIndex % 2 == 0;
      final isOpponent = playIsTeamA != playerIsTeamA;
      if (isOpponent && play.card.suit == trumpSuit) {
        final strength = play.card.getStrength(
          mode: GameMode.hakam,
          trumpSuit: trumpSuit,
        );
        if (strength > highestOpponentTrump) {
          highestOpponentTrump = strength;
        }
      }
    }

    if (highestOpponentTrump < 0) {
      // No one (or only teammate) has played trump yet — no up-trump restriction
      return const PlayValidationResult.valid();
    }

    final cardStrength = card.getStrength(
      mode: GameMode.hakam,
      trumpSuit: trumpSuit,
    );

    if (cardStrength > highestOpponentTrump) {
      // Playing a higher trump than the opponent — valid
      return const PlayValidationResult.valid();
    }

    // Check if the player HAS a higher trump in hand to beat the opponent
    final hasHigherTrump = hand.any((c) {
      if (c.suit != trumpSuit) return false;
      return c.getStrength(mode: GameMode.hakam, trumpSuit: trumpSuit) >
          highestOpponentTrump;
    });

    if (hasHigherTrump) {
      return PlayValidationResult.violation(
        ViolationKind.upTrumpViolation,
        'Must play a higher trump when an opponent has already cut.',
      );
    }

    // Player doesn't have a higher trump — playing lower is fine
    return const PlayValidationResult.valid();
  }

  /// Get all valid cards a player can play from their hand.
  /// Useful for bot logic (play lowest valid card).
  List<CardModel> getValidCards({
    required List<CardModel> hand,
    required List<CardPlayModel> currentTrick,
    required GameMode mode,
    Suit? trumpSuit,
    DoubleStatus doubleStatus = DoubleStatus.none,
    bool isOpenPlay = true,
    int? playerSeat,
  }) {
    return hand.where((card) {
      final result = validate(
        card: card,
        hand: hand,
        currentTrick: currentTrick,
        mode: mode,
        trumpSuit: trumpSuit,
        doubleStatus: doubleStatus,
        isOpenPlay: isOpenPlay,
        playerSeat: playerSeat,
      );
      return result.isValid;
    }).toList();
  }

  /// Calculates who is currently winning the trick based on Hakam rules.
  int _getCurrentWinnerSeat({
    required List<CardPlayModel> currentTrick,
    required Suit leadingSuit,
    Suit? trumpSuit,
  }) {
    if (currentTrick.isEmpty) return -1;
    
    int winnerSeat = currentTrick.first.playerIndex;
    CardModel winningCard = currentTrick.first.card;
    
    for (int i = 1; i < currentTrick.length; i++) {
      final play = currentTrick[i];
      final card = play.card;
      
      bool isNewWinner = false;
      if (winningCard.suit == trumpSuit) {
        // Current winning card is a trump. New card must be higher trump.
        if (card.suit == trumpSuit && 
            card.getStrength(mode: GameMode.hakam, trumpSuit: trumpSuit) > 
            winningCard.getStrength(mode: GameMode.hakam, trumpSuit: trumpSuit)) {
          isNewWinner = true;
        }
      } else {
        // Current winning card is non-trump.
        if (card.suit == trumpSuit) {
          // Cut with trump wins.
          isNewWinner = true;
        } else if (card.suit == leadingSuit && winningCard.suit == leadingSuit) {
          // Followed suit, must be higher strength.
          if (card.getStrength(mode: GameMode.hakam, trumpSuit: trumpSuit) > 
              winningCard.getStrength(mode: GameMode.hakam, trumpSuit: trumpSuit)) {
            isNewWinner = true;
          }
        }
      }
      
      if (isNewWinner) {
        winningCard = card;
        winnerSeat = play.playerIndex;
      }
    }
    
    return winnerSeat;
  }
}
