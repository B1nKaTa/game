# Waiting Room Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The Waiting Room becomes a small floor of departments on the run floors' room grid, each opened by the first clear of a floor. Upgrades become stamped forms with a choice at one milestone. Bosses hang mementos on a trophy wall. A Bounty Office pays for wanted posters in Pension and a new cosmetic currency, Condolences. A Training Yard lets Grandpa try earned recipes on a dummy. A Decor Office sells decor and Grandpa cosmetics. The queue ticket calls events, letters arrive, and the Dealer keeps a back room.

**Architecture:**
- **Departments:** `Departments` (pure) lists each department, its grid cell, its layout, what opens it and which stations stand in it. `Departments.build_map()` makes an ordinary `FloorMap` of `TYPE_DEPARTMENT` rooms, and `waiting_room.gd` shows each one with the same `RoomView`, `Door` and `RoomCamera` the run floors use. A closed department's door is `chained`.
- **Stations:** every counter, board and merchant is a `WaitingStation` node placed by the scene from `Departments.STATIONS`. The scene finds the nearest one in reach and opens its panel, as today's `_merchant_in_range` does.
- **Forms:** each `UpgradeDef` gains a `milestone_level` and two `StatEffect` sub-resources. `PlayerStats.compute` adds the chosen option's effect once the milestone is filed. Choices live in `ProgressData.form_choices`, where a missing entry means option A.
- **Rewards:** `Mementos`, `BountyBoard`, `TicketRules`, `LetterBook` and `CoachTips` are pure `RefCounted` rules with headless tests. They read and write only `ProgressData`. `Progress` wraps each in a saving call, as it already does for crafting and brewing.
- **Save:** `ProgressData.VERSION` stays 1. Every new field is optional with a fallback, so an old save loads unchanged and upgrades already bought carry over.

**Tech Stack:** Godot 4.7.2 standard, GDScript, `gl_compatibility`, 640×360 viewport, nodes built in code, `.tres` data, headless tests.

**Spec:** `docs/superpowers/specs/2026-11-04-waiting-room-overhaul-design.md`. Read it before any task. The spec governs where this plan is silent.

## Decisions made in this plan

The spec leaves these open. Each is the plan's choice, and the user can veto any of them before work starts.

1. **A Hallway joins the lobby to three departments.** The lobby has only four sides, and six departments must each be reachable on their own, whatever order floors are cleared in. The Hallway is open from the start and holds nothing.
   - Lobby: Bounty Office north, Training Yard east, Back Room south, Hallway west.
   - Hallway: Apothecary Wing north, Boiler Room south, Decor Office west.
2. **The run door stands inside the lobby, not in a wall**, since all four lobby walls lead to departments.
3. **A department that holds a merchant also opens when that merchant's own rule opens.** Old saves opened Madame Murk and Boom Bernard by `legacy_clears`, without the path ids, so this keeps them reachable.
4. **Old saves get their first path of each depth filled in.** A save with `floors_cleared >= 1` and no `paths_cleared` entry at depth 1 gets `floor_1`, since only that path is open before a first clear. The same applies to `sunset_shores` for a depth-2 clear and `funeral_parlour` for a depth-3 clear.
5. **The milestone is level 2** of every three- and four-level form, and level 1 of Prescription Glasses, which has only one level.
6. **The option values:**

   | Form | Option A | Option B |
   |---|---|---|
   | Reinforced Cane | Heavy Head: +15% cane damage, swings 10% slower | Lightweight: swings 20% faster, −5% cane damage |
   | Better Knees | Long Stride: the dodge lasts 30% longer | Quick Recovery: dodge cooldown cut by a further 15% |
   | Black Market Pills | One more pill | Every heal restores one extra pill |
   | Bribed Clerk | +20% Pension from enemies | +30% Pension from chests, treasure and bosses |
   | Prescription Glasses | Bifocals: +20% damage to enemies below half health (the weak spot) | Night Vision: secret rooms show on the map |
   | Denture Adhesive | Bite: +25% bite damage | Boomerang: the teeth come back 1 s sooner |
   | Questionable Fuel | Big Bang: blast radius +30% | Spare Can: one more Thermos at the start of each run |

7. **Refiling costs a flat 40 Pension.** Every form gets one free switch, new players included, since that is simpler than tracking which saves came from before the overhaul.
8. **The memento perks, and their numbers:**
   - **Name badge:** +10 Pension at the start of each run.
   - **Bent shovel:** coin chances from breakables ×1.25.
   - **Bedpan:** the first heal of each run restores 1 extra pill.
   - **Coal shovel:** every second hit from a fire hazard (vents, burns, steam) is shrugged off.
   - **Top hat:** heal 1 pill on first entering a mini-boss or floor-boss room.
   - **Empty sack:** treasure rooms lay out one more item to choose from.
9. **Mementos come from `paths_cleared`, so old saves hang theirs at once.** First-beat Condolences are paid only for beats from now on, never back-paid.
10. **Condolences amounts:**
    - First beat of a mini boss: 5. First beat of a floor boss: 10.
    - Poster: 10 for a mini boss, 20 for a floor boss.
    - Each floor cleared in a cursed run: 10.
    - A chest opening: a 5% chance of 3.
11. **Poster Pension is 40 × depth for a mini boss and 100 × depth for a floor boss.** That gives 40/100, 80/200 and 120/300 by depth.
12. **The poster extras** (4 items, 4 recipes and 4 cosmetics):

    | Poster | Extra |
    |---|---|
    | Senior Adjuster | recipe: Support Stockings |
    | Regional Reaper | cosmetic: Reaper's Hood (hat) |
    | Gus, Head Groundskeeper | recipe: Titanium Hip |
    | Digby, Tired Undertaker | item: Undertaker's Work Gloves |
    | Barbara, Activities Coordinator | cosmetic: Bingo Night Teal (cardigan) |
    | Matron Mercy | item: Comfort Care Lanyard |
    | Foreman Klaus | recipe: Nitroglycerin Tablets |
    | Old Smokey | cosmetic: Sooty Cane (cane skin) |
    | The Reverend | recipe: Medical Alert Bracelet |
    | Mortimer Grimsby | item: Funeral Director's Pocket Watch |
    | Gloria | cosmetic: Fountain Coin Tiara (hat) |
    | The Mall Santa | item: The Naughty List |

    If a recipe extra is already found, the poster pays half its Pension again instead.
13. **The unique items use existing stats only:**
    - Gloves: +20% cane damage.
    - Lanyard: +1 pill and +0.1 warning.
    - Pocket Watch: dodge cooldown −15% and speed +5%.
    - Naughty List: +25% Pension.
14. **A poster is taken for good.** There is no way to drop one. Only posters for floors Grandpa can reach can be taken, so he can never get stuck with one he cannot finish.
15. **The Training Yard rack lists found recipes only**, as the spec says, not bounty items. In the yard, Thermoses are topped up to 99 after every throw.
16. **The first decor set all goes in the lobby**, the one department always open. Each item has a fixed spot, with no free placing:
    - a potted fern (20)
    - a motivational poster (15)
    - a better chair (40)
    - warm lamps (30)
    - a fish tank (60)
    - a new carpet (50)
17. **The cosmetics on sale, priced in Condolences:**
    - Hats: flat cap (30), party hat (40).
    - Cardigans: mustard (25), burgundy (25).
    - Canes: polished oak (35), candy stripe (45).
    - The four bounty cosmetics are never sold.
    - Placeholders are code-drawn: a hat shape over the head, a coloured cardigan band over the chest, and a tinted cane line and swing arc.
18. **The Decor Office has a counter, not a named clerk**, since the spec names no one. Cosmetics are worn from the same panel.
19. **Ticket events:**
    - The ticket is `run_count`, and every 5th run is called. The events cycle in order: clerk deal (5, 20, …), new arrival (10, 25, …), cursed ticket (15, 30, …).
    - Old saves start with every past ticket counted as called, so nothing fires back-dated.
    - The clerk deal takes 25% off one form that is not yet maxed, for that visit.
    - The cursed run gives enemies ×1.25 health and ×1.5 Pension.
20. **Letters come from `paths_cleared`**, one per path, so old saves receive theirs at once. The text is a one-line placeholder.
21. **New departments are announced in one notice** on the next visit ("New departments open: …"), followed by each one's arrival line, one at a time.
22. **The Back Room has two tables, Blackjack and Draw Poker, with the Arcade's house edge.** He deals cards, so the slot machine stays in the Arcade. The tables refill on every visit to the Back Room.
23. **The loadout bench is a reserved 3×2 patch of plain floor in the Back Room** (`Departments.LOADOUT_BENCH_CELLS`), with nothing drawn and nothing to use.
24. **The Waiting Room has no mini map.** Each door carries a department name sign instead, and a closed door says which floor opens it.
25. **NPC lines are placeholders**, three to five each, for Deputy Dolores, Coach Bertram and the Dealer's back room.

## Global Constraints

- Never name another game in any file, comment, asset name or commit message.
- Ask before adding dependencies or add-ons. None are needed.
- Commit messages are in the imperative mood, one logical change per commit, and end with a blank line and then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Use a PowerShell here-string with `git commit -m @'...'@` (never `-F -`; see `LESSONS.md`).
- Read `LESSONS.md` before each task, and append dated lessons (`- 2026-11-04: <what happened> → <rule>`) when something tricky comes up.
- Leave the project runnable after every commit.
- **Save compatibility:**
  - Old saves must load. `ProgressData.VERSION` stays 1, and every new save field is optional with a fallback.
  - Upgrades already bought carry over.
  - Each milestone choice of an old save reads as option A, with one free switch.
- Data lives in `.tres` files, nodes are built in code, and pure rules are `RefCounted` with headless tests. Scripts loaded by tests must not reference autoloads, so pass `Progress` in as `_bank`, as `RoomView` already does.
- **Condolences buy only looks and never gameplay power.** Regular enemies never pay them.
- Use the names exactly as given: Deputy Dolores, Overdue Accounts; Coach Bertram, Retired PE Teacher; the Dealer; Digby, Tired Undertaker.
- Art is placeholder only and code-drawn. Spend no PixelLab generations.
- **Screens:** screenshot every new panel at its fullest, since the 360 px screen hides tall panels. Give any overlay that covers most of the screen its own opaque backing.
- **Running Godot:** run Godot in any form only after the user has said testing is on. Even then, never launch it while the user's game window is open. Check first:

  ```powershell
  Get-CimInstance Win32_Process -Filter "Name like 'Godot%'" | Select-Object ProcessId, CommandLine
  ```

  A process whose command line has no `--headless` and points at a project path is the user's game. Until testing is on, write code and tests, leave the "run" boxes unticked, and note that new scripts have no `.uid` file until the first import.
- **The real save:** `%APPDATA%\Godot\app_userdata\Grandpa\save.json` must stay untouched. Never run a scene without `--smoke` or the dev shortcut's throwaway profile. Read its MD5 before and after any session that runs Godot (`Get-FileHash -Algorithm MD5`).
- Commands, run from `C:\GameDev\game\.worktrees\waiting-room`:

  ```powershell
  powershell -File tools/test.ps1   # ends with "N tests, 0 failed"
  powershell -File tools/smoke.ps1  # prints "SMOKE PASS ..." or "SMOKE FAIL: ..."
  ```

  Read the summary line, not a piped exit code. After a run, `git checkout -- art/sprites` clears line-ending-only `.import` churn.
- **Repeated full-loop runs:** export the commit with `git archive` and rename `config/name` in the copy, so it gets its own user folder.
- **Files and line endings:**
  - The worktree checks files out with CRLF. Make multi-line changes with the Edit tool, end single-line sed patterns with `\r\?$`, and never use PowerShell `Set-Content` on text or `.tres` files.
  - Write new large files with the Write tool.

---

## File structure

**New pure rules (`scripts/core/`):**
- `departments.gd`: the department table, links, stations and merchants, plus `build_map`, `is_open` and `newly_opened`.
- `mementos.gd`: the boss-to-path mapping, which mementos hang, and the perk ids.
- `bounty_board.gd`: which posters show, taking, winning and collecting.
- `ticket_rules.gd`: which event a ticket calls, and the clerk deal pick.
- `letter_book.gd`: the letters that have arrived, and which are unread.
- `coach_tips.gd`: Coach Bertram's lines.
- `form_text.gd`: the text on a form row and on a refile row.

**New content scripts (`scripts/content/`):** `bounty_def.gd` and `cosmetic_def.gd`.

**New nodes:**
- `scripts/world/`: `waiting_station.gd`, `department_sign.gd`, `trophy_wall.gd`, `lobby_decor.gd`, `grandpa_look.gd` and `training_dummy.gd`.
- `scripts/actors/behaviors/dummy_behavior.gd`.

**New panels (`scripts/ui/`):**
- `refile_panel.gd`
- `bounty_panel.gd`
- `item_rack_panel.gd`
- `decor_panel.gd`
- `noticeboard_panel.gd`
- `ticket_panel.gd`

**New data:**
- `data/rooms/waiting_room/`: eight department layouts.
- `data/floors/waiting_room.tres`
- `data/bounties/`: 12 posters.
- `data/cosmetics/`: 4 bounty cosmetics, 6 on sale and 6 decor.
- `data/items/`: 4 bounty items.
- `data/npcs/`: `deputy_dolores.tres`, `coach_bertram.tres` and `dealer_back_room.tres`.
- `data/enemies/training_dummy.tres`

**Changed:**
- Save: `scripts/core/progress_data.gd` and `scripts/autoload/progress.gd`.
- Stats: `scripts/content/stat_effect.gd`, `scripts/content/upgrade_def.gd`, `scripts/content/item_def.gd`, `scripts/core/player_stats.gd`, `scripts/core/run_state.gd` and `scripts/core/health.gd`.
- Combat rules: `scripts/core/cane_combo.gd` and `scripts/core/dodge_timer.gd`.
- `scripts/content/room_layout.gd`: `TYPE_DEPARTMENT`.
- Play: `scripts/actors/player.gd`, `scripts/world/thermos.gd` and `scripts/world/room_view.gd`.
- Rules and screens: `scripts/world/room_rules.gd`, `scripts/ui/floor_map_view.gd`, `scripts/ui/hud.gd` and `scripts/ui/merchant_panel.gd`.
- Npcs: `scripts/world/npc.gd` (`set_lines`).
- Scenes: `scripts/scenes/waiting_room.gd` (rewritten) and `scripts/scenes/floor_scene.gd`.
- All seven `data/upgrades/*.tres`, `data/npcs/dealer.tres` and `tools/smoke_driver.gd`.

**New tests (`tests/`):**
- `test_save_migration.gd` and its fixture `fixtures/save_v1_2026-11-04.json`
- `test_departments.gd`
- `test_forms.gd`
- `test_mementos.gd`
- `test_condolences.gd`
- `test_bounties.gd`
- `test_training_yard.gd`
- `test_cosmetics.gd`
- `test_tickets_and_letters.gd`

---

## Step 0: Base

### Task 1: Rebase onto the third floor with the dev shortcut, and open every department in its profile

The dev shortcut is being built on `third-floor` by another agent: debug builds only, a run that starts at floor 3 with every upgrade at max level, and a separate throwaway save. This plan does not build a shortcut. It rebases onto it and extends it only where the departments need it.

**Files:**
- Modify: the shortcut's profile-seeding code. Find it with `git grep -n "is_debug_build" -- scripts tools`.
- Test: the shortcut's own test file, which gets one new test.

**Interfaces:**
- Produces: a user argument `--dev-all-departments`. Within the shortcut's throwaway profile only, it marks all six path ids cleared (`floor_1`, `cemetery`, `sunset_shores`, `furnace_works`, `funeral_parlour`, `golden_years_mall`), so every department is open at once from Task 4 onwards.

- [x] **Step 1: Check the shortcut has landed.** `git log --oneline third-floor -10` must show the shortcut's commits. If they are not there yet, stop and tell the controller. Do not touch `third-floor`.

- [x] **Step 2: Rebase.**

  ```powershell
  git -C C:\GameDev\game\.worktrees\waiting-room rebase third-floor
  ```

  The only commit on `waiting-room` is this plan, so no conflict is expected. Then read the shortcut's code and test, and note its seeding function, its profile path and how it is launched.

