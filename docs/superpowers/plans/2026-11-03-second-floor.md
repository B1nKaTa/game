# Second Floor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Beating a first-floor boss leads to a choice of two items, a stairwell, a healing landing and a second Crossroads. From there two second-floor paths, Sunset Shores Eternal Care and the Furnace Works, are each complete with enemies, bosses, hazards and rooms.

**Architecture:**
- **Depth:** the floor scene gains a current depth (1 or 2). `_continue_after_floor` either opens the way down or ends the run.
- **Unlocks:** these become depth-aware through `ProgressData.clears_at(depth)`, a set of cleared path ids, and a frozen `legacy_clears` value that keeps old saves' merchants open.
- **Content:** each path is a `FloorDef` with its own layouts, palette, enemies and bosses, built the same way as the Cemetery. New behaviors follow the existing behavior scripts.

**Tech Stack:** Godot 4.7.2 standard, GDScript, `gl_compatibility`, 640×360 viewport, nodes built in code, `.tres` data, headless tests.

**Spec:** `docs/superpowers/specs/2026-11-03-second-floor-design.md`. Read it before any task. The spec governs where this plan is silent.

## Global Constraints

- Never name another game in any file, comment, asset name or commit message.
- Ask before adding dependencies. None are needed.
- Commit messages are in the imperative mood, one logical change per commit, and end with a blank line and then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Append dated lessons to `LESSONS.md` (`- 2026-11-03: <what happened> → <rule>`) when a bug or gotcha teaches something.
- Leave the project runnable after every commit.
- Every attack shows its warning circle first, and attacks that travel in a line also show a lane. Bosses start attacks only with their whole body in view (`BossMoves.in_view`).
- Summoned enemies pay no Pension.
- Old saves must load. Every new save field is optional and has a fallback.
- Scripts loaded by tests must not reference autoloads. Pass `Progress` in as `_bank`, as `RoomView` already does.
- **When the user is playing:** never launch Godot or run tests while the user's game window is open. Check with:

  ```powershell
  Get-CimInstance Win32_Process -Filter "Name like 'Godot%'" | Select-Object ProcessId, CommandLine
  ```

  A process whose command line has no `--headless` and points at a project path is the user's game. Wait, or ask the controller.
- **The real save:** never run a scene without `--smoke`, because that writes to `%APPDATA%\Godot\app_userdata\Grandpa\save.json`.
- Commands, run from `C:\GameDev\game\.worktrees\next-build`:

  ```powershell
  powershell -File tools/test.ps1   # ends with "N tests, 0 failed"
  powershell -File tools/smoke.ps1  # prints "SMOKE PASS ..." or "SMOKE FAIL: ..."
  ```

  Read the summary line, not a piped exit code. After a run, `git checkout -- art/sprites` clears line-ending-only `.import` churn.
- **Repeated full-loop runs:** export the commit with `git archive` and rename `config/name` in the copy so it gets its own user folder. See `LESSONS.md`.

---

## File structure

**New pure rules (tested headlessly):**
- `scripts/core/choice_group.gd`: a set of pickups where taking one removes the rest.
- `scripts/core/slow_effect.gd`: a timed movement slow, used by sedatives.
- `scripts/core/vent_cycle.gd`: when a floor vent warns and flares.

**Changed:**
- `scripts/core/progress_data.gd`: `deep_clears`, `paths_cleared`, `legacy_clears`, `clears_at()`, `record_floor_cleared(depth, path_id)`.
- `scripts/autoload/progress.gd`: `record_floor_cleared(depth, path_id)`.
- `scripts/core/merchant_rules.gd`: entries open by depth clears, by cleared paths, or by legacy clears.
- `scripts/content/floor_def.gd`: `depth`, `open_after_depth`, `health_mult`, `pension_mult`, `enemies_by_size`.
- `scripts/scenes/waiting_room.gd`: the new merchant rules.
- `scripts/world/crossroads_view.gd`: `setup_paths(paths, data)` takes the `ProgressData`.
- `scripts/scenes/floor_scene.gd`: depth, paths by depth, stairwell, landing, second Crossroads, end point.
- `scripts/world/room_view.gd`: the boss item choice, the stairwell door, floor multipliers, hazards.
- `scripts/actors/player.gd`: slow and sliding.
- `scripts/actors/enemy.gd`: floor multipliers at spawn.

**New world and actors:**
- `scripts/world/wet_floor.gd` and `scripts/world/floor_vent.gd`.
- **Regular behaviors:** `scripts/actors/behaviors/orderly_behavior.gd`, `cart_nurse_behavior.gd`, `bingo_caller_behavior.gd`, `stoker_behavior.gd`, `steam_valve_behavior.gd`, `soot_ghost_behavior.gd`.
- **Boss behaviors:** `activities_coordinator_behavior.gd`, `matron_behavior.gd`, `foreman_behavior.gd`, `chief_stoker_behavior.gd`.

**New data:**
- `data/floors/landing.tres`, `crossroads_2.tres`, `sunset_shores.tres`, `furnace_works.tres`.
- `data/rooms/landing/`, `data/rooms/sunset_shores/` and `data/rooms/furnace_works/`.
- One `.tres` per new enemy in `data/enemies/`.

---

## Step 1: The connection

### Task 1: Clears by depth, cleared paths and kept merchants

**Files:**
- Modify: `scripts/core/progress_data.gd`, `scripts/autoload/progress.gd`, `scripts/core/merchant_rules.gd`, `scripts/content/floor_def.gd`, `scripts/scenes/waiting_room.gd`, `scripts/world/crossroads_view.gd`, `scripts/scenes/floor_scene.gd:127,191`, `tools/smoke_driver.gd` (merchant checks at lines 57, 62, 75)
- Test: `tests/test_floor_unlocks.gd` (new), plus existing tests that call `record_floor_cleared()`, `MerchantRules` or `setup_paths`

**Interfaces:**
- Produces:
  - `ProgressData.clears_at(depth: int) -> int`
  - `ProgressData.record_floor_cleared(depth := 1, path_id := "") -> void`
  - `ProgressData.has_cleared_path(id: String) -> bool`
  - `ProgressData.legacy_clears: int`
  - `FloorDef.depth: int`, `FloorDef.open_after_depth: int`
  - `FloorDef.is_open_for(data: ProgressData) -> bool`
  - `MerchantRules.is_open(entry: Dictionary, data: ProgressData) -> bool`
  - `MerchantRules.open_ones(entries: Array, data: ProgressData) -> Array`
  - `CrossroadsView.setup_paths(paths: Array[FloorDef], data: ProgressData)`
  - `Progress.record_floor_cleared(depth: int, path_id: String)`

