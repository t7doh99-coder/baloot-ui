# 🎴 Card Animation System — Complete Design Spec
# For: Royal Baloot Card Game (Flutter)
# Reference: Kamelna (كملنا) + Jawaker (جواكر) Apps
# Status: FINAL — Ready for Implementation
# Related: See MAJLIS_THEME_DESIGN.md for background theme

---

## 📋 Overview

This document specifies **every animation** in the Baloot card game UI. The game follows
a deal → bid → play → score loop, and each phase has distinct animations. All animations
are designed to match the premium feel of Kamelna/Jawaker while running smoothly at 60fps.

**Game Flow & Animation Sequence:**
```
┌─────────┐   ┌─────────┐   ┌──────────┐   ┌─────────┐   ┌─────────┐
│  DEAL   │ → │  BID    │ → │  DOUBLE  │ → │  PLAY   │ → │  SCORE  │
│ Anim 1  │   │ Anim 5  │   │ Anim 9   │   │ Anim 2-4│   │ Anim 6  │
│ Anim 8  │   │ Anim 7  │   │          │   │ Anim 7  │   │         │
└─────────┘   └─────────┘   └──────────┘   └─────────┘   └─────────┘
                                                               │
                                              ┌────────────────┘
                                              ↓
                                         Next Round or
                                         Game Over (Anim 10)
```

---

## 🃏 Card Widget Specifications

### Card Dimensions
```
┌──────────────────┐
│                  │  Height: 100px (base)
│     CARD FACE    │  Width:  70px (base)
│                  │  Ratio:  1:1.43
│   Rank + Suit    │  Corner radius: 6px
│                  │  Border: 1px #DDDDDD
└──────────────────┘

Scale variants:
- Bottom player (you):  100% (70×100)
- Top player (partner): 60%  (42×60)
- Left/Right players:   55%  (38×55)
- Center played cards:  85%  (60×85)
- Buyer card (reveal):  100% (70×100)
```

### Card Face Design
```dart
class CardWidget extends StatelessWidget {
  final CardModel card;
  final bool faceUp;
  final double scale;

  // Face-up: White background, rank top-left and bottom-right,
  // suit symbol in center, colored pips (red=hearts/diamonds, black=spades/clubs)
  // Face-down: Dark navy (#1B2838) with gold ornate pattern overlay
}
```

### Card Shadow
```dart
BoxShadow(
  color: Colors.black.withOpacity(0.3),
  blurRadius: 4,
  offset: Offset(2, 3),     // resting
  // During flight: blurRadius: 8, offset: Offset(4, 6)
)
```

---

## 🎬 Animation 1: Card Dealing

**When:** Game starts a new round, after bidding completes.
**What:** Cards fly one-by-one from center deck stack to each player.

### Dealing Sequence (Matches Real Baloot Rules)
```
Phase 1: Deal 3 cards to each player
  → Player order: dealer+1, dealer+2, dealer+3, dealer (counter-clockwise)
  → 12 cards total, staggered

Phase 2: Deal 2 cards to each player
  → Same order, 8 more cards
  → Buyer card revealed after this phase (Animation 8)

Phase 3: Bidding happens (no dealing animation)

Phase 4: Deal remaining 3 cards to each player
  → Buyer gets 2 + buyer card, others get 3
  → 13 cards total (12 dealt + 1 buyer card to winner)
```

### Animation Properties
| Property | Value | Notes |
|----------|-------|-------|
| Per-card duration | `200ms` | Time for one card to reach destination |
| Stagger delay | `80ms` | Gap between consecutive cards |
| Easing curve | `Curves.easeOutCubic` | Fast start, gentle landing |
| Scale | `0.4 → 1.0` | Card grows as it approaches player |
| Rotation | `0° → targetAngle` | Rotates to match fan angle |
| Path | Straight line | From center deck → player position |
| Opacity | `0.0 → 1.0` | Fade in during first 30% of journey |

