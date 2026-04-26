import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  static const List<String> _majlisMapPaths = [
    AppAssets.majlisTableMap,
    AppAssets.majlisTableMap2,
  ];

  void _cycleMajlisMap() {
    setState(() {
      _mapIndex = (_mapIndex + 1) % _majlisMapPaths.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final game = context.watch<GameProvider>();
    final topInset = MediaQuery.paddingOf(context).top;
    final layoutScale = GameTableLayout.scale(context);

    final humanProjectCards = game.showProjectReveal
        ? game.allDeclaredProjects
            .where((p) => p.playerIndex == 0)
            .expand((p) => p.cards)
            .toList()
        : const <CardModel>[];

    return Scaffold(
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
                    onBack: () => Navigator.of(context).pop(),
                    onCycleWallpaper: _cycleMajlisMap,
                    onTestMode: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DesignerTableTestScreen(),
                        ),
                      );
                    },
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
          // Show overlay whenever a round result exists
          // (engine goes scoring→dealing in one step, so we match on result != null)
          if (game.lastRoundResult != null && game.phase != GamePhase.gameOver)
            const RoundScoreOverlay(),
          if (game.phase == GamePhase.gameOver) const GameOverOverlay(),

          // Qaid (Violation) Banner — Kammelna-style
          if (game.qaidViolationMessage != null)
            _QaidViolationBanner(
              message: game.qaidViolationMessage!,
              onDismiss: () => context.read<GameProvider>().clearQaidViolation(),
            ),
        ],
      ),
    );
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

      return Stack(
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
      );
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
//  hakamConfirmation│ Confirm Hakam · Switch to Sun (R1 Hakam or R2 Second Hakam — Visca/Kammelna)
//  doubleWindow     │ Pass · Double · Four · Gahwa
//                   │ (only defending team; Hakam mode; or Sun >100 rule)
//  playing trick 1  │ Projects (declare up to 2)
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

  @override
  void didUpdateWidget(_HumanDashboardWidget old) {
    super.didUpdateWidget(old);

    // Project reveal relies on the Radial Fan, not the dashboard picker menu.

    // Reset picker state if the main game phase or bidding sub-phase actually advances.
    // Also reset if double mode changes (escalation/cancellation) or trick advances to 2.
    if (widget.game.phase != old.game.phase || 
        widget.game.biddingPhase != old.game.biddingPhase ||
        old.game.doubleStatus != widget.game.doubleStatus ||
        widget.game.trickNumber != old.game.trickNumber) {
      if (_activePicker != _DashboardPicker.none) {
        setState(() {
          _activePicker = _DashboardPicker.none;
          _pendingDouble = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    return Column(
      mainAxisSize: MainAxisSize.min,
      // The hierarchy: Top (Projects expanded), Middle (Profile), Bottom (Actions)
      children: [
        if (_activePicker == _DashboardPicker.projects)
          _buildProjectPickerExpanded(context, GameL10n.of(context)),
        if (_showHand(game.phase))
          const HumanPlayerMajlisBar(),
        _buildBottomActions(context),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final loc = GameL10n.of(context);
    final game = widget.game;
    final phase = game.phase;
    final isHumanTurn = game.isHumanTurn;

    List<Widget> buttons = [];

    // During the 3s table pause + 6s scoreboard: show nothing
    if (game.isRoundJustEnded) return const SizedBox(height: 8);

    if (_activePicker == _DashboardPicker.suit) {
      buttons = _buildSuitPickerButtons(context, loc);
    } else if (_activePicker == _DashboardPicker.doublePlay) {
      buttons = _buildDoublePlayButtons(context, loc);
    } else if (phase == GamePhase.bidding) {
      if (isHumanTurn) {
        buttons = _biddingButtons(context, loc);
      }
    } else if (phase == GamePhase.doubleWindow) {
      if (isHumanTurn &&
          (game.isHumanDefender || game.isHumanBuyer)) {
        buttons = _doubleButtons(context, loc);
      }
    } else if (phase == GamePhase.playing) {
      buttons = _playingButtons(context, loc);
    }

    if (buttons.isEmpty) return const SizedBox(height: 8);

    final scale = GameTableLayout.scale(context);
    final barH = (56 * scale).clamp(48.0, 62.0);

    return Container(
      height: barH,
      margin: EdgeInsets.fromLTRB(10, 2, 10, 8 * scale),
      child: Row(
        children: buttons.map((b) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: b,
          ),
        )).toList(),
      ),
    );
  }

  List<Widget> _biddingButtons(BuildContext ctx, GameL10n loc) {
    final bp = widget.game.biddingPhase;
    final gp = ctx.read<GameProvider>();

    if (bp == BiddingPhase.round1) {
      final dealer = widget.game.dealerIndex;
      final sane   = (dealer + 3) % 4; // player to dealer's left (CCW)
      final canAshkal = (0 == dealer || 0 == sane);

      // Kammelna-style row: صن · حكم · أشكال · بس (+ سوى when defending after a Hakam)
      return [
        _GameBtn(label: loc.sun, onTap: () => gp.humanBid(BidAction.sun)),
        if (!gp.hasActiveHakamBid)
          _GameBtn(label: loc.hakam, onTap: () => gp.humanBid(BidAction.hakam)),
        if (!gp.hasActiveHakamBid && canAshkal)
          _GameBtn(label: loc.ashkal, onTap: () => gp.humanBid(BidAction.ashkal)),
        _GameBtn(label: loc.pass, onTap: () => gp.humanBid(BidAction.pass)),
        if (_humanCanSawaRound1(gp))
          _GameBtn(label: loc.sawa, onTap: () => gp.humanBid(BidAction.sawa)),
      ];
    }

    if (bp == BiddingPhase.hakamConfirmation) {
      return [
        _GameBtn(label: loc.confirmHakam, onTap: () => gp.humanBid(BidAction.confirmHakam)),
        _GameBtn(label: loc.switchToSun, onTap: () => gp.humanBid(BidAction.sun)),
      ];
    }

    // Round 2 — after Sun / Second Hakam, apps show Pass + Sawa only (Kammelna/Jawaker).
    if (widget.game.hasRound2PendingBid) {
      return [
        _GameBtn(label: loc.passRound2, onTap: () => gp.humanBid(BidAction.pass)),
        if (_humanCanSawaRound2(gp))
          _GameBtn(label: loc.sawa, onTap: () => gp.humanBid(BidAction.sawa)),
      ];
    }

    // Round 2 opening bids — BALOOT_RULES §4.3 (order matches Kammelna: صن · حكم ثاني · ولا)
    return [
      _GameBtn(label: loc.sun, onTap: () => gp.humanBid(BidAction.sun)),
      _GameBtn(
        label: loc.secondHakam,
        onTap: () => setState(() => _activePicker = _DashboardPicker.suit),
      ),
      _GameBtn(label: loc.passRound2, onTap: () => gp.humanBid(BidAction.pass)),
    ];
  }

  static const int _humanSeat = 0;

  bool _humanCanSawaRound1(GameProvider gp) {
    if (!gp.hasActiveHakamBid) return false;
    final h = gp.activeRound1HakamSeat;
    if (h == null) return false;
    return (_humanSeat % 2) != (h % 2);
  }

  bool _humanCanSawaRound2(GameProvider gp) {
    if (!gp.hasRound2PendingBid) return false;
    final p = gp.activeRound2PendingBuyerSeat;
    if (p == null) return false;
    return (_humanSeat % 2) != (p % 2);
  }

  List<Widget> _doubleButtons(BuildContext ctx, GameL10n loc) {
    final gp = ctx.read<GameProvider>();
    final status = widget.game.doubleStatus;
    final mode = widget.game.roundState.activeMode ?? GameMode.hakam;

    void openDoublePicker(DoubleStatus d) {
      setState(() {
        _pendingDouble = d;
        _activePicker = _DashboardPicker.doublePlay;
      });
    }

    // Buyer responses (Hakam chain only — Sun stops at one Double per rules).
    if (gp.isHumanBuyer) {
      if (status == DoubleStatus.doubled && mode == GameMode.hakam) {
        return [
          _GameBtn(label: loc.pass, onTap: () => gp.humanSkipDouble()),
          _GameBtn(label: loc.triple, onTap: () => openDoublePicker(DoubleStatus.tripled)),
        ];
      }
      if (status == DoubleStatus.four && mode == GameMode.hakam) {
        return [
          _GameBtn(label: loc.pass, onTap: () => gp.humanSkipDouble()),
          _GameBtn(label: loc.gahwa, onTap: () => gp.humanDouble(DoubleStatus.gahwa)),
        ];
      }
      return [];
    }

    if (!gp.isHumanDefender) return [];

    if (mode == GameMode.sun) {
      if (!gp.canDefenderDoubleInSun) {
        return [
          _GameBtn(label: loc.pass, onTap: () => gp.humanSkipDouble()),
        ];
      }
      if (status != DoubleStatus.none) return [];
      return [
        _GameBtn(label: loc.pass, onTap: () => gp.humanSkipDouble()),
        _GameBtn(label: loc.doubleWord, onTap: () => openDoublePicker(DoubleStatus.doubled)),
      ];
    }

    // Hakam — show only the next legal defender action (not Four/Gahwa up front).
    if (status == DoubleStatus.none) {
      return [
        _GameBtn(label: loc.pass, onTap: () => gp.humanSkipDouble()),
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

  List<Widget> _playingButtons(BuildContext ctx, GameL10n loc) {
    final gp = ctx.read<GameProvider>();
    if (gp.trickNumber > 1) return [];
    final detected = gp.playerProjects.where((p) => p.type != ProjectType.baloot).toList();
    
    return [
      Badge(
        isLabelVisible: detected.isNotEmpty,
        label: Text('${detected.length}'),
        offset: const Offset(-4, -4),
        child: _GameBtn(
          label: loc.projects,
          isActive: _activePicker == _DashboardPicker.projects,
          onTap: () {
            setState(() {
              _activePicker = _activePicker == _DashboardPicker.projects
                  ? _DashboardPicker.none
                  : _DashboardPicker.projects;
            });
          },
        ),
      ),
    ];
  }

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
    final canEditProjects = gp.trickNumber == 1;
    var detected = gp.playerProjects.where((p) => p.type != ProjectType.baloot).toList();
    
    final declared = gp.humanDeclaredProjects;
    final remaining = 2 - declared.length;

    const orderedTypes = [
      ProjectType.fourHundred,
      ProjectType.hundred,
      ProjectType.fifty,
      ProjectType.sera,
    ];

    final scale = GameTableLayout.scale(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      height: (48 * scale).clamp(44.0, 56.0),
      child: Row(
        children: List.generate(orderedTypes.length, (idx) {
          final t = orderedTypes[idx];
          
          // Find if user has this project available (either actually declared, or in detected list)
          final matches = detected.where((p) => p.type == t).toList();
          final countVal = matches.isEmpty ? 0 : 1;
          
          // Find matching index in the original detected list for selection tracking
          final origIndex = detected.indexWhere((p) => p.type == t);
          final isDeclared = declared.any((d) => d.type == t);
          final isSelected = origIndex >= 0 && _selectedProjects.contains(origIndex);
          final isActive = isDeclared || isSelected;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: idx < 3 ? 8.0 : 0.0),
              child: _GameBtn(
                leading: Container(
                  width: 18, height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(countVal.toString(), 
                    style: TextStyle(
                      color: isActive ? Colors.black : Colors.white, 
                      fontSize: 11, fontWeight: FontWeight.bold, height: 1
                    )
                  ),
                ),
                label: loc.projectType(t),
                isActive: isActive,
                onTap: () {
                  if (!canEditProjects) return;
                  if (origIndex < 0) return; // Completely unavailable
                  
                  if (isActive) {
                    // Toggle OFF (Undeclare)
                    setState(() {
                       _selectedProjects.remove(origIndex);
                    });
                     gp.humanUndeclareProject(t);
                  } else if (remaining > 0) {
                     // Toggle ON (Declare)
                     setState(() {
                       _selectedProjects.add(origIndex);
                     });
                     gp.humanDeclareProject(origIndex);
                  }
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
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  static (LinearGradient, Color, Color) _style(bool isPressed) {
    // Designer test screen match: Golden effect appears when button is selected (pressed).
    if (isPressed) {
      return (
        const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF2D08D), Color(0xFFC3912A)],
        ),
        const Color(0xFFE8C874), // Border
        const Color(0xFF41210E), // Text
      );
    } else {
      return (
        const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5A5A5A), Color(0xFF2D2D2D)],
        ),
        Colors.white.withValues(alpha: 0.12), // Border
        Colors.white, // Text
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (gradient, borderColor, txtCol) = _style(_isPressed || widget.isActive);
    final scale = GameTableLayout.scale(context);
    final baseFs = widget.label.length > 12 ? 12.0 : 14.0;
    final textStyle = TextStyle(
      fontSize: (baseFs * scale).clamp(11.0, 16.0),
      fontWeight: FontWeight.w800,
      color: txtCol,
      height: 1.05,
    );
    final btnH = (44 * scale).clamp(40.0, 52.0);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: btnH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: gradient,
            border: Border.all(color: borderColor, width: 1),
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
                  style: textStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------
//  QAID (VIOLATION) BANNER — Kammelna-style red flash
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
                gradient: const LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFF7F0000)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(
                  color: Colors.red.shade300.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Illegal Play!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _labelMap.entries
                              .firstWhere(
                                (e) => widget.message.toLowerCase().contains(e.key.toLowerCase()),
                                orElse: () => MapEntry('', widget.message),
                              )
                              .value,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
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


