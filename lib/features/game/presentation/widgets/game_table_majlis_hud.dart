import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/game_l10n.dart';
import '../../../../core/l10n/locale_provider.dart';
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
    context.watch<LocaleProvider>();
    final loc = GameL10n.of(context);
    final score = game.gameScore;
    final base = Theme.of(context).textTheme;
    final textTheme = GoogleFonts.readexProTextTheme(base);

    return Theme(
      data: Theme.of(context).copyWith(textTheme: textTheme),
      child: SizedBox(
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: PopupMenuButton<int>(
            tooltip: '',
            padding: EdgeInsets.zero,
            offset: const Offset(0, 56),
            color: const Color(0xFF2D2D2D), // Exact game button charcoal
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),   // sharp — attaches to button on left
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            onSelected: (value) {
              if (value == 0) onBack();
              if (value == 1) onCycleWallpaper();
              if (value == 2 && onTestMode != null) onTestMode!();
              if (value == 98) game.toggleGodMode();
              if (value == 99) {
                Clipboard.setData(ClipboardData(text: game.gameLog));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.gameLogCopied)),
                );
              }
              // value == 4 is Emote
            },
            itemBuilder: (context) {
              const iconColor = Color(0xFFF2D08D); // game gold
              const textStyle = TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800);
              const divider = PopupMenuDivider(height: 1);

              return [
                PopupMenuItem<int>(
                  value: 0,
                  height: 48,
                  child: Row(children: [
                    const Icon(Icons.meeting_room_rounded, color: iconColor, size: 18),
                    const SizedBox(width: 12),
                    Text(loc.leave, style: textStyle),
                  ]),
                ),
                divider,
                PopupMenuItem<int>(
                  value: 1,
                  height: 48,
                  child: Row(children: [
                    const Icon(Icons.wallpaper_rounded, color: iconColor, size: 18),
                    const SizedBox(width: 12),
                    Text(loc.wallpaper, style: textStyle),
                  ]),
                ),
                if (onTestMode != null) ...[
                  divider,
                  PopupMenuItem<int>(
                    value: 2,
                    height: 48,
                    child: Row(children: [
                      const Icon(Icons.science_rounded, color: iconColor, size: 18),
                      const SizedBox(width: 12),
                      Text(loc.testMode, style: textStyle),
                    ]),
                  ),
                ],
                divider,
                PopupMenuItem<int>(
                  value: 98,
                  height: 48,
                  child: Row(children: [
                    Icon(
                      game.isGodModeEnabled ? Icons.visibility_off : Icons.visibility,
                      color: iconColor, 
                      size: 18
                    ),
                    const SizedBox(width: 12),
                    Text(game.isGodModeEnabled ? 'Hide All Cards' : 'Reveal All Cards', style: textStyle),
                  ]),
                ),
                divider,
                PopupMenuItem<int>(
                  value: 99,
                  height: 48,
                  child: Row(children: [
                    const Icon(Icons.copy_all_rounded, color: iconColor, size: 18),
                    const SizedBox(width: 12),
                    Text(loc.copyGameLog, style: textStyle),
                  ]),
                ),
                divider,
                PopupMenuItem<int>(
                  value: 3,
                  height: 48,
                  child: Row(children: [
                    const Icon(Icons.volume_up_rounded, color: iconColor, size: 18),
                    const SizedBox(width: 12),
                    Text(loc.sound, style: textStyle),
                  ]),
                ),
                divider,
                PopupMenuItem<int>(
                  value: 4,
                  height: 48,
                  child: Row(children: [
                    const Icon(Icons.emoji_emotions_outlined, color: iconColor, size: 18),
                    const SizedBox(width: 12),
                    Text(loc.emotes, style: textStyle),
                  ]),
                ),
              ];
            },
            child: const _HudButton(
              icon: Icons.menu_rounded,
            ),
          ),
          ),
            SizedBox(
              width: 150,
              child: _MajlisScoreHud(
                leftLabel: loc.them,
                leftScore: score.teamB,
                rightLabel: loc.us,
                rightScore: score.teamA,
              ),
            ),
          ],
      ),
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF585858), Color(0xFF2D2D2D)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 20,
        color: Colors.white.withValues(alpha: 0.95),
      ),
    );
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
