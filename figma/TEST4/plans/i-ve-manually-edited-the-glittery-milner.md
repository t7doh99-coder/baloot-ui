# Plan: Clash Royale–Style Diamond Tile Background

## Context

The current SVG implementation produces diamonds but lacks the signature **3D bevel edge** that makes the Clash Royale background look authentically raised/quilted. The user wants a pixel-accurate replica of that look: each diamond tile must have a clearly lit top-left bevel edge, a shadowed bottom-right bevel edge, a soft gradient face, and a drop shadow — all in a monochromatic sky-blue palette.

## Reference Analysis

From the provided screenshot the pattern has:
- **Tile layout**: 45°-rotated squares (diamonds) in a straight grid (no row offset)
- **Gap/grout**: thin dark-blue gap (~6–8 px) between every tile
- **Bevel edges**: each tile edge visibly split — top-left edge is *lighter* than the face (catching light from upper-left), bottom-right edge is *darker* (in shadow)
- **Face gradient**: top-left of face is lighter, bottom-right is slightly darker
- **Drop shadow**: soft dark shadow below/right of each tile adds physical depth
- **Corner radius**: pronounced rounded corners (~20% of diamond half-width)
- **Palette (approximate)**:
  - Gap: `#1868a2`
  - Shadow: `#083058` @ 50% opacity
  - Dark bevel (bottom-right edge): `#2060a0`
  - Light bevel (top-left edge): `#88c8ea`
  - Face gradient: `#b8e0f8` → `#4898cc`
  - Specular sheen: white → transparent

## Implementation Plan

**File to edit**: `src/app/App.tsx` (only file that changes)

### Geometry (80 × 80 px tile, center at 40,40)

| Layer | Square size | x,y offset | rx | Transform |
|-------|------------|------------|-----|-----------|
| Shadow | 52 × 52 | 14,14 | 10 | `translate(2,4) rotate(45 40 40)` |
| Dark bevel base | 52 × 52 | 14,14 | 10 | `rotate(45 40 40)` |
| Light bevel (shifted up-left) | 52 × 52 | 14,14 | 10 | `translate(-1,-2) rotate(45 40 40)` |
| Face | 46 × 46 | 17,17 | 9 | `rotate(45 40 40)` |
| Sheen overlay | 46 × 46 | 17,17 | 9 | `rotate(45 40 40)` |

The face (46px) is **smaller** than the bevel base (52px). The exposed 3-px border around the face IS the visible bevel. The light bevel sits underneath and is shifted (-1,-2) in screen space so it peeks out on the top-left side; the dark bevel base peeks out on the bottom-right side.

> **Transform order note**: `transform="translate(-1,-2) rotate(45 40 40)"` applies rotate first then translate, shifting the whole diamond in screen-space. This is the correct SVG semantics.

### SVG Gradients (all `gradientUnits="userSpaceOnUse"` within the 80×80 pattern cell)

```
dFace:  linear  (17,17)→(63,63)   #b8e0f8 0% → #80c4e4 25% → #52a4d4 65% → #3282bc 100%
dSheen: linear  (17,17)→(52,52)   #ffffff 50% opacity 0% → #ffffff 5% opacity 55% → transparent
```

### Layer Paint Order (inside `<pattern>`)

1. `<rect>` full cell — gap fill `#1868a2`
2. Shadow diamond — `#083058`, opacity 0.5, translate(+2,+4)
3. Dark bevel diamond — `#1e5e9e`, no opacity
4. Light bevel diamond — `#88c8ea`, translate(-1,-2)
5. Face diamond — `fill="url(#dFace)"`
6. Sheen overlay — `fill="url(#dSheen)"`

### Other Settings

- `patternUnits="userSpaceOnUse"`, pattern width/height = `80`
- Container: `width:100vw; height:100vh; overflow:hidden`
- SVG `display:block` to prevent inline baseline gap

## Verification

After implementation, the preview should show:
- ~5 diamonds visible across a 390 px wide mobile viewport
- Each diamond clearly has a lighter left/top edge and darker right/bottom edge (bevel)
- Visible soft drop shadow beneath each tile
- No tile bleeds outside the viewport; gap fills seamlessly at all edges
