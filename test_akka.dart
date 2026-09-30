import 'dart:math';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/baloot_game_controller.dart';
import 'package:baloot_game/features/game/domain/engines/bot_engine.dart';

void main() {
  print('--- Akka Fix Test Scenario ---');
  
  // Create controller
  final controller = BalootGameController(random: Random(42));
  controller.startNewGame(['Human', 'Bot1', 'Bot2', 'Bot3']);
  
  // 1. Force round start
  controller.startNewRound();
  
  // 2. Force bidding to end: Seat 1 buys Hakam Spades
  controller.bid(1, BiddingDecision.hakam(Suit.spades));
  controller.bid(2, BiddingDecision.pass());
  controller.bid(3, BiddingDecision.pass());
  controller.bid(0, BiddingDecision.pass());
  
  print('Game phase is now: ${controller.gamePhase}');
  
  // 3. Human's turn to lead.
  // We want to test if the NEXT player (Seat 1) will trigger Akka when playing 2nd.
  print('\nHuman (Seat 0) leads with 10 of Hearts...');
  final tenHearts = CardModel(suit: Suit.hearts, rank: Rank.ten);
  
  // We don't actually need the human to hold it in test, skip validation.
  controller.playCard(0, tenHearts, skipValidation: true);
  
  // 4. Now it's Bot 1 (Seat 1)'s turn.
  print('Is current trick empty? ${controller.canEkka(1) ? "Yes" : "No"} (canEkka = ${controller.canEkka(1)})');
  
  // Simulate the game provider logic for Seat 1
  final wasLeading = controller.canEkka(1);
  print('Seat 1 wasLeading = $wasLeading');
  
  print('\nBot 1 (Seat 1) plays King of Hearts...');
  final kingHearts = CardModel(suit: Suit.hearts, rank: Rank.king);
  controller.playCard(1, kingHearts, skipValidation: true);
  
  // Determine if bot would claim Akka
  final lastCard = kingHearts;
  final isAkkaMathematically = controller.isAkka(lastCard);
  final botClaimedEkka = controller.ekkaClaimSeat == 1;
  final didClaimAkka = botClaimedEkka || (wasLeading && isAkkaMathematically);
  
  print('Did the bot mathematically hold the highest remaining card? $isAkkaMathematically');
  print('Did the bot actually announce Akka? $didClaimAkka');
  
  if (didClaimAkka) {
    print('❌ BUG: Bot announced Akka incorrectly!');
  } else {
    print('✅ SUCCESS: Bot did NOT announce Akka because it was not leading the trick.');
  }
}
