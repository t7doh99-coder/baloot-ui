import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/card_model.dart' show CardModel, Suit, Rank;
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
    final game = context.watch<GameProvider>();
    final topInset = MediaQuery.paddingOf(context).top;

    final humanProjectCards = game.allDeclaredProjects
        .where((p) => p.playerIndex == 0)
        .expand((p) => p.cards)
        .toList();

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
                          bottom: 215, // Nudged further down as requested
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
                        bottom: 90, // Keeps cards static exactly under the regular dashboard profile
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
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      // Side column — wide enough for card fan + info box, with edge breathing room.
      const seatColW   = 92.0;
      const seatColPad = 4.0;
      // Partner band height — compact [_SeatPlayerInfoBox] + fan + bubble; [_TopSeat] scales via FittedBox.
      const topSeatH   = 128.0;
      const bottomPad  = 4.0;

      // Designer [`_TableSeatOverlay`]: rug begins below partner (`top: height * 0.055` + band).
      final rugTop   = h * 0.055 + topSeatH;
      final rugW     = w - seatColW * 2 - seatColPad * 2;
      final availH   = h - rugTop - bottomPad;
      final rugH     = (rugW / 0.727).clamp(0.0, availH);

      const rugLeft = seatColW + seatColPad;

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
                    onTap: () => context.read<GameProvider>().startGame()),
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
  final VoidCallback onTap;
  const _StartBtn({required this.onTap});

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
        child: const Text('Start Game',
            style: TextStyle(
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
//  bidding R1       │ Pass · Hakam · Sawa (if someone bid Hakam)
//  bidding R2       │ Pass · Sun · Hakam · Ashkal (dealer/sane)
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
    // Reset picker state if the main game phase or bidding sub-phase actually advances.
    // Also reset if double mode changes (escalation/cancellation).
    if (widget.game.phase != old.game.phase || 
        widget.game.biddingPhase != old.game.biddingPhase ||
        old.game.doubleStatus != widget.game.doubleStatus) {
      if (_activePicker != _DashboardPicker.none) {
        setState(() {
          _activePicker = _DashboardPicker.none;
          _pendingDouble = null;
          _selectedProjects.clear();
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
          _buildProjectPickerExpanded(context),
        if (_showHand(game.phase))
          const HumanPlayerMajlisBar(),
        _buildBottomActions(context),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final game = widget.game;
    final phase = game.phase;
    final isHumanTurn = game.isHumanTurn;

    List<Widget> buttons = [];

    if (_activePicker == _DashboardPicker.suit) {
      buttons = _buildSuitPickerButtons(context);
    } else if (_activePicker == _DashboardPicker.doublePlay) {
      buttons = _buildDoublePlayButtons(context);
    } else if (phase == GamePhase.bidding && isHumanTurn) {
      buttons = _biddingButtons(context);
    } else if (phase == GamePhase.doubleWindow && game.isHumanDefender) {
      buttons = _doubleButtons(context);
    } else if (phase == GamePhase.playing) {
      buttons = _playingButtons(context);
    } else {
      // DEV Mock standard fallback so bottom bar doesn't vanish
      buttons = [
        _GameBtn(label: 'Pass', onTap: () {}),
        _GameBtn(label: 'Hakam', onTap: () {}),
        _GameBtn(label: 'Projects', isActive: _activePicker == _DashboardPicker.projects, onTap: () {
          setState(() => _activePicker = _DashboardPicker.projects);
        }),
      ];
    }

    if (buttons.isEmpty) return const SizedBox(height: 8);

    return Container(
      height: 56,
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 8),
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

  List<Widget> _biddingButtons(BuildContext ctx) {
    final bp = widget.game.biddingPhase;
    final gp = ctx.read<GameProvider>();

    if (bp == BiddingPhase.round1) {
      final dealer = widget.game.dealerIndex;
      final sane   = (dealer + 3) % 4; // player to dealer's left (CCW)
      final canAshkal = (0 == dealer || 0 == sane);

      return [
        _GameBtn(label: 'Pass', onTap: () => gp.humanBid(BidAction.pass)),
        _GameBtn(label: 'Hakam', onTap: () => gp.humanBid(BidAction.hakam)),
        if (canAshkal)
          _GameBtn(label: 'Ashkal', onTap: () => gp.humanBid(BidAction.ashkal)),
        if (widget.game.hasActiveHakamBid)
          _GameBtn(label: 'Sawa', onTap: () => gp.humanBid(BidAction.sawa)),
      ];
    }

    if (bp == BiddingPhase.hakamConfirmation) {
      return [
        _GameBtn(label: 'Confirm Hakam', onTap: () => gp.humanBid(BidAction.confirmHakam)),
        _GameBtn(label: 'Switch to Sun', onTap: () => gp.humanBid(BidAction.sun)),
      ];
    }

    // Round 2
    return [
      _GameBtn(label: 'Pass', onTap: () => gp.humanBid(BidAction.pass)),
      _GameBtn(label: 'Sun', onTap: () => gp.humanBid(BidAction.sun)),
      _GameBtn(label: 'Hakam', onTap: () => setState(() => _activePicker = _DashboardPicker.suit)),
    ];
  }

  List<Widget> _doubleButtons(BuildContext ctx) {
    final gp = ctx.read<GameProvider>();
    final status = widget.game.doubleStatus;
    final levels = <(String, DoubleStatus)>[];

    if (status == DoubleStatus.none) {
      levels.add(('Double', DoubleStatus.doubled));
    }
    if (status == DoubleStatus.none || status == DoubleStatus.doubled) {
      levels.add(('Four', DoubleStatus.four));
    }
    levels.add(('Gahwa', DoubleStatus.gahwa));

    return [
      _GameBtn(label: 'Pass', onTap: () => gp.humanSkipDouble()),
      for (final (label, ds) in levels)
        _GameBtn(
          label: label,
          onTap: () {
            if (ds == DoubleStatus.gahwa) {
               gp.humanDouble(ds);
            } else {
               setState(() {
                 _pendingDouble = ds;
                 _activePicker = _DashboardPicker.doublePlay;
               });
            }
          },
        ),
    ];
  }

  List<Widget> _playingButtons(BuildContext ctx) {
    final gp = ctx.read<GameProvider>();
    final detected = gp.playerProjects.where((p) => p.type != ProjectType.baloot).toList();
    
    // In Kamelna/Jawaker, usually 4 buttons exist, but user requested just Projects and Sawa for now.
    return [
      // Projects Button (With little notification hint if detected > 0)
      Badge(
        isLabelVisible: detected.isNotEmpty && gp.trickNumber == 1,
        label: Text('${detected.length}'),
        offset: const Offset(-4, -4),
        child: _GameBtn(
          label: 'Projects', 
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
      
      _GameBtn(label: 'Sawa', onTap: () {}),
    ];
  }

  List<Widget> _buildSuitPickerButtons(BuildContext ctx) {
    final gp = ctx.read<GameProvider>();
    final buyerSuit = gp.buyerCard?.suit;
    final suits = Suit.values.where((s) => s != buyerSuit).toList();
    const suitNames = {Suit.hearts: '♥', Suit.diamonds: '♦', Suit.spades: '♠', Suit.clubs: '♣'};
    
    return [
       _GameBtn(label: 'Cancel', onTap: () => setState(() => _activePicker = _DashboardPicker.none)),
       for (final s in suits)
         _GameBtn(label: suitNames[s]!, onTap: () => gp.humanBid(BidAction.secondHakam, secondHakamSuit: s)),
    ];
  }

  List<Widget> _buildDoublePlayButtons(BuildContext ctx) {
    final gp = ctx.read<GameProvider>();
    return [
       _GameBtn(label: 'Cancel', onTap: () => setState(() => _activePicker = _DashboardPicker.none)),
       _GameBtn(label: 'Closed', onTap: () => gp.humanDouble(_pendingDouble ?? DoubleStatus.doubled, isOpenPlay: false)),
       _GameBtn(label: 'Open', onTap: () => gp.humanDouble(_pendingDouble ?? DoubleStatus.doubled, isOpenPlay: true)),
    ];
  }

  Widget _buildProjectPickerExpanded(BuildContext context) {
    final gp = context.read<GameProvider>();
    var detected = gp.playerProjects.where((p) => p.type != ProjectType.baloot).toList();
    
    final declared = gp.humanDeclaredProjects;
    final remaining = 2 - declared.length;

    const orderedTypes = [
      ProjectType.fourHundred,
      ProjectType.hundred,
      ProjectType.fifty,
      ProjectType.sera,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      height: 48,
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
                label: _projectName(t),
                isActive: isActive,
                onTap: () {
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

  String _projectName(ProjectType type) {
    switch (type) {
      case ProjectType.sera: return 'Sera';
      case ProjectType.fifty: return '50';
      case ProjectType.hundred: return '100';
      case ProjectType.fourHundred: return '400';
      case ProjectType.baloot: return 'Baloot';
    }
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
    final textStyle = TextStyle(
      fontSize: widget.label.length > 12 ? 12 : 14,
      fontWeight: FontWeight.w800,
      color: txtCol,
      height: 1.05,
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 44,
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
