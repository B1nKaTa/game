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
- **Warnings under the small map** (`WarningWindow`, replaced by `MapFade` after its test run, see below): the HUD's first child is a `BackBufferCopy` of the world under `Hud.MAP_PANEL`, taken before any HUD piece draws, and the small map carries a window whose shader redraws from that copy every pixel at or within 20 px of the warning red (`c.r - max(c.g, c.b)`, smoothstep 0.17 to 0.30) at 0.9 alpha. A warning shows through the map where it lies, and the map stays whole elsewhere. It rests on the look's rule that no tile, prop or shot uses the warning red (section 3). This was chosen over lifting warnings above the HUD, which would move dozens of world nodes onto another canvas layer.
- **The planchette's path**: `MadameZaraBehavior.ouija_plan` takes what the camera shows clear of the HUD (`BossMoves.clear_view`: the view below `Hud.BAND_BOTTOM`, less `Hud.MAP_PANEL`) and tries first the words whose whole path shows there with half its band on screen (`OuijaPlanchette.path_shown`), falling back to the old order when none of them leaves a way out.
- **The Projectionist's burn** is laid again on his next turn when leaving the room cleared it (a teleport, the Eternal Warranty), as Madame Zara re-makes her circle, carrying on from the reach it had (`BurnRing.resume`), so the screen's burn does not snap back.
- **`escalator_hum`** was already gone from the sound bank, `tools/sfx/sfx.py` and `audio/sfx` (paths-rework); only history notes name it, so there was nothing to remove.

## Verified on 2026-11-08 (polish, after merging art-direction)

`polish` had branched at 291126a, before art-direction's last six commits (build id, window steadiness, hidden ground cues, side bars), so those were merged in first (9aadf77) and everything below ran on the merged head, in renamed `git archive` copies (GrandpaPol1 for the suite, loop and `--script` probes, GrandpaPolWin for the normal-run window probe), one Godot job at a time. Shots are in `D:\grandpa-shots-ad\polish\` (`tools/probes/polish_look.gd`, `tools/probes/window_look.gd`).

