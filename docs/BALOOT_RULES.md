# 🃏 Baloot (بلوت) — Complete Game Rulebook
# Arba'a Morba'a Baloot — Phase 2 Engine Reference
#
# Source: Abdul Sami's Project Doc + Client (Visca ME) + Jawaker + Meeting Videos
# Benchmark App: Kammelna (كملنا) / Jawaker (القوانين)
# Status: v3.1 — FINAL — All rules verified against Jawaker + Kamelna apps.
# ══════════════════════════════════════════════════════════════════════

---

## ⚠️ Corrections vs. Client Conversation (Cross-Reference Results)

| # | Topic | Client Said | Jawaker (Official) | Final Rule |
|---|---|---|---|---|
| 1 | Sun Scoring Formula | `÷10 × 2` | "Rounded to nearest 10, ×2, ÷10" = **same** | ✅ Confirmed |
| 2 | Hakam Scoring | Abnat determines winner only | "÷10 rounded" + 16 pts for loser | ✅ Confirmed |
| 3 | Project values (Scoreboard) | Sera=2, 50=5, 100=10 | Confirmed (add to round pts) | ✅ Confirmed |
| 4 | Khams (Sweep) pts | Sun=26, Hakam=16 | Sun=26 (0 for loser), Hakam=16 | ✅ Confirmed |
| 5 | Kabout (All-tricks sweep) | Not mentioned | Sun=44, Hakam=25 pts | 🆕 **Client missed this** |
| 6 | Mia (100) Requirements | 5 consecutive same suit | Also: 4×10/J/Q/K same suit OR 4 Aces | 🆕 **Client missed this** |
| 7 | Sun — 400 Project | 4 Aces in Sun | Confirmed | ✅ Confirmed |
| 8 | San Scoring tie condition | Must exceed 65 | "Cannot achieve required points → loses" | ✅ Confirmed |
| 9 | Double — Open/Closed play | Not mentioned | Open vs Closed play rules exist | 🆕 **Client missed this** |
| 10 | Game end target | Not specified | **152 points OR Gahwa win** | 🆕 **Client missed this** |
| 11 | Project announcement | First trick only | "Announced first round, shown second" | ⚠️ **2 rounds, not 1** |
| 12 | Scoring rounding — Hakam | Abnat → winner only | 15.5 rounds DOWN to 15, 15.6 UP to 16 | 🆕 **Specific rounding rule** |

---

## 1. Core Game Foundation

