# Title Menu, Options, Save Slots and Run Checkpoint Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build stage 1 of `docs/superpowers/specs/2026-11-04-title-menu-options-saves-design.md`: its build-order
steps 1 to 4 (settings and Options, the title screen and pause menu, three save slots, the run checkpoint).
Step 5 (controller) is stage 2 and is left out, but the data is shaped so it can be added without migration.

**Architecture:** Pure rules live on core `RefCounted` classes that tests can call (`GameSettings`,
`SaveSlots`, `RunCheckpoint`, `TitleQueue` rules); the autoloads (`Settings`, `Progress`, `Game`) and
scene scripts only wire them up, since tests never load scripts that name autoloads (LESSONS 2026-11-04).
Panels are code-built `CanvasLayer`s with an opaque backing, as every other panel is.

**Tech Stack:** Godot 4.7.2, GDScript, `ConfigFile`, `JSON`, Control nodes, a canvas_item shader. No add-ons.

## Global Constraints

- Never name another game in any file, comment, asset name or commit message.
- No new dependencies. Settings use `ConfigFile`, menus use Control nodes.
- Every new save field is optional with a fallback. The player's current save survives unchanged into slot 1.
- Migration COPIES `user://save.json` and `.bak` into `user://slot_1/`; the originals are never moved or changed,
  and an existing `slot_1/save.json` is never overwritten.
- `--smoke` skips the title screen, keeps `user://smoke_save.json`, and never writes `settings.cfg`.
  Tests never write `settings.cfg` or slot folders in the real user folder (they use `OS.get_temp_dir()`).
- The screen is 640x360. Big overlays get an opaque backing; decorative full-screen Controls get
  `mouse_filter = IGNORE`; panels the full loop drives poll `Input.is_action_just_pressed` in `_process`.
- Every new menu string goes through `tr()`.
- Files keep CRLF line endings (convert Write-tool files before committing).
- Dev runs never write a checkpoint.

## File Structure

| File | Responsibility |
|---|---|
| `scripts/core/game_settings.gd` (new, `GameSettings`) | Defaults, load/save of `settings.cfg`, reset a tab, resolution list, adjustment numbers |
| `scripts/autoload/settings.gd` (new autoload `Settings`) | Holds the live `GameSettings`, applies video/audio, owns the adjustment layer and audio buses |
| `scripts/world/adjust_layer.gd` (new, `AdjustLayer`) | Full-screen shader layer for brightness/contrast/gamma |
| `scripts/ui/menu_style.gd` (new, `MenuStyle`) | Shared opaque backing, gold highlight bar, button factory |
| `scripts/ui/options_panel.gd` (new, `OptionsPanel`) | Video/Audio/Game/Input tabs, Defaults, OK, Esc with discard confirm |
| `scripts/core/key_bindings.gd` | `rebind` returns the action it swapped with; `save_to` keeps an optional `pad` key |
| `scripts/core/input_setup.gd` | Adds the `pause` action (Esc) |
| `scripts/world/combat_feedback.gd` | `shake_enabled`, `hit_stop_enabled`, players on the `Effects` bus |
| `scripts/actors/player.gd` | `mouse_aim` flag: off aims the way he last moved |
| `scripts/core/run_state.gd` | `heals_at_full` flag; checkpoint round trip helpers live in `RunCheckpoint` |
| `scripts/ui/hud.gd` | Optional run timer on the top row |
| `scripts/core/title_queue.gd` (new, `TitleQueue`) | The queue's ticking rules (now serving, shuffle step) |
| `scripts/ui/title_scene_art.gd` (new, `TitleSceneArt`) | Code-drawn Waiting Room queue |
| `scenes/title.tscn`, `scripts/scenes/title_screen.gd` (new) | Title menu, version, credits, slot picker host |
| `scripts/ui/credits_card.gd` (new, `CreditsCard`) | Scrolling credits |
| `scripts/ui/slot_picker.gd` (new, `SlotPicker`) | Three slot cards, new/load modes, overwrite/delete/abandon confirms |
| `scripts/ui/confirm_box.gd` (new, `ConfirmBox`) | A small yes/no box used by Options, the picker and pause |
| `scripts/ui/pause_menu.gd` (new, `PauseMenu`) | Resume, Options, Save and Quit to Title, Quit to Desktop |
| `scripts/core/save_slots.gd` (new, `SaveSlots`) | Slot paths, migration, summaries, delete, last used slot |
| `scripts/autoload/progress.gd` | `select_slot(n)`, slot-aware store, checkpoint read/write/clear, resume hand-off |
| `scripts/core/run_checkpoint.gd` (new, `RunCheckpoint`) | Versioned atomic file, RunState and map round trip, map signature |
| `scripts/world/room_view.gd` | Tags pickups and chests for the checkpoint, `snapshot()`, restore mode, `finished` signal |
| `scripts/scenes/floor_scene.gd` | Floor seed, checkpoint writes, resume, pause, minimap options, run timer |
| `scripts/scenes/waiting_room.gd` | Pause, Esc closes panels, Key Settings board opens Options on Input |
| `scripts/autoload/game.gd` | Title routing, `continue_game`, `resume_run`, `quit_to_title`, `abandon_run` |
| `tools/smoke_driver.gd` | Checkpoint written mid-floor resumes into the same room with the same RunState |
| `project.godot` | `config/version="0.5.0"`, `Settings` autoload first |