- **Parse and import**: every touched script parses (`--check-only`; options_panel, pause_menu and title_screen only report the autoload names, which `--check-only --script` does not register); `--import` shows no errors.
- **Suite**: one failure on the first run, `test_what_shows_clear_of_the_hud_is_below_its_band_and_off_the_small_map`: the test assumed the view starts at the room's top, but a 352 px room is centred in the 360 px view, so the test was fixed, not the code. The planchette test prints 28 of 28 paths in view in the south half (4 before), so its first-guess thresholds (15 spots, more than before) hold and were kept.
- **Loop**: SMOKE PASS, no SCRIPT ERROR. It logged twelve `keep_vivid` deferred-call errors (a node freed before `DepthLook.keep_vivid` ran; fixed by an untyped argument).
- **Small map** (WarningWindow, replaced): the BackBufferCopy and `hint_screen_texture` shader did work on gl_compatibility (rings showed through the map), but with no warning anywhere near, the window opened over 29% of the map on the parlour's wine carpet and lit wall, and 9% on the basement's bricks. It was replaced by `MapFade`: the map, its floor name and its panel (now its own `Hud.MapBack`) fade to 35% while a warning shape overlaps the map's part of the view, read from the warnings themselves (route_rects, route_circles, lane_rect, a ground strike's radius, else a 40 px circle; an enemy's windup as a 56 px circle when its warnings are drawn). Shots `minimap_*`: whole when quiet on the parlour, basement and hotline; faded for rings and a lane under it; whole again after; the big map covers all. The check costs 35 to 93 us a frame in a large room.
- **Harold's swing**: strip frames 0 and 1 east and west in no cardigan, burgundy, mustard and bingo teal (`swing_*`): no lump behind his back.
- **The Chairman**: his windup and slam in his fight (`chairman_fight_*`) read broad, no slim side-on pose. Under New Management (`new_management_*`): his own art, facing west, a head taller than Harold, his bow (`new_management_bow`, a lean toward Harold at his feet) and his walk out mirrored west. His lines show in the dialogue box, not a bubble.
- **Hand-drawn props** (`prop_*`): the drip stand on the shores, the gauge in the furnace, the candelabra on the parlour carpet and the aisle lights at the Cinema's row ends are all nameable at 1x with their shadows. The gauge's brass glows under the furnace light but does not read as a lamp.
- **Partitions** (`partitions_*`): a muted fabric in a teal frame, office screens and not glass, apart from the violet carpet; runs join, lone panels stand.
- **Planchette** (`zara_planchette_*`): with Harold at three south-half spots of the large room, all three words' paths showed clear of the HUD band and off the map.
- **Projectionist's burn** (`burn_*`): reach 147 of 240 before a teleport out, 150 after coming back (carried on, not reset), one ring, the screen burning 0.61 then 0.63. This found that the boss bar never came back after the teleport; it is now shown again for a standing boss on entering his room.
- **Hidden ground cues** (`cue_*`): a regular's strike with warnings off draws the dark cue (cue() "shadow") on the hotline, parlour, shores, office and basement; faint on the dark hotline, plainly darker on the pale floors, never red. On the hotline's darkest floor its late disc could pass for a shallow hole. The phone psychic's band shows faintly. The steam valve's lane shot missed its windup.
- **Build id in the real exe**: done for playtest 4 (`D:\Grandpa-playtest-4.zip`, built from 4149395 by docs/release/build-steps.md, music from the `check` worktree): a renamed test export of the same stamped source (GrandpaExportTest) shows `build 4149395 (2026-11-08)` in the title corner (`export_test_title.png`) and as the first line of its display_log.txt, so `include_filter` takes build_info.txt into the pck. The real-named exe was not started.
- **Window** (normal run of GrandpaPolWin, on a 2560x1440 screen at 125%): the first window opened at 1920x1080. F11 in Options went fullscreen with the toggle reading On and the draft only changed, F11 again and Alt+Enter both switched, Discard put the window back, OK kept it, F11 on the title switched back. A dragged window stayed at its spot through three video and four audio slider moves, and display_log.txt was not rewritten; a resolution change re-centred it and rewrote the log. A key cell waiting for a key took F11 as its binding; it now turns the fullscreen keys away and keeps waiting. The side bars kept the area's frame through minimise and restore in a 1800x700 window, and went plain black on the title after leaving the run; the frame's viewport was activated again on every repaint (an engine error each time), now only once.

### Still unverified

- **Side bars on a real wide screen in fullscreen**: this PC has only 16:9 screens, and Windows kept reporting the window's size while minimised, so the zero-size guard never ran.
- **Window on other PCs**: 1080p, 1440p and two screens at 100% and 150% scaling; and the first 1920x1080 window on a screen smaller than 1080p (a 1366x768 laptop).
- **The steam valve's** hidden cue mid-windup.

## Boss warnings and the cage lift (2026-11-08, branch `exits-warnings`)

On top of `polish` 95447f7 with `art-direction` 4757d12 merged in (it held the hidden ground cue, e0398a6). Testing was paused for the whole pass: no Godot job ran, so nothing below has been parsed or seen in the engine.

**What each boss attack shows with Attack warnings off.** W is the windup pose and pale flash; "ring", "lane" and "cone" are the dark cue the boss's own warning layer draws; "shadow" is a ground strike's dark cue.