- [x] **Step 3: Write the failing test** in the shortcut's test file. Use the shortcut's real seeding function name in place of `seed_profile` below:

  ```gdscript
  func test_all_departments_flag_clears_every_path_in_the_throwaway_profile_only() -> void:
  	var data := ProgressData.new()
  	# seed_profile is the shortcut's own seeding call. Pass the flag the way it passes its others.
  	seed_profile(data, PackedStringArray(["--dev-all-departments"]))
  	for id in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "golden_years_mall"]:
  		assert_true(data.has_cleared_path(id), id)
  ```

  Also assert that the shortcut's profile path is not `Progress.SAVE_PATH` with the flag set, if the shortcut's test does not already cover that.

- [ ] **Step 4: When testing is allowed, run it to make sure it fails.**

- [x] **Step 5: Implement.** In the seeding function, when the flag is present, call `data.record_floor_cleared(depth, id)` for each of the six paths at its depth (1, 1, 2, 2, 3, 3). Keep it inside the same `OS.is_debug_build()` gate and the same throwaway profile as the rest of the shortcut. Add one line on the flag to wherever the shortcut documents its launch.

- [ ] **Step 6: When testing is allowed, run the tests.** Expected: `N tests, 0 failed`. Compare the real save's MD5 before and after.

- [x] **Step 7: Commit.**

  ```powershell
  git commit -m @'
  Let the dev shortcut open every department at once

  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  '@
  ```

### Task 2: Save fields and the migration test

Every new save field is added here at once, with its fallback, so each later task only adds behaviour. The fixture is a save in today's exact format.

**Files:**
- Modify: `scripts/core/progress_data.gd`
- Create: `tests/fixtures/save_v1_2026-11-04.json`, `tests/test_save_migration.gd`

**Interfaces:**
- Produces new `ProgressData` fields, each with its fallback when a save lacks it:

  | Field | Type | Fallback |
  |---|---|---|
  | `form_choices` | `Dictionary` (form id → `"a"` or `"b"`) | `{}`, read as `"a"` |
  | `free_refile_used` | `Dictionary` (form id → `true`) | `{}` |
  | `condolences` | `int` | `0` |
  | `bosses_beaten` | `Dictionary` (EnemyDef id → `true`) | `{}` |
  | `bounty_taken` | `String` (BountyDef id) | `""` |
  | `bounty_won` | `bool` | `false` |
  | `bounties_retired` | `Dictionary` | `{}` |
  | `cosmetics_owned` | `Dictionary` | `{}` |
  | `cosmetics_worn` | `Dictionary` (slot → cosmetic id) | `{}` |
  | `departments_seen` | `Dictionary` | `{}` |
  | `coach_met` | `bool` | `false` |
  | `ticket_called` | `int` | `run_count` |
  | `clerk_deal` | `String` (form id) | `""` |
  | `cursed_offer` | `bool` | `false` |
  | `cursed_next_run` | `bool` | `false` |
  | `letters_read` | `Dictionary` | `{}` |

- Produces `ProgressData.FIRST_PATH_BY_DEPTH := {1: "floor_1", 2: "sunset_shores", 3: "funeral_parlour"}` and the private `_infer_first_paths()`.

- [x] **Step 1: Write the fixture.** `tests/fixtures/save_v1_2026-11-04.json` is what `to_dict()` writes today, filled in as a mid-game save:

  ```json
  {"version": 1, "pension": 312, "upgrades": {"reinforced_cane": 3, "better_knees": 1, "black_market_pills": 2, "bribed_clerk": 2, "prescription_glasses": 1, "thermos_fuel": 2},
   "opening_seen": true, "retirement_balance": 60, "retirement_peak": 100, "run_count": 23, "retirement_deposit_run": 21,
   "recipes_found": {"titanium_hip": true, "bifocals": true}, "items_unlocked": {"titanium_hip": true}, "crafted_for_next_run": "",
   "floors_cleared": 4, "deep_clears": {"2": 2, "3": 1}, "paths_cleared": {"floor_1": true, "cemetery": true, "sunset_shores": true, "furnace_works": true, "funeral_parlour": true},
   "legacy_clears": 0, "brewed_potion": "swift_tea"}
  ```

- [x] **Step 2: Write the failing tests** in `tests/test_save_migration.gd`:

  ```gdscript
  extends TestCase

  const FIXTURE := "res://tests/fixtures/save_v1_2026-11-04.json"


  func _today() -> ProgressData:
  	var json := JSON.new()
  	assert_eq(json.parse(FileAccess.get_file_as_string(FIXTURE)), OK, "the fixture is valid JSON")
  	return ProgressData.from_dict(json.data)


  func test_a_save_in_todays_format_loads() -> void:
  	var data := _today()
  	assert_true(data != null, "loads")
  	assert_eq(data.pension, 312)
  	assert_eq(data.run_count, 23)
  	assert_eq(data.brewed_potion, "swift_tea")


  func test_bought_upgrades_carry_over() -> void:
  	var data := _today()
  	assert_eq(data.level_of("reinforced_cane"), 3)
  	assert_eq(data.level_of("black_market_pills"), 2)
  	assert_eq(data.level_of("denture_adhesive"), 0)


  func test_new_fields_start_empty() -> void:
  	var data := _today()
  	assert_eq(data.condolences, 0)
  	assert_eq(data.form_choices.size(), 0)
  	assert_eq(data.bounty_taken, "")
  	assert_false(data.cursed_next_run)
  	assert_eq(data.ticket_called, 23, "no ticket event fires back-dated")


  func test_a_round_trip_keeps_every_new_field() -> void:
  	var data := _today()
  	data.condolences = 7
  	data.form_choices = {"reinforced_cane": "b"}
  	data.bounty_taken = "regional_reaper"
  	data.cosmetics_worn = {"hat": "flat_cap"}
  	var again := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
  	assert_eq(again.condolences, 7)
  	assert_eq(again.form_choices["reinforced_cane"], "b")
  	assert_eq(again.bounty_taken, "regional_reaper")
  	assert_eq(again.cosmetics_worn["hat"], "flat_cap")


  func test_a_save_from_before_paths_gets_its_first_paths() -> void:
  	var raw := {"version": 1, "pension": 0, "upgrades": {}, "opening_seen": true, "floors_cleared": 2, "deep_clears": {"2": 1}}
  	var data := ProgressData.from_dict(raw)
  	assert_true(data.has_cleared_path("floor_1"))
  	assert_true(data.has_cleared_path("sunset_shores"))
  	assert_false(data.has_cleared_path("cemetery"), "a second first-floor clear may have been the same path")


  func test_bad_new_fields_fall_back() -> void:
  	var raw := {"version": 1, "pension": 0, "upgrades": {}, "opening_seen": true, "condolences": -5, "form_choices": {"reinforced_cane": "z"}, "bounty_taken": 3}
  	var data := ProgressData.from_dict(raw)
  	assert_eq(data.condolences, 0)
  	assert_false(data.form_choices.has("reinforced_cane"), "only a or b is kept")
  	assert_eq(data.bounty_taken, "")
  ```

  Later tasks append milestone, department, memento and letter checks to this file.

- [ ] **Step 3: When testing is allowed, run them to make sure they fail.** Expected: unknown members `condolences`, `form_choices`, `ticket_called`, and the first-path test fails.

- [x] **Step 4: Implement.**
  - Declare each field with a one-line comment.
  - Write each to `to_dict()`.
  - Read each in `from_dict()` with type checks, as the existing fields are read:
    - Dictionaries go through `_id_set`.
    - `form_choices` keeps only the values `"a"` and `"b"`.
    - Ints are clamped at 0, except `ticket_called := maxi(int(raw.get("ticket_called", data.run_count)), 0)`.
    - Strings fall back to `""` when not a `String`.
  - At the end of `from_dict()` call `data._infer_first_paths()`:

  ```gdscript
  # A save from before paths were kept has its clears but no path ids. At each depth only one path is
  # open before that depth's first clear, so that one must have been it.
  func _infer_first_paths() -> void:
  	for depth: int in FIRST_PATH_BY_DEPTH:
  		var id: String = FIRST_PATH_BY_DEPTH[depth]
  		if clears_at(depth) > 0 and not _has_path_at_depth(depth):
  			paths_cleared[id] = true


  func _has_path_at_depth(depth: int) -> bool:
  	for id in PATHS_AT_DEPTH[depth]:
  		if paths_cleared.has(id):
  			return true
  	return false
  ```

  Add `const PATHS_AT_DEPTH := {1: ["floor_1", "cemetery"], 2: ["sunset_shores", "furnace_works"], 3: ["funeral_parlour", "golden_years_mall"]}` with a comment that it mirrors `floor_scene.gd`'s `PATHS_BY_DEPTH` by id. `ProgressData` must not load FloorDefs.

- [ ] **Step 5: When testing is allowed, run the tests.** Expected: `0 failed`, `test_save.gd` included.

- [x] **Step 6: Commit** ("Add the Waiting Room save fields with fallbacks for old saves").

---

## Step 1: Departments on the room grid, and the trophy wall

### Task 3: The department rules and layouts

**Files:**
- Create: `scripts/core/departments.gd`, `data/rooms/waiting_room/` (eight layouts), `data/floors/waiting_room.tres`
- Modify: `scripts/content/room_layout.gd` (`TYPE_DEPARTMENT`), `scripts/world/room_rules.gd` (`ICONS`)
- Test: `tests/test_departments.gd` (new)

**Interfaces:**
- Produces:
  - `RoomLayout.TYPE_DEPARTMENT := "department"`, with `REQUIRED[TYPE_DEPARTMENT] = {}`, and `FloorRoom.is_detour()` unchanged.
  - `Departments.LOBBY := "lobby"`, `HALLWAY`, `BOUNTY_OFFICE`, `TRAINING_YARD`, `APOTHECARY_WING`, `BOILER_ROOM`, `DECOR_OFFICE` and `BACK_ROOM` (string ids).
  - `Departments.ALL: Array[Dictionary]`. Each entry is `{"id", "name", "cell": Vector2i, "layout": String, "opens_on": String path id or "", "merchant": String or absent, "arrival": String}`.
  - `Departments.LINKS: Array` of id pairs.
  - `Departments.MERCHANTS`: today's `waiting_room.gd` `MERCHANTS` moved here unchanged, each with an added `"department"` key.
  - `Departments.STATIONS: Array[Dictionary]`, each `{"id", "department", "cell", "title", "prompt", "art", "color"}`. These are the non-merchant stations, filled in by later tasks.
  - `Departments.LOADOUT_BENCH_CELLS: Array[Vector2i]`, the reserved floor in the Back Room.
  - `Departments.index_of(id: String) -> int`: the room id in the built map, which is the index in `ALL`.
  - `Departments.build_map(layouts: Dictionary) -> FloorMap`: id → `RoomLayout`, a room per entry of type `TYPE_DEPARTMENT`, joined by `LINKS`, with the start in the lobby.
  - `Departments.is_open(id: String, data: ProgressData) -> bool`
  - `Departments.open_ids(data) -> Array[String]`, in `ALL` order.
  - `Departments.newly_opened(data) -> Array[String]`: open and not in `data.departments_seen`, except the lobby and the hallway, which are never announced.
  - `Departments.closed_hint(id) -> String`: for example "Opens when the Records Basement is cleared".
  - `Departments.load_layouts() -> Dictionary`, loading `ALL[i]["layout"]`.

**The table:**

| id | name | cell | layout size | opens on | merchant |
|---|---|---|---|---|---|
| `lobby` | Lobby | (0, 0) | 30×11 | start | |
| `hallway` | Hallway | (−1, 0) | 14×9 | start | |
| `bounty_office` | Bounty Office | (0, −1) | 20×11 | `floor_1` | |
| `training_yard` | Training Yard | (1, 0) | 20×11 | `cemetery` | |
| `apothecary_wing` | Apothecary Wing | (−1, −1) | 14×9 | `sunset_shores` | `potion_merchant` |
| `boiler_room` | Boiler Room | (−1, 1) | 14×9 | `furnace_works` | `bomb_merchant` |
| `decor_office` | Decor Office | (−2, 0) | 20×11 | `funeral_parlour` | |
| `back_room` | Back Room | (0, 1) | 20×11 | `golden_years_mall` | |

`LINKS := [["lobby", "bounty_office"], ["lobby", "training_yard"], ["lobby", "back_room"], ["lobby", "hallway"], ["hallway", "apothecary_wing"], ["hallway", "boiler_room"], ["hallway", "decor_office"]]`

**Arrival lines (placeholders):**
- Bounty Office: "A new door creaks open: the Bounty Office. Someone in there wants names."
- Training Yard: "The Training Yard is open. Somebody has set up a dummy that looks very familiar."
- Apothecary Wing: "Madame Murk has moved into the Apothecary Wing. It smells of liniment."
- Boiler Room: "Boom Bernard has set up shop in the Boiler Room. Mind the fumes."
- Decor Office: "The Decor Office is open. Condolences accepted, sympathy extra."
- Back Room: "A door marked PRIVATE swings open. The Dealer has a back room."

**The layouts** (`room_type = "department"`):
- Only `#`, `.`, `l` on the border, decor symbols, and `G` (in the Back Room only, two of them).
- Door cells are floor on all four sides, as `validate()` demands. A side with no link just never gets a door.
- **Lobby (30×11):** plain floor, with `l` lanterns in the top wall at x = 6, 15 and 24.
- **Back Room (20×11):** `G` at (7, 4) and (12, 4), and the Dealer stands at `merchant_cell()`. Keep `LOADOUT_BENCH_CELLS = [(14,7),(15,7),(16,7),(14,8),(15,8),(16,8)]` plain floor.

`data/floors/waiting_room.tres`:
- `id = "waiting_room"`, `display_name = "The Waiting Room"`, `rooms_dir = "res://data/rooms/waiting_room/"`.
- `enemies = []`, no bosses, `arcade_chance = 0.0`.
- No palette, so it keeps today's default look.

- [x] **Step 1: Write the failing tests** in `tests/test_departments.gd`:

  ```gdscript
  extends TestCase


  func _data(paths: Array = []) -> ProgressData:
  	var data := ProgressData.new()
  	for id in paths:
  		data.paths_cleared[id] = true
  	return data


  func test_every_layout_is_valid() -> void:
  	var layouts := Departments.load_layouts()
  	assert_eq(layouts.size(), Departments.ALL.size())
  	for id in layouts:
  		assert_eq((layouts[id] as RoomLayout).validate(), PackedStringArray(), id)


  func test_a_fresh_save_opens_only_the_lobby_and_hallway() -> void:
  	assert_eq(Departments.open_ids(_data()), [Departments.LOBBY, Departments.HALLWAY])


  func test_each_department_opens_on_its_floors_first_clear() -> void:
  	var cases := {"floor_1": Departments.BOUNTY_OFFICE, "cemetery": Departments.TRAINING_YARD, "sunset_shores": Departments.APOTHECARY_WING, "furnace_works": Departments.BOILER_ROOM, "funeral_parlour": Departments.DECOR_OFFICE, "golden_years_mall": Departments.BACK_ROOM}
  	for path in cases:
  		assert_true(Departments.is_open(cases[path], _data([path])), path)
  		assert_eq(Departments.open_ids(_data([path])).size(), 3, "only one more opens for %s" % path)


  func test_a_legacy_merchant_is_never_behind_a_closed_door() -> void:
  	var data := _data()
  	data.legacy_clears = 3
  	assert_true(Departments.is_open(Departments.APOTHECARY_WING, data))
  	assert_true(Departments.is_open(Departments.BOILER_ROOM, data))


  func test_the_map_joins_every_department_and_each_is_reachable_on_its_own() -> void:
  	var map := Departments.build_map(Departments.load_layouts())
  	assert_eq(map.rooms.size(), Departments.ALL.size())
  	assert_eq(map.start_id, Departments.index_of(Departments.LOBBY))
  	# Opening any one department alone must never need another closed one: each path from the lobby
  	# runs only through the lobby, the hallway and the department itself.
  	var always := [Departments.index_of(Departments.LOBBY), Departments.index_of(Departments.HALLWAY)]
  	for entry: Dictionary in Departments.ALL:
  		var avoid: Array[int] = []
  		for other: Dictionary in Departments.ALL:
  			var other_id := Departments.index_of(other["id"])
  			if other["id"] != entry["id"] and not always.has(other_id):
  				avoid.append(other_id)
  		assert_true(map.walk_from(map.start_id, avoid).has(Departments.index_of(entry["id"])), entry["id"])


  func test_newly_opened_skips_seen_ones_and_the_always_open_rooms() -> void:
  	var data := _data(["floor_1", "cemetery"])
  	assert_eq(Departments.newly_opened(data), [Departments.BOUNTY_OFFICE, Departments.TRAINING_YARD])
  	data.departments_seen[Departments.BOUNTY_OFFICE] = true
  	assert_eq(Departments.newly_opened(data), [Departments.TRAINING_YARD])


  func test_merchants_keep_their_rules_and_name_a_department() -> void:
  	for entry: Dictionary in Departments.MERCHANTS:
  		assert_true(Departments.index_of(entry["department"]) >= 0, entry["id"])
  	assert_eq(MerchantRules.open_ones(Departments.MERCHANTS, _data()).map(func(e): return e["id"]), ["black_market", "optometrist"])


  func test_the_loadout_bench_space_is_plain_floor() -> void:
  	var back: RoomLayout = Departments.load_layouts()[Departments.BACK_ROOM]
  	for cell in Departments.LOADOUT_BENCH_CELLS:
  		assert_eq(back.symbol_at(cell), RoomLayout.SYMBOL_FLOOR, str(cell))
  ```

  Append to `tests/test_save_migration.gd`:

  ```gdscript
  func test_old_saves_open_the_departments_of_their_cleared_floors() -> void:
  	var open := Departments.open_ids(_today())
  	for id in [Departments.BOUNTY_OFFICE, Departments.TRAINING_YARD, Departments.APOTHECARY_WING, Departments.BOILER_ROOM, Departments.DECOR_OFFICE]:
  		assert_true(open.has(id), id)
  	assert_false(open.has(Departments.BACK_ROOM), "the Mall was never cleared")
  ```

