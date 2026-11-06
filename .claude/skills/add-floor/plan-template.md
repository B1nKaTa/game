# Plan template for a new floor

Write the plan as `docs/superpowers/plans/<date>-<floor>.md`. The worked example is
`docs/superpowers/plans/2026-11-03-third-floor.md`: copy its header (goal, architecture, tech
stack, spec link) and its **Global Constraints** section, then update the worktree path and the
testing state. Do not copy its tasks. Use the order below, which is the order that worked for
floor 3 (its Steps 2 to 5), and give every task a **Files**, an **Interfaces** (names and
signatures it produces) and a **Rules** or **numbers** block, failing tests first, then
implementation, then the run and look steps, then the commit.

Mark each "run" step "when testing is allowed". When testing is on hold, tick nothing that needs
Godot, and keep the owed list (see `docs/superpowers/plans/waiting-room-untested.md`).

`<N>` is the new depth, `<west>` and `<east>` the two path ids, `<floor>` a short test prefix per
path (floor 3 used `parlour` and `mall`).

---

## Step 1: The connection (placeholder content proves the depth)

### Task 1: Depth N, its landing, its Crossroads and the end of the run
Floor-3 model: plan Task 6.

- **Create:**
  - `data/floors/landing_<N>.tres`, copied from `landing_3.tres` (`id`, `display_name = "Floor N"`,
    `depth = N`).
  - `data/floors/<west>.tres` and `data/floors/<east>.tres` as placeholders: `rooms_dir` pointing at
    an existing folder (floor 3 pointed at `res://data/rooms/sunset_shores/`), the previous depth's
    enemies and bosses, but the new depth's `depth`, `open_after_depth`, `clears_to_open`, `danger`,
    `closed_hint`, `health_mult`, `pension_mult`, `enemies_by_size` and `chest_weights`.
- **Modify:**
  - `scripts/scenes/floor_scene.gd`: `PATHS_BY_DEPTH[N]`, `LAST_DEPTH := N`, `LANDINGS_BY_DEPTH[N]`.
    The previous depth's floor bosses now drop their two items and a stairwell through
    `_continue_after_floor`, with no other change.
  - `scripts/core/progress_data.gd`: `FIRST_PATH_BY_DEPTH[N]` and `PATHS_AT_DEPTH[N]`.
  - `tools/smoke_driver.gd`: `_clear_three_floors` becomes a four-floor walk; the check
    "a third-floor boss ends the run" moves to depth N; add checks that the landing says
    "Floor N", heals, that `<east>` refuses before a depth-N clear and opens after one. Raise
    `TIMEOUT` (1080 s; a floor-3 run took about 388 s before the Waiting Room checks) and report
    the new run time.
  - Optionally, if the user agreed: `scripts/core/dev_start.gd` (`START_DEPTH`, `CLEARS_BY_DEPTH`,
    `PATHS_CLEARED`, `ALL_PATHS`, `HINT`), `tests/test_dev_start.gd`, and `_check_dev_start` in
    the smoke driver, which names `"landing_3"` and `"flashback_cinema"` literally.
- **Test:** `tests/test_fourth_floor_unlocks.gd` (new), modelled on
  `tests/test_third_floor_unlocks.gd`: the open path is open, the locked one waits for a depth-N
  clear with its `closed_hint`, clears at depth N survive a save and an old save has none, the
  difficulty numbers, and the landing's name. Also `tests/test_crossroads.gd` and
  `tests/test_floor_unlocks.gd` must still pass.
- **Careful:** do **not** add the placeholder floors to the six-path lists in the Waiting Room
  tests yet (see Task 8). A placeholder that borrows earlier bosses would make
  `test_there_is_a_poster_for_every_mini_and_floor_boss` map those bosses to the new floor.

Push and stop for the user to try the connection before building content, as floor 3 did.

---

## Step 2 (and Step 3 for the second path): one path, complete

Read these as models first: the previous floor's `data/floors/*.tres`, its behaviors (for floor 3:
`reverend_behavior.gd`, `funeral_director_behavior.gd`, `fountain_diva_behavior.gd`,
`mall_santa_behavior.gd`, `florist_behavior.gd`, `pallbearer_behavior.gd`), its hazard
(`scripts/core/pipe_beat.gd` with `scripts/world/organ_pipe.gd`, or `scripts/core/conveyor_rule.gd`
with `scripts/world/conveyor_strip.gd`) and its tests (`tests/test_parlour_*.gd`).

### Task 2: The hazard
Floor-3 model: Tasks 10 and 15.
- **Create:** a pure rule in `scripts/core/<hazard>.gd` (timing, push or carry, as `PipeBeat`,
  `ConveyorRule`, `ConveyorCycle`, `VentCycle`), and its node in `scripts/world/<hazard>.gd`.
