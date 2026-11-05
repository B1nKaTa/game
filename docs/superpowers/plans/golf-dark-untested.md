# Fairway's End at Midnight: what has not been run yet

On 2026-11-05, with testing on hold, the floor-4 east path `fairways_end` was restyled from dusk to
midnight on `round-2`: the same course, mechanics, layouts, numbers and sand rule, under a darker,
colder light. **Nothing here has been parsed, imported or run by Godot.** No tests, no loop, no probe,
no screenshots. The colour checks were worked by hand with a Python copy of each test's formula
(below). No new scripts, so no new `.uid` files.

## What changed

Commits: `107af47` fog decor kind, `983cb30` prop drawings, `4602fcc` midnight palette and enemy
colours with the new tests, `412b8d7` the name, and the commit holding this file.

- **Name:** "Fairway's End Golf Club" -> "Fairway's End Golf Club at Midnight" (FloorDef,
  `Departments.FLOOR_NAMES`, `test_deep_floor_unlocks` NAMES, `test_golf_floor`). It shows on the
  Crossroads sign, both maps and the Pro Shop's closed-door hint.
- **Light** (`data/floors/fairways_end.tres`):
  - `ambient` (0.58, 0.5, 0.56) -> (0.3, 0.34, 0.52)
  - `torch`, the wall lights, now moonlight: (1, 0.7, 0.4) -> (0.5, 0.62, 0.9)
  - `fill_light` (1, 0.72, 0.55) -> (0.6, 0.7, 1). Fill lights are still in every room.
  - `lantern_light` (1, 0.8, 0.5) -> (1, 0.74, 0.42), the only warm light. `lantern` is unchanged.
  - `darkness` (0.04, 0.03, 0.06) -> (0.01, 0.02, 0.04). `flicker` is unchanged at 0.03.
- **Ground and walls:**
  - `floor_a` (0.36, 0.56, 0.3) -> (0.26, 0.5, 0.36), `floor_b` (0.33, 0.52, 0.28) ->
    (0.24, 0.46, 0.34), `floor_c` (0.38, 0.58, 0.32) -> (0.28, 0.52, 0.38)
  - `fairway_stripe` (1, 1, 0.85, 0.08) -> (0.8, 0.9, 1, 0.07)
  - `wall` (0.13, 0.42, 0.16) -> (0.05, 0.18, 0.1), `wall_line` (0.55, 0.8, 0.45, 0.35) ->
    (0.3, 0.5, 0.4, 0.25), `carpet_motif` (the hedge wall's top) (0.7, 0.95, 0.55, 0.35) ->
    (0.4, 0.6, 0.5, 0.25)
  - `grass` (0.5, 0.75, 0.38) -> (0.36, 0.62, 0.5), `grass_cut` (0.4, 0.62, 0.3) ->
    (0.26, 0.46, 0.36), `bench` (0.55, 0.38, 0.24) -> (0.42, 0.34, 0.28)
  - **Sand, grain and shine are unchanged**, as are the sand rule and its door clearance.
- **Props:**
  - `hedge` (0.18, 0.42, 0.2) -> (0.08, 0.21, 0.12), `hedge_leaf` (0.25, 0.54, 0.25) ->
    (0.13, 0.3, 0.18)
  - `golf_cart` (0.93, 0.91, 0.85) -> (0.72, 0.74, 0.72), `golf_cart_roof` (0.25, 0.48, 0.29) ->
    (0.16, 0.3, 0.2)
  - `flag_cloth` (0.85, 0.27, 0.23) -> (0.8, 0.82, 0.86), `flag_pole` (0.96, 0.95, 0.9) ->
    (0.66, 0.64, 0.6)
  - `ball_washer` (0.23, 0.44, 0.69) -> (0.35, 0.55, 0.92). The old blue fell to 0.337 against the
    new `floor_a` in the debris test, under its 0.4.
  - Drawings: the flag pin's pole is crooked and its pennant tattered. Hedges and hedge walls grow
    stray shoots. The washer's towel stripe takes `golf_cart_roof`, since the pennant cloth is
    pale now. Collision boxes are untouched.
- **Fog:** a new decor kind `RoomDecor.FOG` (two faint level wisps, lines only) and palette field
  `fog` = (0.75, 0.82, 0.95, 0.14). Its weight is 2.0, and `decor_density` goes from 0.06 to 0.081, so
  grass, benches, plants and lanterns keep their old expected counts (0.06 x 3/5.6 = 0.081 x 3/7.6).
- **Enemy colours** (flavour, names and numbers unchanged):
  - Gopher (0.62, 0.44, 0.26) -> (0.74, 0.6, 0.44)
  - golf Soot Ghost (0.55, 0.5, 0.78) -> (0.6, 0.5, 0.9). It now has saturation 0.44, so the Caddie
    is the floor's only pale body (the cruise's rule).
  - Fairweather (0.22, 0.3, 0.68) -> (0.32, 0.42, 0.86)

