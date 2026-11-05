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
- **Retired enemies in the case file:** `enemies_seen` keeps the old ids as history. Any id with no
  EnemyDef (the old bosses once Tasks 4 and 5 delete them) shows after the real cells as a known
  history cell: its count, a name made from its id ("Mall Santa"), a grey placeholder chip, no
  floor, and the detail "No longer found on any floor.". The Log already names kills from ids.
- **Save migration** runs on the raw dict at the top of `ProgressData.from_dict` (after the version
  checks), on a deep copy, so the file on disk changes only on the next ordinary save; the `.bak`
  and atomic writes are untouched. It maps `paths_cleared`, `item_paths_seen`, `letters_read`,
  `path_clears` (summed when both ids are present), `departments_seen`, `bounty_taken` and
  `bounties_retired`; `bosses_beaten` keeps the old ids and gains the new. Idempotent: no old key
  is left for a second pass to map.
- **Not migrated, on purpose:** `enemies_seen` and the run log's kill and met lists keep the old
  ids as history, and the run log's `floor` and `killer` are display text of what happened, so an
  old run still reads "Fairway's End Golf Club at Midnight (floor 4)". Endings, cosmetics, upgrades
  and form choices store no path, boss or department id that changed.
- **Seeding the Bestiary:** a save with no `enemies_seen` yet is seeded from `bosses_beaten`
  before the new boss ids join it, so a migrated save never counts the Projectionist as met.
- **Checkpoint migration** runs in `RunCheckpoint._read_file`, so every reader of run.json (resume,
  abandon, the slot summary) sees the migrated run. A run that stood on a retired path gets the new
  floor path and `restart_floor: true`; `FloorScene._resume_map` rebuilds the new floor from the
  same seed and `RunCheckpoint.restart_floor` puts Harold in its first room, come in from the
  Crossroads, with nothing visited or cleared. Items, pills, keys, Thermoses, potion, Pension and
  run earnings are the checkpoint's own. The route (`ending.paths`) is mapped too. A per-floor item
  state is restored as saved rather than reset, as any resume does.

## Task 3: the Cinema's look, props, screen, life signs and rooms

- **Palette:** a deep teal carpet (0.09, 0.32, 0.33) in three close tones, dark indigo panels
  (0.12, 0.07, 0.21) with gold trim, plum velvet seats, a dim violet-grey ambient, warm amber wall
  sconces, a faint cool fill and no scattered lanterns. Nothing large is red; a test keeps every big
  area's hue off red and far from the warning colour, and the walls apart from the Parlour's.
- **Patterns 14:** `CinemaLook.CARPET` lays two lighter carpet runners edged in thin gold lines along
  the door column and the door row (so they always lead door to door), and faint art-deco fans of
  thin arcs on the rest. No dots, small squares, speckle or dark bands, which are the film strip's
  look (Task 2), and no bright diagonals, which are the wet floor's. `CinemaLook.DECO_WALL` draws a
  gold rail, fluting, a gold skirting and a gold chevron on every other panel.
- **Decor:** only cobwebs and potted palms are scattered, thinly (density 0.03); the aisle lights are
  placed by rule with the seat rows, not scattered.
- **Seat rows (`-`):** each cell is a `CinemaSeat`, a `RockBlock`: solid on the wall layer, so it stops
  walkers and every shot, breaks only to blasts and bosses (as a chapel pew), and hides a coin at the
  furniture rate. Breakable rather than wall-like, so a boss's charge and a Thermos can open cover, as
  on every earlier floor; `WALLS_AND_BOMB_ONLY` keeps every needed route free of them. Neighbouring
  cells join into one long row when drawn.
- **Pillars (`|`):** a `CinemaPillar` is a plain `StaticBody2D` on the wall layer, never broken, not
  even by a boss, and in `WALLS`, so no route may need one. Charges stop at it.
