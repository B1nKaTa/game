# Verification checklist for a new floor

Run nothing here while the user has said testing is on hold. Run every step from the floor's own
worktree or an exported copy of it, never from the worktree the user plays from.

Godot: `D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` (the
console build; set `GODOT` if it moved). The windowed build beside it is
`Godot_v4.7.2-stable_win64.exe`.

## Around every Godot session: the window check and the save guard

Before each session, in PowerShell:

```powershell
$playing = @(Get-CimInstance Win32_Process -Filter "Name like 'Godot%'" |
  Where-Object { $_.CommandLine -notmatch '--headless' -and $_.CommandLine -match '--path' })
if ($playing.Count -gt 0) { $playing | ForEach-Object { "PLAYING: $($_.ProcessId) $($_.CommandLine)" } } else { "clear" }
(Get-FileHash "$env:APPDATA\Godot\app_userdata\Grandpa\save.json" -Algorithm MD5).Hash
```

If anything prints `PLAYING`, do not launch. Wait, or ask. Write the MD5 down. After the session,
take the MD5 again: it must be identical. If it changed, stop, restore from your backup and tell the
user. For any probe that runs real scenes, also copy `save.json`, `save.json.bak` and `keys.json`
from `%APPDATA%\Godot\app_userdata\Grandpa\` to the scratchpad first and restore them after. Never
hardcode the MD5: it changes whenever the user plays.

`tools/test.ps1` and `tools/smoke.ps1` are safe for the save: tests never touch it, and `--smoke`
makes `Progress` use `user://smoke_save.json`.

## 1. Tests: 0 failed

```powershell
powershell -File tools/test.ps1
```

- Read the summary line, `N tests, M failed`, and search the output for `SCRIPT ERROR` and
  `Parse Error`. Never pipe it through `tail` or `Select-String` and trust the piped exit code.
- After new class names: run `& $godot --headless --path . --import` once first. On a parse error,
  check scripts one by one with `--check-only --script <path>` and fix the first error.
- Afterwards `git checkout -- art/sprites` clears line-ending-only `.import` churn.
- When a new check fails rarely, reproduce it by forcing the state (layout by arrival side) rather
  than rerunning, and never relax it before you know the cause.

## 2. Three full loops, in `git archive` copies on D:

Each copy gets its own `config/name`, so it gets its own user folder and cannot touch the real one,
and all three can run at once while work goes on. Commit first: the copy is of a commit, not the
working tree.

```powershell
$repo = "C:\GameDev\game\.worktrees\<floor-branch>"
$commit = (git -C $repo rev-parse HEAD)
$godot = "D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
foreach ($tag in "A", "B", "C") {
  $dest = "D:\grandpa-verify\smoke$tag"
  if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
  New-Item -ItemType Directory -Force $dest | Out-Null
  git -C $repo archive --format=zip -o "$dest.zip" $commit
  Expand-Archive -Path "$dest.zip" -DestinationPath $dest -Force
  Remove-Item "$dest.zip"
  $proj = Join-Path $dest "project.godot"
  $text = [System.IO.File]::ReadAllText($proj) -replace "`r`n", "`n"
  $text = $text -replace 'config/name="Grandpa"', "config/name=`"GrandpaSmoke$tag`""
  [System.IO.File]::WriteAllText($proj, $text)
  if (-not (Select-String -Path $proj -Pattern "GrandpaSmoke$tag" -CaseSensitive -Quiet)) { "RENAME FAILED $tag" }
}
```

Then run each one (in the background, one Bash or PowerShell call per copy) and keep the whole log:

```powershell
$env:GODOT = $godot; powershell -File D:\grandpa-verify\smokeA\tools\smoke.ps1 *> D:\grandpa-verify\smokeA.log; "exit=$LASTEXITCODE"
```

- Pass means exit 0, both `SMOKE PASS ...` lines (the run line and `SMOKE PASS waiting room: ...`),
  every flag in them true, and no `SCRIPT ERROR` anywhere in the log. Report the run time.
- If a run goes far past its usual time, a parse error in `tools/smoke_driver.gd` can hang it: run
  Godot directly on the copy with output redirected and read the first error.
- The Funeral Parlour's arrival check ("he arrives standing on the door") flaked once. Reproduce a
  flake by forcing its layout and arrival side before relaxing anything.
- Afterwards delete the copies and their user folders:

```powershell
Remove-Item -Recurse -Force D:\grandpa-verify
Get-ChildItem "$env:APPDATA\Godot\app_userdata" -Directory -Filter "GrandpaSmoke*" | Remove-Item -Recurse -Force
```

If a safety check blocks a delete, say so in the report and ask the user to delete it (as with
`D:\grandpa-verify-tmp` on 2026-11-04). C: has filled up before, so keep copies on D:.

## 3. Screenshots of every new attack, in a real window

- Write a screenshot probe (`extends SceneTree`), starting from a copy of the floor-3 probe in
  `tools/probes/floor3_look.gd`, which writes its PNGs to `D:/grandpa-verify/shots/floor3/`. Load the
  new `EnemyDef` and `FloorDef` files directly (a probe made before the floor is wired shows the old
  bosses otherwise), build the room, keep Grandpa alive by setting run fields directly, and save
  `get_viewport().get_texture().get_image()` to PNGs.
