# Night report, 2026-11-04

All five steps of the third floor are built on `third-floor`, tested and pushed at `0bdcf25`. Nobody has played floor 3 yet. Neither `second-floor` nor `third-floor` is merged; that waits until you have played them.

## How to play it

Your play copy is already on this build and its cache is rebuilt:

```
& "D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "C:\GameDev\game\.worktrees\check"
```

Beat either floor-2 boss, take the stairs, and the Floor 3 landing leads to a third Crossroads. The Funeral Parlour (west) is open. The Golden Years Mall (east) is chained until you beat a floor-3 boss once. Beating a floor-3 boss ends the run with "FLOOR CLEARED".

## What was built

1. **Dentures and chests** (you have played this): the teeth throw, Denture Adhesive, and the five chest types including the Mimic.
2. **The connection and the Arcade Room.** The Arcade rolls on about 1 floor in 4 and has a die on its door. The Dealer stands inside with a slot machine (3 pulls), blackjack and draw poker (one hand each per visit).
3. **The Eternal Rest Funeral Parlour.**
   - Hazard: organ pipes push with a ring that does no damage.
   - Enemies: Mourners in packs, the Florist and the Pallbearers, plus two returning enemies.
   - Mini boss: the Reverend.
   - Floor boss: Mortimer Grimsby.
   - 33 rooms.
4. **The Golden Years Mall.**
   - Hazard: escalator strips, some of which reverse after a chime.
   - Enemies: Mall Walkers, the Mall Cop and the Perfume Sprayer, plus two returning enemies.
   - Mini boss: Gloria.
   - Floor boss: the Mall Santa.
   - 33 rooms.
5. **Balance pass and independent review.**

## What was checked

- **Tests:** 937, 0 failed, on the final code.
- **Full loop:** 3 of 3 passes on the final code, about 388 s each. Each one clears all six paths, checks that the Mall refuses before a floor-3 clear, opens every chest type, plays each Arcade game and throws the dentures.
- **Real windows:** every new attack was seen in a screenshot, with 93 shots in total.
- **Your save:** unchanged by all of this.
- **Independent review:** no critical or important bugs. Its four minor findings are all fixed:
  1. Mortimer and the Santa started wedged between pews or fountains in one of their two rooms. Those rooms now have space around the boss, and a new test checks every boss room.
  2. Mall Walkers walking back to their loop, and the second Pallbearer, now route around props instead of grinding into them.
  3. Perfume clouds, wet patches, dropped coffins, presents and the closing ring are cleared when you leave a room.
  4. Escalator strips no longer push a charging enemy off its warned lane.

## Fixed during testing

- The card-table overlay let the room's labels show through. It now has a solid backing.
- On the Mall's white tile the HUD pills were hard to read, so the top row now has a faint dark band. You will see it on every floor.
- The perfume cloud and the wet floor were nearly invisible on the Mall tile, so both have stronger colours there.
- Mortimer's organ crescendo had one safe spot among about 16 red rings, too hard to find in time. The safe spot now has a green ring.

## Balance (simulated player, rough)

- **Floor bosses:** Mortimer and the Mall Santa are clearly harder than Matron and Old Smokey, but a strong save beats them.
- **Gloria:** about as hard as Foreman Klaus.
- **The Reverend:** lasts as long as Klaus but lands fewer hits. The bot dodges his lines easily, so he needs your judgement.
- **The Furnace Works' regular rooms are easier now.** The bot reached its boss 14 times in 20, against 3 in 15 before.
- **Income per full clear:** about 258 in the Parlour and about 271 in the Mall, against about 231 on Sunset Shores.
- **Spec changes made during balance** (all recorded in the plan):
  - The Santa's closing ring costs 1 pill instead of 2.
  - Some summon timers changed.

## Decisions waiting for you

1. **Blackjack pays back about 94%,** not the 90% we aimed for. That's what the rules we agreed give. To make it tighter, pay a blackjack 2× instead of 2.5×, or have pushes lose.
2. **The Mall's rooms reuse the Funeral Parlour's room shapes,** turned into planters, fountains, carts and escalators. It has its own look, props and enemies. If it feels too samey, giving it its own layouts is a contained job.
3. **The Reverend** may need to be harder.
4. **The Santa's closing ring:** is it fair to escape?

## What to try first

- Walk from floor 2 into floor 3, and play the Arcade if it rolls.
- Fight Mortimer: the Casket slam (3 pills) and the green safe spot during the crescendo.
- After a floor-3 clear, the Mall: the escalators, the perfume haze, and the Santa's sleigh and ring.
- Check the HUD band on the older floors.

## Housekeeping

- **Drive C: was full** in the night: 0 bytes free. The game work wasn't the cause; my temporary files were about 150 MB, and I deleted my old test copies. C: now has about 150 MB free.
  - The largest folders I saw were NVIDIA in `AppData\Local`, about 12 GB, and Windows' hibernation file, about 13 GB. I didn't touch either.
- **`D:\grandpa-verify-tmp`** holds only three small logs. A safety check blocked its deletion, so please delete it yourself.
