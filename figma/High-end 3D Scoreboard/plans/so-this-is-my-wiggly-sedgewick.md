# Context

The user has a card game app (Baloot / أربعة مربعة style) with a dark luxury leather-textured home screen (image-1). They currently have a plain dark scoreboard (image-2) and want it completely rebuilt as a high-end 3D-style 2026 scoreboard that inherits the gold/brown luxury aesthetic of the home screen.

## What the scoreboard shows (from image-2)
- Title: "Scoreboard"
- Game info card: Game type (Sun), Buyer (Our team), Purchase result (Won – made threshold)
- Score table: Them vs Us columns
  - Tricks: 24 vs 86
  - Ground: — vs 10
  - Projects: — vs —
  - Trick pts (cards): 24 vs 96
  - Result: 5 vs 21
- Footer: Match: Us 0, Them 0

## Visual language to match (from image-1)
- Dark brown/near-black background with diamond quilted leather texture
- Rich gold (#c9a84c / #d4a017) as primary accent — headings, borders, glows
- Raised metallic/embossed panel aesthetic
- Subtle amber glow effects
- Luxury card-game atmosphere

---

## Implementation Plan

### 1. Replace `src/App.tsx` entirely with the Scoreboard component

The existing App is a pointer-tracking dot grid demo — the user wants the scoreboard to be the full page.

### 2. Add quilted leather background to the page

CSS: repeating diamond/rhombus pattern via `background-image` with radial-gradient or a custom SVG data-URI, dark brown (`#1a1208`) base. Subtle ambient amber vibe via a centered radial glow.

### 3. Build the scoreboard card with 3D depth

- Rounded card (`border-radius: 20px`)
- Multi-layer box-shadow: outer dark shadow + inner amber glow (`0 0 40px rgba(201,168,76,0.25)`)
- Background: `linear-gradient(145deg, #2a1f0e, #1a1208)` 
- Top border: 1px solid gold gradient
- Optional: subtle `perspective` + `rotateX(2deg)` tilt for 3D feel
- Glass-like inner panel with `backdrop-filter: blur` tinted surfaces

### 4. Header section — "Scoreboard" title
- Large gold text, serif/display weight
- Letterpress effect: `text-shadow: 0 1px 0 #7a5c00, 0 -1px 0 #fff3`
- Thin gold divider line below

### 5. Game info card (Game / Buyer / Result)
- Slightly raised inner card with dark matte background
- Gold left-border accent strip
- "Won (made threshold)" in bright green with glow: `text-shadow: 0 0 12px #00ff88`

### 6. Score table — the centerpiece
- Column headers "Them" / "Us" with colored glows (red for Them, green for Us)
- Each row: alternating slight background tint
- Numbers rendered large and bold with colored glow matching their team
- "Result" row: highlighted with a gold border box, larger font, extra glow — this is the hero row
- Separator lines: thin gold `rgba(201,168,76,0.3)` hairlines

### 7. Footer "Match" bar
- Pill/badge shape at bottom of card
- Muted gold text on dark surface

### 8. Animations (subtle, 2026-feel)
- `@keyframes shimmer` on the card border (gold shimmer sweep)
- Number count-up animation on mount using `useState` + `useEffect` + `requestAnimationFrame`
- Subtle `fadeInUp` on card mount

### 9. Fonts
- Use `font-family: 'Georgia', serif` for title (reliable fallback, luxury feel) OR resolve a font via `figma fonts resolve`
- Numbers: monospace or tabular-nums for alignment

---

## Files to modify
- `src/App.tsx` — full replacement with new Scoreboard component
- `src/index.css` — add `@import 'tailwindcss';` stays; add CSS custom props for gold palette and any keyframe animations

## Verification
- Open preview URL in browser — scoreboard should fill the screen
- Verify count-up animations fire on load
- Check gold glow effects render on card and numbers
- Confirm all score data from image-2 is present (Tricks, Ground, Projects, Trick pts, Result, Match)
- Check mobile layout looks good at ~390px width
