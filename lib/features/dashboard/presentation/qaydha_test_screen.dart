import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../game/presentation/game_provider.dart';
import '../../game/presentation/game_table_screen.dart';
import '../../game/presentation/widgets/qaydha_review_overlay.dart';
import '../../../../data/models/card_model.dart';
import '../../../../data/models/card_play_model.dart';
import '../../game/domain/managers/turn_manager.dart' show TrickResult;

class QaydhaTestScreen extends StatefulWidget {
  const QaydhaTestScreen({super.key});

  @override
  State<QaydhaTestScreen> createState() => _QaydhaTestScreenState();
}

class _QaydhaTestScreenState extends State<QaydhaTestScreen> {
  late GameProvider _game;

  @override
  void initState() {
    super.initState();
    _game = GameProvider();
    _game.startGame(suspendAutoPlay: true);
    
    // Add mock tricks so the table is rich with gameplay
    final mockTrick1 = TrickResult(
      winnerIndex: 1,
      cards: const [
        CardPlayModel(card: CardModel(suit: Suit.diamonds, rank: Rank.ace), playerIndex: 0),
        CardPlayModel(card: CardModel(suit: Suit.clubs, rank: Rank.nine), playerIndex: 1),
        CardPlayModel(card: CardModel(suit: Suit.diamonds, rank: Rank.seven), playerIndex: 2),
        CardPlayModel(card: CardModel(suit: Suit.diamonds, rank: Rank.eight), playerIndex: 3),
      ],
      abnat: 11,
      isLastTrick: false,
      lastTrickBonus: 0,
    );
    final mockTrick2 = TrickResult(
      winnerIndex: 0,
      cards: const [
        CardPlayModel(card: CardModel(suit: Suit.spades, rank: Rank.ace), playerIndex: 0),
        CardPlayModel(card: CardModel(suit: Suit.clubs, rank: Rank.eight), playerIndex: 1),
        CardPlayModel(card: CardModel(suit: Suit.spades, rank: Rank.seven), playerIndex: 2),
        CardPlayModel(card: CardModel(suit: Suit.spades, rank: Rank.queen), playerIndex: 3),
      ],
      abnat: 11,
      isLastTrick: false,
      lastTrickBonus: 0,
    );
    _game.setMockQaydhaTricks([mockTrick1, mockTrick2]);

    // Force Qaydha to show
    _game.forceShowQaydhaReview();
    _game.addListener(_onGameChanged);
  }

  void _onGameChanged() {
    if (!_game.isQaydhaReviewVisible && _game.qaidClaimResult == null && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    _game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _game,
      child: const Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            GameTableScreen(),
            QaydhaReviewOverlay(),
          ],
        ),
      ),
    );
  }
}
