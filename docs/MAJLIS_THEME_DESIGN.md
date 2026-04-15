# 🏛️ Majlis Theme — Game Background Design Spec
# For: Royal Baloot Game Table Background
# Target: Flutter CustomPainter + Asset Layering
# Style Reference: Kamelna + Jawaker + Traditional Saudi Majlis

---

## 🎨 Design Vision

The game table should feel like you're sitting in a **luxurious Saudi Majlis (مجلس)** — a traditional
Arabic sitting room where men gather to play cards, drink Arabic coffee, and socialize. The atmosphere
is warm, intimate, and premium — think VIP private room, not a casual café.

**Mood Keywords:** Warm, Intimate, Luxurious, Arabian Heritage, VIP Dark, Gold Accents

---

## 🖼️ Background Layers (Bottom to Top)

The background is composed of **5 visual layers** stacked on top of each other:

### Layer 1: Room Walls (Outermost)
```
┌─────────────────────────────────────────┐
│                                         │
│   Dark walls with Arabic architectural  │
│   elements visible at the edges         │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │                                 │   │
│   │        (Table Area)             │   │
│   │                                 │   │
│   └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

**Specifications:**
- **Color:** Deep charcoal (#1A1A2E) to dark navy (#16213E) gradient
- **Visible Elements at edges:**
  - Arabic arched windows/doorways (top corners)
  - Geometric Islamic patterns (mashrabiya / مشربية) as subtle border decoration
  - Warm amber glow from hidden light sources (lanterns)
  - Subtle vignette effect (darker at edges, lighter toward center)

### Layer 2: Floor / Carpet Base
**The main table surface — designed to look like an ornate Arabian carpet on a dark floor.**

**Specifications:**
- **Primary carpet colors:** Deep burgundy (#8B1A1A), navy (#1B2838), gold accent (#C9A84C)
- **Carpet pattern:** Central medallion design (traditional Persian/Arabian style)
- **Carpet border:** Intricate geometric repeating pattern (2-3px gold line work)
- **Carpet size:** 75% of screen width, 65% of screen height (centered)
- **Outside carpet:** Dark hardwood floor texture (#2D1810) with subtle grain
- **Carpet material feel:** Slightly textured, not flat — use subtle noise/grain overlay

### Layer 3: Table Decorations (Ambient Props)
**Cultural props placed around the table edges to create atmosphere.**

Position these items in the table corners/edges, OUTSIDE the play area:

| Item | Position | Size | Description |
|------|----------|------|-------------|
| **دلة (Dallah)** — Arabic coffee pot | Top-left corner | 48×64px | Gold/brass traditional coffee pot with long spout |
| **فناجين (Finajeen)** — Coffee cups | Next to Dallah | 3 small cups, 16×16px each | Small handleless cups, arranged in a triangle |
| **تمر (Dates tray)** — Dates plate | Top-right corner | 48×48px | Small wooden/brass plate with brown dates |
| **مبخرة (Mabkhara)** — Incense burner | Bottom-left corner | 40×56px | Ornate brass incense burner with subtle smoke wisps |
| **سبحة (Misbaha)** — Prayer beads | Bottom-right corner | 32×32px | Amber/brown prayer beads in a coiled arrangement |
| **فانوس (Fanous)** — Lantern | Top corners (behind players) | 32×64px | Ornate hanging lantern with warm amber glow |

**Smoke Effect (from Mabkhara):**
- 3-4 semi-transparent white wisps
- Slow upward drift animation (8-10 seconds loop)
- Opacity: 0.1 to 0.3
- Use `CustomPainter` with animated Bezier curves

### Layer 4: Play Area (Center Carpet Detail)
**The central area where cards are played — highlighted region on the carpet.**

**Specifications:**
- **Shape:** Rounded rectangle with ornate border
- **Size:** 50% of screen width, 40% of screen height
- **Background:** Slightly lighter shade of the carpet (#3D1F1F or dark red-brown)
- **Border:** Double-line gold border with corner flourishes
- **Corner Flourishes:** Small Islamic geometric rosettes at each corner
- **Inner pattern:** Subtle repeating geometric pattern at 5% opacity (barely visible)
- **Drop shadow:** Subtle inset shadow to create depth (cards sit ON the carpet)

### Layer 5: Ambient Lighting & Effects
**Post-processing effects applied over everything.**

| Effect | Implementation |
|--------|---------------|
| **Vignette** | Radial gradient overlay: transparent center → 40% black at edges |
| **Warm glow** | Amber (#FFB347) radial gradient at 5% opacity from lantern positions |
| **Grain texture** | 2% opacity noise overlay for tactile carpet feel |
| **Ambient particles** | Optional: very subtle dust motes floating (2-3 at most, slow) |

---

## 🎨 Complete Color Palette

### Primary Colors
| Name | Hex | Usage |
|------|-----|-------|
| **Majlis Dark** | `#1A1A2E` | Room walls, deepest background |
| **Carpet Burgundy** | `#8B1A1A` | Main carpet color |
| **Carpet Navy** | `#1B2838` | Carpet secondary/border color |
| **Gold Accent** | `#C9A84C` | Borders, decorations, highlights |
| **Dark Wood** | `#2D1810` | Floor outside carpet |
| **Warm Amber** | `#FFB347` | Lantern glow, warm lighting |

