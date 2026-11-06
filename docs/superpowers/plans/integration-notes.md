# Integration notes (2026-11-05)

The `integration` branch started at `deep-floors` (1fe6587) and merged five branches in this order.
Each merge was followed by `tools/test.ps1` and fixed before the next.

| Merge | Branch tip | Tests after |
|---|---|---|
| Merge the title menu (9e193f4) | `title-menu` c7c758d | 1597, 0 failed |
| Merge the sound effects (886cd52) | `sfx` c2a03ad | 1617, 0 failed |
| Merge the music (397a91c) | `music` 6b7a662 | 1635, 0 failed |
| Merge the endings (98f0f09) | `endings` 38955e4 | 1682, 5 failed, fixed in the commits below |
| Merge the items (258905c) | `items` 86e670b | 1828, 0 failed |

`items` had moved on from the briefed d32fa66 to 86e670b by the time it was merged: batch 2 (the ten
dodge and movement items, the first ten defence and health items, the Mobility Scooter combo, its look
probe and notes) had landed. That tip was merged.

## Conflicts and how they were resolved

### title-menu
- `LESSONS.md`: both sides kept.
- `tools/smoke_driver.gd`, the Plot Holder warning timing: the physics-time version (deep-floors,
  matching items) kept, the frame-time one dropped. title-menu's lesson about it stays in LESSONS.md.

### sfx
- `project.godot` autoloads: Settings, PadWatch, Sounds, Progress, Game (Sounds needs the buses
  Settings makes).
- `combat_feedback.gd`: the heavy-hit rumble kept beside the new hit sounds.
- `floor_scene.gd`: the pause sound moved into `_open_pause`, so it plays whether Esc or a lost pad
  opens the pause menu.

### music
- `LESSONS.md` only. MusicPlayer loads last, after Settings has made the Music bus.

### endings
- `ending_card.gd` (deleted by endings, given pad input by title-menu): deleted; the pad input moved to
  CutscenePlayer (see fixes).
- `floor_scene.gd`: title-menu's checkpoint, pause and resume `_ready` kept, with endings' `hurt`
  hook. `_run_earned` became `RunState.pension_earned` everywhere (the checkpoint keeps writing it as
  `run_earned`, which `Game.abandon_run` reads). `_ending_due` left the checkpoint, since the ending is
  chosen as the run ends. Play time and the run timer both tick in `_process`. The music still stops
  on the last clear before the Chairman's or Augustine's scene.
- `run_state.gd`, `npc.gd` (typing blips and Gerald's look), `waiting_room.gd` (pause and the Back
  Room's won visit, music and the department hook), `smoke_driver.gd` (resume, controller, Augustine
  and ending checks): both sides kept.

### items
- `player.gd`: the swing sound plays after the items reshape the swing; the dodge sound moved into
  `start_dodge`; the sand steps still crunch.
- `floor_scene.gd`: the items' Pension is wired by `_wire_item_pension()` in both a new run and a
  resumed one; the effect context and combo banner wiring joined title-menu's `_ready`; a new floor
  tells the items (`floor_start`) before the checkpoint is written.
- `room_view.gd`: pickups keep their sounds and checkpoint marks beside the rarity colours and item
  hooks. A heal takes the Game tab's "heals at full" option or an item's wish
  (`_run.can_take_heal() or _run.effects.accepts_pickup(HEAL)`). The free item keeps its rarity colour
  and is marked free for the checkpoint. `test_game_options` reads the new rule.
- `progress_data.gd`, `hud.gd`, `combat_feedback.gd`, `waiting_room.gd`: both sides (endings and item
  news, timer and combo banner, knocks and slow time).
- `test_cosmetics.gd`: the never-sold hats include Gerald's hat and leave out the Reaper's Hood and the
  Captain's Hat, which items moved to the Decor Office.

## Fixes after the merges

- **Play the title music on the title screen** (055d438): `MusicPlayer.play(MusicRules.title())`, as
  the music branch asked.
- **Play the ending music under the ending scenes** (580bd38): `MusicRules.ending_scene(id)` gives the
  ending song, or `eternal_feud` for the Eternal Feud. It plays at the end of a run and on an archive
  replay, which brings the room's song back afterwards. CutscenePlayer is loaded by tests, so it cannot
  name the MusicPlayer autoload; the scenes that start a cutscene play the music. The music test named
  EndingCard and now names EndingRules.
