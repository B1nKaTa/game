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
