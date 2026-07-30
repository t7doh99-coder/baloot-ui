import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/layout/game_table_layout.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/game_l10n.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../data/models/card_model.dart' show CardModel, Suit, GameMode;
import '../../../data/models/round_state_model.dart'
    show BiddingPhase, DoubleStatus, ProjectType;
import '../domain/baloot_game_controller.dart' show GamePhase;
import '../domain/managers/bidding_manager.dart' show BidAction;
import 'game_provider.dart';
import 'widgets/deal_overlay_widget.dart';
import 'widgets/human_hand_widget.dart';
import 'widgets/human_player_majlis_bar.dart';
import 'widgets/player_seat_widget.dart';

import 'widgets/scoring_overlays.dart';
import 'widgets/trick_area_widget.dart';
import 'widgets/last_trick_mini_widget.dart';
import 'widgets/game_table_majlis_hud.dart';
import 'widgets/majlis_table_background.dart';
import 'designer_table_test_screen.dart';

// ── Sandstone Dark palette ─────────
const _kGBgCanvas   = Color(0xFF1E1808);
const _kGBgCard     = Color(0xFF2C2210);
const _kGBgElevated = Color(0xFF392C14);
const _kGSandGold   = Color(0xFFC49028);
const _kGSandDark   = Color(0xFF886018);
const _kGTextPrim   = Color(0xFFF8EDD8);
const _kGSandBorder = Color(0x42C49028);
// ───────────────────────────────────

bool _showHand(GamePhase phase) {
  return phase != GamePhase.notStarted &&
      phase != GamePhase.dealing &&
      phase != GamePhase.scoring &&
      phase != GamePhase.gameOver;
}

// ══════════════════════════════════════════════════════════════════
//  GAME TABLE SCREEN
//
//  ┌──────────────────────────────────┐
//  │  TOP BAR:  Us | Baloot | Them   │
//  ├──────────────────────────────────┤
//  │  [Top player]                   │
//  │  [L]  [  TABLE / RUG  ]  [R]   │
//  ├──────────────────────────────────┤
//  │  [Curved human hand]            │
//  ├──────────────────────────────────┤
//  │  BOTTOM BAR: Pass / Hakam / …   │
//  ├──────────────────────────────────┤
//  │  Player strip (name · timer)    │
//  └──────────────────────────────────┘
// ══════════════════════════════════════════════════════════════════

class GameTableScreen extends StatefulWidget {
  const GameTableScreen({super.key});

  @override
  State<GameTableScreen> createState() => _GameTableScreenState();
}

class _GameTableScreenState extends State<GameTableScreen> {
  int _mapIndex = 0;
  Timer? _dealingWatchdog;
  bool _didPlayRoundStartSound = false;

