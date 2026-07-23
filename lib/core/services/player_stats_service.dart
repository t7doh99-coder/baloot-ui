import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/player_stats.dart';
import '../../data/models/rank_tier.dart';
import 'points_calculator.dart';
import 'rank_calculator.dart';

// ── MATCH OUTCOME (returned to UI) ────────────────────────────
class MatchOutcome {
  final PointResult result;
  final RankTier oldRank;
  final RankTier newRank;
  final bool rankedUp;
  final int oldStars;
  final int newStars;
  final int oldMedals;
  final int newMedals;

  const MatchOutcome({
    required this.result,
    required this.oldRank,
    required this.newRank,
    required this.rankedUp,
    required this.oldStars,
    required this.newStars,
    required this.oldMedals,
    required this.newMedals,
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
      } catch (e) {
        // If parsing fails, fall through and return a new instance
      }
    }
    
    return PlayerStats(); // Return default empty stats
  }

  // ── SAVE STATS ──────────────────────────────────────────────
  static Future<void> saveStats(PlayerStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(stats.toJson());
    await prefs.setString(_prefsKey, encoded);
  }

  // ── APPLY MATCH RESULT TO PLAYER ──────────────────────────────
  static Future<MatchOutcome> applyMatchResult({
    required PlayerStats stats,
    required PointResult result,
    required GameResult gameResult,
  }) async {
    final RankTier oldRank = RankCalculator.getRankFromMedals(stats.medals);
    final int oldMedals    = stats.medals;
    final int oldStars     = stats.blueStars;

    // ── Apply blue stars ──────────────────────────────────────
    stats.blueStars = max(0, stats.blueStars + result.blueStarsChange);

    // ── Apply medals (never subtract — protection floor built in) ─
    stats.medals = max(stats.medals, stats.medals + result.medalsChange);

    // ── Update win streak ─────────────────────────────────────
    if (gameResult == GameResult.win) {
      stats.currentWinStreak += 1;
      stats.totalWins += 1;
    } else {
      stats.currentWinStreak = 0;
    }
    
    stats.totalGamesPlayed += 1;

    // ── Check for rank up ─────────────────────────────────────
    final RankTier newRank = RankCalculator.getRankFromMedals(stats.medals);
    final bool rankedUp = RankCalculator.rankIndex(newRank.mainRank) >
                          RankCalculator.rankIndex(oldRank.mainRank);

    // ── Save stats ────────────────────────────────────────────
    await saveStats(stats);

    return MatchOutcome(
      result:          result,
      oldRank:         oldRank,
      newRank:         newRank,
      rankedUp:        rankedUp,
      oldStars:        oldStars,
      newStars:        stats.blueStars,
      oldMedals:       oldMedals,
      newMedals:       stats.medals,
    );
  }
}
