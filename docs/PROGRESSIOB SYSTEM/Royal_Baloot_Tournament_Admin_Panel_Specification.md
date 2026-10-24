# ROYAL BALOOT — TOURNAMENT ADMIN PANEL SPECIFICATION & BLUEPRINT

**Document Version:** 1.0 (Production Master)  
**Project:** Royal Baloot  
**Target Client:** Visca ME (Mohamed)  
**Author:** Abdul Sami  
**Date:** October 2026  

---

## Executive Overview

This specification defines the complete web-based **Tournament Admin Panel** for Royal Baloot. Engineered directly to fulfill Mohamed's directive, this dashboard gives platform administrators 100% operational autonomy to create, schedule, monitor, referee, and settle official tournaments and leagues without requiring code modifications or developer deployment cycles.

---

## PART 1: Core Architectural Principles of the Admin Panel

1. **Form-Driven Zero-Code Operation:** Every tournament parameter (format, rank band, buy-in, capacity, schedule cron, and prize structure) is configured through visual forms.
2. **Real-Time Operations & Live Refereeing:** Live bracket progression, match state inspection, and manual dispute resolution occur in real time using WebSocket feeds.
3. **Financial Safety & Ledger Auditing:** Every prize release moves through a mandatory confirmation workflow backed by an immutable Golden Card transaction ledger.
4. **Role-Based Access Control (RBAC):** Granular permissions separate Super Admins, Tournament Directors, Match Referees, and Financial Auditors.

---

## PART 2: Screen 1 — Master Tournament Dashboard

The central hub displaying high-level performance metrics, status counters, and the complete tournament inventory.

```text
+----------------------------------------------------------------------------------------------------+
| ROYAL BALOOT ADMIN • TOURNAMENT DASHBOARD                                  [Admin: Mohamed ▾]      |
+----------------------------------------------------------------------------------------------------+
| [ACTIVE TOURNAMENTS: 4]  [REGISTRATION OPEN: 3]  [COMPLETED TODAY: 12]  [ESCROW POOL: 45,000 GC]    |
+----------------------------------------------------------------------------------------------------+
| Filters: [All Statuses ▾] [All Formats ▾] [Rank Bands ▾]  [Search by Name...]  [+ CREATE TOURNAMENT]|
+----------------------------------------------------------------------------------------------------+
| ID    | NAME                 | FORMAT       | RANK BAND      | ENTRY FEE | TEAMS  | STATUS      | ACTIONS     |
| #1042 | Weekly Masters Cup   | Single Elim  | خبير – أمير     | 200 GC    | 32/32  | LIVE (R3)   | [Monitor]   |
| #1043 | Daily Ladder #18     | Points Ladder| متوسط – متقدم   | FREE      | 142/200| REG OPEN    | [Edit] [X]  |
| #1044 | Friday Royal Grand   | Double Elim  | Open (All)     | 500 GC    | 64/64  | SCHEDULED   | [View] [X]  |
| #1041 | VIP Invitational     | Swiss (4 Rnd)| محترف+ (Sub)   | FREE (VIP)| 16/16  | COMPLETED   | [Payouts]   |
+----------------------------------------------------------------------------------------------------+
```

### Dashboard Elements & Controls:
* **Top KPI Counters:** Live events counter, open registrations, 24h completion volume, and total Golden Cards currently locked in escrow.
* **Status Filter Tabs:** All, Draft, Scheduled, Registration Open, Live, Completed, Archived.
* **Direct Action Bar:** Primary *"+ Create Tournament"* button, CSV export of historical records, and global search.
* **Row-Level Action Buttons:** Context-sensitive controls based on state (e.g. *[Monitor]* for Live, *[Edit]* for Draft/Scheduled, *[Payouts]* for Completed).

---

## PART 3: Screen 2 — Tournament Builder & Scheduling Wizard

A multi-step configuration wizard allowing administrators to launch tournaments within 60 seconds.

