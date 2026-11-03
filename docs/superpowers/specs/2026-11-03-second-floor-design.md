# Second floor design

Approved in conversation on 2026-11-03. It builds on `2026-11-02-living-floor-design.md`, and every rule there still applies unless this spec says otherwise. Art stays placeholder. Real art comes in one pass once the roster is settled.

## Summary

Beating either first-floor boss no longer ends the run:

1. Grandpa picks one of two items, takes a stairwell and heals on a safe landing.
2. He chooses between two second-floor paths at a second Crossroads.
3. **Sunset Shores Eternal Care** is open from the start. **The Furnace Works** opens after any second-floor boss has been beaten once.
4. Until a third floor exists, beating a second-floor boss ends the run with "FLOOR CLEARED", as a first-floor boss does today.

## Ground rules

- Never name another game in any file, comment, asset name or commit message.
- Ask before adding dependencies. Keep `LESSONS.md` up to date, and leave the project runnable after every commit.
- Every attack shows its warning circle first, and attacks that travel in a line also show a lane. Bosses start attacks only with their whole body in view.
- Summoned enemies pay no Pension.
- Old saves must load. Every new save field is optional and has a fallback.

## 1. Between the floors

**The floor boss's reward.**
- **Pension:** the boss pays its Pension as today.
- **Items:** two free items appear near where it fell. Taking one makes the other vanish.
- **Item pool:** both come from the run's normal item pool with the usual rules, so no recipe item is offered before it is crafted and nothing promised elsewhere is offered.
- **Running out:** if the pool has only one item left, one is shown, and if it has none, none.
- **Stairwell:** the room's exit to the next floor opens once the boss is down. It does not wait for an item to be taken.

**The landing.** The stairwell leads to a small, safe room with no enemies and a sign reading "Floor 2". On arrival Grandpa heals 2 pills, up to his maximum. Its only other exit leads to the second Crossroads.

**The second Crossroads.**
- **Layout:** the same room type as the first Crossroads, with two signs and two exits.
- **West:** Sunset Shores, always open.
- **East:** the Furnace Works, which hangs in chains with the hint "Beat a second-floor boss first" until a second-floor boss has been beaten once.
- **Map:** the floor name and maps work as on the first floor.

**What carries over.** Items, pills, keys, Thermoses, the potion, an active buff and the Retirement Plan state all carry over. Run-only state tied to the first floor's map does not, such as rooms visited and the mini boss being down.

**Where it hooks in.** `_continue_after_floor` in `scripts/scenes/floor_scene.gd` builds the landing and the second Crossroads after a first-floor boss. A second-floor boss's clear goes to a single point that ends the run, kept as obvious as `_continue_after_floor` so a third floor slots in later.

## 2. Progress and unlocks

- **Clears by depth:** clears are saved for each floor depth separately, as first-floor clears and second-floor clears. The existing `floors_cleared` count stays the first-floor count, so old saves keep their meaning.
- **Opening paths:** a floor's unlock rule names the depth whose clears it needs. The Cemetery needs 1 first-floor clear, as today. The Furnace Works needs 1 second-floor clear.
- **Madame Murk** now opens after 1 second-floor clear, and **Boom Bernard** after clears of both second-floor paths. This means saving which paths have been cleared, by id.
- **Already-open merchants:** a merchant already open in a save made before this change stays open. Record that when an old save first loads, so the new rules never close one.

## 3. Difficulty

These are starting values, to be tuned later with the simulated player.
- **Enemy health:** second-floor enemies have about 40% more health than comparable first-floor ones.
- **Enemies per room:** one more than the first floor, so 5, 7 and 12 by size.
- **Damage:** regular hits cost 1 pill. Each second-floor boss's heaviest attacks cost 2 pills. They are named below and must have clear warnings.
- **Target:** on the same save, the second floor's win rate should land somewhat below the first floor's.
- **Pension:** second-floor enemies pay about 1.5 times their first-floor counterparts, rounded up, and bosses follow the same ratio.

## 4. Sunset Shores Eternal Care (open path)

**Look.** A warm, faded care home: pastel walls, patterned carpet and linoleum, armchairs, beds, IV stands, potted plants, bingo tables. Lights are soft and warm, unlike the Basement and the Cemetery. Breakables include wheelchairs, food trays and flower vases, which follow the existing prop rules with the floor's own colors.