### Flutter Implementation
```dart
class DealingAnimation extends StatefulWidget {
  final int targetSeat;      // 0=bottom, 1=right, 2=top, 3=left
  final int cardIndex;       // Position in fan (0-7)
  final int dealOrder;       // Stagger order (0-31)
  final VoidCallback onComplete;

  // ...
}

class _DealingAnimationState extends State<DealingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotationAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Delay start based on deal order
    Future.delayed(Duration(milliseconds: widget.dealOrder * 80), () {
      if (mounted) _controller.forward();
    });

    // Position: center → target seat position
    final targetOffset = _getSeatOffset(widget.targetSeat);
    _positionAnim = Tween<Offset>(
      begin: Offset.zero,  // center of table
      end: targetOffset,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Scale: small → full size
    _scaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Rotation: 0 → fan angle for this card
    final targetAngle = _getFanAngle(widget.targetSeat, widget.cardIndex);
    _rotationAnim = Tween<double>(begin: 0.0, end: targetAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  Offset _getSeatOffset(int seat) {
    switch (seat) {
      case 0: return Offset(0, 280);     // bottom
      case 1: return Offset(150, 0);     // right
      case 2: return Offset(0, -250);    // top
      case 3: return Offset(-150, 0);    // left
      default: return Offset.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _positionAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: Transform.rotate(
              angle: _rotationAnim.value,
              child: CardWidget(card: widget.card, faceUp: widget.targetSeat == 0),
            ),
          ),
        );
      },
    );
  }
}
```

### Sound Effect
- File: `assets/sounds/card_deal.mp3`
- Trigger: On each card start
- Duration: ~100ms soft "whoosh/slide" sound
- Volume: 30%

---

## 🎬 Animation 2: Hand Fan Layout

**When:** Cards are in the bottom player's (your) hand.
**What:** Cards spread in a curved arc, interactive with tap/drag.

### Fan Geometry
```
Fan Arc Diagram (Bottom Player):

     ╭─ Card 1 (leftmost, rotated -25°)
    ╭──── Card 2 (rotated -18°)
   ╭─────── Card 3 (rotated -10°)
  ╭────────── Card 4 (rotated -3°)   ← center-ish
  ╰────────── Card 5 (rotated +3°)
   ╰─────── Card 6 (rotated +10°)
    ╰──── Card 7 (rotated +18°)
     ╰─ Card 8 (rightmost, rotated +25°)

Fan origin point: bottom-center of screen (off-screen pivot)
Total arc: ~50-60° spread
Card overlap: ~55-65% (adjustable based on card count)
```

### Fan Properties
| Property | 8 Cards | 7 Cards | 6 Cards | 5 Cards |
|----------|---------|---------|---------|---------|
| Total arc angle | 56° | 49° | 42° | 35° |
| Per-card angle | 8° | 8° | 8° | 8° |
| Card overlap | 60% | 55% | 50% | 45% |

### Interaction States
```
┌──────────────────────────────────────────┐
│ STATE: NORMAL                            │
│ All cards at rest position in fan arc     │
│                                          │
│ STATE: HOVER/TOUCH                       │
│ Touched card slides UP by 25px           │
│ Duration: 150ms, Curves.easeOut          │
│ Adjacent cards shift apart slightly (5px)│
│                                          │
│ STATE: SELECTED (tapped)                 │
│ Card slides UP by 40px                   │
│ Scale: 1.0 → 1.1                        │
│ Glow: Subtle gold border appears         │
│ Duration: 200ms, Curves.easeOutBack      │
│                                          │
│ STATE: PLAYED (confirmed)                │
│ Card flies to center → Animation 3       │
│ Remaining cards re-fan smoothly          │
│ Duration: 250ms for re-fan              │
└──────────────────────────────────────────┘
```

### Flutter Implementation
```dart
class InteractiveCardFan extends StatefulWidget {
  final List<CardModel> cards;
  final ValueChanged<CardModel>? onCardSelected;
  final bool isMyTurn;

  // ...
}

class _InteractiveCardFanState extends State<InteractiveCardFan> {
  int? _hoveredIndex;
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final cardCount = widget.cards.length;
    final totalArc = cardCount * 8.0;  // degrees
    final startAngle = -totalArc / 2;

    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: List.generate(cardCount, (i) {
          final angle = startAngle + (i * 8.0);
          final radians = angle * (pi / 180);
          final isHovered = _hoveredIndex == i;
          final isSelected = _selectedIndex == i;
          final yOffset = isSelected ? -40.0 : (isHovered ? -25.0 : 0.0);

          return AnimatedPositioned(
            duration: Duration(milliseconds: isSelected ? 200 : 150),
            curve: isSelected ? Curves.easeOutBack : Curves.easeOut,
            bottom: yOffset,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _hoveredIndex = i),
              onTapUp: (_) => _onCardTap(i),
              onTapCancel: () => setState(() => _hoveredIndex = null),
              child: AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: Duration(milliseconds: 200),
                child: Transform.rotate(
                  angle: radians,
                  alignment: Alignment.bottomCenter,
                  child: CardWidget(
                    card: widget.cards[i],
                    faceUp: true,
                    highlighted: isSelected,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
```

