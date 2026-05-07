import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Majlis room SVG + vignette (designer table look). Game logic–agnostic.
class MajlisTableBackground extends StatelessWidget {
  const MajlisTableBackground({super.key, required this.mapAssetPath});

  final String mapAssetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5A3328),
            Color(0xFF44261F),
            Color(0xFF301914),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              mapAssetPath,
              fit: BoxFit.fill,
              alignment: Alignment.center,
              // Avoid Flutter’s default red/yellow error screen if an SVG fails.
              // Parent gradient still shows; table remains usable.
              errorBuilder: (_, __, ___) => const SizedBox.expand(),
              placeholderBuilder: (_) => const ColoredBox(
                color: Colors.transparent,
                child: SizedBox.expand(),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x14000000),
                  Colors.transparent,
                  Color(0x28000000),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