- Run it **without** `--headless`, from an exported copy with a renamed `config/name`, after the
  window check: `& <windowed godot> --path D:\grandpa-verify\look --script <probe> -- <args>`.
- Wait with `Time.get_ticks_msec`, never by counting frames (a real window runs far above 60 fps).
  Start the probe with `call_deferred`, give it a timer that quits with an error, await
  `process_frame` before simulating input, and drive aim through the player's `aim_source`.
- Shoot: every attack at the middle of its windup and as it lands, the heaviest attack's warning,
  any safe spot, the hazard, each prop and each enemy, small, medium and large rooms, each effect
  and the HUD over the floor's palest tile in a large room, any new panel at its fullest, and the
  boss bar's name in each boss shot.
- **Open every PNG with the Read tool and look at it.** Fix what does not read (floor 3 fixed the
  overlay backing, the HUD band, the perfume and wet colours, and the crescendo's safe spot this way).

## 4. Balance bot, compared with earlier floors

- The simulated player and the income probe are in `tools/probes/`: `bot_probe.gd` and
  `income_probe.gd` (the floor-3 versions). Run the bot with
  `powershell -File tools/probes/run_bot.ps1 -Cases "max good 20 0 3 bosses;some good 20 0 3 bosses" -Tag <tag>`.
  That exports a renamed copy with `export_copy.ps1` to `D:\grandpa-verify\botroot` and writes its
  results to `D:\grandpa-verify\bot\`. For a single probe, `tools/probes/run_probe.ps1 -Probe <path>`
  backs up and restores the save files and stops only its own process on a timeout. Delete
  `D:\grandpa-verify` when you are done.
- Bot arguments after `--`: `<fresh|some|max> <average|good> <runs> <path index> <depth> [bosses|haul]`.
  It writes its own `user://probe_*.json`, never the real save.
- First teach it every new warning, hazard and safe spot, as v4 was taught the floor-3 ones.
- Calibrate on a build with a known result, run 20 boss fights per boss on "some" and "max" with
  `good`, and whole floors with `haul`. Batches swing (Mortimer measured 7 to 15 of 20 unchanged), so
  run more than one batch before tuning, and call results estimates.
- Compare against the floor-3 numbers in `docs/playtest-notes.md` (the "Third floor tested and
  balanced" entry). Targets: mini bosses at least equal to the last depth's, floor bosses clearly
  harder but winnable on a strong save, regular rooms not walls.
- Income per full clear with and without blasting. Floor 3: about 258 (Parlour) and 271 (Mall)
  against 231 (Sunset Shores). Measure; don't trust multipliers on small whole numbers.
- Tune health, windups, rests and summon timers first. Record every change before and after in
  `docs/playtest-notes.md`.

## 5. Independent review

Use the superpowers:requesting-code-review skill. One reviewer on the strongest model, read-only,
over `git diff <base-branch>...<floor-branch>`, against the spec, told in its brief not to run Godot
in any form or touch `%APPDATA%\Godot\app_userdata\Grandpa\`. Verify each finding by reading the
code (superpowers:receiving-code-review), fix confirmed ones one commit each with a test, then
repeat steps 1 and 2.

## 6. The report

Write `docs/night-report-<date>.md` in the shape of `docs/night-report-2026-11-04.md`: how to play
it (the exact launch command and worktree), what was built, what was checked (test count, full loops
with run times, screenshot count, the save's MD5 unchanged, the review), fixed during testing,
balance (rough), decisions waiting for the user, what to try first, housekeeping. Update
`docs/playtest-notes.md` and `LESSONS.md`, push, and stop for the user to play. Do not merge.

## Commit and push

```bash
cd /c/GameDev/game/.worktrees/<floor-branch>
file <every touched file>            # CRLF kept? no BOM?
git add <paths> && git commit -F /path/to/scratchpad/msg.txt && git show --stat HEAD | head -20
env -u GIT_TERMINAL_PROMPT -u GCM_INTERACTIVE git push -u origin <floor-branch>
```

The message file is imperative, one logical change, and ends with a blank line and
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. It names no other game.

## Done means all of these

- [ ] Spec approved and plan written, both in `docs/superpowers/`
- [ ] Both paths wired: `PATHS_BY_DEPTH`, `LAST_DEPTH`, `LANDINGS_BY_DEPTH`, `FIRST_PATH_BY_DEPTH`, `PATHS_AT_DEPTH`
- [ ] Each path: hazard, 3 new and 2 returning enemies, mini boss, floor boss, about 33 valid rooms, palette
- [ ] Waiting Room: department, memento, two posters each, letter, the six-path test lists extended
- [ ] `tools/test.ps1`: `N tests, 0 failed`, no script errors
- [ ] 3 of 3 full loops pass in `git archive` copies on D:, copies and user folders deleted
- [ ] Every new attack, hazard, prop and room size screenshotted in a real window and looked at
- [ ] Balance bot and income compared with earlier floors, changes recorded
- [ ] Independent review done, findings verified and fixed
- [ ] Real save MD5 unchanged from the start
- [ ] Report, playtest notes and lessons written, branch pushed, user told it is ready to play
