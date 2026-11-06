---
name: add-floor
description: Use when designing or building a new floor (depth) or a new path of the Grandpa game, starting with floor 4 - its theme, hazard, enemies, mini boss and floor boss, about 33 room layouts, palette, unlock rule, the Waiting Room hooks it feeds (department, memento, wanted posters, letter), and the verification needed before the floor counts as done.
---

# Add a floor to Grandpa

A floor is a **depth** with two **paths**: an open one and a locked one, offered side by side at that
depth's Crossroads. Each path is one `FloorDef` with its own rooms, palette, hazard, 3 new enemies,
2 returning ones, a mini boss and a floor boss. Floors 1 to 3 were built this way, and floor 3 is the
worked example:

- Spec: `docs/superpowers/specs/2026-11-03-third-floor-design.md`
- Plan: `docs/superpowers/plans/2026-11-03-third-floor.md` (Steps 2 to 5 are the floor work)
- Floor 2, the same pattern one depth up: `docs/superpowers/specs/2026-11-03-second-floor-design.md`
  and `docs/superpowers/plans/2026-11-03-second-floor.md`
- What the user was told at the end: `docs/night-report-2026-11-04.md`

Supporting files beside this one:
- `plan-template.md`: the task order, with the files each task touches and its required tests.
- `layouts.md`: how to make and check room layouts, and every rule learned the hard way.
- `checklist.md`: the exact verification commands and the "done" checklist.

## 0. Before anything

1. Read `CLAUDE.md` and **all** of `LESSONS.md`. Most lessons came from building floors. Copy the
   relevant ones into any brief you hand a subagent.
2. Read the floor-3 spec and plan above, then `docs/playtest-notes.md` (the last entries hold the
   balance numbers you will compare against).
3. Ask the user which branch is the latest **tested** one to build on. On 2026-11-04 that was not
   settled: `third-floor` was tested but unmerged, and `waiting-room` (which holds the Waiting Room
   hooks this skill names) was written but never run. See
   `docs/superpowers/plans/waiting-room-untested.md`.
4. Ask whether **testing is allowed** right now (see rule 11 below).

## The user's standing rules (never break these)

1. **Never name other games** anywhere: code, comments, specs, plans, asset names, commit messages,
   PR text. Describe features directly. Check specs and commit messages before committing.
2. **No new dependencies** or add-ons without asking. None have been needed so far.
3. **Guard the real save** at `%APPDATA%\Godot\app_userdata\Grandpa\save.json`: record its MD5
   before every Godot session and compare after. Also back up `save.json.bak` and `keys.json`
   around any probe that runs real scenes. Never run a scene without `--smoke`, and never point a
   probe at the real save. Commands are in `checklist.md`.
4. **Check for an open game window before launching Godot** in any form:
   `Get-CimInstance Win32_Process -Filter "Name like 'Godot%'" | Select-Object ProcessId, CommandLine`.
   A process with no `--headless` and a `--path` is the user playing. Wait, or ask. Never launch
   anything with sound while they play.
5. **Never edit the worktree the user plays from.** Godot loads files lazily, so edits there break
   their game. On 2026-11-04 they played from `C:\GameDev\game\.worktrees\check`. Ask if unsure.
6. **Build on a new branch in a new worktree**:
   `git worktree add -b <floor-branch> .worktrees/<floor-branch> origin/<base-branch>` from
   `C:\GameDev\game`. Leave other worktrees alone, especially any another agent is using.
7. **No PowerShell `Set-Content` or `Out-File` on game files**: Windows PowerShell 5.1 adds a byte
   order mark that breaks `.tres` and Markdown. Use the Edit tool, or `sed -b -i`.
8. **Keep line endings.** The repo has `core.autocrlf true`, so files check out as CRLF. Use the
   Edit tool for multi-line changes, `sed -b -i` with `\(\r\?\)$` and `\1` for single lines, and
   check with `file <path>` (and `tr -cd '\r' < f | wc -c` against `wc -l`) before each commit.
9. **Push with `GIT_TERMINAL_PROMPT` and `GCM_INTERACTIVE` unset** for that one command, since the
   shell sets them and the push fails otherwise:
   `env -u GIT_TERMINAL_PROMPT -u GCM_INTERACTIVE git push -u origin <branch>` (Git Bash).
