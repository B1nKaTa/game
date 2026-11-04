param([string]$Commit = "HEAD", [string]$Cases = "max good 20 0 3 bosses", [string]$Tag = "base", [switch]$NoExport)
# Runs the simulated player (bot_probe.gd) from an exported copy of this worktree with its own user
# folder, several cases at once (separate cases with ";"). Outputs bot_<tag>_<case>.txt in D:\grandpa-verify\bot.
$here = $PSScriptRoot
$s = "D:\grandpa-verify\bot"
New-Item -ItemType Directory -Force $s | Out-Null
$root = "D:\grandpa-verify\botroot"
$g = "D:\new-etf\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
if (-not $NoExport) {
	& (Join-Path $here "export_copy.ps1") -Dest botroot -Name GrandpaBot -Commit $Commit | Out-Null
}
$caseList = $Cases -split ";"
$jobs = foreach ($c in $caseList) {
	Start-Job -ArgumentList $s, $root, $c, $g, $Tag, $here -ScriptBlock {
		param($s, $root, $c, $g, $Tag, $here)
		$o = Join-Path $s ("bot_" + $Tag + "_" + ($c -replace ' ','_') + ".txt")
		$p = Start-Process -FilePath $g -ArgumentList "--headless --fixed-fps 60 --path `"$root`" --script `"$here\bot_probe.gd`" -- $c" -PassThru -NoNewWindow -RedirectStandardOutput $o -RedirectStandardError "$o.err"
		if (-not $p.WaitForExit(1800000)) { Stop-Process -Id $p.Id -Force; "KILLED $c" }
		"== $c"
		Get-Content $o | Where-Object { $_ -match 'SUMMARY|WALL|hits by source|SCRIPT ERROR' }
		Get-Content "$o.err" | Where-Object { $_ -match 'SCRIPT ERROR|Parse Error' } | Select-Object -First 3
	}
}
$jobs | Wait-Job | Receive-Job
$save = Join-Path $env:APPDATA "Godot\app_userdata\Grandpa\save.json"
"real save " + (Get-FileHash $save -Algorithm MD5).Hash