### Secondary Colors
| Name | Hex | Usage |
|------|-----|-------|
| **Deep Purple** | `#16213E` | Gradient blend with dark walls |
| **Carpet Red-Brown** | `#3D1F1F` | Play area background |
| **Parchment** | `#F5E6CC` | Card faces, text backgrounds |
| **Brass** | `#B5861B` | Dallah, Mabkhara metalwork |
| **Smoke White** | `#E8E8E8` | Incense smoke wisps |

### UI Overlay Colors
| Name | Hex + Alpha | Usage |
|------|------------|-------|
| **HUD Background** | `#1A1A2E` @ 85% | Score bar, bidding overlay |
| **Button Primary** | `#C9A84C` | Active/confirm buttons |
| **Button Danger** | `#D32F2F` | Reject/cancel buttons |
| **Turn Glow** | `#FFD700` @ 60% | Active player border glow |

---

## 📐 Layout Specifications (Portrait Mobile)

```
Screen: 390×844 (iPhone 14 reference)

┌──────────────── 390px ────────────────┐
│ ┌──────── Score Bar ────────────┐  ←8px│ 48px
│ │  [لنا: 138]  ⚡  [لهم: 97]   │     │
│ └───────────────────────────────┘     │
│                                       │
│      ╭── Top Player ──╮         ←80px │ 120px
│      │ [Cards Fan]    │              │
│      │ [Avatar+Name]  │              │
│      ╰────────────────╯              │
│                                       │
│ ╭Left╮  ╔═══════════════╗  ╭Right╮   │
│ │Card│  ║               ║  │Card │   │ 320px
│ │Fan │  ║  PLAY AREA    ║  │Fan  │   │ (center)
│ │    │  ║  (Carpet)     ║  │     │   │
│ │[Av]│  ║               ║  │[Av] │   │
│ ╰────╯  ╚═══════════════╝  ╰─────╯   │
│                                       │
│   ╭─── Bottom Player (You) ───╮  ←624│ 220px
│   │                           │      │
│   │  [Interactive Card Fan]   │      │
│   │  [Avatar + Name + Timer]  │      │
│   ╰───────────────────────────╯      │
└───────────────────────────────────────┘
```

---

## 🛠️ Flutter Implementation Guide

### File Structure
```
lib/features/game/presentation/
├── widgets/
│   ├── game_background.dart        ← Main background widget
│   ├── majlis_carpet_painter.dart   ← CustomPainter for carpet
│   ├── ambient_decorations.dart     ← Coffee pot, dates, incense
│   ├── smoke_effect_painter.dart    ← Animated incense smoke
│   └── vignette_overlay.dart        ← Post-processing effects
├── assets/ (referenced)
│   ├── textures/
│   │   ├── wood_floor.png          ← Tileable dark wood texture
│   │   ├── carpet_pattern.png      ← Carpet medallion center
│   │   ├── carpet_border.png       ← Repeating border pattern
│   │   └── grain_overlay.png       ← Subtle noise texture
│   └── decorations/
│       ├── dallah.png              ← Arabic coffee pot
│       ├── finajeen.png            ← Coffee cups
│       ├── dates_tray.png          ← Dates plate
│       ├── mabkhara.png            ← Incense burner
│       ├── misbaha.png             ← Prayer beads
│       └── lantern.png             ← Hanging lantern
```

