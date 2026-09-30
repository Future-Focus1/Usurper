param(
    [string]$Godot = 'P:\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe'
)

$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$consoleGodot = $Godot -replace '\.exe$', '_console.exe'
if (Test-Path -LiteralPath $consoleGodot -PathType Leaf) { $Godot = $consoleGodot }
$releaseTemplate = Join-Path $projectRoot 'build\template-cache\windows_release_x86_64.exe'
if (-not (Test-Path -LiteralPath $releaseTemplate -PathType Leaf)) {
    throw 'Place the official Godot 4.6.3 windows_release_x86_64.exe export template in build/template-cache. The project export preset uses that exact version.'
}
$outputDirectory = Join-Path $projectRoot 'build\windows'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
& $Godot --headless --path $projectRoot --editor --import --log-file (Join-Path $outputDirectory 'import.log')
if ($LASTEXITCODE -ne 0) { throw "Import failed: $LASTEXITCODE" }
if (Select-String -LiteralPath (Join-Path $outputDirectory 'import.log') -Pattern '^(SCRIPT ERROR:|ERROR:)' -Quiet) { throw 'Import reported a script/resource error.' }
& $Godot --headless --path $projectRoot --export-release 'Windows Desktop' (Join-Path $outputDirectory 'Usurper.exe') --log-file (Join-Path $outputDirectory 'export.log')
if ($LASTEXITCODE -ne 0) { throw "Windows export failed: $LASTEXITCODE" }
if (Select-String -LiteralPath (Join-Path $outputDirectory 'export.log') -Pattern '^(SCRIPT ERROR:|ERROR:)' -Quiet) { throw 'Export reported a script/resource error.' }
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs\licenses\GODOT-LICENSE.txt') -Destination (Join-Path $outputDirectory 'GODOT-LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs\licenses\GODOT-COPYRIGHT.txt') -Destination (Join-Path $outputDirectory 'GODOT-COPYRIGHT.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets\fonts\OFL.txt') -Destination (Join-Path $outputDirectory 'FONT-LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs\PLAYER_GUIDE.txt') -Destination (Join-Path $outputDirectory 'READ_ME.txt')
$builtGame = Join-Path $outputDirectory 'Usurper.exe'
$hash = Get-FileHash -LiteralPath $builtGame -Algorithm SHA256
"$($hash.Hash.ToLower())  Usurper.exe" | Set-Content -LiteralPath (Join-Path $outputDirectory 'SHA256.txt')
$releaseFiles = 'Usurper.exe', 'READ_ME.txt', 'GODOT-LICENSE.txt', 'GODOT-COPYRIGHT.txt', 'FONT-LICENSE.txt', 'SHA256.txt' | ForEach-Object { Join-Path $outputDirectory $_ }
Compress-Archive -LiteralPath $releaseFiles -DestinationPath (Join-Path $projectRoot 'build\Usurper-Windows-1.0.0.zip') -CompressionLevel Optimal -Force
Write-Output "Built $builtGame"
