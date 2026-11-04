param([string]$Dest = "copy", [string]$Name = "GrandpaVerifyCopy", [string]$Commit = "HEAD", [string]$Worktree = "")
# Exports a commit of a worktree (default: the one this script is in) into D:\grandpa-verify\<Dest>
# under its own project name, so it gets its own user folder and never touches the real save.
if (-not $Worktree) { $Worktree = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path }
$sp = "D:\grandpa-verify"
New-Item -ItemType Directory -Force $sp | Out-Null
$dir = Join-Path $sp $Dest
$godot = "D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
New-Item -ItemType Directory $dir | Out-Null
$tar = Join-Path $sp ("{0}.tar" -f $Dest)
git -C $Worktree archive $Commit --format=tar -o $tar
tar -xf $tar -C $dir
Remove-Item $tar
$project = Join-Path $dir "project.godot"
$text = [IO.File]::ReadAllText($project) -replace "`r`n", "`n"
$text = $text.Replace('config/name="Grandpa"', ('config/name="{0}"' -f $Name))
[IO.File]::WriteAllText($project, $text, (New-Object System.Text.UTF8Encoding($false)))
if (-not (Select-String -Path $project -Pattern $Name -Quiet)) { "RENAME FAILED"; exit 3 }
& $godot --headless --path $dir --import *> $null
"EXPORTED $Commit to $dir as $Name"
