# Room Art Notes

Written 2026-11-06 on branch `env-art` for the environment art pass: the floor and wall tiles, props, decor, doors, chests and pickups of 8 paths, the shared pieces and the Waiting Room. Golden Years Mall and Fairway's End are left out, since two new paths replace them. The Flashback Cinema and the Séance Hotline are drawn ahead of their floors.

The user delegated every choice. Each one below gives its reason in a line.

## 1. Hooks (Part A)

### 1.1 Tiles: `TileArt` and `RoomBackdrop`

- **Where.** `res://art/tiles/<set>/` holds:
  - `floor_a_N.png`, `floor_b_N.png` and `floor_c_N.png`, the variants of the palette's three floor tones;
  - `wall_N.png`;
  - `wall_face_N.png`, used where open floor lies just south of a wall.
- **Which set.** The set is `FloorDef.art()`: the new `art_set` field, or else the floor's id. The four landings set `art_set = "crossroads"`, so they share the Crossroads tiles without copies.
- **Patches kept.** A cell keeps the tone of its 3x3 patch (`RoomPalette.patch_of`). It then picks one of that tone's variants by noise, so the a/b/c patches read as they did.
- **Jitter.** The palette's `floor_jitter` still varies each cell, but now only darkens. A tile never shows brighter than it was drawn.
- **Fallback.** A set missing any tone or its walls counts as missing (`TileArt.for_set` returns null). The code patterns then draw exactly as before.
- **Arcade.** An Arcade Room keeps its neon code patterns and gets no tile set, so it never passes for an ordinary room of the floor.
- **Collision.** The wall bodies are untouched.

### 1.2 Props: `PropArt`

- **Shared and per path.** `res://art/props/<id>.png` is shared. `res://art/props/<set>/<id>.png` wins while that path's rooms are built: `RoomView` sets `PropArt.art_set` from `FloorDef.art()`. Today every shipped prop is shared; the per-path folder exists for overrides and for the two new paths.
- **States.** A state is `<id>_<state>.png`. A state with no picture draws that state's placeholder, so a half-drawn set never shows the wrong state.
- **Placement.** Pictures land on whole pixels: `PropArt.centred`, or `PropArt.standing` for things placed by their bottom row.
- **Bodies unchanged.** No body, shape or size reads the art.

### 1.3 Hooked pieces and their states

| Piece | Picture ids | Kept in code over the art |
|---|---|---|
| Every breakable (`BreakableBlock`) | `<art_id>`, plus `art_state()`, `art_flipped()` and `art_angle()` hooks | `_draw_over_art()` |
| Grass | `grass`, and `grass_cut` once cut; odd variants mirrored | |
| Reinforced stone | `reinforced_rock` | its pulsing edge glow |
| Dropped coffin | `dropped_coffin`, turned upright when it lies along a column | |
| Decor (`DecorLayer`) | `decor_<kind>`, odd variants mirrored | |
| Hole, pool water | `hole`, `pool_water` | the pool's moving ripples |
| Doors | `door_open`, `door_key` (needs a Slip), `door_locked`, `door_chained` | the room letter (outlined over art), the Arcade die, the Slip prompt |
| Chests | `chest_lunchbox`, `chest_locked`, `chest_safe` and `chest_urn`, each with `_open` | the Safe's hint |
| Mimic | wears `chest_locked` | its breathing swell (a scale on the picture) |
| Pickups | `Pickup.art_id`: `pickup_coin`, `pickup_slip`, `pickup_thermos`, `pickup_potion`, `pickup_pill`, `pickup_recipe`; shop heals, Slips and Thermoses use the same | the name label and prompt |
| Placed Thermos | `pickup_thermos` | the blast ring; the fuse blink tints the picture warning red |
| Retirement Plan | `retirement_station` | the status lines and prompt |
| Crossroads sign | `path_sign` and `path_sign_chained`, drawn pointing east and mirrored for a west exit | the name, skulls and hint |
| Arcade tables | `arcade_table_slot`, `arcade_table_cards` | the name and prompt |
| Floor vent | `floor_vent` | the warning fill and flare, on the overlay |
| Organ pipe | `organ_pipe`, drawn for the north wall and turned with the case | the glow and its ring |
| Waiting Room boards (`WaitingStation`) | `station_<id>` | the label (outlined), the badge, the prompt |
| Trophy frames, bounty board | `trophy_frame`, `poster_board` | the mementos, posters, captions |
| Lobby decor | `lobby_<shape>` | the lamp lights |

