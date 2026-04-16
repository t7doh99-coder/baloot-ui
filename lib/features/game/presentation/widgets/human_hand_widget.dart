import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/card_model.dart';
import '../../domain/baloot_game_controller.dart' show GamePhase;
import '../game_provider.dart';
import 'playing_card.dart';
import 'player_seat_widget.dart' show PlayerAvatarRing;

// ══════════════════════════════════════════════════════════════════
//  HUMAN HAND WIDGET  (Seat 0 — bottom player)
//
//  Full-width curved arc of face-up cards, like holding cards
//  in your hand. Each card is rotated around a pivot point far
//  below the screen, creating a natural hand-held curve.
//
//  • Cards fill the entire bottom section
//  • Each card has a slight rotation based on its position
//  • Cards in the centre sit higher than those on the edges
//  • Selected card rises 16px with gold glow
//  • Tapping plays the card in the playing phase
// ══════════════════════════════════════════════════════════════════

class HumanHandWidget extends StatelessWidget {
  const HumanHandWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final game  = context.watch<GameProvider>();
    final hand  = game.playerHand;
    final phase = game.phase;

    if (phase == GamePhase.notStarted) {
      return const SizedBox(height: 8);
    }

    final isPlayPhase  = phase == GamePhase.playing;
    final isHumanTurn  = game.isHumanTurn;
    final selectedCard = game.selectedCard;
    final validCards   = isPlayPhase && isHumanTurn ? game.validCards : hand;

    final screenW = MediaQuery.sizeOf(context).width;

    const teamColor = Color(0xFF28802E); // seat 0 — team A

    // Tighter layout on short screens to avoid Column overflow vs play area.
    final handH = MediaQuery.sizeOf(context).height < 700 ? 104.0 : 112.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: PlayerAvatarRing(
            seatIndex: 0,
            name: game.playerName(0),
            isActive: game.isHumanTurn,
            isDealer: game.dealerIndex == 0,
            isBuyer: game.buyerIndex == 0,
            teamColor: teamColor,
            timerSecs: game.turnTimerSeconds,
            avatarDiameter: 40,
          ),
        ),

        // Turn indicator + Play button
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: (isPlayPhase && isHumanTurn && selectedCard != null)
              ? Padding(
                  key: const ValueKey('play'),
                  padding: const EdgeInsets.only(bottom: 2),
                  child: _PlayButton(onTap: () => game.playSelectedCard()),
                )
              : (isPlayPhase && isHumanTurn)
                  ? const Padding(
                      key: ValueKey('turn'),
                      padding: EdgeInsets.only(bottom: 2),
                      child: _TurnIndicator(),
                    )
                  : const SizedBox(key: ValueKey('no-play'), height: 2),
        ),

        // Curved card fan (may be empty briefly between phases)
        if (hand.isEmpty)
          const SizedBox(height: 6)
        else
          SizedBox(
            width: screenW,
            height: handH,
            child: _CurvedHand(
              hand: hand,
              selectedCard: selectedCard,
              validCards: validCards,
              interactive: isPlayPhase && isHumanTurn,
              onCardTap: (card) => game.selectCard(card),
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  CURVED HAND  — arc layout engine
// ══════════════════════════════════════════════════════════════════

class _CurvedHand extends StatelessWidget {
  final List<CardModel> hand;
  final CardModel? selectedCard;
  final List<CardModel> validCards;
  final bool interactive;
  final ValueChanged<CardModel> onCardTap;

  const _CurvedHand({
    required this.hand,
    required this.selectedCard,
    required this.validCards,
    required this.interactive,
    required this.onCardTap,
  });

  // The arc radius — larger = flatter curve
  static const double _arcRadius = 600.0;
  // Total angle sweep of the fan (in radians)
  static const double _maxSweep = 0.38; // ~22 degrees total

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final areaW = constraints.maxWidth;
      final areaH = constraints.maxHeight;

      // Pivot point — far below the bottom centre of the area
      final pivotX = areaW / 2;
      final pivotY = areaH + _arcRadius - 40;

      final n = hand.length;
      // Sweep is proportional to card count, capped at _maxSweep
      final sweep = min(_maxSweep, 0.06 * n);
      final startAngle = -pi / 2 - sweep / 2;

      return Stack(
        clipBehavior: Clip.none,
        children: List.generate(n, (i) {
          final t = n > 1 ? i / (n - 1) : 0.5;
          final angle = startAngle + t * sweep;

          final card = hand[i];
          final isSelected = selectedCard == card;
          final isValid = !interactive || validCards.contains(card);

          // Position on arc
          final cx = pivotX + _arcRadius * cos(angle);
          final cy = pivotY + _arcRadius * sin(angle);

          // Rotation for this card (tangent to arc)
          final rotation = angle + pi / 2;

          // Selected card lifts up
          final liftY = isSelected ? -18.0 : 0.0;

          return Positioned(
            left: cx - CardSize.medium.width / 2,
            top:  cy - CardSize.medium.height + liftY,
            child: _ArcCard(
              key: ValueKey(card),
              card: card,
              rotation: rotation,
              isSelected: isSelected,
              dimmed: !isValid,
              onTap: interactive && isValid ? () => onCardTap(card) : null,
            ),
          );
        }),
      );
    });
  }
}

// ── Single card in the arc ─────────────────────────────────────────

class _ArcCard extends StatefulWidget {
  final CardModel card;
  final double rotation;
  final bool isSelected;
  final bool dimmed;
  final VoidCallback? onTap;

  const _ArcCard({
    super.key,
    required this.card,
    required this.rotation,
    required this.isSelected,
    this.dimmed = false,
    required this.onTap,
  });

  @override
  State<_ArcCard> createState() => _ArcCardState();
}

class _ArcCardState extends State<_ArcCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dealCtrl;
  late final Animation<double> _dealSlide;
  late final Animation<double> _dealFade;

  @override
  void initState() {
    super.initState();
    _dealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _dealSlide = Tween<double>(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(parent: _dealCtrl, curve: Curves.easeOutCubic),
    );
    _dealFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dealCtrl, curve: Curves.easeIn),
    );
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _dealCtrl.forward();
    });
  }

  @override
  void dispose() {
    _dealCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dealCtrl,
      builder: (ctx, child) {
        return Transform.translate(
          offset: Offset(0, _dealSlide.value),
          child: Opacity(
            opacity: _dealFade.value,
            child: Transform.rotate(
              angle: widget.rotation,
              alignment: Alignment.bottomCenter,
              child: PlayingCard(
                card: widget.card,
                size: CardSize.medium,
                faceUp: true,
                selected: widget.isSelected,
                dimmed: widget.dimmed,
                onTap: widget.onTap,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Turn indicator ─────────────────────────────────────────────────

class _TurnIndicator extends StatefulWidget {
  const _TurnIndicator();

  @override
  State<_TurnIndicator> createState() => _TurnIndicatorState();
}

class _TurnIndicatorState extends State<_TurnIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.5, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.goldAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.goldAccent.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          'Your Turn — tap a card',
          style: TextStyle(
            color: AppColors.goldAccent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Play button ────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD4AF37), Color(0xFFFFE066)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldAccent.withValues(alpha: 0.45),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'Play',
          style: TextStyle(
            color: Color(0xFF3D2518),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontFamily: 'Tajawal',
            height: 1,
          ),
        ),
      ),
    );
  }
}
