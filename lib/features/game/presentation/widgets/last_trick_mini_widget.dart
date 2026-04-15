import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_provider.dart';
import 'playing_card.dart';

/// Top-right Jawaker-style mini panel: last completed trick in a + layout.
///
/// • Before any trick in the session: four **red** card backs (first-round look).
/// • After each trick: the four real cards by seat (2=top, 1=right, 0=bottom, 3=left).
class LastTrickMiniWidget extends StatelessWidget {
  const LastTrickMiniWidget({super.key});

  static const _box = 58.0;
  static const _cardW = 17.0;
  static const _cardH = 24.0;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final cards = game.lastTrickMiniBySeat;
    final faceUp = cards != null;

    Widget cardForSeat(int seat) {
      return SizedBox(
        width: _cardW,
        height: _cardH,
        child: FittedBox(
          fit: BoxFit.contain,
          child: PlayingCard(
            card: cards?[seat],
            size: CardSize.small,
            faceUp: faceUp,
            back: CardBack.red,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 1,
          height: 40,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: Colors.white.withValues(alpha: 0.22),
          ),
        ),
        Container(
          width: _box,
          height: _box,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: !faceUp
                  ? const Color(0xFFE63946).withValues(alpha: 0.75)
                  : Colors.white.withValues(alpha: 0.18),
              width: !faceUp ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Top — seat 2 (partner)
              Positioned(
                top: 3,
                left: 0,
                right: 0,
                child: Center(child: cardForSeat(2)),
              ),
              // Bottom — seat 0 (you)
              Positioned(
                bottom: 3,
                left: 0,
                right: 0,
                child: Center(child: cardForSeat(0)),
              ),
              // Left — seat 3
              Positioned(
                left: 3,
                top: 0,
                bottom: 0,
                child: Center(child: cardForSeat(3)),
              ),
              // Right — seat 1
              Positioned(
                right: 3,
                top: 0,
                bottom: 0,
                child: Center(child: cardForSeat(1)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
