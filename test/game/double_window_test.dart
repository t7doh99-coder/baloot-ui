import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/core/errors/game_exceptions.dart';
import 'package:baloot_game/features/game/domain/managers/bidding_manager.dart';
import 'package:baloot_game/features/game/domain/baloot_game_controller.dart';
import 'package:baloot_game/features/game/domain/engines/scoring_engine.dart';

// ══════════════════════════════════════════════════════════════════
//  TEST HELPERS
// ══════════════════════════════════════════════════════════════════

/// Advance from dealing -> bidding (mirrors UI flow).
void _syncRound(BalootGameController ctrl) {
  if (ctrl.gamePhase == GamePhase.dealing) {
    ctrl.startNewRound();
  }
}

/// Bid Hakam with the current player, then pass the rest through confirmation.
void _bidHakam(BalootGameController ctrl) {
  ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.hakam);
  while (ctrl.gamePhase == GamePhase.bidding) {
    final bp = ctrl.roundState.biddingPhase;
    if (bp == BiddingPhase.hakamConfirmation) {
      ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.confirmHakam);
    } else {
      ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.pass);
    }
  }
}

/// Bid Sun with the current player, then pass the rest through confirmation.
void _bidSun(BalootGameController ctrl) {
  ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.sun);
  while (ctrl.gamePhase == GamePhase.bidding) {
    final bp = ctrl.roundState.biddingPhase;
    if (bp == BiddingPhase.hakamConfirmation) {
      ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.confirmHakam);
    } else {
      ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.pass);
    }
  }
}

/// Returns a defending seat (opposite team of buyer).
int _defenderSeat(BalootGameController ctrl) {
  final buyerIdx = ctrl.roundState.buyerIndex!;
  return (buyerIdx % 2 == 0) ? 1 : 0;
}

/// Returns a buyer team seat.
int _buyerTeamSeat(BalootGameController ctrl) {
  final buyerIdx = ctrl.roundState.buyerIndex!;
  return (buyerIdx % 2 == 0) ? 0 : 1;
}