10. **Commits:** imperative mood, one logical change each, ending with a blank line and
    `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. In Windows PowerShell write the
    message to a scratchpad file and use `git commit -F <file>` (a here-string piped to `-F -`
    becomes a pathspec). After a `git mv`, `git add` only the new paths and read `--stat`.
11. **When the user says testing is on hold**, write code and tests but run nothing: no Godot in
    any form, not even `--headless --import` or `--check-only`. Leave the plan's run steps
    unticked, say plainly the work is untested, and keep a list of what to run later in the style
    of `docs/superpowers/plans/waiting-room-untested.md`. New scripts have no `.uid` until the
    first import.
12. **PixelLab generations need the user's go-ahead.** They are on the trial plan. Art stays
    code-drawn placeholder until the one art pass, which sets prop collision boxes too, so never
    change prop collision boxes before then.
13. **Leave the project runnable after every commit**, and append a dated lesson to `LESSONS.md`
    (`- YYYY-MM-DD: <what happened> → <rule>`) whenever a bug or gotcha teaches something.
14. **An independent review comes before a merge**, not before every push. Never merge until the
    user has played the floor.

## 1. Design stage: settle these with the user before any code

Ask one question at a time, recommend one answer and say why. Do not dump lists of options. Record
each answer as you go. The floor-3 spec shows the level of detail wanted.

1. **Theme, names, depth and paths.** One place per path, in the game's dark-comedy afterlife tone
   (the earlier ones: Records Basement, Unkempt Cemetery, Sunset Shores Eternal Care, Furnace Works,
   Eternal Rest Funeral Parlour, The Flashback Cinema, Last Showing). Which is west (open) and east (locked).
   Each path needs an `id` in snake_case, which every hook below keys on.
2. **Unlock rule.** So far always: the west path opens on reaching the depth
   (`open_after_depth = depth - 1`, `clears_to_open = 0`), the east one after one clear at its own
   depth (`open_after_depth = depth`, `clears_to_open = 1`, `closed_hint = "Beat a fourth-floor boss
   first"`). `FloorDef.is_open_for` reads these through `ProgressData.clears_at`. Also `danger`
   (skulls on the sign: 1, 2, 3, 4 so far).
3. **Difficulty numbers.** The table so far, to extend one step:

   | | Floor 1 | Floor 2 | Floor 3 |
   |---|---|---|---|
   | `health_mult` | 1.0 | 1.4 | 1.8 |
   | `pension_mult` | 1.0 | 1.5 | 2.0 |
   | `enemies_by_size` small/medium/large | 4/6/11 | 5/7/12 | 6/8/13 |
   | `chest_weights` lunchbox/locked/safe/urn/mimic | 50/30/12/8/0 | 40/26/16/10/8 | 32/24/18/13/13 |
   | Heaviest hit | 1 pill | 2 pills | 2, plus one 3-pill attack per floor boss |

4. **The hazard.** One per path, room-wide, readable, with its own symbol. Earlier ones: holes, wet
   floor (`W`), vents (`U`), organ pipes (`o`), escalator strips (`><^v`). Decide whether it hurts,
   how a dodge treats it, which enemies it affects, and whether bosses can drive it (as Mortimer
   plays the pipes and the Santa reverses strips).
5. **Regular enemies: 3 new and 2 returning per path.** Give each new one a role that matches a
   first-floor role (pack, ranged, charger, ground marks, ambusher), its attack, its warning time and
   its counter. The 2 returning ones are earlier enemies as new `.tres` files in the floor's colours
   (as `parlour_plot_holder.tres`, `mall_intern_reaper.tres`), same numbers, and the floor's
   `health_mult` does the rest. Agree spawn weights (floor 3 used 3, 4, 3, 3, 2).
6. **Mini boss and floor boss.** For each: name and title, 3 to 4 attacks with their telegraphs
   (windup, warning shape, lane or spot), what it summons and the cap, the phase-two change, and the
   one heaviest attack with its extra-clear warning. Apply section 3 of this file.
7. **Room count and mix.** About 33 per path, in the floor-3 proportions (see `layouts.md`).
8. **Palette and readability.** Floor, wall, ambient, fill light, `floor_pattern`, `wall_pattern`,
   flicker, decor kinds, and how the hazard and every effect read on the palest tile.
9. **Waiting Room hooks.** The department its first clear opens (name, what it holds, arrival line),
   the floor boss's memento and perk, the two wanted posters with their reward extra (item, recipe or
   cosmetic), and the letter text. See the hooks section of `plan-template.md` for the exact places.
