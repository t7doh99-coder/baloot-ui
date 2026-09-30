import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/card_play_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/managers/turn_manager.dart';
import 'package:baloot_game/features/game/domain/models/qaydha_models.dart';
import 'package:baloot_game/features/game/domain/engines/qaydha_engine.dart';

TrickResult _makeTrick({
  required List<CardPlayModel> cards,
  required Map<int, List<CardModel>> hands,
  int winnerIndex = 0,
}) {
  return TrickResult(
    winnerIndex: winnerIndex,
    abnat: 0,
    isLastTrick: false,
    lastTrickBonus: 0,
    cards: cards,
    handsAtStartOfTrick: hands,
  );
}

QaydhaViolationType? detectViolation({
  required TrickResult trick,
  required int accusedSeat,
  required GameMode mode,
  Suit? trump,
  DoubleStatus doubleStatus = DoubleStatus.none,
}) {
  final history = [trick];
  final typesToCheck = [
    QaydhaViolationType.qate,
    if (mode == GameMode.hakam) QaydhaViolationType.maDaqBiHakam,
    if (mode == GameMode.hakam) QaydhaViolationType.maKabbarBiHakam,
    if (mode == GameMode.hakam && doubleStatus != DoubleStatus.none)
      QaydhaViolationType.rubFiAlDubl,
  ];
  for (final type in typesToCheck) {
    try {
      final result = QaydhaEngine.evaluateChallenge(
        history: history,
        challengerIndex: 0,
        trickIndex: 0,
        accusedSeatIndex: accusedSeat,
        violationType: type,
        gameMode: mode,
        trumpSuit: trump,
        doubleStatus: doubleStatus,
      );
      if (result.isCorrect) return type;
    } catch (_) {
      continue;
    }
  }
  return null;
}

