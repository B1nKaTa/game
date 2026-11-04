# Title menu, options, save slots, run checkpoint and controller design

Approved in conversation on 2026-11-04. It builds on the floors four and five branch (`deep-floors`).
Every earlier spec's ground rules still apply. Art stays code-drawn placeholder until the art pass.

## Ground rules

- **No other game names:** never name another game in any file, comment, asset name or commit message.
- **Dependencies:** no new dependencies. Controllers, settings files and menus use Godot's built-in
  input, `ConfigFile` and Control nodes.
- **Old saves load:** every new save field is optional and has a fallback. The player's current save
  must survive unchanged into slot 1.
- **Runnable:** leave the project runnable after every commit, and keep `LESSONS.md` up to date.
- **Testing is on hold** until the user says go. Write code and tests, run nothing, and keep the owed
  list in `docs/superpowers/plans/title-menu-untested.md`.

## 1. The title screen

The game opens here, after the boot scene, instead of going straight to the opening or the Waiting
Room.

- **The scene:** the afterlife's Waiting Room queue, drawn in code.
  - A line of shuffling old souls holds tickets, with Grandpa among them, and the "Take a Number"
    machine glows at the end.
  - A "NOW SERVING" sign ticks to the next number every few seconds, and the queue shuffles one step
    forward.
  - The game's name sits above the scene.
  - The scene is drawn at the game's 640x360 view, as everything else is.
- **The menu, bottom-left:**
  - **Continue**: loads the last used save slot. If that slot has an interrupted run, it resumes the
    run (section 5). Otherwise it goes into the Waiting Room, or the opening for a slot that has never
    seen it. Hidden when no slot has any progress.
  - **New Game**: opens the slot picker (section 4).
  - **Load Game**: the slot picker in load mode. Shown when more than one slot has progress.
  - **Options**: the options panel (section 2).
  - **Credits**: a short scrolling credits card.
  - **Quit Game**
- **Version:** the version in small text under the menu, read from `application/config/version` in
  `project.godot` (add it there as `0.5.0` if it is missing).
- **Controls:** mouse, keyboard (arrows or W/S, then Enter) and controller (section 6) all work. The
  selected item gets the gold highlight bar.
- **Dev keys:** debug builds only. F3, F5 and F6 still start dev runs from the Waiting Room, and the
  title screen ignores them.
- **The full loop** (`--smoke`) skips the title screen and goes straight in, as it does today.

## 2. Options

One panel, opened from the title screen, the pause menu and the Waiting Room's Key Settings board. It
has four tabs: **Video, Audio, Game, Input**. Shoulder buttons or Q/E switch tabs on a controller or
keyboard. **Defaults** resets the open tab, and **OK** saves and closes. Esc or B closes without
saving that tab's unsaved changes, after a "Discard changes?" confirm if anything changed. The panel
has its own opaque backing, as every large overlay must (see LESSONS), and fits the 640x360 view.

**Video**

| Setting | Kind | Default | How |
|---|---|---|---|
| Brightness | slider −50..50 | 0 | full-screen adjustment layer (shader on a top CanvasLayer) |
| Contrast | slider −50..50 | 0 | same layer |
| Gamma | slider −50..50 | 0 | same layer |
| Resolution | dropdown | the largest whole multiple of 640x360 that fits the screen | windowed size; whole multiples only (1280x720, 1920x1080, 2560x1440, 3840x2160), the best fit marked with * |
| Fullscreen | on/off | on | `DisplayServer.window_set_mode` |
| Vsync | on/off | on | `DisplayServer.window_set_vsync_mode` |
| Confine mouse cursor | on/off | on | `Input.MOUSE_MODE_CONFINED` while playing (hidden-and-confined where the game hides it) |
| Pixel-perfect scaling | on/off | on | integer stretch scale; off allows fractional fill |

**Audio**: Master, Effects, Music and Ambience sliders 0..100, defaults 100/80/70/70, through audio
buses (create `Effects`, `Music` and `Ambience` buses under Master and route `CombatFeedback`'s players
to Effects). Music and Ambience have nothing to play yet.

**Game**

