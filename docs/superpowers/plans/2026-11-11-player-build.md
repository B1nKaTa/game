# Player Build Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the build ready for 5-10 real players, as `docs/superpowers/specs/2026-11-11-player-build-design.md` decides: control tips during a new save's first run, attack warnings on by default, a skippable opening, room rules on every floor (early on a first run), an Auditor that keeps up with depth, four eras instead of two, Harold's hurt, death and dodge animations, and a zip.

**Architecture:** Each change sits behind a small static function or a plain object the test runner can reach (`RulePicker`, `RoomRule`/`RuleWatch`, `AuditorBehavior.cooldown_mult`, `Eras`, `EraMoves`, `EraShot`, `Player.feedback_anim`, `FirstRunTips`, `ProgressData`), and the scene wiring is thin. Every animation hook checks that its strip exists, so the code lands before the art and works with today's look. The tips are a pure table (`FirstRunTips`) driven by one node (`TipCoach`) that reads facts from the floor scene and marks tips done in the profile.

**Tech Stack:** Godot 4.7.2, GDScript, the repo's own test runner (`tests/run_tests.gd`, `tests/support/test_case.gd`), `tools/test.ps1`, `tools/smoke.ps1`, plain Python 3 for the strip tool (`py -I`).

## Global Constraints

- Worktree: `C:\GameDev\game\.worktrees\player-build`, branch `player-build` (from `new-items` at ed66010). Every path below is relative to it.
- **Godot never runs on the worktree.** Any `--path` run of a project named "Grandpa" (import, one test file, the suite, the full loop, a probe) writes Godot's logs into `%APPDATA%\Godot\app_userdata\Grandpa\` (LESSONS 2026-11-05, 2026-11-07). Every launch in this plan runs in a `git archive` copy renamed `GrandpaPlayerCopy`, made by `tools/probes/export_copy.ps1`, which also imports it. Refresh the copy before every run, from the worktree in PowerShell:

  ```powershell
  $GODOT = "D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
  $COPY = "D:\grandpa-verify\player"
  git add <this task's new and changed files>
  $snap = git stash create
  if (-not $snap) { $snap = "HEAD" }
  powershell -File tools/probes/export_copy.ps1 -Dest player -Name GrandpaPlayerCopy -Commit $snap
  ```

  (`git stash create` makes a commit of the index and working tree without touching either, so a failing test can be run before its task commits. Files must be `git add`-ed to be in it.) Expect the line `EXPORTED <hash> to D:\grandpa-verify\player as GrandpaPlayerCopy`.
- Quick test run, after refreshing the copy: `& $GODOT --headless --path $COPY --script res://tests/run_tests.gd -- --only=<file-name fragment>`. `--only` matches test **file** names. Check the "N tests, M failed" line, and that N is more than 0. In the tasks, "Run: `-- --only=x`" is short for this command.
- Full suite, after refreshing the copy: `powershell -File $COPY\tools\test.ps1` (read the "N tests, M failed" line; the runner also fails on any `SCRIPT ERROR` or `Parse Error`). Full loop: `powershell -File $COPY\tools\smoke.ps1` (must print `SMOKE PASS`). Both scripts run Godot on the folder they sit in, so the copy's own scripts keep to the copy.
- **Never run Godot while the user plays:** before every launch run `Get-Process *godot* -ErrorAction SilentlyContinue`; a windowed Godot (no `--headless` in its command line) means stop and wait. One heavy Godot job at a time.
- **Never write to `%APPDATA%\Godot\app_userdata\Grandpa\`.** Tests use `OS.get_temp_dir()`.
- Never name another video game anywhere (code, comments, data, assets, commits).
- No religious symbols in any drawn shape: no crosses, plus shapes, halos, inverted crosses, rings of thorns, pentagrams. Check every new `_draw` for two crossing straight strokes.
- No new dependencies or add-ons.
- Player-facing strings in new UI code go through `tr()`; item names and descriptions live in `.tres` data as today.
- Edit files with the Edit and Write tools or `py -I` scripts with `C:/` paths. Never Git Bash `sed -i` or PowerShell `Set-Content` (they rewrite CRLF files or add a BOM; LESSONS 2026-11-04, 2026-11-05, 2026-11-09). Before each commit run `git ls-files --eol <new files>` and expect `i/lf`.
- New sounds: none. Every `ctx.play_sound("...")` name must pass `SoundBank.can_play` (`tests/test_item_sounds.gd` reads every script in `scripts/items/`), so reuse names the old items already use: `coin`, `small_blast`, `pill_heal`, `thermos_pickup`, `slip_pickup`, `shield_block`, `form_filed`, `alarm`, `chime`, `charge_ready`, `slot_win`, `ticket_ding`, `card_flip`, `lethal_save`, `ui_ching`. A kept item keeps the key sound `KEY_SOUNDS` in that test names for it. `Sfx.play` names in non-item code come from `SoundBank.NAMES`.
- Any node an item leaves in a room joins `ItemFx.GROUP` (so `RoomView.is_passing_effect` clears it) or is added to `RoomView.is_passing_effect`.
- Item effects keep per-run state in plain member variables (RunEffects duplicates each effect per run). Once-a-run, per-floor and counter state goes through `save_state`/`load_state` (`state_of`, `load_members`).
- Every new rule that changes damage, pays Pension, blocks, soaks or heals does nothing while `ctx.counting_exact` (damage, Pension, fuses) or `ctx.counting_pills` (blocks, soaks, heals) is set, as the old items do.
- **Deleting old item files waits for the user's OK.** Until then old files stay, retired by id.
- Commits: imperative mood, one logical change, and the message ends with the line `Co-Authored-By: Claude <noreply@anthropic.com>`. In PowerShell: `git commit -m "Subject" -m "Co-Authored-By: Claude <noreply@anthropic.com>"`. Do not push unless the user asks.
- Read `LESSONS.md` before starting; append a dated one-liner for every new gotcha.

**Also binding in this plan (from LESSONS):**
- `var x := <Variant>` does not parse here (a Dictionary read, `Array.pop_front()`, a ternary of mixed or duck-typed values): give the type (`var x: String = d.get("k", "")`). A ternary of typed-array literals loses its element type at run time: build the typed array, then change it.
- The test root is not in a started tree: `_ready()` must be called by hand, groups are empty, `is_inside_tree()` is false, `is_visible_in_tree()` is false. Test through static functions, `Player.new()` + `setup(run)`, `RunState`, `Hud.new()` + `setup` + `_ready()`.
- Signals connect their own callables (`died.emit`), never a lambda that captures `self`.
- The full loop presses actions with `Input.action_press` (no InputEvent): anything the loop must drive polls `Input.is_action_just_pressed` in `_process`.

## Shared names

| Name | Where | What | Task |
|---|---|---|---|
| `GameSettings.DEFAULTS[GAME]["attack_warnings"]` | game_settings.gd | now `true` | 1 |
| `next_index(index: int, skip: bool) -> int` (static) | scripts/scenes/opening.gd | the card after a press; `LINES.size()` on skip | 1 |
| `RulePicker.ENABLED_DEPTH` (99), `RulePicker.EARLY_ROOMS` (3) | rule_picker.gd | | 2 |
| `RulePicker.rule_rooms(map, depth, seed_text, extra := 0, early := false) -> Array[int]` | rule_picker.gd | | 2 |
| `RulePicker.early_candidates(map: FloorMap) -> Array[int]` | rule_picker.gd | first 3 main-path combat rooms | 2 |
| `RuleKeeper.first_run: bool` | rule_keeper.gd | set by FloorScene before `plan_floor` | 2 |
| `Player.is_held_still() -> bool` | player.gd | taped or self-stunned | 2 |
| `AuditorBehavior` (class_name), `AuditorBehavior.cooldown_mult(depth: int) -> float`, `tempo: float` | auditor_behavior.gd | | 3 |
| `Eras.DANCE` (`"dance_hall_1962"`), `Eras.ALLOTMENT` (`"allotment_1988"`), `Eras.BIRTH_YEAR` (1942), `Eras.STARTING` (4 ids), `Eras.year(id) -> int`, `Eras.age(id) -> int`, `Eras.tint(id) -> Color` | eras.gd | | 4 |
| `EraMoves.throw_cooldown`, `EraMoves.dodge_length`, `EraMoves.DISC_COOLDOWN` (1.5), `EraMoves.MARROW_COOLDOWN` (2.0) | era_moves.gd | | 4 |
| `EraShot` (`for_disc()`, `for_marrow()`, `direction`, `damage`, `speed`, `max_range`, `pierce`, `splash_radius`, `look`, `LOOK_DISC`, `LOOK_MARROW`, static `splash_targets(at: Vector2, bodies: Array, radius: float) -> Array`) | scripts/actors/era_shot.gd | | 4 |
| `Player.HURT_ANIM_TIME` (0.25), `Player.DEATH_ANIM_TIME` (0.9), `Player.feedback_anim(art_id: String, anim: String) -> String` (static), `Player.death_anim_time() -> float`, `Player.uses_dodge_ghosts() -> bool` | player.gd | | 5 |
| `tools/art/harold_anims.py` | tools/art | frames to strips | 6 |
| `FirstRunTips` (ids `MOVE` ... `MAP`, `ORDER`, `ACTIONS`, `next_tip(done: Dictionary, facts: Dictionary) -> String`, `text_for(id: String, pad: bool, family: String) -> String`) | scripts/core/first_run_tips.gd | | 7 |
| `ProgressData.tips_done: Dictionary`, `ProgressData.mark_tip(id: String) -> bool`, `ProgressData.reset_tips()` | progress_data.gd | | 7 |
| `Progress.mark_tip_done(id: String)`, `Progress.reset_tips()` | scripts/autoload/progress.gd | save at once | 7 |
| `Hud.show_tip(text: String)`, `Hud.clear_tip()`, `Hud.tip_text() -> String`, `Hud.TIP_RECT` | hud.gd | | 7 |
| `TipCoach` (`setup(player: Player, hud: Hud, run: RunState, rules: RuleKeeper)`, `set_room(view: RoomView, room_type: String)`, `facts() -> Dictionary`, `note_done(id: String)`) | scripts/ui/tip_coach.gd | | 7 |
| `RuleKeeper.lift_rule(room_id: int)` | rule_keeper.gd | the loop's way to quiet a room it measures | 8 |

---

### Task 1: Attack warnings on by default, and a one-press skip for the opening

**Files:**
- Modify: `scripts/core/game_settings.gd` (DEFAULTS), `scripts/scenes/opening.gd`
- Test: `tests/test_game_settings.gd` (add one assert), create `tests/test_opening.gd`

**Interfaces:**
- Consumes: `Game.finish_opening()`, `KeyBindings.label_for(action)`, `PadInput.BACK_ACTION`.
- Produces: `attack_warnings` default `true`; `static func next_index(index: int, skip: bool) -> int` in opening.gd.

Old tests that pin these: `grep -rn "attack_warnings" tests` finds only `tests/test_attack_warnings.gd:80` (a source read of attack_warnings.gd, unaffected). `test_game_settings.gd` `test_defaults` (lines 28-43) lists the GAME defaults without `attack_warnings`; add it there. No test names the opening.

- [ ] **Step 1: Write the failing tests.** In `tests/test_game_settings.gd`, in the defaults test, after the `run_timer` assert add:

```gdscript
	assert_eq(s.value(GameSettings.GAME, "attack_warnings"), true, "new players see the red warnings")
```

and a new test at the end of the file:

```gdscript
# A file saved before this build holds attack_warnings=false (save_to writes every key) and keeps it.
func test_a_saved_file_keeps_its_attack_warnings() -> void:
	var path := OS.get_temp_dir().path_join("grandpa_settings_warn_test.cfg")
	var old := GameSettings.new()
	old.set_value(GameSettings.GAME, "attack_warnings", false)
	assert_true(old.save_to(path))
	var loaded := GameSettings.new()
	assert_true(loaded.load_from(path))
	assert_eq(loaded.value(GameSettings.GAME, "attack_warnings"), false)
	DirAccess.remove_absolute(path)
```

Create `tests/test_opening.gd`:

```gdscript
extends TestCase

const OPENING := "res://scripts/scenes/opening.gd"


func test_a_press_shows_the_next_card() -> void:
	var script: GDScript = load(OPENING)
	assert_eq(script.next_index(0, false), 1)
	assert_eq(script.next_index(5, false), 6)