### Opponent Hand Fans (Face-Down)
```
Top Player:    Horizontal fan, face-down, 55% scale
               Cards arc DOWNWARD (pivot at top of screen)
               No interaction

Left Player:   Vertical fan (rotated 90° CW), face-down, 55% scale
               Cards arc toward center
               No interaction

Right Player:  Vertical fan (rotated 90° CCW), face-down, 55% scale
               Cards arc toward center
               No interaction
```

---

## 🎬 Animation 3: Card Play (Hand → Center)

**When:** A player (you or bot) plays a card.
**What:** Card flies from player position to center play area.

### Flight Path
```dart
// Each player's card lands at a specific offset from center,
// angled TOWARD the player who played it:

const Map<int, CardLandingPosition> landingPositions = {
  0: CardLandingPosition(  // Bottom player (you)
    offset: Offset(0, 35),
    rotation: -3.0 * (pi / 180),  // slight tilt
  ),
  1: CardLandingPosition(  // Right player
    offset: Offset(45, 5),
    rotation: 8.0 * (pi / 180),
  ),
  2: CardLandingPosition(  // Top player (partner)
    offset: Offset(-5, -35),
    rotation: 5.0 * (pi / 180),
  ),
  3: CardLandingPosition(  // Left player
    offset: Offset(-45, -5),
    rotation: -8.0 * (pi / 180),
  ),
};
```

### Animation Properties
| Property | Value |
|----------|-------|
| Duration | `300ms` |
| Easing | `Curves.easeOutQuad` |
| Path type | Bezier curve (slight arc upward) |
| Rotation | Current fan angle → landing rotation |
| Scale | Player scale → 85% (center card size) |
| Shadow | Grows during flight: blur 4→8, offset 2→4 |
| Z-index | Flying card renders above everything |

### Flutter Implementation
```dart
class CardFlightAnimation extends StatefulWidget {
  final CardModel card;
  final int fromSeat;          // 0-3
  final Offset startPosition;  // Global position
  final VoidCallback onComplete;

  // ...
}

class _CardFlightAnimationState extends State<CardFlightAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward().then((_) => widget.onComplete());
  }

  @override
  Widget build(BuildContext context) {
    final landing = landingPositions[widget.fromSeat]!;
    final centerPos = _getCenterPlayAreaPosition(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutQuad.transform(_controller.value);

        // Bezier curve path
        final midPoint = Offset(
          (widget.startPosition.dx + centerPos.dx) / 2,
          (widget.startPosition.dy + centerPos.dy) / 2 - 30, // arc upward
        );

        final currentPos = _quadBezier(
          widget.startPosition,
          midPoint,
          centerPos + landing.offset,
          t,
        );

        return Positioned(
          left: currentPos.dx,
          top: currentPos.dy,
          child: Transform.rotate(
            angle: lerpDouble(0, landing.rotation, t)!,
            child: Transform.scale(
              scale: lerpDouble(1.0, 0.85, t)!,
              child: CardWidget(card: widget.card, faceUp: true),
            ),
          ),
        );
      },
    );
  }

  Offset _quadBezier(Offset p0, Offset p1, Offset p2, double t) {
    final x = pow(1 - t, 2) * p0.dx + 2 * (1 - t) * t * p1.dx + pow(t, 2) * p2.dx;
    final y = pow(1 - t, 2) * p0.dy + 2 * (1 - t) * t * p1.dy + pow(t, 2) * p2.dy;
    return Offset(x.toDouble(), y.toDouble());
  }
}
```

### Sound Effect
- File: `assets/sounds/card_play.mp3`
- Trigger: On card placement
- Duration: ~150ms "card slap on table"
- Volume: 50%

---

## 🎬 Animation 4: Trick Collection (Sweep to Winner)

