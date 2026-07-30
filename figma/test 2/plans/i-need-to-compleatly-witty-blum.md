# Plan: Game Mode Panel → Half-Screen Bottom Drawer (CR Style)

## Context
Currently `GameModePanel` replaces the full screen. CR's game mode picker is a **half-screen bottom drawer** that slides up over the existing home screen — the top half (arena, top bar) stays visible behind a dark backdrop, and tapping the backdrop closes the drawer. The down-arrow pill sits at the TOP EDGE of the drawer, not at the top of the screen.

## Where the code lives (for the user)
| What | File |
|------|------|
| PLAY button + left mode box + right mode button | `src/app/components/BattleRow.tsx` |
| Game mode selection panel/drawer | `src/app/components/GameModePanel.tsx` |
| State glue (selectedMode, showModePanel) | `src/app/components/HomeScreen.tsx` |

## Changes — only `GameModePanel.tsx`

### Layout structure
```
<div  full-screen absolute z-30, onClick=close>          ← dark backdrop (top ~45%)
  <div  absolute bottom-0 h-[58%] rounded-t-3xl>         ← the drawer itself
    <e.stopPropagation on the drawer div>

    <!-- Down-arrow pill at very top of drawer -->
    <div flex justify-center pt-2.5 pb-1>
      <button blue-pill ▼>

    <!-- "Game Modes" title -->
    <h2 bold white centered px-4 pb-2>Game Modes</h2>

    <!-- Horizontal divider line -->
    <hr rgba(255,255,255,0.15)>

    <!-- Scrollable ticket list (compact cards) -->
    <div overflow-y-auto flex-1 px-4 py-2 space-y-2>
      {sections → SectionLabel + TicketCards}

    <!-- PLAY NOW confirm button pinned at bottom -->
    <div px-4 pb-4 pt-2 flex-shrink-0>
      <button gold PLAY NOW full-width>
```

### Backdrop behaviour
- The outer `<div onClick={onClose}>` covers full screen with `rgba(0,0,0,0.55)`
- The inner drawer `<div onClick={e => e.stopPropagation()}>` prevents tap-through
- Tapping anywhere above the drawer (the dark area) closes it — exactly like CR

### Drawer sizing
- `height: 58%` of the container — shows roughly half the home screen above
- `border-radius: 24px 24px 0 0` on top corners
- Background: same `linear-gradient(180deg, #1560B8 → #1050A0)`
- Top-edge shine line `rgba(255,255,255,0.2)` 1px

### Animation
Keep existing `cr-slide-up` (translateY 100% → 0) — already correct

### Ticket cards — make compact
- Reduce `minHeight` from 72px → 60px
- Font sizes slightly smaller to fit more cards in half-screen
- Keep ticket left/right box + section labels design exactly as-is

### PLAY NOW button (new addition)
- Pinned at bottom of drawer, full width, gold gradient
- Same style as before: `linear-gradient(135deg, #F5C842, #E8920E)`
- `onClick={() => onConfirm(selectedModeId)}`
- Always visible, not inside the scroll area

---

# Plan: Battle Row — Clash Royale Box Layout

