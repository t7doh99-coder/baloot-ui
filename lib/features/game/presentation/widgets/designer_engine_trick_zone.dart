import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../data/models/card_model.dart';
import 'playing_card.dart' as pc;

/// Seat layout matches engine: 0 bottom, 1 right, 2 top, 3 left.
enum DesignerTrickSeat { top, left, right, bottom }

DesignerTrickSeat designerTrickSeatForPlayer(int playerIndex) {
  switch (playerIndex & 3) {
    case 0:
      return DesignerTrickSeat.bottom;
    case 1:
      return DesignerTrickSeat.right;
    case 2:
      return DesignerTrickSeat.top;
    case 3:
      return DesignerTrickSeat.left;
    default:
      return DesignerTrickSeat.bottom;
  }
}

/// Inverse of [designerTrickSeatForPlayer] (bottom→0, right→1, top→2, left→3).
int playerIndexForDesignerTrickSeat(DesignerTrickSeat seat) {
  switch (seat) {
    case DesignerTrickSeat.bottom:
      return 0;
    case DesignerTrickSeat.right:
      return 1;
    case DesignerTrickSeat.top:
      return 2;
    case DesignerTrickSeat.left:
      return 3;
  }
}

/// Base rotation for face-down won-trick stacks (matches designer_table_test_screen).
const Map<DesignerTrickSeat, double> kDesignerWinnerPileBaseAngles = {
  DesignerTrickSeat.right: 1.22173, // 70deg
  DesignerTrickSeat.left: 1.91986, // 110deg
  DesignerTrickSeat.bottom: 0.10472, // 6deg
  DesignerTrickSeat.top: -0.10472, // -6deg
};

/// Angle for the i-th card (0-based) in a seat's won pile — same wobble as designer test UI.
double designerWonTrickPileAngle(DesignerTrickSeat seat, int pileCardIndex) {
  const wobbleSteps = [0.0, 0.52, -0.52, 1.05, -1.05, 0.30, -0.30];
  final base = kDesignerWinnerPileBaseAngles[seat] ?? 0.0;
  final wobble = wobbleSteps[pileCardIndex % wobbleSteps.length];
  return base + wobble;
}

const CardModel _kPilePlaceholderCard = CardModel(
  suit: Suit.spades,
  rank: Rank.ace,
);

/// One card on the table from a given seat (Baloot-dev trick motion).
class EngineTrickEntry {
  const EngineTrickEntry({
    required this.seat,
    required this.card,
  });

  final DesignerTrickSeat seat;
  final CardModel card;
}

/// Settled trick layout — matches designer [`_CenterTrickZone`]: each seat has a
/// base offset + strong tilt; repeated plays from the same seat nudge (+1.6, −1.2)
/// and angle +0.004. Z-order is **throw order** (first card bottom, last on top).
class _CenterTrickLayout {
  _CenterTrickLayout._();

  static const Map<DesignerTrickSeat, Offset> _offsets = {
    DesignerTrickSeat.top: Offset(0, -70),
    DesignerTrickSeat.left: Offset(-34, -30),
    DesignerTrickSeat.right: Offset(36, -29),
    DesignerTrickSeat.bottom: Offset(0, 0),
  };

  static const Map<DesignerTrickSeat, double> _angles = {
    DesignerTrickSeat.right: 1.22173, // ~70°
    DesignerTrickSeat.left: 1.91986, // ~110°
    DesignerTrickSeat.bottom: 0.10472, // ~6°
    DesignerTrickSeat.top: -0.10472, // ~−6°
  };

  static int _seatPlayIndex(List<EngineTrickEntry> plays, int globalIndex) {
    final seat = plays[globalIndex].seat;
    var count = 0;
    for (var i = 0; i <= globalIndex; i++) {
      if (plays[i].seat == seat) {
        if (i == globalIndex) return count;
        count++;
      }
    }
    return count;
  }

  static Offset offsetFor(List<EngineTrickEntry> plays, int globalIndex) {
    if (plays.isEmpty || globalIndex < 0 || globalIndex >= plays.length) {
      return Offset.zero;
    }
    final seat = plays[globalIndex].seat;
    final idx = _seatPlayIndex(plays, globalIndex);
    final base = _offsets[seat] ?? Offset.zero;
    return Offset(base.dx + idx * 1.6, base.dy - idx * 1.2);
  }

  static double angleFor(List<EngineTrickEntry> plays, int globalIndex) {
    if (plays.isEmpty || globalIndex < 0 || globalIndex >= plays.length) {
      return 0.0;
    }
    final seat = plays[globalIndex].seat;
    final idx = _seatPlayIndex(plays, globalIndex);
    final base = _angles[seat] ?? 0.0;
    return base + idx * 0.004;
  }
}

