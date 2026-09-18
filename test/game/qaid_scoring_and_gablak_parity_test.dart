import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/managers/bidding_manager.dart';
import 'package:baloot_game/features/game/domain/engines/scoring_engine.dart';
import 'package:baloot_game/features/game/domain/models/qaydha_models.dart';
import 'package:baloot_game/core/errors/game_exceptions.dart';

void main() {
  group('1. Dealer Restriction ("Gablak") Parity Scenarios', () {
    const defaultBuyerCard = CardModel(suit: Suit.hearts, rank: Rank.king);

    test('1.1 Dealer cannot override First Player\'s Hakam with Hakam', () {
      // Dealer is Seat 0. First player is Seat 1.
      final bm = BiddingManager(dealerIndex: 0, buyerCard: defaultBuyerCard);

      // Seat 1 (First Player) takes Hakam
      expect(bm.currentBidder, 1);
      bm.placeBid(1, BidAction.hakam);

      // Seat 2 and Seat 3 pass
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);

      // Turn reaches Dealer (Seat 0)
      expect(bm.currentBidder, 0);
      final dealerActions = bm.getAllowedActions(0);

      // Dealer CANNOT bid Hakam or "Gablak" on Hakam!
      expect(dealerActions.contains(BidAction.hakam), isFalse,
          reason: 'Dealer should NOT have Hakam action when first player bid Hakam');
      expect(dealerActions, containsAll([BidAction.sun, BidAction.ashkal, BidAction.pass]));

      // Attempting to place Hakam anyway must throw an InvalidBidException
      expect(
        () => bm.placeBid(0, BidAction.hakam),
        throwsA(isA<InvalidBidException>().having(
          (e) => e.message,
          'message',
          contains('First player took Hakam. Dealer cannot override'),
        )),
      );
    });

    test('1.2 Dealer can override First Player\'s Hakam with Sun', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: defaultBuyerCard);

      // First player takes Hakam
      bm.placeBid(1, BidAction.hakam);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);

      // Dealer chooses Sun (valid override)
      bm.placeBid(0, BidAction.sun);

      // Sun triggers Qablak intervention for earlier seats or completes
      expect(bm.result?.mode == GameMode.sun || bm.phase == BiddingPhase.qablakIntervention, isTrue);
    });

    test('1.3 Dealer can override First Player\'s Hakam with Ashkal', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: defaultBuyerCard);

      // First player takes Hakam
      bm.placeBid(1, BidAction.hakam);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);

      // Dealer chooses Ashkal (valid override)
      bm.placeBid(0, BidAction.ashkal);

      // Ashkal forces Sun mode
      expect(bm.result?.mode == GameMode.sun || bm.phase == BiddingPhase.qablakIntervention, isTrue);
    });

    test('1.4 Dealer Pass locks in First Player\'s Hakam', () {
      final bm = BiddingManager(dealerIndex: 0, buyerCard: defaultBuyerCard);

      // First player takes Hakam
      bm.placeBid(1, BidAction.hakam);
      bm.placeBid(2, BidAction.pass);
      bm.placeBid(3, BidAction.pass);

      // Dealer passes
      bm.placeBid(0, BidAction.pass);

      // All 3 others passed -> Advances to Hakam Confirmation for Seat 1
      expect(bm.phase, BiddingPhase.hakamConfirmation);
      expect(bm.currentBidder, 1);
    });

    test('1.5 Rotational Independence: Verified across all dealer positions', () {
      for (int dealer = 0; dealer < 4; dealer++) {
        final bm = BiddingManager(dealerIndex: dealer, buyerCard: defaultBuyerCard);
        final firstPlayer = (dealer + 1) % 4;

        // First player bids Hakam
        expect(bm.currentBidder, firstPlayer);
        bm.placeBid(firstPlayer, BidAction.hakam);

        // Advance until turn reaches Dealer
        while (bm.currentBidder != dealer) {
          bm.placeBid(bm.currentBidder, BidAction.pass);
        }

        // Dealer must not be allowed to bid Hakam
        final actions = bm.getAllowedActions(dealer);
        expect(actions.contains(BidAction.hakam), isFalse,
            reason: 'Dealer (Seat $dealer) must not have Hakam when first player (Seat $firstPlayer) bid Hakam');
        expect(actions, containsAll([BidAction.sun, BidAction.ashkal, BidAction.pass]));
      }
    });
  });

  group('2. Qaid Scoring Exact Parity Scenarios (26 Sun / 16 Hakam)', () {
    final scoringEngine = ScoringEngine();

    test('2.1 Correct Qaid in Sun Mode awards exactly 26 points (NOT 44 Kabout)', () {
      final correctQaydha = QaydhaResult(
        challengerIndex: 0, // Team A challenged
        violationType: QaydhaViolationType.qate,
        isCorrect: true, // Proven cheating
        trickIndex: 2,
        accusedCard: const CardModel(suit: Suit.spades, rank: Rank.seven),
      );

      final result = scoringEngine.calculateRoundScore(
        teamAAbnat: 60,
        teamBAbnat: 70,
        mode: GameMode.sun,
        buyerTeam: 'B',
        teamATricksCount: 4,
        teamBTricksCount: 4,
        qaydhaResult: correctQaydha,
      );

      expect(result.winningTeam, equals('A'), reason: 'Challenger team wins the Qaid');
      expect(result.teamAPoints, equals(26), reason: 'Sun Qaid base points must be 26 (Kammelna standard)');
      expect(result.teamBPoints, equals(0), reason: 'Violating team gets 0 points');
      expect(result.isKabout, isFalse, reason: 'Qaid is distinct from Kabout');
      expect(result.isQaydha, isTrue);
    });

    test('2.2 Correct Qaid in Hakam Mode awards exactly 16 points (NOT 25 Kabout)', () {
      final correctQaydha = QaydhaResult(
        challengerIndex: 1, // Team B challenged
        violationType: QaydhaViolationType.maDaqBiHakam,
        isCorrect: true,
        trickIndex: 1,
        accusedCard: const CardModel(suit: Suit.hearts, rank: Rank.eight),
      );

      final result = scoringEngine.calculateRoundScore(
        teamAAbnat: 80,
        teamBAbnat: 72,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 4,
        teamBTricksCount: 4,
        qaydhaResult: correctQaydha,
      );

      expect(result.winningTeam, equals('B'), reason: 'Challenger team B wins');
      expect(result.teamBPoints, equals(16), reason: 'Hakam Qaid base points must be 16 (Kammelna standard)');
      expect(result.teamAPoints, equals(0), reason: 'Violating team A gets 0 points');
      expect(result.isKabout, isFalse);
    });

    test('2.3 Correct Qaid in Sun with Declared Projects: Winner steals all projects', () {
      final correctQaydha = QaydhaResult(
        challengerIndex: 0, // Team A
        violationType: QaydhaViolationType.qate,
        isCorrect: true,
        trickIndex: 3,
        accusedCard: const CardModel(suit: Suit.clubs, rank: Rank.jack),
      );

      // Team A had 4 pts projects (Sira), Team B had 10 pts projects (100)
      final result = scoringEngine.calculateRoundScore(
        teamAAbnat: 50,
        teamBAbnat: 80,
        mode: GameMode.sun,
        buyerTeam: 'B',
        teamATricksCount: 3,
        teamBTricksCount: 5,
        teamAProjectScoreboard: 4,
        teamBProjectScoreboard: 10,
        qaydhaResult: correctQaydha,
      );

      expect(result.winningTeam, equals('A'));
      // 26 base + 4 own projects + 10 stolen projects = 40 points
      expect(result.teamAPoints, equals(26 + 4 + 10));
      expect(result.teamBPoints, equals(0));
    });

    test('2.4 Correct Qaid with Doubled Sun awards 52 points (26 × 2)', () {
      final correctQaydha = QaydhaResult(
        challengerIndex: 0,
        violationType: QaydhaViolationType.qate,
        isCorrect: true,
        trickIndex: 0,
        accusedCard: const CardModel(suit: Suit.diamonds, rank: Rank.queen),
      );

      final result = scoringEngine.calculateRoundScore(
        teamAAbnat: 70,
        teamBAbnat: 60,
        mode: GameMode.sun,
        buyerTeam: 'B',
        doubleStatus: DoubleStatus.doubled,
        teamATricksCount: 4,
        teamBTricksCount: 4,
        qaydhaResult: correctQaydha,
      );

      expect(result.winningTeam, equals('A'));
      expect(result.teamAPoints, equals(52), reason: 'Doubled Sun Qaid must be 52 (26 * 2)');
      expect(result.teamBPoints, equals(0));
    });

    test('2.5 Correct Qaid with Doubled Hakam awards 32 / 48 / 64 points', () {
      final qaid = QaydhaResult(
        challengerIndex: 0,
        violationType: QaydhaViolationType.maKabbarBiHakam,
        isCorrect: true,
        trickIndex: 2,
        accusedCard: const CardModel(suit: Suit.hearts, rank: Rank.nine),
      );

      // Doubled: 16 * 2 = 32
      final res2 = scoringEngine.calculateRoundScore(
        teamAAbnat: 80, teamBAbnat: 72, mode: GameMode.hakam, buyerTeam: 'B',
        doubleStatus: DoubleStatus.doubled, teamATricksCount: 4, teamBTricksCount: 4,
        qaydhaResult: qaid,
      );
      expect(res2.teamAPoints, equals(32));

      // Tripled: 16 * 3 = 48
      final res3 = scoringEngine.calculateRoundScore(
        teamAAbnat: 80, teamBAbnat: 72, mode: GameMode.hakam, buyerTeam: 'B',
        doubleStatus: DoubleStatus.tripled, teamATricksCount: 4, teamBTricksCount: 4,
        qaydhaResult: qaid,
      );
      expect(res3.teamAPoints, equals(48));

      // Four: 16 * 4 = 64
      final res4 = scoringEngine.calculateRoundScore(
        teamAAbnat: 80, teamBAbnat: 72, mode: GameMode.hakam, buyerTeam: 'B',
        doubleStatus: DoubleStatus.four, teamATricksCount: 4, teamBTricksCount: 4,
        qaydhaResult: qaid,
      );
      expect(res4.teamAPoints, equals(64));
    });

    test('2.6 False Qaid Penalty: Accusing team gets 0, Accused team gets full 26 / 16 points', () {
      // Team A falsely accuses Team B in Sun mode
      final falseQaydhaSun = QaydhaResult(
        challengerIndex: 0, // Team A falsely challenges
        violationType: QaydhaViolationType.qate,
        isCorrect: false, // FALSE accusation!
        trickIndex: 1,
        accusedCard: const CardModel(suit: Suit.spades, rank: Rank.ace),
      );

      final resultSun = scoringEngine.calculateRoundScore(
        teamAAbnat: 60,
        teamBAbnat: 70,
        mode: GameMode.sun,
        buyerTeam: 'A',
        teamATricksCount: 4,
        teamBTricksCount: 4,
        qaydhaResult: falseQaydhaSun,
      );

      expect(resultSun.winningTeam, equals('B'), reason: 'Innocent Team B wins false Qaid');
      expect(resultSun.teamBPoints, equals(26), reason: 'Innocent Team B receives the full 26 Sun points');
      expect(resultSun.teamAPoints, equals(0));

      // Team A falsely accuses Team B in Hakam mode
      final falseQaydhaHakam = QaydhaResult(
        challengerIndex: 0,
        violationType: QaydhaViolationType.maKabbarBiHakam,
        isCorrect: false,
        trickIndex: 1,
        accusedCard: const CardModel(suit: Suit.hearts, rank: Rank.seven),
      );

      final resultHakam = scoringEngine.calculateRoundScore(
        teamAAbnat: 60,
        teamBAbnat: 92,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 4,
        teamBTricksCount: 4,
        qaydhaResult: falseQaydhaHakam,
      );

      expect(resultHakam.winningTeam, equals('B'), reason: 'Innocent Team B wins false Qaid');
      expect(resultHakam.teamBPoints, equals(16), reason: 'Innocent Team B receives the full 16 Hakam points');
      expect(resultHakam.teamAPoints, equals(0));
    });
  });
}
