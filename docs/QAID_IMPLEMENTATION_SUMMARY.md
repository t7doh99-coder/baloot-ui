# Qaid, Ekka, and Sawa Implementation Summary (Professional Ruleset)

This document outlines the complete architecture and implementation details for **Qaid (قيدها / Challenge)**, **Ekka (إكة)**, and **Sawa (سوا)** mechanics in our Baloot game. We enforce a **strict, professional ruleset** inspired by competitive tournament play and apps like Kammelna, preventing frivolous challenges while rewarding tactical vigilance.

---

## 1. System Overview & Core Philosophy

- **Unified Penalty Stakes**: Every false challenge or unsubstantiated accusation carries a full round loss penalty.
- **Point of No Return**: Once cards are revealed via the review screen, hidden hands are compromised. Therefore, a challenge cannot be cancelled to simply resume play — the round must conclude with a win or loss verdict.
- **Deep Historical & Hand Visibility**: Challenger has 60 seconds to inspect the full trick history and all 4 players' hands simultaneously in a unified scrollable view.

---

## 2. Bottom HUD: Qaid Button & Contextual 3-Option Popup

In the persistent bottom HUD (`HumanPlayerMajlisBar`), the **Qaid button** provides access to a vertical 3-option popup menu:

```
┌─────────────────────────────────┐
│  1. إكة خاطئة (False Ekka)      │  <- Contextual (Active for 6s after opponent's Akka)
│  2. سوا خطأ (False Sawa)        │  <- Contextual (Active during opponent's Sawa reveal)
│  3. اكشف الورق (Reveal Cards)    │  <- Always Available (Opens full Qaid review overlay)
└─────────────────────────────────┘
                ▲
         [ قيدها (Qaid) ]
```

### Option Availability Rules
| Menu Option | Visual State | Trigger Condition / Window | Action |
| --- | --- | --- | --- |
| **إكة خاطئة (False Ekka)** | Enabled / Dimmed (38%) | Active for **6 seconds** after an opponent bot announces "Akka" | Evaluates if a higher card in that suit remained unplayed |
| **سوا خطأ (False Sawa)** | Enabled / Dimmed (38%) | Active during an opponent's Sawa reveal sequence | Evaluates if claimant held any non-master cards |
| **اكشف الورق (Reveal Cards)** | Always Enabled | Available at any time during active trick play | Opens the full 60-second `QaydhaReviewOverlay` |

---

## 3. Qaid Review Overlay Architecture & 2-Step Card Selection

The review screen (`QaydhaReviewOverlay`) is a single, continuous vertical scroll view designed to fit all screen sizes with seamless interaction:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Dynamic Instruction Pill (Red -> Yellow -> Green)        │
│ 2. Violation Buttons (Cut, Four in Double, Over-Trump, etc) │
├─────────────────────────────────────────────────────────────┤
│ 3. Trick History Cards                                      │
│    - Trick 1: [Card 1] [Card 2] [Card 3] [Card 4]           │
│    - Trick 2: [Card 1] [Card 2] [Card 3] [Card 4]           │
├─────────────────────────────────────────────────────────────┤
│ 4. All 4 Players' Remaining Hands (2x2 Grid at bottom)      │
│    Shows ONLY currently unplayed cards (الأوراق المتبقية)   │
│    [Michael - Top]       [Jim - Right]                      │
│    [Dwight - Left]        [Human - Bottom]                  │
├─────────────────────────────────────────────────────────────┤
│ 5. Fixed Bottom Action Bar                                  │
│    [ Challenge / Close ]    [ Challenger Pill ]    [ Timer ]│
└─────────────────────────────────────────────────────────────┘
```

> [!IMPORTANT]
> **Remaining Cards Only (الأوراق المتبقية)**: Following official Baloot and Kammelna rules, the 2x2 player hand grid at the bottom **only displays the cards each player currently holds (unplayed cards)**. For example, if 4 tricks were already played, each player's box displays exactly 4 remaining cards (never the full 8 starting cards). Every card in the 32-card deck is visible on screen in exactly one place: either in a completed trick row or in a player's remaining hand.


### Card Highlighting & Selection Semantics (Kammelna Rules)
1. **Accused Card (الورقة المغشوش بها - Cheating Card)**:
   - **Color**: Translucent Red/Pink tint (`#FF4D4F`) over the card with glow and border.
   - **Selection**: Must be selected from a completed trick where the illegal play occurred.
   - **Deselection**: Tapping the Red card again deselects it and clears any selected proof card (full reset back to Step 1).