void main() {
  const scoring = ScoringEngine();

  // ══════════════════════════════════════════════════════════════════
  //  GROUP 1: DOUBLE WINDOW BASICS
  // ══════════════════════════════════════════════════════════════════

  group('Group 1: Double Window Basics', () {
    test('1. Double window opens after bidding with 8 cards per player', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      expect(ctrl.gamePhase, GamePhase.doubleWindow);
      expect(ctrl.roundState.isDoubleWindowOpen, true);
      expect(ctrl.roundState.doubleStatus, DoubleStatus.none);

      // All 4 players must have full 8 cards dealt
      for (int seat = 0; seat < 4; seat++) {
        expect(ctrl.getHand(seat).length, 8,
            reason: 'Seat $seat must have all 8 cards before double window');
      }
    });

    test('2. Skip double proceeds to play with doubleStatus.none', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      expect(ctrl.gamePhase, GamePhase.doubleWindow);
      ctrl.skipDoubleWindow();

      expect(ctrl.gamePhase, GamePhase.playing);
      expect(ctrl.roundState.doubleStatus, DoubleStatus.none);
      expect(ctrl.roundState.isDoubleWindowOpen, false);
    });

    test('3. Defender can call Double', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      ctrl.callDouble(defSeat, DoubleStatus.doubled);

      expect(ctrl.roundState.doubleStatus, DoubleStatus.doubled);
      expect(ctrl.roundState.doubleCallerIndex, defSeat);
    });

    test('4. Buyer team CANNOT call Double', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final buyerSeat = _buyerTeamSeat(ctrl);
      expect(
        () => ctrl.callDouble(buyerSeat, DoubleStatus.doubled),
        throwsA(isA<InvalidBidException>()),
        reason: 'Buyer team calling Double must throw InvalidBidException',
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  GROUP 2: ESCALATION CHAIN (HAKAM)
  // ══════════════════════════════════════════════════════════════════

  group('Group 2: Escalation Chain (Hakam)', () {
    test('5. Double -> Triple flow', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      final buySeat = _buyerTeamSeat(ctrl);

      ctrl.callDouble(defSeat, DoubleStatus.doubled);
      expect(ctrl.roundState.doubleStatus, DoubleStatus.doubled);

      ctrl.callDouble(buySeat, DoubleStatus.tripled);
      expect(ctrl.roundState.doubleStatus, DoubleStatus.tripled);
    });

    test('6. Triple -> Four flow', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      final buySeat = _buyerTeamSeat(ctrl);

      ctrl.callDouble(defSeat, DoubleStatus.doubled);
      ctrl.callDouble(buySeat, DoubleStatus.tripled);
      ctrl.callDouble(defSeat, DoubleStatus.four);

      expect(ctrl.roundState.doubleStatus, DoubleStatus.four);
    });

    test('7. Four -> Gahwa flow transitions directly to playing phase', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      final buySeat = _buyerTeamSeat(ctrl);

      ctrl.callDouble(defSeat, DoubleStatus.doubled);
      ctrl.callDouble(buySeat, DoubleStatus.tripled);
      ctrl.callDouble(defSeat, DoubleStatus.four);
      ctrl.callDouble(buySeat, DoubleStatus.gahwa);

      expect(ctrl.roundState.doubleStatus, DoubleStatus.gahwa);
      expect(ctrl.gamePhase, GamePhase.playing);
      expect(ctrl.roundState.isDoubleWindowOpen, false);
    });

    test('8. Full chain: Double -> Triple -> Four -> Gahwa in sequence', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      final buySeat = _buyerTeamSeat(ctrl);

      ctrl.callDouble(defSeat, DoubleStatus.doubled);
      expect(ctrl.roundState.doubleStatus, DoubleStatus.doubled);

      ctrl.callDouble(buySeat, DoubleStatus.tripled);
      expect(ctrl.roundState.doubleStatus, DoubleStatus.tripled);

      ctrl.callDouble(defSeat, DoubleStatus.four);
      expect(ctrl.roundState.doubleStatus, DoubleStatus.four);

      ctrl.callDouble(buySeat, DoubleStatus.gahwa);
      expect(ctrl.roundState.doubleStatus, DoubleStatus.gahwa);
      expect(ctrl.gamePhase, GamePhase.playing);
    });

    test('9. Wrong team escalation is rejected', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      final buySeat = _buyerTeamSeat(ctrl);

      ctrl.callDouble(defSeat, DoubleStatus.doubled);

      // Defender trying to call Triple must be rejected
      expect(
        () => ctrl.callDouble(defSeat, DoubleStatus.tripled),
        throwsA(isA<InvalidBidException>()),
      );

      ctrl.callDouble(buySeat, DoubleStatus.tripled);

      // Buyer trying to call Four must be rejected
      expect(
        () => ctrl.callDouble(buySeat, DoubleStatus.four),
        throwsA(isA<InvalidBidException>()),
      );

      ctrl.callDouble(defSeat, DoubleStatus.four);

      // Defender trying to call Gahwa must be rejected
      expect(
        () => ctrl.callDouble(defSeat, DoubleStatus.gahwa),
        throwsA(isA<InvalidBidException>()),
      );
    });

    test('10. Buyer skips after Double proceeds to play with doubled status', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      ctrl.callDouble(defSeat, DoubleStatus.doubled);
      expect(ctrl.roundState.doubleStatus, DoubleStatus.doubled);

      ctrl.skipDoubleWindow();
      expect(ctrl.gamePhase, GamePhase.playing);
      expect(ctrl.roundState.doubleStatus, DoubleStatus.doubled);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  GROUP 3: SUN MODE DOUBLE RESTRICTIONS
  // ══════════════════════════════════════════════════════════════════

  group('Group 3: Sun Mode Double Restrictions', () {
    test('11. Sun: Double allowed when buyer > 100 and defender < 100', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);

      // Current player will bid Sun. Determine team:
      final bidder = ctrl.roundState.currentPlayerIndex;
      final bidderIsTeamA = bidder % 2 == 0;

      // Buyer > 100, Defender < 100
      if (bidderIsTeamA) {
        ctrl.setScoresForTest(120, 40);
      } else {
        ctrl.setScoresForTest(40, 120);
      }

      _bidSun(ctrl);

      expect(ctrl.gamePhase, GamePhase.doubleWindow);
      expect(ctrl.roundState.isDoubleWindowOpen, true);

      final defSeat = _defenderSeat(ctrl);
      ctrl.callDouble(defSeat, DoubleStatus.doubled);
      expect(ctrl.roundState.doubleStatus, DoubleStatus.doubled);
    });

    test('12. Sun: Double blocked when buyer <= 100 (window skipped)', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);

      // Both teams <= 100 pts
      ctrl.setScoresForTest(80, 50);
      _bidSun(ctrl);

      // Window should have been skipped entirely
      expect(ctrl.gamePhase, GamePhase.playing);
      expect(ctrl.roundState.isDoubleWindowOpen, false);

      // Calling double now throws InvalidMoveException (not in double window)
      final defSeat = _defenderSeat(ctrl);
      expect(
        () => ctrl.callDouble(defSeat, DoubleStatus.doubled),
        throwsA(isA<InvalidMoveException>()),
      );
    });

    test('13. Sun: Triple/Four/Gahwa always blocked', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);

      final bidder = ctrl.roundState.currentPlayerIndex;
      final bidderIsTeamA = bidder % 2 == 0;
      if (bidderIsTeamA) {
        ctrl.setScoresForTest(120, 40);
      } else {
        ctrl.setScoresForTest(40, 120);
      }

      _bidSun(ctrl);
      expect(ctrl.gamePhase, GamePhase.doubleWindow);

      final defSeat = _defenderSeat(ctrl);
      final buySeat = _buyerTeamSeat(ctrl);

      ctrl.callDouble(defSeat, DoubleStatus.doubled);

      // Triple is blocked in Sun
      expect(
        () => ctrl.callDouble(buySeat, DoubleStatus.tripled),
        throwsA(isA<InvalidBidException>()),
      );

      // Four is blocked in Sun
      expect(
        () => ctrl.callDouble(defSeat, DoubleStatus.four),
        throwsA(isA<InvalidBidException>()),
      );

      // Gahwa is blocked in Sun
      expect(
        () => ctrl.callDouble(buySeat, DoubleStatus.gahwa),
        throwsA(isA<InvalidBidException>()),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  GROUP 4: OPEN VS CLOSED PLAY
  // ══════════════════════════════════════════════════════════════════

  group('Group 4: Open vs Closed Play', () {
    test('14. Closed Play: cannot lead with trump when holding non-trump', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      ctrl.callDouble(defSeat, DoubleStatus.doubled, isOpenPlay: false);
      ctrl.skipDoubleWindow();

      expect(ctrl.gamePhase, GamePhase.playing);
      expect(ctrl.roundState.isOpenPlay, false);

      final leadSeat = ctrl.roundState.currentPlayerIndex;
      final trump = ctrl.roundState.trumpSuit!;
      final nonTrump = Suit.values.firstWhere((s) => s != trump);

      // Lead player has 1 trump and 1 non-trump
      final trumpCard = CardModel(suit: trump, rank: Rank.seven);
      final nonTrumpCard = CardModel(suit: nonTrump, rank: Rank.eight);
      ctrl.setHandForTest(leadSeat, [trumpCard, nonTrumpCard]);

      // Leading with trump while holding non-trump must throw PlayViolationException
      expect(
        () => ctrl.playCard(leadSeat, trumpCard),
        throwsA(isA<PlayViolationException>()),
      );
    });

    test('15. Open Play: can lead with trump', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      ctrl.callDouble(defSeat, DoubleStatus.doubled, isOpenPlay: true);
      ctrl.skipDoubleWindow();

      expect(ctrl.gamePhase, GamePhase.playing);
      expect(ctrl.roundState.isOpenPlay, true);

      final leadSeat = ctrl.roundState.currentPlayerIndex;
      final trump = ctrl.roundState.trumpSuit!;
      final nonTrump = Suit.values.firstWhere((s) => s != trump);

      final trumpCard = CardModel(suit: trump, rank: Rank.seven);
      final nonTrumpCard = CardModel(suit: nonTrump, rank: Rank.eight);
      ctrl.setHandForTest(leadSeat, [trumpCard, nonTrumpCard]);

      // In Open Play, leading with trump is permitted
      expect(() => ctrl.playCard(leadSeat, trumpCard), returnsNormally);
    });

    test('16. Closed Play: can lead with trump when ONLY trump remains', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      ctrl.callDouble(defSeat, DoubleStatus.doubled, isOpenPlay: false);
      ctrl.skipDoubleWindow();

      expect(ctrl.roundState.isOpenPlay, false);

      final leadSeat = ctrl.roundState.currentPlayerIndex;
      final trump = ctrl.roundState.trumpSuit!;

      // Lead player holds ONLY trump cards
      final trump1 = CardModel(suit: trump, rank: Rank.seven);
      final trump2 = CardModel(suit: trump, rank: Rank.eight);
      ctrl.setHandForTest(leadSeat, [trump1, trump2]);

      // Leading trump is allowed when holding no non-trump cards
      expect(() => ctrl.playCard(leadSeat, trump1), returnsNormally);
    });

    test('17. Open/Closed persists through escalation', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);
      _syncRound(ctrl);
      _bidHakam(ctrl);

      final defSeat = _defenderSeat(ctrl);
      final buySeat = _buyerTeamSeat(ctrl);

      // First Double picks Closed Play
      ctrl.callDouble(defSeat, DoubleStatus.doubled, isOpenPlay: false);
      expect(ctrl.roundState.isOpenPlay, false);

      // Triple escalation inherits Closed Play
      ctrl.callDouble(buySeat, DoubleStatus.tripled);
      expect(ctrl.roundState.isOpenPlay, false);

      // Four escalation inherits Closed Play
      ctrl.callDouble(defSeat, DoubleStatus.four);
      expect(ctrl.roundState.isOpenPlay, false);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  GROUP 5: SCORING WITH DOUBLES
  // ══════════════════════════════════════════════════════════════════

  group('Group 5: Scoring with Doubles', () {
    test('18. Hakam Double: winner gets 32, loser gets 0', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 90,
        teamBAbnat: 72,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.doubled,
      );
      expect(r.teamAPoints, 32);
      expect(r.teamBPoints, 0);
    });

    test('19. Hakam Triple: winner gets 48', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 90,
        teamBAbnat: 72,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.tripled,
      );
      expect(r.teamAPoints, 48);
      expect(r.teamBPoints, 0);
    });

    test('20. Hakam Four: winner gets 64', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 90,
        teamBAbnat: 72,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.four,
      );
      expect(r.teamAPoints, 64);
      expect(r.teamBPoints, 0);
    });

    test('21. Hakam Gahwa: winner gets 152 (instant game over)', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 90,
        teamBAbnat: 72,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.gahwa,
      );
      expect(r.teamAPoints, 152);
      expect(scoring.isGameOver(r.teamAPoints, r.teamBPoints, DoubleStatus.gahwa), true);
    });

    test('22. Sun Double: winner gets 52', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 70,
        teamBAbnat: 60,
        mode: GameMode.sun,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.doubled,
      );
      expect(r.teamAPoints, 52);
      expect(r.teamBPoints, 0);
    });

    test('23. Khams with Double: defenders get 32, buyer gets 0', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 70,
        teamBAbnat: 92,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 3,
        teamBTricksCount: 5,
        doubleStatus: DoubleStatus.doubled,
      );
      expect(r.isKhams, true);
      expect(r.teamAPoints, 0);
      expect(r.teamBPoints, 32);
    });

    test('24. Kabout with Double: 25x2 = 50 pts', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 162,
        teamBAbnat: 0,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 8,
        teamBTricksCount: 0,
        isKabout: true,
        doubleStatus: DoubleStatus.doubled,
      );
      expect(r.isKabout, true);
      expect(r.teamAPoints, 50);
    });

    test('25. Projects multiplied by Double level', () {
      // Sera (2 pts) in Doubled round = 32 base + 2x2 = 36 pts
      final rDoubled = scoring.calculateRoundScore(
        teamAAbnat: 90,
        teamBAbnat: 72,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.doubled,
        teamAProjectScoreboard: 2,
        projectWinningTeam: 'A',
      );
      expect(rDoubled.teamAPoints, 36);

      // Sera (2 pts) in Tripled round = 48 base + 2x3 = 54 pts
      final rTripled = scoring.calculateRoundScore(
        teamAAbnat: 90,
        teamBAbnat: 72,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.tripled,
        teamAProjectScoreboard: 2,
        projectWinningTeam: 'A',
      );
      expect(rTripled.teamAPoints, 54);

      // Sera (2 pts) in Four round = 64 base + 2x4 = 72 pts
      final rFour = scoring.calculateRoundScore(
        teamAAbnat: 90,
        teamBAbnat: 72,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.four,
        teamAProjectScoreboard: 2,
        projectWinningTeam: 'A',
      );
      expect(rFour.teamAPoints, 72);

      // Baloot is NEVER multiplied (always +2)
      final rBaloot = scoring.calculateRoundScore(
        teamAAbnat: 90,
        teamBAbnat: 72,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 5,
        teamBTricksCount: 3,
        doubleStatus: DoubleStatus.four,
        balootPoints: 2,
        balootTeam: 'A',
      );
      expect(rBaloot.teamAPoints, 66); // 64 base + 2 baloot
    });

    test('26. Tie in Doubled round: Double caller loses', () {
      final r = scoring.calculateRoundScore(
        teamAAbnat: 81,
        teamBAbnat: 81,
        mode: GameMode.hakam,
        buyerTeam: 'A',
        teamATricksCount: 4,
        teamBTricksCount: 4,
        doubleStatus: DoubleStatus.doubled,
        doubleCallerTeam: 'B',
      );
      // Team B called double, so Team B loses the tie; Team A wins
      expect(r.winningTeam, 'A');
    });
  });
}