  static const List<String> _majlisMapPaths = [
    AppAssets.majlisTableMap2,
    AppAssets.majlisTableMap,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final game = context.read<GameProvider>();
      // Resume turn loop now that the table UI is on screen.
      game.onTableReady();
      _armDealingWatchdog(game);
      _playRoundStartSoundDeferred(game);
    });
  }

  void _armDealingWatchdog(GameProvider game) {
    _dealingWatchdog?.cancel();
    if (game.phase != GamePhase.dealing) return;
    // Belt-and-suspenders: loading should have finished dealing already.
    _dealingWatchdog = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final g = context.read<GameProvider>();
      if (g.phase == GamePhase.dealing) {
        debugPrint('[GameTable] dealing watchdog fired');
        g.ensureDealingAdvances(force: true);
      }
    });
  }

  void _playRoundStartSoundDeferred(GameProvider game) {
    if (_didPlayRoundStartSound) return;
    if (game.phase == GamePhase.dealing) return;
    _didPlayRoundStartSound = true;
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<GameProvider>().audioService.playEffect(
            'round  start card sound.mp3',
          );
    });
  }

  @override
  void dispose() {
    _dealingWatchdog?.cancel();
    super.dispose();
  }

  bool _allowPop = false;

  void _confirmLeave(BuildContext context, GameProvider game) {
    final isAr = context.read<LocaleProvider>().isArabic;
    final titleFont = isAr ? GoogleFonts.cairo : GoogleFonts.readexPro;
    final bodyFont = isAr ? GoogleFonts.tajawal : GoogleFonts.readexPro;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1808), // bgCanvas
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC49028), width: 1.5), // gold border
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.redAccent, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  isAr ? 'مغادرة المباراة؟' : 'Leave Game?',
                  style: titleFont(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFDFAE45),
                  ),
                ),
                const SizedBox(height: 12),

                // Message banner / warning box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2210), // bgCard
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF392C14)),
                  ),
                  child: Text(
                    isAr
                        ? 'تنبيه: لن تحصل على أي نقاط خبرة (XP) أو مكافآت أو تقدم في المهام إذا غادرت المباراة الآن!'
                        : 'Warning: You will lose all match progress, XP rewards, and coin bonuses if you leave now!',
                    textAlign: TextAlign.center,
                    style: bodyFont(
                      fontSize: 13,
                      color: const Color(0xFFF8EDD8),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // Stay button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogCtx).pop(),
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2210),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFC49028)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isAr ? 'البقاء في اللعبة' : 'Stay in Game',
                            style: titleFont(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFDFAE45),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Leave button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(dialogCtx).pop(); // Close dialog
                          setState(() => _allowPop = true);
                          game.leaveTable();
                          Navigator.of(context).pop(); // Exit screen
                        },
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.redAccent.shade700, Colors.red.shade900],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isAr ? 'مغادرة' : 'Leave Game',
                            style: titleFont(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _cycleMajlisMap() {
    setState(() {
      _mapIndex = (_mapIndex + 1) % _majlisMapPaths.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final game = context.watch<GameProvider>();
    final lang = context.read<LocaleProvider>().isArabic ? 'ar' : 'en';
    if (game.audioService.langCode != lang) {
      // Defer — never notify GameProvider during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<GameProvider>().setLanguage(lang);
      });
    }
    final topInset = MediaQuery.paddingOf(context).top;
    final layoutScale = GameTableLayout.scale(context);

    final sawaBottom = game.isSawaRevealPlaying
        ? game.sawaRevealCardsForSeat(0)
        : const <CardModel>[];
    final humanProjectCards = sawaBottom.isNotEmpty
        ? sawaBottom
        : (game.showProjectReveal && game.projectRevealSeat == 0
            ? game.winningTeamBestProjectsForReveal
                .where((p) => p.playerIndex == 0)
                .expand((p) => p.cards)
                .toList()
            : const <CardModel>[]);

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _confirmLeave(context, game);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: MajlisTableBackground(
                mapAssetPath: _majlisMapPaths[_mapIndex],
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                    child: GameTableMajlisHud(
                      game: game,
                      onBack: () {
                        _confirmLeave(context, game);
                      },
                    onCycleWallpaper: _cycleMajlisMap,
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      // 1) The main play area (deals, tricks, other players)
                      Positioned.fill(child: _PlayArea(game: game)),

                      // 2) Human Player's Declared Project Cards (rendered underneath the hand/profile)
                      if (humanProjectCards.isNotEmpty)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: GameTableLayout.projectFanBottom(layoutScale),
                          child: Center(
                            child: ProjectCardFanRadial(
                              cards: humanProjectCards,
                              orientation: SeatOrientation.bottom,
                            ),
                          ),
                        ),
                      
                      // 3) The Human Hand — anchored at a fixed distance from bottom
                      // so when the dashboard expands, the cards do NOT move up!
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: GameTableLayout.handStackBottom(layoutScale),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: _showHand(game.phase)
                              ? const HumanHandWidget(key: ValueKey('hand'))
                              : const SizedBox(key: ValueKey('no-hand'), height: 8),
                        ),
                      ),
                      
                      // Speech Bubble for Human Player (Seat 0)
                      if (game.bubbles[0] != null)
                        Positioned(
                          right: 24 * layoutScale,
                          bottom: GameTableLayout.handStackBottom(layoutScale) + 160 * layoutScale,
                          child: SpeechBubbleOverlay(
                            bubble: game.bubbles[0]!,
                            tailOnLeft: true,
                          ),
                        ),
                      
                      // 4) The Unified Dashboard — anchored to the absolute bottom.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _HumanDashboardWidget(game: game),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Jawaker-style: last trick mini (red backs until first trick completes)
          if (game.phase != GamePhase.notStarted)
            Positioned(
              top: topInset + 6,
              right: 10,
              child: const LastTrickMiniWidget(),
            ),
          // Standard-style: persistent Double/Triple/Four badge during play
          if (game.doubleStatus != DoubleStatus.none &&
              (game.phase == GamePhase.playing || game.phase == GamePhase.scoring))
            Positioned(
              top: topInset + 60,
              left: 0,
              right: 0,
              child: Center(child: _DoubleBadge(status: game.doubleStatus)),
            ),
          // Show overlay whenever a round result exists (prioritize round scoreboard)
          if (game.lastRoundResult != null)
            const RoundScoreOverlay()
          else if (game.showGameOverOverlay)
            const GameOverOverlay(),

          // Qaid (Violation) Banner — Standard-style
          if (game.qaidViolationMessage != null)
            _QaidViolationBanner(
              message: game.qaidViolationMessage!,
              onDismiss: () => context.read<GameProvider>().clearQaidViolation(),
            ),
          // Qaid Claim Result Banner — Standard manual flag result
          if (game.qaidClaimResult != null)
            _QaidClaimResultBanner(
              isCorrect: game.qaidClaimResult == 'correct',
              onDismiss: () => context.read<GameProvider>().clearQaidClaimResult(),
            ),
        ],
      ),
    ));
  }
}

