import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/card_model.dart';
import '../../domain/baloot_game_controller.dart' show GamePhase;
import '../game_provider.dart';
import 'playing_card.dart';

/// [pointerDragAnchorStrategy] pins the feedback’s **top-left** to the touch, so the
/// card sits awkwardly beside the finger. This pins the **center** of the hand-sized
/// feedback card to the fingertip instead.
Offset _handCardCenterDragAnchor(
  Draggable<Object> draggable,
  BuildContext context,
  Offset position,
) {
  return Offset(
    CardSize.hand.width / 2,
    CardSize.hand.height / 2,
  );
}

// ══════════════════════════════════════════════════════════════════
//  HUMAN HAND WIDGET  (Seat 0 — bottom player)
//
//  Layout matches designer [`_BottomSeat`] + [`_CardFan`] `large`:
//  • Card size from [CardSize.hand], overlap from `_fitLargeOverlap`
//  • Parabolic arc (center lifted), rotation 0.05 rad per step from center
//  • Z-order: left → right (rightmost on top)
//  • Selected: scale 1.18, extra lift (designer values)
//  • Tap to play (valid) or select (invalid); drag valid card onto table to play;
//    quick flick upward still plays if the drag is not accepted by a target
// ══════════════════════════════════════════════════════════════════

class HumanHandWidget extends StatelessWidget {
  const HumanHandWidget({super.key});

  /// Same as designer [`_BottomSeat.largeCardHeight`].
  /// Room for hand arc, selection lift (−46), and drag feedback without
  /// painting outside the band (avoids rare sub-pixel Column overflows).
  static const double _largeBandHeight = 186.0;

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
                  // Reduce available width so rotated cards don't overhang screen edges
                  availableWidth: screenW - 40,
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

  static double get _cardWidth => CardSize.hand.width;
  static double get _cardHeight => CardSize.hand.height;
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
    return fittedOverlap.clamp(28.0, 56.0);
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

          final cardModel = cards[index];
          final isValid = !interactive || validCards.contains(cardModel);

          final cardFace = AnimatedScale(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            scale: isSelected ? 1.18 : 1.0,
            alignment: Alignment.bottomCenter,
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              turns: ((index - (n - 1) / 2) * _largeRotation) / (2 * 3.14159),
              child: PlayingCard(
                card: cardModel,
                size: CardSize.hand,
                faceUp: true,
                selected: isSelected,
                suppressSelectionOffset: true,
                dimmed: !isValid,
                onTap: null,
              ),
            ),
          );

          final tappable = GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: interactive ? () => onCardTap(cardModel) : null,
            child: cardFace,
          );

          final draggableChild = (interactive && isValid)
              ? Draggable<CardModel>(
                  data: cardModel,
                  maxSimultaneousDrags: 1,
                  dragAnchorStrategy: _handCardCenterDragAnchor,
                  // Upright feedback matches anchor math (center = half of hand size).
                  feedback: Material(
                    elevation: 10,
                    shadowColor: Colors.black54,
                    borderRadius: BorderRadius.circular(11),
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.96,
                      child: SizedBox(
                        width: _cardWidth,
                        height: _cardHeight,
                        child: PlayingCard(
                          card: cardModel,
                          size: CardSize.hand,
                          faceUp: true,
                          selected: isSelected,
                          suppressSelectionOffset: true,
                          dimmed: false,
                          onTap: null,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.38,
                    child: cardFace,
                  ),
                  onDragEnd: (details) {
                    if (details.wasAccepted) return;
                    final v = details.velocity;
                    if (v.pixelsPerSecond.dy < -90 &&
                        v.pixelsPerSecond.dy.abs() >=
                            v.pixelsPerSecond.dx.abs()) {
                      onSwipePlay(cardModel);
                    }
                  },
                  child: tappable,
                )
              : tappable;

          final cardNode = AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            offset: Offset(
              0,
              ((isSelected ? -46.0 : 0.0) + largeArcLift) / _cardHeight,
            ),
            child: draggableChild,
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