- **Drive the ending scenes and the Ending Archive with a controller** (e2c7c3f): any pad button and B
  move a scene's text on, the pad's interact held skips, and the skip hint follows the device in use.
  The archive adds `PadFocus` and a `leave()`, so Esc or B ends a replay before closing the panel. The
  pad-focus and prompt source tests name `cutscene_player.gd` and the archive in place of the card. The
  archive's Leave is kept quiet (`sfx` meta "") since the Waiting Room plays the close.
- **Sound the ending scenes and the Ending Archive** (930112c): the `sound` step plays through `Sfx`
  (built on two lines so `test_sfx` no longer reads the step's keys as sound names; the ending scripts
  test checks step names against `SoundBank.NAMES`), a press moving text on ticks `ui_move`, and a
  finished skip plays `ui_back`. The archive's buttons sound through the Sounds autoload's button hooks.
- **Carry the ending's run tracking through the checkpoint** (4875c7f): play time, Pension earned,
  paths taken, the boss-room pill and won Arcade visits are saved beside the RunState
  (`RunCheckpoint.ending_to_dict`/`apply_ending`), so a resumed run picks the ending it earned.
- **Give a resumed run its items' effects and combos back** (d682aef): the checkpoint appended items
  straight onto the run, so the item system never held their effects; it now uses `add_item`.
- **Add the integration screenshot probe** (0410897): `tools/probes/integration_look.gd`.

## Verification

- Tests: 1829, 0 failed (after the last fix).
- Three full loops in parallel, `git archive` copies of d682aef in `D:\grandpa-verify-int\smokeA/B/C`
  (GrandpaSmokeIntA/B/C), without the rendered music: all exit 0, both SMOKE PASS lines, every flag
  true (resume checked and controller checked included), no SCRIPT ERROR. Times: A 611 s, B 615 s,
  C 601 s. The logs were UTF-8 with a BOM.
- Music rendered into `audio/music/` in the integration worktree (25 songs, about 2 minutes) and
  imported. It is gitignored.
- Real-window screenshots from a renamed exported copy (`D:/grandpa-look-int/`): the title screen
  (menu, queue, version), Options' Video tab, the Lobby with the trophy wall's "Endings found: 0/11",
  the Ending Archive with three files and the gold pad focus on the first Replay, a floor 1 fight with
  the HUD, the shop with a rare item in blue and a cursed one in purple with its skull, and the Eternal
  Feud's scene with Gerald, the text box and the skip hint. No integration breakage was found. One
  thing that was there before the merges: in floor 1's `combat_02`, the long item name on the top-left
  `T` cell runs past the room's left edge.
- The real save's MD5s matched before and after every Godot session: save.json
  f4a62baf2984c99a2fc54ebd6dc1e308, save.json.bak ec5412ad4aa142699213a24ad7563c92. No `slot_1`
  folder was made in the real user folder.

## Save-safety fixes (2026-11-05)

A review of the save code found nine problems, all confirmed and fixed one commit each:

- **Make the slot folder before the first save** (e8356a1): `SaveStore.save_progress` makes its folder.
- **Copy the old save into slot 1 only once** (c221dfd): `user://migrated.txt` marks the copy done.
- **Make the copy into slot 1 safe to kill and retry** (0dec4b4): the backup first and the save last,
  each through a temp file; a slot 1 save that does not parse, with no marker, is copied again; a lone
  old `save.json.bak` is copied too.
- **Put the checkpoint's Pension back on resume** (94c3901): the checkpoint keeps the save's Pension, less
  what the current room paid while its fight is on; Condolences are not put back.
- **Write a start checkpoint at the first Crossroads** (089c701): kind `start`, so Save and Quit there
  keeps what `start_run` used up.
- **Delete a checkpoint that cannot be resumed** (6c92d76).
- **Read a finished temp checkpoint when run.json is missing** (f21cf7e).
- **Clear an abandoned run before paying its parachute** (6347902).
- **Treat -s as a script run in every autoload guard** (0dd155e): `RunMode.is_script_run()`.

Verified with tests (1846, 0 failed), two full loops (602 s and 620 s, every flag true), and a migration
check in a renamed copy's own user folder seeded with copies of the real save: first launch, a relaunch
after slot 1 was emptied (it stayed empty), a half-written slot file recovered, and a `-s` run that
copied nothing. The real save's MD5s never changed.

## Items batches 3 and 4 (2026-11-05)

`items` at 941bff5 (all 100 items and the 12 combos) was merged in 88de272, read with `git rev-parse`
right before the merge. Tests after the merge: 1907, 0 failed. `--import` made no new `.uid` files.

### Conflicts and how they were resolved

Each block was resolved by an explicit per-block choice (ours, theirs, both, or written text) and read
afterwards; no line was deduplicated outside LESSONS.md.

