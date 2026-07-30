# Baloot Home Screen — Option C: Abyssal Teal
### 2026 Jewel-Tone Dark · OLED-Optimised · Cursor Implementation Spec
> Pin this file as context in Cursor, then paste the prompts at the bottom one at a time.
> Run each prompt fully and test on device before moving to the next.

---

## WHY THIS PALETTE (research summary)

2026 mobile game design research identified three signals that shaped this option:

1. **Teal/blue-green is the dominant jewel tone of 2026** — it bridges natural depth
   and digital precision, and is currently unoccupied in the Arabic card game market.
2. **OLED-first dark mode** — near-black bases (not pure black) with 4 distinct
   surface levels are now the industry standard for flagship-phone apps.
3. **Gold contrasts hardest against teal** — warm gold (#C9A84C) and cool teal
   (#1A8C7A) sit opposite each other on the colour wheel, giving the highest
   perceived premium contrast of the three options.

---

## 1. COLOUR TOKENS — CREATE THIS FILE FIRST

Create `theme/balootColors.js` (or update your existing theme file).
Every component must reference these tokens. Zero hardcoded hex values elsewhere.

```js
// theme/balootColors.js

export const BalootColors = {

  // ── Backgrounds — 4 levels required for 2026 dark-mode spec ──
  bgCanvas:      '#080F12',   // Page root — OLED near-black with teal cast
  bgCard:        '#0D1A1F',   // Profile card, main content surfaces
  bgElevated:    '#132229',   // Play row, nav bar, button containers
  bgPanel:       '#18303C',   // Drawers, dropdowns, modal sheets

  // ── Teal — primary brand accent ──────────────────────────────
  tealPrimary:   '#1A8C7A',   // Avatar ring, badge borders, progress fill base
  tealLight:     '#2BB89F',   // Active nav label, menu icon, card title accents
  tealDark:      '#0D4F46',   // Teal shadow / depth layer in gradients
  tealBorder:    'rgba(26, 140, 122, 0.28)',  // Card and pill hairline borders
  tealBorderStrong: 'rgba(26, 140, 122, 0.55)', // Focused / selected state border

  // ── Gold — premium signature accent ──────────────────────────
  goldPrimary:   '#C9A84C',   // Game title, medal count, rank badge text, trophy icon
  goldLight:     '#E8C86A',   // Star icon, shimmer highlights
  goldDark:      '#8B6006',   // Gold shadow in avatar ring depth layers
  goldBorder:    'rgba(201, 168, 76, 0.25)',  // Gold card shimmer line, crown badge border

  // ── Emerald — Play button ONLY, do not reuse elsewhere ───────
  emerald:       '#135C40',   // Play button background
  emeraldHover:  '#1A7A55',   // Play button pressed/hover state
  emeraldBorder: 'rgba(43, 184, 159, 0.25)', // Play button border (teal tint)
  emeraldText:   '#C8F0DC',   // Text on the play button

  // ── Crimson — hearts / lives only ────────────────────────────
  crimson:       '#8B2A38',   // Heart icon colour
  crimsonBg:     '#1A080C',   // Heart stat pill background
  crimsonBorder: 'rgba(139, 42, 56, 0.40)',  // Heart pill border

  // ── Typography ───────────────────────────────────────────────
  textPrimary:   '#E8F4F2',   // Main text — username, scores, stat values
  textSecondary: '#7BAAA8',   // Labels, sub-text, secondary info
  textMuted:     '#3A5A5A',   // Disabled, placeholder, nav inactive, XP sub-text

  // ── Structural borders ───────────────────────────────────────
  borderDefault: 'rgba(255, 255, 255, 0.07)', // Default hairline on all containers
  borderStrong:  'rgba(255, 255, 255, 0.12)', // Dividers, section separators
};
```

---

## 2. DIAMOND BACKGROUND PATTERN

The background diamond/quilted pattern is kept but fully rethemed.

```
Root screen background:   BalootColors.bgCanvas  (#080F12)

Diamond overlay:
  - Pattern colour:   #1A8C7A  (tealPrimary)
  - Opacity:          0.05     ← critical — any higher looks cartoonish
  - Style:            repeating-linear-gradient at 45° and -45°, 1px lines, 22px spacing

Radial vignettes (two, subtle):
  - Top-left:   radial-gradient from bgCard (#0D1A1F) at 40% opacity → transparent
  - Bottom-right: same, gives depth without a flat feel
```

---

## 3. ELEMENT-BY-ELEMENT CHANGES

### 3a. Top navigation bar

```
Container background:     bgCanvas (#080F12)
No border or shadow — flush with screen edge.

LEFT button (Alerts / Notifications):
  background:             bgElevated (#132229)
  border:                 1px borderDefault
  borderRadius:           12
  icon:                   ti-bell
  iconColour:             textSecondary (#7BAAA8)
  accessibilityLabel:     "Notifications"
  REMOVE label text "Alerts" — icon only

RIGHT button (Menu):
  background:             bgElevated (#132229)
  border:                 1px borderDefault
  borderRadius:           12
  icon:                   ti-menu-2  (three lines)
  iconColour:             tealLight (#2BB89F)   ← teal here, not gold — differentiates from title
  accessibilityLabel:     "Main menu"
  REMOVE label text "More" — icon only

CENTRE title:
  text:                   "Baloot"
  colour:                 goldPrimary (#C9A84C)
  fontWeight:             700
  fontSize:               20
  letterSpacing:          1

Suit icons row (♠ ♥ ♣ ♦):
  spade (♠):              textMuted (#3A5A5A)
  heart (♥):              crimson (#8B2A38)
  club (♣):               textMuted (#3A5A5A)
  diamond (♦):            crimson (#8B2A38)
  fontSize:               11
```

---

### 3b. Profile card

```
Container:
  background:             bgCard (#0D1A1F)
  border:                 1px tealBorder  rgba(26,140,122,0.28)
  borderRadius:           20
  margin:                 6px 14px 12px
  padding:                14px

Top shimmer line:
  Position:               absolute, top:0, left:0, right:0, height:1px
  background:             linear-gradient(90deg,
                            transparent,
                            rgba(26,140,122,0.35),
                            transparent)
  — This gives a subtle lit-from-above effect on the card top edge
```

**Stat pills (top row)**

```
STAR pill:
  background:             rgba(26,140,122,0.10)
  border:                 1px tealBorder
  icon:                   ti-star
  iconColour:             goldPrimary (#C9A84C)   ← gold on teal pill = premium
  valueColour:            textPrimary (#E8F4F2)
  accessibilityLabel:     "0 gold stars"

SPARKLES pill:
  background:             rgba(26,140,122,0.10)
  border:                 1px tealBorder
  icon:                   ti-sparkles
  iconColour:             tealLight (#2BB89F)
  valueColour:            textPrimary (#E8F4F2)
  accessibilityLabel:     "0 special points"

HEART pill:
  background:             crimsonBg (#1A080C)
  border:                 1px crimsonBorder  rgba(139,42,56,0.40)
  icon:                   ti-heart
  iconColour:             crimson (#8B2A38)
  valueColour:            textPrimary (#E8F4F2)
  accessibilityLabel:     "0 hearts"

All pills:
  borderRadius:           20
  padding:                5px 10px
  gap between icon and value: 4px
```

**Avatar ring**

```
Outer ring:
  width/height:           72px
  shape:                  circle (borderRadius 50%)
  background:             conic-gradient(
                            #1A8C7A 0%,
                            #0D4F46 40%,
                            #2BB89F 70%,
                            #1A8C7A 100%
                          )
  — Gives the ring a rotating shimmer effect even when static

Inner circle:
  width/height:           62px
  background:             bgCard (#0D1A1F)
  borderRadius:           50%

Default avatar icon:      ti-user
iconColour:               textSecondary (#7BAAA8)
iconSize:                 28

Rank badge (below avatar):
  position:               absolute, bottom:-2, centred horizontally
  background:             tealPrimary (#1A8C7A)
  text colour:            bgCanvas (#080F12)   ← dark text on teal = readable
  text:                   "Expert"  (sentence case — NOT "EXPERT")
  fontSize:               9
  fontWeight:             700
  padding:                1px 6px
  borderRadius:           6
```

**Username + info**

```
Username "Ghh LoF":
  colour:                 textPrimary (#E8F4F2)
  fontSize:               17
  fontWeight:             700

Card icon (right of username):
  icon:                   ti-playing-card
  colour:                 textMuted (#3A5A5A)
  fontSize:               22
```

**Badge row (left + right of avatar area)**

```
LEFT badge (rank/shield):
  width/height:           38px
  background:             rgba(26,140,122,0.10)
  border:                 1px tealBorder
  borderRadius:           10
  icon:                   ti-shield-star
  iconColour:             tealPrimary (#1A8C7A)
  iconSize:               18
  accessibilityLabel:     "Rank badge"

RIGHT badge (VIP/crown):
  width/height:           38px
  background:             rgba(201,168,76,0.10)
  border:                 1px goldBorder
  borderRadius:           10
  icon:                   ti-crown
  iconColour:             goldPrimary (#C9A84C)
  iconSize:               18
  accessibilityLabel:     "VIP badge"

  NOTE: Left badge uses TEAL, right badge uses GOLD.
  The contrast between the two creates visual interest within the card.
```

**Progress / XP bar**

```
Row (medal + rank + xp text):
  Medal icon:             ti-medal, colour goldPrimary (#C9A84C), size 13
  Medal count "7":        colour goldPrimary, fontSize 13, fontWeight 700
  Rank pill "Expert":
    background:           rgba(26,140,122,0.12)
    border:               1px tealBorder
    text:                 tealLight (#2BB89F)
    fontSize:             10
    fontWeight:           700
    padding:              2px 8px
    borderRadius:         6

  XP text "1,820 of 2,800 to Legend":
    colour:               textMuted (#3A5A5A)
    fontSize:             11
    NOTE: Update from "1,820 / 2,800 Medals" to "1,820 of 2,800 to Legend"

Progress bar track:
  background:             rgba(255,255,255,0.05)
  height:                 6
  borderRadius:           3
  width:                  100%

Progress bar fill (65% filled):
  background:             linear-gradient(90deg,
                            #0D4F46,    ← tealDark
                            #1A8C7A,    ← tealPrimary
                            #2BB89F     ← tealLight
                          )
  borderRadius:           3

ARIA attributes (add to the progress bar element):
  role="progressbar"
  aria-valuenow={1820}
  aria-valuemin={0}
  aria-valuemax={2800}
  aria-label="1,820 of 2,800 medals to Legend rank"
```

---

### 3c. Play / action row

```
Container:
  background:             bgElevated (#132229)
  border:                 1px borderDefault
  borderRadius:           18
  margin:                 0 14px 10px
  padding:                4px
  display:                flex, align-items center, gap 4px

LEFT button (Leaderboard):
  width:                  48px
  height:                 56px
  background:             rgba(255,255,255,0.04)
  border:                 1px borderDefault
  borderRadius:           14
  icon:                   ti-list-numbers
  iconColour:             textSecondary (#7BAAA8)
  iconSize:               22
  accessibilityLabel:     "Leaderboard"

CENTRE play button:
  flex:                   1
  height:                 56px
  background:             emerald (#135C40)
  border:                 1px emeraldBorder  rgba(43,184,159,0.25)
  borderRadius:           14
  text:                   "Play"
  textColour:             emeraldText (#C8F0DC)
  fontSize:               18
  fontWeight:             700
  fontFamily:             Cairo

  Inner top highlight:
    position:             absolute, top:0, left:10%, right:10%, height:1px
    background:           rgba(43,184,159,0.20)
    — Subtle lit-edge on play button top

RIGHT button (Mode selector):
  width:                  56px
  height:                 56px
  background:             rgba(255,255,255,0.04)
  border:                 1px borderDefault
  borderRadius:           14
  icon:                   ti-chevron-down
  iconColour:             textSecondary (#7BAAA8)
  label text:             "Game type"   ← change from "MODE"
  labelColour:            textMuted (#3A5A5A)
  labelSize:              9
  labelWeight:            500
```

---

### 3d. "Baloot Cup" divider label

```
Text content:             "· · · Live now · · ·"
colour:                   rgba(26,140,122,0.35)    ← teal at low opacity
fontSize:                 10
fontWeight:               400
letterSpacing:            3
textTransform:            uppercase
textAlign:                center
marginBottom:             8
```

---

### 3e. Kammelna Cup tournament banner

```
Container:
  margin:                 0 14px 14px
  background:             linear-gradient(135deg,
                            #08100D 0%,     ← near-black teal base
                            #0D1A15 40%,    ← slightly lighter
                            #0A1410 100%    ← back to deep
                          )
  border:                 1px tealBorder  rgba(26,140,122,0.28)
  borderRadius:           16
  padding:                12px 14px
  display:                flex, align-items center, gap 10px
  overflow:               hidden

Left edge shimmer overlay:
  position:               absolute, inset 0
  background:             linear-gradient(90deg,
                            rgba(26,140,122,0.07),
                            transparent 55%
                          )
  pointerEvents:          none

Trophy icon (left):
  icon:                   ti-trophy
  colour:                 goldPrimary (#C9A84C)
  size:                   28
  accessibilityLabel:     "Tournament"

Title "Kammelna Cup":
  colour:                 tealLight (#2BB89F)    ← NOT gold here — teal keeps hierarchy
  fontSize:               15
  fontWeight:             700

Subtitle:
  text:                   "Live now · Enter the cup"
  colour:                 rgba(43,184,159,0.45)
  fontSize:               11

Right icon (card/joker):
  icon:                   ti-playing-card
  colour:                 textMuted (#3A5A5A)
  size:                   22
  opacity:                0.6

accessibilityRole:        "button"  (if banner is tappable)
accessibilityLabel:       "Kammelna Cup tournament — Live now"
```

---

### 3f. Bottom navigation bar

```
Container:
  background:             bgCanvas (#080F12)
  borderTop:              1px borderStrong  rgba(255,255,255,0.12)
  paddingBottom:          12   (device safe area — use SafeAreaView or equivalent)
  paddingTop:             8

INACTIVE items (Store, Community, Tournaments, Chat):
  iconColour:             textMuted (#3A5A5A)
  labelColour:            textMuted (#3A5A5A)
  fontSize:               10
  fontWeight:             500

ACTIVE item (Home):
  iconColour:             tealLight (#2BB89F)
  labelColour:            tealLight (#2BB89F)
  fontSize:               10
  fontWeight:             600
  Active pill behind icon:
    background:           rgba(26,140,122,0.12)
    borderRadius:         12
    padding:              6px 14px

ICON ASSIGNMENTS:
  Store →                 ti-shopping-bag
  Community →             ti-users-group
  Home →                  ti-home  (or ti-playing-card for game identity)
  Tournaments →           ti-trophy
  Chat →                  ti-message-circle

All icons: strokeWidth 1.5, no fill
accessibilityRole on each: "tab"
accessibilityState on active: { selected: true }
```

---

## 4. BUGS — FIX IN PROMPT 3 (before any styling)

These must be resolved before visual work so styling is applied to clean code.

### Bug 1 — Duplicate hearts counter
```
Symptom:  Two hearts values are visible simultaneously, often showing
          conflicting numbers.
Fix:      Search the home screen component tree for all heart/life renders.
          Delete every duplicate. Bind the remaining one to a SINGLE
          state variable. Apply crimsonBg / crimson styling from Section 1.
```

### Bug 2 — Currency bar invisible / zero-height
```
Symptom:  Currency bar does not render — appears as a gap or zero-height element.
Fix:      Add explicit styles:
            background: BalootColors.bgElevated (#132229)
            height: 36
            colour: BalootColors.textPrimary (#E8F4F2)
            padding: 0 12px
          Check for opacity:0, display:none, or a missing data prop
          causing a conditional null return. Remove the conditional or
          provide a default value.
```

### Bug 3 — VIP Store inside Game Modes panel
```
Symptom:  VIP Store entry appears nested inside the Game Modes dropdown/panel.
Fix:      Remove VIP Store from the modes list entirely.
          It belongs in the Store tab flow.
          The modes list must contain ONLY game variant options
          (e.g. Regular, Sun/Moon, Limited Play, etc.).
```

### Bug 4 — Bright blue Game Modes panel
```
Symptom:  Game Modes panel background is a bright cobalt/electric blue
          that conflicts with the dark theme.
Fix:      Replace panel background with BalootColors.bgElevated (#132229).
          Border: 1px BalootColors.borderDefault.
          This is covered by the play-row styling in Section 3c but
          flag it as a priority bug — the panel must not render until fixed.
```

---

## 5. ICON REFERENCE TABLE

All icons: Tabler Icons, strokeWidth={1.5}, no fill.
Install: `npm install @tabler/icons-react-native` (RN) or `@tabler/icons-react` (web).

| Location | Current | Replace with | Colour token |
|---|---|---|---|
| Notifications button | Bell / emoji | `ti-bell` | `textSecondary` #7BAAA8 |
| Menu button | ≡ lines | `ti-menu-2` | `tealLight` #2BB89F |
| Star stat pill | ⭐ emoji | `ti-star` | `goldPrimary` #C9A84C |
| Sparkles stat pill | ✦ emoji | `ti-sparkles` | `tealLight` #2BB89F |
| Heart stat pill | ♥ emoji | `ti-heart` | `crimson` #8B2A38 |
| Left rank badge | Circle star | `ti-shield-star` | `tealPrimary` #1A8C7A |
| Right VIP badge | Circle star | `ti-crown` | `goldPrimary` #C9A84C |
| Medal count | 🏅 emoji | `ti-medal` | `goldPrimary` #C9A84C |
| Leaderboard button | 🏆 trophy | `ti-list-numbers` | `textSecondary` #7BAAA8 |
| Mode/type chevron | ↓ text | `ti-chevron-down` | `textSecondary` #7BAAA8 |
| Tournament trophy | 🏆 emoji | `ti-trophy` | `goldPrimary` #C9A84C |
| Card visual | 🃏 emoji | `ti-playing-card` | `textMuted` #3A5A5A |
| Store nav | 🛍 emoji | `ti-shopping-bag` | `textMuted` / `tealLight` (active) |
| Community nav | 👥 emoji | `ti-users-group` | `textMuted` |
| Home nav | 🃏 emoji | `ti-home` | `textMuted` / `tealLight` (active) |
| Tournaments nav | 🏆 emoji | `ti-trophy` | `textMuted` |
| Chat nav | 💬 emoji | `ti-message-circle` | `textMuted` |
| Chest / reward | (not present) | `ti-diamond` | `goldPrimary` #C9A84C |

---

## 6. ACCESSIBILITY REQUIREMENTS

Add these to every interactive element in the same pass as icons.

```
Notifications button:    accessibilityLabel="Notifications"
                         accessibilityRole="button"

Menu button:             accessibilityLabel="Main menu"
                         accessibilityRole="button"

Star pill:               accessibilityLabel="0 gold stars"
Sparkles pill:           accessibilityLabel="0 special points"
Heart pill:              accessibilityLabel="0 hearts remaining"

Avatar + rank:           accessibilityLabel="Player avatar — Expert rank"

Left badge:              accessibilityLabel="Rank badge"
Right badge:             accessibilityLabel="VIP badge"

Progress bar:            role="progressbar"  (web) / accessibilityRole="progressbar" (RN)
                         aria-valuenow={1820}
                         aria-valuemin={0}
                         aria-valuemax={2800}
                         aria-label="1,820 of 2,800 medals to Legend rank"

Leaderboard button:      accessibilityLabel="Leaderboard"
                         accessibilityRole="button"

Play button:             accessibilityLabel="Play Baloot"
                         accessibilityRole="button"

Mode button:             accessibilityLabel="Select game type"
                         accessibilityRole="button"

Tournament banner:       accessibilityLabel="Kammelna Cup — Live now. Tap to enter."
                         accessibilityRole="button"  (if tappable)

Nav items:               accessibilityRole="tab"
                         accessibilityState={{ selected: isActive }}
                         accessibilityLabel on each: "Store", "Community", "Home", "Tournaments", "Chat"
```

**Contrast check for Option C palette (WCAG AA = 4.5:1 minimum):**
```
textPrimary #E8F4F2 on bgCard #0D1A1F:         ~14.8:1  ✅ PASS
goldPrimary #C9A84C on bgCard #0D1A1F:          ~8.2:1  ✅ PASS
tealLight #2BB89F on bgCard #0D1A1F:            ~6.9:1  ✅ PASS
emeraldText #C8F0DC on emerald #135C40:         ~7.1:1  ✅ PASS
bgCanvas (#080F12) on teal rank badge #1A8C7A:  ~5.5:1  ✅ PASS
textMuted #3A5A5A on bgCanvas #080F12:          ~3.1:1  ⚠️  ONLY use for decorative/
                                                         non-essential text (inactive nav)
```

---

## 7. TYPOGRAPHY

```
Font family:    Cairo (Arabic + Latin support)
                Fallback: -apple-system, BlinkMacSystemFont, sans-serif

Element                 Size    Weight    Colour token
─────────────────────────────────────────────────────────────
Game title "Baloot"     20px    700       goldPrimary
Username                17px    700       textPrimary
Rank badge text         9px     700       bgCanvas (dark on teal bg)
Rank pill text          10px    700       tealLight
Star / sparkle values   12px    600       textPrimary
Heart value             12px    600       textPrimary
Medal count             13px    700       goldPrimary
XP sub-text             11px    400       textMuted
Play button             18px    700       emeraldText
Mode sub-label          9px     500       textMuted
"Live now" divider      10px    400       rgba(26,140,122,0.35)
Tournament title        15px    700       tealLight
Tournament subtitle     11px    400       rgba(43,184,159,0.45)
Nav labels (inactive)   10px    500       textMuted
Nav labels (active)     10px    600       tealLight

CASING RULE: Only "EXPERT" all-caps rank text needs fixing.
Change all ALL-CAPS labels to sentence case:
  "EXPERT" → "Expert"
  "MODE"   → "Game type"  (also change the label itself per Section 3c)
```

---

## 8. CURSOR PROMPTS — PASTE ONE AT A TIME

Pin `baloot-homescreen-option-c-abyssal-teal.md` as context before starting.
Wait for each prompt to fully complete before pasting the next.

---

### PROMPT 1 — Colour token file
```
Using the spec in baloot-homescreen-option-c-abyssal-teal.md, create the
colour token file at theme/balootColors.js exactly as written in Section 1.
Include every token — backgrounds, teal, gold, emerald, crimson, typography,
and borders. Do not change any component files yet. Tokens only.
```

---

### PROMPT 2 — Background and screen root
```
Using baloot-homescreen-option-c-abyssal-teal.md Section 2, update the
home screen root background:
- Set background to BalootColors.bgCanvas
- Retheme the diamond overlay: colour #1A8C7A (tealPrimary), opacity 0.05
- Add the two radial vignettes at top-left and bottom-right using bgCard
Do not touch any other component. Background only.
```

---

### PROMPT 3 — Fix the 4 bugs (do this before any visual work)
```
Using baloot-homescreen-option-c-abyssal-teal.md Section 4, fix all four bugs:
1. Remove the duplicate hearts counter — find both render locations, delete the
   duplicate, and bind to a single state variable.
2. Fix the invisible currency bar — add explicit background, height, padding,
   and colour from BalootColors.
3. Move VIP Store out of the Game Modes panel into the Store tab.
4. Change Game Modes panel background to BalootColors.bgElevated (#132229).
Do not change anything visual beyond what the bug fix requires.
```

---

### PROMPT 4 — Install icons and replace emoji
```
Using baloot-homescreen-option-c-abyssal-teal.md Section 5:
1. Install @tabler/icons-react-native (or @tabler/icons-react if this is a
   web project).
2. Replace every emoji and inconsistent icon in the home screen with the
   Tabler icon listed in the table. Set strokeWidth={1.5} on all icons.
3. Apply the colour token from the table to each icon.
4. Add the accessibilityLabel from Section 6 to every icon-only button.
Do not apply any background or layout changes yet — icons and labels only.
```

---

### PROMPT 5 — Top navigation bar
```
Using baloot-homescreen-option-c-abyssal-teal.md Section 3a, restyle the
top bar:
- Notifications button: bgElevated background, borderDefault border, ti-bell
  icon in textSecondary. Remove the "Alerts" text label.
- Menu button: bgElevated background, ti-menu-2 icon in tealLight (#2BB89F).
  Remove the "More" text label.
- Game title "Baloot": goldPrimary colour, fontWeight 700, fontSize 20.
- Suit icons: spade/club in textMuted, heart/diamond in crimson.
Do not change the profile card or anything below the top bar.
```

---

### PROMPT 6 — Profile card
```
Using baloot-homescreen-option-c-abyssal-teal.md Section 3b, fully restyle
the profile card:
- Card container: bgCard background, tealBorder, borderRadius 20, shimmer line
- Star pill: teal background/border, gold icon
- Sparkles pill: teal background/border, teal icon
- Heart pill: crimsonBg background, crimsonBorder, crimson icon
- Avatar ring: conic-gradient using tealDark/tealPrimary/tealLight
- Avatar inner: bgCard background
- Rank badge below avatar: tealPrimary background, bgCanvas text, "Expert"
- Username: textPrimary colour
- Left badge: teal background/border, ti-shield-star in tealPrimary
- Right badge: gold background/border, ti-crown in goldPrimary
- Rank pill: teal background/border, tealLight text, "Expert" sentence case
- XP text: "1,820 of 2,800 to Legend", textMuted colour
- Progress bar: rgba(255,255,255,0.05) track, teal gradient fill
- Progress bar ARIA attributes as listed in Section 3b
Do not change anything outside the profile card.
```

---

### PROMPT 7 — Play row, divider, tournament banner
```
Using baloot-homescreen-option-c-abyssal-teal.md Sections 3c, 3d, and 3e:

Play row:
- Container: bgElevated, borderDefault, borderRadius 18
- Leaderboard button: rgba(255,255,255,0.04) background, ti-list-numbers in textSecondary
- Play button: emerald (#135C40) background, emeraldBorder, emeraldText (#C8F0DC),
  inner top highlight line
- Mode button: rgba(255,255,255,0.04) background, ti-chevron-down in textSecondary,
  label changed to "Game type" in textMuted

Divider label:
- Change text to "· · · Live now · · ·"
- Apply rgba(26,140,122,0.35) colour, fontSize 10, letterSpacing 3, uppercase

Tournament banner:
- Dark teal gradient background as specified
- tealBorder border
- ti-trophy icon in goldPrimary
- Title "Kammelna Cup" in tealLight
- Subtitle "Live now · Enter the cup" in rgba(43,184,159,0.45)
- Left shimmer overlay as specified
```

---

### PROMPT 8 — Bottom navigation bar
```
Using baloot-homescreen-option-c-abyssal-teal.md Section 3f:
- Container: bgCanvas background, borderStrong top border, safe-area padding
- All inactive items: icons and labels in textMuted (#3A5A5A)
- Active Home item: icons and label in tealLight (#2BB89F),
  active pill background rgba(26,140,122,0.12)
- Apply icon replacements from Section 5 to each nav item
- Add accessibilityRole="tab" and accessibilityState to each item
```

---

### PROMPT 9 — Final typography and accessibility pass
```
Using baloot-homescreen-option-c-abyssal-teal.md Sections 6 and 7:
1. Check every text element on the home screen against the typography table.
   Apply the correct fontSize, fontWeight, and colour token to each.
2. Change any ALL-CAPS rank text from "EXPERT" to "Expert".
3. Add every accessibilityLabel, accessibilityRole, and accessibilityState
   listed in Section 6 to the corresponding element.
4. Verify fontFamily is Cairo on all game-facing text with the correct fallback.
Do not touch any layout, background, or game logic.
```

---

*End of spec. Run Prompts 1–9 in order. Screenshot and compare with Kammelna after Prompt 3 (bugs), Prompt 6 (card), and Prompt 9 (final). The teal+gold combination should feel noticeably more premium than the current build after Prompt 6.*
