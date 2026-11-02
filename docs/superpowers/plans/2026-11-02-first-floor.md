# First Floor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first playable version: a Waiting Room hub, one branching floor with cane combat, enemies, bosses, run items, and permanent upgrades bought with carried-over currency.

**Architecture:** Game rules live in small pure `RefCounted` classes covered by headless tests. Godot nodes built in code handle input, physics and drawing, and content lives in `.tres` data files. Two autoloads, `Progress` and `Game`, own saved data and scene flow, so the rest of the game has no autoload dependency.

**Tech Stack:** Godot 4.7.2 standard, GDScript, PowerShell helper scripts. No add-ons.

**Spec:** `docs/superpowers/specs/2026-11-02-first-floor-design.md`

## Global Constraints

- Never name other games as inspirations or references in any project file, comment, asset name or commit message.
- Godot 4.7.2 standard version with GDScript. No add-ons and no new dependencies without asking the user.
- Render at 640×360, scaled up to fill the screen.
- No endings or living-world scenes. Beating the floor boss shows a "floor cleared" message and returns to the Waiting Room.
- Pension is the only currency, is saved as it is earned, and is fully kept on death.
- All names and numbers are working values, tuned through playtesting.
- Commit messages use imperative mood, cover one logical change, and end with: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`
- Leave the project runnable after every task.
- Append tricky bugs and gotchas to `LESSONS.md` as `- YYYY-MM-DD: <what happened> → <rule to follow next time>`.

## Prerequisite

Godot must be extracted so this file exists, or the `GODOT` environment variable must point to the console executable:

`D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`

Stop and ask the user if it is missing.

## File Structure

```
project.godot                 Project settings and autoloads
CLAUDE.md, LESSONS.md         Project rules and lessons
tools/test.ps1                Imports the project and runs headless tests
tools/smoke.ps1               Runs the automated full-loop check
tools/smoke_driver.gd         Plays through the loop automatically
tools/art/                    Pixel cleanup script and command-line wrapper
tests/support/test_case.gd    Assertions
tests/run_tests.gd            Test runner
tests/test_*.gd               Test files
scripts/autoload/             Progress (saved data) and Game (scene flow)
scripts/content/              Resource classes and the content loader
scripts/core/                 Pure rules: stats, save, health, combat, floor building
scripts/actors/               Player, enemies, behaviors, projectiles
scripts/world/                Room view, doors, pickups, backdrop, lighting, visuals
scripts/ui/                   HUD and merchant panel
scripts/scenes/               Root scripts for each scene
scenes/                       Minimal .tscn files that attach root scripts
data/items, upgrades, enemies, floors, rooms/floor_1   Content
art/                          Style guide, palette and final sprites
```

---

### Task 1: Project setup and test runner

**Files:**
- Create: `project.godot`, `.gitignore`, `CLAUDE.md`, `LESSONS.md`, `tools/test.ps1`, `tests/support/test_case.gd`, `tests/run_tests.gd`
- Test: `tests/test_test_case.gd`

**Interfaces:**
- Produces: `TestCase` with `failures: PackedStringArray`, `assert_true(value, message := "")`, `assert_false(value, message := "")`, `assert_eq(actual, expected, message := "")`, `assert_near(actual: float, expected: float, message := "")`. Test files extend `TestCase`, and any method starting with `test_` runs.

- [ ] **Step 1: Set the repo-local Git identity**

The PC has no Git identity. Use the same one as the first commit, in this repo only:

```powershell
git -C C:\GameDev\game config user.name "B1nKaTa"
git -C C:\GameDev\game config user.email "stanislav.zlatkov.bg@gmail.com"
```

- [ ] **Step 2: Create project files**

`project.godot`:

```ini
config_version=5

[application]

config/name="Grandpa"
config/features=PackedStringArray("4.7")

[display]

window/size/viewport_width=640
window/size/viewport_height=360
window/size/window_width_override=1280
window/size/window_height_override=720
window/stretch/mode="viewport"
window/stretch/scale_mode="integer"

[rendering]

renderer/rendering_method="gl_compatibility"
textures/canvas_textures/default_texture_filter=0
```

`.gitignore`:

```
.godot/
export/
.superpowers/
```

`CLAUDE.md`:

```markdown
# Grandpa

Top-down action roguelike in Godot 4.7.2 with GDScript. The design is in docs/superpowers/specs.

## Rules

- Never name other games as inspirations or references in any project file, comment, asset name or commit message.
- No add-ons or new dependencies without asking first.
- Read LESSONS.md before significant work, and append new gotchas to it.

## Commands

- Run tests: `powershell -File tools/test.ps1`
- Run the full-loop check: `powershell -File tools/smoke.ps1`

Set the GODOT environment variable if Godot isn't at D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe.
```

`LESSONS.md`:

```markdown
# Lessons