- [ ] **Step 1: Write the failing tests** in `tests/test_floor_unlocks.gd`:

```gdscript
extends TestCase


func _old_save(clears: int) -> Dictionary:
	return {"version": ProgressData.VERSION, "pension": 0, "upgrades": {}, "opening_seen": true, "floors_cleared": clears}


func test_first_floor_clears_stay_in_floors_cleared() -> void:
	var data := ProgressData.new()
	data.record_floor_cleared(1, "floor_1")
	assert_eq(data.floors_cleared, 1)
	assert_eq(data.clears_at(1), 1)
	assert_eq(data.clears_at(2), 0)


func test_second_floor_clears_are_counted_apart() -> void:
	var data := ProgressData.new()
	data.record_floor_cleared(2, "sunset_shores")
	assert_eq(data.floors_cleared, 0, "a deeper clear never opens first-floor rules")
	assert_eq(data.clears_at(2), 1)
	assert_true(data.has_cleared_path("sunset_shores"))
	assert_false(data.has_cleared_path("furnace_works"))


func test_clears_and_paths_survive_a_save() -> void:
	var data := ProgressData.new()
	data.record_floor_cleared(2, "furnace_works")
	var loaded := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_eq(loaded.clears_at(2), 1)
	assert_true(loaded.has_cleared_path("furnace_works"))
	assert_eq(loaded.legacy_clears, 0, "a save written by this version is not an old one")


func test_an_old_save_freezes_its_clears_for_merchants() -> void:
	var loaded := ProgressData.from_dict(_old_save(3))
	assert_eq(loaded.legacy_clears, 3)
	assert_eq(loaded.clears_at(2), 0)
	loaded.record_floor_cleared(1, "floor_1")
	var again := ProgressData.from_dict(JSON.parse_string(JSON.stringify(loaded.to_dict())))
	assert_eq(again.legacy_clears, 3, "only the first load of an old save sets it")


func test_a_path_opens_on_the_clears_of_the_depth_it_names() -> void:
	var furnace := FloorDef.new()
	furnace.depth = 2
	furnace.open_after_depth = 2
	furnace.clears_to_open = 1
	var data := ProgressData.new()
	data.record_floor_cleared(1, "floor_1")
	assert_false(furnace.is_open_for(data))
	data.record_floor_cleared(2, "sunset_shores")
	assert_true(furnace.is_open_for(data))


func test_merchants_open_by_depth_by_paths_or_by_an_old_save() -> void:
	var murk := {"id": "potion_merchant", "depth": 2, "clears": 1, "legacy_clears": 1}
	var bernard := {"id": "bomb_merchant", "paths": ["sunset_shores", "furnace_works"], "legacy_clears": 3}
	var data := ProgressData.new()
	data.record_floor_cleared(1, "floor_1")
	assert_false(MerchantRules.is_open(murk, data), "a first-floor clear no longer opens her")
	data.record_floor_cleared(2, "sunset_shores")
	assert_true(MerchantRules.is_open(murk, data))
	assert_false(MerchantRules.is_open(bernard, data))
	data.record_floor_cleared(2, "furnace_works")
	assert_true(MerchantRules.is_open(bernard, data))
	var old := ProgressData.from_dict(_old_save(3))
	assert_true(MerchantRules.is_open(murk, old), "kept open from the old rules")
	assert_true(MerchantRules.is_open(bernard, old))
	assert_true(MerchantRules.is_open({"id": "black_market"}, ProgressData.new()), "no rule means always open")
```

- [ ] **Step 2: Run the tests to make sure they fail.** Run `powershell -File tools/test.ps1`. Expected: failures naming `clears_at`, `has_cleared_path`, `legacy_clears`, `is_open_for` and the new `MerchantRules.is_open` signature.

- [ ] **Step 3: Implement `ProgressData`.** Add these fields under `floors_cleared`:

```gdscript
# Clears of floors below the first, by depth as a string key, since JSON keys are strings.
var deep_clears: Dictionary = {}
var paths_cleared: Dictionary = {}
# A save from before clears were kept by depth keeps the merchants its old count had opened.
var legacy_clears: int = 0
```

Replace `record_floor_cleared` and add:

```gdscript
# First-floor clears stay in floors_cleared, so older saves and the Cemetery's rule keep their meaning.
func record_floor_cleared(depth := 1, path_id := "") -> void:
	if depth <= 1:
		floors_cleared += 1
	else:
		deep_clears[str(depth)] = clears_at(depth) + 1
	if not path_id.is_empty():
		paths_cleared[path_id] = true


func clears_at(depth: int) -> int:
	if depth <= 1:
		return floors_cleared
	return int(deep_clears.get(str(depth), 0))


func has_cleared_path(id: String) -> bool:
	return paths_cleared.has(id)
```

In `to_dict` add `"deep_clears": deep_clears, "paths_cleared": paths_cleared, "legacy_clears": legacy_clears`. In `from_dict`, after `floors_cleared`, add:

```gdscript
	data.deep_clears = {}
	var deep: Variant = raw.get("deep_clears", {})
	if deep is Dictionary:
		for key in deep:
			data.deep_clears[str(key)] = maxi(int(deep[key]), 0)
	data.paths_cleared = _id_set(raw.get("paths_cleared"))
	# Only a save older than clears by depth lacks the key. Its count is frozen here, once.
	data.legacy_clears = maxi(int(raw.get("legacy_clears", data.floors_cleared)), 0)
```

- [ ] **Step 4: Implement `FloorDef`.** In the Path group, add the fields and the new check. Keep `is_open(clears)` for callers that already hold a count.

```gdscript
# 1 for a floor reached from the first Crossroads, 2 for one reached from the second.
@export var depth: int = 1
# Whose clears clears_to_open counts: the first floor's, or the second's.
@export var open_after_depth: int = 1
```

```gdscript
func is_open_for(data: ProgressData) -> bool:
	return is_open(data.clears_at(open_after_depth))
```

- [ ] **Step 5: Implement `MerchantRules`.** Replace the file body with:

```gdscript
class_name MerchantRules
extends RefCounted

# A Waiting Room merchant entry may say when it appears:
# - "depth" and "clears": that many clears of floors at that depth.
# - "paths": every listed path id has been cleared.
# - "legacy_clears": a save from before clears by depth with at least that many clears keeps it.
# Entries without "clears" or "paths" are always there. The numbers live in the Waiting Room's list.


static func is_open(entry: Dictionary, data: ProgressData) -> bool:
	if entry.has("legacy_clears") and data.legacy_clears >= int(entry["legacy_clears"]):
		return true
	if entry.has("paths"):
		for id in entry["paths"]:
			if not data.has_cleared_path(id):
				return false
		return true
	return data.clears_at(int(entry.get("depth", 1))) >= int(entry.get("clears", 0))


static func open_ones(entries: Array, data: ProgressData) -> Array:
	var open: Array = []
	for entry: Dictionary in entries:
		if is_open(entry, data):
			open.append(entry)
	return open
```

- [ ] **Step 6: Update the callers.**
  - **`waiting_room.gd`:** change the Murk entry to `"depth": 2, "clears": 1, "legacy_clears": 1` and the Bernard entry to `"paths": ["sunset_shores", "furnace_works"], "legacy_clears": 3`. Change `_ready` to `MerchantRules.open_ones(MERCHANTS, Progress.data)`. Update the comment above `MERCHANTS`.
  - **`progress.gd`:** make it `func record_floor_cleared(depth: int, path_id: String) -> void`, calling `data.record_floor_cleared(depth, path_id)`.
  - **`crossroads_view.gd`:** make it `setup_paths(paths: Array[FloorDef], data: ProgressData)`, store `_data`, and use `not _paths[i].is_open_for(_data)`.
  - **`floor_scene.gd`:** line 127 uses `def.is_open_for(Progress.data)`, line 191 passes `Progress.data`, and line 226 becomes `Progress.record_floor_cleared(_floor_def.depth, _floor_def.id)`.
  - **Old callers:** fix every existing test and `tools/smoke_driver.gd` call site that used the old signatures. Find them with `Grep` for `record_floor_cleared|MerchantRules|setup_paths|floors_cleared`. The smoke merchant checks at lines 57, 62 and 75 must now assert the new rules: no Murk after first-floor clears, and Murk after a second-floor clear. That check can only run once Task 3 exists, so until then set the clears directly on `Progress.data` in the driver, as it already does.

- [ ] **Step 7: Run the tests.** Run `powershell -File tools/test.ps1`. Expected: `N tests, 0 failed`.

- [ ] **Step 8: Commit.**

```bash
git add scripts/core/progress_data.gd scripts/autoload/progress.gd scripts/core/merchant_rules.gd scripts/content/floor_def.gd scripts/scenes/waiting_room.gd scripts/world/crossroads_view.gd scripts/scenes/floor_scene.gd tools/smoke_driver.gd tests/
git commit -m "Count floor clears by depth and keep an old save's merchants open"
```

### Task 2: The floor boss's choice of two items

**Files:**
- Create: `scripts/core/choice_group.gd`
- Modify: `scripts/world/room_view.gd` (`_on_enemy_defeated` at about line 343, and a new `_drop_boss_choice`)
- Test: `tests/test_choice_group.gd` (new)

**Interfaces:**
- Produces:
  - `ChoiceGroup.add(pickup: Node) -> void`
  - `ChoiceGroup.take(pickup: Node) -> void`, which frees the others
  - `RoomView.boss_choice_dropped(count: int)` signal, for the smoke driver

- [ ] **Step 1: Write the failing test** in `tests/test_choice_group.gd`:

```gdscript
extends TestCase


func test_taking_one_removes_the_others() -> void:
	var group := ChoiceGroup.new()
	var a := Node.new()
	var b := Node.new()
	group.add(a)
	group.add(b)
	group.take(a)
	assert_false(a.is_queued_for_deletion(), "the taken one is left to its own pickup code")
	assert_true(b.is_queued_for_deletion())
	a.free()
	b.free()


func test_taking_twice_does_nothing_more() -> void:
	var group := ChoiceGroup.new()
	var a := Node.new()
	var b := Node.new()
	group.add(a)
	group.add(b)
	group.take(a)
	group.take(b)
	assert_true(group.is_settled())
	a.free()
	b.free()
```

- [ ] **Step 2: Run the test to make sure it fails.** Expected: `ChoiceGroup` is not defined.

- [ ] **Step 3: Implement `scripts/core/choice_group.gd`:**

```gdscript
class_name ChoiceGroup
extends RefCounted

# Items laid out as a choice. Taking one clears the rest away, once.
var _members: Array[Node] = []
var _settled := false


func add(pickup: Node) -> void:
	_members.append(pickup)


func take(pickup: Node) -> void:
	if _settled:
		return
	_settled = true
	for other in _members:
		if other != pickup and is_instance_valid(other) and not other.is_queued_for_deletion():
			other.queue_free()


func is_settled() -> bool:
	return _settled
```

- [ ] **Step 4: Drop the choice in `room_view.gd`.**
  - **When:** when a floor boss dies (`_room.room_type == RoomLayout.TYPE_FLOOR_BOSS and enemy.def.is_boss`, using whatever constant names the floor boss room), call `_drop_boss_choice(spot)`.
  - **Picking:** pick up to 2 items with the same picker the treasure room uses. Find it in `_create_rewards`, and use the same rules for recipes, promises and items already held. Call `_run.promise(item)` on each item shown.
  - **Placing:** place them with `_add_free_item` on two floor cells beside the spot, as `_drop_boss_rewards` does.
  - **Linking:** add both to one `ChoiceGroup`, and call `group.take(pickup)` from the pickup's take callback before the item is added. Read `_add_item_pickup` to find where the take callback runs.
  - **Signal:** emit `boss_choice_dropped(count)`.
  - **Empty pool:** with one item left show one, and with none show none.

- [ ] **Step 5: Run the tests.** Expected: `0 failed`.

- [ ] **Step 6: Commit.**

```bash
git add scripts/core/choice_group.gd scripts/world/room_view.gd tests/test_choice_group.gd
git commit -m "Offer a choice of two items when a floor boss falls"
```

### Task 3: Stairwell, landing, second Crossroads and the end point

