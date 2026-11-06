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
- **Colours:** Usher royal blue (0.25, 0.4, 0.95), Vendor popcorn yellow, Reel copper (0.72, 0.5, 0.28),
  Extra mid grey (0.5), the Intern Reaper pink (art hue 275 to 325), the Notary sky blue, Crabtree olive
  tweed and the Projectionist khaki, so no body is red and each is told apart on the teal carpet.
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
- **The Projectionist's numbers:** the Mall Santa's 1650 final health (916.67 in the .tres, the
  Santa's own figure), 80 px/s, 16 Pension, his 0.65 s rest (0.45 in phase two), 1.2x speed and 0.8x
  windups in phase two. No summons.
- **Heaviest attack: the lens beam** (3 pills, the whole 1.2 s windup shown, the start line outlined
  twice, never shortened). It is the projector's own light, so it is the natural big hit, and the
  splice could not be it, since the spec has splices quicken in phase two. The beam is thrown from
  where he stands (he holds still for its windup and sweep), 340 px long, 26 px wide, sweeping 100
  degrees in 2.2 s; the whole arc it has still to cross is tinted red the whole time (lesson 160), and
  feet it passes over cost 3 pills once.
- **The beam's plan:** OverlapRoute holds only rects and circles, so the sweep is sampled as circles
  along the beam (18 px apart, radius 22) at slices 18 px of far-end travel apart, each hurting for its
  slice (about 500 circles). He tries the arc's middle on Grandpa first, then turned 30, 60 and 95
  degrees off each way, either way round, over everything under way (the reel's lanes, the splice, the
  burn), and marks the nearest spot the beam never covers. Over 200 seeds in his two rooms the first
  try worked 199 times in 199 (one state was lost before the beam), the slowest plan 43 ms.
- **OverlapRoute got faster, not different:** each shape now visits only the grid points inside its
  bounding box (the exact test is unchanged), and overlapping windows on one point are merged. The
  airport's and office's 200-seed tests and the route's own tests pass as before.
- **The splice:** 2 or 3 lanes (always 3 in phase two), 36 px wide, their middles 96 px apart, right
  across the room as rows or columns; warned 1.0 s (0.85 in phase two) after a 0.5 s windup ("Splice!"),
  then the film snaps shut and feet in a lane cost a pill. Planned round his feet first, then moved
  half a pitch at a time, over everything under way; 195 of 195 live states planned, slowest 16 ms.
  Drawn as two dark film strips with sprocket holes along each lane's sides, slamming together.
- **The reel change:** every 14 s (10 in phase two, the first after 3 s), never two running and never
  the same genre twice in a row. A 0.7 s windup ("Reel change!") cuts the screen to black with the
  queue barrier's chime (`barrier_chime`, the game's warning chime), then a flash, and the reel runs
  8 s (`ReelChange`): rain wets every floor cell but the doorways' (WetSplash, the wet floor's own
  slide rules) with faint rain streaks over the room; a silent comedy throws a custard pie down a warned
  lane (a row or column, either way, 380 px/s) every 1.0 s; a western rolls a tumbleweed along a warned
  row (200 px/s) every 1.3 s; both 0.8x as often in phase two. Each lane warns 0.9 s, is 28 px wide, and
  is planned with OverlapRoute too (his own line or up to 3 lanes off it, half the time his line first),
  skipped when none leaves a way out.
- **Phase two's burn:** a half disc burns out from the screen's foot at 6 px/s, to a cap of half the
  room's height (240 px at most), so the back rows always stay; inside it burns as fire (a fire hit
  every 0.8 s). A white burning edge on the warning layer, a scorched inside under the bodies, and the
  screen burns along with it (`CinemaScreen.set_burning`). It goes out when he falls.
- **Retired with the Mall Santa:** his elves, his behavior, the present drop and the closing ring
  (nothing else used them), his art folder `art/sprites/mall_santa` (the PixelLab originals stay there),
  and his entries in the art strips tool and the art look probe. The later floors' floor-boss tests
  compare with the Projectionist. `tests/support/pending_bosses.gd` keeps only Chip and Thaddeus for
  Task 5.