- `LESSONS.md`: both sides kept, every line.
- `run_state.gd`: the endings' tracking kept, with batch 3's `lost_max_pills`; `pension_earned` is
  declared once and serves both the endings and the Pension Fund Statement.
- `floor_scene.gd`: the checkpoint, resume and pause code kept; items' copy of the old `_ready` dropped,
  with its one new line (`_run.changed.connect(_refresh_map_items)`) moved into the merged `_ready`.
  `_on_pension_earned` keeps only `_run.pension_earned` (no `_run_earned`).
- `room_view.gd`: `arcade_settled` (the endings' won visits) beside `arcade_win_bonus`; `_buy` plays the
  till and counts the purchase, and takes a free (price 0) ware; `_create_shop_keeper(extra)` takes the
  Coupon Booklet's extra ware cells so the plan's rewards keep off them.
- `thermos.gd`: reads `fuse_time` (Pressure Cooker), then plays the hiss.
- `income_probe.gd`: the deep clears and the item arguments both kept; `args` read once.
- `test_cosmetics.gd`: the never-sold looks are `bingo_teal`, `geralds_hat` and `sooty_cane`, since batch
  4 moved the Power Tie, Aviator Sunglasses, Golf Visor and Fountain Tiara to the Decor Office.

### Fixes after the merge

- **A resumed shop keeps its extra ware's spot, its "half" prices and its purchases** (in the merge):
  `RoomView.restored_extra_cells` finds the snapshot's wares off the S cells, the snapshot keeps `half`
  per ware and the shop's `purchases` (for the Tax Refund).
- **Resume a run's items without a second on_gain** (c7d3448): `RunState.restore_item` adds an item
  through `RunEffects.add(item, false)`, and combos formed on the way skip `on_gain` too. `ItemEffect`
  has `save_state()` / `load_state()`, empty by default, with `state_of` / `load_members` helpers that
  read JSON numbers back as each member's own type. The checkpoint keeps `effects` (item id or combo id
  -> state), `lost_max_pills` and `half_pills`. Kept: the Eternal Warranty's `used`, the Expired
  Coupon's free shop this floor, the Bureaucrat's Stamp's recharge, Bubble Wrap and Second Opinion per
  floor, the Pill Organizer's heals, the Bingo Card's and Hall Pass's counters, the Knitted Cardigan's
  half pill, the Reading Glasses' and Pogo Cane's counts, the Sympathy Card's count and the Tax Refund's
  paid shops (now by room id, cleared on each floor). The five effects whose `on_gain` only shuffled
  their dice shuffle them in `load_state`. `Progress.restore_pension` still runs after `apply_run`, as
  the save-safety fix needs. Tests: `tests/test_resume_item_state.gd`.
- **Sound the key moments of the third and fourth batches** (d1cff9a): through `ctx.play_sound`, which
  `CombatFeedback.play` hands to `Sfx`. `form_filed` for the Rubber Stamps and the Bureaucrat's Stamp
  (its old `"stamp"` named no sound), `coin` for the money items, `slot_win` for a winning scratcher,
  `lethal_save` for the Warranty, `pill_heal` for the Harmonica and Family Visit, `ticket_ding` for a
  filed complaint, `shield_block` for the Lawyer's objection, `card_flip` for the Fortune Teller,
  `ui_ching` for a free shop, `slip_pickup` for a forged Slip, `steam_hiss` for the Kettle Whistle,
  `small_blast` for the Polyester Suit's zap, `charge_ready` for the Early Bird and a re-inked stamp,
  `thermos_pickup` for the Moving Boxes and the items' `chime` for the Magnifying Glass's glint. No new
  audio files. `tests/test_item_sounds.gd` checks every item sound name can play.
