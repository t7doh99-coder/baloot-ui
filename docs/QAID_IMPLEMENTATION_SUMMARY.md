# Qaid, Ekka, and Sawa Implementation Summary (Professional Ruleset)

This document outlines the complete implementation of the **Qaid (Challenge)**, **Ekka (اكة)**, and **Sawa (سوا)** mechanics in our game. We have intentionally chosen a **stricter, more professional ruleset** than competitors like Kammelna to ensure a highly competitive and fair gameplay experience.

## 1. System Overview & Professional Ruleset

Unlike casual apps, our game enforces strict accountability for all challenges to prevent spamming and guessing.

### The "High Stakes" Philosophy
- **Unified Penalty System**: In our game, **EVERY false challenge carries a Kabout penalty**. This applies to Qaid (Trick-Play), False Ekka, and False Sawa. If a player halts the game to make an accusation and they are wrong, their team is penalized. 
- **Unified Review Interface**: We use a unified, deep-review overlay (`QaydhaReviewOverlay`) for all challenges, giving players 60 seconds to meticulously review trick history and remaining hands before committing to a high-stakes accusation.

### Bottom Bar Button Availability
| Button | Who Sees It | When Visible |
| --- | --- | --- |
| **قيدها (Qaid)** | All 4 players | Trick play, ≥1 card played, no active Qaid |
| **اكة (Ekka)** | Local player only | Only when leading AND haven't played lead yet |
| **سوا (Sawa)** | All 4 players | Trick play, ≥1 card played |
| **اكشف الورق (Reveal)** | All 4 players | Auto-triggered during Qaid review, Ekka dispute, or Sawa dispute |

## 2. Qaid (قيدها) — Trick-Play Challenge

Qaid is used to review and penalize illegal plays during a trick (e.g., cutting illegally, failing to trump).

### Execution Flow
1. **Instant Freeze**: Server broadcasts `FREEZE_GAME` (≤100ms). No cards can be played.
2. **Snapshot Sent**: Server captures and sends the current game state (all hands, trick history).
3. **Overlay & Timer**: The Qaid overlay slides up on all screens. A **60-second** countdown timer starts.
4. **Step 1 - Select Violation**: The challenger selects one of the 4 violation types.
5. **Step 2 - Select Card**: The challenger taps a specific illegal card in the trick list (blue border). **Both type and card must be selected** to enable the "Challenge" button.
6. **Verdict & Stakes (Point of No Return)**: 
   - **RIGHT (صحيح)**: Confirmed violation. Round ends immediately. Challenger team wins all round points (Hakam=16pts, Sun=26pts × multiplier) + steals all declared projects. Opponents get 0.
   - **WRONG (خطأ)**: False accusation penalty. Round ends immediately. Challenger team gets 0 points. Opposing team gets full round points (16 in Hakam, 26 in Sun × multiplier) + keeps all projects.
   - **Timer Expiry (0s)**: If 60 seconds expire without submitting valid proof, it is automatically treated as a WRONG challenge. Challenger team receives the False Claim Penalty (0 points, opponents win round).
   - **No "Cancel" to Resume Play**: Once cards are revealed, the game CANNOT simply resume because the secrecy of hidden cards was broken. The round MUST conclude with a win or loss.

### Violation Types by Mode
| Type | Sun | Hakam (Open Double) | Hakam (Closed Double) |
| --- | --- | --- | --- |
| Cut (قاطعة) | Yes | Yes | Yes |
| No Trump (ما دق بحكم) | No | Yes | Yes |
| No Over-Trump (ما كبر بحكم) | No | Yes | Yes |
| Four in Double (ربع في الدبل) | No | No | Yes |

## 3. Ekka (اكة) and False Ekka

Ekka is a claim that the player's lead card is the **highest remaining card of that suit** (cannot be beaten by any unplayed card of that suit). If valid, the player's partner is exempt from forced trump.

### Execution Flow
1. Local player presses "اكة" (visible only to them) *before* playing their lead card.
2. Server broadcasts the claim. A speech bubble appears over the player.
3. Opponents can trigger the Review Overlay to challenge the Ekka claim.
4. **FALSE (Claim was a lie)**: Ekka claimant's team gets a Kabout penalty.
5. **TRUE (Claim was honest)**: The disputing challenger's team gets a Kabout penalty.

## 4. Sawa (سوا) and False Sawa

Sawa is a claim that the player holds **only master cards** and is guaranteed to win all remaining tricks.

### Execution Flow
1. Player presses "سوا". Game PAUSES for all 4 players.
2. All 4 players' hands are revealed face-up automatically (اكشف الورق).
3. Opponents can trigger the Review Overlay to dispute the Sawa.
4. **Sawa is VALID**: Disputing challenger team gets Kabout penalty.
5. **Sawa is INVALID**: Sawa claimant team gets Kabout penalty.

## 5. UI Requirements (Qaid Review Screen & Kammelna Design)

The Qaid review screen is a **single scrollable view**.
- **Top Panel**: Dynamic instruction pill (Red ➔ Amber ➔ Green) + Violation type buttons (Cut, Four in Double, Didn't Over-Trump, Didn't Trump).
- **Middle Body**: Trick history. Each trick shows 4 overlapping cards with full shadows and highlights.
- **Bottom (Scroll End)**: **All 4 players' hands** arranged in a 2x2 grid (matching Kammelna `5.png`), permanently visible at the bottom of the scroll view.
- **Fixed Bottom Bar**: Action button ("Challenge" / "Close") on the left, Challenger identity pill in the center, and circular countdown timer on the right.

### Card Selection & Highlighting States (Kammelna Rules)
1. **Accused Card (الورقة المغشوش بها - Cheating Card)**:
   - Always highlighted in vibrant **RED** (`0xFFFF4D4F`) with red outline and glow.
   - Selected from any trick played during the round.
2. **Proof / Other Card (ورقة الإثبات - Evidence Card)**:
   - Always highlighted in vibrant emerald **GREEN** (`0xFF4ADE80`) with green border, emerald tint, and lift animation.
   - Can be selected from **any of the 4 players' hands** below OR from **another trick** played during the round (matching Kammelna `4.png` & `5.png`).
3. **Challenge Readiness**:
   - Both the Accused Card (Red) and the Proof Card (Green, for violations requiring proof) must be selected before the "Challenge" button enables in royal gold.

### Qaid 3-Option Popup Menu
When tapping "Qaid" in the bottom HUD:
- A vertical popup menu appears directly above the Qaid button:
  1. **False Ekka (إكة خاطئة)**
  2. **Wrong Sawa (سوا خطأ)**
  3. **Reveal Cards (اكشف الورق)** ➔ Opens the full Review Overlay.
