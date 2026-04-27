import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../data/models/card_model.dart';
import '../../dashboard/presentation/navigation_shell.dart';
import '../../game/presentation/widgets/playing_card.dart';

// ─── Data ──────────────────────────────────────────────────────────
const _cards = [
  CardModel(suit: Suit.spades, rank: Rank.ace),
  CardModel(suit: Suit.hearts, rank: Rank.king),
  CardModel(suit: Suit.clubs, rank: Rank.queen),
  CardModel(suit: Suit.diamonds, rank: Rank.jack),
];

// Vertical arc offsets for cards
const _cardArcOffsets = [-8.0, -18.0, -18.0, -8.0];

// ─── Splash Screen ─────────────────────────────────────────────────
// PERFORMANCE NOTES:
// • Removed VipBackgroundShell (heavy CustomPaint every frame)
// • Replaced with static gradient (zero repaints)
// • Reduced animation controllers from 6 to 3
// • Cut total splash time from 5s to 2.8s
// • Smoother card animations with faster stagger
// ───────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Single controller for all 4 cards (staggered via intervals)
  late final AnimationController _cardsController;
  late final List<Animation<double>> _cardY;
  late final List<Animation<double>> _cardScale;
  late final List<Animation<double>> _cardOpacity;

  // Text + subtitle reveal
  late final AnimationController _revealController;
  late final Animation<double> _textOpacity;
  late final Animation<double> _textScale;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;

  // Golden circle
  late final AnimationController _circleController;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    // ── Cards: single controller, staggered intervals ──
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _cardY = List.generate(4, (i) {
      final start = i * 0.15; // 0, 0.15, 0.30, 0.45
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween<double>(begin: -500, end: 0).animate(
        CurvedAnimation(
          parent: _cardsController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _cardScale = List.generate(4, (i) {
      final start = i * 0.15;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween<double>(begin: 1.5, end: 1.0).animate(
        CurvedAnimation(
          parent: _cardsController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _cardOpacity = List.generate(4, (i) {
      final start = i * 0.15;
      final end = (start + 0.2).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _cardsController,
          curve: Interval(start, end, curve: Curves.easeIn),
        ),
      );
    });

    // ── Text + subtitle: single controller ──
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _textScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    // ── Golden circle ──
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _startSequence();
  }

  void _startSequence() async {
    // Phase 1: Cards fly in (starts immediately, no delay)
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) _cardsController.forward();

    // Phase 2: Text + circle (after cards land ~1.2s)
    await Future.delayed(const Duration(milliseconds: 1300));
    if (mounted) {
      _revealController.forward();
      _circleController.forward();
    }

    // Navigate at 2.8s total (fast!)
    _navTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, __, ___) => const NavigationShell(),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(opacity: anim, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _cardsController.dispose();
    _revealController.dispose();
    _circleController.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // ── Background: Static gradient (zero repaints, fast) ──
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

          // ── Golden circle arcs ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _circleController,
              builder: (_, __) {
                return CustomPaint(
                  painter: _GoldenCirclePainter(_circleController.value),
                );
              },
            ),
          ),

          // ── Cards ──
          ...List.generate(4, (i) => _buildCard(i)),

          // ── Top logo text ──
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 220,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _revealController,
              builder: (_, __) {
                return Opacity(
                  opacity: _textOpacity.value,
                  child: Transform.scale(
                    scale: _textScale.value,
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo-text2.png',
                        width: 170,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Bottom logo text ──
          Positioned(
            top: MediaQuery.of(context).size.height / 2 + 100,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _revealController,
              builder: (_, __) {
                return Opacity(
                  opacity: _textOpacity.value,
                  child: Transform.scale(
                    scale: _textScale.value,
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo-text1.png',
                        width: 170,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Subtitle — at the bottom ──
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _revealController,
              builder: (_, __) {
                return SlideTransition(
                  position: _subtitleSlide,
                  child: Opacity(
                    opacity: _subtitleOpacity.value,
                    child: Center(
                      child: Text(
                        context.read<LocaleProvider>().isArabic
                            ? 'لعبة الورق الملكية'
                            : 'THE ROYAL CARD GAME',
                        style: GoogleFonts.readexPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 6,
                          color: AppColors.royalGold.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    final card = _cards[index];
    final rotation = (index - 1.5) * 8 * pi / 180;
    final xOffset = (index - 1.5) * 60.0;
    final yOffset = _cardArcOffsets[index];

    return Center(
      child: AnimatedBuilder(
        animation: _cardsController,
        builder: (_, __) {
          return Opacity(
            opacity: _cardOpacity[index].value,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..translate(xOffset, _cardY[index].value + yOffset)
                ..rotateZ(rotation)
                ..scale(_cardScale[index].value),
              child: SizedBox(
                width: 90,
                height: 130,
                child: PlayingCard(
                  card: card,
                  size: CardSize.large,
                  faceUp: true,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Golden Circle Painter ──────────────────────────────────────────
class _GoldenCirclePainter extends CustomPainter {
  final double progress;

  _GoldenCirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final center = Offset(size.width / 2, size.height / 2 - 15);
    final radius = 160.0;

    const gapAngle = 0.60;
    const maxSweep = pi - 2 * gapAngle;
    final sweep = maxSweep * progress;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // ── Glow layer (wider, blurred, softer) ──
    final glowPaint = Paint()
      ..color = AppColors.royalGold.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawArc(rect, -pi / 2 - gapAngle, -sweep, false, glowPaint);
    canvas.drawArc(rect, -pi / 2 + gapAngle, sweep, false, glowPaint);

    // ── Main stroke (thicker, solid) ──
    final paint = Paint()
      ..color = AppColors.royalGold.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -pi / 2 - gapAngle, -sweep, false, paint);
    canvas.drawArc(rect, -pi / 2 + gapAngle, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _GoldenCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
