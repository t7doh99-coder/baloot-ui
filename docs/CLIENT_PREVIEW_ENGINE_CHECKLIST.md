# Client preview — engine vs `BALOOT_RULES.md` checklist

**Purpose:** Step-by-step verification before showing Jawaker/Kammelna parity to the client.  
**Source of truth:** `docs/BALOOT_RULES.md` (v3.1). Apps are used for **UX/button parity** only where the doc is silent.

---

## Legend

| Status | Meaning |
|--------|---------|
| ✅ | Implemented & covered by automated tests (or trivially verifiable) |
| 🔧 | Fixed/added in this audit pass |
| ⚠️ | Partial / needs manual playtest vs Jawaker/Kammelna |
| 📋 | Recommended next implementation step |

---

## 0. `BALOOT_RULES.md` — section traceability & gaps

| Doc section | Topic | Primary code | Automated tests / notes |
|-------------|-------|--------------|-------------------------|
| (preamble) | Corrections vs client / Jawaker | — | See table in rulebook; each row should match engine + `test/game/` or be marked N/A |
| §1 | Core foundation (152, teams, 32 cards) | `round_state_model`, `baloot_game_controller` | `scoring_engine_test` (152 / Gahwa) |
| §2 | Dealing, Kut, remainder, Ashkal path | `deck_manager.dart` | `deck_manager_test` |
| §3 | Card values / Hakam & Sun ranking | `card_model.dart`, `turn_manager` | `turn_manager_test` |
| §4 | Bidding (R1, R2, Sawa, Ashkal) | `bidding_manager.dart` | `bidding_manager_test` |
| §5 | Play (lead, follow, void, +10 last trick) | `play_validator.dart`, `turn_manager` | `play_validator_test`, `turn_manager_test` |
| §6 | Projects (Sra, 50, 100, 400, Baloot) | `project_detector.dart`, `baloot_game_controller` | `project_detector_test` |
| §7 | Double / Sun exception / open-closed / tie | `baloot_game_controller`, `scoring_engine` | `baloot_game_controller_test`, `scoring_engine_test`, `play_validator_test` (closed) |
| §8 | Scoring, Khams, Kabout, rounding | `scoring_engine.dart` | `scoring_engine_test`, `round_score_rules_test` |
| §9 | Qaid / violations | `play_validator` (illegal play blocked); round loss for violation | play-level; **false Qaid penalty** = 📋 not in engine (see gaps in §0 / section 13) |
| §10 | 10s timer, bot on expiry | `game_provider.dart` | manual / UI; human seat 0 only in local build |
| §11 | Reconnection | `getGameState()` snapshot | **Partial:** JSON snapshot for future sync; no live multiplayer resume |
| §12 | Terminology | L10N / `game_l10n` | N/A (copy) |
| §13 | Confirmed decisions | — | product sign-off |
| §14 | Kammelna edge-cases (14.1–14.6) | various | 14.1 priority: `project_detector` (tie → Team A by convention, not turn order); 14.2 empty bid: `bidding_manager` + `baloot_game_controller_test`; 14.3 tie 152+: `isGameOver` / `gameWinner`; 14.4 Khams steal buyer projects: `scoring_engine._scoreKhams` + test; 14.5 Qaid: **📋**; 14.6 Kabout overrides Khams: `isKabout` first in `calculateRoundScore` |

**Gaps to track (not silent):** §9 false Qaid claim, §11 full reconnect, §14.5 manual Qaid flag, optional bot Sawa (see section 13).

---

## 1. Foundation & dealing

| Rule | Engine | Tests |
|------|--------|-------|
| 4 players, 32 cards, teams 0&2 vs 1&3 | ✅ | `deck_manager_test`, `round_state_model_test` |
| Deal 3+2, buyer card, then bidding | ✅ | `deck_manager_test` |
| Remainder: buyer +2 + card; others +3 (Ashkal: teammate gets buyer card) | ✅ | `deck_manager_test` |
| Dealer advances clockwise on screen (+1) | ✅ | `baloot_game_controller_test` |

---

## 2. Bidding (Section 4)