```text
+----------------------------------------------------------------------------------------------------+
| CREATE NEW TOURNAMENT • 5-STEP WIZARD                                                              |
| [1. Basic Info] → [2. Format & Rules] → [3. Eligibility] → [4. Schedule] → [5. Prizes & Fees]      |
+----------------------------------------------------------------------------------------------------+
| STEP 1: BASIC INFO & BRANDING                                                                      |
| Tournament Name:      [ Royal Friday Grand Cup 2026                             ]                  |
| Tournament Subtitle:  [ Compete for 10,000 Golden Cards and the Amir Prestige Badge    ]                  |
| Event Banner:         [ Upload Graphic (1200x400 PNG/JPG) ] → [royal_cup_banner.png]               |
| Visibility:           (•) Public (Visible to all)   ( ) VIP Only (Subscribers only)                 |
| Event Category:       (•) Official Admin Cup   ( ) Community League   ( ) Seasonal Series          |
+----------------------------------------------------------------------------------------------------+
| STEP 2: FORMAT & COMPETITIVE RULES                                                                 |
| Tournament Format:    (•) Single Elimination   ( ) Double Elimination   ( ) Swiss   ( ) Points Ladder|
| Max Team Capacity:    [ 32 Teams (64 Players) ▾]                                                   |
| Team Formation:       (•) Pre-formed Pairs Only  ( ) Solo Queue Auto-Pair  ( ) Both Allowed        |
| Match Gameplay Mode:  (•) Standard Baloot    ( ) Advanced Baloot (Qaid & Sawa Enabled)              |
| Turn Speed:           [ Normal (15s) ▾]  Match Length: [ Standard 4 Rounds ▾]                        |
+----------------------------------------------------------------------------------------------------+
| STEP 3: ELIGIBILITY & ANTI-SMURF GATES                                                             |
| Rank Band Minimum:    [ متوسط I (300 RP) ▾]     Rank Band Maximum: [ أمير 👑 (8000+ RP) ▾]         |
| Min Account Games:    [ 25 Ranked Games Played ]  (Anti-Smurf Gate)                                |
| Subscription Gate:    [ ] Require Active VIP Subscription for Entry                                |
| Real-Time Qualified Player Pool: 14,820 Active Accounts match these criteria ✓                      |
+----------------------------------------------------------------------------------------------------+
| STEP 4: SCHEDULE & RECURRENCE ENGINE                                                               |
| Registration Window:  Opens: [2026-10-10 12:00 UTC] → Closes: [2026-10-10 17:30 UTC]                |
| Tournament Kick-Off:  Starts: [2026-10-10 18:00 UTC] → Target End: [2026-10-10 22:00 UTC]         |
| Auto-Recurrence:      (•) One-Off Event   ( ) Daily Recurring   ( ) Weekly on Fridays (Cron)        |
+----------------------------------------------------------------------------------------------------+
| STEP 5: ENTRY FEES & TIERED PRIZE POOL                                                             |
| Entry Fee Model:      ( ) Free Entry (Admin Funded)  (•) Fixed GC Buy-in: [ 100 GC ]               |
| Guaranteed Platform Prize Subsidy: [ 5,000 GC ]                                                    |
| Total Projected Prize Pool: 8,200 GC (5,000 Platform + 3,200 Buy-ins)                              |
| Tier 1 (Champion):    [ 50% ] = 4,100 GC  + [ Amir Crown Animated Badge ▾] + [ 30 Days VIP ]       |
| Tier 2 (Runner-Up):   [ 25% ] = 2,050 GC  + [ Silver Finalist Card Back ▾]                         |
| Tier 3 (3rd - 4th):   [ 12.5% each ] = 1,025 GC                                                    |
+----------------------------------------------------------------------------------------------------+
| [Save Draft]                                                      [PREVIEW & PUBLISH TOURNAMENT →] |
+----------------------------------------------------------------------------------------------------+
```

