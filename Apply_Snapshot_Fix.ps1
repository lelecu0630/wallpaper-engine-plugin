$ErrorActionPreference='Stop'
$base=Join-Path $env:LOCALAPPDATA 'WallpaperEngineMCP\0.1.0\plugins\wallpaper-engine-local'
$target=Join-Path $base 'windows.ps1'
$source=Join-Path $PSScriptRoot 'windows.ps1'
if(-not (Test-Path -LiteralPath $target)){throw 'Installed windows.ps1 not found'}
Copy-Item -LiteralPath $target -Destination ($target+'.snapshot-backup-'+(Get-Date -Format 'yyyyMMddHHmmss'))
Copy-Item -LiteralPath $source -Destination $target -Force
$cache=Join-Path $env:USERPROFILE '.codex\plugins\cache\wallpaper-local\wallpaper-engine-local'
if(Test-Path -LiteralPath $cache){Get-ChildItem -LiteralPath $cache -Directory | ForEach-Object {$f=Join-Path $_.FullName 'windows.ps1';if(Test-Path -LiteralPath $f){Copy-Item -LiteralPath $f -Destination ($f+'.snapshot-backup') -Force;Copy-Item -LiteralPath $source -Destination $f -Force}}}
& node (Join-Path $base 'diagnose.mjs')
if($LASTEXITCODE -ne 0){throw 'Patched, but diagnostics failed. Share the error above.'}
Write-Host 'Patch applied. Inspect diagnostic capture dimensions. Blank or unavailable windows are not a successful capture.'
