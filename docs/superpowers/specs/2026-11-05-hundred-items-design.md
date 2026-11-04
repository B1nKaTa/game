# One hundred items design

Approved in conversation on 2026-11-05. It builds on `deep-floors`. Every earlier spec's ground rules
still apply. Item icons stay code-drawn placeholders until the art pass, one icon per item.

## Ground rules

- **No other game's name** appears in any file, comment, asset name or commit message.
- **No new dependencies.**
- **Old saves load.** An item id a save knows keeps working. When an item is reworked, its id stays,
  so recipes, bounties and the item rack still find it.
- **Item names and texts** are in the game's dark-comedy voice: one short effect sentence, then one
  joke sentence, as today.
- **Keep the project runnable after every commit,** and keep `LESSONS.md` up to date.

## 1. Why

Today's 20 items are almost all flat stat boosts:
- 5 give speed or dodge,
- 4 give Pension,
- 3 give pills,
- 3 give damage.

Few of them change how a run plays. The new set aims for **100 items**, most of which change a
mechanic, so that each run builds into something different.

## 2. The item system

### Effects through hooks

Items keep their stat part (`StatEffect`). They also gain an optional **`effect: ItemEffect`**: a
script resource whose methods are called at moments of play. An item with no effect is stats only.

`ItemEffect` (`scripts/content/item_effect.gd`) has empty virtual methods, and `RunEffects`
(`scripts/core/run_effects.gd`) calls them on every held item, in pickup order. The moments are:

| Hook | When |
|---|---|
| `on_floor_start(ctx)` | a floor or landing is entered |
| `on_room_enter(ctx, room)` | Grandpa enters a room |
| `on_room_clear(ctx, room, damage_taken_here)` | a fight room's last enemy falls |
| `on_hit(ctx, enemy, amount, source)` | any of his hits lands. `source` is `swing`, `charge`, `combo_3`, `bite`, `thermos`, `item` |
| `on_kill(ctx, enemy, source)` | an enemy dies to him |
| `on_dodge(ctx, direction)` / `on_dodge_end(ctx)` | a dodge starts or ends |
| `on_close_call(ctx)` | an attack's hitbox passes over him mid-dodge, at most once per attack |
| `on_hurt(ctx, pills, source)` | he takes damage. It can return a smaller amount, for blocks |
| `on_lethal(ctx)` | a hit would finish him. It can return true to survive |
| `on_throw(ctx)` / `on_bite(ctx, enemy)` | the dentures leave and when they bite |
| `on_charge_release(ctx, full)` | a charged swing is let go |
| `on_bomb(ctx, at)` | a Thermos goes off |
| `on_pickup(ctx, kind, amount)` | Pension, a heal, a Slip or a Thermos is collected |
| `on_shop_open(ctx, stock)` | a shop's stock is rolled. Items may change it |
| `tick(ctx, delta)` | every frame, for timers. Use sparingly |

- **`ctx`** is a small `EffectContext` that gives safe access to the player, the run, the room and
  the HUD notice. Items never reach into scenes directly.
- **Stacking:** each effect is written for one copy, and holding two copies is not possible, as
  today.
- **Helpers:** shared visual helpers that many effects draw with go in `scripts/world/item_fx.gd`.
  These are shockwaves, clouds, puddles, sparks and a "BINGO" pop.

### Rarity, curses and tags

- **`rarity`:** `common`, `rare` or `legendary`. The rarity is shown by the colour of the item's
  pedestal and of its name.
- **`cursed`:** a strong effect with a real drawback. It is shown with a purple name and a skull. A
  cursed item always says its drawback in its text.
- **`tags`:** `cane`, `bite`, `dodge`, `defence`, `money`, `thermos`, `vision`, `room`, `boss`.
  Tags are used for the combos and for the Coach's tips.

### Where items come from

Each source rolls its rarity first, then picks an item of that rarity from the unlocked pool:

| Source | Common | Rare | Legendary |
|---|---|---|---|
| Shop | 70 | 27 | 3 (priced at 3× a rare) |
| Item room, Arcade skulls | 60 | 35 | 5 |
| Treasure room | 50 | 40 | 10 |
| Gilded Urn | 40 | 45 | 15 |
| Vault | 30 | 50 | 20 |
| Floor boss reward (pick 1 of 2) | 20 | 50 | 30 |

