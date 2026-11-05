# The Flashback Cinema and the Séance Hotline: plan

**Goal:** replace Golden Years Mall (floor 3, `golden_years_mall`) with **The Flashback Cinema**
(`flashback_cinema`) and Fairway's End (floor 4, `fairways_end`) with **the Séance Hotline**
(`seance_hotline`), as the approved spec says:
`docs/superpowers/specs/2026-11-06-cinema-and-seance-paths-design.md`.

**Worktree:** `C:\GameDev\game\.worktrees\paths-rework`, branch `paths-rework`, off `round-2` at
`918d343`. Work only there. Never touch `.worktrees\check` or `.worktrees\round-2`.

**Testing is allowed.** Godot console:
`D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.

**Decisions** are logged in `docs/superpowers/plans/paths-rework-notes.md`, one line each, as they
are made. The user delegated every one.

## Global constraints (every task)

- Read `CLAUDE.md` and all of `LESSONS.md` first. The ones that bite most here: CRLF files (use the
  Edit tool or `py` with `newline=''`; never Git Bash `sed -i` without `-b`; run a CRLF pass over
  every new file before each commit and check with `git ls-files --eol`), LESSONS.md is UTF-8,
  probes need a quit timer and `call_deferred`, `--script` runs cannot name autoloads, nodes added
  in a test's `_initialize` get no `_ready`, PowerShell `Set-Content` adds a BOM.
- Never name other games in any file or commit message.
- No new dependencies.
- **The real save** `%APPDATA%\Godot\app_userdata\Grandpa\slot_1\save.json` must keep MD5
  `510284fa2ead4647c94fee44f99ca787`. Check it before and after every Godot session. Never write
  to that folder. Tests and `--smoke` use their own files; full loops and bots run in `git archive`
  copies with a renamed `config/name`.
- Commits: imperative mood, one logical change, message from a scratchpad file, ending with a
  blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Leave the project
  runnable after each commit (the suite passes).
- Push often: `env -u GIT_TERMINAL_PROMPT -u GCM_INTERACTIVE git push -u origin paths-rework`
  (Git Bash).
- Art is placeholder: SpriteVisual's coloured boxes plus `EnemyMarks`-style drawn marks, drawn
  props. Every new EnemyDef gets `art_id` equal to its own id (the H1 to H4 hooks are in the
  base), so art drops in at `res://art/sprites/<id>/<anim>.png`.
- New behaviors follow `.claude/skills/add-floor/SKILL.md` section 3: every attack warns, every
  `*WINDUP`/`FUSE` constant is at least 0.2 s times `PlayerStats.BASE_WARNING`, the heaviest
  attack costs 3 and shows its whole 1.2 s windup with a second outline, lingering effects are
  listed in `RoomView.is_passing_effect`, room code names no enemy data, pure rules are static
  functions with headless tests, warnings stay on the z 60 layer, a single safe spot is marked.
- **Bot readability:** every new hazard node the bot must step out of answers two methods,
  `threat_at(p: Vector2, strict: bool) -> int` (0 clear, 1 better avoided, 2 a coming hit) and
  `threat_imminent(p: Vector2) -> bool`, which `tools/probes/bot_probe.gd` reads generically
  (Task 6 adds that reader).

## Task 1: The id swap, save migration and the Waiting Room hooks

The game keeps running on the old content under the new ids, so every later commit is runnable.

- **Rename** `data/floors/golden_years_mall.tres` to `flashback_cinema.tres` and
  `fairways_end.tres` to `seance_hotline.tres` (`git mv`), with the new `id`, `display_name`
  ("The Flashback Cinema, Last Showing", "Beyond Calling Psychic Hotline, Night Shift") and
  `rooms_dir`. Move the room folders to `data/rooms/flashback_cinema/` and
  `data/rooms/seance_hotline/` for now (their content is replaced in Tasks 3 and 5).
- **Lists of paths:** `floor_scene.gd` depth table, `progress_data.gd` `PATHS_AT_DEPTH`,
  `dev_start.gd` `ALL_PATHS`, `ending_rules.gd` `SCENIC_PATHS`, `music_rules.gd` `PATH_THEMES`
  (new song ids `flashback_cinema` and `seance_hotline`), `departments.gd` path names, every
  test and probe that names an old id.