void main() {
  group('Bot Qaydha Detection', () {
    group('1. Qate', () {
      test('1.1 Human plays wrong suit but held led suit => Qate', () {
        final trick = _makeTrick(
          cards: [
            const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.clubs, rank: Rank.king)),
            const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.hearts, rank: Rank.ace)),
          ],
          hands: {
            0: [
              const CardModel(suit: Suit.clubs, rank: Rank.eight),
              const CardModel(suit: Suit.hearts, rank: Rank.ace),
            ],
          },
        );
        expect(detectViolation(trick: trick, accusedSeat: 0, mode: GameMode.hakam, trump: Suit.spades),
            equals(QaydhaViolationType.qate));
      });

      test('1.2 Human void in led suit => Legal', () {
        final trick = _makeTrick(
          cards: [
            const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.clubs, rank: Rank.king)),
            const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.hearts, rank: Rank.ace)),
          ],
          hands: {
            0: [
              const CardModel(suit: Suit.hearts, rank: Rank.ace),
              const CardModel(suit: Suit.diamonds, rank: Rank.seven),
            ],
          },
        );
        expect(detectViolation(trick: trick, accusedSeat: 0, mode: GameMode.hakam, trump: Suit.spades), isNull);
      });
    });

    group('2. Ma Daq Bi Hakam', () {
      test('2.1 Void in led suit, has trumps, plays off-suit => MaDaq', () {
        final trick = _makeTrick(
          cards: [
            const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.diamonds, rank: Rank.ace)),
            const CardPlayModel(playerIndex: 2, card: CardModel(suit: Suit.diamonds, rank: Rank.ten)),
            const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.clubs, rank: Rank.seven)),
          ],
          hands: {
            0: [
              const CardModel(suit: Suit.spades, rank: Rank.jack),
              const CardModel(suit: Suit.clubs, rank: Rank.seven),
            ],
          },
        );
        expect(detectViolation(trick: trick, accusedSeat: 0, mode: GameMode.hakam, trump: Suit.spades),
            equals(QaydhaViolationType.maDaqBiHakam));
      });

      test('2.2 Partner winning => Qabalak exemption => Legal', () {
        final trick = _makeTrick(
          cards: [
            const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.diamonds, rank: Rank.ace)),
            const CardPlayModel(playerIndex: 2, card: CardModel(suit: Suit.spades, rank: Rank.jack)),
            const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.clubs, rank: Rank.seven)),
          ],
          hands: {
            0: [
              const CardModel(suit: Suit.spades, rank: Rank.seven),
              const CardModel(suit: Suit.clubs, rank: Rank.seven),
            ],
          },
        );
        expect(detectViolation(trick: trick, accusedSeat: 0, mode: GameMode.hakam, trump: Suit.spades), isNull);
      });
    });

    group('3. Ma Kabbar Bi Hakam', () {
      test('3.1 Played low trump when held higher trump => MaKabbar', () {
        final trick = _makeTrick(
          cards: [
            const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.hearts, rank: Rank.ace)),
            const CardPlayModel(playerIndex: 3, card: CardModel(suit: Suit.spades, rank: Rank.ten)),
            const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.spades, rank: Rank.seven)),
          ],
          hands: {
            0: [
              const CardModel(suit: Suit.spades, rank: Rank.jack),
              const CardModel(suit: Suit.spades, rank: Rank.seven),
            ],
          },
        );
        expect(detectViolation(trick: trick, accusedSeat: 0, mode: GameMode.hakam, trump: Suit.spades),
            equals(QaydhaViolationType.maKabbarBiHakam));
      });
    });

    group('4. Rub Fi Al-Dubl', () {
      test('4.1 Human leads trump during closed double => Violation', () {
        final trick = _makeTrick(
          cards: [
            const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.spades, rank: Rank.jack)),
            const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.spades, rank: Rank.ten)),
          ],
          hands: {
            0: [
              const CardModel(suit: Suit.spades, rank: Rank.jack),
              const CardModel(suit: Suit.hearts, rank: Rank.seven),
            ],
          },
        );
        expect(detectViolation(trick: trick, accusedSeat: 0, mode: GameMode.hakam,
            trump: Suit.spades, doubleStatus: DoubleStatus.doubled),
            equals(QaydhaViolationType.rubFiAlDubl));
      });

      test('4.2 No double active => No RubFiAlDubl check', () {
        final trick = _makeTrick(
          cards: [
            const CardPlayModel(playerIndex: 0, card: CardModel(suit: Suit.spades, rank: Rank.jack)),
            const CardPlayModel(playerIndex: 1, card: CardModel(suit: Suit.spades, rank: Rank.ten)),
          ],
          hands: {
            0: [const CardModel(suit: Suit.spades, rank: Rank.jack)],
          },
        );
        expect(detectViolation(trick: trick, accusedSeat: 0, mode: GameMode.hakam,
            trump: Suit.spades, doubleStatus: DoubleStatus.none), isNull);
      });
    });

    group('5. Proof card auto-selection logic', () {
      test('5.1 Qate: finds first card matching led suit in snapshot', () {
        final snapshot = [
          const CardModel(suit: Suit.spades, rank: Rank.seven),
          const CardModel(suit: Suit.clubs, rank: Rank.eight),
          const CardModel(suit: Suit.hearts, rank: Rank.nine),
        ];
        const ledSuit = Suit.clubs;
        final proofIdx = snapshot.indexWhere((c) => c.suit == ledSuit);
        expect(proofIdx, equals(1));
      });

      test('5.2 MaDaq: finds any trump card in snapshot', () {
        final snapshot = [
          const CardModel(suit: Suit.hearts, rank: Rank.ace),
          const CardModel(suit: Suit.spades, rank: Rank.jack),
          const CardModel(suit: Suit.clubs, rank: Rank.seven),
        ];
        const trump = Suit.spades;
        final proofIdx = snapshot.indexWhere((c) => c.suit == trump);
        expect(proofIdx, equals(1));
      });

      test('5.3 MaKabbar: finds trump stronger than highest already played', () {
        final snapshot = [
          const CardModel(suit: Suit.spades, rank: Rank.seven),
          const CardModel(suit: Suit.spades, rank: Rank.jack),
          const CardModel(suit: Suit.hearts, rank: Rank.ace),
        ];
        const mode = GameMode.hakam;
        const trump = Suit.spades;
        const played = CardModel(suit: Suit.spades, rank: Rank.ten);
        final threshold = played.getStrength(mode: mode, trumpSuit: trump);
        final proofIdx = snapshot.indexWhere((c) =>
            c.suit == trump && c.getStrength(mode: mode, trumpSuit: trump) > threshold);
        expect(proofIdx, equals(1));
        expect(snapshot[proofIdx].rank, equals(Rank.jack));
      });
    });
  });
}
