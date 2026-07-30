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
//  GAME LOADING SCREEN — Wait-until-ready Transition
//
//  Stays visible until the match engine has finished the opening deal
//  (phase past dealing). A short minimum display keeps the branding
//  from flashing on fast phones; slow phones simply stay longer.
// ══════════════════════════════════════════════════════════════════

class GameLoadingScreen extends StatefulWidget {
  final BotDifficulty difficulty;

  const GameLoadingScreen({super.key, required this.difficulty});

  @override
  State<GameLoadingScreen> createState() => _GameLoadingScreenState();
}

class _GameLoadingScreenState extends State<GameLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  int _activeSuitIndex = 0;
  Timer? _suitTimer;
  bool _navigating = false;
  String _statusKey = 'preparing'; // preparing | dealing | ready

  static const _minDisplay = Duration(milliseconds: 1800);
  static const _hardTimeout = Duration(seconds: 10);

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

    // Start prep after first frame so the loading UI paints immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareAndNavigate();
    });
  }

  Future<void> _prepareAndNavigate() async {
    if (!mounted || _navigating) return;
    final started = DateTime.now();
    final game = context.read<GameProvider>();
    final isAr = context.read<LocaleProvider>().isArabic;

    game.setLanguage(isAr ? 'ar' : 'en');

    try {
      if (mounted) setState(() => _statusKey = 'preparing');
      await game.prepareMatchForTable(difficulty: widget.difficulty);

      // Poll briefly if somehow still dealing (should be rare).
      var attempts = 0;
      while (mounted &&
          !game.isMatchReady &&
          DateTime.now().difference(started) < _hardTimeout &&
          attempts < 20) {
        if (mounted) setState(() => _statusKey = 'dealing');
        game.ensureDealingAdvances(force: true);
        await Future<void>.delayed(const Duration(milliseconds: 150));
        attempts++;
      }
    } catch (e, st) {
      debugPrint('[GameLoading] prepare failed: $e\n$st');
      try {
        if (!game.isMatchReady) {
          game.ensureDealingAdvances(force: true);
        }
      } catch (_) {}
    }

    // Keep branding on screen at least [_minDisplay], even on fast devices.
    final elapsed = DateTime.now().difference(started);
    if (elapsed < _minDisplay) {
      await Future<void>.delayed(_minDisplay - elapsed);
    }

    if (!mounted || _navigating) return;

    // Never open the table while still stuck in dealing.
    if (!game.isMatchReady) {
      debugPrint('[GameLoading] still not ready after timeout — forcing');
      game.ensureDealingAdvances(force: true);
    }

    if (mounted) setState(() => _statusKey = 'ready');
    await Future<void>.delayed(const Duration(milliseconds: 120));

    if (!mounted || _navigating) return;
    _navigating = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const GameTableScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _suitTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  String _difficultyLabel(BotDifficulty d, bool isAr) {
    return switch (d) {
      BotDifficulty.easy => isAr ? 'مبتدئ' : 'Beginner',
      BotDifficulty.medium => isAr ? 'عادي' : 'Regular',
      BotDifficulty.hard => isAr ? 'خبير' : 'Expert',
    };
  }

  String _statusText(bool isAr) {
    return switch (_statusKey) {
      'dealing' => isAr ? 'جاري توزيع الأوراق...' : 'Dealing cards...',
      'ready' => isAr ? 'الطاولة جاهزة' : 'Table ready',
      _ => isAr ? 'جاري تحضير الطاولة...' : 'Preparing Match...',
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
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(
                                scale: anim,
                                child: FadeTransition(
                                  opacity: anim,
                                  child: child,
                                ),
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

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        _statusText(isAr),
                        key: ValueKey(_statusKey),
                        style: titleFont(
                          color: AppColors.goldAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
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

                    SizedBox(
                      width: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.08),
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