```

`tools/test.ps1`:

```powershell
$godot = if ($env:GODOT) { $env:GODOT } else { "D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
if (-not (Test-Path $godot)) { Write-Output "Godot not found at $godot"; exit 2 }
$root = Split-Path $PSScriptRoot -Parent
& $godot --headless --path $root --import *> $null
$output = & $godot --headless --path $root --script res://tests/run_tests.gd 2>&1 | ForEach-Object { "$_" }
$code = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
if ($output -match "SCRIPT ERROR|Parse Error") { Write-Output "FAILED: script errors found"; exit 1 }
exit $code
```

- [ ] **Step 3: Write the failing test**

`tests/test_test_case.gd`:

```gdscript
extends TestCase


func test_assert_eq_records_mismatch() -> void:
	var probe := TestCase.new()
	probe.assert_eq(1, 2, "numbers")
	assert_eq(probe.failures.size(), 1)


func test_assert_eq_passes_on_match() -> void:
	var probe := TestCase.new()
	probe.assert_eq("a", "a")
	assert_eq(probe.failures.size(), 0)


func test_assert_eq_handles_mixed_types() -> void:
	var probe := TestCase.new()
	probe.assert_eq(1, "one")
	assert_eq(probe.failures.size(), 1)


func test_assert_near_allows_small_difference() -> void:
	var probe := TestCase.new()
	probe.assert_near(1.0, 1.00001)
	assert_eq(probe.failures.size(), 0)
```

- [ ] **Step 4: Create the runner and run it to verify the test fails**

`tests/run_tests.gd`:

```gdscript
extends SceneTree

const TEST_DIR := "res://tests/"


func _initialize() -> void:
	var ran := 0
	var failed := 0
	var files := DirAccess.get_files_at(TEST_DIR)
	files.sort()
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		var script: GDScript = load(TEST_DIR + file)
		if script == null or not script.can_instantiate():
			print("FAIL %s: could not load" % file)
			failed += 1
			continue
		var instance = script.new()
		for method in instance.get_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			instance.failures.clear()
			instance.call(method_name)
			ran += 1
			if instance.failures.is_empty():
				continue
			failed += 1
			print("FAIL %s.%s" % [file, method_name])
			for failure in instance.failures:
				print("  " + failure)
	print("%d tests, %d failed" % [ran, failed])
	quit(1 if failed > 0 or ran == 0 else 0)
```

Run: `powershell -File tools/test.ps1`
Expected: FAIL, because `TestCase` does not exist yet.

- [ ] **Step 5: Implement assertions**

`tests/support/test_case.gd`:

```gdscript
class_name TestCase
extends RefCounted

var failures: PackedStringArray = []


func assert_true(value: bool, message := "") -> void:
	if not value:
		failures.append("expected true: %s" % message)


func assert_false(value: bool, message := "") -> void:
	if value:
		failures.append("expected false: %s" % message)


func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("expected %s, got %s: %s" % [str(expected), str(actual), message])


func assert_near(actual: float, expected: float, message := "") -> void:
	if absf(actual - expected) > 0.001:
		failures.append("expected about %f, got %f: %s" % [expected, actual, message])
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `powershell -File tools/test.ps1`
Expected: `4 tests, 0 failed`, exit code 0.

- [ ] **Step 7: Commit**

```powershell
git add .gitignore project.godot CLAUDE.md LESSONS.md tools tests docs/superpowers/plans
git commit -m "Set up Godot project and test runner" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Items, upgrades and player stats

**Files:**
- Create: `scripts/content/stat_effect.gd`, `scripts/content/item_def.gd`, `scripts/content/upgrade_def.gd`, `scripts/content/content.gd`, `scripts/core/player_stats.gd`, 6 files in `data/items/`, 4 files in `data/upgrades/`
- Test: `tests/test_stats.gd`

**Interfaces:**
- Produces:
  - `StatEffect` Resource: `bonus_pills: int`, `move_speed_bonus`, `dodge_cooldown_cut`, `damage_bonus`, `pension_bonus`, `warning_bonus` (floats).
  - `ItemDef extends StatEffect`: `id`, `display_name`, `description` (Strings).
  - `UpgradeDef extends StatEffect`: `id`, `display_name`, `description`, `prices: PackedInt32Array`, `max_level() -> int`, `price_at(level: int) -> int`, returning -1 at max level.
  - `Content`: static `items() -> Array[ItemDef]`, `upgrades() -> Array[UpgradeDef]`, `load_dir(path: String) -> Array`.
  - `PlayerStats`: `max_pills: int`, `move_speed`, `dodge_cooldown`, `damage_mult`, `pension_mult`, `warning_fraction` (floats), and static `compute(upgrades: Array[UpgradeDef], levels: Dictionary, items: Array[ItemDef]) -> PlayerStats`.

- [ ] **Step 1: Write the failing test**

`tests/test_stats.gd`:

```gdscript
extends TestCase


func _no_upgrades() -> Array[UpgradeDef]:
	var list: Array[UpgradeDef] = []
	return list


func _no_items() -> Array[ItemDef]:
	var list: Array[ItemDef] = []
	return list


func test_base_stats() -> void:
	var stats := PlayerStats.compute(_no_upgrades(), {}, _no_items())
	assert_eq(stats.max_pills, 4)
	assert_near(stats.move_speed, 120.0)
	assert_near(stats.dodge_cooldown, 1.0)
	assert_near(stats.damage_mult, 1.0)
	assert_near(stats.pension_mult, 1.0)
	assert_near(stats.warning_fraction, 0.5)


func test_upgrade_applies_once_per_level() -> void:
	var cane := UpgradeDef.new()
	cane.id = "cane"
	cane.damage_bonus = 0.1
	var upgrades: Array[UpgradeDef] = [cane]
	var stats := PlayerStats.compute(upgrades, {"cane": 3}, _no_items())
	assert_near(stats.damage_mult, 1.3)


func test_items_add_to_upgrades() -> void:
	var pills := UpgradeDef.new()
	pills.id = "pills"
	pills.bonus_pills = 1
	var upgrades: Array[UpgradeDef] = [pills]
	var organizer := ItemDef.new()
	organizer.bonus_pills = 1
	var items: Array[ItemDef] = [organizer]
	var stats := PlayerStats.compute(upgrades, {"pills": 2}, items)
	assert_eq(stats.max_pills, 7)


func test_dodge_cooldown_cut_is_capped_at_half() -> void:
	var prune := ItemDef.new()
	prune.dodge_cooldown_cut = 0.9
	var items: Array[ItemDef] = [prune]
	var stats := PlayerStats.compute(_no_upgrades(), {}, items)
	assert_near(stats.dodge_cooldown, 0.5)


func test_warning_fraction_is_capped_at_one() -> void:
	var aid := ItemDef.new()
	aid.warning_bonus = 0.9
	var items: Array[ItemDef] = [aid]
	var stats := PlayerStats.compute(_no_upgrades(), {}, items)
	assert_near(stats.warning_fraction, 1.0)


func test_upgrade_prices() -> void:
	var def := UpgradeDef.new()
	def.prices = PackedInt32Array([10, 20])
	assert_eq(def.max_level(), 2)
	assert_eq(def.price_at(1), 20)
	assert_eq(def.price_at(2), -1)


func test_shipped_content_loads() -> void:
	assert_eq(Content.items().size(), 6)
	assert_eq(Content.upgrades().size(), 4)
	for upgrade in Content.upgrades():
		assert_true(upgrade.max_level() > 0, upgrade.id)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `powershell -File tools/test.ps1`
Expected: FAIL, reporting that `test_stats.gd` could not load.

- [ ] **Step 3: Implement the classes**

`scripts/content/stat_effect.gd`:

```gdscript
class_name StatEffect
extends Resource

@export var bonus_pills: int = 0
@export var move_speed_bonus: float = 0.0
@export var dodge_cooldown_cut: float = 0.0
@export var damage_bonus: float = 0.0
@export var pension_bonus: float = 0.0
@export var warning_bonus: float = 0.0
```

`scripts/content/item_def.gd`:

```gdscript
class_name ItemDef
extends StatEffect

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
```

`scripts/content/upgrade_def.gd`:

```gdscript
class_name UpgradeDef
extends StatEffect

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var prices: PackedInt32Array = []


func max_level() -> int:
	return prices.size()


func price_at(level: int) -> int:
	if level < 0 or level >= prices.size():
		return -1
	return prices[level]
```

`scripts/content/content.gd`:

```gdscript
class_name Content
extends RefCounted

const ITEMS_DIR := "res://data/items/"
const UPGRADES_DIR := "res://data/upgrades/"


static func load_dir(path: String) -> Array:
	var loaded: Array = []
	var files := DirAccess.get_files_at(path)
	files.sort()
	for file in files:
		var name := file.trim_suffix(".remap")
		if not name.ends_with(".tres"):
			continue
		var resource := ResourceLoader.load(path + name)
		if resource == null:
			push_error("Could not load content file: %s" % (path + name))
			continue
		loaded.append(resource)
	return loaded


static func items() -> Array[ItemDef]:
	var list: Array[ItemDef] = []
	for resource in load_dir(ITEMS_DIR):
		if resource is ItemDef:
			list.append(resource)
	return list


static func upgrades() -> Array[UpgradeDef]:
	var list: Array[UpgradeDef] = []
	for resource in load_dir(UPGRADES_DIR):
		if resource is UpgradeDef:
			list.append(resource)
	return list
```

`scripts/core/player_stats.gd`:

```gdscript
class_name PlayerStats
extends RefCounted

const BASE_PILLS := 4
const BASE_SPEED := 120.0
const BASE_DODGE_COOLDOWN := 1.0
const BASE_WARNING := 0.5
const MAX_DODGE_CUT := 0.5

var max_pills: int = BASE_PILLS
var move_speed: float = BASE_SPEED
var dodge_cooldown: float = BASE_DODGE_COOLDOWN
var damage_mult: float = 1.0
var pension_mult: float = 1.0
var warning_fraction: float = BASE_WARNING


static func compute(upgrades: Array[UpgradeDef], levels: Dictionary, items: Array[ItemDef]) -> PlayerStats:
	var pills := 0
	var speed := 0.0
	var cut := 0.0
	var damage := 0.0
	var pension := 0.0
	var warning := 0.0
	var effects: Array = []
	for upgrade in upgrades:
		effects.append([upgrade, int(levels.get(upgrade.id, 0))])
	for item in items:
		effects.append([item, 1])
	for entry in effects:
		var effect: StatEffect = entry[0]
		var count: int = entry[1]
		pills += effect.bonus_pills * count
		speed += effect.move_speed_bonus * count
		cut += effect.dodge_cooldown_cut * count
		damage += effect.damage_bonus * count
		pension += effect.pension_bonus * count
		warning += effect.warning_bonus * count
	var stats := PlayerStats.new()
	stats.max_pills = BASE_PILLS + pills
	stats.move_speed = BASE_SPEED * (1.0 + speed)
	stats.dodge_cooldown = BASE_DODGE_COOLDOWN * (1.0 - minf(cut, MAX_DODGE_CUT))
	stats.damage_mult = 1.0 + damage
	stats.pension_mult = 1.0 + pension
	stats.warning_fraction = minf(BASE_WARNING + warning, 1.0)
	return stats
```

- [ ] **Step 4: Create the content files**

`data/items/dentures.tres`:

```
[gd_resource type="Resource" script_class="ItemDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/content/item_def.gd" id="1"]

[resource]
script = ExtResource("1")
id = "dentures"
display_name = "Extra Strong Dentures"
description = "More cane damage. Don't ask how."
damage_bonus = 0.25
```

`data/items/slippers.tres`:

```
[gd_resource type="Resource" script_class="ItemDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/content/item_def.gd" id="1"]

[resource]
script = ExtResource("1")
id = "slippers"
display_name = "Orthopedic Slippers"
description = "Faster movement."
move_speed_bonus = 0.15
```

`data/items/prune_juice.tres`:

```
[gd_resource type="Resource" script_class="ItemDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/content/item_def.gd" id="1"]

[resource]
script = ExtResource("1")
id = "prune_juice"
display_name = "Prune Juice"
description = "Shorter dodge cooldown. You will move quickly."
dodge_cooldown_cut = 0.3
```

`data/items/hearing_aid.tres`:

```
[gd_resource type="Resource" script_class="ItemDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/content/item_def.gd" id="1"]

[resource]
script = ExtResource("1")
id = "hearing_aid"
display_name = "Hearing Aid"
description = "See enemy attacks coming earlier."
warning_bonus = 0.5
```

`data/items/bingo_card.tres`:

```
[gd_resource type="Resource" script_class="ItemDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/content/item_def.gd" id="1"]

[resource]
script = ExtResource("1")
id = "bingo_card"
display_name = "Lucky Bingo Card"
description = "More Pension from all sources."
pension_bonus = 0.25
```

`data/items/pill_organizer.tres`:

```
[gd_resource type="Resource" script_class="ItemDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/content/item_def.gd" id="1"]

[resource]
script = ExtResource("1")
id = "pill_organizer"
display_name = "Spare Pill Organizer"
description = "One extra pill for this run."
bonus_pills = 1
```

`data/upgrades/black_market_pills.tres`:

```
[gd_resource type="Resource" script_class="UpgradeDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/content/upgrade_def.gd" id="1"]

[resource]
script = ExtResource("1")
id = "black_market_pills"
display_name = "Black Market Pills"
description = "One more starting pill."
prices = PackedInt32Array(40, 100, 200)
bonus_pills = 1
```

`data/upgrades/better_knees.tres`:

```
[gd_resource type="Resource" script_class="UpgradeDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/content/upgrade_def.gd" id="1"]

[resource]
script = ExtResource("1")
id = "better_knees"
display_name = "Better Knees"
description = "Faster movement and a shorter dodge cooldown."
prices = PackedInt32Array(30, 75, 150)
move_speed_bonus = 0.05
dodge_cooldown_cut = 0.1
```

`data/upgrades/reinforced_cane.tres`:

```
[gd_resource type="Resource" script_class="UpgradeDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/content/upgrade_def.gd" id="1"]

[resource]
script = ExtResource("1")
id = "reinforced_cane"
display_name = "Reinforced Cane"
description = "More cane damage."
prices = PackedInt32Array(50, 120, 240)
damage_bonus = 0.1
```

`data/upgrades/bribed_clerk.tres`:

```
[gd_resource type="Resource" script_class="UpgradeDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/content/upgrade_def.gd" id="1"]

[resource]
script = ExtResource("1")
id = "bribed_clerk"
display_name = "Bribed Clerk"
description = "More Pension from all sources."
prices = PackedInt32Array(60, 150)
pension_bonus = 0.1
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `powershell -File tools/test.ps1`
Expected: 0 failed.

- [ ] **Step 6: Commit**

```powershell
git add scripts data tests
git commit -m "Add items, upgrades and player stat calculation" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Saved progress

**Files:**
- Create: `scripts/core/progress_data.gd`, `scripts/core/save_store.gd`
- Test: `tests/test_save.gd`

**Interfaces:**
- Consumes: `UpgradeDef.price_at`, `UpgradeDef.id`.
- Produces:
  - `ProgressData`: `pension: int`, `upgrades: Dictionary` of id to level, `opening_seen: bool`, `level_of(id: String) -> int`, `add_pension(amount: int)`, `can_buy(def: UpgradeDef) -> bool`, `buy(def: UpgradeDef) -> bool`, `to_dict() -> Dictionary`, static `from_dict(raw: Variant) -> ProgressData`, returning null when invalid.
  - `SaveStore.new(path: String)`: `save_progress(data: ProgressData) -> bool`, `load_progress() -> ProgressData`, `delete_all()`, `last_status: int`, with constants `STATUS_OK`, `STATUS_NEW`, `STATUS_BACKUP`, `STATUS_RESET`.

- [ ] **Step 1: Write the failing test**

`tests/test_save.gd`:

```gdscript
extends TestCase

const PATH := "user://test_save.json"


func _store() -> SaveStore:
	var store := SaveStore.new(PATH)
	store.delete_all()
	return store


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _upgrade(prices: Array) -> UpgradeDef:
	var def := UpgradeDef.new()
	def.id = "cane"
	def.prices = PackedInt32Array(prices)
	return def


func test_no_save_starts_new_without_warning() -> void:
	var store := _store()
	var data := store.load_progress()
	assert_eq(data.pension, 0)
	assert_eq(store.last_status, SaveStore.STATUS_NEW)


func test_round_trip() -> void:
	var store := _store()
	var data := ProgressData.new()
	data.pension = 42
	data.upgrades = {"cane": 2}
	data.opening_seen = true
	assert_true(store.save_progress(data))
	var loaded := store.load_progress()
	assert_eq(loaded.pension, 42)
	assert_eq(loaded.level_of("cane"), 2)
	assert_true(loaded.opening_seen)
	assert_eq(store.last_status, SaveStore.STATUS_OK)
	store.delete_all()


func test_damaged_save_uses_backup() -> void:
	var store := _store()
	var data := ProgressData.new()
	data.pension = 10
	store.save_progress(data)
	data.pension = 20
	store.save_progress(data)
	_write(PATH, "{not json")
	var loaded := store.load_progress()
	assert_eq(loaded.pension, 10)
	assert_eq(store.last_status, SaveStore.STATUS_BACKUP)
	store.delete_all()


func test_both_damaged_resets_and_reports() -> void:
	var store := _store()
	_write(PATH, "garbage")
	_write(PATH + ".bak", "garbage")
	var loaded := store.load_progress()
	assert_eq(loaded.pension, 0)
	assert_eq(store.last_status, SaveStore.STATUS_RESET)
	store.delete_all()


func test_missing_main_with_backup_recovers() -> void:
	var store := _store()
	var data := ProgressData.new()
	data.pension = 7
	store.save_progress(data)
	store.save_progress(data)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	assert_eq(store.load_progress().pension, 7)
	assert_eq(store.last_status, SaveStore.STATUS_BACKUP)
	store.delete_all()


func test_from_dict_rejects_bad_data() -> void:
	assert_true(ProgressData.from_dict("nope") == null)
	assert_true(ProgressData.from_dict({"version": 99, "pension": 1, "upgrades": {}, "opening_seen": false}) == null)
	assert_true(ProgressData.from_dict({"version": 1, "pension": -5, "upgrades": {}, "opening_seen": false}) == null)
	assert_true(ProgressData.from_dict({"version": 1, "pension": 5}) == null)


func test_buy_spends_pension_and_raises_level() -> void:
	var data := ProgressData.new()
	data.pension = 30
	var def := _upgrade([10, 100])
	assert_true(data.buy(def))
	assert_eq(data.pension, 20)
	assert_eq(data.level_of("cane"), 1)


func test_cannot_buy_without_pension() -> void:
	var data := ProgressData.new()
	data.pension = 5
	assert_false(data.buy(_upgrade([10])))
	assert_eq(data.pension, 5)
	assert_eq(data.level_of("cane"), 0)


func test_cannot_buy_past_max_level() -> void:
	var data := ProgressData.new()
	data.pension = 100
	data.upgrades = {"cane": 1}
	assert_false(data.buy(_upgrade([10])))
	assert_eq(data.pension, 100)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `powershell -File tools/test.ps1`
Expected: FAIL, reporting that `test_save.gd` could not load.

- [ ] **Step 3: Implement**

`scripts/core/progress_data.gd`:

```gdscript
class_name ProgressData
extends RefCounted

const VERSION := 1

var pension: int = 0
var upgrades: Dictionary = {}
var opening_seen: bool = false


func level_of(id: String) -> int:
	return int(upgrades.get(id, 0))


func add_pension(amount: int) -> void:
	pension += maxi(amount, 0)


func can_buy(def: UpgradeDef) -> bool:
	var price := def.price_at(level_of(def.id))
	return price >= 0 and pension >= price


func buy(def: UpgradeDef) -> bool:
	if not can_buy(def):
		return false
	pension -= def.price_at(level_of(def.id))
	upgrades[def.id] = level_of(def.id) + 1
	return true


func to_dict() -> Dictionary:
	return {
		"version": VERSION,
		"pension": pension,
		"upgrades": upgrades,
		"opening_seen": opening_seen,
	}


static func from_dict(raw: Variant) -> ProgressData:
	if not raw is Dictionary:
		return null
	for key in ["version", "pension", "upgrades", "opening_seen"]:
		if not raw.has(key):
			return null
	if int(raw["version"]) != VERSION or int(raw["pension"]) < 0:
		return null
	if not raw["upgrades"] is Dictionary or not raw["opening_seen"] is bool:
		return null
	var data := ProgressData.new()
	data.pension = int(raw["pension"])
	data.opening_seen = raw["opening_seen"]
	for id in raw["upgrades"]:
		data.upgrades[str(id)] = int(raw["upgrades"][id])
	return data
```

`scripts/core/save_store.gd`:

```gdscript
class_name SaveStore
extends RefCounted

enum { STATUS_OK, STATUS_NEW, STATUS_BACKUP, STATUS_RESET }

var last_status: int = STATUS_NEW
var _path: String
var _backup: String
var _temp: String


func _init(path: String) -> void:
	_path = ProjectSettings.globalize_path(path)
	_backup = _path + ".bak"
	_temp = _path + ".tmp"


func save_progress(data: ProgressData) -> bool:
	var file := FileAccess.open(_temp, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save file: %s" % _temp)
		return false
	file.store_string(JSON.stringify(data.to_dict()))
	file.close()
	if FileAccess.file_exists(_path):
		if FileAccess.file_exists(_backup):
			DirAccess.remove_absolute(_backup)
		DirAccess.rename_absolute(_path, _backup)
	return DirAccess.rename_absolute(_temp, _path) == OK


func load_progress() -> ProgressData:
	var had_main := FileAccess.file_exists(_path)
	var had_backup := FileAccess.file_exists(_backup)
	if not had_main and not had_backup:
		last_status = STATUS_NEW
		return ProgressData.new()
	var data := _read(_path)
	if data != null:
		last_status = STATUS_OK
		return data
	data = _read(_backup)
	if data != null:
		last_status = STATUS_BACKUP
		return data
	last_status = STATUS_RESET
	return ProgressData.new()


func delete_all() -> void:
	for path in [_path, _backup, _temp]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _read(path: String) -> ProgressData:
	if not FileAccess.file_exists(path):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return ProgressData.from_dict(json.data)
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `powershell -File tools/test.ps1`
Expected: 0 failed.

- [ ] **Step 5: Commit**

```powershell
git add scripts tests
git commit -m "Add saved progress with backup recovery" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Health and run state

**Files:**
- Create: `scripts/core/health.gd`, `scripts/core/run_state.gd`
- Test: `tests/test_run_state.gd`

**Interfaces:**
- Consumes: `PlayerStats.compute`, `ItemDef`, `UpgradeDef`.
- Produces:
  - `Health.new(max_pills: int)`: signals `changed`, `died`; `max_pills`, `pills`, `hit(amount: int) -> bool`, `heal(amount: int)`, `raise_max(new_max: int)`, `tick(delta: float)`, `is_dead() -> bool`, `is_invulnerable() -> bool`. A hit gives `INVULN_TIME` of invulnerability.
  - `RunState.new(upgrades: Array[UpgradeDef], levels: Dictionary)`: signal `changed`; `stats: PlayerStats`, `health: Health`, `items: Array[ItemDef]`, `add_item(item: ItemDef)`, `has_item(id: String) -> bool`, `pension_amount(base: int) -> int`.

- [ ] **Step 1: Write the failing test**

`tests/test_run_state.gd`:

```gdscript
extends TestCase


func _run(levels := {}) -> RunState:
	var pills := UpgradeDef.new()
	pills.id = "pills"
	pills.bonus_pills = 1
	var upgrades: Array[UpgradeDef] = [pills]
	return RunState.new(upgrades, levels)


func test_hit_removes_pills_and_grants_invulnerability() -> void:
	var health := Health.new(4)
	assert_true(health.hit(1))
	assert_eq(health.pills, 3)
	assert_false(health.hit(1), "invulnerable")
	assert_eq(health.pills, 3)
	health.tick(Health.INVULN_TIME + 0.01)
	assert_true(health.hit(1))
	assert_eq(health.pills, 2)


func test_death_signal_fires_once() -> void:
	var health := Health.new(1)
	var deaths := [0]
	health.died.connect(func(): deaths[0] += 1)
	health.hit(5)
	health.tick(Health.INVULN_TIME + 0.01)
	health.hit(1)
	assert_eq(deaths[0], 1)
	assert_true(health.is_dead())
	assert_eq(health.pills, 0)


func test_heal_stops_at_max() -> void:
	var health := Health.new(4)
	health.hit(3)
	health.heal(2)
	assert_eq(health.pills, 3)
	health.heal(5)
	assert_eq(health.pills, 4)


func test_raise_max_adds_the_difference() -> void:
	var health := Health.new(4)
	health.hit(2)
	health.raise_max(5)
	assert_eq(health.max_pills, 5)
	assert_eq(health.pills, 3)


func test_run_starts_with_upgrades_applied() -> void:
	var run := _run({"pills": 2})
	assert_eq(run.stats.max_pills, 6)
	assert_eq(run.health.pills, 6)


func test_extra_pill_item_raises_and_restores() -> void:
	var run := _run()
	var organizer := ItemDef.new()
	organizer.id = "organizer"
	organizer.bonus_pills = 1
	run.add_item(organizer)
	assert_eq(run.stats.max_pills, 5)
	assert_eq(run.health.pills, 5)
	assert_true(run.has_item("organizer"))


func test_item_changes_stats_and_signals() -> void:
	var run := _run()
	var calls := [0]
	run.changed.connect(func(): calls[0] += 1)
	var dentures := ItemDef.new()
	dentures.damage_bonus = 0.5
	run.add_item(dentures)
	assert_near(run.stats.damage_mult, 1.5)
	assert_eq(calls[0], 1)


func test_pension_amount_rounds_up() -> void:
	var run := _run()
	var card := ItemDef.new()
	card.pension_bonus = 0.25
	run.add_item(card)
	assert_eq(run.pension_amount(5), 7)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `powershell -File tools/test.ps1`
Expected: FAIL, reporting that `test_run_state.gd` could not load.

- [ ] **Step 3: Implement**

`scripts/core/health.gd`:

```gdscript
class_name Health
extends RefCounted

signal changed
signal died

const INVULN_TIME := 0.8

var max_pills: int
var pills: int
var _invuln := 0.0


func _init(start_pills: int) -> void:
	max_pills = start_pills
	pills = start_pills


func hit(amount: int) -> bool:
	if is_dead() or is_invulnerable():
		return false
	pills = maxi(pills - amount, 0)
	_invuln = INVULN_TIME
	changed.emit()
	if pills == 0:
		died.emit()
	return true


func heal(amount: int) -> void:
	if is_dead():
		return
	pills = mini(pills + amount, max_pills)
	changed.emit()


func raise_max(new_max: int) -> void:
	var difference := new_max - max_pills
	max_pills = new_max
	if difference > 0:
		pills += difference
	changed.emit()


func tick(delta: float) -> void:
	_invuln = maxf(_invuln - delta, 0.0)


func is_dead() -> bool:
	return pills <= 0


func is_invulnerable() -> bool:
	return _invuln > 0.0
```

`scripts/core/run_state.gd`:

```gdscript
class_name RunState
extends RefCounted

signal changed

var stats: PlayerStats
var health: Health
var items: Array[ItemDef] = []
var _upgrades: Array[UpgradeDef]
var _levels: Dictionary


func _init(upgrades: Array[UpgradeDef], levels: Dictionary) -> void:
	_upgrades = upgrades
	_levels = levels
	stats = PlayerStats.compute(_upgrades, _levels, items)
	health = Health.new(stats.max_pills)
	health.changed.connect(func(): changed.emit())


func add_item(item: ItemDef) -> void:
	items.append(item)
	stats = PlayerStats.compute(_upgrades, _levels, items)
	if stats.max_pills != health.max_pills:
		health.raise_max(stats.max_pills)
	else:
		changed.emit()


func has_item(id: String) -> bool:
	for item in items:
		if item.id == id:
			return true
	return false


func pension_amount(base: int) -> int:
	return ceili(base * stats.pension_mult)
```

Note: `raise_max` emits `Health.changed`, which `RunState` forwards, so `changed` fires exactly once per added item.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `powershell -File tools/test.ps1`
Expected: 0 failed.

- [ ] **Step 5: Commit**

```powershell
git add scripts tests
git commit -m "Add health and run state" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Combat rules

**Files:**
- Create: `scripts/core/cane_combo.gd`, `scripts/core/charge_swing.gd`, `scripts/core/dodge_timer.gd`, `scripts/core/melee_arc.gd`, `scripts/core/telegraph.gd`, `scripts/core/input_setup.gd`
- Test: `tests/test_combat.gd`

**Interfaces:**
- Produces:
  - `CaneCombo`: `try_attack() -> int`, returning the damage or 0 when locked; `tick(delta)`; `step() -> int`; constants `DAMAGE`, `LOCK_TIME`, `WINDOW`.
  - `ChargeSwing`: `start()`, `release() -> bool`, true when fully charged; `tick(delta)`; `is_charging() -> bool`; `progress() -> float`; constants `CHARGE_TIME`, `DAMAGE`, `KNOCKBACK`.
  - `DodgeTimer`: `try_start(cooldown: float) -> bool`, `tick(delta)`, `is_active() -> bool`; constant `DURATION`.
  - `MeleeArc`: static `hits(origin: Vector2, direction: Vector2, reach: float, half_angle_deg: float, target: Vector2) -> bool`.
  - `Telegraph`: `start(duration: float)`, `tick(delta) -> bool`, true once when finished; `is_active() -> bool`; `shows_warning(fraction: float) -> bool`.
  - `InputSetup`: static `ensure()`, creating actions `move_left`, `move_right`, `move_up`, `move_down`, `attack`, `charge`, `dodge`, `interact`.

- [ ] **Step 1: Write the failing test**

`tests/test_combat.gd`:

```gdscript
extends TestCase


func test_combo_runs_three_hits_with_a_stronger_finish() -> void:
	var combo := CaneCombo.new()
	assert_eq(combo.try_attack(), 10)
	combo.tick(CaneCombo.LOCK_TIME + 0.01)
	assert_eq(combo.try_attack(), 10)
	combo.tick(CaneCombo.LOCK_TIME + 0.01)
	assert_eq(combo.try_attack(), 18)
	combo.tick(CaneCombo.LOCK_TIME + 0.01)
	assert_eq(combo.try_attack(), 10, "wraps to the first hit")


func test_combo_is_locked_during_a_swing() -> void:
	var combo := CaneCombo.new()
	combo.try_attack()
	assert_eq(combo.try_attack(), 0)


func test_combo_resets_after_the_window() -> void:
	var combo := CaneCombo.new()
	combo.try_attack()
	combo.tick(CaneCombo.LOCK_TIME + CaneCombo.WINDOW + 0.01)
	assert_eq(combo.step(), 0)


func test_charge_needs_full_time() -> void:
	var charge := ChargeSwing.new()
	charge.start()
	charge.tick(ChargeSwing.CHARGE_TIME - 0.1)
	assert_false(charge.release())
	assert_false(charge.is_charging())
	charge.start()
	charge.tick(ChargeSwing.CHARGE_TIME + 0.01)
	assert_near(charge.progress(), 1.0)
	assert_true(charge.release())


func test_dodge_has_duration_and_cooldown() -> void:
	var dodge := DodgeTimer.new()
	assert_true(dodge.try_start(1.0))
	assert_true(dodge.is_active())
	assert_false(dodge.try_start(1.0))
	dodge.tick(DodgeTimer.DURATION + 0.01)
	assert_false(dodge.is_active())
	assert_false(dodge.try_start(1.0), "cooling down")
	dodge.tick(1.0)
	assert_true(dodge.try_start(1.0))


func test_melee_arc() -> void:
	var o := Vector2.ZERO
	assert_true(MeleeArc.hits(o, Vector2.RIGHT, 40.0, 60.0, Vector2(30, 0)))
	assert_false(MeleeArc.hits(o, Vector2.RIGHT, 40.0, 60.0, Vector2(50, 0)), "too far")
	assert_false(MeleeArc.hits(o, Vector2.RIGHT, 40.0, 60.0, Vector2(-30, 0)), "behind")
	assert_true(MeleeArc.hits(o, Vector2.RIGHT, 40.0, 60.0, Vector2.ZERO), "same spot")


func test_telegraph_finishes_once() -> void:
	var telegraph := Telegraph.new()
	telegraph.start(1.0)
	assert_true(telegraph.is_active())
	assert_false(telegraph.tick(0.5))
	assert_true(telegraph.tick(0.6))
	assert_false(telegraph.is_active())
	assert_false(telegraph.tick(0.1))


func test_warning_shows_for_the_given_fraction() -> void:
	var telegraph := Telegraph.new()
	telegraph.start(1.0)
	assert_false(telegraph.shows_warning(0.5))
	assert_true(telegraph.shows_warning(1.0))
	telegraph.tick(0.6)
	assert_true(telegraph.shows_warning(0.5))


func test_input_actions_exist() -> void:
	InputSetup.ensure()
	InputSetup.ensure()
	for action in ["move_left", "move_right", "move_up", "move_down", "attack", "charge", "dodge", "interact"]:
		assert_true(InputMap.has_action(action), action)
		assert_eq(InputMap.action_get_events(action).size(), 1, action)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `powershell -File tools/test.ps1`
Expected: FAIL, reporting that `test_combat.gd` could not load.

- [ ] **Step 3: Implement**

`scripts/core/cane_combo.gd`:

```gdscript
class_name CaneCombo
extends RefCounted

const DAMAGE := [10, 10, 18]
const LOCK_TIME := 0.2
const WINDOW := 0.45

var _step := 0
var _lock := 0.0
var _window := 0.0


func try_attack() -> int:
	if _lock > 0.0:
		return 0
	var damage: int = DAMAGE[_step]
	_step = (_step + 1) % DAMAGE.size()
	_lock = LOCK_TIME
	_window = WINDOW
	return damage


func tick(delta: float) -> void:
	if _lock > 0.0:
		var used := minf(_lock, delta)
		_lock -= used
		delta -= used
	if _lock <= 0.0 and _window > 0.0:
		_window -= delta
		if _window <= 0.0:
			_window = 0.0
			_step = 0


func step() -> int:
	return _step
```

`scripts/core/charge_swing.gd`:

```gdscript
class_name ChargeSwing
extends RefCounted

const CHARGE_TIME := 0.7
const DAMAGE := 30
const KNOCKBACK := 220.0

var _charging := false
var _time := 0.0


func start() -> void:
	_charging = true
	_time = 0.0


func release() -> bool:
	var ready := _charging and _time >= CHARGE_TIME
	_charging = false
	_time = 0.0
	return ready


func tick(delta: float) -> void:
	if _charging:
		_time += delta


func is_charging() -> bool:
	return _charging


func progress() -> float:
	return minf(_time / CHARGE_TIME, 1.0)
```

`scripts/core/dodge_timer.gd`:

```gdscript
class_name DodgeTimer
extends RefCounted

const DURATION := 0.2

var _active := 0.0
var _cooldown := 0.0


func try_start(cooldown: float) -> bool:
	if _active > 0.0 or _cooldown > 0.0:
		return false
	_active = DURATION
	_cooldown = cooldown
	return true


func tick(delta: float) -> void:
	if _active > 0.0:
		var used := minf(_active, delta)
		_active -= used
		delta -= used
	if _active <= 0.0:
		_cooldown = maxf(_cooldown - delta, 0.0)


func is_active() -> bool:
	return _active > 0.0
```

`scripts/core/melee_arc.gd`:

```gdscript
class_name MeleeArc
extends RefCounted


static func hits(origin: Vector2, direction: Vector2, reach: float, half_angle_deg: float, target: Vector2) -> bool:
	var offset := target - origin
	if offset.length() > reach:
		return false
	if offset.is_zero_approx():
		return true
	return absf(direction.angle_to(offset)) <= deg_to_rad(half_angle_deg)
```

`scripts/core/telegraph.gd`:

```gdscript
class_name Telegraph
extends RefCounted

var _duration := 0.0
var _remaining := 0.0


func start(duration: float) -> void:
	_duration = duration
	_remaining = duration


func tick(delta: float) -> bool:
	if _remaining <= 0.0:
		return false
	_remaining -= delta
	return _remaining <= 0.0


func is_active() -> bool:
	return _remaining > 0.0


func shows_warning(fraction: float) -> bool:
	return is_active() and _remaining <= _duration * fraction
```

`scripts/core/input_setup.gd`:

```gdscript
class_name InputSetup
extends RefCounted


static func ensure() -> void:
	_key("move_left", KEY_A)
	_key("move_right", KEY_D)
	_key("move_up", KEY_W)
	_key("move_down", KEY_S)
	_key("dodge", KEY_SPACE)
	_key("interact", KEY_E)
	_mouse("attack", MOUSE_BUTTON_LEFT)
	_mouse("charge", MOUSE_BUTTON_RIGHT)


static func _key(action: String, key: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)


static func _mouse(action: String, button: MouseButton) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `powershell -File tools/test.ps1`
Expected: 0 failed.

- [ ] **Step 5: Commit**

```powershell
git add scripts tests
git commit -m "Add combat rules, attack warnings and input setup" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Player and sandbox

**Files:**
- Create: `scripts/world/sprite_visual.gd`, `scripts/world/room_backdrop.gd`, `scripts/actors/player.gd`, `scripts/scenes/sandbox.gd`, `scenes/dev/sandbox.tscn`
- Test: `tests/test_sprite_visual.gd`

**Interfaces:**
- Consumes: `RunState`, `CaneCombo`, `ChargeSwing`, `DodgeTimer`, `MeleeArc`, `InputSetup`.
- Produces:
  - `SpriteVisual` Node2D: `setup(art_id: String, body_size: Vector2, color: Color, frame_width: int)`, `play(anim: String)`, `set_facing_left(left: bool)`, static `frame_count(texture_width: int, frame_width: int) -> int`. Looks for `res://art/sprites/<art_id>/<anim>.png` as a horizontal strip, and draws a colored placeholder when it's missing.
  - `RoomBackdrop` Node2D: `setup(rows: PackedStringArray)`, constant `TILE := 32`, static `cell_center(cell: Vector2i) -> Vector2`. Draws tiles and creates wall bodies on collision layer 1.
  - `Player` CharacterBody2D: `setup(run_state: RunState)`, `run: RunState`, `take_hit(amount: int) -> bool`, signal `died`, group `player`. It finds targets in group `enemies` and calls `take_damage(amount: float, push: Vector2)` on them.

- [ ] **Step 1: Write the failing test**

`tests/test_sprite_visual.gd`:

```gdscript
extends TestCase


func test_frame_count_from_strip_width() -> void:
	assert_eq(SpriteVisual.frame_count(128, 32), 4)


func test_frame_count_is_at_least_one() -> void:
	assert_eq(SpriteVisual.frame_count(16, 32), 1)
	assert_eq(SpriteVisual.frame_count(64, 0), 1)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `powershell -File tools/test.ps1`
Expected: FAIL, reporting that `test_sprite_visual.gd` could not load.

- [ ] **Step 3: Implement**

`scripts/world/sprite_visual.gd`:

```gdscript
class_name SpriteVisual
extends Node2D

const FPS := 10.0

var _art_id := ""
var _size := Vector2(20, 24)
var _color := Color.WHITE
var _frame_width := 32
var _anim := ""
var _sprite: Sprite2D
var _time := 0.0


static func frame_count(texture_width: int, frame_width: int) -> int:
	if frame_width <= 0:
		return 1
	return maxi(texture_width / frame_width, 1)


func setup(art_id: String, body_size: Vector2, color: Color, frame_width: int) -> void:
	_art_id = art_id
	_size = body_size
	_color = color
	_frame_width = frame_width
	play("idle")


func play(anim: String) -> void:
	if anim == _anim:
		return
	_anim = anim
	_time = 0.0
	var path := "res://art/sprites/%s/%s.png" % [_art_id, anim]
	if not ResourceLoader.exists(path):
		if _sprite != null:
			_sprite.visible = false
		queue_redraw()
		return
	if _sprite == null:
		_sprite = Sprite2D.new()
		add_child(_sprite)
	var texture: Texture2D = load(path)
	_sprite.texture = texture
	_sprite.hframes = frame_count(texture.get_width(), _frame_width)
	_sprite.frame = 0
	_sprite.visible = true
	queue_redraw()


func set_facing_left(left: bool) -> void:
	if _sprite != null:
		_sprite.flip_h = left


func _process(delta: float) -> void:
	if _sprite == null or not _sprite.visible:
		return
	_time += delta
	_sprite.frame = int(_time * FPS) % _sprite.hframes


func _draw() -> void:
	if _sprite != null and _sprite.visible:
		return
	draw_rect(Rect2(-_size / 2.0, _size), _color)
	draw_rect(Rect2(-_size / 2.0, _size), Color.BLACK, false, 1.0)
```

`scripts/world/room_backdrop.gd`:

```gdscript
class_name RoomBackdrop
extends Node2D

const TILE := 32
const FLOOR_A := Color("6a6677")
const FLOOR_B := Color("625e6f")
const WALL := Color("3a3547")

var _rows: PackedStringArray = []


static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)


func setup(rows: PackedStringArray) -> void:
	_rows = rows
	z_index = -10


func _ready() -> void:
	for y in _rows.size():
		for x in _rows[y].length():
			if _rows[y][x] == "#":
				_add_wall(Vector2i(x, y))
	queue_redraw()


func _add_wall(cell: Vector2i) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = cell_center(cell)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE)
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func _draw() -> void:
	for y in _rows.size():
		for x in _rows[y].length():
			var color := WALL if _rows[y][x] == "#" else (FLOOR_A if (x + y) % 2 == 0 else FLOOR_B)
			draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), color)
