import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../game_provider.dart';

/// Designer-style top HUD: square buttons + dual score pill (Them | Us).
/// Wired to [GameProvider.gameScore] only — no engine behavior changes.
class GameTableMajlisHud extends StatelessWidget {
  const GameTableMajlisHud({
    super.key,
    required this.game,
    required this.onBack,
    required this.onCycleWallpaper,
    this.onTestMode,
  });

  final GameProvider game;
  final VoidCallback onBack;
  final VoidCallback onCycleWallpaper;
  final VoidCallback? onTestMode;

  @override
  Widget build(BuildContext context) {
    final score = game.gameScore;
    final base = Theme.of(context).textTheme;
    final textTheme = GoogleFonts.tajawalTextTheme(base);

    return Theme(
      data: Theme.of(context).copyWith(textTheme: textTheme),
      child: Row(
        children: [
          _HudButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 6),
          PopupMenuButton<int>(
            tooltip: '',
            padding: EdgeInsets.zero,
            offset: const Offset(0, 56),
            color: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 1) onCycleWallpaper();
            },
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                value: 1,
                padding: EdgeInsets.zero,
                child: _HudButton(
                  icon: Icons.wallpaper_rounded,
                  lightStyle: true,
                  iconColor: const Color(0xFF747474),
                ),
              ),
            ],
            child: const _HudButton(
              icon: Icons.more_horiz_rounded,
              label: 'More',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MajlisScoreHud(
              leftLabel: 'Them',
              leftScore: score.teamB,
              rightLabel: 'Us',
              rightScore: score.teamA,
            ),
          ),
          if (onTestMode != null) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: onTestMode,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.goldAccent,
              ),
              child: const Text(
                'Test',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
          const _HudButton(icon: Icons.volume_up_rounded, label: 'Sound'),
          const SizedBox(width: 6),
          const _HudButton(icon: Icons.emoji_emotions_outlined, label: 'Emote'),
        ],
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    required this.icon,
    this.label,
    this.onTap,
    this.lightStyle = false,
    this.iconColor,
  });

  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final bool lightStyle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: lightStyle
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF9F9F9), Color(0xFFECECEC)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF585858), Color(0xFF2D2D2D)],
              ),
        border: Border.all(
          color: lightStyle
              ? const Color(0xFFD3D3D3)
              : Colors.white.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: lightStyle ? 0.10 : 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ??
                (lightStyle
                    ? const Color(0xFF6F6F6F)
                    : Colors.white.withValues(alpha: 0.95)),
          ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(
              label!,
              style: TextStyle(
                color: lightStyle
                    ? const Color(0xFF6F6F6F)
                    : Colors.white.withValues(alpha: 0.86),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );

    return onTap == null ? child : GestureDetector(onTap: onTap, child: child);
  }
}

class _MajlisScoreHud extends StatelessWidget {
  const _MajlisScoreHud({
    required this.leftLabel,
    required this.leftScore,
    required this.rightLabel,
    required this.rightScore,
  });

  final String leftLabel;
  final int leftScore;
  final String rightLabel;
  final int rightScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F4F4F), Color(0xFF262626)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: _scoreCell(leftLabel, leftScore),
            ),
            Container(width: 1, color: Colors.white.withValues(alpha: 0.12)),
            Expanded(
              child: _scoreCell(rightLabel, rightScore),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _scoreCell(String label, int score) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      const SizedBox(height: 1),
      TweenAnimationBuilder<int>(
        tween: IntTween(begin: score, end: score),
        duration: const Duration(milliseconds: 600),
        builder: (ctx, val, _) => Text(
          '$val',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    ],
  );
}
