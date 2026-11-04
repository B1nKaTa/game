# Floors four and five design

Approved in conversation on 2026-11-04. It builds on `2026-11-03-third-floor-design.md` and
`2026-11-04-waiting-room-overhaul-design.md`. Every rule in those specs still applies unless this one
says otherwise, and so does every rule in `.claude/skills/add-floor/`. Art stays placeholder until
the one art pass.

## Ground rules

- **Other games:** never name one in any file, comment, asset name or commit message.
- **Housekeeping:** ask before adding dependencies, keep `LESSONS.md` up to date, and leave the
  project runnable after every commit.
- **Warnings:** every attack warns first, and line attacks also show a lane.
- **Bosses:** start attacks only with their whole body on screen (`Enemy.target_in_view()`).
  Walkers route with `Enemy.chase_direction()` or `Enemy.walk_direction_to()`.
- **Summons:** summoned enemies pay no Pension.
- **Saves:** old saves load, and every new save field is optional with a fallback.
- **Collision boxes:** don't change prop collision boxes.
- **Branch:** build on `deep-floors`, never in the `check` play copy.

## 1. The connection

- **Floor 3 to 4:** beating a floor-3 boss drops two items and opens a stairwell. The "Floor 4"
  landing heals 2 pills, and a fourth Crossroads offers:
  - **West:** The Last Resort Cruise, always open.
  - **East:** Fairway's End Golf Club, chained with "Beat a fourth-floor boss first" until a
    floor-4 boss has been beaten once.
- **Floor 4 to 5:** the same, with a "Floor 5" landing and a fifth Crossroads:
  - **West:** Departures, Terminal Zero, always open.
  - **East:** Head Office, Eternity Incorporated, chained with "Beat a fifth-floor boss first".
- **End of a run:** beating a floor-5 boss ends it with "FLOOR CLEARED". `LAST_DEPTH` is 5.
- **Clears:** recorded by depth, as before. `FIRST_PATH_BY_DEPTH` and `PATHS_AT_DEPTH` gain depths
  4 and 5.
- **Path ids:** `last_resort_cruise`, `fairways_end`, `terminal_zero`, `head_office`.
- **Danger skulls on the signs:** 5 and 6 for floor 4, 7 and 8 for floor 5. If the sign has no room
  for that many skulls, show a number beside one skull.

## 2. Difficulty

| | Floor 3 | Floor 4 | Floor 5 |
|---|---|---|---|
| `health_mult` | 1.8 | 2.2 | 2.6 |
| `pension_mult` | 2.0 | 2.5 | 3.0 |
| `enemies_by_size` small/medium/large | 6/8/13 | 7/9/14 | 8/10/15 |
| `chest_weights` lunchbox/locked/safe/urn/mimic | 32/24/18/13/13 | 26/22/20/16/16 | 20/20/22/19/19 |
| `treasure_pension` | 16 | 20 | 24 |
| Mini boss final health | 640 | about 760 | about 880 |
| Floor boss final health | 1700 / 1650 | about 1950 | about 2250 |

- **Heaviest attacks:** each floor boss has one 3-pill attack (`Enemy.HEAVIEST_DAMAGE`), shown for its
  whole 1.2 s windup with the second outline. On floor 5, phase two chains straight into it once.
- **Mini bosses** must be at least as hard as the last depth's, and **floor bosses** clearly harder.
  Check both with tests that compare numbers, then with the balance bot.
- **Returning enemies:** floor 4 brings back two floor-2 enemies per path, and floor 5 two floor-3
  enemies per path. They are new `.tres` files in the path's colours with the old numbers.

## 3. The Last Resort Cruise, Lido Deck at Night (floor 4, west)

**Look.**
- A cruise ship's deck at night: teak planks, white rails, string lights, a pool, deck chairs,
  lifebuoys and a buffet.
- Breakables: deck chairs and buffet trays. Solids: the pool and the lifeboat davits.
- **Symbols:** this path may use `b`, `0`, `1` and `2`.

