# Floor-5 boss rework: verified 2026-11-05

Checked on `round-2` with Godot 4.7.2: headless import clean; `tools/test.ps1` 1972 tests, 0 failed, with exit-time leak lines identical to `integration` 85e7162 (3 Body2D RIDs, 3 CanvasItem RIDs, 6 ObjectDB instances, 2 resources); three full loops in `git archive` copies (D:\grandpa-verify-r2-1..3) all passed in 615, 627 and 625 s, with exit leaks matching an `integration` loop run alongside (627 s) and no warning line that loop lacks. The save guard held: slot_1/save.json stayed 510284fa2ead4647c94fee44f99ca787. Screenshots are in D:\grandpa-shots-r2\ (tools/probes/round2_look.gd, and golf_look.gd into golf\).

- Fixed: a phase-two chart with its tape could leave no reachable spot (1 seed in 200); `choose_chart` now re-rolls up to 8 layouts. The 200-seed gavel test froze Grandpa under a falling bar 1.55 s into a chart; it now finds him on the mark for a late gavel and counts states the bars alone have lost (2 of 200). Measured thresholds: gavel on his feet 194 of 200 (test >= 175); runway centred 188, stamps found 195, stamps on feet 195 (tests >= 170, 180, 170).
- Fixed: runway_plan took up to 169 ms in the 30x17 room. Tries share one floor and the floor is built per block and per cell: worst runway 33 ms, chart 7 ms, stamp 33 ms, gavel under 1 ms.
- Slack beyond the 0.3 s reaction (tools/probes/slack_probe.gd, 200 seeds): runway median 1.0 s (p10 0.35), runway then stamp 0.45 (p10 0.2), chart 1.55 (p10 0.35), chart then gavel 0.45 (p10 0.2).
- Screenshots b1-b7 (gavel during a chart in both phases, desk slam ring, papers and shove) and a1-a3 (runway with ropes up and its mark, a stamp and a gate change during a pattern) all read. The desk slam's outer ring is a thin line, fainter than the gavel's double ring.
- Bot, max good, 20 fights a batch (wins; boss health left on losses). Before the rework: Augustine 18, 18; the Chairman 20, 20. After, bot v6: Augustine 0, 0; the Chairman 9, 11, 10. Bot v7 with escapes sliding round bodies: Augustine 0, 0 (36%, 37% left); the Chairman 13, 15, then with charts every 1.6 s (1.0 s in phase two) 13, 12 (11%, 10%); the Commodore 4, 2 and 6, 4 (21%, 28%); Thaddeus 0, 0 and 1, 1 (26%). At 3000 health the Chairman still won 12 and 7 (13%, 15%) in fights of 146 to 162 s, so that was reverted.
- So Augustine already sits above the fourth floor for the bot, which mostly loses his runway among the ropes (90 to 104 runway hits a batch) though the slack matches the chart's. The Chairman is still the easiest deep boss for the bot; health and chart pacing do not change that. Left for the user.

The original list of owed checks follows.

## Floor-5 boss rework: checks still owed

Branch `boss-rework`, off `integration` at 85e7162 (1927 tests passing there). Written on 2026-11-05.
Testing was put on hold partway through the work. **None of the rework has been parsed or run by
Godot**: no import, `--check-only`, test, full loop, bot batch, probe or screenshot. Only the
"before" bot batches below ran, on 85e7162, before any change. `scripts/core/overlap_route.gd` and
`scripts/world/desk_slam.gd` are new and have no `.uid` yet.

## What changed

- **`OverlapRoute`** (`scripts/core/overlap_route.gd`): a pure check on a 16 px feet grid. Grandpa
  waits 0.3 s, then walks a step at a time at base speed (never diagonally). Hazards are rects or
  circles with a time window, grown by 9 px and half a step of time each way, so the answer can only
  miss a way out, never invent one. Blocks (ropes, a boss body), closed cells and red tape (a 0.6 s
  hold on stepping onto it or when it is strung under him) are modelled too. `escape()` returns
  safe / haven / pure; `strike_plan()` tries a heavy strike on his feet, then up to 32 spots further
  off, and returns the first that leaves a way out and a pure spot to mark.
- **The Chairman** (`chairman_behavior.gd`): charts rise on their own clock (first after 1.5 s, then
  2.4 s after each one sinks, 1.4 s in phase two). He stands at the chart while it runs and only
  gavels. Each gavel during a chart is planned with `gavel_plan` and moves the GapMark. Between
  charts: desk slam when Grandpa's feet are within 80 px (new `DeskSlam`, a `GroundStrike` of
  radius 72, 0.8 s shown whole in both phases, 1 pill, shoves him 260 px/s for 0.25 s), takeover
  from 130 px, gavel otherwise. Phase two: the tape spreads as a chart rises (no longer as an
  attack of its own), and the gavel follows the chart with no rest. `projection_bars` widens any
  wall-side gap narrower than 40 px by trimming its bar.
