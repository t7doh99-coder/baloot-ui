import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/vip_background_shell.dart';
import '../../dashboard/presentation/navigation_shell.dart';

// ─── Data ──────────────────────────────────────────────────────────
class _CardData {
  final String suit;
  final String value;
  final Color suitColor;
  const _CardData(this.suit, this.value, this.suitColor);
}

const _cards = [
  _CardData('♠', 'A', Colors.white),
  _CardData('♥', 'K', Color(0xFFE53935)),
  _CardData('♣', 'Q', Colors.white),
  _CardData('♦', 'J', Color(0xFFE53935)),
];

const _suitSymbols = ['♠', '♥', '♣', '♦'];
const _suitColors = [
  Color(0xFFC0C0C0),
  Color(0xFFE53935),
  Color(0xFFC0C0C0),
  Color(0xFFE53935),
];

// Vertical arc offsets for cards (parabolic curve)
// Cards index 0,1,2,3 → offsets to form a gentle upward arc
const _cardArcOffsets = [-8.0, -18.0, -18.0, -8.0];

// ─── Main Splash Screen ────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Card drop animations
  late final List<AnimationController> _cardControllers;
  late final List<Animation<double>> _cardYAnimations;
  late final List<Animation<double>> _cardScaleAnimations;
  late final List<Animation<double>> _cardOpacityAnimations;

  // Text reveal (after cards land)
  late final AnimationController _textRevealController;
  late final Animation<double> _textRevealOpacity;
  late final Animation<double> _textRevealScale;

  // Subtitle
  late final AnimationController _subtitleController;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;

  // Shimmer
  late final AnimationController _shimmerController;

  // Glow pulse
  late final AnimationController _glowController;
  late final Animation<double> _glowIntensity;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    // ── Card drops ──
    _cardControllers = List.generate(4, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );
    });

    _cardYAnimations = _cardControllers.map((c) {
      return Tween<double>(begin: -600, end: 0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOutBack),
      );
    }).toList();

    _cardScaleAnimations = _cardControllers.map((c) {
      return Tween<double>(begin: 1.8, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOut),
      );
    }).toList();

    _cardOpacityAnimations = _cardControllers.map((c) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: c,
          curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
        ),
      );
    }).toList();

    // ── Text reveal ──
    _textRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textRevealOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textRevealController, curve: Curves.easeOut),
    );
    _textRevealScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _textRevealController, curve: Curves.easeOutCubic),
    );

    // ── Subtitle ──
    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _subtitleOpacity = Tween<double>(begin: 0, end: 1).animate(_subtitleController);
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _subtitleController, curve: Curves.easeOut));

    // ── Shimmer ──
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // ── Glow pulse ──
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _glowIntensity = Tween<double>(begin: 0.06, end: 0.18).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startSequence();
  }

  void _startSequence() async {
    // Phase 1: Stagger card drops — each card 350ms apart
    for (int i = 0; i < 4; i++) {
      Future.delayed(Duration(milliseconds: 400 + i * 350), () {
        if (mounted) _cardControllers[i].forward();
      });
    }

    // Phase 2: After all cards land → text appears
    // Last card starts at 400+3*350=1450ms, takes 1200ms → lands at ~2650ms
    await Future.delayed(const Duration(milliseconds: 2900));
    if (mounted) _textRevealController.forward();

    // Phase 3: Subtitle
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) _subtitleController.forward();

    // Phase 4: Shimmer + glow
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _shimmerController.repeat();
      _glowController.repeat(reverse: true);
    }

    // Navigate after 5s
    _navTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
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
    for (var c in _cardControllers) {
      c.dispose();
    }
    _textRevealController.dispose();
    _subtitleController.dispose();
    _shimmerController.dispose();
    _glowController.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // ── Background: VIP Shell (gradient + suit pattern + shimmer) ──
          const VipBackgroundShell(),




          // ── Golden Circle Lines (rendered under cards) ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _textRevealController,
              builder: (_, __) {
                return CustomPaint(
                  painter: _GoldenCirclePainter(_textRevealController.value),
                );
              },
            ),
          ),

          // ── Cards fan — positioned in main Stack so they can fly in from top ──
          ...List.generate(4, (i) => _buildCard(i)),

          // ── TOP TEXT: أربعة (gold) — positioned above cards ──
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 220,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _textRevealController,
              builder: (_, __) {
                return Opacity(
                  opacity: _textRevealOpacity.value,
                  child: Transform.scale(
                    scale: _textRevealScale.value,
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

          // ── BOTTOM TEXT: مربعة (silver/white) — positioned below cards ──
          Positioned(
            top: MediaQuery.of(context).size.height / 2 + 100,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _textRevealController,
              builder: (_, __) {
                return Opacity(
                  opacity: _textRevealOpacity.value,
                  child: Transform.scale(
                    scale: _textRevealScale.value,
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

          // ── Subtitle ──
          Positioned(
            top: MediaQuery.of(context).size.height / 2 + 160,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _subtitleSlide,
              child: FadeTransition(
                opacity: _subtitleOpacity,
                child: Center(
                  child: Text(
                    'THE ROYAL CARD GAME',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 6,
                      color: AppColors.royalGold.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  // ─── Playing Card (matching Figma animation) ──────────────────────
  Widget _buildCard(int index) {
    final card = _cards[index];
    final rotation = (index - 1.5) * 8 * pi / 180; // 8° fan spread (Figma)
    final xOffset = (index - 1.5) * 60.0; // 60px spacing (Figma)
    final yOffset = _cardArcOffsets[index]; // gentle upward arc

    return Center(
      child: AnimatedBuilder(
        animation: _cardControllers[index],
        builder: (_, __) {
          return Opacity(
            opacity: _cardOpacityAnimations[index].value,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..translate(xOffset, _cardYAnimations[index].value + yOffset)
                ..rotateZ(rotation)
                ..scale(_cardScaleAnimations[index].value),
              child: Container(
                width: 90,
                height: 130,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.royalGold.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 15),
                    ),
                    BoxShadow(
                      color: AppColors.royalGold.withValues(alpha: 0.15),
                      blurRadius: 10,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(card.value, style: GoogleFonts.cairo(
                            fontSize: 18, height: 1, color: card.suitColor,
                            fontWeight: FontWeight.w700,
                          )),
                          Text(card.suit, style: TextStyle(
                            fontSize: 14, height: 1, color: card.suitColor,
                          )),
                        ],
                      ),
                    ),
                    Text(card.suit, style: TextStyle(
                      fontSize: 32, height: 1,
                      color: card.suitColor.withValues(alpha: 0.3),
                    )),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Transform.rotate(
                        angle: pi,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(card.value, style: GoogleFonts.cairo(
                              fontSize: 18, height: 1, color: card.suitColor,
                              fontWeight: FontWeight.w700,
                            )),
                            Text(card.suit, style: TextStyle(
                              fontSize: 14, height: 1, color: card.suitColor,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
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

    final paint = Paint()
      ..color = AppColors.royalGold.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Center point midway between the top and bottom text elements
    // Top text center ~ -190, Bottom text center ~ +130 => Center is -30
    // Shifting it a bit lower to match visual weight
    final center = Offset(size.width / 2, size.height / 2 - 15);
    // Radius of 160 reaches exactly -190 (top) and +130 (bottom)
    final radius = 160.0;

    // Gap at the top and bottom so it connects perfectly to the text width
    const gapAngle = 0.60; // Increased to give text more breathing room
    const maxSweep = pi - 2 * gapAngle;
    final sweep = maxSweep * progress;

    // Left arc: starting near top-left, going down to bottom-left
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2 - gapAngle,
      -sweep,
      false,
      paint,
    );

    // Right arc: starting near top-right, going down to bottom-right
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2 + gapAngle,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoldenCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
