import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/features/game/domain/managers/turn_manager.dart';

void main() {
  group('Sun trick evaluation', () {
    test('highest card of leading suit wins', () {
      final tm = TurnManager(
        mode: GameMode.sun,
        firstPlayerIndex: 0,
      );

      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.ten)); // lead
      tm.playCard(3, const CardModel(suit: Suit.hearts, rank: Rank.ace)); // highest
      tm.playCard(2, const CardModel(suit: Suit.hearts, rank: Rank.seven));
      final result = tm.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.king));

      expect(result, isNotNull);
      expect(result!.winnerIndex, 3); // Ace of hearts wins
    });

    test('off-suit card cannot win in Sun', () {
      final tm = TurnManager(
        mode: GameMode.sun,
        firstPlayerIndex: 0,
      );

      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.seven)); // lead hearts
      tm.playCard(3, const CardModel(suit: Suit.spades, rank: Rank.ace)); // off-suit ace
      tm.playCard(2, const CardModel(suit: Suit.hearts, rank: Rank.ten));
      final result = tm.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.eight));

      expect(result!.winnerIndex, 2); // 10 of hearts wins, not ace of spades
    });
  });

  group('Hakam trick evaluation', () {
    test('trump beats higher non-trump card', () {
      final tm = TurnManager(
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        firstPlayerIndex: 0,
      );

      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.ace)); // lead
      tm.playCard(3, const CardModel(suit: Suit.spades, rank: Rank.seven)); // low trump
      tm.playCard(2, const CardModel(suit: Suit.hearts, rank: Rank.king));
      final result = tm.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.ten));

      expect(result!.winnerIndex, 3); // 7 of trump beats ace of hearts
    });

    test('higher trump beats lower trump', () {
      final tm = TurnManager(
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        firstPlayerIndex: 0,
      );

      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.ten)); // lead
      tm.playCard(3, const CardModel(suit: Suit.spades, rank: Rank.seven)); // low trump
      tm.playCard(2, const CardModel(suit: Suit.spades, rank: Rank.jack)); // J trump (highest)
      final result = tm.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.ace));

      expect(result!.winnerIndex, 2); // Jack of trump beats 7 of trump
    });

    test('no trump played → highest of leading suit wins', () {
      final tm = TurnManager(
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        firstPlayerIndex: 0,
      );

      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.seven));
      tm.playCard(3, const CardModel(suit: Suit.hearts, rank: Rank.ace));
      tm.playCard(2, const CardModel(suit: Suit.hearts, rank: Rank.king));
      final result = tm.playCard(1, const CardModel(suit: Suit.clubs, rank: Rank.ace));

      expect(result!.winnerIndex, 3); // Ace of hearts (leading suit)
    });

    test('trump J > trump 9 > trump A (Hakam ranking)', () {
      final tm = TurnManager(
        mode: GameMode.hakam,
        trumpSuit: Suit.diamonds,
        firstPlayerIndex: 0,
      );

      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.seven));
      tm.playCard(3, const CardModel(suit: Suit.diamonds, rank: Rank.ace));
      tm.playCard(2, const CardModel(suit: Suit.diamonds, rank: Rank.jack)); // strongest
      final result = tm.playCard(1, const CardModel(suit: Suit.diamonds, rank: Rank.nine));

      expect(result!.winnerIndex, 2); // Jack of trump is strongest in Hakam
    });
  });

  group('Abnat calculation', () {
    test('trick Abnat sums card point values', () {
      final tm = TurnManager(
        mode: GameMode.sun,
        firstPlayerIndex: 0,
      );

      // Sun points: Ace=11, Ten=10, King=4, Seven=0
      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.ace));
      tm.playCard(3, const CardModel(suit: Suit.hearts, rank: Rank.ten));
      tm.playCard(2, const CardModel(suit: Suit.hearts, rank: Rank.king));
      final result = tm.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.seven));

      expect(result!.abnat, 25); // 11+10+4+0
    });

    test('Hakam trick: trump cards use Hakam point values', () {
      final tm = TurnManager(
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        firstPlayerIndex: 0,
      );

      // Spades (trump): Jack=20, Nine=14; Hearts (non-trump): Ace=11, Ten=10
      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.ace));
      tm.playCard(3, const CardModel(suit: Suit.spades, rank: Rank.jack));
      tm.playCard(2, const CardModel(suit: Suit.hearts, rank: Rank.ten));
      final result = tm.playCard(1, const CardModel(suit: Suit.spades, rank: Rank.nine));

      expect(result!.abnat, 55); // 11+20+10+14
    });
  });

  group('Last trick bonus', () {
    test('trick 8 gives +10 last trick bonus', () {
      final tm = TurnManager(
        mode: GameMode.sun,
        firstPlayerIndex: 0,
      );

      // Play 7 tricks with minimal cards
      for (int trick = 0; trick < 7; trick++) {
        for (int i = 0; i < 4; i++) {
          final suit = Suit.values[trick % 4];
          final rank = Rank.values[i];
          tm.playCard(tm.currentPlayerIndex, CardModel(suit: suit, rank: rank));
        }
      }

      expect(tm.trickNumber, 8);

      // Trick 8
      tm.playCard(tm.currentPlayerIndex,
          const CardModel(suit: Suit.clubs, rank: Rank.seven));
      tm.playCard(tm.currentPlayerIndex,
          const CardModel(suit: Suit.clubs, rank: Rank.eight));
      tm.playCard(tm.currentPlayerIndex,
          const CardModel(suit: Suit.clubs, rank: Rank.nine));
      final result = tm.playCard(tm.currentPlayerIndex,
          const CardModel(suit: Suit.clubs, rank: Rank.ten));

      expect(result!.isLastTrick, true);
      expect(result.lastTrickBonus, 10);
    });
  });

  group('Kabout detection', () {
    test('one team wins all 8 tricks → Kabout', () {
      // Set up so seat 0 (Team A) always wins by leading with Ace
      final tm = TurnManager(
        mode: GameMode.sun,
        firstPlayerIndex: 0,
      );

      // Play 8 tricks where seat 0 always leads and wins
      for (int trick = 0; trick < 8; trick++) {
        final suit = Suit.values[trick % 4];
        // Seat 0 plays Ace (highest)
        tm.playCard(0, CardModel(suit: suit, rank: Rank.ace));
        tm.playCard(3, CardModel(suit: suit, rank: Rank.seven));
        tm.playCard(2, CardModel(suit: suit, rank: Rank.eight));
        tm.playCard(1, CardModel(suit: suit, rank: Rank.nine));
        // Winner is seat 0 (Team A) every time
      }

      expect(tm.isRoundComplete, true);
      expect(tm.isKabout, true);
      expect(tm.kaboutTeam, 'A');
      expect(tm.teamATricksWon.length, 8);
      expect(tm.teamBTricksWon.length, 0);
    });

    test('mixed trick wins → no Kabout', () {
      final tm = TurnManager(
        mode: GameMode.sun,
        firstPlayerIndex: 0,
      );

      // Trick 1: seat 0 wins (Team A)
      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.ace));
      tm.playCard(3, const CardModel(suit: Suit.hearts, rank: Rank.seven));
      tm.playCard(2, const CardModel(suit: Suit.hearts, rank: Rank.eight));
      tm.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.nine));

      // Trick 2: seat 1 wins (Team B)
      tm.playCard(0, const CardModel(suit: Suit.spades, rank: Rank.seven));
      tm.playCard(3, const CardModel(suit: Suit.spades, rank: Rank.ace));
      tm.playCard(2, const CardModel(suit: Suit.spades, rank: Rank.eight));
      tm.playCard(1, const CardModel(suit: Suit.spades, rank: Rank.nine));

      // After 2 tricks, both teams have won at least 1
      expect(tm.teamATricksWon.length, 1);
      expect(tm.teamBTricksWon.length, 1);
    });
  });

  group('Turn advancement', () {
    test('winner of trick leads next trick', () {
      final tm = TurnManager(
        mode: GameMode.sun,
        firstPlayerIndex: 0,
      );

      // Seat 3 wins with Ace
      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.seven));
      tm.playCard(3, const CardModel(suit: Suit.hearts, rank: Rank.ace));
      tm.playCard(2, const CardModel(suit: Suit.hearts, rank: Rank.eight));
      tm.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.nine));

      // Next trick should start with seat 3
      expect(tm.currentPlayerIndex, 3);
    });
  });
}
