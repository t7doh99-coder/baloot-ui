import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:provider/provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/l10n/game_l10n.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/layout/game_table_layout.dart';
import '../../../../data/models/card_model.dart'
    show CardModel, Suit, Rank, GameMode;
import '../../../../data/models/round_state_model.dart' show BiddingPhase;
import '../../domain/baloot_game_controller.dart' show GamePhase;
import '../game_provider.dart';
import 'playing_card.dart'
    show CardBack, CardSize, PlayingCard, cardBackForSeat, playingCardHeightForWidth;

// ══════════════════════════════════════════════════════════════════
//  PLAYER SEAT WIDGET  — Jawaker-style circular avatar
//
//  Layout per seat:
//    • Face-down card fan
//    • Speech bubble
//    • Circular dark-sphere avatar with gold ring
//      - Ring starts FULL, depletes CLOCKWISE as turn runs out
//      - Sparkle particle at the shrinking tip (clockwise end)
//    • Name tag overlapping BOTTOM of the avatar circle (Jawaker style)
// ══════════════════════════════════════════════════════════════════

enum SeatOrientation { top, left, right, bottom }

class PlayerSeatWidget extends StatelessWidget {
  final int seat;
  final SeatOrientation orientation;

  const PlayerSeatWidget({
    super.key,
    required this.seat,
    required this.orientation,
  });