**When:** All 4 players have played a card for the current trick.
**What:** 4 cards pause → gather → sweep to winner's position.

### Sequence Timeline
```
Time 0ms     : All 4 cards sitting in center (visible)
Time 0-800ms : PAUSE — Players see the result, winner highlighted
Time 800ms   : Winner's avatar flashes gold briefly
Time 800-1000ms: GATHER — All 4 cards slide to center point (overlap)
Time 1000-1400ms: SWEEP — Card stack slides toward winner's seat
Time 1400-1600ms: FADE — Cards shrink (0.3 scale) + fade (0 opacity)
Time 1600ms  : Cards removed from widget tree, trick counter +1
```

### Flutter Implementation
```dart
class TrickSweepAnimation extends StatefulWidget {
  final int winnerSeat;         // 0-3
  final List<CardPlayModel> trickCards;  // 4 cards with seat info
  final VoidCallback onComplete;

  // ...
}

class _TrickSweepAnimationState extends State<TrickSweepAnimation>
    with TickerProviderStateMixin {
  late AnimationController _gatherController;
  late AnimationController _sweepController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    // Phase 1: Gather (200ms)
    _gatherController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Phase 2: Sweep to winner (400ms)
    _sweepController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Phase 3: Fade out (200ms)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Sequential execution with pause
    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(Duration(milliseconds: 800));  // pause
    await _gatherController.forward();                   // gather
    await _sweepController.forward();                    // sweep
    await _fadeController.forward();                     // fade
    widget.onComplete();
  }

  Offset _getWinnerDirection(int seat) {
    switch (seat) {
      case 0: return Offset(0, 300);     // sweep down to you
      case 1: return Offset(200, 0);     // sweep right
      case 2: return Offset(0, -300);    // sweep up to partner
      case 3: return Offset(-200, 0);    // sweep left
      default: return Offset.zero;
    }
  }
}
```

### Sound Effect
- File: `assets/sounds/trick_sweep.mp3`
- Trigger: At sweep start (800ms mark)
- Duration: ~300ms "cards sliding/scooping" sound
- Volume: 40%

---

## 🎬 Animation 5: Bidding UI Overlay

**When:** Game enters bidding phase.
**What:** Action buttons appear for the current bidder.

### Button Layout — Round 1
```
┌──────────────────────────────────┐
│                                  │
│  ┌────────┐ ┌────────┐ ┌──────┐ │
│  │  حكم   │ │  صن    │ │ بس   │ │
│  │ (gold) │ │ (blue) │ │(gray)│ │
│  └────────┘ └────────┘ └──────┘ │
│                                  │
│  ┌────────┐  ← Only for Dealer  │
│  │ أشكال  │     and Sane seats  │
│  │(purple)│                      │
│  └────────┘                      │
└──────────────────────────────────┘
```

### Button Layout — Round 2
```
┌──────────────────────────────────┐
│                                  │
│  ┌────────┐ ┌──────────┐ ┌────┐ │
│  │  صن    │ │ حكم ثاني │ │ بس │ │
│  │ (blue) │ │  (gold)  │ │gray│ │
│  └────────┘ └──────────┘ └────┘ │
│                                  │
└──────────────────────────────────┘
```

### Button Layout — Double Window
```
┌──────────────────────────────────┐
│                                  │
│  ┌────────┐  ┌──────────┐       │
│  │  دبل   │  │   تخطي   │       │
│  │ (red)  │  │  (gray)  │       │
│  └────────┘  └──────────┘       │
│                                  │
└──────────────────────────────────┘

Escalation progression:
  دبل (Double) → ثري (Triple) → فور (Four) → قهوة (Gahwa)
```

### Animation Properties
| Property | Appear | Disappear |
|----------|--------|-----------|
| Duration | `300ms` | `200ms` |
| Easing | `Curves.easeOutBack` | `Curves.easeIn` |
| Direction | Slide UP from bottom | Slide DOWN + fade |
| Scale | `0.8 → 1.0` | `1.0 → 0.9` |
| Backdrop | Fade in dark overlay (30% black) | Fade out |

