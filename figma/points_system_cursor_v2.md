# Baloot Game — Points & Progression System v2.0
# UPDATED per client feedback — complete replacement of v1
# Paste this entire file into Cursor

---

## WHAT CHANGED FROM v1 AND WHY

The client correctly identified a critical flaw in v1:
- v1 WIN:  +100 base +20 human +50 streak +30 rank = up to 200 stars per win
- v1 LOSS: -60 base = only 60 stars lost

This meant a player with 50% win rate would STILL climb the ranks over time.
Ranks represented "games played" not "actual skill." The client wants:

> "A win against an equal opponent gives roughly the same amount that a loss removes."

The new system is ELO-inspired and symmetric:
- Equal opponent: Win +50, Loss -50 (exactly balanced)
- Better opponent: Win more, Lose less
- Weaker opponent: Win less, Lose more
- A 50% win rate = ZERO net progress (rank reflects pure skill)
- Win streak bonus is tiny (max +9, not +50)
- Medals are ACHIEVEMENT-ONLY — NOT earned from every win

DO NOT implement: Cup Tickets, purchases, Gold Cards for now.
FOCUS ONLY ON: Blue Stars formula, Rank system, Achievement medals.

---

## STEP 1 — UPDATED DATA MODELS

### File: lib/models/player_stats.dart

```dart
import 'package:hive/hive.dart';
part 'player_stats.g.dart';

@HiveType(typeId: 0)
class PlayerStats extends HiveObject {

  // ── Competitive stars (goes UP and DOWN) ──────────────────────
  @HiveField(0)
  int blueStars;

  // ── Peak stars — used for rank badge (never decreases) ────────
  // When blueStars hits a new high, peakBlueStars updates.
  // Rank badge is derived from peakBlueStars with a protection floor.
  @HiveField(1)
  int peakBlueStars;

  // ── Medals — ACHIEVEMENT TROPHIES ONLY (not from wins) ────────
  // These are cosmetic/trophy medals earned from specific achievements.
  // They do NOT drive rank progression anymore.
  @HiveField(2)
  int medals;

  // ── Which achievements the player has already unlocked ────────
  @HiveField(3)
  List<String> unlockedAchievements;  // e.g. ['first_win', 'kaboot_x1', ...]

  // ── Energy ────────────────────────────────────────────────────
  @HiveField(4)
  int hearts;                          // max 20, refills over time
  @HiveField(5)
  DateTime heartsLastUpdated;

  // ── Session tracking ─────────────────────────────────────────
  @HiveField(6)
  int freeRankedSessionsUsedToday;     // resets daily, cap is 2
  @HiveField(7)
  DateTime freeSessionsLastReset;
  @HiveField(8)
  bool isSubscriber;                   // VIP/subscription status
  @HiveField(9)
  DateTime? subscriptionExpiresAt;

  // ── Anti-exploit tracking ─────────────────────────────────────
  @HiveField(10)
  List<String> recentOpponentIds;     // last 3 opponent player IDs
  @HiveField(11)
  List<String> recentPartnerIds;      // last 3 partner player IDs
  @HiveField(12)
  int currentWinStreak;

  // ── Lifetime stats for achievements ───────────────────────────
  @HiveField(13)
  int totalWins;
  @HiveField(14)
  int totalGamesPlayed;
  @HiveField(15)
  int totalKaboots;
  @HiveField(16)
  int totalRankedMinutesPlayed;       // rank badge shows after 180 min

  PlayerStats({
    this.blueStars = 0,
    this.peakBlueStars = 0,
    this.medals = 0,
    List<String>? unlockedAchievements,
    this.hearts = 20,
    DateTime? heartsLastUpdated,
    this.freeRankedSessionsUsedToday = 0,
    DateTime? freeSessionsLastReset,
    this.isSubscriber = false,
    this.subscriptionExpiresAt,
    List<String>? recentOpponentIds,
    List<String>? recentPartnerIds,
    this.currentWinStreak = 0,
    this.totalWins = 0,
    this.totalGamesPlayed = 0,
    this.totalKaboots = 0,
    this.totalRankedMinutesPlayed = 0,
  })  : heartsLastUpdated = heartsLastUpdated ?? DateTime.now(),
        freeSessionsLastReset = freeSessionsLastReset ?? DateTime.now(),
        unlockedAchievements = unlockedAchievements ?? [],
        recentOpponentIds = recentOpponentIds ?? [],
        recentPartnerIds = recentPartnerIds ?? [];
}
```

