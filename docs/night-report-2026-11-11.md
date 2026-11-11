# Night report, 11 November 2026: playtest-9

**The build is ready: `D:\Grandpa-playtest-9.zip`** (93 MB, build `0c234a7`, tagged `playtest-9`).
It holds the new item list, your three choices from the review (first ten minutes, the hook on every
floor, Harold's animations) and the new soundtrack.

It passed every automated check, but **no person has played it**. Play it yourself for 15 minutes
before you send it. If something looks wrong, `D:\Grandpa-playtest-8.zip` is the safe fallback (the
old items, the new music, none of last night's work).

## How it was tested

- **Tests:** 2,699 passed, 0 failed, on the exact commit that was built.
- **Full loop:** the bot cleared all ten paths and the Waiting Room, counting damage, Pension and pills
  exactly. It passed on the merged game and again after the last fixes.
- **The exported game:** a renamed copy of the export started by itself and walked title, opening,
  lobby and the first room. Inside the exported game it confirmed 107 items all with icons, 10 pets all
  with sprites, 7 potions, 11 sets, all four eras and old Harold with every animation strip, and all 24
  songs loading. Screenshots are in `D:\grandpa-playtest-9-build\verify\`.
- **Reviews:** every task had its own reviewer, and the most capable model reviewed the whole merged
  build at the end. Its verdict was "ship with the listed fixes"; the one must-fix was fixed.
- **Your save:** untouched (same checksum before and after; nothing in the user folder changed).

Not done, because I do not run the real exe: the zip's own `Grandpa.exe` has not been started. The
title screen's corner should read `build 0c234a7 (2026-11-11)`.

## Before you send it: 15 minutes

Your own save hides two things testers will see, so use an empty slot:

1. **New Game on an empty slot.** Your existing save has every control tip marked done.
2. **Options: turn Attack warnings on.** Your settings file already stores "off"; new players get "on".

Then look at these, which only eyes can judge:

- **The tip line** at the bottom centre. Does it ever sit on a shop label, a pickup name or text near
  the bottom wall?
- **The first rule room** (within your first three fights) and your first film reel.
- **The two new eras** when a reel gives you one: the 1962 dancer's spin jumps to a back view on its
  first frame; the 1988 gardener's spade pulls back in reverse after the thrust, and his dodge hovers
  2 pixels off the floor at the end.
- **Old Harold's new animations:** the hurt flinch is small; the dodge holds the cane level and snaps
  it upright; his hat and sunglasses vanish during hurt, dodge and death and come back after.
- **Pets:** the moth reads more like a martini glass than a moth.
- **The music level.** The new songs are about 5 dB quieter than the old soundtrack (the Waiting Room
  about 9 dB). If it sits too far behind the sound effects, tell me and I will raise it.
- **Potion names in the HUD:** the new ones are short ("Brew", "Slip", "Salt", "Flip", "Pets", "Nip").
  "Nip" (Dutch Courage) and "Pets" (Pet Food) are weak.

## What is in the build

- **Items:** the approved list, word for word: 107 pool items (89 passives, 10 pets, 8 actives),
  7 run potions and 11 set bonuses. The 48 old items are out of every pool. All have icons.
- **New systems:** an active item used with R (pad B) that recharges by rooms cleared; pets that
  follow Harold; sets formed by three items of one build; potions with lasting effects.
- **First ten minutes:** control tips during a new save's first run; attack warnings on by default;
  the opening skips with one press. Floor 1 is exactly as hard as before.
- **The hook everywhere:** rules post on every floor; on a first run the first rule room is one of
  the first three fights; four eras in all (football 1960, the Dance Hall 1962, the bus 1975, the
  Allotment 1988); the Auditor rests less between attacks on deeper floors.
- **Harold:** hurt, death and dodge animations, for old Harold, his three cardigan outfits and the eras.
- **Music:** all 24 songs from the new renderer. The floor tracks are the action set; the title,
  landings, arcade, bosses and endings are still from the set you called "weird / forced".
- **Old saves:** a save or mid-run checkpoint from an earlier build loads. Renamed items carry over,
  retired ones are dropped, and a crafted item whose recipe was retired is refunded once.

## Balance and text notes

Nothing here was changed; each follows the plan or the approved list. They are for you to judge in play.

- **The spade (Allotment 1988) may be the strongest era.** The bot read it about +33% over old Harold,
  but its number did not move when damage or recovery time changed, so the real edge is unknown
  (somewhere from +10% to +35%). The spin reads +16%, football +19%, the bus +26%.
- **Compound Interest feeds itself:** its payout earns interest again at the next floor, roughly
  doubling a run's Pension over five floors if nothing is spent.
- **Rules items scale with no cap:** Model Citizen's Badge (6% per rule kept), Repeat Offender and
  Scrapbook. With rules on every floor a full run has about nine rule rooms, so about +54% at most.
- **Two of the same potion stack:** two Dutch Courages give 2.56 times damage and 4 times damage taken.
- **Starting items are uneven by build:** slip 7, bite 6, pets 6, pension 5, rules 5, any 5, dodge 3,
  pills 3, cane 2, risk 2, thermos 2, memory 1. A new player cannot form the Cane, Risk, Thermos or
  Memory set until they unlock more.
- **Text that differs slightly from behaviour:**
  - Glass Hip says "every hit costs one more half pill"; it takes one whole pill on every second hit.
  - Last Orders spares bosses, but its text no longer says so.
  - Gold Top Milk pays for Slips and Thermoses only up to the scaling cap of 20, though it says "every".
  - Pet Food says "twice as hard"; two of them give four times.
- **Small behaviours:** the Megaphone spends its charge with nobody in its cone; reloading a save
  before using the Lottery Scratcher rerolls its prize.

## Decisions I made without you

- **The two new eras:** the Dance Hall 1962 (spin) and the Allotment 1988 (spade), from his life story.
- **Two and at times three test streams ran at once**, against your one-heavy-job rule, so the night
  could finish. Each ran in its own renamed copy.
- **Pet sprites:** the plan left pets as coloured circles. I generated ten small sprites (26
  generations, from the unspent part of the item-icon allowance) and the stray cat reuses the cat.
- **Art spend:** 42 generations for Harold and the eras (of the 300 you approved), 26 for the pets.
- **Three old potions keep their HUD names** (Tonic, Small, Swift). An agent had shortened them too.
- **The half-pill heal bonus and two tip rules** were built differently from the plan where the plan
  did not meet its own rules; each is noted in the build ledgers.
- **Test-only review findings were parked**, not fixed, where the code itself was confirmed correct.

## Not done

- **Deleting the 48 retired item files** (item plan Task 26). It needs your OK. They sit on disk,
  out of every pool.
- **A test-hardening pass** for the parked findings (thin tests around some items' full-loop guards
  and save round trips). Listed in the item ledger under "PARKED".
- **The full loop no longer plays a rule room through** obeying or breaking it; unit tests cover that.
- **Nothing was merged to main.** `rules-flashbacks` is still waiting for your play of playtest-7.
- **Harold's pickup lines** and the rest of the soundtrack (bosses, title, endings) are still to do.
- **My review's advice stands:** after this build goes out, freeze content until the players'
  feedback is read.

## Where everything is

- **Zip:** `D:\Grandpa-playtest-9.zip`. Build folder: `D:\grandpa-playtest-9-build\`.
- **Branches (all pushed):** `player-build` (everything, the build's source), `new-items`,
  `jukebox-music`. Tag `playtest-9`.
- **Art sheets:** `D:\grandpa-art\icons\items\sheet.html` (item icons),
  `D:\grandpa-art\harold\sheet.html` (Harold and the eras), `D:\grandpa-art\pets\sheet.html` (pets).
- **Build ledgers** (every task, its review, and every deferred point), in the worktrees:
  `.worktrees\new-items\.superpowers\sdd\2026-11-10-new-item-list\progress.md` and
  `.worktrees\player-build\.superpowers\sdd\2026-11-11-player-build\progress.md`.
- **Plans and specs:** `docs/superpowers/plans/2026-11-10-new-item-list.md` and
  `2026-11-11-player-build.md` on `player-build`, with their specs beside them.
