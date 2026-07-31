import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/game_l10n.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../data/models/card_model.dart' show GameMode;
import '../../../../data/models/round_state_model.dart' show DoubleStatus, DeclaredProject, ProjectType;
import '../game_provider.dart';
import '../../../../core/services/player_stats_service.dart';
import '../../../../core/services/rank_calculator.dart';
import '../../../../core/services/points_calculator.dart';
import '../../../../data/models/rank_tier.dart';
import 'rank_badge_widget.dart';

// ══════════════════════════════════════════════════════════════════
//  ROUND SCORE OVERLAY — Standard-style breakdown + Majlis charcoal theme
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
                    _buildStatusBanner(isAr, r),
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

                            // ── Multiplier badge ──
                            if (r.doubleStatus != DoubleStatus.none) _buildMultiplierBadge(isAr, r),

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

  Widget _buildStatusBanner(bool isAr, dynamic r) {
    final buyerIsUs = r.buyerTeam == 'A';
    final weWon = r.winningTeam == 'A';

    String message;
    Color color;

    if (r.isKabout) {
      message = isAr ? '🏆 كبوت!!' : '🏆 KABOOT!!';
      color = const Color(0xFFFFD700);
    } else if (r.teamAPoints == r.teamBPoints) {
      message = isAr ? 'سوا — تعادل' : 'SAWA — Draw';
      color = const Color(0xFFC9A84C);
    } else if (r.isKhams) {
      if (buyerIsUs) {
        message = isAr ? 'شرائنا: خسرنا 💔' : 'Our Purchase: Lost';
        color = const Color(0xFFFF3D3D);
      } else {
        message = isAr ? 'شرائهم: خسروا 🎉' : 'Their Purchase: Lost — We Win!';
        color = const Color(0xFF00E87A);
      }
    } else if (buyerIsUs) {
      if (weWon) {
        message = isAr ? 'شرائنا: فزنا ✓' : 'Our Purchase: Won ✓';
        color = const Color(0xFF00E87A);
      } else {
        message = isAr ? 'شرائنا: خسرنا' : 'Our Purchase: Lost';
        color = const Color(0xFFFF3D3D);
      }
    } else {
      if (weWon) {
        message = isAr ? 'شرائهم: خسروا 🎉' : 'Their Purchase: Lost — We Win!';
        color = const Color(0xFF00E87A);
      } else {
        message = isAr ? 'شرائهم: فازوا' : 'Their Purchase: Won';
        color = const Color(0xFFFF3D3D);
      }
    }

    return AnimatedBuilder(
      animation: _trophyController,
      builder: (context, _) {
        final t = math.sin(_trophyController.value * math.pi * 2);
        final offset = t * -4.0;
        return Transform.translate(
          offset: Offset(0, offset),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.readexPro(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: isAr ? 0 : 2.0,
              shadows: [
                BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 16),
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 32),
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
                          letterSpacing: isAr ? 0 : 3.5,
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
                          letterSpacing: isAr ? 0 : 3.5,
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
                      letterSpacing: isAr ? 0 : 2.0,
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
                      letterSpacing: isAr ? 0 : 2.0,
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
    final teamAGround = r.lastTrickBonusTeam == 'A' ? 10 : 0;
    final teamBGround = r.lastTrickBonusTeam == 'B' ? 10 : 0;
    // teamATrickAbnat from engine already includes the +10 ground bonus,
    // so subtract it for the pure card-points display (Row 1).
    final teamAPureCards = (r.teamATrickAbnat as int) - teamAGround;
    final teamBPureCards = (r.teamBTrickAbnat as int) - teamBGround;
    // Subtotal = pure cards + ground = original teamATrickAbnat (unchanged)
    final teamATrickPts = r.teamATrickAbnat as int;
    final teamBTrickPts = r.teamBTrickAbnat as int;

    return Container(
      decoration: const BoxDecoration(color: Color(0xFF0C0A06)),
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
                    isAr ? 'البيان' : 'Details',
                    style: GoogleFonts.readexPro(
                      color: const Color(0xFFC9A84C).withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: isAr ? 0 : 1.5,
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
                      letterSpacing: isAr ? 0 : 1.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    isAr ? 'لنا' : 'US',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.readexPro(
                      color: const Color(0xFF00E87A),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: isAr ? 0 : 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Row 1: Tricks (pure card points from tricks — no ground bonus)
          _buildTableRow(
            label: isAr ? 'الأوراق / الأبناط' : 'Tricks',
            sub: isAr ? 'نقاط أوراق الأكلات' : 'card pts won in tricks',
            themVal: '$teamBPureCards',
            usVal: '$teamAPureCards',
          ),
          // Row 2: Ground (+10 last trick bonus)
          _buildTableRow(
            label: isAr ? 'الأرضية' : 'Ground',
            sub: isAr ? 'مكافأة آخر أكلة' : 'last trick bonus (+10)',
            themVal: teamBGround > 0 ? '+$teamBGround' : '0',
            usVal: teamAGround > 0 ? '+$teamAGround' : '0',
          ),
          // Row 3: Projects — individual declaration breakdown
          ..._buildProjectRows(isAr, r),
          // Baloot sub-row (always scores independently, even if project comparison lost)
          if (r.balootTeam != null) _buildBalootRow(isAr, r),
          // Row 4: Trick pts subtotal = Tricks + Ground (before conversion)
          _buildTableRow(
            label: isAr ? 'نقاط الأوراق' : 'Trick pts',
            sub: isAr ? 'صف 1 + صف 2' : 'row 1 + row 2',
            themVal: '$teamBTrickPts',
            usVal: '$teamATrickPts',
            isSubtotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow({
    required String label,
    String? sub,
    required String themVal,
    required String usVal,
    bool isSubtotal = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: isSubtotal ? 13 : 10),
      decoration: BoxDecoration(
        color: isSubtotal ? const Color(0xFFC49028).withValues(alpha: 0.06) : null,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFC9A84C).withValues(alpha: 0.08)),
          top: isSubtotal
              ? BorderSide(color: const Color(0xFFC49028).withValues(alpha: 0.2))
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.readexPro(
                    color: isSubtotal ? const Color(0xFFC9A84C) : Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: isSubtotal ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: GoogleFonts.readexPro(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              themVal,
              textAlign: TextAlign.center,
              style: GoogleFonts.readexPro(
                color: const Color(0xFFFF3D3D),
                fontSize: isSubtotal ? 15 : 14,
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
                fontSize: isSubtotal ? 15 : 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalootRow(bool isAr, dynamic r) {
    final balootIsUs = r.balootTeam == 'A';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFC49028).withValues(alpha: 0.07),
        border: Border(
          bottom: BorderSide(color: const Color(0xFFC9A84C).withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Text('⭐', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isAr ? 'بلوت' : 'Baloot',
              style: GoogleFonts.readexPro(
                color: const Color(0xFFC9A84C),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              balootIsUs ? '0' : '+2',
              textAlign: TextAlign.center,
              style: GoogleFonts.readexPro(
                color: balootIsUs ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFFF3D3D),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              balootIsUs ? '+2' : '0',
              textAlign: TextAlign.center,
              style: GoogleFonts.readexPro(
                color: balootIsUs ? const Color(0xFF00E87A) : Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplierBadge(bool isAr, dynamic r) {
    String label;
    switch (r.doubleStatus) {
      case DoubleStatus.doubled:
        label = isAr ? '× 2 — دبل' : '× 2 — Double';
        break;
      case DoubleStatus.tripled:
        label = isAr ? '× 3 — تربل' : '× 3 — Triple';
        break;
      case DoubleStatus.four:
        label = isAr ? '× 4 — فور' : '× 4 — Four';
        break;
      case DoubleStatus.gahwa:
        label = isAr ? 'قهوة ☕' : 'Gahwa ☕';
        break;
      default:
        label = '';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFB8860B).withValues(alpha: 0.25),
            const Color(0xFFC49028).withValues(alpha: 0.15),
          ],
        ),
        border: Border(
          top: BorderSide(color: const Color(0xFFC49028).withValues(alpha: 0.4)),
          bottom: BorderSide(color: const Color(0xFFC49028).withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.readexPro(
              color: const Color(0xFFFFD700),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: isAr ? 0 : 2.0,
            ),
          ),
          const SizedBox(width: 8),
          const Text('⚡', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  List<Widget> _buildProjectRows(bool isAr, dynamic r) {
    final teamAProjects = (r.teamAProjectsList as List).cast<DeclaredProject>();
    final teamBProjects = (r.teamBProjectsList as List).cast<DeclaredProject>();

    final aHasProjects = (r.teamAProjectAbnat as int) > 0;
    final bHasProjects = (r.teamBProjectAbnat as int) > 0;

    // Filter out Baloot (handled separately in its own row)
    final showA = teamAProjects.where((p) => p.type != ProjectType.baloot).toList();
    final showB = teamBProjects.where((p) => p.type != ProjectType.baloot).toList();

    // No projects from either team
    if (!aHasProjects && !bHasProjects || (showA.isEmpty && showB.isEmpty)) {
      return [
        _buildTableRow(
          label: isAr ? 'المشاريع' : 'Projects',
          sub: isAr ? 'لا توجد تصريحات' : 'no combo declarations',
          themVal: '0',
          usVal: '0',
        ),
      ];
    }

    final List<Widget> rows = [];

    // Section header row
    rows.add(_buildProjectSectionHeader(isAr));

    // Team B (THEM) projects — only if they won the comparison
    if (bHasProjects) {
      for (final proj in showB) {
        rows.add(_buildProjectItemRow(
          isAr: isAr,
          name: _projectName(isAr, proj.type),
          abnat: proj.getAbnat(r.mode as GameMode),
          isUsProject: false,
        ));
      }
    }

    // Team A (US) projects — only if they won the comparison
    if (aHasProjects) {
      for (final proj in showA) {
        rows.add(_buildProjectItemRow(
          isAr: isAr,
          name: _projectName(isAr, proj.type),
          abnat: proj.getAbnat(r.mode as GameMode),
          isUsProject: true,
        ));
      }
    }

    return rows;
  }

  Widget _buildProjectSectionHeader(bool isAr) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFFC9A84C).withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Text(
            isAr ? 'المشاريع' : 'Projects',
            style: GoogleFonts.readexPro(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isAr ? 'تفاصيل التصريحات' : 'declaration breakdown',
            style: GoogleFonts.readexPro(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 9.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectItemRow({
    required bool isAr,
    required String name,
    required int abnat,
    required bool isUsProject,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFFC9A84C).withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Text('—', style: TextStyle(color: const Color(0xFFC9A84C).withValues(alpha: 0.6), fontSize: 11)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.readexPro(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              isUsProject ? '—' : '+$abnat',
              textAlign: TextAlign.center,
              style: GoogleFonts.readexPro(
                color: isUsProject
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFFF3D3D),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              isUsProject ? '+$abnat' : '—',
              textAlign: TextAlign.center,
              style: GoogleFonts.readexPro(
                color: isUsProject
                    ? const Color(0xFF00E87A)
                    : Colors.white.withValues(alpha: 0.25),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _projectName(bool isAr, ProjectType type) {
    switch (type) {
      case ProjectType.sera:         return isAr ? 'سرا' : 'Sra';
      case ProjectType.fifty:        return isAr ? 'خمسين' : 'Khamsin';
      case ProjectType.hundred:      return isAr ? 'مية' : 'Mia (100)';
      case ProjectType.sixCardRun:   return isAr ? 'سرا 6 أوراق' : '6-card Run';
      case ProjectType.sevenCardRun: return isAr ? 'سرا 7 أوراق' : '7-card Run';
      case ProjectType.eightCardRun: return isAr ? 'سرا 8 أوراق' : '8-card Run';
      case ProjectType.fourJacks:    return isAr ? 'أربع جكر' : 'Four Jacks';
      case ProjectType.fourHundred:  return isAr ? 'أربعمية (4 آسات)' : '400 (4 Aces)';
      case ProjectType.baloot:       return isAr ? 'بلوت' : 'Baloot';
    }
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
                letterSpacing: isAr ? 0 : 2.0,
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
    
    // Outcome fallback for real game data
    final liveOutcome = game.lastMatchOutcome;
    final outcome = liveOutcome ?? MatchOutcome(
      result: const PointResult(baseExchange: 0, streakBonus: 0, blueStarsChange: 0, heartsChange: 0, explanation: ''),
      oldRank: const RankTier(mainRank: MainRank.beginner, subLevel: 1),
      newRank: const RankTier(mainRank: MainRank.beginner, subLevel: 1),
      rankedUp: false, rankedDown: false, starsChange: 0,
      oldStars: 0, newStars: 0, oldMedals: 0, newMedals: 0,
      newAchievements: const [],
    );

    final teamA = total.teamA;
    final teamB = total.teamB;
    
    final humanWon = game.didHumanWinGame;
    final isArabic = context.read<LocaleProvider>().isArabic;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.95),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      humanWon ? (isArabic ? 'فوز' : 'WIN') : (isArabic ? 'خسارة' : 'LOSS'),
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: humanWon ? const Color(0xFF00E87A) : const Color(0xFFFF3D3D),
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: (humanWon ? const Color(0xFF00E87A) : const Color(0xFFFF3D3D)).withValues(alpha: 0.75),
                            blurRadius: 25,
                          ),
                          Shadow(
                            color: (humanWon ? const Color(0xFF00E87A) : const Color(0xFFFF3D3D)).withValues(alpha: 0.35),
                            blurRadius: 50,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (liveOutcome != null) ...[
                      _buildPointsBreakdown(context, outcome, loc, isArabic),
                      const SizedBox(height: 20),
                      _buildRankProgress(context, outcome, loc),
                      const SizedBox(height: 22),
                    ],

                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0B09),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.goldAccent.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 2.5,
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
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 24, horizontal: 16),
                              child: Column(
                                children: [
                                  Text(
                                    loc.finalScore.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 2,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // THEM / Team B (Red)
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              isArabic ? 'الخصوم' : 'THEM',
                                              style: TextStyle(
                                                color: const Color(0xFFFF3D3D),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: isArabic ? 0 : 3,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '$teamB',
                                              style: TextStyle(
                                                fontFamily: 'Georgia',
                                                fontSize: 56,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFFFF3D3D),
                                                height: 1.0,
                                                shadows: [
                                                  Shadow(
                                                    color: const Color(0xFFFF3D3D)
                                                        .withValues(alpha: 0.75),
                                                    blurRadius: 25,
                                                  ),
                                                  Shadow(
                                                    color: const Color(0xFFFF3D3D)
                                                        .withValues(alpha: 0.35),
                                                    blurRadius: 50,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              isArabic ? 'نقاط' : 'POINTS',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: const Color(0xFFFF3D3D)
                                                    .withValues(alpha: 0.5),
                                                letterSpacing: isArabic ? 0 : 1.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Small separation line like before
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(
                                          '\u2014',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.35),
                                            fontSize: 32,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ),
                                      // US / Team A (Green)
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              isArabic ? 'فريقنا' : 'US',
                                              style: TextStyle(
                                                color: const Color(0xFF00E87A),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: isArabic ? 0 : 3,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '$teamA',
                                              style: TextStyle(
                                                fontFamily: 'Georgia',
                                                fontSize: 56,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFF00E87A),
                                                height: 1.0,
                                                shadows: [
                                                  Shadow(
                                                    color: const Color(0xFF00E87A)
                                                        .withValues(alpha: 0.75),
                                                    blurRadius: 25,
                                                  ),
                                                  Shadow(
                                                    color: const Color(0xFF00E87A)
                                                        .withValues(alpha: 0.35),
                                                    blurRadius: 50,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              isArabic ? 'نقاط' : 'POINTS',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: const Color(0xFF00E87A)
                                                    .withValues(alpha: 0.5),
                                                letterSpacing: isArabic ? 0 : 1.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: _build3DButton(
                            text: loc.exitGame,
                            isPrimary: false,
                            isDanger: true,
                            onTap: () {
                              context.read<GameProvider>().leaveTable();
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _build3DButton(
                            text: loc.playAgain,
                            isPrimary: true,
                            onTap: () {
                              context.read<GameProvider>().restartGame();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DButton({
    required String text,
    required VoidCallback onTap,
    required bool isPrimary,
    bool isDanger = false,
  }) {
    final outerBorderColor = Colors.black;
    final innerBorderColor = isDanger
        ? const Color(0xFFFF6666)
        : (isPrimary ? const Color(0xFFFFE066) : const Color(0xFF888888));
    final gradientColors = isDanger
        ? const [Color(0xFFE63030), Color(0xFF9E1010)]
        : (isPrimary
            ? const [Color(0xFFE6A330), Color(0xFF9E6510)]
            : const [Color(0xFF3A3A3A), Color(0xFF1A1A1A)]);
    final textColor = isDanger || isPrimary ? Colors.white : Colors.white70;

    return GestureDetector(
      onTap: () {
        if (isPrimary) {
          context.read<GameProvider>().audioService.playGoldButton();
        } else {
          context.read<GameProvider>().audioService.playNormalButton();
        }
        onTap();
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: outerBorderColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: innerBorderColor,
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 1.0,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointsBreakdown(BuildContext context, MatchOutcome outcome, GameL10n loc, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1810),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildBreakdownRow(
            isArabic ? 'نتيجة المباراة' : 'Match Result',
            '', // Value removed per user request
          ),
          if (outcome.result.rankGapBonus != 0)
            _buildBreakdownRow(
              loc.pointsRankGap,
              '${outcome.result.rankGapBonus > 0 ? '+' : ''}${outcome.result.rankGapBonus}',
            ),
          if (outcome.result.streakBonus > 0)
            _buildBreakdownRow(
              loc.pointsStreakBonus,
              '+${outcome.result.streakBonus}',
            ),
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
                      Image.asset('assets/icons/gold_star.png', width: 24, height: 24),
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
                      Image.asset('assets/icons/medal.png', width: 24, height: 24),
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
    final progress = RankCalculator.progressToNextSubLevel(outcome.newStars);
    final medalsNeeded = RankCalculator.starsToNextSubLevel(outcome.newStars, outcome.newStars);
    
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