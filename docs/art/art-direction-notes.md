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
  - A world attack a regular starts (the popcorn tub, phone cord, perfume, write-up, crystal ball, steam jet, shuffleboard puck, ground strike) asks `AttackWarnings.drawn_by(source)` before drawing red; the thing itself (the tub and its shadow, the memo, the mist, the ball) always shows. The crystal ball flashes pale as its burst starts.
  - Only the shapes hide: a regular's stun stars and spoken lines always show.
  - A riser (the Plot Holders) winds up under Harold, where his body hides its mound, so with the ring hidden it flashes a pale ring round the spot and kicks up earth (`Enemy._draw_rising_cue`).

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

## Side bars on wide screens

Godot 4 has no `black_bars_set_images`, and on gl_compatibility the bars stay black whatever the clear colour. `SideBars` therefore keeps one window-sized viewport that paints the area's dark frame and the game's own picture at the rect Godot would use (`SideBars.picture_rect`), and takes the game's viewport off the screen every frame, since two viewports shown on one window halved the frame rate. Input mapping stays Godot's own. It switches on only while the window has bars; with none (an exact 16:9 fit) the screen is Godot's and only the window size is compared each frame. Measured with `art_direction_look.gd barcost` on a 2540x1080 window, vsync off: 0.94 ms a frame with the frame against 0.89 ms with black bars (p95 1.30 against 1.21), the mouse read back to within the same half pixel either way, and a change on screen after one frame either way. Shot with `wide`.

## Verified on 2026-11-07

Testing resumed ("test everything"). Shots are in `D:\grandpa-shots-ad\verify2` (every area), `verify3` (windups, wide window, bars, lineups) and `verify4` (rising cue, hats).

- Suite and two full loops pass; the window opens inside its screen, F11 toggles fullscreen and is kept.
- Every area's combat room, fight with the setting off and on, door shut and open, mini boss and boss. With the setting off no regular draws red (fixed: seven world attacks drew theirs regardless); bosses and mini bosses keep theirs. Warning reds stay distinct on the parlour's wine carpet and the office's red tape.
- Every regular's windup flashes pale and reads, except the risers, which now have their own cue. The usher, the sunbather and the lost luggage never wind up in plain sight (they shush or ambush).
- The Waiting Room's parquet was calmed (saturation 0.58 to 0.37, `depth_art.py` `patch`). Harold's flat cap was reshaped onto his hair.
- Bodies read on every floor. The Chairman measures 0.32 (a charcoal suit, which a value lift cannot raise), but reads on the pale carpet; a lighter redraw would lift him.

## Fixed on 2026-11-07 (fix5)

Shots are in `D:\grandpa-shots-ad\fix5` (`art_direction_look.gd fix5`).

- **The Chairman** is redrawn in the depth style (`create_character` v3, 64 px, low top-down, black outline, low detail) in a light silver pinstripe with a navy tie, broad as before, gavel in hand. His idle, walk and the windup and slam cut from his attack are built into a 72 px canvas (`enemy_strips.py`, export in `D:/grandpa-art/direction/enemies`). He measures 0.54 alone and 0.42 in his fight, where his own warning fills tint him.
- **Cardigans are outfits.** Each cardigan cosmetic drawn as a cardigan has its own copy of Harold's three strips with his olive cardigan redrawn in its colour (`tools/art/harold_outfits.py`, `art/sprites/grandpa_<id>/`): his five cardigan tones each become the same step of a ramp built from the cosmetic's colour, so every frame lines up with his own. `GrandpaLook.outfit_art` picks the art and `SpriteVisual.set_art` swaps it without restarting the anim. He faces east in the art and is mirrored for west, as before. The code band remains only as the fallback for a cardigan with no outfit built; the Power Tie is still drawn in code.
- **Sunset Shores' carpet** is turned from salmon to a dusty teal (`depth_art.py` `patch_hue`, `turn_patch`): on the salmon a boss's ring all but vanished, on the teal every ring and fill reads.
- **The Crossroads** is plain earth (`plain`): its lone cobble patch at the south wall read as a pile beside Harold, even dimmed.

The list below is the checklist as it was written before the run.

- **Window on other PCs** (2026-11-07). On a friend's PC the window came out bigger than the screen, cropping the HUD on the left, and changing the resolution in Options did not help. The changes:
  - sizes now come from the window's own screen, its free area outside the taskbar, less the title bar;
  - the window is never placed past the screen's top-left corner;
  - the default is a 1920x1080 window, not fullscreen;
  - F11 and Alt+Enter toggle fullscreen;
  - user://display_log.txt records what the game saw of the screens.

  Check that it opens fully on screen on 1080p, 1440p and two-screen setups, with Windows scaling at 100% and 150%; that F11 and Alt+Enter work and are kept; that the Options resolution list fits the screen; and that test_game_settings passes.
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