### Key Form Validations & Safety Rules:
* **Instant Pool Validation:** The wizard checks player database records in real time to show how many active users qualify for the selected rank band, preventing unfillable tournaments.
* **Field Locking upon Publishing:** Formats, buy-ins, and prize distribution permanently lock when published to ensure platform trust.
* **Escrow Pre-Check:** If the tournament includes an admin-funded Golden Card subsidy, the system verifies sufficient administrative balance before allowing publication.

---

## PART 4: Screen 3 — Live Tournament Operations & Referee Monitor

The mission-control screen used by admins and match referees to supervise ongoing tournaments in real time.

```text
+----------------------------------------------------------------------------------------------------+
| LIVE TOURNAMENT MONITOR • WEEKLY MASTERS CUP (#1042) • ROUND 3 / QUARTER-FINALS                    |
| [Status: LIVE]  [Active Matches: 4]  [Matches Resolved: 28/32]  [Dispute Alerts: 1 Δ]                |
+----------------------------------------------------------------------------------------------------+
| INTERACTIVE TOURNAMENT BRACKET (ZOOM: 100%)                                                       |
|                                                                                                    |
| [R16: Team Falcon 152] —+                                                                          |
| [R16: Team Riyadh 98 ]  |---> [QF1: Team Falcon  42] • IN PROGRESS (T2)                             |
|                               [QF1: Team Najd    38] • [Spectate Match] [Logs]                       |
| [R16: Team Najd   160] —+                                                                          |
|                                                                                                    |
| [R16: Team Shamal 155] —+                                                                          |
| [R16: Team Dammam  82]  |---> [QF2: Team Shamal  --] • DISPUTE FLAGGED Δ                         |
|                               [QF2: Team Hijaz   --] • [INVESTIGATE & RESOLVE] [Match Replay]      |
| [R16: Team Hijaz  154] —+                                                                          |
+----------------------------------------------------------------------------------------------------+
| REFEREE DISPUTE RESOLUTION QUEUE                                                                   |
| Flagged Match: QF2 (Team Shamal vs. Team Hijaz) • Trigger: Partner Disconnect Timeout (60s)        |
| Player Offline: Hijaz_Player2 (Disconnected during Round 2, Trick 3)                              |
| Automated Action: Grace period expired → Team Shamal lead 74 to 28                                 |
| Referee Override Actions: [Confirm Forfeit Victory to Shamal]  [Grant 3-Min Reconnect]  [Restart Game] |
+----------------------------------------------------------------------------------------------------+
```

### Live Operations Capabilities:
* **Live Spectator Feed:** Admins can click *[Spectate Match]* to view any table without lag or revealing cards to other players.
* **Instant Hand Replay:** Full inspection of bids, cards played, tricks taken, and timestamps to evaluate claims of collusion or rule violations.
* **Referee Overrides:** Manual referee controls to forfeit match outcomes, disqualify colluding teams, or grant reconnect grace extensions.

---

## PART 5: Screen 4 — Prize Payout Approval & Settlement Queue

The financial safeguarding screen ensuring zero accidental or disputed currency payouts.

```text
+----------------------------------------------------------------------------------------------------+
| PRIZE PAYOUT APPROVAL • WEEKLY MASTERS CUP (#1042)                                                 |
| Tournament Status: COMPLETED • Final Standings Resolved • Escrow Total: 8,200 GC                   |
+----------------------------------------------------------------------------------------------------+
| Integrity Audit Status: [ ✓ All 31 Matches Clean • 0 Open Collusion Flags • Disconnect Resolved ]  |
+----------------------------------------------------------------------------------------------------+
| TIER     | WINNING TEAM         | PLAYERS                       | GC REWARD  | COSMETICS & PERKS    | STATUS    |
| 1st (50%)| Team Falcon          | Falcon_Leader & Falcon_Pro     | 4,100 GC   | Amir Crown + 30d VIP | [READY]   |
| 2nd (25%)| Team Shamal          | Shamal_Ace & Shamal_King       | 2,050 GC   | Silver Card Back     | [READY]   |
| 3rd-4th  | Team Najd & Team Hijaz | 4 Players Total               | 2,050 GC   | Bronze Profile Badge | [READY]   |
+----------------------------------------------------------------------------------------------------+
| Actions: [HOLD SPECIFIC TEAM PAYOUT]  [VIEW MATCH LOGS]               [APPROVE & RELEASE ALL PRIZES ✓] |
+----------------------------------------------------------------------------------------------------+
```

