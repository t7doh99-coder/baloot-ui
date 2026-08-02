import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/errors/game_exceptions.dart' show PlayViolationException;
import '../../../core/services/game_audio_service.dart';
import '../../../core/services/player_stats_service.dart';
import '../../../core/services/points_calculator.dart';
import '../../../core/services/rank_calculator.dart';
import '../../../data/models/bot_difficulty.dart';
import '../../../data/models/bot_personality.dart';
import '../../../data/models/card_model.dart';
import '../../../data/models/card_play_model.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/player_stats.dart';
import '../../../data/models/rank_tier.dart';
import '../../../data/models/round_state_model.dart';
import '../domain/baloot_game_controller.dart' show GamePhase, BalootGameController;
import '../domain/engines/project_detector.dart';
import '../domain/managers/turn_manager.dart' show TrickResult;
import '../domain/engines/scoring_engine.dart' show RoundScoreResult;
import '../domain/managers/bidding_manager.dart';
import '../../../core/errors/game_exceptions.dart' show PlayViolationException;
import '../../../core/services/game_audio_service.dart';

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

  /// Which team declared Baloot (K+Q of trump) this round — null if none.
  final String? balootTeam;

  final bool isKhams;
  final bool isKabout;
  final String? reason; // 'khams', 'kabout', 'kabout_ace', 'normal'
  final String winningTeam;
  final String buyerTeam;
  final GameMode mode;
  final Suit? trumpSuit;
  final DoubleStatus doubleStatus;

  /// In-play master-card Sawa ended the round (Standard); null = normal play-out.
  final int? playSawaClaimSeat;

  final List<DeclaredProject> teamAProjectsList;
  final List<DeclaredProject> teamBProjectsList;

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
    this.balootTeam,
    required this.isKhams,
    required this.isKabout,
    this.reason,
    this.winningTeam = 'A',
    this.buyerTeam = 'A',
    required this.mode,
    this.trumpSuit,
    this.doubleStatus = DoubleStatus.none,
    this.playSawaClaimSeat,
    this.teamAProjectsList = const [],
    this.teamBProjectsList = const [],
  });
}

class GameProvider extends ChangeNotifier {
  // ── Engine ──
  BalootGameController _engine;
  final Random _rng;

  // ── Audio Service ──
  final GameAudioService _audioService = GameAudioService();
  GameAudioService get audioService => _audioService;

