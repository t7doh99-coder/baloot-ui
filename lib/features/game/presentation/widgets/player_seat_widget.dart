import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../game_provider.dart';

// ══════════════════════════════════════════════════════════════════
//  PLAYER SEAT WIDGET  (Step 4 — refined)
//
//  Card position layout (matching reference screenshot):
//
//  TOP seat (seat 2):
//    [ face-down card fan  ]   ← above avatar
//    [ speech bubble       ]
//    [ avatar circle       ]
//    [ name + level badge  ]
//
//  SIDE seats (seats 1 & 3):
//    [ face-down card fan  ]   ← above info
//    [ avatar + name pill  ]
//
//  BOTTOM seat (seat 0) — no seat widget; hand shown separately.
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
    final timerSecs = isActive && seat == 0 ? game.timerSeconds : null;

    final teamColor = (seat % 2 == 0)
        ? const Color(0xFF28802E)
        : const Color(0xFFE63946);

    if (orientation == SeatOrientation.left ||
        orientation == SeatOrientation.right) {
      return _SideSeat(
        cardCount: cardCount,
        name: name,
        isActive: isActive,
        isDealer: isDealer,
        isBuyer: isBuyer,
        teamColor: teamColor,
        bubble: bubble,
      );
    }

    // Top seat
    return _TopSeat(
      seat: seat,
      cardCount: cardCount,
      name: name,
      isActive: isActive,
      isDealer: isDealer,
      isBuyer: isBuyer,
      teamColor: teamColor,
      timerSecs: timerSecs,
      bubble: bubble,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TOP SEAT  (seat 2 — opponent directly across)
// ══════════════════════════════════════════════════════════════════

class _TopSeat extends StatelessWidget {
  final int seat;
  final int cardCount;
  final String name;
  final bool isActive;
  final bool isDealer;
  final bool isBuyer;
  final Color teamColor;
  final int? timerSecs;
  final PlayerBubble? bubble;

  const _TopSeat({
    required this.seat,
    required this.cardCount,
    required this.name,
    required this.isActive,
    required this.isDealer,
    required this.isBuyer,
    required this.teamColor,
    required this.timerSecs,
    required this.bubble,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Face-down card fan (above everything)
        if (cardCount > 0) _TopCardFan(count: cardCount, teamColor: teamColor),

        const SizedBox(height: 4),

        // 2. Speech bubble
        _SpeechBubble(bubble: bubble, teamColor: teamColor),

        // 3. Avatar with timer ring
        _AvatarCard(
          name: name,
          isActive: isActive,
          isDealer: isDealer,
          isBuyer: isBuyer,
          teamColor: teamColor,
          timerSecs: timerSecs,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  SIDE SEAT  (seats 1 & 3 — left / right opponents)
// ══════════════════════════════════════════════════════════════════

class _SideSeat extends StatelessWidget {
  final int cardCount;
  final String name;
  final bool isActive;
  final bool isDealer;
  final bool isBuyer;
  final Color teamColor;
  final PlayerBubble? bubble;

  const _SideSeat({
    required this.cardCount,
    required this.name,
    required this.isActive,
    required this.isDealer,
    required this.isBuyer,
    required this.teamColor,
    required this.bubble,
  });

  // Strictly constrained width for the whole side seat
  static const double _colW = 64.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _colW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Face-down card fan
          if (cardCount > 0)
            _SideCardFan(count: cardCount, teamColor: teamColor),

          const SizedBox(height: 4),

          // 2. Speech bubble (compact, centred)
          if (bubble != null)
            _SpeechBubble(bubble: bubble, teamColor: teamColor),

          // 3. Vertical info pill — avatar + name + badge, all centred
          _SideInfoPill(
            name: name,
            isActive: isActive,
            isDealer: isDealer,
            isBuyer: isBuyer,
            teamColor: teamColor,
            width: _colW,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  SIDE INFO PILL  (strict width, vertical layout)
// ══════════════════════════════════════════════════════════════════

class _SideInfoPill extends StatelessWidget {
  final String name;
  final bool isActive;
  final bool isDealer;
  final bool isBuyer;
  final Color teamColor;
  final double width;

  const _SideInfoPill({
    required this.name,
    required this.isActive,
    required this.isDealer,
    required this.isBuyer,
    required this.teamColor,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: isActive ? 0.68 : 0.50),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? AppColors.goldAccent.withValues(alpha: 0.85)
              : teamColor.withValues(alpha: 0.45),
          width: isActive ? 1.8 : 1.1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: AppColors.goldAccent.withValues(alpha: 0.25),
              blurRadius: 10,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar circle
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: teamColor.withValues(alpha: isActive ? 0.25 : 0.12),
              border: Border.all(
                color: isActive
                    ? AppColors.goldAccent.withValues(alpha: 0.8)
                    : teamColor.withValues(alpha: 0.5),
                width: isActive ? 2.0 : 1.2,
              ),
            ),
            child: Icon(
              Icons.person,
              color: teamColor.withValues(alpha: 0.85),
              size: 16,
            ),
          ),

          const SizedBox(height: 3),

          // Name
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.90),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              fontFamily: 'Tajawal',
              height: 1.1,
            ),
          ),

          const SizedBox(height: 3),

          // Level / dealer row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: teamColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: teamColor.withValues(alpha: 0.4), width: 0.7),
                ),
                child: Text(
                  'Mid',
                  style: TextStyle(
                    color: teamColor.withValues(alpha: 0.9),
                    fontSize: 7,
                    fontFamily: 'Tajawal',
                    height: 1.2,
                  ),
                ),
              ),
              if (isDealer) ...[
                const SizedBox(width: 2),
                _DealerChip(compact: true),
              ],
              if (isBuyer && !isDealer) ...[
                const SizedBox(width: 2),
                Icon(Icons.star, color: teamColor, size: 9),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  AVATAR CARD  (avatar circle + name + level badge)
// ══════════════════════════════════════════════════════════════════

class _AvatarCard extends StatelessWidget {
  final String name;
  final bool isActive;
  final bool isDealer;
  final bool isBuyer;
  final Color teamColor;
  final int? timerSecs;
  final bool compact;

  const _AvatarCard({
    required this.name,
    required this.isActive,
    required this.isDealer,
    required this.isBuyer,
    required this.teamColor,
    required this.timerSecs,
    this.compact = false,
  });

  static const _levels = ['Beginner', 'Mid', 'Advanced', 'Pro', 'Expert'];

  @override
  Widget build(BuildContext context) {
    final avatarR = compact ? 16.0 : 20.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 7, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: isActive ? 0.72 : 0.52),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isActive
              ? AppColors.goldAccent.withValues(alpha: 0.85)
              : teamColor.withValues(alpha: 0.45),
          width: isActive ? 1.8 : 1.1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: AppColors.goldAccent.withValues(alpha: 0.28),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with optional timer ring
          _TimerAvatar(
            isActive: isActive,
            teamColor: teamColor,
            timerSecs: timerSecs,
            avatarR: avatarR,
          ),
          const SizedBox(width: 5),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: compact ? 9 : 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Tajawal',
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LevelBadge(level: _levels[0], teamColor: teamColor, compact: compact),
                  if (isDealer) ...[
                    const SizedBox(width: 3),
                    _DealerChip(compact: compact),
                  ],
                  if (isBuyer && !isDealer) ...[
                    const SizedBox(width: 3),
                    Icon(Icons.star, color: teamColor, size: compact ? 9 : 11),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TIMER AVATAR
// ══════════════════════════════════════════════════════════════════

class _TimerAvatar extends StatelessWidget {
  final bool isActive;
  final Color teamColor;
  final int? timerSecs;
  final double avatarR;

  const _TimerAvatar({
    required this.isActive,
    required this.teamColor,
    required this.timerSecs,
    required this.avatarR,
  });

  @override
  Widget build(BuildContext context) {
    final ring = avatarR * 2 + 6;
    return SizedBox(
      width: ring,
      height: ring,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isActive)
            CustomPaint(
              size: Size(ring, ring),
              painter: _TimerRingPainter(
                progress: timerSecs != null ? timerSecs! / 10.0 : 1.0,
                ringColor: timerSecs != null && timerSecs! <= 3
                    ? const Color(0xFFE63946)
                    : AppColors.goldAccent,
              ),
            ),
          Container(
            width: avatarR * 2,
            height: avatarR * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: teamColor.withValues(alpha: 0.18),
              border: Border.all(
                color: isActive
                    ? AppColors.goldAccent.withValues(alpha: 0.7)
                    : teamColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(Icons.person,
                color: teamColor.withValues(alpha: 0.85),
                size: avatarR),
          ),
          if (isActive && timerSecs != null)
            Positioned(
              bottom: 1, right: 1,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: timerSecs! <= 3
                      ? const Color(0xFFE63946)
                      : AppColors.goldAccent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$timerSecs',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 6.5,
                    fontWeight: FontWeight.w900,
                    height: 1,
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
//  TIMER RING PAINTER
// ══════════════════════════════════════════════════════════════════

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  const _TimerRingPainter({required this.progress, required this.ringColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = min(cx, cy) - 1.5;

    canvas.drawCircle(Offset(cx, cy), r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0);

    if (progress <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -pi / 2, 2 * pi * progress, false,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TimerRingPainter old) =>
      old.progress != progress || old.ringColor != ringColor;
}

// ══════════════════════════════════════════════════════════════════
//  LEVEL BADGE
// ══════════════════════════════════════════════════════════════════

class _LevelBadge extends StatelessWidget {
  final String level;
  final Color teamColor;
  final bool compact;
  const _LevelBadge(
      {required this.level, required this.teamColor, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 5, vertical: compact ? 1 : 1),
      decoration: BoxDecoration(
        color: teamColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: teamColor.withValues(alpha: 0.45), width: 0.8),
      ),
      child: Text(
        level,
        style: TextStyle(
          color: teamColor.withValues(alpha: 0.9),
          fontSize: compact ? 7 : 8,
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  DEALER CHIP
// ══════════════════════════════════════════════════════════════════

class _DealerChip extends StatelessWidget {
  final bool compact;
  const _DealerChip({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 14.0 : 18.0;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFFFE066)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: AppColors.goldAccent.withValues(alpha: 0.4),
              blurRadius: 4),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'د',
        style: TextStyle(
            color: const Color(0xFF3D2518),
            fontSize: compact ? 7 : 9,
            fontWeight: FontWeight.w900,
            height: 1),
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
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
      child: bubble == null
          ? const SizedBox(key: ValueKey('empty'))
          : Container(
              key: ValueKey(bubble!.shownAt),
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: teamColor.withValues(alpha: 0.6), width: 1),
              ),
              child: Text(
                bubble!.text,
                style: TextStyle(
                  color: teamColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Tajawal',
                  height: 1,
                ),
              ),
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TOP CARD FAN  (horizontal fan for seat 2)
//
//  Cards spread in a gentle arc — widest card in center,
//  slightly fanned outward like a hand held face-down.
// ══════════════════════════════════════════════════════════════════

class _TopCardFan extends StatelessWidget {
  final int count;
  final Color teamColor;
  const _TopCardFan({required this.count, required this.teamColor});

  @override
  Widget build(BuildContext context) {
    const cardW = 26.0;
    const cardH = 37.0;
    const maxFanWidth = 130.0;
    final overlap = count > 1
        ? ((maxFanWidth - cardW) / (count - 1)).clamp(6.0, 14.0)
        : 0.0;
    final fanWidth = cardW + (count - 1) * overlap;
    const maxAngle = 20.0; // degrees total spread

    return SizedBox(
      width: fanWidth,
      height: cardH + 10, // room for arc rotation
      child: Stack(
        alignment: Alignment.bottomLeft,
        clipBehavior: Clip.none,
        children: List.generate(count, (i) {
          final t = count > 1 ? i / (count - 1) : 0.5;
          final angleDeg = (t - 0.5) * maxAngle;
          final angleRad = angleDeg * pi / 180;
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
//  SIDE CARD FAN  (compact fan for seats 1 & 3)
//
//  Fits within ~68px column width. Cards stacked with a small
//  diagonal offset to show depth.
// ══════════════════════════════════════════════════════════════════

class _SideCardFan extends StatelessWidget {
  final int count;
  final Color teamColor;
  const _SideCardFan({required this.count, required this.teamColor});

  @override
  Widget build(BuildContext context) {
    const cardW = 24.0;
    const cardH = 34.0;
    // Fit all cards in 64px width
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
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.35), width: 0.7),
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