---

## STEP 2 — RANK SYSTEM (now based on Blue Stars, not medals)

### File: lib/models/rank_tier.dart

```dart
enum MainRank {
  beginner,       // مبتدئ
  amateur,        // هاوي
  good,           // جيد
  advanced,       // متقدم
  expert,         // خبير
  professional    // محترف
}

class RankTier {
  final MainRank mainRank;
  final int subLevel;   // 1 to 5

  const RankTier({required this.mainRank, required this.subLevel});

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

  int get suitIconCount => subLevel;

  @override
  String toString() => '$englishName $subLevel';
}
```

### File: lib/services/rank_calculator.dart

```dart
import '../models/rank_tier.dart';

class RankCalculator {

  // ── RANK THRESHOLDS (Blue Stars required to REACH each rank) ───
  // CHANGED FROM v1: Now driven by Blue Stars, not medals
  static const Map<MainRank, int> rankThresholds = {
    MainRank.beginner:     0,
    MainRank.amateur:      300,
    MainRank.good:         800,
    MainRank.advanced:     1800,
    MainRank.expert:       3500,
    MainRank.professional: 6500,
  };

  // ── RANK PROTECTION FLOOR ───────────────────────────────────────
  // Once you reach a rank, you cannot fall below its Tier 1 threshold.
  // This uses peakBlueStars to determine the floor.
  static const Map<MainRank, int> rankFloors = {
    MainRank.beginner:     0,
    MainRank.amateur:      300,    // can't fall below 300 once Amateur reached
    MainRank.good:         800,
    MainRank.advanced:     1800,
    MainRank.expert:       3500,
    MainRank.professional: 6500,
  };

  static const List<MainRank> rankOrder = [
    MainRank.beginner,
    MainRank.amateur,
    MainRank.good,
    MainRank.advanced,
    MainRank.expert,
    MainRank.professional,
  ];

  // ── GET RANK FROM BLUE STARS (with protection floor) ───────────
  static RankTier getRankFromStars(int blueStars, int peakBlueStars) {
    // The effective stars for rank calculation cannot go below the
    // protection floor set by the player's peak stars.
    final int effectiveStars = _applyProtectionFloor(blueStars, peakBlueStars);

    MainRank currentMain = MainRank.beginner;
    for (final rank in rankOrder.reversed) {
      if (effectiveStars >= rankThresholds[rank]!) {
        currentMain = rank;
        break;
      }
    }

    final int subLevel = _calculateSubLevel(currentMain, effectiveStars);
    return RankTier(mainRank: currentMain, subLevel: subLevel);
  }

  // Apply protection floor: effective stars cannot go below the
  // lowest threshold of the rank the player has already earned.
  static int _applyProtectionFloor(int blueStars, int peakBlueStars) {
    // Find what rank peak stars correspond to
    MainRank peakRank = MainRank.beginner;
    for (final rank in rankOrder.reversed) {
      if (peakBlueStars >= rankThresholds[rank]!) {
        peakRank = rank;
        break;
      }
    }
    // The floor is the minimum threshold of that rank
    final int floor = rankFloors[peakRank] ?? 0;
    return blueStars < floor ? floor : blueStars;
  }

  static int _calculateSubLevel(MainRank rank, int stars) {
    final int rankIndex = rankOrder.indexOf(rank);
    final int currentThreshold = rankThresholds[rank]!;
    final int nextThreshold = rankIndex < rankOrder.length - 1
        ? rankThresholds[rankOrder[rankIndex + 1]]!
        : currentThreshold + 3500;

    final int pointsPerSubLevel = (nextThreshold - currentThreshold) ~/ 5;
    if (pointsPerSubLevel == 0) return 5;

    final int starsIntoThisRank = stars - currentThreshold;
    return (starsIntoThisRank ~/ pointsPerSubLevel + 1).clamp(1, 5);
  }

  static int starsToNextSubLevel(int blueStars, int peakStars) {
    final tier = getRankFromStars(blueStars, peakStars);
    if (tier.subLevel == 5 && tier.mainRank == MainRank.professional) return 0;

    final int rankIndex = rankOrder.indexOf(tier.mainRank);
    final int currentThreshold = rankThresholds[tier.mainRank]!;
    final int nextRankThreshold = rankIndex < rankOrder.length - 1
        ? rankThresholds[rankOrder[rankIndex + 1]]!
        : currentThreshold + 3500;

    final int pointsPerSubLevel = (nextRankThreshold - currentThreshold) ~/ 5;
    final int starsIntoThisRank = blueStars - currentThreshold;
    final int starsIntoSubLevel = starsIntoThisRank % pointsPerSubLevel;
    return pointsPerSubLevel - starsIntoSubLevel;
  }

  static int rankIndex(MainRank rank) => rankOrder.indexOf(rank);

  // Returns tier difference: positive = opponent is higher ranked
  static int rankGapTiers(RankTier playerRank, RankTier opponentRank) {
    return rankIndex(opponentRank.mainRank) - rankIndex(playerRank.mainRank);
  }
}
```

