import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/card_play_model.dart';
import '../../../game/domain/baloot_game_controller.dart' show GamePhase;
import '../../../game/domain/managers/turn_manager.dart' show TrickResult;
import '../game_provider.dart';
import 'designer_engine_trick_zone.dart';

// ══════════════════════════════════════════════════════════════════
//  TRICK AREA — Baloot-dev center motion (throw / impact / collect)
//  wired to live [GameProvider] tricks. Engine rules unchanged.
// ══════════════════════════════════════════════════════════════════

class TrickAreaWidget extends StatefulWidget {
  const TrickAreaWidget({super.key});

  @override
  State<TrickAreaWidget> createState() => _TrickAreaWidgetState();
}

Map<DesignerTrickSeat, List<double>> _emptyPileAngles() => {
      for (final s in DesignerTrickSeat.values) s: <double>[],
    };

/// Won-trick face-down stacks from engine history; [historyForPiles] excludes the
/// trick still animating (overlay + collect) so the pile does not jump early.
void _fillWonTrickPileMaps(
  List<TrickResult> historyForPiles,
  Map<DesignerTrickSeat, int> pilesOut,
  Map<DesignerTrickSeat, List<double>> anglesOut,
) {
  for (final s in DesignerTrickSeat.values) {
    pilesOut[s] = 0;
    (anglesOut[s] ??= <double>[]).clear();
  }
  for (final r in historyForPiles) {
    final seat = designerTrickSeatForPlayer(r.winnerIndex);
    pilesOut[seat] = (pilesOut[seat] ?? 0) + 1;
    final list = anglesOut[seat]!;
    list.add(designerWonTrickPileAngle(seat, list.length));
  }
}

class _TrickAreaWidgetState extends State<TrickAreaWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashCtrl;
  late final Animation<double> _flashOpacity;

  int _prevCompletedTricks = 0;
  List<CardPlayModel>? _overlayPlays;
  DesignerTrickSeat? _collectWinner;
  int _collectAnimTick = 0;
  bool _collectScheduled = false;
  bool _flashedForOverlay = false;
  bool _pendingCollectSchedule = false;

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

  void _onCollectFinished() {
    if (!mounted) return;
    setState(() {
      _overlayPlays = null;
      _collectWinner = null;
      _collectScheduled = false;
      _flashedForOverlay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final trick = game.currentTrick;
    final trickNum = game.trickNumber;
    final isPlaying = game.phase == GamePhase.playing;
    final completed = game.completedTricksCount;

    if (trick.isNotEmpty) {
      _overlayPlays = null;
      _collectWinner = null;
      _collectScheduled = false;
      _flashedForOverlay = false;
      _prevCompletedTricks = completed;
    } else if (completed > _prevCompletedTricks) {
      _prevCompletedTricks = completed;
      final r = game.lastTrickResult;
      if (r != null && r.cards.length == 4) {
        _overlayPlays = List<CardPlayModel>.from(r.cards);
        _collectWinner = designerTrickSeatForPlayer(r.winnerIndex);
        _collectScheduled = false;
      }
    }

    final plays =
        trick.isNotEmpty ? trick : (_overlayPlays ?? const <CardPlayModel>[]);

    if (_overlayPlays != null &&
        _overlayPlays!.length == 4 &&
        _collectWinner != null &&
        !_collectScheduled) {
      _pendingCollectSchedule = true;
    }

    if (_pendingCollectSchedule && !_collectScheduled) {
      _pendingCollectSchedule = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _collectScheduled) return;
        _collectScheduled = true;
        if (!_flashedForOverlay) {
          _flashedForOverlay = true;
          _flashCtrl.forward(from: 0).then((_) => _flashCtrl.reverse());
          HapticFeedback.mediumImpact();
        }
        final collectDelay = completed == 8 ? 4000 : 1000;
        unawaited(Future<void>.delayed(Duration(milliseconds: collectDelay), () {
          if (!mounted) return;
          setState(() => _collectAnimTick++);
        }));
      });
    }

    final entries = <EngineTrickEntry>[
      for (final p in plays)
        EngineTrickEntry(
          seat: designerTrickSeatForPlayer(p.playerIndex),
          card: p.card,
        ),
    ];

    final fullHistory = game.trickHistoryThisRound;
    final historyForPiles = (_overlayPlays != null && fullHistory.isNotEmpty)
        ? fullHistory.sublist(0, fullHistory.length - 1)
        : fullHistory;
    final wonTrickPiles = <DesignerTrickSeat, int>{};
    final wonTrickPileAngles = _emptyPileAngles();
    _fillWonTrickPileMaps(historyForPiles, wonTrickPiles, wonTrickPileAngles);

    return LayoutBuilder(builder: (ctx, box) {
      final areaW = box.maxWidth;
      final areaH = box.maxHeight;
      // Shave a couple px so labels + card stack never fractionally exceed parent.
      final zone = (((areaW < areaH ? areaW : areaH) * 0.92) - 2.0)
          .clamp(1.0, double.infinity);

      return Stack(
        clipBehavior: Clip.none,
        children: [
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
          Center(
            child: SizedBox(
              width: zone,
              height: zone,
              child: DesignerEngineTrickZone(
                zoneSize: zone,
                playedCardsInTrick: entries,
                collectWinnerSeat: _collectWinner,
                collectAnimationTick: _collectAnimTick,
                wonTrickPiles: wonTrickPiles,
                wonTrickPileAngles: wonTrickPileAngles,
                bottomThrowCardIndex: game.lastHumanThrowCardIndex,
                bottomThrowHandCount: game.lastHumanThrowHandCount,
                onCollectAnimationFinished: _onCollectFinished,
              ),
            ),
          ),
        ],
      );
    });
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
