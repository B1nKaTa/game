# Art Inventory and PixelLab Plan

Written 2026-11-05 on branch `round-2` for the art pass. Today the whole game is placeholder drawing: boxes, polygons and `_draw()` code. Only Harold (`art/sprites/grandpa/`) and the 9 NPCs (`art/npcs/`) have art.

Item icons are **on hold** while the items are reviewed. Section 2.12 lists where they go, but they are not counted in any total.

Generation costs below come from PixelLab's own help (`search_help`, asked on 2026-11-05) where it gave a number. Anything marked **est.** is a guess to check against the job receipt.

**Contents**

1. How art is loaded today
2. Every visual entity, by floor and path
3. Totals and recommended order
4. Style guide
5. Readability constraints

---

## 1. How art is loaded today

### 1.1 SpriteVisual: enemies, Harold, hub stations and Harold in cutscenes

The code is in `scripts/world/sprite_visual.gd`.

**Path.** Art is loaded from `res://art/sprites/<art_id>/<anim>.png`, one horizontal strip per anim.
- The strip is cut into `frame_width` frames (`hframes = texture width / frame_width`).
- It loops at `FPS = 10`. `play_once(anim, duration)` stretches one pass over `duration`.
- The `Sprite2D` is **centred on the node's origin**, with no feet offset.
- A shader handles the hit flash (`flash()`), alpha and a multiply `tint`. Modulate never reaches the art.
- Without the file it draws the placeholder: a `body_size` box in `def.color` (brightness at least 0.55), a black outline and a pale halo.

**Enemies** (`scripts/actors/enemy.gd:153-155`).
- The call is `_visual.setup(def.id, def.body_size, def.color, def.frame_width)`. The art id is the EnemyDef's `id` and there is no `art_id` field.
- `frame_width` defaults to 32. The data uses 48 for mini bosses and 64 for floor bosses.
- `setup` calls `play("idle")`, and **nothing else ever calls `play`, `play_once` or `set_facing_left` on an enemy.** Enemies only ever show `idle`, and they never flip.
- Hurt is only the 0.08 s white shader flash. A stun shows code-drawn stars.
- Death has no animation. `room_view.gd:758` spawns `DeathBurst` (`scripts/world/death_burst.gd`): squares in `def.color`, bigger for a boss.
- A submerged enemy hides its sprite, and `enemy.gd:_draw` draws a dirt mound (or 3 grey smoke circles for `hidden_look = "smoke"`).
- `EnemyMarks` (`scripts/world/enemy_marks.gd`, plus `cruise_marks.gd`, `golf_marks.gd` and `terminal_marks.gd`) draws each type's hat or held prop over the box, chosen by `def.mark`. The art should absorb these. EnemyMarks also draws the shield arc of the Claims Denial Officer, and that arc must stay.

**Harold** (`scripts/actors/player.gd`).
- The call is `setup("grandpa", Vector2(20, 28), ..., SPRITE_FRAME_WIDTH = 68)`.
- Anims asked for:
  - `idle` and `walk` (line 648, by input);
  - `attack` through `play_once("attack", CaneCombo.LOCK_TIME)` (line 554), which is also used for the charged swing.
- He faces left or right by flip, from his aim (`set_facing_left(_aim.x < 0)`, line 313).
- The dodge uses `make_ghost()`, a tinted copy of the current frame, so it needs no anim.
- His feet box is 14x12 at (0, 17). Its bottom edge is `SPRITE_FEET_Y = 23`, and `tests/test_combat.gd:167` checks it.
- Current strips: `idle` 272x68 (4 frames), `walk` 408x68 (6), `attack` 204x68 (3).
- The cane is still drawn in code over the sprite when a cane cosmetic is worn (`player.gd:727-736`).

**Hub stations** (`scripts/world/waiting_station.gd`) with an `art` key use SpriteVisual with 32 px frames and a 22x30 box. They are `merchant`, `optometrist`, `apothecary`, `fuel_dealer` and `crafter`, and none of them exists yet.

**Cutscenes** (`scripts/world/cutscene_actor.gd`): Harold is the only actor with a SpriteVisual. It plays `idle`, `walk`, and `attack` for "swing".

**Anims the code asks for today:** `idle`, `walk` and `attack`. Nothing asks for `hurt` or `death`; a flash and a burst stand in for them. Every other enemy anim listed in section 2 needs a code hook first (see 1.8).

### 1.2 NpcSprite

The code is in `scripts/world/npc_sprite.gd` and is used by `scripts/world/npc.gd`. The art id is `NpcDef.art()`, which is `art_id` or else `id`.

- `res://art/npcs/<art_id>/idle.png` holds 48 px frames of him standing facing south, looping at 8 fps.
- `res://art/npcs/<art_id>/rotations.png` holds 8 frames in the order S, SE, E, NE, N, NW, W, SW (`direction()`). South plays the idle loop; every other way holds a rotation.
- The feet go on the node origin. Each strip is placed by its own lowest used row (`used_rows`), because PixelLab's idle frames stand 1 to 5 px higher than its rotations.
- The strips are built by `py tools/art/npc_strips.py <export> art/npcs`.
- All 9 art ids have art: coach_bertram, dealer, deputy_dolores, duty_free_clerk, gerald, pro_shop_keeper, purser, severance_clerk, shop_merchant. `dealer_back_room` uses `dealer`.

### 1.3 Case-file icons

The path is built in `scripts/core/case_file_data.gd`:
- `ITEM_ICON_DIR`, line 23: `res://art/icons/items/<id>.png` (used at line 87);
- `ENEMY_ICON_DIR`, line 24: `res://art/icons/enemies/<id>.png` (used at line 263).

They are drawn in `scripts/ui/case_file.gd:615-617` (CaseCell):
- `draw_texture_rect(load(path), rect.grow(-2), false)` draws the icon stretched into **26x26** inside a 30x30 cell, without keeping the aspect ratio.
- A known item with no icon shows a colour chip and its initials.
- The Bestiary has 71 enemies (all 72 defs except `training_dummy`). There are 100 items.

### 1.4 Rooms: floors, walls, decor and props

All of these are code; Section 2 lists each piece by path.

**Floors and walls** (`scripts/world/room_backdrop.gd`, z -10).
- Tiles are 32 px (`TILE = 32`). A medium room is 20x11 cells, a large one 30 wide, the smallest 10x7.
- Each floor cell takes `floor_a`, `floor_b` or `floor_c` by 3x3-cell patches, plus a noise wobble (`floor_jitter`), grout and speckle.
- Each wall cell (`#`, `l`, `o`) is a `wall` rectangle with a `wall_line`.
- `floor_pattern` values:
  - 0 plain tile;
  - 1 woven carpet;
  - 2 iron tread plate;
  - 3 polished mall tile;
  - 10 teak deck;
  - 12 office carpet tile;
  - 13 mown fairway stripes (`golf_look.gd`).
- `wall_pattern` values:
  - 0 line;
  - 1 brick;
  - 2 wood panels;
  - 3 shop shutters;
  - 10 ship rail;
  - 12 office plaster and dado;
  - 13 hedge.
- **There is no texture hook.**

**Palettes** (`scripts/content/room_palette.gd`): one `RoomPalette` sub-resource in each `data/floors/*.tres`. It holds the room tones (floor, wall, darkness, ambient, torch, fill_light), the colours of every prop family, the patterns, the decor weights and `scatter_lights`.

**Lighting** (`scripts/world/lighting.gd`).
- A `CanvasModulate` is set to `palette.ambient`, so **it multiplies every sprite**.
- Fill lights are PointLight2D at `FILL_ENERGY = 0.32`, one every 8 cells.
- Torch lights sit along the walls. They are light only, with no sprite.
- Decor lights come from torches, lanterns, furnaces, stained glass and fluorescents.
- `light_flicker.gd` wobbles the energy.
- Every enemy carries a small read glow (`enemy.gd` READ_GLOW, energy 0.3, scale 0.6).

**Decor** (`scripts/world/decor_layer.gd`, z -9, kinds in `scripts/content/room_decor.gd`).
- Decor is drawn by `_draw_placeholder` in 4 jittered variants.
- **A hook exists:** `PropArt.texture("decor_" + kind)`, i.e. `res://art/props/decor_<kind>.png`.
- The comments in `decor_layer.gd` and `terminal_decor.gd` say `res://art/decor/<kind>.png`. The code wins.

**Breakable props** (`scripts/world/breakable_block.gd` and its about 40 subclasses).
- **A hook exists:** `PropArt.texture(art_id())` (`scripts/world/prop_art.gd`) loads `res://art/props/<art_id>.png`. It is drawn at native size, centred, as one still image.
- `hole.gd` uses `res://art/props/hole.png` and `pool_water.gd` uses `res://art/props/pool_water.png`.
- `art/props/` does not exist yet.
- **Limit:** one PNG, no states. Cut grass, the reinforced stone's glow, fountain and pool ripples and the mimic's breathing are drawn only in placeholder code, so a still PNG would hide them.