- **Departments:** the Back Room opens on `flashback_cinema`. The Pro Shop becomes the **Crystal
  Counter** (department id `crystal_counter`, same slot, unlock on `seance_hotline`, same stock
  logic), its title "Crystal Counter. Crystals, Candles and Incense", run by **Esme, Crystal-Shop
  Keeper** (`data/npcs/esme.tres`, placeholder colour, voice `blip_mystic`, new lines). Duffy's
  NpcDef and art folder are retired. The Pro Shop's upgrades keep their ids and effects and get
  new names and text (crystals, candles, incense).
- **Letters, mementos, bounties, first-clear items, endings** exactly as the spec says. Mementos
  keep the two perks (treasure choice, charge power) with new names and text. Bounty files are
  renamed to the new boss ids (`crabtree`, `projectionist`, `celestine`, `madame_zara`), keep
  their rewards and change `floor_id`. Until Tasks 4 and 5 add the new bosses, the FloorDefs keep
  the old bosses, so the bounty and memento tests that match a boss to a floor are moved with the
  boss swap in Tasks 4 and 5.
- **Save migration** in `ProgressData.from_dict` (`PathMigration`, a new static helper in
  `scripts/core/path_migration.gd` with `const PATHS := {"golden_years_mall": "flashback_cinema",
  "fairways_end": "seance_hotline"}`, `const BOSSES := {...}`, `const POSTERS := {...}`,
  `const DEPARTMENTS := {"pro_shop": "crystal_counter"}`). Map every stored id: `paths_cleared`,
  `path_clears`, `item_paths_seen`, `letters_read`, `departments_seen`, `bounty_taken`,
  `bounties_retired`, `bosses_beaten` (old boss ids kept as history, new ones added),
  run log entries' path ids, and anything else found by grepping `from_dict`. The bestiary's
  `enemies_seen` keeps the old boss ids as history; their art falls back to a placeholder. The
  run checkpoint (`run_checkpoint.gd`): a run stopped on a retired path resumes at the start of
  that floor on the replacement path, keeping items, pills and money. `.bak` and atomic writes
  unchanged.
- **Tests:** `tests/test_path_migration.gd` with old-save fixtures under
  `tests/fixtures/old_save_mall_golf.json` (Mall and golf progress: clears, bounties taken and
  retired, mementos, Pro Shop seen, letters read, run log, endings) and two checkpoint fixtures
  (one stopped on each retired path). Each fixture loads, migrates, round-trips through
  `to_dict`/`from_dict` unchanged, and a second migration is a no-op. Waiting Room unlocks under
  the new ids.

## Task 2: Cinema regulars, summon and shared recolours

- `usher` (UsherBehavior: patrol, torch cone, 0.6 s in the cone winds up "Shh!" and charges
  along the beam line), `popcorn_vendor` (keeps distance, lobs a tub at a marked spot, bursts into
  6 kernels), `film_reel` (rolls straight, bounces off walls and seats, turns 90° toward Harold
  on each bounce, lays a fading film-strip trail that slows like the sticky floor, 4 s), the
  summon `extra` (grey film extra, fragile, quick, simple shove), and the recolours
  `cinema_intern_reaper` and `cinema_notary_public`. Numbers start from the Mall regulars' roles.