/// Won-trick piles: portrait cards fanned with a landscape cap (Majlis reference).
/// Collect flight + shrink still use [`_startCollectAnimationIfPossible`]; this is
/// the settled pile by each seat.
class _WonPileLayout {
  _WonPileLayout._();

  static const double kScale = 0.26;
  static const double kBaseW = 80.0;
  static const double kBaseH = 120.0;

  /// Stagger so edges show toward table center (reference: white edges to one side).
  static Offset layerOffset(DesignerTrickSeat seat, int layer) {
    const sx = 5.0;
    const sy = 2.5;
    switch (seat) {
      case DesignerTrickSeat.left:
        return Offset(-layer * sx, -layer * sy);
      case DesignerTrickSeat.right:
        return Offset(layer * sx, -layer * sy);
      case DesignerTrickSeat.top:
        return Offset(-layer * sx * 0.72, layer * sy * 0.85);
      case DesignerTrickSeat.bottom:
        return Offset(-layer * sx, -layer * sy);
    }
  }

  /// When only the last [visible] tricks are drawn, map layer → trick history index.
  static double angleForVisibleLayer(
    DesignerTrickSeat seat,
    List<double> angleHistory,
    int pileCount,
    int visible,
    int layerInVisible,
  ) {
    final hi = pileCount - visible + layerInVisible;
    if (hi >= 0 && hi < angleHistory.length) {
      return angleHistory[hi];
    }
    return kDesignerWinnerPileBaseAngles[seat] ?? 0.0;
  }
}

class DesignerEngineTrickZone extends StatefulWidget {
  const DesignerEngineTrickZone({
    super.key,
    required this.zoneSize,
    required this.playedCardsInTrick,
    required this.collectWinnerSeat,
    required this.collectAnimationTick,
    required this.wonTrickPiles,
    required this.wonTrickPileAngles,
    required this.bottomThrowCardIndex,
    required this.bottomThrowHandCount,
    required this.onCollectAnimationFinished,
  });

  final double zoneSize;
  final List<EngineTrickEntry> playedCardsInTrick;
  final DesignerTrickSeat? collectWinnerSeat;
  final int collectAnimationTick;
  final Map<DesignerTrickSeat, int> wonTrickPiles;
  final Map<DesignerTrickSeat, List<double>> wonTrickPileAngles;
  final int bottomThrowCardIndex;
  final int bottomThrowHandCount;
  final VoidCallback onCollectAnimationFinished;

  @override
  State<DesignerEngineTrickZone> createState() => _DesignerEngineTrickZoneState();
}