---

## STEP 3 — NEW ELO-INSPIRED POINTS CALCULATOR

### File: lib/services/points_calculator.dart

```dart
import 'dart:math';
import '../models/player_stats.dart';
import '../models/rank_tier.dart';
import 'rank_calculator.dart';

// ── ENUMS ─────────────────────────────────────────────────────
enum SessionType { ranked, friendly }
enum GameResult  { win, loss }

class OpponentInfo {
  final RankTier rank;
  final bool isBot;
  final String playerId;
  const OpponentInfo({required this.rank, required this.isBot, required this.playerId});
}

class PointResult {
  final int blueStarsChange;     // positive = gained, negative = lost
  final int heartsChange;        // always 0 or -1
  final String explanation;      // for UI display

  // Breakdown for results screen
  final int baseExchange;        // the symmetric base (50 for equal, varies)
  final int streakBonus;         // small bonus for win streak
  final int repeatPenalty;       // penalty for farming same opponent
  final bool wasBotCapped;

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
class PointsCalculator {

  // ── CORE CONSTANTS (v2 — balanced) ─────────────────────────────
  // The base exchange is the stars traded between equal players.
  // Win gives BASE_EXCHANGE, Loss takes BASE_EXCHANGE. Perfectly symmetric.
  static const int BASE_EXCHANGE   = 50;

  // Each rank tier difference shifts the exchange by this amount.
  // Higher opponent = you gain more, lose less.
  static const int TIER_SHIFT      = 10;

  // Win streak bonus — MUCH smaller than v1 (was +10/win, cap 50)
  // Now: +3 per consecutive win, max +9 after 3 wins
  static const int STREAK_BONUS    = 3;
  static const int STREAK_MAX      = 9;   // caps after 3 wins

  // Penalty for playing same opponent repeatedly
  static const int REPEAT_PENALTY  = 8;

  // Bot caps — much lower than v1
  static const int BOT_STAR_CAP    = 15;  // max stars from any bot game

  // Hearts — 1 heart lost per ranked loss (no change on win)
  static const int MAX_HEARTS      = 20;
  static const int HEARTS_REGEN_MINUTES = 30;

  // ── MAIN ENTRY POINT ──────────────────────────────────────────
  static PointResult calculateMatchPoints({
    required GameResult result,
    required SessionType sessionType,
    required PlayerStats playerStats,
    required RankTier playerRank,
    required List<OpponentInfo> opponents,
    required String partnerId,
  }) {
    // Friendly: zero effect on everything
    if (sessionType == SessionType.friendly) {
      return const PointResult(
        blueStarsChange: 0,
        heartsChange: 0,
        explanation: 'Friendly game — no points affected',
      );
    }

    final bool vsBot = opponents.any((o) => o.isBot);
    final OpponentInfo mainOpponent = opponents.reduce(
      (a, b) => RankCalculator.rankIndex(a.rank.mainRank) >
                 RankCalculator.rankIndex(b.rank.mainRank) ? a : b,
    );

    // ── STEP 1: Calculate base exchange from rank gap ────────────
    // rankGap > 0 means opponent is HIGHER ranked (harder game)
    // rankGap < 0 means opponent is LOWER ranked (easier game)
    final int rankGap = RankCalculator.rankGapTiers(playerRank, mainOpponent.rank);

    // Clamp shift to max ±3 tiers worth (prevents extreme values)
    final int clampedGap = rankGap.clamp(-3, 3);
    final int shift = clampedGap * TIER_SHIFT;

    // Exchange amount this player wins or loses
    // WIN:  base + shift (more if stronger opponent, less if weaker)
    // LOSS: base - shift (less if stronger opponent, more if weaker)
    final int winAmount  = (BASE_EXCHANGE + shift).clamp(15, 80);
    final int lossAmount = (BASE_EXCHANGE - shift).clamp(10, 75);

    // ── STEP 2: Apply modifiers ──────────────────────────────────
    bool wasBotCapped = false;

    if (result == GameResult.win) {
      // Win streak bonus (tiny)
      final int streakBonus = min(playerStats.currentWinStreak * STREAK_BONUS, STREAK_MAX);

      // Repeat opponent penalty
      int repeatPenalty = 0;
      for (final opp in opponents) {
        if (playerStats.recentOpponentIds.contains(opp.playerId)) {
          repeatPenalty = REPEAT_PENALTY;
          break;
        }
      }

      int total = winAmount + streakBonus - repeatPenalty;
      total = total.clamp(5, 9999);

      // Bot cap: hard ceiling for bot games
      if (vsBot && total > BOT_STAR_CAP) {
        total = BOT_STAR_CAP;
        wasBotCapped = true;
      }

      final parts = <String>['Base: +$winAmount'];
      if (streakBonus > 0) parts.add('Streak: +$streakBonus');
      if (repeatPenalty > 0) parts.add('Repeat: -$repeatPenalty');
      if (wasBotCapped) parts.add('(bot cap)');

      return PointResult(
        blueStarsChange: total,
        heartsChange: 0,
        explanation: 'WIN: ${parts.join(', ')} = $total stars',
        baseExchange: winAmount,
        streakBonus: streakBonus,
        repeatPenalty: repeatPenalty,
        wasBotCapped: wasBotCapped,
      );

    } else {
      // LOSS
      int total = lossAmount;
      total = total.clamp(10, 75);

      return PointResult(
        blueStarsChange: -total,
        heartsChange: -1,  // lose 1 heart on ranked loss
        explanation: 'LOSS: -$total stars, -1 heart',
        baseExchange: lossAmount,
      );
    }
  }
}
```