## The colour checks, worked by hand

"Lit" means colour x (ambient + fill_light x `Lighting.FILL_ENERGY`), at a fill's centre, clipped at
white. "Wall" adds `torch`, as in Head Office's test.

| Check (test) | Rule | Dusk | Midnight |
|---|---|---|---|
| floor_a against the 6 older floors | > 0.15 | min 0.225 | min 0.178 (cemetery) |
| wall against the 6 older floors | > 0.15 | min 0.197 | min 0.167 (funeral parlour) |
| sand against stripes and tones | > 0.3 | 0.594 | 0.677 |
| sand against grain | > 0.25 | 0.664 | 0.664 |
| sand b / r | >= 0.8 | 0.826 | 0.826 |
| debris: flag, washer, hedge, cart | > 0.4 | 0.570, 0.423, 0.407, 0.832 | 0.769, 0.545, 0.482, 0.598 |
| enemies against the grass (unlit) | >= 0.25 | pass | pass |
| enemies told apart | >= 0.25 or size gap >= 12 | pass | pass |
| **new:** palest stripe at a wall light | peak < 1 | 0.878 | 0.737 |
| **new:** lit warning red against lit sand | >= 0.4 | 0.475 | 0.442 |
| **new:** lit warning red against the lit darkest grass | >= 0.3 | 0.528 | 0.332 |
| **new:** lit enemies against lit grass | >= 0.22 | min 0.243 | min 0.236 (Gopher) |
| **new:** pale bodies (s < 0.4) | <= 1 | 2 | 1 (Caddie) |
| **new:** fog alpha | <= 0.2 | - | 0.14 |

For scale, the Records Basement's light gives lit grass a luminance of about 0.23 and a lit warning
0.30 against its floor. Midnight's lit grass is 0.23 to 0.26, so the course is about as dark as the
first floor, and much darker and colder than the dusk's 0.35 to 0.39. Lit sand turns from a warm hue
of 20 degrees to a moonlit blue of 224 degrees, far from the warning's 342.

The test pinned to the old name (`test_fairways_end_is_the_locked_fourth_floor_path_with_its_own_rooms`)
was updated, since its rule (the path is named so) still holds. No other test pinned a dusk value.

## Owed when testing resumes

1. **Import, then the tests:** `test_golf_floor` (six new tests), `test_golf_enemies` (the Soot
   Ghost's colour still differs from the original's), `test_golf_bosses`, `test_golf_hazard`,
   `test_deep_floor_unlocks`, `test_departments`, `test_stage2_props`, `test_crossroads`, then the
   whole suite.
   - Check that `fog` in the `.tres` loads as the new `RoomPalette.fog`, and that the decor layer
     draws fog without errors.
   - The hedge's `for shoot: Array in [...]` loop and the flag's concave 7-point pennant polygon:
     `draw_colored_polygon` prints an error and draws nothing if it can't triangulate.
2. **Screenshots in a real window** with `tools/probes/golf_look.gd`, against the old dusk shots in
   `D:/grandpa-verify-golf/shots/`:
   - Every room size with enemies in, and a large room with the HUD over the palest stripe.
   - **Red warnings on sand and on the darkest grass, far from any fill light** (lit at ambient only
     the lane fill is just 0.09 to 0.12 from the ground). Chip's chip spots, the hole in one's rings,
     the bunker spread and the Caddie's lane above all.
   - **The Gopher** (lowest lit contrast, 0.236), its mound in a dark corner, and **Fairweather's
     navy** in phase two.
   - **Hedges in the dark corners:** a hedge is 0.15 from the grass at ambient alone. Hedge walls
     against the room's darkness.
   - The flag pin's crooked pole and pennant, the hedge shoots (do they read as overgrowth or as
     noise?), and the fog: faint, never a lane, never a sand patch.
   - **Sand under a wall light** turns a pale cyan (0.85, 0.98, 1.0). Check pale things on it: the
     flag's pennant, the Caddie, debris.
   - Lantern pools: are they warm against the blue and do they leave warnings readable?
   - Is it creepy enough, or too dark? The first knobs to turn are `ambient` and `fill_light`.
3. **Text fit:**
   - The 35-character name on the Crossroads east sign (centred, font 11), and on the mini map's
     top row, right-aligned from x 636 at font 9. That is about as long as "Head Office, Eternity
     Incorporated", which is already there at depth 5, but check that it clears the HUD counters.
   - The Pro Shop hint "Opens when Fairway's End Golf Club at Midnight is cleared" in the Annexe.
4. **Not done, and could come later:** the "300 years on the back nine" line has no cheap slot. The
   open sign shows only the name, the closed hint is shared by depth and pinned, and the lobby letter
   comes from the living world. There is no clubhouse-window decor either: the wall lanterns stand
   in for the lit windows.