**Hazard: the ship rolls.**
- Every 9 s or so a horn sounds and a big arrow shows the side.
- Then for 2 s everyone slides that way: Grandpa, walkers and loose pickups.
- The roll does no damage. A dodge holds Grandpa in place while it lasts.
- A running charge holds its lane (`hold_lane`).
- Bosses never slide.
- The roll is room-wide and lays no tile, so give it no symbol. A layout opts in with a flag, as
  `strips_reverse` does. About two thirds of the rooms roll.

**Regular enemies.**
- **Early Bird Diners** (pack, like the Mourners):
  - Three shuffle together with trays.
  - After a warned dinner bell, all three rush.
- **Shuffleboard Shark** (ranged):
  - Slides pucks along warned lanes.
  - A puck bounces once off a wall.
- **Sunburnt Sunbather** (ambusher):
  - Lies looking like a deck chair.
  - When Grandpa comes close, he wakes with a warned snap of the chair and then chases.
- **Returning:** the Night Shift Orderly and the Stoker.

**Mini boss: Lorraine, Cruise Director.**
- Conga line: rows of dancers cross in warned lanes, with one gap.
- Karaoke shockwave: a warned cone.
- Quoit toss: rings land on warned spots and slow Grandpa inside them for a few seconds.
- Summon: Diners, at most 5 enemies in the room.

**Floor boss: Commodore Wellington.**
- Anchor drop: a warned spot. The 3-pill attack.
- Foghorn blast: a wide warned lane.
- "Hard to port": a strong roll of the ship, warned as the hazard is.
- Lifebuoys: rings roll across the room in warned lanes.
- Phase two: wet patches spread on the deck (reuse the wet floor), and the anchor drops twice in a
  row, each drop warned.

## 4. Fairway's End Golf Club at Dusk (floor 4, east)

**Look.**
- A golf course at dusk: striped fairway grass, flags, hedges, a clubhouse terrace and golf carts.
- Breakables: flag pins and ball washers. Solids: hedges and parked carts.
- **Symbols:** this path may use `s`, `3`, `4` and `5`, with `s` for sand.

**Hazard: sand bunkers.**
- Sand cells make anyone on them slower.
- Grandpa can't dodge while standing in sand.
- The sand has its own grainy dotted look, a shape no floor pattern uses.
- It is kept 2 cells off doors.

**Regular enemies.**
- **Caddie** (charger): drives a golf cart along a warned lane, breaking props.
- **Club Golfer** (ranged): shouts "FORE!" and then drives balls along warned lanes.
- **Gopher** (ambusher): pops up from a hole under a warned ring near Grandpa, bites, and burrows
  again.
- **Returning:** the Bingo Caller and the Soot Ghost.

**Mini boss: Chip, Club Pro.**
- Chip shot: balls lob onto warned spots.
- Putt: a ball rolls along a warned curve.
- Summon: Gophers, at most 5 enemies in the room.

**Floor boss: Club President Thaddeus Fairweather.**
- Hole in one: a giant ball drops on a warned spot. The 3-pill attack.
- Cart charge: along a warned lane, holding its lane.
- Sprinkler sweep: a warned arc that rotates around him.
- Bunker spread: warned patches of floor turn to sand for 8 s.
- Phase two: he summons Caddies, at most 3 at once.

## 5. Departures, Terminal Zero (floor 5, west)

**Look.**
- An airport departure hall: grey carpet, rows of seats, departure boards, luggage trolleys and
  potted plants.
- Breakables: luggage trolleys and suitcase stacks. Solids: the rows of seats.
- **Symbols:** this path may use `=`, `6`, `7` and `8`, with `=` for barrier lines.

**Hazard: queue barriers.**
- Rope barriers rise along marked floor lines on a timer, with a chime and a flash before they rise.
- While up, they block Grandpa and his dentures only. Staff duck under the rope, so enemies and
  their shots pass, and the walk grid never changes.
