import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/card_model.dart';
import '../../../../data/models/round_state_model.dart';
import '../../domain/baloot_game_controller.dart';
import '../../domain/managers/bidding_manager.dart';
import '../game_provider.dart';

class QaidTestScenarios {
  

  static void showLiveCheatModeDialog(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Live Bot Cheat Mode'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('0. None (Play Fair)'),
                subtitle: const Text('Bots play by the rules'),
                selected: game.engine.activeCheatMode == BotCheatMode.none,
                onTap: () {
                  game.engine.activeCheatMode = BotCheatMode.none;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('1. Force Suit Violation'),
                subtitle: const Text('Bot will play wrong suit if possible'),
                selected: game.engine.activeCheatMode == BotCheatMode.suitViolation,
                onTap: () {
                  game.engine.activeCheatMode = BotCheatMode.suitViolation;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('2. Force Cut Violation'),
                subtitle: const Text('Bot will fail to cut if possible'),
                selected: game.engine.activeCheatMode == BotCheatMode.cutViolation,
                onTap: () {
                  game.engine.activeCheatMode = BotCheatMode.cutViolation;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('3. Force Up-Trump Violation'),
                subtitle: const Text('Bot will play lower trump when they have higher'),
                selected: game.engine.activeCheatMode == BotCheatMode.upTrumpViolation,
                onTap: () {
                  game.engine.activeCheatMode = BotCheatMode.upTrumpViolation;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('4. Force Closed Play Violation'),
                subtitle: const Text('Bot will lead trump during Double'),
                selected: game.engine.activeCheatMode == BotCheatMode.closedPlayViolation,
                onTap: () {
                  game.engine.activeCheatMode = BotCheatMode.closedPlayViolation;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('5. Force False Akka'),
                subtitle: const Text('Bot will randomly claim Akka'),
                selected: game.engine.activeCheatMode == BotCheatMode.falseAkka,
                onTap: () {
                  game.engine.activeCheatMode = BotCheatMode.falseAkka;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('6. Force False Sawa'),
                subtitle: const Text('Bot will instantly claim Sawa'),
                selected: game.engine.activeCheatMode == BotCheatMode.falseSawa,
                onTap: () {
                  game.engine.activeCheatMode = BotCheatMode.falseSawa;
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
