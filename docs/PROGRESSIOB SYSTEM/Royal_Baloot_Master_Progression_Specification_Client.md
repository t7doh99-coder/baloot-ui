# ROYAL BALOOT — COMPLETE PROGRESSION, RANKING & ECONOMY SPECIFICATION

**Document Version:** 2.0 (Client Master Document)  
**Project:** Royal Baloot  
**Target Client:** Visca ME (Mohamed)  
**Author:** Abdul Sami  
**Date:** October 2026  

---

## EXECUTIVE SUMMARY & CORE DESIGN PHILOSOPHY

This specification provides the complete roadmap for Royal Baloot's Progression, Ranking, and Economy Systems. The architecture is engineered around one foundational rule: **Competitive skill alone determines player rank.** Gameplay luck (such as dealt card hands) and time investment are decoupled from Rating Points (RP) and rewarded through a parallel **XP and Golden Cards (GC)** economy. This guarantees total competitive integrity, eliminates player hesitation, and maximizes daily retention and monetization.

---

## SECTION 1: Regional Benchmark Comparison (Kammelna vs. Royal Baloot)

To ensure immediate familiarity for experienced GCC Baloot players while resolving known pain points in existing titles, Royal Baloot directly refines the market benchmark (*Kammelna*):

| Domain | Kammelna Benchmark | Royal Baloot Specification | Strategic Value |
| :--- | :--- | :--- | :--- |
| **Rank Structure** | 6 ranks, 5 sub-levels each (30 total levels) | **6 ranks, 3 sub-levels each (18 total levels)** | Cleaner UX, faster perceived milestones, reduced progression fatigue. |
| **Pinnacle Tier** | نابغة (Prodigy) | **أمير 👑 (Amir)** | Distinct Royal Baloot prestige branding; aspirational royalty status. |
| **RP Calculation** | Volatile individual swings | **2v2 Team-Average Elo Delta (±20 Base)** | Eliminates partner disparity; mathematically balanced for 2v2 play. |
| **In-Game Bonuses** | Direct point injections | **Decoupled to XP & Golden Cards (Zero RP)** | Card deal luck never inflates rank; protects pure skill integrity. |
| **Cup Arena** | 2 tickets/day for VIP, open farming | **Ticket-gated + Hard 4/day cap + 100 RP cap** | Prevents whales from spamming matches and buying top rank spots. |
| **Promotion Gates** | Linear rollover point threshold | **Best-of-3 Promotion Series (100% Free)** | Creates high-stakes, broadcast-worthy milestone matches. |
| **Private Leagues** | VIP room creation only | **VIP Host + GC Prize Pool + 10% Platform Rake** | Generates organic, passive platform revenue from player rivalries. |
| **Subscription Value** | 34.99 SAR / month | **24.99 SAR / month (29% below Kammelna)** | Lowers entry friction; captures aggressive market conversion. |

---

## SECTION 2: 2v2 Match Rating Points (RP) Engine

Rating Points (RP) measure genuine competitive skill and opponent strength. In Baloot's cooperative 2v2 gameplay, calculating individual ratings creates unfair partner disparity. Royal Baloot calculates rating movements using the **Team Average Method**: both teammates on the same team always receive the **exact same RP adjustment**.

```
Team A Average RP = (Player 1 RP + Player 2 RP) / 2
Team B Average RP = (Player 3 RP + Player 4 RP) / 2
Tier Gap = Opponent Team Tier Index - My Team Tier Index   [Clamped: -3 to +3]
```

### Base RP Matrix (Standard Ranked Play)

| Match Context | Team Tier Differential | RP on Victory | RP on Defeat |
| :--- | :---: | :---: | :---: |
| **Even Match** | Equal Level (Gap = 0) | **+20 RP (Base)** | **-20 RP (Base)** |
| **Underdog Win / Favorite Loss** | Opponents 1 Tier Higher (+1) | **+24 RP** | **-24 RP** |
| **Significant Underdog** | Opponents 2 Tiers Higher (+2) | **+28 RP** | **-28 RP** |
| **Maximum Upset** | Opponents 3+ Tiers Higher (+3) | **+32 RP (Max Win)** | **-32 RP (Max Loss)** |

