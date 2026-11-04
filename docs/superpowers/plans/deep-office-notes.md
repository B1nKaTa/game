# Deep floors, Step 2d: Head Office, Eternity Incorporated

Branch `deep-office`, built off `deep-floors` in `.worktrees/deep-office` on 2026-11-04. This is the
skill's `plan-template.md` Tasks 2 to 6 for the fifth floor's east path, the game's last.

**Nothing here has been run.** Testing was on hold by the user's order the whole time: no Godot in
any form, not even `--headless --import`. Every script, test and layout is written but unparsed, and
no plan step that needs Godot is ticked. The only check made was a Python port of
`RoomLayout.validate()` over the 33 layouts (see "Layouts" below). New scripts have no `.uid` yet.

## What was built

**Hazard: red tape (`x`).** Walking into tape holds Grandpa in place for 0.6 s, once each time he
steps onto tape from clear floor, so he then walks on through. A dodge is never held, frees him from a
hold, and cuts every tape cell under his feet for 6 s (cut cells hang slack, then are strung again).
Enemies ignore it (it is not solid, so the walk grid is open, and `enemy.gd` never names it). No
damage. It draws as a red band with white diagonal hatching and dark edges, running along its row or
down its column as its strand does. Kept 2 cells off every door by its own `RED_TAPE_DOOR_CLEARANCE`
check in `validate()`. The rule is `RedTapeRule`, the cell is `RedTape`, and a `TapeSpread` lays
warned, temporary tape for the Chairman.

**Regular enemies** (weights 3, 4, 3, 3, 2):
- **Yes-Man** (pack, `group_size` 3, 15 hp). Each closes in from its own side and makes a short
  warned lunge (0.55 s, shown whole, 24 px lane). A `YesMenChorus` (through metadata, as
  `WalkerLine`) tells the other two, which start the same warned lunge 0.3 s later. An echo never
  leads another, and a member busy with its own lunge skips the copy.
- **Paper Shredder** (charger, 36 hp). Warned 0.75 s lane, 230 px charge that stops at solids and
  holds its lane, dropping a short `PaperTrail` (at most 6 scraps, lasts 3 s) that slows Grandpa
  35% while he stands in it and never hurts.
- **HR Representative** (ranged, 30 hp). Keeps 130 to 210 px away and throws memos at warned spots
  near him. Each `WriteUpMark` lands as a warned spot does (1 pill, breaks props), then lies 3.5 s and
  stings 1 pill after he has stood in it 0.6 s straight, and again each 0.6 s he stays.
- **Returning:** `office_florist.tres` and `office_perfume_sprayer.tres`, the old numbers, sizes,
  marks and behaviors in the office's colours.

**Mini boss: Doreen, Executive Assistant** (`doreen`, 338.462 hp, so 880 final). Memo storm: three
warned lanes (48 px, 1.0 s warning, staggered 0.15 s) across the room's whole height or width, one on
Grandpa and one a 40 px gap to each side, kept inside the room (`LaneDrop`). Hold music: a dotted red
spiral shows for her 0.55 s windup, then 3 arms of 7 slow notes (90 px/s) turn out 0.3 rad a step
(`HoldMusic`, new `Projectile.LOOK_NOTE`). She alternates the two. Summons Yes-Men (3 at a time) every
9 s, never past 5 enemies in the room; summons pay nothing. Rest 0.5 s, as the Reverend's.

**Floor boss: The Chairman of the Board** (`chairman_of_the_board`, 865.385 hp, so 2250 final, body
44x52, no summons).
- **Gavel:** the 3-pill attack (`Enemy.HEAVIEST_DAMAGE`), 1.2 s windup in both phases, warning
  shown whole on him, and a `GavelStrike` (a `GroundStrike` with a second ring and a gavel shadow).