- [ ] **Step 2: When testing is allowed, run them to make sure they fail.**

- [x] **Step 3: Implement** `Departments`, the layouts, the FloorDef and `TYPE_DEPARTMENT`.
  - `is_open` returns true for an empty `opens_on`, or when `data.has_cleared_path(opens_on)`. Otherwise, for an entry with a `"merchant"`, it returns `MerchantRules.is_open(that merchant entry, data)`.
  - In `RoomRules.ICONS`, a department door shows `"<"`, the default. The name comes from `DepartmentSign` (Task 4).
  - Write the layouts with the Write tool, modelled on `data/rooms/landing/landing.tres`.

- [ ] **Step 4: When testing is allowed, run the tests.** `test_room_layouts.gd` and `test_boss_spawn_room.gd` must still pass. The latter skips rooms without `B`.

- [x] **Step 5: Commit** ("Describe the Waiting Room departments and lay them out on the room grid").

### Task 4: The Waiting Room rebuilt on the grid

**Files:**
- Create: `scripts/world/waiting_station.gd`, `scripts/world/department_sign.gd`
- Modify: `scripts/scenes/waiting_room.gd` (rewritten), `scripts/autoload/progress.gd`, `scripts/world/room_view.gd` (one helper)
- Test: `tests/test_departments.gd`

**Interfaces:**
- Consumes: Task 3's `Departments`.
- Produces:
  - `WaitingStation extends Node2D`:
    - fields `id: String`, `title: String`, `prompt: String`
    - `setup(entry: Dictionary, feet: Node2D)`, `is_near() -> bool`, `USE_RADIUS := 48.0`
    - draws a `SpriteVisual` when `entry` has `"art"`, or a code-drawn board of `entry["color"]` and `entry["size"]` otherwise, plus its prompt when near, as `_draw` does today.
  - `DepartmentSign extends Node2D`: `setup(text: String, closed: bool)`. It draws the name above a door, and in grey with the hint under it when closed.
  - `RoomView.chain_door(target_id: int)`: sets `chained = true` on that door.
  - `Progress.mark_departments_seen(ids: Array) -> void` (saves).
  - Scene API, which the smoke driver uses:
    - `open_merchant_ids() -> Array`, kept
    - `open_department_ids() -> Array[String]`
    - `current_department() -> String`
    - `debug_enter_department(id: String)`
    - `station(id: String) -> WaitingStation`
    - `use_station(id: String)`: opens what interact would
    - `open_panel() -> CanvasLayer`: whichever panel is open, or null
    - `debug_room_view() -> RoomView`

**What the scene does:**
- **`_ready`:**
  1. Make one run with `Progress.make_run()` and a `Player`.
  2. Build `_map := Departments.build_map(Departments.load_layouts())` and a `FloorProgress`.
  3. Make a `Camera2D` and a `Hud.setup(null)`.
  4. Enter the lobby with the player at the run door's west side.
- **`_enter_department(room_id)`:** works like `floor_scene._enter_room`, without a mini map.
  - Keep each department's `RoomView` in `_views`, made on first entry with `RoomView.setup(room, _map, load("res://data/floors/waiting_room.tres"), _run, player, _rng, _progress, Progress)`.
  - For each door to a closed department, call `chain_door`.
  - Add a `DepartmentSign` per door. Place it one cell in from the door, toward the room's middle, so a sign never leaves the room.
  - Add the department's stations: open merchants from `Departments.MERCHANTS` whose `"department"` matches, then `Departments.STATIONS`.
- **The run door:** a `Door` at lobby cell (26, 5), unlocked, whose `entered` calls `Game.begin_run()`.
- **The Keys board and Agnes** become `STATIONS` entries in the lobby (`key_board` and `crafter`), with today's titles and colours.
- **Camera:** `_camera.position = RoomCamera.center_for(room_size, player.feet().global_position, RoomBackdrop.VIEW_SIZE)` every frame.
- **Interact:** `_station_in_range()` picks the nearest `WaitingStation` with `is_near()` in the current view, and opens its panel exactly as today: merchants → `MerchantPanel` or `PotionPanel`, `key_board` → `KeysPanel`, `crafter` → `CraftPanel`.
  - Lesson: poll `Input.is_action_just_pressed` in `_process`, and ignore the frame a panel closed on.
- **Arrival:**
  - `Departments.newly_opened(Progress.data)` makes one notice, "New departments open: Bounty Office, Training Yard.".
  - Each department's arrival line is then queued and shown one at a time, every `Hud.NOTICE_TIME`.
  - Then call `Progress.mark_departments_seen`.
  - Today's `Progress.notice` (save damage) still shows first.
- **Leaving:** `_exit_tree` frees views out of the tree, as `floor_scene` does.

Merchant positions:

| Merchant | Department | Cell |
|---|---|---|
| Black Market | lobby | (6, 3) |
| Dr. Squint | lobby | (6, 7) |
| Madame Murk | apothecary_wing | (7, 3) |
| Boom Bernard | boiler_room | (7, 3) |

Lobby stations from this task:

| Station | Cell |
|---|---|
| Agnes | (11, 7) |
| Keys board | (20, 3) |
| Run door | (26, 5) |

Later tasks add the trophy wall (15, 2), the forms counter (11, 3), the ticket machine (23, 3) and the noticeboard (23, 7).

- [x] **Step 1: Write the failing tests** (pure parts) in `tests/test_departments.gd`:

  ```gdscript
  func test_stations_stand_on_open_floor_clear_of_doors_and_each_other() -> void:
  	var layouts := Departments.load_layouts()
  	var all: Array = Departments.MERCHANTS.duplicate()
  	all.append_array(Departments.STATIONS)
  	var taken := {}
  	for entry: Dictionary in all:
  		var layout: RoomLayout = layouts[entry["department"]]
  		var cell: Vector2i = entry["cell"]
  		assert_eq(layout.symbol_at(cell), RoomLayout.SYMBOL_FLOOR, "%s on floor" % entry["id"])
  		for side in RoomLayout.SIDES:
  			assert_true(Vector2(cell).distance_to(Vector2(layout.door_cell(side))) >= 3.0, "%s clear of doors" % entry["id"])
  		var key := "%s %s" % [entry["department"], str(cell)]
  		assert_false(taken.has(key), "%s shares a cell" % entry["id"])
  		taken[key] = true
  		assert_true(cell.y >= RoomLayout.UNDER_THE_HUD + 1, "%s clear of the HUD row" % entry["id"])


  func test_a_closed_department_says_what_opens_it() -> void:
  	assert_eq(Departments.closed_hint(Departments.BOUNTY_OFFICE), "Opens when The Records Basement is cleared")
  ```

  `closed_hint` takes the floor's display name from a small `const FLOOR_NAMES` in `Departments`. It must not load FloorDefs. The test above fixes the wording.

- [ ] **Step 2: When testing is allowed, run them to make sure they fail.**

- [x] **Step 3: Implement** `WaitingStation`, `DepartmentSign`, `RoomView.chain_door`, `Progress.mark_departments_seen` and the new `waiting_room.gd`. Remove `ROWS`, `MERCHANTS`, `DOOR_CELL`, `KEY_BOARD_*` and `CRAFTER_*` from the scene. "NOW SERVING: 666" stays drawn in the lobby until Task 18 replaces it.

- [ ] **Step 4: When testing is allowed, run the tests and one full loop.** The smoke driver's opening checks (`open_merchant_ids() == ["black_market", "optometrist"]`, both merchant checks after clears) must pass unchanged.

- [ ] **Step 5: When testing is allowed, screenshot** in a real window, using the shortcut's throwaway profile with `--dev-all-departments`:
  - the lobby, with the camera scrolling across its 30 cells
  - a closed door's sign
  - every department
  - each moved merchant's panel

- [x] **Step 6: Commit** ("Rebuild the Waiting Room as departments on the room grid").

### Task 5: The trophy wall and the memento rules

**Files:**
- Create: `scripts/core/mementos.gd`, `scripts/world/trophy_wall.gd`
- Modify: `scripts/scenes/waiting_room.gd`, `scripts/core/departments.gd` (the `trophy_wall` station)
- Test: `tests/test_mementos.gd` (new), `tests/test_save_migration.gd`

**Interfaces:**
- Produces:
  - `Mementos.ALL: Array[Dictionary]`, in floor order. Each entry is `{"boss": EnemyDef id, "boss_name", "path": path id, "memento", "perk": perk id, "perk_text"}`.
  - Perk ids: `Mementos.START_PENSION_PERK := "start_pension"`, `PROP_COINS_PERK := "prop_coins"`, `FIRST_HEAL_PERK := "first_heal"`, `FIRE_PERK := "fire_shrug"`, `BOSS_ROOM_PILL_PERK := "boss_room_pill"`, `TREASURE_CHOICE_PERK := "treasure_choice"`.
  - Numbers: `START_PENSION := 10`, `PROP_COIN_MULT := 1.25`, `FIRST_HEAL_EXTRA := 1`, `BOSS_ROOM_HEAL := 1`, `TREASURE_EXTRA := 1`.
  - `Mementos.hung(data: ProgressData) -> Array[Dictionary]`: entries whose path is cleared.
  - `Mementos.perks(data) -> Dictionary`: perk id → true.
  - `TrophyWall extends Node2D`: `setup(data: ProgressData)`. It draws six frames.

| boss | path | memento | perk |
|---|---|---|---|
| `regional_reaper` | `floor_1` | Name badge | `start_pension` "Start each run with 10 Pension" |
| `tired_undertaker` | `cemetery` | Bent shovel | `prop_coins` "Breakables drop Pension a little more often" |
| `matron_mercy` | `sunset_shores` | Bedpan | `first_heal` "The first heal of each run restores one extra pill" |
| `old_smokey` | `furnace_works` | Coal shovel | `fire_shrug` "Every second hit from fire is shrugged off" |
| `mortimer_grimsby` | `funeral_parlour` | Top hat | `boss_room_pill` "+1 pill on entering a boss room" |
| `mall_santa` | `golden_years_mall` | Empty sack | `treasure_choice` "One more item to choose from in treasure rooms" |

**The wall:**
- The station sits at lobby cell (15, 2), with frames from x = 12 to 18 on row 1, in the top wall's face.
- Each frame is 26×22 px, dark wood with a pale mat.
- **An empty frame** shows a faint "?" and the boss's short name under it, so what is left to beat is always in view.
- **A hung memento** is a small code-drawn shape:
  - Name badge: a white rectangle with a red stripe.
  - Bent shovel: a grey blade on a bent brown line.
  - Bedpan: a pale oval.
  - Coal shovel: a black blade.
  - Top hat: a black hat with a band.
  - Empty sack: a red sack outline.
- Interact ("Look") shows a HUD notice listing each hung memento with its perk text, or "Empty frames. Beat a floor boss to hang one." when none.

- [x] **Step 1: Write the failing tests** in `tests/test_mementos.gd`:

  ```gdscript
  extends TestCase


  func test_every_floor_boss_has_a_frame_and_its_floor_names_it() -> void:
  	assert_eq(Mementos.ALL.size(), 6)
  	for entry: Dictionary in Mementos.ALL:
  		var floor_path := "res://data/floors/%s.tres" % entry["path"]
  		var def: FloorDef = load(floor_path)
  		assert_eq(def.floor_boss.id, entry["boss"], entry["path"])


  func test_a_fresh_save_hangs_nothing() -> void:
  	assert_eq(Mementos.hung(ProgressData.new()).size(), 0)
  	assert_eq(Mementos.perks(ProgressData.new()).size(), 0)


  func test_a_cleared_path_hangs_its_memento_and_grants_its_perk() -> void:
  	var data := ProgressData.new()
  	data.record_floor_cleared(1, "cemetery")
  	assert_eq(Mementos.hung(data).size(), 1)
  	assert_true(Mementos.perks(data).has(Mementos.PROP_COINS_PERK))
  	assert_false(Mementos.perks(data).has(Mementos.START_PENSION_PERK))
  ```

  Append to `tests/test_save_migration.gd`:

  ```gdscript
  func test_old_saves_hang_the_mementos_of_floors_already_cleared() -> void:
  	assert_eq(Mementos.hung(_today()).size(), 5)
  ```

- [ ] **Step 2: When testing is allowed, run them to make sure they fail.**

- [x] **Step 3: Implement** `Mementos`, `TrophyWall` and the lobby station.

- [ ] **Step 4: When testing is allowed, run the tests, and screenshot the wall** with no frames filled and with all six (`--dev-all-departments`).

- [x] **Step 5: Commit** ("Hang a memento on the trophy wall for each floor boss beaten").

### Task 6: Memento perks in runs

**Files:**
- Modify: `scripts/core/run_state.gd`, `scripts/core/health.gd`, `scripts/autoload/progress.gd` (`make_run`), `scripts/scenes/floor_scene.gd`, `scripts/world/room_view.gd`, `scripts/actors/player.gd`, and the fire hazards `scripts/world/floor_vent.gd`, `scripts/world/ground_strike.gd` and `scripts/world/steam_jet.gd`
- Test: `tests/test_mementos.gd`

**Interfaces:**
- Consumes: Task 5's `Mementos`.
- Produces:
  - `RunState.perks: Dictionary`, `RunState.has_perk(id: String) -> bool`, and `RunState.apply_perks()`, which sets `health.first_heal_bonus`.
  - `RunState.prop_coin_mult() -> float`: `Mementos.PROP_COIN_MULT` with the perk, else 1.0.
  - `Health.first_heal_bonus: int`, spent by the first `heal()` that restores anything.
  - `Player.take_fire_hit(amount: int) -> bool`. With the perk, every second call returns `false` and does nothing. Otherwise it calls `take_hit`.
  - `RoomView._prop_coin_roll() -> float`: `_rng.randf() / _run.prop_coin_mult()`. Every breakable's coin roll goes through it.

