# Room Rules and Flashbacks (floor-1 prototype) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the floor-1 prototype of the spec `docs/superpowers/specs/2026-11-09-rules-and-flashbacks-design.md`: one rule room on floor 1, the Auditor when the rule is broken, a film reel when it is kept, and two playable younger-Harold eras that a reel unlocks for one room.

**Architecture:** Pure rule logic lives in small core classes (`RoomRule`, `RulePicker`, `RuleWatch`, `Eras`) that tests can load without autoloads. One `RuleKeeper` node, owned by `FloorScene`, joins them to the running game: it hears the player's action signals and the room's events, shows the HUD pieces and calls the room to bring in the Auditor. The eras are a `EraMoves` helper the `Player` consults when an era is active, so old Harold's code path is untouched when no flashback runs.

**Tech Stack:** Godot 4.7.2, GDScript, the repo's own test runner (`tests/run_tests.gd`), PixelLab MCP for art, `tools/sfx/sfx.py` for sounds.

## Global Constraints

- Worktree: `C:\GameDev\game\.worktrees\rules-flashbacks`, branch `rules-flashbacks` (made from `combined` at 0cf70fc). Every path below is relative to it.
- Godot: `D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` (call it `$GODOT`). The first run in a fresh worktree needs `& $GODOT --headless --path . --import`.
- Quick test run (PowerShell, from the worktree): `& $GODOT --headless --path . --script res://tests/run_tests.gd -- --only=<fragment>`. Read `tests/run_tests.gd` once to confirm what `--only` matches; if it matches method names rather than files, use a method-name fragment.
- Full suite: `powershell -File tools/test.ps1`. Full loop: `powershell -File tools/smoke.ps1` (must print `SMOKE PASS`). Read the "N tests, M failed" line every time.
- **One heavy Godot job at a time** (this PC blue-screened under load). Check `Get-Process *godot*` before every launch; if a windowed Godot is running, the user is playing: stop and wait.
- **Never write to `%APPDATA%\Godot\app_userdata\Grandpa\`.** Record the MD5 of `profile` save files there at the start of each task and confirm at the end (it may change only if the user played).
- Never name other games anywhere (code, comments, assets, commits).
- No religious or devil imagery: no crosses or plus-shapes in pictograms, no 666, halos, pentagrams. The crossing-out stroke is one diagonal slash inside a circle.
- No new dependencies or add-ons.
- All player-facing strings go through `tr()`.
- The warning red `#e4524f` and safe-spot mint `#7fe0a0` are never used for the rule icon's pulse.
- Edit GDScript with the Edit tool or `py -I` scripts with `C:/...` paths. Never Git Bash `sed -i` or PowerShell `Set-Content`. Before each commit run a CRLF pass on new files and check with `git ls-files --eol` (LESSONS L117, L220).
- Any node an attack or effect leaves in a room must be added to `RoomView.is_passing_effect` (room_view.gd:333).
- Sound names appear literally on `Sfx.play("...")` lines, are in `SoundBank.NAMES`, and have real `.wav` files (tests/test_sfx.gd). Do not use the name `stamp`.
- Commits: imperative mood, one logical change, ending with the line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Push with `env -u GIT_TERMINAL_PROMPT -u GCM_INTERACTIVE git push -u origin rules-flashbacks` (Git Bash).
- Read `LESSONS.md` before starting. Append a dated one-liner for every new gotcha.

## Decisions this plan adds to the spec

These close gaps the code exposed; the spec's intent is kept.

1. **Using a reel at a door.** A door enters on its own as soon as Harold walks onto an open one, so he can't stand in a doorway and press F. Instead, pressing F **within 48 px of a door that leads into a room whose fight hasn't started** *readies* the reel for that door: Harold glows sepia and a notice says "Memory ready: go through the door". Walking through that door spends it. Going through another door cancels the readying and keeps the reel.
2. **The Auditor's 2 s walk-in.** The room reserves him the moment the rule breaks (its enemy count goes up by one), so the room cannot clear in those 2 s.
3. **The Auditor's damage** is one pill per hit, like every enemy. Only his health scales by floor, through `FloorDef.health_mult`, as for all enemies; enemy damage has no depth multiplier in this game.
4. **The Auditor is not a boss** (`is_boss = false`). A boss's death clears every other enemy in the room.
5. **The reel pickup's id is `memory_reel`.** `film_reel` is already a Cinema enemy.
6. **Era ids:** `rec_football_1960` and `no12_bus_1975`.
7. **Bomb blasts.** A Thermos blast counts as Harold breaking an exhibit; an enemy's blast (`EnemyBlast`) or a boss smash does not.
8. **Saving.** The run checkpoint has no `.bak` (only the profile has), so the run fields follow the checkpoint's own atomic write.

## File map

| File | New/Modify | Responsibility |
|---|---|---|
| `scripts/core/room_rule.gd` | new | rule ids, sign text, what each forbids, readiness |
| `scripts/core/rule_picker.gd` | new | which rooms of a floor get a rule, and which rule |
| `scripts/core/rule_watch.gd` | new | one room's rule state: active, broken, kept, lifted; loitering clock; pulse |
| `scripts/core/eras.gd` | new | the two eras' data |
| `scripts/world/rule_keeper.gd` | new | runtime glue in a floor: rules, Auditor call, reels, flashbacks |
| `scripts/ui/rule_pictogram.gd` | new | draws each rule's pictogram into an Image |
| `scripts/ui/rule_stamp.gd` | new | the centre-screen announcement and the VIOLATION / GOOD CONDUCT / REGULATION LIFTED stamps |
| `scripts/ui/rule_icon.gd` | new | the HUD rule icon under the minimap, with its pulse |
| `scripts/ui/reel_slot.gd` | new | the held reel's HUD icon |
| `scripts/world/sepia_flicker.gd` + `.gdshader` | new | the screen-wide film flicker |
| `scripts/actors/behaviors/auditor_behavior.gd` | new | the Auditor's clipboard swing and thrown FINED stamp |
| `scripts/world/ink_blot.gd` | new | the stamp's slowing ink blot |
| `data/enemies/auditor.tres` | new | the Auditor's EnemyDef |
| `scripts/actors/era_moves.gd` | new | an era's attack, dodge and throw |
| `scripts/actors/era_ball.gd` | new | the bouncing football |
| `scripts/world/ticket_line.gd` | new | the unspooled bus tickets |
| `scripts/actors/player.gd` | modify | `swing_started`, `dodge_started` signals; era hooks |
| `scripts/world/breakable_block.gd`, `scripts/world/thermos.gd` | modify | tell the room when Harold broke a prop |
| `scripts/world/room_view.gd` | modify | `prop_broken`, reserved arrival, Auditor drop, reel pickup, passing effects |
| `scripts/world/door.gd` | modify | `is_within(radius)` |
| `scripts/scenes/floor_scene.gd` | modify | own the RuleKeeper, call it on entry, checkpoint fields |
| `scripts/ui/hud.gd` | modify | host the rule icon, stamp and reel slot |
| `scripts/core/run_state.gd`, `scripts/core/run_checkpoint.gd` | modify | `held_reel` |
| `scripts/core/progress_data.gd`, `scripts/autoload/progress.gd` | modify | `eras_unlocked`, `rules_kept`, `rules_broken` |
| `scripts/core/input_setup.gd`, `pad_input.gd`, `key_bindings.gd` | modify | the `flashback` action (F, pad Y) |
| `scripts/core/dev_start.gd` | modify | DEV F7: give a reel |
| `scripts/world/sound_bank.gd`, `tools/sfx/sfx.py`, `audio/sfx/` | modify | `rule_whistle`, `rule_stamp`, `reel_flicker` |
| `scripts/actors/projectile.gd` | modify | `LOOK_FINED` stamp look |
| `tools/probes/bot_probe.gd` | modify | collect and use reels; play eras; era DPS case |
| `tests/test_room_rules.gd`, `tests/test_rule_watch.gd`, `tests/test_rule_keeper.gd`, `tests/test_rule_hud.gd`, `tests/test_auditor.gd`, `tests/test_reels.gd`, `tests/test_eras.gd` | new | tests |

---

### Task 1: Rule data and the rule picker

**Files:**
- Create: `scripts/core/room_rule.gd`, `scripts/core/rule_picker.gd`
- Test: `tests/test_room_rules.gd`

**Interfaces:**
- Produces: `RoomRule.ALL: Array[String]`, `RoomRule.sign_text(rule) -> String`, `RoomRule.action_of(rule) -> String`, `RoomRule.button_of(rule) -> String`, `RoomRule.can_apply(rule, ready: Dictionary) -> bool`, the `RoomRule.ACTION_*` and rule id constants; `RulePicker.ENABLED_DEPTH := 1`, `RulePicker.rule_room_count(depth, combat_rooms) -> int`, `RulePicker.rule_rooms(map: FloorMap, depth: int, seed_text: String) -> Array[int]`, `RulePicker.pick_rule(seed_text, room_id, ready: Dictionary) -> String`.

- [ ] **Step 1: Write the failing tests** in `tests/test_room_rules.gd`:

```gdscript
extends TestCase

const SEEDS := ["1", "42", "777", "90210", "123456789"]


func _floor_map(seed_text: String) -> FloorMap:
	return RunCheckpoint.build_floor(load("res://data/floors/floor_1.tres"), seed_text)


func test_every_rule_has_sign_text_an_action_and_a_button() -> void:
	assert_eq(RoomRule.ALL.size(), 7)
	for rule in RoomRule.ALL:
		assert_false(RoomRule.sign_text(rule).is_empty(), rule)
		assert_false(RoomRule.action_of(rule).is_empty(), rule)
	assert_eq(RoomRule.button_of(RoomRule.NO_CANE), "attack")
	assert_eq(RoomRule.button_of(RoomRule.NO_HORSEPLAY), "dodge")
	assert_eq(RoomRule.button_of(RoomRule.TEETH_IN), "throw")
	assert_eq(RoomRule.button_of(RoomRule.NO_EXPLOSIVES), "bomb")
	assert_eq(RoomRule.button_of(RoomRule.NO_FOOD), "potion")
	assert_eq(RoomRule.button_of(RoomRule.EXHIBITS), "")
	assert_eq(RoomRule.button_of(RoomRule.NO_LOITERING), "")


func test_a_rule_only_applies_where_it_can_matter() -> void:
	var bare := {"has_bomb": false, "has_potion": false, "has_breakables": false}
	assert_false(RoomRule.can_apply(RoomRule.NO_EXPLOSIVES, bare))
	assert_false(RoomRule.can_apply(RoomRule.NO_FOOD, bare))
	assert_false(RoomRule.can_apply(RoomRule.EXHIBITS, bare))
	assert_true(RoomRule.can_apply(RoomRule.NO_CANE, bare))
	var full := {"has_bomb": true, "has_potion": true, "has_breakables": true}
	for rule in RoomRule.ALL:
		assert_true(RoomRule.can_apply(rule, full), rule)


func test_floor_one_has_exactly_one_combat_rule_room() -> void:
	for seed_text in SEEDS:
		var map := _floor_map(seed_text)
		var ids := RulePicker.rule_rooms(map, 1, seed_text)
		assert_eq(ids.size(), 1, "seed %s" % seed_text)
		assert_eq(map.room(ids[0]).room_type, RoomLayout.TYPE_COMBAT, "seed %s" % seed_text)


func test_the_prototype_posts_no_rules_below_floor_one() -> void:
	for seed_text in SEEDS:
		assert_eq(RulePicker.rule_rooms(_floor_map(seed_text), 2, seed_text).size(), 0)


func test_the_counts_follow_the_depth_table() -> void:
	assert_eq(RulePicker.rule_room_count(1, 6, 99), 1)
	assert_eq(RulePicker.rule_room_count(2, 6, 99), 2)
	assert_eq(RulePicker.rule_room_count(3, 10, 99), 4, "40% of 10")
	assert_eq(RulePicker.rule_room_count(3, 3, 99), 2, "at least 2")
	assert_eq(RulePicker.rule_room_count(2, 1, 99), 1, "never more than the combat rooms")
	assert_eq(RulePicker.rule_room_count(2, 6, 1), 0, "above the enabled depth")


func test_the_same_seed_picks_the_same_rooms_and_rule() -> void:
	var ready := {"has_bomb": true, "has_potion": true, "has_breakables": true}
	for seed_text in SEEDS:
		var map := _floor_map(seed_text)
		var first := RulePicker.rule_rooms(map, 1, seed_text)
		assert_eq(RulePicker.rule_rooms(map, 1, seed_text), first)
		assert_eq(RulePicker.pick_rule(seed_text, first[0], ready), RulePicker.pick_rule(seed_text, first[0], ready))


func test_picking_never_returns_a_rule_that_cannot_apply() -> void:
	var bare := {"has_bomb": false, "has_potion": false, "has_breakables": false}
	for i in 200:
		var rule := RulePicker.pick_rule(str(i), i % 9, bare)
		assert_true(RoomRule.can_apply(rule, bare), rule)
```

Before running, confirm the floor-1 resource path with `ls data/floors/` and the FloorMap build call in `RunCheckpoint.build_floor` (run_checkpoint.gd:241). Fix the path in `_floor_map` if it differs.

- [ ] **Step 2: Run to see it fail**

Run: `& $GODOT --headless --path . --script res://tests/run_tests.gd -- --only=room_rules`
Expected: FAIL / parse error: `RoomRule` and `RulePicker` not declared.

- [ ] **Step 3: Write `scripts/core/room_rule.gd`**

