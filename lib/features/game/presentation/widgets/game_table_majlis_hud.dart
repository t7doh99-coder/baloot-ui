import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/game_l10n.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../game_provider.dart';

// ── Sandstone Dark palette ─────────
const _kGBgCanvas   = Color(0xFF1E1808);
const _kGBgCard     = Color(0xFF2C2210);
const _kGBgElevated = Color(0xFF392C14);
const _kGSandGold   = Color(0xFFC49028);
const _kGSandDark   = Color(0xFF886018);
const _kGTextPrim   = Color(0xFFF8EDD8);
const _kGTextSec    = Color(0xFFC8A868);
const _kGSandBorder = Color(0x42C49028);
const _kGCrimson    = Color(0xFF8B2020);
// ───────────────────────────────────

/// Designer-style top HUD: square buttons + dual score pill (Them | Us).
/// Wired to [GameProvider.gameScore] only — no engine behavior changes.
class GameTableMajlisHud extends StatelessWidget {
  const GameTableMajlisHud({
    super.key,
    required this.game,
    required this.onBack,
    required this.onCycleWallpaper,
  });

  final GameProvider game;
  final VoidCallback onBack;
  final VoidCallback onCycleWallpaper;

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
            color: Colors.transparent, // Make Material transparent
            elevation: 0, // Remove Material shadow so we can draw our own
            onSelected: (value) {
              if (value == 0) onBack();
              if (value == 1) onCycleWallpaper();
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
              
              Widget buildItem(IconData icon, String text, int value) {
                return InkWell(
                  onTap: () => Navigator.of(context).pop(value),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(icon, color: iconColor, size: 18),
                        const SizedBox(width: 12),
                        Text(text, style: textStyle),
                      ],
                    ),
                  ),
                );
              }

              final divider = Container(height: 1, color: Colors.white.withValues(alpha: 0.12));

              return [
                PopupMenuItem<int>(
                  enabled: false, // We handle taps manually in buildItem
                  padding: EdgeInsets.zero,
                  child: Container(
                    width: 220, // Give the menu a fixed width
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [_kGBgElevated.withValues(alpha: 0.90), _kGBgCard.withValues(alpha: 0.90)],
                          ),
                            border: Border.all(
                              color: _kGSandBorder,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              buildItem(Icons.meeting_room_rounded, loc.leave, 0),
                              divider,
                              buildItem(Icons.wallpaper_rounded, loc.wallpaper, 1),
                              divider,
                              buildItem(game.isGodModeEnabled ? Icons.visibility_off : Icons.visibility, game.isGodModeEnabled ? 'Hide All Cards' : 'Reveal All Cards', 98),
                              divider,
                              buildItem(Icons.copy_all_rounded, loc.copyGameLog, 99),
                              divider,
                              buildItem(Icons.volume_up_rounded, loc.sound, 3),
                              divider,
                              buildItem(Icons.emoji_emotions_outlined, loc.emotes, 4),
                            ],
                          ),
                        ),
                      ),
                    ),
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
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kGBgElevated.withValues(alpha: 0.90), _kGBgCard.withValues(alpha: 0.90)],
        ),
            border: Border.all(
              color: _kGSandBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.12),
                offset: const Offset(0, 1),
                blurRadius: 2,
                blurStyle: BlurStyle.inner,
              ),
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
            color: _kGTextPrim,
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
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kGBgElevated.withValues(alpha: 0.90), _kGBgCard.withValues(alpha: 0.90)],
        ),
            border: Border.all(color: _kGSandBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.12),
                offset: const Offset(0, 1),
                blurRadius: 2,
                blurStyle: BlurStyle.inner,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: _scoreCell(leftLabel, leftScore),
                ),
                Container(width: 1, color: _kGSandBorder),
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
        style: const TextStyle(
          color: _kGTextSec,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      const SizedBox(height: 1),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: Tween<double>(begin: 1.4, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: Text(
          '$score',
          key: ValueKey<int>(score),
          style: TextStyle(
            color: _kGTextPrim,
            fontSize: 16,
            fontWeight: FontWeight.w900, // Thicker font weight for extra pop
            height: 1,
            shadows: [
              Shadow(
                color: _kGSandGold.withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