---

## STEP 4 — ACHIEVEMENT SYSTEM (replaces medal-per-win)

### File: lib/services/achievement_service.dart

```dart
import '../models/player_stats.dart';
import 'rank_calculator.dart';

// ── ACHIEVEMENT DEFINITIONS ─────────────────────────────────────
// Medals are now ONLY earned through achievements.
// Each achievement can only be unlocked ONCE per player.
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

class AchievementService {

  static const List<Achievement> allAchievements = [

    // ── FIRST STEPS ───────────────────────────────────────────────
    Achievement(id: 'first_game',  arabicName: 'الخطوة الأولى', englishName: 'First Step',
        medalReward: 5,   description: 'Play your first ranked match'),
    Achievement(id: 'first_win',   arabicName: 'أول انتصار',   englishName: 'First Victory',
        medalReward: 10,  description: 'Win your first ranked match'),

    // ── WIN MILESTONES ────────────────────────────────────────────
    Achievement(id: 'wins_10',    arabicName: '10 انتصارات',  englishName: '10 Victories',
        medalReward: 20,  description: 'Win 10 ranked matches'),
    Achievement(id: 'wins_25',    arabicName: '25 انتصارات',  englishName: '25 Victories',
        medalReward: 35,  description: 'Win 25 ranked matches'),
    Achievement(id: 'wins_50',    arabicName: '50 انتصارات',  englishName: '50 Victories',
        medalReward: 60,  description: 'Win 50 ranked matches'),
    Achievement(id: 'wins_100',   arabicName: 'مئة انتصار',   englishName: '100 Victories',
        medalReward: 100, description: 'Win 100 ranked matches'),
    Achievement(id: 'wins_250',   arabicName: '250 انتصارات', englishName: '250 Victories',
        medalReward: 200, description: 'Win 250 ranked matches'),

    // ── GAMES PLAYED ──────────────────────────────────────────────
    Achievement(id: 'games_10',   arabicName: 'لاعب نشيط',   englishName: 'Active Player',
        medalReward: 10,  description: 'Play 10 ranked matches'),
    Achievement(id: 'games_50',   arabicName: 'مخضرم',        englishName: 'Veteran',
        medalReward: 30,  description: 'Play 50 ranked matches'),
    Achievement(id: 'games_100',  arabicName: 'لاعب محترف',   englishName: 'Pro Player',
        medalReward: 60,  description: 'Play 100 ranked matches'),
    Achievement(id: 'games_500',  arabicName: 'أسطورة البلوت', englishName: 'Baloot Legend',
        medalReward: 150, description: 'Play 500 ranked matches'),

    // ── WIN STREAKS ───────────────────────────────────────────────
    Achievement(id: 'streak_3',   arabicName: 'ثلاثية',       englishName: 'Hat Trick',
        medalReward: 15,  description: 'Win 3 matches in a row'),
    Achievement(id: 'streak_5',   arabicName: 'سلسلة ذهبية',  englishName: 'Golden Streak',
        medalReward: 30,  description: 'Win 5 matches in a row'),
    Achievement(id: 'streak_10',  arabicName: 'غير قابل للإيقاف', englishName: 'Unstoppable',
        medalReward: 75,  description: 'Win 10 matches in a row'),

    // ── KABOOT ────────────────────────────────────────────────────
    Achievement(id: 'kaboot_1',   arabicName: 'أول كبوت',     englishName: 'First Kaboot',
        medalReward: 20,  description: 'Win all 8 tricks in a match'),
    Achievement(id: 'kaboot_5',   arabicName: 'سيد الكبوت',   englishName: 'Kaboot Master',
        medalReward: 50,  description: 'Achieve Kaboot 5 times'),
    Achievement(id: 'kaboot_25',  arabicName: 'أسطورة الكبوت', englishName: 'Kaboot Legend',
        medalReward: 100, description: 'Achieve Kaboot 25 times'),

    // ── RANK MILESTONES (biggest medals — unlocked when first reaching rank) ──
    Achievement(id: 'reach_amateur',       arabicName: 'هاوي',   englishName: 'Reached Amateur',
        medalReward: 50,   description: 'Reach Amateur rank for the first time'),
    Achievement(id: 'reach_good',          arabicName: 'جيد',    englishName: 'Reached Good',
        medalReward: 100,  description: 'Reach Good rank for the first time'),
    Achievement(id: 'reach_advanced',      arabicName: 'متقدم',  englishName: 'Reached Advanced',
        medalReward: 200,  description: 'Reach Advanced rank for the first time'),
    Achievement(id: 'reach_expert',        arabicName: 'خبير',   englishName: 'Reached Expert',
        medalReward: 400,  description: 'Reach Expert rank for the first time'),
    Achievement(id: 'reach_professional',  arabicName: 'محترف',  englishName: 'Reached Professional',
        medalReward: 800,  description: 'Reach Professional rank for the first time'),

    // ── SPECIAL ───────────────────────────────────────────────────
    Achievement(id: 'baloot_declared',  arabicName: 'أول بلوت',  englishName: 'First Baloot',
        medalReward: 15,  description: 'Declare Baloot (K+Q of trump) for the first time'),
    Achievement(id: 'beat_expert',     arabicName: 'ضربة حظ',    englishName: 'Underdog Win',
        medalReward: 30,  description: 'Win against an Expert or Professional as a Beginner or Amateur'),
  ];

  // ── CHECK AND UNLOCK ACHIEVEMENTS AFTER EACH GAME ─────────────
  // Returns list of newly unlocked achievements (to show celebration UI)
  static List<Achievement> checkAchievements(
    PlayerStats stats,
    GameResult result,
    bool wasKaboot,
    bool balootDeclared,
    RankTier playerRank,
    RankTier opponentRank,
  ) {
    final List<Achievement> newlyUnlocked = [];

    void tryUnlock(String achievementId) {
      if (!stats.unlockedAchievements.contains(achievementId)) {
        final achievement = allAchievements.firstWhere(
          (a) => a.id == achievementId,
          orElse: () => throw Exception('Achievement not found: $achievementId'),
        );
        stats.unlockedAchievements.add(achievementId);
        stats.medals += achievement.medalReward;
        newlyUnlocked.add(achievement);
      }
    }

    // First game
    if (stats.totalGamesPlayed >= 1)  tryUnlock('first_game');
    if (stats.totalGamesPlayed >= 10) tryUnlock('games_10');
    if (stats.totalGamesPlayed >= 50) tryUnlock('games_50');
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
      if (stats.totalKaboots >= 1)  tryUnlock('kaboot_1');
      if (stats.totalKaboots >= 5)  tryUnlock('kaboot_5');
      if (stats.totalKaboots >= 25) tryUnlock('kaboot_25');
    }

    // Baloot declared
    if (balootDeclared) tryUnlock('baloot_declared');

    // Underdog win
    if (result == GameResult.win) {
      final playerIsLow = RankCalculator.rankIndex(playerRank.mainRank) <= 1;
      final opponentIsHigh = RankCalculator.rankIndex(opponentRank.mainRank) >= 4;
      if (playerIsLow && opponentIsHigh) tryUnlock('beat_expert');
    }

    return newlyUnlocked;
  }

  // ── CHECK RANK MILESTONE ACHIEVEMENTS ─────────────────────────
  // Call this after updating player stars / rank
  static List<Achievement> checkRankMilestones(
    PlayerStats stats, RankTier newRank) {
    final List<Achievement> newlyUnlocked = [];

    void tryUnlock(String id) {
      if (!stats.unlockedAchievements.contains(id)) {
        final a = allAchievements.firstWhere((x) => x.id == id);
        stats.unlockedAchievements.add(id);
        stats.medals += a.medalReward;
        newlyUnlocked.add(a);
      }
    }

    switch (newRank.mainRank) {
      case MainRank.amateur:       tryUnlock('reach_amateur'); break;
      case MainRank.good:          tryUnlock('reach_good'); break;
      case MainRank.advanced:      tryUnlock('reach_advanced'); break;
      case MainRank.expert:        tryUnlock('reach_expert'); break;
      case MainRank.professional:  tryUnlock('reach_professional'); break;
      default: break;
    }

    return newlyUnlocked;
  }
}
```

