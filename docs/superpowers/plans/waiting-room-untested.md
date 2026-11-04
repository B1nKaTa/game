# Waiting Room overhaul: what has not been run yet

On 2026-11-04 the user put testing on hold. Everything on `waiting-room` from 3d1f790 onward is written but has never been parsed or run by Godot. Run all of it together when testing resumes, and expect small compile fixes on the first run.

## Test files to run
- Chunk 1 (Tasks 1–6):
  - new: `tests/test_save_migration.gd` with its fixture `tests/fixtures/save_v1_2026-11-04.json`, `tests/test_departments.gd`, `tests/test_mementos.gd`
  - changed: `tests/test_dev_start.gd`

## Watch for on the first run
- **Arrays:** typed versus untyped array equality in `assert_eq(open_ids(...), [..])`.
- **Constant data:** the nested dictionaries in `const ALL: Array[Dictionary]`, the constant entries of `Departments.STATIONS`, and `merchant.duplicate()` of constant dictionaries in `waiting_room.gd`.
- **The full loop and mementos:** once mementos hang, later runs change Pension and pill counts. The name badge adds 10 Pension at run start, the bedpan heals an extra pill, and the coal shovel and top hat change pills. Adjust the loop's exact-number checks.
- **Arrival notice:** the "New departments open: …" line with five names may be wider than 640 px.
- **Back Room tables:** the `G` cells don't build tables yet. That is Task 19 or 21.
- **Seeing the departments in a dev run:** the dev profile exists only during a dev run. To look at the departments with everything open, call `Progress.begin_dev_run(DevStart.progress(..., ["--dev-all-departments"]))`, then load `waiting_room.tscn`.

## Things to look at in play
- Lobby layout: the run door is at (26,8), inside the room, and the trophy wall is at (20,3).
- The trophy wall shows one notice per memento.

## Chunk 2 (Tasks 7–10)

Written on 2026-11-04, from 149fec2 to e716e52. None of it has been parsed or run.

### Test files to run
- new: `tests/test_forms.gd` (Tasks 7, 8 and 9) and `tests/test_condolences.gd`
- changed: `tests/test_stats.gd`, `tests/test_dentures.gd` (option A's +0.25 bite from level 2 is now expected), `tests/test_floor_map_view.gd`, `tests/test_save_migration.gd` and `tests/test_hud.gd`

### Watch for on the first run
- **The upgrade `.tres` files:** each now has two `stat_effect.gd` sub-resources and `load_steps=5`. Check that all seven load, and that `Content.upgrades()` still finds seven.
- **`PlayerStats` names `Thermos.BLAST_RADIUS`:** a core script now reaches a world node class. If that makes a load cycle, move the constant somewhere neutral.
- **Shipped forms now apply option A from their milestone:** any existing check built on shipped upgrades at level 2 or more can shift. `test_dentures` is updated. In the full loop's dev run, every form is maxed, so Grandpa has the cane swinging at 0.9 speed, one more pill, +20% enemy Pension, a bigger blast and harder bites. Look for exact-number checks there.
- **Pension sources:** boss coins and chest coins now use the reward rate and enemy coins the enemy rate. With no Bribed Clerk at level 2 or more nothing changes, but the full loop's Pension checks should be reread.
- **`Health.heal_bonus`** applies to every heal that restores anything, potions and healing rooms included.
- **The weak spot:** `PlayerStats.strike_damage` divides `enemy.hp` by `maxf(enemy.max_hp(), 1.0)`. Check that `hp` is the live value and not scaled in some other way.
- **Calls on `_bank`:** `RoomView` calls `_bank.add_condolences` on a `Node`-typed `_bank`, the same duck-typed pattern it already uses for `spend`.
- **Two notices at once:** a chest's "+3 Condolences" notice replaces the chest's own line, and a boss's "+N Condolences" can land at the same moment as other boss notices.

### Screenshots still owed (the plan asks for them)
- The Black Market panel at its fullest: five forms, a milestone row showing both "File:" buttons, and the FILED stamp mid-animation. The panel is 600 px wide at (20,16), with 10 px row text.
- The Optometrist panel: Prescription Glasses has its milestone at level 1, so the first purchase is the choice.
- The refile panel with all seven forms.
- The HUD in the Waiting Room with 9999 Pension and 9999 Condolences, and during a run with a "+N Condolences" pop-up.
- The Night Vision map: an unfound secret room as an outline with a "?", on both the mini map and the big map.
- The forms counter board at lobby (11,3), between the Black Market (6,3) and the north door.

### Things to look at in play
- Heavy Head (0.9 swing speed) only stretches the lock between swings. The attack animation still plays for `CaneCombo.LOCK_TIME`.
- The Long Stride dodge lasts 0.26 s instead of 0.2 s, and the dodge ghosts follow it.