  @override
  Widget build(BuildContext context) {
    final game      = context.watch<GameProvider>();
    final isActive  = game.currentPlayerIndex == seat;
    final isDealer  = game.dealerIndex == seat;
    final isBuyer   = game.buyerIndex  == seat;
    final name      = game.playerName(seat);
    final cardCount = game.handSize(seat);
    final bubble    = game.bubbles[seat];

    final teamColor = (seat % 2 == 0)
        ? const Color(0xFF28802E)
        : const Color(0xFFE63946);

    // Project cards for this seat to show face-up behind the card fan
    final projectCards = game.allDeclaredProjects
        .where((p) => p.playerIndex == seat)
        .expand((p) => p.cards)
        .toList();

    if (orientation == SeatOrientation.left ||
        orientation == SeatOrientation.right) {
      return _SideSeat(
        seat: seat,
        cardCount: cardCount,
        name: name,
        isActive: isActive,
        isDealer: isDealer,
        isBuyer: isBuyer,
        teamColor: teamColor,
        bubble: bubble,
        orientation: orientation,
        projectCards: projectCards,
      );
    }

    return _TopSeat(
      seat: seat,
      cardCount: cardCount,
      name: name,
      isActive: isActive,
      isDealer: isDealer,
      isBuyer: isBuyer,
      teamColor: teamColor,
      bubble: bubble,
      projectCards: projectCards,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TOP SEAT  (seat 2 — partner)
// ══════════════════════════════════════════════════════════════════

class _TopSeat extends StatelessWidget {
  final int seat;
  final int cardCount;
  final String name;
  final bool isActive;
  final bool isDealer;
  final bool isBuyer;
  final Color teamColor;
  final PlayerBubble? bubble;
  final List<CardModel> projectCards;

  const _TopSeat({
    required this.seat,
    required this.cardCount,
    required this.name,
    required this.isActive,
    required this.isDealer,
    required this.isBuyer,
    required this.teamColor,
    required this.bubble,
    this.projectCards = const [],
  });

  @override
  Widget build(BuildContext context) {
    final scale = GameTableLayout.scale(context);
    final narrow = GameTableLayout.sideSeatColumnWidth(scale);
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (cardCount > 0)
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _TopCardFan(
                count: cardCount,
                seat: seat,
              ),
            ),
          ),

        Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              if (projectCards.isNotEmpty)
                Positioned(
                  top: 32 * scale, // Adjusted for 40% hidden look
                  child: ProjectCardFanRadial(
                    cards: projectCards,
                    orientation: SeatOrientation.top,
                  ),
                ),
              _SeatPlayerInfoBox(
                seatIndex: seat,
                name: name,
                isActive: isActive,
                isDealer: isDealer,
                isBuyer: isBuyer,
                teamColor: teamColor,
                orientation: SeatOrientation.top,
                designerNarrowWidth: narrow,
              ),
            ],
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        if (!maxW.isFinite || !maxH.isFinite) return column;
        return FittedBox(
          clipBehavior: Clip.none,
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: maxW,
            child: column,
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  SIDE SEAT  (seats 1 & 3 — left/right opponents)
// ══════════════════════════════════════════════════════════════════

class _SideSeat extends StatelessWidget {
  final int seat;
  final int cardCount;
  final String name;
  final bool isActive;
  final bool isDealer;
  final bool isBuyer;
  final Color teamColor;
  final PlayerBubble? bubble;
  final List<CardModel> projectCards;

  const _SideSeat({
    required this.seat,
    required this.cardCount,
    required this.name,
    required this.isActive,
    required this.isDealer,
    required this.isBuyer,
    required this.teamColor,
    required this.bubble,
    required this.orientation,
    this.projectCards = const [],
  });

  final SeatOrientation orientation;

  @override
  Widget build(BuildContext context) {
    final scale = GameTableLayout.scale(context);
    final narrow = GameTableLayout.sideSeatColumnWidth(scale);
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (cardCount > 0)
          _SideCardFan(
            count: cardCount,
            seat: seat,
          ),

        Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              if (projectCards.isNotEmpty)
                Positioned(
                  top: 32 * scale, // Adjusted for 40% hidden look
                  child: ProjectCardFanRadial(
                    cards: projectCards,
                    orientation: orientation,
                  ),
                ),
              _SeatPlayerInfoBox(
                seatIndex: seat,
                name: name,
                isActive: isActive,
                isDealer: isDealer,
                isBuyer: isBuyer,
                teamColor: teamColor,
                orientation: orientation,
                designerNarrowWidth: narrow,
              ),
            ],
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        if (!maxW.isFinite || !maxH.isFinite) return column;
        return FittedBox(
          clipBehavior: Clip.none,
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: maxW,
            child: column,
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  SEAT INFO CARD  — rounded glass box: avatar + name + round mode (Sun/Hakam…)
// ══════════════════════════════════════════════════════════════════

class _SeatPlayerInfoBox extends StatelessWidget {
  const _SeatPlayerInfoBox({
    required this.seatIndex,
    required this.name,
    required this.isActive,
    required this.isDealer,
    required this.isBuyer,
    required this.teamColor,
    required this.orientation,
    this.designerNarrowWidth,
  });

  final int seatIndex;
  final String name;
  final bool isActive;
  final bool isDealer;
  final bool isBuyer;
  final Color teamColor;
  final SeatOrientation orientation;
  final double? designerNarrowWidth;

  /// Matches designer [`_PlayerInfoChip`] `avatarSize: 36`.
  static const double _kAvatarDiameter = 36.0;

  static String _suitSymbol(Suit s) {
    switch (s) {
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.spades:
        return '♠';
      case Suit.clubs:
        return '♣';
    }
  }

  String _gameModeLine(GameProvider game, GameL10n loc) {
    switch (game.phase) {
      case GamePhase.notStarted:
        return '';
      case GamePhase.dealing:
        return loc.dealingShort;
      case GamePhase.bidding:
        final bp = game.biddingPhase;
        if (bp == BiddingPhase.hakamConfirmation) return loc.confirmShort;
        if (bp == BiddingPhase.round2) return loc.bidRound2Short;
        return loc.bidRound1Short;
      case GamePhase.doubleWindow:
        return loc.doubleShort;
      case GamePhase.playing:
      case GamePhase.scoring:
        final mode = game.roundState.activeMode;
        if (mode == null) return '—';
        final trump = game.trumpSuit;
        if (mode == GameMode.hakam && trump != null) {
          return '${loc.hakam} ${_suitSymbol(trump)}';
        }
        if (mode == GameMode.sun) {
          return loc.sun;
        }
        return loc.modeLabel(game.gameModeLabel);
      case GamePhase.gameOver:
        return loc.gameOverShort;
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final loc = GameL10n.of(context);
    final game = context.watch<GameProvider>();
    final modeText = _gameModeLine(game, loc);
    final highlighted = isActive;

    // Designer [`_PlayerInfoChip`] `compact: true` — exact colors & radii.
    final chip = Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xB070120E)
            : const Color(0x991F120F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? const Color(0xE0E4C267)
              : const Color(0x66FFFFFF),
          width: highlighted ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: PlayerAvatarRing(
              seatIndex: seatIndex,
              name: name,
              isActive: isActive,
              isDealer: isDealer,
              isBuyer: isBuyer,
              teamColor: teamColor,
              avatarDiameter: _kAvatarDiameter,
              showOverlayNameTag: false,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.94),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
              if (isDealer) ...[
                const SizedBox(width: 3),
                const _MiniDealerChip(compact: true),
              ],
              if (isBuyer) ...[
                const SizedBox(width: 2),
                const Icon(Icons.star,
                    color: Color(0xFFFFD700), size: 9),
              ],
            ],
          ),
          // The old dark badge is removed from here
        ],
      ),
    );

    final chipFrame = designerNarrowWidth != null
        ? SizedBox(width: designerNarrowWidth, child: chip)
        : chip;

    // ── Kamelna-style "Drawer" Bid Badge ─────────────
    Widget? bidBadge;
    if (seatIndex == game.buyerIndex && modeText.isNotEmpty) {
      final label = game.gameModeLabel == '—' ? modeText : game.gameModeLabel;
      final suit = game.trumpSuit; 
      
      // Determine theme colors based on parent box
      final bgColor = highlighted ? const Color(0xFF70120E) : const Color(0xFF2F1A15);
      final borderColor = highlighted ? const Color(0xE0E4C267) : const Color(0x66FFFFFF);
      
      bidBadge = _KamelnaBidBadge(
        label: label,
        suit: suit,
        backgroundColor: bgColor,
        borderColor: borderColor,
        isHighlighted: highlighted,
      );
    }

    final bubble = game.bubbles[seatIndex];

    final bool isLeft = orientation == SeatOrientation.left;
    final bool isRight = orientation == SeatOrientation.right;
    final bool isTop = orientation == SeatOrientation.top;

    final bool tailOnLeft = isLeft || isTop;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        chipFrame,
        if (bidBadge != null)
          Positioned(
            bottom: -15, // Tucked under the box
            child: bidBadge,
          ),
        if (bubble != null)
          Positioned(
            top: 10, // Align with avatar center
            left: (isLeft || isTop) ? 65.0 : null,
            right: isRight ? 65.0 : null,
            child: _SpeechBubbleOverlay(
              bubble: bubble,
              tailOnLeft: tailOnLeft,
            ),
          ),
      ],
    );
  }
}

