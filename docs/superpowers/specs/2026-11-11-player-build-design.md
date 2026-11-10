# Player Build: Design

**Date:** 2026-11-11
**Status:** the user's decisions of 2026-11-11 (after the outside review). Plan: docs/superpowers/plans/2026-11-11-player-build.md.
**Goal:** a build for 5-10 real players that teaches its controls in the first run, shows its hook (room rules and flashbacks) on every floor, and gives Harold hurt, death and dodge animations.

Out of scope: any enemy, damage or health tuning on floor 1 ("keep it as hard as now"); a tutorial room; unlocking eras through endings; the Memories page.

## A. The first ten minutes

### A.1 Control tips during the first run
- One short line at a time, bottom centre of the screen (Hud tip label, rect 120,292 to 520,308, font 8, the notice's colours, behind no other HUD text). It names the bound key or pad button through `KeyBindings`, like every prompt: "LMB: Swing the cane".
- A tip shows when it is needed and goes the moment the player has done the thing. Doing the thing before its tip shows also counts.
- Each tip is done once per save (`ProgressData.tips_done`, saved at once). A done tip never shows again.
- Not shown in a dev run (`Progress.is_dev_run()`), during a rule announcement, or while the run is over.

| Id | Shows when (first that applies, in this order) | Text (`tr()`; key by `KeyBindings.with_key`) | Done when |
|---|---|---|---|
| `rule` | a rule is posted in this room and its announcement is over | "Keep the room's rule for a film reel. Break it and the Auditor comes." (no key) | that room's rule state ends (kept, broken-and-cleared or lifted) |
| `reel` | he holds a reel, outside a fight | flashback: "At a door to a new fight: relive a memory." | an era starts |
| `move` | always (the first room) | "WASD: Walk" (the four move labels; "Left stick: Walk" on a pad) | his feet have moved for 0.6 s in all |
| `swing` | the room is fighting | attack: "Swing the cane. Three swings make a combo." | a swing starts |
| `dodge` | fighting, and `swing` is done | dodge: "Dodge. It's not running away. It's tactical." | a dodge starts |
| `throw` | fighting, and `dodge` is done | throw: "Throw the teeth. They come back. Usually." | a throw (teeth or an era's throw) |
| `charge` | fighting, and 4 or more swings this run | attack: "Hold to charge a big swing." | a charged swing lands or misses |
| `potion` | he holds a potion and is below full pills | potion: "Drink your potion." | a potion is drunk |
| `interact` | in an item, shop or treasure room | interact: "Pick up, open, talk." | interact is pressed |
| `thermos` | he holds a Thermos, outside a fight, after a room has cleared | bomb: "Put down a Thermos. It blows up rocks and cracked walls." | a Thermos is placed |
| `map` | a room has cleared, outside a fight | map: "Open the map." | map is pressed |

- Text reuses Coach Bertram's first-visit lines where they fit. `CoachTips` and the Training Yard are not changed.
- **Old saves:** a save loaded without a `tips_done` key and with `run_count > 0` gets every tip marked done (its player is past the first ten minutes). A new save has none done.
- **Options:** the Game tab gains a button row "Show control tips again". It clears `tips_done` for the open save and saves; the button then reads "Tips will show again" and is disabled until the panel is reopened. With no save loaded it is disabled.

### A.2 Attack warnings on by default
- `GameSettings.DEFAULTS[GAME]["attack_warnings"]` becomes `true`.
- **An existing settings file** keeps what it holds: `save_to` writes every key, so a file saved before this build holds `attack_warnings=false` and stays off. Only a machine with no settings file (every new player) starts with warnings on. The user's own machine keeps them off until he switches them on in Options.
- `AttackWarnings.shown` stays `false` as a static default. The Settings autoload sets it from the settings at start, as today, so the tests keep their current starting state.

### A.3 The opening
- Today each press shows the next of seven cards (seven presses). Add a skip: `pause` (Esc), the pad's Back action (`PadInput.BACK_ACTION`, B) or `ui_cancel` ends the opening at once (`Game.finish_opening()`).
- The hint becomes "Click or press Space to continue. Esc to skip." (through `tr()`, and naming the bound keys via `KeyBindings.label_for` for `dodge` and `pause`).
- The opening's "Harold, 87" stays (born 1942, died 2029: no contradiction).

### A.4 Floor 1
Unchanged: no enemy, damage, health, room or reward tuning.

## B. The hook everywhere

### B.1 Rules on every floor
- `RulePicker.ENABLED_DEPTH` goes from 1 to 99 (every depth). The table stays: depth 1: 1 rule room; depth 2: 2; deeper: `max(2, round(0.4 x combat rooms))`; never more than the floor's combat rooms; By the Book's `extra` on top.
- Only `TYPE_COMBAT` rooms other than the start room, as today: never boss, mini-boss, shop, item, treasure, healing, secret, vault, arcade, side, crossroads or landing rooms.
- `RunState.rules_posted()` is then true on every floor, so rules and memory items are offered on every floor.

### B.2 The first run meets the hook early
- When the save's `run_count <= 1` (its first run) and it is not a dev run, the first rule room of each floor is drawn from the first three combat rooms on the floor's main path (`FloorMap.main_path` order, start room excluded). Other rule rooms (depth 2+) are drawn as today from the rest.
- Later runs place rule rooms exactly as today (same seed, same rooms).
- A resumed checkpoint keeps its saved rule rooms.

### B.3 Each rule on every floor
| Rule | Can it fail to make sense deeper? | Fix |
|---|---|---|
| Leave Canes at Reception | no: every enemy takes teeth, era moves and Thermos hits | none |
| No Horseplay | no: holes stop dodges and walks alike, no room needs a dodge to finish | none |
| Keep Your Teeth In | no | none |
| No Explosives | only picked when he holds a Thermos (today) | none |
| No Food or Drink | only picked when he holds a potion (today) | none |
| Do Not Touch the Exhibits | only picked where a cane-breakable `BreakableBlock` stands (today); reinforced rocks and secret walls don't count | none |
| No Loitering | **yes**: red tape (`Player.is_taped`) and the Polyester Suit's spark (`is_self_stunned`) hold his feet still against his will, so the 2.5 s could run out while he is held | time held counts as moving: the still-timer resets while `Player.is_held_still()` |

A cruise deck sliding him counts as movement, which only makes No Loitering easier there. Accepted.

### B.4 The Auditor on deep floors
- **Already done:** he spawns through `RoomView._spawn_enemy`, so his health and Pension take the floor's `health_mult` and `pension_mult` like every enemy: health 160 / 224 / 288 / 352 / 416 at depths 1-5 (cursed runs on top), Pension 3 x the floor's rate. Enemy damage is 1 pill everywhere in the game, so his stays 1.
- **New, deeper only:** his attack cooldowns shorten with depth so a floor-4 Auditor presses as hard as that floor's regulars: `cooldown_mult(depth) = clamp(1 - 0.06 x (depth - 1), 0.76, 1.0)`, i.e. 1.0 / 0.94 / 0.88 / 0.82 / 0.76. Windups (0.5 s swing, 0.6 s throw) never shorten, so his warnings read the same. Depth 1 is exactly as today.
- Obeying still pays a film reel (and the kept-rule events and counts as today) on every floor.

### B.5 Four eras
Born **1942**. Every era's age is its year minus 1942 (`Eras.age(id)`); the 1975 era's stored age 40 was wrong and goes.

| | Football on the Rec, 1960 | The Dance Hall, 1962 | The No. 12 Bus, 1975 | The Allotment, 1988 |
|---|---|---|---|---|
| id / art | `rec_football_1960` / `harold_1960` | `dance_hall_1962` / `harold_1962` | `no12_bus_1975` / `harold_1975` | `allotment_1988` / `harold_1988` |
| Age | 18 | 20 | 33 | 46 |
| Pace (x old Harold) | 1.25 (today) | 1.1 | 1.0 (today) | 1.0 |
| Attack | 3-kick combo 6/6/12, reach 34, half-angle 70, lock 0.12 | **spin**: one hit all round, 9, reach 30, half-angle 180, push 40, lock 0.14 | punch 25, reach 46, half-angle 50, lock 0.42 | **spade thrust**: 30, reach 64, half-angle 15, push 110, lock 0.5 |
| On paper DPS (cane 63.3) | 66.7 (x1.05) | 64.3 (x1.02), but hits every enemy in reach | 59.5 (x0.94) | 60.0 (x0.95), heaviest single hit |
| Dodge | spin turn, hits 5 | **slide**: 1.3 x as long, hits 3, push 30 | barge, hits 8, stun 0.2 | **handle shove**: hits 6, push 120 |
| Throw | football, bounces 3 | **a 45 record**: flies straight, passes through, 7 a hit, 200 px, cooldown 1.5 s | ticket roll line, cooldown 2.5 s | **a marrow**: lobbed 150 px, 14 to the one it hits and 14 to every enemy within 24 px where it stops, cooldown 2.0 s |

- On-paper bands follow the existing test: a combo era 1.0-1.2 x the cane; a one-heavy-hit era 0.75-1.0 x the cane with its hit above every cane hit. In play each lands about 15% above old Harold (the bot's `eras` mode measures it, as for the first two).
- The 45 record is a dark disc with a lighter label circle; the marrow a green ellipse with a darker stripe along it. No crossing strokes.
- All four are unlocked from the start. `Eras.STARTING` holds all four, and loading any save always adds the starting eras (`Eras.known_or_starting` returns the starting four plus any other known saved ones), so an existing save gains the two new ones.
- Bomb and potion as old Harold. Items that change the cane or dentures don't touch an era's moves (as today).
- **Missing art:** an era whose `idle` strip is missing draws old Harold's sprite tinted (1962 `f0c8e8`, 1988 `c8e0b0`), as the first two did before their art.

## C. Harold's feedback animations
| Anim | When | Length | Without its strip |
|---|---|---|---|
| `hurt` | a hit lands and he lives | 0.25 s, once | today's red flash only |
| `death` | the finishing hit; holds its last frame | 0.9 s; the game-over message waits for it | no wait, today's look |
| `dodge` | a dodge starts | the dodge's own length | today's ghost copies |

- Each anim plays only when the shown art has that strip (`SpriteVisual.has_anim(art, anim)`). `SpriteVisual` would otherwise fall back to the attack strip, so the check is in Player.
- The red flash and the hit's invulnerability blink stay with the hurt anim.
- During the death anim his sprite keeps animating though the scene disables him (the visual alone runs `PROCESS_MODE_ALWAYS` from then on).
- With a dodge strip the ghost copies stop for that art; eras without a dodge strip keep the ghosts.
- Cardigan outfits: `tools/art/harold_outfits.py` recolours every base strip that exists, new ones included. An outfit without a strip falls back to today's look.
- **Art:** PNG frames in `D:\grandpa-art\harold\<set>\<anim>\`, read with that folder's `notes.md` (frame counts, directions). East-facing frames only (the game flips for west). `tools/art/harold_anims.py` places every frame on the 60 px canvas with his feet on row 52 (as `harold_strips.py` does) and joins them into `art/sprites/<set>/<anim>.png`. Sets: `grandpa` (hurt, death, dodge), `harold_1960` and `harold_1975` (dodge), `harold_1962` and `harold_1988` (idle, walk, attack, dodge).

## D. The player build
- Merge `jukebox-music` and the finished `new-items` (the controller merges), then the full suite, the full loop and the bot in the renamed copy, then the zip by `docs/release/build-steps.md`.
- Godot's import and export of the build copy (named Grandpa) run with `APPDATA` pointed at `D:\grandpa-build\appdata` (export templates joined in), so nothing lands in the real user folder; the folder's listing is compared before and after.
- The real exe is never started by an agent. A second, renamed export (`GrandpaPlayerWalk`) carrying a walk probe is started instead: title, opening, lobby, first rooms; it checks the frame draws and music plays, and quits.

## Testing
- Unit tests for: tip order and conditions, old-save tip migration, tip reset; opening skip; settings default; rule counts on every depth; early rule room on a first run; No Loitering while held; Auditor cooldown by depth and health by floor; four eras' data, ages, numbers, throws and unlocks; feedback anim choice with and without strips; death wait time.
- The full loop and the bot must pass with rules on every floor.
