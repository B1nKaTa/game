# Third floor design, with dentures, chest types and the Arcade Room

Approved in conversation on 2026-11-03. It builds on `2026-11-03-second-floor-design.md` and `2026-11-02-living-floor-design.md`. Every rule there still applies unless this spec says otherwise. Art stays placeholder until the one art pass.

## Ground rules

- Never name another game in any file, comment, asset name or commit message.
- Ask before adding dependencies. Keep `LESSONS.md` up to date, and leave the project runnable after every commit.
- Every attack shows its warning first, and line attacks also show a lane. Bosses start attacks only with their whole body on screen, using `Enemy.target_in_view()`.
- Walkers use `Enemy.chase_direction()`.
- Summoned enemies pay no Pension.
- Old saves must load. Every new save field is optional and has a fallback.
- Don't change prop collision boxes. They get set from the final art.

## 1. Dentures replace the thrown cane

**The throw (the throw key, right click by default).**
- **Throwing.** Grandpa throws his false teeth. They fly forward chattering and bite the first enemy for the damage the thrown cane does today. Then they drop to the floor and keep chattering.
- **Coming back.** They return after 3 s, or at once if Grandpa walks over them.
- **The cane stays.** Grandpa keeps his cane the whole time, so swinging, the combo and the charge all work while the teeth are away. Their time away is the throw's cooldown.
- **The world.** Holes, grass, barrels and walls treat the dentures as they treated the thrown cane.
- **Range.** It drops to 170 px at base. The thrown cane reached 200 px.

**Extra Strong Dentures (item).** It changes from "+25% cane damage" to "thrown dentures bite 50% harder and bite through up to 2 enemies".

**Fury Liniment (potion).** Its text becomes "Cane and dentures hit 50% harder for 15 seconds". The effect covers both.

**Denture Adhesive (new Waiting Room upgrade).** It is sold by the same merchant as Reinforced Cane.

| Level | Price | Bite damage | Range | Other |
|---|---|---|---|---|
| 1 | 50 | +15% | 210 px | |
| 2 | 120 | +30% | 250 px | |
| 3 | 240 | +45% | 290 px | The teeth return after 2 s instead of 3 |

**Later, not in this build.** While his teeth are out, his talk lines come out mumbled.

## 2. Chest types

Today's single Locked Chest becomes one of five chest types. Each has its own look, cost and loot.

| Chest | Opening | Loot | Rarity |
|---|---|---|---|
| Old Lunchbox | Free, by interacting | A little Pension, sometimes a heal or a Thermos | Common |
| Locked Chest | 1 Permission Slip | Treasure, as today: Pension and sometimes a recipe | Uncommon |
| Safe Deposit Box | A Thermos blast, no Slip | A big pile of Pension | Uncommon |
| Gilded Urn | 2 Permission Slips | A guaranteed item: pick 1 of 2, and the other vanishes | Rare |
| "Chest" (a mimic) | It looks like a Locked Chest and wakes when touched | Fight it. It pays well in Pension and drops a Slip | Rare, floor 2 and deeper |

- **Odds.** Each floor has its own chest odds, and the rare types get likelier deeper down.
- **The mimic.** It shows one subtle tell, a tiny tongue or a slow breathing motion. It always follows the attack and warning rules.
- **Room cells.** A layout's `C` cell rolls the chest type.

## 3. The Arcade Room

**Where it appears.**
- It is a rare special room, like the vault, and rolls on about 1 floor in 4, on any floor.
- Its door shows a dice icon. The room is safe, with neon light and a loud carpet.
- A **Dealer** NPC stands in it, using the talk system, with placeholder lines.

**The games.** Each game plays once per visit. A game opens a simple card-table overlay, and the room stays safe while it is open.

| Game | Play | Bet | Payout |
|---|---|---|---|
| Slot machine | Pull the lever and 3 reels spin. 3 pulls per visit | 10 a pull | A pair returns the bet. Three of a kind pays 5×. Three skulls give a free item. Three pills give a full heal |
| Blackjack | One hand against the dealer, who stands on 17. Hit or stand | 10, 25 or 50 | A win pays 2×, a blackjack pays 2.5×, and a push returns the bet |
| Draw poker | One hand: deal 5, hold any, draw once | 10, 25 or 50 | Paid from Jacks or better at 1× up to a royal flush at 50× |

- **Odds.** The odds are set so that on average about 90% comes back. Pure rules (shuffles, hands and payouts) get headless tests with a seeded random number generator.
- **Art.** The cards and reels are code-drawn for now.

## 4. Between floors 2 and 3

This works the same way as between floors 1 and 2:
- A floor-2 boss drops two items to pick from, and the stairwell opens.
- The landing has a "Floor 3" sign and heals 2 pills.
- A third Crossroads offers two paths:
  - **West:** the Eternal Rest Funeral Parlour, always open.
  - **East:** the Golden Years Mall, chained with the hint "Beat a third-floor boss first" until a third-floor boss has been beaten once.
- **The end of the run.** Until a fourth floor exists, beating a floor-3 boss ends the run with "FLOOR CLEARED".
- **Clears.** Clears are recorded by depth, and the Mall's unlock uses depth 3.
- No new Waiting Room unlocks are tied to floor 3 for now.

## 5. Difficulty

| | Floor 1 | Floor 2 | Floor 3 |
|---|---|---|---|
| Enemy health | base | ×1.4 | ×1.8 |
| Enemies per room (small / medium / large) | 4 / 6 / 11 | 5 / 7 / 12 | 6 / 8 / 13 |
| Pension (rounded up) | base | ×1.5 | ×2 |
| Heaviest boss attacks | 1 pill | 2 pills | 2 pills, plus one 3-pill attack per floor boss with an extra-clear warning |