### Form Adjustments, Bots & Edge Cases
* **Win Streak Form Factor:** 3–4 consecutive wins grant a **+2 RP** bonus; 5+ consecutive wins grant a **+4 RP** bonus. This is strictly capped at +4 RP to prevent rating inflation through lucky streaks.
* **Bot Matches:** Bots are benchmarked at Tier 0 (مبتدئ). Defeating a bot team yields a flat **+5 RP**; losing to bots inflicts **0 RP loss**.
* **Match Disconnections:** The player who disconnects suffers the full match loss penalty (-20 to -32 RP). Their innocent partner incurs only **half penalty (-50%)**. Opponents receive the full win credit.

---

## SECTION 3: Decoupling Pure Skill (RP) from In-Game Feats

To preserve competitive integrity, in-game gameplay feats and daily missions are decoupled from RP and routed into **XP and Golden Cards (GC)**.

> **Why This Is Critical:** If dealt lucky trump cards (such as the King and Queen of trump for a Baloot declaration or high cards for a Kabout sweep), a player should not gain rating points over superior opponents. Conversely, penalizing players with RP for using Qaid or Sawa creates anxiety and ruins gameplay flow.

| Action / Feat | Previous Draft | Updated Production System | Design Rationale |
| :--- | :---: | :---: | :--- |
| **Kabout (كبوت)** | +4 RP / -4 RP | **+40 XP + 5 Golden Cards** | Card-luck dependent; dealt trump hands must not distort rank. |
| **Baloot Call (بلوت)** | +1 RP | **+15 XP + 2 Golden Cards** | Dealt hand luck (K+Q of trump); not a tactical decision. |
| **Sawa Win (سوا)** | +2 RP | **+25 XP + 3 Golden Cards** | Encourages confident Sawa usage without fear of rank penalties. |
| **Qaid Confirmed (قيد)** | +2 RP | **+20 XP + 2 Golden Cards** | Removes player hesitation; keeps Qaid as a pure tactical tool. |
| **Daily Missions (6 Daily)** | Up to +25 RP each | **XP + Golden Cards only (Zero RP)** | Missions are engagement tools; grinders must not outrank skilled players. |
| **First Win of the Day** | +3 RP | **+100 XP only** | Habit reward; not a reflection of competitive mastery. |

---

## SECTION 4: Rank Tiers & Best-of-3 Promotion Series

Royal Baloot features 6 primary ranks, divided into 3 sub-levels (I, II, III). To transition between main ranks, players participate in a high-stakes **Best-of-3 Promotion Series**.

| Tier # | Arabic Name | English Name | Required RP Range | Sub-Level I | Sub-Level II | Sub-Level III (Promo Zone) | Expected % |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **1** | **مبتدئ** | Beginner | 0 – 299 RP | 0 – 99 | 100 – 199 | 200 – 299 | ~35% |
| **2** | **متوسط** | Intermediate | 300 – 899 RP | 300 – 499 | 500 – 699 | 700 – 899 | ~28% |
| **3** | **متقدم** | Advanced | 900 – 1,799 RP | 900 – 1,199 | 1,200 – 1,499 | 1,500 – 1,799 | ~18% |
| **4** | **محترف** | Professional | 1,800 – 3,299 RP | 1,800 – 2,299 | 2,300 – 2,799 | 2,800 – 3,299 | ~12% |
| **5** | **خبير** | Expert | 3,300 – 5,999 RP | 3,300 – 4,299 | 4,300 – 5,299 | 5,300 – 5,999 | ~5% |
| **6** | **أمير 👑** | Amir | 6,000+ RP | 6,000 – 6,999 | 7,000 – 7,999 | 8,000+ *(Top 500 Hall)* | <2% |

