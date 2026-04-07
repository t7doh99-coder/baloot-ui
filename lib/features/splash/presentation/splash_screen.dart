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

  // Suit loader
  late final AnimationController _loaderFadeController;
  late final Animation<double> _loaderOpacity;
  int _activeSuit = 0;
  Timer? _suitTimer;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    // ── Card drops ──
    _cardControllers = List.generate(4, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
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
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
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

    // ── Loader ──
    _loaderFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loaderOpacity = Tween<double>(begin: 0, end: 1).animate(_loaderFadeController);

    _startSequence();
  }

  void _startSequence() async {
    // Phase 1: Stagger card drops
    for (int i = 0; i < 4; i++) {
      Future.delayed(Duration(milliseconds: 300 + i * 120), () {
        if (mounted) _cardControllers[i].forward();
      });
    }

    // Phase 2: After all cards land → text appears
    await Future.delayed(const Duration(milliseconds: 1400));
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

    // Phase 5: Suit loader
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _loaderFadeController.forward();
      _suitTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) setState(() => _activeSuit = (_activeSuit + 1) % 4);
      });
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
    _loaderFadeController.dispose();
    _suitTimer?.cancel();
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

          // ── Gold glow aura (pulsing) ──
          Center(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (_, __) {
                return Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.royalGold.withValues(
                          alpha: _glowController.isAnimating
                              ? _glowIntensity.value
                              : 0.0,
                        ),
                        blurRadius: 80,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Main content ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── TOP TEXT: أربعة (gold) ──
                AnimatedBuilder(
                  animation: _textRevealController,
                  builder: (_, __) {
                    return Opacity(
                      opacity: _textRevealOpacity.value,
                      child: Transform.scale(
                        scale: _textRevealScale.value,
                        child: Image.asset(
                          'assets/images/logo-text2.png',
                          width: 220,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // ── CARDS FAN (with arc) ──
                SizedBox(
                  height: 160,
                  width: 320,
                  child: Stack(
                    alignment: Alignment.center,
                    children: List.generate(4, (i) => _buildCard(i)),
                  ),
                ),

                const SizedBox(height: 12),

                // ── BOTTOM TEXT: مربعة (silver/white) ──
                AnimatedBuilder(
                  animation: _textRevealController,
                  builder: (_, __) {
                    return Opacity(
                      opacity: _textRevealOpacity.value,
                      child: Transform.scale(
                        scale: _textRevealScale.value,
                        child: Image.asset(
                          'assets/images/logo-text1.png',
                          width: 220,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ── Subtitle ──
                SlideTransition(
                  position: _subtitleSlide,
                  child: FadeTransition(
                    opacity: _subtitleOpacity,
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
              ],
            ),
          ),

          // ── Suit loader at bottom ──
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _loaderOpacity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => _buildSuitIcon(i)),
              ),
            ),
          ),

        ],
      ),
    );
  }

  // ─── Playing Card (with arc positioning) ──────────────────────────
  Widget _buildCard(int index) {
    final card = _cards[index];
    final rotation = (index - 1.5) * 10 * pi / 180; // slightly more fan spread
    final xOffset = (index - 1.5) * 55.0;
    final yOffset = _cardArcOffsets[index]; // gentle upward arc

    return AnimatedBuilder(
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
              width: 78,
              height: 115,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.royalGold.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppColors.royalGold.withValues(alpha: 0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
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
                          fontSize: 15, height: 1, color: card.suitColor,
                          fontWeight: FontWeight.w700,
                        )),
                        Text(card.suit, style: TextStyle(
                          fontSize: 11, height: 1, color: card.suitColor,
                        )),
                      ],
                    ),
                  ),
                  Text(card.suit, style: TextStyle(
                    fontSize: 26, height: 1,
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
                            fontSize: 15, height: 1, color: card.suitColor,
                            fontWeight: FontWeight.w700,
                          )),
                          Text(card.suit, style: TextStyle(
                            fontSize: 11, height: 1, color: card.suitColor,
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
    );
  }

  // ─── Suit Loader Icon ─────────────────────────────────────────────
  Widget _buildSuitIcon(int index) {
    final isActive = _activeSuit == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: AnimatedScale(
        scale: isActive ? 1.5 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: AnimatedOpacity(
          opacity: isActive ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 300),
          child: Text(
            _suitSymbols[index],
            style: TextStyle(
              fontSize: 28,
              color: _suitColors[index],
              shadows: isActive
                  ? [Shadow(
                      color: _suitColors[index].withValues(alpha: 0.8),
                      blurRadius: 20,
                    )]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