## Context (latest change)
User wants the battle row redesigned to exactly match the Clash Royale layout from the screenshot:
- **Left**: A square dark-blue box (same size as CR's card deck box) — shows selected game mode
- **Center**: Wide gold "PLAY" button dominant element (like CR's "Battle" button) — pill shape, bright gold gradient, 3D raised look
- **Right**: A smaller square dark-blue box (like CR's trophy box, but empty placeholder for now) — game mode picker

No icons/trophy/cards yet — just the boxes and button shapes with correct proportions and 3D bevel effect matching CR.

### Clash Royale button anatomy (from screenshot)
- Three elements sit on a dark teal/navy strip with rounded corners
- Left square box: ~64×64px, rounded ~10px, dark navy bg, 3D raised (lighter top border, darker bottom border/shadow)
- Center Battle button: wide pill (flex-1), ~56px tall, bright yellow-gold gradient top to bottom, 3D raised, bold text
- Right box: slightly smaller (~52×52px), same dark navy style, optically raised slightly above center button baseline
- Gap between elements: ~6–8px

### 3D bevel technique
Gold button:
```
background: linear-gradient(180deg, #FFE566 0%, #F5A820 60%, #D47808 100%)
border-top:    2px solid rgba(255,255,255,0.55)   ← shine
border-bottom: 3px solid rgba(140,70,0,0.85)      ← shadow base
box-shadow: 0 4px 0 rgba(100,50,0,0.6)            ← depth
```
Dark boxes:
```
background: linear-gradient(180deg, #1C4080 0%, #0F2456 100%)
border-top:    2px solid rgba(80,150,230,0.55)
border-bottom: 3px solid rgba(4,12,36,0.9)
box-shadow: 0 4px 0 rgba(4,12,36,0.7)
```

### File to change
Only `src/app/components/BattleRow.tsx` — full rewrite of the component layout.

No other files need changes.

---

# Plan: Baloot Home Screen — Royal Blue VIP Theme + Interactive Play Button

## Context
The user wants a premium Baloot game home screen inspired by Clash Royale's aesthetic:
- **Deep royal blue** background with diamond tile texture (not cartoonish, not desert — VIP/premium feel)
- **Gold accents** for primary actions
- **Interactive PLAY button**: pressing it opens a game mode selection panel (bottom sheet)
- **Left of PLAY button**: live display of the currently selected game mode
- **Right of PLAY button**: dropdown to quickly switch game modes without launching

---

## Color Palette (Clash Royale inspired, premium not cartoonish)
```
Background gradient: #0A1F4E → #0D2B6B → #0F2559  (deep royal navy)
Diamond tile overlay: rgba(74,144,217,0.07) at 24px grid
Surface cards: rgba(15, 35, 85, 0.85) + border rgba(74,144,217,0.25)
Gold primary: linear-gradient(135deg, #F5C842, #E8920E)
Gold text: #F5A623
Blue accent: #4A90D9
Muted text: #8DB4E8
White text: #FFFFFF
Glow gold: box-shadow 0 0 20px rgba(245,166,35,0.4)
Glow blue: box-shadow 0 0 15px rgba(74,144,217,0.3)
```

---

## Key UX: The Battle Row

```
┌───────────────┬──────────────────┬───────────────┐
│  SELECTED     │                  │               │
│  MODE DISPLAY │   ♠  PLAY        │  Change  ∨    │
│  🃏 Normal    │                  │  Mode         │
└───────────────┴──────────────────┴───────────────┘
```

- **Left box**: Shows active game mode icon + name. Updates when user picks a mode.
- **Center**: Gold PLAY button with spade icon + pulsing glow. Pressing opens `GameModePanel`.
- **Right box**: "Change Mode" + chevron. Pressing also opens `GameModePanel`.

### GameModePanel (Bottom Sheet)
Slides up from bottom when PLAY or Change Mode is pressed:
- Semi-transparent dark backdrop (tapping outside closes)
- Bottom sheet with list of 6 game modes:
  - Normal Session 🃏 — "4 players • Classic Baloot"
  - Friendly Game 🤝 — "Play with friends"
  - Voice Session 🎙 — "With voice chat"
  - Create Session ➕ — "Custom settings"
  - Browse Sessions 📋 — "Join existing games"
  - Tournament 🏆 — "Compete for prizes"
- Currently selected mode highlighted with gold border
- Large "PLAY NOW" gold button to confirm and launch
- Tapping a mode selects it without closing (user then taps PLAY NOW)

---

## Full Screen Layout

```
┌─────────────────────────────────────────┐
│ [Avatar|Name|Lv]   [Coins][Gems]  [☰]  │ ← TopBar
│ [🏆Daily]   [⚡XP] [❤️Hearts] [EXPERT] │ ← Stats
│                                          │
│         ╔═══════════════════╗            │
│         ║  Arena / Cards    ║            │ ← ArenaDisplay
│         ╚═══════════════════╝            │
│                                          │
│ [🃏 Normal] [♠ PLAY ▶] [Mode ∨]         │ ← BattleRow
│                                          │
│ [🏆 Desert Cup Tournament — Join Now]   │ ← TournamentBanner
├─────────────────────────────────────────┤
│ [🛍][👥][🏠 Home*][💬][🏆]              │ ← BottomNav
└─────────────────────────────────────────┘
```

---

## Files to Create/Modify

### `src/app/App.tsx`
Render `<HomeScreen />`.

### `src/app/components/HomeScreen.tsx`
State: `selectedModeId`, `showModePanel`, `activeTab`.
Assembles all components. Passes state down.

### `src/app/components/TopBar.tsx`
- Left: Avatar circle (initials fallback) + player name + gold level badge
- Center-right: Coin pill (`🪙 1.1M`) + Gem pill (`💎 662`) with `+` prefix, gold/blue styling
- Right: Hamburger `≡` button (dark blue card)

### `src/app/components/PlayerStats.tsx`
Horizontal row: XP (`⚡20`), Hearts (`❤️344`), Stars (`⭐25,477`), Rank badge pill (`EXPERT` — amber glow).
Each stat in a small dark-blue chip.

### `src/app/components/ArenaDisplay.tsx`
Visual centerpiece — CSS card table:
- Oval "arena" table with green felt gradient
- 4 card positions (corners) with decorative face-down cards
- Spade suit large watermark in center
- Gold rim around table
- Subtle glow

### `src/app/components/BattleRow.tsx`
Three-column row:
- **SelectedModeBox** (left): dark blue card, shows `selectedMode.icon` + `selectedMode.name`, gold border when active
- **PlayButton** (center): gold gradient circle/pill, `♠ PLAY`, pulsing glow animation via `@keyframes`, pressing calls `onPlayPress`
- **ModeButton** (right): dark blue card with `∨` chevron + "Mode" label, pressing calls `onModeChange` (opens panel)

### `src/app/components/GameModePanel.tsx`
Full overlay:
```
<div backdrop> // semi-transparent, onClick closes
  <div sheet>  // slides up, bg dark blue
    <h2>Select Game Mode</h2>
    {gameModes.map(mode => (
      <ModeRow key={mode.id} selected={mode.id === selectedModeId} onClick={select} />
    ))}
    <button "PLAY NOW" gold> // calls onConfirm(selectedId)
  </div>
</div>
```
ModeRow: icon box (colored), name bold, description muted, checkmark if selected.

### `src/app/components/TournamentBanner.tsx`
Gold gradient horizontal card:
- Left: 🏆 trophy icon
- Center: "Baloot Cup" title + "Limited time event" subtitle  
- Right: "Join" button (dark blue)

### `src/app/components/BottomNav.tsx`
5 tabs: Store 🛍, Friends 👥, Home 🏠 (active = gold + underline), Chat 💬, Trophy 🏆.
Dark navy bar, active tab gets gold color.

### `src/app/components/AchievementBadge.tsx`
Absolute-positioned left side, below TopBar:
- Gold ring circle
- `🎁` or trophy icon
- "Daily" label

---

## Shared Game Mode Data (in HomeScreen.tsx)
```ts
export const gameModes = [
  { id: 'normal',      name: 'Normal Session',  icon: '🃏', desc: '4 players • Classic Baloot', color: '#4A90D9' },
  { id: 'friendly',    name: 'Friendly Game',   icon: '🤝', desc: 'Play with friends',          color: '#5BB96E' },
  { id: 'voice',       name: 'Voice Session',   icon: '🎙️', desc: 'With voice chat',            color: '#9B59B6' },
  { id: 'create',      name: 'Create Session',  icon: '➕', desc: 'Custom settings',            color: '#E8920E' },
  { id: 'sessions',    name: 'Browse Sessions', icon: '📋', desc: 'Join existing games',        color: '#E74C3C' },
  { id: 'tournament',  name: 'Tournament',      icon: '🏆', desc: 'Compete for prizes',         color: '#F5A623' },
];
```

---

## Animation Details
- PlayButton: CSS `@keyframes pulse-glow` — gold box-shadow fades in/out every 2s
- GameModePanel sheet: `transition: transform 300ms ease-out` slides up from bottom
- Backdrop: `transition: opacity 200ms` fades in

---

## Implementation Order
1. `src/app/components/HomeScreen.tsx` (state + layout shell)
2. `src/app/components/TopBar.tsx`
3. `src/app/components/PlayerStats.tsx`
4. `src/app/components/ArenaDisplay.tsx`
5. `src/app/components/BattleRow.tsx`
6. `src/app/components/GameModePanel.tsx`
7. `src/app/components/TournamentBanner.tsx`
8. `src/app/components/BottomNav.tsx`
9. `src/app/App.tsx` (wire up HomeScreen)

---

## Verification
- Deep royal blue diamond-tile background visible
- TopBar shows avatar, name, level, coins, gems, menu
- Stats row shows XP, hearts, stars, rank badge
- Arena card table visual in center
- Battle row: left box shows "Normal Session 🃏", center gold PLAY button, right "Mode ∨"
- Pressing PLAY or Mode → GameModePanel slides up from bottom
- Selecting a mode + pressing PLAY NOW → panel closes, left box updates to selected mode
- Tournament banner visible above bottom nav
- Bottom nav has 5 tabs, Home is gold/active