- [x] **Step 1: Write the failing tests:**

  ```gdscript
  func _run_with(perk: String) -> RunState:
  	var run := RunState.new([], {})
  	run.perks = {perk: true}
  	run.apply_perks()
  	return run


  func test_the_bedpan_adds_one_pill_to_the_first_heal_only() -> void:
  	var run := _run_with(Mementos.FIRST_HEAL_PERK)
  	run.health.hit(3)
  	run.health.heal(1)
  	assert_eq(run.health.pills, PlayerStats.BASE_PILLS - 3 + 2)
  	run.health.heal(1)
  	assert_eq(run.health.pills, PlayerStats.BASE_PILLS - 3 + 3)


  func test_a_heal_on_full_pills_does_not_spend_the_bedpan() -> void:
  	var run := _run_with(Mementos.FIRST_HEAL_PERK)
  	run.health.heal(1)
  	run.health.hit(2)
  	run.health.heal(1)
  	assert_eq(run.health.pills, PlayerStats.BASE_PILLS)


  func test_the_coal_shovel_shrugs_off_every_second_fire_hit() -> void:
  	var player := Player.new()
  	player.setup(_run_with(Mementos.FIRE_PERK))
  	assert_true(player.take_fire_hit(1))
  	player.run.health.tick(Health.INVULN_TIME + 0.1)
  	assert_false(player.take_fire_hit(1), "the second is shrugged off")
  	player.run.health.tick(Health.INVULN_TIME + 0.1)
  	assert_true(player.take_fire_hit(1))
  	player.free()


  func test_the_bent_shovel_raises_prop_coin_odds() -> void:
  	assert_near(_run_with(Mementos.PROP_COINS_PERK).prop_coin_mult(), 1.25)
  	assert_near(RunState.new([], {}).prop_coin_mult(), 1.0)
  ```

  Check the real name of the player's run field in `player.gd` and use it in place of `player.run`.

- [ ] **Step 2: When testing is allowed, run them to make sure they fail.**

- [x] **Step 3: Implement.**
  - **`Progress.make_run()`:** set `run.perks = Mementos.perks(data)`, then `run.apply_perks()`.
  - **Name badge:** in `floor_scene._ready`, after `Progress.start_run()`, when `_run.has_perk(START_PENSION_PERK)`, call `Progress.add_pension(Mementos.START_PENSION)` and show the notice "Your name badge still works: +10 Pension".
  - **Bent shovel:** in `room_view.gd`, route every `_rng.randf()` that decides a prop's coin through `_prop_coin_roll()`. Find them by reading `_create_props` and the `_on_*_broken` handlers with their `RoomRules.*_COIN_CHANCE` rolls. Only coin rolls change, not bomb or item rolls.
  - **Bedpan:** `Health.heal` adds `first_heal_bonus` once, but only when `pills < max_pills` before the heal, then sets it to 0.
  - **Coal shovel:**
    - Replace `player.take_hit(PLAYER_DAMAGE)` in `floor_vent.gd:163` and the burn's `target.take_hit(BURN_PLAYER_DAMAGE)` in `ground_strike.gd:192` with `take_fire_hit`.
    - Make the same change in `steam_jet.gd` wherever it hurts Grandpa (`git grep -n "take_hit\|hit_target" scripts/world/steam_jet.gd`).
    - A shrugged hit sets `Player._fire_shrugged_last`, and only a hit that lands flips it.
  - **Top hat:** in `floor_scene._enter_room`, on the first visit (check `_progress.is_visited` before `enter`) to a `TYPE_MINI_BOSS` or `TYPE_FLOOR_BOSS` room, `_run.health.heal(Mementos.BOSS_ROOM_HEAL)` with the notice "You tip your hat. +1 pill".
  - **Empty sack:** in `RoomView._create_rewards`, a `TYPE_TREASURE` room with the perk adds one more cell from `_room.layout.open_spots_near(cells, cells)` before `_create_item_choice`.

- [ ] **Step 4: When testing is allowed, run the tests and one full loop.**

- [x] **Step 5: Commit** ("Give each memento its perk in runs").

---

## Step 2: Forms with the milestone choice and refiling

### Task 7: Form options in the data and the stats

**Files:**
- Modify: `scripts/content/stat_effect.gd`, `scripts/content/upgrade_def.gd`, `scripts/core/player_stats.gd`, `scripts/core/run_state.gd`, `scripts/autoload/progress.gd` (`make_run`), all seven `data/upgrades/*.tres`
- Test: `tests/test_forms.gd` (new), `tests/test_stats.gd`

**Interfaces:**
- Produces:
  - New `StatEffect` fields, each with a one-line comment:
    - `swing_speed_bonus: float`
    - `dodge_length_bonus: float`
    - `heal_bonus: int`
    - `enemy_pension_bonus: float`
    - `reward_pension_bonus: float`
    - `wounded_damage_bonus: float`
    - `reveals_secrets: bool`
    - `blast_radius_bonus: float`
    - `bonus_bombs: int`
    - `teeth_return_cut: float`
  - `UpgradeDef`:
    - `OPTION_A := "a"`, `OPTION_B := "b"`
    - `@export_group("Form")` with `milestone_level: int = 0`, `option_a_name`, `option_a_text`, `option_a: StatEffect`, `option_b_name`, `option_b_text`, `option_b: StatEffect`
    - `has_choice() -> bool`, `option(choice: String) -> StatEffect`, `option_name(choice) -> String`, `option_text(choice) -> String`
  - `PlayerStats.compute(upgrades, levels, items, choices := {})`. For an upgrade with `has_choice()` and a level at or over its milestone, the effect of `option(choices.get(id, OPTION_A))` is added once.
  - New `PlayerStats` fields:
    - `swing_speed := 1.0`, clamped to [0.5, 2.0]
    - `dodge_length := 1.0`
    - `heal_bonus := 0`
    - `enemy_pension_mult := 1.0`, `reward_pension_mult := 1.0`
    - `wounded_damage_mult := 1.0`
    - `reveals_secrets := false`
    - `blast_radius := Thermos.BLAST_RADIUS`
    - `bonus_bombs := 0`
    - `teeth_return_delay` is reduced by `teeth_return_cut`, never below 1.0.
  - `RunState.new(upgrades, levels, choices := {})`. `bombs` starts at `STARTING_BOMBS + stats.bonus_bombs`, and `health.heal_bonus = stats.heal_bonus` (kept in step after `add_item`).
  - `Progress.make_run()` passes `data.form_choices`.

**The data:** each `.tres` gets `milestone_level`, two names, two one-line texts, and two sub-resources of `res://scripts/content/stat_effect.gd`, with the values from "Decisions made in this plan", item 6. Model for `reinforced_cane.tres`:

```
[gd_resource type="Resource" script_class="UpgradeDef" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/content/upgrade_def.gd" id="1"]
[ext_resource type="Script" path="res://scripts/content/stat_effect.gd" id="2"]

[sub_resource type="Resource" id="Resource_heavy"]
script = ExtResource("2")
damage_bonus = 0.15
swing_speed_bonus = -0.1

[sub_resource type="Resource" id="Resource_light"]
script = ExtResource("2")
damage_bonus = -0.05
swing_speed_bonus = 0.2

[resource]
script = ExtResource("1")
id = "reinforced_cane"
display_name = "Reinforced Cane"
description = "More cane damage."
prices = PackedInt32Array(50, 120, 240)
damage_bonus = 0.1
milestone_level = 2
option_a_name = "Heavy Head"
option_a_text = "Much harder swings, a little slower."
option_a = SubResource("Resource_heavy")
option_b_name = "Lightweight"
option_b_text = "Faster combo, a little less damage."
option_b = SubResource("Resource_light")
```

Edit the `.tres` files with the Edit tool. Never use `Set-Content`, which adds a BOM.

- [x] **Step 1: Write the failing tests** in `tests/test_forms.gd`:

  ```gdscript
  extends TestCase


  func _shipped(id: String) -> UpgradeDef:
  	for def in Content.upgrades():
  		if def.id == id:
  			return def
  	return null


  func _stats(id: String, level: int, choice := "") -> PlayerStats:
  	var def := _shipped(id)
  	var upgrades: Array[UpgradeDef] = [def]
  	var choices := {} if choice.is_empty() else {id: choice}
  	var items: Array[ItemDef] = []
  	return PlayerStats.compute(upgrades, {id: level}, items, choices)


  func test_every_form_has_a_milestone_with_two_named_options() -> void:
  	for def in Content.upgrades():
  		assert_true(def.has_choice(), def.id)
  		assert_true(def.milestone_level >= 1 and def.milestone_level <= def.max_level(), def.id)
  		for choice in [UpgradeDef.OPTION_A, UpgradeDef.OPTION_B]:
  			assert_false(def.option_name(choice).is_empty(), "%s %s" % [def.id, choice])
  			assert_true(def.option(choice) != null, "%s %s" % [def.id, choice])


  func test_nothing_changes_below_the_milestone() -> void:
  	assert_near(_stats("reinforced_cane", 1, "b").damage_mult, 1.1)
  	assert_near(_stats("reinforced_cane", 1, "b").swing_speed, 1.0)


  func test_a_missing_choice_reads_as_option_a() -> void:
  	assert_near(_stats("reinforced_cane", 2).damage_mult, 1.0 + 0.2 + 0.15)
  	assert_near(_stats("reinforced_cane", 2).swing_speed, 0.9)


  func test_option_b_of_each_form() -> void:
  	assert_near(_stats("reinforced_cane", 2, "b").swing_speed, 1.2)
  	assert_near(_stats("better_knees", 2, "b").dodge_cooldown, PlayerStats.BASE_DODGE_COOLDOWN * (1.0 - 0.2 - 0.15))
  	assert_eq(_stats("black_market_pills", 2, "b").heal_bonus, 1)
  	assert_near(_stats("bribed_clerk", 2, "b").reward_pension_mult, 1.3)
  	assert_true(_stats("prescription_glasses", 1, "b").reveals_secrets)
  	assert_near(_stats("denture_adhesive", 2, "b").teeth_return_delay, DentureThrow.RETURN_DELAY - 1.0)
  	assert_eq(_stats("thermos_fuel", 2, "b").bonus_bombs, 1)


  func test_option_a_of_each_form() -> void:
  	assert_near(_stats("better_knees", 2, "a").dodge_length, 1.3)
  	assert_eq(_stats("black_market_pills", 2, "a").max_pills, PlayerStats.BASE_PILLS + 3)
  	assert_near(_stats("bribed_clerk", 2, "a").enemy_pension_mult, 1.2)
  	assert_near(_stats("prescription_glasses", 1, "a").wounded_damage_mult, 1.2)
  	assert_near(_stats("denture_adhesive", 2, "a").bite_damage_mult, 1.0 + 0.3 + 0.25)
  	assert_near(_stats("thermos_fuel", 2, "a").blast_radius, Thermos.BLAST_RADIUS * 1.3)


  func test_a_spare_can_starts_the_run_with_one_more_thermos() -> void:
  	var fuel := _shipped("thermos_fuel")
  	var run := RunState.new([fuel], {fuel.id: 2}, {fuel.id: "b"})
  	assert_eq(run.bombs, RunState.STARTING_BOMBS + 1)
  ```

  In `test_stats.gd`, keep every old assertion. With no choices passed, levels below the milestones give the same numbers as before.

- [ ] **Step 2: When testing is allowed, run them to make sure they fail.**

- [x] **Step 3: Implement** the fields, `compute`, `RunState` and the data.
  - Options are plain `StatEffect`s, never `UpgradeDef`s, so the `effect is UpgradeDef` special cases in `compute` (Thermos levels, the quick return) ignore them, as they should.
  - `prescription_glasses` has one level, so its milestone is 1. Buying it is the choice.

- [ ] **Step 4: When testing is allowed, run the tests.**

- [x] **Step 5: Commit** ("Give every form two options at its milestone").

### Task 8: The options in play

**Files:**
- Modify: `scripts/core/cane_combo.gd`, `scripts/core/dodge_timer.gd`, `scripts/core/health.gd`, `scripts/core/run_state.gd`, `scripts/actors/player.gd`, `scripts/world/thermos.gd`, `scripts/world/room_view.gd`, `scripts/ui/floor_map_view.gd`, `scripts/scenes/floor_scene.gd`
- Test: `tests/test_forms.gd`, `tests/test_floor_map_view.gd`

**Interfaces:**
- Consumes: Task 7's stats.
- Produces:
  - `CaneCombo.lock_time := LOCK_TIME` (a member that `try_attack` uses), and `DodgeTimer.try_start(cooldown: float, duration := DURATION) -> bool`.
  - `Health.heal_bonus: int`, added to every heal that restores anything.
  - `RunState.PENSION_ENEMY := "enemy"`, `PENSION_REWARD := "reward"`, and `RunState.pension_amount(base: int, source := "") -> int`, which uses `stats.pension_mult` times the source's own multiplier.
  - `PlayerStats.strike_damage(base: float, hp_fraction: float, wounded_mult: float) -> float` (static): `base * wounded_mult` below `WOUNDED_BELOW := 0.5`, else `base`.
  - `Thermos.radius: float` (default `BLAST_RADIUS`), used everywhere the blast reads its radius.
  - `FloorMapView.shown_ids(map: FloorMap, progress: FloorProgress, show_secrets: bool) -> Array[int]` (static), and `FloorMapView.show_secrets: bool`.

- [x] **Step 1: Write the failing tests:**

  ```gdscript
  func test_a_slower_lock_holds_the_next_swing_longer() -> void:
  	var combo := CaneCombo.new()
  	combo.lock_time = CaneCombo.LOCK_TIME / 0.9
  	combo.try_attack()
  	combo.tick(CaneCombo.LOCK_TIME + 0.001)
  	assert_eq(combo.try_attack(), 0, "still locked")


  func test_a_longer_dodge_lasts_longer() -> void:
  	var dodge := DodgeTimer.new()
  	dodge.try_start(1.0, DodgeTimer.DURATION * 1.3)
  	dodge.tick(DodgeTimer.DURATION + 0.01)
  	assert_true(dodge.is_active())


  func test_pills_heal_more_never_past_the_maximum() -> void:
  	var health := Health.new(4)
  	health.heal_bonus = 1
  	health.hit(3)
  	health.heal(1)
  	assert_eq(health.pills, 3)
  	health.heal(2)
  	assert_eq(health.pills, 4)


  func test_pension_by_source() -> void:
  	var clerk := _shipped("bribed_clerk")
  	var run := RunState.new([clerk], {clerk.id: 2}, {clerk.id: "a"})
  	assert_eq(run.pension_amount(10, RunState.PENSION_ENEMY), ceili(10 * 1.2 * 1.2))
  	assert_eq(run.pension_amount(10, RunState.PENSION_REWARD), ceili(10 * 1.2))
  	assert_eq(run.pension_amount(10), ceili(10 * 1.2))


  func test_the_weak_spot_only_counts_below_half_health() -> void:
  	assert_near(PlayerStats.strike_damage(10.0, 0.6, 1.2), 10.0)
  	assert_near(PlayerStats.strike_damage(10.0, 0.4, 1.2), 12.0)
  ```

  In `test_floor_map_view.gd`, use a map with a secret room. `shown_ids` must leave it out with `show_secrets = false` until visited, and include it with `true`.

- [ ] **Step 2: When testing is allowed, run them to make sure they fail.**

- [x] **Step 3: Implement.**
  - **Swing:** in `Player`, before `_combo.try_attack()`, set `_combo.lock_time = CaneCombo.LOCK_TIME / run.stats.swing_speed`.
  - **Dodge:** `_dodge.try_start(run.stats.dodge_cooldown, DodgeTimer.DURATION * run.stats.dodge_length)`.
  - **Weak spot:** in `_strike_enemies`, pass `PlayerStats.strike_damage(swing.damage, enemy.hp / enemy.max_hp(), run.stats.wounded_damage_mult)` to `take_strike`. Do the same where `ThrownDentures` bites, if it can reach the enemy's health (`enemy.hp`). Otherwise leave the teeth as they are and say so in the commit.
  - **Thermos:**
    - `RoomView.place_bomb` sets `thermos.radius = _run.stats.blast_radius`.
    - In `thermos.gd`, every `BLAST_RADIUS` in `_explode`, `_draw` and the reach test becomes `radius`. Static helpers gain a `radius := BLAST_RADIUS` parameter.
  - **Pension sources:**
    - `RoomView._drop_coin(at, base_amount, source := "")`.
    - An enemy's coin passes `PENSION_REWARD` when `enemy.def.is_boss`, and `PENSION_ENEMY` otherwise.
    - Treasure fallbacks, chest coins (`_open_lunchbox`, `_open_safe`, the urn fallback) and `_create_item_choice`'s fallback pass `PENSION_REWARD`.
    - Props and room-clear Pension pass nothing.
  - **Night Vision:** `floor_scene._add_map_view` and `_choose_path` set `view.show_secrets = _run.stats.reveals_secrets`. `_draw` draws `shown_ids` instead of `visited_ids`, and an unvisited secret room as an outline with "?".

