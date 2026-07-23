# Baloot Home Screen — Option H: Sandstone
### Sandy Brown · Yellow-Brown Surfaces · Sandy Gold + Honey · 2026 Warm
> Pin this file as context in Cursor, then paste the numbered prompts one at a time.
> Complete each prompt fully and test on device before moving to the next.

---

## HOW THIS DIFFERS FROM OPTIONS D, E, AND G

All four options share the warm brown family but each leans a different direction:

| Layer     | D — Desert Dusk | E — Amber Sands | G — Walnut    | H — Sandstone   |
|-----------|-----------------|-----------------|---------------|-----------------|
| Canvas    | #0E0904         | #1E1408         | #130A05       | #1E1808         |
| Card      | #181008         | #2A1C0C         | #1E1009       | #2C2210         |
| Elevated  | #221608         | #362410         | #2C1A0C       | #392C14         |
| Hue dir.  | Red-brown       | Orange-brown    | Dark red-brown| Yellow-brown    |
| Accent    | Ochre #C4903A   | Warm ochre #D49832 | Bronze #B87A38 | Sandy gold #C49028 |
| Secondary | Terracotta      | Terracotta      | Copper        | Honey #B87818   |

Option H is the only one that leans yellow-brown — the direction of real
desert sand. Every other option leans orange (E) or red (D, G). The
surfaces in H have noticeably more yellow pigment, which reads sandy
rather than chocolatey or caramel. The accent Sandy Gold #C49028 and
secondary Honey #B87818 both stay inside the yellow-brown family.

---

## WHY THIS PALETTE

1. Yellow-brown is the colour of actual sand. Desert sand sits around
   hsl(38, 35%, 60%) — warm, yellow-leaning brown. This palette takes that
   hue direction and darkens it for a premium dark-mode game UI. The result
   is the closest any of these options gets to the literal colour of sand.

