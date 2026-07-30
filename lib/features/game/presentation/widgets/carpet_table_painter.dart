import 'dart:math';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════
//  CARPET TABLE PAINTER
//
//  Paints an ornate traditional Arabic/Berber geometric carpet
//  pattern inspired by the Tuareg mandala design:
//  • Cream base
//  • Outer decorative mosaic ring with colored triangular points
//  • Checkered diamond / woven lattice band inside the ring
//  • Inner geometric star medallion
//  • Corner decorative elements
// ══════════════════════════════════════════════════════════════════

class CarpetTablePainter extends CustomPainter {
  const CarpetTablePainter();

  // ── Palette (from reference image) ──
  static const _cream    = Color(0xFFF5F0E8);
  static const _red      = Color(0xFFD32F2F);
  static const _green    = Color(0xFF388E3C);
  static const _blue     = Color(0xFF1565C0);
  static const _yellow   = Color(0xFFF9A825);
  static const _orange   = Color(0xFFE64A19);
  static const _brown    = Color(0xFF4E342E);
  static const _teal     = Color(0xFF00796B);
  static const _darkLine = Color(0xFF2C1810);

  static const _ringColors = [
    _red, _green, _blue, _yellow, _orange, _teal, _red, _green,
    _blue, _yellow, _orange, _teal, _red, _green, _blue, _yellow,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // 1. Cream base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = _cream,
    );

    // 2. Subtle diagonal grid texture (woven feel)
    _paintWovenTexture(canvas, size);

    // 3. Outer border frame
    _paintOuterBorderFrame(canvas, size);

    // 4. Mosaic ring with triangular points
    _paintMosaicRing(canvas, cx, cy, min(w, h) * 0.42, min(w, h) * 0.32);

    // 5. Inner woven lattice band
    _paintLattice(canvas, cx, cy, min(w, h) * 0.30);

    // 6. Center medallion star
    _paintCenterMedallion(canvas, cx, cy, min(w, h) * 0.18);

