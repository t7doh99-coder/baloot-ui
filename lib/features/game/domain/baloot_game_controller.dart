import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/errors/game_exceptions.dart';
import '../../../core/interfaces/i_baloot_controller.dart';
import '../../../data/models/card_model.dart';
import '../../../data/models/card_play_model.dart';
import '../../../data/models/round_state_model.dart';
import 'managers/deck_manager.dart';
import 'managers/bidding_manager.dart';
import 'managers/turn_manager.dart';
import 'validators/play_validator.dart';
import 'engines/bot_engine.dart';
import 'engines/qaydha_engine.dart';
import 'engines/project_detector.dart';
import 'engines/scoring_engine.dart';
import 'engines/sawa_probability_engine.dart';
import '../../../data/models/bot_difficulty.dart';
import '../../../data/models/bot_personality.dart';
import '../../../core/utils/game_logger.dart';
import 'models/qaydha_models.dart';

/// Defines specific cheat rules to force bots to make illegal plays in a live game.
enum BotCheatMode {
  none,
  suitViolation,
  cutViolation,
  upTrumpViolation,
  closedPlayViolation,
  falseAkka,
  falseSawa,
}

/// The game phase the controller is currently in.
enum GamePhase { notStarted, dealing, bidding, doubleWindow, playing, scoring, gameOver }

/// Master controller that ties all engine modules together.
///
/// Implements the full game loop:
/// deal → bid → (optional double) → play 8 tricks → score → check game end → next round.
///
/// Per ENGINE_IMPLEMENTATION_PLAN.md Step 8 and BALOOT_RULES.md.
class BalootGameController implements IBalootController {
  final Random _rng;
  final PlayValidator _playValidator = const PlayValidator();
  final ProjectDetector _projectDetector = const ProjectDetector();
  final ScoringEngine _scoringEngine = const ScoringEngine();
  late final BotEngine _botEngine;
  final GameLogger logger = GameLogger();

  // Game-level state
  late List<String> _playerNames;
  @override
  List<String> get playerNames => List.unmodifiable(_playerNames);

  int _teamAScore = 0;
  int _teamBScore = 0;
  int _dealerIndex = 0;
  
  @visibleForTesting
  void setDealerIndexForTest(int index) => _dealerIndex = index;

  @visibleForTesting
  void setScoresForTest(int teamA, int teamB) {
    _teamAScore = teamA;
    _teamBScore = teamB;
  }

  @visibleForTesting
  void setHandForTest(int seatIndex, List<CardModel> hand) {
    _hands[seatIndex] = List<CardModel>.from(hand);
  }
  int _targetScore = 152; // Default: Jawaker standard (152)
  GamePhase _gamePhase = GamePhase.notStarted;

  // Round-level state
  late DeckManager _deckManager;
  BiddingManager? _biddingManager;
  TurnManager? _turnManager;
  late RoundStateModel _roundState;
  late List<List<CardModel>> _hands;

  bool _useInjectedDeckManager = false;

  @visibleForTesting
  void setDeckManagerForTest(DeckManager dm) {
    _deckManager = dm;
    _useInjectedDeckManager = true;
  }

  // Detected projects per player (from initial 8-card hand)
  final Map<int, List<DetectedProject>> _detectedProjects = {};
  // Projects the player has chosen to declare
  final List<DeclaredProject> _activeDeclaredProjects = [];
  // Track if Baloot has been declared (auto, on 2nd card of K-Q pair)
  final Set<int> _balootDeclaredBy = {};

  /// Seat that last called Double or Four (defender); buyer Triple / Gahwa return here.
  int? _escalationDefenderSeat;

  /// Result of the most recently scored round (for UI overlay).
  RoundScoreResult? _lastRoundScoreResult;

  /// Set when the round ends via in-play **Sawa** (master cards), not trick 8 played out.
  int? _lastPlaySawaClaimSeat;

  int? _ekkaClaimSeat;
  @override
  int? get ekkaClaimSeat => _ekkaClaimSeat;

  BalootGameController({
    Random? random,
    BotDifficulty botDifficulty = BotDifficulty.medium,
  })  : _rng = random ?? Random() {
    _botEngine = BotEngine(difficulty: botDifficulty, random: _rng);
    _botEngine.assignIdentities();
  }

  @visibleForTesting
  void setBotEngineForTest(BotEngine be) => _botEngine = be;
  
  @visibleForTesting
  void setRoundStateForTest(RoundStateModel rs) => _roundState = rs;

  @visibleForTesting
  void setTurnManagerForTest(TurnManager tm) => _turnManager = tm;

  /// Expose bot identity for UI (names, rank badges).
  BotIdentity botIdentityOf(int seat) => _botEngine.identityOf(seat);

  /// Points and flags from the last completed round (cleared on new round).
  RoundScoreResult? get lastRoundScoreResult => _lastRoundScoreResult;

  /// Seat that claimed in-play Sawa for the last scored round; null otherwise.
  int? get lastPlaySawaClaimSeat => _lastPlaySawaClaimSeat;

  /// Cards from the last completed trick, indexed by seat 0–3 (for mini history UI).
  /// Only non-null while a [TurnManager] exists with at least one finished trick.
  List<CardModel>? get lastTrickCardsBySeat {
    final tm = _turnManager;
    if (tm == null || tm.trickHistory.isEmpty) return null;
    final last = tm.trickHistory.last;
    if (last.cards.length != 4) return null;
    final map = <int, CardModel>{};
    for (final p in last.cards) {
      map[p.playerIndex] = p.card;
    }
    return List.generate(4, (i) => map[i]!);
  }


  /// First seat on the defending (non-buyer) team.
  /// Ensures human (seat 0) gets priority when on the defending side.
  int _firstDefenderSeat(int buyerIndex) {
    final buyerTeamIsA = buyerIndex % 2 == 0;
    if (buyerTeamIsA) return 1; // Team B defends: seat 1
    return 0; // Team A defends: seat 0 (human)
  }

  /// When true, the next bot turn will force a Qaid violation (if they hold an illegal card)
  bool _forceNextBotMistake = false;
  
  /// Live Bot Cheat Mode: forces the bot to make specific illegal plays if possible.
  BotCheatMode activeCheatMode = BotCheatMode.none;

  int? _lastCheatSeat;
  int? get lastCheatSeat => _lastCheatSeat;
  void clearCheatSeat() {
    _lastCheatSeat = null;
  }

  /// The allowed bid actions for a given seat in the current bidding state.
  List<BidAction> allowedActions(int seatIndex) {
    if (_biddingManager == null) return [];
    return _biddingManager!.getAllowedActions(seatIndex);
  }

  /// Most recently completed trick (for UI throw / collect animations).
  TrickResult? get lastTrickResult {
    final tm = _turnManager;
    if (tm == null || tm.trickHistory.isEmpty) return null;
    return tm.trickHistory.last;
  }

  /// Number of tricks fully completed this round (for UI transitions).
  int get completedTricksCount => _turnManager?.trickHistory.length ?? 0;

  /// Completed tricks this round (empty when not in play or before first trick).
  List<TrickResult> get trickHistoryThisRound {
    final tm = _turnManager;
    if (tm == null) return const <TrickResult>[];
    return List<TrickResult>.unmodifiable(tm.trickHistory);
  }

  /// Standard "أكة" (Akka) detection.
  ///
  /// Returns `true` when [card] is the **strongest remaining card** of its suit
  /// at the moment it is played AND the player is **leading** the trick (first card).
  ///
  /// Rules (per pagat.com / Standard):
  /// - Only triggers on the **lead** card (first card of a trick).
  /// Akka (إكة) announcement rules (Kammelna / Saudi Baloot standard):
  ///
  /// - Akka ONLY exists in Hakam (حكم) mode.
  ///   It does NOT exist in Sun (صن) or Ashkal (أشكال) — in those modes
  ///   there are no trump cards and everyone must follow suit, so the
  ///   "warn your partner not to cut" signal has no meaning.
  /// - Akka NEVER applies when the card is an Ace (إكة/آص).
  ///   An Ace is self-evidently the highest card in its suit; it doesn't
  ///   need an announcement and can never be a false-Akka. Kammelna never
  ///   shows an Akka bubble or opens a challenge window for an Ace lead.
  /// - Akka only applies to NON-trump suits in Hakam
  ///   (trump already has its own J > 9 > A > 10 > K > Q > 8 > 7 hierarchy).
  /// - A card qualifies as Akka when every card of the same suit that
  ///   would beat it has already been played in a previous trick.
  bool isAkka(CardModel card) {
    final tm = _turnManager;
    if (tm == null) return false;

    final mode = _roundState.activeMode;
    if (mode == null) return false;
    final trump = _roundState.trumpSuit;

    // ── Rule 1: Akka ONLY exists in Hakam mode ──
    // Sun and Ashkal have no Akka announcement mechanic.
    if (mode != GameMode.hakam) return false;

    // ── Rule 1b: In Kammelna, Akka is not allowed on trick 8 (last trick) ──
    if (tm.trickNumber == 8) return false;

    // ── Rule 2: Ace cards are NEVER an Akka ──
    // An Ace is the absolute highest card in its suit by definition.
    // Announcing "Akka" on an Ace is meaningless (and Kammelna never does it).
    if (card.rank == Rank.ace) return false;

    // ── Rule 3: In Hakam, Akka only applies to non-trump suits ──
    // Trump suit has its own hierarchy (J > 9 > A > 10 …).
    if (card.suit == trump) return false;

    // ── LEAD-ONLY CHECK ──
    // Akka only applies when the player LEADS the trick (plays first).
    // After playCard(), either:
    //   a) Trick still in progress → card is in currentTrick
    //   b) Trick just completed → card is in trickHistory.last
    // Before playCard(), if currentTrick is empty, this is candidate lead card.
    bool isLeadCard = false;
    int historyCount = tm.trickHistory.length;
    if (tm.currentTrick.isNotEmpty) {
      // Trick in progress — was this card the first one?
      isLeadCard = tm.currentTrick.first.card == card;
      historyCount = tm.trickHistory.length;
    } else if (tm.trickHistory.isNotEmpty &&
               tm.trickHistory.last.cards.isNotEmpty &&
               tm.trickHistory.last.cards.first.card == card) {
      // Trick just completed — was this card the lead?
      isLeadCard = true;
      historyCount = tm.trickHistory.length - 1;
    } else {
      // Either (a) the card was a non-lead card in the last completed trick
      // (e.g. the 2nd/3rd/4th card that just finished a trick), or
      // (b) this is called before playCard() as a candidate lead card.
      if (tm.trickHistory.isNotEmpty &&
          tm.trickHistory.last.cards.any((p) => p.card == card)) {
        // Card was in the last completed trick but NOT as lead — NOT Akka
        isLeadCard = false;
      } else {
        // Card is about to be played as lead of next trick
        isLeadCard = true;
        historyCount = tm.trickHistory.length;
      }
    }
    if (!isLeadCard) return false;

    // Collect all cards of the SAME suit that have been played in PREVIOUS tricks
    final playedOfSuit = <CardModel>{};
    for (int i = 0; i < historyCount; i++) {
      for (final play in tm.trickHistory[i].cards) {
        if (play.card.suit == card.suit) {
          playedOfSuit.add(play.card);
        }
      }
    }

    // Get the strength of the played card
    final cardStrength = card.getStrength(mode: mode, trumpSuit: trump);

    // Check all 8 ranks of this suit: is there any UNPLAYED card that's stronger?
    for (final rank in Rank.values) {
      final other = CardModel(suit: card.suit, rank: rank);
      if (other == card) continue; // skip self
      if (playedOfSuit.contains(other)) continue; // already played — gone

      final otherStrength = other.getStrength(mode: mode, trumpSuit: trump);
      if (otherStrength > cardStrength) {
        return false; // a stronger card is still unplayed — NOT Akka
      }
    }

    return true; // no stronger card remains — this IS Akka!
  }