---

### Task 1: GameSettings storage

**Files:** Create `scripts/core/game_settings.gd`; Test `tests/test_game_settings.gd`

**Interfaces — Produces:**
- `const VIDEO := "video"`, `AUDIO := "audio"`, `GAME := "game"`, `INPUT := "input"`, `const DEFAULTS: Dictionary` (section -> key -> value)
- `func value(section: String, key: String) -> Variant`, `func set_value(section, key, v) -> void`
- `func reset_section(section: String) -> void`, `func duplicate_settings() -> GameSettings`, `func equals(other: GameSettings, section := "") -> bool`
- `func load_from(path: String) -> bool` (missing or damaged falls back to defaults, bad types and out-of-range values too), `func save_to(path: String) -> bool`
- `static func resolutions_for(screen: Vector2i) -> Array[Vector2i]` (whole multiples of 640x360 that fit, at least 640x360... list starts at 1280x720), `static func best_resolution(screen) -> Vector2i`
- `static func brightness_offset(v: int) -> float` (v/250), `static func contrast_factor(v) -> float` (1+v/100), `static func gamma_power(v) -> float` (2^(v/50)), `static func is_neutral(b, c, g) -> bool`
- `static func bus_db(percent: int) -> float` (0 -> -80, else linear_to_db)

- [ ] Step 1: tests — defaults match the spec table; round trip through a temp file in `OS.get_temp_dir()`; a damaged file and a missing file load as defaults; an out-of-range slider is clamped; `reset_section` resets only that section; resolutions for 1920x1080 are `[1280x720, 1920x1080]` with best 1920x1080, for 2560x1600 `[1280x720, 1920x1080, 2560x1440]`; neutral adjustment at 0/0/0.

```gdscript
func test_defaults_match_the_spec() -> void:
	var s := GameSettings.new()
	assert_eq(s.value(GameSettings.VIDEO, "brightness"), 0)
	assert_eq(s.value(GameSettings.VIDEO, "fullscreen"), true)
	assert_eq(s.value(GameSettings.AUDIO, "effects"), 80)
	assert_eq(s.value(GameSettings.GAME, "minimap_opacity"), 100)
	assert_eq(s.value(GameSettings.GAME, "heal_at_full"), false)
	assert_eq(s.value(GameSettings.GAME, "language"), "en")
```
- [ ] Step 2: run `powershell -File tools/test.ps1`, expect "could not load"/FAIL for test_game_settings.
- [ ] Step 3: implement `GameSettings` with ConfigFile; each default carries its kind (bool, int range, string choice) so loading validates.
- [ ] Step 4: tests pass. Step 5: commit "Add the game settings file and its defaults".

### Task 2: Settings autoload, adjustment layer and audio buses

**Files:** Create `scripts/autoload/settings.gd`, `scripts/world/adjust_layer.gd`; Modify `project.godot` (autoload `Settings` first, `config/version="0.5.0"`), `scripts/world/combat_feedback.gd`; Test `tests/test_adjust_layer.gd`, `tests/test_combat_feedback.gd`

**Interfaces — Produces:**
- `Settings.current: GameSettings`, `Settings.PATH := "user://settings.cfg"`, `signal changed`
- `Settings.apply(s: GameSettings) -> void` (live preview, no write), `Settings.commit(s) -> void` (apply + write unless smoke or script run)
- `Settings.cursor_mode(hidden: bool) -> Input.MouseMode` (confined variants when the option is on)
- `Settings.game(key) -> Variant` shortcut
- `AdjustLayer.set_levels(brightness: int, contrast: int, gamma: int)`; hidden when neutral; layer 128; `mouse_filter = IGNORE`
- `AudioBuses` handled inside Settings: `ensure_buses()` adds `Effects`, `Music`, `Ambience` sending to Master
- `CombatFeedback.shake_enabled := true`, `hit_stop_enabled := true`; `const BUS := "Effects"`

- [ ] Step 1: tests — `CombatFeedback` with `shake_enabled = false` reports `shake_magnitude() == 0` after a hurt; with `hit_stop_enabled = false` a landed swing leaves `Engine.time_scale == 1`; its players use the `Effects` bus name; the shader source in `AdjustLayer` exists and the layer hides at 0/0/0.
- [ ] Step 2: run, fail. Step 3: implement. Step 4: pass. Step 5: commit "Apply settings through an autoload, an adjustment layer and audio buses".

### Task 3: Game-tab options wired into play