    // 7. Dark outline rings
    _paintOutlineRings(canvas, cx, cy, size);
  }

  void _paintWovenTexture(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _brown.withValues(alpha: 0.04)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const step = 18.0;
    for (double i = 0; i < size.width + size.height; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(0, i), paint);
      canvas.drawLine(
          Offset(size.width - i, 0), Offset(size.width, i), paint);
    }
  }

  void _paintOuterBorderFrame(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const inset1 = 6.0;
    const inset2 = 12.0;
    const inset3 = 18.0;

    // Outer dark border
    canvas.drawRect(
      Rect.fromLTWH(inset1, inset1, w - inset1 * 2, h - inset1 * 2),
      Paint()
        ..color = _darkLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    // Red accent border
    canvas.drawRect(
      Rect.fromLTWH(inset2, inset2, w - inset2 * 2, h - inset2 * 2),
      Paint()
        ..color = _red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Inner dark border
    canvas.drawRect(
      Rect.fromLTWH(inset3, inset3, w - inset3 * 2, h - inset3 * 2),
      Paint()
        ..color = _darkLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Corner diamond accents
    _paintCornerDiamonds(canvas, size);
  }

  void _paintCornerDiamonds(Canvas canvas, Size size) {
    final corners = [
      Offset(size.width * 0.08, size.height * 0.08),
      Offset(size.width * 0.92, size.height * 0.08),
      Offset(size.width * 0.08, size.height * 0.92),
      Offset(size.width * 0.92, size.height * 0.92),
    ];
    final colors = [_red, _blue, _green, _yellow];
    for (int i = 0; i < corners.length; i++) {
      _drawDiamond(canvas, corners[i], 7, Paint()..color = colors[i]);
      _drawDiamond(
        canvas, corners[i], 8,
        Paint()
          ..color = _darkLine
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _paintMosaicRing(
      Canvas canvas, double cx, double cy, double outerR, double innerR) {
    // The mosaic ring = many triangular spike segments around the outer edge
    // and a filled ring with the woven checkerboard pattern

    const segments = 32;
    const angleStep = (2 * pi) / segments;

    for (int i = 0; i < segments; i++) {
      final angle = i * angleStep - pi / 2;
      final nextAngle = (i + 1) * angleStep - pi / 2;
      final midAngle = angle + angleStep / 2;
      final color = _ringColors[i % _ringColors.length];

      // Outer spike (triangular point)
      final tipX = cx + outerR * cos(midAngle);
      final tipY = cy + outerR * sin(midAngle);
      final baseL = Offset(
        cx + (innerR + (outerR - innerR) * 0.3) * cos(angle),
        cy + (innerR + (outerR - innerR) * 0.3) * sin(angle),
      );
      final baseR = Offset(
        cx + (innerR + (outerR - innerR) * 0.3) * cos(nextAngle),
        cy + (innerR + (outerR - innerR) * 0.3) * sin(nextAngle),
      );

      final spikePath = Path()
        ..moveTo(tipX, tipY)
        ..lineTo(baseL.dx, baseL.dy)
        ..lineTo(baseR.dx, baseR.dy)
        ..close();
      canvas.drawPath(spikePath, Paint()..color = color);

      // Mosaic tile in the ring band
      _paintMosaicTile(canvas, cx, cy, i, segments, innerR,
          innerR + (outerR - innerR) * 0.3, color, angle, nextAngle);
    }

    // Dark outline for the ring
    canvas.drawCircle(
      Offset(cx, cy),
      innerR,
      Paint()
        ..color = _darkLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      outerR * 0.75,
      Paint()
        ..color = _darkLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _paintMosaicTile(Canvas canvas, double cx, double cy, int i,
      int segments, double r1, double r2, Color color, double a1, double a2) {
    // Alternate between filled and outlined tiles for mosaic effect
    final isEven = i % 2 == 0;
    final tileColor = isEven ? color : color.withValues(alpha: 0.4);
    final midR = (r1 + r2) / 2;

    // Draw arc segment as path
    final path = Path();
    final steps = 6;
    final dA = (a2 - a1) / steps;

    path.moveTo(cx + r1 * cos(a1), cy + r1 * sin(a1));
    for (int s = 0; s <= steps; s++) {
      final a = a1 + s * dA;
      path.lineTo(cx + r2 * cos(a), cy + r2 * sin(a));
    }
    for (int s = steps; s >= 0; s--) {
      final a = a1 + s * dA;
      path.lineTo(cx + r1 * cos(a), cy + r1 * sin(a));
    }
    path.close();
    canvas.drawPath(path, Paint()..color = tileColor);

    // Small inner diamond in mosaic tile
    if (isEven) {
      final midA = (a1 + a2) / 2;
      _drawDiamond(
        canvas,
        Offset(cx + midR * cos(midA), cy + midR * sin(midA)),
        3.5,
        Paint()..color = _cream,
      );
    }
  }

  void _paintLattice(Canvas canvas, double cx, double cy, double r) {
    // Draw a woven/lattice circle filled background
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = _cream,
    );

    // Lattice lines — diagonal grid clipped to circle
    canvas.save();
    final clip = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.clipPath(clip);

    final latticePaint = Paint()
      ..color = _brown.withValues(alpha: 0.18)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const step = 10.0;
    for (double d = -r * 2; d < r * 2; d += step) {
      canvas.drawLine(Offset(cx + d, cy - r), Offset(cx + d + r * 2, cy + r), latticePaint);
      canvas.drawLine(Offset(cx + d, cy - r), Offset(cx + d - r * 2, cy + r), latticePaint);
    }

    // Small colored diamonds scattered in lattice
    const colors = [_red, _blue, _green, _yellow, _orange, _teal];
    const dotCount = 20;
    for (int i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 2 * pi;
      final dist = r * 0.62;
      final x = cx + dist * cos(angle);
      final y = cy + dist * sin(angle);
      _drawDiamond(canvas, Offset(x, y), 3.5,
          Paint()..color = colors[i % colors.length]);
    }

    canvas.restore();

    // Lattice circle outline
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = _darkLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _paintCenterMedallion(Canvas canvas, double cx, double cy, double r) {
    // Cream filled center circle
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = _cream,
    );

    // 8-pointed star with colored triangular petals
    const petals = 8;
    const petalColors = [_red, _yellow, _blue, _orange, _green, _yellow, _teal, _red];
    for (int i = 0; i < petals; i++) {
      final angle = (i / petals) * 2 * pi - pi / 2;
      final nextAngle = ((i + 1) / petals) * 2 * pi - pi / 2;
      final midAngle = angle + pi / petals;

      // Outer petal triangle
      final tip = Offset(cx + r * cos(midAngle), cy + r * sin(midAngle));
      final bl  = Offset(cx + r * 0.45 * cos(angle), cy + r * 0.45 * sin(angle));
      final br  = Offset(cx + r * 0.45 * cos(nextAngle), cy + r * 0.45 * sin(nextAngle));

      final path = Path()..moveTo(tip.dx, tip.dy)..lineTo(bl.dx, bl.dy)..lineTo(br.dx, br.dy)..close();
      canvas.drawPath(path, Paint()..color = petalColors[i]);
      canvas.drawPath(
        path,
        Paint()
          ..color = _darkLine
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );

      // Inner half-petal (inverted triangle)
      final innerTip = Offset(cx + r * 0.3 * cos(midAngle + pi / petals),
          cy + r * 0.3 * sin(midAngle + pi / petals));
      final ibl = Offset(cx + r * 0.5 * cos(midAngle - pi / petals * 0.5),
          cy + r * 0.5 * sin(midAngle - pi / petals * 0.5));
      final ibr = Offset(cx + r * 0.5 * cos(midAngle + pi / petals * 0.5),
          cy + r * 0.5 * sin(midAngle + pi / petals * 0.5));

      final innerPath = Path()
        ..moveTo(innerTip.dx, innerTip.dy)
        ..lineTo(ibl.dx, ibl.dy)
        ..lineTo(ibr.dx, ibr.dy)
        ..close();
      canvas.drawPath(
          innerPath, Paint()..color = petalColors[(i + 4) % petals]);
    }

    // Center diamond stack (the characteristic Tuareg symbol)
    _paintTuaregSymbol(canvas, cx, cy, r * 0.28);

    // Medallion outline
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = _darkLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _paintTuaregSymbol(Canvas canvas, double cx, double cy, double size) {
    // Classic Tuareg/Berber center symbol: stacked triangles and diamonds
    // Top triangle (pointing up)
    _drawTriangle(canvas, Offset(cx, cy - size * 0.7), size * 0.55, true,
        Paint()..color = _yellow);
    _drawTriangle(canvas, Offset(cx, cy - size * 0.7), size * 0.55, true,
        Paint()
          ..color = _darkLine
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);

    // Bottom triangle (pointing down)
    _drawTriangle(canvas, Offset(cx, cy + size * 0.7), size * 0.55, false,
        Paint()..color = _red);
    _drawTriangle(canvas, Offset(cx, cy + size * 0.7), size * 0.55, false,
        Paint()
          ..color = _darkLine
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);

    // Center diamond
    _drawDiamond(canvas, Offset(cx, cy), size * 0.38,
        Paint()..color = _brown);
    _drawDiamond(
      canvas, Offset(cx, cy), size * 0.38,
      Paint()
        ..color = _darkLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Small dot accents
    const dotPositions = [
      Offset(-1, -1.6), Offset(1, -1.6), Offset(-1, 1.6), Offset(1, 1.6),
    ];
    for (final dp in dotPositions) {
      canvas.drawCircle(
        Offset(cx + dp.dx * size * 0.4, cy + dp.dy * size * 0.3),
        2.0,
        Paint()..color = _brown,
      );
    }
  }

  void _drawTriangle(
      Canvas canvas, Offset center, double size, bool pointingUp, Paint paint) {
    final path = Path();
    if (pointingUp) {
      path
        ..moveTo(center.dx, center.dy - size * 0.6)
        ..lineTo(center.dx - size * 0.5, center.dy + size * 0.4)
        ..lineTo(center.dx + size * 0.5, center.dy + size * 0.4)
        ..close();
    } else {
      path
        ..moveTo(center.dx, center.dy + size * 0.6)
        ..lineTo(center.dx - size * 0.5, center.dy - size * 0.4)
        ..lineTo(center.dx + size * 0.5, center.dy - size * 0.4)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  void _paintOutlineRings(Canvas canvas, double cx, double cy, Size size) {
    // Fern/branch tick marks around the outer medallion ring (like the reference)
    final tickR = min(size.width, size.height) * 0.44;
    const tickCount = 48;
    final tickPaint = Paint()
      ..color = _darkLine
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < tickCount; i++) {
      final angle = (i / tickCount) * 2 * pi;
      final inner = Offset(cx + (tickR - 5) * cos(angle), cy + (tickR - 5) * sin(angle));
      final outer = Offset(cx + (tickR + 3) * cos(angle), cy + (tickR + 3) * sin(angle));
      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
