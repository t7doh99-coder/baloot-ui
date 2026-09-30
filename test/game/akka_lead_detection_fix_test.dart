import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/round_state_model.dart';
import 'package:baloot_game/features/game/domain/baloot_game_controller.dart';
import 'package:baloot_game/features/game/domain/managers/turn_manager.dart';

/// Tests for the Akka lead-card detection fix.
///
/// The bug: when a player plays the 4th card that completes a trick,
/// TurnManager clears currentTrick. Then isAkka()'s else-branch
/// incorrectly defaulted isLeadCard = true, causing false Akka
/// announcements from non-leading players.
void main() {
  group('Akka Lead-Card Detection Fix Tests', () {
    late BalootGameController game;

    setUp(() {
      game = BalootGameController();
    });

    /// Helper to set up Hakam mode with spades as trump.
    void setupHakamWithSpadesTrump(TurnManager tm) {
      final rs = const RoundStateModel(
        dealerIndex: 0,
        currentPlayerIndex: 0,
      ).copyWith(
        activeMode: GameMode.hakam,
        trumpSuit: Suit.spades,
      );
      game.setRoundStateForTest(rs);
      game.setTurnManagerForTest(tm);
    }

    test('BUG FIX: 4th card completing a trick must NOT be considered Akka', () {
      // Setup: Hakam with spades trump.
      // Trick 1: Play Ace, 10, 8 of hearts. Seat 3 plays King of hearts (4th card).
      // After trick 1, King of hearts IS the highest remaining card of hearts,
      // but it should NOT be Akka because it was NOT the lead card.
      final tm = TurnManager(
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        firstPlayerIndex: 0,
      );
      setupHakamWithSpadesTrump(tm);

      // Trick 1: 4 cards complete the trick
      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.ace));
      tm.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.ten));
      tm.playCard(2, const CardModel(suit: Suit.hearts, rank: Rank.eight));
      tm.playCard(3, const CardModel(suit: Suit.hearts, rank: Rank.king));
      // Trick is completed. currentTrick is now EMPTY.
      // King of hearts is in trickHistory.last as the 4th card (NOT lead).

      // The King of hearts IS the strongest remaining hearts card,
      // but it was the 4th card, not the lead. It must NOT be Akka.
      final kingOfHearts = const CardModel(suit: Suit.hearts, rank: Rank.king);
      expect(game.isAkka(kingOfHearts), isFalse,
          reason: 'King was the 4th card in a completed trick, not the lead — NOT Akka');
    });

    test('BUG FIX: 2nd card in a completed trick must NOT be Akka', () {
      final tm = TurnManager(
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        firstPlayerIndex: 0,
      );
      setupHakamWithSpadesTrump(tm);

      // Trick 1: Seat 0 leads with 7♣, seat 1 plays 10♣ (2nd card)
      tm.playCard(0, const CardModel(suit: Suit.clubs, rank: Rank.seven));
      tm.playCard(1, const CardModel(suit: Suit.clubs, rank: Rank.ten));
      tm.playCard(2, const CardModel(suit: Suit.clubs, rank: Rank.eight));
      tm.playCard(3, const CardModel(suit: Suit.clubs, rank: Rank.nine));

      // 10♣ was the 2nd card (not lead) — even though it was played,
      // isAkka should return false because it's in trickHistory as a non-lead card.
      final tenOfClubs = const CardModel(suit: Suit.clubs, rank: Rank.ten);
      expect(game.isAkka(tenOfClubs), isFalse,
          reason: '10♣ was the 2nd card in the completed trick — NOT Akka');
    });

    test('BUG FIX: 3rd card in a completed trick must NOT be Akka', () {
      final tm = TurnManager(
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        firstPlayerIndex: 0,
      );
      setupHakamWithSpadesTrump(tm);

      // Trick 1
      tm.playCard(0, const CardModel(suit: Suit.diamonds, rank: Rank.ace));
      tm.playCard(1, const CardModel(suit: Suit.diamonds, rank: Rank.eight));
      tm.playCard(2, const CardModel(suit: Suit.diamonds, rank: Rank.ten));
      tm.playCard(3, const CardModel(suit: Suit.diamonds, rank: Rank.seven));

      // 10 of diamonds was the 3rd card and is now the strongest remaining
      // (after Ace was played as lead). But 10 was NOT lead — cannot be Akka.
      final tenOfDiamonds = const CardModel(suit: Suit.diamonds, rank: Rank.ten);
      expect(game.isAkka(tenOfDiamonds), isFalse,
          reason: '10 was the 3rd card in the completed trick — NOT Akka');
    });

    test('Lead card of a completed trick IS correctly detected as Akka', () {
      final tm = TurnManager(
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        firstPlayerIndex: 0,
      );
      setupHakamWithSpadesTrump(tm);

      // Trick 1: Play Ace and 10 of hearts to make King the highest remaining
      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.ace));
      tm.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.ten));
      tm.playCard(2, const CardModel(suit: Suit.hearts, rank: Rank.eight));
      tm.playCard(3, const CardModel(suit: Suit.hearts, rank: Rank.seven));

      // Trick 2: Seat 0 LEADS with King of hearts
      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.king));
      tm.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.nine));
      tm.playCard(2, const CardModel(suit: Suit.diamonds, rank: Rank.seven));
      tm.playCard(3, const CardModel(suit: Suit.clubs, rank: Rank.seven));

      // King of hearts was the LEAD card of trick 2, and it IS the strongest
      // remaining hearts card. This SHOULD be Akka.
      final kingOfHearts = const CardModel(suit: Suit.hearts, rank: Rank.king);
      expect(game.isAkka(kingOfHearts), isTrue,
          reason: 'King was the lead card and IS the strongest remaining — valid Akka');
    });

    test('User scenario: 10♥ leads with Akka, then opponent K♥ in same trick must NOT be Akka', () {
      // This is the EXACT scenario from the user's bug report:
      // "If I have the 10 of Hearts and I call Akkah, then an opponent plays
      //  the King of Hearts, that opponent should not also say Akkah."
      final tm = TurnManager(
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        firstPlayerIndex: 0,
      );
      setupHakamWithSpadesTrump(tm);

      // Pre-condition: Ace of hearts already played in a previous trick
      // so that 10 of hearts IS the highest remaining
      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.ace));
      tm.playCard(1, const CardModel(suit: Suit.clubs, rank: Rank.seven));
      tm.playCard(2, const CardModel(suit: Suit.clubs, rank: Rank.eight));
      tm.playCard(3, const CardModel(suit: Suit.clubs, rank: Rank.nine));

      // Trick 2: Seat 0 leads with 10♥ (this IS a valid Akka — highest remaining)
      final tenOfHearts = const CardModel(suit: Suit.hearts, rank: Rank.ten);
      // Before playing, check it's Akka
      expect(game.isAkka(tenOfHearts), isTrue,
          reason: '10♥ is the highest remaining hearts card and is about to lead');

      // Now play the trick
      tm.playCard(0, tenOfHearts);
      // Seat 1 (opponent) plays K♥
      tm.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.king));

      // K♥ is now the 2nd card in the trick (not lead). It must NOT be Akka.
      final kingOfHearts = const CardModel(suit: Suit.hearts, rank: Rank.king);
      expect(game.isAkka(kingOfHearts), isFalse,
          reason: 'K♥ was played as 2nd card in the trick, not as lead — NOT Akka');

      // Complete the trick
      tm.playCard(2, const CardModel(suit: Suit.diamonds, rank: Rank.seven));
      tm.playCard(3, const CardModel(suit: Suit.diamonds, rank: Rank.eight));

      // After trick completes, K♥ is in trickHistory.last as 2nd card.
      // It STILL must NOT be Akka.
      expect(game.isAkka(kingOfHearts), isFalse,
          reason: 'K♥ was in the completed trick as non-lead — still NOT Akka');
    });

    test('Candidate lead card (before playCard) IS correctly treated as potential Akka', () {
      final tm = TurnManager(
        mode: GameMode.hakam,
        trumpSuit: Suit.spades,
        firstPlayerIndex: 0,
      );
      setupHakamWithSpadesTrump(tm);

      // Play out Ace and 10 of hearts in a previous trick
      tm.playCard(0, const CardModel(suit: Suit.hearts, rank: Rank.ace));
      tm.playCard(1, const CardModel(suit: Suit.hearts, rank: Rank.ten));
      tm.playCard(2, const CardModel(suit: Suit.hearts, rank: Rank.eight));
      tm.playCard(3, const CardModel(suit: Suit.hearts, rank: Rank.seven));

      // Now, BEFORE playing, check if King of hearts would be Akka as lead candidate
      final kingOfHearts = const CardModel(suit: Suit.hearts, rank: Rank.king);
      expect(game.isAkka(kingOfHearts), isTrue,
          reason: 'K♥ is not in any trick yet, so it is a valid lead candidate for Akka');
    });
  });
}
