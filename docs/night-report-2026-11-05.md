# Night report, 2026-11-05

Everything from tonight is merged on `integration` and pushed:

- floors 4 and 5;
- the title menu, options, save slots and run checkpoint;
- controller support;
- sound effects and music;
- the 11 endings;
- all 100 items and 12 combos.

It is tested, and three full loops pass. Nobody has played the merged build yet.

## How to play it

This build is the `integration` branch (see the last commit in the git log; this report is part of it). I did not touch your play copy, `C:\GameDev\game\.worktrees\check`. To play this build, put that worktree on `integration` first. Then launch it as usual:

```
& "D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "C:\GameDev\game\.worktrees\check"
```

- **The first launch copies your save into slot 1 and keeps the original** where it was. It copies once, and a later launch never copies it again.
- **Dev keys:**
  - F3, F5 and F6 start a run on floor 3, 4 or 5 with every upgrade maxed.
  - F4 opens the dev Waiting Room with every department open.
- **Music:** the songs are rendered files that git doesn't keep. If the play copy has no `audio/music/`, render them with `py tools/music/render.py audio/music`, which takes about 2 minutes.

## What was built

1. **Floors 4 and 5.**
   - Four paths: the Last Resort Cruise, Fairway's End, Terminal Zero and Head Office.
   - Each path has its own mini boss and floor boss, so 8 bosses in all.
   - Each path has its own hazards and enemies.
2. **The title menu.**
   - Options with Video, Audio, Game and Input tabs.
   - Three save slots.
   - A run checkpoint: Save and Quit mid-run, and Resume later from the slot.
3. **Controller support.**
   - Every menu and panel works with a pad, and B always backs out.
   - Prompts name the pad's buttons, Xbox or PlayStation. A DualSense is detected as PlayStation.
   - Rumble.
   - The run pauses if the pad is unplugged.
4. **Music.** 25 tracks and a music player that changes with the room, the boss, the endings and the title.
5. **About 99 sound effects** for combat, pickups, rooms, the Arcade, menus and NPC voices.
6. **11 endings.**
   - Each is a short scene, chosen by how the run went.
   - The Ending Archive in the Executive Suite replays the ones you have found.
   - Gerald.
7. **100 items and 12 combos.**
   - Rarity: common, rare, legendary. There are 7 cursed items.
   - 40 items are open from the start. 30 come from first clears, 18 from recipes and 12 from bounties.
   - A banner shows when a combo forms.

## What was checked

- **Tests:** 1927, 0 failed, on the final code.
- **Full loop:** 3 of 3 passes in parallel, at 609, 610 and 617 s. Each one:
  - clears all ten paths;
  - resumes a checkpoint mid-floor and at the first Crossroads;
  - plays with a pad (now also opening the big map with View and closing it with B);
  - checks the endings.
- **Real-window screenshots:**
  - the title screen;
  - the Lobby;
  - a run's HUD;
  - a shop with a legendary item (gold) and a cursed one (purple, with the skull);
  - the Mobility Scooter's combo banner;
  - the big map with the Floor Plan and the Fortune Teller's boss tags;
  - the Ending Archive with the pad's gold focus.

  Nothing was broken by the merge.
- **Save safety:** a review of the save code found nine problems, and all nine are fixed. The main ones:
  - The copy into slot 1 happens once, and is safe to kill and retry.
  - New slots make their folder before the first save.
  - A resumed run puts the checkpoint's Pension back, so coins are never paid twice.
  - A checkpoint is written at the first Crossroads.
  - A broken checkpoint is deleted.
  - Script runs never touch the save.
- **Fixed in tonight's merge:**
  - **Resuming a run no longer repeats an item's pickup effect.** Before, the Inheritance Letter's 60 Pension and the Second Thermos Strap's Thermoses paid again.
  - **Resuming also keeps each item's state.** Examples are the Eternal Warranty's once-a-run save, the Expired Coupon's lost pills and free shop, the Bureaucrat's Stamp's recharge, and the per-floor Bubble Wrap and Second Opinion.
  - **Sounds for the newer items' key moments.** These include a stamp for the stamps, coins for the money items, a heal for the Harmonica and Family Visit, a shield block for the Lawyer's objection, and a card flip for the Fortune Teller.