The two 3-pill attacks are Mortimer's Casket slam and the Mall Santa's Sleigh run.
- **Mini bosses.** Floor-3 mini bosses must be at least as hard as the strengthened Barbara and Foreman Klaus.
- **Floor bosses.** Floor-3 floor bosses must be clearly harder than Matron Mercy and Old Smokey. Measure this with the simulated player.

## 6. Eternal Rest Funeral Parlour (open path)

**Look.** It is dim and hushed: dark wood panelling, burgundy carpet, stained-glass light, candle stands, rows of chapel pews, coffins on stands and flower wreaths.
- **Breakables.** Wreaths, candle stands and hymn-book carts.
- **Solids.** Pews are solid and stand in rows, which makes lanes.

**Hazard: organ pipes.**
- Pipes set in some walls play a chord on a steady beat, glowing before each one.
- Each chord sends out a ring that pushes Grandpa and enemies away from the pipe.
- The ring does no damage, and a dodge passes through it.

**Regular enemies.**
- **Weeping Mourner.** Mourners come in packs of 3 and drift slowly toward Grandpa. After a warned wail, they all lunge together.
- **The Florist.** She keeps her distance and lobs thorny wreaths at warned spots. Each leaves a ring of thorns for a few seconds.
- **The Pallbearers.** Two of them carry a coffin and charge it along a warned lane as a battering ram that breaks props. When one dies, the other drops the coffin and fights alone.
- **Returning.** Two Cemetery enemies, in tougher versions with the floor's colours.

**Mini boss: the Reverend, Officiant of Last Words.**
- **Eulogy.** Words fall onto warned spots in a line.
- **Collection plate.** He throws a boomerang along a warned curve.
- **Summon.** He calls 3 Mourners.

**Floor boss: Mortimer Grimsby, Funeral Director.**
- **Casket slam.** A coffin slams down on a warned spot. Costs 3 pills.
- **Procession.** A line of pallbearers marches across the room in warned lanes, with one gap.
- **Embalming spray.** A warned cone that slows Grandpa, like the sedative.
- **Organ crescendo.** Every pipe in the room plays in a pattern, with one safe spot each time.
- **Second phase.** He climbs into a coffin, which charges like the Pallbearers between his other attacks.

## 7. Golden Years Mall at 7 a.m. (unlocked path)

**Look.** An empty early-morning mall: shiny tile, closed shop shutters, potted palms, benches, a fountain, a food court and flickering fluorescent lights.
- **Breakables.** Shopping carts, sale-sign stands and gumball machines.
- **Solids.** Fountains and planters.

**Hazard: escalator conveyors.**
- Moving strips carry Grandpa and enemies one way, with arrows showing the direction. Walking against a strip is slow, and walking with it is fast.
- Some rooms reverse their strips every few seconds, after a chime and flashing arrows.
- The strips never do damage.

**Regular enemies.**
- **Mall Walkers.** A line of 3 power-walks a loop and hurts on contact. After a warned whistle, the line breaks off toward Grandpa.
- **Mall Cop.** He rides a scooter and charges along a warned lane. Then he stops and whistles, which calls the nearest enemy to Grandpa.
- **Perfume Sprayer.** She keeps her distance and sprays warned clouds that linger. Inside a cloud, vision shrinks, like a small Lights Out.
- **Returning.** Two Records Basement enemies, in tougher versions with the floor's colours.

**Mini boss: Gloria, Mall Fountain Diva.**
- **Coin toss.** A spray of wishing-well coins along warned lanes.
- **Splash.** Fountain jets on warned spots. The floor around each jet stays wet for a few seconds, reusing the wet floor.
- **Summon.** She calls a line of Mall Walkers.

**Floor boss: the Mall Santa.**
- **Sleigh run.** A charge along a warned lane. Costs 3 pills.
- **Present drop.** Gift boxes land on warned spots and burst into rings of shots.
- **"Ho ho hold still".** A warned ring closes in around Grandpa, and he must dodge out before it shuts.
- **Conveyor control.** He reverses or speeds up every strip in the room.
- **Second phase.** He summons fast elves, at most 3 at once, and the sleigh run chains straight into a present drop.

## 8. Size

Each path gets about 30 layouts in small, medium and large sizes, in the same proportions as the earlier floors. A floor has the usual rooms: a mini boss, a shop with its Shopkeeper and the plan rewards, a treasure room, a secret wall, a vault when one rolls, and the Arcade Room when one rolls.

## 9. Build order

Push after each step and check the full loop each time. Testing waits for the user's go.

1. **Dentures and chests.** The dentures throw, the item and potion changes, Denture Adhesive and the five chest types, across all floors. The user plays it.
2. **The connection.** The third Crossroads, clears at depth 3, the end-of-run point and the Arcade Room. Placeholder floor-3 content proves the connection.
3. **The Funeral Parlour,** complete. The user plays it.
4. **The Mall,** complete. The user plays it.
5. **Balance and review.** A balance pass with the simulated player, then one independent review of the whole branch before merging.

## Testing

- **Headless tests.** Pure rules get headless tests: the denture states, range and damage by upgrade level, chest rolls and opening rules, the card games and their payouts (seeded), floor-3 unlocks, hazard timing and each new behaviour's choices.
- **The full loop.** It throws the dentures and checks they come back. It opens every chest type and plays each Arcade game once when the room rolls. It walks through to floor 3 and clears both floor-3 paths.
- **Real window.** Every new attack is seen in a real window at least once before its step is called done.