- [ ] **Step 4: When testing is allowed, run the tests and one full loop.**

- [x] **Step 5: Commit** ("Make each form option change play").

### Task 9: Filing forms, the stamp and refiling

**Files:**
- Create: `scripts/core/form_text.gd`, `scripts/ui/refile_panel.gd`
- Modify: `scripts/core/progress_data.gd`, `scripts/autoload/progress.gd`, `scripts/ui/merchant_panel.gd`, `scripts/core/departments.gd` (the `forms_counter` station), `scripts/scenes/waiting_room.gd`
- Test: `tests/test_forms.gd`, `tests/test_save_migration.gd`

**Interfaces:**
- Produces:
  - `ProgressData.REFILE_FEE := 40` and `CLERK_DEAL_CUT := 0.25`.
  - `ProgressData.price_of(def: UpgradeDef) -> int`: the price at the next level, less the clerk deal for that form. It is −1 when maxed.
  - `can_buy` and `buy` use `price_of`.
  - `ProgressData.buy(def: UpgradeDef, option := "") -> bool`. Filing the milestone level stores `option` (empty means `"a"`) and refuses anything other than `"a"` or `"b"`.
  - `ProgressData.choice_of(def) -> String`: `""` below the milestone, else the stored choice or `"a"`.
  - `ProgressData.refile_price(def) -> int`: −1 with no choice yet, 0 while the free switch is unused, else `REFILE_FEE`.
  - `ProgressData.refile(def) -> bool`: switches to the other option, pays, and marks the free switch used.
  - `Progress.buy(def, option := "")` and `Progress.refile(def) -> bool`, both saving and emitting `pension_changed`.
  - `FormText.row(def, level, price, choice) -> String`, `FormText.stamps(def, level) -> String` (for example `"[FILED] [FILED] [ ]"`) and `FormText.refile_row(def, choice, price) -> String`.
  - Lobby station `forms_counter` at (11, 3), titled "Forms Counter. Refiling, Window 2", with the prompt "Refile".

**The panels:**
- **`MerchantPanel`:**
  - Each upgrade is a form row: name, stamps, chosen option name if any, and price. One "File" button per row.
  - When the next level is the milestone, the row shows two buttons, "File: <option A name>" and "File: <option B name>", each with its text as the tooltip.
  - After a filing, a red "FILED" label is laid over the row. A `Tween` scales it 1.6 → 1.0 over 0.15 s, then the list rebuilds.
  - Keep the panel inside 360 px. The Black Market sells five forms.
- **`RefilePanel`:** one row per form with a choice: "<form>: <current option> → <other option>  Free" or "40 Pension". The button is disabled when unaffordable.

- [x] **Step 1: Write the failing tests:**

  ```gdscript
  func _data_with(pension: int, levels := {}) -> ProgressData:
  	var data := ProgressData.new()
  	data.pension = pension
  	data.upgrades = levels.duplicate()
  	return data


  func test_filing_the_milestone_stores_the_choice() -> void:
  	var cane := _shipped("reinforced_cane")
  	var data := _data_with(1000, {"reinforced_cane": 1})
  	assert_eq(data.choice_of(cane), "")
  	assert_false(data.buy(cane, "z"))
  	assert_true(data.buy(cane, "b"))
  	assert_eq(data.choice_of(cane), "b")
  	assert_eq(data.level_of("reinforced_cane"), 2)


  func test_filing_without_a_choice_takes_option_a() -> void:
  	var cane := _shipped("reinforced_cane")
  	var data := _data_with(1000, {"reinforced_cane": 1})
  	assert_true(data.buy(cane))
  	assert_eq(data.choice_of(cane), "a")


  func test_the_first_refile_is_free_and_the_next_costs_the_fee() -> void:
  	var cane := _shipped("reinforced_cane")
  	var data := _data_with(100, {"reinforced_cane": 2})
  	assert_eq(data.refile_price(cane), 0)
  	assert_true(data.refile(cane))
  	assert_eq(data.choice_of(cane), "b")
  	assert_eq(data.pension, 100)
  	assert_eq(data.refile_price(cane), ProgressData.REFILE_FEE)
  	assert_true(data.refile(cane))
  	assert_eq(data.choice_of(cane), "a")
  	assert_eq(data.pension, 100 - ProgressData.REFILE_FEE)


  func test_nothing_to_refile_below_the_milestone() -> void:
  	var cane := _shipped("reinforced_cane")
  	var data := _data_with(100, {"reinforced_cane": 1})
  	assert_eq(data.refile_price(cane), -1)
  	assert_false(data.refile(cane))


  func test_the_clerk_deal_takes_a_quarter_off_one_form() -> void:
  	var cane := _shipped("reinforced_cane")
  	var data := _data_with(1000)
  	data.clerk_deal = "reinforced_cane"
  	assert_eq(data.price_of(cane), ceili(50 * 0.75))
  	assert_true(data.buy(cane))
  	assert_eq(data.pension, 1000 - ceili(50 * 0.75))


  func test_a_form_row_shows_its_stamps() -> void:
  	assert_eq(FormText.stamps(_shipped("reinforced_cane"), 2), "[FILED] [FILED] [ ]")
  ```

  Append to `tests/test_save_migration.gd`:

  ```gdscript
  func test_old_saves_read_option_a_with_one_free_switch() -> void:
  	var data := _today()
  	for def in Content.upgrades():
  		if data.level_of(def.id) >= def.milestone_level:
  			assert_eq(data.choice_of(def), UpgradeDef.OPTION_A, def.id)
  			assert_eq(data.refile_price(def), 0, def.id)
  	assert_eq(data.choice_of(_find("better_knees")), "", "level 1 is below its milestone")


  func _find(id: String) -> UpgradeDef:
  	for def in Content.upgrades():
  		if def.id == id:
  			return def
  	return null
  ```

- [ ] **Step 2: When testing is allowed, run them to make sure they fail.**

- [x] **Step 3: Implement** `ProgressData`, `Progress`, `FormText`, `MerchantPanel`, `RefilePanel` and the station.

- [ ] **Step 4: When testing is allowed, run the tests. Screenshot** the Black Market panel at its fullest, with a milestone row showing both options and the stamp mid-animation, and the refile panel with all seven forms.

- [x] **Step 5: Commit**: one for filing and refiling in `ProgressData` with tests ("File forms with a milestone choice and refile them for a fee"), and one for the panels ("Show upgrades as stamped forms").

---

## Step 3: The Bounty Office and Condolences

### Task 10: Condolences

**Files:**
- Modify: `scripts/core/progress_data.gd`, `scripts/autoload/progress.gd`, `scripts/ui/hud.gd`, `scripts/scenes/waiting_room.gd`, `scripts/scenes/floor_scene.gd`, `scripts/world/room_view.gd`, `scripts/world/room_rules.gd`
- Test: `tests/test_condolences.gd` (new), `tests/test_hud.gd`

**Interfaces:**
- Produces:
  - `ProgressData.add_condolences(amount: int)` and `spend_condolences(amount: int) -> bool`.
  - `ProgressData.FIRST_MINI_BOSS_CONDOLENCES := 5`, `FIRST_FLOOR_BOSS_CONDOLENCES := 10`, `CURSED_FLOOR_CONDOLENCES := 10`.
  - `ProgressData.record_boss_beaten(boss_id: String, is_floor_boss: bool) -> int`. It returns the Condolences paid: the first-beat amount once per boss, else 0. It also marks a taken bounty for that boss as won (Task 11 adds that line).
  - `Progress.condolences_changed(amount: int)` (signal), `Progress.add_condolences(amount)`, `Progress.spend_condolences(amount) -> bool` and `Progress.record_boss_beaten(boss_id, is_floor_boss) -> int`.
  - `RoomRules.CHEST_CONDOLENCES_CHANCE := 0.05`, `CHEST_CONDOLENCES := 3`, and `RoomRules.chest_condolences(roll: float) -> int`.
  - `Hud.set_condolences(amount: int)` and `Hud.status_text(pension: int, condolences: int, show_condolences: bool) -> String` (static). The Waiting Room shows both. A run shows Pension only.

- [x] **Step 1: Write the failing tests** in `tests/test_condolences.gd`:

  ```gdscript
  extends TestCase


  func test_the_first_beat_of_each_boss_pays_once() -> void:
  	var data := ProgressData.new()
  	assert_eq(data.record_boss_beaten("senior_adjuster", false), ProgressData.FIRST_MINI_BOSS_CONDOLENCES)
  	assert_eq(data.record_boss_beaten("senior_adjuster", false), 0)
  	assert_eq(data.record_boss_beaten("regional_reaper", true), ProgressData.FIRST_FLOOR_BOSS_CONDOLENCES)
  	assert_eq(data.condolences, 15)


  func test_spending_never_goes_below_zero() -> void:
  	var data := ProgressData.new()
  	data.add_condolences(10)
  	assert_false(data.spend_condolences(11))
  	assert_true(data.spend_condolences(10))
  	assert_eq(data.condolences, 0)
  	data.add_condolences(-4)
  	assert_eq(data.condolences, 0)


  func test_chests_rarely_pay_condolences() -> void:
  	assert_eq(RoomRules.chest_condolences(0.01), RoomRules.CHEST_CONDOLENCES)
  	assert_eq(RoomRules.chest_condolences(0.5), 0)


  # The rule itself does not check what was beaten, so the guard lives in floor_scene. This pins it there.
  func test_the_floor_scene_pays_only_for_real_bosses() -> void:
  	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
  	assert_true(source.contains("if boss.is_summon or not boss.def.is_boss"))
  ```

  In `tests/test_hud.gd`:

  ```gdscript
  func test_the_waiting_room_shows_both_currencies_and_a_run_only_pension() -> void:
  	assert_eq(Hud.status_text(12, 3, true), "Pension: 12   Condolences: 3")
  	assert_eq(Hud.status_text(12, 3, false), "Pension: 12")
  ```

- [ ] **Step 2: When testing is allowed, run them to make sure they fail.**

- [x] **Step 3: Implement.**
  - **`floor_scene._on_boss_defeated(boss)`:** return early `if boss.is_summon or not boss.def.is_boss`. Then `var paid := Progress.record_boss_beaten(boss.def.id, boss.def == _floor_def.floor_boss)`, and show `"+%d Condolences" % paid` as a notice when `paid > 0`.
  - **Chests:** in `RoomView`, after each of `_open_lunchbox`, `_open_locked`, `_open_urn` and `_open_safe`:

    ```gdscript
    var condolences := RoomRules.chest_condolences(_rng.randf())
    if condolences > 0:
    	_bank.add_condolences(condolences)
    	notice.emit("+%d Condolences" % condolences)
    ```

  - **The HUD:**
    - `Hud._refresh` uses `status_text`.
    - The Waiting Room calls `_hud.show_condolences = true` and `set_condolences(Progress.data.condolences)`, and connects `Progress.condolences_changed`.
    - Check that the top row fits with 9999 of each (lesson: keep HUD text on the fixed top row).

- [ ] **Step 4: When testing is allowed, run the tests, and screenshot the HUD** in the Waiting Room with both counters at 9999, and during a run with a pop-up showing.

- [x] **Step 5: Commit** ("Add Condolences, earned from first boss beats and rare chests").

### Task 11: Bounty data and rules

**Files:**
- Create: `scripts/content/bounty_def.gd`, `scripts/core/bounty_board.gd`, `data/bounties/` (12 files), `data/items/undertakers_gloves.tres`, `comfort_care_lanyard.tres`, `pocket_watch.tres`, `naughty_list.tres`
- Modify: `scripts/content/item_def.gd`, `scripts/core/run_state.gd`, `scripts/core/progress_data.gd`
- Test: `tests/test_bounties.gd` (new), plus any test that counts `Content.items()` (`git grep -n "Content.items()" tests`)

