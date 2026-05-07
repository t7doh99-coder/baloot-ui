# Baloot Scoring Engine Specification

This document outlines the official mathematical logic, rounding rules, and edge-case handling implemented in the Baloot Scoring Engine. The engine strictly adheres to professional tournament rules (e.g., Kammelna, Jawaker).

---

## 1. Core Concepts: Abnat vs. Scoreboard Points
The engine distinguishes between two types of points:
*   **Abnat (أبناط):** The raw points calculated directly from the cards played during the tricks and declared projects.
*   **Scoreboard Points (بنط/نقاط):** The final divided and rounded points that are added to the team's overall score on the scoreboard. 

The game is played until a team reaches the target score of **152 Scoreboard Points**.

---

## 2. Card Values and Abnat
The raw Abnat values of the cards depend on the active Game Mode.

### Hakam (حكم) - Trump Suit
*   **Jack:** 20
*   **9:** 14
*   **Ace:** 11
*   **10:** 10
*   **King:** 4
*   **Queen:** 3
*   *(All other non-trump cards retain their standard Sun values below).*

### Sun (صن) - No Trump / Non-Trump Cards
*   **Ace:** 11
*   **10:** 10
*   **King:** 4
*   **Queen:** 3
*   **Jack:** 2
*   **9, 8, 7:** 0

*Note: The team that wins the final trick of the round receives a **Ground Bonus of +10 Abnat**.*
*   Total card Abnat in Sun (including Ground Bonus) = **130 Abnat**
*   Total card Abnat in Hakam (including Ground Bonus) = **162 Abnat**

---

## 3. Project Rules, Values, and Scoreboard Conversion
Projects (المشاريع) are specific combinations of cards in a player's hand that provide bonus Abnat.

### Declaration and Priority Rules
1. **Declaration Window:** Projects (except Baloot) must be declared verbally during **Trick 1**, strictly before the player plays their first card.
2. **Project Priority (المفاضلة):** If players from opposing teams both declare projects, the engine resolves priority based on the Kammelna rulebook:
   * **Rule 1 (Sequence Length):** A 400 beats a 100, a 100 beats a 50, a 50 beats a Sera.
   * **Rule 2 (Card Rank):** If sequence lengths are equal (e.g., both have a 50), the project with the highest card wins (e.g., a 50 ending in an Ace beats a 50 ending in a King).
   * **Rule 3 (Turn Order):** If both teams have exactly identical projects, the player closest to the right of the Dealer (earlier in the turn order) wins the priority.
3. **Nullification (إسقاط المشاريع):** The team that loses the priority resolution has all of their declared projects **nullified**. They receive 0 points for them, and only the winning team's projects are scored.
4. **The Baloot Project:** The "Baloot" project (holding the King and Queen of the Trump suit in Hakam) is an exception. It is declared automatically when the second of the two cards is played during the round. It cannot be nullified by priority resolution.

5. **Card Overlap Constraints:** A single card cannot be used in more than one project (e.g., you cannot use the Ace of Spades in both a 100 sequence and a Four Aces project). The only exception is the **Baloot** project, whose cards (K/Q) can simultaneously be part of another sequence project. A player can declare a maximum of 2 projects per round.

### Project Values Table
| Project Type | Abnat Value | Sun Scoreboard Points | Hakam Scoreboard Points |
| :--- | :--- | :--- | :--- |
| **Sera (سرا)** | 20 | 4 | 2 |
| **Fifty (خمسين)** | 50 | 10 | 5 |
| **Hundred (مية)** | 100 | 20 | 10 |
| **Four Hundred (أربعمية)** | 400 | 40 | N/A |
| **Baloot (بلوت)** | 20 | N/A | 2 |

### Scoreboard Conversion Math
The final Scoreboard Points are calculated by dividing the total Abnat by a fixed divisor, followed by specific rounding rules.

