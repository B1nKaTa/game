param(
	[Parameter(Mandatory = $true)][string]$Probe,
	[int]$TimeoutSec = 280,
	[string]$GodotArgs = "--headless --fixed-fps 60",
	[string]$UserArgs = "",
	[string]$Root = ""
)
# Guards the real save around any probe: backs up, runs with a hard timeout, restores, diffs.
# Root defaults to the worktree this script is in. Prefer running probes in an export_copy.ps1 copy.
$godot = "D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
$root = if ($Root) { $Root } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path }
$scratch = "D:\grandpa-verify"
New-Item -ItemType Directory -Force $scratch | Out-Null
$user = Join-Path $env:APPDATA "Godot\app_userdata\Grandpa"
$guard = Join-Path $scratch "guard_$PID"
New-Item -ItemType Directory -Force $guard | Out-Null
$files = @("save.json", "save.json.bak", "keys.json")
$before = @{}
foreach ($f in $files) {
	$p = Join-Path $user $f
	if (Test-Path $p) { Copy-Item $p (Join-Path $guard $f) -Force; $before[$f] = (Get-FileHash $p).Hash } else { $before[$f] = "absent" }
}
$out = Join-Path $scratch "probe_out_$PID.txt"
$err = Join-Path $scratch "probe_err_$PID.txt"
$argLine = "$GodotArgs --path `"$root`" --script `"$Probe`""
if ($UserArgs) { $argLine += " -- $UserArgs" }
$proc = Start-Process -FilePath $godot -ArgumentList $argLine -PassThru -NoNewWindow -RedirectStandardOutput $out -RedirectStandardError $err
if (-not $proc.WaitForExit($TimeoutSec * 1000)) {
	Write-Output "PROBE TIMED OUT after $TimeoutSec s, stopping only its own process $($proc.Id)"
	Stop-Process -Id $proc.Id -Force
	$proc.WaitForExit(5000) | Out-Null
}
Get-Content $out | Where-Object { $_ -notmatch '^(Godot Engine|\s*$)' }
Get-Content $err | Where-Object { $_ -match 'ERROR|error' } | Select-Object -First 20
foreach ($f in $files) {
	$p = Join-Path $user $f
	$now = if (Test-Path $p) { (Get-FileHash $p).Hash } else { "absent" }
	if ($now -ne $before[$f]) { Write-Output "SAVE GUARD: $f changed, restoring" }
	if (Test-Path (Join-Path $guard $f)) { Copy-Item (Join-Path $guard $f) $p -Force } elseif (Test-Path $p) { Remove-Item $p -Force }
	$after = if (Test-Path $p) { (Get-FileHash $p).Hash } else { "absent" }
	if ($after -ne $before[$f]) { Write-Output "SAVE GUARD FAILED for $f" }
}
Write-Output "save guard ok: $(($files | ForEach-Object { $_ + '=' + $before[$_].Substring(0,[Math]::Min(8,$before[$_].Length)) }) -join ' ')"
Remove-Item $guard -Recurse -Force
Remove-Item $out, $err -Force -ErrorAction SilentlyContinue
