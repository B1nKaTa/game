# Playtest-10: the fix round

The first two players of playtest-9 (build `0c234a7`) sent 21 notes, and the user added one. Every note
is in `docs/playtest-9-feedback.md`, numbered; this spec says what playtest-10 does about each. The user
asked on 2026-11-12: "fix everything reported till now, what we decided".

Three parts, built in this order:

1. **Fixes:** bugs and small decided changes.
2. **Map and HUD readability:** the floor-plan map, the minimap, the top HUD, item names.
3. **Furniture at Harold's scale on every floor:** its own spec and plan, after parts 1 and 2 (see the
   end of this file).

Not in this round: the late-game balance (feedback 21). It waits for Player 1's runs on the right-hand
paths. Floor 1's difficulty does not change: no enemy, damage or health tuning, except the rule choice
in item 20 below.

## Part 1: fixes

| Note | What playtest-10 does |
|---|---|
| 13 Door enters from far away | Reproduce it in a test first (a large floor-1 room, Harold where the screenshot shows him, holding Left), find the cause and fix it. A door enters only when Harold's feet reach its opening. |
| 1 Enemy stuck behind a prop | A melee enemy starts its attack only when nothing solid stands between it and Harold (`WalkGrid.line_is_clear`); otherwise it keeps walking its route. The shield enemy routes like the others. |
| 9 Save and quit respawns props | A room's checkpoint keeps the cells of its broken props, and a resumed room leaves them broken (no prop, no drop, its walk cell open). |
| 10 New pet appears next room | A pet's body appears beside Harold the moment its item is taken, in that room. Moths too. |
| 18 Charge carries into the next room | Entering a room cancels a held charge, as the map and the case file do. |
| 4 Shop potion cannot be bought | **Swap.** With a potion carried, a potion on the floor or in the shop shows "[E] Swap" at Harold's feet. Pressing it takes the new one and lays the old one where the new one was. In the shop he pays for the new one; the old one is not refunded and is free to take back. With a full slot a swap always needs the press. With an empty slot nothing changes. |
| 11 F does nothing (the user) | **Reel rework.** F plays the held reel at once, anywhere in the room Harold stands in, also mid-fight: sepia flicker, the era on the spot. It lasts for that room and ends as he leaves it. In a room with no fight left, F keeps the reel and says "Save it for a fight". The Old Projector ("A flashback lasts one more room") carries it into the next room. Every refusal says why, every time: "No memory to play", "Already remembering". The door step, the readied glow and "Memory ready" go. Tips and the HUD hint that mention a door are reworded. |
| 8 A run starts in a fight | Each floor's first room is a quiet room with no enemies and at least two doors onward. The Crossroads still joins it. |
| 14 The big item room is empty | Item rooms use the small and medium layouts only. The ten `item_large_01` layouts stay on disk, out of the item pool. |
| 20 No-cane rule with 15 enemies | "Leave Canes at Reception" applies only to rooms with at most 6 enemies. The other rules are unchanged. |
| P2-2 Harold turns strangely | Harold faces the way he walks. He turns to the aim while he swings, charges or throws, and for 0.6 s after the mouse or the right stick moves. With Mouse aim off nothing changes. |
| 12 No lightning bolt | The Lightning Rod Cane's bolt is drawn: a jagged pale-blue stroke from above the screen to the enemy, then the flash. Confirm in a test that the bolt's damage lands on a charged hit. |
| 15 Pet Rock text | "Counts as a pet. Pet items make it bigger, and once big enough it blocks shots." |
| 16 Case file overlap | Every stats label fits its column, measured in the case file's font; "Shop discount" becomes "Discount". The case file's "Combos" row (combos are retired, so it always reads "-") becomes "Sets" and lists the formed sets. |
| 17 Ending dialogue cut off | Check the ending's dialogue box sits inside the 640 px screen; fix if not. |
| 19 Cheats for testers | A tester panel in playtest builds only (a `playtest` export feature tag): god mode, any item or potion, +99 slips and thermoses. Opened by a key in a run; never in a release export. |
| P2-4 First boss spawns fast | No change (floor 1 stays as hard as it is). |
| 21 Too easy late | Not in this round. |

