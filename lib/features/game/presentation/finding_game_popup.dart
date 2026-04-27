import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/locale_provider.dart';

// ══════════════════════════════════════════════════════════════════
//  FINDING GAME POPUP — Shows when player taps "Play"
//
//  Features:
//  • "Finding Game..." text
//  • Suit icons (♠ ♥ ♣ ♦) highlight one-by-one as loading
//  • Back button top-right to cancel search
//
//  LOGIC_PLUG_IN:
//  • Replace Timer with actual matchmaking websocket
//  • On match found → navigate to game table
// ══════════════════════════════════════════════════════════════════

class FindingGamePopup {
  FindingGamePopup._();

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'FindingGame',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, __) => const _FindingGameContent(),
    );
  }
}

class _FindingGameContent extends StatefulWidget {
  const _FindingGameContent();

  @override
  State<_FindingGameContent> createState() => _FindingGameContentState();
}

class _FindingGameContentState extends State<_FindingGameContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _suits = ['♠', '♥', '♣', '♦'];
  static const _suitColors = [
    Colors.white,
    Color(0xFFE53935),
    Colors.white,
    Color(0xFFE53935),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Smooth sine-wave intensity for each suit (0.0 → 1.0)
  // Each suit is offset by 0.25 (90°) so they wave in sequence
  double _intensity(int index) {
    final phase = index / 4.0;
    final t = (_controller.value + phase) % 1.0;
    // Sine wave: peaks at t=0.25 for each suit
    final sine = sin(t * 2 * pi);
    // Remap -1..1 → 0..1, then bias toward 0 for sharper pulse
    return ((sine + 1) / 2).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.fromLTRB(24, 16, 16, 28),
        decoration: BoxDecoration(
          color: const Color(0xFF141720),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.royalGold.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.royalGold.withValues(alpha: 0.08),
              blurRadius: 30,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Close chevron (top-right) ──
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/images/chevron-left.png',
                      width: 28,
                      height: 28,
                      color: AppColors.royalGold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Finding Game text ──
              Text(
                context.watch<LocaleProvider>().isArabic
                    ? 'البحث عن لعبة'
                    : 'Finding Game',
                style: GoogleFonts.readexPro(
                  color: const Color(0xFFF4E4B7),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 1,
                ),
              ),

              const SizedBox(height: 8),

              // ── Subtitle ──
              Text(
                context.watch<LocaleProvider>().isArabic
                    ? 'جاري البحث عن لاعبين...'
                    : 'Searching for players...',
                style: GoogleFonts.readexPro(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11,
                  letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 0.3,
                ),
              ),

              const SizedBox(height: 32),

              // ── Smooth suit wave animation ──
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final t = _intensity(i);
                      final scale = 1.0 + t * 0.35; // 1.0 → 1.35
                      final opacity = 0.12 + t * 0.88; // 0.12 → 1.0
                      final glowRadius = t * 14; // 0 → 14

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: Transform.scale(
                          scale: scale,
                          child: Text(
                            _suits[i],
                            style: TextStyle(
                              fontSize: 28,
                              color: _suitColors[i].withValues(alpha: opacity),
                              shadows: t > 0.3
                                  ? [
                                      Shadow(
                                        color: _suitColors[i]
                                            .withValues(alpha: t * 0.6),
                                        blurRadius: glowRadius,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