- **Modify:** `scripts/content/room_layout.gd` (a new symbol constant with a comment, added to
  `ALLOWED`, and to `SOLID_SYMBOLS`, `WALL_LIKE` or `WALLS` if it blocks; a `*_DOOR_CLEARANCE`
  and its check in `validate()`), `scripts/world/room_view.gd` (build it, and add any lingering
  node to `is_passing_effect`), `scripts/actors/player.gd` and `scripts/actors/enemy.gd` if it moves
  bodies (`Enemy.apply_push`, `Enemy.rides_strips`, `Enemy.hold_lane`).
- **Test:** `tests/test_<floor>_hazard.gd` (new): timing repeats and warns before it acts, each event
  fires once whatever the frame times, a dodge ignores it, it never carries a charge off its lane,
  and the symbol keeps its clearance from doors. When testing is allowed, screenshot a room with it.

### Task 3: Three regular enemies, plus two returning
Floor-3 model: Tasks 11 and 16.
- **Create:** `scripts/actors/behaviors/<name>_behavior.gd` (`class_name`, `extends EnemyBehavior`,
  a header comment saying what it does, constants for every number, statics for every pattern) and
  `data/enemies/<id>.tres` for each. Two returning enemies as new `.tres` files in the floor's
  colours (`<path>_<old_id>.tres`), keeping the old numbers.
- **Shared helpers** for groups go through members' metadata, as `MourningPack` and `WalkerLine` do.
- **Test:** `tests/test_<floor>_enemies.gd` (new), like `tests/test_parlour_enemies.gd`: every static,
  every warning leaves time to step out, returning enemies keep their numbers and take the floor's
  colours (`test_returning_enemies_keep_their_numbers_and_take_the_floors_colors`), and new enemies
  match the first-floor role they fill (`test_new_enemies_match_the_first_floor_role_they_fill`).
  Add the behaviors to `BEHAVIORS` in `tests/test_enemy_types.gd`.
- When testing is allowed, look at each in a real window. One commit per enemy, one for the pair.

### Task 4: The mini boss
Floor-3 model: Tasks 12 and 17.
- **Create:** `scripts/actors/behaviors/<name>_behavior.gd`, `data/enemies/<boss_id>.tres` with
  `is_boss = true` and `max_hp` = final health / `health_mult` (write 3 decimals, as 355.556).
- **Test:** `tests/test_<floor>_bosses.gd` (new): each attack's statics, the summon cap
  (`BossMoves.can_summon`), summons pay nothing, it alternates attacks, and
  `test_<name>_is_at_least_as_hard_as_<last depth's mini bosses>` comparing health, rest and windups.
- When testing is allowed, screenshot every attack in a real window.

### Task 5: The floor boss
Floor-3 model: Tasks 13 and 18.
- **Create:** behavior and `.tres` as above. Its heaviest attack uses `Enemy.HEAVIEST_DAMAGE` with
  `set_warning(..., true)` and `Enemy.mark_lane_heaviest` or a second ring. Phase two below half
  health: 1.2x speed, 0.8x windups except the heaviest, shorter rests, one chained followup.
- **Test:** in `tests/test_<floor>_bosses.gd`: the heaviest attack costs 3 and its warning shows
  whole, any single safe spot always exists over 200 seeds and is marked, every lane or gap stays
  inside the room, phase two chains its followup, and
  `test_<name>_is_clearly_harder_than_<last depth's floor bosses>`.
- When testing is allowed, screenshot every attack, the heaviest warning above all.

### Task 6: Floor content
Floor-3 model: Tasks 14 and 19.
- **Palette:** a `RoomPalette` sub-resource in the FloorDef. New colour fields go in
  `scripts/content/room_palette.gd`; new patterns in `scripts/world/room_backdrop.gd`
  (`floor_pattern`, `wall_pattern`); new decor kinds in `scripts/content/room_decor.gd`.
- **Props:** scripts in `scripts/world/` extending the right base: `Barrel` (cane breaks it),
  `RockBlock` (blasts and bosses only, can hide a coin at the furniture rate), or `BreakableBlock`
  for a stand that blocks nothing and breaks to anything (as `WreathStand`, `SaleSign`). New symbols in `room_layout.gd` (`ALLOWED`, `SOLID_SYMBOLS`,
  `WALLS_AND_BOMB_ONLY` for rock-like ones, `DECOR_SYMBOLS` for decor).
