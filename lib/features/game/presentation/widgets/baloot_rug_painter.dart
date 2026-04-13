import 'dart:math';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════
//  BALOOT RUG PAINTER
//
//  Faithful Flutter CustomPainter conversion of the Figma-designed
//  Arabic floor rug (App.tsx  800×1100 SVG).
//
//  Design elements (top → bottom):
//   • Top fringe
//   • Red outer border + corner spandrels
//   • Cream woven field with leaf branches along edges
//   • Center medallion: diamond bands, radiating triangles, 8-point star
//   • Scattered field dots & diamonds
//   • Bottom fringe
// ══════════════════════════════════════════════════════════════════

class BalootRugPainter extends CustomPainter {
  const BalootRugPainter();

  // ── Palette (matches Figma constants) ──────────────────────────
  static const _cream     = Color(0xFFFAF3E0);
  static const _red       = Color(0xFFE63946);
  static const _darkRed   = Color(0xFFA02020);
  static const _blue      = Color(0xFF2080D0);
  static const _skyBlue   = Color(0xFF30C8D8);
  static const _teal      = Color(0xFF28B0A0);
  static const _yellow    = Color(0xFFF0C820);
  static const _orange    = Color(0xFFD88030);
  static const _brown     = Color(0xFF5C3A1E);
  static const _darkBrown = Color(0xFF3D2518);
  static const _green     = Color(0xFF28802E);
  static const _darkGreen = Color(0xFF1A5028);
  static const _navy      = Color(0xFF1E2878);
  static const _black     = Color(0xFF222222);
  static const _pink      = Color(0xFFE87080);

  static const _diamondPalette = [
    _red, _blue, _yellow, _teal, _orange, _green,
    _brown, _navy, _darkRed, _skyBlue, _pink, _darkGreen,
  ];

  // Original SVG dimensions
  static const double _svgW = 800;
  static const double _svgH = 1100;

  @override
  void paint(Canvas canvas, Size size) {
    // Scale factors so the painter fills whatever size it receives
    final sx = size.width  / _svgW;
    final sy = size.height / _svgH;

    canvas.save();
    canvas.scale(sx, sy);

    // Paint in SVG layer order
    _paintTopFringe(canvas);
    _paintRugBody(canvas);
    _paintOuterBorder(canvas);
    _paintInnerField(canvas);
    _paintCornerSpandrels(canvas);
    _paintEdgeLeafBranches(canvas);
    _paintOuterCircleAndDiamondBand(canvas);
    _paintRadiatingTriangles(canvas);
    _paintInnerCirclesAndBand(canvas);
    _paintCenterStar(canvas);
    _paintTealSquaresAroundMedallion(canvas);
    _paintScatteredFieldDots(canvas);
    _paintBorderDiamondDecorations(canvas);
    _paintBottomFringe(canvas);

    canvas.restore();
  }

  // ── Helpers ────────────────────────────────────────────────────

  Paint _fill(Color c, [double alpha = 1.0]) =>
      Paint()..color = alpha < 1.0 ? c.withValues(alpha: alpha) : c
             ..style = PaintingStyle.fill;

  Paint _stroke(Color c, double w) =>
      Paint()..color = c
             ..style = PaintingStyle.stroke
             ..strokeWidth = w;

  /// Diamond (rotated square) centered at (cx, cy) with half-side `half`
  void _drawDiamond(Canvas canvas, double cx, double cy, double half, Paint p) {
    final path = Path()
      ..moveTo(cx,        cy - half)
      ..lineTo(cx + half, cy)
      ..lineTo(cx,        cy + half)
      ..lineTo(cx - half, cy)
      ..close();
    canvas.drawPath(path, p);
  }

  /// Triangle: 3 points
  void _drawTri(Canvas canvas, List<Offset> pts, Paint p) {
    final path = Path()
      ..moveTo(pts[0].dx, pts[0].dy)
      ..lineTo(pts[1].dx, pts[1].dy)
      ..lineTo(pts[2].dx, pts[2].dy)
      ..close();
    canvas.drawPath(path, p);
  }