#### **Sun (صن) Rules:**
*   **Formula:** (Abnat ÷ 5) rounded to the nearest whole number. This is mathematically identical to the standard Kammelna formula: `(Abnat × 2) ÷ 10`.
*   **Rounding:** Decimals of `.5` or higher round **UP**. Decimals `.4` or lower round **DOWN**.
*   *Note on Sums:* The total Scoreboard Points for cards in Sun is always strictly **26 points** (130 / 5). Digital rounding guarantees this sum.
*   **Examples:**
    *   `113 Abnat` → 113 ÷ 5 = 22.6 → Rounds UP to **23 points**.
    *   `112 Abnat` → 112 ÷ 5 = 22.4 → Rounds DOWN to **22 points**.
    *   `115 Abnat` → 115 ÷ 5 = 23.0 → Exactly **23 points**.

#### **Hakam (حكم) Rules:**
*   **Formula:** (Abnat ÷ 10).
*   **Rounding:** The engine uses Jawaker-standard rounding where exactly `.5` rounds **DOWN**, and `.6` or higher rounds **UP**.
*   *Note on Sums:* The total Scoreboard Points for cards in Hakam is always strictly **16 points** (162 / 10 = 16.2 -> 16).
*   **Examples:**
    *   `75 Abnat` → 7.5 → Rounds DOWN to **7 points**.
    *   `76 Abnat` → 7.6 → Rounds UP to **8 points**.

---

## 4. Win/Loss Conditions & Khams (خسارة المشتري)
To successfully win a round, the team that bought the game (The Buyer) must prove their superiority mathematically.

### The "Covering Projects" Rule (تغطية المشاريع)
To win a round, the Buyer's **Total Abnat** (Cards + Projects) must be **strictly greater** than the Defender's **Total Abnat** (Cards + Projects). 
*   If the Defender has declared projects, the Buyer must earn enough card Abnat to outscore the Defender's combined total.

### Tie Breaker Rules (Sawa / Khams)
If the Total Abnat of both teams is an **exact tie** (e.g., 85 vs 85):
1.  **Normal Play:** The Buyer has failed to achieve superiority. The Buyer **loses the round (Khams)**.
2.  **Doubled Play:** If a Double/Triple/Four multiplier is active, the team that **initiated the last multiplier** loses the tie, and the opposing team wins.

### Khams Penalty Scoring
When the Buyer loses the round (Khams):
*   The Buyer receives **0 points**.
*   The Defenders receive the **entire base score** of the round (26 in Sun, 16 in Hakam).
*   The Defenders also steal and receive all points for **both their own projects AND the Buyer's projects**.

### Kabout (الكبوت)
If a team sweeps and wins all 8 tricks in a round:
*   **Sun Kabout:** 44 Scoreboard Points + Projects
*   **Hakam Kabout:** 25 Scoreboard Points + Projects
*   *(If the Buyer buys the game using an Ace and scores Kabout, the Kabout base points are doubled).*

---

## 5. Multipliers (Doubles)
During the Bidding Phase, the defending team can initiate a multiplier. The engine scales the final scoreboard points dynamically:

*   **Double (دبل):** x2
*   **Triple (ثري):** x3
*   **Four (فور):** x4
*   **Gahwa (قهوة):** x4 (Can only be called as a response to a 'Four' bid, effectively forcing a game-winning/losing wager).
*   *Exception:* The "Baloot" project is strictly immune to multipliers and always grants 2 points. Kabout and Khams penalties properly scale with the multiplier.

---

## 6. Advanced Game Mechanics
*   **Ashkal (أشكال):** A special Sun bid where the buyer passes the purchase to their partner. Scoring is mathematically identical to Sun.
*   **In-Play Sawa (سوا لعب):** If a player holds the remaining master cards in a round, they can declare a Sawa claim. This instantly ends the round, awarding all remaining trick Abnat and the Ground Bonus to the claiming team.
*   **Double Constraints in Sun:** By standard tournament rules, a defending team is restricted from calling "Double" in Sun if they currently have more than 100 points, *unless* the buyer also has more than 100 points. The engine enforces this strictly.