// ══════════════════════════════════════════════════════════════════
//  PLAY AREA
// ══════════════════════════════════════════════════════════════════

class _PlayArea extends StatelessWidget {
  final GameProvider game;
  const _PlayArea({required this.game});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final scale = GameTableLayout.scale(ctx);

      // Side column — wide enough for card fan + info box, with edge breathing room.
      final seatColW   = GameTableLayout.sideSeatColumnWidth(scale);
      const seatColPad = 4.0;
      // Partner band height — compact [_SeatPlayerInfoBox] + fan + bubble; [_TopSeat] scales via FittedBox.
      final topSeatH   = GameTableLayout.topPartnerBandHeight(scale);
      final bottomPad  = 4.0 * scale;

      // Designer [`_TableSeatOverlay`]: rug begins below partner (`top: height * 0.055` + band).
      final rugTop   = h * 0.055 + topSeatH;
      final rugW     = w - seatColW * 2 - seatColPad * 2;
      final availH   = h - rugTop - bottomPad;
      final rugH     = (rugW / 0.727).clamp(0.0, availH);

      final rugLeft = seatColW + seatColPad;

      return GestureDetector(
        onTap: () {
          final g = context.read<GameProvider>();
          if (g.selectedCard != null) g.clearSelection();
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          clipBehavior: Clip.none,
        children: [
          // Table area
          Positioned(
            left: rugLeft, top: rugTop,
            width: rugW, height: rugH,
            child: _TableArea(width: rugW, height: rugH),
          ),

          // Trick zone — played cards in the center (also drop target for hand drag)
          Positioned(
            left: rugLeft + rugW * 0.08,
            top:  rugTop  + rugH * 0.24,  // Moved trick zone further down to absolute center
            width: rugW   * 0.84,
            height: rugH  * 0.68,
            child: _TableCardDropTarget(game: game),
          ),

          // Deal overlay
          Positioned(
            left: rugLeft + rugW * 0.10,
            top:  rugTop  + rugH * 0.15,
            width: rugW   * 0.80,
            height: rugH  * 0.70,
            child: const DealOverlayWidget(),
          ),

          // Seat 2: top — designer [`_TableSeatOverlay`] `left/right: 31%`, `top: 5.5%`.
          Positioned(
            top: h * 0.055,
            left: w * 0.31,
            right: w * 0.31,
            height: topSeatH,
            child: const Center(
              child: PlayerSeatWidget(seat: 2, orientation: SeatOrientation.top),
            ),
          ),

          // Seat 3: left — shifted up to match table lift
          Positioned(
            left: 0,
            top: h * 0.24,
            bottom: h * 0.42,
            width: seatColW,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Center(
                child: PlayerSeatWidget(seat: 3, orientation: SeatOrientation.left),
              ),
            ),
          ),

          // Seat 1: right — shifted up to match table lift
          Positioned(
            right: 0,
            top: h * 0.24,
            bottom: h * 0.42,
            width: seatColW,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Center(
                child: PlayerSeatWidget(seat: 1, orientation: SeatOrientation.right),
              ),
            ),
          ),



          // Start game button
          if (game.phase == GamePhase.notStarted)
            Positioned(
              left: rugLeft, top: rugTop, width: rugW, height: rugH,
              child: Center(
                child: _StartBtn(
                  label: GameL10n.of(context).startGame,
                  onTap: () => context.read<GameProvider>().startGame(),
                ),
              ),
            ),
        ],
      ));
    });
  }
}

/// Accepts [Draggable] hand cards over the trick / table play area.
class _TableCardDropTarget extends StatelessWidget {
  const _TableCardDropTarget({required this.game});

  final GameProvider game;