## Polish pass (2026-11-08, branch `polish`)

Art leftovers and small bugs, on top of `art-direction` 291126a. The user asked for no testing during this pass, so no Godot job ran at all: no suite, no loop, no import, no screenshot. Every change below is unverified in the engine.

- **Harold's thrust frames** (export attack frames 7 and 8, strip frames 0 and 1) carried a dark slate satchel behind his back. `harold_strips.py` clears every pixel left of his back outline on rows 26 to 37 of those frames (`LUMP_ROWS`, `TRIM`), and `harold_outfits.py` rebuilt the three cardigan outfits from the fixed strip. The idle and walk are byte for byte as before.
- **The Chairman in the endings** plays his own art: `ActorLook.SPRITE_ART` maps the cutscene actor `chairman` to `chairman_of_the_board`, and `CutsceneActor` stands that SpriteVisual on his feet (`set_feet(0)`), mirrored for west. The code drawing is only the fallback now, in his art's silver suit, pinstripe and navy tie. His idle holds a gavel while the scene hands Harold another; a small continuity point left as it is.
- **The Chairman's slam** turned him side on, a 22 px torso against 29 to 30 in his idle and walk. `enemy_strips.py` gains `WIDEN`, guarded by the export's hash: on each row his back (outline and rim) moves out by up to 7 columns and the gap is filled with a copy of the cloth behind the rim, rising smoothly from the shoulders and falling to the hips. The slam measures 30 and 28 px, the windup's last frame 27 (was 25). Nothing else in a frame moves.
- **Small props drawn by hand** (`tools/art/hand_props.py`, run after `area_props.py`, which now leaves them to it as `'hand'`): the care home's drip stand (14x27: hook bar, a fluid bag with a label, a tube, a wheeled base), the furnace's gauge (16x20: a brass dial with ticks and a needle on a pipe and flange), the parlour's candelabra (14x25: three lit cream candles on a brass stand, which reads on the wine carpet where the black one sank) and the Cinema's aisle light (10x6, was 8x5: a dark brass rim round a warm lens, flat with no outline). Each fills its old box; the props keep their collision.
- **The hotline's partitions**: the bright violet glass panes with a diagonal glare are a muted slate fabric with a faint two-tone weave inside the teal frame (`hand_props.partition_fabric`, mapping the five pane tones). Rerun `hand_props.py` whenever `area_props.py` rebuilds the hotline.
- **Warnings under the small map** (`WarningWindow`): the HUD's first child is a `BackBufferCopy` of the world under `Hud.MAP_PANEL`, taken before any HUD piece draws, and the small map carries a window whose shader redraws from that copy every pixel at or within 20 px of the warning red (`c.r - max(c.g, c.b)`, smoothstep 0.17 to 0.30) at 0.9 alpha. A warning shows through the map where it lies, and the map stays whole elsewhere. It rests on the look's rule that no tile, prop or shot uses the warning red (section 3). This was chosen over lifting warnings above the HUD, which would move dozens of world nodes onto another canvas layer.
- **The planchette's path**: `MadameZaraBehavior.ouija_plan` takes what the camera shows clear of the HUD (`BossMoves.clear_view`: the view below `Hud.BAND_BOTTOM`, less `Hud.MAP_PANEL`) and tries first the words whose whole path shows there with half its band on screen (`OuijaPlanchette.path_shown`), falling back to the old order when none of them leaves a way out.
- **The Projectionist's burn** is laid again on his next turn when leaving the room cleared it (a teleport, the Eternal Warranty), as Madame Zara re-makes her circle, carrying on from the reach it had (`BurnRing.resume`), so the screen's burn does not snap back.
- **`escalator_hum`** was already gone from the sound bank, `tools/sfx/sfx.py` and `audio/sfx` (paths-rework); only history notes name it, so there was nothing to remove.

## To verify when testing resumes

Run everything in a renamed `git archive` copy (never the real user folder), one heavy job at a time.

