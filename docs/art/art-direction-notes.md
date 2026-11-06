# Art Direction: the Depth Look

Written 2026-11-06 on branch `art-direction`. The Records Basement (`floor_1`) is the test slice: it is drawn in the new direction so the look can be judged before the other 11 areas follow. Every other floor keeps its flat tiles, light and warnings; it only gains the shared pieces (contact shadows, door openings, the HUD, and Harold).

This is a rulebook. A floor redone later follows it and only picks its own materials and colours.

## 1. Switching it on

- `FloorDef.art_style = "depth"` (`DepthLook.STYLE`) turns the look on for a floor. `floor_1.tres` is the only floor that sets it.
- The art lives in `res://art/tiles/<set>/depth/` (`ground.png`, `cap.png`, `face_N.png`, `sconce.png`) and `res://art/props/<set>/`. A set missing its depth art falls back to the flat look.
- Build it with `py tools/art/depth_art.py D:/grandpa-art/direction . <set>`. Raw exports are in `D:\grandpa-art\direction\`.
- An Arcade Room keeps its neon look on every floor.

## 2. Pixel density, outline and shading

- **One density.** Everything is drawn 1:1 at the 640x360 view: 32 px cells, props near their cell, Harold about 42 px tall in a 60 px frame. Nothing is scaled at draw time.
- **Outline.** Characters and standing props have a single-colour dark outline. Flat floor art (ground, decals, holes, paper scraps) has no outline.
- **Shading.** Basic shading, one or two steps per colour, light from the upper left. No baked glow and no baked cast shadow; the engine draws both.
- **PixelLab settings.** Ground: `create_topdown_tileset` in pro mode, high top-down, 32 px, `boundary_amplitude` 0.2, `raggedness` 0.4 (15 gens). Walls: `create_tiles_pro`, square top-down, flat top-down view, segmentation outline, each tile named as a wall or floor tile (10 gens). Props: `create_map_object`, low top-down, single-colour outline, basic shading, low detail, 32 px canvas (1 gen each). Harold: `create_character` v3, 44 px, low top-down, single colour black outline, low detail, with v3 custom anims facing east (about 5 gens).

## 3. Palette

- **Earth and stone.** The base ground is a dark warm earth; its patches are worn grey flagstones, dimmed and warmed in the build (`GROUND_TONE`) so they never outshine a body.
- **Walls.** Fronts are grey-brown brick (`face_N`); tops are darker rubble (`cap`, toned to about 70%). The top must always be darker than the front, so a block reads as a mass with height.
- **Warm light, cool dark.** Light sources are warm orange (`SCONCE_LIGHT`); the ambient is a dim violet-grey (`AMBIENT`).
- **Keep clear of the warning colours.** No large area of warning red (#e4524f) or safe-spot mint (#7fe0a0) in any tile or prop. The rubble's pink bricks were recoloured to brown for this reason (`recolour_brick`).

## 4. Ground

- **One continuous ground per room.** There are no per-cell frames. The base terrain covers the room, and the patch terrain is laid over it by a smooth noise on the cell corners (`DepthLook.corner_noise`, `PATCH_LEVEL`, `PATCH_SCALE`). The 16 Wang tiles join the two terrains seamlessly.
- **Decals ignore the grid.** Only cracks are baked and dropped at pixel offsets (`DECAL_DENSITY`). Puddles and grit read as dark blobs with dots at 1x and were removed. The flat look's code puddles, cracks and bone scatters stay out of a depth room.
- **The nameable rule.** If a prop or mark cannot be named from a 1x screenshot, redraw it or remove it. Prefer fewer, bigger, clearer props; props are toned to about 74% (`dim`) so the torches never light them like lamps.
- **Basement scatter.** The floor's grass is tied stacks of files here (half as many as the flat look's tufts); cut grass is torn scraps. Rubble is a fallen masonry block, the bone heap a skull on bones.
- **Pits.** A rim of wall top round the edge, the brick of the far side going down into the dark, and black at the bottom (`depth_art.pit`).

## 5. Walls with height

- A wall cell with open floor south of it shows a **front face**. Every other wall cell shows its **top**. A block one cell deep shows a strip of top above its face.
- **Edges.** A top that meets the floor has a dark line and a lit rim. A few stones poke up to 3 px over the edge, so no edge runs ruler-straight.
- **Cast shadow.** Banded black falls on the floor below every face (4 bands of 4 px: 0.42, 0.30, 0.20, 0.10) and a narrower band east of every wall.
- **The mass.** Outside the room the wall tops run on a ragged 6 to 20 px into darkness, so the room reads as cut out of solid rock.
- **Collision never changes.** All of this is drawn. The whole backdrop is painted once into one texture (`DepthLook.bake`), so it costs one draw.

## 6. Lighting

- **Ambient.** `CanvasModulate` at `AMBIENT` (0.33, 0.30, 0.38).
- **Light sources.** Warm sconces on the north wall faces (`sconce_cells`, every 7 cells, kept 3 cells off the door) and on up to two of the room's own wall blocks, where they show (the north wall sits under the HUD in a room that fits the view), plus the floor's own standing torches and lanterns. One wide warm fill every 12 cells keeps corners from going black. A medium room has about 2 fills, 2 to 3 sconces and the scatter's lights.
- **Vignette.** The view darkens toward its edges (`Vignette`, strength 0.7). It sits over the floor (z -2) and under every body, prop, shot and warning.
- **Bodies keep one even light.** Enemies and Harold draw unshaded in this look, at `BODY_LIGHT` with their darks lifted by `BODY_GAMMA`, so a dark corner never swallows them. The target is a lit body luminance of at least 0.4, measured from a screenshot as the pixels that change when the sprite is hidden (`tools/probes/art_direction_look.gd`).
- **Warnings, shots and ground marks draw unshaded.** Anything a depth room gains at z 50 or above gets an unshaded material (`DepthLook.keep_vivid`), and so does every enemy's warning layer. Unshaded items in Godot 4 ignore `CanvasModulate` too, so the warning red and safe-spot mint keep their full colour.
- The HUD is a CanvasLayer and is never darkened.

## 7. Shadows on the ground

- Every standing thing gets a contact shadow (`ContactShadow`): Harold, enemies, NPCs, breakable props, chests and pickups. It is a baked ellipse in three hard bands at 0.42 alpha, about 0.36 as tall as it is wide, drawn at z -7 as a child of its owner, so it moves for free.
- Things set into a wall (reinforced stone, the secret crack) and wall-mounted enemies cast none. A submerged enemy's shadow hides with it.
- This applies to every floor.

## 8. Doors

- A door in a wall is an **opening** (`DoorOpening`): a gap two cells wide through the whole wall, with stone jambs, the floor running on into darkness in four bands, and a gate of iron bars while the way is shut. The gate rises into the dark over 0.35 s when the room is cleared.
- A Slip door shows a gold padlock on its bars; a chained door shows chains across them.
- A **small sign** hangs in the opening for what lies beyond (`DoorSign`): a money bag for the shop, a skull for the boss, a small skull for the mini boss, a chest for treasure, a star for an item room, a cross for healing, a question mark for a side room, an eye for a secret, a lock for a vault, a signpost for the Crossroads, stairs for a landing, and the die for the Arcade. A plain fight room shows none. The small map keeps its own letters.
- The door's cell, its trigger and the walls' bodies are unchanged. Doors standing on the floor (the stairwell, the Waiting Room's run door) keep their picture.
- This applies to every floor; the flat floors use their palette's wall and floor colours for the jambs and the gap.

## 9. HUD

- Two framed panels in dark wood and brass (`HudStyle.draw_panel`) leave the top middle clear for the north door and its sign. The left panel holds the pills as capsule icons, Pension with a coin, the Slip and Thermos counters, the item row and the case-file key. The right panel holds the potion slot (and the run timer). The small map has its own panel.
- **Font.** `res://art/ui/basement_ledger.fnt`, a bitmap font built by `tools/art/font_build.py` from a PixelLab `create_font` atlas, with D, O, `[` and `]` redrawn by hand, drawn at 8 px (16 px for large lines) at whole-number scales and a 2 px black outline. Glyphs it lacks fall back to the engine font.

