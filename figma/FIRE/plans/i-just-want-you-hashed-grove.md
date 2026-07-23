# Plan: Animated Flames Icon

## Context

The user wants a new standalone animated flames icon to complement the existing chest icon. The flames should look dynamic and alive — like a fire/torch icon you'd find in a game UI.

## Approach

Create `src/app/components/FlameIcon.tsx` — a self-contained SVG + CSS animation component using:

### SVG Structure
1. **3–4 layered flame shapes** (SVG `<path>` teardrop/flame curves), stacked from large (outer) to small (inner):
   - Outer flame: deep orange-red (`#DC2626` → `#EA580C`)
   - Mid flame: orange-amber (`#F97316` → `#FBBF24`)
   - Inner flame: bright yellow-white (`#FDE68A` → `#FFFBEB`)
   - Core flicker: tiny near-white spike at the tip
2. **Ember base glow**: radial gradient ellipse at the bottom simulating heat glow
3. **Floating ember particles**: 4–5 tiny circles that drift upward and fade out

### Animation (pure CSS `@keyframes` via `<style>` tag injected into the SVG)
- **`flicker`** on the outer flame: slight vertical scale + slight horizontal sway, 0.8s ease-in-out infinite alternate
- **`flicker2`** on the mid flame: offset timing (0.4s delay), slightly different sway
- **`flicker3`** on the inner flame: faster 0.5s, more vertical movement
- **`ember`** on each particle: translateY upward + opacity fade, staggered delays (0s, 0.3s, 0.6s, 0.9s, 1.2s), 1.5s linear infinite

### Display in App.tsx
Show both icons side by side:
```
<ChestIcon size={280} />
<FlameIcon size={200} />
```

## Files to Create/Modify

- `src/app/components/FlameIcon.tsx` — **new file**, exports `<FlameIcon>` with embedded CSS animations
- `src/app/App.tsx` — add `<FlameIcon>` next to the existing chest, change layout to `flex-row` with `gap-10`

## Color Tokens

| Element | Color |
|---------|-------|
| Outer flame base | `#B91C1C` (red-700) |
| Outer flame tip | `#EA580C` (orange-600) |
| Mid flame | `#F97316` (orange-500) → `#FBBF24` (amber-400) |
| Inner flame | `#FDE68A` (amber-200) → `#FFFBEB` |
| Base glow | `#FCD34D` (amber-300) |
| Ember particles | `#FCA5A5` (red-300), `#FCD34D` |

## Verification

Preview should show:
- Chest icon and flame icon displayed side by side on dark background
- Flames visibly animate (flicker/sway motion)
- Embers float upward and fade
- Icon looks like a game-UI fire element