  @override
  Widget build(BuildContext context) {
    return DragTarget<CardModel>(
      onWillAcceptWithDetails: (details) {
        if (game.phase != GamePhase.playing || !game.isHumanTurn) {
          return false;
        }
        return game.validCards.contains(details.data);
      },
      onAcceptWithDetails: (details) {
        HapticFeedback.mediumImpact();
        game.humanPlayCard(details.data);
      },
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            const TrickAreaWidget(),
            if (hovering)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.07),
                    border: Border.all(
                      color: AppColors.goldAccent.withValues(alpha: 0.45),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TableArea extends StatelessWidget {
  final double width;
  final double height;
  const _TableArea({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    // Open table surface — same tone as scaffold; no cream panel or frame
    return SizedBox(
      width: width,
      height: height,
    );
  }
}


class _StartBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _StartBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD4AF37), Color(0xFFFFE066)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.goldAccent.withValues(alpha: 0.5),
                blurRadius: 16, spreadRadius: 2),
          ],
        ),
        child: Text(label,
            style: const TextStyle(
                color: Color(0xFF3D2518),
                fontSize: 17,
                fontWeight: FontWeight.w900)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  BOTTOM BAR  — phase-aware gameplay buttons (per BALOOT_RULES.md)
//
//  Phase            │ Buttons (rules reference)
//  ─────────────────┼────────────────────────────────────────────
//  notStarted       │ (none)
//  dealing          │ (none)
//  bidding R1       │ Sun · Hakam · Ashkal? · Pass · Sawa? (Sawa = defenders after Hakam)
//  bidding R2       │ Sun · Second Hakam (suit) · ولا · then Pass/Sawa when bid pending
//  hakamConfirmation│ Confirm Hakam · Switch to Sun (R1 Hakam or R2 Second Hakam — Visca/Standard)
//  doubleWindow     │ Pass · Double · Four · Gahwa
//                   │ (only defending team; Hakam mode; or Sun >100 rule)
//  playing trick 1  │ Projects (8s pre-lead — you only); Majlis shows your 8s ring
//  playing trick 2+ │ (none — card tap + Play button handles it)
//  scoring          │ Next Round (auto)
//  gameOver         │ (none)
// ══════════════════════════════════════════════════════════════════

enum _DashboardPicker { none, projects, suit, doublePlay }

class _HumanDashboardWidget extends StatefulWidget {
  final GameProvider game;
  const _HumanDashboardWidget({required this.game});

  @override
  State<_HumanDashboardWidget> createState() => _HumanDashboardWidgetState();
}

class _HumanDashboardWidgetState extends State<_HumanDashboardWidget> {
  _DashboardPicker _activePicker = _DashboardPicker.none;
  DoubleStatus? _pendingDouble;
  final Set<int> _selectedProjects = {};

  int _manual400 = 0;
  int _manual100 = 0;
  int _manual50 = 0;
  int _manualSera = 0;

  int get _totalManual => _manual400 + _manual100 + _manual50 + _manualSera;

  /// [GameProvider] is a single instance; `didUpdateWidget`'s `oldWidget.game` is that
  /// same object, so comparing `old.game.phase` to `widget.game.phase` never detects
  /// engine updates. Track the last values we saw from a build instead.
  late GamePhase _trackedPhase;
  late int _trackedTrickNumber;
  late BiddingPhase _trackedBiddingPhase;
  late DoubleStatus _trackedDoubleStatus;

  @override
  void initState() {
    super.initState();
    _syncTrackedEngineFields(widget.game);
  }

  void _syncTrackedEngineFields(GameProvider g) {
    _trackedPhase = g.phase;
    _trackedTrickNumber = g.trickNumber;
    _trackedBiddingPhase = g.biddingPhase;
    _trackedDoubleStatus = g.doubleStatus;
  }

  /// Expanded project row: only before the opening lead on trick 1.
  static bool _projectsPickerMayShow(GameProvider g) {
    return g.canDeclareProjects;
  }

  @override
  void didUpdateWidget(_HumanDashboardWidget old) {
    super.didUpdateWidget(old);

    final g = widget.game;

    final progressed = g.phase != _trackedPhase ||
        g.trickNumber != _trackedTrickNumber ||
        g.biddingPhase != _trackedBiddingPhase ||
        g.doubleStatus != _trackedDoubleStatus;

    if (progressed) {
      if (_activePicker != _DashboardPicker.none) {
        setState(() {
          _activePicker = _DashboardPicker.none;
          _pendingDouble = null;
          _selectedProjects.clear();
          _manual400 = 0;
          _manual100 = 0;
          _manual50 = 0;
          _manualSera = 0;
        });
      } else {
        _selectedProjects.clear();
        _manual400 = 0;
        _manual100 = 0;
        _manual50 = 0;
        _manualSera = 0;
      }
      _syncTrackedEngineFields(g);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zone A: Action popup or project picker — separate box above player bar
        Transform.translate(
          offset: const Offset(0, 20.0), // Shift down to connect flush with yTop of the main bar
          child: _buildContextualZone(context),
        ),
        // Zones B+C: Player bar below
        if (_showHand(game.phase))
          HumanPlayerMajlisBar(
            isProjectExpanded: _activePicker == _DashboardPicker.projects,
            onProjectTap: () {
              setState(() {
                _activePicker = _activePicker == _DashboardPicker.projects
                    ? _DashboardPicker.none
                    : _DashboardPicker.projects;
              });
            },
          ),
      ],
    );
  }

  // ── Zone A: Action popup box (with side gaps) or project picker ──
  Widget _buildContextualZone(BuildContext context) {
    final loc  = GameL10n.of(context);
    final game = widget.game;

    if (game.isRoundJustEnded) return const SizedBox.shrink();

    if (_activePicker == _DashboardPicker.projects && _projectsPickerMayShow(game)) {
      return _buildProjectPickerExpanded(context, loc);
    }

    List<Widget> buttons = [];

    if (_activePicker == _DashboardPicker.suit) {
      buttons = _buildSuitPickerButtons(context, loc);
    } else if (_activePicker == _DashboardPicker.doublePlay) {
      buttons = _buildDoublePlayButtons(context, loc);
    } else if (game.phase == GamePhase.bidding && game.isHumanTurn) {
      buttons = _biddingButtons(context, loc);
    } else if (game.phase == GamePhase.doubleWindow &&
        game.isHumanTurn &&
        (game.isHumanDefender || game.isHumanBuyer)) {
      buttons = _doubleButtons(context, loc);
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    final scale = GameTableLayout.scale(context);
    final barH  = (56 * scale).clamp(50.0, 64.0);
    const extraBottomPadding = 14.0;

    // Stepped console box: left/right margin = 14px, bottom margin = 0px, flat bottom corners to connect with below bar
    return Container(
      height: barH + extraBottomPadding,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4 + extraBottomPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2210),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(
          top: BorderSide(color: Color(0x66C49028), width: 1.5),
          left: BorderSide(color: Color(0x66C49028), width: 1.5),
          right: BorderSide(color: Color(0x66C49028), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buttons
            .map((b) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: b,
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Bidding action buttons ──────────────────────────────────────────────
  List<Widget> _biddingButtons(BuildContext ctx, GameL10n loc) {
    final bp = widget.game.biddingPhase;
    final gp = ctx.read<GameProvider>();

    if (bp == BiddingPhase.round1) {
      final dealer    = widget.game.dealerIndex;
      final sane      = (dealer + 3) % 4;
      final canAshkal = (0 == dealer || 0 == sane);

      return [
        _GameBtn(label: loc.sun, onTap: () => gp.humanBid(BidAction.sun)),
        if (!gp.hasActiveHakamBid)
          _GameBtn(label: loc.hakam, onTap: () => gp.humanBid(BidAction.hakam)),
        if (!gp.hasActiveHakamBid && canAshkal)
          _GameBtn(label: loc.ashkal, onTap: () => gp.humanBid(BidAction.ashkal)),
        _GameBtn(label: loc.pass, onTap: () => gp.humanBid(BidAction.pass)),
      ];
    }

    if (bp == BiddingPhase.qablakIntervention) {
      return [
        _GameBtn(label: loc.qablak, onTap: () => gp.humanBid(BidAction.qablak)),
        _GameBtn(label: loc.pass, onTap: () => gp.humanBid(BidAction.pass)),
      ];
    }

    if (bp == BiddingPhase.hakamConfirmation) {
      return [
        _GameBtn(label: loc.confirmHakam, onTap: () => gp.humanBid(BidAction.confirmHakam)),
        _GameBtn(label: loc.switchToSun, onTap: () => gp.humanBid(BidAction.sun)),
      ];
    }

    if (widget.game.hasRound2PendingBid) {
      final isHakam = widget.game.activeRound2PendingMode == GameMode.hakam;
      return [
        if (isHakam) _GameBtn(label: loc.sun, onTap: () => gp.humanBid(BidAction.sun)),
        _GameBtn(label: loc.passRound2, onTap: () => gp.humanBid(BidAction.pass)),
      ];
    }

    final isDealer = widget.game.roundState.dealerIndex == _humanSeat;
    final isSane   = (widget.game.roundState.dealerIndex + 3) % 4 == _humanSeat;

    return [
      _GameBtn(label: loc.sun, onTap: () => gp.humanBid(BidAction.sun)),
      _GameBtn(
        label: loc.secondHakam,
        onTap: () => setState(() => _activePicker = _DashboardPicker.suit),
      ),
      if (isDealer || isSane)
        _GameBtn(label: loc.ashkal, onTap: () => gp.humanBid(BidAction.ashkal)),
      _GameBtn(label: loc.passRound2, onTap: () => gp.humanBid(BidAction.pass)),
    ];
  }

  // ── Double/pass action buttons ─────────────────────────────────────────
  List<Widget> _doubleButtons(BuildContext ctx, GameL10n loc) {
    final gp     = ctx.read<GameProvider>();
    final status = widget.game.doubleStatus;
    final mode   = widget.game.roundState.activeMode ?? GameMode.hakam;

    void openDoublePicker(DoubleStatus d) {
      setState(() {
        _pendingDouble = d;
        _activePicker  = _DashboardPicker.doublePlay;
      });
    }

    if (gp.isHumanBuyer) {
      if (status == DoubleStatus.doubled && mode == GameMode.hakam) {
        return [
          _GameBtn(label: loc.pass,   onTap: () => gp.humanSkipDouble()),
          _GameBtn(label: loc.triple, onTap: () => openDoublePicker(DoubleStatus.tripled)),
        ];
      }
      if (status == DoubleStatus.four && mode == GameMode.hakam) {
        return [
          _GameBtn(label: loc.pass,  onTap: () => gp.humanSkipDouble()),
          _GameBtn(label: loc.gahwa, onTap: () => gp.humanDouble(DoubleStatus.gahwa)),
        ];
      }
      return [];
    }

    if (!gp.isHumanDefender) return [];

    if (mode == GameMode.sun) {
      if (!gp.canDefenderDoubleInSun) {
        return [_GameBtn(label: loc.pass, onTap: () => gp.humanSkipDouble())];
      }
      if (status != DoubleStatus.none) return [];
      return [
        _GameBtn(label: loc.pass,       onTap: () => gp.humanSkipDouble()),
        _GameBtn(label: loc.doubleWord, onTap: () => openDoublePicker(DoubleStatus.doubled)),
      ];
    }

    if (status == DoubleStatus.none) {
      return [
        _GameBtn(label: loc.pass,       onTap: () => gp.humanSkipDouble()),
        _GameBtn(label: loc.doubleWord, onTap: () => openDoublePicker(DoubleStatus.doubled)),
      ];
    }
    if (status == DoubleStatus.tripled) {
      return [
        _GameBtn(label: loc.pass, onTap: () => gp.humanSkipDouble()),
        _GameBtn(label: loc.four, onTap: () => openDoublePicker(DoubleStatus.four)),
      ];
    }
    return [];
  }

  static const int _humanSeat = 0;



  List<Widget> _buildSuitPickerButtons(BuildContext ctx, GameL10n loc) {
    final gp = ctx.read<GameProvider>();
    final buyerSuit = gp.buyerCard?.suit;
    final suits = Suit.values.where((s) => s != buyerSuit).toList();
    const suitNames = {Suit.hearts: '\u2665', Suit.diamonds: '\u2666', Suit.spades: '\u2660', Suit.clubs: '\u2663'};
    
    return [
       for (final s in suits)
         _GameBtn(label: suitNames[s]!, onTap: () {
           gp.humanBid(BidAction.secondHakam, secondHakamSuit: s);
           setState(() => _activePicker = _DashboardPicker.none);
         }),
    ];
  }

  List<Widget> _buildDoublePlayButtons(BuildContext ctx, GameL10n loc) {
    final gp = ctx.read<GameProvider>();
    return [
       _GameBtn(label: loc.closed, onTap: () {
         gp.humanDouble(_pendingDouble ?? DoubleStatus.doubled, isOpenPlay: false);
         setState(() => _activePicker = _DashboardPicker.none);
       }),
       _GameBtn(label: loc.open, onTap: () {
         gp.humanDouble(_pendingDouble ?? DoubleStatus.doubled, isOpenPlay: true);
         setState(() => _activePicker = _DashboardPicker.none);
       }),
    ];
  }

  Widget _buildProjectPickerExpanded(BuildContext context, GameL10n loc) {
    final gp = context.read<GameProvider>();
    final canEditProjects = gp.canDeclareProjects;
    final allProjects = gp.playerProjects;

    const orderedTypes = [
      ProjectType.fourHundred,
      ProjectType.hundred,
      ProjectType.fifty,
      ProjectType.sera,
    ];

    final scale = GameTableLayout.scale(context);
    const extraBottomPadding = 14.0;

    // Stepped console box: left/right margin = 14px, bottom margin = 0px, flat bottom corners to connect with below bar
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4 + extraBottomPadding),
      height: (48 * scale).clamp(44.0, 56.0) + extraBottomPadding,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2210),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(
          top: BorderSide(color: Color(0x66C49028), width: 1.5),
          left: BorderSide(color: Color(0x66C49028), width: 1.5),
          right: BorderSide(color: Color(0x66C49028), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: List.generate(orderedTypes.length, (idx) {
          final t = orderedTypes[idx];
          
          final List<ProjectType> matchingTypes;
          if (t == ProjectType.hundred) {
            matchingTypes = [
              ProjectType.hundred,
              ProjectType.fourJacks,
              ProjectType.sixCardRun,
              ProjectType.sevenCardRun,
              ProjectType.eightCardRun
            ];
          } else {
            matchingTypes = [t];
          }

          final origIndices = allProjects.asMap().entries
              .where((e) => matchingTypes.contains(e.value.type))
              .map((e) => e.key).toList();
              
          int manualCount = 0;
          if (t == ProjectType.fourHundred) manualCount = _manual400;
          else if (t == ProjectType.hundred) manualCount = _manual100;
          else if (t == ProjectType.fifty) manualCount = _manual50;
          else if (t == ProjectType.sera) manualCount = _manualSera;

          final isActive = manualCount > 0;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: idx < 3 ? 8.0 : 0.0),
              child: _GameBtn(
                leading: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFD4AF37).withValues(alpha: 0.65)
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    manualCount.toString(),
                    style: TextStyle(
                      color: isActive
                          ? Colors.black
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
                label: loc.projectType(t),
                isActive: isActive,
                onTap: () {
                  if (!canEditProjects) return;
                  
                  setState(() {
                    if (_totalManual >= 2) {
                      // 3rd press resets everything
                      _manual400 = 0;
                      _manual100 = 0;
                      _manual50 = 0;
                      _manualSera = 0;
                      
                      // Undeclare from engine
                      for (var idx in _selectedProjects) {
                        gp.humanUndeclareProject(allProjects[idx].type);
                      }
                      _selectedProjects.clear();
                    } else {
                      // Increment counter
                      if (t == ProjectType.fourHundred) _manual400++;
                      else if (t == ProjectType.hundred) _manual100++;
                      else if (t == ProjectType.fifty) _manual50++;
                      else if (t == ProjectType.sera) _manualSera++;
                      
                      // If the user actually HAS this occurrence, declare it in engine
                      int newCount = 0;
                      if (t == ProjectType.fourHundred) newCount = _manual400;
                      else if (t == ProjectType.hundred) newCount = _manual100;
                      else if (t == ProjectType.fifty) newCount = _manual50;
                      else if (t == ProjectType.sera) newCount = _manualSera;
                      
                      int foundCount = 0;
                      for (var oIdx in origIndices) {
                        foundCount++;
                        if (foundCount == newCount && !_selectedProjects.contains(oIdx)) {
                          _selectedProjects.add(oIdx);
                          gp.humanDeclareProject(oIdx);
                          break;
                        }
                      }
                    }
                  });
                }
              ),
            ),
          );
        }),
      )
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  MAJLIS ACTION BUTTONS  — pill gradients + Arabic (designer reference)
// ══════════════════════════════════════════════════════════════════



class _GameBtn extends StatefulWidget {
  final String label;
  final Widget? leading;
  final bool isActive;
  final VoidCallback onTap;
  const _GameBtn({
    required this.label,
    this.leading,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<_GameBtn> createState() => _GameBtnState();
}

class _GameBtnState extends State<_GameBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    setState(() => _isPressed = true);
    _ctrl.forward();
  }

  void _handleTapUp(_) {
    setState(() => _isPressed = false);
    _ctrl.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _ctrl.reverse();
  }

  void _handleTap() {
    context.read<GameProvider>().audioService.playGoldButton();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _isPressed || widget.isActive;
    final layoutScale = GameTableLayout.scale(context);
    final baseFs = widget.label.length > 12 ? 12.0 : 14.0;
    final btnH = (40 * layoutScale).clamp(36.0, 44.0);

    // 3D effect via multi-stop gradient instead of asymmetric borders
    // (Flutter doesn't support borderRadius + non-uniform Border widths)
    final faceGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: pressed
          ? const [0.0, 0.05, 0.95, 1.0]
          : const [0.0, 0.06, 0.85, 1.0],
      colors: pressed
          ? const [
              Color(0xFFD4A830), // bright gold top edge
              Color(0xFFB88820), // face top
              Color(0xFF886010), // face bottom
              Color(0xFF5A3A08), // darker bottom edge
            ]
          : const [
              Color(0xFFEED080), // bright highlight top edge (simulates light)
              Color(0xFFAA8848), // face top
              Color(0xFF4A3018), // face bottom
              Color(0xFF0A0602), // very dark bottom edge (simulates depth)
            ],
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          height: btnH + 4,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            margin: EdgeInsets.only(top: pressed ? 4.0 : 0.0),
            height: btnH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: faceGrad,
              // Uniform border — safe with borderRadius
              border: Border.all(
                color: pressed
                    ? const Color(0xFFC49028)
                    : const Color(0xFF9A7820),
                width: 1.0,
              ),
              boxShadow: pressed
                  ? [BoxShadow(color: _kGSandGold.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 1)]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 6, offset: const Offset(0, 5))],
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.leading != null) ...[
                    widget.leading!,
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: (baseFs * layoutScale).clamp(11.0, 16.0),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}




// -------------------------------------------------------------------------
//  QAID (VIOLATION) BANNER — Standard-style red flash
//  Shows when the human tries to play an illegal card.
// -------------------------------------------------------------------------

class _QaidViolationBanner extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;
  const _QaidViolationBanner({required this.message, required this.onDismiss});

  @override
  State<_QaidViolationBanner> createState() => _QaidViolationBannerState();
}

class _QaidViolationBannerState extends State<_QaidViolationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    // Auto-dismiss after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _ctrl.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _labelMap = {
    'suitViolation': 'Must follow the leading suit!',
    'cutViolation': 'Must cut with trump (Hakam)!',
    'upTrumpViolation': 'Must play a higher trump!',
    'closedPlayViolation': 'Closed play - cannot cut with trump!',
  };

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// -------------------------------------------------------------------------
//  QAID CLAIM RESULT BANNER — Standard manual flag result
//  Shows whether the Qaid claim was correct or false.
// -------------------------------------------------------------------------

