import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TestScreen6 extends StatefulWidget {
  final bool isArabic;

  const TestScreen6({
    super.key,
    required this.isArabic,
  });

  @override
  State<TestScreen6> createState() => _TestScreen6State();
}

class _TestScreen6State extends State<TestScreen6> with TickerProviderStateMixin {
  late AnimationController _trophyController;
  late AnimationController _shimmerController;
  late AnimationController _particlesController;
  late AnimationController _pulseController;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _trophyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _initParticles();
  }

  void _initParticles() {
    final rnd = math.Random();
    final colors = [
      const Color(0xFFC9A84C),
      const Color(0xFF00E87A),
      const Color(0xFFFF3D3D),
      const Color(0xFFF0D47A),
      const Color(0xFFFFFFFF),
    ];
    for (int i = 0; i < 28; i++) {
      _particles.add(_Particle(
        id: i,
        x: 0.05 + rnd.nextDouble() * 0.9,
        y: 0.4 + rnd.nextDouble() * 0.55,
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
    _shimmerController.dispose();
    _particlesController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status banner above scoreboard box
                      _buildStatusBanner(isAr, true), // true = won (usScore 21 > themScore 5)
                      const SizedBox(height: 16),
                      Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFC9A84C).withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Hero panel — split rivalry (with particles inside) ──
                          _buildHeroPanel(isAr),

                          // ── Game info cards (Game Type & Buyer) in circle area ──
                          _buildGameInfoCards(isAr),

                          // ── Stats table ──
                          _buildStatsTable(isAr),

                          // ── Result row ──
                          _buildResultRow(isAr),
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
    );
  }

  Widget _buildHeroPanel(bool isAr) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0E0B05),
            Color(0xFF080603),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: const Color(0xFFC9A84C).withValues(alpha: 0.25), width: 1),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Particles rising ONLY inside this hero panel container (`overflow: hidden`)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particlesController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _HeroParticlePainter(_particles, _particlesController.value),
                );
              },
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
                // THEM side
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        isAr ? 'الخصوم' : 'THEM',
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
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final blur = 25.0 + _pulseController.value * 15.0;
                          return Text(
                            '5',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 62,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFFF3D3D),
                              height: 1.0,
                              shadows: [
                                Shadow(color: const Color(0xFFFF3D3D).withValues(alpha: 0.8), blurRadius: blur),
                                Shadow(color: const Color(0xFFFF3D3D).withValues(alpha: 0.4), blurRadius: blur * 2),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isAr ? 'نقاط' : 'POINTS',
                        style: GoogleFonts.readexPro(
                          fontSize: 10,
                          color: const Color(0xFFFF3D3D).withValues(alpha: 0.45),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Center Trophy and VS
                AnimatedBuilder(
                  animation: _trophyController,
                  builder: (context, child) {
                    // @keyframes troFloat: translateY(-10px) rotate(2deg)
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
                // US side
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
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final blur = 25.0 + _pulseController.value * 15.0;
                          return Text(
                            '21',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 62,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF00E87A),
                              height: 1.0,
                              shadows: [
                                Shadow(color: const Color(0xFF00E87A).withValues(alpha: 0.8), blurRadius: blur),
                                Shadow(color: const Color(0xFF00E87A).withValues(alpha: 0.4), blurRadius: blur * 2),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isAr ? 'نقاط' : 'POINTS',
                        style: GoogleFonts.readexPro(
                          fontSize: 10,
                          color: const Color(0xFF00E87A).withValues(alpha: 0.45),
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

  Widget _buildGameInfoCards(bool isAr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
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
                border: Border.all(color: const Color(0xFFC9A84C).withValues(alpha: 0.35), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC9A84C).withValues(alpha: 0.08),
                    blurRadius: 8,
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
                    isAr ? 'صن' : 'Sun',
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
                border: Border.all(color: const Color(0xFFC9A84C).withValues(alpha: 0.35), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC9A84C).withValues(alpha: 0.08),
                    blurRadius: 8,
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
                    isAr ? 'فريقنا' : 'Our team',
                    style: GoogleFonts.readexPro(
                      color: const Color(0xFF00E87A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        BoxShadow(
                          color: const Color(0xFF00E87A).withValues(alpha: 0.5),
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

  Widget _buildStatsTable(bool isAr) {
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
              color: const Color(0xFFC9A84C).withValues(alpha: 0.04),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFC9A84C).withValues(alpha: 0.18)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isAr ? 'الفئة' : 'CATEGORY',
                    style: GoogleFonts.readexPro(
                      color: const Color(0xFFC9A84C).withValues(alpha: 0.35),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    isAr ? 'الخصوم' : 'THEM',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.readexPro(
                      color: const Color(0xFFFF3D3D),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      shadows: [
                        BoxShadow(
                          color: const Color(0xFFFF3D3D).withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    isAr ? 'فريقنا' : 'US',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.readexPro(
                      color: const Color(0xFF00E87A),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      shadows: [
                        BoxShadow(
                          color: const Color(0xFF00E87A).withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table rows
          _buildStatRow(label: isAr ? 'الأوراق (TRICKS)' : 'TRICKS', them: '24', us: '86'),
          _buildStatRow(label: isAr ? 'الأرضية (GROUND)' : 'GROUND', them: '—', us: '10'),
          _buildStatRow(label: isAr ? 'المشاريع (PROJECTS)' : 'PROJECTS', them: '—', us: '—'),
          _buildStatRow(
            label: isAr ? 'نقاط الأوراق (TRICK PTS)' : 'TRICK PTS (CARDS)',
            them: '24',
            us: '96',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String them,
    required String us,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(color: const Color(0xFFC9A84C).withValues(alpha: 0.07)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.readexPro(
                color: const Color(0xFF7A6A48),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              them,
              textAlign: TextAlign.center,
              style: GoogleFonts.readexPro(
                color: them == '—' ? const Color(0xFF3A3428) : const Color(0xFFFF3D3D),
                fontSize: 15,
                fontWeight: FontWeight.w800,
                shadows: them == '—' ? null : [
                  BoxShadow(
                    color: const Color(0xFFFF3D3D).withValues(alpha: 0.55),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              us,
              textAlign: TextAlign.center,
              style: GoogleFonts.readexPro(
                color: us == '—' ? const Color(0xFF3A3428) : const Color(0xFF00E87A),
                fontSize: 15,
                fontWeight: FontWeight.w800,
                shadows: us == '—' ? null : [
                  BoxShadow(
                    color: const Color(0xFF00E87A).withValues(alpha: 0.55),
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

  Widget _buildResultRow(bool isAr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0E0B05),
            Color(0xFF141008),
            Color(0xFF0E0B05),
          ],
        ),
        border: Border(
          top: BorderSide(color: const Color(0xFFC9A84C).withValues(alpha: 0.35), width: 1),
        ),
      ),
      child: Stack(
        children: [
          // Left gold bar (`width: 3px`)
          Positioned(
            left: -20,
            top: -16,
            bottom: -16,
            child: Container(
              width: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xFFC9A84C),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  isAr ? 'النتيجة' : 'RESULT',
                  style: GoogleFonts.readexPro(
                    color: const Color(0xFFC9A84C),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    shadows: [
                      BoxShadow(
                        color: const Color(0xFFC9A84C).withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                width: 80,
                child: Text(
                  '5',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF3D3D),
                    shadows: [
                      Shadow(color: Color(0xFFFF3D3D), blurRadius: 20),
                      Shadow(color: Color(0xFFFF3D3D), blurRadius: 40),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                width: 80,
                child: Text(
                  '21',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00E87A),
                    shadows: [
                      Shadow(color: Color(0xFF00E87A), blurRadius: 20),
                      Shadow(color: Color(0xFF00E87A), blurRadius: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final int id;
  final double x;
  final double y;
  final double size;
  final Color color;
  final double speed;
  final bool isStar;
  final double phase;

  _Particle({
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

class _HeroParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _HeroParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // @keyframes particleRise: translateY(0) to translateY(-180px) and opacity fade out
      final t = (progress * p.speed + p.phase) % 1.0;
      final yPos = size.height * (0.9 - t * 0.9);
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
  bool shouldRepaint(covariant _HeroParticlePainter oldDelegate) => true;
}
