# Deep floors: what has not been run yet

On 2026-11-04 the user put testing on hold. Everything on `deep-floors` from the Step 1 commits onward
(the skull number on signs, depths four and five, the F5 and F6 dev runs) was written without being
parsed or run by Godot. No test, import, `--check-only`, full loop or probe has run it. Nothing that
needs Godot is ticked in the plan.

## First test session

Do these in order. First check that no game window is open
(`Get-CimInstance Win32_Process -Filter "Name like 'Godot%'"`), and record the real save's MD5
(`%APPDATA%\Godot\app_userdata\Grandpa\save.json`). It must be the same afterwards.

1. **Import:** run `--headless --path . --import` once. Step 1 adds no new `class_name` and no new
   script, so no new `.uid` files are expected, but the six new `.tres` files are imported for the
   first time.
2. **Fix parse errors:** if anything fails to load, check the touched scripts one by one with
   `--check-only --script <path>`: `scripts/world/path_sign.gd`, `scripts/core/dev_start.gd`,
   `scripts/autoload/progress.gd`, `scripts/autoload/game.gd`, `scripts/scenes/waiting_room.gd`,
   `scripts/scenes/floor_scene.gd`, `tools/smoke_driver.gd`, and the tests below.
3. **Get `tools/test.ps1` green:** read the summary line, and expect "N tests, 0 failed" with no
   `SCRIPT ERROR` or `Parse Error`. Then `git checkout -- art/sprites`.
