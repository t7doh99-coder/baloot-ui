import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/layout/game_table_layout.dart';
import '../../../../data/models/card_model.dart';
import '../../domain/baloot_game_controller.dart' show GamePhase;
import '../game_provider.dart';
import 'playing_card.dart';

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

    // During the project declaration in trick 1, the human can still play valid cards.
    final validCards = isPlayPhase && isHumanTurn
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
                ignoring: sawaReveal,
                child: Transform.translate(
                    offset: Offset(0, -4 * scale),
                    child: _DesignerHandFan(
                      scale: scale,
                      cards: hand,
                      selectedCard: selectedCard,
                      validCards: validCards,
                      interactive: isPlayPhase && !sawaReveal,
                      canPlay: isPlayPhase && isHumanTurn && !sawaReveal,
                      trumpSuit: trumpSuit,
                      // Reduce available width so rotated cards don't overhang screen edges
                      availableWidth: screenW - 40 * scale,
                      onCardTap: (card) {
                        if (!isPlayPhase) return;
                        
                        // If the card is already selected, tap again to play it (Method 2)
                        if (game.selectedCard == card) {
                          if (validCards.contains(card) && isHumanTurn) {
                            game.humanPlayCard(card);
                          }
                        } else {
                          // Otherwise, just select it
                          game.selectCard(card);
                        }
                      },
                      onSwipePlay: (card) {
                        if (!isPlayPhase || !isHumanTurn) {
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
        ],
      );
  }
}

/// Port of designer [`_CardFan`] for `large` + horizontal + face-up.
/// Standard-style: first tap pops card up with spring bounce,
/// second tap on same selected valid card plays it.
class _DesignerHandFan extends StatefulWidget {
  const _DesignerHandFan({
    required this.scale,
    required this.cards,
    required this.selectedCard,
    required this.validCards,
    required this.interactive,
    required this.canPlay,
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
  final bool canPlay;
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

  /// Active direct-pointer drag tracking (0ms response, zero gesture-arena delay)
  int? _activeDragIndex;
  Offset? _dragStartPos;
  final ValueNotifier<Offset> _dragOffsetNotifier = ValueNotifier<Offset>(Offset.zero);
  VelocityTracker? _velocityTracker;
  CardModel? _prevSelectedBeforeTouch;

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
  void didUpdateWidget(_DesignerHandFan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.cards, widget.cards)) {
      _bouncingIndex = null;
      if (_springCtrl.isAnimating) _springCtrl.stop();
      _activeDragIndex = null;
      _dragOffsetNotifier.value = Offset.zero;
    }
  }

  @override
  void dispose() {
    _springCtrl.dispose();
    _dragOffsetNotifier.dispose();
    super.dispose();
  }

  void _triggerBounce(int index) {
    setState(() => _bouncingIndex = index);
    _springCtrl.forward(from: 0);
  }

  double get _cardWidth => GameTableLayout.handCardSize(widget.scale).width;
  double get _cardHeight => GameTableLayout.handCardSize(widget.scale).height;
  static const double _largeRotation = 0.065;
  double get _arcLift => 20.0 * widget.scale;
  double get _selLift => 56.0 * widget.scale;

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

  void _handlePointerDown(int index, CardModel card, PointerDownEvent e) {
    if (!widget.interactive) return;
    _activeDragIndex = index;
    _dragStartPos = e.position;
    _dragOffsetNotifier.value = Offset.zero;
    _velocityTracker = VelocityTracker.withKind(e.kind);
    _velocityTracker?.addPosition(e.timeStamp, e.position);
    _prevSelectedBeforeTouch = widget.selectedCard;

    // Instant haptic feedback on touch down
    HapticFeedback.selectionClick();

    // Select card immediately at 0ms touch
    if (widget.selectedCard != card) {
      widget.onCardTap(card);
    }
    _triggerBounce(index);
    setState(() {}); // Bring this card to the top of the Stack immediately
  }

  void _handlePointerMove(int index, PointerMoveEvent e) {
    if (_activeDragIndex != index || _dragStartPos == null) return;
    _velocityTracker?.addPosition(e.timeStamp, e.position);
    final delta = e.position - _dragStartPos!;
    // Upward tracking is 1:1, horizontal is slightly dampened, downward resists
    _dragOffsetNotifier.value = Offset(
      delta.dx * 0.9,
      delta.dy < 0 ? delta.dy : delta.dy * 0.25,
    );
  }

