import '../../../../data/models/card_model.dart';
import '../../../../data/models/card_play_model.dart';
import '../../../../data/models/round_state_model.dart';
import '../managers/bidding_manager.dart';
import '../validators/play_validator.dart';

/// Rule-based bot AI for Baloot.
///
/// Pure Dart, no UI dependencies. Evaluates hand strength and game state
/// to make strategic decisions for bidding and card play.
class BotEngine {
  const BotEngine();

  static const PlayValidator _validator = PlayValidator();

  // ── Bidding Decision ──

  /// Decide what bid to place given the bot's hand and the buyer card.
  ///
  /// Returns a [BotBidDecision] with the chosen action and optional suit.
  BotBidDecision decideBid({
    required List<CardModel> hand,
    required CardModel buyerCard,
    required BiddingPhase phase,
    required int seatIndex,
    required int dealerIndex,
    bool round2PendingBid = false,
    int? round1HakamBidderSeat,
    int? round2PendingBuyerSeat,
    GameMode? round2PendingMode,
    Suit? round2PendingTrump,
  }) {
    if (phase == BiddingPhase.round1) {
      if (round1HakamBidderSeat != null) {
        return _decideRound1AfterHakam(
          hand,
          buyerCard,
          seatIndex,
          round1HakamBidderSeat,
        );
      }
      return _decideRound1(hand, buyerCard);
    }
    if (phase == BiddingPhase.hakamConfirmation) {
      // Bot already bid Hakam — confirm it (could add Sun-switch logic later)
      return const BotBidDecision(action: BidAction.confirmHakam);
    }
    return _decideRound2(
      hand,
      buyerCard,
      seatIndex,
      dealerIndex,
      round2PendingBid: round2PendingBid,
      round2PendingBuyerSeat: round2PendingBuyerSeat,
      round2PendingMode: round2PendingMode,
      round2PendingTrump: round2PendingTrump,
    );
  }

  BotBidDecision _decideRound1(List<CardModel> hand, CardModel buyerCard) {
    final trumpSuit = buyerCard.suit;
    final score = _evaluateHakamHand(hand, trumpSuit);

    // Bid Hakam if hand is strong in the buyer card's suit
    if (score >= 35) {
      return const BotBidDecision(action: BidAction.hakam);
    }
    return const BotBidDecision(action: BidAction.pass);
  }

  /// After an opponent bid Hakam: Pass, Sawa (accept), or Sun (override) — Jawaker/Kammelna.
  BotBidDecision _decideRound1AfterHakam(
    List<CardModel> hand,
    CardModel buyerCard,
    int seatIndex,
    int hakamBidderSeat,
  ) {
    if ((seatIndex % 2) == (hakamBidderSeat % 2)) {
      return const BotBidDecision(action: BidAction.pass);
    }
    final sunScore = _evaluateSunHand(hand);
    if (sunScore >= 48) {
      return const BotBidDecision(action: BidAction.sun);
    }
    final vsTheirTrump = _evaluateHakamHand(hand, buyerCard.suit);
    if (vsTheirTrump < 26) {
      return const BotBidDecision(action: BidAction.pass);
    }
    return const BotBidDecision(action: BidAction.sawa);
  }

  BotBidDecision _decideRound2(
    List<CardModel> hand,
    CardModel buyerCard,
    int seatIndex,
    int dealerIndex, {
    required bool round2PendingBid,
    int? round2PendingBuyerSeat,
    GameMode? round2PendingMode,
    Suit? round2PendingTrump,
  }) {
    // Others must react with Pass or Sawa (no new Sun/Hakam).
    if (round2PendingBid &&
        round2PendingBuyerSeat != null &&
        round2PendingMode != null) {
      if ((seatIndex % 2) == (round2PendingBuyerSeat % 2)) {
        return const BotBidDecision(action: BidAction.pass);
      }
      if (round2PendingMode == GameMode.sun) {
        final s = _evaluateSunHand(hand);
        return s >= 38
            ? const BotBidDecision(action: BidAction.pass)
            : const BotBidDecision(action: BidAction.sawa);
      }
      if (round2PendingMode == GameMode.hakam && round2PendingTrump != null) {
        final h = _evaluateHakamHand(hand, round2PendingTrump);
        return h >= 36
            ? const BotBidDecision(action: BidAction.pass)
            : const BotBidDecision(action: BidAction.sawa);
      }
    }

    if (round2PendingBid) {
      return const BotBidDecision(action: BidAction.pass);
    }

    // Evaluate Sun strength
    final sunScore = _evaluateSunHand(hand);
    if (sunScore >= 40) {
      return const BotBidDecision(action: BidAction.sun);
    }

    // Evaluate Second Hakam — find strongest off-suit
    final bestSuit = _findStrongestTrumpSuit(hand, exclude: buyerCard.suit);
    if (bestSuit != null) {
      final hakamScore = _evaluateHakamHand(hand, bestSuit);
      if (hakamScore >= 35) {
        return BotBidDecision(
          action: BidAction.secondHakam,
          secondHakamSuit: bestSuit,
        );
      }
    }

    // Ashkal is Round 1 only (BALOOT_RULES.md §4.6) — never in Round 2.

    return const BotBidDecision(action: BidAction.pass);
  }