```gdscript
class_name RoomRule
extends RefCounted

# The afterlife's petty rules. Each forbids an action Harold already has; he has no run.

const NO_CANE := "no_cane"
const NO_HORSEPLAY := "no_horseplay"
const TEETH_IN := "teeth_in"
const NO_EXPLOSIVES := "no_explosives"
const NO_FOOD := "no_food"
const EXHIBITS := "exhibits"
const NO_LOITERING := "no_loitering"
const ALL: Array[String] = [NO_CANE, NO_HORSEPLAY, TEETH_IN, NO_EXPLOSIVES, NO_FOOD, EXHIBITS, NO_LOITERING]

# What Harold did, as the RuleKeeper reports it.
const ACTION_SWING := "swing"
const ACTION_DODGE := "dodge"
const ACTION_THROW := "throw"
const ACTION_BOMB := "bomb"
const ACTION_POTION := "potion"
const ACTION_BREAK := "break"
const ACTION_LOITER := "loiter"

const _SIGNS := {
	NO_CANE: "LEAVE CANES AT RECEPTION",
	NO_HORSEPLAY: "NO HORSEPLAY",
	TEETH_IN: "KEEP YOUR TEETH IN",
	NO_EXPLOSIVES: "NO EXPLOSIVES",
	NO_FOOD: "NO FOOD OR DRINK",
	EXHIBITS: "DO NOT TOUCH THE EXHIBITS",
	NO_LOITERING: "NO LOITERING",
}
const _ACTIONS := {
	NO_CANE: ACTION_SWING, NO_HORSEPLAY: ACTION_DODGE, TEETH_IN: ACTION_THROW, NO_EXPLOSIVES: ACTION_BOMB,
	NO_FOOD: ACTION_POTION, EXHIBITS: ACTION_BREAK, NO_LOITERING: ACTION_LOITER,
}
# The input action whose press is about to break it, for the icon's pulse. "" when no button does.
const _BUTTONS := {
	NO_CANE: "attack", NO_HORSEPLAY: "dodge", TEETH_IN: "throw", NO_EXPLOSIVES: "bomb", NO_FOOD: "potion",
	EXHIBITS: "", NO_LOITERING: "",
}
# How often each is picked, among the rules that can apply.
const WEIGHTS := {
	NO_CANE: 2.0, NO_HORSEPLAY: 3.0, TEETH_IN: 3.0, NO_EXPLOSIVES: 1.0, NO_FOOD: 1.0, EXHIBITS: 2.0, NO_LOITERING: 2.0,
}


static func sign_text(rule: String) -> String:
	return _SIGNS.get(rule, "")


static func action_of(rule: String) -> String:
	return _ACTIONS.get(rule, "")


static func button_of(rule: String) -> String:
	return _BUTTONS.get(rule, "")


# ready: {"has_bomb": bool, "has_potion": bool, "has_breakables": bool}, read as Harold enters.
static func can_apply(rule: String, ready: Dictionary) -> bool:
	match rule:
		NO_EXPLOSIVES:
			return ready.get("has_bomb", false)
		NO_FOOD:
			return ready.get("has_potion", false)
		EXHIBITS:
			return ready.get("has_breakables", false)
	return ALL.has(rule)
```

- [ ] **Step 4: Write `scripts/core/rule_picker.gd`**

```gdscript
class_name RulePicker
extends RefCounted

# Which rooms of a floor post a rule, and which. Draws from its own generator seeded by the floor's seed,
# never from FloorBuilder's stream, so existing floors and checkpoints are unchanged.

# The prototype posts rules on floor 1 only. Raise this to switch on the deeper rows of the table.
const ENABLED_DEPTH := 1
const BY_DEPTH := {1: 1, 2: 2}
const DEEP_SHARE := 0.4
const DEEP_MIN := 2


static func rule_room_count(depth: int, combat_rooms: int, enabled_depth := ENABLED_DEPTH) -> int:
	if depth > enabled_depth or combat_rooms <= 0:
		return 0
	var wanted: int = BY_DEPTH.get(depth, maxi(DEEP_MIN, roundi(combat_rooms * DEEP_SHARE)))
	return mini(wanted, combat_rooms)


# Combat rooms only: never loot, shop, treasure, item, healing, secret, vault, mini-boss or boss rooms.
static func rule_rooms(map: FloorMap, depth: int, seed_text: String) -> Array[int]:
	var combat: Array[int] = []
	for room in map.rooms:
		if room.room_type == RoomLayout.TYPE_COMBAT and room.id != map.start_id:
			combat.append(room.id)
	combat.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_text + ":rule_rooms")
	var picked: Array[int] = []
	for i in rule_room_count(depth, combat.size()):
		picked.append(combat.pop_at(rng.randi_range(0, combat.size() - 1)))
	picked.sort()
	return picked


static func pick_rule(seed_text: String, room_id: int, ready: Dictionary) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:rule:%d" % [seed_text, room_id])
	var choices: Array[String] = []
	var total := 0.0
	for rule in RoomRule.ALL:
		if RoomRule.can_apply(rule, ready):
			choices.append(rule)
			total += RoomRule.WEIGHTS[rule]
	var roll := rng.randf() * total
	for rule in choices:
		roll -= RoomRule.WEIGHTS[rule]
		if roll <= 0.0:
			return rule
	return choices[-1]
```

Check `map.start_id`'s room type first: if the start room is never `TYPE_COMBAT`, the `!= map.start_id` guard is harmless; keep it.

- [ ] **Step 5: Run the tests**

Run: `& $GODOT --headless --path . --script res://tests/run_tests.gd -- --only=room_rules`
Expected: `7 tests, 0 failed`. If floor 1 can generate a map with no combat room, the "exactly one" test fails; in that case print the seed's room types and tell the reviewer before changing the test.

- [ ] **Step 6: Commit**

```bash
git add scripts/core/room_rule.gd scripts/core/rule_picker.gd tests/test_room_rules.gd
git commit -m "Add the room rules and the floor's rule picker"
```

---

### Task 2: One room's rule state (RuleWatch)

**Files:**
- Create: `scripts/core/rule_watch.gd`
- Test: `tests/test_rule_watch.gd`

**Interfaces:**
- Consumes: `RoomRule` (Task 1).
- Produces: `RuleWatch.new(rule: String)`; `enum State { ACTIVE, BROKEN, KEPT, LIFTED }`; `var state`, `var announced: bool`; `report(action: String) -> bool` (true only on the first break); `tick_still(delta: float, moved: bool) -> bool` (true when loitering breaks it); `pulsing(held: Dictionary) -> bool`; `finish() -> int` (new state); `is_open() -> bool`; `to_dict() -> Dictionary`; `static from_dict(raw: Dictionary) -> RuleWatch`; consts `LOITER_TIME := 2.5`, `LOITER_WARN := 1.0`.

- [ ] **Step 1: Write the failing tests** in `tests/test_rule_watch.gd`:

```gdscript
extends TestCase


func test_only_the_forbidden_action_breaks_it_and_only_once() -> void:
	var watch := RuleWatch.new(RoomRule.NO_HORSEPLAY)
	assert_false(watch.report(RoomRule.ACTION_SWING))
	assert_eq(watch.state, RuleWatch.State.ACTIVE)
	assert_true(watch.report(RoomRule.ACTION_DODGE), "the first dodge breaks it")
	assert_eq(watch.state, RuleWatch.State.BROKEN)
	assert_false(watch.report(RoomRule.ACTION_DODGE), "a second break changes nothing")


func test_loitering_breaks_after_two_and_a_half_still_seconds() -> void:
	var watch := RuleWatch.new(RoomRule.NO_LOITERING)
	for i in 24:
		assert_false(watch.tick_still(0.1, false))
	assert_false(watch.tick_still(0.05, true), "a step resets the clock")
	for i in 24:
		assert_false(watch.tick_still(0.1, false))
	assert_true(watch.tick_still(0.2, false))
	assert_eq(watch.state, RuleWatch.State.BROKEN)


func test_standing_still_only_counts_for_the_loitering_rule() -> void:
	var watch := RuleWatch.new(RoomRule.NO_CANE)
	for i in 100:
		assert_false(watch.tick_still(0.1, false))


func test_the_icon_pulses_while_the_forbidden_button_is_held() -> void:
	var watch := RuleWatch.new(RoomRule.TEETH_IN)
	assert_false(watch.pulsing({"throw": false, "attack": true}))
	assert_true(watch.pulsing({"throw": true}))
	watch.report(RoomRule.ACTION_THROW)
	assert_false(watch.pulsing({"throw": true}), "a broken rule no longer warns")


func test_loitering_pulses_in_its_last_second() -> void:
	var watch := RuleWatch.new(RoomRule.NO_LOITERING)
	watch.tick_still(1.4, false)
	assert_false(watch.pulsing({}))
	watch.tick_still(0.2, false)
	assert_true(watch.pulsing({}))


func test_clearing_the_room_keeps_or_lifts_it() -> void:
	var kept := RuleWatch.new(RoomRule.NO_CANE)
	assert_eq(kept.finish(), RuleWatch.State.KEPT)
	var broken := RuleWatch.new(RoomRule.NO_CANE)
	broken.report(RoomRule.ACTION_SWING)
	assert_eq(broken.finish(), RuleWatch.State.LIFTED)
	assert_false(kept.is_open())
	assert_false(broken.report(RoomRule.ACTION_SWING), "a finished rule cannot break")


func test_it_round_trips_through_a_dictionary() -> void:
	var watch := RuleWatch.new(RoomRule.EXHIBITS)
	watch.announced = true
	watch.report(RoomRule.ACTION_BREAK)
	var copy := RuleWatch.from_dict(watch.to_dict())
	assert_eq(copy.rule, RoomRule.EXHIBITS)
	assert_eq(copy.state, RuleWatch.State.BROKEN)
	assert_true(copy.announced)
	assert_eq(RuleWatch.from_dict({}).rule, "", "an old checkpoint has no rule")
```

- [ ] **Step 2: Run to see it fail**

Run: `& $GODOT --headless --path . --script res://tests/run_tests.gd -- --only=rule_watch`
Expected: FAIL: `RuleWatch` not declared.

- [ ] **Step 3: Write `scripts/core/rule_watch.gd`**

```gdscript
class_name RuleWatch
extends RefCounted

# One room's rule through its fight: active until Harold breaks it, then kept or lifted on the clear.

enum State { ACTIVE, BROKEN, KEPT, LIFTED }

const LOITER_TIME := 2.5
# The icon pulses this long before loitering counts.
const LOITER_WARN := 1.0

var rule := ""
var state := State.ACTIVE
# Whether the big notice has shown; it shows on the first entry only.
var announced := false
var _still := 0.0


func _init(room_rule := "") -> void:
	rule = room_rule


func is_open() -> bool:
	return state == State.ACTIVE or state == State.BROKEN


# Returns true the first time this breaks the rule, when the Auditor is called.
func report(action: String) -> bool:
	if state != State.ACTIVE or action != RoomRule.action_of(rule):
		return false
	state = State.BROKEN
	return true


func tick_still(delta: float, moved: bool) -> bool:
	if rule != RoomRule.NO_LOITERING or state != State.ACTIVE:
		return false
	_still = 0.0 if moved else _still + delta
	return _still >= LOITER_TIME and report(RoomRule.ACTION_LOITER)


# held: input action name -> whether it is held this frame.
func pulsing(held: Dictionary) -> bool:
	if state != State.ACTIVE:
		return false
	if rule == RoomRule.NO_LOITERING:
		return _still >= LOITER_TIME - LOITER_WARN
	var button := RoomRule.button_of(rule)
	return not button.is_empty() and held.get(button, false)


func finish() -> int:
	if state == State.ACTIVE:
		state = State.KEPT
	elif state == State.BROKEN:
		state = State.LIFTED
	return state


func to_dict() -> Dictionary:
	return {"rule": rule, "state": state, "announced": announced}


static func from_dict(raw: Dictionary) -> RuleWatch:
	var watch := RuleWatch.new(str(raw.get("rule", "")))
	watch.state = clampi(int(raw.get("state", State.ACTIVE)), State.ACTIVE, State.LIFTED)
	watch.announced = bool(raw.get("announced", false))
	return watch
```

- [ ] **Step 4: Run the tests**

Run: `& $GODOT --headless --path . --script res://tests/run_tests.gd -- --only=rule_watch`
Expected: `7 tests, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add scripts/core/rule_watch.gd tests/test_rule_watch.gd
git commit -m "Track a room rule from first entry to the clear"
```

---

### Task 3: Player and prop signals the rules listen to

**Files:**
- Modify: `scripts/actors/player.gd` (signals at :4-12, `_swing` :579, `start_dodge` :689)
- Modify: `scripts/world/breakable_block.gd` (`hit_by` :92, `_break` :108), `scripts/world/thermos.gd` (:88)
- Modify: `scripts/world/room_view.gd` (signals at :4-22)
- Test: `tests/test_rule_keeper.gd` (new; this task adds its first tests)

**Interfaces:**
- Produces: `Player.swing_started` (no args), `Player.dodge_started` (no args); `BreakableBlock.blame_harold: bool` (static var), `BreakableBlock.broken_by_harold() -> bool`; `RoomView.prop_broken(by_harold: bool)` signal and `RoomView.note_prop_broken(by_harold: bool)`.

- [ ] **Step 1: Write the failing tests** in `tests/test_rule_keeper.gd`:

```gdscript
extends TestCase


func test_the_player_tells_when_a_swing_or_dodge_starts() -> void:
	assert_true(Player.new().has_signal("swing_started"))
	var source := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	var swing := source.substr(source.find("func _swing("), 700)
	assert_true(swing.contains("swing_started.emit()"), "every swing, combo or charged, starts in _swing")
	var dodge := source.substr(source.find("func start_dodge("), 900)
	assert_true(dodge.contains("dodge_started.emit()"))


func test_a_prop_knows_whether_harold_broke_it() -> void:
	var block := BreakableBlock.new()
	block.last_source = BreakableBlock.SOURCE_CANE
	assert_true(block.broken_by_harold())
	block.last_source = BreakableBlock.SOURCE_BOSS
	assert_false(block.broken_by_harold())
	block.last_source = BreakableBlock.SOURCE_BLAST
	assert_false(block.broken_by_harold(), "an enemy's blast is not his")
	BreakableBlock.blame_harold = true
	assert_true(block.broken_by_harold(), "his Thermos is")
	BreakableBlock.blame_harold = false
	block.free()


func test_the_thermos_blames_harold_only_for_its_own_blast() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/thermos.gd")
	var at := source.find("BreakableBlock.smash(")
	var window := source.substr(at - 120, 260)
	assert_true(window.contains("BreakableBlock.blame_harold = true"))
	assert_true(window.contains("BreakableBlock.blame_harold = false"))
```

Note: `Player.new()` leaks unless freed; add `.free()` as in tests/test_combat.gd:155-163 (keep the instance in a var and free it).

- [ ] **Step 2: Run to see it fail**

Run: `& $GODOT --headless --path . --script res://tests/run_tests.gd -- --only=rule_keeper`
Expected: FAIL.

- [ ] **Step 3: Add the player signals.** In `scripts/actors/player.gd` after the existing `signal potion_drunk(...)` line add:

```gdscript
# For the room rules: a swing or a dodge began, whether or not it lands.
signal swing_started
signal dodge_started
```

In `_swing(...)` add `swing_started.emit()` right after `_finish_swing()`. In `start_dodge(...)` add `dodge_started.emit()` right after `run.effects.dodge(direction)`.