**Files:**
- Create: `data/floors/landing.tres`, `data/floors/crossroads_2.tres`, `data/rooms/landing/landing.tres`, `data/floors/sunset_shores.tres` and `data/floors/furnace_works.tres`. The last two are placeholders that point `rooms_dir` at `res://data/rooms/` (the first floor's layouts) and copy `floor_1.tres`'s enemies and bosses.
- Modify: `scripts/scenes/floor_scene.gd`, `scripts/world/room_view.gd` (the stairwell door), `scripts/core/floor_map.gd` (a two-room map like `with_only_crossroads`), `tools/smoke_driver.gd`
- Test: `tests/test_floor_map.gd` or the existing map test file, plus smoke

**Interfaces:**
- Consumes: `FloorDef.depth`, `FloorDef.is_open_for`, `Progress.record_floor_cleared(depth, path_id)` and `RoomView.boss_choice_dropped` from Tasks 1 and 2.
- Produces:
  - `floor_scene.gd`: `const PATHS_BY_DEPTH := {1: [...], 2: ["res://data/floors/sunset_shores.tres", "res://data/floors/furnace_works.tres"]}`, `const LAST_DEPTH := 2`, `const LANDING_HEAL := 2`, `var _depth := 1`
  - `func _continue_after_floor() -> void` opens the stairwell when `_floor_def.depth < LAST_DEPTH` and ends the run otherwise.
  - `func _go_down() -> void` builds the landing and the second Crossroads.
  - `FloorMap.with_landing_and_crossroads(landing: RoomLayout, crossroads: RoomLayout) -> FloorMap`
  - `RoomView.add_stairwell() -> void` and `RoomView.stairwell_entered` signal
  - `func debug_depth() -> int` for the smoke driver

- [ ] **Step 1: Write a failing test** for `FloorMap.with_landing_and_crossroads`. It returns a map of two rooms joined by one door: the start room is the landing, of type `RoomLayout.TYPE_LANDING`, a new type constant, and the second room is `TYPE_CROSSROADS`. Model the test on the existing test of `with_only_crossroads`, found with `Grep` for `with_only_crossroads` in `tests/`. Assert the room count, the types, that the two rooms are linked both ways, and that the landing has exactly one door.

- [ ] **Step 2: Run the test to make sure it fails, then implement** `with_landing_and_crossroads` next to `with_only_crossroads`. Add `TYPE_LANDING := "landing"` to `RoomLayout`, and keep layout validation accepting a landing with no enemies and one door. Run the test until it passes.

- [ ] **Step 3: Make the floor scene depth-aware.**
  - **Paths by depth:** replace `PATH_FLOORS` with `PATHS_BY_DEPTH`, and make `_path_defs()` return the defs for `_depth`.
  - **Clearing a floor:** `_on_floor_cleared` records the clear with `_floor_def.depth` and `_floor_def.id`, then calls `_continue_after_floor()`.
  - **`_continue_after_floor`:** if `_floor_def.depth < LAST_DEPTH`, call `_room_view.add_stairwell()` and return. Otherwise call `_end_run("FLOOR CLEARED")`. Keep its comment saying this is the one place a third floor slots in.
  - **Clearing the flag:** `is_cleared` must reset when a new floor starts, so the second floor's boss can clear it.

- [ ] **Step 4: The stairwell.**
  - **The door:** `RoomView.add_stairwell()` adds a door on a free floor cell near the boss room's center, using the `Door` class with label `"v"`. It arms like other late doors (`door.rearm()`), so Grandpa standing on it doesn't trigger it, and emits `stairwell_entered` when used.
  - **Connecting:** in `_make_room_view`, connect `stairwell_entered` to `_go_down.call_deferred()`.
  - **Not waiting for the choice:** `add_stairwell` is called whether or not an item is taken.

- [ ] **Step 5: `_go_down()`.** Model it on `_choose_path`:
  - **Setup:** set `_depth = 2` and `is_cleared = false`.
  - **The map:** set `_floor_def = load("res://data/floors/landing.tres")`, a FloorDef with display name `"Floor 2"`. Build `_map` with `FloorMap.with_landing_and_crossroads(load(landing layout), load("res://data/rooms/crossroads/crossroads.tres"))`.
  - **Moving in:** reset `_progress`, `_room_views` and both map views, as `_choose_path` does, and free the old views the same way it does. Then `_enter_room(_map.start_id)`.
  - **The heal:** heal `LANDING_HEAL` pills once on arrival with `_run.health.heal(LANDING_HEAL)`, and show the notice `"You catch your breath. +2 pills"`.
  - **What carries:** items, consumables, potion, buff and pills all live on `_run`, so they carry. `_run.mini_boss_down` resets to `false`.
  - **Choosing a path:** `_choose_path` must now work from this second Crossroads too. It uses `_path_defs()`, which follows `_depth`, so check that `attach_crossroads` still finds a free side on the new floor.

- [ ] **Step 6: The second Crossroads' signs.** These come from the depth-2 defs:
  - **`sunset_shores.tres`:** `depth = 2`, `open_after_depth = 1`, `clears_to_open = 0`, `danger = 2`, display name `"Sunset Shores Eternal Care"`, id `"sunset_shores"`.
  - **`furnace_works.tres`:** `depth = 2`, `open_after_depth = 2`, `clears_to_open = 1`, `danger = 3`, display name `"The Furnace Works"`, id `"furnace_works"`, closed hint `"Beat a second-floor boss first"`.

- [ ] **Step 7: Extend the smoke driver's full loop.**
  - **From the first boss:** after a first-floor boss falls, check `boss_choice_dropped` reported 2, or fewer only when the item pool is that small. Take one and check the other is gone.
  - **The landing:** walk the stairwell, check `debug_depth() == 2`, the floor name `"Floor 2"`, and that pills rose by `mini(2, missing)`.
  - **The second Crossroads:** check the Furnace Works is refused before a second-floor clear, clear Sunset Shores, then check it opens.
  - **The run end:** check the run ends after a second-floor boss.
  - **The Furnace Works:** on another pass, clear it too.
  - **Timeout:** raise the timeout in `tools/smoke.ps1` if a run now takes longer. Report the new run time.

- [ ] **Step 8: Run all tests and the full loop.** Run tests, then 3 smoke runs from an exported copy. Expected: `0 failed` and `SMOKE PASS` each time.

- [ ] **Step 9: Commit.** Use one commit per logical change: the map and room type, the stairwell and landing flow, the placeholder floor defs, and the smoke driver.

### Task 4: Floor difficulty settings and two-pill attacks

**Files:**
- Modify: `scripts/content/floor_def.gd`, `scripts/actors/enemy.gd` (where HP and `coin_value()` come from), `scripts/world/room_view.gd` (`_spawn_enemy`), and the layout validation that counts enemy cells by size. Find that validation with `Grep` for `11` near `size` in `scripts/content/room_layout.gd` or `scripts/core/floor_builder.gd`.
- Test: `tests/test_floor_difficulty.gd` (new)

**Interfaces:**
- Produces:
  - `FloorDef.health_mult: float = 1.0`
  - `FloorDef.pension_mult: float = 1.0`
  - `FloorDef.enemies_by_size: Dictionary = {"small": 4, "medium": 6, "large": 11}`
  - `Enemy.apply_floor(health_mult: float, pension_mult: float) -> void`, called before `_ready`

- [ ] **Step 1: Write failing tests:**

```gdscript
extends TestCase


func _def(hp: float, pays: int) -> EnemyDef:
	var def := EnemyDef.new()
	def.max_hp = hp
	def.coin_value = pays
	return def


func test_a_floor_scales_health_and_pay() -> void:
	var enemy := Enemy.new()
	enemy.def = _def(50.0, 2)
	enemy.apply_floor(1.4, 1.5)
	assert_near(enemy.max_hp(), 70.0)
	assert_eq(enemy.coin_value(), 3, "1.5 times 2 is 3")
	enemy.free()


func test_pay_rounds_up() -> void:
	var enemy := Enemy.new()
	enemy.def = _def(10.0, 1)
	enemy.apply_floor(1.0, 1.5)
	assert_eq(enemy.coin_value(), 2)
	enemy.free()


func test_summons_still_pay_nothing_on_a_deeper_floor() -> void:
	var enemy := Enemy.new()
	enemy.def = _def(10.0, 2)
	enemy.is_summoned = true
	enemy.apply_floor(1.4, 1.5)
	assert_eq(enemy.coin_value(), 0)
	enemy.free()


func test_first_floors_keep_their_room_sizes() -> void:
	var def := FloorDef.new()
	assert_eq(def.enemies_by_size, {"small": 4, "medium": 6, "large": 11})
```

Before writing these, read `enemy.gd`. Match the real names for max HP, the coin value and the summoned flag (Grep `coin_value`, `max_hp` and the summon flag), and adjust the test to those names. Keep the asserted behavior.

- [ ] **Step 2: Run the tests to make sure they fail, then implement.**
  - **`apply_floor`:** stores both multipliers. HP starts at `def.max_hp * health_mult`, and `coin_value()` returns `ceili(base * pension_mult)` when the base is above 0.
  - **Bosses:** use the same multipliers. Their own HP values are set in data with this in mind, so second-floor boss `.tres` files hold their final HP divided by `health_mult`. Document that in a comment on `health_mult`.
  - **Room sizes:** layout validation reads `enemies_by_size` from the floor def it validates for. If validation has no def, it falls back to the old numbers.

- [ ] **Step 3: Two-pill attacks.**
  - **The call:** every behavior already calls `enemy.hit_target(enemy.def.damage)` or `strike_ground(...)`. Add an optional damage argument to `strike_ground` and the lane attacks if they lack one, defaulting to `enemy.def.damage`, so a boss can pass `HEAVY_DAMAGE := 2` for named attacks.
  - **The test:** check that a ground strike made with damage 2 removes 2 pills from a fresh `Health`. Read `ground_strike.gd` first.

- [ ] **Step 4: Run the tests, then commit.**

```bash
git commit -m "Let a floor scale enemy health, pay and room size, and let attacks cost two pills"
```

---

## Step 2: Sunset Shores Eternal Care

Read these as models before starting:
- **Behaviors:** `scripts/actors/behaviors/groundskeeper_behavior.gd` (a mini boss), `undertaker_behavior.gd` (a floor boss with two phases), `riser_behavior.gd`, `charger_behavior.gd` and `burst_shooter_behavior.gd`.
- **Data:** `data/floors/cemetery.tres` and `data/rooms/cemetery/`.
- **Content tests:** `tests/test_cemetery_enemies.gd`, the pattern for testing behavior statics.

### Task 5: Slow, sliding and wet floors

**Files:**
- Create: `scripts/core/slow_effect.gd`, `scripts/world/wet_floor.gd`
- Modify: `scripts/actors/player.gd` (movement), `scripts/world/room_view.gd` (place wet floor from a new layout symbol), `scripts/world/room_decor.gd` or the decor table (a breakable "Caution: Wet" sign)
- Test: `tests/test_slow_and_wet.gd` (new)

**Interfaces:**
- Produces:
  - `SlowEffect.apply(fraction: float, seconds: float)`, `SlowEffect.tick(delta)` and `SlowEffect.speed_factor() -> float`. The strongest active slow wins, and the factor is never below 0.4.
  - `Player.slow(fraction: float, seconds: float)`
  - `WetFloor`: an `Area2D` the size of one cell
  - `Player.on_wet: bool`, true while his feet overlap any `WetFloor`
  - `SlideRule.velocity(current: Vector2, wanted: Vector2, on_wet: bool, delta: float) -> Vector2`, a static in `slow_effect.gd` or its own file. On wet ground it moves toward `wanted` at `WET_GRIP := 4.0` per second instead of snapping.
  - Layout symbol `W` for a wet cell, unused so far. Check the symbol list in `room_layout.gd` first, and pick another free letter if `W` is taken.

- [ ] **Step 1: Write failing tests:**

```gdscript
extends TestCase


func test_a_slow_fades_when_its_time_runs_out() -> void:
	var slow := SlowEffect.new()
	slow.apply(0.5, 1.0)
	assert_near(slow.speed_factor(), 0.5)
	slow.tick(1.01)
	assert_near(slow.speed_factor(), 1.0)


func test_the_strongest_slow_wins_and_never_stops_him() -> void:
	var slow := SlowEffect.new()
	slow.apply(0.3, 2.0)
	slow.apply(0.9, 0.5)
	assert_near(slow.speed_factor(), 0.4, "capped so he can always move")
	slow.tick(0.6)
	assert_near(slow.speed_factor(), 0.7)


func test_dry_ground_answers_at_once_and_wet_ground_slides() -> void:
	var dry := SlideRule.velocity(Vector2(100, 0), Vector2.ZERO, false, 0.1)
	assert_eq(dry, Vector2.ZERO)
	var wet := SlideRule.velocity(Vector2(100, 0), Vector2.ZERO, true, 0.1)
	assert_true(wet.x > 0.0 and wet.x < 100.0, "keeps some speed after letting go")
```

- [ ] **Step 2: Run the tests to make sure they fail, then implement.**
  - **Movement:** player movement multiplies speed by `slow.speed_factor()` and passes through `SlideRule`.
  - **Dodges:** a dodge ignores sliding.
  - **Wet floor:** it never does damage and is drawn as a pale blue sheen.
  - **Chargers:** charging enemies use `SlideRule` too while on wet ground. This goes in `charger_behavior.gd`, so a nurse overshoots.

- [ ] **Step 3: Run the tests and one full loop, then commit.**

```bash
git commit -m "Add sedative slows and slippery wet floors"
```

### Task 6: Sunset Shores regular enemies

**Files:**
- Create: `orderly_behavior.gd`, `cart_nurse_behavior.gd` and `bingo_caller_behavior.gd` in `scripts/actors/behaviors/`, plus `data/enemies/orderly.tres`, `cart_nurse.tres`, `bingo_caller.tres`
- Modify: the behavior registry, found with `Grep` for `groundskeeper` in `scripts/actors/` to see how a behavior id maps to a script
- Test: `tests/test_sunset_enemies.gd` (new)

**What each one does.** Base HP and pay match a first-floor enemy of the same role, and the floor's `health_mult` and `pension_mult` do the rest.
- **Orderly:** like `burst_shooter_behavior.gd`, but with one dart per shot along a warned lane (lane width 10, 0.6 s windup). A dart that hits calls `Player.slow(0.5, 1.5)` and costs 1 pill. Projectiles need a `slow` field. Find where `Projectile` hits the player.
- **Med-Cart Nurse:** like `charger_behavior.gd`. She breaks props in her lane with `enemy.smash`. Hitting a wall stuns her for 1.2 s, shown by circling stars or a flash, and she takes double damage while stunned. She slides on wet floors.
- **Bingo Caller:** keeps 120 px or more from Grandpa. Every 3.5 s she marks `bingo_marks(target, count, rng)` spots, 3 by default (2 when 2 or more other enemies are alive). These are within 48 px of Grandpa and at least 28 px apart, and each one strikes after 0.9 s through `enemy.strike_ground`.

- [ ] **Step 1: Write failing tests** for the statics:

```gdscript
extends TestCase


func test_bingo_marks_land_near_him_and_apart() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 50:
		var marks := BingoCallerBehavior.bingo_marks(Vector2(100, 100), 3, rng)
		assert_eq(marks.size(), 3)
		for a in marks.size():
			assert_true(marks[a].distance_to(Vector2(100, 100)) <= 48.0)
			for b in range(a + 1, marks.size()):
				assert_true(marks[a].distance_to(marks[b]) >= 28.0)


func test_a_crowded_room_gets_fewer_marks() -> void:
	assert_eq(BingoCallerBehavior.mark_count(0), 3)
	assert_eq(BingoCallerBehavior.mark_count(2), 2)


func test_a_stunned_nurse_takes_double_damage() -> void:
	assert_near(CartNurseBehavior.damage_taken(10.0, true), 20.0)
	assert_near(CartNurseBehavior.damage_taken(10.0, false), 10.0)
```

- [ ] **Step 2: Run the tests to make sure they fail, implement the three behaviors and their `.tres` files, then run the tests until they pass.**

- [ ] **Step 3: Returning enemies.** Pick the two first-floor enemies that suit a care home best, and say which in the commit message. Give them Sunset Shores colors, using new `.tres` copies with a different color when the enemy has no palette hook. The floor's multipliers make them tougher.

- [ ] **Step 4: Look at it.** Place each new enemy in a room through the smoke driver's room setup, or a scratchpad probe run with `--smoke`. Take a screenshot in a real window, and check every warning reads.

- [ ] **Step 5: Commit.** Make one commit per enemy.

### Task 7: Barbara, Activities Coordinator (mini boss)

**Files:**
- Create: `scripts/actors/behaviors/activities_coordinator_behavior.gd`, `data/enemies/activities_coordinator.tres`
- Test: `tests/test_sunset_bosses.gd` (new)

**Stats:** HP 500 before the multiplier, so store `500 / health_mult` in the `.tres`. Speed 70, pays 8 before the multiplier. Model it on `groundskeeper_behavior.gd`.
- **Bingo:** a grid of 4×4 tiles, 32 px apart, centered on Grandpa. Tiles strike row by row 0.25 s apart, each warned for 0.8 s. `bingo_grid(center, safe_column)` leaves one column safe, chosen at random and different from the last.
- **Ball cage:** a 0.7 s windup with a warned lane, then 5 balls in a 50° fan along it, through `fan_directions` as in `undertaker_behavior.gd`, aimed down the shown lane.
- **Summon:** 2 residents. Reuse the Seasonal Temp or a slow melee enemy in Sunset Shores colors, every 12 s, through `request_summon_at` with marks.

- [ ] **Step 1: Write failing tests:**

```gdscript
func test_the_bingo_grid_always_leaves_one_safe_column() -> void:
	var tiles := ActivitiesCoordinatorBehavior.bingo_grid(Vector2.ZERO, 2)
	assert_eq(tiles.size(), 12, "4 rows of 4, minus the safe column")
	for tile: Vector2 in tiles:
		assert_true(absf(tile.x - ActivitiesCoordinatorBehavior.column_x(Vector2.ZERO, 2)) > 1.0)


func test_the_safe_column_moves_each_time() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var last := 1
	for i in 30:
		var next := ActivitiesCoordinatorBehavior.next_safe_column(last, rng)
		assert_true(next != last and next >= 0 and next < 4)
		last = next
```

- [ ] **Step 2: Implement until the tests pass, then look at it in a real window and commit.**

```bash
git commit -m "Add Barbara, the Activities Coordinator"
```

### Task 8: Matron Mercy, Head of Comfort Care (floor boss)

**Files:**
- Create: `scripts/actors/behaviors/matron_behavior.gd`, `data/enemies/matron_mercy.tres`
- Modify: `scripts/world/room_view.gd` or `scripts/scenes/floor_scene.gd` for the Lights Out darkness
- Test: `tests/test_sunset_bosses.gd`

**Stats:** HP 1200 final, so 1200 / `health_mult` in data. Speed 80, pays 16 before the multiplier. Model it on `undertaker_behavior.gd`, including phase two below half health with 1.2× speed and 0.8× windups.
- **Sedative volley:** 3 syringes in a 30° fan down a lane warned for 0.7 s. Each slows (0.5, 1.5 s) and costs 1 pill.
- **Gurney charge:** a 0.9 s windup with lane and circle, and a dash of 220 px that breaks props through `enemy.smash`. A hit costs `HEAVY_DAMAGE` (2 pills). She stops at walls.
- **Lights Out:** a 1.0 s warning, shown as the room dimming and the text "Lights out!". For 4 s a `CanvasModulate` darkens the room to 15% outside a soft light of radius 70 around Grandpa.
  - Ground marks and warning lanes must stay visible inside that circle. Draw them on a layer above the darkness, or give each a small light.
  - During Lights Out she only throws sedative volleys.
  - It is used at most once every 20 s.
- **Visiting Hours:** summons Orderlies, keeping at most 2 summoned ones alive.
- **Second phase:** the gurney charge chains straight into a sedative volley, using a `followup` like Mortimer's.

- [ ] **Step 1: Write failing tests** for the statics: `choose_attack` never picks Lights Out within 20 s of the last one, and never picks Visiting Hours with 2 summoned Orderlies alive. `charge_end(from, dir, length, walls)` stops before walls; mirror how `boss_dash.gd` is tested. `followup` in phase two after `GURNEY` returns `SEDATIVE`.

- [ ] **Step 2: Implement until the tests pass.**

- [ ] **Step 3: Look at every attack in a real window, Lights Out above all.** If the warnings can't be read in the dark, make Lights Out only dim the room to 50% and note it in `docs/playtest-notes.md`. If that still doesn't read, replace it with a second sedative pattern and tell the controller. The spec allows this.

- [ ] **Step 4: Commit.**

```bash
git commit -m "Add Matron Mercy, the Head of Comfort Care"
```

### Task 9: Sunset Shores floor content

**Files:**
- Modify: `data/floors/sunset_shores.tres`, replacing the placeholder from Task 3
- Create: `data/rooms/sunset_shores/`, a palette resource, and new props and decor as needed

**What to build:**
- **Palette:** pastel walls, patterned carpet and linoleum floor, and soft warm fill lights. Copy how `cemetery.tres` sets a palette and lights.
- **Props:** wheelchairs and food trays break to anything, like barrels. Flower vases break to anything and are not solid, like grass. Armchairs and beds are solid and break only to blasts and bosses, like rocks. Follow the existing prop classes and `room_decor.gd`.
- **Wet floor:** the `W` symbol (or the letter Task 5 chose) in some rooms, never on door cells or within 2 cells of a door.
- **Layouts:** about 30, in the same small, medium and large proportions as `data/rooms/cemetery/`, with 5, 7 and 12 enemy cells. Include a mini boss room, a floor boss room, shop, treasure, healing, vault and secret-capable rooms, matching what the Cemetery folder has. Run the layout validation tests over the folder.
- **Floor def:**
  - **Enemies:** the 3 new ones and 2 returning ones, with weights, mini boss Barbara and floor boss Mercy.
  - **Multipliers:** `health_mult = 1.4`, `pension_mult = 1.5` and `enemies_by_size = {"small": 5, "medium": 7, "large": 12}`.
  - **Pension and stone:** prop and clear Pension scaled about 1.5×, and `vault_stone_level` as on the first floor.
- **Income:** check income per full clear with the income probe at `C:\Users\PC\AppData\Local\Temp\claude\C--Users-PC\5df3bd71-deda-4c2b-b0a3-333826050d73\scratchpad\income_probe.gd`, or copy its approach into a new probe. Aim for about 1.5× the first floor's 125 to 136 without blasting.

- [ ] **Step 1: Build the palette, props and decor, and commit.**
- [ ] **Step 2: Build the layouts, run the tests including layout validation, and commit.**
- [ ] **Step 3: Finish the floor def, run the tests and 3 full loops, and commit.**
- [ ] **Step 4: Screenshot small, medium and large rooms in a real window next to Cemetery rooms.** The floors must look clearly different.
- [ ] **Step 5: Update `docs/playtest-notes.md`, the next-rounds plan and `LESSONS.md`. Push, then stop and report to the controller.** The user plays here before the Furnace Works.

---

## Step 3: The Furnace Works

Same models as Step 2.

### Task 10: Floor vents and burning ground

**Files:**
- Create: `scripts/core/vent_cycle.gd`, `scripts/world/floor_vent.gd`
- Modify: `scripts/world/ground_strike.gd`, to add an optional `linger` time for burning ground that keeps hurting
- Test: `tests/test_vents.gd` (new)

**Interfaces:**
- Produces:
  - `VentCycle.new(period: float, warn: float, flare: float, offset: float)`
  - `VentCycle.state_at(time: float) -> int`, one of `VentCycle.IDLE`, `WARN` or `FLARE`
  - `FloorVent`, placed by layout symbol `V`-like. Check free symbols; `V` is used by stage 2, so pick a free letter.
  - Burning ground through `strike_ground(at, radius, warning, delay := 0.0, follow := 0.0, damage := 1, linger := 0.0)`. Read the existing signature first and add `linger` last.

**Rules:**
- **Timing:** room vents use period 3.0 s, warn 0.8 s and flare 0.5 s by default, with offsets so neighbours alternate.
- **Damage:** a flare costs Grandpa 1 pill, deals 20 damage to enemies, and respects dodges like all damage.
- **Burning ground:** hurts at most once per 0.6 s for each body standing in it.

- [ ] **Step 1: Write failing tests:**

```gdscript
extends TestCase


func test_a_vent_warns_before_it_flares() -> void:
	var cycle := VentCycle.new(3.0, 0.8, 0.5, 0.0)
	assert_eq(cycle.state_at(0.1), VentCycle.IDLE)
	assert_eq(cycle.state_at(1.8), VentCycle.WARN)
	assert_eq(cycle.state_at(2.6), VentCycle.FLARE)
	assert_eq(cycle.state_at(3.1), VentCycle.IDLE, "and the cycle repeats")


func test_an_offset_shifts_the_whole_cycle() -> void:
	var cycle := VentCycle.new(3.0, 0.8, 0.5, 1.5)
	assert_eq(cycle.state_at(1.0), VentCycle.FLARE)
```

These assume a flare occupies the last `flare` seconds of each period and a warning the `warn` seconds before it. State that in a comment in `vent_cycle.gd`.

- [ ] **Step 2: Implement until the tests pass. Add a burning-ground test through `GroundStrike` if its logic is testable without the tree; otherwise cover it in the smoke loop. Look at it in a real window, then commit.**

### Task 11: Furnace Works regular enemies

**Files:**
- Create: `stoker_behavior.gd`, `steam_valve_behavior.gd`, `soot_ghost_behavior.gd`, and their `.tres` files
- Test: `tests/test_furnace_enemies.gd` (new)

**What each one does:**
- **Stoker:** like `thrower_behavior.gd`. It throws coal at a mark warned for 0.8 s, which leaves burning ground of radius 22 for 2.5 s.
- **Steam Valve:**
  - **Body:** fixed in place, never moves, and placed only on cells next to a wall.
  - **Venting:** it vents along one of 4 lanes in turn (`next_lane(last)` cycles clockwise), 0.8 s warned lane, 140 px long and 18 px wide.
  - **Health:** low HP, worth about a first-floor Notary Public. It counts toward clearing the room.
- **Soot Ghost:**
  - **Hiding:** it fades into smoke for 1.5 s, and nothing can hit it then. Reuse the Plot Holder's `submerged` flag.
  - **Coming out:** it appears beside Grandpa after a 0.85 s warning shown in full, and swipes within 28 px.
  - **Open time:** it stays visible for 2.5 s.
  - **Finishing rooms:** it must always come back out, as the Plot Holder does, so rooms can always finish. At most 3 per room.

- [ ] **Step 1: Write failing tests** for `SteamValveBehavior.next_lane` cycling all 4 directions, `SootGhostBehavior.next_state` always going `SMOKE -> RISING` on its timer, and `StokerBehavior` keeping its distance. Mirror the Plot Holder tests in `tests/test_cemetery_enemies.gd`.
- [ ] **Step 2: Implement until the tests pass, add 2 returning enemies in Furnace colors, look at each one in a real window, and commit one commit per enemy.**

### Task 12: Foreman Klaus, Shift Supervisor (mini boss)

**Files:**
- Create: `scripts/actors/behaviors/foreman_behavior.gd`, `data/enemies/foreman_klaus.tres`
- Test: `tests/test_furnace_bosses.gd` (new)

**Stats:** HP 500 final, speed 75, pays 8 before the multiplier. Model it on `groundskeeper_behavior.gd`.
- **Hammer slam:** a 0.7 s windup, radius 60, then a shockwave ring that grows from 60 to 140 px over 0.6 s. A ring hurts where its edge passes, and a dodge passes through it. `shockwave_hits(center, radius_now, width, point)` is a static.
- **Steam lines:** 3 parallel lanes across the room, 0.9 s warned, with one gap lane safe. `steam_lanes(room_rect, direction, gap_index)` is a static.
- **Summon:** 2 Stokers every 12 s.

- [ ] **Step 1: Write failing tests** for `shockwave_hits` (inside the band yes, inside the ring's hollow no) and for `steam_lanes` (3 lanes, the gap missing, all inside the room).
- [ ] **Step 2: Implement, look at it in a real window, and commit.**

### Task 13: Old Smokey, Chief Stoker (floor boss)

**Files:**
- Create: `scripts/actors/behaviors/chief_stoker_behavior.gd`, `data/enemies/old_smokey.tres`
- Test: `tests/test_furnace_bosses.gd`

**Stats:** HP 1200 final, speed 70, pays 16 before the multiplier. The floor boss layout has vents.
- **Fire breath:** a 0.9 s warned cone, 60° wide and 130 px long, that costs `HEAVY_DAMAGE`. Draw the cone warning; `MeleeArc` may already test cones. `in_cone(origin, dir, angle, length, point)` is a static or reuses `MeleeArc`.
- **Coal rain:** 5 marks, from 3 near Grandpa and 2 random in the room, each warned 0.9 s, leaving burning ground for 3 s.
- **Vent grid:** the boss room's vents flare in a pattern with one safe path. `safe_pattern(vent_cells, rng)` returns the vents to flare, leaving a connected safe path from Grandpa's cell to at least one cell 4 or more cells away. Use a breadth-first search over room floor cells.
- **Bellows:** a 0.8 s warned lane, then a push of 260 px/s for 0.5 s toward the boss. It does no damage, and dodging cancels the push.
- **Second phase:** vents run at a 0.75× period and burning ground lasts 1.5× as long.

- [ ] **Step 1: Write failing tests** for `in_cone`, for `safe_pattern` (over 200 seeds a safe path always exists and at least half the vents flare), and for the second phase's period and linger multipliers.
- [ ] **Step 2: Implement, look at every attack in a real window, and commit.**

### Task 14: Furnace Works floor content

The same work as Task 9, for `data/floors/furnace_works.tres` and `data/rooms/furnace_works/`:
- **Palette:** iron grating, brick, pipes and gauges, with orange flickering lights. A flicker is a light energy wobble; keep it subtle.
- **Props:** coal sacks and crates break to anything. Pipe valves break to anything and are not solid. Coal heaps are solid and break only to blasts and bosses, like rocks.
- **Vents:** in some rooms, never within 2 cells of a door.
- **Floor def:** about 30 layouts with 5, 7 and 12 enemy cells, the same multipliers, and an unlock of `open_after_depth = 2`, `clears_to_open = 1` (already set in Task 3).
- **Checks:** the income check, 3 full loops, screenshots against Sunset Shores, then update the docs, push and stop for the user to play.

---

## Step 4: Balance and review

### Task 15: Balance pass

- [ ] **Step 1: Teach the simulated player the new hazards.** Use the bot probe at `C:\Users\PC\AppData\Local\Temp\claude\C--Users-PC\5df3bd71-deda-4c2b-b0a3-333826050d73\scratchpad\bot_probe.gd`. It must avoid wet floors, step out of vent flares, see the cone and avoid burning ground, as it was taught ground marks for the Cemetery.
- [ ] **Step 2: Measure.** Measure wins for each second-floor path on the three saves (fresh, some upgrades, nearly maxed), starting the run at the second Crossroads with a typical first-floor haul: 2 or 3 items and the landing heal.
- [ ] **Step 3: Tune.** Tune only `health_mult`, boss windups and summon timers until each path lands somewhat below the matching first-floor path's win rate on the same save. Record before and after in `docs/playtest-notes.md`.
- [ ] **Step 4: Run the tests and 3 full loops, commit and push.**

### Task 16: Independent review

- [ ] **Step 1: Dispatch one reviewer** on the strongest model, read-only, over `git diff <commit before Task 1>...next-build`, against the spec. Use the same brief as the living floor review, which forbids running Godot and the real save.
- [ ] **Step 2: Verify each finding by reading the code.** Fix the confirmed ones, one commit each, with tests.
- [ ] **Step 3: Run the tests and 6 full loops, push, and write a short report** for the user, in the style of `docs/night-report-2026-11-03.md`. Don't merge into `first-floor` until the user has played it.
