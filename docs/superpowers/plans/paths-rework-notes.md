# Paths rework: decisions and notes

The user delegated every decision for the Cinema and Séance build. Each one is logged here with a
short reason. Plan: `2026-11-06-cinema-and-seance-paths.md`. Spec:
`../specs/2026-11-06-cinema-and-seance-paths-design.md`.

## Decisions

- **Build order:** swap the ids first, with the old content running under the new ids, then
  replace each path's content. Every commit stays runnable.
- **Department id:** the Pro Shop's id becomes `crystal_counter`, migrated in `departments_seen`.
  Its upgrades keep their ids (as the six first-clear items do), so `upgrades` in old saves need
  no migration; only their names and text change.
- **Mementos:** the two new entries keep the old perks (one more treasure choice for the
  Projectionist, harder charged swings for Madame Zara), with new memento names, short names and
  perk text themed to them. New perk mechanics would change balance the spec does not ask about.
- **Beaten bosses:** `bosses_beaten` keeps the old boss ids and gains the new ones, so mementos,
  first-kill pay and bounties carry over while the bestiary keeps the old bosses as history.
- **Séance returning pair:** golf had no reaper or notary, so the Séance follows the Cruise
  pattern with the golf path's own returning pair rethemed: `seance_bingo_caller` (a caller on a
  hotline) and `seance_soot_ghost` (a ghost at a séance).
- **Bot:** new hazards answer `threat_at(p, strict)` and `threat_imminent(p)`, read generically by
  the bot, instead of one bot branch per hazard class.
- **Bot baseline:** round-2's tip is `918d343`, this branch's base, so the Mall Santa and Thaddeus
  baselines are measured on an export of `918d343` in the same session as the new bosses.
- **Task 1, the id swap:** the floors, room folders and every list move to the new ids in one
  commit, with the old rooms, enemies and bosses still wired, so the game runs unchanged under the
  new names until Tasks 2 to 5 replace the content.
- **Songs for now:** the music catalog's Mall and golf keys are renamed `flashback_cinema` and
  `seance_hotline` while their tune functions (`places.golden_years_mall`, `places.fairways_end`)
  keep their names, so the old tunes play under the new ids until Task 5 writes the new ones.
- **Code comments about the old content** (sand bunkers, golf props, Mall tiles and the like) stay
  as they are, since that code is retired with its content in Tasks 4 and 5.
- **Crystal Counter:** the Pro Shop's department and merchant ids both become `crystal_counter`
  (the Golf Glove's `merchant` too), and its Waiting Room layout moves to `crystal_counter.tres`;
  its board reads "Crystals" on the old 40x24 board, in violet.
- **The Golf Glove** keeps its id `golf_glove` and its effects, renamed the Charging Crystal, with
  options Full Moon (harder charged swings) and Burning Sage (faster combo), so saved levels and
  form choices need no migration.
- **Esme** speaks with `blip_mystic` at pitch 1.2, so she sounds apart from Madame Murk (1.0), and
  stands where Duffy stood. She has no art yet, so test_npc keeps an `AWAITING_ART` list (`esme`)
  that the art pass empties. Duffy's NpcDef and art folder are deleted; nothing else used them.
- **Ticket line:** Duffy's new-arrival line becomes Esme's, in the same slot.
- **First-clear items' new names:** the Cinema's are the Ticket Stub Book (coupon_booklet, as the
  spec says), the Matinee Pass (hagglers_hat) and the Lucky Seat Ticket (loaded_dice, still
  cursed); the Seance's are the Crystal Cane Topper (brass_topper), Incense Sticks
  (knitting_needles) and Levitation Slippers (hover_round). Ids, effects and drawn looks are
  unchanged, so the item audit can still rename them.
- **Posters and mementos before their bosses:** the bounty files and the two mementos already name
  `crabtree`, `projectionist`, `celestine` and `madame_zara`, while the floor defs still hold the
  Mall's and golf club's bosses. Rather than placeholder EnemyDefs or an alias in game code, the
  tests that match a floor's boss to its poster or memento (test_bounties, test_mementos) read it
  through `tests/support/pending_bosses.gd` (`PendingBosses.BY_OLD`), a test-only map. **Tasks 4
  and 5 delete that file** with the boss swap. Until then a taken poster for a new boss cannot be
  won in play, which only the branch ever sees.
- **Mementos:** the Projectionist hangs the Last reel (one more treasure choice) and Madame Zara the
  Crystal ball (charged swings 15% harder), drawn as a silver film reel and a violet ball on a
  stand. Short names "Projectionist" and "Zara" pass the caption-overlap test.
- **Deputy Dolores** gets a new take line for each of the four new posters, in her usual voice.
- **Poster looks** fountain_tiara and golf_visor (now sold at the Decor Office) keep their names;
  the item audit or Tasks 4 and 5 may retheme them.