2. **Proof Card (ورقة الإثبات - Evidence Card)**:
   - **Color**: Translucent Green tint (`#4ADE80` / `#22C55E`) over the card with emerald glow.
   - **Selection**: Can be selected either from another trick in history OR from any player's remaining unplayed hand at the bottom.
   - **Deselection**: Tapping the Green card again deselects only the proof card (returning to Step 2).
3. **The 3rd Card Tap Reset (Kammelna Cycle)**:
   - When **both** Card 1 (Red) and Card 2 (Green) are already selected:
   - Tapping any **3rd card in a trick** immediately **RESETS** the previous selection pair (clears the old Red and old Green) and designates this newly tapped card as the new **Red (Accused) card**!
   - This prevents players from getting stuck when changing their accusation and provides a fast, seamless 1-tap reset.
4. **Dynamic Instruction Banner Text (Matching Kammelna)**:
   - **Step 1 (No Card Selected)**: `أختر الورقة التي تم الغش بها` ("Choose the card that was cheated with").
   - **Step 2 (Accused Card Selected)**: `أختر الورقة التي كشفت الغش` ("Choose the card that revealed the cheating").
   - **Step 3 (Both Cards Selected / Ready)**: `جاهز — اضغط قيدها` ("Ready — Press Challenge").
5. **Action Button States**:
   - **Disabled**: Dimmed with 35% opacity while card selection is incomplete.
   - **Enabled**: Golden gradient (`#F0CA60` ➔ `#C49028`) with active haptics when valid combination is chosen.

---

## 4. Violation Rules & Mode-Specific Availability Matrix

Violations are dynamically checked against the current round's `GameMode` and `DoubleStatus`. Unavailable options are visually dimmed (38% opacity) and unclickable:

| Violation ID | Type (English) | Type (Arabic) | Sun (صن) | Hakam Open Double | Hakam Closed Double | Proof Requirement |
| :---: | :--- | :--- | :---: | :---: | :---: | :--- |
| **0** | **Cut** | **قاطعة** | **Yes** | **Yes** | **Yes** | Proof card of lead suit showing accused held lead suit |
| **1** | **Four in Double** | **ربع في الدبل** | *No (Dimmed)* | *No (Dimmed)* | **Yes** | Lead card was trump during closed double |
| **2** | **Didn't Over-Trump** | **ما كبر بحكم** | *No (Dimmed)* | **Yes** | **Yes** | Proof card showing higher trump in hand |
| **3** | **Didn't Trump** | **ما دق بحكم** | *No (Dimmed)* | **Yes** | **Yes** | Proof card showing trump held when void in lead |
| **4** | **False Ekka** | **إكة خاطئة** | *No (Dimmed)* | **Yes** | **Yes** | Evaluates if unplayed card is stronger than lead card |

### Violation Logic Rules
1. **قاطعة (Cut / Illegal Off-Suit Play)**:
   - Player failed to follow suit when they still held a card of the trick's lead suit.
   - Mandatory in both Sun and Hakam.