- **Opened chests** (`Chest._leave_opened`, `PropPicture`). When a lunchbox, locked chest or urn is opened, or a safe is blasted, a `PropPicture` of its `_open` picture is left where it stood. It is not a pickup, has no body and blocks nothing. With no open picture, the chest just goes, as before.
- **Hazards and telegraphs stay code.** These are red tape, the queue barrier, the conveyor, the wet floor, the steam jets, every warning, and the effects. Their geometry and timing are the gameplay, and section 5 of the inventory keeps warnings in code.

## 2. Generation (Part B)

### 2.1 Tools and settings

- **Tiles: `create_tiles_pro`.** Square top-down at 32 px, top-down view, segmentation outline. One sheet of 16 tiles costs 10, the best value per tile. The Pro top-down tileset is 15 for transitions the game does not draw. The tiles are flat floor, so no low-view depth.
- **Props: `create_map_object`.** Low top-down view, single-colour black outline, medium detail, basic shading, 1 generation each. The canvas is close to the prop's size (32 px for most) so the art needs little shrinking.
- **Prompts.** Every prompt says "flat even lighting, no shadow" and, for anything with a flame, lamp or screen, "no glow". Flames are drawn as shapes only; the engine lights them.

### 2.2 Building (`tools/art/env_art.py`, plain Python)

- **Tiles onto the palette.** Each tile's mean colour is moved onto its palette tone, and its spread of brightness is squeezed to at most 0.035 (walls 0.07; Head Office and Terminal floors 0.025).
  - Every lit-contrast check already made against the palette colours still holds.
  - A path's three tones stay as close as its palette has them.
  - The floors stay quiet under the bodies.
- **Tone overrides, for the tiles only** (`EXTRA_TONES`):
  - Furnace Works: the iron-plate tone is lifted from 0.30 to 0.36 in value, to keep the three tones within 10%.
  - Funeral Parlour: a darker wine and brown, because the palette's wine lit up beside the warning red under the parlour's torches.
  - Waiting Room: a warm brown carpet and olive wallpaper. Its palette keeps the stone defaults for the code look.
  - Cinema and Séance: their tones come from the design (no `.tres` on this branch yet).
- **Skipped tiles** (`SKIP`): tiles that read wrong in play, such as logos, writing, window grids, crack marks that look like the crack decor, pit-like blotches, and red specks. Each skip names its reason.
- **Blank sheets.** The tool refuses a sheet of blank white tiles.
- **Props** (`tools/art/env_props.txt`). Each prop is trimmed and given hard alpha, then shrunk to its box by the commonest colour in each block, so the black outline survives.
  - `exact` fills a cell exactly (hole, pool water, trophy frame, bounty board, rug).
  - `main` keeps the largest connected piece (it drops a floating sign).
  - `keybg` clears the flat background of a canvas too big for PixelLab to make transparent (the lobby rug).
- **Exports** are in `D:\grandpa-art\env\<set>\tiles` and `\props`, with `objects.tsv` (set, name, PixelLab object id) and each sheet's `job.txt`.

### 2.3 What was made