- A barrier rising under Grandpa pushes him to the nearest free side and does no damage.
- Barrier lines are kept 2 cells off doors, so a raised barrier never cuts off a door.

**Regular enemies.**
- **Tour Group** (pack):
  - A guide with a flag and two followers.
  - The followers copy the guide's warned rush.
  - If the guide is killed, the followers scatter and wander slowly.
- **Baggage Handler** (charger): pushes a luggage cart along a warned lane, breaking props.
- **Lost Luggage** (ambusher): a suitcase on the floor that springs open with a warned bite when
  Grandpa comes close.
- **Returning:** the Weeping Mourner and the Mall Cop.

**Mini boss: Sergeant Wanda, Airport Security.**
- X-ray sweep: a warned beam crosses the room, with one marked safe spot (`SafeSpotMark`).
- Tray toss: grey trays land on warned spots.
- Summon: Lost Luggage, at most 5 enemies in the room.

**Floor boss: Augustine, Head of Departures.**
- Boarding stamp: a giant stamp on a warned spot. The 3-pill attack.
- Runway lights: warned lanes light up one after another.
- Gate change: every barrier in the room rises or drops at once, warned like the hazard.
- Phase two: he calls Tour Groups, at most 5 enemies in the room, the barriers cycle twice as fast,
  and one runway-lights pattern chains into the stamp.

## 6. Head Office, Eternity Incorporated (floor 5, east)

**Look.**
- The top of the bureaucracy: beige carpet tiles, cubicle walls, water coolers, potted ficus and
  glass meeting rooms.
- It closes the loop with the Records Basement.
- Breakables: water coolers and in-trays. Solids: cubicle walls.
- **Symbols:** this path may use `x`, `9`, `N` and `y`, with `x` for red tape.

**Hazard: red tape.**
- Tape strung across lane cells holds Grandpa in place for 0.6 s when he walks into it.
- A dodge cuts it, and the cut tape is gone for 6 s.
- Enemies ignore it. It does no damage, has a striped look no floor pattern uses, and is kept
  2 cells off doors.

**Regular enemies.**
- **Yes-Men** (pack): three who copy one another. When one makes its warned lunge, the other two
  follow half a beat later.
- **Paper Shredder** (charger): charges along a warned lane and leaves a short trail of paper that
  slows.
- **HR Representative** (ranged): throws memos at warned spots, each leaving a "write-up" mark that
  stings if stood in for a moment.
- **Returning:** the Florist and the Perfume Sprayer.

**Mini boss: Doreen, Executive Assistant.**
- Memo storm: paper falls in warned lanes.
- Hold music: notes spiral out from her as slow shots along a warned spiral.
- Summon: Yes-Men, at most 5 enemies in the room.

**Floor boss: The Chairman of the Board.**
- Gavel: a warned spot. The 3-pill attack.
- Quarterly projections: warned columns rise and fall in turn, like a bar chart.
- Hostile takeover: a warned tether pulls Grandpa a short way toward him, then he charges. A dodge
  breaks the tether.
- Phase two: red tape spreads across warned lanes of the room for 10 s, and one projection chains
  into the gavel.
- The game's last boss. Beating him the first time shows the ending card (section 7).

## 7. Waiting Room hooks

**Four new departments**, one opened by each path's first clear.
- Every square beside the Lobby and Hallway is taken, so add one new corridor department reached
  from an existing one. It is open from the start and holds nothing. The four new departments hang
  off it, so every department is still reached through corridors.
- **Purser's Office** (cruise): the Purser NPC hands out a Bon Voyage Bag. While the department is
  open, every run starts with one random consumable (a potion or a Thermos). The arrival line names
  it.
- **Pro Shop** (golf): a merchant selling the **Golf Glove** upgrade, which charges the cane swing
  faster.

  | Level | Price | Charge time |
  |---|---|---|
  | 1 | 160 | −10% |
  | 2 | 320 | −20% |
  | 3 | 560 | −30% |