  // ── Card Play Decision ──

  /// Pick the best card to play from the bot's hand.
  ///
  /// Strategy varies by position in the trick (leading vs following),
  /// game mode, and teammate/opponent analysis.
  CardModel decidePlay({
    required List<CardModel> hand,
    required List<CardPlayModel> currentTrick,
    required GameMode mode,
    Suit? trumpSuit,
    required DoubleStatus doubleStatus,
    required bool isOpenPlay,
    required int trickNumber,
    required int teamAAbnat,
    required int teamBAbnat,
    required int buyerIndex,
    required int seatIndex,
  }) {
    final validCards = _validator.getValidCards(
      hand: hand,
      currentTrick: currentTrick,
      mode: mode,
      trumpSuit: trumpSuit,
      doubleStatus: doubleStatus,
      isOpenPlay: isOpenPlay,
      playerSeat: seatIndex,
    );

    if (validCards.isEmpty) return hand.first;
    if (validCards.length == 1) return validCards.first;

    if (currentTrick.isEmpty) {
      return _decideLead(
        validCards: validCards,
        hand: hand,
        mode: mode,
        trumpSuit: trumpSuit,
        seatIndex: seatIndex,
        trickNumber: trickNumber,
        buyerIndex: buyerIndex,
      );
    }

    return _decideFollow(
      validCards: validCards,
      hand: hand,
      currentTrick: currentTrick,
      mode: mode,
      trumpSuit: trumpSuit,
      seatIndex: seatIndex,
      buyerIndex: buyerIndex,
    );
  }

  CardModel _decideLead({
    required List<CardModel> validCards,
    required List<CardModel> hand,
    required GameMode mode,
    Suit? trumpSuit,
    required int seatIndex,
    required int trickNumber,
    required int buyerIndex,
  }) {
    if (mode == GameMode.hakam && trumpSuit != null) {
      final isBuyerTeam = (seatIndex % 2) == (buyerIndex % 2);
      final trumpCards = validCards.where((c) => c.suit == trumpSuit).toList();

      // NEW STRATEGY (Visca ME): If we bought, lead high trumps early to draw them out.
      if (isBuyerTeam && trumpCards.isNotEmpty && trickNumber <= 3) {
        // Sort by strength descending (Jack, 9, Ace, ...)
        trumpCards.sort((a, b) =>
            b.getStrength(mode: mode, trumpSuit: trumpSuit)
                .compareTo(a.getStrength(mode: mode, trumpSuit: trumpSuit)));
        
        final topTrump = trumpCards.first;
        // If we have Jack or 9, lead it.
        if (topTrump.rank == Rank.jack || topTrump.rank == Rank.nine) {
          return topTrump;
        }
      }

      // In Hakam, lead with a strong non-trump Ace to collect points
      final nonTrumpAces = validCards
          .where((c) => c.suit != trumpSuit && c.rank == Rank.ace)
          .toList();
      if (nonTrumpAces.isNotEmpty) return nonTrumpAces.first;

      // Lead with a strong non-trump 10 if we also hold the Ace of that suit
      final tens = validCards.where((c) =>
          c.suit != trumpSuit &&
          c.rank == Rank.ten &&
          hand.any((h) => h.suit == c.suit && h.rank == Rank.ace));
      if (tens.isNotEmpty) return tens.first;

      // Late game: lead trump to draw out remaining trumps
      if (trickNumber >= 5) {
        if (trumpCards.isNotEmpty) {
          trumpCards.sort((a, b) =>
              b.getStrength(mode: mode, trumpSuit: trumpSuit)
                  .compareTo(a.getStrength(mode: mode, trumpSuit: trumpSuit)));
          return trumpCards.first;
        }
      }

      // Lead lowest non-trump card to feel out opponents
      final nonTrumps =
          validCards.where((c) => c.suit != trumpSuit).toList();
      if (nonTrumps.isNotEmpty) {
        return _lowestStrengthCard(nonTrumps, mode, trumpSuit);
      }
    }

    if (mode == GameMode.sun) {
      // Sun: lead with Aces to grab points
      final aces = validCards.where((c) => c.rank == Rank.ace).toList();
      if (aces.isNotEmpty) return aces.first;

      // Lead a suit where we're strong (have multiple high cards)
      final suitGroups = <Suit, List<CardModel>>{};
      for (final c in validCards) {
        suitGroups.putIfAbsent(c.suit, () => []).add(c);
      }
      // Find a suit with 2+ cards where we have the highest card
      for (final entry in suitGroups.entries) {
        if (entry.value.length >= 2) {
          entry.value.sort((a, b) =>
              b.getStrength(mode: mode).compareTo(a.getStrength(mode: mode)));
          if (entry.value.first.rank == Rank.ace ||
              entry.value.first.rank == Rank.ten) {
            return entry.value.first;
          }
        }
      }
    }

    // Default: lead lowest value card
    return _lowestValueCard(validCards, mode, trumpSuit);
  }

