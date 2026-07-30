# Baloot Game & Scoring Engine Specification

This document outlines the complete game rules, mathematical logic, rounding rules, and edge-case handling implemented in the Baloot Game Engine. The engine strictly adheres to professional tournament rules (Kammelna / Jawaker standard).

---

## 1. Game Structure & Setup
*   **Players:** 4 players in 2 teams. Partners sit across from each other (Seat 0 & Seat 2 = Team A, Seat 1 & Seat 3 = Team B).
*   **Deck:** Standard 32-card Baloot deck (7, 8, 9, 10, Jack, Queen, King, Ace × 4 suits).
*   **Dealer Selection:** The initial dealer is chosen randomly. After each round, the dealer rotates one seat to the right (clockwise on screen).
*   **Turn Order:** Play proceeds from the dealer's right, continuing clockwise on screen (counter-clockwise at a real table).
*   **Rounds:** Each round consists of exactly **8 tricks**. The winner of each trick leads the next one. The first trick of a round is led by the player to the dealer's right.
*   **Game Target:** The game is played until a team reaches **152 Scoreboard Points**.
*   **Sudden-Death Tie-Breaker:** If both teams cross 152 points in the same round and their scores are an exact tie (e.g., 155 to 155), the game does not end. Additional rounds are played until the tie is broken.

---

## 2. Core Concepts: Abnat vs. Scoreboard Points
The engine distinguishes between two types of points:
*   **Abnat (أبناط):** The raw points calculated directly from the cards played during the tricks and declared projects.
*   **Scoreboard Points (بنط/نقاط):** The final divided and rounded points that are added to the team's overall score on the scoreboard.

---

## 3. Card Values and Abnat
The raw Abnat values of the cards depend on the active Game Mode.

### Hakam (حكم) - Trump Suit
*   **Abnat Values:** Jack (20), 9 (14), Ace (11), 10 (10), King (4), Queen (3).
*   **Trick-Winning Hierarchy:** **Jack > 9 > Ace > 10 > King > Queen > 8 > 7**.
*   *(All non-trump cards retain their standard Sun values and hierarchy below).*

### Sun (صن) - No Trump / Non-Trump Cards
*   **Abnat Values:** Ace (11), 10 (10), King (4), Queen (3), Jack (2), 9/8/7 (0).
*   **Trick-Winning Hierarchy:** **Ace > 10 > King > Queen > Jack > 9 > 8 > 7**.

*Note: The team that wins the final trick of the round receives a **Ground Bonus of +10 Abnat**.*
*   Total card Abnat in Sun (including Ground Bonus) = **130 Abnat**
*   Total card Abnat in Hakam (including Ground Bonus) = **162 Abnat**

---

## 4. Project Rules, Values, and Scoreboard Conversion
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

### Project Values & Composition Table
| Project Type | Composition | Abnat | Sun Pts | Hakam Pts |
| :--- | :--- | :--- | :--- | :--- |
| **Sera (سرا)** | 3 consecutive cards of the same suit | 20 | 4 | 2 |
| **Fifty (خمسين)** | 4 consecutive cards of the same suit | 50 | 10 | 5 |
| **Hundred (مية)** | 5+ consecutive cards of same suit, **OR** Four 10s, Ks, Qs, or Js | 100 | 20 | 10 |
| **Four Hundred (أربعمية)** | Four Aces (Only valid in Sun mode) | 400 | 40 | N/A |
| **Hundred (Aces)** | Four Aces (When played in Hakam mode) | 100 | N/A | 10 |
| **Baloot (بلوت)** | King and Queen of the Trump suit (Hakam only) | 20 | N/A | 2 |

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

## 5. Win/Loss Conditions & Khams (خسارة المشتري)
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

## 6. Multipliers (Doubles)
During the Bidding Phase, the defending team can initiate a multiplier. The engine scales the final scoreboard points dynamically:

*   **Double (دبل):** x2
*   **Triple (ثري):** x3
*   **Four (فور):** x4
*   **Gahwa (قهوة):** This is NOT a point multiplier. Gahwa is an **instant match-ending declaration**. It can only be called by the Buyer's team in response to a 'Four' bid. The round does not play out — the Buyer's team immediately wins the entire game (score is set to 152), regardless of the current scoreboard. It is an all-or-nothing gamble.
*   *Exception:* The "Baloot" project is strictly immune to multipliers and always grants 2 points. Kabout and Khams penalties properly scale with the multiplier.

