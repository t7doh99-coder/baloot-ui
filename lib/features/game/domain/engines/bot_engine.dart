import 'dart:math';
import '../../../../data/models/card_model.dart';
import '../../../../data/models/card_play_model.dart';
import '../../../../data/models/round_state_model.dart';
import '../../../../data/models/bot_difficulty.dart';
import '../managers/bidding_manager.dart';
import '../managers/turn_manager.dart';
import '../validators/play_validator.dart';

/// Rule-based bot AI for Baloot.
///
/// Pure Dart, no UI dependencies. Evaluates hand strength and game state
/// to make strategic decisions for bidding and card play.
class BotEngine {
  final BotDifficulty difficulty;
  final Random _random;

  BotEngine({
    this.difficulty = BotDifficulty.medium,
    Random? random,
  }) : _random = random ?? Random();

  static const PlayValidator _validator = PlayValidator();

  // ── Bidding Decision ──

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

    int threshold = 35; // Medium
    if (difficulty == BotDifficulty.easy) threshold = 28;
    if (difficulty == BotDifficulty.hard) threshold = 38;

    if (score >= threshold) {
      return const BotBidDecision(action: BidAction.hakam);
    }
    return const BotBidDecision(action: BidAction.pass);
  }

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
    
    int sunThreshold = 24; // Medium
    if (difficulty == BotDifficulty.easy) sunThreshold = 18;
    if (difficulty == BotDifficulty.hard) sunThreshold = 26;

    if (sunScore >= sunThreshold) {
      return const BotBidDecision(action: BidAction.sun);
    }
    return const BotBidDecision(action: BidAction.pass);
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
    if (round2PendingBid &&
        round2PendingBuyerSeat != null &&
        round2PendingMode != null) {
      if ((seatIndex % 2) == (round2PendingBuyerSeat % 2)) {
        return const BotBidDecision(action: BidAction.pass);
      }
      if (round2PendingMode == GameMode.sun) {
        return const BotBidDecision(action: BidAction.pass);
      }
      if (round2PendingMode == GameMode.hakam && round2PendingTrump != null) {
        return const BotBidDecision(action: BidAction.pass);
      }
    }

    if (round2PendingBid) {
      return const BotBidDecision(action: BidAction.pass);
    }

    final sunScore = _evaluateSunHand(hand);
    int sunThreshold = 18; // Medium
    if (difficulty == BotDifficulty.easy) sunThreshold = 14;
    if (difficulty == BotDifficulty.hard) sunThreshold = 22;

    if (sunScore >= sunThreshold) {
      return const BotBidDecision(action: BidAction.sun);
    }

    final bestSuit = _findStrongestTrumpSuit(hand, exclude: buyerCard.suit);
    if (bestSuit != null) {
      final hakamScore = _evaluateHakamHand(hand, bestSuit);
      int hakamThreshold = 30; // Medium
      if (difficulty == BotDifficulty.easy) hakamThreshold = 24;
      if (difficulty == BotDifficulty.hard) hakamThreshold = 34;

      if (hakamScore >= hakamThreshold) {
        return BotBidDecision(
          action: BidAction.secondHakam,
          secondHakamSuit: bestSuit,
        );
      }
    }

    final saneIndex = (dealerIndex + 3) % 4;
    if (seatIndex == dealerIndex || seatIndex == saneIndex) {
      int ashkalThreshold = 16; // Medium
      if (difficulty == BotDifficulty.easy) ashkalThreshold = 12;
      if (difficulty == BotDifficulty.hard) ashkalThreshold = 20;

      if (sunScore >= ashkalThreshold) {
        return const BotBidDecision(action: BidAction.ashkal);
      }
    }

    return const BotBidDecision(action: BidAction.pass);
  }

  // ── Card Play Decision ──

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
    List<TrickResult>? trickHistory,
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

    // Easy difficulty mistake (15% chance to just play a random valid card)
    if (difficulty == BotDifficulty.easy && _random.nextDouble() < 0.15) {
      return validCards[_random.nextInt(validCards.length)];
    }

    if (currentTrick.isEmpty) {
      return _decideLead(
        validCards: validCards,
        hand: hand,
        mode: mode,
        trumpSuit: trumpSuit,
        seatIndex: seatIndex,
        trickNumber: trickNumber,
        buyerIndex: buyerIndex,
        trickHistory: trickHistory,
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
      trickHistory: trickHistory,
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
    List<TrickResult>? trickHistory,
  }) {
    if (difficulty == BotDifficulty.easy) {
      // Novice: Leads the absolute highest card they have without thinking.
      return _highestStrengthCard(validCards, mode, trumpSuit);
    }

    if (mode == GameMode.hakam && trumpSuit != null) {
      final isBuyerTeam = (seatIndex % 2) == (buyerIndex % 2);
      final trumpCards = validCards.where((c) => c.suit == trumpSuit).toList();

      if (isBuyerTeam && trumpCards.isNotEmpty && trickNumber <= 3) {
        trumpCards.sort((a, b) =>
            b.getStrength(mode: mode, trumpSuit: trumpSuit)
                .compareTo(a.getStrength(mode: mode, trumpSuit: trumpSuit)));
        
        final topTrump = trumpCards.first;
        if (topTrump.rank == Rank.jack || topTrump.rank == Rank.nine) {
          return topTrump;
        }
      }

      // In Hakam, lead with a strong non-trump Ace
      final nonTrumpAces = validCards
          .where((c) => c.suit != trumpSuit && c.rank == Rank.ace)
          .toList();
      if (nonTrumpAces.isNotEmpty) return nonTrumpAces.first;

      // Hard Mode: Card counting. If Ace of a suit is gone, lead the 10 safely.
      if (difficulty == BotDifficulty.hard && trickHistory != null) {
        final tens = validCards.where((c) => c.suit != trumpSuit && c.rank == Rank.ten);
        for (final ten in tens) {
          if (_isCardPlayed(trickHistory, ten.suit, Rank.ace)) {
            return ten;
          }
        }
      }

      final tens = validCards.where((c) =>
          c.suit != trumpSuit &&
          c.rank == Rank.ten &&
          hand.any((h) => h.suit == c.suit && h.rank == Rank.ace));
      if (tens.isNotEmpty) return tens.first;

      if (trickNumber >= 5) {
        if (trumpCards.isNotEmpty) {
          trumpCards.sort((a, b) =>
              b.getStrength(mode: mode, trumpSuit: trumpSuit)
                  .compareTo(a.getStrength(mode: mode, trumpSuit: trumpSuit)));
          return trumpCards.first;
        }
      }

      final nonTrumps = validCards.where((c) => c.suit != trumpSuit).toList();
      if (nonTrumps.isNotEmpty) {
        return _lowestStrengthCard(nonTrumps, mode, trumpSuit);
      }
    }

    if (mode == GameMode.sun) {
      final aces = validCards.where((c) => c.rank == Rank.ace).toList();
      if (aces.isNotEmpty) return aces.first;

      // Hard Mode: Play 10 if Ace is already gone.
      if (difficulty == BotDifficulty.hard && trickHistory != null) {
        final tens = validCards.where((c) => c.rank == Rank.ten);
        for (final ten in tens) {
          if (_isCardPlayed(trickHistory, ten.suit, Rank.ace)) {
            return ten;
          }
        }
      }

      final suitGroups = <Suit, List<CardModel>>{};
      for (final c in validCards) {
        suitGroups.putIfAbsent(c.suit, () => []).add(c);
      }
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
    List<TrickResult>? trickHistory,
  }) {
    final leadSuit = currentTrick.first.card.suit;
    final partnerSeat = (seatIndex + 2) % 4;
    final isTeamA = seatIndex % 2 == 0;

    final currentWinner = _trickWinner(currentTrick, mode, trumpSuit);
    final winnerIsPartner = currentWinner?.playerIndex == partnerSeat;
    final winnerIsTeammate = currentWinner != null &&
        (currentWinner.playerIndex % 2 == 0) == isTeamA;

    if (difficulty == BotDifficulty.easy) {
      // Novice: Might cut teammate or just play whatever highest card they have.
      if (mode == GameMode.hakam && trumpSuit != null) {
        final trumps = validCards.where((c) => c.suit == trumpSuit).toList();
        if (trumps.isNotEmpty) return _highestStrengthCard(trumps, mode, trumpSuit);
      }
      return _highestStrengthCard(validCards, mode, trumpSuit);
    }

    final followCards = validCards.where((c) => c.suit == leadSuit).toList();
    final trumpCards = mode == GameMode.hakam && trumpSuit != null
        ? validCards.where((c) => c.suit == trumpSuit).toList()
        : <CardModel>[];
    final offCards = validCards
        .where((c) => c.suit != leadSuit && c.suit != trumpSuit)
        .toList();

    if (followCards.isNotEmpty) {
      if (winnerIsTeammate) {
        // Hard difficulty might dump high points if teammate is securely winning
        if (difficulty == BotDifficulty.hard && currentWinner != null) {
           final winnerStrength = currentWinner.card.getStrength(mode: mode, trumpSuit: trumpSuit);
           final isSecurelyWinning = (winnerStrength > 10); // arbitrary "strong" card logic
           if (isSecurelyWinning) {
              return _highestValueCard(followCards, mode, trumpSuit); // dump points
           }
        }
        return _lowestStrengthCard(followCards, mode, trumpSuit);
      }

      final winningCards = followCards.where((c) {
        if (currentWinner == null) return true;
        final trumpPlayed = currentTrick.any((p) =>
            p.card.suit == trumpSuit && p.card.suit != leadSuit);
        if (trumpPlayed && mode == GameMode.hakam) return false;
        return c.getStrength(mode: mode, trumpSuit: trumpSuit) >
            currentWinner.card.getStrength(mode: mode, trumpSuit: trumpSuit);
      }).toList();

      if (winningCards.isNotEmpty) {
        return _lowestStrengthCard(winningCards, mode, trumpSuit);
      }

      return _lowestValueCard(followCards, mode, trumpSuit);
    }

    if (mode == GameMode.hakam && trumpCards.isNotEmpty) {
      if (winnerIsTeammate) {
        if (offCards.isNotEmpty) {
          if (difficulty == BotDifficulty.hard) {
             return _highestValueCard(offCards, mode, trumpSuit); // Dump points to partner
          }
          return _lowestValueCard(offCards, mode, trumpSuit);
        }
        return _lowestStrengthCard(trumpCards, mode, trumpSuit);
      }

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
      return _lowestStrengthCard(trumpCards, mode, trumpSuit);
    }

    return _lowestValueCard(validCards, mode, trumpSuit);
  }

  // ── Double Decision ──

  DoubleStatus? decideDouble({
    required List<CardModel> hand,
    required GameMode mode,
    Suit? trumpSuit,
    required int ownScore,
    required int opponentScore,
    required DoubleStatus currentDoubleStatus,
    required bool isDefender,
  }) {
    if (mode == GameMode.sun || difficulty == BotDifficulty.easy) return null;

    final handScore = _evaluateHakamHand(hand, trumpSuit!);
    
    // Easy and Medium don't do complex escalation. They just double defensively if trailing heavily.
    if (difficulty != BotDifficulty.hard) {
      if (currentDoubleStatus == DoubleStatus.none && isDefender) {
        if (handScore >= 55 && ownScore < opponentScore) return DoubleStatus.doubled;
      }
      return null;
    }

    // Hard difficulty calculates its odds for all levels.
    if (isDefender) {
      if (currentDoubleStatus == DoubleStatus.none) {
        // First double
        if (handScore >= 50 && ownScore < opponentScore) return DoubleStatus.doubled;
      } else if (currentDoubleStatus == DoubleStatus.tripled) {
        // Counter triple with four
        if (handScore >= 62) return DoubleStatus.four;
      }
    } else {
      // Buyer Team
      if (currentDoubleStatus == DoubleStatus.doubled) {
        // Counter double with triple
        if (handScore >= 60) return DoubleStatus.tripled;
      } else if (currentDoubleStatus == DoubleStatus.four) {
        // Counter four with Gahwa (rare, needs perfect hand)
        if (handScore >= 70) return DoubleStatus.gahwa;
      }
    }

    return null;
  }

  // ── Memory / Card Tracking (Hard Mode) ──

  bool _isCardPlayed(List<TrickResult> trickHistory, Suit suit, Rank rank) {
    for (final trick in trickHistory) {
      for (final play in trick.cards) {
        if (play.card.suit == suit && play.card.rank == rank) {
          return true;
        }
      }
    }
    return false;
  }

  // ── Hand Evaluation Helpers ──

  int _evaluateHakamHand(List<CardModel> hand, Suit trumpSuit) {
    int score = 0;
    final trumpCards = hand.where((c) => c.suit == trumpSuit).toList();
    final nonTrumpCards = hand.where((c) => c.suit != trumpSuit).toList();

    score += trumpCards.length * 6;
    for (final c in trumpCards) {
      if (c.rank == Rank.jack) score += 15;
      if (c.rank == Rank.nine) score += 10;
      if (c.rank == Rank.ace) score += 6;
      if (c.rank == Rank.ten) score += 4;
    }
    for (final c in nonTrumpCards) {
      if (c.rank == Rank.ace) score += 5;
      if (c.rank == Rank.ten) score += 2;
    }
    return score;
  }

  int _evaluateSunHand(List<CardModel> hand) {
    int score = 0;
    for (final c in hand) {
      if (c.rank == Rank.ace) score += 8;
      if (c.rank == Rank.ten) score += 5;
      if (c.rank == Rank.king) score += 3;
    }
    final suitAces = hand.where((c) => c.rank == Rank.ace).map((c) => c.suit).toSet();
    if (suitAces.length >= 3) score += 10;
    if (suitAces.length == 4) score += 8;
    return score;
  }

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

  CardModel _lowestValueCard(List<CardModel> cards, GameMode mode, Suit? trumpSuit) {
    final sorted = List<CardModel>.from(cards)..sort((a, b) =>
        a.getPointValue(mode: mode, trumpSuit: trumpSuit)
            .compareTo(b.getPointValue(mode: mode, trumpSuit: trumpSuit)));
    return sorted.first;
  }

  CardModel _highestValueCard(List<CardModel> cards, GameMode mode, Suit? trumpSuit) {
    final sorted = List<CardModel>.from(cards)..sort((a, b) =>
        b.getPointValue(mode: mode, trumpSuit: trumpSuit)
            .compareTo(a.getPointValue(mode: mode, trumpSuit: trumpSuit)));
    return sorted.first;
  }

  CardModel _lowestStrengthCard(List<CardModel> cards, GameMode mode, Suit? trumpSuit) {
    final sorted = List<CardModel>.from(cards)..sort((a, b) =>
        a.getStrength(mode: mode, trumpSuit: trumpSuit)
            .compareTo(b.getStrength(mode: mode, trumpSuit: trumpSuit)));
    return sorted.first;
  }

  CardModel _highestStrengthCard(List<CardModel> cards, GameMode mode, Suit? trumpSuit) {
    final sorted = List<CardModel>.from(cards)..sort((a, b) =>
        b.getStrength(mode: mode, trumpSuit: trumpSuit)
            .compareTo(a.getStrength(mode: mode, trumpSuit: trumpSuit)));
    return sorted.first;
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

  CardPlayModel? _trickWinner(List<CardPlayModel> trick, GameMode mode, Suit? trumpSuit) {
    if (trick.isEmpty) return null;
    final leadSuit = trick.first.card.suit;
    CardPlayModel winner = trick.first;
    for (int i = 1; i < trick.length; i++) {
      final play = trick[i];
      final challengerIsTrump = mode == GameMode.hakam && play.card.suit == trumpSuit;
      final winnerIsTrump = mode == GameMode.hakam && winner.card.suit == trumpSuit;

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

class BotBidDecision {
  final BidAction action;
  final Suit? secondHakamSuit;
  const BotBidDecision({required this.action, this.secondHakamSuit});
}
