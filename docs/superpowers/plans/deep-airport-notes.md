# Departures, Terminal Zero: build notes (Step 2c)

Branch `deep-airport`, off `deep-floors` at 16a57f4. Written on 2026-11-04 while testing was on hold.
**Nothing here has been parsed or run by Godot**: no test, import, `--check-only`, full loop, probe or
screenshot. New scripts have no `.uid` files until the first import. Nothing that needs Godot is ticked.

## What was built

- **Hazard, queue barriers (`=`).** `BarrierCycle` (pure: 10 s period, 1 s chime, 3 s up; `faster`
  halves the period and the time up but keeps the whole chime; `push_out`) and `QueueBarrier` (one
  node per cell). Down, a taped line with post bases; chiming, it flashes; up, posts and a red rope.
  The rope's body is a `StaticBody2D` on layer 16 (`QueueBarrier.LAYER`), which only Grandpa's
  collision mask and his dentures' ray test (`ThrownDentures.BLOCKED_BY`). Enemies, their shots, their
  warned lanes and the walk grid never see it (`=` is not solid). A rope rising under his feet moves
  him just clear of it, to the open side nearer his feet, no damage. Every barrier of a room shares
  one clock. `take_control(RISE or DROP)` chimes 1 s, then holds 5 s, then the timer starts again
  down, so no rope ever rises unwarned. `validate()` gained `BARRIER_DOOR_CLEARANCE = 2` and
  `_barrier_errors()`: with every barrier up, every door, every must-reach cell and every open cell
  must still be reachable, so a barrier line can never fence anything in.
- **Enemies.** Tour Group (pack, group of 3: the guide carries a flag and runs the clock, every member
  warns of a lane the guide's way and they rush together; with the guide gone the followers say
  "Where did they go?" and wander slowly, never rushing again). Baggage Handler (charger: luggage cart
  down a warned lane, smashing props, dazed for 0.9 s when it hits a wall head on). Lost Luggage
  (ambusher: lies still until Grandpa is within 72 px, then a bite warned whole, radius 34, then stays
  awake). Returning: `airport_weeping_mourner` and `airport_mall_cop`, old numbers, new colours.
- **Mini boss, Sergeant Wanda, Airport Security.** 880 final health (338.462). X-ray sweep: a beam the
  height or width of the room crosses it after a 0.6 s windup and 1.2 s warning, sparing one marked
  safe spot (a `SafeSpotMark`) within 120 px of him, off her body and off barrier cells. Tray toss: 4
  trays on warned spots, 0.15 s apart. Summons Lost Luggage, at most 3 at a time under a cap of 5.
  She alternates her two attacks; rest 0.45 s.
- **Floor boss, Augustine, Head of Departures.** 2250 final health (865.385). Boarding stamp: the
  3-pill attack, 1.2 s shown whole, radius 46, second ring and a growing stamp shadow. Runway lights:
  5 lanes of 40 px around him, warned 0.9 s each, lit 0.25 s one after another 0.35 s apart. Gate
  change (only with barriers in the room, every 8 s at most): every barrier rises if most are down,
  drops if most are up, after their own chime. Phase two (half health): 1.2x speed, 0.8x windups but
  never the stamp's, rest 0.4 s, Tour Groups up to 3 under a cap of 5, barriers cycle twice as fast,
  and **once** a runway pattern chains straight into the stamp.
- **Content.** Props `6` luggage trolley (barrel), `7` suitcase stack (blocks nothing, like grass),
  `8` row of departure seats (rock, can hide a coin at the furniture rate). Decor kind
  `departure_board`. Palette: navy carpet (`floor_pattern = 1`, a pale blue diamond motif), steel
  walls (`wall_pattern = 0`), cool fill light, 3% flicker, decor boards, fluorescents and plants.
  33 layouts in `data/rooms/terminal_zero/` in the floor-3 mix with 8/10/15 enemy cells, barriers in
  25 rooms (16 and 48 cells in the floor boss rooms), 4 chest cells. The FloorDef keeps Step 1's id,
  depth, locks, danger and numbers, with enemy weights 3, 3, 4, 3, 2.

## Files

