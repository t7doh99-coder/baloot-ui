import 'package:flutter/material.dart';

enum MainRank {
  beginner,    // مبتدئ — 0 medals
  amateur,     // هاوي  — 500 medals
  good,        // جيد   — 1500 medals
  advanced,    // متقدم — 3500 medals
  expert,      // خبير  — 7500 medals
  professional // محترف — 15000 medals
}

class RankTier {
  final MainRank mainRank;
  final int subLevel;        // 1 to 5

  const RankTier({required this.mainRank, required this.subLevel});

  // Display name in Arabic
  String get arabicName {
    switch (mainRank) {
      case MainRank.beginner:     return 'مبتدئ';
      case MainRank.amateur:      return 'هاوي';
      case MainRank.good:         return 'جيد';
      case MainRank.advanced:     return 'متقدم';
      case MainRank.expert:       return 'خبير';
      case MainRank.professional: return 'محترف';
    }
  }

  // Display name in English
  String get englishName {
    switch (mainRank) {
      case MainRank.beginner:     return 'Beginner';
      case MainRank.amateur:      return 'Amateur';
      case MainRank.good:         return 'Good';
      case MainRank.advanced:     return 'Advanced';
      case MainRank.expert:       return 'Expert';
      case MainRank.professional: return 'Professional';
    }
  }

  // Color theme for the rank badge
  Color get badgeColor {
    switch (mainRank) {
      case MainRank.beginner:     return const Color(0xFFCD7F32); // Bronze
      case MainRank.amateur:      return const Color(0xFFC0C0C0); // Silver
      case MainRank.good:         return const Color(0xFFFFD700); // Gold
      case MainRank.advanced:     return const Color(0xFF50C878); // Emerald
      case MainRank.expert:       return const Color(0xFF0F52BA); // Sapphire
      case MainRank.professional: return const Color(0xFFB9F2FF); // Diamond
    }
  }

  // Number of suit icons shown in badge (1 to 5 then all 4 suits for professional)
  int get suitIconCount => subLevel;

  @override
  String toString() => '$englishName $subLevel';
}
