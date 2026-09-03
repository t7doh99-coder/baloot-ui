# Context

Baloot card game challenge/violation UI. Build only the **Top Panel** and **Bottom Bar** — no body/card area. Must look better than the original screenshot. Three reference images provided.

---

## Reference Analysis

**image.png** (top bar from another game — layout target):
- Left area: Red text "Choose violation type" on dark panel (no heavy pill border — text is inline)
- Right: Raised "Violation Type" tab, separated from left by a subtle border
- Below: 4 pill-shaped silver/gray violation buttons in a row

**image-1.png** (bottom bar result state — after challenge submitted):
- Left: Bright green pill "Result: Correct" 
- Right: Dark pill "Violation Type: Cut" (shows what was selected)

**Original screenshot** (Baloot game):
- Top: Red border instruction pill (left) + gold "Violation Type" tab (right)
- Bottom: Cream "Close" button (left) + "Challenger: Player" + circular timer "53" (right)

---

## States

### Top Panel — Instruction pill (left side):
| State | Text | Style |
|---|---|---|
| 1 — no violation selected | "Choose the card that was cheated with" | Red text/border |
| 2 — violation selected | "Choose violation type" | Red text/border |
| 3 — ready | "Ready — Press Challenge" | Green text/border |

### Bottom Bar:
| State | Left | Right |
|---|---|---|
| Default | "Close" — beige pill | "Challenger: Player" pill + circular 60s timer |
| Ready | "Challenge" — gold glow pulse button | "Challenger: Player" pill + circular timer |
| Result (after challenge) | "Result: Correct" — bright green pill | "Violation Type: [selected]" — dark pill |

---

## Design Direction

**Palette:**
- Page bg: `#120904`
- Panel bg: `#1e1108`
- Panel surface: `#2a1a0a`
- Border: `#3d2410`
- Gold: `#d4a843`
- Gold bright: `#f0ca60`
- Red: `#e03535`
- Green: `#4ade80`
- Cream: `#f5e6c8`
- Muted text: `#a07850`

**Font:** Outfit (Google Font) — import via CSS2 in `src/index.css`

---

## Implementation Plan

### `src/index.css`
1. Add Google Fonts `@import` for Outfit at the very top (before all other imports)
2. Add CSS custom properties for palette
3. Set `font-family: 'Outfit', sans-serif` on body

### `src/App.tsx`
Full implementation, single file. Layout: `min-h-screen flex flex-col justify-between` on dark bg.

**State:**
```ts
const [cardSelected, setCardSelected] = useState(false)
const [selectedViolation, setSelectedViolation] = useState<string | null>(null)
const [timeLeft, setTimeLeft] = useState(60)
const [submitted, setSubmitted] = useState(false)
```

**Derived:**
```ts
const step = !cardSelected ? 1 : !selectedViolation ? 2 : 3
const isReady = cardSelected && selectedViolation !== null
```

**TopPanel:**
- Outer: dark panel with subtle bottom border, padding `px-4 py-3`
- Row 1 — two sections side by side:
  - Left (flex-1): instruction pill — rounded border, text + border color transitions red→green via CSS transition. Transitions to green in state 3.
  - Right: "Violation Type" label — raised dark box with gold text, slightly inset border-left separator
- Row 2 — violation buttons (`flex gap-2 flex-wrap mt-3`):
  - Violations: `["Cut", "Four in Double", "Didn't Over-Trump", "Didn't Trump"]`
  - Default: dark brown bg, muted border, cream text
  - Selected: gold border + gold text, subtle gold bg tint
  - Hover: scale-[1.02] transition
- Row 3 — small demo toggle chip: "Simulate card selected ✓" (tiny, bottom of panel) to let user test state 1→3. Clicking it toggles `cardSelected`.

**BottomBar:**
- Outer: dark panel with subtle top border, `px-4 py-3`, flex row space-between items-center
- Left — Action button:
  - `submitted` → green pill "Result: Correct" (static, no click)
  - `isReady && !submitted` → gold glow button "Challenge" with CSS keyframe glow-pulse, clicking sets `submitted=true`
  - default → beige/cream pill "Close"
  - Smooth: use key on button so text swap animates via opacity fade
- Right:
  - `submitted` → dark pill showing "Violation: [selectedViolation]"
  - default → flex row: "Challenger: Player" cream pill + SVG circular timer
    - Timer: 64×64 SVG, background circle stroke `#2a1a0a`, progress arc stroke gold
    - `stroke-dasharray = circumference`, `stroke-dashoffset = circumference * (1 - timeLeft/60)`
    - Center: bold gold number
    - useEffect setInterval every 1s, clears at 0

**Micro-details:**
- All color transitions: `transition-all duration-300`
- Challenge button: `animate-[glow_1.5s_ease-in-out_infinite]` via inline CSS keyframes in index.css
- Timer arc: `transition: stroke-dashoffset 0.9s linear` for smooth sweep
- Violation buttons: `active:scale-95` 

---

## Files to Modify

| File | Change |
|---|---|
| `src/index.css` | Outfit import, CSS vars, glow keyframe |
| `src/App.tsx` | Full TopPanel + BottomBar implementation |

---

## Verification

1. Top panel renders — check 3 pill states by toggling card sim + clicking violations
2. Violation buttons highlight gold on select
3. Bottom bar: Close → Challenge → Result transitions work
4. Circular timer counts down, arc sweeps gold
5. Layout: bars at top/bottom, empty dark space in middle
