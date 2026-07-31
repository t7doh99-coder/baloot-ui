import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/player_stats.dart';
import '../../data/models/rank_tier.dart';
import 'achievement_service.dart';
import 'points_calculator.dart';
import 'rank_calculator.dart';

// ── MATCH OUTCOME (returned to UI) ────────────────────────────
class MatchOutcome {
  final PointResult result;
  final RankTier oldRank;
  final RankTier newRank;
  final bool rankedUp;
  final bool rankedDown;
  final int starsChange;
  final int oldStars;
  final int newStars;
  final int oldMedals;
  final int newMedals;
  final List<Achievement> newAchievements; // shown in celebration UI

  const MatchOutcome({
    required this.result,
    required this.oldRank,
    required this.newRank,
    required this.rankedUp,
    required this.rankedDown,
    required this.starsChange,
    required this.oldStars,
    required this.newStars,
    required this.oldMedals,
    required this.newMedals,
    required this.newAchievements,
  });
}

class PlayerStatsService {
  static const String _prefsKey = 'baloot_player_stats';

  // ── LOAD STATS ──────────────────────────────────────────────
  static Future<PlayerStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final String? statsJson = prefs.getString(_prefsKey);

    if (statsJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(statsJson);
        return PlayerStats.fromJson(decoded);
      } catch (_) {}
    }

    return PlayerStats();
  }

  // ── SAVE STATS ──────────────────────────────────────────────
  static Future<void> saveStats(PlayerStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(stats.toJson()));
  }

  // ── APPLY MATCH RESULT TO PLAYER (v2) ─────────────────────────
  static Future<MatchOutcome> applyMatchResult({
    required PlayerStats stats,
    required PointResult result,
    required GameResult gameResult,
    bool wasKaboot = false,
    bool balootDeclared = false,
    List<String> opponentIds = const [],
    RankTier? opponentRank,
  }) async {
    // Load extra stats (achievements, peak stars, etc.)
    final extra = await PlayerExtraStats.load();

    // Snapshot before applying
    final RankTier oldRank = RankCalculator.getRankFromStars(
        stats.blueStars, extra.peakBlueStars);
    final int oldStars  = stats.blueStars;
    final int oldMedals = stats.medals;

    // ── Apply blue stars ─────────────────────────────────────
    stats.blueStars = max(0, stats.blueStars + result.blueStarsChange);

    // Update peak stars (never decreases)
    if (stats.blueStars > extra.peakBlueStars) {
      extra.peakBlueStars = stats.blueStars;
    }

    // ── Update win streak ────────────────────────────────────
    if (gameResult == GameResult.win) {
      stats.currentWinStreak += 1;
      stats.totalWins += 1;
    } else {
      stats.currentWinStreak = 0;
    }
    stats.totalGamesPlayed += 1;

    // ── Update kaboot count ──────────────────────────────────
    if (wasKaboot) extra.totalKaboots += 1;

    // ── Update recent opponents (anti-exploit) ───────────────
    for (final id in opponentIds) {
      extra.recentOpponentIds.add(id);
    }
    while (extra.recentOpponentIds.length > 3) {
      extra.recentOpponentIds.removeAt(0);
    }

    // ── Compute new rank ─────────────────────────────────────
    final RankTier newRank = RankCalculator.getRankFromStars(
        stats.blueStars, extra.peakBlueStars);

    final bool rankedUp   = RankCalculator.rankIndex(newRank.mainRank) >
                            RankCalculator.rankIndex(oldRank.mainRank);
    final bool rankedDown = RankCalculator.rankIndex(newRank.mainRank) <
                            RankCalculator.rankIndex(oldRank.mainRank);

    // ── Check achievements (adds medals to stats.medals) ─────
    final List<Achievement> newAchievements = AchievementService.checkAchievements(
      stats: stats,
      extra: extra,
      result: gameResult,
      wasKaboot: wasKaboot,
      balootDeclared: balootDeclared,
      playerRank: oldRank,
      opponentRank: opponentRank ?? oldRank,
    );

    if (rankedUp) {
      newAchievements.addAll(
        AchievementService.checkRankMilestones(stats, extra, newRank),
      );
    }

    // ── Save everything ──────────────────────────────────────
    await saveStats(stats);
    await extra.save();

    return MatchOutcome(
      result:          result,
      oldRank:         oldRank,
      newRank:         newRank,
      rankedUp:        rankedUp,
      rankedDown:      rankedDown,
      starsChange:     result.blueStarsChange,
      oldStars:        oldStars,
      newStars:        stats.blueStars,
      oldMedals:       oldMedals,
      newMedals:       stats.medals,
      newAchievements: newAchievements,
    );
  }
}
