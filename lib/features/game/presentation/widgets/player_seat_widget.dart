import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:provider/provider.dart';
import '../game_provider.dart';

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

  const _TopSeat({
    required this.seat,
    required this.cardCount,
    required this.name,
    required this.isActive,
    required this.isDealer,
    required this.isBuyer,
    required this.teamColor,
    required this.bubble,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (cardCount > 0)
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _TopCardFan(count: cardCount, teamColor: teamColor),
            ),
          ),
        const SizedBox(height: 4),
        Center(child: _SpeechBubble(bubble: bubble, teamColor: teamColor)),
        const SizedBox(height: 2),
        Center(
          child: PlayerAvatarRing(
            seatIndex: seat,
            name: name,
            isActive: isActive,
            isDealer: isDealer,
            isBuyer: isBuyer,
            teamColor: teamColor,
            avatarDiameter: 40.0,
          ),
        ),
      ],
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

  const _SideSeat({
    required this.seat,
    required this.cardCount,
    required this.name,
    required this.isActive,
    required this.isDealer,
    required this.isBuyer,
    required this.teamColor,
    required this.bubble,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (cardCount > 0)
          _SideCardFan(count: cardCount, teamColor: teamColor),
        const SizedBox(height: 4),
        _SpeechBubble(bubble: bubble, teamColor: teamColor),
        const SizedBox(height: 2),
        PlayerAvatarRing(
          seatIndex: seat,
          name: name,
          isActive: isActive,
          isDealer: isDealer,
          isBuyer: isBuyer,
          teamColor: teamColor,
          avatarDiameter: 34.0,
        ),
      ],
    );
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

    const nameImages = [
      'assets/images/avatars/Screenshot 2026-04-16 194030.png',
      'assets/images/avatars/Screenshot 2026-04-16 194232.png',
      'assets/images/avatars/Screenshot 2026-04-16 194821.png',
      'assets/images/avatars/bc9fd4bd-de9b-4555-976c-8360576c6708.jpg',
    ];
    // Map seat index directly to ensure 4 different images for 4 players
    final avatarImagePath = nameImages[widget.seatIndex % 4];

    return AnimatedBuilder(
      animation: _flickerCtrl,
      builder: (context, _) {
        final flicker = _flickerAnim.value;
        // Stack: ring canvas + dark sphere + name tag overlapping bottom
        return SizedBox(
          width: totalSz,
          // Extra height for the name tag that overlaps bottom
          height: totalSz + 16,
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

              // ── Name tag overlapping bottom of ring ─────────────
              // Positioned so it sits at the bottom edge of the circle
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

class _SpeechBubble extends StatelessWidget {
  final PlayerBubble? bubble;
  final Color teamColor;
  const _SpeechBubble({required this.bubble, required this.teamColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => ScaleTransition(
          scale: anim, child: FadeTransition(opacity: anim, child: child)),
      child: bubble == null
          ? const SizedBox(key: ValueKey('empty'))
          : LayoutBuilder(
              key: ValueKey(bubble!.shownAt),
              builder: (context, c) {
                final maxW = c.maxWidth.isFinite ? c.maxWidth : 200.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  constraints: BoxConstraints(maxWidth: maxW),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: teamColor.withValues(alpha: 0.6), width: 1),
                  ),
                  child: Text(
                    bubble!.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: teamColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Tajawal',
                      height: 1.2,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TOP CARD FAN  (horizontal fan, seat 2)
// ══════════════════════════════════════════════════════════════════

class _TopCardFan extends StatelessWidget {
  final int count;
  final Color teamColor;
  const _TopCardFan({required this.count, required this.teamColor});

  @override
  Widget build(BuildContext context) {
    const cardW       = 26.0;
    const cardH       = 37.0;
    const maxFanWidth = 130.0;
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
        children: List.generate(count, (i) {
          final t = count > 1 ? i / (count - 1) : 0.5;
          final angleRad = (t - 0.5) * maxAngle * pi / 180;
          return Positioned(
            left: i * overlap,
            bottom: 0,
            child: Transform.rotate(
              angle: angleRad,
              alignment: Alignment.bottomCenter,
              child: _FaceDownCard(
                  width: cardW, height: cardH, teamColor: teamColor),
            ),
          );
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  SIDE CARD FAN  (seats 1 & 3)
// ══════════════════════════════════════════════════════════════════

class _SideCardFan extends StatelessWidget {
  final int count;
  final Color teamColor;
  const _SideCardFan({required this.count, required this.teamColor});

  @override
  Widget build(BuildContext context) {
    const cardW  = 24.0;
    const cardH  = 34.0;
    final overlap =
        count > 1 ? ((64.0 - cardW) / (count - 1)).clamp(4.0, 10.0) : 0.0;
    final fanWidth = cardW + (count - 1) * overlap;
    const maxAngle = 18.0;

    return SizedBox(
      width: fanWidth,
      height: cardH + 8,
      child: Stack(
        alignment: Alignment.bottomLeft,
        clipBehavior: Clip.none,
        children: List.generate(count, (i) {
          final t = count > 1 ? i / (count - 1) : 0.5;
          final angleRad = (t - 0.5) * maxAngle * pi / 180;
          return Positioned(
            left: i * overlap,
            bottom: 0,
            child: Transform.rotate(
              angle: angleRad,
              alignment: Alignment.bottomCenter,
              child: _FaceDownCard(
                  width: cardW, height: cardH, teamColor: teamColor),
            ),
          );
        }),
      ),
    );
  }
}

// ── Single face-down card ──────────────────────────────────────────

class _FaceDownCard extends StatelessWidget {
  final double width;
  final double height;
  final Color teamColor;
  const _FaceDownCard(
      {required this.width, required this.height, required this.teamColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2878),
        borderRadius: BorderRadius.circular(3),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.35), width: 0.7),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 3,
              offset: const Offset(1, 1)),
        ],
      ),
      child: Center(
        child: Container(
          width: width * 0.55,
          height: height * 0.7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1.5),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.15), width: 0.5),
          ),
        ),
      ),
    );
  }
}
