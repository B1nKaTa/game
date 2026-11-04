# Waiting Room overhaul: what has not been run yet

On 2026-11-04 the user put testing on hold. Everything on `waiting-room` from 3d1f790 onward was written without being parsed or run by Godot. The first test session below ran it all. The chunk notes further down are kept as they were written, and this section says which of them still stand.

## First test session: results (2026-11-04, 2ce4093 to 9dd88ed)

### Verified
- **Import:** clean on the first run, with no parse or load errors. The 32 new `.uid` files are committed (2ce4093).
- **Tests:** `1098 tests, 0 failed`, with no `SCRIPT ERROR`. Only one test was stale: the five floors' coverage tests did not exempt the department room type (b852ab8).
- **Full loop:** 7 passes in 7 runs after one fix, each with both `SMOKE PASS` lines, every Waiting Room flag true, and "mini bosses beaten: 6".
  - **The fix:** the loop's in-memory Furnace Works clear was written to disk by the arrival's departments-seen save (e01672b).
  - **Flakes:** none.
- **The real save, loaded read-only:**
  - every upgrade level is intact, and the forms at their milestone take option a
  - Bounty Office, Training Yard, Apothecary Wing and Boiler Room open, and announce once
  - four mementos hang, and four letters arrive unread
  - 0 Condolences, and ticket 14 counts as already called
- **The dev Waiting Room:**
  - the real F4 key works both ways with no panel open
  - the hint fits the bottom wall, and "DEV PROFILE" clears the HUD
  - the profile's own save is byte for byte the same afterwards, and `save_dev.json` is gone
