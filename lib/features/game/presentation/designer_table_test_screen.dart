import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playing_cards/playing_cards.dart';

/// Designer / Baloot-dev majlis table UI (demo: `playing_cards`, SVG maps, motion).
/// Open from the real game via **Test mode** in the top bar.
class DesignerTableTestScreen extends StatefulWidget {
  const DesignerTableTestScreen({super.key});

  @override
  State<DesignerTableTestScreen> createState() => _DesignerTableTestScreenState();
}

class _DesignerTableTestScreenState extends State<DesignerTableTestScreen> {
  int? _selectedBottomCardIndex;
  _SeatAlignment _currentTurnPlayer = _SeatAlignment.bottom;
  final List<dynamic> _playedCardsInTrick = [];
  final List<PlayingCard> _bottomHand =
      List<PlayingCard>.from(_demoBottomHandSeed);
  int _activeMapIndex = 0;
  // Track which card position the bottom player threw from.
  int _lastBottomThrowCardIndex = 0;
  int _lastBottomThrowHandCount = 5;
  static const List<String> _mapAssets = [
    'assets/images/majlis_table_map.svg',
    'assets/images/map2.svg',
  ];
  // TODO(game-logic): Remove this unlimited throw testing flag once real
  // turn/trick validation is implemented in the game engine.
  static const bool _unlimitedThrowUiTesting = true;
  // TODO(game-logic): UI testing only.
  // When the user throws, make the 3 opponents throw one card each.
  // Remove this fake behavior once real engine turn simulation is integrated.
  final Map<_SeatAlignment, int> _uiTestOpponentCardCursor = {
    _SeatAlignment.left: 0,
    _SeatAlignment.top: 0,
    _SeatAlignment.right: 0,
  };
  bool _uiTestTrickInProgress = false;
  _SeatAlignment? _uiTestCollectWinner;
  int _uiTestCollectAnimationTick = 0;
  int _uiTestWinnerCycleIndex = 0;
  final Map<_SeatAlignment, int> _uiTestWonTrickPiles = {
    _SeatAlignment.left: 0,
    _SeatAlignment.top: 0,
    _SeatAlignment.right: 0,
    _SeatAlignment.bottom: 0,
  };
  // TODO(game-logic): UI testing only.
  // Keep hand counts in UI so each thrown card leaves that player's hand.
  // Remove test hand simulation when real game engine state is integrated,
  // but keep this UI wiring (cardCount / bottom hand rendering).
  final Map<_SeatAlignment, int> _uiTestSeatCardCounts = {
    _SeatAlignment.left: 5,
    _SeatAlignment.top: 5,
    _SeatAlignment.right: 5,
    _SeatAlignment.bottom: 5,
  };
  final Map<_SeatAlignment, List<double>> _uiTestWonTrickPileAngles = {
    _SeatAlignment.left: <double>[],
    _SeatAlignment.top: <double>[],
    _SeatAlignment.right: <double>[],
    _SeatAlignment.bottom: <double>[],
  };

  List<_PlayedCardEntry> get _playedCardsInTrickView =>
      _playedCardsInTrick.whereType<_PlayedCardEntry>().toList(growable: false);

  PlayingCard _nextUiTestOpponentCard(_SeatAlignment seat) {
    final cursor = _uiTestOpponentCardCursor[seat] ?? 0;
    final card = _uiTestOpponentDeck[cursor % _uiTestOpponentDeck.length];
    _uiTestOpponentCardCursor[seat] = cursor + 1;
    return card;
  }

  double _nextUiTestPileAngle(_SeatAlignment seat) {
    // Keep base pile direction same as throw direction per seat.
    const baseAngles = {
      _SeatAlignment.right: 1.22173, // 70deg
      _SeatAlignment.left: 1.91986, // 110deg
      _SeatAlignment.bottom: 0.10472, // 6deg
      _SeatAlignment.top: -0.10472, // -6deg
    };
    // UI testing: strong angle variation to form a star-like pile.
    // Pattern intent: right tilt -> left tilt -> near 90deg -> opposite
    // points, while preserving old card angles.
    const wobbleSteps = [0.0, 0.52, -0.52, 1.05, -1.05, 0.30, -0.30];
    final currentCount = _uiTestWonTrickPileAngles[seat]?.length ?? 0;
    final base = baseAngles[seat] ?? 0.0;
    final wobble = wobbleSteps[currentCount % wobbleSteps.length];
    return base + wobble;
  }

  Future<void> _runUiTestThrowCycle(int index) async {
    if (_uiTestTrickInProgress) return;
    if (index < 0 || index >= _bottomHand.length) return;
    if ((_uiTestSeatCardCounts[_SeatAlignment.bottom] ?? 0) <= 0) return;
    _uiTestTrickInProgress = true;

    // Save the card's position in hand BEFORE removing it.
    _lastBottomThrowCardIndex = index;
    _lastBottomThrowHandCount = _bottomHand.length;

    final myCard = _bottomHand.removeAt(index);
    setState(() {
      _playedCardsInTrick.add(
        _PlayedCardEntry(seat: _SeatAlignment.bottom, card: myCard),
      );
      _uiTestSeatCardCounts[_SeatAlignment.bottom] =
          (_uiTestSeatCardCounts[_SeatAlignment.bottom] ?? 0) - 1;
      _selectedBottomCardIndex = null;
    });

    // UI testing flow: user throw -> right -> top -> left (snappy timing).
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    if ((_uiTestSeatCardCounts[_SeatAlignment.right] ?? 0) > 0) {
      setState(() {
        _playedCardsInTrick.add(
          _PlayedCardEntry(
            seat: _SeatAlignment.right,
            card: _nextUiTestOpponentCard(_SeatAlignment.right),
          ),
        );
        _uiTestSeatCardCounts[_SeatAlignment.right] =
            (_uiTestSeatCardCounts[_SeatAlignment.right] ?? 0) - 1;
      });
    }

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    if ((_uiTestSeatCardCounts[_SeatAlignment.top] ?? 0) > 0) {
      setState(() {
        _playedCardsInTrick.add(
          _PlayedCardEntry(
            seat: _SeatAlignment.top,
            card: _nextUiTestOpponentCard(_SeatAlignment.top),
          ),
        );
        _uiTestSeatCardCounts[_SeatAlignment.top] =
            (_uiTestSeatCardCounts[_SeatAlignment.top] ?? 0) - 1;
      });
    }

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    if ((_uiTestSeatCardCounts[_SeatAlignment.left] ?? 0) > 0) {
      setState(() {
        _playedCardsInTrick.add(
          _PlayedCardEntry(
            seat: _SeatAlignment.left,
            card: _nextUiTestOpponentCard(_SeatAlignment.left),
          ),
        );
        _uiTestSeatCardCounts[_SeatAlignment.left] =
            (_uiTestSeatCardCounts[_SeatAlignment.left] ?? 0) - 1;
      });
    }

    // Brief pause after the last card lands so the player can absorb
    // the completed trick before the collect animation sweeps them away.
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    // UI testing only: deterministic winner cycle.
    // Order requested: me(bottom) -> right -> top -> left -> repeat.
    const winners = [
      _SeatAlignment.bottom,
      _SeatAlignment.right,
      _SeatAlignment.top,
      _SeatAlignment.left,
    ];
    final winner = winners[_uiTestWinnerCycleIndex % winners.length];
    _uiTestWinnerCycleIndex += 1;

    // UI testing only: trigger collect animation to winner.
    setState(() {
      _uiTestCollectWinner = winner;
      _uiTestCollectAnimationTick += 1;
    });
  }

