# Client QA trace matrix (Baloot UI vs Kammelna / Visca ME)

Bidirectional checklist: client email bullets ↔ in-repo rule reference ↔ runtime surface (files).

| Client concern | BALOOT_RULES / expectation | Behaviour & code |
|----------------|---------------------------|------------------|
| Dealer not identifiable | §4 / seat order; Ashkal = dealer or sane | Orbital seats: `player_seat_widget.dart` (`isDealer`). Bottom Majlis bar shows “Dealer” on the bronze chip **only when the human is seat 0** (`human_player_majlis_bar.dart`). |
| Projects too early / before first card | §6: announce first **trick**, show second trick | Engine still uses `GamePhase.projectDeclaration` **before** trick 1 (`baloot_game_controller.dart`); reveal fan on first card of trick 2: `game_provider.dart`. **Product decision needed** to align declaration timing with §6. |
| Only highest project visible | §6.3 project priority | After trick 1: `_filterLosingProjects()`; reveal: `winningTeamBestProjectsForReveal`; scoring: `projectWinningTeam` + `scoring_engine.dart`. |
| Sawa “forced Hakam” | §4.4 Sawa matches bid; buyer unchanged | Bidding `BidAction.sawa`: `bidding_manager.dart`. UI label **“Sawa”** / **“سوى”** vs in-play `Tooltip` on hands Sawa: `game_table_screen.dart`, `human_player_majlis_bar.dart`. |
| Nashra / loss vs manual Abnat | §8 trick threshold 65/65 not projects | `ScoringEngine.calculateRoundScore` — buyer win from **trick** Abnat only. Overlay: **“Trick pts (cards)”** row + Khams project footnote: `scoring_overlays.dart`. |
| Both teams’ projects counted | §6.3 / §14.4 Khams steal | Normal: one team’s project scoreboard. Khams: stolen buyer projects appear on defender column — footnote explains. |
| Hand order H–S–D–C, low→high | Sort order | `CardModel.compareTo`; all four hands sorted after deal: `baloot_game_controller.dart`. |

---

## Regression test script (manual, ~4 rounds)

1. **Dealer rotation** — Play through 4 complete rounds (any outcome). Confirm the **orbital** dealer badge matches [`dealerIndex`](lib/features/game/domain/baloot_game_controller.dart) in the copied game log after each round.
2. **Dual projects** — Declarations on both teams before play; after trick 1 verify losing team’s non-Baloot projects removed; after first card of trick 2 only one project fan (winning side’s best).
3. **Bidding Sawa** — Round 1: opponent bids Hakam; as defender tap **“Sawa”** (**“سوى”** in Arabic); confirm contract locks to Hakam with original Hakam bidder as buyer (per §4.4). Do **not** confuse with in-play Sawa (tooltip on bottom bar).
4. **Khams + projects** — Engineer buyer loss below threshold with declared projects on buyer; open score overlay: read **Khams** footnote under Projects; confirm trick row is **Trick pts (cards)** only.

Recording: capture screen + `Copy game log` from the HUD menu for any mismatch.