**Files:** Modify `scripts/actors/player.gd`, `scripts/core/run_state.gd`, `scripts/world/room_view.gd`, `scripts/ui/hud.gd`, `scripts/scenes/floor_scene.gd`, `scripts/scenes/waiting_room.gd`; Test `tests/test_game_options.gd`

**Interfaces — Produces:**
- `Player.mouse_aim := true`; `static func move_aim_point(from: Vector2, last_move: Vector2) -> Vector2` (40 px ahead)
- `RunState.heals_at_full := false`; `RunState.can_take_heal() -> bool`
- `RoomView.is_fighting() -> bool`
- `Hud.show_timer := false`, `Hud.set_run_time(seconds: float)`, `static func timer_text(seconds) -> String` ("12:05", hours "1:02:03")
- `static FloorScene` rule on a core class: `GameSettings.minimap_visible(hide_in_combat: bool, fighting: bool, big_open: bool) -> bool`

- [ ] Step 1: tests for `move_aim_point`, `can_take_heal` both ways, `timer_text`, `minimap_visible`.
- [ ] Step 2–4: implement, wire in floor scene (`_apply_game_settings()` on ready and on `Settings.changed`), pass.
- [ ] Step 5: commit "Wire the Game options into play".

### Task 4: Options panel

**Files:** Create `scripts/ui/menu_style.gd`, `scripts/ui/confirm_box.gd`, `scripts/ui/options_panel.gd`; Modify `scripts/core/key_bindings.gd`, `scripts/core/input_setup.gd`; Test `tests/test_key_bindings.gd` (rebind returns the swapped action, `pad` key kept), `tests/test_options_source.gd` (source checks: four tabs, `tr(`, opaque backing)

**Interfaces — Produces:**
- `OptionsPanel.new()`, `setup(tab: String)`, `signal closed`; tabs `GameSettings.VIDEO/AUDIO/GAME/INPUT`
- Q/E switch tabs, Esc closes (confirm if changed), Defaults resets the open tab, OK commits all.
- `KeyBindings.rebind(action, event) -> String` (the swapped action or ""), `KeyBindings.PAD_KEY := "pad"`, `KeyBindings.snapshot() -> Dictionary`, `KeyBindings.restore(raw: Dictionary)`
- `InputSetup` adds `pause` (Esc); `KeyBindings.ACTIONS` lists it as "Pause / back".
- Input tab rows: label, keyboard/mouse button, controller cell showing `tr("coming")`.

- [ ] Steps: tests first (key bindings), implement, screenshot later at Task 10, commit "Add the Options panel".

### Task 5: Title screen, credits and pause menu

**Files:** Create `scripts/core/title_queue.gd`, `scripts/ui/title_scene_art.gd`, `scripts/scenes/title_screen.gd`, `scenes/title.tscn`, `scripts/ui/credits_card.gd`, `scripts/ui/pause_menu.gd`; Modify `scripts/autoload/game.gd`, `scripts/scenes/floor_scene.gd`, `scripts/scenes/waiting_room.gd`; Test `tests/test_title_queue.gd`

**Interfaces — Produces:**
- `TitleQueue.new(start_number: int)`, `tick(delta) -> bool` (true when it served), `now_serving: int`, `const SERVE_TIME := 3.0`, `step: int` (shuffles so far)
- `TitleScreen` menu items by `TitleScreen.menu_items(any_progress: bool, slots_with_progress: int) -> Array[String]`  (static, on `SaveSlots` so tests can reach it)
- `Game.start()` → title unless `--smoke`; `Game.quit_to_title()`; `Game.continue_game()`
- `PauseMenu.setup(in_run: bool)`, `signal resumed`, `signal save_quit(to_desktop: bool)`; `process_mode = ALWAYS`; tree paused while open.
- Esc order: open panel closes first (card table leave / big map closes / Waiting Room panel closes), else pause.

- [ ] Steps: tests for the queue rules and the menu item rule, implement, commit "Add the title screen, credits and pause menu".

### Task 6: Save slots and migration

**Files:** Create `scripts/core/save_slots.gd`; Modify `scripts/autoload/progress.gd`; Test `tests/test_save_slots.gd`

**Interfaces — Produces:**
- `SaveSlots.COUNT := 3`, `static func slot_dir(root: String, n: int) -> String` (`root + "slot_%d/"`), `save_path(root, n)`, `run_path(root, n)`
- `static func migrate(root: String) -> bool` — copies `root/save.json` and `.bak` into `slot_1/` byte for byte, never when `slot_1/save.json` exists, never touches the originals
- `static func summary(root, n) -> Dictionary` — `{"empty": bool, "floors": int, "deepest": int, "pension": int, "runs": int, "date": String, "run_floor": int}` (run_floor 0 = none)
- `static func summary_of(data: ProgressData) -> Dictionary`, `static func has_progress(data) -> bool`
- `static func delete_slot(root, n)`, `static func read_last(root) -> int` (1 when missing), `static func write_last(root, n)`
- `static func menu_items(slots_with_progress: int, last_has_progress: bool) -> Array[String]`
- `Progress.select_slot(n)`, `Progress.slot := 1`, `Progress.ROOT := "user://"`; smoke keeps `SMOKE_PATH`; dev keeps `DEV_PATH`; a `--script` run neither migrates nor writes.

