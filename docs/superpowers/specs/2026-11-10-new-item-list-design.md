# New item list design

Date: 2026-11-10. Branch: `new-items` (from `rules-flashbacks`).

The item pool is replaced by the user-approved list (125 entries after four cuts): 107 pool items (89
passives, 10 pets, 8 actives), 7 run potions and 11 set bonuses. The list was reviewed entry by entry on
2026-11-10. This document turns every entry into a precise, testable rule, names the systems the game
needs for them, and says how the pools, saves and old content change.

## Ground rules

- **Source of truth:** the review list, committed as `2026-11-10-new-item-list-items.json` beside this
  file (125 entries: the cut four left out, the review's changes made). Each item, run potion and set
  keeps its id, name, build, kind, rarity, curse and player-facing description from it, word for word,
  and a test checks every shipped one against it. Where the description is vague, this document
  picks a number and says so in the "Choices" column or the section's notes.
- **Cut, never built:** `kettle_whistle`, `red_tape`, `sticky_lid`, `sugar_lumps`.
- **Changed by the review:**
  - `second_brew`: when a Thermos explodes, a few little bombs fly out and detonate a second time.
  - `filing_cabinet`: the Slip twin of `tea_urn`, balanced the same way (+5% per Slip carried, at most 20).
  - `tea_urn` keeps "+5% hit damage per Thermos carried".
- **User decisions (2026-11-10):**
  1. The new list is the whole pool. Old items not on it leave every pool and registry first; deleting
     their files is a separate step that needs the user's OK (git keeps the history).
  2. Actives: a "use item" input, a HUD slot, charge by fight rooms cleared (2 to 6 rooms each, from the
     description), one held at a time, and picking up another swaps (the old one drops).
  3. Items that scale per Thermos or Slip carried count at most 20. The hold cap stays 99
     (`RunState.MAX_CONSUMABLE`).
  4. Icons: 32 px icons at `res://art/icons/items/<id>.png`, made separately. This work adds the hooks
     only: room pickups, shop wares, the HUD item row and the case file show the icon when the PNG
     exists and keep today's look otherwise.
  5. Harold's pickup lines are not part of this work.
- **Project rules:** never name another video game anywhere (code, comments, data, docs, commits). No
  religious symbols in any drawn shape: no crosses, plus shapes, halos, inverted crosses, wreaths of
  thorns, pentagrams. No new dependencies or add-ons.

## 1. Words used below

- **His hits:** damage Harold deals himself, the `RunEffects` sources `swing`, `charge`, `combo_3`,
  `bite`, `thermos`, `item` and `era`. Pet hits (`pet`) and the turned Auditor's hits (`ally`) are not his
  hits: the "+N% to all your hits" items never multiply them. Pets have their own multiplier (section 4.3).
- **Fight room:** a room whose clear calls `RunEffects.room_clear` (it had enemies when he walked in).
- **Floor start:** `RunEffects.floor_start` on a floor, never on a landing (`EffectContext.is_landing()`).
- **Purse (Pension carried):** Pension is the save's bank, which lives across runs, so "Pension you carry"
  would make the money build free for any old save. It means the **purse**: what the bank holds above what
  it held when this run began, never below zero and never more than the bank
  (`clamp(bank - bank_at_run_start, 0, bank)`). Spending from the bank lowers the purse with it.
- **Thermos count** and **Slip count**, for the items that scale with them: the number carried, at most
  the **scale cap**, 20 (`PlayerStats.SCALE_CAP`). Two things raise the Thermos cap (Flask Holster +4,
  the Tea Lady set +3). Nothing raises the Slip cap.
- **Regular enemy:** any enemy whose `def.is_boss` is false. The Auditor is a regular enemy.
- **The full loop:** `tools/smoke.ps1`. Its checks count damage, Pension and pills exactly, through
  `EffectContext.counting_exact` and `counting_pills`. Every new rule that changes damage, pays Pension,
  blocks or heals stays quiet while those are set, as the old items do.

## 2. Systems this list needs

### 2.1 Item data

`ItemDef` gains:

| Field | Values | Meaning |
|---|---|---|
| `build` | `thermos`, `slip`, `pension`, `pets`, `bite`, `cane`, `dodge`, `pills`, `risk`, `rules`, `memory`, `any` | The build an item belongs to. Sets count it. |
| `kind` | `passive`, `pet`, `active` | How it is held. |
| `charge_rooms` | int | An active's recharge in fight rooms cleared. 0 for others. |
| `charge_per_floor` | bool | An active that recharges once a floor instead (Lottery Scratcher). |

`ItemDef.TAGS` gains the build names, and every new item's `tags` is `[build]`, so the existing tag
checks and the Coach keep working.

### 2.2 The 20-count rule

- `PlayerStats.SCALE_CAP := 20`, and a new stat `thermos_scale_bonus` (int).
- `RunState.scaled_bombs() = min(bombs, SCALE_CAP + stats.thermos_scale_bonus)` and
  `RunState.scaled_keys() = min(keys, SCALE_CAP)`.
- Every item that reads a count reads these: Tea Urn, Filing Cabinet, Gold Top Milk. Loose Paperwork
  has its own lower cap (5).
- Holding stays capped at 99 (`MAX_CONSUMABLE`), and a doubling potion never goes past it.

### 2.3 Actives

- **Holding:** `RunState.active: ItemDef` (one at most) and `RunState.active_charge: int`. Actives are not
  in `RunState.items`, but `has_item(id)` also answers for the held active, so pools never offer it twice.
  The case file shows it as the first held cell with the badge "USE".
- **Effects:** an active's `ItemEffect` runs every usual hook while held (Dinner Bell needs `tick`), and
  adds `use(ctx) -> bool` (true when it did something; false keeps the charge) and `can_use(ctx) -> bool`.
- **Charge:** each fight room cleared adds 1, up to `charge_rooms`. A `charge_per_floor` active fills
  at every floor start. Using it empties it.
- **Taking one:** a new active arrives fully charged. Taking one while holding another swaps them: the
  held one drops at Harold's feet as an item pickup that keeps its charge, and taking that one back
  brings that charge back (no free recharge by swapping).
- **Input:** a new action `use_item`, keyboard **R**, controller **B**. Space is the dodge and Q the
  Thermos, and both shoulder buttons are taken (RB the Thermos, LB the potion), so neither the asked-for
  keys nor a shoulder is free. R is free on the keyboard (no script or test binds it). B is free in play;
  in panels it is the menu's back button (`ui_pad_back`), which is a different action and does not clash,
  as A is both the dodge and `ui_accept`. B also closes the big map, the pause menu, the case file and the
  card table, which unpause the game on that press, so a use-item press counts only when the game was
  not paused the physics frame before (`Player.use_press_counts`). `tests/test_key_bindings.gd` rebinds the dodge to B as a
  "free" button in one test, so that test moves to the left stick press (LESSONS 2026-11-09). It is listed
  in `KeyBindings.ACTIONS` as "Use item", so it can be rebound.
- **HUD:** an `ActiveSlot` sits in the top band between the left panel and the right panel (x from the
  left panel's end + 4 to 400, y 3, 16 high; the band is HUD already). It shows the item's icon (14 px) or
  a drawn placeholder (a rounded box in the rarity colour with the item's initials), the key in brackets
  and the item's name, clipped, and a 2 px charge bar along its bottom with a tick per room. The bar is
  gold when ready. With no active held it draws nothing.
- **Rules rooms:** using an active is no rule action; no rule forbids it.
- **Save:** the checkpoint keeps `active` (id) and `active_charge`; the effect's own state goes in with
  the items' (`effects.save_state` gains an `"active"` entry).

### 2.4 Pets

- **Pets are items** of kind `pet`, held in `RunState.items` like passives.
- **Pet count:** `RunState.pet_count()` = pet items held + `stats.extra_pets` (the Animal Lover's stray
  cat). Pet Rock counts.
- **Pet multiplier:** `RunState.pet_damage_mult() = (1 + stats.pet_damage_bonus) × the product of every
  effect's pet_damage_scale(ctx)`. Tin of Dog Treats and Animal Lover add to the bonus (+0.5 each); Tin of
  Pet Food (×2 this floor) and Dinner Bell (×3 for 5 s) scale it.
- **Pet hits** go through `RunEffects.land` with the new source `pet`, so "on hit" items (bleeds, dabs)
  hear them as any item hit, but the "+N% to his hits" items skip them.
- **Bodies:** each pet item's effect places a `Pet` node beside Harold on every room entered. A pet
  follows him to a slot round his feet (slot angle by pickup order), at 150 px/s (Shelley 40 px/s;
  `pet_speed_bonus` adds), lunges at what it bites, never takes damage, never blocks Harold or enemies,
  and is no enemy and no target. A pet joins `ItemFx.GROUP`, so leaving a room clears it and the next
  room places it again. All of a pet's rules live in its effect, so tests drive them without nodes.
- **Looks:** placeholders drawn in code (a body, a head, ears or wings in the pet's colour) until art
  exists; then `res://art/props/pet_<id>.png` through `PropArt.texture("pet_<id>")`. No pet look uses a cross or plus shape.

### 2.5 Shot guards

- New `ShotGuards` (core): group `shot_guards`, and `ShotGuards.try_block(tree, at) -> bool`, which asks
  each guard node `blocks_shot(at) -> bool` (a guard that blocks also spends what it had).
- `Projectile._physics_process` asks it every step before its target check; a blocked shot lands where
  it is (`_land()`), as on a wall. Only `Projectile` shots are "shots": ground strikes, blasts and lanes
  are not, so no guard stops them.
- Guards: Joey the Budgie, Shelley the Tortoise, the moths, a big enough Pet Rock, Loose Paperwork's
  sheets and the Walking Frame.

### 2.6 Set bonuses

- New `SetDef extends StatEffect` in `data/sets/<id>.tres`: `id`, `display_name`, `description`,
  `build`, `needed` (3), and `effect: ItemEffect`. Its stats count once, as a combo's do.
- **Counting:** items held (passives, pets) plus the held active whose `build` is the set's build. The
  Animal Lover counts pet items (`kind == pet`) instead. Potions never count; `any` counts for nothing.
- **Forming:** the moment the count reaches `needed`, once per run. A formed set stays for the run even if
  a swap drops the count (as a combo forms once). A banner shows "SET: <name>" (the combo banner's look),
  and the big map's summary lists formed sets.
- **Save:** the checkpoint keeps the formed set ids and puts them back without a second `on_gain`.
- **The old pair combos are retired** with the old items (section 6): the set bonuses take their place,
  and seven of the twelve name an item that leaves. `ComboDef` and its code stay, so a combo can come back.

### 2.7 Potions

- `PotionDef` gains `action` (one of `double_bombs`, `double_slips`, `swap`, `cash_in`, `salts`,
  `courage`, `pet_food`, or "" for a plain heal or buff), `run_rarity` (`common`, `rare`, or "" for never
  in a run's pool), and `effect: ItemEffect` (a lasting part).
- `RunState.can_drink_potion` refuses a potion that would do nothing (doubling 0, swapping equal counts,
  cashing in nothing, pet food with no pet), as it refuses a heal at full pills today.
- **Lasting parts:** drinking puts a copy of `effect` into `RunEffects` as a lasting effect, which hears
  every hook and is dropped once its `is_spent()` is true. The checkpoint keeps each lasting effect's
  potion id and state.
- **Where run potions come from** (`PotionPool`):
  - every potion drop (barrels, lunchboxes, vaults, the Naughty-List-style presents): 55% Small Potion,
    30% a common run potion, 15% a rare one, each picked evenly;
  - every shop sells one potion ware: common 70%, rare 30%; price 25 (common) or 40 (rare) times the
    floor's `pension_mult`, with discounts as other wares;
  - the Waiting Room's merchant brews are unchanged and never sell run potions.

### 2.8 Rules and memories

The rules-and-flashbacks prototype posts rules on floor 1 only (`RulePicker.ENABLED_DEPTH = 1`), and
reels come only from kept rules. So:
- **Rules and memory items are offered only on floors that post rules:** `RunState.rules_posted()` is
  true when `floor_depth <= RulePicker.ENABLED_DEPTH` or `stats.extra_rule_rooms > 0`.
  `RoomRules.offerable` skips `rules` and `memory` passives otherwise (the Megaphone, a `rules` active,
  works anywhere and is always offered). Held ones keep working everywhere.
- **Run counters:** `RunState.rules_kept`, `rules_broken`, `flashbacks_played` (this run only; the
  save's lifetime counts stay as they are). The checkpoint keeps them.
- **Events:** `RunEffects.EVENT_RULE_KEPT`, `EVENT_RULE_BROKEN`, `EVENT_FLASHBACK_START`,
  `EVENT_FLASHBACK_END` reach every effect through `on_event`.
- **New hooks:** `excuses_rule_break(ctx) -> bool` (Fine Print) and `sides_with_you(ctx) -> bool` (Clipboard
  of Your Own).
- **Reels:** `RunState.held_reels: Array[String]`, at most `reel_cap() = 1 + stats.extra_reels`.
  `held_reel` stays as a property (the first held), so the HUD, the keeper and old checkpoints keep
  working. The HUD reel slot adds "x2" when two are held.
- **Longer flashbacks:** `stats.extra_era_rooms` (Old Projector) keeps an era going into that many more
  fight rooms entered for the first time on the floor.
- **Extra rule rooms:** `RulePicker.rule_rooms(map, depth, seed, extra)` posts `extra` more, deeper
  floors included, never more than the floor's combat rooms.

### 2.9 Other hooks and plumbing

- `ItemEffect.on_blast_hits(ctx, at, count)`: a Thermos blast landed on `count` enemies (Tea Break).
- `ItemEffect.pet_damage_scale(ctx) -> float` (2.4).
- `ItemEffect.is_spent() -> bool` (2.7) and `on_drink(ctx)`.
- **Pickup amounts for Slips and Thermoses:** `RoomView._take_consumable` gives what
  `effects.pickup(kind, 1)` returns, not always 1 (In Triplicate), capped at 99.
- **Purse:** `EffectContext.pension_balance` (a Callable the floor scene sets to read the bank),
  `ctx.purse()` and `ctx.spend_from_purse(amount) -> bool`. `RunState.pension_at_start` is set when the
  run begins and kept by the checkpoint.
- **Floor depth:** `RunState.floor_depth`, set on every floor and landing.
- **Health:** `Health.lose_half(never_last)` (Unpaid Bill), and `Health.half_heal_bonus` (Hypochondriac:
  every heal that restores a pill also heals half a pill, never twice from one heal).
- **Auditor:** `Enemy.extra_damage` (added to every attack's pills) and `Enemy.coin_mult` (on its
  Pension). An ally Auditor (`AllyAuditor`) for Clipboard of Your Own.
- **Item icons (`ItemIcons`):** `ItemIcons.path(id)` is `res://art/icons/items/<id>.png`;
  `ItemIcons.texture(id)` loads it when `ResourceLoader.exists`, else returns null; tests can put a
  texture in with `ItemIcons.set_for_test(id, texture)`. Used by:
  - `Pickup.icon_id`: a room item, a free item, a boss or urn choice, a dropped active and an item shop
    ware draw the icon at 20x20 centred instead of the rarity disc; the name label and prompt stay;
  - the HUD item row: each of the newest three items shows its icon at 12x12 in place of its name when it
    has one, else its name, after "Items: N";
  - the case file: it already draws `<id>.png` at 26x26; it now goes through `ItemIcons`;
  - the active slot (2.3).

## 3. Pools, rarity and unlocks

### 3.1 The pool

- The pool is `Content.items()`: every `data/items/*.tres` whose id is not in `RetiredContent.RETIRED_ITEMS`.
  `Content.all_items()` still loads every file, for old tests and save migration, until the deletion step.
- Pool items are passives, pets and actives. Potions and sets are never in it.
- **Rarity tables are unchanged** (`ItemRarity.WEIGHTS`): shop 70/27/3, item room and Arcade 60/35/5,
  treasure 50/40/10, urn 40/45/15, vault 30/50/20, boss 20/50/30. Prices unchanged (35, 60, 175).
- Cursed items stay out of boss rewards and vaults. Rules and memory items stay out of floors with no
  rules (2.8).
- Counts: 40 common, 52 rare, 15 legendary; 5 cursed (Nitroglycerin Tablets, Polyester Suit, Prune Juice,
  Unpaid Bill, Glass Hip).

### 3.2 Where each kind drops

| Source | Gives |
|---|---|
| Item room, treasure room, Gilded Urn, vault, Arcade item win, Retirement Plan bonus, Auditor's item | pool items (passive, pet or active), by the source's table |
| Floor boss | a choice of 2 pool items |
| Shop | 2 pool items (+1 with Coupon Booklet), 1 run potion, a heal, a Slip, a Thermos |
| Barrels, lunchboxes, vaults' extras | a potion drop rolls the potion pool (2.7) |
| Rule room kept | a reel (two with By the Book), a 1-pill heal with Gold Star Sticker |
| Sets | never dropped; formed by holding 3 of a build |

### 3.3 Unlock sources

Each pool item has exactly one source (`ItemUnlocks`), keeping the old quotas: 47 open from the start,
30 on first clears (3 per path), 18 recipes, 12 poster rewards. Kept items keep their old source; a
renamed item takes its old id's source.

- **Recipes (18):** the 14 kept recipe items at their prices (Suspicious Bifocals 70, Titanium Hip 80,
  Senior Discount Card 90, Nitroglycerin Tablets 120, Cane Sword 180, Denture Glue Gun 200, Pressure Cooker
  210, Spare Set 220, Wheelchair Wheels 240, Hot Soup Thermos 250, Life Alert Button 280, Shark Tooth
  Implant 360, Eternal Warranty 380, Grandma's Rolling Pin 400) and four new legendaries at 350: Tea Urn,
  Filing Cabinet, Money Belt, Heart Monitor. The four recipe posters whose recipes leave change:
  The Reverend → Tea Urn, Senior Adjuster → Filing Cabinet, The Chairman of the Board → Money Belt,
  Madame Zara → Heart Monitor.
- **Poster rewards (12):** the six kept (Bureaucrat's Stamp: Doreen; Comfort Care Lanyard: Matron Mercy;
  Complaint Form: Sergeant Wanda; Life Jacket: Commodore Wellington; Funeral Director's Pocket Watch:
  Mortimer Grimsby; The Reaper's Other Scythe: Regional Reaper) and six on the posters whose items leave:
  Augustine → Photocopier, Sister Celestine → Old Shep, Cornelius Crabtree → Overarm Bowler, Lorraine →
  Polly the Parrot, The Projectionist → Old Projector, Digby the Tired Undertaker → Pet Cemetery Plot.
- **First clears (30):**

  | Path | Items |
  |---|---|
  | floor_1 (Records Basement) | Floor Plan, Rubber Stamp Collection, Model Citizen's Badge |
  | cemetery | Last Orders, Pocketful of Moths, Cactus Brooch |
  | sunset_shores | Bingo Dabber, Joey the Budgie, Those Were the Days |
  | furnace_works | Bottomless Flask, Tea Break, Second Brew |
  | funeral_parlour | Obituary Clippings, Harmonica, Mittens |
  | flashback_cinema | Coupon Booklet, Haggler's Hat, Photo Album |
  | last_resort_cruise | Pogo Cane, Shelley the Tortoise, Shepherd's Crook Handle |
  | seance_hotline | Brass Cane Topper, Knitting Needles, Rose-Tinted Glasses |
  | terminal_zero | Velcro Shoes, Unpaid Bill, Glass Hip |
  | head_office | Compound Interest, Polyester Suit, Repeat Offender |

- **Open from the start (47):** every other pool item.
- **Coach tips:** every pool item has a `CoachTips` tip, short and in the Coach's voice
  (`test_training_yard` checks it). Kept ids keep theirs unless their rule changed; the plan gives every
  new one.

## 4. The items

Each row gives the rule a test checks. "Src" is the unlock source (S start, R recipe, B poster, F first
clear). Every number in **bold** was chosen here because the list leaves it open.

### 4.1 Thermos (9)

| id | Name | Rarity, src | Rule |
|---|---|---|---|
| `tea_urn` | Tea Urn | legendary, R 350 | His hits deal +5% per Thermos counted (2.2). |
| `flask_holster` | Flask Holster | common, S | On taking: +2 Thermoses. `thermos_scale_bonus` +4, so Thermos counts reach 24. (Replaces Second Thermos Strap.) |
| `bottomless_flask` | Bottomless Flask | rare, F furnace_works | Every 2nd fight room cleared gives +1 Thermos (a pop "+1"). The count survives a resume. |
| `hot_soup_thermos` | Hot Soup Thermos | rare, R 250 | Each of his blasts leaves a burning puddle, radius 34 px, for 3 s, burning enemies in it for 2 damage at the puddle's usual rate (`ItemFx.FxBurn`, today's rule; the combo's longer puddle goes). |
| `pressure_cooker` | Pressure Cooker | rare, R 210 | Blast radius +50%, fuse +0.3 s. |
| `tea_cosy` | Tea Cosy | common, S | His own blasts never cost him a pill. |
| `second_brew` | Second Brew | rare, F furnace_works | When one of his Thermoses explodes, **3** bomblets fly out to points **40 px** away (120° apart, the first at a random angle) and burst **0.35 s** later: radius **26 px**, **half** that Thermos's damage, push 80, enemies only (no props, walls, chests or Harold). Bomblets never make bomblets and never count as a Thermos exploding for other items. |
| `thermos_lob` | Overarm Bowler | legendary, B Crabtree | The Thermos key throws instead of placing: the Thermos flies toward the aim point, at most **160 px**, in **0.4 s**, stopping early at a wall, and bursts on landing (plus the Pressure Cooker's 0.3 s when held). A Thermos rule still counts it as placed. |
| `tea_break` | Tea Break | rare, F furnace_works | A blast of his that lands on 3 or more enemies heals half a pill (pop "TEA BREAK"). |

### 4.2 Slips (8)

| id | Name | Rarity, src | Rule |
|---|---|---|---|
| `filing_cabinet` | Filing Cabinet | legendary, R 350 | His hits deal +5% per Slip counted (at most 20). |
| `in_triplicate` | In Triplicate | rare, S | Every Slip picked up or bought counts as 2. |
| `key_cutter` | Duplicate Key Cutter | common, S | On taking: +3 Slips. Every floor start: +1 Slip. |
| `loose_paperwork` | Loose Paperwork | rare, S | On entering a room, he gets one sheet per Slip carried, at most 5. Sheets circle him at 20 px; each blocks one shot and is gone until the next room. |
| `rubber_stamp_collection` | Rubber Stamp Collection | common, F floor_1 | Every Slip handed over pays 15 Pension. (Replaces `rubber_stamps`.) |
| `paper_cuts` | Paper Cuts | rare, S | Every combo finisher also flings a paper slip forward: it cuts every enemy in its line for **14**, flies **180 px** at **320 px/s**, and costs no Slip. |
| `locksmiths_apron` | Locksmith's Apron | common, S | Everything opened with Slips costs one fewer, never less than one. Today only the Gilded Urn costs more than one (2 → 1). |
| `desk_drawer` | Desk Drawer | rare, S | The first Slip he picks up in a room also gives a Thermos; the first Thermos he picks up in a room also gives a Slip. |

### 4.3 Pension (9)

| id | Name | Rarity, src | Rule |
|---|---|---|---|
| `money_belt` | Money Belt | legendary, R 350 | His hits deal +5% per full 50 Pension in the purse, at most +50%. |
| `piggy_bank` | Piggy Bank | rare, S | A hit that would cost N pills costs 20×N Pension from the purse instead, when the purse holds that much (a coin sound and "-20"). |
| `compound_interest` | Compound Interest | rare, F head_office | Every floor start: pays 15% of the purse, rounded down. (Replaces Pension Fund Statement.) |
| `senior_discount` | Senior Discount Card | rare, R 90 | Shop prices −25%. |
| `hagglers_hat` | Haggler's Hat | common, F flashback_cinema | The cheapest item ware in every shop is free ("Free: <name>"). |
| `coupon_booklet` | Coupon Booklet | common, F flashback_cinema | Shops sell one more item. |
| `gold_fillings` | Gold Fillings | common, S | Each bite knocks a 1-Pension coin loose one time in four (25%), at most 6 a room, from paying enemies only. |
| `coin_purse_cane` | Coin Purse Cane | rare, S | Every 10 Pension picked up loads a coin (at most **3** loaded). His next cane swing fires one: a shot of **12** that flies **220 px** at **360 px/s** and stops at the first enemy. |
| `inheritance_letter` | Inheritance Letter | common, S | Pays 75 Pension on taking. |

### 4.4 Pets (12, and the stray cat)

M is the pet multiplier (2.4). "Nearest" means nearest to Harold's feet.

| id | Name | Rarity, src | Rule |
|---|---|---|---|
| `rex` | Rex, the Late Dog | rare, S | Every 1.0 s, bites the nearest enemy within **160 px** for **6×M**. |
| `mittens` | Mittens | rare, F funeral_parlour | Every **0.5 s**, finishes the nearest regular enemy within **200 px** that is below 25% health (a pet hit for its remaining health). **Never a boss.** |
| `budgie` | Joey the Budgie | common, F sunset_shores | Circles him at 22 px and blocks a shot; after a block it needs 3 s before it blocks again. |
| `tortoise` | Shelley the Tortoise | common, F last_resort_cruise | Plods after him at **40 px/s**. Every shot that touches her **18×12 px** body stops. She cannot be hurt. |
| `racing_pigeon` | Racing Pigeon | common, S | Every **1.5 s**, fetches the nearest waiting coin, Slip or Thermos in the room that he could take: it flies to him. (Replaces Penny Jar.) |
| `moths` | Pocketful of Moths | common, F cemetery | Two moths circle him at 26 px, opposite each other. A moth touching an enemy's body nibbles it for **2×M**, each enemy at most once a **0.5 s** per moth. Each moth blocks one shot, then is gone for **4 s**. (Replaces Mothball Pockets.) |
| `ferret` | Trouser Ferret | rare, S | Every dodge, bites the nearest enemy within **120 px** for **15×M**. |
| `sheepdog` | Old Shep | legendary, B Celestine | Every **6 s**, every regular enemy within **220 px** is shoved toward a point 64 px ahead of him (in his aim) over 0.35 s and dazed 0.3 s. No damage. |
| `parrot` | Polly the Parrot | rare, B Lorraine | 1.0 s after a cane swing lands, Polly repeats it: each enemy that swing hit, if still alive, takes **half** that hit's damage ×M as a pet hit. Only cane swings are copied. |
| `pet_rock` | Pet Rock | common, S | A pet that does nothing but grow: size = 1 + other `pets`-build items held. At size **3** or more it sits at his heel and blocks every shot that touches it (radius 6 + 3×size px). |
| `dog_treats` | Tin of Dog Treats | common, S | `pet_damage_bonus` +0.5, `pet_speed_bonus` +0.25. |
| `pet_cemetery_plot` | Pet Cemetery Plot | legendary, B Digby | His hits deal +8% per pet (`pet_count`). |
| (stray cat) | Stray Cat | from Animal Lover | Every **1.5 s**, scratches the nearest enemy within **120 px** for **4×M**. Counts as a pet. |

### 4.5 Dentures (9)

| id | Name | Rarity, src | Rule |
|---|---|---|---|
| `strong_dentures` | Extra Strong Dentures | rare, S | Bites +50%, bite through 2 enemies. (Replaces `dentures`.) |
| `boomerang_bite` | Boomerang Bite | common, S | The dentures fly back by themselves, biting on the way. |
| `spare_set` | Spare Set | rare, R 220 | Two sets a throw, in a spread. |
| `shark_tooth` | Shark Tooth Implant | legendary, R 360 | Each bite starts a bleed of 3 hits of 5, one a second; bleeds stack. |
| `glue_gun` | Denture Glue Gun | rare, R 200 | The dentures stick to the first enemy bitten and keep biting for 2 s. |
| `chattering_bounce` | Chattering Ricochet | rare, S | After each bite, the dentures jump to the next nearest living enemy within **140 px** of the bitten one that this throw has not bitten, up to 3 jumps a throw. A jump is a bite (bite damage, source `bite`, and the bite hook runs). |
| `windup_teeth` | Chattering Wind-Up Teeth | rare, S | Dentures lying on the floor bite what walks over them. |
| `fizzy_tablet` | Fizzy Cleaning Tablet | common, S | A bite slows the bitten enemy by half for 2 s, and its fizz on the floor slows by half for 2 s. |
| `dentures_in_glass` | Dentures in a Glass | common, S | While his dentures are out, his combo swings 25% faster. |

### 4.6 Cane (10)

| id | Name | Rarity, src | Rule |
|---|---|---|---|
| `cane_sword` | Cane Sword | rare, R 180 | A full charge also sends a shockwave forward (18, 150 px). |
| `brass_topper` | Brass Cane Topper | rare, F seance_hotline | A combo finisher hits all round him. (Display name back to the list's.) |
| `lightning_rod` | Lightning Rod Cane | rare, S | Every enemy a fully charged swing hits also takes a bolt of **20** (item hit, a small blast look). |
| `rolling_pin` | Grandma's Rolling Pin | legendary, R 400 | Every plain swing is a slow, huge smash that also hits behind him (×2 damage, swing speed −40%). |
| `reapers_scythe` | The Reaper's Other Scythe | legendary, B Regional Reaper | A full charge becomes a spinning sweep all round him. |
| `knitting_needles` | Knitting Needles | rare, F seance_hotline | Every swing pokes two needles forward (5 each, 130 px). (Display name back to the list's.) |
| `cane_hook` | Shepherd's Crook Handle | common, F last_resort_cruise | Each regular enemy a combo finisher hits is pulled toward his feet (push **240**, **0.25 s**). |
| `rusty_hinge` | Rusty Hinge | common, S | The combo's third hit stuns for 1.0 s; the same enemy again only after **2.5 s**. |
| `bingo_dabber` | Bingo Dabber | common, F sunset_shores | His hits dab marks; the fifth bursts for 30. |
| `obituary_clippings` | Obituary Clippings | common, F funeral_parlour | Each kill in a room adds +5% to his hits there, at most 10 kills (+50%). Each kill pops the total ("+25%") over him. |

### 4.7 Dodge (8)

| id | Name | Rarity, src | Rule |
|---|---|---|---|
| `pocket_watch` | Funeral Director's Pocket Watch | rare, B Mortimer | A close-call dodge slows time to 40% for 1 s. |
| `wheelchair_wheels` | Wheelchair Wheels | rare, R 240 | The dodge is a 60% longer roll that runs over enemies (a plain swing each). |
| `titanium_hip` | Titanium Hip | rare, R 80 | Dodging through an enemy deals a full plain swing (10 × his cane damage). |
| `pogo_cane` | Pogo Cane | rare, F last_resort_cruise | A close-call dodge makes the dodge ready at once. |
| `velcro_shoes` | Velcro Shoes | common, F terminal_zero | +1 dodge in a row, and no longer cooldown. |
| `afterimage` | Afterimage | rare, S | A copy stays where a dodge began for 1 s, and regular enemies go for it. |
| `bad_hip` | Bad Hip | common, S | Every dodge leaves a cough cloud, radius **36 px**, for 3 s, slowing enemies by half. |
| `rocking_chair` | Rocking Chair Rhythm | common, S | The first swing within 0.8 s of a dodge ending hits twice as hard. |

### 4.8 Pills (8)

| id | Name | Rarity, src | Rule |
|---|---|---|---|
| `heart_monitor` | Heart Monitor | legendary, R 350 | His hits deal +6% per pill of maximum health. |
| `hospital_bracelet` | Hospital Bracelet | common, S | +1 pill. |
| `comfort_care_lanyard` | Comfort Care Lanyard | rare, B Matron Mercy | +1 pill; every heal gives 1 more. |
| `pill_organizer` | Spare Pill Organizer | common, S | A heal taken at full health is stored, up to 3; each stored heal soaks one whole hit. No extra pill any more. |
| `casserole_dish` | Casserole Dish | common, S | The first kill in each room heals half a pill. |
| `life_alert_button` | Life Alert Button | rare, R 280 | The first hit in each room is blocked. |
| `life_jacket` | Life Jacket | rare, B Commodore | Once a floor, a finishing hit leaves him one pill. |
| `eternal_warranty` | Eternal Warranty | legendary, R 380 | Once a run, death puts him back at the room's door with every pill. |

### 4.9 Risk (6)

| id | Name | Rarity, src | Rule |
|---|---|---|---|
| `photo_of_grandkids` | Photo of the Grandkids | rare, S | On his last pill his hits deal double. |
| `nitro_tablets` | Nitroglycerin Tablets | rare, R 120, cursed | Cane +40%; a hit of 2 pills or more sets off a blast round him (30, 72 px) that never hurts him. |
| `polyester_suit` | Polyester Suit | common, F head_office, cursed | Cane +35%; each swing has a **10%** chance to shock him still for 0.5 s, with a crackle. |
| `prune_juice` | Prune Juice | common, S, cursed | The dodge recovers twice as fast; every dodge costs 1 Pension (free with none). |
| `unpaid_bill` | Unpaid Bill | rare, F terminal_zero, cursed | His hits deal +50%. Walking into a fight room for the first time takes 10 Pension from the purse; with less than 10 it takes half a pill instead (`Health.lose_half`, **never his last pill**). |
| `glass_hip` | Glass Hip | rare, F terminal_zero, cursed | Walk and swing 30% faster; every hit costs one more half pill (every second hit that costs pills costs one pill more). |

### 4.10 Rules and the Auditor (6)

Offered only on floors that post rules (2.8).

| id | Name | Rarity, src | Rule |
|---|---|---|---|
| `model_citizen` | Model Citizen's Badge | rare, F floor_1 | His hits deal +6% per rule kept this run. |
| `repeat_offender` | Repeat Offender | rare, F head_office | His hits deal +6% per rule broken this run. Every Auditor's hit costs **1 more pill**. |
| `fine_print` | Fine Print | common, S | The first rule broken on each floor is let off: no Auditor, a grey "WARNING" stamp instead of VIOLATION. It still counts as broken. |
| `brown_envelope` | Brown Envelope | rare, S | The Auditor pays twice his Pension and always leaves an item. |
| `turned_auditor` | Clipboard of Your Own | legendary, S | A broken rule (not let off) sends an ally Auditor through the same door after the usual 2 s. He fights for Harold the rest of the room: walks to the nearest enemy at **90 px/s** and swings his clipboard every **1.2 s** for **12** (source `ally`) at **36 px**; he cannot be hurt, is no enemy, and leaves when the room clears. |
| `gold_star` | Gold Star Sticker | common, S | A kept rule also drops a 1-pill heal beside the reel. |

### 4.11 Memories (5)

Offered only on floors that post rules (2.8).

| id | Name | Rarity, src | Rule |
|---|---|---|---|
| `photo_album` | Photo Album | rare, F flashback_cinema | `extra_reels` +1: hold two reels. |
| `old_projector` | Old Projector | rare, B Projectionist | `extra_era_rooms` +1: after the era's room clears, the era goes on into the next fight room he enters for the first time on this floor, and ends when that one clears (or the floor ends). |
| `those_were_the_days` | Those Were the Days | common, F sunset_shores | A flashback ending heals one pill (not when the floor ends it). |
| `rose_tinted` | Rose-Tinted Glasses | rare, F seance_hotline | In a flashback (`run.era` set), his hits deal +30%. |
| `scrapbook` | Scrapbook | legendary, S | Old Harold's hits (`run.era` empty) deal +8% per flashback started this run. |

### 4.12 Any build (9)

| id | Name | Rarity, src | Rule |
|---|---|---|---|
| `floor_plan` | Floor Plan | common, F floor_1 | The map shows every room of a floor on arrival. |
| `magnifying_glass` | Magnifying Glass | common, S | Secret walls glint from across the room. |
| `alarm_clock` | Alarm Clock | common, S | Walking into a fight room stuns every enemy there for 1.0 s once the room's wait is over. |
| `early_bird_special` | Early Bird Special | common, S | For the first 10 s in a fight room he walks and swings 25% faster. |
| `bureaucrats_stamp` | Bureaucrat's Stamp | legendary, B Doreen | Every 30 s his next hit files a regular enemy away for good; on a boss it takes 10% of its health, never past its phase line. |
| `bifocals` | Suspicious Bifocals | rare, R 70 | A hit of his that leaves a regular enemy below 15% health finishes it. (No health bars any more: the list does not name them.) |
| `last_orders` | Last Orders | rare, F cemetery | The last enemy left in a room takes double damage (never a boss). |
| `complaint_form` | Complaint Form | rare, B Sergeant Wanda | His hits on a boss fill a form; a full one stuns it 2 s. |
| `cactus_brooch` | Cactus Brooch | rare, F cemetery | An enemy whose body touches him takes **6** (item hit) and is pushed away (**160**, **0.2 s**), each enemy at most once a **0.5 s**. Drawn as a small green brooch with a spark, never a ring of thorns. (Replaces Wreath of Thorns.) |

### 4.13 Actives (8)

| id | Name | Rarity, src | Charge | Use |
|---|---|---|---|---|
| `hearing_aid_feedback` | Hearing Aid | rare, S | 3 rooms | Stuns every enemy in the room for 2 s, with a ring shockwave. (Replaces `hearing_aid`.) |
| `harmonica` | Harmonica | common, F funeral_parlour | 4 rooms | Heals one pill. Refused at full pills. |
| `lottery_scratcher` | Lottery Scratcher | common, S | once a floor | Drops one random thing at his feet: **40%** a 25-Pension coin, **20%** a Slip, **20%** a Thermos, **15%** a 1-pill heal, **5%** a free item from the item-room table (a coin if none is left). |
| `walking_frame` | Walking Frame | common, S | 2 rooms | Plants a frame **24 px** ahead, across his aim, **40×10 px**, for 6 s: a solid body (collision layer 1) that stops enemies, and a shot guard. |
| `exchange_desk` | Exchange Desk | rare, S | 2 rooms | Swaps his Slips and Thermoses. Refused when they are equal. |
| `photocopier` | Photocopier | legendary, B Augustine | 6 rooms | Copies the waiting pickup nearest him: a coin (same amount), Slip, Thermos, heal or potion; the copy lies beside it. Never an item, ware, recipe, reel or chest. Nothing to copy: not used. |
| `megaphone` | Megaphone | rare, S | 2 rooms | Every enemy in a **90°** cone **150 px** ahead is shoved away (**220**, 0.3 s) and stunned **1.5 s**. |
| `dinner_bell` | Dinner Bell | rare, S | 2 rooms | Pets hit three times as hard for 5 s. Refused with no pet. |

### 4.14 Potions (7)

| id | Name | Run rarity | Drink |
|---|---|---|---|
| `double_brew` | Double Brew | rare | Thermoses ×2 (at most 99). |
| `locksmiths_tonic` | Locksmith's Tonic | rare | Slips ×2 (at most 99). |
| `topsy_turvy` | Topsy-Turvy Tonic | common | Swaps Slips and Thermoses. |
| `gold_top` | Gold Top Milk | rare | Pays 10 Pension per Slip and per Thermos counted (each at most 20, so at most 400), and keeps them. |
| `smelling_salts` | Smelling Salts | common | The next fight room he enters: its enemies are stunned for 3 s once the room's wait is over. |
| `dutch_courage` | Dutch Courage | rare | His hits +60%, and every hit on him costs double, until **2 fight rooms are cleared** (the one he is in counts) or the floor ends. |
| `pet_food` | Tin of Pet Food | common | Pets ×2 until the floor ends. |

### 4.15 Set bonuses (11)

| id | Name | Needs | Bonus |
|---|---|---|---|
| `set_tea_lady` | Tea Lady | 3 thermos | `thermos_scale_bonus` +3 ("carry 3 more", see 7.1), blast radius +25%. |
| `set_civil_servant` | Civil Servant | 3 slip | Every fight room cleared: a 1-in-3 chance of a Slip where the last enemy fell. |
| `set_penny_pincher` | Penny Pincher | 3 pension | Coins fly to him from anywhere in the room (`coin_reach_bonus` +20), shop prices −15%. |
| `set_animal_lover` | Animal Lover | 3 pets (pet items) | `pet_damage_bonus` +0.5, and the stray cat joins for the run (`extra_pets` +1). |
| `set_full_set` | Full Set | 3 bite | One more set of dentures every throw (`bonus_teeth_sets` +1: 2 sets, 3 with Spare Set). |
| `set_old_soldier` | Old Soldier | 3 cane | Every combo finisher sends a shockwave forward (18, 150 px). |
| `set_spry` | Spry | 3 dodge | +1 dodge in a row, dodge lasts 30% longer (untouchable for longer). |
| `set_hypochondriac` | Hypochondriac | 3 pills | +1 pill, and every heal gives half a pill more. |
| `set_daredevil` | Daredevil | 3 risk | The first kill in each room heals half a pill. |
| `set_rulebook` | By the Book | 3 rules | `extra_rule_rooms` +1 on every floor, deeper floors too, and a kept rule drops two reels. |
| `set_nostalgic` | Nostalgic | 3 memory | `extra_reels` +1: a kept rule's reel is kept even while two are held. |

## 5. Save and compatibility

- **Renamed ids** (`RetiredContent.RENAMED`): `second_thermos_strap` → `flask_holster`, `rubber_stamps`
  → `rubber_stamp_collection`, `pension_statement` → `compound_interest`, `penny_jar` → `racing_pigeon`,
  `mothball_pockets` → `moths`, `wreath_of_thorns` → `cactus_brooch`, `hearing_aid` →
  `hearing_aid_feedback`, `dentures` → `strong_dentures`.
- **A resumed run:** `RunCheckpoint.apply_run` maps every item id through `RENAMED`, skips ids that are
  retired or unknown (as it skips unknown ids today), puts an active back in the active slot with its
  charge, gives the effect no saved state when its id was renamed, and drops saved combo states. A
  checkpoint's `held_reel` string loads into `held_reels`. A room snapshot's retired item is left out.
- **The profile:** `ProgressData.from_dict` maps `recipes_found`, `items_unlocked`, `items_seen` and
  `crafted_for_next_run` through `RENAMED`. A crafted item waiting for the next run whose recipe leaves
  (`alert_bracelet` 100, `golden_parachute` 110, `lucky_tee` 90, `support_stockings` 80) is refunded
  its price into the bank. Retired ids left in `items_unlocked` and `items_seen` are harmless.
- **Old saves load:** a test loads `tests/fixtures/save_v1_2026-11-04.json` and a checkpoint holding
  `second_thermos_strap`, `bingo_card` and `hearing_aid`, and checks the result.

## 6. Old content leaving

- **Retired at the switch-over** (out of every pool and registry, files kept): the 48 old items not on the
  list (the 47 old ids not on it and the cut `kettle_whistle`), and all 12 combos.
- **Deleted later, with the user's OK:** those 48 `.tres` files, the 12 combo `.tres` files, the item
  scripts only they use, and the tests only about them. The plan lists each file.
- **Coach tips, the dev kit and the full loop** move off retired ids in the switch-over.

## 7. Conflicts and choices to confirm

1. **"Carry more Thermoses" with a 99 cap.** Flask Holster ("carry 4 more") and Tea Lady ("carry 3 more")
   have nothing to raise while holding stays at 99. Chosen: they raise the Thermos **scale cap** (20 → 24
   → 27), so the Thermos build's scaling items count more. Alternative: give them the old Strap's
   "+1 Thermos every floor".
2. **Pension carried.** The bank lives across runs, so the Money Belt and Piggy Bank would be maxed for
   any old save. Chosen: the purse (section 1).
3. **Rules and memories on floor 1 only.** Rules post on floor 1 only today, so these 11 items would be
   dead weight deeper. Chosen: offered only on floors that post rules; By the Book posts rules deeper.
   Raising `RulePicker.ENABLED_DEPTH` later opens them up with no item change.
4. **Locksmith's Apron** only changes the Gilded Urn (the only thing costing 2 Slips).
5. **Combos retired.** The list replaces them with set bonuses; the code stays.
6. **Mittens never finishes a boss**, and **Polly copies at half damage**, so neither pet ends a boss
   fight alone.
7. **The use-item key is R / pad B**, since Space, Q and both shoulders are taken (2.3).
8. **Nostalgic** is read as "hold one more reel".
9. **Suspicious Bifocals** lose the enemy health bars, as the list's text does not name them.
10. **Display names** follow the list: Matinee Pass → Haggler's Hat, Ticket Stub Book → Coupon Booklet,
    Crystal Cane Topper → Brass Cane Topper, Incense Sticks → Knitting Needles.
11. **Offered only where rules post** applies to rules and memory passives, not the Megaphone.

## 8. Testing

- Headless tests for every item's rule, every new system (actives, pets, guards, sets, potions, icons,
  rules hooks), the pools (counts, sources, gating), and the old-save and checkpoint migration.
- The full loop (`tools/smoke.ps1`) passes after the switch-over, and keeps every new block, heal and
  payout quiet while it counts.
- An income check (`tools/probes/income_probe.gd`) with the money items before the user plays.
- One heavy Godot job at a time, and never while the user plays. Every Godot run (tests, the full loop,
  probes, a windowed look) happens in a renamed `git archive` copy, so nothing writes into the real user
  folder; the export build and starting the exe are left to the user.
