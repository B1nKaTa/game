# Build Steps

How to make a zip of Grandpa that a friend can play, and that names its build in every bug report.
Do every step for every zip, in this order: archive, music, stamp, import, export.

The build id is the short commit and the day of the build, for example `build 291126a (2026-11-08)`.
It shows in the title screen's bottom-right corner, in the pause menu's bottom-right corner, and as the
first line of `%APPDATA%\Godot\app_userdata\Grandpa\display_log.txt`. A copy that was never stamped
shows `dev`, as the editor and the tests do.

## 1. Archive

Build from a clean copy of a committed state, never from a working folder with changes in it.
Run from PowerShell in the project folder (Git Bash's own tar cannot unpack onto `D:\`):

```
git archive --format=zip -o D:\grandpa-build\src.zip HEAD
Expand-Archive D:\grandpa-build\src.zip D:\grandpa-build\src
```

Tag the commit first if the build goes to players (`git tag playtest-1`), so it can be found again.

## 2. Music

The songs are not in git. Render them into the copy:

```
py tools/music/render.py D:\grandpa-build\src\audio\music
```

## 3. Stamp

Write the build id into the copy, from the project folder, since the copy is not a git checkout:

```
powershell -File tools/stamp_build.ps1 -Out D:\grandpa-build\src
```

This writes `build_info.txt` (`commit=` and `date=` lines) into the copy's root. The file is
gitignored, and `export_presets.cfg` lists it in `include_filter`, since a plain text file is not a
resource and would otherwise be left out of the export. To stamp a commit other than HEAD, add
`-Commit <hash or tag>`.

## 4. Import

```
& $env:GODOT --headless --path D:\grandpa-build\src --import
```

## 5. Export

```
& $env:GODOT --headless --path D:\grandpa-build\src --export-release "Windows Desktop" D:\grandpa-build\Grandpa.exe
```

Then zip `Grandpa.exe` alone as `Grandpa-<commit>.zip`, start it once, and check that the title
screen's corner shows the same commit as the zip's name. If it shows `dev`, step 3 was skipped.
