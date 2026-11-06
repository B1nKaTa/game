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
- **Decals ignore the grid.** Puddles, cracks and grit are baked once as small textures and dropped at pixel offsets (`DECAL_DENSITY`). The flat look's code puddles and cracks stay out of a depth room.
- **Basement scatter.** The floor's grass is loose paper here; cut grass is torn scraps. Holes are black pits.

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
- **Font.** `res://art/ui/basement_ledger.ttf`, a pixel font made for the game with PixelLab `create_font`, drawn at 8 px (16 px for large lines) with antialiasing off and a 2 px black outline. Glyphs it lacks fall back to the engine font.

## 10. Doing another floor

1. Generate one ground tileset (two terrains that suit the place), one wall sheet (fronts and tops), and the floor's props, with the settings in section 2.
2. Build them with `tools/art/depth_art.py`, setting that floor's tones in the build so the top is darker than the front and the ground stays under the bodies.
3. Set `art_style = "depth"` on its FloorDef.
4. Shoot it with `tools/probes/art_direction_look.gd` and check the body luminance, the warnings and the doors in the shots before keeping it.
