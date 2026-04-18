import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/card_model.dart' show Suit;
import '../../../data/models/round_state_model.dart'
    show BiddingPhase, DoubleStatus, ProjectType;
import '../domain/baloot_game_controller.dart' show GamePhase;
import '../domain/managers/bidding_manager.dart' show BidAction;
import 'game_provider.dart';
import 'widgets/deal_overlay_widget.dart';
import 'widgets/human_hand_widget.dart';
import 'widgets/human_player_majlis_bar.dart';
import 'widgets/player_seat_widget.dart';
import 'widgets/project_sheet.dart';
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
                Expanded(child: _PlayArea(game: game)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  // SizeTransition clips the curved hand (card tops); fade only.
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: _showHand(game.phase)
                      ? const HumanHandWidget(key: ValueKey('hand'))
                      : const SizedBox(key: ValueKey('no-hand'), height: 8),
                ),
                _BottomBar(game: game),
                if (_showHand(game.phase)) const HumanPlayerMajlisBar(),
              ],
            ),
          ),
          // Jawaker-style: last trick mini (red backs until first trick completes)
          if (game.phase != GamePhase.notStarted)
            Positioned(
              top: topInset + 58,
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

      const seatColW   = 72.0;
      const seatColPad = 2.0;
      // Room for card fan + avatar + bubble; [_TopSeat] also uses FittedBox if still tight
      const topSeatH   = 140.0;
      const bottomPad  = 4.0;

      final rugW   = w - seatColW * 2 - seatColPad * 2;
      final availH = h - topSeatH - bottomPad;
      final rugH   = (rugW / 0.727).clamp(0.0, availH);

      const rugLeft = seatColW + seatColPad;
      const rugTop  = topSeatH;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Table area
          Positioned(
            left: rugLeft, top: rugTop,
            width: rugW, height: rugH,
            child: _TableArea(width: rugW, height: rugH),
          ),

          // Trick zone — played cards in the center
          Positioned(
            left: rugLeft + rugW * 0.10,
            top:  rugTop  + rugH * 0.20,
            width: rugW   * 0.80,
            height: rugH  * 0.60,
            child: const TrickAreaWidget(),
          ),

          // Deal overlay
          Positioned(
            left: rugLeft + rugW * 0.10,
            top:  rugTop  + rugH * 0.15,
            width: rugW   * 0.80,
            height: rugH  * 0.70,
            child: const DealOverlayWidget(),
          ),

          // Seat 2: top
          Positioned(
            top: 0, left: rugLeft,
            width: rugW, height: topSeatH,
            child: Center(
              child: PlayerSeatWidget(seat: 2, orientation: SeatOrientation.top),
            ),
          ),

          // Seat 3: left
          Positioned(
            left: 0, top: rugTop + rugH * 0.15,
            width: seatColW,
            child: Center(
              child: PlayerSeatWidget(seat: 3, orientation: SeatOrientation.left),
            ),
          ),

          // Seat 1: right
          Positioned(
            right: 0, top: rugTop + rugH * 0.15,
            width: seatColW,
            child: Center(
              child: PlayerSeatWidget(seat: 1, orientation: SeatOrientation.right),
            ),
          ),

          // Project reveal banner (shown at trick 2)
          if (game.phase == GamePhase.playing &&
              game.trickNumber == 2 &&
              game.allDeclaredProjects.isNotEmpty)
            Positioned(
              left: rugLeft, top: rugTop + rugH * 0.05,
              width: rugW,
              child: ProjectRevealBanner(
                projects: game.allDeclaredProjects,
                playerName: game.playerName,
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

class _BottomBar extends StatelessWidget {
  final GameProvider game;
  const _BottomBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final phase = game.phase;
    final isHumanTurn = game.isHumanTurn;

    List<Widget> buttons = [];

    if (phase == GamePhase.bidding && isHumanTurn) {
      buttons = _biddingButtons(context);
    } else if (phase == GamePhase.doubleWindow && game.isHumanDefender) {
      buttons = _doubleButtons(context);
    } else if (phase == GamePhase.playing && game.trickNumber <= 1) {
      buttons = _playingButtons(context);
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

  // ── Bidding ───────────────────────────────────────────────────
  // R1: Pass · Hakam · (Sawa — only if another player already bid Hakam)
  // R2: Pass · Sun · Hakam(new suit) · Ashkal (only dealer or sane seat)
  List<Widget> _biddingButtons(BuildContext ctx) {
    final bp = game.biddingPhase;
    final gp = ctx.read<GameProvider>();

    if (bp == BiddingPhase.round1) {
      return [
        _GameBtn(
          label: 'Pass',
          variant: _MajlisActionButtonVariant.secondary,
          onTap: () => gp.humanBid(BidAction.pass),
        ),
        _GameBtn(
          label: 'Hakam',
          variant: _MajlisActionButtonVariant.primary,
          onTap: () => gp.humanBid(BidAction.hakam),
        ),
        if (game.hasActiveHakamBid)
          _GameBtn(
            label: 'Sawa',
            variant: _MajlisActionButtonVariant.accentBlue,
            onTap: () => gp.humanBid(BidAction.sawa),
          ),
      ];
    }

    // Hakam Confirmation — buyer confirms Hakam or switches to Sun
    if (bp == BiddingPhase.hakamConfirmation) {
      return [
        _GameBtn(
          label: 'Confirm Hakam',
          variant: _MajlisActionButtonVariant.primary,
          onTap: () => gp.humanBid(BidAction.confirmHakam),
        ),
        _GameBtn(
          label: 'Switch to Sun',
          variant: _MajlisActionButtonVariant.accentCoral,
          onTap: () => gp.humanBid(BidAction.sun),
        ),
      ];
    }

    // Round 2 — dynamic set
    final dealer = game.dealerIndex;
    final sane   = (dealer + 3) % 4; // player to dealer's left (CCW)
    final canAshkal = (0 == dealer || 0 == sane);

    return [
      _GameBtn(
        label: 'Pass',
        variant: _MajlisActionButtonVariant.secondary,
        onTap: () => gp.humanBid(BidAction.pass),
      ),
      _GameBtn(
        label: 'Sun',
        variant: _MajlisActionButtonVariant.accentCoral,
        onTap: () => gp.humanBid(BidAction.sun),
      ),
      _GameBtn(
        label: 'Hakam',
        variant: _MajlisActionButtonVariant.primary,
        onTap: () => _showSuitPicker(ctx, gp),
      ),
      if (canAshkal)
        _GameBtn(
          label: 'Ashkal',
          variant: _MajlisActionButtonVariant.accentBlue,
          onTap: () => gp.humanBid(BidAction.ashkal),
        ),
    ];
  }

  // ── Double Window ─────────────────────────────────────────────
  // Escalation: Pass · Double · Triple · Four · Gahwa
  // Only defending team can initiate; show current + next level
  List<Widget> _doubleButtons(BuildContext ctx) {
    final gp     = ctx.read<GameProvider>();
    final status = game.doubleStatus;

    // Determine which levels are still available (escalation)
    final levels = <(String, DoubleStatus, Color)>[];

    if (status == DoubleStatus.none) {
      levels.add(('Double', DoubleStatus.doubled, const Color(0xFFE63946)));
    }
    if (status == DoubleStatus.none || status == DoubleStatus.doubled) {
      levels.add(('Four', DoubleStatus.four, const Color(0xFFD88030)));
    }
    levels.add(('Gahwa', DoubleStatus.gahwa, const Color(0xFF8B0000)));

    return [
      _GameBtn(
        label: 'Pass',
        variant: _MajlisActionButtonVariant.secondary,
        onTap: () => gp.humanSkipDouble(),
      ),
      for (final (label, ds, col) in levels)
        _GameBtn(
          label: label,
          variant: _doubleVariantFor(col),
          onTap: ds == DoubleStatus.gahwa
              ? () => gp.humanDouble(ds)
              : () => _showOpenClosedPicker(ctx, gp, ds),
        ),
    ];
  }

  static _MajlisActionButtonVariant _doubleVariantFor(Color legacyAccent) {
    if (legacyAccent == const Color(0xFF8B0000)) {
      return _MajlisActionButtonVariant.danger;
    }
    if (legacyAccent == const Color(0xFFD88030)) {
      return _MajlisActionButtonVariant.accentAmber;
    }
    return _MajlisActionButtonVariant.accentCoral;
  }

  // ── Playing (trick 1 only) ─────────────────────────────────────
  // Project declaration button
  List<Widget> _playingButtons(BuildContext ctx) {
    final gp = ctx.read<GameProvider>();
    final detected = gp.playerProjects;
    final declared = gp.humanDeclaredProjects;
    final remaining = 2 - declared.length;

    // Hide if no projects detected or max already declared
    final nonBaloot = detected.where(
        (p) => p.type != ProjectType.baloot).toList();
    if (nonBaloot.isEmpty || remaining <= 0) return [];

    return [
      _GameBtn(
        label: 'Projects (${nonBaloot.length})',
        variant: _MajlisActionButtonVariant.primary,
        onTap: () => _showProjectPicker(ctx, gp),
      ),
    ];
  }

  // ── Suit picker for Second Hakam ──────────────────────────────
  void _showSuitPicker(BuildContext ctx, GameProvider gp) {
    final buyerSuit = gp.buyerCard?.suit;

    showModalBottomSheet<Suit>(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuitPickerSheet(excludeSuit: buyerSuit),
    ).then((suit) {
      if (suit != null) {
        gp.humanBid(BidAction.secondHakam, secondHakamSuit: suit);
      }
    });
  }

  // ── Project picker ─────────────────────────────────────────────
  void _showProjectPicker(BuildContext ctx, GameProvider gp) {
    showModalBottomSheet<List<int>>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProjectPickerSheet(
        detected: gp.playerProjects,
        alreadyDeclared: gp.humanDeclaredProjects,
        mode: gp.roundState.activeMode,
      ),
    ).then((indices) {
      if (indices != null) {
        for (final idx in indices) {
          gp.humanDeclareProject(idx);
        }
      }
    });
  }

  // ── Open/Closed picker for Double ─────────────────────────────
  void _showOpenClosedPicker(BuildContext ctx, GameProvider gp, DoubleStatus level) {
    showModalBottomSheet<bool>(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => const _OpenClosedSheet(),
    ).then((isOpen) {
      if (isOpen != null) {
        gp.humanDouble(level, isOpenPlay: isOpen);
      }
    });
  }
}

// ══════════════════════════════════════════════════════════════════
//  SUIT PICKER SHEET  — choose trump suit for Second Hakam (R2)
// ══════════════════════════════════════════════════════════════════

class _SuitPickerSheet extends StatelessWidget {
  final Suit? excludeSuit;
  const _SuitPickerSheet({this.excludeSuit});

  static const _suitData = <Suit, (String, Color)>{
    Suit.hearts:   ('Hearts ♥',   Color(0xFFE63946)),
    Suit.diamonds: ('Diamonds ♦', Color(0xFFE63946)),
    Suit.spades:   ('Spades ♠',   Color(0xFF2B2D42)),
    Suit.clubs:    ('Clubs ♣',    Color(0xFF2B2D42)),
  };

  @override
  Widget build(BuildContext context) {
    final suits = Suit.values.where((s) => s != excludeSuit).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Choose Trump Suit',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          if (excludeSuit != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '(${_suitData[excludeSuit]!.$1} is the buyer card suit)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: suits.map((s) {
              final (label, color) = _suitData[s]!;
              final symbol = label.split(' ').last;
              return GestureDetector(
                onTap: () => Navigator.pop(context, s),
                child: Container(
                  width: 72, height: 88,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(symbol,
                          style: TextStyle(fontSize: 32, color: color)),
                      const SizedBox(height: 2),
                      Text(label.split(' ').first,
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  OPEN / CLOSED SHEET  — choose play mode when doubling
// ══════════════════════════════════════════════════════════════════

class _OpenClosedSheet extends StatelessWidget {
  const _OpenClosedSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Choose Play Mode',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Applies to all players for this round',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, true),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E8B57).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF2E8B57).withValues(alpha: 0.5)),
                    ),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_open, color: Color(0xFF2E8B57), size: 28),
                        SizedBox(height: 4),
                        Text('Open', style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: Color(0xFF2E8B57))),
                        Text('Can lead with trump',
                            style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE63946).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFE63946).withValues(alpha: 0.5)),
                    ),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, color: Color(0xFFE63946), size: 28),
                        SizedBox(height: 4),
                        Text('Closed', style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: Color(0xFFE63946))),
                        Text('Cannot lead with trump',
                            style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  MAJLIS ACTION BUTTONS  — pill gradients + Arabic (designer reference)
// ══════════════════════════════════════════════════════════════════

enum _MajlisActionButtonVariant {
  /// Warm gold — Hakam, Confirm Hakam, Projects
  primary,
  /// Charcoal — Pass
  secondary,
  /// Cool blue — Sawa, Ashkal
  accentBlue,
  /// Coral-red — Sun, Switch to Sun, Double
  accentCoral,
  /// Warm orange — Four
  accentAmber,
  /// Deep red — Gahwa
  danger,
}

class _GameBtn extends StatefulWidget {
  final String label;
  final _MajlisActionButtonVariant variant;
  final VoidCallback onTap;
  const _GameBtn({
    required this.label,
    this.variant = _MajlisActionButtonVariant.secondary,
    required this.onTap,
  });

  @override
  State<_GameBtn> createState() => _GameBtnState();
}

class _GameBtnState extends State<_GameBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

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

  void _handleTap() {
    HapticFeedback.lightImpact();
    _ctrl.forward().then((_) {
      _ctrl.reverse();
      widget.onTap();
    });
  }

  static (LinearGradient, Color, List<BoxShadow>) _style(
    _MajlisActionButtonVariant v,
  ) {
    switch (v) {
      case _MajlisActionButtonVariant.primary:
        return (
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0D078),
              Color(0xFFD4A017),
              Color(0xFF9A7209),
            ],
          ),
          Colors.white.withValues(alpha: 0.22),
          [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        );
      case _MajlisActionButtonVariant.secondary:
        return (
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF5E5E5E).withValues(alpha: 0.92),
              const Color(0xFF2C2C2C),
            ],
          ),
          Colors.white.withValues(alpha: 0.12),
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case _MajlisActionButtonVariant.accentBlue:
        return (
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A6FA5),
              Color(0xFF2E4A6E),
              Color(0xFF1A2F4A),
            ],
          ),
          Colors.white.withValues(alpha: 0.14),
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case _MajlisActionButtonVariant.accentCoral:
        return (
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF9A4A4A),
              Color(0xFF6B2D2D),
              Color(0xFF3D1818),
            ],
          ),
          Colors.white.withValues(alpha: 0.12),
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case _MajlisActionButtonVariant.accentAmber:
        return (
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB87A30),
              Color(0xFF8A5218),
              Color(0xFF5C3410),
            ],
          ),
          Colors.white.withValues(alpha: 0.12),
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case _MajlisActionButtonVariant.danger:
        return (
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8B2A2A),
              Color(0xFF521414),
              Color(0xFF2A0A0A),
            ],
          ),
          Colors.white.withValues(alpha: 0.10),
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (gradient, borderColor, shadows) = _style(widget.variant);
    final textStyle = TextStyle(
      fontSize: widget.label.length > 12 ? 12 : 15,
      fontWeight: FontWeight.w700,
      color: Colors.white.withValues(alpha: 0.96),
      height: 1.05,
    );

    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: gradient,
            border: Border.all(color: borderColor, width: 1),
            boxShadow: shadows,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: textStyle,
            ),
          ),
        ),
      ),
    );
  }
}
