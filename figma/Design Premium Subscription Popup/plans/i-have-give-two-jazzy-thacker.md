# Plan: Premium Subscription Popup

## Context
The user has a Baloot (Arabic card game) with a specific dark luxury aesthetic — deep chocolate-brown quilted backgrounds, rich gold/amber accents, warm cream text, and ornate golden borders. The reference popup from another app uses a flat cream/beige design that looks completely out of place. The goal is a brand-new, original premium subscription popup that lives in the game's visual world.

## Design Decisions

**Palette (from game screenshots):**
- Page ground: `#0D0804` (near-black brown)
- Panel surface: `#1C1207` with subtle diamond-pattern via CSS
- Gold primary: `#D4A520`
- Gold bright: `#F2C840`
- Gold dark border: `#5C3E0A`
- Cream text: `#F5E6C0`
- Muted text: `#9A7E55`

**Typography:** Cinzel (serif display, Latin/Roman regal feel for titles) + Cairo (Google Font, Arabic-friendly, legible for body). Both via Google Fonts CSS2 `@import` in `src/index.css`.

**Concept — "The Golden Chamber":**
- Full-screen dimmed overlay (dark semi-transparent)
- Centered modal with rounded corners, thick golden border, subtle inner glow
- Diamond/quilted CSS texture on panel background (repeating rhombus via `background-image: repeating-linear-gradient`)
- Top: golden crown SVG icon with radial glow halo
- Title: "VIP Premium" in Cinzel gold, subtitle in Arabic (Cairo)
- Benefits: 2-column icon grid, each item has a small golden icon + text; icons are inline SVG symbols (crown, shield, chat, trophy, card, star, no-ads, ticket)
- Pricing tiers: 3 cards side by side — Weekly / Monthly (highlighted, slightly larger, gold glow) / Annual
- CTA: large gradient gold button "Subscribe Now"
- Close X in top-right corner

## Files to Create/Modify

- **`src/App.tsx`** — Replace with the subscription popup as the sole rendered component (since user wants only this 1 screen)
- **`src/index.css`** — Add Google Fonts `@import` for Cinzel + Cairo at the very top

## Implementation Detail

### src/index.css (top)
```css
@import url('https://fonts.googleapis.com/css2?family=Cinzel:wght@600;700;900&family=Cairo:wght@400;500;600;700&display=swap');
@import 'tailwindcss';
```

### src/App.tsx
Single React component `PremiumModal` with:
- Outer: full-viewport flex-center dark overlay
- Inner modal: ~400px wide, scrollable, dark brown panel with gold border + diamond CSS texture
- Header section: crown SVG + title + subtitle
- Benefits grid: 2-col, 8 benefits with inline SVG icons
- Pricing row: 3 tiers (weekly / monthly / annual) — monthly is visually elevated with gold glow border and "BEST VALUE" badge
- CTA button: full-width, gold gradient, Cinzel font
- Close button: top-right X with hover effect

All styling via Tailwind utility classes + inline `style` where CSS variables or gradients are needed.

## Verification
Open the preview panel — the popup should render centered on a dark background, looking like a native part of the game UI with gold borders, diamond texture, crown, benefits grid, and three pricing options.
