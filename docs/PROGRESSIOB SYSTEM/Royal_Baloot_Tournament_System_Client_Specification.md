# Royal Baloot — Tournament System Architecture & Implementation Guide

**Document Version:** 2.0 (Executive Client Technical Specification)  
**Project:** Royal Baloot  
**Target Client:** Visca ME (Mohamed)  
**Author:** Abdul Sami  
**Date:** October 2026  

---

## Executive Summary & Four Core Architectural Principles

This technical specification details the complete tournament architecture for **Royal Baloot**, directly addressing the client's directive for a marquee competitive environment without compromising fair play or tilting into pay-to-win.

### The Four Pillars
1. **Skill Decides Outcomes, Not Spend:** Golden Cards and VIP subscriptions grant entry access, tournament hosting rights, and cosmetic elevation — never card probability advantages or in-match bonuses.
2. **100% Admin-Configurable:** Formats, eligibility, recurrence, buy-ins, and prize pools are form fields in the Admin Dashboard, not hardcoded into software builds.
3. **Tight Ranking Coupling:** Tournaments inherit eligibility from the ranking engine. Using rank bands rather than single floors ensures competitive parity across all skill tiers.
4. **Auditable Economy Ledger:** All buy-ins and prize payouts move through an append-only transaction ledger, preventing currency manipulation and facilitating dispute audits.

---

## PART 1: Tournament Types & Competitive Formats

| Tournament Type | Cadence | Competitive Format | Strategic Purpose |
| :--- | :--- | :--- | :--- |
| **Scheduled Ladder Events** | Daily & Weekly (Auto-recurring) | Points Ladder (cumulative points) | Low-friction daily engagement; continuous leaderboard climbing. |
| **Official Royal Cup** | Monthly / Seasonal Marquee | Single or Double Elimination Bracket | High-stakes flagship competition; the aspirational milestone event. |
| **Seasonal Leagues** | Multi-week window | Swiss or Ladder Points Accumulation | Long-term retention anchor bridging flagship Royal Cup tournaments. |
| **VIP / Exclusive Invitationals** | Admin-scheduled specials | Round Robin or Swiss Bracket | Subscription value perk; high prestige, custom broadcast events. |

### Formats & Team Pairing Mechanics
* **Points Ladder:** Teams accumulate points across ranked matches within a set timeframe.
* **Single Elimination Bracket:** High-tension knockout; one defeat eliminates the team.
* **Double Elimination Bracket:** Winner and Loser brackets; gives teams a second chance to recover from an unlucky hand.
* **Swiss System:** Pairs teams with identical win/loss records each round without early eliminations.
* **Pairing Methods:** Supports **Pre-formed Teams** (entering with an invited partner) and **Solo Queue** (automated pairing with another solo entrant of matching rank at registration close).

---

## PART 2: Core Data Model & Admin Tournament Builder

### Data Schema
* **Tournament:** `id`, `name`, `description`, `banner_url`, `type`, `format`, `eligibility_rule_id`, `entry_fee_type`, `entry_fee_gc`, `max_teams`, `reg_opens_at`, `reg_closes_at`, `starts_at`, `ends_at`, `recurrence_rule`, `prize_tier_id`, `visibility`, `status`
* **TeamEntry / Participant:** `id`, `tournament_id`, `player_1_id`, `player_2_id`, `registered_at`, `current_tier_at_entry`, `seed_number`, `status` (registered | active | eliminated | disqualified)
* **Round / Match:** `id`, `tournament_id`, `round_number`, `team_a_id`, `team_b_id`, `game_session_id`, `score_a`, `score_b`, `winner_team_id`, `completed_at`
* **Standing:** `tournament_id`, `team_id`, `points`, `wins`, `losses`, `ladder_rank`
* **PrizeTier:** `id`, `tournament_id`, `rank_range` (1st, 2nd-3rd, 4th-8th), `reward_type` (GC | Badge | Title | SubDays), `reward_amount`
* **EligibilityRule:** `min_tier`, `max_tier`, `min_games_played`, `subscription_required` (bool)

### Admin Tournament Builder (Required Form Fields)
* **Metadata:** Event Name, Description, Promotional Banner Image, Display Priority.
* **Format Selector:** Points Ladder, Single Elimination, Double Elimination, Swiss.
* **Eligibility Rules:** Rank Tier Band (e.g. *متوسط I to متقدم III*), Minimum Lifetime Games, VIP Only toggle.
* **Schedule:** Registration Window (Open/Close), Kick-off Time, Completion Target, Recurrence Cron.
* **Entry & Prizes:** Entry Fee (Free / Fixed GC / Subscription-Gated), Tiered Prize Payout distribution.
* **Capacity & Visibility:** Maximum Teams (4, 8, 16, 32, 64, 128), Public vs. VIP-Only listing.

---

## PART 3: Tournament Lifecycle State Machine

```
Draft → Scheduled → Registration Open → Registration Closed → Live → Completed → Prizes Distributed → Archived
```

| Lifecycle Transition | Trigger Mechanism | System Action & Field Freezing |
| :--- | :--- | :--- |
| **Draft → Scheduled** | Admin clicks "Publish" | Event appears on public/VIP tournament calendar. Format and prize fields freeze permanently. |
| **Scheduled → Registration Open** | Cron at `reg_opens_at` | Players can register, form teams, and deposit entry fees into escrow ledger. |
| **Registration Open → Closed** | Cron at `reg_closes_at` OR Capacity full | Rosters freeze. Solo entrants are paired by rank. Brackets / matchups are generated. |
| **Registration Closed → Live** | Cron at `starts_at` | First round matches spawn. Deep-link push notifications dispatched to all participants. |
| **Live → Completed** | Final match resolves OR `ends_at` | Final standings calculated. Results flagged for dispute check if necessary. |
| **Completed → Prizes Distributed** | Automated OR Admin Release | Golden Cards credited via ledger. Exclusive cosmetic trophies and titles pinned to profiles. |
| **Prizes Distributed → Archived** | System maintenance cron | Standings preserved for historical record; removed from active tournament lobby. |

