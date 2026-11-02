# Next Rounds Plan

Work happens on the `next-build` branch while the `first-floor` copy stays untouched for play. Nothing on this branch has been run. The game, tests and full-loop check all wait until testing together resumes. Never name other games in project files.

## Order

| Round | What | Needs a decision first? |
|---|---|---|
| 1 | Secret rooms opened by a Thermos | No |
| 2 | More combat layouts, including breakable blocks and chests | No |
| 3 | Key remapping screen | No |
| 4 | More Waiting Room upgrades for earning Pension | Number of levels and prices |
| 5 | Real rewards for the Retirement Plan tiers | Reward list, and the two rule questions below |
| 6 | Special items with mana | Design talk first |
| 7 | Art for enemies and the room | Spends generations, so only with approval |
| 8 | Second floor | After the first floor feels right |

## Round 1: Secret rooms

- Each floor can have one, hanging off a combat room with no side room. It may sit on a route the player skips.
- A faint crack in the top wall is the only hint. A Thermos blast next to it opens a door.
- The room holds rewards and no enemies. It appears on the maps only once visited.

## Round 2: More combat layouts

- Add layouts that use blocks, pockets and chests in new ways, so runs feel different.
- Rules still apply: every door and enemy is reachable without a bomb.

## Round 3: Key remapping

- A screen in the Waiting Room to rebind every action, saved between sessions.

## Open questions for the player

1. Does each Retirement Plan tier pay once ever, or again after cashing out?
2. Does a tier's free item come only in the run it was reached, or in every run after?
3. Should shop prices come down now that income is halved?

## To test together when testing resumes

Run the tests and the full-loop check first, because this branch has never been run. Then play:

- Finding the crack, blasting it, and the room and maps afterwards.
- Coming back from a secret room, and leaving it for later.
- Each new layout, to check it plays well and nothing is awkward to reach.
- Rebinding keys, then quitting and reopening.