## 10. Enemies

- **Staff of the place.** Every regular enemy must read at a glance as belonging to its floor's theme (the basement: office staff of the dead) and differ from the others in silhouette and main colour, so a crowd can be told apart.
- Same settings as Harold: `create_character` v3, low top-down, single colour black outline, low detail, 48 px (32 px for the smallest), with v3 custom idle, walk and attack facing east. Strips are built by `tools/art/enemy_strips.py` from `D:/grandpa-art/direction/enemies`, with the windup cut from the attack (`CUTS`), and stray specks cleared from the frames first.
- When a base art is redrawn, re-aim its variants' `art_hue_from` at the new art's main colour.
- **Health bars** sit a few pixels over the top of the drawn art (`Enemy.bar_top`, `SpriteVisual.idle_height`), on their own layer one z over the bodies.
- **Attack warnings.** Regular enemies draw no warning shapes unless the Game tab's "Attack warnings" is on (`AttackWarnings`); their tell is the windup pose and a short pale flash at its start (`Enemy.WINDUP_CUE`). Bosses and mini bosses keep every telegraph and safe-spot mark.

## 11. The other areas

Each area's export is in `D:/grandpa-art/direction/sets/<set>/` (one pro Wang ground tileset, one tiles_pro sheet of wall fronts), built with `py tools/art/depth_art.py D:/grandpa-art/direction . <set>` from its `AREAS` entry. Its wall top is its plainest front darkened, its light comes from its palette (`DepthLook.tune`), stone places use the basement's torch and indoor places a brass lamp (`sets/_shared/lamp.png`).