  /// Returns the most recently played card by [seat], checking the current
  /// trick first, then the last completed trick. Used for Akka detection.
  CardModel? lastPlayedCardBySeat(int seat) {
    final tm = _turnManager;
    if (tm == null) return null;

    // Check current trick first (card was just played)
    for (int i = tm.currentTrick.length - 1; i >= 0; i--) {
      if (tm.currentTrick[i].playerIndex == seat) {
        return tm.currentTrick[i].card;
      }
    }

    // If trick just completed, check the last completed trick
    if (tm.trickHistory.isNotEmpty) {
      final last = tm.trickHistory.last;
      for (int i = last.cards.length - 1; i >= 0; i--) {
        if (last.cards[i].playerIndex == seat) {
          return last.cards[i].card;
        }
      }
    }

    return null;
  }

  GamePhase get gamePhase => _gamePhase;

  // ── IBalootController implementation ──

  @override
  void startNewGame(List<String> playerNames) {
    if (playerNames.length != 4) {
      throw const InvalidMoveException('Exactly 4 players required.');
    }
    logger.clear();
    logger.log('--- NEW GAME STARTED ---');
    _botEngine.assignIdentities();
    _playerNames = [
      playerNames[0],
      _botEngine.identityOf(1).name,
      _botEngine.identityOf(2).name,
      _botEngine.identityOf(3).name,
    ];
    _teamAScore = 0;
    _teamBScore = 0;
    _targetScore = 152; // Standard strict classic score
    _dealerIndex = _rng.nextInt(4);
    logger.log('Initial dealer: Seat $_dealerIndex');
    logger.log('Target score: $_targetScore');
    _gamePhase = GamePhase.dealing;

    // Safe placeholder until [startNewRound] runs (~1 frame / timer later).
    // Without this, [roundState] / [_hands] were never initialized while phase
    // was already [dealing] — UI reads caused LateInitializationError (red screen).
    _roundState = RoundStateModel.empty().copyWith(
      dealerIndex: _dealerIndex,
      currentPlayerIndex: (_dealerIndex + 1) % 4,
    );
    _hands = List.generate(4, (_) => <CardModel>[]);
    _biddingManager = null;
    _turnManager = null;
    _detectedProjects.clear();
    _activeDeclaredProjects.clear();
    _balootDeclaredBy.clear();
    _escalationDefenderSeat = null;
    _lastRoundScoreResult = null;
    _lastPlaySawaClaimSeat = null;

    // Do NOT call startNewRound() here — let the UI show the dealing
    // spinner first. GameProvider._scheduleNextAction() will call
    // startNewRound() after a short delay.
  }

  @override
  void startNewRound() {
    logger.log('--- NEW ROUND ---');
    logger.log('Score: Team A $_teamAScore - $_teamBScore Team B');
    _lastRoundScoreResult = null;
    _lastPlaySawaClaimSeat = null;
    _botEngine.resetMemories();
    if (!_useInjectedDeckManager) {
      _deckManager = DeckManager(random: _rng);
    }

    _deckManager.createDeck();
    _deckManager.shuffle();
    _deckManager.kut();
    _deckManager.dealInitial(_dealerIndex);

    _hands = _deckManager.hands.map((h) => List<CardModel>.from(h)).toList();
    for (var i = 0; i < 4; i++) {
      _hands[i].sort((a, b) => a.compareTo(b));
    }

    final firstToBid = (_dealerIndex + 1) % 4;
    logger.log('Dealer: Seat $_dealerIndex. First to bid: Seat $firstToBid. Buyer card: ${_deckManager.buyerCard!.displayName}');
    _biddingManager = BiddingManager(
      dealerIndex: _dealerIndex,
      buyerCard: _deckManager.buyerCard!,
    );

    _roundState = RoundStateModel(
      dealerIndex: _dealerIndex,
      currentPlayerIndex: _biddingManager!.currentBidder, // Kammelna starts bidding at dealer + 2
      buyerCard: _deckManager.buyerCard,
    );

    _turnManager = null;
    _detectedProjects.clear();
    _activeDeclaredProjects.clear();
    _balootDeclaredBy.clear();
    _escalationDefenderSeat = null;
    _gamePhase = GamePhase.bidding;
  }

  @override
  void applyQaidPenalty(int violatorSeatIndex) {
    if (_gamePhase != GamePhase.playing) return;

    final winnerTeam = violatorSeatIndex % 2 == 0 ? 'B' : 'A';
    final mode = _roundState.activeMode ?? GameMode.sun;

    // Projects: count all declared projects for the winning team
    int teamAProjectScoreboard = 0, teamBProjectScoreboard = 0;
    for (final p in _activeDeclaredProjects) {
      if (p.type == ProjectType.baloot) continue;
      if (p.playerIndex % 2 == 0) {
        teamAProjectScoreboard += p.getScoreboardPoints(mode);
      } else {
        teamBProjectScoreboard += p.getScoreboardPoints(mode);
      }
    }

    // Baloot handling
    int balootPts = 0;
    String? balootTeam;
    final balootProjects = _activeDeclaredProjects.where((p) => p.type == ProjectType.baloot);
    if (balootProjects.isNotEmpty) {
      balootPts = 2;
      balootTeam = balootProjects.first.playerIndex % 2 == 0 ? 'A' : 'B';
    }

    final scoreResult = _scoringEngine.calculateViolationScore(
      mode: mode,
      winningTeam: winnerTeam,
      doubleStatus: _roundState.doubleStatus,
      teamAProjectScoreboard: teamAProjectScoreboard,
      teamBProjectScoreboard: teamBProjectScoreboard,
      balootPoints: balootPts,
      balootTeam: balootTeam,
    );

    _lastRoundScoreResult = scoreResult;
    _teamAScore += scoreResult.teamAPoints;
    _teamBScore += scoreResult.teamBPoints;

    logger.log('QAID VIOLATION by Seat $violatorSeatIndex. Penalty applied.');
    logger.log('Score Added -> Team A: +${scoreResult.teamAPoints}, Team B: +${scoreResult.teamBPoints}');

    // Check game end
    if (_scoringEngine.isGameOver(_teamAScore, _teamBScore, _roundState.doubleStatus)) {
      _gamePhase = GamePhase.gameOver;
    } else {
      _dealerIndex = (_dealerIndex + 1) % 4;
      _gamePhase = GamePhase.dealing;
    }
  }

  void _processEndOfRound(RoundScoreResult scoreResult) {
    _lastRoundScoreResult = scoreResult;
    _teamAScore += scoreResult.teamAPoints;
    _teamBScore += scoreResult.teamBPoints;
    
    if (_scoringEngine.isGameOver(_teamAScore, _teamBScore, _roundState.doubleStatus)) {
      _gamePhase = GamePhase.gameOver;
    }
  }

