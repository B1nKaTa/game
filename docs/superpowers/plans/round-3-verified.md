# Round 3 polish: verified 2026-11-05

Built and checked on `round-2` with Godot 4.7.2, not yet played by a person. `tools/test.ps1`: 2005 tests, 0 failed, with exit-time leak lines identical to round 2 (3 Body2D RIDs, 3 CanvasItem RIDs, 6 ObjectDB instances, 2 resources). Two full loops in `git archive` copies D:\grandpa-verify-r3-1 and -2 (config/name GrandpaR31 and GrandpaR32): see the run times in the report. The save guard held: slot_1/save.json stayed 510284fa2ead4647c94fee44f99ca787. Screenshots are in D:\grandpa-shots-r3\ (tools/probes/round3_look.gd, args hud, case, chairman, sand, ring, bubble or all).

## What changed

- **Harold's case file (Tab).** A manila folder with five paper tabs, opened by the new rebindable action `case_file` (Tab; the DualSense touchpad on a pad), in a run or in the Waiting Room. It pauses the game. Q / E or LB / RB switch tabs; arrows, D-pad or mouse move round a page; PageUp / PageDown or the Prev / Next buttons turn pages; Tab, Esc or B close it. Tab was bound to nothing before (the map is M / View), and an old keys.json keeps its bindings: one with no `case_file` keeps Tab, and one that already put Tab on another action keeps it there and gives the case file that action's old key (tested).
  - Harold: his stats, the forms bought, the held items as a paged 8 x 3 grid with stack badges and a detail line; on the right the floor, route, run time, Pension this run, Slips, Thermoses, potion and buff, kills, hits taken, combos, curses (cursed ticket, cursed items) and blessings (memento perks). The Waiting Room shows "No active case" and what is on file.
  - Items: all 100, 8 x 6 a page, unfound ones dark with "?", "N/100 found", and name, effect, rarity, times found and first-floor shop price (or "never sold").
  - Bestiary: every EnemyDef but the Training Yard dummy (71), by floor, met ones in colour with their kills, the name, the floor and "A boss." only; no lore was written.
  - Stats: lifetime runs, wins, endings, deaths, defeats, hits taken, Pension, items found, floors cleared; and the best single run.
  - Log: the last 50 runs, newest first, with date and how each ended (died on floor N to the nearest enemy or boss, an ending, a clear, or given up), and its time, seeds, Pension, defeats by enemy and items.
  - Cells show an icon from `res://art/icons/items/<id>.png` or `res://art/icons/enemies/<id>.png` when the art pass adds one, else a colour chip and initials.
- **Save data.** New optional keys in the slot's save (`items_seen`, `enemies_seen`, `lifetime`, `best_run`, `run_log`), through `ProgressData.from_dict` as every later field; VERSION stays 1, writes stay atomic with the .bak. An older save loads unchanged with an empty history, its crafted items counted as found and its beaten bosses as met. The run's tally (kills, met, found, hits, seeds) lives on RunState and in the checkpoint. A run is logged the moment it ends (or is given up from the title), and its ending is filled in once chosen. Tests: the 2026-11-04 fixture loads, a round trip, the 50 cap, damaged history.
- **HUD item row.** `Items: N` and the newest three names, ellipsized on one line, with "Tab: Case file" (the real bound key) right-aligned before the small map. 100 items fit.
- **The Chairman's restructuring.** Right after a chart rises he may call "Restructuring!": rows of filing cabinets slide their drawers out across the room in turn (as tall as a bar is wide, 0.9 s warning, 0.4 s apart, standing 0.4 s), crossing the bars. The rows are laid out with `OverlapRoute.with_rects` against the chart as it stands, so a way to a spot nothing will hurt is always left, and the green mark moves there; the gavel follows. 42% of charts, 70% below half health, once a chart. 200-seed test: 200 of 200 laid, 0 states the chart alone had lost, 173 gavels after, slowest plan 2.3 ms.
- **Sand** at Fairway's End: (0.86, 0.83, 0.71) -> (0.55, 0.5, 0.76), grain and shine darker. Measured in the window under Grandpa's own glow, luminance 0.90 -> 0.76; elsewhere about 0.40. Lit warning against lit sand 0.426 (test >= 0.4), and a new test keeps the sand at a wall light under 0.7.
- **Desk slam ring:** a 3 px rim on a dark 6 px backing and a second 2 px ring 8 px inside, as strong as the gavel's double ring.
- **Big map prompt:** a pad shows "Circle: Close" / "B: Close" (the back button, which closes it), right-aligned in the corner; the keyboard still shows the map key.
- **Speech:** NPC bubbles and bosses' spoken lines flip below the speaker when above would reach into the HUD band (Hud.BAND_BOTTOM, 36 px on screen), and slide in from the screen's sides; a bubble hung below clears the Talk prompt.

## Bot (v8, max good, boss fights only, 20 a batch)

| Build | Chairman wins | won fight length | boss left on losses |
|---|---|---|---|
| c52df6e, before | 13 | 124 s | 9% |
| restructure 50% / 80% | 1, 4 | 123, 132 s | 18%, 25% |
| 35% / 60% | 9, 5 | 141, 140 s | 12%, 21% |
| 42% / 70% (kept) | 8, 7, 7, 4 | 138, 131, 161, 145 s | 17%, 20%, 20%, 21% |

Augustine as the control on the new build: 0 of 20, 37.5% left (round 2: 0, 36 to 37%).

## Still to judge in play

- Whether the restructuring reads at a glance for a person, and whether its longer fights (about +16% for the bot) are fine. Health below Augustine's would shorten them but break the rule that the Chairman is the toughest.
- Xbox pads have no touchpad, so the case file needs rebinding there (Y, LS or RS are free).
- The sand is now a moonlit lavender; darker still would need the warning-on-sand limit relaxed below 0.4.
