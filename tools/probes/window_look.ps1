param([Parameter(Mandatory = $true)][string]$Root, [int]$TimeoutSec = 240)
# Runs tools/probes/window_look.gd in a normal (not --script) run of an exported copy: adds it as an
# autoload to that copy's project.godot, which must already carry a renamed config/name, and starts it.
$ErrorActionPreference = "Stop"
$godot = "D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
$proj = Join-Path $Root "project.godot"
$text = [System.IO.File]::ReadAllText($proj)
if ($text -match 'config/name="Grandpa"') { Write-Output "REFUSED: the copy still has the real config/name"; exit 3 }
if ($text -notmatch 'WindowLook=') {
	$text = $text -replace '\[autoload\]\r?\n', ("[autoload]`r`n`r`nWindowLook=`"*res://tools/probes/window_look.gd`"`r`n")
	[System.IO.File]::WriteAllText($proj, $text)
}
$out = Join-Path $Root "window_look_out.txt"
$proc = Start-Process -FilePath $godot -ArgumentList "--path `"$Root`"" -PassThru -NoNewWindow -RedirectStandardOutput $out -RedirectStandardError (Join-Path $Root "window_look_err.txt")
if (-not $proc.WaitForExit($TimeoutSec * 1000)) {
	Write-Output "TIMED OUT, stopping $($proc.Id)"
	Stop-Process -Id $proc.Id -Force
}
Get-Content $out | Where-Object { $_ -match 'WINDOW|ERROR' }
Get-Content (Join-Path $Root "window_look_err.txt") | Where-Object { $_ -match 'ERROR' } | Select-Object -First 20