| Property       | Value                                       |
|----------------|---------------------------------------------|
| Players        | 4 (2 teams of 2, sitting across)            |
| Deck           | 32 cards (7 through A, no 2-6 or jokers)    |
| Dealing Order  | Counter-Clockwise at table (= clockwise on screen; to each player's RIGHT) |
| Hand Size      | 8 cards per player (after full distribution)|
| Teams          | Team A: Seats 0 & 2 / Team B: Seats 1 & 3  |
| Game End       | First team to reach **152 points** OR Gahwa win. *(Note: Custom non-standard lobbies may target 300 or 330 points)* |

---

## 2. Dealing Sequence

1. Dealer deals **3 cards** to each player (counter-clockwise).
2. Dealer deals **2 cards** to each player (total: 5 cards each).
3. One card is revealed face-up on the table → the **Buyer Card (Mustari / مشترى)**.
4. **Bidding begins** (see Section 3).
5. After bidding resolves:
   - The **winning bidder** receives the Buyer Card + **2 additional cards** (total 3 new cards → 8 total).
   - All **other 3 players** receive **3 cards** each.

### Kut (Cut)
- Before dealing, the player to the dealer's right cuts the deck.
- Implementation: Randomized background split (no UI interaction required for MVP).

---

## 3. Card Rankings & Point Values

### 3.1 Hakam (Trump) Mode

#### Trump Suit Cards (Rank: highest → lowest)
`J > 9 > A > 10 > K > Q > 8 > 7`

| Card  | Points |
|-------|--------|
| Jack  | 20     |
| 9     | 14     |
| Ace   | 11     |
| 10    | 10     |
| King  | 4      |
| Queen | 3      |
| 8     | 0      |
| 7     | 0      |

#### Non-Trump Suits (Rank: highest → lowest)
`A > 10 > K > Q > J > 9 > 8 > 7`

| Card  | Points |
|-------|--------|
| Ace   | 11     |
| 10    | 10     |
| King  | 4      |
| Queen | 3      |
| Jack  | 2      |
| 9     | 0      |
| 8     | 0      |
| 7     | 0      |

**Total Hakam Raw Abnat:** 152 card pts + 10 (Last Trick bonus) = **162 Abnat**
**Balance Point:** 162 ÷ 2 = **81** (must EXCEED this to win as buyer)

---

### 3.2 Sun (No-Trump) Mode

All suits equal. Rank: `A > 10 > K > Q > J > 9 > 8 > 7`

| Card  | Points |
|-------|--------|
| Ace   | 11     |
| 10    | 10     |
| King  | 4      |
| Queen | 3      |
| Jack  | 2      |
| 9/8/7 | 0      |

**Total Sun Raw Abnat:** 120 card pts + 10 (Last Trick bonus) = **130 Abnat**
**Balance Point:** 130 ÷ 2 = **65** (must EXCEED this to win as buyer)

---

## 4. Bidding System

### 4.1 Turn Order
Starting from the player to the **right of the dealer**, continuing to the right (counter-clockwise at a real table = clockwise on screen).
Screen seat map: 0=bottom(you), 1=right, 2=top(partner), 3=left. +1 = next player.

### 4.2 Round 1 Options (all players)
| Option | Result |
|--------|--------|
| **Hakam** | Accept the revealed card's suit as trump. Bidding continues (see note below). |
| **Pass (Bess)** | Pass to next player. |

> [!IMPORTANT] **Hakam Confirmation Step (Visca ME / Jawaker / Kammelna — VERIFIED):**
> Selecting **Hakam** (Round 1 on buyer card, or **Round 2 Second Hakam**) does **not** immediately lock the contract if other players can still respond. When **no one** has switched to Sun and **no Sawa** has locked the bid:
> - If another player picks **Sun** in Round 1 → game becomes Sun immediately (Sun > Hukm).
> - If another player calls **Sawa** on an existing Hakam bid → Hakam is locked immediately.
> - If **all 3 other players Pass** after a Hakam bid → the **same Hakam bidder** enters a **Confirmation Step**:
>   1. **Confirm Hakam** — locks Hakam (Round 1: buyer card suit; Round 2: chosen Second Hakam suit).
>   2. **Switch to Sun** — converts the game to Sun instead; **same player remains buyer**.
> - This confirmation is **mandatory** before the deal finalizes (Round 1 and Round 2 Second Hakam).
>
> **Visca ME (Apr 2026):** Document explicitly requires this flow for Hakam bought in **first or second round** when no interrupt/Sun switch occurred — parity with Kammelna / Jawaker.

### 4.3 Round 2 Options (if all pass Round 1)
| Option | Result |
|--------|--------|
| **Sun** | No-trump game. Others Pass or Sawa; three Passes lock Sun (no Hakam-style confirmation). |
| **Second Hakam** | Choose a NEW trump suit (must differ from Buyer Card's suit). Others Pass or Sawa; three Passes → **same confirmation** as §4.2: **Confirm Hakam** or **Switch to Sun**. |
| **Pass** | Pass to next player. |

> [!WARNING] **Ashkal is NOT available in Round 2** (verified: Jawaker + Kamelna + Pagat).
> Round 2 options are: Sun, Second Hakam, or Pass only.

### 4.4 Sawa (سوى) — Bid Matching
> [!IMPORTANT] **Confirmed from client meeting video (14-00-32.mp4 @ 00:54) + Jawaker / Kammelna:**
> Sawa matches the current bid level and **immediately ends the bidding phase**.
> Only a player on the **defending team** (opponents of the Hakam / Sun / Second-Hakam bidder) may call Sawa — not the bidder’s partner.
> The **buyer** remains the player who first declared that contract (original Hakam / Sun / Second Hakam bidder); Sawa does not move the buyer to the Sawa caller.
> The opposing team does NOT get a further bidding chance after Sawa.
> (Exception: The defending team may still call a Double BEFORE the first card is played.)

### 4.5 If ALL players pass BOTH rounds
- Round is **cancelled**. New deal with the next dealer.

### 4.6 Ashkal (أشكال) Mode — Special Case
- Available to: **Dealer** and **Player to the LEFT of the Dealer** only.
- The bidder does NOT take the Buyer Card themselves.
- The Buyer Card is given to the bidder's **teammate** instead.
- Game automatically plays as **Sun (No-Trump)**.
- Distribution: Teammate gets Buyer Card + 2 extra cards; others get 3 cards each.

---

## 5. Rules of Play

### 5.0 First Trick Leader (Kammelna Standard)
The player sitting to the **RIGHT of the dealer** leads the first trick in the round, regardless of who bought the bid. 
*(Note: If your previous developer said the "Buyer" leads, that is mathematically incorrect for Kammelna/Saudi rules).*

### 5.1 Mandatory Rules (Both Modes)
1. **Follow Suit:** Player MUST play the leading suit if they hold it.
2. If player cannot follow suit:
   - **Sun:** Play any card (it cannot win the trick).
   - **Hakam:** Player MUST play a Trump card if available.

### 5.2 Hakam-Specific Rules
3. **Up-Trump:** If the player must cut (trump) and an opponent has ALREADY cut, the player MUST play a **higher trump** if they hold one.

### 5.3 Trick Winner Logic
- **Sun / Non-trump play:** Highest card of the **leading suit** wins.
- **Hakam (trump in play):** Highest Trump card wins.
- **Last Trick:** +10 Abnat bonus to the winning team.
- **Next Turn (Important Terminology):** The player who wins the current **Trick** immediately plays the first card of the *next* Trick. (Note: Only at the start of a completely new 8-trick **Round** does the turn reset to the person to the right of the Dealer).

---

## 6. Projects (مشاريع)

### 6.1 Timing Rules (Kammelna — FINAL)
- **Sequence projects (Sera / 50 / 100 / 400):** The declaration window opens **immediately after the opening lead** (after the **first card of trick 1** is played), **before** the second card of that trick. Players declare via a **UI button** in that window; play is paused until declarations are confirmed.
- Each player may announce a maximum of **2 projects** in that window.
- **Baloot** (K+Q of trump in Hakam) remains **engine-detected** when the pair is completed (see §6.4); it is not chosen from the sequence-project declaration UI.
- After trick 1 continues, **revealed** projects behave as in play (e.g. confirmation in later tricks for display) per table convention; the **mandatory declaration window** for sequences is only between the first and second card of trick 1.

### 6.2 Project Reference Table

> [!IMPORTANT] **Project Abnat values DIFFER between Sun and Hakam modes!**

| Project        | Arabic     | Sun Scoreboard Pts | Hakam Scoreboard Pts | Availability   | Requirement |
|----------------|------------|------|------|---------------|-------------|
| Sera           | سرا        | **4** | **2** | Both modes    | 3 consecutive cards, same suit |
| Fifty (50)     | خمسين      | **10** | **5** | Both modes    | 4 consecutive cards, same suit |
| Hundred (100)  | مية        | **20** | **10** | Both modes ⚠️ | 5 consecutive; OR 4×(10/J/Q/K) |
| Four Hundred   | أربعمئة   | **40** | —    | ⚠️ Sun ONLY  | 4 Aces |
| Baloot         | بلوت       | —    | **2** 🔒 | Hakam ONLY | K + Q of Trump (auto, immune to doubling) |

> [!IMPORTANT] **Mia (100) Correction:** Requires 5 consecutive same-suit cards OR four 10/J/Q/K of same suit. Note: 100 IS available in Sun mode! Four Aces in Sun automatically upgrades to 400.

### 6.3 Project Priority Logic
- Both teams compare their highest eligible sequence project.
- Team with the **superior project** has their Abnat added (only the winning team's sequence project counts).
- If tied project rank → compare highest card in the sequence; higher wins.
- If still tied (same rank and same high card, and neither side wins the trump split) → **project Sawa**: **neither** team receives sequence project points (no turn-order tiebreak).
- **Baloot (K+Q):** evaluated separately per engine rules (see §6.5); sequence-project Sawa does not cancel Baloot except where Khams stealing rules apply (§14.4).

### 6.4 Project Multiplier Rule (Jawaker/Kamelna — VERIFIED)
> [!IMPORTANT] When a Double/Triple/Four is active:
> - Project scoreboard points are multiplied by **×2 MAXIMUM** (capped), even in Triple/Four.
> - Example: Double active + Sera (2 pts) = **2 × 2 = 4 pts** from Sera alone.
> - Example: Triple active + Sera (2 pts) = **2 × 2 = 4 pts** (NOT 2 × 3).
> - **Exception: Baloot is ALWAYS exactly 2 pts — it is immune to ALL multipliers.**

### 6.5 Baloot Declaration Timing
- NOT declared during the first trick.
- Declared when the player plays the **SECOND card** of the K-Q pair.
- Worth **2 Scoreboard Points** (not Abnat).

---

## 7. Double System (Hakam Mode Only)

### 7.1 Double Escalation Chain (Jawaker/Kamelna/Pagat — VERIFIED)
The double escalation **alternates between teams**:

| Level | Called By | Response To |
|-------|-----------|------------|
| **Double** | Defending Team | — (initiation) |
| **Triple** | Buyer Team | Response to Double |
| **Four** | Defending Team | Response to Triple |
| **Gahwa** | Buyer Team | Response to Four |

- Only available in **Hakam** mode.
- **Sun Double Exception:** In Sun mode, a Double is ONLY allowed if:
  - The Sun declarer has **more than 100 total scoreboard points**
  - AND the opposing team has **fewer than 100 scoreboard points**
  - In Sun, **no further escalation** beyond Double is possible.

### 7.2 Double Initiation Timing
> [!IMPORTANT] **Confirmed from client meeting video (13-51-23.mp4 @ 02:04):**
> The Double window is open only **BEFORE the first card of the round is played**.
> Once the lead player plays their first card, the Double option is permanently closed for that round.

### 7.3 Double Values (Base Round Reward)

| Action   | Hakam Base Pts | Sun Base Pts | Formula |
|----------|----------------|--------------|--------|
| Double   | **32**         | **52**       | Base (16 or 26) × 2 |
| Triple   | **48**         | —            | 16 × 3 |
| Four     | **64**         | —            | 16 × 4 |
| Gahwa    | Game Win       | —            | Instant |

> [!IMPORTANT] **Double = BASE reward only.** Final score = Base Value + Project Scoreboard Points.
> Note: In Sun mode, escalation beyond 'Double' is strictly prohibited.

### 7.3 Open vs Closed Play (Jawaker Official — New)
When a Double is active, the game must declare Open or Closed:
- **Closed Play:** No player may lead a round with a Trump card if they hold any other suit.
- **Open Play:** Any player may lead with a Trump card freely.

### 7.4 Tie-Breaker Rule (Double Active)
- If Abnat totals are exactly equal (81 vs 81) → **Double caller automatically LOSES**.
- The buyer's team wins. Strict superiority (+1 Abnat minimum) is required by the caller.

---

## 8. Scoring System

### 8.1 Step 1 — Calculate Raw Abnat
```
Each team totals: card point values from all tricks won + any project Abnat
```
- Last trick winner adds +10 Abnat.
- Project Abnat is added BEFORE comparing totals.
- Only the WINNING project team's Abnat is counted.

### 8.2 Step 2 — Determine Round Winner
- **Sun:** Buyer must score MORE THAN 65 Abnat.
- **Hakam:** Buyer must score MORE THAN 81 Abnat.
- If buyer fails → **Khams** (Sweep) applies.

### 8.3 Khams (كهمس / Sweep — Buyer Loses)
| Mode   | Defending Team Gets | Buyer Team Gets |
|--------|---------------------|-----------------|
| Sun    | 26 pts              | 0 pts           |
| Hakam  | 16 pts              | 0 pts           |

### 8.4 Kabout (كبوت / All-Tricks Sweep — Jawaker/Kamelna VERIFIED)
If one team wins **ALL 8 tricks**:
| Mode | Normal Kabout | Ace Kabout | Doubled | Tripled |
|------|--------------|------------|---------|--------|
| **Sun** | **44** pts | **88** pts | 88 pts | — |
| **Hakam** | **25** pts | **50** pts | 50 pts | 75 pts |

> [!IMPORTANT] **Mode-dependent scoring (client / Kammelna & Jawaker):**
> - **Sun (Sann) Kabout** = **44** scoreboard points **+ declared project scoreboard points** (+ Baloot if any).
> - **Hakam Kabout** = **25** scoreboard points **+ declared project scoreboard points** (+ Baloot if any).
> - Sun/Hakam bases are as above (derived from full trick Abnat ÷ 5 vs ÷ 10 in classic scoring).
> - Ace **doubles** the Kabout base only. Double/Triple/Four **also multiply** the Kabout base; project lines use the usual project multiplier (capped ×2 when double is active).

### 8.5 Step 3 — Convert Abnat to Scoreboard Points

#### Sun (No-Trump) Formula (Jawaker Official)
```
Scoreboard Points = round(Raw Abnat ÷ 10) × 2
```
Alternative phrasing: Double the Abnat sum, divide by 10, round.

**Confirmed Examples (from client):**
- 88 Abnat → 88÷10=8.8 → rounds to 9 → 9×2 = **18 pts**
- 42 Abnat → 42÷10=4.2 → rounds to 4 → 4×2 = **8 pts**
- 65 Abnat → 6.5 → rounds to 7 → 7×2 = **14 pts**
- Round total without projects = **26 pts** (opponent’s line is the complement so the two sides always sum to 26)

#### Hakam Formula
```
Scoreboard Points = round(Raw Abnat ÷ 10)
Rounding rule: JAWAKER STYLE — exactly .5 rounds DOWN, .6+ rounds UP
Example: 15.5 → 15 | 15.6 → 16
```
> [!NOTE] **Jawaker rounding (final):** Use `(abnat / 10).truncate()` when remainder is exactly .5,
> otherwise use standard `.round()`. In Dart: `(abnat / 10 * 2).floor() / 2` or custom helper.

### 8.6 Step 4 — Apply Double & Projects to Final Score
```
// No Double:
Final Score = Scoreboard Points (from Abnat conversion) + Project Scoreboard Pts + Baloot Pts

// With Double:
Final Score = Base Double Value (32 / 48 / 64) + Project Scoreboard Pts (×2 cap)
```

**Double + Project Example (confirmed by client):**
- Defending team wins Hakam + Double + Sera (20 Abnat = 2 pts)
- Base = 32 (Double) + 2 (Sera) = **Final = 34 pts**

---

## 9. Violation Guard (Qaid / قيد)

Violations are auto-detected by the engine. Confirmed violation = instant round loss.

| Violation         | Trigger Condition                                                    |
|-------------------|----------------------------------------------------------------------|
| Suit Violation    | Not playing the leading suit while holding one                       |
| Trump Violation   | Not playing higher Trump when required (Up-Trump, Hakam only)        |
| Cut Violation     | Not playing a Trump when out of leading suit (Hakam only)            |

> [!CAUTION] Per client: A **wrong Qaid claim** (falsely accusing another player) results in the **opponent winning** instead.

---

## 10. Turn & Timeout Management

- Each player has **10 seconds** to make a decision.
- Timer expiry → **Bot Takeover**:
  - During bidding: Auto-pass.
  - During play: Play the lowest valid non-violating card.

---

## 11. State Recovery (Reconnection)
On reconnect:
1. Restore player's current hand.
2. Restore game state (trick #, score, active contract, double status).
3. Resume from correct turn position.

---

## 12. Full AR/EN Terminology

| English             | Arabic       | Notes                                    |
|---------------------|--------------|------------------------------------------|
| Sun                 | سن           | No-Trump game mode                       |
| Hakam               | حكم          | Trump game mode                          |
| Ashkal              | أشكال        | Special Sun buy variant                  |
| Mustari / Buyer     | مشتري        | Player who wins the bid                  |
| Buyer Card          | ورقة المشترى | The revealed card on the table           |
| Sane                | صانع         | Player to dealer's left                  |
| Pass / Bess         | تمرير / بس   | Pass in bidding                          |
| Sawa                | سوى          | Match bid                                |
| Baloot              | بلوت         | K+Q of trump (auto, 2 pts)               |
| Lana                | لنا          | Our Score                                |
| Lahum               | لهم          | Their Score                              |
| Abnat               | أبنات        | Raw point unit                           |
| Khams               | كهمس         | Sweep (buyer loses round)                |
| Kabout              | كبوت         | All-tricks sweep                         |
| Sera                | سرا          | 3-card sequence (20 Abnat)               |
| Kut                 | كت           | Deck cut before dealing                  |
| Gahwa               | قهوة         | Maximum double — instant game win        |
| Qaid                | قيد          | Violation / illegal move                 |
| Open Play           | لعب مفتوح    | Can lead with trump (Double active)      |
| Closed Play         | لعب مغلق     | Cannot lead with trump (Double active)   |

---

## 13. All Rules Confirmed ✅

All previously open questions have been resolved from client meeting video recordings:

| # | Question | Final Answer | Evidence |
|---|---|---|---|
| 1 | Project Declaration | **Manual UI button** (Baloot is auto only) | video 13-51-23.mp4 @ 01:16 |
| 2 | Double Timing | **Before first card is played** | video 13-51-23.mp4 @ 02:04 |
| 3 | Sawa Mechanic | **Ends bidding, locks current bid** | video 14-00-32.mp4 @ 00:54 |
| 4 | Hakam Rounding .5 | **Jawaker style — .5 rounds DOWN** (15.5 → 15, 15.6 → 16) | Jawaker official rules |
| 5 | Game End Target | **152 scoreboard points OR Gahwa** | video 13-23-47.mp4 @ 03:09 |

---

## 14. Kammelna Edge-Cases (Phase 2 Programming Logic)

To ensure the game engine handles edge cases identically to professional GCC tournament standards (matching **Kammelna**), the following strict rules must be programmed:

### 14.1 Project Tie-Breakers & Overlaps
- **Rank Ties:** If both teams hold a sequence project of equal rank (e.g., both hold A-K-Q), the Hakam/Trump sequence wins when one side holds trump-backed sequence and ordering rules dictate. After rank → high card → trump-split steps, **if still tied** → **project Sawa**: neither team earns sequence-project points (**no turn-order tiebreak**, matching Kammelna).
- **Overlaps:** A single card **cannot** be double-dipped into two sequence projects. The engine must only permit declaring the highest valid sequence. Cards in a sequence, however, **can** be reused to declare a "Baloot" pair.

### 14.2 The "Empty Bidding" Loop
- If all four players Pass during Round 1, and again all four Pass during Round 2, the current distribution is scrapped. **No points are awarded**, and the Dealer role permanently passes to the right for a completely fresh hand.

### 14.3 Game-End Exact Ties
- The game triggers the end phase when a team crosses 152 points.
- If both teams cross 152 points in the same round, the team with the higher score wins (e.g., 158 over 154).
- If the final score is an **exact tie (e.g., 154-154)**, there are no draws. The game is extended to a **Sudden-Death Tie-Breaker Round**.

### 14.4 Khams (Sweep) Project Stealing
- If a Buyer declares projects but still suffers a Khams loss, the Defending Team is awarded the Khams base points (26/16) **AND steals the Buyer's project points**.
- *Exception:* The "Baloot" (K+Q) declaration points cannot be stolen.

### 14.5 Qaid (Violation) Penalties
- Kammelna allows manual Qaid ("Flag") UI clicking.
- Committing a genuine Qaid instantly loses the round. The opposing (winning) team is awarded the **Kabout score (44 Sun / 25 Hakam)** + their active project points.
- If a player falsely claims a Qaid, the *accuser* loses the round and suffers the exact same Kabout score penalty.

### 14.6 Defensive Kabout
- If the Defending team successfully wins all 8 tricks, it overrides the standard Khams. They are awarded the massive base **Kabout points (44 Sun / 25 Hakam)** instead of the usual 26/16 sweep points.

---
*Document Version: 4.0 — FINAL (Kammelna Integration)*
*Sources: Kammelna Edge-Cases + Jawaker Official Rules + Client (Visca ME) + Meeting Videos (April 2026)*
*Status: ✅ COMPLETE — Ready for Phase 2.1 Engine Implementation*