### Button Specs
```dart
// Button dimensions
const double buttonWidth = 90;
const double buttonHeight = 44;
const double buttonRadius = 12;
const double fontSize = 16; // Arabic text

// Button colors
const hakamColor = Color(0xFFC9A84C);     // Gold
const sunColor = Color(0xFF2196F3);        // Blue
const passColor = Color(0xFF616161);        // Gray
const ashkalColor = Color(0xFF7B1FA2);     // Purple
const doubleColor = Color(0xFFD32F2F);     // Red
const skipColor = Color(0xFF757575);        // Gray
const gahwaColor = Color(0xFFB71C1C);      // Dark Red
```

### Bot Bid Indicator
When a bot (non-you player) bids, show a speech bubble near their avatar:
```
  ╭──────────────╮
  │  حكم / بس    │   ← Shows what they bid
  │              │
  ╰──────╥───────╯
         ║  ← Pointer toward avatar
```
- Duration visible: 1200ms
- Entry: Scale up from 0 (pop) — 200ms, `easeOutBack`
- Exit: Fade out — 300ms

---

## 🎬 Animation 6: Score Overlay (Round End)

**When:** All 8 tricks are completed and round is scored.
**What:** Results modal appears with animated counters.

### Layout
```
╔═══════════════════════════════════════════╗
║              نتيجة الجولة                ║
║         (Round Result)                    ║
╠═════════════════╦═════════════════════════╣
║      لنا        ║        لهم             ║
║    (Our Team)   ║    (Their Team)        ║
╠─────────────────╬────────────────────────╣
║                 ║                        ║
║    ┌─────┐      ║      ┌─────┐          ║
║    │ +14 │ ←count║     │ +2  │ ←count   ║
║    └─────┘      ║      └─────┘          ║
║                 ║                        ║
║  ┌──────────┐   ║                        ║
║  │ سرا +2   │   ║                        ║
║  └──────────┘   ║                        ║
║                 ║                        ║
║  ┌──────────┐   ║                        ║
║  │ بلوت +2  │   ║                        ║
║  └──────────┘   ║                        ║
║                 ║                        ║
╠═════════════════╩═════════════════════════╣
║                                          ║
║  Special badge (if applicable):          ║
║  ┌────────────────────────────┐          ║
║  │  🏆 كبوت! (KABOUT!)       │          ║
║  │  or  كهمس (KHAMS!)        │          ║
║  └────────────────────────────┘          ║
║                                          ║
║          [متابعة]  (Continue)            ║
╚══════════════════════════════════════════╝
```

### Animation Sequence
| Time | What | Duration | Easing |
|------|------|----------|--------|
| 0ms | Dark backdrop fades in (40% black) | 200ms | `easeOut` |
| 200ms | Card slides DOWN from top | 400ms | `easeOutCubic` |
| 600ms | Score numbers count up (0 → final) | 800ms | `easeOutExpo` |
| 1400ms | Project badges appear (one by one) | 200ms each | `easeOutBack` |
| 1800ms | Special badge (Kabout/Khams) PULSES | 300ms × 3 | `easeInOut` loop |
| 3000ms+ | Tap "Continue" or auto-dismiss after 5s | 300ms | `easeIn` |

### Flutter Implementation
```dart
class ScoreCounterWidget extends StatefulWidget {
  final int targetValue;
  final Duration duration;

  // ...
}

class _ScoreCounterState extends State<ScoreCounterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = (widget.targetValue * _controller.value).round();
        return Text(
          '+$value',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: value > 0 ? Color(0xFFC9A84C) : Colors.white54,
          ),
        );
      },
    );
  }
}
```

### Sound Effects
- Score appear: "ding" sound
- Counter counting: Rapid soft "tick tick tick"
- Kabout/Khams: Celebration fanfare

---

## 🎬 Animation 7: Turn Indicator (Active Player Glow)

**When:** It's a player's turn to act (bid or play).
**What:** Their avatar border glows gold + circular timer appears.

### Glow Effect
```dart
class TurnGlowIndicator extends StatefulWidget {
  final bool isActive;

  // ...
}

// When active:
Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: Color(0xFFFFD700),  // Gold
      width: _pulseAnimation.value,  // 2px → 4px → 2px
    ),
    boxShadow: [
      BoxShadow(
        color: Color(0xFFFFD700).withOpacity(0.4),
        blurRadius: 12,
        spreadRadius: 2,
      ),
    ],
  ),
)

// Pulse animation: 1500ms looping
// Curves.easeInOut
```

