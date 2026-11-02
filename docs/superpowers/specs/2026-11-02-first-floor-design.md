# First Floor Design

Date: 2026-11-02
Status: Awaiting review

All character, item and currency names are working names and can change without affecting the design.
All numbers are starting values to tune through playtesting.

## Summary

A grandpa dies at the start of the game and refuses to accept it. He fights grim reapers and other agents of the afterlife with his cane, in a top-down action roguelike.

This spec covers the first playable version: one complete floor, plus the hub and upgrade loop around it. Later floors and all endings are out of scope, and each will get its own spec.

## Game Vision

This section gives context for design decisions. Only the First Version Scope section below gets built now.

- **Tone:** Mostly dark comedy. The afterlife is run like a tired government office, and Grandpa treats death as one more thing to complain about. A sincere emotional story emerges slowly.
- **Story hook:** Grandpa claims he is going back to finish a 40-year feud with his neighbor. His real reasons come out over time, including one last game with his dog and a promise to his granddaughter.
- **Full run:** One long journey across several floors. Routes branch, with different mini bosses, floor bosses and places to explore.
- **Endings:** Each completed journey ends with a short scene in the living world, where Grandpa finishes one piece of unfinished business. Death's office then drags him back on a technicality. Reasons follow a fixed order from petty to personal, ending with the granddaughter. The plan is 10 endings first, possibly growing to 20.
- **Progression:** Early runs are deliberately too hard. Currency earned across runs buys permanent upgrades from black market merchants who oppose the afterlife, and those upgrades make the full journey possible.
- **Platforms:** PC first. Android comes later and is not designed for in this version, beyond choosing an engine that can export to it.

## First Version Scope

Included:

- A short opening where Grandpa dies and arrives in the Waiting Room
- A small Waiting Room hub with two merchants and a door to the floor
- One floor with a branching route of 10 to 12 rooms
- Cane combat with a combo, a charged swing, a cane throw and a dodge
- 3 enemy types, 1 mini boss and 1 floor boss
- 6 run items and 5 permanent upgrades
- One currency that carries over between runs
- Saving and loading
- Placeholder art at first, followed by an early AI art test

Excluded:

- Endings and living-world scenes
- More than one floor
- More weapons
- More merchants beyond the two in the Waiting Room, and further Waiting Room characters
- Controller support and Android support
- Full key remapping, planned as a later feature
- Sound and music beyond simple placeholder effects

## Gameplay

### Loop

1. Grandpa starts in the Waiting Room and can spend Pension on permanent upgrades.
2. He goes through the door and fights through the floor.
3. When he dies or beats the floor boss, he returns to the Waiting Room and keeps all Pension earned.

Beating the floor boss shows a "floor cleared" message before the return. No ending plays in this version.

### Controls

Move with WASD and aim with the mouse. Tapping left click hits with the cane combo, and holding it after the hit charges a swing that fires on release once fully charged. Right click throws the cane, Space dodges, Q places a Thermos, E interacts, and M opens the floor map.

### Combat

- **Combo:** Three quick cane hits, with the third dealing the most damage.
- **Charged swing:** Hold left click after the combo hit. The player slows and a charge ring shows after 0.2 seconds of holding. Releasing when fully charged does a slower swing that deals high damage and knocks enemies back, and releasing earlier does nothing further.
- **Cane throw:** Right click throws the cane in the aim direction at 320 pixels per second for up to 200 pixels. It hits the first enemy it touches for 14 damage with a small push, then drops there. It also drops at a wall or at full range. While the cane is away, Grandpa cannot attack with combo or charged swings, and cannot throw again. Walking over the dropped cane picks it up. If it is left for 3 seconds it flies back to Grandpa without dealing damage, so he is never stuck without it. Changing rooms returns it at once.
- **Dodge:** A short hobble-dash that avoids damage while active, with a cooldown of about 1 second.
- **Hit rules:** Swings and the thrown cane test the enemy's whole body. A swing stays active for the 0.1 seconds its arc shows, hits each enemy at most once, and stays in the direction it was swung.
- **Health:** Shown as pills, starting at 4. Each enemy hit removes one pill unless an enemy's data says otherwise. Health is restored only by healing rooms and items during a run.

