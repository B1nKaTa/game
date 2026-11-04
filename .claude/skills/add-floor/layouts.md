# Room layouts for a new floor

A room is a `RoomLayout` `.tres` (`scripts/content/room_layout.gd`): a `room_type` and `rows`, a
`PackedStringArray` of equal-length strings, one character per 32 px cell. A path's rooms live in
`data/rooms/<path_id>/` and the FloorDef's `rooms_dir` points there. `RoomCatalog.load_valid(dir)`
loads only rooms that pass `validate()`, so a broken room silently drops out of play: always run the
floor test that asserts every file in the folder is valid.

## The mix: 33 rooms, as both floor-3 paths

| Type (`room_type`) | Files (Funeral Parlour) | Size |
|---|---|---|
| `combat` | `combat_01` to `combat_07` | medium 20x11, `E` = medium count (8 on floor 3) |
| `combat` | `combat_large_01` to `_03` | large 30x17, `E` = large count (13) |
| `combat` | `combat_small_01` to `_03` | small 14x9, `E` = small count (6) |
| `mini_boss` | `mini_boss_01`, `mini_boss_large_01` | one `B` |
| `floor_boss` | `floor_boss_01`, `floor_boss_large_01` | one `B` |
| `item` | `item_01`, `item_large_01`, `item_small_01` | 2 or more `I` |
| `healing` | `healing_01`, `healing_small_01` | `H` |
| `treasure` | `treasure_01`, `treasure_small_01` | 3 or more `I` |
| `side` | `side_01`, `side_large_01`, `side_small_01` | `T`, 2 `E` |
| `secret` | `secret_01`, `secret_small_01` | 2 or more `T` |
| `vault` | `vault_01`, `vault_large_01`, `vault_small_01` | 3 `I`, 3 `T`, room for `VAULT_EXTRAS` |
| `shop` | `shop_01` | 5 `S`, one `P` |

Size class comes from the width (`RoomLayout.MEDIUM_WIDTH = 20`, `LARGE_WIDTH = 30`, at least
`MIN_SIZE = 10x7`). Combat rooms must hold exactly the floor's `enemies_by_size` count of `E`
(`FloorDef.room_size_errors`). Put `C` (chest) cells in about three combat rooms. Required symbols per
type are in `RoomLayout.REQUIRED`.

## Symbols

All allowed symbols are in `RoomLayout.ALLOWED`, solids in `SOLID_SYMBOLS`, wall-like ones in
`WALL_LIKE` and `WALLS`, bomb-only blockers in `WALLS_AND_BOMB_ONLY`, decor in `DECOR_SYMBOLS`, and
the ones that must be reachable without breaking anything in `MUST_REACH_WITHOUT_BREAKING`. The
alphabet is crowded: before picking a letter for a new prop or hazard, list the free ones and check
them **case-sensitively** (a PowerShell port of the rules once read coal sack `L` as lantern `l`):

```bash
cd <worktree> && allowed=$(grep -o 'const ALLOWED := "[^"]*"' scripts/content/room_layout.gd | cut -d'"' -f2)
for c in {a..z} {A..Z} 0 1 2 3 4 5 6 7 8 9; do case "$allowed" in *"$c"*) ;; *) printf '%s ' "$c";; esac; done; echo
```

Wall fixtures (lanterns `l`, organ pipes `o`) sit only in plain border wall cells, never beside a
door cell. A hazard laid in the floor gets its own `*_DOOR_CLEARANCE` (2 for wet floor, vents and
strips) and a check in `validate()`.

## What `validate()` already checks

Size and even rows, known symbols, a wall border, required symbols, the four door cells being floor
and reachable without a bomb, every non-wall cell reachable, `EBIHSPG` reachable without breaking
anything, nothing solid or fighting on or beside a door cell (`_door_clearance_errors`, and
`MIN_FIGHTER_DOOR_DISTANCE = 3` for `E` and `B`), hazard clearances, vault pickup room, and arcade
rules. Any door can be the way in, so this applies to all four sides of every room.

## Rules learned the hard way (validate() does not catch these)

- **A boss's start cell must clear the boss's real collision box.** `validate()` checks cells, but a
  boss's box is 0.8 of its `body_size` (Mortimer 42x50, the Santa 44x50), wider and taller than a
  cell. Two floor-3 bosses started wedged in pews and fountains. `tests/test_boss_spawn_room.gd`
  (`solid_cells_under`) now checks every `B` in every floor's rooms against its real boss, so leave
  at least one open cell on each side of `B` for big bodies, and read that test's output.