4. **Run 2 full loops** in `git archive` copies on D: (`D:\grandpa-verify-conn\`, config names
   `GrandpaSmokeConnA` and `GrandpaSmokeConnB`), as `checklist.md` section 2 shows. Pass is exit 0,
   both `SMOKE PASS` lines, no `SCRIPT ERROR`. Report each run's time: it now clears 10 floors (5 per
   run) instead of 6, plus three dev starts, against a `TIMEOUT` of 1800 s. The last measured run, with
   6 floors, took about 388 s, so expect roughly 600 to 700 s. Delete the copies and the
   `GrandpaSmokeConn*` user folders afterwards.
5. **Look at the signs in a real window** (only when the user is not playing): the Floor 4 and
   Floor 5 Crossroads, where each sign should show one skull with "x5", "x6", "x7" or "x8" beside it,
   under the path's name and above the chained hint. The F5 and F6 dev runs reach them fastest.
6. **Try the keys by hand** in a debug build: F3, F5 and F6 in the lobby, the DEV hint at the bottom
   of the lobby (it now reads "DEV  F3/F5/F6: Floor 3/4/5 (max upgrades)   F4: ..."), and F4 then the
   run door, which should still start at Floor 3.

## Test files to run

- `tests/test_deep_floor_unlocks.gd` (new): locks, hints, save round trip, old saves, difficulty
  numbers, names and danger, landings, the save lists mirroring `floor_scene.gd`, and the skull number.
- `tests/test_crossroads.gd`: the new `test_a_deadly_path_shows_one_skull_and_its_number`.
- `tests/test_dev_start.gd`: the new start-key, deeper-profile, floor-3-profile, start-depth and
  source tests, and the changed `test_the_dev_waiting_room_has_its_own_key_and_hint`.
- `tests/test_lobby_text.gd`: unchanged, but `DevStart.HINT` changed, so the hint's width is
  re-checked.
- Must still pass: `tests/test_third_floor_unlocks.gd`, `tests/test_floor_unlocks.gd`,
  `tests/test_boss_spawn_room.gd` (it walks every file in `data/floors/`, so it now checks the four
  placeholders' borrowed rooms too).

## Risky spots to look at first

- **Typed against untyped arrays:** `DevStart.paths_cleared` returns `Array[String]` built from the
  untyped `ProgressData.PATHS_AT_DEPTH`. The test compares it element by element to avoid a
  typed/untyped `==`.
- **`Progress.dev_start_depth`:** a new member on the autoload, defaulted from `DevStart.START_DEPTH`.
  `test_dev_start.gd` preloads `progress.gd` and reads it through a `Node`-typed variable.
- **`Game.begin_dev_run(start_depth)`** now passes `Progress.DEV_PATH` explicitly; a wrong constant name
  here would only show at runtime, in the full loop's `_check_dev_start`.
- **The hint's width:** `test_the_dev_hint_and_profile_label_fit_the_bottom_of_the_screen` is the only
  check that the longer key list still clears the "DEV PROFILE" label. If it fails, shorten
  `DevStart.HINT` rather than move the label.
- **The full loop at depth 3:** a floor-3 boss used to end the run and now drops two items and a
  stairwell. `_take_the_stairwell` and `_check_boss_choice` have only run at depths 1 and 2 before.
- **Placeholder enemy counts:** the four placeholders carry the real 7/9/14 and 8/10/15 room sizes but
  the third floor's rooms (6/8/13), so `FloorDef.room_size_errors` reports them. Nothing checks that for
  these files yet; the path steps bring their own rooms.
- **Mini bosses beaten:** the Waiting Room PASS line counts mini bosses per path, so it can now read up
  to 10, with the placeholders' borrowed bosses counted again. It is counted, not demanded.
- **Run time:** if a loop runs far past about 700 s, suspect a hang (a parse error in the driver) before
  the timeout, and run Godot directly with output redirected (see `LESSONS.md`).

## Step 3: the Waiting Room hooks (2026-11-04)

Written while testing was on hold, then tested once the user allowed it: after one
`--headless --import`, `tools/test.ps1` reads **1457 tests, 0 failed** (no SCRIPT ERROR or Parse Error;
the one "Parse JSON failed" line is `test_key_bindings`' damaged-file case). The real save's MD5 was the
same before and after (F4A62BAF2984C99A2FC54EBD6DC1E308). The first run also loaded four test files
that had never parsed since the path merges (`test_chests`, `test_shop`, `test_cruise_floor`,
`test_golf_floor`), and they pass now.

Still owed (no full loop or real window has run on Step 3):

- **Full loops, 3 runs** in `git archive` copies on D:. New or changed checks:
  `_check_departments_at_start` (open ids are now `Departments.corridor_ids()`),
  `_check_bounty_collected` (nine open ids after the first run, the annexe's included),
  `_walk_every_department` (it now walks through the Bounty Office into the Annexe and the Upper
  Landing, and checks the three counters, the plaque and the four keepers), the Bon Voyage Bag at the
  start of each run, `_take_the_stairwell` (`scene.landing_heal()`, 3 once Augustine hangs), the new
  `_check_ending_card` after the second run, and `lethal_saves = 0` before both deaths.
- **Screenshots with F4** (each opened and looked at):
  - the Annexe and the Upper Landing, and the Bounty Office's north door and its sign;
  - the Purser's Office, the Pro Shop, Duty Free and the Executive Suite with their counters, keepers
    (name labels over the 14-cell rooms' walls?), the plaque, and a keeper's greeting bubble after a
    death and after a boss win;
  - the trophy wall with all 10 frames filled and with all 10 empty (captions now staggered 13 px:
    do the low ones clear the ticket machine's and trophy wall's prompts?);
  - the cork board with 20 papers and a TAKEN mark on a paper past the twelfth;
  - the bounty panel with all 20 posters: it must scroll and keep its Leave button on screen;
  - the noticeboard with 10 letters (it scrolls now) and a long letter shown;
  - the refile panel with 10 forms past their milestone, the craft panel and the item rack with 8
    recipes: none of these scroll, so check they still fit 360 px;
  - the Decor Office's Grandpa tab with 14 looks;
  - the four new looks on Grandpa facing both ways, in the Waiting Room and over a pale run floor:
    the Captain's Hat, the Golf Visor, the Aviator Sunglasses (placed from an ASCII dump of the idle
    frame, eyes taken as y = -16, lenses at x 4 and 8.5 the way he faces) and the Power Tie (drawn
    from the chest band's point, 2 px the way he faces). Measure on an 8x crop as `LESSONS.md` says;
  - the ending card (Head Office cleared for the first time), and that a press after one second
    closes it into the Waiting Room.

### Risky spots

- **The annexe through the Bounty Office.** A save that cleared the Cemetery but has no `floor_1` in
  `paths_cleared` would keep the annexe behind a chained door. `_infer_first_paths` covers saves from
  before paths were kept only when no depth-1 path is recorded at all.
- **One press, two answers.** Npc's rivals list ignores WaitingStation, so keepers stand more than
  `USE_RADIUS + TALK_RADIUS` from every counter (`test_a_keeper_stands_out_of_reach...`).
- **Slide perk.** Halves `Player.push` (bellows, foghorn, organ rings, the Chairman's pull) and the ship
  roll, not the queue barrier's push-out (it moves him just clear of a rope) or escalator strips.
- **Golden Parachute.** No Pension was ever lost on death, so it pays a quarter of what this run's rooms
  paid (not Arcade winnings) again when he dies. That is a reading of "keep 25% more", for the user.
- **Bon Voyage Bag.** 50% a random potion for sale (Healing Tonic, Fury Liniment, Swift Tea) when the
  slot is free, else a Thermos. Packed before a dev run's kit, which then overwrites Thermoses.
- **Dev F4 profile.** Now also records two clears at depths 4 and 5, so every poster shows; the run
  door's F3 run on that profile finds Fairway's End and Head Office open.
- **Ending card.** Shown in `_end_run` after the 2 s message, saved as seen when it appears, closed by
  interact or attack after 1 s or by itself after 9 s.
