import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../data/models/card_model.dart';

/// Card display sizes used throughout the game UI.
enum CardSize {
  small(width: 36, height: 50),
  medium(width: 56, height: 80),
  large(width: 80, height: 114);

  final double width;
  final double height;
  const CardSize({required this.width, required this.height});
}

/// Which card back design to use.
///
/// [red]  → opponent / enemy cards (opposing team)
/// [blue] → partner / teammate cards
enum CardBack { red, blue }

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

  const PlayingCard({
    super.key,
    this.card,
    this.size = CardSize.medium,
    this.faceUp = true,
    this.back = CardBack.red,
    this.selected = false,
    this.dimmed = false,
    this.onTap,
  });

  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, selected ? -12 : 0, 0),
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
        : (back == CardBack.red ? AppAssets.cardBackRed : AppAssets.cardBackBlue);

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
    }
  }
}
