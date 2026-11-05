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