  void _onUiTestCollectAnimationFinished() {
    final winner = _uiTestCollectWinner;
    if (winner == null || !mounted) return;
    final allHandsEmpty =
        (_uiTestSeatCardCounts[_SeatAlignment.left] ?? 0) <= 0 &&
            (_uiTestSeatCardCounts[_SeatAlignment.top] ?? 0) <= 0 &&
            (_uiTestSeatCardCounts[_SeatAlignment.right] ?? 0) <= 0 &&
            (_uiTestSeatCardCounts[_SeatAlignment.bottom] ?? 0) <= 0;

    // Show score card dialog at the end of every trick as requested for testing.
    // The UI layout is permanent, but the data is hardcoded for simulation right now.
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: false,
      builder: (context) => const _ScoreCardDialog(),
    ).then((_) {
      if (!mounted) return;

      // UI testing only: after dialog, clear center and assign points.
      setState(() {
        // Keep table fully clear after every completed trick cycle.
        _playedCardsInTrick.clear();
        _currentTurnPlayer = winner;
        _uiTestWonTrickPiles[winner] = (_uiTestWonTrickPiles[winner] ?? 0) + 1;
        final angles = _uiTestWonTrickPileAngles[winner] ?? <double>[];
        angles.add(_nextUiTestPileAngle(winner));
        _uiTestWonTrickPileAngles[winner] = angles;
        _uiTestCollectWinner = null;
        _uiTestTrickInProgress = false;

        // Auto-reset all hands when everyone reaches 0 cards.
        if (allHandsEmpty) {
          _bottomHand
            ..clear()
            ..addAll(_demoBottomHandSeed);
          _uiTestSeatCardCounts[_SeatAlignment.left] = 5;
          _uiTestSeatCardCounts[_SeatAlignment.top] = 5;
          _uiTestSeatCardCounts[_SeatAlignment.right] = 5;
          _uiTestSeatCardCounts[_SeatAlignment.bottom] = 5;
          _selectedBottomCardIndex = null;
        }
      });
    });
  }

  void _playBottomCardAtIndex(int index) {
    if (_unlimitedThrowUiTesting) {
      _runUiTestThrowCycle(index);
      return;
    }
    if (!_unlimitedThrowUiTesting &&
        _currentTurnPlayer != _SeatAlignment.bottom) {
      return;
    }
    if (index < 0 || index >= _bottomHand.length) return;
    // Save the card's position in hand BEFORE removing it.
    _lastBottomThrowCardIndex = index;
    _lastBottomThrowHandCount = _bottomHand.length;
    final selectedCard = _bottomHand.removeAt(index);
    setState(() {
      _playedCardsInTrick.add(
        _PlayedCardEntry(seat: _SeatAlignment.bottom, card: selectedCard),
      );
      _uiTestSeatCardCounts[_SeatAlignment.bottom] =
          (_uiTestSeatCardCounts[_SeatAlignment.bottom] ?? 0) - 1;
      _selectedBottomCardIndex = null;
      if (!_unlimitedThrowUiTesting) {
        _currentTurnPlayer = _nextTurnAfter(_currentTurnPlayer);
      }
    });
  }

  _SeatAlignment _nextTurnAfter(_SeatAlignment seat) {
    switch (seat) {
      case _SeatAlignment.bottom:
        return _SeatAlignment.right;
      case _SeatAlignment.right:
        return _SeatAlignment.top;
      case _SeatAlignment.top:
        return _SeatAlignment.left;
      case _SeatAlignment.left:
        return _SeatAlignment.bottom;
    }
  }

  void _cycleBackgroundMap() {
    setState(() {
      _activeMapIndex = (_activeMapIndex + 1) % _mapAssets.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    return Theme(
      data: baseTheme.copyWith(
        textTheme: GoogleFonts.readexProTextTheme(baseTheme.textTheme),
      ),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            _MajlisBackground(mapAssetPath: _mapAssets[_activeMapIndex]),
            SafeArea(
            bottom: false,
            child: Stack(
              children: [
                _TableSeatOverlay(
                  selectedBottomCardIndex: _selectedBottomCardIndex,
                  bottomCards: _bottomHand,
                  seatCardCounts: _uiTestSeatCardCounts,
                  playedCardsInTrick: _playedCardsInTrickView,
                  currentTurnPlayer: _currentTurnPlayer,
                  collectWinnerSeat: _uiTestCollectWinner,
                  collectAnimationTick: _uiTestCollectAnimationTick,
                  wonTrickPiles: _uiTestWonTrickPiles,
                  wonTrickPileAngles: _uiTestWonTrickPileAngles,
                  bottomThrowCardIndex: _lastBottomThrowCardIndex,
                  bottomThrowHandCount: _lastBottomThrowHandCount,
                  onCollectAnimationFinished: _onUiTestCollectAnimationFinished,
                  onBottomCardTap: (index) {
                    setState(() {
                      _selectedBottomCardIndex =
                          _selectedBottomCardIndex == index ? null : index;
                    });
                  },
                  onBottomCardSwipe: _playBottomCardAtIndex,
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: _TopHudBar(
                    onBack: () => Navigator.of(context).pop(),
                    onChangeWallpaper: _cycleBackgroundMap,
                  ),
                ),
                const Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: SizedBox.shrink(),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 12,
                  child: _BottomControlsBar(
                    // Swipe-up controls throwing in UI testing mode.
                    canConfirm: false,
                    onConfirm: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

final List<PlayingCard> _demoBottomHandSeed = [
  PlayingCard(Suit.spades, CardValue.seven),
  PlayingCard(Suit.spades, CardValue.jack),
  PlayingCard(Suit.spades, CardValue.queen),
  PlayingCard(Suit.spades, CardValue.king),
  PlayingCard(Suit.spades, CardValue.ten),
];

final List<PlayingCard> _uiTestOpponentDeck = [
  PlayingCard(Suit.hearts, CardValue.ten),
  PlayingCard(Suit.clubs, CardValue.jack),
  PlayingCard(Suit.diamonds, CardValue.queen),
  PlayingCard(Suit.spades, CardValue.king),
  PlayingCard(Suit.hearts, CardValue.ace),
  PlayingCard(Suit.clubs, CardValue.ten),
  PlayingCard(Suit.diamonds, CardValue.king),
  PlayingCard(Suit.spades, CardValue.queen),
];

class _TopHudBar extends StatelessWidget {
  const _TopHudBar({
    required this.onBack,
    required this.onChangeWallpaper,
  });

  final VoidCallback onBack;
  final VoidCallback onChangeWallpaper;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HudButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 6),
        PopupMenuButton<int>(
          tooltip: '',
          padding: EdgeInsets.zero,
          offset: const Offset(0, 56),
          color: Colors.transparent,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (value) {
            if (value == 1) {
              onChangeWallpaper();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<int>(
              value: 1,
              padding: EdgeInsets.zero,
              child: _HudButton(
                icon: Icons.wallpaper_rounded,
                lightStyle: true,
                iconColor: const Color(0xFF747474),
              ),
            ),
          ],
          child:
              const _HudButton(icon: Icons.more_horiz_rounded, label: 'More'),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: _ScoreHud(
            leftLabel: 'Them',
            leftScore: '41',
            rightLabel: 'Us',
            rightScore: '143',
            roomLabel: '6566 Session',
          ),
        ),
        const SizedBox(width: 8),
        const _HudButton(icon: Icons.volume_up_rounded, label: 'Sound'),
        const SizedBox(width: 6),
        const _HudButton(icon: Icons.emoji_emotions_outlined, label: 'Emote'),
      ],
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    required this.icon,
    this.label,
    this.onTap,
    this.lightStyle = false,
    this.iconColor,
  });

  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final bool lightStyle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: lightStyle
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF9F9F9), Color(0xFFECECEC)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF585858), Color(0xFF2D2D2D)],
              ),
        border: Border.all(
          color: lightStyle
              ? const Color(0xFFD3D3D3)
              : Colors.white.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: lightStyle ? 0.10 : 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ??
                (lightStyle
                    ? const Color(0xFF6F6F6F)
                    : Colors.white.withValues(alpha: 0.95)),
          ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(
              label!,
              style: TextStyle(
                color: lightStyle
                    ? const Color(0xFF6F6F6F)
                    : Colors.white.withValues(alpha: 0.86),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );

    return onTap == null ? child : GestureDetector(onTap: onTap, child: child);
  }
}

class _ScoreHud extends StatelessWidget {
  const _ScoreHud({
    required this.leftLabel,
    required this.leftScore,
    required this.rightLabel,
    required this.rightScore,
    required this.roomLabel,
  });

  final String leftLabel;
  final String leftScore;
  final String rightLabel;
  final String rightScore;
  final String roomLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F4F4F), Color(0xFF262626)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(child: _scoreCell(leftLabel, leftScore)),
                Container(
                    width: 1, color: Colors.white.withValues(alpha: 0.12)),
                Expanded(child: _scoreCell(rightLabel, rightScore)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _scoreCell(String label, String score) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      const SizedBox(height: 1),
      Text(
        score,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    ],
  );
}

class _BottomControlsBar extends StatelessWidget {
  const _BottomControlsBar({
    required this.canConfirm,
    required this.onConfirm,
  });

  final bool canConfirm;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5B5B5B), Color(0xFF2E2E2E)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Flexible(
                flex: 0,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFF4B412E),
                    ),
                    child: const Text(
                      'مبتدئ',
                      style: TextStyle(
                        color: Color(0xFFE8D7B2),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFF454545),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xFF6B6B6B),
                        child: Icon(Icons.person_rounded,
                            size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Wassay Khan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: canConfirm ? onConfirm : null,
                child: Opacity(
                  opacity: canConfirm ? 1 : 0.6,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF7B7B7B), Color(0xFF373737)],
                      ),
                      border:
                          Border.all(color: const Color(0xFFE0C56E), width: 2),
                    ),
                    child: const Text(
                      '6',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _BottomHudIcon(icon: Icons.card_giftcard_rounded),
              const SizedBox(width: 6),
              _BottomHudIcon(icon: Icons.water_drop_outlined),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: _ActionButton(label: 'صن')),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: 'حكم',
                highlighted: true,
                enabled: canConfirm,
                onTap: onConfirm,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(child: _ActionButton(label: 'بس')),
          ],
        ),
      ],
    );
  }
}