  void setLanguage(String langCode) {
    if (_audioService.langCode == langCode) return;
    _audioService.setLanguage(langCode);
    // Never notify during build — that races on low-end devices and can
    // abort the rest of [startGame] / timer scheduling.
    final phase = WidgetsBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_audioService.langCode == langCode) notifyListeners();
      });
    }
  }

  // ── Difficulty ──
  BotDifficulty _lastDifficulty = BotDifficulty.medium;

  // ── Player names (seat 0 = human) — always initialised, safe before startGame() ──
  static const List<String> _playerNames = ['You', 'Jim', 'Michael', 'Dwight'];

  // ── Turn timer ──
  Timer? _turnTimer;
  int _timerSeconds = 10;
  static const _turnDuration = 10;

  // ── Bot delay timer ──
  Timer? _botTimer;
  DateTime? _botTurnStartedAt;  // tracks when bot turn began for ring animation
  int _botTurnDurationMs = 0;

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
  int _prevCompletedTricks = 0;
  int _prevDealerIndex = -1;
  BiddingPhase _prevBiddingPhase = BiddingPhase.round1;

  // ── Qaid Violation notification (Standard-style banner) ──
  String? _qaidViolationMessage;
  int? _qaidViolationSeat;

  // ── Qaid Claim result (Standard manual flag button) ──
  String? _qaidClaimResult; // 'correct' or 'false'
  String? _qaidClaimMessage;

  // ── Project Reveal at Trick 2 (Standard-style: per-turn, sequential) ──
  /// Which single seat is currently revealing its project (null = none).
  int? _projectRevealSeat;
  /// Seats that have already revealed during this Trick 2.
  final Set<int> _revealedProjectSeats = {};

  /// Standard-style Sawa: سوا badge + all hands face-up (~5s), then engine ends round.
  Timer? _sawaRevealTimer;
  List<List<CardModel>>? _sawaRevealHands;
  int? _sawaRevealClaimSeat;
  bool _sawaSkipTablePauseBeforeScoreboard = false;



  // ── Currently selected card in hand (seat 0) ──
  CardModel? _selectedCard;

  /// Designer throw: hand index when human (seat 0) plays a card.
  int _lastHumanThrowCardIndex = 0;
  int _lastHumanThrowHandCount = 8;
  
  // ── God Mode (for debugging bots) ──
  bool _isGodModeEnabled = false;

  GameProvider({Random? random})
      : _engine = BalootGameController(random: random ?? Random()),
        _rng = random ?? Random() {
    _initStats();
  }

  // ── Player Stats ──
  PlayerStats _playerStats = PlayerStats();
  MatchOutcome? _lastMatchOutcome;

  Future<void> _initStats() async {
    _playerStats = await PlayerStatsService.loadStats();
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════
  //  PUBLIC STATE GETTERS
  // ══════════════════════════════════════════════════════════════════

  PlayerStats get playerStats => _playerStats;
  MatchOutcome? get lastMatchOutcome => _lastMatchOutcome;

  Future<void> updatePlayerName(String newName) async {
    _playerStats = _playerStats.copyWith(playerName: newName);
    notifyListeners();
    await PlayerStatsService.saveStats(_playerStats);
  }

  Future<void> updatePlayerAvatar(String path) async {
    _playerStats = _playerStats.copyWith(customAvatarPath: path);
    notifyListeners();
    await PlayerStatsService.saveStats(_playerStats);
  }

  RankTier get playerRank => RankCalculator.getRankFromStars(
      _playerStats.blueStars, _playerStats.blueStars);

  GamePhase get phase => _engine.gamePhase;
  int _targetScore = 152;
  int get targetScore => _targetScore;

  String get gameLog => _engine.logger.fullLog;

  bool get isGodModeEnabled => _isGodModeEnabled;

  void toggleGodMode() {
    _isGodModeEnabled = !_isGodModeEnabled;
    notifyListeners();
  }

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

  /// Get the hand of any player (for God Mode).
  List<CardModel> getHand(int seat) =>
      phase == GamePhase.notStarted ? [] : _engine.getHand(seat);

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
    // Both human and bot use the same 10-second visual window so all timer rings move at identical speed
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

  /// True when it is human's turn in Trick 1 and they haven't exhausted their 2 declarations.
  bool get canDeclareProjects {
    if (phase != GamePhase.playing || trickNumber != 1) return false;
    
    // Standard Rule: Can declare anytime in Trick 1 as long as you haven't played your card yet.
    final hasPlayedCard = roundState.currentTrick.any((p) => p.playerIndex == 0);
    return !hasPlayedCard;
  }

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

  /// Defending player (seat 0) may call **Sawa** on an active opponent bid (§4.4).
  bool get canHumanBidSawa {
    return _engine.allowedActions(0).contains(BidAction.sawa);
  }

  bool get hasRound2PendingBid =>
      phase == GamePhase.notStarted ? false : _engine.hasRound2PendingBid;

  int? get activeRound1HakamSeat =>
      phase == GamePhase.notStarted ? null : _engine.activeRound1HakamSeat;

  int? get activeRound2PendingBuyerSeat =>
      phase == GamePhase.notStarted ? null : _engine.activeRound2PendingBuyerSeat;

  GameMode? get activeRound2PendingMode =>
      phase == GamePhase.notStarted ? null : _engine.activeRound2PendingMode;

  Suit? get activeRound2PendingTrump =>
      phase == GamePhase.notStarted ? null : _engine.activeRound2PendingTrump;

  /// Which seat is the dealer.
  int get dealerIndex => roundState.dealerIndex;
  
  /// Whether the human player can claim Sawa (100% win probability)
  bool get canSawa => _engine.canSawa(0);

  /// Which seat is the buyer.
  int? get buyerIndex => roundState.buyerIndex;

  /// Whether the human player is on the defending team this round.
  bool get isHumanDefender {
    final buyer = roundState.buyerIndex;
    if (buyer == null) return false;
    return (buyer % 2) != 0; // seat 0 is team A, buyer on team B = human defends
  }

  /// Human (seat 0) won the purchase this round.
  bool get isHumanBuyer {
    final buyer = roundState.buyerIndex;
    if (buyer == null) return false;
    return buyer == 0;
  }

  /// BALOOT_RULES §7.1 — in Sun, defender may Double only if buyer > 100 and defender < 100.
  bool get canDefenderDoubleInSun {
    if (phase != GamePhase.doubleWindow) return false;
    if (roundState.activeMode != GameMode.sun) return true;
    final buyer = roundState.buyerIndex;
    if (buyer == null) return false;
    final buyerIsA = buyer % 2 == 0;
    final buyerPts = buyerIsA ? gameScore.teamA : gameScore.teamB;
    final defPts = buyerIsA ? gameScore.teamB : gameScore.teamA;
    return buyerPts > 100 && defPts < 100;
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
  List<DeclaredProject> _testDeclaredProjects = [];
  List<DeclaredProject> get allDeclaredProjects {
    if (_testDeclaredProjects.isNotEmpty) return _testDeclaredProjects;
    
    final winner = _engine.projectWinningTeam;
    if (winner == null) return roundState.declaredProjects;
    
    return roundState.declaredProjects.where((p) {
      if (p.type == ProjectType.baloot) return true; // Baloot is always valid/shown
      final isTeamA = p.playerIndex % 2 == 0;
      return (winner == 'A' && isTeamA) || (winner == 'B' && !isTeamA);
    }).toList();
  }

  /// Trick-2 **display**: winning team's **single best** project (UI-only; scoring unchanged).
  List<DeclaredProject> get winningTeamBestProjectsForReveal {
    if (_testDeclaredProjects.isNotEmpty) return _testDeclaredProjects;
    if (phase == GamePhase.notStarted) return [];
    return _engine.winningTeamBestProjectsForReveal;
  }

  /// Trigger a fake project reveal for testing the UI animation.
  void triggerTestProjectReveal() {
    _testDeclaredProjects = [
      const DeclaredProject(
        playerIndex: 2, // Partner's seat, to clearly see the avatar animation
        type: ProjectType.sera,
        cards: [
          CardModel(suit: Suit.spades, rank: Rank.seven),
          CardModel(suit: Suit.spades, rank: Rank.eight),
          CardModel(suit: Suit.spades, rank: Rank.nine),
        ],
      )
    ];
    notifyListeners();
    
    // Auto-clear after 4 seconds (approx time projects stay on screen)
    Timer(const Duration(seconds: 4), () {
      _testDeclaredProjects = [];
      notifyListeners();
    });
  }

  /// Legally playable cards for the human player (seat 0).
  List<CardModel> get validCards => _engine.getValidCards(0);

  /// Last completed trick (same as engine history tail).
  TrickResult? get lastTrickResult =>
      phase == GamePhase.notStarted ? null : _engine.lastTrickResult;

  /// Tricks completed this round (for designer collect / overlay timing).
  int get completedTricksCount => _engine.completedTricksCount;

  /// Full trick history for won-pile counts / angles in the designer trick zone.
  List<TrickResult> get trickHistoryThisRound => _engine.trickHistoryThisRound;

  /// Qaid (Violation) notification — null when clear.
  String? get qaidViolationMessage => _qaidViolationMessage;
  int? get qaidViolationSeat => _qaidViolationSeat;

  /// Qaid claim result — null when no claim active.
  String? get qaidClaimResult => _qaidClaimResult;
  String? get qaidClaimMessage => _qaidClaimMessage;

  /// Whether the human player can currently claim Qaid (Standard manual flag).
  bool get canClaimQaid => _engine.canClaimQaid(0);

  /// Clear the Qaid notification (called after UI shows it).
  void clearQaidViolation() {
    _qaidViolationMessage = null;
    _qaidViolationSeat = null;
    notifyListeners();
  }

  /// Clear the Qaid claim result banner.
  void clearQaidClaimResult() {
    _qaidClaimResult = null;
    _qaidClaimMessage = null;
    notifyListeners();
  }

  /// Human claims Qaid (seat 0) — Standard manual violation reporting.
  /// Per BALOOT_RULES.md §14.5:
  /// - If opponent actually violated → opponent gets Kabout penalty
  /// - If false claim → accuser (human) gets Kabout penalty
  void humanClaimQaid() {
    if (phase != GamePhase.playing || !canClaimQaid) return;
    _cancelTimers();

    final violatorSeat = _engine.checkLastPlayViolation(0);

    if (violatorSeat != null) {
      // Correct claim — opponent violated
      _engine.applyQaidPenalty(violatorSeat);
      _qaidClaimResult = 'correct';
      _qaidClaimMessage = null; // Will be set by UI using l10n
      HapticFeedback.heavyImpact();
      _showBubble(0, 'Qaid');
    } else {
      // False claim — human gets penalty
      _engine.applyQaidPenalty(0);
      _qaidClaimResult = 'false';
      _qaidClaimMessage = null;
      HapticFeedback.heavyImpact();
    }

    _afterEngineAction();
  }

  /// Whether to show a project reveal for a specific seat (Standard per-turn).
  bool get showProjectReveal => _projectRevealSeat != null;

  /// The specific seat currently revealing its project (null = none).
  int? get projectRevealSeat => _projectRevealSeat;

  bool get isSawaRevealPlaying => _sawaRevealHands != null;

  int? get sawaRevealClaimSeat => _sawaRevealClaimSeat;

  List<CardModel> sawaRevealCardsForSeat(int seat) {
    if (_sawaRevealHands == null || seat < 0 || seat >= 4) {
      return const <CardModel>[];
    }
    return List.unmodifiable(_sawaRevealHands![seat]);
  }

  void clearLastRoundResult() {
    _lastRoundResult = null;
    notifyListeners();
  }

  void setMockRoundResult() {
    _lastRoundResult = const LastRoundResult(
      teamAPoints: 21,
      teamBPoints: 5,
      teamAAbnat: 106,
      teamBAbnat: 24,
      teamATrickAbnat: 96,
      teamBTrickAbnat: 24,
      lastTrickBonusTeam: 'A',
      teamAProjectAbnat: 0,
      teamBProjectAbnat: 0,
      isKhams: false,
      isKabout: false,
      winningTeam: 'A',
      buyerTeam: 'A',
      mode: GameMode.sun,
      trumpSuit: null,
      doubleStatus: DoubleStatus.none,
      teamAProjectsList: [],
      teamBProjectsList: [],
    );
    notifyListeners();
  }

  void dismissProjectReveal() {
    _projectRevealSeat = null;
    notifyListeners();
  }

  /// Fan index / hand size for designer bottom throw (seat 0).
  int get lastHumanThrowCardIndex => _lastHumanThrowCardIndex;
  int get lastHumanThrowHandCount => _lastHumanThrowHandCount;

  /// Player names.
  String playerName(int seat) {
    if (seat == 0) return _playerStats.playerName;
    if (_audioService.langCode != 'ar') {
      return _playerNames[seat % _playerNames.length]; // 'You', 'Jim', 'Michael', 'Dwight'
    }
    try {
      return _engine.playerNames[seat % 4];
    } catch (_) {
      return _playerNames[seat % _playerNames.length];
    }
  }

  /// Player rank badges (for bot seats).
  String playerRankBadge(int seat) {
    if (seat == 0) return 'Human';
    try {
      return _engine.botIdentityOf(seat).rankBadge;
    } catch (_) {
      return 'Good';
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  GAME LIFECYCLE
  // ══════════════════════════════════════════════════════════════════

  // When true, timers / bot turns are not scheduled. Used while the loading
  // screen finishes the opening deal so bots don't bid before the table opens.
  bool _autoPlaySuspended = false;

  /// True once the opening deal has finished and the table can be shown.
  /// Loading screen waits for this before leaving.
  bool get isMatchReady =>
      phase != GamePhase.notStarted && phase != GamePhase.dealing;

  /// Start a new game. Call this once after creating the provider.
  ///
  /// When [suspendAutoPlay] is true (loading-screen prep), the dealing timer
  /// and bot turns are not started — call [onTableReady] after the table mounts.
  void startGame({
    BotDifficulty difficulty = BotDifficulty.medium,
    bool suspendAutoPlay = false,
  }) {
    // Cancel any leftover timers from a previous session first.
    _cancelTimers();
    _autoPlaySuspended = suspendAutoPlay;

    _lastDifficulty = difficulty;
    _targetScore = 152;
    _lastTrickMiniBySeat = null;

    // Re-initialize engine with selected difficulty
    _engine = BalootGameController(
      random: _rng,
      botDifficulty: difficulty,
    );

    _engine.startNewGame(_playerNames);
    _prevPhase = _engine.gamePhase;
    _prevCompletedTricks = 0;
    _prevDealerIndex = _engine.roundState.dealerIndex;
    _prevBiddingPhase = _engine.roundState.biddingPhase;
    _lastRoundResult = null;
    _selectedCard = null;
    _roundJustEnded = false;
    _roundCancelled = false;
    _isMatchOverOverlayReady = false;
    _clearSawaRevealState();

    // Schedule dealing→bidding BEFORE notifyListeners. On low-end phones a
    // heavy listener rebuild can throw; if we notified first, the dealing
    // timer would never be armed and the match stays on "جاري التوزيع...".
    if (!_autoPlaySuspended) {
      _scheduleNextAction();
    }
    notifyListeners();
  }

  /// Prepare a match while the loading screen is visible: start the engine,
  /// finish the opening deal, but do NOT start bot turns yet.
  ///
  /// Call [onTableReady] from [GameTableScreen] after it mounts.
  Future<void> prepareMatchForTable({
    BotDifficulty difficulty = BotDifficulty.medium,
  }) async {
    startGame(difficulty: difficulty, suspendAutoPlay: true);

    if (_engine.gamePhase == GamePhase.dealing) {
      try {
        _engine.startNewRound();
        _prevPhase = _engine.gamePhase;
        _prevBiddingPhase = _engine.roundState.biddingPhase;
        notifyListeners();
      } catch (e, st) {
        debugPrint('[GameProvider] prepareMatch deal failed: $e\n$st');
      }
    }

    // Yield so the loading animation can paint on slow GPUs.
    await Future<void>.delayed(Duration.zero);

    if (_engine.gamePhase == GamePhase.dealing) {
      try {
        _engine.startNewRound();
        _prevPhase = _engine.gamePhase;
        _prevBiddingPhase = _engine.roundState.biddingPhase;
        notifyListeners();
      } catch (e, st) {
        debugPrint('[GameProvider] prepareMatch deal retry failed: $e\n$st');
      }
    }
  }

  /// Resume bot / human turn loop after [GameTableScreen] is on screen.
  void onTableReady() {
    if (_engine.gamePhase == GamePhase.dealing) {
      _autoPlaySuspended = false;
      ensureDealingAdvances(force: true);
      return;
    }
    if (!_autoPlaySuspended) return;
    _autoPlaySuspended = false;

    if (_engine.gamePhase == GamePhase.bidding) {
      _showBubble(_engine.roundState.dealerIndex, 'Awal');
    }
    _scheduleNextAction();
  }

  /// Safety net for low-end devices: if we are still in [GamePhase.dealing]
  /// with no active bot timer, re-arm advancement. Called from the table
  /// screen after the first frame / as a short watchdog.
  ///
  /// When [force] is true (watchdog), advance immediately even if a timer
  /// appears active — covers cases where the callback was dropped under jank.
  void ensureDealingAdvances({bool force = false}) {
    if (_engine.gamePhase != GamePhase.dealing) return;
    if (!force && _botTimer != null && _botTimer!.isActive) return;
    debugPrint(
      '[GameProvider] dealing watchdog — '
      '${force ? "forcing" : "re-arming"} startNewRound',
    );
    if (force) {
      _cancelTimers();
      _advanceFromDealing();
    } else {
      _scheduleNextAction();
    }
  }

  /// Restart game after game over (keeps same target score).
  void restartGame() {
    _cancelTimers();
    _bubbles.clear();
    startGame(difficulty: _lastDifficulty);
  }

  /// Leave the table (e.g. Exit from round scoreboard). Cancels timers; engine
  /// state is left as-is until the next [startGame].
  void leaveTable() {
    _cancelTimers();
    _audioService.stop();
    _clearSawaRevealState();
    _lastRoundResult = null;
    _roundJustEnded = false;
    _roundCancelled = false;
    _isMatchOverOverlayReady = false;
    _humanTurnStartedAt = null;
    _botTurnStartedAt = null;
    for (final t in _bubbleTimers.values) {
      t.cancel();
    }
    _bubbleTimers.clear();
    _bubbles.clear();
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════
  //  HUMAN ACTIONS — called by UI widgets
  // ══════════════════════════════════════════════════════════════════

  /// Human places a bid (seat 0 only).
  void humanBid(BidAction action, {Suit? secondHakamSuit}) {
    if (!isHumanTurn || phase != GamePhase.bidding) return;
    if (_turnTimer == null) return; // Ignore input during system pauses/animations
    _cancelTimers();
    try {
      final label = _bidActionLabel(action, secondHakamSuit);
      _engine.placeBid(0, action, secondHakamSuit: secondHakamSuit);
      _showBubble(0, label);
      HapticFeedback.lightImpact();
      _afterEngineAction();
    } catch (e) {
      debugPrint('[GameProvider] humanBid error: $e');
    }
  }

  /// Human calls double (seat 0 only, defending team).
  void humanDouble(DoubleStatus level, {bool isOpenPlay = true}) {
    if (phase != GamePhase.doubleWindow) return;
    if (_turnTimer == null) return; // Ignore input during system pauses/animations
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
    if (_turnTimer == null) return; // Ignore input during system pauses/animations
    _cancelTimers();
    try {
      _engine.skipDoubleWindow();
      _showBubble(0, 'Pass');
      _afterEngineAction();
    } catch (e) {
      debugPrint('[GameProvider] humanSkipDouble error: $e');
    }
  }

  void selectCard(CardModel card) {
    if (phase != GamePhase.playing) {
      // Phase changed away from playing (e.g. bidding popup appeared while a
      // card was selected) — clear any stuck selection and bail out.
      if (_selectedCard != null) {
        _selectedCard = null;
        notifyListeners();
      }
      return;
    }
    // Note: intentionally NO _turnTimer guard here — card selection (visual + sound)
    // should always work so the player can pre-select their card on the bot's turn.
    // Always play sound on EVERY tap (both select and deselect).
    // Uses dedicated player that interrupts itself — no stacking on rapid taps.
    _audioService.playCardSelect();
    HapticFeedback.selectionClick();
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

  /// Deselect the currently selected card (if any).
  void clearSelection() {
    if (_selectedCard != null) {
      _selectedCard = null;
      notifyListeners();
    }
  }

  /// Human plays a card directly (seat 0 only).
  void humanPlayCard(CardModel card) {
    if (!isHumanTurn || phase != GamePhase.playing) return;
    if (_turnTimer == null) return; // Ignore input during system pauses/animations
    
    // Clear the selection since an action is being taken
    _selectedCard = null;

    // The moment the human plays a card, they forfeit any un-declared projects.
    // The turn will advance automatically and canDeclareProjects will become false.
    final hand = playerHand;
    if (hand.isNotEmpty) {
      final idx = hand.indexOf(card);
      _lastHumanThrowHandCount = hand.length;
      _lastHumanThrowCardIndex = idx >= 0 ? idx : hand.length ~/ 2;
    }
    _cancelTimers();
    try {
      final trickBefore = trickNumber;
      final balootBefore = roundState.declaredProjects.where((p) => p.type == ProjectType.baloot).length;
      _engine.playCard(0, card);
      _selectedCard = null;
      HapticFeedback.mediumImpact();
      // Announce Baloot if the 2nd K-Q trump card just triggered auto-declaration
      final balootAfter = roundState.declaredProjects.where((p) => p.type == ProjectType.baloot).length;
      if (balootAfter > balootBefore) {
        _showBubble(0, 'Baloot');
      } else if (trickBefore == 1) {
        // Announce user's manually declared projects (if any) when they play their first card
        _announceProjects(0);
      } else if (_engine.isAkka(card)) {
        // Standard "أكة" — auto-detect strongest remaining card of suit
        _showBubble(0, 'Akka');
      }
      _afterEngineAction();
    } on PlayViolationException catch (e) {
      // Qaid (Violation) — show Standard-style banner
      _qaidViolationMessage = e.message;
      _qaidViolationSeat = 0;
      
      // Apply professional Standard penalty (instant round loss + Kabout score)
      _engine.applyQaidPenalty(0);
      
      HapticFeedback.heavyImpact();
      _afterEngineAction(); // Transition to next round/game over
    } catch (e) {
      debugPrint('[GameProvider] humanPlayCard error: $e');
    }
  }



  /// Human declares a project — only allowed during Trick 1 of playing phase.
  void humanDeclareProject(int projectIndex) {
    final ok = canDeclareProjects;
    if (!ok || _turnTimer == null) return;
    try {
      _engine.declareProject(0, projectIndex);
      notifyListeners();
    } catch (e) {
      debugPrint('[GameProvider] humanDeclareProject error: $e');
    }
  }

  void humanUndeclareProject(ProjectType type) {
    final ok = canDeclareProjects;
    if (!ok || _turnTimer == null) return;
    try {
      _engine.undeclareProject(0, type);
      notifyListeners();
    } catch (e) {
      debugPrint('[GameProvider] humanUndeclareProject error: $e');
    }
  }

  /// Generic Sawa claim — badge + all hands revealed [~5s], then round score.
  static const int _sawaRevealDurationMs = 5000;

  void humanClaimSawa() {
    if (phase != GamePhase.playing || !canSawa) return;
    if (_turnTimer == null) return; // Ignore input during system pauses/animations
    _showBubble(0, 'Sawa');
    _startSawaReveal(0);
  }

  void _startSawaReveal(int seat) {
    if (_sawaRevealHands != null) return;
    _cancelTimers();

    _sawaRevealHands = List.generate(
      4,
      (s) => List<CardModel>.from(_engine.getHand(s)),
    );
    _sawaRevealClaimSeat = seat;
    notifyListeners();

    _sawaRevealTimer = Timer(
      const Duration(milliseconds: _sawaRevealDurationMs),
      () => _finalizeSawaReveal(seat),
    );
  }

  void _finalizeSawaReveal(int seat) {
    _sawaRevealTimer?.cancel();
    _sawaRevealTimer = null;

    try {
      if (phase != GamePhase.playing || !_engine.canSawa(seat)) {
        _clearSawaRevealState();
        notifyListeners();
        return;
      }
      _sawaRevealHands = null;
      _sawaRevealClaimSeat = null;

      _sawaSkipTablePauseBeforeScoreboard = true;
      _engine.claimSawa(seat);
      if (seat == 0) HapticFeedback.heavyImpact();
      _afterEngineAction();
    } catch (e) {
      debugPrint('[GameProvider] SawaReveal error: $e');
      _sawaSkipTablePauseBeforeScoreboard = false;
      _clearSawaRevealState();
      notifyListeners();
    }
  }

  void _clearSawaRevealState() {
    _sawaRevealTimer?.cancel();
    _sawaRevealTimer = null;
    _sawaRevealHands = null;
    _sawaRevealClaimSeat = null;
  }

  // ══════════════════════════════════════════════════════════════════
  //  INTERNAL: schedule bot actions and timer
  // ══════════════════════════════════════════════════════════════════

  /// True during the 3s table pause + 6s scoreboard window after trick 8.
  /// Used by UI to hide Dealing spinner and bidding buttons.
  bool _roundJustEnded = false;
  bool get isRoundJustEnded => _roundJustEnded;

  // ── Round Cancelled (all-pass both rounds) overlay ──
  bool _roundCancelled = false;
  String _cancelledNewDealerName = '';
  bool _isMatchOverOverlayReady = false;

  /// Whether a round has just ended and we are transitioning (scoreboard is visible or waiting for it).
  bool get isRoundTransitioning => _roundJustEnded;
  
  bool get showGameOverOverlay => phase == GamePhase.gameOver && _isMatchOverOverlayReady;

  bool get isRoundCancelled => _roundCancelled;
  String get cancelledNewDealerName => _cancelledNewDealerName;

  void _afterEngineAction() {
    _syncLastTrickMini();

    final newPhase = _engine.gamePhase;
    final newDealerIndex = _engine.roundState.dealerIndex;
    final newBiddingPhase = newPhase == GamePhase.bidding ? _engine.roundState.biddingPhase : BiddingPhase.round1;

    // Detect all-pass cancellation: phase stays bidding but dealer rotates
    if (_prevPhase == GamePhase.bidding && newPhase == GamePhase.bidding && newDealerIndex != _prevDealerIndex) {
      _prevDealerIndex = newDealerIndex;
      _prevBiddingPhase = newBiddingPhase;
      _showCancelledOverlay(newDealerIndex);
      return;
    }
    
    // Silently transition to Round 2 (no bubble, matches Kammelna)
    if (_prevPhase == GamePhase.bidding && newPhase == GamePhase.bidding && _prevBiddingPhase == BiddingPhase.round1 && newBiddingPhase == BiddingPhase.round2) {
      HapticFeedback.lightImpact();
    }
    
    _prevDealerIndex = newDealerIndex;
    _prevBiddingPhase = newBiddingPhase;

    if (newPhase == GamePhase.dealing) {

    }

    // Clean transition: When bidding completes and we lock in the mode,
    // immediately clear all lingering bidding dialogue (Pass/Bas/Sann).
    if (_prevPhase == GamePhase.bidding && newPhase == GamePhase.doubleWindow) {
      _clearAllBubbles();
      // Play sound for the distribution of the remaining 4 cards
      _audioService.playEffect('card distribution sound.mp3');
    }

    // Auto-clear any selected card whenever we leave the playing phase.
    // This prevents cards from appearing stuck-elevated when a bidding popup
    // or double window appears after the player had pre-selected a card.
    if (_prevPhase == GamePhase.playing && newPhase != GamePhase.playing) {
      _selectedCard = null;
    }

    // Detect "round just completed" by watching playing → scoring.
    final roundJustScored = _prevPhase == GamePhase.playing &&
        (newPhase == GamePhase.scoring || newPhase == GamePhase.gameOver);

    final newCompletedTricks = completedTricksCount;
    final trickJustCompleted =
        newPhase == GamePhase.playing && newCompletedTricks > _prevCompletedTricks;
    _prevCompletedTricks = newCompletedTricks;

    if (trickJustCompleted) {
      final lastTrick = _engine.lastTrickResult;
      if (lastTrick != null) {
        final winnerTeam = (lastTrick.winnerIndex % 2 == 0) ? 'A' : 'B';
        final abnat = lastTrick.totalAbnat;
        if (abnat >= 15) {
          for (int seat = 1; seat < 4; seat++) {
            final botTeam = (seat % 2 == 0) ? 'A' : 'B';
            if (botTeam != winnerTeam) {
              _checkBotExpressions(seat, event: 'lost_critical_trick', abnatLost: abnat);
            }
          }
        }
      }
    }

    if (roundJustScored) {
      _prevCompletedTricks = 0;
      _roundJustEnded = true;
      // After normal trick 8: 3s table pause then scoreboard. After Sawa reveal we already
      // held ~5s of animation — show scoreboard immediately.
      final quick = _sawaSkipTablePauseBeforeScoreboard;
      _sawaSkipTablePauseBeforeScoreboard = false;
      HapticFeedback.heavyImpact();
      _botTimer = Timer(
        Duration(milliseconds: quick ? 0 : 3000),
        () {
        _captureLastRoundResult(); // shows scoreboard overlay
        notifyListeners();
        // Auto-dismiss scoreboard and start next round after 6 seconds
        _botTimer = Timer(const Duration(milliseconds: 6000), () {
          _roundJustEnded = false;
          _lastRoundResult = null;
          
          if (_engine.isGameOver) {
            _isMatchOverOverlayReady = true;
          } else if (_engine.gamePhase == GamePhase.scoring) {
            _engine.startNewRound();
            _prevPhase = _engine.gamePhase;
            _prevBiddingPhase = _engine.roundState.biddingPhase;
            if (_engine.gamePhase == GamePhase.bidding) {
              _showBubble(_engine.roundState.dealerIndex, 'Awal');
            }
          }
          notifyListeners();
          _scheduleNextAction();
        });
      },
      );
    } else {
      _lastRoundResult = null; // clear stale result from previous round
    }

    _prevPhase = newPhase;
    notifyListeners();

    if (roundJustScored) return;

    if (trickJustCompleted) {
      final isTransitionToTrick2 = _engine.gamePhase == GamePhase.playing && trickNumber == 2;
      final hasProjectsToReveal = winningTeamBestProjectsForReveal.isNotEmpty;
      
      if (isTransitionToTrick2 && hasProjectsToReveal) {
        // Standard-style: clear reveal state, then proceed to Trick 2.
        // Each player's project will be revealed individually in _scheduleNextAction.
        _revealedProjectSeats.clear();
        _projectRevealSeat = null;
        _botTimer = Timer(const Duration(milliseconds: 2000), () {
          _scheduleNextAction();
        });
      } else {
        // Normal trick completion pause (3.35s)
        _botTimer = Timer(const Duration(milliseconds: 3350), () {
          _scheduleNextAction();
        });
      }
    } else {
      _scheduleNextAction();
    }
  }

  /// Called when all 4 players passed both bidding rounds.
  /// Shows a 2-second "Round Cancelled / New Dealer" overlay then resumes.
  void _showCancelledOverlay(int newDealerSeat) {
    _cancelTimers();
    _roundCancelled = true;
    _cancelledNewDealerName = playerName(newDealerSeat);
    _prevPhase = phase;
    notifyListeners();

    _botTimer = Timer(const Duration(milliseconds: 2200), () {
      _roundCancelled = false;
      _cancelledNewDealerName = '';
      if (_engine.gamePhase == GamePhase.bidding) {
        _showBubble(newDealerSeat, 'Awal');
      }
      notifyListeners();
      _scheduleNextAction();
    });
  }

  /// Move engine from dealing → bidding, then continue the turn loop.
  /// Isolated so the dealing timer and the low-end watchdog share one path.
  void _advanceFromDealing() {
    if (_engine.gamePhase != GamePhase.dealing) return;
    try {
      _engine.startNewRound();
      _prevPhase = _engine.gamePhase;
      _prevBiddingPhase = _engine.roundState.biddingPhase;
      if (_engine.gamePhase == GamePhase.bidding) {
        _showBubble(_engine.roundState.dealerIndex, 'Awal');
      }
      notifyListeners();
      _scheduleNextAction();
    } catch (e, st) {
      debugPrint('[GameProvider] startNewRound failed during dealing: $e\n$st');
      // Retry once shortly — common under memory/jank pressure on budget phones.
      _botTimer = Timer(const Duration(milliseconds: 800), () {
        if (_engine.gamePhase != GamePhase.dealing) return;
        try {
          _engine.startNewRound();
          _prevPhase = _engine.gamePhase;
          _prevBiddingPhase = _engine.roundState.biddingPhase;
          notifyListeners();
          _scheduleNextAction();
        } catch (e2, st2) {
          debugPrint('[GameProvider] startNewRound retry failed: $e2\n$st2');
        }
      });
    }
  }

  void _scheduleNextAction() {
    if (_engine.isGameOver) return;
    if (_autoPlaySuspended) return;

    _cancelTimers();

    final p = _engine.gamePhase;

    if (p == GamePhase.dealing) {
      // Very first deal at game start — advance quickly after short animation.
      // Longer delay on first paint helps low-end devices finish the route
      // transition before we mutate engine state + rebuild the table.
      _botTimer = Timer(const Duration(milliseconds: 1200), () {
        _advanceFromDealing();
      });
      return;
    }

    if (p == GamePhase.scoring) {
      // Scoreboard is displayed via roundJustScored logic. We just wait here.
      // The roundJustScored timer will dismiss it and call startNewRound.
      return;
    }

    final currentSeat = roundState.currentPlayerIndex;

    // ── Standard-style: per-turn project reveal during Trick 2 ──
    // Before a player plays their Trick 2 card, reveal their project first.
    if (p == GamePhase.playing && trickNumber == 2) {
      final seatProjects = winningTeamBestProjectsForReveal
          .where((proj) => proj.playerIndex == currentSeat && proj.type != ProjectType.baloot)
          .toList();

      if (seatProjects.isNotEmpty && !_revealedProjectSeats.contains(currentSeat)) {
        // This player has unrevealed projects — show fan visually, but NO audio (already declared in Trick 1)
        _revealedProjectSeats.add(currentSeat);
        _projectRevealSeat = currentSeat;
        // Show the reveal visually. It will be cleared when the turn ends (via _cancelTimers)
        // or after 5 seconds if the turn takes longer.
        Timer(const Duration(milliseconds: 5000), () {
          if (_projectRevealSeat == currentSeat) {
            _projectRevealSeat = null;
            notifyListeners();
          }
        });
        
        // Dispatch the turn immediately so the timer ring runs concurrently.
        _dispatchTurn(currentSeat);
        return;
      }
    }

    _dispatchTurn(currentSeat);
  }

  /// Dispatches the actual turn (human timer or bot delay) for [seat].
  void _dispatchTurn(int seat) {
    if (seat == 0) {
      // Human's turn — start timer
      _startTurnTimer();
    } else {
      // Bot's turn — difficulty-aware realistic delay
      final delay = _calculateBotDelay();
      _botTurnDurationMs = delay;
      _botTurnStartedAt = DateTime.now();
      _botTimer = Timer(Duration(milliseconds: delay), () {
        _executeBotTurn(seat);
      });
    }
  }

  /// Difficulty-scaled bot thinking delay (per baloot_bot_spec).
  ///
  /// Easy:   3000–5000ms  (slow, beginner)
  /// Medium: 1500–3000ms  (+15% "thinking" turns at 4000–6000ms)
  /// Hard:   800–2000ms   (+20% fast snap 500–900ms, +15% fake hesitation 4000–7000ms)
  int _calculateBotDelay() {
    final roll = _rng.nextDouble();
    switch (_lastDifficulty) {
      case BotDifficulty.easy:
        return 3000 + _rng.nextInt(2001);        // 3000–5000ms
      case BotDifficulty.medium:
        if (roll < 0.15) {                        // 15% "thinking" turns
          return 4000 + _rng.nextInt(2001);       // 4000–6000ms
        }
        return 1500 + _rng.nextInt(1501);         // 1500–3000ms
      case BotDifficulty.hard:
        if (roll < 0.20) {                        // 20% fast snap
          return 500 + _rng.nextInt(401);         // 500–900ms
        }
        if (roll < 0.35) {                        // next 15% fake hesitation
          return 4000 + _rng.nextInt(3001);       // 4000–7000ms
        }
        return 800 + _rng.nextInt(1201);          // 800–2000ms
    }
  }

  void _executeBotTurn(int seat) {
    if (_engine.isGameOver) return;
    final current = roundState.currentPlayerIndex;
    if (current != seat) return;

    final phaseBefore = _engine.gamePhase;
    final bpBefore = roundState.biddingPhase;
    final dealerBefore = roundState.dealerIndex;

    try {
      // In-play Sawa (hand reveal / end round): human only — bots never auto-claim.

      final declaredBefore = roundState.declaredProjects.length;
      final balootBefore = roundState.declaredProjects.where((p) => p.type == ProjectType.baloot).length;
      _engine.botPlay(seat);
      final declaredAfter = roundState.declaredProjects.length;
      final balootAfter = roundState.declaredProjects.where((p) => p.type == ProjectType.baloot).length;

      // Show speech bubble for bot actions
      if (phaseBefore == GamePhase.bidding) {
        _inferBotBidBubble(seat, bpBefore);
      } else if (phaseBefore == GamePhase.doubleWindow) {
        _inferBotDoubleBubble(seat);
      } else if (phaseBefore == GamePhase.playing) {
        // Baloot declaration takes priority over regular project announcements
        if (balootAfter > balootBefore) {
          _showBubble(seat, 'Baloot');
        } else if (declaredAfter > declaredBefore) {
          _announceProjects(seat);
        } else {
          // Standard "أكة" — auto-detect strongest remaining card of suit
          // Find the card this bot just played (last card in current trick or last trick)
          final lastCard = _engine.lastPlayedCardBySeat(seat);
          if (lastCard != null && _engine.isAkka(lastCard)) {
            _showBubble(seat, 'Akka');
          } else {
            _checkBotExpressions(seat, event: 'turn');
          }
        }
      }

      // Detect all-pass cancellation: dealer rotated means new deal was triggered
      if (phaseBefore == GamePhase.bidding &&
          phase == GamePhase.bidding &&
          roundState.dealerIndex != dealerBefore) {
        _showCancelledOverlay(roundState.dealerIndex);
        return;
      }

      _afterEngineAction();
    } catch (e) {
      debugPrint('[GameProvider] botPlay error (seat $seat): $e');
      _afterEngineAction();
    }
  }

  /// Infer what the bot bid and show a speech bubble.
  void _inferBotBidBubble(int seat, BiddingPhase bpBefore) {
    final rs = _engine.roundState;

    if (bpBefore == BiddingPhase.qablakIntervention) {
      // The bot decided to either steal Sun or Pass
      if (rs.activeMode == GameMode.sun && _engine.roundState.buyerIndex == seat) {
        _showBubble(seat, 'Qablak'); // Qablak steal
      } else {
        _showBubble(seat, 'Pass');
      }
    } else if (bpBefore == BiddingPhase.hakamConfirmation) {
      // Third pass just entered confirmation; this seat was the passer
      _showBubble(seat, 'Pass');
    } else if (bpBefore == BiddingPhase.round1) {
      // Round 1: check if this bot just bid Hakam or Sun
      if (_engine.activeRound1HakamSeat == seat) {
        _showBubble(seat, 'Hakam');
      } else if (rs.activeMode == GameMode.sun && rs.buyerIndex == seat) {
        _showBubble(seat, 'Sun');
      } else if (rs.isAshkal && rs.buyerIndex == seat) {
        _showBubble(seat, 'Ashkal');
      } else {
        _showBubble(seat, 'Pass');
      }
    } else if (bpBefore == BiddingPhase.round2) {
      // Round 2: check if this bot just placed a pending bid
      if (_engine.activeRound2PendingBuyerSeat == seat) {
        final pendingMode = _engine.activeRound2PendingMode;
        if (pendingMode == GameMode.sun) {
          _showBubble(seat, 'Sun');
        } else {
          final suit = _engine.activeRound2PendingTrump;
          _showBubble(seat, 'Hakam Sani ${_suitSymbol(suit)}');
        }
      } else if (rs.activeMode == GameMode.sun && rs.buyerIndex == seat) {
         _showBubble(seat, 'Sun');
      } else if (rs.isAshkal && rs.buyerIndex == seat) {
         _showBubble(seat, 'Ashkal');
      } else {
        _showBubble(seat, 'PassR2');
      }
    } else {
      _showBubble(seat, 'Pass');
    }
  }

  /// Infer what the bot did in the double window.
  void _inferBotDoubleBubble(int seat) {
    final ds = _engine.roundState.doubleStatus;
    if (ds != DoubleStatus.none) {
      _showBubble(seat, _doubleLabel(ds));
    }
    // Note: If the bot passes (DoubleStatus.none), we do NOT show a "Pass" bubble.
    // This ensures a clean, silent transition to gameplay without lingering "Bas" bubbles.
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
    
    // Clear selection on timeout so it doesn't get stuck
    _selectedCard = null;
    
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
    _humanTurnStartedAt = null;
    _botTimer?.cancel();
    _botTimer = null;
    _botTurnStartedAt = null;
    _sawaRevealTimer?.cancel();
    _sawaRevealTimer = null;
  }





  // ══════════════════════════════════════════════════════════════════
  //  SPEECH BUBBLES
  // ══════════════════════════════════════════════════════════════════

  void _showBubble(int seat, String text) {
    _audioService.playBubble(text);
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

  void _clearAllBubbles() {
    for (final timer in _bubbleTimers.values) {
      timer.cancel();
    }
    _bubbleTimers.clear();
    _bubbles.clear();
    notifyListeners();
  }

  void _announceProjects(int seatIndex) {
    final projects = roundState.declaredProjects
        .where((p) => p.playerIndex == seatIndex && p.type != ProjectType.baloot)
        .toList();
    if (projects.isEmpty) return;
    
    // Standard standard: announce only the project type name (no card details).
    // Use the same short display labels as the picker buttons.
    final names = projects.map((p) {
      switch (p.type) {
        case ProjectType.fourHundred: return '400';
        case ProjectType.hundred:
        case ProjectType.fourJacks:
        case ProjectType.sixCardRun:
        case ProjectType.sevenCardRun:
        case ProjectType.eightCardRun:
          return '100';
        case ProjectType.fifty: return '50';
        case ProjectType.sera: return 'Sera';
        case ProjectType.baloot: return ''; // Never shown here
      }
    }).where((s) => s.isNotEmpty).toSet().toList();
    
    _showBubble(seatIndex, names.join(' & '));

    final has400 = projects.any((p) => p.type == ProjectType.fourHundred);
    if (has400) {
      final opp1 = (seatIndex + 1) % 4;
      final opp2 = (seatIndex + 3) % 4;
      if (opp1 != 0) _checkBotExpressions(opp1, event: 'opponent_400');
      if (opp2 != 0) _checkBotExpressions(opp2, event: 'opponent_400');
    }
  }

  void _checkBotExpressions(int seat, {required String event, int? abnatLost}) {
    return; // Disabled for now per user request
    if (seat == 0 || _engine.isGameOver) return;
    final diff = _lastDifficulty;
    final roll = _rng.nextDouble();

    if (diff == BotDifficulty.easy) {
      // Spec §1.6: 20% chance to send ANY expression on any turn, not contextually
      if (event == 'turn' && roll < 0.20) {
        const exprs = ['Celebrate', 'Oops', 'Surprised', 'GoodLuck'];
        _showBubble(seat, exprs[_rng.nextInt(exprs.length)]);
      }
      return;
    }

    if (diff == BotDifficulty.medium) {
      // Spec §2.7: Contextually appropriate 40% of the time (60% no expression)
      if (roll >= 0.40) return;
      if (event == 'kaboot') {
        _showBubble(seat, 'Celebrate');
      } else if (event == 'lost_critical_trick' && (abnatLost ?? 0) >= 15) {
        _showBubble(seat, 'Oops');
      } else if (event == 'opponent_400') {
        _showBubble(seat, 'Surprised');
      }
      return;
    }

    if (diff == BotDifficulty.hard) {
      // Spec §3: Contextually perfect, timed naturally
      if (event == 'kaboot' && roll < 0.80) {
        _showBubble(seat, 'Celebrate');
      } else if (event == 'lost_critical_trick' && (abnatLost ?? 0) >= 15 && roll < 0.50) {
        _showBubble(seat, 'Oops');
      } else if (event == 'opponent_400' && roll < 0.85) {
        _showBubble(seat, 'Surprised');
      } else if (event == 'turn' && roll < 0.05) {
        _showBubble(seat, 'GoodLuck');
      }
    }
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

    // Find if any team declared Baloot this round
    final balootProject = rs.declaredProjects
        .where((p) => p.type == ProjectType.baloot)
        .firstOrNull;
    final balootTeam = balootProject != null
        ? (balootProject.playerIndex % 2 == 0 ? 'A' : 'B')
        : null;

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
      balootTeam: balootTeam,
      isKhams: d.isKhams,
      isKabout: d.isKabout,
      reason: d.reason,
      winningTeam: d.winningTeam,
      buyerTeam: d.buyerTeam,
      mode: d.mode,
      trumpSuit: rs.trumpSuit,
      doubleStatus: d.doubleStatus,
      playSawaClaimSeat: _engine.lastPlaySawaClaimSeat,
      teamAProjectsList: d.teamAProjectsList,
      teamBProjectsList: d.teamBProjectsList,
    );

    if (_engine.isGameOver) {
      // Detect if the human team achieved kaboot (won all 8 tricks = isKabout flag on game-ending event)
      final bool humanTeamKaboot = d.isKabout && _engine.gameWinner == 'A';
      if (_engine.gameWinner == 'A') {
        _audioService.playYouWin();
      } else {
        _audioService.playYouLose();
      }
      
      _handleMatchOver(wasKaboot: humanTeamKaboot); // Calculate points!
    } else if (d.isKabout) {
      _audioService.playKabloot();
      for (int seat = 1; seat < 4; seat++) {
        final botTeam = (seat % 2 == 0) ? 'A' : 'B';
        if (botTeam == d.winningTeam) {
          _checkBotExpressions(seat, event: 'kaboot');
        }
      }
    }
  }

  Future<void> _handleMatchOver({bool wasKaboot = false}) async {
    final bool humanWon = didHumanWinGame;

    // Simulate bot opponent rank (slightly below player for offline bot games)
    final RankTier oppRank = _playerStats.blueStars > 300
        ? RankCalculator.getRankFromStars(
            (_playerStats.blueStars - 200).clamp(0, 9999),
            (_playerStats.blueStars - 200).clamp(0, 9999))
        : playerRank;

    final result = PointsCalculator.calculateMatchPoints(
      result: humanWon ? GameResult.win : GameResult.loss,
      playerStats: _playerStats,
      playerRank: playerRank,
      opponentRank: oppRank,
      applyBotCap: true, // always capped — offline bot games only
    );

    _lastMatchOutcome = await PlayerStatsService.applyMatchResult(
      stats: _playerStats,
      result: result,
      gameResult: humanWon ? GameResult.win : GameResult.loss,
      wasKaboot: wasKaboot,
      opponentRank: oppRank,
    );
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════════

  String _bidActionLabel(BidAction action, Suit? secondHakamSuit) {
    switch (action) {
      case BidAction.hakam:        return 'Hakam';
      case BidAction.sun:          return 'Sun';
      case BidAction.secondHakam:  return 'Hakam Sani ${_suitSymbol(secondHakamSuit)}';
      case BidAction.ashkal:       return 'Ashkal';
      case BidAction.qablak:       return 'Qablak';
      case BidAction.sawa:         return 'Sawa';
      case BidAction.pass:
        if (_engine.roundState.biddingPhase == BiddingPhase.round2) {
          return 'PassR2';
        }
        return 'Pass';
      case BidAction.confirmHakam: 
        final trump = _engine.roundState.trumpSuit;
        final buyerCard = _engine.roundState.buyerCard;
        if (trump != null && buyerCard != null && trump != buyerCard.suit) {
          return 'Hakam Sani ${_suitSymbol(trump)}';
        }
        return 'Hakam';
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
  //  DEBUG / TEST
  // ══════════════════════════════════════════════════════════════════

  void testRevealProjects() {
    _testDeclaredProjects = [
      const DeclaredProject(
        playerIndex: 1,
        type: ProjectType.hundred,
        cards: [
          CardModel(suit: Suit.spades, rank: Rank.ten),
          CardModel(suit: Suit.spades, rank: Rank.jack),
          CardModel(suit: Suit.spades, rank: Rank.queen),
          CardModel(suit: Suit.spades, rank: Rank.king),
          CardModel(suit: Suit.spades, rank: Rank.ace),
        ],
      ),
      const DeclaredProject(
        playerIndex: 2,
        type: ProjectType.sera,
        cards: [
          CardModel(suit: Suit.hearts, rank: Rank.ten),
          CardModel(suit: Suit.hearts, rank: Rank.jack),
          CardModel(suit: Suit.hearts, rank: Rank.queen),
        ],
      ),
      const DeclaredProject(
        playerIndex: 3,
        type: ProjectType.fifty,
        cards: [
          CardModel(suit: Suit.diamonds, rank: Rank.seven),
          CardModel(suit: Suit.diamonds, rank: Rank.eight),
          CardModel(suit: Suit.diamonds, rank: Rank.nine),
          CardModel(suit: Suit.diamonds, rank: Rank.ten),
        ],
      ),
    ];
    notifyListeners();
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
    _audioService.dispose();
    super.dispose();
  }
}
