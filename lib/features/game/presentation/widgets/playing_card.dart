import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../data/models/card_model.dart';

/// Card display sizes used throughout the game UI.
enum CardSize {
  small(width: 36, height: 50),
  medium(width: 56, height: 80),
  large(width: 80, height: 114),
  /// Majlis bottom hand — matches designer [`_CardFan`] `large` mode.
  hand(width: 123.5, height: 163.4);

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
    this.faceUp = true,
    this.back = CardBack.red,
    this.selected = false,
    this.dimmed = false,
    this.onTap,
    this.suppressSelectionOffset = false,
  });

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
        child: _buildCardShell(),
      ),
    );
  }

  Widget _buildCardShell() {
    final radius = _radius;
    return Container(
      width: size.width,
      height: size.height,
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
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final path = faceUp && card != null
        ? AppAssets.cardImage(card!)
        : backAssetPath(back);

    return Image.asset(
      path,
      width: size.width,
      height: size.height,
      fit: BoxFit.fill,
      // Show a placeholder card outline if image fails to load
      errorBuilder: (_, __, ___) => _errorPlaceholder(),
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      color: const Color(0xFFFFFDF5),
      child: Center(
        child: Text(
          card != null ? '?' : '🂠',
          style: TextStyle(
            fontSize: size.width * 0.3,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  double get _radius {
    switch (size) {
      case CardSize.small:
        return 4;
      case CardSize.medium:
        return 6;
      case CardSize.large:
        return 8;
      case CardSize.hand:
        return 11;
    }
  }
}
