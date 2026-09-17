import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../game/presentation/game_provider.dart';
import '../../game/presentation/widgets/majlis_table_background.dart';

/// Pixel-perfect, high-impact Matchup / Versus screen.
/// Features rich player banner cards with avatars, rank pills,
/// and an animated 3D VS emblem with rotating golden sunburst and pulse aura.
class MatchupVersusScreen extends StatefulWidget {
  final bool isIntroMode;
  final bool hasExternalBackground;
  final String? enemy1Name;
  final String? enemy2Name;
  final String? partnerName;
  final String? playerName;
  final VoidCallback? onDismiss;

  const MatchupVersusScreen({
    super.key,
    this.isIntroMode = false,
    this.hasExternalBackground = false,
    this.enemy1Name,
    this.enemy2Name,
    this.partnerName,
    this.playerName,
    this.onDismiss,
  });

  @override
  State<MatchupVersusScreen> createState() => _MatchupVersusScreenState();
}

class _MatchupVersusScreenState extends State<MatchupVersusScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _vsAnimController;

  @override
  void initState() {
    super.initState();
    // Continuous breathing & rotating sunburst animation for the VS emblem
    _vsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _vsAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;

    // Responsive banner height: ~11% dvh (clamp 76 to 92px)
    final bannerH = (h * 0.112).clamp(76.0, 94.0);

    final game = Provider.of<GameProvider?>(context);
    final localeProvider = Provider.of<LocaleProvider?>(context);
    final isAr = localeProvider?.isArabic ?? true;

    // Helper to resolve player names cleanly
    String resolveName(int seat, String defaultAr, String defaultEn) {
      if (game == null) return isAr ? defaultAr : defaultEn;
      try {
        final n = game.playerName(seat, isArabic: isAr);
        if (isAr && (n == 'Jim' || n == 'Michael' || n == 'Dwight')) {
          return defaultAr;
        }
        if (n.isNotEmpty && n != 'Player' && n != 'You') return n;
        if (seat == 0) return isAr ? 'أنت' : 'You';
        return isAr ? defaultAr : defaultEn;
      } catch (_) {
        return isAr ? defaultAr : defaultEn;
      }
    }

    // Top Banners: ENEMY TEAM (Seat 1 Right Bot, Seat 3 Left Bot)
    final enemy1 = widget.enemy1Name ?? resolveName(1, 'فيصل', 'Jim');
    final enemy2 = widget.enemy2Name ?? resolveName(3, 'ماجد', 'Dwight');

    // Bottom Banners: OUR TEAM (Seat 2 Partner Bot, Seat 0 Human Player)
    final partner = widget.partnerName ?? resolveName(2, 'فهد', 'Michael');
    final player = widget.playerName ?? resolveName(0, 'أنت', 'You');

    // Luxury Color Palette:
    // Top (Enemy Team): Imperial Velvet Burgundy
    const enemyEdgeColor = Color(0xFF8E2536);
    const enemyFillColor = Color(0xFF1E0B10);

    // Bottom (Our Team): Royal Sapphire & Deep Cobalt Blue (matching the bottom blue theme)
    const teamEdgeColor = Color(0xFF2678D8);
    const teamFillColor = Color(0xFF0D254C);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.isIntroMode ? null : () {
          if (widget.onDismiss != null) {
            widget.onDismiss!();
          } else {
            Navigator.of(context).maybePop();
          }
        },
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Game Screen Behind (Majlis Table Background) - used when opened standalone
              if (!widget.hasExternalBackground)
                const Positioned.fill(
                  child: MajlisTableBackground(
                    mapAssetPath: AppAssets.majlisTableMap2,
                  ),
                ),

              // 2. Translucent Clash Royale Style Gradient (Top slightly Red, Bottom slightly Blue)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.20, 0.40, 0.50, 0.60, 0.80, 1.0],
                      colors: [
                        Color(0xD94A0A16), // Translucent deep crimson at top edge
                        Color(0x9E781222), // Translucent red behind enemy banners
                        Color(0x522A0C16), // Soft fading red approaching center
                        Color(0x3B0C101A), // Subtle dark tint behind center VS crest
                        Color(0x520A1E38), // Soft fading blue emerging below center
                        Color(0x9E0E3870), // Translucent royal blue behind our team banners
                        Color(0xD908204A), // Translucent deep navy/cobalt at bottom edge
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Subtle Vignette Shadow around screen edges for cinematic focus
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.15,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.52),
                      ],
                      stops: const [0.55, 0.82, 1.0],
                    ),
                  ),
                ),
              ),

              // 4. Center Golden Radial Glow behind the VS Badge
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: (w * 0.75).clamp(240.0, 320.0),
                  height: (w * 0.75).clamp(240.0, 320.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFA500).withValues(alpha: 0.18),
                        const Color(0xFFFF8C00).withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // ══════════════════════════════════════════════════════════════
              // ENEMY TEAM (TOP BANNERS)
              // ══════════════════════════════════════════════════════════════

              // Row 1: Enemy 1 (Seat 1)
              _buildTopRow(
                context: context,
                top: h * 0.106,
                bannerH: bannerH,
                name: enemy1,
                edgeColor: enemyEdgeColor,
                fillColor: enemyFillColor,
              ),

              // Row 2: Enemy 2 (Seat 3)
              _buildTopRow(
                context: context,
                top: h * 0.258,
                bannerH: bannerH,
                name: enemy2,
                edgeColor: enemyEdgeColor,
                fillColor: enemyFillColor,
              ),

              // ══════════════════════════════════════════════════════════════
              // ANIMATED VS CREST (CENTER)
              // ══════════════════════════════════════════════════════════════
              Align(
                alignment: Alignment.center,
                child: _AnimatedVsCrest(
                  animation: _vsAnimController,
                  size: (w * 0.40).clamp(130.0, 185.0),
                ),
              ),

              // ══════════════════════════════════════════════════════════════
              // OUR TEAM (BOTTOM BANNERS)
              // ══════════════════════════════════════════════════════════════

              // Row 3: Partner Bot (Seat 2)
              _buildBottomRow(
                context: context,
                top: h * 0.630,
                bannerH: bannerH,
                name: partner,
                edgeColor: teamEdgeColor,
                fillColor: teamFillColor,
              ),

              // Row 4: You / Human Player (Seat 0)
              _buildBottomRow(
                context: context,
                top: h * 0.782,
                bannerH: bannerH,
                name: player,
                edgeColor: teamEdgeColor,
                fillColor: teamFillColor,
                isUser: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Row: Enemy card stretching from left-notch to right screen edge
  Widget _buildTopRow({
    required BuildContext context,
    required double top,
    required double bannerH,
    required String name,
    required Color edgeColor,
    required Color fillColor,
  }) {
    final w = MediaQuery.sizeOf(context).width;

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: bannerH,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          // Banner plate stretching to the right
          Positioned(
            left: w * 0.16,
            right: -10,
            top: 0,
            bottom: 0,
            child: _MatchupBanner(
              isRightBanner: true,
              edgeColor: edgeColor,
              fillColor: fillColor,
            ),
          ),

          // Player Name (inside banner, to the right of notch)
          Positioned(
            left: (w * 0.25) + 16,
            right: 16,
            top: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.readexPro(
                  fontSize: (w * 0.052).clamp(16.0, 24.0),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFFFDF9),
                  letterSpacing: 0.3,
                  shadows: const [
                    Shadow(offset: Offset(0, 2), color: Color(0xFF14080B)),
                    Shadow(offset: Offset(1, 2), color: Color(0xFF14080B)),
                    Shadow(offset: Offset(0, 4), blurRadius: 8, color: Color(0x99000000)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Row: Our Team card stretching from right-notch to left screen edge
  Widget _buildBottomRow({
    required BuildContext context,
    required double top,
    required double bannerH,
    required String name,
    required Color edgeColor,
    required Color fillColor,
    bool isUser = false,
  }) {
    final w = MediaQuery.sizeOf(context).width;

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: bannerH,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerRight,
        children: [
          // Banner plate stretching to the left
          Positioned(
            left: -10,
            right: w * 0.16,
            top: 0,
            bottom: 0,
            child: _MatchupBanner(
              isRightBanner: false,
              edgeColor: edgeColor,
              fillColor: fillColor,
            ),
          ),

          // Player Name (inside banner, to the left of notch)
          Positioned(
            left: 16,
            right: (w * 0.25) + 16,
            top: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.readexPro(
                  fontSize: (w * 0.052).clamp(16.0, 24.0),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFFFDF9),
                  letterSpacing: 0.3,
                  shadows: const [
                    Shadow(offset: Offset(0, 2), color: Color(0xFF071426)),
                    Shadow(offset: Offset(1, 2), color: Color(0xFF071426)),
                    Shadow(offset: Offset(0, 4), blurRadius: 8, color: Color(0x99000000)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// ══════════════════════════════════════════════════════════════════
//  ANIMATED VS CREST (BREATHING PULSE + ROTATING GOLDEN SUNBURST)
// ══════════════════════════════════════════════════════════════════
class _AnimatedVsCrest extends StatelessWidget {
  final Animation<double> animation;
  final double size;

  const _AnimatedVsCrest({
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Continuous smooth sine breathing curve between 0.95 and 1.07
        final t = animation.value;
        final pulse = 0.96 + 0.10 * (0.5 + 0.5 * math.sin(t * 2 * math.pi * 5.0));
        final rayAngle = t * 2 * math.pi;

        return SizedBox(
          width: size * 1.5,
          height: size * 1.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Rotating Golden Sunburst Light Rays
              Transform.rotate(
                angle: rayAngle,
                child: CustomPaint(
                  size: Size(size * 1.45, size * 1.45),
                  painter: _SunburstRaysPainter(
                    rayColor: const Color(0xFFFFD54F).withValues(alpha: 0.22),
                  ),
                ),
              ),

              // 2. Pulsing Golden Energy Halo
              Container(
                width: size * 0.82 * pulse,
                height: size * 0.82 * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.40),
                      blurRadius: 36 * pulse,
                      spreadRadius: 8 * pulse,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF6F00).withValues(alpha: 0.25),
                      blurRadius: 52 * pulse,
                      spreadRadius: 18 * pulse,
                    ),
                  ],
                ),
              ),

              // 3. 3D VS Coin Emblem scaling with the pulse
              Transform.scale(
                scale: pulse,
                child: Image.asset(
                  'assets/icons/vs.png',
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for golden rotating light rays behind VS
class _SunburstRaysPainter extends CustomPainter {
  final Color rayColor;
  const _SunburstRaysPainter({required this.rayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const numRays = 14;
    const rayWidth = (2 * math.pi / numRays) * 0.38;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          rayColor,
          rayColor.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    for (int i = 0; i < numRays; i++) {
      final startAngle = i * (2 * math.pi / numRays);
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          rayWidth,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunburstRaysPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════════════
//  MATCHUP BANNER BEVELED PLATE
// ══════════════════════════════════════════════════════════════════
class _MatchupBanner extends StatelessWidget {
  final bool isRightBanner;
  final Color edgeColor;
  final Color fillColor;

  const _MatchupBanner({
    required this.isRightBanner,
    required this.edgeColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final clipper = _BannerClipper(isRightBanner: isRightBanner);
    return ClipPath(
      clipper: clipper,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Outer bevel gradient + edge color
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFFFFFF).withValues(alpha: 0.35),
                  edgeColor,
                  Color.lerp(edgeColor, Colors.black, 0.45)!,
                ],
                stops: const [0.0, 0.15, 0.95],
              ),
            ),
          ),

          // 2. Inner rich metallic plate
          Padding(
            padding: const EdgeInsets.all(3.8),
            child: ClipPath(
              clipper: clipper,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(-0.8, -1.0),
                    end: const Alignment(0.8, 1.0),
                    colors: [
                      Color.lerp(fillColor, Colors.white, 0.12)!,
                      fillColor,
                      Color.lerp(fillColor, Colors.black, 0.40)!,
                    ],
                    stops: const [0.0, 0.40, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. Subtle metallic diagonal sheen layer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
            child: ClipPath(
              clipper: clipper,
              child: const Opacity(
                opacity: 0.25,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-0.9, -1.0),
                      end: Alignment(0.9, 1.0),
                      colors: [
                        Color(0x33FFFFFF),
                        Colors.transparent,
                        Color(0x66000000),
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Razor-sharp top metallic specular highlight
          Positioned(
            top: 5.5,
            left: 14.0,
            right: 14.0,
            height: 1.8,
            child: Opacity(
              opacity: 0.55,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(1.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Clip path matching CSS chevron polygon
class _BannerClipper extends CustomClipper<Path> {
  final bool isRightBanner;
  _BannerClipper({required this.isRightBanner});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    if (isRightBanner) {
      // Chevron notch at left side (opening to left)
      final notchX = w * 0.086;
      path.moveTo(0, 0);
      path.lineTo(w, 0);
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.lineTo(notchX, h * 0.5);
      path.close();
    } else {
      // Chevron notch at right side (opening to right)
      final notchX = w * 0.086;
      path.moveTo(0, 0);
      path.lineTo(w - notchX, 0);
      path.lineTo(w, h * 0.5);
      path.lineTo(w - notchX, h);
      path.lineTo(0, h);
      path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _BannerClipper oldClipper) =>
      oldClipper.isRightBanner != isRightBanner;
}


