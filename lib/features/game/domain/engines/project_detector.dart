import '../../../../data/models/card_model.dart';
import '../../../../data/models/round_state_model.dart';

/// Detected project in a player's hand.
class DetectedProject {
  final ProjectType type;
  final List<CardModel> cards;

  /// The highest card's standard strength (for tie-breaking).
  final int highestStrength;

  const DetectedProject({
    required this.type,
    required this.cards,
    required this.highestStrength,
  });

  int get priorityRank {
    switch (type) {
      case ProjectType.sera:
        return 1;
      case ProjectType.fifty:
        return 2;
      case ProjectType.hundred:
        return 3;
      case ProjectType.fourHundred:
        return 4;
      case ProjectType.baloot:
        return 0;
    }
  }
}

/// Scans hands to detect projects per BALOOT_RULES.md Section 6.
///
/// Projects:
/// - Sera: 3 consecutive same suit
/// - 50: 4 consecutive same suit
/// - 100: 5 consecutive same suit, OR 4×(10/J/Q/K) same suit, OR 4 Aces (Hakam only)
/// - 400: 4 Aces (Sun only)
/// - Baloot: K+Q of trump (Hakam only, auto-detected)
class ProjectDetector {
  const ProjectDetector();

  /// Rank indices for sequence detection (standard order: 7,8,9,10,J,Q,K,A).
  static const _rankOrder = {
    Rank.seven: 0,
    Rank.eight: 1,
    Rank.nine: 2,
    Rank.ten: 3,
    Rank.jack: 4,
    Rank.queen: 5,
    Rank.king: 6,
    Rank.ace: 7,
  };

  /// Detect all projects in a hand. Max 2 non-Baloot projects per player.
  /// Baloot is separate and always auto-detected.
  List<DetectedProject> detectAll(List<CardModel> hand, GameMode mode, {Suit? trumpSuit}) {
    final projects = <DetectedProject>[];

    // Detect sequence-based projects (Sera, 50, 100-sequence)
    projects.addAll(_detectSequences(hand, mode));

    // Detect 4-of-a-kind projects
    projects.addAll(_detectFourOfAKind(hand, mode));

    // Detect Baloot (Hakam only)
    if (mode == GameMode.hakam && trumpSuit != null) {
      final baloot = _detectBaloot(hand, trumpSuit);
      if (baloot != null) projects.add(baloot);
    }

    // Sort by priority (highest first), then by highest card strength
    projects.sort((a, b) {
      final cmp = b.priorityRank.compareTo(a.priorityRank);
      if (cmp != 0) return cmp;
      return b.highestStrength.compareTo(a.highestStrength);
    });

    // Separate Baloot from regular projects (Baloot doesn't count against limit)
    final balootProjects = projects.where((p) => p.type == ProjectType.baloot).toList();
    final regularProjects = projects.where((p) => p.type != ProjectType.baloot).toList();

    // Max 2 regular projects per player
    final limited = regularProjects.take(2).toList();
    limited.addAll(balootProjects);

    return limited;
  }

  /// Find consecutive card sequences of the same suit.
  List<DetectedProject> _detectSequences(List<CardModel> hand, GameMode mode) {
    final projects = <DetectedProject>[];

    // Group cards by suit
    final bySuit = <Suit, List<CardModel>>{};
    for (final card in hand) {
      bySuit.putIfAbsent(card.suit, () => []).add(card);
    }

    for (final entry in bySuit.entries) {
      final suitCards = entry.value;
      if (suitCards.length < 3) continue;

      // Sort by rank order
      suitCards.sort((a, b) => _rankOrder[a.rank]!.compareTo(_rankOrder[b.rank]!));

      // Find all consecutive runs
      final runs = _findConsecutiveRuns(suitCards);

      for (final run in runs) {
        if (run.length >= 5 && mode == GameMode.hakam) {
          // 100 (5-consecutive, Hakam only)
          final highest = run.last.getStrength(mode: GameMode.sun);
          projects.add(DetectedProject(
            type: ProjectType.hundred,
            cards: run,
            highestStrength: highest,
          ));
        } else if (run.length >= 4) {
          // 50 (4-consecutive)
          final highest = run.last.getStrength(mode: GameMode.sun);
          projects.add(DetectedProject(
            type: ProjectType.fifty,
            cards: run.length > 4 ? run.sublist(run.length - 4) : run,
            highestStrength: highest,
          ));
        } else if (run.length >= 3) {
          // Sera (3-consecutive)
          final highest = run.last.getStrength(mode: GameMode.sun);
          projects.add(DetectedProject(
            type: ProjectType.sera,
            cards: run,
            highestStrength: highest,
          ));
        }
      }
    }

    return projects;
  }