class _QaidClaimResultBanner extends StatefulWidget {
  final bool isCorrect;
  final VoidCallback onDismiss;
  const _QaidClaimResultBanner({required this.isCorrect, required this.onDismiss});

  @override
  State<_QaidClaimResultBanner> createState() => _QaidClaimResultBannerState();
}

class _QaidClaimResultBannerState extends State<_QaidClaimResultBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _ctrl.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = GameL10n.of(context);
    final isCorrect = widget.isCorrect;
    final gradientColors = isCorrect
        ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)] // Green for correct
        : [const Color(0xFFB71C1C), const Color(0xFF7F0000)]; // Red for false
    final icon = isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final title = isCorrect ? loc.correctQaidMessage : loc.falseQaidMessage;

    return Positioned(
      top: 80,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isCorrect ? Colors.green : Colors.red).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(
                  color: (isCorrect ? Colors.green.shade300 : Colors.red.shade300).withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// DOUBLE STATUS BADGE (Standard-style)
//
// Persistent floating pill shown on the table during play when a
// Double/Triple/Four is active. Includes a subtle pulse animation.
// ══════════════════════════════════════════════════════════════════

class _DoubleBadge extends StatefulWidget {
  final DoubleStatus status;
  const _DoubleBadge({required this.status});

  @override
  State<_DoubleBadge> createState() => _DoubleBadgeState();
}

class _DoubleBadgeState extends State<_DoubleBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (label, multiplier, color) = switch (widget.status) {
      DoubleStatus.doubled => ('دبل', '×2', const Color(0xFFE63946)),
      DoubleStatus.tripled => ('تربل', '×3', const Color(0xFFFF6B00)),
      DoubleStatus.four    => ('فور', '×4', const Color(0xFFD4AF37)),
      DoubleStatus.gahwa   => ('قهوة', '☕', const Color(0xFF8B4513)),
      _                    => ('', '', Colors.transparent),
    };

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glowOpacity = 0.3 + (_pulse.value * 0.4);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: glowOpacity),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                multiplier,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: GoogleFonts.readexPro().fontFamily,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: GoogleFonts.readexPro().fontFamily,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