  @override
  void placeBid(int seatIndex, BidAction action, {Suit? secondHakamSuit}) {
    if (_gamePhase != GamePhase.bidding) {
      throw const InvalidMoveException('Not in bidding phase.');
    }

    final phaseBefore = _biddingManager!.phase;
    _biddingManager!.placeBid(seatIndex, action,
        secondHakamSuit: secondHakamSuit);
    String actionName = action.name;
    if (action == BidAction.pass && phaseBefore == BiddingPhase.round2) {
      actionName = 'wala';
    } else if (action == BidAction.secondHakam) {
      actionName = 'Second Hukam';
    } else if (action == BidAction.confirmHakam) {
      actionName = 'Confirm Hukam';
    }
    
    logger.log('Seat $seatIndex bid: $actionName${secondHakamSuit != null ? ' (${secondHakamSuit.name})' : ''}');

    _roundState = _roundState.copyWith(
      currentPlayerIndex: _biddingManager!.currentBidder,
      biddingPhase: _biddingManager!.phase,
    );

    if (_biddingManager!.isFinished) {
      final bidResult = _biddingManager!.result;

      if (bidResult == null || bidResult.isKasho) {
        // All passed both rounds, OR someone called Kasho → cancelled, advance dealer
        if (bidResult?.isKasho == true) {
          logger.log('Seat ${bidResult!.buyerIndex} called Kasho! Hand is garbage. Round cancelled.');
          _roundState = _roundState.copyWith(
            biddingPhase: BiddingPhase.cancelled,
            kashoPlayerIndex: bidResult.buyerIndex,
          );
        } else {
          logger.log('All players passed. Round cancelled.');
          _roundState = _roundState.copyWith(
            biddingPhase: BiddingPhase.cancelled,
          );
        }
        
        _dealerIndex = (_dealerIndex + 1) % 4; // dealer passes to the right
        _gamePhase = GamePhase.dealing;
        return;
      }

      // Ashkal (§4.6): bidder does not take the buyer card — teammate does. Stored
      // [RoundState.buyerIndex] must be that teammate for scoring / UI (Standard).
      final effectiveBuyerIndex = bidResult.isAshkal
          ? (bidResult.buyerIndex + 2) % 4
          : bidResult.buyerIndex;

      logger.log(
        'Bidding Complete. Mode: ${bidResult.mode.name}, Buyer: Seat $effectiveBuyerIndex'
        '${bidResult.isAshkal ? " (Ashkal bid by Seat ${bidResult.buyerIndex})" : ""}, '
        'Trump: ${bidResult.trumpSuit?.name}, Ashkal: ${bidResult.isAshkal}',
      );

      // Complete the deal ([dealRemainder] still takes the bidder index when Ashkal)
      _deckManager.dealRemainder(
        bidResult.buyerIndex,
        isAshkal: bidResult.isAshkal,
      );
      _hands = _deckManager.hands.map((h) => List<CardModel>.from(h)).toList();
      for (var i = 0; i < 4; i++) {
        _hands[i].sort((a, b) => a.compareTo(b));
      }

      // Detect projects in all hands
      for (int i = 0; i < 4; i++) {
        _detectedProjects[i] = _projectDetector.detectAll(
          _hands[i],
          bidResult.mode,
          trumpSuit: bidResult.trumpSuit,
        );
      }

      bool skipDouble = false;
      if (bidResult.mode == GameMode.sun) {
        final buyerTeamIsA = effectiveBuyerIndex % 2 == 0;
        final buyerPts = buyerTeamIsA ? _teamAScore : _teamBScore;
        final defPts = buyerTeamIsA ? _teamBScore : _teamAScore;
        if (buyerPts <= 100 || defPts >= 100) {
          skipDouble = true;
        }
      }

      _escalationDefenderSeat = null;
      _roundState = _roundState.copyWith(
        biddingPhase: BiddingPhase.completed,
        activeMode: bidResult.mode,
        trumpSuit: bidResult.trumpSuit,
        buyerIndex: effectiveBuyerIndex,
        isAshkal: bidResult.isAshkal,
        currentPlayerIndex: skipDouble ? (_dealerIndex + 1) % 4 : _firstDefenderSeat(effectiveBuyerIndex),
        isDoubleWindowOpen: !skipDouble,
      );

      if (skipDouble) {
        _gamePhase = GamePhase.playing;
        logger.log('Sun mode double conditions not met (buyer <= 100 or defender >= 100). Skipping double window.');
        _startPlayPhase();
      } else {
        _gamePhase = GamePhase.doubleWindow;
        logger.log('Starting double window');
      }
    }
  }

  @override
  void callDouble(int seatIndex, DoubleStatus level, {bool isOpenPlay = true}) {
    if (_gamePhase != GamePhase.doubleWindow) {
      throw const InvalidMoveException('Double window is not open.');
    }

    final buyerIndex = _roundState.buyerIndex!;
    final buyerIsTeamA = buyerIndex % 2 == 0;
    final callerIsTeamA = seatIndex % 2 == 0;

    // Jawaker/Kamelna: Double escalation alternates between teams.
    // Defending → Double, Buyer → Triple, Defending → Four, Buyer → Gahwa
    final bool callerShouldBeDefender =
        level == DoubleStatus.doubled || level == DoubleStatus.four;
    final bool callerShouldBeBuyer =
        level == DoubleStatus.tripled || level == DoubleStatus.gahwa;

    if (callerShouldBeDefender && callerIsTeamA == buyerIsTeamA) {
      throw InvalidBidException(
        playerIndex: seatIndex,
        message: 'Double/Four can only be called by the defending team.',
      );
    }
    if (callerShouldBeBuyer && callerIsTeamA != buyerIsTeamA) {
      throw InvalidBidException(
        playerIndex: seatIndex,
        message: 'Triple/Gahwa can only be called by the buyer team.',
      );
    }

    logger.log('Seat $seatIndex called Double Level: ${level.name}');

    // Sun (BALOOT_RULES.md §7.1): only a single Double — no Triple/Four/Gahwa.
    if (_roundState.activeMode == GameMode.sun &&
        (level == DoubleStatus.tripled ||
            level == DoubleStatus.four ||
            level == DoubleStatus.gahwa)) {
      throw InvalidBidException(
        playerIndex: seatIndex,
        message: 'Sun mode allows at most a Double — no Triple, Four, or Gahwa.',
      );
    }

    // Sun Double Exception (BALOOT_RULES.md Section 7.1):
    // In Sun mode, Double is ONLY allowed if the buyer has >100 pts
    // AND the opposing team has <100 pts.
    if (_roundState.activeMode == GameMode.sun) {
      final buyerScore = buyerIsTeamA ? _teamAScore : _teamBScore;
      final defenderScore = buyerIsTeamA ? _teamBScore : _teamAScore;
      if (buyerScore <= 100 || defenderScore >= 100) {
        throw InvalidBidException(
          playerIndex: seatIndex,
          message:
              'Sun Double only allowed when buyer >100 pts and defender <100 pts.',
        );
      }
    }

    // Only the initial Double selects Open/Closed; subsequent escalations inherit it.
    final bool effectiveIsOpenPlay =
        (level == DoubleStatus.doubled) ? isOpenPlay : _roundState.isOpenPlay;

    if (level == DoubleStatus.gahwa) {
      // Gahwa = highest level, instantly closes double window and starts the round
      _roundState = _roundState.copyWith(
        doubleStatus: level,
        doubleCallerIndex: seatIndex,
        isOpenPlay: effectiveIsOpenPlay,
        isDoubleWindowOpen: false,
      );
      _gamePhase = GamePhase.playing;
      _startPlayPhase();
      return;
    }

    if (callerShouldBeDefender &&
        (level == DoubleStatus.doubled || level == DoubleStatus.four)) {
      _escalationDefenderSeat = seatIndex;
    }

    int nextSeat = _roundState.currentPlayerIndex;
    if (level == DoubleStatus.doubled) {
      nextSeat = buyerIndex;
    } else if (level == DoubleStatus.tripled) {
      nextSeat = _escalationDefenderSeat ?? ((buyerIndex + 1) % 4);
    } else if (level == DoubleStatus.four) {
      nextSeat = buyerIndex;
    }

    _roundState = _roundState.copyWith(
      doubleStatus: level,
      doubleCallerIndex: seatIndex,
      isOpenPlay: effectiveIsOpenPlay,
      currentPlayerIndex: nextSeat,
    );
    logger.log('[DoubleDebug] callDouble: seat=$seatIndex level=$level → roundState.doubleStatus=${_roundState.doubleStatus}');
    debugPrint('[DoubleDebug] callDouble: seat=$seatIndex level=$level → ds=${_roundState.doubleStatus}');
  }

  /// Skip the double window for everyone and proceed to play.
  void skipDoubleWindow() {
    if (_gamePhase != GamePhase.doubleWindow) {
      throw const InvalidMoveException('Double window is not open.');
    }
    _escalationDefenderSeat = null;
    final dsBeforeSkip = _roundState.doubleStatus;
    _roundState = _roundState.copyWith(isDoubleWindowOpen: false);
    logger.log('[DoubleDebug] skipDoubleWindow: doubleStatus BEFORE=$dsBeforeSkip, AFTER=${_roundState.doubleStatus}');
    debugPrint('[DoubleDebug] skipDoubleWindow: BEFORE=$dsBeforeSkip AFTER=${_roundState.doubleStatus}');
    _gamePhase = GamePhase.playing;
    _startPlayPhase();
  }

  /// Pass the opportunity to double. Passes the turn to the partner if they haven't decided yet.
  void passDoubleWindow(int seatIndex) {
    if (_gamePhase != GamePhase.doubleWindow) {
      throw const InvalidMoveException('Double window is not open.');
    }
    
    if (seatIndex != _roundState.currentPlayerIndex) {
      return; // Ignore if not this player's turn
    }

    final buyerIndex = _roundState.buyerIndex!;
    final isDefender = (seatIndex % 2) != (buyerIndex % 2);

    if (isDefender) {
      // If it's the first defender's turn to double, pass to the second defender
      if (seatIndex == _firstDefenderSeat(buyerIndex)) {
         _roundState = _roundState.copyWith(currentPlayerIndex: (seatIndex + 2) % 4);
         return;
      }
    } else {
      // If it's the buyer's turn to escalate (Triple/Gahwa), pass to their partner
      if (seatIndex == buyerIndex) {
         _roundState = _roundState.copyWith(currentPlayerIndex: (seatIndex + 2) % 4);
         return;
      }
    }
    
    // If we reach here, both members of the team have passed, or the partner passed
    skipDoubleWindow();
  }

