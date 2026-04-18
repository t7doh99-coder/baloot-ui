import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../data/models/card_model.dart';
import '../../../data/models/card_play_model.dart';
import '../../../data/models/round_state_model.dart';
import '../domain/baloot_game_controller.dart';
import '../domain/engines/project_detector.dart';
import '../domain/managers/turn_manager.dart' show TrickResult;
import '../domain/engines/scoring_engine.dart' show RoundScoreResult;
import '../domain/managers/bidding_manager.dart';

// ══════════════════════════════════════════════════════════════════
//  GAME PROVIDER — Presentation-layer ViewModel
//
//  Wraps BalootGameController and exposes all state the UI needs.
//  Responsibilities:
//   • Calls engine methods and notifyListeners() after each change
//   • Runs a 10-second turn timer with auto-bot-play on timeout
//   • Schedules bot actions with realistic random delays (600–1500ms)
//   • Human player = seat 0 (bottom); bots = seats 1, 2, 3
//   • Exposes convenience getters so widgets stay thin
// ══════════════════════════════════════════════════════════════════

/// A speech bubble message shown near a player avatar.
class PlayerBubble {
  final int seatIndex;
  final String text;
  final DateTime shownAt;

  const PlayerBubble({
    required this.seatIndex,
    required this.text,
    required this.shownAt,
  });
}

/// Result data from the last completed round (for Kamelna-style score overlay).
class LastRoundResult {
  // Scoreboard points
  final int teamAPoints;
  final int teamBPoints;

  // Total Abnat (tricks + ground + projects)
  final int teamAAbnat;
  final int teamBAbnat;

  // Breakdown: trick card points only (no ground, no projects)
  final int teamATrickAbnat;
  final int teamBTrickAbnat;

  // Which team won the last trick (+10 ground bonus)
  final String? lastTrickBonusTeam;

  // Project Abnat (only the winning team's projects)
  final int teamAProjectAbnat;
  final int teamBProjectAbnat;

  final bool isKhams;
  final bool isKabout;
  final String? reason; // 'khams', 'kabout', 'kabout_ace', 'normal'
  final String winningTeam;
  final String buyerTeam;
  final GameMode mode;
  final Suit? trumpSuit;
  final DoubleStatus doubleStatus;

  const LastRoundResult({
    required this.teamAPoints,
    required this.teamBPoints,
    required this.teamAAbnat,
    required this.teamBAbnat,
    this.teamATrickAbnat = 0,
    this.teamBTrickAbnat = 0,
    this.lastTrickBonusTeam,
    this.teamAProjectAbnat = 0,
    this.teamBProjectAbnat = 0,
    required this.isKhams,
    required this.isKabout,
    this.reason,
    this.winningTeam = 'A',
    this.buyerTeam = 'A',
    required this.mode,
    this.trumpSuit,
    this.doubleStatus = DoubleStatus.none,
  });
}

class GameProvider extends ChangeNotifier {
  // ── Engine ──
  final BalootGameController _engine;
  final Random _rng;

  // ── Player names (seat 0 = human) — always initialised, safe before startGame() ──
  static const List<String> _playerNames = ['You', 'Player 2', 'Partner', 'Player 4'];

  // ── Turn timer ──
  Timer? _turnTimer;
  int _timerSeconds = 10;
  static const _turnDuration = 10;

  // ── Bot delay timer ──
  Timer? _botTimer;
  DateTime? _botTurnStartedAt;  // tracks when bot turn began for ring animation
  int _botTurnMaxMs = 1200;     // mirrors the random bot delay used in _scheduleNextAction

  // ── Human turn start (for smooth sub-second timer ring) ──
  DateTime? _humanTurnStartedAt;

  // ── Bubble display ──
  final Map<int, PlayerBubble> _bubbles = {};
  final Map<int, Timer> _bubbleTimers = {};

  // ── Last round result (for score overlay UI) ──
  LastRoundResult? _lastRoundResult;

  // ── Last trick mini (top-right Jawaker-style); persists across rounds ──
  List<CardModel>? _lastTrickMiniBySeat;

