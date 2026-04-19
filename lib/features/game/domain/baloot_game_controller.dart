import 'dart:math';
import '../../../core/errors/game_exceptions.dart';
import '../../../core/interfaces/i_baloot_controller.dart';
import '../../../data/models/card_model.dart';
import '../../../data/models/round_state_model.dart';
import 'managers/deck_manager.dart';
import 'managers/bidding_manager.dart';
import 'managers/turn_manager.dart';
import 'validators/play_validator.dart';
import 'engines/bot_engine.dart';
import 'engines/project_detector.dart';
import 'engines/scoring_engine.dart';

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
  final BotEngine _botEngine = const BotEngine();

  // Game-level state
  late List<String> _playerNames;
  int _teamAScore = 0;
  int _teamBScore = 0;
  int _dealerIndex = 0;
  GamePhase _gamePhase = GamePhase.notStarted;

  // Round-level state
  late DeckManager _deckManager;
  BiddingManager? _biddingManager;
  TurnManager? _turnManager;
  late RoundStateModel _roundState;
  late List<List<CardModel>> _hands;

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

  BalootGameController({Random? random}) : _rng = random ?? Random();

  /// Points and flags from the last completed round (cleared on new round).
  RoundScoreResult? get lastRoundScoreResult => _lastRoundScoreResult;

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

  GamePhase get gamePhase => _gamePhase;

  // ── IBalootController implementation ──

  @override
  void startNewGame(List<String> playerNames) {
    if (playerNames.length != 4) {
      throw const InvalidMoveException('Exactly 4 players required.');
    }
    _playerNames = playerNames;
    _teamAScore = 0;
    _teamBScore = 0;
    _dealerIndex = _rng.nextInt(4);
    _gamePhase = GamePhase.dealing;
    startNewRound();
  }

  @override
  void startNewRound() {
    _lastRoundScoreResult = null;
    _deckManager = DeckManager(random: _rng);
    _deckManager.createDeck();
    _deckManager.shuffle();
    _deckManager.kut();
    _deckManager.dealInitial(_dealerIndex);

    _hands = _deckManager.hands.map((h) => List<CardModel>.from(h)).toList();

    _roundState = RoundStateModel(
      dealerIndex: _dealerIndex,
      currentPlayerIndex: (_dealerIndex + 1) % 4, // first bidder = to dealer's right
      buyerCard: _deckManager.buyerCard,
    );

    _biddingManager = BiddingManager(
      dealerIndex: _dealerIndex,
      buyerCard: _deckManager.buyerCard!,
    );

    _turnManager = null;
    _detectedProjects.clear();
    _activeDeclaredProjects.clear();
    _balootDeclaredBy.clear();
    _escalationDefenderSeat = null;

    _gamePhase = GamePhase.bidding;
  }

  @override
  void placeBid(int seatIndex, BidAction action, {Suit? secondHakamSuit}) {
    if (_gamePhase != GamePhase.bidding) {
      throw const InvalidMoveException('Not in bidding phase.');
    }

    _biddingManager!.placeBid(seatIndex, action,
        secondHakamSuit: secondHakamSuit);

    _roundState = _roundState.copyWith(
      currentPlayerIndex: _biddingManager!.currentBidder,
      biddingPhase: _biddingManager!.phase,
    );

    if (_biddingManager!.isFinished) {
      final bidResult = _biddingManager!.result;

      if (bidResult == null) {
        // All passed both rounds → cancelled, advance dealer
        _roundState = _roundState.copyWith(
          biddingPhase: BiddingPhase.cancelled,
        );
        _dealerIndex = (_dealerIndex + 1) % 4; // dealer passes to the right
        _gamePhase = GamePhase.dealing;
        startNewRound();
        return;
      }

      // Complete the deal
      _deckManager.dealRemainder(
        bidResult.buyerIndex,
        isAshkal: bidResult.isAshkal,
      );
      _hands = _deckManager.hands.map((h) => List<CardModel>.from(h)).toList();

      // Detect projects in all hands
      for (int i = 0; i < 4; i++) {
        _detectedProjects[i] = _projectDetector.detectAll(
          _hands[i],
          bidResult.mode,
          trumpSuit: bidResult.trumpSuit,
        );
      }

      _escalationDefenderSeat = null;
      _roundState = _roundState.copyWith(
        biddingPhase: BiddingPhase.completed,
        activeMode: bidResult.mode,
        trumpSuit: bidResult.trumpSuit,
        buyerIndex: bidResult.buyerIndex,
        isAshkal: bidResult.isAshkal,
        currentPlayerIndex: (bidResult.buyerIndex + 1) % 4, // next player clockwise
        isDoubleWindowOpen: true,
      );

      _gamePhase = GamePhase.doubleWindow;
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

    if (level == DoubleStatus.gahwa) {
      // Gahwa = instant game win for the buyer team (who calls Gahwa)
      _roundState = _roundState.copyWith(
        doubleStatus: level,
        isOpenPlay: isOpenPlay,
        isDoubleWindowOpen: false,
      );
      final winnerTeam = callerIsTeamA ? 'A' : 'B';
      if (winnerTeam == 'A') {
        _teamAScore = 152;
      } else {
        _teamBScore = 152;
      }
      _gamePhase = GamePhase.gameOver;
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
      isOpenPlay: isOpenPlay,
      currentPlayerIndex: nextSeat,
    );
  }

  /// Skip the double window and proceed to play.
  void skipDoubleWindow() {
    if (_gamePhase != GamePhase.doubleWindow) {
      throw const InvalidMoveException('Double window is not open.');
    }
    _escalationDefenderSeat = null;
    _roundState = _roundState.copyWith(isDoubleWindowOpen: false);
    _gamePhase = GamePhase.playing;
    _startPlayPhase();
  }

  void _startPlayPhase() {
    // Jawaker/Kamelna: the buyer leads the first trick.
    final firstPlayer = _roundState.buyerIndex!;
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
  void playCard(int seatIndex, CardModel card) {
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

    // Validate the play
    final validation = _playValidator.validate(
      card: card,
      hand: _hands[seatIndex],
      currentTrick: _turnManager!.currentTrick,
      mode: _roundState.activeMode!,
      trumpSuit: _roundState.trumpSuit,
      doubleStatus: _roundState.doubleStatus,
      isOpenPlay: _roundState.isOpenPlay,
      playerSeat: seatIndex,
    );

    if (!validation.isValid) {
      throw PlayViolationException(
        type: _mapViolationKind(validation.violationKind!),
        playerIndex: seatIndex,
        message: validation.violationMessage!,
      );
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

    // Play the card
    final trickResult = _turnManager!.playCard(seatIndex, card);

    _roundState = _roundState.copyWith(
      currentTrick: _turnManager!.currentTrick,
      currentPlayerIndex: _turnManager!.currentPlayerIndex,
    );

    if (trickResult != null) {
      // Trick complete
      _roundState = _roundState.copyWith(
        trickNumber: _turnManager!.trickNumber,
        currentTrick: const [],
        teamATricksWon: List.from(_turnManager!.teamATricksWon),
        teamBTricksWon: List.from(_turnManager!.teamBTricksWon),
        teamAAbnat: _turnManager!.teamAAbnat,
        teamBAbnat: _turnManager!.teamBAbnat,
      );

      // Check if round is complete (all 8 tricks played)
      if (_turnManager!.isRoundComplete) {
        _scoreRound();
      }
    }
  }

  @override
  void declareProject(int seatIndex, int projectIndex) {
    if (_gamePhase != GamePhase.playing) {
      throw const InvalidMoveException('Not in play phase.');
    }
    if (_turnManager!.trickNumber > 1) {
      throw const InvalidMoveException(
        'Projects can only be declared during trick 1.',
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
    if (_gamePhase != GamePhase.playing || _turnManager!.trickNumber > 1) {
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

  void _scoreRound() {
    _gamePhase = GamePhase.scoring;

    final mode = _roundState.activeMode!;
    final buyerIndex = _roundState.buyerIndex!;
    final buyerTeam = buyerIndex % 2 == 0 ? 'A' : 'B';

    // Separate projects by team
    final teamAProjects = _activeDeclaredProjects
        .where((p) => p.playerIndex % 2 == 0)
        .toList();
    final teamBProjects = _activeDeclaredProjects
        .where((p) => p.playerIndex % 2 != 0)
        .toList();

    // Resolve project priority
    final projectWinner =
        _projectDetector.resolveProjectPriority(teamAProjects, teamBProjects);

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
      // Defending team = non-buyer team
      doubleCallerTeam = buyerTeam == 'A' ? 'B' : 'A';
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
    );

    _lastRoundScoreResult = scoreResult;

    _teamAScore += scoreResult.teamAPoints;
    _teamBScore += scoreResult.teamBPoints;

    // Check game end
    if (_scoringEngine.isGameOver(
        _teamAScore, _teamBScore, _roundState.doubleStatus)) {
      _gamePhase = GamePhase.gameOver;
    } else {
      // Advance dealer to the right for next round
      _dealerIndex = (_dealerIndex + 1) % 4;
      _gamePhase = GamePhase.dealing;
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
        if (botIsDefender && _roundState.activeMode == GameMode.hakam) {
          final level = _botEngine.decideDouble(
            hand: _hands[seatIndex],
            mode: _roundState.activeMode!,
            trumpSuit: _roundState.trumpSuit,
            ownScore: seatIndex % 2 == 0 ? _teamAScore : _teamBScore,
            opponentScore: seatIndex % 2 == 0 ? _teamBScore : _teamAScore,
          );
          if (level != null) {
            callDouble(seatIndex, level);
            return;
          }
        }
        skipDoubleWindow();

      case GamePhase.playing:
        // Auto-declare projects during trick 1
        if (_turnManager!.trickNumber == 1) {
          _botDeclareProjects(seatIndex);
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
        );
        playCard(seatIndex, card);

      default:
        break;
    }
  }

  /// Bot auto-declares all available non-Baloot projects during trick 1.
  void _botDeclareProjects(int seatIndex) {
    final projects = _detectedProjects[seatIndex];
    if (projects == null) return;

    for (int i = 0; i < projects.length; i++) {
      if (projects[i].type == ProjectType.baloot) continue;
      final alreadyDeclared = _activeDeclaredProjects
          .where(
              (p) => p.playerIndex == seatIndex && p.type != ProjectType.baloot)
          .length;
      if (alreadyDeclared >= 2) break;
      try {
        declareProject(seatIndex, i);
      } catch (_) {
        break;
      }
    }
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
    );
  }

  @override
  String? get gameWinner {
    if (!isGameOver) return null;
    return _scoringEngine.gameWinner(
        _teamAScore, _teamBScore, _roundState.doubleStatus);
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