  void _startPlayPhase() {
    // Standard/Saudi rules: the player to the RIGHT of the dealer leads trick 1.
    final firstPlayer = (_dealerIndex + 1) % 4;
    _turnManager = TurnManager(
      mode: _roundState.activeMode!,
      trumpSuit: _roundState.trumpSuit,
      firstPlayerIndex: firstPlayer,
    );
    _roundState = _roundState.copyWith(
      currentPlayerIndex: firstPlayer,
      trickNumber: 1,
    );
  }

  @override
  bool canEkka(int seatIndex) {
    if (_gamePhase != GamePhase.playing) return false;
    // Akka is strictly a Hakam-only mechanic. It does not exist in Sun.
    if (_roundState.activeMode != GameMode.hakam) return false;
    // In Kammelna, Akka is not allowed on the very last trick (Trick 8).
    if (_roundState.trickNumber == 8) return false;
    if (_turnManager?.currentPlayerIndex != seatIndex) return false;
    // You can only call Ekka when leading a trick
    if (_turnManager?.currentTrick.isNotEmpty ?? true) return false;
    return true;
  }

  @override
  void claimEkka(int seatIndex) {
    if (!canEkka(seatIndex)) return;
    _ekkaClaimSeat = seatIndex;
    logger.log('Seat $seatIndex claimed Ekka!');
  }

  @override
  void playCard(int seatIndex, CardModel card, {bool skipValidation = false}) {
    if (_gamePhase != GamePhase.playing) {
      throw const InvalidMoveException('Not in play phase.');
    }
    if (seatIndex != _turnManager!.currentPlayerIndex) {
      throw InvalidMoveException(
        'Not your turn. Current player is seat ${_turnManager!.currentPlayerIndex}.',
      );
    }
    if (!_hands[seatIndex].contains(card)) {
      throw InvalidMoveException(
        'Card ${card.displayName} is not in your hand.',
      );
    }

    // Validate the play (skip when Card Restrictions are OFF — free play mode)
    if (!skipValidation) {
      final validation = _playValidator.validate(
        card: card,
        hand: _hands[seatIndex],
        currentTrick: _turnManager!.currentTrick,
        mode: _roundState.activeMode!,
        trumpSuit: _roundState.trumpSuit,
        doubleStatus: _roundState.doubleStatus,
        isOpenPlay: _roundState.isOpenPlay,
        playerSeat: seatIndex,
        playedCards: _turnManager!.playedCards,
        ekkaClaimSeat: _ekkaClaimSeat,
      );

      if (!validation.isValid) {
        throw PlayViolationException(
          type: _mapViolationKind(validation.violationKind!),
          playerIndex: seatIndex,
          message: validation.violationMessage!,
        );
      }
    }

    // Remove card from hand
    _hands[seatIndex].remove(card);

    // Baloot auto-declaration: when playing the 2nd card of the K-Q pair
    // of the trump suit (BALOOT_RULES.md Section 6.4)
    if (_roundState.activeMode == GameMode.hakam &&
        _roundState.trumpSuit != null &&
        !_balootDeclaredBy.contains(seatIndex)) {
      _checkBalootDeclaration(seatIndex, card);
    }

    // Feed card into bot memory system
    final Suit? leadSuit = _turnManager!.currentTrick.isNotEmpty
        ? _turnManager!.currentTrick.first.card.suit
        : null;
    _botEngine.recordCardPlayed(card, seatIndex, leadSuit);

    // Play the card and advance the turn.
    final trickResult = _turnManager!.playCard(seatIndex, card, advanceTurn: true, currentHands: _hands.asMap());
    logger.log('Seat $seatIndex played ${card.displayName}');

    _roundState = _roundState.copyWith(
      currentTrick: _turnManager!.currentTrick,
      currentPlayerIndex: _turnManager!.currentPlayerIndex,
    );

    // Project declarations are allowed during playing phase on Trick 1
    // (no separate projectDeclaration phase — uses the standard turn timer)
    
    if (trickResult != null) {
      _handleTrickResult(trickResult);
    }
  }


  /// Handles trick completion separately if needed, but playCard evaluates tricks synchronously.
  void _handleTrickResult(TrickResult trickResult) {
    // Feed trick result into bot memory
    _botEngine.recordTrickResult(trickResult.winnerIndex);
    // Trick complete
      logger.log('Trick completed. Winner: Seat ${trickResult.winnerIndex}');
      _ekkaClaimSeat = null; // Reset Ekka claim at the end of the trick
      _roundState = _roundState.copyWith(
        trickNumber: _turnManager!.trickNumber,
        currentTrick: const [],
        teamATricksWon: List.from(_turnManager!.teamATricksWon),
        teamBTricksWon: List.from(_turnManager!.teamBTricksWon),
        teamAAbnat: _turnManager!.teamAAbnat,
        teamBAbnat: _turnManager!.teamBAbnat,
      );

      // Check if Trick 1 just completed to filter losing projects (Standard rule)
      if (_turnManager!.trickNumber == 2 && _activeDeclaredProjects.isNotEmpty) {
        _filterLosingProjects();
      }

      // Check if round is complete (all 8 tricks played)
      if (_turnManager!.isRoundComplete) {
        _scoreRound();
      }
  }

  @override
  void declareProject(int seatIndex, int projectIndex) {
    // Standard: projects can be declared anytime during Trick 1 before playing your card.
    final hasPlayedCard = _turnManager!.currentTrick.any((p) => p.playerIndex == seatIndex);
    final validDeclarationTurn = _gamePhase == GamePhase.playing &&
        _turnManager != null &&
        _turnManager!.trickNumber == 1 &&
        !hasPlayedCard;
    if (!validDeclarationTurn) {
      throw const InvalidMoveException(
        'Projects can only be declared during the first trick before you play your card.',
      );
    }

    final playerProjects = _detectedProjects[seatIndex];
    if (playerProjects == null || projectIndex >= playerProjects.length) {
      throw const InvalidMoveException('Invalid project index.');
    }

    final project = playerProjects[projectIndex];
    if (project.type == ProjectType.baloot) {
      throw const InvalidMoveException(
        'Baloot is auto-declared, not manually.',
      );
    }

    // Check max 2 declared per player (non-Baloot)
    final alreadyDeclared = _activeDeclaredProjects
        .where((p) => p.playerIndex == seatIndex && p.type != ProjectType.baloot)
        .length;
    if (alreadyDeclared >= 2) {
      throw const InvalidMoveException('Max 2 projects per player.');
    }

    _activeDeclaredProjects.add(DeclaredProject(
      type: project.type,
      playerIndex: seatIndex,
      cards: project.cards,
    ));

    _roundState = _roundState.copyWith(
      declaredProjects: List.from(_activeDeclaredProjects),
    );
  }

  void undeclareProject(int seatIndex, ProjectType type) {
    final hasPlayedCard = _turnManager!.currentTrick.any((p) => p.playerIndex == seatIndex);
    final validDeclarationTurn = _gamePhase == GamePhase.playing &&
        _turnManager != null &&
        _turnManager!.trickNumber == 1 &&
        !hasPlayedCard;
    if (!validDeclarationTurn) {
      return; // Silently ignore invalid un-declares
    }

    final toRemove = _activeDeclaredProjects.where((p) => p.playerIndex == seatIndex && p.type == type).toList();
    if (toRemove.isNotEmpty) {
      _activeDeclaredProjects.remove(toRemove.first);
      _roundState = _roundState.copyWith(
        declaredProjects: List.from(_activeDeclaredProjects),
      );
    }
  }

  /// Whether the human player (seat 0) can currently claim Qaid.
  /// Per HTML spec: Qaid is available at ANY time after the first card of the
  /// round has been played (mid-trick, between tricks — any time).
  /// It is only disabled during: dealing, bidding, multiplier window,
  /// when another Qaid is already in progress, and after the round ends.
  bool canClaimQaid(int seatIndex) {
    if (_gamePhase != GamePhase.playing || _turnManager == null) return false;
    // Qaid is only available once at least Trick 1 has completed
    // so there is at least one trick in history to review and challenge.
    if (_turnManager!.trickHistory.isEmpty) return false;
    return true;
  }