  // ── Phase tracking for transition detection ──
  GamePhase _prevPhase = GamePhase.notStarted;

  // ── Currently selected card in hand (seat 0) ──
  CardModel? _selectedCard;

  /// Designer throw: hand index when human (seat 0) plays a card.
  int _lastHumanThrowCardIndex = 0;
  int _lastHumanThrowHandCount = 8;

  GameProvider({Random? random})
      : _engine = BalootGameController(random: random ?? Random()),
        _rng = random ?? Random();

  // ══════════════════════════════════════════════════════════════════
  //  PUBLIC STATE GETTERS
  // ══════════════════════════════════════════════════════════════════

  GamePhase get phase => _engine.gamePhase;

  /// Safe accessor — returns a dummy empty RoundStateModel before game starts.
  RoundStateModel get roundState =>
      phase == GamePhase.notStarted ? RoundStateModel.empty() : _engine.roundState;

  ({int teamA, int teamB}) get gameScore =>
      phase == GamePhase.notStarted ? (teamA: 0, teamB: 0) : _engine.gameScore;

  bool get isGameOver => _engine.isGameOver;
  String? get gameWinner => _engine.gameWinner;

  /// The player's own hand (seat 0).
  List<CardModel> get playerHand =>
      phase == GamePhase.notStarted ? [] : _engine.getHand(0);

  /// Get any player's hand size (for opponent card-count display).
  int handSize(int seat) =>
      phase == GamePhase.notStarted ? 0 : _engine.getHand(seat).length;

  /// Current player whose turn it is.
  int get currentPlayerIndex => roundState.currentPlayerIndex;

  /// Whether it's the human player's turn.
  bool get isHumanTurn => currentPlayerIndex == 0;

  /// Timer countdown value (0–10), ticking only while the periodic timer runs.
  int get timerSeconds => _timerSeconds;

  /// Use for the burn-ring UI: only meaningful on the human's turn (seat 0).
  /// Opponents should not read raw [timerSeconds] — it can be stale after a bot turn.
  int? get turnTimerSeconds =>
      currentPlayerIndex == 0 ? _timerSeconds : null;

  /// 0.0 → 1.0 progress for the active seat's burn ring (works for all seats).
  /// 1.0 = full ring (just started), 0.0 = ring empty (time up).
  ///
  /// ALL seats use the same _turnDuration (10s) as the visual window so the
  /// ring always depletes at an identical speed. For bots the ring simply
  /// stops (seat becomes inactive) when the bot plays — before the ring
  /// empties. This exactly matches Jawaker's behaviour.
  double get activeSeatTimerProgress {
    final seat    = currentPlayerIndex;
    final started = seat == 0 ? _humanTurnStartedAt : _botTurnStartedAt;
    if (started == null) return 1.0;
    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    // Both human and bot use the same 10-second visual window
    return (1.0 - elapsedMs / (_turnDuration * 1000)).clamp(0.0, 1.0);
  }


  /// Game mode label for UI ("Sun" / "Hakam" / "—").
  String get gameModeLabel {
    final mode = roundState.activeMode;
    if (mode == null) return '—';
    return mode == GameMode.sun ? 'Sun' : 'Hakam';
  }

  /// Trump suit (null for Sun mode or before bidding resolves).
  Suit? get trumpSuit => roundState.trumpSuit;

  /// The buyer card shown during bidding.
  CardModel? get buyerCard => roundState.buyerCard;

  /// The cards currently played in the active trick.
  List<CardPlayModel> get currentTrick => roundState.currentTrick;

  /// Current trick number (1–8).
  int get trickNumber => roundState.trickNumber;

  /// Whether the double window is open.
  bool get isDoubleWindowOpen => roundState.isDoubleWindowOpen;

  /// Current double status.
  DoubleStatus get doubleStatus => roundState.doubleStatus;

  /// Whether it's open play (can lead trump freely).
  bool get isOpenPlay => roundState.isOpenPlay;

  /// Bidding phase (round1 / round2 / completed / cancelled).
  BiddingPhase get biddingPhase => roundState.biddingPhase;

