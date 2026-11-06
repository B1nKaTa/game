# Night report: 2026-11-06

**State:** round-2 is at `7fe8e72` and pushed. The `check` play copy is on that commit, with music rendered and assets imported. main is untouched and waits for you to play.

**Verification:**
- 2207 tests, 0 failed.
- Bot loops: 3 integration loops and 2 paths loops, all SMOKE PASS, every path cleared.
- An independent review found no bugs at confidence 80 or above.
- slot_1 save MD5 is unchanged.

## What's new to play

- **The Flashback Cinema** (floor 3, replaces the Mall).
  - Ushers, popcorn vendors, film reels and summoned extras.
  - Mini-boss: **Crabtree** the critic.
  - Boss: **the Projectionist** (reel changes, Lens Beam, splice, a phase-two burn).
  - The screen plays 14 sepia scenes from Harold's life, and 40 life-sign lines turn up once each per run.
- **The Séance Hotline** (floor 4, replaces the golf club).
  - Phone psychics, crystal gazers, poltergeists and ectoplasm.
  - Mini-boss: **Sister Celestine** and her tarot cards.
  - Boss: **Madame Zara** (On the Line tether, Ouija board, possession, séance circle).
- **The Waiting Room.**
  - The Pro Shop is now the **Crystal Counter**, run by Esme.
  - The Back Room opens on the first Cinema clear.
  - New letters, mementos and bounties, and 6 rethemed first-clear items.
  - Two new songs.
- **Art.**
  - Tiles and props for every floor and the Waiting Room.
  - Chests, doors and pickups.
  - All enemies and bosses on the new paths.
  - Crabtree's spinning star and a rolling tumbleweed.
- **Old saves migrate automatically.** Progress on the Mall or golf carries over to the new paths. A run saved mid-floor there restarts that floor on the new path, keeping items, pills and money.

## Decisions I made for you

- The Crystal Counter keeps the Pro Shop's upgrades, renamed. The mementos keep their perks with new names.
- Seat rows only break to blasts and bosses.
- The cinema screen sits on the north wall, clear of the minimap.
- Difficulty targets:
  - The Projectionist wins 3–7 of 20 bot runs, against 0 for the Mall Santa. That is about 22 points above the old boss, just outside the target; I left it there rather than make him harder.
  - Madame Zara wins 2–7 of 20, against 0–2 for the old golf boss. I raised her health to 2300.
- Crabtree was retuned. He started at 3 of 20 and now wins 12–16 of 20, close to Gloria's 16–17.
- The no-flip art flag is called `art_flips` everywhere.
- The new returning enemies on these paths (bingo caller, soot ghost, notary) got their own art, so the older floors' versions stay as they were.
- The notary was redrawn in light grey because the first suit was too dark on the floor.
- These stay drawn in code, because the art made for them didn't fit:
  - the Cinema screen frame;
  - the Séance cubicle partition;
  - the small séance table.

## Known minor issues

- In a large room, a lane warning in the top right can sit under the minimap.
- The Ouija planchette's path can run under the HUD when Harold stands in the south half.
- If you leave the Projectionist's room mid-fight (only possible by teleport), his phase-two burn ring doesn't come back.
- The `escalator_hum` sound is no longer used.

## Waiting on you

1. **Item Audit:** go through the items (https://claude.ai/artifact/Cch2xeENKugYxVpqTtA18F). Item icons start after that.
2. **Play round-2 in check**, then I merge it into main.
3. **Still open from before:**
   - Chairman fight length;
   - a controller button for the case file;
   - cane outfits;
   - the lost_luggage asleep animation.
4. **Leftover test folders you can delete:**
   - `D:\grandpa-verify-*`;
   - `D:\grandpa-music-check`;
   - the matching Grandpa* user-data folders, except `Grandpa` itself.

   Screenshots are in `D:\grandpa-shots-int\` and `D:\grandpa-shots-pr\`.

PixelLab credits left: about 4226.