  /// Retrospectively check if the last card played by an opponent of [accuserSeat]
  /// was a violation. Returns the violator's seat index if a violation is found,
  /// or null if the play was legal (meaning it's a false Qaid claim).
  int? checkLastPlayViolation(int accuserSeat) {
    if (_gamePhase != GamePhase.playing || _turnManager == null) return null;
    final trick = _turnManager!.currentTrick;
    if (trick.isEmpty) return null;

    // Find the most recent card played by an opponent
    CardPlayModel? opponentPlay;
    for (int i = trick.length - 1; i >= 0; i--) {
      final play = trick[i];
      final isOpponent = (play.playerIndex % 2) != (accuserSeat % 2);
      if (isOpponent) {
        opponentPlay = play;
        break;
      }
    }
    if (opponentPlay == null) return null;

    final opponentSeat = opponentPlay.playerIndex;
    final card = opponentPlay.card;

    // Reconstruct the trick state at the time the opponent played
    // (all cards played BEFORE the opponent's card)
    final trickBeforePlay = <CardPlayModel>[];
    for (final play in trick) {
      if (play.playerIndex == opponentSeat && play.card == card) break;
      trickBeforePlay.add(play);
    }

    // Reconstruct the opponent's hand at that time:
    // current hand + all cards they've played since (including this one)
    final opponentHandNow = _hands[opponentSeat];
    final opponentPlayedCards = <CardModel>[];
    // Cards played by this opponent in the current trick (including the one in question)
    for (final play in trick) {
      if (play.playerIndex == opponentSeat) {
        opponentPlayedCards.add(play.card);
      }
    }
    // Also include cards played in previous tricks by this opponent
    for (final trickResult in _turnManager!.trickHistory) {
      for (final play in trickResult.cards) {
        if (play.playerIndex == opponentSeat) {
          opponentPlayedCards.add(play.card);
        }
      }
    }
    // Hand at the time = current hand + all played cards
    final opponentHandAtTime = [...opponentHandNow, ...opponentPlayedCards];

    // Validate the play retrospectively
    final validation = _playValidator.validate(
      card: card,
      hand: opponentHandAtTime,
      currentTrick: trickBeforePlay,
      mode: _roundState.activeMode!,
      trumpSuit: _roundState.trumpSuit,
      doubleStatus: _roundState.doubleStatus,
      isOpenPlay: _roundState.isOpenPlay,
      playerSeat: opponentSeat,
      playedCards: _turnManager!.playedCards,
    );

    if (!validation.isValid) {
      return opponentSeat; // Violation found!
    }
    return null; // Play was legal → false claim
  }

  bool canSawa(int seatIndex) {
    if (_gamePhase != GamePhase.playing || _turnManager == null) return false;
    
    // In Kammelna & official Baloot rules, Sawa is strictly a late-game action:
    // Only available when 4 cards or fewer remain in hand (i.e. Trick 5 or later)
    if (_hands[seatIndex].length > 4) {
      return false;
    }

    // Only allow Sawa if it's the player's turn to lead a trick
    // (i.e. no cards have been played in the current trick yet)
    if (_turnManager!.currentPlayerIndex != seatIndex || _turnManager!.currentTrick.isNotEmpty) {
      return false;
    }

    return true;
  }

  /// Evaluates whether the Sawa claim made by [seatIndex] is actually correct.
  /// Used by the Engine to resolve Objections, and by Bots to decide if they should object.
  bool isSawaMathematicallyValid(int seatIndex) {
    if (_turnManager == null) return false;
    
    final playedCards = _turnManager!.trickHistory
        .expand((trick) => trick.cards)
        .map((play) => play.card)
        .toList();

    return SawaProbabilityEngine.canSawaYad(
      playerSeat: seatIndex,
      playerHand: _hands[seatIndex],
      playedCards: playedCards,
      mode: _roundState.activeMode!,
      trumpSuit: _roundState.trumpSuit,
      allHands: _hands,
    );
  }

  @override
  void claimSawa(int seatIndex) {
    logger.log('--- SAWA CLAIMED by Seat $seatIndex ---');
    _lastPlaySawaClaimSeat = seatIndex;

    final tm = _turnManager!;
    final teamIndex = seatIndex % 2;

    logger.log(
        'Play Sawa: claimant Seat $seatIndex (Team ${teamIndex == 0 ? 'A' : 'B'}); '
        'Buyer seat ${_roundState.buyerIndex} (Team ${_roundState.buyerIndex! % 2 == 0 ? 'A' : 'B'}) — '
        '+remaining card Abnat + ground → claimant team tally.');


    // Award point value of all cards still held (remaining tricks folded into one tally).
    int remainingAbnat = 0;
    for (int s = 0; s < 4; s++) {
      for (final card in _hands[s]) {
        remainingAbnat += card.getPointValue(
          mode: _roundState.activeMode!,
          trumpSuit: _roundState.trumpSuit,
        );
      }
      _hands[s].clear();
    }

    final claimantWonTeamA = teamIndex == 0;

    if (claimantWonTeamA) {
      tm.teamAAbnat += remainingAbnat;
    } else {
      tm.teamBAbnat += remainingAbnat;
    }

    // Assign each not-yet-played trick index to the claimant's team (skip duplicates).
    for (int trickIdx = tm.trickNumber; trickIdx <= 8; trickIdx++) {
      final already =
          tm.teamATricksWon.contains(trickIdx) || tm.teamBTricksWon.contains(trickIdx);
      if (already) continue;
      if (claimantWonTeamA) {
        tm.teamATricksWon.add(trickIdx);
      } else {
        tm.teamBTricksWon.add(trickIdx);
      }
    }

    // Single +10 ground for the final trick of the round (same as normal trick 8).
    if (claimantWonTeamA) {
      tm.teamAAbnat += 10;
    } else {
      tm.teamBAbnat += 10;
    }

    tm.trickHistory.add(TrickResult(
      winnerIndex: seatIndex,
      cards: const <CardPlayModel>[],
      abnat: remainingAbnat,
      isLastTrick: true,
      lastTrickBonus: 10,
    ));

    tm.markRoundSealedAfterPlayClaimSawa();

    _roundState = _roundState.copyWith(
      trickNumber: 9,
      currentTrick: const [],
      currentPlayerIndex: seatIndex,
      teamATricksWon: List.from(tm.teamATricksWon),
      teamBTricksWon: List.from(tm.teamBTricksWon),
      teamAAbnat: tm.teamAAbnat,
      teamBAbnat: tm.teamBAbnat,
    );

    _scoreRound();
  }

  @override
  void resolveSawaObjection(int claimantSeat, bool isObjectionCorrect) {
    if (_gamePhase != GamePhase.playing) return;

    if (isObjectionCorrect) {
      // The objection was correct -> The claimant made a false Sawa claim.
      // This is a Khataa. The opposing team instantly wins all points (Kabout).
      final winnerTeam = claimantSeat % 2 == 0 ? 'B' : 'A';
      final mode = _roundState.activeMode ?? GameMode.sun;
      
      // Projects: The claiming team forfeits all projects. We only count the winning team's projects.
      int teamAProjectScoreboard = 0, teamBProjectScoreboard = 0;
      for (final p in _activeDeclaredProjects) {
        if (p.type == ProjectType.baloot) continue;
        if (p.playerIndex % 2 == 0) {
          if (winnerTeam == 'A') teamAProjectScoreboard += p.getScoreboardPoints(mode);
        } else {
          if (winnerTeam == 'B') teamBProjectScoreboard += p.getScoreboardPoints(mode);
        }
      }

      int balootPts = 0;
      String? balootTeam;
      final balootProjects = _activeDeclaredProjects.where((p) => p.type == ProjectType.baloot);
      if (balootProjects.isNotEmpty) {
        final bTeam = balootProjects.first.playerIndex % 2 == 0 ? 'A' : 'B';
        if (bTeam == winnerTeam) {
          balootPts = 2;
          balootTeam = bTeam;
        }
      }

      final scoreResult = _scoringEngine.calculateViolationScore(
        mode: mode,
        winningTeam: winnerTeam,
        doubleStatus: _roundState.doubleStatus,
        teamAProjectScoreboard: teamAProjectScoreboard,
        teamBProjectScoreboard: teamBProjectScoreboard,
        balootPoints: balootPts,
        balootTeam: balootTeam,
      );

      final finalScoreResult = RoundScoreResult(
        teamAPoints: scoreResult.teamAPoints,
        teamBPoints: scoreResult.teamBPoints,
        teamARawAbnat: scoreResult.teamARawAbnat,
        teamBRawAbnat: scoreResult.teamBRawAbnat,
        isKhams: scoreResult.isKhams,
        isKabout: scoreResult.isKabout,
        winningTeam: scoreResult.winningTeam,
        reason: 'false_sawa_claim',
        teamATrickAbnat: scoreResult.teamATrickAbnat,
        teamBTrickAbnat: scoreResult.teamBTrickAbnat,
        lastTrickBonusTeam: scoreResult.lastTrickBonusTeam,
        teamAProjectAbnat: scoreResult.teamAProjectAbnat,
        teamBProjectAbnat: scoreResult.teamBProjectAbnat,
        mode: scoreResult.mode,
        buyerTeam: scoreResult.buyerTeam,
        doubleStatus: scoreResult.doubleStatus,
        teamAProjectsList: scoreResult.teamAProjectsList,
        teamBProjectsList: scoreResult.teamBProjectsList,
      );

      _lastRoundScoreResult = finalScoreResult;
      _teamAScore += finalScoreResult.teamAPoints;
      _teamBScore += finalScoreResult.teamBPoints;

      logger.log('FALSE SAWA CLAIM by Seat $claimantSeat. Penalty applied.');
      logger.log('Score Added -> Team A: +${finalScoreResult.teamAPoints}, Team B: +${finalScoreResult.teamBPoints}');

      if (_scoringEngine.isGameOver(_teamAScore, _teamBScore, _roundState.doubleStatus)) {
        _gamePhase = GamePhase.gameOver;
      } else {
        _dealerIndex = (_dealerIndex + 1) % 4;
        _gamePhase = GamePhase.scoring;
      }
    } else {
      // The objection was incorrect -> The claimant's Sawa was actually valid.
      // In competitive Baloot / Kammelna, false objection carries full round penalty against the challenger.
      final winnerTeam = claimantSeat % 2 == 0 ? 'A' : 'B';
      final mode = _roundState.activeMode ?? GameMode.sun;

      int teamAProjectScoreboard = 0, teamBProjectScoreboard = 0;
      for (final p in _activeDeclaredProjects) {
        if (p.type == ProjectType.baloot) continue;
        if (p.playerIndex % 2 == 0) {
          if (winnerTeam == 'A') teamAProjectScoreboard += p.getScoreboardPoints(mode);
        } else {
          if (winnerTeam == 'B') teamBProjectScoreboard += p.getScoreboardPoints(mode);
        }
      }

      int balootPts = 0;
      String? balootTeam;
      final balootProjects = _activeDeclaredProjects.where((p) => p.type == ProjectType.baloot);
      if (balootProjects.isNotEmpty) {
        final bTeam = balootProjects.first.playerIndex % 2 == 0 ? 'A' : 'B';
        if (bTeam == winnerTeam) {
          balootPts = 2;
          balootTeam = bTeam;
        }
      }

      final scoreResult = _scoringEngine.calculateViolationScore(
        mode: mode,
        winningTeam: winnerTeam,
        doubleStatus: _roundState.doubleStatus,
        teamAProjectScoreboard: teamAProjectScoreboard,
        teamBProjectScoreboard: teamBProjectScoreboard,
        balootPoints: balootPts,
        balootTeam: balootTeam,
      );

      final finalScoreResult = RoundScoreResult(
        teamAPoints: scoreResult.teamAPoints,
        teamBPoints: scoreResult.teamBPoints,
        teamARawAbnat: scoreResult.teamARawAbnat,
        teamBRawAbnat: scoreResult.teamBRawAbnat,
        isKhams: scoreResult.isKhams,
        isKabout: scoreResult.isKabout,
        winningTeam: scoreResult.winningTeam,
        reason: 'valid_sawa_claim',
        teamATrickAbnat: scoreResult.teamATrickAbnat,
        teamBTrickAbnat: scoreResult.teamBTrickAbnat,
        lastTrickBonusTeam: scoreResult.lastTrickBonusTeam,
        teamAProjectAbnat: scoreResult.teamAProjectAbnat,
        teamBProjectAbnat: scoreResult.teamBProjectAbnat,
        mode: scoreResult.mode,
        buyerTeam: scoreResult.buyerTeam,
        doubleStatus: scoreResult.doubleStatus,
        teamAProjectsList: scoreResult.teamAProjectsList,
        teamBProjectsList: scoreResult.teamBProjectsList,
      );

      _lastRoundScoreResult = finalScoreResult;
      _teamAScore += finalScoreResult.teamAPoints;
      _teamBScore += finalScoreResult.teamBPoints;

      logger.log('VALID SAWA CONFIRMED for Seat $claimantSeat. False objection penalty applied to challenger.');
      logger.log('Score Added -> Team A: +${finalScoreResult.teamAPoints}, Team B: +${finalScoreResult.teamBPoints}');

      if (_scoringEngine.isGameOver(_teamAScore, _teamBScore, _roundState.doubleStatus)) {
        _gamePhase = GamePhase.gameOver;
      } else {
        _dealerIndex = (_dealerIndex + 1) % 4;
        _gamePhase = GamePhase.scoring;
      }
    }
  }

