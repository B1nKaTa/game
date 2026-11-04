# Floors Four and Five Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add depths 4 and 5 to the run, each with an open and a locked path, complete with hazards, enemies, bosses, rooms and Waiting Room hooks, as set out in the spec.

**Spec:** `docs/superpowers/specs/2026-11-04-floors-four-and-five-design.md`

**Architecture:** The work follows the add-floor skill (`.claude/skills/add-floor/`). Its `plan-template.md` holds the task shapes: files, interfaces, tests and the floor-3 model for each. Its `layouts.md` covers rooms and `checklist.md` covers verification. This plan fixes the order, the per-path facts and how the parallel work is split. Read the skill's `SKILL.md`, `CLAUDE.md` and all of `LESSONS.md` before starting any task.

**Tech Stack:** Godot 4.7.2, GDScript, and headless tests through `tools/test.ps1`.

## Global Constraints

- Never name another game in any file, comment, asset name, commit message or PR text.
- No new dependencies.
- Guard the real save at `%APPDATA%\Godot\app_userdata\Grandpa\save.json`:
  - Take its MD5 before and after every Godot session.
  - Back up `save.json`, `save.json.bak` and `keys.json` around any probe that runs real scenes.
- Before any Godot launch, check for a non-headless Godot process with `--path`. If there is one, the user is playing: run nothing that opens a window.
- Never touch `C:\GameDev\game\.worktrees\check`.
- No PowerShell `Set-Content` or `Out-File` on game files. Keep every file's line endings:
  - Use the Edit tool, or `sed -b -i` with `\(\r\?\)$` and `\1`.
  - Check with `file` before each commit.
- Commits are imperative, one logical change each, and end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
  - Write the message to a scratchpad file and use `git commit -F`.