**Golf hedge and pennants.**
- `scripts/world/hedge.gd` is a breakable that has the hook (`5` cell). The hedge **walls** are `GolfLook.draw_wall_tile`, which has none.
- The pennants are the flag cloth on `flag_pin.gd` (breakable, has the hook) and on `ball_washer.gd`.

### 1.5 Projectiles, hazards and telegraphs

**Projectiles** (`scripts/actors/projectile.gd`, z 55, hit radius 12).
- They are pure `_draw` by `look`:
  - paper: an 8x10 sheet;
  - `make_dart()`: a 10x5 syringe;
  - `coin`: r5;
  - `ornament`: r5;
  - `note`: a quaver.
- `golf_ball_shot.gd` extends it.
- **There is no texture hook.**

**Hazards** (`floor_vent`, `organ_pipe`, `conveyor_strip`, `red_tape`, `sand_trap`, `queue_barrier`, `wet_floor`, `steam_jet`, `perfume_cloud` and the others): all `_draw`, with no hook. Many have states (idle, warning, active, held).

**Telegraphs**, all code, which is right (see section 5):
- `enemy._draw_warning` on a WarningLayer at z 60: circle, lane and cone fills in `#e4524f`;
- `scripts/world/ground_strike.gd`: rings, a following crosshair, and the coal, thorns, casket and splash looks;
- `summon_mark.gd`: a red r16 and an X;
- `safe_spot_mark.gd` and `gap_mark.gd`: green rings;
- `lights_out.gd`: a black overlay with a 70 px hole.

**Enemy overlays drawn in code**, which rotate to any angle:
- the Baggage Handler's trolley;
- the Caddie and Club President's golf cart (`CaddieBehavior.Cart`);
- the Mall Santa's `Sleigh`;
- the Pallbearers' `CoffinCarry`;
- Mortimer's `CoffinShell`;
- the Tour Group's `GuideFlag`.

### 1.6 HUD and menus

No font file or Theme exists. Everything uses Godot's fallback font with outlines.

- **`scripts/ui/hud.gd`:**
  - pills as the text characters ■ and □;
  - Pension as text;
  - the item row as text;
  - Slip and Thermos counters drawn by `scripts/ui/consumable_icon.gd`, about 12x13;
  - the potion slot (`scripts/ui/potion_slot.gd`), a code-drawn flask of 10x13;
  - the boss bar, a 480x10 ColorRect at (80, 336);
  - the minimap (`floor_map_view.gd`), code-drawn squares.
- **Menus** (`scripts/ui/menu_style.gd`): StyleBoxFlat with a gold selection bar. The hub panels are a StyleBoxFlat with stock Buttons.
- **Case file:** StyleBoxFlat folder and pages.
- **Card table:** cards, suits and slot symbols all drawn in code.
- **Title screen:**
  - the logo is the **text** "GRANDPA" at size 44 (`scripts/scenes/title_screen.gd`);
  - the picture is all `_draw` in `scripts/ui/title_scene_art.gd`: the queue, the take-a-number machine and the NOW SERVING sign.
- **Opening:** text only (`scripts/scenes/opening.gd`).
- **There is no texture hook anywhere in the UI** except the case-file icons.

### 1.7 Waiting Room and endings

- **Waiting Room** (`scripts/scenes/waiting_room.gd`, `scripts/core/departments.gd`):
  - stations, boards, the trophy wall, the poster board, lobby decor, the arcade tables and department signs are all `_draw`;
  - the five station people use the SpriteVisual path, with no art yet.
- **Endings:**
  - `scripts/world/cutscene_stage.gd` draws 13 side-view stages in code, at 320x180 shown 2x;
  - `scripts/world/actor_look.gd` draws every actor except Harold, and every prop;
  - their anims are transforms (rotate, hop, tilt, fade), not frame strips;
  - **there is no hook for actor or prop art**, and Gerald's and the Dealer's NPC art is not used there.

### 1.8 Where code must be added before art can show

| # | Hook | Where | Why |
|---|---|---|---|
| H1 | **Enemy anim driver** | `enemy.gd`, `enemy_behavior.gd` | Today it is idle only. Wanted: `walk` while moving, `windup` while `is_winding_up()`, `attack` by `play_once` when a strike lands, named specials (e.g. `charge`, `emerge`, `summon`), and `set_facing_left(direction_to_target().x < 0)`. A generic mapping covers about 80% of behaviours. The rest call `enemy.play_anim(name)`. |
| H2 | **Feet offset in SpriteVisual** | `sprite_visual.gd` | The sprite is centred today. Place each strip by its lowest used row, as `NpcSprite.used_rows` does, so the feet land on `+body_size.y / 2` for enemies and on `SPRITE_FEET_Y` for Harold. |
| H3 | **`EnemyDef.art_id` and recolour** | `enemy_def.gd`, `sprite_visual.gd` | 16 enemy ids are floor variants of another (section 2). They should share one art folder, plus a palette swap or a hue-shift uniform in the existing shader. The shader `tint` only multiplies, which cannot turn purple into green. |
| H4 | **`frame_width` in the data** | `data/enemies/*.tres` | A data change, not code: 32/48/64 become the real canvas sizes (section 4.3). |
| H5 | **Tile textures** | `room_backdrop.gd`, `golf_look.gd` | Load `res://art/tiles/<floor_id>/floor_*.png` and `wall_*.png` per cell, keeping the a/b/c patch choice and leaving the pattern code as the fallback. |
| H6 | **Stateful props** | `prop_art.gd` / `breakable_block.gd` | Allow `res://art/props/<id>_<state>.png` or a strip: grass cut/uncut, reinforced glow, fountain, pool, organ pipe, vents, conveyor and barrier. |
| H7 | **Doors, chests, pickups, Thermos, Retirement Plan** | `door.gd`, `chest.gd`, `pickup.gd`, `thermos.gd`, `retirement_station.gd` | None loads art. Keep the door's letter icon and the pickup's name label in code over the art. |
| H8 | **Projectile looks** | `projectile.gd`, `golf_ball_shot.gd`, `shuffleboard_puck.gd`, `collection_plate.gd`, `ground_strike.gd` (coal, thorns, casket) | e.g. `res://art/fx/<look>.png`, rotated to flight where it matters. |
| H9 | **Enemy overlays** | trolley, golf cart, sleigh, coffin carry, coffin shell, guide flag | One top-down sprite each, rotated as today. |
| H10 | **Hub** | `waiting_station.gd`, `lobby_decor.gd`, `trophy_wall.gd`, `poster_board.gd`, `arcade_table.gd`, `department_sign.gd` | Move the five station people to NpcSprite (48 px, like the other NPCs), and boards to PropArt. |
| H11 | **Cutscenes** | `actor_look.gd`, `cutscene_stage.gd` | Actors get an NPC-style east frame or SpriteVisual. Stages get one backdrop PNG each, with props over it. |
| H12 | **UI** | `hud.gd`, `consumable_icon.gd`, `potion_slot.gd`, `menu_style.gd`, `title_screen.gd`, `title_scene_art.gd`, `card_table_panel.gd`, `case_file.gd` | TextureRects and StyleBoxTexture in place of the drawn shapes and ■ □ text. |
| H13 | **Bestiary icons** | a tool, not game code | Cut `res://art/icons/enemies/<id>.png` from each enemy's first idle frame with a py script. This costs no generations. |

### 1.9 Enemy art as built (H1 to H4, 2026-11-05)

H1 to H4 are in. The first ten enemies have art: intern_reaper, stoker, mall_cop, club_golfer, hr_representative, regional_reaper, old_smokey, mall_santa, thaddeus_fairweather and chairman_of_the_board. On 2026-11-06 the other 38 exports went in, and the regenerated, lighter Regional Reaper replaced his first export. Every enemy outside the Mall and Fairway's End now has art, except the Training Yard dummy. The decisions and per-enemy verdicts are in `docs/art/enemy-art-notes.md`.

