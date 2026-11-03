# Third Floor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Grandpa throws his false teeth instead of his cane, every `C` cell rolls one of five chest types, a rare Arcade Room offers three games of chance, and beating a second-floor boss leads to a third floor with two paths, the Eternal Rest Funeral Parlour and the Golden Years Mall, each complete with enemies, bosses, a hazard and rooms.

**Architecture:**
- **Dentures:** `DentureThrow` (pure state rules) and `ThrownDentures` (the actor) replace `CaneThrow` and `ThrownCane`. The throw has its own stats on `PlayerStats` (`bite_damage_mult`, `bite_range`, `bites_per_throw`, `teeth_return_delay`), fed by new `StatEffect` fields. The cane no longer leaves his hand, so the swing code never waits on the teeth.
- **Chests:** `ChestRules` (pure) rolls a kind from `FloorDef.chest_weights` and says what each kind costs and pays. `Chest` (a `Pickup`) draws each kind and opens by key, by the player's Thermos (`Chest.blast`, like `SecretWall.blast`) or by touch (the mimic). `RoomView` spends Slips and drops the loot.
- **Depth 3:** `floor_scene.gd` gains a third entry in `PATHS_BY_DEPTH`, `LAST_DEPTH = 3` and a landing per depth. Unlocks use `ProgressData.clears_at(3)`.
- **Arcade:** pure card and reel rules (`CardDeck`, `SlotMachine`, `Blackjack`, `DrawPoker`) with seeded tests. A new room type, attached by `FloorBuilder` like a side room on about 1 floor in 4, holds a Dealer NPC and three game tables that open a code-drawn overlay.
- **Content:** each path is a `FloorDef` with its own layouts, palette, enemies, bosses and hazard, built exactly as Sunset Shores and the Furnace Works were.

**Tech Stack:** Godot 4.7.2 standard, GDScript, `gl_compatibility`, 640×360 viewport, nodes built in code, `.tres` data, headless tests.

**Spec:** `docs/superpowers/specs/2026-11-03-third-floor-design.md`. Read it before any task. The spec governs where this plan is silent.

## Global Constraints

- Never name another game in any file, comment, asset name or commit message.
- Ask before adding dependencies. None are needed.
- Commit messages are in the imperative mood, one logical change per commit, and end with a blank line and then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Use a PowerShell here-string so the trailer stays on its own line.
- Append dated lessons to `LESSONS.md` (`- 2026-11-03: <what happened> → <rule>`) when a bug or gotcha teaches something. Read `LESSONS.md` before each step.
- Leave the project runnable after every commit.
- Every attack shows its warning first, and line attacks also show a lane. Bosses start attacks only with their whole body on screen, using `Enemy.target_in_view()` (which calls `BossMoves.in_view`).
- Walkers move with `Enemy.chase_direction()`, which routes round walls through the room's `WalkGrid`.
- Summoned enemies pay no Pension.
- Old saves must load. Every new save field is optional and has a fallback.
- Don't change prop collision boxes. They get set from the final art.
- Data lives in `.tres` files, nodes are built in code, and pure rules are `RefCounted` with headless tests. Scripts loaded by tests must not reference autoloads. Pass `Progress` in as `_bank`, as `RoomView` already does.
- **Testing is on hold until the user says go.** Every "run" step below is written "when testing is allowed". Until then: write code and tests without running Godot in any form, leave those boxes unticked, and note that new scripts have no `.uid` file until the first import.
- **When testing is allowed, and the user is playing:** never launch Godot while the user's game window is open. Check with:

  ```powershell
  Get-CimInstance Win32_Process -Filter "Name like 'Godot%'" | Select-Object ProcessId, CommandLine
  ```

  A process whose command line has no `--headless` and points at a project path is the user's game. Wait, or ask the controller.
- **The real save:** never run a scene without `--smoke`, because that writes to `%APPDATA%\Godot\app_userdata\Grandpa\save.json`.
- Commands, run from `C:\GameDev\game\.worktrees\third-floor`, when testing is allowed:

  ```powershell
  powershell -File tools/test.ps1   # ends with "N tests, 0 failed"
  powershell -File tools/smoke.ps1  # prints "SMOKE PASS ..." or "SMOKE FAIL: ..."
  ```

  Read the summary line, not a piped exit code. After a run, `git checkout -- art/sprites` clears line-ending-only `.import` churn.
- **Repeated full-loop runs:** export the commit with `git archive` and rename `config/name` in the copy so it gets its own user folder. See `LESSONS.md`.
- **Files and line endings:** the worktree checks files out with CRLF. Make multi-line changes with the Edit tool, end single-line sed patterns with `\r\?$`, and never use PowerShell `Set-Content` on text (see `LESSONS.md`).

---

## File structure

**Step 1, new:**
- `scripts/core/denture_throw.gd` (renamed from `cane_throw.gd`): the throw's states and its return delay.
- `scripts/actors/thrown_dentures.gd` (renamed from `thrown_cane.gd`): the teeth in flight, the bite, the pierce, the chattering drawing.
- `scripts/core/chest_rules.gd`: chest kinds, rolls, costs and loot amounts.
- `scripts/world/chest.gd`: a `Pickup` drawn per kind that opens by key, blast or touch.
- `scripts/actors/behaviors/mimic_behavior.gd` and `data/enemies/mimic.tres`.
- `data/upgrades/denture_adhesive.tres`.
- `tests/test_dentures.gd` (renamed from `test_cane_throw.gd`) and `tests/test_chests.gd`.

**Step 1, changed:**
- `scripts/content/stat_effect.gd`: `bite_damage_bonus`, `bite_range_bonus`, `bites_through`.
- `scripts/core/player_stats.gd`, `scripts/core/run_state.gd`: the bite stats and `RunState.bite_damage_mult()`.
- `scripts/actors/player.gd`: the throw sends teeth, the swing never waits for them.
- `scripts/world/combat_feedback.gd`, `scripts/world/sound_bank.gd`, `scripts/core/hit_stop.gd`, `scripts/core/key_bindings.gd`, `scripts/scenes/floor_scene.gd`.
- `scripts/content/floor_def.gd`: `chest_weights` and `chest_odds()`. `scripts/content/enemy_def.gd`: `drops_key`.
- `scripts/world/room_view.gd`, `scripts/world/pickup.gd` (`_draw_body`), `scripts/world/thermos.gd`, `scripts/world/enemy_marks.gd`.
- `data/items/dentures.tres`, `data/potions/fury_liniment.tres`, the four floor `.tres` files.
- `tools/smoke_driver.gd` and the tests that named the old throw.

**Step 2, new:** `data/floors/landing_3.tres`, `data/floors/funeral_parlour.tres` and `data/floors/golden_years_mall.tres` (placeholders first), `scripts/core/card_deck.gd`, `scripts/core/slot_machine.gd`, `scripts/core/blackjack.gd`, `scripts/core/draw_poker.gd`, `scripts/world/arcade_table.gd`, `scripts/ui/card_table_panel.gd`, `data/npcs/dealer.tres`, `data/rooms/arcade/`, `tests/test_third_floor_unlocks.gd`, `tests/test_arcade_rules.gd`, `tests/test_arcade_room.gd`.

**Steps 3 and 4, new:** per path, a hazard rule and its node, behaviors for three regular enemies, a mini boss and a floor boss, their `.tres` files, two returning enemies, props, a palette and about 30 layouts. Names are given in each task.

---

## Step 1: Dentures and chests

### Task 1: Denture rules and stats

**Files:**
- Rename: `scripts/core/cane_throw.gd` → `scripts/core/denture_throw.gd` with its `.uid`, and `tests/test_cane_throw.gd` → `tests/test_dentures.gd` with its `.uid` (`git mv` both files of each pair, so the uid stays valid).
- Modify: `scripts/content/stat_effect.gd`, `scripts/core/player_stats.gd`, `scripts/core/run_state.gd`, `data/items/dentures.tres`, `data/potions/fury_liniment.tres`
- Create: `data/upgrades/denture_adhesive.tres`
- Test: `tests/test_dentures.gd`, `tests/test_potions.gd`, `tests/test_stats.gd`, `tests/test_vaults.gd`

**Interfaces:**
- Produces:
  - `DentureThrow.new(delay := RETURN_DELAY)`, `RETURN_DELAY := 3.0`, `QUICK_RETURN_DELAY := 2.0`, `BASE_RANGE := 170.0`, `var return_delay: float`
  - `DentureThrow.try_throw() -> bool`, `drop()`, `tick(delta)`, `catch_teeth()`, `is_held()`, `is_flying()`, `is_dropped()`, `is_returning()`
  - `StatEffect.bite_damage_bonus: float`, `StatEffect.bite_range_bonus: float`, `StatEffect.bites_through: int`
  - `PlayerStats.bite_damage_mult: float`, `bite_range: float`, `bites_per_throw: int`, `teeth_return_delay: float`
  - `RunState.bite_damage_mult() -> float`, which adds a running buff's `damage_bonus`

- [x] **Step 1: Write the failing tests** in `tests/test_dentures.gd`. Keep every state test of the old file, renamed to the teeth, and add:

```gdscript
func test_a_shorter_delay_brings_them_back_sooner() -> void:
	var teeth := DentureThrow.new(DentureThrow.QUICK_RETURN_DELAY)
	teeth.try_throw()
	teeth.drop()
	teeth.tick(DentureThrow.QUICK_RETURN_DELAY + 0.01)
	assert_true(teeth.is_returning())


func test_adhesive_levels_raise_bite_range_and_return() -> void:
	var adhesive := _shipped_upgrade("denture_adhesive")
	assert_eq(adhesive.merchant, "black_market", "sold beside Reinforced Cane")
	assert_eq(adhesive.prices, PackedInt32Array([50, 120, 240]))
	var upgrades: Array[UpgradeDef] = [adhesive]
	var bites := [1.0, 1.15, 1.30, 1.45]
	var ranges := [170.0, 210.0, 250.0, 290.0]
	var delays := [3.0, 3.0, 3.0, 2.0]
	for level in 4:
		var stats := PlayerStats.compute(upgrades, {adhesive.id: level}, _no_items())
		assert_near(stats.bite_damage_mult, bites[level], "bite at level %d" % level)
		assert_near(stats.bite_range, ranges[level], "range at level %d" % level)
		assert_near(stats.teeth_return_delay, delays[level], "return at level %d" % level)
		assert_near(stats.damage_mult, 1.0, "the cane is untouched at level %d" % level)


func test_extra_strong_dentures_bite_harder_and_through_two() -> void:
	var items: Array[ItemDef] = [_shipped_item("dentures")]
	var stats := PlayerStats.compute(_no_upgrades(), {}, items)
	assert_near(stats.bite_damage_mult, 1.5)
	assert_eq(stats.bites_per_throw, 2)
	assert_near(stats.damage_mult, 1.0, "the cane gets nothing from them any more")


func test_fury_covers_the_teeth_and_the_cane() -> void:
	var run := RunState.new(_no_upgrades(), {})
	run.give_potion(Content.potion("fury_liniment"))
	run.drink_potion()
	assert_near(run.damage_mult(), 1.5)
	assert_near(run.bite_damage_mult(), 1.5)


func test_an_old_save_without_adhesive_loads_at_level_zero() -> void:
	var raw := {"version": ProgressData.VERSION, "pension": 10, "upgrades": {"reinforced_cane": 2}, "opening_seen": true}
	assert_eq(ProgressData.from_dict(raw).level_of("denture_adhesive"), 0)
```

Also update the old counts: `test_stats.gd` expects 7 upgrades and 5 at the Black Market, and `test_vaults.gd`'s total becomes `2055 + 380 + 410`. In `test_potions.gd`, the Fury test also asserts `run.bite_damage_mult()`.

- [x] **Step 2: When testing is allowed, run the tests to make sure they fail.** Expected: `DentureThrow`, `bite_damage_mult` and `denture_adhesive` are unknown.

- [x] **Step 3: Implement.**
  - **`DentureThrow`:** the old `CaneThrow` with `catch_cane` renamed `catch_teeth`, a `return_delay` member set by `_init`, and the three constants above.
  - **`StatEffect`:** add the three fields, each with a one-line comment. Note on `damage_bonus` that it is cane damage only.
  - **`PlayerStats.compute`:** sum `bite_damage_bonus` and `bite_range_bonus` times the level, take the largest `bites_through` of anything owned (never below 1), and set `teeth_return_delay` to `QUICK_RETURN_DELAY` when an upgrade with `bite_range_bonus > 0` is at its last level.
  - **`RunState.bite_damage_mult()`:** `stats.bite_damage_mult + (buff.damage_bonus if buff != null else 0.0)`. Change the comment on `damage_mult()` to say it is the cane's.
  - **Data:**
    - `dentures.tres`: drop `damage_bonus`, add `bite_damage_bonus = 0.5` and `bites_through = 2`. Description: "Thrown dentures bite 50% harder and through up to 2 enemies. Don't ask how."
    - `fury_liniment.tres`: description "Cane and dentures hit 50% harder for 15 seconds." Its `damage_bonus` already feeds both multipliers.
    - `denture_adhesive.tres`: modelled on `reinforced_cane.tres`, no `merchant` line (so the Black Market sells it), `prices = PackedInt32Array(50, 120, 240)`, `bite_damage_bonus = 0.15`, `bite_range_bonus = 40.0`.

- [x] **Step 4: When testing is allowed, run the tests.** Expected: `N tests, 0 failed`.

- [x] **Step 5: Commit.**

```powershell
git commit -m @'
Give the thrown dentures their own stats and add Denture Adhesive

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
'@
```

### Task 2: The thrown dentures in play