- **Cursed items** roll as their rarity, but are never offered as a boss reward and never in a vault.
- **Shop prices:** common 30, rare 55, legendary 160, each times the floor's `pension_mult`. Read the
  current shop price rule first and keep its ratios if they differ.

### Unlocking

Not all 100 items are in the pool from the start. They join in four ways:
- **40 are open from the start.**
- **30 join on first clears:**
  - 3 per path, on that path's first clear (10 paths × 3 = 30).
  - The list is in section 5.
  - The Waiting Room's arrival notice names them.
- **18 are recipes**, crafted at Agnes. The 8 recipes that exist today keep their prices. The 10 new
  ones cost 150 to 400 Pension.
- **12 are bounty rewards.** These are the 6 bounty items that exist today plus 6 new ones. They
  replace cosmetics on 6 posters, and those cosmetics move to the Decor Office for Condolences.

### Combos

There are 12 named pairs. Holding both adds a bonus effect. When a combo forms, a small banner shows
"COMBO: <name>", and the pause menu's run summary lists the active ones.

| Combo | Items | Bonus |
|---|---|---|
| Full Set | Extra Strong Dentures + Spare Set | both sets bite through 3 |
| Bingo Night | Lucky Bingo Card + Bingo Dabber | a BINGO also heals half a pill |
| Retirement Plan | Golden Parachute + Pension Fund Statement | death pays 50% instead of 25% |
| Mobility Scooter | Titanium Hip + Wheelchair Wheels | the roll leaves a short fire trail |
| Family Visit | Photo of the Grandkids + Casserole Dish | at 1 pill, kills heal a full pill (once per room) |
| Night Shift | Hearing Aid + Night Light | rooms are never dark (Lights Out does nothing) |
| Soup of the Day | Hot Soup Thermos + Second Thermos Strap | puddles last twice as long |
| Paper Trail | Bureaucrat's Stamp + Rubber Stamp Collection | the stamp recharges in 20 s |
| Dentist's Nightmare | Gold Fillings + Denture Glue Gun | each glued second knocks out a coin |
| Early Riser | Early Bird Special + Alarm Clock | the opening rush lasts 20 s |
| Card Shark | Loaded Dice + Lucky Bingo Card | the card table's payouts +10% |
| Last Rites | Do Not Resuscitate Bracelet + Life Jacket | the Life Jacket works twice per floor |

## 3. The current 20, reworked

The ids stay the same, so recipes and bounties keep working. The effects change, so that no two
items are plain overlaps. "Pill" means one point of health.

| Item (id) | Rarity | New effect | Source |
|---|---|---|---|
| Medical Alert Bracelet (`alert_bracelet`) | rare | +1 max pill. Dropping to 1 pill sounds an alarm that stuns nearby enemies for 1.5 s, once per room | recipe |
| Suspicious Bifocals (`bifocals`) | rare | see enemy health, and hit enemies under 25% health for +50% | recipe |
| Lucky Bingo Card (`bingo_card`) | common | every 5th Pension pickup is worth 5×, with a BINGO pop | start |
| Comfort Care Lanyard (`comfort_care_lanyard`) | rare | +1 max pill, and every heal restores +1 more | bounty |
| Extra Strong Dentures (`strong_dentures`) | rare | bites hit 50% harder and go through up to 2 enemies (unchanged) | start |
| Golden Parachute (`golden_parachute`) | rare | on death, 25% of the run's room Pension is paid again (unchanged) | recipe |
| Hearing Aid (`hearing_aid`) | common | earlier warnings, and arrows at the screen edge point to enemies off screen | start |
| Life Jacket (`life_jacket`) | rare | once per floor a lethal hit leaves 1 pill (unchanged) | bounty |
| Lucky Tee (`lucky_tee`) | common | one swing in ten hits twice as hard (unchanged) | recipe |
| The Naughty List (`naughty_list`) | rare | summoned enemies drop a present, a random small pickup, 1 in 3 times | bounty |
| Neck Pillow (`neck_pillow`) | common | +1 max pill, and landings heal you fully | bounty |
| Nitroglycerin Tablets (`nitro_tablets`) | rare, cursed | +40% cane damage. A hit of 2 or more pills makes him explode, hurting everything near him (not him) | recipe |
| Spare Pill Organizer (`pill_organizer`) | common | +1 max pill. Heals picked up at full are stored (up to 2) and used when he next takes damage | start |
| Funeral Director's Pocket Watch (`pocket_watch`) | rare | a close-call dodge slows time to 40% for 1 s | bounty |
| Prune Juice (`prune_juice`) | common, cursed | dodge cooldown halved, but each dodge costs 1 Pension (never below 0) | start |
| Senior Discount Card (`senior_discount`) | rare | shops are 25% cheaper | recipe |
| Orthopedic Slippers (`orthopedic_slippers`) | common | +10% speed, and wet floor never slides him | start |
| Support Stockings (`support_stockings`) | common | nothing slows him below 70% speed: wet, sand, sedative, quoits, paper | recipe |
| Titanium Hip (`titanium_hip`) | rare | dodging through an enemy hits it for half a swing. Queue barriers chime when he passes | recipe |
| Undertaker's Work Gloves (`undertakers_gloves`) | common | +20% cane damage. Enemies he finishes leave nothing harmful behind (no death blasts or splits) | bounty |

