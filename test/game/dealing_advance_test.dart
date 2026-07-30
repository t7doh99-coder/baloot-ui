import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baloot_game/data/models/bot_difficulty.dart';
import 'package:baloot_game/features/game/domain/baloot_game_controller.dart';
import 'package:baloot_game/features/game/presentation/game_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dealing advance (low-end safety)', () {
    test('startGame leaves dealing then advances to bidding', () {
      fakeAsync((async) {
        final game = GameProvider();
        game.startGame(difficulty: BotDifficulty.medium);
        expect(game.phase, GamePhase.dealing);

        async.elapse(const Duration(milliseconds: 1300));
        expect(game.phase, GamePhase.bidding);

        game.dispose();
      });
    });

    test('ensureDealingAdvances(force) unsticks dealing with no timer', () {
      fakeAsync((async) {
        final game = GameProvider();
        game.startGame(difficulty: BotDifficulty.medium);
        expect(game.phase, GamePhase.dealing);

        game.leaveTable();
        expect(game.phase, GamePhase.dealing);

        game.ensureDealingAdvances(force: true);
        expect(game.phase, GamePhase.bidding);

        game.dispose();
      });
    });

    test('prepareMatchForTable finishes deal before table opens', () {
      fakeAsync((async) {
        final game = GameProvider();

        game.prepareMatchForTable(difficulty: BotDifficulty.medium);
        async.flushMicrotasks();
        async.elapse(Duration.zero);
        async.flushMicrotasks();

        expect(game.isMatchReady, isTrue);
        expect(game.phase, GamePhase.bidding);

        // Autoplay still suspended until table ready.
        async.elapse(const Duration(seconds: 5));
        expect(game.phase, GamePhase.bidding);

        game.onTableReady();
        async.elapse(const Duration(milliseconds: 600));
        expect(game.phase, isNot(GamePhase.dealing));

        game.dispose();
      });
    });
  });
}
