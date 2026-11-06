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
  - each area's props against the nameable rule (they keep their env-art pictures; none was redrawn in the rollout);
  - test_art_direction's every-area check (each area must have its depth art).
- **Rollout enemies**: the care home's Claims Denial Officer (a stern administrator behind a serving tray), the Cinema's Intern Reaper (a reaper usher) and the parlour's Seasonal Temp (a skeleton altar server) have their own art now; check them as for floor 1, and that the Denial Officer's shield arc sits over the tray.