**Interfaces:**
- Produces:
  - `ItemDef.from_bounty: bool`. `RunState.can_offer` returns `unlocked_items.has(item.id)` for such an item, so it joins the pool only once won.
  - `BountyDef` (`Resource`):
    - `id` (the boss's EnemyDef id), `boss_name`, `floor_id`, `depth: int`, `floor_boss: bool`
    - `pension: int`, `condolences: int`
    - `extra_kind: String` (`EXTRA_ITEM`, `EXTRA_RECIPE` or `EXTRA_COSMETIC`), `extra_id: String`
  - `BountyBoard.DIR := "res://data/bounties/"` and `BountyBoard.all() -> Array[BountyDef]` (via `Content.load_dir`).
  - `BountyBoard.floor_reachable(floor: FloorDef, data: ProgressData) -> bool`: `floor.is_open_for(data) and (floor.depth <= 1 or data.clears_at(floor.depth - 1) > 0)`.
  - `BountyBoard.posters(defs: Array[BountyDef], floors: Dictionary, data) -> Array[BountyDef]`. `floors` maps floor id to FloorDef. It returns reachable, unretired posters.
  - `BountyBoard.can_take(def, data) -> bool`, `take(def, data) -> bool`, `can_collect(def, data) -> bool` and `collect(def, data) -> Dictionary`. The result is `{"pension", "condolences", "extra_kind", "extra_id", "extra_was_new": bool}`.
  - `ProgressData.record_boss_beaten` sets `bounty_won = true` when `bounty_taken == boss_id`.

**The posters** (the Pension and Condolences come from decisions 10 and 11, the extras from decision 12):

| id | floor | depth | floor boss | pension | condolences | extra |
|---|---|---|---|---|---|---|
| `senior_adjuster` | `floor_1` | 1 | no | 40 | 10 | recipe `support_stockings` |
| `regional_reaper` | `floor_1` | 1 | yes | 100 | 20 | cosmetic `reaper_hood` |
| `head_groundskeeper` | `cemetery` | 1 | no | 40 | 10 | recipe `titanium_hip` |
| `tired_undertaker` | `cemetery` | 1 | yes | 100 | 20 | item `undertakers_gloves` |
| `activities_coordinator` | `sunset_shores` | 2 | no | 80 | 10 | cosmetic `bingo_teal` |
| `matron_mercy` | `sunset_shores` | 2 | yes | 200 | 20 | item `comfort_care_lanyard` |
| `foreman_klaus` | `furnace_works` | 2 | no | 80 | 10 | recipe `nitro_tablets` |
| `old_smokey` | `furnace_works` | 2 | yes | 200 | 20 | cosmetic `sooty_cane` |
| `reverend` | `funeral_parlour` | 3 | no | 120 | 10 | recipe `alert_bracelet` |
| `mortimer_grimsby` | `funeral_parlour` | 3 | yes | 300 | 20 | item `pocket_watch` |
| `gloria` | `golden_years_mall` | 3 | no | 120 | 10 | cosmetic `fountain_tiara` |
| `mall_santa` | `golden_years_mall` | 3 | yes | 300 | 20 | item `naughty_list` |

**The items** (`from_bounty = true`, no `craft_price`):
- **Undertaker's Work Gloves:** `damage_bonus = 0.2`. "More cane damage. They still smell of earth."
- **Comfort Care Lanyard:** `bonus_pills = 1`, `warning_bonus = 0.1`. "One more pill and earlier warnings. Visiting hours are over."
- **Funeral Director's Pocket Watch:** `dodge_cooldown_cut = 0.15`, `move_speed_bonus = 0.05`. "Shorter dodge cooldown and a little more speed. Always running late."
- **The Naughty List:** `pension_bonus = 0.25`. "More Pension from all sources. You're on it twice."

The four cosmetic ids are created in Task 15. Until then, `collect` stores the id in `cosmetics_owned` all the same.

- [ ] **Step 1: Write the failing tests** in `tests/test_bounties.gd`:

  ```gdscript
  extends TestCase


  func _floors() -> Dictionary:
  	var floors := {}
  	for id in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "golden_years_mall"]:
  		floors[id] = load("res://data/floors/%s.tres" % id)
  	return floors


  func _poster(id: String) -> BountyDef:
  	for def in BountyBoard.all():
  		if def.id == id:
  			return def
  	return null


  func test_there_is_a_poster_for_every_mini_and_floor_boss() -> void:
  	var floors := _floors()
  	var wanted := {}
  	for id in floors:
  		wanted[(floors[id] as FloorDef).mini_boss.id] = id
  		wanted[(floors[id] as FloorDef).floor_boss.id] = id
  	assert_eq(BountyBoard.all().size(), 12)
  	for def in BountyBoard.all():
  		assert_eq(wanted.get(def.id, ""), def.floor_id, def.id)


  func test_the_extras_are_four_of_each_kind_and_all_real() -> void:
  	var counts := {}
  	for def in BountyBoard.all():
  		counts[def.extra_kind] = counts.get(def.extra_kind, 0) + 1
  		if def.extra_kind == BountyDef.EXTRA_RECIPE:
  			assert_true(Content.recipes().any(func(i): return i.id == def.extra_id), def.id)
  		if def.extra_kind == BountyDef.EXTRA_ITEM:
  			assert_true(Content.items().any(func(i): return i.id == def.extra_id and i.from_bounty), def.id)
  	assert_eq(counts, {BountyDef.EXTRA_ITEM: 4, BountyDef.EXTRA_RECIPE: 4, BountyDef.EXTRA_COSMETIC: 4})


  func test_a_fresh_save_sees_only_the_first_floors_posters() -> void:
  	var ids := BountyBoard.posters(BountyBoard.all(), _floors(), ProgressData.new()).map(func(d): return d.id)
  	assert_eq(ids.size(), 2)
  	assert_true(ids.has("senior_adjuster") and ids.has("regional_reaper"))


  func test_one_poster_at_a_time_and_it_stays_through_runs() -> void:
  	var data := ProgressData.new()
  	assert_true(BountyBoard.take(_poster("senior_adjuster"), data))
  	assert_false(BountyBoard.can_take(_poster("regional_reaper"), data))
  	data.start_run()
  	assert_eq(data.bounty_taken, "senior_adjuster")
  	var again := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
  	assert_eq(again.bounty_taken, "senior_adjuster", "survives a save")


  func test_beating_the_boss_then_collecting_pays_and_retires() -> void:
  	var data := ProgressData.new()
  	var poster := _poster("senior_adjuster")
  	BountyBoard.take(poster, data)
  	assert_false(BountyBoard.can_collect(poster, data))
  	data.record_boss_beaten("senior_adjuster", false)
  	assert_true(BountyBoard.can_collect(poster, data))
  	var paid := BountyBoard.collect(poster, data)
  	assert_eq(paid["pension"], 40)
  	assert_eq(data.pension, 40)
  	assert_eq(data.condolences, ProgressData.FIRST_MINI_BOSS_CONDOLENCES + 10)
  	assert_true(data.has_recipe("support_stockings"))
  	assert_eq(data.bounty_taken, "")
  	assert_false(BountyBoard.can_take(poster, data), "retired for good")
  	assert_false(BountyBoard.posters(BountyBoard.all(), _floors(), data).has(poster))


  func test_a_win_before_taking_the_poster_does_not_count() -> void:
  	var data := ProgressData.new()
  	data.record_boss_beaten("senior_adjuster", false)
  	BountyBoard.take(_poster("senior_adjuster"), data)
  	assert_false(BountyBoard.can_collect(_poster("senior_adjuster"), data))


  func test_a_recipe_already_found_pays_half_again_instead() -> void:
  	var data := ProgressData.new()
  	data.find_recipe("support_stockings")
  	var poster := _poster("senior_adjuster")
  	BountyBoard.take(poster, data)
  	data.record_boss_beaten("senior_adjuster", false)
  	var paid := BountyBoard.collect(poster, data)
  	assert_false(paid["extra_was_new"])
  	assert_eq(paid["pension"], 60)


  func test_a_won_item_joins_the_pool_only_once_won() -> void:
  	var gloves: ItemDef = load("res://data/items/undertakers_gloves.tres")
  	var run := RunState.new([], {})
  	assert_false(run.can_offer(gloves))
  	run.unlocked_items = {"undertakers_gloves": true}
  	assert_true(run.can_offer(gloves))
  ```

- [ ] **Step 2: When testing is allowed, run them to make sure they fail.**

- [ ] **Step 3: Implement** the defs, the 12 posters, the four items and the rules. `take` clears `bounty_won`, so a win from before the taking never counts. Update every test that counts items or sums item prices.

- [ ] **Step 4: When testing is allowed, run the tests.**

- [ ] **Step 5: Commit** ("Add a wanted poster for every boss, with its reward").

### Task 12: Deputy Dolores and the Bounty Office

**Files:**
- Create: `scripts/ui/bounty_panel.gd`, `data/npcs/deputy_dolores.tres`
- Modify: `scripts/autoload/progress.gd`, `scripts/core/departments.gd` (stations), `scripts/scenes/waiting_room.gd`
- Test: `tests/test_bounties.gd`

**Interfaces:**
- Consumes: Task 11's `BountyBoard`, Task 10's Condolences.
- Produces:
  - `Progress.take_bounty(def: BountyDef) -> bool` and `Progress.collect_bounty(def: BountyDef) -> Dictionary`. Both save and emit both currency signals.
  - `BountyPanel` (`CanvasLayer`, signal `closed`):
    - It lists `BountyBoard.posters(...)` as rows "WANTED: <boss_name>  <pension> Pension, <condolences> Condolences, + <extra text>".
    - Each row has one button: "Take", "Taken: go get them", "Collect" or disabled "One at a time".
    - `BountyPanel.extra_text(def) -> String` (static): "a recipe for Agnes", "a unique item" or "something to wear".
  - Bounty Office stations:
    - `bounty_board` at (10, 2): a cork board, code-drawn with up to 12 small paper rectangles (one per showing poster, a red "TAKEN" across the taken one). Prompt "Wanted posters".
    - An `Npc` for Deputy Dolores at (10, 6), built from `deputy_dolores.tres`.
    - Talking to her opens the same `BountyPanel` when a poster can be collected, and otherwise says her next line.

`deputy_dolores.tres`:
- `display_name = "Deputy Dolores, Overdue Accounts"`, `color = Color(0.36, 0.42, 0.62, 1)`, `body_size = Vector2(22, 30)`.
- Placeholder lines:
  - "Every soul has a balance. Some are overdue."
  - "Take a poster. Bring me proof. Paperwork is proof."
  - "One account at a time, dear. I'm not made of ink."
  - "Paid in full. Lovely. Next!"

- [ ] **Step 1: Write the failing test:**

  ```gdscript
  func test_the_extra_text_names_what_the_poster_pays() -> void:
  	assert_eq(BountyPanel.extra_text(_poster("senior_adjuster")), "a recipe for Agnes")
  	assert_eq(BountyPanel.extra_text(_poster("tired_undertaker")), "a unique item")
  	assert_eq(BountyPanel.extra_text(_poster("regional_reaper")), "something to wear")
  ```

- [ ] **Step 2: When testing is allowed, run it to make sure it fails.**

- [ ] **Step 3: Implement** the panel, the NPC data, the stations and the `Progress` calls.
  - On collecting, show a HUD notice, for example "Paid: 40 Pension, 10 Condolences, and a recipe for Agnes".
  - The panel is opaque and fits 360 px with 12 rows. Use 9 px font rows, or a `ScrollContainer` when more than 8 show.

- [ ] **Step 4: When testing is allowed, run the tests. Screenshot** the panel with every poster showing (`--dev-all-departments`), with one taken, and with one ready to collect.

- [ ] **Step 5: Commit** ("Open the Bounty Office with Deputy Dolores and her wanted posters").

---

## Step 4: The Training Yard

### Task 13: The dummy

**Files:**
- Create: `scripts/actors/behaviors/dummy_behavior.gd`, `data/enemies/training_dummy.tres`, `scripts/world/training_dummy.gd`
- Modify: `scripts/world/room_view.gd` (`spawn_fixture`), `scripts/scenes/waiting_room.gd`
- Test: `tests/test_training_yard.gd` (new)

**Interfaces:**
- Produces:
  - `DummyBehavior extends EnemyBehavior`. `tick` restores `enemy.hp = enemy.max_hp()` each frame and never moves or attacks. `damage_scale` returns 1.0.
  - `training_dummy.tres`:
    - `id = "training_dummy"`, `display_name = "Intern on a Stand"`, `max_hp = 100000.0`, `speed = 0.0`, `damage = 0`, `pension_drop = 0`
    - `wall_mounted = true` (nothing pushes it), `body_size = Vector2(22, 32)`, `color = Color(0.55, 0.55, 0.6, 1)`
  - `RoomView.spawn_fixture(def: EnemyDef, cell: Vector2i) -> Enemy`: an enemy added after the room has finished, so its doors stay open.
  - `TrainingDummy extends Node2D`:
    - `watch(enemy: Enemy)` listens to `health_changed`.
    - `TrainingDummy.hit_amount(before: float, after: float) -> int` (static): `roundi(before - after)`.
    - Each hit shows a number rising 18 px and fading over 0.8 s, above the dummy's head.
    - Numbers draw on z 50, above the bubble layer.
  - The yard's `RoomView` connects `Player.bomb_requested` to `place_bomb`, so Thermoses work there.

- [ ] **Step 1: Write the failing tests** in `tests/test_training_yard.gd`:

  ```gdscript
  extends TestCase


  func _dummy() -> Enemy:
  	var enemy := Enemy.new()
  	enemy.setup(load("res://data/enemies/training_dummy.tres"), null, 0.5)
  	return enemy


  func test_the_dummy_never_dies() -> void:
  	var enemy := _dummy()
  	var died := [false]
  	enemy.defeated.connect(func(_e: Enemy): died[0] = true)
  	for i in 50:
  		enemy.take_damage(999.0, Vector2.ZERO)
  		DummyBehavior.new().tick(enemy, 0.016)
  	assert_false(died[0])
  	assert_near(enemy.hp, enemy.max_hp())
  	enemy.free()


  func test_the_dummy_pays_nothing() -> void:
  	var def: EnemyDef = load("res://data/enemies/training_dummy.tres")
  	assert_eq(def.pension_drop, 0)
  	assert_false(def.is_boss)


  func test_a_hit_shows_its_damage() -> void:
  	assert_eq(TrainingDummy.hit_amount(100000.0, 99982.0), 18)
  ```

- [ ] **Step 2: When testing is allowed, run them to make sure they fail.**

- [ ] **Step 3: Implement.**
  - The yard spawns the dummy at (10, 5) on first entry.
  - Only the yard ever calls `spawn_fixture`, so the Waiting Room's FloorDef stays enemy-free.
  - Tests keep the dummy out of the tree and call `tick` by hand (lesson: nodes kept out of the tree never run `_ready`).

- [ ] **Step 4: When testing is allowed, run the tests. Screenshot** a combo, a charged swing, the teeth and a Thermos on the dummy, each showing a number.

- [ ] **Step 5: Commit** ("Put a dummy in the Training Yard that shows each hit").

### Task 14: The item rack and Coach Bertram

**Files:**
- Create: `scripts/ui/item_rack_panel.gd`, `scripts/core/coach_tips.gd`, `data/npcs/coach_bertram.tres`
- Modify: `scripts/core/run_state.gd` (`clear_items`), `scripts/world/npc.gd` (`set_lines`), `scripts/core/departments.gd` (stations), `scripts/scenes/waiting_room.gd`, `scripts/autoload/progress.gd` (`mark_coach_met`)
- Test: `tests/test_training_yard.gd`

**Interfaces:**
- Produces:
  - `RunState.clear_items()`: empties `items`, recomputes stats, lowers `max_pills` back through `raise_max`, and emits `changed`.
  - `RunState.YARD_SUPPLY := MAX_CONSUMABLE`.
  - `ItemRackPanel.rack_items(data: ProgressData) -> Array[ItemDef]` (static): every recipe with `data.has_recipe`, crafted or not, in `Content.recipes()` order.
  - `ItemRackPanel`: one "Try <name>" button per rack item, disabled when already held. The signal `taken(item: ItemDef)` fires per button.
  - `Npc.set_lines(lines: Array[String])`: replaces the lines and restarts at the first.
  - `CoachTips.FIRST_VISIT: Array[String]`, `CoachTips.TIPS: Dictionary` (item id → line), `CoachTips.DEFAULT_TIP: String`, and `CoachTips.lines_for(held: Array[ItemDef], first_visit: bool) -> Array[String]`.
  - `Progress.mark_coach_met()`.

**In the yard:**
- **The rack** is a station at (15, 3), titled "Item Rack", with the prompt "Try items".
- **Taking an item** calls `_run.add_item(item)`.
- **Supplies:** on entering the yard, set `_run.bombs = RunState.YARD_SUPPLY`. After each Thermos, set it back to `YARD_SUPPLY`.
- **Leaving the yard**, by any door, calls `_run.clear_items()` and sets `_run.bombs = RunState.STARTING_BOMBS + _run.stats.bonus_bombs`.
- **Coach Bertram** stands at (5, 5).
  - On entering, and on each rack take, call `coach.set_lines(CoachTips.lines_for(_run.items, not Progress.data.coach_met))`.
  - The first talk marks him met.

`coach_bertram.tres`: `display_name = "Coach Bertram, Retired PE Teacher"`, `color = Color(0.25, 0.5, 0.3, 1)`.

`CoachTips` (placeholder lines):
- `FIRST_VISIT`:
  - "Right! Click to swing, hold to charge. Three swings make a combo."
  - "Right click throws the teeth. They come back. Usually."
  - "Space to dodge. Dodging is not running away. It's tactical."
  - "Try anything off the rack. It's free in here. Out there it isn't."
- `TIPS`, one per recipe item:
  - `alert_bracelet`: "Two extra pills. Don't let it make you careless."
  - `bifocals`: "You'll see it coming earlier. Move before the red, not after."
  - `nitro_tablets`: "Big hits. Land the third swing of the combo."
  - `senior_discount`: "More Pension. Doesn't help you hit. Hit anyway."
  - `support_stockings`: "Quicker dodge. Dodge through, not away."
  - `titanium_hip`: "Faster on your feet. Circle them."
- `DEFAULT_TIP`: "Pick something off the rack and I'll tell you what it's good for."
- `lines_for` returns `FIRST_VISIT` on a first visit, else one tip per held rack item in held order, else `[DEFAULT_TIP]`.

- [ ] **Step 1: Write the failing tests:**

  ```gdscript
  func test_the_rack_lists_every_found_recipe_crafted_or_not() -> void:
  	var data := ProgressData.new()
  	data.find_recipe("titanium_hip")
  	data.find_recipe("bifocals")
  	data.items_unlocked["titanium_hip"] = true
  	var ids := ItemRackPanel.rack_items(data).map(func(i): return i.id)
  	assert_eq(ids.size(), 2)
  	assert_true(ids.has("titanium_hip") and ids.has("bifocals"))


  func test_items_tried_in_the_yard_are_gone_on_leaving() -> void:
  	var run := RunState.new([], {})
  	var hip: ItemDef = load("res://data/items/titanium_hip.tres")
  	run.add_item(hip)
  	assert_true(run.stats.move_speed > PlayerStats.BASE_SPEED)
  	run.clear_items()
  	assert_eq(run.items.size(), 0)
  	assert_near(run.stats.move_speed, PlayerStats.BASE_SPEED)


  func test_items_raising_pills_give_them_back_on_leaving() -> void:
  	var run := RunState.new([], {})
  	run.add_item(load("res://data/items/alert_bracelet.tres"))
  	run.clear_items()
  	assert_eq(run.health.max_pills, PlayerStats.BASE_PILLS)
  	assert_true(run.health.pills <= run.health.max_pills)


  func test_the_coach_has_a_tip_for_every_recipe() -> void:
  	for item in Content.recipes():
  		assert_true(CoachTips.TIPS.has(item.id), item.id)
  	assert_eq(CoachTips.lines_for([], true), CoachTips.FIRST_VISIT)
  	assert_eq(CoachTips.lines_for([], false), [CoachTips.DEFAULT_TIP])
  ```

- [ ] **Step 2: When testing is allowed, run them to make sure they fail.**

- [ ] **Step 3: Implement.**
  - The Waiting Room's own run must never carry yard items into a run. `Game.begin_run()` changes scene, and `floor_scene` makes a fresh run, so this holds already. Add a scene comment saying so.
  - `CoachTips.TIPS` is checked against `Content.recipes()` by the test, so a new recipe without a tip fails it.

- [ ] **Step 4: When testing is allowed, run the tests. Screenshot** the rack panel with all six recipes, and the coach's bubble.

- [ ] **Step 5: Commit** ("Add the item rack and Coach Bertram to the Training Yard").

---

## Step 5: The Decor Office and Grandpa cosmetics

### Task 15: Cosmetic data, the Decor Office and the lobby decor

**Files:**
- Create: `scripts/content/cosmetic_def.gd`, `data/cosmetics/` (16 files), `scripts/ui/decor_panel.gd`, `scripts/world/lobby_decor.gd`
- Modify: `scripts/core/progress_data.gd`, `scripts/autoload/progress.gd`, `scripts/core/departments.gd` (the `decor_counter` station), `scripts/scenes/waiting_room.gd`
- Test: `tests/test_cosmetics.gd` (new)

**Interfaces:**
- Produces:
  - `CosmeticDef` (`Resource`):
    - `id`, `display_name`, `description`
    - `slot: String` (`SLOT_HAT`, `SLOT_CARDIGAN`, `SLOT_CANE` or `SLOT_DECOR`)
    - `price: int` (Condolences; 0 means bounty only, never sold)
    - `color: Color`, `shape: String`
  - `CosmeticDef.DIR := "res://data/cosmetics/"` and `CosmeticDef.all() -> Array[CosmeticDef]` (static, via `Content.load_dir`).
  - `ProgressData`:
    - `owns_cosmetic(id) -> bool`
    - `can_buy_cosmetic(def: CosmeticDef) -> bool`: `price > 0`, not owned, enough Condolences
    - `buy_cosmetic(def) -> bool`
    - `wear(def) -> bool`: owned and not decor, sets `cosmetics_worn[slot]`
    - `take_off(slot: String)`
  - `Progress.buy_cosmetic(def) -> bool` and `Progress.wear(def) -> bool`, both saving. `buy_cosmetic` emits `condolences_changed`.
  - `LobbyDecor extends Node2D`: `setup(owned: Dictionary)`. `LobbyDecor.SPOTS: Dictionary` maps decor id to a lobby cell, and `LobbyDecor.draw_kind(canvas, kind, at)` (static) draws each kind.
  - The `decor_counter` station in the Decor Office at (10, 4), titled "Decor Office. Sympathy in Every Shade", with the prompt "Browse".

**The cosmetics:**

| id | slot | price | shape | colour |
|---|---|---|---|---|
| `flat_cap` | hat | 30 | `flat_cap` | `5a4a3a` |
| `party_hat` | hat | 40 | `cone` | `e4524f` |
| `reaper_hood` | hat | 0 | `hood` | `1a1620` |
| `fountain_tiara` | hat | 0 | `tiara` | `ffd24a` |
| `mustard_cardigan` | cardigan | 25 | `band` | `c9a23c` |
| `burgundy_cardigan` | cardigan | 25 | `band` | `7a2a3a` |
| `bingo_teal` | cardigan | 0 | `band` | `2f8f8a` |
| `polished_oak` | cane | 35 | `cane` | `9a6a3a` |
| `candy_stripe` | cane | 45 | `stripe` | `f4efe2` |
| `sooty_cane` | cane | 0 | `cane` | `2a2622` |
| `potted_fern` | decor | 20 | `fern` | `4a8a4a` |
| `motivational_poster` | decor | 15 | `poster` | `d9c9a0` |
| `better_chair` | decor | 40 | `chair` | `8a4f3a` |
| `warm_lamps` | decor | 30 | `lamps` | `ffc070` |
| `fish_tank` | decor | 60 | `tank` | `3c8ac9` |
| `new_carpet` | decor | 50 | `carpet` | `6a2a3a` |

**The decor:**
- Spots in the lobby, each clear of every station (floor cells, or wall faces where marked):

  | Decor | Cell |
  |---|---|
  | fern | (2, 2) |
  | poster | (9, 1), a wall face |
  | chair | (3, 8) |
  | lamps | (8, 1) and (21, 1), wall faces |
  | tank | (27, 8) |

- The carpet is a 10×5 rug centred on (15, 6), drawn under everything at z −1.
- `warm_lamps` also adds two `Lighting.make_light(Color("ffc070"), 0.6, 1.0)` at its spots.

**`DecorPanel`:**
- Two tabs (two `Button`s that switch the list): "For the Waiting Room" and "For Grandpa".
- **A decor row:** "Buy (N Condolences)" or "Placed".
- **A Grandpa row:** "Buy (N)", "Wear", "Take off", or "Bounty reward" when price is 0 and it is not owned.
- The status line shows Condolences.
- Opaque, and fits 360 px with 10 rows.

- [ ] **Step 1: Write the failing tests** in `tests/test_cosmetics.gd`:

  ```gdscript
  extends TestCase


  func _cosmetic(id: String) -> CosmeticDef:
  	for def in CosmeticDef.all():
  		if def.id == id:
  			return def
  	return null


  func test_the_set_is_complete_and_every_bounty_cosmetic_exists() -> void:
  	assert_eq(CosmeticDef.all().size(), 16)
  	for poster in BountyBoard.all():
  		if poster.extra_kind == BountyDef.EXTRA_COSMETIC:
  			var def := _cosmetic(poster.extra_id)
  			assert_true(def != null, poster.extra_id)
  			assert_eq(def.price, 0, "%s is never sold" % poster.extra_id)


  func test_condolences_buy_and_bounty_ones_are_never_for_sale() -> void:
  	var data := ProgressData.new()
  	data.condolences = 100
  	assert_true(data.buy_cosmetic(_cosmetic("flat_cap")))
  	assert_eq(data.condolences, 70)
  	assert_false(data.buy_cosmetic(_cosmetic("flat_cap")), "owned already")
  	assert_false(data.buy_cosmetic(_cosmetic("reaper_hood")))


  func test_one_worn_per_slot_and_decor_is_never_worn() -> void:
  	var data := ProgressData.new()
  	data.cosmetics_owned = {"flat_cap": true, "party_hat": true, "potted_fern": true}
  	assert_true(data.wear(_cosmetic("flat_cap")))
  	assert_true(data.wear(_cosmetic("party_hat")))
  	assert_eq(data.cosmetics_worn, {CosmeticDef.SLOT_HAT: "party_hat"})
  	assert_false(data.wear(_cosmetic("potted_fern")))
  	assert_false(data.wear(_cosmetic("candy_stripe")), "not owned")


  func test_cosmetics_carry_no_stats() -> void:
  	# Condolences buy looks only. CosmeticDef is not a StatEffect, so nothing can add it to the stats.
  	assert_false(CosmeticDef.new() is StatEffect)


  func test_every_decor_item_has_a_spot_on_lobby_floor_clear_of_stations() -> void:
  	var lobby: RoomLayout = Departments.load_layouts()[Departments.LOBBY]
  	var station_cells := []
  	for entry: Dictionary in Departments.STATIONS + Departments.MERCHANTS:
  		if entry["department"] == Departments.LOBBY:
  			station_cells.append(entry["cell"])
  	for def in CosmeticDef.all():
  		if def.slot != CosmeticDef.SLOT_DECOR or def.id == "new_carpet":
  			continue
  		for cell: Vector2i in LobbyDecor.cells_of(def.id):
  			assert_false(station_cells.has(cell), def.id)
  			assert_true(cell.x > 0 and cell.x < lobby.size_in_cells().x - 1, def.id)
  ```

  `LobbyDecor.cells_of(id) -> Array[Vector2i]` returns the one or two cells of an id.

- [ ] **Step 2: When testing is allowed, run them to make sure they fail.**

- [ ] **Step 3: Implement** the defs, the data, the rules, the panel, `LobbyDecor` and the station. The lobby rebuilds its `LobbyDecor` when the panel closes.

- [ ] **Step 4: When testing is allowed, run the tests. Screenshot** the panel's two tabs, and the lobby bare and with all six decor items.

- [ ] **Step 5: Commit** ("Open the Decor Office and furnish the lobby with Condolences").

### Task 16: Grandpa's cosmetics on screen

**Files:**
- Create: `scripts/world/grandpa_look.gd`
- Modify: `scripts/core/run_state.gd` (`look`), `scripts/autoload/progress.gd` (`make_run`), `scripts/actors/player.gd`
- Test: `tests/test_cosmetics.gd`

**Interfaces:**
- Produces:
  - `RunState.look: Dictionary` (slot → `CosmeticDef`), set by `Progress.make_run()` from `cosmetics_worn`. Unknown ids are skipped.
  - `GrandpaLook extends Node2D`: `setup(look: Dictionary)`.
    - It draws a hat over the head and a cardigan band over the chest, on z 1 above the sprite.
    - Its static `cane_color(look: Dictionary, fallback: Color) -> Color` gives the cane's colour.
  - `Player` adds a `GrandpaLook` in `_ready` when `run.look` is not empty.
    - The placeholder cane line and the swing arc use `GrandpaLook.cane_color(run.look, <today's colour>)`.
    - A `stripe` cane also draws three short red bands along the line.

**Hat shapes (placeholders):**
- `flat_cap`: a flat rounded rect with a peak.
- `cone`: a triangle with a dot on top.
- `hood`: a dark arc over the head down to the shoulders.
- `tiara`: three small gold points.

Each is drawn relative to the sprite's head. The head offset is `Vector2(0, -22)` for the 68 px frame. Check it by screenshot.

- [ ] **Step 1: Write the failing tests:**

  ```gdscript
  func test_make_run_carries_what_is_worn() -> void:
  	var data := ProgressData.new()
  	data.cosmetics_owned = {"party_hat": true}
  	data.cosmetics_worn = {CosmeticDef.SLOT_HAT: "party_hat", CosmeticDef.SLOT_CANE: "no_such_cane"}
  	var look := RunState.look_from(data.cosmetics_worn, CosmeticDef.all())
  	assert_eq(look.size(), 1)
  	assert_eq((look[CosmeticDef.SLOT_HAT] as CosmeticDef).id, "party_hat")


  func test_the_cane_colour_falls_back_without_a_skin() -> void:
  	assert_eq(GrandpaLook.cane_color({}, Color.WHITE), Color.WHITE)
  	assert_eq(GrandpaLook.cane_color({CosmeticDef.SLOT_CANE: _cosmetic("sooty_cane")}, Color.WHITE), Color("2a2622"))


  func test_a_worn_look_changes_no_stat() -> void:
  	var plain := RunState.new([], {})
  	var dressed := RunState.new([], {})
  	dressed.look = {CosmeticDef.SLOT_HAT: _cosmetic("party_hat")}
  	assert_near(dressed.damage_mult(), plain.damage_mult())
  	assert_near(dressed.move_speed(), plain.move_speed())
  ```

  `RunState.look_from(worn: Dictionary, all: Array[CosmeticDef]) -> Dictionary` (static) is what `make_run` calls, so the test needs no autoload.

- [ ] **Step 2: When testing is allowed, run them to make sure they fail.**

- [ ] **Step 3: Implement** `GrandpaLook`, `look_from` and the player hooks. The look is drawn both in the Waiting Room and in runs.

- [ ] **Step 4: When testing is allowed, run the tests and one full loop. Screenshot** Grandpa in each hat, each cardigan and each cane, standing, walking and swinging, in the lobby and on the Mall's pale tile (lesson: check effects over each floor's palest tile).