- **Check the map items with a controller in the full loop** (6137dd3): the Floor Plan and the Fortune
  Teller's Card only change what the maps draw, and the big map holds nothing to focus, so no PadFocus
  was needed. The controller check takes both items, sees the plan on both maps, opens the big map with
  View and closes it with B. Shop wares (the Coupon Booklet's extra one too) are pickups. Tests:
  `tests/test_items_pad.gd`.
- **The counting switches**: `counting_exact` and `counting_pills` are set every physics frame by the
  full loop, so the resume, start-checkpoint, controller and ending checks run with them; the resume
  check's `run_to_dict` comparison now includes the effects' state.
- **Add the final screenshot probe** (03bfb17, 35bfbec, 4e0febc): `tools/probes/final_look.gd`. The floor's
  first room is a live fight, so the probe keeps him alive, and it shoots the combo banner a few frames
  after it forms, since with `--fixed-fps` game time runs ahead of the probe's real-time waits.

### Verification

- Tests: 1927, 0 failed (1907 after the merge; 10 resume, 7 sound and 3 pad tests added).
- Three full loops in parallel, `git archive` copies of 6137dd3 in `D:\grandpa-verify-final\smokeA/B/C`
  (GrandpaSmokeFinA/B/C), without the rendered music: all exit 0, both SMOKE PASS lines, every flag
  true (resume checked and controller checked included), no SCRIPT ERROR. Times: A 609 s, B 610 s,
  C 617 s. The logs were plain ASCII (written through bash).
- Music rendered into `audio/music/` in the integration worktree (25 songs, about 2 minutes).
- Real-window screenshots from a renamed copy (GrandpaLookFin) in `D:/grandpa-look-final/`: the title
  screen, the Lobby, a run's HUD, a shop with Grandma's Rolling Pin (legendary, gold) and the
  Nitroglycerin Tablets (cursed, purple with the skull), the Mobility Scooter's combo banner, the big map
  with the Floor Plan's outlines and the Fortune Teller's "Senior Adjuster" and "Regional Reaper" tags,
  and the Ending Archive with the gold pad focus on the first Replay. Nothing broken by the merge. Still
  there from before: a recipe's label on floor 1 `combat_02`'s top-left T cell runs under the HUD's
  item line and past the room's left edge.
- The real save's MD5s matched before and after every Godot session: save.json
  f4a62baf2984c99a2fc54ebd6dc1e308, save.json.bak ec5412ad4aa142699213a24ad7563c92.

---

# Round-2 integration: env-art and paths-rework (2026-11-06)

The user was asleep and delegated every decision; each is logged here with its reason.

## What was merged

- **env-art at `ebc1600`** (merge `f3b455a`): tiles and props for eight paths, the Waiting Room, chests,
  doors and pickups, plus the Cinema and Seance tile and prop files. Only LESSONS.md clashed (both sides
  kept).
- **paths-rework at `45b4e3e`** (merge `351861f`): the Flashback Cinema and the Seance Hotline replace
  the Mall and Fairway's End, with save migration, the Crystal Counter and Esme, and the new bosses.
  Clashes: LESSONS.md, the art inventory's section 1.9, `Enemy._update_anim`, `tests/test_enemy_art.gd`
  and `tools/art/enemy_strips.py`.

## Decisions

- **The no-flip flag is `art_flips`.** round-2 is the trunk, so paths-rework's `EnemyDef.flips` went:
  the film reel and the Ectoplasm set `art_flips = false`, `Enemy._update_anim` keeps round-2's form,
  and the tool, the seance enemy test and the art inventory say `art_flips`.
- **test_enemy_art keeps both branches' checks.** ARTED is round-2's list less the three retired
  exports (club_golfer, mall_santa, thaddeus_fairweather) plus the new-path ones; mall_cop's art is
  read through `WORN_BY` (airport_mall_cop), since mall_cop.tres is retired. Both "never mirrored"
  tests stay: round-2's over all five south-drawn objects, and paths-rework's, renamed, over the two
  halved ones with its box-size check. The two boss-anim tests became one (paths-rework's, which also
  accepts `_anim(enemy, ...)`) over both branches' bosses. Both "own anim plays through the windup"
  tests stay (the Undertaker's and Zara's).
- **No Mall or golf art to delete.** env-art never drew `golden_years_mall` or `fairways_end` tiles or
  props, and the retired enemies' strips went with paths-rework.
- **film_reel `roll` and Ectoplasm `wobble`: nothing to do.** paths-rework had already built them into
  `idle` and `walk`, and no code plays `roll` or `wobble`.
- **No `art_set` for the Cinema and Seance.** `FloorDef.art()` falls back to the floor's id, and the
  tile folders are named `flashback_cinema` and `seance_hotline`, so the floors load them as they are.
  A test now checks both floors resolve to a complete set.
- **The Cinema and Seance tiles were rebuilt onto their real palettes.** env-art drew them before the
  floors existed, on tones of its own (`EXTRA_TONES`), which differed a lot from paths-rework's palettes
  (the hotline's walls were indigo in the art, teal in the palette). paths-rework's lit-contrast checks
  are all against the palette, so the tiles now take the palette's tones.
- **Prop mapping** (code class -> picture in `art/props/<set>/`):
  - `CinemaSeat` -> `seat_row`, one per cell;
  - `CinemaPillar` -> `pillar`, standing on the code plinth so the whole solid cell shows;
  - `AisleLight` -> `aisle_light`;
  - `LifeSign` (the lobby easel) -> `lobby_card`;
  - `PsychicDesk` -> `psychic_desk` for both sizes. The art is one desk a cell wide, so a wide desk
    shows two side by side rather than one stretched;
  - `SeanceTable` (large) -> `seance_table`, on a dark rug of its cloth colour. The 44x39 picture is
    smaller than the 64x64 body, and the rug shows what is solid. The small table keeps its drawing;
  - `LavaLamp` -> `lava_lamp`, already named so;
  - `BeadedCurtain` -> `beaded_curtain`, drawn by columns so the strands still part round Grandpa.
- **Left in code.**
  - The hotline's partition (`SeancePartition`): env-art's `seance_hotline/cubicle_wall.png` came out a
    10x16 framed poster, not a partition, so the file and its manifest line were deleted.
  - The Cinema's screen (`CinemaScreen`): the memory-scene pictures fill the screen wall, and the 101x59
    `screen_frame.png` fits neither. The file stays for a later pass.

## The newpaths2 art (arrived during the merge)

- **The three returning enemies get their own art ids.** round-2 already wears `bingo_caller`,
  `soot_ghost` and `notary_public` strips on the older floors, so building the new exports under those
  ids would have redrawn reviewed enemies. They were built from a scratch copy whose folders were
  renamed `seance_bingo_caller`, `seance_soot_ghost` and `cinema_notary_public`, and those three .tres
  files dropped their `art_id`, so each wears its own art with no recolour. Before the drop,
  `cinema_notary_public` briefly wore the base notary's art.
- **No scaling.** The figures stand 44, 28 and 47 px tall, against round-2's 42 to 43 for the same
  bodies. The soot ghost is a low blob, which suits its 18x24 box.
- **Cuts**, read from contact sheets: the bingo caller's windup 1-3 and attack 5-7 (frame 4's ball in
  flight would double the game's own thrown ball); the soot ghost's 1-3 and 4-6; the notary's 2-4 (the
  stamp overhead) and 5-7 (the slam).
- **Crabtree's star** spins through `star_spin.png`, a frame every 0.08 s, else the still `star.png`,
  else the drawn star. A star projectile now redraws each physics frame; nothing else in its flight
  changed.
- **The tumbleweed** rolls through `tumbleweed_roll.png`, a quarter turn every 14 px and backwards going
  west, on whole pixels. The newpaths2 `tumbleweed.png` (24x24) replaced paths-rework's 32x32 one, and
  the rotated picture and then the drawing remain the fallbacks.

## Verification

- **Suite:** 2205 tests, 0 failed, no script error on the merged tree; 2206 after the prop wiring; 2207 on
  the final tree (`7aeae08`), each in a `git archive` copy (GrandpaIntT). One failure on the way: the
  hotline's returning-enemy test still expected the base art ids, updated to the new own ids.
- **Full loops** of `df5c378` (the merges, tiles, props and probe) in `D:\grandpa-verify-int-1` and `-2`
  (GrandpaInt1, GrandpaInt2), run together: both exited 0 with both SMOKE PASS lines, 10 paths cleared
  each, no SCRIPT ERROR in either log. One more loop of `7aeae08`, since a star projectile now redraws
  in `_physics_process`, in `D:\grandpa-verify-int-1` (GrandpaInt1): exit 0, both SMOKE PASS
  lines, no SCRIPT ERROR.
- **Screenshots** in `D:\grandpa-shots-int\` (`env_art_look.gd` for the Cinema, the Seance Hotline, the
  Records Basement and the Waiting Room; `enemy_art_look.gd` in `enemies\`; `cinema_look.gd attacks` in
  `cinema_attacks\`; `tumbleweed_and_star_check.png` from a throwaway probe). Seen:
  - env-art tiles show on all four (teal Cinema carpet, violet hotline carpet with teal walls, stone
    basement, brown lobby carpet); props read, warnings stay red on every floor, no red floods;
  - the mint safe-spot ring shows only as the mark by Harold, never in a floor tile;
  - lit floor and Harold, sampled: Cinema 0.39 / 0.53, hotline 0.21 / 0.55, basement 0.44 / 0.71;
  - the new enemies' body luminance: notary 0.41, bingo caller 0.59 (the probe's diff); the soot ghost
    hides in smoke when idle, so the probe's diff found nothing, and its walking body samples 0.49 from
    the shot;
  - the star spins (its flying shot happened to catch the thin edge-on frame); the tumbleweed rolls on
    its lane both ways (the Cinema probe's own flying shot had its lane off camera).
- **Left open:** the Cinema's `screen_frame.png` and a hotline partition picture, if wanted, need art at
  the sizes the code draws; the small seance table could use a picture of its own.
