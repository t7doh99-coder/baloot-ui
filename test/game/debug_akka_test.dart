import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/card_play_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/baloot_game_controller.dart';
import 'package:baloot_game/features/game/domain/managers/turn_manager.dart';

void main() {
  test('Debug isAkka on Trick 8 4th card', () {
    final game = BalootGameController();
    final tm = TurnManager(mode: GameMode.hakam, trumpSuit: Suit.clubs, firstPlayerIndex: 0);
    game.setRoundStateForTest(const RoundStateModel(dealerIndex: 0, currentPlayerIndex: 0).copyWith(activeMode: GameMode.hakam, trumpSuit: Suit.clubs));
    game.setTurnManagerForTest(tm);

    // Add 7 tricks
    for(int i=0; i<7; i++) {
       tm.playCard(0, CardModel(suit: Suit.spades, rank: Rank.ace));
       tm.playCard(1, CardModel(suit: Suit.spades, rank: Rank.ten));
       tm.playCard(2, CardModel(suit: Suit.spades, rank: Rank.king));
       tm.playCard(3, CardModel(suit: Suit.spades, rank: Rank.queen));
    }

    // Trick 8
    tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.nine));
    tm.playCard(1, const CardModel(suit: Suit.diamonds, rank: Rank.eight));
    tm.playCard(2, const CardModel(suit: Suit.hearts, rank: Rank.king));
    tm.playCard(3, const CardModel(suit: Suit.diamonds, rank: Rank.ten)); // Seat 3 plays 10♦

    final tenDiamonds = const CardModel(suit: Suit.diamonds, rank: Rank.ten);
    final result = game.isAkka(tenDiamonds);
    print('isAkka for 10♦ returned: $result');
    print('trickNumber: ${tm.trickNumber}');
    print('isLeadCard in last trick: ${tm.trickHistory.last.cards.first.card == tenDiamonds}');
    print('isInLastTrick: ${tm.trickHistory.last.cards.any((p) => p.card == tenDiamonds)}');
  });
}