### Floor

The floor is a layered route. Each layer offers one or two rooms, and doors connect each room to one or two rooms in the next layer. Every route must reach the floor boss.

Each door shows an icon for the room type behind it, so route choice is a real decision. Entering a combat or boss room locks its doors until all enemies are defeated.

In regular rooms Grandpa arrives on the left and the exits are on the right. Every room except the first and the floor boss room has a return door at the arrival cell, leading to the room he came from. In a side room he spawns one cell to its right. Going back puts him at the door he originally left through. A door only works after he has stepped away from it, so arriving on one never sends him straight back.

Entering a room in a layer seals the other room in that layer, so the skipped route shows a sealed door for the rest of the run. Side rooms never seal. Rooms remember their state: cleared rooms stay empty and earn nothing more, and pickups left behind stay there. An item he has since gained elsewhere can't be taken again.

### Consumables, Blocks and Treasure

A run starts with no Permission Slips and one Overheated Thermos.

- **Permission Slips** open locked chests and the treasure room. The mini boss always drops one. Cleared combat and side rooms drop one 15% of the time.
- **Overheated Thermoses** are placed with Q and go off after 1.2 seconds, with a 56 pixel blast. The blast deals 30 damage to enemies, breaks blocks, and costs Grandpa one pill if he is caught. Cleared combat and side rooms drop one 20% of the time.
- **Breakable blocks** act as walls until blasted, then drop Pension 30% of the time, a Thermos 15% and a Slip 10%. Blocks can close off a loot pocket. Layouts fail validation if a door, enemy or required reward can't be reached without a bomb.
- **Locked chests** give the same reward as treasure, for one Slip.
- **The treasure room** appears once per floor, behind a locked door in the bottom middle of a room that is alone in its layer, so a route choice can never hide it. One Slip opens the door for good, and the room offers a choice of three items.

### Maps

A small map in the top right corner shows visited rooms, the links between them and the current room. Pressing M opens a large map with room type icons and a legend, and pauses the game until M is pressed again. Unvisited rooms never show on either map. The map reads left to right from the start to the floor boss, with side rooms beside their parent.

| Room type | Purpose |
|---|---|
| Combat | Fight enemies, then earn Pension |
| Item | Choose one of two items, with light or no combat |
| Healing | Restore 2 pills |
| Side room | Optional detour from a door in a regular room, holding Pension or an item, with some risk |
| Mini boss | Mandatory fight around the middle of the floor, on every route |
| Floor boss | Final room of the floor |

Rooms are hand-built. Each run picks from a pool of at least 15 layouts, excluding the two boss rooms. A normal run should take about 10 to 15 minutes.

### Enemies

| Enemy | Behavior |
|---|---|
| Intern Reaper | Walks toward Grandpa and swings a small scythe at close range |
| Filing Clerk | Keeps its distance and throws slow-moving paperwork |
| Debt Collector Ghost | Floats through obstacles and charges in straight lines |
| Senior Adjuster (mini boss) | Sweeping melee attacks, and calls in Interns during the fight |
| Regional Reaper (floor boss) | Two phases of scythe sweeps and ranged attacks, with faster patterns in the second phase |

### Run Items

Items last for the current run only. Grandpa can hold any number of them.

| Item | Effect |
|---|---|
| Extra Strong Dentures | More cane damage |
| Orthopedic Slippers | Faster movement |
| Prune Juice | Shorter dodge cooldown |
| Hearing Aid | Shows enemy attack warnings earlier |
| Lucky Bingo Card | More Pension from all sources |
| Spare Pill Organizer | 1 extra pill for this run, and restores it |

### Currency and Upgrades

Pension is the only currency. Enemies and rooms drop it, and picking it up adds it immediately. All of it is kept on death.

Two merchants in the Waiting Room sell permanent upgrades, with rising prices at each level. The black market merchant sells the first four below. Dr. Squint, Unlicensed Optometrist, stands in a different spot and sells the glasses. Walking close to either shows "E: Trade", and only one trade panel is open at a time.

