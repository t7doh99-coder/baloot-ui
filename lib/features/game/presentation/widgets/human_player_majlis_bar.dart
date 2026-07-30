import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'dart:ui';
import 'dart:math' as math;

import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/custom_player_avatar.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/l10n/game_l10n.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../domain/baloot_game_controller.dart' show GamePhase;
import '../../domain/managers/bidding_manager.dart' show BidAction;
import '../game_provider.dart';

/// Majlis bottom HUD — charcoal bar, bronze status chip, nested name pill,
/// gold ring timer, light action chips (reference layout).
/// Uses live [GameProvider] data for seat 0 only (no gameplay logic).

// ── Sandstone Dark palette ─────────
const _kGBgCanvas   = Color(0xFF1E1808);
const _kGBgElevated = Color(0xFF392C14);
const _kGSandGold   = Color(0xFFC49028);
const _kGTextPrim   = Color(0xFFF8EDD8);
const _kGSandBorder = Color(0x42C49028);
// ───────────────────────────────────

const Color _kBarCharcoal = _kGBgElevated;
const Color _kGoldRing    = _kGSandGold;
class HumanPlayerMajlisBar extends StatefulWidget {
  final VoidCallback? onProjectTap;
  final bool isProjectExpanded;
  const HumanPlayerMajlisBar({
    super.key,
    this.onProjectTap,
    this.isProjectExpanded = false,
  });

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

