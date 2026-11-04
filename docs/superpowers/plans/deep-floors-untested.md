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