Check the real ids in `data/items/` before changing anything, and keep each existing file's id.

## 4. The 80 new items

**Cane (12)**
| Item | Rarity | Effect |
|---|---|---|
| Walker Tennis Balls | common | swings knock enemies back 60% further |
| Cane Sword | rare | a fully charged swing also sends a short shockwave forward |
| Bingo Dabber | common | hits mark an enemy, and the 5th mark bursts for a big hit |
| Rusty Hinge | common | the third hit of a combo stuns for 0.5 s |
| Reading Glasses on a Chain | rare | a swing that hits 3 or more enemies refunds the dodge |
| Rocking Chair Rhythm | common | right after a dodge, the next swing is a heavy hit |
| Rubber Ferrule | common | swings are 15% faster, but deal 5% less damage |
| Knitting Needles | rare | every swing also pokes 2 small needles forward |
| Shoe Horn | common | +30% damage against enemies that are winding up an attack |
| Brass Cane Topper | rare | combo finishers hit in a small ring around him |
| Grandma's Rolling Pin | legendary | the swing becomes a slow, huge overhead smash that also hits behind |
| The Reaper's Other Scythe | legendary | fully charged swings become a wide spinning sweep |

**Dentures (8)**
| Item | Rarity | Effect |
|---|---|---|
| Denture Glue Gun | rare | the dentures stick to the first enemy and keep biting for 2 s |
| Spare Set | rare | throw two sets at once, in a small spread |
| Boomerang Bite | common | the dentures fly back by themselves, biting on the way |
| Gold Fillings | common | each bite has a 20% chance to knock 1 Pension out |
| Fizzy Cleaning Tablet | common | bites leave a small fizz that slows for 1 s |
| Chattering Wind-Up Teeth | rare | lying on the floor, the dentures bite anything that walks over them |
| Overbite | common | throw range +40% |
| Shark Tooth Implant | legendary | bites cause bleeding: 3 small hits over 3 s, stacking |

**Dodge and movement (10)**
| Item | Rarity | Effect |
|---|---|---|
| Bad Hip | common | dodging leaves a cough cloud that slows enemies |
| Afterimage | rare | a ghost Grandpa left at the dodge start draws attacks for 1 s |
| Wheelchair Wheels | rare | the dodge becomes a longer roll that hits enemies on the way |
| Velcro Shoes | common | +1 dodge charge (two dodges back to back) with 30% longer cooldown |
| Hover Round | rare | while charging a swing he moves at full speed |
| Squeaky Shoes | common, cursed | +15% speed, but enemies notice him from twice as far |
| Pogo Cane | rare | a close-call dodge resets the dodge cooldown |
| Banana Peel | common | his first dodge in each room drops a peel that trips the first enemy onto it |
| Bunion Pads | common | +8% speed, and dodging never stops on a prop's corner |
| Gravity Boots | rare | slides and pushes don't move him (the roll, barriers, rings, gusts) |