10. **NPCs.** Any new NPC on the floor or in its department, with placeholder lines.
11. **Does F3 move?** `DevStart.START_DEPTH` is 3. Ask whether the dev shortcut should start at the
    new depth once it exists.

Then write the spec as `docs/superpowers/specs/<date>-<floor>-design.md`, shaped like the floor-3
spec: ground rules, the connection, difficulty, one section per path (look, hazard, enemies, mini
boss, floor boss), size, Waiting Room hooks, build order, testing. Get the user's approval, then
write the plan from `plan-template.md` with the superpowers:writing-plans skill.

## 2. How a floor plugs in (real names, all checked)

- **Data:** `data/floors/<path_id>.tres` (`FloorDef`, `scripts/content/floor_def.gd`), rooms in
  `data/rooms/<path_id>/`, enemies in `data/enemies/`, behaviors in `scripts/actors/behaviors/`.
- **Depth wiring:** `scripts/scenes/floor_scene.gd` holds `PATHS_BY_DEPTH`, `LAST_DEPTH` and
  `LANDINGS_BY_DEPTH`. Its comment over `_continue_after_floor` says exactly what to change: raise
  `LAST_DEPTH`, list the paths, add a landing. `_go_down` loads the landing and heals `LANDING_HEAL`.
- **Landing:** copy `data/floors/landing_3.tres` to `landing_<N>.tres` (`display_name = "Floor N"`,
  `depth = N`). The layout `data/rooms/landing/landing.tres` and the Crossroads
  (`data/floors/crossroads.tres`, `data/rooms/crossroads/crossroads.tres`,
  `scripts/world/crossroads_view.gd`) are shared by every depth.
- **Save rules that mirror the floor list** (ProgressData must not load FloorDefs):
  `scripts/core/progress_data.gd` `FIRST_PATH_BY_DEPTH` and `PATHS_AT_DEPTH`.
- **Merchants:** `MerchantRules.is_open` (`scripts/core/merchant_rules.gd`) reads an entry's
  `depth`/`clears`, `paths` or `legacy_clears`. Entries live in `Departments.MERCHANTS`.
- **Dev shortcut:** `scripts/core/dev_start.gd` (`START_DEPTH`, `START_KEYS` with F3, F5 and F6 for
  depths 3, 4 and 5, `clears_by_depth`, `paths_cleared`, `ALL_PATHS`, `HINT`), reached in the Waiting
  Room through `Game.begin_dev_run(start_depth)` (`scripts/autoload/game.gd`), which leaves the depth in
  `Progress.dev_start_depth` for `floor_scene.gd`. F4 is the dev Waiting Room. The profiles are built
  from `ProgressData.PATHS_AT_DEPTH`, so a new depth is covered once it is listed there.
- **The full loop:** `tools/smoke_driver.gd` (`_clear_every_depth`, `_check_crossroads`,
  `_check_dev_start`, `TIMEOUT`), run by `tools/smoke.ps1`. `_clear_every_depth` walks every depth
  from 1 to the scene's `LAST_DEPTH` through `PATHS_BY_DEPTH`, west paths on the first run and east on
  the second, so a new path is cleared as soon as it is listed. Path-specific fight checks hang off
  `_clear_whole_floor` by depth and path index, as `_check_care_home_fights` does.

## 3. Boss and enemy rules (from the lessons)

- **Every attack warns first,** and line attacks also show a lane (`Enemy.set_warning`,
  `set_warning_lane`, `set_warning_cone`, `add_warning_lane` for extra lanes). Every behavior
  constant named `*WINDUP` (or `FUSE`) must give at least 0.2 s times `PlayerStats.BASE_WARNING`:
  `tests/test_enemy_types.gd` `test_every_attack_warning_shows_long_enough_to_read`. Its `BEHAVIORS`
  list holds only floor-1 behaviors, so add the new floor's behaviors to it, and also give each
  attack its own test that the warning leaves time to step out (as `tests/test_parlour_enemies.gd`
  `test_the_wail_leaves_time_to_step_out_of_a_lane`).
- **Check warning time against reaction time.** A warning that shows only for part of a fuse got the
  bot hit by half of all blasts. Pass `whole_windup = true` to `set_warning` for anything that starts
  right beside Grandpa or costs the most.
- **The heaviest attack** costs `Enemy.HEAVIEST_DAMAGE` (3), shows its whole 1.2 s windup, and gets a
  second outline (`Enemy.mark_lane_heaviest`) or second ring. Phase two never shortens it.
