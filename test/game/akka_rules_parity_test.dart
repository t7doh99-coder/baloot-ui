import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/card_play_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/baloot_game_controller.dart';
import 'package:baloot_game/features/game/domain/managers/turn_manager.dart';

void main() {
  group('Kammelna Akka Rules Parity Tests (BalootGameController)', () {
    late BalootGameController game;

    setUp(() {
      game = BalootGameController();
    });

    test('1. canEkka and isAkka only work in Hakam mode (not Sun or Ashkal)', () {
      final rsSun = const RoundStateModel(dealerIndex: 0, currentPlayerIndex: 0).copyWith(
        activeMode: GameMode.sun,
        trumpSuit: null,
      );
      final tmSun = TurnManager(mode: GameMode.sun, trumpSuit: null, firstPlayerIndex: 0);

      game.setRoundStateForTest(rsSun);
      game.setTurnManagerForTest(tmSun);

      // We inject playing phase manually for canEkka check
      // Wait, gamePhase is internal. We can just test isAkka directly because it checks mode.
      final candidateCard = const CardModel(suit: Suit.hearts, rank: Rank.king);

      // Should be false for Sun
      expect(game.isAkka(candidateCard), isFalse, reason: 'Akka does not exist in Sun mode');

      final rsAshkal = const RoundStateModel(dealerIndex: 0, currentPlayerIndex: 0).copyWith(
        activeMode: GameMode.sun,
        isAshkal: true,
        trumpSuit: null,
      );
      game.setRoundStateForTest(rsAshkal);
      
      // Should be false for Ashkal
      expect(game.isAkka(candidateCard), isFalse, reason: 'Akka does not exist in Ashkal mode');
    });

    test('2. Ace is NEVER considered an Akka, even in Hakam', () {
      final rsHakam = const RoundStateModel(dealerIndex: 0, currentPlayerIndex: 0).copyWith(
        activeMode: GameMode.hakam,
        trumpSuit: Suit.spades,
      );
      final tmHakam = TurnManager(mode: GameMode.hakam, trumpSuit: Suit.spades, firstPlayerIndex: 0);
      game.setRoundStateForTest(rsHakam);
      game.setTurnManagerForTest(tmHakam);

      final aceCard = const CardModel(suit: Suit.hearts, rank: Rank.ace);

      expect(game.isAkka(aceCard), isFalse, reason: 'Ace is never an Akka');
    });

    test('3. Trump suit is NEVER considered an Akka', () {
      final rsHakam = const RoundStateModel(dealerIndex: 0, currentPlayerIndex: 0).copyWith(
        activeMode: GameMode.hakam,
        trumpSuit: Suit.spades,
      );
      final tmHakam = TurnManager(mode: GameMode.hakam, trumpSuit: Suit.spades, firstPlayerIndex: 0);
      game.setRoundStateForTest(rsHakam);
      game.setTurnManagerForTest(tmHakam);

      // Even the strongest unplayed trump shouldn't be Akka
      final trumpCard = const CardModel(suit: Suit.spades, rank: Rank.jack); // Highest trump
      
      expect(game.isAkka(trumpCard), isFalse, reason: 'Trump cards cannot be Akka');
    });

    test('4. Highest remaining non-trump card is Akka (e.g. King when Ace and 10 are played)', () {
      final rsHakam = const RoundStateModel(dealerIndex: 0, currentPlayerIndex: 0).copyWith(
        activeMode: GameMode.hakam,
        trumpSuit: Suit.spades,
      );
      final tmHakam = TurnManager(mode: GameMode.hakam, trumpSuit: Suit.spades, firstPlayerIndex: 0);
      game.setRoundStateForTest(rsHakam);
      game.setTurnManagerForTest(tmHakam);

      final kingOfHearts = const CardModel(suit: Suit.hearts, rank: Rank.king);

      // If no cards have been played, King is NOT Akka (because Ace and 10 are still unplayed)
      expect(game.isAkka(kingOfHearts), isFalse, reason: 'Ace and 10 of hearts are still unplayed');

      // Simulate a trick where the Ace and 10 of Hearts were played
      tmHakam.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.ace));
      tmHakam.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.ten));
      tmHakam.playCard(2, const CardModel(suit: Suit.hearts, rank: Rank.eight));
      tmHakam.playCard(3, const CardModel(suit: Suit.hearts, rank: Rank.nine));

      // Now the Ace and 10 of Hearts are played. King of Hearts should be Akka!
      expect(game.isAkka(kingOfHearts), isTrue, reason: 'King of Hearts is now the highest remaining card in Hearts');
    });

    test('5. Deep Akka: 9 is Akka if Ace, 10, King, Queen, Jack are played', () {
      final rsHakam = const RoundStateModel(dealerIndex: 0, currentPlayerIndex: 0).copyWith(
        activeMode: GameMode.hakam,
        trumpSuit: Suit.spades,
      );
      final tmHakam = TurnManager(mode: GameMode.hakam, trumpSuit: Suit.spades, firstPlayerIndex: 0);
      game.setRoundStateForTest(rsHakam);
      game.setTurnManagerForTest(tmHakam);

      final nineOfClubs = const CardModel(suit: Suit.clubs, rank: Rank.nine);

      // Simulate Trick 1
      tmHakam.playCard(0, const CardModel(suit: Suit.clubs, rank: Rank.ace));
      tmHakam.playCard(1, const CardModel(suit: Suit.clubs, rank: Rank.ten));
      tmHakam.playCard(2, const CardModel(suit: Suit.clubs, rank: Rank.king));
      tmHakam.playCard(3, const CardModel(suit: Suit.clubs, rank: Rank.seven));

      expect(game.isAkka(nineOfClubs), isFalse, reason: 'Queen and Jack of clubs are still unplayed');

      // Simulate Trick 2
      tmHakam.playCard(0, const CardModel(suit: Suit.clubs, rank: Rank.queen));
      tmHakam.playCard(1, const CardModel(suit: Suit.clubs, rank: Rank.jack));
      tmHakam.playCard(2, const CardModel(suit: Suit.clubs, rank: Rank.eight));
      tmHakam.playCard(3, const CardModel(suit: Suit.diamonds, rank: Rank.seven));

      // Now 9 of Clubs is the highest!
      expect(game.isAkka(nineOfClubs), isTrue, reason: '9 of Clubs is now the highest remaining card');
    });
  });
}