```

`scripts/actors/player.gd`:

```gdscript
class_name Player
extends CharacterBody2D

signal died

const ATTACK_REACH := 44.0
const ATTACK_ANGLE := 60.0
const CHARGE_REACH := 56.0
const CHARGE_ANGLE := 75.0
const ATTACK_PUSH := 60.0
const DODGE_SPEED := 300.0
const CHARGE_SLOWDOWN := 0.4
const SWING_SHOW_TIME := 0.1

var run: RunState
var _combo := CaneCombo.new()
var _charge := ChargeSwing.new()
var _dodge := DodgeTimer.new()
var _aim := Vector2.RIGHT
var _dodge_direction := Vector2.RIGHT
var _swing_show := 0.0
var _swing_reach := 0.0
var _visual: SpriteVisual


func setup(run_state: RunState) -> void:
	run = run_state


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 18)
	shape.shape = rect
	add_child(shape)
	_visual = SpriteVisual.new()
	add_child(_visual)
	_visual.setup("grandpa", Vector2(20, 28), Color("7d9a5c"), 32)
	run.health.died.connect(func(): died.emit())


func take_hit(amount: int) -> bool:
	if _dodge.is_active():
		return false
	return run.health.hit(amount)


func _physics_process(delta: float) -> void:
	_combo.tick(delta)
	_charge.tick(delta)
	_dodge.tick(delta)
	run.health.tick(delta)
	_swing_show = maxf(_swing_show - delta, 0.0)
	var to_mouse := get_global_mouse_position() - global_position
	if not to_mouse.is_zero_approx():
		_aim = to_mouse.normalized()
	_visual.set_facing_left(_aim.x < 0.0)
	_handle_attacks()
	_handle_movement()
	queue_redraw()


func _handle_attacks() -> void:
	if Input.is_action_just_pressed("charge"):
		_charge.start()
	if Input.is_action_just_released("charge"):
		if _charge.release():
			_swing(ChargeSwing.DAMAGE, CHARGE_REACH, CHARGE_ANGLE, ChargeSwing.KNOCKBACK)
	if Input.is_action_just_pressed("attack") and not _charge.is_charging():
		var damage := _combo.try_attack()
		if damage > 0:
			_swing(damage, ATTACK_REACH, ATTACK_ANGLE, ATTACK_PUSH)


func _swing(damage: float, reach: float, angle: float, push: float) -> void:
	_swing_show = SWING_SHOW_TIME
	_swing_reach = reach
	_visual.play("attack")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if MeleeArc.hits(global_position, _aim, reach, angle, enemy.global_position):
			enemy.take_damage(damage * run.stats.damage_mult, _aim * push)


func _handle_movement() -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_just_pressed("dodge") and _dodge.try_start(run.stats.dodge_cooldown):
		_dodge_direction = input.normalized() if input != Vector2.ZERO else _aim
	if _dodge.is_active():
		velocity = _dodge_direction * DODGE_SPEED
	else:
		var speed := run.stats.move_speed
		if _charge.is_charging():
			speed *= CHARGE_SLOWDOWN
		velocity = input * speed
		if _swing_show <= 0.0:
			_visual.play("walk" if input != Vector2.ZERO else "idle")
	move_and_slide()


func _draw() -> void:
	draw_line(Vector2.ZERO, _aim * 20.0, Color("a8692f"), 3.0)
	if _swing_show > 0.0:
		draw_arc(Vector2.ZERO, _swing_reach, _aim.angle() - 1.0, _aim.angle() + 1.0, 12, Color("ffe58a"), 3.0)
	if _charge.is_charging():
		draw_arc(Vector2.ZERO, 22.0, -PI / 2.0, -PI / 2.0 + TAU * _charge.progress(), 24, Color("f4c542"), 2.0)
```

`scripts/scenes/sandbox.gd`:

```gdscript
extends Node2D

const ROWS := [
	"####################",
	"#..................#",
	"#..................#",
	"#....##......##....#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#....##......##....#",
	"#..................#",
	"#..................#",
	"####################",
]

var player: Player


func _ready() -> void:
	InputSetup.ensure()
	var backdrop := RoomBackdrop.new()
	backdrop.setup(PackedStringArray(ROWS))
	add_child(backdrop)
	_spawn_player()


func _spawn_player() -> void:
	var upgrades: Array[UpgradeDef] = []
	player = Player.new()
	player.setup(RunState.new(upgrades, {}))
	player.position = RoomBackdrop.cell_center(Vector2i(10, 5))
	player.died.connect(_on_player_died)
	add_child(player)


func _on_player_died() -> void:
	player.queue_free()
	_spawn_player.call_deferred()
```

`scenes/dev/sandbox.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/scenes/sandbox.gd" id="1"]

[node name="Sandbox" type="Node2D"]
script = ExtResource("1")
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `powershell -File tools/test.ps1`
Expected: 0 failed.

- [ ] **Step 5: Check the sandbox loads without errors**

Run:

```powershell
$godot = if ($env:GODOT) { $env:GODOT } else { "D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
& $godot --headless --path C:\GameDev\game res://scenes/dev/sandbox.tscn --quit-after 60
```

Expected: exits with no `SCRIPT ERROR` or `Parse Error` lines.

- [ ] **Step 6: Commit**

```powershell
git add scripts scenes tests
git commit -m "Add player with cane combat and a sandbox room" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

**Human checkpoint:** Ask the user to run the sandbox and try moving, the combo, the charged swing and the dodge. Command: `& $godot --path C:\GameDev\game res://scenes/dev/sandbox.tscn`, using the non-console executable if preferred. Tune the constants in `player.gd`, `cane_combo.gd` and `charge_swing.gd` from their feedback.

---

### Task 7: Enemies

**Files:**
- Create: `scripts/content/enemy_def.gd`, `scripts/actors/enemy.gd`, `scripts/actors/enemy_behavior.gd`, `scripts/actors/projectile.gd`, `scripts/actors/behaviors/melee_behavior.gd`, `scripts/actors/behaviors/thrower_behavior.gd`, `scripts/actors/behaviors/charger_behavior.gd`, `data/enemies/intern_reaper.tres`, `data/enemies/filing_clerk.tres`, `data/enemies/debt_ghost.tres`
- Modify: `scripts/scenes/sandbox.gd`
- Test: `tests/test_enemy.gd`

**Interfaces:**
- Consumes: `Telegraph`, `SpriteVisual`, `Player.take_hit`.
- Produces:
  - `EnemyDef` Resource: `id`, `display_name`, `max_hp: float`, `speed: float`, `damage: int`, `pension_drop: int`, `ignores_walls: bool`, `is_boss: bool`, `body_size: Vector2`, `color: Color`, `frame_width: int`, `behavior_script: Script`, `summon: EnemyDef`.
  - `Enemy` CharacterBody2D: `setup(enemy_def: EnemyDef, target: Node2D, warning_fraction: float)`, `def`, `hp`, `target`, `desired_velocity`, `take_damage(amount: float, push: Vector2)`, `hit_target(amount: int)`, `distance_to_target() -> float`, `direction_to_target() -> Vector2`, `set_warning(telegraph: Telegraph, radius: float)`, `clear_warning()`, `shoot(direction: Vector2, speed: float)`, `request_summon(count: int)`, signals `defeated(enemy: Enemy)` and `summon_requested(enemy_def: EnemyDef, position: Vector2)`, group `enemies`.
  - `EnemyBehavior`: `tick(enemy: Enemy, delta: float)`.
  - `Projectile` Node2D: `setup(direction: Vector2, speed: float, target: Node2D, damage: int)`.