## 12. Doing another floor

1. Generate one ground tileset (two terrains that suit the place), one wall sheet (fronts and tops), and the floor's props, with the settings in section 2.
2. Build them with `tools/art/depth_art.py`, setting that floor's tones in the build so the top is darker than the front and the ground stays under the bodies.
3. Set `art_style = "depth"` on its FloorDef.
4. Shoot it with `tools/probes/art_direction_look.gd` and check the body luminance, the warnings and the doors in the shots before keeping it.

## 13. The areas' props

Every prop and decor picture of the rollout areas has its own copy in `res://art/props/<set>/`, built by `py tools/art/area_props.py D:/grandpa-art/direction . [set ...]` from `D:/grandpa-art/direction/props2/` (`AREA_PROPS` lists each area's pictures, sources and boxes).

- **New drawings** for what could not be named at 1x, at the size of the picture they replace, outlined again after shrinking and toned (`TONE`, `DIM` for pale or loud ones). Nothing is ever stretched up; a drawing only shrinks into its box.
- **Kept pictures** that already read are only toned onto the look (`KEPT`), so the whole area sits at one brightness.
- **Left out in the depth look** (`RoomView.DEPTH_LEFT_OUT`): moss and coal dust, which read as dark blobs, with the puddles, cracks and bone scatters as before. A fluorescent panel keeps only its light (`DEPTH_UNSEEN`).
- **Run pieces.** The hotline's partition is drawn as two panels and built into a west end, a middle, an east end and a lone panel, 32x26 each at the drawing's own scale (`SeancePartition.art_state`).
- **Code shapes given art.** The Cinema screen's gold frame is a 7x7 nine-slice (`screen_trim.png`, `CinemaScreen.FRAME_ART`) drawn round the picture at the size the code uses; the hotline's partition and small side table (`seance_table_small.png`) have pictures now; the deck bench and cafe table decor have pictures. Each keeps its code drawing as the fallback.
- **What each area got:**
  - Waiting Room: a lobby lamp, a slot machine, the basement's lantern; every station board, the trophy frame and lobby decor toned.
  - Crossroads and landings: dry weeds and their stubble for grass, the basement's lantern; path signs toned.
  - Cemetery: gravestone, weeds and stubble, a dead shrub for the saplings, the basement's skull pile and lantern; barrel, rock, dead tree, stump and torch toned. Moss is gone.
  - Sunset Shores: care bed, meal trolley, wet-floor sign, drip stand, lantern; vase, armchair, wheelchair and plant toned.
  - Furnace Works: coal heap, valve, gauge, pipe, lantern; sack, crate, vent and furnace toned. Coal dust is gone.
  - Funeral Parlour: candelabra, wreath, hymn cart, coffin stand, lantern; pew, organ pipe (toned further), dropped coffin and stained glass toned.
  - Flashback Cinema: the lobby card (an easel with a framed photograph), the screen's frame; plant toned. Seats, pillars and aisle lights keep their pictures; the screen scenes are unchanged.
  - Last Resort Cruise: buffet cloche, lifeboat davit, deck bench, cafe table, lantern; deck chair and plant toned, pool water toned deep.
  - Seance Hotline: partition pieces, small side table, in-tray, office chair, lantern.
  - Terminal Zero: airport seats, lantern; suitcases, trolley, departure board and plant toned. The fluorescent glare is gone.
  - Head Office: cubicle wall, water cooler, in-tray, office chair; ficus and plant toned. The fluorescent glare is gone.

## 14. Shots and thrown things

Built by `py tools/art/shot_art.py D:/grandpa-art/direction .` into `res://art/props/`. The smallest are drawn by hand in the tool; the rest come from `create_map_object` exports in `D:/grandpa-art/direction/projectiles/`.

- **Readability.** Everything an enemy throws has a warm or bright body, a dark outline (`ENEMY_LINE`) and a pale warm rim outside it (`ENEMY_RIM`). The rim's luminance is 0.90, at least 0.75 over every floor's base ground (the parlour's is 0.06), measured on the contact sheets. Harold's own things wear a cool pale ring inside a dark one (`HAROLD_RING`), so they never look like an enemy's. What lies on the floor (the thorns, the write-up, goo, film, red tape) and the scythe keep their outline only. No shot uses the warning red or the safe-spot mint: the lifebuoy's red is orange, the plate's velvet pale brass, the puck's navy orange and the anchor pale steel.
- **1:1.** Every picture is drawn at its own size, never scaled, and the smallest shot is 13 px across. Spinning things use pre-drawn turns (`ROTATIONS`, drawn by `PropArt.draw_frame` and `turn_frame`): the plate and lifebuoy four over a quarter turn, the paper sheet eight over a half turn (the memo in flight; a plain shot shows the first), the film pieces four. Only the scythe, which sweeps to any angle, is drawn turned. The coal flickers through a two-frame strip.
- **Telegraphs stay code.** Every warning fill and ring, the casket's and gavel's growing shadows, and every safe-spot mark are drawn as before.
- **Every shot and thrown thing, with its code size and what it has now:**

| What | Where (script) | Who | Code size | Art |
|---|---|---|---|---|
| Plain shot (paper) | projectile.gd | every thrower and burst shooter, the floor bosses' rings, the undertaker | 8x10 | `shot_paper` 14x15, in 8 turns of 20x20 |
| Sedative dart | projectile.gd | orderly, cruise orderly | 10x5 + needle | `shot_dart` 19x9, turns with flight |
| Hold-music note | projectile.gd, hold_music.gd | Doreen | about 10x12 on a glow | `shot_note` 14x16 |
| Popcorn kernel | projectile.gd | popcorn tub | 9 | `kernel` (had art) |
| Critic's star | projectile.gd | Crabtree | 13 | `star_spin` (had art) |
| Stapler, mug, fax | projectile.gd | poltergeist | 24 | had art |
| Lump of coal | ground_strike.gd | stoker, cruise stoker, Old Smokey | 8 | `shot_coal` 2 frames of 13x13 |
| Thorny wreath in flight | ground_strike.gd | florist, office florist | 13 | `shot_wreath` 15x15 |
| Ring of thorns left | ground_strike.gd | florist, office florist | about 56 | `thorns_lying` 56x54 |
| Collection plate | collection_plate.gd | Reverend | 14x8, spins | `collection_plate` 4 turns of 22x22 |
| Anchor | anchor_drop.gd | Commodore | about 26x30 | `anchor` 25x32 |
| Lifebuoy | deck_lane.gd | Commodore | 26, rolls | `lifebuoy` 4 turns, 26 px in 36x36 |
| Quoit | quoit_ring.gd | Lorraine | 32 | `quoit` 31x32 |
| Shuffleboard puck | shuffleboard_puck.gd | shuffleboard shark | 14 | `puck` 16x16, orange |
| Falling star | star_fall.gd | Celestine | 12 | `star` (Crabtree's) |
| Security tray | terminal_strike.gd | Sergeant Wanda | 24x16 | `security_tray` 26x20 |
| Rubber stamp | terminal_strike.gd | Augustine | 64x41 shadow and handle | `rubber_stamp` 38x40, coming down in the warning's last half |
| Gavel (landed) | gavel_strike.gd | Chairman | about 42x21 | `gavel` 41x23 |
| Memo in flight | write_up_mark.gd | HR representative | 8x10, spins | `shot_paper`, its 8 turns |
| Write-up form left | write_up_mark.gd | HR representative | 16x20 | `write_up` 14x20 |
| Seance spirit | spirit_swoop.gd | seance circle | 12 | `spirit_orb` 14x13 |
| Casket (landed) | ground_strike.gd | Mortimer | about 40x80 | `casket` 39x82 |
| Scythe | scythe_sweep.gd | Celestine | 110 px snath and blade | `scythe` 107x37, turned to the sweep |
| Film pieces | film_trail.gd | film reel | 12x12, turned | `film_piece` 4 turns of 17x17 |
| Red tape (strung) | red_tape.gd | Chairman, office rooms | 32x8 | `red_tape` 32x8 |
| Ectoplasm blob | ectoplasm_trail.gd | ectoplasm | 16 | `ectoplasm` 16x15 |
| Thrown dentures | thrown_dentures.gd | Harold | 12x11, two jaws | `dentures_upper` / `_lower` 16x7, opened in code |
| Knitting needle | item_fx.gd FxNeedle | Harold | 14x5 | `fx_needle` 17x7 |
| Banana peel | item_fx.gd FxPeel | Harold | 16 | `fx_peel` 18x17 |
| Tarot cards, planchette, crystal ball, popcorn tub, pie, tumbleweed, dropped coffin | their own scripts | hotline, Cinema, parlour | | had art |
| Procession, conga line, baggage cart, pallbearers' coffin | ground_strike.gd, procession_lane.gd, deck_lane.gd, behaviours | parlour, cruise, terminal | | still code |
| Wheel blades, phone cord, the stamp's ink, memos, bar and drawers, desk papers, paper scraps, cut tape, wet tiles, perfume mist | their own scripts | hotline, terminal, office, Cinema, cruise | | still code |
| Fire breath, steam, shockwaves, pipe rings, burn rings, beams, foghorn, blasts | their own scripts | | effects | still code |
| Harold's cane wave, rolling pin, soup, scooter flames, fizz, cough, clouds | item_fx.gd | Harold | effects | still code |

## To verify when testing resumes

Testing was paused on 2026-11-06 by the user ("don't test anything until further notice"). Everything below was built but not yet run.

- **Suite and full loop.** Run tools/test.ps1 and one full loop in a renamed export after all of pass 2 and the rollout; commit edf4571 onward is untested.
- **Health bars** (edf4571): screenshot a bar over a short (seasonal_temp), a tall (denial_officer, notary_public) and a wide enemy on floor 1, the cemetery and the parlour (`art_direction_look.gd bars`), and check the bar never sits on a body.
- **Hidden warnings** (3ae4990):
  - shoot a floor 1 fight with the setting off (no red shapes from regulars) and on (shapes back), and a boss fight (shapes always);
  - confirm every regular enemy's windup pose and pale flash read in a window, and list any that need more;
  - the Options Game tab with the new row at its fullest (it now has 10 rows), and that the setting saves and loads;
  - bot numbers before and after (`max good 20 0 1` and `max good 20 0 3`). Before, on 1318bd5: floor 1 reached_mini 16, beat_mini 14, reached_boss 1, beat_boss 1, hits 9.3; Funeral Parlour reached_mini 15, beat_mini 14, reached_boss 1, beat_boss 0, hits 10.1. The bot reads threats from code, so its numbers should not move.
- **Redrawn enemies** (130700f): the floor 1 lineup with names (`art_direction_look.gd lineup`), their body luminance against 0.4, their figure size against the body box, and the variants' recolours (`variants`: shores and parlour temps, shores denial officer, furnace auditor). The denial officer's shield arc must still sit over his drawer.
- **Props, pits and ground** (1085f87): a busy floor 1 combat room at 1x; every prop nameable, no dark blobs, pits with a rim; the new cobble patches.
- **Font** (b8af413): the HUD, the potion slot's "[H]" and a notice line in the new bitmap font; check it imports and scales only by whole numbers. Its .import file was not generated yet.
- **Rollout areas** (every FloorDef now has `art_style = "depth"`): for the Waiting Room, the Crossroads and landings, the cemetery, Sunset Shores, the Furnace Works, the Funeral Parlour, the Flashback Cinema, the cruise, the Seance Hotline, Terminal Zero and Head Office, shoot each area's combat, shop, treasure and boss room (the Waiting Room's lobby and departments):
  - ground patches, wall fronts and tops, pits and sconces or lamps;
  - door openings with the area's own jambs;
  - the light (its palette's ambient times `AREA_AMBIENT` 0.72, its torch and fill colours) and body luminance against 0.4;
  - every hazard and its warning against the new ground: the cruise's wet deck and rolling deck, the furnace vents against the riveted plates, the office's red tape on the grey carpet tiles, the terminal's queue barriers and runway lanes on the terrazzo, the parlour's wine carpet against the warning red, the hotline's checked tiles against the seance marks;
  - the code floor patterns (the Cinema's runners, the hotline's stars) are no longer drawn; check nothing relied on them;
  - each area's props against the nameable rule (redrawn or toned since, section 13);
  - test_art_direction's every-area check (each area must have its depth art).
- **Rollout enemies**: the care home's Claims Denial Officer (a stern administrator behind a serving tray), the Cinema's Intern Reaper (a reaper usher) and the parlour's Seasonal Temp (a skeleton altar server) have their own art now; check them as for floor 1, and that the Denial Officer's shield arc sits over the tray.
- **Area props** (32315e1, e6bdeea): in each rollout area's combat, shop and treasure rooms at 1x, every prop nameable and none lit like a lamp; the new pictures' outlines after shrinking; the toned station boards and lobby decor in the Waiting Room; the cemetery's weeds (halved, as the basement's paper) and stubble once cut; the deep pool water against the deck; the partition runs joining post to post, and a lone panel; the small seance table on its rug; the contact shadows under the new pictures (the care bed, now wider). Moss, coal dust and the fluorescent glare must be gone with their lights kept.
- **Tests touched without a run**: test_env_art (the partition now has art, its pieces), test_seance_floor (`SeancePartition.ART_SIZE` 32x26). The new PNGs have no .import files yet.
- **Cinema screen frame** (9f5b4d3): the nine-slice frame round a full and a trimmed picture, a cut to black and a flash, and test_cinema_screen.
- **Shots** (6db2026): every shot in the table of section 14 in flight on its floor, beside its warning: the paper shot on every floor, the dart turning with its flight, the coal's flicker, the wreath and the thorns ring it leaves (drawn for a 26 px strike), the plate and lifebuoy turning, the anchor falling and landing, the quoit lying, the tray coming clear, the gavel landing, the memo turning and the form fading, the spirit, the ectoplasm fading; Harold's dentures opening and shutting, flipped, spinning home, glued and with the wind-up key, his needle and banana peel. Check each reads against the warning red lane or ring it flies over, and that Harold's pale ring tells his apart.
- **Shots, second pass** (1b84122): every enemy shot's warm rim against the darkest floors in a window (parlour, terminal, hotline) and the palest (shores, office, cruise deck); the pre-drawn turns of the plate, lifebuoy, memo and film against their old smooth spin; the scythe drawn turned and mirrored the way it sweeps; the stamp coming down over its shadow; the casket on landing; red tape across and down a corridor; the thorns ring (now 56 px) and quoit (31 px) against their reach rings. `PropArt.draw_frame` and `turn_frame` are new and untested.