class _KamelnaBidBadge extends StatelessWidget {
  final String label;
  final Suit? suit;
  final Color backgroundColor;
  final Color borderColor;
  final bool isHighlighted;

  const _KamelnaBidBadge({
    required this.label,
    this.suit,
    required this.backgroundColor,
    required this.borderColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78, // Slightly narrower than the 92px name box
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border.all(
          color: borderColor,
          width: isHighlighted ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (suit != null) ...[
            Text(
              _suitSymbol(suit!),
              style: TextStyle(
                color: (suit == Suit.hearts || suit == Suit.diamonds)
                    ? const Color(0xFFE53935)
                    : Colors.white,
                fontSize: 10,
                height: 1,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isHighlighted ? Colors.white : Colors.white.withValues(alpha: 0.8),
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  String _suitSymbol(Suit s) {
    switch (s) {
      case Suit.hearts: return '♥';
      case Suit.diamonds: return '♦';
      case Suit.spades: return '♠';
      case Suit.clubs: return '♣';
    }
  }
}

// ══════════════════════════════════════════════════════════════════
//  PLAYER AVATAR RING  — dark sphere + gold timer ring
//  Matches Jawaker exactly:
//    • Full gold ring when turn starts
//    • Ring depletes CLOCKWISE (remaining gold = remaining time)
//    • Sparkle particle at the shrinking TIP (clockwise leading edge)
//    • Name tag overlaps the bottom of the avatar (dark pill style)
// ══════════════════════════════════════════════════════════════════

class PlayerAvatarRing extends StatefulWidget {
  final int seatIndex;
  final String name;
  final bool isActive;
  final bool isDealer;
  final bool isBuyer;
  final Color teamColor;
  final double avatarDiameter;

  // Kept for backward-compatible call-sites
  final int? timerSecs;
  final int maxTimerSecs;

  /// When false, the Jawaker-style name pill on the avatar is omitted (e.g. when
  /// [_SeatPlayerInfoBox] shows name + mode below).
  final bool showOverlayNameTag;

  const PlayerAvatarRing({
    super.key,
    required this.seatIndex,
    required this.name,
    required this.isActive,
    required this.isDealer,
    required this.isBuyer,
    required this.teamColor,
    this.timerSecs,
    this.maxTimerSecs = 10,
    this.avatarDiameter = 46.0,
    this.showOverlayNameTag = true,
  });

  @override
  State<PlayerAvatarRing> createState() => _PlayerAvatarRingState();
}

class _PlayerAvatarRingState extends State<PlayerAvatarRing>
    with TickerProviderStateMixin {

  // Controls sparkle brightness oscillation (~3.5 Hz)
  late AnimationController _flickerCtrl;
  late Animation<double> _flickerAnim;

  // 60fps repaint ticker — smooth comet/ring movement
  Ticker? _repaintTicker;

  @override
  void initState() {
    super.initState();
    _flickerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..repeat(reverse: true);
    _flickerAnim = Tween<double>(begin: 0.45, end: 1.0).animate(_flickerCtrl);

    if (widget.isActive) {
      _repaintTicker = createTicker((_) => setState(() {}))..start();
    }
  }

  @override
  void didUpdateWidget(PlayerAvatarRing old) {
    super.didUpdateWidget(old);
    if (widget.isActive && _repaintTicker == null) {
      _repaintTicker = createTicker((_) => setState(() {}))..start();
    } else if (!widget.isActive && _repaintTicker != null) {
      _repaintTicker?.dispose();
      _repaintTicker = null;
    }
  }

  @override
  void dispose() {
    _repaintTicker?.dispose();
    _flickerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Live progress from provider — updated every frame by ticker
    final game      = context.watch<GameProvider>();
    final ringT     = (widget.avatarDiameter * 0.13).clamp(4.0, 7.0);
    final totalSz   = widget.avatarDiameter + ringT * 2 + 6;
    final progress  = widget.isActive ? game.activeSeatTimerProgress : 1.0;

    final avatarImagePath = AppAssets.playerAvatarPath(widget.seatIndex);

    return AnimatedBuilder(
      animation: _flickerCtrl,
      builder: (context, _) {
        final flicker = _flickerAnim.value;
        final tagH = widget.showOverlayNameTag ? 16.0 : 0.0;
        // Stack: ring canvas + dark sphere + optional name tag overlapping bottom
        return SizedBox(
          width: totalSz,
          height: totalSz + tagH,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // ── Gold ring + comet ───────────────────────────────
              CustomPaint(
                size: Size(totalSz, totalSz),
                painter: _RingPainter(
                  progress: progress,
                  ringThickness: ringT,
                  teamColor: widget.teamColor,
                  isActive: widget.isActive,
                  flicker: flicker,
                ),
              ),

              // ── Dark sphere ─────────────────────────────────────
              Positioned(
                top: ringT + 3,
                left: ringT + 3,
                child: _DarkSphere(
                  diameter: widget.avatarDiameter,
                  teamColor: widget.teamColor,
                  isActive: widget.isActive,
                  avatarImagePath: avatarImagePath,
                ),
              ),

              if (widget.showOverlayNameTag)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _NameTag(
                      name: widget.name,
                      teamColor: widget.teamColor,
                      isDealer: widget.isDealer,
                      isBuyer: widget.isBuyer,
                      compact: widget.avatarDiameter < 40,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  DARK SPHERE  (inner avatar circle)
// ══════════════════════════════════════════════════════════════════

class _DarkSphere extends StatelessWidget {
  final double diameter;
  final Color teamColor;
  final bool isActive;
  final String avatarImagePath;

  const _DarkSphere({
    required this.diameter,
    required this.teamColor,
    required this.isActive,
    required this.avatarImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.28, -0.38),
          radius: 0.85,
          colors: [
            Color(0xFF383860),
            Color(0xFF141428),
            Color(0xFF060610),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Avatar Image
          Positioned.fill(
            child: ClipOval(
              child: Opacity(
                opacity: isActive ? 1.0 : 0.6,
                child: Image.asset(
                  avatarImagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Specular highlight (top-left glass shine) over the image
          Positioned(
            top: diameter * 0.09,
            left: diameter * 0.17,
            child: Container(
              width: diameter * 0.44,
              height: diameter * 0.25,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(diameter * 0.15),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.32),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  BURNING FUSE RING PAINTER
//
//  A premium 60-fps circular countdown timer that looks like a
//  burning fuse wrapped around the avatar:
//
//  • progress = 1.0  →  full gold circle
//  • progress = 0.0  →  ring has fully burned away
//  • The ring burns CLOCKWISE from 12 o'clock
//    (arc CCW = remaining time; clockwise tip = burning point)
//
//  Layers (back → front):
//    1. Glowing bloom  — wide blurred arc behind the gold line
//    2. Gold fuse line — solid metallic arc (StrokeCap.round)
//    3. Tip corona     — soft blurred halo at the burning head
//    4. Tip core dot   — bright white centre of the flame
//    5. Sparkle cloud  — 8 tiny dots with independent flicker
// ══════════════════════════════════════════════════════════════════

class _RingPainter extends CustomPainter {
  // 1.0 = full ring, 0.0 = completely burned away
  final double progress;
  final double ringThickness;
  final Color  teamColor;
  final bool   isActive;
  // Oscillates 0.45 → 1.0 at ~3.5 Hz (driven by _flickerCtrl)
  final double flicker;

  // ── Palette ──────────────────────────────────────────────────────
  static const _fuseGold  = Color(0xFFD4A017); // main fuse line
  static const _fuseBright = Color(0xFFFFE566); // highlight / sparkles
  static const _fuseCore  = Color(0xFFFFF4AA); // very bright centre
  static const _fuseHot   = Color(0xFFFF8C00); // tip when < 30% left
  static const _fuseBloom = Color(0xFFB8860B); // broad glow behind arc

  const _RingPainter({
    required this.progress,
    required this.ringThickness,
    required this.teamColor,
    required this.isActive,
    required this.flicker,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive || progress <= 0.001) return;

    final cx     = size.width  / 2;
    final cy     = size.height / 2;
    final r      = min(cx, cy) - ringThickness / 2 - 1;
    final center = Offset(cx, cy);
    final rect   = Rect.fromCircle(center: center, radius: r);

    // ── Geometry ─────────────────────────────────────────────────
    // Arc starts at 12 o'clock and sweeps CCW for (progress × 360°).
    // The CLOCKWISE end of the arc is the burning TIP.
    const startAngle = -pi / 2;           // 12 o'clock (top)
    final arcSweep   = 2 * pi * progress; // CCW extent of gold arc
    final tipAngle   = startAngle - arcSweep; // burning tip position

    final tipX = cx + cos(tipAngle) * r;
    final tipY = cy + sin(tipAngle) * r;
    final tip  = Offset(tipX, tipY);

    // Hot state (< 30% remaining): tip turns orange
    final isHot     = progress < 0.30;
    final hotLerp   = isHot ? ((0.30 - progress) / 0.30).clamp(0.0, 1.0) : 0.0;
    final tipColor  = Color.lerp(_fuseBright, _fuseHot, hotLerp * flicker)!;

    // ── LAYER 1: Bloom glow behind the fuse line ─────────────────
    // A wide, soft, blurred arc that makes the line look "hot".
    canvas.drawArc(
      rect,
      tipAngle,
      arcSweep,
      false,
      Paint()
        ..color       = _fuseBloom.withValues(alpha: 0.40 * flicker)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = ringThickness * 2.8
        ..strokeCap   = StrokeCap.butt
        ..maskFilter  = MaskFilter.blur(BlurStyle.normal, ringThickness * 1.4),
    );

    // ── LAYER 2: Gold fuse line ───────────────────────────────────
    // Solid, metallic arc. StrokeCap.round gives rounded ends.
    canvas.drawArc(
      rect,
      tipAngle,
      arcSweep,
      false,
      Paint()
        ..color       = _fuseGold
        ..style       = PaintingStyle.stroke
        ..strokeWidth = ringThickness
        ..strokeCap   = StrokeCap.butt,
    );

    // Thin bright highlight on top (makes it look metallic)
    canvas.drawArc(
      rect,
      tipAngle,
      arcSweep,
      false,
      Paint()
        ..color       = _fuseBright.withValues(alpha: 0.45)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = ringThickness * 0.35
        ..strokeCap   = StrokeCap.butt,
    );

    // ── LAYER 3: Tip corona (wide soft halo) ─────────────────────
    canvas.drawCircle(
      tip,
      ringThickness * 2.5,
      Paint()
        ..color      = tipColor.withValues(alpha: 0.55 * flicker)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ringThickness * 1.6),
    );

    // Tighter inner glow
    canvas.drawCircle(
      tip,
      ringThickness * 1.2,
      Paint()
        ..color      = tipColor.withValues(alpha: 0.70 * flicker)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ringThickness * 0.5),
    );

    // ── LAYER 4: Tip core — bright white centre dot ───────────────
    canvas.drawCircle(
      tip,
      ringThickness * 0.65,
      Paint()..color = Colors.white.withValues(alpha: 0.95 * flicker),
    );

    // ── LAYER 5: Sparkle cloud around the burning tip ─────────────
    // 8 particles — each at a slightly different angle, distance,
    // and blink phase — giving an organic, randomly-twinkling feel.
    //
    // (angleOffsetDeg, radialOffset, dotRadius, phaseShift)
    // rOff values are plain numbers — ringThickness can't be used in const
    final particles = [
      ( 0.0,  2.2,  1.4, 0.00),
      ( 5.0,  1.8,  1.0, 0.55),
      (-6.0,  2.0,  1.1, 1.10),
      (11.0,  3.2,  0.8, 1.65),
      (-13.0, 2.8,  0.9, 2.20),
      ( 3.0, -2.1,  0.7, 2.75),
      (-4.0, -2.4,  0.8, 3.30),
      ( 8.0, -1.9,  0.6, 3.85),
    ];

    for (final (deg, rOff, dotR, phase) in particles) {
      final pAngle = tipAngle + deg * pi / 180;
      final pr     = r + rOff;
      final pPos   = Offset(cx + cos(pAngle) * pr, cy + sin(pAngle) * pr);

      // Each particle blinks independently: phase shifts sine wave
      final blink = (sin(tipAngle * 11.3 + phase) * 0.5 + 0.5);
      final alpha = (flicker * blink).clamp(0.0, 1.0);

      // Tiny corona per particle
      canvas.drawCircle(
        pPos, dotR + 1.2,
        Paint()
          ..color      = tipColor.withValues(alpha: alpha * 0.40)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
      );
      // Solid sparkle dot
      canvas.drawCircle(
        pPos, dotR,
        Paint()..color = _fuseCore.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress  != progress  ||
      old.isActive  != isActive  ||
      old.flicker   != flicker;
}

// ══════════════════════════════════════════════════════════════════
//  NAME TAG  — dark pill overlapping BOTTOM of avatar circle
//  Matches Jawaker: "New-UQD38Z" dark translucent bar at circle bottom
// ══════════════════════════════════════════════════════════════════

class _NameTag extends StatelessWidget {
  final String name;
  final Color teamColor;
  final bool isDealer;
  final bool isBuyer;
  final bool compact;

  const _NameTag({
    required this.name,
    required this.teamColor,
    required this.isDealer,
    required this.isBuyer,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 7,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 8.0 : 10.0,
                fontWeight: FontWeight.w700,
                fontFamily: 'Tajawal',
                height: 1.1,
              ),
            ),
          ),
          if (isDealer) ...[
            const SizedBox(width: 3),
            _MiniDealerChip(compact: compact),
          ],
          if (isBuyer && !isDealer) ...[
            const SizedBox(width: 2),
            Icon(Icons.star, color: const Color(0xFFFFD700), size: compact ? 8 : 10),
          ],
        ],
      ),
    );
  }
}

class _MiniDealerChip extends StatelessWidget {
  final bool compact;
  const _MiniDealerChip({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final sz = compact ? 12.0 : 15.0;
    return Container(
      width: sz, height: sz,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFD4AF37),
      ),
      alignment: Alignment.center,
      child: Text(
        'D',
        style: TextStyle(
          color: const Color(0xFF3D2518),
          fontSize: compact ? 6.5 : 8.0,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  SPEECH BUBBLE


// ══════════════════════════════════════════════════════════════════
//  TOP CARD FAN  (horizontal fan, seat 2)
// ══════════════════════════════════════════════════════════════════

class _TopCardFan extends StatelessWidget {
  final int count;
  final int seat;
  const _TopCardFan({required this.count, required this.seat});

  @override
  Widget build(BuildContext context) {
    const cardW = 36.0;
    final cardH = playingCardHeightForWidth(cardW);
    const maxFanWidth = 162.0;
    final overlap = count > 1
        ? ((maxFanWidth - cardW) / (count - 1)).clamp(6.0, 14.0)
        : 0.0;
    final fanWidth = cardW + (count - 1) * overlap;
    const maxAngle = 20.0;

    return SizedBox(
      width: fanWidth,
      height: cardH + 10,
      child: Stack(
        alignment: Alignment.bottomLeft,
        clipBehavior: Clip.none,
        children: [
          // ── Layer 1: Face-down card fan (on top) ──
          ...List.generate(count, (i) {
            final t = count > 1 ? i / (count - 1) : 0.5;
            final angleRad = (t - 0.5) * maxAngle * pi / 180;
            return Positioned(
              left: i * overlap,
              bottom: 0,
              child: Transform.rotate(
                angle: angleRad,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.medium,
                child: _FaceDownCard(width: cardW, height: cardH, seat: seat),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  SIDE CARD FAN  (seats 1 & 3)
// ══════════════════════════════════════════════════════════════════

class _SideCardFan extends StatelessWidget {
  final int count;
  final int seat;
  const _SideCardFan({required this.count, required this.seat});

  @override
  Widget build(BuildContext context) {
    const cardW = 32.0;
    final cardH = playingCardHeightForWidth(cardW);
    final overlap = count > 1 ? ((82.0 - cardW) / (count - 1)).clamp(4.0, 10.0) : 0.0;
    final fanWidth = cardW + (count - 1) * overlap;
    const maxAngle = 18.0;

    return SizedBox(
      width: fanWidth,
      height: cardH + 8,
      child: Stack(
        alignment: Alignment.bottomLeft,
        clipBehavior: Clip.none,
        children: [
          // ── Layer 1: Face-down card fan (on top) ──
          ...List.generate(count, (i) {
            final t = count > 1 ? i / (count - 1) : 0.5;
            final angleRad = (t - 0.5) * maxAngle * pi / 180;
            return Positioned(
              left: i * overlap,
              bottom: 0,
              child: Transform.rotate(
                angle: angleRad,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.medium,
                child: _FaceDownCard(width: cardW, height: cardH, seat: seat),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Single face-down card (Figma red/blue backs by team) ───────────

class _FaceDownCard extends StatelessWidget {
  final double width;
  final double height;
  final int seat;
  const _FaceDownCard({
    required this.width,
    required this.height,
    required this.seat,
  });

  @override
  Widget build(BuildContext context) {
    final path = PlayingCard.backAssetPath(cardBackForSeat(seat));
    final r = BorderRadius.circular(3.0);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final oversample = width < 56 ? 1.2 : width < 72 ? 1.12 : 1.0;
    final cacheW = (width * dpr * oversample).round().clamp(1, 8192);
    final cacheH = (height * dpr * oversample).round().clamp(1, 8192);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Image.asset(
          path,
          width: width,
          height: height,
          fit: BoxFit.cover,
          filterQuality: width < 72 ? FilterQuality.high : FilterQuality.medium,
          cacheWidth: cacheW,
          cacheHeight: cacheH,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: cardBackForSeat(seat) == CardBack.red
                ? const Color(0xFFB71C1C)
                : const Color(0xFF1E3A8A),
            child: const Center(
              child: Icon(Icons.style_outlined, size: 14, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CHAT BUBBLE OVERLAY
// ══════════════════════════════════════════════════════════════════

class _ChatBubblePainter extends CustomPainter {
  final bool tailOnLeft;
  _ChatBubblePainter({required this.tailOnLeft});

  @override
  void paint(Canvas canvas, Size size) {
    const tailW = 14.0;
    
    final ovalPath = Path();
    if (tailOnLeft) {
      ovalPath.addOval(Rect.fromLTWH(tailW, 0, size.width - tailW, size.height));
    } else {
      ovalPath.addOval(Rect.fromLTWH(0, 0, size.width - tailW, size.height));
    }

    final tailPath = Path();
    if (tailOnLeft) {
      // Tail pointing to bottom-left 
      tailPath.moveTo(size.width * 0.4, size.height * 0.5); // Upper base inside oval
      tailPath.lineTo(0, size.height * 0.9); // Point
      tailPath.lineTo(size.width * 0.4, size.height * 0.85); // Lower base inside oval
      tailPath.close();
    } else {
      // Tail pointing to bottom-right
      tailPath.moveTo(size.width * 0.6, size.height * 0.5);
      tailPath.lineTo(size.width, size.height * 0.9);
      tailPath.lineTo(size.width * 0.6, size.height * 0.85);
      tailPath.close();
    }

    final combinedPath = Path.combine(PathOperation.union, ovalPath, tailPath);

    final fillPaint = Paint()
      ..color = const Color(0xFF1F1A17)
      ..style = PaintingStyle.fill;
    canvas.drawPath(combinedPath, fillPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFE4C267).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(combinedPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpeechBubbleOverlay extends StatelessWidget {
  final PlayerBubble bubble;
  final bool tailOnLeft;

  const _SpeechBubbleOverlay({required this.bubble, required this.tailOnLeft});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final line = GameL10n.of(context).localizeBubble(bubble.text);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: anim,
        alignment: tailOnLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: CustomPaint(
        key: ValueKey(bubble.shownAt),
        painter: _ChatBubblePainter(tailOnLeft: tailOnLeft),
        child: Padding(
          padding: EdgeInsets.only(
            left: tailOnLeft ? 22 : 12,
            right: tailOnLeft ? 12 : 22,
            top: 10,
            bottom: 10,
          ),
          child: Text(
            line,
            style: const TextStyle(
              color: Color(0xFFE4C267),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  PROJECT CARDS RADIAL FAN
// ══════════════════════════════════════════════════════════════════

class ProjectCardFanRadial extends StatefulWidget {
  final List<CardModel> cards;
  final SeatOrientation orientation;

  const ProjectCardFanRadial({required this.cards, required this.orientation});

  @override
  State<ProjectCardFanRadial> createState() => _ProjectCardFanRadialState();
}

class _ProjectCardFanRadialState extends State<ProjectCardFanRadial> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void didUpdateWidget(ProjectCardFanRadial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cards.length != widget.cards.length && widget.cards.isNotEmpty) {
      _controller.forward(from: 0.0);
      _startHideTimer();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox();

    final scale = GameTableLayout.scale(context);
    final int n = widget.cards.length;
    final bool isRight = widget.orientation == SeatOrientation.right;
    final bool isLeft = widget.orientation == SeatOrientation.left;
    final bool isTop = widget.orientation == SeatOrientation.top;

    // Wide fan angle depending on how many cards are revealed
    final totalSweep = (n - 1) * 20.0;
    final startAngle = -totalSweep / 2;
    final sweepRadius = 65.0 * scale; // Distance from avatar center
    final pcSize = widget.orientation == SeatOrientation.bottom
        ? CardSize.medium
        : CardSize.small;

    return SizedBox(
      width: 1, // acts as a center anchor point for Stack
      height: 1,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center, // This ensures non-positioned wrappers anchor to center
        children: List.generate(n, (i) {
          // Calculate destination angle and offset
          final currentAngleDegrees = startAngle + (i * 20.0);
          double angleRad = currentAngleDegrees * pi / 180;
          double destX = 0;
          double destY = 0;

          if (isRight) {
             final finalAngle = pi + angleRad;
             destX = cos(finalAngle) * sweepRadius;
             destY = sin(finalAngle) * sweepRadius;
             angleRad = finalAngle - pi/2;
          } else if (isLeft) {
             final finalAngle = 0.0 + angleRad;
             destX = cos(finalAngle) * sweepRadius;
             destY = sin(finalAngle) * sweepRadius;
             angleRad = finalAngle - pi/2;
          } else if (isTop) {
             // Sweep DOWNWARDS (towards table center)
             final finalAngle = pi/2 + angleRad; 
             destX = cos(finalAngle) * sweepRadius;
             destY = sin(finalAngle) * sweepRadius;
             angleRad = finalAngle - pi/2;
          } else {
             // Sweep UPWARDS (towards table center) for Bottom Seat
             final finalAngle = -pi/2 + angleRad; 
             destX = cos(finalAngle) * sweepRadius;
             destY = sin(finalAngle) * sweepRadius;
             angleRad = finalAngle - pi/2;
          }

          // Create a staggered animation curve for this specific card
          final double delay = (i * 0.1).clamp(0.0, 0.5);
          final Animation<double> cardAnim = CurvedAnimation(
            parent: _controller,
            curve: Interval(
              delay,
              (delay + 0.5).clamp(0.0, 1.0),
              curve: Curves.easeOutBack,
            ),
          );

          // We use AnimatedBuilder but bind explicit offset values without Transform
          return AnimatedBuilder(
            animation: cardAnim,
            builder: (context, child) {
              final val = cardAnim.value;
              final sc = val.clamp(0.01, 1.0);
              return Positioned(
                left: destX * val - pcSize.width / 2,
                top: destY * val - pcSize.height / 2,
                child: Transform.scale(
                  scale: sc,
                  child: Transform.rotate(
                    angle: angleRad,
                    child: child,
                  ),
                ),
              );
            },
            child: PlayingCard(
              card: widget.cards[i],
              size: (widget.orientation == SeatOrientation.bottom) 
                  ? CardSize.medium 
                  : CardSize.small,
              faceUp: true,
            ),
          );
        }),
      ),
    );
  }
}

