# New Item List Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 100 old items with the user-approved list in `docs/superpowers/specs/2026-11-10-new-item-list-design.md`: 107 pool items (passives, pets, actives), 7 run potions and 11 set bonuses, with the systems they need, and retire the old items from every pool.

**Architecture:** Systems land first and stay inert until items use them: item data fields and a retired-content registry, icon hooks, the active slot, pets and shot guards, set bonuses, potion actions, and the play and rules hooks. Then the items land in batches by build, each new `.tres` joining the pool at once beside the old ones (renamed old ids retire the moment their replacement lands). A switch-over task retires every other old item and migrates saves; deleting the old files is a separate step that waits for the user's OK. Item rules live in `ItemEffect` scripts reached only through `EffectContext`, so every rule is tested headless with `tests/support/item_kit.gd`.

**Tech Stack:** Godot 4.7.2, GDScript, the repo's own test runner (`tests/run_tests.gd`, `tests/support/test_case.gd`), `tools/test.ps1`, `tools/smoke.ps1`.

## Global Constraints

- Worktree: `C:\GameDev\game\.worktrees\new-items`, branch `new-items` (from `rules-flashbacks`). Every path below is relative to it.
- Godot: `$GODOT = "D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"` (or `$env:GODOT` when set). A fresh worktree needs `& $GODOT --headless --path . --import` once.
- Quick test run (PowerShell, from the worktree): `& $GODOT --headless --path . --script res://tests/run_tests.gd -- --only=<file-name fragment>`. `--only` matches test **file** names. Check the "N tests, M failed" line, and that N is more than 0.
- Full suite: `powershell -File tools/test.ps1` (read the "N tests, M failed" line; the runner also fails on any `SCRIPT ERROR` or `Parse Error`). Full loop: `powershell -File tools/smoke.ps1` (must print `SMOKE PASS`).
- **Never run Godot while the user plays:** before every launch run `Get-Process *godot* -ErrorAction SilentlyContinue`; a windowed Godot (no `--headless` in its command line) means stop and wait. One heavy Godot job at a time.
- **Never write to `%APPDATA%\Godot\app_userdata\Grandpa\`.** Tests use `OS.get_temp_dir()`.
- Never name another video game anywhere (code, comments, data, assets, commits).
- No religious symbols in any drawn shape: no crosses, plus shapes, halos, inverted crosses, rings of thorns, pentagrams. Check every new `_draw` for two crossing straight strokes.
- No new dependencies or add-ons.
- Player-facing strings in new UI code go through `tr()`; item names and descriptions live in `.tres` data as today.
- Edit files with the Edit and Write tools or `py -I` scripts with `C:/` paths. Never Git Bash `sed -i` or PowerShell `Set-Content` (they rewrite CRLF files or add a BOM; LESSONS 2026-11-04, 2026-11-05, 2026-11-09). Before each commit run `git ls-files --eol <new files>` and expect `i/lf`.
- New sounds: none. Every `ctx.play_sound("...")` name must pass `SoundBank.can_play` (`tests/test_item_sounds.gd` reads every script in `scripts/items/`), so reuse names the old items already use: `coin`, `small_blast`, `pill_heal`, `thermos_pickup`, `slip_pickup`, `shield_block`, `form_filed`, `alarm`, `chime`, `charge_ready`, `slot_win`, `ticket_ding`, `card_flip`, `lethal_save`, `ui_ching`. A kept item keeps the key sound `KEY_SOUNDS` in that test names for it (Harmonica `pill_heal`, Lottery Scratcher `slot_win`, Early Bird Special `charge_ready`, Polyester Suit `small_blast`, Bureaucrat's Stamp `form_filed`, Complaint Form `ticket_ding`, Inheritance Letter `coin`, Eternal Warranty `lethal_save`, Magnifying Glass `chime`). `Sfx.play` names in non-item code come from `SoundBank.NAMES`.
- Any node an item leaves in a room joins `ItemFx.GROUP` (so `RoomView.is_passing_effect` clears it) or is added to `RoomView.is_passing_effect`.
- Item effects keep per-run state in plain member variables (RunEffects duplicates each effect per run). Once-a-run, per-floor and counter state goes through `save_state`/`load_state` (`state_of`, `load_members`).
- Every new rule that changes damage, pays Pension, blocks, soaks or heals does nothing while `ctx.counting_exact` (damage, Pension, fuses) or `ctx.counting_pills` (blocks, soaks, heals) is set, as the old items do.
- **Deleting old item files waits for the user's OK** (Task 26). Until then old files stay, retired by id.
- Commits: imperative mood, one logical change, and the message ends with the line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. In PowerShell: `git commit -m "Subject" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`. Do not push unless the user asks.
- Read `LESSONS.md` before starting; append a dated one-liner for every new gotcha.

## Shared names

Every task uses these names exactly. A task's "Interfaces" block repeats the ones it consumes.

| Name | Where | What |
|---|---|---|
| `ItemDef.KIND_PASSIVE`, `KIND_PET`, `KIND_ACTIVE`, `BUILDS` | item_def.gd | kinds and build ids |
| `ItemDef.build`, `kind`, `charge_rooms`, `charge_per_floor` | item_def.gd | new exports |
| `ItemDef.is_active()`, `is_pet()`, `needs_rules()` | item_def.gd | `needs_rules` is build `rules` or `memory`, not an active |
| `RetiredContent.RETIRED_ITEMS`, `RETIRED_COMBOS`, `RENAMED`, `RETIRED_RECIPE_PRICES`, `current_id(id)`, `is_retired(id)` | scripts/content/retired_content.gd | the registry |
| `Content.items()` (pool), `Content.all_items()`, `Content.sets()`, `Content.run_potions()` | content.gd | |
| `PlayerStats.SCALE_CAP` (20) | player_stats.gd | |
| stats `thermos_scale_bonus`, `extra_rule_rooms`, `bonus_kept_reels`, `extra_reels`, `extra_era_rooms`, `bonus_teeth_sets`, `pet_damage_bonus`, `pet_speed_bonus`, `extra_pets`, `half_heal_bonus`, `slip_cost_cut`, `throws_thermos` | StatEffect and PlayerStats | same name on both |
| `RunState.scaled_bombs()`, `scaled_keys()`, `add_keys(n)`, `add_bombs(n)` | run_state.gd | |
| `RunState.pension_at_start`, `floor_depth`, `rules_kept`, `rules_broken`, `flashbacks_played` | run_state.gd | |
| `RunState.held_reels`, `held_reel` (property), `reel_cap()` | run_state.gd | |
| `RunState.active`, `active_charge`, `active_swapped(old, charge)`, `add_item(item, active_charge := -1)`, `take_active`, `active_needed`, `active_ready`, `charge_active`, `fill_active`, `use_active` | run_state.gd | |
| `RunState.pet_count()`, `pet_damage_mult()`, `rules_posted()` | run_state.gd | |
| `EffectContext.pension_balance`, `purse()`, `spend_from_purse(n)`, `drop_item(item, at)`, `fetcher`, `fetch_pickup()`, `copier`, `copy_pickup()`, `lose_half()` | effect_context.gd | |
| `RunEffects.PET`, `ALLY`, `HIS_HITS`, `is_his_hit(source)` (static), `EVENT_RULE_KEPT`, `EVENT_RULE_BROKEN`, `EVENT_FLASHBACK_START`, `EVENT_FLASHBACK_END` | run_effects.gd | |
| `RunEffects.set_active`, `clear_active`, `active_effect`, `use_active`, `add_lasting`, `lasting_entries`, `set_sets`, `active_sets`, `has_set`, `restore_sets`, `set_formed`, `bonus_names`, `blast_hits`, `excuses_rule_break`, `sides_with_you`, `auditor`, `pet_damage_scale` | run_effects.gd | |
| `ItemEffect.use`, `can_use`, `on_blast_hits`, `excuses_rule_break`, `sides_with_you`, `on_auditor`, `pet_damage_scale`, `is_spent`, `on_drink` | item_effect.gd | |
| `HitScaleEffect` (`bonus(ctx)`) | scripts/items/hit_scale_effect.gd | "+N% to his hits" items (Task 11) |
| `ItemIcons.path`, `texture`, `set_for_test`, `clear_test` | scripts/ui/item_icons.gd | |
| `ActiveSlot` | scripts/ui/active_slot.gd | HUD slot |
| `Pet`, `PetEffect`, `ShotGuard`, `ShotGuards` | world/pet.gd, items/pet_effect.gd, world/shot_guard.gd, core/shot_guards.gd | |
| `SetDef` | scripts/content/set_def.gd | |
| `PotionDef.action`, `run_rarity`, `effect`, `ACTION_*`; `PotionActions`; `PotionPool` | potion_def.gd, core/potion_actions.gd, core/potion_pool.gd | |
| `ThrownThermos`, `Bomblet`, `WalkingFrame`, `AllyAuditor` | scripts/world/ | |
| `Enemy.extra_damage`, `Enemy.coin_mult`, `Enemy.leaves_item` | enemy.gd | |
| `Health.lose_half(never_last := true)`, `Health.half_heal_bonus` | health.gd | |
| `ShopRules.KIND_POTION` | shop_rules.gd | |
| `RuleStamp.KIND_WARNING` | rule_stamp.gd | |

## Item file template

Every new item is one `.tres` in `data/items/<id>.tres`. With an effect script:

```
[gd_resource type="Resource" script_class="ItemDef" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/content/item_def.gd" id="1"]
[ext_resource type="Script" path="res://scripts/items/<id>.gd" id="2"]

[sub_resource type="Resource" id="Effect"]
script = ExtResource("2")

[resource]
script = ExtResource("1")
id = "<id>"
display_name = "<Name>"
description = "<desc from the list>"
rarity = "<common|rare|legendary>"
tags = PackedStringArray("<build>")
build = "<build>"
kind = "<passive|pet|active>"
effect = SubResource("Effect")
```

Without a script, drop the second `ext_resource`, the `sub_resource` and the `effect` line and set `load_steps=2`. Add stat lines (`bonus_pills = 1` and so on), `cursed = true`, `charge_rooms = 3` or `charge_per_floor = true` as the task says. The description is the list's `desc`, word for word, unless a task says otherwise. Leave unlock fields (`craft_price`, `from_bounty`, `first_clear_path`) out of new items until Task 23, except where a task gives them. A kept item (same id) keeps its unlock lines.

For pets the sub-resource also sets the look: `look = "<id>"` and `color = Color(r, g, b, 1)` under `script = ExtResource("2")`.

## Test harness reminders

- `ItemKit.new()`; `kit.run_with(["id", ...])` gives a run holding shipped items; `kit.enemy("intern_reaper", hp)` makes an enemy out of the tree; set `.position` to place it; `kit.free_enemies()` at the end. `ctx.feet()` is `Vector2.ZERO` in tests, so "nearest to Harold" is nearest to the origin.
- `kit.notices`, `kit.fx` (`kit.fx_of(ItemFx.FxPop)`), `kit.sounds`, `kit.drops` (`[kind, at]`), `kit.paid`, `kit.spent`, `kit.pension` (what spends can take).
- `run.effects.effect_of(id)` returns the run's copy of an effect.
- Tests are synchronous; nodes added under `Engine.get_main_loop().root` get `_ready` and groups, but no frames run.

---
## Phase A: systems (nothing in the pool changes yet)

### Task 1: Item data fields, the retired registry, the 20-count rule, the purse and run counters

**Files:**
- Modify: `scripts/content/item_def.gd`, `scripts/content/content.gd`, `scripts/content/stat_effect.gd`, `scripts/core/player_stats.gd`, `scripts/core/run_state.gd`, `scripts/core/effect_context.gd`, `scripts/core/run_checkpoint.gd`, `scripts/scenes/floor_scene.gd`, `tests/support/item_kit.gd`, `tests/test_stats.gd`, `tests/test_items_batch4.gd`
- Create: `scripts/content/retired_content.gd`, `tests/test_item_data.gd`

**Interfaces:**
- Produces: everything in the Shared names table under item_def.gd, retired_content.gd, content.gd, PlayerStats/StatEffect stats, `RunState.scaled_bombs/scaled_keys/add_keys/add_bombs/pension_at_start/floor_depth/rules_kept/rules_broken/flashbacks_played`, `EffectContext.pension_balance/purse/spend_from_purse`. Stats added now, read by later tasks: `thermos_scale_bonus: int`, `extra_rule_rooms: int`, `extra_reels: int`, `extra_era_rooms: int`, `bonus_kept_reels: int`, `bonus_teeth_sets: int`, `pet_damage_bonus: float`, `pet_speed_bonus: float`, `extra_pets: int`, `half_heal_bonus: bool`, `slip_cost_cut: int`, `throws_thermos: bool`.

- [ ] **Step 1: Write the failing test** `tests/test_item_data.gd`

```gdscript
extends TestCase

# The new list's item fields, the retired registry, the 20-count rule, the purse and the run's own
# rule and flashback counters.


func test_new_item_fields_default_to_a_plain_passive() -> void:
	var item := ItemDef.new()
	assert_eq(item.build, "any")
	assert_eq(item.kind, ItemDef.KIND_PASSIVE)
	assert_false(item.is_active())
	assert_false(item.is_pet())
	assert_false(item.needs_rules())
	item.build = "rules"
	assert_true(item.needs_rules())
	item.build = "memory"
	assert_true(item.needs_rules())
	item.kind = ItemDef.KIND_ACTIVE
	assert_true(item.is_active())
	item.kind = ItemDef.KIND_PET
	assert_true(item.is_pet())
	for build: String in ItemDef.BUILDS:
		assert_true(ItemDef.TAGS.has(build), "%s is a tag too" % build)


func test_retired_ids_leave_the_pool_but_stay_loadable() -> void:
	var pool := {}
	for item in Content.items():
		pool[item.id] = true
	var every := {}
	for item in Content.all_items():
		every[item.id] = true
	for id: String in RetiredContent.RETIRED_ITEMS:
		assert_false(pool.has(id), "%s is retired" % id)
	assert_true(every.size() >= pool.size())
	assert_eq(RetiredContent.current_id("second_thermos_strap"), "flask_holster")
	assert_eq(RetiredContent.current_id("dentures"), "strong_dentures")
	assert_eq(RetiredContent.current_id("tea_cosy"), "tea_cosy", "a kept id maps to itself")


func test_scaled_counts_stop_at_twenty_and_the_bonus_raises_the_thermos_cap() -> void:
	var run := ItemKit.new().make_run()
	run.bombs = 50
	run.keys = 50
	assert_eq(run.scaled_bombs(), PlayerStats.SCALE_CAP)
	assert_eq(run.scaled_keys(), 20)
	var bonus := ItemDef.new()
	bonus.id = "test_scale"
	bonus.thermos_scale_bonus = 4
	run.add_item(bonus)
	assert_eq(run.scaled_bombs(), 24)
	assert_eq(run.scaled_keys(), 20, "nothing raises the Slip cap")
	run.bombs = 3
	assert_eq(run.scaled_bombs(), 3)


func test_adding_many_never_passes_the_hold_cap() -> void:
	var run := ItemKit.new().make_run()
	run.bombs = 97
	run.add_bombs(5)
	assert_eq(run.bombs, RunState.MAX_CONSUMABLE)
	run.keys = 0
	run.add_keys(3)
	assert_eq(run.keys, 3)
	run.add_keys(0)
	assert_eq(run.keys, 3)


func test_the_purse_is_what_the_bank_gained_this_run() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	kit.pension = 500
	run.pension_at_start = 400
	assert_eq(run.effects.ctx.purse(), 100)
	kit.pension = 300
	assert_eq(run.effects.ctx.purse(), 0, "never below zero")
	run.pension_at_start = 0
	kit.pension = 30
	assert_true(run.effects.ctx.spend_from_purse(20))
	assert_eq(kit.pension, 10)
	assert_false(run.effects.ctx.spend_from_purse(20), "the purse cannot cover it")
	assert_eq(kit.pension, 10)
	run.pension_at_start = -1
	assert_eq(run.effects.ctx.purse(), 10, "an unknown start counts the whole bank, never more")


func test_new_stats_add_up_from_items() -> void:
	var a := ItemDef.new()
	a.id = "a"
	a.extra_reels = 1
	a.pet_damage_bonus = 0.5
	a.bonus_teeth_sets = 1
	a.thermos_scale_bonus = 3
	var b := ItemDef.new()
	b.id = "b"
	b.extra_reels = 1
	b.teeth_sets = 2
	b.extra_rule_rooms = 1
	b.bonus_kept_reels = 1
	b.half_heal_bonus = true
	b.throws_thermos = true
	b.slip_cost_cut = 1
	b.extra_pets = 1
	b.pet_speed_bonus = 0.25
	b.extra_era_rooms = 1
	b.thermos_scale_bonus = 4
	var none: Array[UpgradeDef] = []
	var items: Array[ItemDef] = [a, b]
	var stats := PlayerStats.compute(none, {}, items)
	assert_eq(stats.extra_reels, 2)
	assert_near(stats.pet_damage_bonus, 0.5)
	assert_eq(stats.teeth_sets, 3, "the largest set count plus the bonus")
	assert_eq(stats.extra_rule_rooms, 1)
	assert_eq(stats.bonus_kept_reels, 1)
	assert_true(stats.half_heal_bonus)
	assert_true(stats.throws_thermos)
	assert_eq(stats.slip_cost_cut, 1)
	assert_eq(stats.extra_pets, 1)
	assert_near(stats.pet_speed_bonus, 0.25)
	assert_eq(stats.extra_era_rooms, 1)
	assert_eq(stats.thermos_scale_bonus, 7)
	var plain := PlayerStats.compute(none, {}, [] as Array[ItemDef])
	assert_eq(plain.teeth_sets, 1)
	assert_false(plain.throws_thermos)


func test_the_run_counters_and_purse_start_survive_the_checkpoint() -> void:
	var run := ItemKit.new().make_run()
	run.pension_at_start = 250
	run.floor_depth = 3
	run.rules_kept = 2
	run.rules_broken = 1
	run.flashbacks_played = 4
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run)))
	var back := ItemKit.new().make_run()
	RunCheckpoint.apply_run(back, raw, Content.items())
	assert_eq(back.pension_at_start, 250)
	assert_eq(back.floor_depth, 3)
	assert_eq(back.rules_kept, 2)
	assert_eq(back.rules_broken, 1)
	assert_eq(back.flashbacks_played, 4)
	var old := ItemKit.new().make_run()
	RunCheckpoint.apply_run(old, {}, Content.items())
	assert_eq(old.rules_kept, 0, "an older checkpoint starts at zero")
	assert_eq(old.pension_at_start, -1, "unknown until the floor scene reads the bank")


func test_the_floor_scene_sets_the_purse_and_depth() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(source.contains("_run.pension_at_start = Progress.data.pension"))
	assert_true(source.contains("ctx.pension_balance = _bank_balance"))
	assert_true(source.contains("_run.floor_depth = def.depth"))
	assert_true(source.contains("_run.floor_depth = _depth"))
```

- [ ] **Step 2: Run it to see it fail**

Run: `& $GODOT --headless --path . --script res://tests/run_tests.gd -- --only=item_data`
Expected: FAIL (parse errors: `build`, `RetiredContent`, `scaled_bombs` are not declared).

- [ ] **Step 3: Item fields.** In `scripts/content/item_def.gd`, replace the `TAGS` line and add the new exports and functions:

```gdscript
const KIND_PASSIVE := "passive"
const KIND_PET := "pet"
const KIND_ACTIVE := "active"
# The builds of the new list. Sets count items by build; every new item's tags are [build].
const BUILDS := ["thermos", "slip", "pension", "pets", "bite", "cane", "dodge", "pills", "risk", "rules", "memory", "any"]
# What tags may name. They group items for the Coach's tips; the builds are tags too.
const TAGS := ["cane", "bite", "dodge", "defence", "money", "thermos", "vision", "room", "boss",
	"slip", "pension", "pets", "pills", "risk", "rules", "memory", "any"]
```

and after `@export var tags`:

```gdscript
# The build it belongs to (BUILDS), and how it is held: a passive, a pet, or an active in the use slot.
@export var build: String = "any"
@export var kind: String = KIND_PASSIVE
# An active's recharge: fight rooms cleared to fill it, or once a floor when charge_per_floor is set.
@export var charge_rooms: int = 0
@export var charge_per_floor: bool = false
```

and at the end:

```gdscript
func is_active() -> bool:
	return kind == KIND_ACTIVE


func is_pet() -> bool:
	return kind == KIND_PET


# Rules and memory passives only make sense on floors that post room rules (RunState.rules_posted). An
# active of the rules build (the Megaphone) works anywhere.
func needs_rules() -> bool:
	return (build == "rules" or build == "memory") and kind != KIND_ACTIVE
```

- [ ] **Step 4: The registry.** Create `scripts/content/retired_content.gd`:

```gdscript
class_name RetiredContent
extends RefCounted

# Old content that has left the game's pools. A retired id's file may still be on disk until the user
# agrees to delete it (the new item list's plan, Task 26): Content.items() leaves it out, Content.all_items()
# still loads it. RENAMED maps an old id to the new item that took its place, for saves and checkpoints.

const RETIRED_ITEMS: Array[String] = []
const RETIRED_COMBOS: Array[String] = []
const RENAMED := {
	"second_thermos_strap": "flask_holster",
	"rubber_stamps": "rubber_stamp_collection",
	"pension_statement": "compound_interest",
	"penny_jar": "racing_pigeon",
	"mothball_pockets": "moths",
	"wreath_of_thorns": "cactus_brooch",
	"hearing_aid": "hearing_aid_feedback",
	"dentures": "strong_dentures",
}
# What a crafted item whose recipe left cost, refunded to a save that had one waiting.
const RETIRED_RECIPE_PRICES := {"alert_bracelet": 100, "golden_parachute": 110, "lucky_tee": 90, "support_stockings": 80}


static func current_id(id: String) -> String:
	return str(RENAMED.get(id, id))


static func is_retired(id: String) -> bool:
	return RETIRED_ITEMS.has(id)
```

- [ ] **Step 5: Content.** In `scripts/content/content.gd`, rename the body of `items()` to a new `all_items()` and make `items()` filter it; skip retired combos:

```gdscript
# The pool: every shipped item but the retired ones.
static func items() -> Array[ItemDef]:
	var list: Array[ItemDef] = []
	for item in all_items():
		if not RetiredContent.is_retired(item.id):
			list.append(item)
	return list


# Every item file, retired or not, for old tests and save migration.
static func all_items() -> Array[ItemDef]:
	var list: Array[ItemDef] = []
	for resource in load_dir(ITEMS_DIR):
		if resource is ItemDef:
			list.append(resource)
	return list
```

In `combos()`, change the append to `if resource is ComboDef and not RetiredContent.RETIRED_COMBOS.has(resource.id):`.

- [ ] **Step 6: Stats.** In `scripts/content/stat_effect.gd`, add at the end:

```gdscript
# The new item list. How many more Thermoses the scaling items count past PlayerStats.SCALE_CAP.
@export var thermos_scale_bonus: int = 0
# More rule rooms on every floor, deeper floors too (By the Book), and more reels a kept rule drops.
@export var extra_rule_rooms: int = 0
@export var bonus_kept_reels: int = 0
# More reels he may hold (Photo Album, Nostalgic), and more fight rooms a flashback lasts (Old Projector).
@export var extra_reels: int = 0
@export var extra_era_rooms: int = 0
# Sets of dentures added to the most any item gives (Full Set).
@export var bonus_teeth_sets: int = 0
# Pets: their hits' share on top (Tin of Dog Treats, Animal Lover), their walk, and pets that come with no item.
@export var pet_damage_bonus: float = 0.0
@export var pet_speed_bonus: float = 0.0
@export var extra_pets: int = 0
# Whether every heal that restores a pill also heals half a pill (Hypochondriac).
@export var half_heal_bonus: bool = false
# Slips taken off what opening anything costs, never below one (Locksmith's Apron).
@export var slip_cost_cut: int = 0
# Whether the Thermos key throws instead of placing (Overarm Bowler).
@export var throws_thermos: bool = false
```

In `scripts/core/player_stats.gd`: add `const SCALE_CAP := 20` under the other constants with the comment `# What the items that scale per Thermos or Slip carried count at most. Holding stays at RunState.MAX_CONSUMABLE.`; add the members

```gdscript
# The new item list's stats. See StatEffect.
var thermos_scale_bonus := 0
var extra_rule_rooms := 0
var bonus_kept_reels := 0
var extra_reels := 0
var extra_era_rooms := 0
var pet_damage_bonus := 0.0
var pet_speed_bonus := 0.0
var extra_pets := 0
var half_heal_bonus := false
var slip_cost_cut := 0
var throws_thermos := false
```

In `compute`, add the locals `var scale_bonus := 0`, `var rule_rooms := 0`, `var kept_reels := 0`, `var reels := 0`, `var era_rooms := 0`, `var bonus_sets := 0`, `var pet_damage := 0.0`, `var pet_speed := 0.0`, `var pets := 0`, `var half_heal := false`, `var cost_cut := 0`, `var throws := false`; in the loop add

```gdscript
		scale_bonus += effect.thermos_scale_bonus * count
		rule_rooms += effect.extra_rule_rooms * count
		kept_reels += effect.bonus_kept_reels * count
		reels += effect.extra_reels * count
		era_rooms += effect.extra_era_rooms * count
		bonus_sets += effect.bonus_teeth_sets * count
		pet_damage += effect.pet_damage_bonus * count
		pet_speed += effect.pet_speed_bonus * count
		pets += effect.extra_pets * count
		cost_cut += effect.slip_cost_cut * count
		if count > 0:
			half_heal = half_heal or effect.half_heal_bonus
			throws = throws or effect.throws_thermos
```

and after the stats are built change `stats.teeth_sets = sets` to `stats.teeth_sets = sets + maxi(bonus_sets, 0)` and add

```gdscript
	stats.thermos_scale_bonus = maxi(scale_bonus, 0)
	stats.extra_rule_rooms = maxi(rule_rooms, 0)
	stats.bonus_kept_reels = maxi(kept_reels, 0)
	stats.extra_reels = maxi(reels, 0)
	stats.extra_era_rooms = maxi(era_rooms, 0)
	stats.pet_damage_bonus = maxf(pet_damage, 0.0)
	stats.pet_speed_bonus = maxf(pet_speed, 0.0)
	stats.extra_pets = maxi(pets, 0)
	stats.half_heal_bonus = half_heal
	stats.slip_cost_cut = maxi(cost_cut, 0)
	stats.throws_thermos = throws
```

- [ ] **Step 7: RunState.** In `scripts/core/run_state.gd` add under `var era := ""`:

```gdscript
# What the bank held when this run began, so the items that read "Pension carried" read only what this
# run brought in (EffectContext.purse). -1 until known: a checkpoint from before it existed.
var pension_at_start := 0
# The depth of the floor or landing he is on, for the items offered only where rules are posted.
var floor_depth := 0
# This run's rules kept and broken, and flashbacks started, for the rules and memory items. The save's
# lifetime counts (ProgressData.rules_kept) are separate.
var rules_kept := 0
var rules_broken := 0
var flashbacks_played := 0
```

and after `use_bomb()`:

```gdscript
func add_keys(count: int) -> void:
	if count <= 0:
		return
	keys = mini(keys + count, MAX_CONSUMABLE)
	changed.emit()


func add_bombs(count: int) -> void:
	if count <= 0:
		return
	bombs = mini(bombs + count, MAX_CONSUMABLE)
	changed.emit()


# What the items that scale per Thermos or Slip carried count: never more than PlayerStats.SCALE_CAP,
# and for Thermoses the Flask Holster and the Tea Lady count a few more.
func scaled_bombs() -> int:
	return mini(bombs, PlayerStats.SCALE_CAP + stats.thermos_scale_bonus)


func scaled_keys() -> int:
	return mini(keys, PlayerStats.SCALE_CAP)
```

- [ ] **Step 8: The purse.** In `scripts/core/effect_context.gd` add under `spend_pension`:

```gdscript
# Reads the bank's Pension. Set by the scene; tests wire it to the kit.
var pension_balance := Callable()
```

and after `spend()`:

```gdscript
# The Pension this run brought in and still has: the bank above what it held when the run began, never
# below zero or above the bank. "Pension you carry" on an item means this.
func purse() -> int:
	var state := run()
	if state == null or not pension_balance.is_valid():
		return 0
	var balance := maxi(int(pension_balance.call()), 0)
	return clampi(balance - state.pension_at_start, 0, balance)


func spend_from_purse(amount: int) -> bool:
	if amount <= 0:
		return true
	if purse() < amount:
		return false
	return spend(amount)
```

- [ ] **Step 9: The checkpoint.** In `RunCheckpoint.run_to_dict` add the entries `"pension_at_start": run.pension_at_start, "floor_depth": run.floor_depth, "rules_kept": run.rules_kept, "rules_broken": run.rules_broken, "flashbacks_played": run.flashbacks_played,`. In `apply_run`, before `run.changed.emit()`:

```gdscript
	run.pension_at_start = int(raw.get("pension_at_start", -1))
	run.floor_depth = maxi(int(raw.get("floor_depth", 0)), 0)
	run.rules_kept = maxi(int(raw.get("rules_kept", 0)), 0)
	run.rules_broken = maxi(int(raw.get("rules_broken", 0)), 0)
	run.flashbacks_played = maxi(int(raw.get("flashbacks_played", 0)), 0)
```

- [ ] **Step 10: The floor scene.** In `scripts/scenes/floor_scene.gd`:
  - in `_start_run()`, right after `_run = Progress.make_run()`: `_run.pension_at_start = Progress.data.pension`;
  - in `_wire_item_pension()`: add `_run.effects.ctx.pension_balance = _bank_balance`, and add the method

    ```gdscript
    func _bank_balance() -> int:
    	return Progress.data.pension
    ```
  - right after `RunCheckpoint.apply_run(_run, resume.get("run", {}), Content.items())`: `if _run.pension_at_start < 0:` / `	_run.pension_at_start = Progress.data.pension`;
  - in the function that starts a new floor, just before `_rules.plan_floor(map, def.depth, seed_text, _progress)`: `_run.floor_depth = def.depth`;
  - on a landing, just before `_rules.plan_floor(FloorMap.new(), _depth, "")` (both calls): `_run.floor_depth = _depth`.
  Check `_wire_item_pension()` also runs on a resume (grep its callers); if not, call it there too.

- [ ] **Step 11: The kit and two old counting tests.** In `tests/support/item_kit.gd`: `item()` loops `Content.all_items()` instead of `Content.items()`; `wire()` adds `ctx.pension_balance = _on_balance`; add

```gdscript
func _on_balance() -> int:
	return pension
```

In `tests/test_stats.gd`, `test_shipped_content_loads`: replace `assert_eq(Content.items().size(), 100)` with `assert_true(Content.items().size() >= 52, "the pool loads")`. In `tests/test_recipes.gd`, `test_shipped_recipe_items_have_prices_and_base_items_do_not`: replace `assert_eq(base, 70)` with `assert_true(base >= 47, "the open items")` (Task 24 sets the exact count). In `tests/test_items_batch4.gd`, delete the whole function `test_the_hundred_items_add_up` (from its `func` line down to the blank lines before `# --- vision ---`); Task 24 adds the new pool's count test.

- [ ] **Step 12: Run the new and the touched tests**

Run: `& $GODOT --headless --path . --script res://tests/run_tests.gd -- --only=item_data` then `-- --only=stats`, `-- --only=run_checkpoint`, `-- --only=items_batch4`.
Expected: all PASS.

- [ ] **Step 13: Full suite**

Run: `powershell -File tools/test.ps1`
Expected: "N tests, 0 failed".

- [ ] **Step 14: Commit**

```powershell
git add scripts/content/item_def.gd scripts/content/content.gd scripts/content/stat_effect.gd scripts/content/retired_content.gd scripts/core/player_stats.gd scripts/core/run_state.gd scripts/core/effect_context.gd scripts/core/run_checkpoint.gd scripts/scenes/floor_scene.gd tests/support/item_kit.gd tests/test_item_data.gd tests/test_stats.gd tests/test_recipes.gd tests/test_items_batch4.gd
git commit -m "Add the new item list's data fields, retired registry, purse and 20-count rule" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Item icon hooks

**Files:**
- Create: `scripts/ui/item_icons.gd`, `scripts/ui/item_row.gd`, `tests/test_item_icons.gd`
- Modify: `scripts/world/pickup.gd`, `scripts/world/room_view.gd` (`_mark_item`), `scripts/ui/hud.gd` (item row), `scripts/ui/case_file.gd` (`CaseCell._draw`), `scripts/core/case_file_data.gd` (`item_cell`), `docs/art/art-inventory.md` (§1.3, §2.12)

**Interfaces:**
- Produces: `ItemIcons.DIR`, `ItemIcons.path(id) -> String`, `ItemIcons.texture(id) -> Texture2D` (null without a PNG), `ItemIcons.set_for_test(id, tex)`, `ItemIcons.clear_test()`; `Pickup.icon_id: String`, `Pickup.ICON_SIZE := 20.0`, `Pickup.draws_icon() -> bool`; `ItemRow.pieces(count, entries) -> Array` (each `["text", String]` or `["icon", Texture2D]`); `Hud.item_row_entries(items: Array[ItemDef]) -> Array[Dictionary]` (`{"name", "icon"}`, newest first, at most `ITEMS_SHOWN`); `Hud.item_row_uses_icons() -> bool`; `CaseFile.cell_texture(cell: Dictionary) -> Texture2D`.
- Task 4 uses `ItemIcons.texture` in the active slot.

- [ ] **Step 1: Write the failing test** `tests/test_item_icons.gd`

```gdscript
extends TestCase

# Item icons are drawn wherever an item shows once the art pass drops a PNG at its path; until then
# every place keeps its old look.


func _icon() -> Texture2D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.ORANGE)
	return ImageTexture.create_from_image(image)


func _item(id: String, item_name: String) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	item.display_name = item_name
	return item


func test_an_icon_path_names_the_item() -> void:
	assert_eq(ItemIcons.path("tea_urn"), "res://art/icons/items/tea_urn.png")
	assert_eq(CaseFileData.ITEM_ICON_DIR, ItemIcons.DIR)


func test_no_png_means_no_icon_and_a_test_icon_is_used() -> void:
	ItemIcons.clear_test()
	assert_true(ItemIcons.texture("no_such_item_anywhere") == null)
	assert_true(ItemIcons.texture("") == null)
	var icon := _icon()
	ItemIcons.set_for_test("tea_urn", icon)
	assert_eq(ItemIcons.texture("tea_urn"), icon)
	ItemIcons.clear_test()


func test_a_pickup_draws_its_icon_only_when_there_is_one() -> void:
	ItemIcons.clear_test()
	var pickup := Pickup.new()
	# A made-up id: real icons are arriving in art/icons/items/ (LESSONS 2026-11-09).
	pickup.icon_id = "no_icon_test_item"
	assert_false(pickup.draws_icon(), "no PNG: the disc stays")
	ItemIcons.set_for_test("no_icon_test_item", _icon())
	assert_true(pickup.draws_icon())
	pickup.free()
	ItemIcons.clear_test()


func test_room_item_pickups_and_wares_name_their_icon() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	var mark := source.substr(source.find("func _mark_item"), 200)
	assert_true(mark.contains("pickup.icon_id = item.id"), "every item pickup and item ware goes through _mark_item")


func test_the_item_row_keeps_names_until_an_icon_exists() -> void:
	ItemIcons.clear_test()
	var items: Array[ItemDef] = [_item("test_a", "Alpha"), _item("test_b", "Beta"), _item("test_c", "Gamma"), _item("test_d", "Delta")]
	var entries := Hud.item_row_entries(items)
	assert_eq(entries.size(), Hud.ITEMS_SHOWN)
	assert_eq(entries[0]["name"], "Delta", "newest first")
	assert_true(entries[0]["icon"] == null)
	var icon := _icon()
	ItemIcons.set_for_test("test_c", icon)
	entries = Hud.item_row_entries(items)
	var pieces := ItemRow.pieces(items.size(), entries)
	assert_eq(pieces[0], ["text", "Items: 4   "])
	assert_eq(pieces[1], ["text", "Delta, "])
	assert_eq(pieces[2], ["icon", icon])
	assert_eq(pieces[3], ["text", "Beta"])
	ItemIcons.clear_test()


func test_the_case_file_takes_its_item_icons_from_item_icons() -> void:
	ItemIcons.clear_test()
	var item := _item("no_icon_test_item", "Test Item")
	var cell := CaseFileData.item_cell(item, true, 1)
	assert_true(CaseFile.cell_texture(cell) == null)
	var icon := _icon()
	ItemIcons.set_for_test("no_icon_test_item", icon)
	assert_eq(CaseFile.cell_texture(cell), icon)
	ItemIcons.clear_test()
```

- [ ] **Step 2: Run it to see it fail**

Run: `& $GODOT --headless --path . --script res://tests/run_tests.gd -- --only=item_icons`
Expected: FAIL (`ItemIcons` not declared).

- [ ] **Step 3: ItemIcons.** Create `scripts/ui/item_icons.gd`:

```gdscript
class_name ItemIcons
extends RefCounted

# Item icons: 32 px PNGs at DIR/<id>.png, made apart from the code. Every place that shows an item (room
# pickups, shop wares, the HUD's item row and active slot, the case file) asks here and keeps its old look
# while there is no PNG.

const DIR := "res://art/icons/items/"

static var _test := {}
static var _cache := {}


static func path(id: String) -> String:
	return DIR + id + ".png"


static func texture(id: String) -> Texture2D:
	if id.is_empty():
		return null
	if _test.has(id):
		return _test[id]
	if _cache.has(id):
		return _cache[id]
	var found: Texture2D = null
	if ResourceLoader.exists(path(id)):
		found = load(path(id)) as Texture2D
	_cache[id] = found
	return found


static func set_for_test(id: String, icon: Texture2D) -> void:
	_test[id] = icon


static func clear_test() -> void:
	_test.clear()
	_cache.clear()
```

- [ ] **Step 4: Pickups.** In `scripts/world/pickup.gd` add `const ICON_SIZE := 20.0` and, under `var art_id`,

```gdscript
# An item's id, whose icon (ItemIcons) is drawn instead of the disc once its PNG exists. "" for none.
var icon_id := ""
```

add `func draws_icon() -> bool: return ItemIcons.texture(icon_id) != null` (as a two-line function), and make `_draw_body()` start with

```gdscript
	var icon := ItemIcons.texture(icon_id)
	if icon != null:
		draw_texture_rect(icon, Rect2(Vector2(-ICON_SIZE, -ICON_SIZE) / 2.0, Vector2(ICON_SIZE, ICON_SIZE)), false)
		return
```

In `scripts/world/room_view.gd`, `_mark_item(pickup, item)`: add the line `pickup.icon_id = item.id`.

- [ ] **Step 5: The HUD item row.** Create `scripts/ui/item_row.gd`:

```gdscript
class_name ItemRow
extends Control

# The HUD's item row once any of its newest items has an icon: "Items: N", then each newest item's icon
# at ICON px, or its name where it has none. With no icon at all the HUD keeps its plain label.

const ICON := 12.0
const GAP := 3.0

var _pieces: Array = []


# What the row draws, in order: ["text", words] or ["icon", texture].
static func pieces(count: int, entries: Array[Dictionary]) -> Array:
	var out: Array = [["text", "Items: %d   " % count]]
	for i in entries.size():
		var icon: Texture2D = entries[i]["icon"]
		if icon != null:
			out.append(["icon", icon])
		else:
			out.append(["text", str(entries[i]["name"]) + (", " if i < entries.size() - 1 else "")])
	return out


func show_pieces(list: Array) -> void:
	_pieces = list
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var font := HudStyle.font()
	var x := 0.0
	for piece in _pieces:
		if x >= size.x:
			return
		if piece[0] == "icon":
			draw_texture_rect(piece[1], Rect2(Vector2(x, 0.0), Vector2(ICON, ICON)), false)
			x += ICON + GAP
		else:
			draw_string(font, Vector2(x, 9.0), piece[1], HORIZONTAL_ALIGNMENT_LEFT, size.x - x, Hud.ITEM_ROW_FONT)
			x += font.get_string_size(piece[1], HORIZONTAL_ALIGNMENT_LEFT, -1, Hud.ITEM_ROW_FONT).x
```

In `scripts/ui/hud.gd`: add `var _item_row: ItemRow`; in `_ready()` after `_items` is made: `_item_row = ItemRow.new()`, `_item_row.visible = false`, `add_child(_item_row)`; add

```gdscript
# The newest few items, newest first, with each one's icon or null.
static func item_row_entries(items: Array[ItemDef]) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for i in mini(ITEMS_SHOWN, items.size()):
		var item := items[items.size() - 1 - i]
		entries.append({"name": item.display_name, "icon": ItemIcons.texture(item.id)})
	return entries


func item_row_uses_icons() -> bool:
	return _item_row != null and _item_row.visible
```

and in `_refresh()`, after `_items.text = items_text(names)`:

```gdscript
		var entries := item_row_entries(_run.items)
		var with_icons := entries.any(func(entry): return entry["icon"] != null)
		_item_row.visible = with_icons
		_items.visible = not with_icons
		if with_icons:
			_item_row.show_pieces(ItemRow.pieces(_run.items.size(), entries))
```

and where `_items.position`/`_items.size` are set from `rects[0]`, set `_item_row.position = rects[0].position` and `_item_row.size = rects[0].size` too.

- [ ] **Step 6: The case file.** In `scripts/core/case_file_data.gd`: `const ITEM_ICON_DIR := ItemIcons.DIR` and in `item_cell`, `"icon": ItemIcons.path(item.id)`. In `scripts/ui/case_file.gd` add to `CaseFile`:

```gdscript
# A cell's picture: an item's icon through ItemIcons, an enemy's from its icon path, or null.
static func cell_texture(cell: Dictionary) -> Texture2D:
	if cell.get("item") != null:
		return ItemIcons.texture(str(cell.get("id", "")))
	var icon_path := str(cell.get("icon", ""))
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		return load(icon_path) as Texture2D
	return null
```

and in `CaseCell._draw()` replace the two lines `var icon_path := ...` / `if known and ResourceLoader.exists(icon_path):` / `draw_texture_rect(load(icon_path), ...)` with

```gdscript
		var picture := CaseFile.cell_texture(cell)
		if known and picture != null:
			draw_texture_rect(picture, rect.grow(-2), false)
```

- [ ] **Step 7: The art doc.** In `docs/art/art-inventory.md` §2.12, replace "There are 100 items" with "There are 107 items" and mark points 2 and 3 as hooked: "Hooked (new item list): `Pickup.icon_id` draws the icon at 20x20 for room items and item wares; the HUD row (`ItemRow`) draws 12x12 icons; the active slot draws 14x14. All read `ItemIcons.texture`." In §1.3 change "There are 100 items." to "There are 107 items."

- [ ] **Step 8: Run the tests**

Run: `-- --only=item_icons`, `-- --only=case_file`, `-- --only=hud`, `-- --only=pickup`
Expected: all PASS.

- [ ] **Step 9: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/ui/item_icons.gd scripts/ui/item_row.gd scripts/world/pickup.gd scripts/world/room_view.gd scripts/ui/hud.gd scripts/ui/case_file.gd scripts/core/case_file_data.gd docs/art/art-inventory.md tests/test_item_icons.gd
git commit -m "Draw item icons on pickups, wares, the HUD row and the case file once they exist" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: The active slot's core, and the new effect hooks

**Files:**
- Modify: `scripts/content/item_effect.gd`, `scripts/core/run_effects.gd`, `scripts/core/run_state.gd`, `scripts/core/run_checkpoint.gd`
- Create: `tests/support/test_active_effect.gd`, `tests/test_active_items.gd`

**Interfaces:**
- Consumes: `ItemDef.is_active()`, `charge_rooms`, `charge_per_floor` (Task 1).
- Produces:
  - `ItemEffect.can_use(ctx) -> bool`, `use(ctx) -> bool`, `pet_damage_scale(ctx) -> float`, `on_blast_hits(ctx, at: Vector2, count: int)`, `excuses_rule_break(ctx) -> bool`, `sides_with_you(ctx) -> bool`, `on_auditor(ctx, auditor: Enemy)`, `is_spent() -> bool`, `on_drink(ctx)`.
  - `RunEffects.PET := "pet"`, `ALLY := "ally"`, `HIS_HITS`, `static is_his_hit(source) -> bool`, `set_active(item, gain := true)`, `clear_active()`, `active_effect() -> ItemEffect`, `use_active() -> bool`, `blast_hits(at, count)`, `excuses_rule_break() -> bool` (the first effect that says yes is the only one asked), `sides_with_you() -> bool`, `auditor(enemy)`, `pet_damage_scale() -> float`.
  - `RunState.active: ItemDef`, `active_charge: int`, `signal active_swapped(old: ItemDef, charge: int)`, `add_item(item, active_charge_left := -1)`, `take_active(item, charge := -1)`, `restore_active(item, charge)`, `active_needed() -> int`, `active_ready() -> bool`, `charge_active()`, `fill_active()`, `use_active() -> bool`; `has_item(id)` also answers for the active.
  - Checkpoint keys `"active"` (id) and `"active_charge"`; `effects.save_state()` gains `"active"`.

- [ ] **Step 1: The test effect** `tests/support/test_active_effect.gd`

```gdscript
extends ItemEffect

# A test active: counts its uses, and can refuse (allow) or do nothing (does).

@export var allow := true
@export var does := true
var uses := 0


func can_use(_ctx: EffectContext) -> bool:
	return allow


func use(_ctx: EffectContext) -> bool:
	if does:
		uses += 1
	return does


func save_state() -> Dictionary:
	return state_of(["uses"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["uses"])
```

- [ ] **Step 2: Write the failing test** `tests/test_active_items.gd`

```gdscript
extends TestCase

# The active slot: one held at a time, charged by fight rooms (or once a floor), used with its own key,
# swapped by taking another.

const TestActive := preload("res://tests/support/test_active_effect.gd")
const Counting := preload("res://tests/support/counting_effect.gd")


func _active(id: String, rooms := 2, per_floor := false) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	item.display_name = id.capitalize()
	item.kind = ItemDef.KIND_ACTIVE
	item.charge_rooms = rooms
	item.charge_per_floor = per_floor
	item.effect = TestActive.new()
	return item


func test_a_new_active_arrives_charged_and_is_held_apart_from_items() -> void:
	var run := ItemKit.new().make_run()
	var bell := _active("bell", 2)
	run.add_item(bell)
	assert_eq(run.active, bell)
	assert_true(run.items.is_empty(), "actives are not in the item list")
	assert_true(run.has_item("bell"), "but the pools see it as held")
	assert_true(run.active_ready())
	assert_eq(run.found, ["bell"] as Array[String], "the case file counts it as found")


func test_using_spends_the_charge_and_fight_rooms_fill_it_again() -> void:
	var run := ItemKit.new().make_run()
	run.add_item(_active("bell", 2))
	assert_true(run.use_active())
	assert_eq(run.effects.active_effect().uses, 1)
	assert_false(run.active_ready())
	assert_false(run.use_active(), "empty")
	run.effects.room_clear(null)
	assert_false(run.active_ready())
	run.effects.room_clear(null)
	assert_true(run.active_ready())
	run.effects.room_clear(null)
	assert_eq(run.active_charge, 2, "never past full")


func test_a_refused_or_idle_use_keeps_the_charge() -> void:
	var run := ItemKit.new().make_run()
	run.add_item(_active("bell", 2))
	run.effects.active_effect().allow = false
	assert_false(run.use_active())
	assert_true(run.active_ready())
	run.effects.active_effect().allow = true
	run.effects.active_effect().does = false
	assert_false(run.use_active())
	assert_true(run.active_ready())


func test_a_once_a_floor_active_fills_at_each_floor_start() -> void:
	var run := ItemKit.new().make_run()
	run.add_item(_active("ticket", 0, true))
	assert_eq(run.active_needed(), 1)
	assert_true(run.use_active())
	run.effects.room_clear(null)
	assert_false(run.active_ready(), "rooms do not fill it")
	run.effects.floor_start()
	assert_true(run.active_ready())


func test_taking_another_swaps_and_the_old_one_keeps_its_charge() -> void:
	var run := ItemKit.new().make_run()
	var seen: Array = []
	run.active_swapped.connect(func(old: ItemDef, charge: int): seen.append([old.id, charge]))
	run.add_item(_active("bell", 3))
	run.use_active()
	run.effects.room_clear(null)
	run.add_item(_active("frame", 2))
	assert_eq(run.active.id, "frame")
	assert_true(run.active_ready(), "the new one arrives charged")
	assert_eq(seen, [["bell", 1]])
	assert_false(run.has_item("bell"))
	run.add_item(_active("bell", 3), 1)
	assert_eq(run.active_charge, 1, "taking a dropped one back brings back its charge")


func test_the_active_survives_the_checkpoint_with_its_charge_and_state() -> void:
	var run := ItemKit.new().make_run()
	var bell := _active("bell", 3)
	run.add_item(bell)
	run.use_active()
	run.effects.room_clear(null)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run)))
	var back := ItemKit.new().make_run()
	var shipped: Array[ItemDef] = [bell]
	RunCheckpoint.apply_run(back, raw, shipped)
	assert_eq(back.active, bell)
	assert_eq(back.active_charge, 1)
	assert_eq(back.effects.active_effect().uses, 1, "its state came back")


func test_the_active_hears_the_usual_hooks_and_leaves_with_the_items() -> void:
	var run := ItemKit.new().make_run()
	var item := _active("counting", 2)
	item.effect = Counting.new()
	run.add_item(item)
	run.effects.tick(0.1)
	assert_eq(int(run.effects.active_effect().counts.get("tick", 0)), 1)
	assert_eq(run.effects.effect_of("counting"), run.effects.active_effect())
	run.clear_items()
	assert_true(run.active == null, "leaving the Training Yard drops the active too")
	assert_true(run.effects.active_effect() == null)


func test_new_hook_dispatchers_default_to_no_change() -> void:
	var run := ItemKit.new().make_run()
	assert_near(run.effects.pet_damage_scale(), 1.0)
	assert_false(run.effects.excuses_rule_break())
	assert_false(run.effects.sides_with_you())
	run.effects.blast_hits(Vector2.ZERO, 3)
	assert_true(RunEffects.is_his_hit(RunEffects.SWING))
	assert_true(RunEffects.is_his_hit("era"))
	assert_false(RunEffects.is_his_hit(RunEffects.PET))
	assert_false(RunEffects.is_his_hit(RunEffects.ALLY))
```

- [ ] **Step 3: Run it to see it fail**

Run: `-- --only=active_items`
Expected: FAIL (`active` and `use_active` not declared).

- [ ] **Step 4: ItemEffect hooks.** Append to `scripts/content/item_effect.gd`, before `# --- a resumed run ---`:

```gdscript
# --- the new item list ---

# Whether an active may be used now (Harmonica waits for a missing pill). Only an active's effect is asked.
func can_use(_ctx: EffectContext) -> bool:
	return true


# The active is used. Return true when it did something, which spends its charge; false keeps it.
func use(_ctx: EffectContext) -> bool:
	return false


# What pets' hits are multiplied by at this moment (Dinner Bell, Tin of Pet Food). 1.0 for no change.
func pet_damage_scale(_ctx: EffectContext) -> float:
	return 1.0


# One of his Thermos blasts landed on count enemies (Tea Break).
func on_blast_hits(_ctx: EffectContext, _at: Vector2, _count: int) -> void:
	pass


# A room rule has just been broken. Return true to let it off with a warning: no Auditor (Fine Print).
func excuses_rule_break(_ctx: EffectContext) -> bool:
	return false


# Whether the Auditor a broken rule sends fights for Harold instead (Clipboard of Your Own).
func sides_with_you(_ctx: EffectContext) -> bool:
	return false


# The Auditor has walked into the room (Repeat Offender, Brown Envelope).
func on_auditor(_ctx: EffectContext, _auditor: Enemy) -> void:
	pass


# A potion's lasting part is dropped once this is true.
func is_spent() -> bool:
	return false


# A potion's lasting part, the moment it is drunk.
func on_drink(_ctx: EffectContext) -> void:
	pass
```

- [ ] **Step 5: RunEffects.** In `scripts/core/run_effects.gd`:

```gdscript
# A pet's bite and the turned Auditor's clipboard. Neither is one of his hits.
const PET := "pet"
const ALLY := "ally"
# His own hits: what the "+N% to all your hits" items scale. "era" is Player.ERA_HIT, named here since
# this core script must not name Player.
const HIS_HITS := [SWING, CHARGE, COMBO_3, BITE, THERMOS, ITEM, "era"]
```

add the members `var _active_id := ""` and `var _active_effect: ItemEffect`, and:

```gdscript
static func is_his_hit(source: String) -> bool:
	return HIS_HITS.has(source)


# --- the active slot ---

# The held active's effect. gain is false when a resumed run gets it back.
func set_active(item: ItemDef, gain := true) -> void:
	clear_active()
	if item == null:
		return
	_active_id = item.id
	if item.effect != null:
		_active_effect = item.effect.duplicate()
		if gain:
			_active_effect.on_gain(ctx)


func clear_active() -> void:
	_active_id = ""
	_active_effect = null


func active_effect() -> ItemEffect:
	return _active_effect


func use_active() -> bool:
	if _active_effect == null or not _active_effect.can_use(ctx):
		return false
	return _active_effect.use(ctx)


func blast_hits(at: Vector2, count: int) -> void:
	for effect in _all():
		effect.on_blast_hits(ctx, at, count)


func excuses_rule_break() -> bool:
	for effect in _all():
		if effect.excuses_rule_break(ctx):
			return true
	return false


func sides_with_you() -> bool:
	for effect in _all():
		if effect.sides_with_you(ctx):
			return true
	return false


func auditor(enemy: Enemy) -> void:
	for effect in _all():
		effect.on_auditor(ctx, enemy)


func pet_damage_scale() -> float:
	var scale := 1.0
	for effect in _all():
		scale *= effect.pet_damage_scale(ctx)
	return scale
```

Change `_all()` to append `_active_effect` (when not null) after the entries and before the combos; `effect_of(id)` returns `_active_effect` when `id == _active_id`; `clear()` calls `clear_active()`; `tick()` becomes `for effect in _all(): effect.tick(ctx, delta)`; `save_state()` adds `"active": _active_effect.save_state() if _active_effect != null else {}`; `load_state()` ends with

```gdscript
	if _active_effect != null:
		var state: Variant = raw.get("active", {})
		_active_effect.load_state(state if state is Dictionary else {})
```

At the end of `room_clear(room)`: `var run := _run()` / `if run != null:` / `run.charge_active()`. At the end of `floor_start()`: `var run := _run()` / `if run != null and not ctx.is_landing():` / `run.fill_active()`.

- [ ] **Step 6: RunState.** In `scripts/core/run_state.gd` add `signal active_swapped(old: ItemDef, charge: int)` under `signal changed`, the members

```gdscript
# The one active he holds (ItemDef.KIND_ACTIVE), not in items, and its charge in fight rooms cleared.
var active: ItemDef
var active_charge := 0
```

replace `add_item` with

```gdscript
# An active goes to the active slot, swapping out any held one, which keeps its charge
# (active_swapped). active_charge_left is the charge a dropped active is taken back with; -1 is full.
func add_item(item: ItemDef, active_charge_left := -1) -> void:
	found.append(item.id)
	if item.is_active():
		take_active(item, active_charge_left)
		return
	var saves_before := stats.floor_lethal_saves
	items.append(item)
	effects.add(item)
	refresh_stats()
	# A Life Jacket picked up mid-floor works on this floor already, as does a combo that adds a save.
	health.lethal_saves += maxi(stats.floor_lethal_saves - saves_before, 0)
```

and add

```gdscript
func take_active(item: ItemDef, charge := -1) -> void:
	var old := active
	var old_charge := active_charge
	active = item
	active_charge = active_needed() if charge < 0 else clampi(charge, 0, active_needed())
	effects.set_active(item)
	refresh_stats()
	if old != null:
		active_swapped.emit(old, old_charge)


# A resumed run's active, put back without a second on_gain.
func restore_active(item: ItemDef, charge: int) -> void:
	active = item
	active_charge = clampi(charge, 0, active_needed())
	effects.set_active(item, false)


# Fight rooms the held active needs, 1 for a once-a-floor one, 0 with none.
func active_needed() -> int:
	if active == null:
		return 0
	return 1 if active.charge_per_floor else maxi(active.charge_rooms, 1)


func active_ready() -> bool:
	return active != null and active_charge >= active_needed()


# A fight room cleared.
func charge_active() -> void:
	if active == null or active.charge_per_floor or active_ready():
		return
	active_charge += 1
	changed.emit()


# A floor start fills a once-a-floor active.
func fill_active() -> void:
	if active != null and active.charge_per_floor and not active_ready():
		active_charge = active_needed()
		changed.emit()


func use_active() -> bool:
	if not active_ready() or not effects.use_active():
		return false
	active_charge = 0
	changed.emit()
	return true
```

`has_item(id)` gains, before `return false`: `if active != null and active.id == id:` / `return true`. `clear_items()` adds `active = null` and `active_charge = 0` before `effects.clear()`.

- [ ] **Step 7: The checkpoint.** `run_to_dict` adds `"active": run.active.id if run.active != null else "", "active_charge": run.active_charge,`. In `apply_run`, after the items loop and before `effects.load_state`:

```gdscript
	var active_id := str(raw.get("active", ""))
	if not active_id.is_empty():
		for item in items:
			if item.id == active_id and item.is_active():
				run.restore_active(item, int(raw.get("active_charge", 0)))
				break
```

- [ ] **Step 8: Run the tests**

Run: `-- --only=active_items`, `-- --only=item_system`, `-- --only=resume_item_state`, `-- --only=run_checkpoint`
Expected: all PASS.

- [ ] **Step 9: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/content/item_effect.gd scripts/core/run_effects.gd scripts/core/run_state.gd scripts/core/run_checkpoint.gd tests/support/test_active_effect.gd tests/test_active_items.gd
git commit -m "Add the active item slot, its charge and the new effect hooks" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: The use-item key, the HUD active slot, dropping a swapped active

**Files:**
- Modify: `scripts/core/input_setup.gd`, `scripts/core/pad_input.gd`, `scripts/core/key_bindings.gd`, `scripts/actors/player.gd`, `scripts/ui/hud.gd`, `scripts/scenes/floor_scene.gd`, `scripts/world/room_view.gd`, `scripts/core/case_file_data.gd`, `scripts/ui/case_file.gd`, `tests/test_key_bindings.gd`
- Create: `scripts/ui/active_slot.gd`, `tests/test_active_slot.gd`

**Interfaces:**
- Consumes: `RunState.active`, `active_charge`, `active_needed()`, `active_ready()`, `use_active()`, `active_swapped` (Task 3); `ItemIcons.texture` (Task 2).
- Produces: action `"use_item"` (key R, pad B); `Player.active_used(item: ItemDef)` signal; `ActiveSlot.label_text(key, item) -> String`, `ActiveSlot.charge_fraction(charge, needed) -> float`, `ActiveSlot.slot_rect(left_end: float) -> Rect2`, `ActiveSlot.show_active(item, charge, needed, key)`; `Hud.active_label() -> String`; `RoomView.drop_active(item, charge, at) -> Pickup`; `CaseFileData.held_cells(items, active := null)` (the active first, with `"use": true`).

- [ ] **Step 1: Write the failing test** `tests/test_active_slot.gd`

```gdscript
extends TestCase

const TestActive := preload("res://tests/support/test_active_effect.gd")


func _active(id: String, item_name: String) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	item.display_name = item_name
	item.kind = ItemDef.KIND_ACTIVE
	item.charge_rooms = 2
	item.effect = TestActive.new()
	return item


func test_the_use_item_action_is_r_and_pad_b() -> void:
	InputSetup.ensure()
	KeyBindings.reset_to_defaults()
	assert_true(InputMap.has_action("use_item"))
	assert_eq(KeyBindings.label_for("use_item"), "R")
	assert_eq(KeyBindings.pad_label_for("use_item", PadInput.XBOX), "B")
	assert_eq(KeyBindings.action_label("use_item"), "Use item")


func test_no_two_actions_share_a_default_binding() -> void:
	InputSetup.ensure()
	KeyBindings.reset_to_defaults()
	var keys := {}
	var pads := {}
	for entry in KeyBindings.ACTIONS:
		var action: String = entry["action"]
		var key := KeyBindings.label_for(action)
		var pad := KeyBindings.pad_label_for(action, PadInput.XBOX)
		assert_false(keys.has(key), "%s and %s share %s" % [action, keys.get(key, ""), key])
		assert_false(pads.has(pad), "%s and %s share %s" % [action, pads.get(pad, ""), pad])
		keys[key] = action
		pads[pad] = action


func test_the_slot_text_and_charge() -> void:
	var item := _active("hearing", "Hearing Aid")
	assert_eq(ActiveSlot.label_text("R", item), "[R] Hearing Aid")
	assert_eq(ActiveSlot.label_text("R", null), "")
	assert_near(ActiveSlot.charge_fraction(1, 3), 1.0 / 3.0)
	assert_near(ActiveSlot.charge_fraction(5, 3), 1.0)
	assert_near(ActiveSlot.charge_fraction(0, 0), 0.0)


func test_the_slot_sits_in_the_top_band_between_the_panels() -> void:
	var rect := ActiveSlot.slot_rect(Hud.LEFT_PANEL_AT.x + Hud.LEFT_PANEL_MIN_WIDTH)
	assert_true(rect.position.x >= Hud.LEFT_PANEL_AT.x + Hud.LEFT_PANEL_MIN_WIDTH)
	assert_true(rect.end.x <= Hud.RIGHT_PANEL.position.x)
	assert_true(rect.end.y <= Hud.TOP_BAND_SIZE.y)
	var wide := ActiveSlot.slot_rect(380.0)
	assert_true(wide.size.x >= ActiveSlot.MIN_WIDTH, "a wide left panel still leaves the icon and bar")


func test_the_hud_shows_the_held_active_only_while_held() -> void:
	var run := ItemKit.new().make_run()
	var hud := Hud.new()
	hud.setup(run)
	hud._ready()
	assert_eq(hud.active_label(), "")
	run.add_item(_active("bell", "Dinner Bell"))
	assert_eq(hud.active_label(), "[%s] Dinner Bell" % KeyBindings.prompt_label("use_item"))
	run.clear_items()
	assert_eq(hud.active_label(), "")
	hud.free()


func test_the_case_file_shows_the_active_first() -> void:
	var tea := ItemDef.new()
	tea.id = "tea_cosy"
	tea.display_name = "Tea Cosy"
	var items: Array[ItemDef] = [tea]
	var cells := CaseFileData.held_cells(items, _active("bell", "Dinner Bell"))
	assert_eq(cells.size(), 2)
	assert_eq(cells[0]["id"], "bell")
	assert_true(cells[0]["use"])
	assert_false(cells[1].get("use", false))


func test_the_player_uses_the_active_and_the_floor_drops_a_swapped_one() -> void:
	var player := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(player.contains("Input.is_action_just_pressed(\"use_item\")"))
	assert_true(player.contains("active_used.emit("))
	var floor_scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(floor_scene.contains("_run.active_swapped.connect(_on_active_swapped)"))
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(room.contains("func drop_active("))
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=active_slot`
Expected: FAIL (`ActiveSlot` not declared; `use_item` missing).

- [ ] **Step 3: The action.** `scripts/core/input_setup.gd`: after `_action("potion", _key(KEY_H))` add `_action("use_item", _key(KEY_R))`. `scripts/core/pad_input.gd` `DEFAULT_BUTTONS`: add `"use_item": JOY_BUTTON_B,` with the comment `# B backs out of panels (BACK_ACTION, its own action); in play it uses the held active.` `scripts/core/key_bindings.gd` `ACTIONS`: after the potion entry add `{"action": "use_item", "label": "Use item"},`.

In `tests/test_key_bindings.gd`, `test_both_columns_survive_saving_and_loading`: change `KeyBindings.rebind("dodge", _pad(JOY_BUTTON_B))` to `KeyBindings.rebind("dodge", _pad(JOY_BUTTON_LEFT_STICK))` and `assert_eq(KeyBindings.pad_label_for("dodge", PadInput.XBOX), "B")` to `assert_eq(KeyBindings.pad_label_for("dodge", PadInput.XBOX), "LS")`, with the comment `# The left stick press: B is the use-item button now.` Also grep `tests/` and `tools/` for `JOY_BUTTON_B` and `KEY_R` used as a "free" binding and move any such use to `JOY_BUTTON_LEFT_STICK` / `KEY_G`.

- [ ] **Step 4: The player.** In `scripts/actors/player.gd` add `signal active_used(item: ItemDef)` under `signal potion_drunk`, call `_handle_active()` right after `_handle_potion()` in `_physics_process`, and add

```gdscript
func _handle_active() -> void:
	if not InputMap.has_action("use_item") or not Input.is_action_just_pressed("use_item"):
		return
	var used := run.active
	if run.use_active():
		Sfx.play("item_fanfare")
		active_used.emit(used)
```

- [ ] **Step 5: The slot.** Create `scripts/ui/active_slot.gd`:

```gdscript
class_name ActiveSlot
extends Control

# The HUD's active slot, in the top band between the left panel and the right panel: the held active's
# icon (or a box in its rarity colour with its initials), its key and name, and a charge bar along the
# bottom with a tick per room, gold when ready. Nothing while no active is held.

const RIGHT_EDGE := 400.0
const GAP := 4.0
const TOP := 3.0
const HEIGHT := 16.0
const MIN_WIDTH := 40.0
const ICON := 14.0
const TEXT_AT := Vector2(18, 1)
const BAR_HEIGHT := 2.0
const BAR_EMPTY := Color(0.0, 0.0, 0.0, 0.5)
const BAR_FILL := Color("9fd8ff")
const BAR_READY := Color("ffd24a")

var _item: ItemDef
var _fraction := 0.0
var _needed := 0
var _label: Label


static func label_text(key: String, item: ItemDef) -> String:
	return "" if item == null else "[%s] %s" % [key, item.display_name]


static func charge_fraction(charge: int, needed: int) -> float:
	return 0.0 if needed <= 0 else clampf(float(charge) / float(needed), 0.0, 1.0)


# Where the slot sits when the left panel ends at left_end: just after it, up to RIGHT_EDGE, never
# narrower than MIN_WIDTH.
static func slot_rect(left_end: float) -> Rect2:
	var x := minf(left_end + GAP, RIGHT_EDGE - MIN_WIDTH)
	return Rect2(Vector2(x, TOP), Vector2(RIGHT_EDGE - x, HEIGHT))


func _ready() -> void:
	if _label != null:
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.position = TEXT_AT
	_label.clip_text = true
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudStyle.style_label(_label, HudStyle.SMALL)
	add_child(_label)


func show_active(item: ItemDef, charge: int, needed: int, key: String) -> void:
	_ready()
	_item = item
	_needed = needed
	_fraction = charge_fraction(charge, needed)
	_label.text = label_text(key, item)
	_label.size = Vector2(maxf(size.x - TEXT_AT.x, 0.0), 12.0)
	queue_redraw()


func label_text_shown() -> String:
	return _label.text if _label != null else ""


func _draw() -> void:
	if _item == null:
		return
	var icon := ItemIcons.texture(_item.id)
	var box := Rect2(Vector2(1, 0), Vector2(ICON, ICON))
	if icon != null:
		draw_texture_rect(icon, box, false)
	else:
		draw_rect(box, ItemRarity.name_color(_item))
		draw_rect(box, Color.BLACK, false, 1.0)
		var font := HudStyle.font()
		var text := CaseFileData.initials(_item.display_name)
		draw_string(font, Vector2(2, 10), text, HORIZONTAL_ALIGNMENT_LEFT, ICON, 8, Color.BLACK)
	var bar := Rect2(Vector2(0, size.y - BAR_HEIGHT), Vector2(size.x, BAR_HEIGHT))
	draw_rect(bar, BAR_EMPTY)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _fraction, BAR_HEIGHT)), BAR_READY if _fraction >= 1.0 else BAR_FILL)
	for i in range(1, _needed):
		var x := bar.size.x * i / _needed
		draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y), Color.BLACK, 1.0)
```

- [ ] **Step 6: The HUD.** In `scripts/ui/hud.gd` add `var _active_slot: ActiveSlot` and `var _active_key := ""`; in `_ready()` inside `if _run != null:` after the reel slot: `_active_slot = ActiveSlot.new()`, `add_child(_active_slot)`. In `_refresh()` inside `if _run != null:` after `_reel_slot.show_reel(...)`:

```gdscript
		_active_key = KeyBindings.prompt_label("use_item")
		var slot := ActiveSlot.slot_rect(left_panel_rect().end.x)
		_active_slot.position = slot.position
		_active_slot.size = slot.size
		_active_slot.show_active(_run.active, _run.active_charge, _run.active_needed(), _active_key)
```

(this must come after `_layout_top_row()` runs, so move it below that call in `_refresh`). In `_process`, add `or KeyBindings.prompt_label("use_item") != _active_key` to the key-change check that calls `_refresh()`. Add

```gdscript
# What the active slot says: its key and the active's name, "" while none is held.
func active_label() -> String:
	return _active_slot.label_text_shown() if _active_slot != null else ""
```

- [ ] **Step 7: Dropping a swapped active.** In `scripts/scenes/floor_scene.gd`, beside `_run.effects.combo_formed.connect(_on_combo_formed)`: `_run.active_swapped.connect(_on_active_swapped)`, and

```gdscript
# Taking an active while holding one drops the old one at his feet, keeping its charge.
func _on_active_swapped(old: ItemDef, charge: int) -> void:
	if _room_view != null and is_instance_valid(_room_view):
		_room_view.drop_active(old, charge, player.feet().global_position)
```

In `scripts/world/room_view.gd` add

```gdscript
# A swapped-out active, a cell beside him, waiting to be taken back with the charge it had.
func drop_active(item: ItemDef, charge: int, at: Vector2) -> Pickup:
	var spot := clear_spot(at + Vector2(RoomBackdrop.TILE, 0))
	var pickup := _add_pickup(spot, item.display_name, ItemRarity.color_of(item.rarity), func(): _run.add_item(item, charge), true, "item_fanfare")
	pickup.can_take = func(): return not _run.has_item(item.id)
	pickup.set_meta(KEEP, {"kind": KEEP_ITEM, "id": item.id, "charge": charge})
	_mark_item(pickup, item)
	return pickup
```

and in `_restore_entry`, in the `KEEP_ITEM, KEEP_FREE` branch, before making the pickup: `if entry.has("charge") and item.is_active():` / `drop_active(item, int(entry["charge"]), at - Vector2(RoomBackdrop.TILE, 0))` / `return`. (The Training Yard has no room view: a swapped active there simply leaves, as items tried there do.)

- [ ] **Step 8: The case file.** `CaseFileData.held_cells(items: Array[ItemDef], active: ItemDef = null)`: when `active != null`, the first cell is `item_cell(active, true, 1)` with `"badge": true` and `"use": true`. `scripts/ui/case_file.gd` line `return CaseFileData.held_cells(_run.items) if _run != null else []` becomes `return CaseFileData.held_cells(_run.items, _run.active) if _run != null else []`. In `CaseCell._draw()`, after the count badge, a cell with `cell.get("use", false)` draws `tr("USE")` in the small font in its bottom-left corner, in `CaseFile.INK` on a 1 px paper box, so the active reads apart from the passives.

- [ ] **Step 9: Run the tests**

Run: `-- --only=active_slot`, `-- --only=key_bindings`, `-- --only=pad_input`, `-- --only=hud`, `-- --only=case_file`
Expected: all PASS.

- [ ] **Step 10: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/core/input_setup.gd scripts/core/pad_input.gd scripts/core/key_bindings.gd scripts/actors/player.gd scripts/ui/active_slot.gd scripts/ui/hud.gd scripts/scenes/floor_scene.gd scripts/world/room_view.gd scripts/core/case_file_data.gd scripts/ui/case_file.gd tests/test_key_bindings.gd tests/test_active_slot.gd
git commit -m "Add the use-item key, the HUD active slot and dropping a swapped active" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---
### Task 5: Pets and shot guards

**Files:**
- Create: `scripts/core/shot_guards.gd`, `scripts/world/shot_guard.gd`, `scripts/world/pet.gd`, `scripts/items/pet_effect.gd`, `tests/support/scale_effect.gd`, `tests/test_pets.gd`
- Modify: `scripts/core/run_state.gd`, `scripts/core/run_effects.gd` (`add`, `clear`), `scripts/actors/projectile.gd`

**Interfaces:**
- Consumes: `ItemDef.is_pet()`, stats `pet_damage_bonus`, `pet_speed_bonus`, `extra_pets` (Task 1); `RunEffects.PET`, `pet_damage_scale()` (Task 3).
- Produces: `ShotGuards.GROUP`, `ShotGuards.try_block(tree, at) -> bool`; `ShotGuard` (Node2D: `radius`, `check: Callable -> bool`, `spend: Callable`, `blocks_shot(at) -> bool`); `Pet extends ShotGuard` (`Pet.make(look, color, slot, speed := Pet.SPEED) -> Pet`, `Pet.slot_offset(slot) -> Vector2`, `follow`, `orbit_speed`, `orbit_radius`, `lunge_to(at)`); `PetEffect extends ItemEffect` (`@export look`, `@export color`, `slot: int`, `pet() -> Pet`, `setup_pet(ctx, pet)`, `base_speed() -> float`, `mult(ctx) -> float`, `nearest(ctx, reach, regular_only := false) -> Enemy`, `strike(ctx, enemy, base) -> bool`); `RunState.pet_count() -> int`, `RunState.pet_damage_mult() -> float`.

- [ ] **Step 1: Support effect** `tests/support/scale_effect.gd`

```gdscript
extends ItemEffect

# A test effect that scales pets' hits.

@export var scale := 2.0


func pet_damage_scale(_ctx: EffectContext) -> float:
	return scale
```

- [ ] **Step 2: Write the failing test** `tests/test_pets.gd`

```gdscript
extends TestCase

const Scale := preload("res://tests/support/scale_effect.gd")


func _pet_item(id: String) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	item.display_name = id.capitalize()
	item.kind = ItemDef.KIND_PET
	item.build = "pets"
	var effect := PetEffect.new()
	effect.look = id
	item.effect = effect
	return item


func _stat_item(id: String) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	return item


func test_pets_count_and_extra_pets_count_too() -> void:
	var run := ItemKit.new().make_run()
	assert_eq(run.pet_count(), 0)
	run.add_item(_pet_item("rex_test"))
	run.add_item(_pet_item("mittens_test"))
	assert_eq(run.pet_count(), 2)
	var cat := _stat_item("cat_bonus")
	cat.extra_pets = 1
	run.add_item(cat)
	assert_eq(run.pet_count(), 3)


func test_the_pet_multiplier_adds_bonuses_and_multiplies_scales() -> void:
	var run := ItemKit.new().make_run()
	assert_near(run.pet_damage_mult(), 1.0)
	var treats := _stat_item("treats")
	treats.pet_damage_bonus = 0.5
	run.add_item(treats)
	assert_near(run.pet_damage_mult(), 1.5)
	var bell := _stat_item("bell")
	bell.effect = Scale.new()
	run.add_item(bell)
	assert_near(run.pet_damage_mult(), 3.0)


func test_a_pet_hit_lands_as_a_pet_hit_scaled_by_the_multiplier() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.add_item(_pet_item("rex_test"))
	var treats := _stat_item("treats")
	treats.pet_damage_bonus = 0.5
	run.add_item(treats)
	var effect: PetEffect = run.effects.effect_of("rex_test")
	var enemy := kit.enemy()
	var before := enemy.hp
	assert_true(effect.strike(run.effects.ctx, enemy, 6.0))
	assert_near(before - enemy.hp, 9.0)
	run.effects.ctx.counting_exact = true
	assert_false(effect.strike(run.effects.ctx, enemy, 6.0), "the full loop counts damage exactly")
	kit.free_enemies()


func test_a_pet_finds_the_nearest_enemy_in_reach() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.add_item(_pet_item("rex_test"))
	var effect: PetEffect = run.effects.effect_of("rex_test")
	var far := kit.enemy()
	far.position = Vector2(100, 0)
	var near := kit.enemy()
	near.position = Vector2(50, 0)
	var boss := kit.enemy("regional_reaper")
	boss.position = Vector2(10, 0)
	assert_eq(effect.nearest(run.effects.ctx, 160.0), boss)
	assert_eq(effect.nearest(run.effects.ctx, 160.0, true), near, "regular only skips the boss")
	assert_true(effect.nearest(run.effects.ctx, 5.0) == null)
	kit.free_enemies()


func test_each_pet_places_its_body_in_every_room_on_its_own_slot() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.add_item(_pet_item("rex_test"))
	run.add_item(_pet_item("mittens_test"))
	run.effects.room_enter(null)
	assert_eq(kit.fx.filter(func(entry): return entry["script"] == Pet).size(), 2)
	assert_eq(run.effects.effect_of("rex_test").slot, 0)
	assert_eq(run.effects.effect_of("mittens_test").slot, 1)
	var seen := {}
	for i in 6:
		var offset := Pet.slot_offset(i)
		assert_false(seen.has(offset), "slot %d has its own spot" % i)
		seen[offset] = true


func test_a_pet_body_is_a_passing_effect_and_never_blocks_by_itself() -> void:
	var pet := Pet.make("rex", Color("8a5a2b"), 0)
	assert_true(RoomView.is_passing_effect(pet))
	var root: Window = Engine.get_main_loop().root
	root.add_child(pet)
	pet.global_position = Vector2(200, 200)
	assert_false(ShotGuards.try_block(root.get_tree(), Vector2(200, 200)), "a pet with no guard rule blocks nothing")
	root.remove_child(pet)
	pet.free()


func test_a_guard_blocks_a_shot_in_reach_only_when_ready_and_spends() -> void:
	var root: Window = Engine.get_main_loop().root
	var guard := ShotGuard.new()
	guard.radius = 10.0
	var state := {"ready": true, "spent": 0}
	guard.check = func() -> bool: return state["ready"]
	guard.spend = func() -> void:
		state["spent"] += 1
		state["ready"] = false
	root.add_child(guard)
	guard.global_position = Vector2(300, 300)
	assert_false(ShotGuards.try_block(root.get_tree(), Vector2(340, 300)), "out of reach")
	assert_true(ShotGuards.try_block(root.get_tree(), Vector2(305, 300)))
	assert_eq(state["spent"], 1)
	assert_false(ShotGuards.try_block(root.get_tree(), Vector2(305, 300)), "spent until ready again")
	root.remove_child(guard)
	guard.free()


func test_projectiles_ask_the_guards_before_their_target() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/actors/projectile.gd")
	var guard_at := source.find("ShotGuards.try_block(get_tree(), global_position)")
	assert_true(guard_at > 0)
	assert_true(guard_at < source.find("_target.take_hit("), "a guard stops the shot before it reaches him")
```

- [ ] **Step 3: Run it to see it fail**

Run: `-- --only=test_pets`
Expected: FAIL (`PetEffect`, `ShotGuards` not declared).

- [ ] **Step 4: Shot guards.** Create `scripts/core/shot_guards.gd`:

```gdscript
class_name ShotGuards
extends RefCounted

# Whatever stops an enemy's shot (a Projectile) short of Harold: Joey the Budgie, Shelley, the moths, a big
# Pet Rock, Loose Paperwork's sheets and the Walking Frame. Each is a node in GROUP with
# blocks_shot(at) -> bool, which spends what it had when it says yes. Ground strikes, blasts and lanes
# are no shots, so nothing here stops them.

const GROUP := "shot_guards"


static func try_block(tree: SceneTree, at: Vector2) -> bool:
	if tree == null:
		return false
	for node in tree.get_nodes_in_group(GROUP):
		if node.is_queued_for_deletion() or not node.has_method("blocks_shot"):
			continue
		if node.blocks_shot(at):
			return true
	return false
```

Create `scripts/world/shot_guard.gd`:

```gdscript
class_name ShotGuard
extends Node2D

# One shot guard: a shot within radius is stopped when check says it may be, and spend is told it was.
# With no check it never blocks, so a pet that guards nothing is a plain body. It is an item's look in
# the room (ItemFx.GROUP), so leaving the room clears it.

var radius := 8.0
var check := Callable()
var spend := Callable()
# What it stands on, if anything (Loose Paperwork's sheets stand on Harold). Pet moves on its own.
var follow: Node2D


func _init() -> void:
	add_to_group(ShotGuards.GROUP)
	add_to_group(ItemFx.GROUP)
	z_index = ItemFx.Z


func _process(_delta: float) -> void:
	if is_instance_valid(follow):
		global_position = follow.global_position
	queue_redraw()


func blocks_shot(at: Vector2) -> bool:
	if not is_inside_tree() or not check.is_valid():
		return false
	if global_position.distance_to(at) > radius or not bool(check.call()):
		return false
	if spend.is_valid():
		spend.call()
	return true
```

In `scripts/actors/projectile.gd` `_physics_process`, right after `global_position = next`:

```gdscript
	# A pet, a sheet of paperwork or a walking frame in the way stops it here.
	if ShotGuards.try_block(get_tree(), global_position):
		_land()
		return
```

- [ ] **Step 5: The pet body.** Create `scripts/world/pet.gd`:

```gdscript
class_name Pet
extends ShotGuard

# A pet beside Harold: it walks to its slot round his feet (or circles him), lunges at what it bites, and
# draws a placeholder in its colour until res://art/props/pet_<look>.png exists. Its rules live in its
# item's effect (PetEffect); this node shows it, and blocks a shot when its effect sets check.

const SPEED := 150.0
const SLOT_REACH := 22.0
# Behind him first, then to his sides, then round again a little further out.
const SLOT_ANGLES := [150.0, 30.0, 210.0, 330.0, 90.0, 270.0]
const LUNGE_TIME := 0.18
const LUNGE_PACE := 2.5
const EYE := Color("1a1410")

var look := ""
var color := Color.WHITE
var slot := 0
var speed := SPEED
# Radians a second for the pets that circle him (Joey, the moths); 0 for one that keeps its slot.
var orbit_speed := 0.0
var orbit_radius := SLOT_REACH
var orbit_angle := 0.0
var _lunge_to := Vector2.INF
var _lunge_left := 0.0


static func make(pet_look: String, pet_color: Color, pet_slot: int, walk_speed := SPEED) -> Pet:
	var pet := Pet.new()
	pet.look = pet_look
	pet.color = pet_color
	pet.slot = pet_slot
	pet.speed = walk_speed
	return pet


static func slot_offset(pet_slot: int, reach := SLOT_REACH) -> Vector2:
	var ring := pet_slot / SLOT_ANGLES.size()
	var angle := deg_to_rad(float(SLOT_ANGLES[pet_slot % SLOT_ANGLES.size()]))
	return Vector2.from_angle(angle) * (reach + 10.0 * ring)


static func step_toward(from: Vector2, to: Vector2, pace: float, delta: float) -> Vector2:
	var offset := to - from
	var step := pace * delta
	return to if offset.length() <= step else from + offset.normalized() * step


func home() -> Vector2:
	if not is_instance_valid(follow):
		return global_position
	if orbit_speed != 0.0:
		return follow.global_position + Vector2.from_angle(orbit_angle) * orbit_radius
	return follow.global_position + slot_offset(slot)


func lunge_to(at: Vector2) -> void:
	_lunge_to = at
	_lunge_left = LUNGE_TIME


func _process(delta: float) -> void:
	orbit_angle = wrapf(orbit_angle + orbit_speed * delta, 0.0, TAU)
	if _lunge_left > 0.0:
		_lunge_left -= delta
		global_position = step_toward(global_position, _lunge_to, speed * LUNGE_PACE, delta)
	elif orbit_speed != 0.0:
		global_position = home()
	else:
		global_position = step_toward(global_position, home(), speed, delta)
	queue_redraw()


# A round body, a smaller head toward where it last moved, and one dark eye. No straight crossing strokes.
func _draw() -> void:
	var art := PropArt.texture("pet_" + look)
	if art != null:
		PropArt.draw(self, art)
		return
	draw_circle(Vector2(0, 1), 5.0, color.darkened(0.35))
	draw_circle(Vector2.ZERO, 4.5, color)
	draw_circle(Vector2(4, -3), 3.0, color)
	draw_circle(Vector2(5, -3.5), 0.9, EYE)
```

- [ ] **Step 6: The pet effect.** Create `scripts/items/pet_effect.gd`:

```gdscript
class_name PetEffect
extends ItemEffect

# What every pet's effect shares: it places the pet's body (Pet) by Harold in every room he enters, finds
# what the pet goes for, and lands its hits through the run's hooks as pet hits, scaled by the pet
# multiplier (RunState.pet_damage_mult). Each pet's own script says what it does. slot is set by
# RunEffects in pickup order.

@export var look := ""
@export var color := Color.WHITE
var slot := 0
var _pet: WeakRef


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	_pet = null
	var body := Pet.make(look, color, slot, base_speed() * (1.0 + _speed_bonus(ctx)))
	body.follow = ctx.player if ctx.has_player() else null
	setup_pet(ctx, body)
	var placed := ctx.add_fx(body, ctx.feet() + Pet.slot_offset(slot))
	_pet = weakref(placed) if placed != null else null


# The body this room, or null (always null in tests, where the room frees it at once).
func pet() -> Pet:
	return _pet.get_ref() as Pet if _pet != null else null


# A pet that guards or circles sets its body up here.
func setup_pet(_ctx: EffectContext, _body: Pet) -> void:
	pass


func base_speed() -> float:
	return Pet.SPEED


func mult(ctx: EffectContext) -> float:
	var run := ctx.run()
	return run.pet_damage_mult() if run != null else 1.0


func nearest(ctx: EffectContext, reach: float, regular_only := false) -> Enemy:
	var best: Enemy = null
	var best_distance := reach
	for enemy in ctx.enemies_near(ctx.feet(), reach):
		if regular_only and enemy.def.is_boss:
			continue
		var distance := enemy.global_position.distance_to(ctx.feet())
		if distance <= best_distance:
			best = enemy
			best_distance = distance
	return best


# One pet hit of base damage, times the pet multiplier. Nothing while the full loop counts damage.
func strike(ctx: EffectContext, enemy: Enemy, base: float) -> bool:
	if enemy == null or ctx.counting_exact:
		return false
	var body := pet()
	if body != null:
		body.lunge_to(enemy.global_position)
	return ctx.hit_enemy(enemy, base * mult(ctx), RunEffects.PET)


func _speed_bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	return run.stats.pet_speed_bonus if run != null else 0.0
```

- [ ] **Step 7: Seats and counts.** In `scripts/core/run_effects.gd`, in `add()` right after `var copy: ItemEffect = item.effect.duplicate()`: `_seat_pet(copy)`, and add

```gdscript
# A pet's slot round his feet: how many pets were seated before it.
func _seat_pet(copy: ItemEffect) -> void:
	if not copy is PetEffect:
		return
	var seated := 0
	for effect in _all():
		if effect is PetEffect:
			seated += 1
	copy.slot = seated
```

In `scripts/core/run_state.gd` add

```gdscript
# Pet items held, and pets that came with no item (the Animal Lover's stray cat).
func pet_count() -> int:
	var count := stats.extra_pets
	for item in items:
		if item.is_pet():
			count += 1
	return count


# What a pet's hit is multiplied by: the bonuses added (Tin of Dog Treats, Animal Lover), then each
# effect's scale (Tin of Pet Food, Dinner Bell).
func pet_damage_mult() -> float:
	return (1.0 + stats.pet_damage_bonus) * effects.pet_damage_scale()
```

- [ ] **Step 8: Run the tests**

Run: `-- --only=test_pets`, `-- --only=item_system`
Expected: PASS.

- [ ] **Step 9: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/core/shot_guards.gd scripts/world/shot_guard.gd scripts/world/pet.gd scripts/items/pet_effect.gd scripts/core/run_state.gd scripts/core/run_effects.gd scripts/actors/projectile.gd tests/support/scale_effect.gd tests/test_pets.gd
git commit -m "Add pets that follow Harold and shot guards that stop shots" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Set bonuses, and retiring the pair combos

**Files:**
- Create: `scripts/content/set_def.gd`, `tests/test_sets.gd` (the `data/sets/` folder comes with the sets themselves in Task 23; `Content.sets()` copes with it missing)
- Modify: `scripts/content/content.gd`, `scripts/core/run_effects.gd`, `scripts/core/player_stats.gd`, `scripts/core/run_state.gd`, `scripts/autoload/progress.gd`, `scripts/scenes/floor_scene.gd`, `scripts/ui/hud.gd`, `scripts/content/retired_content.gd`, `tests/test_run_checkpoint.gd`, `tests/test_items_batch1.gd`, `tests/test_items_batch2.gd`, `tests/test_items_batch3.gd`, `tests/test_items_batch4.gd`

**Interfaces:**
- Consumes: `ItemDef.build`, `is_pet()` (Task 1); `RunState.active` (Task 3); `_seat_pet` (Task 5).
- Produces: `SetDef` (`id`, `display_name`, `description`, `build`, `needed := 3`, `effect`, `count_in(items, active := null) -> int`, `is_met(items, active := null) -> bool`); `Content.SETS_DIR := "res://data/sets/"`, `Content.sets() -> Array[SetDef]`; `RunEffects.set_formed(set_def)` signal, `set_sets(defs)`, `active_sets() -> Array[SetDef]`, `has_set(id) -> bool`, `set_names() -> PackedStringArray`, `bonus_names() -> PackedStringArray` (combos then sets), `restore_sets(ids)`, `effect_of(id)` also finds a set's effect; `effects.save_state()` gains `"formed_sets"` (ids) and `"sets"` (states); `PlayerStats.compute(..., combos, sets: Array[SetDef] = [])`; `Hud.SET_BANNER_TEXT`, `Hud.set_banner_text(name)`, `Hud.show_set(name)`.

- [ ] **Step 1: Write the failing test** `tests/test_sets.gd`

```gdscript
extends TestCase

const Counting := preload("res://tests/support/counting_effect.gd")


func _item(id: String, build: String, kind := ItemDef.KIND_PASSIVE) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	item.display_name = id.capitalize()
	item.build = build
	item.kind = kind
	return item


func _set(id: String, build: String) -> SetDef:
	var def := SetDef.new()
	def.id = id
	def.display_name = id.capitalize()
	def.build = build
	return def


func _run_with_sets(defs: Array[SetDef]) -> RunState:
	var run := ItemKit.new().make_run()
	run.effects.set_sets(defs)
	return run


func test_a_set_forms_at_three_of_its_build_and_only_once() -> void:
	var run := _run_with_sets([_set("tea", "thermos")] as Array[SetDef])
	var formed: Array = []
	run.effects.set_formed.connect(func(def: SetDef): formed.append(def.id))
	run.add_item(_item("a", "thermos"))
	run.add_item(_item("b", "thermos"))
	run.add_item(_item("c", "slip"))
	assert_false(run.effects.has_set("tea"))
	run.add_item(_item("d", "thermos"))
	assert_true(run.effects.has_set("tea"))
	run.add_item(_item("e", "thermos"))
	assert_eq(formed, ["tea"])


func test_the_held_active_counts_for_its_build() -> void:
	var run := _run_with_sets([_set("clerk", "slip")] as Array[SetDef])
	run.add_item(_item("a", "slip"))
	run.add_item(_item("b", "slip"))
	run.add_item(_item("desk", "slip", ItemDef.KIND_ACTIVE))
	assert_true(run.effects.has_set("clerk"))


func test_the_pets_set_counts_pet_items_only() -> void:
	var run := _run_with_sets([_set("lover", "pets")] as Array[SetDef])
	run.add_item(_item("treats", "pets"))
	run.add_item(_item("p1", "pets", ItemDef.KIND_PET))
	run.add_item(_item("p2", "pets", ItemDef.KIND_PET))
	assert_false(run.effects.has_set("lover"), "a pets-build passive is no pet")
	run.add_item(_item("p3", "pets", ItemDef.KIND_PET))
	assert_true(run.effects.has_set("lover"))


func test_a_sets_stats_count_and_its_effect_runs_after_the_items() -> void:
	var spry := _set("spry", "dodge")
	spry.bonus_dodge_charges = 1
	spry.effect = Counting.new()
	var run := _run_with_sets([spry] as Array[SetDef])
	for id in ["a", "b", "c"]:
		run.add_item(_item(id, "dodge"))
	assert_eq(run.stats.dodge_charges, 2)
	run.effects.tick(0.1)
	var copy = run.effects.effect_of("spry")
	assert_eq(int(copy.counts.get("tick", 0)), 1)
	assert_eq(int(copy.counts.get("gain", 0)), 1)


func test_a_formed_set_stays_after_a_swap_and_comes_back_on_a_resume() -> void:
	var clerk := _set("clerk", "slip")
	var run := _run_with_sets([clerk] as Array[SetDef])
	run.add_item(_item("a", "slip"))
	run.add_item(_item("b", "slip"))
	var desk := _item("desk", "slip", ItemDef.KIND_ACTIVE)
	run.add_item(desk)
	var bell := _item("bell", "pets", ItemDef.KIND_ACTIVE)
	run.add_item(bell)
	assert_true(run.effects.has_set("clerk"), "a swap never unforms it")
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run)))
	var back := ItemKit.new().make_run()
	back.effects.set_sets([clerk] as Array[SetDef])
	var shipped: Array[ItemDef] = [run.items[0], run.items[1], desk, bell]
	RunCheckpoint.apply_run(back, raw, shipped)
	assert_true(back.effects.has_set("clerk"))


func test_the_banner_names_the_set_and_the_summary_lists_it() -> void:
	assert_eq(Hud.set_banner_text("Tea Lady"), "SET: Tea Lady")
	var run := _run_with_sets([_set("tea", "thermos")] as Array[SetDef])
	for id in ["a", "b", "c"]:
		run.add_item(_item(id, "thermos"))
	assert_true(run.effects.bonus_names().has("Tea"))


func test_the_old_pair_combos_are_retired_and_runs_know_the_sets() -> void:
	assert_true(Content.combos().is_empty())
	assert_eq(RetiredContent.RETIRED_COMBOS.size(), 12)
	assert_true(FileAccess.get_file_as_string("res://scripts/autoload/progress.gd").contains("run.effects.set_sets(Content.sets())"))
	assert_true(FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd").contains("_run.effects.set_formed.connect(_on_set_formed)"))
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=test_sets`
Expected: FAIL (`SetDef` not declared).

- [ ] **Step 3: SetDef.** Create `scripts/content/set_def.gd`:

```gdscript
class_name SetDef
extends StatEffect

# A set bonus: holding `needed` items of one build adds its stats and runs its effect, after the items'
# and combos'. The held active counts for its build; the pets set counts pet items (kind pet) instead.
# A set forms once per run, the moment the count is reached, and stays.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var build: String = ""
@export var needed: int = 3
@export var effect: ItemEffect


func count_in(items: Array[ItemDef], active: ItemDef = null) -> int:
	var held: Array[ItemDef] = items.duplicate()
	if active != null:
		held.append(active)
	var count := 0
	for item in held:
		if build == "pets":
			if item.is_pet():
				count += 1
		elif item.build == build:
			count += 1
	return count


func is_met(items: Array[ItemDef], active: ItemDef = null) -> bool:
	return count_in(items, active) >= needed
```

In `scripts/content/content.gd`: `const SETS_DIR := "res://data/sets/"` and

```gdscript
# An empty or missing folder gives none.
static func sets() -> Array[SetDef]:
	var list: Array[SetDef] = []
	if not DirAccess.dir_exists_absolute(SETS_DIR):
		return list
	for resource in load_dir(SETS_DIR):
		if resource is SetDef:
			list.append(resource)
	return list
```

- [ ] **Step 4: RunEffects.** In `scripts/core/run_effects.gd` add `signal set_formed(set_def: SetDef)` and

```gdscript
var _set_defs: Array[SetDef] = []
var _sets: Array[SetDef] = []
# Each entry is [set id, its ItemEffect copy].
var _set_effects: Array = []


func set_sets(defs: Array[SetDef]) -> void:
	_set_defs = defs
	_form_sets()


func active_sets() -> Array[SetDef]:
	return _sets


func has_set(id: String) -> bool:
	for def in _sets:
		if def.id == id:
			return true
	return false


func set_names() -> PackedStringArray:
	var names := PackedStringArray()
	for def in _sets:
		names.append(def.display_name)
	return names


# The combos' and sets' names, for the big map's summary.
func bonus_names() -> PackedStringArray:
	var names := combo_names()
	names.append_array(set_names())
	return names


# A resumed run's sets, formed again by id without a second on_gain, whatever the count is now.
func restore_sets(ids: Array) -> void:
	for id in ids:
		for def in _set_defs:
			if def.id == str(id) and not _sets.has(def):
				_form_set(def, false)


func _form_sets(gain := true) -> void:
	var run := _run()
	if run == null:
		return
	for def in _set_defs:
		if not _sets.has(def) and def.is_met(run.items, run.active):
			_form_set(def, gain)
			set_formed.emit(def)


func _form_set(def: SetDef, gain: bool) -> void:
	_sets.append(def)
	if def.effect == null:
		return
	var copy: ItemEffect = def.effect.duplicate()
	_seat_pet(copy)
	_set_effects.append([def.id, copy])
	if gain:
		copy.on_gain(ctx)
```

Call `_form_sets(gain)` at the end of `add()` and at the end of `set_active()`. `clear()` also clears `_sets` and `_set_effects`. `_all()` appends each `_set_effects` entry's effect after the combo effects. `effect_of(id)` also searches `_set_effects`. `save_state()` adds `"formed_sets": ` the ids of `_sets` and `"sets": ` id → state for non-empty states. `load_state(raw)` starts with `restore_sets(raw.get("formed_sets", []) if raw.get("formed_sets", []) is Array else [])` and then hands each set effect its state from `raw.get("sets", {})` as the combos do.

- [ ] **Step 5: Stats.** `PlayerStats.compute(upgrades, levels, items, choices := {}, combos: Array[ComboDef] = [], sets: Array[SetDef] = [])`: after the combos loop, `for set_def in sets: effects.append([set_def, 1])`. In `RunState.refresh_stats()` pass `effects.active_sets()` as the sixth argument.

- [ ] **Step 6: Wiring.** `scripts/autoload/progress.gd` `make_run()`: after `run.effects.set_combos(Content.combos())` add `run.effects.set_sets(Content.sets())`. `scripts/ui/hud.gd`: `const SET_BANNER_TEXT := "SET: %s"`, `static func set_banner_text(set_name: String) -> String: return SET_BANNER_TEXT % set_name`, and

```gdscript
func show_set(set_name: String) -> void:
	_banner.text = set_banner_text(set_name)
	_banner_left = BANNER_TIME
```

`scripts/scenes/floor_scene.gd`: beside the combo connection, `_run.effects.set_formed.connect(_on_set_formed)`; change both `_big_map.combo_names = _run.effects.combo_names()` lines to `bonus_names()`; add

```gdscript
func _on_set_formed(set_def: SetDef) -> void:
	_hud.show_set(set_def.display_name)
	_big_map.combo_names = _run.effects.bonus_names()
```

- [ ] **Step 7: Retire the combos.** In `scripts/content/retired_content.gd`:

```gdscript
# The pair combos of the hundred items. The new list's set bonuses take their place; ComboDef stays.
const RETIRED_COMBOS: Array[String] = ["bingo_night", "card_shark", "dentists_nightmare", "early_riser",
	"family_visit", "full_set", "last_rites", "mobility_scooter", "night_shift", "paper_trail",
	"retirement_plan", "soup_of_the_day"]
```

Delete these test functions, whose shipped combos are retired: in `tests/test_items_batch1.gd` `test_full_set_makes_both_sets_bite_through_three`, `test_dentists_nightmare_knocks_a_coin_out_each_glued_second`, `test_bingo_night_heals_half_a_pill_on_every_bingo`; in `tests/test_items_batch2.gd` `test_mobility_scooter_lays_a_fire_trail_that_burns_now_and_then`; in `tests/test_items_batch3.gd` `test_retirement_plan_pays_half_on_a_death`, `test_soup_of_the_day_keeps_the_puddles_twice_as_long`, `test_card_shark_adds_to_the_poker_table`, `test_last_rites_makes_the_life_jacket_work_twice_a_floor`, `test_night_shift_keeps_the_lights_on`; in `tests/test_items_batch4.gd` `test_family_visit_heals_a_whole_pill_on_a_last_pill_kill_once_a_room`, `test_paper_trail_recharges_the_stamp_in_twenty_seconds`, `test_early_riser_makes_the_rush_last_twenty_seconds`. In `tests/test_run_checkpoint.gd`, rewrite `test_a_resumed_run_gets_its_items_effects_and_combos_back` with a combo of its own:

```gdscript
func test_a_resumed_run_gets_its_items_effects_and_combos_back() -> void:
	var combo := ComboDef.new()
	combo.id = "test_pair"
	combo.item_a = "casserole_dish"
	combo.item_b = "tea_cosy"
	var combos: Array[ComboDef] = [combo]
	var run := _fresh_run()
	run.effects.set_combos(combos)
	run.add_item(_item("casserole_dish"))
	run.add_item(_item("tea_cosy"))
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run)))
	var back := _fresh_run()
	back.effects.set_combos(combos)
	RunCheckpoint.apply_run(back, raw, Content.items())
	assert_true(back.effects.effect_of("casserole_dish") != null, "the item's effect is held again")
	assert_true(back.effects.has_combo("test_pair"), "the combo forms again")
	assert_eq(back.items.size(), 2)
```

- [ ] **Step 8: Run the tests**

Run: `-- --only=test_sets`, `-- --only=combos`, `-- --only=run_checkpoint`, `-- --only=items_batch`
Expected: PASS.

- [ ] **Step 9: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed). If a remaining old test still names a retired combo, delete that test function too and list it in the commit body.

```powershell
git add scripts/content/set_def.gd scripts/content/content.gd scripts/core/run_effects.gd scripts/core/player_stats.gd scripts/core/run_state.gd scripts/autoload/progress.gd scripts/scenes/floor_scene.gd scripts/ui/hud.gd scripts/content/retired_content.gd tests/test_sets.gd tests/test_run_checkpoint.gd tests/test_items_batch1.gd tests/test_items_batch2.gd tests/test_items_batch3.gd tests/test_items_batch4.gd
git commit -m "Add set bonuses and retire the pair combos" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Potion actions, lasting potion effects, the run potion pool and the shop's potion

**Files:**
- Create: `scripts/core/potion_actions.gd`, `scripts/core/potion_pool.gd`, `tests/support/lasting_effect.gd`, `tests/test_run_potions.gd`
- Modify: `scripts/content/potion_def.gd`, `scripts/content/content.gd`, `scripts/core/run_state.gd`, `scripts/core/run_effects.gd`, `scripts/core/run_checkpoint.gd`, `scripts/core/shop_rules.gd`, `scripts/world/room_view.gd`

**Interfaces:**
- Consumes: `RunState.add_bombs/add_keys/scaled_*` (Task 1), `pet_count()` (Task 5), `ItemEffect.is_spent/on_drink` (Task 3).
- Produces: `PotionDef.ACTION_DOUBLE_BOMBS` (`"double_bombs"`), `ACTION_DOUBLE_SLIPS` (`"double_slips"`), `ACTION_SWAP` (`"swap"`), `ACTION_CASH_IN` (`"cash_in"`), `ACTION_SALTS` (`"salts"`), `ACTION_COURAGE` (`"courage"`), `ACTION_PET_FOOD` (`"pet_food"`), `action`, `run_rarity`, `effect`, `is_run_potion()`; `PotionActions.CASH_PER := 10`, `PotionActions.can_drink(run, def) -> bool`, `PotionActions.apply(run, def)`; `PotionPool.SMALL_ID := "small_potion"`, `SMALL_SHARE := 0.55`, `COMMON_SHARE := 0.30`, `SHOP_COMMON_SHARE := 0.7`, `PRICES := {"common": 25, "rare": 40}`, `roll(all, roll_kind, roll_pick) -> PotionDef`, `shop_roll(all, roll_kind, roll_pick) -> PotionDef` (null with no run potion), `shop_price(def, pension_mult) -> int`; `Content.run_potions()`; `RunEffects.add_lasting(potion_id, effect, gain := true)`, `lasting_entries() -> Array` (each `[id, effect]`); `effects.save_state()` gains `"lasting"`; `ShopRules.KIND_POTION := "potion"`, `ShopRules.stock(all_items, run, rng, pension_mult := 1.0, potions: Array[PotionDef] = [])` (a potion entry has `"potion": PotionDef`); `RoomView._drop_potion(at, def)`.

- [ ] **Step 1: Support effect** `tests/support/lasting_effect.gd`

```gdscript
extends ItemEffect

# A test potion part that lasts `rooms` fight-room clears.

@export var rooms := 1
var left := -1


func on_drink(ctx: EffectContext) -> void:
	left = rooms
	ctx.notice("drunk")


func on_room_clear(_ctx: EffectContext, _room: Node, _damage_taken_here: int) -> void:
	left -= 1


func is_spent() -> bool:
	return left == 0


func save_state() -> Dictionary:
	return state_of(["left"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["left"])
```

- [ ] **Step 2: Write the failing test** `tests/test_run_potions.gd`

```gdscript
extends TestCase

const Lasting := preload("res://tests/support/lasting_effect.gd")


func _potion(id: String, action: String, rarity := "common") -> PotionDef:
	var def := PotionDef.new()
	def.id = id
	def.display_name = id.capitalize()
	def.short_name = id
	def.action = action
	def.run_rarity = rarity
	return def


func _drink(run: RunState, def: PotionDef) -> bool:
	run.potion = null
	run.give_potion(def)
	return run.drink_potion()


func test_doubling_never_passes_the_cap_and_waits_while_it_would_do_nothing() -> void:
	var run := ItemKit.new().make_run()
	var brew := _potion("double_test", PotionDef.ACTION_DOUBLE_BOMBS, "rare")
	run.bombs = 0
	assert_false(_drink(run, brew), "doubling nothing waits in the slot")
	run.bombs = 60
	assert_true(_drink(run, brew))
	assert_eq(run.bombs, RunState.MAX_CONSUMABLE)
	run.keys = 4
	assert_true(_drink(run, _potion("tonic_test", PotionDef.ACTION_DOUBLE_SLIPS, "rare")))
	assert_eq(run.keys, 8)


func test_the_swap_waits_on_equal_counts() -> void:
	var run := ItemKit.new().make_run()
	var swap := _potion("swap_test", PotionDef.ACTION_SWAP)
	run.keys = 3
	run.bombs = 3
	assert_false(_drink(run, swap))
	run.bombs = 7
	assert_true(_drink(run, swap))
	assert_eq(run.keys, 7)
	assert_eq(run.bombs, 3)


func test_cash_in_pays_ten_each_counted_up_to_twenty_and_keeps_them() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.keys = 30
	run.bombs = 2
	assert_true(_drink(run, _potion("milk_test", PotionDef.ACTION_CASH_IN, "rare")))
	assert_eq(kit.paid, PotionActions.CASH_PER * (20 + 2))
	assert_eq(run.keys, 30, "he keeps them")
	run.keys = 0
	run.bombs = 0
	assert_false(_drink(run, _potion("milk_test", PotionDef.ACTION_CASH_IN, "rare")))


func test_pet_food_waits_for_a_pet() -> void:
	var run := ItemKit.new().make_run()
	var food := _potion("food_test", PotionDef.ACTION_PET_FOOD)
	assert_false(_drink(run, food))
	var dog := ItemDef.new()
	dog.id = "dog_test"
	dog.kind = ItemDef.KIND_PET
	run.add_item(dog)
	assert_true(_drink(run, food))


func test_a_plain_heal_still_waits_for_a_missing_pill() -> void:
	var run := ItemKit.new().make_run()
	var small := _potion("small_potion", "", "")
	small.heal = 1
	assert_false(_drink(run, small), "full pills")
	run.health.pills -= 1
	assert_true(_drink(run, small))


func test_a_lasting_part_hears_hooks_until_spent_and_is_saved() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var salts := _potion("salts_test", PotionDef.ACTION_SALTS)
	salts.effect = Lasting.new()
	assert_true(_drink(run, salts))
	assert_eq(kit.notices, ["drunk"] as Array[String])
	assert_eq(run.effects.lasting_entries().size(), 1)
	var saved: Dictionary = run.effects.save_state()
	assert_eq(saved["lasting"][0]["id"], "salts_test")
	run.effects.room_clear(null)
	assert_eq(run.effects.lasting_entries().size(), 0, "spent after its room")


func test_the_potion_pool_rolls_small_common_and_rare() -> void:
	var small := _potion("small_potion", "", "")
	small.heal = 1
	var common := _potion("common_test", PotionDef.ACTION_SWAP, "common")
	var rare := _potion("rare_test", PotionDef.ACTION_DOUBLE_BOMBS, "rare")
	var all: Array[PotionDef] = [small, common, rare]
	assert_eq(PotionPool.roll(all, 0.0, 0.5), small)
	assert_eq(PotionPool.roll(all, 0.54, 0.5), small)
	assert_eq(PotionPool.roll(all, 0.56, 0.5), common)
	assert_eq(PotionPool.roll(all, 0.86, 0.5), rare)
	var only_small: Array[PotionDef] = [small]
	assert_eq(PotionPool.roll(only_small, 0.9, 0.5), small, "no run potion: the small one")
	assert_eq(PotionPool.shop_roll(all, 0.69, 0.0), common)
	assert_eq(PotionPool.shop_roll(all, 0.71, 0.0), rare)
	assert_true(PotionPool.shop_roll(only_small, 0.1, 0.0) == null)
	assert_eq(PotionPool.shop_price(common, 1.0), 25)
	assert_eq(PotionPool.shop_price(rare, 2.0), 80)


func test_shops_sell_one_run_potion_when_there_are_any() -> void:
	var run := ItemKit.new().make_run()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var small := _potion("small_potion", "", "")
	var all: Array[PotionDef] = [small, _potion("common_test", PotionDef.ACTION_SWAP), _potion("rare_test", PotionDef.ACTION_DOUBLE_BOMBS, "rare")]
	var stock := ShopRules.stock(Content.items(), run, rng, 1.0, all)
	var potions := stock.filter(func(entry): return entry["kind"] == ShopRules.KIND_POTION)
	assert_eq(potions.size(), 1)
	assert_true((potions[0]["potion"] as PotionDef).is_run_potion())
	var plain := ShopRules.stock(Content.items(), run, rng, 1.0)
	assert_eq(plain.filter(func(entry): return entry["kind"] == ShopRules.KIND_POTION).size(), 0)


func test_the_room_rolls_its_potion_drops_and_sells_potions() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(source.contains("PotionPool.roll(Content.potions(), _rng.randf(), _rng.randf())"))
	assert_true(source.contains("ShopRules.KIND_POTION:"))
	assert_true(source.contains("ShopRules.stock(Content.items(), _run, _rng, _floor_def.pension_mult, Content.potions())"))
```

- [ ] **Step 3: Run it to see it fail**

Run: `-- --only=run_potions`
Expected: FAIL.

- [ ] **Step 4: PotionDef.** Add to `scripts/content/potion_def.gd`:

```gdscript
const ACTION_DOUBLE_BOMBS := "double_bombs"
const ACTION_DOUBLE_SLIPS := "double_slips"
const ACTION_SWAP := "swap"
const ACTION_CASH_IN := "cash_in"
const ACTION_SALTS := "salts"
const ACTION_COURAGE := "courage"
const ACTION_PET_FOOD := "pet_food"

# What drinking does beyond a heal or a timed buff (PotionActions), "" for none.
@export var action := ""
# common or rare: found in runs (PotionPool). "" for a potion no run finds or sells.
@export var run_rarity := ""
# What lasts after drinking (Smelling Salts, Dutch Courage, Tin of Pet Food): a copy joins the run's
# effects until it says it is spent.
@export var effect: ItemEffect


func is_run_potion() -> bool:
	return not run_rarity.is_empty()
```

In `content.gd` add `static func run_potions() -> Array[PotionDef]` returning `potions()` filtered by `is_run_potion()`.

- [ ] **Step 5: PotionActions.** Create `scripts/core/potion_actions.gd`:

```gdscript
class_name PotionActions
extends RefCounted

# What the new list's potions do when drunk. A potion that would change nothing waits in its slot, as a
# heal waits at full pills.

const CASH_PER := 10


static func can_drink(run: RunState, def: PotionDef) -> bool:
	match def.action:
		PotionDef.ACTION_DOUBLE_BOMBS:
			return run.bombs > 0 and run.bombs < RunState.MAX_CONSUMABLE
		PotionDef.ACTION_DOUBLE_SLIPS:
			return run.keys > 0 and run.keys < RunState.MAX_CONSUMABLE
		PotionDef.ACTION_SWAP:
			return run.keys != run.bombs
		PotionDef.ACTION_CASH_IN:
			return run.keys + run.bombs > 0
		PotionDef.ACTION_PET_FOOD:
			return run.pet_count() > 0
	return true


static func apply(run: RunState, def: PotionDef) -> void:
	match def.action:
		PotionDef.ACTION_DOUBLE_BOMBS:
			run.add_bombs(run.bombs)
		PotionDef.ACTION_DOUBLE_SLIPS:
			run.add_keys(run.keys)
		PotionDef.ACTION_SWAP:
			var slips := run.keys
			run.keys = run.bombs
			run.bombs = slips
			run.changed.emit()
		PotionDef.ACTION_CASH_IN:
			run.effects.ctx.pay(CASH_PER * (run.scaled_keys() + run.scaled_bombs()))
	if def.effect != null:
		run.effects.add_lasting(def.id, def.effect.duplicate())
```

In `RunState.can_drink_potion()`, before the heal rule: `if not potion.action.is_empty() or potion.effect != null:` / `return PotionActions.can_drink(self, potion)`. In `drink_potion()`, after the buff lines: `if not drunk.action.is_empty() or drunk.effect != null:` / `PotionActions.apply(self, drunk)`.

- [ ] **Step 6: Lasting effects.** In `scripts/core/run_effects.gd`:

```gdscript
# A drunk potion's lasting parts: [potion id, its ItemEffect copy], dropped once spent.
var _lasting: Array = []


func add_lasting(potion_id: String, effect: ItemEffect, gain := true) -> void:
	_lasting.append([potion_id, effect])
	if gain:
		effect.on_drink(ctx)


func lasting_entries() -> Array:
	return _lasting


func _prune_lasting() -> void:
	_lasting = _lasting.filter(func(entry): return not entry[1].is_spent())
```

`_all()` appends each lasting effect last; `clear()` clears `_lasting`; call `_prune_lasting()` at the end of `room_enter`, `room_clear` and `floor_start`; `save_state()` adds `"lasting": ` an Array of `{"id": entry[0], "state": entry[1].save_state()}`.

In `RunCheckpoint.apply_run`, after `run.effects.load_state(...)`:

```gdscript
	var lasting: Variant = (effects.get("lasting", []) if effects is Dictionary else [])
	if lasting is Array:
		for entry in lasting:
			if not entry is Dictionary:
				continue
			var def := Content.potion(str(entry.get("id", "")))
			if def == null or def.effect == null:
				continue
			var copy: ItemEffect = def.effect.duplicate()
			copy.load_state(entry.get("state", {}) if entry.get("state", {}) is Dictionary else {})
			run.effects.add_lasting(def.id, copy, false)
```

- [ ] **Step 7: The pool.** Create `scripts/core/potion_pool.gd`:

```gdscript
class_name PotionPool
extends RefCounted

# Which potion a potion drop holds, and which one a shop sells. A drop is most often the Small Potion;
# else a run potion of a rolled rarity, picked evenly. Shops sell one run potion. The Waiting Room's
# brews are apart from this.

const SMALL_ID := "small_potion"
const SMALL_SHARE := 0.55
const COMMON_SHARE := 0.30
const SHOP_COMMON_SHARE := 0.7
const PRICES := {"common": 25, "rare": 40}


static func of_rarity(all: Array[PotionDef], rarity: String) -> Array[PotionDef]:
	var list: Array[PotionDef] = []
	for def in all:
		if def.run_rarity == rarity:
			list.append(def)
	return list


static func roll(all: Array[PotionDef], roll_kind: float, roll_pick: float) -> PotionDef:
	var small: PotionDef = null
	for def in all:
		if def.id == SMALL_ID:
			small = def
	if roll_kind < SMALL_SHARE:
		return small
	var picked := _pick(all, "common" if roll_kind < SMALL_SHARE + COMMON_SHARE else "rare", roll_pick)
	return picked if picked != null else small


static func shop_roll(all: Array[PotionDef], roll_kind: float, roll_pick: float) -> PotionDef:
	return _pick(all, "common" if roll_kind < SHOP_COMMON_SHARE else "rare", roll_pick)


static func shop_price(def: PotionDef, pension_mult: float) -> int:
	return maxi(roundi(int(PRICES.get(def.run_rarity, PRICES["common"])) * maxf(pension_mult, 0.0)), 1)


# One of the rarity, or of the other when it has none.
static func _pick(all: Array[PotionDef], rarity: String, roll_pick: float) -> PotionDef:
	var list := of_rarity(all, rarity)
	if list.is_empty():
		list = of_rarity(all, "rare" if rarity == "common" else "common")
	if list.is_empty():
		return null
	return list[clampi(int(roll_pick * list.size()), 0, list.size() - 1)]
```

- [ ] **Step 8: Shops and drops.** `scripts/core/shop_rules.gd`: `const KIND_POTION := "potion"`; `stock(all_items, run, rng, pension_mult := 1.0, potions: Array[PotionDef] = [])`; after the item entries:

```gdscript
	var potion := PotionPool.shop_roll(potions, rng.randf(), rng.randf()) if not potions.is_empty() else null
	if potion != null:
		entries.append({"kind": KIND_POTION, "price": price_after(PotionPool.shop_price(potion, pension_mult), discount), "item": null, "potion": potion})
```

`scripts/world/room_view.gd`:
- `_create_shop()`: `ShopRules.stock(Content.items(), _run, _rng, _floor_def.pension_mult, Content.potions())`.
- `_add_shop_entry()`: add a branch

```gdscript
		ShopRules.KIND_POTION:
			var potion: PotionDef = entry["potion"]
			label = potion.display_name
			color = potion.color
			give = func(): _run.give_potion(potion)
			allowed = _run.can_take_potion
```

  set `pickup.art_id = ART_POTION` for it (add `ShopRules.KIND_POTION: ART_POTION` to `SHOP_ART`), and put the potion's id in the meta: `var item_id: String = entry["item"].id if entry.get("item") != null else (entry["potion"].id if entry.get("potion") != null else "")`.
- `_restore_entry` `KEEP_SHOP`: for `ShopRules.KIND_POTION`, `var potion := Content.potion(str(entry.get("id", "")))`, skip when null, and pass `"potion": potion`.
- `_drop_consumable` `DROP_POTION`: replace the small potion with `_drop_potion(at, PotionPool.roll(Content.potions(), _rng.randf(), _rng.randf()))`, and add

```gdscript
# A potion lying in the room. It fills the potion slot, and waits on the floor while the slot is full.
func _drop_potion(at: Vector2, def: PotionDef) -> Pickup:
	if def == null:
		def = Content.potion(RoomRules.SMALL_POTION_ID)
	var potion := _add_pickup(at, def.display_name, def.color, func(): _take_consumable(func(): _run.give_potion(def)), false, "pill_heal")
	potion.can_take = _run.can_take_potion
	potion.carry_kind = RoomRules.DROP_POTION
	potion.art_id = ART_POTION
	return potion
```

- [ ] **Step 9: Run the tests**

Run: `-- --only=run_potions`, `-- --only=potions`, `-- --only=shop`, `-- --only=consumables`
Expected: PASS. `test_shop` builds stock without potions, so its counts stand.

- [ ] **Step 10: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/content/potion_def.gd scripts/content/content.gd scripts/core/potion_actions.gd scripts/core/potion_pool.gd scripts/core/run_state.gd scripts/core/run_effects.gd scripts/core/run_checkpoint.gd scripts/core/shop_rules.gd scripts/world/room_view.gd tests/support/lasting_effect.gd tests/test_run_potions.gd
git commit -m "Add potion actions, lasting potion effects and the run potion pool" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Play hooks for the new items (pickups, health, enemies, the room's helpers)

**Files:**
- Modify: `scripts/world/room_view.gd`, `scripts/world/pickup.gd`, `scripts/core/health.gd`, `scripts/core/run_state.gd` (`refresh_stats`), `scripts/actors/enemy.gd`, `scripts/core/effect_context.gd`, `scripts/core/chest_rules.gd`, `tests/support/item_kit.gd`
- Create: `tests/test_play_hooks.gd`

**Interfaces:**
- Consumes: stats `half_heal_bonus`, `slip_cost_cut` (Task 1).
- Produces:
  - `RoomView._take_consumable` gives `effects.pickup(kind, 1)` of them; `RoomView.drop_free_item(item, at)`, `RoomView.fetch_nearest_pickup(at) -> bool`, `RoomView.copy_nearest_pickup(at) -> bool`, `static RoomView.nearest_pickup(pickups: Array, at: Vector2, kinds: Array) -> Pickup` (by `fetch_kind`), `static RoomView.nearest_copyable(pickups, at) -> Pickup` (by `copy_kind`); `RoomView._place_coin(at, amount)`.
  - `Pickup.fetch_kind` (`"coin"`, `"key"`, `"bomb"` or ""), `Pickup.copy_kind` (`"coin"`, `"key"`, `"bomb"`, `"heal"`, `"potion"` or ""), `Pickup.copy_amount`, `Pickup.copy_potion`.
  - `Health.lose_half(never_last := true) -> bool` (true when a whole pill went), `Health.half_lost`, `Health.half_heal_bonus`, `Health.heal(amount, from_half := false)`.
  - `Enemy.extra_damage: int`, `Enemy.coin_mult: float`, `Enemy.leaves_item: bool`.
  - `EffectContext.drop_item(item, at)`, `fetcher: Callable -> bool`, `fetch_pickup() -> bool`, `copier: Callable -> bool`, `copy_pickup() -> bool`, `lose_half() -> bool`.
  - `ChestRules.slips_for(kind, cut := 0) -> int`, `ChestRules.can_open(kind, slips, cut := 0)`, `ChestRules.prompt_for(kind, cut := 0)`.
  - ItemKit: `can_fetch`, `fetches`, `can_copy`, `copies`.

- [ ] **Step 1: Write the failing test** `tests/test_play_hooks.gd`

```gdscript
extends TestCase


func test_a_pickup_gives_what_the_items_make_of_it() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	var take := source.substr(source.find("func _take_consumable"), 400)
	assert_true(take.contains("_run.effects.pickup(kind, 1)"))
	assert_true(take.contains("for i in amount"), "every Slip or Thermos the items say comes")


func test_losing_halves_takes_a_pill_every_second_half_and_never_the_last() -> void:
	var health := Health.new(4)
	health.pills = 2
	assert_false(health.lose_half(), "the first half takes nothing yet")
	assert_eq(health.pills, 2)
	assert_true(health.lose_half())
	assert_eq(health.pills, 1)
	health.lose_half()
	assert_false(health.lose_half(), "never his last pill")
	assert_eq(health.pills, 1)


func test_a_half_heal_bonus_adds_half_a_pill_to_every_heal_once() -> void:
	var health := Health.new(8)
	health.pills = 2
	health.half_heal_bonus = true
	health.heal(1)
	assert_eq(health.pills, 3)
	assert_eq(health.half_pills, 1)
	health.heal(1)
	assert_eq(health.pills, 5, "the second half made a pill, with no half added for it")
	assert_eq(health.half_pills, 0)


func test_the_run_hands_the_half_heal_bonus_to_his_health() -> void:
	var run := ItemKit.new().make_run()
	var hypo := ItemDef.new()
	hypo.id = "hypo"
	hypo.half_heal_bonus = true
	run.add_item(hypo)
	assert_true(run.health.half_heal_bonus)


func test_an_enemy_can_hit_harder_and_pay_more() -> void:
	var kit := ItemKit.new()
	var enemy := kit.enemy()
	assert_eq(enemy.attack_damage(), enemy.def.damage)
	enemy.extra_damage = 1
	assert_eq(enemy.attack_damage(), enemy.def.damage + 1)
	assert_eq(enemy.attack_damage(2), 3)
	var coins := enemy.coin_value()
	enemy.coin_mult = 2.0
	assert_eq(enemy.coin_value(), coins * 2)
	assert_false(enemy.leaves_item)
	kit.free_enemies()


func test_the_context_drops_fetches_copies_and_loses_halves() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var ctx := run.effects.ctx
	var item := ItemDef.new()
	item.id = "free_test"
	ctx.drop_item(item, Vector2(5, 5))
	assert_eq(kit.drops, [["item", Vector2(5, 5)]])
	assert_false(ctx.fetch_pickup())
	kit.can_fetch = true
	assert_true(ctx.fetch_pickup())
	assert_eq(kit.fetches, 1)
	assert_false(ctx.copy_pickup())
	kit.can_copy = true
	assert_true(ctx.copy_pickup())
	run.health.pills = 3
	ctx.lose_half()
	ctx.lose_half()
	assert_eq(run.health.pills, 2)
	ctx.counting_pills = true
	ctx.lose_half()
	ctx.lose_half()
	assert_eq(run.health.pills, 2, "the full loop counts pills itself")


func test_the_nearest_pickup_of_a_kind_that_waits() -> void:
	var coin := Pickup.new()
	coin.fetch_kind = "coin"
	coin.position = Vector2(50, 0)
	var slip := Pickup.new()
	slip.fetch_kind = "key"
	slip.copy_kind = "key"
	slip.position = Vector2(20, 0)
	var item := Pickup.new()
	item.position = Vector2(5, 0)
	var all := [coin, slip, item]
	assert_eq(RoomView.nearest_pickup(all, Vector2.ZERO, ["coin", "key", "bomb"]), slip)
	assert_eq(RoomView.nearest_pickup(all, Vector2.ZERO, ["coin"]), coin)
	assert_eq(RoomView.nearest_copyable(all, Vector2.ZERO), slip, "an item is never copied")
	slip.can_take = func() -> bool: return false
	assert_eq(RoomView.nearest_pickup(all, Vector2.ZERO, ["coin", "key"]), coin, "one he cannot take is left")
	for pickup in all:
		pickup.free()


func test_the_apron_takes_a_slip_off_and_never_below_one() -> void:
	assert_eq(ChestRules.slips_for(ChestRules.URN, 1), 1)
	assert_eq(ChestRules.slips_for(ChestRules.URN, 0), 2)
	assert_eq(ChestRules.slips_for(ChestRules.LOCKED, 1), 1)
	assert_eq(ChestRules.slips_for(ChestRules.LUNCHBOX, 1), 0)
	assert_true(ChestRules.can_open(ChestRules.URN, 1, 1))
	assert_false(ChestRules.can_open(ChestRules.URN, 1, 0))
	assert_eq(ChestRules.prompt_for(ChestRules.URN, 1), ChestRules.prompt_for(ChestRules.LOCKED))
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=play_hooks`
Expected: FAIL.

- [ ] **Step 3: Health.** In `scripts/core/health.gd` add

```gdscript
# Halves of a pill lost, from the items that cost half a pill (Unpaid Bill). Two make a pill.
var half_lost := 0
# Whether every heal that restores a pill also heals half a pill (Hypochondriac).
var half_heal_bonus := false
```

change `func heal(amount: int) -> void:` to `func heal(amount: int, from_half := false) -> void:`, keeping its body, and add at its end (before `changed.emit()`, after `pills = ...`):

```gdscript
	if half_heal_bonus and amount > 0 and not from_half and pills < max_pills:
		half_pills += 1
		if half_pills >= 2:
			half_pills = 0
			pills = mini(pills + 1, max_pills)
```

In `heal_half()`, change `heal(1)` to `heal(1, true)`. Add

```gdscript
# Half a pill lost. Every second half takes a whole pill, never the last when never_last is set.
# Returns whether a whole pill went.
func lose_half(never_last := true) -> bool:
	if is_dead():
		return false
	half_lost += 1
	if half_lost < 2:
		return false
	half_lost = 0
	if never_last and pills <= 1:
		return false
	pills = maxi(pills - 1, 0)
	changed.emit()
	if pills == 0:
		died.emit()
	return true
```

In `RunState.refresh_stats()` and `_init`, beside `health.heal_bonus = stats.heal_bonus`: `health.half_heal_bonus = stats.half_heal_bonus`.

- [ ] **Step 4: Enemy.** In `scripts/actors/enemy.gd` add under `var harmless_death`:

```gdscript
# Set by items when the Auditor walks in: more pills a hit costs (Repeat Offender), what his Pension is
# multiplied by, and whether he always leaves an item (Brown Envelope).
var extra_damage := 0
var coin_mult := 1.0
var leaves_item := false
```

`attack_damage` returns `(damage if damage >= 0 else def.damage) + extra_damage`; `coin_value` returns `ceili(def.pension_drop * _pension_mult * coin_mult - 0.0001)`. In `RoomView._on_enemy_defeated`, change the Auditor's item line to `if enemy.def.id == AUDITOR_ID and (enemy.leaves_item or _rng.randf() < AUDIT_ITEM_CHANCE):`.

- [ ] **Step 5: Pickup fields.** In `scripts/world/pickup.gd` add

```gdscript
# What a Racing Pigeon may fetch ("coin", "key" or "bomb") and what a Photocopier may copy ("coin", "key",
# "bomb", "heal" or "potion"), with a copy's amount and potion. "" for neither.
var fetch_kind := ""
var copy_kind := ""
var copy_amount := 1
var copy_potion: PotionDef
```

- [ ] **Step 6: The context.** In `scripts/core/effect_context.gd` add listeners `var fetcher := Callable()` and `var copier := Callable()` with the comment `# Tests answer fetch_pickup and copy_pickup through these; in play the room does.`, and

```gdscript
# A free item lying in the room at a spot (Lottery Scratcher's rare prize), promised so nothing else
# offers it. Listeners hear it as the kind "item".
func drop_item(item: ItemDef, at: Vector2) -> void:
	if on_drop.is_valid():
		on_drop.call("item", at)
	if has_room():
		room.drop_free_item(item, at)


# Calls the nearest waiting coin, Slip or Thermos to him (Racing Pigeon). Returns whether one came.
func fetch_pickup() -> bool:
	if fetcher.is_valid():
		return bool(fetcher.call())
	return has_room() and room.fetch_nearest_pickup(feet())


# Lays a copy of the waiting pickup nearest him (Photocopier). Returns whether one was copied.
func copy_pickup() -> bool:
	if copier.is_valid():
		return bool(copier.call())
	return has_room() and room.copy_nearest_pickup(feet())


# Half a pill off him (Unpaid Bill), never his last. Nothing while the full loop counts pills.
func lose_half() -> bool:
	var state := run()
	if state == null or counting_pills:
		return false
	return state.health.lose_half(true)
```

In `tests/support/item_kit.gd` add `var can_fetch := false`, `var fetches := 0`, `var can_copy := false`, `var copies := 0`; in `wire()`: `ctx.fetcher = _on_fetch` and `ctx.copier = _on_copy`; and

```gdscript
func _on_fetch() -> bool:
	if can_fetch:
		fetches += 1
	return can_fetch


func _on_copy() -> bool:
	if can_copy:
		copies += 1
	return can_copy
```

- [ ] **Step 7: The room.** In `scripts/world/room_view.gd`:
  - `_take_consumable(add: Callable, kind := "")` becomes

    ```gdscript
    # kind is the RunEffects pickup kind the items hear, or "" for one they do not. The items may make one
    # pickup more than one (In Triplicate); each still respects the hold cap.
    func _take_consumable(add: Callable, kind := "") -> void:
    	var amount := 1
    	if not kind.is_empty():
    		amount = maxi(_run.effects.pickup(kind, 1), 0)
    	for i in amount:
    		add.call()
    	consumable_taken.emit()
    ```
  - Split `_drop_coin` so its last part is `_place_coin(at: Vector2, amount: int) -> Pickup` (everything after the amount is worked out); the coin gets `fetch_kind = "coin"`, `copy_kind = "coin"`, `copy_amount = amount`. In `_drop_consumable`, the Slip gets `fetch_kind = "key"` and `copy_kind = "key"`, the Thermos `"bomb"` and `"bomb"`. `_add_heal` sets `copy_kind = "heal"` and `copy_amount = pills`. `_drop_potion` sets `copy_kind = "potion"` and `copy_potion = def`.
  - Add

    ```gdscript
    func drop_free_item(item: ItemDef, at: Vector2) -> void:
    	_run.promise(item)
    	_add_free_item(clear_spot(at), item)


    static func nearest_pickup(pickups: Array, at: Vector2, kinds: Array) -> Pickup:
    	var best: Pickup = null
    	for node in pickups:
    		var pickup := node as Pickup
    		if pickup == null or not pickup.is_waiting() or not kinds.has(pickup.fetch_kind):
    			continue
    		if pickup.can_take.is_valid() and not pickup.can_take.call():
    			continue
    		if best == null or pickup.global_position.distance_to(at) < best.global_position.distance_to(at):
    			best = pickup
    	return best


    static func nearest_copyable(pickups: Array, at: Vector2) -> Pickup:
    	var best: Pickup = null
    	for node in pickups:
    		var pickup := node as Pickup
    		if pickup == null or not pickup.is_waiting() or pickup.copy_kind.is_empty():
    			continue
    		if best == null or pickup.global_position.distance_to(at) < best.global_position.distance_to(at):
    			best = pickup
    	return best


    func fetch_nearest_pickup(at: Vector2) -> bool:
    	var pickup := nearest_pickup(get_children(), at, ["coin", "key", "bomb"])
    	if pickup == null:
    		return false
    	pickup.fly()
    	return true


    func copy_nearest_pickup(at: Vector2) -> bool:
    	var pickup := nearest_copyable(get_children(), at)
    	if pickup == null:
    		return false
    	var spot := clear_spot(pickup.position + Vector2(RoomBackdrop.TILE, 0))
    	match pickup.copy_kind:
    		"coin":
    			_place_coin(spot, pickup.copy_amount)
    		"key":
    			_drop_consumable(spot, RoomRules.DROP_KEY)
    		"bomb":
    			_drop_consumable(spot, RoomRules.DROP_BOMB)
    		"heal":
    			_add_heal(spot, pickup.copy_amount)
    		"potion":
    			_drop_potion(spot, pickup.copy_potion)
    	return true
    ```
  - Slip costs: chests' `can_take` use `ChestRules.can_open(kind, _run.keys, _run.stats.slip_cost_cut)` (and `ChestRules.LOCKED` for the mimic); `_open_locked` and `_open_urn` spend `ChestRules.slips_for(<kind>, _run.stats.slip_cost_cut)`; `chest.prompt = ChestRules.prompt_for(kind, _run.stats.slip_cost_cut)`.

- [ ] **Step 8: ChestRules.** In `scripts/core/chest_rules.gd` add

```gdscript
# What opening costs with cut Slips taken off (Locksmith's Apron): never below one for anything that
# costs a Slip at all.
static func slips_for(kind: String, cut := 0) -> int:
	var need := slips_needed(kind)
	return need if need <= 1 else maxi(need - maxi(cut, 0), 1)
```

and make `can_open(kind, slips, cut := 0)` compare against `slips_for(kind, cut)`, and `prompt_for(kind, cut := 0)` return `PROMPTS[LOCKED]` when `kind == URN and slips_for(kind, cut) == 1`.

- [ ] **Step 9: Run the tests**

Run: `-- --only=play_hooks`, `-- --only=chests`, `-- --only=blocks_and_chests`, `-- --only=consumables`, `-- --only=auditor`
Expected: PASS.

- [ ] **Step 10: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/world/room_view.gd scripts/world/pickup.gd scripts/core/health.gd scripts/core/run_state.gd scripts/actors/enemy.gd scripts/core/effect_context.gd scripts/core/chest_rules.gd tests/support/item_kit.gd tests/test_play_hooks.gd
git commit -m "Add the play hooks the new items need: pickup amounts, half pills, fetch and copy" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Thermos hooks: blast counts, thrown Thermoses, bomblets and the walking frame

**Files:**
- Create: `scripts/world/thrown_thermos.gd`, `scripts/world/bomblet.gd`, `scripts/world/walking_frame.gd`, `tests/test_thermos_hooks.gd`
- Modify: `scripts/world/thermos.gd`, `scripts/world/room_view.gd` (`place_bomb`, `clear_passing_effects`, `is_passing_effect`), `scripts/actors/player.gd` (`aim_point`)

**Interfaces:**
- Consumes: `RunEffects.blast_hits` (Task 3), stat `throws_thermos` (Task 1), `ShotGuards` (Task 5).
- Produces: `Thermos._explode` calls `effects.blast_hits(global_position, hits)`; `Player.aim_point() -> Vector2`; `ThrownThermos.REACH := 160.0`, `FLIGHT := 0.4`, `static landing(from, aim_point, reach := REACH) -> Vector2`, `static height(progress) -> float`; `Bomblet.COUNT := 3`, `SPREAD := 40.0`, `DELAY := 0.35`, `RADIUS := 26.0`, `SHARE := 0.5`, `PUSH := 80.0`, `static spots(at, first_angle) -> Array[Vector2]`, `static burst(ctx, at, damage, radius := RADIUS) -> int`, `static make(ctx, at, damage) -> Bomblet`; `WalkingFrame.AHEAD := 24.0`, `SIZE := Vector2(40, 10)`, `LIFE := 6.0`, `static make(feet, aim) -> WalkingFrame`, `blocks_shot(at) -> bool`.

- [ ] **Step 1: Write the failing test** `tests/test_thermos_hooks.gd`

```gdscript
extends TestCase


func test_a_blast_tells_the_items_how_many_it_hit() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/thermos.gd")
	assert_true(source.contains("effects.blast_hits(global_position, hits)"))


func test_a_thrown_thermos_lands_at_the_aim_point_within_its_reach() -> void:
	assert_eq(ThrownThermos.landing(Vector2.ZERO, Vector2(100, 0)), Vector2(100, 0))
	assert_eq(ThrownThermos.landing(Vector2.ZERO, Vector2(400, 0)), Vector2(ThrownThermos.REACH, 0))
	assert_eq(ThrownThermos.landing(Vector2(10, 10), Vector2(10, 10)), Vector2(10, 10))
	assert_near(ThrownThermos.height(0.0), 0.0)
	assert_near(ThrownThermos.height(1.0), 0.0)
	assert_true(ThrownThermos.height(0.5) > ThrownThermos.height(0.2), "it arcs")


func test_the_room_throws_when_the_stat_says_so() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	var place := source.substr(source.find("func place_bomb"), 900)
	assert_true(place.contains("_run.stats.throws_thermos"))
	assert_true(place.contains("ThrownThermos.landing("))


func test_bomblets_fly_out_evenly_and_burst_on_enemies_only() -> void:
	var spots := Bomblet.spots(Vector2(100, 100), 0.0)
	assert_eq(spots.size(), Bomblet.COUNT)
	for spot in spots:
		assert_near(spot.distance_to(Vector2(100, 100)), Bomblet.SPREAD)
	assert_near(absf(wrapf(spots[1].angle_to_point(Vector2(100, 100)) - spots[0].angle_to_point(Vector2(100, 100)), -PI, PI)), deg_to_rad(120.0))
	var kit := ItemKit.new()
	var run := kit.make_run()
	var near := kit.enemy()
	near.position = Vector2(10, 0)
	var far := kit.enemy()
	far.position = Vector2(100, 0)
	var before := far.hp
	var near_before := near.hp
	assert_eq(Bomblet.burst(run.effects.ctx, Vector2.ZERO, 15.0), 1)
	assert_near(near_before - near.hp, 15.0)
	assert_near(far.hp, before)
	kit.free_enemies()


func test_bomblets_are_passing_effects() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var bomblet := Bomblet.make(run.effects.ctx, Vector2.ZERO, 15.0)
	assert_true(RoomView.is_passing_effect(bomblet))
	bomblet.free()


func test_the_walking_frame_stands_across_his_aim_and_guards() -> void:
	var root: Window = Engine.get_main_loop().root
	var frame := WalkingFrame.make(Vector2(300, 300), Vector2.RIGHT)
	root.add_child(frame)
	assert_eq(frame.global_position, Vector2(300 + WalkingFrame.AHEAD, 300))
	assert_true(frame.blocks_shot(Vector2(300 + WalkingFrame.AHEAD, 310)), "along the frame")
	assert_false(frame.blocks_shot(Vector2(300 + WalkingFrame.AHEAD + 20, 300)), "past its thickness")
	assert_true(frame.blocks_shot(Vector2(300 + WalkingFrame.AHEAD, 310)), "it never runs out")
	assert_true(RoomView.is_passing_effect(frame))
	root.remove_child(frame)
	frame.free()
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=thermos_hooks`
Expected: FAIL.

- [ ] **Step 3: Blast counts.** In `scripts/world/thermos.gd` `_explode()`: add `var hits := 0` before the enemy loop and `hits += 1` inside the `if` that lands a blast on an enemy; after the loop:

```gdscript
	if is_instance_valid(_player) and _player.run != null:
		_player.run.effects.blast_hits(global_position, hits)
```

- [ ] **Step 4: ThrownThermos.** Create `scripts/world/thrown_thermos.gd`:

```gdscript
class_name ThrownThermos
extends Node2D

# The Overarm Bowler's Thermos: thrown in an arc toward the aim point, at most REACH away, stopping at the
# first wall, and bursting where it lands (a Thermos with the Pressure Cooker's extra fuse only).

const REACH := 160.0
const FLIGHT := 0.4
const ARC := 22.0

var from := Vector2.ZERO
var to := Vector2.ZERO
var room: Node
var _age := 0.0


static func landing(start: Vector2, aim_point: Vector2, reach := REACH) -> Vector2:
	var offset := aim_point - start
	if offset.length() <= reach:
		return aim_point
	return start + offset.normalized() * reach


# How high over the ground it flies at this share of its flight.
static func height(progress: float) -> float:
	return 4.0 * ARC * progress * (1.0 - progress)


func _ready() -> void:
	add_to_group(ItemFx.GROUP)
	z_index = ItemFx.Z
	global_position = from


func _process(delta: float) -> void:
	_age += delta
	var progress := clampf(_age / FLIGHT, 0.0, 1.0)
	global_position = from.lerp(to, progress)
	queue_redraw()
	if progress >= 1.0:
		if is_instance_valid(room) and room.has_method("land_thrown_bomb"):
			room.land_thrown_bomb(to)
		queue_free()


func _draw() -> void:
	var lift := Vector2(0, -height(clampf(_age / FLIGHT, 0.0, 1.0)))
	var art := PropArt.texture(Thermos.ART)
	if art != null:
		PropArt.draw(self, art, lift)
		return
	draw_rect(Rect2(lift + Vector2(-5, -9), Vector2(10, 15)), Thermos.BODY_COLOR)
	draw_rect(Rect2(lift + Vector2(-5, -9), Vector2(10, 15)), Color.BLACK, false, 1.0)
```

In `scripts/actors/player.gd` add `func aim_point() -> Vector2: return _aim_point()` (two lines). In `scripts/world/room_view.gd`, rename the body of `place_bomb(at)` to `_place_thermos(at: Vector2, fuse: float)` (the fuse it sets instead of `Thermos.FUSE_TIME + fuse_bonus`), and make `place_bomb`:

```gdscript
func place_bomb(at: Vector2) -> void:
	# The Overarm Bowler throws it; the full loop places and times its Thermoses as they are.
	if _run.stats.throws_thermos and not _run.effects.ctx.counting_exact:
		var wanted := ThrownThermos.landing(at, _player.aim_point())
		var query := PhysicsRayQueryParameters2D.create(at, wanted, 1)
		var wall := get_world_2d().direct_space_state.intersect_ray(query)
		var thrown := ThrownThermos.new()
		thrown.from = at
		thrown.to = wall["position"] - (wanted - at).normalized() * 6.0 if not wall.is_empty() else wanted
		thrown.room = self
		add_child(thrown)
		return
	var fuse := Thermos.FUSE_TIME
	if not _run.effects.ctx.counting_exact:
		fuse += _run.stats.fuse_bonus
	_place_thermos(at, fuse)


# A thrown Thermos has landed: it bursts there, after the Pressure Cooker's extra fuse if he has one.
func land_thrown_bomb(at: Vector2) -> void:
	_place_thermos(at, maxf(_run.stats.fuse_bonus, 0.01))
```

In `clear_passing_effects()`, a `ThrownThermos` still flying gives its Thermos back: `if child is ThrownThermos: _run.add_bomb()`.

- [ ] **Step 5: Bomblets.** Create `scripts/world/bomblet.gd`:

```gdscript
class_name Bomblet
extends Node2D

# Second Brew's little bombs: COUNT fly out SPREAD px from a blast, evenly round it, and each bursts
# DELAY later for SHARE of the Thermos's damage at RADIUS. They hurt enemies only (no props, walls,
# chests or Harold), make no bomblets, and are no Thermos to the other items.

const COUNT := 3
const SPREAD := 40.0
const DELAY := 0.35
const RADIUS := 26.0
const SHARE := 0.5
const PUSH := 80.0
const COLOR := Color("ffb23a")

var ctx: EffectContext
var damage := 0.0
var _left := DELAY
var _burst := false


static func spots(at: Vector2, first_angle: float) -> Array[Vector2]:
	var list: Array[Vector2] = []
	for i in COUNT:
		list.append(at + Vector2.from_angle(first_angle + TAU * i / COUNT) * SPREAD)
	return list


# Hits every enemy within radius of at, as Thermos hits. Returns how many it hit.
static func burst(context: EffectContext, at: Vector2, amount: float, radius := RADIUS) -> int:
	var hit := 0
	for enemy in context.enemies_near(at, radius):
		if context.hit_enemy(enemy, amount, RunEffects.THERMOS, at.direction_to(enemy.global_position) * PUSH):
			hit += 1
	return hit


static func make(context: EffectContext, at: Vector2, amount: float) -> Bomblet:
	var bomblet := Bomblet.new()
	bomblet.ctx = context
	bomblet.damage = amount
	bomblet.position = at
	return bomblet


func _init() -> void:
	add_to_group(ItemFx.GROUP)
	z_index = ItemFx.Z


func _process(delta: float) -> void:
	if _burst:
		return
	_left -= delta
	queue_redraw()
	if _left > 0.0:
		return
	_burst = true
	if ctx != null:
		burst(ctx, global_position, damage)
		ctx.add_fx(ItemFx.make_blast(RADIUS), global_position)
		ctx.play_sound("small_blast")
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, COLOR)
	draw_arc(Vector2.ZERO, 3.0, 0.0, TAU, 10, Color.BLACK, 1.0)
```

- [ ] **Step 6: The walking frame.** Create `scripts/world/walking_frame.gd`:

```gdscript
class_name WalkingFrame
extends Node2D

# The Walking Frame planted AHEAD of him, across his aim, for LIFE seconds: a solid body (collision layer 1)
# that stops enemies, and a shot guard that never runs out. Two uprights and a top rail, never crossing.

const AHEAD := 24.0
const SIZE := Vector2(40, 10)
const LIFE := 6.0
const METAL := Color("c9ced8")
const RUBBER := Color("3a3741")

var _age := 0.0


static func make(feet: Vector2, aim: Vector2) -> WalkingFrame:
	var frame := WalkingFrame.new()
	var way := aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
	frame.position = feet + way * AHEAD
	frame.rotation = way.angle() + PI / 2.0
	return frame


func _init() -> void:
	add_to_group(ShotGuards.GROUP)
	add_to_group(ItemFx.GROUP)
	z_index = ItemFx.Z
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func blocks_shot(at: Vector2) -> bool:
	if not is_inside_tree():
		return false
	return Rect2(-SIZE / 2.0, SIZE).has_point(to_local(at))


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var half := SIZE / 2.0
	draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), METAL, 2.0)
	draw_line(Vector2(-half.x, -half.y), Vector2(-half.x, half.y), METAL, 2.0)
	draw_line(Vector2(half.x, -half.y), Vector2(half.x, half.y), METAL, 2.0)
	draw_circle(Vector2(-half.x, half.y), 1.5, RUBBER)
	draw_circle(Vector2(half.x, half.y), 1.5, RUBBER)
```

(The top rail meets the two uprights only at their ends, an open square bracket shape: no stroke crosses another.)

- [ ] **Step 7: Run the tests**

Run: `-- --only=thermos_hooks`, `-- --only=combat`, `-- --only=item_system`
Expected: PASS.

- [ ] **Step 8: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/world/thrown_thermos.gd scripts/world/bomblet.gd scripts/world/walking_frame.gd scripts/world/thermos.gd scripts/world/room_view.gd scripts/actors/player.gd tests/test_thermos_hooks.gd
git commit -m "Add blast counts, thrown Thermoses, bomblets and the walking frame" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---
### Task 10: Rules and memory hooks: run counts, events, Fine Print's let-off, the ally Auditor, more reels, longer flashbacks, deeper rules

**Files:**
- Create: `scripts/world/ally_auditor.gd`, `tests/support/event_effect.gd`, `tests/test_rule_item_hooks.gd`
- Modify: `scripts/core/run_state.gd` (reels, `rules_posted`), `scripts/core/run_checkpoint.gd` (reels), `scripts/core/rule_picker.gd`, `scripts/world/rule_keeper.gd`, `scripts/ui/rule_stamp.gd`, `scripts/ui/reel_slot.gd`, `scripts/ui/hud.gd` (reel count), `scripts/world/room_rules.gd` (`offerable`), `scripts/world/room_view.gd` (`call_ally_auditor`, `_tick_audit`), `scripts/scenes/floor_scene.gd` (`_on_rule_broken`), `scripts/core/run_effects.gd` (event names)

**Interfaces:**
- Consumes: `RunState.rules_kept/rules_broken/flashbacks_played/floor_depth` (Task 1); stats `extra_rule_rooms`, `bonus_kept_reels`, `extra_reels`, `extra_era_rooms` (Task 1); `RunEffects.excuses_rule_break`, `sides_with_you`, `auditor`, `ALLY` (Task 3); `Pet.step_toward` (Task 5).
- Produces: `RunEffects.EVENT_RULE_KEPT := "rule_kept"`, `EVENT_RULE_BROKEN := "rule_broken"`, `EVENT_FLASHBACK_START := "flashback_start"`, `EVENT_FLASHBACK_END := "flashback_end"`; `RunState.held_reels: Array[String]`, `held_reel` (property), `reel_cap() -> int`, `rules_posted() -> bool`; checkpoint key `"held_reels"`; `RulePicker.rule_room_count(depth, combat_rooms, enabled_depth := ENABLED_DEPTH, extra := 0)`, `RulePicker.rule_rooms(map, depth, seed_text, extra := 0)`; `RuleKeeper.ERA_WAITING := -2`, `era_waiting() -> bool`, `_claim_era_room(room_id)`; `RuleStamp.KIND_WARNING := "warning"`; `ReelSlot.text_for(era, key, count := 1)`, `ReelSlot.show_reel(era, key, count := 1)`; `AllyAuditor` (`SPEED 90`, `REACH 36`, `SWING_EVERY 1.2`, `DAMAGE 12`, `make(ctx)`, `pick_target(from, enemies)`, `step(delta)`); `RoomView.call_ally_auditor(from_door)`.

- [ ] **Step 1: Support effect** `tests/support/event_effect.gd`

```gdscript
extends ItemEffect

# A test effect that notes every event, lets a few rule breaks off, and may side with him.

@export var excuses := 0
@export var sides := false
var events: Array[String] = []


func on_event(_ctx: EffectContext, event_name: String) -> void:
	events.append(event_name)


func excuses_rule_break(_ctx: EffectContext) -> bool:
	if excuses > 0:
		excuses -= 1
		return true
	return false


func sides_with_you(_ctx: EffectContext) -> bool:
	return sides
```

- [ ] **Step 2: Write the failing test** `tests/test_rule_item_hooks.gd`

```gdscript
extends TestCase

const EventEffect := preload("res://tests/support/event_effect.gd")


func _stat(id: String) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	return item


func _run_with_events(excuses := 0) -> RunState:
	var run := ItemKit.new().make_run()
	var item := _stat("events")
	var effect := EventEffect.new()
	effect.excuses = excuses
	item.effect = effect
	run.add_item(item)
	return run


func test_he_holds_as_many_reels_as_his_cap() -> void:
	var run := ItemKit.new().make_run()
	assert_eq(run.reel_cap(), 1)
	assert_true(run.give_reel(Eras.FOOTBALL))
	assert_false(run.give_reel(Eras.BUS), "one memory at a time")
	var album := _stat("album")
	album.extra_reels = 1
	run.add_item(album)
	assert_true(run.give_reel(Eras.BUS))
	assert_eq(run.held_reels.size(), 2)
	assert_eq(run.held_reel, Eras.FOOTBALL)
	assert_eq(run.take_reel(), Eras.FOOTBALL)
	assert_eq(run.held_reel, Eras.BUS)
	run.held_reel = ""
	assert_true(run.held_reels.is_empty())


func test_two_reels_survive_the_checkpoint_and_an_old_one_loads() -> void:
	var album := _stat("album")
	album.extra_reels = 1
	var run := ItemKit.new().make_run()
	run.add_item(album)
	run.give_reel(Eras.FOOTBALL)
	run.give_reel(Eras.BUS)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run)))
	var back := ItemKit.new().make_run()
	var shipped: Array[ItemDef] = [album]
	RunCheckpoint.apply_run(back, raw, shipped)
	assert_eq(back.held_reels, [Eras.FOOTBALL, Eras.BUS] as Array[String])
	var old := ItemKit.new().make_run()
	RunCheckpoint.apply_run(old, {"held_reel": Eras.BUS}, Content.items())
	assert_eq(old.held_reel, Eras.BUS)


func test_the_reel_slot_says_how_many() -> void:
	assert_eq(ReelSlot.text_for(Eras.BUS, "F"), "[F]")
	assert_eq(ReelSlot.text_for(Eras.BUS, "F", 2), "[F] x2")
	assert_eq(ReelSlot.text_for("", "F", 0), "")


func test_extra_rule_rooms_post_rules_deeper_too() -> void:
	assert_eq(RulePicker.rule_room_count(3, 6, 1, 0), 0)
	assert_eq(RulePicker.rule_room_count(3, 6, 1, 1), 1)
	assert_eq(RulePicker.rule_room_count(1, 6, 1, 1), 2)
	assert_eq(RulePicker.rule_room_count(1, 1, 1, 1), 1, "never more than the floor's combat rooms")


func test_rules_items_are_offered_only_where_rules_are_posted() -> void:
	var run := ItemKit.new().make_run()
	var badge := _stat("badge_test")
	badge.build = "rules"
	var reel := _stat("reel_test")
	reel.build = "memory"
	var plain := _stat("plain_test")
	var all: Array[ItemDef] = [badge, reel, plain]
	run.floor_depth = 1
	assert_eq(RoomRules.offerable(all, run).size(), 3)
	run.floor_depth = 2
	assert_eq(RoomRules.offerable(all, run), [plain] as Array[ItemDef])
	var book := _stat("book")
	book.extra_rule_rooms = 1
	run.add_item(book)
	assert_true(run.rules_posted())
	assert_eq(RoomRules.offerable(all, run).size(), 3)


func test_a_broken_rule_counts_tells_the_items_and_can_be_let_off() -> void:
	var run := _run_with_events(1)
	var keeper := RuleKeeper.new()
	keeper._run = run
	keeper.set_watch(4, RuleWatch.new(RoomRule.NO_HORSEPLAY))
	keeper.current_id = 4
	var calls: Array = []
	keeper.rule_broken.connect(func(_view): calls.append(1))
	keeper.report(RoomRule.ACTION_DODGE)
	assert_eq(calls.size(), 0, "let off with a warning: no Auditor")
	assert_eq(run.rules_broken, 1, "it still counts as broken")
	assert_eq(run.effects.effect_of("events").events, [RunEffects.EVENT_RULE_BROKEN] as Array[String])
	keeper.set_watch(5, RuleWatch.new(RoomRule.NO_HORSEPLAY))
	keeper.current_id = 5
	keeper.report(RoomRule.ACTION_DODGE)
	assert_eq(calls.size(), 1)
	assert_eq(run.rules_broken, 2)
	keeper.free()


func test_a_kept_rule_counts_and_tells_the_items() -> void:
	var run := _run_with_events()
	var keeper := RuleKeeper.new()
	keeper._run = run
	keeper.set_watch(4, RuleWatch.new(RoomRule.NO_HORSEPLAY))
	var view := RoomView.new()
	keeper._on_room_finished(view, 4)
	assert_eq(run.rules_kept, 1)
	assert_true(run.effects.effect_of("events").events.has(RunEffects.EVENT_RULE_KEPT))
	view.free()
	keeper.free()


func test_an_old_projector_keeps_the_era_into_one_more_fight_room() -> void:
	var run := _run_with_events()
	var projector := _stat("projector")
	projector.extra_era_rooms = 1
	run.add_item(projector)
	var keeper := RuleKeeper.new()
	keeper._run = run
	var view := RoomView.new()
	keeper._start_era(Eras.FOOTBALL, 4)
	assert_eq(run.flashbacks_played, 1)
	keeper._on_room_finished(view, 4)
	assert_eq(run.era, Eras.FOOTBALL, "it goes on")
	assert_true(keeper.era_waiting())
	keeper._claim_era_room(9)
	assert_false(keeper.era_waiting())
	keeper._on_room_finished(view, 9)
	assert_eq(run.era, "", "it ends after one more room")
	var events: Array[String] = run.effects.effect_of("events").events
	assert_eq(events, [RunEffects.EVENT_FLASHBACK_START, RunEffects.EVENT_FLASHBACK_END] as Array[String])
	view.free()
	keeper.free()


func test_the_warning_stamp_reads_warning() -> void:
	assert_eq(RuleStamp.text_of(RuleStamp.KIND_WARNING), "WARNING")
	assert_true(RuleStamp.KIND_COLORS.has(RuleStamp.KIND_WARNING))


func test_the_ally_auditor_walks_up_and_swings_on_his_own_time() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var ally := AllyAuditor.make(run.effects.ctx)
	var near := kit.enemy()
	near.position = Vector2(20, 0)
	var before := near.hp
	ally.step(0.1)
	assert_near(before - near.hp, AllyAuditor.DAMAGE)
	ally.step(0.1)
	assert_near(before - near.hp, AllyAuditor.DAMAGE, "he swings every 1.2 s")
	ally.step(AllyAuditor.SWING_EVERY)
	assert_near(before - near.hp, AllyAuditor.DAMAGE * 2.0)
	near.position = Vector2(400, 0)
	ally.step(1.0)
	assert_near(ally.position.x, AllyAuditor.SPEED, "he walks toward the nearest enemy")
	ally.free()
	kit.free_enemies()


func test_the_scene_and_room_wire_the_auditor_items() -> void:
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(scene.contains("_run.effects.sides_with_you()"))
	assert_true(scene.contains("view.call_ally_auditor("))
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(room.contains("_run.effects.auditor(auditor)"))
	var keeper := FileAccess.get_file_as_string("res://scripts/world/rule_keeper.gd")
	assert_true(keeper.contains("RulePicker.rule_rooms(map, depth, seed_text, _run.stats.extra_rule_rooms if _run != null else 0)"))
```

- [ ] **Step 3: Run it to see it fail**

Run: `-- --only=rule_item_hooks`
Expected: FAIL.

- [ ] **Step 4: Events.** In `scripts/core/run_effects.gd` beside `EVENT_BINGO`:

```gdscript
# The room rules and flashbacks tell the items through event() as well.
const EVENT_RULE_KEPT := "rule_kept"
const EVENT_RULE_BROKEN := "rule_broken"
const EVENT_FLASHBACK_START := "flashback_start"
const EVENT_FLASHBACK_END := "flashback_end"
```

- [ ] **Step 5: Reels and rules_posted.** In `scripts/core/run_state.gd` replace `var held_reel := ""` with

```gdscript
# The film reels he carries (Eras ids), at most reel_cap(): one memory at a time unless an item says more.
# held_reel is the first, as the HUD, the keeper and older checkpoints know it. The checkpoint keeps them.
var held_reels: Array[String] = []
var held_reel: String:
	get:
		return held_reels[0] if not held_reels.is_empty() else ""
	set(value):
		held_reels.clear()
		if not value.is_empty():
			held_reels.append(value)
```

and replace `give_reel` / `take_reel` with

```gdscript
func reel_cap() -> int:
	return 1 + stats.extra_reels


# A reel past his cap is wasted, on purpose, to reward using them.
func give_reel(era_id: String) -> bool:
	if held_reels.size() >= reel_cap():
		return false
	held_reels.append(era_id)
	changed.emit()
	return true


func take_reel() -> String:
	var reel := "" if held_reels.is_empty() else held_reels.pop_front()
	changed.emit()
	return reel


# Whether this floor posts room rules, for the rules and memory items (RoomRules.offerable).
func rules_posted() -> bool:
	return floor_depth <= RulePicker.ENABLED_DEPTH or stats.extra_rule_rooms > 0
```

In `RunCheckpoint.run_to_dict` keep `"held_reel"` as it is and add

```gdscript
		"held_reels": _reels_to_keep(run),
```

with

```gdscript
# The reels held, and the era being lived when a slot is free for it, as the single held_reel did.
static func _reels_to_keep(run: RunState) -> Array:
	var reels: Array = Array(run.held_reels)
	if not run.era.is_empty() and reels.size() < run.reel_cap():
		reels.append(run.era)
	return reels
```

In `apply_run`, replace the two `held_reel` lines with

```gdscript
	var reels: Variant = raw.get("held_reels", null)
	run.held_reels.clear()
	if reels is Array:
		for reel in reels:
			if Eras.is_known(str(reel)) and run.held_reels.size() < run.reel_cap():
				run.held_reels.append(str(reel))
	else:
		var reel := str(raw.get("held_reel", ""))
		run.held_reel = reel if Eras.is_known(reel) else ""
```

- [ ] **Step 6: The reel slot.** `ReelSlot.text_for(era, key, count := 1)` returns `""` for an empty era, else `"[%s]" % key` plus `" x%d" % count` when `count > 1`. `show_reel(era, key, count := 1)` passes the count. In `Hud._refresh()`: `_reel_slot.show_reel(_run.held_reel, _reel_key, _run.held_reels.size())`.

- [ ] **Step 7: Rule rooms.** In `scripts/core/rule_picker.gd`:

```gdscript
# extra more rooms on every floor (By the Book), deeper floors too, never more than its combat rooms.
static func rule_room_count(depth: int, combat_rooms: int, enabled_depth := ENABLED_DEPTH, extra := 0) -> int:
	if combat_rooms <= 0:
		return 0
	var wanted: int = 0 if depth > enabled_depth else BY_DEPTH.get(depth, maxi(DEEP_MIN, roundi(combat_rooms * DEEP_SHARE)))
	return mini(wanted + maxi(extra, 0), combat_rooms)
```

and `rule_rooms(map, depth, seed_text, extra := 0)` passes `rule_room_count(depth, combat.size(), ENABLED_DEPTH, extra)`. In `RuleKeeper.plan_floor`, `_rule_rooms = RulePicker.rule_rooms(map, depth, seed_text, _run.stats.extra_rule_rooms if _run != null else 0)`.

- [ ] **Step 8: The keeper.** In `scripts/world/rule_keeper.gd`:
  - add `const ERA_WAITING := -2` (an era whose room cleared and that waits for its next fight room) and `var _era_rooms_left := 0`;
  - `report()` becomes

    ```gdscript
    func report(action: String) -> void:
    	var watch := watch_of(current_id)
    	if watch == null or not watch.report(action):
    		return
    	Sfx.play("rule_whistle")
    	if _record_rule.is_valid():
    		_record_rule.call(false)
    	if _run != null:
    		_run.rules_broken += 1
    		_run.effects.event(RunEffects.EVENT_RULE_BROKEN)
    	# Fine Print lets the first break of a floor off: no Auditor, a warning stamp.
    	var excused := _run != null and _run.effects.excuses_rule_break()
    	if _hud != null:
    		_hud.stamp_rule(RuleStamp.KIND_WARNING if excused else RuleStamp.KIND_VIOLATION)
    		_hud.break_rule()
    	if not excused:
    		rule_broken.emit(_view)
    ```
  - in `_on_room_finished`, replace `if _era_room == room_id: _end_era()` with

    ```gdscript
    	if _era_room == room_id:
    		if _era_rooms_left > 0:
    			_era_rooms_left -= 1
    			_era_room = ERA_WAITING
    		else:
    			_end_era()
    ```

    and in its `if kept:` branch, before `rule_kept.emit(...)`: `if _run != null:` / `_run.rules_kept += 1` / `_run.effects.event(RunEffects.EVENT_RULE_KEPT)`;
  - in `on_room_entered`, after the readied-door block: `if first_visit and view.is_fighting():` / `_claim_era_room(room.id)`;
  - add

    ```gdscript
    func era_waiting() -> bool:
    	return _era_room == ERA_WAITING


    # A longer flashback (Old Projector) takes the next fight room he walks into for the first time.
    func _claim_era_room(room_id: int) -> void:
    	if _era_room == ERA_WAITING:
    		_era_room = room_id
    ```
  - `_start_era`: after `_era_room = room_id`: `_era_rooms_left = _run.stats.extra_era_rooms if _run != null else 0`, and after `era_started.emit(era)`: `if _run != null:` / `_run.flashbacks_played += 1` / `_run.effects.event(RunEffects.EVENT_FLASHBACK_START)`;
  - `_end_era`: before `_stop_era()`: `if _run != null:` / `_run.effects.event(RunEffects.EVENT_FLASHBACK_END)`;
  - `_on_rule_kept`: drop `1 + _run.stats.bonus_kept_reels` reels: the first exactly as today (`Eras.pick(_unlocked, _seed, current_id)`), each further one with `Eras.pick(_unlocked, "%s:%d" % [_seed, i], current_id)`.

- [ ] **Step 9: The stamp.** In `scripts/ui/rule_stamp.gd`: `const KIND_WARNING := "warning"`, add `KIND_WARNING: Color("5b6b85")` to `KIND_COLORS`, and `KIND_WARNING: return "WARNING"` in `text_of`.

- [ ] **Step 10: Offering.** In `RoomRules.offerable`, inside the loop before the `can_offer` check: `if item.needs_rules() and not run.rules_posted():` / `continue`.

- [ ] **Step 11: The Auditor items.** Create `scripts/world/ally_auditor.gd`:

```gdscript
class_name AllyAuditor
extends Node2D

# Clipboard of Your Own: the Auditor on Harold's side for the rest of a room. He walks to the enemy nearest
# him and swings his clipboard at it every SWING_EVERY for DAMAGE, an ally hit. He cannot be hurt and is
# no enemy, so the room clears without him; it frees him then (RoomView), and leaving the room clears him.
# Drawn in code, a grey suit with a clipboard, until art exists.

const SPEED := 90.0
const REACH := 36.0
const SWING_EVERY := 1.2
const DAMAGE := 12.0
const PUSH := 80.0
const SUIT := Color("4a4f5c")
const SKIN := Color("e0b48c")
const CLIPBOARD := Color("b48a5a")
const PAPER := Color("efe6cf")
const LABEL_TIME := 1.5

var ctx: EffectContext
var _cooldown := 0.0
var _age := 0.0


static func make(context: EffectContext) -> AllyAuditor:
	var ally := AllyAuditor.new()
	ally.ctx = context
	return ally


static func pick_target(from: Vector2, enemies: Array[Enemy]) -> Enemy:
	var best: Enemy = null
	for enemy in enemies:
		if best == null or enemy.global_position.distance_to(from) < best.global_position.distance_to(from):
			best = enemy
	return best


func _init() -> void:
	add_to_group(ItemFx.GROUP)
	z_index = ItemFx.Z


# One step of his fight: walk, or swing once his clipboard is ready.
func step(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if ctx == null:
		return
	var target := pick_target(global_position, ctx.enemies())
	if target == null:
		return
	if global_position.distance_to(target.global_position) > REACH:
		global_position = Pet.step_toward(global_position, target.global_position, SPEED, delta)
	elif _cooldown <= 0.0 and not ctx.counting_exact:
		_cooldown = SWING_EVERY
		ctx.hit_enemy(target, DAMAGE, RunEffects.ALLY, global_position.direction_to(target.global_position) * PUSH)


func _process(delta: float) -> void:
	_age += delta
	step(delta)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-6, -8, 12, 16), SUIT)
	draw_circle(Vector2(0, -12), 4.0, SKIN)
	draw_rect(Rect2(5, -4, 7, 9), CLIPBOARD)
	draw_rect(Rect2(6, -2, 5, 6), PAPER)
	if _age < LABEL_TIME:
		Npc._draw_centered(self, tr("ON YOUR SIDE"), Vector2(0, -22), Color("7fe0a0"))
```

In `scripts/world/room_view.gd`: add `var _ally_left := -1.0` and `var _ally_door: Door`;

```gdscript
# Clipboard of Your Own: the Auditor walks in on his side after the same wait, and the room stays his to clear.
func call_ally_auditor(from_door: Door) -> void:
	if _audited or _finished:
		return
	_audited = true
	_ally_door = from_door
	_ally_left = AUDIT_DELAY
```

and at the end of `_tick_audit(delta)` handle `_ally_left` the same way as `_audit_left` (count down; at zero spawn `AllyAuditor.make(_run.effects.ctx)` at `summon_spot(_audit_spot_for(_ally_door))`, add it as a child, `finished.connect(ally.queue_free, CONNECT_ONE_SHOT)`, play `door_open`). Factor the door spot out of `_audit_spot()` into `_audit_spot_for(door: Door) -> Vector2` so both use it. Right after the hostile Auditor spawns (`var auditor := _spawn_enemy(_audit_def, at)`), add `_run.effects.auditor(auditor)`.

In `scripts/scenes/floor_scene.gd` `_on_rule_broken`:

```gdscript
	var door := view.door_to(_arrived_from)
	if _run.effects.sides_with_you():
		view.call_ally_auditor(door)
	else:
		view.call_auditor(load(AUDITOR_PATH), door)
```

- [ ] **Step 12: Run the tests**

Run: `-- --only=rule_item_hooks`, `-- --only=rule_keeper`, `-- --only=rule_picker`, `-- --only=reels`, `-- --only=auditor`, `-- --only=rule_hud`, `-- --only=run_checkpoint`
Expected: PASS.

- [ ] **Step 13: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/world/ally_auditor.gd scripts/core/run_state.gd scripts/core/run_checkpoint.gd scripts/core/rule_picker.gd scripts/world/rule_keeper.gd scripts/ui/rule_stamp.gd scripts/ui/reel_slot.gd scripts/ui/hud.gd scripts/world/room_rules.gd scripts/world/room_view.gd scripts/scenes/floor_scene.gd scripts/core/run_effects.gd tests/support/event_effect.gd tests/test_rule_item_hooks.gd
git commit -m "Add the rules and memory hooks the new items need" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Phase B: the items, by build

Each batch task follows the same shape: new `.tres` files from the template, scripts in `scripts/items/`, kept items rewritten in place, renamed old ids added to `RetiredContent.RETIRED_ITEMS`, the old tests that assert a changed rule retired, one new test file, then the suite and a commit. "Retire old tests" means: remove each named kept id from the old file's `BATCH` (or `IDS`) dictionary or list, and delete each named test function. A kept item keeps its unlock line (`craft_price`, `from_bounty` or `first_clear_path`) as it is. Every new id gets the `CoachTips.TIPS` line its task gives (`scripts/core/coach_tips.gd`; `test_training_yard.test_the_coach_has_a_tip_for_every_item` checks every pool item), added at the end of the `TIPS` dictionary, and every task adds `scripts/core/coach_tips.gd` to its commit.

### Task 11: Thermos items (9)

**Files:**
- Create: `scripts/items/hit_scale_effect.gd`, `scripts/items/tea_urn.gd`, `scripts/items/flask_holster.gd`, `scripts/items/bottomless_flask.gd`, `scripts/items/second_brew.gd`, `scripts/items/tea_break.gd`, `data/items/tea_urn.tres`, `data/items/flask_holster.tres`, `data/items/bottomless_flask.tres`, `data/items/second_brew.tres`, `data/items/thermos_lob.tres`, `data/items/tea_break.tres`, `tests/test_items_thermos.gd`
- Modify: `data/items/hot_soup_thermos.tres`, `data/items/pressure_cooker.tres`, `data/items/tea_cosy.tres`, `scripts/items/hot_soup_thermos.gd`, `scripts/content/retired_content.gd`, `tests/test_items_batch3.gd`, `tests/test_resume_item_state.gd`

**Interfaces:**
- Consumes: `RunState.scaled_bombs`, `add_bombs` (Task 1); `RunEffects.is_his_hit`, `on_blast_hits` (Task 3); `Bomblet` (Task 9); stat `throws_thermos`, `thermos_scale_bonus` (Task 1).
- Produces: `HitScaleEffect` (class_name; `bonus(ctx) -> float`; multiplies his hits by `1 + bonus`), used by Tasks 12, 13, 15, 18, 19, 20, 22.

- [ ] **Step 1: Write the failing test** `tests/test_items_thermos.gd`

```gdscript
extends TestCase

const IDS := {"tea_urn": "legendary", "flask_holster": "common", "bottomless_flask": "rare", "hot_soup_thermos": "rare",
	"pressure_cooker": "rare", "tea_cosy": "common", "second_brew": "rare", "thermos_lob": "legendary", "tea_break": "rare"}


func test_the_thermos_items_ship_as_the_list_says() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "thermos", id)
		assert_eq(item.kind, ItemDef.KIND_PASSIVE, id)
		assert_eq(item.rarity, IDS[id], id)
		assert_eq(Array(item.tags), ["thermos"], id)
		assert_false(item.cursed, id)
	assert_eq(ItemKit.item("thermos_lob").display_name, "Overarm Bowler")
	assert_eq(ItemKit.item("tea_urn").description, "Every Thermos you carry makes all your hits 5% harder.")
	assert_true(RetiredContent.is_retired("second_thermos_strap"))


func test_tea_urn_adds_five_percent_per_thermos_counted() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["tea_urn"])
	var enemy := kit.enemy()
	run.bombs = 4
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 12.0)
	run.bombs = 50
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.BITE), 20.0, "at most 20 count")
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.PET), 10.0, "a pet's bite is not his hit")
	run.effects.ctx.counting_exact = true
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 10.0)
	kit.free_enemies()


func test_flask_holster_gives_two_and_lets_four_more_count() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var before := run.bombs
	run.add_item(ItemKit.item("flask_holster"))
	assert_eq(run.bombs, before + 2)
	run.bombs = 50
	assert_eq(run.scaled_bombs(), 24)
	run.add_item(ItemKit.item("tea_urn"))
	var enemy := kit.enemy()
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 22.0)
	kit.free_enemies()


func test_bottomless_flask_gives_a_thermos_every_second_clear() -> void:
	var run := ItemKit.new().run_with(["bottomless_flask"])
	run.bombs = 0
	run.effects.room_clear(null)
	assert_eq(run.bombs, 0)
	run.effects.room_clear(null)
	assert_eq(run.bombs, 1)
	run.effects.room_clear(null)
	run.effects.room_clear(null)
	assert_eq(run.bombs, 2)
	assert_eq(run.effects.effect_of("bottomless_flask").save_state(), {"cleared": 4})


func test_hot_soup_lays_a_three_second_puddle_on_every_blast() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["hot_soup_thermos"])
	run.effects.bomb(Vector2.ZERO)
	assert_eq(kit.fx_of(ItemFx.FxSoup).size(), 1)
	assert_near(run.effects.effect_of("hot_soup_thermos").puddle_time(run.effects.ctx), 3.0)


func test_pressure_cooker_is_half_again_as_wide_with_a_longer_fuse() -> void:
	var run := ItemKit.new().run_with(["pressure_cooker"])
	assert_near(run.stats.blast_radius, PlayerStats.BASE_BLAST_RADIUS * 1.5)
	assert_near(run.stats.fuse_bonus, 0.3)


func test_tea_cosy_spares_him_his_own_blasts_only() -> void:
	var run := ItemKit.new().run_with(["tea_cosy"])
	assert_eq(run.effects.hurt(1, RunEffects.HURT_OWN_BLAST), 0)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1)


func test_second_brew_throws_three_bomblets_for_half_the_blast() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["second_brew"])
	run.effects.bomb(Vector2.ZERO)
	assert_eq(kit.fx_of(Bomblet).size(), Bomblet.COUNT)
	run.effects.ctx.counting_exact = true
	run.effects.bomb(Vector2.ZERO)
	assert_eq(kit.fx_of(Bomblet).size(), Bomblet.COUNT, "none while the full loop counts")


func test_overarm_bowler_throws_the_thermos() -> void:
	assert_true(ItemKit.new().run_with(["thermos_lob"]).stats.throws_thermos)
	assert_false(ItemKit.new().make_run().stats.throws_thermos)


func test_tea_break_heals_half_a_pill_for_three_or_more_hit() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["tea_break"])
	run.health.pills = 2
	run.effects.blast_hits(Vector2.ZERO, 2)
	assert_eq(run.health.half_pills, 0)
	run.effects.blast_hits(Vector2.ZERO, 3)
	assert_eq(run.health.half_pills, 1)
	run.effects.blast_hits(Vector2.ZERO, 5)
	assert_eq(run.health.pills, 3)
	assert_eq(kit.fx_of(ItemFx.FxPop).size(), 2)
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=items_thermos`
Expected: FAIL (no `tea_urn` shipped).

- [ ] **Step 3: The shared hit scale.** Create `scripts/items/hit_scale_effect.gd`:

```gdscript
class_name HitScaleEffect
extends ItemEffect

# What the "+N% to all your hits" items share: his own hits (RunEffects.HIS_HITS) are multiplied by
# 1 + bonus(ctx). A pet's bite and the turned Auditor's clipboard are not his hits. The full loop measures
# damage exactly, so there they add nothing.


func bonus(_ctx: EffectContext) -> float:
	return 0.0


func hit_damage(ctx: EffectContext, _enemy: Enemy, amount: float, source: String) -> float:
	if ctx.counting_exact or not RunEffects.is_his_hit(source):
		return amount
	return amount * (1.0 + maxf(bonus(ctx), 0.0))
```

- [ ] **Step 4: The scripts.**

`scripts/items/tea_urn.gd`:

```gdscript
extends HitScaleEffect

# Tea Urn: every Thermos he carries makes his hits PER harder, counting at most the scale cap
# (RunState.scaled_bombs).

const PER := 0.05


func bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	return PER * run.scaled_bombs() if run != null else 0.0
```

`scripts/items/flask_holster.gd`:

```gdscript
extends ItemEffect

# Flask Holster: two Thermoses the moment it is taken; its stats let the Thermos items count four more.

const AT_ONCE := 2


func on_gain(ctx: EffectContext) -> void:
	var run := ctx.run()
	if run != null:
		run.add_bombs(AT_ONCE)
```

`scripts/items/bottomless_flask.gd`:

```gdscript
extends ItemEffect

# Bottomless Flask: every EVERY-th fight room cleared gives a Thermos back, with a pop. The full loop
# counts Thermoses as the rooms give them, so there it gives none.

const EVERY := 2
const TEXT := "+1 THERMOS"
var cleared := 0


func on_room_clear(ctx: EffectContext, _room: Node, _damage_taken_here: int) -> void:
	cleared += 1
	var run := ctx.run()
	if cleared % EVERY != 0 or run == null or ctx.counting_exact:
		return
	run.add_bombs(1)
	ctx.add_fx(ItemFx.make_pop(TEXT), ctx.feet())
	ctx.play_sound("thermos_pickup")


func save_state() -> Dictionary:
	return state_of(["cleared"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["cleared"])
```

`scripts/items/second_brew.gd`:

```gdscript
extends ItemEffect

# Second Brew: when one of his Thermoses explodes, Bomblet.COUNT little bombs fly out and burst a moment
# later for half its damage, enemies only. Bomblets are no Thermos to the other items and never make
# bomblets. The full loop measures each blast, so there none fly.


func on_bomb(ctx: EffectContext, at: Vector2) -> void:
	if ctx.counting_exact:
		return
	var run := ctx.run()
	var damage := Thermos.DAMAGE * (run.stats.thermos_damage_mult if run != null else 1.0) * Bomblet.SHARE
	for spot in Bomblet.spots(at, randf() * TAU):
		ctx.add_fx(Bomblet.make(ctx, spot, damage), spot)
```

`scripts/items/tea_break.gd`:

```gdscript
extends ItemEffect

# Tea Break: a blast of his that lands on MOST or more enemies heals half a pill.

const MOST := 3
const TEXT := "TEA BREAK"
const COLOR := Color("c98a4b")


func on_blast_hits(ctx: EffectContext, _at: Vector2, count: int) -> void:
	if count < MOST or ctx.counting_pills:
		return
	ctx.heal_half()
	ctx.add_fx(ItemFx.make_pop(TEXT, COLOR), ctx.feet())
	ctx.play_sound("pill_heal")
```

In `scripts/items/hot_soup_thermos.gd`, drop `COMBO` and the combo branch: `puddle_time(_ctx)` returns `TIME`; update the header comment to drop the Strap.

- [ ] **Step 5: The data.** New files from the template (build `thermos`, tags `["thermos"]`, kind `passive`, description = the list's text):
  - `tea_urn.tres`: "Tea Urn", legendary, script `tea_urn.gd`.
  - `flask_holster.tres`: "Flask Holster", common, script `flask_holster.gd`, `thermos_scale_bonus = 4`.
  - `bottomless_flask.tres`: "Bottomless Flask", rare, script `bottomless_flask.gd`.
  - `second_brew.tres`: "Second Brew", rare, script `second_brew.gd`, description "When a Thermos explodes, a few little bombs fly out and go off a second time." (the review's change).
  - `thermos_lob.tres`: "Overarm Bowler", legendary, no script, `throws_thermos = true`.
  - `tea_break.tres`: "Tea Break", rare, script `tea_break.gd`.
  Kept, rewritten in place (keep each one's `craft_price`): `hot_soup_thermos.tres` (description from the list, `tags = PackedStringArray("thermos")`, `build = "thermos"`, `kind = "passive"`); `pressure_cooker.tres` (same, and `blast_radius_bonus = 0.5`); `tea_cosy.tres` (same).

Coach tips:

```gdscript
	"tea_urn": "Carry your Thermoses, don't throw the lot. Every one in your pocket hits for you.",
	"flask_holster": "More straps, more flasks. Hoard them and the urn counts the lot.",
	"bottomless_flask": "Clear two rooms, get one back. Keep moving.",
	"second_brew": "Blast the middle of a crowd. The little ones see to the edges.",
	"thermos_lob": "Aim and let it fly. Just don't stand where it lands.",
	"tea_break": "Wait till three are in the blast. Then put the kettle on.",
```

- [ ] **Step 6: Retire and fix old tests.** `RetiredContent.RETIRED_ITEMS` gets `"second_thermos_strap"`. In `tests/test_resume_item_state.gd`, `_resume()` passes `Content.all_items()` to `apply_run` (old ids still resume in old tests until Task 26). Retire old tests in `tests/test_items_batch3.gd`: remove `hot_soup_thermos`, `pressure_cooker`, `tea_cosy` from `BATCH`; delete `test_hot_soup_lays_a_burning_puddle_that_spares_nobody_but_him`, `test_pressure_cooker_widens_the_blast_and_lengthens_the_fuse`, `test_tea_cosy_takes_only_his_own_blasts`.

- [ ] **Step 7: Run the tests**

Run: `-- --only=items_thermos`, `-- --only=items_batch3`, `-- --only=resume_item_state`, `-- --only=item_unlocks`, `-- --only=reworked_items`
Expected: PASS.

- [ ] **Step 8: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/items/hit_scale_effect.gd scripts/items/tea_urn.gd scripts/items/flask_holster.gd scripts/items/bottomless_flask.gd scripts/items/second_brew.gd scripts/items/tea_break.gd scripts/items/hot_soup_thermos.gd data/items/tea_urn.tres data/items/flask_holster.tres data/items/bottomless_flask.tres data/items/second_brew.tres data/items/thermos_lob.tres data/items/tea_break.tres data/items/hot_soup_thermos.tres data/items/pressure_cooker.tres data/items/tea_cosy.tres scripts/content/retired_content.gd tests/test_items_thermos.gd tests/test_items_batch3.gd tests/test_resume_item_state.gd
git commit -m "Add the Thermos build's items" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 12: Slip items (8)

**Files:**
- Create: `scripts/items/filing_cabinet.gd`, `scripts/items/in_triplicate.gd`, `scripts/items/key_cutter.gd`, `scripts/items/loose_paperwork.gd`, `scripts/items/rubber_stamp_collection.gd`, `scripts/items/paper_cuts.gd`, `scripts/items/desk_drawer.gd`, and `data/items/` `filing_cabinet.tres`, `in_triplicate.tres`, `key_cutter.tres`, `loose_paperwork.tres`, `rubber_stamp_collection.tres`, `paper_cuts.tres`, `locksmiths_apron.tres`, `desk_drawer.tres`, `tests/test_items_slips.gd`
- Modify: `scripts/content/retired_content.gd`

**Interfaces:**
- Consumes: `HitScaleEffect` (Task 11); `RunState.scaled_keys`, `add_keys`, `add_bombs` (Task 1); `ShotGuard` (Task 5); stat `slip_cost_cut` (Task 1, read by ChestRules in Task 8).

- [ ] **Step 1: Write the failing test** `tests/test_items_slips.gd`

```gdscript
extends TestCase

const IDS := {"filing_cabinet": "legendary", "in_triplicate": "rare", "key_cutter": "common", "loose_paperwork": "rare",
	"rubber_stamp_collection": "common", "paper_cuts": "rare", "locksmiths_apron": "common", "desk_drawer": "rare"}


func _finisher() -> SwingAttack:
	return SwingAttack.new(Vector2.RIGHT, 44.0, 60.0, 18.0, 60.0, false, true)


func _plain_swing() -> SwingAttack:
	return SwingAttack.new(Vector2.RIGHT, 44.0, 60.0, 10.0, 60.0, false, false)


func test_the_slip_items_ship_as_the_list_says() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "slip", id)
		assert_eq(item.rarity, IDS[id], id)
		assert_eq(Array(item.tags), ["slip"], id)
	assert_eq(ItemKit.item("rubber_stamp_collection").first_clear_path, "floor_1", "it takes the old stamps' source")
	assert_true(RetiredContent.is_retired("rubber_stamps"))


func test_filing_cabinet_adds_five_percent_per_slip_counted() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["filing_cabinet"])
	var enemy := kit.enemy()
	run.keys = 6
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 13.0)
	run.keys = 99
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.THERMOS), 20.0, "at most 20 count")
	kit.free_enemies()


func test_in_triplicate_makes_each_slip_two() -> void:
	var run := ItemKit.new().run_with(["in_triplicate"])
	assert_eq(run.effects.pickup(RunEffects.SLIP, 1), 2)
	assert_eq(run.effects.pickup(RunEffects.BOMB, 1), 1)


func test_key_cutter_gives_three_now_and_one_each_floor() -> void:
	var run := ItemKit.new().make_run()
	run.keys = 0
	run.add_item(ItemKit.item("key_cutter"))
	assert_eq(run.keys, 3)
	run.effects.floor_start()
	assert_eq(run.keys, 4)


func test_loose_paperwork_lays_one_sheet_per_slip_up_to_five_each_room() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["loose_paperwork"])
	var paper = run.effects.effect_of("loose_paperwork")
	run.keys = 7
	run.effects.room_enter(null)
	assert_eq(paper.sheets, 5)
	for i in 5:
		assert_true(paper.has_sheet())
		paper.use_sheet()
	assert_false(paper.has_sheet(), "gone until the next room")
	run.keys = 2
	run.effects.room_enter(null)
	assert_eq(paper.sheets, 2)


func test_the_stamp_collection_pays_fifteen_a_slip() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["rubber_stamp_collection"])
	run.keys = 2
	run.use_key()
	run.use_key()
	assert_eq(kit.paid, 30)
	assert_eq(kit.sounds, ["form_filed", "form_filed"] as Array[String])


func test_paper_cuts_fling_a_slip_with_each_finisher_only() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["paper_cuts"])
	run.keys = 3
	run.effects.swing(_plain_swing())
	assert_eq(kit.fx_of(ItemFx.FxNeedle).size(), 0)
	run.effects.swing(_finisher())
	assert_eq(kit.fx_of(ItemFx.FxNeedle).size(), 1)
	assert_eq(run.keys, 3, "it costs no Slip")


func test_locksmiths_apron_takes_a_slip_off() -> void:
	assert_eq(ItemKit.new().run_with(["locksmiths_apron"]).stats.slip_cost_cut, 1)


func test_desk_drawer_links_the_first_slip_and_thermos_of_each_room() -> void:
	var run := ItemKit.new().run_with(["desk_drawer"])
	run.keys = 0
	run.bombs = 0
	run.effects.room_enter(null)
	run.effects.pickup(RunEffects.SLIP, 1)
	assert_eq(run.bombs, 1)
	run.effects.pickup(RunEffects.SLIP, 1)
	assert_eq(run.bombs, 1, "once a room")
	run.effects.pickup(RunEffects.BOMB, 1)
	assert_eq(run.keys, 1)
	run.effects.room_enter(null)
	run.effects.pickup(RunEffects.SLIP, 1)
	assert_eq(run.bombs, 2)
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=items_slips`
Expected: FAIL.

- [ ] **Step 3: The scripts.**

`scripts/items/filing_cabinet.gd`:

```gdscript
extends HitScaleEffect

# Filing Cabinet: the Slip twin of the Tea Urn. Every Slip he carries makes his hits PER harder, counting
# at most PlayerStats.SCALE_CAP.

const PER := 0.05


func bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	return PER * run.scaled_keys() if run != null else 0.0
```

`scripts/items/in_triplicate.gd`:

```gdscript
extends ItemEffect

# In Triplicate: every Slip picked up or bought counts as two. The full loop counts Slips exactly.


func on_pickup(ctx: EffectContext, kind: String, amount: int) -> int:
	if kind == RunEffects.SLIP and not ctx.counting_exact:
		return amount * 2
	return amount
```

`scripts/items/key_cutter.gd`:

```gdscript
extends ItemEffect

# Duplicate Key Cutter: three Slips the moment it is taken, and one more at every floor start (never a landing).

const AT_ONCE := 3
const EACH_FLOOR := 1


func on_gain(ctx: EffectContext) -> void:
	var run := ctx.run()
	if run != null:
		run.add_keys(AT_ONCE)


func on_floor_start(ctx: EffectContext) -> void:
	var run := ctx.run()
	if run != null and not ctx.is_landing() and not ctx.counting_exact:
		run.add_keys(EACH_FLOOR)
```

`scripts/items/loose_paperwork.gd`:

```gdscript
extends ItemEffect

# Loose Paperwork: on entering a room he gets a sheet per Slip carried, at most MOST. The sheets circle him
# and each stops one shot (a shot guard round him), and are gone until the next room. The full loop counts
# every pill a shot costs, so there no sheet blocks.

const MOST := 5
const REACH := 20.0
const PAPER := Color("f2ecd8")
var sheets := 0
var _guard: WeakRef
# Kept for has_sheet, which the guard calls with no context. Safe: the run owns this effect, and the
# context holds the run weakly.
var _ctx: EffectContext


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	_ctx = ctx
	var run := ctx.run()
	sheets = mini(run.keys, MOST) if run != null else 0
	var guard := PaperSheets.new()
	guard.radius = REACH
	guard.check = has_sheet
	guard.spend = use_sheet
	guard.owner_effect = weakref(self)
	guard.follow = ctx.player if ctx.has_player() else null
	var placed := ctx.add_fx(guard, ctx.feet())
	_guard = weakref(placed) if placed != null else null


func has_sheet() -> bool:
	return sheets > 0 and not (_ctx != null and _ctx.counting_pills)


func use_sheet() -> void:
	sheets = maxi(sheets - 1, 0)


# The sheets round him, drawn as small pale rectangles turning slowly.
class PaperSheets extends ShotGuard:
	var owner_effect: WeakRef
	var _turn := 0.0

	func _process(delta: float) -> void:
		super(delta)
		_turn += delta * 2.0

	func _draw() -> void:
		var effect = owner_effect.get_ref() if owner_effect != null else null
		var count: int = effect.sheets if effect != null else 0
		for i in count:
			var at := Vector2.from_angle(_turn + TAU * i / maxf(count, 1)) * radius
			draw_set_transform(at, _turn + i, Vector2.ONE)
			draw_rect(Rect2(-3, -2, 6, 4), Color("f2ecd8"))
			draw_rect(Rect2(-3, -2, 6, 4), Color(0.3, 0.27, 0.2), false, 1.0)
		draw_set_transform(Vector2.ZERO)
```

`scripts/items/rubber_stamp_collection.gd`:

```gdscript
extends ItemEffect

# Rubber Stamp Collection: every Slip handed over pays PAY Pension, kept or not, with a stamp over his head.
# Slips only open what a floor has locked, so this cannot be farmed.

const PAY := 15
const INK := Color("e0307a")


func on_slip_spent(ctx: EffectContext, _kept: bool) -> void:
	ctx.pay(PAY)
	ctx.add_fx(ItemFx.make_pop("APPROVED +%d" % PAY, INK), ctx.feet())
	ctx.play_sound("form_filed")
```

`scripts/items/paper_cuts.gd`:

```gdscript
extends ItemEffect

# Paper Cuts: every combo finisher also flings a paper slip forward that cuts every enemy in its line,
# for free. A flashback's own moves fling nothing.

const DAMAGE := 14.0
const DISTANCE := 180.0
const SPEED := 320.0
const AHEAD := 14.0
const PAPER := Color("f2ecd8")


func on_swing(ctx: EffectContext, swing: SwingAttack) -> void:
	if not swing.finisher or swing.from_era:
		return
	var slip := ItemFx.make_needle(ctx, swing.direction, DAMAGE, DISTANCE)
	slip.stops_at_first = false
	slip.speed = SPEED
	slip.color = PAPER
	ctx.add_fx(slip, ctx.feet() + swing.direction * AHEAD)
```

`scripts/items/desk_drawer.gd`:

```gdscript
extends ItemEffect

# Desk Drawer: the first Slip he picks up in a room also gives a Thermos, and the first Thermos also gives
# a Slip. The full loop counts both exactly.

var _gave_bomb := false
var _gave_slip := false


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	_gave_bomb = false
	_gave_slip = false


func on_pickup(ctx: EffectContext, kind: String, amount: int) -> int:
	var run := ctx.run()
	if run == null or ctx.counting_exact:
		return amount
	if kind == RunEffects.SLIP and not _gave_bomb:
		_gave_bomb = true
		run.add_bombs(1)
	elif kind == RunEffects.BOMB and not _gave_slip:
		_gave_slip = true
		run.add_keys(1)
	return amount
```

- [ ] **Step 4: The data.** From the template, build `slip`, tags `["slip"]`: `filing_cabinet.tres` ("Filing Cabinet", legendary, description "Every Slip you carry makes all your hits 5% harder."), `in_triplicate.tres` ("In Triplicate", rare), `key_cutter.tres` ("Duplicate Key Cutter", common), `loose_paperwork.tres` ("Loose Paperwork", rare), `rubber_stamp_collection.tres` ("Rubber Stamp Collection", common, `first_clear_path = "floor_1"`), `paper_cuts.tres` ("Paper Cuts", rare), `locksmiths_apron.tres` ("Locksmith's Apron", common, no script, `slip_cost_cut = 1`), `desk_drawer.tres` ("Desk Drawer", rare). `RetiredContent.RETIRED_ITEMS` gets `"rubber_stamps"`. Coach tips:

```gdscript
	"filing_cabinet": "Keep your Slips. Every one in the drawer hits for you.",
	"in_triplicate": "Pick up every Slip you see. Each one counts twice.",
	"key_cutter": "A Slip every floor. Don't hoard what you can spend.",
	"loose_paperwork": "Carry five Slips and the shots can't touch you. Paper's tougher than it looks.",
	"rubber_stamp_collection": "Spend your Slips and get paid for it. Open everything.",
	"paper_cuts": "Finish the combo down a line of them. The slip goes all the way through.",
	"locksmiths_apron": "Urns for one Slip now. Open every one you find.",
	"desk_drawer": "First Slip, a Thermos. First Thermos, a Slip. Pick up both in every room.",
```

- [ ] **Step 5: Run the tests**

Run: `-- --only=items_slips`, `-- --only=item_sounds`, `-- --only=items_batch3`, `-- --only=item_unlocks`
Expected: PASS.

- [ ] **Step 6: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/items/filing_cabinet.gd scripts/items/in_triplicate.gd scripts/items/key_cutter.gd scripts/items/loose_paperwork.gd scripts/items/rubber_stamp_collection.gd scripts/items/paper_cuts.gd scripts/items/desk_drawer.gd data/items/filing_cabinet.tres data/items/in_triplicate.tres data/items/key_cutter.tres data/items/loose_paperwork.tres data/items/rubber_stamp_collection.tres data/items/paper_cuts.tres data/items/locksmiths_apron.tres data/items/desk_drawer.tres scripts/content/retired_content.gd tests/test_items_slips.gd
git commit -m "Add the Slip build's items" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 13: Pension items (9)

**Files:**
- Create: `scripts/items/money_belt.gd`, `scripts/items/piggy_bank.gd`, `scripts/items/compound_interest.gd`, `scripts/items/coin_purse_cane.gd`, `data/items/money_belt.tres`, `data/items/piggy_bank.tres`, `data/items/compound_interest.tres`, `data/items/coin_purse_cane.tres`, `tests/test_items_pension.gd`
- Modify: `data/items/senior_discount.tres`, `data/items/hagglers_hat.tres`, `data/items/coupon_booklet.tres`, `data/items/gold_fillings.tres`, `data/items/inheritance_letter.tres`, `scripts/items/hagglers_hat.gd`, `scripts/items/gold_fillings.gd`, `scripts/items/inheritance_letter.gd`, `scripts/content/retired_content.gd`, `tests/test_items_batch1.gd`, `tests/test_items_batch3.gd`, `tests/test_reworked_items.gd`

**Interfaces:**
- Consumes: `HitScaleEffect` (Task 11); `EffectContext.purse`, `spend_from_purse` (Task 1).

- [ ] **Step 1: Write the failing test** `tests/test_items_pension.gd`

```gdscript
extends TestCase

const IDS := {"money_belt": "legendary", "piggy_bank": "rare", "compound_interest": "rare", "senior_discount": "rare",
	"hagglers_hat": "common", "coupon_booklet": "common", "gold_fillings": "common", "coin_purse_cane": "rare",
	"inheritance_letter": "common"}


func _swing() -> SwingAttack:
	return SwingAttack.new(Vector2.RIGHT, 44.0, 60.0, 10.0, 60.0, false, false)


func test_the_pension_items_ship_as_the_list_says() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "pension", id)
		assert_eq(item.rarity, IDS[id], id)
	assert_eq(ItemKit.item("hagglers_hat").display_name, "Haggler's Hat")
	assert_eq(ItemKit.item("coupon_booklet").display_name, "Coupon Booklet")
	assert_eq(ItemKit.item("compound_interest").first_clear_path, "head_office")
	assert_true(RetiredContent.is_retired("pension_statement"))


func test_money_belt_adds_five_percent_per_fifty_in_the_purse_up_to_half() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["money_belt"])
	var enemy := kit.enemy()
	run.pension_at_start = 100
	kit.pension = 260
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 11.5, "160 in the purse: three fifties")
	kit.pension = 5000
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 15.0, "at most half again")
	kit.free_enemies()


func test_piggy_bank_pays_twenty_a_pill_from_the_purse_instead() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["piggy_bank"])
	run.pension_at_start = 0
	kit.pension = 50
	assert_eq(run.effects.hurt(2, RunEffects.HURT_ENEMY), 0)
	assert_eq(kit.pension, 10)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1, "the purse cannot cover it")
	assert_eq(kit.pension, 10)
	kit.pension = 40
	run.effects.ctx.counting_pills = true
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1, "the full loop counts every pill")


func test_compound_interest_pays_fifteen_percent_of_the_purse_each_floor() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["compound_interest"])
	run.pension_at_start = 0
	kit.pension = 210
	run.effects.floor_start()
	assert_eq(kit.paid, 31)


func test_senior_discount_takes_a_quarter_off() -> void:
	assert_near(ItemKit.new().run_with(["senior_discount"]).stats.shop_discount, 0.25)


func test_hagglers_hat_makes_the_cheapest_item_free() -> void:
	var run := ItemKit.new().run_with(["hagglers_hat"])
	var cheap := ItemKit.item("tea_cosy")
	var dear := ItemKit.item("tea_urn")
	var stock: Array[Dictionary] = [
		{"kind": ShopRules.KIND_ITEM, "price": 175, "item": dear},
		{"kind": ShopRules.KIND_ITEM, "price": 35, "item": cheap},
		{"kind": ShopRules.KIND_HEAL, "price": 20, "item": null},
	]
	run.effects.shop_open(stock)
	assert_eq(stock[1]["price"], 0)
	assert_eq(stock[0]["price"], 175)
	assert_eq(stock[2]["price"], 20, "only items")


func test_coupon_booklet_adds_a_ware() -> void:
	assert_eq(ItemKit.new().run_with(["coupon_booklet"]).stats.shop_extra_items, 1)


func test_gold_fillings_knock_a_coin_loose_one_bite_in_four() -> void:
	var gold := load("res://scripts/items/gold_fillings.gd")
	assert_near(gold.CHANCE, 0.25)


func test_coin_purse_cane_loads_a_coin_per_ten_and_fires_one_a_swing() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["coin_purse_cane"])
	var purse = run.effects.effect_of("coin_purse_cane")
	run.effects.pickup(RunEffects.PENSION, 7)
	assert_eq(purse.loaded, 0)
	run.effects.pickup(RunEffects.PENSION, 25)
	assert_eq(purse.loaded, 3, "at most three")
	run.effects.swing(_swing())
	assert_eq(purse.loaded, 2)
	assert_eq(kit.fx_of(ItemFx.FxNeedle).size(), 1)
	assert_eq(purse.save_state()["loaded"], 2)


func test_inheritance_letter_pays_seventy_five_once() -> void:
	var kit := ItemKit.new()
	kit.run_with(["inheritance_letter"])
	assert_eq(kit.paid, 75)
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=items_pension`
Expected: FAIL.

- [ ] **Step 3: The scripts.**

`scripts/items/money_belt.gd`:

```gdscript
extends HitScaleEffect

# Money Belt: every full STEP Pension in the purse (EffectContext.purse) makes his hits PER harder, at most
# MOST_STEPS of them.

const STEP := 50
const PER := 0.05
const MOST_STEPS := 10


func bonus(ctx: EffectContext) -> float:
	return PER * mini(ctx.purse() / STEP, MOST_STEPS)
```

`scripts/items/piggy_bank.gd`:

```gdscript
extends ItemEffect

# Piggy Bank: a hit that would cost pills costs COST Pension a pill from the purse instead, while the purse
# covers the whole hit. The full loop counts every pill a hit costs, so there it pays nothing.

const COST := 20
const COLOR := Color("ff9fc0")


func on_hurt(ctx: EffectContext, pills: int, _source: String) -> int:
	if pills <= 0 or ctx.counting_pills:
		return pills
	if not ctx.spend_from_purse(COST * pills):
		return pills
	ctx.add_fx(ItemFx.make_pop("-%d" % (COST * pills), COLOR), ctx.feet())
	ctx.play_sound("coin")
	return 0
```

`scripts/items/compound_interest.gd`:

```gdscript
extends ItemEffect

# Compound Interest: every floor start (never a landing) pays SHARE of the purse, rounded down.

const SHARE := 0.15
const GOLD := Color("ffd24a")


func on_floor_start(ctx: EffectContext) -> void:
	if ctx.is_landing() or ctx.counting_exact:
		return
	var pay := floori(ctx.purse() * SHARE)
	if pay <= 0:
		return
	ctx.pay(pay)
	ctx.add_fx(ItemFx.make_pop("+%d INTEREST" % pay, GOLD), ctx.feet())
	ctx.play_sound("coin")
```

`scripts/items/coin_purse_cane.gd`:

```gdscript
extends ItemEffect

# Coin Purse Cane: every PER Pension picked up loads a coin, at most MOST, and his next cane swing fires
# one: a shot that stops at the first enemy. A flashback's own moves fire nothing.

const PER := 10
const MOST := 3
const DAMAGE := 12.0
const DISTANCE := 220.0
const SPEED := 360.0
const AHEAD := 12.0
const GOLD := Color("ffd24a")
var loaded := 0
var _toward := 0


func on_pickup(_ctx: EffectContext, kind: String, amount: int) -> int:
	if kind != RunEffects.PENSION:
		return amount
	_toward += amount
	while _toward >= PER and loaded < MOST:
		_toward -= PER
		loaded += 1
	if loaded >= MOST:
		_toward = 0
	return amount


func on_swing(ctx: EffectContext, swing: SwingAttack) -> void:
	if loaded <= 0 or swing.from_era or ctx.counting_exact:
		return
	loaded -= 1
	var coin := ItemFx.make_needle(ctx, swing.direction, DAMAGE, DISTANCE)
	coin.stops_at_first = true
	coin.speed = SPEED
	coin.color = GOLD
	ctx.add_fx(coin, ctx.feet() + swing.direction * AHEAD)
	ctx.play_sound("coin")


func save_state() -> Dictionary:
	return state_of(["loaded", "_toward"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["loaded", "_toward"])
```

`scripts/items/hagglers_hat.gd`: replace its body so the cheapest item ware's `price` becomes 0 (keep the loop that finds the cheapest `ShopRules.KIND_ITEM` entry; set `entry["price"] = 0` and leave `"half"` unset); header `# Haggler's Hat: the cheapest item for sale in every shop is free. Heals, Slips, Thermoses and potions keep their prices.` `gold_fillings.gd`: `const CHANCE := 0.25`. `inheritance_letter.gd`: `const PAY := 75`.

- [ ] **Step 4: The data.** New (build `pension`, tags `["pension"]`): `money_belt.tres` ("Money Belt", legendary), `piggy_bank.tres` ("Piggy Bank", rare), `compound_interest.tres` ("Compound Interest", rare, `first_clear_path = "head_office"`), `coin_purse_cane.tres` ("Coin Purse Cane", rare). Kept, rewritten in place: `senior_discount.tres`, `hagglers_hat.tres` (display_name "Haggler's Hat"), `coupon_booklet.tres` (display_name "Coupon Booklet"), `gold_fillings.tres`, `inheritance_letter.tres`: list description, `build = "pension"`, `tags = PackedStringArray("pension")`. `RETIRED_ITEMS` gets `"pension_statement"`. Coach tips (the Haggler's Hat's line is replaced, as its rule changed):

```gdscript
	"money_belt": "Bank it, don't spend it. Fat pockets, hard hits.",
	"piggy_bank": "Keep a few tenners in the purse and the knocks cost coins, not pills.",
	"compound_interest": "Carry your money down the stairs. It grows on the way.",
	"coin_purse_cane": "Pick up coins, then swing. The money flies out the end.",
	"hagglers_hat": "One thing in every shop is free. Look for the dearest.",
```

- [ ] **Step 5: Retire old tests.** `tests/test_items_batch1.gd`: remove `gold_fillings` from `BATCH`; delete `test_gold_fillings_knock_a_coin_loose_one_bite_in_five`. `tests/test_items_batch3.gd`: remove `coupon_booklet`, `hagglers_hat`, `inheritance_letter` from `BATCH`; delete `test_hagglers_hat_halves_the_cheapest_item` and `test_inheritance_letter_pays_once_on_taking`. `tests/test_reworked_items.gd`: remove `senior_discount` from `IDS` and from the `rare` and `recipes` lists in `test_rarity_curses_and_sources_follow_the_design`.

- [ ] **Step 6: Run the tests**

Run: `-- --only=items_pension`, `-- --only=items_batch`, `-- --only=reworked_items`, `-- --only=item_sounds`, `-- --only=shop`
Expected: PASS.

- [ ] **Step 7: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/items/money_belt.gd scripts/items/piggy_bank.gd scripts/items/compound_interest.gd scripts/items/coin_purse_cane.gd scripts/items/hagglers_hat.gd scripts/items/gold_fillings.gd scripts/items/inheritance_letter.gd data/items/money_belt.tres data/items/piggy_bank.tres data/items/compound_interest.tres data/items/coin_purse_cane.tres data/items/senior_discount.tres data/items/hagglers_hat.tres data/items/coupon_booklet.tres data/items/gold_fillings.tres data/items/inheritance_letter.tres scripts/content/retired_content.gd tests/test_items_pension.gd tests/test_items_batch1.gd tests/test_items_batch3.gd tests/test_reworked_items.gd
git commit -m "Add the Pension build's items" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---
### Task 14: Pets that fight and fetch (6): Rex, Mittens, the ferret, Old Shep, Polly, the pigeon

**Files:**
- Create: `scripts/items/rex.gd`, `scripts/items/mittens.gd`, `scripts/items/ferret.gd`, `scripts/items/sheepdog.gd`, `scripts/items/parrot.gd`, `scripts/items/racing_pigeon.gd`, `data/items/rex.tres`, `data/items/mittens.tres`, `data/items/ferret.tres`, `data/items/sheepdog.tres`, `data/items/parrot.tres`, `data/items/racing_pigeon.tres`, `tests/test_items_pets_fighting.gd`
- Modify: `scripts/content/retired_content.gd`

**Interfaces:**
- Consumes: `PetEffect` (`nearest`, `strike`, `pet`, `mult`), `Pet` (Task 5); `EffectContext.fetch_pickup` (Task 8); `RunEffects.PET`.

- [ ] **Step 1: Write the failing test** `tests/test_items_pets_fighting.gd`

```gdscript
extends TestCase

const IDS := {"rex": "rare", "mittens": "rare", "ferret": "rare", "sheepdog": "legendary", "parrot": "rare", "racing_pigeon": "common"}


func test_the_fighting_pets_ship_as_pets() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.kind, ItemDef.KIND_PET, id)
		assert_eq(item.build, "pets", id)
		assert_eq(item.rarity, IDS[id], id)
		assert_true(item.effect is PetEffect, id)
	assert_true(RetiredContent.is_retired("penny_jar"))


func test_rex_bites_the_nearest_enemy_every_second() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["rex"])
	var near := kit.enemy()
	near.position = Vector2(100, 0)
	var far := kit.enemy()
	far.position = Vector2(300, 0)
	var before := near.hp
	run.effects.tick(1.0)
	assert_near(before - near.hp, 6.0)
	run.effects.tick(0.5)
	assert_near(before - near.hp, 6.0)
	run.effects.tick(0.5)
	assert_near(before - near.hp, 12.0)
	assert_near(far.hp, far.max_hp(), "out of reach")
	kit.free_enemies()


func test_mittens_finishes_regular_enemies_below_a_quarter() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["mittens"])
	var low := kit.enemy("intern_reaper", 8.0)
	low.position = Vector2(50, 0)
	var healthy := kit.enemy("intern_reaper", 20.0)
	healthy.position = Vector2(40, 0)
	var boss := kit.enemy("regional_reaper")
	boss.hp = boss.max_hp() * 0.1
	boss.position = Vector2(30, 0)
	run.effects.tick(0.5)
	assert_true(low.is_dead())
	assert_false(healthy.is_dead(), "above a quarter")
	assert_false(boss.is_dead(), "never a boss")
	kit.free_enemies()


func test_the_ferret_bites_hard_on_every_dodge() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["ferret"])
	var enemy := kit.enemy()
	enemy.position = Vector2(80, 0)
	var before := enemy.hp
	run.effects.dodge(Vector2.RIGHT)
	assert_near(before - enemy.hp, 15.0)
	kit.free_enemies()


func test_old_shep_herds_regular_enemies_every_six_seconds() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["sheepdog"])
	var stray := kit.enemy()
	stray.position = Vector2(150, 40)
	var boss := kit.enemy("regional_reaper")
	boss.position = Vector2(120, 0)
	run.effects.tick(5.9)
	assert_false(stray.is_pushed())
	run.effects.tick(0.2)
	assert_true(stray.is_pushed())
	assert_true(stray.is_dazed())
	assert_false(boss.is_pushed(), "a boss is not herded")
	kit.free_enemies()


func test_polly_repeats_a_landed_swing_a_second_later_at_half() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["parrot"])
	var enemy := kit.enemy()
	var swing := SwingAttack.new(Vector2.RIGHT, 44.0, 60.0, 10.0, 60.0, false, false)
	run.effects.swing(swing)
	run.effects.hit(enemy, 10.0, RunEffects.SWING)
	run.effects.swing_end(swing)
	var before := enemy.hp
	run.effects.tick(0.5)
	assert_near(enemy.hp, before)
	run.effects.tick(0.6)
	assert_near(before - enemy.hp, 5.0)
	run.effects.tick(2.0)
	assert_near(before - enemy.hp, 5.0, "once")
	kit.free_enemies()


func test_the_pigeon_fetches_a_pickup_now_and_then() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["racing_pigeon"])
	kit.can_fetch = true
	run.effects.tick(1.5)
	assert_eq(kit.fetches, 1)
	run.effects.tick(1.0)
	assert_eq(kit.fetches, 1)
	run.effects.tick(0.5)
	assert_eq(kit.fetches, 2)
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=items_pets_fighting`
Expected: FAIL.

- [ ] **Step 3: The scripts.**

`scripts/items/rex.gd`:

```gdscript
extends PetEffect

# Rex, the Late Dog: every EVERY seconds he bites the enemy nearest Harold within REACH for DAMAGE.

const EVERY := 1.0
const REACH := 160.0
const DAMAGE := 6.0
var _left := EVERY


func tick(ctx: EffectContext, delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	_left = EVERY
	strike(ctx, nearest(ctx, REACH), DAMAGE)
```

`scripts/items/mittens.gd`:

```gdscript
extends PetEffect

# Mittens: every EVERY seconds she finishes the nearest regular enemy within REACH that is below BELOW of
# its health. Never a boss. The full loop counts damage exactly, so there she only watches.

const EVERY := 0.5
const REACH := 200.0
const BELOW := 0.25
var _left := EVERY


func tick(ctx: EffectContext, delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	_left = EVERY
	if ctx.counting_exact:
		return
	var best: Enemy = null
	for enemy in ctx.enemies_near(ctx.feet(), REACH):
		if enemy.def.is_boss or enemy.hp >= enemy.max_hp() * BELOW:
			continue
		if best == null or enemy.global_position.distance_to(ctx.feet()) < best.global_position.distance_to(ctx.feet()):
			best = enemy
	if best == null:
		return
	var body := pet()
	if body != null:
		body.lunge_to(best.global_position)
	ctx.hit_enemy(best, best.hp + 1.0, RunEffects.PET)
```

`scripts/items/ferret.gd`:

```gdscript
extends PetEffect

# Trouser Ferret: every dodge, he leaps out and bites the enemy nearest Harold within REACH for DAMAGE.

const REACH := 120.0
const DAMAGE := 15.0


func on_dodge(ctx: EffectContext, _direction: Vector2) -> void:
	strike(ctx, nearest(ctx, REACH), DAMAGE)
```

`scripts/items/sheepdog.gd`:

```gdscript
extends PetEffect

# Old Shep: every EVERY seconds he herds every regular enemy within REACH toward a spot AHEAD of Harold,
# the way he aims, over TIME, dazing them a moment. No damage. The full loop places its own enemies, so
# there he only watches.

const EVERY := 6.0
const REACH := 220.0
const AHEAD := 64.0
const TIME := 0.35
const DAZE := 0.3
var _left := EVERY


func tick(ctx: EffectContext, delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	_left = EVERY
	if ctx.counting_exact:
		return
	var aim := ctx.player.aim_direction() if ctx.has_player() else Vector2.RIGHT
	var spot := ctx.feet() + aim * AHEAD
	for enemy in ctx.enemies_near(ctx.feet(), REACH):
		if enemy.def.is_boss:
			continue
		enemy.apply_push((spot - enemy.global_position) / TIME, TIME)
		enemy.daze(DAZE)
	var body := pet()
	if body != null:
		body.lunge_to(spot)
```

`scripts/items/parrot.gd`:

```gdscript
extends PetEffect

# Polly the Parrot: DELAY after a cane swing lands, she repeats it: each enemy the swing hit, if still alive,
# takes SHARE of that hit as a pet hit. Only cane swings are copied.

const DELAY := 1.0
const SHARE := 0.5
const SWINGS := [RunEffects.SWING, RunEffects.CHARGE, RunEffects.COMBO_3]
# This swing's hits: [WeakRef to the enemy, the damage].
var _hits: Array = []
# Each echo: [seconds left, its hits].
var _echoes: Array = []


func on_swing(_ctx: EffectContext, _swing: SwingAttack) -> void:
	_hits = []


func on_hit(_ctx: EffectContext, enemy: Enemy, amount: float, source: String) -> void:
	if SWINGS.has(source):
		_hits.append([weakref(enemy), amount])


func on_swing_end(_ctx: EffectContext, _swing: SwingAttack) -> void:
	if not _hits.is_empty():
		_echoes.append([DELAY, _hits])
	_hits = []


func on_room_enter(ctx: EffectContext, room: Node) -> void:
	super(ctx, room)
	_hits = []
	_echoes = []


func tick(ctx: EffectContext, delta: float) -> void:
	var due: Array = []
	for echo in _echoes:
		echo[0] -= delta
		if echo[0] <= 0.0:
			due.append(echo)
	for echo in due:
		_echoes.erase(echo)
		for hit in echo[1]:
			var enemy := hit[0].get_ref() as Enemy
			if enemy != null and not enemy.is_dead():
				strike(ctx, enemy, float(hit[1]) * SHARE)
```

`scripts/items/racing_pigeon.gd`:

```gdscript
extends PetEffect

# Racing Pigeon: every EVERY seconds it fetches the nearest waiting coin, Slip or Thermos in the room that
# Harold could take, which flies to him.

const EVERY := 1.5
var _left := EVERY


func tick(ctx: EffectContext, delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	_left = EVERY
	if ctx.fetch_pickup():
		var body := pet()
		if body != null:
			body.lunge_to(ctx.feet())
```

- [ ] **Step 4: The data.** From the template, kind `pet`, build `pets`, tags `["pets"]`, each sub-resource with `look` and `color`:

| file | display_name | rarity | color |
|---|---|---|---|
| `rex.tres` | Rex, the Late Dog | rare | `Color(0.545, 0.353, 0.169, 1)` |
| `mittens.tres` | Mittens | rare | `Color(0.62, 0.6, 0.58, 1)` |
| `ferret.tres` | Trouser Ferret | rare | `Color(0.85, 0.75, 0.55, 1)` |
| `sheepdog.tres` | Old Shep | legendary | `Color(0.92, 0.92, 0.88, 1)` |
| `parrot.tres` | Polly the Parrot | rare | `Color(0.2, 0.75, 0.3, 1)` |
| `racing_pigeon.tres` | Racing Pigeon | common | `Color(0.6, 0.62, 0.7, 1)` |

`RETIRED_ITEMS` gets `"penny_jar"`. Coach tips:

```gdscript
	"rex": "Let him at them. Stay close, he won't go far.",
	"mittens": "Knock them down to a sliver. She does the rest.",
	"ferret": "Dodge into them. He comes out biting.",
	"sheepdog": "Stand where you want them. Shep brings them to you.",
	"parrot": "Land a good one and Polly lands it again.",
	"racing_pigeon": "Don't run about for coins. The bird fetches.",
```

- [ ] **Step 5: Run the tests**

Run: `-- --only=items_pets_fighting`, `-- --only=test_pets`, `-- --only=items_batch3`
Expected: PASS.

- [ ] **Step 6: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/items/rex.gd scripts/items/mittens.gd scripts/items/ferret.gd scripts/items/sheepdog.gd scripts/items/parrot.gd scripts/items/racing_pigeon.gd data/items/rex.tres data/items/mittens.tres data/items/ferret.tres data/items/sheepdog.tres data/items/parrot.tres data/items/racing_pigeon.tres scripts/content/retired_content.gd tests/test_items_pets_fighting.gd
git commit -m "Add the pets that fight and fetch" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 15: Pets that guard, and the pet buffs (6): Joey, Shelley, the moths, Pet Rock, Dog Treats, the plot

**Files:**
- Create: `scripts/items/budgie.gd`, `scripts/items/tortoise.gd`, `scripts/items/moths.gd`, `scripts/items/pet_rock.gd`, `scripts/items/pet_cemetery_plot.gd`, `data/items/budgie.tres`, `data/items/tortoise.tres`, `data/items/moths.tres`, `data/items/pet_rock.tres`, `data/items/dog_treats.tres`, `data/items/pet_cemetery_plot.tres`, `tests/test_items_pets_guarding.gd`
- Modify: `scripts/content/retired_content.gd`

**Interfaces:**
- Consumes: `PetEffect`, `Pet`, `ShotGuard` (Task 5); `HitScaleEffect` (Task 11); `RunState.pet_count` (Task 5).

- [ ] **Step 1: Write the failing test** `tests/test_items_pets_guarding.gd`

```gdscript
extends TestCase

const IDS := {"budgie": ["common", ItemDef.KIND_PET], "tortoise": ["common", ItemDef.KIND_PET], "moths": ["common", ItemDef.KIND_PET],
	"pet_rock": ["common", ItemDef.KIND_PET], "dog_treats": ["common", ItemDef.KIND_PASSIVE], "pet_cemetery_plot": ["legendary", ItemDef.KIND_PASSIVE]}


func test_the_guarding_pets_and_buffs_ship_as_the_list_says() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "pets", id)
		assert_eq(item.rarity, IDS[id][0], id)
		assert_eq(item.kind, IDS[id][1], id)
	assert_eq(ItemKit.item("moths").first_clear_path, "cemetery", "it takes the mothballs' source")
	assert_true(RetiredContent.is_retired("mothball_pockets"))


func test_joey_blocks_a_shot_then_rests_three_seconds() -> void:
	var run := ItemKit.new().run_with(["budgie"])
	var joey = run.effects.effect_of("budgie")
	assert_true(joey.can_block())
	joey.blocked()
	assert_false(joey.can_block())
	run.effects.tick(2.9)
	assert_false(joey.can_block())
	run.effects.tick(0.2)
	assert_true(joey.can_block())
	run.effects.ctx.counting_pills = true
	assert_false(joey.can_block(), "the full loop counts every pill a shot costs")


func test_shelley_plods_and_always_stops_a_shot() -> void:
	var run := ItemKit.new().run_with(["tortoise"])
	var shelley = run.effects.effect_of("tortoise")
	assert_near(shelley.base_speed(), 40.0)
	run.effects.room_enter(null)
	assert_true(shelley.can_block())
	shelley.blocked()
	assert_true(shelley.can_block(), "she never runs out")


func test_the_moths_nibble_what_they_touch_and_each_blocks_one_shot() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["moths"])
	var moths = run.effects.effect_of("moths")
	moths.orbit_speed = 0.0
	run.effects.room_enter(null)
	var enemy := kit.enemy()
	enemy.position = moths.moth_spot(run.effects.ctx, 0)
	var before := enemy.hp
	run.effects.tick(0.01)
	assert_near(before - enemy.hp, 2.0)
	run.effects.tick(0.1)
	assert_near(before - enemy.hp, 2.0, "once a half second per moth")
	run.effects.tick(0.5)
	assert_near(before - enemy.hp, 4.0)
	assert_true(moths.can_block(1))
	moths.blocked(1)
	assert_false(moths.can_block(1))
	assert_true(moths.can_block(0), "the other moth still guards")
	run.effects.tick(4.0)
	assert_true(moths.can_block(1), "it comes back")
	kit.free_enemies()


func test_pet_rock_grows_with_pet_items_and_guards_once_big() -> void:
	var run := ItemKit.new().run_with(["pet_rock"])
	var rock = run.effects.effect_of("pet_rock")
	assert_eq(rock.size(run.effects.ctx), 1)
	assert_false(rock.can_block())
	run.add_item(ItemKit.item("dog_treats"))
	run.add_item(ItemKit.item("rex"))
	assert_eq(rock.size(run.effects.ctx), 3)
	run.effects.room_enter(null)
	assert_true(rock.can_block())


func test_dog_treats_make_pets_hit_harder_and_walk_faster() -> void:
	var run := ItemKit.new().run_with(["dog_treats"])
	assert_near(run.pet_damage_mult(), 1.5)
	assert_near(run.stats.pet_speed_bonus, 0.25)


func test_the_pet_cemetery_plot_adds_eight_percent_per_pet() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["pet_cemetery_plot", "rex", "mittens"])
	var enemy := kit.enemy()
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 11.6)
	kit.free_enemies()
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=items_pets_guarding`
Expected: FAIL.

- [ ] **Step 3: The scripts.**

`scripts/items/budgie.gd`:

```gdscript
extends PetEffect

# Joey the Budgie: circles Harold and blocks a shot, then needs REST seconds before he blocks again. The full
# loop counts every pill a shot costs, so there he blocks nothing.

const REST := 3.0
const ORBIT := 22.0
const ORBIT_SPEED := 3.0
const REACH := 42.0
var _rest := 0.0
# Kept for can_block, which the guard calls with no context. Set on taking and on every room; a resumed run
# walks into its room, which sets it again. Safe: the run owns this effect, the context holds the run weakly.
var _ctx: EffectContext


func on_gain(ctx: EffectContext) -> void:
	_ctx = ctx


func on_room_enter(ctx: EffectContext, room: Node) -> void:
	_ctx = ctx
	super(ctx, room)


func setup_pet(_ctx_now: EffectContext, body: Pet) -> void:
	body.orbit_speed = ORBIT_SPEED
	body.orbit_radius = ORBIT
	body.radius = REACH
	body.check = can_block
	body.spend = blocked


func can_block() -> bool:
	return _rest <= 0.0 and not (_ctx != null and _ctx.counting_pills)


func blocked() -> void:
	_rest = REST


func tick(_ctx_now: EffectContext, delta: float) -> void:
	_rest = maxf(_rest - delta, 0.0)
```

`scripts/items/tortoise.gd`:

```gdscript
extends PetEffect

# Shelley the Tortoise: plods after Harold at SPEED. Every shot that touches her body stops; she cannot be
# hurt and never runs out. The full loop counts every pill a shot costs, so there she stops nothing.

const SPEED := 40.0
const BODY_REACH := 10.0
var _ctx: EffectContext


func on_gain(ctx: EffectContext) -> void:
	_ctx = ctx


func base_speed() -> float:
	return SPEED


func setup_pet(ctx: EffectContext, body: Pet) -> void:
	_ctx = ctx
	body.radius = BODY_REACH
	body.check = can_block
	body.spend = blocked


func can_block() -> bool:
	return not (_ctx != null and _ctx.counting_pills)


func blocked() -> void:
	pass
```

`scripts/items/moths.gd`:

```gdscript
extends PetEffect

# Pocketful of Moths: two moths circle Harold at ORBIT, opposite each other. A moth touching an enemy's
# body nibbles it for DAMAGE (a pet hit), each enemy at most once every AGAIN per moth. Each moth blocks
# one shot, then is gone for GONE seconds.

const COUNT := 2
const ORBIT := 26.0
const DAMAGE := 2.0
const AGAIN := 0.5
const GONE := 4.0
const REACH := 8.0
@export var orbit_speed := 2.5
var _angle := 0.0
var _gone: Array[float] = [0.0, 0.0]
# Moth index -> {enemy instance id: seconds until it may nibble that one again}.
var _again: Array = [{}, {}]
var _ctx: EffectContext


func on_gain(ctx: EffectContext) -> void:
	_ctx = ctx


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	_ctx = ctx
	_again = [{}, {}]
	for i in COUNT:
		var body := Pet.make(look, color, slot, base_speed())
		body.follow = ctx.player if ctx.has_player() else null
		body.orbit_speed = orbit_speed
		body.orbit_radius = ORBIT
		body.orbit_angle = _angle + PI * i
		body.radius = REACH
		body.check = can_block.bind(i)
		body.spend = blocked.bind(i)
		ctx.add_fx(body, moth_spot(ctx, i))


func moth_spot(ctx: EffectContext, index: int) -> Vector2:
	return ctx.feet() + Vector2.from_angle(_angle + PI * index) * ORBIT


func can_block(index: int) -> bool:
	return _gone[index] <= 0.0 and not (_ctx != null and _ctx.counting_pills)


func blocked(index: int) -> void:
	_gone[index] = GONE


func tick(ctx: EffectContext, delta: float) -> void:
	_angle = wrapf(_angle + orbit_speed * delta, 0.0, TAU)
	for i in COUNT:
		_gone[i] = maxf(_gone[i] - delta, 0.0)
		var waits: Dictionary = _again[i]
		for key in waits.keys():
			waits[key] = float(waits[key]) - delta
			if waits[key] <= 0.0:
				waits.erase(key)
		if _gone[i] > 0.0:
			continue
		var spot := moth_spot(ctx, i)
		for enemy in ctx.enemies():
			var key := enemy.get_instance_id()
			if waits.has(key) or not enemy.body_rect().grow(REACH).has_point(spot):
				continue
			if strike(ctx, enemy, DAMAGE):
				waits[key] = AGAIN
```

`scripts/items/pet_rock.gd`:

```gdscript
extends PetEffect

# Pet Rock: a pet that only grows. Its size is 1 plus the other pets-build items held. At BIG or more it
# sits at his heel and stops every shot that touches it.

const BIG := 3
var _ctx: EffectContext


func on_gain(ctx: EffectContext) -> void:
	_ctx = ctx


func size(ctx: EffectContext) -> int:
	var run := ctx.run()
	if run == null:
		return 1
	var grown := 1
	for item in run.items:
		if item.build == "pets" and item.id != "pet_rock":
			grown += 1
	if run.active != null and run.active.build == "pets":
		grown += 1
	return grown


func setup_pet(ctx: EffectContext, body: Pet) -> void:
	_ctx = ctx
	body.radius = 6.0 + 3.0 * size(ctx)
	body.check = can_block
	body.scale = Vector2.ONE * (1.0 + 0.25 * (size(ctx) - 1))


func can_block() -> bool:
	return _ctx != null and size(_ctx) >= BIG and not _ctx.counting_pills
```

`scripts/items/pet_cemetery_plot.gd`:

```gdscript
extends HitScaleEffect

# Pet Cemetery Plot: every pet he has (RunState.pet_count) makes his hits PER harder.

const PER := 0.08


func bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	return PER * run.pet_count() if run != null else 0.0
```

- [ ] **Step 4: The data.** Pets (kind `pet`, build `pets`, tags `["pets"]`, with `look` and `color`): `budgie.tres` ("Joey the Budgie", common, `Color(0.55, 0.85, 0.3, 1)`), `tortoise.tres` ("Shelley the Tortoise", common, `Color(0.42, 0.5, 0.3, 1)`), `moths.tres` ("Pocketful of Moths", common, `Color(0.85, 0.82, 0.7, 1)`, `first_clear_path = "cemetery"`), `pet_rock.tres` ("Pet Rock", common, `Color(0.55, 0.55, 0.55, 1)`). Passives (build `pets`): `dog_treats.tres` ("Tin of Dog Treats", common, no script, `pet_damage_bonus = 0.5`, `pet_speed_bonus = 0.25`), `pet_cemetery_plot.tres` ("Pet Cemetery Plot", legendary, script). `RETIRED_ITEMS` gets `"mothball_pockets"`. Coach tips:

```gdscript
	"budgie": "Joey takes a shot for you. Then give him a breather.",
	"tortoise": "Keep Shelley between you and the shooters. Slow, but solid.",
	"moths": "Walk in close. The moths nibble, and the shots land on them.",
	"pet_rock": "Get more pets and the rock grows. A big rock stops shots.",
	"dog_treats": "Treats for the animals. They bite harder and keep up.",
	"pet_cemetery_plot": "Every pet you keep makes you hit harder. Collect the lot.",
```

- [ ] **Step 5: Run the tests**

Run: `-- --only=items_pets_guarding`, `-- --only=items_pets_fighting`, `-- --only=contact`, `-- --only=items_batch4`
Expected: PASS.

- [ ] **Step 6: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/items/budgie.gd scripts/items/tortoise.gd scripts/items/moths.gd scripts/items/pet_rock.gd scripts/items/pet_cemetery_plot.gd data/items/budgie.tres data/items/tortoise.tres data/items/moths.tres data/items/pet_rock.tres data/items/dog_treats.tres data/items/pet_cemetery_plot.tres scripts/content/retired_content.gd tests/test_items_pets_guarding.gd
git commit -m "Add the guarding pets and the pet buffs" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 16: Denture items (9)

**Files:**
- Create: `scripts/items/chattering_bounce.gd`, `data/items/strong_dentures.tres`, `data/items/chattering_bounce.tres`, `tests/test_items_dentures.gd`
- Modify: `data/items/boomerang_bite.tres`, `data/items/spare_set.tres`, `data/items/shark_tooth.tres`, `data/items/glue_gun.tres`, `data/items/windup_teeth.tres`, `data/items/fizzy_tablet.tres`, `data/items/dentures_in_glass.tres`, `scripts/items/fizzy_tablet.gd`, `scripts/items/dentures_in_glass.gd`, `scripts/content/retired_content.gd`, `tests/test_items_batch1.gd`, `tests/test_items_batch4.gd`, `tests/test_reworked_items.gd`

**Interfaces:**
- Consumes: `RunEffects.bite`, `ThrownDentures.bite_damage(mult)`.

- [ ] **Step 1: Write the failing test** `tests/test_items_dentures.gd`

```gdscript
extends TestCase

const IDS := {"strong_dentures": "rare", "boomerang_bite": "common", "spare_set": "rare", "shark_tooth": "legendary",
	"glue_gun": "rare", "chattering_bounce": "rare", "windup_teeth": "rare", "fizzy_tablet": "common", "dentures_in_glass": "common"}


func test_the_denture_items_ship_as_the_list_says() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "bite", id)
		assert_eq(item.rarity, IDS[id], id)
		assert_eq(Array(item.tags), ["bite"], id)
	assert_true(RetiredContent.is_retired("dentures"))


func test_extra_strong_dentures_bite_harder_and_through_two() -> void:
	var run := ItemKit.new().run_with(["strong_dentures"])
	assert_near(run.stats.bite_damage_mult, 1.5)
	assert_eq(run.stats.bites_per_throw, 2)


func test_the_kept_denture_rules_stand() -> void:
	var kit := ItemKit.new()
	assert_true(kit.run_with(["boomerang_bite"]).stats.teeth_boomerang)
	assert_eq(kit.run_with(["spare_set"]).stats.teeth_sets, 2)
	assert_near(kit.run_with(["glue_gun"]).stats.teeth_glue_time, 2.0)
	assert_true(kit.run_with(["windup_teeth"]).stats.teeth_floor_bite)


func test_the_chatter_jumps_to_three_more_enemies_then_stops() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["chattering_bounce"])
	var line: Array[Enemy] = []
	for i in 5:
		var enemy := kit.enemy()
		enemy.position = Vector2(100 * i, 0)
		line.append(enemy)
	var bite := ThrownDentures.bite_damage(run.bite_damage_mult())
	run.effects.throw()
	run.effects.bite(line[0])
	for i in range(1, 4):
		assert_near(line[i].max_hp() - line[i].hp, bite, "jump %d" % i)
	assert_near(line[4].hp, line[4].max_hp(), "three jumps a throw")
	kit.free_enemies()


func test_the_fizz_slows_for_two_seconds() -> void:
	var fizzy := load("res://scripts/items/fizzy_tablet.gd")
	assert_near(fizzy.TIME, 2.0)
	assert_near(fizzy.SHARE, 0.5)


func test_dentures_in_a_glass_swing_a_quarter_faster() -> void:
	var glass := load("res://scripts/items/dentures_in_glass.gd")
	assert_near(glass.PACE, 1.25)
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=items_dentures`
Expected: FAIL.

- [ ] **Step 3: The scripts.** `scripts/items/chattering_bounce.gd`:

```gdscript
extends ItemEffect

# Chattering Ricochet: after each bite, the dentures jump to the next nearest living enemy within REACH of
# the bitten one that this throw has not bitten, up to JUMPS a throw. A jump is a bite: bite damage, the
# bite source, and the bite hook runs, so bleeds and glue follow it. The full loop counts damage exactly.

const JUMPS := 3
const REACH := 140.0
var _jumps := 0
var _bitten := {}


func on_throw(_ctx: EffectContext) -> void:
	_jumps = 0
	_bitten.clear()


func on_bite(ctx: EffectContext, enemy: Enemy) -> void:
	_bitten[enemy.get_instance_id()] = true
	var run := ctx.run()
	if _jumps >= JUMPS or run == null or ctx.counting_exact:
		return
	var next := _next(ctx, enemy)
	if next == null:
		return
	_jumps += 1
	ctx.add_fx(ItemFx.make_sparks(ItemFx.FIZZ_COLOR), next.global_position)
	if ctx.hit_enemy(next, ThrownDentures.bite_damage(run.bite_damage_mult()), RunEffects.BITE):
		run.effects.bite(next)


func _next(ctx: EffectContext, from: Enemy) -> Enemy:
	var best: Enemy = null
	for enemy in ctx.enemies_near(from.global_position, REACH):
		if enemy == from or _bitten.has(enemy.get_instance_id()):
			continue
		if best == null or enemy.global_position.distance_to(from.global_position) < best.global_position.distance_to(from.global_position):
			best = enemy
	return best
```

`fizzy_tablet.gd`: `const TIME := 2.0`. `dentures_in_glass.gd`: `const PACE := 1.25`.

- [ ] **Step 4: The data.** New (build `bite`, tags `["bite"]`): `strong_dentures.tres` ("Extra Strong Dentures", rare, no script, `bite_damage_bonus = 0.5`, `bites_through = 2`), `chattering_bounce.tres` ("Chattering Ricochet", rare, script). Kept, rewritten in place (list description, build, tags; stats stay): `boomerang_bite`, `spare_set`, `shark_tooth`, `glue_gun`, `windup_teeth`, `fizzy_tablet`, `dentures_in_glass`. `RETIRED_ITEMS` gets `"dentures"`. Coach tips:

```gdscript
	"strong_dentures": "Line them up and throw through the lot. Teeth first, questions later.",
	"chattering_bounce": "Throw into a crowd. They hop from one to the next.",
```

- [ ] **Step 5: Retire old tests.** `tests/test_items_batch1.gd`: remove `boomerang_bite`, `spare_set`, `shark_tooth`, `glue_gun`, `windup_teeth`, `fizzy_tablet` from `BATCH`; delete `test_fizzy_tablet_slows_the_bitten_and_what_stands_in_the_fizz`. `tests/test_items_batch4.gd`: remove `dentures_in_glass` from `BATCH`; delete `test_dentures_in_a_glass_speed_his_swings_while_they_are_out`. `tests/test_reworked_items.gd`: remove `"dentures"` from `IDS` and from the `rare` list. If `tests/test_dentures.gd` finds the item through `Content.items()`, switch it to `ItemKit.item("strong_dentures")`.

- [ ] **Step 6: Run the tests**

Run: `-- --only=items_dentures`, `-- --only=dentures`, `-- --only=items_batch`, `-- --only=reworked_items`
Expected: PASS.

- [ ] **Step 7: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/items/chattering_bounce.gd scripts/items/fizzy_tablet.gd scripts/items/dentures_in_glass.gd data/items/strong_dentures.tres data/items/chattering_bounce.tres data/items/boomerang_bite.tres data/items/spare_set.tres data/items/shark_tooth.tres data/items/glue_gun.tres data/items/windup_teeth.tres data/items/fizzy_tablet.tres data/items/dentures_in_glass.tres scripts/content/retired_content.gd tests/test_items_dentures.gd tests/test_items_batch1.gd tests/test_items_batch4.gd tests/test_reworked_items.gd tests/test_dentures.gd
git commit -m "Add the dentures build's items" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 17: Cane items (10)

**Files:**
- Create: `scripts/items/lightning_rod.gd`, `scripts/items/cane_hook.gd`, `data/items/lightning_rod.tres`, `data/items/cane_hook.tres`, `tests/test_items_cane.gd`
- Modify: `data/items/cane_sword.tres`, `data/items/brass_topper.tres`, `data/items/rolling_pin.tres`, `data/items/reapers_scythe.tres`, `data/items/knitting_needles.tres`, `data/items/rusty_hinge.tres`, `data/items/bingo_dabber.tres`, `data/items/obituary_clippings.tres`, `scripts/items/rusty_hinge.gd`, `scripts/items/obituary_clippings.gd`, `scripts/items/brass_topper.gd` (header comment), `scripts/items/knitting_needles.gd` (header comment), `tests/test_items_batch1.gd`, `tests/test_items_batch4.gd`

- [ ] **Step 1: Write the failing test** `tests/test_items_cane.gd`

```gdscript
extends TestCase

const IDS := {"cane_sword": "rare", "brass_topper": "rare", "lightning_rod": "rare", "rolling_pin": "legendary",
	"reapers_scythe": "legendary", "knitting_needles": "rare", "cane_hook": "common", "rusty_hinge": "common",
	"bingo_dabber": "common", "obituary_clippings": "common"}


func test_the_cane_items_ship_as_the_list_says() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "cane", id)
		assert_eq(item.rarity, IDS[id], id)
	assert_eq(ItemKit.item("brass_topper").display_name, "Brass Cane Topper")
	assert_eq(ItemKit.item("knitting_needles").display_name, "Knitting Needles")
	assert_eq(ItemKit.item("cane_hook").display_name, "Shepherd's Crook Handle")


func test_the_lightning_rod_strikes_what_a_full_charge_hits() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["lightning_rod"])
	var enemy := kit.enemy("intern_reaper", 40.0)
	run.effects.charge_release(true)
	run.effects.hit(enemy, 30.0, RunEffects.CHARGE)
	assert_near(enemy.hp, 20.0, "a bolt of 20")
	run.effects.charge_release(false)
	run.effects.hit(enemy, 30.0, RunEffects.CHARGE)
	assert_near(enemy.hp, 20.0, "a half charge calls no bolt")
	kit.free_enemies()


func test_the_crook_pulls_what_a_finisher_hits() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["cane_hook"])
	var enemy := kit.enemy()
	enemy.position = Vector2(60, 0)
	var boss := kit.enemy("regional_reaper")
	boss.position = Vector2(60, 20)
	run.effects.hit(enemy, 18.0, RunEffects.SWING)
	assert_false(enemy.is_pushed(), "only the finisher hooks")
	run.effects.hit(enemy, 18.0, RunEffects.COMBO_3)
	run.effects.hit(boss, 18.0, RunEffects.COMBO_3)
	assert_true(enemy.is_pushed())
	assert_false(boss.is_pushed(), "never a boss")
	kit.free_enemies()


func test_the_rusty_hinge_stuns_a_full_second() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["rusty_hinge"])
	var hinge := load("res://scripts/items/rusty_hinge.gd")
	assert_near(hinge.STUN_TIME, 1.0)
	assert_near(hinge.AGAIN_AFTER, 2.5)
	var enemy := kit.enemy()
	run.effects.hit(enemy, 18.0, RunEffects.COMBO_3)
	assert_true(enemy.is_stunned())
	kit.free_enemies()


func test_obituaries_add_five_percent_a_kill_up_to_half_and_say_so() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["obituary_clippings"])
	var enemy := kit.enemy()
	run.effects.room_enter(null)
	for i in 3:
		run.effects.kill(kit.enemy(), RunEffects.SWING)
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 11.5)
	var pops := kit.fx_of(ItemFx.FxPop)
	assert_eq(pops.size(), 3)
	assert_eq(pops[2]["text"], "+15%")
	for i in 12:
		run.effects.kill(kit.enemy(), RunEffects.SWING)
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 15.0)
	kit.free_enemies()
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=items_cane`
Expected: FAIL.

- [ ] **Step 3: The scripts.**

`scripts/items/lightning_rod.gd`:

```gdscript
extends ItemEffect

# Lightning Rod Cane: every enemy a fully charged swing hits also takes a bolt of BOLT, an item hit. The
# full loop counts damage exactly, so there no bolt falls.

const BOLT := 20.0
const RADIUS := 14.0
const COLOR := Color("cfe8ff")
var _full := false


func on_charge_release(_ctx: EffectContext, full: bool) -> void:
	_full = full


func on_hit(ctx: EffectContext, enemy: Enemy, _amount: float, source: String) -> void:
	if source != RunEffects.CHARGE or not _full or ctx.counting_exact:
		return
	ctx.add_fx(ItemFx.make_blast(RADIUS, COLOR), enemy.global_position)
	ctx.hit_enemy(enemy, BOLT, RunEffects.ITEM)


func on_swing_end(_ctx: EffectContext, _swing: SwingAttack) -> void:
	_full = false
```

`scripts/items/cane_hook.gd`:

```gdscript
extends ItemEffect

# Shepherd's Crook Handle: each regular enemy a combo finisher hits is pulled toward his feet. Bosses stand.

const PULL := 240.0
const TIME := 0.25


func on_hit(ctx: EffectContext, enemy: Enemy, _amount: float, source: String) -> void:
	if source != RunEffects.COMBO_3 or enemy.def.is_boss or enemy.is_dead():
		return
	var way := enemy.global_position.direction_to(ctx.feet())
	if way.is_zero_approx():
		return
	enemy.apply_push(way * PULL, TIME)
```

`rusty_hinge.gd`: `const STUN_TIME := 1.0`, `const AGAIN_AFTER := 2.5`. `obituary_clippings.gd`: `const PER_KILL := 0.05`, and in `on_kill`, after counting a kill, `ctx.add_fx(ItemFx.make_pop("+%d%%" % roundi(PER_KILL * 100.0 * kills_counted), COLOR), ctx.feet())` (use the script's own counter name for `kills_counted`; the pop shows the running total, at most +50%). Update the brass topper's and knitting needles' header comments to their list names.

- [ ] **Step 4: The data.** New (build `cane`, tags `["cane"]`): `lightning_rod.tres` ("Lightning Rod Cane", rare, script), `cane_hook.tres` ("Shepherd's Crook Handle", common, script, `first_clear_path = "last_resort_cruise"`). Kept, rewritten in place (list description, build, tags; stats and unlock lines stay): `cane_sword`, `brass_topper` (display_name "Brass Cane Topper"), `rolling_pin`, `reapers_scythe`, `knitting_needles` (display_name "Knitting Needles"), `rusty_hinge`, `bingo_dabber`, `obituary_clippings`. Coach tips:

```gdscript
	"lightning_rod": "Charge it all the way. The sky does the rest.",
	"cane_hook": "Finish the combo and drag them in. Then do it again.",
```

- [ ] **Step 5: Retire old tests.** `tests/test_items_batch1.gd`: remove `cane_sword`, `bingo_dabber`, `rusty_hinge`, `knitting_needles`, `brass_topper`, `rolling_pin`, `reapers_scythe` from `BATCH`; delete `test_rusty_hinge_stuns_on_the_combos_third_hit_with_a_rest_between`. `tests/test_items_batch4.gd`: remove `obituary_clippings` from `BATCH`; delete `test_obituary_clippings_add_four_percent_a_kill_until_the_next_room`.

- [ ] **Step 6: Run the tests**

Run: `-- --only=items_cane`, `-- --only=items_batch`, `-- --only=eras`
Expected: PASS.

- [ ] **Step 7: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/items/lightning_rod.gd scripts/items/cane_hook.gd scripts/items/rusty_hinge.gd scripts/items/obituary_clippings.gd scripts/items/brass_topper.gd scripts/items/knitting_needles.gd data/items/lightning_rod.tres data/items/cane_hook.tres data/items/cane_sword.tres data/items/brass_topper.tres data/items/rolling_pin.tres data/items/reapers_scythe.tres data/items/knitting_needles.tres data/items/rusty_hinge.tres data/items/bingo_dabber.tres data/items/obituary_clippings.tres tests/test_items_cane.gd tests/test_items_batch1.gd tests/test_items_batch4.gd
git commit -m "Add the cane build's items" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---
### Task 18: Dodge (8) and Pills (8) items

**Files:**
- Create: `scripts/items/heart_monitor.gd`, `data/items/heart_monitor.tres`, `tests/test_items_dodge_pills.gd`
- Modify: `data/items/` `pocket_watch.tres`, `wheelchair_wheels.tres`, `titanium_hip.tres`, `pogo_cane.tres`, `velcro_shoes.tres`, `afterimage.tres`, `bad_hip.tres`, `rocking_chair.tres`, `hospital_bracelet.tres`, `comfort_care_lanyard.tres`, `pill_organizer.tres`, `casserole_dish.tres`, `life_alert_button.tres`, `life_jacket.tres`, `eternal_warranty.tres`; `scripts/items/titanium_hip.gd`, `scripts/items/bad_hip.gd`, `scripts/items/pill_organizer.gd`, `scripts/core/coach_tips.gd`; `tests/test_items_batch1.gd`, `tests/test_items_batch2.gd`, `tests/test_items_batch3.gd`, `tests/test_reworked_items.gd`

- [ ] **Step 1: Write the failing test** `tests/test_items_dodge_pills.gd`

```gdscript
extends TestCase

const DODGE := {"pocket_watch": "rare", "wheelchair_wheels": "rare", "titanium_hip": "rare", "pogo_cane": "rare",
	"velcro_shoes": "common", "afterimage": "rare", "bad_hip": "common", "rocking_chair": "common"}
const PILLS := {"heart_monitor": "legendary", "hospital_bracelet": "common", "comfort_care_lanyard": "rare",
	"pill_organizer": "common", "casserole_dish": "common", "life_alert_button": "rare", "life_jacket": "rare",
	"eternal_warranty": "legendary"}


func test_the_dodge_and_pill_items_ship_as_the_list_says() -> void:
	for id: String in DODGE:
		var item := ItemKit.item(id)
		assert_eq(item.build, "dodge", id)
		assert_eq(item.rarity, DODGE[id], id)
	for id: String in PILLS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "pills", id)
		assert_eq(item.rarity, PILLS[id], id)


func test_the_titanium_hip_hits_for_a_whole_swing() -> void:
	assert_near(load("res://scripts/items/titanium_hip.gd").SHARE, 1.0)


func test_velcro_shoes_add_a_dodge_with_no_longer_cooldown() -> void:
	var run := ItemKit.new().run_with(["velcro_shoes"])
	assert_eq(run.stats.dodge_charges, 2)
	assert_near(run.stats.dodge_cooldown, PlayerStats.BASE_DODGE_COOLDOWN)


func test_the_bad_hip_cough_is_bigger_and_longer() -> void:
	var hip := load("res://scripts/items/bad_hip.gd")
	assert_near(hip.RADIUS, 36.0)
	assert_near(hip.TIME, 3.0)
	assert_near(hip.SHARE, 0.5)


func test_the_heart_monitor_adds_six_percent_a_pill_of_maximum() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["heart_monitor", "hospital_bracelet"])
	var enemy := kit.enemy()
	assert_eq(run.health.max_pills, PlayerStats.BASE_PILLS + 1)
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 13.0)
	kit.free_enemies()


func test_the_organizer_stores_three_heals_and_each_soaks_a_whole_hit() -> void:
	var run := ItemKit.new().run_with(["pill_organizer"])
	assert_eq(run.stats.max_pills, PlayerStats.BASE_PILLS, "no extra pill any more")
	var organizer = run.effects.effect_of("pill_organizer")
	assert_true(run.effects.accepts_pickup(RunEffects.HEAL))
	for i in 4:
		run.effects.pickup(RunEffects.HEAL, 1)
	assert_eq(organizer.stored, 3)
	assert_eq(run.effects.hurt(2, RunEffects.HURT_ENEMY), 0, "a whole hit, however big")
	assert_eq(organizer.stored, 2)
	run.effects.ctx.counting_pills = true
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1)


func test_the_kept_pill_rules_stand() -> void:
	var kit := ItemKit.new()
	assert_eq(kit.run_with(["hospital_bracelet"]).stats.max_pills, PlayerStats.BASE_PILLS + 1)
	var lanyard := kit.run_with(["comfort_care_lanyard"])
	assert_eq(lanyard.stats.max_pills, PlayerStats.BASE_PILLS + 1)
	assert_eq(lanyard.stats.heal_bonus, 1)
	assert_eq(kit.run_with(["life_jacket"]).stats.floor_lethal_saves, 1)
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=items_dodge_pills`
Expected: FAIL.

- [ ] **Step 3: The scripts.** `scripts/items/heart_monitor.gd`:

```gdscript
extends HitScaleEffect

# Heart Monitor: every pill of his maximum makes his hits PER harder.

const PER := 0.06


func bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	return PER * run.health.max_pills if run != null else 0.0
```

`titanium_hip.gd`: `const SHARE := 1.0` (header: a full plain swing). `bad_hip.gd`: `const RADIUS := 36.0`, `const TIME := 3.0`. `pill_organizer.gd` becomes (the member stays `stored`, which the full loop empties):

```gdscript
extends ItemEffect

# Spare Pill Organizer: a heal taken at full health is stored instead, up to CAPACITY, and each stored heal
# soaks one whole hit, however big. The full loop counts every pill, so there it neither stores nor soaks.

const CAPACITY := 3
const COLOR := Color("e4524f")
var stored := 0


func accepts_pickup(ctx: EffectContext, kind: String) -> bool:
	var run := ctx.run()
	return kind == RunEffects.HEAL and stored < CAPACITY and run != null and run.health.pills >= run.health.max_pills and not ctx.counting_pills


func on_pickup(ctx: EffectContext, kind: String, amount: int) -> int:
	var run := ctx.run()
	if kind != RunEffects.HEAL or run == null or ctx.counting_pills or run.health.pills < run.health.max_pills or stored >= CAPACITY:
		return amount
	stored += 1
	ctx.notice("Saved for later: %d in the organizer" % stored)
	return amount


func on_hurt(ctx: EffectContext, pills: int, _source: String) -> int:
	if pills <= 0 or stored <= 0 or ctx.counting_pills:
		return pills
	stored -= 1
	ctx.add_fx(ItemFx.make_pop("SOAKED", COLOR), ctx.feet())
	return 0


func save_state() -> Dictionary:
	return state_of(["stored"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["stored"])
```

- [ ] **Step 4: The data.** New: `heart_monitor.tres` ("Heart Monitor", legendary, build `pills`, script). Kept, rewritten in place with the list's description, `build`, `tags = [build]`: the eight dodge items (`build = "dodge"`) and the seven kept pill items (`build = "pills"`). `velcro_shoes.tres`: delete the `dodge_cooldown_cut = -0.3` line. `pill_organizer.tres`: delete `bonus_pills = 1`. Coach tips:

```gdscript
	"heart_monitor": "More pills, harder hits. Look after your heart.",
```

- [ ] **Step 5: Retire old tests.** `tests/test_items_batch1.gd`: remove `rocking_chair` from `BATCH`. `tests/test_items_batch2.gd`: remove `bad_hip`, `afterimage`, `wheelchair_wheels`, `velcro_shoes`, `pogo_cane`, `life_alert_button`, `casserole_dish`, `hospital_bracelet` from `BATCH`; delete `test_bad_hip_leaves_a_cough_that_slows_what_it_touches` and `test_velcro_shoes_give_two_dodges_back_to_back_on_a_longer_cooldown`. `tests/test_items_batch3.gd`: remove `eternal_warranty` from `BATCH`. `tests/test_reworked_items.gd`: remove `comfort_care_lanyard`, `life_jacket`, `pill_organizer`, `pocket_watch`, `titanium_hip` from `IDS` and from the `rare`, `recipes` and `bounties` lists; delete `test_titanium_hip_hits_what_he_dodges_through_once_a_dodge` and `test_pill_organizer_stores_heals_taken_at_full_and_soaks_the_next_hit`.

- [ ] **Step 6: Run the tests**

Run: `-- --only=items_dodge_pills`, `-- --only=items_batch`, `-- --only=reworked_items`, `-- --only=resume_item_state`, `-- --only=contact`, `-- --only=training_yard`
Expected: PASS.

- [ ] **Step 7: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/items/heart_monitor.gd scripts/items/titanium_hip.gd scripts/items/bad_hip.gd scripts/items/pill_organizer.gd scripts/core/coach_tips.gd data/items/heart_monitor.tres data/items/pocket_watch.tres data/items/wheelchair_wheels.tres data/items/titanium_hip.tres data/items/pogo_cane.tres data/items/velcro_shoes.tres data/items/afterimage.tres data/items/bad_hip.tres data/items/rocking_chair.tres data/items/hospital_bracelet.tres data/items/comfort_care_lanyard.tres data/items/pill_organizer.tres data/items/casserole_dish.tres data/items/life_alert_button.tres data/items/life_jacket.tres data/items/eternal_warranty.tres tests/test_items_dodge_pills.gd tests/test_items_batch1.gd tests/test_items_batch2.gd tests/test_items_batch3.gd tests/test_reworked_items.gd
git commit -m "Add the dodge and pills builds' items" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 19: Risk (6) and Any-build (9) items

**Files:**
- Create: `scripts/items/unpaid_bill.gd`, `scripts/items/glass_hip.gd`, `scripts/items/cactus_brooch.gd`, `data/items/unpaid_bill.tres`, `data/items/glass_hip.tres`, `data/items/cactus_brooch.tres`, `tests/test_items_risk_any.gd`
- Modify: `data/items/` `photo_of_grandkids.tres`, `nitro_tablets.tres`, `polyester_suit.tres`, `prune_juice.tres`, `floor_plan.tres`, `magnifying_glass.tres`, `alarm_clock.tres`, `early_bird_special.tres`, `bureaucrats_stamp.tres`, `bifocals.tres`, `last_orders.tres`, `complaint_form.tres`; `scripts/items/polyester_suit.gd`, `scripts/items/alarm_clock.gd`, `scripts/items/early_bird_special.gd`, `scripts/items/bureaucrats_stamp.gd`, `scripts/items/bifocals.gd`, `scripts/content/retired_content.gd`, `scripts/core/coach_tips.gd`; `tests/test_items_batch4.gd`, `tests/test_reworked_items.gd`, `tests/test_resume_item_state.gd`

**Interfaces:**
- Consumes: `HitScaleEffect` (Task 11); `ctx.spend_from_purse`, `ctx.lose_half` (Tasks 1, 8).

- [ ] **Step 1: Write the failing test** `tests/test_items_risk_any.gd`

```gdscript
extends TestCase

const RISK := {"photo_of_grandkids": ["rare", false], "nitro_tablets": ["rare", true], "polyester_suit": ["common", true],
	"prune_juice": ["common", true], "unpaid_bill": ["rare", true], "glass_hip": ["rare", true]}
const ANY := {"floor_plan": "common", "magnifying_glass": "common", "alarm_clock": "common", "early_bird_special": "common",
	"bureaucrats_stamp": "legendary", "bifocals": "rare", "last_orders": "rare", "complaint_form": "rare", "cactus_brooch": "rare"}


func test_the_risk_and_any_items_ship_as_the_list_says() -> void:
	for id: String in RISK:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "risk", id)
		assert_eq(item.rarity, RISK[id][0], id)
		assert_eq(item.cursed, RISK[id][1], id)
		if item.cursed:
			assert_true(item.description.contains("but"), "%s names its cost" % id)
	for id: String in ANY:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "any", id)
		assert_eq(item.rarity, ANY[id], id)
	assert_true(RetiredContent.is_retired("wreath_of_thorns"))
	assert_false(ItemKit.item("bifocals").reveals_enemy_health, "the list names no health bars")


func test_the_polyester_suit_hits_harder_and_shocks_for_half_a_second() -> void:
	var run := ItemKit.new().run_with(["polyester_suit"])
	assert_near(run.stats.damage_mult, 1.35)
	var suit := load("res://scripts/items/polyester_suit.gd")
	assert_near(suit.STUN, 0.5)
	assert_near(suit.CHANCE, 0.1)


func test_the_unpaid_bill_hits_harder_and_takes_ten_a_fight_room() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["unpaid_bill"])
	var enemy := kit.enemy()
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 15.0)
	run.pension_at_start = 0
	kit.pension = 25
	run.effects.room_enter(null)
	assert_eq(kit.pension, 15)
	kit.pension = 5
	run.health.pills = 3
	run.effects.room_enter(null)
	run.effects.room_enter(null)
	assert_eq(run.health.pills, 2, "two halves with nothing to pay")
	assert_eq(kit.pension, 5)
	kit.free_enemies()
	run.effects.room_enter(null)
	assert_eq(run.health.pills, 2, "a room with no fight takes nothing")


func test_the_glass_hip_is_quick_and_every_second_hit_costs_a_pill_more() -> void:
	var run := ItemKit.new().run_with(["glass_hip"])
	assert_near(run.stats.move_speed, PlayerStats.BASE_SPEED * 1.3)
	assert_near(run.stats.swing_speed, 1.3)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 2)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1)
	assert_eq(run.effects.hurt(0, RunEffects.HURT_ENEMY), 0, "a blocked hit costs nothing")


func test_the_alarm_clock_stuns_a_full_second() -> void:
	assert_near(load("res://scripts/items/alarm_clock.gd").STUN, 1.0)


func test_the_early_bird_rush_is_a_quarter_faster_and_has_no_combo() -> void:
	var bird := load("res://scripts/items/early_bird_special.gd")
	assert_near(bird.BOOST, 1.25)
	assert_false(FileAccess.get_file_as_string("res://scripts/items/early_bird_special.gd").contains("has_combo"))


func test_the_stamp_takes_a_tenth_of_a_boss() -> void:
	assert_near(load("res://scripts/items/bureaucrats_stamp.gd").BOSS_SHARE, 0.1)
	assert_false(FileAccess.get_file_as_string("res://scripts/items/bureaucrats_stamp.gd").contains("has_combo"))


func test_the_bifocals_finish_regular_enemies_below_fifteen_percent() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["bifocals"])
	var low := kit.enemy("intern_reaper", 6.0)
	run.effects.hit(low, 4.0, RunEffects.SWING)
	assert_true(low.is_dead(), "6 of 42 left: finished")
	var high := kit.enemy("intern_reaper", 30.0)
	run.effects.hit(high, 4.0, RunEffects.SWING)
	assert_false(high.is_dead())
	var boss := kit.enemy("regional_reaper")
	boss.hp = boss.max_hp() * 0.1
	run.effects.hit(boss, 1.0, RunEffects.SWING)
	assert_false(boss.is_dead(), "never a boss")
	kit.free_enemies()


func test_the_cactus_brooch_pricks_and_pushes_what_touches_him() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["cactus_brooch"])
	run.effects.room_enter(null)
	var enemy := kit.enemy()
	enemy.position = Vector2(0, -14)
	var before := enemy.hp
	run.effects.tick(0.01)
	assert_near(before - enemy.hp, 6.0)
	assert_true(enemy.is_pushed())
	run.effects.tick(0.1)
	assert_near(before - enemy.hp, 6.0, "once a half second")
	run.effects.tick(0.5)
	assert_near(before - enemy.hp, 12.0)
	kit.free_enemies()
```

`run.effects.hit()` runs the on_hit hooks only, so an enemy's health is what the test set: 6 of 42 is about 14%, 30 of 42 is over 15%.

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=items_risk_any`
Expected: FAIL.

- [ ] **Step 3: The scripts.**

`scripts/items/unpaid_bill.gd`:

```gdscript
extends HitScaleEffect

# Unpaid Bill: his hits deal half again, but every fight room he walks into takes FEE Pension from the purse,
# or, with less than that, half a pill (never his last). The full loop counts Pension and pills exactly.

const BONUS := 0.5
const FEE := 10
const RED := Color("e0262f")


func bonus(_ctx: EffectContext) -> float:
	return BONUS


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	if ctx.enemies().is_empty() or ctx.counting_exact or ctx.counting_pills:
		return
	if ctx.spend_from_purse(FEE):
		ctx.add_fx(ItemFx.make_pop("BILL -%d" % FEE, RED), ctx.feet())
		ctx.play_sound("coin")
		return
	ctx.lose_half()
	ctx.add_fx(ItemFx.make_pop("FINAL DEMAND", RED), ctx.feet())
```

`scripts/items/glass_hip.gd`:

```gdscript
extends ItemEffect

# Glass Hip: quick on his feet (its stats), but every hit costs half a pill more: every second hit that
# costs pills costs one pill more. The full loop counts every pill a hit costs.

var _halves := 0


func on_hurt(ctx: EffectContext, pills: int, _source: String) -> int:
	if pills <= 0 or ctx.counting_pills:
		return pills
	_halves += 1
	if _halves < 2:
		return pills
	_halves = 0
	return pills + 1


func save_state() -> Dictionary:
	return state_of(["_halves"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["_halves"])
```

`scripts/items/cactus_brooch.gd`:

```gdscript
extends ItemEffect

# Cactus Brooch: an enemy whose body touches his takes DAMAGE (an item hit) and is pushed away, each at
# most once every AGAIN. It shows as a green spark where it pricks, never a ring of thorns. The full loop
# measures what each hit deals, so there it pricks nobody.

const DAMAGE := 6.0
const PUSH := 160.0
const PUSH_TIME := 0.2
const AGAIN := 0.5
# His body over his feet, and how close counts as touching.
const BODY := Vector2(20, 28)
const REACH := 3.0
const GREEN := Color("6fbf5a")
var _again := {}


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	_again.clear()


func tick(ctx: EffectContext, delta: float) -> void:
	for key in _again.keys():
		_again[key] = float(_again[key]) - delta
		if _again[key] <= 0.0:
			_again.erase(key)
	if ctx.counting_exact:
		return
	var body := Rect2(ctx.feet() - Vector2(BODY.x / 2.0, BODY.y), BODY).grow(REACH)
	for enemy in ctx.enemies():
		var key := enemy.get_instance_id()
		if _again.has(key) or not enemy.body_rect().intersects(body):
			continue
		_again[key] = AGAIN
		var away := ctx.feet().direction_to(enemy.global_position)
		ctx.add_fx(ItemFx.make_sparks(GREEN, 6.0), enemy.global_position)
		ctx.hit_enemy(enemy, DAMAGE, RunEffects.ITEM)
		if not enemy.is_dead() and not away.is_zero_approx():
			enemy.apply_push(away * PUSH, PUSH_TIME)
```

Kept scripts: `polyester_suit.gd` `const STUN := 0.5` (keep its `small_blast` sound); `alarm_clock.gd` `const STUN := 1.0`; `early_bird_special.gd` `const BOOST := 1.25`, drop `COMBO_RUSH` and `COMBO`, `rush_time()` returns `RUSH`; `bureaucrats_stamp.gd` `const BOSS_SHARE := 0.1`, drop `COMBO_RECHARGE`, `COMBO` and its branch (`recharge_time()` returns `RECHARGE`); `bifocals.gd` becomes

```gdscript
extends ItemEffect

# Suspicious Bifocals: a hit of his that leaves a regular enemy below BELOW of its health finishes it. Never
# a boss. The full loop counts damage exactly.

const BELOW := 0.15


func on_hit(ctx: EffectContext, enemy: Enemy, _amount: float, source: String) -> void:
	if ctx.counting_exact or enemy.is_dead() or enemy.def.is_boss or not RunEffects.is_his_hit(source):
		return
	if enemy.hp < enemy.max_hp() * BELOW:
		ctx.hit_enemy(enemy, enemy.hp + 1.0, RunEffects.ITEM)
```

- [ ] **Step 4: The data.** New: `unpaid_bill.tres` ("Unpaid Bill", rare, build `risk`, `cursed = true`, script), `glass_hip.tres` ("Glass Hip", rare, build `risk`, `cursed = true`, script, `move_speed_bonus = 0.3`, `swing_speed_bonus = 0.3`), `cactus_brooch.tres` ("Cactus Brooch", rare, build `any`, script, `first_clear_path = "cemetery"`). Kept, rewritten in place (list description, `build`, `tags = [build]`): the four kept risk items (`polyester_suit.tres` also `damage_bonus = 0.35`) and the eight kept any items (`bifocals.tres` loses `reveals_enemy_health = true`). `RETIRED_ITEMS` gets `"wreath_of_thorns"`. Coach tips (the bifocals' line is replaced):

```gdscript
	"unpaid_bill": "Every fight room costs a tenner. Hit hard and earn it back.",
	"glass_hip": "Quick on your feet. Don't get hit, it costs you extra.",
	"cactus_brooch": "Let them come close. They won't like what they find.",
	"bifocals": "Get them low and the glasses finish them off.",
```

- [ ] **Step 5: Retire old tests.** `tests/test_items_batch4.gd`: remove `magnifying_glass`, `floor_plan`, `early_bird_special`, `alarm_clock`, `last_orders`, `photo_of_grandkids`, `complaint_form`, `bureaucrats_stamp`, `polyester_suit` from `BATCH`; delete `test_early_bird_special_speeds_him_for_the_first_ten_seconds_of_a_fight`, `test_alarm_clock_stuns_a_fight_room_as_he_walks_in`, `test_the_stamp_takes_a_share_of_a_boss_and_never_skips_a_phase`, `test_polyester_suit_hits_harder_but_sparks_now_and_then`. `tests/test_reworked_items.gd`: remove `bifocals`, `nitro_tablets`, `prune_juice` from `IDS` and its lists; delete `test_bifocals_show_health_and_hit_the_nearly_dead_harder`. In `tests/test_resume_item_state.gd`, `test_a_resumed_run_keeps_the_stamps_recharge` stays (the 30 s recharge is unchanged).

- [ ] **Step 6: Run the tests**

Run: `-- --only=items_risk_any`, `-- --only=items_batch4`, `-- --only=reworked_items`, `-- --only=resume_item_state`, `-- --only=item_sounds`, `-- --only=contact`
Expected: PASS.

- [ ] **Step 7: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/items/unpaid_bill.gd scripts/items/glass_hip.gd scripts/items/cactus_brooch.gd scripts/items/polyester_suit.gd scripts/items/alarm_clock.gd scripts/items/early_bird_special.gd scripts/items/bureaucrats_stamp.gd scripts/items/bifocals.gd scripts/content/retired_content.gd scripts/core/coach_tips.gd data/items/unpaid_bill.tres data/items/glass_hip.tres data/items/cactus_brooch.tres data/items/photo_of_grandkids.tres data/items/nitro_tablets.tres data/items/polyester_suit.tres data/items/prune_juice.tres data/items/floor_plan.tres data/items/magnifying_glass.tres data/items/alarm_clock.tres data/items/early_bird_special.tres data/items/bureaucrats_stamp.tres data/items/bifocals.tres data/items/last_orders.tres data/items/complaint_form.tres tests/test_items_risk_any.gd tests/test_items_batch4.gd tests/test_reworked_items.gd
git commit -m "Add the risk build's items and rework the any-build items" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 20: Rules (6) and memory (5) items

**Files:**
- Create: `scripts/items/model_citizen.gd`, `scripts/items/repeat_offender.gd`, `scripts/items/fine_print.gd`, `scripts/items/brown_envelope.gd`, `scripts/items/turned_auditor.gd`, `scripts/items/gold_star.gd`, `scripts/items/those_were_the_days.gd`, `scripts/items/rose_tinted.gd`, `scripts/items/scrapbook.gd`, and `data/items/` `model_citizen.tres`, `repeat_offender.tres`, `fine_print.tres`, `brown_envelope.tres`, `turned_auditor.tres`, `gold_star.tres`, `photo_album.tres`, `old_projector.tres`, `those_were_the_days.tres`, `rose_tinted.tres`, `scrapbook.tres`, `tests/test_items_rules_memory.gd`
- Modify: `scripts/core/coach_tips.gd`

**Interfaces:**
- Consumes: `RunEffects.EVENT_*`, `excuses_rule_break`, `sides_with_you`, `on_auditor` (Tasks 3, 10); `Enemy.extra_damage/coin_mult/leaves_item` (Task 8); stats `extra_reels`, `extra_era_rooms` (Task 1); `HitScaleEffect` (Task 11).

- [ ] **Step 1: Write the failing test** `tests/test_items_rules_memory.gd`

```gdscript
extends TestCase

const RULES := {"model_citizen": "rare", "repeat_offender": "rare", "fine_print": "common", "brown_envelope": "rare",
	"turned_auditor": "legendary", "gold_star": "common"}
const MEMORY := {"photo_album": "rare", "old_projector": "rare", "those_were_the_days": "common", "rose_tinted": "rare", "scrapbook": "legendary"}


func test_the_rules_and_memory_items_ship_and_wait_for_rule_floors() -> void:
	for id: String in RULES:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "rules", id)
		assert_eq(item.rarity, RULES[id], id)
		assert_true(item.needs_rules(), id)
	for id: String in MEMORY:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "memory", id)
		assert_eq(item.rarity, MEMORY[id], id)
	assert_eq(ItemKit.item("turned_auditor").display_name, "Clipboard of Your Own")


func test_kept_and_broken_rules_this_run_add_six_percent_each() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["model_citizen", "repeat_offender"])
	var enemy := kit.enemy()
	run.rules_kept = 2
	run.rules_broken = 1
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 10.0 * 1.12 * 1.06)
	kit.free_enemies()


func test_the_auditor_hits_harder_for_a_repeat_offender_and_pays_double_with_an_envelope() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["repeat_offender", "brown_envelope"])
	var auditor := kit.enemy("auditor")
	run.effects.auditor(auditor)
	assert_eq(auditor.extra_damage, 1)
	assert_near(auditor.coin_mult, 2.0)
	assert_true(auditor.leaves_item)
	kit.free_enemies()


func test_fine_print_lets_one_break_a_floor_off() -> void:
	var run := ItemKit.new().run_with(["fine_print"])
	assert_true(run.effects.excuses_rule_break())
	assert_false(run.effects.excuses_rule_break())
	run.effects.floor_start()
	assert_true(run.effects.excuses_rule_break(), "a new floor, a new warning")


func test_the_clipboard_takes_his_side() -> void:
	assert_true(ItemKit.new().run_with(["turned_auditor"]).effects.sides_with_you())


func test_a_gold_star_drops_a_pill_for_a_kept_rule() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["gold_star"])
	run.effects.event(RunEffects.EVENT_RULE_KEPT)
	assert_eq(kit.drops.size(), 1)
	assert_eq(kit.drops[0][0], RoomRules.DROP_HEAL)
	run.effects.event(RunEffects.EVENT_RULE_BROKEN)
	assert_eq(kit.drops.size(), 1)


func test_the_album_and_projector_add_a_reel_and_a_room() -> void:
	var kit := ItemKit.new()
	assert_eq(kit.run_with(["photo_album"]).reel_cap(), 2)
	assert_eq(kit.run_with(["old_projector"]).stats.extra_era_rooms, 1)


func test_a_flashback_ending_heals_a_pill() -> void:
	var run := ItemKit.new().run_with(["those_were_the_days"])
	run.health.pills = 2
	run.effects.event(RunEffects.EVENT_FLASHBACK_END)
	assert_eq(run.health.pills, 3)


func test_rose_tint_helps_young_harold_and_the_scrapbook_old_harold() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["rose_tinted", "scrapbook"])
	var enemy := kit.enemy()
	run.flashbacks_played = 2
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 11.6, "old Harold: the scrapbook alone")
	run.era = Eras.FOOTBALL
	assert_near(run.effects.hit_damage(enemy, 10.0, "era"), 13.0, "young Harold: the glasses alone")
	kit.free_enemies()
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=items_rules_memory`
Expected: FAIL.

- [ ] **Step 3: The scripts.**

`model_citizen.gd`:

```gdscript
extends HitScaleEffect

# Model Citizen's Badge: every rule kept this run makes his hits PER harder.

const PER := 0.06


func bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	return PER * run.rules_kept if run != null else 0.0
```

`repeat_offender.gd`:

```gdscript
extends HitScaleEffect

# Repeat Offender: every rule broken this run makes his hits PER harder, and every Auditor's hit costs
# EXTRA more pills.

const PER := 0.06
const EXTRA := 1


func bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	return PER * run.rules_broken if run != null else 0.0


func on_auditor(_ctx: EffectContext, auditor: Enemy) -> void:
	auditor.extra_damage += EXTRA
```

`fine_print.gd`:

```gdscript
extends ItemEffect

# Fine Print: the first rule broken on each floor is let off with a warning, so no Auditor comes. It still
# counts as broken.

var used := false


func on_floor_start(_ctx: EffectContext) -> void:
	used = false


func excuses_rule_break(_ctx: EffectContext) -> bool:
	if used:
		return false
	used = true
	return true


func save_state() -> Dictionary:
	return state_of(["used"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["used"])
```

`brown_envelope.gd`:

```gdscript
extends ItemEffect

# Brown Envelope: the Auditor pays twice his Pension and always leaves an item.

const MULT := 2.0


func on_auditor(_ctx: EffectContext, auditor: Enemy) -> void:
	auditor.coin_mult = MULT
	auditor.leaves_item = true
```

`turned_auditor.gd`:

```gdscript
extends ItemEffect

# Clipboard of Your Own: a broken rule's Auditor fights for Harold instead (AllyAuditor). Fine Print asks
# first, so a let-off break sends nobody.


func sides_with_you(_ctx: EffectContext) -> bool:
	return true
```

`gold_star.gd`:

```gdscript
extends ItemEffect

# Gold Star Sticker: a kept rule also drops a one-pill heal by where the reel lands.


func on_event(ctx: EffectContext, event_name: String) -> void:
	if event_name != RunEffects.EVENT_RULE_KEPT:
		return
	var at := ctx.room.last_death_spot() if ctx.has_room() else ctx.feet()
	ctx.drop(RoomRules.DROP_HEAL, at, 1)
```

`those_were_the_days.gd`:

```gdscript
extends ItemEffect

# Those Were the Days: a flashback ending (its room cleared, not the floor ending it) heals one pill.


func on_event(ctx: EffectContext, event_name: String) -> void:
	if event_name == RunEffects.EVENT_FLASHBACK_END:
		ctx.heal(1)
```

`rose_tinted.gd`:

```gdscript
extends HitScaleEffect

# Rose-Tinted Glasses: in a flashback, his hits deal BONUS more.

const BONUS := 0.3


func bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	return BONUS if run != null and not run.era.is_empty() else 0.0
```

`scrapbook.gd`:

```gdscript
extends HitScaleEffect

# Scrapbook: every flashback started this run makes old Harold's hits PER harder (not young Harold's).

const PER := 0.08


func bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	if run == null or not run.era.is_empty():
		return 0.0
	return PER * run.flashbacks_played
```

- [ ] **Step 4: The data.** From the template. Rules (build `rules`, tags `["rules"]`): `model_citizen.tres` ("Model Citizen's Badge", rare), `repeat_offender.tres` ("Repeat Offender", rare), `fine_print.tres` ("Fine Print", common), `brown_envelope.tres` ("Brown Envelope", rare), `turned_auditor.tres` ("Clipboard of Your Own", legendary), `gold_star.tres` ("Gold Star Sticker", common). Memory (build `memory`, tags `["memory"]`): `photo_album.tres` ("Photo Album", rare, no script, `extra_reels = 1`), `old_projector.tres` ("Old Projector", rare, no script, `extra_era_rooms = 1`), `those_were_the_days.tres` ("Those Were the Days", common), `rose_tinted.tres` ("Rose-Tinted Glasses", rare), `scrapbook.tres` ("Scrapbook", legendary). Coach tips:

```gdscript
	"model_citizen": "Keep the rules. Every one you keep makes you stronger.",
	"repeat_offender": "Break them all. Just mind the Auditor, he's cross with you.",
	"fine_print": "The first rule you break on a floor, they let go. Pick it well.",
	"brown_envelope": "Let the Auditor come. He pays well.",
	"turned_auditor": "Break a rule and the Auditor fights for you. Bend them early.",
	"gold_star": "Keep a rule, get a pill. Be good.",
	"photo_album": "Two reels in your pocket. Save one for the hard room.",
	"old_projector": "A flashback runs two rooms now. Pick the second well.",
	"those_were_the_days": "Every flashback ends in a pill. Go back often.",
	"rose_tinted": "You hit harder in the old days. Use your reels on big fights.",
	"scrapbook": "Play every flashback. Old you remembers them all.",
```

- [ ] **Step 5: Run the tests**

Run: `-- --only=items_rules_memory`, `-- --only=rule_item_hooks`, `-- --only=training_yard`
Expected: PASS.

- [ ] **Step 6: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/items/model_citizen.gd scripts/items/repeat_offender.gd scripts/items/fine_print.gd scripts/items/brown_envelope.gd scripts/items/turned_auditor.gd scripts/items/gold_star.gd scripts/items/those_were_the_days.gd scripts/items/rose_tinted.gd scripts/items/scrapbook.gd scripts/core/coach_tips.gd data/items/model_citizen.tres data/items/repeat_offender.tres data/items/fine_print.tres data/items/brown_envelope.tres data/items/turned_auditor.tres data/items/gold_star.tres data/items/photo_album.tres data/items/old_projector.tres data/items/those_were_the_days.tres data/items/rose_tinted.tres data/items/scrapbook.tres tests/test_items_rules_memory.gd
git commit -m "Add the rules and memories builds' items" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 21: Active items (8)

**Files:**
- Create: `scripts/items/hearing_aid_feedback.gd`, `scripts/items/walking_frame.gd`, `scripts/items/exchange_desk.gd`, `scripts/items/photocopier.gd`, `scripts/items/megaphone.gd`, `scripts/items/dinner_bell.gd`, and `data/items/` `hearing_aid_feedback.tres`, `walking_frame.tres`, `exchange_desk.tres`, `photocopier.tres`, `megaphone.tres`, `dinner_bell.tres`, `tests/test_items_actives.gd`
- Modify: `scripts/items/harmonica.gd`, `scripts/items/lottery_scratcher.gd`, `data/items/harmonica.tres`, `data/items/lottery_scratcher.tres`, `scripts/content/retired_content.gd`, `scripts/core/coach_tips.gd`, `tests/test_items_batch3.gd`, `tests/test_items_batch4.gd`, `tests/test_reworked_items.gd`

**Interfaces:**
- Consumes: the active slot (Tasks 3, 4); `WalkingFrame` (Task 9); `ctx.copy_pickup`, `ctx.drop_item` (Task 8); `RoomRules.pick_items`; `ItemFx`.
- Produces: `Megaphone.in_cone(from, aim, at, reach, half_angle_deg) -> bool` (static, in `megaphone.gd`, reached by `load()`); `LotteryScratcher.prize(roll) -> String` (static, in `lottery_scratcher.gd`: `"coin"`, `"key"`, `"bomb"`, `"heal"` or `"item"`).

- [ ] **Step 1: Write the failing test** `tests/test_items_actives.gd`

```gdscript
extends TestCase

const IDS := {"hearing_aid_feedback": [3, "rare", "any"], "harmonica": [4, "common", "pills"], "lottery_scratcher": [0, "common", "pension"],
	"walking_frame": [2, "common", "any"], "exchange_desk": [2, "rare", "slip"], "photocopier": [6, "legendary", "any"],
	"megaphone": [2, "rare", "rules"], "dinner_bell": [2, "rare", "pets"]}


func test_the_actives_ship_with_their_charge() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_true(item.is_active(), id)
		assert_eq(item.charge_rooms, IDS[id][0], id)
		assert_eq(item.rarity, IDS[id][1], id)
		assert_eq(item.build, IDS[id][2], id)
	assert_true(ItemKit.item("lottery_scratcher").charge_per_floor)
	assert_false(ItemKit.item("megaphone").needs_rules(), "a rules active works anywhere")
	assert_eq(ItemKit.item("hearing_aid_feedback").display_name, "Hearing Aid")
	assert_true(RetiredContent.is_retired("hearing_aid"))


func test_the_hearing_aid_stuns_the_room_and_waits_for_enemies() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["hearing_aid_feedback"])
	assert_false(run.use_active(), "no one to stun: the charge stays")
	var a := kit.enemy()
	var b := kit.enemy("regional_reaper")
	assert_true(run.use_active())
	assert_true(a.is_stunned())
	assert_true(b.is_stunned())
	kit.free_enemies()


func test_the_harmonica_heals_a_pill_and_waits_at_full() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["harmonica"])
	assert_false(run.use_active(), "full pills")
	run.health.pills = 2
	assert_true(run.use_active())
	assert_eq(run.health.pills, 3)
	assert_true(kit.sounds.has("pill_heal"))


func test_the_scratcher_drops_one_prize_a_floor() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["lottery_scratcher"])
	var lottery := load("res://scripts/items/lottery_scratcher.gd")
	assert_eq(lottery.prize(0.0), "coin")
	assert_eq(lottery.prize(0.45), "key")
	assert_eq(lottery.prize(0.65), "bomb")
	assert_eq(lottery.prize(0.9), "heal")
	assert_eq(lottery.prize(0.97), "item")
	assert_true(run.use_active())
	assert_eq(kit.drops.size(), 1)
	assert_false(run.use_active(), "once a floor")
	run.effects.floor_start()
	assert_true(run.use_active())


func test_the_walking_frame_plants_a_frame() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["walking_frame"])
	assert_true(run.use_active())
	assert_eq(kit.fx_of(WalkingFrame).size(), 1)


func test_the_exchange_desk_swaps_and_waits_on_equal_counts() -> void:
	var run := ItemKit.new().run_with(["exchange_desk"])
	run.keys = 4
	run.bombs = 4
	assert_false(run.use_active())
	run.bombs = 9
	assert_true(run.use_active())
	assert_eq(run.keys, 9)
	assert_eq(run.bombs, 4)


func test_the_photocopier_copies_or_keeps_its_charge() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["photocopier"])
	assert_false(run.use_active(), "nothing to copy")
	kit.can_copy = true
	assert_true(run.use_active())
	assert_eq(kit.copies, 1)


func test_the_megaphone_shoves_and_stuns_what_is_in_front() -> void:
	var megaphone := load("res://scripts/items/megaphone.gd")
	assert_true(megaphone.in_cone(Vector2.ZERO, Vector2.RIGHT, Vector2(100, 30), 150.0, 45.0))
	assert_false(megaphone.in_cone(Vector2.ZERO, Vector2.RIGHT, Vector2(-100, 0), 150.0, 45.0), "behind him")
	assert_false(megaphone.in_cone(Vector2.ZERO, Vector2.RIGHT, Vector2(200, 0), 150.0, 45.0), "too far")
	var kit := ItemKit.new()
	var run := kit.run_with(["megaphone"])
	var front := kit.enemy()
	front.position = Vector2(80, 0)
	var back := kit.enemy()
	back.position = Vector2(-80, 0)
	assert_true(run.use_active())
	assert_true(front.is_stunned())
	assert_true(front.is_pushed())
	assert_false(back.is_stunned())
	kit.free_enemies()


func test_the_dinner_bell_triples_pets_for_five_seconds() -> void:
	var run := ItemKit.new().run_with(["dinner_bell"])
	assert_false(run.use_active(), "no pet to call")
	run.add_item(ItemKit.item("rex"))
	assert_true(run.use_active())
	assert_near(run.pet_damage_mult(), 3.0)
	run.effects.tick(5.1)
	assert_near(run.pet_damage_mult(), 1.0)
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=items_actives`
Expected: FAIL.

- [ ] **Step 3: The scripts.**

`hearing_aid_feedback.gd`:

```gdscript
extends ItemEffect

# Hearing Aid (active): a feedback screech stuns every enemy in the room for STUN. With nobody to stun it
# keeps its charge.

const STUN := 2.0
const RING := 160.0
const COLOR := Color("9fd8ff")


func can_use(ctx: EffectContext) -> bool:
	return not ctx.enemies().is_empty()


func use(ctx: EffectContext) -> bool:
	for enemy in ctx.enemies():
		ctx.stun(enemy, STUN)
	ctx.add_fx(ItemFx.make_shockwave(RING, COLOR), ctx.feet())
	ctx.play_sound("alarm")
	return true
```

`harmonica.gd` (replaces the chord rule):

```gdscript
extends ItemEffect

# Harmonica (active): plays the one song he knows and heals a pill. It waits while his pills are full.


func can_use(ctx: EffectContext) -> bool:
	var run := ctx.run()
	return run != null and run.health.pills < run.health.max_pills


func use(ctx: EffectContext) -> bool:
	ctx.heal(1)
	ctx.add_fx(ItemFx.make_note(0), ctx.feet())
	ctx.play_sound("pill_heal")
	return true
```

`lottery_scratcher.gd` (replaces the floor payout; `rng` stays, shuffled on taking and on a resume):

```gdscript
extends ItemEffect

# Lottery Scratcher (active, once a floor): scratch for one prize at his feet: a coin of COIN Pension, a
# Slip, a Thermos, a one-pill heal or, rarely, a free item (a coin when no item is left to offer).

const COIN := 25
const EDGES := [[0.40, "coin"], [0.60, "key"], [0.80, "bomb"], [0.95, "heal"], [1.01, "item"]]
const AHEAD := Vector2(16, 0)
var rng := RandomNumberGenerator.new()


static func prize(roll: float) -> String:
	for edge in EDGES:
		if roll < edge[0]:
			return edge[1]
	return "item"


func on_gain(_ctx: EffectContext) -> void:
	rng.randomize()


func load_state(_state: Dictionary) -> void:
	rng.randomize()


func use(ctx: EffectContext) -> bool:
	var run := ctx.run()
	if run == null:
		return false
	var at := ctx.feet() + AHEAD
	match prize(rng.randf()):
		"key":
			ctx.drop(RoomRules.DROP_KEY, at)
		"bomb":
			ctx.drop(RoomRules.DROP_BOMB, at)
		"heal":
			ctx.drop(RoomRules.DROP_HEAL, at, 1)
		"item":
			var picked := RoomRules.pick_items(Content.items(), run, 1, rng, ItemRarity.ITEM_ROOM)
			if picked.is_empty():
				ctx.drop(RoomRules.DROP_COIN, at, run.pension_amount(COIN, RunState.PENSION_REWARD))
			else:
				ctx.drop_item(picked[0], at)
		_:
			ctx.drop(RoomRules.DROP_COIN, at, run.pension_amount(COIN, RunState.PENSION_REWARD))
	ctx.play_sound("slot_win")
	return true
```

`walking_frame.gd`:

```gdscript
extends ItemEffect

# Walking Frame (active): plants a frame ahead of him, across his aim, for WalkingFrame.LIFE seconds.


func use(ctx: EffectContext) -> bool:
	var aim := ctx.player.aim_direction() if ctx.has_player() else Vector2.RIGHT
	var frame := WalkingFrame.make(ctx.feet(), aim)
	ctx.add_fx(frame, frame.position)
	return true
```

`exchange_desk.gd`:

```gdscript
extends ItemEffect

# Exchange Desk (active): swaps his Slips and Thermoses. It waits while they are equal.


func can_use(ctx: EffectContext) -> bool:
	var run := ctx.run()
	return run != null and run.keys != run.bombs


func use(ctx: EffectContext) -> bool:
	var run := ctx.run()
	var slips := run.keys
	run.keys = run.bombs
	run.bombs = slips
	run.changed.emit()
	ctx.play_sound("form_filed")
	return true
```

`photocopier.gd`:

```gdscript
extends ItemEffect

# Photocopier (active): copies the waiting pickup nearest him (a coin, Slip, Thermos, heal or potion), the
# copy beside it. With nothing to copy it keeps its charge.


func use(ctx: EffectContext) -> bool:
	return ctx.copy_pickup()
```

`megaphone.gd`:

```gdscript
extends ItemEffect

# Megaphone (active): every enemy in a cone ahead of him is shoved away and stunned.

const REACH := 150.0
const HALF_ANGLE := 45.0
const PUSH := 220.0
const PUSH_TIME := 0.3
const STUN := 1.5
const COLOR := Color("ffd24a")


static func in_cone(from: Vector2, aim: Vector2, at: Vector2, reach: float, half_angle_deg: float) -> bool:
	var offset := at - from
	if offset.length() > reach or offset.is_zero_approx():
		return offset.is_zero_approx()
	return absf(aim.angle_to(offset)) <= deg_to_rad(half_angle_deg)


func use(ctx: EffectContext) -> bool:
	var aim := ctx.player.aim_direction() if ctx.has_player() else Vector2.RIGHT
	for enemy in ctx.enemies():
		if not in_cone(ctx.feet(), aim, enemy.global_position, REACH, HALF_ANGLE):
			continue
		enemy.apply_push(ctx.feet().direction_to(enemy.global_position) * PUSH, PUSH_TIME)
		ctx.stun(enemy, STUN)
	ctx.add_fx(ItemFx.make_shockwave(REACH * 0.6, COLOR), ctx.feet() + aim * 30.0)
	ctx.play_sound("alarm")
	return true
```

`dinner_bell.gd`:

```gdscript
extends ItemEffect

# Dinner Bell (active): his pets hit SCALE times as hard for TIME seconds. It waits while he has no pet.

const SCALE := 3.0
const TIME := 5.0
var _left := 0.0


func can_use(ctx: EffectContext) -> bool:
	var run := ctx.run()
	return run != null and run.pet_count() > 0


func use(ctx: EffectContext) -> bool:
	_left = TIME
	ctx.add_fx(ItemFx.make_pop("DINNER!", ItemFx.BINGO_COLOR), ctx.feet())
	return true


func pet_damage_scale(_ctx: EffectContext) -> float:
	return SCALE if _left > 0.0 else 1.0


func tick(_ctx: EffectContext, delta: float) -> void:
	_left = maxf(_left - delta, 0.0)
```

- [ ] **Step 4: The data.** From the template, kind `active`: `hearing_aid_feedback.tres` ("Hearing Aid", rare, build `any`, `charge_rooms = 3`), `walking_frame.tres` ("Walking Frame", common, `any`, 2), `exchange_desk.tres` ("Exchange Desk", rare, `slip`, 2), `photocopier.tres` ("Photocopier", legendary, `any`, 6), `megaphone.tres` ("Megaphone", rare, `rules`, 2), `dinner_bell.tres` ("Dinner Bell", rare, `pets`, 2). Kept, rewritten in place: `harmonica.tres` (`kind = "active"`, `build = "pills"`, `charge_rooms = 4`, tags `["pills"]`, list description; it keeps `first_clear_path = "funeral_parlour"`), `lottery_scratcher.tres` (`kind = "active"`, `build = "pension"`, `charge_per_floor = true`, tags `["pension"]`). `RETIRED_ITEMS` gets `"hearing_aid"`. Coach tips (the harmonica's and the scratcher's lines are replaced):

```gdscript
	"hearing_aid_feedback": "Save the screech for a crowd. Everyone stops.",
	"walking_frame": "Plant it in a doorway and get your breath back.",
	"exchange_desk": "Too many Slips, not enough Thermoses? Swap them over.",
	"photocopier": "Find something good on the floor, copy it, then pick up both.",
	"megaphone": "Shout them back when they crowd you.",
	"dinner_bell": "Ring it in a big fight. The animals go wild.",
	"harmonica": "Play it when you're a pill down. Four rooms between songs.",
	"lottery_scratcher": "Scratch one every floor. You never know.",
```

- [ ] **Step 5: Retire old tests.** `tests/test_items_batch3.gd`: remove `lottery_scratcher` from `BATCH`; delete `test_lottery_scratcher_pays_zero_to_a_hundred_each_floor`. `tests/test_items_batch4.gd`: remove `harmonica` from `BATCH`; delete `test_harmonica_heals_half_a_pill_for_a_quick_chord_once_a_room`. `tests/test_reworked_items.gd`: remove `hearing_aid` from `IDS`; delete `test_hearing_aid_warns_earlier_and_shows_off_screen_arrows`. `tests/test_resume_item_state.gd` `test_a_resume_shuffles_the_dice_of_effects_that_shuffled_on_gain` keeps passing: the scratcher is now the active, `effect_of` finds it, and its `rng` is shuffled on resume.

- [ ] **Step 6: Run the tests**

Run: `-- --only=items_actives`, `-- --only=active`, `-- --only=item_sounds`, `-- --only=resume_item_state`, `-- --only=items_batch`
Expected: PASS.

- [ ] **Step 7: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/items/hearing_aid_feedback.gd scripts/items/walking_frame.gd scripts/items/exchange_desk.gd scripts/items/photocopier.gd scripts/items/megaphone.gd scripts/items/dinner_bell.gd scripts/items/harmonica.gd scripts/items/lottery_scratcher.gd scripts/content/retired_content.gd scripts/core/coach_tips.gd data/items/hearing_aid_feedback.tres data/items/walking_frame.tres data/items/exchange_desk.tres data/items/photocopier.tres data/items/megaphone.tres data/items/dinner_bell.tres data/items/harmonica.tres data/items/lottery_scratcher.tres tests/test_items_actives.gd tests/test_items_batch3.gd tests/test_items_batch4.gd tests/test_reworked_items.gd
git commit -m "Add the active items" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 22: Run potions (7)

**Files:**
- Create: `scripts/items/potion_smelling_salts.gd`, `scripts/items/potion_dutch_courage.gd`, `scripts/items/potion_pet_food.gd`, and `data/potions/` `double_brew.tres`, `locksmiths_tonic.tres`, `topsy_turvy.tres`, `gold_top.tres`, `smelling_salts.tres`, `dutch_courage.tres`, `pet_food.tres`, `tests/test_potion_items.gd`

**Interfaces:**
- Consumes: `PotionDef.action/run_rarity/effect`, `PotionActions`, `RunEffects.add_lasting` (Task 7); `HitScaleEffect`'s rule (Task 11) for the courage.

- [ ] **Step 1: Write the failing test** `tests/test_potion_items.gd`

```gdscript
extends TestCase

const RARITY := {"double_brew": "rare", "locksmiths_tonic": "rare", "topsy_turvy": "common", "gold_top": "rare",
	"smelling_salts": "common", "dutch_courage": "rare", "pet_food": "common"}


func _drink(run: RunState, id: String) -> bool:
	run.potion = null
	run.give_potion(Content.potion(id))
	return run.drink_potion()


func test_the_run_potions_ship_and_the_merchant_never_sells_them() -> void:
	assert_eq(Content.run_potions().size(), RARITY.size())
	for id: String in RARITY:
		var def := Content.potion(id)
		assert_true(def != null, id)
		if def == null:
			continue
		assert_eq(def.run_rarity, RARITY[id], id)
		assert_false(def.is_for_sale(), "%s is found in runs, never brewed" % id)
		assert_false(def.short_name.is_empty(), id)


func test_the_count_potions_do_what_they_say() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.bombs = 3
	assert_true(_drink(run, "double_brew"))
	assert_eq(run.bombs, 6)
	run.keys = 5
	assert_true(_drink(run, "locksmiths_tonic"))
	assert_eq(run.keys, 10)
	assert_true(_drink(run, "topsy_turvy"))
	assert_eq(run.keys, 6)
	assert_eq(run.bombs, 10)
	assert_true(_drink(run, "gold_top"))
	assert_eq(kit.paid, 160)


func test_smelling_salts_stun_the_next_fight_room_once() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	assert_true(_drink(run, "smelling_salts"))
	run.effects.room_enter(null)
	assert_eq(run.effects.lasting_entries().size(), 1, "no fight in an empty room")
	var enemy := kit.enemy()
	run.effects.room_enter(null)
	assert_true(enemy.is_stunned())
	assert_eq(run.effects.lasting_entries().size(), 0)
	kit.free_enemies()


func test_dutch_courage_hits_harder_hurts_double_for_two_clears() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var enemy := kit.enemy()
	assert_true(_drink(run, "dutch_courage"))
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 16.0)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 2)
	run.effects.room_clear(null)
	assert_eq(run.effects.lasting_entries().size(), 1)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run)))
	var back := ItemKit.new().make_run()
	RunCheckpoint.apply_run(back, raw, Content.items())
	assert_eq(back.effects.lasting_entries().size(), 1, "it survives a resume")
	run.effects.room_clear(null)
	assert_eq(run.effects.lasting_entries().size(), 0)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1)
	kit.free_enemies()


func test_pet_food_doubles_pets_until_the_floor_ends() -> void:
	var run := ItemKit.new().run_with(["rex"])
	assert_true(_drink(run, "pet_food"))
	assert_near(run.pet_damage_mult(), 2.0)
	run.effects.room_clear(null)
	assert_near(run.pet_damage_mult(), 2.0)
	run.effects.floor_start()
	assert_near(run.pet_damage_mult(), 1.0)
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=potion_items`
Expected: FAIL.

- [ ] **Step 3: The lasting parts.**

`scripts/items/potion_smelling_salts.gd`:

```gdscript
extends ItemEffect

# Smelling Salts' lasting part: the next fight room he walks into, every enemy there is stunned for STUN.

const STUN := 3.0
var spent := false


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	if spent:
		return
	var enemies := ctx.enemies()
	if enemies.is_empty():
		return
	for enemy in enemies:
		ctx.stun(enemy, STUN)
	spent = true


func is_spent() -> bool:
	return spent


func save_state() -> Dictionary:
	return state_of(["spent"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["spent"])
```

`scripts/items/potion_dutch_courage.gd`:

```gdscript
extends HitScaleEffect

# Dutch Courage's lasting part: his hits deal BONUS more and every hit on him costs double, until ROOMS
# fight rooms are cleared (the one he is in counts) or the floor ends.

const BONUS := 0.6
const ROOMS := 2
var rooms_left := ROOMS


func bonus(_ctx: EffectContext) -> float:
	return BONUS


func on_hurt(ctx: EffectContext, pills: int, _source: String) -> int:
	return pills * 2 if pills > 0 and not ctx.counting_pills else pills


func on_room_clear(_ctx: EffectContext, _room: Node, _damage_taken_here: int) -> void:
	rooms_left -= 1


func on_floor_start(_ctx: EffectContext) -> void:
	rooms_left = 0


func is_spent() -> bool:
	return rooms_left <= 0


func save_state() -> Dictionary:
	return state_of(["rooms_left"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["rooms_left"])
```

`scripts/items/potion_pet_food.gd`:

```gdscript
extends ItemEffect

# Tin of Pet Food's lasting part: pets hit SCALE times as hard until the floor ends.

const SCALE := 2.0
var done := false


func pet_damage_scale(_ctx: EffectContext) -> float:
	return 1.0 if done else SCALE


func on_floor_start(_ctx: EffectContext) -> void:
	done = true


func is_spent() -> bool:
	return done


func save_state() -> Dictionary:
	return state_of(["done"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["done"])
```

- [ ] **Step 4: The data.** Each `data/potions/<id>.tres` follows `data/potions/swift_tea.tres` with `price` left out (0: never brewed), plus `action`, `run_rarity` and, for the last three, an `effect` sub-resource on their script:

| file | display_name | short_name | action | run_rarity | color | effect |
|---|---|---|---|---|---|---|
| `double_brew.tres` | Double Brew | Brew x2 | `double_bombs` | rare | `Color(0.66, 0.41, 0.18, 1)` | |
| `locksmiths_tonic.tres` | Locksmith's Tonic | Slips x2 | `double_slips` | rare | `Color(0.85, 0.72, 0.3, 1)` | |
| `topsy_turvy.tres` | Topsy-Turvy Tonic | Swap | `swap` | common | `Color(0.6, 0.45, 0.85, 1)` | |
| `gold_top.tres` | Gold Top Milk | Milk | `cash_in` | rare | `Color(0.96, 0.9, 0.7, 1)` | |
| `smelling_salts.tres` | Smelling Salts | Salts | `salts` | common | `Color(0.75, 0.9, 0.85, 1)` | `potion_smelling_salts.gd` |
| `dutch_courage.tres` | Dutch Courage | Courage | `courage` | rare | `Color(0.85, 0.55, 0.2, 1)` | `potion_dutch_courage.gd` |
| `pet_food.tres` | Tin of Pet Food | Pet Food | `pet_food` | common | `Color(0.7, 0.5, 0.35, 1)` | `potion_pet_food.gd` |

Descriptions are the list's text. With an effect the header is `load_steps=3` with a second `ext_resource` for the effect script and a `[sub_resource type="Resource" id="Effect"]` block, as an item's.

- [ ] **Step 5: Run the tests**

Run: `-- --only=potion_items`, `-- --only=run_potions`, `-- --only=potions`, `-- --only=bon_voyage`
Expected: PASS. `test_potions` and the Bon Voyage tests use `Content.potions_for_sale()`, which these never join.

- [ ] **Step 6: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/items/potion_smelling_salts.gd scripts/items/potion_dutch_courage.gd scripts/items/potion_pet_food.gd data/potions/double_brew.tres data/potions/locksmiths_tonic.tres data/potions/topsy_turvy.tres data/potions/gold_top.tres data/potions/smelling_salts.tres data/potions/dutch_courage.tres data/potions/pet_food.tres tests/test_potion_items.gd
git commit -m "Add the run potions" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 23: Set bonuses (11)

**Files:**
- Create: `data/sets/` `set_tea_lady.tres`, `set_civil_servant.tres`, `set_penny_pincher.tres`, `set_animal_lover.tres`, `set_full_set.tres`, `set_old_soldier.tres`, `set_spry.tres`, `set_hypochondriac.tres`, `set_daredevil.tres`, `set_rulebook.tres`, `set_nostalgic.tres`; `scripts/items/set_civil_servant.gd`, `scripts/items/set_old_soldier.gd`, `scripts/items/set_daredevil.gd`, `scripts/items/stray_cat.gd`; `tests/test_set_items.gd`

**Interfaces:**
- Consumes: `SetDef`, `Content.sets()`, `RunEffects.set_sets` (Task 6); `PetEffect` (Task 5); stats (Task 1).

- [ ] **Step 1: Write the failing test** `tests/test_set_items.gd`

```gdscript
extends TestCase

const BUILDS := {"set_tea_lady": "thermos", "set_civil_servant": "slip", "set_penny_pincher": "pension", "set_animal_lover": "pets",
	"set_full_set": "bite", "set_old_soldier": "cane", "set_spry": "dodge", "set_hypochondriac": "pills", "set_daredevil": "risk",
	"set_rulebook": "rules", "set_nostalgic": "memory"}


func _set_run(ids: Array) -> RunState:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.effects.set_sets(Content.sets())
	for id: String in ids:
		run.add_item(ItemKit.item(id))
	return run


func test_eleven_sets_ship_one_per_build_but_any() -> void:
	var sets := Content.sets()
	assert_eq(sets.size(), 11)
	for def in sets:
		assert_eq(def.build, BUILDS.get(def.id, ""), def.id)
		assert_eq(def.needed, 3, def.id)
		assert_false(def.description.is_empty(), def.id)


func test_tea_lady_counts_three_more_and_widens_blasts() -> void:
	var run := _set_run(["tea_cosy", "pressure_cooker", "tea_break"])
	assert_true(run.effects.has_set("set_tea_lady"))
	run.bombs = 50
	assert_eq(run.scaled_bombs(), 23)
	assert_near(run.stats.blast_radius, PlayerStats.BASE_BLAST_RADIUS * (1.0 + 0.5 + 0.25))


func test_the_stat_sets_add_what_they_say() -> void:
	assert_near(_set_run(["money_belt", "piggy_bank", "coupon_booklet"]).stats.coin_reach_mult, 21.0)
	assert_eq(_set_run(["boomerang_bite", "glue_gun", "windup_teeth"]).stats.teeth_sets, 2)
	assert_eq(_set_run(["spare_set", "glue_gun", "windup_teeth"]).stats.teeth_sets, 3)
	var spry := _set_run(["afterimage", "bad_hip", "rocking_chair"])
	assert_eq(spry.stats.dodge_charges, 2)
	assert_near(spry.stats.dodge_length, 1.3)
	var hypo := _set_run(["casserole_dish", "life_jacket", "hospital_bracelet"])
	assert_eq(hypo.stats.max_pills, PlayerStats.BASE_PILLS + 2)
	assert_true(hypo.health.half_heal_bonus)
	var book := _set_run(["fine_print", "gold_star", "brown_envelope"])
	assert_eq(book.stats.extra_rule_rooms, 1)
	assert_eq(book.stats.bonus_kept_reels, 1)
	assert_eq(_set_run(["photo_album", "scrapbook", "rose_tinted"]).reel_cap(), 3)


func test_the_animal_lover_adds_a_stray_cat_that_scratches() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.effects.set_sets(Content.sets())
	for id in ["rex", "mittens", "budgie"]:
		run.add_item(ItemKit.item(id))
	assert_true(run.effects.has_set("set_animal_lover"))
	assert_eq(run.pet_count(), 4)
	var enemy := kit.enemy()
	enemy.position = Vector2(300, 0)
	var near := kit.enemy()
	near.position = Vector2(60, 0)
	var before := near.hp
	var mult := run.pet_damage_mult()
	run.effects.tick(1.5)
	assert_true(before - near.hp >= 4.0 * mult - 0.01, "the cat scratched")
	kit.free_enemies()


func test_the_civil_servant_drops_a_slip_about_one_clear_in_three() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.effects.set_sets(Content.sets())
	for id in ["in_triplicate", "key_cutter", "desk_drawer"]:
		run.add_item(ItemKit.item(id))
	var servant = run.effects.effect_of("set_civil_servant")
	servant.rng.seed = 7
	for i in 60:
		run.effects.room_clear(null)
	var slips := kit.drops.filter(func(drop): return drop[0] == RoomRules.DROP_KEY).size()
	assert_true(slips >= 10 and slips <= 30, "about a third: %d of 60" % slips)


func test_the_old_soldier_sends_a_wave_with_every_finisher() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.effects.set_sets(Content.sets())
	for id in ["cane_hook", "rusty_hinge", "bingo_dabber"]:
		run.add_item(ItemKit.item(id))
	run.effects.swing(SwingAttack.new(Vector2.RIGHT, 44.0, 60.0, 18.0, 60.0, false, true))
	assert_eq(kit.fx_of(ItemFx.FxWave).size(), 1)
	run.effects.swing(SwingAttack.new(Vector2.RIGHT, 44.0, 60.0, 10.0, 60.0, false, false))
	assert_eq(kit.fx_of(ItemFx.FxWave).size(), 1)


func test_the_daredevil_heals_half_a_pill_on_a_rooms_first_kill() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.effects.set_sets(Content.sets())
	for id in ["photo_of_grandkids", "unpaid_bill", "glass_hip"]:
		run.add_item(ItemKit.item(id))
	run.health.pills = 2
	run.effects.room_enter(null)
	run.effects.kill(kit.enemy(), RunEffects.SWING)
	run.effects.kill(kit.enemy(), RunEffects.SWING)
	assert_eq(run.health.half_pills, 1, "once a room")
	kit.free_enemies()
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=set_items`
Expected: FAIL.

- [ ] **Step 3: The set effects.**

`scripts/items/set_civil_servant.gd`:

```gdscript
extends ItemEffect

# Civil Servant (set): every fight room cleared has a CHANCE of a Slip where the last enemy fell.

const CHANCE := 1.0 / 3.0
var rng := RandomNumberGenerator.new()


func on_gain(_ctx: EffectContext) -> void:
	rng.randomize()


func load_state(_state: Dictionary) -> void:
	rng.randomize()


func on_room_clear(ctx: EffectContext, _room: Node, _damage_taken_here: int) -> void:
	if ctx.counting_exact or rng.randf() >= CHANCE:
		return
	var at := ctx.room.last_death_spot() if ctx.has_room() else ctx.feet()
	ctx.drop(RoomRules.DROP_KEY, at)
```

`scripts/items/set_old_soldier.gd`:

```gdscript
extends ItemEffect

# Old Soldier (set): every combo finisher sends a shockwave forward, as the Cane Sword's.

const DAMAGE := 18.0
const DISTANCE := 150.0
const AHEAD := 18.0


func on_swing(ctx: EffectContext, swing: SwingAttack) -> void:
	if not swing.finisher or swing.from_era:
		return
	ctx.add_fx(ItemFx.make_wave(ctx, swing.direction, DAMAGE, DISTANCE), ctx.feet() + swing.direction * AHEAD)
```

`scripts/items/set_daredevil.gd`:

```gdscript
extends ItemEffect

# Daredevil (set): the first kill in each room heals half a pill.

var _healed := false


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	_healed = false


func on_kill(ctx: EffectContext, _enemy: Enemy, _source: String) -> void:
	if _healed:
		return
	_healed = true
	ctx.heal_half()
```

`scripts/items/stray_cat.gd`:

```gdscript
extends PetEffect

# The Animal Lover's stray cat: every EVERY seconds it scratches the enemy nearest Harold within REACH for DAMAGE.

const EVERY := 1.5
const REACH := 120.0
const DAMAGE := 4.0
var _left := EVERY


func tick(ctx: EffectContext, delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	_left = EVERY
	strike(ctx, nearest(ctx, REACH), DAMAGE)
```

- [ ] **Step 4: The data.** Each `data/sets/<id>.tres`:

```
[gd_resource type="Resource" script_class="SetDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/content/set_def.gd" id="1"]

[resource]
script = ExtResource("1")
id = "set_tea_lady"
display_name = "Tea Lady"
description = "With 3 Thermos items: carry 3 more Thermoses, and blasts are 25% bigger."
build = "thermos"
thermos_scale_bonus = 3
blast_radius_bonus = 0.25
```

With an effect, `load_steps=3`, a second `ext_resource` for its script, a `[sub_resource type="Resource" id="Effect"]` (with `look = "stray_cat"` and `color = Color(0.85, 0.6, 0.35, 1)` for the cat) and `effect = SubResource("Effect")`. The eleven:

| id | display_name | build | stats | effect |
|---|---|---|---|---|
| `set_tea_lady` | Tea Lady | thermos | `thermos_scale_bonus = 3`, `blast_radius_bonus = 0.25` | |
| `set_civil_servant` | Civil Servant | slip | | `set_civil_servant.gd` |
| `set_penny_pincher` | Penny Pincher | pension | `coin_reach_bonus = 20.0`, `shop_discount = 0.15` | |
| `set_animal_lover` | Animal Lover | pets | `pet_damage_bonus = 0.5`, `extra_pets = 1` | `stray_cat.gd` |
| `set_full_set` | Full Set | bite | `bonus_teeth_sets = 1` | |
| `set_old_soldier` | Old Soldier | cane | | `set_old_soldier.gd` |
| `set_spry` | Spry | dodge | `bonus_dodge_charges = 1`, `dodge_length_bonus = 0.3` | |
| `set_hypochondriac` | Hypochondriac | pills | `bonus_pills = 1`, `half_heal_bonus = true` | |
| `set_daredevil` | Daredevil | risk | | `set_daredevil.gd` |
| `set_rulebook` | By the Book | rules | `extra_rule_rooms = 1`, `bonus_kept_reels = 1` | |
| `set_nostalgic` | Nostalgic | memory | `extra_reels = 1` | |

Descriptions are the list's text.

- [ ] **Step 5: Run the tests**

Run: `-- --only=set_items`, `-- --only=test_sets`
Expected: PASS.

- [ ] **Step 6: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add data/sets scripts/items/set_civil_servant.gd scripts/items/set_old_soldier.gd scripts/items/set_daredevil.gd scripts/items/stray_cat.gd tests/test_set_items.gd
git commit -m "Add the eleven set bonuses" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---
## Phase C: the switch-over

### Task 24: Retire every old item, give the new items their unlock sources, and reassign the posters

**Files:**
- Modify: `scripts/content/retired_content.gd`; `data/items/` (unlock lines on 24 new items, listed below); `data/bounties/` `augustine.tres`, `celestine.tres`, `crabtree.tres`, `lorraine.tres`, `projectionist.tres`, `tired_undertaker.tres`, `chairman_of_the_board.tres`, `madame_zara.tres`, `reverend.tres`, `senior_adjuster.tres`; `scripts/core/dev_start.gd`; `tests/test_stats.gd`, `tests/test_recipes.gd`, `tests/test_deep_rewards.gd`, `tests/test_run_checkpoint.gd`, `tests/test_reels.gd`, `tests/test_path_migration.gd`, `tests/test_reworked_items.gd`, `tests/test_items_batch2.gd`, `tests/test_items_batch4.gd`
- Create: `tests/test_new_item_pool.gd`

**Interfaces:**
- Consumes: every item batch (Tasks 11 to 21), `RetiredContent` (Task 1).
- Produces: the final pool (107), `RetiredContent.RETIRED_ITEMS` (48 ids), the posters' new rewards.

- [ ] **Step 1: Write the failing test** `tests/test_new_item_pool.gd`

```gdscript
extends TestCase

# The pool is the approved list: 107 items, each with one source, the old quotas kept.

const LIST := ["afterimage", "alarm_clock", "bad_hip", "bifocals", "bingo_dabber", "boomerang_bite", "bottomless_flask",
	"brass_topper", "brown_envelope", "budgie", "bureaucrats_stamp", "cactus_brooch", "cane_hook", "cane_sword",
	"casserole_dish", "chattering_bounce", "coin_purse_cane", "comfort_care_lanyard", "complaint_form", "compound_interest",
	"coupon_booklet", "dentures_in_glass", "desk_drawer", "dinner_bell", "dog_treats", "early_bird_special",
	"eternal_warranty", "exchange_desk", "ferret", "filing_cabinet", "fine_print", "fizzy_tablet", "flask_holster",
	"floor_plan", "glass_hip", "glue_gun", "gold_fillings", "gold_star", "hagglers_hat", "harmonica",
	"hearing_aid_feedback", "heart_monitor", "hospital_bracelet", "hot_soup_thermos", "in_triplicate",
	"inheritance_letter", "key_cutter", "knitting_needles", "last_orders", "life_alert_button", "life_jacket",
	"lightning_rod", "locksmiths_apron", "loose_paperwork", "lottery_scratcher", "magnifying_glass", "megaphone",
	"mittens", "model_citizen", "money_belt", "moths", "nitro_tablets", "obituary_clippings", "old_projector",
	"paper_cuts", "parrot", "pet_cemetery_plot", "pet_rock", "photo_album", "photo_of_grandkids", "photocopier",
	"piggy_bank", "pill_organizer", "pocket_watch", "pogo_cane", "polyester_suit", "pressure_cooker", "prune_juice",
	"racing_pigeon", "reapers_scythe", "repeat_offender", "rex", "rocking_chair", "rolling_pin", "rose_tinted",
	"rubber_stamp_collection", "rusty_hinge", "scrapbook", "second_brew", "senior_discount", "shark_tooth", "sheepdog",
	"spare_set", "strong_dentures", "tea_break", "tea_cosy", "tea_urn", "thermos_lob", "those_were_the_days",
	"titanium_hip", "tortoise", "turned_auditor", "unpaid_bill", "velcro_shoes", "walking_frame", "wheelchair_wheels",
	"windup_teeth"]
const PATHS := ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "flashback_cinema",
	"last_resort_cruise", "seance_hotline", "terminal_zero", "head_office"]
const POSTERS := {"augustine": "photocopier", "celestine": "sheepdog", "crabtree": "thermos_lob", "lorraine": "parrot",
	"projectionist": "old_projector", "tired_undertaker": "pet_cemetery_plot", "doreen": "bureaucrats_stamp",
	"matron_mercy": "comfort_care_lanyard", "sergeant_wanda": "complaint_form", "commodore_wellington": "life_jacket",
	"mortimer_grimsby": "pocket_watch", "regional_reaper": "reapers_scythe", "chairman_of_the_board": "money_belt",
	"madame_zara": "heart_monitor", "reverend": "tea_urn", "senior_adjuster": "filing_cabinet",
	"foreman_klaus": "nitro_tablets", "head_groundskeeper": "titanium_hip"}


func test_the_pool_is_the_approved_list() -> void:
	var ids: Array = []
	for item in Content.items():
		assert_false(ids.has(item.id), "%s ships once" % item.id)
		ids.append(item.id)
	ids.sort()
	assert_eq(ids, LIST)
	assert_eq(RetiredContent.RETIRED_ITEMS.size(), 48)
	for id: String in RetiredContent.RETIRED_ITEMS:
		assert_false(LIST.has(id), "%s is retired" % id)


func test_the_pool_adds_up() -> void:
	var sources := {}
	var rarity := {}
	var kinds := {}
	var cursed: Array[String] = []
	var per_path := {}
	for item in Content.items():
		var source := ItemUnlocks.source_of(item)
		sources[source] = int(sources.get(source, 0)) + 1
		rarity[item.rarity] = int(rarity.get(item.rarity, 0)) + 1
		kinds[item.kind] = int(kinds.get(item.kind, 0)) + 1
		assert_true(ItemUnlocks.source_count(item) <= 1, item.id)
		assert_true(ItemDef.BUILDS.has(item.build), item.id)
		assert_eq(Array(item.tags), [item.build], item.id)
		assert_false(item.description.is_empty(), item.id)
		assert_true(CoachTips.TIPS.has(item.id), "%s has a tip" % item.id)
		if item.cursed:
			cursed.append(item.id)
		if not item.first_clear_path.is_empty():
			per_path[item.first_clear_path] = int(per_path.get(item.first_clear_path, 0)) + 1
	assert_eq(sources, {ItemUnlocks.START: 47, ItemUnlocks.FIRST_CLEAR: 30, ItemUnlocks.RECIPE: 18, ItemUnlocks.BOUNTY: 12})
	assert_eq(rarity, {ItemDef.COMMON: 40, ItemDef.RARE: 52, ItemDef.LEGENDARY: 15})
	assert_eq(kinds, {ItemDef.KIND_PASSIVE: 89, ItemDef.KIND_PET: 10, ItemDef.KIND_ACTIVE: 8})
	cursed.sort()
	assert_eq(cursed, ["glass_hip", "nitro_tablets", "polyester_suit", "prune_juice", "unpaid_bill"] as Array[String])
	for path: String in PATHS:
		assert_eq(per_path.get(path, 0), 3, "%s opens three" % path)
	assert_eq(Content.sets().size(), 11)
	assert_eq(Content.run_potions().size(), 7)
	assert_true(Content.combos().is_empty())


func test_the_posters_pay_the_new_rewards() -> void:
	for def in BountyBoard.all():
		if POSTERS.has(def.id):
			assert_eq(def.extra_id, POSTERS[def.id], def.id)
	assert_eq(ItemKit.item("tea_urn").craft_price, 350)
	assert_true(ItemKit.item("photocopier").from_bounty)
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=new_item_pool`
Expected: FAIL (the old items are still in the pool).

- [ ] **Step 3: Retire them all.** `scripts/content/retired_content.gd`:

```gdscript
# The hundred items' ids not on the new list (and Kettle Whistle, cut in review). Task 26 deletes their files.
const RETIRED_ITEMS: Array[String] = ["alert_bracelet", "banana_peel", "bingo_card", "bingo_hall_pass", "bubble_wrap",
	"bunion_pads", "collection_plate", "dentures", "do_not_resuscitate", "expired_coupon", "forged_signature",
	"fortune_card", "golden_parachute", "gravity_boots", "grief_counselor", "hearing_aid", "hot_water_bottle",
	"hover_round", "kettle_whistle", "knitted_cardigan", "lawyers_card", "loaded_dice", "lucky_tee", "mothball_pockets",
	"moving_boxes", "naughty_list", "neck_pillow", "night_light", "overbite", "penny_jar", "pension_statement",
	"pill_crusher", "reading_glasses", "rubber_ferrule", "rubber_stamps", "second_opinion", "second_thermos_strap",
	"shoe_horn", "slippers", "squeaky_shoes", "support_stockings", "sympathy_card", "tax_refund", "telescope_cane",
	"thick_skull", "undertakers_gloves", "walker_tennis_balls", "wreath_of_thorns"]
```

- [ ] **Step 4: Unlock lines.** Add to each `.tres` (exactly one unlock line each):
  - `first_clear_path`: `model_citizen` floor_1; `budgie`, `those_were_the_days` sunset_shores; `bottomless_flask`, `tea_break`, `second_brew` furnace_works; `mittens` funeral_parlour; `photo_album` flashback_cinema; `tortoise` last_resort_cruise; `rose_tinted` seance_hotline; `unpaid_bill`, `glass_hip` terminal_zero; `repeat_offender` head_office. (`rubber_stamp_collection`, `moths`, `cactus_brooch`, `cane_hook` and `compound_interest` have theirs already.)
  - `craft_price = 350`: `tea_urn`, `filing_cabinet`, `money_belt`, `heart_monitor`.
  - `from_bounty = true`: `photocopier`, `sheepdog`, `thermos_lob`, `parrot`, `old_projector`, `pet_cemetery_plot`.

- [ ] **Step 5: Posters.** Change each poster's `extra_id` (its `extra_kind` stays): `augustine.tres` → `"photocopier"`, `celestine.tres` → `"sheepdog"`, `crabtree.tres` → `"thermos_lob"`, `lorraine.tres` → `"parrot"`, `projectionist.tres` → `"old_projector"`, `tired_undertaker.tres` → `"pet_cemetery_plot"` (all `item`); `chairman_of_the_board.tres` → `"money_belt"`, `madame_zara.tres` → `"heart_monitor"`, `reverend.tres` → `"tea_urn"`, `senior_adjuster.tres` → `"filing_cabinet"` (all `recipe`). Grep `scripts/` and `tests/` for any text that names a poster's old reward (for example a poster line in `scripts/core/bounty_board.gd` or a cosmetic note) and update it to the new item's name.

- [ ] **Step 6: The dev kit.** `scripts/core/dev_start.gd`: `const ITEMS := ["pill_organizer", "velcro_shoes", "hearing_aid_feedback"]`.

- [ ] **Step 7: Old tests that read the old pool.**
  - `tests/test_stats.gd`: `assert_eq(Content.items().size(), 107)`. `tests/test_recipes.gd`: `assert_eq(base, 47)`.
  - `tests/test_deep_rewards.gd`: `_item()` reads `Content.all_items()`; `test_the_new_rewards_are_shipped_as_the_posters_need` keeps only the `life_jacket` lines.
  - `tests/test_run_checkpoint.gd`: `_item()` reads `Content.all_items()`, and every `RunCheckpoint.apply_run(..., Content.items())` in it, in `tests/test_reels.gd` and in `tests/test_path_migration.gd` passes `Content.all_items()`, so their old ids still resume until Task 26.
  - `tests/test_reworked_items.gd`: delete `test_every_old_item_id_still_ships`.
  - `tests/test_items_batch2.gd`: delete `test_lorraines_poster_pays_the_gravity_boots_and_her_hat_is_sold`. `tests/test_items_batch4.gd`: delete `test_the_bounty_items_take_four_free_posters_and_their_looks_are_sold`.
  - Run the suite; any other failure that comes from a test reading `Content.items()` for a retired id is fixed the same way (read `Content.all_items()`), and listed in the commit body.

- [ ] **Step 8: Run the tests**

Run: `-- --only=new_item_pool`, `-- --only=item_unlocks`, `-- --only=bounties`, `-- --only=recipes`, `-- --only=training_yard`, `-- --only=dev_start`, `-- --only=stats`
Expected: PASS.

- [ ] **Step 9: Full suite, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed).

```powershell
git add scripts/content/retired_content.gd data/items data/bounties scripts/core/dev_start.gd tests
git commit -m "Switch the pool to the new item list and reassign the posters" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Read `git diff --cached --name-status` before committing: only the files this task names may be staged.

---

### Task 25: Old saves and checkpoints load cleanly; the full loop follows the new items

**Files:**
- Modify: `scripts/core/run_checkpoint.gd`, `scripts/core/progress_data.gd`, `scripts/world/room_view.gd` (`_item_by_id`), `tools/smoke_driver.gd`
- Create: `tests/test_new_item_migration.gd`

**Interfaces:**
- Consumes: `RetiredContent.current_id`, `is_retired`, `RETIRED_RECIPE_PRICES` (Task 1); `RunState.restore_active` (Task 3).

- [ ] **Step 1: Write the failing test** `tests/test_new_item_migration.gd`

```gdscript
extends TestCase

# Saves and checkpoints from before the new list load cleanly: renamed ids become their new items, retired
# ones are left out, and a crafted item whose recipe left is paid back.


func _old_profile(extra: Dictionary) -> Dictionary:
	var raw := {"version": 1, "pension": 100, "upgrades": {}, "opening_seen": true}
	raw.merge(extra, true)
	return raw


func test_a_checkpoint_with_old_ids_resumes_with_their_new_items() -> void:
	var back := ItemKit.new().make_run()
	var raw := {"items": ["second_thermos_strap", "bingo_card", "hearing_aid", "tea_cosy"], "pills": 3, "max_pills": 4,
		"keys": 1, "bombs": 2, "effects": {"items": {"bingo_card": {"_count": 3}}}}
	RunCheckpoint.apply_run(back, raw, Content.items())
	var ids: Array = []
	for item in back.items:
		ids.append(item.id)
	assert_eq(ids, ["flask_holster", "tea_cosy"])
	assert_eq(back.active.id, "hearing_aid_feedback", "a renamed active goes to the active slot")
	assert_eq(back.bombs, 2, "a renamed item never pays its on_gain again")


func test_an_old_profile_maps_renamed_ids_and_refunds_a_retired_craft() -> void:
	var data := ProgressData.from_dict(_old_profile({
		"crafted_for_next_run": "golden_parachute",
		"recipes_found": {"rubber_stamps": true, "tea_cosy": true},
		"items_unlocked": {"rubber_stamps": true, "neck_pillow": true},
		"items_seen": {"penny_jar": 2},
	}))
	assert_true(data != null)
	assert_eq(data.pension, 210, "the parachute's 110 comes back")
	assert_eq(data.crafted_for_next_run, "")
	assert_true(data.recipes_found.has("rubber_stamp_collection"))
	assert_true(data.items_unlocked.has("rubber_stamp_collection"))
	assert_eq(int(data.items_seen.get("racing_pigeon", 0)), 2)


func test_a_crafted_kept_item_still_waits() -> void:
	var data := ProgressData.from_dict(_old_profile({"crafted_for_next_run": "rolling_pin"}))
	assert_eq(data.crafted_for_next_run, "rolling_pin")
	assert_eq(data.pension, 100)


func test_the_shipped_old_save_fixture_still_loads() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/save_v1_2026-11-04.json"))
	assert_true(ProgressData.from_dict(raw) != null)


func test_a_room_snapshot_skips_retired_items_and_maps_renamed_ones() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	var find := source.substr(source.find("func _item_by_id"), 400)
	assert_true(find.contains("RetiredContent.current_id("))
```

- [ ] **Step 2: Run it to see it fail**

Run: `-- --only=new_item_migration`
Expected: FAIL.

- [ ] **Step 3: The checkpoint.** In `RunCheckpoint.apply_run`, the items loop becomes

```gdscript
	for raw_id in raw.get("items", []):
		var id := RetiredContent.current_id(str(raw_id))
		if RetiredContent.is_retired(id):
			continue
		for item in items:
			if item.id != id:
				continue
			if item.is_active():
				run.restore_active(item, 99)
			else:
				run.restore_item(item)
			break
```

(`restore_active` clamps the charge to full.) Saved effect states stay keyed by the old id, so a renamed item's new effect starts with no state, which is what `load_state({})` gives.

- [ ] **Step 4: The profile.** In `ProgressData.from_dict`, after `recipes_found`, `items_unlocked`, `items_seen` and `crafted_for_next_run` are read:

```gdscript
	data.recipes_found = _renamed_keys(data.recipes_found)
	data.items_unlocked = _renamed_keys(data.items_unlocked)
	data.items_seen = _renamed_keys(data.items_seen)
	# A crafted item whose recipe left the game is paid back; a renamed one waits as its new item.
	if RetiredContent.RETIRED_RECIPE_PRICES.has(data.crafted_for_next_run):
		data.pension += int(RetiredContent.RETIRED_RECIPE_PRICES[data.crafted_for_next_run])
		data.crafted_for_next_run = ""
	else:
		data.crafted_for_next_run = RetiredContent.current_id(data.crafted_for_next_run)
```

with

```gdscript
# The same table with every renamed item id (RetiredContent.RENAMED) under its new id. Counts add up.
static func _renamed_keys(table: Dictionary) -> Dictionary:
	var out := {}
	for key in table:
		var id := RetiredContent.current_id(str(key))
		var value: Variant = table[key]
		if out.has(id) and (value is int or value is float):
			out[id] = int(out[id]) + int(value)
		else:
			out[id] = value
	return out
```

Put the refund after `pension` is read, so it adds to the loaded amount.

- [ ] **Step 5: A room's snapshot.** `RoomView._item_by_id(id)` first maps `id = RetiredContent.current_id(id)` and returns null for `RetiredContent.is_retired(id)`; then it searches `Content.items()` as today.

- [ ] **Step 6: The full loop.** In `tools/smoke_driver.gd`: `_check_pad_map` loops `["floor_plan"]` only (the Fortune Teller's Card is retired); the landing-heal check's `run.has_item("neck_pillow")` branch goes (no item heals fully on a landing now). Grep the driver for every other old id (`grep -n -E "\"(<the 48 retired ids joined by |>)\"" tools/smoke_driver.gd`) and replace each with a kept item of the same mechanic, or drop the check when nothing kept does it; list each in the commit body. Its pill-blocking switch keeps the Spare Pill Organizer empty through `stored`, which Task 18 kept.

- [ ] **Step 7: Run the tests**

Run: `-- --only=new_item_migration`, `-- --only=run_checkpoint`, `-- --only=save`, `-- --only=path_migration`, `-- --only=reels`
Expected: PASS.

- [ ] **Step 8: Full suite and the full loop, then commit**

Run: `powershell -File tools/test.ps1` (expect 0 failed), then `powershell -File tools/smoke.ps1` (expect `SMOKE PASS`; read the whole tail, LESSONS 2026-11-03). Run the full loop three times, since it picks up whatever items it is offered (LESSONS 2026-11-02).

```powershell
git add scripts/core/run_checkpoint.gd scripts/core/progress_data.gd scripts/world/room_view.gd tools/smoke_driver.gd tests/test_new_item_migration.gd
git commit -m "Load old saves and checkpoints onto the new item list" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 26: Delete the retired item files (NEEDS THE USER'S OK FIRST)

> **Stop before this task.** Deleting files needs the user's explicit OK. Show them this list and wait. Git keeps every file's history, and nothing in the pool uses them after Task 24. If the user says no, skip to Task 27: the retired files stay on disk, unused.

**Files to delete:**
- Items (48): `data/items/` `alert_bracelet.tres`, `banana_peel.tres`, `bingo_card.tres`, `bingo_hall_pass.tres`, `bubble_wrap.tres`, `bunion_pads.tres`, `collection_plate.tres`, `dentures.tres`, `do_not_resuscitate.tres`, `expired_coupon.tres`, `forged_signature.tres`, `fortune_card.tres`, `golden_parachute.tres`, `gravity_boots.tres`, `grief_counselor.tres`, `hearing_aid.tres`, `hot_water_bottle.tres`, `hover_round.tres`, `kettle_whistle.tres`, `knitted_cardigan.tres`, `lawyers_card.tres`, `loaded_dice.tres`, `lucky_tee.tres`, `mothball_pockets.tres`, `moving_boxes.tres`, `naughty_list.tres`, `neck_pillow.tres`, `night_light.tres`, `overbite.tres`, `penny_jar.tres`, `pension_statement.tres`, `pill_crusher.tres`, `reading_glasses.tres`, `rubber_ferrule.tres`, `rubber_stamps.tres`, `second_opinion.tres`, `second_thermos_strap.tres`, `shoe_horn.tres`, `slippers.tres`, `squeaky_shoes.tres`, `support_stockings.tres`, `sympathy_card.tres`, `tax_refund.tres`, `telescope_cane.tres`, `thick_skull.tres`, `undertakers_gloves.tres`, `walker_tennis_balls.tres`, `wreath_of_thorns.tres`.
- Combos (12): every file in `data/combos/` (`bingo_night`, `card_shark`, `dentists_nightmare`, `early_riser`, `family_visit`, `full_set`, `last_rites`, `mobility_scooter`, `night_shift`, `paper_trail`, `retirement_plan`, `soup_of_the_day`, each `.tres`). The folder itself may go; `Content.combos()` copes with it missing.
- Item scripts only those use (each with its `.gd.uid`): `scripts/items/` `alert_bracelet`, `banana_peel`, `bingo_card`, `bingo_hall_pass`, `bingo_night`, `bubble_wrap`, `collection_plate`, `dentists_nightmare`, `do_not_resuscitate`, `expired_coupon`, `family_visit`, `forged_signature`, `fortune_card`, `grief_counselor`, `hot_water_bottle`, `kettle_whistle`, `knitted_cardigan`, `lawyers_card`, `mobility_scooter`, `mothball_pockets`, `moving_boxes`, `naughty_list`, `neck_pillow`, `pension_statement`, `pill_crusher`, `reading_glasses`, `rubber_stamps`, `second_opinion`, `second_thermos_strap`, `shoe_horn`, `sympathy_card`, `tax_refund`, `thick_skull`, `wreath_of_thorns`. **Not** `scripts/world/collection_plate.gd` (an enemy's thrown plate) and no other world script.
- Tests only about them: in `tests/test_items_batch1.gd` the functions for walker tennis balls, reading glasses, rubber ferrule, shoe horn and overbite, the batch meta tests (`test_the_batch_ships_with_its_rarity_tags_and_one_source`, `test_every_batch_text_is_two_sentences_and_has_a_coach_tip`, `test_the_batchs_combos_ship_with_both_items`), `BATCH`, and the preload of `dentists_nightmare.gd`; in `tests/test_items_batch2.gd` the functions for hover round, squeaky shoes, banana peel, bunion pads, gravity boots, knitted cardigan, sympathy card, pill crusher, hot water bottle, bubble wrap, thick skull and second opinion, the meta tests, `BATCH`, and the preloads of `banana_peel.gd`, `sympathy_card.gd`, `hot_water_bottle.gd`, `mobility_scooter.gd`; in `tests/test_items_batch3.gd` the functions for do not resuscitate, the full loop's whole pills (if it names a retired id), second thermos strap, forged signature, rubber stamps, kettle whistle, penny jar, pension statement, loaded dice, the house-still-wins test, expired coupon, collection plate, tax refund and night light, `test_no_poster_pays_a_batch_item`, the meta tests, `BATCH`, and the preloads of `second_thermos_strap.gd`, `kettle_whistle.gd`, `pension_statement.gd`; in `tests/test_items_batch4.gd` the functions for the fortune teller, mothball pockets, telescope cane, grief counselor, wreath of thorns, bingo hall pass, moving boxes and lawyer's card, the meta tests, `BATCH`, and the preloads of `mothball_pockets.gd`, `fortune_card.gd`, `grief_counselor.gd`, `wreath_of_thorns.gd`, `bingo_hall_pass.gd`; in `tests/test_reworked_items.gd` every function naming a retired id, `IDS` and its meta tests, and the preload of `naughty_list.gd`; in `tests/test_contact.gd` the lawyer's card, bubble wrap, thick skull, mothball pockets and wreath of thorns functions; in `tests/test_deep_rewards.gd` the neck pillow, lucky tee and golden parachute functions; in `tests/test_resume_item_state.gd` the expired coupon and tax refund functions, with `test_a_resumed_run_keeps_counters_and_floor_flags` and `test_the_checkpoint_round_trip_still_matches_with_effect_state` rewritten on kept items (`pill_organizer.stored`, `bottomless_flask.cleared`, `glass_hip._halves`, `fine_print.used`, `eternal_warranty`, `bureaucrats_stamp`); in `tests/test_item_sounds.gd` the retired ids in `KEY_SOUNDS`, `test_a_free_shop_rings_the_till_once`, and `test_paying_items_ring_the_coin` and `test_the_stamps_sound_like_stamps` rewritten on `inheritance_letter` and `rubber_stamp_collection`. Any test left naming a retired id (`tests/test_eras.gd`, `tests/test_training_yard.gd`, `tests/test_path_migration.gd`, `tests/test_run_checkpoint.gd`, `tests/test_dentures.gd`) uses a kept item of the same mechanic instead.
- `CoachTips.TIPS` lines for retired ids.

**Keep:** `RetiredContent` (its `RENAMED` and `RETIRED_RECIPE_PRICES` still migrate old saves; `RETIRED_ITEMS` stays as the record), `ComboDef` and its code, `Content.all_items()`.

- [ ] **Step 1: Ask the user.** Show the list above. Continue only on a clear yes.
- [ ] **Step 2: Delete in one command with its commit** (LESSONS 2026-11-08: a staged `git rm` rides into the next commit otherwise): `git rm <the .tres and .gd and .gd.uid files>` then edit the tests and tips, then `git add tests scripts/core/coach_tips.gd` and read `git diff --cached --name-status`.
- [ ] **Step 3: Full suite and the full loop**

Run: `powershell -File tools/test.ps1` (expect 0 failed and no `Could not load content file` errors), then `powershell -File tools/smoke.ps1` (expect `SMOKE PASS`).

- [ ] **Step 4: Commit**

```powershell
git commit -m "Delete the retired item, combo and script files" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 27: Verify, measure income, and build

**Files:**
- Modify: `LESSONS.md` (new gotchas), `docs/superpowers/plans/2026-11-10-new-item-list.md` (an "As built" note at the end)

- [ ] **Step 1: The suite and the full loop.** `powershell -File tools/test.ps1` (0 failed), then `powershell -File tools/smoke.ps1` three times (`SMOKE PASS` each; read each tail).
- [ ] **Step 2: Income.** The money items change Pension per clear. One heavy job at a time, with no windowed Godot running: `& $GODOT --headless --path . --script res://tools/probes/income_probe.gd -- 0 1 none 16`, then the same with `money_belt,compound_interest,coin_purse_cane,inheritance_letter` and with `rubber_stamp_collection,gold_fillings`, and at depth 3 (`-- 0 3 ...`). Write the Pension per clear of each next to "none" in the As built note. If one item alone adds more than about a tenth to a full clear (the 2026-11-05 bar), say so in the note and propose a number; do not change it without the user.
- [ ] **Step 3: Look at the new looks.** The pets, the paper sheets, the walking frame, the bomblets, the thrown Thermos, the ally Auditor and the active slot are drawn in code. In a windowed run of a `git archive` copy (never the worktree, never while the user plays), shoot each once with `tools/probes/items_look.gd` adapted to give the item, and check: nothing reads as a cross, plus or halo at 1x; the active slot fits between the panels with every counter at 99 (LESSONS 2026-11-03); the "[R] ..." label fits.
- [ ] **Step 4: Export build.** Follow `docs/release/build-steps.md` in full and in order (archive, music, stamp, import, export), into `D:\grandpa-build\`. Start the exe once into the Waiting Room, and check the title corner shows the commit. Compare the exe size with the last build (LESSONS 2026-11-10). Keep `editor/export/convert_text_resources_to_binary` off.
- [ ] **Step 5: Notes and commit.** Append each new gotcha to `LESSONS.md` as a dated one-liner. Add an "As built" section to this plan with the income table and anything that changed.

```powershell
git add LESSONS.md docs/superpowers/plans/2026-11-10-new-item-list.md
git commit -m "Record the new item list's income check and build notes" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 6: Review before merge.** The new item list is a large round: ask for an independent review of the branch before it is merged (`superpowers:requesting-code-review`), then hand it to the user to play.
