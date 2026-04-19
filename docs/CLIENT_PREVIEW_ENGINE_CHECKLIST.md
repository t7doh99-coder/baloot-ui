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

## 9. Recommended implementation order (remaining work)

1. **Playtest R2 bidding** after Sun/Second Hakam with Pass/Sawa (3 passes) — confirm copy matches app labels.  
2. **UI:** Hide/disable Triple/Four/Gahwa in Sun on the bottom bar (engine already blocks).  
3. **Optional:** Bot “Sawa” heuristic when partner’s bid is pending (currently always Pass).  
4. **Optional:** Wrong Qaid claim penalty (doc §9 — not in engine).  
5. **Golden / integration:** One scripted full round recording scores vs hand-calculated expectations.

---

## 10. Test commands

```bash
flutter test test/game/
flutter test test/game/round_score_rules_test.dart
flutter test
```

All **game logic** tests should pass; `test/game/` is the authoritative suite for rules compliance.