  /// Whether someone has already bid Hakam in Round 1 (Sawa available).
  bool get hasActiveHakamBid =>
      phase == GamePhase.notStarted ? false : _engine.hasActiveHakamBid;

  /// Which seat is the dealer.
  int get dealerIndex => roundState.dealerIndex;

  /// Which seat is the buyer.
  int? get buyerIndex => roundState.buyerIndex;

  /// Whether the human player is on the defending team this round.
  bool get isHumanDefender {
    final buyer = roundState.buyerIndex;
    if (buyer == null) return false;
    return (buyer % 2) != 0; // seat 0 is team A, buyer on team B = human defends
  }

  /// Speech bubbles keyed by seat index.
  Map<int, PlayerBubble> get bubbles => Map.unmodifiable(_bubbles);

  /// Result of the last completed round.
  LastRoundResult? get lastRoundResult => _lastRoundResult;

  /// Last completed trick (4 cards by seat) for the top-right mini panel.
  /// Persists after a round ends until a new trick is played in the next round.
  /// Null before the first trick of the session → show red card backs.
  List<CardModel>? get lastTrickMiniBySeat => _lastTrickMiniBySeat;

  /// Rich scoring breakdown from the engine (Khams, Kabout, etc.).
  RoundScoreResult? get lastRoundScoreResult {
    if (phase == GamePhase.notStarted) return null;
    return _engine.lastRoundScoreResult;
  }

  /// Human (seat 0) is on team A — "Us" in the top bar.
  bool get isHumanTeamA => true;

  /// Whether team A (human) won the match — handles Gahwa when [gameWinner] is null.
  bool get didHumanWinGame {
    final w = gameWinner;
    if (w != null) return w == 'A';
    final s = gameScore;
    if (s.teamA >= 152 && s.teamB < 152) return true;
    if (s.teamB >= 152 && s.teamA < 152) return false;
    return s.teamA > s.teamB;
  }

  /// The currently selected card in the human's hand.
  CardModel? get selectedCard => _selectedCard;

  /// Detected projects for the human player (seat 0).
  List<DetectedProject> get playerProjects =>
      phase == GamePhase.notStarted ? [] : _engine.getDetectedProjects(0);

  /// Projects already declared by the human (seat 0) this round.
  List<DeclaredProject> get humanDeclaredProjects =>
      roundState.declaredProjects
          .where((p) => p.playerIndex == 0 && p.type != ProjectType.baloot)
          .toList();

  /// All declared projects in the current round (for reveal on trick 2).
  List<DeclaredProject> get allDeclaredProjects => roundState.declaredProjects;

  /// Legally playable cards for the human player (seat 0).
  List<CardModel> get validCards => _engine.getValidCards(0);

  /// Last completed trick (same as engine history tail).
  TrickResult? get lastTrickResult =>
      phase == GamePhase.notStarted ? null : _engine.lastTrickResult;

  /// Tricks completed this round (for designer collect / overlay timing).
  int get completedTricksCount => _engine.completedTricksCount;

  /// Full trick history for won-pile counts / angles in the designer trick zone.
  List<TrickResult> get trickHistoryThisRound => _engine.trickHistoryThisRound;

  /// Fan index / hand size for designer bottom throw (seat 0).
  int get lastHumanThrowCardIndex => _lastHumanThrowCardIndex;
  int get lastHumanThrowHandCount => _lastHumanThrowHandCount;

  /// Player names.
  String playerName(int seat) => _playerNames[seat % _playerNames.length];

  // ══════════════════════════════════════════════════════════════════
  //  GAME LIFECYCLE
  // ══════════════════════════════════════════════════════════════════

  /// Start a new game. Call this once after creating the provider.
  void startGame() {
    _lastTrickMiniBySeat = null;
    _engine.startNewGame(_playerNames);
    _prevPhase = _engine.gamePhase;
    _lastRoundResult = null;
    _selectedCard = null;
    notifyListeners();
    _scheduleNextAction();
  }

  /// Restart game after game over.
  void restartGame() {
    _cancelTimers();
    _bubbles.clear();
    startGame();
  }