- [ ] Step 1: tests in a temp folder: migration copies byte-identical files and leaves originals' MD5 unchanged; a second migration does not overwrite a changed slot_1; no source means nothing copied; summary of an empty slot; summary of a fixture save (`tests/fixtures/save_v1_2026-11-04.json`); delete; last slot round trip; menu items.
- [ ] Steps 2–5: fail, implement, pass, commit "Add three save slots with a copy-only migration".

### Task 7: Slot picker on the title screen

**Files:** Create `scripts/ui/slot_picker.gd`; Modify `scripts/scenes/title_screen.gd`, `scripts/autoload/game.gd`

**Interfaces — Produces:**
- `SlotPicker.setup(mode: String)` with `SlotPicker.MODE_NEW`/`MODE_LOAD`, `signal picked(slot: int, action: String)` (`"new"`, `"load"`, `"resume"`, `"abandon"`), `signal closed`
- `Game.new_game(slot)`, `Game.load_game(slot)`, `Game.abandon_and_load(slot)`
- Confirms: "Overwrite slot N? This can't be undone.", the same for Delete, "Abandon your run on Floor N?" with Resume / Abandon / Cancel.

- [ ] Steps: build, screenshot at Task 10, commit "Add the slot picker".

### Task 8: Run checkpoint file and round trip

**Files:** Create `scripts/core/run_checkpoint.gd`; Test `tests/test_run_checkpoint.gd`

**Interfaces — Produces:**
- `RunCheckpoint.VERSION := 1`; `static func write(path: String, data: Dictionary) -> bool` (to `path + ".tmp"`, then rename); `static func read(path) -> Dictionary` ({} when missing, damaged or another version); `static func delete(path)`
- `static func run_to_dict(run: RunState) -> Dictionary`; `static func apply_run(run: RunState, raw: Dictionary, items: Array[ItemDef]) -> void`
- `static func map_signature(map: FloorMap) -> Array` (id, type, cell, layout path, decor seed, extra enemies, doors)
- `static func build_floor(def: FloorDef, seed_text: String, pool := []) -> FloorMap`; `static func new_seed(rng) -> String`
- `RunState.promised_ids() -> Array`, `offered_recipe_ids() -> Array` and setters

- [ ] Step 1: tests — RunState round trip (pills, max, items in order, keys, bombs, potion, cursed, promised); damaged/missing reads as {}; another version reads as {}; the rebuilt map equals the original for 100 seeds on each of the ten paths (pool loaded once per path).
- [ ] Steps 2–5: fail, implement, pass, commit "Add the run checkpoint file".

### Task 9: Checkpoint writes and resume in the floor scene

**Files:** Modify `scripts/world/room_view.gd`, `scripts/scenes/floor_scene.gd`, `scripts/autoload/progress.gd`, `scripts/autoload/game.gd`, `tools/smoke_driver.gd`; Test `tests/test_room_snapshot_source.gd` (source checks)

**Interfaces — Produces:**
- `RoomView.finished` signal; `RoomView.snapshot() -> Dictionary` (`{"cleared": bool, "keep": Array}`); `RoomView.restore := {}` (set before `_ready`); `RoomView.open_hidden_doors(visited: Array[int])`
- `FloorScene.write_checkpoint() -> bool`, `FloorScene.debug_run_time()`
- `Progress.run_path() -> String` ("" in a dev run), `Progress.read_checkpoint()`, `write_checkpoint(d)`, `clear_checkpoint()`, `Progress.resume := {}`
- `Game.resume_run()`
- Resume rules: cleared rooms rebuild with no enemies, open doors and only kept pickups (items, shop stock, free items, recipes, unopened chests). Loose coins, heals and consumables are gone. Opened chests are gone, unopened ones stay closed. Hidden doors to visited rooms come back open. `Progress.start_run()` is not called.
- Smoke: write a checkpoint mid-floor, `Game.resume_run()`, then the room id, floor, map signature and `run_to_dict` match, and the run count is unchanged.

- [ ] Steps: implement, smoke loop in copies, commit "Write a checkpoint during runs and resume from it".

### Task 10: Screenshots and fitting

Real-window screenshots from a renamed `git archive` copy with an extra probe autoload, waits by `Time.get_ticks_msec`, after checking no non-headless Godot with `--path` runs: the title screen, each Options tab, the slot picker with three fake slots in the copy's own user folder, the pause menu, a resumed run, and the HUD with the timer and every counter at 99. Read each PNG and fix what does not fit 640x360.

---

## Self-review