- Push with `env -u GIT_TERMINAL_PROMPT -u GCM_INTERACTIVE git push`. GitHub sometimes returns 500: retry.
- Leave the project runnable after every commit.
- **Testing is ON HOLD (user, 2026-11-04):** run no Godot in any form (no tests, smoke, import, check-only, probes) until the user says so. Write code and tests, tick nothing that needs Godot, and list owed checks in `docs/superpowers/plans/deep-floors-untested.md` (SKILL.md rule 11).
- Full loops and probes run only in `git archive` copies on `D:\` with a renamed `config/name`. Keep C: free, because it is small.
- Art stays code-drawn placeholder, and prop collision boxes stay unchanged.

## How the work is split

| Step | Branch / worktree | Who |
|---|---|---|
| 1. Connection | `deep-floors` in `.worktrees/deep-floors` | one agent |
| 2a. Cruise | `deep-cruise` off `deep-floors` after Step 1 | one agent |
| 2b. Golf | `deep-golf` | one agent, in parallel with 2a, 2c and 2d |
| 2c. Departures | `deep-airport` | one agent |
| 2d. Head Office | `deep-office` | one agent |
| Merge | each path branch into `deep-floors` | the coordinator |
| 3. Waiting Room hooks | `deep-floors` | one agent |
| 4. Balance, review, report | `deep-floors` | agents plus the coordinator |

**Rules for the parallel step.** Four branches edit some of the same files. Keep merges easy:

- **Symbols:** each path uses only its own symbols.

  | Path | Symbols |
  |---|---|
  | cruise | `b 0 1 2`, and no hazard symbol (a layout flag instead) |
  | golf | `s 3 4 5` |
  | airport | `= 6 7 8` |
  | office | `x 9 N y` |

- **Shared lists:** add new entries to the **end** of a shared list or table, each in its own block with a comment naming the path. This covers `ALLOWED`, the symbol constants, `is_passing_effect`, the `BEHAVIORS` test list and the floor folder lists in the tests. Never reorder or reformat existing lines.
- **New code goes in new files.** A hazard rule and its node are new files. Change `player.gd`, `enemy.gd` and `room_view.gd` only by adding small hooks, such as one call or one property.
- **Off-limits in Step 2:**
  - `scripts/scenes/floor_scene.gd` and `scripts/core/progress_data.gd`, which Step 1 owns.
  - The Waiting Room files, which Step 3 owns.
  - `tools/smoke_driver.gd`, except one path-specific check, if one is needed, in a new function added at the end.
- **Test file prefixes:** cruise `cruise`, golf `golf`, airport `airport`, office `office`.

## Step 1: The connection

### Task 1: Depths 4 and 5, landings, Crossroads, end of run, dev keys

This follows the skill's `plan-template.md` Task 1, done for two depths at once.

- **Create:**
  - `data/floors/landing_4.tres` and `landing_5.tres`.
  - `data/floors/last_resort_cruise.tres` and `fairways_end.tres` (depth 4), and `terminal_zero.tres` and `head_office.tres` (depth 5), as placeholders:
    - Use an existing `rooms_dir` and the floor-3 enemies and bosses.
    - Use the spec's real numbers: `depth`, `open_after_depth`, `clears_to_open`, `danger` (5/6/7/8), `closed_hint`, `health_mult`, `pension_mult`, `enemies_by_size`, `chest_weights` and `treasure_pension`.
    - Give each placeholder its real `display_name`.
  - `tests/test_deep_floor_unlocks.gd`, modelled on `tests/test_third_floor_unlocks.gd`, covering both depths.
- **Modify:**
  - `floor_scene.gd`: set `PATHS_BY_DEPTH[4]` and `[5]`, `LAST_DEPTH := 5`, and `LANDINGS_BY_DEPTH[4]` and `[5]`.
  - `progress_data.gd`: set `FIRST_PATH_BY_DEPTH` and `PATHS_AT_DEPTH` for 4 and 5.
  - The Crossroads sign drawing, if it can't show 5 to 8 skulls: draw a number beside one skull.
- **Make the full loop generic.**
  - `tools/smoke_driver.gd` walks every depth from 1 to `LAST_DEPTH` using `PATHS_BY_DEPTH`, rather than naming three floors. Each later path step then gets its coverage for free.
  - At each depth it checks the landing name and heal, and that the east path refuses before a clear at that depth and opens after one.
  - "A boss ends the run" moves to depth 5.
  - Raise `TIMEOUT` to fit, then measure and report the new run time.
- **Dev keys:**
  - In `scripts/core/dev_start.gd`, add a start depth parameter. F3 starts depth 3, F5 depth 4 and F6 depth 5. Each unlocks the paths above it, with every upgrade at max.
  - Wire the keys in `scripts/autoload/game.gd` and the Waiting Room's key handling, wherever F3 is handled.
  - Update `tests/test_dev_start.gd` and `_check_dev_start`, which names `landing_3` literally.
  - Update the DEV hint text to list F3, F4, F5 and F6, and keep it fitting the screen (`tests/test_lobby_text.gd`).
- **Careful:** don't add the placeholder paths to the six-path lists in the Waiting Room tests (bounties, mementos, departments, letters). Step 3 does that once the real bosses exist.
- **Verify:**
  - Tests show 0 failed.
  - 2 full loops pass in copies on D:, and you report their run time.
  - The real save's MD5 is unchanged.
- **Push** `deep-floors`.

## Step 2: One complete path per agent (2a to 2d, in parallel)

Each path agent works in its own worktree:

```bash
cd /c/GameDev/game && git worktree add -b deep-<x> .worktrees/deep-<x> origin/deep-floors
```

It then does the skill's `plan-template.md` Tasks 2 to 6 for its path:

- **Task 2:** the hazard.
- **Task 3:** three new enemies and two returning ones.
- **Task 4:** the mini boss.
- **Task 5:** the floor boss.
- **Task 6:** the content: palette, props, about 33 layouts, and the real FloorDef replacing the placeholder.

Each agent follows its own section of the spec and the parallel rules above, commits often and pushes its branch.

**Per path, before calling it done:**

- Tests show 0 failed.
- 2 full loops pass in copies on D:, with the copy names unique to the path (`GrandpaSmoke<x>A`, `GrandpaSmoke<x>B`) so parallel agents never collide.
- Screenshots of every attack, the hazard, each prop and enemy, and small, medium and large rooms, taken in a real window.
  - Write the probe at `tools/probes/<x>_look.gd`, modelled on `floor3_look.gd`.
  - Write the PNGs to `D:/grandpa-verify-<x>/shots/`.
  - Open each one with the Read tool and fix anything that doesn't read.
- Measure income per full clear with and without blasting using `tools/probes/income_probe.gd`, adapted to the path.
- Write a short summary in `docs/superpowers/plans/deep-<x>-notes.md`. It covers what was built, the test count, the loop times, the income and any open decisions.
- The real save's MD5 is unchanged.

The window check matters even more with four agents. Any agent that sees the user playing waits before opening a real window. Headless tests and loops can still run.

**Per-path facts the template needs:**

| | Cruise | Golf | Airport | Office |
|---|---|---|---|---|
| path id | `last_resort_cruise` | `fairways_end` | `terminal_zero` | `head_office` |
| depth | 4 | 4 | 5 | 5 |
| last depth's mini bosses to beat | Reverend 640, Gloria 640 | same | the floor-4 minis (about 760) | same |
| last depth's floor bosses to beat | Mortimer 1700, Santa 1650 | same | the floor-4 floor bosses (about 1950) | same |
| returning enemies from | Sunset Shores / Furnace Works | same | Parlour / Mall | same |

The floor-5 agents can't read the floor-4 bosses' numbers while they're being built in parallel. Compare against the spec's targets in their tests: mini 880 against 760, floor 2250 against 1950. The coordinator re-checks against the real values after merging.

## Merge (coordinator)

Merge `deep-cruise`, `deep-golf`, `deep-airport` and `deep-office` into `deep-floors` in that order:

- Resolve list conflicts by keeping every side's entries.
- After each merge, run the tests.
- After the last merge, run 3 full loops and push.

## Step 3: Waiting Room hooks

### Task 7

This follows the skill's `plan-template.md` Task 7 for all four paths, plus the spec's section 7:

- **Departments:**
  - Add a corridor department that is open from the start and reached through an existing one.
  - Add the four new departments, linked from it.
- **The Bon Voyage Bag:** a start-of-run consumable, applied where a run starts (`Progress.make_run` / `RunState`).
- **Three new upgrades** with their merchants: Golf Glove, Frequent Flyer Miles and Golden Handshake. They use the existing `UpgradeDef` and merchant patterns. Frequent Flyer Miles applies where run shop prices are worked out. Golden Handshake applies where boss Pension is paid.
- **Mementos:** four new ones, with their perk constants:
  - `SLIDE_PERK` "slide_half"
  - `CHARGE_PERK` "charge_power"
  - `LANDING_PERK` "landing_pill"
  - `BOSS_DAMAGE_PERK` "boss_damage"

  Also add their trophy wall frames. 10 frames must still clear the north door and lanterns.
- **Wanted posters:** eight new ones, plus their extras:
  - 4 cosmetics in `data/cosmetics/`.
  - Life Jacket and Neck Pillow as `from_bounty` items.
  - Lucky Tee and Golden Parachute as recipes.
  - A Coach tip for each new item and recipe.
  - Update the 4/4/4 test to 6/6/8.
- **Letters:** four new ones.
- **Lines:**
  - Dolores gets a take line for each new poster in `data/npcs/deputy_dolores.tres`.
  - Each new NPC gets lines with the opener rotation and its moments.
- **The ending card:** shown the first time the Chairman is beaten, behind a new optional save field `ending_seen`.
- **Tests to extend:** the six-path lists (bounties, mementos, departments, letters, dev start) become ten-path lists.
- **Verify:**
  - Tests show 0 failed and 2 full loops pass.
  - Take screenshots with F4: the new corridor and departments, the trophy wall with all 10 frames, the bounty panel with 20 posters (it must scroll and keep its Leave button), and the ending card.

## Step 4: Balance, review, report

- **Task 8, balance:** the skill's `checklist.md` section 4 for all four paths. Compare against floor 3, and floor 5 against floor 4. Record changes in `docs/playtest-notes.md`.
- **Task 9, review:** the skill's `checklist.md` section 5, over `git diff origin/waiting-room...deep-floors`, against the spec. Fix the confirmed findings, then run the tests and 3 full loops again.
- **Task 10, report:**
  - Write `docs/night-report-<date>.md` in the shape of `docs/night-report-2026-11-04.md`.
  - Move the user's play copy to the final commit only when they're not playing, then run `--headless --import` in it.
  - Stop for the user to play. Don't merge.
