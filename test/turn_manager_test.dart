import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/features/game/domain/managers/turn_manager.dart';

void main() {
  group('Module D: TurnManager', () {
    group('D1-D2: Card Strength', () {
      test('Standard strength: A > 10 > K > Q > J > 9 > 8 > 7', () {
        final strengths = [
          const CardModel(suit: Suit.hearts, rank: Rank.seven).getStrength(mode: GameMode.sun),
          const CardModel(suit: Suit.hearts, rank: Rank.eight).getStrength(mode: GameMode.sun),
          const CardModel(suit: Suit.hearts, rank: Rank.nine).getStrength(mode: GameMode.sun),
          const CardModel(suit: Suit.hearts, rank: Rank.jack).getStrength(mode: GameMode.sun),
          const CardModel(suit: Suit.hearts, rank: Rank.queen).getStrength(mode: GameMode.sun),
          const CardModel(suit: Suit.hearts, rank: Rank.king).getStrength(mode: GameMode.sun),
          const CardModel(suit: Suit.hearts, rank: Rank.ten).getStrength(mode: GameMode.sun),
          const CardModel(suit: Suit.hearts, rank: Rank.ace).getStrength(mode: GameMode.sun),
        ];
        for (int i = 1; i < strengths.length; i++) {
          expect(strengths[i] > strengths[i - 1], true,
              reason: 'Standard strength should increase');
        }
      });

      test('Hakam trump strength: J > 9 > A > 10 > K > Q > 8 > 7', () {
        const trump = Suit.spades;
        final j = const CardModel(suit: trump, rank: Rank.jack).getStrength(mode: GameMode.hakam, trumpSuit: trump);
        final n = const CardModel(suit: trump, rank: Rank.nine).getStrength(mode: GameMode.hakam, trumpSuit: trump);
        final a = const CardModel(suit: trump, rank: Rank.ace).getStrength(mode: GameMode.hakam, trumpSuit: trump);
        final t = const CardModel(suit: trump, rank: Rank.ten).getStrength(mode: GameMode.hakam, trumpSuit: trump);
        expect(j > n, true);
        expect(n > a, true);
        expect(a > t, true);
      });
    });

    group('D3-D5: Trick Winner', () {
      test('Sun: highest of leading suit wins', () {
        final tm = TurnManager(mode: GameMode.sun, firstPlayerIndex: 0);
        tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.ten));
        tm.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.ace));
        tm.playCard(2, const CardModel(suit: Suit.spades, rank: Rank.ace)); // off-suit
        final result = tm.playCard(3, const CardModel(suit: Suit.hearts, rank: Rank.king));
        expect(result, isNotNull);
        expect(result!.winnerIndex, 1); // Ace of hearts wins
      });

      test('Hakam: trump beats non-trump', () {
        final tm = TurnManager(mode: GameMode.hakam, trumpSuit: Suit.clubs, firstPlayerIndex: 0);
        tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.ace)); // lead
        tm.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.ten));
        tm.playCard(2, const CardModel(suit: Suit.clubs, rank: Rank.seven)); // trump 7
        final result = tm.playCard(3, const CardModel(suit: Suit.hearts, rank: Rank.king));
        expect(result!.winnerIndex, 2); // Trump 7 beats non-trump Ace
      });

      test('Hakam: highest trump wins among multiple trumps', () {
        final tm = TurnManager(mode: GameMode.hakam, trumpSuit: Suit.clubs, firstPlayerIndex: 0);
        tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.ace)); // lead
        tm.playCard(1, const CardModel(suit: Suit.clubs, rank: Rank.eight)); // trump 8
        tm.playCard(2, const CardModel(suit: Suit.clubs, rank: Rank.jack)); // trump J (highest)
        final result = tm.playCard(3, const CardModel(suit: Suit.clubs, rank: Rank.nine)); // trump 9
        expect(result!.winnerIndex, 2); // Trump J wins
      });
    });

    group('D6-D7: Card Point Values', () {
      test('Standard point values correct', () {
        expect(const CardModel(suit: Suit.hearts, rank: Rank.seven).getPointValue(mode: GameMode.sun), 0);
        expect(const CardModel(suit: Suit.hearts, rank: Rank.eight).getPointValue(mode: GameMode.sun), 0);
        expect(const CardModel(suit: Suit.hearts, rank: Rank.nine).getPointValue(mode: GameMode.sun), 0);
        expect(const CardModel(suit: Suit.hearts, rank: Rank.jack).getPointValue(mode: GameMode.sun), 2);
        expect(const CardModel(suit: Suit.hearts, rank: Rank.queen).getPointValue(mode: GameMode.sun), 3);
        expect(const CardModel(suit: Suit.hearts, rank: Rank.king).getPointValue(mode: GameMode.sun), 4);
        expect(const CardModel(suit: Suit.hearts, rank: Rank.ten).getPointValue(mode: GameMode.sun), 10);
        expect(const CardModel(suit: Suit.hearts, rank: Rank.ace).getPointValue(mode: GameMode.sun), 11);
      });

      test('Hakam trump point values correct', () {
        const trump = Suit.spades;
        expect(const CardModel(suit: trump, rank: Rank.jack).getPointValue(mode: GameMode.hakam, trumpSuit: trump), 20);
        expect(const CardModel(suit: trump, rank: Rank.nine).getPointValue(mode: GameMode.hakam, trumpSuit: trump), 14);
        expect(const CardModel(suit: trump, rank: Rank.ace).getPointValue(mode: GameMode.hakam, trumpSuit: trump), 11);
      });

      test('Sun total = 130 (120 cards + 10 ground)', () {
        int total = 0;
        for (final suit in Suit.values) {
          for (final rank in Rank.values) {
            total += CardModel(suit: suit, rank: rank).getPointValue(mode: GameMode.sun);
          }
        }
        expect(total, 120); // Without ground
        expect(total + 10, 130); // With ground
      });

      test('Hakam total = 162 (152 cards + 10 ground)', () {
        const trump = Suit.hearts;
        int total = 0;
        for (final suit in Suit.values) {
          for (final rank in Rank.values) {
            total += CardModel(suit: suit, rank: rank).getPointValue(mode: GameMode.hakam, trumpSuit: trump);
          }
        }
        expect(total, 152); // Without ground
        expect(total + 10, 162); // With ground
      });
    });

    group('D8: Ground Bonus', () {
      test('Only trick 8 gets +10 abnat', () {
        final tm = TurnManager(mode: GameMode.sun, firstPlayerIndex: 0);
        // Play 7 tricks with zero-value cards
        for (int trick = 0; trick < 7; trick++) {
          for (int p = 0; p < 4; p++) {
            final suit = Suit.values[trick % 4];
            final rank = Rank.values[p];
            tm.playCard(tm.currentPlayerIndex, CardModel(suit: suit, rank: rank));
          }
        }
        // Trick 8 (last trick)
        tm.playCard(tm.currentPlayerIndex, const CardModel(suit: Suit.hearts, rank: Rank.seven));
        tm.playCard(tm.currentPlayerIndex, const CardModel(suit: Suit.hearts, rank: Rank.eight));
        tm.playCard(tm.currentPlayerIndex, const CardModel(suit: Suit.hearts, rank: Rank.nine));
        final result = tm.playCard(tm.currentPlayerIndex, const CardModel(suit: Suit.hearts, rank: Rank.jack));
        expect(result!.isLastTrick, true);
        expect(result.lastTrickBonus, 10);
      });
    });

    group('D9-D10: Round Completion & Kabout', () {
      test('Kabout detection', () {
        final tm = TurnManager(mode: GameMode.sun, firstPlayerIndex: 0);
        // We need one team to win ALL tricks.
        // Play 8 tricks where seat 0 always wins (seat 0 leads Ace each time)
        for (int trick = 0; trick < 8; trick++) {
          final suit = Suit.values[trick % 4];
          tm.playCard(0, CardModel(suit: suit, rank: Rank.ace)); // Lead Ace (seat 0 wins)
          tm.playCard(1, CardModel(suit: suit, rank: Rank.seven));
          tm.playCard(2, CardModel(suit: suit, rank: Rank.eight));
          tm.playCard(3, CardModel(suit: suit, rank: Rank.nine));
        }
        expect(tm.isRoundComplete, true);
        expect(tm.isKabout, true);
        expect(tm.kaboutTeam, 'A'); // Seat 0 is Team A
      });
    });
  });
}