class _BottomHudIcon extends StatelessWidget {
  const _BottomHudIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 33,
      height: 33,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE7E7E7), Color(0xFFBFBFBF)],
        ),
        border: Border.all(color: const Color(0xFF8A8A8A)),
      ),
      child: Icon(icon, size: 19, color: const Color(0xFF3B3B3B)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    this.highlighted = false,
    this.enabled = true,
    this.onTap,
  });

  final String label;
  final bool highlighted;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = enabled;
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Opacity(
        opacity: active ? 1 : 0.55,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: highlighted
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF2D08D), Color(0xFFC3912A)],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF5A5A5A), Color(0xFF2D2D2D)],
                  ),
            border: Border.all(
              color: highlighted
                  ? const Color(0xFFE8C874)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: highlighted ? const Color(0xFF41210E) : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TableSeatOverlay extends StatelessWidget {
  const _TableSeatOverlay({
    required this.selectedBottomCardIndex,
    required this.bottomCards,
    required this.seatCardCounts,
    required this.playedCardsInTrick,
    required this.currentTurnPlayer,
    required this.collectWinnerSeat,
    required this.collectAnimationTick,
    required this.wonTrickPiles,
    required this.wonTrickPileAngles,
    required this.bottomThrowCardIndex,
    required this.bottomThrowHandCount,
    required this.onCollectAnimationFinished,
    required this.onBottomCardTap,
    required this.onBottomCardSwipe,
  });

  final int? selectedBottomCardIndex;
  final List<PlayingCard> bottomCards;
  final Map<_SeatAlignment, int> seatCardCounts;
  final List<_PlayedCardEntry> playedCardsInTrick;
  final _SeatAlignment currentTurnPlayer;
  final _SeatAlignment? collectWinnerSeat;
  final int collectAnimationTick;
  final Map<_SeatAlignment, int> wonTrickPiles;
  final Map<_SeatAlignment, List<double>> wonTrickPileAngles;
  final int bottomThrowCardIndex;
  final int bottomThrowHandCount;
  final VoidCallback onCollectAnimationFinished;
  final ValueChanged<int> onBottomCardTap;
  final ValueChanged<int> onBottomCardSwipe;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          children: [
            Align(
              alignment: const Alignment(0, -0.02),
              child: _CenterTrickZone(
                zoneSize: width * 0.30,
                playedCardsInTrick: playedCardsInTrick,
                collectWinnerSeat: collectWinnerSeat,
                collectAnimationTick: collectAnimationTick,
                wonTrickPiles: wonTrickPiles,
                wonTrickPileAngles: wonTrickPileAngles,
                bottomThrowCardIndex: bottomThrowCardIndex,
                bottomThrowHandCount: bottomThrowHandCount,
                onCollectAnimationFinished: onCollectAnimationFinished,
              ),
            ),
            Positioned(
              left: width * 0.31,
              right: width * 0.31,
              top: height * 0.11,
              child: _PlayerSeat(
                name: 'Ahmed',
                badge: 'Partner',
                alignment: _SeatAlignment.top,
                cardCount: seatCardCounts[_SeatAlignment.top] ?? 0,
                isActive: currentTurnPlayer == _SeatAlignment.top,
              ),
            ),
            Positioned(
              left: 0,
              top: height * 0.285,
              bottom: height * 0.375,
              child: _PlayerSeat(
                name: 'Adel',
                badge: 'Opponent',
                alignment: _SeatAlignment.left,
                cardCount: seatCardCounts[_SeatAlignment.left] ?? 0,
                isActive: currentTurnPlayer == _SeatAlignment.left,
              ),
            ),
            Positioned(
              right: 0,
              top: height * 0.285,
              bottom: height * 0.375,
              child: _PlayerSeat(
                name: 'Hasan',
                badge: 'Opponent',
                alignment: _SeatAlignment.right,
                cardCount: seatCardCounts[_SeatAlignment.right] ?? 0,
                isActive: currentTurnPlayer == _SeatAlignment.right,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: height * 0.075,
              child: _PlayerSeat(
                name: 'You',
                badge: 'Your Turn',
                alignment: _SeatAlignment.bottom,
                isSelf: true,
                cardCount: seatCardCounts[_SeatAlignment.bottom] ?? 0,
                isActive: currentTurnPlayer == _SeatAlignment.bottom,
                bottomCards: bottomCards,
                selectedBottomCardIndex: selectedBottomCardIndex,
                onBottomCardTap: onBottomCardTap,
                onBottomCardSwipe: onBottomCardSwipe,
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _SeatAlignment { top, left, right, bottom }

class _PlayerSeat extends StatelessWidget {
  const _PlayerSeat({
    required this.name,
    required this.badge,
    required this.alignment,
    required this.cardCount,
    this.isSelf = false,
    this.isActive = false,
    this.bottomCards,
    this.selectedBottomCardIndex,
    this.onBottomCardTap,
    this.onBottomCardSwipe,
  });

  final String name;
  final String badge;
  final _SeatAlignment alignment;
  final int cardCount;
  final bool isSelf;
  final bool isActive;
  final List<PlayingCard>? bottomCards;
  final int? selectedBottomCardIndex;
  final ValueChanged<int>? onBottomCardTap;
  final ValueChanged<int>? onBottomCardSwipe;

  @override
  Widget build(BuildContext context) {
    switch (alignment) {
      case _SeatAlignment.top:
        return _TopSeat(
          name: name,
          badge: badge,
          cardCount: cardCount,
          isActive: isActive,
        );
      case _SeatAlignment.left:
        return _SideSeat(
          name: name,
          badge: badge,
          cardCount: cardCount,
          isLeft: true,
          isActive: isActive,
        );
      case _SeatAlignment.right:
        return _SideSeat(
          name: name,
          badge: badge,
          cardCount: cardCount,
          isLeft: false,
          isActive: isActive,
        );
      case _SeatAlignment.bottom:
        return _BottomSeat(
          name: name,
          badge: badge,
          cardCount: cardCount,
          isActive: isActive,
          bottomCards: bottomCards,
          selectedCardIndex: selectedBottomCardIndex,
          onCardTap: onBottomCardTap,
          onCardSwipe: onBottomCardSwipe,
        );
    }
  }
}

class _TopSeat extends StatelessWidget {
  const _TopSeat({
    required this.name,
    required this.badge,
    required this.cardCount,
    required this.isActive,
  });

  final String name;
  final String badge;
  final int cardCount;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CardFan(
          cardCount: cardCount,
          direction: Axis.horizontal,
          faceUp: false,
          compact: true,
        ),
        const SizedBox(height: 6),
        _PlayerInfoChip(
          name: name,
          badge: badge,
          avatarSize: 36,
          showTurnDot: isActive,
        ),
      ],
    );
  }
}

class _SideSeat extends StatelessWidget {
  const _SideSeat({
    required this.name,
    required this.badge,
    required this.cardCount,
    required this.isLeft,
    required this.isActive,
  });

  final String name;
  final String badge;
  final int cardCount;
  final bool isLeft;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _CardFan(
          cardCount: cardCount,
          direction: Axis.horizontal,
          faceUp: false,
          compact: true,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 78,
          child: _PlayerInfoChip(
            name: name,
            badge: badge,
            avatarSize: 36,
            compact: true,
            showTurnDot: isActive,
          ),
        ),
      ],
    );
  }
}