- Activities Coordinator: bingo W, ring, grid spots as shadows row by row; cage W, ring, lane, the balls flying.
- Head of Departures: stamp W, ring, stamp shadow and the stamp dropping in (its outer red ring hidden); runway W, ring, lane cues with the runway lamps blinking, safe-spot mark; gate W, ring (it only pushes).
- Sister Celestine (no windup; the card turning is her tell): tower tile-edge cues and growing tile shadows; death sector cue with the scythe waiting on its edge; wheel band edges and dark blades; star spot cues with the stars streaking down.
- The Chairman: gavel ring cue and the gavel's shadow, gap mark; projections strip cues, gap mark; takeover the cord filling solid, ring cue round Grandpa; charge ring and lane (it follows the takeover with no fresh flash); tape a faint pulsing band; slam ring cue and his fists coming down; restructure drawer-row cues, gap mark.
- Commodore Wellington: anchor ring cue, the anchor on its chain and its shadow; foghorn W, ring, lane; port W, ring (no harm); buoys W, ring, lane cues, then the buoys; swab splash spots as shadows.
- Crabtree: stars W, ring, fanned lane cues, the star shots; thumbs W, ring, the shockwave's reach as a cue, then the ring.
- Doreen: memos W, ring, strip cues, then the paper lands; music W, ring, the spiral as a cue, then the notes.
- Foreman Klaus: slam W, ring, shockwave reach cue; steam W, ring, steam lane cues.
- Head Groundskeeper: slam W, ring; furrow W, ring, lane, shadows; clippings W, ring, four shadows.
- Lorraine: conga W, ring, lane cues, then the dancers, safe-spot mark; karaoke W, ring, cone; quoits W, ring, quoit cue and the quoit falling on its rope.
- Madame Zara: line W, ring, the cord's coil (a leash, no harm); ouija W, ring, the board and planchette, the path as a cue, safe-spot mark; possession W, ring, the faint copy, its trail and rise ring as cues, safe-spot mark; seance swoops the spirit flying in and a spot cue (in a room 50% dim).
- Matron Mercy: sedative W, ring, lane, the darts (pale cue in her Lights Out); gurney W, ring, lane; lights out W, ring, the dimming and "Lights out!" (no harm); visiting W, ring, summon spots as cues.
- Mortimer Grimsby: casket W, ring, shadow and the coffin's growing shadow (now shown with the red hidden); procession W, ring, lane cues, then the bearers; spray W, ring, cone; crescendo W, ring, the pipes glowing and their reach as a cue, safe-spot mark; charge W, ring, lane.
- Old Smokey: breath W, ring, cone; rain W, ring, the coal thrown in its arc; grid W, ring, the forced vents' squares as cues; bellows W, ring, lane (a push).
- The Projectionist: beam W, ring, the lens glowing, the lane and the arc to turn as cues, safe-spot mark, then the beam of light (no red edge); splice W, ring, strip cues between the two lengths of film, safe-spot mark; reel W, ring, the screen cutting to black, then pie or tumbleweed lane cues and the thing itself; the burn's white edge always shows.
- Regional Reaper: sweep W, ring; dash W, ring, lane; ring W, ring, the shots; summon W, ring, summon spots.
- The Reverend: eulogy W, ring, lane, shadows along the line; plate W, ring, lane, return-path cues, then the plate.
- Senior Adjuster: sweep W, ring; charge W, ring, lane.
- Sergeant Wanda: x-ray W, ring, the beam's start as a cue with dark chevrons, then the beam crossing, safe-spot mark; trays W, ring, shadows and the trays fading in.
- Tired Undertaker: shovel W, ring, four shadows; rows W, ring, row shadows; pits W, ring, nothing while the pit follows him, then a shadow; wreaths W, ring, lane, the wreaths flying; summon W, ring, summon spots.
- A summon's spot (`SummonMark`) is a dark cue with its cross for every enemy now, not red.

No hurting attack is left with no tell: an independent read of every behavior found none, and the three it found still red (the stamp's ring, the crescendo's reach, the vent grid) were fixed (3e892ce).

## Waiting Room props (2026-11-08, branch `waiting-props`)

The user played the Waiting Room and named its weak and placeholder props. Testing was paused, so nothing below has run in Godot; the art was judged on Python contact sheets over the Waiting Room's ground tiles. The pictures are built by `py tools/art/waiting_props.py D:/grandpa-art/direction .` (hand-drawn pieces, portraits and the dummy), `py tools/art/npc_strips.py --idle-from-south D:/grandpa-art/direction/merchants art/npcs <ids>` (the merchants) and `area_props.py` (the crystal counter, `props2/crystal_counter.png`).

