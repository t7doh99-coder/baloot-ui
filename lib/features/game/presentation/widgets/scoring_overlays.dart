import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/game_l10n.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../data/models/card_model.dart' show GameMode;
import '../../../../data/models/round_state_model.dart' show DoubleStatus;
import '../game_provider.dart';
import '../../../../core/services/player_stats_service.dart';
import '../../../../core/services/rank_calculator.dart';
import 'rank_badge_widget.dart';

// ══════════════════════════════════════════════════════════════════
//  ROUND SCORE OVERLAY — Kammelna-style breakdown + Majlis charcoal theme
//
//  • Charcoal panel (matches table HUD), gold accent border
//  • Rows: Tricks, Ground, Projects, Points (Abnat), Result — AR when locale ar
//  • Exit / Play again below the card (not inside the border)
// ══════════════════════════════════════════════════════════════════

class RoundScoreOverlay extends StatefulWidget {
  const RoundScoreOverlay({super.key});

  @override
  State<RoundScoreOverlay> createState() => _RoundScoreOverlayState();
}

class _RoundScoreOverlayState extends State<RoundScoreOverlay> with TickerProviderStateMixin {
  late final AnimationController _trophyController;
  late final AnimationController _particlesController;
  final List<_ScoreParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _trophyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _initParticles();
  }

  void _initParticles() {
    final rnd = math.Random();
    final colors = [
      const Color(0xFFC49028),
      const Color(0xFF00E87A),
      const Color(0xFFFF3D3D),
      const Color(0xFFF0D47A),
      const Color(0xFFFFFFFF),
    ];
    for (int i = 0; i < 32; i++) {
      _particles.add(_ScoreParticle(
        id: i,
        x: 0.05 + rnd.nextDouble() * 0.9,
        y: 0.3 + rnd.nextDouble() * 0.65,
        size: 3.0 + rnd.nextDouble() * 4.5,
        color: colors[rnd.nextInt(colors.length)],
        speed: 0.2 + rnd.nextDouble() * 0.35,
        isStar: rnd.nextBool(),
        phase: rnd.nextDouble() * 1.0,
      ));
    }
  }

  @override
  void dispose() {
    _trophyController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isAr = context.watch<LocaleProvider>().isArabic;
    final r = game.lastRoundResult;
    final total = game.gameScore;
    if (r == null) return const SizedBox.shrink();

    final isUsWon = r.teamAPoints >= r.teamBPoints;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.62),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status banner above scoreboard box
                    _buildStatusBanner(isAr, isUsWon),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF392C14),
                            Color(0xFF2C2210),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFFC49028).withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.12),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                            blurStyle: BlurStyle.inner,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Combined top black section (`_buildHeroPanel` + `_buildGameInfoCards`) with full-section particles ──
                            Stack(
                              children: [
                                // 1. Black backgrounds stacked cleanly
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildHeroPanel(isAr, r, total, onlyBg: true),
                                    _buildGameInfoCards(isAr, r, onlyBg: true),
                                  ],
                                ),
                                // 2. Animated floating particles rising across the ENTIRE top black section
                                Positioned.fill(
                                  child: ClipRect(
                                    child: AnimatedBuilder(
                                      animation: _particlesController,
                                      builder: (context, _) {
                                        return CustomPaint(
                                          painter: _ScoreParticlePainter(_particles, _particlesController.value),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                // 3. Crisp foreground content (`THEM 30`, `US 0`, `VS` coin, and the two inner cards)
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildHeroPanel(isAr, r, total, onlyContent: true),
                                    _buildGameInfoCards(isAr, r, onlyContent: true),
                                  ],
                                ),
                              ],
                            ),

                            // ── Stats table ──
                            _buildStatsTable(isAr, r),

                            // ── Result row ──
                            _buildResultRow(isAr, r),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(bool isAr, bool isUsWon) {
    return AnimatedBuilder(
      animation: _trophyController,
      builder: (context, _) {
        final t = math.sin(_trophyController.value * math.pi * 2);
        final offset = t * -4.0;
        return Transform.translate(
          offset: Offset(0, offset),
          child: Text(
            isUsWon
                ? (isAr ? 'فريقك فاز' : 'YOUR TEAM WON')
                : (isAr ? 'فريقك خسر' : 'YOUR TEAM LOST'),
            textAlign: TextAlign.center,
            style: GoogleFonts.readexPro(
              color: isUsWon ? const Color(0xFF00E87A) : const Color(0xFFFF3D3D),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.5,
              shadows: [
                BoxShadow(
                  color: (isUsWon ? const Color(0xFF00E87A) : const Color(0xFFFF3D3D)).withValues(alpha: 0.8),
                  blurRadius: 16,
                ),
                BoxShadow(
                  color: (isUsWon ? const Color(0xFF00E87A) : const Color(0xFFFF3D3D)).withValues(alpha: 0.4),
                  blurRadius: 32,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroPanel(bool isAr, dynamic r, dynamic total, {bool onlyBg = false, bool onlyContent = false}) {
    if (onlyBg) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0E0B05),
              Color(0xFF080603),
            ],
          ),
        ),
        child: Opacity(
          opacity: 0,
          child: _buildHeroPanel(isAr, r, total, onlyContent: true),
        ),
      );
    }

    return Container(
      decoration: onlyContent ? const BoxDecoration(color: Colors.transparent) : const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0E0B05),
            Color(0xFF080603),
          ],
        ),
      ),
      child: Stack(
        children: [
          if (!onlyContent && !onlyBg)
            Positioned.fill(
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _particlesController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ScoreParticlePainter(_particles, _particlesController.value),
                    );
                  },
                ),
              ),
            ),
          // Top border shimmer
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0xFFFF3D3D),
                    Color(0xFFC9A84C),
                    Color(0xFF00E87A),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main scores and trophy content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
            child: Row(
              children: [
                // THEM side (Team B)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        isAr ? 'لهم' : 'THEM',
                        style: GoogleFonts.readexPro(
                          color: const Color(0xFFFF3D3D),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.5,
                          shadows: [
                            BoxShadow(
                              color: const Color(0xFFFF3D3D).withValues(alpha: 0.6),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${r.teamBPoints}',
                        style: GoogleFonts.readexPro(
                          color: const Color(0xFFFF3D3D),
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          shadows: [
                            BoxShadow(
                              color: const Color(0xFFFF3D3D).withValues(alpha: 0.8),
                              blurRadius: 18,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF3D3D).withValues(alpha: 0.3),
                              blurRadius: 36,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAr ? '${total.teamB} الإجمالي' : '${total.teamB} TOTAL',
                        style: GoogleFonts.readexPro(
                          color: const Color(0xFFC9A84C).withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Center VS
                AnimatedBuilder(
                  animation: _trophyController,
                  builder: (context, child) {
                    final t = math.sin(_trophyController.value * math.pi * 2);
                    final offset = t * -5.0;
                    final angle = t * (2.0 * math.pi / 180.0);
                    return Transform.translate(
                      offset: Offset(0, offset),
                      child: Transform.rotate(
                        angle: angle,
                        child: Image.asset(
                          'assets/images/2d_vs_icon.png',
                          width: 68,
                          height: 68,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    );
                  },
                ),
                // US side (Team A)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        isAr ? 'فريقنا' : 'US',
                        style: GoogleFonts.readexPro(
                          color: const Color(0xFF00E87A),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.5,
                          shadows: [
                            BoxShadow(
                              color: const Color(0xFF00E87A).withValues(alpha: 0.6),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${r.teamAPoints}',
                        style: GoogleFonts.readexPro(
                          color: const Color(0xFF00E87A),
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          shadows: [
                            BoxShadow(
                              color: const Color(0xFF00E87A).withValues(alpha: 0.8),
                              blurRadius: 18,
                            ),
                            BoxShadow(
                              color: const Color(0xFF00E87A).withValues(alpha: 0.3),
                              blurRadius: 36,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAr ? '${total.teamA} الإجمالي' : '${total.teamA} TOTAL',
                        style: GoogleFonts.readexPro(
                          color: const Color(0xFFC9A84C).withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameInfoCards(bool isAr, dynamic r, {bool onlyBg = false, bool onlyContent = false}) {
    if (onlyBg) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF0A0805),
        ),
        child: Opacity(
          opacity: 0,
          child: _buildGameInfoCards(isAr, r, onlyContent: true),
        ),
      );
    }

    final modeText = r.mode == GameMode.sun ? (isAr ? 'صن' : 'Sun') : (isAr ? 'حكم' : 'Hakam');
    final buyerSide = r.buyerTeam == 'A' ? (isAr ? 'فريقنا' : 'Our team') : (isAr ? 'فريقهم' : 'Their team');
    final buyerColor = r.buyerTeam == 'A' ? const Color(0xFF00E87A) : const Color(0xFFFF3D3D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: onlyContent ? const BoxDecoration(color: Colors.transparent) : const BoxDecoration(
        color: Color(0xFF0A0805),
      ),
      child: Row(
        children: [
          // Left card: Game Type
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF141008),
                    Color(0xFF0E0B05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC49028).withValues(alpha: 0.35), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isAr ? 'نوع اللعبة' : 'GAME TYPE',
                    style: GoogleFonts.readexPro(
                      color: const Color(0xFFC9A84C),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    modeText,
                    style: GoogleFonts.readexPro(
                      color: const Color(0xFFD4AF37),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Right card: Buyer
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF141008),
                    Color(0xFF0E0B05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC49028).withValues(alpha: 0.35), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isAr ? 'المشتري' : 'BUYER',
                    style: GoogleFonts.readexPro(
                      color: const Color(0xFFC9A84C),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    buyerSide,
                    style: GoogleFonts.readexPro(
                      color: buyerColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        BoxShadow(
                          color: buyerColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTable(bool isAr, dynamic r) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0C0A06),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFC49028).withValues(alpha: 0.12),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFC49028).withValues(alpha: 0.25)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isAr ? 'الأكلات' : 'Tricks',
                    style: GoogleFonts.readexPro(
                      color: const Color(0xFFC9A84C).withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    isAr ? 'لهم' : 'THEM',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.readexPro(
                      color: const Color(0xFFFF3D3D),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    isAr ? 'فريقنا' : 'US',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.readexPro(
                      color: const Color(0xFF00E87A),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Row 1: Tricks
          _buildTableRow(
            isAr ? 'الأكلات' : 'Tricks',
            '${r.teamBTrickAbnat}',
            '${r.teamATrickAbnat}',
          ),
          // Row 2: Projects
          _buildTableRow(
            isAr ? 'المشاريع' : 'Projects',
            '${r.teamBProjectAbnat}',
            '${r.teamAProjectAbnat}',
          ),
          // Row 3: Trick points
          _buildTableRow(
            isAr ? 'أبناط الأكل' : 'Trick points',
            '${r.teamBPoints}',
            '${r.teamAPoints}',
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String label, String themVal, String usVal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFFC9A84C).withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.readexPro(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              themVal,
              textAlign: TextAlign.center,
              style: GoogleFonts.readexPro(
                color: const Color(0xFFFF3D3D),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              usVal,
              textAlign: TextAlign.center,
              style: GoogleFonts.readexPro(
                color: const Color(0xFF00E87A),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(bool isAr, dynamic r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2210),
        border: Border(
          top: BorderSide(color: const Color(0xFFC49028).withValues(alpha: 0.45), width: 1.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isAr ? 'نتيجة الجولة' : 'ROUND RESULT',
              style: GoogleFonts.readexPro(
                color: const Color(0xFFC49028),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '${r.teamBPoints}',
              textAlign: TextAlign.center,
              style: GoogleFonts.readexPro(
                color: const Color(0xFFFF3D3D),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                shadows: [
                  BoxShadow(
                    color: const Color(0xFFFF3D3D).withValues(alpha: 0.6),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '${r.teamAPoints}',
              textAlign: TextAlign.center,
              style: GoogleFonts.readexPro(
                color: const Color(0xFF00E87A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                shadows: [
                  BoxShadow(
                    color: const Color(0xFF00E87A).withValues(alpha: 0.6),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreParticle {
  final int id;
  final double x;
  final double y;
  final double size;
  final Color color;
  final double speed;
  final bool isStar;
  final double phase;

  _ScoreParticle({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.isStar,
    required this.phase,
  });
}

class _ScoreParticlePainter extends CustomPainter {
  final List<_ScoreParticle> particles;
  final double progress;

  _ScoreParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final yPos = size.height * (0.95 - t * 0.9);
      final xPos = p.x * size.width;
      final opacity = (1.0 - t).clamp(0.0, 1.0);

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = p.color.withValues(alpha: opacity * 0.85);

      if (p.isStar) {
        canvas.save();
        canvas.translate(xPos, yPos);
        canvas.rotate(math.pi / 4);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size), paint);
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(xPos, yPos), p.size / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreParticlePainter oldDelegate) => true;
}

// ══════════════════════════════════════════════════════════════════
//  GAME OVER OVERLAY — full screen when [GamePhase.gameOver]
// ══════════════════════════════════════════════════════════════════

class GameOverOverlay extends StatefulWidget {
  const GameOverOverlay({super.key});

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay> {

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    context.watch<LocaleProvider>();
    final loc = GameL10n.of(context);
    final total = game.gameScore;
    final lastRound = game.lastRoundResult;
    final winner = game.gameWinner;

    final humanWon = game.didHumanWinGame;
    final gahwa = game.roundState.doubleStatus == DoubleStatus.gahwa;
    final title = gahwa
        ? loc.gahwaTitle
        : humanWon
            ? loc.youWin
            : loc.youLose;

    final outcome = game.lastMatchOutcome;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    humanWon ? Icons.emoji_events : Icons.sentiment_neutral,
                    size: 56,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.goldAccent,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 0.5,
                    ),
                  ),
                  if (winner != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        loc.teamReachedTarget(winner == 'A', context.read<GameProvider>().targetScore),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _StarRow(won: humanWon || gahwa),
                  const SizedBox(height: 22),
                  
                  if (outcome != null)
                    _buildPointsBreakdown(context, outcome, loc),
                  
                  if (outcome != null) ...[
                    const SizedBox(height: 20),
                    _buildRankProgress(context, outcome, loc),
                  ],
                  
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1810),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.goldAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(loc.finalScore,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            )),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${total.teamA}',
                                style: const TextStyle(
                                  color: Color(0xFF28802E),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                )),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('\u2014',
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.3),
                                    fontSize: 24,
                                  )),
                            ),
                            Text('${total.teamB}',
                                style: const TextStyle(
                                  color: Color(0xFFE63946),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                )),
                          ],
                        ),
                        if (lastRound != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            loc.lastRoundPts(
                              lastRound.teamAPoints,
                              lastRound.teamBPoints,
                            ),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            context.read<GameProvider>().leaveTable();
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(loc.exitGame),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<GameProvider>().restartGame();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldAccent,
                            foregroundColor: const Color(0xFF1E1810),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            loc.playAgain,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointsBreakdown(BuildContext context, MatchOutcome outcome, GameL10n loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1810),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildBreakdownRow(loc.pointsBase, '+${outcome.result.basePoints}'),
          if (outcome.result.rankGapBonus != 0)
            _buildBreakdownRow(loc.pointsRankGap, '${outcome.result.rankGapBonus > 0 ? '+' : ''}${outcome.result.rankGapBonus}'),
          if (outcome.result.streakBonus > 0)
            _buildBreakdownRow(loc.pointsStreakBonus, '+${outcome.result.streakBonus}'),
          if (outcome.result.wasCapped)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(loc.botCapApplied, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
            ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(loc.totalStars, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${outcome.result.blueStarsChange > 0 ? '+' : ''}${outcome.result.blueStarsChange}',
                        style: TextStyle(
                          color: outcome.result.blueStarsChange > 0 ? AppColors.goldAccent : Colors.redAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: AppColors.goldAccent, size: 20),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  Text(loc.totalMedals, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '+${outcome.result.medalsChange}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.emoji_events, color: Colors.orangeAccent, size: 20),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRankProgress(BuildContext context, MatchOutcome outcome, GameL10n loc) {
    final progress = RankCalculator.progressToNextSubLevel(outcome.newMedals);
    final medalsNeeded = RankCalculator.medalsToNextSubLevel(outcome.newMedals);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1810),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.rankProgress, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              if (outcome.rankedUp)
                Text(loc.rankUp, style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              RankBadgeWidget(rank: outcome.newRank, compact: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(outcome.newRank.badgeColor),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      medalsNeeded == 0 ? 'Max Rank' : loc.medalsToNext(medalsNeeded),
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final bool won;
  const _StarRow({required this.won});

  @override
  Widget build(BuildContext context) {
    final n = won ? 5 : 2;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < n;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(
            filled ? Icons.star : Icons.star_border,
            color: filled
                ? AppColors.goldAccent
                : Colors.white.withValues(alpha: 0.2),
            size: 28,
          ),
        );
      }),
    );
  }
}