- [ ] **Step 5: Commit** ("Draw Grandpa's hats, cardigans and cane skins as placeholders").

---

## Step 6: The ticket number, letters and the Dealer's back room

### Task 17: Ticket rules and the cursed run

**Files:**
- Create: `scripts/core/ticket_rules.gd`
- Modify: `scripts/core/progress_data.gd`, `scripts/autoload/progress.gd`, `scripts/core/run_state.gd`, `scripts/world/room_view.gd` (`_spawn_enemy`), `scripts/scenes/floor_scene.gd`
- Test: `tests/test_tickets_and_letters.gd` (new)

**Interfaces:**
- Produces:
  - `TicketRules.CALL_EVERY := 5`, `CLERK_DEAL := "clerk_deal"`, `NEW_ARRIVAL := "new_arrival"`, `CURSED_OFFER := "cursed_offer"`, and `EVENTS := [CLERK_DEAL, NEW_ARRIVAL, CURSED_OFFER]`.
  - `TicketRules.event_for(ticket: int) -> String`: `""` unless `ticket > 0 and ticket % CALL_EVERY == 0`, else `EVENTS[(ticket / CALL_EVERY - 1) % EVENTS.size()]`.
  - `TicketRules.deal_form(upgrades: Array[UpgradeDef], data: ProgressData, roll: float) -> String`: one form not yet maxed, or `""`.
  - `TicketRules.ARRIVAL_LINES: Array[String]`, placeholder one-liners by open NPCs, and `TicketRules.arrival_line(open_department_ids: Array, roll: float) -> String`.
  - Cursed run numbers: `CURSED_HEALTH_MULT := 1.25`, `CURSED_PENSION_MULT := 1.5`.
  - `ProgressData.call_ticket(upgrades: Array[UpgradeDef], roll: float) -> String`. When `ticket_called < run_count`, it sets `ticket_called = run_count` and applies the event: it sets `clerk_deal` or sets `cursed_offer`. It returns the event, or `""`.
  - `ProgressData.accept_cursed_ticket() -> bool` (only while `cursed_offer`) and `take_cursed_run() -> bool` (returns and clears `cursed_next_run`).
  - `ProgressData.start_run()` also clears `clerk_deal` and `cursed_offer`.
  - `Progress.call_ticket() -> String`, `Progress.accept_cursed_ticket() -> bool` and `Progress.take_cursed_run() -> bool`.
  - `RunState.cursed: bool`, `RunState.enemy_health_mult() -> float` and `RunState.enemy_pension_mult() -> float`.

`ARRIVAL_LINES` (placeholders, each prefixed by who says it):
- "Black Market: Psst. New stock. Same old you."
- "Dr. Squint: Your eyes look tired. Or dead. Hard to say."
- "Agnes: I knitted you something. Then I unknitted it."
- "Deputy Dolores: Your file has grown a second file."
- "Coach Bertram: Drop and give me twenty. Pills, I mean."

`arrival_line` only picks a speaker whose department is open. Black Market, Dr. Squint and Agnes are in the lobby.

- [ ] **Step 1: Write the failing tests** in `tests/test_tickets_and_letters.gd`:

  ```gdscript
  extends TestCase


  func test_every_fifth_ticket_is_called_and_the_events_cycle() -> void:
  	assert_eq(TicketRules.event_for(4), "")
  	assert_eq(TicketRules.event_for(5), TicketRules.CLERK_DEAL)
  	assert_eq(TicketRules.event_for(10), TicketRules.NEW_ARRIVAL)
  	assert_eq(TicketRules.event_for(15), TicketRules.CURSED_OFFER)
  	assert_eq(TicketRules.event_for(20), TicketRules.CLERK_DEAL)


  func test_a_ticket_is_called_once() -> void:
  	var data := ProgressData.new()
  	data.run_count = 5
  	data.ticket_called = 4
  	assert_eq(data.call_ticket(Content.upgrades(), 0.0), TicketRules.CLERK_DEAL)
  	assert_false(data.clerk_deal.is_empty())
  	assert_eq(data.call_ticket(Content.upgrades(), 0.0), "")


  func test_the_deal_lasts_one_visit() -> void:
  	var data := ProgressData.new()
  	data.clerk_deal = "reinforced_cane"
  	data.start_run()
  	assert_eq(data.clerk_deal, "")


  func test_the_deal_never_picks_a_maxed_form() -> void:
  	var data := ProgressData.new()
  	for def in Content.upgrades():
  		data.upgrades[def.id] = def.max_level()
  	assert_eq(TicketRules.deal_form(Content.upgrades(), data, 0.5), "")


  func test_the_cursed_ticket_is_opt_in_and_lasts_one_run() -> void:
  	var data := ProgressData.new()
  	assert_false(data.accept_cursed_ticket(), "only when offered")
  	data.cursed_offer = true
  	assert_true(data.accept_cursed_ticket())
  	assert_true(data.take_cursed_run())
  	assert_false(data.take_cursed_run())


  func test_a_cursed_run_is_tougher_and_pays_more() -> void:
  	var run := RunState.new([], {})
  	run.cursed = true
  	assert_near(run.enemy_health_mult(), 1.25)
  	assert_near(run.enemy_pension_mult(), 1.5)
  	assert_near(RunState.new([], {}).enemy_health_mult(), 1.0)
  ```

