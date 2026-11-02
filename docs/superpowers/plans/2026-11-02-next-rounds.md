# Next Rounds Plan

Work happens on the `next-build` branch while the `first-floor` copy stays untouched for play. Nothing on this branch has been run. The game, tests and full-loop check all wait until testing together resumes. Never name other games in project files.

## Order

| Round | What | Needs a decision first? |
|---|---|---|
| 1 | Secret rooms opened by a Thermos | No |
| 2 | More combat layouts, including breakable blocks and chests | No |
| 3 | Key remapping screen | No |
| 4 | Two more Bribed Clerk levels at 300 and 500 | Decided, built |
| 5 | Recipes and Agnes the crafter | Built |
| 5b | Real rewards for the Retirement Plan tiers | Reward list only |
| 6 | Special items with mana | Design talk first |
| 7 | Art for enemies and the room | Spends generations, so only with approval |
| 7b | Living floor stages 1 to 5, see the living floor design | Stages 1 to 5 built (stage 4: potions, merchants by floors cleared, Thermos fuel, reinforced stones, vaults; stage 5: the Crossroads and the Unkempt Cemetery) |
| 8 | Second floor, reached from both first floors | After the first floors feel right. It slots in at `_continue_after_floor` in the floor scene |

## Round 1: Secret rooms

- Each floor can have one, hanging off a combat room with no side room. It may sit on a route the player skips.
- A faint crack in the top wall is the only hint. A Thermos blast next to it opens a door.
- The room holds rewards and no enemies. It appears on the maps only once visited.

## Round 2: More combat layouts

- Add layouts that use blocks, pockets and chests in new ways, so runs feel different.
- Rules still apply: every door and enemy is reachable without a bomb.

## Round 3: Key remapping

- A screen in the Waiting Room to rebind every action, saved between sessions.

## Decided by the player

1. Each Retirement Plan tier pays once ever.
2. A tier's free item comes only in the run it was reached.
3. Shop prices stay as they are for now.

## To test together when testing resumes

Run the tests and the full-loop check first, because this branch has never been run. Then play:

- Finding the crack, blasting it, and the room and maps afterwards.
- Coming back from a secret room, and leaving it for later.
- Each new layout, to check it plays well and nothing is awkward to reach.
- Rebinding keys, then quitting and reopening.
- Finding a recipe, crafting it with Agnes, starting the next run with the item, and seeing it appear in later runs.
- The crosshair at the mouse on the floor, the normal pointer back in the Waiting Room and panels, and the fading copies of Grandpa behind a dodge.

## Status

- Rounds 1 to 5 are written and pushed on `next-build`, and none of it has been run. Room layouts passed a separate check for size, door cells and reachability, run without starting the game.
- Round 5b waits on the reward list, and round 6 on a design talk.
- Before merging into `first-floor`: run the tests and the full-loop check, then play the list above.

## Living floor stage 4 status

Built and checked by tests, the full-loop check and screenshots, not yet played:

- Potion slot with H to drink, small potions from barrels fill it, brews from Madame Murk (after 1 floor clear) fill it for the next run.
- Boom Bernard (after 3 floor clears) sells Questionable Fuel, 3 levels, Thermos damage to enemies only.
- Reinforced stones and vaults. The number of vaults and the Thermos level the stones want are `vault_count` and `vault_stone_level` in `FloorDef`, so a second first floor sets its own. The unlock clears are in the merchant list in the Waiting Room scene.
- `ProgressData` has optional `floors_cleared` and `brewed_potion`, and a test proves an older save loads.

To play and judge together: brew prices against income, whether a new merchant is noticed, how the stone and the resist message read, whether a vault feels worth 380 Pension of fuel, the buff lengths, and how the potion slot sits in the HUD beside the item list.

## Living floor stage 5 status

Built and checked by tests, the full-loop check and screenshots, not yet played:

- The Crossroads opens every run. A closed path hangs in chains and refuses the door. Paths are listed in `PATH_FLOORS` in the floor scene, and each `FloorDef` holds `clears_to_open`, `danger` and `closed_hint`. No new save field: the rule reads `floors_cleared`.
- The Unkempt Cemetery is its own `FloorDef` and `data/rooms/cemetery/` folder of 33 layouts, with a mossy palette, gravestones, dead trees, stumps, moss and saplings.
- New enemy: Delinquent Plot Holder. New bosses: Gus, Head Groundskeeper, and Mortimer, Tired Undertaker. Ground attacks go through `GroundStrike` and break props by `Enemy.smash`.
- Both maps name the floor, and the Crossroads shows as a small linked room.
- The next floor slots in at `_continue_after_floor` in the floor scene.

To play and judge together: whether the signs get noticed, whether two skulls read as a warning, how a Plot Holder's mound and warning read in a crowd, whether rows, furrows and open graves feel fair at speed, whether both new bosses feel equal to the first floor's, whether the rows of graves in layouts get in the way, and every placeholder drawing.
