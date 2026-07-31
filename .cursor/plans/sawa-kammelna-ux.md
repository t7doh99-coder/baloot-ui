# Sawa UX — Kammelna reference (user screenshot) vs baloot-ui

## Motion reference (video)

- **YouTube Short:** [https://youtube.com/shorts/gtO9DIp0c1Q](https://youtube.com/shorts/gtO9DIp0c1Q) (~46s, hashtags e.g. `#بلوت` / `#كملنا` in title area). Use as the **authoritative timing and motion** reference for Sawa at the end of the clip (press Sawa → label → reveal → scoreboard).
- **Note:** Automated page fetch does **not** extract frame-by-frame UX (YouTube returns title/metadata/transcript that may be music-only). Implementation decisions for **duration, multi-hand reveal order, and SFX** should follow **direct review of this Short** plus the static screenshot below.

## Kammelna sequence (confirmed from reference)

From the provided Kammelna screenshot and description:

1. **Claimant seat badge** — Whoever calls **Sawa** gets a **pill/label under their profile** (same visual family as **صن Sun** / dealer / mode tags). In the image: **green bar** with Arabic **"سوا"** under the **top** player.
2. **Hand reveal on table** — That player’s cards (and in full flow, typically **all remaining hands**) are **fanned face-up on the table**, similar in *presentation* to **project card fan** (dramatic reveal before scoring).
3. **Action bar** — Bottom **سوا** (and related) buttons **grey out** once the claim resolves; user cannot act again during the sequence.
4. **Round end** — After the reveal beat, the app transitions to **scoreboard / round result** as usual.

So the user’s mental model is **correct**: **label first → table reveal (project-like) → scoreboard**, not an instant jump.

## What baloot-ui does today (gap)

- **Engine** ([`claimSawa`](lib/features/game/domain/baloot_game_controller.dart)): immediately clears hands, adds synthetic empty trick, **`_scoreRound()`** — **no** phased UI.
- **Provider**: same **3s → scoreboard** path as any round end; **no** Sawa label widget, **no** hand-reveal animation tied to Sawa.
- **Seats** ([`player_seat_widget`](lib/features/game/presentation/widgets/player_seat_widget.dart)): mode/buyer badges exist; **no** “Sawa caller” badge path.

## Possible Kammelna details to lock from the Short (not from one frame)

Along with the linked video, confirm:

| Detail | Why it matters |
|--------|----------------|
| **Reveal order** (claimer only vs all four hands, clockwise?) | Drives animation choreography |
| **Duration** (~1s vs ~2–3s hold before scoreboard) | Match feel + timer integration |
| **SFX** (whoosh, chime) | Polish |
| **Particles / screen flash** | Not in static shot; may appear |
| **Arabic copy** exact string if not just "سوا" | L10n parity |

After watching the Short’s **Sawa beat** at the end, add any extra beats (e.g. full-table sweep, second camera shake) **here** as bullet steps so engineering can match them.

## Implemented in baloot-ui (2026)

- **5s** reveal: [`GameProvider`](lib/features/game/presentation/game_provider.dart) snapshots hands, sets `sawaRevealClaimSeat`, then after **5000ms** calls `claimSawa(0)` with `_sawaSkipTablePauseBeforeScoreboard` so scoreboard follows without the usual **3s** table pause.
- **ProjectCardFanRadial** at each seat + bottom bar (same as trick-2 project reveal).
- **سوى** drawer on claimant via [`player_seat_widget`](lib/features/game/presentation/widgets/player_seat_widget.dart); Majlis chip shows mode **· سوى** during reveal.

## Implementation direction (when building)

- **`GameProvider` / engine flag**: e.g. `lastRoundEndReason.sawa` + `sawaClaimSeat` so UI can show badge on correct seat **before** clearing visual state (or snapshot hands for reveal **before** engine clears).
- **Phased UI**: (1) show seat “سوا” badge + optional banner, (2) play **reveal animation** using snapshot of hands (similar stack to project fan), (3) **then** apply engine resolution or run engine first but keep **copy of hands** for animation only.
- **Avoid** clearing hands in engine **before** snapshot if we need true Kammelna-style reveal—today `claimSawa` clears `_hands` immediately; may need **delay** or **pre-snapshot** on successful claim.

## User confirmation

The described Kammelna flow **matches** common Jawaker-family Sawa presentation: **status label on claimant + dramatic reveal + then scoreboard**. Nothing major is missing from that description except **timing, sound, and multi-hand reveal order**, which a video will lock in.
