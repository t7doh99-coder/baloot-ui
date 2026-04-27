import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// VIP Dark Theme — The identity of Antigravitty Royal Baloot
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.antigravityBlack,
      primaryColor: AppColors.royalGold,
      canvasColor: AppColors.antigravityBlack,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.royalGold,
        secondary: AppColors.silverLining,
        surface: AppColors.slateGlass,
        error: AppColors.error,
        onPrimary: AppColors.antigravityBlack,
        onSecondary: AppColors.antigravityBlack,
        onSurface: AppColors.pureWhite,
        onError: AppColors.pureWhite,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.antigravityBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _fontStyle(18, FontWeight.w700, AppColors.royalGold),
        iconTheme: const IconThemeData(color: AppColors.royalGold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.slateGlass,
        selectedItemColor: AppColors.royalGold,
        unselectedItemColor: AppColors.silverLining,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: AppColors.silverLining),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slateGlass.withValues(alpha: 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.18)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.royalGold, width: 1.4),
        ),
        hintStyle: _fontStyle(13, FontWeight.w400, AppColors.muted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.slateGlass.withValues(alpha: 0.7),
        selectedColor: AppColors.royalGold.withValues(alpha: 0.18),
        labelStyle: _fontStyle(12, FontWeight.w600, AppColors.silverLining),
        side: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusXl)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1C1F26),
        contentTextStyle: _fontStyle(13, FontWeight.w500, AppColors.pureWhite),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          side: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.25)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1C1F26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.22)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.slateGlass,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.royalGold,
          foregroundColor: AppColors.antigravityBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.xl,
            vertical: AppSizes.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          textStyle: _fontStyle(16, FontWeight.w700, AppColors.antigravityBlack),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.royalGold,
          side: const BorderSide(color: AppColors.royalGold, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.xl,
            vertical: AppSizes.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          textStyle: _fontStyle(16, FontWeight.w600, AppColors.royalGold),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.muted,
        thickness: 0.5,
      ),
      textTheme: _buildTextTheme(),
    );
  }

  /// Readex Pro — single font for both Arabic and English
  static TextStyle _fontStyle(double size, FontWeight weight, Color color) {
    return GoogleFonts.readexPro(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  /// Build text theme — uses Readex Pro (supports Arabic + English natively)
  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.readexPro(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AppColors.pureWhite,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.readexPro(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.pureWhite,
      ),
      headlineLarge: GoogleFonts.readexPro(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.royalGold,
      ),
      headlineMedium: GoogleFonts.readexPro(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.pureWhite,
      ),
      titleLarge: GoogleFonts.readexPro(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.pureWhite,
      ),
      titleMedium: GoogleFonts.readexPro(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.pureWhite,
      ),
      bodyLarge: GoogleFonts.readexPro(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.silverLining,
      ),
      bodyMedium: GoogleFonts.readexPro(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.silverLining,
      ),
      bodySmall: GoogleFonts.readexPro(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
      ),
      labelLarge: GoogleFonts.readexPro(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.royalGold,
        letterSpacing: 1.2,
      ),
    );
  }

  /// Returns locale-aware text theme.
  /// Readex Pro supports both Arabic and English natively,
  /// so we use it for both locales — no font switching needed.
  static TextTheme localizedTextTheme(Locale locale) {
    return _buildTextTheme();
  }
}