  void _filterLosingProjects() {
    // Separate projects by team
    final teamAProjects = _activeDeclaredProjects
        .where((p) => p.playerIndex % 2 == 0)
        .toList();
    final teamBProjects = _activeDeclaredProjects
        .where((p) => p.playerIndex % 2 != 0)
        .toList();

    if (teamAProjects.isEmpty && teamBProjects.isEmpty) return;

    final projectWinner = _projectDetector.resolveProjectPriority(
      teamAProjects,
      teamBProjects,
      _roundState.activeMode!,
      _roundState.trumpSuit,
      (_dealerIndex + 1) % 4,
    );

    final hasSeqA = teamAProjects.any((p) => p.type != ProjectType.baloot);
    final hasSeqB = teamBProjects.any((p) => p.type != ProjectType.baloot);

    if (projectWinner == 'A') {
      // Team A won, delete Team B's projects (except Baloot, which is handled later)
      _activeDeclaredProjects.removeWhere((p) => p.playerIndex % 2 != 0 && p.type != ProjectType.baloot);
      if (hasSeqB) {
        logger.log('Team A won project priority. Team B projects nullified.');
      } else if (hasSeqA) {
        logger.log('Team A won project priority.');
      }
    } else if (projectWinner == 'B') {
      // Team B won, delete Team A's projects
      _activeDeclaredProjects.removeWhere((p) => p.playerIndex % 2 == 0 && p.type != ProjectType.baloot);
      if (hasSeqA) {
        logger.log('Team B won project priority. Team A projects nullified.');
      } else if (hasSeqB) {
        logger.log('Team B won project priority.');
      }
    }
  }

  void _scoreRound() {
    logger.log('[DoubleDebug] _scoreRound called: doubleStatus=${_roundState.doubleStatus}');
    debugPrint('[DoubleDebug] _scoreRound: doubleStatus=${_roundState.doubleStatus}');
    _gamePhase = GamePhase.scoring;

    final mode = _roundState.activeMode!;
    final buyerIndex = _roundState.buyerIndex!;
    final buyerTeam = buyerIndex % 2 == 0 ? 'A' : 'B';

    // Separate remaining winning projects by team
    final teamAProjects = _activeDeclaredProjects
        .where((p) => p.playerIndex % 2 == 0)
        .toList();
    final teamBProjects = _activeDeclaredProjects
        .where((p) => p.playerIndex % 2 != 0)
        .toList();

    // Resolve project priority
    final projectWinner = _projectDetector.resolveProjectPriority(
      teamAProjects,
      teamBProjects,
      mode,
      _roundState.trumpSuit,
      (_dealerIndex + 1) % 4,
    );

    // Calculate project Abnat and scoreboard points
    int teamAProjectAbnat = 0, teamBProjectAbnat = 0;
    int teamAProjectScoreboard = 0, teamBProjectScoreboard = 0;

    for (final p in teamAProjects) {
      if (p.type != ProjectType.baloot) {
        teamAProjectAbnat += p.getAbnat(mode);
        teamAProjectScoreboard += p.getScoreboardPoints(mode);
      }
    }
    for (final p in teamBProjects) {
      if (p.type != ProjectType.baloot) {
        teamBProjectAbnat += p.getAbnat(mode);
        teamBProjectScoreboard += p.getScoreboardPoints(mode);
      }
    }

    // Baloot handling
    int balootPts = 0;
    String? balootTeam;
    final balootProjects = _activeDeclaredProjects
        .where((p) => p.type == ProjectType.baloot);
    if (balootProjects.isNotEmpty) {
      balootPts = 2;
      balootTeam = balootProjects.first.playerIndex % 2 == 0 ? 'A' : 'B';
    }

    // Determine double caller team
    String? doubleCallerTeam;
    if (_roundState.doubleStatus != DoubleStatus.none) {
      final defenderTeam = buyerTeam == 'A' ? 'B' : 'A';
      switch (_roundState.doubleStatus) {
        case DoubleStatus.doubled:
        case DoubleStatus.four:
          doubleCallerTeam = defenderTeam; // Defender calls these
          break;
        case DoubleStatus.tripled:
        case DoubleStatus.gahwa:
          doubleCallerTeam = buyerTeam; // Buyer calls these
          break;
        case DoubleStatus.none:
          break;
      }
    }

    final buyerCardIsAce = _roundState.buyerCard?.rank == Rank.ace;

    // Determine which team won the last trick (for +10 ground bonus display)
    final lastTrickTeam = _turnManager!.trickHistory.isNotEmpty
        ? (_turnManager!.trickHistory.last.winnerIndex % 2 == 0 ? 'A' : 'B')
        : null;

    final scoreResult = _scoringEngine.calculateRoundScore(
      teamAAbnat: _turnManager!.teamAAbnat,
      teamBAbnat: _turnManager!.teamBAbnat,
      mode: mode,
      buyerTeam: buyerTeam,
      teamATricksCount: _turnManager!.teamATricksWon.length,
      teamBTricksCount: _turnManager!.teamBTricksWon.length,
      lastTrickBonusTeam: lastTrickTeam,
      teamAProjectAbnat: teamAProjectAbnat,
      teamBProjectAbnat: teamBProjectAbnat,
      teamAProjectScoreboard: teamAProjectScoreboard,
      teamBProjectScoreboard: teamBProjectScoreboard,
      balootPoints: balootPts,
      balootTeam: balootTeam,
      doubleStatus: _roundState.doubleStatus,
      isKabout: _turnManager!.isKabout,
      buyerCardIsAce: buyerCardIsAce,
      projectWinningTeam: projectWinner,
      doubleCallerTeam: doubleCallerTeam,
      teamAProjectsList: teamAProjects.where((p) => p.type != ProjectType.baloot).toList(),
      teamBProjectsList: teamBProjects.where((p) => p.type != ProjectType.baloot).toList(),
    );

    _lastRoundScoreResult = scoreResult;

    _teamAScore += scoreResult.teamAPoints;
    _teamBScore += scoreResult.teamBPoints;
    logger.log('Round Score Added -> Team A: +${scoreResult.teamAPoints}, Team B: +${scoreResult.teamBPoints}');
    logger.log('--- Standard SCORE BREAKDOWN ---');
    logger.log('  Buyer: Seat ${_roundState.buyerIndex} (Team $buyerTeam)');
    logger.log('  Mode: ${scoreResult.mode.name.toUpperCase()}, Double: ${scoreResult.doubleStatus.name}');
    logger.log('  Outcome Reason: ${scoreResult.reason ?? "Normal"}');
    if (_lastPlaySawaClaimSeat != null) {
      logger.log(
          '  In-play Sawa: Seat $_lastPlaySawaClaimSeat claimed remaining tricks');
    }
    logger.log('  Trick Abnat (Cards): A=${scoreResult.teamATrickAbnat}, B=${scoreResult.teamBTrickAbnat}');
    if (lastTrickTeam != null) {
      logger.log('  Ground Bonus (+10): Team $lastTrickTeam');
    }
    
    // Log explicit projects (seat disambiguates two Sera / Fifty on same team)
    for (final p in teamAProjects) {
      if (p.type != ProjectType.baloot) {
        logger.log(
          '  Project (Team A, seat ${p.playerIndex} ${_playerNames[p.playerIndex]}): ${p.type.name} (${p.getAbnat(mode)} Abnat)',
        );
      }
    }
    for (final p in teamBProjects) {
      if (p.type != ProjectType.baloot) {
        logger.log(
          '  Project (Team B, seat ${p.playerIndex} ${_playerNames[p.playerIndex]}): ${p.type.name} (${p.getAbnat(mode)} Abnat)',
        );
      }
    }
    
    if (projectWinner != null) {
      logger.log('  Project Priority Winner: Team $projectWinner');
    }

    if (scoreResult.isKhams) {
      logger.log(
        '  Sequence project Abnat (Khams: all credited to defenders Team ${scoreResult.winningTeam}): A=${scoreResult.teamAProjectAbnat}, B=${scoreResult.teamBProjectAbnat}',
      );
    } else {
      logger.log(
        '  Effective Project Abnat (after priority): A=${scoreResult.teamAProjectAbnat}, B=${scoreResult.teamBProjectAbnat}',
      );
    }

    if (balootTeam != null) {
      logger.log('  Baloot Declared: Team $balootTeam (+2 Scoreboard Pts)');
    }

    // Check game end
    if (_scoringEngine.isGameOver(_teamAScore, _teamBScore, _roundState.doubleStatus)) {
      logger.log('GAME OVER! Final Score - Team A: $_teamAScore, Team B: $_teamBScore');
      _gamePhase = GamePhase.gameOver;
    } else {
      // Advance dealer to the right for next round
      _dealerIndex = (_dealerIndex + 1) % 4;
      _gamePhase = GamePhase.scoring;
    }
  }

