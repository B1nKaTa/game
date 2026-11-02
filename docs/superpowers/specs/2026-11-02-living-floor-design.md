# Living Floor Design

The player found the floor far too easy and the rooms lifeless, and wants rooms that connect by position. This round rebuilds how a floor is laid out and fills it with life. All numbers are working values. Never name other games in any project file, comment, asset name or commit message.

## Ground rules for building

- Work only on the `next-build` branch in `C:\GameDev\game\.worktrees\next-build`. Never touch the `first-floor` folder.
- The player is busy in another game. Never open a game window or play sound. Headless only: `powershell -File tools/test.ps1` and `powershell -File tools/smoke.ps1`, plus headless probes in the scratchpad.
- Probes that run real scenes without `--smoke` write to the real save. Back up and restore `save.json`, `save.json.bak` and `keys.json` in `%APPDATA%\Godot\app_userdata\Grandpa` around them, and give every probe a timer that quits with an error.
- Read `CLAUDE.md` and `LESSONS.md` first. Scripts loaded by tests must not reference autoloads. No new dependencies. No PixelLab generations: new things are drawn in code as placeholders through the same art lookup as enemies.
- Write tests first. Keep every existing test's intent, updating ones the new design replaces. Imperative commit messages, one logical change each, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Don't push.

## Stage 1: Rooms connected by position

**Floor layout.** A floor is rooms on a grid. Two neighboring grid cells may be joined by a door. A door on a room's north wall leads to the room above, and you arrive at that room's south door. This replaces layers and exits.

**Exploring replaces sealed routes.** Rooms can all be explored and walked back through, so sealing goes away. Doors still lock during combat. `FloorProgress` keeps visited rooms and arrival cells, without layers or sealing.

**Generating a floor.**
- About 12 to 15 regular rooms: a main path of about 7 rooms from the start to the floor boss, with branches off it.
- The floor boss sits at the end of the main path with one door. The mini boss sits about halfway along it, so it can't be skipped.
- Item rooms, a healing room and combat rooms fill the rest, mostly on branches, so exploring pays.
- Detours attach at free neighboring cells: one shop, one locked treasure room, side rooms by chance, and one secret room when a free cell exists. Rewards, Slips and the shop must always be reachable without a bomb, except secret rooms and pockets.
- Same seed gives the same floor. Test hundreds of seeds: everything is reachable, no two rooms share a cell, the boss has one door.

**Room sizes.** Layouts can be small, medium or large, read from their rows rather than constants. Medium is today's 20 by 11. Small is about 14 by 9, centered with darkness around it. Large is about 30 by 17, and the camera follows Grandpa, stopping at the room's edges, with the HUD staying put. Screen shake still works, and aiming still follows the mouse correctly. Enemy clamps, the backdrop, lighting and overdraw must all use the room's real size.

**Doors.** Each room has one door cell per side, at the middle of that wall and computed from its size. A layout must keep all four reachable without a bomb. Only sides with a neighbor get a door. Grandpa arrives at the door on the side he came from, standing on it, and it only works once he steps away. Locked treasure doors, the shop and the secret crack use these same side cells. The crack sits in the wall on the side leading to the secret room. Update existing layouts as needed, and add at least 4 small and 4 large rooms across types.

**Maps.** The mini map and big map draw the grid as joined cells with door links, like a real floor plan, with the current room highlighted and room type icons. Only visited rooms show, as agreed. Rooms are drawn at their cell whatever their size.

**Records.** Update the first floor design spec's floor and map sections, and `docs/playtest-notes.md`.

## Stage 2: Rooms that feel alive

New layout symbols, each with a placeholder drawn in code:
- **Rocks:** block walking and shots, and break to bombs and boss attacks, not the cane. A rock can hide a coin.
- **Barrels:** block walking, and break to a cane hit, a thrown cane, a bomb or a boss. They drop a Slip, a Thermos, a coin or a small potion by chance. Most drop nothing or a coin.
- **Holes:** block walking, but shots and the thrown cane pass over. Dodging does not cross them, and ghosts ignore them. Enemies avoid them only by collision, as with walls. Layouts must stay reachable around them.
- **Skeletons:** a small breakable pile with a small chance of a coin.
- **Grass, bones, cobwebs, puddles, floor cracks, wall lanterns and torches:** no collision. Grass parts or is cut when hit, as a small effect. Torches and lanterns add real light through the existing lighting, so rooms get pools of warm light. Each room also gets a light scatter of these chosen by the room's seed, avoiding doors and solid cells, so a repeated layout still looks different.

Every breakable stays broken when you return, and layout validation still guarantees doors and enemies are reachable without a bomb. Update layouts so rooms have real character, and give floor tiles more variety than today's checkerboard.

**Bosses break stones.** The floor boss's sweep and the mini boss's attacks break rocks, barrels and crates they reach, so hiding behind cover doesn't last.

## Stage 3: A real fight

**Target.** A fresh save usually dies before the floor boss. A nearly maxed save wins most runs. Measure what you can with calculation or a headless probe, and say plainly what only a human can judge.

**Numbers, as a start.** Regional Reaper about 1200 health, Senior Adjuster about 500. Regular enemies about 50% more health and clearly faster. Shorter windups and gaps. Keep every attack telegraphed with the warning circle so it stays fair.

**More enemies.** Most combat rooms get noticeably more, with more on bigger rooms. Later rooms on the main path can add one or two extra.

**New enemy types.** Add at least these, as data plus a behavior script, with placeholder colors and dark comedy names:
- A fast, fragile pack that surrounds you, spawned in groups.
- A shooter that fires short aimed bursts and backs away.
- One that rushes in and explodes after a warning, which also hurts other enemies and breaks barrels and rocks.
- A slow, tough one with a frontal shield that blocks hits from the front, so you must get around it or throw over it.

Summons always pay nothing. Enemy shots and blasts must respect the room's walls and holes as their design says.

**Boss patterns.** All telegraphed. Regional Reaper: a dash across the room, a scythe sweep, a projectile ring, a summon, and a harder second phase mixing them faster. Senior Adjuster: a charge, a sweep, and summons that cut off your path. Patterns must not depend on art.

## Stage 4: Potions, bombs and deeper paths

**Unlocking merchants.** Two new Waiting Room merchants appear only once earned. There is only one floor today, so use floors cleared as a stand-in, saved in `ProgressData` as an optional field so old saves load: the potion merchant after 1 clear, the bomb merchant after 3. Keep these as easy-to-change values, since later floors will move them.

**Potion merchant.** Sells potion recipes or brews for Pension. A brew fills a potion slot for the next run, and only one can be carried. A new rebindable action, default H, drinks it. Potions include healing and one or two short buffs. Small potions found in runs fill the slot too, and are not wasted if the slot is full, as they stay on the floor. The HUD shows the slot at all times.

**Bomb merchant.** Upgrades Thermos damage over 3 levels for Pension, using the existing upgrade data with a new merchant id and a new stat field. It shows on the Thermos's blast.

**Reinforced stones.** A new rock type breaks only to a max level Thermos and looks clearly different, so players learn to come back for it. Some rooms have one covering a door to a vault, a rich detour room. Floors must still be fully winnable without it, and vaults never hold anything required.

**Records.** Update the design spec, `docs/playtest-notes.md`, `docs/superpowers/plans/2026-11-02-next-rounds.md` and `LESSONS.md`.
