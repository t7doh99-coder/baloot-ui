import 'dart:math';
import '../../../../data/models/card_model.dart';
import '../../../../data/models/card_play_model.dart';
import '../../../../data/models/round_state_model.dart';
import '../../../../data/models/bot_difficulty.dart';
import '../../../../data/models/bot_personality.dart';
import '../managers/bidding_manager.dart';
import '../managers/turn_manager.dart';
import '../validators/play_validator.dart';
import 'bot_memory.dart';

// ══════════════════════════════════════════════════════════════════
//  BOT ENGINE — 3-Tier AI (Easy / Medium / Hard)
//
//  Per baloot_bot_spec.docx:
//    Easy   → 35% worst-card mistakes, no memory, no Sun/Ashkal/Double
//    Medium → 15% 2nd-best mistakes, 60% trump memory, partner-aware
//    Hard   → 5% "human moment" (once per game), 95% full memory,
//             personality-driven, trick-phase strategy
//
//  Legal rules are ALWAYS followed — mistakes only change WHICH
//  legal card is chosen, never play an illegal card.
// ══════════════════════════════════════════════════════════════════

class BotEngine {
  final BotDifficulty difficulty;
  final Random _random;

  /// Per-bot identities (seats 1, 2, 3). Assigned once per game session.
  final Map<int, BotIdentity> _identities = {};

  /// Per-bot memory systems.
  final Map<int, BotMemory> _memories = {};

  BotEngine({
    this.difficulty = BotDifficulty.medium,
    Random? random,
  }) : _random = random ?? Random();

  static const PlayValidator _validator = const PlayValidator();

  // ── Identity Management ──

  /// Assign random identities for a new game session.
  void assignIdentities() {
    for (final seat in [1, 2, 3]) {
      _identities[seat] = BotIdentity.random(difficulty, seat, _random);
      _memories[seat] = BotMemory(difficulty: difficulty, random: _random);
    }
  }

  /// Get identity for [seat]. Falls back to a default if not yet assigned.
  BotIdentity identityOf(int seat) =>
      _identities[seat] ?? BotIdentity.random(difficulty, seat, _random);

  /// Get memory for [seat].
  BotMemory memoryOf(int seat) =>
      _memories[seat] ?? BotMemory(difficulty: difficulty, random: _random);

  /// Reset all memories (call between rounds).
  void resetMemories() {
    for (final m in _memories.values) {
      m.reset();
    }
  }

  /// Feed a played card into all bot memories.
  void recordCardPlayed(CardModel card, int seatIndex, Suit? leadSuit) {
    for (final entry in _memories.entries) {
      entry.value.recordCardPlayed(card, seatIndex);
      // Detect void: if player didn't follow the lead suit
      if (leadSuit != null && card.suit != leadSuit && seatIndex != entry.key) {
        entry.value.recordVoidInSuit(seatIndex, leadSuit);
      }
    }
  }