- **Screenshots:** every one owed below is taken, in `D:\grandpa-shots-wr\`. The ones taken before the layout fixes are in `before-fixes\`.

### Fixed because of the screenshots
- **The new-departments notice:** six names filled the 640 px line edge to edge, so it now runs three names a line (068c68b).
- **The poster board:** its prompt printed over the board's WANTED title, and now sits higher (8844b40).
- **The lobby lanterns:** the two lanterns under the ticket line moved from columns 6 and 11 to 3 and 13 (78c55e7).
- **The trophy wall:** the empty-frame captions "Smokey" and "Mortimer" ran together, so alternate captions are now staggered (839f70b).
- **Hats and bands:**
  - Every hat floated above his hair, and the band lay across his beard.
  - `HEAD` is now (0, -18) and `CHEST` (0, 1), measured on the sprite (abdd12c).
- **The Mall's white tile:** the tiara and the candy stripe cane all but vanished there, and now have dark edges (194c779).
- **The potion panel:** the Apothecary's panel was see-through, and now has an opaque backing (9dd88ed).

### Still open
- **The independent review:** Task 21 step 4, then step 5. After that, the push and the report (step 6).
- **The red steps:** each task's "run them to make sure they fail" step was never run, since the code came before testing. They stay unticked.
- **Looked at and left as they are:**
  - **The cane skins:** a worn skin draws the placeholder cane line pointing along his aim, over the sprite's own vertical cane, so it reads as a stick held out in front. This is the documented deviation, and the art pass should replace it.
  - **The Training Yard's closed-door hint:** "Opens when The Unkempt Cemetery is cleared" reaches the lobby's east wall over its own door, but stays inside the room.
  - **The mini bosses:** the count is the number of paths beaten, which is 6 at most, not 12. All 7 runs showed 6, but the check still counts them rather than demanding them.
  - **The Bounty panel:** its rows are about 23 px tall, not the guessed 20, so the list scrolls a row sooner. Leave still fits.
- **Play only:** the "Things to look at in play" lists below, such as how Heavy Head and Long Stride feel, whether the letter line nags, and the placeholder looks of NPCs and hats.

## First test session

Do these in order. First check that no game window is open, and record the real save's MD5. It is `EC5412AD4AA142699213A24AD7563C92`.

1. **Import:** run `--headless --import` once, so the new class names get their `.uid` files and enter the class cache.
2. **Fix parse errors:** check the scripts one by one with `--check-only` until none is left.
3. **Get `tools/test.ps1` green:** read the summary line, and expect "N tests, 0 failed" with no `SCRIPT ERROR`.
4. **Run 3 smoke runs:** export the commit with `git archive`, rename `config/name` in the copy, and run `tools/smoke.ps1` there. Each run must print both `SMOKE PASS` lines, with every Waiting Room flag true.
5. **Load a copy of the real save, read-only:** copy it into the scratchpad, never into the game's user folder. Run Task 21 step 3's one-off probe, then delete the probe.
6. **Take the screenshot pass:** every screenshot listed as owed below, in all four chunks.
7. **Get an independent review:** Task 21 step 4, read-only, over `git diff third-floor...waiting-room`.

Afterwards, check the real save's MD5 again.

## Test files to run
- Chunk 1 (Tasks 1–6):
  - new: `tests/test_save_migration.gd` with its fixture `tests/fixtures/save_v1_2026-11-04.json`, `tests/test_departments.gd`, `tests/test_mementos.gd`
  - changed: `tests/test_dev_start.gd`

## Watch for on the first run
- **Arrays:** typed versus untyped array equality in `assert_eq(open_ids(...), [..])`.
- **Constant data:** the nested dictionaries in `const ALL: Array[Dictionary]`, the constant entries of `Departments.STATIONS`, and `merchant.duplicate()` of constant dictionaries in `waiting_room.gd`.
- **The full loop and mementos:** once mementos hang, later runs change Pension and pill counts. The name badge adds 10 Pension at run start, the bedpan heals an extra pill, and the coal shovel and top hat change pills. Adjust the loop's exact-number checks.
- **Arrival notice:** the "New departments open: …" line with five names may be wider than 640 px.
- **Back Room tables:** the `G` cells don't build tables yet. That is Task 19 or 21.
- **Seeing every department: the dev Waiting Room.** The `--dev-all-departments` flag is gone, since `Game.return_to_waiting()` ended its profile before the Waiting Room could read it.
  - **Way in:** in a debug build, press F4 in the Waiting Room. It reloads the Waiting Room under `Progress.begin_dev_run(DevStart.progress(..., true))`, a throwaway profile with every department open. "DEV PROFILE" shows in the bottom right of every department, and the lobby's DEV hint says what F4 does.
  - **Ways out:** each one ends the profile and brings back the real progress exactly as it was.
    - F4 again reloads the real Waiting Room.
    - F3 starts the Floor 3 dev run on a fresh profile of its own.
    - The run door starts the same Floor 3 dev run on the dev Waiting Room's profile, since `floor_scene` treats any run under a dev profile as one. That run ends on return, so you come back to the real Waiting Room.
    - Quitting the game ends it, through `Progress._notification` (window close) and `Progress._exit_tree`.
  - **The real save:** every save goes to `user://save_dev.json` while it is on, and that file is deleted on the way out. Pension and Condolences earned or spent there are thrown away. `Game.toggle_dev_waiting_room` stops the scene being left before swapping profiles, so nothing in it can save into the other one.
  - **Check on the first run:**
    - F4 works with no panel open.
    - The hint line fits on the lobby's bottom wall.
    - "DEV PROFILE" clears the HUD.
    - Leaving with F4 leaves the real save's MD5 as it was.

## Things to look at in play
- Lobby layout: the run door is at (26,8), inside the room, and the trophy wall is at (20,3).
- The trophy wall shows one notice per memento.

## Chunk 2 (Tasks 7–10)

Written on 2026-11-04, from 149fec2 to e716e52. None of it has been parsed or run.

