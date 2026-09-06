import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:baloot_game/features/game/presentation/game_provider.dart';
import 'package:baloot_game/features/game/domain/baloot_game_controller.dart';
import 'package:baloot_game/data/models/card_model.dart';
import 'package:baloot_game/features/game/domain/managers/bidding_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Auto & Manual Akka Mode & Controls Tests', () {
    test('1. Default Akka mode is auto and autoAkkaEnabled is true', () {
      final provider = GameProvider(random: Random(42));
      provider.audioService.setMuted(true);

      expect(provider.akkaMode, equals(AkkaMode.auto));
      expect(provider.isAkkaAutoSetting, isTrue);
      expect(provider.autoAkkaEnabled, isTrue);
    });

    test('2. Changing Akka mode to manual disables autoAkkaEnabled and updates getters', () async {
      final provider = GameProvider(random: Random(42));
      provider.audioService.setMuted(true);

      await provider.setAkkaMode(AkkaMode.manual);
      expect(provider.akkaMode, equals(AkkaMode.manual));
      expect(provider.isAkkaAutoSetting, isFalse);
      expect(provider.autoAkkaEnabled, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_akka_mode'), equals('manual'));

      await provider.setAkkaMode(AkkaMode.auto);
      expect(provider.akkaMode, equals(AkkaMode.auto));
      expect(provider.isAkkaAutoSetting, isTrue);
      expect(provider.autoAkkaEnabled, isTrue);
      expect(prefs.getString('pref_akka_mode'), equals('auto'));
    });

    test('3. toggleAutoAkka toggles autoAkkaEnabled in-game', () {
      final provider = GameProvider(random: Random(42));
      provider.audioService.setMuted(true);

      expect(provider.autoAkkaEnabled, isTrue);
      provider.toggleAutoAkka();
      expect(provider.autoAkkaEnabled, isFalse);
      provider.toggleAutoAkka();
      expect(provider.autoAkkaEnabled, isTrue);
    });

    test('4. In Manual Mode, claimAkka claims Ekka on engine and shows speech bubble', () {
      final provider = GameProvider(random: Random(42));
      provider.audioService.setMuted(true);
      provider.startGame();

      // Put into playing phase
      provider.engine.startNewRound();
      final firstBidder = provider.engine.roundState.currentPlayerIndex;
      provider.engine.placeBid(firstBidder, BidAction.sun);
      if (provider.engine.gamePhase == GamePhase.doubleWindow) {
        provider.engine.skipDoubleWindow();
      }

      // If seat 0 is leading the trick, canAkka should be true
      if (provider.currentPlayerIndex == 0) {
        expect(provider.canAkka, isTrue);
        provider.claimAkka();
        expect(provider.bubbles[0], equals('Akka'));
        expect(provider.engine.ekkaClaimSeat, equals(0));
      }
    });

    test('5. Pre-play isAkka check accurately identifies lead Akka card', () {
      final controller = BalootGameController(random: Random(42));
      controller.startNewGame(['Human', 'Bot 1', 'Bot 2', 'Bot 3']);
      controller.startNewRound();

      final firstBidder = controller.roundState.currentPlayerIndex;
      controller.placeBid(firstBidder, BidAction.sun);
      if (controller.gamePhase == GamePhase.doubleWindow) {
        controller.skipDoubleWindow();
      }

      expect(controller.gamePhase, equals(GamePhase.playing));

      // Ace of any suit is an Akka on trick 1 in Sun
      const aceOfSpades = CardModel(suit: Suit.spades, rank: Rank.ace);
      expect(controller.isAkka(aceOfSpades), isTrue);

      // Seven of any suit is NOT an Akka when higher cards exist
      const sevenOfSpades = CardModel(suit: Suit.spades, rank: Rank.seven);
      expect(controller.isAkka(sevenOfSpades), isFalse);
    });
  });
}