- **Quarterly projections:** bars 64 px wide with 40 px gaps across the whole room, rising in turn
  (0.9 s warning each, 0.3 s apart, either way round) and standing 0.35 s, hurting once. The gap
  nearest Grandpa is marked with a `SafeSpotMark`, kept off his body.
- **Hostile takeover** (only when Grandpa is 130 px or more away): a `TakeoverTether` and a warned
  lane show for the whole 0.9 s windup. A dodge in that time snaps it and the attack ends. Otherwise
  he is pulled through `Player.push` (240 px/s for at most 0.3 s, never nearer than 60 px), which
  slides against walls and holes and which a dodge breaks, then a fresh 0.75 s warned lane and a
  2-pill `BossDash` charge.
- **Phase two** (half health): 1.2x speed, 0.8x windups except the gavel, rest 0.6 to 0.42 s. Every
  16 s red tape spreads along three rows (his row and 3 rows each side) for 10 s after a 1.0 s
  warning, off walls, props and 2 cells off doors. Every projection chains straight into one gavel.

**Look.** Floor pattern 4, carpet tiles (a seam and dark flecks, no lines, so the tape stands out);
wall pattern 4, plaster over a darker dado with a chair rail and skirting; beige floor
(0.66, 0.6, 0.46) and taupe walls (0.5, 0.45, 0.38), bright cool office light; decor: fluorescent
panels, potted plants, and two new kinds, `ficus` and `office_chair`.

**Props.** Water cooler `9` (a `Barrel`), cubicle wall `N` (a `RockBlock`, coin at the furniture
rate), in-tray `y` (blocks nothing, breaks to anything). Their colours are constants in their own
scripts, so `RoomPalette` gained no fields.

**Layouts.** 33 in `data/rooms/head_office/`, in the floor-3 mix: 7 medium (10 E), 3 large (15 E),
3 small (8 E) combat rooms, 2 mini boss, 2 floor boss, 3 item, 2 healing, 2 treasure, 3 side,
2 secret, 3 vault and 1 shop. Shapes of their own: cubicle pods, a glass meeting room with taped
doors, a comb of desks, partition corridors, corner offices, taped queues to the coolers, a stagger
of desks, a cubicle farm, a boardroom table, aisles of desk columns. Red tape in 13 rooms (89 cells),
chests in 4 combat rooms, 754 cubicle cells (the Parlour has 781 pews), 25 coolers, 59 in-trays.

## Files added

- `scripts/core/red_tape_rule.gd`
- `scripts/world/red_tape.gd`, `tape_spread.gd`, `paper_trail.gd`, `write_up_mark.gd`,
  `lane_drop.gd`, `hold_music.gd`, `gavel_strike.gd`, `takeover_tether.gd`, `water_cooler.gd`,
  `cubicle_wall.gd`, `in_tray.gd`
- `scripts/actors/behaviors/yes_men_chorus.gd`, `yes_man_behavior.gd`,
  `paper_shredder_behavior.gd`, `hr_rep_behavior.gd`, `doreen_behavior.gd`, `chairman_behavior.gd`
- `data/enemies/yes_man.tres`, `paper_shredder.tres`, `hr_representative.tres`,
  `office_florist.tres`, `office_perfume_sprayer.tres`, `doreen.tres`, `chairman_of_the_board.tres`
- `data/rooms/head_office/` (33 layouts)
- `tests/test_office_hazard.gd`, `test_office_enemies.gd`, `test_office_bosses.gd`,
  `test_office_floor.gd`
- this file

## Shared files touched (for the merge)

Every list entry was added at the end, in a block naming Head Office where a comment fits.

- `scripts/content/room_layout.gd`: a block after `SYMBOL_SALE_SIGN` with `SYMBOL_RED_TAPE` "x",
  `RED_TAPE_DOOR_CLEARANCE` 2, `SYMBOL_WATER_COOLER` "9", `SYMBOL_CUBICLE` "N", `SYMBOL_IN_TRAY` "y";
  characters appended to the end of `ALLOWED` (`x9Ny`), `SOLID_SYMBOLS` (`9N`),
  `WALLS_AND_BOMB_ONLY` (`N`) and `DECOR_SYMBOLS` (`y`); one red-tape clearance check in
  `validate()` after the strip check. All four path branches change these same one-line strings, so
  keep every side's characters.