---

## STEP 5 — POINTS SERVICE (apply results to player)

### File: lib/services/points_service.dart

```dart
import 'dart:math';
import '../models/player_stats.dart';
import '../models/rank_tier.dart';
import 'points_calculator.dart';
import 'rank_calculator.dart';
import 'achievement_service.dart';

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
  final List<Achievement> newAchievements;  // to show celebration UI

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

class PointsService {

  static MatchOutcome applyMatchResult({
    required PlayerStats stats,
    required PointResult result,
    required GameResult gameResult,
    required String opponentId1,
    required String opponentId2,
    required String partnerId,
    required RankTier opponentRank,
    bool wasKaboot = false,
    bool balootDeclared = false,
  }) {
    final RankTier oldRank = RankCalculator.getRankFromStars(
        stats.blueStars, stats.peakBlueStars);
    final int oldStars = stats.blueStars;
    final int oldMedals = stats.medals;

    // ── Apply stars change ────────────────────────────────────────
    stats.blueStars = max(0, stats.blueStars + result.blueStarsChange);

    // Update peak stars — never decreases
    if (stats.blueStars > stats.peakBlueStars) {
      stats.peakBlueStars = stats.blueStars;
    }

    // ── Apply hearts ──────────────────────────────────────────────
    stats.hearts = (stats.hearts + result.heartsChange).clamp(0, PointsCalculator.MAX_HEARTS);

    // ── Update win streak ─────────────────────────────────────────
    if (gameResult == GameResult.win) {
      stats.currentWinStreak += 1;
      stats.totalWins += 1;
    } else {
      stats.currentWinStreak = 0;
    }
    stats.totalGamesPlayed += 1;

    // ── Update kaboot count ───────────────────────────────────────
    if (wasKaboot) stats.totalKaboots += 1;

    // ── Update recent opponents (anti-exploit) ────────────────────
    stats.recentOpponentIds.add(opponentId1);
    stats.recentOpponentIds.add(opponentId2);
    while (stats.recentOpponentIds.length > 3) {
      stats.recentOpponentIds.removeAt(0);
    }
    stats.recentPartnerIds.add(partnerId);
    while (stats.recentPartnerIds.length > 3) {
      stats.recentPartnerIds.removeAt(0);
    }

    // ── Get new rank ──────────────────────────────────────────────
    final RankTier newRank = RankCalculator.getRankFromStars(
        stats.blueStars, stats.peakBlueStars);

    final bool rankedUp = RankCalculator.rankIndex(newRank.mainRank) >
                          RankCalculator.rankIndex(oldRank.mainRank);
    final bool rankedDown = RankCalculator.rankIndex(newRank.mainRank) <
                             RankCalculator.rankIndex(oldRank.mainRank);

    // ── Check achievements (unlocks medals) ───────────────────────
    final List<Achievement> newAchievements = AchievementService.checkAchievements(
      stats, gameResult, wasKaboot, balootDeclared, oldRank, opponentRank,
    );

    // Also check rank milestone achievements
    if (rankedUp) {
      newAchievements.addAll(
        AchievementService.checkRankMilestones(stats, newRank),
      );
    }

    stats.save();

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

  // ── HEARTS REFILL ──────────────────────────────────────────────
  static void refillHearts(PlayerStats stats) {
    if (stats.isSubscriber) {
      stats.hearts = PointsCalculator.MAX_HEARTS;
      stats.heartsLastUpdated = DateTime.now();
      stats.save();
      return;
    }

    final DateTime now = DateTime.now();
    final int minutesElapsed = now.difference(stats.heartsLastUpdated).inMinutes;
    final int heartsToAdd = minutesElapsed ~/ PointsCalculator.HEARTS_REGEN_MINUTES;

    if (heartsToAdd > 0) {
      stats.hearts = min(PointsCalculator.MAX_HEARTS, stats.hearts + heartsToAdd);
      stats.heartsLastUpdated = stats.heartsLastUpdated.add(
        Duration(minutes: heartsToAdd * PointsCalculator.HEARTS_REGEN_MINUTES),
      );
      stats.save();
    }
  }

  // ── FREE SESSION GATE ──────────────────────────────────────────
  static bool canPlayRankedForFree(PlayerStats stats) {
    if (stats.isSubscriber) return true;

    final DateTime now = DateTime.now();
    final bool isNewDay = now.day != stats.freeSessionsLastReset.day ||
                          now.month != stats.freeSessionsLastReset.month;
    if (isNewDay) {
      stats.freeRankedSessionsUsedToday = 0;
      stats.freeSessionsLastReset = now;
      stats.save();
    }

    // 2 free ranked sessions per day for non-subscribers
    return stats.freeRankedSessionsUsedToday < 2;
  }

  static void recordFreeSessionUsed(PlayerStats stats) {
    stats.freeRankedSessionsUsedToday += 1;
    stats.save();
  }

  static bool shouldShowRankBadge(PlayerStats stats) {
    return stats.totalRankedMinutesPlayed >= 180;
  }

  static void addRankedPlayTime(PlayerStats stats, int minutesPlayed) {
    stats.totalRankedMinutesPlayed += minutesPlayed;
    stats.save();
  }
}
```

