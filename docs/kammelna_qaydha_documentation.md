# Kammelna Baloot — Qaydha (Challenge) Feature Documentation

> Living document. Each screen/flow of the Qaydha system is documented here as we go through the code and screenshots.

---

## Screen 1 — Qaydha Review Overlay: **Selection Mode**

**Source file:** `qaydha_review_overlay.dart`
**Widget:** `QaydhaReviewOverlay` → `_buildSelectionTopPanel`, `_buildTrickRow`, `_buildBottomBar`
**Reference screenshot:** `2.png`

### 1. Purpose

This is the entry screen of the "Qaydha" (تقييد / calling a foul) flow. When a player suspects an opponent broke a rule during the round (e.g. didn't follow suit, didn't trump when required), they open this overlay to:

1. Pick **which trick** ("أكلة") contains the suspicious play.
2. Pick **which violation type** applies to that trick.
3. Submit the challenge ("قيدها").

The overlay is a full-screen modal (`Positioned.fill` + `Container(color: black@88%)`), blocking interaction with the table underneath. Tapping the background does nothing (`onTap: () {}` — intentionally non-dismissible; only the explicit buttons close it).

### 2. Layout (top → bottom)

| Region | Widget | Content |
|---|---|---|
| Top Panel | `_buildSelectionTopPanel` | Instruction pill + violation-type button row |
| Body | `ListView` inside `Expanded` | One row per trick played this round (`الأكلة 1`, `الأكلة 2`, …) |
| Bottom Bar | `_buildBottomBar` | Challenge/Close button (left) + Challenger name & countdown timer (right) |

### 3. Top Panel — detail

**Row 1: Instruction pill (left) + static label (right)**

The instruction pill text and color change based on 2-step selection state:

| State | Condition | Arabic text | English text | Pill color |
|---|---|---|---|---|
| Step 1 | No trick selected yet | أختر الورقة التي تم الغش بها | Choose the card that was cheated with | 🔴 Red `#E53935` |
| Step 2 | Trick selected, no violation yet | أختر نوع القيد | Choose violation type | 🔴 Red `#E53935` |
| Step 3 | Both selected | جاهز — اضغط قيدها | Ready — Press Challenge | 🟢 Green `#66BB6A` |

The right-side pill is static: **"نوع القيد"** ("Violation Type") — just a section label, not interactive.

**Row 2: Violation-type buttons**

The available violation options depend on game mode (`game.roundState.activeMode`):

- **If mode is `hakam`** (Hakam/trump-caller mode):
  - قاطع — Cut (index 0) — *always shown*
  - ربع في الدبل — Four in Double (index 1) — **only shown if `isClosedDouble`** (i.e. `doubleStatus != none` AND `!isOpenPlay`)
  - ما كبر بحكم — Didn't Over-Trump (index 2)
  - ما دق بحكم — Didn't Trump (index 3)
- **Any other mode** (e.g. Sun/no-trump):
  - قاطع — Cut (index 0) — the *only* option