- `scripts/world/room_view.gd`: one more line at the end of `is_passing_effect`'s expression
  (`TapeSpread`, `PaperTrail`, `WriteUpMark`, `LaneDrop`, `HoldMusic`, `TakeoverTether`); one call
  `_create_office_props(layout, palette)` at the end of `_create_props`; and the new function
  `_create_office_props` at the end of the file.
- `scripts/actors/player.gd`: `var _tape := RedTapeRule.new()`; `is_dodging()` and `is_taped()`
  after `is_slowed()`; in `_handle_movement`, two lines after `on_wet` and `if taped: velocity =
  Vector2.ZERO` after the strip carry; in `_draw`, two lines after `_draw_slowed()`.
- `scripts/actors/projectile.gd`: `LOOK_NOTE` and two colours after `ORNAMENT_RED`, and a note
  branch after the ornament's in `_draw`.
- `scripts/world/enemy_marks.gd`: a block of colours after `ELF_HAT`, and the "tie", "shredder",
  "clipboard", "headset" and "chairman" marks at the end of the `match`.
- `scripts/world/room_backdrop.gd`: wall pattern 4 after pattern 3's branch, floor pattern 4 after
  pattern 3's branch.
- `scripts/content/room_palette.gd`: one comment line each over `floor_pattern` and `wall_pattern`.
- `scripts/content/room_decor.gd`: `FICUS` and `OFFICE_CHAIR` after `FLUORESCENT`.
- `scripts/world/decor_layer.gd`: their two branches at the end of the `match`.
- `data/floors/head_office.tres`: replaced, keeping Step 1's id, depth, lock, danger and numbers.
- Tests: `test_enemy_types.gd` (`BEHAVIORS` end: the five office behaviors), `test_chests.gd`
  (line 281, the folder list), `test_shop.gd` (line 115), `test_arcade_room.gd` (`FLOORS` end),
  `test_stage2_props.gd` (`test_the_third_floors_effects_are_cleared_from_a_stored_room`, seven
  office effects at the end of its array).
- `LESSONS.md`: two lessons at the end.

Not touched: `floor_scene.gd`, `progress_data.gd`, every Waiting Room file, `tools/smoke_driver.gd`.

## Owed checks, for when testing resumes

Check for an open game window first and record the real save's MD5; it must be the same after.

1. **Import** once with `--headless --path . --import`: 18 new `class_name` scripts get their `.uid`
   files and the class cache learns them. Commit the new `.uid` files.
2. **Parse:** if anything fails, `--check-only --script` each new script, then `player.gd`,
   `room_view.gd`, `room_layout.gd`, `room_backdrop.gd`, `decor_layer.gd`, `enemy_marks.gd`,
   `projectile.gd`.
3. **Tests** (`tools/test.ps1`, read the summary line): the four `test_office_*.gd` files, then
   `test_enemy_types.gd` (warning times of the five behaviors), `test_boss_spawn_room.gd` (the
   Chairman's 44x52 body on both floor boss rooms), `test_shop.gd` (seven plan reward spots in
   `shop_01`), `test_chests.gd`, `test_arcade_room.gd`, `test_stage2_props.gd`,
   `test_deep_floor_unlocks.gd`, `test_room_layouts.gd`. Then `git checkout -- art/sprites`.
4. **Full loops:** 2 (or 3) in `git archive` copies on D: named `GrandpaSmokeofficeA`/`B`. The
   generic walk clears Head Office on the east run at depth 5, so the Chairman's fight and the run's
   end run there. No path-specific smoke check was added. Report run times.
