import '../../../../core/errors/game_exceptions.dart';
import '../../../../data/models/card_model.dart';
import '../../../../data/models/round_state_model.dart';

/// The action a player can take during bidding.
/// [confirmHakam] is used only during the [BiddingPhase.hakamConfirmation] step.
enum BidAction { hakam, sun, secondHakam, ashkal, pass, sawa, confirmHakam }

/// Manages the Mzad (bidding) phase per BALOOT_RULES.md Section 4.
///
/// Turn order: starts at dealer's right, counter-clockwise.
/// Round 1: Hakam (buyer card suit) or Pass.
///   - If all others pass a Hakam bid → [BiddingPhase.hakamConfirmation]:
///     the buyer must [BidAction.confirmHakam] (keep Hakam) or [BidAction.sun]
///     (switch to Sun). This is confirmed by Jawaker/Kamelna/client.
/// Round 2: Sun, Second Hakam (different suit), Pass.
/// After Sun: others Pass or Sawa; three Passes lock Sun (no confirmation).
/// After Second Hakam: Sawa locks immediately; three Passes →
/// [BiddingPhase.hakamConfirmation] (Visca / Jawaker / Kammelna).
class BiddingManager {
  final int dealerIndex;
  final CardModel buyerCard;

  BiddingPhase _phase = BiddingPhase.round1;
  int _currentBidder = -1;
  int _passCount = 0;

  // Track the leading bid in Round 1 (someone may bid Hakam early,
  // but others can still bid Sun to override)
  int? _round1HakamBidder;

  /// [hakamConfirmation] only: seat that must choose Confirm Hakam vs Sun.
  int? _hakamConfirmBuyer;
  /// null → Round 1 Hakam (trump = buyer card suit); non-null → R2 Second Hakam trump.
  Suit? _hakamConfirmTrumpOverride;

  /// Round 2: after Sun or Second Hakam, others Pass or Sawa (Jawaker/Kamelna §4.4).
  int? _round2PendingBuyer;
  GameMode? _round2PendingMode;
  Suit? _round2PendingTrump;

  // Final result
  BidResult? _result;
  bool _isFinished = false;

  BiddingManager({
    required this.dealerIndex,
    required this.buyerCard,
  }) {
    // First bidder is to the dealer's right.
    // Screen seats: 0=bottom, 1=right, 2=top, 3=left → +1 = right.
    _currentBidder = (dealerIndex + 1) % 4;
  }

  BiddingPhase get phase => _phase;
  int get currentBidder => _currentBidder;
  bool get isFinished => _isFinished;
  BidResult? get result => _result;

  /// Whether someone has already bid Hakam in Round 1 (Sawa becomes available).
  bool get hasActiveHakamBid => _round1HakamBidder != null;

  /// Seat that opened Hakam in Round 1 (null if none yet). Exposed for UI/bots.
  int? get activeRound1HakamSeat => _round1HakamBidder;

  /// True when Round 2 is waiting for Pass/Sawa after Sun or Second Hakam.
  bool get hasRound2PendingBid => _round2PendingBuyer != null;

  /// Seat that bid Sun / Second Hakam while others react (Round 2).
  int? get activeRound2PendingBuyerSeat => _round2PendingBuyer;

  static bool _opposingTeams(int seatA, int seatB) => (seatA % 2) != (seatB % 2);

  /// The Sane (صانع) is the player to the dealer's LEFT.
  /// Screen: 0=bottom,1=right,2=top,3=left → left of dealer = +3 (≡ -1).
  int get _saneIndex => (dealerIndex + 3) % 4;

  /// Process a bid action from the current player.
  ///
  /// [seatIndex] must match [currentBidder].
  /// [action] is the bid type.
  /// [secondHakamSuit] is required when action is [BidAction.secondHakam].
  void placeBid(int seatIndex, BidAction action, {Suit? secondHakamSuit}) {
    if (_isFinished) {
      throw const InvalidMoveException('Bidding has already ended.');
    }
    if (seatIndex != _currentBidder) {
      throw InvalidBidException(
        playerIndex: seatIndex,
        message: 'Not your turn. Current bidder is seat $_currentBidder.',
      );
    }

    switch (_phase) {
      case BiddingPhase.round1:
        _handleRound1(seatIndex, action);
      case BiddingPhase.round2:
        _handleRound2(seatIndex, action, secondHakamSuit);
      case BiddingPhase.hakamConfirmation:
        _handleHakamConfirmation(seatIndex, action);
      case BiddingPhase.completed:
      case BiddingPhase.cancelled:
        throw const InvalidMoveException('Bidding is not active.');
    }
  }