## Part 2: map and HUD readability

Notes 2, 3, 6, 7, P2-1 and P2-3, plus the map rework the user chose on 2026-11-11 (direction A, "the
floor plan"; mockup `D:\grandpa-art\map\directions.html`).

### The big map (M)
- A floor plan on cream paper in the case file's palette (PAPER `f1e8d0`, EDGE `b9a886`, INK `2b2218`,
  STAMP `9c2f2a`, MANILA `cfae68`), with a manila "FLOOR PLAN" tab carrying the floor's name, a faint
  graph grid, ink room outlines with double-line corridors and door gaps.
- Each visited room carries its door's sign (`DoorSign` pixel pictograms) in ink; plain fight rooms stay
  blank. A red "YOU ARE HERE" stamp marks the current room.
- **Unexplored exits:** from every visited room, a door to a room not yet visited is a dashed corridor
  stub that ends in that door's sign, or "?" for a plain fight room. Secret and vault doors show only
  once found.
- A key lists only the room types present on the floor.
- Kept, restyled: Floor Plan item rooms as pencil outlines; Night Vision secrets with "?"; the Fortune
  Teller's boss name in ink. The paused map lists the run's formed sets instead of the retired combos.
- It still pauses and closes with M.

### The room starts below the HUD
- Today a room taller than the screen is clamped by the camera with its top wall at screen y 0..32,
  always under the HUD's top rows (which end at `Hud.BAND_BOTTOM` 36): the top wall, its door's sign
  and any enemy near it are hidden. A short room is centred on the whole screen.
- From now the camera treats the area below the HUD (screen y 36..360) as the view: a tall room clamps
  with its top wall starting at screen y 36, and a short room is centred in that area. Nothing of a
  room is ever under the top strip. This one change answers notes 6, P2-1 and P2-3: the top door's
  sign is no longer under the active item panel, and the lobby's portraits sit clear of the HUD.

### The minimap
- A paper scrap in the same style, with the same exit stubs.
- It reaches below the HUD's rows (it is 75 px tall), so it fades to about a third whenever Harold, a
  pickup, an enemy or a warning is under it (today `MapFade` fades it for warnings only).
- The opacity slider works again: today `Hud.set_map_alpha` overwrites it every frame. The slider sets
  the solid level and the fade multiplies it. "Hide minimap in combat" stays.

### Item names
- A pickup's name, and a shop ware's price, show only while Harold is within 2 tiles of it. Of several
  in reach, only the nearest shows its name. Coin, slip, thermos and heal pop-ups are not names and are
  unchanged.

### The lobby's portraits
- The ten boss portraits hang in one straight row. The staggered name plates under them go; a boss's
  name is read by looking at the wall, as today's look-at text already lists each memento. The endings
  plaque stays.

### Text in the game's font
- Every label drawn on the map, the minimap, the HUD and the case file is measured against its box in the
  game's font by a test.

## Part 3: furniture (separate spec)

The user, 2026-11-12: furniture at Harold's real scale (a bed he could lie on, a chair he could sit in)
and arranged like a real room, on every floor. Budget about 400 PixelLab generations, up to 600-800 if
needed. It needs props that span two cells and grouped placement, so it gets its own spec and plan once
parts 1 and 2 are merged: one test room first, shown to the user, then every floor.

## Testing

- Each change has unit tests through static functions or plain objects, as the code base does.
- The full suite and the full loop pass before the build.
- Screenshots of the new map, the minimap and the HUD on two or three floors, taken from a renamed copy,
  are shown to the user before the build is zipped.
- Nothing runs on the worktree, nothing writes to the real user folder, and nothing launches while the
  user plays.