5. **Screenshots** in a real window (only when the user is not playing), probe at
   `tools/probes/office_look.gd` modelled on `floor3_look.gd`, PNGs to `D:/grandpa-verify-office/shots/`:
   - every attack: Yes-Men lunge and echo, the shredder's lane and paper trail, a memo's warning,
     landing and write-up (and its sting ring filling), the memo storm's lanes and falling paper, the
     hold music's spiral warning and notes, the gavel's double ring and shadow, the bar chart rising
     with the green gap mark, the tether, the pull and the charge lane, the phase-two tape spread
     (warning outline, then strung);
   - the hazard: red tape strung, cut (slack ends), and Grandpa held (the loops at his ankles),
     **on the palest carpet tile**, in a large room where the HUD sits over floor;
   - each prop (cooler, cubicle wall runs, in-tray), each enemy and both bosses with their marks;
   - small, medium and large rooms next to the Mall's and the Records Basement's;
   - the HUD pills and the perfume cloud over the beige carpet.
6. **Income:** `tools/probes/income_probe.gd` adapted to the path, with and without blasting, against
   the floor-3 paths (Parlour 258 and 271). The cubicle walls hide coins at the furniture rate.
7. **Balance bot** for Doreen and the Chairman against the floor-3 and floor-4 bosses (Step 4).

## Risky spots

- **Never parsed.** Typed-variable dynamic calls (`enemy.target.is_dodging()`, `.push`, `.feet()`)
  copy existing patterns, but a typo would only show at load.
- **The pull vs red tape:** a push still applies while Grandpa is held by tape (the hold zeroes his
  walk, not the push). Probably right, but watch it.
- **Tape under his feet:** a spread row through where he stands becomes strung under him after its
  warning and holds him once, since he was not on strung tape the frame before. It is warned 1 s.
- **`hurts_at` in `LaneDrop`** is used by tests only; the real hit is in `_process`. A bar stood in
  after it rose but while it stands still hurts, once.
- **`HoldMusic` note count:** at a very long frame only one step leaves the frame the warning ends,
  then the rest catch up (tested); notes come from Doreen's current position.
- **Yes-Men echoes** start even from far away; a far echo lunges at nothing. Cheap, but it looks odd
  if many stand apart.
- **Comments inside multi-line array literals** (`test_enemy_types.gd`, `test_arcade_room.gd`,
  `test_stage2_props.gd`) follow `departments.gd`, which does the same in a dictionary.
- **Colour separation:** the closest pairs (Yes-Man against the office Florist and Perfume Sprayer,
  the Shredder against the Florist) are 0.26 to 0.28 apart after `SpriteVisual.readable`, just over
  the test's 0.25. The Chairman and the Shredder are 0.24 apart but differ in size.
- **The coordinator's re-check:** the boss tests compare against the spec's floor-4 targets (760,
  1950). After the merge, compare against the real floor-4 bosses too.

## Decisions made (open for the user)

- **"Chains once":** read as "every phase-two projection is followed by exactly one gavel, never a
  second", as the Santa's sleigh always chains into presents. It could instead mean once per fight.
- **The memo landing hurts** (1 pill, like the Florist's wreath) as well as the write-up's sting; the
  spec could be read as the mark alone stinging.
- **Cutting tape:** a dodge cuts only the cells under his feet, so it opens a gap, not the whole strand.
- **Hold rule:** tape catches him only on stepping onto it from clear floor, then lets him walk on.
- **Prop colours** sit in the prop scripts rather than as new `RoomPalette` fields, to keep the shared
  file free of merge conflicts.
- **Boss ids:** `doreen` and `chairman_of_the_board`. Step 3's ending card, memento, perk and
  posters key on `chairman_of_the_board`.
- **No path-specific smoke check**; the generic walk covers the path.
- **Water coolers are few** (25 cells): they roll barrel drops, so rooms other than combat and
  healing use in-trays instead.