- **Aisle lights:** placed by rule, not by symbol: the plain floor cell past each open end of a seat
  row gets a small brass step light with a little warm pool (`AisleLight`, flat at the floor's z), at
  most 8 to a room, spread evenly, none touching a door. So every layout lights its own aisles.
- **Symbols:** `-` and `|` because every letter but `i` and every digit is taken; `i` is kept for the
  life signs. Both are appended with `+ "-|"` to `ALLOWED`, `SOLID_SYMBOLS`, `WALLS_AND_BOMB_ONLY`,
  and `|` to `WALLS`, as lesson 131 asks.
- **The screen's wall:** the north wall is a single cell, and in medium and large rooms it sits under
  the HUD's top band, so every Cinema fighting and boss room keeps its second row as wall too, except
  the north door's cell, which becomes a one-cell alcove. That gives a 64 px screen wall whose lower
  half is always clear of the HUD. `CinemaScreen.wall_rect` falls back to the single wall row (and a
  shrunk picture) for a layout without it.
- **Where the screen hangs:** west of the north door's alcove, always, centred on that stretch of
  wall, since the door is in the middle of every wall and the small map covers the top right of the
  view. The rest of that stretch is velvet drapes; the stretch east of the door is plain deco wall.
- **Frame size for the art:** each scene frame is **160x56 px**, shown at 1:1, and a scene file
  `res://art/cinema/scenes/<id>.png` is a horizontal strip of **3 frames** (480x56; 2 frames, 320x56,
  also works), small changes of one still. The screen adds sepia, grain, scratches, flicker, gate
  hops and a vignette itself. Until a file exists, `CinemaScenes.placeholder_image` paints a sepia
  gradient, Harold's silhouette with his cane and one simple prop per scene.
- **Scenes:** 14 (the spec's 11 plus the prize marrow, a fishing trip and the tandem). A room's scene
  is `CinemaScenes.pick(decor_seed)`; `CinemaScenes.assign(map)` takes screen rooms in id order and
  steps to the next scene when a room through any door already shows it, so neighbours never match.
- **The beam:** a faint additive wedge (`CinemaBeam`, z -7, alpha 0.16 at the port to 0.05 at the
  screen) straight up from a port in the south wall below the picture, with 18 slow dust motes, and
  no light of its own, so bodies are never lit or hidden by it. It goes out while the screen is cut
  to black. The screen itself is drawn unshaded and gives a cool glow light below the picture.
- **The Projectionist's API** (Task 4): `CinemaScreen.in_room(room_view)` finds the screen;
  `cut_to_black(seconds)`, `flash(strength = 1.0)`, `set_burning(progress 0..1)`, `burning()`,
  `is_dark()`, `darkness()` and `picture_rect()` (global) drive and read it.
- **Life signs as a layout symbol:** `i` is a lobby card on an easel (`LifeSign`), a decor symbol that
  blocks nothing and breaks to nothing, kept off the cells touching a door (`validate()`). A symbol
  rather than a placement rule, so each card stands where the layout leaves it room, and the floor
  test checks every one of the 33 rooms holds exactly one.
- **Showing a line:** within 46 px of his feet the card shows its line in a speech-bubble card (the
  NPC bubble's colours and `Npc.bubble_box`, so it hangs below the card instead of reaching into the
  HUD band and stays inside the screen's sides), wrapped to 220 px; it hides past 62 px. Nothing
  pauses. The card picks its line the first time it shows and keeps it while the room lasts.
- **The run's seed:** a run has no single seed, so the lines are ordered by the seed the Cinema floor
  was built from (`RunState.seeds[-1]`, kept by the checkpoint). The order is a per-line hash of that
  seed, so a line keeps its place however many others are seen meanwhile.
- **Saved lines:** `ProgressData.life_signs_seen` maps a line id to a stamp, one more than the latest
  so far, written the moment a line first shows (`Progress.take_life_sign` saves at once). Lines not
  in the save come first, then seen ones oldest stamp first, so when all 40 are seen a run starts with
  those seen longest ago; within a run no line repeats, and the 41st card would stay blank. An older
  save without the key loads with none seen.
- **Checkpoint:** cheap, so the run's shown lines ride in the checkpoint's tally (`life_signs`), and a
  resumed run never repeats one. An older checkpoint starts with none shown.
- **The 40 lines:** the spec's three word for word, ten about Gerald, eight about Biscuit, nine about
  the depot and ten small wins and failures; none mention an ending or his house.
- **The 33 layouts:** the same file names, types, sizes and mix as the Mall's, drawn from its shapes:
  planters and fountains became seat rows, the corner walls of `combat_04` and `combat_large_03`
  became pillar boxes, a few pillars were added, and the strips, carts, gumball machines and sale
  signs are gone, so the Cinema lays no hazard in its floor. The 17 fighting and boss rooms were
  redrawn round the screen wall (their row-1 enemies moved down, from the legal-cell maps); the other
  16 kept their shapes. Seat rows and pillars never lie on the two carpet runners, so a clear aisle
  always runs door to door. Chests stand in four fighting rooms. Every boss cell has its 3x3 clear, so
  the Projectionist (44x52) and Crabtree (32x40) fit as well as the Mall's bosses now holding them.
- **Tests moved:** the Mall's layout, room-mix and whole-floor tests now live in `test_cinema_floor.gd`
  against the new rooms; `test_mall_floor.gd` keeps only the Mall's enemies, bosses, decor kinds and
  props, for Task 4 to retire with them.