- [ ] **Step 4: Attribute broken props.** In `scripts/world/breakable_block.gd`:

```gdscript
# Set by Harold's Thermos around its own blast, so an exhibit it breaks is his. Enemy blasts leave it false.
static var blame_harold := false

# The source of the hit that broke it.
var last_source := ""
```

In `hit_by(source)`, set `last_source = source` before `_break()`. Add:

```gdscript
func broken_by_harold() -> bool:
	return last_source == SOURCE_CANE or blame_harold
```

In `_break()`, after `broken.emit(global_position)` add:

```gdscript
	# The room's rule hears of it: Do Not Touch the Exhibits.
	var room := get_parent()
	while room != null and not room.has_method("note_prop_broken"):
		room = room.get_parent()
	if room != null:
		room.note_prop_broken(broken_by_harold())
```

In `scripts/world/thermos.gd` around the `BreakableBlock.smash(get_tree(), global_position, radius, BreakableBlock.SOURCE_BLAST)` line:

```gdscript
	BreakableBlock.blame_harold = true
	BreakableBlock.smash(get_tree(), global_position, radius, BreakableBlock.SOURCE_BLAST)
	BreakableBlock.blame_harold = false
```

In `scripts/world/room_view.gd` add the signal with the others and a method near `last_death_spot()`:

```gdscript
signal prop_broken(by_harold: bool)

func note_prop_broken(by_harold: bool) -> void:
	prop_broken.emit(by_harold)
```

Check `grep -rn "take_blast()" scripts`: `take_blast` calls `hit_by(SOURCE_BLAST)`, so `last_source` is set on that path too.

- [ ] **Step 5: Run the tests, then the full suite**

Run: `& $GODOT --headless --path . --script res://tests/run_tests.gd -- --only=rule_keeper` → `3 tests, 0 failed`.
Run: `powershell -File tools/test.ps1` → `0 failed`. Some source-window tests read player.gd (LESSONS L215, L247): if one fails, move the new line, not the test.

- [ ] **Step 6: Commit**

```bash
git add scripts/actors/player.gd scripts/world/breakable_block.gd scripts/world/thermos.gd scripts/world/room_view.gd tests/test_rule_keeper.gd
git commit -m "Signal swing and dodge starts and props Harold breaks"
```

---

### Task 4: Pictograms, the rule HUD and the rule sounds

**Files:**
- Create: `scripts/ui/rule_pictogram.gd`, `scripts/ui/rule_stamp.gd`, `scripts/ui/rule_icon.gd`
- Modify: `scripts/ui/hud.gd`, `scripts/world/sound_bank.gd`, `tools/sfx/sfx.py`; new `audio/sfx/rule_whistle.wav`, `audio/sfx/rule_stamp.wav`, `audio/sfx/reel_flicker.wav`
- Test: `tests/test_rule_hud.gd`

**Interfaces:**
- Consumes: `RoomRule` (Task 1).
- Produces: `RulePictogram.SIZE := 24`, `RulePictogram.image(rule: String) -> Image`; `RuleStamp` (Control) with `announce(rule: String)`, `stamp(kind: String)`, consts `KIND_VIOLATION := "violation"`, `KIND_GOOD := "good"`, `KIND_LIFTED := "lifted"`, `ANNOUNCE_TIME := 1.5`, `is_showing() -> bool`; `RuleIcon` (Control) with `show_rule(rule: String)`, `set_pulse(on: bool)`, `set_broken()`, `clear()`, const `AT := Vector2(588, 78)`; `Hud.show_rule(rule)`, `Hud.announce_rule(rule)`, `Hud.stamp_rule(kind)`, `Hud.pulse_rule(on)`, `Hud.break_rule()`, `Hud.clear_rule()`.

- [ ] **Step 1: Write the failing tests** in `tests/test_rule_hud.gd`:

```gdscript
extends TestCase


# A plus-shaped 5x5 core: a pixel with lit neighbours straight up, down, left and right, and the four
# diagonal neighbours dark, at arm length 2. Any such spot reads as a cross at 1x.
func _has_plus(image: Image) -> bool:
	for y in range(2, image.get_height() - 2):
		for x in range(2, image.get_width() - 2):
			var lit := func(px: int, py: int) -> bool: return image.get_pixel(px, py).a > 0.5
			if not lit.call(x, y):
				continue
			var arms := lit.call(x, y - 1) and lit.call(x, y - 2) and lit.call(x, y + 1) and lit.call(x, y + 2) \
				and lit.call(x - 1, y) and lit.call(x - 2, y) and lit.call(x + 1, y) and lit.call(x + 2, y)
			var corners := lit.call(x - 1, y - 1) or lit.call(x + 1, y - 1) or lit.call(x - 1, y + 1) or lit.call(x + 1, y + 1)
			if arms and not corners:
				return true
	return false


func test_every_rule_has_a_pictogram_without_a_cross() -> void:
	for rule in RoomRule.ALL:
		var image := RulePictogram.image(rule)
		assert_eq(image.get_width(), RulePictogram.SIZE, rule)
		assert_false(_has_plus(image), "%s draws a plus shape" % rule)


func test_the_cross_check_catches_a_plus() -> void:
	var image := Image.create(9, 9, false, Image.FORMAT_RGBA8)
	for i in 9:
		image.set_pixel(4, i, Color.WHITE)
		image.set_pixel(i, 4, Color.WHITE)
	assert_true(_has_plus(image))


func test_the_pulse_never_uses_the_warning_red_or_safe_mint() -> void:
	for color in [RuleIcon.PULSE_COLOR, RuleIcon.BROKEN_COLOR]:
		assert_false(color.is_equal_approx(Color("e4524f")))
		assert_false(color.is_equal_approx(Color("7fe0a0")))


func test_the_icon_sits_under_the_minimap_on_screen() -> void:
	var rect := Rect2(RuleIcon.AT, Vector2(RulePictogram.SIZE + 4, RulePictogram.SIZE + 4))
	assert_true(rect.position.y >= Hud.MAP_PANEL.end.y, "below the map panel")
	assert_true(rect.end.x <= 640.0 and rect.end.y <= 360.0)


func test_the_stamp_words_are_short_enough_to_read_in_a_second() -> void:
	for kind in [RuleStamp.KIND_VIOLATION, RuleStamp.KIND_GOOD, RuleStamp.KIND_LIFTED]:
		assert_true(RuleStamp.text_of(kind).length() <= 18, kind)


func test_the_rule_sounds_are_catalogued() -> void:
	for name in ["rule_whistle", "rule_stamp", "reel_flicker"]:
		assert_true(SoundBank.NAMES.has(name), name)
```

- [ ] **Step 2: Run to see it fail**

Run: `& $GODOT --headless --path . --script res://tests/run_tests.gd -- --only=rule_hud` → FAIL.

- [ ] **Step 3: Write `scripts/ui/rule_pictogram.gd`.** Each pictogram is a 24x24 image: a dark disc rim, a simple light figure, and for every rule except loitering a single diagonal red-brown slash from top-left to bottom-right. Loitering shows a standing figure beside a small clock, no slash.

```gdscript
class_name RulePictogram
extends RefCounted

# Each rule's sign, drawn in code so it stays sharp at 1x. The crossing-out is one diagonal slash in a
# circle, never a cross shape (tests/test_rule_hud.gd checks for a plus).

const SIZE := 24
const RIM := Color("2b2622")
const FACE := Color("ece9e0")
const INK := Color("3a332c")
const SLASH := Color("b8642f")


static func image(rule: String) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var c := Vector2(SIZE / 2.0 - 0.5, SIZE / 2.0 - 0.5)
	for y in SIZE:
		for x in SIZE:
			var d := Vector2(x, y).distance_to(c)
			if d <= 11.5:
				img.set_pixel(x, y, RIM if d > 10.0 else FACE)
	match rule:
		RoomRule.NO_CANE:
			_line(img, Vector2i(8, 18), Vector2i(15, 6), INK)
			_line(img, Vector2i(15, 6), Vector2i(17, 7), INK)
		RoomRule.NO_HORSEPLAY:
			_figure(img, Vector2i(12, 5), true)
		RoomRule.TEETH_IN:
			_rect(img, Rect2i(7, 9, 10, 3), INK)
			_rect(img, Rect2i(7, 13, 10, 3), INK)
			for x in [8, 10, 12, 14]:
				img.set_pixel(x, 11, FACE)
				img.set_pixel(x + 1, 13, FACE)
		RoomRule.NO_EXPLOSIVES:
			_rect(img, Rect2i(9, 8, 6, 10), INK)
			_rect(img, Rect2i(10, 6, 4, 2), INK)
		RoomRule.NO_FOOD:
			_rect(img, Rect2i(8, 9, 7, 8), INK)
			_rect(img, Rect2i(15, 11, 2, 1), INK)
			_rect(img, Rect2i(16, 11, 1, 4), INK)
			_rect(img, Rect2i(15, 14, 2, 1), INK)
		RoomRule.EXHIBITS:
			_rect(img, Rect2i(10, 10, 4, 8), INK)
			_rect(img, Rect2i(9, 12, 6, 4), INK)
			_rect(img, Rect2i(11, 8, 2, 2), INK)
			_rect(img, Rect2i(13, 5, 5, 3), SLASH.darkened(0.3))
		RoomRule.NO_LOITERING:
			_figure(img, Vector2i(9, 5), false)
			_ring(img, Vector2i(16, 11), 3, INK)
			_line(img, Vector2i(16, 11), Vector2i(17, 9), INK)
			return img
	_slash(img)
	return img


static func texture(rule: String) -> ImageTexture:
	return ImageTexture.create_from_image(image(rule))


# Top-left to bottom-right, two pixels thick: a diagonal never makes a plus.
static func _slash(img: Image) -> void:
	for i in range(5, 19):
		img.set_pixel(i, i, SLASH)
		img.set_pixel(i + 1, i, SLASH)


# A figure: head, body, and legs apart (jumping) or together (standing). Arms go out diagonally.
static func _figure(img: Image, head: Vector2i, jumping: bool) -> void:
	_rect(img, Rect2i(head.x - 1, head.y, 3, 3), INK)
	_rect(img, Rect2i(head.x, head.y + 3, 1, 6), INK)
	_line(img, head + Vector2i(0, 4), head + Vector2i(-3, 2 if jumping else 7), INK)
	_line(img, head + Vector2i(0, 4), head + Vector2i(3, 2 if jumping else 7), INK)
	_line(img, head + Vector2i(0, 9), head + Vector2i(-3, 13), INK)
	_line(img, head + Vector2i(0, 9), head + Vector2i(3, 13), INK)


static func _rect(img: Image, r: Rect2i, color: Color) -> void:
	img.fill_rect(r, color)


static func _line(img: Image, a: Vector2i, b: Vector2i, color: Color) -> void:
	var steps := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in steps + 1:
		var p := Vector2(a).lerp(Vector2(b), float(i) / maxf(steps, 1))
		img.set_pixel(roundi(p.x), roundi(p.y), color)


static func _ring(img: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(-radius - 1, radius + 2):
		for x in range(-radius - 1, radius + 2):
			var d := Vector2(x, y).length()
			if absf(d - radius) < 0.6:
				img.set_pixel(center.x + x, center.y + y, color)
```