| Set | Tiles | Props |
|---|---|---|
| floor_1 (Records Basement) | sheet 1 | shared crate, rock, barrel, bone pile, grass and cut grass, hole, reinforced stone, torch and lantern decor |
| cemetery | sheet 3 (sheets 1 and 2 came back blank) | gravestone, dead tree, stump, sapling |
| sunset_shores | sheet 1 | care bed (rerolled upright), armchair, wheelchair, food trolley, flower vase, wet sign, plant, IV stand |
| furnace_works | sheet 1 | coal heap, coal sack, furnace crate, pipe valve, floor vent, pipe, gauge, furnace |
| funeral_parlour | sheet 1 | chapel pew, hymn cart, wreath stand, candle stand, dropped coffin, organ pipe, stained glass, coffin stand |
| last_resort_cruise | sheet 1 | deck chair, buffet tray, lifeboat davit, pool water |
| terminal_zero | sheet 2 (sheet 1 was too busy) | luggage trolley, suitcase stack, departure seats, departure board |
| head_office | sheet 1 | cubicle wall, water cooler, in-tray, ficus, office chair |
| crossroads (and landings) | sheet 1 | path sign open and chained |
| shared | | 4 doors, 4 chests and their 4 open states, 6 pickups, Retirement Plan, 2 arcade tables |
| waiting_room | sheet 1 | 10 station boards, trophy frame, bounty board, 5 lobby pieces, lobby rug |
| flashback_cinema (not wired) | sheet 1 | seat_row, pillar, lobby_card, screen_frame, aisle_light |
| seance_hotline (not wired) | sheet 1 | cubicle_wall, psychic_desk, lava_lamp, beaded_curtain, seance_table |

**Rerolled once:** the lunchbox, locked chest and safe open states, the open door, the forms counter and the duty free board (gibberish lettering), the lobby poster, the lobby rug (a large warning-like red), the care bed, the psychic desk (a person sat at it) and the beaded curtain.

**Total generations: 277**, out of a budget of 700. That is 16 tile sheets at 10 and 117 map objects at 1.

### 2.4 Left in code on purpose

- **Translucent overlays.** Cobweb, puddle, floor crack, moss, coal dust, fog and wet floor are see-through. The generated cobweb and crack came out empty, and the puddle came out as a flat opaque disc. The code versions read better.
- **Department signs.** They are text only.
- **Items.** These wait for the item audit, so they keep the rarity disc.
- **People.** The station people and the training dummy are characters, not room art.
- **Hazards and every telegraph** (see 1.3).

## 3. The Cinema and the Séance, ready to wire

Their files are named for the props the design calls for. Wiring them takes the floor ids `flashback_cinema` and `seance_hotline`; their tiles then load with no further code.

- **Tiles:** `art/tiles/flashback_cinema/` (teal carpet, plum and gold walls) and `art/tiles/seance_hotline/` (violet carpet, indigo walls).
- **Cinema props** (`art/props/flashback_cinema/`):
  - `seat_row` (32x28, cover);
  - `pillar` (24x40);
  - `lobby_card` (an easel);
  - `screen_frame` (160x80, an empty screen for the memory scenes);
  - `aisle_light`.
- **Séance props** (`art/props/seance_hotline/`):
  - `cubicle_wall`;
  - `psychic_desk`;
  - `lava_lamp`;
  - `beaded_curtain`;
  - `seance_table` (44x40).

Each new prop needs its own script with `art_id()` returning its name, as the existing props do. Because these sit in the path's own folder, they load only while that path is played.

## 4. Verification

- **Probe.** `tools/probes/env_art_look.gd`, run from an exported copy, shoots a combat room for each path with a ground warning laid by Harold, then a shop with a door in each state, a treasure room with every chest kind (one left open) and every pickup, and the boss room. It then shoots the Waiting Room lobby with all its decor and three departments. It prints the lit luminance of the floor, the warning and Harold, sampled from the shot.
- **Fixes found by looking:**
  - the Parlour wine was too near the warning red;
  - the Cemetery sheets were blank;
  - the Terminal and Head Office floors were busy;
  - Waiting Room blotches;
  - a sideways bed.