---

## STEP 6 — HOW TO CALL IT (integration in game screen)

```dart
void onGameComplete({
  required bool playerWon,
  required bool wasKaboot,
  required bool balootDeclared,
  required bool opponentIsBot,
  required String opponent1Id,
  required String opponent2Id,
  required String partnerId,
  required PlayerStats myStats,
  required PlayerStats opponentStats,
}) {
  // 1. Get current ranks
  final playerRank = RankCalculator.getRankFromStars(
    myStats.blueStars, myStats.peakBlueStars);
  final opponentRank = RankCalculator.getRankFromStars(
    opponentStats.blueStars, opponentStats.peakBlueStars);

  // 2. Calculate the star change
  final result = PointsCalculator.calculateMatchPoints(
    result:      playerWon ? GameResult.win : GameResult.loss,
    sessionType: SessionType.ranked,
    playerStats: myStats,
    playerRank:  playerRank,
    opponents: [
      OpponentInfo(rank: opponentRank, isBot: opponentIsBot, playerId: opponent1Id),
      OpponentInfo(rank: opponentRank, isBot: opponentIsBot, playerId: opponent2Id),
    ],
    partnerId: partnerId,
  );

  // 3. Apply and get full outcome (includes achievements)
  final outcome = PointsService.applyMatchResult(
    stats:          myStats,
    result:         result,
    gameResult:     playerWon ? GameResult.win : GameResult.loss,
    opponentId1:    opponent1Id,
    opponentId2:    opponent2Id,
    partnerId:      partnerId,
    opponentRank:   opponentRank,
    wasKaboot:      wasKaboot,
    balootDeclared: balootDeclared,
  );

  // 4. Show results screen
  showResultsScreen(outcome);

  // 5. If new achievements unlocked — show celebration
  if (outcome.newAchievements.isNotEmpty) {
    showAchievementCelebration(outcome.newAchievements);
  }

  // 6. If rank changed — show animation
  if (outcome.rankedUp) playRankUpAnimation(outcome.newRank);
  if (outcome.rankedDown) playRankDownAnimation(outcome.newRank);
}
```