  // ── Qaydha Integration ──
  
  @override
  void applyQaydhaResult(QaydhaResult qaydhaResult) {
    if (_gamePhase != GamePhase.playing) return;

    logger.log('--- QAYDHA CHALLENGE FIRED ---');
    logger.log('Is Correct: ${qaydhaResult.isCorrect}, Type: ${qaydhaResult.violationType.name}');
    
    _endRoundWithQaydha(qaydhaResult);
  }

  void _endRoundWithQaydha(QaydhaResult qaydhaResult) {
    _gamePhase = GamePhase.scoring;

    final mode = _roundState.activeMode ?? GameMode.hakam;
    final buyerTeam = _roundState.buyerIndex != null ? (_roundState.isBuyerTeamA() ? 'A' : 'B') : 'A';

    // 1. Calculate project Abnat (both teams keep their declared projects)
    int teamAProjectAbnat = 0;
    int teamBProjectAbnat = 0;
    int teamAProjectScoreboard = 0;
    int teamBProjectScoreboard = 0;

    final teamAProjects = _activeDeclaredProjects.where((p) => _roundState.isTeamA(p.playerIndex)).toList();
    final teamBProjects = _activeDeclaredProjects.where((p) => !_roundState.isTeamA(p.playerIndex)).toList();

    for (final p in teamAProjects) {
      if (p.type != ProjectType.baloot) {
        teamAProjectAbnat += p.getAbnat(mode);
        teamAProjectScoreboard += p.getScoreboardPoints(mode);
      }
    }
    for (final p in teamBProjects) {
      if (p.type != ProjectType.baloot) {
        teamBProjectAbnat += p.getAbnat(mode);
        teamBProjectScoreboard += p.getScoreboardPoints(mode);
      }
    }

    // 2. Baloot
    int balootPts = 0;
    String? balootTeam;
    if (_balootDeclaredBy.isNotEmpty) {
      final seat = _balootDeclaredBy.first;
      balootPts = 2; // Fixed scoreboard points
      balootTeam = _roundState.isTeamA(seat) ? 'A' : 'B';
    }

    // Get current trick points so far, PLUS all unplayed cards as part of the trick penalty pool
    int baseTotalTrickAbnat = mode == GameMode.hakam ? 152 : 130;
    int groundBonus = 10;
    int totalTrickPool = baseTotalTrickAbnat + groundBonus;

    // Fake the Abnat so that one team gets the full pool and the other gets 0
    final isChallengerA = qaydhaResult.challengerIndex % 2 == 0;
    final winnerIsA = qaydhaResult.isCorrect ? isChallengerA : !isChallengerA;
    final winnerTeam = winnerIsA ? 'A' : 'B';
    
    final scoreResult = _scoringEngine.calculateRoundScore(
      teamAAbnat: winnerIsA ? totalTrickPool : 0,
      teamBAbnat: winnerIsA ? 0 : totalTrickPool,
      lastTrickBonusTeam: winnerTeam,
      projectWinningTeam: winnerTeam,
      mode: mode,
      buyerTeam: buyerTeam,
      teamATricksCount: winnerIsA ? 8 : 0,
      teamBTricksCount: winnerIsA ? 0 : 8,
      teamAProjectAbnat: teamAProjectAbnat,
      teamBProjectAbnat: teamBProjectAbnat,
      teamAProjectScoreboard: teamAProjectScoreboard,
      teamBProjectScoreboard: teamBProjectScoreboard,
      balootPoints: balootPts,
      balootTeam: balootTeam,
      doubleStatus: _roundState.doubleStatus,
      isKabout: false,
      buyerCardIsAce: false,
      qaydhaResult: qaydhaResult,
      teamAProjectsList: teamAProjects.where((p) => p.type != ProjectType.baloot).toList(),
      teamBProjectsList: teamBProjects.where((p) => p.type != ProjectType.baloot).toList(),
    );

    _lastRoundScoreResult = scoreResult;

    _teamAScore += scoreResult.teamAPoints;
    _teamBScore += scoreResult.teamBPoints;
    logger.log('Round Score (QAYDHA) -> Team A: +${scoreResult.teamAPoints}, Team B: +${scoreResult.teamBPoints}');

    if (_roundState.doubleStatus == DoubleStatus.gahwa) {
      if (scoreResult.winningTeam == 'A') _teamAScore = _targetScore;
      else _teamBScore = _targetScore;
    }

    if (_teamAScore >= _targetScore || _teamBScore >= _targetScore) {
      if (_teamAScore != _teamBScore) {
        _gamePhase = GamePhase.gameOver;
      } else {
        // tie - play one more round
        _dealerIndex = (_dealerIndex + 1) % 4;
      }
    } else {
      _dealerIndex = (_dealerIndex + 1) % 4;
    }
  }

  // ── Bot Logic ──

  /// Smart bot play using [BotEngine] for strategic decisions.
  ///
  /// Bidding: evaluates hand strength to decide Hakam/Sun/Pass/etc.
  /// Playing: considers trick position, partner, trumps, point dumping.
  /// Double: evaluates hand defensively, may call Double with strong hand.
  void botPlay(int seatIndex) {
    switch (_gamePhase) {
      case GamePhase.bidding:
        final bm = _biddingManager!;
        final decision = _botEngine.decideBid(
          hand: _hands[seatIndex],
          buyerCard: _deckManager.buyerCard!,
          phase: bm.phase,
          seatIndex: seatIndex,
          dealerIndex: _dealerIndex,
          round2PendingBid: bm.hasRound2PendingBid,
          round2PendingBuyerSeat:
              bm.hasRound2PendingBid ? bm.activeRound2PendingBuyerSeat : null,
          round2PendingMode:
              bm.hasRound2PendingBid ? bm.activeRound2PendingMode : null,
          round2PendingTrump:
              bm.hasRound2PendingBid ? bm.activeRound2PendingTrump : null,
          round1HakamBidderSeat:
              bm.phase == BiddingPhase.round1 && bm.hasActiveHakamBid
                  ? bm.activeRound1HakamSeat
                  : null,
        );
        placeBid(seatIndex, decision.action,
            secondHakamSuit: decision.secondHakamSuit);

      case GamePhase.doubleWindow:
        final buyerIdx = _roundState.buyerIndex ?? 0;
        final botIsDefender = (seatIndex % 2) != (buyerIdx % 2);
        
        if (_roundState.activeMode == GameMode.hakam) {
          final level = _botEngine.decideDouble(
            hand: _hands[seatIndex],
            mode: _roundState.activeMode!,
            trumpSuit: _roundState.trumpSuit,
            ownScore: seatIndex % 2 == 0 ? _teamAScore : _teamBScore,
            opponentScore: seatIndex % 2 == 0 ? _teamBScore : _teamAScore,
            currentDoubleStatus: _roundState.doubleStatus,
            isDefender: botIsDefender,
          );
          if (level != null) {
            callDouble(seatIndex, level);
            return;
          }
        }
        passDoubleWindow(seatIndex);

      // Project declarations by bots now happen during playing phase, Trick 1
      case GamePhase.playing:
        if (_turnManager != null && _turnManager!.trickNumber == 1) {
          final hasDeclaredAlready = _activeDeclaredProjects.any((p) => p.playerIndex == seatIndex && p.type != ProjectType.baloot);
          if (!hasDeclaredAlready) {
             final declared = _botDeclareProjects(seatIndex);
             if (declared) return; // Yield turn so UI updates, timer will fire again to play the card
          }
        }
        
        // For Qaid testing, prevent the user's partner (seat 2, or any even seat assuming user is 0) 
        // from committing card-play violations, because the user cannot challenge their own partner.
        BotCheatMode currentCheatMode = activeCheatMode;
        if (seatIndex % 2 == 0 && currentCheatMode != BotCheatMode.none && currentCheatMode != BotCheatMode.falseAkka && currentCheatMode != BotCheatMode.falseSawa) {
          currentCheatMode = BotCheatMode.none;
        }

        if (currentCheatMode == BotCheatMode.falseAkka && canEkka(seatIndex)) {
          // Cheat mode: Force an Akka claim when leading, even if not mathematically correct
          _ekkaClaimSeat = seatIndex;
          logger.log('Cheat Mode: Seat $seatIndex forced False Ekka!');
          // We don't return here so the bot actually plays the card right after claiming.
        }

        final card = _botEngine.decidePlay(
          hand: _hands[seatIndex],
          currentTrick: _turnManager!.currentTrick,
          mode: _roundState.activeMode!,
          trumpSuit: _roundState.trumpSuit,
          doubleStatus: _roundState.doubleStatus,
          isOpenPlay: _roundState.isOpenPlay,
          seatIndex: seatIndex,
          trickNumber: _turnManager!.trickNumber,
          teamAAbnat: _turnManager!.teamAAbnat,
          teamBAbnat: _turnManager!.teamBAbnat,
          buyerIndex: _roundState.buyerIndex ?? -1,
          trickHistory: _turnManager!.trickHistory,
          ekkaClaimSeat: _ekkaClaimSeat,
          cheatMode: currentCheatMode,
        );
        
        // Skip validation if cheat mode is active and the card is illegal
        final validCards = getValidCards(seatIndex);
        final bool isCardIllegal = !validCards.contains(card);
        final bool shouldSkipValidation = currentCheatMode != BotCheatMode.none && isCardIllegal;
        
        if (shouldSkipValidation) {
          _lastCheatSeat = seatIndex;
        }

        playCard(seatIndex, card, skipValidation: shouldSkipValidation);

      default:
        break;
    }
  }

