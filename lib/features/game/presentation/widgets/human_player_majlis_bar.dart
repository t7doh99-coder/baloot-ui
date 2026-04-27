import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:provider/provider.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/l10n/game_l10n.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../game_provider.dart';

/// Majlis bottom HUD — charcoal bar, bronze status chip, nested name pill,
/// gold ring timer, light action chips (reference layout).
/// Uses live [GameProvider] data for seat 0 only (no gameplay logic).

// Reference palette (screenshot / design spec)
const Color _kBarCharcoal = Color(0xFF2C2C2C);
const Color _kNamePillBg = Color(0xFF232323);
const Color _kGoldRing = Color(0xFFD4AF37);
class HumanPlayerMajlisBar extends StatefulWidget {
  const HumanPlayerMajlisBar({super.key});

  @override
  State<HumanPlayerMajlisBar> createState() => _HumanPlayerMajlisBarState();
}

class _HumanPlayerMajlisBarState extends State<HumanPlayerMajlisBar>
    with TickerProviderStateMixin {
  Ticker? _ringTicker;
  bool _humanTurn = false;

  @override
  void dispose() {
    _ringTicker?.dispose();
    _ringTicker = null;
    super.dispose();
  }

  void _syncRingTicker(bool humanTurn) {
    if (humanTurn == _humanTurn) return;
    _humanTurn = humanTurn;
    if (humanTurn) {
      _ringTicker?.dispose();
      _ringTicker = null;
      _ringTicker = createTicker((_) {
        if (mounted) setState(() {});
      })..start();
    } else {
      _ringTicker?.dispose();
      _ringTicker = null;
    }
  }

  static String _leftBadgeLabel(GameProvider game, GameL10n loc) {
    final mode = game.gameModeLabel;
    if (mode != '—') return loc.modeLabel(mode);
    if (game.dealerIndex == 0) return loc.dealer;
    if (game.buyerIndex == 0) return loc.buyer;
    return loc.us;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final loc = GameL10n.of(context);
    final game = context.watch<GameProvider>();
    _syncRingTicker(game.isHumanTurn);

    final name = game.playerName(0);
    final avatarPath = AppAssets.playerAvatarPath(0);
    final badge = _leftBadgeLabel(game, loc);
    final secs = game.turnTimerSeconds;
    final rawProgress =
        game.isHumanTurn ? game.activeSeatTimerProgress : 0.0;
    final progress = rawProgress.isFinite ? rawProgress.clamp(0.0, 1.0) : 1.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _kBarCharcoal,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.04),
              blurRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            _RankChip(label: badge),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _kNamePillBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    _MiniAvatar(path: avatarPath, active: game.isHumanTurn),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.96),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 0.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            _CountdownRing(
              isActive: game.isHumanTurn,
              progress: progress,
              secondsText: game.isHumanTurn ? '${secs ?? 0}' : '—',
            ),
          ],
        ),
      ),
    );
  }
}

class _RankChip extends StatelessWidget {
  const _RankChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5C4033),
            Color(0xFF3D2818),
            Color(0xFF2A1810),
          ],
        ),
        border: Border.all(
          color: _kGoldRing.withValues(alpha: 0.28),
          width: 0.9,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.94),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 0.2,
        ),
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.path, required this.active});

  final String path;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(
        child: Opacity(
          opacity: active ? 1.0 : 0.65,
          child: Image.asset(
            path,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: const Color(0xFF3A3A3A),
              child: Icon(
                Icons.person_rounded,
                size: 17,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    required this.isActive,
    required this.progress,
    required this.secondsText,
  });

  final bool isActive;
  final double progress;
  final String secondsText;

  @override
  Widget build(BuildContext context) {
    const size = 42.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isActive)
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: progress <= 0
                    ? 0.0
                    : progress.clamp(0.001, 1.0),
                strokeWidth: 2.4,
                strokeCap: StrokeCap.round,
                backgroundColor: _kGoldRing.withValues(alpha: 0.15),
                color: _kGoldRing,
              ),
            )
          else
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _kGoldRing.withValues(alpha: 0.45),
                  width: 2.0,
                ),
              ),
            ),
          Text(
            secondsText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: isActive ? 0.98 : 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