- [ ] **Step 2: When testing is allowed, run them to make sure they fail.**

- [ ] **Step 3: Implement.**
  - **`RoomView._spawn_enemy`:** `enemy.apply_floor(_floor_def.health_mult * _run.enemy_health_mult(), _floor_def.pension_mult * _run.enemy_pension_mult())`.
  - **The start of a cursed run:** in `floor_scene._ready`, `_run.cursed = Progress.take_cursed_run()`. When it is cursed, show the notice "Cursed ticket: they hit harder, and pay better".
  - **Clears in a cursed run:** in `floor_scene._on_floor_cleared`, also call `Progress.add_condolences(ProgressData.CURSED_FLOOR_CONDOLENCES)` with a notice.

- [ ] **Step 4: When testing is allowed, run the tests.**

- [ ] **Step 5: Commit** ("Call every fifth ticket for a deal, an arrival or a cursed run").

### Task 18: The ticket machine, letters and the noticeboard

**Files:**
- Create: `scripts/core/letter_book.gd`, `scripts/ui/ticket_panel.gd`, `scripts/ui/noticeboard_panel.gd`
- Modify: `scripts/core/progress_data.gd` (`read_letter`), `scripts/autoload/progress.gd`, `scripts/core/departments.gd` (stations), `scripts/scenes/waiting_room.gd`
- Test: `tests/test_tickets_and_letters.gd`, `tests/test_save_migration.gd`

**Interfaces:**
- Produces:
  - `LetterBook.LETTERS: Array[Dictionary]`, in floor order, each `{"path", "from", "text"}`.
  - `LetterBook.arrived(data) -> Array[Dictionary]` (letters whose path is cleared), `LetterBook.unread(data) -> Array[Dictionary]`, and `ProgressData.read_letter(path_id: String)`.
  - `Progress.read_letter(path_id)`.
  - `TicketPanel`:
    - shows "Your ticket: N" (`run_count + 1`), "Every fifth number is called."
    - while `cursed_offer`, shows a "Take the cursed ticket" button and a "No thanks" button
    - shows "Deal of the visit: <form> 25% off" while `clerk_deal` is set
  - `NoticeboardPanel`: a list of arrived letters, unread ones marked "NEW". Clicking one shows its text and marks it read.
  - Lobby stations:
    - `ticket_machine` at (23, 3): a red box with a paper tongue, prompt "Ticket".
    - `noticeboard` at (23, 7): cork, prompt "Read", drawing a small "NEW" when anything is unread.
  - The lobby's top text becomes `"YOUR TICKET: %d   NOW SERVING: %d" % [run_count + 1, called]`. `called` is `run_count` on a called visit, drawn in red with "Called!". Otherwise it is 666.

**On arrival**, after the department notices:
1. `var event := Progress.call_ticket()`.
2. Show the event's notice:
   - a clerk deal: "Number %d! The clerk slips you a deal on %s."
   - a new arrival: its line
   - a cursed offer: "Number %d! A cursed ticket is on offer at the machine."
3. If `LetterBook.unread` is not empty: "A letter has arrived on the noticeboard."

**Letters** (placeholder text, to be written later):

| path | from | text |
|---|---|---|
| `floor_1` | Your neighbour | "Your hedge is finally mine. Rest in peace, you old goat." |
| `cemetery` | The parish | "Your plot is paid for. Please stop leaving it." |
| `sunset_shores` | Sunset Shores | "Your room has been let. We kept the slippers." |
| `furnace_works` | The crematorium | "Re: your booking. Postponed until further notice." |
| `funeral_parlour` | Your son | "Dad, the service was lovely. Mum said you'd have hated it." |
| `golden_years_mall` | Your granddaughter | "Grandpa, I walked your dog at the mall. He waited by the bench." |

- [ ] **Step 1: Write the failing tests:**

  ```gdscript
  func test_a_letter_arrives_with_each_floors_first_clear() -> void:
  	var data := ProgressData.new()
  	assert_eq(LetterBook.arrived(data).size(), 0)
  	data.record_floor_cleared(1, "floor_1")
  	assert_eq(LetterBook.arrived(data).size(), 1)
  	data.record_floor_cleared(1, "floor_1")
  	assert_eq(LetterBook.arrived(data).size(), 1, "one per floor, not per clear")


  func test_reading_a_letter_marks_it() -> void:
  	var data := ProgressData.new()
  	data.record_floor_cleared(1, "floor_1")
  	assert_eq(LetterBook.unread(data).size(), 1)
  	data.read_letter("floor_1")
  	assert_eq(LetterBook.unread(data).size(), 0)


  func test_every_path_has_a_letter() -> void:
  	var paths := LetterBook.LETTERS.map(func(l): return l["path"])
  	for id in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "golden_years_mall"]:
  		assert_true(paths.has(id), id)
  ```

  Append to `tests/test_save_migration.gd`:

  ```gdscript
  func test_old_saves_receive_the_letters_of_floors_already_cleared() -> void:
  	assert_eq(LetterBook.unread(_today()).size(), 5)
  ```

- [ ] **Step 2: When testing is allowed, run them to make sure they fail.**

- [ ] **Step 3: Implement** the book, the panels, the stations and the lobby text.

- [ ] **Step 4: When testing is allowed, run the tests. Screenshot** the ticket panel with a cursed offer and a deal, and the noticeboard with six letters.

- [ ] **Step 5: Commit** ("Add the ticket machine and letters on the noticeboard").

### Task 19: The Dealer's back room

**Files:**
- Create: `data/npcs/dealer_back_room.tres`
- Modify: `scripts/world/room_view.gd` (`add_arcade_tables`), `scripts/scenes/waiting_room.gd`, `data/npcs/dealer.tres` (more lines)
- Test: `tests/test_arcade_room.gd`

**Interfaces:**
- Produces:
  - `RoomView.add_arcade_tables(games: Array[String], dealer: NpcDef)`. It places the dealer at `merchant_cell()` and one table per `G` cell, cycling `games`. `_create_arcade()` becomes `add_arcade_tables(ArcadeTable.GAMES, DEALER)`, so Arcade Rooms are unchanged.
  - `Departments.BACK_ROOM_GAMES := [ArcadeTable.BLACKJACK, ArcadeTable.POKER]`.
  - The Waiting Room opens `CardTablePanel` from the Back Room's `arcade_game_wanted`, exactly as `floor_scene._open_card_table` and `_close_card_table` do: the guard on the closing frame, and the mouse shown while open. The bank is `Progress` through the view, so bets come from and go to Pension.
  - Re-entering the Back Room calls `refresh_doors()`, which refills both tables.
  - The loadout bench cells stay plain floor. Nothing is drawn or placed there (decision 23).

**The Dealer's lines** (placeholders):
- `dealer.tres` gets more Arcade lines, keeping the four already there:
  - "Sit down, sit down. Your luck's due. Statistically."
  - "Grief is a gamble. So is this, but with prizes."
- `dealer_back_room.tres` (`display_name = "The Dealer"`, same colour):
  - "Members only. You're a member now. Congratulations, and condolences."
  - "Same odds as the Arcade. I'm a man of principle. Small principle."
  - "Cards, not slots. Slots are for amateurs and the living."
  - "Keep the bench clear. Something's coming for it."

- [ ] **Step 1: Write the failing test** in `tests/test_arcade_room.gd`:

  ```gdscript
  func test_the_back_room_holds_two_card_tables_at_the_arcades_odds() -> void:
  	var back: RoomLayout = Departments.load_layouts()[Departments.BACK_ROOM]
  	assert_eq(back.cells_of(RoomLayout.SYMBOL_GAME).size(), Departments.BACK_ROOM_GAMES.size())
  	assert_false(Departments.BACK_ROOM_GAMES.has(ArcadeTable.SLOT))
  	assert_true(back.merchant_cell() != Vector2i(-1, -1), "room for the Dealer")
  ```

  The odds need no new test. The tables are the Arcade's own `Blackjack` and `DrawPoker`, whose returns `test_arcade_rules.gd` already checks.

- [ ] **Step 2: When testing is allowed, run it to make sure it fails.**

- [ ] **Step 3: Implement** `add_arcade_tables`, the NPC data and the scene wiring.

- [ ] **Step 4: When testing is allowed, run the tests and one full loop**, which still plays the Arcade through `_create_arcade`. **Screenshot** the Back Room and a hand of blackjack there.

- [ ] **Step 5: Commit** ("Give the Dealer a private card room in the Waiting Room").

---

## Step 7: Wrap-up

### Task 20: The full loop walks the departments, the bounty and the forms

**Files:**
- Modify: `tools/smoke_driver.gd`, `docs/playtest-notes.md`, `LESSONS.md`

**Interfaces:**
- Consumes: the scene API from Task 4 (`open_department_ids`, `current_department`, `debug_enter_department`, `station`, `use_station`, `open_panel`), plus `Progress.take_bounty`, `collect_bounty`, `buy`, `refile`, `buy_cosmetic` and `wear`.
- Produces new driver checks:
  - `_check_departments_at_start()`
  - `_check_forms()`
  - `_take_first_bounty()`
  - `_check_bounty_collected()`
  - `_walk_every_department()`
  - `_check_training_yard()`
  - `_check_decor()`
  - `_check_ticket_and_letters()`

  It also adds the flags `_checked_departments`, `_checked_forms`, `_checked_bounty`, `_checked_yard` and `_checked_decor`.

- [ ] **Step 1: At the start of `_run`**, after the opening:
  - **`_check_departments_at_start`:**
    - `open_department_ids() == ["lobby", "hallway"]`.
    - Walk Grandpa onto the lobby's west door and check `current_department() == "hallway"`.
    - Stand on the Bounty Office door and check it is chained and he stays in the lobby.
  - **`_check_forms`:** replaces today's `Progress.buy(Content.upgrades()[0])`.
    - Add 1000 Pension.
    - Through `use_station("black_market")`, file Reinforced Cane levels 1 and 2. Press the panel's "File: Lightweight" button, found by its text, not by `Progress.buy`.
    - Check `choice_of == "b"` and `Progress.make_run().stats.swing_speed > 1.0`.
    - Check `refile_price == 0`, refile through `use_station("forms_counter")`, and check option A with Pension unchanged.
    - Refile again, and check 40 was taken.
    - Close the panels with the `interact`/close path the driver already uses for overlays (lesson: `Input.action_press` sends no InputEvent).
    - Keep `upgrade` set to the cane for the existing "upgrade survives a reload" check, which now expects level 2.
  - **`_take_first_bounty`:**
    - Check the Bounty Office is closed, then `Progress.take_bounty` of the `senior_adjuster` poster. The rule allows a reachable poster before its office opens, since the board's rules don't need the room. This checks only the rules.
    - Check `bounty_taken` survives `Progress.reload()`.

- [ ] **Step 2: After the first `_clear_three_floors`:**
  - **`_check_bounty_collected`:**
    - The first run cleared `floor_1`, `sunset_shores` and `funeral_parlour`. Check exactly the Bounty Office, the Apothecary Wing and the Decor Office opened, beside the lobby and hallway.
    - Check `bounty_won`.
    - Enter the Bounty Office, `use_station("bounty_board")`, and press "Collect".
    - Check the poster's Pension and Condolences arrived, Agnes has `support_stockings`, and `bounty_taken == ""`.
  - **`_check_decor`:**
    - Enter the Decor Office.
    - Buy the fern through the panel, after adding Condolences directly. Only the purchase is under test.
    - Check the lobby's `LobbyDecor` has it.
    - Buy and wear the flat cap, and check `Progress.make_run().look` has it.

- [ ] **Step 3: After the second `_clear_three_floors`:**
  - **`_walk_every_department`:**
    - Every department is open. Walk to each through its doors with the driver's `_walk_through_door`, and check `current_department()`.
    - In each, check the stations expected from `Departments.STATIONS` and `MERCHANTS` stand there.
    - Check the trophy wall shows six mementos.
  - **`_check_training_yard`:**
    - In the yard, take a found recipe from the rack.
    - Swing at the dummy and check it is alive, a damage number showed, and a Thermos still leaves 99.
    - Leave by a door and check `_run.items` is empty.
  - **`_check_ticket_and_letters`:**
    - Set `run_count` to the next multiple of 15 at or above it (a cursed-offer ticket) and `ticket_called` to `run_count - 1`, then `Game.return_to_waiting()`.
    - Check the cursed offer is shown, accept it at the machine, and check the next run's `_run.cursed`. Use the start of `_die_in_a_run`.
    - Check the noticeboard lists six letters and reading one marks it.
  - **Condolences:** check `Progress.data.condolences > 0` and `bosses_beaten.size() == 12`, if the loop beat every mini boss. Otherwise assert at least the six floor bosses.
  - **The pass line** adds: departments walked, forms checked, bounty collected, yard checked, decor checked.

- [ ] **Step 4: Update `docs/playtest-notes.md`** with what to try:
  - each department's opening
  - filing a milestone and refiling
  - a poster from take to collect
  - the yard
  - decor and a hat
  - a called ticket
  - a letter
  - the Back Room

  Add anything tricky to `LESSONS.md`.

- [ ] **Step 5: When testing is allowed, run the tests and 3 full loops** from an exported copy (`git archive`, renamed `config/name`). Expected: `0 failed`, and `SMOKE PASS` three times with every new flag true. Compare the real save's MD5 before and after.

- [ ] **Step 6: Commit** ("Walk the departments, a bounty and the forms in the full loop"), then push.

### Task 21: Full verification and independent review

- [ ] **Step 1: When testing is allowed**, check no game window is open and record the real save's MD5. Then run the whole suite:

  ```powershell
  powershell -File tools/test.ps1
  ```

  Expected: `N tests, 0 failed`, with no `SCRIPT ERROR`.

- [ ] **Step 2: Run 3 full loops** from an exported copy of the branch tip:

  ```powershell
  powershell -File tools/smoke.ps1
  ```

  Expected: `SMOKE PASS ...` each time. Read the whole tail, not a filtered line. Check the real save's MD5 is unchanged.

- [ ] **Step 3: Load the user's real save read-only.** Copy `%APPDATA%\Godot\app_userdata\Grandpa\save.json` into the scratchpad, never into the game's user folder. Run a one-off headless probe that calls `ProgressData.from_dict` on the copy and prints:
  - levels
  - `choice_of` for each form
  - `Departments.open_ids`
  - `Mementos.hung`
  - `LetterBook.unread`

  It must load with every upgrade level intact. Delete the probe afterwards, and do not commit it.

- [ ] **Step 4: Dispatch one independent reviewer** on the strongest model, read-only, over `git diff third-floor...waiting-room` against the spec and this plan.
  - The brief forbids running Godot and touching the real save.
  - It asks about save compatibility, Condolences ever buying power, panels running off 360 px, any lambda capturing `self` on a signal, and RefCounted helpers kept alive only by a signal.

- [ ] **Step 5: Verify each finding by reading the code.** Fix the confirmed ones, one commit each with a test, then re-run the tests and 3 full loops.

- [ ] **Step 6: Push** `waiting-room`, and write a short report for the user in the style of `docs/night-report-2026-11-03.md`:
  - what was built
  - the screenshots taken
  - the decisions above, open to veto
  - what to try first

  Don't merge until the user has played it.