---

## 7. Advanced Game Mechanics
*   **Ashkal (أشكال):** A special Sun bid where the buyer passes the purchase to their partner. Scoring is mathematically identical to Sun.
*   **In-Play Sawa (سوا لعب):** If a player holds the remaining master cards in a round, they can declare a Sawa claim. This instantly ends the round, awarding all remaining trick Abnat and the Ground Bonus to the claiming team.
*   **Double Constraints in Sun:** By standard tournament rules, a defending team is restricted from calling "Double" in Sun if they currently have more than 100 points, *unless* the buyer also has more than 100 points. The engine enforces this strictly.
*   **Open/Closed Play (مفتوح/مقفل):** When a player calls Double, they may optionally declare the play as **Closed (مقفل)**. In Closed Play, the leading player **cannot lead with a trump card** unless their entire hand consists of trump cards. If no declaration is made, the default is **Open (مفتوح)**, meaning there are no restrictions on leading with trump. This choice is made at the time of doubling and persists for the entire round, even through escalation (Triple/Four).

---

## 8. Dealing System (التوزيع)
The engine uses the standard 32-card Baloot deck (7 through Ace, 4 suits) and deals in two phases:
1.  **Phase 1 (Before Bidding):** Deal 3 cards to each player, then 2 more cards to each player, then reveal 1 face-up **Buyer Card (المشتري)** on the table. Each player now has **5 cards**, with 11 remaining in the deck.
2.  **Phase 2 (After Bidding):** The buyer (or their partner in Ashkal) receives the face-up buyer card + 2 cards from the deck. All other players receive 3 cards from the deck. All players now have **8 cards** and the deck is empty.
3.  **Kut (الكت):** Before dealing, the deck is shuffled and cut (split at a random point and swapped) to ensure fairness.

---

## 9. Bidding Mechanics (الاشتراء)
The engine strictly manages the two-round bidding phase:
*   **First Round:** Players can buy the revealed table card as **Sun**, **Hakam** (in the card's suit), **Ashkal**, or **Pass**.
*   **Sun Overcall:** If a player bids **Hakam** and another player later bids **Sun**, the Sun bid wins instantly (Sun overrides Hakam). The first Sun bidder in turn order wins.
*   **Ashkal Restrictions:** Ashkal can only be called in Round 1 by the **Dealer** or the **Sane (صاني)** (the player to the dealer's left). It is not available in Round 2.
*   **Second Round:** If all four players pass in Round 1, the second round begins. Players can only buy **Hakam** in a suit *different* from the table card's suit. Sun and Ashkal cannot be bid in Round 2.
*   **Hakam Confirmation:** After a player bids Hakam and the remaining 3 players pass, the Hakam bidder gets a final choice: confirm Hakam or switch to Sun.
*   **All-Pass Cancellation:** If all players pass in both rounds, the engine automatically cancels the round, rotates the dealer, and starts a new deal.
*   **Multiplier Escalation Sequence:** Double/Triple/Four/Gahwa must follow a strict alternating pattern: **Defenders → Double**, **Buyer → Triple**, **Defenders → Four**, **Buyer → Gahwa**.

---

## 10. Trick-Play Validation (قوانين اللعب)
The engine actively validates every card played to enforce strict Baloot mechanics:
1.  **Following Suit:** Players *must* play a card of the lead suit if they hold one.
2.  **Trumping (القطع):** In Hakam mode, if a player does not hold the lead suit, they must play a trump card to cut the trick.
3.  **Over-Trumping (التعلاية):** If an **opponent** has already trumped the trick, subsequent players who lack the lead suit *must* play a higher trump card if they have one. If they cannot over-trump, they may play any card.
4.  **Ekka Rule (إيكا):** If a player's **partner** leads with an **Ace**, the partner (as 3rd player) is **exempt** from the forced-trump obligation. They are free to play any card instead of being forced to cut their own partner's winning trick.
5.  **Partner Exemption:** If a partner is currently winning the trick (and the lead was not an Ace), the 3rd player still must cut with trump if they can.

---

## 11. Rule Violations & Penalties (القيود)
The engine acts as an impartial referee. If a severe violation occurs (or in environments where the engine detects a forced illegal state):
*   **The Penalty (القيد):** The round ends immediately.
*   **Penalty Score:** The engine awards the non-violating team a **Kabout score** (44 points in Sun / 25 points in Hakam) **plus** any active project points.
