import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/card_model.dart';
import '../../domain/baloot_game_controller.dart' show GamePhase;
import '../game_provider.dart';
import 'playing_card.dart';

// ══════════════════════════════════════════════════════════════════
//  HUMAN HAND WIDGET  (Seat 0 — bottom player)
//
//  Layout matches designer [`_BottomSeat`] + [`_CardFan`] `large`:
//  • Card size 123.5 × 163.4, overlap from `_fitLargeOverlap`
//  • Parabolic arc (center lifted), rotation 0.05 rad per step from center
//  • Z-order: left → right (rightmost on top)
//  • Selected: scale 1.18, extra lift (designer values)
//  • Tap / swipe-up to play when interactive
// ══════════════════════════════════════════════════════════════════

class HumanHandWidget extends StatelessWidget {
  const HumanHandWidget({super.key});

  /// Same as designer [`_BottomSeat.largeCardHeight`].
  static const double _largeBandHeight = 172.0;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final hand = game.playerHand;
    final phase = game.phase;

    if (phase == GamePhase.notStarted) {
      return const SizedBox(height: 8);
    }

    final isPlayPhase = phase == GamePhase.playing;
    final isHumanTurn = game.isHumanTurn;
    final selectedCard = game.selectedCard;
    final validCards = isPlayPhase && isHumanTurn ? game.validCards : hand;

    final screenW = MediaQuery.sizeOf(context).width;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hand.isEmpty)
          const SizedBox(height: 6)
        else
          SizedBox(
            width: screenW,
            height: _largeBandHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: const Offset(0, -4),
                child: _DesignerHandFan(
                  cards: hand,
                  selectedCard: selectedCard,
                  validCards: validCards,
                  interactive: isPlayPhase && isHumanTurn,
                  availableWidth: screenW,
                  onCardTap: (card) {
                    if (!isPlayPhase || !isHumanTurn) return;
                    if (validCards.contains(card)) {
                      game.humanPlayCard(card);
                    } else {
                      game.selectCard(card);
                    }
                  },
                  onSwipePlay: (card) {
                    if (!isPlayPhase || !isHumanTurn) return;
                    if (validCards.contains(card)) {
                      game.humanPlayCard(card);
                    }
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Port of designer [`_CardFan`] for `large` + horizontal + face-up.
class _DesignerHandFan extends StatelessWidget {
  const _DesignerHandFan({
    required this.cards,
    required this.selectedCard,
    required this.validCards,
    required this.interactive,
    required this.availableWidth,
    required this.onCardTap,
    required this.onSwipePlay,
  });

  final List<CardModel> cards;
  final CardModel? selectedCard;
  final List<CardModel> validCards;
  final bool interactive;
  final double availableWidth;
  final ValueChanged<CardModel> onCardTap;
  final ValueChanged<CardModel> onSwipePlay;

  static const double _cardWidth = 123.5;
  static const double _cardHeight = 163.4;
  static const double _largeRotation = 0.05;
  static const double _arcLift = 14.0;

  int? get _selectedIndex {
    if (selectedCard == null) return null;
    final i = cards.indexOf(selectedCard!);
    if (i < 0) return null;
    return i;
  }

  double _fitLargeOverlap(int cardCount) {
    if (cardCount <= 1) return 64.0;
    final usableWidth =
        availableWidth.clamp(_cardWidth, double.infinity);
    final fittedOverlap = (usableWidth - _cardWidth) / (cardCount - 1);
    return fittedOverlap.clamp(36.0, 64.0);
  }

  @override
  Widget build(BuildContext context) {
    final n = cards.length;
    if (n == 0) return const SizedBox.shrink();

    final overlap = _fitLargeOverlap(n);
    final totalExtent = _cardWidth + ((n - 1) * overlap);

    final sel = _selectedIndex;

    return SizedBox(
      width: totalExtent,
      height: _cardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(n, (index) {
          final offset = index * overlap;
          var dragUpDistance = 0.0;

          final center = (n - 1) / 2;
          final distanceFromCenter = (index - center).abs();
          final maxDistance = center == 0 ? 1.0 : center;
          final normalizedDist =
              (distanceFromCenter / maxDistance).clamp(0.0, 1.0);
          final largeArcLift =
              -(1.0 - normalizedDist * normalizedDist) * _arcLift;

          // Match designer [`_CardFan`]: selected gets -46 extra lift; others
          // only use the parabolic arc.
          final isSelected = sel == index;

          final isValid = !interactive || validCards.contains(cards[index]);

          final cardNode = Transform.translate(
            offset: Offset(
              0,
              (isSelected ? -46.0 : 0.0) + largeArcLift,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: interactive
                  ? () => onCardTap(cards[index])
                  : null,
              onPanStart: interactive
                  ? (_) {
                      dragUpDistance = 0;
                    }
                  : null,
              onPanUpdate: interactive
                  ? (details) {
                      dragUpDistance += -details.delta.dy;
                    }
                  : null,
              onPanEnd: interactive
                  ? (details) {
                      final isPlayableSwipe = details
                                  .velocity.pixelsPerSecond.dy <
                              -90 ||
                          dragUpDistance > 26;
                      if (isPlayableSwipe) {
                        onSwipePlay(cards[index]);
                      }
                    }
                  : null,
              child: Transform.scale(
                scale: isSelected ? 1.18 : 1.0,
                alignment: Alignment.bottomCenter,
                child: Transform.rotate(
                  alignment: Alignment.bottomCenter,
                  angle: (index - (n - 1) / 2) * _largeRotation,
                  child: PlayingCard(
                    card: cards[index],
                    size: CardSize.hand,
                    faceUp: true,
                    selected: isSelected,
                    suppressSelectionOffset: true,
                    dimmed: !isValid,
                    onTap: null,
                  ),
                ),
              ),
            ),
          );

          return AnimatedPositioned(
            key: ValueKey(cards[index]),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: offset,
            top: 0,
            child: cardNode,
          );
        }),
      ),
    );
  }
}
