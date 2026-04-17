import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
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
//  When all 4 cards land, a brief gold flash signals trick won.
// ══════════════════════════════════════════════════════════════════

class TrickAreaWidget extends StatefulWidget {
  const TrickAreaWidget({super.key});

  @override
  State<TrickAreaWidget> createState() => _TrickAreaWidgetState();
}

class _TrickAreaWidgetState extends State<TrickAreaWidget>
    with SingleTickerProviderStateMixin {
  // Must match [PlayingCard] with [CardSize.small]
  static final double _cardW = CardSize.small.width;
  static final double _cardH = CardSize.small.height;

  late final AnimationController _flashCtrl;
  late final Animation<double> _flashOpacity;
  int _prevTrickSize = 0;

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flashOpacity = Tween<double>(begin: 0.0, end: 0.45).animate(
      CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _flashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final trick = game.currentTrick;
    final trickNum = game.trickNumber;
    final isPlaying = game.phase == GamePhase.playing;

    // Trigger flash when trick completes (goes from 4→0 or 3→4→0)
    if (trick.length == 4 && _prevTrickSize < 4) {
      _flashCtrl.forward(from: 0).then((_) => _flashCtrl.reverse());
      HapticFeedback.mediumImpact();
    }
    _prevTrickSize = trick.length;

    return LayoutBuilder(builder: (ctx, box) {
      final areaW = box.maxWidth;
      final areaH = box.maxHeight;

      // Shrink spread on short trick zones so four cards stay inside bounds
      final maxSpreadY =
          ((areaH - _cardH) / 2 - 2).clamp(4.0, 18.0);
      final maxSpreadX =
          ((areaW - _cardW) / 2 - 2).clamp(4.0, 26.0);

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Trick-won flash
          FadeTransition(
            opacity: _flashOpacity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: RadialGradient(
                  colors: [
                    AppColors.goldAccent.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Trick counter (top) — game state, not decoration
          if (isPlaying)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    key: ValueKey('trick-$trickNum'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
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
            ),

          // Mode / trump (bottom)
          if (isPlaying && game.gameModeLabel != '—')
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            _buildTrickCard(
              play,
              areaW,
              areaH,
              maxSpreadX,
              maxSpreadY,
            ),
        ],
      );
    });
  }

  Widget _buildTrickCard(
    CardPlayModel play,
    double areaW,
    double areaH,
    double spreadX,
    double spreadY,
  ) {
    final seat = play.playerIndex;
    final pos = _cardOffset(seat, areaW, areaH, spreadX, spreadY);

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: _AnimatedTrickCard(
        key: ValueKey('t${play.card.suit}-${play.card.rank}-s$seat'),
        play: play,
        seat: seat,
      ),
    );
  }

  Offset _cardOffset(
    int seat,
    double areaW,
    double areaH,
    double spreadX,
    double spreadY,
  ) {
    final cx = (areaW - _cardW) / 2;
    final cy = (areaH - _cardH) / 2;

    switch (seat) {
      case 0:
        return Offset(cx, cy + spreadY);
      case 1:
        return Offset(cx + spreadX, cy);
      case 2:
        return Offset(cx, cy - spreadY);
      case 3:
        return Offset(cx - spreadX, cy);
      default:
        return Offset(cx, cy);
    }
  }

  static String _suitSymbol(dynamic suit) {
    final name = suit.toString().split('.').last;
    switch (name) {
      case 'hearts':
        return '♥';
      case 'diamonds':
        return '♦';
      case 'spades':
        return '♠';
      case 'clubs':
        return '♣';
      default:
        return '';
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