### Financial Settlement Workflow:
1. **Automatic Integrity Check:** The system automatically verifies that all matches completed normally without unresolved fraud flags.
2. **Dispute Hold Option:** Admins can place an individual team's payout on hold while releasing prizes to all other innocent participants.
3. **Atomic Ledger Execution:** Clicking *"Approve & Release"* executes an atomic database transaction that updates player balances and writes immutable ledger records simultaneously.

---

## PART 6: Screen 5 — Golden Card Financial Audit Ledger

An append-only, tamper-proof financial ledger providing complete auditability for all tournament-related currency transactions.

```text
+----------------------------------------------------------------------------------------------------+
| GOLDEN CARD FINANCIAL AUDIT LEDGER                                           [Export to Excel / CSV]|
+----------------------------------------------------------------------------------------------------+
| Filter by: [Tournament ID: #1042 ▾]  [User ID: All]  [Type: All ▾]  [Date: Last 24 Hours ▾]         |
+----------------------------------------------------------------------------------------------------+
| TX_ID      | TIMESTAMP (UTC)   | USER / TEAM   | EVENT_ID | TYPE         | AMOUNT    | BALANCE_AFTER |
| #TX-88421  | 2026-10-10 22:05  | Falcon_Leader | #1042    | PRIZE_PAYOUT | +2,050 GC | 6,850 GC      |
| #TX-88420  | 2026-10-10 22:05  | Falcon_Pro    | #1042    | PRIZE_PAYOUT | +2,050 GC | 4,200 GC      |
| #TX-88419  | 2026-10-10 22:05  | Royal_Baloot  | #1042    | PLATFORM_FEE | +800 GC   | SYSTEM_VAULT  |
| #TX-87910  | 2026-10-10 17:28  | Hijaz_Player1 | #1042    | BUYIN_ESCROW | -100 GC   | 1,450 GC      |
| #TX-87909  | 2026-10-10 17:28  | Hijaz_Player2 | #1042    | BUYIN_ESCROW | -100 GC   | 820 GC        |
+----------------------------------------------------------------------------------------------------+
```

---

## PART 7: Role-Based Access Control (RBAC) & Security

| Admin Role | Permissions Granted | Restricted Actions |
| :--- | :--- | :--- |
| **Super Admin** | Full access to all screens, admin creation, subsidy balance funding, and system configuration. | None (Full authority). |
| **Tournament Director** | Create/edit tournaments, manage schedules, configure rank bands, approve prize payouts. | Cannot alter platform rake rates or modify user accounts directly. |
| **Match Referee** | Access to Live Tournament Monitor, spectate matches, review replays, rule on disconnect forfeits. | Cannot create tournaments or release Golden Card payouts. |
| **Financial Auditor** | Full read-only access to Golden Card Ledger, historical payouts, and dispute archives. | Cannot create tournaments or modify match outcomes. |

---

## PART 8: Phased Implementation Plan for the Admin Panel

| Phase | Deliverable Screens | Key Capabilities | Delivery Target |
| :--- | :--- | :--- | :--- |
| **Phase 1 (MVP)** | Dashboard & Tournament Builder Wizard | Manual creation of Points-Ladder & Single Elimination cups, rank band selection, prize setup. | Sprint 1 |
| **Phase 2** | Live Tournament Monitor & Payout Queue | Live interactive brackets, spectate matches, referee forfeit controls, atomic prize release. | Sprint 2 |
| **Phase 3** | Audit Ledger, Replay Viewer & Cron Scheduler | Searchable Golden Card ledger, match hand-by-hand replay inspector, automated cron recurrence. | Sprint 3 |
