param([string]$CodexPath, [string]$WallpaperEnginePath, [string]$WorkshopPath)
$ErrorActionPreference='Stop'
try {
 $node=(Get-Command node.exe -ErrorAction Stop).Source
 if(-not $WallpaperEnginePath){
  $running=Get-Process wallpaper64,wallpaper32 -ErrorAction SilentlyContinue | Select-Object -First 1
  if($running -and $running.Path){$WallpaperEnginePath=Split-Path $running.Path}else{$WallpaperEnginePath=Join-Path ${env:ProgramFiles(x86)} 'Steam\steamapps\common\wallpaper_engine'}
 }
 if(-not $WorkshopPath){$steamapps=Split-Path (Split-Path $WallpaperEnginePath);$WorkshopPath=Join-Path $steamapps 'workshop\content\431960'}
 if(-not (Test-Path -LiteralPath (Join-Path $WallpaperEnginePath 'wallpaper64.exe'))){throw 'Wallpaper Engine not found. Pass -WallpaperEnginePath and -WorkshopPath.'}
 if(-not $CodexPath){
  $cli=Get-Command codex.exe -ErrorAction SilentlyContinue
  if($cli){$CodexPath=$cli.Source}else{
   $candidate=Get-ChildItem -LiteralPath (Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin') -Filter codex.exe -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
   if($candidate){$CodexPath=$candidate.FullName}
  }
 }
 if(-not $CodexPath -or -not (Test-Path -LiteralPath $CodexPath)){throw 'Codex CLI not found. Pass -CodexPath with the installed codex.exe path.'}
 $base=Join-Path $env:LOCALAPPDATA 'WallpaperEngineMCP\0.1.0'
 $plugin=Join-Path $base 'plugins\wallpaper-engine-local'
 New-Item -ItemType Directory -Path $plugin -Force | Out-Null
 # Copy only known source files, never cache snapshots, logs or user wallpaper files.
 foreach($name in @('server.mjs','windows.ps1','package.json','test.mjs','diagnose.mjs','README.md')){Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination $plugin -Force}
 $manifestDir=Join-Path $plugin '.codex-plugin'
 New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
 Copy-Item -LiteralPath (Join-Path $PSScriptRoot '.codex-plugin\plugin.json') -Destination $manifestDir -Force
 $utf8=New-Object System.Text.UTF8Encoding($false)
 [IO.File]::WriteAllText((Join-Path $plugin 'config.json'),(@{installPath=$WallpaperEnginePath;workshopPath=$WorkshopPath}|ConvertTo-Json),$utf8)
 $mcp=@{mcpServers=@{wallpaper_engine=@{command=$node;args=@((Join-Path $plugin 'server.mjs'));cwd=$plugin;enabled=$true;startup_timeout_sec=20;tool_timeout_sec=30}}}
 [IO.File]::WriteAllText((Join-Path $plugin '.mcp.json'),($mcp|ConvertTo-Json -Depth 8),$utf8)
 $catalog=Join-Path $base '.claude-plugin'
 New-Item -ItemType Directory -Path $catalog -Force | Out-Null
 $market=@{name='wallpaper-local';interface=@{displayName='Wallpaper Engine Local'};plugins=@(@{name='wallpaper-engine-local';source=@{source='local';path='./plugins/wallpaper-engine-local'};policy=@{installation='AVAILABLE';authentication='ON_INSTALL'};category='Productivity'})}
 [IO.File]::WriteAllText((Join-Path $catalog 'marketplace.json'),($market|ConvertTo-Json -Depth 8),$utf8)
 & $node (Join-Path $plugin 'diagnose.mjs')
 if($LASTEXITCODE -ne 0){throw 'Diagnostics failed; plugin has not been registered.'}
 & $CodexPath plugin marketplace add $base
 if($LASTEXITCODE -ne 0){throw 'Marketplace registration failed.'}
 & $CodexPath plugin add 'wallpaper-engine-local@wallpaper-local'
 if($LASTEXITCODE -ne 0){throw 'Plugin installation failed. Check the Plugins Directory.'}
 Write-Host 'Installed. Restart ChatGPT desktop / Work mode and enable Wallpaper Engine Local.'
 Write-Host ('Installed files: '+$plugin)
}catch{Write-Error $_;exit 1}