### Best-of-3 (BO3) Promotion Series Rules
* **Automatic Gate:** Triggers immediately upon filling Sub-Level III. **100% Free** (never ticket-gated).
* **Frozen RP:** RP movement is frozen during the series. Win and loss tokens are tracked (first to 2 wins promotes; 2 losses fails).
* **Success Outcome:** Instant promotion to Sub-Level I of the next tier at 0 RP + Grand Chest awarded.
* **Failure Outcome:** The player remains in their current tier, dropping back to **70% of Sub-Level III** (requiring 2–3 standard wins to earn another attempt).

---

## SECTION 5: Daily Missions & Engagement Rewards

To incentivize daily active logins without compromising ladder integrity, players receive 6 daily missions that reset at midnight (00:00 UTC). All rewards are granted in **XP and Golden Cards (GC)**, ensuring grinders do not distort the competitive RP ladder:

| Mission Name (Arabic) | Requirement | Updated Production Reward |
| :--- | :--- | :---: |
| **3× تسلسل** | Win 3 ranked games in a row | **+100 XP + 15 Golden Cards** |
| **كبوت!** | Win a round by Kabout | **+80 XP + 12 Golden Cards** |
| **اربح مرتين** | Win 2 ranked games | **+50 XP + 8 Golden Cards** |
| **فز بالحكم** | Win any ranked game in Hakam mode | **+40 XP + 5 Golden Cards** |
| **إبلوت!** | Declare Baloot in a ranked match | **+30 XP + 5 Golden Cards** |
| **العب جولة واحدة** | Play 1 ranked game (win or lose) | **+20 XP + 2 Golden Cards** |

---

## SECTION 6: Royal Cup — Premium Ticket-Gated Arena

The Royal Cup operates parallel to standard ranked play as an elevated arena with 75% higher RP stakes (±35 RP), hard anti-farming restrictions, and Cup Season Points (CSP).

| Feature | Standard Ranked Play | Royal Cup Arena | Anti-Farming Protection |
| :--- | :--- | :--- | :--- |
| **Entry Cost** | Free (Hearts gated) | **1 Cup Ticket** | VIPs receive 2/day; extra tickets 100 GC. |
| **Daily Entries** | Unlimited | **Max 4 entries per day** | Server-enforced hard cap prevents spamming. |
| **Base RP Stakes** | ±20 RP Base | **±35 RP Base (75% higher)** | Elevated risk and reward. |
| **Daily RP Gain Cap** | Unlimited | **Max +100 RP gain / day** | Gains halt at +100; losses continue to apply. |
| **Rank Eligibility** | All Ranks (0+ RP) | **متوسط I (300 RP) Minimum** | Protects competitive arena integrity. |
| **Bots Allowed** | Yes (low tiers) | **Strictly Real Players (0 Bots)** | 100% genuine peer competition. |
| **Seasonal Reward** | Standard Chest + XP | **Cup Season Points (CSP)** | Dedicated seasonal Hall of Fame leaderboard. |

---

## SECTION 7: Leagues, Private Tournaments & 10% Platform Rake

### 7.1 Player-Created Leagues (Community-Funded)
* **Hosting Requirements:** Active Subscription + Minimum 500 Golden Cards (GC) prize pool deposit.
* **Custom Brackets:** 4, 8, 16, or 32 players; Single Elimination, Double Elimination, or Swiss formats.
* **Custom Entry Buy-Ins:** 0 to 200 GC per player.
* **10% Platform Rake:** The platform automatically retains **10% of every league prize pool** as passive revenue. (e.g. A 16-player league with 500 GC buy-in generates an 8,000 GC pool. Winners split 7,200 GC; Royal Baloot retains 800 GC).

