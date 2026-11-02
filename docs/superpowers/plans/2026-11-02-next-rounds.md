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
| 7b | Living floor stages 1 to 5, see the living floor design | Decided, building |
| 8 | Second floor, reached from both first floors | After the first floors feel right |

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
