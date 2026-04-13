import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../data/models/card_model.dart';
import '../../../data/models/card_play_model.dart';
import '../../../data/models/round_state_model.dart';
import '../domain/baloot_game_controller.dart';
import '../domain/engines/project_detector.dart';
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

/// Result data from the last completed round (for score overlay).
class LastRoundResult {
  final int teamAPoints;
  final int teamBPoints;
  final int teamAAbnat;
  final int teamBAbnat;
  final bool isKhams;
  final bool isKabout;
  final GameMode mode;
  final Suit? trumpSuit;

  const LastRoundResult({
    required this.teamAPoints,
    required this.teamBPoints,
    required this.teamAAbnat,
    required this.teamBAbnat,
    required this.isKhams,
    required this.isKabout,
    required this.mode,
    this.trumpSuit,
  });
}

class GameProvider extends ChangeNotifier {
  // ── Engine ──
  final BalootGameController _engine;
  final Random _rng;

  // ── Player names (seat 0 = human) ──
  static const _playerNames = ['أنت', 'لاعب ٢', 'شريك', 'لاعب ٤'];

  // ── Turn timer ──
  Timer? _turnTimer;
  int _timerSeconds = 10;
  static const _turnDuration = 10;

  // ── Bot delay timer ──
  Timer? _botTimer;

  // ── Bubble display ──
  final Map<int, PlayerBubble> _bubbles = {};
  final Map<int, Timer> _bubbleTimers = {};

  // ── Last round result (for score overlay UI) ──
  LastRoundResult? _lastRoundResult;

  // ── Phase tracking for transition detection ──
  GamePhase _prevPhase = GamePhase.notStarted;

  // ── Currently selected card in hand (seat 0) ──
  CardModel? _selectedCard;

  GameProvider({Random? random})
      : _engine = BalootGameController(random: random ?? Random()),
        _rng = random ?? Random();

  // ══════════════════════════════════════════════════════════════════
  //  PUBLIC STATE GETTERS
  // ══════════════════════════════════════════════════════════════════

  GamePhase get phase => _engine.gamePhase;
  RoundStateModel get roundState => _engine.roundState;
  ({int teamA, int teamB}) get gameScore => _engine.gameScore;
  bool get isGameOver => _engine.isGameOver;
  String? get gameWinner => _engine.gameWinner;

  /// The player's own hand (seat 0).
  List<CardModel> get playerHand => _engine.getHand(0);

  /// Get any player's hand size (for opponent card-count display).
  int handSize(int seat) => _engine.getHand(seat).length;

  /// Current player whose turn it is.
  int get currentPlayerIndex => roundState.currentPlayerIndex;

  /// Whether it's the human player's turn.
  bool get isHumanTurn => currentPlayerIndex == 0;

  /// Timer countdown value (0–10).
  int get timerSeconds => _timerSeconds;

  /// Game mode label for bottom bar ("صن" / "حكم" / "—").
  String get gameModeLabel {
    final mode = roundState.activeMode;
    if (mode == null) return '—';
    return mode == GameMode.sun ? 'صن' : 'حكم';
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

  /// The currently selected card in the human's hand.
  CardModel? get selectedCard => _selectedCard;

  /// Detected projects for the human player (seat 0).
  List<DetectedProject> get playerProjects => _engine.getDetectedProjects(0);

  /// Player names.
  String playerName(int seat) => _playerNames[seat];

  // ══════════════════════════════════════════════════════════════════
  //  GAME LIFECYCLE
  // ══════════════════════════════════════════════════════════════════

  /// Start a new game. Call this once after creating the provider.
  void startGame() {
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
    _cancelTimers();
    try {
      _engine.playCard(0, card);
      _selectedCard = null;
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

  void _afterEngineAction() {
    _lastRoundResult = null; // clear stale result
    final newPhase = _engine.gamePhase;

    // Detect round completion → capture scoring result
    if (_prevPhase == GamePhase.playing && newPhase == GamePhase.scoring) {
      _captureLastRoundResult();
    }

    _prevPhase = newPhase;
    notifyListeners();
    _scheduleNextAction();
  }

  void _scheduleNextAction() {
    _cancelTimers();

    if (_engine.isGameOver) return;

    final p = _engine.gamePhase;

    // Dealing phase auto-progresses (no user input needed)
    if (p == GamePhase.dealing) {
      _botTimer = Timer(const Duration(milliseconds: 800), () {
        // Engine already starts new round from dealing phase internally
        // Just notify so UI can show the deal animation
        notifyListeners();
      });
      return;
    }

    // Scoring phase: show result briefly then start next round
    if (p == GamePhase.scoring) {
      notifyListeners();
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
      _botTimer = Timer(Duration(milliseconds: delay), () {
        _executeBotTurn(currentSeat);
      });
    }
  }

  void _executeBotTurn(int seat) {
    if (_engine.isGameOver) return;
    // Confirm it's still this bot's turn
    final current = roundState.currentPlayerIndex;
    if (current != seat) return;

    try {
      _engine.botPlay(seat);

      // Show speech bubble for bot bid/double actions
      final p = _engine.gamePhase;
      if (p == GamePhase.bidding || p == GamePhase.doubleWindow) {
        // Bubble already handled; just notify
      }

      _afterEngineAction();
    } catch (e) {
      debugPrint('[GameProvider] botPlay error (seat $seat): $e');
      // If bot errors, still advance to avoid stalling
      _afterEngineAction();
    }
  }

  void _startTurnTimer() {
    _timerSeconds = _turnDuration;
    notifyListeners();

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _timerSeconds--;
      notifyListeners();

      if (_timerSeconds <= 0) {
        t.cancel();
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

  // ══════════════════════════════════════════════════════════════════
  //  SCORE CAPTURE
  // ══════════════════════════════════════════════════════════════════

  void _captureLastRoundResult() {
    final rs = _engine.roundState;
    final score = _engine.gameScore;

    // Extract abnat from round state
    _lastRoundResult = LastRoundResult(
      teamAPoints: score.teamA,
      teamBPoints: score.teamB,
      teamAAbnat: rs.teamAAbnat,
      teamBAbnat: rs.teamBAbnat,
      isKhams: false, // ScoringEngine determines this — simplified for now
      isKabout: false,
      mode: rs.activeMode ?? GameMode.hakam,
      trumpSuit: rs.trumpSuit,
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════════

  String _bidActionLabel(BidAction action, Suit? secondHakamSuit) {
    switch (action) {
      case BidAction.hakam:   return 'حكم';
      case BidAction.sun:     return 'صن';
      case BidAction.secondHakam: return 'حكم ${_suitAr(secondHakamSuit)}';
      case BidAction.ashkal:  return 'أشكل';
      case BidAction.pass:    return 'بس';
      case BidAction.sawa:    return 'سوى';
    }
  }

  String _doubleLabel(DoubleStatus level) {
    switch (level) {
      case DoubleStatus.none:     return 'بس';
      case DoubleStatus.doubled:  return 'دبل';
      case DoubleStatus.tripled:  return 'تريبل';
      case DoubleStatus.four:     return 'فور';
      case DoubleStatus.gahwa:    return 'قهوة';
    }
  }

  String _suitAr(Suit? suit) {
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
