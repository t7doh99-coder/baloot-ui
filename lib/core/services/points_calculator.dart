import 'dart:math';
import '../../data/models/player_stats.dart';
import '../../data/models/rank_tier.dart';
import 'rank_calculator.dart';

// ── ENUMS ──────────────────────────────────────────────────────
enum GameResult { win, loss }
enum SessionType { ranked, friendly }

// ── POINT RESULT ───────────────────────────────────────────────
/// v2: blueStarsChange is symmetric — equal opponent: +50 win / -50 loss.
/// medalsChange is always 0 (medals come from achievements only).
class PointResult {
  final int blueStarsChange;   // positive = gained, negative = lost
  final int heartsChange;      // 0 or -1 (lose 1 heart on ranked loss)
  final String explanation;    // human-readable breakdown for UI

  // Breakdown shown on results screen
  final int baseExchange;      // symmetric base (50 for equal, varies by gap)
  final int streakBonus;       // +3/+6/+9 for consecutive wins
  final int repeatPenalty;     // -8 if same opponent farmed
  final bool wasBotCapped;     // true if bot cap (15) was applied

  // Kept for backward compat with existing UI
  int get medalsChange => 0;
  // Old names — kept so existing UI compiles without changes
  int get basePoints => baseExchange;
  int get rankGapBonus => 0;      // v2 doesn't expose this separately
  bool get wasCapped => wasBotCapped;

  const PointResult({
    required this.blueStarsChange,
    required this.heartsChange,
    required this.explanation,
    this.baseExchange = 0,
    this.streakBonus = 0,
    this.repeatPenalty = 0,
    this.wasBotCapped = false,
  });
}

// ── MAIN CALCULATOR ────────────────────────────────────────────
/// ELO-inspired symmetric points system.
/// Equal opponent → Win +50, Loss -50. 50% win rate = 0 net progress.
class PointsCalculator {

  // ── CORE CONSTANTS (v2 — balanced) ──────────────────────────
  static const int BASE_EXCHANGE  = 50;  // stars traded for equal players
  static const int TIER_SHIFT     = 10;  // shift per rank tier difference
  static const int STREAK_BONUS   = 3;   // +3 per consecutive win
  static const int STREAK_MAX     = 9;   // capped after 3 wins
  static const int REPEAT_PENALTY = 8;   // farming same opponent penalty
  static const int BOT_STAR_CAP   = 15;  // max stars from any bot game

  // Hearts
  static const int MAX_HEARTS            = 5;   // visible hearts in UI
  static const int HEARTS_REGEN_MINUTES  = 30;

  // ── MAIN ENTRY POINT ────────────────────────────────────────
  static PointResult calculateMatchPoints({
    required GameResult result,
    required PlayerStats playerStats,
    required RankTier playerRank,
    RankTier? opponentRank,
    bool applyBotCap = true,
    SessionType sessionType = SessionType.ranked,
    List<String> opponentIds = const [],
  }) {
    // Friendly: zero effect
    if (sessionType == SessionType.friendly) {
      return const PointResult(
        blueStarsChange: 0,
        heartsChange: 0,
        explanation: 'Friendly game — no points affected',
      );
    }

    final RankTier oppRank = opponentRank ?? playerRank;

    // ── Rank gap calculation ─────────────────────────────────
    // rankGap > 0 → opponent is HIGHER ranked (harder)
    // rankGap < 0 → opponent is LOWER ranked (easier)
    final int rankGap = RankCalculator.rankGapTiers(playerRank, oppRank);
    final int clampedGap = rankGap.clamp(-3, 3);
    final int shift = clampedGap * TIER_SHIFT;

    final int winAmount  = (BASE_EXCHANGE + shift).clamp(15, 80);
    final int lossAmount = (BASE_EXCHANGE - shift).clamp(10, 75);

    if (result == GameResult.win) {
      return _calculateWin(
        playerStats: playerStats,
        winAmount: winAmount,
        applyBotCap: applyBotCap,
        opponentIds: opponentIds,
      );
    } else {
      return _calculateLoss(lossAmount: lossAmount);
    }
  }

  // ── WIN ──────────────────────────────────────────────────────
  static PointResult _calculateWin({
    required PlayerStats playerStats,
    required int winAmount,
    required bool applyBotCap,
    required List<String> opponentIds,
  }) {
    // Streak bonus (tiny)
    final int streak = min(playerStats.currentWinStreak * STREAK_BONUS, STREAK_MAX);

    // Repeat opponent penalty (anti-exploit) — the full check is done in
    // PlayerStatsService using PlayerExtraStats. Here it's always 0 since
    // we don't have access to stored recent opponent history in this layer.
    const int repeatPenalty = 0;

    int total = (winAmount + streak - repeatPenalty).clamp(5, 9999);

    bool botCapped = false;
    if (applyBotCap && total > BOT_STAR_CAP) {
      total = BOT_STAR_CAP;
      botCapped = true;
    }

    final parts = <String>['Base: +$winAmount'];
    if (streak > 0) parts.add('Streak: +$streak');
    if (repeatPenalty > 0) parts.add('Repeat: -$repeatPenalty');
    if (botCapped) parts.add('(bot cap $BOT_STAR_CAP)');

    return PointResult(
      blueStarsChange: total,
      heartsChange: 0,
      explanation: 'WIN: ${parts.join(', ')} = $total ⭐',
      baseExchange: winAmount,
      streakBonus: streak,
      repeatPenalty: repeatPenalty,
      wasBotCapped: botCapped,
    );
  }

  // ── LOSS ─────────────────────────────────────────────────────
  static PointResult _calculateLoss({required int lossAmount}) {
    return PointResult(
      blueStarsChange: -lossAmount,
      heartsChange: -1,
      explanation: 'LOSS: -$lossAmount ⭐, -1 ❤️',
      baseExchange: lossAmount,
    );
  }
}