- **Retired with the Mall's props:** the shopping cart, gumball machine, planter, fountain and sale
  sign with their symbols `a z d q e`, their palette colours and room branches; the escalator strips
  (`> < ^ v`, `ConveyorStrip`, `ConveyorRule`, `ConveyorCycle`, `strips_reverse`, the carry in the
  enemy's and the player's walk; `Enemy.rides_strips` folded into `slides_with_roll`, which the rolling
  deck still reads); the polished tile and shop-shutter patterns 3; the Mall Walkers', Gloria's, the
  Santa's and the elves' marks and the coin and ornament shots; `test_mall_floor.gd` and
  `test_mall_hazard.gd` (the fluorescent-panel rule moved to the airport's floor test). The bench,
  food-court table and fluorescent panel stay, as the cruise, the airport and the office hang them.
  No layout in any folder used a retired symbol. The `escalator_hum` sound stays in the sound bank,
  unplayed, for the music and sound pass to drop with the golf path's.
- **Looked at in a real window** (`tools/probes/cinema_look.gd attacks`, 34 shots in
  `D:\grandpa-shots-pr\cinema_attack_*.png`, each timed by the attack's own state, the boss held each
  frame between the probe's attacks). Fixed after looking: the violet Usher read as one more plum seat
  (now royal blue); the light-grey Extras burned to white under the read glow (now mid grey in a dark
  suit with a pale collar, drawn by its mark, with the reel moved to copper so the two stay apart); the reel stopped and turned on a wall it was only rolling
  along, so it now bounces only off what it meets head on (`FilmReelBehavior.ran_into`); hecklers side
  by side printed their calls over one another, so one stays quiet while a neighbour calls; the
  tumbleweed was small and dark on the seats (now bigger, sandy, outlined); the beam's arc still to
  cross was a faint tint (now stronger, with a 2 px edge); the splice's lanes filled a little stronger;
  and the beam's safe spot sat right against his body, where touching him costs a pill, so his marks
  keep 16 px more clear (`ProjectionistBehavior.MARK_CLEARANCE`). The reel-change shots stand Harold near
  the north wall so the black screen and the flash are in view; red warnings read on the rain reel's
  wet floor (a splice over it).
- **Look hooks:** `CrabtreeBehavior.forced_rating` and `ProjectionistBehavior.forced_reel` let a probe
  pick the next rating or reel; 0 and -1 leave the choice to them.
- **The bot's generic reader is in** (`tools/probes/bot_probe.gd`, version 9): any room child with
  `threat_at` and `threat_imminent` counts as a deep hazard, read through those two methods. Not yet
  run in a batch: Task 6 measures and tunes. The Usher's torch beam is no hazard (it hangs on him) and
  answers nothing.
- **Verified:** the suite passed at every commit in `git archive` copies (2124 tests, 0 failed at the
  end), and one full loop from a copy of `3d02faf` printed both SMOKE PASS lines with no script error
  (the usual exit-time leak lines only, as before).
- **Left for later:** Task 5 retires `tests/support/pending_bosses.gd` with Chip and Thaddeus; Task 6
  runs the bot against the Mall Santa's baseline on `918d343` (the Projectionist keeps the Santa's
  numbers until then); the `escalator_hum` sound is unplayed; the Mall Cop's art folder stays for the
  airport's recolour.

## Task 5: the Seance Hotline

- **Palette (Phase A):** a deep violet carpet (0.23, 0.13, 0.37) in three close tones with almost no
  jitter, dark teal wall panels (0.04, 0.23, 0.25), a violet ambient (0.46, 0.36, 0.52), candle-warm
  wall lights (0.85, 0.62, 0.36) and lanterns, a cool teal fill (0.56, 0.72, 0.86) and a slight flicker
  (0.05). The carpet is a little bluer and darker than a plain violet so the warning red still stands
  0.43 apart on it under the fill; nothing large is red or green, and the ectoplasm colour kept for the
  summon (0.12, 0.42, 0.27) is far darker than the safe-spot mint. Phone displays are a lime of their own.
- **Patterns 15:** `SeanceLook.CARPET` scatters faint four-point stars (two short strokes, upright and
  level) and thin crescent moons (two arcs) by a per-cell roll, about a quarter of the cells, at a spot of
  their own in each cell; no fills, no seams, no grid, no diagonals, so it shares nothing with the
  ectoplasm's blobs, the Ouija board's letter grid, a film strip or a wet floor. `SeanceLook.STAR_WALL`
  draws a thin teal rail, a dado line, a skirting and a small star on every other panel.
- **Decor:** cobwebs, office chairs (the cubicles' own) and a few cracks, thinly (0.035), no scattered
  lights, no plants (no green near the mint). Golf's grass, fog, benches, plants and lanterns are gone
  from the palette, and so are the fairway stripe, hedge, cart, flag and ball-washer colours (defaults
  until the golf props retire).
- **No ectoplasm-drip decor:** a green drip on the carpet would read as the summon's sticky trail, which
  is a hazard, so the drips are left to the summon itself.
- **Sand stays in the palette:** the Club President still spreads bunkers here until his room is taken,
  so the moonlit sand colours stay and test_golf_floor's sand tests now read them on the carpet.
- **Golf look tests:** the fairway, night-light, enemies-on-grass and prop-debris tests left
  test_golf_floor (the debris of the golf props no longer matters on a floor that will not hold them);
  the palette tests now live in the new test_seance_floor.gd.
- **Props (Phase A):** `d` psychic desk, `q` seance table and `z` cubicle partition are solid furniture
  (`RockBlock`s on the wall layer, in `WALLS_AND_BOMB_ONLY`, broken by blasts and bosses, each hiding a
  coin at the furniture rate); `a` lava lamp breaks to anything like the vase and gives a small soft
  violet light; `e` beaded curtain is a plain `Node2D` that blocks nothing and never breaks, lying under
  the bodies at 0.8 alpha, its strands parting round Grandpa. Filing trays reuse Head Office's `y`.
- **Multi-cell pieces:** the desk art is 64x48 and the table art 64x64, so two desk cells side by side
  (paired from the west along a row) are one `PsychicDesk` with a 64x32 body, and a 2x2 square of table
  cells is one `SeanceTable` with a 64x64 body. A leftover desk or table cell is a narrow desk or small
  table with its own placeholder (art ids `psychic_desk_narrow`, `seance_table_small`, no art planned).
  Breaking a piece opens every cell it covered. One prop, one coin roll.
- **Partition art:** `cubicle_partition.png` is a 64x48 strip of two cells, so `SeancePartition` stays one
  per cell (as the Cinema's seats) drawn 32x48 with frame posts only at a run's open ends; the strip is to
  be cut into two 32x48 halves when the art is wired. The lamp is drawn for 32x48 art and the curtain for
  48x64. No PNG is wired yet.
- **The table's candles** give a small flickering candle light; the desks give none, the wall lights
  being the candle-warm desk lights.
- **`SeanceProps.is_passing_effect`** returns false until the hotline's attacks add their effects.
- **The 33 layouts (Phase A):** the same file names, types, sizes and mix as Fairway's End's, drawn over
  the old shapes: hedgerows became cubicle banks (a run of partitions with a run of desks against it,
  forming lanes), the dogleg and the staircases stayed as stepped banks, the round hedge became a ring
  of partitions with desks, sand traps and flags became lava lamps, beaded curtains and filing trays,
  and ball washers became lamps and trays. Fighters were placed from the printed legal-cell maps and
  every room checked with a py port of `validate()` and the hotline's rules before Godot ran.
- **Counts across the folder:** 341 partition cells, 276 desk cells (138 desks), 48 table cells (12
  tables), 44 lava lamps, 16 curtains, 16 filing trays, 60 wall lanterns, 3 chests (combat_02,
  combat_05, combat_large_02, as golf had), 132 `E`, 4 `B`. That is 491 coin rolls at the furniture
  rate (each partition cell, each desk and each table once), under the Cinema's 785 seats and Head
  Office's 754 partitions, so no coin rate changes; a test keeps the count under the Cinema's seats.
- **Seance tables** stand in all 8 large rooms (two in some) and in no other, since a 2x2 table needs
  the room; the boss rooms flank the `B` with them. Every `B` keeps its 3x3 clear and fits a 32x40, a
  44x52 and the Club President's 46x52 box.
- **Lanterns** stay where golf hung them: wall lanterns, lit candle-warm by the palette.
- **Tests moved:** the floor's path, difficulty, layout, mix, combat numbers, room types, whole-floor,
  crossroads, vault and shop tests moved from test_golf_floor.gd to test_seance_floor.gd against the new
  rooms; test_golf_floor keeps only the golf enemies, bosses, patterns, sand, fog and golf-prop tests for
  the later phases to retire. The chest and shop loops over the folder now say "The Seance Hotline".
- **Enemies (Phase B), one commit:** the hotline's three regulars, the Ectoplasm and the returning pair
  go in with the floor wired and golf's regulars retired, as lesson 288 asks. The slots keep golf's
  roles and numbers: the Phone Psychic the Gopher's (44 health, 58 px/s, weight 3, against the Plot
  Holder), the Crystal Gazer the Club Golfer's (30, 66, weight 4, the Filing Clerk's thrower role) and
  the Poltergeist on Hold the Caddie's (36, 64, weight 3, the Debt Collector Ghost's), then the Bingo
  Caller (3) and the Soot Ghost (2). One Pension each, at most 3 a room.