  CardModel _decideFollow({
    required List<CardModel> validCards,
    required List<CardModel> hand,
    required List<CardPlayModel> currentTrick,
    required GameMode mode,
    Suit? trumpSuit,
    required int seatIndex,
    required int buyerIndex,
  }) {
    final leadSuit = currentTrick.first.card.suit;
    final partnerSeat = (seatIndex + 2) % 4;
    final isTeamA = seatIndex % 2 == 0;

    // Determine who is currently winning the trick
    final currentWinner = _trickWinner(currentTrick, mode, trumpSuit);
    final winnerIsPartner = currentWinner?.playerIndex == partnerSeat;
    final winnerIsTeammate = currentWinner != null &&
        (currentWinner.playerIndex % 2 == 0) == isTeamA;

    // Can we follow suit?
    final followCards = validCards.where((c) => c.suit == leadSuit).toList();
    final trumpCards = mode == GameMode.hakam && trumpSuit != null
        ? validCards.where((c) => c.suit == trumpSuit).toList()
        : <CardModel>[];
    final offCards = validCards
        .where((c) => c.suit != leadSuit && c.suit != trumpSuit)
        .toList();

    if (followCards.isNotEmpty) {
      // We can follow suit
      if (winnerIsTeammate) {
        // Partner is winning — play lowest to save high cards
        return _lowestStrengthCard(followCards, mode, trumpSuit);
      }

      // Try to win the trick with the cheapest winning card
      final winningCards = followCards.where((c) {
        if (currentWinner == null) return true;
        // Can only win with same suit if no trump has been played
        final trumpPlayed = currentTrick.any((p) =>
            p.card.suit == trumpSuit && p.card.suit != leadSuit);
        if (trumpPlayed && mode == GameMode.hakam) return false;
        return c.getStrength(mode: mode, trumpSuit: trumpSuit) >
            currentWinner.card.getStrength(mode: mode, trumpSuit: trumpSuit);
      }).toList();

      if (winningCards.isNotEmpty) {
        // Play the cheapest card that still wins
        return _lowestStrengthCard(winningCards, mode, trumpSuit);
      }

      // Can't win — dump lowest value card
      return _lowestValueCard(followCards, mode, trumpSuit);
    }

    // We're void in the lead suit
    if (mode == GameMode.hakam && trumpCards.isNotEmpty) {
      if (winnerIsTeammate) {
        // Partner is winning — dump lowest non-trump instead
        if (offCards.isNotEmpty) {
          return _lowestValueCard(offCards, mode, trumpSuit);
        }
        // Only have trump — play lowest
        return _lowestStrengthCard(trumpCards, mode, trumpSuit);
      }

      // Cut with the cheapest trump that beats any existing trump
      final existingTrumpStrength = _highestTrumpInTrick(currentTrick, trumpSuit);
      if (existingTrumpStrength >= 0) {
        final beatingTrumps = trumpCards
            .where((c) =>
                c.getStrength(mode: mode, trumpSuit: trumpSuit) >
                existingTrumpStrength)
            .toList();
        if (beatingTrumps.isNotEmpty) {
          return _lowestStrengthCard(beatingTrumps, mode, trumpSuit);
        }
      }
      // No higher trump needed / just cut with lowest trump
      return _lowestStrengthCard(trumpCards, mode, trumpSuit);
    }

    // Sun mode void, or Hakam void in both lead + trump — dump lowest value
    return _lowestValueCard(validCards, mode, trumpSuit);
  }

  // ── Double Decision ──

  /// Decide whether to call Double (defending team only).
  ///
  /// Returns null if the bot should skip, otherwise the level.
  DoubleStatus? decideDouble({
    required List<CardModel> hand,
    required GameMode mode,
    Suit? trumpSuit,
    required int ownScore,
    required int opponentScore,
  }) {
    if (mode == GameMode.sun) return null;

    final handScore = _evaluateHakamHand(hand, trumpSuit!);

    // Very strong hand — consider doubling
    if (handScore >= 55 && ownScore < opponentScore) {
      return DoubleStatus.doubled;
    }

    return null;
  }