- **The wanted board** (Bounty Office): the glowing pale box with stick figures is a walnut-framed cork board, 258x84, hung under the north wall left of the north door (`PosterBoard.BOARD_CENTER`, x 32 to 290, top at y 40 under the HUD band), with a pinned WANTED card. Each bounty is a 24x28 paper poster in two rows of ten: a 16x14 sepia print of its boss, cut from his own south rotation (`D:/grandpa-art/direction/portraits/<id>.png`: head and shoulders found from the torso's middle column, box-filtered down, 30% of its own colour kept), over a rubber stamp in a 3x5 pixel font: **REWARD** (deep red) while up, **TAKEN** (navy) while held, **DENIED** (deep red) once the boss is beaten and the reward waits, and **CLOSED** (black, grey paper, the print dimmed and crossed out) once collected. Collected posters now stay on the board in their floor's place (`BountyBoard.board_entries`, `poster_state`); what can be taken or collected is unchanged (`showing`, the bounty panel). The board draws at z -1, under every body.
- **Plain coloured rectangles** were people and a fixture with no art, drawn by `SpriteVisual`'s placeholder box:
  - pink (lobby, 35.png): the Black Market dealer (`merchant`), now a hooded dealer in a purple coat held open on stolen trinkets;
  - teal (lobby): Dr. Squint (`optometrist`), now an old optometrist in a teal coat, huge spectacles and a head mirror, with an eye chart;
  - brown (lobby): Agnes (`crafter`), now an old craft lady in a mustard cardigan, knitting a red scarf with a ball of yarn;
  - pink (Apothecary Wing, 38.png): Madame Murk (`apothecary`), now an apothecary in a plum shawl holding up a potion;
  - orange (Boiler Room, not in the shots): Boom Bernard (`fuel_dealer`), now a stoker in sooty orange overalls holding a bomb;
  - pale pink with a red bar (Training Yard, 37.png): the training dummy ("Intern on a Stand"; the red bar was its health bar), now a stuffed sack in a purple intern's hood on a wooden stand (`art/sprites/training_dummy/idle.png`, one frame, toned), with a contact shadow the scene adds, since it counts as wall-mounted.
  The merchants are `create_character` v3, 48 px, low top-down, black outline, low detail, built as NPC strips (`art/npcs/<art>/`, a breathing idle from the south rotation). `WaitingStation` stands such a merchant on the bottom of his body box with a contact shadow, sorts him by his feet and turns him to face Harold while he is in reach; `SpriteVisual` stays the fallback.
- **The portrait wall** (lobby): the bright flat frames are dark walnut frames with a brass bevel on a dark backing (`trophy_frame`). A beaten boss hangs in colour (`trophy_<boss>`, 16x16, outlined, toned); one still to beat shows as his dark silhouette (the same picture drawn near black). Every frame has a small brass name plate (`brass_plate`: a 3 px cap each side and one stretched middle column) with the name engraved in dark ink, every second plate a row lower, and the endings count sits on a larger brass plaque (`brass_plaque`). The frames moved down from y 34 to 44 (`Departments.TROPHY_WALL_Y`), since the top wall's face is the row the HUD band covers. The mementos' code drawings stay only as the fallback for a frame with no portrait; looking at the wall still lists each memento and its perk.
- **Also fixed** while looking over the Waiting Room: the run door's bare ">" letter is now the stairs plaque that doors in walls hang (`DoorSign` "v"), hung in its arch (`Door.SIGN_AT`), which the run floors' stairwell shares; the Crystal Counter, a purple box, is a counter of crystals and candles on violet cloth (`station_crystal_counter`); the departments' corner cobwebs, five crossed code lines, are a hand-drawn web (`decor_cobweb`).
- Credits: 12 generations (five merchants at 2, the dummy and the counter at 1).

## Cinema story pass (2026-11-08, branch `cinema-story`)

After the user played the Cinema: the lobby card's line did not match the film, the card stood far from the screen, the seats were tiny and too many, and the lines were mostly about the dog. Testing was paused, so no Godot job ran; every change below is unverified in the engine.

- **Lines match the film.** Every one of the 40 lines (`LifeSigns.ALL`) names its film (`scene`), and a card asks only for lines of the film its room's screen plays (`CinemaProps.build` passes the scene to `LifeSigns.take`, through `Progress.take_life_sign`). Each line still shows once a run and is still saved in `life_signs_seen`; lines whose words stayed kept their ids. `CinemaScenes.assign` now gives each screen on a floor a film of its own while unused films remain (neighbours still never match), so a card always has its film's 2 or 3 lines to itself. The full list by film is in `docs/cinema-life-signs.md`.
- **The card beside the screen.** Cards stand only in the 17 screen rooms (none in shops, treasure, item, healing, side, secret or vault rooms), in row 2 right under the screen wall, just west of the picture: x 1 in small rooms, x 2 in medium, x 4 (x 5 in `combat_large_03`, whose x 4 is a pillar) in large. The top left is far from the small map, and no card touches a door.
- **Bigger, fewer seats.** A seat cell is now one chunky velvet seat seen from behind, 28x32 (`CinemaSeat.ART_SIZE`), where the old picture was two or three small seats in 30x15. Built by `area_props.py` from `create_map_object` (low top-down, single colour outline, basic shading, low detail, 48 px canvas) saved as `D:/grandpa-art/direction/props2/cinema_seat.png`, toned like the area's other props. Seat cells across the 33 rooms went from 785 to 349, in rows of 2 or 3 seats (was 3 to 5), with two rows in small and medium rooms and three or four in large ones. Seats are still cover, still break only to blasts and bosses, and still hide a coin at the furniture rate (so the Cinema's seat coins fall with the count). Every layout passes a py port of `validate()` and the Cinema floor tests' rules (runners, screen wall, boss clearance, card placement); only seats were removed or moved, so no cell became harder to reach.
- **Five new films** for parts of his life that had none, made as the first 14 were: `create_image_pro` 160x64 with the bike lesson still as the style image (sepia, film grain), one candidate kept, and its second frame by `edit_image` (a small change, 4 to 15% of pixels, against 7 to 21% in the old pairs). Frames are in `D:/grandpa-art/newpaths/scenes/frames/<id>_f1/_f2.png` and the strips beside them: `bus_route` (at the wheel of the number 12, waving; then his hand back on the wheel), `wedding_day` (the church steps under confetti; then the wind takes his hat), `prize_marrow` (Harold and Gerald with their marrows at the village show; then he leans in to measure), `fishing_trip` (a riverbank under a willow; then he lands a boot) and `caravan_holiday` (a caravan in the rain, the children at the window; then the windbreak blows away).

