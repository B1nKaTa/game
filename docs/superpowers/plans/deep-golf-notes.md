# Deep golf: Fairway's End Golf Club at Dusk, notes

Step 2b of `2026-11-04-floors-four-and-five.md`: the floor-4 east path, `fairways_end`, built on
`deep-golf` off `deep-floors`. **Testing was on hold the whole time.** Nothing here has been parsed,
imported or run by Godot: no tests, no full loop, no probes, no screenshots. New scripts have no
`.uid` files yet. The layouts were checked with a Python port of `RoomLayout.validate()` (see below).

## What was built

- **Hazard, sand bunkers (`s`).** Anyone walking on the floor wades at 0.6 of their speed. Grandpa
  can't start a dodge in sand, though a dodge he started before stepping in carries on. Sand and a
  sedative together never leave him under `SlowEffect.MIN_FACTOR`. Sand never hurts, and ghosts,
  mounds and wall fixtures never touch it. Bosses wade too. It is drawn as a pale bed of dark and
  bright grains. It stays 2 cells off doors (`SAND_DOOR_CLEARANCE`, checked in `validate()`).
- **Regular enemies:**
  - **Caddie** (charger, debt-ghost numbers): shows a warned lane (0.8 s), drives his cart down
    it at 300 px/s, smashing props and holding the lane, stops at walls, then rests 0.8 s.
  - **Club Golfer** (ranged, filing-clerk numbers): keeps 120 to 210 px away, shouts "FORE!", and
    drives 3 balls down a warned 30° fan (0.8 s).
  - **Gopher** (ambusher, plot-holder numbers): burrows as a mound, rises under Grandpa under a
    ring warned for its whole 0.8 s, bites, sits up for 1.6 s, then burrows again.
  - **Returning:** `golf_bingo_caller` (sky blue) and `golf_soot_ghost` (lavender), with the old
    numbers.
  - Weights 3, 4, 3, 3, 2.
- **Chip, Club Pro** (mini boss, `chip`, 760 final, 345.455 in the `.tres`):
  - **Chip shot:** 4 balls lob onto spots round Grandpa, one on him, each warned 0.9 s and landing
    0.12 s apart.
  - **Putt:** a ball rolls a curve that breaks 70 px to one side, the whole curve marked for 0.7 s.
  - He alternates the two, and calls 2 Gophers at a time, never past 5 enemies. Rest 0.5 s.
- **Club President Thaddeus Fairweather** (floor boss, `thaddeus_fairweather`, 1950 final,
  886.364, body 46x52):
  - **Hole in one:** a giant ball drops on a spot under Grandpa, warned whole for 1.2 s with a
    second ring, for 3 pills.
  - **Cart charge:** a 0.9 s warned lane, 400 px/s, 2 pills, through `BossDash`.
  - **Sprinkler sweep:** a 150 px jet turns 270° round him in 1.5 s. The red sector and turn arrow
    show for the windup, and the dry quarter behind him is edged green.
  - **Bunker spread:** 3 warned 3x3 patches (1.0 s) turn to sand for 8 s.
  - **Phase two:** 1.2x speed, 0.8x windups except the hole in one, rests 0.6 then 0.42. He calls
    up to 3 of his own Caddies every 9 s, and each cart charge chains into a bunker spread.
- **Props:**
  - Flag pin (`3`): blocks nothing, breaks to anything.
  - Ball washer (`4`): a `Barrel`.
  - Hedge (`5`): a `RockBlock` that can hide a coin. A `5` with no orthogonal `5` beside it is a
    `ParkedCart` instead (`GolfProps.is_parked_cart`). There are 33 carts and 237 hedge cells.
- **Look:**
  - Floor pattern 13: mown stripes two columns wide, with no dots, so it shares no shape with sand.
  - Wall pattern 13: clipped hedges.
  - Dusk light: a mauve ambient and a warm orange fill. Decor is grass, benches, plants and
    lanterns.
  - Mark drawings live in `GolfMarks`.
- **33 layouts** in `data/rooms/fairways_end/`, in the floor-3 mix: 7 medium, 3 large and 3 small
  combat rooms with 9, 14 and 7 `E`, 3 rooms with `C`, sand in 28. The shapes are new: a dogleg
  hedgerow, sand-ringed greens, hedge stubs, a terrace with a hedge U, crosses, a round hedge, a
  slanted long fairway, the eighteenth green and a driving range.
- **FloorDef:** `data/floors/fairways_end.tres` replaced. The id, depth, locks, danger,
  multipliers, room sizes, chests and treasure 20 are kept.

## Commits (deep-golf)

`440e4d1` sand · `32fbae6` returning pair · `83ca638` three enemies · `96b3ae7` Chip ·
`6040e6d` Fairweather · `3e28818` props and look · `3ffb6c8` 33 layouts · `cf84865` FloorDef,
floor test and shared test folders · `b63c5cd` patterns moved to 13 · `b0ff187` sprinkler accessor
rename · and the commit holding this file.