  /// Leaf/feather branch (matches Figma `Branch` component).
  /// Draws at local (0,0) pointing up, then caller should save/translate/rotate.
  void _drawBranchAt(Canvas canvas, double x, double y, double angleDeg,
      double scale) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angleDeg * pi / 180);
    canvas.scale(scale);

    final p = _stroke(_darkBrown, 1.2);
    // Stem
    canvas.drawLine(Offset.zero, const Offset(0, -32), p);
    // Leaves at y = -5, -10, -15, -20, -25
    final leafP = _stroke(_darkBrown, 0.9);
    for (int i = 0; i < 5; i++) {
      final dy = -(5.0 + i * 5);
      final lx = -(7.0 - i);
      final rx =  (7.0 - i);
      canvas.drawLine(Offset(0, dy), Offset(lx, dy - 4), leafP);
      canvas.drawLine(Offset(0, dy), Offset(rx, dy - 4), leafP);
    }

    canvas.restore();
  }

  /// Multicolored diamond ring (matches Figma `DiamondBand`).
  void _drawDiamondBand(Canvas canvas, double cx, double cy, double r,
      int count, double size) {
    final half = size / 2;
    for (int i = 0; i < count; i++) {
      final a   = (i * 2 * pi) / count;
      final x   = cx + cos(a) * r;
      final y   = cy + sin(a) * r;
      final col = _diamondPalette[i % _diamondPalette.length];
      _drawDiamond(canvas, x, y, half, _fill(col));
      _drawDiamond(canvas, x, y, half, _stroke(_darkBrown, 0.5));
    }
  }

  // ── Fringe ─────────────────────────────────────────────────────

  void _paintTopFringe(Canvas canvas) {
    final p = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD8C8A0), Color(0xFFA08860)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(0, 0, 8, 28))
      ..style = PaintingStyle.fill;
    p.color = p.color.withValues(alpha: 0.85);

    for (int i = 0; i < 100; i++) {
      final px = i * 8.0 + 4;
      final paint = Paint()
        ..color = const Color(0xFFD8C8A0).withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(px, 0, 1.6, 28), paint);
    }
  }

  void _paintBottomFringe(Canvas canvas) {
    for (int i = 0; i < 100; i++) {
      final px = i * 8.0 + 4;
      final paint = Paint()
        ..color = const Color(0xFFA08860).withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(px, 1072, 1.6, 28), paint);
    }
  }

  // ── Rug Body ───────────────────────────────────────────────────

  void _paintRugBody(Canvas canvas) {
    // Cream base
    canvas.drawRect(
        Rect.fromLTWH(0, 28, _svgW, 1044), _fill(_cream));

    // Subtle weave crosshatch
    final wp = _stroke(const Color(0xFFEDE5D0), 0.3)
      ..color = const Color(0xFFEDE5D0).withValues(alpha: 0.4);
    const step = 3.0;
    for (double y = 28; y < 1072; y += step) {
      canvas.drawLine(Offset(0, y), Offset(_svgW, y), wp);
    }
    final wp2 = _stroke(const Color(0xFFEDE5D0), 0.3)
      ..color = const Color(0xFFEDE5D0).withValues(alpha: 0.3);
    for (double x = 0; x < _svgW; x += step) {
      canvas.drawLine(Offset(x, 28), Offset(x, 1072), wp2);
    }
  }

  // ── Outer Red Border ───────────────────────────────────────────

  void _paintOuterBorder(Canvas canvas) {
    final rp = _fill(_red);
    // Top band
    canvas.drawRect(Rect.fromLTWH(0, 28, _svgW, 47), rp);
    // Bottom band
    canvas.drawRect(Rect.fromLTWH(0, 1025, _svgW, 47), rp);
    // Left band
    canvas.drawRect(Rect.fromLTWH(0, 28, 40, 1044), rp);
    // Right band
    canvas.drawRect(Rect.fromLTWH(760, 28, 40, 1044), rp);

    // Yellow inner line
    canvas.drawRect(
      Rect.fromLTWH(40, 75, 720, 950),
      _stroke(_yellow, 5),
    );
    // Dark brown line
    canvas.drawRect(
      Rect.fromLTWH(48, 83, 704, 934),
      _stroke(_darkBrown, 2),
    );

    // Green corner triangles
    final greenP = _fill(_darkGreen);
    _drawTri(canvas, [const Offset(0,28),   const Offset(40,28),  const Offset(0,68)],   greenP);
    _drawTri(canvas, [const Offset(800,28), const Offset(760,28), const Offset(800,68)], greenP);
    _drawTri(canvas, [const Offset(0,1072), const Offset(40,1072),const Offset(0,1032)], greenP);
    _drawTri(canvas, [const Offset(800,1072),const Offset(760,1072),const Offset(800,1032)],greenP);

    // Blue rectangles in border corners
    final blueP = _fill(_blue);
    canvas.drawRect(Rect.fromLTWH(8,   38,   22, 18), blueP);
    canvas.drawRect(Rect.fromLTWH(770, 38,   22, 18), blueP);
    canvas.drawRect(Rect.fromLTWH(8,   1044, 22, 18), blueP);
    canvas.drawRect(Rect.fromLTWH(770, 1044, 22, 18), blueP);
  }

  // ── Inner Field ────────────────────────────────────────────────

  void _paintInnerField(Canvas canvas) {
    canvas.drawRect(
        Rect.fromLTWH(52, 87, 696, 926), _fill(_cream));
    canvas.drawRect(
        Rect.fromLTWH(52, 87, 696, 926), _stroke(_darkBrown, 1));
  }

  // ── Corner Spandrels ───────────────────────────────────────────

  void _paintCornerSpandrels(Canvas canvas) {
    final corners = [
      [1.0, 1.0,   52.0,  87.0],
      [-1.0, 1.0,  748.0, 87.0],
      [1.0, -1.0,  52.0,  1013.0],
      [-1.0, -1.0, 748.0, 1013.0],
    ];

    for (final c in corners) {
      final ox = c[2], oy = c[3];
      final sx = c[0], sy = c[1];

      canvas.save();
      canvas.translate(ox, oy);
      canvas.scale(sx, sy);

      _drawTri(canvas,[Offset.zero, const Offset(120,0), const Offset(0,120)], _fill(_red, 0.85));
      _drawTri(canvas,[const Offset(5,5), const Offset(90,5), const Offset(5,90)], _fill(_yellow, 0.7));
      _drawTri(canvas,[const Offset(10,10),const Offset(80,10),const Offset(10,80)], _stroke(_darkBrown,1.5));
      _drawTri(canvas,[const Offset(15,15),const Offset(65,15),const Offset(15,65)], _fill(_red, 0.6));
      _drawTri(canvas,[const Offset(20,20),const Offset(50,20),const Offset(20,50)], _fill(_darkBrown, 0.5));

      canvas.drawRect(Rect.fromLTWH(70, 8,  12, 12), _fill(_blue));
      canvas.drawRect(Rect.fromLTWH(70, 8,  12, 12), _stroke(_darkBrown, 0.5));
      canvas.drawRect(Rect.fromLTWH(8,  70, 12, 12), _fill(_blue));
      canvas.drawRect(Rect.fromLTWH(8,  70, 12, 12), _stroke(_darkBrown, 0.5));

      // Dots
      canvas.drawCircle(const Offset(95, 25), 2, _fill(_black));
      canvas.drawCircle(const Offset(25, 95), 2, _fill(_black));
      canvas.drawCircle(const Offset(100,35), 1.5, _fill(_yellow));
      canvas.drawCircle(const Offset(35,100), 1.5, _fill(_yellow));

      // Leaf branch in corner
      _drawBranchAt(canvas, 85, 85, -135, 0.6);

      canvas.restore();
    }
  }

  // ── Edge Leaf Branches ─────────────────────────────────────────

  void _paintEdgeLeafBranches(Canvas canvas) {
    const cx = _svgW / 2;
    const cy = _svgH / 2;

    // Radiating from center
    for (int i = 0; i < 16; i++) {
      final a   = (i * 2 * pi) / 16;
      final x   = cx + cos(a) * 200;
      final y   = cy + sin(a) * 200;
      _drawBranchAt(canvas, x, y, a * 180 / pi + 90, 0.85);
    }
    // Extra between main
    for (int i = 0; i < 16; i++) {
      final a   = (i * 2 * pi) / 16 + (11.25 * pi / 180);
      final x   = cx + cos(a) * 185;
      final y   = cy + sin(a) * 185;
      _drawBranchAt(canvas, x, y, a * 180 / pi + 90, 0.55);
    }

    // Top edge
    for (int i = 0; i < 12; i++) {
      _drawBranchAt(canvas, 100 + i * 52, 100, 180, 0.5);
    }
    // Bottom edge
    for (int i = 0; i < 12; i++) {
      _drawBranchAt(canvas, 100 + i * 52, 1000, 0, 0.5);
    }
    // Left edge
    for (int i = 0; i < 14; i++) {
      _drawBranchAt(canvas, 70, 130 + i * 60, 90, 0.45);
    }
    // Right edge
    for (int i = 0; i < 14; i++) {
      _drawBranchAt(canvas, 730, 130 + i * 60, -90, 0.45);
    }
  }

  // ── Outer Circle + Diamond Band ────────────────────────────────

  void _paintOuterCircleAndDiamondBand(Canvas canvas) {
    const cx = _svgW / 2;
    const cy = _svgH / 2;

    canvas.drawCircle(const Offset(cx, cy), 170, _stroke(_cream,    5));
    canvas.drawCircle(const Offset(cx, cy), 167, _stroke(_darkBrown,1));
    _drawDiamondBand(canvas, cx, cy, 158, 52, 9);
  }

  // ── Radiating Triangles ────────────────────────────────────────

  void _paintRadiatingTriangles(Canvas canvas) {
    const cx = _svgW / 2;
    const cy = _svgH / 2;
    const count = 16;

    final colorSets = [
      [_darkBrown, _orange, _red],
      [_darkBrown, _red,    _pink],
      [_darkBrown, _skyBlue,_blue],
      [_darkBrown, _blue,   _orange],
    ];

    for (int i = 0; i < count; i++) {
      final a    = (i * 2 * pi) / count;
      final dist = 168.0;
      final x    = cx + cos(a) * dist;
      final y    = cy + sin(a) * dist;
      final cs   = colorSets[i % 4];

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(a + pi / 2);

      _drawTri(canvas,[const Offset(0,-32),const Offset(-16,10),const Offset(16,10)],  _fill(cs[0]));
      _drawTri(canvas,[const Offset(0,-32),const Offset(-16,10),const Offset(16,10)],  _stroke(_darkBrown, 0.8));
      _drawTri(canvas,[const Offset(0,-24),const Offset(-11,6), const Offset(11,6)],   _fill(cs[1]));
      _drawTri(canvas,[const Offset(0,-16),const Offset(-7,3),  const Offset(7,3)],    _fill(cs[2]));
      _drawBranchAt(canvas, 0, -34, 0, 0.35);

      canvas.restore();
    }
  }

  // ── Inner Circles + Diamond Band ──────────────────────────────

  void _paintInnerCirclesAndBand(Canvas canvas) {
    const cx = _svgW / 2;
    const cy = _svgH / 2;

    canvas.drawCircle(const Offset(cx, cy), 138, _stroke(_darkBrown, 1));
    canvas.drawCircle(const Offset(cx, cy), 134, _stroke(_skyBlue,   2));
    _drawDiamondBand(canvas, cx, cy, 126, 40, 8);
    canvas.drawCircle(const Offset(cx, cy), 116, _stroke(_darkBrown, 1));
    canvas.drawCircle(const Offset(cx, cy), 114, _fill(_cream));
    canvas.drawCircle(const Offset(cx, cy), 114, _stroke(_skyBlue,   1.5));
  }

  // ── Center Star ────────────────────────────────────────────────

  void _paintCenterStar(Canvas canvas) {
    const cx = _svgW / 2;
    const cy = _svgH / 2;

    canvas.save();
    canvas.translate(cx, cy);

    // Cardinal points (0, 90, 180, 270)
    for (final angleDeg in [0.0, 90.0, 180.0, 270.0]) {
      canvas.save();
      canvas.rotate(angleDeg * pi / 180);

      _drawTri(canvas,[const Offset(0,-75),const Offset(-20,-28),const Offset(20,-28)], _fill(_darkBrown));
      _drawTri(canvas,[const Offset(0,-75),const Offset(-20,-28),const Offset(20,-28)], _stroke(_darkBrown, 0.5));
      _drawTri(canvas,[const Offset(0,-65),const Offset(-14,-30),const Offset(14,-30)], _fill(_orange));
      _drawTri(canvas,[const Offset(0,-55),const Offset(-9,-32), const Offset(9,-32)],  _fill(_darkBrown, 0.6));
      _drawBranchAt(canvas, 0, -78, 0, 0.4);

      canvas.restore();
    }

    // Diagonal points (45, 135, 225, 315)
    for (final angleDeg in [45.0, 135.0, 225.0, 315.0]) {
      canvas.save();
      canvas.rotate(angleDeg * pi / 180);

      _drawTri(canvas,[const Offset(0,-60),const Offset(-14,-25),const Offset(14,-25)], _fill(_darkBrown));
      _drawTri(canvas,[const Offset(0,-50),const Offset(-9,-27), const Offset(9,-27)],  _fill(_skyBlue));
      _drawBranchAt(canvas, 0, -63, 0, 0.3);

      canvas.restore();
    }

    // Center yellow square
    canvas.drawRect(
      const Rect.fromLTWH(-30, -30, 60, 60),
      _fill(_yellow),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-30, -30, 60, 60),
      _stroke(_darkBrown, 2),
    );

    // Brown diamond overlay
    final diamPath = Path()
      ..moveTo(0, -30)
      ..lineTo(-30, 0)
      ..lineTo(0, 30)
      ..lineTo(30, 0)
      ..close();
    canvas.drawPath(diamPath, _stroke(_darkBrown, 2));

    // Top row triangles
    _drawTri(canvas,[const Offset(-18,-25),const Offset(-8,-5), const Offset(-28,-5)], _fill(_pink, 0.8));
    _drawTri(canvas,[const Offset(0,-25),  const Offset(-10,-5),const Offset(10,-5)],  _fill(_red,  0.8));
    _drawTri(canvas,[const Offset(18,-25), const Offset(8,-5),  const Offset(28,-5)],  _fill(_pink, 0.8));

    // Bottom row triangles
    _drawTri(canvas,[const Offset(-18,25), const Offset(-8,5),  const Offset(-28,5)],  _fill(_red,  0.8));
    _drawTri(canvas,[const Offset(0,25),   const Offset(-10,5), const Offset(10,5)],   _fill(_pink, 0.8));
    _drawTri(canvas,[const Offset(18,25),  const Offset(8,5),   const Offset(28,5)],   _fill(_red,  0.8));

    // Small chevrons
    _drawTri(canvas,[const Offset(0,-18),const Offset(-5,-10),const Offset(5,-10)], _fill(_darkBrown, 0.5));
    _drawTri(canvas,[const Offset(0,18), const Offset(-5,10), const Offset(5,10)],  _fill(_darkBrown, 0.5));

    // Dots around center
    for (final p in [
      [-35.0,-35.0],[35.0,-35.0],[-35.0,35.0],[35.0,35.0],
      [-40.0, 0.0], [40.0,  0.0],[ 0.0,-40.0],[ 0.0,40.0],
    ]) {
      canvas.drawCircle(Offset(p[0], p[1]), 2, _fill(_black));
    }
    // Pair dots
    for (final p in [
      [-55.0,-55.0],[55.0,-55.0],[-55.0,55.0],[55.0,55.0],
    ]) {
      canvas.drawCircle(Offset(p[0],     p[1]), 2, _fill(_black));
      canvas.drawCircle(Offset(p[0] + 8, p[1]), 2, _fill(_black));
    }

    canvas.restore();
  }

  // ── Teal squares around medallion ─────────────────────────────

  void _paintTealSquaresAroundMedallion(Canvas canvas) {
    const cx = _svgW / 2;
    const cy = _svgH / 2;

    for (int i = 0; i < 8; i++) {
      final a = (i * 2 * pi) / 8 + (22.5 * pi / 180);
      final x = cx + cos(a) * 145;
      final y = cy + sin(a) * 145;
      canvas.drawRect(Rect.fromLTWH(x - 4, y - 4, 8, 8), _fill(_skyBlue));
      canvas.drawRect(Rect.fromLTWH(x - 4, y - 4, 8, 8), _stroke(_darkBrown, 0.5));
    }
  }

  // ── Scattered Field Dots & Diamonds ───────────────────────────

  void _paintScatteredFieldDots(Canvas canvas) {
    // Dot pairs
    for (final d in [
      [120.0,150.0],[680.0,150.0],[120.0,950.0],[680.0,950.0],
      [200.0,200.0],[600.0,200.0],[200.0,900.0],[600.0,900.0],
      [150.0,550.0],[650.0,550.0],[400.0,200.0],[400.0,900.0],
      [300.0,300.0],[500.0,300.0],[300.0,800.0],[500.0,800.0],
      [250.0,450.0],[550.0,450.0],[250.0,650.0],[550.0,650.0],
    ]) {
      canvas.drawCircle(Offset(d[0],     d[1]),     2, _fill(_black));
      canvas.drawCircle(Offset(d[0] + 6, d[1] + 3), 2, _fill(_black));
    }

    // Red diamonds
    for (final d in [
      [170.0,250.0],[630.0,250.0],[170.0,850.0],[630.0,850.0],
      [130.0,400.0],[670.0,400.0],[130.0,700.0],[670.0,700.0],
    ]) {
      _drawDiamond(canvas, d[0], d[1], 4, _fill(_red));
    }

    // Yellow dots
    for (final d in [
      [100.0,180.0],[700.0,180.0],[100.0,920.0],[700.0,920.0],
      [180.0,130.0],[620.0,130.0],[180.0,970.0],[620.0,970.0],
    ]) {
      canvas.drawCircle(Offset(d[0], d[1]), 3, _fill(_yellow));
    }
  }

  // ── Border Diamond Decorations ─────────────────────────────────

  void _paintBorderDiamondDecorations(Canvas canvas) {
    const cols = [_red, _blue, _yellow, _green, _orange, _teal];
    for (int i = 0; i < 18; i++) {
      final col = cols[i % 6];
      final cx1 = 83.0 + i * 37;
      _drawDiamond(canvas, cx1, 43,   3, _fill(col));
      _drawDiamond(canvas, cx1, 1056, 3, _fill(col));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
