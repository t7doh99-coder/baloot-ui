import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/player_stats.dart';
import '../../data/models/rank_tier.dart';
import 'points_calculator.dart';
import 'rank_calculator.dart';

// ── ACHIEVEMENT DEFINITION ─────────────────────────────────────
class Achievement {
  final String id;
  final String arabicName;
  final String englishName;
  final int medalReward;
  final String description;

  const Achievement({
    required this.id,
    required this.arabicName,
    required this.englishName,
    required this.medalReward,
    required this.description,
  });
}

// ── EXTRA TRACKING (stored separately since model isn't changed) ─
/// Extra fields that v2 needs but the PlayerStats model doesn't have.
/// Persisted in SharedPreferences as JSON.
class PlayerExtraStats {
  List<String> unlockedAchievements;
  List<String> recentOpponentIds; // last 3 for anti-exploit
  int totalKaboots;
  int peakBlueStars; // never decreases — used for rank protection floor

  PlayerExtraStats({
    List<String>? unlockedAchievements,
    List<String>? recentOpponentIds,
    this.totalKaboots = 0,
    this.peakBlueStars = 0,
  })  : unlockedAchievements = unlockedAchievements ?? [],
        recentOpponentIds = recentOpponentIds ?? [];

  factory PlayerExtraStats.fromJson(Map<String, dynamic> j) => PlayerExtraStats(
    unlockedAchievements: List<String>.from(j['unlocked'] ?? []),
    recentOpponentIds: List<String>.from(j['recentOpp'] ?? []),
    totalKaboots: j['kaboots'] as int? ?? 0,
    peakBlueStars: j['peakStars'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'unlocked': unlockedAchievements,
    'recentOpp': recentOpponentIds,
    'kaboots': totalKaboots,
    'peakStars': peakBlueStars,
  };

  static const _prefsKey = 'baloot_extra_stats_v2';

  static Future<PlayerExtraStats> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_prefsKey);
    if (s == null) return PlayerExtraStats();
    try {
      return PlayerExtraStats.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return PlayerExtraStats();
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKey, jsonEncode(toJson()));
  }
}

// ── ACHIEVEMENT SERVICE ────────────────────────────────────────
class AchievementService {

  static const List<Achievement> allAchievements = [

    // First steps
    Achievement(id: 'first_game', arabicName: 'الخطوة الأولى', englishName: 'First Step',
        medalReward: 5, description: 'Play your first ranked match'),
    Achievement(id: 'first_win', arabicName: 'أول انتصار', englishName: 'First Victory',
        medalReward: 10, description: 'Win your first ranked match'),

    // Win milestones
    Achievement(id: 'wins_10', arabicName: '10 انتصارات', englishName: '10 Victories',
        medalReward: 20, description: 'Win 10 ranked matches'),
    Achievement(id: 'wins_25', arabicName: '25 انتصارات', englishName: '25 Victories',
        medalReward: 35, description: 'Win 25 ranked matches'),
    Achievement(id: 'wins_50', arabicName: '50 انتصارات', englishName: '50 Victories',
        medalReward: 60, description: 'Win 50 ranked matches'),
    Achievement(id: 'wins_100', arabicName: 'مئة انتصار', englishName: '100 Victories',
        medalReward: 100, description: 'Win 100 ranked matches'),
    Achievement(id: 'wins_250', arabicName: '250 انتصارات', englishName: '250 Victories',
        medalReward: 200, description: 'Win 250 ranked matches'),

    // Games played
    Achievement(id: 'games_10', arabicName: 'لاعب نشيط', englishName: 'Active Player',
        medalReward: 10, description: 'Play 10 ranked matches'),
    Achievement(id: 'games_50', arabicName: 'مخضرم', englishName: 'Veteran',
        medalReward: 30, description: 'Play 50 ranked matches'),
    Achievement(id: 'games_100', arabicName: 'لاعب محترف', englishName: 'Pro Player',
        medalReward: 60, description: 'Play 100 ranked matches'),
    Achievement(id: 'games_500', arabicName: 'أسطورة البلوت', englishName: 'Baloot Legend',
        medalReward: 150, description: 'Play 500 ranked matches'),

    // Streaks
    Achievement(id: 'streak_3', arabicName: 'ثلاثية', englishName: 'Hat Trick',
        medalReward: 15, description: 'Win 3 matches in a row'),
    Achievement(id: 'streak_5', arabicName: 'سلسلة ذهبية', englishName: 'Golden Streak',
        medalReward: 30, description: 'Win 5 matches in a row'),
    Achievement(id: 'streak_10', arabicName: 'غير قابل للإيقاف', englishName: 'Unstoppable',
        medalReward: 75, description: 'Win 10 matches in a row'),

    // Kaboot
    Achievement(id: 'kaboot_1', arabicName: 'أول كبوت', englishName: 'First Kaboot',
        medalReward: 20, description: 'Win all 8 tricks in a match'),
    Achievement(id: 'kaboot_5', arabicName: 'سيد الكبوت', englishName: 'Kaboot Master',
        medalReward: 50, description: 'Achieve Kaboot 5 times'),
    Achievement(id: 'kaboot_25', arabicName: 'أسطورة الكبوت', englishName: 'Kaboot Legend',
        medalReward: 100, description: 'Achieve Kaboot 25 times'),

    // Rank milestones (largest medals)
    Achievement(id: 'reach_amateur', arabicName: 'هاوي', englishName: 'Reached Amateur',
        medalReward: 50, description: 'Reach Amateur rank for the first time'),
    Achievement(id: 'reach_good', arabicName: 'جيد', englishName: 'Reached Good',
        medalReward: 100, description: 'Reach Good rank for the first time'),
    Achievement(id: 'reach_advanced', arabicName: 'متقدم', englishName: 'Reached Advanced',
        medalReward: 200, description: 'Reach Advanced rank for the first time'),
    Achievement(id: 'reach_expert', arabicName: 'خبير', englishName: 'Reached Expert',
        medalReward: 400, description: 'Reach Expert rank for the first time'),
    Achievement(id: 'reach_professional', arabicName: 'محترف', englishName: 'Reached Professional',
        medalReward: 800, description: 'Reach Professional rank for the first time'),

    // Special
    Achievement(id: 'baloot_declared', arabicName: 'أول بلوت', englishName: 'First Baloot',
        medalReward: 15, description: 'Declare Baloot (K+Q of trump) for the first time'),
    Achievement(id: 'beat_expert', arabicName: 'ضربة حظ', englishName: 'Underdog Win',
        medalReward: 30, description: 'Win against Expert/Professional as Beginner/Amateur'),
  ];