  void _handlePointerUp(int index, CardModel card, bool isValid, PointerUpEvent e) {
    if (_activeDragIndex != index) return;
    _velocityTracker?.addPosition(e.timeStamp, e.position);
    final velocity = _velocityTracker?.getVelocity() ?? Velocity.zero;
    final delta = _dragOffsetNotifier.value;

    final isFlickUp = velocity.pixelsPerSecond.dy < -140 * widget.scale;
    final isDraggedUp = delta.dy < -42 * widget.scale;
    final isTap = delta.distance < 12.0;

    if ((isFlickUp || isDraggedUp) && widget.canPlay && isValid) {
      // Immediate flick or drag release upwards -> PLAY CARD!
      HapticFeedback.mediumImpact();
      widget.onSwipePlay(card);
    } else if (isTap) {
      // Tap behavior: if card was ALREADY selected before touch, play it
      if (_prevSelectedBeforeTouch == card && widget.canPlay && isValid) {
        HapticFeedback.mediumImpact();
        widget.onSwipePlay(card);
      }
    }

    _dragOffsetNotifier.value = Offset.zero;
    setState(() {
      _activeDragIndex = null;
      _dragStartPos = null;
      _velocityTracker = null;
    });
  }

  void _handlePointerCancel(int index) {
    if (_activeDragIndex == index) {
      _dragOffsetNotifier.value = Offset.zero;
      setState(() {
        _activeDragIndex = null;
        _dragStartPos = null;
        _velocityTracker = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.cards.length;
    if (n == 0) return const SizedBox.shrink();

    final overlap = _fitLargeOverlap(n);
    final totalExtent = _cardWidth + ((n - 1) * overlap);
    final sel = _selectedIndex;

    // Display order: active drag index renders last (on top of all others),
    // followed by the selected card, followed by the natural left-to-right order.
    final displayIndices = List.generate(n, (i) => i);
    displayIndices.sort((a, b) {
      if (a == _activeDragIndex) return 1;
      if (b == _activeDragIndex) return -1;
      if (a == sel) return 1;
      if (b == sel) return -1;
      return a.compareTo(b);
    });

    return AnimatedBuilder(
      animation: _springAnim,
      builder: (context, _) {
        return SizedBox(
          width: totalExtent,
          height: _cardHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: displayIndices.map((index) {
              final offset = index * overlap;

              final center = (n - 1) / 2;
              final distanceFromCenter = (index - center).abs();
              final maxDistance = center == 0 ? 1.0 : center;
              final normalizedDist =
                  (distanceFromCenter / maxDistance).clamp(0.0, 1.0);
              final largeArcLift =
                  -(1.0 - normalizedDist * normalizedDist) * _arcLift;

              final isSelected = sel == index;
              final isBeingDragged = _activeDragIndex == index;
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
                selected: isSelected || isBeingDragged,
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
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutBack,
                scale: (isBeingDragged || isSelected) ? 1.16 : 1.0,
                alignment: Alignment.bottomCenter,
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.bottomCenter,
                  turns: ((index - (n - 1) / 2) * _largeRotation) / (2 * 3.14159),
                  child: RepaintBoundary(child: highlightedCard),
                ),
              );

              final totalLift =
                  (isSelected ? -_selLift : 0.0) + largeArcLift + bounceExtra;

              final positionedBase = AnimatedSlide(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutBack,
                offset: Offset(0, totalLift / _cardHeight),
                child: cardFace,
              );

              // Dynamic finger tracking: transforms ONLY the dragged card without full rebuilds
              final draggableCard = ValueListenableBuilder<Offset>(
                valueListenable: _dragOffsetNotifier,
                builder: (context, dragOffset, child) {
                  final activeOffset = isBeingDragged ? dragOffset : Offset.zero;
                  return Transform.translate(
                    offset: activeOffset,
                    child: child,
                  );
                },
                child: positionedBase,
              );

              final interactiveCard = Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _handlePointerDown(index, cardModel, e),
                onPointerMove: (e) => _handlePointerMove(index, e),
                onPointerUp: (e) => _handlePointerUp(index, cardModel, isValid, e),
                onPointerCancel: (_) => _handlePointerCancel(index),
                child: draggableCard,
              );

              return AnimatedPositioned(
                key: ValueKey(widget.cards[index]),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutBack,
                left: offset,
                top: 0,
                child: interactiveCard,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
