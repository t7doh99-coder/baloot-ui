import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';

void main() {
  group('CardModel point values', () {
    test('Sun mode: Jack = 2, Nine = 0, Ace = 11', () {
      const jack = CardModel(suit: Suit.hearts, rank: Rank.jack);
      const nine = CardModel(suit: Suit.hearts, rank: Rank.nine);
      const ace = CardModel(suit: Suit.hearts, rank: Rank.ace);

      expect(jack.getPointValue(mode: GameMode.sun), 2);
      expect(nine.getPointValue(mode: GameMode.sun), 0);
      expect(ace.getPointValue(mode: GameMode.sun), 11);
    });

    test('Hakam mode: trump Jack = 20, trump Nine = 14', () {
      const jack = CardModel(suit: Suit.spades, rank: Rank.jack);
      const nine = CardModel(suit: Suit.spades, rank: Rank.nine);

      expect(
        jack.getPointValue(mode: GameMode.hakam, trumpSuit: Suit.spades),
        20,
      );
      expect(
        nine.getPointValue(mode: GameMode.hakam, trumpSuit: Suit.spades),
        14,
      );
    });

    test('Hakam mode: non-trump Jack = 2, non-trump Nine = 0', () {
      const jack = CardModel(suit: Suit.hearts, rank: Rank.jack);
      const nine = CardModel(suit: Suit.hearts, rank: Rank.nine);

      expect(
        jack.getPointValue(mode: GameMode.hakam, trumpSuit: Suit.spades),
        2,
      );
      expect(
        nine.getPointValue(mode: GameMode.hakam, trumpSuit: Suit.spades),
        0,
      );
    });

    test('Total Sun Abnat = 120 card points (no last trick bonus)', () {
      int total = 0;
      for (final suit in Suit.values) {
        for (final rank in Rank.values) {
          total += const CardModel(suit: Suit.hearts, rank: Rank.ace)
              .getPointValue(mode: GameMode.sun)
              .bitLength; // dummy call to show pattern
        }
      }
      // Direct calculation: 4 suits * (0+0+0+10+2+3+4+11) = 4 * 30 = 120
      int sunTotal = 0;
      for (final suit in Suit.values) {
        for (final rank in Rank.values) {
          final card = CardModel(suit: suit, rank: rank);
          sunTotal += card.getPointValue(mode: GameMode.sun);
        }
      }
      expect(sunTotal, 120);
    });

    test('Total Hakam Abnat = 152 card points (no last trick bonus)', () {
      const trumpSuit = Suit.hearts;
      int hakamTotal = 0;
      for (final suit in Suit.values) {
        for (final rank in Rank.values) {
          final card = CardModel(suit: suit, rank: rank);
          hakamTotal += card.getPointValue(
            mode: GameMode.hakam,
            trumpSuit: trumpSuit,
          );
        }
      }
      // 3 non-trump suits * 30 = 90 + trump suit (0+0+14+10+20+3+4+11) = 62 => 152
      expect(hakamTotal, 152);
    });
  });

  group('CardModel strength rankings', () {
    test('Sun strength: Ace > Ten > King > Queen > Jack > 9 > 8 > 7', () {
      final strengths = Rank.values
          .map((r) => CardModel(suit: Suit.hearts, rank: r)
              .getStrength(mode: GameMode.sun))
          .toList();
      // seven=0, eight=1, nine=2, ten=6, jack=3, queen=4, king=5, ace=7
      expect(strengths, [0, 1, 2, 6, 3, 4, 5, 7]);
    });

    test('Hakam trump strength: Jack > 9 > Ace > 10 > King > Queen > 8 > 7',
        () {
      final strengths = Rank.values
          .map((r) => CardModel(suit: Suit.spades, rank: r)
              .getStrength(mode: GameMode.hakam, trumpSuit: Suit.spades))
          .toList();
      // seven=0, eight=1, nine=6, ten=4, jack=7, queen=2, king=3, ace=5
      expect(strengths, [0, 1, 6, 4, 7, 2, 3, 5]);
    });

    test('Hakam non-trump uses standard strength', () {
      final hearts = CardModel(suit: Suit.hearts, rank: Rank.jack);
      expect(
        hearts.getStrength(mode: GameMode.hakam, trumpSuit: Suit.spades),
        3, // standard Jack strength
      );
    });
  });

  group('RoundStateModel', () {
    test('creates with defaults', () {
      const state = RoundStateModel(dealerIndex: 0, currentPlayerIndex: 1);
      expect(state.biddingPhase, BiddingPhase.round1);
      expect(state.activeMode, isNull);
      expect(state.trumpSuit, isNull);
      expect(state.doubleStatus, DoubleStatus.none);
      expect(state.trickNumber, 1);
      expect(state.currentTrick, isEmpty);
      expect(state.teamATricksWon, isEmpty);
      expect(state.teamBTricksWon, isEmpty);
    });

    test('copyWith preserves unchanged fields', () {
      const state = RoundStateModel(dealerIndex: 0, currentPlayerIndex: 1);
      final updated = state.copyWith(trickNumber: 5, activeMode: GameMode.sun);

      expect(updated.dealerIndex, 0);
      expect(updated.currentPlayerIndex, 1);
      expect(updated.trickNumber, 5);
      expect(updated.activeMode, GameMode.sun);
      expect(updated.biddingPhase, BiddingPhase.round1);
    });

    test('team assignment: seats 0,2 = Team A; seats 1,3 = Team B', () {
      const state = RoundStateModel(dealerIndex: 0, currentPlayerIndex: 0);
      expect(state.isTeamA(0), true);
      expect(state.isTeamA(1), false);
      expect(state.isTeamA(2), true);
      expect(state.isTeamA(3), false);
    });

    test('toSnapshot contains all reconnection fields', () {
      const state = RoundStateModel(
        dealerIndex: 2,
        currentPlayerIndex: 3,
        activeMode: GameMode.hakam,
        trumpSuit: Suit.hearts,
        trickNumber: 4,
      );
      final snap = state.toSnapshot();
      expect(snap['dealerIndex'], 2);
      expect(snap['currentPlayerIndex'], 3);
      expect(snap['activeMode'], 'hakam');
      expect(snap['trumpSuit'], 'hearts');
      expect(snap['trickNumber'], 4);
    });
  });

  group('DeclaredProject', () {
    test('Sera: 20 Abnat in Hakam, 4 in Sun', () {
      const project = DeclaredProject(
        type: ProjectType.sera,
        playerIndex: 0,
        cards: [],
      );
      expect(project.getAbnat(GameMode.hakam), 20);
      expect(project.getAbnat(GameMode.sun), 4);
    });

    test('Fifty: 50 Abnat in Hakam, 10 in Sun', () {
      const project = DeclaredProject(
        type: ProjectType.fifty,
        playerIndex: 0,
        cards: [],
      );
      expect(project.getAbnat(GameMode.hakam), 50);
      expect(project.getAbnat(GameMode.sun), 10);
    });

    test('Hundred: 100 Abnat (Hakam only)', () {
      const project = DeclaredProject(
        type: ProjectType.hundred,
        playerIndex: 0,
        cards: [],
      );
      expect(project.getAbnat(GameMode.hakam), 100);
    });

    test('FourHundred: 40 Abnat (Sun only)', () {
      const project = DeclaredProject(
        type: ProjectType.fourHundred,
        playerIndex: 0,
        cards: [],
      );
      expect(project.getAbnat(GameMode.sun), 40);
    });

    test('Baloot: 0 Abnat, always 2 scoreboard pts', () {
      const project = DeclaredProject(
        type: ProjectType.baloot,
        playerIndex: 0,
        cards: [],
      );
      expect(project.getAbnat(GameMode.hakam), 0);
      expect(project.getScoreboardPoints(GameMode.hakam), 2);
    });

    test('priority ranking: 400 > 100 > 50 > Sera', () {
      const sera = DeclaredProject(
          type: ProjectType.sera, playerIndex: 0, cards: []);
      const fifty = DeclaredProject(
          type: ProjectType.fifty, playerIndex: 0, cards: []);
      const hundred = DeclaredProject(
          type: ProjectType.hundred, playerIndex: 0, cards: []);
      const fourHundred = DeclaredProject(
          type: ProjectType.fourHundred, playerIndex: 0, cards: []);

      expect(fourHundred.priorityRank > hundred.priorityRank, true);
      expect(hundred.priorityRank > fifty.priorityRank, true);
      expect(fifty.priorityRank > sera.priorityRank, true);
    });
  });
}