  /// Find runs of consecutive ranks within sorted same-suit cards.
  List<List<CardModel>> _findConsecutiveRuns(List<CardModel> sorted) {
    if (sorted.isEmpty) return [];

    final runs = <List<CardModel>>[];
    var currentRun = [sorted.first];

    for (int i = 1; i < sorted.length; i++) {
      final prevIdx = _rankOrder[sorted[i - 1].rank]!;
      final currIdx = _rankOrder[sorted[i].rank]!;

      if (currIdx == prevIdx + 1) {
        currentRun.add(sorted[i]);
      } else {
        if (currentRun.length >= 3) runs.add(List.from(currentRun));
        currentRun = [sorted[i]];
      }
    }
    if (currentRun.length >= 3) runs.add(currentRun);

    return runs;
  }

  /// Detect 4-of-a-kind projects:
  /// - 4 Aces in Sun → 400
  /// - 4 Aces in Hakam → 100
  /// - 4×(10/J/Q/K) same suit → 100 (Hakam only)
  List<DetectedProject> _detectFourOfAKind(List<CardModel> hand, GameMode mode) {
    final projects = <DetectedProject>[];

    // 4 Aces
    final aces = hand.where((c) => c.rank == Rank.ace).toList();
    if (aces.length == 4) {
      if (mode == GameMode.sun) {
        projects.add(DetectedProject(
          type: ProjectType.fourHundred,
          cards: aces,
          highestStrength: aces.first.getStrength(mode: GameMode.sun),
        ));
      } else {
        // 4 Aces in Hakam = 100
        projects.add(DetectedProject(
          type: ProjectType.hundred,
          cards: aces,
          highestStrength: aces.first.getStrength(mode: GameMode.sun),
        ));
      }
    }

    // 4×(10/J/Q/K) of same suit → 100 (Hakam only)
    if (mode == GameMode.hakam) {
      final courtRanks = {Rank.ten, Rank.jack, Rank.queen, Rank.king};
      for (final suit in Suit.values) {
        final courtCards = hand.where(
          (c) => c.suit == suit && courtRanks.contains(c.rank),
        ).toList();
        if (courtCards.length == 4) {
          final highest = courtCards
              .map((c) => c.getStrength(mode: GameMode.sun))
              .reduce((a, b) => a > b ? a : b);
          projects.add(DetectedProject(
            type: ProjectType.hundred,
            cards: courtCards,
            highestStrength: highest,
          ));
        }
      }
    }

    return projects;
  }

  /// Detect Baloot: K+Q of trump suit (Hakam only).
  DetectedProject? _detectBaloot(List<CardModel> hand, Suit trumpSuit) {
    final hasKing = hand.any((c) => c.suit == trumpSuit && c.rank == Rank.king);
    final hasQueen = hand.any((c) => c.suit == trumpSuit && c.rank == Rank.queen);

    if (hasKing && hasQueen) {
      final cards = hand
          .where((c) =>
              c.suit == trumpSuit &&
              (c.rank == Rank.king || c.rank == Rank.queen))
          .toList();
      return DetectedProject(
        type: ProjectType.baloot,
        cards: cards,
        highestStrength: 0,
      );
    }
    return null;
  }

  /// Compare two teams' projects and determine which team's projects count.
  /// Returns 'A', 'B', or null (if no projects declared).
  ///
  /// Per BALOOT_RULES.md Section 6.3:
  /// Both teams compare highest project. Superior project wins.
  /// If tied rank → highest card in sequence wins.
  /// Only winning team's project Abnat is counted.
  String? resolveProjectPriority(
    List<DeclaredProject> teamAProjects,
    List<DeclaredProject> teamBProjects,
  ) {
    // Filter out Baloot (doesn't participate in priority)
    final aRegular = teamAProjects.where((p) => p.type != ProjectType.baloot).toList();
    final bRegular = teamBProjects.where((p) => p.type != ProjectType.baloot).toList();

    if (aRegular.isEmpty && bRegular.isEmpty) return null;
    if (aRegular.isEmpty) return 'B';
    if (bRegular.isEmpty) return 'A';

    // Compare highest project from each team
    aRegular.sort((a, b) {
      final cmp = b.priorityRank.compareTo(a.priorityRank);
      if (cmp != 0) return cmp;
      return b.highestCardStrength.compareTo(a.highestCardStrength);
    });
    bRegular.sort((a, b) {
      final cmp = b.priorityRank.compareTo(a.priorityRank);
      if (cmp != 0) return cmp;
      return b.highestCardStrength.compareTo(a.highestCardStrength);
    });

    final aBest = aRegular.first;
    final bBest = bRegular.first;

    if (aBest.priorityRank > bBest.priorityRank) return 'A';
    if (bBest.priorityRank > aBest.priorityRank) return 'B';

    // Same priority rank — compare highest card
    if (aBest.highestCardStrength > bBest.highestCardStrength) return 'A';
    if (bBest.highestCardStrength > aBest.highestCardStrength) return 'B';

    // Exact tie — first declared wins (Team A by convention)
    return 'A';
  }
}
