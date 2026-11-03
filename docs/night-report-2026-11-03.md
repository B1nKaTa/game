# Night report, 2026-11-03

All five living floor stages are built on `next-build` and pushed. Nobody has played them yet, and `next-build` is not merged into `first-floor`. That waits until we have played it together.

## How to play it

Open the project in `C:\GameDev\game\.worktrees\next-build` and press Play, or run:

```
& "D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path C:\GameDev\game\.worktrees\next-build
```

## What was checked

- Tests: 563, 0 failed, on the final code.
- Full loop: 6 of 6 runs passed on the final code. Each one clears both paths and checks that the closed path refuses before a clear.
- Save: `save.json` was unchanged by these runs.
- One independent review of the whole branch found no critical or important bugs. It read the code but did not run the game.
- Screenshots in real windows covered the Crossroads, the maps, Cemetery rooms and most boss attacks. Mortimer's second phase was checked by code only, and his fight screenshots predate his last softening.

## Fixed after the review

All five findings were minor.

1. An Auditor's blast could open a secret wall. Now only your own Thermos does.
2. Mortimer's second and third wreath volleys re-aimed with no warning. All three now fly down the warned lane, which makes him a little easier.
3. Leaving a room with a Thermos still burning lost it. It now goes back in your pocket.
4. An older key settings file could put two actions on H. Loading now swaps keys.
5. A shield block played the hit sound and hit stop. It now plays only the block sound.

## What only you can judge

- Whether fights are fair at real speed, and whether the warnings read in a crowd.
- Whether the signs at the Crossroads get noticed.
- Whether Mortimer feels equal to the Reaper. In simulation the Cemetery is the harder path.
- Whether the Senior Adjuster is a wall for slower players. A simulated slow player on a nearly maxed save won 1 of 30 runs at stage 3.

The simulated player never throws the cane or uses a Thermos, so these numbers are a rough guide only.

| Save | Records Basement wins | Unkempt Cemetery wins |
|---|---|---|
| Nearly maxed | 18 of 20 | 61 of 80 |
| Some upgrades | 6 of 20 | 5 of 40 |
| Fresh | 3 of 20 | 3 of 40 |

## Decisions I made that you may want to change

- West is the Records Basement, east is the Cemetery.
- Sealed routes were replaced by free exploring.
- Stand-in merchant unlocks: Madame Murk after 1 clear, Boom Bernard after 3. They will move to later floors once those exist.
- Door icons show the type of a room you haven't visited.
- A clear of either floor boss opens the second path.
- Beating either floor boss still ends the run, because there is no second floor yet. `_continue_after_floor` in `scripts/scenes/floor_scene.gd` is where it will connect.
- Income is about 125 to 136 Pension per full clear without blasting. All upgrades cost 2435, which is about 19 clean runs. I don't know yet if that pace feels right.

## Known small issues

- Long item names on the small vault's item row still touch.
- The Waiting Room HUD has no potion slot. The spec says the slot shows "at all times", and I read that as during runs only.
- A vault on an early save can show fewer than three items.

## Later, together

The 7 Retirement Plan tier rewards, special items with mana, art (generations need your approval) and the second floor.