  /// Feed a trick result into all bot memories.
  void recordTrickResult(int winningSeat) {
    for (final m in _memories.values) {
      m.recordTrickWinner(winningSeat);
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  BIDDING DECISION
  // ══════════════════════════════════════════════════════════════════

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
          hand, buyerCard, seatIndex, round1HakamBidderSeat,
        );
      }
      return _decideRound1(hand, buyerCard, seatIndex);
    }
    if (phase == BiddingPhase.hakamConfirmation) {
      return const BotBidDecision(action: BidAction.confirmHakam);
    }
    if (phase == BiddingPhase.qablakIntervention) {
      // Very basic Qablak bot logic: 30% chance to steal Sun if holding strong cards (Sun score >= 8).
      final sunScore = _evaluateSunStrength(hand);
      if (sunScore >= 8 && _random.nextDouble() < 0.3) {
        return const BotBidDecision(action: BidAction.sun); // Steal!
      }
      return const BotBidDecision(action: BidAction.pass);
    }
    return _decideRound2(
      hand, buyerCard, seatIndex, dealerIndex,
      round2PendingBid: round2PendingBid,
      round2PendingBuyerSeat: round2PendingBuyerSeat,
      round2PendingMode: round2PendingMode,
      round2PendingTrump: round2PendingTrump,
    );
  }

  // ── Round 1 Bidding ──

  BotBidDecision _decideRound1(List<CardModel> hand, CardModel buyerCard, int seatIndex) {
    final trumpSuit = buyerCard.suit;

    switch (difficulty) {
      case BotDifficulty.easy:
        // Spec §1.2: Only bid Hokum with 3+ cards of face-up suit.
        // 70% bid, 30% pass even then.
        final trumpCount = hand.where((c) => c.suit == trumpSuit).length;
        if (trumpCount >= 3 && _random.nextDouble() < 0.70) {
          return const BotBidDecision(action: BidAction.hakam);
        }
        return const BotBidDecision(action: BidAction.pass);

      case BotDifficulty.medium:
        // Spec §2.2: Count-based. Jack=4, 9=3, Ace(any)=2, 10(any)=1.
        // 4+ cards OR 3 incl Jack → always bid.
        // 2 strong (Jack+Ace or Jack+9) → 70% bid.
        // 2 weak → 20% bid. 0-1 → pass.
        final trumpCards = hand.where((c) => c.suit == trumpSuit).toList();
        final hasJack = trumpCards.any((c) => c.rank == Rank.jack);
        final hasNine = trumpCards.any((c) => c.rank == Rank.nine);
        final hasAce = trumpCards.any((c) => c.rank == Rank.ace);
        final count = trumpCards.length;

        if (count >= 4 || (count >= 3 && hasJack)) {
          return const BotBidDecision(action: BidAction.hakam);
        }
        if (count >= 2 && hasJack && (hasAce || hasNine)) {
          return _random.nextDouble() < 0.70
              ? const BotBidDecision(action: BidAction.hakam)
              : const BotBidDecision(action: BidAction.pass);
        }
        if (count >= 2) {
          return _random.nextDouble() < 0.20
              ? const BotBidDecision(action: BidAction.hakam)
              : const BotBidDecision(action: BidAction.pass);
        }
        return const BotBidDecision(action: BidAction.pass);

      case BotDifficulty.hard:
        // Spec §3.2: Full hand scoring.
        // Jack=4, 9=3, Ace(any)=2, 10(any)=1, extra trump beyond 1st=1.
        // Score 6+ → confident Hokum. 4-5 → 75%/25%. 3 → pass R1.
        final score = _evaluateHandSpec(hand, trumpSuit);
        final personality = identityOf(seatIndex).personality;

        // Personality modifiers
        int threshold = 6;
        if (personality.hard == HardPersonality.crusher) threshold = 4;
        if (personality.hard == HardPersonality.patient) threshold = 7;

        if (score >= threshold) {
          return const BotBidDecision(action: BidAction.hakam);
        }
        if (score >= 4) {
          final chance = personality.hard == HardPersonality.crusher ? 0.85 : 0.75;
          return _random.nextDouble() < chance
              ? const BotBidDecision(action: BidAction.hakam)
              : const BotBidDecision(action: BidAction.pass);
        }
        return const BotBidDecision(action: BidAction.pass);
    }
  }

  // ── Round 1 After Hakam (Sun counter-bid) ──

  BotBidDecision _decideRound1AfterHakam(
    List<CardModel> hand, CardModel buyerCard, int seatIndex, int hakamBidderSeat,
  ) {
    // Teammates don't counter their own partner
    if ((seatIndex % 2) == (hakamBidderSeat % 2)) {
      return const BotBidDecision(action: BidAction.pass);
    }

    switch (difficulty) {
      case BotDifficulty.easy:
        // Spec §1.2: NEVER bids Sun in round 1
        return const BotBidDecision(action: BidAction.pass);

      case BotDifficulty.medium:
        // Spec §2.2: Sun if 4+ Aces/Tens across all suits + no strong single suit
        final acesAndTens = hand.where((c) =>
            c.rank == Rank.ace || c.rank == Rank.ten).length;
        if (acesAndTens >= 4) {
          return const BotBidDecision(action: BidAction.sun);
        }
        return const BotBidDecision(action: BidAction.pass);

      case BotDifficulty.hard:
        // Spec §3.2: Aces + Tens ≥ 5 and no suit has Jack + 3 more cards
        final acesAndTens = hand.where((c) =>
            c.rank == Rank.ace || c.rank == Rank.ten).length;
        final hasDominantSuit = Suit.values.any((s) {
          final suitCards = hand.where((c) => c.suit == s).toList();
          return suitCards.length >= 4 && suitCards.any((c) => c.rank == Rank.jack);
        });
        if (acesAndTens >= 5 && !hasDominantSuit) {
          return const BotBidDecision(action: BidAction.sun);
        }
        return const BotBidDecision(action: BidAction.pass);
    }
  }

  /// Calculates a simple score for a potential Sun hand based on high cards.
  int _evaluateSunStrength(List<CardModel> hand) {
    int score = 0;
    for (final card in hand) {
      if (card.rank == Rank.ace) score += 3;
      else if (card.rank == Rank.ten) score += 2;
      else if (card.rank == Rank.king) score += 1;
    }
    return score;
  }

  // ── Round 2 Bidding ──

  BotBidDecision _decideRound2(
    List<CardModel> hand, CardModel buyerCard,
    int seatIndex, int dealerIndex, {
    required bool round2PendingBid,
    int? round2PendingBuyerSeat,
    GameMode? round2PendingMode,
    Suit? round2PendingTrump,
  }) {
    // If there's a pending counter-bid from opponent, let it pass
    if (round2PendingBid &&
        round2PendingBuyerSeat != null &&
        round2PendingMode != null) {
      if ((seatIndex % 2) == (round2PendingBuyerSeat % 2)) {
        return const BotBidDecision(action: BidAction.pass);
      }
      // Opponents already bid — don't counter for now
      return const BotBidDecision(action: BidAction.pass);
    }
    if (round2PendingBid) {
      return const BotBidDecision(action: BidAction.pass);
    }

    switch (difficulty) {
      case BotDifficulty.easy:
        // Spec §1.2: 50% Pass, 50% Hokum on any suit with 2+ cards
        if (_random.nextDouble() < 0.50) {
          return const BotBidDecision(action: BidAction.pass);
        }
        final bestSuit = _findBestSuitR2(hand, exclude: buyerCard.suit);
        if (bestSuit != null) {
          final count = hand.where((c) => c.suit == bestSuit).length;
          if (count >= 2) {
            return BotBidDecision(action: BidAction.secondHakam, secondHakamSuit: bestSuit);
          }
        }
        return const BotBidDecision(action: BidAction.pass);

      case BotDifficulty.medium:
        // Spec §2.2: Look for best suit (3+ cards) → Hokum Thani.
        // Sun Thani if no suit has 3+ but has multiple high cards.
        // Ashkal if in 3rd/4th position.
        final bestSuit = _findBestSuitR2(hand, exclude: buyerCard.suit);
        if (bestSuit != null) {
          final suitCards = hand.where((c) => c.suit == bestSuit).toList();
          if (suitCards.length >= 3) {
            return BotBidDecision(action: BidAction.secondHakam, secondHakamSuit: bestSuit);
          }
        }
        // Sun Thani check
        final acesAndTens = hand.where((c) =>
            c.rank == Rank.ace || c.rank == Rank.ten).length;
        if (acesAndTens >= 4) {
          return const BotBidDecision(action: BidAction.sun);
        }
        // Ashkal check (3rd/4th position = dealer or sane)
        final saneIndex = (dealerIndex + 3) % 4;
        if (seatIndex == dealerIndex || seatIndex == saneIndex) {
          if (acesAndTens >= 3) {
            return const BotBidDecision(action: BidAction.ashkal);
          }
        }
        return const BotBidDecision(action: BidAction.pass);

      case BotDifficulty.hard:
        // Full evaluation with personality modifiers
        final personality = identityOf(seatIndex).personality;

        // Sun evaluation first
        final acesAndTens = hand.where((c) =>
            c.rank == Rank.ace || c.rank == Rank.ten).length;
        final hasDominantSuit = Suit.values.any((s) {
          if (s == buyerCard.suit) return false;
          final suitCards = hand.where((c) => c.suit == s).toList();
          return suitCards.length >= 4 && suitCards.any((c) => c.rank == Rank.jack);
        });
        if (acesAndTens >= 5 && !hasDominantSuit) {
          return const BotBidDecision(action: BidAction.sun);
        }

        // Hakam Thani on strongest non-buyer suit
        final bestSuit = _findBestSuitR2(hand, exclude: buyerCard.suit);
        if (bestSuit != null) {
          final score = _evaluateHandSpec(hand, bestSuit);
          int threshold = 4;
          if (personality.hard == HardPersonality.crusher) threshold = 3;
          if (personality.hard == HardPersonality.patient) threshold = 5;

          if (score >= threshold) {
            return BotBidDecision(action: BidAction.secondHakam, secondHakamSuit: bestSuit);
          }
        }

        // Ashkal check
        final saneIndex = (dealerIndex + 3) % 4;
        if (seatIndex == dealerIndex || seatIndex == saneIndex) {
          if (acesAndTens >= 3) {
            return const BotBidDecision(action: BidAction.ashkal);
          }
        }
        return const BotBidDecision(action: BidAction.pass);
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  CARD PLAY DECISION
  // ══════════════════════════════════════════════════════════════════

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

    // Get optimal card first
    final optimalCard = _getOptimalCard(
      validCards: validCards,
      hand: hand,
      currentTrick: currentTrick,
      mode: mode,
      trumpSuit: trumpSuit,
      seatIndex: seatIndex,
      trickNumber: trickNumber,
      buyerIndex: buyerIndex,
      trickHistory: trickHistory,
    );

    // Apply mistake system per spec
    return _applyMistakeSystem(optimalCard, validCards, seatIndex);
  }

  // ── Mistake System (spec §1.3, §2.3, §3.3) ──

  CardModel _applyMistakeSystem(
    CardModel optimal, List<CardModel> validCards, int seatIndex,
  ) {
    if (validCards.length <= 1) return optimal;

    final roll = _random.nextInt(100);
    switch (difficulty) {
      case BotDifficulty.easy:
        // 35% chance: play the WORST legal card
        if (roll < 35) {
          return _worstCard(validCards);
        }
        return optimal;

      case BotDifficulty.medium:
        // 15% chance: play the SECOND-best legal card
        if (roll < 15) {
          return _secondBestCard(optimal, validCards);
        }
        return optimal;

      case BotDifficulty.hard:
        // 5% chance: one "human moment" per game session
        final identity = identityOf(seatIndex);
        if (roll < 5 && !identity.humanMomentUsed) {
          identity.humanMomentUsed = true;
          return _secondBestCard(optimal, validCards);
        }
        return optimal;
    }
  }

  /// Return the worst (lowest strategic value) legal card.
  CardModel _worstCard(List<CardModel> cards) {
    final sorted = List<CardModel>.from(cards)..sort((a, b) =>
        a.getStrength(mode: GameMode.hakam).compareTo(
            b.getStrength(mode: GameMode.hakam)));
    return sorted.first; // weakest card
  }

  /// Return the second-best card (skip the optimal, pick next best).
  CardModel _secondBestCard(CardModel optimal, List<CardModel> cards) {
    final sorted = List<CardModel>.from(cards)..sort((a, b) =>
        b.getStrength(mode: GameMode.hakam).compareTo(
            a.getStrength(mode: GameMode.hakam)));
    // Return first card that isn't the optimal
    for (final c in sorted) {
      if (c != optimal) return c;
    }
    return optimal; // fallback
  }

  // ── Optimal Card Selection ──

  CardModel _getOptimalCard({
    required List<CardModel> validCards,
    required List<CardModel> hand,
    required List<CardPlayModel> currentTrick,
    required GameMode mode,
    Suit? trumpSuit,
    required int seatIndex,
    required int trickNumber,
    required int buyerIndex,
    List<TrickResult>? trickHistory,
  }) {
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
      trickNumber: trickNumber,
    );
  }

  // ── Leading a Trick ──

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
    final memory = memoryOf(seatIndex);

    switch (difficulty) {
      case BotDifficulty.easy:
        // Spec §1.3: leads a random card — no strategy
        return validCards[_random.nextInt(validCards.length)];

      case BotDifficulty.medium:
        // Spec §2.3: structured lead strategy
        if (mode == GameMode.hakam && trumpSuit != null) {
          // First 3 tricks: lead with Ace if available
          if (trickNumber <= 3) {
            final aces = validCards.where((c) => c.suit != trumpSuit && c.rank == Rank.ace).toList();
            if (aces.isNotEmpty) return aces.first;
          }
          // Mid-game: lead non-trump high cards
          final nonTrumpHigh = validCards
              .where((c) => c.suit != trumpSuit && (c.rank == Rank.ace || c.rank == Rank.ten))
              .toList();
          if (nonTrumpHigh.isNotEmpty) return nonTrumpHigh.first;
          // Late game: lead trump if winning
          if (trickNumber >= 5) {
            final trumpCards = validCards.where((c) => c.suit == trumpSuit).toList();
            if (trumpCards.isNotEmpty) {
              return _highestStrengthCard(trumpCards, mode, trumpSuit);
            }
          }
          return _lowestValueCard(validCards, mode, trumpSuit);
        }
        // Sun mode
        final aces = validCards.where((c) => c.rank == Rank.ace).toList();
        if (aces.isNotEmpty) return aces.first;
        return _lowestValueCard(validCards, mode, trumpSuit);

      case BotDifficulty.hard:
        // Spec §3.3: trick-phase strategy with memory
        final personality = identityOf(seatIndex).personality;
        final isBuyerTeam = (seatIndex % 2) == (buyerIndex % 2);

        if (mode == GameMode.hakam && trumpSuit != null) {
          final trumpCards = validCards.where((c) => c.suit == trumpSuit).toList();
          final nonTrumpCards = validCards.where((c) => c.suit != trumpSuit).toList();

          // Patient personality: dump low cards for 5 tricks then unleash
          if (personality.hard == HardPersonality.patient && trickNumber <= 5) {
            if (nonTrumpCards.isNotEmpty) {
              return _lowestValueCard(nonTrumpCards, mode, trumpSuit);
            }
          }

          // Crusher personality: lead trump early to drain opponents
          if (personality.hard == HardPersonality.crusher &&
              isBuyerTeam && trumpCards.isNotEmpty && trickNumber <= 3) {
            trumpCards.sort((a, b) =>
                b.getStrength(mode: mode, trumpSuit: trumpSuit)
                    .compareTo(a.getStrength(mode: mode, trumpSuit: trumpSuit)));
            return trumpCards.first;
          }

          // Deceiver: lead with weak cards to fake voidness
          if (personality.hard == HardPersonality.deceiver && trickNumber <= 4) {
            if (nonTrumpCards.isNotEmpty) {
              return _lowestStrengthCard(nonTrumpCards, mode, trumpSuit);
            }
          }

          // Standard Hard strategy by trick phase
          if (trickNumber <= 2) {
            // Tricks 1-2: clear Aces from non-trump suits
            final nonTrumpAces = nonTrumpCards.where((c) => c.rank == Rank.ace).toList();
            if (nonTrumpAces.isNotEmpty) return nonTrumpAces.first;
          } else if (trickNumber <= 4) {
            // Tricks 3-4: lead with partner's strong suit (inferred from bids)
            // Memory: lead safe 10s if Ace already played
            for (final c in nonTrumpCards) {
              if (c.rank == Rank.ten && memory.isCardPlayed(c.suit, Rank.ace)) {
                return c;
              }
            }
            final nonTrumpAces = nonTrumpCards.where((c) => c.rank == Rank.ace).toList();
            if (nonTrumpAces.isNotEmpty) return nonTrumpAces.first;
          } else if (trickNumber <= 6) {
            // Tricks 5-6: pressure — lead suits opponents are void in
            for (final seat in [(seatIndex + 1) % 4, (seatIndex + 3) % 4]) {
              for (final c in nonTrumpCards) {
                if (!memory.isSeatVoidIn(seat, c.suit) && c.rank == Rank.ace) {
                  return c;
                }
              }
            }
          }
          // Tricks 7-8 or fallback: use trump strategically
          if (trickNumber >= 7 && trumpCards.isNotEmpty && isBuyerTeam) {
            return _highestStrengthCard(trumpCards, mode, trumpSuit);
          }

          if (nonTrumpCards.isNotEmpty) {
            return _lowestValueCard(nonTrumpCards, mode, trumpSuit);
          }
          return _lowestStrengthCard(validCards, mode, trumpSuit);
        }

        // Sun mode (Hard)
        final aces = validCards.where((c) => c.rank == Rank.ace).toList();
        if (aces.isNotEmpty) return aces.first;
        // Memory: safe 10 if Ace gone
        for (final c in validCards) {
          if (c.rank == Rank.ten && memory.isCardPlayed(c.suit, Rank.ace)) {
            return c;
          }
        }
        return _lowestValueCard(validCards, mode, trumpSuit);
    }
  }

  // ── Following a Trick ──

  CardModel _decideFollow({
    required List<CardModel> validCards,
    required List<CardModel> hand,
    required List<CardPlayModel> currentTrick,
    required GameMode mode,
    Suit? trumpSuit,
    required int seatIndex,
    required int buyerIndex,
    List<TrickResult>? trickHistory,
    required int trickNumber,
  }) {
    final leadSuit = currentTrick.first.card.suit;
    final partnerSeat = (seatIndex + 2) % 4;
    final isTeamA = seatIndex % 2 == 0;

    final currentWinner = _trickWinner(currentTrick, mode, trumpSuit);
    final winnerIsTeammate = currentWinner != null &&
        (currentWinner.playerIndex % 2 == 0) == isTeamA;

    final followCards = validCards.where((c) => c.suit == leadSuit).toList();
    final trumpCards = mode == GameMode.hakam && trumpSuit != null
        ? validCards.where((c) => c.suit == trumpSuit).toList()
        : <CardModel>[];
    final offCards = validCards
        .where((c) => c.suit != leadSuit && c.suit != trumpSuit)
        .toList();

    switch (difficulty) {
      case BotDifficulty.easy:
        // Spec §1.3: plays highest card available, throws trump even when partner wins
        if (mode == GameMode.hakam && trumpSuit != null && trumpCards.isNotEmpty) {
          return _highestStrengthCard(trumpCards, mode, trumpSuit);
        }
        return _highestStrengthCard(validCards, mode, trumpSuit);

      case BotDifficulty.medium:
        // Spec §2.3 + §2.5: Partner coordination — never overtrump partner
        if (followCards.isNotEmpty) {
          if (winnerIsTeammate) {
            // Dump high points to partner (spec §2.5)
            if (trickNumber >= 7) {
              return _highestValueCard(followCards, mode, trumpSuit);
            }
            return _lowestStrengthCard(followCards, mode, trumpSuit);
          }
          // Try to beat current winner
          final winningCards = _getWinningCards(followCards, currentTrick, currentWinner, mode, trumpSuit);
          if (winningCards.isNotEmpty) {
            return _lowestStrengthCard(winningCards, mode, trumpSuit);
          }
          return _lowestValueCard(followCards, mode, trumpSuit);
        }
        // Can't follow suit
        if (mode == GameMode.hakam && trumpCards.isNotEmpty) {
          if (winnerIsTeammate) {
            // NEVER overtrump partner (spec §2.5)
            if (offCards.isNotEmpty) return _lowestValueCard(offCards, mode, trumpSuit);
            return _lowestStrengthCard(trumpCards, mode, trumpSuit);
          }
          return _lowestStrengthCard(trumpCards, mode, trumpSuit);
        }
        return _lowestValueCard(validCards, mode, trumpSuit);

      case BotDifficulty.hard:
        // Spec §3.3 + §3.5: Advanced partner coordination + memory
        final memory = memoryOf(seatIndex);

        if (followCards.isNotEmpty) {
          if (winnerIsTeammate) {
            // Hard: dump high-value cards if partner winning securely (spec §3.5)
            if (currentWinner != null) {
              final winnerStrength = currentWinner.card.getStrength(
                  mode: mode, trumpSuit: trumpSuit);
              if (winnerStrength > 10) {
                return _highestValueCard(followCards, mode, trumpSuit);
              }
            }
            return _lowestStrengthCard(followCards, mode, trumpSuit);
          }
          // Try to beat with minimum winning card
          final winningCards = _getWinningCards(followCards, currentTrick, currentWinner, mode, trumpSuit);
          if (winningCards.isNotEmpty) {
            return _lowestStrengthCard(winningCards, mode, trumpSuit);
          }
          // Spec §3.3: NEVER plays Ace/Ten into a trick the team will lose
          final safeCards = followCards.where((c) =>
              c.rank != Rank.ace && c.rank != Rank.ten).toList();
          if (safeCards.isNotEmpty) return _lowestValueCard(safeCards, mode, trumpSuit);
          return _lowestValueCard(followCards, mode, trumpSuit);
        }

        // Can't follow suit
        if (mode == GameMode.hakam && trumpCards.isNotEmpty) {
          if (winnerIsTeammate) {
            // NEVER trump when partner is winning (spec §3.3)
            if (offCards.isNotEmpty) {
              // Hard: dump high points to partner (spec §3.5)
              return _highestValueCard(offCards, mode, trumpSuit);
            }
            return _lowestStrengthCard(trumpCards, mode, trumpSuit);
          }
          // Trump to win — use minimum trump that beats existing trumps
          final existingTrumpStrength = _highestTrumpInTrick(currentTrick, trumpSuit);
          if (existingTrumpStrength >= 0) {
            final beatingTrumps = trumpCards.where((c) =>
                c.getStrength(mode: mode, trumpSuit: trumpSuit) > existingTrumpStrength)
                .toList();
            if (beatingTrumps.isNotEmpty) {
              return _lowestStrengthCard(beatingTrumps, mode, trumpSuit);
            }
          }
          // Spec §3.3: Save Jack of trump until opponents played 2+ other trumps
          final playedTrumpCount = memory.countPlayedTrumps(trumpSuit!);
          final jackOfTrump = trumpCards.where((c) => c.rank == Rank.jack).toList();
          if (jackOfTrump.isNotEmpty && playedTrumpCount < 2 && trumpCards.length > 1) {
            // Save Jack — play a lesser trump
            final nonJackTrumps = trumpCards.where((c) => c.rank != Rank.jack).toList();
            if (nonJackTrumps.isNotEmpty) {
              return _lowestStrengthCard(nonJackTrumps, mode, trumpSuit);
            }
          }
          return _lowestStrengthCard(trumpCards, mode, trumpSuit);
        }

        // Kaboot prevention: if opponents at 7 tricks, sacrifice to win one
        if (memory.tricksWonByOpponentTeam(seatIndex) >= 7 && trumpCards.isNotEmpty) {
          return _highestStrengthCard(trumpCards, mode, trumpSuit);
        }

        return _lowestValueCard(validCards, mode, trumpSuit);
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  DOUBLE DECISION
  // ══════════════════════════════════════════════════════════════════

  DoubleStatus? decideDouble({
    required List<CardModel> hand,
    required GameMode mode,
    Suit? trumpSuit,
    required int ownScore,
    required int opponentScore,
    required DoubleStatus currentDoubleStatus,
    required bool isDefender,
  }) {
    switch (difficulty) {
      case BotDifficulty.easy:
        // Spec §1.2: NEVER doubles, triples, or fours
        return null;

      case BotDifficulty.medium:
        // Spec §2.2: doubles if own team won last 2 rounds AND strong cards (40%)
        if (mode == GameMode.sun) return null;
        if (currentDoubleStatus == DoubleStatus.none && isDefender) {
          final score = _evaluateHandSpec(hand, trumpSuit!);
          if (score >= 5 && ownScore < opponentScore && _random.nextDouble() < 0.40) {
            return DoubleStatus.doubled;
          }
        }
        // Gahwa: 50% if doubled and confident
        if (currentDoubleStatus == DoubleStatus.doubled && !isDefender) {
          final score = _evaluateHandSpec(hand, trumpSuit!);
          if (score >= 6 && _random.nextDouble() < 0.50) {
            return DoubleStatus.tripled;
          }
        }
        return null;

      case BotDifficulty.hard:
        if (mode == GameMode.sun) return null;
        final score = _evaluateHandSpec(hand, trumpSuit!);

        if (isDefender) {
          if (currentDoubleStatus == DoubleStatus.none) {
            // Spec §3.2: doubles if team won 3+ of last 4 tricks
            if (score >= 5 && ownScore < opponentScore) return DoubleStatus.doubled;
          } else if (currentDoubleStatus == DoubleStatus.tripled) {
            // Counter triple with four
            if (score >= 7) return DoubleStatus.four;
          }
        } else {
          // Buyer team
          if (currentDoubleStatus == DoubleStatus.doubled) {
            // Spec §3.2: triples if 4-of-4
            if (score >= 6) return DoubleStatus.tripled;
          } else if (currentDoubleStatus == DoubleStatus.four) {
            // Gahwa: bot fires if hand score was 6+ (spec §3.2)
            if (score >= 6) return DoubleStatus.gahwa;
          }
        }
        return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  HAND EVALUATION (Spec scale: Jack=4, 9=3, Ace=2, 10=1, extra trump=1)
  // ══════════════════════════════════════════════════════════════════

  int _evaluateHandSpec(List<CardModel> hand, Suit trumpSuit) {
    int score = 0;
    int trumpCount = 0;
    for (final c in hand) {
      if (c.suit == trumpSuit) {
        trumpCount++;
        if (c.rank == Rank.jack) {
          score += 4;
        } else if (c.rank == Rank.nine) {
          score += 3;
        } else {
          score += 1; // every trump card = 1
        }
      } else {
        if (c.rank == Rank.ace) score += 2;
        if (c.rank == Rank.ten) score += 1;
      }
    }
    // Extra trump beyond first = additional +1 each (already counted above as base 1)
    return score;
  }

  // ══════════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════════

  Suit? _findBestSuitR2(List<CardModel> hand, {required Suit exclude}) {
    Suit? bestSuit;
    int bestCount = 0;
    int bestScore = 0;
    for (final suit in Suit.values) {
      if (suit == exclude) continue;
      final suitCards = hand.where((c) => c.suit == suit).toList();
      final score = _evaluateHandSpec(hand, suit);
      if (suitCards.length > bestCount ||
          (suitCards.length == bestCount && score > bestScore)) {
        bestCount = suitCards.length;
        bestScore = score;
        bestSuit = suit;
      }
    }
    return bestSuit;
  }

  /// Get cards from [candidates] that beat the current trick winner.
  List<CardModel> _getWinningCards(
    List<CardModel> candidates,
    List<CardPlayModel> currentTrick,
    CardPlayModel? currentWinner,
    GameMode mode,
    Suit? trumpSuit,
  ) {
    if (currentWinner == null) return candidates;
    final leadSuit = currentTrick.first.card.suit;
    return candidates.where((c) {
      final trumpPlayed = currentTrick.any((p) =>
          p.card.suit == trumpSuit && p.card.suit != leadSuit);
      if (trumpPlayed && mode == GameMode.hakam && c.suit != trumpSuit) return false;
      return c.getStrength(mode: mode, trumpSuit: trumpSuit) >
          currentWinner.card.getStrength(mode: mode, trumpSuit: trumpSuit);
    }).toList();
  }

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