| Upgrade | Effect per level |
|---|---|
| Black Market Pills | 1 more starting pill |
| Better Knees | Faster movement and shorter dodge cooldown |
| Reinforced Cane | More cane damage |
| Bribed Clerk | More Pension from all sources |
| Prescription Glasses (Dr. Squint, one level) | Regular enemies show a small health bar above their heads |

### Boss Health Bar

Bosses draw no bar above their heads. Entering a boss room shows a large bar centered along the bottom of the screen, with the boss's name in larger text just above it. It appears when the boss spawns, drops as the boss takes damage, and disappears when the boss dies or the run ends. Entering another room never leaves a stale bar. The item list moves up to sit just under the pills line at the top, so it never overlaps the bar.

### Difficulty Target

A new player should usually die before beating the floor boss. A few runs of upgrades should make a win realistic.

## Architecture

The game uses Godot 4.7.2, standard version, with GDScript. No add-ons are planned. It renders at 640×360 and scales up to fill the screen.

### Components

| Component | Responsibility |
|---|---|
| Player | Movement, attacks, dodge and health |
| Enemies | Shared behavior, with each type defined by its data and attack pattern |
| Floor builder | Selects rooms and connects them into a valid route |
| Rooms | Doors, spawns, rewards, and locking until a fight ends |
| Run state | Current health, items and route progress, cleared at the end of each run |
| Save data | Pension and purchased upgrades |
| Waiting Room | Hub scene, its merchants and the door to the floor |
| Game flow | Moves between opening, Waiting Room, floor, death and floor cleared |

### Content as Data

Enemies, items, upgrades and rooms each live in separate data files or scenes, not in core code. Adding an item or enemy of an existing kind should not require changing core systems. A later floor is mostly a new list of rooms, enemies and bosses.

### Run Flow

1. The Waiting Room loads saved Pension and upgrades.
2. The player spends Pension, and each purchase saves immediately.
3. The floor builder creates a route, and the run begins with upgrades applied.
4. Rewards update the run state, and earned Pension saves as it is collected.
5. On death or floor clear, the run state is cleared and the game returns to the Waiting Room.

### Save Data

Saves are stored in Godot's per-user data folder as a small versioned file. Each save is written to a temporary file and then swapped in, keeping the previous save as a backup. Only Pension, upgrade levels and whether the opening has been seen are saved. A run in progress is not saved, so quitting mid-run ends that run while keeping its Pension.

### Error Handling

- **Damaged save:** The game tries the backup. If both fail, it starts fresh and tells the player.
- **Broken room data:** The floor builder skips the room, logs the error and continues. If too few valid rooms remain to build a route, it shows an error message and returns to the Waiting Room.

## Art

The target is high-quality, moody pixel art: dark rooms lit by torches, sparks and glowing enemies, with cold shadows against warm light. Comedy comes from office details placed in grim settings, such as filing cabinets and take-a-number machines. Godot's 2D lighting provides much of the mood.

Grandpa is about 32 pixels wide and 48 tall, which the art test may change.

### Workflow

1. Build and playtest the floor with simple placeholder art.
2. Test AI art early on Grandpa's walk and cane swing, to confirm he can stay consistent across animation frames.
3. Write a short style guide covering palette, sprite sizes and lighting rules, then write reusable prompts from it.
4. Generate images with an AI tool whose terms allow commercial use.
5. Clean up each image by reducing it to the true pixel grid and palette, then fixing stray pixels and frame differences by hand. Scripts handle the repetitive parts.
6. Swap finished art in, with no code changes.

AI use is disclosed wherever a store requires it. If the art test shows AI can't produce usable animation, the art approach gets revisited before more assets are made.

## Testing

Small test scripts run through Godot's headless command-line mode, with no test add-on. They cover:

- Saving, loading, and recovering from damaged saves
- Damage and health
- Pension earning and spending
- Upgrade purchases and their effects
- Floor generation, checking that many generated floors can each be completed from start to boss

Game feel and difficulty are checked by playtesting.

## Done Criteria

The first version is done when all of these are true:

- The full loop from Waiting Room to floor and back plays without crashes.
- Pension and upgrades survive quitting and reopening the game.
- Automated tests pass, including the floor generation check.
- A new player usually dies before beating the floor boss, and a few rounds of upgrades make a win realistic.
- The cane combat feels good in playtesting, which is the most important criterion.