- Tests: `tests/test_cinema_enemies.gd` (every attack's warning leaves time, the cone timer, the
  bounce turn, the trail's fade and slow, the kernel ring, told-apart colours), plus
  `test_enemy_types` `BEHAVIORS`.

## Task 3: The Cinema's look, props, screen, life signs and 33 rooms

- Palette (gold trim, deep teal carpet, plum seats, no large red), floor pattern 14 (carpet with
  aisle runners) and wall pattern 14 (deco panels with gold trim), decor (aisle lights, pillars,
  dust), lighting (dim, one warm projector beam, a cool screen glow).
- Seat rows (`SYMBOL_SEAT`): solid cover that blocks movement and projectiles like crates.
  Pillars.
- **The screen** (`scripts/world/cinema_screen.gd` and `scripts/world/cinema_screen.gdshader`):
  on the north wall of every combat room, flicker, film grain, vertical scratches, a dusty
  projector beam from the south, a slow cross-fade between 2 or 3 frames. It loads
  `res://art/cinema/scenes/<id>.png` (one strip of frames) and falls back to a drawn sepia
  gradient with a silhouette. `CinemaScenes` (`scripts/content/cinema_scenes.gd`) holds the 14
  scene ids and descriptions, and `CinemaScenes.pick(room_seed)` chooses one per room.
- **Life signs** (`scripts/world/life_sign.gd`, `scripts/content/life_signs.gd`): one lobby card
  per Cinema room, the 40 lines, shown while Harold is near and hidden when he walks away, never
  pausing play. Each line is shown at most once per run, picked by the run seed, favouring lines
  not in the save's new `life_signs_seen` key (default empty). Tests for once-per-run, the save
  key and old saves without it.
- 33 layouts in `data/rooms/flashback_cinema/`, the old shapes with seat rows, every combat room
  with room for one life sign; the floor test `tests/test_cinema_floor.gd`.

## Task 4: Cornelius Crabtree and the Projectionist

- `crabtree` (32x40, Gloria's slot, 640 final): star rating (1 to 5 stars in a fan, narrow and
  fast for low, wide and slow for high), thumbs down (windup, stomp ring), bad review (2 or 3
  Extras on marks, capped).
- `projectionist` (44x52, the Mall Santa's slot, 1650 final to start): reel change (screen to
  black, warning tone and flash, then 8 s of rain/slippery floor, silent comedy pies down warned
  lanes, or western tumbleweeds down lanes, never the same reel twice running), lens beam (a
  turning telegraphed beam, OverlapRoute-checked), splice (2 or 3 film-strip lanes snap shut after
  a warning), phase two below half: a slowly growing white burn ring from the screen while reels
  and splices quicken.
- Swap the FloorDef's bosses, move the bounty and memento boss tests, the 200-seed OverlapRoute
  tests for the Lens Beam and the Splice, `test_boss_spawn_room`.
- Retire the Mall: its unique enemies, bosses, behaviors, props, hazards, marks, palette entries,
  tests and probes that nothing else uses (the Mall Cop's behavior and art stay for the airport).

## Task 5: The Séance Hotline, complete

- Regulars `phone_psychic`, `crystal_gazer`, `poltergeist`, summon `ectoplasm`, recolours
  `seance_bingo_caller` and `seance_soot_ghost` (the golf path's returning pair, rethemed).
- Look (violet carpet, teal, candle warm, phone green; ectoplasm darker than the safe-spot mint),
  cubicle partitions, desks, filing trays, a séance table in large rooms; 33 layouts.
- `celestine` (32x40, Chip's slot, 760 final): deals 3 face-down cards, turns them one by one,
  each showing its symbol before acting (Tower, Death, Wheel, Star), never 3 of a kind.
- `madame_zara` (44x52, Thaddeus's slot, 1950 final to start): On the Line (tether circle shown
  first, 3 s, OverlapRoute keeps a safe spot inside), Ouija board (letter grid, planchette path
  previewed), Possession (a ghost replays his last 2 s for 4 s), phase two séance circle (a wide,
  drifting ring of light in a dim room, spirits attack outside it). No hold music.
- Music: an organ intermission theme and a theremin-and-tremolo line in `tools/music`, replacing
  the old Mall and golf songs.
- Retire the golf path the same way as the Mall.

## Task 6: Verify and tune

- The bot's generic `threat_at` reader. Bot batches in the same session: the Projectionist
  against the Mall Santa on `918d343` (round-2's code), Madame Zara against Thaddeus. Tune to
  within about 20%.
- The full suite, 2 or more full loops from `git archive` copies on `D:\grandpa-verify-pr-N`.
- Screenshots in `D:\grandpa-shots-pr\` of every new attack, the screen, a life sign, the Ouija
  board, the séance circle and both paths' rooms. Look at each and fix what reads badly.
- Write the art list (ids, sizes, anim names, scene ids) into the notes.
