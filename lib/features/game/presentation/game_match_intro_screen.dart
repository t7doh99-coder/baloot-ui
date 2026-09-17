import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/bot_difficulty.dart';
import 'game_provider.dart';
import 'game_table_screen.dart';

/// Intermediate screen shown after [GameLoadingScreen].
/// Displays the matchup versus screen for 3.2 seconds before initializing
/// the game match and transitioning to [GameTableScreen] where the
/// bidding scenario and Awal voice start.
class GameMatchIntroScreen extends StatefulWidget {
  final BotDifficulty difficulty;

  const GameMatchIntroScreen({super.key, required this.difficulty});

  @override
  State<GameMatchIntroScreen> createState() => _GameMatchIntroScreenState();
}

class _GameMatchIntroScreenState extends State<GameMatchIntroScreen> {
  Timer? _timer;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _startIntroTimer();
  }

  void _startIntroTimer() {
    _timer = Timer(const Duration(milliseconds: 2000), () async {
      if (!mounted || _navigating) return;
      _navigating = true;

      final game = context.read<GameProvider>();
      // Ensure match engine has finished dealing before switching to table
      await game.prepareMatchForTable(difficulty: widget.difficulty);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => const GameTableScreen(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: GameTableScreen(showIntroVersus: true),
    );
  }
}
