import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../data/models/bot_difficulty.dart';
import 'game_provider.dart';
import 'game_table_screen.dart';

// ══════════════════════════════════════════════════════════════════
//  GAME LOADING SCREEN — 3-Second Transition & Initialization
//
//  Shows a premium Sandstone Dark loading interface with pulsing suit
//  animations when the player presses Play. After exactly 3 seconds,
//  it initializes the game engine and transitions cleanly to the table.
// ══════════════════════════════════════════════════════════════════

class GameLoadingScreen extends StatefulWidget {
  final BotDifficulty difficulty;

  const GameLoadingScreen({super.key, required this.difficulty});

  @override
  State<GameLoadingScreen> createState() => _GameLoadingScreenState();
}

class _GameLoadingScreenState extends State<GameLoadingScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _animController;
  int _activeSuitIndex = 0;
  Timer? _suitTimer;

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
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _suitTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) {
        setState(() {
          _activeSuitIndex = (_activeSuitIndex + 1) % _suits.length;
        });
      }
    });

    // Exactly 3 seconds loading as requested
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      final game = context.read<GameProvider>();
      
      // Start the game right when showing the game screen
      game.startGame(difficulty: widget.difficulty);

      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => const GameTableScreen(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _suitTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  String _difficultyLabel(BotDifficulty d, bool isAr) {
    return switch (d) {
      BotDifficulty.easy => isAr ? 'سهل' : 'Easy',
      BotDifficulty.medium => isAr ? 'متوسط' : 'Medium',
      BotDifficulty.hard => isAr ? 'صعب' : 'Hard',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<LocaleProvider>().isArabic;
    final titleFont = isAr ? GoogleFonts.cairo : GoogleFonts.readexPro;
    final bodyFont = isAr ? GoogleFonts.tajawal : GoogleFonts.readexPro;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF26201A), // Deep Sandstone
              Color(0xFF14110E), // Very dark charcoal
              Color(0xFF0C0A08),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Top back button to cancel search if desired
              Positioned(
                top: 12,
                left: isAr ? null : 16,
                right: isAr ? 16 : null,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // Center content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing gold ring with suits
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1E1A16),
                            border: Border.all(
                              color: AppColors.goldAccent.withValues(
                                alpha: 0.3 + (_animController.value * 0.5),
                              ),
                              width: 2 + (_animController.value * 2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.goldAccent.withValues(
                                  alpha: 0.15 + (_animController.value * 0.25),
                                ),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, anim) => ScaleTransition(
                                scale: anim,
                                child: FadeTransition(opacity: anim, child: child),
                              ),
                              child: Text(
                                _suits[_activeSuitIndex],
                                key: ValueKey(_activeSuitIndex),
                                style: TextStyle(
                                  fontSize: 48,
                                  color: _suitColors[_activeSuitIndex],
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 36),

                    // Loading Title
                    Text(
                      isAr ? 'جاري تحضير الطاولة...' : 'Preparing Match...',
                      style: titleFont(
                        color: AppColors.goldAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Difficulty indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        '${isAr ? 'المستوى' : 'Difficulty'}: ${_difficultyLabel(widget.difficulty, isAr)}',
                        style: bodyFont(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Shimmering progress bar
                    SizedBox(
                      width: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.goldAccent.withValues(alpha: 0.8),
                          ),
                          minHeight: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom tip text
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Text(
                  isAr
                      ? 'تلميح: يمكنك استخدام تعبيرات الوجه والصوت أثناء اللعب من قائمة الطاولة العليا.'
                      : 'Tip: You can use emotes and voice expressions during the match from the top menu.',
                  textAlign: TextAlign.center,
                  style: bodyFont(
                    color: Colors.white38,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