- Spec 1 (title): Tasks 5, 7. Spec 2 (options): Tasks 1–4. Spec 3 (pause): Task 5. Spec 4 (slots): Tasks 6, 7. Spec 5 (checkpoint): Tasks 8, 9. Spec 6 (controller): stage 2; the Input tab shows "coming" and `keys.json` keeps a `pad` key.
- Vibration is stored and shown but does nothing until stage 2 adds rumble.

## As built (2026-11-05)

- Task 6 (slots) was built before Task 5, since the title's menu reads slot state. `menu_items` takes
  only the count of slots with progress, and `SaveSlots.continue_slot` picks the last used slot or the
  newest with progress. The last used slot lives in `user://last_slot.txt`.
- The old `KeysPanel` is gone; the Key Settings board opens Options on its Input tab.
- Load Game on a slot with an interrupted run offers Resume run, Abandon run and Cancel, so a run in
  another slot is never lost by one wrong press.
- A pause-menu save mid-fight puts Grandpa back in the last cleared room, so the fight starts over when
  he walks back in. Opened chests are gone on resume, unopened ones stay closed.
- Esc discards every tab's unsaved changes, not only the open tab's, after the one confirm.
- The run timer sits in the top row's gap before the Slip counter, since the small map's floor name
  holds the row's right end. It fits with eleven pills and 9999 Pension; more pills would crowd it.

---

# Stage 2: Controller Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build spec section 6 (controller), the Input tab's controller column (section 2) and the Vibration
option: default pad bindings, twin-stick aim, the active-device switch, device-aware prompts, pad rebinding,
rumble, hot-plugging, and controller focus in every panel.

**Architecture:** Pure rules go on core classes that tests reach: `PadInput` (defaults, names by family, stick
aim, dead zone, which device an event belongs to, rumble strengths), `ActiveDevice` (static state: pad or
keys, which pad, its family, cursor hiding rule), `PadRumble` (static gate and play), `PadFocus` (a Node every
panel adds: first focus, focus kept inside, gold highlight, re-focus after a rebuild, shoulder tabs).
`KeyBindings` grows a second slot per action. A new autoload `PadWatch` only wires events, hot-plug and the
cursor. Tests never name `PadWatch` (LESSONS 2026-11-04).

**Tech Stack:** Godot 4.7.2 built-in joypad input (`InputEventJoypadButton/Motion`, `Input.get_joy_axis`,
`Input.get_joy_name`, `Input.start_joy_vibration`, `Input.joy_connection_changed`). No add-ons.

## Global Constraints

- Never name another game anywhere. No new dependencies.
- Old `keys.json` files load unchanged; the controller column lives under `KeyBindings.PAD_KEY` ("pad").
- Every action the keyboard has must have a controller binding; a test checks none is unbound.
- Xbox-style names: A/B/X/Y, LB/RB, LT/RT, View, Menu. PlayStation-style: Cross/Circle/Square/Triangle,
  L1/R1, L2/R2, Create/Share, Options. Anything else gets Xbox-style names.
- Vibration is off when the Vibration option is off.
- Panels the full loop drives keep polling `Input.is_action_just_pressed` in `_process` (LESSONS 2026-11-03).
- Tests and `--smoke` never write `keys.json` or `settings.cfg` in the real user folder.
- CRLF line endings on every file.

## Engine facts checked first (headless probe, 2026-11-05)

- 4.7's `ui_accept` holds Enter, Kp Enter and Space only, and `ui_cancel` only Escape. `ui_up/down/left/right`
  already hold the D-pad and the left stick. So `InputSetup` adds pad A to `ui_accept`, and B gets its own
  fixed action `ui_pad_back`, so Esc is never seen twice in one frame.
- `InputMap.add_action` defaults to a 0.2 dead zone.
- `Input.parse_input_event` then `Input.flush_buffered_events()` updates action state and `Input.get_joy_axis`
  in a `--script` run, so headless tests can drive pads with synthetic events. A synthetic device has an
  empty `Input.get_joy_name`, which gets the Xbox-style default.

## Default layout

| Action | Controller (rebindable slot) | Fixed extra |
|---|---|---|
| move_up/down/left/right | left stick up/down/left/right | D-pad (always moves, never rebound) |
| attack | right trigger (hold to charge) | |
| throw | left trigger | |
| dodge | A / Cross | |
| interact | X / Square | |
| bomb | RB / R1 | |
| potion | LB / L1 | |
| map | View / Create | |
| pause | Menu / Options | |
| aim (not an action) | right stick | |
| menus | A confirm, B back (`ui_pad_back`), LB/RB tabs (`ui_tab_prev`/`ui_tab_next`), D-pad/left stick move focus | |

## File Structure

