# Room Rules and Flashbacks: Design

**Date:** 2026-11-09
**Status:** approved by the user on 2026-11-09. Plan: docs/superpowers/plans/2026-11-09-rules-and-flashbacks.md.
**Goal:** give the game a mechanical hook that comes from its theme. Grumpy old Harold, stuck in the afterlife's bureaucracy, decides whether to follow its rules. Following them earns him a moment of his youth.

**One-line pitch:** *Obey the afterlife's petty rules to relive your youth, or break them and deal with the Auditor.*

## 1. The loop

1. Some combat rooms post a **rule**, for example "NO HORSEPLAY".
2. **Obey it** for the whole fight and you earn a **film reel**: a memory from Harold's life.
3. **Break it** and the **Auditor** comes for you: a tough inspector who is worth beating.
4. Use a reel at a room's door to **relive that memory** for the whole next room, as a younger Harold with a different moveset.
5. When that room is cleared, Harold is old again, grumbling: *"Those were the days."*

Old Harold is the baseline and the game's identity. Youth is a short, earned treat. The endings are unchanged.

## 2. Room rules

### 2.1 The rules
Every rule forbids an action Harold already has. Harold has no run or sprint.

| Rule (sign text) | Pictogram | Forbids | Counts as broken when |
|---|---|---|---|
| LEAVE CANES AT RECEPTION | a cane, crossed out | the cane attack | a cane swing starts |
| NO HORSEPLAY | a figure jumping, crossed out | the dodge | a dodge starts |
| KEEP YOUR TEETH IN | dentures, crossed out | the denture throw | the teeth leave his mouth |
| NO EXPLOSIVES | a thermos bomb, crossed out | bombs | a bomb is placed |
| NO FOOD OR DRINK | a cup, crossed out | the potion | a potion is drunk |
| DO NOT TOUCH THE EXHIBITS | a hand over a vase, crossed out | breaking props, crates and blocks | Harold breaks one, by any means |
| NO LOITERING | a figure with a clock | standing still | his feet don't move for 2.5 s while enemies remain |

**Choosing a rule:**
- A rule is only chosen if it can matter in that room: Exhibits only where there are breakables, Explosives only if Harold has a bomb, Food or Drink only if he has a potion.
- Otherwise the pick is weighted at random from the floor's seed, so a run replays the same.
- The crossing-out stroke is always a single diagonal slash in a circle; there is never a cross shape (the no-religious-imagery rule).

### 2.2 How often
Only rooms **with enemies** get a rule. Loot, shop, treasure, item, healing, secret and vault rooms never do.

| Floor depth | Rule rooms |
|---|---|
| 1 | exactly 1 combat room |
| 2 | exactly 2 combat rooms |
| 3 and deeper | about 1 in every 2–3 combat rooms (40% of them, at least 2) |

- Boss and mini-boss rooms **never** get a rule: they are already the floor's big moment.
- The prototype applies this to floor 1 only (see §6).

### 2.3 Readability
1. **The announcement:**
   - On Harold's **first** entry into a rule room, a stamped notice drops onto the centre of the screen, with the stamp sound: the pictogram large, the rule's words under it.
   - It stays for about 1.5 s while the room's enemies hold still, then shrinks into a **rule icon** in the HUD (top right, under the minimap).
2. **The icon** stays while the room has enemies. It **pulses** when Harold is about to break the rule:
   - while the button is held;
   - while a dodge is buffered;
   - during the last second of the 2.5 s before loitering counts.
3. **A broken rule:**
   - a red **VIOLATION** stamp over the icon, and a whistle;
   - the icon turns grey;
   - the Auditor is on his way (§3).
4. **Room cleared:**
   - If the rule was kept: a green **GOOD CONDUCT** stamp, and a film reel drops (§4.1).
   - If the rule was broken: **REGULATION LIFTED**.
   - Either way the icon goes.
5. **Coming back:**
   - Leaving and re-entering a room whose fight isn't done shows no announcement, only the icon.
   - A cleared room has no rule.
   - Its state (kept, broken or cleared) belongs to the room for the rest of the floor.

### 2.4 Settings and accessibility
- The announcement can't be turned off, but it is short.
- Its text goes through `tr()`, like all text.
- The icon's pulse never uses the warning red (#e4524f) or the safe-spot mint (#7fe0a0).

## 3. The Auditor

- **Arrival:** the first time a room's rule is broken, a whistle blows. **2 s** later the Auditor walks in through the door Harold came in by, with a stamped "AUDIT" door flash. There is **at most one Auditor per room**; breaking the rule again changes nothing.
- **Look:** a tall grey official with a clipboard and a huge rubber stamp. New PixelLab art in the depth style:
  - idle, walk, windup and attack anims;
  - clearly not one of the floor's own staff;
  - **no religious imagery**.
- **Strength:** a mini-elite, tougher than any regular and weaker than a mini-boss. His health and damage scale with floor depth, using the same depth multiplier as other enemies.
- **Attacks:**
  - a **clipboard swing**, a close melee arc with a windup pose;
  - a thrown **"FINED" stamp**, a slow projectile that leaves a short-lived ink blot slowing Harold.
  - Both follow the Attack-warnings setting like other enemies: a windup flash and a faint cue when warnings are off.