class _DesignerEngineTrickZoneState extends State<DesignerEngineTrickZone>
    with TickerProviderStateMixin {
  static const _allSeats = [
    DesignerTrickSeat.left,
    DesignerTrickSeat.top,
    DesignerTrickSeat.right,
    DesignerTrickSeat.bottom,
  ];

  static const Map<DesignerTrickSeat, Offset> _throwStartOffsets = {
    DesignerTrickSeat.left: Offset(-112, -12),
    // Start from partner name-box area.
    DesignerTrickSeat.top: Offset(0, -180),
    DesignerTrickSeat.right: Offset(112, -12),
    // Start deep from user's hand zone ΓÇö matches the actual card position
    // so there's no visible teleport when the card leaves the hand.
    DesignerTrickSeat.bottom: Offset(0, 270),
  };

  static const Map<DesignerTrickSeat, double> _throwStartAngles = {
    DesignerTrickSeat.left: -0.20,
    DesignerTrickSeat.top: 0.10,
    DesignerTrickSeat.right: 0.20,
    DesignerTrickSeat.bottom: 0.12,
  };
  static const Map<DesignerTrickSeat, double> _throwArcStrength = {
    // Per-seat arc feel tuning for more natural throws.
    DesignerTrickSeat.left: 0.15,
    DesignerTrickSeat.top: 0.22,
    DesignerTrickSeat.right: 0.14,
    DesignerTrickSeat.bottom: 0.19,
  };
  static const Map<DesignerTrickSeat, double> _throwSideCurve = {
    // Small lateral curve (+ right, - left) to avoid identical trajectories.
    DesignerTrickSeat.left: -6.0,
    DesignerTrickSeat.top: 0.0,
    DesignerTrickSeat.right: 6.0,
    DesignerTrickSeat.bottom: 0.0,
  };
  static const Map<DesignerTrickSeat, Offset> _winnerPileOffsets = {
    DesignerTrickSeat.top: Offset(0, -100),    // Blue circle for Michael
    DesignerTrickSeat.left: Offset(-65, 30),   // Blue circle for Dwight
    DesignerTrickSeat.right: Offset(65, 30),   // Blue circle for Jim
    DesignerTrickSeat.bottom: Offset(0, 150),  // Moved further down for You
  };
  Map<DesignerTrickSeat, AnimationController> _throwControllers = {};
  late final AnimationController _collectController;
  bool _controllersInitialized = false;
  int _lastCollectAnimationTick = 0;
  bool _isCollecting = false;
  int _lastTotalTrickCount = 0;
  final List<_CollectAnimEntry> _collectAnimEntries = [];
  final Map<int, _StaticImpactPose> _tableImpactPoses = {};
  final Map<DesignerTrickSeat, bool> _impactAppliedForSeat = {
    DesignerTrickSeat.left: false,
    DesignerTrickSeat.top: false,
    DesignerTrickSeat.right: false,
    DesignerTrickSeat.bottom: false,
  };
  final Map<DesignerTrickSeat, double> _impactContactStartTBySeat = {
    DesignerTrickSeat.left: 1.0,
    DesignerTrickSeat.top: 1.0,
    DesignerTrickSeat.right: 1.0,
    DesignerTrickSeat.bottom: 1.0,
  };
  final Map<DesignerTrickSeat, CardModel?> _animatingCards = {
    DesignerTrickSeat.left: null,
    DesignerTrickSeat.top: null,
    DesignerTrickSeat.right: null,
    DesignerTrickSeat.bottom: null,
  };
  // Dynamic X start offset for the bottom throw ΓÇö set per-throw based on
  // which card in the fan was swiped.
  double _bottomThrowStartDx = 0.0;
  // Dynamic start angle ΓÇö matches the card's tilt in the hand fan.
  double _bottomThrowStartAngle = 0.12;
  final Map<DesignerTrickSeat, int> _lastSeatCounts = {
    DesignerTrickSeat.left: 0,
    DesignerTrickSeat.top: 0,
    DesignerTrickSeat.right: 0,
    DesignerTrickSeat.bottom: 0,
  };

  @override
  void initState() {
    super.initState();
    _ensureThrowControllersInitialized();
    _collectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && _isCollecting) {
          _isCollecting = false;
          widget.onCollectAnimationFinished();
        }
      });
  }

  // Per-seat throw duration ΓÇö bottom is fastest (user's flick), top is
  // slowest (travels the longest distance).
  static const Map<DesignerTrickSeat, Duration> _throwDurations = {
    DesignerTrickSeat.bottom: Duration(milliseconds: 750),
    DesignerTrickSeat.right: Duration(milliseconds: 680),
    DesignerTrickSeat.left: Duration(milliseconds: 680),
    DesignerTrickSeat.top: Duration(milliseconds: 750),
  };

  void _ensureThrowControllersInitialized() {
    if (_controllersInitialized) return;
    _throwControllers = {
      for (final seat in _allSeats)
        seat: AnimationController(
          vsync: this,
          duration: _throwDurations[seat] ?? const Duration(milliseconds: 650),
        )
          ..addListener(_onThrowTick)
          ..addStatusListener((status) {
            // When the throw finishes, force a parent rebuild so that
            // hideLatestForSeat flips to false and the static card
            // appears ΓÇö prevents the "card disappears" gap.
            if (status == AnimationStatus.completed && mounted) {
              setState(() {});
            }
          }),
    };
    _controllersInitialized = true;
  }

  void _onThrowTick() {
    if (!mounted || _isCollecting) return;
    for (final seat in _allSeats) {
      final controller = _throwControllers[seat];
      if (controller == null) continue;
      final applied = _impactAppliedForSeat[seat] ?? false;
      if (!applied &&
          controller.isAnimating &&
          _shouldApplyImpactNow(seat, controller.value)) {
        _applyPermanentImpactOnLanding();
        _impactAppliedForSeat[seat] = true;
        _impactContactStartTBySeat[seat] = controller.value;
        setState(() {});
        break;
      }
      if (!controller.isAnimating) {
        _impactContactStartTBySeat[seat] = 1.0;
      }
    }
  }

  bool _shouldApplyImpactNow(DesignerTrickSeat seat, double tRaw) {
    final totalCount = widget.playedCardsInTrick.length;
    if (totalCount < 2) return false;

    final seatEntries = _entriesFor(seat);
    if (seatEntries.isEmpty) return false;
    final gMoving = _globalIndexOfLastPlayForSeat(seat);
    final moving = _computeThrowPose(seat, tRaw, gMoving);

    // Top static card before incoming one is always previous global throw.
    final staticGlobalIndex = totalCount - 2;
    final fan = _CenterTrickLayout.offsetFor(widget.playedCardsInTrick, staticGlobalIndex);
    final impact =
        _tableImpactPoses[staticGlobalIndex] ?? const _StaticImpactPose();
    final staticDx = fan.dx + impact.dx;
    final staticDy = fan.dy + impact.dy;

    final distance =
        (Offset(moving.dx, moving.dy) - Offset(staticDx, staticDy)).distance;
    // Trigger when incoming card is close to pile.
    const contactRadius = 80.0;
    return distance <= contactRadius || tRaw >= 0.70;
  }

  int _globalIndexOfLastPlayForSeat(DesignerTrickSeat seat) {
    for (int i = widget.playedCardsInTrick.length - 1; i >= 0; i--) {
      if (widget.playedCardsInTrick[i].seat == seat) return i;
    }
    return 0;
  }

  _ThrowPose _computeThrowPose(
      DesignerTrickSeat seat, double rawT, int globalTargetIndex) {
    const bottomThrowCurve = Cubic(0.22, 0.68, 0.35, 1.0);
    final travelT = switch (seat) {
      DesignerTrickSeat.bottom => bottomThrowCurve.transform(rawT),
      DesignerTrickSeat.top    => Curves.easeOutCubic.transform(rawT),
      DesignerTrickSeat.left   => Curves.easeOutQuart.transform(rawT),
      DesignerTrickSeat.right  => Curves.easeOutQuart.transform(rawT),
    };
    final settleT = Curves.easeOutCubic.transform(rawT);

    final plays = widget.playedCardsInTrick;
    final fanTarget = _CenterTrickLayout.offsetFor(plays, globalTargetIndex);
    final targetDx = fanTarget.dx;
    final targetDy = fanTarget.dy;
    final targetAngle = _CenterTrickLayout.angleFor(plays, globalTargetIndex);

    final start = _throwStartOffsets[seat] ?? Offset.zero;
    final startAngle = _throwStartAngles[seat] ?? 0.0;

    final distanceY = (targetDy - start.dy).abs();
    final arcStrength = _throwArcStrength[seat] ?? 0.18;
    final arcBoost = switch (seat) {
      DesignerTrickSeat.top => 1.28,
      DesignerTrickSeat.bottom => 1.45,
      DesignerTrickSeat.left => 1.0,
      DesignerTrickSeat.right => 1.0,
    };
    final arcLift = (distanceY * arcStrength * arcBoost).clamp(10.0, 38.0);
    final arcY = -arcLift * (4 * travelT * (1 - travelT));
    final sideCurve =
        (_throwSideCurve[seat] ?? 0.0) * (4 * travelT * (1 - travelT));

    final dx = start.dx + ((targetDx - start.dx) * travelT) + sideCurve;
    final dy = start.dy + ((targetDy - start.dy) * travelT) + arcY;
    final angle = startAngle + ((targetAngle - startAngle) * settleT);
    return _ThrowPose(dx: dx, dy: dy, angle: angle);
  }

  void _applyPermanentImpactOnLanding() {
    final totalCount = widget.playedCardsInTrick.length;
    if (totalCount <= 1) {
      _tableImpactPoses[0] = const _StaticImpactPose();
      _lastTotalTrickCount = totalCount;
      return;
    }

    // Determine push direction from where the incoming card came from.
    final incomingSeat = widget.playedCardsInTrick.last.seat;
    // Incoming card pushes existing cards AWAY from its origin.
    final pushDirX = switch (incomingSeat) {
      DesignerTrickSeat.left => 1.0, // card from left pushes right
      DesignerTrickSeat.right => -1.0, // card from right pushes left
      DesignerTrickSeat.bottom => 0.0, // card from bottom pushes up
      DesignerTrickSeat.top => 0.0, // card from top pushes down
    };
    final pushDirY = switch (incomingSeat) {
      DesignerTrickSeat.bottom => -1.0, // pushes upward
      DesignerTrickSeat.top => 1.0, // pushes downward
      DesignerTrickSeat.left => 0.0,
      DesignerTrickSeat.right => 0.0,
    };

    for (int i = 0; i < totalCount - 1; i++) {
      final prev = _tableImpactPoses[i] ?? const _StaticImpactPose();
      // Each card gets a unique variation so they don't all move identically.
      final variation = ((i * 7 + totalCount * 3) % 5) + 1;
      final sign = ((i + totalCount) % 2 == 0) ? 1.0 : -1.0;

      // Directional push from incoming card + perpendicular scatter.
      final dxDelta = (pushDirX * (3.0 + variation * 0.8)) +
          (sign * (1.5 + variation * 0.6));
      final dyDelta = (pushDirY * (2.5 + variation * 0.6)) +
          (sign * (0.8 + variation * 0.4));
      // Strong angle rotation ΓÇö each card rotates differently.
      final angleDelta = sign * (0.04 + (((i + totalCount) % 3) * 0.025));

      _tableImpactPoses[i] = _StaticImpactPose(
        dx: (prev.dx + dxDelta).clamp(-18.0, 18.0),
        dy: (prev.dy + dyDelta).clamp(-12.0, 8.0),
        angle: (prev.angle + angleDelta).clamp(-0.45, 0.45),
      );
    }
    _tableImpactPoses[totalCount - 1] = const _StaticImpactPose();
    _lastTotalTrickCount = totalCount;
  }

  List<EngineTrickEntry> _entriesFor(DesignerTrickSeat seat) =>
      widget.playedCardsInTrick.where((entry) => entry.seat == seat).toList();

  @override
  void didUpdateWidget(covariant DesignerEngineTrickZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureThrowControllersInitialized();
    for (final seat in _allSeats) {
      final seatEntries = _entriesFor(seat);
      final count = seatEntries.length;
      if (count > (_lastSeatCounts[seat] ?? 0)) {
        _animatingCards[seat] = seatEntries.last.card;
        _impactAppliedForSeat[seat] = false;
        // For the bottom seat, calculate the X start based on which card
        // in the fan was thrown ΓÇö rightmost card starts right, etc.
        if (seat == DesignerTrickSeat.bottom) {
          final idx = widget.bottomThrowCardIndex;
          final cnt = widget.bottomThrowHandCount;
          final center = (cnt - 1) / 2.0;
          _bottomThrowStartDx = (idx - center) * 52.0;
          // Match the card's tilt in the hand fan ΓÇö rightmost tilts
          // clockwise, leftmost counter-clockwise.
          _bottomThrowStartAngle = (idx - center) * 0.06;
        }
        _throwControllers[seat]!.forward(from: 0);
      }
      _lastSeatCounts[seat] = count;
    }

    final totalCount = widget.playedCardsInTrick.length;
    if (totalCount == 0) {
      _tableImpactPoses.clear();
    } else if (totalCount < _lastTotalTrickCount) {
      // Keep only poses for currently existing cards.
      _tableImpactPoses.removeWhere((key, _) => key >= totalCount);
    }
    _lastTotalTrickCount = totalCount;

    final collectTriggered =
        widget.collectAnimationTick != _lastCollectAnimationTick;
    if (collectTriggered) {
      _lastCollectAnimationTick = widget.collectAnimationTick;
      _startCollectAnimationIfPossible();
    }
  }

  void _startCollectAnimationIfPossible() {
    final winner = widget.collectWinnerSeat;
    if (winner == null || widget.playedCardsInTrick.isEmpty) return;
    final target = _winnerPileOffsets[winner] ?? Offset.zero;

    // Stop any in-flight throw overlays before collect starts, so the
    // last opponent card does not linger on screen.
    for (final seat in _allSeats) {
      _throwControllers[seat]?.stop();
      _animatingCards[seat] = null;
    }

    _collectAnimEntries
      ..clear()
      ..addAll(
        widget.playedCardsInTrick.asMap().entries.map((entry) {
          final i = entry.key;
          final played = entry.value;
          final plays = widget.playedCardsInTrick;
          final fan = _CenterTrickLayout.offsetFor(plays, i);
          final impact = _tableImpactPoses[i] ?? const _StaticImpactPose();
          final startDx = fan.dx + impact.dx;
          final startDy = fan.dy + impact.dy;
          final startAngle = _CenterTrickLayout.angleFor(plays, i) + impact.angle;
          return _CollectAnimEntry(
            card: played.card,
            index: i,
            startDx: startDx,
            startDy: startDy,
            startAngle: startAngle,
            targetDx: target.dx + (i * 0.9),
            targetDy: target.dy - (i * 0.7),
          );
        }),
      );

    _isCollecting = true;
    _collectController.forward(from: 0);
  }

  /// Majlis-style pile next to each seat (fanned portrait + π/2 cap); cap pops in
  /// briefly when [pileCount] changes (designer-style polish).
  List<Widget> _buildDesignerWonTrickPileChildren({
    required DesignerTrickSeat seat,
    required int pileCount,
    required Offset pileOffset,
    required List<double> angleHistory,
  }) {
    final visible = pileCount > 5 ? 5 : pileCount;
    if (visible <= 0) return const [];

    const scale = _WonPileLayout.kScale;
    const bw = _WonPileLayout.kBaseW;
    const bh = _WonPileLayout.kBaseH;
    final pileBack =
        pc.cardBackForSeat(playerIndexForDesignerTrickSeat(seat));
    final out = <Widget>[];

    if (visible == 1) {
      final ang = _WonPileLayout.angleForVisibleLayer(
        seat, angleHistory, pileCount, visible, 0,
      );
      out.add(
        TweenAnimationBuilder<double>(
          key: ValueKey<Object>('${seat}_pile_$pileCount'),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: _EngineTrickCardAt(
            card: _kPilePlaceholderCard,
            dx: pileOffset.dx,
            dy: pileOffset.dy,
            angle: ang + math.pi / 2,
            faceUp: false,
            faceDownBack: pileBack,
            scale: scale * 1.04,
            baseWidth: bw,
            baseHeight: bh,
          ),
          builder: (context, t, child) {
            return Transform.scale(
              scale: 0.84 + 0.16 * t,
              alignment: Alignment.center,
              child: Opacity(opacity: t, child: child),
            );
          },
        ),
      );
      return out;
    }

    for (int i = 0; i < visible - 1; i++) {
      final d = _WonPileLayout.layerOffset(seat, i);
      final ang = _WonPileLayout.angleForVisibleLayer(
        seat, angleHistory, pileCount, visible, i,
      );
      out.add(
        _EngineTrickCardAt(
          card: _kPilePlaceholderCard,
          dx: pileOffset.dx + d.dx,
          dy: pileOffset.dy + d.dy,
          angle: ang,
          faceUp: false,
          faceDownBack: pileBack,
          scale: scale,
          baseWidth: bw,
          baseHeight: bh,
        ),
      );
    }

    final capLayer = visible - 1;
    final dCap = _WonPileLayout.layerOffset(seat, capLayer);
    final capAng = _WonPileLayout.angleForVisibleLayer(
      seat, angleHistory, pileCount, visible, capLayer,
    );
    out.add(
      TweenAnimationBuilder<double>(
        key: ValueKey<Object>('${seat}_pilecap_$pileCount'),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: _EngineTrickCardAt(
          card: _kPilePlaceholderCard,
          dx: pileOffset.dx + dCap.dx,
          dy: pileOffset.dy + dCap.dy - 8,
          angle: capAng + math.pi / 2,
          faceUp: false,
          faceDownBack: pileBack,
          scale: scale * 1.05,
          baseWidth: bw,
          baseHeight: bh,
        ),
        builder: (context, t, child) {
          return Transform.scale(
            scale: 0.84 + 0.16 * t,
            alignment: Alignment.center,
            child: Opacity(opacity: t, child: child),
          );
        },
      ),
    );

    return out;
  }

  @override
  void dispose() {
    _collectController.dispose();
    if (_controllersInitialized) {
      for (final controller in _throwControllers.values) {
        controller.removeListener(_onThrowTick);
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ensureThrowControllersInitialized();
    final children = <Widget>[];
    final animatedChildren = <Widget>[];
    final hideLatestForSeat = <DesignerTrickSeat, bool>{};
    final seatEntriesMap = <DesignerTrickSeat, List<EngineTrickEntry>>{
      for (final seat in _allSeats) seat: _entriesFor(seat),
    };

    for (final seat in _allSeats) {
      final controller = _throwControllers[seat]!;
      final seatEntries = seatEntriesMap[seat] ?? const <EngineTrickEntry>[];
      hideLatestForSeat[seat] =
          !_isCollecting && controller.isAnimating && seatEntries.isNotEmpty;

      final animatingCard = _animatingCards[seat];
      if (!_isCollecting && animatingCard != null) {
        animatedChildren.add(
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              if (!controller.isAnimating) {
                return const SizedBox.shrink();
              }
              final t = controller.value;

              // ΓöÇΓöÇ Per-seat easing curves ΓöÇΓöÇ
              // Bottom: custom curve ΓÇö slow peel from hand, fast flick
              // through mid-air, gentle deceleration onto table.
              // Sides: punchy.  Top: smooth.
              const bottomThrowCurve = Cubic(0.22, 0.68, 0.35, 1.0);
              final travelT = switch (seat) {
                DesignerTrickSeat.bottom => bottomThrowCurve.transform(t),
                DesignerTrickSeat.top    => Curves.easeOutCubic.transform(t),
                DesignerTrickSeat.left   => Curves.easeOutQuart.transform(t),
                DesignerTrickSeat.right  => Curves.easeOutQuart.transform(t),
              };
              final settleT = Curves.easeOutCubic.transform(t);

              final gTarget = _globalIndexOfLastPlayForSeat(seat);
              final plays = widget.playedCardsInTrick;
              final fanT = _CenterTrickLayout.offsetFor(plays, gTarget);
              final targetDx = fanT.dx;
              final targetDy = fanT.dy;
              final targetAngle = _CenterTrickLayout.angleFor(plays, gTarget);

              final start = seat == DesignerTrickSeat.bottom
                  ? Offset(_bottomThrowStartDx, _throwStartOffsets[seat]?.dy ?? 270)
                  : _throwStartOffsets[seat] ?? Offset.zero;
              final startAngle = seat == DesignerTrickSeat.bottom
                  ? _bottomThrowStartAngle
                  : _throwStartAngles[seat] ?? 0.0;

              // ΓöÇΓöÇ Parabolic arc (natural curve, not straight line) ΓöÇΓöÇ
              final distanceY = (targetDy - start.dy).abs();
              final arcStrength = _throwArcStrength[seat] ?? 0.18;
              final arcBoost = switch (seat) {
                DesignerTrickSeat.top => 1.28,
                DesignerTrickSeat.bottom => 1.45,
                DesignerTrickSeat.left => 1.0,
                DesignerTrickSeat.right => 1.0,
              };
              final arcLift =
                  (distanceY * arcStrength * arcBoost).clamp(10.0, 38.0);
              final arcY = -arcLift * (4 * travelT * (1 - travelT));
              final sideCurve = (_throwSideCurve[seat] ?? 0.0) *
                  (4 * travelT * (1 - travelT));

              // ΓöÇΓöÇ Position: smooth single-curve trajectory ΓöÇΓöÇ
              final dx =
                  start.dx + ((targetDx - start.dx) * travelT) + sideCurve;
              final dy = start.dy + ((targetDy - start.dy) * travelT) + arcY;

              // ΓöÇΓöÇ Angle: base interpolation + subtle flight spin ΓöÇΓöÇ
              // sin(╧Ç┬╖t) peaks at midpoint ΓÇö card spins slightly mid-flight
              // then settles perfectly to the target angle.
              const spinAmounts = {
                DesignerTrickSeat.bottom: 0.12,
                DesignerTrickSeat.right: -0.06,
                DesignerTrickSeat.left: 0.06,
                DesignerTrickSeat.top: -0.05,
              };
              final spin =
                  (spinAmounts[seat] ?? 0.0) * math.sin(travelT * math.pi);

              final angle =
                  startAngle +
                  ((targetAngle - startAngle) * settleT) +
                  spin;

              // ΓöÇΓöÇ Depth scale: smooth bell curve (rises mid-flight) ΓöÇΓöÇ
              // sin(╧Ç┬╖travelT) peaks at 0.5 ΓåÆ card "lifts toward camera"
              // at the apex of its arc, then settles back to 1.0.
              // Bottom gets a bigger pulse since it travels the furthest.
              final depthAmount = seat == DesignerTrickSeat.bottom ? 0.14 : 0.10;
              final depthPulse = math.sin(travelT * math.pi) * depthAmount;

              // ΓöÇΓöÇ Landing thump ΓöÇΓöÇ
              // In the last 15%: card compresses on impact then snaps
              // back ΓÇö single hard bump like slamming a card on felt.
              double thumpScale = 0.0;
              double thumpDy = 0.0;
              if (travelT > 0.85) {
                final p = (travelT - 0.85) / 0.15; // 0ΓåÆ1 in last 15%
                // Sharp dip then rebound: sin(╧Ç┬╖p) peaks at p=0.5
                final bump = math.sin(p * math.pi);
                thumpScale = -0.07 * bump; // compress 7% at peak
                thumpDy = 4.0 * bump; // overshoot 4px past target
              }

              final scale = 1.0 + depthPulse + thumpScale;

              // ΓöÇΓöÇ Lift-off blend (bottom seat only) ΓöÇΓöÇ
              // Quick fade-in so the card doesn't pop into existence.
              final liftOpacity = seat == DesignerTrickSeat.bottom
                  ? (t / 0.05).clamp(0.0, 1.0)
                  : 1.0;
              final liftScale = seat == DesignerTrickSeat.bottom
                  ? 0.92 + 0.08 * (t / 0.10).clamp(0.0, 1.0)
                  : 1.0;

              final card = _EngineTrickCardAt(
                card: animatingCard,
                dx: dx,
                dy: dy + thumpDy,
                angle: angle,
                scale: scale * liftScale,
              );

              return liftOpacity < 1.0
                  ? Opacity(opacity: liftOpacity, child: card)
                  : card;
            },
          ),
        );
      }
    }

    // 1. Won-trick piles (Rendered first, so they stay UNDER the thrown cards)
    for (final seat in _allSeats) {
      final pileCount = widget.wonTrickPiles[seat] ?? 0;
      if (pileCount <= 0) continue;
      final pileOffset = _winnerPileOffsets[seat] ?? Offset.zero;
      final angleHistory = widget.wonTrickPileAngles[seat] ?? const <double>[];
      children.addAll(_buildDesignerWonTrickPileChildren(
        seat: seat,
        pileCount: pileCount,
        pileOffset: pileOffset,
        angleHistory: angleHistory,
      ));
    }

    // 2. Static trick on the table
    if (!_isCollecting) {
      final throwTick = Listenable.merge(_throwControllers.values.toList());
      children.add(
        AnimatedBuilder(
          animation: throwTick,
          builder: (context, _) {
            final plays = widget.playedCardsInTrick;
            final n = plays.length;
            final seatSeenCounts = <DesignerTrickSeat, int>{
              DesignerTrickSeat.left: 0,
              DesignerTrickSeat.top: 0,
              DesignerTrickSeat.right: 0,
              DesignerTrickSeat.bottom: 0,
            };
            final staticCards = <Widget>[];
            for (int throwIndex = 0; throwIndex < n; throwIndex++) {
              final entry = plays[throwIndex];
              final seat = entry.seat;
              final seatCount = (seatSeenCounts[seat] ?? 0);
              seatSeenCounts[seat] = seatCount + 1;
              final seatTotal = seatEntriesMap[seat]?.length ?? 0;
              final shouldHideLatest = hideLatestForSeat[seat] ?? false;
              if (shouldHideLatest && seatCount == seatTotal - 1) {
                continue;
              }
              final fan = _CenterTrickLayout.offsetFor(plays, throwIndex);
              final baseAngle = _CenterTrickLayout.angleFor(plays, throwIndex);
              final impactPose =
                  _tableImpactPoses[throwIndex] ?? const _StaticImpactPose();

              staticCards.add(
                TweenAnimationBuilder<double>(
                  key: ValueKey('table_pose_$throwIndex'),
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) {
                    return _EngineTrickCardAt(
                      card: entry.card,
                      dx: fan.dx + (impactPose.dx * t),
                      dy: fan.dy + (impactPose.dy * t),
                      angle: baseAngle + (impactPose.angle * t),
                    );
                  },
                ),
              );
            }
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: staticCards,
            );
          },
        ),
      );
    }
    
    // 3. Keep in-flight thrown cards above static stack and won piles immediately.
    children.addAll(animatedChildren);

    if (_isCollecting && _collectAnimEntries.isNotEmpty) {
      children.add(
        AnimatedBuilder(
          animation: _collectController,
          builder: (context, _) {
            final t = Curves.easeInOutCubic.transform(_collectController.value);
            final winnerSeat = widget.collectWinnerSeat;
            final winnerTeamBack = winnerSeat == null
                ? pc.CardBack.red
                : pc.cardBackForSeat(
                    playerIndexForDesignerTrickSeat(winnerSeat),
                  );
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: _collectAnimEntries.map((entry) {
                final dx =
                    entry.startDx + ((entry.targetDx - entry.startDx) * t);
                final dy =
                    entry.startDy + ((entry.targetDy - entry.startDy) * t);
                // Base angle unwinds to 0, plus a per-card spin wobble
                // that gives the gathering a dynamic, swirling feel.
                final spinSpeed = 1.5 + (entry.index * 0.7);
                final spinAmp = 0.15 + (entry.index * 0.05);
                final collectSpin =
                    math.sin(t * math.pi * spinSpeed) * spinAmp * (1 - t);
                final angle = entry.startAngle * (1 - t) + collectSpin;
                final scale = 1.0 - (0.74 * t);
                final faceUp = t < 0.72;
                final bw = 72.0 + (80.0 - 72.0) * t;
                final bh = 100.0 + (120.0 - 100.0) * t;
                return _EngineTrickCardAt(
                  card: entry.card,
                  dx: dx,
                  dy: dy,
                  angle: angle,
                  faceUp: faceUp,
                  faceDownBack: winnerTeamBack,
                  scale: scale,
                  baseWidth: bw,
                  baseHeight: bh,
                );
              }).toList(growable: false),
            );
          },
        ),
      );
    }

    return SizedBox(
      width: widget.zoneSize,
      height: widget.zoneSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: children,
      ),
    );
  }
}