- **A single safe spot is marked visibly** with `SafeSpotMark` (`scripts/world/safe_spot_mark.gd`),
  kept off the boss's own body and anything solid that moves. Mortimer's crescendo was unreadable
  among a dozen red reaches until it had a green ring.
- **Bosses start attacks only with their whole body on screen:** `Enemy.target_in_view()`, which
  uses `BossMoves.in_view`. "On screen" is the camera's rule, `RoomCamera.center_for`, never an
  offset from Grandpa.
- **Walkers route through the walk grid:** `Enemy.chase_direction()` toward Grandpa and
  `Enemy.walk_direction_to(point)` toward any other point. Never a bare `direction_to` unless the
  way is known to be open. Route waypoints with `WalkGrid.fit_point` for the biggest body.
- **Summons:** through `Enemy.request_summon_at` on marked spots, capped with
  `BossMoves.can_summon(alive, cap)` (5 enemies in the room for floor 3), and they pay no Pension
  (`Enemy.is_summon`). Anything that can spawn without limit pays nothing.
- **Charges** use `BossDash` (stops at walls via `BossDash.stops_at`, smashes props through
  `Enemy.smash`) or `MatronBehavior.charge_end`, and call `enemy.hold_lane()` every frame they run,
  so a hazard such as a strip never carries them off the warned lane (`Enemy.rides_strips`).
- **Lingering effects:** anything an attack leaves in a room for a while must be listed in
  `RoomView.is_passing_effect` (`scripts/world/room_view.gd`), which `clear_passing_effects` frees
  when Grandpa leaves. Tested by `tests/test_stage2_props.gd`
  `test_the_third_floors_effects_are_cleared_from_a_stored_room`. Extend that test.
- **Health against earlier bosses** (final health; the `.tres` holds final / `health_mult`):

  | Depth | Mini bosses | Floor bosses |
  |---|---|---|
  | 1 | Senior Adjuster 500, Gus 500 | Regional Reaper 1200, Digby 1200 |
  | 2 | Barbara 500, Klaus 500 | Matron Mercy 1500, Old Smokey 1500 |
  | 3 | Reverend 640, Gloria 640 | Mortimer 1700, Mall Santa 1650 |

  A new mini boss must be at least as hard as the last depth's mini bosses, and a floor boss clearly
  harder than the last depth's floor bosses, each checked by a test comparing numbers (as
  `tests/test_parlour_bosses.gd` `test_mortimer_is_clearly_harder_than_matron_and_smokey`) and then
  by the balance bot.
- **Readability on light tiles:** effects tuned on dark floors (the perfume cloud, wet floor, the
  HUD pills) vanished on the Mall's white tile. Screenshot every effect and the HUD over the floor's
  palest tile in a large room. Warnings, shots and ground marks stay on their own high z layer so no
  darkness overlay can hide them. Every enemy must be told apart by colour or size
  (`test_every_enemy_of_the_floor_can_be_told_apart` in the floor test).
- **A hazard tile shares no shape with any floor pattern,** and a floor pattern uses no shape the
  floor's hazard uses (boiler vents looked like the tread plate; Mall glints would have read as wet).
- **Room code never names enemy data:** anything a room spawns comes from its `FloorDef`
  (`tests/test_enemy_plan.gd` `test_behaviors_and_rooms_name_no_floor`).
- **Pure rules are `RefCounted` with static functions and headless tests.** Name enums through the
  class (`MatronBehavior.Attack.X`), and preload a script when a test wants a const alias.

## 4. Verification before calling a floor done

All of these, in order. Commands and details are in `checklist.md`.

1. `powershell -File tools/test.ps1` ends with `N tests, 0 failed` and no `SCRIPT ERROR`.
2. 3 full-loop runs, each in its own `git archive` copy on D: with its own `config/name`, every one
   printing `SMOKE PASS`. Delete the copies afterwards.
3. Screenshots of every new attack, hazard, prop and room size in a real window, each one opened and
   looked at, with fixes for anything unreadable.
4. A balance bot run for both new bosses of each path and whole floors, compared with the earlier
   depths on the same saves, and the income per full clear.
5. One independent review of the whole branch against the spec, every finding verified by reading
   the code before fixing.
6. A night or status report for the user in the style of `docs/night-report-2026-11-04.md`, plus
   updates to `docs/playtest-notes.md` and `LESSONS.md`. Push, then stop for the user to play.

The real save's MD5 is the same before and after every one of these steps.
