# Contact damage: verified 2026-11-05

Checked on `round-2` with Godot 4.7.2: headless import clean; `tools/test.ps1` 1972 tests, 0 failed, with exit-time leak lines identical to `integration` 85e7162 (3 Body2D RIDs, 3 CanvasItem RIDs, 6 ObjectDB instances, 2 resources); three full loops in `git archive` copies (D:\grandpa-verify-r2-1..3) all passed in 615, 627 and 625 s, with exit leaks matching an `integration` loop run alongside (627 s) and no warning line that loop lacks. The save guard held: slot_1/save.json stayed 510284fa2ead4647c94fee44f99ca787. Screenshots are in D:\grandpa-shots-r2\ (tools/probes/round2_look.gd, and golf_look.gd into golf\).

- `_check_contact` ran and passed in all three loops; no other pill check moved.
- Screenshots c1_* (Records Basement) and c2_* (midnight course): a touch flashes Grandpa solid red and takes a pill, the shove carries him out, a dodge passes through with no pill lost. Reads clearly.
- Fixed: the shove is now sized from the body it must clear (`ContactRule.shove(..., body, feet_size)`). The plain 29 px shove could not clear a boss's 44 by 52 body from its middle, and the Commodore's memento halves every shove. Tested in test_contact.gd.
- Balance: contact cost the floor-4 bosses 3 to 6 bot wins in 20 (integration: Commodore 9, Thaddeus 3; round-2: Commodore 1 to 6, Thaddeus 0 to 1). Most touches come from bodies moving into him (charges, carts) or from escaping through a boss, not from walking into one. The bot (v7) now keeps off bodies and names touches `touch_<id>`.
- Still for a person: whether boss bodies costing a pill (charges through him, standing at a chart) feel fair; the Steam Valve's touch; the Wreath of Thorns through walls.

The original list of owed checks follows.

## Contact damage: checks still owed

Testing went on hold partway through this branch. One unit run finished before the hold: `tools/test.ps1` gave
1947 tests, 0 failed (1927 before, plus the 20 in `tests/test_contact.gd`). Nothing else has run. Every check
below still has to be done.

## What to run

1. `powershell -File tools/test.ps1`: expect 1947 tests, 0 failed. Before trusting it, compare the exit-time
   leak lines with a run on `integration` (85e7162). The run on this branch ended with "3 RID allocations of
   type 'P11GodotBody2D' were leaked" and "6 ObjectDB instances were leaked". If `integration` shows fewer,
   a test in `tests/test_contact.gd` leaves a CharacterBody2D (Player or Enemy) unfreed.
2. Two full loops in `git archive` copies under `D:\grandpa-verify-contact\` (GrandpaSmokeConA/B), as
   `.claude/skills/add-floor/checklist.md` section 2 shows. Read the whole log: it may be UTF-16 or UTF-8
   with a BOM. The new check is `_check_contact` in `tools/smoke_driver.gd`, run from `_check_fight_room`
   after `_check_shield`. None of its lines has ever run.
3. Real-window screenshots from a renamed exported copy (`tools/probes/export_copy.ps1`, `run_probe.ps1`)
   into `D:/grandpa-look-contact/`. Take three: walking into an enemy (the red flash), the shove that follows,
   and a dodge through a body. No look probe has been written for this yet.
4. Save guard. Record the MD5s of `%APPDATA%\Godot\app_userdata\Grandpa\save.json`, `.bak` and `slot_1\*`
   before and after every session. Before this branch they were:
   - save.json: f4a62baf2984c99a2fc54ebd6dc1e308
   - save.json.bak: ec5412ad4aa142699213a24ad7563c92
   - slot_1/save.json: 510284fa2ead4647c94fee44f99ca787
   - slot_1/save.json.bak: f4a62baf2984c99a2fc54ebd6dc1e308

   They were the same after the one unit run.

## Risky spots to check first

- **`_check_contact` timing.** It puts his feet 6 px right of a frozen Intern Reaper. It expects one pill gone
  within 0.5 s and his feet out of the body 0.3 s later. The shove is 180 px/s for 0.16 s, about 29 px, and
  it goes through `Player.push`. The loop's `_physics_process` sets `steady_feet = false`, so Gravity Boots
  from the dev kit should not swallow it. If the "shoves him out" line fails, print his feet and `is_pushed()`
  for each frame.
- **The dodge line.** He starts 36 px left of the body and dodges right for 0.2 s at 300 px/s, about 60 px,
  so he should end 24 px past the body's middle. The body's half width (10) plus his feet box's half width
  (7) is 17, so he should end clear. If a dodge item in the loop's run shortens or changes the dodge, he could
  end inside the body. The grace after a hit would then fail "a dodge costs nothing" at the frame the dodge
  ends.
- **`contact_off` everywhere else.** The loop sets `ctx.contact_off = not _contact_check` every physics frame,
  so every other check sees the old rules. If any pill check fails anyway, look for a path where the driver's
  `_physics_process` returns early: no `player` on the scene, the Waiting Room or a cutscene. The player
  could then touch a body there.
- **Arrival and door checks.** The loop keeps contact off, so these should not move. In play, a shove that
  lands on a door frame is ended by `FloorScene._enter_room`, as every push is.
- **Wreath of Thorns.** It now pricks over his body merged with his feet box (`Wreath.body_of`), which reaches
  9 px lower than before. Its unit test passed. Check in play that it does not prick through walls more than
  it did.
- **Boss rework.** Augustine and the Chairman are being reworked in another worktree. Their bodies cost 1 like
  every boss. At merge time, check that neither stands its body on a spot he must cross, such as a safe spot
  or a gap mark. If one does, set `contact_damage = 0` on that def, or add an `is_sleeping` override for that
  phase.
- **The Steam Valve.** It is wall-mounted, but it is an enemy with a body on a floor cell, so touching it
  costs a pill. That was chosen on purpose. Confirm it reads fairly in a screenshot.
- **The balance bot** (`tools/probes/bot_probe.gd`) was not changed and does not avoid bodies yet. Its next
  numbers will include contact hits. Compare them only against bot runs on this branch, not earlier ones.