- **Suite**: `tools/test.ps1` must pass with 0 failed and no SCRIPT ERROR. New or changed tests that have never run:
  - `test_cinema_bosses.test_the_burn_is_laid_again_after_his_stored_room_was_cleared`;
  - `test_seance_bosses.test_what_shows_clear_of_the_hud_is_below_its_band_and_off_the_small_map`;
  - `test_seance_bosses.test_the_planchette_keeps_its_path_in_view_when_a_word_there_will_do`, whose thresholds (15 or more south-half spots, more words in view than before) are first guesses: read its printed line;
  - `test_floor_map_view.test_warnings_under_the_small_map_show_through_it`, which calls `Hud._ready` out of the tree;
  - `test_ending_scripts.test_the_chairman_wears_his_own_art_in_the_endings`.
  Every touched script has never been parsed by Godot: `warning_window.gd` (its shader too), `hud.gd`, `floor_map_view.gd`, `boss_moves.gd`, `madame_zara_behavior.gd`, `ouija_planchette.gd`, `projectionist_behavior.gd`, `burn_ring.gd`, `actor_look.gd`, `cutscene_actor.gd`. Run `--check-only` on them first if the suite will not start.
- **Imports**: the changed PNGs keep their paths and `.import` files, so nothing new should import, but run `--import` and check for errors.
- **Full loop**: one bot loop, SMOKE PASS, no SCRIPT ERROR in the whole log.
- **Shots** (into `D:\grandpa-shots-ad\polish\`):
  - Harold's swing in every cardigan (`fix5` cardigan sheet): no lump in strip frames 0 and 1, east and west;
  - Under New Management: the Chairman in his art, his size beside Harold (his 72 px canvas against Harold's 60), his bow and his walk out mirrored west, his speech bubble placed over his taller head;
  - the Chairman's windup and slam in his fight, his width steady through idle, walk, windup and slam;
  - the drip stand, gauge, candelabra and aisle lights at 1x in a combat room of their floors, against the nameable rule, with their contact shadows; the aisle light 10 px wide at a row end beside the seats;
  - a run of hotline partitions and a lone panel under the area's light, reading as office partitions, not glass, and still apart from the violet carpet;
  - a lane warning in the top right of a large room under the small map: it must show through the map, and the map must stay whole with no warning there (and over the parlour's wine carpet, where faint red tones may open the window a little); check `BackBufferCopy` and `hint_screen_texture` behave this way on gl_compatibility, and that the big map still covers it;
  - Madame Zara's planchette in the large room with Harold in its south half: its path in view below the HUD band and off the small map;
  - the Projectionist in phase two: leave by teleport and come back, and the burn ring is back at the reach it had, the screen burning with it.
- **Save guard**: the real `slot_1\save.json` MD5 was d5100b123e498c491f6fa88f5b879d27 (2026-11-06 17:52) when this pass began; nothing in it ran Godot.

### Art-direction review fixes (2c6819b to d2f153e, merged into polish)

Testing was stopped on 2026-11-08 ("don't test anything right now"). Already checked before the stop, in a renamed export: the suite (2258 tests, 0 failed, on d2f153e), one full loop (SMOKE PASS), the title screen and pause menu with a stamped build id (`D:\grandpa-shots-ad\buildid`), and the side-bar frame in a 1440x900 window (`D:\grandpa-shots-ad\sidebars`: picture not black, 12 of 12 frames show that frame's picture, the same after minimise and restore). Still to check:

- **Build id in a real exe** (2c6819b): run the build steps (docs/release/build-steps.md) once into a scratch folder, start the exe, and check that the title corner and the first line of display_log.txt name the stamped commit. That proves `include_filter="build_info.txt"` takes the file into the pck; no exe was exported.
- **F11 with Options open** (5fc40b5): open Options, press F11 and Alt+Enter, and check that the window switches, the Fullscreen toggle's text follows, OK keeps the change, and Esc then "Discard" puts the window back. Also F11 while a key cell waits for a key (it should be ignored).
- **Window steadiness** (5fc40b5): drag the window, move a brightness or volume slider in Options, and check that the window stays where it was dragged; change the resolution and check that it re-centres. display_log.txt should be written at startup and on a mode or size change only (check its time stamp after slider moves).
- **Hidden ground cues** (e0398a6): with Attack warnings off, shoot the bingo caller's marks (floor 1 and the hotline), a steam valve's lane (furnace) and a Phone Psychic's band (hotline) mid-warning and late, on a dark floor and a pale one. The dark cue must be visible but clearly fainter than the red shapes, and it must never read as a hole or a floor pattern.
- **Side bars** (d2f153e): the probe's minimised window kept reporting 1440x900, so the zero-size guard never ran. Check minimise and restore on a real wide screen in fullscreen. Check the bars turn plain black on the title screen after Save and Quit from a run. On a screen smaller than 1920x1080 (a 1366x768 laptop), check how the first window looks: it now opens at 1920x1080 before Settings shrinks it. The probe's shots are the frame viewport's own image, not a grab of the screen.
