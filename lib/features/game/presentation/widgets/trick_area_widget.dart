import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/card_play_model.dart';
import '../../../game/domain/baloot_game_controller.dart' show GamePhase;
import '../game_provider.dart';
import 'playing_card.dart';

// ══════════════════════════════════════════════════════════════════
//  TRICK AREA — the 4-card play zone in the center of the table
//
//  Layout (relative to center):
//
//          [seat 2]        ← top/partner
//    [seat 3]    [seat 1]  ← left / right
//          [seat 0]        ← bottom/you
//
//  Each card slides in from the player's direction when played.
// ══════════════════════════════════════════════════════════════════

class TrickAreaWidget extends StatelessWidget {
  const TrickAreaWidget({super.key});

  static const _cardW = 44.0;
  static const _cardH = 62.0;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final trick = game.currentTrick;
    final trickNum = game.trickNumber;
    final isPlaying = game.phase == GamePhase.playing;

    return LayoutBuilder(builder: (ctx, box) {
      final areaW = box.maxWidth;
      final areaH = box.maxHeight;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Trick counter pill (top-center)
          if (isPlaying)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Center(
                child: Container(
                  key: ValueKey('trick-$trickNum'),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Trick $trickNum / 8',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // Mode / trump indicator
          if (isPlaying && game.gameModeLabel != '—')
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    game.trumpSuit != null
                        ? '${game.gameModeLabel} ${_suitSymbol(game.trumpSuit!)}'
                        : game.gameModeLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // Played cards — each positioned by seat
          for (final play in trick)
            _buildTrickCard(play, areaW, areaH, trickNum, trick.length),
        ],
      );
    });
  }

  Widget _buildTrickCard(
      CardPlayModel play, double areaW, double areaH,
      int trickNum, int trickSize) {
    final seat = play.playerIndex;
    final pos = _cardOffset(seat, areaW, areaH);

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: _AnimatedTrickCard(
        key: ValueKey('t$trickNum-s$seat'),
        play: play,
        seat: seat,
      ),
    );
  }

  Offset _cardOffset(int seat, double areaW, double areaH) {
    final cx = (areaW - _cardW) / 2;
    final cy = (areaH - _cardH) / 2;
    const spreadX = 26.0;
    const spreadY = 18.0;

    switch (seat) {
      case 0: return Offset(cx, cy + spreadY);        // below center
      case 1: return Offset(cx + spreadX, cy);         // right of center
      case 2: return Offset(cx, cy - spreadY);         // above center
      case 3: return Offset(cx - spreadX, cy);         // left of center
      default: return Offset(cx, cy);
    }
  }

  static String _suitSymbol(dynamic suit) {
    final name = suit.toString().split('.').last;
    switch (name) {
      case 'hearts':   return '♥';
      case 'diamonds': return '♦';
      case 'spades':   return '♠';
      case 'clubs':    return '♣';
      default:         return '';
    }
  }
}

// ══════════════════════════════════════════════════════════════════
//  ANIMATED TRICK CARD — slides in from player's direction
// ══════════════════════════════════════════════════════════════════

class _AnimatedTrickCard extends StatefulWidget {
  final CardPlayModel play;
  final int seat;

  const _AnimatedTrickCard({
    super.key,
    required this.play,
    required this.seat,
  });

  @override
  State<_AnimatedTrickCard> createState() => _AnimatedTrickCardState();
}

class _AnimatedTrickCardState extends State<_AnimatedTrickCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final begin = _beginOffset(widget.seat);
    _slide = Tween<Offset>(begin: begin, end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _scale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
  }

  Offset _beginOffset(int seat) {
    switch (seat) {
      case 0: return const Offset(0, 2.0);   // from bottom
      case 1: return const Offset(2.0, 0);   // from right
      case 2: return const Offset(0, -2.0);  // from top
      case 3: return const Offset(-2.0, 0);  // from left
      default: return Offset.zero;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: PlayingCard(
            card: widget.play.card,
            size: CardSize.small,
            faceUp: true,
          ),
        ),
      ),
    );
  }
}