- **Your save:** the MD5s of `save.json` and `save.json.bak` were the same before and after every Godot run:
  - `save.json`: `f4a62baf2984c99a2fc54ebd6dc1e308`
  - `save.json.bak`: `ec5412ad4aa142699213a24ad7563c92`
- **Seen in a screenshot, from before the merges:** on floor 1's `combat_02`, a recipe's label on the top-left cell runs under the HUD's item line and past the room's edge.

## Balance (simulated player, rough)

- **The cruise is still a wall for the bot.** It reached the cruise's floor boss, the Commodore, about 11 times in 60. Terminal Zero improved to about 26 in 60. Most runs die in regular rooms.
- **Augustine and the Chairman are easy for the bot.** It beats them nearly every time, because their attacks are shown in full and it reads them perfectly. You need to judge them in play.
- **Income per full clear:** about 420 on floor 4 and about 550 on floor 5.
- **Item income:** each money item adds roughly a tenth to a full run.

## Decisions waiting for you

1. **Nitroglycerin Tablets' drawback.** It is the cursed item, but its blast on a big hit hurts enemies, not him. That makes the drawback mostly an upside. Make the blast hurt him too, or give it another cost?
2. **Fortune and Glory needs 2500 Pension earned in one run.** Full-loop runs carrying many items already reach about 2700, so it is too easy. I suggest about 3500.
3. **Floor-5 boss design.** If Augustine and the Chairman feel easy to you too, the fix is in their design, such as overlapping attacks or the takeover up close, not their numbers.
4. **The cruise's difficulty.** If it is a wall for you too, the levers are Lorraine, the shared Night Stoker and orderly, or the cap on each enemy kind per room.
5. **Thaddeus's sprinkler after a sand spread.** Sand takes the dodge away while the sprinkler follows Grandpa round. Is that fair?
6. **Floor-3 drift.** Mortimer and the Santa measure harder on this build than their recorded numbers. Retune them, or accept it?
7. **The credits name.** They say "A game by Stanislav Zlatkov". Keep it, or use another name or studio?
8. **Fullscreen by default.** Is it on for a first launch, or should the game start in a window?

## What to try first

- **Resume:** Save and Quit mid-run from the pause menu, then Resume from the slot. Check that your items, Pension and Thermoses match.
- **A run with a controller:** the DualSense prompts, rumble, and the big map on the Create (View) button.
- **Floors 4 and 5:** the cruise's roll, the golf club's sand and sprinkler, the terminal's queue barriers, the office's red tape.
- **Ending Archive:** find an ending, then replay it in the Archive.
- **New items:** the Floor Plan and the Fortune Teller's Card on the big map, the Bureaucrat's Stamp, the Eternal Warranty.

## Housekeeping

- **Delete these by hand on D: when you like.** Each is test copies, screenshots or logs, and none is needed:
  - every `D:\grandpa-verify*` folder: `grandpa-verify`, `-bal2`, `-deep`, `-endings`, `-fix`, `-items`, `-items1` to `-items4`, `-logs-wr`, `-menu`, `-music`, `-sfx`, `-tmp` and `-final` (tonight's loop logs; a safety check stopped me from deleting it);
  - the `D:\grandpa-look-*`, `D:\grandpa-shots-wr`, `D:\grandpa-music-samples` and `D:\grandpa-sfx-samples` folders.
- **Leftover Godot user folders** from earlier agents, in `%APPDATA%\Godot\app_userdata\`: every `GrandpaSmoke*` folder (for example `GrandpaSmoke1` to `3`, `GrandpaSmokeA`, `-Bal2A/B`, `-EndA/B/Base`, `-It4A/B`, `-f1` to `3`, `-fin1` to `3`, `-fw1/2` and `-t1` to `-t9b`), every `GrandpaLook*`, `GrandpaLoop*` and `GrandpaVerify*` folder, and `GrandpaFurnaceLook` and `GrandpaStep1Look`. Only `Grandpa` is your real one.
- **`D:\grandpa-git-backup`** is an old backup of the repository. Delete it once you are happy with the pushed branches.
- **`D:\grandpa-save-backups`** holds copies of your save. Keep it until you have played the merged build.
