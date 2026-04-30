import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/layout/game_table_layout.dart';
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
  final s = GameTableLayout.handCardSize(GameTableLayout.scale(context));
  return Offset(s.width / 2, s.height / 2);
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

  @override
  Widget build(BuildContext context) {
    final scale = GameTableLayout.scale(context);
    final game = context.watch<GameProvider>();
    final hand = game.playerHand;
    final phase = game.phase;

    if (phase == GamePhase.notStarted) {
      return const SizedBox(height: 8);
    }

    final isPlayPhase = phase == GamePhase.playing;
    final isHumanTurn = game.isHumanTurn;
    final selectedCard = game.selectedCard;
    final sawaReveal = game.isSawaRevealPlaying;
    final openingProjects = game.isOpeningProjectWindow;

    final validCards = isPlayPhase && isHumanTurn && !openingProjects
        ? game.validCards
        : hand;
    final trumpSuit = game.roundState.activeMode == GameMode.hakam
        ? game.roundState.trumpSuit
        : null;

    final screenW = MediaQuery.sizeOf(context).width;
    final bandH = GameTableLayout.handFanBandHeight(scale);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hand.isEmpty)
          const SizedBox(height: 6)
        else
          SizedBox(
            width: screenW,
            height: bandH,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                ignoring: sawaReveal || openingProjects,
                child: Opacity(
                  opacity: sawaReveal
                      ? 0.0
                      : (openingProjects ? 0.85 : 1.0),
                  child: Transform.translate(
                    offset: Offset(0, -4 * scale),
                    child: _DesignerHandFan(
                      scale: scale,
                      cards: hand,
                      selectedCard: selectedCard,
                      validCards: validCards,
                      interactive: isPlayPhase &&
                          isHumanTurn &&
                          !sawaReveal &&
                          !openingProjects,
                      trumpSuit: trumpSuit,
                      // Reduce available width so rotated cards don't overhang screen edges
                      availableWidth: screenW - 40 * scale,
                      onCardTap: (card) {
                        if (!isPlayPhase || !isHumanTurn || openingProjects) {
                          return;
                        }
                        // Tapping ONLY selects (pops up) the card.
                        // To play, the user must drag and drop (or swipe up).
                        game.selectCard(card);
                      },
                      onSwipePlay: (card) {
                        if (!isPlayPhase || !isHumanTurn || openingProjects) {
                          return;
                        }
                        if (validCards.contains(card)) {
                          game.humanPlayCard(card);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Port of designer [`_CardFan`] for `large` + horizontal + face-up.
/// Kammelna-style: first tap pops card up with spring bounce,
/// second tap on same selected valid card plays it.
class _DesignerHandFan extends StatefulWidget {
  const _DesignerHandFan({
    required this.scale,
    required this.cards,
    required this.selectedCard,
    required this.validCards,
    required this.interactive,
    required this.availableWidth,
    required this.onCardTap,
    required this.onSwipePlay,
    this.trumpSuit,
  });

  final double scale;
  final List<CardModel> cards;
  final CardModel? selectedCard;
  final List<CardModel> validCards;
  final bool interactive;
  final double availableWidth;
  final ValueChanged<CardModel> onCardTap;
  final ValueChanged<CardModel> onSwipePlay;
  final Suit? trumpSuit;

  @override
  State<_DesignerHandFan> createState() => _DesignerHandFanState();
}

class _DesignerHandFanState extends State<_DesignerHandFan>
    with SingleTickerProviderStateMixin {
  /// Spring controller — drives the bounce when a card is selected.
  late AnimationController _springCtrl;
  late Animation<double> _springAnim;

  /// Which card index just got the bounce (so only that card bounces).
  int? _bouncingIndex;

  @override
  void initState() {
    super.initState();
    _springCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _springAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -10.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -10.0, end: 4.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 4.0, end: -2.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -2.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
    ]).animate(_springCtrl);
  }

  @override
  void dispose() {
    _springCtrl.dispose();
    super.dispose();
  }

  void _triggerBounce(int index) {
    setState(() => _bouncingIndex = index);
    _springCtrl.forward(from: 0);
  }

  double get _cardWidth => GameTableLayout.handCardSize(widget.scale).width;
  double get _cardHeight => GameTableLayout.handCardSize(widget.scale).height;
  static const double _largeRotation = 0.05;
  double get _arcLift => 14.0 * widget.scale;
  double get _selLift => 46.0 * widget.scale;

  int? get _selectedIndex {
    if (widget.selectedCard == null) return null;
    final i = widget.cards.indexOf(widget.selectedCard!);
    if (i < 0) return null;
    return i;
  }

  double _fitLargeOverlap(int cardCount) {
    if (cardCount <= 1) return 64.0 * widget.scale;
    final usableWidth =
        widget.availableWidth.clamp(_cardWidth, double.infinity);
    final fittedOverlap = (usableWidth - _cardWidth) / (cardCount - 1);
    return fittedOverlap.clamp(28.0 * widget.scale, 56.0 * widget.scale);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.cards.length;
    if (n == 0) return const SizedBox.shrink();

    final overlap = _fitLargeOverlap(n);
    final totalExtent = _cardWidth + ((n - 1) * overlap);
    final sel = _selectedIndex;

    return AnimatedBuilder(
      animation: _springAnim,
      builder: (context, _) {
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

              final isSelected = sel == index;
              final isBouncing = _bouncingIndex == index;
              final cardModel = widget.cards[index];
              final isValid =
                  !widget.interactive || widget.validCards.contains(cardModel);
              final isTrump =
                  widget.trumpSuit != null &&
                  cardModel.suit == widget.trumpSuit;

              final cardWidget = PlayingCard(
                card: cardModel,
                size: CardSize.hand,
                width: _cardWidth,
                height: _cardHeight,
                faceUp: true,
                selected: isSelected,
                suppressSelectionOffset: true,
                dimmed: !isValid,
                onTap: null,
              );

              // Trump highlight: subtle golden border glow
              final highlightedCard = isTrump
                  ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 0.5,
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                      ),
                      child: cardWidget,
                    )
                  : cardWidget;

              // Extra bounce offset on top of the selection lift
              final bounceExtra =
                  (isBouncing && _springCtrl.isAnimating)
                      ? _springAnim.value * widget.scale
                      : 0.0;

              final cardFace = AnimatedScale(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                scale: isSelected ? 1.18 : 1.0,
                alignment: Alignment.bottomCenter,
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.bottomCenter,
                  turns: ((index - (n - 1) / 2) * _largeRotation) / (2 * 3.14159),
                  child: highlightedCard,
                ),
              );

              final tappable = Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: widget.interactive
                    ? (event) {
                        final card = cardModel;
                        // Always select (pop up) with bounce instantly on touch.
                        _triggerBounce(index);
                        widget.onCardTap(card);
                      }
                    : null,
                child: cardFace,
              );

              final draggableChild = (widget.interactive && isValid)
                  ? Draggable<CardModel>(
                      data: cardModel,
                      maxSimultaneousDrags: 1,
                      dragAnchorStrategy: _handCardCenterDragAnchor,
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
                              width: _cardWidth,
                              height: _cardHeight,
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
                        if (v.pixelsPerSecond.dy < -90 * widget.scale &&
                            v.pixelsPerSecond.dy.abs() >=
                                v.pixelsPerSecond.dx.abs()) {
                          widget.onSwipePlay(cardModel);
                        }
                      },
                      child: tappable,
                    )
                  : tappable;

              // Combine: arc lift + selection lift + spring bounce
              final totalLift =
                  (isSelected ? -_selLift : 0.0) + largeArcLift + bounceExtra;

              final cardNode = AnimatedSlide(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                offset: Offset(0, totalLift / _cardHeight),
                child: draggableChild,
              );

              return AnimatedPositioned(
                key: ValueKey(widget.cards[index]),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                left: offset,
                top: 0,
                child: cardNode,
              );
            }),
          ),
        );
      },
    );
  }
}
