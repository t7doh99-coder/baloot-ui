import 'package:flutter/material.dart';

/// Static VIP Background — Suit pattern painted ONCE, never repaints.
///
/// This is a const-friendly, zero-animation background with:
/// - Deep obsidian radial gradient
/// - Tiled card suit icons (♠♥♣♦) at very low opacity
/// - Painted once via RepaintBoundary — zero GPU cost after first frame
///
/// ```dart
/// Stack(children: [const VipStaticBackground(), /* content */])
/// ```
class VipStaticBackground extends StatelessWidget {
  const VipStaticBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return RepaintBoundary(
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            // ── Layer 1: Deep gradient ──
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

            // ── Layer 2: Static suit pattern (painted once) ──
            CustomPaint(
              size: size,
              painter: const _StaticSuitPainter(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints filled card suit icons at very low opacity.
/// Since it's const and has no changing state, Flutter paints it
/// once and caches it — zero repaints.
class _StaticSuitPainter extends CustomPainter {
  const _StaticSuitPainter();

  static const double _tileSize = 30.0;
  static const double _iconSize = 16.0;
  static const double _opacity = 0.035;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = (size.width / _tileSize).ceil() + 1;
    final rows = (size.height / _tileSize).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final suitIndex = (row + col) % 4;

        final staggerX = (row % 2 == 1) ? _tileSize / 2 : 0.0;
        final x = col * _tileSize + (_tileSize - _iconSize) / 2 + staggerX;
        final y = row * _tileSize + (_tileSize - _iconSize) / 2;

        // Red for hearts & diamonds, white for spades & clubs
        final Color suitColor;
        if (suitIndex == 1 || suitIndex == 3) {
          suitColor = const Color(0xFFE53935).withValues(alpha: _opacity);
        } else {
          suitColor = Colors.white.withValues(alpha: _opacity);
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

  void _drawSpade(Canvas canvas, Paint paint) {
    final path = Path();
    const s = _iconSize;
    const cx = s / 2;
    path.moveTo(cx, 0);
    path.cubicTo(cx + s * 0.55, s * 0.35, cx + s * 0.4, s * 0.75, cx, s * 0.6);
    path.cubicTo(cx - s * 0.4, s * 0.75, cx - s * 0.55, s * 0.35, cx, 0);
    path.close();
    canvas.drawPath(path, paint);

    final stemRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - s * 0.06, s * 0.55, s * 0.12, s * 0.3),
      const Radius.circular(1),
    );
    canvas.drawRRect(stemRect, paint);
  }

  void _drawHeart(Canvas canvas, Paint paint) {
    final path = Path();
    const s = _iconSize;
    const cx = s / 2;
    path.moveTo(cx, s * 0.85);
    path.cubicTo(cx + s * 0.55, s * 0.55, cx + s * 0.55, s * 0.05, cx, s * 0.3);
    path.cubicTo(cx - s * 0.55, s * 0.05, cx - s * 0.55, s * 0.55, cx, s * 0.85);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawClub(Canvas canvas, Paint paint) {
    const s = _iconSize;
    const cx = s / 2;
    const r = s * 0.19;
    canvas.drawCircle(const Offset(cx, s * 0.24), r, paint);
    canvas.drawCircle(const Offset(cx - s * 0.22, s * 0.48), r, paint);
    canvas.drawCircle(const Offset(cx + s * 0.22, s * 0.48), r, paint);

    final stemRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - s * 0.06, s * 0.5, s * 0.12, s * 0.35),
      const Radius.circular(1),
    );
    canvas.drawRRect(stemRect, paint);
  }

  void _drawDiamond(Canvas canvas, Paint paint) {
    final path = Path();
    const s = _iconSize;
    const cx = s / 2;
    const cy = s / 2;
    path.moveTo(cx, cy - s * 0.42);
    path.lineTo(cx + s * 0.3, cy);
    path.lineTo(cx, cy + s * 0.42);
    path.lineTo(cx - s * 0.3, cy);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StaticSuitPainter oldDelegate) => false;
}
