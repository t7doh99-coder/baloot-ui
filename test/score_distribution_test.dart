// Statistical analysis of hand score distributions
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import '../lib/data/models/card_model.dart';
import '../lib/features/game/domain/engines/bot_engine.dart';
import '../lib/features/game/domain/managers/deck_manager.dart';

void main() {
  test('Score distributions for 5-card hands', () {
    final rng = Random(42);
    final bot = const BotEngine();
    
    final hakamScores = <int>[];
    final sunScores = <int>[];

    for (int trial = 0; trial < 5000; trial++) {
      final dm = DeckManager(random: rng);
      dm.createDeck();
      dm.shuffle();
      dm.kut();

      final dealer = trial % 4;
      dm.dealInitial(dealer);

      final buyerCard = dm.buyerCard!;
      final trumpSuit = buyerCard.suit;

      // Check all 4 players' hands
      for (int seat = 0; seat < 4; seat++) {
        final hand = dm.hands[seat];
        
        // Hakam score for this hand (using buyer card suit as trump)
        int hScore = 0;
        final trumpCards = hand.where((c) => c.suit == trumpSuit).toList();
        final nonTrumpCards = hand.where((c) => c.suit != trumpSuit).toList();
        hScore += trumpCards.length * 6;
        for (final c in trumpCards) {
          if (c.rank == Rank.jack) hScore += 15;
          if (c.rank == Rank.nine) hScore += 10;
          if (c.rank == Rank.ace) hScore += 6;
          if (c.rank == Rank.ten) hScore += 4;
        }
        for (final c in nonTrumpCards) {
          if (c.rank == Rank.ace) hScore += 5;
          if (c.rank == Rank.ten) hScore += 2;
        }
        hakamScores.add(hScore);
        
        // Sun score
        int sScore = 0;
        for (final c in hand) {
          if (c.rank == Rank.ace) sScore += 8;
          if (c.rank == Rank.ten) sScore += 5;
          if (c.rank == Rank.king) sScore += 3;
        }
        final suitAces = hand.where((c) => c.rank == Rank.ace).map((c) => c.suit).toSet();
        if (suitAces.length >= 3) sScore += 10;
        if (suitAces.length == 4) sScore += 8;
        sunScores.add(sScore);
      }
    }

    // Sort and print distributions
    hakamScores.sort();
    sunScores.sort();
    
    final n = hakamScores.length;
    print('=== HAKAM Score Distribution (${n} hands) ===');
    print('  Min: ${hakamScores.first}');
    print('  25th: ${hakamScores[(n * 0.25).round()]}');
    print('  Median: ${hakamScores[(n * 0.5).round()]}');
    print('  75th: ${hakamScores[(n * 0.75).round()]}');
    print('  90th: ${hakamScores[(n * 0.90).round()]}');
    print('  Max: ${hakamScores.last}');
    print('  Mean: ${(hakamScores.reduce((a,b) => a+b) / n).toStringAsFixed(1)}');
    print('  Hands >= 35: ${hakamScores.where((s) => s >= 35).length} (${(hakamScores.where((s) => s >= 35).length / n * 100).toStringAsFixed(1)}%)');
    print('  Hands >= 40: ${hakamScores.where((s) => s >= 40).length} (${(hakamScores.where((s) => s >= 40).length / n * 100).toStringAsFixed(1)}%)');
    print('  Hands >= 45: ${hakamScores.where((s) => s >= 45).length} (${(hakamScores.where((s) => s >= 45).length / n * 100).toStringAsFixed(1)}%)');
    
    print('');
    print('=== SUN Score Distribution (${n} hands) ===');
    print('  Min: ${sunScores.first}');
    print('  25th: ${sunScores[(n * 0.25).round()]}');
    print('  Median: ${sunScores[(n * 0.5).round()]}');
    print('  75th: ${sunScores[(n * 0.75).round()]}');
    print('  90th: ${sunScores[(n * 0.90).round()]}');
    print('  Max: ${sunScores.last}');
    print('  Mean: ${(sunScores.reduce((a,b) => a+b) / n).toStringAsFixed(1)}');
    print('  Hands >= 30: ${sunScores.where((s) => s >= 30).length} (${(sunScores.where((s) => s >= 30).length / n * 100).toStringAsFixed(1)}%)');
    print('  Hands >= 35: ${sunScores.where((s) => s >= 35).length} (${(sunScores.where((s) => s >= 35).length / n * 100).toStringAsFixed(1)}%)');
    print('  Hands >= 40: ${sunScores.where((s) => s >= 40).length} (${(sunScores.where((s) => s >= 40).length / n * 100).toStringAsFixed(1)}%)');
    print('  Hands >= 48: ${sunScores.where((s) => s >= 48).length} (${(sunScores.where((s) => s >= 48).length / n * 100).toStringAsFixed(1)}%)');
    
    print('');
    print('=== Probability any of 4 players bids (per deal) ===');
    // Probability that at least 1 of 4 players has hakam >= 35
    final pSingleHakam = hakamScores.where((s) => s >= 35).length / n;
    final pNoHakam = 1 - pSingleHakam;
    final pAnyHakam = 1 - (pNoHakam * pNoHakam * pNoHakam * pNoHakam);
    print('  P(any player Hakam>=35): ${(pAnyHakam * 100).toStringAsFixed(1)}%');

    final pSingleSun = sunScores.where((s) => s >= 48).length / n;
    final pNoSun = 1 - pSingleSun;
    final pAnySun = 1 - (pNoSun * pNoSun * pNoSun * pNoSun);
    print('  P(any player Sun>=48): ${(pAnySun * 100).toStringAsFixed(1)}%');

    final pSingleSunR2 = sunScores.where((s) => s >= 40).length / n;
    final pNoSunR2 = 1 - pSingleSunR2;
    final pAnySunR2 = 1 - (pNoSunR2 * pNoSunR2 * pNoSunR2 * pNoSunR2);
    print('  P(any player Sun>=40 in R2): ${(pAnySunR2 * 100).toStringAsFixed(1)}%');
  });
}
