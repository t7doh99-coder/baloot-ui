import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/data/models/card_play_model.dart';

class TrickResult {
  final int winnerIndex;
  final List<CardPlayModel> cards;
  final int abnat;
  final bool isLastTrick;
  final int lastTrickBonus;
  TrickResult({required this.winnerIndex, required this.cards, required this.abnat, required this.isLastTrick, required this.lastTrickBonus});
}

bool testIsAkka(CardModel card, GameMode mode, Suit? trump, List<TrickResult> trickHistory, List<CardPlayModel> currentTrick) {
    if (mode == GameMode.sun) return false;
    if (card.suit == trump) return false;

    bool isLeadCard = false;
    if (currentTrick.isNotEmpty) {
      isLeadCard = currentTrick.first.card == card;
    } else if (trickHistory.isNotEmpty) {
      final lastTrick = trickHistory.last;
      if (lastTrick.cards.isNotEmpty) {
        isLeadCard = lastTrick.cards.first.card == card;
      }
    }
    if (!isLeadCard) return false;

    final playedOfSuit = <CardModel>{};
    final historyCount = currentTrick.isNotEmpty
        ? trickHistory.length
        : trickHistory.length - 1;
    for (int i = 0; i < historyCount; i++) {
      for (final play in trickHistory[i].cards) {
        if (play.card.suit == card.suit) {
          playedOfSuit.add(play.card);
        }
      }
    }

    final cardStrength = card.getStrength(mode: mode, trumpSuit: trump);

    for (final rank in Rank.values) {
      final other = CardModel(suit: card.suit, rank: rank);
      if (other == card) continue;
      if (playedOfSuit.contains(other)) continue;

      final otherStrength = other.getStrength(mode: mode, trumpSuit: trump);
      if (otherStrength > cardStrength) {
        return false;
      }
    }
    return true;
}

void main() {
  print('--- AKKA LOGIC TESTS ---');

  final aceHearts = CardModel(suit: Suit.hearts, rank: Rank.ace);
  final tenHearts = CardModel(suit: Suit.hearts, rank: Rank.ten);
  final kingHearts = CardModel(suit: Suit.hearts, rank: Rank.king);
  final jackSpades = CardModel(suit: Suit.spades, rank: Rank.jack);
  final aceSpades = CardModel(suit: Suit.spades, rank: Rank.ace);

  // 1. Sun Mode -> Should be false immediately
  bool sunTest = testIsAkka(aceHearts, GameMode.sun, null, [], [CardPlayModel(card: aceHearts, playerIndex: 0)]);
  print('1. Sun Mode Test (A Hearts): \$sunTest (Expected: false)');

  // 2. Hakam Mode, Trump Suit -> Should be false immediately
  bool trumpTest = testIsAkka(jackSpades, GameMode.hakam, Suit.spades, [], [CardPlayModel(card: jackSpades, playerIndex: 0)]);
  print('2. Hakam Trump Test (J Spades): \$trumpTest (Expected: false)');

  // 3. Hakam Mode, Lead with Ace -> Should be true (Ace is highest)
  bool leadAceTest = testIsAkka(aceHearts, GameMode.hakam, Suit.spades, [], [CardPlayModel(card: aceHearts, playerIndex: 0)]);
  print('3. Lead with Ace (No cards played yet): \$leadAceTest (Expected: true)');

  // 4. Hakam Mode, Following with Ace -> Should be false
  bool followAceTest = testIsAkka(aceHearts, GameMode.hakam, Suit.spades, [], [CardPlayModel(card: tenHearts, playerIndex: 1), CardPlayModel(card: aceHearts, playerIndex: 0)]);
  print('4. Following with Ace (Not leading): \$followAceTest (Expected: false)');

  // 5. Hakam Mode, Lead with 10 when Ace is NOT played -> Should be false
  bool leadTenAceUnplayed = testIsAkka(tenHearts, GameMode.hakam, Suit.spades, [], [CardPlayModel(card: tenHearts, playerIndex: 0)]);
  print('5. Lead with 10 (Ace not played): \$leadTenAceUnplayed (Expected: false)');

  // 6. Hakam Mode, Lead with 10 when Ace IS played in trick history -> Should be true
  final trick1 = TrickResult(
    winnerIndex: 0, 
    cards: [
      CardPlayModel(card: aceHearts, playerIndex: 0),
      CardPlayModel(card: CardModel(suit: Suit.clubs, rank: Rank.seven), playerIndex: 1),
      CardPlayModel(card: CardModel(suit: Suit.diamonds, rank: Rank.seven), playerIndex: 2),
      CardPlayModel(card: CardModel(suit: Suit.clubs, rank: Rank.eight), playerIndex: 3),
    ], 
    abnat: 11, isLastTrick: false, lastTrickBonus: 0
  );
  bool leadTenAcePlayed = testIsAkka(tenHearts, GameMode.hakam, Suit.spades, [trick1], [CardPlayModel(card: tenHearts, playerIndex: 0)]);
  print('6. Lead with 10 (Ace already played): \$leadTenAcePlayed (Expected: true)');
}