New:
- `scripts/core/barrier_cycle.gd`
- `scripts/world/queue_barrier.gd`, `terminal_props.gd`, `terminal_marks.gd`, `terminal_strike.gd`,
  `xray_sweep.gd`, `runway_lane.gd`, `terminal_decor.gd`, `luggage_trolley.gd`, `departure_seats.gd`,
  `suitcase_stack.gd`
- `scripts/actors/behaviors/tour_group.gd`, `tour_group_behavior.gd`, `baggage_handler_behavior.gd`,
  `lost_luggage_behavior.gd`, `security_sergeant_behavior.gd`, `head_of_departures_behavior.gd`
- `data/enemies/tour_group.tres`, `baggage_handler.tres`, `lost_luggage.tres`,
  `airport_weeping_mourner.tres`, `airport_mall_cop.tres`, `sergeant_wanda.tres`, `augustine.tres`
- `data/rooms/terminal_zero/` (33 files)
- `tests/test_airport_hazard.gd`, `test_airport_enemies.gd`, `test_airport_bosses.gd`,
  `test_airport_floor.gd`

Changed: `data/floors/terminal_zero.tres` (placeholder replaced). Shared files, each with an
airport-commented addition at the end of its list (see "For merging").

## For merging: shared files touched

| File | Where |
|---|---|
| `scripts/content/room_layout.gd` | new constants `SYMBOL_BARRIER`, `BARRIER_DOOR_CLEARANCE`, `SYMBOL_LUGGAGE_TROLLEY`, `SYMBOL_SUITCASES`, `SYMBOL_SEATS` after `SYMBOL_SALE_SIGN`; `=678` at the end of `ALLOWED`, `68` of `SOLID_SYMBOLS`, `8` of `WALLS_AND_BOMB_ONLY`, `7` of `DECOR_SYMBOLS`; in `validate()` one barrier clearance check after the strip check, and `errors.append_array(_barrier_errors())` after the door loop; `_barrier_errors()` and `barrier_runs_across()` at the end of the file |
| `scripts/world/room_view.gd` | `or child is XRaySweep or child is RunwayLane` as the last line of `is_passing_effect` (plus a comment line above the function); `TerminalProps.build(self, layout, palette)` at the end of `_create_props` |
| `scripts/actors/player.gd` | `_ready`: `collision_mask = 1 \| Hole.LAYER \| QueueBarrier.LAYER`; `_throw_teeth`: the spawn ray uses `ThrownDentures.BLOCKED_BY` |
| `scripts/actors/thrown_dentures.gd` | new `const BLOCKED_BY` after `WALL_LAYER`; `_fly`'s ray uses it |
| `scripts/world/enemy_marks.gd` | one line after the mark `match`: `TerminalMarks.draw_mark(self, _def.mark, half)` |
| `scripts/world/decor_layer.gd` | one line at the end of `_draw_placeholder`: `TerminalDecor.draw_placeholder(self, kind, variant, p)` |
| `scripts/content/room_decor.gd` | `const DEPARTURE_BOARD` after `FLUORESCENT` |
| `tests/test_enemy_types.gd` | a comment above `BEHAVIORS` and the five airport behaviors on the list's last lines |
| `tests/test_chests.gd`, `tests/test_shop.gd` | `terminal_zero` added at the end of the folder list (on its own line) |
| `tests/test_arcade_room.gd` | `terminal_zero.tres` as the last entry of `FLOORS` |
| `LESSONS.md` | two lines at the end |

Not touched: `floor_scene.gd`, `progress_data.gd`, Waiting Room files, `tools/smoke_driver.gd`,
`room_backdrop.gd`, `room_palette.gd`. **No new floor or wall pattern number** is used (the
coordinator offered 14): the airport reuses `floor_pattern = 1` and `wall_pattern = 0`, so nothing in
`room_backdrop.gd` can clash. Prop colours are constants in the prop scripts, not palette fields.

## Owed checks, for when testing resumes

1. **Import** once (`--headless --path . --import`): 17 new `class_name` scripts. If anything fails,
   `--check-only --script` each new script, then the hooked files above.
