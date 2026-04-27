import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/card_play_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/engines/bot_engine.dart';
import 'package:baloot_game/features/game/domain/managers/bidding_manager.dart';
import 'package:baloot_game/features/game/domain/baloot_game_controller.dart';

void main() {
  const bot = BotEngine();
  const buyerCard = CardModel(suit: Suit.hearts, rank: Rank.ten);

  group('Bidding — Round 1', () {
    test('bids Hakam with strong trump hand (J + 9 + A of trump)', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.jack),
        const CardModel(suit: Suit.hearts, rank: Rank.nine),
        const CardModel(suit: Suit.hearts, rank: Rank.ace),
        const CardModel(suit: Suit.spades, rank: Rank.seven),
        const CardModel(suit: Suit.diamonds, rank: Rank.eight),
      ];
      final decision = bot.decideBid(
        hand: hand,
        buyerCard: buyerCard,
        phase: BiddingPhase.round1,
        seatIndex: 1,
        dealerIndex: 0,
      );
      expect(decision.action, BidAction.hakam);
    });

    test('passes with weak trump hand', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.spades, rank: Rank.ace),
        const CardModel(suit: Suit.diamonds, rank: Rank.king),
        const CardModel(suit: Suit.clubs, rank: Rank.queen),
        const CardModel(suit: Suit.clubs, rank: Rank.eight),
      ];
      final decision = bot.decideBid(
        hand: hand,
        buyerCard: buyerCard,
        phase: BiddingPhase.round1,
        seatIndex: 1,
        dealerIndex: 0,
      );
      expect(decision.action, BidAction.pass);
    });
  });

  group('Bidding — Round 2', () {
    test('bids Sun with multiple aces', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.ace),
        const CardModel(suit: Suit.spades, rank: Rank.ace),
        const CardModel(suit: Suit.diamonds, rank: Rank.ace),
        const CardModel(suit: Suit.clubs, rank: Rank.ten),
        const CardModel(suit: Suit.spades, rank: Rank.ten),
      ];
      final decision = bot.decideBid(
        hand: hand,
        buyerCard: buyerCard,
        phase: BiddingPhase.round2,
        seatIndex: 1,
        dealerIndex: 0,
      );
      expect(decision.action, BidAction.sun);
    });

    test('bids Second Hakam with strong off-suit', () {
      final hand = [
        const CardModel(suit: Suit.spades, rank: Rank.jack),
        const CardModel(suit: Suit.spades, rank: Rank.nine),
        const CardModel(suit: Suit.spades, rank: Rank.ace),
        const CardModel(suit: Suit.spades, rank: Rank.ten),
        const CardModel(suit: Suit.diamonds, rank: Rank.seven),
      ];
      final decision = bot.decideBid(
        hand: hand,
        buyerCard: buyerCard,
        phase: BiddingPhase.round2,
        seatIndex: 1,
        dealerIndex: 0,
      );
      expect(decision.action, BidAction.secondHakam);
      expect(decision.secondHakamSuit, Suit.spades);
    });

    test('passes with weak hand in Round 2', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.spades, rank: Rank.eight),
        const CardModel(suit: Suit.diamonds, rank: Rank.seven),
        const CardModel(suit: Suit.clubs, rank: Rank.eight),
        const CardModel(suit: Suit.hearts, rank: Rank.eight),
      ];
      final decision = bot.decideBid(
        hand: hand,
        buyerCard: buyerCard,
        phase: BiddingPhase.round2,
        seatIndex: 1,
        dealerIndex: 0,
      );
      expect(decision.action, BidAction.pass);
    });

    test('Round 2 reaction: passes when another bid is pending', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.ace),
        const CardModel(suit: Suit.spades, rank: Rank.ace),
        const CardModel(suit: Suit.diamonds, rank: Rank.ace),
        const CardModel(suit: Suit.clubs, rank: Rank.ten),
        const CardModel(suit: Suit.spades, rank: Rank.ten),
      ];
      final decision = bot.decideBid(
        hand: hand,
        buyerCard: buyerCard,
        phase: BiddingPhase.round2,
        seatIndex: 2,
        dealerIndex: 0,
        round2PendingBid: true,
      );
      expect(decision.action, BidAction.pass);
    });
  });

  group('Card Play — Leading', () {
    test('leads with non-trump Ace in Hakam', () {
      final hand = [
        const CardModel(suit: Suit.spades, rank: Rank.ace),
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.diamonds, rank: Rank.eight),
      ];
      final card = bot.decidePlay(
        hand: hand,
        currentTrick: [],
        mode: GameMode.hakam,
        trumpSuit: Suit.hearts,
        doubleStatus: DoubleStatus.none,
        isOpenPlay: true,
        seatIndex: 0,
        trickNumber: 1,
        teamAAbnat: 0,
        teamBAbnat: 0,
        buyerIndex: 0,
      );
      expect(card.rank, Rank.ace);
      expect(card.suit, Suit.spades);
    });

    test('leads with Ace in Sun mode', () {
      final hand = [
        const CardModel(suit: Suit.clubs, rank: Rank.ace),
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.diamonds, rank: Rank.eight),
      ];
      final card = bot.decidePlay(
        hand: hand,
        currentTrick: [],
        mode: GameMode.sun,
        doubleStatus: DoubleStatus.none,
        isOpenPlay: true,
        seatIndex: 0,
        trickNumber: 1,
        teamAAbnat: 0,
        teamBAbnat: 0,
        buyerIndex: 0,
      );
      expect(card.rank, Rank.ace);
    });
  });

  group('Card Play — Following', () {
    test('plays lowest card when partner is winning', () {
      final hand = [
        const CardModel(suit: Suit.spades, rank: Rank.ace),
        const CardModel(suit: Suit.spades, rank: Rank.seven),
      ];
      final trick = [
        const CardPlayModel(
          card: CardModel(suit: Suit.spades, rank: Rank.ten),
          playerIndex: 2,
        ),
        const CardPlayModel(
          card: CardModel(suit: Suit.spades, rank: Rank.eight),
          playerIndex: 3,
        ),
      ];
      final card = bot.decidePlay(
        hand: hand,
        currentTrick: trick,
        mode: GameMode.sun,
        doubleStatus: DoubleStatus.none,
        isOpenPlay: true,
        seatIndex: 0,
        trickNumber: 2,
        teamAAbnat: 0,
        teamBAbnat: 0,
        buyerIndex: 0,
      );
      expect(card.rank, Rank.seven);
    });

    test('cuts with trump when void in lead suit and opponent winning', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.nine),
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.clubs, rank: Rank.eight),
      ];
      final trick = [
        const CardPlayModel(
          card: CardModel(suit: Suit.spades, rank: Rank.ace),
          playerIndex: 1,
        ),
      ];
      final card = bot.decidePlay(
        hand: hand,
        currentTrick: trick,
        mode: GameMode.hakam,
        trumpSuit: Suit.hearts,
        doubleStatus: DoubleStatus.none,
        isOpenPlay: true,
        seatIndex: 0,
        trickNumber: 2,
        teamAAbnat: 0,
        teamBAbnat: 0,
        buyerIndex: 0,
      );
      expect(card.suit, Suit.hearts);
      expect(card.rank, Rank.seven);
    });
  });

  group('Double Decision', () {
    test('doubles with strong defensive hand when trailing', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.jack),
        const CardModel(suit: Suit.hearts, rank: Rank.nine),
        const CardModel(suit: Suit.hearts, rank: Rank.ace),
        const CardModel(suit: Suit.hearts, rank: Rank.ten),
        const CardModel(suit: Suit.spades, rank: Rank.ace),
        const CardModel(suit: Suit.diamonds, rank: Rank.ace),
        const CardModel(suit: Suit.clubs, rank: Rank.king),
        const CardModel(suit: Suit.clubs, rank: Rank.seven),
      ];
      final result = bot.decideDouble(
        hand: hand,
        mode: GameMode.hakam,
        trumpSuit: Suit.hearts,
        ownScore: 40,
        opponentScore: 80,
      );
      expect(result, DoubleStatus.doubled);
    });

    test('skips double with weak hand', () {
      final hand = [
        const CardModel(suit: Suit.hearts, rank: Rank.seven),
        const CardModel(suit: Suit.spades, rank: Rank.eight),
        const CardModel(suit: Suit.diamonds, rank: Rank.seven),
        const CardModel(suit: Suit.clubs, rank: Rank.eight),
        const CardModel(suit: Suit.hearts, rank: Rank.eight),
        const CardModel(suit: Suit.spades, rank: Rank.seven),
        const CardModel(suit: Suit.diamonds, rank: Rank.eight),
        const CardModel(suit: Suit.clubs, rank: Rank.seven),
      ];
      final result = bot.decideDouble(
        hand: hand,
        mode: GameMode.hakam,
        trumpSuit: Suit.hearts,
        ownScore: 40,
        opponentScore: 80,
      );
      expect(result, isNull);
    });

    test('skips double in Sun mode', () {
      final result = bot.decideDouble(
        hand: const [CardModel(suit: Suit.hearts, rank: Rank.ace)],
        mode: GameMode.sun,
        ownScore: 40,
        opponentScore: 80,
      );
      expect(result, isNull);
    });
  });

  group('Full game simulation with bots', () {
    test('game completes without errors when all 4 players are bots', () {
      final controller = BalootGameController();
      controller.startNewGame(['Bot A', 'Bot B', 'Bot C', 'Bot D']);

      int safety = 0;
      while (!controller.isGameOver && safety < 5000) {
        final phase = controller.gamePhase;
        if (phase == GamePhase.notStarted || phase == GamePhase.gameOver) break;

        if (phase == GamePhase.dealing) {
          controller.startNewRound();
          continue;
        }

        final currentSeat = controller.roundState.currentPlayerIndex;
        controller.botPlay(currentSeat);
        safety++;
      }

      expect(controller.isGameOver, isTrue);
      expect(controller.gameWinner, isNotNull);
      final scores = controller.gameScore;
      expect(scores.teamA >= 0, isTrue);
      expect(scores.teamB >= 0, isTrue);
    });
  });
}
