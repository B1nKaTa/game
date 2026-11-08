# Writes build_info.txt, the build id the game shows on the title screen, the pause menu and the first
# line of display_log.txt (scripts/core/build_info.gd). Run it before every export (docs/release/build-steps.md).
#   powershell -File tools/stamp_build.ps1                 stamps this checkout's HEAD into its own root
#   powershell -File tools/stamp_build.ps1 -Out D:\copy    stamps into another folder, such as a git archive copy
# The commit comes from git here, since the game cannot run git. Without the file the game reads "dev".
param(
    [string]$Out = "",
    [string]$Commit = "HEAD"
)
$root = Split-Path $PSScriptRoot -Parent
if ($Out -eq "") { $Out = $root }
if (-not (Test-Path (Join-Path $Out "project.godot"))) { Write-Output "No project.godot in $Out"; exit 2 }
$short = (& git -C $root rev-parse --short=7 $Commit).Trim()
if ($LASTEXITCODE -ne 0 -or $short -notmatch '^[0-9a-f]{7,40}$') { Write-Output "git could not name commit $Commit"; exit 1 }
$date = Get-Date -Format "yyyy-MM-dd"
$path = Join-Path $Out "build_info.txt"
# UTF-8 without a byte order mark, and LF, so the game's parser sees exactly these lines.
[System.IO.File]::WriteAllText($path, "commit=$short`ndate=$date`n", (New-Object System.Text.UTF8Encoding($false)))
Write-Output "Stamped build $short ($date) into $path"