2. **ما دق بحكم (Didn't Trump)**:
   - In Hakam, when void in the lead suit and no one has trumped yet, a player is legally required to trump.
   - Discarding an off-suit card while holding a trump card is an immediate violation.
3. **ما كبر بحكم (Didn't Over-Trump)**:
   - In Hakam, if an opponent has already played trump, subsequent void players must over-trump (play a higher trump) if able.
   - *Partner Exemption*: If player's teammate currently heads the trick with trump, player is exempt from forced over-trumping.
4. **ربع في الدبل (Four in Double / Trump Lead in Closed Double)**:
   - In Hakam with Closed Double (`doubleStatus != none && !isOpenPlay`), leading a trick with trump is prohibited unless player holds ONLY trump cards.

---

## 5. Verdict Evaluation & Scoring Engine

Challenges are evaluated by `QaydhaEngine.evaluateChallenge()` and scored via `ScoringEngine`:

### Point Allocation Table
| Game Mode | Correct Challenge (فائز) | False Challenge / Timeout (خاسر) | Projects Handling |
| --- | :---: | :---: | :--- |
| **Sun (صن)** | Challenger gets **26 pts** (× Double multiplier) | Opponents get **26 pts** (× Double multiplier) | Winner steals all declared projects; Baloot remains immune |
| **Hakam (حكم)** | Challenger gets **16 pts** (× Double multiplier) | Opponents get **16 pts** (× Double multiplier) | Winner steals all declared projects; Baloot remains immune |
| **Gahwa (قهوة)** | Challenger wins entire match (152 pts) | Opponents win entire match (152 pts) | Instant game over |

### Timer Durations
- **Review / Selection Countdown**: **60 seconds**.
- **Timeout Rule**: If 60 seconds expire without selecting valid proof and submitting, it is treated as an automatic failed challenge (forfeiture of round).
- **Verdict Display Countdown**: **6 seconds** (or manual dismissal via "إغلاق / Close").

---

## 6. False Ekka & False Sawa Challenges

### False Ekka (إكة خاطئة)
- **Claim**: Player leads a card claiming it is the master of that suit (no unplayed card of that suit can beat it).
- **Challenge Window**: Opponents have a **6-second window** after an Akka announcement to challenge.
- **Evaluation**: `QaydhaEngine._checkFalseEkka` scans the trick history and remaining cards:
  - If any unplayed card in that suit has higher rank (e.g. Ace or 10 in Sun) ➔ **False Ekka (Violation confirmed)**.
  - If all higher cards were already played in previous tricks ➔ **Valid Ekka (Challenger penalized)**.

### False Sawa (سوا خطأ)
- **Claim**: Player claims to hold only winning master cards for all remaining tricks.
- **Challenge Window**: Active while the Sawa reveal sequence displays all 4 players' hands.
- **Evaluation**: Engine verifies whether any opposing player holds a card that could win a trick against the claimant's hand. If claimant cannot win every trick, Sawa is false.

---

## 7. Scoreboard & Next Round Transition Lifecycle

To ensure zero freezing and rock-solid state management, the transition from Qaid to the new round follows an exact sequence:

1. **Immediate Scoreboard Capture**:
   - `closeQaydhaResult()` terminates review mode and invokes `_engine.applyQaydhaResult(result)`.
   - `_captureLastRoundResult()` executes **synchronously**, immediately populating `game.lastRoundResult`.
   - `RoundScoreOverlay` renders instantly on screen displaying the banner (`قيد صحيح: فزنا 🎉` or `قيد خاطئ: خسرنا 💔`) alongside complete round points and project breakdown.
2. **Scoring Phase Timer Protection**:
   - `_scheduleNextAction()` guards against cancelling timers during `GamePhase.scoring`, preventing race conditions where the transition timer could get dropped.
3. **Automatic Round Reset (6-Second Window)**:
   - Handled cleanly by `_dismissScoreboardAndStartNextRound()`:
     - Dismisses `RoundScoreOverlay` (`_lastRoundResult = null`).
     - Rotates dealer index clockwise: `_dealerIndex = (_dealerIndex + 1) % 4`.
     - Invokes `_engine.startNewRound()`, dealing 5 initial cards to all players and resetting trick state.
     - New dealer announces `'Awal'` via speech bubble.
     - Transitions phase to `GamePhase.bidding` and resumes turn timers.