## To verify (combined branch)

### Boss warnings and the cage lift (`exits-warnings`)

- **Imports first**: `lift_closed.png`, `lift_half.png` and `lift_open.png` are new and have no `.import` files. Run `--import` (in a renamed `git archive` copy, never the real user folder) and commit the three `.import` files it writes, or `test_door.test_the_lift_shows_shut_half_and_open_gates` fails.
- **Suite**: never-run tests `test_attack_warnings` (all of it changed), `test_hidden_cues` (four new tests, two changed), `test_door` (three new). Every touched script is unparsed: `attack_warnings.gd`, `enemy.gd`, `door.gd`, `room_view.gd`, `waiting_room.gd`, `game_settings.gd`, `funeral_director_behavior.gd`, `chief_stoker_behavior.gd`, and the world scripts `anchor_drop`, `burn_ring`, `collection_plate`, `deck_lane`, `desk_slam`, `floor_vent`, `gavel_strike`, `ground_strike`, `hold_music`, `lane_drop`, `lens_beam`, `organ_pipe`, `ouija_planchette`, `possession_ghost`, `procession_lane`, `quoit_ring`, `red_tape`, `reel_lane`, `runway_lane`, `scythe_sweep`, `shockwave`, `spirit_swoop`, `splice_lane`, `star_fall`, `steam_jet`, `summon_mark`, `takeover_tether`, `terminal_strike`, `tower_tiles`, `wheel_ring`, `xray_sweep`.
- **Full loop**: SMOKE PASS, no SCRIPT ERROR (the boss fights draw every changed branch).
- **Boss shots, warnings off** (into `D:\grandpa-shots-ad\exits\`): every boss and mini boss mid-windup and late in each attack listed above, on a dark floor and a pale one. No red anywhere; each cue visible but clearly fainter than red was; the safe-spot mint and the gap mark still there. Then the same few with the setting on: everything red as before. Watch in particular the Matron's pale cue in her Lights Out, Zara's swoops in the dim seance, the x-ray sweep with no red over the room, the wheel's dark blades, the runway lamps blinking, and the Chairman's charge straight after his takeover (no second flash).
- **Lift shots**: the stairwell appearing in a boss room on a depth floor and a flat one (its gates folding open over 0.6 s, half frame then open), its 72 px height against whatever stands north of it (it may cover a prop up to two cells above), Grandpa walking into it from each side (y-sorted: in front from the south, behind it from the north) and going down on the same trigger; the Waiting Room run door at cell (26, 8), standing open, against the lobby's wall and props above it; the dial reading as "down" at 1x.

- **Waiting Room props** (`waiting-props`), none of it run. Run `--import` first: every new PNG lacks its `.import` file, so `ResourceLoader.exists` (and with it `PropArt`, `NpcSprite` and the new tests) sees none of them until then. Tests new or changed: `test_bounties` (the board fits, keeps clear of the wall, door and HUD, poster states, every print), `test_departments.test_every_station_has_a_picture_and_every_merchant_a_person`, `test_mementos.test_every_frame_has_a_portrait_and_the_name_plates_never_meet`, `test_enemy_art.test_an_enemy_without_art_keeps_its_placeholder_and_marks`. Scripts never parsed: `poster_board.gd`, `trophy_wall.gd`, `waiting_station.gd`, `door.gd`, `bounty_board.gd`, `waiting_room.gd`, `departments.gd`. Shots:
  - the Bounty Office with a fresh save, then with a taken, a won and a collected poster: the board under the HUD band, every stamp legible at 1x, the prints nameable, Harold drawn over the board wherever he stands, the station's prompt over it;
  - the lobby's portrait wall with some bosses beaten: portraits and silhouettes, each plate's words centred inside its brass (the fallback font's ascent decides it: `PLATE_ABOVE_BASELINE` 7, `PLAQUE_ABOVE_BASELINE` 9), the endings plaque clear of the trophy station's prompt and the ticket machine, the frames at y 44 clear of the HUD at both ends of the camera's travel;
  - each merchant at his station (lobby, Apothecary Wing, Boiler Room): standing on his feet, sorted against Harold, turning to face him in reach and back to south, not lit like a lamp, his prompt and voice as before;
  - the training dummy in the yard: its picture on its stand, the shadow under it, the damage numbers and the health bar over its head;
  - the run door and a floor's stairwell with the stairs plaque in the arch; the Crystal Counter's picture under its label; the cobwebs in a department's corners, the mirrored one in the top right.

- **Cinema story pass** (branch `cinema-story`, nothing run):
  - `--import` first: the five new strips in `art/cinema/scenes/` have no `.import` files, and `seat_row.png` changed size (30x15 to 28x32).
  - tests touched without a run: `test_life_signs` (the topics test is new, the scene-filtered take is new), `test_cinema_floor` (seat count 250 to 400, the card test now wants cards beside the screen in the 17 screen rooms and none elsewhere, a shop has no card, a card's lines are its film's, the seat's size), `test_cinema_screen` (19 films, each film once a floor while films remain) and `test_seance_floor` (coin pieces against the old 785 seats). `test_cinema_bosses` reads `floor_boss_01` and `floor_boss_large_01`, which have fewer seats now: read its OverlapRoute and "harder than" numbers.
  - shots (`cinema_look.gd`, its sign shots now in screen rooms): a combat room of each size at 1x with Harold beside a row, the seats reading as seats and at his scale, their contact shadows, the aisle lights at the new row ends; a card beside the screen in each room size, its bubble placement under the HUD's left panel, and its line naming what the film shows; the five new films on the screen with flicker and the cross-fade.
  - play: walk a Cinema floor and read every card against its screen; check the rooms still feel like fights with fewer seats (cover against the Usher's charge and the popcorn tubs), the film reel's bounces, and the Projectionist's and Crabtree's fights in their rooms.
  - bot: one Cinema batch (`max good 20 1 3 boss`) against the last numbers, since cover changed.