| File | Responsibility |
|---|---|
| `scripts/core/pad_input.gd` (new, `PadInput`) | Default pad events, fixed D-pad extras, family by joy name, button/axis names, describe, raw round trip, stick dead zone and aim point, event-to-device rule, capture filter, rumble strengths |
| `scripts/core/active_device.gd` (new, `ActiveDevice`) | Static `using_pad`, `pad_id`, `family`; `note(event)`, `lost(device)`, `hidden_mode(mode)` |
| `scripts/core/pad_rumble.gd` (new, `PadRumble`) | Static `enabled`, `last`; `play(kind)` gated by option and device |
| `scripts/ui/pad_focus.gd` (new, `PadFocus`) | Focus helper node added by every panel |
| `scripts/autoload/pad_watch.gd` (new autoload `PadWatch`) | `_input` → `ActiveDevice.note`, `signal device_changed`, `signal pad_lost`, cursor hiding in `_process`, hot-plug |
| `scripts/core/input_setup.gd` | Pad defaults, extras, menu actions |
| `scripts/core/key_bindings.gd` | Two slots per action, pad rebind/snapshot/save/load, device-aware `with_key` and `prompt_label` |
| `scripts/actors/player.gd` | Right-stick aim in `_aim_point`, crosshair at the pad aim point |
| `scripts/world/combat_feedback.gd`, `scripts/world/ground_strike.gd` | Rumble on hurt, heavy hit landed, boss strike landing |
| `scripts/autoload/settings.gd` | `PadRumble.enabled` from the Vibration option |
| `scripts/ui/options_panel.gd` | Controller column rebinding, shoulder tabs, B back, notes |
| every panel in `scripts/ui/`, `scripts/scenes/title_screen.gd`, `waiting_room.gd`, `floor_scene.gd` | `PadFocus`, B = Leave, pause on pad loss |
| `tools/smoke_driver.gd` | `_check_controller()` with synthetic joypad events |

### Task 11: Pad rules (`PadInput`) and the default layout

**Files:** Create `scripts/core/pad_input.gd`; Modify `scripts/core/input_setup.gd`; Test `tests/test_pad_input.gd`

**Interfaces — Produces:**
- `const XBOX := "xbox"`, `PLAYSTATION := "playstation"`, `PLAYSTATION_4 := "playstation_4"`
- `const STICK_DEAD_ZONE := 0.25`, `const AIM_REACH := 60.0`, `const SWITCH_AXIS := 0.5`, `const CAPTURE_AXIS := 0.6`, `const ACTION_DEAD_ZONE := 0.25`
- `static func default_event(action: String) -> InputEvent`, `static func extras(action: String) -> Array[InputEvent]`
- `static func family_for(joy_name: String) -> String`
- `static func button_name(button: int, family: String) -> String`, `static func axis_name(axis: int, sign: float, family: String) -> String`, `static func describe(event: InputEvent, family: String) -> String` ("?" for null/non-pad)
- `static func is_pad(event) -> bool`, `static func same(a, b) -> bool` (button index, or axis and sign)
- `static func to_raw(event) -> Dictionary` (`{"type":"joy_button","button":n}` / `{"type":"joy_axis","axis":n,"sign":±1}`), `static func from_raw(raw) -> InputEvent`
- `static func stick_dir(stick: Vector2) -> Vector2` (ZERO inside the dead zone, else normalized)
- `static func aim_point(from: Vector2, stick: Vector2, last_dir: Vector2) -> Vector2` (from + dir·AIM_REACH; resting stick keeps last_dir)
- `static func device_of(event) -> String` (`"pad"`, `"keys"`, or `""` for drift and jitter)
- `static func capture(event) -> InputEvent` (a clean pad event to bind, or null: releases, D-pad, small axis moves)
- `InputSetup.ensure()` adds every pad default and extra, `ui_accept` + A, `ui_pad_back` (B), `ui_tab_prev` (LB), `ui_tab_next` (RB)

- [ ] Step 1: tests — every `KeyBindings.ACTIONS` entry has a pad event after `ensure()` and no two share one; the default table above; names in both families for A/B/X/Y, shoulders, triggers, View/Menu, PS4 "Share" vs PS5 "Create"; family of "Xbox Series Controller", "PS5 Controller", "DualSense Wireless Controller", "PS4 Controller", "Nintendo Switch Pro Controller" (Xbox default), ""; dead zone; aim point straight, diagonal, resting; device_of for buttons, big and small axis moves, keys, mouse clicks, big and tiny mouse motion; capture skips D-pad and releases; raw round trip; synthetic `Input.parse_input_event` + `flush_buffered_events` of the right trigger presses `attack`, the left stick moves `get_vector`.
- [ ] Step 2: run `powershell -File tools/test.ps1 -- --only=pad_input` style (the runner reads `--only=`), expect "could not load".
- [ ] Step 3: implement. Step 4: pass. Step 5: commit "Add the controller rules and default layout".

### Task 12: Two binding slots in `KeyBindings`

**Files:** Modify `scripts/core/key_bindings.gd`; Test `tests/test_key_bindings.gd`