func test_skip_ends_it_in_one_press() -> void:
	var script: GDScript = load(OPENING)
	var count: int = script.LINES.size()
	assert_eq(script.next_index(0, true), count)
	assert_eq(script.next_index(count - 1, false), count, "the last card's press ends it too")
```

- [ ] **Step 2: Run them and see them fail.** Run: `-- --only=game_settings` and `-- --only=opening` (the first fails on the default, the second on the missing function).

- [ ] **Step 3: Implement.**
  - `game_settings.gd`: `"attack_warnings": true,` and update the comment above it: "On by default since the player build; a file saved earlier keeps its own value."
  - `opening.gd`: add

```gdscript
const HINT := "Click or press %s to continue. %s to skip."


static func next_index(index: int, skip: bool) -> int:
	return LINES.size() if skip else mini(index + 1, LINES.size())
```

  and replace the body of `_unhandled_input`:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
	var skip := event.is_action_pressed("pause") or event.is_action_pressed(PadInput.BACK_ACTION) or event.is_action_pressed("ui_cancel")
	var next := event.is_action_pressed("attack") or event.is_action_pressed("dodge") or event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	if not skip and not next:
		return
	_index = next_index(_index, skip)
	if _index >= LINES.size():
		Game.finish_opening()
	else:
		_label.text = LINES[_index]
```

  and set the hint with `hint.text = tr(HINT) % [KeyBindings.label_for("dodge"), KeyBindings.label_for("pause")]`.
  - Check `Game.finish_opening()` can only run once: if it changes scene, a second press in the same frame must not call it twice. Guard with a `var _done := false` set before calling it.

- [ ] **Step 4: Run the tests and see them pass.** `-- --only=game_settings`, `-- --only=opening`, `-- --only=attack_warnings`, `-- --only=options`.

- [ ] **Step 5: Commit.** `git ls-files --eol tests/test_opening.gd` (expect `i/lf` once added). `git commit -m "Turn attack warnings on by default and let the opening be skipped" -m "Co-Authored-By: Claude <noreply@anthropic.com>"`

---

### Task 2: Rules on every floor, early on a first run, and a fair No Loitering

**Files:**
- Modify: `scripts/core/rule_picker.gd`, `scripts/world/rule_keeper.gd`, `scripts/actors/player.gd` (one function), `scripts/scenes/floor_scene.gd` (one line)
- Test: `tests/test_rule_picker.gd`, `tests/test_rule_item_hooks.gd`, `tests/test_rule_keeper.gd`

**Interfaces:**
- Consumes: `FloorMap.main_path: Array[int]`, `FloorMap.start_id`, `map.room(id).room_type`, `RoomLayout.TYPE_COMBAT`, `Player.is_taped()`, `Player.is_self_stunned()`, `Progress.data.run_count`, `Progress.is_dev_run()`.
- Produces: `RulePicker.ENABLED_DEPTH := 99`, `RulePicker.EARLY_ROOMS := 3`, `RulePicker.early_candidates(map)`, `RulePicker.rule_rooms(map, depth, seed_text, extra := 0, early := false)`, `RuleKeeper.first_run`, `Player.is_held_still()`.

Old tests that pin the old behaviour (update them in this task):
- `tests/test_rule_picker.gd::test_the_prototype_posts_no_rules_below_floor_one` expects 0 rule rooms at depth 2. Replace it (below).
- `tests/test_rule_picker.gd::test_the_counts_follow_the_depth_table` passes `enabled_depth` explicitly (99, and 1 for "above the enabled depth"): still valid, keep.
- `tests/test_rule_item_hooks.gd::test_extra_rule_rooms_post_rules_deeper_too` passes `enabled_depth = 1` explicitly: still valid, keep.
- `tests/test_rule_item_hooks.gd::test_rules_items_are_offered_only_where_rules_are_posted` expects only `[plain]` at depth 2. Change it (below).
- `tests/test_rule_item_hooks.gd` line 187 pins the source line `RulePicker.rule_rooms(map, depth, seed_text, _run.stats.extra_rule_rooms if _run != null else 0)`. Change it to the new line (below).

- [ ] **Step 1: Write the failing tests.** In `tests/test_rule_picker.gd` replace `test_the_prototype_posts_no_rules_below_floor_one` with:

```gdscript
func test_every_floor_posts_rules() -> void:
	assert_eq(RulePicker.rule_room_count(2, 6), 2, "depth 2 by the default enabled depth")
	assert_eq(RulePicker.rule_room_count(4, 10), 4, "deep floors: 40%")
	assert_eq(RulePicker.rule_room_count(5, 3), 2, "at least 2")
	for seed_text in SEEDS:
		var map := _floor_map(seed_text)
		var ids := RulePicker.rule_rooms(map, 2, seed_text)
		assert_eq(ids.size(), mini(2, _combat_count(map)), "seed %s" % seed_text)
		for id in ids:
			assert_eq(map.room(id).room_type, RoomLayout.TYPE_COMBAT)
			assert_true(id != map.start_id)


func _combat_count(map: FloorMap) -> int:
	var n := 0
	for room in map.rooms:
		if room.room_type == RoomLayout.TYPE_COMBAT and room.id != map.start_id:
			n += 1
	return n


func test_a_first_run_meets_its_rule_in_the_first_three_fights() -> void:
	for seed_text in SEEDS:
		var map := _floor_map(seed_text)
		var early := RulePicker.early_candidates(map)
		assert_true(early.size() >= 1 and early.size() <= RulePicker.EARLY_ROOMS, "seed %s" % seed_text)
		var on_path := map.main_path.filter(func(id): return map.room(id).room_type == RoomLayout.TYPE_COMBAT and id != map.start_id)
		for i in early.size():
			assert_eq(early[i], on_path[i], "in main-path order")
		var ids := RulePicker.rule_rooms(map, 1, seed_text, 0, true)
		assert_eq(ids.size(), 1)
		assert_true(early.has(ids[0]), "seed %s: room %d" % [seed_text, ids[0]])
		assert_eq(RulePicker.rule_rooms(map, 1, seed_text, 0, true), ids, "same seed, same room")


func test_later_runs_place_rules_as_before() -> void:
	# The old draw: the default (not early) picks are unchanged by this round, so a seed replays the same.
	for seed_text in SEEDS:
		var map := _floor_map(seed_text)
		assert_eq(RulePicker.rule_rooms(map, 1, seed_text), RulePicker.rule_rooms(map, 1, seed_text, 0, false))
```

(Before writing the second test, read `scripts/core/floor_map.gd` to confirm `main_path` holds room ids in order from the start; if it holds cells, map them to ids the way `FloorMap` does and say so in the test comment. A floor-1 map whose main path has no combat room is impossible by its layout rules; if a seed has none, `early_candidates` returns `[]` and `rule_rooms` falls back to the normal draw. Add that case to the test only if a seed shows it.)

In `tests/test_rule_item_hooks.gd::test_rules_items_are_offered_only_where_rules_are_posted`, replace the depth-2 lines with:

```gdscript
	run.floor_depth = 2
	assert_eq(RoomRules.offerable(all, run).size(), 3, "rules post on every floor now")
	run.floor_depth = 5
	assert_eq(RoomRules.offerable(all, run).size(), 3)
```

(keep the `book` lines after it) and rename the test `test_rules_items_are_offered_on_every_floor`. At line 187 change the pinned string to `RulePicker.rule_rooms(map, depth, seed_text, _run.stats.extra_rule_rooms if _run != null else 0, first_run)`.

In `tests/test_rule_keeper.gd` add (read the file first to reuse its helpers for a keeper with a player; if none exists build it as below):

```gdscript
# Red tape and the Polyester Suit's spark hold his feet against his will; that time never counts as loitering.
func test_being_held_is_not_loitering() -> void:
	var watch := RuleWatch.new(RoomRule.NO_LOITERING)
	watch.state = RuleWatch.State.ACTIVE
	for i in 200:
		assert_false(watch.tick_still(0.02, RuleKeeper.counts_as_moving(0.0, true)), "held for %.2f s" % (i * 0.02))
	assert_true(RuleKeeper.counts_as_moving(RuleKeeper.STILL_SPEED, false))
	assert_false(RuleKeeper.counts_as_moving(0.0, false))


func test_a_player_held_still_says_so() -> void:
	var player := Player.new()
	player.setup(ItemKit.new().make_run())
	assert_false(player.is_held_still())
	player.stun_self(1.0)
	assert_true(player.is_held_still())
	player.free()
```

(Check `RuleWatch.State` and how a watch becomes `ACTIVE` in `scripts/core/rule_watch.gd`; set it the way the existing rule-watch tests do.)

- [ ] **Step 2: Run and see them fail.** `-- --only=rule_picker`, `-- --only=rule_item_hooks`, `-- --only=rule_keeper`.

- [ ] **Step 3: Implement.**

`rule_picker.gd`:

```gdscript
# Rules post on every floor since the player build. Kept as a constant so a test can still ask for less.
const ENABLED_DEPTH := 99
const BY_DEPTH := {1: 1, 2: 2}
const DEEP_SHARE := 0.4
const DEEP_MIN := 2
# A save's first run meets its first rule among the first few fights on the main path.
const EARLY_ROOMS := 3


# The first EARLY_ROOMS combat rooms on the main path, in path order, never the start room.
static func early_candidates(map: FloorMap) -> Array[int]:
	var out: Array[int] = []
	for id in map.main_path:
		if out.size() >= EARLY_ROOMS:
			break
		if id != map.start_id and map.room(id).room_type == RoomLayout.TYPE_COMBAT:
			out.append(id)
	return out


# early (a save's first run): the first pick comes from early_candidates; the rest as always.
static func rule_rooms(map: FloorMap, depth: int, seed_text: String, extra := 0, early := false) -> Array[int]:
	var combat: Array[int] = []
	for room in map.rooms:
		if room.room_type == RoomLayout.TYPE_COMBAT and room.id != map.start_id:
			combat.append(room.id)
	combat.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_text + ":rule_rooms")
	var picked: Array[int] = []
	var count := rule_room_count(depth, combat.size(), ENABLED_DEPTH, extra)
	var first := early_candidates(map) if early else ([] as Array[int])
	if count > 0 and not first.is_empty():
		var chosen: int = first[rng.randi_range(0, first.size() - 1)]
		picked.append(chosen)
		combat.erase(chosen)
	while picked.size() < count:
		picked.append(combat.pop_at(rng.randi_range(0, combat.size() - 1)))
	picked.sort()
	return picked
```

(With `early` false the generator is drawn exactly as before: same rooms for the same seed.)

`player.gd`, beside `is_self_stunned()`:

```gdscript
# Held where he stands against his will (red tape, the Polyester Suit's spark), for No Loitering.
func is_held_still() -> bool:
	return is_taped() or is_self_stunned()
```

`rule_keeper.gd`:
  - add `var first_run := false` under `var current_id`, with the comment "A save's first run: the floor's first rule room is one of its first fights (FloorScene sets it)."
  - in `plan_floor` pass it: `_rule_rooms = RulePicker.rule_rooms(map, depth, seed_text, _run.stats.extra_rule_rooms if _run != null else 0, first_run)` (exactly this text: the test pins it).
  - add

```gdscript
# A step at STILL_SPEED or more is moving; so is any moment he is held where he stands.
static func counts_as_moving(speed: float, held: bool) -> bool:
	return held or speed >= STILL_SPEED
```

  - in `_process` replace `_player.velocity.length() >= STILL_SPEED` with `counts_as_moving(_player.velocity.length(), _player.is_held_still())`.

`floor_scene.gd`, right after `add_child(_rules)` in `_ready`:

```gdscript
	# A new save's first run meets a rule early (RulePicker.early_candidates).
	_rules.first_run = Progress.data.run_count <= 1 and not Progress.is_dev_run()
```

