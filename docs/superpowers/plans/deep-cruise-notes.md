# The Last Resort Cruise: build notes

Step 2a of `2026-11-04-floors-four-and-five.md`, on branch `deep-cruise` (off `deep-floors`). It is the
spec's section 3, built as the add-floor skill's Tasks 2 to 6.

**Nothing here has been run.** Testing was on hold (SKILL.md rule 11) for the whole step: no Godot in
any form, not even `--headless --import` or `--check-only`. Every test below is written but has never
been parsed. The only checks made were a Python port of `RoomLayout.validate()` over the layouts and
careful rereading. New scripts have no `.uid` files until the first import, which is expected.

## What was built

**The hazard: the ship rolls.**
- `ShipRoll` is the pure rule: every 9 s the deck lies quiet, then a 1.5 s horn, then a 2 s slide at
  70 px/s, to port or starboard only. The side of each roll is fixed by the room's seed. An offset from
  the seed keeps rooms out of step.
- `ShipDeck` is the node, one per room whose layout has `ship_rolls = true`.
  - It draws a big arrow 62 px above Grandpa's feet with "HOOONK!" while the horn sounds, and faint
    chevrons across the deck that drift with the slide.
  - It slides Grandpa's walk (never his dodge), every walker (`Enemy.slides_with_roll()`), and loose
    pickups. A pickup only slides onto open floor that is clear of door cells. Chests, wares, items
    for sale and flying coins never slide.
  - Bosses never slide, and nor does a running charge (`hold_lane`), a ghost, a mound or anything
    bolted to a wall.
  - Within 80 px of any door cell the deck holds steady, so nobody is carried through a door and the
    arrival check never sees a slide.
  - `force_roll(side, horn, seconds, speed)` is the Commodore's order. It sounds the same horn with an
    orange arrow, then slides harder.
- 22 of the 33 layouts roll: every combat, boss and side room, `healing_01` and `item_large_01`.

**Regular enemies** (weights 3, 4, 3, 3, 2):
- **Early Bird Diner** (pack, like the Seasonal Temp: 15 hp, pays 1, groups of 3, at most 2 groups).
  - Tables of three shuffle at speed 45.
  - The leader rings a 0.9 s dinner bell, shown whole on every member with its own lane.
  - Then all three rush at 250 px/s to where Grandpa stood plus 30 px, between 60 and 160 px.
  - `DinnerBell` keeps the table's clock, as `MourningPack` does.
- **Shuffleboard Shark** (ranged, like the Filing Clerk: 30 hp).
  - He keeps 120 to 220 px away and winds up for 0.7 s.
  - A `ShuffleboardPuck` marks its whole way during the windup: the lane out, a ring at the bounce
    and the lane back.
  - It bounces once off the first wall or solid prop (ray mask 1), stops at the second thing it meets,
    and slides at 250 px/s for at most 420 px.
