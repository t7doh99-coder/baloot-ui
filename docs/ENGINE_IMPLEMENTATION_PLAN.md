# Baloot Game Engine — AI Implementation Plan (Logic First)
**Status:** Ready for Execution
**Target:** Cursor AI / Developer Copilot
**Rulebook Reference:** `docs/BALOOT_RULES.md` (v3.0 - FINAL)

---

## 🤖 System Context & Instructions for AI
You are assisting in building the core logic engine for a highly accurate Arba'a Morba'a Baloot game. 
**CRITICAL CONSTRAINTS FOR AI:**
1. **NO UI CODE:** Do NOT modify or create any Flutter `Widget`, `BuildContext`, or UI files. We are building the "Brain" strictly using pure Dart in the `domain` and `data` layers.
2. **CLEAN ARCHITECTURE:** Stick strictly to feature-first architecture. All logic must be decoupled from presentation.
3. **RULEBOOK SUPREMACY:** Any logic relating to Abnat, bidding, projects, or turning MUST strictly adhere to `docs/BALOOT_RULES.md`. If in doubt, read that file first.
4. **TDD APPROACH:** For complex modules (like the Rules Validator or Scoring Engine), write Dart unit tests in the `test/` directory to prove the logic works before moving on.

---

## 🏗️ Directory Structure Context
All logic will be housed within the `lib/features/game/` directory and shared `lib/data/` layer.

```text
lib/
├── core/
│   ├── interfaces/
│   │   └── i_baloot_controller.dart     # The main contract the UI will eventually talk to
│   └── errors/
│       └── game_exceptions.dart         # Custom exceptions (e.g., InvalidMoveException)
├── data/
│   └── models/
│       ├── card_model.dart              # Base card data
│       ├── player_model.dart            # Player state, hand, index
│       └── round_state_model.dart       # Holds bids, projects, points
└── features/
    └── game/
        └── domain/
            ├── managers/                # State mutation and flow control
            │   ├── deck_manager.dart
            │   ├── turn_manager.dart
            │   └── bidding_manager.dart
            ├── engines/                 # Pure math and rules evaluation
            │   ├── scoring_engine.dart
            │   └── project_detector.dart
            └── validators/              # Qaid (Violation) enforcement
                └── play_validator.dart
```

---

## 🚀 Execution Steps (Sequential)

### Step 1: Upgrade Foundation Models
**Target:** `lib/data/models/`
1. Update `CardModel` to support dynamic point values. Since a Jack is worth 2 in Sun but 20 in Hakam (if it's the trump suit), `value` cannot be hardcoded without context. Create a method `int getPointValue({bool isSun, Suit? trumpSuit})`.
2. Create `CardPlayModel` (wraps a CardModel with the Player who played it).
3. Create `RoundStateModel`: Needs to track `biddingPhase` (Round 1 or 2), `activeMode` (Sun/Hakam/Ashkal), `trumpSuit`, `doubleStatus` (None/Double/Triple/Four/Gahwa), `trickNumber` (1-8).

### Step 2: The Deck & Dealer Manager
**Target:** `lib/features/game/domain/managers/deck_manager.dart`
1. Create a pure Dart class to represent the 32-card deck (7 to Ace).
2. Implement `shuffle()` and `Kut` (cut).
3. Implement `dealInitial()`: Deals 3 cards, then 2 cards, then reveals 1 `buyerCard`.
4. Implement `dealRemainder(Player buyer)`: Handles giving the buyer 2 extra cards + the buyer card, and 3 cards to everyone else. (Handle `Ashkal` exception where teammate gets the cards).

### Step 3: Bidding Engine (Mzad)
**Target:** `lib/features/game/domain/managers/bidding_manager.dart`
1. Create logic for **Round 1**: Players can only choose Hakam (matching buyer card suit) or Pass.
2. Create logic for **Round 2**: Players can choose Hakam (new suit), Sun, Ashkal (restricted to Dealer/Sane), or Pass.
3. Handle **Sawa**: Instantly locks the bid and ends the phase.
4. Output the final Contract (Mode + Buyer + Trump Suit).

### Step 4: The Rules & Violation Validator (Qaid)
**Target:** `lib/features/game/domain/validators/play_validator.dart`
1. Write pure functions to validate if a played card is legal based on `BALOOT_RULES.md` (Section 5 & 9).
2. **Rule 1:** Must follow leading suit if held.
3. **Rule 2:** Mandatory cut (must play trump if void in leading suit during Hakam).
4. **Rule 3:** Up-Trump (must play a higher trump if someone already cut).
5. Throw specific `PlayViolationException` if a rule is broken.

### Step 5: Trick Evaluator & Turn Manager
**Target:** `lib/features/game/domain/managers/turn_manager.dart`
1. Manage the 4-card 'Trick'.
2. Evaluate which of the 4 cards played wins the trick (implementing Sun logic vs Hakam logic).
3. Advance the turn to the winner of the trick.

### Step 6: Project Detector
**Target:** `lib/features/game/domain/engines/project_detector.dart`
1. Implement algorithms to scan an 8-card hand and detect Sera (3 sequence), 50 (4 seq), 100 (5 seq, or 4 of a kind), 400 (4 Aces in Sun only).
2. Implement ranking logic: `400 > 100 > 50 > Sera`. Highest rank wins. If tied, highest card in sequence wins.
3. Detect Baloot (K+Q of trump) — immune to standard project rules.

### Step 7: The Master Scoring Engine
**Target:** `lib/features/game/domain/engines/scoring_engine.dart`
1. This is the most complex math module. Implement **Section 8** of the rulebook.
2. Calculate Raw Abnat from won tricks (+10 for last trick).
3. Determine Round Winner: Did Mustari exceed 65 (Sun) or 81 (Hakam)? If not = Khams (Sweep, 26/16). Check for Kabout (44/25, or 88 for Ace).
4. Apply Double System Logic: Base values (32/40/48) + Project multipliers.
5. Apply specific Jawaker Hakam Rounding (`.5` rounds DOWN, `.6` rounds UP).

### Step 8: Master Controller Integration
**Target:** `lib/features/game/domain/baloot_game_controller.dart` (Implements `IBalootController`)
1. Tie all managers together into the facade that the UI will eventually listen to.
2. Ensure state changes notify listeners or output streams.

---
**End of AI Prompt Plan**
*Feed this file to Cursor Agent to begin logic generation.*