### Timer Ring (10-second countdown)
```dart
class TurnTimerRing extends StatelessWidget {
  final double progress;  // 1.0 → 0.0 over 10 seconds

  // Circular progress indicator around avatar
  // Color transitions: Green (>60%) → Yellow (30-60%) → Red (<30%)

  Color get timerColor {
    if (progress > 0.6) return Color(0xFF4CAF50);      // Green
    if (progress > 0.3) return Color(0xFFFFC107);       // Yellow
    return Color(0xFFF44336);                            // Red
  }
}
```

---

## 🎬 Animation 8: Buyer Card Reveal (3D Flip)

**When:** After dealing Phase 2 (5 cards each), the buyer card flips face-up.
**What:** A face-down card in center does a 3D flip to reveal itself.

### Flip Sequence
```
Time 0ms     : Card face-down in center
Time 0-250ms : Card rotates Y-axis 0° → 90° (face-down disappears)
               Scale: 1.0 → 1.15 (growing)
Time 250ms   : SWAP — Switch from back widget to face widget
Time 250-500ms: Card rotates Y-axis 90° → 0° (face-up appears)
               Scale: 1.15 → 1.0 (settling)
Time 500-700ms: Golden glow burst (expand + fade)
Time 700ms   : Card at rest, face-up
```

### Flutter Implementation
```dart
class BuyerCardFlip extends StatefulWidget {
  final CardModel card;
  final VoidCallback onComplete;

  // ...
}

class _BuyerCardFlipState extends State<BuyerCardFlip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showFront = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _controller.addListener(() {
      if (_controller.value >= 0.5 && !_showFront) {
        setState(() => _showFront = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * pi;  // 0 → π
        final scale = 1.0 + 0.15 * sin(angle);  // peak at middle

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)  // perspective
            ..rotateY(angle)
            ..scale(scale),
          child: _showFront
              ? CardWidget(card: widget.card, faceUp: true)
              : CardWidget(card: widget.card, faceUp: false),
        );
      },
    );
  }
}
```

### Golden Glow Burst
```dart
// Expanding circle, gold, fading
// Duration: 200ms after flip completes
// Start: radius 0, opacity 0.6
// End:   radius 60, opacity 0.0
// Color: Color(0xFFFFD700)
```

---

## 🎬 Animation 9: Double Window Overlay

**When:** After bidding, the double window opens before play starts.
**What:** Double/Triple/Four/Gahwa escalation buttons.

### Escalation Chain Visual
```
Step 1: Defending team sees → [دبل] [تخطي]
Step 2: If doubled, buyer sees → [ثري] [قبول]
Step 3: If tripled, defender sees → [فور] [قبول]
Step 4: If four'd, buyer sees → [قهوة] [قبول]

Each step: button swap animation (300ms cross-fade)
```

### Animation of previous bid indicator:
```
After Double called:
  ╭─── "دبل!" bubble appears near caller ───╮
  │ Gold text, scale-pop animation           │
  │ Duration: 200ms appear, 1000ms visible   │
  ╰──────────────────────────────────────────╯
```

---

## 🎬 Animation 10: Game Over Celebration

**When:** A team reaches 152 points or Gahwa is called.
**What:** Victory screen with celebration effects.

### Winner Team Celebration
```
┌──────────────────────────────────────┐
│                                      │
│         🏆 مبروك! 🏆               │
│       (Congratulations!)             │
│                                      │
│     ┌──────────────────────┐         │
│     │  Team A Wins!        │         │
│     │  Final: 160 - 134    │         │
│     └──────────────────────┘         │
│                                      │
│     ✨ Confetti particles ✨         │
│                                      │
│     [لعبة جديدة] (New Game)          │
│     [الرئيسية] (Main Menu)           │
└──────────────────────────────────────┘
```

### Confetti Particles
- 50-100 small colored rectangles
- Fall from top with random X drift + rotation
- Colors: Gold, Red, Green, Blue, White
- Duration: 3 seconds continuous
- Physics: Gravity + slight wind sway

---

## 🔧 Animation Orchestrator

**Central controller that manages which animations play and when:**