  /// Bot auto-declares all available non-Baloot projects during trick 1.
  /// Returns true if any project was declared.
  bool _botDeclareProjects(int seatIndex) {
    bool declaredAny = false;
    final projects = _detectedProjects[seatIndex];
    if (projects == null) return false;

    for (int i = 0; i < projects.length; i++) {
      if (projects[i].type == ProjectType.baloot) continue;
      final alreadyDeclared = _activeDeclaredProjects
          .where(
              (p) => p.playerIndex == seatIndex && p.type != ProjectType.baloot)
          .length;
      if (alreadyDeclared >= 2) break;
      try {
        declareProject(seatIndex, i);
        declaredAny = true;
      } catch (_) {
        break;
      }
    }
    return declaredAny;
  }



  // ── State Queries ──

  @override
  RoundStateModel get roundState => _roundState;

  @override
  List<CardModel> getHand(int seatIndex) => List.unmodifiable(_hands[seatIndex]);

  @override
  ({int teamA, int teamB}) get gameScore =>
      (teamA: _teamAScore, teamB: _teamBScore);

  @override
  bool get isGameOver => _gamePhase == GamePhase.gameOver;

  /// Whether there's an active Hakam bid in Round 1 (Sawa is available).
  bool get hasActiveHakamBid =>
      _biddingManager?.hasActiveHakamBid ?? false;

  /// Round 2: Sun / Second Hakam bid placed; others must Pass or Sawa.
  bool get hasRound2PendingBid =>
      _biddingManager?.hasRound2PendingBid ?? false;

  int? get activeRound1HakamSeat =>
      _biddingManager?.activeRound1HakamSeat;

  int? get activeRound2PendingBuyerSeat =>
      _biddingManager?.activeRound2PendingBuyerSeat;

  GameMode? get activeRound2PendingMode =>
      _biddingManager?.activeRound2PendingMode;

  Suit? get activeRound2PendingTrump =>
      _biddingManager?.activeRound2PendingTrump;

  bool get isRound2Confirmation =>
      _biddingManager?.isRound2Confirmation ?? false;

  /// Current pass count in the active bidding round.
  int get passCount => _biddingManager?.passCount ?? 0;

  /// Returns the list of legally playable cards for [seatIndex].
  List<CardModel> getValidCards(int seatIndex) {
    if (_gamePhase != GamePhase.playing || _turnManager == null) return [];
    return _playValidator.getValidCards(
      hand: _hands[seatIndex],
      currentTrick: _turnManager!.currentTrick,
      mode: _roundState.activeMode ?? GameMode.sun,
      trumpSuit: _roundState.trumpSuit,
      doubleStatus: _roundState.doubleStatus,
      isOpenPlay: _roundState.isOpenPlay,
      playerSeat: seatIndex,
    );
  }

  @override
  String? get gameWinner {
    if (!isGameOver) return null;
    return _scoringEngine.gameWinner(
        _teamAScore, _teamBScore, _roundState.doubleStatus);
  }

  @override
  String? get projectWinningTeam {
    if (_roundState.activeMode == null) return null;
    final teamAProjects = _activeDeclaredProjects
        .where((p) => p.playerIndex % 2 == 0)
        .toList();
    final teamBProjects = _activeDeclaredProjects
        .where((p) => p.playerIndex % 2 != 0)
        .toList();
    return _projectDetector.resolveProjectPriority(
      teamAProjects,
      teamBProjects,
      _roundState.activeMode!,
      _roundState.trumpSuit,
      (_dealerIndex + 1) % 4,
    );
  }

  /// UI: winning team's projects for reveal (client spec).
  List<DeclaredProject> get winningTeamBestProjectsForReveal {
    final winner = projectWinningTeam;
    if (winner == null || _roundState.activeMode == null) return [];
    final ours = _activeDeclaredProjects.where((p) {
      final teamA = p.playerIndex % 2 == 0;
      return winner == 'A' ? teamA : !teamA;
    }).toList();
    if (ours.isEmpty) return [];

    final result = <DeclaredProject>[];
    
    final regular = ours.where((p) => p.type != ProjectType.baloot).toList();
    if (regular.isNotEmpty) {
      regular.sort((a, b) {
        final cmp = b.priorityRank.compareTo(a.priorityRank);
        if (cmp != 0) return cmp;
        return b.highestCardStrength.compareTo(a.highestCardStrength);
      });
      // Standard rules: return ALL projects for the winning team!
      result.addAll(regular);
    }
    
    final baloot = ours.where((p) => p.type == ProjectType.baloot).toList();
    if (baloot.isNotEmpty) {
      result.addAll(baloot);
    }
    
    return result;
  }

  @override
  Map<String, dynamic> getGameState() {
    return {
      'gamePhase': _gamePhase.name,
      'playerNames': _playerNames,
      'teamAScore': _teamAScore,
      'teamBScore': _teamBScore,
      'dealerIndex': _dealerIndex,
      'roundState': _roundState.toSnapshot(),
      'hands': _hands.map((h) => h.map((c) => c.displayName).toList()).toList(),
    };
  }

  /// Get detected projects for a player (for UI display).
  List<DetectedProject> getDetectedProjects(int seatIndex) =>
      _detectedProjects[seatIndex] ?? [];

  /// Checks if playing [card] triggers Baloot auto-declaration.
  /// Baloot = K+Q of trump. Declared when the 2nd card of the pair is played.
  void _checkBalootDeclaration(int seatIndex, CardModel card) {
    final trump = _roundState.trumpSuit!;
    if (card.suit != trump) return;
    if (card.rank != Rank.king && card.rank != Rank.queen) return;

    // Only proceed if this player was actually dealt both K+Q of trump
    final hasBalootProject = _detectedProjects[seatIndex]
        ?.any((p) => p.type == ProjectType.baloot) ?? false;
    if (!hasBalootProject) return;

    // Standard §2.3: Baloot CANNOT be declared if BOTH K+Q of trump are
    // inside a declared Mia (100+) project. If only one card is in a
    // Sira or 50, Baloot CAN still be declared.
    final miaTypes = {
      ProjectType.hundred, ProjectType.sixCardRun,
      ProjectType.sevenCardRun, ProjectType.eightCardRun,
    };
    final playerDeclaredMia = _activeDeclaredProjects.where(
      (p) => p.playerIndex == seatIndex && miaTypes.contains(p.type),
    );
    for (final mia in playerDeclaredMia) {
      final miaCards = mia.cards;
      final hasKing = miaCards.any((c) => c.suit == trump && c.rank == Rank.king);
      final hasQueen = miaCards.any((c) => c.suit == trump && c.rank == Rank.queen);
      if (hasKing && hasQueen) {
        // Both K+Q are inside this Mia — Baloot is blocked
        return;
      }
    }

    // Check if the player already played the OTHER card of the K-Q pair
    // (i.e., it's no longer in their hand — we already removed it)
    final otherRank = card.rank == Rank.king ? Rank.queen : Rank.king;
    final otherInHand = _hands[seatIndex].any(
      (c) => c.suit == trump && c.rank == otherRank,
    );

    if (!otherInHand) {
      // The other card is NOT in hand → it was already played → this is the 2nd card
      _balootDeclaredBy.add(seatIndex);
      _activeDeclaredProjects.add(DeclaredProject(
        type: ProjectType.baloot,
        playerIndex: seatIndex,
        cards: [
          CardModel(suit: trump, rank: Rank.king),
          CardModel(suit: trump, rank: Rank.queen),
        ],
      ));
      _roundState = _roundState.copyWith(
        declaredProjects: List.from(_activeDeclaredProjects),
      );
    }
  }

  ViolationType _mapViolationKind(ViolationKind kind) {
    switch (kind) {
      case ViolationKind.suitViolation:
        return ViolationType.suitViolation;
      case ViolationKind.cutViolation:
        return ViolationType.cutViolation;
      case ViolationKind.upTrumpViolation:
        return ViolationType.upTrumpViolation;
      case ViolationKind.closedPlayViolation:
        return ViolationType.closedPlayViolation;
    }
  }
}
