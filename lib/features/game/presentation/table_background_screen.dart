import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';

/// Full-screen table / rug background.
///
/// Layer stack (bottom → top) — mirrors [figma/carpet/MajlisLayout.tsx]:
///   1. Base fill      – Deep mauve-purple #3C1B33
///   2. Arabesque SVG  – Tileable carved-wood pattern @ 5 % opacity
///   3. Vignette       – Radial gradient: transparent centre → dark-purple edges
///   4. Central rug    – Rectangular rug centered on screen (Figma CentralRug)
///   5. Back button    – Floating top-left so it never competes with content
///
/// Layout rules:
///   • Fills the ENTIRE physical screen — no letter-boxing, no padding.
///   • `MediaQuery.paddingOf` keeps the back button out of the notch/cutout.
///   • Everything uses relative sizes so it scales on any density / screen size.
class TableBackgroundScreen extends StatelessWidget {
  const TableBackgroundScreen({super.key});

  static const _baseColor = Color(0xFF3C1B33);

  @override
  Widget build(BuildContext context) {
    // Edge-to-edge: hide system overlays while on this screen
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _baseColor,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Layer 1: base colour ──
            const ColoredBox(color: _baseColor),

            // ── Layer 2: Arabesque pattern (5% opacity, fills 100% of screen) ──
            Opacity(
              opacity: 0.05,
              child: SvgPicture.asset(
                'assets/figma/arabesque_pattern.svg',
                fit: BoxFit.fill,
              ),
            ),

            // ── Layer 3: Radial vignette ──
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      Color.fromRGBO(30, 8, 26, 0.00),
                      Color.fromRGBO(22, 6, 19, 0.28),
                      Color.fromRGBO(14, 3, 12, 0.60),
                      Color.fromRGBO(7, 1, 6, 0.85),
                    ],
                    stops: [0.0, 0.40, 0.70, 1.0],
                  ),
                ),
              ),
            ),

            // ── Layer 4: Central rectangular rug ──
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return Stack(
                  children: [
                    Positioned(
                      left: w * 0.18,
                      top: h * 0.26,
                      width: w * 0.64,
                      height: h * 0.48,
                      child: const _CentralRug(),
                    ),
                  ],
                );
              },
            ),

            // ── Layer 5: Floating back button (safe-area aware) ──
            _BackButton(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Central Rug
// ─────────────────────────────────────────────────────────────────────────────

class _CentralRug extends StatelessWidget {
  const _CentralRug();

  static const _gold = Color(0xFFC1A36E);
  static const _goldFaint = Color(0x59C1A36E); // ~35% alpha

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.antiAlias,
      children: [
        // ── Rug field: radial gradient background ──
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const RadialGradient(
              center: Alignment.center,
              radius: 0.85,
              colors: [
                Color(0xFF3D1F6E),
                Color(0xFF271248),
                Color(0xFF160A30),
              ],
              stops: [0.0, 0.60, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.60),
                blurRadius: 32,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 20,
                spreadRadius: -4,
              ),
            ],
          ),
        ),

        // ── Arabesque pattern overlay on rug (subtle texture, 8% opacity) ──
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Opacity(
            opacity: 0.08,
            child: SvgPicture.asset(
              'assets/figma/arabesque_pattern.svg',
              fit: BoxFit.cover,
            ),
          ),
        ),

        // ── Center medallion ──
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.45,
            heightFactor: 0.30,
            child: SvgPicture.asset(
              'assets/figma/rug_medallion.svg',
              fit: BoxFit.contain,
            ),
          ),
        ),

        // ── Arabesque border motifs ──
        Positioned.fill(
          child: IgnorePointer(
            child: SvgPicture.asset(
              'assets/figma/rug_border.svg',
              fit: BoxFit.fill,
            ),
          ),
        ),

        // ── Gold outer border (2 px) ──
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: _gold, width: 2),
              ),
            ),
          ),
        ),

        // ── Inner border 1 (6 px inset) ──
        Positioned(
          left: 6, top: 6, right: 6, bottom: 6,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: _goldFaint,
                  width: 1,
                ),
              ),
            ),
          ),
        ),

        // ── Inner border 2 (11 px inset) ──
        Positioned(
          left: 11, top: 11, right: 11, bottom: 11,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                border: Border.all(
                  color: _goldFaint.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Floating back button ───────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final screenW = MediaQuery.sizeOf(context).width;
    // Scale icon size slightly on tablets / large phones
    final iconSize = (screenW * 0.045).clamp(16.0, 22.0);

    return Positioned(
      top: top + 8,
      left: 12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.royalGold.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white.withValues(alpha: 0.85),
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