2. **Tests:** `tools/test.ps1` to 0 failed. The new files: `test_airport_hazard.gd`,
   `test_airport_enemies.gd`, `test_airport_bosses.gd`, `test_airport_floor.gd`. Touched and must still
   pass: `test_enemy_types.gd` (windup lengths of the 5 new behaviors), `test_chests.gd`,
   `test_shop.gd`, `test_arcade_room.gd`, `test_boss_spawn_room.gd` (checks Wanda 32x40 and
   Augustine 44x52 in these rooms), `test_stage2_props.gd` (player masks), `test_deep_floor_unlocks.gd`
   (Terminal Zero's numbers are unchanged), `test_crossroads.gd`.
3. **Full loops:** 2 runs in `git archive` copies on D: named `GrandpaSmokeAirportA`/`B`. The generic
   depth walk clears Terminal Zero on the west run. No airport-specific smoke check was added. Watch
   for the full loop teleporting Grandpa onto a raised rope (it would be pushed out by physics) and
   for arrival flakes like the Parlour's.
4. **Screenshots in a real window** (only when the user is not playing), probe
   `tools/probes/airport_look.gd` modelled on `floor3_look.gd`, PNGs in `D:/grandpa-verify-airport/shots/`:
   - the barriers down, chiming (flash) and up, **on the palest tile** (`floor_b`), in a large room,
     with the HUD over floor; a rope rising under Grandpa, and where he ends up;
   - each enemy: the Tour Group with the guide's flag, its warned rush, followers scattered; the
     Baggage Handler's lane and cart, and its daze; Lost Luggage lying and biting;
     the airport Mourner and Mall Cop colours;
   - Wanda: the X-ray beam's start lane with chevrons, the beam sweeping, the green mat; the tray
     marks and their landing;
   - Augustine: the stamp's two rings and shadow (above all), the DEPARTED ink, the runway lanes
     waiting, warning and lit, a gate change chime, phase two with Tour Groups and fast barriers;
   - each prop (trolley, seats, suitcases) and the departure boards;
   - small, medium and large rooms next to the Funeral Parlour's.
5. **Balance and income:** the balance bot on both bosses and whole floors against the floor-4 bosses
   once merged; `tools/probes/income_probe.gd` adapted, with and without blasting. Expectation only:
   the floor has 659 seat cells (the Parlour 781 pews) and 39 trolleys (16 hymn carts), and every
   enemy pays ceil(1 x 3.0) = 3.
6. **Loops to watch:** enemies stuck on seats (they route through the walk grid); Tour Group
   followers catching up round seat rows; Wanda's summons landing on barrier cells (harmless).

## Risky spots

- **Collision layer 16** is new for the whole game. If another path also picked 16, merge must
  change one. `Player`/`QueueBarrier`/`ThrownDentures` now refer to each other (a constant in
  `ThrownDentures.BLOCKED_BY` depends on `QueueBarrier.LAYER`): if Godot reports a cyclic reference,
  write `1 | 16` there with a comment.
- **`TerminalStrike` overrides `_draw` and calls `super()`**, and reads GroundStrike's `_delay`,
  `_landed`, `_show_left`.
- **`TerminalProps` calls RoomView's underscore helpers** (`_place_prop`, `_on_barrel_broken`,
  `_on_rock_broken`, `_on_vase_broken`, `_prop_coin_roll`) from outside; GDScript allows it, but a
  rename there breaks this file.
- **The X-ray sweep** spares only the mat (or a dodge). The mat is always within 120 px (1 s walk)
  of him and the beam moves after 1.8 s, but whether it reads in time needs a real look.
- **The push-out** moves Grandpa up to about 12 px; if both sides are blocked it uses the nearer,
  and physics settles the rest.
- **Floor-4 comparisons** use the spec's 760 and 1950, not real files; re-check after merging.

## Open decisions

- **Phase-two chain:** "chains once" is implemented as exactly one runway-to-stamp chain per fight,
  not one after every runway pattern. Easy to change in `HeadOfDeparturesBehavior.followup`.
- **Lost Luggage** stays awake after its first bite (it never lies down again).
- **Scattered tourists** are harmless and pay nothing (followers never pay), but must still be beaten
  to clear the room.
- **No airport floor or wall pattern** of its own (merge safety); a dedicated pattern (number 14)
  could come with the art pass.
- **Departure boards** stand on the floor as decor, not in the walls.
- **Colours** were moved for the navy carpet: Baggage Handler green, Lost Luggage teal, Augustine
  magenta.