**Interfaces — Produces:**
- `KeyBindings.key_event(action) -> InputEvent`, `pad_event(action) -> InputEvent`
- `label_for(action)` stays the keyboard label; `pad_label_for(action, family) -> String`
- `rebind(action, event) -> String` works on the slot of the event's kind, swaps only with that slot, never touches extras
- `snapshot()` gains `PAD_KEY: {action: raw}`; `restore` puts both back; `save_to` writes both; `load_from` reads `pad` with swaps, ignoring bad entries
- `static func with_device(action, text, pad: bool, family) -> String`; `with_key(action, text)` uses `ActiveDevice`; `prompt_label(action) -> String`

- [ ] Step 1: tests — rebinding a pad button swaps with the pad slot only (keyboard unchanged); a pad rebind leaves the D-pad extra in place; save/load round trip of both columns in `OS.get_temp_dir()`; an old file without `pad` keeps the pad defaults; a damaged `pad` entry keeps its default; `with_device("interact", "Talk", true, PadInput.XBOX) == "X: Talk"` and `"Square: Talk"` for PlayStation; the existing test file moves from `user://test_keys.json` to the temp folder.
- [ ] Steps 2–5: fail, implement, pass, commit "Give every action a controller binding beside its key".

### Task 13: Active device, rumble and the `PadWatch` autoload

**Files:** Create `scripts/core/active_device.gd`, `scripts/core/pad_rumble.gd`, `scripts/autoload/pad_watch.gd`; Modify `project.godot` (autoload after Settings), `scripts/autoload/settings.gd`, `scripts/world/combat_feedback.gd`, `scripts/world/ground_strike.gd`; Test `tests/test_active_device.gd`

**Interfaces — Produces:**
- `ActiveDevice.using_pad: bool`, `pad_id: int` (-1 none), `family: String`; `static func note(event) -> bool` (true when the device changed); `static func lost(device: int) -> bool` (true when it was the active pad); `static func reset()`; `static func hidden_mode(mode: Input.MouseMode) -> Input.MouseMode`
- `PadRumble.HIT_TAKEN`, `HEAVY_LANDED`, `BOSS_SLAM`; `static var enabled := true`; `static var last := ""`; `static func play(kind) -> bool`; `static func strength(kind) -> Vector3` (weak, strong, seconds)
- `PadWatch.device_changed`, `PadWatch.pad_lost`
- `CombatFeedback.on_hurt` → HIT_TAKEN; `on_swing_landed(heavy)` → HEAVY_LANDED; `GroundStrike` landing from a boss → BOSS_SLAM

- [ ] Step 1: tests — note() switches on a pad button, stays on drift, switches back on a key; the family follows the pad's name; lost() of the active pad drops to keys; hidden_mode maps VISIBLE→HIDDEN and CONFINED→CONFINED_HIDDEN; rumble plays only with the option on and a pad active; heavy is stronger than a hit taken and a boss slam the strongest; source checks that combat_feedback and ground_strike call PadRumble.
- [ ] Steps 2–5: fail, implement, pass, commit "Follow the last used device and rumble on heavy moments".

### Task 14: Right-stick aim and prompts that follow the device

**Files:** Modify `scripts/actors/player.gd`, `scripts/ui/hud.gd`, prompt users (`npc.gd`, `pickup.gd`, `door.gd`, `waiting_station.gd`, `arcade_table.gd`, `retirement_station.gd`, `floor_map_view.gd`, `ending_card.gd`, `card_table_panel.gd`); Test `tests/test_game_options.gd`

**Interfaces — Produces:**
- `Player.pad_aim_point(from, stick, last_dir, mouse_aim, last_move) -> Vector2` (static: stick held aims; resting keeps the last stick way; with Mouse aim off and no stick used, the move way)
- `_aim_point()` order: `aim_source`, pad (when `ActiveDevice.using_pad`), Mouse aim off, mouse.
- The crosshair draws at the aim point whenever a pad aims.

- [ ] Step 1: tests for `pad_aim_point`; a source test that every `with_key` caller goes through the device-aware path (no prompt builds "%s: %s" itself).
- [ ] Steps 2–5: fail, implement (HUD potion slot refreshes on `PadWatch.device_changed`), pass, commit "Aim with the right stick and name the pad's buttons in prompts".

### Task 15: `PadFocus` and controller focus in every panel

**Files:** Create `scripts/ui/pad_focus.gd`; Modify every panel in `scripts/ui/`, `scripts/scenes/title_screen.gd`, `scripts/scenes/waiting_room.gd`, `scripts/scenes/floor_scene.gd`; Test `tests/test_pad_focus.gd`