### 7.2 Official Royal Baloot Tournaments (Admin-Created)
* Managed directly via the Web Admin Dashboard.
* Configurable rank eligibility bands (e.g. *محترف to أمير only*) to ensure competitive balance.
* Weekly standard cups, monthly grand invitationals, and national holiday specials.
* Prizes include massive GC pools, animated card backs, unique avatar frames, and permanent Hall of Fame honors.

---

## SECTION 8: Retention Systems: Seasons, Decay & Chest Milestones

* **90-Day Seasons:** Quarterly seasons featuring a soft reset (20% RP reduction across all players).
* **Inactivity Decay:** Accounts inactive for 14 consecutive days lose **5 RP per day**. This prevents leaderboard parking and drives weekly activity.
* **Chest Cadence:** Wood Chest awarded every game; Silver Chest every 5 games; Gold Chest every 15 games; Grand Chest upon main tier promotion.
* **Permanent Lifetime Wins:** A permanent 'Total Wins' counter is publicly showcased on player profiles, unlocking exclusive milestone badges and prestige cosmetics.

---

## SECTION 9: Macro Economy & Subscription Benchmarking

### Subscription Benchmarking vs. Market Leader (Kammelna)

| Billing Cycle | Royal Baloot (SAR) | Royal Baloot (USD) | Kammelna (SAR) | Price Advantage |
| :--- | :---: | :---: | :---: | :---: |
| **Weekly (أسبوعي)** | **9.99 SAR** | ~$2.99 | 12.99 SAR | **23% Cheaper** |
| **Monthly (شهري)** | **24.99 SAR** | ~$6.99 | 34.99 SAR | **29% Cheaper** |
| **Quarterly (3 أشهر)** | **64.99 SAR** | ~$17.99 | ~95.00 SAR | **32% Cheaper** |
| **Annual (سنوي)** | **199.99 SAR** | ~$54.99 | 289.99 SAR | **31% Cheaper** |

### Golden Cards (GC) Sinks and Circulation
* **Earn Channels:** In-game feats (Kabout +5 GC, Sawa +3 GC, Baloot +2 GC, Qaid +2 GC), daily/weekly missions (10–50 GC), seasonal tier finishes (up to 500 GC), and tournament placements.
* **Primary Sinks:** Extra Cup tickets (100 GC), tournament host deposits (500+ GC), animated card backs (1,200 GC), custom tables (800 GC), animated frames (500 GC), and social gifts (50–2,000 GC).

---

## SECTION 10: Evolution Matrix (Comparison with Previous 3-Page Draft)

| System Area | Previous 3-Page Draft | Finalized Production System | Strategic Rationale |
| :--- | :--- | :--- | :--- |
| **Top Rank Name** | نابغة (Prodigy) | **أمير 👑 (Amir)** | Builds an iconic identity fitting the Royal Baloot brand. |
| **Kabout / Baloot** | +4 RP / +1 RP | **Award XP & Golden Cards (Zero RP)** | Card deal luck must never influence competitive ranking. |
| **Qaid / Sawa** | +2 RP each | **Award XP & Golden Cards (Zero RP)** | Eliminates player hesitation; preserves tactical gameplay flow. |
| **Daily Missions** | Up to +25 RP each | **Award XP & Golden Cards (Zero RP)** | Grinders cannot bypass genuine skill through playtime volume. |
| **First Win of Day** | +3 RP | **+100 XP only** | Habit driver; decoupled from competitive standings. |
| **Win Streak Bonus** | Up to +8 RP | **Capped at max +4 RP** | Suppresses runaway rating inflation. |
| **Elo Base** | Individual Player Elo | **2v2 Team Average Formula** | Balanced, mathematically fair partner rating changes. |
| **Royal Cup** | Not integrated | **Ticket-Gated Arena (+35/-35 RP, Caps)** | Anchors subscription utility and high-stakes prestige. |
| **Leagues & Rake** | Not integrated | **10% Platform Rake on GC Pools** | Creates passive, sustainable platform revenue. |

---