  // ══════════════════════════════════════════════════════════════════
  //  HUMAN ACTIONS — called by UI widgets
  // ══════════════════════════════════════════════════════════════════

  /// Human places a bid (seat 0 only).
  void humanBid(BidAction action, {Suit? secondHakamSuit}) {
    if (!isHumanTurn || phase != GamePhase.bidding) return;
    _cancelTimers();
    try {
      _engine.placeBid(0, action, secondHakamSuit: secondHakamSuit);
      _showBubble(0, _bidActionLabel(action, secondHakamSuit));
      HapticFeedback.lightImpact();
      _afterEngineAction();
    } catch (e) {
      debugPrint('[GameProvider] humanBid error: $e');
    }
  }

  /// Human calls double (seat 0 only, defending team).
  void humanDouble(DoubleStatus level, {bool isOpenPlay = true}) {
    if (phase != GamePhase.doubleWindow) return;
    _cancelTimers();
    try {
      _engine.callDouble(0, level, isOpenPlay: isOpenPlay);
      _showBubble(0, _doubleLabel(level));
      HapticFeedback.heavyImpact();
      _afterEngineAction();
    } catch (e) {
      debugPrint('[GameProvider] humanDouble error: $e');
    }
  }

  /// Human skips the double window.
  void humanSkipDouble() {
    if (phase != GamePhase.doubleWindow) return;
    _cancelTimers();
    try {
      _engine.skipDoubleWindow();
      _afterEngineAction();
    } catch (e) {
      debugPrint('[GameProvider] humanSkipDouble error: $e');
    }
  }

  /// Tap a card in the human's hand to select/deselect it.
  void selectCard(CardModel card) {
    if (!isHumanTurn || phase != GamePhase.playing) return;
    if (_selectedCard == card) {
      _selectedCard = null;
    } else {
      _selectedCard = card;
      HapticFeedback.selectionClick();
    }
    notifyListeners();
  }

  /// Play the currently selected card.
  void playSelectedCard() {
    if (_selectedCard == null) return;
    humanPlayCard(_selectedCard!);
  }

  /// Human plays a card directly (seat 0 only).
  void humanPlayCard(CardModel card) {
    if (!isHumanTurn || phase != GamePhase.playing) return;
    final hand = playerHand;
    if (hand.isNotEmpty) {
      final idx = hand.indexOf(card);
      _lastHumanThrowHandCount = hand.length;
      _lastHumanThrowCardIndex = idx >= 0 ? idx : hand.length ~/ 2;
    }
    _cancelTimers();
    try {
      _engine.playCard(0, card);
      _selectedCard = null;
      HapticFeedback.mediumImpact();
      _afterEngineAction();
    } catch (e) {
      debugPrint('[GameProvider] humanPlayCard error: $e');
    }
  }