---

## PART 4: Eligibility & Rank Band Integration

* **Rank Band Principle:** By setting bands such as "Tier 2–3 (متوسط to متقدم)" for mid-tier ladders and "Tier 5–6 (خبير to أمير)" for masters invitationals, multiple balanced tournaments run concurrently without locking out 90% of the active player base.
* **Anti-Smurf Protections:** Tournaments enforce a `min_games_played` threshold (e.g., minimum 25 ranked matches) to prevent brand-new accounts from entering low-tier events to snipe prizes.
* **Pool Size Validation Tooling:** The Admin Builder displays live data showing exactly how many active registered players qualify under the chosen rank band before the admin publishes the event.

---

## PART 5: Economy Integration & Auditable Golden Card Ledger

### Entry Fee Models
1. **Model 1: Free Entry, Admin-Funded Prizes (Lowest Risk):** Recommended for MVP and daily retention ladders. Drives participation with zero financial barrier.
2. **Model 2: Fixed GC Entry, Hybrid Funded Prizes (Balanced):** Core model for weekly tournaments and the Royal Cup. Players spend earned or purchased GC; prize pools are subsidized by the platform.
3. **Model 3: Player-Funded Wagered Pools (10% Rake):** Used in player-created leagues. 90% of collected buy-ins form the prize pool; Royal Baloot retains 10% as passive revenue.

### Append-Only Ledger Architecture
Direct database balance adjustments are strictly forbidden. All entry deductions, escrow holds, rake deductions, and prize payouts append immutable records to the `golden_card_ledger` with timestamps, tournament IDs, and match session references.

---

## PART 6: VIP Subscription Integration (Zero Pay-to-Win)

| Subscriber Privilege | Description | Fair Play Guarantee |
| :--- | :--- | :--- |
| **Early Bird Registration** | 24-hour priority window before high-demand tournaments open to free players. | Zero gameplay advantage; early seat reservation only. |
| **VIP-Exclusive Events** | Entry to subscriber-only invitationals with unique cosmetic trophies. | Operates in a separate pool; does not skew open tournaments. |
| **Waived / Discounted Buy-Ins** | Free entry tokens or 50% discount on select Golden Card tournament fees. | Economic convenience perk; zero impact on match mechanics. |
| **Prestige Cosmetics** | Exclusive animated tournament avatar frames, badges, and table felts. | 100% cosmetic vanity; card odds remain untouched. |

---

## PART 7: Anti-Cheat, Collusion Detection & Fair Play

Because Baloot is a partner-driven game, tournaments are uniquely vulnerable to partner collusion and result manipulation. Royal Baloot establishes industry-standard defenses:

* **Server-Authoritative RNG:** Shuffling and card dealing occur strictly server-side using cryptographically secure random number generation. The client never knows hidden cards until they are legitimately played.
* **Collusion Detection Flags:** Algorithms flag suspicious patterns, such as opposing accounts repeatedly entering the same bracket, abnormally passive bidding/folding, or intentional trick throws.
* **Device & IP Multi-Accounting Checks:** Prevents one individual from entering multiple accounts into the same bracket using hardware ID and IP tracking.
* **Tournament Disconnect Rules:** Strict 60-second reconnect grace window. If a player fails to reconnect, their team forfeits the match, preventing stall tactics.
* **Full State Match Replays:** Complete logs of all dealt cards, bids, plays, and timestamps are recorded for every tournament match, allowing admins to reconstruct disputed hands in seconds.

---

## PART 8: Backend Architecture & Admin Dashboard Screens

### Service Architecture
* **Tournament Service:** Handles CRUD operations and drives the lifecycle state machine.
* **Matchmaking & Bracket Service:** Manages team formation, seeds, brackets, and Swiss pairing logic.
* **Standings Service:** Computes live ladder points and tiebreakers.
* **Prize Distribution Service:** Automates payouts and writes directly to the Golden Card ledger.
* **Notification Service:** Dispatches deep-linked push notifications for registration, match starts, and prize delivery.

### Admin Panel Screens
1. **Tournament Management Dashboard:** Master table of all events filterable by state (Draft, Scheduled, Live, Completed).
2. **Tournament Builder Form:** Complete visual configuration tool for creating and scheduling events.
3. **Live Tournament Monitor:** Real-time bracket visualization with flagged match alerts and manual referee override tools.
4. **Prize Payout Confirmation:** Pre-release approval screen with options to hold payouts on disputed matches.
5. **Golden Card Audit Ledger:** Searchable transaction history tracking all tournament-related currency flows.

---

## PART 9: Recommended Phased Implementation Roadmap

| Phase | Scope & Deliverables | Key Technical Features | Strategic Outcome |
| :--- | :--- | :--- | :--- |
| **MVP Phase** | Scheduled Points-Ladder Events | Server-authoritative deal, basic rank band eligibility, admin builder, admin-funded GC prizes. | Rapid deployment; zero bracket complexity; immediate retention boost. |
| **Phase 2** | Brackets & Royal Cup Flagship | Single/Double Elimination brackets, Swiss pairings, solo-queue pairing, VIP tournament integration. | Launches marquee esports competition; drives subscriptions. |
| **Phase 3** | Advanced Integrity & Auto-Recurrence | Automated collusion detection flags, full ledger auditing screens, cron auto-scheduling, match replay viewer. | Enterprise-grade scalability, hands-off automation, fraud protection. |
