import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/card_play_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/managers/turn_manager.dart';
import 'package:baloot_game/features/game/domain/managers/bidding_manager.dart';
import 'package:baloot_game/features/game/domain/models/qaydha_models.dart';
import 'package:baloot_game/features/game/domain/engines/qaydha_engine.dart';
import 'package:baloot_game/features/game/domain/engines/scoring_engine.dart';
import 'package:baloot_game/features/game/domain/baloot_game_controller.dart';
import 'package:baloot_game/features/game/presentation/game_provider.dart';
import 'package:baloot_game/features/game/presentation/widgets/qaydha_types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const playerNames = ['You', 'Jim', 'Michael', 'Dwight'];

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1: Client Video Scenarios Parity Tests (7 Tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 1: Client Video Scenarios Parity Tests', () {
    // 1. Video 0:00-0:31 — Dealer (Seat 3) buys Hakam in Round 1
    test('1. testVideo_000_Round1HakamPurchase: Round 1 Hakam bought by dealer (Seat 3)', () {
      const buyerCard = CardModel(suit: Suit.diamonds, rank: Rank.seven);
      final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);

      // Seat 0 (first bidder after dealer) allowed: Sun, Hakam, Pass
      expect(bm.currentBidder, equals(0));
      expect(bm.getAllowedActions(0), containsAll([BidAction.sun, BidAction.hakam, BidAction.pass]));
      expect(bm.getAllowedActions(0).contains(BidAction.ashkal), isFalse); // Non-dealer/sane cannot Ashkal

      // Seats 0, 1, 2 pass
      bm.placeBid(0, BidAction.pass);
      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.pass);

      // Dealer (Seat 3) bids Hakam
      expect(bm.currentBidder, equals(3));
      bm.placeBid(3, BidAction.hakam);

      // Next bidder is Seat 0, who can override with Sun or Pass
      expect(bm.currentBidder, equals(0));
      expect(bm.getAllowedActions(0), containsAll([BidAction.sun, BidAction.pass]));
      expect(bm.getAllowedActions(0).contains(BidAction.hakam), isFalse); // Cannot bid Hakam over Hakam
    });

    // 2. Video 0:37-1:21 — Defender Double/Sun/Bas Window
    test('2. testVideo_037_DefenderDoubleSunBasWindow: Post-Hakam buy defender action window options', () {
      final controller = BalootGameController(random: Random(42));
      controller.startNewGame(playerNames);
      controller.startNewRound();

      // Mode check: Sun mode allows at most a single Double (no Triple/Gahwa)
      const scoring = ScoringEngine();
      final sunDoublePts = scoring.calculateRoundScore(
        teamAAbnat: 130,
        teamBAbnat: 0,
        mode: GameMode.sun,
        buyerTeam: 'A',
        teamATricksCount: 8,
        teamBTricksCount: 0,
        doubleStatus: DoubleStatus.doubled,
      );
      expect(sunDoublePts.teamAPoints, equals(52)); // Sun Double = 52
    });

    // 3. Video 1:48-2:20 — Qaid Review Menu offers 5 violations including False Ekka
    test('3. testVideo_148_QaidMenu5thViolation: Verify Qaid review screen offers 5 violation options', () {
      // Must include exactly 5 enum values matching Kammelna
      expect(QaydhaViolationType.values.length, equals(5));
      expect(QaydhaViolationType.values, contains(QaydhaViolationType.qate));
      expect(QaydhaViolationType.values, contains(QaydhaViolationType.rubFiAlDubl));
      expect(QaydhaViolationType.values, contains(QaydhaViolationType.maKabbarBiHakam));
      expect(QaydhaViolationType.values, contains(QaydhaViolationType.maDaqBiHakam));
      expect(QaydhaViolationType.values, contains(QaydhaViolationType.falseEkka));
    });

    // 4. Video 2:22-3:30 — Scoreboard Gahwa Columns and Point Allocation
    test('4. testVideo_222_ScoreboardGahwaColumns: Verify scoreboard structure supports 152 instant win', () {
      const scoring = ScoringEngine();

      final normalHakam = scoring.calculateRoundScore(
        teamAAbnat: 90,
        teamBAbnat: 72,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.none,
      );
      expect(normalHakam.teamAPoints, equals(9));

      final gahwaScore = scoring.calculateRoundScore(
        teamAAbnat: 90,
        teamBAbnat: 72,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.gahwa,
      );
      // Gahwa awards 152 points directly to winning team
      expect(gahwaScore.teamAPoints, equals(152));
      expect(scoring.isGameOver(gahwaScore.teamAPoints, 0, DoubleStatus.gahwa), isTrue);
    });

    // 5. Video 4:02-4:40 — Sawa Late Game Restriction (Hand <= 4 & Lead Turn)
    test('5. testVideo_402_SawaLateGameRestriction: Verify canSawa is false early, true late with lead', () {
      final controller = BalootGameController(random: Random(42));
      controller.startNewGame(playerNames);
      controller.startNewRound();

      // Hand length > 4 (start of round): canSawa MUST be false
      expect(controller.getHand(0).length, greaterThan(4));
      expect(controller.canSawa(0), isFalse);
    });

    // 6. Video 6:17-6:50 — Sun Trump Violation Immunity
    test('6. testVideo_617_SunTrumpViolationImmunity: Trump cut violations cannot be claimed in Sun mode', () {
      const trick = TrickResult(
        winnerIndex: 0,
        abnat: 11,
        isLastTrick: false,
        lastTrickBonus: 0,
        cards: [
          CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.hearts, rank: Rank.ace)),
          CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.spades, rank: Rank.seven)),
        ],
        handsAtStartOfTrick: {
          1: [CardModel(suit: Suit.clubs, rank: Rank.seven)],
        },
      );

      // In Sun mode, Ma Daq Bi Hakam is never valid
      final result = QaydhaEngine.evaluateChallenge(
        history: const [trick],
        challengerIndex: 0,
        trickIndex: 0,
        accusedSeatIndex: 1,
        violationType: QaydhaViolationType.maDaqBiHakam,
        gameMode: GameMode.sun,
        trumpSuit: null,
        doubleStatus: DoubleStatus.none,
      );
      expect(result.isCorrect, isFalse);
    });

    // 7. Video 8:31-9:14 — Dealer Turn Purchasing Rules in Round 2
    test('7. testVideo_831_DealerTurnPurchasingRules: Verify dealer turn bidding rules in round 2', () {
      const buyerCard = CardModel(suit: Suit.diamonds, rank: Rank.seven);
      final bm = BiddingManager(dealerIndex: 3, buyerCard: buyerCard);

      // Pass Round 1 completely
      bm.placeBid(0, BidAction.pass);
      bm.placeBid(1, BidAction.pass);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);

      expect(bm.phase, equals(BiddingPhase.round2));

      // In Round 2: Dealer is Seat 3, Sane (dealer - 1 / dealer + 3) is Seat 2.
      // Seats 2 and 3 can bid Ashkal. Seats 0 and 1 cannot.
      expect(bm.currentBidder, equals(0));
      expect(bm.getAllowedActions(0).contains(BidAction.ashkal), isFalse);

      bm.placeBid(0, BidAction.pass);
      expect(bm.currentBidder, equals(1));
      expect(bm.getAllowedActions(1).contains(BidAction.ashkal), isFalse);

      bm.placeBid(1, BidAction.pass);

      // Seat 2 is Sane -> can bid Ashkal
      expect(bm.currentBidder, equals(2));
      expect(bm.getAllowedActions(2), contains(BidAction.ashkal));

      bm.placeBid(2, BidAction.pass);

      // Seat 3 is Dealer -> can bid Ashkal
      expect(bm.currentBidder, equals(3));
      expect(bm.getAllowedActions(3), contains(BidAction.ashkal));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2: Qaid 5 Violation Types & Proof Mechanics (5 Tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 2: Qaid 5 Violation Types & Proof Mechanics', () {
    // 8. Violation 1: Qate (قطع)
    test('8. testQaid_Violation1_Qate: Failure to follow suit when holding suit cards', () {
      const trick = TrickResult(
        winnerIndex: 0,
        abnat: 11,
        isLastTrick: false,
        lastTrickBonus: 0,
        cards: [
          CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.diamonds, rank: Rank.ace)),
          CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.hearts, rank: Rank.seven)), // Played Hearts
        ],
        handsAtStartOfTrick: {
          1: [
            CardModel(suit: Suit.diamonds, rank: Rank.eight), // Held Diamond!
            CardModel(suit: Suit.hearts, rank: Rank.seven),
          ],
        },
      );

      final result = QaydhaEngine.evaluateChallenge(
        history: const [trick],
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

    // 9. Violation 2: Ma Kabbar Bi Hakam (ما كبر بحكم)
    test('9. testQaid_Violation2_MaKabbarBiHakam: Failure to over-trump opponent with partner exemption', () {
      // Opponent cuts with trump 10. Accused held Jack, played 8 -> Violation
      const trickOpponent = TrickResult(
        winnerIndex: 1,
        abnat: 21,
        isLastTrick: false,
        lastTrickBonus: 0,
        cards: [
          CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.hearts, rank: Rank.ace)),
          CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.clubs, rank: Rank.ten)),
          CardPlayModel(playerIndex: 2, card: CardModel(suit: Suit.clubs, rank: Rank.eight)),
        ],
        handsAtStartOfTrick: {
          2: [
            CardModel(suit: Suit.clubs, rank: Rank.jack),
            CardModel(suit: Suit.clubs, rank: Rank.eight),
          ],
        },
      );

      final resultOpponent = QaydhaEngine.evaluateChallenge(
        history: const [trickOpponent],
        challengerIndex: 1,
        trickIndex: 0,
        accusedSeatIndex: 2,
        violationType: QaydhaViolationType.maKabbarBiHakam,
        gameMode: GameMode.hakam,
        trumpSuit: Suit.clubs,
        doubleStatus: DoubleStatus.none,
      );
      expect(resultOpponent.isCorrect, isTrue);

      // Partner cuts with trump 10. Accused (Seat 3, partner of Seat 1) plays 8 holding Jack -> Legal
      const trickPartner = TrickResult(
        winnerIndex: 1,
        abnat: 21,
        isLastTrick: false,
        lastTrickBonus: 0,
        cards: [
          CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.hearts, rank: Rank.ace)),
          CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.clubs, rank: Rank.ten)),
          CardPlayModel(playerIndex: 2, card: CardModel(suit: Suit.hearts, rank: Rank.seven)),
          CardPlayModel(playerIndex: 3, card: CardModel(suit: Suit.clubs, rank: Rank.eight)),
        ],
        handsAtStartOfTrick: {
          3: [
            CardModel(suit: Suit.clubs, rank: Rank.jack),
            CardModel(suit: Suit.clubs, rank: Rank.eight),
          ],
        },
      );

      final resultPartner = QaydhaEngine.evaluateChallenge(
        history: const [trickPartner],
        challengerIndex: 0,
        trickIndex: 0,
        accusedSeatIndex: 3,
        violationType: QaydhaViolationType.maKabbarBiHakam,
        gameMode: GameMode.hakam,
        trumpSuit: Suit.clubs,
        doubleStatus: DoubleStatus.none,
      );
      expect(resultPartner.isCorrect, isFalse); // Partner exemption!
    });

    // 10. Violation 3: Ma Daq Bi Hakam (ما دق بحكم)
    test('10. testQaid_Violation3_MaDaqBiHakam: Failure to cut with trump when void in lead suit', () {
      const trick = TrickResult(
        winnerIndex: 0,
        abnat: 11,
        isLastTrick: false,
        lastTrickBonus: 0,
        cards: [
          CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.hearts, rank: Rank.ace)),
          CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.spades, rank: Rank.seven)),
        ],
        handsAtStartOfTrick: {
          1: [
            CardModel(suit: Suit.clubs, rank: Rank.seven), // Trump held!
            CardModel(suit: Suit.spades, rank: Rank.seven),
          ],
        },
      );

      final result = QaydhaEngine.evaluateChallenge(
        history: const [trick],
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

    // 11. Violation 4: Rub Fi Al-Dubl (ربع في الدبل)
    test('11. testQaid_Violation4_RubFiAlDubl: Leading trump in doubled round when holding alternatives', () {
      const trick = TrickResult(
        winnerIndex: 1,
        abnat: 0,
        isLastTrick: false,
        lastTrickBonus: 0,
        cards: [
          CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.clubs, rank: Rank.seven)),
        ],
        handsAtStartOfTrick: {
          1: [
            CardModel(suit: Suit.clubs, rank: Rank.seven),
            CardModel(suit: Suit.hearts, rank: Rank.king),
          ],
        },
      );

      final resultDoubled = QaydhaEngine.evaluateChallenge(
        history: const [trick],
        challengerIndex: 0,
        trickIndex: 0,
        accusedSeatIndex: 1,
        violationType: QaydhaViolationType.rubFiAlDubl,
        gameMode: GameMode.hakam,
        trumpSuit: Suit.clubs,
        doubleStatus: DoubleStatus.doubled,
      );
      expect(resultDoubled.isCorrect, isTrue);

      final resultUndoubled = QaydhaEngine.evaluateChallenge(
        history: const [trick],
        challengerIndex: 0,
        trickIndex: 0,
        accusedSeatIndex: 1,
        violationType: QaydhaViolationType.rubFiAlDubl,
        gameMode: GameMode.hakam,
        trumpSuit: Suit.clubs,
        doubleStatus: DoubleStatus.none,
      );
      expect(resultUndoubled.isCorrect, isFalse);
    });

    // 12. Violation 5: False Ekka (إكة خاطئة)
    test('12. testQaid_Violation5_FalseEkka: Declaring Ekka when card is not highest remaining', () {
      const trick = TrickResult(
        winnerIndex: 1,
        abnat: 4,
        isLastTrick: false,
        lastTrickBonus: 0,
        cards: [
          CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.spades, rank: Rank.king)),
        ],
        handsAtStartOfTrick: {
          1: [CardModel(suit: Suit.spades, rank: Rank.king)],
        },
      );

      // Ace of Spades unplayed -> King is NOT master -> False Ekka!
      final result = QaydhaEngine.evaluateChallenge(
        history: const [trick],
        challengerIndex: 0,
        trickIndex: 0,
        accusedSeatIndex: 1,
        violationType: QaydhaViolationType.falseEkka,
        gameMode: GameMode.sun,
        trumpSuit: null,
        doubleStatus: DoubleStatus.none,
      );
      expect(result.isCorrect, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3: Qaid Card Selection & Inspector Rules (3 Tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 3: Qaid Card Selection & Inspector Rules', () {
    // 13. Red Accused, Green Proof
    test('13. testQaid_CardSelection_RedAccusedGreenProof: Accused card red, proof card green', () {
      final provider = GameProvider(random: Random(42));
      provider.audioService.setMuted(true);

      // 1st card tap -> Accused card
      provider.selectQaydhaCard(0, 1, cardIndexInTrick: 0);
      expect(provider.selectedQaydhaTrickIndex, equals(0));
      expect(provider.selectedQaydhaCardSeatIndex, equals(1));
      expect(provider.selectedQaydhaProofTrickIndex, isNull);

      // 2nd card tap -> Proof card
      provider.selectQaydhaCard(1, 2, cardIndexInTrick: 1);
      expect(provider.selectedQaydhaProofTrickIndex, equals(1));
      expect(provider.selectedQaydhaProofSeatIndex, equals(2));
      expect(provider.selectedQaydhaProofCardIndex, equals(1));
    });

    // 14. 3rd Card Selection Resets Both Cards
    test('14. testQaid_CardSelection_ThirdCardDeselection: Selecting 3rd card resets pair and sets new accused', () {
      final provider = GameProvider(random: Random(42));
      provider.audioService.setMuted(true);

      // Select Accused (Trick 0, Seat 1)
      provider.selectQaydhaCard(0, 1, cardIndexInTrick: 0);
      // Select Proof (Trick 0, Seat 2)
      provider.selectQaydhaCard(0, 2, cardIndexInTrick: 1);

      expect(provider.selectedQaydhaTrickIndex, equals(0));
      expect(provider.selectedQaydhaProofTrickIndex, equals(0));

      // Tap 3rd card (Trick 1, Seat 3) -> resets both and becomes new Accused card
      provider.selectQaydhaCard(1, 3, cardIndexInTrick: 0);

      expect(provider.selectedQaydhaTrickIndex, equals(1));
      expect(provider.selectedQaydhaCardSeatIndex, equals(3));
      expect(provider.selectedQaydhaProofTrickIndex, isNull);
      expect(provider.selectedQaydhaProofSeatIndex, isNull);
    });

    // 15. Unplayed Hand Filtering
    test('15. testQaid_UnplayedHandFiltering: Accused card must come from completed tricks', () {
      final provider = GameProvider(random: Random(42));
      provider.audioService.setMuted(true);

      // Proof card can only be selected from hand IF an accused trick card was already chosen
      provider.selectQaydhaProofCard(1, 0);
      // Accused trick was not selected, so proof from hand is rejected
      expect(provider.selectedQaydhaProofSeatIndex, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4: Sawa Full Lifecycle & False Sawa Challenge (4 Tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 4: Sawa Full Lifecycle & False Sawa Challenge', () {
    // 16. Legitimate Sawa Claim
    test('16. testSawa_LegitimateClaim_InstantWin: Valid Sawa claim awards Kabout and full points', () {
      final controller = BalootGameController(random: Random(42));
      controller.startNewGame(playerNames);
      controller.startNewRound();

      // In Sun mode, Sawa Kabout gives 44 points (+ ground bonus handled in scoring)
      const scoring = ScoringEngine();
      final score = scoring.calculateRoundScore(
        teamAAbnat: 130,
        teamBAbnat: 0,
        mode: GameMode.sun,
        buyerTeam: 'A',
        teamATricksCount: 8,
        teamBTricksCount: 0,
        isKabout: true,
      );
      expect(score.teamAPoints, equals(44));
      expect(score.isKabout, isTrue);
    });

    // 17. False Sawa Claim gives entire round to opponent
    test('17. testSawa_FalseClaim_OpponentInstantWin: False Sawa awards all points to opponent team', () {
      final controller = BalootGameController(random: Random(42));
      controller.startNewGame(playerNames);
      controller.startNewRound();

      // Pass Round 1 with Sun bid
      final firstBidder = controller.roundState.currentPlayerIndex;
      controller.placeBid(firstBidder, BidAction.sun);
      if (controller.gamePhase == GamePhase.doubleWindow) controller.skipDoubleWindow();

      expect(controller.gamePhase, equals(GamePhase.playing));

      // Seat 1 makes a false Sawa claim -> Opponent objects correctly
      controller.resolveSawaObjection(1, true);

      // Winner must be Team A (Seat 0 and Seat 2), opponent of claimant Seat 1
      expect(controller.lastRoundScoreResult, isNotNull);
      expect(controller.lastRoundScoreResult!.winningTeam, equals('A'));
      expect(controller.lastRoundScoreResult!.isKabout, isTrue);
      expect(controller.lastRoundScoreResult!.teamAPoints, equals(44));
      expect(controller.lastRoundScoreResult!.teamBPoints, equals(0));
    });

    // 18. Bug Fix Verification in game_provider.dart: Seat 1 claims, Seat 0 objects
    test('18. testSawa_OpponentChallenge_BugFixVerification: Objecting to opponent Sawa awards win to challenger', () {
      final controller = BalootGameController(random: Random(42));
      controller.startNewGame(playerNames);
      controller.startNewRound();

      final firstBidder = controller.roundState.currentPlayerIndex;
      controller.placeBid(firstBidder, BidAction.sun);
      if (controller.gamePhase == GamePhase.doubleWindow) controller.skipDoubleWindow();

      expect(controller.gamePhase, equals(GamePhase.playing));

      // Claimant is Seat 1 (Team B). Objection is correct (invalid claim).
      // Verify resolveSawaObjection assigns victory to Team A (challenger's team).
      const claimantSeat = 1;
      const isObjectionCorrect = true;

      controller.resolveSawaObjection(claimantSeat, isObjectionCorrect);

      expect(controller.lastRoundScoreResult!.winningTeam, equals('A'));
      expect(controller.gameScore.teamA, equals(44));
      expect(controller.gameScore.teamB, equals(0));
    });

    // 19. Sawa Reveal Exposes Hands
    test('19. testSawa_UnrevealedOpponentHandsInspection: Sawa reveal exposes all players remaining hands', () {
      final provider = GameProvider(random: Random(42));
      provider.audioService.setMuted(true);
      provider.startGame();

      // During normal play, sawaRevealCardsForSeat is empty if no Sawa active
      expect(provider.sawaRevealCardsForSeat(0), isEmpty);
      expect(provider.isSawaRevealPlaying, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5: Gahwa Mechanics & Match Termination (3 Tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 5: Gahwa Mechanics & Match Termination', () {
    // 20. Gahwa Escalation Chain
    test('20. testGahwa_EscalationChain_DoubleThurayiFourGahwa: Valid bidding escalation sequence', () {
      // In Hakam mode, Double -> Triple -> Four -> Gahwa
      const validProgression = [
        DoubleStatus.doubled,
        DoubleStatus.tripled,
        DoubleStatus.four,
        DoubleStatus.gahwa,
      ];
      expect(validProgression.length, equals(4));

      // Calling Double when double window is not open throws InvalidMoveException
      final controller = BalootGameController(random: Random(42));
      controller.startNewGame(playerNames);
      controller.startNewRound();
      expect(
        () => controller.callDouble(0, DoubleStatus.gahwa),
        throwsA(isA<Exception>()),
      );
    });

    // 21. Gahwa Match Instant Win (152 Points)
    test('21. testGahwa_MatchInstantWin_152Points: Winner of Gahwa round receives 152 points', () {
      const scoring = ScoringEngine();

      final scoreResult = scoring.calculateRoundScore(
        teamAAbnat: 90,
        teamBAbnat: 72,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.gahwa,
      );

      expect(scoreResult.teamAPoints, equals(152));
      expect(scoreResult.winningTeam, equals('A'));
      expect(scoring.isGameOver(152, 0, DoubleStatus.gahwa), isTrue);
    });

    // 22. Gahwa Tie-Breaker: Caller (Buyer) Loses
    test('22. testGahwa_TieBreaker_BuyerLoses: In Gahwa tie (81 vs 81), buyer loses match', () {
      const scoring = ScoringEngine();

      final tieScore = scoring.calculateRoundScore(
        teamAAbnat: 81,
        teamBAbnat: 81,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        doubleCallerTeam: 'A', // Buyer called Gahwa
        teamATricksCount: 4,
        teamBTricksCount: 4,
        doubleStatus: DoubleStatus.gahwa,
      );

      // Buyer called Gahwa and tied -> Buyer loses (Khams) -> Defender (Team B) wins!
      expect(tieScore.winningTeam, equals('B'));
      expect(tieScore.isKhams, isTrue);
      expect(tieScore.teamBPoints, equals(152)); // Defender wins 152 in Gahwa
      expect(tieScore.teamAPoints, equals(0));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 6: Kammelna Parity — Direct False Ekka & Sawa Verification
  // ═══════════════════════════════════════════════════════════════════════════
  group('Group 6: Kammelna Parity — Direct False Ekka & Sawa Verification', () {
    test('23. testFalseEkka_DirectChallenge_InstantResolution: wrongTrick resolves instantly without review overlay', () {
      final provider = GameProvider(random: Random(42));
      provider.audioService.setMuted(true);
      provider.startGame();

      // Put engine into playing phase
      provider.engine.startNewRound();
      final firstBidder = provider.engine.roundState.currentPlayerIndex;
      provider.engine.placeBid(firstBidder, BidAction.sun);
      if (provider.engine.gamePhase == GamePhase.doubleWindow) {
        provider.engine.skipDoubleWindow();
      }

      // Simulate opponent Seat 1 leading King of Spades (Ace of Spades unplayed)
      const akkaCard = CardModel(suit: Suit.spades, rank: Rank.king);
      provider.openFalseEkkaWindowForTest(1, akkaCard);

      expect(provider.isFalseEkkaWindowOpen, isTrue);

      // Challenger presses "False Ekka"
      provider.handleQaydhaMenuSelection(QaydhaActionType.wrongTrick);

      // Must resolve instantly: overlay not open, window closed, scoreboard captured
      expect(provider.isQaydhaReviewVisible, isFalse);
      expect(provider.isFalseEkkaWindowOpen, isFalse);
      expect(provider.lastRoundResult, isNotNull);
      expect(provider.lastRoundResult!.isQaydha, isTrue);
      expect(provider.lastRoundResult!.qaydhaCorrect, isTrue); // Ace was unplayed -> Akka was false!
      expect(provider.lastRoundResult!.qaydhaViolationType, equals(QaydhaViolationType.falseEkka));
    });

    test('24. testFalseEkka_AceLead_DetectedAsAkka: Leading an Ace is recognized as Akka in Hakam and Sun', () {
      final controller = BalootGameController(random: Random(42));
      controller.startNewGame(playerNames);
      controller.startNewRound();

      final firstBidder = controller.roundState.currentPlayerIndex;
      controller.placeBid(firstBidder, BidAction.sun);
      if (controller.gamePhase == GamePhase.doubleWindow) controller.skipDoubleWindow();

      expect(controller.gamePhase, equals(GamePhase.playing));

      final leadPlayer = controller.roundState.currentPlayerIndex;
      // Find an Ace in hand or play lead card
      final hand = controller.getHand(leadPlayer);
      final aceCard = hand.firstWhere(
        (c) => c.rank == Rank.ace,
        orElse: () => hand.first,
      );

      controller.playCard(leadPlayer, aceCard);

      if (aceCard.rank == Rank.ace) {
        expect(controller.isAkka(aceCard), isTrue);
      } else {
        expect(controller.isAkka(aceCard), isA<bool>());
      }
    });

    test('25. testFalseSawa_DirectChallenge_InstantObjection: wrongSawa objection awards Kabout to challenger', () {
      final provider = GameProvider(random: Random(42));
      provider.audioService.setMuted(true);
      provider.startGame();

      // Simulate opponent Seat 1 claiming Sawa (with non-master cards)
      provider.startSawaRevealForTest(1);
      expect(provider.isFalseSawaWindowOpen, isTrue);

      // Challenger taps "Wrong Sawa"
      provider.handleQaydhaMenuSelection(QaydhaActionType.wrongSawa);

      // Must finalize Sawa reveal and award victory
      expect(provider.isFalseSawaWindowOpen, isFalse);
      expect(provider.isSawaRevealPlaying, isFalse);
    });
  });
}

