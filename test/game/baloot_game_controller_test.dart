import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/core/errors/game_exceptions.dart';
import 'package:baloot_game/features/game/domain/managers/bidding_manager.dart';
import 'package:baloot_game/features/game/domain/baloot_game_controller.dart';

void main() {
  group('Game lifecycle', () {
    test('startNewGame initializes 4 players and enters bidding', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['Alice', 'Bob', 'Charlie', 'Dave']);

      expect(ctrl.gamePhase, GamePhase.bidding);
      expect(ctrl.gameScore.teamA, 0);
      expect(ctrl.gameScore.teamB, 0);
      expect(ctrl.isGameOver, false);
    });

    test('requires exactly 4 players', () {
      final ctrl = BalootGameController();
      expect(
        () => ctrl.startNewGame(['A', 'B']),
        throwsA(isA<InvalidMoveException>()),
      );
    });
  });

  group('Bidding flow', () {
    test('bidding Hakam → transitions to double window → then play', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);

      final bidder = ctrl.roundState.currentPlayerIndex;

      // Bid Hakam
      ctrl.placeBid(bidder, BidAction.hakam);

      // Others pass
      for (int i = 0; i < 3; i++) {
        if (ctrl.gamePhase == GamePhase.bidding) {
          ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.pass);
        }
      }

      expect(ctrl.gamePhase, GamePhase.doubleWindow);
      expect(ctrl.roundState.activeMode, GameMode.hakam);

      // Skip double
      ctrl.skipDoubleWindow();
      expect(ctrl.gamePhase, GamePhase.playing);
    });

    test('all pass both rounds → new round with advanced dealer', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);

      final initialDealer = ctrl.roundState.dealerIndex;

      // All pass Round 1
      for (int i = 0; i < 4; i++) {
        ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.pass);
      }

      // All pass Round 2 → auto-starts new round
      for (int i = 0; i < 4; i++) {
        if (ctrl.gamePhase == GamePhase.bidding) {
          ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.pass);
        }
      }

      // Dealer should have advanced
      expect(ctrl.gamePhase, GamePhase.bidding);
      expect(ctrl.roundState.dealerIndex != initialDealer, true);
    });
  });

  group('Full round simulation', () {
    test('deal, bid Hakam, play 8 tricks via bot, score correctly', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);

      // Bid Hakam
      ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.hakam);
      while (ctrl.gamePhase == GamePhase.bidding) {
        ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.pass);
      }

      // Skip double
      ctrl.skipDoubleWindow();
      expect(ctrl.gamePhase, GamePhase.playing);

      // All players have 8 cards
      for (int i = 0; i < 4; i++) {
        expect(ctrl.getHand(i).length, 8);
      }

      // Play all 8 tricks using bot logic
      int safetyCounter = 0;
      while (ctrl.gamePhase == GamePhase.playing && safetyCounter < 40) {
        ctrl.botPlay(ctrl.roundState.currentPlayerIndex);
        safetyCounter++;
      }

      // Round should be scored
      expect(
        ctrl.gamePhase == GamePhase.dealing || ctrl.gamePhase == GamePhase.gameOver,
        true,
        reason: 'Game should be in dealing (next round) or gameOver after 8 tricks',
      );

      // Score should have changed
      final score = ctrl.gameScore;
      expect(score.teamA + score.teamB > 0, true,
          reason: 'At least one team should have scored');
    });
  });

  group('Play validation', () {
    test('playing a card not in hand throws', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);

      // Bid Sun for simplicity
      ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.hakam);
      while (ctrl.gamePhase == GamePhase.bidding) {
        ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.pass);
      }
      ctrl.skipDoubleWindow();

      final currentSeat = ctrl.roundState.currentPlayerIndex;
      // Try to play a card we definitely don't have
      // (create an impossible card scenario)
      final hand = ctrl.getHand(currentSeat);
      // Find a card NOT in hand
      CardModel? notInHand;
      for (final suit in Suit.values) {
        for (final rank in Rank.values) {
          final card = CardModel(suit: suit, rank: rank);
          if (!hand.contains(card)) {
            notInHand = card;
            break;
          }
        }
        if (notInHand != null) break;
      }

      expect(
        () => ctrl.playCard(currentSeat, notInHand!),
        throwsA(isA<InvalidMoveException>()),
      );
    });

    test('playing out of turn throws', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);

      ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.hakam);
      while (ctrl.gamePhase == GamePhase.bidding) {
        ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.pass);
      }
      ctrl.skipDoubleWindow();

      final currentSeat = ctrl.roundState.currentPlayerIndex;
      final wrongSeat = (currentSeat + 1) % 4;
      final card = ctrl.getHand(wrongSeat).first;

      expect(
        () => ctrl.playCard(wrongSeat, card),
        throwsA(isA<InvalidMoveException>()),
      );
    });
  });

  group('Gahwa instant win', () {
    test('calling Gahwa ends the game', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);

      // Bid Hakam
      ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.hakam);
      while (ctrl.gamePhase == GamePhase.bidding) {
        ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.pass);
      }

      expect(ctrl.gamePhase, GamePhase.doubleWindow);

      // Find a defender (non-buyer) seat
      final buyerIndex = ctrl.roundState.buyerIndex!;
      final buyerIsTeamA = buyerIndex % 2 == 0;
      int defenderSeat;
      if (buyerIsTeamA) {
        defenderSeat = 1; // Team B
      } else {
        defenderSeat = 0; // Team A
      }

      ctrl.callDouble(defenderSeat, DoubleStatus.gahwa);

      expect(ctrl.isGameOver, true);
      expect(ctrl.gamePhase, GamePhase.gameOver);
    });
  });

  group('State snapshot', () {
    test('getGameState returns all reconnection data', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);

      final state = ctrl.getGameState();
      expect(state['gamePhase'], isNotNull);
      expect(state['playerNames'], hasLength(4));
      expect(state['teamAScore'], isNotNull);
      expect(state['teamBScore'], isNotNull);
      expect(state['hands'], hasLength(4));
      expect(state['roundState'], isNotNull);
    });
  });

  group('Multiple rounds', () {
    test('can play multiple rounds until game ends', () {
      final ctrl = BalootGameController(random: Random(42));
      ctrl.startNewGame(['A', 'B', 'C', 'D']);

      int roundCount = 0;
      const maxRounds = 50; // safety limit

      while (!ctrl.isGameOver && roundCount < maxRounds) {
        // Bidding: first player bids Hakam
        if (ctrl.gamePhase == GamePhase.bidding) {
          ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.hakam);
          while (ctrl.gamePhase == GamePhase.bidding) {
            ctrl.placeBid(ctrl.roundState.currentPlayerIndex, BidAction.pass);
          }
        }

        // Skip double
        if (ctrl.gamePhase == GamePhase.doubleWindow) {
          ctrl.skipDoubleWindow();
        }

        // Play round with bot
        int safety = 0;
        while (ctrl.gamePhase == GamePhase.playing && safety < 40) {
          ctrl.botPlay(ctrl.roundState.currentPlayerIndex);
          safety++;
        }

        // Start next round if needed
        if (ctrl.gamePhase == GamePhase.dealing) {
          ctrl.startNewRound();
        }

        roundCount++;
      }

      // Game should eventually end
      final score = ctrl.gameScore;
      expect(score.teamA >= 152 || score.teamB >= 152, true,
          reason: 'One team should reach 152 to end the game');
      expect(ctrl.isGameOver, true);
    });
  });
}