- **The Phone Psychic:** keeps 80 to 150 px off; every 3.2 s (first at 1.2 s), with his feet 40 to 170 px
  from it and in view, it holds still, says "I sense you..." and lays a `PhoneCordLash` where it stands:
  a red ring (14 px) on his feet's spot and the band the cord sweeps, an arc round the psychic through
  that spot, 22 px across and 40 degrees either side, both shown and filling for the whole 0.7 s. Then
  the coiled cord whips along the arc, and feet in the band cost a pill once. A step 22 px in or out
  clears it (he walks 48 px in 0.4 s). The psychic's own windup ring (12 px) runs with it, so its art's
  windup and attack anims play through Enemy's anim driver. No wall test on the arc: it is a cord.
- **The Crystal Gazer:** keeps 110 to 220 px off; a 0.6 s windup (warning ring 16 px) over her ball, then
  a `CrystalBall` goes, one at a time (the next windup waits until the last ball is gone, then 2.4 s).
  The ball homes on his feet at 75 px/s, turning at most 110 degrees a second, for 3 s; then it stops
  and a 28 px red ring fills round it for 0.6 s and it bursts (feet in it cost a pill unless a wall
  stands between, as with a blast). Meeting cover (a ray on the wall layer, which holds the desks and
  partitions, as a shot's) stops it there and starts the same warned burst at once, so no burst is ever
  unwarned. Touching his feet on the way (10 px) costs a pill and pops it with no burst after. It comes
  to nothing if she falls.
- **The Poltergeist on Hold:** keeps 100 to 200 px off; every 2.8 s (first at 1.4 s) a 0.6 s windup with
  its lane warned (260 px, 20 px wide, ending at walls and props), then it hurls a stapler, a mug and a
  fax machine in turn (190 px/s), plain `Projectile`s with three new looks, so they stop at cover and a
  stored room clears them already. It says "Please hold..." on every third throw.
- **The Poltergeist is a ghost through `ContactRule.is_ghost`,** which knows ghosts by id ("ghost",
  "mourner"), so "poltergeist" was added there; `ghost_contact` stays false, since that flag opts a
  ghost back into hurting by touch. The Mothball Pockets keep it off as any ghost. It is drawn at 0.6
  alpha (`SpriteVisual.set_alpha` in `on_ready`, so it reaches art and placeholder alike).
- **The Poltergeist walks round cover** (`ignores_walls` false), as the Soot Ghosts and the Weeping
  Mourners do; only the charging Debt Collector Ghost passes through walls. A thrower inside a partition
  would be out of his reach, and `Enemy._clear_length` skips the wall test for a wall-ignorer, so its
  warned lane would run through walls its objects stop at.
- **The Ectoplasm** (Madame Zara's summon): 14 health, 42 px/s, 22x18, the palette's deep green
  (0.12, 0.42, 0.27); it oozes after him and hurts by touch only. Its `EctoplasmTrail` lays a blob (r 7)
  every 10 px oozed, at most 10 (a 100 px trail), each fading 2.5 s after it was laid, and slows him by
  0.35 for 0.4 s every 0.2 s while his feet are on it, as the film does. The goo is `#1f6b45`, tested
  equal to `RoomPalette.ectoplasm`.
- **A body that never flips:** the film reel has no special handling (it is drawn east and flips like
  every enemy), so the Ectoplasm's south-only art got a new `EnemyDef.flips` (true by default); with it
  false, `Enemy._update_anim` never mirrors the look. A test runs it on real art.
- **The Ectoplasm is on no floor yet:** the case file's test allows two enemies on no floor and none was
  missing, so it waits there for Phase D to make it Zara's summon, and the Caddie stays the Club
  President's summon (his cart charge still uses `CaddieBehavior.Cart`).
- **`test_enemy_types` BEHAVIORS** gains the psychic, gazer and poltergeist behaviors, but not the
  Ectoplasm's: that test wants a WINDUP constant in every behavior it lists, and the blob has no attack.
- **Colours:** the psychic gold (0.98, 0.88, 0.32), the gazer cornflower (0.4, 0.58, 1), the poltergeist a
  pale ghost blue (0.75, 0.9, 1, the floor's one low-saturation body), the Bingo Caller magenta pink
  (0.95, 0.42, 0.8), the Soot Ghost cyan (0.35, 0.92, 0.95) and the Ectoplasm deep green. Checked in py
  as lit by the hotline's light: each stands 0.25 or more off the carpet, 0.44 or more off the warning
  red and 0.36 or more off the mint, and each pair of the floor's bodies, the golf bosses and their
  summons included, is 0.25 apart or 12 px apart in size. Tests keep the red, mint and carpet-hue gaps.
- **The returning pair:** `golf_bingo_caller` and `golf_soot_ghost` were renamed to `seance_bingo_caller`
  and `seance_soot_ghost` with the same numbers (the bases'), new colours and `art_id` "bingo_caller" and
  "soot_ghost". Neither base has an art folder, so no `art_hue` fields: the art pass sets them if its
  colours need turning.
- **Placeholders sized for the art:** the crystal ball is drawn r 10 (about 21x24, its 32x32 art at 1:1);
  the stapler, mug and fax fill 24x24 (their 32x32 art at 0.75: about 20x16, 15x16, 20x18), small
  enough to read as thrown office things beside an 18x24 body. No PNG is wired.
- **Marks:** `SeanceMarks` draws a headset with a mic and a green-lit desk phone on its coiled cord, a
  coin-hung veil with a pink jewel and a crystal ball held out, a ghost's hollow eyes and wisps with a
  receiver off the hook, and the blob's shine, eyes and drips; EnemyMarks hands them over after the
  Cinema's.
- **Hazards answer the bot:** `PhoneCordLash`, `CrystalBall` and `EctoplasmTrail` answer `threat_at` and
  `threat_imminent`; the lash's `route_circles` samples its band as circles 10 px apart along the arc
  (14 px radius, hurting at the lash), and the ball gives its warned ring, or while it flies its reach
  until it stops and the ring wherever it could stop. All three are in `SeanceProps.is_passing_effect`.
- **Retired with golf's regulars:** the Club Golfer (def, behavior, `GolfBallShot`, its "golf_cap" mark,
  its art folder `art/sprites/club_golfer`, its strips-tool cut and art-look probe entry; the Bestiary's
  history cell names him from his id), `golf_bingo_caller` and `golf_soot_ghost`, and their tests. The
  Caddie and the Gopher keep their defs, behaviors, marks and tests as the golf bosses' summons until
  Phases C and D retire Chip and the Club President. The golf look probe lost its golfer shots, and
  round2_look and round3_look now warn with a Crystal Gazer where they used the golfer.
- **Tests moved:** the floor's enemy list and the told-apart test moved from test_golf_floor to
  test_seance_floor (now with the bosses' summons and the Ectoplasm); test_golf_floor keeps only a check
  that Chip and the Club President still hold the boss rooms with their summons. A headless live check
  (each new enemy in a tree beside a stand-in Grandpa for 7 s) saw every attack fire and land, with no
  script error.
- **Sister Celestine (Phase C), one commit:** she takes Chip's slot and numbers (760 final health,
  345.455 in the `.tres`, 75 px/s, 8 Pension, 32x40) with the floor wired and Chip retired in the same
  commit. Ochre (0.65, 0.5, 0), the floor's one ochre: 0.25 or more off every hotline body, 0.4 off the
  warning red, off the mint and the carpet's violet (checked in py, then tested). Mark `tarot_shawl`: a
  dark headscarf with a gold star, a fringed violet shawl and three card backs fanned in her hand.
- **Her hand:** she deals 3 cards face down (0.6 s, "Let us see your cards...", `deal_cards` anim, the
  cards landing 0.15 s apart and sliding out of her hand), then turns them one at a time. A turned card
  flips (0.16 s) and shows its symbol with a name tag under it, and she says its name, for 0.6 s
  (`TURN_WINDUP`, `attack` anim) before its attack starts. Each card's attack is its own node with a
  whole warning of its own; she sets no windup ring on herself, since the deal hurts no one.
- **One attack at a time:** she turns the next card only once the last card's attack can hurt no more
  (`is_spent`), then waits 0.25 s, so no two cards' hits are ever under way together; that spacing is
  the overlap rule rather than an OverlapRoute plan, and a test plays out every hand to check at most
  one attack is live at any frame. The hotline's regulars can still overlap her, as any room's can.
- **She holds still from the deal to her last card** (as the Projectionist holds for his beam), so the
  Wheel and Death, which reach round and ahead of her, are what punish standing beside her.
  Between hands she rests Chip's slot's 0.5 s (the Reverend's), keeps within 110 px and chases at the
  catch-up speed while her body is off screen; a hand starts only with her body in view.
- **The deal rule:** `CelestineBehavior.deal(rolls)` draws the first two cards freely (a quarter each)
  and, when they match, the third from the other three, so three of a kind never comes and two alike
  do (5 hands in 8; the rest are three different cards). `is_valid_hand` says 3 cards of the deck, not all alike. `forced_hand` (a
  valid hand) lets a look probe pick her cards.
- **Where the cards lie:** a row of three 40 px apart, 52 px above or below her, or a column 56 px
  apart, 40 px beside her, on the side facing Grandpa's feet first, then the others by how much they
  face him, each tried slid 0, 24 or 48 px along its line; the first that lies wholly in the room on
  open floor (each card's middle and both ends) wins, else each card goes to the nearest open cell clear of her body and the others. Cards are
  flat decor (z -8), harmless, and fade when the hand ends or vanish when she falls.
- **The cards' art hook:** `TarotCard.SIZE` is 32x48, the size of the tarot PNGs, and `art_id()` names
  the stem it shows now (`tarot_card_back` face down, then `tarot_tower`, `tarot_death`,
  `tarot_wheel`, `tarot_star`); no PNG is wired. Placeholders: a dark violet back with a gold border,
  a diamond lattice and a crescent; a cream face with the symbol and its number (XVI, XIII, X, XVII).
- **The Tower:** 5 cell-sized squares (32x32, on whole cells): his feet's cell and 4 more at most 2 cells
  from it, on open floor inside the walls, never every open cell beside his own; then `tower_plan`
  checks them with OverlapRoute (walls, props, her body) and drops the last tile picked, never his
  own, until he has a way out (the cell rule alone left 4 of 200 states shut in her rooms). Warned 0.9 s by red
  squares filling from the middle with a growing tile shadow; then the tiles fall at once and feet in a
  square (2 px spare) cost 1 pill. Plaster bits lie 0.45 s.
- **Death:** a 90 degree sector (45 either side of Grandpa's feet), 110 px from her, tinted, filling
  from the edge the blade starts on and outlined twice, for 1.0 s; then the scythe sweeps it edge to
  edge in 0.3 s, either way round, and feet it passes over cost 2 pills (`Enemy.HEAVY_DAMAGE`), once.
  Two, not three: a mini boss keeps the heaviest hit for the floor bosses, as Crabtree and Chip did.
  No wall test (it is a spirit's scythe), so the warning is the whole sector.
- **The Wheel:** a band from 36 to 84 px round her with 3 blades of 70 degrees and 50 degree gaps,
  outlined and filling for 1.0 s without turning, then spinning 2.0 s at 2 rad/s either way; a blade
  over his feet costs 1 pill, once. Her body fits inside the clear inner ring (36 px), and outside the
  band is always clear, so a step of half the band's width out is the readable way out.
- **The Star:** 5 spots (r 16), the first on his feet and the rest 38 px or more apart within 90 px of
  him, on open floor; all show at once, each filling for its own warning, the first landing at 0.8 s
  and each other 0.15 s later, a star streaking down onto each. Feet in a spot as it lands cost 1 pill.
- **Every hazard answers the bot** (`threat_at`, `threat_imminent`, `is_spent`) and shows a planner its
  shapes: the Tower's squares as `route_rects`, the scythe's sector as circles 14 px apart (r 13) over
  the sweep, the wheel's band as circles round its middle (half the band plus 3) for the whole spin, and
  each star at its landing. A 200-seed test in her two rooms finds a way out of every card with
  OverlapRoute (200 of 200 for each). All five nodes (the card too) are in `SeanceProps.is_passing_effect`.
- **No summons:** Chip's Gophers are not replaced, as the Ectoplasm is Madame Zara's.
- **Retired with Chip:** `chip.tres` (renamed to `celestine.tres` in git), `club_pro_behavior.gd`, the
  Gopher (`gopher.tres`, `gopher_behavior.gd`), `golf_ball_lob.gd` and `putt_roll.gd` (only Chip used
  them), the `pro_visor` and `gopher_teeth` marks, Chip's and the Gopher's tests, the bot's `PuttRoll` and
  `GolfBallLob` branches (the puck's stay), the golf look probe's Chip and Gopher shots, and round2_look's
  Gopher shots (its dark-corner chip shot now shows Celestine's Star). `PendingBosses` keeps only
  Thaddeus. `test_golf_floor` now checks only the Club President's room. Old saves keep `chip` and
  `gopher` as history (`path_migration.gd` still maps `chip` to `celestine` for posters and beaten bosses).
- **Left as it is:** the Golf Visor cosmetic (Celestine's poster extra) still says "Chip's own"; its
  text is the item audit's to retheme with the other poster looks.
- **Madame Zara (Phase D), one commit:** she takes the Club President's slot and numbers (1950 final
  health, 886.364 in the `.tres`, 80 px/s, 16 Pension, 44x52, the Commodore's 0.6 and 0.42 rests), with
  the floor wired and Thaddeus retired in the same commit. Teal (0.1, 0.7, 0.65): 0.25 or more off every
  hotline body and the Ectoplasm, 0.4 off the warning red, off the mint and the carpet's violet, and
  not pale (s 0.86, so the Poltergeist stays the floor's one pale body). Mark `medium_turban`: a plum
  turban with a crystal and a feather, two strands of gold and pink beads, a receiver on its cord.
- **Second phase:** 1.2x speed, 0.8x windups except the Ouija board's, 0.42 s rests, as the
  Projectionist's. She holds still while a line holds and while the planchette is warned and slides
  (a medium at her table), and through a possession's windup only, so the copy can walk while she moves.
- **The Ouija board** (`OuijaBoard`) lies on her room's floor for the whole fight, laid in `on_ready`
  and laid again if a stored room ever clears it: a 7x4 letter grid (YES, A to E, NO; F to L; M to S;
  T to Z), the room less 48 px, letters at most 96x80 px apart so in the large room it lies in the
  middle, on translucent dark wood with a gold rim and cream letters, flat at z -8 under the bodies. One
  framed board of letters, nothing like the carpet's scattered stars and moons. It fades when she falls.
- **The planchette, her heaviest attack** (`OuijaPlanchette`): 3 pills once, the whole 1.2 s windup
  shown (`set_warning` whole, never shortened in phase two), every piece of its path a red band 32 px
  wide with a ring on each letter, each outlined twice (`Enemy.HEAVIEST_LANE_GAP`), and what it has still
  to cross stays shown as it slides. It spells one of 18 words (HELLO, BOO, GERALD, HEDGE, ...) at
  230 px/s, resting 0.12 s on each letter; a word taking more than 4.0 s to spell is left out (11 of 18
  fit the large room, all but few the medium). Sized to `planchette.png` (32x32, not wired): drawn as a
  wooden heart with a glass window, hitting feet within 16 px of its middle.
- **The board's plan:** the words sorted by how near their path passes his feet, starting at one of the
  3 nearest, at most 8 tried, each slide sampled as circles every 12 px (and one for each rest) over
  everything under way; the first that leaves a spot nothing ever covers wins, else the first that leaves
  any way out. Marks are the escape's never-covered spot, or the spot that stays safe once he gets there,
  never one by her body (`mark_of`).
- **On the Line** (`LineTether`): a circle of radius 88 round his feet as she calls, shown 0.8 s (0.64 in
  phase two) as a coiled cord on the floor with a cord from her to its edge, in the cord's cream, never
  the warning red, since the circle itself hurts no one. Then the line locks and holds him 3 s. She calls
  only when what is under way leaves him a safe spot inside the circle, and checks again as it locks
  (he may have moved): when nothing is safe the line goes dead ("The line's gone dead.") and holds no one.
  Alongside she runs the board or a possession, the board first and the possession first by turns,
  planned with the circle as the only open floor; with neither fitting, the hold runs alone.
- **The circle a plan may use:** `LineTether.open_within` answers for whole walk-grid cells and calls a
  cell open only when all four of its corners lie inside the circle (and the room's floor is open there),
  since OverlapRoute asks `set_open` once per cell with whichever corner lands there first. So a plan can
  miss a way out inside the circle but never promise one outside it. His own cell always counts.
- **The hold on Grandpa:** `Player.leash_to(center, radius, seconds)`, `end_leash`, `is_leashed`, read
  through `LeashRule.held_velocity`, applied at the end of `_handle_movement` after every push and before
  `move_and_slide`, so walks, dodges, pushes and body shoves all stay inside: a step that would cross the
  edge stops on it, keeping its share along the edge; caught outside as it locks he is drawn back in at
  150 px/s (quicker than his walk) and may not step further out. It ends with its own time, in
  `FloorScene._enter_room` (beside `end_push`, lesson 132), when she falls (`on_killed`), and when the
  line drops or leaves the room (`_exit_tree`), each only if it still holds that line's circle.
- **Bot reading:** the circle is 1 outside it while it warns and 2 outside it while it holds (margin
  12 px strict, 4 px otherwise), and never imminent, since it never hurts. The planchette is 2 along all it
  has still to cross; the copy 2 along its next 1.5 s of walk; the seance circle 2 outside its light; a
  spirit's ring 2 unless the spot is lit. The bot treats the planchette and the copy as moving hazards
  (its `sweeps` list), keeping a dodge for the moment they arrive.
- **Possession** (`PossessionGhost`, `FeetTrail`): she records his feet every tick (the last 2.25 s
  kept); a possession takes his last 2 s as 41 points 0.05 s apart. Warned 0.7 s (0.56 in phase two): a
  dotted red trail of his steps and a red ring where it rises, the copy faint there. Then it walks the
  trail at his pace and, for the rest of its 4 s, walks it back (decided over a second pass: no jump, and
  everywhere it goes was shown). So a moment t into its walk it stands where he stood t after the
  recording began, which is 2 s plus its windup before. A pale violet copy at half alpha with wisps and
  a red ring round its feet (his own frame, tinted, once his art is loaded; a see-through outline
  before), drawn on the shots' layer. 1 pill a touch (feet within 12 px), and it hurts again only after
  his feet have left it; the player's own grace does the rest. She casts it only when it leaves him a way
  out over what is under way, and only once she has his last 2 s.
- **The seance circle** (`SeanceCircle`, phase two): the room dims to 0.5 (Lights Out is 0.85) over
  0.8 s but for a ring of light of radius 132 (Lights Out's is 70 and rides on him) round a point that
  drifts at 12 px/s toward random goals inside the room less 64 px, its candle-warm edge drawn. It sits on
  Lights Out's z 50, under every warning and shot. Night Shift (`LightsOut.kept_lit`) keeps the room lit,
  but the ring and spirits still show and still strike, since they are an attack, not a darkness. Four
  spirits circle 26 px outside the ring; after his feet have stood outside it 0.5 s, one swoops every
  1.6 s (`SpiritSwoop`): a 22 px red ring on his spot warned 0.8 s with the spirit flying in, 1 pill only if
  his feet are still in the ring and still outside the light as it lands.
- **Her plans in the light:** while he stands in the light, every plan of hers treats only the cells
  wholly inside the light shrunk by its drift over 3 s (132 - 36 = 96 px) as open, so the way out she
  leaves keeps him in the light; when he stands outside it she plans over the open floor, and the spirits
  do the rest.
- **The Ectoplasm** comes in pairs every 12 s (first at 5 s), on summon marks across his way, never past
  5 enemies in the room, paying nothing as every summon. It is the floor's summon at last
  (`madame_zara.summon`).
- **No hold music:** a test reads her behavior and all six of her nodes and finds no `HoldMusic`.
- **Look hooks:** `forced_attack` (used once) starts any attack; `forced_phase_two` starts the seance
  circle whatever her health; `last_anim`, `tether()`, `planchette()`, `ghost()`, `board()`, `circle()`
  let a probe time its shots on state.
- **Retired with Thaddeus:** `thaddeus_fairweather.tres` (renamed to `madame_zara.tres` in git),
  `club_president_behavior.gd`, the Caddie (`caddie.tres`, `caddie_behavior.gd` with its `Cart`, which
  nothing else used; the baggage handler has its own), `giant_ball_drop.gd`, `sprinkler_sweep.gd`,
  `bunker_patch.gd` (only he used them), `golf_marks.gd` (only the boater and the caddie's bib were left),
  `GolfProps.is_passing_effect` (it only named the patch and the sprinkler) and its room line, his art
  folder `art/sprites/thaddeus_fairweather` (the Bestiary's history cell draws a placeholder), his
  strips-tool cut and art-look probe entry, the bot's sprinkler, bunker and giant-ball branches,
  `test_golf_bosses.gd`, `test_golf_enemies.gd`, the spread-sand tests of `test_golf_hazard.gd`, the golf
  look probe's enemy and president shots, and round2_look's caddie and president shots (its dark corner
  now shows the Ouija board's path and its mid room the seance circle). `tests/support/pending_bosses.gd`
  is gone: test_bounties and test_mementos read the floor's real bosses.
- **Left for Phase E:** `SandTrap`, `SandRule` (still read by the player's walk and dodge and the
  enemy's walk), `GolfProps` (the sand, flag pins, ball washers, hedges and parked carts), `GolfLook`
  (patterns 13), the sand palette fields, `FlagPin`, `BallWasher`, `Hedge`, `ParkedCart`, the symbols
  `s 3 4 5`, `test_golf_floor.gd` and `test_golf_hazard.gd` (now only the sand and props), and the golf
  look probe's rooms, props and pale-tile shots. No layout uses any of them.
- **Verified (Phase D):** the suite passed in a `git archive` copy of the commit (2187 tests, 0 failed).
  Over 200 seeds in her two rooms: the board planned 175 of 175 live states (25 lost before it), every
  one marked, 110 sliding within 56 px of him, slowest 9 ms in the large room; On the Line called in 180
  (20 refused, the circle already shut), dropped 3 at the lock, ran an attack alongside in all other 177,
  each with a marked spot inside the circle, slowest call and plan 24 ms; a possession was cast in 199 of
  199, slowest 12 ms. Not looked at in a real window yet (Task 6 shoots it).
- **Phase E, one commit:** the golf course's sand, props and looks go together, as the Mall's did in
  Task 4, since no layout has used any of them since Phase A and nothing else reads them.
- **Retired with the sand:** `SandTrap`, `SandRule`, the symbol `s` and its door check, the player's
  wade and no-dodge in sand (`is_in_sand`, the crunching steps), the enemy's wade, and the bot's sand
  branches (its wait for a dodge, its step out of sand near a boss, its walk round bunkers); the bot's
  version stays 9, since no other reading changed. The dodge line is a plain
  `Input.is_action_just_pressed("dodge")`, so the Polyester Suit's check stays inside `start_dodge`
  (lesson 215); test_reworked_items now reads the walk line without the sand.
- **Sounds:** `sand_step` and the Cinema's unplayed `escalator_hum` both left the sound bank, the
  pool's gaps, jitter and volumes, `tools/sfx/sfx.py` and `audio/sfx`, rather than waiting for the
  sound pass: nothing plays either, and sfx.py can make them again from history if a later floor wants
  a crunch or a hum.
- **Retired with the props and looks:** `GolfProps`, `GolfLook` (floor and wall patterns 13 and their
  backdrop branches), `FlagPin`, `BallWasher`, `Hedge`, `ParkedCart`, the symbols `3 4 5` from every
  list, `RoomView`'s golf build line, the golf palette group (sand, grains, shine, fairway stripe,
  hedge, cart, flag and ball-washer colours) with the hotline's sand values, and the ground fog decor
  (`RoomDecor.FOG`, its palette colour and its decor-layer branch), since no floor's decor weights
  name it. `s 3 4 5` are free again; a test keeps them out of every list and the palette.
- **Tests and probes:** `test_golf_floor.gd` and `test_golf_hazard.gd` are gone; the only rule still
  meaningful, one pale body a floor, moved to test_seance_floor, beside a new test that the golf
  symbols are free. `tools/probes/golf_look.gd` is deleted; round3_look lost its midnight-sand shots
  and round2_look's golf part is now `seance` (same shots, the hotline's sign and maps).
- **Items:** no item's effect named sand or golf. The Support Stockings now read "Sedatives, sticky
  trails, quoits and paper never slow you below 70% speed" (the film and the ectoplasm slow through the
  same rule), with the coach's tip to match; their 0.7 floor is unchanged. The Incense Sticks' sandalwood
  is no sand, so it stays.
- **The Golf Visor** keeps its id `golf_visor` (saves and the Decor Office may own it, and Celestine's
  poster names it by path) and becomes the Tarot Headscarf: Sister Celestine's spare, violet, drawn as
  a scarf over the crown knotted behind with two tails and a small gold star (`GrandpaLook` shape
  `headscarf`, which replaces `visor`). Drawn at the other hats' offsets; not yet looked at in a window.
- **Left as they are:** the Golf Glove's id (the Charging Crystal since Task 1); the path-migration
  map, its fixtures and tests, which still name the golf ids old saves hold; Harold's "That's me on a
  golf course" in the Scenic Route ending, which is his own life, not the retired floor; Gerald's hedge
  in the letters, life signs, Cinema scenes and Ouija words, which is the neighbours' feud; the
  Bestiary's history cells; history docs (night report, playtest notes, plans) and the bot's version
  history comment.
- **Docs:** the art inventory lost its "Left from Fairway's End" rows and its code paths to deleted
  files (golf marks, golf look, hedge and pennant hooks, laid sand, the golf cart and sleigh overlays),
  and now lists patterns 14 and 15; its history tables and totals stay, as Task 4 left the Mall's.
  The add-floor layouts guide named the deleted `test_mall_hazard.gd`; it now points at the cruise's
  slide test.
- **Looked at in a real window (Phase F):** `tools/probes/seance_look.gd` (parts rooms, regulars,
  celestine, zara, hud, scarf; 58 shots in `D:\grandpa-shots-pr\seance_*.png`), each attack shot timed by
  its own state (a lash's `fill` and `has_lashed`, the ball's `state` and `fill`, a card's
  `shows_symbol`, each card attack's `fill` and fallen, sweeping, spinning or landed state, the line's
  `is_warning` and `is_held`, the planchette's and the copy's `fill` and slide or walk), the bosses held
  between the probe's attacks by a per-frame callable, Celestine's cards picked with `forced_hand`,
  Zara's attacks started through `_begin` and her circle with `forced_phase_two`. Harold is kept alive
  by setting his pills directly (8, with `changed` emitted so the HUD shows them), walked to and fro by
  a per-frame callable for the possession's trail, and stepped onto her safe-spot marks once a warning
  is shot.
- **Fixed after looking:** the floor's long name ran left over the potion slot's "[H] Swift Tea" on the
  HUD's top row (the Cinema's, Head Office's, the Funeral Parlour's and Departures' did too, with a long
  enough potion), so the mini map now writes a name that does not fit its 108 px smaller (8, then 7 at
  the least) or only the part before its comma (`FloorMapView.mini_name`: the hotline shows "Beyond
  Calling Psychic Hotline" at 7); the big map and `floor_name()` keep the whole name, and a test holds
  every floor's mini name right of the potion slot. A card dealt in a column lies 8 px below the one
  above, so it covered the turned card's name tag ("The Star"); the tag is now drawn on a child node one
  z above the cards (`TarotCard.tag_node`). The stapler's grey arm vanished on the violet carpet (now
  chrome, with a test that every thrown thing's main colour stands 0.5 off each carpet tone). A lava
  lamp in `healing_01` stood on a beaded curtain's rail, which reaches 12 px into the cell above, so it
  moved two cells west, with a test that no lamp or filing tray stands right above a curtain. The
  Tarot Headscarf's flat top read as a box hat on Harold, so it is rounded over the crown.
- **Left as they read:** the planchette's path can run on toward the board's far rows under the HUD's
  top band or the small map when he stands in the south half of the large room (the camera cannot show
  a 30x17 room, and every part near him shows whole and outlined twice); the safe-spot mint pales
  beside Harold's own glow but stays apart from the red; the Wheel's warning tints its whole band, since
  the blades sweep all of it in their 2 s spin; the office chairs on the carpet read as decor. Desks and
  partitions on the second row of medium rooms sit clear of the HUD band.
- **Verified (Phase F):** the suite passed in `git archive` copies of both Phase F commits (2168 tests
  with the probe, 2172, 0 failed, with the four new tests); the 200-seed plan results are Phase C's and
  D's above. A first run of the final copy failed `test_game_settings`' round trip only because a second
  copy's suite ran at the same moment and wrote the same settings file in the OS temp folder; alone it
  passed. A 3-run bot smoke (`max good 3 1 4 bosses`, path index 1 is the hotline at depth 4, version 9
  from its own copy) beat Celestine 3 of 3 and Madame Zara 2 of 3 (boss_left 5.8, the loss with 17% of
  her health left; most hits were touches of her and of the Ectoplasm), with no script error: it plays
  the floor, and Task 6 tunes. One full loop from a copy of `d387bcb` (10 minutes, nothing else
  running) exited 0 with both SMOKE PASS lines, every flag true, 10 paths cleared and no SCRIPT ERROR in
  the whole log; its second run takes every east path, so it cleared the Seance Hotline, Celestine and
  Madame Zara included (the "seance_hotline's clear is remembered" check held), with no change to the
  driver. The real save's MD5 stayed 510284fa2ead4647c94fee44f99ca787 throughout.