class _BottomSeat extends StatelessWidget {
  const _BottomSeat({
    required this.name,
    required this.badge,
    required this.cardCount,
    required this.isActive,
    this.bottomCards,
    this.selectedCardIndex,
    this.onCardTap,
    this.onCardSwipe,
  });

  final String name;
  final String badge;
  final int cardCount;
  final bool isActive;
  final List<PlayingCard>? bottomCards;
  final int? selectedCardIndex;
  final ValueChanged<int>? onCardTap;
  final ValueChanged<int>? onCardSwipe;

  @override
  Widget build(BuildContext context) {
    final visibleCards =
        (bottomCards ?? const <PlayingCard>[]).take(5).toList(growable: false);
    final clampedSelectedIndex = (selectedCardIndex != null &&
            selectedCardIndex! >= 0 &&
            selectedCardIndex! < visibleCards.length)
        ? selectedCardIndex
        : null;
    const largeCardHeight = 172.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: largeCardHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Transform.translate(
              offset: const Offset(0, -4),
              child: _CardFan(
                cardCount: visibleCards.length,
                direction: Axis.horizontal,
                faceUp: true,
                large: true,
                cards: visibleCards,
                selectedIndex: clampedSelectedIndex,
                onCardTap: onCardTap,
                onCardSwipe: onCardSwipe,
                availableWidth: constraints.maxWidth,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlayerInfoChip extends StatelessWidget {
  const _PlayerInfoChip({
    required this.name,
    required this.badge,
    required this.avatarSize,
    this.showTurnDot = false,
    this.compact = false,
    this.highlighted = false,
  });

  final String name;
  final String badge;
  final double avatarSize;
  final bool showTurnDot;
  final bool compact;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color:
              highlighted ? const Color(0xB070120E) : const Color(0x991F120F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                highlighted ? const Color(0xE0E4C267) : const Color(0x66FFFFFF),
            width: highlighted ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SeatAvatar(size: avatarSize, highlighted: highlighted),
            const SizedBox(height: 4),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.94),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xB070120E) : const Color(0x991F120F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              highlighted ? const Color(0xE0E4C267) : const Color(0x66FFFFFF),
          width: highlighted ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SeatAvatar(size: avatarSize, highlighted: highlighted),
          SizedBox(width: compact ? 6 : 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.94),
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 5 : 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: highlighted
                      ? const Color(0xFFD4AF37)
                      : Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: highlighted
                        ? const Color(0xFF41210E)
                        : Colors.white.withValues(alpha: 0.86),
                    fontSize: compact ? 8 : 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (showTurnDot) ...[
            const SizedBox(width: 8),
            Container(
              width: compact ? 7 : 9,
              height: compact ? 7 : 9,
              decoration: const BoxDecoration(
                color: Color(0xFFF4C86E),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeatAvatar extends StatelessWidget {
  const _SeatAvatar({
    required this.size,
    this.highlighted = false,
  });

  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: highlighted
              ? const [Color(0xFFF5CF7C), Color(0xFFB77A1D)]
              : const [Color(0xFFE8D8C0), Color(0xFFAD8D6D)],
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        color: const Color(0xFF4A2414),
        size: size * 0.58,
      ),
    );
  }
}

class _CardFan extends StatelessWidget {
  const _CardFan({
    required this.cardCount,
    required this.direction,
    this.faceUp = false,
    this.compact = false,
    this.large = false,
    this.cards,
    this.selectedIndex,
    this.onCardTap,
    this.onCardSwipe,
    this.availableWidth,
  });

  final int cardCount;
  final Axis direction;
  final bool faceUp;
  final bool compact;
  final bool large;
  final List<PlayingCard>? cards;
  final int? selectedIndex;
  final ValueChanged<int>? onCardTap;
  final ValueChanged<int>? onCardSwipe;
  final double? availableWidth;

  @override
  Widget build(BuildContext context) {
    final compactDensity = compact ? ((cardCount - 5).clamp(0, 7) / 7) : 0.0;
    final cardWidth =
        compact ? (32.0 - (compactDensity * 5.0)) : (large ? 123.5 : 32.0);
    final cardHeight =
        compact ? (43.0 - (compactDensity * 6.8)) : (large ? 163.4 : 48.0);
    final overlap = compact
        ? (7.6 - (compactDensity * 3.2))
        : (large
            ? _fitLargeOverlap(cardWidth, cardCount, availableWidth)
            : 17.0);
    final totalExtent = cardWidth + ((cardCount - 1) * overlap);

    return SizedBox(
      width: direction == Axis.horizontal ? totalExtent : cardHeight,
      height: direction == Axis.horizontal ? cardHeight : totalExtent,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(cardCount, (index) {
          final offset = index * overlap;
          double dragUpDistance = 0;
          final center = (cardCount - 1) / 2;
          final distanceFromCenter = (index - center).abs();
          final maxDistance = center == 0 ? 1.0 : center;
          // Gentle arc so compact fans feel curved but even on top.
          final compactArcLift = compact && direction == Axis.horizontal
              ? -((1 - (distanceFromCenter / maxDistance)) *
                  (2.0 - (compactDensity * 0.8)))
              : 0.0;
          // Smooth parabolic arc for large bottom hand cards ΓÇö center card
          // lifts UP, edges stay put, creating a natural held-in-hand curve.
          final normalizedDist =
              (distanceFromCenter / maxDistance).clamp(0.0, 1.0);
          final largeArcLift = large && !compact && direction == Axis.horizontal
              ? -(1.0 - normalizedDist * normalizedDist) * 14.0
              : 0.0;
          final isSelected = selectedIndex == index &&
              direction == Axis.horizontal &&
              !compact &&
              large;
          final lift = isSelected ? -46.0 : -14.0;
          final scale = isSelected ? 1.18 : 1.0;
          final cardNode = Transform.translate(
            offset: Offset(
              0,
              (isSelected ? lift : 0.0) + compactArcLift + largeArcLift,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onCardTap == null ? null : () => onCardTap!(index),
              onPanStart: onCardSwipe == null
                  ? null
                  : (_) {
                      dragUpDistance = 0;
                    },
              onPanUpdate: onCardSwipe == null
                  ? null
                  : (details) {
                      if (!faceUp || !large) return;
                      // Track upward drag distance to support slow swipes too.
                      dragUpDistance += (-details.delta.dy);
                    },
              onPanEnd: onCardSwipe == null
                  ? null
                  : (details) {
                      final isPlayableSwipe = faceUp &&
                          large &&
                          (details.velocity.pixelsPerSecond.dy < -90 ||
                              dragUpDistance > 26);
                      if (isPlayableSwipe) {
                        onCardSwipe!(index);
                      }
                    },
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.bottomCenter,
                child: Transform.rotate(
                  alignment: large ? Alignment.bottomCenter : Alignment.center,
                  angle: direction == Axis.horizontal
                      ? ((index - (cardCount - 1) / 2) *
                          (large
                              ? 0.05
                              : (compact
                                  ? (0.035 - (compactDensity * 0.012))
                                  : 0.04)))
                      : ((index - (cardCount - 1) / 2) *
                          (compact ? 0.015 : 0.025)),
                  child: _MiniCard(
                    width: cardWidth,
                    height: cardHeight,
                    faceUp: faceUp,
                    card: cards != null && index < cards!.length
                        ? cards![index]
                        : null,
                    highlighted: isSelected && faceUp,
                  ),
                ),
              ),
            ),
          );

          // Animate card re-settling when a card is removed:
          // - Bottom hand (large faceUp): 220ms smooth close gap
          // - Opponent fans (compact): 180ms snappy close gap
          final shouldAnimate = direction == Axis.horizontal &&
              (large && faceUp || compact);
          if (shouldAnimate) {
            return AnimatedPositioned(
              key: ValueKey(compact ? 'compact_fan_$index' : 'bottom_hand_$index'),
              duration: Duration(milliseconds: compact ? 180 : 220),
              curve: Curves.easeOutCubic,
              left: direction == Axis.horizontal ? offset : 0,
              top: direction == Axis.horizontal ? 0 : offset,
              child: cardNode,
            );
          }

          return Positioned(
            left: direction == Axis.horizontal ? offset : 0,
            top: direction == Axis.horizontal ? 0 : offset,
            child: cardNode,
          );
        }),
      ),
    );
  }

  double _fitLargeOverlap(
      double cardWidth, int cardCount, double? availableWidth) {
    if (availableWidth == null || cardCount <= 1) {
      return 64.0;
    }
    final horizontalPadding = 0.0;
    final usableWidth =
        (availableWidth - horizontalPadding).clamp(cardWidth, double.infinity);
    final fittedOverlap = (usableWidth - cardWidth) / (cardCount - 1);
    return fittedOverlap.clamp(36.0, 64.0);
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.width,
    required this.height,
    required this.faceUp,
    this.card,
    this.highlighted = false,
  });

  final double width;
  final double height;
  final bool faceUp;
  final PlayingCard? card;
  final bool highlighted;

  static final PlayingCard _placeholder =
      PlayingCard(Suit.hearts, CardValue.ace);

  @override
  Widget build(BuildContext context) {
    final effective = card ?? _placeholder;

    if (!faceUp) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2.2),
          border: Border.all(
            color: const Color(0xFFF7F7F7),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1.2),
            child: CustomPaint(
              painter: _CardBackCarpetPainter(),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3.1),
          // Keep a subtle natural edge, not heavy 3D.
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: highlighted ? 0.24 : 0.16),
              blurRadius: highlighted ? 4.2 : 3.4,
              offset: const Offset(0, 1.4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3.1),
          child: Padding(
            // Tiny safe inset so values like "10" are never clipped.
            padding: const EdgeInsets.all(0.9),
            child: PlayingCardView(
              card: effective,
              showBack: false,
              elevation: 0.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.1),
                side: highlighted
                    ? const BorderSide(
                        color: Color(0xFFF4C86E),
                        width: 2.8,
                      )
                    : BorderSide(
                        color: Colors.black.withValues(alpha: 0.82),
                        width: 0.8,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBackCarpetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()..color = const Color(0xFF7A5C3D);
    canvas.drawRect(rect, base);

    final bandPaint = Paint()..color = const Color(0xFF9B3026);
    final midBand =
        Rect.fromLTWH(0, size.height * 0.28, size.width, size.height * 0.44);
    canvas.drawRect(midBand, bandPaint);

    final stripe1 = Paint()..color = const Color(0xFF1A6A57);
    final stripe2 = Paint()..color = const Color(0xFFD79E39);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.40, size.width, size.height * 0.06),
      stripe1,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.54, size.width, size.height * 0.06),
      stripe2,
    );