| Setting | Default | Effect |
|---|---|---|
| Screen shake | on | off makes `CombatFeedback.shake_magnitude()` 0 |
| Hit-stop | on | off skips the hit-stop freeze |
| Vibration | on | controller rumble on hits taken, heavy hits landed and boss slams |
| Pick up heals at full pills | off | off leaves heal pickups on the floor while pills are full |
| Mouse aim | on | off aims the cane and the dentures the way Grandpa last moved; a controller's right stick always aims while it is held |
| Hide minimap during combat | off | the minimap hides while a room's fight is on |
| Minimap opacity | 100 | 20..100 |
| Show run timer | off | a small run timer on the HUD's top row (fit it by screenshot with every counter at 99, as LESSONS says) |
| Language | English | a dropdown with English only for now; every new menu string goes through `tr()` so translations can come later |

**Input**: every action in two columns, **Keyboard / Mouse** and **Controller**.
- Selecting a slot and pressing a key, mouse button or controller button rebinds it.
- A key or button already used by another action swaps with it, after a short "swapped with X" notice.
- **Defaults** resets both columns.
- The existing key bindings (`KeyBindings`, `user://keys.json`) are kept. The controller column is
  added beside them in the same file under a new optional key, so an old `keys.json` loads unchanged.
- The Waiting Room's Key Settings board opens Options on this tab.

**Storage.** Settings live in `user://settings.cfg` (`ConfigFile`), one file for the whole game. They
are not in any save slot. A missing or damaged file falls back to the defaults. `--smoke` and tests
never write it.

## 3. The pause menu

Esc (keyboard) or Start (controller) during a run or in the Waiting Room pauses the game. It opens
only when no other panel is open; with a panel open, Esc first closes that panel. The menu offers:
- **Resume**
- **Options**
- **Save and Quit to Title.** In a run this writes the checkpoint first (section 5).
- **Quit to Desktop.** Same as above, then quits.

While paused the tree is paused, except for the menu.

## 4. Save slots

**Three slots,** each with its own progress and its own interrupted run.
- **Files:** `user://slot_1/save.json`, `slot_2/`, `slot_3/`. Each folder has the same files the
  single save has today: `save.json`, `save.json.bak` and `run.json` (the checkpoint).
- **Migration:** on the first start of this build, an existing `user://save.json` and its `.bak` are
  **copied** into `slot_1/`, and the originals are left in place untouched. Slot 1 becomes the last
  used slot. The copy never overwrites an existing `slot_1/save.json`. Migration is covered by a test
  on a copy.
- **The slot picker:** three cards, each showing:
  - empty, or the slot's floors cleared, deepest depth reached, Pension, runs played and last played
    date;
  - "Run in progress: Floor N" when it has a checkpoint.

  New Game on a slot with progress asks "Overwrite slot N? This can't be undone." Deleting a slot
  is a separate button on its card, with the same confirm.
- **`Progress`** gains `select_slot(n)`. `SAVE_PATH` becomes the selected slot's path. The smoke path
  and the dev profile path stay as they are, separate from all slots.
- **`keys.json` and `settings.cfg`** stay global, outside the slots.

## 5. The run checkpoint

A run can be resumed after any quit, including Alt+F4 or a crash.

- **When it is written:**
  - each time a room is cleared;
  - on arriving at a landing;
  - on entering a floor through its Crossroads choice;
  - from the pause menu's save and quit.

  It is written atomically (to `run.json.tmp`, then renamed), so a kill during the write never
  leaves a broken file.
- **What it holds:**
  - the depth, the path id, and the floor's seed and map (or the seed plus everything the builder
    needs to rebuild the same map);
  - the ids of cleared and visited rooms, and the room Grandpa was last in when it was written;
  - the whole `RunState`: pills and max pills, items held in order, Pension earned this run,
    Thermoses, Slips, the brewed potion, consumables, the cursed flag, the ticket and run-only perks;
  - shop stock still for sale and items still waiting in item, treasure and vault rooms;
  - the run's RNG state for anything rolled later.
- **What it does not hold:** loose pickups lying on cleared floors (coins, heals, keys), opened or
  unopened chests, and broken props. On resume, cleared rooms come back empty of loose pickups, and
  their chests are gone if they were opened or stay closed if not (pick whichever the code makes
  simpler, and say which).
