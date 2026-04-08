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
        titleTextStyle: _montserratStyle(18, FontWeight.w700, AppColors.royalGold),
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
        hintStyle: _montserratStyle(13, FontWeight.w400, AppColors.muted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.slateGlass.withValues(alpha: 0.7),
        selectedColor: AppColors.royalGold.withValues(alpha: 0.18),
        labelStyle: _montserratStyle(12, FontWeight.w600, AppColors.silverLining),
        side: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusXl)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1C1F26),
        contentTextStyle: _montserratStyle(13, FontWeight.w500, AppColors.pureWhite),
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
          textStyle: _montserratStyle(16, FontWeight.w700, AppColors.antigravityBlack),
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
          textStyle: _montserratStyle(16, FontWeight.w600, AppColors.royalGold),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.muted,
        thickness: 0.5,
      ),
      textTheme: _buildTextTheme(),
    );
  }

  /// English text style (Montserrat)
  static TextStyle _montserratStyle(double size, FontWeight weight, Color color) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  /// Build text theme — uses Montserrat by default, Arabic handled via locale
  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AppColors.pureWhite,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.pureWhite,
      ),
      headlineLarge: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.royalGold,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.pureWhite,
      ),
      titleLarge: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.pureWhite,
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.pureWhite,
      ),
      bodyLarge: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.silverLining,
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.silverLining,
      ),
      bodySmall: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
      ),
      labelLarge: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.royalGold,
        letterSpacing: 1.2,
      ),
    );
  }

  /// Returns locale-aware text theme — Tajawal for Arabic, Montserrat for English
  static TextTheme localizedTextTheme(Locale locale) {
    if (locale.languageCode == 'ar') {
      return TextTheme(
        displayLarge: GoogleFonts.tajawal(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.pureWhite),
        displayMedium: GoogleFonts.tajawal(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.pureWhite),
        headlineLarge: GoogleFonts.tajawal(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.royalGold),
        headlineMedium: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.pureWhite),
        titleLarge: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.pureWhite),
        titleMedium: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.pureWhite),
        bodyLarge: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.silverLining),
        bodyMedium: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.silverLining),
        bodySmall: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.muted),
        labelLarge: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.royalGold),
      );
    }
    return _buildTextTheme();
  }
}