  void _handleRound1(int seatIndex, BidAction action) {
    switch (action) {
      case BidAction.hakam:
        if (_round1HakamBidder != null) {
          throw InvalidBidException(
            playerIndex: seatIndex,
            message:
                'Hakam was already bid — use Pass, Sawa (defenders), or Sun (Jawaker/Kammelna).',
          );
        }
        _round1HakamBidder = seatIndex;
        _passCount = 0;
        _advanceBidder();
        // Bidding continues — others may still pass or (later in round) Sun overrides

      case BidAction.sun:
        // Sun overrides any Hakam bid in Round 1
        _result = BidResult(
          mode: GameMode.sun,
          buyerIndex: seatIndex,
        );
        _phase = BiddingPhase.completed;
        _isFinished = true;

      case BidAction.sawa:
        if (_round1HakamBidder != null) {
          if (!_opposingTeams(seatIndex, _round1HakamBidder!)) {
            throw InvalidBidException(
              playerIndex: seatIndex,
              message:
                  'Sawa is only for the defending team — not your partner (Jawaker/Kammelna).',
            );
          }
          // Sawa: defenders accept Hakam; original Hakam bidder remains buyer.
          _result = BidResult(
            mode: GameMode.hakam,
            buyerIndex: _round1HakamBidder!,
            trumpSuit: buyerCard.suit,
          );
          _phase = BiddingPhase.completed;
          _isFinished = true;
        } else {
          throw InvalidBidException(
            playerIndex: seatIndex,
            message: 'Cannot Sawa without an active bid.',
          );
        }

      case BidAction.pass:
        _passCount++;
        if (_round1HakamBidder != null) {
          // Someone bid Hakam — check if all others passed
          if (_passCount >= 3) {
            // All 3 others passed → buyer must now confirm Hakam or switch to Sun
            // (Jawaker/Kamelna/Visca rule: buyer gets a final choice.)
            _hakamConfirmBuyer = _round1HakamBidder;
            _hakamConfirmTrumpOverride = null;
            _phase = BiddingPhase.hakamConfirmation;
            _currentBidder = _round1HakamBidder!;
          } else {
            _advanceBidder();
            // Skip the hakam bidder — they already bid
            if (_currentBidder == _round1HakamBidder) {
              _advanceBidder();
            }
          }
        } else {
          // No one bid Hakam yet
          if (_passCount >= 4) {
            // All 4 passed Round 1 → move to Round 2
            _phase = BiddingPhase.round2;
            _passCount = 0;
            _currentBidder = (dealerIndex + 1) % 4;
          } else {
            _advanceBidder();
          }
        }

      case BidAction.ashkal:
        // Jawaker/Kamelna: Ashkal is allowed in Round 1 only.
        // Only Dealer and Sane (dealer's left) can call Ashkal.
        if (seatIndex != dealerIndex && seatIndex != _saneIndex) {
          throw InvalidBidException(
            playerIndex: seatIndex,
            message:
                'Ashkal is only available to Dealer (seat $dealerIndex) or Sane (seat $_saneIndex).',
          );
        }
        _result = BidResult(
          mode: GameMode.sun,
          buyerIndex: seatIndex,
          isAshkal: true,
        );
        _phase = BiddingPhase.completed;
        _isFinished = true;

      default:
        throw InvalidBidException(
          playerIndex: seatIndex,
          message: '$action is not valid in Round 1.',
        );
    }
  }

  /// Hakam Confirmation — buyer chooses: confirm Hakam OR switch to Sun.
  /// Round 1: after others pass a Hakam on buyer card suit.
  /// Round 2: after others pass a Second Hakam (Visca / Jawaker / Kammelna).
  void _handleHakamConfirmation(int seatIndex, BidAction action) {
    final buyer = _hakamConfirmBuyer;
    if (buyer == null) {
      throw const InvalidMoveException('Hakam confirmation state is invalid.');
    }
    if (seatIndex != buyer) {
      throw InvalidBidException(
        playerIndex: seatIndex,
        message: 'Only the Hakam bidder (seat $buyer) can act during confirmation.',
      );
    }

    switch (action) {
      case BidAction.confirmHakam:
        final trump = _hakamConfirmTrumpOverride ?? buyerCard.suit;
        _result = BidResult(
          mode: GameMode.hakam,
          buyerIndex: seatIndex,
          trumpSuit: trump,
        );
        _phase = BiddingPhase.completed;
        _isFinished = true;
        _hakamConfirmBuyer = null;
        _hakamConfirmTrumpOverride = null;

      case BidAction.sun:
        _result = BidResult(
          mode: GameMode.sun,
          buyerIndex: seatIndex,
        );
        _phase = BiddingPhase.completed;
        _isFinished = true;
        _hakamConfirmBuyer = null;
        _hakamConfirmTrumpOverride = null;

      default:
        throw InvalidBidException(
          playerIndex: seatIndex,
          message:
              'During Hakam confirmation, only confirmHakam or sun are allowed.',
        );
    }
  }