## Files added

- `scripts/core/sand_rule.gd`
- `scripts/world/`: `sand_trap.gd`, `bunker_patch.gd`, `golf_props.gd`, `golf_look.gd`,
  `golf_marks.gd`, `golf_ball_shot.gd`, `golf_ball_lob.gd`, `putt_roll.gd`, `giant_ball_drop.gd`,
  `sprinkler_sweep.gd`, `flag_pin.gd`, `ball_washer.gd`, `hedge.gd`, `parked_cart.gd`
- `scripts/actors/behaviors/`: `caddie_behavior.gd`, `club_golfer_behavior.gd`,
  `gopher_behavior.gd`, `club_pro_behavior.gd`, `club_president_behavior.gd`
- `data/enemies/`: `caddie.tres`, `club_golfer.tres`, `gopher.tres`, `golf_bingo_caller.tres`,
  `golf_soot_ghost.tres`, `chip.tres`, `thaddeus_fairweather.tres`
- `data/rooms/fairways_end/*.tres` (33 rooms)
- `tests/`: `test_golf_hazard.gd`, `test_golf_enemies.gd`, `test_golf_bosses.gd`,
  `test_golf_floor.gd`

## Shared files touched, and where (for merging)

Each change is a small block, commented "Fairway's End".

- `scripts/content/room_layout.gd`:
  - New constants `SYMBOL_SAND`, `SAND_DOOR_CLEARANCE`, `SYMBOL_FLAG`, `SYMBOL_BALL_WASHER` and
    `SYMBOL_HEDGE`, just before `ALLOWED`.
  - `ALLOWED` ends `...azdqes345`, `SOLID_SYMBOLS` ends `...q45`, `WALLS_AND_BOMB_ONLY` ends `...q5`
    and `DECOR_SYMBOLS` ends `...ce3`.
  - A sand clearance check in `validate()`, right after the strip check.
- `scripts/content/room_palette.gd`: a new `@export_group("Fairway's End")` after
  `scatter_lights`, holding `sand`, `sand_grain`, `sand_shine`, `fairway_stripe`, `hedge`,
  `hedge_leaf`, `golf_cart`, `golf_cart_roof`, `flag_cloth`, `flag_pole` and `ball_washer`.
- `scripts/actors/player.gd`:
  - In `_handle_movement`: `var sunk := is_in_sand()`, the dodge condition gains
    `SandRule.can_dodge(sunk) and`, and the speed line becomes
    `SandRule.slowed(_slow.speed_factor(), sunk)`.
  - A new `is_in_sand()` after `is_slowed()`.
- `scripts/actors/enemy.gd`: three lines after `velocity = desired_velocity + _knockback` in
  `_physics_process`: `if SandTrap.slows(self): velocity -= ...`.
- `scripts/world/room_view.gd`:
  - The last line of `is_passing_effect` gains `or GolfProps.is_passing_effect(child))`.
  - `GolfProps.build(self, layout, palette)` at the end of `_create_props`.
- `scripts/world/room_backdrop.gd`:
  - Wall branch: an `if _palette.wall_pattern == GolfLook.HEDGE_WALL` block before its
    `continue`.
  - Floor branch: an `if _palette.floor_pattern == GolfLook.FAIRWAY` block after the Mall's
    pattern-3 block.
  - Both use 13, as the coordinator asked (the cruise has 10, Head Office 12).
- `scripts/world/enemy_marks.gd`: one match arm after `"elf_hat"`:
  `"caddie_bib", "golf_cap", "gopher_teeth", "pro_visor", "boater": GolfMarks.draw_mark(...)`.
- `tests/test_enemy_types.gd`: the last two lines of `BEHAVIORS` are the five golf behaviors, with
  a comment line under the list.
- `tests/test_chests.gd` (`test_shipped_rooms_still_hold_chest_cells`) and `tests/test_shop.gd`
  (`_shops`): a separate loop over `res://data/rooms/fairways_end/` after the existing loop.
- `tests/test_arcade_room.gd`: `FLOORS` gains `"res://data/floors/fairways_end.tres"` as its last
  entry.
- `data/floors/fairways_end.tres`: rewritten. It was the Step 1 placeholder.

Not touched: `floor_scene.gd`, `progress_data.gd`, the Waiting Room files and
`tools/smoke_driver.gd`. I added no path-specific smoke check: the generic walk covers the path,
and an untested driver change could break every loop.

## Owed when testing resumes

