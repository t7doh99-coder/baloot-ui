import 'dart:math';
import '../../data/models/player_stats.dart';
import '../../data/models/rank_tier.dart';
import 'rank_calculator.dart';

enum GameResult { win, loss }

// ── POINT RESULT (returned after every match) ──────────────────
class PointResult {
  final int blueStarsChange;  // positive = gained, negative = lost
  final int medalsChange;     // always 0 or positive — never negative
  final String explanation;   // human-readable breakdown

  // Breakdown for UI display
  final int basePoints;
  final int rankGapBonus;
  final int streakBonus;
  final bool wasCapped;       // true if bot cap was applied

  const PointResult({
    required this.blueStarsChange,
    required this.medalsChange,
    required this.explanation,
    this.basePoints = 0,
    this.rankGapBonus = 0,
    this.streakBonus = 0,
    this.wasCapped = false,
  });
}

class PointsCalculator {
  // ── CONSTANTS ─────────────────────────────────────────────────
  // Blue stars
  static const int WIN_BASE            = 100;
  static const int LOSS_BASE           = 60;   // LESS than win
  static const int RANK_GAP_BONUS      = 15;   // per tier difference
  static const int STREAK_BONUS_PER_WIN= 10;   // per consecutive win
  static const int STREAK_BONUS_MAX    = 50;   // cap at 5 wins
  static const int BOT_STAR_CAP        = 40;   // max stars from any bot game
  static const int MIN_LOSS_DEDUCTION  = 20;   // floor on loss penalty
  static const int MAX_LOSS_DEDUCTION  = 80;   // ceiling on loss penalty

  // Medals
  static const int MEDAL_WIN_BASE      = 20;
  static const int BOT_MEDAL_CAP       = 10;   // max medals from bot game

  // ── MAIN FUNCTION: CALCULATE POINTS AFTER A MATCH ─────────────
  static PointResult calculateMatchPoints({
    required GameResult result,
    required PlayerStats playerStats,
    required RankTier playerRank,
    RankTier? opponentRank, // Optional opponent rank if we want to simulate higher tier bots
    bool applyBotCap = true, // Whether to clamp to +40/+10
  }) {
    // If opponent rank isn't provided, assume same rank for bots
    final oppRank = opponentRank ?? playerRank;

    if (result == GameResult.win) {
      return _calculateWin(
        playerStats: playerStats,
        playerRank: playerRank,
        opponentRank: oppRank,
        applyBotCap: applyBotCap,
      );
    } else {
      return _calculateLoss(
        playerStats: playerStats,
        playerRank: playerRank,
        opponentRank: oppRank,
      );
    }
  }

  // ── WIN CALCULATION ────────────────────────────────────────────
  static PointResult _calculateWin({
    required PlayerStats playerStats,
    required RankTier playerRank,
    required RankTier opponentRank,
    required bool applyBotCap,
  }) {
    int base = WIN_BASE;
    int rankBonus = 0;
    int streakBonus = 0;
    bool wasCapped = false;

    // 1. Rank gap bonus/penalty
    final int gapTiers = RankCalculator.rankGapTiers(playerRank, opponentRank);
    rankBonus = gapTiers * RANK_GAP_BONUS;

    // 2. Win streak bonus
    streakBonus = min(playerStats.currentWinStreak * STREAK_BONUS_PER_WIN, STREAK_BONUS_MAX);

    // 3. Calculate total
    int totalStars = base + rankBonus + streakBonus;
    totalStars = totalStars.clamp(1, 9999);

    // 4. Apply bot cap
    if (applyBotCap && totalStars > BOT_STAR_CAP) {
      totalStars = BOT_STAR_CAP;
      wasCapped = true;
    }

    // 5. Calculate medals
    int medalGain = MEDAL_WIN_BASE;
    if (applyBotCap) {
      medalGain = min(medalGain, BOT_MEDAL_CAP);
    }

    // Build explanation
    final parts = <String>[];
    parts.add('Base: +$base');
    if (rankBonus != 0) parts.add('Rank gap: ${rankBonus > 0 ? '+' : ''}$rankBonus');
    if (streakBonus > 0) parts.add('Streak bonus: +$streakBonus');
    if (wasCapped) parts.add('(Bot cap applied)');
    final explanation = 'WIN: ${parts.join(', ')} = $totalStars stars, +$medalGain medals';

    return PointResult(
      blueStarsChange:  totalStars,
      medalsChange:     medalGain,
      explanation:      explanation,
      basePoints:       base,
      rankGapBonus:     rankBonus,
      streakBonus:      streakBonus,
      wasCapped:        wasCapped,
    );
  }

  // ── LOSS CALCULATION ───────────────────────────────────────────
  static PointResult _calculateLoss({
    required PlayerStats playerStats,
    required RankTier playerRank,
    required RankTier opponentRank,
  }) {
    int base = LOSS_BASE;

    final int gapTiers = RankCalculator.rankGapTiers(playerRank, opponentRank);
    int rankPenaltyAdjustment = gapTiers * RANK_GAP_BONUS * -1;

    int totalLoss = base + rankPenaltyAdjustment;
    totalLoss = totalLoss.clamp(MIN_LOSS_DEDUCTION, MAX_LOSS_DEDUCTION);

    final explanation = 'LOSS: -$totalLoss stars, Medals unchanged.';

    return PointResult(
      blueStarsChange:  -totalLoss,
      medalsChange:     0,
      explanation:      explanation,
      basePoints:       base,
      rankGapBonus:     rankPenaltyAdjustment * -1,
    );
  }
}