| Rule | Engine | Notes |
|------|--------|--------|
| First bidder = dealer’s right (+1) | ✅ | `bidding_manager_test`, `turn order` |
| R1: Hakam, Pass; Sun overrides Hakam | ✅ | |
| R1: Hakam → 3 passes → **Confirm Hakam / Sun** | ✅ | `hakamConfirmation` |
| R1: Sawa locks Hakam (buyer = original Hakam bidder); **Sawa only by defenders** | ✅ | `bidding_manager_test` |
| R1: Ashkal only dealer or sane; Sun + Ashkal flag | ✅ | |
| R2: Sun, Second Hakam, Pass — **no Ashkal** | ✅ | |
| R2: Sun → others Pass/Sawa; 3 passes locks Sun | ✅ | No Hakam-style confirmation |
| R2: Second Hakam → others Pass/Sawa; 3 passes → **Confirm Hakam / Switch to Sun** | ✅ | Visca ME + Kammelna (same as R1 Hakam); `bidding_manager_test` |
| R2: Sawa locks pending Sun or Second Hakam immediately; **defenders only** | ✅ | |
| All pass R1 + all pass R2 (no bid) → cancel round | ✅ | |

---

## 3. Double (Section 7)

| Rule | Engine | Notes |
|------|--------|--------|
| Window before first card | ✅ | `doubleWindow` phase |
| Hakam: Double → Triple → Four → Gahwa (alternating teams) | ✅ | `baloot_game_controller_test`, `scoring_engine_test` |
| Sun: **only Double**, buyer >100 & defender <100 | 🔧 | **Triple/Four/Gahwa now rejected** in Sun (`callDouble`) |
| Open vs Closed play when doubled | ✅ | `play_validator_test` |
| Gahwa → instant game end | ✅ | |

---

## 4. Play (Section 5)

| Rule | Engine | Notes |
|------|--------|--------|
| **First trick leader = buyer** | ✅ | `baloot_game_controller._startPlayPhase` (doc §5.0 aligned) |
| Follow suit; Hakam cut & up-trump | ✅ | `play_validator_test` |
| Sun void: any card | ✅ | |
| Last trick +10 Abnat | ✅ | `turn_manager_test` |

---

## 5. Projects (Section 6)

| Rule | Engine | Notes |
|------|--------|--------|
| Sera / 50 / 100 (incl. 4×10,J,Q,K same suit, 4 Aces) / 400 Sun / Baloot auto | ✅ | `project_detector_test` |
| Max 2 manual projects; Baloot separate | ✅ | |
| Declare trick 1 / reveal trick 2 (UI + `declareProject` guard) | ✅ | `trickNumber > 1` blocks declare |
| Project priority & Baloot immune to ×2 cap | ✅ | `scoring_engine_test` |

---

## 6. Scoring (Section 8)

| Rule | Engine | Tests |
|------|--------|--------|
| Sun: round(abnat/10)×2 | ✅ | `scoring_engine_test` |
| Hakam: Jawaker .5 down | ✅ | `scoring_engine_test` |
| Thresholds 65 / 81 | ✅ | |
| Khams 26 / 16 | ✅ | |
| Khams §14.4: defenders steal **buyer’s** project pts (not project-priority team) | ✅ | `scoring_engine_test` “Khams: defenders get buyer declared projects…” |
| Kabout Sun 44 / Hakam 25 + projects + ace/double rules | ✅ | `scoring_engine_test` |
| Game to 152 or Gahwa | ✅ | |
| Round scoreboard numbers vs §8 (Sun 67/63→14/12, Khams 26/0, etc.) | ✅ | `round_score_rules_test` |

---

## 7. Timer & bots (Section 10)

| Rule | Engine | Notes |
|------|--------|--------|
| 10s human timer; bot takeover | ✅ | `GameProvider` (UI separate) |
| Bot R2: Pass when bid pending (no illegal Ashkal) | 🔧 | `bot_engine` |

---

## 8. UI parity (Jawaker / Kammelna) — manual matrix

These are **not** fully testable without UI snapshots:

| Area | 📋 Action |
|------|-----------|
| Bidding buttons: Pass, Hakam, Sun, Second Hakam + suit picker, Sawa, Ashkal (when legal), Confirm Hakam | Playtest each seat |
| Double bar: Double / Triple / Four / Gahwa + Open/Closed | Hakam only; Sun hides escalation |
| Project button trick 1 only | |
| Score overlay: charcoal theme, لنا/لهم + row labels (AR locale), buttons **below** card | ✅ / playtest |
| Kammelna-only: single “عودة” vs our Exit + Play again (by design) | |

---

## 9. Manual E2E flow scenarios (Kammelna / Jawaker–style)

Run on **device or web** with human at seat 0. Pass = tick each line when done.