  // ── Hand Evaluation Helpers ──

  /// Score a hand for Hakam strength with the given trump suit.
  /// Higher = stronger. Range roughly 0-80.
  int _evaluateHakamHand(List<CardModel> hand, Suit trumpSuit) {
    int score = 0;

    final trumpCards = hand.where((c) => c.suit == trumpSuit).toList();
    final nonTrumpCards = hand.where((c) => c.suit != trumpSuit).toList();

    // Trump count is critical
    score += trumpCards.length * 6;

    // High trumps are very valuable
    for (final c in trumpCards) {
      if (c.rank == Rank.jack) score += 15;
      if (c.rank == Rank.nine) score += 10;
      if (c.rank == Rank.ace) score += 6;
      if (c.rank == Rank.ten) score += 4;
    }

    // Non-trump Aces are side winners
    for (final c in nonTrumpCards) {
      if (c.rank == Rank.ace) score += 5;
      if (c.rank == Rank.ten) score += 2;
    }

    return score;
  }

  /// Score a hand for Sun strength (all suits equal).
  /// Higher = stronger. Range roughly 0-70.
  int _evaluateSunHand(List<CardModel> hand) {
    int score = 0;

    for (final c in hand) {
      if (c.rank == Rank.ace) score += 8;
      if (c.rank == Rank.ten) score += 5;
      if (c.rank == Rank.king) score += 3;
    }

    // Suit diversity bonus — having aces in multiple suits is very strong
    final suitAces = hand.where((c) => c.rank == Rank.ace).map((c) => c.suit).toSet();
    if (suitAces.length >= 3) score += 10;
    if (suitAces.length == 4) score += 8;

    return score;
  }

  /// Find the best suit for Second Hakam (excluding the buyer card suit).
  Suit? _findStrongestTrumpSuit(List<CardModel> hand, {required Suit exclude}) {
    Suit? bestSuit;
    int bestScore = 0;

    for (final suit in Suit.values) {
      if (suit == exclude) continue;
      final score = _evaluateHakamHand(hand, suit);
      if (score > bestScore) {
        bestScore = score;
        bestSuit = suit;
      }
    }

    return bestSuit;
  }

  // ── Card Comparison Helpers ──

  CardModel _lowestValueCard(
      List<CardModel> cards, GameMode mode, Suit? trumpSuit) {
    cards.sort((a, b) =>
        a.getPointValue(mode: mode, trumpSuit: trumpSuit)
            .compareTo(b.getPointValue(mode: mode, trumpSuit: trumpSuit)));
    return cards.first;
  }

  CardModel _lowestStrengthCard(
      List<CardModel> cards, GameMode mode, Suit? trumpSuit) {
    cards.sort((a, b) =>
        a.getStrength(mode: mode, trumpSuit: trumpSuit)
            .compareTo(b.getStrength(mode: mode, trumpSuit: trumpSuit)));
    return cards.first;
  }

  int _highestTrumpInTrick(List<CardPlayModel> trick, Suit? trumpSuit) {
    if (trumpSuit == null) return -1;
    int highest = -1;
    for (final p in trick) {
      if (p.card.suit == trumpSuit) {
        final s = p.card.getStrength(mode: GameMode.hakam, trumpSuit: trumpSuit);
        if (s > highest) highest = s;
      }
    }
    return highest;
  }

  /// Determine who is currently winning the trick.
  CardPlayModel? _trickWinner(
      List<CardPlayModel> trick, GameMode mode, Suit? trumpSuit) {
    if (trick.isEmpty) return null;

    final leadSuit = trick.first.card.suit;
    CardPlayModel winner = trick.first;

    for (int i = 1; i < trick.length; i++) {
      final play = trick[i];
      final challengerIsTrump =
          mode == GameMode.hakam && play.card.suit == trumpSuit;
      final winnerIsTrump =
          mode == GameMode.hakam && winner.card.suit == trumpSuit;

      if (challengerIsTrump && !winnerIsTrump) {
        winner = play;
      } else if (challengerIsTrump && winnerIsTrump) {
        if (play.card.getStrength(mode: mode, trumpSuit: trumpSuit) >
            winner.card.getStrength(mode: mode, trumpSuit: trumpSuit)) {
          winner = play;
        }
      } else if (play.card.suit == leadSuit && winner.card.suit == leadSuit) {
        if (play.card.getStrength(mode: mode, trumpSuit: trumpSuit) >
            winner.card.getStrength(mode: mode, trumpSuit: trumpSuit)) {
          winner = play;
        }
      }
    }

    return winner;
  }
}

/// Result of a bot bidding decision.
class BotBidDecision {
  final BidAction action;
  final Suit? secondHakamSuit;

  const BotBidDecision({required this.action, this.secondHakamSuit});
}
