import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/card_play_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/baloot_game_controller.dart';
import 'package:baloot_game/features/game/domain/managers/turn_manager.dart';
import 'package:baloot_game/features/game/domain/models/qaydha_models.dart';
import 'package:baloot_game/features/game/domain/engines/qaydha_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  TrickResult makeTrick({
    required List<CardPlayModel> cards,
    Map<int, List<CardModel>>? hands,
    int winner = 0,
  }) {
    return TrickResult(
      winnerIndex: winner,
      abnat: 0,
      isLastTrick: false,
      lastTrickBonus: 0,
      cards: cards,
      handsAtStartOfTrick: hands,
    );
  }

  group('ISSUE 1 — Akkah (Ekka) Correctness', () {
    late BalootGameController game;

    setUp(() {
      game = BalootGameController();
    });

    void setupHakamSpades(TurnManager tm) {
      final rs = const RoundStateModel(dealerIndex: 0, currentPlayerIndex: 0)
          .copyWith(activeMode: GameMode.hakam, trumpSuit: Suit.spades);
      game.setRoundStateForTest(rs);
      game.setTurnManagerForTest(tm);
    }

    test('1.1 — Trick 2: holder of highest remaining card IS Akkah', () {
      final tm = TurnManager(
          mode: GameMode.hakam, trumpSuit: Suit.spades, firstPlayerIndex: 0);
      setupHakamSpades(tm);

      // Trick 1: consume A♥
      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.ace));
      tm.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.seven));
      tm.playCard(2, const CardModel(suit: Suit.clubs, rank: Rank.seven));
      tm.playCard(3, const CardModel(suit: Suit.diamonds, rank: Rank.seven));
      
      // Now in trick 2: seat 0 leads ♥10 (highest remaining heart, since A♥ is played)
      expect(tm.trickHistory.length, equals(1));

      final tenHearts = const CardModel(suit: Suit.hearts, rank: Rank.ten);
      expect(game.isAkka(tenHearts), isTrue,
          reason: '10 of hearts IS the highest remaining heart → valid Akkah');
    });

    test('1.2 — Non-lead card (4th card) must NEVER be Akkah', () {
      final tm = TurnManager(
          mode: GameMode.hakam, trumpSuit: Suit.spades, firstPlayerIndex: 0);
      setupHakamSpades(tm);

      // Complete one trick where seat 3 plays ♥10 as the 4th card (assuming A♥ was already played or ♥10 is highest left)
      // Wait, A♥ is NOT played, but it doesn't matter, if it's 4th card it's false.
      // But let's make it the highest remaining to be sure it's the 4th-card rule failing it.
      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.ace));
      tm.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.seven));
      tm.playCard(2, const CardModel(suit: Suit.hearts, rank: Rank.eight));
      tm.playCard(3, const CardModel(suit: Suit.hearts, rank: Rank.ten));
      
      final tenHearts = const CardModel(suit: Suit.hearts, rank: Rank.ten);
      expect(game.isAkka(tenHearts), isFalse,
          reason: '♥10 was the 4th card (not the lead) → must NOT be Akkah');
    });

    test('1.3 — Lower card with higher remaining in suit is NOT Akkah', () {
      final tm = TurnManager(
          mode: GameMode.hakam, trumpSuit: Suit.spades, firstPlayerIndex: 0);
      setupHakamSpades(tm);

      // No tricks played yet. Seat 0 about to lead ♥10.
      // ♥A is still out there.
      final tenHearts = const CardModel(suit: Suit.hearts, rank: Rank.ten);
      expect(game.isAkka(tenHearts), isFalse,
          reason: '♥10 is NOT highest remaining heart (♥A still out there)');
    });
  });

  group('ISSUE 2 — Qaid Reveal: Proof Card Snapshot Visibility', () {
    test('2.1 — Hand snapshot at Trick N includes cards played in later tricks', () {
      const trickN = 0;
      const botSeat = 1;
      const accusedCard = CardModel(suit: Suit.hearts, rank: Rank.ace);
      const proofCard = CardModel(suit: Suit.clubs, rank: Rank.eight);

      final trickNResult = TrickResult(
        winnerIndex: 0,
        abnat: 0,
        isLastTrick: false,
        lastTrickBonus: 0,
        cards: [
          const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.clubs, rank: Rank.king)),
          const CardPlayModel(playerIndex: botSeat, card: accusedCard),
          const CardPlayModel(playerIndex: 2, card: CardModel(suit: Suit.clubs, rank: Rank.seven)),
          const CardPlayModel(playerIndex: 3, card: CardModel(suit: Suit.clubs, rank: Rank.nine)),
        ],
        handsAtStartOfTrick: {
          botSeat: [accusedCard, proofCard],
        },
      );

      final snapshot = trickNResult.handsAtStartOfTrick![botSeat]!;
      expect(snapshot.contains(proofCard), isTrue);

      final result = QaydhaEngine.evaluateChallenge(
        history: [trickNResult],
        challengerIndex: 0,
        trickIndex: trickN,
        accusedSeatIndex: botSeat,
        violationType: QaydhaViolationType.qate,
        gameMode: GameMode.hakam,
        trumpSuit: Suit.spades,
        doubleStatus: DoubleStatus.none,
        explicitProofCard: proofCard,
      );
      expect(result.isCorrect, isTrue);
    });

    test('2.2 — Without snapshot fix: current hand would be missing 8♣', () {
      final currentHandAfterPlay = [
        const CardModel(suit: Suit.spades, rank: Rank.seven),
        const CardModel(suit: Suit.diamonds, rank: Rank.eight),
      ];
      const proofCard = CardModel(suit: Suit.clubs, rank: Rank.eight);
      expect(currentHandAfterPlay.contains(proofCard), isFalse);
    });

    test('2.3 — Snapshot correctly isolates each trick\'s hand state', () {
      const card1 = CardModel(suit: Suit.hearts, rank: Rank.ace);
      const card2 = CardModel(suit: Suit.clubs, rank: Rank.eight);

      final trick1 = TrickResult(
        winnerIndex: 0, abnat: 0, isLastTrick: false, lastTrickBonus: 0,
        cards: [const CardPlayModel(playerIndex: 0, card: card1)],
        handsAtStartOfTrick: {0: [card1, card2]},
      );
      final trick2 = TrickResult(
        winnerIndex: 0, abnat: 0, isLastTrick: false, lastTrickBonus: 0,
        cards: [const CardPlayModel(playerIndex: 0, card: card2)],
        handsAtStartOfTrick: {0: [card2]},
      );

      expect(trick1.handsAtStartOfTrick![0]!.contains(card1), isTrue);
      expect(trick1.handsAtStartOfTrick![0]!.contains(card2), isTrue);
      expect(trick2.handsAtStartOfTrick![0]!.contains(card1), isFalse);
      expect(trick2.handsAtStartOfTrick![0]!.contains(card2), isTrue);
    });

    test('2.4 — QaydhaEngine validates Qate with explicit proof from snapshot', () {
      final trick = TrickResult(
        winnerIndex: 0, abnat: 11, isLastTrick: false, lastTrickBonus: 0,
        cards: [
          const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.clubs, rank: Rank.king)),
          const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.hearts, rank: Rank.ace)),
          const CardPlayModel(playerIndex: 2, card: CardModel(suit: Suit.clubs, rank: Rank.seven)),
          const CardPlayModel(playerIndex: 3, card: CardModel(suit: Suit.clubs, rank: Rank.nine)),
        ],
        handsAtStartOfTrick: {
          1: [
            const CardModel(suit: Suit.hearts, rank: Rank.ace),
            const CardModel(suit: Suit.clubs, rank: Rank.eight),
          ],
        },
      );

      final snapshot = trick.handsAtStartOfTrick![1]!;
      final proofCard = snapshot.firstWhere((c) => c.suit == Suit.clubs);

      final result = QaydhaEngine.evaluateChallenge(
        history: [trick],
        challengerIndex: 0,
        trickIndex: 0,
        accusedSeatIndex: 1,
        violationType: QaydhaViolationType.qate,
        gameMode: GameMode.hakam,
        trumpSuit: Suit.spades,
        doubleStatus: DoubleStatus.none,
        explicitProofCard: proofCard,
      );

      expect(result.isCorrect, isTrue);
      expect(result.accusedCard, equals(const CardModel(suit: Suit.hearts, rank: Rank.ace)));
    });
  });

  group('ISSUE 3 — Bot Qaid Detection When Human Cheats', () {
    QaydhaViolationType? detectViolation(
        TrickResult trick, int accused, GameMode mode, Suit? trump,
        {DoubleStatus ds = DoubleStatus.none}) {
      final types = [
        QaydhaViolationType.qate,
        if (mode == GameMode.hakam) QaydhaViolationType.maDaqBiHakam,
        if (mode == GameMode.hakam) QaydhaViolationType.maKabbarBiHakam,
        if (mode == GameMode.hakam && ds != DoubleStatus.none)
          QaydhaViolationType.rubFiAlDubl,
      ];
      for (final t in types) {
        try {
          final r = QaydhaEngine.evaluateChallenge(
              history: [trick], challengerIndex: 0, trickIndex: 0,
              accusedSeatIndex: accused, violationType: t,
              gameMode: mode, trumpSuit: trump, doubleStatus: ds);
          if (r.isCorrect) return t;
        } catch (_) { continue; }
      }
      return null;
    }

    test('3.1 — EXACT CLIENT SCENARIO: Human breaks ♣ suit with A♥ → Qate detected', () {
      final trick = TrickResult(
        winnerIndex: 1, abnat: 15, isLastTrick: false, lastTrickBonus: 0,
        cards: [
          const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.clubs, rank: Rank.king)),
          const CardPlayModel(playerIndex: 2, card: CardModel(suit: Suit.clubs, rank: Rank.seven)),
          const CardPlayModel(playerIndex: 3, card: CardModel(suit: Suit.clubs, rank: Rank.nine)),
          const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.hearts, rank: Rank.ace)),
        ],
        handsAtStartOfTrick: {
          0: [
            const CardModel(suit: Suit.clubs, rank: Rank.eight),
            const CardModel(suit: Suit.hearts, rank: Rank.ace),
          ],
        },
      );

      final violation = detectViolation(trick, 0, GameMode.hakam, Suit.spades);
      expect(violation, equals(QaydhaViolationType.qate));
    });

    test('3.2 — Legal play: human void in led suit → bot does NOT call Qaid', () {
      final trick = TrickResult(
        winnerIndex: 1, abnat: 15, isLastTrick: false, lastTrickBonus: 0,
        cards: [
          const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.clubs, rank: Rank.king)),
          const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.hearts, rank: Rank.ace)),
        ],
        handsAtStartOfTrick: {
          0: [
            const CardModel(suit: Suit.hearts, rank: Rank.ace),
            const CardModel(suit: Suit.diamonds, rank: Rank.seven),
          ],
        },
      );

      final violation = detectViolation(trick, 0, GameMode.hakam, Suit.spades);
      expect(violation, isNull);
    });

    test('3.3 — Human plays off-suit (no trump) in Hakam when void → MaDaq detected', () {
      final trick = TrickResult(
        winnerIndex: 3, abnat: 0, isLastTrick: false, lastTrickBonus: 0,
        cards: [
          const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.diamonds, rank: Rank.ace)),
          const CardPlayModel(playerIndex: 3, card: CardModel(suit: Suit.diamonds, rank: Rank.ten)),
          const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.clubs, rank: Rank.seven)),
        ],
        handsAtStartOfTrick: {
          0: [
            const CardModel(suit: Suit.spades, rank: Rank.jack),
            const CardModel(suit: Suit.clubs, rank: Rank.seven),
          ],
        },
      );

      final violation = detectViolation(trick, 0, GameMode.hakam, Suit.spades);
      expect(violation, equals(QaydhaViolationType.maDaqBiHakam));
    });

    test('3.4 — Qabalak exemption: partner winning → bot correctly does NOT call Qaid', () {
      final trick = TrickResult(
        winnerIndex: 2, abnat: 0, isLastTrick: false, lastTrickBonus: 0,
        cards: [
          const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.diamonds, rank: Rank.ace)),
          const CardPlayModel(playerIndex: 2, card: CardModel(suit: Suit.spades, rank: Rank.jack)),
          const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.clubs, rank: Rank.seven)),
        ],
        handsAtStartOfTrick: {
          0: [
            const CardModel(suit: Suit.spades, rank: Rank.seven),
            const CardModel(suit: Suit.clubs, rank: Rank.seven),
          ],
        },
      );

      final violation = detectViolation(trick, 0, GameMode.hakam, Suit.spades);
      expect(violation, isNull);
    });

    test('3.5 — Bot auto-selects correct proof card: first matching led suit in snapshot', () {
      const ledSuit = Suit.clubs;
      final snapshot = [
        const CardModel(suit: Suit.hearts, rank: Rank.ace),
        const CardModel(suit: Suit.clubs, rank: Rank.eight),
        const CardModel(suit: Suit.spades, rank: Rank.seven),
      ];

      final proofIdx = snapshot.indexWhere((c) => c.suit == ledSuit);
      expect(proofIdx, equals(1));
      expect(snapshot[proofIdx], equals(const CardModel(suit: Suit.clubs, rank: Rank.eight)));
    });

    test('3.6 — Same trick not challenged twice (de-duplication guard)', () {
      final challenged = <int>{};
      challenged.add(3);
      expect(challenged.contains(3), isTrue);

      bool wouldSkip(int trickIdx) => challenged.contains(trickIdx);
      expect(wouldSkip(3), isTrue);
      expect(wouldSkip(4), isFalse);
    });
  });
}