Buttons are laid out with `Wrap` (wraps to new line if they don't fit), `Directionality` set per locale (RTL for Arabic). Selecting one sets `game.selectedQaydhaViolationIndex`.

*(Selected/unselected button styling for these chips is in the still-untruncated part of the file we haven't fully reviewed yet — to be filled in.)*

### 4. Body — Trick List

Rendered via `List.generate(tricks.length, ...)` → `_buildTrickRow` for each trick in `game.trickHistoryThisRound`.

From the screenshot, each trick row shows:
- A header bar with the trick number, right-aligned in Arabic: **"الأكلة 1"**, **"الأكلة 2"**, **"الأكلة 3"**, **"الأكلة 4"** ("Trick 1/2/3/4")
- The 4 cards played in that trick, rendered left-to-right, overlapping/fanned, using the shared `PlayingCard` widget (from `playing_card.dart`)
- Rows are dark cards (`#1E1808`-family) with rounded corners, stacked vertically in the scroll view, separated by spacing

Tapping a row presumably sets `game.selectedQaydhaTrickIndex = index` (drives the instruction-pill state above). *(Exact tap/selection visuals — e.g. highlight border on selected trick — still need to be confirmed from the truncated `_buildTrickRow` implementation.)*

If a trick is selected and we're **not** in result mode, an additional section appears below the trick list: `_buildPlayersCardsSection` — presumably where the player picks a specific card within the trick, and/or a "proof card" (see below).

### 5. Bottom Bar — detail

**Left: Action button**

- Shows **"إغلاق" (Close)** when:
  - We're in result mode, OR
  - Action type is `reviewTricks` and the challenge can't yet be submitted (`!canSubmit`)
  - Tapping calls `game.cancelQaydha()` (selection mode) or `game.closeQaydhaResult()` (result mode)
- Otherwise shows **"قيدها" (Challenge)**:
  - Enabled (`canSubmit == true`) only when a trick AND a violation type are selected — plus, if the violation type requires proof (`requiresProof`), a proof card must also be selected (`game.selectedQaydhaProofCardIndex != null`)
  - Enabled state: gold gradient (`#FFD54F` → `#C49028`), gold border/glow
  - Disabled state: dark flat gradient (`#392C14` → `#2C2210`), dim text
  - Tapping (when enabled) calls `game.submitQaydhaChallenge()`

**Right: Challenger identity + countdown timer**

- Pill showing **"المقيد: <player name>"** ("Challenger: <name>") — in the screenshot: `elpatron12215`
- A circular countdown timer next to it:
  - **60 seconds** in selection mode, **8 seconds** in result mode (`TweenAnimationBuilder`, 1.0 → 0.0)
  - Timer ring/text color: gold `#C49028` while >25% time remains, red `#E53935` when low
  - On timer expiry (`onEnd`):
    - If in result mode → `game.closeQaydhaResult()`
    - If action is `revealCards` → `game.cancelQaydha()`
    - Otherwise (still selecting) → auto-submit if `canSubmit`, else auto-cancel

### 6. Data / State Dependencies

From `GameProvider` (`game_provider.dart`):
- `isQaydhaReviewVisible` — whether overlay should show
- `qaydhaChallengeResult` — non-null once a challenge has been submitted and resolved (switches UI to result mode)
- `currentQaydhaAction` (`QaydhaActionType`) — current step/action in the flow
- `trickHistoryThisRound` — list of tricks played this round, each rendered as a row
- `selectedQaydhaTrickIndex` — which trick the player picked
- `selectedQaydhaViolationIndex` — which violation type the player picked
- `selectedQaydhaProofCardIndex` — proof card, if the violation type requires one
- `roundState.activeMode` — determines which violation options are available (Hakam vs. other)
- `doubleStatus`, `isOpenPlay` — determine whether "ربع في الدبل" is offered
- `playerName(0)` — the challenger's display name

### 7. Card Selection Highlighting (confirmed from screenshots 3–6)

Once the player taps an individual card inside a trick row, that card gets a colored overlay so it stands out from the rest of the (still white/normal) cards in that trick:

| Highlight color | Seen on | Likely meaning |
|---|---|---|
| 🩷 Pink/red wash | 9♣ in "الأكلة 1" (trick 1) | The **accused card** — the specific card the challenger is flagging as played illegally (e.g. a "cut"/didn't-follow-suit violation) |
| 🟩 Green wash | 9♦ in "الأكلة 5" (trick 5) | Appears in a different screenshot where the players'-hands section is already showing below — likely marks a **different selection state**, possibly the reference/matching card once a violation type tied to trump ("ربع في الدبل" / didn't-trump types) is selected, or a secondary "confirmed" selection state as opposed to the initial pink "picking" state |

Only one card per trick row appears highlighted at a time — the rest of that trick's cards, and all other tricks' cards, stay in normal full color. This confirms `_buildTrickRow` takes a per-card tap handler (not just a per-row/per-trick one) — the player selects a specific **card**, not just a trick, and `game.selectedQaydhaTrickIndex` is paired with a specific selected card index within that trick.

*(Note: two different highlight colors were observed pink vs. green across screenshots; the exact rule for which color appears in which state still needs confirming against `_buildTrickRow`'s source once we view lines 198–709 directly — noted below as still open.)*

### 8. Players' Cards Section — `_buildPlayersCardsSection` (confirmed from screenshots 3–6)

Once a trick + card is selected, this section appears below the trick list (matches the earlier note that it only shows "if `selectedQaydhaTrickIndex != null` and not result mode").

**Layout:** A 2-column grid, one card-column per player, in pairs of rows (4 players total → 2 rows × 2 columns). Each player's box has:
- **Header:** player name (e.g. `Taleb Alkathiree`, `ابو عليه0`, `elpatron12215`, `كمبيوتر 3` — "Computer 3", i.e. a bot) with a small colored dot badge next to the name (status/turn indicator — color varies, seen as yellow/orange dots)
- **Body:** that player's current remaining hand, shown as 2–3 face-up playing cards (their cards left after the tricks played so far)

**Selectable vs. non-selectable cards:** In the full 4-player view (screenshot "Image 3"), two players' cards render in **normal full color** (`Taleb Alkathiree`, `ابو عليه0`) while the other two players' cards (`elpatron12215` — the challenger themself, and `كمبيوتر 3`) render **desaturated/grayed out**.

This strongly suggests:
- This section is used to pick the **proof card** (`selectedQaydhaProofCardIndex`) — i.e., visually prove the accused player still held a card of the relevant suit/rank when they committed the violation.
- **Grayed-out hands are not eligible for selection** (e.g. the challenger's own hand, and/or players not relevant to this specific accusation), while **full-color hands belong to selectable players** (candidates for who committed the violation / whose card can serve as proof).
- This confirms `requiresProof` is tied to certain violation types (per the bottom-bar logic already documented) — likely "قاطع" (Cut) and the "didn't trump" variants, since those are exactly the violations where you'd need to show the accused still had a valid card in hand.

### 9. Instruction Pill — transitional/overlapping text (screenshots 3 & 6)

Two screenshots caught the instruction pill mid-animation, showing overlapping text like **"أختر" + "نوع القيد"** layered on top of each other, and one frame even shows the pill briefly rendering **"قيدها"** (the Challenge button's own label) inside it. This is very likely just a captured cross-fade/`AnimatedSwitcher` transition frame between instruction states (e.g. "Choose the card…" → "Choose violation type…"), not a distinct designed state — worth flagging as a **potential minor UI/animation bug** (text overlap should be avoided during transition, e.g. by using a fade+size clip) rather than intentional design.

### 10. Timer confirms countdown-only, not reset by interaction

Across the 4 new screenshots the timer value only counts down (58 → 32 → 28 → 24 across the sequence) and never resets/increases as the player makes selections (picks a trick, a card, opens the players'-cards section). This confirms the 60-second countdown from `_buildBottomBar` runs continuously for the whole selection flow regardless of interaction — the player must complete trick + violation-type (+ proof card, if required) + tap "قيدها" within that single window, or it auto-submits/auto-cancels per the `onEnd` logic already documented.

### 11. Open items (still need the untruncated middle of the file, lines 198–709, to fully confirm)

- [ ] Exact selected/unselected chip styling for violation-type buttons themselves
- [ ] `_buildTrickRow` — exact tap target (whole trick vs. individual card), and the rule governing pink vs. green highlight color
- [ ] `_buildPlayersCardsSection` — exact selection/tap behavior for proof cards, and why 2 of 4 players' hands are grayed out (challenger's own hand excluded? teammate excluded? only accused pair eligible?)
- [ ] `_buildResultTopPanel` — result mode's top panel (win/lose messaging) — not yet screenshotted
- [ ] Formal definition of `requiresProof` per violation type in code

---

## Appendix A — Domain Research: How "قيود" (Qaydha) Works in Real Baloot, and Gap-Check vs. Kammelna

I researched how Qaydha/"قيود" (violation-calling) works in Baloot generally and in other Arabic card-game apps, to sanity-check what we've documented from Kammelna's code/screenshots and flag anything that might be missing.

### A.1 What "قيد" means in general

A "qayd" (restriction/violation record) is, generally, the act of logging a cheating incident against an opposing team's player when that player plays an illegal card. *(Source: Jawaker Blog — "قيود البلوت")* This matches exactly what `QaydhaReviewOverlay` implements: pick the trick, pick the violation type, submit.

### A.2 Violation-type taxonomy is mode-dependent — confirmed, and possibly incomplete in Kammelna

Other Baloot platforms (e.g. Jawaker) split violation types by game mode into two groups. *(Source: Jawaker Blog — "قيود البلوت")*

- **قيود الصن (Sun-mode violations):** قاطع (Cut), and **سوا خاطىء** (Wrong "Sawa"/false claim of taking all remaining tricks)
- **قيود الحكم (Hukom-mode violations):** قاطع (Cut), ما كبر بحكم (Didn't Over-Trump), ربَع في الدبل (Four in Double), ما دق بحكم (Didn't Trump), and **سوا خاطىء** again

**This lines up almost exactly with what the Kammelna code implements** (`_buildSelectionTopPanel`'s `violationOptions` list) — *except for one thing*: **"سوا خاطىء" (Wrong Sawa) is not among Kammelna's four buttons**, in either the Hakam list (`قاطع`, `ربع في الدبل`, `ما كبر بحكم`, `ما دق بحكم`) or the non-Hakam/Sun list (`قاطع` only).

This is worth flagging as a genuine gap to verify with the client/dev team:
- Either Kammelna intentionally doesn't support calling out a false "Sawa" claim through this overlay (maybe it's auto-detected/handled elsewhere in the game engine, since "Sawa" is a declared claim the server could validate automatically rather than needing a manual challenge), **or**
- It's a missing violation type compared to competitor apps, and worth asking the client whether it's intentionally out of scope for this screen.

### A.3 Confirmed meaning of "قاطع" (Cut) — matches our earlier inference

"Qate3" (Cut) refers to a player who plays a card that doesn't match the suit currently on the table. *(Source: maugames.com — "مصطلحات لايفهمها الا محبي البلوت")* This confirms our doc's inference in section 7 — it's a **revoke/failure-to-follow-suit** violation, i.e. the accused player had a card of the led suit but played something else instead. This also explains *why* the proof-card section exists: the challenger needs to point at a card still in the accused player's hand that proves they were holding the led suit at the time.

### A.4 What "سوا خاطىء" is (for context, even though it's absent from Kammelna's list here)

A false "Sawa" claim happens when a player declares they'll take all the remaining tricks but their hand doesn't actually guarantee that; in that case the full points go to the opposing team and the claiming team scores zero. *(Source: maugames.com — "مصطلحات لايفهمها الا محبي البلوت")* Good to have documented even though it's not one of the four buttons in this overlay — useful if we find it implemented as a separate flow elsewhere in the app.

### A.5 Real-world procedural rule that the digital UI **replaces**, not "misses"

In physical/live-scored Baloot, requesting a violation record requires placing the card face-down and asking the referee for the record — and if the card is revealed before that, the player forfeits the right to request it, with a penalty ("takweesh") going the other way if the accusation turns out to be wrong. *(Source: Sport360x — "قوانين البلوت")*

Kammelna's digital version obviously can't have a "face-down card" concept — it replaces that whole real-world procedure with:
- The visible trick history + tap-to-select UI (no concealment needed since the server already knows exact card order)
- The 60-second countdown as the digital equivalent of "you must act quickly, before the moment passes"

**One thing worth double-checking**, though: the real-world rule has a real **penalty for a wrong accusation** — a false accusation flips the penalty onto the accuser. We haven't yet seen a Kammelna screenshot confirming what happens if `qaydhaChallengeResult` comes back as "the accusation was wrong" — i.e. does the *accusing* team get penalized, or does it just silently fail? This is the single biggest functional gap in our documentation right now, and matches the still-open "Open item" about `_buildResultTopPanel` (we don't have a result-mode screenshot yet).

### A.6 App context (background, not screen-specific)

For context on the app itself: Kammelna markets itself as offering the most realistic Baloot experience, specifically calling out that it lets players cut and register violations during play just like real physical Baloot. *(Source: Kammelna app store listing, via MWM)* This Qaydha overlay is very likely the flagship implementation of that marketed feature — worth noting in an intro/exec-summary if this document is shared with stakeholders.

### A.7 Precise definitions confirmed for "ما دق بحكم" and "ما كبر بحكم" (previously inferred, now sourced)

A dedicated Baloot rules article breaks the "must-play" obligations in Hakam mode into three layered rules, which map 1:1 onto Kammelna's four violation buttons:

| Real Baloot obligation | What it requires | Kammelna violation button if broken |
|---|---|---|
| **قيد اللون** (follow-suit rule) | If you hold a card of the suit led, you must play it | **قاطع** (Cut) |
| **قيد القطع** (must-trump rule) | If you don't hold the suit led but do hold a trump card, you must play trump | **ما دق بحكم** (Didn't Trump) |
| **قيد الرفع / التشلية** (must-over-trump rule) | If a trump has already been played in the trick and you hold a *higher* trump, you're expected to play the higher one rather than under-trump | **ما كبر بحكم** (Didn't Over-Trump) |

*(Source: BalootX — "أنواع القيد في البلوت")* This confirms our earlier inference precisely: these three buttons plus "قاطع" cover the complete set of mandatory-play violations in Hakam mode. Nothing appears to be missing from that specific rule family.

### A.8 "ربَع في الدبل" (Four in Double) — refined understanding

We still don't have a clean one-line definition of this exact phrase, but combining two more research threads gets us closer than before:

- Baloot's **"أربع مية" project** (sometimes shortened in speech to just **"ربع"**) is holding four cards of the same rank — worth 400 points in Sun mode, or 100 points in Hakam mode. *(Source: Almrsal — "ترتيب المشاريع في البلوت")*
- Separately, a general Baloot rules-store page documents a standalone violation category: **a player mentions having a project but doesn't lay/show it (فرش) on the table** — the opposing team then has the right to request a formal record (تسجيل) against them for it. *(Source: rb3haa.com — "قوانين البلوت")*

Put together, "ربَع في الدبل" most likely means: **a player claims/implies a "ربع" (four-of-a-kind) project during a closed double but fails to properly lay it down/reveal it as required** — and this specific violation is scoped to the *closed double* case because that's exactly the scenario where projects can't just be casually re-confirmed later (the "closed" nature of the double removes the normal opportunity to double-check). This lines up with the code gating this button on `isClosedDouble`.

This is still an inference rather than a confirmed 1:1 match — flagged below as still worth a final check against Kammelna's own in-app rules text if one exists, since "closed double" project-disclosure conventions can vary by regional house-rules.

### A.9 Nothing else appears to be missing from the violation taxonomy itself

Cross-checking against every Baloot rules source found (Jawaker, BalootX, Sport360x, rb3haa.com, Almrsal), the only violation category **not** represented as a button in this Kammelna screen is "سوا خاطىء" (already flagged in A.2) — every other standard violation type (suit-following, must-trump, must-over-trump, and four-of-a-kind/project disclosure) has a corresponding button. So the open questions have narrowed down to implementation details (styling, tap targets, result-screen behavior) rather than missing game-rule coverage.

### A.10 Updated Open Items List (merging code-review gaps + research gaps)

- [ ] **(Functional gap — highest priority)** What does the *result* screen show for a **failed/incorrect** challenge — is there a penalty to the accusing player/team, matching the real-world "takweesh" reversal rule? Need a result-mode screenshot or the `_buildResultTopPanel` source.
- [ ] Why is "سوا خاطىء" (Wrong Sawa) not offered as a violation type in this overlay — intentionally out of scope, or handled elsewhere?
- [ ] Exact selected/unselected chip styling for violation-type buttons
- [ ] `_buildTrickRow` — exact tap target and the rule governing pink vs. green card-highlight color
- [ ] `_buildPlayersCardsSection` — exact proof-card selection rule (why 2 of 4 hands are grayed out)
- [ ] Formal definition of `requiresProof` per violation type in code
- [x] ~~Meaning of "قاطع", "ما دق بحكم", "ما كبر بحكم"~~ — confirmed in A.7 above
- [ ] Final confirmation of "ربَع في الدبل" against Kammelna's own in-app rules text, if available (our best inference is in A.8, but not yet verified against the actual app copy)

---

*(Next: continue documenting the result screen and remaining helper widgets once reviewed / once a result-mode screenshot is available.)*