- [ ] **Step 1: Write the failing test**

`tests/test_enemy.gd`:

```gdscript
extends TestCase


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


func test_regular_enemies_load_with_behaviors() -> void:
	for id in ["intern_reaper", "filing_clerk", "debt_ghost"]:
		var def := _load(id)
		assert_true(def != null, id)
		assert_true(def.max_hp > 0.0, id)
		assert_true(def.pension_drop > 0, id)
		assert_true(def.behavior_script != null, id)
		assert_true(def.behavior_script.new() is EnemyBehavior, id)


func test_only_the_ghost_ignores_walls() -> void:
	assert_false(_load("intern_reaper").ignores_walls)
	assert_false(_load("filing_clerk").ignores_walls)
	assert_true(_load("debt_ghost").ignores_walls)


func test_damage_defeats_once() -> void:
	var enemy := Enemy.new()
	enemy.setup(_load("intern_reaper"), null, 0.5)
	var defeats := [0]
	enemy.defeated.connect(func(_e): defeats[0] += 1)
	enemy.take_damage(1000.0, Vector2.ZERO)
	enemy.take_damage(1000.0, Vector2.ZERO)
	assert_eq(defeats[0], 1)
	enemy.free()


func test_damage_reduces_hp() -> void:
	var def := _load("intern_reaper")
	var enemy := Enemy.new()
	enemy.setup(def, null, 0.5)
	enemy.take_damage(5.0, Vector2.ZERO)
	assert_near(enemy.hp, def.max_hp - 5.0)
	enemy.free()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `powershell -File tools/test.ps1`
Expected: FAIL, reporting that `test_enemy.gd` could not load.

- [ ] **Step 3: Implement the classes**

`scripts/content/enemy_def.gd`:

```gdscript
class_name EnemyDef
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: float = 30.0
@export var speed: float = 60.0
@export var damage: int = 1
@export var pension_drop: int = 4
@export var ignores_walls: bool = false
@export var is_boss: bool = false
@export var body_size: Vector2 = Vector2(20, 24)
@export var color: Color = Color.WHITE
@export var frame_width: int = 32
@export var behavior_script: Script
@export var summon: EnemyDef
```

`scripts/actors/enemy_behavior.gd`:

```gdscript
class_name EnemyBehavior
extends RefCounted


func tick(_enemy: Enemy, _delta: float) -> void:
	pass
```

`scripts/actors/enemy.gd`:

```gdscript
class_name Enemy
extends CharacterBody2D

signal defeated(enemy: Enemy)
signal summon_requested(enemy_def: EnemyDef, spawn_position: Vector2)

const KNOCKBACK_DECAY := 8.0
const BOSS_KNOCKBACK_SCALE := 0.2
const SUMMON_SPREAD := 40.0

var def: EnemyDef
var hp: float = 0.0
var target: Node2D
var desired_velocity := Vector2.ZERO
var _warning_fraction := 0.5
var _behavior: EnemyBehavior
var _knockback := Vector2.ZERO
var _dead := false
var _warning: Telegraph
var _warning_radius := 0.0
var _visual: SpriteVisual


func setup(enemy_def: EnemyDef, chase_target: Node2D, warning_fraction: float) -> void:
	def = enemy_def
	hp = def.max_hp
	target = chase_target
	_warning_fraction = warning_fraction
	_behavior = def.behavior_script.new()


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 0 if def.ignores_walls else 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = def.body_size * 0.8
	shape.shape = rect
	add_child(shape)
	_visual = SpriteVisual.new()
	add_child(_visual)
	_visual.setup(def.id, def.body_size, def.color, def.frame_width)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	desired_velocity = Vector2.ZERO
	_behavior.tick(self, delta)
	velocity = desired_velocity + _knockback
	_knockback = _knockback.lerp(Vector2.ZERO, minf(KNOCKBACK_DECAY * delta, 1.0))
	move_and_slide()
	queue_redraw()


func take_damage(amount: float, push: Vector2) -> void:
	if _dead:
		return
	hp -= amount
	_knockback += push * (BOSS_KNOCKBACK_SCALE if def.is_boss else 1.0)
	if hp <= 0.0:
		_dead = true
		defeated.emit(self)
		if is_inside_tree():
			queue_free()


func hit_target(amount: int) -> void:
	if is_instance_valid(target) and target.has_method("take_hit"):
		target.take_hit(amount)


func distance_to_target() -> float:
	return global_position.distance_to(target.global_position)


func direction_to_target() -> Vector2:
	return global_position.direction_to(target.global_position)


func set_warning(telegraph: Telegraph, radius: float) -> void:
	_warning = telegraph
	_warning_radius = radius


func clear_warning() -> void:
	_warning = null


func shoot(direction: Vector2, speed: float) -> void:
	var projectile := Projectile.new()
	projectile.setup(direction, speed, target, def.damage)
	projectile.position = position
	get_parent().add_child(projectile)


func request_summon(count: int) -> void:
	if def.summon == null:
		return
	for i in count:
		var angle := TAU * i / float(count)
		summon_requested.emit(def.summon, position + Vector2.from_angle(angle) * SUMMON_SPREAD)


func _draw() -> void:
	if _warning != null and _warning.shows_warning(_warning_fraction):
		draw_arc(Vector2.ZERO, _warning_radius, 0.0, TAU, 32, Color("e4524f"), 2.0)
	if def != null and def.is_boss:
		var width := def.body_size.x + 20.0
		var top := -def.body_size.y / 2.0 - 8.0
		draw_rect(Rect2(-width / 2.0, top, width, 3.0), Color.BLACK)
		draw_rect(Rect2(-width / 2.0, top, width * maxf(hp, 0.0) / def.max_hp, 3.0), Color("e4524f"))
```

`scripts/actors/projectile.gd`:

```gdscript
class_name Projectile
extends Node2D

const HIT_RADIUS := 12.0
const LIFETIME := 5.0

var _velocity := Vector2.ZERO
var _target: Node2D
var _damage := 1
var _age := 0.0


func setup(direction: Vector2, speed: float, target: Node2D, damage: int) -> void:
	_velocity = direction.normalized() * speed
	_target = target
	_damage = damage


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME or not is_instance_valid(_target):
		queue_free()
		return
	var next := global_position + _velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, next, 1)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		queue_free()
		return
	global_position = next
	if global_position.distance_to(_target.global_position) <= HIT_RADIUS:
		_target.take_hit(_damage)
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(-4, -5, 8, 10), Color("efe8d2"))
	draw_rect(Rect2(-4, -5, 8, 10), Color.BLACK, false, 1.0)
```

`scripts/actors/behaviors/melee_behavior.gd`:

```gdscript
extends EnemyBehavior

const START_RANGE := 30.0
const STRIKE_RANGE := 40.0
const WINDUP := 0.6
const COOLDOWN := 1.0

var _telegraph := Telegraph.new()
var _cooldown := 0.0


func tick(enemy: Enemy, delta: float) -> void:
	var distance := enemy.distance_to_target()
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = COOLDOWN
			if distance <= STRIKE_RANGE:
				enemy.hit_target(enemy.def.damage)
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if distance <= START_RANGE:
		if _cooldown <= 0.0:
			_telegraph.start(WINDUP)
			enemy.set_warning(_telegraph, STRIKE_RANGE)
		return
	enemy.desired_velocity = enemy.direction_to_target() * enemy.def.speed
```

`scripts/actors/behaviors/thrower_behavior.gd`:

```gdscript
extends EnemyBehavior

const TOO_CLOSE := 90.0
const TOO_FAR := 170.0
const WINDUP := 0.5
const COOLDOWN := 2.0
const PROJECTILE_SPEED := 110.0

var _telegraph := Telegraph.new()
var _cooldown := 1.0


func tick(enemy: Enemy, delta: float) -> void:
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			enemy.shoot(enemy.direction_to_target(), PROJECTILE_SPEED)
			_cooldown = COOLDOWN
		return
	_cooldown -= delta
	var distance := enemy.distance_to_target()
	if distance < TOO_CLOSE:
		enemy.desired_velocity = -enemy.direction_to_target() * enemy.def.speed
	elif distance > TOO_FAR:
		enemy.desired_velocity = enemy.direction_to_target() * enemy.def.speed
	if _cooldown <= 0.0:
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, 18.0)
```

`scripts/actors/behaviors/charger_behavior.gd`:

```gdscript
extends EnemyBehavior

const START_RANGE := 180.0
const WINDUP := 0.7
const CHARGE_TIME := 0.7
const CHARGE_SPEED := 240.0
const HIT_RANGE := 16.0
const COOLDOWN := 1.5

var _telegraph := Telegraph.new()
var _cooldown := 1.0
var _charge_left := 0.0
var _direction := Vector2.RIGHT
var _has_hit := false