```dart
class AnimationOrchestrator {
  // Queues animations and plays them sequentially
  // Ensures no conflicting animations run simultaneously

  Future<void> dealCards(List<CardDealEvent> events) async { /* ... */ }
  Future<void> playCard(int seat, CardModel card) async { /* ... */ }
  Future<void> collectTrick(int winnerSeat) async { /* ... */ }
  Future<void> showBiddingUI(BiddingPhase phase) async { /* ... */ }
  Future<void> showScoreOverlay(RoundScoreResult result) async { /* ... */ }
  Future<void> showGameOver(String winnerTeam) async { /* ... */ }

  // Timing constants
  static const dealDelay = Duration(milliseconds: 80);
  static const trickPause = Duration(milliseconds: 800);
  static const scoreDisplayTime = Duration(seconds: 5);
}
```

---

## 📦 File Structure

```
lib/features/game/presentation/
├── screens/
│   └── game_screen.dart              ← Main game screen
├── widgets/
│   ├── card/
│   │   ├── card_widget.dart          ← Single card (face-up/down)
│   │   ├── card_fan.dart             ← Fan layout for any player
│   │   ├── interactive_card_fan.dart  ← Tappable fan (bottom player)
│   │   └── card_back.dart            ← Card back design
│   ├── animations/
│   │   ├── animation_orchestrator.dart ← Central animation controller
│   │   ├── deal_animation.dart        ← Dealing cards animation
│   │   ├── card_flight.dart           ← Card play hand→center
│   │   ├── trick_sweep.dart           ← Trick collection sweep
│   │   ├── buyer_card_flip.dart       ← 3D card flip
│   │   ├── score_counter.dart         ← Counting up numbers
│   │   └── confetti.dart              ← Game over celebration
│   ├── overlays/
│   │   ├── bidding_overlay.dart       ← Bidding action buttons
│   │   ├── double_overlay.dart        ← Double/Triple/Four/Gahwa
│   │   ├── score_overlay.dart         ← Round results modal
│   │   └── game_over_overlay.dart     ← Victory screen
│   ├── player/
│   │   ├── player_position.dart       ← Avatar + cards + name
│   │   ├── turn_glow.dart             ← Active turn indicator
│   │   ├── turn_timer.dart            ← 10-second countdown ring
│   │   └── bid_bubble.dart            ← Bot bid speech bubble
│   └── hud/
│       ├── score_bar.dart             ← Top persistent score display
│       └── mode_badge.dart            ← "صن" / "حكم" indicator
```

---

## ⏱️ Complete Animation Timing Reference

| Animation | Trigger | Duration | Easing |
|-----------|---------|----------|--------|
| Card Deal | Round start | 200ms/card + 80ms stagger | `easeOutCubic` |
| Hand Fan arrange | After deal | 250ms | `easeOut` |
| Card hover | Touch | 150ms | `easeOut` |
| Card select | Tap | 200ms | `easeOutBack` |
| Card play flight | Confirmed play | 300ms | `easeOutQuad` |
| Hand re-fan | After card removed | 250ms | `easeOut` |
| Trick pause | 4 cards played | 800ms | — |
| Trick gather | After pause | 200ms | `easeIn` |
| Trick sweep | After gather | 400ms | `easeInBack` |
| Trick fade | After sweep | 200ms | `easeOut` |
| Buyer card flip | After Phase 2 deal | 500ms | linear (rotation) |
| Bidding buttons appear | Player's turn to bid | 300ms | `easeOutBack` |
| Bidding buttons dismiss | Bid placed | 200ms | `easeIn` |
| Bot bid bubble | Bot bids | 200ms appear + 1000ms hold | `easeOutBack` |
| Double overlay | After bidding | 300ms | `easeOutBack` |
| Score overlay slide-in | Round end | 400ms | `easeOutCubic` |
| Score counter | Inside overlay | 800ms | `easeOutExpo` |
| Project badge appear | After counter | 200ms each | `easeOutBack` |
| Turn glow pulse | Player's turn | 1500ms loop | `easeInOut` |
| Timer ring | Player's turn | 10000ms linear | linear |
| Game over confetti | Game ends | 3000ms | gravity physics |

---

> [!NOTE]
> This document is self-contained. It provides all timing, easing, layout, and code
> specifications needed to implement every animation in the Baloot card game UI.
> Use with MAJLIS_THEME_DESIGN.md for the complete visual experience.