### GameBackground Widget
```dart
class GameBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 1: Room walls (gradient)
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Color(0xFF16213E), // center: slightly lighter
                Color(0xFF1A1A2E), // edges: deep dark
              ],
            ),
          ),
        ),

        // Layer 2: Wood floor texture (if using asset)
        // Positioned.fill(child: Image.asset('assets/textures/wood_floor.png', fit: BoxFit.cover)),

        // Layer 3: Main carpet (CustomPainter)
        Center(
          child: CustomPaint(
            size: Size(screenWidth * 0.85, screenHeight * 0.70),
            painter: MajlisCarpetPainter(),
          ),
        ),

        // Layer 4: Ambient decorations
        AmbientDecorations(), // Positioned coffee pot, dates, incense

        // Layer 5: Vignette overlay
        VignetteOverlay(),

        // Layer 6: Grain texture (subtle)
        Opacity(
          opacity: 0.02,
          child: Image.asset('assets/textures/grain_overlay.png',
            fit: BoxFit.cover, repeat: ImageRepeat.repeat),
        ),
      ],
    );
  }
}
```

### MajlisCarpetPainter (Key Implementation)
```dart
class MajlisCarpetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw carpet base (rounded rect, burgundy fill)
    final carpetRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(16),
    );
    canvas.drawRRect(carpetRect, Paint()..color = Color(0xFF8B1A1A));

    // 2. Draw gold border (double line)
    canvas.drawRRect(carpetRect, Paint()
      ..color = Color(0xFFC9A84C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);

    // Inner border
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      Radius.circular(12),
    );
    canvas.drawRRect(innerRect, Paint()
      ..color = Color(0xFFC9A84C).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);

    // 3. Draw center medallion pattern
    // (Complex Islamic geometric pattern — use Path operations)
    _drawCenterMedallion(canvas, size);

    // 4. Draw corner flourishes
    _drawCornerFlourish(canvas, Offset(16, 16));      // top-left
    _drawCornerFlourish(canvas, Offset(size.width - 16, 16));  // top-right
    // ... etc

    // 5. Draw play area highlight
    final playArea = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.6,
        height: size.height * 0.55,
      ),
      Radius.circular(12),
    );
    canvas.drawRRect(playArea, Paint()
      ..color = Color(0xFF3D1F1F).withOpacity(0.4));
  }
}
```

---

## 📋 Asset Generation Checklist

These assets need to be created (by designer or AI image generation):

| Asset | Size | Format | Priority |
|-------|------|--------|----------|
| `wood_floor.png` | 512×512 tileable | PNG | HIGH |
| `carpet_pattern.png` | 1024×1024 | PNG with alpha | HIGH |
| `carpet_border.png` | 256×64 tileable | PNG with alpha | MEDIUM |
| `dallah.png` | 96×128 | PNG with alpha | HIGH |
| `finajeen.png` | 64×48 | PNG with alpha | HIGH |
| `dates_tray.png` | 96×96 | PNG with alpha | MEDIUM |
| `mabkhara.png` | 80×112 | PNG with alpha | MEDIUM |
| `misbaha.png` | 64×64 | PNG with alpha | LOW |
| `lantern.png` | 64×128 | PNG with alpha | MEDIUM |
| `grain_overlay.png` | 256×256 tileable | PNG | LOW |
| `mashrabiya_pattern.svg` | Vector | SVG | LOW |

---

## ✨ Animation Details for Background

### Incense Smoke (Continuous)
```dart
// 3 bezier curves drifting upward
// Each curve: 8-10 seconds, slightly different timing
// Colors: white @ 10-30% opacity
// Width: 2-4px, tapering at top
class SmokeEffectPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0, loops

  void paint(Canvas canvas, Size size) {
    final path = Path();
    // Sine-wave drift with upward movement
    for (double t = 0; t < progress; t += 0.01) {
      double x = sin(t * 3) * 15 + size.width / 2;
      double y = size.height * (1 - t);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3));
  }
}
```

### Lantern Glow (Pulsing)
```dart
// Slow amber pulse: 3-4 second cycle
// Opacity: 0.03 to 0.08
// Radius: 60-80px from lantern position
AnimationController(duration: Duration(seconds: 4), vsync: this)..repeat(reverse: true);
```

---

> [!NOTE]
> This document is designed to be self-contained enough for Cursor or any AI coding assistant
> to implement the Majlis background theme without additional context. All colors, sizes,
> positions, and implementation details are specified.