---

## STEP 7 — RESULTS SCREEN UI BREAKDOWN (show these to player)

```
// WIN example (equal rank opponent):
//   ⭐ Base:           +50
//   🔥 Win streak:     +6  (2 consecutive wins × 3)
//   ────────────────────────
//   Total:            +56 stars
//   ❤️  Hearts:         No change
//
// WIN example (vs 2 tiers higher opponent):
//   ⭐ Base:           +70  (50 + 10×2 rank shift)
//   🔥 Win streak:     +3
//   ────────────────────────
//   Total:            +73 stars
//
// LOSS example (equal rank opponent):
//   ⭐ Base:           -50
//   ────────────────────────
//   Total:            -50 stars
//   ❤️  Hearts:         -1
//
// LOSS example (vs 2 tiers higher opponent):
//   ⭐ Base:           -30  (50 - 10×2 rank shift)
//   ────────────────────────
//   Total:            -30 stars
//   ❤️  Hearts:         -1
//
// If achievement unlocked: show medal award card separately
```

---

## QUICK REFERENCE TABLE — NEW v2 NUMBERS

| Scenario                      | Stars     | Medals        | Hearts |
|-------------------------------|-----------|---------------|--------|
| Win vs same rank              | +50       | 0 (no win medals) | 0  |
| Win vs 1 rank above           | +60       | 0             | 0      |
| Win vs 2 ranks above          | +70       | 0             | 0      |
| Win vs 3 ranks above          | +80       | 0             | 0      |
| Win vs 1 rank below           | +40       | 0             | 0      |
| Win vs 2 ranks below          | +30       | 0             | 0      |
| Win vs 3 ranks below          | +20       | 0             | 0      |
| Win vs bot                    | +15 max   | 0             | 0      |
| Win streak +3 per win (max+9) | +3/+6/+9  | 0             | 0      |
| Loss vs same rank             | -50       | 0             | -1     |
| Loss vs 1 rank above          | -40       | 0             | -1     |
| Loss vs 2 ranks above         | -30       | 0             | -1     |
| Loss vs 3 ranks above         | -20       | 0             | -1     |
| Loss vs 1 rank below          | -60       | 0             | -1     |
| Loss vs 2 ranks below         | -70       | 0             | -1     |
| Loss vs 3 ranks below         | -80       | 0             | -1     |
| Friendly game                 | 0         | 0             | 0      |
| Achievement unlock            | 0         | +5 to +800    | 0      |

## KEY PROOF: 50% WIN RATE = ZERO NET PROGRESS

Player A (same rank):
- Session 1: Win → +50 stars
- Session 2: Loss → -50 stars
- Session 3: Win → +50 stars
- Session 4: Loss → -50 stars
- Net after 4 sessions: 0 stars ← rank reflects SKILL, not games played ✅

## WHAT TO TELL CURSOR

"Replace the entire points_calculator.dart, points_service.dart, and rank_calculator.dart 
with the new v2 versions in this file. The key changes are:
1. Win and loss are now symmetric: equal opponents = +50 win, -50 loss
2. Rank gap shifts the amount: stronger opponent = more on win, less on loss
3. Win streak bonus is tiny: +3 per win, max +9 total
4. Medals are NO LONGER earned from wins — remove all medal calculations from 
   win/loss flow — medals now come only from achievements
5. Rank is now determined by Blue Stars (with protection floor from peakBlueStars),
   not from medals
6. Add the AchievementService — check after every game and after rank changes
7. Keep hearts system exactly as before
8. Do NOT implement Cup Tickets or Gold Cards purchases yet"