  /// Human declares a project (seat 0, trick 1 only).
  void humanDeclareProject(int projectIndex) {
    if (phase != GamePhase.playing || trickNumber > 1) return;
    try {
      _engine.declareProject(0, projectIndex);
      notifyListeners();
    } catch (e) {
      debugPrint('[GameProvider] humanDeclareProject error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  INTERNAL: schedule bot actions and timer
  // ══════════════════════════════════════════════════════════════════

  /// Close the round scoreboard early (same as waiting for the auto timer).
  void dismissRoundScoreOverlay() {
    _botTimer?.cancel();
    _botTimer = null;
    if (_lastRoundResult == null) return;
    _lastRoundResult = null;
    if (!_engine.isGameOver && _engine.gamePhase == GamePhase.dealing) {
      _engine.startNewRound();
      _prevPhase = _engine.gamePhase;
    }
    notifyListeners();
    _scheduleNextAction();
  }

  void _afterEngineAction() {
    _syncLastTrickMini();

    final newPhase = _engine.gamePhase;

    // The engine's _scoreRound() transitions: scoring (transient) → dealing or gameOver.
    // By the time we read it the phase is already 'dealing' or 'gameOver', not 'scoring'.
    // Detect "round just completed" by watching playing → dealing|gameOver.
    final roundJustScored = _prevPhase == GamePhase.playing &&
        (newPhase == GamePhase.dealing || newPhase == GamePhase.gameOver);

    if (roundJustScored) {
      _captureLastRoundResult();
      HapticFeedback.heavyImpact();
    } else {
      _lastRoundResult = null; // clear stale result from previous round
    }

    _prevPhase = newPhase;
    notifyListeners();
    _scheduleNextAction();
  }

  void _scheduleNextAction() {
    _cancelTimers();

    if (_engine.isGameOver) return;

    final p = _engine.gamePhase;

    // 'dealing' is the phase the engine sits in between rounds.
    // If _lastRoundResult is set, we just finished a round → show overlay
    // for 3.5 s then start the next round.
    // If _lastRoundResult is null, this is the very first deal → advance
    // quickly after a short animation pause.
    if (p == GamePhase.dealing) {
      final delay = _lastRoundResult != null
          ? const Duration(milliseconds: 3500) // score overlay display time
          : const Duration(milliseconds: 900);  // initial deal animation
      _botTimer = Timer(delay, () {
        _lastRoundResult = null;
        _engine.startNewRound();
        _prevPhase = _engine.gamePhase;
        notifyListeners();
        _scheduleNextAction();
      });
      return;
    }

    // The engine no longer stays in 'scoring' — handled above.
    // Keep this guard for safety:
    if (p == GamePhase.scoring) {
      _botTimer = Timer(const Duration(milliseconds: 3500), () {
        _lastRoundResult = null;
        _engine.startNewRound();
        _prevPhase = _engine.gamePhase;
        notifyListeners();
        _scheduleNextAction();
      });
      return;
    }

    if (p == GamePhase.gameOver) return;

    final currentSeat = roundState.currentPlayerIndex;

    if (currentSeat == 0) {
      // Human's turn — start timer
      _startTurnTimer();
    } else {
      // Bot's turn — schedule with realistic delay
      final delay = 600 + _rng.nextInt(900); // 600–1500ms
      _botTurnStartedAt = DateTime.now();
      _botTurnMaxMs = delay;
      _botTimer = Timer(Duration(milliseconds: delay), () {
        _executeBotTurn(currentSeat);
      });
    }
  }

  void _executeBotTurn(int seat) {
    if (_engine.isGameOver) return;
    final current = roundState.currentPlayerIndex;
    if (current != seat) return;

    final phaseBefore = _engine.gamePhase;

    try {
      _engine.botPlay(seat);

      // Show speech bubble for bot bid actions
      if (phaseBefore == GamePhase.bidding) {
        _inferBotBidBubble(seat);
      } else if (phaseBefore == GamePhase.doubleWindow) {
        _inferBotDoubleBubble(seat);
      }

      _afterEngineAction();
    } catch (e) {
      debugPrint('[GameProvider] botPlay error (seat $seat): $e');
      _afterEngineAction();
    }
  }

  /// Infer what the bot bid and show a speech bubble.
  void _inferBotBidBubble(int seat) {
    final rs = _engine.roundState;
    final bp = rs.biddingPhase;

    if (bp == BiddingPhase.completed) {
      // Bidding just ended — the bot made the winning bid
      final mode = rs.activeMode;
      if (rs.isAshkal) {
        _showBubble(seat, 'Ashkal');
      } else if (mode == GameMode.sun) {
        _showBubble(seat, 'Sun');
      } else {
        _showBubble(seat, 'Hakam ✓');
      }
    } else if (bp == BiddingPhase.hakamConfirmation) {
      // Third pass just entered confirmation; this seat was the passer
      _showBubble(seat, 'Pass');
    } else {
      // Bidding continues — bot either passed or bid Hakam in R1
      _showBubble(seat, 'Pass');
    }
  }

  /// Infer what the bot did in the double window.
  void _inferBotDoubleBubble(int seat) {
    final ds = _engine.roundState.doubleStatus;
    if (ds != DoubleStatus.none) {
      _showBubble(seat, _doubleLabel(ds));
    } else {
      _showBubble(seat, 'Pass');
    }
  }

  void _startTurnTimer() {
    _timerSeconds = _turnDuration;
    _humanTurnStartedAt = DateTime.now(); // start ms-based smooth tracking
    notifyListeners();

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _timerSeconds--;
      notifyListeners();

      if (_timerSeconds <= 0) {
        t.cancel();
        _humanTurnStartedAt = null;
        _onHumanTimeout();
      }
    });
  }

  void _onHumanTimeout() {
    // Bot takes over for the human player this turn
    debugPrint('[GameProvider] Human timeout — bot taking over seat 0');
    try {
      _engine.botPlay(0);
      _afterEngineAction();
    } catch (e) {
      debugPrint('[GameProvider] timeout bot error: $e');
    }
  }

  void _cancelTimers() {
    _turnTimer?.cancel();
    _turnTimer = null;
    _botTimer?.cancel();
    _botTimer = null;
  }

  // ══════════════════════════════════════════════════════════════════
  //  SPEECH BUBBLES
  // ══════════════════════════════════════════════════════════════════

  void _showBubble(int seat, String text) {
    _bubbleTimers[seat]?.cancel();
    _bubbles[seat] = PlayerBubble(
      seatIndex: seat,
      text: text,
      shownAt: DateTime.now(),
    );
    notifyListeners();

    _bubbleTimers[seat] = Timer(const Duration(milliseconds: 2200), () {
      _bubbles.remove(seat);
      _bubbleTimers.remove(seat);
      notifyListeners();
    });
  }

  void _syncLastTrickMini() {
    final fromEngine = _engine.lastTrickCardsBySeat;
    if (fromEngine != null) {
      _lastTrickMiniBySeat = fromEngine;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  SCORE CAPTURE
  // ══════════════════════════════════════════════════════════════════

  void _captureLastRoundResult() {
    final rs = _engine.roundState;
    final d = _engine.lastRoundScoreResult;
    if (d == null) return;

    _lastRoundResult = LastRoundResult(
      teamAPoints: d.teamAPoints,
      teamBPoints: d.teamBPoints,
      teamAAbnat: d.teamARawAbnat,
      teamBAbnat: d.teamBRawAbnat,
      teamATrickAbnat: d.teamATrickAbnat,
      teamBTrickAbnat: d.teamBTrickAbnat,
      lastTrickBonusTeam: d.lastTrickBonusTeam,
      teamAProjectAbnat: d.teamAProjectAbnat,
      teamBProjectAbnat: d.teamBProjectAbnat,
      isKhams: d.isKhams,
      isKabout: d.isKabout,
      reason: d.reason,
      winningTeam: d.winningTeam,
      buyerTeam: d.buyerTeam,
      mode: d.mode,
      trumpSuit: rs.trumpSuit,
      doubleStatus: d.doubleStatus,
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════════

  String _bidActionLabel(BidAction action, Suit? secondHakamSuit) {
    switch (action) {
      case BidAction.hakam:        return 'Hakam';
      case BidAction.sun:          return 'Sun';
      case BidAction.secondHakam:  return 'Hakam ${_suitSymbol(secondHakamSuit)}';
      case BidAction.ashkal:       return 'Ashkal';
      case BidAction.pass:         return 'Pass';
      case BidAction.sawa:         return 'Sawa';
      case BidAction.confirmHakam: return 'Hakam ✓';
    }
  }

  String _doubleLabel(DoubleStatus level) {
    switch (level) {
      case DoubleStatus.none:     return 'Pass';
      case DoubleStatus.doubled:  return 'Double';
      case DoubleStatus.tripled:  return 'Triple';
      case DoubleStatus.four:     return 'Four';
      case DoubleStatus.gahwa:    return 'Gahwa';
    }
  }

  String _suitSymbol(Suit? suit) {
    switch (suit) {
      case Suit.hearts:   return '♥';
      case Suit.diamonds: return '♦';
      case Suit.spades:   return '♠';
      case Suit.clubs:    return '♣';
      case null:          return '';
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  CLEANUP
  // ══════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _cancelTimers();
    for (final t in _bubbleTimers.values) {
      t.cancel();
    }
    super.dispose();
  }
}
