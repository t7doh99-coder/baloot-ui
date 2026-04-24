import 'card_model.dart';
import 'card_play_model.dart';

/// The phase of bidding within a round.
/// [hakamConfirmation] is the step where the Hakam bidder
/// (after all others passed in Round 1) may confirm Hakam or switch to Sun.
enum BiddingPhase { round1, round2, hakamConfirmation, completed, cancelled }

/// Double escalation levels (Hakam mode primarily).
enum DoubleStatus { none, doubled, tripled, four, gahwa }

/// The result of the bidding phase.
class BidResult {
  final GameMode mode;
  final int buyerIndex; // Seat 0-3
  final Suit? trumpSuit; // null for Sun
  final bool isAshkal;

  const BidResult({
    required this.mode,
    required this.buyerIndex,
    this.trumpSuit,
    this.isAshkal = false,
  });

  @override
  String toString() =>
      'BidResult(mode: $mode, buyer: $buyerIndex, trump: $trumpSuit, ashkal: $isAshkal)';
}

/// A declared project by a player.
class DeclaredProject {
  final ProjectType type;
  final int playerIndex;
  final List<CardModel> cards;

  const DeclaredProject({
    required this.type,
    required this.playerIndex,
    required this.cards,
  });

  /// Abnat value of this project (same in both modes per Jawaker/Kammelna).
  /// The Abnat→Scoreboard conversion formula (Sun: ×2/10, Hakam: /10)
  /// automatically produces the correct mode-specific scoreboard points.
  int getAbnat(GameMode mode) {
    switch (type) {
      case ProjectType.sera:
        return 20; // Both modes: 20 Abnat
      case ProjectType.fifty:
        return 50; // Both modes: 50 Abnat
      case ProjectType.hundred:
        return 100; // Both modes: 100 Abnat
      case ProjectType.fourHundred:
        return 200; // Sun only: 200 Abnat → round(200/10)*2 = 40 scoreboard pts
      case ProjectType.baloot:
        return 0; // Baloot is scoreboard pts, not Abnat
    }
  }

  /// Scoreboard points (used directly in doubled rounds, bypassing Abnat conversion).
  /// Per BALOOT_RULES.md & Jawaker/Kammelna:
  ///   Sera:  Sun=4, Hakam=2  |  Fifty: Sun=10, Hakam=5
  ///   100:   Sun=20, Hakam=10 |  400:   Sun=40 (Sun only)
  ///   Baloot: always 2 (immune to doubling)
  int getScoreboardPoints(GameMode mode) {
    switch (type) {
      case ProjectType.sera:
        return mode == GameMode.sun ? 4 : 2;
      case ProjectType.fifty:
        return mode == GameMode.sun ? 10 : 5;
      case ProjectType.hundred:
        return mode == GameMode.sun ? 20 : 10;
      case ProjectType.fourHundred:
        return 40; // Sun only
      case ProjectType.baloot:
        return 2; // Always 2, immune to doubling
    }
  }

  /// Priority rank for comparing projects (higher wins).
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
        return 0; // Baloot doesn't participate in priority comparison
    }
  }

  /// Highest card rank in the project (for tie-breaking).
  int get highestCardStrength {
    if (cards.isEmpty) return 0;
    return cards
        .map((c) => c.rank.index)
        .reduce((a, b) => a > b ? a : b);
  }
}

enum ProjectType { sera, fifty, hundred, fourHundred, baloot }

/// Complete state of a single round — everything needed for
/// state recovery / reconnection (BALOOT_RULES.md Section 11).
class RoundStateModel {
  final int dealerIndex;
  final int currentPlayerIndex;
  final BiddingPhase biddingPhase;
  final GameMode? activeMode;
  final Suit? trumpSuit;
  final int? buyerIndex;
  final CardModel? buyerCard;
  final bool isAshkal;
  final DoubleStatus doubleStatus;
  final bool isOpenPlay;
  final int trickNumber; // 1-8
  final List<CardPlayModel> currentTrick;
  final List<int> teamATricksWon; // trick indices won by team A
  final List<int> teamBTricksWon;
  final int teamAAbnat;
  final int teamBAbnat;
  final List<DeclaredProject> declaredProjects;
  final bool isDoubleWindowOpen;