**Hazard: wet floors.** Some rooms have freshly mopped patches marked by a "Caution: Wet" sign. Grandpa slides a little on them, keeping some speed after letting go, and charging enemies slide too. They never do damage. The sign is decor and can be broken.

**Regular enemies.**
- **Orderly:** fires a sedative dart along a warned lane. A hit costs 1 pill and slows Grandpa for a short time, with the slow shown on him.
- **Med-Cart Nurse:** charges along a warned lane and breaks props in the way. Hitting a wall stuns her briefly.
- **Bingo Caller:** marks two or three spots near Grandpa that strike after a called-out delay. She keeps her distance.
- **Returning:** two first-floor enemies in tougher versions with the floor's coloring. The builder picks the two that suit the floor best.

**Mini boss: Barbara, Activities Coordinator.**
- **Bingo:** she lights a grid of floor tiles that strike one after another, with a safe path each time.
- **Ball cage:** she spins it and fires a spread of bingo balls along warned lanes.
- **Summon:** she wakes two residents.

**Floor boss: Matron Mercy, Head of Comfort Care.**
- **Sedative volley:** syringes along warned lanes that slow on hit.
- **Gurney charge:** a charge down a warned lane that breaks props. It costs 2 pills.
- **Lights Out:** the room goes dark except for a circle around Grandpa, and warning marks stay visible inside it. If play shows it is unfair, replace it with a simpler attack and say so.
- **Visiting Hours:** she calls in orderlies, at most 2 at a time.
- **Second phase:** below half health she moves faster, and the gurney charge chains into a sedative volley.

## 5. The Furnace Works (unlocked path)

**Look.** A dark, hot boiler hall: iron grating, brick, pipes, gauges, coal heaps, furnaces. Lights are orange and flickering. Breakables include coal sacks, crates and pipe valves. Coal heaps are solid, like rocks.

**Hazard: floor vents.** Some rooms have vents that flare on a steady rhythm and glow before each flare. A flare hurts Grandpa (1 pill) and enemies alike. A dodge passes through it, as with any damage.

**Regular enemies.**
- **Stoker:** throws coal at a warned mark, which leaves burning ground for a short time.
- **Steam Valve:** a fixed enemy that vents steam along warned lanes in turn.
- **Soot Ghost:** fades into smoke, where it can't be hit, and comes out next to Grandpa after a warning. It works like the Plot Holder's rule that every hiding enemy always comes back out, so rooms can always be finished.
- **Returning:** two first-floor enemies in tougher versions, as on Sunset Shores.

**Mini boss: Foreman Klaus, Shift Supervisor.**
- **Hammer slam:** a strike around him with an outward shockwave ring.
- **Steam lines:** jets that cross the room along warned lanes.
- **Summon:** he calls in two Stokers.

**Floor boss: Old Smokey, Chief Stoker.**
- **Fire breath:** a cone of flame shown as a warned cone. It costs 2 pills.
- **Coal rain:** coal falls on warned marks and leaves burning ground for a short time.
- **Vent grid:** the boss room's vents flare in patterns, with one safe path each time.
- **Bellows:** a push toward the fire, warned by a lane. It does no damage itself.
- **Second phase:** the vents flare faster and burning ground lasts longer.

## 6. Size

Each path gets about 30 layouts in small, medium and large sizes, in the same proportions as the Cemetery. A run's floor has the usual rooms: a mini boss, a shop, a treasure room, a secret wall and a vault when it rolls.

## 7. Build order

Push after each step, and check the full loop after each one.

1. **The connection:** the boss's two items, the stairwell, the landing, the second Crossroads, clears by depth, merchant unlocks, and the end-of-run point. Before Sunset Shores exists, a placeholder floor built from first-floor content proves the connection.
2. **Sunset Shores:** complete. The user plays it.
3. **The Furnace Works:** complete. The user plays it.
4. **Balance and review:** a balance pass with the simulated player, then one independent review of the whole branch before merging.

## Testing

- Pure rules get headless tests: the two-item pick, clears by depth, unlocks, keeping already-open merchants, the heal on arrival, the hazards' timing, and each new behavior's choices.
- The full loop walks start, first floor, items, landing and second Crossroads, and checks that the Furnace Works is refused before its unlock. It then clears each second-floor path.
- Every new attack is seen in a real window at least once before a step is called done.