- **Resume:**
  - The same floor is rebuilt from the seed, with cleared rooms cleared, their doors open and no
    enemies.
  - Grandpa stands where he arrives in the last room he cleared. On a landing checkpoint, he is on
    the landing.
  - A fight that was going on when the game quit starts over when he walks back in.
  - `Progress.start_run()` is not called again, so the run count and ticket stay the same.
- **Ending:** the checkpoint is deleted when the run ends by death or by "FLOOR CLEARED", and when
  the player gives it up. Only one checkpoint exists per slot.
- **Giving it up:** entering the Waiting Room from Continue resumes the run. Choosing the Waiting Room
  any other way (Load Game) with a checkpoint present asks "Abandon your run on Floor N?". Abandoning
  ends the run as a death would, for income and the ticket.
- **Dev runs:** they never write a checkpoint.
- **Tests:**
  - round-trip a `RunState` and a floor through the file;
  - a damaged or missing `run.json` loads as no run;
  - a version field rejects files from an incompatible build;
  - the rebuilt map equals the original for the same seed over 100 seeds on every path.

## 6. Controller support

Godot's built-in joypad input, with no add-ons.

- **Default layout**, all of it remappable on the Input tab:

  | Action | Controller |
  |---|---|
  | Move | left stick and D-pad |
  | Aim | right stick (twin-stick); when the stick rests, aim stays where it was |
  | Swing / charge (attack) | right trigger (hold to charge) |
  | Throw dentures | left trigger |
  | Dodge | bottom face button |
  | Interact | left face button |
  | Thermos (bomb) | right bumper |
  | Drink potion | left bumper |
  | Map | View / Select |
  | Pause | Start |

  Every action the keyboard has must have a controller binding. A test checks none is left unbound.
- **Aim:** goes through the player's existing aim path (`Player.aim_point()` / `aim_source`). Right
  stick aim is a point at a fixed distance from Grandpa in the stick's direction, with a small dead
  zone. While a controller is the active device the mouse cursor hides.
- **Active device:** whichever was used last, mouse/keyboard or controller. Prompts follow it:
  - "[E] Talk" becomes the controller's button name.
  - Button names follow the controller's family, read from `Input.get_joy_name`. Xbox-style names
    are A/B/X/Y, LB/RB, LT/RT, View and Menu. PlayStation-style names are Cross/Circle/Square/
    Triangle, L1/R1, L2/R2, Create/Share and Options. Anything else gets Xbox-style names.
  - `KeyBindings.with_key` grows a device-aware variant, and every prompt uses it.
- **Menus:** every panel can be driven by a controller.
  - That covers the title screen, slot picker, options, pause, shops, forms and refiling, crafting,
    potions, decor, bounty board, noticeboard, ticket, item rack, the card tables and the big map.
  - Each panel sets a first focused control and a sensible focus order.
  - The D-pad or left stick moves focus, A or Cross confirms, and B or Circle backs out (the same as
    the panel's Leave). Shoulder buttons switch tabs where a panel has tabs.
  - The focused control shows the gold highlight.
- **Vibration:** `Input.start_joy_vibration`, short and weak for hits taken, stronger for a heavy hit
  landed and boss slams. It is off when the Vibration option is off.
- **Hot-plugging:** connecting or disconnecting a controller mid-game works. Disconnecting during a run
  pauses it.

## 7. Build order

1. Settings storage, the Options panel (all four tabs, keyboard and mouse) and the adjustment layer.
2. The title screen, the pause menu and Credits.
3. Save slots and migration.
4. The run checkpoint and resume.
5. Controller input, aim, prompts, vibration, the controller column of the Input tab, and controller
   focus in every panel.
6. An independent review, then the user plays. Nothing is merged until then.

## Testing (when allowed)

- **Headless tests** for the settings file and its defaults, the slot paths and migration on a copy,
  the checkpoint round trip and damage handling, the rebuild matching its seed, that every action has
  both bindings, button names by family, and the aim point from a stick.
- **Full loop:** it still passes with `--smoke`. Add a check that a checkpoint written mid-floor
  resumes into the same room with the same `RunState`.
- **Screenshots** in a real window of the title screen, every Options tab at its fullest, the slot
  picker with three filled slots, the pause menu, and prompts in both device modes.
- **By the user:** on a real controller (Xbox or PlayStation).
- **The real save:** guard it as always. Migration is first proven on a copy, and the real
  `save.json` must still be byte-identical afterwards, since it is copied, never moved.
