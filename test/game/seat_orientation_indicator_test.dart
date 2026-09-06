import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/features/game/presentation/widgets/seat_orientation_indicator.dart';

void main() {
  group('SeatOrientationIndicator Tests', () {
    testWidgets('renders properly for Seat 0 (Player / Bottom)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeatOrientationIndicator(seatIndex: 0),
          ),
        ),
      );

      expect(find.byType(SeatOrientationIndicator), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SeatOrientationIndicator),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders properly for Seat 1 (Right)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeatOrientationIndicator(seatIndex: 1),
          ),
        ),
      );

      expect(find.byType(SeatOrientationIndicator), findsOneWidget);
    });

    testWidgets('renders properly for Seat 2 (Top / Partner)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeatOrientationIndicator(seatIndex: 2),
          ),
        ),
      );

      expect(find.byType(SeatOrientationIndicator), findsOneWidget);
    });

    testWidgets('renders properly for Seat 3 (Left)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeatOrientationIndicator(seatIndex: 3),
          ),
        ),
      );

      expect(find.byType(SeatOrientationIndicator), findsOneWidget);
    });

    test('shouldRepaint returns true when seatIndex changes', () {
      const painter1 = SeatOrientationPainter(
        seatIndex: 0,
        activeColor: Color(0xFFCEE53D),
        inactiveColor: Color(0xFF000000),
      );
      const painter2 = SeatOrientationPainter(
        seatIndex: 1,
        activeColor: Color(0xFFCEE53D),
        inactiveColor: Color(0xFF000000),
      );
      const painter3 = SeatOrientationPainter(
        seatIndex: 0,
        activeColor: Color(0xFFCEE53D),
        inactiveColor: Color(0xFF000000),
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
      expect(painter1.shouldRepaint(painter3), isFalse);
    });
  });
}
