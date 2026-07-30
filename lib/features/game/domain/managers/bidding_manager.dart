import '../../../../core/errors/game_exceptions.dart';
import '../../../../data/models/card_model.dart';
import '../../../../data/models/round_state_model.dart';

/// The action a player can take during bidding.
/// [confirmHakam] is used only during the [BiddingPhase.hakamConfirmation] step.
enum BidAction {
  pass, // بس / ولا
  sun, // صن
  hakam, // حكم
  secondHakam, // حكم ثاني (different suit)
  ashkal, // أشكال
  qablak, // قبلك
  sawa, // سوى (defender locks Hakam)
  confirmHakam, // تأكيد الحكم
}

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

  // Qablak Priority Queue
  final List<int> _qablakQueue = [];
  int? _originalSunBidder;
  bool _originalSunIsAshkal = false;

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

  /// Mode of the pending Round 2 bid (Sun / Second Hakam) — for bot/UI.
  GameMode? get activeRound2PendingMode => _round2PendingMode;

  /// Trump for pending Second Hakam only; null if pending Sun.
  Suit? get activeRound2PendingTrump => _round2PendingTrump;

  static bool _opposingTeams(int seatA, int seatB) => (seatA % 2) != (seatB % 2);

  /// The Sane (صانع) is the player to the dealer's LEFT.
  /// Screen: 0=bottom,1=right,2=top,3=left → left of dealer = +3 (≡ -1).
  int get _saneIndex => (dealerIndex + 3) % 4;

  bool _isDealer(int seat) => seat == dealerIndex;
  bool _isSane(int seat) => seat == _saneIndex;

  List<BidAction> getAllowedActions(int playerIndex) {
    final actions = <BidAction>[];

    // Qablak queue processing
    if (_phase == BiddingPhase.qablakIntervention) {
      if (playerIndex == _currentBidder) {
        actions.add(BidAction.qablak);
        actions.add(BidAction.sun);
        actions.add(BidAction.pass);
      }
      return actions;
    }

    if (playerIndex != _currentBidder) return [];

    if (_phase == BiddingPhase.round1) {
      if (_round1HakamBidder == null) {
        actions.add(BidAction.sun);
        actions.add(BidAction.hakam);
        if (_isDealer(playerIndex) || _isSane(playerIndex)) {
          actions.add(BidAction.ashkal);
        }
        actions.add(BidAction.pass);
      } else {
        // Someone already bid Hakam.
        actions.add(BidAction.sun);
        
        // Opponents of the Hakam bidder can call Sawa
        if (_opposingTeams(playerIndex, _round1HakamBidder!)) {
          actions.add(BidAction.sawa);
        }
        
        if (_isDealer(playerIndex) || _isSane(playerIndex)) {
          actions.add(BidAction.ashkal);
        }
        actions.add(BidAction.pass);
      }
    } else if (_phase == BiddingPhase.round2) {
      if (_round2PendingBuyer == null) {
        actions.add(BidAction.sun);
        actions.add(BidAction.secondHakam);
        
        if (_isDealer(playerIndex) || _isSane(playerIndex)) {
          actions.add(BidAction.ashkal);
        }
        
        actions.add(BidAction.pass);
      } else {
        actions.add(BidAction.sun);
        
        // Opponents of the Second Hakam bidder can call Sawa
        if (_opposingTeams(playerIndex, _round2PendingBuyer!)) {
          actions.add(BidAction.sawa);
        }
        
        if (_isDealer(playerIndex) || _isSane(playerIndex)) {
          actions.add(BidAction.ashkal);
        }
        actions.add(BidAction.pass);
      }
    } else if (_phase == BiddingPhase.hakamConfirmation) {
      if (playerIndex == _hakamConfirmBuyer) {
        actions.add(BidAction.confirmHakam);
        actions.add(BidAction.sun);
      }
    }

    return actions;
  }

  void _advanceBidder() {
    _currentBidder = (_currentBidder + 1) % 4;
  }

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
      case BiddingPhase.qablakIntervention:
        _handleQablakIntervention(seatIndex, action);
      case BiddingPhase.completed:
      case BiddingPhase.cancelled:
        throw const InvalidMoveException('Bidding is not active.');
    }
  }

  void _triggerQablakOrComplete(int seatIndex, bool isAshkal) {
    _qablakQueue.clear();
    int firstBidder = (dealerIndex + 1) % 4;
    int current = firstBidder;
    
    // Anyone who sat before the current bidder in turn order can steal
    while (current != seatIndex) {
      _qablakQueue.add(current);
      current = (current + 1) % 4;
    }

    if (_qablakQueue.isEmpty) {
      // First player called Sun, or queue is empty
      _result = BidResult(mode: GameMode.sun, buyerIndex: seatIndex, isAshkal: isAshkal);
      _phase = BiddingPhase.completed;
      _isFinished = true;
    } else {
      _originalSunBidder = seatIndex;
      _originalSunIsAshkal = isAshkal;
      _phase = BiddingPhase.qablakIntervention;
      _currentBidder = _qablakQueue.removeAt(0);
    }
  }

  void _handleQablakIntervention(int seatIndex, BidAction action) {
    if (action == BidAction.qablak || action == BidAction.sun) {
      // Player steals the Sun! (Stolen Ashkal converts to standard Sun for the stealer)
      _result = BidResult(mode: GameMode.sun, buyerIndex: seatIndex, isAshkal: false);
      _phase = BiddingPhase.completed;
      _isFinished = true;
      _qablakQueue.clear();
    } else if (action == BidAction.pass) {
      // Player declines to steal
      if (_qablakQueue.isNotEmpty) {
        _currentBidder = _qablakQueue.removeAt(0);
      } else {
        // No one else can steal, original bidder wins
        _result = BidResult(
          mode: GameMode.sun, 
          buyerIndex: _originalSunBidder!, 
          isAshkal: _originalSunIsAshkal
        );
        _phase = BiddingPhase.completed;
        _isFinished = true;
      }
    } else {
      throw InvalidBidException(
        playerIndex: seatIndex,
        message: 'Only Qablak/Sun or Pass allowed during Qablak Intervention.',
      );
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

      case BidAction.sun:
        _triggerQablakOrComplete(seatIndex, false);

      case BidAction.sawa:
        if (_round1HakamBidder == null || !_opposingTeams(seatIndex, _round1HakamBidder!)) {
          throw InvalidBidException(
            playerIndex: seatIndex,
            message: 'Sawa can only be called by opponents against an active Hakam bid.',
          );
        }
        // Sawa locks the Hakam bid immediately for the original buyer
        _result = BidResult(
          mode: GameMode.hakam,
          buyerIndex: _round1HakamBidder!,
          trumpSuit: buyerCard.suit,
          isAshkal: false,
        );
        _phase = BiddingPhase.completed;
        _isFinished = true;

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
        // Kamelna: Ashkal is allowed in Round 1 only.
        // Only Dealer and Sane (dealer's left) can call Ashkal, and NOT on an Ace.
        // Penalty: If attempted illegally, forced to buy as normal Sun.
        if (seatIndex != dealerIndex && seatIndex != _saneIndex || buyerCard.rank == Rank.ace) {
          _triggerQablakOrComplete(seatIndex, false);
        } else {
          _triggerQablakOrComplete(seatIndex, true);
        }


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
          if (_round2PendingMode == GameMode.sun) {
            throw InvalidBidException(
              playerIndex: seatIndex,
              message: 'Round 2: Sun is already bid — cannot bid Sun again.',
            );
          }
        }
        // Sun immediately overrides any pending Second Hakam and triggers Qablak.
        _triggerQablakOrComplete(seatIndex, false);
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
        // Kamelna: Ashkal is strictly forbidden in Round 2.
        // Penalty: Forced to buy as standard Sun.
        _triggerQablakOrComplete(seatIndex, false);
        break;

      case BidAction.sawa:
        if (_round2PendingBuyer == null || !_opposingTeams(seatIndex, _round2PendingBuyer!)) {
          throw InvalidBidException(
            playerIndex: seatIndex,
            message: 'Sawa can only be called by opponents against an active Second Hakam bid.',
          );
        }
        // Sawa locks the Second Hakam bid immediately for the original buyer
        _result = BidResult(
          mode: GameMode.hakam,
          buyerIndex: _round2PendingBuyer!,
          trumpSuit: _round2PendingTrump!,
          isAshkal: false,
        );
        _phase = BiddingPhase.completed;
        _isFinished = true;
        break;

      case BidAction.pass:
        if (_round2PendingBuyer != null) {
          _passCount++;
          if (_passCount >= 3) {
            // Second Hakam: same confirm-or-Sun step as Round 1.
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
}