2. Sandy Gold reads differently from Gold or Bronze. Standard gold (#C9A84C)
   is used by Kammelna and most competitors. Bronze (#B87A38) leans red.
   Sandy Gold (#C49028) leans yellow — it harmonises specifically with
   yellow-brown surfaces in a way gold and bronze do not.

3. Honey as secondary is unique across all options. Terracotta (D/E),
   copper (G), and now honey (H) each represent a different warm secondary.
   Honey (#B87818) is amber-yellow rather than orange-brown or red-brown,
   keeping the whole palette inside the yellow-warm family.

4. The lightest dark-mode brown option. H's canvas (#1E1808) and card
   (#2C2210) are the most visible warm surfaces across D, E, G, H — still
   premium dark game UI, but with the most visible warmth of the four.

---

## 1. COLOUR TOKENS — CREATE THIS FILE FIRST

Create theme/balootColors.js (or update your existing theme file).
Every component must reference these tokens. No hardcoded hex values elsewhere.

```js
// theme/balootColors.js

export const BalootColors = {

  // Backgrounds — 4 yellow-brown sandy levels
  bgCanvas:      '#1E1808',   // Page root — deep sandy base, yellow-brown cast
  bgCard:        '#2C2210',   // Profile card, main content surfaces
  bgElevated:    '#392C14',   // Play row, nav bar, button containers
  bgPanel:       '#473618',   // Drawers, dropdowns, modal sheets

  // Sandy Gold — primary brand accent
  sandGold:      '#C49028',   // Game title, medal count, rank badge bg, trophy
  sandGoldLight: '#DFAE45',   // Active nav, rank pill text, highlights
  sandGoldDark:  '#886018',   // Progress fill base / gradient depth
  sandBorder:    'rgba(196, 144, 40, 0.26)',
  sandBorderStrong: 'rgba(196, 144, 40, 0.50)',

  // Honey — secondary accent
  honey:         '#B87818',   // Menu icon, sparkle pill icon, crown badge
  honeyLight:    '#D09030',   // Lighter honey highlight
  honeyDark:     '#7A4E10',   // Deep honey for ring gradient
  honeyBg:       'rgba(184, 120, 24, 0.12)',
  honeyBorder:   'rgba(184, 120, 24, 0.26)',

  // Sienna — Play button ONLY, do not reuse
  sienna:        '#7A4808',   // Play button background
  siennaHover:   '#964E10',   // Play button pressed / hover
  siennaBorder:  'rgba(196, 120, 40, 0.28)',
  siennaText:    '#FFECCC',   // Text on the play button

  // Crimson — hearts / lives only
  crimson:       '#8B2020',
  crimsonBg:     '#200808',
  crimsonBorder: 'rgba(139, 32, 32, 0.35)',

  // Typography
  textPrimary:   '#F8EDD8',   // Most sandy/beige cream of all options
  textSecondary: '#C8A868',   // Warm beige-grey
  textMuted:     '#806840',   // Sandy muted — decorative / inactive only

  // Structural borders
  borderDefault: 'rgba(255, 255, 255, 0.08)',
  borderStrong:  'rgba(255, 255, 255, 0.13)',
};
```

---

## 2. DIAMOND BACKGROUND PATTERN

Root background:    BalootColors.bgCanvas  (#1E1808)

Diamond overlay:
  Pattern colour:   #C49028  (sandGold)
  Opacity:          0.04
  IMPORTANT: keep at exactly 0.04. H has the lightest surfaces of all
  four brown options — the diamond pattern is more visible here than in
  D, E, or G. 0.05 will look heavy. 0.04 gives warmth without mudding.
  Style: repeating-linear-gradient at 45 and -45 degrees,
         1px lines, 22px spacing

Radial vignettes:
  Top-left:     radial gradient from bgCard (#2C2210) at 28% opacity to transparent
  Bottom-right: same

---

## 3. ELEMENT-BY-ELEMENT CHANGES

### 3a. Top navigation bar

Container:              bgCanvas (#1E1808)

LEFT button (Notifications):
  background:           bgElevated (#392C14)
  border:               1px borderDefault
  borderRadius:         12
  icon:                 ti-bell
  iconColour:           textSecondary (#C8A868)
  accessibilityLabel:   "Notifications"
  REMOVE label text "Alerts"

RIGHT button (Menu):
  background:           bgElevated (#392C14)
  border:               1px borderDefault
  borderRadius:         12
  icon:                 ti-menu-2
  iconColour:           honey (#B87818)
  accessibilityLabel:   "Main menu"
  REMOVE label text "More"

CENTRE title "Baloot":
  colour:               sandGold (#C49028)
  fontWeight:           700
  fontSize:             20
  letterSpacing:        1

Suit icons:
  spade / club:         textMuted (#806840)
  heart / diamond:      crimson (#8B2020)
  fontSize:             11

---

### 3b. Profile card

Container:
  background:           bgCard (#2C2210)
  border:               1px sandBorder  rgba(196,144,40,0.26)
  borderRadius:         20
  margin:               6px 14px 12px
  padding:              14px

Top shimmer line:
  position: absolute, top:0, left:0, right:0, height:1px
  background: linear-gradient(90deg, transparent, rgba(196,144,40,0.22), transparent)

STAR pill:
  background:           rgba(196,144,40,0.12)
  border:               1px sandBorder
  icon:                 ti-star
  iconColour:           sandGoldLight (#DFAE45)
  valueColour:          textPrimary (#F8EDD8)
  accessibilityLabel:   "0 gold stars"

SPARKLES pill:
  background:           honeyBg  rgba(184,120,24,0.12)
  border:               1px honeyBorder
  icon:                 ti-sparkles
  iconColour:           honey (#B87818)
  valueColour:          textPrimary (#F8EDD8)
  accessibilityLabel:   "0 special points"

HEART pill:
  background:           crimsonBg (#200808)
  border:               1px crimsonBorder
  icon:                 ti-heart
  iconColour:           crimson (#8B2020)
  valueColour:          textPrimary (#F8EDD8)
  accessibilityLabel:   "0 hearts"

All pills:
  borderRadius:         20
  padding:              5px 10px
  gap:                  4px

Avatar ring:
  width/height:         72px
  borderRadius:         50%
  background:           conic-gradient(
                          #886018 0%,
                          #4A3408 40%,
                          #C49028 70%,
                          #886018 100%
                        )

Avatar inner:
  width/height:         62px
  background:           bgCard (#2C2210)
  borderRadius:         50%
  icon:                 ti-user
  iconColour:           textSecondary (#C8A868)
  iconSize:             28

Rank badge (below avatar):
  position:             absolute, bottom:-2, centred
  background:           sandGold (#C49028)
  textColour:           bgCanvas (#1E1808)
  text:                 "Expert"
  fontSize:             9, fontWeight 700
  padding:              1px 6px, borderRadius 6

Username: textPrimary (#F8EDD8), fontSize 17, fontWeight 700
Card icon: ti-playing-card, textMuted (#806840), fontSize 22

LEFT badge:
  width/height:         38px
  background:           rgba(196,144,40,0.12)
  border:               1px sandBorder
  borderRadius:         10
  icon:                 ti-shield-star
  iconColour:           sandGold (#C49028)
  accessibilityLabel:   "Rank badge"

RIGHT badge:
  width/height:         38px
  background:           honeyBg
  border:               1px honeyBorder
  borderRadius:         10
  icon:                 ti-crown
  iconColour:           honey (#B87818)
  accessibilityLabel:   "VIP badge"

Rank pill "Expert":
  background:           rgba(196,144,40,0.13)
  border:               1px sandBorder
  text:                 sandGoldLight (#DFAE45)
  fontSize:             10, fontWeight 700, sentence case

XP text: "1,820 of 2,800 to Legend", textMuted (#806840), fontSize 11

Progress bar track:
  background:           rgba(255,255,255,0.07)
  height:               6, borderRadius 3

Progress bar fill (65%):
  background:           linear-gradient(90deg, #886018, #C49028, #DFAE45)
  borderRadius:         3

ARIA:
  role="progressbar"
  aria-valuenow={1820}
  aria-valuemin={0}
  aria-valuemax={2800}
  aria-label="1,820 of 2,800 medals to Legend rank"

---

### 3c. Play / action row

Container:
  background:           bgElevated (#392C14)
  border:               1px borderDefault
  borderRadius:         18
  margin:               0 14px 10px
  padding:              4px

LEFT button (Leaderboard):
  width: 48px, height: 56px
  background:           rgba(255,255,255,0.05)
  border:               1px borderDefault
  borderRadius:         14
  icon:                 ti-list-numbers
  iconColour:           textSecondary (#C8A868)
  accessibilityLabel:   "Leaderboard"

PLAY button:
  flex: 1, height: 56px
  background:           sienna (#7A4808)
  border:               1px siennaBorder  rgba(196,120,40,0.28)
  borderRadius:         14
  text:                 "Play"
  textColour:           siennaText (#FFECCC)
  fontSize:             18, fontWeight 700, fontFamily Cairo
  Inner top highlight:  position absolute, top:0, left:10%, right:10%, height:1px
                        background rgba(255,220,160,0.18)

RIGHT button (Mode):
  width: 56px, height: 56px
  background:           rgba(255,255,255,0.05)
  border:               1px borderDefault
  borderRadius:         14
  icon:                 ti-chevron-down
  iconColour:           textSecondary (#C8A868)
  label:                "Game type"  (NOT "MODE")
  labelColour:          textMuted (#806840)
  labelSize:            9, labelWeight 500

---

### 3d. Divider label

Text:           "· · · Live now · · ·"
colour:         rgba(196, 144, 40, 0.35)
fontSize:       10, letterSpacing 3, uppercase, centered
marginBottom:   8

---

### 3e. Tournament banner

Container:
  margin:         0 14px 14px
  background:     linear-gradient(135deg, #151108 0%, #1E1A0A 40%, #181408 100%)
  border:         1px sandBorder  rgba(196,144,40,0.20)
  borderRadius:   16
  padding:        12px 14px 12px 18px
  overflow:       hidden

Left-edge stripe:
  position: absolute, top:0, left:0, bottom:0, width:3px
  background: sandGoldDark (#886018)
  borderRadius: 0  (no independent radius on this element)

Trophy icon:    ti-trophy, sandGold (#C49028), size 28, marginLeft 6
Title:          "Kammelna Cup", sandGoldLight (#DFAE45), fontSize 15, fontWeight 700
Subtitle:       "Live now · Enter the cup", rgba(184,120,24,0.65), fontSize 11
Right icon:     ti-playing-card, textMuted (#806840), size 22, opacity 0.6

accessibilityRole: "button" (if tappable)
accessibilityLabel: "Kammelna Cup — Live now. Tap to enter."

---

### 3f. Bottom navigation bar

Container:
  background:     bgCanvas (#1E1808)
  borderTop:      1px borderStrong  rgba(255,255,255,0.13)
  paddingBottom:  12  (safe area)
  paddingTop:     8

INACTIVE items:   textMuted (#806840), fontSize 10, fontWeight 500

ACTIVE item (Home):
  icon / label:   sandGoldLight (#DFAE45), fontSize 10, fontWeight 600
  Active pill:    rgba(196,144,40,0.14) background, borderRadius 12, padding 6px 14px

Icons:
  Store:          ti-shopping-bag
  Community:      ti-users-group
  Home:           ti-home
  Tournaments:    ti-trophy
  Chat:           ti-message-circle

All: strokeWidth 1.5, no fill
Each: accessibilityRole="tab"
Active: accessibilityState={{ selected: true }}

---

## 4. BUGS TO FIX IN PROMPT 3

Bug 1 — Duplicate hearts counter:
  Find every hearts/lives render. Delete all duplicates.
  Bind single remaining to one state variable. Apply crimsonBg / crimson styling.

Bug 2 — Currency bar invisible:
  Add: background bgElevated (#392C14), height 36, colour textPrimary (#F8EDD8),
  padding 0 12px. Remove any opacity:0 or display:none causing empty return.

Bug 3 — VIP Store in Game Modes panel:
  Remove VIP Store from modes list. Move to Store tab. Modes = game variants only.

Bug 4 — Game Modes panel bright blue:
  Replace background with bgElevated (#392C14). Border: 1px borderDefault.

---

## 5. ICON REFERENCE TABLE

Install: npm install @tabler/icons-react-native (RN) or @tabler/icons-react (web)
All icons: strokeWidth={1.5}, no fill.

| Location             | Replace with       | Token            | Hex     |
|----------------------|--------------------|------------------|---------|
| Notifications button | ti-bell            | textSecondary    | #C8A868 |
| Menu button          | ti-menu-2          | honey            | #B87818 |
| Star stat pill       | ti-star            | sandGoldLight    | #DFAE45 |
| Sparkles stat pill   | ti-sparkles        | honey            | #B87818 |
| Heart stat pill      | ti-heart           | crimson          | #8B2020 |
| Left rank badge      | ti-shield-star     | sandGold         | #C49028 |
| Right VIP badge      | ti-crown           | honey            | #B87818 |
| Medal count          | ti-medal           | sandGold         | #C49028 |
| Leaderboard button   | ti-list-numbers    | textSecondary    | #C8A868 |
| Mode chevron         | ti-chevron-down    | textSecondary    | #C8A868 |
| Tournament trophy    | ti-trophy          | sandGold         | #C49028 |
| Card visual          | ti-playing-card    | textMuted        | #806840 |
| Store nav            | ti-shopping-bag    | textMuted/active | —       |
| Community nav        | ti-users-group     | textMuted        | #806840 |
| Home nav             | ti-home            | textMuted/active | —       |
| Tournaments nav      | ti-trophy          | textMuted        | #806840 |
| Chat nav             | ti-message-circle  | textMuted        | #806840 |
| Chest / reward       | ti-diamond         | sandGold         | #C49028 |

---

## 6. ACCESSIBILITY

Notifications:     accessibilityLabel="Notifications", accessibilityRole="button"
Menu button:       accessibilityLabel="Main menu", accessibilityRole="button"
Star pill:         accessibilityLabel="0 gold stars"
Sparkles pill:     accessibilityLabel="0 special points"
Heart pill:        accessibilityLabel="0 hearts remaining"
Avatar:            accessibilityLabel="Player avatar — Expert rank"
Left badge:        accessibilityLabel="Rank badge"
Right badge:       accessibilityLabel="VIP badge"
Progress bar:      role="progressbar", aria-valuenow={1820}, aria-valuemin={0},
                   aria-valuemax={2800},
                   aria-label="1,820 of 2,800 medals to Legend rank"
Leaderboard:       accessibilityLabel="Leaderboard"
Play button:       accessibilityLabel="Play Baloot"
Mode button:       accessibilityLabel="Select game type"
Tournament:        accessibilityLabel="Kammelna Cup — Live now. Tap to enter."
                   accessibilityRole="button"
Nav items:         accessibilityRole="tab", accessibilityState={{ selected: isActive }}
                   Labels: "Store", "Community", "Home", "Tournaments", "Chat"

Contrast check (WCAG AA = 4.5:1 minimum):
  textPrimary #F8EDD8 on bgCard #2C2210:          ~11.2:1  PASS
  sandGold #C49028 on bgCard #2C2210:              ~5.2:1  PASS
  sandGoldLight #DFAE45 on bgCard #2C2210:         ~7.8:1  PASS
  siennaText #FFECCC on sienna #7A4808:           ~10.4:1  PASS
  bgCanvas #1E1808 on sandGold #C49028 badge:      ~5.2:1  PASS
  honey #B87818 on bgCard #2C2210:                 ~4.5:1  PASS (tight — icons only)
  textMuted #806840 on bgCanvas #1E1808:           ~3.2:1  WARNING decorative only

---

## 7. TYPOGRAPHY

Font family:    Cairo
                Fallback: -apple-system, BlinkMacSystemFont, sans-serif

Element                   Size    Weight    Token
Game title "Baloot"       20px    700       sandGold
Username                  17px    700       textPrimary
Rank badge text           9px     700       bgCanvas (dark on sandy gold)
Rank pill "Expert"        10px    700       sandGoldLight
Star / sparkles values    12px    600       textPrimary
Heart value               12px    600       textPrimary
Medal count "7"           13px    700       sandGold
XP sub-text               11px    400       textMuted
Play button               18px    700       siennaText
Mode label "Game type"    9px     500       textMuted
Divider "Live now"        10px    400       rgba(196,144,40,0.35)
Tournament title          15px    700       sandGoldLight
Tournament subtitle       11px    400       rgba(184,120,24,0.65)
Nav inactive              10px    500       textMuted
Nav active                10px    600       sandGoldLight

CASING FIXES:
  "EXPERT"  to  "Expert"
  "MODE"    to  "Game type"

---

## 8. SANDY GOLD STRIPE — BANNER LEFT EDGE

The 3px left-edge stripe on the tournament banner must render without
independent border-radius. Uses sandGoldDark (#886018) not sandGold.

React Native:
  <View style={{
    position: 'absolute',
    top: 0, left: 0, bottom: 0,
    width: 3,
    backgroundColor: '#886018',
    borderTopLeftRadius: 16,
    borderBottomLeftRadius: 16,
  }} />

Web CSS:
  .tournament-banner {
    border-left: 3px solid #886018;
    border-radius: 16px;
  }

Do not use sandGold or honey for this stripe. sandGoldDark only.
Do not add this stripe to any other component — banner only.

---

## 9. VISUAL TEST FOR OPTION H

After Prompt 6, check the card surface #2C2210 on device:
  CORRECT: sandy yellow-brown, like sun-baked stone
  WRONG (orange): bgCard token not applied, check theme/balootColors.js
  WRONG (chocolate): you are looking at Option G, check the file context

The sandGold #C49028 accent should look different from:
  Kammelna gold:   more yellow, less saturated than #C9A84C
  Option G bronze: more yellow, less red than #B87A38
  Option E ochre:  more brown, less yellow than #D49832

---

## 10. CURSOR PROMPTS — PASTE ONE AT A TIME

Pin baloot-homescreen-option-h-sandstone.md as context in Cursor.
Complete and test each prompt before pasting the next.

PROMPT 1 — Colour token file
  Using the spec in baloot-homescreen-option-h-sandstone.md, create the
  colour token file at theme/balootColors.js exactly as written in Section 1.
  Include all tokens: four sandy-brown background levels, sandy gold,
  honey, sienna, crimson, typography, and borders.
  Token file only — do not touch any component files yet.

PROMPT 2 — Background and screen root
  Using baloot-homescreen-option-h-sandstone.md Section 2:
  Set screen root background to BalootColors.bgCanvas (#1E1808).
  Diamond overlay: colour #C49028, opacity exactly 0.04 (not higher).
  Add two radial vignettes using bgCard (#2C2210) at 28% opacity.
  Background only — no other components.

PROMPT 3 — Fix all 4 bugs before any styling
  Using baloot-homescreen-option-h-sandstone.md Section 4, fix all four bugs:
  1. Duplicate hearts counter — delete duplicate, bind to single state variable.
  2. Invisible currency bar — add background (#392C14), height (36),
     padding (0 12px), colour (#F8EDD8). Remove opacity:0 or display:none.
  3. VIP Store in Game Modes — remove from modes list, move to Store tab.
  4. Bright blue Game Modes panel — replace with bgElevated (#392C14),
     borderDefault border.
  Bug fixes only — no visual restyling.

PROMPT 4 — Install icons and replace all emoji
  Using baloot-homescreen-option-h-sandstone.md Section 5:
  1. Install @tabler/icons-react-native (or @tabler/icons-react for web).
  2. Replace every emoji and inconsistent icon with the Tabler icon in the table.
     Set strokeWidth={1.5} on every icon.
  3. Apply the exact hex colour from the table to each icon.
  4. Add the accessibilityLabel from Section 6 to every icon-only button.
  Icons and labels only — no backgrounds or layout changes.

PROMPT 5 — Top navigation bar
  Using baloot-homescreen-option-h-sandstone.md Section 3a:
  Notifications button: bgElevated (#392C14) background, borderDefault border,
  ti-bell in textSecondary (#C8A868). Remove "Alerts" label.
  Menu button: bgElevated background, ti-menu-2 in honey (#B87818).
  Remove "More" label.
  Title "Baloot": sandGold (#C49028), fontWeight 700, fontSize 20.
  Suits: spade/club in textMuted (#806840), heart/diamond in crimson (#8B2020).
  Top bar only.

PROMPT 6 — Profile card
  Using baloot-homescreen-option-h-sandstone.md Section 3b, fully restyle
  the profile card:
  Container: bgCard (#2C2210) background, sandBorder border, borderRadius 20,
  shimmer line rgba(196,144,40,0.22).
  Star pill: rgba(196,144,40,0.12) background, sandBorder, ti-star in sandGoldLight.
  Sparkles pill: honeyBg background, honeyBorder, ti-sparkles in honey (#B87818).
  Heart pill: crimsonBg background, crimsonBorder, ti-heart in crimson (#8B2020).
  Avatar ring: conic-gradient #886018 / #4A3408 / #C49028 (Section 3b).
  Avatar inner: bgCard background, ti-user in textSecondary.
  Rank badge: sandGold background, bgCanvas text, "Expert".
  Username: textPrimary (#F8EDD8), fontSize 17, fontWeight 700.
  Card icon: ti-playing-card in textMuted.
  Left badge: rgba(196,144,40,0.12) background, sandBorder, ti-shield-star in sandGold.
  Right badge: honeyBg background, honeyBorder, ti-crown in honey.
  Rank pill: rgba(196,144,40,0.13) background, sandBorder, sandGoldLight text, "Expert".
  XP text: "1,820 of 2,800 to Legend", textMuted.
  Progress bar: rgba(255,255,255,0.07) track, sandy gold gradient fill, ARIA attributes.
  Profile card only.

PROMPT 7 — Play row and mode selector
  Using baloot-homescreen-option-h-sandstone.md Section 3c:
  Container: bgElevated (#392C14) background, borderDefault border, borderRadius 18.
  Leaderboard button: rgba(255,255,255,0.05) background, borderDefault,
  ti-list-numbers in textSecondary (#C8A868).
  Play button: sienna (#7A4808) background, siennaBorder border,
  siennaText (#FFECCC) colour, inner top highlight rgba(255,220,160,0.18).
  Mode button: rgba(255,255,255,0.05) background, ti-chevron-down in textSecondary,
  label changed to "Game type" in textMuted (#806840).

PROMPT 8 — Divider, banner, nav bar
  Using baloot-homescreen-option-h-sandstone.md Sections 3d, 3e, 3f and Section 8:

  Divider: "· · · Live now · · ·", rgba(196,144,40,0.35), fontSize 10,
  letterSpacing 3, uppercase.

  Tournament banner:
  Dark warm gradient background (Section 3e).
  sandBorder rgba(196,144,40,0.20).
  Sandy gold dark left-edge stripe — 3px, #886018, no independent border-radius
  (see Section 8 for exact RN and web implementation code).
  ti-trophy in sandGold (#C49028) with marginLeft 6.
  Title "Kammelna Cup" in sandGoldLight (#DFAE45).
  Subtitle "Live now · Enter the cup" in rgba(184,120,24,0.65).
  accessibilityRole and accessibilityLabel from Section 6.

  Navigation bar:
  bgCanvas (#1E1808) background, borderStrong top border.
  Inactive: textMuted (#806840) icons and labels.
  Active Home: sandGoldLight (#DFAE45) icon and label,
  rgba(196,144,40,0.14) active pill.
  Icon replacements from Section 5.
  accessibilityRole and accessibilityState on each item.

PROMPT 9 — Typography and accessibility final pass
  Using baloot-homescreen-option-h-sandstone.md Sections 6 and 7:
  1. Check every text element against the typography table. Apply correct
     fontSize, fontWeight, and colour token to each.
  2. Fix casing — "EXPERT" to "Expert", "MODE" to "Game type".
  3. Add every accessibilityLabel, accessibilityRole, and accessibilityState
     from Section 6 to the matching element.
  4. Confirm fontFamily is Cairo with correct fallback.
  Typography and accessibility only — no layout, background, or logic changes.

---

End of spec. Run Prompts 1 through 9 in order.

Checkpoints:
  After Prompt 3 — hearts shows one value, currency bar visible, modes panel sandy
  After Prompt 6 — use the visual test in Section 9 to confirm sandy yellow-brown
  After Prompt 8 — verify the 3px sandGoldDark stripe renders without radius
  After Prompt 9 — screenshot and compare against D, E, G for the full brown range

The defining test: does the card surface read sandy (H applied correctly)
or orange (bgCard token missing)? Check theme/balootColors.js first if wrong.
