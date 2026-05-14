import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/features/game/domain/engines/sawa_probability_engine.dart';

void main() {
  group('Module G: SawaProbabilityEngine', () {
    group('G1: All Master Cards', () {
      test('All top cards in Sun → can Sawa', () {
        final hand = [
          const CardModel(suit: Suit.hearts, rank: Rank.ace),
          const CardModel(suit: Suit.spades, rank: Rank.ace),
        ];
        // Mark all higher cards as played (none exist above Ace)
        final played = <CardModel>[];
        final result = SawaProbabilityEngine.canSawaYad(
          playerSeat: 0,
          playerHand: hand,
          playedCards: played,
          mode: GameMode.sun,
          trumpSuit: null,
        );
        expect(result, true);
      });

      test('Card can be beaten → cannot Sawa', () {
        final hand = [
          const CardModel(suit: Suit.hearts, rank: Rank.king), // King, not Ace
        ];
        final played = <CardModel>[];
        final result = SawaProbabilityEngine.canSawaYad(
          playerSeat: 0,
          playerHand: hand,
          playedCards: played,
          mode: GameMode.sun,
          trumpSuit: null,
        );
        expect(result, false); // Ace is still out there
      });
    });

    group('G2: Hakam Trump Risk', () {
      test('Non-trump master but opponents may have trump → false', () {
        final hand = [
          const CardModel(suit: Suit.hearts, rank: Rank.ace),
        ];
        final played = <CardModel>[];
        final result = SawaProbabilityEngine.canSawaYad(
          playerSeat: 0,
          playerHand: hand,
          playedCards: played,
          mode: GameMode.hakam,
          trumpSuit: Suit.clubs,
        );
        expect(result, false); // Opponent might cut with trump
      });
    });

    group('G3: Played Cards Tracking', () {
      test('Higher cards played → lower becomes master', () {
        final hand = [
          const CardModel(suit: Suit.hearts, rank: Rank.king),
        ];
        final played = [
          const CardModel(suit: Suit.hearts, rank: Rank.ace), // Ace already played
        ];
        final result = SawaProbabilityEngine.canSawaYad(
          playerSeat: 0,
          playerHand: hand,
          playedCards: played,
          mode: GameMode.sun,
          trumpSuit: null,
        );
        // King is now the master of hearts since Ace is played
        // But 10 is also out there (10 is higher than K in standard... wait no)
        // Standard: A > 10 > K. So 10 beats K. 10 hasn't been played.
        expect(result, false); // 10 is still out
      });

      test('All higher cards played → true', () {
        final hand = [
          const CardModel(suit: Suit.hearts, rank: Rank.king),
        ];
        final played = [
          const CardModel(suit: Suit.hearts, rank: Rank.ace),
          const CardModel(suit: Suit.hearts, rank: Rank.ten),
        ];
        final result = SawaProbabilityEngine.canSawaYad(
          playerSeat: 0,
          playerHand: hand,
          playedCards: played,
          mode: GameMode.sun,
          trumpSuit: null,
        );
        expect(result, true); // King is now master
      });
    });
  });
}
