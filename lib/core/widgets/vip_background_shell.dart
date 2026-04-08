import 'package:flutter/material.dart';

/// VIP Background Shell — Premium tiled suit pattern with ripple wave effect.
///
/// Features:
/// - Deep obsidian/navy gradient background
/// - Tiled filled suit icons (♠♥♣♦) in white & red
/// - Ripple wave effect sweeping top → bottom continuously
///
/// ```dart
/// Stack(children: [const VipBackgroundShell(), /* content */])
/// ```
class VipBackgroundShell extends StatefulWidget {
  const VipBackgroundShell({super.key});

  @override
  State<VipBackgroundShell> createState() => _VipBackgroundShellState();
}

class _VipBackgroundShellState extends State<VipBackgroundShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      // LOGIC_PLUG_IN: Adjust ripple duration to control wave speed
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          // ── Layer 1: Deep gradient background ──
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF1C1F26),
                  Color(0xFF0A0C10),
                  Color(0xFF050608),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // ── Layer 2: Suit pattern with animated ripple ──
          AnimatedBuilder(
            animation: _rippleController,
            builder: (_, __) {
              return CustomPaint(
                size: size,
                painter: _RippleSuitPainter(
                  rippleProgress: _rippleController.value,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Paints filled card suit icons with a ripple wave sweeping top → bottom.
/// Icons glow brighter as the wave passes over them.
class _RippleSuitPainter extends CustomPainter {
  final double rippleProgress; // 0.0 → 1.0

  // LOGIC_PLUG_IN: Adjust these for pattern density & ripple look
  static const double _tileSize = 28.0;       // Denser grid (more clustered)
  static const double _iconSize = 18.0;       // Larger icons
  static const double _baseOpacity = 0.04;    // idle icon opacity
  static const double _peakOpacity = 0.18;    // icon opacity at wave peak
  static const double _rippleWidth = 0.20;    // width of the ripple band (0→1)

  _RippleSuitPainter({required this.rippleProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final cols = (size.width / _tileSize).ceil() + 1;
    final rows = (size.height / _tileSize).ceil() + 1;

    // Ripple center Y as fraction of screen height
    // Extend range so ripple fully exits the screen
    final rippleY = -_rippleWidth + rippleProgress * (1.0 + 2 * _rippleWidth);

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final suitIndex = (row + col) % 4;

        // Position
        final staggerX = (row % 2 == 1) ? _tileSize / 2 : 0.0;
        final x = col * _tileSize + (_tileSize - _iconSize) / 2 + staggerX;
        final y = row * _tileSize + (_tileSize - _iconSize) / 2;

        // Calculate distance from ripple center (normalized 0→1 of screen)
        final iconYNorm = y / size.height;
        final dist = (iconYNorm - rippleY).abs();

        // Opacity based on distance from ripple wave
        double opacity;
        if (dist < _rippleWidth) {
          // Inside the ripple band — interpolate to peak
          final t = 1.0 - (dist / _rippleWidth);
          // Smooth bell curve
          opacity = _baseOpacity + (_peakOpacity - _baseOpacity) * t * t;
        } else {
          opacity = _baseOpacity;
        }

        // Colors: red for hearts & diamonds, white for spades & clubs
        final Color suitColor;
        if (suitIndex == 1 || suitIndex == 3) {
          // Hearts, Diamonds → red
          suitColor = const Color(0xFFE53935).withValues(alpha: opacity);
        } else {
          // Spades, Clubs → white
          suitColor = Colors.white.withValues(alpha: opacity);
        }

        final paint = Paint()
          ..style = PaintingStyle.fill
          ..color = suitColor;

        canvas.save();
        canvas.translate(x, y);

        switch (suitIndex) {
          case 0:
            _drawSpade(canvas, paint);
            break;
          case 1:
            _drawHeart(canvas, paint);
            break;
          case 2:
            _drawClub(canvas, paint);
            break;
          case 3:
            _drawDiamond(canvas, paint);
            break;
        }

        canvas.restore();
      }
    }
  }

  /// ♠ Spade — filled
  void _drawSpade(Canvas canvas, Paint paint) {
    final path = Path();
    final s = _iconSize;
    final cx = s / 2;

    // Top point → body
    path.moveTo(cx, 0);
    path.cubicTo(cx + s * 0.55, s * 0.35, cx + s * 0.4, s * 0.75, cx, s * 0.6);
    path.cubicTo(cx - s * 0.4, s * 0.75, cx - s * 0.55, s * 0.35, cx, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Stem
    final stemRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - s * 0.06, s * 0.55, s * 0.12, s * 0.3),
      const Radius.circular(1),
    );
    canvas.drawRRect(stemRect, paint);
  }

  /// ♥ Heart — filled
  void _drawHeart(Canvas canvas, Paint paint) {
    final path = Path();
    final s = _iconSize;
    final cx = s / 2;

    path.moveTo(cx, s * 0.85);
    // Right lobe
    path.cubicTo(cx + s * 0.55, s * 0.55, cx + s * 0.55, s * 0.05, cx, s * 0.3);
    // Left lobe
    path.cubicTo(cx - s * 0.55, s * 0.05, cx - s * 0.55, s * 0.55, cx, s * 0.85);
    path.close();

    canvas.drawPath(path, paint);
  }

  /// ♣ Club — filled
  void _drawClub(Canvas canvas, Paint paint) {
    final s = _iconSize;
    final cx = s / 2;
    final r = s * 0.19;

    // Three lobes
    canvas.drawCircle(Offset(cx, s * 0.24), r, paint);
    canvas.drawCircle(Offset(cx - s * 0.22, s * 0.48), r, paint);
    canvas.drawCircle(Offset(cx + s * 0.22, s * 0.48), r, paint);

    // Stem
    final stemRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - s * 0.06, s * 0.5, s * 0.12, s * 0.35),
      const Radius.circular(1),
    );
    canvas.drawRRect(stemRect, paint);
  }

  /// ♦ Diamond — filled
  void _drawDiamond(Canvas canvas, Paint paint) {
    final path = Path();
    final s = _iconSize;
    final cx = s / 2;
    final cy = s / 2;

    path.moveTo(cx, cy - s * 0.42);
    path.lineTo(cx + s * 0.3, cy);
    path.lineTo(cx, cy + s * 0.42);
    path.lineTo(cx - s * 0.3, cy);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RippleSuitPainter oldDelegate) {
    return oldDelegate.rippleProgress != rippleProgress;
  }
}