func tick(enemy: Enemy, delta: float) -> void:
	if _charge_left > 0.0:
		_charge_left -= delta
		enemy.desired_velocity = _direction * CHARGE_SPEED
		if not _has_hit and enemy.distance_to_target() <= HIT_RANGE:
			_has_hit = true
			enemy.hit_target(enemy.def.damage)
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_charge_left = CHARGE_TIME
			_cooldown = COOLDOWN
			_has_hit = false
		return
	_cooldown -= delta
	enemy.desired_velocity = enemy.direction_to_target() * enemy.def.speed
	if _cooldown <= 0.0 and enemy.distance_to_target() <= START_RANGE:
		_direction = enemy.direction_to_target()
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, 20.0)
```

- [ ] **Step 4: Create the enemy data**

`data/enemies/intern_reaper.tres`:

```
[gd_resource type="Resource" script_class="EnemyDef" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/content/enemy_def.gd" id="1"]
[ext_resource type="Script" path="res://scripts/actors/behaviors/melee_behavior.gd" id="2"]

[resource]
script = ExtResource("1")
id = "intern_reaper"
display_name = "Intern Reaper"
max_hp = 28.0
speed = 65.0
pension_drop = 4
body_size = Vector2(20, 24)
color = Color(0.23, 0.2, 0.35, 1)
behavior_script = ExtResource("2")
```

`data/enemies/filing_clerk.tres`:

```
[gd_resource type="Resource" script_class="EnemyDef" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/content/enemy_def.gd" id="1"]
[ext_resource type="Script" path="res://scripts/actors/behaviors/thrower_behavior.gd" id="2"]

[resource]
script = ExtResource("1")
id = "filing_clerk"
display_name = "Filing Clerk"
max_hp = 20.0
speed = 50.0
pension_drop = 5
body_size = Vector2(18, 24)
color = Color(0.45, 0.5, 0.56, 1)
behavior_script = ExtResource("2")
```

`data/enemies/debt_ghost.tres`:

```
[gd_resource type="Resource" script_class="EnemyDef" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/content/enemy_def.gd" id="1"]
[ext_resource type="Script" path="res://scripts/actors/behaviors/charger_behavior.gd" id="2"]

[resource]
script = ExtResource("1")
id = "debt_ghost"
display_name = "Debt Collector Ghost"
max_hp = 24.0
speed = 40.0
pension_drop = 5
ignores_walls = true
body_size = Vector2(20, 22)
color = Color(0.4, 0.94, 0.82, 1)
behavior_script = ExtResource("2")
```

- [ ] **Step 5: Add enemy spawning to the sandbox**

Replace all of `scripts/scenes/sandbox.gd`:

```gdscript
extends Node2D

const ROWS := [
	"####################",
	"#..................#",
	"#..................#",
	"#....##......##....#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#....##......##....#",
	"#..................#",
	"#..................#",
	"####################",
]
const SPAWN_KEYS := {
	KEY_1: "intern_reaper",
	KEY_2: "filing_clerk",
	KEY_3: "debt_ghost",
}

var player: Player


func _ready() -> void:
	InputSetup.ensure()
	var backdrop := RoomBackdrop.new()
	backdrop.setup(PackedStringArray(ROWS))
	add_child(backdrop)
	_spawn_player()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	var key: Key = event.physical_keycode
	if SPAWN_KEYS.has(key):
		var def: EnemyDef = load("res://data/enemies/%s.tres" % SPAWN_KEYS[key])
		_spawn_enemy(def, RoomBackdrop.cell_center(Vector2i(16, 5)))


func _spawn_enemy(def: EnemyDef, at: Vector2) -> void:
	var enemy := Enemy.new()
	enemy.setup(def, player, player.run.stats.warning_fraction)
	enemy.position = at
	enemy.summon_requested.connect(_spawn_enemy)
	add_child(enemy)


func _spawn_player() -> void:
	var upgrades: Array[UpgradeDef] = []
	player = Player.new()
	player.setup(RunState.new(upgrades, {}))
	player.position = RoomBackdrop.cell_center(Vector2i(3, 5))
	player.died.connect(_on_player_died)
	add_child(player)


func _on_player_died() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	player.queue_free()
	_spawn_player.call_deferred()
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `powershell -File tools/test.ps1`
Expected: 0 failed.

- [ ] **Step 7: Commit**

```powershell
git add scripts data tests
git commit -m "Add the three regular enemy types" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

**Human checkpoint:** Ask the user to fight enemies in the sandbox with keys 1, 2 and 3, then tune speeds, hit points and timings from their feedback.

---

### Task 8: Mini boss and floor boss

**Files:**
- Create: `scripts/actors/behaviors/mini_boss_behavior.gd`, `scripts/actors/behaviors/floor_boss_behavior.gd`, `data/enemies/senior_adjuster.tres`, `data/enemies/regional_reaper.tres`
- Modify: `scripts/scenes/sandbox.gd`
- Test: `tests/test_bosses.gd`

**Interfaces:**
- Consumes: `Enemy.set_warning`, `Enemy.shoot`, `Enemy.hit_target`, `Enemy.request_summon`, `Telegraph`.
- Produces: `FloorBossBehavior.is_phase_two(hp: float, max_hp: float) -> bool` as a static function on the behavior script, and enemy data files for both bosses.

- [ ] **Step 1: Write the failing test**

`tests/test_bosses.gd`:

```gdscript
extends TestCase

const FloorBossBehavior := preload("res://scripts/actors/behaviors/floor_boss_behavior.gd")


func test_bosses_are_flagged() -> void:
	for id in ["senior_adjuster", "regional_reaper"]:
		var def: EnemyDef = load("res://data/enemies/%s.tres" % id)
		assert_true(def.is_boss, id)
		assert_true(def.max_hp >= 150.0, id)
		assert_true(def.behavior_script.new() is EnemyBehavior, id)


func test_mini_boss_summons_interns() -> void:
	var def: EnemyDef = load("res://data/enemies/senior_adjuster.tres")
	assert_eq(def.summon.id, "intern_reaper")


func test_floor_boss_changes_phase_at_half_health() -> void:
	assert_false(FloorBossBehavior.is_phase_two(51.0, 100.0))
	assert_true(FloorBossBehavior.is_phase_two(50.0, 100.0))
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `powershell -File tools/test.ps1`
Expected: FAIL, reporting that `test_bosses.gd` could not load.

- [ ] **Step 3: Implement**

`scripts/actors/behaviors/mini_boss_behavior.gd`:

```gdscript
extends EnemyBehavior

const SWEEP_RANGE := 64.0
const START_RANGE := 54.0
const WINDUP := 0.8
const COOLDOWN := 1.3
const SUMMON_EVERY := 8.0
const SUMMON_COUNT := 2
const MAX_ENEMIES := 5

var _telegraph := Telegraph.new()
var _cooldown := 1.0
var _summon_timer := SUMMON_EVERY


func tick(enemy: Enemy, delta: float) -> void:
	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = SUMMON_EVERY
		if enemy.get_tree().get_nodes_in_group("enemies").size() < MAX_ENEMIES:
			enemy.request_summon(SUMMON_COUNT)
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = COOLDOWN
			if enemy.distance_to_target() <= SWEEP_RANGE:
				enemy.hit_target(enemy.def.damage)
		return
	_cooldown -= delta
	if enemy.distance_to_target() <= START_RANGE:
		if _cooldown <= 0.0:
			_telegraph.start(WINDUP)
			enemy.set_warning(_telegraph, SWEEP_RANGE)
		return
	enemy.desired_velocity = enemy.direction_to_target() * enemy.def.speed
```

`scripts/actors/behaviors/floor_boss_behavior.gd`:

```gdscript
extends EnemyBehavior

const SWEEP_RANGE := 72.0
const SWEEP_START := 64.0
const SWEEP_WINDUP := 0.8
const FAN_WINDUP := 0.6
const PROJECTILE_SPEED := 120.0
const FAN_SPREAD := 0.35
const BASE_COOLDOWN := 1.4
const PHASE_TWO_COOLDOWN := 0.9
const PHASE_TWO_SPEED := 1.3
const FAN_SHOTS := 5
const PHASE_TWO_SHOTS := 7

enum Attack { NONE, SWEEP, FAN }

var _telegraph := Telegraph.new()
var _cooldown := 1.5
var _attack := Attack.NONE


static func is_phase_two(hp: float, max_hp: float) -> bool:
	return hp <= max_hp * 0.5


func tick(enemy: Enemy, delta: float) -> void:
	var phase_two := is_phase_two(enemy.hp, enemy.def.max_hp)
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy, phase_two)
		return
	_cooldown -= delta
	var distance := enemy.distance_to_target()
	if _cooldown <= 0.0:
		if distance <= SWEEP_START:
			_attack = Attack.SWEEP
			_telegraph.start(SWEEP_WINDUP)
			enemy.set_warning(_telegraph, SWEEP_RANGE)
		else:
			_attack = Attack.FAN
			_telegraph.start(FAN_WINDUP)
			enemy.set_warning(_telegraph, 30.0)
		return
	if distance > SWEEP_START:
		var speed := enemy.def.speed * (PHASE_TWO_SPEED if phase_two else 1.0)
		enemy.desired_velocity = enemy.direction_to_target() * speed


func _finish_attack(enemy: Enemy, phase_two: bool) -> void:
	_cooldown = PHASE_TWO_COOLDOWN if phase_two else BASE_COOLDOWN
	if _attack == Attack.SWEEP:
		if enemy.distance_to_target() <= SWEEP_RANGE:
			enemy.hit_target(enemy.def.damage)
		return
	var shots := PHASE_TWO_SHOTS if phase_two else FAN_SHOTS
	var aim := enemy.direction_to_target()
	for i in shots:
		var offset := (i - (shots - 1) / 2.0) * FAN_SPREAD
		enemy.shoot(aim.rotated(offset), PROJECTILE_SPEED)
```

`data/enemies/senior_adjuster.tres`:

```
[gd_resource type="Resource" script_class="EnemyDef" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/content/enemy_def.gd" id="1"]
[ext_resource type="Script" path="res://scripts/actors/behaviors/mini_boss_behavior.gd" id="2"]
[ext_resource type="Resource" path="res://data/enemies/intern_reaper.tres" id="3"]

[resource]
script = ExtResource("1")
id = "senior_adjuster"
display_name = "Senior Adjuster"
max_hp = 180.0
speed = 55.0
pension_drop = 30
is_boss = true
body_size = Vector2(32, 38)
color = Color(0.5, 0.25, 0.3, 1)
frame_width = 48
behavior_script = ExtResource("2")
summon = ExtResource("3")
```

`data/enemies/regional_reaper.tres`:

```
[gd_resource type="Resource" script_class="EnemyDef" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/content/enemy_def.gd" id="1"]
[ext_resource type="Script" path="res://scripts/actors/behaviors/floor_boss_behavior.gd" id="2"]

[resource]
script = ExtResource("1")
id = "regional_reaper"
display_name = "Regional Reaper"
max_hp = 420.0
speed = 60.0
pension_drop = 60
is_boss = true
body_size = Vector2(40, 48)
color = Color(0.13, 0.1, 0.22, 1)
frame_width = 64
behavior_script = ExtResource("2")
```

- [ ] **Step 4: Add the bosses to the sandbox keys**

In `scripts/scenes/sandbox.gd`, replace the `SPAWN_KEYS` constant:

```gdscript
const SPAWN_KEYS := {
	KEY_1: "intern_reaper",
	KEY_2: "filing_clerk",
	KEY_3: "debt_ghost",
	KEY_4: "senior_adjuster",
	KEY_5: "regional_reaper",
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `powershell -File tools/test.ps1`
Expected: 0 failed.

- [ ] **Step 6: Commit**

```powershell
git add scripts data tests
git commit -m "Add the mini boss and floor boss" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Room layouts

**Files:**
- Create: `scripts/content/room_layout.gd`, `scripts/content/room_catalog.gd`, 17 files in `data/rooms/floor_1/`
- Test: `tests/test_room_layouts.gd`

**Interfaces:**
- Produces:
  - `RoomLayout` Resource: `room_type: String`, `rows: PackedStringArray`, `validate() -> PackedStringArray` of errors, `cells_of(symbol: String) -> Array[Vector2i]`. Constants: `TYPE_COMBAT`, `TYPE_ITEM`, `TYPE_HEALING`, `TYPE_SIDE`, `TYPE_MINI_BOSS`, `TYPE_FLOOR_BOSS`, `WIDTH := 20`, `HEIGHT := 11`, `ENTRY := Vector2i(1, 5)`, `EXIT_A := Vector2i(18, 3)`, `EXIT_B := Vector2i(18, 7)`, `SIDE_DOOR := Vector2i(10, 1)`.
  - `RoomCatalog`: static `load_valid(dir: String) -> Array[RoomLayout]`, which logs and skips broken rooms.
- Symbols: `#` wall, `.` floor, `E` enemy, `I` item pedestal, `H` healing, `T` treasure, `B` boss.

- [ ] **Step 1: Write the failing test**

`tests/test_room_layouts.gd`:

```gdscript
extends TestCase

const DIR := "res://data/rooms/floor_1/"


func _layout(type: String, rows: Array) -> RoomLayout:
	var layout := RoomLayout.new()
	layout.room_type = type
	layout.rows = PackedStringArray(rows)
	return layout


func _open_rows(middle: String) -> Array:
	var rows := ["####################"]
	for y in range(1, 10):
		rows.append(middle if y == 5 else "#..................#")
	rows.append("####################")
	return rows


func test_valid_combat_room_passes() -> void:
	var layout := _layout(RoomLayout.TYPE_COMBAT, _open_rows("#.......E..E.......#"))
	assert_eq(layout.validate().size(), 0)


func test_wrong_size_fails() -> void:
	var layout := _layout(RoomLayout.TYPE_COMBAT, ["###"])
	assert_true(layout.validate().size() > 0)


func test_open_border_fails() -> void:
	var rows := _open_rows("#.......E..E.......#")
	rows[0] = "#########.##########"
	assert_true(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size() > 0)


func test_blocked_entry_fails() -> void:
	var rows := _open_rows("##......E..E.......#")
	assert_true(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size() > 0)


func test_unreachable_enemy_fails() -> void:
	var rows := _open_rows("#.......E..E.......#")
	rows[8] = "#...###............#"
	rows[9] = "#...#E#............#"
	rows[10] = "####################"
	assert_true(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size() > 0)


func test_required_symbols_by_type() -> void:
	var empty := _open_rows("#..................#")
	assert_true(_layout(RoomLayout.TYPE_COMBAT, empty).validate().size() > 0)
	assert_true(_layout(RoomLayout.TYPE_ITEM, empty).validate().size() > 0)
	assert_true(_layout(RoomLayout.TYPE_HEALING, empty).validate().size() > 0)
	assert_true(_layout(RoomLayout.TYPE_SIDE, empty).validate().size() > 0)
	assert_true(_layout(RoomLayout.TYPE_MINI_BOSS, empty).validate().size() > 0)
	assert_true(_layout(RoomLayout.TYPE_FLOOR_BOSS, empty).validate().size() > 0)


func test_unknown_type_fails() -> void:
	assert_true(_layout("spa", _open_rows("#.......E..E.......#")).validate().size() > 0)


func test_all_shipped_rooms_are_valid() -> void:
	var files := DirAccess.get_files_at(DIR)
	var count := 0
	for file in files:
		var name := file.trim_suffix(".remap")
		if not name.ends_with(".tres"):
			continue
		count += 1
		var layout: RoomLayout = load(DIR + name)
		assert_eq(layout.validate().size(), 0, "%s: %s" % [name, str(layout.validate())])
	assert_eq(count, 17)


func test_catalog_meets_the_spec_counts() -> void:
	var counts := {}
	for layout in RoomCatalog.load_valid(DIR):
		counts[layout.room_type] = counts.get(layout.room_type, 0) + 1
	assert_eq(counts.get(RoomLayout.TYPE_COMBAT, 0), 9)
	assert_eq(counts.get(RoomLayout.TYPE_ITEM, 0), 2)
	assert_eq(counts.get(RoomLayout.TYPE_HEALING, 0), 2)
	assert_eq(counts.get(RoomLayout.TYPE_SIDE, 0), 2)
	assert_eq(counts.get(RoomLayout.TYPE_MINI_BOSS, 0), 1)
	assert_eq(counts.get(RoomLayout.TYPE_FLOOR_BOSS, 0), 1)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `powershell -File tools/test.ps1`
Expected: FAIL, reporting that `test_room_layouts.gd` could not load.

- [ ] **Step 3: Implement**

`scripts/content/room_layout.gd`:

```gdscript
class_name RoomLayout
extends Resource

const TYPE_COMBAT := "combat"
const TYPE_ITEM := "item"
const TYPE_HEALING := "healing"
const TYPE_SIDE := "side"
const TYPE_MINI_BOSS := "mini_boss"
const TYPE_FLOOR_BOSS := "floor_boss"
const WIDTH := 20
const HEIGHT := 11
const ENTRY := Vector2i(1, 5)
const EXIT_A := Vector2i(18, 3)
const EXIT_B := Vector2i(18, 7)
const SIDE_DOOR := Vector2i(10, 1)
const ALLOWED := "#.EIHTB"
const REQUIRED := {
	TYPE_COMBAT: {"E": 2},
	TYPE_ITEM: {"I": 2},
	TYPE_HEALING: {"H": 1},
	TYPE_SIDE: {"T": 1},
	TYPE_MINI_BOSS: {"B": 1},
	TYPE_FLOOR_BOSS: {"B": 1},
}

@export var room_type: String = ""
@export var rows: PackedStringArray = []


func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if not REQUIRED.has(room_type):
		errors.append("unknown room type '%s'" % room_type)
		return errors
	if rows.size() != HEIGHT:
		errors.append("expected %d rows" % HEIGHT)
		return errors
	for y in HEIGHT:
		if rows[y].length() != WIDTH:
			errors.append("row %d must have %d cells" % [y, WIDTH])
			return errors
		for x in WIDTH:
			var symbol := rows[y][x]
			if not ALLOWED.contains(symbol):
				errors.append("unknown symbol '%s' at %d,%d" % [symbol, x, y])
			var on_border := x == 0 or y == 0 or x == WIDTH - 1 or y == HEIGHT - 1
			if on_border and symbol != "#":
				errors.append("border must be wall at %d,%d" % [x, y])
	if not errors.is_empty():
		return errors
	var required: Dictionary = REQUIRED[room_type]
	for symbol in required:
		if cells_of(symbol).size() < required[symbol]:
			errors.append("needs at least %d '%s'" % [required[symbol], symbol])
	for anchor in [ENTRY, EXIT_A, EXIT_B, SIDE_DOOR]:
		if rows[anchor.y][anchor.x] != ".":
			errors.append("door cell must be floor at %s" % str(anchor))
	if not errors.is_empty():
		return errors
	var reachable := _flood_from_entry()
	for y in HEIGHT:
		for x in WIDTH:
			var cell := Vector2i(x, y)
			if rows[y][x] != "#" and not reachable.has(cell):
				errors.append("cell cannot be reached at %s" % str(cell))
	return errors


func cells_of(symbol: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in rows.size():
		for x in rows[y].length():
			if rows[y][x] == symbol:
				cells.append(Vector2i(x, y))
	return cells


func _flood_from_entry() -> Dictionary:
	var seen := {ENTRY: true}
	var open: Array[Vector2i] = [ENTRY]
	while not open.is_empty():
		var cell: Vector2i = open.pop_back()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if seen.has(next) or rows[next.y][next.x] == "#":
				continue
			seen[next] = true
			open.append(next)
	return seen
```

`scripts/content/room_catalog.gd`:

```gdscript
class_name RoomCatalog
extends RefCounted


static func load_valid(dir: String) -> Array[RoomLayout]:
	var valid: Array[RoomLayout] = []
	for resource in Content.load_dir(dir):
		if not resource is RoomLayout:
			push_error("Not a room layout: %s" % resource.resource_path)
			continue
		var errors: PackedStringArray = resource.validate()
		if not errors.is_empty():
			push_error("Skipping broken room %s: %s" % [resource.resource_path, ", ".join(errors)])
			continue
		valid.append(resource)
	return valid
```

- [ ] **Step 4: Create the 17 room files**

Every file uses this exact format, with its own type and rows from the list below. The first example is complete.

`data/rooms/floor_1/combat_01.tres`:

```
[gd_resource type="Resource" script_class="RoomLayout" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/content/room_layout.gd" id="1"]

[resource]
script = ExtResource("1")
room_type = "combat"
rows = PackedStringArray(
"####################",
"#..................#",
"#....##......##....#",
"#....##..E...##....#",
"#..................#",
"#.......E..........#",
"#..................#",
"#....##..E...##....#",
"#....##......##....#",
"#..................#",
"####################"
)
```

`combat_02.tres`, `room_type = "combat"`:

```
"####################",
"#..................#",
"#...E..........E...#",
"#..................#",
"#.......####.......#",
"#.......####.......#",
"#.......####.......#",
"#..................#",
"#...E..........E...#",
"#..................#",
"####################"
```

`combat_03.tres`, `room_type = "combat"`:

```
"####################",
"#..................#",
"#..####......####..#",
"#.........E........#",
"#..E...........E...#",
"#..................#",
"#..E...........E...#",
"#.........E........#",
"#..####......####..#",
"#..................#",
"####################"
```

`combat_04.tres`, `room_type = "combat"`:

```
"####################",
"#..................#",
"#..#....#....#..#..#",
"#......E...........#",
"#....#.....#.....E.#",
"#..................#",
"#.E..#.....#.......#",
"#..........E.......#",
"#..#....#....#..#..#",
"#..................#",
"####################"
```

`combat_05.tres`, `room_type = "combat"`:

```
"####################",
"#......#....#......#",
"#......#....#......#",
"#......#.E..#......#",
"#..................#",
"#....E........E....#",
"#..................#",
"#......#..E.#......#",
"#......#....#......#",
"#......#....#......#",
"####################"
```

`combat_06.tres`, `room_type = "combat"`:

```
"####################",
"#..................#",
"#...###......###...#",
"#...#..........#...#",
"#........E.........#",
"#....E........E....#",
"#........E.........#",
"#...#..........#...#",
"#...###......###...#",
"#..................#",
"####################"
```

`combat_07.tres`, `room_type = "combat"`:

```
"####################",
"#..................#",
"#..................#",
"#.....########.....#",
"#.....#..E...#.....#",
"#.E...#......#...E.#",
"#.....#......#.....#",
"#.....###..###.....#",
"#..................#",
"#..................#",
"####################"
```

`combat_08.tres`, `room_type = "combat"`:

```
"####################",
"#..................#",
"#.##############...#",
"#...E.......E......#",
"#..................#",
"#..................#",
"#.......E..........#",
"#..................#",
"#...##############.#",
"#..................#",
"####################"
```

`combat_09.tres`, `room_type = "combat"`:

```
"####################",
"#..................#",
"#..##..............#",
"#.....##.....E.....#",
"#........##........#",
"#..E........##..E..#",
"#.....E............#",
"#.............##...#",
"#..................#",
"#..................#",
"####################"
```

`item_01.tres`, `room_type = "item"`:

```
"####################",
"#..................#",
"#..................#",
"#...###......###...#",
"#..................#",
"#.......I..I.......#",
"#..................#",
"#...###......###...#",
"#..................#",
"#..................#",
"####################"
```

`item_02.tres`, `room_type = "item"`:

```
"####################",
"#..................#",
"#..##..........##..#",
"#..................#",
"#..................#",
"#......I....I......#",
"#..................#",
"#........E.........#",
"#..##..........##..#",
"#..................#",
"####################"
```

`healing_01.tres`, `room_type = "healing"`:

```
"####################",
"#..................#",
"#..................#",
"#.....#......#.....#",
"#..................#",
"#.........H........#",
"#..................#",
"#.....#......#.....#",
"#..................#",
"#..................#",
"####################"
```

`healing_02.tres`, `room_type = "healing"`:

```
"####################",
"#..................#",
"#..................#",
"#.......####.......#",
"#..................#",
"#.........H........#",
"#..................#",
"#.......####.......#",
"#..................#",
"#..................#",
"####################"
```

`side_01.tres`, `room_type = "side"`:

```
"####################",
"#..................#",
"#..####......####..#",
"#..................#",
"#..................#",
"#...E.......T...E..#",
"#..................#",
"#..................#",
"#..####......####..#",
"#..................#",
"####################"
```

`side_02.tres`, `room_type = "side"`:

```
"####################",
"#..................#",
"#..................#",
"#......######......#",
"#..................#",
"#.......E..T.......#",
"#..................#",
"#......######......#",
"#..................#",
"#..................#",
"####################"
```

`mini_boss_01.tres`, `room_type = "mini_boss"`:

```
"####################",
"#..................#",
"#..................#",
"#...##........##...#",
"#..................#",
"#.........B........#",
"#..................#",
"#...##........##...#",
"#..................#",
"#..................#",
"####################"
```

`floor_boss_01.tres`, `room_type = "floor_boss"`:

```
"####################",
"#..................#",
"#..##..........##..#",
"#..................#",
"#..................#",
"#.........B........#",
"#..................#",
"#..................#",
"#..##..........##..#",
"#..................#",
"####################"
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `powershell -File tools/test.ps1`
Expected: 0 failed. If a shipped room fails, the failure message names the file and cell, so fix the layout.

- [ ] **Step 6: Commit**

```powershell
git add scripts data tests
git commit -m "Add room layouts with validation" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Floor builder

**Files:**
- Create: `scripts/content/floor_def.gd`, `scripts/core/floor_room.gd`, `scripts/core/floor_map.gd`, `scripts/core/floor_builder.gd`, `data/floors/floor_1.tres`
- Test: `tests/test_floor_builder.gd`

**Interfaces:**
- Consumes: `RoomLayout`, `RoomCatalog`, `EnemyDef`.
- Produces:
  - `FloorDef` Resource: `id`, `display_name`, `rooms_dir: String`, `enemies: Array` of `EnemyDef`, `mini_boss: EnemyDef`, `floor_boss: EnemyDef`, `clear_pension: int`, `treasure_pension: int`.
  - `FloorRoom`: `id: int`, `layer: int`, `room_type: String`, `layout: RoomLayout`, `exits: Array[int]`, `side_id: int` (-1 for none), `parent_id: int` (-1 for none).
  - `FloorMap`: `rooms: Array[FloorRoom]`, `start_id: int`, `boss_id: int`, `room(id: int) -> FloorRoom`, `main_rooms() -> Array[FloorRoom]`, `reaches_boss_from_everywhere() -> bool`.
  - `FloorBuilder`: static `build(rng: RandomNumberGenerator, pool: Array[RoomLayout]) -> FloorMap`, returning null when a required room type has no layouts.

- [ ] **Step 1: Write the failing test**

`tests/test_floor_builder.gd`:

```gdscript
extends TestCase

const SEEDS := 300


func _pool() -> Array[RoomLayout]:
	return RoomCatalog.load_valid("res://data/rooms/floor_1/")


func _build(seed_value: int, pool: Array[RoomLayout]) -> FloorMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return FloorBuilder.build(rng, pool)


func test_room_count_is_between_10_and_12() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var count := _build(seed_value, pool).main_rooms().size()
		assert_true(count >= 10 and count <= 12, "seed %d had %d rooms" % [seed_value, count])


func test_every_generated_floor_can_be_completed() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		assert_true(map.reaches_boss_from_everywhere(), "seed %d" % seed_value)


func test_exits_are_within_limits() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		for room in map.main_rooms():
			if room.id == map.boss_id:
				assert_eq(room.exits.size(), 0)
			else:
				assert_true(room.exits.size() >= 1 and room.exits.size() <= 2, "seed %d" % seed_value)


func test_every_room_has_a_way_in() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		var entered := {map.start_id: true}
		for room in map.main_rooms():
			for exit_id in room.exits:
				entered[exit_id] = true
		for room in map.main_rooms():
			assert_true(entered.has(room.id), "seed %d room %d" % [seed_value, room.id])


func test_layers_have_one_or_two_rooms() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var widths := {}
		for room in _build(seed_value, pool).main_rooms():
			widths[room.layer] = widths.get(room.layer, 0) + 1
		for layer in widths:
			assert_true(widths[layer] == 1 or widths[layer] == 2, "seed %d" % seed_value)


func test_structure_has_one_mini_boss_and_ends_with_the_floor_boss() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		var mini_bosses := 0
		for room in map.main_rooms():
			if room.room_type == RoomLayout.TYPE_MINI_BOSS:
				mini_bosses += 1
		assert_eq(mini_bosses, 1)
		assert_eq(map.room(map.boss_id).room_type, RoomLayout.TYPE_FLOOR_BOSS)
		assert_eq(map.room(map.start_id).room_type, RoomLayout.TYPE_COMBAT)


func test_layouts_match_room_types() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		for room in _build(seed_value, pool).rooms:
			assert_eq(room.layout.room_type, room.room_type)


func test_side_rooms_hang_off_combat_rooms_and_return() -> void:
	var pool := _pool()
	var found := 0
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		for room in map.rooms:
			if room.side_id == -1:
				continue
			found += 1
			assert_eq(room.room_type, RoomLayout.TYPE_COMBAT)
			var side := map.room(room.side_id)
			assert_eq(side.room_type, RoomLayout.TYPE_SIDE)
			assert_eq(side.parent_id, room.id)
	assert_true(found > 0, "some floors have side rooms")


func test_same_seed_gives_same_floor() -> void:
	var pool := _pool()
	var first := _build(99, pool)
	var second := _build(99, pool)
	assert_eq(first.rooms.size(), second.rooms.size())
	for i in first.rooms.size():
		assert_eq(first.rooms[i].layout, second.rooms[i].layout)
		assert_eq(first.rooms[i].exits, second.rooms[i].exits)


func test_missing_room_type_returns_null() -> void:
	var pool: Array[RoomLayout] = []
	for layout in _pool():
		if layout.room_type != RoomLayout.TYPE_FLOOR_BOSS:
			pool.append(layout)
	assert_true(_build(1, pool) == null)


func test_floor_data_loads() -> void:
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	assert_eq(def.enemies.size(), 3)
	assert_eq(def.mini_boss.id, "senior_adjuster")
	assert_eq(def.floor_boss.id, "regional_reaper")
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `powershell -File tools/test.ps1`
Expected: FAIL, reporting that `test_floor_builder.gd` could not load.

- [ ] **Step 3: Implement**

`scripts/content/floor_def.gd`:

```gdscript
class_name FloorDef
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var rooms_dir: String = ""
@export var enemies: Array = []
@export var mini_boss: EnemyDef
@export var floor_boss: EnemyDef
@export var clear_pension: int = 8
@export var treasure_pension: int = 25
```

`scripts/core/floor_room.gd`:

```gdscript
class_name FloorRoom
extends RefCounted

var id: int = 0
var layer: int = 0
var room_type: String = ""
var layout: RoomLayout
var exits: Array[int] = []
var side_id: int = -1
var parent_id: int = -1
```

`scripts/core/floor_map.gd`:

```gdscript
class_name FloorMap
extends RefCounted

var rooms: Array[FloorRoom] = []
var start_id: int = 0
var boss_id: int = 0


func room(id: int) -> FloorRoom:
	return rooms[id]


func main_rooms() -> Array[FloorRoom]:
	var list: Array[FloorRoom] = []
	for candidate in rooms:
		if candidate.room_type != RoomLayout.TYPE_SIDE:
			list.append(candidate)
	return list


func reaches_boss_from_everywhere() -> bool:
	var from_start := _walk(start_id)
	for candidate in main_rooms():
		if not from_start.has(candidate.id):
			return false
		if not _walk(candidate.id).has(boss_id):
			return false
	return true


func _walk(from_id: int) -> Dictionary:
	var seen := {from_id: true}
	var open: Array[int] = [from_id]
	while not open.is_empty():
		for exit_id in room(open.pop_back()).exits:
			if not seen.has(exit_id):
				seen[exit_id] = true
				open.append(exit_id)
	return seen
```

`scripts/core/floor_builder.gd`:

```gdscript
class_name FloorBuilder
extends RefCounted

const SIDE_CHANCE := 0.3
const SECOND_ROOM_TYPES := [
	RoomLayout.TYPE_ITEM,
	RoomLayout.TYPE_ITEM,
	RoomLayout.TYPE_HEALING,
	RoomLayout.TYPE_COMBAT,
]


static func build(rng: RandomNumberGenerator, pool: Array[RoomLayout]) -> FloorMap:
	var by_type := {}
	for layout in pool:
		if not by_type.has(layout.room_type):
			by_type[layout.room_type] = []
		by_type[layout.room_type].append(layout)
	var picker := _LayoutPicker.new(by_type, rng)
	var map := FloorMap.new()
	var layers := _plan_layers(rng)
	var previous: Array[FloorRoom] = []
	for layer_index in layers.size():
		var current: Array[FloorRoom] = []
		for room_type: String in layers[layer_index]:
			var layout := picker.pick(room_type)
			if layout == null:
				push_error("No valid layouts for room type: %s" % room_type)
				return null
			current.append(_add_room(map, layer_index, room_type, layout))
		_connect(previous, current, rng)
		previous = current
	map.start_id = 0
	map.boss_id = previous[0].id
	_attach_side_rooms(map, picker, rng)
	return map


static func _plan_layers(rng: RandomNumberGenerator) -> Array:
	var combat := RoomLayout.TYPE_COMBAT
	var first_item := [combat, RoomLayout.TYPE_ITEM]
	return [
		[combat],
		first_item,
		_open_layer(rng),
		[RoomLayout.TYPE_MINI_BOSS],
		[combat, SECOND_ROOM_TYPES[rng.randi_range(0, SECOND_ROOM_TYPES.size() - 1)]],
		_open_layer(rng),
		[RoomLayout.TYPE_HEALING],
		[RoomLayout.TYPE_FLOOR_BOSS],
	]


static func _open_layer(rng: RandomNumberGenerator) -> Array:
	if rng.randf() < 0.5:
		return [RoomLayout.TYPE_COMBAT]
	return [RoomLayout.TYPE_COMBAT, SECOND_ROOM_TYPES[rng.randi_range(0, SECOND_ROOM_TYPES.size() - 1)]]


static func _add_room(map: FloorMap, layer: int, room_type: String, layout: RoomLayout) -> FloorRoom:
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.layer = layer
	room.room_type = room_type
	room.layout = layout
	map.rooms.append(room)
	return room


static func _connect(from_rooms: Array[FloorRoom], to_rooms: Array[FloorRoom], rng: RandomNumberGenerator) -> void:
	if from_rooms.is_empty():
		return
	if from_rooms.size() == 2 and to_rooms.size() == 2:
		from_rooms[0].exits.append(to_rooms[0].id)
		from_rooms[1].exits.append(to_rooms[1].id)
		var crossing := from_rooms[rng.randi_range(0, 1)]
		var other := to_rooms[0].id if crossing == from_rooms[1] else to_rooms[1].id
		crossing.exits.append(other)
		return
	for from_room in from_rooms:
		for to_room in to_rooms:
			from_room.exits.append(to_room.id)


static func _attach_side_rooms(map: FloorMap, picker: _LayoutPicker, rng: RandomNumberGenerator) -> void:
	for room in map.main_rooms():
		if room.room_type != RoomLayout.TYPE_COMBAT or rng.randf() >= SIDE_CHANCE:
			continue
		var layout := picker.pick(RoomLayout.TYPE_SIDE)
		if layout == null:
			continue
		var side := _add_room(map, room.layer, RoomLayout.TYPE_SIDE, layout)
		side.parent_id = room.id
		room.side_id = side.id


class _LayoutPicker:
	var _by_type: Dictionary
	var _rng: RandomNumberGenerator
	var _remaining := {}

	func _init(by_type: Dictionary, rng: RandomNumberGenerator) -> void:
		_by_type = by_type
		_rng = rng

	func pick(room_type: String) -> RoomLayout:
		if not _by_type.has(room_type):
			return null
		if _remaining.get(room_type, []).is_empty():
			_remaining[room_type] = _by_type[room_type].duplicate()
		var options: Array = _remaining[room_type]
		var index := _rng.randi_range(0, options.size() - 1)
		var layout: RoomLayout = options[index]
		options.remove_at(index)
		return layout
```

`data/floors/floor_1.tres`:

```
[gd_resource type="Resource" script_class="FloorDef" load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/content/floor_def.gd" id="1"]
[ext_resource type="Resource" path="res://data/enemies/intern_reaper.tres" id="2"]
[ext_resource type="Resource" path="res://data/enemies/filing_clerk.tres" id="3"]
[ext_resource type="Resource" path="res://data/enemies/debt_ghost.tres" id="4"]
[ext_resource type="Resource" path="res://data/enemies/senior_adjuster.tres" id="5"]
[ext_resource type="Resource" path="res://data/enemies/regional_reaper.tres" id="6"]

[resource]
script = ExtResource("1")
id = "floor_1"
display_name = "Claims Department"
rooms_dir = "res://data/rooms/floor_1/"
enemies = [ExtResource("2"), ExtResource("3"), ExtResource("4")]
mini_boss = ExtResource("5")
floor_boss = ExtResource("6")
clear_pension = 8
treasure_pension = 25
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `powershell -File tools/test.ps1`
Expected: 0 failed.

- [ ] **Step 5: Commit**

```powershell
git add scripts data tests
git commit -m "Add branching floor builder" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11: Room view, doors, rewards and lighting

**Files:**
- Create: `scripts/world/room_rules.gd`, `scripts/world/door.gd`, `scripts/world/pickup.gd`, `scripts/world/lighting.gd`, `scripts/world/room_view.gd`, `scripts/ui/hud.gd`
- Test: `tests/test_room_rules.gd`

**Interfaces:**
- Consumes: `FloorRoom`, `FloorMap`, `FloorDef`, `RoomLayout`, `RoomBackdrop`, `Enemy`, `RunState`, `Content.items`.
- Produces:
  - `RoomRules`: static `door_icon(room_type: String) -> String`, `pick_items(all: Array[ItemDef], run: RunState, count: int, rng: RandomNumberGenerator) -> Array[ItemDef]`. Class lives in `scripts/world/room_rules.gd`.
  - `Door` Node2D: `setup(target_id: int, icon: String, player: Node2D)`, `locked: bool`, signal `entered(target_id: int)`.
  - `Pickup` Node2D: `setup(label: String, color: Color, player: Node2D)`, signal `collected`, `collect()`, group `pickups`.
  - `Lighting`: static `make_light(color: Color, energy: float, scale_factor: float) -> PointLight2D`, `add_room_mood(parent: Node)`.
  - `RoomView` Node2D: `setup(room: FloorRoom, map: FloorMap, floor_def: FloorDef, run: RunState, player: Player, rng: RandomNumberGenerator, already_cleared: bool, side_open: bool)`, signals `door_entered(target_id: int)`, `floor_cleared`, `pension_earned(amount: int)`, `room_finished(room_id: int)`.
  - `Hud` CanvasLayer: `setup(run: RunState)` with null allowed, `set_pension(amount: int)`, `show_message(text: String)`.

- [ ] **Step 1: Write the failing test**

`tests/test_room_rules.gd`:

```gdscript
extends TestCase


func _run() -> RunState:
	var upgrades: Array[UpgradeDef] = []
	return RunState.new(upgrades, {})


func _item(id: String) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	return item


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return rng


func test_door_icons_cover_all_room_types() -> void:
	assert_eq(RoomRules.door_icon(RoomLayout.TYPE_COMBAT), "C")
	assert_eq(RoomRules.door_icon(RoomLayout.TYPE_ITEM), "I")
	assert_eq(RoomRules.door_icon(RoomLayout.TYPE_HEALING), "H")
	assert_eq(RoomRules.door_icon(RoomLayout.TYPE_SIDE), "?")
	assert_eq(RoomRules.door_icon(RoomLayout.TYPE_MINI_BOSS), "M")
	assert_eq(RoomRules.door_icon(RoomLayout.TYPE_FLOOR_BOSS), "B")


func test_pick_items_skips_owned_items() -> void:
	var run := _run()
	var owned := _item("owned")
	run.add_item(owned)
	var all: Array[ItemDef] = [owned, _item("a"), _item("b")]
	var picked := RoomRules.pick_items(all, run, 2, _rng())
	assert_eq(picked.size(), 2)
	for item in picked:
		assert_true(item.id != "owned")


func test_pick_items_gives_distinct_items() -> void:
	var all: Array[ItemDef] = [_item("a"), _item("b"), _item("c")]
	var picked := RoomRules.pick_items(all, _run(), 2, _rng())
	assert_true(picked[0].id != picked[1].id)


func test_pick_items_returns_fewer_when_running_out() -> void:
	var run := _run()
	var only := _item("only")
	run.add_item(only)
	var all: Array[ItemDef] = [only, _item("last")]
	assert_eq(RoomRules.pick_items(all, run, 2, _rng()).size(), 1)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `powershell -File tools/test.ps1`
Expected: FAIL, reporting that `test_room_rules.gd` could not load.

- [ ] **Step 3: Implement**

`scripts/world/room_rules.gd`:

```gdscript
class_name RoomRules
extends RefCounted

const ICONS := {
	RoomLayout.TYPE_COMBAT: "C",
	RoomLayout.TYPE_ITEM: "I",
	RoomLayout.TYPE_HEALING: "H",
	RoomLayout.TYPE_SIDE: "?",
	RoomLayout.TYPE_MINI_BOSS: "M",
	RoomLayout.TYPE_FLOOR_BOSS: "B",
}


static func door_icon(room_type: String) -> String:
	return ICONS.get(room_type, "<")


static func pick_items(all: Array[ItemDef], run: RunState, count: int, rng: RandomNumberGenerator) -> Array[ItemDef]:
	var options: Array[ItemDef] = []
	for item in all:
		if not run.has_item(item.id):
			options.append(item)
	var picked: Array[ItemDef] = []
	while picked.size() < count and not options.is_empty():
		var index := rng.randi_range(0, options.size() - 1)
		picked.append(options[index])
		options.remove_at(index)
	return picked
```

`scripts/world/door.gd`:

```gdscript
class_name Door
extends Node2D

signal entered(target_id: int)

const ENTER_RADIUS := 18.0

var locked := true
var _target_id := -1
var _icon := "?"
var _player: Node2D
var _used := false


func setup(target_id: int, icon: String, player: Node2D) -> void:
	_target_id = target_id
	_icon = icon
	_player = player


func _process(_delta: float) -> void:
	queue_redraw()
	if locked or _used or not is_instance_valid(_player):
		return
	if global_position.distance_to(_player.global_position) <= ENTER_RADIUS:
		_used = true
		entered.emit(_target_id)


func _draw() -> void:
	var color := Color("7a3b3b") if locked else Color("c98a3c")
	draw_rect(Rect2(-14, -14, 28, 28), color)
	draw_rect(Rect2(-14, -14, 28, 28), Color.BLACK, false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-5, 6), _icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
```

`scripts/world/pickup.gd`:

```gdscript
class_name Pickup
extends Node2D

signal collected

const COLLECT_RADIUS := 18.0

var _label := ""
var _color := Color.WHITE
var _player: Node2D
var _done := false


func setup(label: String, color: Color, player: Node2D) -> void:
	_label = label
	_color = color
	_player = player


func _ready() -> void:
	add_to_group("pickups")
	queue_redraw()


func _process(_delta: float) -> void:
	if _done or not is_instance_valid(_player):
		return
	if global_position.distance_to(_player.global_position) <= COLLECT_RADIUS:
		collect()


func collect() -> void:
	if _done:
		return
	_done = true
	collected.emit()
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, _color)
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 16, Color.BLACK, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-18, -12), _label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
```

`scripts/world/lighting.gd`:

```gdscript
class_name Lighting
extends RefCounted

const AMBIENT := Color(0.32, 0.32, 0.48)
const TORCH := Color(1.0, 0.62, 0.3)
const TORCH_CELLS: Array[Vector2i] = [Vector2i(4, 0), Vector2i(15, 0), Vector2i(4, 10), Vector2i(15, 10)]


static func make_light(color: Color, energy: float, scale_factor: float) -> PointLight2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var light := PointLight2D.new()
	light.texture = texture
	light.color = color
	light.energy = energy
	light.texture_scale = scale_factor
	return light


static func add_room_mood(parent: Node) -> void:
	var modulate := CanvasModulate.new()
	modulate.color = AMBIENT
	parent.add_child(modulate)
	for cell in TORCH_CELLS:
		var light := make_light(TORCH, 1.0, 1.6)
		light.position = RoomBackdrop.cell_center(cell)
		parent.add_child(light)
```

`scripts/world/room_view.gd`:

```gdscript
class_name RoomView
extends Node2D

signal door_entered(target_id: int)
signal floor_cleared
signal pension_earned(amount: int)
signal room_finished(room_id: int)

const HEAL_AMOUNT := 2
const PENSION_COLOR := Color("ffd24a")
const ITEM_COLOR := Color("7dd3fc")
const HEAL_COLOR := Color("e4524f")
const COIN_SCATTER := 10.0

var _room: FloorRoom
var _map: FloorMap
var _floor_def: FloorDef
var _run: RunState
var _player: Player
var _rng: RandomNumberGenerator
var _already_cleared := false
var _side_open := false
var _alive := 0
var _finished := false
var _doors: Array[Door] = []
var _coins: Array[Pickup] = []


func setup(room: FloorRoom, map: FloorMap, floor_def: FloorDef, run: RunState, player: Player, rng: RandomNumberGenerator, already_cleared: bool, side_open: bool) -> void:
	_room = room
	_map = map
	_floor_def = floor_def
	_run = run
	_player = player
	_rng = rng
	_already_cleared = already_cleared
	_side_open = side_open


func _ready() -> void:
	var backdrop := RoomBackdrop.new()
	backdrop.setup(_room.layout.rows)
	add_child(backdrop)
	Lighting.add_room_mood(self)
	_create_doors()
	if not _already_cleared:
		_create_rewards()
		_spawn_enemies()
	if _alive == 0:
		_finish_room()


func _create_doors() -> void:
	if _room.room_type == RoomLayout.TYPE_SIDE:
		_add_door(_room.parent_id, "<", RoomLayout.EXIT_A)
	else:
		var cells := [RoomLayout.EXIT_A, RoomLayout.EXIT_B]
		for i in _room.exits.size():
			var target := _map.room(_room.exits[i])
			_add_door(target.id, RoomRules.door_icon(target.room_type), cells[i])
		if _room.side_id != -1 and _side_open:
			_add_door(_room.side_id, RoomRules.door_icon(RoomLayout.TYPE_SIDE), RoomLayout.SIDE_DOOR)


func _add_door(target_id: int, icon: String, cell: Vector2i) -> void:
	var door := Door.new()
	door.setup(target_id, icon, _player)
	door.position = RoomBackdrop.cell_center(cell)
	door.entered.connect(func(id: int): door_entered.emit(id))
	add_child(door)
	_doors.append(door)


func _spawn_enemies() -> void:
	for cell in _room.layout.cells_of("E"):
		var options := _floor_def.enemies
		var def: EnemyDef = options[_rng.randi_range(0, options.size() - 1)]
		_spawn_enemy(def, RoomBackdrop.cell_center(cell))
	for cell in _room.layout.cells_of("B"):
		var boss := _floor_def.mini_boss if _room.room_type == RoomLayout.TYPE_MINI_BOSS else _floor_def.floor_boss
		_spawn_enemy(boss, RoomBackdrop.cell_center(cell))


func _spawn_enemy(def: EnemyDef, at: Vector2) -> void:
	var enemy := Enemy.new()
	enemy.setup(def, _player, _run.stats.warning_fraction)
	enemy.position = at
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.summon_requested.connect(_spawn_enemy)
	_alive += 1
	add_child(enemy)


func _on_enemy_defeated(enemy: Enemy) -> void:
	_alive -= 1
	_drop_coin(enemy.position, enemy.def.pension_drop)
	if enemy.def.is_boss:
		for other in get_tree().get_nodes_in_group("enemies"):
			if other != enemy and other.get_parent() == self:
				other.take_damage(INF, Vector2.ZERO)
	if _alive == 0:
		_finish_room()


func _drop_coin(at: Vector2, base_amount: int) -> void:
	var amount := _run.pension_amount(base_amount)
	var coin := _add_pickup(at + Vector2(_rng.randf_range(-COIN_SCATTER, COIN_SCATTER), _rng.randf_range(-COIN_SCATTER, COIN_SCATTER)), "+%d" % amount, PENSION_COLOR, func(): pension_earned.emit(amount))
	_coins.append(coin)


func _add_pickup(at: Vector2, label: String, color: Color, on_take: Callable) -> Pickup:
	var pickup := Pickup.new()
	pickup.setup(label, color, _player)
	pickup.position = at
	pickup.collected.connect(on_take)
	add_child(pickup)
	return pickup


func _create_rewards() -> void:
	var cells := _room.layout.cells_of("I")
	if not cells.is_empty():
		_create_item_choice(cells)
	for cell in _room.layout.cells_of("H"):
		_add_pickup(RoomBackdrop.cell_center(cell), "Heal", HEAL_COLOR, func(): _run.health.heal(HEAL_AMOUNT))
	for cell in _room.layout.cells_of("T"):
		_create_treasure(cell)


func _create_item_choice(cells: Array[Vector2i]) -> void:
	var picked := RoomRules.pick_items(Content.items(), _run, cells.size(), _rng)
	var choices: Array[Pickup] = []
	for i in picked.size():
		var item := picked[i]
		var choice := _add_pickup(RoomBackdrop.cell_center(cells[i]), item.display_name, ITEM_COLOR, func(): _run.add_item(item))
		choices.append(choice)
	for choice in choices:
		choice.collected.connect(func(): _remove_others(choices, choice))
	if picked.is_empty():
		_drop_coin(RoomBackdrop.cell_center(cells[0]), _floor_def.treasure_pension)


func _remove_others(choices: Array[Pickup], taken: Pickup) -> void:
	for choice in choices:
		if choice != taken and is_instance_valid(choice):
			choice.queue_free()


func _create_treasure(cell: Vector2i) -> void:
	var picked := RoomRules.pick_items(Content.items(), _run, 1, _rng)
	if picked.is_empty() or _rng.randf() < 0.5:
		_drop_coin(RoomBackdrop.cell_center(cell), _floor_def.treasure_pension)
		return
	var item := picked[0]
	_add_pickup(RoomBackdrop.cell_center(cell), item.display_name, ITEM_COLOR, func(): _run.add_item(item))


func _finish_room() -> void:
	if _finished:
		return
	_finished = true
	for door in _doors:
		door.locked = false
	for coin in _coins:
		if is_instance_valid(coin):
			coin.collect()
	if not _already_cleared and _room.room_type in [RoomLayout.TYPE_COMBAT, RoomLayout.TYPE_MINI_BOSS, RoomLayout.TYPE_SIDE]:
		pension_earned.emit(_run.pension_amount(_floor_def.clear_pension))
	room_finished.emit(_room.id)
	if _room.room_type == RoomLayout.TYPE_FLOOR_BOSS:
		floor_cleared.emit()
```

`scripts/ui/hud.gd`:

```gdscript
class_name Hud
extends CanvasLayer

var _run: RunState
var _status: Label
var _items: Label
var _message: Label
var _pension := 0


func setup(run: RunState) -> void:
	_run = run


func _ready() -> void:
	_status = _add_label(Vector2(8, 4), 12)
	_items = _add_label(Vector2(8, 340), 9)
	_message = _add_label(Vector2(0, 150), 20)
	_message.size = Vector2(640, 40)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _run != null:
		_run.changed.connect(_refresh)
	_refresh()


func set_pension(amount: int) -> void:
	_pension = amount
	if _status != null:
		_refresh()


func show_message(text: String) -> void:
	_message.text = text


func _add_label(at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	add_child(label)
	return label


func _refresh() -> void:
	var text := "Pension: %d" % _pension
	if _run != null:
		var pills := "■".repeat(_run.health.pills) + "□".repeat(_run.health.max_pills - _run.health.pills)
		text = "Pills: %s   %s" % [pills, text]
		var names: PackedStringArray = []
		for item in _run.items:
			names.append(item.display_name)
		_items.text = ", ".join(names)
	_status.text = text
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `powershell -File tools/test.ps1`
Expected: 0 failed.

- [ ] **Step 5: Commit**

```powershell
git add scripts tests
git commit -m "Add room view with doors, rewards, lighting and HUD" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

The room view is exercised end to end by the full-loop check in Task 13.

---

### Task 12: Scenes, autoloads and merchant

**Files:**
- Create: `scripts/autoload/progress.gd`, `scripts/autoload/game.gd`, `scripts/scenes/boot.gd`, `scripts/scenes/opening.gd`, `scripts/scenes/waiting_room.gd`, `scripts/scenes/floor_scene.gd`, `scripts/ui/merchant_panel.gd`, `scenes/boot.tscn`, `scenes/opening.tscn`, `scenes/waiting_room.tscn`, `scenes/floor.tscn`
- Modify: `project.godot`
- Test: covered by the launch check here and the full-loop check in Task 13

**Interfaces:**
- Consumes: everything above.
- Produces:
  - Autoload `Progress`: `data: ProgressData`, `notice: String`, signal `pension_changed(amount: int)`, `reload()`, `add_pension(amount: int)`, `buy(def: UpgradeDef) -> bool`, `mark_opening_seen()`, `make_run() -> RunState`.
  - Autoload `Game`: `start()`, `finish_opening()`, `begin_run()`, `return_to_waiting()`.
  - Floor scene root: `player: Player`, `is_cleared: bool`, `is_over: bool`, `debug_take_first_exit()`, constant `MESSAGE_TIME`. Root node names are `Opening`, `WaitingRoom` and `FloorScene`.

- [ ] **Step 1: Implement the autoloads**

`scripts/autoload/progress.gd`:

```gdscript
extends Node

signal pension_changed(amount: int)

const SAVE_PATH := "user://save.json"
const SMOKE_PATH := "user://smoke_save.json"

var data: ProgressData
var notice := ""
var _store: SaveStore


func _ready() -> void:
	var smoke := OS.get_cmdline_user_args().has("--smoke")
	_store = SaveStore.new(SMOKE_PATH if smoke else SAVE_PATH)
	if smoke:
		_store.delete_all()
	reload()


func reload() -> void:
	data = _store.load_progress()
	notice = ""
	if _store.last_status == SaveStore.STATUS_BACKUP:
		notice = "Your save was damaged, so a backup was restored."
	elif _store.last_status == SaveStore.STATUS_RESET:
		notice = "Your save was damaged and could not be recovered. Starting fresh."
	pension_changed.emit(data.pension)


func add_pension(amount: int) -> void:
	data.add_pension(amount)
	_store.save_progress(data)
	pension_changed.emit(data.pension)


func buy(def: UpgradeDef) -> bool:
	if not data.buy(def):
		return false
	_store.save_progress(data)
	pension_changed.emit(data.pension)
	return true


func mark_opening_seen() -> void:
	data.opening_seen = true
	_store.save_progress(data)


func make_run() -> RunState:
	return RunState.new(Content.upgrades(), data.upgrades)
```

`scripts/autoload/game.gd`:

```gdscript
extends Node

const OPENING_SCENE := "res://scenes/opening.tscn"
const WAITING_SCENE := "res://scenes/waiting_room.tscn"
const FLOOR_SCENE := "res://scenes/floor.tscn"


func _ready() -> void:
	InputSetup.ensure()
	if OS.get_cmdline_user_args().has("--smoke"):
		var driver: Node = load("res://tools/smoke_driver.gd").new()
		add_child(driver)


func start() -> void:
	if Progress.data.opening_seen:
		return_to_waiting()
	else:
		get_tree().change_scene_to_file(OPENING_SCENE)


func finish_opening() -> void:
	Progress.mark_opening_seen()
	return_to_waiting()


func begin_run() -> void:
	get_tree().change_scene_to_file(FLOOR_SCENE)


func return_to_waiting() -> void:
	get_tree().change_scene_to_file(WAITING_SCENE)
```

Add to `project.godot`, after the `[application]` section. Also add `run/main_scene` to `[application]`:

```ini
run/main_scene="res://scenes/boot.tscn"

[autoload]

Progress="*res://scripts/autoload/progress.gd"
Game="*res://scripts/autoload/game.gd"
```

- [ ] **Step 2: Implement the scene scripts**

`scripts/scenes/boot.gd`:

```gdscript
extends Node


func _ready() -> void:
	Game.start.call_deferred()
```

`scripts/scenes/opening.gd`:

```gdscript
extends Node2D

const LINES := [
	"Harold, 87. Cause of death: stairs.",
	"\"Welcome to the afterlife. Please take a number.\"",
	"\"I'm not dead.\"",
	"\"Sir, you are extremely dead.\"",
	"\"I have a 40-year feud with my neighbor to finish.\"",
	"\"That's not how this works.\"",
	"He picks up his cane.",
]

var _index := 0
var _label: Label


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var background := ColorRect.new()
	background.color = Color("100e14")
	background.size = Vector2(640, 360)
	layer.add_child(background)
	_label = Label.new()
	_label.position = Vector2(40, 150)
	_label.size = Vector2(560, 60)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	layer.add_child(_label)
	_label.text = LINES[0]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") or event.is_action_pressed("dodge") or event.is_action_pressed("interact"):
		_index += 1
		if _index >= LINES.size():
			Game.finish_opening()
		else:
			_label.text = LINES[_index]
```

`scripts/ui/merchant_panel.gd`:

```gdscript
class_name MerchantPanel
extends CanvasLayer

signal closed

var _list: VBoxContainer


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(100, 40)
	panel.custom_minimum_size = Vector2(440, 260)
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = "Black Market. You didn't see me."
	column.add_child(title)
	_list = VBoxContainer.new()
	column.add_child(_list)
	var close := Button.new()
	close.text = "Leave"
	close.pressed.connect(func(): closed.emit())
	column.add_child(close)
	_rebuild()


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	for def in Content.upgrades():
		var button := Button.new()
		var level := Progress.data.level_of(def.id)
		var price := def.price_at(level)
		var cost_text := "SOLD OUT" if price < 0 else "%d Pension" % price
		button.text = "%s  Lv %d/%d  %s" % [def.display_name, level, def.max_level(), cost_text]
		button.tooltip_text = def.description
		button.disabled = not Progress.data.can_buy(def)
		button.pressed.connect(_buy.bind(def))
		_list.add_child(button)


func _buy(def: UpgradeDef) -> void:
	if Progress.buy(def):
		_rebuild()
```

`scripts/scenes/waiting_room.gd`:

```gdscript
extends Node2D

const ROWS := [
	"####################",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"####################",
]
const MERCHANT_CELL := Vector2i(5, 3)
const DOOR_CELL := Vector2i(18, 5)
const INTERACT_RANGE := 48.0

var player: Player
var _hud: Hud
var _merchant_position := Vector2.ZERO
var _panel: MerchantPanel


func _ready() -> void:
	var backdrop := RoomBackdrop.new()
	backdrop.setup(PackedStringArray(ROWS))
	add_child(backdrop)
	Lighting.add_room_mood(self)
	_merchant_position = RoomBackdrop.cell_center(MERCHANT_CELL)
	var merchant := SpriteVisual.new()
	merchant.position = _merchant_position
	add_child(merchant)
	merchant.setup("merchant", Vector2(22, 30), Color("8a4fbf"), 32)
	player = Player.new()
	player.setup(Progress.make_run())
	player.position = RoomBackdrop.cell_center(Vector2i(3, 5))
	add_child(player)
	var door := Door.new()
	door.setup(0, ">", player)
	door.locked = false
	door.position = RoomBackdrop.cell_center(DOOR_CELL)
	door.entered.connect(func(_id: int): Game.begin_run())
	add_child(door)
	_hud = Hud.new()
	_hud.setup(null)
	add_child(_hud)
	_hud.set_pension(Progress.data.pension)
	Progress.pension_changed.connect(_hud.set_pension)
	_hud.show_message(Progress.notice)
	Progress.notice = ""


func _process(_delta: float) -> void:
	queue_redraw()
	if _panel == null and Input.is_action_just_pressed("interact") and player.global_position.distance_to(_merchant_position) <= INTERACT_RANGE:
		_open_panel()


func _open_panel() -> void:
	_panel = MerchantPanel.new()
	_panel.closed.connect(_close_panel)
	add_child(_panel)
	player.set_physics_process(false)
	_hud.show_message("")


func _close_panel() -> void:
	_panel.queue_free()
	_panel = null
	player.set_physics_process(true)


func _draw() -> void:
	if _panel == null and player != null and player.global_position.distance_to(_merchant_position) <= INTERACT_RANGE:
		draw_string(ThemeDB.fallback_font, _merchant_position + Vector2(-30, -24), "E: Trade", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(240, 24), "NOW SERVING: 666", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("e4524f"))
```

`scripts/scenes/floor_scene.gd`:

```gdscript
extends Node2D

const FLOOR_PATH := "res://data/floors/floor_1.tres"
const MESSAGE_TIME := 2.0

var player: Player
var is_cleared := false
var is_over := false
var _map: FloorMap
var _floor_def: FloorDef
var _run: RunState
var _rng := RandomNumberGenerator.new()
var _room_view: RoomView
var _current_id := -1
var _finished_rooms := {}
var _used_sides := {}
var _hud: Hud


func _ready() -> void:
	_rng.randomize()
	_run = Progress.make_run()
	_hud = Hud.new()
	_hud.setup(_run)
	add_child(_hud)
	_hud.set_pension(Progress.data.pension)
	Progress.pension_changed.connect(_hud.set_pension)
	_floor_def = load(FLOOR_PATH)
	_map = FloorBuilder.build(_rng, RoomCatalog.load_valid(_floor_def.rooms_dir))
	if _map == null:
		_end_run("This floor could not be built. Returning to the Waiting Room.")
		return
	player = Player.new()
	player.setup(_run)
	player.died.connect(_on_player_died)
	add_child(player)
	var glow := Lighting.make_light(Color(1.0, 0.85, 0.6), 0.7, 0.8)
	player.add_child(glow)
	_enter_room(_map.start_id)


func debug_take_first_exit() -> void:
	var room := _map.room(_current_id)
	if room.room_type == RoomLayout.TYPE_SIDE:
		_enter_room(room.parent_id)
	elif not room.exits.is_empty():
		_enter_room(room.exits[0])


func _enter_room(target_id: int) -> void:
	var from_side := _current_id != -1 and _map.room(_current_id).room_type == RoomLayout.TYPE_SIDE
	if _room_view != null:
		_room_view.queue_free()
	var room := _map.room(target_id)
	if room.room_type == RoomLayout.TYPE_SIDE:
		_used_sides[room.parent_id] = true
	_current_id = target_id
	_room_view = RoomView.new()
	_room_view.setup(room, _map, _floor_def, _run, player, _rng, _finished_rooms.has(target_id), not _used_sides.has(target_id))
	_room_view.door_entered.connect(func(id: int): _enter_room.call_deferred(id))
	_room_view.pension_earned.connect(func(amount: int): Progress.add_pension(amount))
	_room_view.room_finished.connect(func(id: int): _finished_rooms[id] = true)
	_room_view.floor_cleared.connect(_on_floor_cleared)
	add_child(_room_view)
	move_child(_room_view, 0)
	var entry := RoomLayout.SIDE_DOOR if from_side else RoomLayout.ENTRY
	player.global_position = RoomBackdrop.cell_center(entry)


func _on_player_died() -> void:
	_end_run("You died again. Please take a number.")


func _on_floor_cleared() -> void:
	is_cleared = true
	_end_run("FLOOR CLEARED")


func _end_run(message: String) -> void:
	if is_over:
		return
	is_over = true
	_hud.show_message(message)
	if player != null:
		player.process_mode = Node.PROCESS_MODE_DISABLED
	if _room_view != null:
		_room_view.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().create_timer(MESSAGE_TIME).timeout
	Game.return_to_waiting()
```

- [ ] **Step 3: Create the scenes**

`scenes/boot.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/scenes/boot.gd" id="1"]

[node name="Boot" type="Node"]
script = ExtResource("1")
```

`scenes/opening.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/scenes/opening.gd" id="1"]

[node name="Opening" type="Node2D"]
script = ExtResource("1")
```

`scenes/waiting_room.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/scenes/waiting_room.gd" id="1"]

[node name="WaitingRoom" type="Node2D"]
script = ExtResource("1")
```

`scenes/floor.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/scenes/floor_scene.gd" id="1"]

[node name="FloorScene" type="Node2D"]
script = ExtResource("1")
```

- [ ] **Step 4: Verify the tests still pass and the game launches**

Run: `powershell -File tools/test.ps1`
Expected: 0 failed. If a test now fails because the runner loads scripts that reference autoloads, keep those scripts out of the test files.

Run:

```powershell
$godot = if ($env:GODOT) { $env:GODOT } else { "D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
& $godot --headless --path C:\GameDev\game --quit-after 120
```

Expected: exits with no `SCRIPT ERROR` or `Parse Error` lines. This run may create a save only if something calls `Progress.add_pension`, which the opening does not.

- [ ] **Step 5: Commit**

```powershell
git add project.godot scripts scenes
git commit -m "Add game flow, Waiting Room, merchant and floor scene" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 13: Automated full-loop check

**Files:**
- Create: `tools/smoke_driver.gd`, `tools/smoke.ps1`
- Modify: `CLAUDE.md` only if the command changes

**Interfaces:**
- Consumes: `Game`, `Progress`, the floor scene's `player`, `is_cleared`, `is_over`, `debug_take_first_exit()` and `MESSAGE_TIME`, groups `enemies` and `pickups`, `Enemy.take_damage`, `Health.hit`.
- Produces: `tools/smoke.ps1`, which exits 0 only when the full loop passes. Uses a separate save file, so real progress is untouched.

- [ ] **Step 1: Write the check**

`tools/smoke_driver.gd`:

```gdscript
extends Node

const TIMEOUT := 180.0
const MAX_ROOMS := 40

var _failed := false


func _ready() -> void:
	get_tree().create_timer(TIMEOUT).timeout.connect(func(): _fail("timed out"))
	_run()


func _run() -> void:
	await _wait(0.5)
	_expect_scene("Opening")
	Game.finish_opening()
	await _wait(0.5)
	_expect_scene("WaitingRoom")
	_check(Progress.data.opening_seen, "opening is remembered")

	Progress.add_pension(500)
	var upgrade: UpgradeDef = Content.upgrades()[0]
	var spent_ok: bool = Progress.buy(upgrade)
	_check(spent_ok, "can buy an upgrade")
	var pension_before: int = Progress.data.pension

	await _clear_whole_floor()
	_check(Progress.data.pension > pension_before, "Pension was earned during the run")
	await _wait(2.5)
	_expect_scene("WaitingRoom")

	await _die_in_a_run()
	await _wait(2.5)
	_expect_scene("WaitingRoom")

	var pension_saved: int = Progress.data.pension
	Progress.reload()
	_check(Progress.data.pension == pension_saved, "Pension survives a reload")
	_check(Progress.data.level_of(upgrade.id) == 1, "upgrade survives a reload")

	if not _failed:
		print("SMOKE PASS")
		get_tree().quit(0)


func _clear_whole_floor() -> void:
	Game.begin_run()
	await _wait(0.5)
	_expect_scene("FloorScene")
	var scene := get_tree().current_scene
	var starting_pills: int = scene.player.run.stats.max_pills
	_check(starting_pills >= 4, "run starts with pills")
	var guard := 0
	while not scene.is_cleared and guard < MAX_ROOMS:
		guard += 1
		await _clear_room(scene)
		if scene.is_cleared:
			break
		scene.debug_take_first_exit()
		await _wait(0.2)
	_check(scene.is_cleared, "floor can be cleared")


func _clear_room(scene: Node) -> void:
	await _wait(0.1)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.take_damage(INF, Vector2.ZERO)
	await _wait(0.1)
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if is_instance_valid(pickup) and not scene.is_over:
			scene.player.global_position = pickup.global_position
			await _wait(0.05)


func _die_in_a_run() -> void:
	Game.begin_run()
	await _wait(0.5)
	_expect_scene("FloorScene")
	var scene := get_tree().current_scene
	scene.player.run.health.hit(999)
	await _wait(0.1)
	_check(scene.is_over, "death ends the run")


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _expect_scene(expected: String) -> void:
	var scene := get_tree().current_scene
	_check(scene != null and scene.name == expected, "expected scene %s" % expected)


func _check(condition: bool, label: String) -> void:
	if not condition:
		_fail(label)


func _fail(label: String) -> void:
	if _failed:
		return
	_failed = true
	print("SMOKE FAIL: " + label)
	get_tree().quit(1)
```

`tools/smoke.ps1`:

```powershell
$godot = if ($env:GODOT) { $env:GODOT } else { "D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
if (-not (Test-Path $godot)) { Write-Output "Godot not found at $godot"; exit 2 }
$root = Split-Path $PSScriptRoot -Parent
& $godot --headless --path $root --import *> $null
$output = & $godot --headless --path $root -- --smoke 2>&1 | ForEach-Object { "$_" }
$code = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
if ($output -match "SCRIPT ERROR|Parse Error") { Write-Output "FAILED: script errors found"; exit 1 }
if ($code -ne 0 -or -not ($output -match "SMOKE PASS")) { exit 1 }
exit 0
```

- [ ] **Step 2: Run the check**

Run: `powershell -File tools/smoke.ps1`
Expected: output contains `SMOKE PASS`, exit code 0. Debug any failure with superpowers:systematic-debugging, and record gotchas in `LESSONS.md`.

- [ ] **Step 3: Run the test suite**

Run: `powershell -File tools/test.ps1`
Expected: 0 failed.

- [ ] **Step 4: Commit**

```powershell
git add tools LESSONS.md
git commit -m "Add automated full-loop check" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

**Human checkpoint:** Ask the user to play the full game with `& D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe --path C:\GameDev\game`, including quitting and reopening to confirm progress is saved.

---

### Task 14: Art pipeline and style guide

**Files:**
- Create: `tools/art/pixel_cleanup.gd`, `tools/art/cleanup_cli.gd`, `art/palette.txt`, `art/STYLE_GUIDE.md`
- Test: `tests/test_pixel_cleanup.gd`

**Interfaces:**
- Consumes: `SpriteVisual`'s lookup path, `res://art/sprites/<art_id>/<anim>.png`, with `idle`, `walk` and `attack` strips.
- Produces: `PixelCleanup`: static `process(source: Image, width: int, height: int, palette: PackedColorArray) -> Image`, static `parse_palette(text: String) -> PackedColorArray`.

- [ ] **Step 1: Write the failing test**

`tests/test_pixel_cleanup.gd`:

```gdscript
extends TestCase


func _palette() -> PackedColorArray:
	return PackedColorArray([Color.BLACK, Color.WHITE, Color.RED])


func test_output_has_the_requested_size() -> void:
	var source := Image.create(64, 96, false, Image.FORMAT_RGBA8)
	var result := PixelCleanup.process(source, 32, 48, _palette())
	assert_eq(result.get_width(), 32)
	assert_eq(result.get_height(), 48)


func test_colors_snap_to_the_palette() -> void:
	var source := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	source.fill(Color(0.9, 0.1, 0.1, 1.0))
	var result := PixelCleanup.process(source, 2, 2, _palette())
	assert_eq(result.get_pixel(0, 0), Color.RED)


func test_soft_edges_become_transparent_or_solid() -> void:
	var source := Image.create(2, 1, false, Image.FORMAT_RGBA8)
	source.set_pixel(0, 0, Color(1, 1, 1, 0.2))
	source.set_pixel(1, 0, Color(1, 1, 1, 0.8))
	var result := PixelCleanup.process(source, 2, 1, _palette())
	assert_near(result.get_pixel(0, 0).a, 0.0)
	assert_near(result.get_pixel(1, 0).a, 1.0)


func test_parse_palette_ignores_comments_and_blanks() -> void:
	var colors := PixelCleanup.parse_palette("# shadows\n\n17131c\nffd24a\n")
	assert_eq(colors.size(), 2)
	assert_eq(colors[0], Color.html("17131c"))


func test_shipped_palette_is_usable() -> void:
	var colors := PixelCleanup.parse_palette(FileAccess.get_file_as_string("res://art/palette.txt"))
	assert_true(colors.size() >= 16)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `powershell -File tools/test.ps1`
Expected: FAIL, reporting that `test_pixel_cleanup.gd` could not load.

- [ ] **Step 3: Implement**

`tools/art/pixel_cleanup.gd`:

```gdscript
class_name PixelCleanup
extends RefCounted

const ALPHA_CUTOFF := 0.5


static func process(source: Image, width: int, height: int, palette: PackedColorArray) -> Image:
	var image := source.duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	image.resize(width, height, Image.INTERPOLATE_NEAREST)
	for y in height:
		for x in width:
			var color := image.get_pixel(x, y)
			if color.a < ALPHA_CUTOFF:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				image.set_pixel(x, y, _nearest(color, palette))
	return image


static func parse_palette(text: String) -> PackedColorArray:
	var colors := PackedColorArray()
	for raw_line in text.split("\n"):
		var line := raw_line.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		colors.append(Color.html(line))
	return colors


static func _nearest(color: Color, palette: PackedColorArray) -> Color:
	var best := palette[0]
	var best_distance := INF
	for candidate in palette:
		var dr := color.r - candidate.r
		var dg := color.g - candidate.g
		var db := color.b - candidate.b
		var distance := dr * dr + dg * dg + db * db
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return Color(best.r, best.g, best.b, 1.0)
```

`tools/art/cleanup_cli.gd`:

```gdscript
extends SceneTree


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 4:
		print("Usage: -- <input.png> <output.png> <width> <height>")
		quit(2)
		return
	var source := Image.load_from_file(args[0])
	if source == null or source.is_empty():
		print("Could not read " + args[0])
		quit(1)
		return
	var palette := PixelCleanup.parse_palette(FileAccess.get_file_as_string("res://art/palette.txt"))
	var result := PixelCleanup.process(source, args[2].to_int(), args[3].to_int(), palette)
	if result.save_png(args[1]) != OK:
		print("Could not write " + args[1])
		quit(1)
		return
	print("Wrote " + args[1])
	quit(0)
```

`art/palette.txt`:

```
# Shadows and outlines
17131c
272140
3a3258
3a3547
# Stone
625e6f
6a6677
8f8ba0
# Warm light
ffd24a
ffd65c
ff9a3c
e4524f
a8692f
6b4a2a
# Grandpa
ece9e0
e8b58e
7d9a5c
506b3b
7a6a58
# Afterlife glow
67f0d0
7dd3fc
```

`art/STYLE_GUIDE.md`:

```markdown
# Art Style Guide

## Look

High-quality moody pixel art, seen from a top-down angle. Dark stone rooms are lit by torches, sparks and glowing enemies, with cold blue-purple shadows against warm orange light. The comedy comes from dreary office details in grim settings, like filing cabinets and take-a-number machines.

## Technical Rules

- Game resolution: 640×360.
- Grandpa: about 32 wide by 48 tall.
- Regular enemies: 32 wide frames.
- Senior Adjuster: 48 wide frames. Regional Reaper: 64 wide frames.
- Tiles: 32×32.
- Colors: only those in art/palette.txt. Lighting happens in the engine, so sprites use flat, evenly lit colors with no baked-in glow.
- Backgrounds: transparent.

## File Layout

Sprites go in `art/sprites/<id>/<anim>.png` as one horizontal strip per animation. The game uses them automatically in place of placeholders.

- `<id>` matches the enemy's id in its data file, or `grandpa` or `merchant`.
- `<anim>` is `idle`, `walk` or `attack`.

Open the project in the Godot editor once after adding files, so they get imported.

## Prompts

Never use names of other games, studios or artists in prompts. Describe the look directly.

Base prompt for a character:

> Pixel art game sprite, single character on a plain flat background, 3/4 top-down view, clean dark outline, limited color palette, flat even lighting, no shadows on the ground, no text. {SUBJECT}

Subjects:

- **Grandpa:** A grumpy thin old man with white hair and a big white mustache, round glasses, olive green cardigan, brown trousers, holding a wooden walking cane.
- **Intern Reaper:** A small nervous hooded skeleton in an ill-fitting dark purple robe, holding a small scythe and a lanyard.
- **Filing Clerk:** A tired grey ghost-like office worker in a short-sleeved shirt and tie, carrying a stack of paper.
- **Debt Collector Ghost:** A floating teal ghost wearing a cheap suit jacket, holding a clipboard.
- **Senior Adjuster:** A large hooded skeleton in a deep red robe, wearing a tie, holding a long scythe.
- **Regional Reaper:** A towering dark hooded reaper with a huge scythe and a name badge, glowing teal eyes.
- **Merchant:** A shady hooded figure in a purple coat, with the coat held open to show stolen goods.

## Processing

1. Generate at the largest size the tool allows, using a tool whose terms allow commercial use.
2. Remove the background.
3. Run the cleanup command, which reduces the image to the game's pixel grid and palette:

       godot --headless --path . --script res://tools/art/cleanup_cli.gd -- input.png output.png 32 48

4. Fix stray pixels and frame-to-frame differences by hand in a pixel art editor.

AI use is disclosed wherever a store requires it.
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `powershell -File tools/test.ps1`
Expected: 0 failed.

- [ ] **Step 5: Commit**

```powershell
git add tools art tests
git commit -m "Add pixel cleanup tool and art style guide" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

**Human checkpoint, the early art test from the spec:** Ask the user to generate Grandpa's `walk` and `attack` strips using the style guide, clean them up, and place them in `art/sprites/grandpa/`. Launch the game and judge whether he stays consistent across frames. If he doesn't, stop and revisit the art approach with the user before making more assets.

---

### Task 15: Playtest and tune against done criteria

**Files:**
- Modify: tuning values in `data/`, `scripts/actors/`, `scripts/core/` as needed
- Create: `docs/playtest-notes.md`

**Interfaces:**
- Consumes: the whole game.
- Produces: a first version that meets the spec's done criteria.

- [ ] **Step 1: Run all automated checks**

Run: `powershell -File tools/test.ps1`, then `powershell -File tools/smoke.ps1`
Expected: both exit with code 0.

- [ ] **Step 2: Ask the user to playtest and record the results**

Create `docs/playtest-notes.md`, recording the user's answers:

```markdown
# Playtest Notes

## First Version Checklist

- [ ] The full loop from Waiting Room to floor and back plays without crashes.
- [ ] Pension and upgrades survive quitting and reopening the game.
- [ ] A new player usually dies before beating the floor boss.
- [ ] A few rounds of upgrades make a win realistic.
- [ ] A normal run takes about 10 to 15 minutes.
- [ ] The cane combat feels good.

## Session Notes
```

- [ ] **Step 3: Tune from the feedback, one change at a time**

Use these starting points:

| Problem | Where to tune |
|---|---|
| Runs are too easy or hard | `max_hp` in `data/enemies/`, and `BASE_PILLS` in `player_stats.gd` |
| Upgrades arrive too slowly or quickly | `pension_drop`, `clear_pension`, and `prices` in `data/upgrades/` |
| Combat feels slow or weak | `cane_combo.gd`, `charge_swing.gd`, and the constants in `player.gd` |
| Runs are too long or short | `E` counts in `data/rooms/floor_1/` |

After each change, re-run both checks from Step 1 and commit:

```powershell
git add data scripts docs
git commit -m "Tune <what changed> from playtesting" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 4: Confirm done**

The first version is done only when the user confirms every item in the checklist, including that the combat feels good. Commit the final notes:

```powershell
git add docs/playtest-notes.md
git commit -m "Record first version playtest results" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