- **Layouts:** about 33 in `data/rooms/<path_id>/`. Follow `layouts.md`.
- **FloorDef:** the 3 new and 2 returning enemies with `enemy_weights`, `mini_boss`, `floor_boss`,
  `mimic`, `treasure_pension` (16 on floor 3, twice floor 1's 8), `extra_enemy_steps`, and Task 1's
  numbers.
- **Test:** `tests/test_<floor>_floor.gd` (new), modelled on `tests/test_parlour_floor.gd`: the path,
  difficulty, its own enemies and bosses, enemies told apart, it looks like no other floor, every
  layout valid, combat rooms hold the depth's enemy counts, every room type covered, its props and
  hazard appear where the spec says, props break as the spec says,
  `test_every_built_floor_follows_the_same_rules_as_the_first` over 300 seeds, and vault extras fit.
  `tests/test_boss_spawn_room.gd` picks up the new rooms by itself, since it walks
  `res://data/floors/`.
- **Also extend** the folder lists in `tests/test_chests.gd` (line ~281) and `tests/test_shop.gd`
  (line ~115), and the floor list in `tests/test_arcade_room.gd`.
- **Income:** measure Pension per full clear with and without blasting (see `checklist.md`). Floor 3
  paid about 258 and 271 against Sunset Shores' 231.
- When testing is allowed: tests, 3 full loops, and screenshots of small, medium and large rooms next
  to the previous floor's. Update `docs/playtest-notes.md`, push, stop for the user to play.

Repeat Tasks 2 to 6 for the second path. Do not reuse the first path's room shapes without asking:
the Mall reused the Parlour's, and the user was left to decide whether it feels samey.

---

## Step 4: Waiting Room hooks

### Task 7: The hooks for both paths
None of these existed when floor 3 was built. Every name below is on the `waiting-room` branch.

- **Department** (one per path, opened on its first clear): an entry in `Departments.ALL`
  (`scripts/core/departments.gd`) with `id`, `name`, `cell` on the department grid, `layout`,
  `opens_on` (the path id) and `arrival` line; a link in `Departments.LINKS` so it is reachable
  through the lobby and hallway alone; the path's display name in `Departments.FLOOR_NAMES`; its
  layout in `data/rooms/waiting_room/<id>.tres`; any stations in `Departments.STATIONS` and NPCs in
  `Departments.NPCS` (`data/npcs/*.tres`).
- **Memento and perk** (floor boss only): an entry in `Mementos.ALL` (`scripts/core/mementos.gd`)
  with `boss` (the EnemyDef id), `boss_name`, `short_name`, `path`, `memento`, `perk`, `perk_text`;
  a new `*_PERK` constant and its number; the perk applied where it acts (as
  `RunState.has_perk` in `scripts/core/run_state.gd`, `floor_scene.gd`, `room_view.gd`); and its
  drawing in `scripts/world/trophy_wall.gd`. Two more frames must still clear the north door and
  the lanterns (`test_the_frames_keep_clear_of_the_north_door_and_the_lanterns`).
- **Wanted posters:** `data/bounties/<boss_id>.tres` for the mini boss and the floor boss
  (`BountyDef`, `scripts/content/bounty_def.gd`). The file's `id` **is** the boss's EnemyDef id.
  `pension = (100 if floor_boss else 40) * depth`, `condolences = 20 if floor_boss else 10`, and an
  `extra_kind` of `item`, `recipe` or `cosmetic` with a real `extra_id` (a `from_bounty` item in
  `data/items/`, a recipe, or a `data/cosmetics/` entry).
  `test_the_extras_are_four_of_each_kind_and_all_real` pins 4/4/4 over 12 posters, so agree the new spread with the user and update the test.
- **Letter:** an entry in `LetterBook.LETTERS` (`scripts/core/letter_book.gd`), keyed by path id.
- **Condolences on first beats** need no new code: `ProgressData.record_boss_beaten` pays
  `FIRST_MINI_BOSS_CONDOLENCES` (5) or `FIRST_FLOOR_BOSS_CONDOLENCES` (10) once per boss id. Check
  both new bosses have `is_boss = true` and distinct ids.
- **Tests to extend** (each holds the six current path ids or counts): `tests/test_bounties.gd`
  (`_floors()` and the `12`), `tests/test_mementos.gd` (the `6`), `tests/test_departments.gd`
  (the `cases` table), `tests/test_tickets_and_letters.gd` (`test_every_path_has_a_letter`),
  `tests/test_dev_start.gd`. The smoke driver's Waiting Room checks (`_walk_every_department`,
  `_check_departments_at_start`) must still pass.
- When testing is allowed: screenshot the new department, the trophy wall with every frame, and the
  bounty panel with every poster (F4 opens all departments), since the view is 360 px tall.

---

## Step 5: Balance and review

### Task 8: Balance pass
Floor-3 model: Task 20. Teach the balance bot each new hazard and attack, measure both bosses of each
path and whole floors on the "some" and "max" saves, tune only health, windups, rests and summon
timers first, and write before and after in `docs/playtest-notes.md`. See `checklist.md`.

### Task 9: Independent review
Floor-3 model: Task 21. One reviewer on the strongest model, read-only, over
`git diff <base>...<floor-branch>` against the spec, forbidden to run Godot or touch the real save.
Verify each finding by reading the code, fix confirmed ones one commit each with tests, then run
the tests and full loops again, push, and write the report.