1. **Hakam R1 — happy path:** Deal → R1 `Hakam` (human if able) or let bots set Hakam → 3× Pass → **Confirm Hakam** (not Sun) → double window: all **Pass** → play **8 tricks** → round score; no exceptions.
2. **Sun R2:** R1 all **Pass** → R2 open **Sun** (human or wait for bot) → 3× **Pass** from others → **Sawa** or lock by passes → double → play to score.
3. **Second Hakam R2:** R1 all Pass → R2 **Second Hakam** + suit (≠ buyer card suit) → 3× Pass → **Confirm Hakam** or **Switch to Sun** → double → play.
4. **Empty round:** R1 all Pass, R2 all Pass → **round cancelled**, dealer advances; no points.
5. **Gahwa (if reachable from UI):** In Hakam double chain, when buyer may call **Gahwa** per rules → **game ends** immediately; verify `gameOver` / winner.
6. **Ashkal (R1 only):** When human is **dealer or sane**, bid **Ashkal** once; verify teammate receives buyer card and mode is Sun + Ashkal per HUD.

**Exit:** Each row completes without red screen / unhandled engine error; first trick leader matches [BALOOT_RULES.md](BALOOT_RULES.md) §5.0 and controller (`_startPlayPhase`).

---

## 10. Scoring & §8 — test index (Kammelna / Jawaker rounding)

| Doc / behavior | `test/game/` location |
|----------------|------------------------|
| Sun `round(abnat/10)×2`, examples 88→18, 42→8, round total 26 | `scoring_engine_test` → `Abnat to scoreboard conversion` / Sun group |
| Hakam Jawaker .5 down (155→15, 85→8, 86→9, …) | `scoring_engine_test` → Hakam group |
| Khams 26 / 16 | `scoring_engine_test` + `round_score_rules_test` Sun Khams |
| Kabout Sun 44, Hakam 25, ace/double variants | `scoring_engine_test` Kabout group |
| Double 32, Triple 48, Four 64; Sera ×2 cap; Baloot not ×2; tie 81–81 | `scoring_engine_test` Double system group |
| Kammelna-style full round: Sun 67/63 Abnat → 14/12 | `round_score_rules_test` |
| Game end 152, Gahwa, both over 152 | `scoring_engine_test` Game end detection |

**Rounding parity:** All Hakam Abnat→scoreboard cases above assert **Jawaker-style** behaviour already codified in [BALOOT_RULES.md](BALOOT_RULES.md) §8.5.

---

## 11. Kammelna / Jawaker — parity log (fill on spot-check)

| Date | App & version | Scenario (short) | Expected (doc §) | Observed in app | Royal Baloot build | Match (Y/N) |
|------|---------------|------------------|------------------|-----------------|--------------------|------------|
| | e.g. Kammelna iOS / Jawaker | e.g. Doubled Hakam + Sera 34 | §8.6 | | `git` / APK | |
| | | e.g. Sun double gate >100 & <100 | §7.1 | | | |
| | | e.g. Khams 26 vs buyer 0 | §8.3 | | | |

Use when claiming **identical** behaviour to a commercial app; the **source of truth** for implementation remains `BALOOT_RULES.md`.

---

## 12. Audit run log

| When | `flutter test test/game/` | Notes |
|------|----------------------------|--------|
| 2026-04-20 | **144 passed**, 0 failed | Hakam **10–J–Q–K** same suit now classified as **100** in [`project_detector.dart`](../lib/features/game/domain/engines/project_detector.dart) (was misclassified as 50); matches BALOOT_RULES §6 / Kammelna-style 100. |

---

## 13. Recommended implementation order (remaining work)

1. **Playtest R2 bidding** after Sun/Second Hakam with Pass/Sawa (3 passes) — confirm copy matches app labels.  
2. **UI:** Hide/disable Triple/Four/Gahwa in Sun on the bottom bar (engine already blocks).  
3. **Optional:** Bot “Sawa” heuristic when partner’s bid is pending (currently always Pass).  
4. **Optional:** Wrong Qaid claim penalty (doc §9 — not in engine).  
5. **Golden / integration:** One scripted full round recording scores vs hand-calculated expectations.

---

## 14. Test commands

```bash
flutter test test/game/
flutter test test/game/round_score_rules_test.dart
flutter test
```

All **game logic** tests should pass; `test/game/` is the authoritative suite for rules compliance.
