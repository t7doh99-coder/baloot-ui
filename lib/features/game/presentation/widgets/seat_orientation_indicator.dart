import 'package:flutter/material.dart';

/// A 4-dot diamond/cross table orientation indicator matching Kammelna design.
///
/// Indicates the player's physical seat position around the table from the user's perspective:
/// - Seat 0: Bottom dot active (Player / South)
/// - Seat 1: Right dot active (Jim / East)
/// - Seat 2: Top dot active (Michael / North / Partner)
/// - Seat 3: Left dot active (Dwight / West)
class SeatOrientationIndicator extends StatelessWidget {
  final int seatIndex;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const SeatOrientationIndicator({
    super.key,
    required this.seatIndex,
    this.size = 15.0,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: SeatOrientationPainter(
        seatIndex: seatIndex,
        activeColor: activeColor ?? const Color(0xFFCEE53D), // Vibrant lime-yellow matching Kammelna
        inactiveColor: inactiveColor ?? const Color(0xFF000000), // Solid dark
      ),
    );
  }
}

class SeatOrientationPainter extends CustomPainter {
  final int seatIndex;
  final Color activeColor;
  final Color inactiveColor;

  const SeatOrientationPainter({
    required this.seatIndex,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final dist = size.width * 0.32;
    final dotR = size.width * 0.125;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Dot positions: Top (2), Right (1), Bottom (0), Left (3)
    final normalizedSeat = (seatIndex % 4 + 4) % 4;

    // Top dot (Seat 2: Partner / North)
    canvas.drawCircle(
      Offset(cx, cy - dist),
      dotR,
      normalizedSeat == 2 ? activePaint : inactivePaint,
    );

    // Right dot (Seat 1: Right opponent / East)
    canvas.drawCircle(
      Offset(cx + dist, cy),
      dotR,
      normalizedSeat == 1 ? activePaint : inactivePaint,
    );

    // Bottom dot (Seat 0: Local player / South)
    canvas.drawCircle(
      Offset(cx, cy + dist),
      dotR,
      normalizedSeat == 0 ? activePaint : inactivePaint,
    );

    // Left dot (Seat 3: Left opponent / West)
    canvas.drawCircle(
      Offset(cx - dist, cy),
      dotR,
      normalizedSeat == 3 ? activePaint : inactivePaint,
    );
  }

  @override
  bool shouldRepaint(covariant SeatOrientationPainter oldDelegate) {
    return oldDelegate.seatIndex != seatIndex ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
