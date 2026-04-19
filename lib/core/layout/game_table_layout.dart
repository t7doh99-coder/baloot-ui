import 'package:flutter/material.dart';

/// Responsive scale for the live game table.
///
/// Designer references were tuned near **~390dp** width. Narrow phones (e.g. ~360dp)
/// shrink slightly; wider phones (e.g. ~412dp) grow slightly so layout stays
/// proportional without re-flowing like a tablet layout.
class GameTableLayout {
  GameTableLayout._();

  /// Baseline logical width used for Baloot table mockups.
  static const double referenceWidth = 390;

  /// Clamp keeps foldables / very wide phones from oversized chrome.
  static const double minScale = 0.82;
  static const double maxScale = 1.12;

  static double scale(BuildContext context) =>
      scaleForWidth(MediaQuery.sizeOf(context).width);

  static double scaleForWidth(double width) {
    final raw = width / referenceWidth;
    return raw.clamp(minScale, maxScale);
  }

  /// Hand card footprint — matches [CardSize.hand] in `playing_card.dart`.
  static Size handCardSize(double scale) => Size(105.0 * scale, 139.0 * scale);

  static double handFanBandHeight(double scale) => 186.0 * scale;

  /// Stack offset from bottom of [Expanded] play column to clear dashboard.
  static double handStackBottom(double scale) => 90.0 * scale;

  /// Declared project mini-fan above the human hand.
  static double projectFanBottom(double scale) => 215.0 * scale;

  static double sideSeatColumnWidth(double scale) => 92.0 * scale;

  static double topPartnerBandHeight(double scale) => 128.0 * scale;
}