1. **Import** (`--headless --import`) for the new `.uid` files, then fix any parse errors. Check
   these scripts one by one: `sand_trap.gd`, `bunker_patch.gd`, `golf_props.gd`,
   `sprinkler_sweep.gd`, `club_president_behavior.gd` (the `CaddieBehavior.Cart` inner-class type),
   `golf_ball_lob.gd` and `giant_ball_drop.gd` (the `super._draw()` overrides of `GroundStrike`), and
   `golf_ball_shot.gd` (overriding `Projectile._draw`).
2. **Tests:**
   - `test_golf_hazard`, `test_golf_enemies`, `test_golf_bosses`, `test_golf_floor`
   - plus `test_enemy_types`, `test_boss_spawn_room` (it now checks Fairweather's 46x52 box in the
     golf boss rooms), `test_chests`, `test_shop`, `test_arcade_room`, `test_deep_floor_unlocks`,
     `test_stage2_props`, `test_mall_hazard` and `test_room_layouts`
   - The whole suite should read "N tests, 0 failed".
3. **Two full loops** in `git archive` copies on D: (`GrandpaSmokeGolfA`, `GrandpaSmokeGolfB`).
   - The second run takes the east path at depth 4, so it clears Fairway's End.
   - Watch for the bot pressing dodge while in sand, which now does nothing.
   - Watch the fourth-floor boss choice and the stairwell.
4. **Screenshots in a real window**, with the probe at `tools/probes/golf_look.gd`, into
   `D:/grandpa-verify-golf/shots/`:
   - Every attack: the Caddie's lane and cart, the golfer's fan and balls, the Gopher's ring, mound
     and bite, Chip's chip spots and lobbed balls and his putt curve and cup, the hole in one's double
     ring and falling ball (above all), the cart charge lane and cart, the sprinkler's red sector,
     arrow, green dry quarter and jet, and the bunker patches' warning, then their sand.
   - The hazard: layout sand and spread sand side by side with the striped fairway, and sand on the
     palest tile (a light stripe) in a large room with the HUD over floor.
   - Every prop: flag pin, ball washer, hedge run, parked cart, and debris colours.
   - Every enemy, the bosses' marks (visor, boater) and the boss bar's name, which is long:
     "Club President Thaddeus Fairweather".
   - Small, medium and large rooms next to Mall rooms, with enemies in.
   - The dusk palette: check that the warm fill light doesn't wash the grass or hide the pale sand
     (lesson of 2026-11-03).
5. **Loops to watch:** a Caddie or Fairweather charging through sand ends early, which is by
   design. A gopher must never stay underground forever, or the room can't finish.
6. **Income probe** (`tools/probes/income_probe.gd`, adapted): a full clear with and without
   blasting, against floor 3's 258 and 271.
   - Hedges hide coins at the furniture rate over 270 cells, fewer than the Mall's 781.
   - Ball washers are barrels.
   - So blasting should pay a little less than on the Mall.
7. **Balance bot:** Chip against the Reverend and Gloria, and Fairweather against Mortimer and the
   Santa, on the "some" and "max" saves. Teach the bot the sand: no dodge in it, slower in it.

## Risky spots

- **Calls into `RoomView` internals.** `GolfProps.build` calls `_place_prop`, `_prop_coin_roll` and
  the `_on_*_broken` handlers. It works in GDScript, but it breaks if those are renamed.
- **The sand slow and charges.** It scales `desired_velocity` after the behavior tick, so a sand
  cell under a charging boss shortens the dash (`BossDash` counts down by its own speed). It never
  turns a charge.
- **Spread sand under the player:** it stops dodges for 8 s. The hole in one and the cart lane are
  tested to leave time to wade out, but not against a gopher bite while wading.
- **`test_in_an_open_room_three_whole_patches_come_and_the_first_is_under_him`** depends on Godot's
  RNG with seed 6 finding 3 patches in 40 tries. If it fails only on the count, try another seed or
  more tries rather than changing the rule.
- **`test_there_is_always_somewhere_dry_within_a_walk`** allows one cell of slack. A corner case
  could still fail on a seed; read the distance it prints.
- **The test reads source text.** `test_the_player_and_enemies_read_the_sand` checks the hook text
  in `player.gd` and `enemy.gd`. A merge that reformats those lines will fail it; update the strings
  then.
- **A stale comment.** The header comment of `tests/test_deep_floor_unlocks.gd` still says the paths
  borrow floor-3 content. I left it, since it isn't my file.

## Decisions I made (open to change)

- Sand slows to 0.6, and bosses wade too.
- A lone hedge cell is a parked cart, since only 3 prop symbols were allowed for 4 props.
- Hedges and carts hide coins at the furniture rate. The flag pin holds nothing, like grass.
- Fairweather's phase-two followup is cart charge into bunker spread. Chip has no phase two.
- Lanterns are used generously for dusk: 60 wall cells over 33 rooms.
- Boss ids are `chip` and `thaddeus_fairweather`. Their wanted posters and the memento (Step 3)
  must use these ids.