**Defence and health (12)**
| Item | Rarity | Effect |
|---|---|---|
| Life Alert Button | rare | the first hit in every room is blocked |
| Knitted Cardigan | common | fire and steam hurt half as much |
| Casserole Dish | common | the first kill in every room heals half a pill |
| Sympathy Card | common | clearing a room has a 25% chance to drop a heal |
| Pill Crusher | common | heals restore half a pill more, but pills on the floor fly to him slower |
| Hot Water Bottle | rare | while standing still for 1 s, he regains half a pill every 8 s |
| Bubble Wrap | common | the first projectile each floor is popped harmlessly |
| Thick Skull | rare | blasts hurt him for one pill less (never zero) |
| Second Opinion | rare | once per floor, a heal pickup heals double |
| Hospital Bracelet | common | +1 max pill |
| Do Not Resuscitate Bracelet | rare, cursed | max pills set to 1, but all his damage is tripled |
| Eternal Warranty | legendary | once per run, death returns him to the room's door with full pills |

**Thermos and Slips (7)**
| Item | Rarity | Effect |
|---|---|---|
| Hot Soup Thermos | rare | blasts leave a burning puddle for 3 s |
| Second Thermos Strap | common | +2 Thermos capacity, and start each floor with 1 more |
| Forged Signature | rare | 25% chance a Permission Slip isn't used up |
| Pressure Cooker | rare | blasts 35% bigger, and the fuse 0.3 s longer |
| Tea Cosy | common | his own blasts never hurt him |
| Rubber Stamp Collection | common | each Slip spent also pays 10 Pension |
| Kettle Whistle | common | a Thermos stuns everything it reaches for 1 s |

**Money and shops (10)**
| Item | Rarity | Effect |
|---|---|---|
| Coupon Booklet | common | shops have one more item for sale |
| Penny Jar | common | Pension pickups fly to him from twice as far |
| Lottery Scratcher | common | each new floor pays a random 0 to 100 Pension |
| Pension Fund Statement | rare | +2% of his run Pension, paid on each room clear (at most 20 a time) |
| Loaded Dice | rare, cursed | Arcade odds are better, but every shop costs 20% more |
| Expired Coupon | rare, cursed | one shop each floor is free, but he loses 1 max pill each floor (never below 1) |
| Haggler's Hat | common | each shop's cheapest item is half price |
| Collection Plate | rare | kills pay +1 Pension |
| Inheritance Letter | common | +60 Pension at once when picked up |
| Tax Refund | rare | when he leaves a shop without buying, it pays 15 |

**Vision and information (6)**
| Item | Rarity | Effect |
|---|---|---|
| Night Light | common | dark rooms are lit around him twice as wide |
| Magnifying Glass | common | secret walls glint from across the room |
| Floor Plan | common | the whole floor's map is shown on arrival (not its contents) |
| Mothball Pockets | rare | ghosts (Soot, Debt, Mourner types) won't come near him for 2 s after a hit |
| Telescope Cane | common | the camera shows a little more ahead of where he faces |
| Fortune Teller's Card | rare | boss rooms show their boss's name on the map, and his first attack is shown slowed |

**Rooms, kills and pace (8)**
| Item | Rarity | Effect |
|---|---|---|
| Obituary Clippings | common | each kill in a room gives +4% damage, resetting at the next room |
| Grief Counselor's Card | rare | a room cleared without damage taken pays 15 Pension |
| Early Bird Special | common | for the first 10 s in each fight room, he moves and swings 20% faster |
| Alarm Clock | common | entering a fight room stuns every enemy for 0.5 s |
| Wreath of Thorns | rare | enemies that touch him take a small hit |
| Bingo Hall Pass | rare | after every 3 cleared rooms, the next room's enemies have 15% less health |
| Moving Boxes | common | leaving a room with items still on the floor carries the cheapest one along |
| Last Orders | rare | the last enemy in a room takes double damage |

**Bosses (4)**
| Item | Rarity | Effect |
|---|---|---|
| Photo of the Grandkids | rare | at 1 pill, all his damage is doubled |
| Complaint Form | rare | his hits on bosses build a meter; when full, the boss is stunned for 2 s |
| Bureaucrat's Stamp | legendary | every 30 s his next hit "files" an enemy, which is gone for good. A boss takes 15% of its health instead |
| Lawyer's Business Card | rare | a boss's first hit on him in each phase does nothing |