- **Augustine** (`head_of_departures_behavior.gd`): with ropes up or chiming he lights the runway.
  `runway_plan` tries both ways, both orders and the band moved up to 5 lanes either side, with every
  rope counted as up, and marks a reachable spot (SafeSpotMark). He stands still while the lanes
  light, may change the gate meanwhile (the ropes' own 1 s chime), and stamps after every pattern
  (phase two with no rest). Each stamp during a pattern is planned with `stamp_plan`. If no
  pattern works, nothing lights and he stamps instead.
- **Effects:** `LaneDrop.danger_window`, `RunwayLane.danger_window` and `lane_rect`, and
  `TapeSpread.cells` and `warning_left`. `DeskSlam` is a GroundStrike, so `RoomView.is_passing_effect`
  already clears it.
- **Bot v6** (`tools/probes/bot_probe.gd`): DeskSlam counts as a deep strike, and Augustine's
  runway mark is honoured while lanes light.
- `tools/probes/airport_look.gd`: dropped the removed `_chained` field.

`player.gd` and `enemy.gd` were not touched (the contact-damage branch edits them).

## Run in this order

Check for an open game window first, and record the MD5s of `save.json`, `save.json.bak` and
`slot_1/save.json(.bak)`. They were F4A62BAF…, EC5412AD…, 510284FA… and F4A62BAF… on 2026-11-05.

1. `--headless --path . --import` once (2 new class names). On a parse error, `--check-only` each of
   `overlap_route.gd`, `desk_slam.gd`, `chairman_behavior.gd`, `head_of_departures_behavior.gd`,
   `lane_drop.gd`, `runway_lane.gd`, `tape_spread.gd`. Commit the new `.uid` files.
2. `powershell -File tools/test.ps1`, 0 failed. New or changed: `test_overlap_route.gd`;
   `test_office_bosses.gd` (takeover/slam choice, slam timing, gap widths, bar windows, **200-seed
   gavel-during-chart**, chart→gavel chain, tape-with-chart source check); `test_airport_bosses.gd`
   (stamp after every pattern, ropes-up choice, lane window/rect, **200-seed runway with every rope
   up plus stamp**). Also `test_enemy_types.gd` (SLAM_WINDUP), `test_office_floor.gd` (reads the
   behaviour's source for `GapMark.new()`), `test_stage2_props.gd`. Then
   `git checkout -- art/sprites audio/sfx`.
3. **Count thresholds I could not check.** If these fail on the numbers, look at the cause before
   relaxing them: `on_feet > 100` (gavels that still fall on his feet), `centred > 100` (patterns
   centred on him), `stamps > 150` (stamps that find a spot at once). Any `"a spot is found"` /
   `"a pattern is found"` failure is a real safety failure. Fix the plan, not the test.
4. **Cost of the search:** `runway_plan` can run up to 44 searches in a trapped spot, and
   `strike_plan` up to 33. Time one gavel and one runway plan in the 30x17 room. Over about 20 ms
   is a visible hitch.
5. Two full loops in `git archive` copies `D:\grandpa-verify-bossrw\GrandpaSmokeBrwA` and `…BrwB`
   (`config/name` renamed), as in `.claude/skills/add-floor/checklist.md` section 2. The east run
   ends on the Chairman, so watch for script errors in his fight. Report the run times.
6. Bot batches (2 of 20 each, max and some, `good`), each batch in its own export copy (two
   batches sharing a user folder share `probe_max_good.json`). The scratchpad runner was
   `bot_rw.ps1`: it exports with `git archive` to `D:\grandpa-verify-bossrw\<copy>` and runs the
   copy's own `bot_probe.gd`. Cases: `max good 20 0 5 boss;some good 20 0 5 boss` (Augustine) and
   `… 1 5 boss` (the Chairman), plus the yardstick `… 0 4 boss` (Commodore) and `… 1 4 boss`
   (Thaddeus) on the same bot v6. Targets: the Chairman clearly below the floor-4 bosses'
   win rate, Augustine between them, both still winnable on max. If the Chairman is too hard, tune
   the chart break first, then the slam.
7. Real-window screenshots (only when the user is not playing) from an `export_copy.ps1` copy, PNGs
   to `D:/grandpa-look-bossrw/`, each opened and looked at, with the boss bar name visible:
   - the Chairman: a chart with a gavel planned on Grandpa's feet and the GapMark moved off it, at
     the moment the most bars are warned; the same with phase-two tape warning; the desk slam's
     ring and fists mid-windup, and its paper burst with Grandpa shoved; a gavel moved off his feet
     (force it by boxing him in).
   - Augustine: ropes up with a runway pattern lighting and the green mark; a gate change chiming
     during a pattern; a stamp during a pattern with its two rings, the mark beside it.
   `tools/probes/office_look.gd` and `airport_look.gd` start attacks through `_begin`, which still
   works, but they do not set up overlaps. A new probe should start a chart (`_begin` PROJECTIONS,
   wait for the windup), then `_begin` GAVEL, and shoot by state (`fill()`), not by time.

## Risky spots to check first

- **Never parsed.** Watch the untyped calls on `enemy.target` in `DeskSlam._shove`, the Variant
  values from Dictionaries passed into typed parameters, and the lambdas in static functions
  (`keep_off_body`).
- **The mark during a chart moves** when a gavel is planned. It reads as "the safe spot changed",
  which is the point, but check that it is not confusing.
- **The Chairman now stands still for whole charts** (2 to 4 s). In a small room, check that he
  still reaches Grandpa between charts and that the fight is not too long.
- **Barriers are counted as all up** for every pattern. In the 30x17 room with 48 rope cells this
  may push the band off him more often than wanted (see the `centred` count).
- **The slam's shove** goes through `Player.push`, which a dodge breaks. It never runs during a
  chart, so it cannot shove him into a rising bar.
- **The tape already strung when a chart begins** is read from `RedTape` nodes; cut tape counts as
  strung again when its cut heals (`_cut_left`, read from outside the class).
- **The phase-two straight chains** make both bosses much busier. If the bot finds them walls,
  give the stamp and the gavel their old rest in phase two first (`rest_after_runway`,
  `rest_after_chart`).
