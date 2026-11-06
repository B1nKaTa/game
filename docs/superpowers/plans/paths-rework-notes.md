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
- **Looked at in a real window** (`tools/probes/cinema_look.gd`, shots in `D:\grandpa-shots-pr\cinema_*.png`):
  the dim teal house keeps every enemy readable, the HUD's band dims the screen's top third in medium
  and large rooms but the HUD stays readable over it, the beam is faint and under the bodies, and
  aisle lights mark every row end. Fixed after looking: a card's line near the top right covered the
  small map, so `LifeSign.bubble_box` hangs it below the card instead.
- **Left for Task 4:** the Mall's props (`ShoppingCart`, `GumballMachine`, `MallPlanter`,
  `MallFountain`, `SaleSign`, the symbols `a z d q e`, their palette fields and room_view branches),
  the escalator strips (`><^v`, `ConveyorStrip`, `strips_reverse`, still read by the Mall Santa,
  Gloria, enemy.gd and player.gd), the Mall's floor and wall pattern 3, `test_mall_floor.gd` and
  `test_mall_hazard.gd`, and `tools/probes/floor3_look.gd` (it still shoots strips in the Cinema's
  rooms, which no longer have any). No layout uses any of them now. The Projectionist reaches the
  screen through `CinemaScreen.in_room(room_view)`.

## Tasks 2 and 4: the Cinema's enemies and bosses

- **Commits fold the wiring and the retiring in:** the case file's test wants every enemy on a floor, so
  each commit that adds the Cinema's enemies or a boss also puts them on the floor and deletes the Mall
  data it leaves on no floor (the regulars with their pair, then Gloria with the Mall Walkers, then the
  Mall Santa with his elves), and the Mall's props, strips and tests go in a commit of their own after.
- **Roles from the Mall's:** the Film Reel takes the Mall Walkers' slot (weight 3, 16 health against
  the Seasonal Temp's 13), the Usher the Mall Cop's (weight 4, the cop's 36 health and charge, as the
  Debt Collector Ghost's role), the Popcorn Vendor the Perfume Sprayer's (weight 3, 30 health, keeps
  110 to 210 px away, as the Filing Clerk's thrower role), then the Intern Reaper (3) and the Notary (2).
- **The Usher:** a torch beam 150 px long and 44 degrees wide, swinging 18 degrees either side of the
  way he walks; 0.6 s of Grandpa in it (with nothing solid between) spots him, and the notice ebbs as
  fast while he is out of it, so stepping out sets it back. Spotted, he says "Shh!", turns the beam
  onto Grandpa and winds up 0.7 s with the lane warned (28 px wide), then charges 240 px at 300 px/s,
  stopping at anything solid, and rests 2.4 s. He patrols to spots 90 px round Grandpa, re-picked every
  2.2 s, so the beam keeps passing near him. The beam (`UsherTorch`) is pale cream, never red, flat on
  the floor under the bodies, and brightens as he takes notice.
- **The Popcorn Vendor:** a 0.5 s windup ("Popcorn!"), then a tub lobbed onto his feet give or take
  24 px; its mark fills for 0.9 s while the striped tub flies in, costs a pill under it (18 px), and
  bursts into 6 kernels at 120 px/s along spokes warned with it. Every 3.4 s. The tub breaks nothing,
  as a regular is no boss.
- **The Film Reel:** rolls 130 px/s along rows and columns only, first toward Grandpa's side; at each
  hit on a wall or seat it rattles 0.45 s with its next 200 px lane warned, then turns 90 degrees to
  Grandpa's side (the other side if that is blocked, back if both are). It hurts by touch only. Its
  film (`FilmTrail`) is a piece 12 px square every 12 px rolled, dark with sprocket holes, slowing him
  by 0.35 for 0.4 s every 0.2 s while his feet are on it, each piece fading 4 s after it was laid.
- **The Extra:** 10 health, 125 px/s, 16x22, grey; a 0.4 s windup and a shove that costs a pill and
  pushes him 200 px/s for 0.16 s (only when it lands, so a dodge passes both). It heckles ("Boo!") as
  it steps in. It is the only summon, Crabtree's.
- **Colours:** Usher violet (0.5, 0.3, 0.8), Vendor popcorn yellow, Reel steel grey, Extra light grey,
  the Intern Reaper pink (art hue 275 to 325) and the Notary sky blue, so no body is red and each is
  told apart on the teal carpet.
- **Placeholder marks** are drawn by `CinemaMarks` (a cap and torch, a popcorn tray, a reel's spokes and
  hub, a flat cap with film scratches, a critic's beret, monocle and notebook, a projectionist's
  eyeshade and hand projector).
- **Retired tests moved:** the Mall Cop's charge, whistle and rally tests went to the airport's enemy
  tests and the Perfume Sprayer's to the office's, each now pinning the numbers the Mall's def had.
- **Crabtree:** 640 final health (355.556 in the .tres), 72 px/s, 8 Pension, Gloria's 0.6 s rest. The
  star rating says its number ("Three stars.") and never repeats the last one; a fan of 1 to 5 stars
  down warned lanes after a 0.6 s windup, spread (stars - 1) x 18 degrees (0 to 72) and flying
  260 - (stars - 1) x 30 px/s (260 to 140). The thumbs down winds up 0.8 s and sends a Klaus-style
  ring from 24 to 130 px over 0.7 s ("Thumbs down."). The bad review comes every 10 s (first at 4 s):
  2 or 3 Extras, as the roll says, on summon marks across his way, never past 5 enemies in the room
  ("A dreadful show!").
- **Gloria's shared rules:** the fountain jets' spot and patch rules, which the Commodore's deck wash
  and the Chairman still use, moved to `SplashJets` with their tests (now in the cruise's boss tests);
  the comparisons against Gloria in the later floors' tests now name Crabtree.
