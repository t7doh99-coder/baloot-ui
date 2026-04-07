import 'package:flutter/material.dart';

/// VIP Design Token Color Palette — Antigravitty Royal Baloot
class AppColors {
  AppColors._();

  /// Primary background — Deep, premium canvas
  static const Color antigravityBlack = Color(0xFF0D0F14);

  /// Accent 1 — Buttons, VIP badges, borders
  static const Color royalGold = Color(0xFFD4AF37);

  /// Accent 2 — Secondary text, subtle dividers
  static const Color silverLining = Color(0xFFC0C0C0);

  /// Surface — Glassmorphism containers
  static const Color slateGlass = Color(0xFF1C1F2B);

  /// Pure white text
  static const Color pureWhite = Color(0xFFFFFFFF);

  /// Muted / disabled
  static const Color muted = Color(0xFF4A4E5A);

  /// Error / warning
  static const Color error = Color(0xFFCF4444);

  /// Gold gradient (start → end)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFFFE066), Color(0xFFB8860B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Background gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0D0F14), Color(0xFF1C1F2B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Glassmorphism surface with transparency
  static Color get glassSurface => slateGlass.withOpacity(0.75);
}