  void _handleRound2(int seatIndex, BidAction action, Suit? secondHakamSuit) {
    switch (action) {
      case BidAction.sun:
        if (_round2PendingBuyer != null) {
          throw InvalidBidException(
            playerIndex: seatIndex,
            message:
                'Round 2: pass or call Sawa on the current bid — cannot bid Sun again.',
          );
        }
        _round2PendingBuyer = seatIndex;
        _round2PendingMode = GameMode.sun;
        _round2PendingTrump = null;
        _passCount = 0;
        _advanceBidder();
        while (_currentBidder == _round2PendingBuyer) {
          _advanceBidder();
        }
        break;

      case BidAction.secondHakam:
        if (_round2PendingBuyer != null) {
          throw InvalidBidException(
            playerIndex: seatIndex,
            message:
                'Round 2: pass or call Sawa on the current bid — cannot bid Second Hakam again.',
          );
        }
        if (secondHakamSuit == null) {
          throw InvalidBidException(
            playerIndex: seatIndex,
            message: 'Must specify a suit for Second Hakam.',
          );
        }
        if (secondHakamSuit == buyerCard.suit) {
          throw InvalidBidException(
            playerIndex: seatIndex,
            message:
                'Second Hakam suit must differ from buyer card suit (${buyerCard.suit}).',
          );
        }
        _round2PendingBuyer = seatIndex;
        _round2PendingMode = GameMode.hakam;
        _round2PendingTrump = secondHakamSuit;
        _passCount = 0;
        _advanceBidder();
        while (_currentBidder == _round2PendingBuyer) {
          _advanceBidder();
        }
        break;

      case BidAction.ashkal:
        // Jawaker/Kamelna/Pagat: Ashkal is NOT available in Round 2.
        // Round 2 options are: Sun, Second Hakam, or Pass only.
        throw InvalidBidException(
          playerIndex: seatIndex,
          message: 'Ashkal is not available in Round 2.',
        );

      case BidAction.sawa:
        if (_round2PendingBuyer == null ||
            _round2PendingMode == null) {
          throw InvalidBidException(
            playerIndex: seatIndex,
            message: 'Cannot Sawa in Round 2 without an active Sun or Hakam bid.',
          );
        }
        if (!_opposingTeams(seatIndex, _round2PendingBuyer!)) {
          throw InvalidBidException(
            playerIndex: seatIndex,
            message:
                'Sawa is only for the defending team — not your partner (Jawaker/Kammelna).',
          );
        }
        _result = BidResult(
          mode: _round2PendingMode!,
          buyerIndex: _round2PendingBuyer!,
          trumpSuit: _round2PendingTrump,
        );
        _phase = BiddingPhase.completed;
        _isFinished = true;
        break;

      case BidAction.pass:
        if (_round2PendingBuyer != null) {
          _passCount++;
          if (_passCount >= 3) {
            // Second Hakam: same confirm-or-Sun step as Round 1 (Visca ME).
            if (_round2PendingMode == GameMode.hakam) {
              _hakamConfirmBuyer = _round2PendingBuyer;
              _hakamConfirmTrumpOverride = _round2PendingTrump;
              _round2PendingBuyer = null;
              _round2PendingMode = null;
              _round2PendingTrump = null;
              _passCount = 0;
              _phase = BiddingPhase.hakamConfirmation;
              _currentBidder = _hakamConfirmBuyer!;
            } else {
              // Sun: no confirmation — lock Sun.
              _result = BidResult(
                mode: GameMode.sun,
                buyerIndex: _round2PendingBuyer!,
                trumpSuit: null,
              );
              _phase = BiddingPhase.completed;
              _isFinished = true;
            }
          } else {
            _advanceBidder();
            while (_currentBidder == _round2PendingBuyer) {
              _advanceBidder();
            }
          }
        } else {
          _passCount++;
          if (_passCount >= 4) {
            // All 4 passed Round 2 with no bid → round cancelled
            _phase = BiddingPhase.cancelled;
            _isFinished = true;
            _result = null;
          } else {
            _advanceBidder();
          }
        }
        break;

      default:
        throw InvalidBidException(
          playerIndex: seatIndex,
          message: '$action is not valid in Round 2.',
        );
    }
  }

  /// Move to next player counter-clockwise.
  void _advanceBidder() {
    _currentBidder = (_currentBidder + 1) % 4;
  }
}