### Test files to run
- new: `tests/test_forms.gd` (Tasks 7, 8 and 9) and `tests/test_condolences.gd`
- changed: `tests/test_stats.gd`, `tests/test_dentures.gd` (option A's +0.25 bite from level 2 is now expected), `tests/test_floor_map_view.gd`, `tests/test_save_migration.gd` and `tests/test_hud.gd`

### Watch for on the first run
- **The upgrade `.tres` files:** each now has two `stat_effect.gd` sub-resources and `load_steps=5`. Check that all seven load, and that `Content.upgrades()` still finds seven.
- **`PlayerStats` names `Thermos.BLAST_RADIUS`:** a core script now reaches a world node class. If that makes a load cycle, move the constant somewhere neutral.
- **Shipped forms now apply option A from their milestone:** any existing check built on shipped upgrades at level 2 or more can shift. `test_dentures` is updated. In the full loop's dev run, every form is maxed, so Grandpa has the cane swinging at 0.9 speed, one more pill, +20% enemy Pension, a bigger blast and harder bites. Look for exact-number checks there.
- **Pension sources:** boss coins and chest coins now use the reward rate and enemy coins the enemy rate. With no Bribed Clerk at level 2 or more nothing changes, but the full loop's Pension checks should be reread.
- **`Health.heal_bonus`** applies to every heal that restores anything, potions and healing rooms included.
- **The weak spot:** `PlayerStats.strike_damage` divides `enemy.hp` by `maxf(enemy.max_hp(), 1.0)`. Check that `hp` is the live value and not scaled in some other way.
- **Calls on `_bank`:** `RoomView` calls `_bank.add_condolences` on a `Node`-typed `_bank`, the same duck-typed pattern it already uses for `spend`.
- **Two notices at once:** a chest's "+3 Condolences" notice replaces the chest's own line, and a boss's "+N Condolences" can land at the same moment as other boss notices.

### Screenshots still owed (the plan asks for them)
- The Black Market panel at its fullest: five forms, a milestone row showing both "File:" buttons, and the FILED stamp mid-animation. The panel is 600 px wide at (20,16), with 10 px row text.
- The Optometrist panel: Prescription Glasses has its milestone at level 1, so the first purchase is the choice.
- The refile panel with all seven forms.
- The HUD in the Waiting Room with 9999 Pension and 9999 Condolences, and during a run with a "+N Condolences" pop-up.
- The Night Vision map: an unfound secret room as an outline with a "?", on both the mini map and the big map.
- The forms counter board at lobby (11,3), between the Black Market (6,3) and the north door.

### Things to look at in play
- Heavy Head (0.9 swing speed) only stretches the lock between swings. The attack animation still plays for `CaneCombo.LOCK_TIME`.
- The Long Stride dodge lasts 0.26 s instead of 0.2 s, and the dodge ghosts follow it.

## Chunk 3 (Tasks 11–14)

Written on 2026-11-04, from 5bac79e to d2873e1. None of it has been parsed or run.

### Test files to run
- new: `tests/test_bounties.gd` (Tasks 11 and 12) and `tests/test_training_yard.gd` (Tasks 13 and 14)
- changed: `tests/test_departments.gd` (a placement test for `Departments.NPCS`), `tests/test_stats.gd` (16 items), `tests/test_recipes.gd` and `tests/test_shop.gd` (the base item counts leave out bounty items)

### Watch for on the first run
- **New class names:** `BountyDef`, `BountyBoard`, `BountyPanel`, `PosterBoard`, `DummyBehavior`, `TrainingDummy`, `CoachTips` and `ItemRackPanel` have no `.uid` and are not in the class cache yet. The `.tres` headers name `script_class="BountyDef"`. Run `--headless --import` first.
- **The item pool:** four `from_bounty` items join `Content.items()`. Shops, vaults and boss choices go through `can_offer`, so they stay out until won, but any full-loop check that counts items left to offer should be reread.
- **The poster match:** `ProgressData.bounty_matches_boss` compares the poster id with the boss's EnemyDef id. `test_there_is_a_poster_for_every_mini_and_floor_boss` pins that they are equal.
- **The Thermos in the yard:** `Player` only spends a Thermos when `bomb_requested` has a connection. The scene connects it on entering the yard and disconnects it on leaving. Check that a Thermos thrown in the yard is not spent elsewhere, and that leaving with a fuse burning gives no extra Thermos after the reset.
- **The dummy:** it is an `Enemy` with `wall_mounted`, spawned through `RoomView.spawn_fixture`, so `_alive` counts it. It never dies, so `_finish_room` is never called twice. `TrainingDummy` skips non-finite health, so a dismiss (an `INF` hit) would still remove the dummy. Nothing in the yard dismisses enemies today. Check that this stays true.
- **Healing in the yard:** a hit while in the yard heals Grandpa in full. The bedpan memento's first-heal bonus is spent on the Waiting Room's own run, which is thrown away.
- **`npc.talk()` with Dolores:** she says her line and opens the panel when a poster is ready. A press with the panel open is ignored.
- **The scroll list:** `BountyPanel` sizes its `ScrollContainer` from a guessed `ROW_HEIGHT` of 20 px at a 9 px font. If the rows are taller, the list scrolls sooner. If they are shorter, a gap shows under them.

### Screenshots still owed (the plan asks for them)
- The Bounty panel with every poster showing (the dev Waiting Room, F4), with one taken, and with one ready to collect. Check that the twelve rows and the Leave button fit in 360 px.
- The poster board at (6, 2) with the TAKEN mark, and the station prompt above it.
- The dummy hit by a combo, a charged swing, the teeth and a Thermos, each showing a number.
- The item rack panel with all six recipes, and the coach's bubble.

### Things to look at in play
- **Deviation:** the poster board stands at (6, 2), not (10, 2), since (10, 2) is one cell from the north door cell, which the station test forbids.
- Dolores's NPC look is the shopkeeper placeholder (cap, apron and moustache), and so is the coach's.
- The coach's first-visit lines stay until Grandpa re-enters the yard or takes an item, even after the first talk marks him met.
- The tips name mouse buttons and Space as placeholders. Check them against the real bindings.

## Chunk 4 (Tasks 15–20)

Written on 2026-11-04, from 07d3cca to e6a93ab. None of it has been parsed or run.

### Test files to run
- **New:**
  - `tests/test_cosmetics.gd` (Tasks 15 and 16)
  - `tests/test_tickets_and_letters.gd` (Tasks 17 and 18)
- **Changed:**
  - `tests/test_arcade_room.gd`: the Back Room's tables, the Dealer, and the Arcade Dealer's two new lines
  - `tests/test_save_migration.gd`: the fixture's five letters arrive unread
- **The full loop:** `tools/smoke_driver.gd` has eleven new checks, and it now prints a second `SMOKE PASS waiting room: ...` line.

### Watch for on the first run
- **New class names:** `CosmeticDef`, `LobbyDecor`, `DecorPanel`, `GrandpaLook`, `TicketRules`, `LetterBook`, `TicketPanel` and `NoticeboardPanel`. The 16 `data/cosmetics/*.tres` headers name `script_class="CosmeticDef"`. Import first.
- **Load order:**
  - `ProgressData` and `TicketRules` name each other, but only inside functions. If that still makes a cycle, move `call_ticket`'s event constants into `ProgressData`.
  - `Departments.BACK_ROOM_GAMES` reads `ArcadeTable`'s constants, so loading `Departments` now loads a world node script.
- **Colours:** the cosmetic colours are written with 9 significant digits. The tests compare them with `is_equal_approx`.
- **A static call on an instance:** the smoke driver calls `scene.now_serving(...)` on the Waiting Room scene. It is static, which is allowed but may warn.
- **The cane line:** with a cane skin worn, the Player's `_draw` draws the cane line under the sprite, since a node's own drawing sits below its children. Check the screenshot that it shows past his hand. If it doesn't, move it into `GrandpaLook`.
- **The swing arc:** it now takes the cane's colour, lifted towards white below a luminance of 0.55 (`GrandpaLook.arc_color`). Without a skin it is the old `ffe58a`.
- **The full loop:**
  - **Forms:** it now files the Reinforced Cane to level 2 and ends on Lightweight, where it used to file Better Knees to level 1. Every run after the first swings 20% faster with 5% less cane damage, and has no Better Knees level. Look for fight checks that were tuned to the old start.
  - **Pension:** it starts with 1000 Pension for the forms, where it used to start with 500. After filing and refiling about 790 is left.
  - **The landing heal:** the check now adds `first_heal_bonus` and `heal_bonus`. In the second run the bedpan can still hold its bonus at the first landing.
  - **The cursed run:** the die run after the ticket check is cursed, so its enemies have 1.25 times the health. It only walks a path and dies, so nothing should notice.
  - **Rare failures:**
    - `_check_back_room` plays the two tables with seed 47. The checks are exact payout checks, as in the Arcade.
    - `_check_training_yard` swings from 28 px left of the dummy. If the swing misses, no number shows. Move him or aim lower.
    - The Thermos goes off at his feet in the yard and heals at once. Check the blast never ends the scene.
  - **Mini bosses:** the loop asserts the six floor bosses' first beats, and counts the mini bosses rather than demanding them. Read the count in the PASS line, and tighten the check to 12 if it is always 12.
  - **The dev run:** the save check compares the save file before and after the dev run. On returning, the Waiting Room calls the ticket, but saves only when a ticket was called, so the file should stay the same.
- **The ticket on return:** `Progress.call_ticket` runs on every arrival in the Waiting Room, including `Game.return_to_waiting()` without a run. It saves only when the number moved.
- **Arrival notices:** after a run on a called number, the queue holds the department news, the ticket's line and "A letter has arrived…". Check none is lost.
- **The cursed run's notices:**
  - At its start, the cursed notice replaces the name badge's.
  - A floor cleared in it shows "+10 Condolences" for the curse, which can land at the same moment as the boss's first-beat notice.

### Screenshots still owed (the plan asks for them)
- **The Decor Office panel:**
  - both tabs, the Grandpa tab with all 10 rows, and the four "Bounty reward" rows
  - that the Leave button fits in 360 px
- **The lobby:**
  - bare
  - with all six decor items: the fern at (2, 2), the poster at (9, 1), the chair at (3, 8), the lamps at (8, 1) and (26, 1) with their light, the tank at (27, 2), and the 10×5 carpet under the middle
- **Grandpa's looks:** in each hat, each cardigan and each cane, standing, walking and swinging. Take them in the lobby and on the Mall's palest tile. Check the hat at `GrandpaLook.HEAD` (0, -22) and the band at `CHEST` (0, -5) against the 68 px frame.
- **The lobby's top line:** "YOUR TICKET: N   NOW SERVING: 666" from x = 164, which runs over the wall lanterns at columns 6 and 11. Check it with "Called!" too, and that it ends before the north door at x = 480.
- **The ticket machine at (23, 3):** the red box with its paper tongue.
- **The ticket panel:** with a deal and a cursed offer showing.
- **The noticeboard:** at (23, 7) with its NEW mark, and its panel with six letters and one open.
- **The Back Room:** the room itself, and a hand of blackjack there.

### Things to look at in play
- **Deviations from the plan:**
  - **Lobby spots:** the second lamp hangs at (26, 1), not (21, 1), which the trophy frames cover. The fish tank stands at (27, 2), not (27, 8), beside the run door.
  - **The cursed notice:** it reads "Cursed ticket: tougher enemies, better pay", since the curse raises health, not damage. The plan said "they hit harder".
  - **No thanks:** the ticket panel's "No thanks" turns the offer down for the visit, through a new `decline_cursed_ticket`.
  - **A deal with nothing to sell:** with every form filed in full, the clerk's deal calls nothing.
  - **The NOW SERVING number:** it shows the called number whenever this visit's ticket is a called number, not only on the visit it was first called.
  - **Cane skins:** a worn cane skin draws the placeholder cane line even over the sprite.
  - **The full loop's buttons:** it presses the panels' real buttons, and closes each panel with its Leave button, since the Waiting Room's panels don't close on interact.
- **The arrival line:** "A letter has arrived on the noticeboard" plays on every visit while any letter is unread, as the plan says. It may nag.
- **The Back Room:**
  - The Dealer stands at about (7, 2), where `merchant_cell` puts him, near the top wall, so his bubble may flip below him.
  - The tables are solid `ArcadeTable` blocks at (7, 5) and (12, 5).
- **Cosmetic placeholders:** the hood, the tiara and the stripe bands are rough code drawings. Judge whether each reads at game scale.

## Review fixes

Written on 2026-11-04, from 0767e6c onwards, after a read-only review. None of it has been parsed or run.

### Test files to run
- **Changed:**
  - `tests/test_forms.gd`: the blast radius lives in `PlayerStats.BASE_BLAST_RADIUS`, and `PlayerStats` names no `Thermos` constant
  - `tests/test_training_yard.gd`: a form filed or refiled during the visit counts in the yard, and the scene refreshes the run's stats
  - `tests/test_tickets_and_letters.gd`: a clerk's deal with every form maxed shows no "Called!"
  - `tests/test_dev_start.gd`: the dev Waiting Room's profile, its key and gate, and that it never writes the real save on any way out

### Watch for on the first run
- **`Thermos.BLAST_RADIUS`** is now `const BLAST_RADIUS := PlayerStats.BASE_BLAST_RADIUS`. Check that the constant resolves, and that the default argument of `Thermos.in_blast` still takes it.
- **Refreshing stats:** closing any panel now works his stats out again, and outside the yard it resets his Thermoses to a run's start. In the full loop, check nothing that pads the Waiting Room run's stats is undone by a panel closing.
- **Source pins:** three new tests read `waiting_room.gd` and `game.gd` as text, since a test cannot load a script that names autoloads. If one fails after a harmless rewrite, update the substring it looks for.
- **The dev Waiting Room:** see "Seeing every department" under the first test session's notes.