class _EngineTrickCardAt extends StatelessWidget {
  const _EngineTrickCardAt({
    required this.card,
    this.dx = 0,
    this.dy = 0,
    this.angle = 0,
    this.faceUp = true,
    this.faceDownBack = pc.CardBack.red,
    this.scale = 1.0,
    this.baseWidth = 72.0,
    this.baseHeight = 100.0,
  });

  final CardModel card;
  final double dx;
  final double dy;
  final double angle;
  final bool faceUp;
  final pc.CardBack faceDownBack;
  final double scale;
  final double baseWidth;
  final double baseHeight;

  @override
  Widget build(BuildContext context) {
    final w = baseWidth * scale;
    final h = baseHeight * scale;
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: angle,
        child: SizedBox(
          width: w,
          height: h,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: pc.CardSize.medium.width,
              height: pc.CardSize.medium.height,
              child: pc.PlayingCard(
                card: card,
                size: pc.CardSize.medium,
                faceUp: faceUp,
                back: faceDownBack,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectAnimEntry {
  const _CollectAnimEntry({
    required this.card,
    required this.index,
    required this.startDx,
    required this.startDy,
    required this.startAngle,
    required this.targetDx,
    required this.targetDy,
  });

  final CardModel card;
  final int index;
  final double startDx;
  final double startDy;
  final double startAngle;
  final double targetDx;
  final double targetDy;
}

class _StaticImpactPose {
  const _StaticImpactPose({
    this.dx = 0.0,
    this.dy = 0.0,
    this.angle = 0.0,
  });

  final double dx;
  final double dy;
  final double angle;
}

class _ThrowPose {
  const _ThrowPose({
    required this.dx,
    required this.dy,
    required this.angle,
  });

  final double dx;
  final double dy;
  final double angle;
}

