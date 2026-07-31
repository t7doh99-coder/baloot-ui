import '../../data/models/rank_tier.dart';

/// v2: Rank is now driven by blueStars (with peakBlueStars protection floor),
/// NOT by medals. Medals are achievement-only cosmetics.
class RankCalculator {

  // ── RANK THRESHOLDS (Blue Stars required to REACH each rank) ──
  static const Map<MainRank, int> rankThresholds = {
    MainRank.beginner:     0,
    MainRank.amateur:      300,
    MainRank.good:         800,
    MainRank.advanced:     1800,
    MainRank.expert:       3500,
    MainRank.professional: 6500,
  };

  // ── RANK PROTECTION FLOOR ──────────────────────────────────────
  // Once you reach a rank, blueStars can't effectively go below this.
  // Uses peakBlueStars to determine the floor.
  static const Map<MainRank, int> rankFloors = {
    MainRank.beginner:     0,
    MainRank.amateur:      300,
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

  // ── GET RANK FROM BLUE STARS (primary v2 method) ───────────────
  static RankTier getRankFromStars(int blueStars, int peakBlueStars) {
    final int effective = _applyProtectionFloor(blueStars, peakBlueStars);

    MainRank currentMain = MainRank.beginner;
    for (final rank in rankOrder.reversed) {
      if (effective >= rankThresholds[rank]!) {
        currentMain = rank;
        break;
      }
    }

    final int sub = _calculateSubLevel(currentMain, effective);
    return RankTier(mainRank: currentMain, subLevel: sub);
  }

  // ── BACKWARD-COMPAT ALIAS — treats blueStars as the "medals" arg ─
  // Existing UI calls getRankFromMedals(stats.medals).
  // Since the model still has 'medals' as a cosmetic count, we keep
  // this alias but now it works on blueStars internally via the caller
  // passing stats.blueStars directly (game_provider already does so after
  // this update). Old callers passing stats.medals will still compile;
  // functionally they'll use the new thresholds which are lower, so they
  // might get a slightly different rank — that is intentional (v2 reset).
  static RankTier getRankFromMedals(int stars) {
    // Treat as blueStars with no peak protection (safe default)
    return getRankFromStars(stars, stars);
  }

  // Apply protection floor using peak stars
  static int _applyProtectionFloor(int blueStars, int peakBlueStars) {
    MainRank peakRank = MainRank.beginner;
    for (final rank in rankOrder.reversed) {
      if (peakBlueStars >= rankThresholds[rank]!) {
        peakRank = rank;
        break;
      }
    }
    final int floor = rankFloors[peakRank] ?? 0;
    return blueStars < floor ? floor : blueStars;
  }

  static int _calculateSubLevel(MainRank rank, int stars) {
    final int idx = rankOrder.indexOf(rank);
    final int cur = rankThresholds[rank]!;
    final int next = idx < rankOrder.length - 1
        ? rankThresholds[rankOrder[idx + 1]]!
        : cur + 3500;

    final int pointsPerSub = (next - cur) ~/ 5;
    if (pointsPerSub == 0) return 5;

    final int starsIn = stars - cur;
    return (starsIn ~/ pointsPerSub + 1).clamp(1, 5);
  }

  // ── STARS TO NEXT SUB-LEVEL ───────────────────────────────────
  static int starsToNextSubLevel(int blueStars, int peakStars) {
    final tier = getRankFromStars(blueStars, peakStars);
    if (tier.subLevel == 5 && tier.mainRank == MainRank.professional) return 0;

    final int idx = rankOrder.indexOf(tier.mainRank);
    final int cur = rankThresholds[tier.mainRank]!;
    final int next = idx < rankOrder.length - 1
        ? rankThresholds[rankOrder[idx + 1]]!
        : cur + 3500;

    final int pps = (next - cur) ~/ 5;
    final int starsIn = blueStars - cur;
    return pps - (starsIn % pps);
  }

  // ── BACKWARD-COMPAT: medalsToNextSubLevel (uses blueStars) ────
  static int medalsToNextSubLevel(int stars) => starsToNextSubLevel(stars, stars);

  // ── PROGRESS 0.0–1.0 to next sub-level ───────────────────────
  static double progressToNextSubLevel(int stars) {
    final tier = getRankFromMedals(stars);
    if (tier.subLevel == 5 && tier.mainRank == MainRank.professional) return 1.0;

    final int idx = rankOrder.indexOf(tier.mainRank);
    final int cur = rankThresholds[tier.mainRank]!;
    final int next = idx < rankOrder.length - 1
        ? rankThresholds[rankOrder[idx + 1]]!
        : cur + 3500;

    final int pps = (next - cur) ~/ 5;
    if (pps == 0) return 1.0;

    final int starsIn = stars - cur;
    return (starsIn % pps) / pps;
  }

  // ── RANK COMPARISON ──────────────────────────────────────────
  static int rankIndex(MainRank rank) => rankOrder.indexOf(rank);

  static int rankGapTiers(RankTier playerRank, RankTier opponentRank) {
    return rankIndex(opponentRank.mainRank) - rankIndex(playerRank.mainRank);
  }
}