    final border = Paint()
      ..color = const Color(0xFFDFA74A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CenterTrickZone extends StatefulWidget {
  const _CenterTrickZone({
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
  final List<_PlayedCardEntry> playedCardsInTrick;
  final _SeatAlignment? collectWinnerSeat;
  final int collectAnimationTick;
  final Map<_SeatAlignment, int> wonTrickPiles;
  final Map<_SeatAlignment, List<double>> wonTrickPileAngles;
  final int bottomThrowCardIndex;
  final int bottomThrowHandCount;
  final VoidCallback onCollectAnimationFinished;

  static const Map<_SeatAlignment, Offset> _seatOffsets = {
    _SeatAlignment.top: Offset(0, -70),
    _SeatAlignment.left: Offset(-34, -30),
    _SeatAlignment.right: Offset(36, -29),
    _SeatAlignment.bottom: Offset(0, 0),
  };

  static const Map<_SeatAlignment, double> _seatAngles = {
    // UI tuning: avoid strict 90deg/180deg orientations.
    // Keep right/left stronger, but top/bottom near-straight with light
    // diagonal tilt.
    _SeatAlignment.right: 1.22173, // 70deg
    _SeatAlignment.left: 1.91986, // 110deg
    _SeatAlignment.bottom: 0.10472, // 6deg
    _SeatAlignment.top: -0.10472, // -6deg
  };

  @override
  State<_CenterTrickZone> createState() => _CenterTrickZoneState();
}

class _CenterTrickZoneState extends State<_CenterTrickZone>
    with TickerProviderStateMixin {
  static const _allSeats = [
    _SeatAlignment.left,
    _SeatAlignment.top,
    _SeatAlignment.right,
    _SeatAlignment.bottom,
  ];

  static const Map<_SeatAlignment, Offset> _throwStartOffsets = {
    _SeatAlignment.left: Offset(-112, -12),
    // Start from partner name-box area.
    _SeatAlignment.top: Offset(0, -180),
    _SeatAlignment.right: Offset(112, -12),
    // Start deep from user's hand zone ΓÇö matches the actual card position
    // so there's no visible teleport when the card leaves the hand.
    _SeatAlignment.bottom: Offset(0, 270),
  };

  static const Map<_SeatAlignment, double> _throwStartAngles = {
    _SeatAlignment.left: -0.20,
    _SeatAlignment.top: 0.10,
    _SeatAlignment.right: 0.20,
    _SeatAlignment.bottom: 0.12,
  };
  static const Map<_SeatAlignment, double> _throwArcStrength = {
    // Per-seat arc feel tuning for more natural throws.
    _SeatAlignment.left: 0.15,
    _SeatAlignment.top: 0.22,
    _SeatAlignment.right: 0.14,
    _SeatAlignment.bottom: 0.19,
  };
  static const Map<_SeatAlignment, double> _throwSideCurve = {
    // Small lateral curve (+ right, - left) to avoid identical trajectories.
    _SeatAlignment.left: -6.0,
    _SeatAlignment.top: 0.0,
    _SeatAlignment.right: 6.0,
    _SeatAlignment.bottom: 0.0,
  };
  static const Map<_SeatAlignment, Offset> _winnerPileOffsets = {
    _SeatAlignment.top: Offset(0, -180),
    _SeatAlignment.left: Offset(-105, -10),
    // BUGFIX: Right winner must target screen-right pile (positive dx). Was
    // mistakenly same as left, so collect flew toward left opponent.
    _SeatAlignment.right: Offset(105, -10),
    // User winner pile sits under the bottom hand cards.
    _SeatAlignment.bottom: Offset(0, 180),
  };
  static const Map<_SeatAlignment, double> _winnerPileBaseAngles = {
    _SeatAlignment.right: 1.22173, // 70deg
    _SeatAlignment.left: 1.91986, // 110deg
    _SeatAlignment.bottom: 0.10472, // 6deg
    _SeatAlignment.top: -0.10472, // -6deg
  };

  Map<_SeatAlignment, AnimationController> _throwControllers = {};
  late final AnimationController _collectController;
  bool _controllersInitialized = false;
  int _lastCollectAnimationTick = 0;
  bool _isCollecting = false;
  int _lastTotalTrickCount = 0;
  final List<_CollectAnimEntry> _collectAnimEntries = [];
  final Map<int, _StaticImpactPose> _tableImpactPoses = {};
  final Map<_SeatAlignment, bool> _impactAppliedForSeat = {
    _SeatAlignment.left: false,
    _SeatAlignment.top: false,
    _SeatAlignment.right: false,
    _SeatAlignment.bottom: false,
  };
  final Map<_SeatAlignment, double> _impactContactStartTBySeat = {
    _SeatAlignment.left: 1.0,
    _SeatAlignment.top: 1.0,
    _SeatAlignment.right: 1.0,
    _SeatAlignment.bottom: 1.0,
  };
  final Map<_SeatAlignment, PlayingCard?> _animatingCards = {
    _SeatAlignment.left: null,
    _SeatAlignment.top: null,
    _SeatAlignment.right: null,
    _SeatAlignment.bottom: null,
  };
  // Dynamic X start offset for the bottom throw ΓÇö set per-throw based on
  // which card in the fan was swiped.
  double _bottomThrowStartDx = 0.0;
  // Dynamic start angle ΓÇö matches the card's tilt in the hand fan.
  double _bottomThrowStartAngle = 0.12;
  final Map<_SeatAlignment, int> _lastSeatCounts = {
    _SeatAlignment.left: 0,
    _SeatAlignment.top: 0,
    _SeatAlignment.right: 0,
    _SeatAlignment.bottom: 0,
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
  static const Map<_SeatAlignment, Duration> _throwDurations = {
    _SeatAlignment.bottom: Duration(milliseconds: 750),
    _SeatAlignment.right: Duration(milliseconds: 680),
    _SeatAlignment.left: Duration(milliseconds: 680),
    _SeatAlignment.top: Duration(milliseconds: 750),
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

  bool _shouldApplyImpactNow(_SeatAlignment seat, double tRaw) {
    final totalCount = widget.playedCardsInTrick.length;
    if (totalCount < 2) return false;

    final seatEntries = _entriesFor(seat);
    if (seatEntries.isEmpty) return false;
    final targetIndex = seatEntries.length - 1;
    final moving = _computeThrowPose(seat, tRaw, targetIndex);

    // Top static card before incoming one is always previous global throw.
    final staticGlobalIndex = totalCount - 2;
    final staticEntry = widget.playedCardsInTrick[staticGlobalIndex];
    final staticSeat = staticEntry.seat;
    final staticSeatIndex = _seatIndexAtGlobalIndex(staticGlobalIndex);
    final baseDx = (_CenterTrickZone._seatOffsets[staticSeat]?.dx ?? 0.0) +
        (staticSeatIndex * 1.6);
    final baseDy = (_CenterTrickZone._seatOffsets[staticSeat]?.dy ?? 0.0) -
        (staticSeatIndex * 1.2);
    final impact =
        _tableImpactPoses[staticGlobalIndex] ?? const _StaticImpactPose();
    final staticDx = baseDx + impact.dx;
    final staticDy = baseDy + impact.dy;

    final distance =
        (Offset(moving.dx, moving.dy) - Offset(staticDx, staticDy)).distance;
    // Trigger when incoming card is close to pile.
    const contactRadius = 80.0;
    return distance <= contactRadius || tRaw >= 0.70;
  }

  int _seatIndexAtGlobalIndex(int globalIndex) {
    final seat = widget.playedCardsInTrick[globalIndex].seat;
    int count = 0;
    for (int i = 0; i <= globalIndex; i++) {
      if (widget.playedCardsInTrick[i].seat == seat) {
        if (i == globalIndex) return count;
        count += 1;
      }
    }
    return count;
  }

  _ThrowPose _computeThrowPose(
      _SeatAlignment seat, double rawT, int targetIndex) {
    const bottomThrowCurve = Cubic(0.22, 0.68, 0.35, 1.0);
    final travelT = switch (seat) {
      _SeatAlignment.bottom => bottomThrowCurve.transform(rawT),
      _SeatAlignment.top    => Curves.easeOutCubic.transform(rawT),
      _SeatAlignment.left   => Curves.easeOutQuart.transform(rawT),
      _SeatAlignment.right  => Curves.easeOutQuart.transform(rawT),
    };
    final settleT = Curves.easeOutCubic.transform(rawT);

    final targetDx =
        (_CenterTrickZone._seatOffsets[seat]?.dx ?? 0) + (targetIndex * 1.6);
    final targetDy =
        (_CenterTrickZone._seatOffsets[seat]?.dy ?? 0) - (targetIndex * 1.2);
    final targetAngle =
        (_CenterTrickZone._seatAngles[seat] ?? 0) + (targetIndex * 0.004);

    final start = _throwStartOffsets[seat] ?? Offset.zero;
    final startAngle = _throwStartAngles[seat] ?? 0.0;

    final distanceY = (targetDy - start.dy).abs();
    final arcStrength = _throwArcStrength[seat] ?? 0.18;
    final arcBoost = switch (seat) {
      _SeatAlignment.top => 1.28,
      _SeatAlignment.bottom => 1.45,
      _SeatAlignment.left => 1.0,
      _SeatAlignment.right => 1.0,
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
      _SeatAlignment.left => 1.0, // card from left pushes right
      _SeatAlignment.right => -1.0, // card from right pushes left
      _SeatAlignment.bottom => 0.0, // card from bottom pushes up
      _SeatAlignment.top => 0.0, // card from top pushes down
    };
    final pushDirY = switch (incomingSeat) {
      _SeatAlignment.bottom => -1.0, // pushes upward
      _SeatAlignment.top => 1.0, // pushes downward
      _SeatAlignment.left => 0.0,
      _SeatAlignment.right => 0.0,
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

  List<_PlayedCardEntry> _entriesFor(_SeatAlignment seat) =>
      widget.playedCardsInTrick.where((entry) => entry.seat == seat).toList();

  @override
  void didUpdateWidget(covariant _CenterTrickZone oldWidget) {
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
        if (seat == _SeatAlignment.bottom) {
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
          final seat = played.seat;
          final seatEntries = _entriesFor(seat);
          final seatIndex = seatEntries.indexWhere((e) => identical(e, played));
          final indexInSeat = seatIndex < 0 ? 0 : seatIndex;
          final startDx = (_CenterTrickZone._seatOffsets[seat]?.dx ?? 0.0) +
              (indexInSeat * 1.6);
          final startDy = (_CenterTrickZone._seatOffsets[seat]?.dy ?? 0.0) -
              (indexInSeat * 1.2);
          final startAngle = (_CenterTrickZone._seatAngles[seat] ?? 0.0) +
              (indexInSeat * 0.004);
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
    final hideLatestForSeat = <_SeatAlignment, bool>{};
    final seatEntriesMap = <_SeatAlignment, List<_PlayedCardEntry>>{
      for (final seat in _allSeats) seat: _entriesFor(seat),
    };

    for (final seat in _allSeats) {
      final controller = _throwControllers[seat]!;
      final seatEntries = seatEntriesMap[seat] ?? const <_PlayedCardEntry>[];
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
                _SeatAlignment.bottom => bottomThrowCurve.transform(t),
                _SeatAlignment.top    => Curves.easeOutCubic.transform(t),
                _SeatAlignment.left   => Curves.easeOutQuart.transform(t),
                _SeatAlignment.right  => Curves.easeOutQuart.transform(t),
              };
              final settleT = Curves.easeOutCubic.transform(t);

              final targetIndex =
                  seatEntries.isEmpty ? 0 : (seatEntries.length - 1);
              final targetDx = (_CenterTrickZone._seatOffsets[seat]?.dx ?? 0) +
                  (targetIndex * 1.6);
              final targetDy = (_CenterTrickZone._seatOffsets[seat]?.dy ?? 0) -
                  (targetIndex * 1.2);
              final targetAngle = (_CenterTrickZone._seatAngles[seat] ?? 0) +
                  (targetIndex * 0.004);

              final start = seat == _SeatAlignment.bottom
                  ? Offset(_bottomThrowStartDx, _throwStartOffsets[seat]?.dy ?? 270)
                  : _throwStartOffsets[seat] ?? Offset.zero;
              final startAngle = seat == _SeatAlignment.bottom
                  ? _bottomThrowStartAngle
                  : _throwStartAngles[seat] ?? 0.0;

              // ΓöÇΓöÇ Parabolic arc (natural curve, not straight line) ΓöÇΓöÇ
              final distanceY = (targetDy - start.dy).abs();
              final arcStrength = _throwArcStrength[seat] ?? 0.18;
              final arcBoost = switch (seat) {
                _SeatAlignment.top => 1.28,
                _SeatAlignment.bottom => 1.45,
                _SeatAlignment.left => 1.0,
                _SeatAlignment.right => 1.0,
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
                _SeatAlignment.bottom: 0.12,
                _SeatAlignment.right: -0.06,
                _SeatAlignment.left: 0.06,
                _SeatAlignment.top: -0.05,
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
              final depthAmount = seat == _SeatAlignment.bottom ? 0.14 : 0.10;
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
              final liftOpacity = seat == _SeatAlignment.bottom
                  ? (t / 0.05).clamp(0.0, 1.0)
                  : 1.0;
              final liftScale = seat == _SeatAlignment.bottom
                  ? 0.92 + 0.08 * (t / 0.10).clamp(0.0, 1.0)
                  : 1.0;

              final card = _PlayedCardAt(
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

    // Render static trick cards in exact throw order so layering is correct:
    // first throw stays below, last throw stays on top.
    if (!_isCollecting) {
      final throwTick = Listenable.merge(_throwControllers.values.toList());
      children.add(
        AnimatedBuilder(
          animation: throwTick,
          builder: (context, _) {
            final staticCards = <Widget>[];
            final seatSeenCounts = <_SeatAlignment, int>{
              _SeatAlignment.left: 0,
              _SeatAlignment.top: 0,
              _SeatAlignment.right: 0,
              _SeatAlignment.bottom: 0,
            };
            for (int throwIndex = 0;
                throwIndex < widget.playedCardsInTrick.length;
                throwIndex++) {
              final entry = widget.playedCardsInTrick[throwIndex];
              final seat = entry.seat;
              final seatCount = (seatSeenCounts[seat] ?? 0);
              seatSeenCounts[seat] = seatCount + 1;
              final seatTotal = seatEntriesMap[seat]?.length ?? 0;
              final shouldHideLatest = hideLatestForSeat[seat] ?? false;
              if (shouldHideLatest && seatCount == seatTotal - 1) {
                continue;
              }
              final baseDx = _CenterTrickZone._seatOffsets[seat]?.dx ?? 0.0;
              final baseDy = _CenterTrickZone._seatOffsets[seat]?.dy ?? 0.0;
              final baseAngle = _CenterTrickZone._seatAngles[seat] ?? 0.0;
              final impactPose =
                  _tableImpactPoses[throwIndex] ?? const _StaticImpactPose();

              staticCards.add(
                TweenAnimationBuilder<double>(
                  key: ValueKey('table_pose_$throwIndex'),
                  tween: Tween<double>(begin: 0, end: 1),
                  // Smooth one-way slide to final impact position ΓÇö no bounce.
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) {
                    return _PlayedCardAt(
                      card: entry.card,
                      dx: baseDx + (seatCount * 1.6) + (impactPose.dx * t),
                      dy: baseDy - (seatCount * 1.2) + (impactPose.dy * t),
                      angle: baseAngle +
                          (seatCount * 0.004) +
                          (impactPose.angle * t),
                    );
                  },
                ),
              );
            }
            return Stack(
              alignment: Alignment.center,
              children: staticCards,
            );
          },
        ),
      );
    }
    // Keep in-flight thrown cards above static stack immediately.
    children.addAll(animatedChildren);

    // Render tiny won-trick piles in front of each winner seat.
    for (final seat in _allSeats) {
      final pileCount = widget.wonTrickPiles[seat] ?? 0;
      if (pileCount <= 0) continue;
      final pileOffset = _winnerPileOffsets[seat] ?? Offset.zero;
      final angleHistory = widget.wonTrickPileAngles[seat] ?? const <double>[];
      final baseAngle = _winnerPileBaseAngles[seat] ?? 0.0;
      final visible = pileCount > 5 ? 5 : pileCount;
      for (int i = 0; i < visible; i++) {
        children.add(
          _PlayedCardAt(
            card: PlayingCard(Suit.spades, CardValue.ace),
            dx: pileOffset.dx + (i * 1.0),
            dy: pileOffset.dy - (i * 0.8),
            angle: i < angleHistory.length ? angleHistory[i] : baseAngle,
            faceUp: false,
            scale: 0.26,
            baseWidth: 80.0,
            baseHeight: 120.0,
          ),
        );
      }
    }

    if (_isCollecting && _collectAnimEntries.isNotEmpty) {
      children.add(
        AnimatedBuilder(
          animation: _collectController,
          builder: (context, _) {
            final t = Curves.easeInOutCubic.transform(_collectController.value);
            return Stack(
              alignment: Alignment.center,
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
                final bw = 90.0 + (80.0 - 90.0) * t;
                final bh = 160.0 + (120.0 - 160.0) * t;
                return _PlayedCardAt(
                  card: entry.card,
                  dx: dx,
                  dy: dy,
                  angle: angle,
                  faceUp: faceUp,
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
        children: children,
      ),
    );
  }
}

class _PlayedCardEntry {
  const _PlayedCardEntry({
    required this.seat,
    required this.card,
  });

  final _SeatAlignment seat;
  final PlayingCard card;
}

class _PlayedCardAt extends StatelessWidget {
  const _PlayedCardAt({
    required this.card,
    this.dx = 0,
    this.dy = 0,
    this.angle = 0,
    this.faceUp = true,
    this.scale = 1.0,
    this.baseWidth = 90.0,
    this.baseHeight = 160.0,
  });

  final PlayingCard card;
  final double dx;
  final double dy;
  final double angle;
  final bool faceUp;
  final double scale;
  final double baseWidth;
  final double baseHeight;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: angle,
        child: SizedBox(
          width: baseWidth * scale,
          height: baseHeight * scale,
          child: _MiniCard(
            width: baseWidth * scale,
            height: baseHeight * scale,
            faceUp: faceUp,
            card: card,
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

  final PlayingCard card;
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

class _MajlisBackground extends StatelessWidget {
  const _MajlisBackground({
    required this.mapAssetPath,
  });

  final String mapAssetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5A3328),
            Color(0xFF44261F),
            Color(0xFF301914),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              mapAssetPath,
              fit: BoxFit.fill,
              alignment: Alignment.center,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x14000000),
                  Colors.transparent,
                  Color(0x28000000),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium Glassmorphic Score Card Dialog
/// UI is permanent design, but data/functionality inside is currently hardcoded
/// for UI testing purposes only until game engine is hooked up.
class _ScoreCardDialog extends StatelessWidget {
  const _ScoreCardDialog();

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.88;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxH),
        // Outer thin gold metallic frame
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE4C267),
              Color(0xFF99732B),
              Color(0xFFE4C267),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Container(
          // Inner rich dark leather/wood background
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Color(0xFF2A1510),
                Color(0xFF140A07),
              ],
            ),
            borderRadius: BorderRadius.circular(18.5),
            border: Border.all(
              color: const Color(0x80E4C267),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.5),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'النشرة',
                          style: TextStyle(
                            color: Color(0xFFF3D88D),
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildClassicDivider(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildGameInfoRow(),
                    const SizedBox(height: 20),
                    _buildScoreTable(),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF3D88D), Color(0xFFC49A3E)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFC49A3E).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: const Color(0xFF2A1510),
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'عودة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassicDivider() {
    return Container(
      height: 2,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Color(0xFFC49A3E),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildGameInfoRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33E4C267)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'اللعبة: صن',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFEADBCE),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'المشتري أو المدبل: فريقنا',
                  textAlign: TextAlign.end,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFEADBCE),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'نتيجة الشراء: خسرانة',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFFFF5E5E),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x40E4C267)),
      ),
      child: Column(
        children: [
          _buildHeaderRow(),
          _buildClassicDivider(),
          _buildDataRow('الأكلات', '39', '81'),
          _buildDataRow('الأرض', '10', '-'),
          _buildDataRow('المشاريع', '-', '20'),
          _buildClassicDivider(),
          _buildDataRow('الأبناط', '49', '101', isBold: true),
          _buildClassicDivider(),
          _buildResultRow('0', '30'),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          const Expanded(flex: 2, child: SizedBox()),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'لنا',
                style: TextStyle(
                  color: const Color(0xFFE4C267),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 18, color: const Color(0x66E4C267)),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'لهم',
                style: TextStyle(
                  color: const Color(0xFFE4C267),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String usStr, String themStr, {bool isBold = false}) {
    final textColor = isBold ? Colors.white : const Color(0xFFEADBCE);
    final fontSize = isBold ? 17.0 : 16.0;
    final fontWeight = isBold ? FontWeight.w800 : FontWeight.w600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFC49A3E),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                usStr,
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                themStr,
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String usScore, String themScore) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0x26E4C267), // Very subtle gold tint
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: Text(
              'النتيجة',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFFE4C267),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                usScore,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                themScore,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