**Interfaces — Produces:**
- `PadFocus.new()` added as the last child in a panel's `_ready`; it treats its parent as the panel.
- `var tabs := Callable()` (called with -1/+1 on LB/RB or Q/E where a panel has tabs); `var pad_only := false` (card tables: buttons take focus only while a pad is active, so Space never presses a clicked bet)
- `static func focusables(root: Node) -> Array[Control]` (visible, focus_mode not NONE, tree order); `static func first_of(list) -> Control` (first enabled, else first); `static func refocus_index(index, count) -> int`; `static func focus_style() -> StyleBoxFlat` (2 px gold border, no fill)
- Behavior in `_process`: when a pad is active or a focus key is pressed and nothing inside the panel has focus, focus the control at the remembered index (after a rebuild) or the first; plain Buttons get the gold focus style; ScrollContainers follow focus.
- B: `ui_pad_back` closes every panel exactly as its Leave/Esc does: the Waiting Room and floor scene send it down their Esc path for panels only (never to open pause); menus that answer Esc themselves (Options, pause, slot picker, confirm, credits) check it beside `pause`. The ending card also takes A and B.

- [ ] Step 1: tests — `focusables` order and filters on a hand-built tree kept out of the scene tree; `first_of` skips disabled; `refocus_index` clamps; a source test that every panel script in `scripts/ui/` that has a Leave or closes adds `PadFocus`, and that the menus check `ui_pad_back`.
- [ ] Steps 2–5: fail, implement, pass, commit "Drive every panel with a controller".

### Task 16: The Input tab's controller column, shoulder tabs and hot-plugging

**Files:** Modify `scripts/ui/options_panel.gd`, `scripts/scenes/floor_scene.gd`; Test `tests/test_options_source.gd`

- Controller cell per action is a button showing `KeyBindings.pad_label_for(action, ActiveDevice.family)`; pressing it waits for a pad input (`PadInput.capture`), Esc or `CAPTURE_TIME` (5 s) cancels, the D-pad never binds; a swap shows "Swapped with X". Defaults resets both columns. LB/RB switch tabs, B leaves. Notes: Vibration's "works once controllers are supported" goes; the Input note says the right stick aims and the D-pad always moves.
- Hot-plug: `PadWatch` drops to keys when the active pad leaves; the floor scene pauses on `pad_lost` when no pause is open and the run is not over.

- [ ] Steps: source tests (controller column, no "coming", `ui_tab_prev`), implement, commit "Rebind the controller column and pause when the pad goes".

### Task 17: Full-loop controller check and screenshots

**Files:** Modify `tools/smoke_driver.gd`; probe `tools/probes/pad_look.gd` (screenshot autoload in a copy)

- `_check_controller()` before `_check_resume()`: in the Waiting Room, a pad X press beside a merchant opens its panel, focus lands inside it, D-pad down moves focus, B closes it. In a run, a few seconds of play: left stick moves him, right stick turns his aim (aim_source cleared), right trigger swings, a hit taken while the pad is active records `PadRumble.last`, a synthetic disconnect pauses the run; a key press hands the device back.
- Screenshots in a real window: Input tab with both columns (Xbox and PlayStation names), prompts in both namings, focus highlights in the title screen, a merchant panel, the bounty board and the card table.

## Stage 2 self-review

- Spec 6 layout: Task 11. Aim: Task 14. Active device and cursor: Task 13. Prompts and names: Tasks 11, 12, 14. Menus: Task 15. Vibration: Task 13. Hot-plug: Tasks 13, 16. Input tab controller column: Task 16. Tests and full loop: every task, Task 17.
- The trophy wall shows its lines as HUD notices and has no panel, so it needs no focus.

## Stage 2 as built (2026-11-05)

- `ActiveDevice` came before the two-slot `KeyBindings`, since `with_key` reads it.
- Pad bindings use device -1, so any pad works, not only the first one plugged in. The screenshot probe
  found this: a pad on device 7 could not switch tabs or back out.
- The D-pad always walks and always moves menu focus, and is never bound to anything else. B (`ui_pad_back`)
  and the shoulder buttons (`ui_tab_prev`/`ui_tab_next`) are fixed menu actions, so B is never a second Esc.
  A was added to `ui_accept`, which in 4.7 holds no pad button.
- `PadFocus` works out each panel's focus neighbours from where its controls are drawn and keeps them inside
  the panel, so the D-pad never reaches a panel behind (the title menu under the slot picker). It focuses
  a control on its own only while a pad plays or after a focus key, so Space on the keyboard never presses
  a button nobody chose. Card-table buttons take focus only while a pad plays.
- With a pad, Mouse aim on means the aim stays where the right stick left it. Mouse aim off means a resting
  stick aims the way he walks.
- A controller cell on the Input tab waits 5 s for a button. Esc, a key or a click cancel it, so a pad
  alone can always back out.
- The Options hints name the device in use ("Q / E", "LB / RB" or "L1 / R1"; "Esc", "B" or "Circle")
  and follow a switch at every tab change.
- The big map closes on Esc and B by itself, since the floor scene is paused while it is open.
- Unplugging the pad being played with pauses a run (not the Waiting Room) and hands play to the keyboard.
- The trophy wall shows HUD lines and has no panel, so it needs no focus.
- A lighter rumble never cuts a stronger one short, and a row of boss strikes rumbles once per landing.
