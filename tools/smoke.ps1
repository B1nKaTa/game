$godot = if ($env:GODOT) { $env:GODOT } else { "D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
if (-not (Test-Path $godot)) { Write-Output "Godot not found at $godot"; exit 2 }
$root = Split-Path $PSScriptRoot -Parent
& $godot --headless --path $root --import *> $null
$output = & $godot --headless --path $root -- --smoke 2>&1 | ForEach-Object { "$_" }
$code = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
if ($output -match "SCRIPT ERROR|Parse Error") { Write-Output "FAILED: script errors found"; exit 1 }
if ($code -ne 0 -or -not ($output -match "SMOKE PASS")) { exit 1 }
exit 0