  // ── CHECK ACHIEVEMENTS AFTER EACH GAME ────────────────────────
  static List<Achievement> checkAchievements({
    required PlayerStats stats,
    required PlayerExtraStats extra,
    required GameResult result,
    required bool wasKaboot,
    required bool balootDeclared,
    required RankTier playerRank,
    required RankTier opponentRank,
  }) {
    final List<Achievement> unlocked = [];

    void tryUnlock(String id) {
      if (!extra.unlockedAchievements.contains(id)) {
        final a = allAchievements.firstWhere((x) => x.id == id,
            orElse: () => throw Exception('Achievement not found: $id'));
        extra.unlockedAchievements.add(id);
        stats.medals += a.medalReward;
        unlocked.add(a);
      }
    }

    // Games played
    if (stats.totalGamesPlayed >= 1)   tryUnlock('first_game');
    if (stats.totalGamesPlayed >= 10)  tryUnlock('games_10');
    if (stats.totalGamesPlayed >= 50)  tryUnlock('games_50');
    if (stats.totalGamesPlayed >= 100) tryUnlock('games_100');
    if (stats.totalGamesPlayed >= 500) tryUnlock('games_500');

    // Wins
    if (result == GameResult.win) {
      if (stats.totalWins >= 1)   tryUnlock('first_win');
      if (stats.totalWins >= 10)  tryUnlock('wins_10');
      if (stats.totalWins >= 25)  tryUnlock('wins_25');
      if (stats.totalWins >= 50)  tryUnlock('wins_50');
      if (stats.totalWins >= 100) tryUnlock('wins_100');
      if (stats.totalWins >= 250) tryUnlock('wins_250');
    }

    // Streaks
    if (stats.currentWinStreak >= 3)  tryUnlock('streak_3');
    if (stats.currentWinStreak >= 5)  tryUnlock('streak_5');
    if (stats.currentWinStreak >= 10) tryUnlock('streak_10');

    // Kaboot
    if (wasKaboot) {
      if (extra.totalKaboots >= 1)  tryUnlock('kaboot_1');
      if (extra.totalKaboots >= 5)  tryUnlock('kaboot_5');
      if (extra.totalKaboots >= 25) tryUnlock('kaboot_25');
    }

    // Baloot declaration
    if (balootDeclared) tryUnlock('baloot_declared');

    // Underdog win
    if (result == GameResult.win) {
      final playerIsLow = RankCalculator.rankIndex(playerRank.mainRank) <= 1;
      final opponentIsHigh = RankCalculator.rankIndex(opponentRank.mainRank) >= 4;
      if (playerIsLow && opponentIsHigh) tryUnlock('beat_expert');
    }

    return unlocked;
  }

  // ── CHECK RANK MILESTONE ACHIEVEMENTS ─────────────────────────
  static List<Achievement> checkRankMilestones(
    PlayerStats stats, PlayerExtraStats extra, RankTier newRank) {
    final List<Achievement> unlocked = [];

    void tryUnlock(String id) {
      if (!extra.unlockedAchievements.contains(id)) {
        final a = allAchievements.firstWhere((x) => x.id == id);
        extra.unlockedAchievements.add(id);
        stats.medals += a.medalReward;
        unlocked.add(a);
      }
    }

    switch (newRank.mainRank) {
      case MainRank.amateur:       tryUnlock('reach_amateur');       break;
      case MainRank.good:          tryUnlock('reach_good');          break;
      case MainRank.advanced:      tryUnlock('reach_advanced');      break;
      case MainRank.expert:        tryUnlock('reach_expert');        break;
      case MainRank.professional:  tryUnlock('reach_professional');  break;
      default: break;
    }

    return unlocked;
  }
}