- **Folders.** `res://art/sprites/<art_id>/<anim>.png`, one row of square frames per anim. `EnemyDef.art()` is `art_id`, or the id when that is empty.
- **Building strips.** Run `py tools/art/enemy_strips.py D:/grandpa-art/enemies art/sprites [id ...]`. It reads `<id>/<state>/animations/<anim>/east/frame_###.png` (or `south/` for an object drawn facing south) and writes every anim folder it finds as `<anim>.png`. idle and walk keep every frame. Every other anim drops frame 000, the reference pose. All frames of one enemy go on one square canvas, a multiple of 4 wide, centred on the source canvas's middle column, with each frame's lowest row on one feet row.
- **Anim names the game asks for.** `idle`, `walk`, `windup` and `attack`, plus any name a behavior plays through `Enemy.play_anim(name, seconds)`: the Mall Cop's `whistle`, and each floor boss's own two (the Undertaker's `wreath_throw` and `point`, the Matron's `lights_out` and `charge`, Mortimer's `embalming_spray` and `conduct`, the Commodore's `foghorn_blast` and `buoy_call`, Augustine's `runway_signal` and `gate_change`). A boss plays its own over the windup plus `EnemyAnim.ATTACK_TIME`, called right after its `set_warning`, and the driver lets it run through the windup and the hit instead of the plain `windup` and `attack`. The Matron's `charge` plays for the length of her gurney dash. Put a new one in the export as `animations/<name>/east/` and rerun the tool.
- **Cuts.** `CUTS` in the tool picks frames for one export, matched by the hash of its frames: the windup is cut from the first frames of the attack, and the attack is trimmed to open on the strike. A newer export of the same anim gets the default (every frame but 000), and a real `windup` folder always wins over a cut. A cut with a fourth element `True` replaces the export's own anim of that name: the mimic's export opens its lid in the idle, so its idle keeps the closed frames and its windup and lunge are cut from the open ones.
- **H1, the driver** (`EnemyAnim`, `Enemy._update_anim`, run every frame).
  - `windup` plays once over the warning's windup and holds its last frame.
  - `attack` plays for `EnemyAnim.ATTACK_TIME` (0.3 s) from the frame the windup ends, which is when every enemy's hit lands.
  - Otherwise it shows `walk` while its own walk moves it, and `idle` when it stands still.
  - While busy or standing it faces Harold; while walking it faces the way it walks, by mirroring the east-drawn art.
  - Fallbacks (`SpriteVisual.resolve`): windup, attack and walk fall back to idle. A behavior's own anim falls back to attack, then to idle. With no idle, the placeholder box draws as before.
  - An enemy with no attack strip keeps walking or standing when its windup ends.
- **H2, the feet.** `SpriteVisual.set_feet(body_size.y / 2)` stands the visual on the body box bottom. Each strip is placed by its own lowest used row there. Harold's visual does the same at `SPRITE_FEET_Y`.
- **H3, sharing art.** `art_id` lets an enemy use another's art. `art_hue_from`, `art_hue_to` and `art_hue_width` (in degrees) recolour that art in the shader. Only hues inside the band move, and only on pixels at least 0.15 saturated, so skin, greys and whites stay. `art_value` multiplies the value of the same band. The reapers use it to lift their robes on the Records Basement (1.3 for the intern, 1.5 for the Regional Reaper).
- **Objects that never turn.** `EnemyDef.art_flips` is true by default. The mimic, the Lost Luggage and the steam valve were drawn facing south, so it is false for them and they are never mirrored. The paper shredder is drawn facing east and mirrors like the rest.
- **H4, frame size.** `EnemyDef.frame_width` defaults to 0, which means square frames as tall as the strip.
- **Marks.** `EnemyMarks` draws no hat or prop for an enemy that shows art. The shield arc still draws.
- **Draw order.** Floor scenes, the Waiting Room, the sandbox and every RoomView sort by y.
  - Enemies, NPCs and Harold stand their looks on their feet, so they sort by where their feet are. Props sort by their middles.
  - Harold's own drawing (swing, cane skin, crosshair) sits at z 1, over every body.
  - Holes, pool water and laid sand sit at z -8, under the bodies.
  - Warnings stay at z 60.

### 1.10 Room art as built (H5 to H7, 2026-11-06)

H5, H6 and H7 are in.
- **Tiles.** `res://art/tiles/<set>/floor_a_N.png`, `floor_b_N.png`, `floor_c_N.png`, `wall_N.png` and `wall_face_N.png`, chosen per cell by `TileArt`. The set is `FloorDef.art()`.
- **Props.** `res://art/props/[<set>/]<id>[_<state>].png` through `PropArt`, covering breakables, decor, doors, chests (with open states), pickups, the Waiting Room boards and the hazards' resting looks.

Every hook, state and choice is in `docs/art/env-art-notes.md`. Build with `py tools/art/env_art.py tiles|props D:/grandpa-art/env .`.

---

## 2. Every visual entity, by floor and path

### Key

**Tool codes:**
- **C48 / C36 / C32**: `create_character` (v3) at that canvas, 2 gens. The v3 canvas max is 256 px. 96 px costs 3.
- **C64 / C88**: `create_character` (v3) at 64 or 88 px, 2 gens.
- **A**: a v3 custom anim facing east, about 1 gen per direction at 64 px or under. At 88 px count **2 (est.)**, because the cost is `ceil(canvas² x frames / 65,536)` and the generated canvas can be larger than the sprite.
- **T**: a template anim, 1 gen per direction. Do not mix it with custom anims on one character (STYLE_GUIDE).
- **MO**: `create_map_object`, low top-down, transparent, 1 gen.
- **AO**: `animate_object` v3, 1 gen at 64 px or under for 8 frames.
- **PX**: `create_image_pixen` at 16-64 px, 1 gen per image (for icons and small projectiles).
- **TS**: a tile set per path. `create_topdown_tileset` Pro (honours the low view, 32 px tiles) is 15, plus `create_tiles_pro` for floor variants (10-25). Count **25 per path (est.)**.
- **UI**: `create_ui_asset`, minimum canvas 192, 10 gens up to 256.
- **Recolour**: a floor variant takes its base's art with a palette swap (H3), 0 gens. If a swap reads wrong, `create_character_state` costs 10 per variant.

**Facing codes:**
- **E+flip**: draw facing east only, and the game mirrors it. This needs H1 for enemies.
- **none**: it does not turn.
- **4-way later**: it would read better with 4 directions. This is not costed. It adds about 1 gen per anim per extra direction.

**Anims.** "windup" is the first frames of the attack, held, and is cut free from the attack strip unless it is listed with its own cost. Every regular enemy gets `idle`, `walk` and `attack` as a minimum.

**Body size** is the `body_size` in its `data/enemies/<id>.tres`. The physics box is 0.8 of it.

### 2.1 Floor 1: The Records Basement (`data/floors/floor_1.tres`)

**Enemies**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| intern_reaper | intern_reaper.tres | 20x24 | idle, walk, windup 0.45, swing | E+flip | C48 + 3A | 5 |
| filing_clerk | filing_clerk.tres | 18x24 | idle, walk (keeps distance), throw | E+flip | C48 + 3A | 5 |
| debt_ghost | debt_ghost.tres | 20x22 | float (idle and walk in one), charge (windup from its start) | E+flip, lane | C48 + 2A | 4 |
| seasonal_temp | seasonal_temp.tres | 13x15 | idle, run (pack), bite | E+flip | C32 + 3A | 5 |
| notary_public | notary_public.tres | 18x26 | idle, walk, stamp burst (3 shots) | E+flip | C48 + 3A | 5 |
| burnt_out_auditor | burnt_out_auditor.tres | 18x20 | idle, walk, lit-fuse crawl. The blink and blast are code. | E+flip | C36 + 3A | 5 |
| denial_officer | denial_officer.tres | 28x32 | idle, walk with shield up, windup 0.9 (shield drops), strike. The shield arc stays code. | E+flip, 4-way later | C48 + 3A | 5 |

**Bosses**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| senior_adjuster (mini) | senior_adjuster.tres | 32x38 | idle, walk, windup, sweep, charge, summon | E+flip | C64 + 6A | 8 |
| regional_reaper (boss) | regional_reaper.tres | 40x48 | idle, walk, windup, sweep, dash, ring cast, summon | E+flip | C88 + 6A@2 | 14 |

**Summons:** intern_reaper (mini boss) and seasonal_temp (boss), both counted above.

**Projectiles**

| id | from | gens |
|---|---|---|
| paper sheet (`projectile.gd` default, 8x10) | Filing Clerk, Notary, Regional Reaper ring | PX 1 |

**Props and decor** (layout letters in `data/rooms/floor_1/`)

| id | type | size | gens |
|---|---|---|---|
| crate | breakable `X` | 32 | MO 1 |
| rock | `O` | about 30 | MO 1 |
| barrel | `Q` | 24x28 | MO 1 |
| bone_pile | `Z` | 22x16 | MO 1 |
| grass | `g`, uncut and cut | 22x18 | MO 2 (H6) |
| hole | `V` | 32 | MO 1 |
| decor_bones, decor_cobweb, decor_puddle, decor_crack | decor | 20-28 | MO 4 |
| decor_torch, decor_lantern | decor with an AO flame each | 20-28 | 4 |

**Tiles:** grey stone tile (pattern 0) and stone wall (pattern 0): TS 25.

**Records Basement total: 97**

### 2.2 Floor 1: The Unkempt Cemetery (`data/floors/cemetery.tres`)

It shares the 7 Records regulars, plus:

**Enemies and bosses**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| plot_holder | plot_holder.tres | 20x24 | idle, walk, attack, emerge (dig = emerge reversed). The mound is code. | E+flip | C48 + 4A | 6 |
| head_groundskeeper (mini) | head_groundskeeper.tres | 32x38 | idle, walk, windup, spade slam, furrow dig, summon | E+flip | C64 + 6A | 8 |
| tired_undertaker (boss) | tired_undertaker.tres | 40x48 | idle, walk, windup, shovel drop, point (pits), wreath throw, summon | E+flip | C88 + 6A@2 | 14 |

**Summons:** plot_holder (both bosses).

**Props and decor**

| id | type | size | gens |
|---|---|---|---|
| gravestone | `A` | 20x26 | MO 1 |
| dead_tree | `Y` | 32x40 | MO 1 |
| decor_stump, decor_moss, decor_sapling | decor | 20-28 | MO 3 |

The cemetery reuses the Records rock, barrel, bones, grass and hole. The undertaker's wreath volleys use the paper-sheet hook, recoloured.

**Tiles:** grass-and-earth floor, mossy stone wall: TS 25.

**Cemetery total: 58**. **Floor 1 total: 155.**

### 2.3 Floor 2: Sunset Shores Eternal Care (`data/floors/sunset_shores.tres`)

**Enemies**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| orderly | orderly.tres | 18x26 | idle, walk, fire dart | E+flip | C48 + 3A | 5 |
| cart_nurse | cart_nurse.tres | 22x22 | idle, walk pushing the cart, charge, stunned after a wall hit. The cart is part of the sprite. | E+flip, 4-way later | C48 + 4A | 6 |
| bingo_caller | bingo_caller.tres | 18x24 | idle, walk, call | E+flip | C48 + 3A | 5 |
| shores_seasonal_temp | shores_seasonal_temp.tres | 13x15 | as seasonal_temp | E+flip | recolour | 0 |
| shores_denial_officer | shores_denial_officer.tres | 28x32 | as denial_officer | E+flip | recolour | 0 |
| resident (summon) | resident.tres | 18x24 | idle, walk, swing | E+flip | C48 + 3A | 5 |
| mimic (floors 2-5) | mimic.tres | 24x20 | breathe (as the locked chest), hop, lunge with the lid open | none | MO + 3AO | 4 |

**Bosses**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| activities_coordinator, Barbara (mini) | activities_coordinator.tres | 32x38 | idle, walk, windup, ball-cage spin, bingo-grid call, summon | E+flip | C64 + 6A | 8 |
| matron_mercy (boss) | matron_mercy.tres | 40x48 | idle, walk, windup, dart-fan throw, gurney charge (she rides one; no overlay today), lights-out gesture, summon | E+flip | C88 + 6A@2 | 14 |

**Summons:** resident (Barbara), orderly (Matron).

**Projectiles and hazards**

| id | notes | gens |
|---|---|---|
| sedative dart (`make_dart`, 10x5, rotated) | | PX 1 |
| `lights_out.gd` | stays code | 0 |

**Props**

| id | type | size | gens |
|---|---|---|---|
| care_bed | `D` | 22x30 | MO 1 |
| armchair | `K` | 28x26 | MO 1 |
| wheelchair | `J` | 24 | MO 1 |
| food_trolley | `F` | 24 | MO 1 |
| flower_vase | `f` | 14x20 | MO 1 |
| wet_sign | beside `W` | 14x20 | MO 1 |
| wet floor | `W` (`wet_floor.gd`) | 32 | MO 1 |
| decor_plant, decor_iv_stand | decor | | MO 2 |

**Tiles:** care-home carpet (pattern 1) and pastel wall: TS 25.

**Sunset Shores total: 82**

### 2.4 Floor 2: The Furnace Works (`data/floors/furnace_works.tres`)

**Enemies**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| stoker | stoker.tres | 20x26 | idle, walk, shovel throw | E+flip | C48 + 3A | 5 |
| steam_valve | steam_valve.tres | 22x22, wall-mounted | idle drip, vent. The 4 jets are `steam_jet.gd`. | none | MO + 2AO | 3 |
| soot_ghost | soot_ghost.tres | 18x24 | float, materialise (dissolve = reversed), swipe. The smoke is code. | E+flip | C48 + 3A | 5 |
| furnace_intern_reaper | furnace_intern_reaper.tres | 20x24 | as intern_reaper | E+flip | recolour | 0 |
| furnace_burnt_out_auditor | furnace_burnt_out_auditor.tres | 18x20 | as burnt_out_auditor | E+flip | recolour | 0 |

**Bosses**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| foreman_klaus (mini) | foreman_klaus.tres | 34x40 | idle, walk, windup, hammer slam, steam call, summon | E+flip | C64 + 6A | 8 |
| old_smokey (boss) | old_smokey.tres | 44x50 | idle, walk, windup, fire breath, coal throw, bellows pull. No summon. | E+flip | C88 + 6A@2 | 14 |

**Summons:** stoker (Klaus).

**Projectiles and hazards**

| id | notes | gens |
|---|---|---|
| coal lump (GroundStrike coal) | | PX 1 |
| steam puff (`steam_jet.gd`) | | AO 1 |
| flame sprite (`flame_burst.gd`) | The cone warning stays code. | AO 1 |

**Props**

| id | type | size | gens |
|---|---|---|---|
| coal_heap | `M` | 30x25 | MO 1 |
| coal_sack | `L` | 26x28 | MO 1 |
| furnace_crate | `R` | 24 | MO 1 |
| pipe_valve | `p` | 14x20 | MO 1 |
| floor_vent | `U`, idle and flare | 32 | MO + AO 2 |
| decor_coal_dust, decor_pipe, decor_gauge | decor | | MO 3 |
| decor_furnace | in the wall, with an AO fire | | 2 |

**Tiles:** iron tread plate (pattern 2) and brick wall (pattern 1): TS 25.

**Furnace Works total: 74**. **Floor 2 total: 156.**

### 2.5 Floor 3: Golden Years Mall at 7 a.m. (`data/floors/golden_years_mall.tres`)

**Enemies**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| mall_walker | mall_walker.tres | 16x20 | idle (the line freezes on the whistle), power-walk, break-away run | E+flip | C36 + 3A | 5 |
| mall_cop | mall_cop.tres | 20x24 | idle, walk, scooter run, whistle | E+flip, lane | C48 + 4A | 6 |
| perfume_sprayer | perfume_sprayer.tres | 18x24 | idle, walk, spray. The cloud and haze are code. | E+flip | C48 + 3A | 5 |
| mall_intern_reaper | mall_intern_reaper.tres | 20x24 | as intern_reaper | E+flip | recolour | 0 |
| mall_notary_public | mall_notary_public.tres | 18x26 | as notary_public | E+flip | recolour | 0 |
| mall_elf (summon) | mall_elf.tres | 12x14 | idle, run, swing | E+flip | C32 + 3A | 5 |

**Bosses**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| gloria (mini) | gloria.tres | 32x40 | idle, walk, windup, coin toss, splash call, summon | E+flip | C64 + 6A | 8 |
| mall_santa (boss) | mall_santa.tres | 44x50 | idle, walk, windup, present throw, "ho ho" ring, conveyor call | E+flip | C88 + 6A@2 | 14 |
| sleigh overlay | `Sleigh` in mall_santa_behavior.gd | about 48x28, rotated | | top-down | MO | 1 |

**Summons:** mall_walker (Gloria), mall_elf (Santa).

**Projectiles**

| id | gens |
|---|---|
| coin (r5) | PX 1 |
| ornament (r5) | PX 1 |
| present (`present_drop.gd`, r18) | MO 1 |

**Props**

| id | type | size | gens |
|---|---|---|---|
| shopping_cart | `a` | 28x24 | MO 1 |
| gumball_machine | `z` | 18x32 | MO 1 |
| mall_planter | `d` | 30x28 | MO 1 |
| mall_fountain | `q`, with ripple | 32x26 | MO + AO 2 |
| sale_sign | `e` | 16x22 | MO 1 |
| conveyor strip | `> < ^ v`, belt plus a moving anim | 32 | MO + AO 2 |
| decor_bench, decor_fluorescent, decor_food_table | decor | | MO 3 |

**Tiles:** polished mall tile (pattern 3) and shop shutters (pattern 3): TS 25.

**Mall total: 83**

### 2.6 Floor 3: Eternal Rest Funeral Parlour (`data/floors/funeral_parlour.tres`)

**Enemies**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| weeping_mourner | weeping_mourner.tres | 16x20 | idle, walk, wail, lunge | E+flip | C36 + 4A | 6 |
| florist | florist.tres | 18x24 | idle, walk, wreath toss | E+flip | C48 + 3A | 5 |
| pallbearer | pallbearer.tres | 20x26 | idle, carry-walk, ram, walk alone, strike | E+flip | C48 + 5A | 7 |
| parlour_plot_holder | parlour_plot_holder.tres | 20x24 | as plot_holder | E+flip | recolour | 0 |
| parlour_seasonal_temp | parlour_seasonal_temp.tres | 13x15 | as seasonal_temp | E+flip | recolour | 0 |

The pallbearers' coffin carry uses the dropped_coffin art below.

**Bosses**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| reverend (mini) | reverend.tres | 32x40 | idle, walk, windup, preach (Eulogy), plate throw, summon | E+flip | C64 + 6A | 8 |
| mortimer_grimsby (boss) | mortimer_grimsby.tres | 42x50 | idle, walk, windup, casket slam, embalming spray, crescendo conduct | E+flip | C88 + 6A@2 | 14 |
| coffin shell (phase 2) | `CoffinShell` | | still plus a charge anim | top-down | MO + AO | 2 |

**Summons:** weeping_mourner (Reverend). The procession uses pallbearer art.

**Projectiles**

| id | gens |
|---|---|
| wreath (thrown, GroundStrike thorns) | PX 1 |
| collection plate (`collection_plate.gd`, r6) | PX 1 |

**Props**

| id | type | size | gens |
|---|---|---|---|
| chapel_pew | `h` | 30x25 | MO 1 |
| hymn_cart | `j` | 27x21 | MO 1 |
| wreath_stand | `r` | 18x22 | MO 1 |
| candle_stand | `c`, with flame | 14x24 | MO + AO 2 |
| dropped_coffin | from pallbearers; already hooked at `art/props/dropped_coffin.png` | about 36x18 | MO 1 |
| organ_pipe | `o`, rest and glow | 32 | MO + AO 2 |
| decor_stained_glass, decor_coffin_stand | decor | | MO 2 |

**Tiles:** wine carpet (pattern 1) and wood panels (pattern 2): TS 25.

**Parlour total: 79**. **Floor 3 total: 162.**

### 2.7 Floor 4: The Last Resort Cruise (`data/floors/last_resort_cruise.tres`)

**Enemies**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| early_bird_diner | early_bird_diner.tres | 16x20 | idle, walk, ring bell, rush | E+flip | C36 + 4A | 6 |
| shuffleboard_shark | shuffleboard_shark.tres | 18x24 | idle, walk, cue aim and shot | E+flip | C48 + 3A | 5 |
| sunburnt_sunbather | sunburnt_sunbather.tres | 22x18 | asleep (as the deck chair art), snap awake, walk, swat | E+flip | C48 + 4A | 6 |
| cruise_orderly | cruise_orderly.tres | 18x26 | as orderly | E+flip | recolour | 0 |
| cruise_stoker | cruise_stoker.tres | 20x26 | as stoker | E+flip | recolour | 0 |

**Bosses**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| lorraine (mini) | lorraine.tres | 32x40 | idle, walk, windup, karaoke sing, quoit toss, summon | E+flip | C64 + 6A | 8 |
| commodore_wellington (boss) | commodore_wellington.tres | 44x52 | idle, walk, windup, anchor throw, foghorn blast, buoy call | E+flip | C88 + 6A@2 | 14 |

**Summons:** early_bird_diner (Lorraine). Conga dancers reuse diner art.

**Projectiles**

| id | gens |
|---|---|
| puck (r7) | PX 1 |
| quoit (r22) | PX 1 |
| anchor (`anchor_drop.gd`) | MO 1 |
| lifebuoy (DeckLane) | PX 1 |

**Props**

| id | type | size | gens |
|---|---|---|---|
| deck_chair | `b`, also the sunbather's disguise | 26x24 | MO 1 |
| buffet_tray | `0` | 22x18 | MO 1 |
| lifeboat_davit | `2` | 28x26 | MO 1 |
| pool_water | `1`, already hooked, with ripple | 32 | MO + AO 2 |

**Tiles:** teak deck (pattern 10) and ship rail (pattern 10): TS 25. `ship_deck.gd` (the roll) stays code.

**Cruise total: 73**

### 2.8 Floor 4: Fairway's End Golf Club at Midnight (`data/floors/fairways_end.tres`)

**Enemies**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| caddie | caddie.tres | 22x22 | idle, walk, climb out (rest) | E+flip | C48 + 3A | 5 |
| golf cart overlay | `CaddieBehavior.Cart`, also the Club President's and the parked cart | about 30x22, rotated | | top-down | MO | 1 |
| club_golfer | club_golfer.tres | 18x26 | idle, walk, drive swing ("FORE!") | E+flip | C48 + 3A | 5 |
| gopher | gopher.tres | 16x16 | idle, emerge, bite. The mound is code. | E+flip | C32 + 3A (or the quadruped template, T) | 5 |
| golf_bingo_caller | golf_bingo_caller.tres | 18x24 | as bingo_caller | E+flip | recolour | 0 |
| golf_soot_ghost | golf_soot_ghost.tres | 18x24 | as soot_ghost | E+flip | recolour | 0 |

**Bosses**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| chip (mini) | chip.tres | 32x40 | idle, walk, windup, chip shot, putt, summon | E+flip | C64 + 6A | 8 |
| thaddeus_fairweather (boss) | thaddeus_fairweather.tres | 46x52 | idle, walk, windup, hole-in-one swing, cart drive (uses the cart overlay), sprinkler call | E+flip | C88 + 6A@2 | 14 |

**Summons:** gopher (Chip), caddie (Thaddeus).

**Projectiles and hazards**

| id | gens |
|---|---|
| golf ball (r4) | PX 1 |
| giant ball (`giant_ball_drop.gd`) | PX 1 |
| sprinkler head (`sprinkler_sweep.gd`). The sector warning stays code. | PX 1 |

**Props**

| id | type | size | gens |
|---|---|---|---|
| flag_pin (pennant) | `3`, with flutter | 14x26 | MO + AO 2 |
| ball_washer | `4` | 22x31 | MO 1 |
| hedge | `5` | 32x28 | MO 1 |
| sand | `s` (`sand_trap.gd`); the bunker patch reuses it | 32 | MO 1 |
| decor_fog | | | MO 1 |

The parked cart (a lone `5`) reuses the golf cart art. Grass, bench and plant are shared.

**Tiles:** mown fairway (pattern 13) and hedge wall (pattern 13): TS 25.

**Fairway's End total: 72**. **Floor 4 total: 145.**

### 2.9 Floor 5: Departures, Terminal Zero (`data/floors/terminal_zero.tres`)

**Enemies**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| tour_group | tour_group.tres | 14x18 | idle, walk, guide call, rush, wander lost | E+flip | C36 + 4A | 6 |
| guide flag | `TourGroup.GuideFlag` | pennant on a pole | | none | PX | 1 |
| baggage_handler | baggage_handler.tres | 22x24 | idle, walk pushing, charge, dazed. The trolley reuses luggage_trolley. | E+flip, 4-way later | C48 + 4A | 6 |
| lost_luggage | lost_luggage.tres | 22x18 | lying asleep, wake, shuffle, bite | none | MO + 4AO | 5 |
| airport_weeping_mourner | airport_weeping_mourner.tres | 16x20 | as weeping_mourner | E+flip | recolour | 0 |
| airport_mall_cop | airport_mall_cop.tres | 20x24 | as mall_cop | E+flip | recolour | 0 |

**Bosses**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| sergeant_wanda (mini) | sergeant_wanda.tres | 32x40 | idle, walk, windup, x-ray wand sweep, tray toss, summon | E+flip | C64 + 6A | 8 |
| augustine (boss) | augustine.tres | 44x52 | idle, walk, windup, boarding-stamp slam, runway signal, gate-change call | E+flip | C88 + 6A@2 | 14 |

**Summons:** lost_luggage (Wanda), tour_group (Augustine).

**Projectiles**

| id | notes | gens |
|---|---|---|
| security tray (TerminalStrike) | The "DEPARTED" stamp stays code text. | PX 1 |

**Props**

| id | type | size | gens |
|---|---|---|---|
| queue_barrier | `=`, posts with the rope down and up | 32 | MO 2 |
| luggage_trolley | `6` | 30x28 | MO 1 |
| suitcase_stack | `7` | 20x22 | MO 1 |
| departure_seats | `8` | 30x24 | MO 1 |
| departure_board | decor, with a flip anim | | MO + AO 2 |

**Tiles:** blue terminal carpet (pattern 1) and pale wall (pattern 0): TS 25.

**Departures total: 73**

### 2.10 Floor 5: Head Office, Eternity Incorporated (`data/floors/head_office.tres`)

**Enemies**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| yes_man | yes_man.tres | 16x20 | idle, walk, nod ("Yes!"), lunge | E+flip | C36 + 4A | 6 |
| paper_shredder | paper_shredder.tres | 22x24 | idle, walk, charge, grind halt | E+flip, 4-way later | C48 (non-humanoid) + 4A | 6 |
| hr_representative | hr_representative.tres | 18x24 | idle, walk, memo toss | E+flip | C48 + 3A | 5 |
| office_florist | office_florist.tres | 18x24 | as florist | E+flip | recolour | 0 |
| office_perfume_sprayer | office_perfume_sprayer.tres | 18x24 | as perfume_sprayer | E+flip | recolour | 0 |

**Bosses**

| id | file | body | anims (from the code) | facing | tool | gens |
|---|---|---|---|---|---|---|
| doreen (mini) | doreen.tres | 32x40 | idle, walk, windup, memo-storm call, hold-music phone, summon | E+flip | C64 + 6A | 8 |
| chairman_of_the_board (boss) | chairman_of_the_board.tres | 44x52 | idle, walk, windup, gavel slam, desk slam, takeover pull, charge | E+flip | C88 + 7A@2 | 16 |

**Summons:** yes_man (Doreen).

**Projectiles and hazards**

| id | gens |
|---|---|
| memo (LaneDrop memos) | PX 1 |
| gavel (`gavel_strike.gd`) | MO 1 |
| filing drawer (LaneDrop drawers) | MO 1 |
| bar-chart bar | PX 1 |
| music note (Hold Music) | PX 1 |
| write-up form (`write_up_mark.gd`) | PX 1 |
| paper scraps (`paper_trail.gd`) | PX 1 |

**Props**

| id | type | size | gens |
|---|---|---|---|
| cubicle_wall | `N` | 32x29 | MO 1 |
| water_cooler | `9`, already hooked | 18x29 | MO 1 |
| in_tray | `y` | 18x16 | MO 1 |
| red tape | `x`, strung and cut; the warning outline stays code | 32x8 | MO 2 |
| decor_ficus, decor_office_chair | decor | | MO 2 |

**Tiles:** office carpet tile (pattern 12) and plaster and dado (pattern 12): TS 25.

**Head Office total: 80**. **Floor 5 total: 153.**

### 2.11 Shared by every floor

**Doors** (`door.gd`, 28x28). Path tints come from a recolour. The letter icon stays code.

| id | gens |
|---|---|
| door, open | MO 1 |
| door, locked | MO 1 |
| door, needs a Slip | MO 1 |
| door, chained | MO 1 |
| stairwell (icon `v`) | MO 1 |
| secret-wall crack | MO 1 |
| reinforced vault stone, with its glow | MO + AO 2 |

**Pickups** (`pickup.gd`, a 16 px disc today)

| id | gens |
|---|---|
| Pension coin, with a spin anim | PX + AO 2 |
| Permission Slip | PX 1 |
| Overheated Thermos, as a pickup and placed with its fuse blink (`thermos.gd`) | PX + AO 2 |
| Small Potion | PX 1 |
| Heal pill | PX 1 |
| Recipe | PX 1 |

**Chests** (`chest.gd`). They have no opened state today.

| id | gens |
|---|---|
| lunchbox | MO 1 |
| locked, with its rattle | MO + AO 2 |
| safe | MO 1 |
| urn | MO 1 |

The mimic's sleeping look is the locked chest.

**Other shared pieces**

| id | gens |
|---|---|
| Retirement Plan (`retirement_station.gd`), shut and cracked | MO 2 |
| Arcade table, slot top and card top (`arcade_table.gd`). Also used in the Back Room. | MO 2 |
| Crossroads path sign, open and chained (`path_sign.gd`) | MO 2 |
| Crossroads and landing tiles. These may instead be a recolour of the Records set. | TS est. 15 |

**Effects** stay code: death burst, dodge ghost, item_fx, shockwave, closing ring, x-ray beam, runway lamps and pipe rings. Code keeps them in step with the hitboxes. 0 gens.

**Shared total: 42**

### 2.12 Item icons (on hold, not counted)

There are 100 items in `data/items`. Their art would go in three places:

1. `res://art/icons/items/<id>.png`. The case file has this hook already; the icon is drawn at 26x26.
2. Item pickups in rooms, shop wares, boss and urn choices (`pickup.gd`). Today these are a disc in the rarity colour, and there is no hook (H7).
3. The HUD item row, which is text today.

One PX per item at 32 px, scaled down for the HUD, would be about 100 gens plus rerolls.

### 2.13 The Waiting Room (`scripts/scenes/waiting_room.gd`, `scripts/core/departments.gd`)

There are 14 departments: Lobby, Hallway, Bounty Office, Training Yard, Apothecary Wing, Boiler Room, Decor Office, Back Room, Annexe, Upper Landing, Purser's Office, Pro Shop, Duty Free, Executive Suite.

**People.** The NPCs with art are Gerald, Deputy Dolores, Coach Bertram, the Dealer, the Purser, the Pro Shop keeper, the Duty Free clerk and the Severance clerk. They need no new art.

The five station people need art, after moving them to NpcSprite (H10). Each is C48 plus an idle facing south (1 A); the 8 rotations come with the character.

| id | who | gens |
|---|---|---|
| merchant | Black Market | 3 |
| optometrist | Dr. Squint | 3 |
| apothecary | Madame Murk | 3 |
| fuel_dealer | Boom Bernard | 3 |
| crafter | Agnes | 3 |

**Training dummy.** `training_dummy`, "Intern on a Stand", body 22x32, wall-mounted, in the Training Yard. It needs an idle and a hit wobble. Tool: MO + AO, **2**.

**Stations and boards.** These are code rects today.

| id | room | size | gens |
|---|---|---|---|
| key_board | Lobby | 28x36 | MO 1 |
| forms_counter | Lobby | 28x36 | MO 1 |
| ticket_machine | Lobby | 20x28 | MO 1 |
| noticeboard | Lobby | 34x24 | MO 1 |
| decor_counter | Decor Office | 44x24 | MO 1 |
| item_rack | Training Yard | 36x28 | MO 1 |
| Pro Shop board | Pro Shop | 40x24 | MO 1 |
| Duty Free board | Duty Free | 40x24 | MO 1 |
| severance_desk | Executive Suite | 48x24 | MO 1 |
| employee_plaque | Executive Suite | 30x20 | MO 1 |
| ending-archive filing cabinet | Executive Suite | 22x34 | MO 1 |

**Trophy wall** (`trophy_wall.gd`). The frame is 22x22, MO 1. The 10 mementos are PX 1 each: name badge, bent shovel, bedpan, coal shovel, top hat, empty sack, anchor, golf trophy, boarding pass and gold gavel. **11** in all.

**Poster board** (`poster_board.gd`): the cork board 104x30 and a wanted paper 8x11. MO + PX, **2**.

**Lobby decor** (`lobby_decor.gd`)

| id | gens |
|---|---|
| potted_fern | MO 1 |
| motivational_poster | MO 1 |
| better_chair | MO 1 |
| warm_lamp | MO 1 |
| fish_tank, with its fish and bubbles | MO + AO 2 |
| new_carpet, a 10x5-cell rug (MO 1, or a tile) | 1 |

**Department sign plate** (`department_sign.gd`): the text stays code. MO **1**.

**Waiting Room tiles:** today the default stone palette is used. Give it its own waiting-room carpet and wallpaper, TS **25**.

**Waiting Room total: 74**

**Harold redraw** at 44 px: C44 plus idle, walk and attack (3 A). The attack starts with the cane already forward, and the cane is gripped in every frame (STYLE_GUIDE). **5.**

### 2.14 Ending puppet scenes (`scripts/content/endings/*.gd`)

There are 11 endings and the Augustine boss scene. The stage is side view, 320x180 at 2x, with the ground at y 128 (`cutscene_stage.gd`). The actor anims are transforms, so most actors need only a standing east frame and a walk.

**Actors that reuse other art (0 gens):**
- Harold uses his sprite;
- Gerald and the Dealer use their NPC east rotation;
- the Chairman and Augustine use their boss art;
- the mourners reuse weeping_mourner;
- the clerk (Excess Baggage) reuses severance_clerk.

All of these need H11.

**New actors**, each C48 plus a walk (1 A):

| id | ending | gens |
|---|---|---|
| doctor | By a Thread | 3 |
| exterminator | Literally | 3 |
| mover, one art for the pair | Fortune and Glory | 3 |

**Props** (22), each MO 1, **22** in all: gavel, file, cheque, letter, wreath, coffin_lid, grapes, grape, photos, souvenirs, garage_door, shirt, boarding_pass, torn_pass, monitor, monitor_flat, sandwich, ladder, zzz, baggage tower, ticket, spray. The zzz text and the monitor line could stay code.

**Stage backdrops** (13), side view at 320x180, about 5 each (**est.**; check with `get_pro_flash_capabilities` or the receipt), **65** in all: stairs_home, fence, funeral, hospital, garage, gerald_house, airport_home, office_top, waiting_room, departures_desk, kitchen, bathroom, living_room.

**The opening** is text only and needs no art.

**Endings total: 96**

### 2.15 Title screen and UI

| piece | where | tool | gens |
|---|---|---|---|
| Title logo "GRANDPA" | `title_screen.gd` (text today) | UI 256x96 | 10 |
| Title picture: waiting-hall backdrop 640x360 | `title_scene_art.gd` | est. | 10 |
| Title: robed soul in the queue (recoloured x7), idle sway | `title_scene_art.gd` | C36 + 1A | 3 |
| Title: take-a-number machine, NOW SERVING sign | `title_scene_art.gd` | MO 2 | 2 |
| HUD icons at 16 px: pill full, pill empty, Pension coin, Slip, Thermos, timer clock | `hud.gd`, `consumable_icon.gd` | PX 6 | 6 |
| Potion slot: empty flask plus a fill mask (the potion colour fills it in code) | `potion_slot.gd` | PX 2 | 2 |
| Boss bar frame | `hud.gd` | UI | 10 |
| Menu panel (9-slice) and button, normal and selected; also the hub panels | `menu_style.gd` and the hub panels | UI 2 | 20 |
| Case file folder plus tab, and paper page | `case_file.gd` | UI 2 | 20 |
| Cutscene text box | `cutscene_player.gd` | UI | 10 |
| Card table: card face, card back, 4 suits, felt, 6 slot symbols (cherry, bell, pill, skull, coin, dentures) | `card_table_panel.gd` | PX 13 | 13 |
| Pixel font, optional (there is no font file today) | everywhere | `create_font` est. | 10 |
| Minimap | `floor_map_view.gd` | stays code | 0 |

**Title and UI total: 116**

**Cosmetics** (15 worn items in `data/cosmetics/`, drawn in code by `scripts/world/grandpa_look.gd`) have no art hook. They would need overlay strips matched frame by frame to Harold's anims. Keep them code-drawn for now; they are not counted.

---

## 3. Totals and recommended order

### 3.1 Totals (first-pass generations, before rerolls)

| Group | Paths | Gens |
|---|---|---|
| Floor 1 | Records Basement 97, Cemetery 58 | **155** |
| Floor 2 | Sunset Shores 82, Furnace Works 74 | **156** |
| Floor 3 | Mall 83, Parlour 79 | **162** |
| Floor 4 | Cruise 73, Fairway's End 72 | **145** |
| Floor 5 | Departures 73, Head Office 80 | **153** |
| Shared | doors, pickups, chests, Crossroads | **42** |
| Waiting Room | plus Harold 5 | **79** |
| Endings | | **96** |
| Title and UI | | **116** |
| **Total** | | **1,104** |

**What the total covers**
- 36 base enemy characters, 16 recolours, 10 mini bosses and 10 floor bosses.
- About 100 props and decor pieces, 11 tile sets, and the UI.

**Budget**
- With one reroll for every piece, expect about **2,200** of the 5,000 generations.
- Keep 160 in reserve in case the 16 recolours need `create_character_state` at 10 each.
- Item icons, when they are released, need about 100 to 200.
- This leaves well over 1,500 unspent before 2026-12-05.

**The biggest uncertainties**
- The 11 tile sets are about 275 gens at an estimated 25 each.
- The 13 stage backdrops are 65, also estimated.
- The bosses' 88 px anims are counted at 2 each.

### 3.2 Recommended order

1. **Code hooks H1 to H4 first**: the anim driver, feet offset, `art_id` with recolour, and frame widths. Without them, enemy art shows as a still idle that never turns, with its feet 8 to 20 px off its box. H5 (tiles) comes before the first tile set lands.
2. **Style check, one test piece per floor** (about 228 gens before rerolls). Each floor gets one regular enemy, its boss and its floor tiles. The path picked on each floor is the one hardest to read:

   | Floor | Regular | Boss | Tiles | Gens |
   |---|---|---|---|---|
   | 1 | intern_reaper (5) | regional_reaper (14) | Records Basement (25) | 44 |
   | 2 | stoker (5) | old_smokey (14) | Furnace Works (25) | 44 |
   | 3 | mall_cop (6) | mall_santa (14) | Mall (25) | 45 |
   | 4 | club_golfer (5) | thaddeus_fairweather (14) | Fairway's End (25) | 44 |
   | 5 | hr_representative (5) | chairman_of_the_board (16) | Head Office (25) | 46 |
   | Harold | at 44 px, first, as the scale anchor | | | 5 |

   - Floor 1: a dark robe in the darkest blue light.
   - Floor 2: orange light that eats warm colours.
   - Floor 3: pale tile, and Santa's red against the warning red.
   - Floor 4: midnight blue light.
   - Floor 5: a busy office carpet and a large boss.

   Play each floor with these in, take screenshots, sample the lit pixels (LESSONS 2026-11-05), and lock the style before going on.
3. **Floor by floor, in play order:** Floor 1 (Records, then Cemetery), the shared doors, pickups and chests, then Floors 2 to 5. On each path do the regulars, then the mini boss, then props and decor.
4. **Waiting Room**: stations, boards, then the trophy wall.
5. **Title and UI.**
6. **Endings** last: their backdrops are the least certain cost and are seen least.

---

## 4. Style guide (extends `art/STYLE_GUIDE.md`)

Everything in `art/STYLE_GUIDE.md` still holds:
- the base prompt;
- no names of other games, studios or artists in prompts;
- flat, evenly lit colours with no baked glow, because the engine does the lighting;
- transparent backgrounds;
- 32x32 tiles;
- the generator's own colours, with no forced reduction to `art/palette.txt`;
- frame 0 left out of each strip;
- no mixing of template and custom anims on one character;
- the cane gripped in every frame;
- the attack strip starting with the cane forward.

What follows adds to it.

### 4.1 Fixed PixelLab settings

- **Characters:** PixelLab v3, **low top-down** view, **single colour black outline**, **medium** detail, flat shading, no ground shadow.
- **Humanoid enemies and NPCs:** **48 px** canvas.
- **Harold:** being redrawn at **44 px**, slightly smaller than the NPCs, so he reads as a frail old man among them. When he lands, `Player.SPRITE_FRAME_WIDTH` changes from 68 to his new frame. His feet still sit at `SPRITE_FEET_Y = 23` below his origin (H2). The guide's "68x68 frames, about 46 tall" line should then be updated.
- **Anims:** east only for anything that flips (section 2). Use v3 custom anims, not templates, for every combat character, so one scale holds.
- **Props and objects:** `create_map_object` in the low top-down view, so they sit in the same view as the characters. Size each object to its body size in section 2, never larger than its cell unless it is a boss overlay.
- **Tiles:** the Pro top-down tileset with the low view, because the standard tileset is high top-down only. Make 3 floor tones per path to match `floor_a`, `floor_b` and `floor_c`.

### 4.2 Frame widths

The guide's "regular 32, Senior Adjuster 48, Regional Reaper 64" are the frame widths the data files hold today. The art pass moves them to the canvases below (H4). Update that line of the guide when the first test piece lands.

### 4.3 Sizing by body

A canvas is about 1.6 to 2 times the body height, rounded to a multiple of 4.

| Body height (`body_size.y`) | Who | Canvas | Figure height in canvas |
|---|---|---|---|
| 14-15 | seasonal temps, mall elf, gopher | 32 | about 24 |
| 18-20 | mourners, diners, walkers, yes-men, tour group, auditor | 36 | about 30 |
| 22-32 | most regulars and the denial officer | 48 | about 38-42 |
| 28 (Harold) | Harold | 44 | about 38 |
| 38-40 | mini bosses (Senior Adjuster, Gus, Barbara, Klaus, Gloria, Reverend, Lorraine, Chip, Wanda, Doreen) | **64** | about 54 |
| 48-52 | floor bosses (Regional Reaper 48, Undertaker 48, Matron 48, Santa 50, Old Smokey 50, Mortimer 50, Commodore 52, Thaddeus 52, Augustine 52, Chairman 52) | **88** (largest at 2 gens; 96 costs 3) | about 72-76 |

A boss must be at least 1.6 times Harold's height on screen, and its feet go on its body box bottom like everyone else's. Scythes, gavels and clubs may reach outside the body box, but **the body itself** should fill about the box's width, so a hit that lands on the art lands on the box.

### 4.4 Per-floor palette notes

The engine multiplies every sprite by the room's `ambient` through CanvasModulate, then adds fill and torch light. As a first guide, the lit colour is about colour x (ambient + fill_light x 0.32), from `lighting.gd` FILL_ENERGY; Harold's own glow adds a little more (LESSONS 2026-11-05). The "lit multiplier" column below is that factor.

| Path | Floor tone | Wall | Ambient | Torch | Lit multiplier (R, G, B) | Art notes |
|---|---|---|---|---|---|---|
| Records Basement | #6a6677 grey-violet stone | #3a3547 | #52527a | #ff9e4c | 0.56, 0.55, 0.77 | The darkest warm channel. Red and orange lose almost half. Purple robes need a pale rim, face or lanyard. Avoid navy and black bodies. |
| Cemetery | #455c40 mossy grass | #384540 | #667a85 | #9ecce0 cold | 0.62, 0.76, 0.81 | Cold moonlight. Greens blend with the grass, so give plot holders warm earth or rust tones. |
| Sunset Shores | #808f85 / #805e6b carpet patches | #8f7894 | #756666 | #f2b280 | 0.74, 0.64, 0.60 | Soft and warm. Pastel uniforms read well. Blues go grey. |
| Furnace Works | #664533 rust | #613026 brick | #6b4c3d | #ff8c38 | 0.71, 0.48, 0.34 | Blue and teal are cut to a third, and orange bodies melt into the floor. Give stokers cool steel and dark soot with bright whites. |
| Golden Years Mall | #bdb8a8 pale tile | #5c667a | #707585 | #d9edff | 0.70, 0.74, 0.82 | A bright floor. Pale sprites and canes vanish (LESSONS), so give everything the full black outline and a mid-dark body. |
| Funeral Parlour | #731a2e wine carpet | #331c14 panels | #6b5766 | #ffb86b | 0.65, 0.52, 0.67 | A red floor: never let a body's main colour be warning red. Black mourning clothes need white gloves, collars and veils for shape. |
| Last Resort Cruise | #9e7042 teak | #141f5c navy | #5c6185 | #ffd180 | 0.58, 0.63, 0.82 | Warm deck under blue night. Sunburn reds turn dull pink. Keep whites (uniforms, hats) as the readable shapes. |
| Fairway's End at midnight | #42805c fairway | #0d2e1a hedge | #4c5785 | #809ee6 blue | 0.49, 0.56, 0.84 | The second-darkest. Red loses half, and the warning red is nearest to drowning here. Golf colours should be pinks, whites and yellows. The sand already read near white in play. |
| Departures | #3d5275 blue carpet | #99a8b8 pale | #6b7385 | #e0f0ff | 0.68, 0.73, 0.82 | Cool and even. Hi-vis greens and oranges read well. |
| Head Office | #a89975 beige carpet | #807361 | #7a7873 | #9499a3 | 0.73, 0.71, 0.67 | Neutral and bright. Suits in blue and grey need white shirts and red ties for shape. |
| Crossroads and landings | #6b665e | #403b40 | #6b6675 | default | 0.66, 0.63, 0.75 | Neutral stone between floors. |
| Waiting Room | palette defaults | | | | | Lit by warm lobby lamps. Its own tile set is free to be warmer. |

Draw floor tiles near these tones **unlit**, flat and evenly lit, because the light comes from the engine. Keep each path's 3 tones within about 10% of each other in value, so walking bodies stay the strongest contrast.

### 4.5 Prompts

Use the guide's base prompt, then a subject line per enemy built from its `display_name` and its mark in `EnemyMarks`, such as "nurse cap", "santa hat" or "hi-vis vest". The mark becomes part of the sprite, and the code mark is removed once art exists.

- **Floor variants:** give the base prompt only. The floor's colour is applied by the recolour.
- **Bosses:** add "large imposing figure" to the prompt. Add the held prop named by the boss's attacks: a shovel, hammer, gavel, anchor, club, stamp or megaphone.

---

## 5. Readability constraints from the game

### 5.1 Telegraphs and red warnings stay readable

- Every warning (`enemy._draw_warning`, GroundStrike, SummonMark, lanes, cones, LaneDrop, RunwayLane and the rest) is drawn in code in **#e4524f** on a layer at z 60, above sprites and above Lights Out. **Keep all of these as code.** The art pass must not bake any warning into a sprite or tile.
- **No sprite or tile should use #e4524f-like red** (a saturated red at mid value) as a large area. This matters most for:
  - Mall Santa: make his red deeper and darker (around #8c1c22), with white trim;
  - Matron's cap band;
  - sunbather sunburn;
  - the airport Mall Cop recolour (0.85, 0.3, 0.3): shift it to maroon or blue;
  - Parlour carpet tiles: keep them wine, darker than the warning.
- A windup must read from the pose as well as the red. The windup frames should show a clear wind-back of the arm or weapon, since `is_winding_up()` drives them (H1).
- Safe spots are green (#7fe0a0). Keep strong mint green off Fairway props near the floor.
- Harold's hurt flash is #e4524f through the shader. His sprite must not be mostly red, or the flash vanishes.

### 5.2 Hitbox-to-sprite alignment

- **The feet go at the body box bottom.**
  - Enemies: the lowest used row of every frame lands on `+body_size.y / 2` below the enemy origin.
  - Harold: it lands on `SPRITE_FEET_Y = 23`, the bottom of his 14x12 feet box at (0, 17).
  - NPCs: on the node origin. This is already done by `NpcSprite.used_rows`.
- **Place each strip by its own lowest row (H2).** PixelLab frames drift 1 to 5 px between idle and other anims. Never use one fixed offset (LESSONS 2026-11-05).
- **The body fills the box width.** The physics box is 0.8 of `body_size`. Contact damage, cane hits and the Wreath of Thorns all use those shapes, so the art body should cover the box and not much more. Weapons may stick out.
- **Bosses:** a 44x52 box needs up to 32 px from its middle for a shove (LESSONS). Draw the boss so its visible bulk matches that box, not the 88 px canvas.
- **Speech:** a head line sits over the body box (`Enemy.say_spot`). A tall hat that pokes far above the box may need the say offset raised.
- **Flipping:** draw facing east with the figure centred on the canvas's middle column, so a mirror does not shift the feet sideways.

### 5.3 Lighting and darkness

- **Placeholders are never darker than 0.55 brightness** (`SpriteVisual.MIN_BRIGHTNESS`). Hold the art to the same rule: the main body value, once lit, should stay above about 0.4 luminance on the Records Basement and Fairway's End. Check it by sampling a screenshot, not by the raw colour (LESSONS 2026-11-05).
- **Records Basement:** ambient #52527a and torches only on walls. Dark-robed reapers (intern_reaper is (0.23, 0.2, 0.35)) need a light face, bone hands, a lanyard or a pale scythe blade. The small enemy read glow (energy 0.3) helps only up close.
- **Fairway's End at midnight:** blue fill, red channel about 0.49. Golf colours shift blue, so test warm pinks and yellows in a screenshot. The fog decor and the sprinkler's green safe quarter must stay apart in value.
- **Lights Out** (Matron): everything outside a 70 px hole round Harold goes black. Enemies there are seen only by their warnings. That is by design, so do not add glow to enemy art to fight it.
- **Perfume haze** (Mall, Head Office) darkens to a 55 px window in the same way.
- **No baked glow, no baked shadow, no light source painted on a sprite** (STYLE_GUIDE). Torches, lanterns, candles, furnaces, stained glass, fluorescents and vents already carry engine lights. A prop with a flame shows only the flame shape, flat, and the light comes from code.
- When a floor's light changes, re-check the lit contrast of the debris and props, such as ball-washer debris against grass at 0.4 or more (LESSONS).

---

## Top risks

1. **Enemy art would show as frozen idles today.** H1 to H4 must come first.
2. **Lighting multiplies everything.** Dark bodies on the Records Basement and Fairway's End, and pale ones on the Mall tile, can vanish. Only a screenshot check proves them.
3. **Red against the warning red.** Santa, the airport Mall Cop and the Parlour carpet.
4. **Tiles are the largest code job and the least certain cost.** The per-tile pattern code must become textures, with the 3-tone patches kept.
5. **The 16 floor variants share art only if a real palette swap is added.** The current tint only multiplies.
6. **PixelLab drift** (scale between anim kinds, feet height, vanishing held props) and reroll cost could double the spend. The budget allows for it.