(Confirm `Progress.start_run()` has already raised `run_count` when the floor scene's `_ready` runs: `Game.begin_run` in `scripts/autoload/game.gd`. If it runs later, use `run_count <= 0` and say why in the comment.)

- [ ] **Step 4: Check every rule on every floor (a read, no code unless a gap shows).** `RoomRule.can_apply` already gates Explosives (Thermos held), Food (potion held), Exhibits (`RoomView.has_breakables`, cane-breakable blocks only). Grep `scripts/world/` for `class_name .* extends BreakableBlock` and for nodes that break on `SOURCE_CANE` but are not direct children of the room view (props in a container would be missed by `has_breakables`, which only reads direct children); if any deep-floor breakable sits in a container, make `has_breakables` walk the container too and add a test with that floor's prop. Note the result in the commit body.

- [ ] **Step 5: Run and see them pass.** `-- --only=rule`, `-- --only=room_rules`, `-- --only=reels`.

- [ ] **Step 6: Commit.** `git commit -m "Post room rules on every floor and early in a first run" -m "Co-Authored-By: Claude <noreply@anthropic.com>"`

---

### Task 3: The Auditor keeps up with depth

**Files:**
- Modify: `scripts/actors/behaviors/auditor_behavior.gd`, `scripts/world/room_view.gd` (`_tick_audit`)
- Test: `tests/test_auditor.gd`

**Interfaces:**
- Consumes: `RoomView._spawn_enemy` (already applies `FloorDef.health_mult` and `pension_mult`), `RoomView._floor_def.depth`, `Enemy._behavior`.
- Produces: `class_name AuditorBehavior`, `static func cooldown_mult(depth: int) -> float`, `var tempo := 1.0`.

Old tests: `test_auditor.gd` pins his floor-1 health band and Pension ratio; both stay true (depth 1 is unchanged). `grep -rn "auditor_behavior" tests tools` before naming the class: if a test or the bot loads the script by path, it still works.

- [ ] **Step 1: Write the failing tests** (append to `tests/test_auditor.gd`):

```gdscript
func _view_on(floor_path: String) -> RoomView:
	var room := FloorRoom.new()
	room.layout = load("res://data/rooms/floor_1/combat_01.tres")
	room.room_type = RoomLayout.TYPE_COMBAT
	var view := RoomView.new()
	view.setup(room, null, load(floor_path), RunState.new([] as Array[UpgradeDef], {}), null, RandomNumberGenerator.new(), null, null)
	return view


# He takes the floor's health rate like every enemy: 160 on floor 1, 352 on a 2.2 floor.
func test_his_health_follows_the_floor() -> void:
	for path in ["res://data/floors/floor_1.tres", "res://data/floors/last_resort_cruise.tres"]:
		var floor_def: FloorDef = load(path)
		var view := _view_on(path)
		view.call_auditor(load(AUDITOR), null)
		view._tick_audit(RoomView.AUDIT_DELAY + 0.1)
		var him: Enemy = _auditors(view)[0]
		assert_near(him.max_hp(), 160.0 * floor_def.health_mult, path)
		view.free()


func test_he_presses_harder_deeper_but_never_on_floor_one() -> void:
	assert_near(AuditorBehavior.cooldown_mult(1), 1.0)
	assert_near(AuditorBehavior.cooldown_mult(2), 0.94)
	assert_near(AuditorBehavior.cooldown_mult(4), 0.82)
	assert_near(AuditorBehavior.cooldown_mult(5), 0.76)
	assert_near(AuditorBehavior.cooldown_mult(9), 0.76, "never quicker than the floor-5 rate")
	var view := _view_on("res://data/floors/last_resort_cruise.tres")
	view.call_auditor(load(AUDITOR), null)
	view._tick_audit(RoomView.AUDIT_DELAY + 0.1)
	var him: Enemy = _auditors(view)[0]
	assert_near((him._behavior as AuditorBehavior).tempo, 0.82, "floor 4")
	view.free()
```

(`_auditors(view)` is the file's existing helper. If `RoomView.setup` with the cruise floor needs its own room layout, use `data/rooms/` of that floor instead; read `_view()` first.)

- [ ] **Step 2: Run and see it fail.** `-- --only=auditor`.

- [ ] **Step 3: Implement.** In `auditor_behavior.gd` add `class_name AuditorBehavior` above `extends EnemyBehavior`, then:

```gdscript
# Deeper floors' regulars press harder, so does he: shorter rests between attacks, never shorter windups,
# so his warnings read the same. Floor 1 is exactly as before.
const DEPTH_STEP := 0.06
const MIN_TEMPO := 0.76

var tempo := 1.0


static func cooldown_mult(depth: int) -> float:
	return clampf(1.0 - DEPTH_STEP * float(depth - 1), MIN_TEMPO, 1.0)
```

and set `_swing_cooldown = SWING_COOLDOWN * tempo` and `_throw_cooldown = THROW_COOLDOWN * tempo` where they are reset. In `room_view.gd::_tick_audit`, after `var auditor := _spawn_enemy(_audit_def, at)`:

```gdscript
	if auditor._behavior is AuditorBehavior:
		(auditor._behavior as AuditorBehavior).tempo = AuditorBehavior.cooldown_mult(_floor_def.depth if _floor_def != null else 1)
```

- [ ] **Step 4: Run and see it pass.** `-- --only=auditor`, `-- --only=rule_item_hooks` (Clipboard of Your Own's ally Auditor must not change: `AllyAuditor` is its own class).

- [ ] **Step 5: Commit.** `git commit -m "Shorten the Auditor's rests on deeper floors" -m "Co-Authored-By: Claude <noreply@anthropic.com>"`

---

### Task 4: Two new eras: the Dance Hall, 1962 and the Allotment, 1988

**Files:**
- Modify: `scripts/core/eras.gd`, `scripts/actors/era_moves.gd`, `scripts/actors/player.gd`, `scripts/world/room_view.gd` (`is_passing_effect`), `tools/probes/bot_probe.gd` (`ERA_TURNS`)
- Create: `scripts/actors/era_shot.gd`
- Test: `tests/test_eras.gd`, `tests/test_reels.gd`

**Interfaces:**
- Consumes: `Player.era_hit(enemy, damage, push, from)`, `ThrownDentures.BLOCKED_BY`, `SpriteVisual.has_anim`, `Enemy.body_rect()`, `Enemy.submerged`.
- Produces: `Eras.DANCE`, `Eras.ALLOTMENT`, `Eras.BIRTH_YEAR`, `Eras.STARTING` (`[FOOTBALL, DANCE, BUS, ALLOTMENT]`), `Eras.year(id)`, `Eras.age(id)`, `Eras.tint(id)`; `EraMoves.throw_cooldown`, `dodge_length`, `DISC_COOLDOWN`, `MARROW_COOLDOWN`; `EraShot`.

Old tests that pin the old list (update in this task):
- `tests/test_reels.gd::test_the_two_prototype_eras_start_unlocked`: asserts `Eras.STARTING == [FOOTBALL, BUS]`. Rename `test_four_eras_start_unlocked` and assert the four (below).
- `tests/test_reels.gd::test_unknown_saved_eras_are_dropped`: `[BUS, "moon_landing_1969"]` loads as `[BUS]`, and `data.eras_unlocked = [BUS]` round-trips as `[BUS]`. Both now give `Eras.STARTING` (starting eras are always held). Rewrite (below).
- `tests/test_eras.gd::test_each_era_plays_differently` and `test_era_damage_per_second_is_above_old_harolds` cover FOOTBALL and BUS only: keep, and add the new ones beside.
- `tests/test_eras.gd::test_cane_pace_and_push_items_leave_the_era_moves_alone` loops `Eras.STARTING`: it covers the new eras automatically; keep.
- `tests/test_eras.gd` line ~202 checks the 1975 art is used if it exists: keep.
- `grep -rn "FOOTBALL_TINT\|BUS_TINT" tests tools` and update any hit to `Eras.tint(...)`.

- [ ] **Step 1: Write the failing tests.** In `tests/test_reels.gd` replace the first test and the unknown-eras test:

```gdscript
func test_four_eras_start_unlocked() -> void:
	assert_eq(Eras.STARTING, [Eras.FOOTBALL, Eras.DANCE, Eras.BUS, Eras.ALLOTMENT] as Array[String])
	assert_eq(ProgressData.new().eras_unlocked, Eras.STARTING)
	assert_eq(Eras.title(Eras.FOOTBALL), "Football on the Rec, 1960")
	assert_eq(Eras.title(Eras.DANCE), "The Dance Hall, 1962")
	assert_eq(Eras.title(Eras.BUS), "The No. 12 Bus, 1975")
	assert_eq(Eras.title(Eras.ALLOTMENT), "The Allotment, 1988")
	assert_near(Eras.speed_mult(Eras.FOOTBALL), 1.25)
	assert_near(Eras.speed_mult(Eras.DANCE), 1.1)
	assert_near(Eras.speed_mult(Eras.BUS), 1.0)
	assert_near(Eras.speed_mult(Eras.ALLOTMENT), 1.0)
	assert_near(Eras.speed_mult(""), 1.0)


# Born 1942: every era's age is its year minus that.
func test_his_ages_agree_with_one_birth_year() -> void:
	assert_eq(Eras.BIRTH_YEAR, 1942)
	assert_eq(Eras.age(Eras.FOOTBALL), 18)
	assert_eq(Eras.age(Eras.DANCE), 20)
	assert_eq(Eras.age(Eras.BUS), 33)
	assert_eq(Eras.age(Eras.ALLOTMENT), 46)


# The starting eras are always held; other saved ids are kept only if this build knows them.
func test_an_older_save_gains_the_new_eras() -> void:
	var base := ProgressData.new().to_dict()
	var raw := base.duplicate(true)
	raw["eras_unlocked"] = [Eras.FOOTBALL, Eras.BUS]
	assert_eq(ProgressData.from_dict(raw).eras_unlocked, Eras.STARTING)
	raw["eras_unlocked"] = [Eras.BUS, "moon_landing_1969"]
	assert_eq(ProgressData.from_dict(raw).eras_unlocked, Eras.STARTING, "unknown ids drop")
	raw["eras_unlocked"] = "not a list"
	assert_eq(ProgressData.from_dict(raw).eras_unlocked, Eras.STARTING)
	base.erase("eras_unlocked")
	assert_eq(ProgressData.from_dict(base).eras_unlocked, Eras.STARTING)
```

Leave `test_a_reel_picks_an_unlocked_era_by_the_seed` as it is (it already loops `STARTING`).

In `tests/test_eras.gd` add:

```gdscript
func test_the_new_eras_play_unlike_the_old_ones() -> void:
	var spin := EraMoves.for_era(Eras.DANCE)
	var spade := EraMoves.for_era(Eras.ALLOTMENT)
	var kick := EraMoves.for_era(Eras.FOOTBALL)
	var punch := EraMoves.for_era(Eras.BUS)
	assert_near(spin.angle, 180.0, "the spin hits all round")
	assert_true(spin.reach < kick.reach, "close round him")
	assert_true(spin.combo_damage[0] < kick.combo_damage[-1], "weaker a hit than the kick combo's finisher")
	assert_true(spin.lock_time < CaneCombo.LOCK_TIME, "quick")
	assert_true(spade.reach > Player.ATTACK_REACH * 1.4 and spade.reach > punch.reach, "reaches well past the cane")
	assert_true(spade.angle < 20.0, "a thrust, not a sweep")
	assert_true(spade.lock_time > punch.lock_time, "slow")
	assert_true(spade.combo_damage[0] > punch.combo_damage[0], "the heaviest hit")
	assert_near(spin.dodge_length, 1.3, "the slide runs long")
	assert_true(spade.dodge_push > Player.ATTACK_PUSH, "the handle shove pushes")


func test_the_new_eras_sit_in_the_damage_bands() -> void:
	var old := _old_combo() / (CaneCombo.LOCK_TIME * CaneCombo.DAMAGE.size())
	var spin := EraMoves.for_era(Eras.DANCE)
	var spin_dps := _combo_total(spin) / (spin.lock_time * spin.combo_damage.size())
	assert_true(spin_dps >= old and spin_dps <= old * 1.2, "spin at %.1f vs %.1f" % [spin_dps, old])
	var spade := EraMoves.for_era(Eras.ALLOTMENT)
	var spade_dps := _combo_total(spade) / (spade.lock_time * spade.combo_damage.size())
	assert_true(spade_dps < old and spade_dps >= old * 0.75, "spade at %.1f vs %.1f" % [spade_dps, old])
	assert_true(spade.combo_damage[0] > float(CaneCombo.DAMAGE.max()))


func test_the_record_and_the_marrow_wait_their_cooldowns() -> void:
	for id in [Eras.DANCE, Eras.ALLOTMENT]:
		var moves := EraMoves.for_era(id)
		assert_true(moves.throw_ready())
		var shot := moves.make_throw(Vector2.RIGHT)
		assert_true(shot is EraShot, id)
		assert_false(moves.throw_ready())
		moves.tick(moves.throw_cooldown - 0.1)
		assert_false(moves.throw_ready())
		moves.tick(0.2)
		assert_true(moves.throw_ready())
		shot.free()
	assert_near(EraMoves.for_era(Eras.DANCE).throw_cooldown, EraMoves.DISC_COOLDOWN)
	assert_near(EraMoves.for_era(Eras.ALLOTMENT).throw_cooldown, EraMoves.MARROW_COOLDOWN)


func test_the_record_passes_through_and_the_marrow_splashes() -> void:
	var disc := EraShot.for_disc()
	assert_true(disc.pierce and disc.splash_radius == 0.0)
	var marrow := EraShot.for_marrow()
	assert_false(marrow.pierce)
	assert_near(marrow.splash_radius, 24.0)
	var bodies := [Rect2(100, 0, 10, 10), Rect2(118, 0, 10, 10), Rect2(200, 0, 10, 10)]
	assert_eq(EraShot.splash_targets(Vector2(105, 5), bodies, marrow.splash_radius), [0, 1], "the two within 24 px")
	disc.free()
	marrow.free()


func test_an_era_without_art_shows_old_harold_tinted() -> void:
	for id in Eras.STARTING:
		if not SpriteVisual.has_anim(Eras.art_id(id), "idle"):
			assert_true(Eras.tint(id) != Color.WHITE, "%s is told apart by a tint" % id)
	assert_eq(Eras.tint(""), Color.WHITE)
```

- [ ] **Step 2: Run and see them fail.** `-- --only=eras`, `-- --only=reels`.

- [ ] **Step 3: Implement `eras.gd`.** Replace the data block:

```gdscript
const FOOTBALL := "rec_football_1960"
const DANCE := "dance_hall_1962"
const BUS := "no12_bus_1975"
const ALLOTMENT := "allotment_1988"
# In the order of his life. All four are his from the start; endings unlock later ones.
const STARTING: Array[String] = [FOOTBALL, DANCE, BUS, ALLOTMENT]
# He was born in 1942 (87 at the opening's death, in 2029): an era's age is its year minus this.
const BIRTH_YEAR := 1942

const _DATA := {
	FOOTBALL: {"title": "Football on the Rec, 1960", "year": 1960, "speed": 1.25, "art": "harold_1960", "tint": Color("ffd9a0")},
	DANCE: {"title": "The Dance Hall, 1962", "year": 1962, "speed": 1.1, "art": "harold_1962", "tint": Color("f0c8e8")},
	BUS: {"title": "The No. 12 Bus, 1975", "year": 1975, "speed": 1.0, "art": "harold_1975", "tint": Color("c9d8ff")},
	ALLOTMENT: {"title": "The Allotment, 1988", "year": 1988, "speed": 1.0, "art": "harold_1988", "tint": Color("c8e0b0")},
}
```

and add:

```gdscript
static func year(id: String) -> int:
	return int(_DATA.get(id, {}).get("year", 0))


static func age(id: String) -> int:
	return year(id) - BIRTH_YEAR if is_known(id) else 0


# Old Harold's sprite tinted, for an era whose own art is not in yet. White for old Harold.
static func tint(id: String) -> Color:
	var data: Dictionary = _DATA.get(id, {})
	return data.get("tint", Color.WHITE)
```

and change `known_or_starting` so the starting eras are always there:

```gdscript
# The starting eras, always, then any other saved era this build knows, in saved order.
static func known_or_starting(raw: Variant) -> Array[String]:
	var out: Array[String] = STARTING.duplicate()
	if raw is Array:
		for id in raw:
			if is_known(str(id)) and not out.has(str(id)):
				out.append(str(id))
	return out
```

- [ ] **Step 4: Implement `era_shot.gd`.**

```gdscript
class_name EraShot
extends Node2D

# A younger Harold's straight throw: the Dance Hall's 45 record (flies through everyone in its way) or the
# Allotment's marrow (stops at the first it hits, or at its range or a wall, and splashes all near). Its hits
# go through Player.era_hit, so stat items apply and the denture items don't. Pays and spawns nothing.

const LOOK_DISC := "disc"
const LOOK_MARROW := "marrow"
const RADIUS := 5.0

var direction := Vector2.RIGHT
var damage := 7.0
var speed := 240.0
var max_range := 200.0
var pierce := true
var splash_radius := 0.0
var look := LOOK_DISC
var _flown := 0.0
var _hit := {}
var _spin := 0.0


static func for_disc() -> EraShot:
	var shot := EraShot.new()
	shot.look = LOOK_DISC
	shot.damage = 7.0
	shot.speed = 240.0
	shot.max_range = 200.0
	shot.pierce = true
	return shot


static func for_marrow() -> EraShot:
	var shot := EraShot.new()
	shot.look = LOOK_MARROW
	shot.damage = 14.0
	shot.speed = 170.0
	shot.max_range = 150.0
	shot.pierce = false
	shot.splash_radius = 24.0
	return shot


# Indexes of the bodies within radius of at (nearest point of each body), in their order.
static func splash_targets(at: Vector2, bodies: Array, radius: float) -> Array:
	var out := []
	for i in bodies.size():
		var body: Rect2 = bodies[i]
		if MeleeArc.closest_point(body, at).distance_to(at) <= radius:
			out.append(i)
	return out


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var step := direction * speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step + direction * RADIUS, ThrownDentures.BLOCKED_BY)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		_land(player)
		return
	global_position += step
	_flown += step.length()
	_spin += delta * 12.0
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		var id := enemy.get_instance_id()
		if _hit.has(id) or enemy.is_queued_for_deletion() or enemy.submerged or enemy.is_dead():
			continue
		if not enemy.body_rect().grow(RADIUS).has_point(global_position):
			continue
		_hit[id] = true
		if player != null:
			player.era_hit(enemy, damage, direction * 60.0, global_position)
		if not pierce:
			_land(player)
			return
	if _flown >= max_range:
		_land(player)
		return
	queue_redraw()


# Where it stops: the marrow splashes everyone near who it has not already hit.
func _land(player: Player) -> void:
	if splash_radius > 0.0 and player != null:
		var enemies: Array[Enemy] = []
		var bodies := []
		for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
			if not _hit.has(enemy.get_instance_id()) and not enemy.is_queued_for_deletion() and not enemy.submerged and not enemy.is_dead():
				enemies.append(enemy)
				bodies.append(enemy.body_rect())
		for i in splash_targets(global_position, bodies, splash_radius):
			player.era_hit(enemies[i], damage, Vector2.ZERO, global_position)
	queue_free()


func _draw() -> void:
	if look == LOOK_MARROW:
		# A green ellipse along its flight with a darker stripe down its length: no crossing strokes.
		var points := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			points.append(Vector2(cos(a) * 7.0, sin(a) * 4.0).rotated(direction.angle()))
		draw_colored_polygon(points, Color("5e8c3a"))
		draw_line(-direction * 5.0, direction * 5.0, Color("3f6126"), 1.0)
	else:
		draw_circle(Vector2.ZERO, RADIUS, Color("1c1a1e"))
		draw_circle(Vector2.ZERO, 2.0, Color("d9493f"))
		draw_arc(Vector2.ZERO, 3.5, _spin, _spin + 1.2, 6, Color("4a4650"), 1.0)
```

(Check `Enemy.is_dead()` exists, as `_era_dodge_strike` uses it. If `MeleeArc.closest_point` takes its arguments in another order, follow its signature in `scripts/core/melee_arc.gd`.)

- [ ] **Step 5: Implement `era_moves.gd`.** Add `const DISC_COOLDOWN := 1.5`, `const MARROW_COOLDOWN := 2.0`, `var throw_cooldown := TICKET_ROLL_COOLDOWN`, `var dodge_length := 1.0`. In `for_era` add:

```gdscript
		Eras.DANCE:
			# One spin, all round and close: 9 over a 0.14 s lock = 64/s on paper, a hair over the cane's
			# 63/s, but it lands on everyone in reach at once.
			moves.combo_damage = [9.0]
			moves.reach = 30.0
			moves.angle = 180.0
			moves.push = 40.0
			moves.lock_time = 0.14
			# The slide runs long and nudges whoever he slides into.
			moves.dodge_hit_damage = 3.0
			moves.dodge_push = 30.0
			moves.dodge_length = 1.3
			moves.throw_cooldown = DISC_COOLDOWN
		Eras.ALLOTMENT:
			# A slow, strong spade thrust well past the cane: 30 over a 0.5 s lock = 60/s on paper; like the
			# punch, its weight per swing sets his pace in play (about 15% above old Harold).
			moves.combo_damage = [30.0]
			moves.reach = 64.0
			moves.angle = 15.0
			moves.push = 110.0
			moves.lock_time = 0.5
			# A shove with the spade's handle.
			moves.dodge_hit_damage = 6.0
			moves.dodge_push = 120.0
			moves.throw_cooldown = MARROW_COOLDOWN
```

Set `moves.throw_cooldown = TICKET_ROLL_COOLDOWN` in the BUS branch (unchanged value). Change `make_throw` to:

```gdscript
func make_throw(aim: Vector2) -> Node2D:
	if era == Eras.FOOTBALL:
		_ball = EraBall.new()
		_ball.direction = aim
		return _ball
	_roll_left = throw_cooldown
	if era == Eras.DANCE or era == Eras.ALLOTMENT:
		var shot := EraShot.for_disc() if era == Eras.DANCE else EraShot.for_marrow()
		shot.direction = aim
		return shot
	var line := TicketLine.new()
	line.direction = aim
	return line
```

(`var shot := A if c else B` is fine here: both sides are `EraShot`. If the parser still refuses, write `var shot: EraShot = ...`.)

- [ ] **Step 6: Wire Player and the room.**
  - `player.gd`: delete `FOOTBALL_TINT` and `BUS_TINT`; `_era_tint()` returns `Color.WHITE` when `_era.is_empty() or SpriteVisual.has_anim(Eras.art_id(_era), "idle")`, else `Eras.tint(_era)`. Update the comment above it.
  - `player.gd::start_dodge`: the length becomes `DodgeTimer.DURATION * run.stats.dodge_length * (_era_moves.dodge_length if _era_moves != null else 1.0)`.
  - `room_view.gd::is_passing_effect`: `if child is EraBall or child is TicketLine or child is EraShot:` and the comment "Flashbacks: the football, the ticket line, the record and the marrow".
  - `tools/probes/bot_probe.gd`: `const ERA_TURNS: Array[String] = ["", Eras.FOOTBALL, Eras.DANCE, Eras.BUS, Eras.ALLOTMENT]`, and update the header comment's list of selves. Read how the bot aims an era's attack (`reach`): a 180-degree spin needs no aim; check the bot does not stand off at `reach` for the spin in a way that never closes in (if it does, treat angle >= 180 as "close in to reach - 4").
  - `rules`: the spin and the thrust go through `_swing` (`swing_started`), the record and the marrow through `_era_throw` (`teeth_thrown`), so Leave Canes and Keep Your Teeth In apply unchanged. No code.

- [ ] **Step 7: Run and see them pass.** `-- --only=eras`, `-- --only=reels`, `-- --only=rule_keeper`, `-- --only=room_view`, then the full suite.

- [ ] **Step 8: Commit.** `git ls-files --eol scripts/actors/era_shot.gd` (expect `i/lf`; also add the `.uid` file Godot writes in the copy: copy `$COPY\scripts\actors\era_shot.gd.uid` into the worktree and add it, as earlier rounds did). `git commit -m "Add the Dance Hall and Allotment eras, with one birth year for all four" -m "Co-Authored-By: Claude <noreply@anthropic.com>"`

---

### Task 5: Hooks for Harold's hurt, death and dodge animations

**Files:**
- Modify: `scripts/actors/player.gd`, `scripts/scenes/floor_scene.gd` (`_end_run`)
- Test: create `tests/test_harold_anims.gd`

**Interfaces:**
- Consumes: `SpriteVisual.has_anim(art_id, anim)`, `SpriteVisual.play_once(anim, duration)`, `SpriteVisual.art_id()`, `Player.died`, `DodgeTimer.DURATION`.
- Produces: `Player.HURT_ANIM_TIME := 0.25`, `Player.DEATH_ANIM_TIME := 0.9`, `static func feedback_anim(art_id: String, anim: String) -> String`, `func death_anim_time() -> float`, `func uses_dodge_ghosts() -> bool`.

Old tests: `grep -rn "make_ghost\|_leave_dodge_ghosts\|GHOST_EVERY\|DodgeGhost" tests` and keep each passing: with no `dodge` strip yet the ghosts behave as today.

- [ ] **Step 1: Write the failing tests** (`tests/test_harold_anims.gd`):

```gdscript
extends TestCase

# SpriteVisual falls back to the attack strip for an anim it lacks, so Player asks first: "" means
# keep today's look.


func test_a_missing_strip_plays_nothing() -> void:
	for anim in ["hurt", "death", "dodge"]:
		assert_eq(Player.feedback_anim("no_such_art", anim), "", anim)
		assert_eq(Player.feedback_anim("", anim), "", anim)


func test_a_present_strip_plays() -> void:
	# idle exists for old Harold today, so it stands in for a present strip.
	assert_eq(Player.feedback_anim("grandpa", "idle"), "idle")


func test_without_strips_he_keeps_todays_look() -> void:
	var player := Player.new()
	player.setup(ItemKit.new().make_run())
	player._ready()
	var has_death := SpriteVisual.has_anim("grandpa", "death")
	assert_near(player.death_anim_time(), Player.DEATH_ANIM_TIME if has_death else 0.0)
	assert_eq(player.uses_dodge_ghosts(), not SpriteVisual.has_anim("grandpa", "dodge"))
	player.free()


func test_a_landed_hit_plays_hurt_only_with_its_strip() -> void:
	var player := Player.new()
	player.setup(ItemKit.new().make_run())
	player._ready()
	assert_true(player.take_hit(1))
	var has_hurt := SpriteVisual.has_anim("grandpa", "hurt")
	assert_eq(player._visual.anim() == "hurt", has_hurt, "hurt plays exactly when its strip is there")
	player.free()


func test_an_era_without_a_dodge_strip_keeps_the_ghosts() -> void:
	var player := Player.new()
	player.setup(ItemKit.new().make_run())
	player._ready()
	for id in Eras.STARTING:
		player.set_era(id)
		assert_eq(player.uses_dodge_ghosts(), not SpriteVisual.has_anim(player._visual.art_id(), "dodge"), id)
	player.free()
```

(If `player._ready()` needs `run.health` wiring the tests in `tests/test_eras.gd` already do, copy their setup. If `take_hit(1)` returns false because a fresh run is invulnerable, follow how `tests/test_player*.gd` lands a hit.)

- [ ] **Step 2: Run and see it fail.** `-- --only=harold_anims`.

- [ ] **Step 3: Implement in `player.gd`.**

```gdscript
# Harold's feedback anims, each only when the art shown has its strip (else today's look).
const HURT_ANIM_TIME := 0.25
const DEATH_ANIM_TIME := 0.9


# anim when that art has the strip, else "": SpriteVisual would show the attack strip instead.
static func feedback_anim(art_id: String, anim: String) -> String:
	return anim if SpriteVisual.has_anim(art_id, anim) else ""


func _shown_art() -> String:
	return _visual.art_id() if _visual != null else ""


# How long the game-over waits for his fall: 0 without a death strip.
func death_anim_time() -> float:
	return DEATH_ANIM_TIME if not feedback_anim(_shown_art(), "death").is_empty() else 0.0


# The ghost copies stand in for a dodge anim until the shown art has one.
func uses_dodge_ghosts() -> bool:
	return feedback_anim(_shown_art(), "dodge").is_empty()
```

  - In `take_hit`, inside `if landed:` after the flash: 

```gdscript
		if _visual != null:
			if run.health.is_dead():
				_play_death()
			elif not feedback_anim(_shown_art(), "hurt").is_empty() and not _dodge.is_active():
				_visual.play_once("hurt", HURT_ANIM_TIME)
```

  - add

```gdscript
# The scene disables him once he dies, so his sprite alone keeps running to finish the fall, then holds
# its last frame (SpriteVisual.once_frame).
func _play_death() -> void:
	if feedback_anim(_shown_art(), "death").is_empty():
		return
	_visual.process_mode = Node.PROCESS_MODE_ALWAYS
	_visual.play_once("death", DEATH_ANIM_TIME)
```

  - Deaths that do not come through `take_hit` (fire, contact, any other `health.hit`): also connect in `_ready`, after `run.health.died.connect(died.emit)`: `run.health.died.connect(_play_death)` (its own callable, no lambda). Make `_play_death` return at once if `_visual.anim() == "death"` so it never restarts.
  - In `start_dodge`, after `dodge_started.emit()`: `if not uses_dodge_ghosts(): _visual.play_once("dodge", DodgeTimer.DURATION * run.stats.dodge_length * (_era_moves.dodge_length if _era_moves != null else 1.0))` (use the same length expression `try_start` got; store it in a local first).
  - In `_leave_dodge_ghosts`, return early (after resetting `_ghost_left`) when `not uses_dodge_ghosts()`.
  - `_handle_movement` already skips walk/idle while `_visual.is_playing_once()`; a swing during a hurt anim replaces it (attack wins), which is wanted.

- [ ] **Step 4: Wait for the fall in `floor_scene.gd::_end_run`.** After `_rules.process_mode = Node.PROCESS_MODE_DISABLED` add:

```gdscript
	# His fall plays out before the message (no wait without a death strip).
	if player != null and player.run.health.is_dead():
		var fall := player.death_anim_time()
		if fall > 0.0:
			await get_tree().create_timer(fall).timeout
```

(Read `_end_run` first: if `player.run` is not the run's field name, use `_run.health`.)

- [ ] **Step 5: Run and see them pass.** `-- --only=harold_anims`, `-- --only=eras`, `-- --only=player`, `-- --only=dodge`, then the full suite.

- [ ] **Step 6: Commit.** `git commit -m "Play Harold's hurt, death and dodge strips when they exist" -m "Co-Authored-By: Claude <noreply@anthropic.com>"`

---

### Task 6: Bring in Harold's new strips

Runs only once `D:\grandpa-art\harold\` holds the art (it is generated separately tonight). If the folder or a set is missing, do the steps for what is there, commit, and report what was missing: every hook keeps today's look without its strip.

**Files:**
- Create: `tools/art/harold_anims.py`
- Modify: `tools/art/harold_outfits.py` (`ANIMS`)
- Create (art): `art/sprites/grandpa/{hurt,death,dodge}.png`, `art/sprites/harold_1960/dodge.png`, `art/sprites/harold_1975/dodge.png`, `art/sprites/harold_1962/{idle,walk,attack,dodge}.png`, `art/sprites/harold_1988/{idle,walk,attack,dodge}.png`, each with its `.png.import`; the cardigan outfits' new strips (`art/sprites/grandpa_<cosmetic>/{hurt,death,dodge}.png` + `.import`).
- Test: `tests/test_harold_art.gd` (create)

**Interfaces:**
- Consumes: `tools/art/npc_strips.py` (`load`, `join`), `tools/art/harold_strips.py` (`place`, `SIZE` 60, `FEET_ROW` 52), `Player.SPRITE_FRAME_WIDTH` (60).
- Produces: the strips above; `py -I tools/art/harold_anims.py <set folder> <target folder>`.

- [ ] **Step 1: Read the art notes.** Read `D:\grandpa-art\harold\notes.md`: per set and anim, the frame count, the direction(s), the frame file names and any frames to drop. Read `tools/art/harold_strips.py` (how `harold_1960/attack.png` was cut: export frames placed on a 60 px canvas, feet on row 52, east only) and `LESSONS.md` 2026-11-05 (feet rows), 2026-11-06 (rebuild in place, never `rm -rf` a sprite folder), 2026-11-08 (pixel fixes go into the tool). Use only east-facing frames; if a set has no east, stop and report.

- [ ] **Step 2: Write the failing art test** (`tests/test_harold_art.gd`). It skips any strip not present, so it is safe before the art lands:

```gdscript
extends TestCase

const STRIPS := {
	"grandpa": ["hurt", "death", "dodge"],
	"harold_1960": ["dodge"],
	"harold_1975": ["dodge"],
	"harold_1962": ["idle", "walk", "attack", "dodge"],
	"harold_1988": ["idle", "walk", "attack", "dodge"],
}


# Every strip is whole 60 px frames, his feet on one row (as harold_strips.py places them).
func test_new_strips_share_his_frame_and_feet() -> void:
	var seen := 0
	for art: String in STRIPS:
		for anim: String in STRIPS[art]:
			if not SpriteVisual.has_anim(art, anim):
				continue
			seen += 1
			var tex: Texture2D = load(SpriteVisual.art_path(art, anim))
			assert_eq(tex.get_height(), Player.SPRITE_FRAME_WIDTH, "%s/%s height" % [art, anim])
			assert_eq(tex.get_width() % Player.SPRITE_FRAME_WIDTH, 0, "%s/%s whole frames" % [art, anim])
			if anim != "death":
				assert_eq(SpriteVisual.feet_row(tex), SpriteVisual.feet_row(load(SpriteVisual.art_path("grandpa", "idle"))), "%s/%s feet" % [art, anim])
	print("harold art strips present: %d" % seen)


# An era with any strip of its own has the idle too, or Player would mix his art with old Harold's.
func test_an_era_with_art_has_its_idle() -> void:
	for art in ["harold_1962", "harold_1988"]:
		for anim in ["walk", "attack", "dodge"]:
			if SpriteVisual.has_anim(art, anim):
				assert_true(SpriteVisual.has_anim(art, "idle"), "%s has %s but no idle" % [art, anim])
```

(Check `SpriteVisual.feet_row` returns the row for a whole strip; if it takes a frame, compare frame 0.)

- [ ] **Step 3: Write `tools/art/harold_anims.py`.**

```python
# Cuts Harold's extra anims from frame folders (D:/grandpa-art/harold/<set>/<anim>/, east-facing PNGs,
# see that folder's notes.md) into art/sprites/<set>/<anim>.png: every frame on one 60 px canvas, feet on
# row 52, as harold_strips.py places his export, so Player.SPRITE_FRAME_WIDTH and SPRITE_FEET_Y hold.
# Only the anims whose folder exists are written; nothing else in the target is touched.
# Plain Python, no packages.
# Usage: py -I tools/art/harold_anims.py <set folder> <art/sprites/<set> folder> [anim ...]
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from npc_strips import join, load  # noqa: E402
from harold_strips import place  # noqa: E402

ANIMS = ('idle', 'walk', 'attack', 'hurt', 'death', 'dodge')
# Frames to leave out, per (set, anim), by index in sorted order, as notes.md asks (e.g. a reference pose).
DROP = {}


def frames_in(folder):
    names = sorted(n for n in os.listdir(folder) if n.lower().endswith('.png'))
    return [os.path.join(folder, n) for n in names]


def main():
    source, target = sys.argv[1], sys.argv[2]
    wanted = sys.argv[3:] or ANIMS
    set_name = os.path.basename(os.path.normpath(source))
    os.makedirs(target, exist_ok=True)
    for anim in wanted:
        folder = os.path.join(source, anim)
        if not os.path.isdir(folder):
            print(anim, 'missing')
            continue
        paths = [p for i, p in enumerate(frames_in(folder)) if i not in DROP.get((set_name, anim), ())]
        frames = [place(load(p)) for p in paths]
        join(frames, os.path.join(target, anim + '.png'))
        print(anim, len(frames))


if __name__ == '__main__':
    main()
```

(If notes.md puts east frames in a subfolder, such as `<anim>/east/`, point `folder` there. If a frame is wider than 60 px or reaches the canvas top, `place` raises: report it rather than scaling. Fill `DROP` from notes.md.)

- [ ] **Step 4: Cut the strips.** For each set present: `py -I tools/art/harold_anims.py D:/grandpa-art/harold/<set> C:/GameDev/game/.worktrees/player-build/art/sprites/<set>` (for `grandpa`, pass `hurt death dodge` so his idle, walk and attack are never rewritten; for `harold_1960` and `harold_1975`, pass `dodge`). Then add `'hurt', 'death', 'dodge'` to `ANIMS` in `tools/art/harold_outfits.py`, make it skip an anim whose base strip is missing, and run `py -I tools/art/harold_outfits.py C:/GameDev/game/.worktrees/player-build`. Check it reports every new strip's cardigan pixels found (a hurt or death pose may hide the cardigan; zero recoloured pixels in a frame is fine only if the frame shows no cardigan).

- [ ] **Step 5: Import and bring back the `.import` files.** Refresh the copy (Global Constraints; it imports). For each new PNG, copy `$COPY\art\sprites\<set>\<anim>.png.import` into the same path in the worktree, then convert to LF with `py -I -c "import sys;p=sys.argv[1];b=open(p,'rb').read().replace(b'\r\n',b'\n');open(p,'wb').write(b)" <path>`. Stage only these paths (LESSONS 2026-11-06: never stage `.import` files by pattern).

- [ ] **Step 6: Run the tests.** Refresh the copy. `-- --only=harold_art` (expect `harold art strips present: N` with N the count you cut), `-- --only=harold_anims`, `-- --only=eras`, `-- --only=grandpa_look`, `-- --only=outfit`.

- [ ] **Step 7: Look once.** With the user not playing, run `tools/probes/harold_look.gd` the way its header says (in the renamed copy, never the worktree), extended if needed to shoot hurt, death and dodge for `grandpa` and every era's idle, attack and dodge by holding him still and calling `_visual.play_once` (LESSONS 2026-11-07). Check feet stay on one row and nothing reads as a cross at 1x. Shots go to `D:\grandpa-shots\player-build\`.

- [ ] **Step 8: Commit.** `git ls-files --eol tools/art/harold_anims.py art/sprites/harold_1962 art/sprites/harold_1988` (text files `i/lf`; PNGs show `-text`). `git commit -m "Add Harold's hurt, death and dodge strips and the two new eras' art" -m "Co-Authored-By: Claude <noreply@anthropic.com>"`

---

### Task 7: Control tips during the first run

**Files:**
- Create: `scripts/core/first_run_tips.gd`, `scripts/ui/tip_coach.gd`
- Modify: `scripts/core/progress_data.gd`, `scripts/autoload/progress.gd`, `scripts/ui/hud.gd`, `scripts/scenes/floor_scene.gd`, `scripts/ui/options_panel.gd`
- Test: create `tests/test_first_run_tips.gd`

**Interfaces:**
- Consumes: `KeyBindings.with_device(action, text, pad, family)`, `KeyBindings.label_for(action)`, `ActiveDevice.using_pad`, `ActiveDevice.family`, `RuleKeeper.watch_of(id)`, `RuleKeeper.current_id`, `RuleKeeper.era_started`, `RuleWatch.is_open()`, `Hud.rule_announcing()`, `RoomView.is_fighting()`, `RoomLayout.TYPE_*`, Player signals `swing_started`, `dodge_started`, `teeth_thrown`, `swing_landed(heavy, finisher)`, `swing_missed(heavy)`, `potion_drunk(potion)`, `bomb_requested(at)`, `RunState.potion`, `RunState.bombs`, `RunState.held_reel`, `RunState.health.pills`, `RunState.stats.max_pills`, `Progress.is_dev_run()`.
- Produces: `FirstRunTips`, `ProgressData.tips_done` / `mark_tip` / `reset_tips`, `Progress.mark_tip_done` / `reset_tips`, `Hud.show_tip` / `clear_tip` / `tip_text` / `TIP_RECT`, `TipCoach`.

Old tests: `grep -rn "to_dict()\|from_dict" tests | grep -i progress` and check none compares the full key list (adding `tips_done` must not break them). `CoachTips` and `test_training_yard.gd` are untouched. `tests/test_options_source.gd` pins some options source lines: read it and keep them.

- [ ] **Step 1: Write the failing tests** (`tests/test_first_run_tips.gd`):

```gdscript
extends TestCase


func _facts(over := {}) -> Dictionary:
	var f := {"fighting": false, "room_type": RoomLayout.TYPE_COMBAT, "rule_on": false, "announcing": false,
		"has_reel": false, "has_potion": false, "hurt": false, "has_bomb": false, "swings": 0, "cleared_one": false}
	f.merge(over, true)
	return f


func test_the_first_tip_is_walking() -> void:
	assert_eq(FirstRunTips.next_tip({}, _facts()), FirstRunTips.MOVE)


func test_a_fight_teaches_swing_then_dodge_then_throw() -> void:
	var done := {FirstRunTips.MOVE: true}
	assert_eq(FirstRunTips.next_tip(done, _facts({"fighting": true})), FirstRunTips.SWING)
	done[FirstRunTips.SWING] = true
	assert_eq(FirstRunTips.next_tip(done, _facts({"fighting": true})), FirstRunTips.DODGE)
	done[FirstRunTips.DODGE] = true
	assert_eq(FirstRunTips.next_tip(done, _facts({"fighting": true})), FirstRunTips.THROW)
	done[FirstRunTips.THROW] = true
	assert_eq(FirstRunTips.next_tip(done, _facts({"fighting": true, "swings": 3})), "", "charge waits for a few swings")
	assert_eq(FirstRunTips.next_tip(done, _facts({"fighting": true, "swings": 4})), FirstRunTips.CHARGE)


func test_the_rule_and_the_reel_come_first_when_they_happen() -> void:
	assert_eq(FirstRunTips.next_tip({}, _facts({"rule_on": true, "fighting": true})), FirstRunTips.RULE)
	assert_eq(FirstRunTips.next_tip({}, _facts({"rule_on": true, "announcing": true})), FirstRunTips.MOVE, "not over the notice")
	assert_eq(FirstRunTips.next_tip({}, _facts({"has_reel": true})), FirstRunTips.REEL)
	assert_eq(FirstRunTips.next_tip({}, _facts({"has_reel": true, "fighting": true})), FirstRunTips.MOVE, "a reel is used at a door, not mid-fight")


func test_the_rest_wait_for_their_moment() -> void:
	var basics := {}
	for id in [FirstRunTips.MOVE, FirstRunTips.SWING, FirstRunTips.DODGE, FirstRunTips.THROW, FirstRunTips.CHARGE]:
		basics[id] = true
	assert_eq(FirstRunTips.next_tip(basics, _facts()), "")
	assert_eq(FirstRunTips.next_tip(basics, _facts({"has_potion": true})), "", "a potion at full pills waits")
	assert_eq(FirstRunTips.next_tip(basics, _facts({"has_potion": true, "hurt": true})), FirstRunTips.POTION)
	assert_eq(FirstRunTips.next_tip(basics, _facts({"room_type": RoomLayout.TYPE_ITEM})), FirstRunTips.INTERACT)
	assert_eq(FirstRunTips.next_tip(basics, _facts({"has_bomb": true, "cleared_one": true})), FirstRunTips.THERMOS)
	basics[FirstRunTips.THERMOS] = true
	assert_eq(FirstRunTips.next_tip(basics, _facts({"cleared_one": true})), FirstRunTips.MAP)
	assert_eq(FirstRunTips.next_tip(basics, _facts({"cleared_one": true, "fighting": true})), "")


func test_every_done_tip_stays_quiet() -> void:
	var all := {}
	for id in FirstRunTips.ORDER:
		all[id] = true
	var busy := _facts({"fighting": true, "rule_on": true, "has_reel": true, "has_potion": true, "hurt": true,
		"has_bomb": true, "swings": 9, "cleared_one": true, "room_type": RoomLayout.TYPE_SHOP})
	assert_eq(FirstRunTips.next_tip(all, busy), "")


func test_every_tip_has_text_naming_its_key() -> void:
	for id in FirstRunTips.ORDER:
		var text := FirstRunTips.text_for(id, false, "")
		assert_false(text.is_empty(), id)
		var action: String = FirstRunTips.ACTIONS.get(id, "")
		if not action.is_empty():
			assert_true(text.begins_with(KeyBindings.label_for(action) + ": "), "%s: %s" % [id, text])
	assert_true(FirstRunTips.text_for(FirstRunTips.MOVE, false, "").ends_with(": Walk"))


func test_a_new_save_has_no_tips_done_and_an_old_one_has_them_all() -> void:
	assert_true(ProgressData.new().tips_done.is_empty())
	var fresh := ProgressData.new().to_dict()
	assert_true(ProgressData.from_dict(fresh).tips_done.is_empty(), "a new save made by this build")
	var old := ProgressData.new().to_dict()
	old.erase("tips_done")
	old["run_count"] = 3
	var loaded := ProgressData.from_dict(old)
	for id in FirstRunTips.ORDER:
		assert_true(loaded.tips_done.has(id), id)
	old["run_count"] = 0
	assert_true(ProgressData.from_dict(old).tips_done.is_empty(), "an old save never played still learns")


func test_marking_and_resetting() -> void:
	var data := ProgressData.new()
	assert_true(data.mark_tip(FirstRunTips.DODGE))
	assert_false(data.mark_tip(FirstRunTips.DODGE), "once")
	assert_false(data.mark_tip("no_such_tip"))
	assert_true(ProgressData.from_dict(data.to_dict()).tips_done.has(FirstRunTips.DODGE))
	data.reset_tips()
	assert_true(data.tips_done.is_empty())


func test_the_hud_shows_one_tip() -> void:
	var hud := Hud.new()
	hud.setup(ItemKit.new().make_run())
	hud._ready()
	assert_eq(hud.tip_text(), "")
	hud.show_tip("Space: Dodge.")
	assert_eq(hud.tip_text(), "Space: Dodge.")
	hud.clear_tip()
	assert_eq(hud.tip_text(), "")
	assert_false(Hud.TIP_RECT.intersects(Rect2(Vector2.ZERO, Vector2(640, Hud.BAND_BOTTOM))), "clear of the top band")
	hud.free()


func test_the_coach_marks_what_he_does() -> void:
	var run := ItemKit.new().make_run()
	var player := Player.new()
	player.setup(run)
	var coach := TipCoach.new()
	var marked: Array[String] = []
	coach.mark = func(id: String) -> void: marked.append(id)
	coach.setup(player, null, run, null)
	player.dodge_started.emit()
	player.teeth_thrown.emit()
	player.swing_landed.emit(true, false)
	assert_eq(marked, [FirstRunTips.DODGE, FirstRunTips.THROW, FirstRunTips.CHARGE] as Array[String])
	player.swing_landed.emit(false, false)
	assert_eq(marked.size(), 3, "a plain swing is not a charge")
	coach.free()
	player.free()
```

(The lambda in the last test captures a local array, not `self`, so it makes no cycle. `TipCoach.mark` is empty by default; the scene sets it to `Progress.mark_tip_done`.)

- [ ] **Step 2: Run and see them fail.** `-- --only=first_run_tips`.

- [ ] **Step 3: Implement `scripts/core/first_run_tips.gd`.**

```gdscript
class_name FirstRunTips
extends RefCounted

# The control tips of a save's first run: one at a time, each when it is needed, each done once per save
# (ProgressData.tips_done). Text reuses Coach Bertram's first-visit lines where they fit (CoachTips).

const RULE := "rule"
const REEL := "reel"
const MOVE := "move"
const SWING := "swing"
const DODGE := "dodge"
const THROW := "throw"
const CHARGE := "charge"
const POTION := "potion"
const INTERACT := "interact"
const THERMOS := "thermos"
const MAP := "map"
# The first that applies shows. The rule and the reel come first: they are over soon.
const ORDER: Array[String] = [RULE, REEL, MOVE, SWING, DODGE, THROW, CHARGE, POTION, INTERACT, THERMOS, MAP]
const CHARGE_AFTER_SWINGS := 4
const QUIET_ROOMS: Array[String] = [RoomLayout.TYPE_ITEM, RoomLayout.TYPE_SHOP, RoomLayout.TYPE_TREASURE]
# The button each tip names ("" for none; MOVE names the four walk keys).
const ACTIONS := {
	REEL: "flashback", SWING: "attack", DODGE: "dodge", THROW: "throw", CHARGE: "attack", POTION: "potion",
	INTERACT: "interact", THERMOS: "bomb", MAP: "map",
}
const TEXTS := {
	RULE: "Keep the room's rule for a film reel. Break it and the Auditor comes.",
	REEL: "At a door to a new fight: relive a memory.",
	MOVE: "Walk",
	SWING: "Swing the cane. Three swings make a combo.",
	DODGE: "Dodge. It's not running away. It's tactical.",
	THROW: "Throw the teeth. They come back. Usually.",
	CHARGE: "Hold to charge a big swing.",
	POTION: "Drink your potion.",
	INTERACT: "Pick up, open, talk.",
	THERMOS: "Put down a Thermos. It blows up rocks and cracked walls.",
	MAP: "Open the map.",
}
const PAD_MOVE := "Left stick"


# facts: fighting, room_type, rule_on, announcing, has_reel, has_potion, hurt, has_bomb, swings, cleared_one.
static func next_tip(done: Dictionary, facts: Dictionary) -> String:
	for id in ORDER:
		if not done.has(id) and _applies(id, done, facts):
			return id
	return ""


static func _applies(id: String, done: Dictionary, facts: Dictionary) -> bool:
	var fighting: bool = facts.get("fighting", false)
	match id:
		RULE:
			return facts.get("rule_on", false) and not facts.get("announcing", false)
		REEL:
			return facts.get("has_reel", false) and not fighting
		MOVE:
			return true
		SWING:
			return fighting
		DODGE:
			return fighting and done.has(SWING)
		THROW:
			return fighting and done.has(DODGE)
		CHARGE:
			return fighting and int(facts.get("swings", 0)) >= CHARGE_AFTER_SWINGS
		POTION:
			return facts.get("has_potion", false) and facts.get("hurt", false)
		INTERACT:
			return QUIET_ROOMS.has(str(facts.get("room_type", "")))
		THERMOS:
			return facts.get("has_bomb", false) and not fighting and facts.get("cleared_one", false)
		MAP:
			return facts.get("cleared_one", false) and not fighting
	return false


# The line for a tip, naming the bound key or pad button as every prompt does.
static func text_for(id: String, pad: bool, family: String) -> String:
	var text: String = TEXTS.get(id, "")
	if text.is_empty():
		return ""
	if id == MOVE:
		var keys := PAD_MOVE if pad else "%s%s%s%s" % [KeyBindings.label_for("move_up"), KeyBindings.label_for("move_left"), KeyBindings.label_for("move_down"), KeyBindings.label_for("move_right")]
		return "%s: %s" % [tr_static(keys), tr_static(text)]
	var action: String = ACTIONS.get(id, "")
	if action.is_empty():
		return tr_static(text)
	return KeyBindings.with_device(action, tr_static(text), pad, family)


# tr() outside a node: TranslationServer, as menus do for static text.
static func tr_static(text: String) -> String:
	return TranslationServer.translate(text)
```

(`var keys := PAD_MOVE if pad else "%s..." % [...]` is String on both sides; if the parser refuses, type it `var keys: String`.)

- [ ] **Step 4: Profile fields.** In `progress_data.gd` add under `eras_unlocked`:

```gdscript
# The first run's control tips done (FirstRunTips ids). A save older than this field that has played a
# run counts them all done.
var tips_done: Dictionary = {}
```

`to_dict()` gains `"tips_done": tips_done.duplicate(),`. `from_dict` gains, beside the eras line:

```gdscript
	# Control tips: an older save that has played a run is past them.
	if raw.has("tips_done"):
		for id in _id_set(raw.get("tips_done")):
			if FirstRunTips.ORDER.has(id):
				data.tips_done[id] = true
	elif data.run_count > 0:
		for id in FirstRunTips.ORDER:
			data.tips_done[id] = true
```

(Place it after `data.run_count` is read.) And:

```gdscript
func mark_tip(id: String) -> bool:
	if tips_done.has(id) or not FirstRunTips.ORDER.has(id):
		return false
	tips_done[id] = true
	return true


func reset_tips() -> void:
	tips_done.clear()
```

`progress.gd` (beside `mark_coach_met`):

```gdscript
func mark_tip_done(id: String) -> void:
	if data != null and data.mark_tip(id):
		_store.save_progress(data)


func reset_tips() -> void:
	if data == null:
		return
	data.reset_tips()
	_store.save_progress(data)
```

(Check how a dev run's data is held: `mark_tip_done` must not save into a real slot during a dev run; follow what `mark_coach_met` does in a dev run.)

- [ ] **Step 5: The HUD tip line.** In `hud.gd`:

```gdscript
# The first run's control tip: one line, bottom centre, above the boss bar's name.
const TIP_RECT := Rect2(120, 292, 400, 16)
const TIP_FONT := 8

var _tip: Label


func show_tip(text: String) -> void:
	if _tip != null:
		_tip.text = text


func clear_tip() -> void:
	show_tip("")


func tip_text() -> String:
	return _tip.text if _tip != null else ""
```

and in `_ready` build `_tip` the way `_notice` is built (same font colour and outline), at `TIP_RECT`, centred, `mouse_filter = IGNORE`, font size `TIP_FONT`. Check in `tests/test_art_direction.gd` which HUD rects must stay clear of each other and of the door openings, and that `TIP_RECT` passes them (bottom door openings: see `DoorOpening.HALF_WIDTH`; if it overlaps a south door's opening, raise it to y 280).

- [ ] **Step 6: `scripts/ui/tip_coach.gd`.**

```gdscript
class_name TipCoach
extends Node

# Shows the first run's control tips (FirstRunTips) on the HUD and marks each done the moment he does
# the thing, whether or not its tip was showing. Polls map and interact in _process, since the full loop
# presses actions without events.

const MOVE_TIME := 0.6
const MOVING_SPEED := 4.0

# Set by FloorScene to Progress.mark_tip_done; empty in tests, so nothing is saved.
var mark := Callable()
var done: Dictionary = {}
var _player: Player
var _hud: Hud
var _run: RunState
var _rules: RuleKeeper
var _view: RoomView
var _room_type := ""
var _swings := 0
var _moved := 0.0
var _cleared_one := false
var _was_fighting := false
var _shown := ""
var _rule_room := -1


func setup(player: Player, hud: Hud, run: RunState, rules: RuleKeeper) -> void:
	_player = player
	_hud = hud
	_run = run
	_rules = rules
	player.swing_started.connect(_on_swing)
	player.dodge_started.connect(note_done.bind(FirstRunTips.DODGE))
	player.teeth_thrown.connect(note_done.bind(FirstRunTips.THROW))
	player.swing_landed.connect(_on_swing_ended)
	player.swing_missed.connect(_on_swing_missed)
	player.potion_drunk.connect(_on_potion)
	player.bomb_requested.connect(_on_bomb)
	if rules != null:
		rules.era_started.connect(_on_era)


func set_room(view: RoomView, room_type: String) -> void:
	_view = view
	_room_type = room_type


func note_done(id: String) -> void:
	if done.has(id):
		return
	done[id] = true
	if mark.is_valid():
		mark.call(id)
	if _shown == id and _hud != null:
		_shown = ""
		_hud.clear_tip()


func _on_swing() -> void:
	_swings += 1
	note_done(FirstRunTips.SWING)


func _on_swing_ended(heavy: bool, _finisher: bool) -> void:
	if heavy:
		note_done(FirstRunTips.CHARGE)


func _on_swing_missed(heavy: bool) -> void:
	if heavy:
		note_done(FirstRunTips.CHARGE)


func _on_potion(_potion: PotionDef) -> void:
	note_done(FirstRunTips.POTION)


func _on_bomb(_at: Vector2) -> void:
	note_done(FirstRunTips.THERMOS)


func _on_era(_era: String) -> void:
	note_done(FirstRunTips.REEL)


func facts() -> Dictionary:
	var fighting := _view != null and is_instance_valid(_view) and _view.is_fighting()
	var watch: RuleWatch = _rules.watch_of(_rules.current_id) if _rules != null else null
	return {
		"fighting": fighting,
		"room_type": _room_type,
		"rule_on": watch != null and watch.is_open() and fighting,
		"announcing": _hud != null and _hud.rule_announcing(),
		"has_reel": _run != null and not _run.held_reel.is_empty(),
		"has_potion": _run != null and _run.potion != null,
		"hurt": _run != null and _run.health.pills < _run.stats.max_pills,
		"has_bomb": _run != null and _run.bombs > 0,
		"swings": _swings,
		"cleared_one": _cleared_one,
	}


func _process(delta: float) -> void:
	if _player == null or _hud == null:
		return
	if _player.velocity.length() >= MOVING_SPEED:
		_moved += delta
		if _moved >= MOVE_TIME:
			note_done(FirstRunTips.MOVE)
	if Input.is_action_just_pressed("map"):
		note_done(FirstRunTips.MAP)
	if Input.is_action_just_pressed("interact"):
		note_done(FirstRunTips.INTERACT)
	var now := facts()
	var fighting: bool = now["fighting"]
	if _was_fighting and not fighting:
		_cleared_one = true
	_was_fighting = fighting
	# The rule tip is done once the room it was shown in stops posting its rule.
	if _shown == FirstRunTips.RULE and not now["rule_on"] and not now["announcing"]:
		note_done(FirstRunTips.RULE)
	var next := FirstRunTips.next_tip(done, now)
	if next != _shown:
		_shown = next
		_hud.show_tip(FirstRunTips.text_for(next, ActiveDevice.using_pad, ActiveDevice.family) if not next.is_empty() else "")
```

(`TipCoach` names no autoload, so tests load it; FloorScene sets `mark`. Check `RunState.health.pills` and `stats.max_pills` names in `run_state.gd` / `health.gd`.)

- [ ] **Step 7: Wire the floor scene.** In `floor_scene.gd` `_ready`, after `_rules.setup(...)`:

```gdscript
	# A save's first run teaches its controls on the spot (none in a dev run).
	if not Progress.is_dev_run() and Progress.data.tips_done.size() < FirstRunTips.ORDER.size():
		_tips = TipCoach.new()
		_tips.mark = Progress.mark_tip_done
		_tips.done = Progress.data.tips_done.duplicate()
		_tips.setup(player, _hud, _run, _rules)
		add_child(_tips)
```

with `var _tips: TipCoach` among the members. Where the scene calls `_rules.on_room_entered(_room_view, _map.room(target_id), first_visit)` (around line 573), also call `if _tips != null: _tips.set_room(_room_view, _map.room(target_id).room_type)`, and do the same for the first room the run starts in (find where the start room view is made). In `_end_run`, `if _tips != null: _tips.process_mode = Node.PROCESS_MODE_DISABLED` and `_hud.clear_tip()`.

- [ ] **Step 8: The Options button.** In `options_panel.gd::_show_tab`, after the GAME rows are built (`for key in TAB_KEYS[tab]` loop), when `tab == GameSettings.GAME` add one button row:

```gdscript
const SHOW_TIPS_TEXT := "Show control tips again"
const TIPS_RESET_TEXT := "Tips will show again"
```

The button uses the panel's existing button style (copy how `_build_row` makes a focusable Button), text `tr(SHOW_TIPS_TEXT)`, disabled when `Progress.data == null`; on press it calls `Progress.reset_tips()`, sets its text to `tr(TIPS_RESET_TEXT)` and disables itself. Check the Game tab's rows still fit the paper (count ROW_HEIGHT x rows against the paper's height in `options_panel.gd`; if 11 rows overflow, put the button beside the tab's Reset button instead). Pad focus: the new button joins the focus chain like the rows.

- [ ] **Step 9: Run and see them pass.** `-- --only=first_run_tips`, `-- --only=progress`, `-- --only=options`, `-- --only=hud`, `-- --only=art_direction`, `-- --only=training_yard`, then the full suite.

- [ ] **Step 10: Commit.** `git ls-files --eol scripts/core/first_run_tips.gd scripts/ui/tip_coach.gd tests/test_first_run_tips.gd` (expect `i/lf`; add the two `.uid` files from the copy). `git commit -m "Teach the controls during a new save's first run" -m "Co-Authored-By: Claude <noreply@anthropic.com>"`

---

### Task 8: The full loop and the bot with rules on every floor

**Files:**
- Modify: `tools/smoke_driver.gd`, `scripts/world/rule_keeper.gd` (`lift_rule`), possibly `tools/probes/bot_probe.gd`
- Test: `tests/test_rule_keeper.gd`

**Interfaces:**
- Consumes: `FloorScene.debug_rules() -> RuleKeeper`, `FloorScene.debug_current_id()`, `RoomView.AUDIT_DELAY`, `RuleKeeper.watch_of(id)`, `RuleKeeper._rule_rooms`.
- Produces: `RuleKeeper.lift_rule(room_id: int)`.

Today the loop never meets a rule outside floor 1. `_clear_room` kills every enemy at once (`take_damage(INF, ...)`), and its own checks press attack, dodge, throw and Thermos in many rooms. With rules on every floor, a check that presses a forbidden button in a rule room calls an Auditor 2 s later (into a room the loop thinks is clear), the 1.5 s announcement holds enemies a timing check measures, and the Auditor's Pension lands inside an exact Pension count.

- [ ] **Step 1: Write the failing test** (append to `tests/test_rule_keeper.gd`):

```gdscript
# The full loop's way to quiet a room it measures: the rule goes, nothing counts, no Auditor comes.
func test_a_lifted_rule_is_gone() -> void:
	var keeper := RuleKeeper.new()
	keeper.set_watch(4, RuleWatch.new(RoomRule.NO_HORSEPLAY))
	keeper.current_id = 4
	var calls: Array = []
	keeper.rule_broken.connect(func(_view): calls.append(1))
	keeper.lift_rule(4)
	assert_true(keeper.watch_of(4) == null)
	keeper.report(RoomRule.ACTION_DODGE)
	assert_eq(calls.size(), 0)
	keeper.free()
```

- [ ] **Step 2: Run and see it fail.** `-- --only=rule_keeper`.

- [ ] **Step 3: Implement `lift_rule`** in `rule_keeper.gd`:

```gdscript
# The full loop's checks measure rooms exactly, so it lifts a room's rule before pressing anything there.
func lift_rule(room_id: int) -> void:
	_watches.erase(room_id)
	_rule_rooms.erase(room_id)
	if room_id == current_id and _hud != null:
		_hud.clear_rule()
```

- [ ] **Step 4: Run the full loop once as it is** (refresh the copy; nobody playing): `powershell -File $COPY\tools\smoke.ps1`. Save the output to `D:\grandpa-verify\player-loop-1.txt`. Read every `FAIL` line and the depth it came at.

- [ ] **Step 5: Teach the driver.** In `tools/smoke_driver.gd`:
  - Add a helper and call it at the start of every check that presses a game action or counts Pension, damage or time inside a room (grep the driver for `action_press`, `_wait(`, `pension ==`, `hp ==`; the depth-specific `_check_*_fights` functions, `_check_fight_room`, `_check_props_room`, `_check_contact`, `_walk_back_and_return`, the potion and Thermos checks):

```gdscript
# Rules post on every floor: a check that presses buttons or counts exactly lifts the room's rule first,
# so no Auditor walks into a room it measures. One check below (_check_rules_deeper) keeps a rule.
func _quiet_rules(scene: Node) -> void:
	scene.debug_rules().lift_rule(scene.debug_current_id())
```

  - In `_clear_room`, before killing the enemies, call `_quiet_rules(scene)`; after the kill, if the view still reports fighting (an Auditor already on his way), wait `RoomView.AUDIT_DELAY + 0.3` s and kill again, up to 3 times, and `_check` the room cleared.
  - Add one check that the hook is there deeper, called once from `_clear_whole_floor` at depth 2:

```gdscript
func _check_rules_deeper(scene: Node) -> void:
	var keeper: RuleKeeper = scene.debug_rules()
	_check(keeper._rule_rooms.size() >= 1, "depth %d posts rules, got %s" % [scene.debug_depth(), str(keeper._rule_rooms)])
	for id in keeper._rule_rooms:
		_check(scene.debug_map().room(id).room_type == RoomLayout.TYPE_COMBAT, "a rule room is a combat room")
```

  - Read how the loop's save is made (`Progress.data.run_count`): if it is a first run, the early rule room lands in the first fights, where the loop's first checks run; `_quiet_rules` covers that.
  - Tips: the loop's save is new, so `TipCoach` runs. Check no loop check reads the HUD text the tip line shares (it has its own label), and that `Progress.mark_tip_done` saving into the loop's temporary save changes no Pension or save check. If one does, mark every tip done in the loop's save at start (`for id in FirstRunTips.ORDER: Progress.data.mark_tip(id)`) and say so in a comment.
  - Attack warnings are now on by default in the copy (no settings file): if a check expected them off, set `AttackWarnings.shown` explicitly in that check and restore it, as `test_hidden_cues.gd` does.
  - Harold's death wait (`death_anim_time`) adds up to 0.9 s before the death message: if a check reads the message after a fixed wait, add `player.death_anim_time()` to it.

- [ ] **Step 6: Run the full loop until it passes, three times in a row** (LESSONS 2026-11-02: new checks can fail one run in five). `SMOKE PASS` each time.

- [ ] **Step 7: The bot.** With nobody playing, one batch: `powershell -File tools/probes/run_bot.ps1` as its header says, case `fresh average 4 0 1 eras` in its own export copy (LESSONS 2026-11-09: read the case's first two words against SAVES and SKILLS). Expect no SCRIPT ERROR, a SUMMARY line, rules met on depth 2 if reached, and `era_dps` above `old_dps`. Record the era_dps per era if the summary gives it; if an era is more than 30% above or below old Harold in play, report the numbers (do not retune in this task).

- [ ] **Step 8: Commit.** `git commit -m "Keep the full loop exact with rules on every floor" -m "Co-Authored-By: Claude <noreply@anthropic.com>"`

---

### Task 9: The player build

The controller merges `jukebox-music` (music renderer and docs only) and the finished `new-items` into `player-build` first. This task checks the merged branch and builds the zip. The real exported `Grandpa.exe` is never started by an agent.

**Files:**
- Create: `tools/probes/build_walk.gd`, `tools/probes/build_walk.ps1`
- Modify: `LESSONS.md` (anything learned), `docs/release/build-steps.md` (only if a step proved wrong)

**Interfaces:**
- Consumes: everything above; `docs/release/build-steps.md`; `tools/music/render_band.py`; `tools/stamp_build.ps1`; `tools/probes/window_look.ps1` (pattern for adding an autoload to a renamed copy).
- Produces: `D:\grandpa-build\Grandpa-<commit>.zip`.

- [ ] **Step 1: Check the merges.** `git log --oneline -5`, `git status` (clean). Conflicts the controller resolved in `rule_keeper.gd`, `floor_scene.gd`, `run_state.gd`, `player.gd`, `smoke_driver.gd`: read each merged hunk against both sides (new-items' e8c307a gates item hooks in the loop; keep both). Then `grep -rn "ENABLED_DEPTH" scripts tests tools` (only `rule_picker.gd` defines it; `run_state.gd::rules_posted` reads it), `grep -rn "Eras.STARTING\|FOOTBALL_TINT\|BUS_TINT" scripts tests tools` (no tint constants left), and check every new `.gd` has its `.gd.uid` tracked (`git ls-files scripts | grep -c "\.gd$"` against `"\.gd\.uid$"` for the new files).

- [ ] **Step 2: Full suite and full loop in the renamed copy.** Refresh the copy from `HEAD`. Full suite: "N tests, 0 failed". Full loop: `SMOKE PASS` twice in a row. One bot batch as Task 8 Step 7. Any failure: stop, fix in the task it belongs to (with its test), commit, repeat.

- [ ] **Step 3: Archive, music, stamp** (docs/release/build-steps.md steps 1-3), from PowerShell in the worktree:

```powershell
git tag playtest-1
Remove-Item -Recurse -Force D:\grandpa-build\src -ErrorAction SilentlyContinue
git archive --format=zip -o D:\grandpa-build\src.zip HEAD
Expand-Archive D:\grandpa-build\src.zip D:\grandpa-build\src
py tools/music/render_band.py D:\grandpa-build\src\audio\music
powershell -File tools/stamp_build.ps1 -Out D:\grandpa-build\src
```

Every render check line ends in `ok` and the folder holds 24 songs. (Ask the controller before tagging if `playtest-1` exists.)

- [ ] **Step 4: Import and export without touching the real user folder.** The build copy keeps `config/name="Grandpa"` (players' saves go there), so Godot's own logs would land in `%APPDATA%\Godot\app_userdata\Grandpa\`. Point `APPDATA` elsewhere for these two runs, with the export templates joined in:

```powershell
$real = Join-Path $env:APPDATA "Godot"
$before = Get-ChildItem -Recurse (Join-Path $real "app_userdata\Grandpa") -ErrorAction SilentlyContinue | Select-Object FullName, LastWriteTime, Length | Out-String
New-Item -ItemType Directory -Force D:\grandpa-build\appdata\Godot | Out-Null
if (-not (Test-Path D:\grandpa-build\appdata\Godot\export_templates)) { New-Item -ItemType Junction -Path D:\grandpa-build\appdata\Godot\export_templates -Target (Join-Path $real "export_templates") | Out-Null }
$env:APPDATA = "D:\grandpa-build\appdata"
& $GODOT --headless --path D:\grandpa-build\src --import
& $GODOT --headless --path D:\grandpa-build\src --export-release "Windows Desktop" D:\grandpa-build\Grandpa.exe
$env:APPDATA = Split-Path $real
$after = Get-ChildItem -Recurse (Join-Path $real "app_userdata\Grandpa") -ErrorAction SilentlyContinue | Select-Object FullName, LastWriteTime, Length | Out-String
if ($before -ne $after) { "REAL USER FOLDER CHANGED: stop and report" } else { "user folder untouched" }
```

If the export cannot find its templates or the folder changed, stop and report; do not retry against the real `APPDATA`. Zip `Grandpa.exe` alone as `D:\grandpa-build\Grandpa-<commit>.zip`.

- [ ] **Step 5: The walk probe.** Create `tools/probes/build_walk.gd` (an autoload in a renamed copy only; never the worktree):

```gdscript
extends Node
# Walks an exported, renamed copy of the build: the title, the opening (skipped with one press), the
# lobby and the first rooms of a run, and checks each draws (the frame is not one flat colour) and that
# music plays. Shots to D:/grandpa-shots/player-build/. Quits when done. Run by build_walk.ps1.

const OUT := "D:/grandpa-shots/player-build/"
var _lines: PackedStringArray = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_walk.call_deferred()


func _walk() -> void:
	await _seconds(3.0)
	_shot("title")
	_press("ui_accept")
	await _seconds(2.0)
	_shot("opening")
	_press("pause")
	await _seconds(3.0)
	_shot("lobby")
	_line("MUSIC %s" % ("on" if MusicPlayer.is_playing() else "OFF"))
	Game.begin_run()
	await _seconds(4.0)
	_shot("first_room")
	_line("SCENE %s" % get_tree().current_scene.name)
	_line("MUSIC %s" % ("on" if MusicPlayer.is_playing() else "OFF"))
	FileAccess.open(OUT + "walk.txt", FileAccess.WRITE).store_string("\n".join(_lines))
	get_tree().quit()


func _press(action: String) -> void:
	Input.action_press(action)
	await get_tree().process_frame
	Input.action_release(action)


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png(OUT + name + ".png")
	var first := image.get_pixel(0, 0)
	var flat := true
	for i in 64:
		if not image.get_pixel(int(image.get_width() * (i % 8 + 0.5) / 8.0), int(image.get_height() * (i / 8 + 0.5) / 8.0)).is_equal_approx(first):
			flat = false
			break
	_line("SHOT %s %s" % [name, "drawn" if not flat else "FLAT"])


func _line(text: String) -> void:
	print("WALK " + text)
	_lines.append(text)
```

Read first how the title moves on (a slot choice may come before the opening: follow `tools/probes/title_look.gd`), what `MusicPlayer` offers for "is playing" (use what exists), and whether the opening plays on a new save (it does when `opening_seen` is false). The opening reads `_unhandled_input`, which `Input.action_press` never reaches (LESSONS 2026-11-03): send a real `InputEventAction` with `Input.parse_input_event` for the opening's press instead.

`tools/probes/build_walk.ps1`: like `window_look.ps1`, but on `D:\grandpa-build\walk`: copy `D:\grandpa-build\src` there (music and `build_info.txt` included), rename `config/name` to `GrandpaPlayerWalk` (refuse if it still reads `Grandpa`), add `BuildWalk="*res://tools/probes/build_walk.gd"` under `[autoload]`, import and export it to `D:\grandpa-build\walk\GrandpaPlayerWalk.exe` (its own name, so its user folder is its own), start that exe and wait up to 120 s, then print the `WALK` lines from `D:\grandpa-shots\player-build\walk.txt`.

- [ ] **Step 6: Walk it.** Check no windowed Godot or game runs (`Get-Process *godot*,Grandpa* -ErrorAction SilentlyContinue`). `powershell -File tools/probes/build_walk.ps1`. Expect every `SHOT ... drawn`, both `MUSIC on`, `SCENE FloorScene`. Look at the four shots: the title shows the build id in its corner (the stamped commit, not `dev`), the lobby and the first room have floor, walls and Harold (LESSONS 2026-11-10), and the first room shows the `move` tip line.

- [ ] **Step 7: Commit.** `git ls-files --eol tools/probes/build_walk.gd tools/probes/build_walk.ps1` (expect `i/lf`). `git commit -m "Add a walk probe for the exported player build" -m "Co-Authored-By: Claude <noreply@anthropic.com>"`. Report the zip's path, its commit, the walk lines and the bot's numbers.