**Files:**
- Rename: `scripts/actors/thrown_cane.gd` → `scripts/actors/thrown_dentures.gd` with its `.uid`
- Modify: `scripts/actors/player.gd`, `scripts/scenes/floor_scene.gd:170,292`, `scripts/world/combat_feedback.gd`, `scripts/world/sound_bank.gd`, `scripts/core/hit_stop.gd`, `scripts/core/key_bindings.gd`, and comments in `barrel.gd`, `grass_tuft.gd`, `hole.gd`
- Modify: `tools/smoke_driver.gd` (`_check_shield`, a new `_check_dentures`, the props check's wording)
- Test: `tests/test_dentures.gd`, `tests/test_combat_feedback.gd`, `tests/test_hit_stop.gd`, `tests/test_sound_bank.gd`, `tests/test_key_bindings.gd`, `tests/test_stage2_props.gd`, `tests/test_enemy_types.gd`

**Interfaces:**
- Consumes: Task 1's `DentureThrow` and the bite stats.
- Produces:
  - `ThrownDentures.setup(state: DentureThrow, player: Node2D, direction: Vector2, bite_mult: float, max_range := DentureThrow.BASE_RANGE, bites := 1)`
  - `ThrownDentures.advance_travel(travelled, delta, max_range := BASE_RANGE) -> float`, `bite_damage(bite_mult) -> float`, `touches_body(point, body) -> bool`, `keeps_flying(bites_done, bites_allowed) -> bool`
  - `ThrownDentures.DAMAGE := 14.0`, `HIT_REACH := 10.0`, `SPAWN_AHEAD := 20.0`, `WALL_LAYER := 1`
  - `Player.can_throw(teeth) -> bool`, `Player.can_swing(teeth) -> bool` (static), `Player.has_teeth() -> bool`, `Player.recall_teeth()`
  - Signals `Player.teeth_thrown`, `teeth_bit`, `teeth_caught`, and `CombatFeedback.on_teeth_thrown/on_teeth_bit/on_teeth_caught`
  - Sounds `"teeth_throw"` and `"teeth_catch"`, and `HitStop.BITE_HIT`
  - The input action keeps its id `"throw"`, so old `keys.json` files still bind it. Its label becomes "Throw dentures".

- [x] **Step 1: Write the failing tests.** In `tests/test_dentures.gd`:

```gdscript
func test_the_cane_swings_whatever_the_teeth_are_doing() -> void:
	var teeth := DentureThrow.new()
	assert_true(Player.can_swing(teeth), "held")
	teeth.try_throw()
	assert_true(Player.can_swing(teeth), "flying")
	teeth.drop()
	assert_true(Player.can_swing(teeth), "lying on the floor")


func test_combo_and_charge_still_work_while_the_teeth_fly() -> void:
	var player := Player.new()
	assert_true(player._teeth.try_throw())
	assert_false(player.has_teeth())
	assert_true(player._combo.try_attack() > 0, "a combo swing starts")
	player._charge.start()
	player._charge.tick(ChargeSwing.CHARGE_TIME + 0.01)
	assert_true(player._charge.release(), "a charged swing fires")
	player.free()


func test_advance_travel_caps_at_the_range_it_is_given() -> void:
	var delta := 1.0 / 60.0
	for max_range: float in [170.0, 210.0, 290.0]:
		var travelled := 0.0
		var frames := 0
		while travelled < max_range and frames < 1000:
			travelled = ThrownDentures.advance_travel(travelled, delta, max_range)
			frames += 1
		assert_eq(frames, ceili(max_range / (ThrownDentures.FLY_SPEED * delta) - 0.0001))
		assert_eq(travelled, max_range)


func test_one_bite_ends_a_flight_and_the_item_allows_a_second() -> void:
	assert_false(ThrownDentures.keeps_flying(1, 1))
	assert_true(ThrownDentures.keeps_flying(1, 2))
	assert_false(ThrownDentures.keeps_flying(2, 2))
```

In `tests/test_key_bindings.gd`, assert the throw's label is "Throw dentures", and that a file written as `{"throw": {"type": "key", "code": KEY_F}}` still binds the throw to F. Rename the old tests' calls (`on_cane_hit` → `on_teeth_bit`, `CANE_HIT` → `BITE_HIT`, the sound names, `ThrownCane.WALL_LAYER` → `ThrownDentures.WALL_LAYER`).

- [x] **Step 2: When testing is allowed, run the tests to make sure they fail.**

- [x] **Step 3: Implement `ThrownDentures`.**
  - **Flight:** as `ThrownCane`, but `_range` from setup replaces `MAX_RANGE`, and `_bitten` holds the instance ids already bitten. A bite emits `hit_enemy` and drops the teeth unless `keeps_flying(_bitten.size(), _bites_allowed)`.
  - **The world:** walls, barrels, piles and grass are met exactly as before, with `BreakableBlock.SOURCE_CANE`, since the spec says the world treats the teeth as it treated the thrown cane.
  - **Drawing:** a small set of teeth from the side, gums top and bottom, four white teeth each, the jaw opening `JAW_OPEN` px at `CHATTER_SPEED` while flying, and slower with a little hop while dropped. Flip with the throw's direction.

- [x] **Step 4: Implement the player.**
  - **State:** `_teeth := DentureThrow.new()` and `_thrown_teeth: ThrownDentures`.
  - **`_handle_attacks`:** the throw fires when `can_throw(_teeth)`, then the swing code runs every frame regardless. Remove the early return and the old `_charge.cancel()` on throw. `can_swing` returns `true` and is the documented rule the tests hold.
  - **`_throw_teeth`:** set `_teeth.return_delay = run.stats.teeth_return_delay` before `try_throw`, spawn at `SPAWN_AHEAD`, and pass `run.bite_damage_mult()`, `run.stats.bite_range` and `run.stats.bites_per_throw`.
  - **Drawing:** the placeholder cane line always draws, since he never lets go of it.
  - **Callers:** `floor_scene.gd` calls `recall_teeth()`, and `CombatFeedback.watch_player` connects the renamed signals.
  - **Feedback:** `SoundBank` gets `"teeth_throw"` (a short rising square clack) and `"teeth_catch"` in place of the cane sounds, and `HitStop.CANE_HIT` becomes `BITE_HIT`.

- [x] **Step 5: Extend the smoke driver.** Add `_check_dentures(scene)` to `_check_fight_room`, after `_check_shield`, in a made room:
  - **Bite:** a frozen Intern Reaper 128 px away. Aim at it, press `throw`, and check `has_teeth()` is false and its health fell by `ThrownDentures.bite_damage(run.bite_damage_mult())`.
  - **Melee while away:** a second frozen enemy 30 px behind him. `_swing_at` it while the teeth lie by the first, and check it was hurt and `has_teeth()` is still false.
  - **Return:** wait until `has_teeth()`, and check it took at least `run.stats.teeth_return_delay` seconds from the throw.
  - **Pierce:** set `run.stats.bites_per_throw = 2`, throw at the far one of two enemies in a row, check both were bitten, and put the value back.
  - **Wording:** `_check_shield` says "thrown dentures go over the shield" and calls `recall_teeth()`.

- [x] **Step 6: When testing is allowed, run the tests and 3 full loops.** Expected: `0 failed` and `SMOKE PASS` each time.

- [x] **Step 7: When testing is allowed, look at it in a real window.** Screenshot the teeth flying, lying on the floor and coming back, and the Black Market panel with five upgrades at its fullest (lesson: the 360 px screen hides tall panels).

- [x] **Step 8: Commit.** One commit for the actor, player and feedback rename with its tests, one for the smoke check.

### Task 3: Chest rules and each floor's odds

**Files:**
- Create: `scripts/core/chest_rules.gd`
- Modify: `scripts/content/floor_def.gd`, `data/floors/floor_1.tres`, `cemetery.tres`, `sunset_shores.tres`, `furnace_works.tres`
- Test: `tests/test_chests.gd` (new)

**Interfaces:**
- Produces:
  - `ChestRules.LUNCHBOX`, `LOCKED`, `SAFE`, `URN`, `MIMIC` and `KINDS: Array[String]`, in that order
  - `ChestRules.odds_for_depth(weights: Dictionary, depth: int) -> Dictionary`: every kind present, negatives as 0, and no mimic above depth `MIMIC_FROM_DEPTH := 2`
  - `ChestRules.roll(odds: Dictionary, roll_value: float) -> String`: a weighted pick walking `KINDS` in order, and `LOCKED` when the odds add up to nothing
  - `display_name(kind)`, `prompt_for(kind)`, `slips_needed(kind)`, `opens_by_hand(kind)`, `opens_by_blast(kind)`, `can_open(kind, slips)`
  - `lunchbox_pension(treasure_pension)`, `lunchbox_extra(roll) -> String` (a `RoomRules.DROP_*`), `safe_pension(treasure_pension)`, `urn_fallback_pension(treasure_pension)`, `coin_split(total, count) -> Array[int]`
  - `FloorDef.chest_weights: Dictionary` and `FloorDef.chest_odds() -> Dictionary`

**The numbers:**

| Floor | Lunchbox | Locked | Safe | Urn | Mimic | Rare share (safe, urn, mimic) |
|---|---|---|---|---|---|---|
| 1 (Records Basement, Cemetery) | 50 | 30 | 12 | 8 | 0 | 20% |
| 2 (Sunset Shores, Furnace Works) | 40 | 26 | 16 | 10 | 8 | 34% |
| 3 (Funeral Parlour, Mall, from Task 6) | 32 | 24 | 18 | 13 | 13 | 44% |

- **Lunchbox:** a quarter of the floor's `treasure_pension`, rounded up and at least 1. A 20% chance of a small potion and a 15% chance of a Thermos.
- **Safe:** twice `treasure_pension`, split over 4 coins.
- **Urn:** 2 items from the usual pool. With none left, twice `treasure_pension`.
- **Mimic:** `pension_drop = 5` before the floor's multiplier, and a Slip.

- [x] **Step 1: Write the failing tests** in `tests/test_chests.gd`:

```gdscript
func test_first_floors_never_roll_a_mimic() -> void:
	for path: String in FLOOR_ONE:
		var def: FloorDef = load(path)
		assert_near(float(def.chest_odds()[ChestRules.MIMIC]), 0.0, path)
		assert_eq(_counts(def.chest_odds(), 3000, 11)[ChestRules.MIMIC], 0, path)


func test_second_floors_roll_mimics_and_more_rare_chests() -> void:
	var first: FloorDef = load(FLOOR_ONE[0])
	for path: String in FLOOR_TWO:
		var def: FloorDef = load(path)
		assert_true(_share(def.chest_odds(), RARE) > _share(first.chest_odds(), RARE), path)
		assert_true(_counts(def.chest_odds(), 3000, 12)[ChestRules.MIMIC] > 0, path)


func test_a_roll_walks_the_kinds_in_order() -> void:
	var odds := {"lunchbox": 50, "locked": 30, "safe": 12, "urn": 8, "mimic": 0}
	assert_eq(ChestRules.roll(odds, 0.0), ChestRules.LUNCHBOX)
	assert_eq(ChestRules.roll(odds, 0.51), ChestRules.LOCKED)
	assert_eq(ChestRules.roll(odds, 0.81), ChestRules.SAFE)
	assert_eq(ChestRules.roll(odds, 0.93), ChestRules.URN)
	assert_eq(ChestRules.roll(odds, 0.9999), ChestRules.URN, "a kind with no weight is never picked")


func test_what_each_kind_costs_to_open() -> void:
	assert_true(ChestRules.can_open(ChestRules.LUNCHBOX, 0))
	assert_false(ChestRules.can_open(ChestRules.LOCKED, 0))
	assert_true(ChestRules.can_open(ChestRules.LOCKED, 1))
	assert_false(ChestRules.can_open(ChestRules.URN, 1))
	assert_true(ChestRules.can_open(ChestRules.URN, 2))


func test_a_safe_holds_a_big_pile_over_several_coins() -> void:
	assert_eq(ChestRules.safe_pension(8), 16)
	var coins := ChestRules.coin_split(16, ChestRules.SAFE_COINS)
	assert_eq(coins.size(), 4)
```

Also: rolls follow the weights within 2% over 20000 seeded rolls; a first floor ignores mimic weight in its data; a mimic has a Locked Chest's name and prompt; no key opens a safe or a mimic; lunchbox amounts and extras; `coin_split` sums.

- [x] **Step 2: When testing is allowed, run them to make sure they fail.**

- [x] **Step 3: Implement `ChestRules` and `FloorDef`.** In `FloorDef`, add an `@export_group("Chests")` with `chest_weights` defaulting to the first-floor row, and `chest_odds()` returning `ChestRules.odds_for_depth(chest_weights, depth)`. Write the row for each floor into its `.tres` (keys sorted, as Godot writes them).

- [x] **Step 4: When testing is allowed, run the tests.**

- [x] **Step 5: Commit** ("Roll five kinds of chest by each floor's odds").

### Task 4: Chests in rooms, and the mimic

**Files:**
- Create: `scripts/world/chest.gd`, `scripts/actors/behaviors/mimic_behavior.gd`, `data/enemies/mimic.tres`
- Modify: `scripts/world/pickup.gd` (`_draw_body`), `scripts/world/room_view.gd` (`_create_chest`, the openers, `_wake_mimic`, `drops_key`), `scripts/world/thermos.gd` (`Chest.blast`), `scripts/content/enemy_def.gd` (`drops_key`), `scripts/world/enemy_marks.gd` (`"chest_jaw"`)
- Test: `tests/test_chests.gd`

**Interfaces:**
- Consumes: Task 3's `ChestRules` and `FloorDef.chest_odds()`.
- Produces:
  - `Chest extends Pickup`, with `kind: String`, signals `woke(at: Vector2)` and `blasted_open(at: Vector2)` (local positions), `wake() -> bool`, `blast_open() -> bool`, `is_open() -> bool`
  - `Chest.blast_among(nodes: Array, center: Vector2, radius: float) -> int` and `Chest.blast(tree, center, radius) -> int`. Only `Thermos._explode` calls it, so Auditor blasts and bosses open nothing.
  - `RoomView._create_chest(cell: Vector2i, kind: String) -> Chest`, for the smoke driver's chest room
  - `EnemyDef.drops_key: bool`, and `FloorDef.mimic: EnemyDef`: what a mimic wakes into on that floor. A floor naming none never rolls one, and room code never names enemy data (a standing test checks this).
  - `MimicBehavior.should_lunge(distance, cooldown) -> bool`, `lane_length() -> float`, `WINDUP := 0.6`

**Rules:**
- **Opening:**
  - A lunchbox, a locked chest and an urn open like any interact pickup, with `can_take` checking `ChestRules.can_open`. `Chest.collect()` also refuses when `can_take` says no, so nothing can open a chest for free.
  - A safe never answers the key, and shows "Needs a Thermos" when Grandpa stands beside it.
  - A mimic wakes when Grandpa's feet come within `Pickup.COLLECT_RADIUS`, when anything calls `collect()` on it, or when the player's Thermos goes off beside it.
- **The mimic's look and fight:**
  - It is drawn exactly as a Locked Chest, with one tell: a slow breathing swell of 7% over 2.6 s.
  - Woken, it becomes a `mimic` enemy on its cell, which waits `Enemy.ROOM_WAKE_TIME` and shouts "Surprise!". Its first lunge waits 0.4 s more, then shows a warning circle and a lane for the whole of its 0.6 s windup, whatever the player's warning stat, since it starts right beside him.
  - It pays its Pension and drops a Slip (`drops_key`, never for a summon).
- **Looks:** every kind is code-drawn and distinct by colour and shape, standing on one floor line:
  - **Lunchbox:** a red tin with a domed lid, a pale stripe and a wire handle.
  - **Locked Chest:** a brown chest with dark bands and a gold padlock.
  - **Safe:** a grey steel box with a dial and hinges.
  - **Urn:** a tall gold urn.
- **The urn's choice:** two items on open spots beside it, kept in a `ChoiceGroup` held in `RoomView._urn_groups` (lesson: a signal alone does not keep a `RefCounted` alive).

- [x] **Step 1: Write the failing tests:**

```gdscript
func test_a_safe_ignores_the_key_and_opens_to_a_blast() -> void:
	var safe := _chest(ChestRules.SAFE)
	var opened := [0]
	safe.blasted_open.connect(func(_at: Vector2): opened[0] += 1)
	safe.collect()
	assert_false(safe.is_queued_for_deletion(), "the interact key does nothing")
	assert_eq(Chest.blast_among([safe], Vector2(500, 500), 56.0), 0, "a far blast misses")
	assert_eq(Chest.blast_among([safe], Vector2(30, 0), 56.0), 1)
	assert_eq(opened[0], 1)
	safe.free()


func test_a_mimic_wakes_when_reached_for() -> void:
	var mimic := _chest(ChestRules.MIMIC)
	var woke := [0]
	mimic.woke.connect(func(_at: Vector2): woke[0] += 1)
	mimic.collect()
	assert_eq(woke[0], 1)
	assert_false(mimic.wake(), "wakes once")
	mimic.free()


func test_the_mimic_pays_well_drops_a_slip_and_warns_first() -> void:
	var mimic: EnemyDef = load("res://data/enemies/mimic.tres")
	assert_true(mimic.drops_key)
	assert_true(MimicBehavior.WINDUP >= 0.5)
	assert_false(MimicBehavior.should_lunge(30.0, 0.2), "rests first")
	assert_true(MimicBehavior.should_lunge(30.0, 0.0))
```

Also: a blast wakes a mimic but leaves honest chests; a locked chest waits for its Slip; a lunchbox opens for free; no regular enemy of floors 1 and 2 drops a Slip.

- [x] **Step 2: When testing is allowed, run them to make sure they fail.**

- [x] **Step 3: Implement** `Chest`, the mimic and the `RoomView` changes as above. `Pickup._draw` calls a new `_draw_body()`, which `Chest` overrides. `_create_rewards` rolls each `C` cell with `ChestRules.roll(_floor_def.chest_odds(), _rng.randf())`. Remove `CHEST_COLOR`, `CHEST_LABEL` and `CHEST_PROMPT`.

- [x] **Step 4: When testing is allowed, run the tests.**

- [x] **Step 5: Commit** ("Turn chest cells into lunchboxes, locked chests, safes, urns and mimics").

### Task 5: The chest room in the full loop, and the step's wrap-up

**Files:**
- Modify: `tools/smoke_driver.gd`, `docs/playtest-notes.md`, `LESSONS.md`, this plan

- [x] **Step 1: Add `_check_chests(scene)` to `_check_fight_room`.** It runs in a made room, with every kind placed by `view._create_chest`, so it never depends on what the floors rolled:
  - **Lunchbox:** opens to the interact key with no Slip, and pays at least `lunchbox_pension`.
  - **Locked Chest:** stays shut without a Slip, then opens and spends one.
  - **Urn:** one Slip is not enough. Two open it and are spent, it lays out `mini(2, offerable)` items, and taking one clears the other.
  - **Safe:** a Slip and an Auditor's `EnemyBlast` leave it shut. The player's Thermos opens it and pays at least `safe_pension`.
  - **Mimic:** it asks for a Slip like a locked chest and sleeps until touched. Touched, it becomes a `mimic` enemy that never bites before its warning shows. Beaten, it pays at least 5 and drops a Slip.
  - **The run:** after the probe, Slips are put back as they were. `_run` checks `_checked_chests` after the first run.
- [x] **Step 2: Mimics in the loop.** Before `_clear_room` gathers pickups, `_beat_mimics_first()` wakes and beats any mimic the room rolled. Otherwise walking onto a coin beside one could leave a live enemy in a room the loop counts as clear. The pass line reports chests checked and mimics beaten on the way.
- [x] **Step 3: Update `docs/playtest-notes.md`** with what to try, and `LESSONS.md` if anything tricky came up.
- [x] **Step 4: When testing is allowed:** run the tests, then 3 full loops from an exported copy, and screenshot each chest kind and the mimic awake in a real window. Fix anything found, push, then stop for the user to play.

---

## Step 2: The connection and the Arcade Room

Read these as models first: `floor_scene.gd` (`PATHS_BY_DEPTH`, `_go_down`, `_continue_after_floor`), `tests/test_floor_unlocks.gd`, `data/floors/landing.tres`, `crossroads_view.gd`, `floor_builder.gd` (`_attach_detours`), `retirement_station.gd` (an interactable station), `scripts/world/npc.gd` with `data/npcs/shop_merchant.tres`, and `scripts/ui/potion_panel.gd` (a `CanvasLayer` panel).

### Task 6: Depth 3, its landing, its Crossroads and the end of the run

**Files:**
- Create: `data/floors/landing_3.tres` (display name "Floor 3"), `data/floors/funeral_parlour.tres` and `data/floors/golden_years_mall.tres`. The two paths are placeholders that point `rooms_dir` at `res://data/rooms/sunset_shores/` and copy Sunset Shores' enemies and bosses.
- Modify: `scripts/scenes/floor_scene.gd`, `tools/smoke_driver.gd`
- Test: `tests/test_third_floor_unlocks.gd` (new)

**Interfaces:**
- Produces:
  - `PATHS_BY_DEPTH[3] = ["res://data/floors/funeral_parlour.tres", "res://data/floors/golden_years_mall.tres"]`, and `LAST_DEPTH := 3`
  - `const LANDINGS_BY_DEPTH := {2: "res://data/floors/landing.tres", 3: "res://data/floors/landing_3.tres"}`, replacing `LANDING_FLOOR`
  - The Funeral Parlour: `depth = 3`, `open_after_depth = 2`, `clears_to_open = 0`, `danger = 3`, id `"funeral_parlour"`, display name "Eternal Rest Funeral Parlour".
  - The Mall: `depth = 3`, `open_after_depth = 3`, `clears_to_open = 1`, `danger = 4`, id `"golden_years_mall"`, display name "Golden Years Mall at 7 a.m.", closed hint "Beat a third-floor boss first".
  - Both paths: `health_mult = 1.8`, `pension_mult = 2.0`, `enemies_by_size = {"small": 6, "medium": 8, "large": 13}`, and the floor-3 chest row from Task 3.

- [x] **Step 1: Write the failing tests:** (written, not yet run)

```gdscript
extends TestCase


func _parlour() -> FloorDef:
	return load("res://data/floors/funeral_parlour.tres")


func _mall() -> FloorDef:
	return load("res://data/floors/golden_years_mall.tres")


func test_the_parlour_is_always_open_and_the_mall_waits_for_a_third_floor_clear() -> void:
	var data := ProgressData.new()
	assert_true(_parlour().is_open_for(data))
	assert_false(_mall().is_open_for(data))
	data.record_floor_cleared(2, "sunset_shores")
	assert_false(_mall().is_open_for(data), "a second-floor clear is not enough")
	data.record_floor_cleared(3, "funeral_parlour")
	assert_eq(data.clears_at(3), 1)
	assert_true(_mall().is_open_for(data))
	assert_eq(_mall().closed_hint, "Beat a third-floor boss first")


func test_third_floor_clears_survive_a_save_and_an_old_save_has_none() -> void:
	var data := ProgressData.new()
	data.record_floor_cleared(3, "golden_years_mall")
	var loaded := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_eq(loaded.clears_at(3), 1)
	assert_true(loaded.has_cleared_path("golden_years_mall"))
	var old := ProgressData.from_dict({"version": ProgressData.VERSION, "pension": 0, "upgrades": {}, "opening_seen": true, "floors_cleared": 2})
	assert_eq(old.clears_at(3), 0)


func test_third_floor_difficulty_follows_the_spec() -> void:
	for def: FloorDef in [_parlour(), _mall()]:
		assert_eq(def.depth, 3)
		assert_near(def.health_mult, 1.8)
		assert_near(def.pension_mult, 2.0)
		assert_eq(def.enemies_by_size, {"small": 6, "medium": 8, "large": 13})
		assert_true(float(def.chest_odds()[ChestRules.MIMIC]) >= 13.0)


func test_the_third_landing_names_floor_3() -> void:
	var landing: FloorDef = load("res://data/floors/landing_3.tres")
	assert_eq(landing.display_name, "Floor 3")
	assert_eq(landing.depth, 3)
```

- [ ] **Step 2: When testing is allowed, run the tests to make sure they fail, then implement.** Implemented; the tests are written but not yet run.
  - **`_go_down`:** load `LANDINGS_BY_DEPTH[_depth]` after raising `_depth`. Everything else stays: the map, the 2-pill heal and its notice.
  - **`_continue_after_floor`:** needs no change, since it already compares against `LAST_DEPTH`.
  - **Saves:** `ProgressData` needs no change, since `deep_clears` already keeps any depth.
- [x] **Step 3: Extend the smoke driver.** Written, not yet run. `tools/smoke.ps1` has no timeout of its own, so only `TIMEOUT` (now 1080 s) was raised; the run time is still to be measured.
  - **The run:** `_clear_two_floors` becomes `_clear_three_floors(first, second, third)`. It checks `debug_depth() == 3`, the landing's "Floor 3" name and the heal, the Mall refused before a third-floor clear, then open after one.
  - **The run's end:** a floor-3 boss ends the run with "FLOOR CLEARED".
  - **Paths:** the second pass clears the Mall.
  - **Timeout:** raise `TIMEOUT` and the timeout in `tools/smoke.ps1` to fit the longer run, and report the new run time.
- [ ] **Step 4: When testing is allowed, run the tests and 3 full loops.**
- [x] **Step 5: Commit**, one commit each for the floor defs, the scene change and the smoke driver. Made as one commit for the task, as the build brief asked.

### Task 7: The games' rules

**Files:**
- Create: `scripts/core/card_deck.gd`, `scripts/core/slot_machine.gd`, `scripts/core/blackjack.gd`, `scripts/core/draw_poker.gd`
- Test: `tests/test_arcade_rules.gd` (new)

**Interfaces:**
- Produces:
  - **`CardDeck`:**
    - `CardDeck.new(rng: RandomNumberGenerator)` holds 52 cards as ints `rank * 4 + suit` (rank 2..14, suit 0..3) and shuffles with its own generator (never `Array.shuffle`, which uses the global one).
    - `draw() -> int`, `static rank(card) -> int`, `static suit(card) -> int`, `static label(card) -> String`, such as `"Q♥"`.
  - **`SlotMachine`:**
    - `SYMBOLS := ["cherry", "bell", "pill", "skull", "coin", "dentures"]` and `spin(rng) -> Array[String]` (3 reels).
    - `payout(reels, bet) -> Dictionary` returns `{"pension": int, "item": bool, "full_heal": bool}`.
    - `PULLS_PER_VISIT := 3`, `BET := 10`.
  - **`Blackjack`:**
    - `Blackjack.new(deck)`, `deal()`, `hit()`, `stand()`, `static hand_value(cards: Array[int]) -> int` (aces count 11 or 1).
    - `is_blackjack(cards) -> bool`, `outcome() -> String` (`"win"`, `"blackjack"`, `"push"`, `"lose"`, `"bust"`), and `static payout(outcome, bet) -> int`.
    - The dealer draws to 17 and stands on all 17s.
  - **`DrawPoker`:**
    - `DrawPoker.new(deck)`, `deal() -> Array[int]`, `draw(held: Array[bool]) -> Array[int]`.
    - `static rank_hand(cards) -> String` and `static payout(hand_name, bet) -> int`.
    - Paytable, as the total handed back for the bet: jacks or better 1×, two pair 2×, three of a kind 3×, straight 4×, flush 6×, full house 9×, four of a kind 25×, straight flush 40×, royal flush 50×. So jacks or better returns the bet, as a pair does on the slot and a blackjack win returns 2×. If the simulated return misses ~90%, tune the middle of the table, never its two ends, which the spec names.
  - `BETS := [10, 25, 50]` on Blackjack and DrawPoker.

- [x] **Step 1: Write the failing tests:** (written, not yet run)

```gdscript
extends TestCase


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _card(rank: int, suit := 0) -> int:
	return rank * 4 + suit


func test_a_deck_holds_52_different_cards_and_the_same_seed_deals_the_same() -> void:
	var a := CardDeck.new(_rng(5))
	var b := CardDeck.new(_rng(5))
	var seen := {}
	for i in 52:
		var card := a.draw()
		assert_eq(card, b.draw())
		seen[card] = true
	assert_eq(seen.size(), 52)


func test_aces_count_high_until_they_would_bust() -> void:
	assert_eq(Blackjack.hand_value([_card(14), _card(13)]), 21)
	assert_eq(Blackjack.hand_value([_card(14), _card(14), _card(9)]), 21)
	assert_eq(Blackjack.hand_value([_card(10), _card(9), _card(5)]), 24)
	assert_true(Blackjack.is_blackjack([_card(14), _card(12)]))


func test_blackjack_payouts() -> void:
	assert_eq(Blackjack.payout("win", 10), 20)
	assert_eq(Blackjack.payout("blackjack", 10), 25)
	assert_eq(Blackjack.payout("push", 10), 10)
	assert_eq(Blackjack.payout("lose", 10), 0)


func test_poker_hands_are_ranked() -> void:
	assert_eq(DrawPoker.rank_hand([_card(10, 1), _card(11, 1), _card(12, 1), _card(13, 1), _card(14, 1)]), "royal_flush")
	assert_eq(DrawPoker.rank_hand([_card(11), _card(11, 1), _card(3), _card(5, 2), _card(9)]), "jacks_or_better")
	assert_eq(DrawPoker.rank_hand([_card(10), _card(10, 1), _card(3), _card(5, 2), _card(9)]), "nothing", "tens are not enough")
	assert_eq(DrawPoker.rank_hand([_card(14), _card(2, 1), _card(3), _card(4, 2), _card(5)]), "straight", "the ace plays low")


func test_three_skulls_give_an_item_and_three_pills_a_full_heal() -> void:
	assert_true(SlotMachine.payout(["skull", "skull", "skull"], 10)["item"])
	assert_true(SlotMachine.payout(["pill", "pill", "pill"], 10)["full_heal"])
	assert_eq(SlotMachine.payout(["bell", "bell", "cherry"], 10)["pension"], 10, "a pair returns the bet")
	assert_eq(SlotMachine.payout(["coin", "coin", "coin"], 10)["pension"], 50)


func test_each_game_returns_about_ninety_percent() -> void:
	# Item and heal wins count at the Pension a shop charges for them, so the slot's return is comparable.
	for game in ["slot", "blackjack", "poker"]:
		var back := ArcadeOdds.simulated_return(game, 20000, _rng(9))
		assert_true(back > 0.85 and back < 0.95, "%s returns %f" % [game, back])
```

`ArcadeOdds.simulated_return` lives in `scripts/core/arcade_odds.gd`:
- **Blackjack:** it plays a simple player who hits below 17.
- **Poker:** it plays a simple player who holds pairs and better, and four to a flush.
- **Slot:** it counts an item at 60 Pension and a full heal at 30.
- **Tuning:** tune the reel weights and, if needed, the poker table until all three land between 85% and 95%.

- [ ] **Step 2: When testing is allowed, run the tests to make sure they fail, implement until they pass, and commit** ("Add the rules of the slot machine, blackjack and draw poker").
  - Implemented and committed before testing was allowed. The returns were estimated outside the engine with the same rules and simple players: the slot about 89.8% (reel weights 15, 11, 4, 2, 4, 4), poker about 89.5% (the table as written, no tuning needed), and blackjack about 94.2%. Blackjack's rules are all fixed by the spec, and with them a player who hits below 17 gets back about 94%, so the seeded test may land above 95%. If it does, the gentlest lever is the dealer hitting a soft 17, which the spec would then need to allow.

### Task 8: The Arcade Room

**Files:**
- Modify: `scripts/content/room_layout.gd` (`TYPE_ARCADE := "arcade"` and a `SYMBOL_GAME` letter for a table, after checking which letters are free), `scripts/world/room_rules.gd` (its icon), `scripts/world/door.gd` and `scripts/ui/floor_map_view.gd` (draw a die for the arcade icon instead of text), `scripts/core/floor_builder.gd`, `scripts/content/floor_def.gd` (`arcade_chance: float = 0.25`), `scripts/world/room_view.gd`
- Create: `data/rooms/arcade/arcade_small_01.tres` and `arcade_01.tres` (shared by every floor, read by `FloorBuilder` from `const ARCADE_DIR := "res://data/rooms/arcade/"`), `data/npcs/dealer.tres`, `scripts/world/arcade_table.gd`
- Test: `tests/test_arcade_room.gd` (new)

**Interfaces:**
- Produces:
  - `FloorBuilder` attaches one arcade room to a combat room after the vaults when `rng.randf() < def.arcade_chance`, as a dead end that needs no bomb.
  - `ArcadeTable` (a `Node2D` like `RetirementStation`) has `game: String` (`"slot"`, `"blackjack"`, `"poker"`), `plays_left: int`, `signal play_wanted(game: String)` and `refill()`. `RoomView.refresh_doors()` calls `refill()` on each table, which is what "once per visit" means.
  - `RoomView._create_arcade()` places the Dealer NPC by `layout.merchant_cell()` and a table on each game cell.

- [x] **Step 1: Write the failing tests:** (written in `tests/test_arcade_room.gd`, not yet run)
  - **Frequency:** over 1000 seeds of each floor def, an arcade room appears on 20% to 30% of floors, never on the main path, and always with exactly one door.
  - **Validation:** the arcade layouts validate, hold one of each table and a merchant spot, and have no enemy cells.
  - **Plays:** a table's `plays_left` is 3 for the slot and 1 for the cards, and `refill()` restores it.
  - **Model:** follow `test_vaults.gd`'s builder tests.
- [ ] **Step 2: When testing is allowed, run them to make sure they fail, then implement.** Implemented; the tests are not yet run. The table letter is `G`. Tables also count as rivals for the Dealer's talk prompt, and the full loop skips them as plain blocks.
  - **The look:** the room is safe, with neon light and a loud carpet. Add a palette override for arcade rooms in `RoomView`: bright magenta and cyan fill lights and a high-contrast `carpet_motif`.
  - **The Dealer:** placeholder lines such as "Place your bets.", "The house is very understanding." and "No refunds, even in the afterlife."
- [ ] **Step 3: When testing is allowed, run tests and 3 full loops, screenshot the room and its door's die, and commit.** Committed before testing; the runs and screenshots are still to do.

### Task 9: The card-table overlay

**Files:**
- Create: `scripts/ui/card_table_panel.gd` (a `CanvasLayer` like `PotionPanel`), drawn in code: green felt, cards as white rounded rectangles with rank and suit, and three reels.
- Modify: `scripts/scenes/floor_scene.gd` (open it, freeze the player as the Waiting Room does, close it), `scripts/world/room_view.gd` (pay out through `_bank`, item wins through `RoomRules.pick_items` and `_add_free_item`, and a full heal through `_run.health.heal(_run.health.max_pills)`), `tools/smoke_driver.gd`

**Rules:**
- **Bets:** come from `Progress` through `_bank.spend(bet)`, refused when short.
- **Safety:** the room has no enemies, and the overlay pauses nothing else. It only freezes the player and closes with the interact key or its Leave button.
- **Smoke:** whenever the full loop meets an arcade room, it plays each game once through the panel's own methods with a seeded generator, and checks Pension moved by exactly the rule's payout. A made arcade room (as `_check_chests` does) guarantees the check runs every time.

- [ ] **Step 1: Implement, then when testing is allowed run the tests and 3 full loops, and screenshot the overlay at its fullest (a blackjack hand of five cards and the poker hand), since the view is only 360 px tall.** Implemented; the runs and screenshots wait for testing. The overlay closes by polling the interact key in `_process` (see `LESSONS.md`), and the full loop plays every table of a made arcade room and of any arcade room a floor rolls.
- [x] **Step 2: Update the docs, push, and stop.** The connection step is checked by the user before the Funeral Parlour.

---

## Step 3: The Eternal Rest Funeral Parlour

Read these as models first:
- **Data:** `data/floors/sunset_shores.tres` and `furnace_works.tres` (palettes, enemies with weights, multipliers).
- **Behaviors:** `scripts/actors/behaviors/foreman_behavior.gd` (a mini boss with statics for every pattern), `chief_stoker_behavior.gd` and `matron_behavior.gd` (floor bosses with two phases and followups), `cart_nurse_behavior.gd` (a lane charge that smashes props), `bingo_caller_behavior.gd` (ground marks), `soot_ghost_behavior.gd`.
- **Hazards:** `scripts/core/vent_cycle.gd` with `scripts/world/floor_vent.gd` (a timed room hazard), and `shockwave.gd` (a ring a dodge passes through).
- **Tests:** `tests/test_furnace_enemies.gd`, `test_furnace_bosses.gd` and `test_furnace_floor.gd`.

### Task 10: Organ pipes

**Files:**
- Create: `scripts/core/pipe_beat.gd` (pure), `scripts/world/organ_pipe.gd`, `scripts/world/pipe_ring.gd`
- Modify: `scripts/content/room_layout.gd` (a wall-pipe symbol; pipes sit in wall cells, as the secret crack does), `scripts/world/room_view.gd`, `scripts/actors/player.gd` (`push` already exists for the bellows), `scripts/actors/enemy.gd` (an `apply_push(shove, seconds)` that adds to its knockback)
- Test: `tests/test_parlour_hazard.gd` (new)

**Interfaces:**
- `PipeBeat.new(period := 3.2, glow := 0.8, offset := 0.0)`
- `PipeBeat.state_at(time) -> int`, one of `PipeBeat.QUIET`, `GLOW` or `CHORD`, with the chord on the last instant of each period.
- `PipeRing.push_for(center, radius_now, width, point, strength) -> Vector2`: a push away from the pipe while the ring's band passes the point, and zero otherwise.

**Rules:**
- **Damage:** the ring does none. It pushes Grandpa at 220 px/s for 0.35 s, and enemies the same.
- **Dodging:** a dodge passes through, as `Player._handle_movement` already cancels a push while dodging.

- [x] **Step 1: Write failing tests** for `PipeBeat` (glow before each chord, offsets shift it, the cycle repeats) and `PipeRing.push_for` (inside the band pushes outward, the hollow and beyond do not, and the push never costs a pill). Written in `tests/test_parlour_hazard.gd`, not yet run.
- [ ] **Step 2: Implement, and when testing is allowed run the tests and screenshot a room with pipes. Commit.** Implemented and committed before testing; the tests, the screenshot and the `.uid` files of the new scripts wait for the first run.
  - **The symbol:** `o`, in a plain border wall cell as a lantern is, counted as wall everywhere, and kept off the cells beside a door.
  - **The chord:** `PipeBeat.CHORD` is the last 0.1 s of each period, and `chords_between` sends each ring exactly once whatever the frame times.
  - **The ring:** drawn on the room's side of the wall only, reach 150 px. `force_chord(glow, reach, damage)` lets a floor boss play every pipe at once; only those rings may cost a pill, and they show their whole reach while they glow.

### Task 11: Funeral Parlour regular enemies

**Files:**
- Create: `weeping_mourner_behavior.gd`, `florist_behavior.gd` and `pallbearer_behavior.gd` in `scripts/actors/behaviors/`, with `.tres` files. Also `parlour_plot_holder.tres` and `parlour_seasonal_temp.tres`, the two returning Cemetery enemies in the floor's colours.
- Test: `tests/test_parlour_enemies.gd` (new)

**What each one does.** Base health and pay match a first-floor enemy of the same role. The floor's `health_mult` and `pension_mult` do the rest.
- **Weeping Mourner:**
  - **Packs:** a pack of 3 (`group_size = 3`, as the Seasonal Temp) drifts toward Grandpa at speed 40 with `chase_direction()`.
  - **The lunge:** every 4 s the leader wails (`say("Wooo...")`, a 0.8 s warning circle on each member), then all three lunge 70 px along their own warned lanes at once.
  - **Static:** `MourningPack.lunge_lanes(members: Array[Vector2], target: Vector2) -> Array[Vector2]`.
- **The Florist:**
  - **Distance:** she keeps 130 px or more away.
  - **Wreaths:** every 3.2 s she lobs a wreath at a warned spot near Grandpa (0.9 s warning, using `GroundStrike.throw_from` as the Stoker does). It leaves a ring of thorns of radius 26 for 3 s, hurting at most once per 0.6 s, which is `strike_ground`'s `linger`.
  - **Static:** `FloristBehavior.wreath_spot(target, rng) -> Vector2` lands within 40 px.
- **The Pallbearers:**
  - **A pair:** two spawn as one group of 2, carrying a coffin between them.
  - **The ram:** after a 0.9 s warned lane (width 36), they charge 240 px at 300 px/s, smashing props with `enemy.smash`, and stop at walls (`BossDash.stops_at`).
  - **Losing one:** when one dies, the other drops the coffin (a solid prop for 6 s) and fights alone with the melee behavior's rules.
  - **Static:** `PallbearerBehavior.alone(partner_alive: bool) -> bool`.

- [x] **Step 1: Write failing tests** for each static, as `test_furnace_enemies.gd` does. Written in `tests/test_parlour_enemies.gd`, not yet run.
- [ ] **Step 2: Implement until they pass. When testing is allowed, look at each in a real window. Commit one commit per enemy, and one for the two returning enemies.** Implemented before testing, in one commit for the task as the build brief asked; the tests and the look in a real window are still to do.
  - **Packs:** `MourningPack` (`scripts/actors/behaviors/mourning_pack.gd`) is shared through the members' metadata. A group's leader gathers its followers, and mourners with no pack (the Reverend's summons) gather any free mourners within 160 px. The first living member runs the clock, so a pack never wails three times as fast. The warning on each member shows whole.
  - **Wreaths:** `GroundStrike` gained a look, `LOOK_THORNS`, which draws a thrown wreath and a ring of brambles instead of coal and fire. The damage rules are the burning ground's.
  - **Pallbearers:** the leader pairs with the nearest follower of its kind within 96 px and runs the pair's clock; both show their own lane and ram together. One hit a ram for the pair, from either bearer or the coffin between them (`ram_hits`). The dropped coffin is `DroppedCoffin`, solid for 6 s unless it would land on Grandpa's feet, broken only by blasts and bosses.
  - **Colours:** mourners pale lavender, the Florist green, Pallbearers charcoal, the Plot Holder mustard and the Seasonal Temp cyan.

### Task 12: The Reverend, Officiant of Last Words (mini boss)

**Files:** `scripts/actors/behaviors/reverend_behavior.gd`, `data/enemies/reverend.tres`, tests in `tests/test_parlour_bosses.gd` (new).

**Stats:** at least as hard as the strengthened Barbara and Foreman Klaus. The final health is 560, so the `.tres` holds 560 / 1.8. Speed 75, pays 8 before the multiplier, and rests 0.8 s between attacks.
- **Eulogy:** 6 words fall one after another, 0.18 s apart, onto spots in a line from him through Grandpa. Each spot is warned 0.8 s and uses `strike_line`. Static: `eulogy_spots(from, to, count) -> Array[Vector2]`.
- **Collection plate:** a boomerang out 180 px and back along a warned curve (a lane out, plus marks along the return). Static: `plate_path(from, aim, length, bend) -> Array[Vector2]`.
- **Summon:** 3 Mourners every 12 s, through `request_summon_at`, with at most 5 enemies in the room (`BossMoves.can_summon`). They pay nothing.

- [x] **Step 1: Write failing tests:** the eulogy has 6 spots evenly spaced along the line, every plate path point is inside the room rectangle, and he never summons over the cap. Written in `tests/test_parlour_bosses.gd`, not yet run.
- [ ] **Step 2: Implement. When testing is allowed, look at every attack in a real window. Commit.** Implemented and committed before testing; the tests and the look in a real window are still to do.
  - **The eulogy:** the line runs from him to 60 px past Grandpa (at least 140 px), so it always passes through him, and it shows as a lane during the 0.6 s windup.
  - **The plate:** `plate_path` takes an optional room rectangle and keeps every point inside it, which is what the test checks. `CollectionPlate` (`scripts/world/collection_plate.gd`) marks the way back for the whole windup, the way out being his warned lane, then flies at 320 px/s and costs a pill once a throw.
  - **The summon:** `summon_count(alive, cap)` calls only as many as fit under 5, at most 3.
  - **The numbers:** 560 final health (311.111 in the `.tres`), speed 75, pays 8, rests 0.8 s. Barbara and Klaus end at 500 and rest 0.825 s, call 2 and alternate two attacks.

### Task 13: Mortimer Grimsby, Funeral Director (floor boss)

**Files:** `scripts/actors/behaviors/funeral_director_behavior.gd`, `data/enemies/mortimer_grimsby.tres`, `tests/test_parlour_bosses.gd`. Add `Enemy.HEAVIEST_DAMAGE := 3` beside `HEAVY_DAMAGE`.

**Stats:** clearly harder than Matron Mercy and Old Smokey. The final health is 1700, speed 75, pays 16 before the multiplier. It goes into phase two below half health, with 1.2× speed and 0.8× windups.
- **Casket slam:** a coffin slams onto a warned spot of radius 44 under Grandpa. It costs `HEAVIEST_DAMAGE`, so it gets the extra-clear warning:
  - **Timing:** a 1.2 s windup shown whole (`set_warning(..., true)`, whatever the player's warning stat).
  - **Look:** a second outer ring and a dark coffin shadow that grows over the spot.
- **Procession:** pallbearers march across the room in 4 warned lanes with one gap, never the last gap. Statics: `procession_lanes(room_rect, direction, gap)` and `next_gap(last, rng)`, as the Foreman's steam lines.
- **Embalming spray:** a 0.9 s warned cone, 50° and 120 px, that slows Grandpa with `Player.slow(0.5, 1.5)` and costs 1 pill. Reuse `ChiefStokerBehavior.in_cone` and the cone warning.
- **Organ crescendo:** every pipe in the room glows, then chords in a pattern that always leaves one safe spot. Static: `crescendo_safe_spot(pipes, room_rect, rng)`, tested to always leave a cell no ring band reaches at its chord time. In a room without pipes he uses the casket slam instead.
- **Second phase:** he climbs into a coffin. Between his other attacks the coffin charges like the Pallbearers (0.9 s warned lane, smashing props, stopping at walls), with followups as Matron's gurney.

- [x] **Step 1: Write failing tests:** the slam costs 3 and its warning is shown whole, the procession always leaves its gap inside the room and moves it each time, the crescendo always has a safe spot over 200 seeds, and phase two chains the charge. Written in `tests/test_parlour_bosses.gd`, not yet run.
- [ ] **Step 2: Implement. When testing is allowed, look at every attack in a real window, the casket slam's warning above all. Commit.** Implemented and committed before testing; the tests and the look in a real window are still to do.
  - **The casket:** a `GroundStrike` of radius 44 locked under Grandpa, whose fill always runs the whole 1.2 s, with `LOOK_CASKET` (a second ring 8 px out and a coffin shadow growing over the spot). His own warning circle shows whole too. The second phase never shortens it, and the coffin charge keeps its 0.9 s; every other windup is 0.8 times as long.
  - **The procession:** 5 slots of 40 px around Grandpa (`procession_slot`), 4 marching and 1 gap, so "4 warned lanes with one gap". The band is moved inside the room like the Foreman's steam lines, and the lanes turn each time. Each lane is a `ProcessionLane` (`scripts/world/procession_lane.gd`): warned for 1 s, then a row of bearers and a coffin marches down it at 300 px/s and costs a pill once.
  - **The crescendo:** the rings of the beat do no damage, so the crescendo's rings cost a pill, or it would be no attack. Every pipe glows 1.3 s (staggered 0.1 s) and chords with a ring that stops 26 px short of one safe cell, at least 74 px from every pipe and within 120 px of Grandpa when one is. Its reach shows as a red arc while it glows. A pipe that would reach under 24 px is held quiet instead, so no harmless push can shove him off the spot. If he falls first, the pipes never chord.
  - **The numbers:** 1700 final health (944.444 in the `.tres`), speed 75, pays 16, rests 0.65 s and 0.45 s below half health. Matron and Smokey end at 1500 and rest 0.8/0.6 and 0.7/0.5. He does not summon.

### Task 14: Funeral Parlour floor content

**Files:**
- Modify: `data/floors/funeral_parlour.tres`, replacing Task 6's placeholder
- Create: `data/rooms/funeral_parlour/`, prop scripts (`wreath_stand.gd`, `candle_stand.gd` and `hymn_cart.gd`, which break like barrels or grass; `chapel_pew.gd`, solid and broken only by blasts and bosses), decor kinds in `room_decor.gd` (stained-glass light pools, coffins on stands)

**What to build:**
- **Palette:** dark wood panelling, burgundy carpet, stained-glass coloured fill lights and candlelight. Judge it from a screenshot with enemies in the room (lesson).
- **Layouts:** about 30, in the same small, medium and large proportions as `data/rooms/furnace_works/`, with 6, 8 and 13 enemy cells. Pews stand in rows that make lanes, and wall pipes appear in some rooms. Include a mini boss room, a floor boss room with pipes, a shop, treasure, healing, vault and secret-capable rooms, and `C` cells.
- **Floor def:** the 3 new enemies and 2 returning ones with weights, the Reverend and Mortimer Grimsby, and Task 6's multipliers and chest odds.
- **Income:** check income per full clear with the income probe approach (see `LESSONS.md`). Aim for about 2× the first floor's 125 to 136 without blasting.

- [x] **Step 1: Palette, props and decor, and commit.** Written; committed with the layouts and the floor def in one commit for the task, as the build brief asked. Not yet seen in a window.
  - **Props:** `ChapelPew` (`h`, a `RockBlock`, can hide a coin at the furniture rate), `HymnCart` (`j`, a `Barrel`), `WreathStand` (`r`) and `CandleStand` (`c`, with its own flickering light), both like a vase. Their colours are new palette fields.
  - **Decor:** `stained_glass` (a coloured pool of light on the floor, its colour fixed by its spot) and `coffin_stand`. Walls get `wall_pattern = 2`, upright wooden panels under a rail.
  - **Palette:** burgundy carpet with a gold woven motif and a dark wooden patch tone, dark wood walls, dim mauve ambient, violet fill light, warm candle torches, a 6% flicker.
- [ ] **Step 2: Layouts. When testing is allowed, run the layout validation tests over the folder, then commit.** 33 layouts written in the Furnace Works' proportions (7 medium, 3 large and 3 small combat rooms with 8, 13 and 6 enemy cells, and every other room type). Pews stand in rows that make lanes, 12 rooms have wall pipes, both floor boss rooms have at least 12, and three combat rooms hold a `C` cell. Not yet validated in Godot: checked instead with a PowerShell port of `RoomLayout.validate()`, the enemy counts and `vault_extra_cells`, which passed all 33 and, as a control, failed the Furnace Works' rooms only on their second-floor enemy counts.
- [ ] **Step 3: The floor def. When testing is allowed, run the tests and 3 full loops, then commit.** Written: the three new enemies and the two returning ones (weights 3, 4, 3, 3, 2), the Reverend, Mortimer Grimsby, Task 6's multipliers and chest odds, and a treasure worth 16 (twice the first floor's 8). Tests in `tests/test_parlour_floor.gd`, not yet run; the shop and chest tests now cover the folder too.
  - **Income:** not measured, since nothing may run. Every enemy that paid 1 pays 2, as on the second floors, and rooms hold one more enemy, so a full clear should land a little above the second floors' 217, short of the 250 to 270 aimed for. The probe and any tuning wait for testing.
- [ ] **Step 4: When testing is allowed, screenshot small, medium and large rooms in a real window next to Sunset Shores rooms.** The floors must look clearly different.
- [ ] **Step 5: Update `docs/playtest-notes.md` and `LESSONS.md`, push, then stop for the user to play.** Notes and lessons updated and pushed; the play waits for testing.

---

## Step 4: The Golden Years Mall at 7 a.m.

Same models as Step 3, plus `scripts/world/wet_floor.gd`, `scripts/world/lights_out.gd` and `scripts/core/slow_effect.gd`'s `SlideRule`.

### Task 15: Escalator conveyors

**Files:**
- Create: `scripts/core/conveyor_rule.gd` (pure), `scripts/world/conveyor_strip.gd` (an `Area2D` one cell wide, drawn with moving arrows)
- Modify: `room_layout.gd` (four direction symbols, after checking which letters are free), `room_view.gd`, `player.gd` and `enemy.gd` (add the strip's carry to the velocity after movement)
- Test: `tests/test_mall_hazard.gd` (new)

**Interfaces:**
- `ConveyorRule.carry(strip_dir: Vector2, speed: float) -> Vector2`, added to whatever stands on the strip. Walking against a 60 px/s strip at 120 nets 60, and with it 180.
- `ConveyorCycle.new(period := 6.0, chime := 1.0)` with `direction_sign_at(time) -> int` and `is_chiming(time) -> bool`, for rooms whose strips reverse after a chime and flashing arrows.

**Rules:**
- **Damage:** the strips never do any.
- **Dodging:** a dodge ignores the carry, as it ignores sliding.
- **Ghosts:** ghosts and anything underground are not carried.

- [x] **Step 1: Write failing tests** for `carry` (with, against, and across a strip) and `ConveyorCycle` (the chime always comes before each reversal, and the sign flips each period). In `tests/test_mall_hazard.gd`, with the strip's own reversal, a boss's order, who rides and the door rule.
- [ ] **Step 2: Implement. When testing is allowed, screenshot a room with strips. Commit.** Implemented, tests run and passing (878); the screenshot waits for a real window.
  - **The symbols:** `>`, `<`, `^` and `v`, the way each strip runs, walkable, never within 2 cells of a door. A layout's `strips_reverse` (default false, so old layouts load as before) makes its strips reverse.
  - **The strip:** `ConveyorStrip` carries at 60 px/s. A reversing room's strips run 6 s each way, chiming with flashing arrows for the last 1 s. `take_control(REVERSE or SPEED_UP)` chimes 1 s, then reverses, or runs ×1.5 for 4 s.
  - **Who rides:** Grandpa's walk and every enemy with `rides_strips()` (not ghosts, mounds or wall fixtures). A dodge sets his velocity outright, so it ignores the carry.

### Task 16: Mall regular enemies

**Files:** `mall_walker_behavior.gd`, `mall_cop_behavior.gd` and `perfume_sprayer_behavior.gd` with `.tres` files. Also `mall_intern_reaper.tres` and `mall_notary_public.tres`, the two returning Records Basement enemies in the floor's colours. Tests in `tests/test_mall_enemies.gd`.

- **Mall Walkers:**
  - **The loop:** a line of 3 (`group_size = 3`) power-walks a loop around its spawn (a rectangle 4 by 3 cells, `walker_loop(origin, cells) -> Array[Vector2]`), and hurts on contact (1 pill, at most once per 0.8 s).
  - **The break:** after a warned whistle (0.8 s, a warning on each member), the line breaks off toward Grandpa for 2.5 s, then returns to its loop.
- **Mall Cop:**
  - **The charge:** a scooter charge along a 0.8 s warned lane, 260 px.
  - **The whistle:** then he stops and whistles, which sets the nearest other enemy's target speed ×1.5 toward Grandpa for 2 s. Static: `nearest_other(enemies, me) -> int`, the index or -1.
- **Perfume Sprayer:**
  - **Distance:** she keeps 120 px or more away.
  - **Clouds:** she sprays a cloud at a warned spot (0.9 s) that lingers 4 s, radius 40.
  - **Inside a cloud:** Grandpa's view shrinks. Reuse `LightsOut` with a short dark time and `LIGHT_RADIUS` about 55, shown only while his feet are in a cloud, so every warning still draws above it (lesson: warnings stay on their own high layer).

- [x] **Step 1: Write failing tests** for `walker_loop` (closed, inside the room, 4 corners), contact damage at most once per 0.8 s, `nearest_other`, and a cloud's coverage test. In `tests/test_mall_enemies.gd`.
- [ ] **Step 2: Implement. When testing is allowed, look at each in a real window. Commit one commit per enemy, and one for the returning pair.** Implemented, tests run and passing (895), in one commit for the task as the build brief asked; the look in a real window is still to do.
  - **Walkers:** a `WalkerLine` (`scripts/actors/behaviors/walker_line.gd`) is shared through metadata, as the mourners' pack is. Its first living member runs the clock and walks the loop at the walker's speed (70), with members 26 px apart. `walker_loop(origin, room_cells, is_open)` keeps the rectangle half a cell off the walls and starts from another corner when the room's walk grid says the first way is blocked. The whistle shows on every member whole; the break chases at 1.5× speed with `chase_direction()`.
  - **Mall Cop:** charges 260 px at 320 px/s down a lane that ends at props, stops at anything solid, then says "FWEEET!" and calls `Enemy.rally(2.0)` on the nearest enemy that answers a whistle (no bosses). A rallied enemy walks at 1.5× toward Grandpa only when it would walk anyway, so it never drops an attack.
  - **Perfume Sprayer:** keeps 120 to 200 px away and sprays every 3.6 s. `PerfumeCloud` warns 0.9 s, hangs 4 s (radius 40) and never hurts. `PerfumeHaze` is a `LightsOut` (which gained `light_radius`, `text` and `current_shade()`) with a 55 px light, eased in only while his feet are in a cloud; it draws at the dark's z, under warnings and shots. Placeholder colours: walkers orange, the Cop blue, the Sprayer pink, the Intern Reaper lime and the Notary Public yellow.

### Task 17: Gloria, Mall Fountain Diva (mini boss)

**Files:** `scripts/actors/behaviors/fountain_diva_behavior.gd`, `data/enemies/gloria.tres`, `tests/test_mall_bosses.gd` (new).

**Stats:** at least as hard as Barbara and Klaus. The final health is 560, speed 70, pays 8, and she rests 0.8 s.
- **Coin toss:** a spray of wishing-well coins along 5 warned lanes in a 60° fan (`BossMoves.fan_directions`), each warned 0.7 s.
- **Splash:** fountain jets on 3 warned spots near Grandpa (0.9 s). Each leaves a 3×3 patch of `WetFloor` for 4 s, added and removed by the boss. Static: `splash_cells(target_cell, count, rng)`, kept off walls and door cells.
- **Summon:** a line of 3 Mall Walkers every 12 s, capped by `BossMoves.can_summon`. They pay nothing.

- [x] **Step 1: Write failing tests** for `splash_cells` and the fan of 5. In `tests/test_mall_bosses.gd`, with the summon cap, her pay-nothing walkers and her numbers against Barbara, Klaus and the Reverend.
- [ ] **Step 2: Implement. When testing is allowed, look at every attack in a real window. Commit.** Implemented, tests run and passing (904); the look in a real window is still to do.
  - **The coins:** all 5 lanes show on her during the 0.7 s windup through a new `Enemy.add_warning_lane`, which draws extra lanes beside the main one and clears with the warning. The coins fly at 230 px/s and draw as coins (`Projectile.look`).
  - **The splash:** `splash_cells(target_cell, count, rng, room_cells, is_open)` puts the first jet under him and the rest within 3 cells, 2 apart, off walls, doors, props and strips. Each jet is a `GroundStrike` of radius 26 with a spray look; `GroundStrike` gained a `landed` signal, on which a `WetSplash` lays the 3×3 patch (less any cell that may not be wet) for 4 s and then takes it up.
  - **The numbers:** 560 final health (311.111 in the `.tres`), speed 70, pays 8, rests 0.8 s, alternates her two attacks, and calls 3 walkers every 12 s under a cap of 5 enemies.

### Task 18: The Mall Santa (floor boss)

**Files:** `scripts/actors/behaviors/mall_santa_behavior.gd`, `data/enemies/mall_santa.tres`, an elf `.tres` that reuses the melee behavior at speed 140, and `tests/test_mall_bosses.gd`.

**Stats:** clearly harder than Matron and Old Smokey. The final health is 1700, speed 80, pays 16.
- **Sleigh run:** a charge along a lane with a 1.2 s warning shown whole and a second outer outline. It costs `Enemy.HEAVIEST_DAMAGE` (3 pills), uses `BossDash`, smashes props and stops at walls.
- **Present drop:** 4 gift boxes land on warned spots (0.9 s), and each bursts into a ring of 6 shots (`BossMoves.ring_directions`).
- **"Ho ho hold still":** a warned ring closes from radius 120 to 20 around where Grandpa stood over 1.4 s. It hurts if he is still inside when it shuts, and a dodge passes through its band. Static: `closing_radius(time)`, tested to reach 20 at the end.
- **Conveyor control:** reverses or speeds up (×1.5 for 4 s) every strip in the room, after the strips' own chime. With no strips he uses the present drop.
- **Second phase:** he summons fast elves, at most 3 alive (`BossMoves.can_summon` counting only elves), and the sleigh run chains straight into a present drop.

- [ ] **Step 1: Write failing tests:** the sleigh costs 3 with a whole warning, never more than 3 elves, `closing_radius`, and phase two's followup.
- [ ] **Step 2: Implement. When testing is allowed, look at every attack in a real window. Commit.**

### Task 19: Mall floor content

The same work as Task 14, for `data/floors/golden_years_mall.tres` and `data/rooms/golden_years_mall/`:
- **Look:** shiny tile, closed shop shutters, potted palms, benches, a fountain, a food court and flickering fluorescent lights (`palette.flicker`).
- **Props:** shopping carts, sale-sign stands and gumball machines break. Fountains and planters are solid.
- **Strips:** in some rooms, never within 2 cells of a door, and some rooms reverse.
- **Checks:** the income check, 3 full loops when testing is allowed, and screenshots against the Funeral Parlour. Then update the docs, push and stop for the user to play.

---

## Step 5: Balance and review

### Task 20: Balance pass

- [ ] **Step 1:** Teach the simulated player the organ rings, the strips, the closing ring and the perfume clouds, as it was taught vents and wet floors.
- [ ] **Step 2:** When testing is allowed, measure wins for each third-floor path on the three saves (fresh, some upgrades, nearly maxed), starting at the third Crossroads with a typical haul from two floors.
- [ ] **Step 3:** Tune only `health_mult`, boss windups and summon timers.
  - **Floor bosses:** each must take more hits and longer fights than Matron Mercy and Old Smokey on the same save.
  - **Mini bosses:** each must be at least equal to the strengthened Barbara and Klaus.
  - **The record:** write before and after in `docs/playtest-notes.md`.
- [ ] **Step 4:** Rebalance chest odds and Arcade payouts against measured income if either moves a full clear's Pension by more than 10%.
- [ ] **Step 5:** When testing is allowed, run the tests and 3 full loops, then commit and push.

### Task 21: Independent review

- [ ] **Step 1:** Dispatch one reviewer on the strongest model, read-only, over `git diff caead10...third-floor`, against the spec. Use the same brief as the earlier reviews, which forbids running Godot and the real save.
- [ ] **Step 2:** Verify each finding by reading the code. Fix the confirmed ones, one commit each, with tests.
- [ ] **Step 3:** When testing is allowed, run the tests and 6 full loops, push, and write a short report for the user in the style of `docs/night-report-2026-11-03.md`. Don't merge until the user has played it.