  const RoundStateModel({
    required this.dealerIndex,
    required this.currentPlayerIndex,
    this.biddingPhase = BiddingPhase.round1,
    this.activeMode,
    this.trumpSuit,
    this.buyerIndex,
    this.buyerCard,
    this.isAshkal = false,
    this.doubleStatus = DoubleStatus.none,
    this.isOpenPlay = true,
    this.trickNumber = 1,
    this.currentTrick = const [],
    this.teamATricksWon = const [],
    this.teamBTricksWon = const [],
    this.teamAAbnat = 0,
    this.teamBAbnat = 0,
    this.declaredProjects = const [],
    this.isDoubleWindowOpen = false,
  });

  /// Team A = seats 0 & 2, Team B = seats 1 & 3.
  bool isTeamA(int seatIndex) => seatIndex % 2 == 0;

  /// The buyer's team.
  bool isBuyerTeamA() => buyerIndex != null && isTeamA(buyerIndex!);

  RoundStateModel copyWith({
    int? dealerIndex,
    int? currentPlayerIndex,
    BiddingPhase? biddingPhase,
    GameMode? activeMode,
    Suit? trumpSuit,
    int? buyerIndex,
    CardModel? buyerCard,
    bool? isAshkal,
    DoubleStatus? doubleStatus,
    bool? isOpenPlay,
    int? trickNumber,
    List<CardPlayModel>? currentTrick,
    List<int>? teamATricksWon,
    List<int>? teamBTricksWon,
    int? teamAAbnat,
    int? teamBAbnat,
    List<DeclaredProject>? declaredProjects,
    bool? isDoubleWindowOpen,
  }) {
    return RoundStateModel(
      dealerIndex: dealerIndex ?? this.dealerIndex,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      biddingPhase: biddingPhase ?? this.biddingPhase,
      activeMode: activeMode ?? this.activeMode,
      trumpSuit: trumpSuit ?? this.trumpSuit,
      buyerIndex: buyerIndex ?? this.buyerIndex,
      buyerCard: buyerCard ?? this.buyerCard,
      isAshkal: isAshkal ?? this.isAshkal,
      doubleStatus: doubleStatus ?? this.doubleStatus,
      isOpenPlay: isOpenPlay ?? this.isOpenPlay,
      trickNumber: trickNumber ?? this.trickNumber,
      currentTrick: currentTrick ?? this.currentTrick,
      teamATricksWon: teamATricksWon ?? this.teamATricksWon,
      teamBTricksWon: teamBTricksWon ?? this.teamBTricksWon,
      teamAAbnat: teamAAbnat ?? this.teamAAbnat,
      teamBAbnat: teamBAbnat ?? this.teamBAbnat,
      declaredProjects: declaredProjects ?? this.declaredProjects,
      isDoubleWindowOpen: isDoubleWindowOpen ?? this.isDoubleWindowOpen,
    );
  }

  /// Safe empty state used before a game starts (avoids late-init errors).
  factory RoundStateModel.empty() => const RoundStateModel(
        dealerIndex: 0,
        currentPlayerIndex: 0,
      );

  /// Serializable snapshot for reconnection.
  Map<String, dynamic> toSnapshot() {
    return {
      'dealerIndex': dealerIndex,
      'currentPlayerIndex': currentPlayerIndex,
      'biddingPhase': biddingPhase.name,
      'activeMode': activeMode?.name,
      'trumpSuit': trumpSuit?.name,
      'buyerIndex': buyerIndex,
      'isAshkal': isAshkal,
      'doubleStatus': doubleStatus.name,
      'isOpenPlay': isOpenPlay,
      'trickNumber': trickNumber,
      'currentTrickCount': currentTrick.length,
      'teamATricksWon': teamATricksWon,
      'teamBTricksWon': teamBTricksWon,
      'teamAAbnat': teamAAbnat,
      'teamBAbnat': teamBAbnat,
      'projectCount': declaredProjects.length,
    };
  }
}