- **Reward when beaten:** a generous pension drop (about 3× a regular's) plus a **25%** chance of an item from the floor's item pool.
- **Room clear:** the room isn't clear until the Auditor is beaten as well.
- **The bot:** treats the Auditor like any enemy.

## 4. Flashbacks

### 4.1 Reels
- **Earning one:** keeping a rule through a room's whole fight drops a **film reel** pickup where the last enemy fell.
- **What it holds:** each reel holds a **specific memory**, shown when picked up as a notice ("Reel: Football on the Rec, 1960"). It is picked at random from the **unlocked eras**, by the floor's seed.
- **One at a time:** Harold can hold **one** reel. Its icon sits in the HUD by the potion slot. Earning a reel while holding one shows "Already holding a memory" and the new reel fades, so it is wasted on purpose: it rewards using reels.
- **Death:** reels don't carry over between runs. A run that ends loses its held reel.

### 4.2 Using a reel
- **The button:** a new action, **flashback**: **F** on the keyboard, **Y** on a controller, rebindable like the others.
- **When it works:** only while Harold stands in a **doorway trigger leading into a room whose fight hasn't started**: any combat room, mini-boss room or **boss room**. Anywhere else the button does nothing, and the reel icon shows a small "use at a door" hint the first time it's pressed in the wrong place.
- **What it does:**
  - a sepia flicker (about 0.6 s, the cinema screen's film look);
  - Harold enters the room as the reel's era;
  - the reel is spent.
- **How long it lasts:** **the whole of that room**, until its fight is cleared.
  - Leaving the room mid-fight keeps the flashback until he returns and clears it.
  - If Harold dies during it, the run ends as normal.
- **The end:** when the room clears, a sepia flicker and a short line from old Harold, picked from a few such as "Those were the days." and "My knees remember that."
- **Health is shared:** a flashback neither heals nor adds health.
- **Items still apply:** every stat item keeps working. Items that change the cane or the dentures don't apply to an era's own moves (§4.3 decides per item group).
- **Rules still apply:** a rule room entered in a flashback still has its rule, mapped onto the era's moves. The kick is the cane button and counts as the attack; the bouncing throw counts as the throw.

### 4.3 The two prototype eras
Each era uses the **same buttons** as old Harold, so there is nothing new to learn.

| | **Football on the Rec, 1960 (age 18)** | **The No. 12 Bus, 1975 (age 40)** |
|---|---|---|
| Feel | quick and light | solid and powerful |
| Move speed | ×1.45 of old Harold | ×1.15 |
| Attack (cane button) | a fast 3-kick combo, short reach, lighter hits | a heavy ticket-punch, longer windup, strong knockback |
| Dodge | a **spin turn**: a quick spin that hits whoever he passes through | a **shoulder barge**: a short forward charge that knocks enemies down |
| Throw (dentures button) | a **football** that bounces off walls up to 3 times and comes to rest; he must pick it up again | a **roll of bus tickets** that unspools into a short line that hurts enemies crossing it |
| Bomb and potion | the same as old Harold | the same as old Harold |

- **Damage balance:** each era's damage per second over a room should land within ±15% of old Harold's at the same point in the game. They play differently, not better. The bot measures this.
- **Items that change old Harold's own moves** (cane upgrades, Denture Adhesive and so on) don't apply to an era's moves. Stat items (damage, speed, health and so on) do.
- **Art:** each era is a new character in the depth style, sized like Harold:
  - idle, walk, attack, dodge and throw anims;
  - a football and a ticket-roll projectile;
  - Harold's hats and cosmetics don't apply in a flashback; it's the past.

### 4.4 Unlocking eras
- **Unlocked from the start:** Football on the Rec and The No. 12 Bus.
- **Unlocked by endings:** each **ending** found unlocks one more era, permanently, saved in the profile. The eras after the prototype are a later spec; the life story offers the Allotment, the Wedding, the Seaside, the First Car and so on.
- **The case file** gets a "Memories" page listing unlocked eras and how many locked ones remain.
- **Nothing de-ages Harold between runs.** He always starts each run at 80.

## 5. Save data
- **New profile fields:**
  - `eras_unlocked: Array[String]` (default: the two prototype eras);
  - `rules_kept` and `rules_broken` counts, for the case file and later achievements.
- **New run fields:**
  - `held_reel: String` (an era id, or "");
  - each room's rule state, for a checkpoint resumed mid-floor.
- **Old saves:** they load with the defaults; save migration only adds keys.
- **Writes:** saving stays atomic, with a `.bak` copy, as now.

## 6. Prototype scope (first build)
- **Rules and the Auditor:** on **floor 1 only**, following the depth table above (exactly one rule room).
- **Eras:** the two eras, earned from that rule room and usable anywhere after it in the run, including later floors and bosses.
- **Dev shortcut:** a DEV key gives a reel at once, for testing.
- **Later (not in this build):**
  - rules on floor 2 and deeper;
  - unlocking eras through endings;
  - the Memories page;
  - rule stacking.
- **The goal is a test with real players.** Questions for them:
  - Do they read the rule?
  - Do they choose to break it?
  - Do they get excited about the reel?
  - Does playing young feel good?

## 7. Testing
- **Tests:**
  - rule selection and frequency;
  - the readiness checks per rule;
  - the break detectors for each action;
  - one Auditor per room, and the room not clearing until he is beaten;
  - holding one reel, and a wasted second reel;
  - using a reel only at a fight-not-started door;
  - the flashback ending on clear;
  - shared health;
  - the save fields and migration;
  - no cross shapes in the new pictograms (a pixel check against a plus-shaped pattern).
- **The bot:**
  - takes reels and uses them at the next door;
  - plays eras with the same aim logic;
  - one batch compares era damage per second against old Harold's, aiming for ±15%.
- **Screenshots:**
  - the announcement;
  - the icon pulsing;
  - VIOLATION and the Auditor's arrival;
  - GOOD CONDUCT and the reel drop;
  - using a reel at a door;
  - each era's attack, dodge and throw;
  - the return to old Harold.

## 8. Out of scope
- the complaint / grievance meter (dropped);
- a "run" or sprint move for old Harold;
- permanent de-aging;
- changes to the endings.