**Silly ones (3)**
| Item | Rarity | Effect |
|---|---|---|
| Dentures in a Glass | common | he can drink from the glass. While the dentures are away, swings are 15% faster |
| Polyester Suit | common, cursed | +25% damage, but sparks: each swing has a 10% chance to stun himself 0.3 s |
| Harmonica | common | each combo finisher plays a note; a chord of 3 in 3 s heals half a pill (once per room) |

That is 12 + 8 + 10 + 12 + 7 + 10 + 6 + 8 + 4 + 3 = **80 new items**. With the 20 reworked ones,
there are **100 in all**. Of these, 7 are cursed (Nitroglycerin Tablets, Prune Juice, Squeaky Shoes, Do Not Resuscitate
Bracelet, Loaded Dice, Expired Coupon, Polyester Suit) and 5 are legendary (Grandma's Rolling Pin,
The Reaper's Other Scythe, Shark Tooth Implant, Eternal Warranty, Bureaucrat's Stamp).

## 5. Unlock lists

- **Open from the start (40):** all the commons not listed below, plus Extra Strong Dentures.
- **Recipes (18):** the existing 8, plus Cane Sword, Spare Set, Denture Glue Gun, Wheelchair Wheels,
  Hot Soup Thermos, Pressure Cooker, Life Alert Button, Shark Tooth Implant, Grandma's Rolling Pin
  and Eternal Warranty.
- **Bounties (12):** the existing 6, plus Bureaucrat's Stamp (the Chairman), The Reaper's Other
  Scythe (Regional Reaper), Complaint Form (Senior Adjuster), Lawyer's Business Card (Doreen),
  Gravity Boots (the Commodore) and Fortune Teller's Card (Gloria). The cosmetics those posters paid
  move to the Decor Office for Condolences. Read each poster's current reward before swapping.
- **First clears (30, 3 per path):**

  | Path | Items |
  |---|---|
  | Records Basement | Rubber Stamp Collection, Floor Plan, Bingo Hall Pass |
  | Cemetery | Wreath of Thorns, Mothball Pockets, Last Orders |
  | Sunset Shores | Hot Water Bottle, Second Opinion, Bingo Dabber |
  | Furnace Works | Knitted Cardigan, Thick Skull, Kettle Whistle |
  | Funeral Parlour | Obituary Clippings, Grief Counselor's Card, Harmonica |
  | Golden Years Mall | Coupon Booklet, Haggler's Hat, Loaded Dice |
  | Last Resort Cruise | Bubble Wrap, Banana Peel, Pogo Cane |
  | Fairway's End | Knitting Needles, Brass Cane Topper, Hover Round |
  | Terminal Zero | Velcro Shoes, Expired Coupon, Tax Refund |
  | Head Office | Pension Fund Statement, Collection Plate, Polyester Suit |

Adjust a list where an item is already a recipe or a bounty. Every item must have exactly one
source, and a test checks it.

## 6. Coach tips and the item rack

- **Coach tips:** every item gets a `CoachTips` tip, short and in the coach's voice.
  `test_the_coach_has_a_tip_for_every_recipe` becomes "for every item".
- **The item rack** in the Training Yard holds every item found or crafted, as today, so many more
  items fit there. Make the rack panel scroll, and fit it to 640x360 by screenshot.

## 7. Build order

1. **The system:** ItemEffect, RunEffects, EffectContext, rarity, cursed, tags, rarity by source,
   unlock sources, combos and the banner. Add tests for each hook firing once, the rarity rolls over
   seeds, the unlock rules and the combos.
2. **The 20 reworked items,** with tests.
3. **The new items in four batches of 20,** in the order of section 4. Each item gets a test of its
   rule, each batch gets a full loop, and each batch's effects get screenshots in a real window.
4. **Balance:** Pension per full clear with the new money items, the cursed items' trade-offs, and
   the legendaries in boss fights, using the balance bot.
5. **An independent review,** then the user plays. Nothing is merged before that.

## Testing

- **Headless tests** for every item's rule, each hook, the rarity weights, the unlocks (exactly one
  source per item), combos, save migration of the reworked ids, and Coach tips for every item.
- **The full loop** still passes, and it picks up whatever items it is offered, as now.
- **Screenshots in a real window** of every visible effect (clouds, shockwaves, puddles, marks,
  stamps, ghosts), of the shop showing rarity colours, of the combo banner and of the rack panel at
  its fullest.
- **The real save's MD5** is unchanged across every session.
