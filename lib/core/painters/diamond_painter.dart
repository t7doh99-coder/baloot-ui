import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Quilted diamond background — shared painter used across all screens.
//  Gives every screen the same premium card-table game feel.
// ─────────────────────────────────────────────────────────────────────────────
class DiamondOnlyPainter extends CustomPainter {
  // ── Quilted diamond config ──
  static const double _tileSquareSide = 80.0;
  static const double _tileCornerRadius = 12.0;
  static const double _pitchH = 124.0;
  static const double _pitchV = 124.0;

  // ── Colour palette — Sandstone ──
  static const Color _bgTop    = Color(0xFF2C2210);  // bgCard
  static const Color _bgBot    = Color(0xFF1E1808);  // bgCanvas
  static const Color _tileTop  = Color(0xFF392C14);  // bgElevated
  static const Color _tileMid  = Color(0xFF2C2210);  // bgCard
  static const Color _tileBot  = Color(0xFF1E1808);  // bgCanvas
  static const Color _tileShdw = Color(0x60080400);  // near-black warm shadow
  static const Color _tileDark = Color(0xFF141008);  // very dark sandy bevel
  static const Color _tileLight= Color(0xFF4A3818);  // muted sandy light bevel

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Gradient background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_bgTop, _bgBot],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Diamond grid
    final double vStep = _pitchV / 2;
    final int cols = (size.width  / _pitchH).ceil() + 2;
    final int rows = (size.height / vStep).ceil()   + 2;

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final double cx = col * _pitchH + (row.isOdd ? _pitchH / 2 : 0);
        final double cy = row * vStep;
        _drawOneDiamond(canvas, cx, cy);
      }
    }
  }

  void _drawOneDiamond(Canvas canvas, double cx, double cy) {
    final half = _tileSquareSide / 2;
    final r = Radius.circular(_tileCornerRadius);
    final rect = Rect.fromLTRB(-half, -half, half, half);
    final rrect = RRect.fromRectAndRadius(rect, r);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(math.pi / 4);

    // a) Shadow
    canvas.drawRRect(rrect.shift(const Offset(3, 3)),
        Paint()..color = _tileShdw);
    // b) Dark bevel
    canvas.drawRRect(rrect.shift(const Offset(2, 2)),
        Paint()..color = _tileDark);
    // c) Light bevel
    canvas.drawRRect(rrect.shift(const Offset(-1.5, -1.5)),
        Paint()..color = _tileLight);
    // d) Face gradient
    canvas.drawRRect(rrect, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [_tileTop, _tileMid, _tileBot],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect));
    // e) Inner border
    canvas.drawRRect(rrect, Paint()
      ..color = _tileDark.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    // f) Specular sheen
    canvas.drawRRect(rrect, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.45, 1.0],
        colors: const [Color(0x60FFFFFF), Color(0x10FFFFFF), Color(0x00FFFFFF)],
      ).createShader(rect));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