Run the test; if any pictogram trips `_has_plus` (the figure's spine and arms can), shift the arms to start one pixel lower or make them diagonal until it passes. Then **look at each one**: save them with a throwaway probe to `D:\grandpa-verify\pictos\<rule>.png` scaled ×6 and read the images. Each must read at 1x as its rule. Redraw any that don't.

- [ ] **Step 4: Write `scripts/ui/rule_icon.gd`**

```gdscript
class_name RuleIcon
extends Control

# The room's rule in the HUD corner under the minimap, while its fight lasts. It pulses when Harold is
# about to break it and greys out once he has.

const AT := Vector2(588, 78)
const PULSE_COLOR := Color("ffd34f")
const BROKEN_COLOR := Color("8a8580")
const PULSE_SPEED := 9.0

var _texture: Texture2D
var _pulse := false
var _broken := false
var _time := 0.0


func _init() -> void:
	position = AT
	size = Vector2(RulePictogram.SIZE + 4, RulePictogram.SIZE + 4)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_rule(rule: String) -> void:
	_texture = RulePictogram.texture(rule)
	_broken = false
	_pulse = false
	visible = true
	queue_redraw()


func set_pulse(on: bool) -> void:
	if on != _pulse:
		_pulse = on
		queue_redraw()


func set_broken() -> void:
	_broken = true
	_pulse = false
	queue_redraw()


func clear() -> void:
	visible = false


func _process(delta: float) -> void:
	if _pulse:
		_time += delta
		queue_redraw()


func _draw() -> void:
	if _texture == null:
		return
	if _pulse:
		var glow := 0.5 + 0.5 * sin(_time * PULSE_SPEED)
		draw_rect(Rect2(Vector2.ZERO, size), Color(PULSE_COLOR, 0.35 + 0.5 * glow))
	var tint := Color(BROKEN_COLOR) if _broken else Color.WHITE
	draw_texture(_texture, Vector2(2, 2), tint)
```

- [ ] **Step 5: Write `scripts/ui/rule_stamp.gd`.** The announcement: the pictogram ×3 (72 px) on a paper card centred at (320, 150), with the sign text under it in `HudStyle.font()` size 16, dropping in over 0.15 s with the `rule_stamp` sound, held for `ANNOUNCE_TIME`, then shrinking towards `RuleIcon.AT` over 0.3 s. A stamp: a rotated (−8°) rubber-stamp rectangle with the word, centred at (320, 120), 1.0 s.

```gdscript
class_name RuleStamp
extends Control

const ANNOUNCE_TIME := 1.5
const SHRINK_TIME := 0.3
const STAMP_TIME := 1.0
const KIND_VIOLATION := "violation"
const KIND_GOOD := "good"
const KIND_LIFTED := "lifted"
const CENTER := Vector2(320, 150)
const CARD := Vector2(200, 112)
const PAPER := Color("efe6cf")
const KIND_COLORS := {KIND_VIOLATION: Color("c43d2f"), KIND_GOOD: Color("3f8f4a"), KIND_LIFTED: Color("6b6258")}

signal announce_done(rule: String)

var _texture: Texture2D
var _rule := ""
var _sign := ""
var _kind := ""
var _left := 0.0
var _total := 0.0


static func text_of(kind: String) -> String:
	match kind:
		KIND_VIOLATION:
			return "VIOLATION"
		KIND_GOOD:
			return "GOOD CONDUCT"
		KIND_LIFTED:
			return "REGULATION LIFTED"
	return ""


func _init() -> void:
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func announce(rule: String) -> void:
	_texture = RulePictogram.texture(rule)
	_rule = rule
	_sign = tr(RoomRule.sign_text(rule))
	_kind = ""
	_total = ANNOUNCE_TIME + SHRINK_TIME
	_left = _total
	Sfx.play("rule_stamp")
	queue_redraw()


func stamp(kind: String) -> void:
	_kind = kind
	_total = STAMP_TIME
	_left = STAMP_TIME
	Sfx.play("rule_stamp")
	queue_redraw()


func is_showing() -> bool:
	return _left > 0.0


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left -= delta
	if _left <= 0.0 and _kind.is_empty():
		announce_done.emit(_rule)
	queue_redraw()


func _draw() -> void:
	if _left <= 0.0:
		return
	var font := HudStyle.font()
	if not _kind.is_empty():
		var word := tr(text_of(_kind))
		var color: Color = KIND_COLORS[_kind]
		var width := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 24
		draw_set_transform(Vector2(320, 120), deg_to_rad(-8.0))
		draw_rect(Rect2(-width / 2, -18, width, 36), color, false, 3.0)
		draw_string(font, Vector2(-width / 2 + 12, 8), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, color)
		draw_set_transform(Vector2.ZERO)
		return
	var elapsed := _total - _left
	var drop := clampf(elapsed / 0.15, 0.0, 1.0)
	var shrink := clampf((elapsed - ANNOUNCE_TIME) / SHRINK_TIME, 0.0, 1.0)
	var scale := lerpf(1.25, 1.0, drop) * lerpf(1.0, 0.15, shrink)
	var center := CENTER.lerp(RuleIcon.AT + Vector2(14, 14), shrink)
	draw_set_transform(center, 0.0, Vector2(scale, scale))
	draw_rect(Rect2(-CARD / 2, CARD), PAPER)
	draw_rect(Rect2(-CARD / 2, CARD), Color("2b2622"), false, 2.0)
	draw_texture_rect(_texture, Rect2(Vector2(-36, -50), Vector2(72, 72)), false)
	var width := font.get_string_size(_sign, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, Vector2(-width / 2, 40), _sign, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("2b2622"))
	draw_set_transform(Vector2.ZERO)
```

Check `HudStyle.font()` exists and its return type (`grep -n "func font" scripts/ui/hud_style.gd`); use the HUD's own font call if it's named differently.

- [ ] **Step 6: Host them in the HUD.** In `scripts/ui/hud.gd`, add members `var _rule_icon: RuleIcon` and `var _rule_stamp: RuleStamp`; create and `add_child` both where the other HUD children are built (stamp last, so it draws on top). Add:

```gdscript
func show_rule(rule: String) -> void:
	_rule_icon.show_rule(rule)


func announce_rule(rule: String) -> void:
	_rule_icon.clear()
	_rule_stamp.announce(rule)


func stamp_rule(kind: String) -> void:
	_rule_stamp.stamp(kind)


func pulse_rule(on: bool) -> void:
	_rule_icon.set_pulse(on)


func break_rule() -> void:
	_rule_icon.set_broken()


func clear_rule() -> void:
	_rule_icon.clear()


func rule_announcing() -> bool:
	return _rule_stamp.is_showing()
```

Where the HUD builds the two nodes, connect once: `_rule_stamp.announce_done.connect(_rule_icon.show_rule)`, so the icon appears with the announced rule as the card shrinks away. Make sure `MapFade` fading the map panel also fades `_rule_icon` if it sits under a warning: call `_rule_icon.modulate.a = alpha` inside `Hud.set_map_alpha`.

- [ ] **Step 7: Make the three sounds.** In `tools/sfx/sfx.py`, add render entries using its helpers: `rule_stamp` from `stamp(rng, 0.18, 95.0)` (a thud), `rule_whistle` as two short high sine bursts (about 2.4 kHz, 0.12 s each, 0.05 s apart, a little vibrato), `reel_flicker` as a 0.6 s projector rattle (clicks at 24 per second over soft noise). Follow how other names are declared and rendered in that file (read its `main`/catalogue section first), then render into `audio/sfx/`. Add `"rule_whistle"`, `"rule_stamp"`, `"reel_flicker"` to `SoundBank.NAMES`. Listen-check: none of them may be louder than `door_close`; compare peak levels with `tools/sfx/check.py` if it reports levels.

- [ ] **Step 8: Run tests**

Run: `& $GODOT --headless --path . --script res://tests/run_tests.gd -- --only=rule_hud` → `6 tests, 0 failed`. Then `powershell -File tools/test.ps1` (test_sfx checks the files).

- [ ] **Step 9: Commit**

```bash
git add scripts/ui/rule_pictogram.gd scripts/ui/rule_icon.gd scripts/ui/rule_stamp.gd scripts/ui/hud.gd scripts/world/sound_bank.gd tools/sfx/sfx.py audio/sfx/rule_whistle.wav audio/sfx/rule_stamp.wav audio/sfx/reel_flicker.wav tests/test_rule_hud.gd
git commit -m "Draw the rule pictograms, icon and stamps"
```

(Include any `.import` files Godot made for the new wavs.)

---

### Task 5: The RuleKeeper in a floor

**Files:**
- Create: `scripts/world/rule_keeper.gd`
- Modify: `scripts/scenes/floor_scene.gd` (`_ready` :102, `_enter_room` :491, `_make_room_view` :707, `write_checkpoint` :229, `_resume_map` :312)
- Modify: `scripts/core/progress_data.gd`, `scripts/autoload/progress.gd`
- Test: `tests/test_rule_keeper.gd` (extend)

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces: `RuleKeeper` (Node) with `setup(player: Player, hud: Hud, run: RunState, record_rule: Callable)`, `plan_floor(map: FloorMap, depth: int, seed_text: String)`, `on_room_entered(view: RoomView, room: FloorRoom, first_visit: bool)`, `watch_of(room_id) -> RuleWatch` (null when none), signals `rule_broken(view: RoomView)` and `rule_kept(view: RoomView, at: Vector2)`, `to_dict() -> Dictionary`, `load_dict(raw: Dictionary)`; consts `HOLD_TIME := RuleStamp.ANNOUNCE_TIME`; `ProgressData.rules_kept: int`, `ProgressData.rules_broken: int`; `Progress.record_rule(kept: bool)`.

The keeper is a Node so it can poll input in `_process` (the smoke loop presses actions with `Input.action_press`; `_unhandled_input` would miss them, LESSONS L80). It must not name autoloads, so tests can load it; Progress is reached through the `record_rule` Callable.

- [ ] **Step 1: Add the failing tests** to `tests/test_rule_keeper.gd`:

```gdscript
func _keeper_with_rule(rule: String) -> Array:
	var keeper := RuleKeeper.new()
	var room := FloorRoom.new()
	room.id = 4
	keeper.set_watch(room.id, RuleWatch.new(rule))
	return [keeper, room]


func test_a_report_in_the_rule_room_breaks_it_once_and_calls_the_auditor() -> void:
	var parts := _keeper_with_rule(RoomRule.NO_HORSEPLAY)
	var keeper: RuleKeeper = parts[0]
	keeper.current_id = 4
	var calls := []
	keeper.rule_broken.connect(func(_view): calls.append(1))
	keeper.report(RoomRule.ACTION_DODGE)
	keeper.report(RoomRule.ACTION_DODGE)
	assert_eq(calls.size(), 1)
	assert_eq(keeper.watch_of(4).state, RuleWatch.State.BROKEN)
	keeper.free()


func test_reports_outside_a_rule_room_do_nothing() -> void:
	var parts := _keeper_with_rule(RoomRule.NO_HORSEPLAY)
	var keeper: RuleKeeper = parts[0]
	keeper.current_id = 7
	keeper.report(RoomRule.ACTION_DODGE)
	assert_eq(keeper.watch_of(4).state, RuleWatch.State.ACTIVE)
	assert_true(keeper.watch_of(7) == null)
	keeper.free()


func test_the_rule_state_survives_the_checkpoint() -> void:
	var parts := _keeper_with_rule(RoomRule.TEETH_IN)
	var keeper: RuleKeeper = parts[0]
	keeper.watch_of(4).announced = true
	var copy := RuleKeeper.new()
	copy.load_dict(keeper.to_dict())
	assert_eq(copy.watch_of(4).rule, RoomRule.TEETH_IN)
	assert_true(copy.watch_of(4).announced)
	copy.load_dict({})
	assert_true(copy.watch_of(4) == null, "an old checkpoint has no rules")
	keeper.free()
	copy.free()


func test_the_profile_counts_rules_and_loads_old_saves() -> void:
	var data := ProgressData.new()
	data.rules_kept = 3
	data.rules_broken = 2
	var copy := ProgressData.from_dict(data.to_dict())
	assert_eq(copy.rules_kept, 3)
	assert_eq(copy.rules_broken, 2)
	var old := ProgressData.from_dict({})
	assert_eq(old.rules_kept, 0)


func test_the_floor_scene_hands_entries_to_the_keeper() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	var enter := source.substr(source.find("func _enter_room("), 3000)
	assert_true(enter.contains("_rules.on_room_entered(_room_view, _map.room(target_id), first_visit)"))
	assert_true(source.contains("\"rules\": _rules.to_dict()"))
```

Check how `ProgressData.from_dict` is called in existing tests (`grep -n "from_dict" tests/*.gd | head`): if it's an instance method, write `var copy := ProgressData.new(); copy.from_dict(...)` instead.

- [ ] **Step 2: Run to see it fail.** `--only=rule_keeper` → FAIL.

- [ ] **Step 3: Profile fields.** In `scripts/core/progress_data.gd` add to the var block `var rules_kept := 0` and `var rules_broken := 0`; in `to_dict()` add `"rules_kept": rules_kept, "rules_broken": rules_broken`; in `from_dict` read `int(raw.get("rules_kept", 0))` and `int(raw.get("rules_broken", 0))` following the file's own pattern. In `scripts/autoload/progress.gd` add, beside `find_recipe`:

```gdscript
func record_rule(kept: bool) -> void:
	if kept:
		data.rules_kept += 1
	else:
		data.rules_broken += 1
	_store.save_progress(data)
```

- [ ] **Step 4: Write `scripts/world/rule_keeper.gd`**

```gdscript
class_name RuleKeeper
extends Node

# The floor's room rules at play: which room posts one, the notice on first entry, the watch on Harold's
# actions, the whistle for the Auditor, and the stamps on the clear. Names no autoload, so tests load it.

signal rule_broken(view: RoomView)
signal rule_kept(view: RoomView, at: Vector2)

const HOLD_TIME := RuleStamp.ANNOUNCE_TIME
# A step this long or longer counts as moving, for No Loitering.
const STILL_SPEED := 4.0

var current_id := -1
var _watches := {}  # room id -> RuleWatch
var _rule_rooms: Array[int] = []
var _seed := ""
var _player: Player
var _hud: Hud
var _run: RunState
var _view: RoomView
var _record_rule := Callable()


func setup(player: Player, hud: Hud, run: RunState, record_rule: Callable) -> void:
	_player = player
	_hud = hud
	_run = run
	_record_rule = record_rule
	player.swing_started.connect(_on_swing)
	player.dodge_started.connect(_on_dodge)
	player.teeth_thrown.connect(_on_throw)
	player.bomb_requested.connect(_on_bomb)
	player.potion_drunk.connect(_on_potion)


func plan_floor(map: FloorMap, depth: int, seed_text: String) -> void:
	_seed = seed_text
	_rule_rooms = RulePicker.rule_rooms(map, depth, seed_text)


func set_watch(room_id: int, watch: RuleWatch) -> void:
	_watches[room_id] = watch


func watch_of(room_id: int) -> RuleWatch:
	return _watches.get(room_id)


func on_room_entered(view: RoomView, room: FloorRoom, first_visit: bool) -> void:
	_leave_view()
	current_id = room.id
	_view = view
	if first_visit and _rule_rooms.has(room.id) and view.is_fighting() and not _watches.has(room.id):
		var ready := {"has_bomb": _run.bombs > 0, "has_potion": _run.potion != null, "has_breakables": view.has_breakables()}
		_watches[room.id] = RuleWatch.new(RulePicker.pick_rule(_seed, room.id, ready))
	var watch := watch_of(room.id)
	if watch == null or not watch.is_open() or not view.is_fighting():
		return
	view.finished.connect(_on_room_finished.bind(view, room.id), CONNECT_ONE_SHOT)
	view.prop_broken.connect(_on_prop_broken)
	if not watch.announced:
		watch.announced = true
		_hud.announce_rule(watch.rule)
		view.hold_enemies(HOLD_TIME)
	else:
		_hud.show_rule(watch.rule)
		if watch.state == RuleWatch.State.BROKEN:
			_hud.break_rule()


func report(action: String) -> void:
	var watch := watch_of(current_id)
	if watch == null or not watch.report(action):
		return
	Sfx.play("rule_whistle")
	if _hud != null:
		_hud.stamp_rule(RuleStamp.KIND_VIOLATION)
		_hud.break_rule()
	if _record_rule.is_valid():
		_record_rule.call(false)
	rule_broken.emit(_view)


func to_dict() -> Dictionary:
	var out := {}
	for id in _watches:
		out[str(id)] = _watches[id].to_dict()
	return {"rooms": _rule_rooms.duplicate(), "watches": out}


func load_dict(raw: Dictionary) -> void:
	_watches.clear()
	_rule_rooms.clear()
	for id in raw.get("rooms", []):
		_rule_rooms.append(int(id))
	var saved: Dictionary = raw.get("watches", {})
	for key in saved:
		_watches[int(key)] = RuleWatch.from_dict(saved[key])


func _process(delta: float) -> void:
	var watch := watch_of(current_id)
	if watch == null or _player == null or _view == null or not watch.is_open() or not _view.is_fighting():
		return
	if _hud.rule_announcing():
		return
	if watch.tick_still(delta, _player.velocity.length() >= STILL_SPEED):
		report(RoomRule.ACTION_LOITER)
	var held := {}
	for action in ["attack", "dodge", "throw", "bomb", "potion"]:
		held[action] = Input.is_action_pressed(action)
	_hud.pulse_rule(watch.pulsing(held))


func _on_room_finished(view: RoomView, room_id: int) -> void:
	var watch := watch_of(room_id)
	if watch == null:
		return
	var kept := watch.finish() == RuleWatch.State.KEPT
	_hud.stamp_rule(RuleStamp.KIND_GOOD if kept else RuleStamp.KIND_LIFTED)
	_hud.clear_rule()
	if kept:
		if _record_rule.is_valid():
			_record_rule.call(true)
		rule_kept.emit(view, view.last_death_spot())


func _leave_view() -> void:
	if _view != null and is_instance_valid(_view) and _view.prop_broken.is_connected(_on_prop_broken):
		_view.prop_broken.disconnect(_on_prop_broken)
	if _hud != null:
		_hud.clear_rule()


# A loitering rule is never broken by a button; the rest report here.
func _on_swing() -> void:
	report(RoomRule.ACTION_SWING)


func _on_dodge() -> void:
	report(RoomRule.ACTION_DODGE)


func _on_throw() -> void:
	report(RoomRule.ACTION_THROW)


func _on_bomb(_at: Vector2) -> void:
	report(RoomRule.ACTION_BOMB)


func _on_potion(_potion: PotionDef) -> void:
	report(RoomRule.ACTION_POTION)


func _on_prop_broken(by_harold: bool) -> void:
	if by_harold:
		report(RoomRule.ACTION_BREAK)
```

Two notes for the implementer:
- `view.finished` connected with `CONNECT_ONE_SHOT` and `bind` would be connected again on re-entry; guard with `if not view.finished.is_connected(...)` using the same bound callable stored in a dictionary per room id, or keep a set of room ids already hooked. Choose the set: `var _hooked := {}`.
- The keeper ignores reports while `_hud.rule_announcing()`? No: the spec holds the *enemies* still during the notice, not Harold. A dodge during the notice still breaks the rule. Leave `report` as written; only loitering waits for the notice to end.

- [ ] **Step 5: Add RoomView helpers** in `scripts/world/room_view.gd`:

```gdscript
# For Do Not Touch the Exhibits: whether anything Harold could break stands in the room.
func has_breakables() -> bool:
	for child in get_children():
		if child is BreakableBlock and not child.is_queued_for_deletion() and child.can_break_by(BreakableBlock.SOURCE_CANE):
			return true
	return false


# The room's enemies wait while its rule is announced.
func hold_enemies(seconds: float) -> void:
	for child in get_children():
		if child is Enemy and not child.is_queued_for_deletion():
			child.stun(seconds)
```

Check whether `Enemy.stun` shows stun stars; if it does, a held enemy must not look stunned. In that case add `Enemy.hold(seconds)` that raises `_wake_left` to `maxf(_wake_left, seconds)` (enemy.gd:530 area) and call that instead. Prefer `hold`.

- [ ] **Step 6: Wire FloorScene.** In `scripts/scenes/floor_scene.gd`:
  - Add `var _rules: RuleKeeper`. In `_ready`, after `player` and `_hud` exist: `_rules = RuleKeeper.new(); add_child(_rules); _rules.setup(player, _hud, _run, Progress.record_rule)`.
  - Where a seeded floor map is built (`_choose_path` around :453-458, and wherever a fresh MAP_FLOOR map is made for the next depth), after the map exists: `_rules.plan_floor(_map, _floor_def.depth, _floor_seed)`. For non-floor maps (start, landing) call `_rules.plan_floor` with an empty `FloorMap.new()` so no stale rule rooms remain.
  - In `_enter_room`, as the last line: `_rules.on_room_entered(_room_view, _map.room(target_id), first_visit)`.
  - In `write_checkpoint`'s dictionary add `"rules": _rules.to_dict()`. In `_resume_map` after `_floor_seed` is restored: `_rules.load_dict(data.get("rules", {}))`. A resumed run starts in a cleared room, so only `rules_kept`-style finished states and the floor's rule rooms matter; an uncleared rule room is rebuilt fresh and its saved watch (with `announced = true`) means no second notice, as the spec asks.
  - Exclude Crossroads views: `on_room_entered` takes a `RoomView`; a `CrossroadsView` must extend `RoomView` for this call to type-check. Check (`grep -n "class_name CrossroadsView" -A1 scripts`); if it doesn't extend RoomView, guard the call with `if _room_view is RoomView`.

- [ ] **Step 7: Run tests and the full suite**

`--only=rule_keeper` → all pass. `powershell -File tools/test.ps1` → `0 failed`. Then `powershell -File tools/smoke.ps1` → `SMOKE PASS`.

- [ ] **Step 8: Commit**

```bash
git add scripts/world/rule_keeper.gd scripts/world/room_view.gd scripts/scenes/floor_scene.gd scripts/core/progress_data.gd scripts/autoload/progress.gd scripts/actors/enemy.gd tests/test_rule_keeper.gd
git commit -m "Post a rule in one floor-1 room and watch it"
```

---

### Task 6: The Auditor

**Files:**
- Create: `data/enemies/auditor.tres`, `scripts/actors/behaviors/auditor_behavior.gd`, `scripts/world/ink_blot.gd`
- Modify: `scripts/actors/projectile.gd` (`LOOK_FINED`), `scripts/world/room_view.gd` (reserved arrival, drops, passing effects), `scripts/scenes/floor_scene.gd` (connect `rule_broken`)
- Test: `tests/test_auditor.gd`

**Interfaces:**
- Consumes: `RuleKeeper.rule_broken(view)` (Task 5).
- Produces: `RoomView.call_auditor(def: EnemyDef, from_door: Door)`; `RoomView.AUDIT_DELAY := 2.0`; `RoomView.AUDIT_ITEM_CHANCE := 0.25`; `RoomView.arrival_door() -> Door` (the door Harold came in by); `InkBlot` with `LINGER`, `SLOW`, `covers(p) -> bool`, `threat_at(p, strict) -> int`, `threat_imminent(p) -> bool`; `Projectile.LOOK_FINED := "fined"`.

- [ ] **Step 1: Write the failing tests** in `tests/test_auditor.gd`:

```gdscript
extends TestCase

const AUDITOR := "res://data/enemies/auditor.tres"


func _view() -> RoomView:
	var room := FloorRoom.new()
	room.layout = load("res://data/rooms/floor_1/combat_01.tres")
	room.room_type = RoomLayout.TYPE_COMBAT
	var view := RoomView.new()
	view.setup(room, null, load("res://data/floors/floor_1.tres"), RunState.new([] as Array[UpgradeDef], {}), null, RandomNumberGenerator.new(), null, null)
	return view


func test_the_auditor_is_a_tough_regular_not_a_boss() -> void:
	var def: EnemyDef = load(AUDITOR)
	assert_false(def.is_boss, "a boss's death wipes the room")
	assert_true(def.max_hp >= 90.0 and def.max_hp <= 160.0, "tougher than a regular, weaker than a mini-boss")
	assert_true(def.pension_drop >= 10, "about three times a regular's")
	assert_eq(def.max_per_room, 1)


func test_the_room_cannot_clear_while_he_is_on_his_way() -> void:
	var view := _view()
	view.debug_set_alive(1)
	view.call_auditor(load(AUDITOR), null)
	view.debug_set_alive(view.debug_alive() - 1)
	assert_true(view.debug_alive() >= 1, "he is counted from the whistle")
	view.call_auditor(load(AUDITOR), null)
	assert_eq(view.debug_alive(), 1, "at most one per room")
	view.free()


func test_his_stamp_and_ink_are_passing_effects() -> void:
	var blot := InkBlot.new()
	assert_true(RoomView.is_passing_effect(blot))
	blot.free()


func test_the_ink_blot_slows_only_where_it_lies() -> void:
	var blot := InkBlot.new()
	blot.position = Vector2(100, 100)
	assert_true(blot.covers(Vector2(104, 102)))
	assert_false(blot.covers(Vector2(140, 100)))
	assert_true(InkBlot.SLOW < 1.0 and InkBlot.SLOW >= SlowEffect.MIN_FACTOR)
	blot.free()
```

Fix the room and floor resource paths to real ones before running (`ls data/rooms`, `ls data/floors`; copy the bare-RoomView pattern from tests/test_cinema_floor.gd:510-520). Add `debug_alive()` and `debug_set_alive(n)` to RoomView only if no equivalent exists; mark them with a `# For tests.` comment.

- [ ] **Step 2: Run to see it fail.** `--only=auditor` → FAIL.

- [ ] **Step 3: The Auditor's def** `data/enemies/auditor.tres` (CRLF, same layout as data/enemies/film_reel.tres):

```
[gd_resource type="Resource" script_class="EnemyDef" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/content/enemy_def.gd" id="1"]
[ext_resource type="Script" path="res://scripts/actors/behaviors/auditor_behavior.gd" id="2"]

[resource]
script = ExtResource("1")
id = "auditor"
display_name = "The Auditor"
max_hp = 120.0
speed = 70.0
damage = 1
contact_damage = 1
pension_drop = 12
body_size = Vector2(20, 30)
color = Color(0.55, 0.56, 0.58, 1)
art_id = "auditor"
behavior_script = ExtResource("2")
max_per_room = 1
```

Compare `max_hp` with floor-1 regulars and the floor-1 mini-boss (`grep -h "max_hp" data/enemies/*.tres | sort | uniq -c`) and set it between them; the test's 90–160 range is a guard, not the target. A test asserts that every enemy is in some FloorDef's pool (LESSONS L77); if such a test exists and fails for the Auditor, add `auditor` to that test's list of enemies brought in by code, with a comment.

- [ ] **Step 4: The behavior** `scripts/actors/behaviors/auditor_behavior.gd`:

```gdscript
extends EnemyBehavior

# The Auditor walks Harold down. Close in, a clipboard swing; further off, a thrown FINED stamp that
# leaves a slowing ink blot where it lands.

const SWING_RANGE := 34.0
const SWING_WINDUP := 0.5
const SWING_COOLDOWN := 1.1
const THROW_RANGE := 160.0
const THROW_WINDUP := 0.6
const THROW_COOLDOWN := 2.4
const STAMP_SPEED := 120.0

var _swing := Telegraph.new()
var _throw := Telegraph.new()
var _swing_cooldown := 0.8
var _throw_cooldown := 1.5


func on_ready(enemy: Enemy) -> void:
	enemy.say("Rules are rules.", 1.4)


func tick(enemy: Enemy, delta: float) -> void:
	if _swing.is_active():
		if _swing.tick(delta):
			enemy.clear_warning()
			if enemy.distance_to_target() <= SWING_RANGE + 8.0:
				enemy.hit_target(enemy.def.damage)
			_swing_cooldown = SWING_COOLDOWN
		return
	if _throw.is_active():
		if _throw.tick(delta):
			enemy.clear_warning()
			var shot := enemy.shoot(enemy.direction_to_target(), STAMP_SPEED)
			if shot != null:
				shot.look = Projectile.LOOK_FINED
				shot.landed_at.connect(InkBlot.spawn_at.bind(enemy.get_parent()))
			_throw_cooldown = THROW_COOLDOWN
		return
	_swing_cooldown -= delta
	_throw_cooldown -= delta
	var distance := enemy.distance_to_target()
	enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
	if distance <= SWING_RANGE and _swing_cooldown <= 0.0:
		_swing.start(SWING_WINDUP)
		enemy.set_warning(_swing, SWING_RANGE)
	elif distance <= THROW_RANGE and _throw_cooldown <= 0.0 and enemy.target_in_view():
		_throw.start(THROW_WINDUP)
		enemy.set_warning(_throw, 18.0)
```

`Projectile` has no `landed_at` signal yet. Read projectile.gd: where it frees itself on hitting a wall, the target or at the end of its life, emit a new `signal landed_at(at: Vector2)` with its position, only for `LOOK_FINED` shots (or for all; nothing else listens). Make `InkBlot.spawn_at(at: Vector2, parent: Node)` static (note the bound argument comes after the emitted one).

- [ ] **Step 5: The stamp look.** In `scripts/actors/projectile.gd` add `const LOOK_FINED := "fined"` and a `_draw` branch: a 12x9 grey-brown block (the stamp's handle 4x4 on top), rotating slowly, with a 1 px dark outline; under it no shadow change. Later (Task 10) PixelLab art can replace it through `LOOK_ART`.

- [ ] **Step 6: The ink blot** `scripts/world/ink_blot.gd`, modelled on `scripts/world/film_trail.gd` (read it first and mirror its `threat_at` / `threat_imminent` signatures for the bot):

```gdscript
class_name InkBlot
extends Node2D

# Where a FINED stamp lands: a blot of stamp ink that slows Harold for a while.

const RADIUS := 14.0
const LINGER := 3.0
const SLOW := 0.5
const SLOW_TIME := 0.3
const SLOW_EVERY := 0.2
const INK := Color("3b2d5c")

var _left := LINGER
var _tick := 0.0


static func spawn_at(at: Vector2, parent: Node) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var blot := InkBlot.new()
	parent.add_child(blot)
	blot.global_position = at


func _ready() -> void:
	z_index = -8


func covers(p: Vector2) -> bool:
	return p.distance_to(position) <= RADIUS


func threat_at(p: Vector2, _strict: bool) -> int:
	return 1 if covers(p) else 0


func threat_imminent(_p: Vector2) -> bool:
	return false


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = SLOW_EVERY
	for player in get_tree().get_nodes_in_group("player"):
		if covers(player.feet() if player.has_method("feet") else player.global_position):
			player.slow(SLOW, SLOW_TIME)
	queue_redraw()


func _draw() -> void:
	var fade := clampf(_left / 0.6, 0.0, 1.0)
	draw_circle(Vector2.ZERO, RADIUS, Color(INK, 0.55 * fade))
	draw_circle(Vector2(4, -3), RADIUS * 0.45, Color(INK, 0.4 * fade))
```

Check how FilmTrail finds Harold (group name, `feet()`), and use exactly that. `covers` uses `position` so the test works out of the tree; in the room, the blot's parent is the RoomView, so `position` and the player's room-local feet match only if the RoomView sits at the origin; FilmTrail shows the right comparison, copy it.

Add `or child is InkBlot` to `RoomView.is_passing_effect`.

- [ ] **Step 7: The room's side.** In `scripts/world/room_view.gd`:

```gdscript
const AUDIT_DELAY := 2.0
const AUDIT_ITEM_CHANCE := 0.25
const AUDITOR_ID := "auditor"

var _audit_def: EnemyDef
var _audit_left := -1.0
var _audit_door: Door
var _audited := false


# The whistle has blown. He is counted from now, so the room cannot clear before he walks in.
func call_auditor(def: EnemyDef, from_door: Door) -> void:
	if _audited or _finished:
		return
	_audited = true
	_audit_def = def
	_audit_door = from_door
	_audit_left = AUDIT_DELAY
	_alive += 1


func _tick_audit(delta: float) -> void:
	if _audit_left < 0.0:
		return
	_audit_left -= delta
	if _audit_left > 0.0:
		return
	_audit_left = -1.0
	var at := summon_spot(_audit_door.position if _audit_door != null else last_death_spot())
	var auditor := _spawn_enemy(_audit_def, at)
	_alive -= 1
	auditor.wait_for_room_start()
	Sfx.play("door_open")
```

Call `_tick_audit(delta)` from a `_physics_process(delta)` on RoomView (add one if there is none; it only runs while the room is in the tree, so leaving the room pauses his walk-in, which is what we want). `door_open` is an existing sound. Add `arrival_door()`: the Door whose `target_id()` equals the room Harold came from; FloorScene knows `_arrived_from`, so pass it: in FloorScene connect `_rules.rule_broken.connect(_on_rule_broken)` and write

```gdscript
func _on_rule_broken(view: RoomView) -> void:
	if view != _room_view:
		return
	view.call_auditor(load("res://data/enemies/auditor.tres"), view.door_to(_arrived_from))
```

In `_on_enemy_defeated`, after the coin drop:

```gdscript
	if enemy.def.id == AUDITOR_ID and _rng.randf() < AUDIT_ITEM_CHANCE:
		var items := RoomRules.pick_items(Content.items(), _run, 1, _rng, ItemRarity.ITEM_ROOM)
		if not items.is_empty():
			_add_free_item(spot + Vector2(RoomBackdrop.TILE, 0), items[0])
```

Check `RoomRules.pick_items`'s exact signature at its definition before writing this, and whether `Content` is an autoload (RoomView already calls `Content.items()` at :1372-1383, so it's fine here).

The Auditor's coin uses `def.pension_drop × floor pension_mult`, which already gives "about 3× a regular" on every floor; measure in Task 11.

- [ ] **Step 8: Run tests and the full suite.** `--only=auditor` → pass. `tools/test.ps1` → `0 failed`.

- [ ] **Step 9: Commit**

```bash
git add data/enemies/auditor.tres scripts/actors/behaviors/auditor_behavior.gd scripts/world/ink_blot.gd scripts/actors/projectile.gd scripts/world/room_view.gd scripts/scenes/floor_scene.gd tests/test_auditor.gd
git commit -m "Send the Auditor when a room rule is broken"
```

---

### Task 7: Reels, the flashback button and the sepia flicker

**Files:**
- Create: `scripts/core/eras.gd`, `scripts/ui/reel_slot.gd`, `scripts/world/sepia_flicker.gd`, `scripts/world/sepia_flicker.gdshader`
- Modify: `scripts/core/run_state.gd`, `scripts/core/run_checkpoint.gd` (`run_to_dict` :84, `apply_run` :190), `scripts/core/progress_data.gd`, `scripts/core/input_setup.gd`, `scripts/core/pad_input.gd`, `scripts/core/key_bindings.gd`, `scripts/core/dev_start.gd`, `scripts/world/door.gd`, `scripts/world/room_view.gd`, `scripts/world/rule_keeper.gd`, `scripts/scenes/floor_scene.gd`, `scripts/ui/hud.gd`
- Test: `tests/test_reels.gd`

**Interfaces:**
- Consumes: `RuleKeeper.rule_kept(view, at)` (Task 5).
- Produces: `Eras.FOOTBALL := "rec_football_1960"`, `Eras.BUS := "no12_bus_1975"`, `Eras.STARTING: Array[String]`, `Eras.title(id) -> String`, `Eras.speed_mult(id) -> float`, `Eras.art_id(id) -> String`, `Eras.pick(unlocked: Array, seed_text: String, room_id: int) -> String`; `RunState.held_reel: String`, `RunState.give_reel(id) -> bool`, `RunState.take_reel() -> String`, `RunState.era: String` (the era playing now, "" for old Harold); `ProgressData.eras_unlocked: Array[String]`; `RoomView.drop_reel(at: Vector2, era: String, on_take: Callable)`; `Door.is_within(radius: float) -> bool`; `RuleKeeper` reel methods `readied_door() -> int`, `try_ready_reel(view, progress, map) -> bool`; `SepiaFlicker.play(parent: Node)`; `DevStart.REEL_KEY := KEY_F7`.

- [ ] **Step 1: Write the failing tests** in `tests/test_reels.gd`:

```gdscript
extends TestCase


func test_the_two_prototype_eras_start_unlocked() -> void:
	assert_eq(Eras.STARTING, [Eras.FOOTBALL, Eras.BUS] as Array[String])
	assert_eq(ProgressData.new().eras_unlocked, Eras.STARTING)
	assert_eq(Eras.title(Eras.FOOTBALL), "Football on the Rec, 1960")
	assert_eq(Eras.title(Eras.BUS), "The No. 12 Bus, 1975")
	assert_near(Eras.speed_mult(Eras.FOOTBALL), 1.45)
	assert_near(Eras.speed_mult(Eras.BUS), 1.15)
	assert_near(Eras.speed_mult(""), 1.0)


func test_a_reel_picks_an_unlocked_era_by_the_seed() -> void:
	for i in 50:
		var era := Eras.pick(Eras.STARTING, str(i), 3)
		assert_true(Eras.STARTING.has(era))
		assert_eq(Eras.pick(Eras.STARTING, str(i), 3), era)
	assert_eq(Eras.pick([Eras.BUS], "9", 1), Eras.BUS)


func test_he_holds_one_reel_and_a_second_is_wasted() -> void:
	var run := RunState.new([] as Array[UpgradeDef], {})
	assert_true(run.give_reel(Eras.FOOTBALL))
	assert_false(run.give_reel(Eras.BUS), "already holding a memory")
	assert_eq(run.held_reel, Eras.FOOTBALL)
	assert_eq(run.take_reel(), Eras.FOOTBALL)
	assert_eq(run.held_reel, "")


func test_the_held_reel_survives_the_checkpoint() -> void:
	var run := RunState.new([] as Array[UpgradeDef], {})
	run.give_reel(Eras.BUS)
	var copy := RunState.new([] as Array[UpgradeDef], {})
	RunCheckpoint.apply_run(copy, RunCheckpoint.run_to_dict(run))
	assert_eq(copy.held_reel, Eras.BUS)
	var old := RunState.new([] as Array[UpgradeDef], {})
	RunCheckpoint.apply_run(old, {})
	assert_eq(old.held_reel, "")


func test_unknown_saved_eras_are_dropped() -> void:
	var data := ProgressData.new()
	data.from_dict({"eras_unlocked": [Eras.BUS, "moon_landing_1969"]})
	assert_eq(data.eras_unlocked, [Eras.BUS] as Array[String])


func test_the_flashback_action_is_f_and_pad_y() -> void:
	InputSetup.ensure()
	assert_true(InputMap.has_action("flashback"))
	var keys := InputMap.action_get_events("flashback").filter(func(e): return e is InputEventKey)
	assert_eq(keys[0].physical_keycode if keys[0].physical_keycode != 0 else keys[0].keycode, KEY_F)
	assert_eq(PadInput.DEFAULT_BUTTONS["flashback"], JOY_BUTTON_Y)
	assert_true(KeyBindings.ACTIONS.any(func(e): return e["action"] == "flashback"))


func test_a_door_knows_when_harold_is_near_it() -> void:
	var door := Door.new()
	var feet := Node2D.new()
	door.position = Vector2(100, 100)
	feet.position = Vector2(130, 100)
	door.debug_set_player(feet)
	assert_true(door.is_within(48.0))
	assert_false(door.is_within(20.0))
	door.free()
	feet.free()
```

Match the existing test idioms: check how `RunCheckpoint.apply_run` / `run_to_dict` are called in `tests/test_run_checkpoint.gd`, how `ProgressData.from_dict` is called, and how `InputSetup` tests read keys (`tests/test_key_bindings.gd`). Adjust the calls, not the intent.

- [ ] **Step 2: Run to see it fail.** `--only=reels` → FAIL.

- [ ] **Step 3: `scripts/core/eras.gd`**

```gdscript
class_name Eras
extends RefCounted

# The moments of Harold's life a film reel lets him relive for one room.

const FOOTBALL := "rec_football_1960"
const BUS := "no12_bus_1975"
const STARTING: Array[String] = [FOOTBALL, BUS]

const _DATA := {
	FOOTBALL: {"title": "Football on the Rec, 1960", "age": 18, "speed": 1.45, "art": "harold_1960"},
	BUS: {"title": "The No. 12 Bus, 1975", "age": 40, "speed": 1.15, "art": "harold_1975"},
}
const RETURN_LINES := ["Those were the days.", "My knees remember that.", "Where did the years go?"]


static func is_known(id: String) -> bool:
	return _DATA.has(id)


static func title(id: String) -> String:
	return _DATA.get(id, {}).get("title", "")


static func speed_mult(id: String) -> float:
	return _DATA.get(id, {}).get("speed", 1.0)


static func art_id(id: String) -> String:
	return _DATA.get(id, {}).get("art", "")


static func pick(unlocked: Array, seed_text: String, room_id: int) -> String:
	var known := unlocked.filter(func(id): return is_known(id))
	if known.is_empty():
		return FOOTBALL
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:reel:%d" % [seed_text, room_id])
	return known[rng.randi_range(0, known.size() - 1)]
```

- [ ] **Step 4: Run and profile fields.**
  - `RunState`: `var held_reel := ""` and `var era := ""`; methods:

```gdscript
# One memory at a time: a second reel is wasted, on purpose, to reward using them.
func give_reel(era_id: String) -> bool:
	if not held_reel.is_empty():
		return false
	held_reel = era_id
	changed.emit()
	return true


func take_reel() -> String:
	var reel := held_reel
	held_reel = ""
	changed.emit()
	return reel
```

  - `RunState.move_speed()`: multiply by `Eras.speed_mult(era)`.
  - `RunCheckpoint.run_to_dict`: `"held_reel": run.held_reel`; `apply_run`: `run.held_reel = str(raw.get("held_reel", ""))` and drop it if `not Eras.is_known(...)`. `era` is not saved: a checkpoint resumes in a cleared room, where no flashback runs.
  - `ProgressData`: `var eras_unlocked: Array[String] = Eras.STARTING.duplicate()`; `to_dict` writes it; `from_dict` reads `raw.get("eras_unlocked", Eras.STARTING)` and keeps only `Eras.is_known` ids, falling back to `Eras.STARTING` when nothing is left (LESSONS L109).

- [ ] **Step 5: The flashback action.** `input_setup.gd` `ensure()`: `_action("flashback", _key(KEY_F))` beside the others (match how `_key` is named there). `pad_input.gd` `DEFAULT_BUTTONS`: `"flashback": JOY_BUTTON_Y`. `key_bindings.gd` `ACTIONS`: `{"action": "flashback", "label": "Flashback"}` after potion. Run `--only=key_bindings` and `--only=pad_input`. Screenshot the Options Input tab at 640x360 later (Task 11): it must not run off the screen (LESSONS L26).

- [ ] **Step 6: Door proximity.** In `scripts/world/door.gd`:

```gdscript
func is_within(radius: float) -> bool:
	return _player != null and is_instance_valid(_player) and global_position.distance_to(_player.global_position) <= radius


# For tests.
func debug_set_player(player: Node2D) -> void:
	_player = player
```

(`_player` is the feet node the door already compares against; see `_process` at :119.)

- [ ] **Step 7: The reel pickup.** In `scripts/world/room_view.gd`:

```gdscript
const ART_REEL := "memory_reel"

# The film reel a kept rule leaves where the last enemy fell. Picking it up always succeeds; the keeper
# decides whether a held reel wastes it.
func drop_reel(at: Vector2, era: String, on_take: Callable) -> Pickup:
	var pickup := _add_pickup(clear_spot(at), tr("Reel: %s") % tr(Eras.title(era)), Color("d9a441"), on_take, false, "item_fanfare")
	pickup.art_id = ART_REEL
	return pickup
```

Check `_add_pickup`'s exact signature (:909) and `clear_spot` (used in `_on_enemy_defeated`). Pickups aren't KEEP-tagged, so a reel left lying in a room is lost on a checkpoint resume; accept that for the prototype (Harold walks over it right after the clear).

- [ ] **Step 8: The keeper's reel logic.** Add to `scripts/world/rule_keeper.gd`:

```gdscript
const USE_RADIUS := 48.0
const READY_NOTICE := "Memory ready: go through the door"
const HELD_NOTICE := "Already holding a memory"
const WRONG_PLACE := "Use a memory at a door to a room you haven't fought in"
const FIGHT_ROOMS := [RoomLayout.TYPE_COMBAT, RoomLayout.TYPE_MINI_BOSS, RoomLayout.TYPE_FLOOR_BOSS]

signal era_started(era: String)
signal era_ended(era: String)

var _readied_door := -1
var _era_room := -1
var _unlocked: Array = Eras.STARTING
var _hinted := false


func set_unlocked(unlocked: Array) -> void:
	_unlocked = unlocked


func readied_door() -> int:
	return _readied_door


# The flashback button: in reach of a door into a room whose fight hasn't started, ready the reel for it.
func try_ready_reel(view: RoomView, progress: FloorProgress, map: FloorMap) -> bool:
	if _run.held_reel.is_empty() or not _run.era.is_empty() or view == null or view.is_fighting():
		return false
	for door in view.doors():
		var target := door.target_id()
		if not door.is_within(USE_RADIUS) or progress.is_visited(target):
			continue
		if map.room(target) == null or not FIGHT_ROOMS.has(map.room(target).room_type):
			continue
		_readied_door = target
		_hud.show_notice(tr(READY_NOTICE))
		_player.set_sepia_glow(true)
		return true
	if not _hinted:
		_hinted = true
		_hud.show_notice(tr(WRONG_PLACE))
	return false


func _reel_taken(era: String) -> void:
	if _run.give_reel(era):
		_hud.show_notice(tr("Reel: %s") % tr(Eras.title(era)))
	else:
		_hud.show_notice(tr(HELD_NOTICE))
```

Hook them in:
  - In `setup`, `rule_kept.connect(_on_rule_kept)`; then

```gdscript
func _on_rule_kept(view: RoomView, at: Vector2) -> void:
	var era := Eras.pick(_unlocked, _seed, current_id)
	view.drop_reel(at, era, _reel_taken.bind(era))
```

  - At the start of `on_room_entered`, before anything else:

```gdscript
	if _readied_door != -1:
		var going := _readied_door
		_readied_door = -1
		_player.set_sepia_glow(false)
		if going == room.id and first_visit:
			_start_era(_run.take_reel(), room.id, view)
```

and

```gdscript
func _start_era(era: String, room_id: int, view: RoomView) -> void:
	_run.era = era
	_era_room = room_id
	SepiaFlicker.play(get_parent())
	Sfx.play("reel_flicker")
	_player.set_era(era)
	view.finished.connect(_end_era.bind(view), CONNECT_ONE_SHOT)
	era_started.emit(era)


func _end_era(_view: RoomView) -> void:
	var era := _run.era
	_run.era = ""
	_era_room = -1
	SepiaFlicker.play(get_parent())
	Sfx.play("reel_flicker")
	_player.set_era("")
	_player.say_line(Eras.RETURN_LINES[randi() % Eras.RETURN_LINES.size()])
	era_ended.emit(era)
```

  - `_process`: before the rule logic, `if Input.is_action_just_pressed("flashback"): try_ready_reel(_view, _progress, _map)`. Give the keeper `_progress` and `_map` through `plan_floor(map, depth, seed_text, progress)` (extend Task 5's signature and its one call in FloorScene). `RoomView.doors()` returns `_doors` (add it if missing).
  - `Player.set_sepia_glow(on)`, `Player.set_era(era)` and `Player.say_line(text)` come from Task 8. In this task, add them as stubs on Player that only store state (`set_sepia_glow` calls `_visual.set_tint(Color("d9b98a") if on else Color.WHITE)`; `set_era` stores `_era := era`; `say_line` shows the line the same way Harold's other speech does, or `Hud.show_notice` through the keeper if Harold has no speech bubble. Check `grep -n "func say\|_tip_hat" scripts/actors/player.gd scripts/scenes/floor_scene.gd`).
  - FloorScene: after `_rules.setup(...)`, `_rules.set_unlocked(Progress.data.eras_unlocked)`.
  - Exhausted reel on death: nothing to do; a new run makes a new RunState.

- [ ] **Step 9: The sepia flicker.** `scripts/world/sepia_flicker.gdshader`:

```glsl
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float flicker = 0.0;

void fragment() {
	vec3 c = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 sepia = vec3(lum * 1.07 + 0.03, lum * 0.88 + 0.02, lum * 0.64 + 0.01);
	sepia *= 1.0 + flicker;
	COLOR = vec4(mix(c, sepia, strength), 1.0);
}
```

`scripts/world/sepia_flicker.gd` (copy the CanvasLayer + ColorRect structure from `scripts/world/adjust_layer.gd`, with a layer **below** the HUD's so the HUD stays in colour; read the HUD's `layer` value first):

```gdscript
class_name SepiaFlicker
extends CanvasLayer

# The cinema screen's film look over the room for a moment, as a memory starts or ends.

const SHADER := preload("res://scripts/world/sepia_flicker.gdshader")
const TIME := 0.6
const LAYER := 50

var _rect: ColorRect
var _left := TIME


static func play(parent: Node) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	parent.add_child(SepiaFlicker.new())


func _ready() -> void:
	layer = LAYER
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var material := ShaderMaterial.new()
	material.shader = SHADER
	_rect.material = material
	add_child(_rect)


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	var t := 1.0 - _left / TIME
	var material := _rect.material as ShaderMaterial
	material.set_shader_parameter("strength", sin(t * PI))
	material.set_shader_parameter("flicker", 0.12 * sin(t * 70.0))
```

- [ ] **Step 10: The reel slot in the HUD.** `scripts/ui/reel_slot.gd`: a Control 22x16 placed left of the potion slot, inside `RIGHT_PANEL`. If there is no room (the potion slot is 110 wide in a 118 panel), place it at `Vector2(380, 5)` and widen `RIGHT_PANEL` leftward by 24 px (`Rect2(380, 1, 142, 34)`), checking `ITEM_ROW_END` (272) and the timer at (474, 22) still clear. It draws a small reel (a 12 px brass disc with three dark holes, drawn in code) when `run.held_reel != ""`, plus `KeyBindings.prompt_label("flashback")` beside it in `HudStyle` small text, and nothing when empty. Hud refreshes it in `_refresh()` like the potion slot. Add `Hud.reel_label()` returning the drawn text for the test below.

Add to `tests/test_reels.gd`:

```gdscript
func test_the_reel_slot_fits_the_top_row() -> void:
	var rect := Rect2(ReelSlot.AT, ReelSlot.SIZE)
	assert_true(rect.end.y <= Hud.BAND_BOTTOM)
	assert_true(rect.position.x >= Hud.ITEM_ROW_END)
	assert_false(rect.intersects(Rect2(Hud.POTION_SLOT_AT, PotionSlot.SIZE)))
```

- [ ] **Step 11: DEV F7.** In `scripts/core/dev_start.gd`: `const REEL_KEY := KEY_F7`. In `RuleKeeper._process`: `if DevStart.is_available() and Input.is_key_pressed(DevStart.REEL_KEY) and not _f7_was_down: _reel_taken(Eras.pick(_unlocked, str(Time.get_ticks_msec()), 0))`, tracking `_f7_was_down` for the press edge. (A key, not an action, so it stays out of KeyBindings and the Options list.)

- [ ] **Step 12: Run tests, full suite, smoke.** `--only=reels`, then `tools/test.ps1`, then `tools/smoke.ps1`.

- [ ] **Step 13: Commit**

```bash
git add scripts/core/eras.gd scripts/ui/reel_slot.gd scripts/world/sepia_flicker.gd scripts/world/sepia_flicker.gdshader scripts/core/run_state.gd scripts/core/run_checkpoint.gd scripts/core/progress_data.gd scripts/core/input_setup.gd scripts/core/pad_input.gd scripts/core/key_bindings.gd scripts/core/dev_start.gd scripts/world/door.gd scripts/world/room_view.gd scripts/world/rule_keeper.gd scripts/scenes/floor_scene.gd scripts/ui/hud.gd scripts/actors/player.gd tests/test_reels.gd
git commit -m "Earn film reels and spend them at a door"
```

---

### Task 8: The two eras' moves

**Files:**
- Create: `scripts/actors/era_moves.gd`, `scripts/actors/era_ball.gd`, `scripts/world/ticket_line.gd`
- Modify: `scripts/actors/player.gd` (`_handle_attacks` :477, `start_dodge` :689, `_handle_movement` :641, the Task 7 stubs), `scripts/world/room_view.gd` (`is_passing_effect`)
- Test: `tests/test_eras.gd`

**Interfaces:**
- Consumes: `Eras` (Task 7), `RunState.era`.
- Produces: `EraMoves.for_era(id) -> EraMoves` (null for ""), with `combo_damage: Array[float]`, `reach`, `angle`, `push`, `lock_time`, `dodge_hit_damage`, `dodge_push`, `dodge_stun`, `make_throw(aim: Vector2) -> Node2D`, `throw_ready() -> bool`; `Player.set_era(id)`, `Player.era() -> String`, `Player.ERA_HIT := "era"`; `EraBall` (bounces ≤3 times then rests; Harold picks it up by walking over it); `TicketLine` (a line that hurts enemies crossing it).

Rules still apply in an era: the kick goes through `_swing`, so `swing_started` fires; the spin and barge go through `start_dodge`, so `dodge_started` fires; the football and ticket roll must emit `teeth_thrown` so Keep Your Teeth In covers them (spec §4.2).

- [ ] **Step 1: Write the failing tests** in `tests/test_eras.gd`:

```gdscript
extends TestCase

# Old Harold's three-swing combo, for the damage comparison.
const OLD_COMBO := 38.0


func test_old_harold_has_no_era_moves() -> void:
	assert_true(EraMoves.for_era("") == null)


func test_each_era_plays_differently() -> void:
	var kick := EraMoves.for_era(Eras.FOOTBALL)
	var punch := EraMoves.for_era(Eras.BUS)
	assert_eq(kick.combo_damage.size(), 3, "a three-kick combo")
	assert_eq(punch.combo_damage.size(), 1, "one heavy punch")
	assert_true(kick.reach < Player.ATTACK_REACH, "short kicks")
	assert_true(punch.reach > Player.ATTACK_REACH, "a long punch")
	assert_true(punch.push > Player.ATTACK_PUSH * 1.5, "strong knockback")
	assert_true(kick.lock_time < CaneCombo.LOCK_TIME and punch.lock_time > CaneCombo.LOCK_TIME)


# The same damage per second within 15%, before the bot checks it in play.
func test_era_damage_per_second_is_close_to_old_harolds() -> void:
	var old := OLD_COMBO / (CaneCombo.LOCK_TIME * 3.0)
	for id in Eras.STARTING:
		var moves := EraMoves.for_era(id)
		var total := 0.0
		for d in moves.combo_damage:
			total += d
		var dps := total / (moves.lock_time * moves.combo_damage.size())
		assert_true(absf(dps / old - 1.0) <= 0.15, "%s at %.1f vs %.1f" % [id, dps, old])


func test_the_football_bounces_three_times_then_rests() -> void:
	var ball := EraBall.new()
	for i in 3:
		assert_true(ball.bounce(Vector2.UP))
	assert_false(ball.bounce(Vector2.UP), "a fourth wall stops it")
	assert_true(ball.is_resting())
	ball.free()


func test_era_leftovers_are_passing_effects() -> void:
	var ball := EraBall.new()
	var line := TicketLine.new()
	assert_true(RoomView.is_passing_effect(ball))
	assert_true(RoomView.is_passing_effect(line))
	ball.free()
	line.free()


func test_an_era_throw_still_counts_as_a_throw_for_the_rules() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	var era_throw := source.substr(source.find("func _era_throw("), 800)
	assert_true(era_throw.contains("teeth_thrown.emit()"))
```

`OLD_COMBO` is `CaneCombo.DAMAGE` summed (10 + 10 + 18); read it from `CaneCombo.DAMAGE` in the test instead of the literal if the array is a const there.

- [ ] **Step 2: Run to see it fail.** `--only=eras` → FAIL.

- [ ] **Step 3: `scripts/actors/era_moves.gd`.** Damage per lock time must land within ±15% of old Harold's (38 over 3 × 0.2 s = 63.3/s):

```gdscript
class_name EraMoves
extends RefCounted

# A younger Harold's moves, on the same buttons. Old Harold has none: for_era("") is null.

const TICKET_ROLL_COOLDOWN := 2.5

var era := ""
var combo_damage: Array[float] = []
var reach := 0.0
var angle := 0.0
var push := 0.0
var lock_time := 0.2
var dodge_hit_damage := 0.0
var dodge_push := 0.0
var dodge_stun := 0.0
var _ball: EraBall
var _roll_left := 0.0


static func for_era(id: String) -> EraMoves:
	var moves := EraMoves.new()
	moves.era = id
	match id:
		Eras.FOOTBALL:
			# Quick, light kicks: 6 + 6 + 10 over three 0.12 s locks = 61/s.
			moves.combo_damage = [6.0, 6.0, 10.0]
			moves.reach = 34.0
			moves.angle = 70.0
			moves.push = 50.0
			moves.lock_time = 0.12
			# The spin turn hits whoever he passes through.
			moves.dodge_hit_damage = 6.0
			moves.dodge_push = 40.0
		Eras.BUS:
			# One heavy ticket-punch: 28 over a 0.42 s lock = 67/s.
			moves.combo_damage = [28.0]
			moves.reach = 52.0
			moves.angle = 50.0
			moves.push = 150.0
			moves.lock_time = 0.42
			# The shoulder barge knocks them down.
			moves.dodge_hit_damage = 8.0
			moves.dodge_push = 160.0
			moves.dodge_stun = 0.6
		_:
			return null
	return moves


func throw_ready() -> bool:
	if era == Eras.FOOTBALL:
		return _ball == null or not is_instance_valid(_ball)
	return _roll_left <= 0.0


func tick(delta: float) -> void:
	_roll_left = maxf(_roll_left - delta, 0.0)


func make_throw(aim: Vector2) -> Node2D:
	if era == Eras.FOOTBALL:
		_ball = EraBall.new()
		_ball.direction = aim
		return _ball
	_roll_left = TICKET_ROLL_COOLDOWN
	var line := TicketLine.new()
	line.direction = aim
	return line
```

- [ ] **Step 4: `scripts/actors/era_ball.gd`**

```gdscript
class_name EraBall
extends Node2D

# The football: it flies, bounces off up to three walls, hurts what it passes through, then rests until
# Harold walks over it.

const SPEED := 260.0
const DAMAGE := 12.0
const BOUNCES := 3
const RADIUS := 6.0
const PICKUP_RADIUS := 16.0
const SLOWDOWN := 0.9

var direction := Vector2.RIGHT
var _bounces_left := BOUNCES
var _speed := SPEED
var _hit := {}


func is_resting() -> bool:
	return _speed <= 0.0


# A wall's normal; returns whether it bounced.
func bounce(normal: Vector2) -> bool:
	if _bounces_left <= 0:
		_speed = 0.0
		return false
	_bounces_left -= 1
	direction = direction.bounce(normal)
	_speed *= SLOWDOWN
	_hit.clear()
	return true


func _physics_process(delta: float) -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if is_resting():
		if player != null and player.global_position.distance_to(global_position) <= PICKUP_RADIUS:
			queue_free()
		return
	var step := direction * _speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step + direction * RADIUS, ThrownDentures.BLOCKED_BY)
	var wall := get_world_2d().direct_space_state.intersect_ray(query)
	if not wall.is_empty():
		bounce(wall["normal"])
		return
	global_position += step
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		var id := enemy.get_instance_id()
		if _hit.has(id) or enemy.is_queued_for_deletion() or not enemy.body_rect().grow(RADIUS).has_point(global_position):
			continue
		_hit[id] = true
		if player != null:
			player.era_hit(enemy, DAMAGE, direction * 60.0)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color("f2efe6"))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 16, Color("2b2622"), 1.0)
	draw_circle(Vector2(-1, -1), 2.0, Color("2b2622"))
```

Check the player group name (`grep -n "add_to_group" scripts/actors/player.gd`) and `ThrownDentures.BLOCKED_BY` exists as a collision mask const.

- [ ] **Step 5: `scripts/world/ticket_line.gd`**

```gdscript
class_name TicketLine
extends Node2D

# A roll of bus tickets unspooled into a line along the floor. Enemies crossing it take a nip.

const LENGTH := 96.0
const UNROLL_TIME := 0.3
const LINGER := 3.0
const DAMAGE := 5.0
const TICK := 0.5
const WIDTH := 8.0

var direction := Vector2.RIGHT
var _time := 0.0
var _last_hit := {}


func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= UNROLL_TIME + LINGER:
		queue_free()
		return
	var length := LENGTH * clampf(_time / UNROLL_TIME, 0.0, 1.0)
	var player: Player = get_tree().get_first_node_in_group("player")
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion():
			continue
		var local := enemy.global_position - global_position
		var along := local.dot(direction)
		var across := absf(local.dot(direction.orthogonal()))
		if along < 0.0 or along > length or across > WIDTH:
			continue
		var id := enemy.get_instance_id()
		if _time - _last_hit.get(id, -TICK) < TICK:
			continue
		_last_hit[id] = _time
		if player != null:
			player.era_hit(enemy, DAMAGE, Vector2.ZERO)
	queue_redraw()


func _draw() -> void:
	var length := LENGTH * clampf(_time / UNROLL_TIME, 0.0, 1.0)
	var fade := clampf((UNROLL_TIME + LINGER - _time) / 0.5, 0.0, 1.0)
	var side := direction.orthogonal() * 3.0
	draw_line(side, direction * length + side, Color(Color("e8dcb0"), fade), 5.0)
	var dash := 0.0
	while dash < length:
		draw_line(direction * dash, direction * (dash + 2.0), Color(Color("a33b2b"), fade), 5.0)
		dash += 10.0
```

Add `or child is EraBall or child is TicketLine` to `RoomView.is_passing_effect`.

- [ ] **Step 6: Player era hooks** in `scripts/actors/player.gd`:

```gdscript
const ERA_HIT := "era"

var _era := ""
var _era_moves: EraMoves


func era() -> String:
	return _era


# A younger Harold for one room, or old Harold again with "". Health and stat items carry over; his cane
# and dentures items don't touch an era's own moves.
func set_era(id: String) -> void:
	_era = id
	_era_moves = EraMoves.for_era(id)
	_combo.reset()
	var art := Eras.art_id(id) if not id.is_empty() else GrandpaLook.outfit_art(run.look)
	if not id.is_empty() and not SpriteVisual.has_anim(art, "idle"):
		# No art yet: old Harold's sprite, warmed up, so playtests can still tell.
		art = GrandpaLook.outfit_art(run.look)
		_visual.set_tint(Color("ffd9a0") if id == Eras.FOOTBALL else Color("c9d8ff"))
	else:
		_visual.set_tint(Color.WHITE)
	_visual.set_art(art)
	if _look != null:
		_look.visible = id.is_empty()
	queue_redraw()


# An era move landing on an enemy, with the same damage path as a swing so stat items apply.
func era_hit(enemy: Enemy, damage: float, push: Vector2) -> void:
	var amount := damage * run.damage_mult()
	amount = PlayerStats.boss_damage(amount, enemy.def.is_boss, run.boss_damage_mult())
	run.effects.land(enemy, amount, ERA_HIT, push, global_position - enemy.global_position)
```

Check: `_combo.reset()` exists on CaneCombo (else set its index back the way `CaneCombo` does after its window); `_look` is the member holding the GrandpaLook (`grep -n "GrandpaLook" scripts/actors/player.gd`); `run.effects.land` accepts a source string it doesn't know (read `RunEffects.land`; items that only react to `SWING`/`COMBO_3`/`CHARGE` then ignore era hits, which is what the spec wants). In `_draw`, skip drawing the cane skin while `not _era.is_empty()`.

Attack, in `_handle_attacks`, before the old cane code:

```gdscript
	if _era_moves != null:
		_era_moves.tick(get_physics_process_delta_time())
		if Input.is_action_just_pressed("throw") and _era_moves.throw_ready():
			_era_throw()
		if Input.is_action_just_pressed("attack"):
			_combo.lock_time = _era_moves.lock_time / run.swing_speed()
			var hit := _combo.try_attack()
			if hit > 0:
				var step := _combo.debug_step() % _era_moves.combo_damage.size()
				_swing(_era_moves.combo_damage[step], _era_moves.reach, _era_moves.angle, _era_moves.push, false, false)
		return
```

`CaneCombo.try_attack()` returns old Harold's damage; we only use it as the "a swing starts now" gate and pick the era's damage by step. Read cane_combo.gd: if it exposes the current step, use that instead of `debug_step()`; if not, keep an `_era_step` counter on Player that resets when the combo window lapses (`CaneCombo.WINDOW`). `_swing` multiplies by `run.damage_mult()` and runs `run.effects.swing(...)`: the cane items would then reshape the kick. To keep cane items off era moves, add a parameter `from_era := false` to `_swing` and skip `run.effects.swing(_active_swing)` and the Lucky Tee when it's true; pass `true` here.

The era's swing also plays `"attack"`; with era art that strip is the kick or punch. Use `Sfx.play("cane_swing")` for now (one sound fewer to make; Task 10 may add `kick`).

Throw:

```gdscript
func _era_throw() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var thrown := _era_moves.make_throw(_aim)
	parent.add_child(thrown)
	thrown.global_position = _feet.global_position + _aim * 10.0
	Sfx.play("teeth_throw")
	teeth_thrown.emit()
```

Use the throw sound name the dentures already use (`grep -n "Sfx.play" scripts/actors/player.gd scripts/actors/thrown_dentures.gd`); test_sfx needs it literal and catalogued.

Dodge, in `start_dodge` after `dodge_started.emit()`:

```gdscript
	if _era_moves != null:
		_era_dodge_hits.clear()
```

and in `_handle_movement` inside `if _dodge.is_active():` after the velocity is set:

```gdscript
		if _era_moves != null:
			_era_dodge_strike()
```

with

```gdscript
var _era_dodge_hits := {}


# The spin turn and the shoulder barge hit each enemy he passes through once per dodge.
func _era_dodge_strike() -> void:
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		var id := enemy.get_instance_id()
		if _era_dodge_hits.has(id) or enemy.is_queued_for_deletion() or not enemy.body_rect().grow(6.0).has_point(_feet.global_position):
			continue
		_era_dodge_hits[id] = true
		era_hit(enemy, _era_moves.dodge_hit_damage, _dodge_direction * _era_moves.dodge_push)
		if _era_moves.dodge_stun > 0.0 and not enemy.def.is_boss:
			enemy.stun(_era_moves.dodge_stun)
```

The barge should feel like a charge: for `Eras.BUS`, multiply the dodge's velocity by 1.2 in that same block (`velocity *= 1.2`). Speed: `RunState.move_speed()` already applies `Eras.speed_mult(run.era)` (Task 7).

Replace the Task 7 stub of `set_era` with this one; keep `set_sepia_glow` and `say_line`.

- [ ] **Step 7: Run tests, full suite, smoke.** `--only=eras`, `tools/test.ps1`, `tools/smoke.ps1`.

- [ ] **Step 8: Commit**

```bash
git add scripts/actors/era_moves.gd scripts/actors/era_ball.gd scripts/world/ticket_line.gd scripts/actors/player.gd scripts/world/room_view.gd tests/test_eras.gd
git commit -m "Play young Harold in the football and bus eras"
```

---

### Task 9: The bot learns reels and eras

**Files:**
- Modify: `tools/probes/bot_probe.gd` (Bot class at :391, `loot` :465, `_physics_process` :484, case parsing), `tools/probes/run_bot.ps1` only if a new case word needs it
- Test: none new in the suite (the bot is a probe); verification is a bot run.

**Interfaces:**
- Consumes: `RuleKeeper.try_ready_reel`, `RunState.held_reel`, `Player.era()`, `RuleKeeper.readied_door()`.
- Produces: bot case flag `eras` (`<save> <skill> <runs> <path> <depth> eras`): the bot gets a reel before every combat room (DEV give) and uses it, and the SUMMARY line gains `era_dps=<era>:<value>` and `old_dps=<value>`.

- [ ] **Step 1: Teach the bot.**
  - The bot already collects pickups via `collect()` in `loot`, so reels are taken.
  - After a room clears and before walking to the next door: if `run.held_reel != ""` and the next door leads to an unvisited fight room, walk to within 40 px of that door, `Input.action_press("flashback")` for one physics frame, release, then continue to the door. Reach the keeper through the scene (`scene.debug_rules()` — add that seam to FloorScene next to `debug_room_view()`, :361-413).
  - Rules: the bot never throws, bombs or drinks, so those rules are kept automatically. For `NO_CANE` and `NO_HORSEPLAY`, read `scene.debug_rules().watch_of(current).rule` and, on case flag `obey`, skip attacking or dodging in that room; by default it plays as it always has (it may break rules, which tests the Auditor).
  - In `eras` mode, add damage counters: total damage dealt per room and room fight time (sum physics delta, LESSONS L154), split into rooms played old and rooms played in each era. Print them on the SUMMARY line.

- [ ] **Step 2: Run one small batch** (only when no windowed Godot is running and nothing else heavy runs):

`powershell -File tools/probes/run_bot.ps1 -Commit HEAD -Cases "max good 6 0 1 eras" -Tag eras1`

Expected: the output file has a SUMMARY line with both era DPS values; no SCRIPT ERROR.

- [ ] **Step 3: Tune.** If an era's DPS is more than 15% off old Harold's over 4+ batches (LESSONS L156), change only `EraMoves` numbers, keep `tests/test_eras.gd` passing, and record the measured numbers in the commit message.

- [ ] **Step 4: Commit**

```bash
git add tools/probes/bot_probe.gd scripts/scenes/floor_scene.gd scripts/actors/era_moves.gd
git commit -m "Let the bot spend reels and measure era damage"
```

---

### Task 10: Art

**Files:**
- Create: `art/sprites/auditor/{idle,walk,windup,attack}.png`, `art/sprites/harold_1960/{idle,walk,attack}.png`, `art/sprites/harold_1975/{idle,walk,attack}.png`, `art/props/memory_reel.png`, the FINED stamp projectile art (through `Projectile.LOOK_ART`)
- Modify: `scripts/actors/projectile.gd` (`LOOK_ART` entry)

This task is done by the orchestrating session (it holds the PixelLab tools), not a subagent. PixelLab: at most 5 jobs at once; check `get_balance` first.

- [ ] **Step 1:** Read how existing depth-style characters were made (LESSONS entries on art, `tools/art/`, and an existing strip such as `art/sprites/grandpa/walk.png`) for frame width, the feet row, palette and outline.
- [ ] **Step 2: The Auditor.** A tall grey office official: grey suit, thin tie, clipboard under one arm, a large rubber stamp in the other hand, a stern face. Same scale as floor-1 regulars but a head taller; 4 directions as the other enemies use. No religious imagery: no collar that reads as clerical, no black-and-white priest look, no cross on the clipboard.
- [ ] **Step 3: Harold at 18 (1960).** Lean young man, short side-parted hair, a striped football shirt, shorts, long socks, boots. Idle, walk, and attack as a kick.
- [ ] **Step 4: Harold at 40 (1975).** A bus conductor: peaked conductor's cap, uniform jacket, ticket machine on a strap, sideburns. Idle, walk, and attack as a punch with the ticket machine.
- [ ] **Step 5:** `memory_reel.png` (a small brass film reel, 16x16) and the FINED stamp (12x12, rubber stamp, its face with "FINED" readable only as a red smear at 1x).
- [ ] **Step 6:** Place every strip, then screenshot each in a room at 1x and 3x. Check them against the floor-1 depth look (art direction lock: LESSONS and memory "art direction first"). Redo anything that looks pasted on.
- [ ] **Step 7:** Re-run `tools/test.ps1` (the art tests check strip sizes and frame counts).
- [ ] **Step 8: Commit** `git commit -m "Draw the Auditor, young Harold and the memory reel"`

---

### Task 11: Verification and handover

- [ ] **Step 1:** `powershell -File tools/test.ps1` → `0 failed`; `powershell -File tools/smoke.ps1` → `SMOKE PASS`.
- [ ] **Step 2: Screenshots** (renamed export, never the real save; one Godot at a time). Take each at 640x360 with every HUD counter full and the potion slot filled (LESSONS L48):
  - the announcement mid-drop, and the icon after it shrinks;
  - the icon pulsing (hold the forbidden button);
  - VIOLATION and the Auditor walking in at the door;
  - GOOD CONDUCT and the reel on the floor; the reel in the HUD slot;
  - "Memory ready" at a door; the sepia flicker; each era's attack, dodge and throw; the return line;
  - the Options Input tab with the new Flashback row.
  Look at every one. Fix overlaps before going on.
- [ ] **Step 3: Bot batch.** `run_bot.ps1 -Cases "average good 10 0 1; average good 10 0 1 eras" -Tag rules1` (one at a time). Compare floor-1 clear rate and pension with the last `combined` batch; the Auditor must not make floor 1 meaningfully harder for an average player who breaks rules by accident.
- [ ] **Step 4: Save guard.** Confirm the profile MD5 matches the one recorded at the start (or that the user played).
- [ ] **Step 5: LESSONS.md.** Append one dated line per new gotcha met during the build.
- [ ] **Step 6: Push** and build a playtest zip from this branch (`D:\Grandpa-playtest-6.zip`, as before, with `tools/stamp_build.ps1`).
- [ ] **Step 7:** Report to the user: what works, the screenshots, the bot numbers, and what to ask the testers (spec §6).

---

## Self-review notes

- **Spec coverage:** rules and readiness (T1), frequency table with only floor 1 enabled (T1), announcement, icon, pulse, stamps, re-entry without a notice (T4, T5), settings and `tr()` (T4–T7), the Auditor with his arrival, one per room, attacks, warnings through `Telegraph`/`set_warning`, rewards and the clear held (T6), reels with one held and the second wasted (T7), use at a door with the sepia flicker and one whole room with shared health (T7, T8), era moves with stat items applying and cane items not (T8), rules applying in eras (T3, T8), eras unlocked in the profile with the two prototype eras (T7), save fields and old saves (T5, T7), DEV key (T7), bot and the ±15% check (T8 test, T9), pictogram cross check (T4), screenshots (T11). The Memories page and unlocking eras by ending stay out, as the spec's §6 says.
- **Spec gaps resolved** in "Decisions this plan adds to the spec" above.