  void _syncRingTicker({required bool humanTurn}) {
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

  /// Two stacked lines narrows horizontal width vs "Sun · Dealer" (fixes bar overflow).
  static ({String primary, String? secondary})? _badgeParts(
    GameProvider game,
    GameL10n loc,
  ) {
    final mode = game.gameModeLabel;
    if (game.isSawaRevealPlaying && game.sawaRevealClaimSeat == 0) {
      if (mode != '—') {
        return (primary: loc.modeLabel(mode), secondary: loc.sawa);
      }
      return (primary: loc.sawa, secondary: null);
    }
    
    final humanDealer = game.dealerIndex == 0;
    final humanBuyer = game.buyerIndex == 0;
    
    if (humanDealer && mode != '—') {
      return (primary: loc.modeLabel(mode), secondary: loc.dealer);
    }
    if (humanBuyer && mode != '—') {
      return (primary: loc.modeLabel(mode), secondary: loc.buyer);
    }
    
    if (mode != '—') return (primary: loc.modeLabel(mode), secondary: null);
    
    if (game.phase != GamePhase.notStarted) {
      if (humanDealer) return (primary: loc.dealer, secondary: null);
      if (humanBuyer) return (primary: loc.buyer, secondary: null);
      // Show defender role once buyer is selected
      if (game.isHumanDefender) {
        return (primary: loc.modeLabel(mode != '—' ? mode : 'Def.'), secondary: null);
      }
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final loc    = GameL10n.of(context);
    final game   = context.watch<GameProvider>();
    _syncRingTicker(humanTurn: game.isHumanTurn);

    final name       = game.playerName(0);
    final badge      = _badgeParts(game, loc);
    final secs       = game.turnTimerSeconds;
    final isAr       = context.read<LocaleProvider>().isArabic;

    final bool ringActive = game.isHumanTurn;
    final ringSecondsText = game.isHumanTurn ? '${secs ?? 0}' : '';
    final rawProgress     = game.isHumanTurn ? game.activeSeatTimerProgress : 0.0;
    final ringProgress    = rawProgress.isFinite ? rawProgress.clamp(0.0, 1.0) : 1.0;

    return Padding(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Background layer: Shadows, Blur, and translucent Fill
          Positioned.fill(
            child: CustomPaint(
              painter: _MajlisBarShadowPainter(),
              child: ClipPath(
                clipper: _MajlisBarClipper(),
                child: CustomPaint(
                  painter: _MajlisBarFillPainter(),
                ),
              ),
            ),
          ),
          
          // Foreground layer: UI Content
          Container(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── Top section: avatar floats centered, info boxes start at avatar midpoint ──
                SizedBox(
                  height: 68, // reduced to move the lower row up
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                  // Info boxes row
                  Positioned(
                    top: 19,
                    left: 0,
                    right: 0,
                    child: Row(
                      children: [
                        // Left info box
                        Expanded(
                          child: badge != null
                              ? _InfoBox(
                                  child: _BadgeText(primary: badge.primary, secondary: badge.secondary),
                                )
                              : const SizedBox.shrink(),
                        ),
                        // Gap in the middle for avatar
                        const SizedBox(width: 84),
                        // Right info box
                        Expanded(
                          child: _InfoBox(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _kGTextPrim,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: isAr ? GoogleFonts.readexPro().fontFamily : null,
                                letterSpacing: isAr ? 0 : 0.1,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Avatar: centered horizontally at the top
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _CenteredAvatarRing(
                        seatIndex: 0,
                        customAvatarPath: game.playerStats.customAvatarPath,
                        isActive: ringActive,
                        progress: ringProgress,
                        secondsText: ringSecondsText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Bottom section: persistent utility row ──
            Row(
              children: [
                Expanded(
                  child: _SawaButton(
                    isActive: (game.canSawa && !game.isSawaRevealPlaying) || game.canHumanBidSawa,
                    onTap: () {
                      if (game.canHumanBidSawa) {
                        game.humanBid(BidAction.sawa);
                      } else {
                        game.humanClaimSawa();
                      }
                    },

                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ProjectButton(
                    isActive: game.canDeclareProjects,
                    isExpanded: widget.isProjectExpanded,
                    onTap: widget.onProjectTap ?? () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QaidButton(
                    isActive: game.canClaimQaid,
                    onTap: () => game.humanClaimQaid(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }
}

class _RankChip extends StatelessWidget {
  const _RankChip({
    required this.primary,
    this.secondary,
  });

  final String primary;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final ar = context.read<LocaleProvider>().isArabic;
    final textStylePrimary = TextStyle(
      color: Colors.white.withValues(alpha: 0.96),
      fontSize: 10,
      fontWeight: FontWeight.w700,
      height: secondary != null ? 1.05 : 1.1,
      letterSpacing: ar ? 0 : 0.15,
    );
    final textStyleSecondary = TextStyle(
      color: Colors.white.withValues(alpha: 0.78),
      fontSize: 9,
      fontWeight: FontWeight.w600,
      height: 1.0,
      letterSpacing: ar ? 0 : 0.1,
    );

    return Container(
      constraints: BoxConstraints(minWidth: secondary != null ? 34 : 40),
      padding: EdgeInsets.symmetric(
        horizontal: secondary != null ? 8 : 10,
        vertical: secondary != null ? 5 : 6,
      ),
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
      child: secondary == null
          ? Text(
              primary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStylePrimary,
              textAlign: TextAlign.center,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStylePrimary,
                  textAlign: TextAlign.center,
                ),
                Text(
                  secondary!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyleSecondary,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}

/// Plain text badge — no capsule/pill, just text centred inside the [_InfoBox].
class _BadgeText extends StatelessWidget {
  const _BadgeText({required this.primary, this.secondary});
  final String primary;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final ar = context.read<LocaleProvider>().isArabic;
    if (secondary == null) {
      return Text(
        primary.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _kGSandGold,
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          letterSpacing: ar ? 0 : 0.15,
          height: 1.2,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          primary.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _kGTextPrim,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: ar ? 0 : 0.15,
            height: 1.15,
          ),
        ),
        Text(
          secondary!.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFFFD700),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: ar ? 0 : 0.1,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

/// Large centered avatar with a gold arc timer ring around it.
/// Replaces the separate _MiniAvatar + _CountdownRing pair.
class _CenteredAvatarRing extends StatelessWidget {
  const _CenteredAvatarRing({
    required this.seatIndex,
    this.customAvatarPath,
    required this.isActive,
    required this.progress,
    required this.secondsText,
  });

  final int seatIndex;
  final String? customAvatarPath;
  final bool isActive;
  final double progress;
  final String secondsText;

  @override
  Widget build(BuildContext context) {
    const totalSize  = 66.0;
    const avatarSize = 62.0;

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Gold arc timer ring (outer) ──
          SizedBox(
            width: totalSize,
            height: totalSize,
            child: isActive
                ? CircularProgressIndicator(
                    value: progress <= 0 ? 0.0 : progress.clamp(0.001, 1.0),
                    strokeWidth: 3.2,
                    strokeCap: StrokeCap.round,
                    backgroundColor: _kGoldRing.withValues(alpha: 0.15),
                    color: _kGoldRing,
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _kGoldRing.withValues(alpha: 0.35),
                        width: 1.8,
                      ),
                    ),
                  ),
          ),
          // ── Avatar image (inner) ──
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Opacity(
                opacity: isActive ? 1.0 : 0.72,
                child: CustomPlayerAvatar(
                  seatIndex: seatIndex,
                  customAvatarPath: customAvatarPath,
                ),
              ),
            ),
          ),
          // Countdown number removed — ring arc alone shows remaining time
        ],
      ),
    );
  }
}

/// Bordered info box used for the dealer badge (left) and player name (right)
/// in the identity row — the 'green boxes' flanking the avatar.
class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kGBgCanvas.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _kGSandBorder,
          width: 1.2,
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
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}



class _SawaButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _SawaButton({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = GameL10n.of(context);
    final ar = context.watch<LocaleProvider>().isArabic;
    const gold = Color(0xFFD4AF37);

    Widget btn = InkWell(
      onTap: isActive ? () {
        context.read<GameProvider>().audioService.playGoldButton();
        onTap();
      } : null,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 42,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? gold : Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.12),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      blurStyle: BlurStyle.inner,
                    ),
                    BoxShadow(
                      color: gold.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.08),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      blurStyle: BlurStyle.inner,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              loc.sawa,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? gold : Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: ar ? GoogleFonts.readexPro().fontFamily : null,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );

    btn = Tooltip(
      message: loc.sawaHandsTooltip,
      preferBelow: false,
      child: btn,
    );

    return Material(
      color: Colors.transparent,
      child: btn,
    );
  }
}

/// Standard-style Qaid (قيدها) button — red accent for danger/risk.
/// Placed right of the Sawa button in the human player bar.
/// Per BALOOT_RULES.md §14.5: manual violation flagging.
class _QaidButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _QaidButton({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = GameL10n.of(context);
    const gold = Color(0xFFD4AF37);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? () {
          context.read<GameProvider>().audioService.playGoldButton();
          onTap();
        } : null,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 42,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? gold : Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.12),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                        blurStyle: BlurStyle.inner,
                      ),
                      BoxShadow(
                        color: gold.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.08),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                        blurStyle: BlurStyle.inner,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                loc.qaid,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? gold : Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: GoogleFonts.readexPro().fontFamily,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectButton extends StatelessWidget {
  final bool isActive;
  final bool isExpanded;
  final VoidCallback onTap;

  const _ProjectButton({
    required this.isActive,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = GameL10n.of(context);
    const gold = Color(0xFFD4AF37);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? () {
          context.read<GameProvider>().audioService.playGoldButton();
          onTap();
        } : null,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 42,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? gold : Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.12),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                        blurStyle: BlurStyle.inner,
                      ),
                      BoxShadow(
                        color: gold.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.08),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                        blurStyle: BlurStyle.inner,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                loc.projects,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? gold : Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: GoogleFonts.readexPro().fontFamily,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MajlisBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const avatarCenterY = 43.0;
    const yTop = 20.0; 
    const cornerRadius = 18.0;
    const cutoutRadius = 41.0; 
    
    final dy = avatarCenterY - yTop;
    double dx = 0.0;
    if (cutoutRadius > dy) {
      dx = math.sqrt(cutoutRadius * cutoutRadius - dy * dy);
    }
    
    final leftX = size.width / 2 - dx;
    final rightX = size.width / 2 + dx;

    final path = Path()
      ..moveTo(0, yTop + cornerRadius)
      ..quadraticBezierTo(0, yTop, cornerRadius, yTop)
      ..lineTo(leftX, yTop);

    if (dx > 0) {
      path.arcToPoint(
        Offset(rightX, yTop),
        radius: const Radius.circular(cutoutRadius),
        clockwise: true,
      );
    }

    path
      ..lineTo(size.width - cornerRadius, yTop)
      ..quadraticBezierTo(size.width, yTop, size.width, yTop + cornerRadius)
      ..lineTo(size.width, size.height - cornerRadius)
      ..quadraticBezierTo(size.width, size.height, size.width - cornerRadius, size.height)
      ..lineTo(cornerRadius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - cornerRadius)
      ..close();
      
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _MajlisBarShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _MajlisBarClipper().getClip(size);
    // Outer shadow
    final shadowPaint1 = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0);
    canvas.drawPath(path.shift(const Offset(0, 5)), shadowPaint1);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MajlisBarFillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _MajlisBarClipper().getClip(size);
    
    // Fill gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF392C14).withValues(alpha: 0.90), // _kGBgElevated
        const Color(0xFF2C2210).withValues(alpha: 0.90), // _kGBgCard
      ],
    );
    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 20, size.width, size.height - 20))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Inner highlight / rim light
    final shadowPaint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawPath(path.shift(const Offset(0, 1)), shadowPaint2);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0x42C49028) // _kGSandBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