- **Duty Free** (airport): a merchant selling the **Frequent Flyer Miles** upgrade, which makes run
  shops cheaper.

  | Level | Price | Shop prices |
  |---|---|---|
  | 1 | 200 | −5% |
  | 2 | 400 | −10% |
  | 3 | 700 | −15% |

- **Executive Suite** (head office): a Severance Desk selling the **Golden Handshake** upgrade,
  which raises boss Pension.

  | Level | Price | Boss Pension |
  |---|---|---|
  | 1 | 250 | +10% |
  | 2 | 500 | +20% |
  | 3 | 900 | +30% |

  It also has a plaque, "Employee of Eternity", that counts Head Office clears.

**Ending card.**
- The first time the Chairman is beaten, a short card shows before the Waiting Room: "You reached the
  top. The paperwork says you may finally rest. Form 27B: Rest, Denied. Please take a number."
- After that, runs go on as normal.

**Mementos**, one per floor boss, with these perks:

| Floor boss | Memento | Perk |
|---|---|---|
| Commodore Wellington | Ship's anchor | Slides and pushes move Grandpa half as far |
| Thaddeus Fairweather | Golf trophy | A charged swing hits 15% harder |
| Augustine | Boarding pass | Landings heal one extra pill |
| The Chairman | Gold gavel | Grandpa hits bosses 10% harder |

**Wanted posters:** two per path, 20 in all.
- Pension is 40 × depth for a mini boss and 100 × depth for a floor boss. Condolences are 10 and 20.
- **Mini boss posters** pay a cosmetic: Captain's Hat, Golf Visor, Aviator Sunglasses and Power Tie.
- **Floor boss posters** pay:
  - Commodore: the Life Jacket item, which once per floor turns a lethal hit into 1 pill left.
  - Fairweather: the Lucky Tee recipe, which gives a 10% chance of a double-damage swing.
  - Augustine: the Neck Pillow item, which gives +1 max pill.
  - Chairman: the Golden Parachute recipe, which keeps 25% more Pension on death.
- The extras are then 6 items, 6 recipes and 8 cosmetics. Update the test that pins 4/4/4.
- New items and recipes each get a Coach tip.

**Letters:** one per path, from the living, in the existing tone.

**Lines:**
- Deputy Dolores gets a take line for each new poster, in the style of her current ones.
- The Purser, the Pro Shop's keeper, Duty Free's clerk and the Severance Desk's clerk get NPC lines
  that use the opener rotation and its moments.

**Dev keys:** F3 stays on floor 3. F5 starts a dev run at floor 4 and F6 at floor 5, both with every
upgrade at max and the paths above unlocked.

## 8. Size

Each path has about 33 layouts, in the floor-3 mix (`layouts.md`).
- The four paths get their own room shapes. None reuses another path's.
- The usual rooms appear on every path: a mini boss, a shop, a treasure room, a secret wall, a vault
  when one rolls, and the Arcade when one rolls.

## 9. Build order

1. **The connection:** depths 4 and 5, their landings, Crossroads and unlocks, with placeholder
   content. Also the end of the run at depth 5 and the dev keys.
2. **One complete step per path,** in this order:
   - The Last Resort Cruise
   - Fairway's End
   - Departures
   - Head Office

   Each step covers the hazard, the enemies, both bosses, the rooms and the palette, and is tested
   and pushed.
3. **The Waiting Room hooks:** the departments, upgrades, mementos, posters, letters, lines and the
   ending card.
4. **Balance with the bot,** then one independent review, then a report for the user. Nothing is
   merged until the user has played.

## Testing

- **Tests:** headless tests for every rule, following `plan-template.md` for each path.
- **The full loop:** it walks all five depths and clears every new path at least once, and its
  timeout is raised.
- **Real window:** every new attack, hazard, prop and room size is screenshotted in a real window and
  looked at.
- **The real save:** its MD5 is unchanged before and after every session.
