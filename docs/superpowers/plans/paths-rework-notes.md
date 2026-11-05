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
