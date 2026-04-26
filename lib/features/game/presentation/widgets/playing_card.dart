import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../data/models/card_model.dart';

/// PNG card art is **438×608**; use this ratio for logical sizes so faces/backs
/// are not stretched and downscaling stays as sharp as possible.
const double kPlayingCardAssetAspect = 438 / 608;

/// Height for a given card [width] matching [kPlayingCardAssetAspect].
double playingCardHeightForWidth(double width) => width / kPlayingCardAssetAspect;

/// Card display sizes used throughout the game UI.
///
/// **small** / **medium** / **large** follow the asset aspect ratio (438:608).
/// **hand** keeps the designer Majlis footprint (slightly taller than strict ratio).
enum CardSize {
  /// Mini panels, last-trick placeholder backs.
  small(width: 42, height: 58),
  /// Center trick / table play.
  medium(width: 58, height: 81),
  /// Deal animation and other hero card moments.
  large(width: 84, height: 117),
  /// Majlis bottom hand — matches designer [`_CardFan`] `large` mode (scaled down to fit 8 cards safely).
  hand(width: 105.0, height: 139.0);

  final double width;
  final double height;
  const CardSize({required this.width, required this.height});
}

/// Which card back design to use.
///
/// [red]  → opposing team (seats 1 & 3)
/// [blue] → your team (seats 0 & 2 — human + partner)
enum CardBack { red, blue }

/// Face-down backs by seat: team A (0, 2) = blue, team B (1, 3) = red.
CardBack cardBackForSeat(int seatIndex) =>
    (seatIndex & 1) == 0 ? CardBack.blue : CardBack.red;

/// A playing card widget that renders a Baloot card using Figma-exported PNGs.
///
/// - Face-up: shows the real card image from [AppAssets.cardImage]
/// - Face-down: shows red or blue back from [AppAssets.cardBackRed] / [AppAssets.cardBackBlue]
/// - [selected]: card rises 12px with gold glow (for hand selection)
/// - [dimmed]: 40% opacity (for invalid / unplayable cards)
class PlayingCard extends StatelessWidget {
  final CardModel? card;
  final CardSize size;
  /// When set, overrides [size] width (responsive hand fan, etc.).
  final double? width;
  /// When set, overrides [size] height.
  final double? height;
  final bool faceUp;
  final CardBack back;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onTap;
  /// When true, selection is shown (glow) but Y-offset is left to the parent
  /// (designer hand uses its own lift / scale).
  final bool suppressSelectionOffset;

  const PlayingCard({
    super.key,
    this.card,
    this.size = CardSize.medium,
    this.width,
    this.height,
    this.faceUp = true,
    this.back = CardBack.red,
    this.selected = false,
    this.dimmed = false,
    this.onTap,
    this.suppressSelectionOffset = false,
  });

  double get _w => width ?? size.width;
  double get _h => height ?? size.height;

  /// Asset path for a face-down back (team-colored).
  static String backAssetPath(CardBack back) =>
      back == CardBack.red ? AppAssets.cardBackRed : AppAssets.cardBackBlue;

  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          0,
          (selected && !suppressSelectionOffset) ? -12 : 0,
          0,
        ),
        child: _buildCardShell(context),
      ),
    );
  }

  Widget _buildCardShell(BuildContext context) {
    final radius = _radius;
    return Container(
      width: _w,
      height: _h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: _gold.withValues(alpha: 0.65),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 5,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Opacity(
          opacity: dimmed ? 0.4 : 1.0,
          child: _buildImage(context),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final showFace = faceUp && card != null;
    final path =
        showFace ? AppAssets.cardImage(card!) : backAssetPath(back);

    final dpr = MediaQuery.devicePixelRatioOf(context);
    Widget imageWidget = Image.asset(
      path,
      width: _w,
      height: _h,
      fit: showFace ? BoxFit.fill : BoxFit.cover,
      filterQuality: FilterQuality.medium,
      // Show a placeholder card outline if image fails to load
      errorBuilder: (_, __, ___) => _errorPlaceholder(),
    );



    return imageWidget;
  }

  Widget _errorPlaceholder() {
    return Container(
      color: const Color(0xFFFFFDF5),
      child: Center(
        child: Text(
          card != null ? '?' : '🂠',
          style: TextStyle(
            fontSize: _w * 0.3,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  double get _radius {
    if (width != null || height != null) {
      return (_w * 0.105).clamp(5.0, 14.0);
    }
    switch (size) {
      case CardSize.small:
        return 5;
      case CardSize.medium:
        return 7;
      case CardSize.large:
        return 9;
      case CardSize.hand:
        return 11;
    }
  }
}