- **Props stay clear of doors.** Nothing solid on or touching any of the four door cells
  (`door_cell(side)`), and before placing anything also check `wall_cell(side)`, since any wall can
  hold a door. Pickups that collect themselves (a Thermos, coins) never go on a door cell or get
  placed by `nearest_floor_cell` alone: one landed on the small vault's south door and was taken
  unseen on arrival.
- **Spawn and station spacing.** `E` and `B` at least 3 cells from every door cell. Labeled pickups
  at least `PICKUP_SPACING` (3) apart and `SAME_ROW_SPACING` (4) on one row, with `LABEL_CELLS` (4)
  of floor to the right of a free item, nothing on the HUD row (`UNDER_THE_HUD`), merchants
  `MERCHANT_DOOR_CLEARANCE` (2) from doors. Waiting Room stations and NPCs stand on floor, at least
  3 cells from every door cell, one per cell, off the HUD row (`tests/test_departments.gd`), and clear
  of everything drawn there (trophy frames, wall lanterns, the run door).
- **Walkers route through the walk grid.** Rows of solid props (pews, planters) make lanes, so any
  enemy heading somewhere must use `Enemy.walk_direction_to(point)` or `Enemy.chase_direction()`.
  A loop or a partner's side reached with a bare `direction_to` stuck on props. Test pathing with the
  biggest body, and aim waypoints with `WalkGrid.fit_point`, which found that the Regional Reaper
  could not fit a two-cell gap aimed at its middle.
- **Clear lingering effects from a stored room.** Visited rooms stay alive out of the tree. Anything
  an attack leaves behind (clouds, wet patches, dropped coffins, presents, rings) must be in
  `RoomView.is_passing_effect`, or it freezes mid-way and resumes on return. Extend
  `tests/test_stage2_props.gd` `test_the_third_floors_effects_are_cleared_from_a_stored_room`.
- **Hazards must not carry a charging enemy off its warned lane.** A dash or charge calls
  `enemy.hold_lane()` every frame it runs, and `Enemy.rides_strips()` then says no
  (`tests/test_mall_hazard.gd` `test_a_running_charge_is_not_carried_off_its_warned_lane`). Any new
  hazard that moves bodies needs the same rule. Strips, vents and wet floor stay 2 cells off doors so
  nobody is carried through one.
- **Leave a free cell beside the start** for every built floor (`tests/test_crossroads.gd`
  `test_every_built_floor_keeps_a_free_cell_beside_its_start`).
- **A floor pattern shares no shape with the hazard**, and a hazard tile no shape with any floor
  pattern. Check both side by side in a screenshot.
- **Big pale rooms and dark rooms:** light every room with faint fill lights, keep placeholder colours
  above a minimum brightness, and judge the palette from a screenshot with enemies in the room, never
  from the colour values.
- **Income:** a prop that can hide a coin pays at the furniture rate, scaled by how many of it a floor
  has (232 gravestones once hid coins at a rock's rate). Measure income with and without blasting.
- **Builder order:** if `FloorBuilder` changes, count how often each "always there" room (vault,
  secret, treasure) appears over 1000 seeds before and after.

## Editing layouts safely

- Write new room files with the Write tool, one file per room, as the existing ones are written
  (`[gd_resource type="Resource" script_class="RoomLayout" load_steps=2 format=3]`, the ext_resource
  for `room_layout.gd`, `room_type`, `rows`, and `strips_reverse` only if needed).
- Edit existing rows with a literal match, never a sed regex: a `.` in a sed pattern is a wildcard and
  once overwrote whole rows of other rooms. Use the Edit tool, or awk `$0 == old`. Keep the committed
  `.tres` as the source to rebuild from.
- In PowerShell, `-eq` ignores case (use `-ceq`), variables differing only by case are one variable,
  and `@(1, $h - 2)` means `(1, $h) - 2` (wrap arithmetic elements in parentheses).
- If testing is on hold, a port of `validate()` (PowerShell or awk) can check the folder, but run it
  first on known-good and known-bad rooms, and read its whole output, not only the summary. Floor 3's
  Parlour layouts were checked this way, then confirmed in Godot when testing resumed.

## When testing is allowed

1. `powershell -File tools/test.ps1`, and read the floor test's layout failures by file name.
2. Screenshot a small, a medium and a large room of the new floor next to the previous floor's in a
   real window, with enemies in, and every placement rule (plan rewards, vault extras, labels) in the
   floor's real rooms. Long names running past a wall and spots under the HUD were only caught this way.