- **Sunburnt Sunbather** (ambusher, like the Plot Holder: 46 hp).
  - He lies drawn as a deck chair (red stripes where the deck's chairs are blue, as the tell) and holds
    his lane so the roll never moves him.
  - He wakes within 64 px or when hit, with a 0.6 s snap of radius 34 shown whole.
  - Then he brawls with melee rules.
- **Returning:** `cruise_orderly` (the Night Shift Orderly, white) and `cruise_stoker` (the Night
  Stoker, amber), with the old numbers and marks.

**Lorraine, Cruise Director** (mini boss, `lorraine.tres`, 345.455, so 760 final; speed 72, pays 8,
rests 0.5 s):
- **Conga line:** a 0.6 s windup, then four `DeckLane` rows of dancers in Mortimer's five procession
  slots, with one gap that moves each time and lanes that turn each time. Each lane is warned for
  1.0 s, then the row crosses at 260 px/s. A `SafeSpotMark` marks the gap level with Grandpa.
- **Karaoke shockwave:** a 0.8 s warned cone, 60° and 150 px, offered only within 170 px. It costs
  1 pill.
- **Quoit toss:** three `QuoitRing`s, one on Grandpa and two around him, at least 50 px apart and inside
  the room. Each is warned for 1.5 s and costs 1 pill on landing. It then lies 3 s and slows him
  (0.5, refreshed every frame he stands inside).
- **Summon:** Early Bird Diners every 10 s (the first at 5 s), at most 3 at a time, with at most 5
  enemies in the room. They pay nothing.
- She never calls the same attack twice running.

**Commodore Wellington** (floor boss, `commodore_wellington.tres`, 886.364, so 1950 final; speed 78,
pays 16, rests 0.6 s and 0.42 s):
- **Anchor drop** (the 3-pill attack): an `AnchorDrop` locked under Grandpa, warned for its whole
  1.2 s with a second ring 8 px out and a growing shadow. It has radius 46, and phase two never
  shortens it.
- **Foghorn:** a 0.9 s warned lane, 84 px wide and up to 340 px long. It costs 2 pills and shoves
  Grandpa back, and a `FoghornBlast` shows it.
- **"Hard to port":** a 0.5 s windup, then every deck in the room gets `force_roll` with the ship's own
  1.5 s horn and a 2.5 s slide at 154 px/s, faster than Grandpa walks. He uses it at most every 11 s
  (the first after 6 s), and only in a rolling room, so he falls back to the foghorn elsewhere.
- **Lifebuoys:** three `DeckLane` rows 96 px apart, one level with Grandpa, warned for 1.6 s. Each ring
  rolls across the room at 300 px/s and costs 1 pill.
- **Phase two** (half health):
  - 1.2× speed and 0.8× windups, except the anchor.
  - Every 8 s, "Swab the decks!": two warned jets that leave 3×3 wet patches for 5 s. They reuse the
    Mall's `splash_cells`, `splash_patch` and `WetSplash`.
  - The anchor drops twice in a row, each drop warned in full (`followup`, `ANCHORS_IN_A_ROW = 2`).
- He calls nobody.

**Content.**
- **Symbols:** `b` deck chair (a `Barrel`, breaks to the cane, drops what a bone pile drops), `0` buffet
  tray (blocks nothing, breaks to anything), `1` pool (a `Hole`: never broken, shots fly over), and
  `2` lifeboat davit (a `RockBlock` that can hide a coin at the furniture rate).
- **Palette:** golden teak planks `floor_pattern = 10` (`RoomBackdrop.FLOOR_TEAK_DECK`), a navy hull
  with a white ship's rail `wall_pattern = 10` (`WALL_SHIP_RAIL`), moonlight fill, warm string lights
  (the lantern decor), a 4% flicker, and a bright blue wet floor so the Commodore's patches read on the
  planks.
- **33 layouts** in `data/rooms/last_resort_cruise/`, in the floor-3 mix: 7 medium, 3 large and 3 small
  combat rooms with 9, 14 and 7 enemy cells, and every other room type. Chests sit in six combat
  rooms. Pools are in 18 rooms, the shapes are the cruise's own, and the only symbols used are
  `#.EIHTBCSPl` and `b012`.
- **The FloorDef** names the cruise's enemies, bosses, palette and rooms, and keeps Step 1's depth-4
  numbers: 2.2, 2.5, 7/9/14, the chest row and a treasure of 20.

## Files

**New scripts:**
- `scripts/core/ship_roll.gd`
- `scripts/world/ship_deck.gd`
- `scripts/world/cruise_props.gd`
- `scripts/world/cruise_marks.gd`
- `scripts/world/shuffleboard_puck.gd`
- `scripts/world/deck_chair.gd`
- `scripts/world/buffet_tray.gd`
- `scripts/world/pool_water.gd`
- `scripts/world/lifeboat_davit.gd`
- `scripts/world/deck_lane.gd`
- `scripts/world/quoit_ring.gd`
- `scripts/world/anchor_drop.gd`
- `scripts/world/foghorn_blast.gd`
- `scripts/actors/behaviors/dinner_bell.gd`
- `scripts/actors/behaviors/early_bird_diner_behavior.gd`
- `scripts/actors/behaviors/shuffleboard_shark_behavior.gd`
- `scripts/actors/behaviors/sunbather_behavior.gd`
- `scripts/actors/behaviors/cruise_director_behavior.gd`
- `scripts/actors/behaviors/commodore_behavior.gd`

**New data:**
- `data/enemies/early_bird_diner.tres`
- `data/enemies/shuffleboard_shark.tres`
- `data/enemies/sunburnt_sunbather.tres`
- `data/enemies/cruise_orderly.tres`
- `data/enemies/cruise_stoker.tres`
- `data/enemies/lorraine.tres`
- `data/enemies/commodore_wellington.tres`
- `data/rooms/last_resort_cruise/` (33 files)

**New tests:**
- `tests/test_cruise_hazard.gd`
- `tests/test_cruise_enemies.gd`
- `tests/test_cruise_bosses.gd`
- `tests/test_cruise_floor.gd`

**Replaced:** `data/floors/last_resort_cruise.tres`, the placeholder.

## Shared files touched, for the merge

Every change is an added block commented "The Last Resort Cruise", except where a line had to change.

| File | Where | What |
|---|---|---|
| `scripts/content/room_layout.gd` | after `SYMBOL_STUMP` | `DECOR_SYMBOLS` line changed to `... + "0"`, with a comment above |
| `scripts/content/room_layout.gd` | after `SYMBOL_SALE_SIGN` | four `SYMBOL_*` constants added; `ALLOWED`, `SOLID_SYMBOLS`, `WALLS` and `WALLS_AND_BOMB_ONLY` lines changed to `old + "b012"`, `+ "b12"`, `+ "1"` and `+ "12"` |
| `scripts/content/room_layout.gd` | end of the exports, after `strips_reverse` | `@export var ship_rolls: bool = false` |
| `scripts/actors/enemy.gd` | `_physics_process`, after the strip carry | two lines adding `ShipDeck.slide_at` |
| `scripts/actors/enemy.gd` | before `hold_lane()` | new `slides_with_roll()` |
| `scripts/actors/player.gd` | `_handle_movement`, after the strip carry in the walk branch | one comment and one line |
| `scripts/world/room_view.gd` | end of `_create_props` | `CruiseProps.build(self, layout, palette)` |
| `scripts/world/room_view.gd` | first lines of `is_passing_effect` | `if CruiseProps.is_passing_effect(child): return true` |
| `scripts/world/room_backdrop.gd` | after `OVERDRAW_MARGIN` | `FLOOR_TEAK_DECK := 10`, `WALL_SHIP_RAIL := 10` |
| `scripts/world/room_backdrop.gd` | wall branch, after the shutter block | the rail pattern |
| `scripts/world/room_backdrop.gd` | floor branch, after the mall tile block | the teak pattern |
| `scripts/world/enemy_marks.gd` | end of the `match`, after `"elf_hat"` | one case for five marks, drawn by `CruiseMarks` |
| `tests/test_enemy_types.gd` | `BEHAVIORS` | the last line now ends with a comma, then five cruise behaviors |
| `tests/test_chests.gd` | `test_shipped_rooms_still_hold_chest_cells` | a loop over the cruise folder |
| `tests/test_shop.gd` | `_shops()` | a loop over the cruise folder |
| `tests/test_arcade_room.gd` | `FLOORS` | the cruise floor at the end |
| `LESSONS.md` | end | three lessons |

Merge cautions:
- The pattern numbers are 10 on purpose. If another path also used 10, renumber one of them, or both
  patterns will draw.
- If two paths both changed the same `const ... :=` line, keep both appended literals. The order does
  not matter.
- Not touched: `floor_scene.gd`, `progress_data.gd`, the Waiting Room files, `room_palette.gd`,
  `room_decor.gd`, `decor_layer.gd`, `tools/smoke_driver.gd`, `test_stage2_props.gd` (the cruise's
  stored-room test is in `test_cruise_bosses.gd`) and `deep-floors-untested.md`.

## Owed checks, for when testing resumes

First check that no game window is open and take the real save's MD5, as `checklist.md` says.

1. **Import:** run `--headless --path . --import` once. Expect new `.uid` files for the 19 new scripts
   and 4 new tests, and the 40 new `.tres` files imported for the first time.
2. **Parse errors:** if anything fails, check each new script with `--check-only --script <path>`,
   starting with the files most likely to break:
   - `ship_deck.gd`: it calls `feet()` on a `Node2D`, as `Enemy.target_ground` does.
   - `cruise_props.gd`: it calls RoomView's underscore methods `_place_prop`, `_on_pile_broken`,
     `_on_vase_broken`, `_on_rock_broken` and `_prop_coin_roll`, and reads `_room` and `_player`.
   - `commodore_behavior.gd`: it binds a static `_wet`, as the Fountain Diva does.
   - `room_layout.gd`: its constants are now concatenations.
   - `enemy_marks.gd`: its new `match` case has several patterns.
3. **Tests:** `tools/test.ps1` should end "N tests, 0 failed".
   - The four `test_cruise_*` files are new.
   - These changed and must pass: `test_enemy_types` (BEHAVIORS), `test_chests`, `test_shop`,
     `test_arcade_room` (1000 seeds of the cruise for the 20 to 30% arcade rule),
     `test_boss_spawn_room` (it now checks Lorraine and the Commodore in the real rooms) and
     `test_deep_floor_unlocks` (the real cruise def).
   - Watch the source-reading test `test_a_dodge_holds_grandpa_and_only_his_walk_slides`, which
     searches `player.gd` for exact text.
4. **Full loops:** run 2 in `git archive` copies on D: named `GrandpaSmokeCruiseA` and
   `GrandpaSmokeCruiseB`.
   - The generic walk clears the cruise at depth 4 on the west run.
   - Watch for a door bounce, a pickup sliding into a wall, and Grandpa sliding during a door step.
   - No path-specific smoke check was added.
5. **Screenshots in a real window,** only when the user is not playing. Write the probe at
   `tools/probes/cruise_look.gd`, modelled on `floor3_look.gd`, and put the shots in
   `D:/grandpa-verify-cruise/shots/`. Open each one:
   - **The roll:** the horn arrow and "HOOONK!" over Grandpa on the palest plank (`floor_c`, in a
     large room), the chevrons, a slide in progress, and the orange arrow of a forced roll.
   - **Each prop:** the deck chair, the buffet tray, the pool (rim and ripples), the davit with its
     lifeboat, and the teak planks beside the Commodore's wet patch, which must not look alike.
   - **Each enemy:** a Diner table with its bell lanes, the Shark's puck lanes with the bounce ring,
     the Sunbather asleep beside real deck chairs and his snap, and the Orderly and Stoker in their
     cruise colours.
   - **Lorraine:** the conga lanes with the gap mark, the karaoke cone, quoits falling and lying.
   - **The Commodore:** the anchor warning above all (both rings and the shadow), the foghorn lane and
     blast, the lifebuoy lanes and rolling rings, the swab jets and the double anchor.
   - **Rooms:** a small, a medium and a large room with enemies in, beside the Parlour's. Also the HUD
     over the planks in a large room.
6. **Income:** run `tools/probes/income_probe.gd`, adapted to the cruise, with and without blasting.
   - The Parlour paid about 258 and 271.
   - The cruise holds one more enemy per room, and a 1-Pension enemy pays `ceil(2.5) = 3`, not 2, so
     expect roughly 1.5× the Parlour: about 380 to 420 without blasting.
   - Davits (143 across the folder) hide coins at the furniture rate, so blasting adds little.
   - If it runs far over, lower the cruise's enemy pay before anything else.
7. **The real save's MD5** must be unchanged.

## Risky spots to look at first

- **CruiseProps and RoomView's private methods.** GDScript allows the calls, but a rename in RoomView
  breaks them silently until a cruise room loads.
- **Pickups on the rolling deck.** Only a pickup's centre cell is checked, so a coin can rest half over
  a solid neighbour. `_check_pickups_off_solids` tests the centre, as this does.
- **A forced roll at 154 px/s** cannot be walked against. Grandpa must dodge or ride it. With a wet
  patch it may feel unfair. That is a balance-bot question.
- **The Sunbather never wakes** if Grandpa stays away, so the room cannot be cleared from afar. This is
  as the mimic works. A thrown denture wakes him.
- **Puck bounces off solid props as well as walls,** since the ray uses mask 1. That reads fine, but
  check one in the screenshots.
- **The quoit's slow** is refreshed every frame he stands inside, at 0.3 s each time, so stepping out
  frees him almost at once.
- **`ShipDeck._draw` follows Grandpa,** so in a large room the arrow stays on screen. If it ever draws
  off screen, check the camera rule.
- **Lorraine's gap mark** is skipped when the spot under it is not open on the walk grid.

## Open decisions for the user

1. **The horn makes no sound.** Sounds are played by `combat_feedback.gd` from scene signals, and
   wiring one needs a hook outside the cruise's files. It shows "HOOONK!" instead.
2. **The Sunbather's chair has red stripes** where real deck chairs have blue, as his one tell, the way
   the mimic breathes. The other choice is identical chairs and no tell.
3. **Deck chairs drop what a bone pile drops** (a coin now and then), not barrel drops, because there
   are about ten times as many as any floor's barrels.
4. **No new decor kinds.** String lights use the lantern decor, and the buffet tables use the mall's
   `food_table`, `bench`, `plant` and `puddle`. Lifebuoys appear only in the Commodore's attack and on
   the davits' boats. Real string-light and lifebuoy decor can come with the art pass.
5. **Which rooms roll:** the shop, vaults, treasures, secrets, two item rooms and the small healing
   room stay still (11 of 33).
6. **Returning enemies keep their old display names,** "Night Shift Orderly" and "Night Stoker", as
   floor 3's did.
7. **Commodore Wellington has no title** in his display name, since the spec gives none. Lorraine is
   "Lorraine, Cruise Director".
