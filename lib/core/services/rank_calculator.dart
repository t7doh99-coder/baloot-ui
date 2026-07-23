import '../../data/models/rank_tier.dart';

class RankCalculator {
  // ── RANK THRESHOLDS (medals required to REACH each main rank) ──
  static const Map<MainRank, int> rankThresholds = {
    MainRank.beginner:     0,
    MainRank.amateur:      500,
    MainRank.good:         1500,
    MainRank.advanced:     3500,
    MainRank.expert:       7500,
    MainRank.professional: 15000,
  };

  static const List<MainRank> rankOrder = [
    MainRank.beginner,
    MainRank.amateur,
    MainRank.good,
    MainRank.advanced,
    MainRank.expert,
    MainRank.professional,
  ];

  // ── GET CURRENT RANK FROM MEDAL COUNT ──────────────────────────
  static RankTier getRankFromMedals(int medals) {
    MainRank currentMain = MainRank.beginner;

    // Find highest main rank the player has reached
    for (final rank in rankOrder.reversed) {
      if (medals >= rankThresholds[rank]!) {
        currentMain = rank;
        break;
      }
    }

    // Calculate sub-level within this main rank
    final currentThreshold = rankThresholds[currentMain]!;
    final int subLevel = _calculateSubLevel(currentMain, medals, currentThreshold);

    return RankTier(mainRank: currentMain, subLevel: subLevel);
  }

  static int _calculateSubLevel(MainRank rank, int medals, int currentThreshold) {
    // Get the next rank threshold (or add 5000 for professional as the max tier)
    final int rankIndex = rankOrder.indexOf(rank);
    final int nextThreshold = rankIndex < rankOrder.length - 1
        ? rankThresholds[rankOrder[rankIndex + 1]]!
        : currentThreshold + 5000;

    // Points needed per sub-level = gap to next rank ÷ 5
    final int pointsPerSubLevel = (nextThreshold - currentThreshold) ~/ 5;
    if (pointsPerSubLevel == 0) return 5;

    final int medalsIntoThisRank = medals - currentThreshold;
    final int subLevel = (medalsIntoThisRank ~/ pointsPerSubLevel) + 1;

    return subLevel.clamp(1, 5);
  }

  // ── MEDALS NEEDED FOR NEXT SUB-LEVEL ──────────────────────────
  static int medalsToNextSubLevel(int currentMedals) {
    final tier = getRankFromMedals(currentMedals);
    if (tier.subLevel == 5 && tier.mainRank == MainRank.professional) return 0;

    final int rankIndex = rankOrder.indexOf(tier.mainRank);
    final int currentThreshold = rankThresholds[tier.mainRank]!;
    final int nextRankThreshold = rankIndex < rankOrder.length - 1
        ? rankThresholds[rankOrder[rankIndex + 1]]!
        : currentThreshold + 5000;

    final int pointsPerSubLevel = (nextRankThreshold - currentThreshold) ~/ 5;
    final int medalsIntoThisRank = currentMedals - currentThreshold;
    final int medalsIntoSubLevel = medalsIntoThisRank % pointsPerSubLevel;

    return pointsPerSubLevel - medalsIntoSubLevel;
  }
  
  static double progressToNextSubLevel(int currentMedals) {
    final tier = getRankFromMedals(currentMedals);
    if (tier.subLevel == 5 && tier.mainRank == MainRank.professional) return 1.0;
    
    final int rankIndex = rankOrder.indexOf(tier.mainRank);
    final int currentThreshold = rankThresholds[tier.mainRank]!;
    final int nextRankThreshold = rankIndex < rankOrder.length - 1
        ? rankThresholds[rankOrder[rankIndex + 1]]!
        : currentThreshold + 5000;

    final int pointsPerSubLevel = (nextRankThreshold - currentThreshold) ~/ 5;
    final int medalsIntoThisRank = currentMedals - currentThreshold;
    final int medalsIntoSubLevel = medalsIntoThisRank % pointsPerSubLevel;
    
    if (pointsPerSubLevel == 0) return 1.0;
    
    return medalsIntoSubLevel / pointsPerSubLevel;
  }

  // ── RANK COMPARISON (for point modifier calculations) ──────────
  // Returns the rank index (0=Beginner, 5=Professional)
  static int rankIndex(MainRank rank) => rankOrder.indexOf(rank);

  // Returns difference in rank tiers between two players
  // Positive = opponent is higher ranked than player
  static int rankGapTiers(RankTier playerRank, RankTier opponentRank) {
    return rankIndex(opponentRank.mainRank) - rankIndex(playerRank.mainRank);
  }
}
