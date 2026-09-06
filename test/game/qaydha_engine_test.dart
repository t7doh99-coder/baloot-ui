import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/card_play_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/managers/turn_manager.dart';
import 'package:baloot_game/features/game/domain/models/qaydha_models.dart';
import 'package:baloot_game/features/game/domain/engines/qaydha_engine.dart';
import 'package:baloot_game/features/game/domain/engines/scoring_engine.dart';
import 'package:baloot_game/features/game/domain/managers/bidding_manager.dart';
import 'package:baloot_game/features/game/domain/baloot_game_controller.dart';

void main() {
  group('QaydhaEngine — Kammelna Rules Verification', () {
    // ══════════════════════════════════════════════════════════════════
    // 1. SCENARIO 1: قاطع (Failure to Follow Suit)
    // ══════════════════════════════════════════════════════════════════
    group('1. Qate (قاطع)', () {
      test('1.1 Player has lead suit but plays different suit → Violation (true)', () {
        final trick = TrickResult(
          winnerIndex: 0,
          abnat: 11,
          isLastTrick: false,
          lastTrickBonus: 0,
          cards: [
            const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.diamonds, rank: Rank.ace)),
            const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.hearts, rank: Rank.seven)), // Accused
          ],
          handsAtStartOfTrick: {
            1: [
              const CardModel(suit: Suit.diamonds, rank: Rank.seven), // Held a diamond!
              const CardModel(suit: Suit.hearts, rank: Rank.seven),
            ],
          },
        );

        final result = QaydhaEngine.evaluateChallenge(
          history: [trick],
          challengerIndex: 0,
          trickIndex: 0,
          accusedSeatIndex: 1,
          violationType: QaydhaViolationType.qate,
          gameMode: GameMode.sun,
          trumpSuit: null,
          doubleStatus: DoubleStatus.none,
        );

        expect(result.isCorrect, isTrue);
      });

      test('1.2 Player is void in lead suit and plays different suit → Legal (false)', () {
        final trick = TrickResult(
          winnerIndex: 0,
          abnat: 11,
          isLastTrick: false,
          lastTrickBonus: 0,
          cards: [
            const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.diamonds, rank: Rank.ace)),
            const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.hearts, rank: Rank.seven)),
          ],
          handsAtStartOfTrick: {
            1: [
              const CardModel(suit: Suit.clubs, rank: Rank.seven),
              const CardModel(suit: Suit.hearts, rank: Rank.seven), // No diamonds held!
            ],
          },
        );

        final result = QaydhaEngine.evaluateChallenge(
          history: [trick],
          challengerIndex: 0,
          trickIndex: 0,
          accusedSeatIndex: 1,
          violationType: QaydhaViolationType.qate,
          gameMode: GameMode.sun,
          trumpSuit: null,
          doubleStatus: DoubleStatus.none,
        );

        expect(result.isCorrect, isFalse);
      });
    });

    // ══════════════════════════════════════════════════════════════════
    // 2. SCENARIO 2: ما كبر بحكم (Failure to Over-Trump)
    // ══════════════════════════════════════════════════════════════════
    group('2. Ma Kabbar Bi Hakam (ما كبر بحكم)', () {
      test('2.1 Opponent (Seat 1) cuts with trump 10, Player (Seat 2) holds Jack but plays 8 → Violation (true)', () {
        // Seat 1 is Team B (Opponent of Seat 2). Seat 2 is Team A (Accused).
        // Mode: Hakam (Clubs). Trump strength: Jack(20) > 9(14) > Ace(11) > 10(10) > King(4) > Queen(3) > 8(0) > 7(0)
        final trick = TrickResult(
          winnerIndex: 1,
          abnat: 21,
          isLastTrick: false,
          lastTrickBonus: 0,
          cards: [
            const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.hearts, rank: Rank.ace)),
            const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.clubs, rank: Rank.ten)), // Opponent cut with 10
            const CardPlayModel(playerIndex: 2, card: CardModel(suit: Suit.clubs, rank: Rank.eight)), // Accused (Seat 2) played 8
          ],
          handsAtStartOfTrick: {
            2: [
              const CardModel(suit: Suit.clubs, rank: Rank.jack), // Held Jack (higher than 10)!
              const CardModel(suit: Suit.clubs, rank: Rank.eight),
            ],
          },
        );

        final result = QaydhaEngine.evaluateChallenge(
          history: [trick],
          challengerIndex: 1,
          trickIndex: 0,
          accusedSeatIndex: 2,
          violationType: QaydhaViolationType.maKabbarBiHakam,
          gameMode: GameMode.hakam,
          trumpSuit: Suit.clubs,
          doubleStatus: DoubleStatus.none,
        );

        expect(result.isCorrect, isTrue);
      });

      test('2.2 Partner (Seat 1) cuts with trump 10, Player (Seat 3) plays 8 while holding Jack → Legal / Partner Exemption (false)', () {
        // Seat 1 is partner of Seat 3 (both Team B). Seat 1 cut. Seat 3 is not forced to over-trump partner!
        final trick = TrickResult(
          winnerIndex: 1,
          abnat: 21,
          isLastTrick: false,
          lastTrickBonus: 0,
          cards: [
            const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.hearts, rank: Rank.ace)),
            const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.clubs, rank: Rank.ten)), // Partner of Seat 3!
            const CardPlayModel(playerIndex: 2, card: CardModel(suit: Suit.hearts, rank: Rank.seven)),
            const CardPlayModel(playerIndex: 3, card: CardModel(suit: Suit.clubs, rank: Rank.eight)), // Accused
          ],
          handsAtStartOfTrick: {
            3: [
              const CardModel(suit: Suit.clubs, rank: Rank.jack), // Held Jack
              const CardModel(suit: Suit.clubs, rank: Rank.eight),
            ],
          },
        );

        final result = QaydhaEngine.evaluateChallenge(
          history: [trick],
          challengerIndex: 0,
          trickIndex: 0,
          accusedSeatIndex: 3,
          violationType: QaydhaViolationType.maKabbarBiHakam,
          gameMode: GameMode.hakam,
          trumpSuit: Suit.clubs,
          doubleStatus: DoubleStatus.none,
        );

        expect(result.isCorrect, isFalse); // Partner exemption!
      });
    });

    // ══════════════════════════════════════════════════════════════════
    // 3. SCENARIO 3: ما دق بحكم (Failure to Cut with Trump)
    // ══════════════════════════════════════════════════════════════════
    group('3. Ma Daq Bi Hakam (ما دق بحكم)', () {
      test('3.1 Void in lead suit, no trump played, player discards off-suit while holding trump → Violation (true)', () {
        final trick = TrickResult(
          winnerIndex: 0,
          abnat: 11,
          isLastTrick: false,
          lastTrickBonus: 0,
          cards: [
            const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.hearts, rank: Rank.ace)),
            const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.spades, rank: Rank.seven)), // Accused discarded Spades
          ],
          handsAtStartOfTrick: {
            1: [
              const CardModel(suit: Suit.clubs, rank: Rank.seven), // Held Club (Trump)!
              const CardModel(suit: Suit.spades, rank: Rank.seven),
            ],
          },
        );

        final result = QaydhaEngine.evaluateChallenge(
          history: [trick],
          challengerIndex: 0,
          trickIndex: 0,
          accusedSeatIndex: 1,
          violationType: QaydhaViolationType.maDaqBiHakam,
          gameMode: GameMode.hakam,
          trumpSuit: Suit.clubs,
          doubleStatus: DoubleStatus.none,
        );

        expect(result.isCorrect, isTrue);
      });
    });

    // ══════════════════════════════════════════════════════════════════
    // 4. SCENARIO 4: ربع في الدبل (Trump Lead in Closed Double)
    // ══════════════════════════════════════════════════════════════════
    group('4. Rub Fi Al-Dubl (ربع في الدبل)', () {
      test('4.1 In Double, player leads trick with trump card → Violation (true)', () {
        final trick = TrickResult(
          winnerIndex: 1,
          abnat: 0,
          isLastTrick: false,
          lastTrickBonus: 0,
          cards: [
            const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.clubs, rank: Rank.seven)), // Led with Trump!
          ],
          handsAtStartOfTrick: {
            1: [const CardModel(suit: Suit.clubs, rank: Rank.seven)],
          },
        );

        final result = QaydhaEngine.evaluateChallenge(
          history: [trick],
          challengerIndex: 0,
          trickIndex: 0,
          accusedSeatIndex: 1,
          violationType: QaydhaViolationType.rubFiAlDubl,
          gameMode: GameMode.hakam,
          trumpSuit: Suit.clubs,
          doubleStatus: DoubleStatus.doubled,
        );

        expect(result.isCorrect, isTrue);
      });

      test('4.2 Normal mode (no double), player leads with trump → Legal (false)', () {
        final trick = TrickResult(
          winnerIndex: 1,
          abnat: 0,
          isLastTrick: false,
          lastTrickBonus: 0,
          cards: [
            const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.clubs, rank: Rank.seven)),
          ],
          handsAtStartOfTrick: {
            1: [const CardModel(suit: Suit.clubs, rank: Rank.seven)],
          },
        );

        final result = QaydhaEngine.evaluateChallenge(
          history: [trick],
          challengerIndex: 0,
          trickIndex: 0,
          accusedSeatIndex: 1,
          violationType: QaydhaViolationType.rubFiAlDubl,
          gameMode: GameMode.hakam,
          trumpSuit: Suit.clubs,
          doubleStatus: DoubleStatus.none,
        );

        expect(result.isCorrect, isFalse);
      });
    });

    // ══════════════════════════════════════════════════════════════════
    // 5. SCENARIO 5: إكة خاطئة (False Ekka)
    // ══════════════════════════════════════════════════════════════════
    group('5. False Ekka (إكة خاطئة)', () {
      test('5.1 Player leads King of Spades when Ace of Spades is unplayed → False Ekka / Violation (true)', () {
        final trick = TrickResult(
          winnerIndex: 1,
          abnat: 4,
          isLastTrick: false,
          lastTrickBonus: 0,
          cards: [
            const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.spades, rank: Rank.king)),
          ],
          handsAtStartOfTrick: {
            1: [const CardModel(suit: Suit.spades, rank: Rank.king)],
          },
        );

        final result = QaydhaEngine.evaluateChallenge(
          history: [trick],
          challengerIndex: 0,
          trickIndex: 0,
          accusedSeatIndex: 1,
          violationType: QaydhaViolationType.falseEkka,
          gameMode: GameMode.sun,
          trumpSuit: null,
          doubleStatus: DoubleStatus.none,
        );

        expect(result.isCorrect, isTrue); // Ace and 10 of Spades are still out there!
      });

      test('5.2 Ace & 10 of Spades were played in Trick 1, Player leads King in Trick 2 → Valid Ekka (false)', () {
        // In Sun mode: Ace > 10 > King. Both Ace and 10 must be gone for King to be master.
        final trick1 = TrickResult(
          winnerIndex: 0,
          abnat: 21,
          isLastTrick: false,
          lastTrickBonus: 0,
          cards: [
            const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.spades, rank: Rank.ace)),
            const CardPlayModel(playerIndex: 2, card: CardModel(suit: Suit.spades, rank: Rank.ten)),
          ],
          handsAtStartOfTrick: {},
        );

        final trick2 = TrickResult(
          winnerIndex: 1,
          abnat: 4,
          isLastTrick: false,
          lastTrickBonus: 0,
          cards: [
            const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.spades, rank: Rank.king)),
          ],
          handsAtStartOfTrick: {
            1: [const CardModel(suit: Suit.spades, rank: Rank.king)],
          },
        );

        final result = QaydhaEngine.evaluateChallenge(
          history: [trick1, trick2],
          challengerIndex: 0,
          trickIndex: 1,
          accusedSeatIndex: 1,
          violationType: QaydhaViolationType.falseEkka,
          gameMode: GameMode.sun,
          trumpSuit: null,
          doubleStatus: DoubleStatus.none,
        );

        expect(result.isCorrect, isFalse); // King is now the true master!
      });
    });

    group('6. Qaid Scoring & False Claim Penalty', () {
      test('6.1 Incorrect challenge / Timeout → Challenger team gets 0, Defending team gets full round points', () {
        final scoringEngine = ScoringEngine();
        final falseQaydha = QaydhaResult(
          challengerIndex: 0, // Team A challenged
          violationType: QaydhaViolationType.qate,
          isCorrect: false, // False claim or timeout!
          trickIndex: 0,
          accusedCard: const CardModel(suit: Suit.hearts, rank: Rank.seven),
        );

        final score = scoringEngine.calculateRoundScore(
          teamAAbnat: 0,
          teamBAbnat: 162,
          mode: GameMode.hakam,
          buyerTeam: 'A',
          teamATricksCount: 0,
          teamBTricksCount: 8,
          qaydhaResult: falseQaydha,
        );

        // Team B (Defenders) should win the full round points (16 in Hakam)
        expect(score.winningTeam, equals('B'));
        expect(score.teamAPoints, equals(0));
        expect(score.teamBPoints, equals(16));
      });

      test('6.2 Correct challenge → Challenger team gets full round points, Defending team gets 0', () {
        final scoringEngine = ScoringEngine();
        final correctQaydha = QaydhaResult(
          challengerIndex: 0, // Team A challenged
          violationType: QaydhaViolationType.qate,
          isCorrect: true, // Proven cheating!
          trickIndex: 0,
          accusedCard: const CardModel(suit: Suit.hearts, rank: Rank.seven),
        );

        final score = scoringEngine.calculateRoundScore(
          teamAAbnat: 162,
          teamBAbnat: 0,
          mode: GameMode.hakam,
          buyerTeam: 'B',
          teamATricksCount: 8,
          teamBTricksCount: 0,
          qaydhaResult: correctQaydha,
        );

        // Team A (Challengers) should win the full round points (16 in Hakam)
        expect(score.winningTeam, equals('A'));
        expect(score.teamAPoints, equals(16));
        expect(score.teamBPoints, equals(0));
      });
    });

    // ══════════════════════════════════════════════════════════════════
    // 7. Akka & Trick 1 Qaid Enabling
    // ══════════════════════════════════════════════════════════════════
    group('7. Akka & Trick 1 Qaid Enabling', () {
      test('7.1 canClaimQaid is enabled in controller once Trick 1 completes', () {
        final controller = BalootGameController();
        controller.startNewGame(['Player', 'Bot 1', 'Bot 2', 'Bot 3']);
        controller.startNewRound();
        
        // Before play starts (during bidding/setup), Qaid is false
        expect(controller.canClaimQaid(0), isFalse);

        // Pass Round 1 with Sun bid
        final firstBidder = controller.roundState.currentPlayerIndex;
        controller.placeBid(firstBidder, BidAction.sun);
        if (controller.gamePhase == GamePhase.doubleWindow) controller.skipDoubleWindow();

        // During Trick 1, before 4 cards are played: Qaid is false
        expect(controller.canClaimQaid(0), isFalse);

        // Play 4 cards to complete Trick 1
        for (int i = 0; i < 4; i++) {
          final curPlayer = controller.roundState.currentPlayerIndex;
          final hand = controller.getHand(curPlayer);
          final trick = controller.roundState.currentTrick;
          final leadSuit = trick.isEmpty ? null : trick.first.card.suit;
          final card = hand.firstWhere(
            (c) => leadSuit == null || c.suit == leadSuit,
            orElse: () => hand.first,
          );
          controller.playCard(curPlayer, card);
        }

        // Once Trick 1 has completed, Qaid is enabled!
        expect(controller.canClaimQaid(0), isTrue);
      });
    });
  });
}
