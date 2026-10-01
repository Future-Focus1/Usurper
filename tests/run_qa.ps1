param(
    [string]$Godot = 'P:\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe',
    [ValidateSet('all', 'audit', 'layout', 'capture', 'smoke', 'frontend', 'audio')][string]$Suite = 'all',
    [string]$Resolution = '1280x720',
    [int]$Seeds = 24,
    [switch]$RecordEvidence,
    [switch]$SkipImport
)

$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$artifactRoot = Join-Path $PSScriptRoot '.artifacts'
$qaUserRoot = Join-Path $artifactRoot 'userdata'
$logRoot = Join-Path $artifactRoot 'logs'
New-Item -ItemType Directory -Path $qaUserRoot, $logRoot -Force | Out-Null
$priorAppData = $env:APPDATA
$priorIsolation = $env:USURPER_QA_USER_ROOT
$env:APPDATA = $qaUserRoot
$env:USURPER_QA_USER_ROOT = $qaUserRoot

try {
    if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) { throw "Godot executable not found: $Godot" }
    $consoleGodot = $Godot -replace '\.exe$', '_console.exe'
    if (Test-Path -LiteralPath $consoleGodot -PathType Leaf) { $Godot = $consoleGodot }
    if (-not $SkipImport) {
        & $Godot --headless --path $projectRoot --editor --import --log-file (Join-Path $logRoot 'import.log')
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "Godot import failed ($LASTEXITCODE)." }
        if (Select-String -LiteralPath (Join-Path $logRoot 'import.log') -Pattern '^(SCRIPT ERROR:|ERROR:)' -Quiet) { throw 'Godot import reported script/resource errors.' }
    }
    $scenes = switch ($Suite) {
        'all' { 'release_audit', 'week_loop_test', 'overlay_close_test', 'interaction_audit', 'frontend_campaign_audit', 'layout_audit', 'audio_test' }
        'audit' { 'release_audit' }
        'layout' { 'layout_audit' }
        'smoke' { 'smoke_runner' }
        'capture' { 'visual_capture' }
        'frontend' { 'frontend_campaign_audit' }
        'audio' { 'audio_test' }
    }
    foreach ($scene in $scenes) {
        $arguments = @('--path', $projectRoot, '--resolution', $Resolution, '--log-file', (Join-Path $logRoot "$scene-$Resolution.log"))
        if ($Suite -ne 'capture') { $arguments += '--headless' }
        $arguments += @('--scene', "res://tests/$scene.tscn", '--', "seeds=$Seeds", "viewport=$Resolution", "capture_dir=$artifactRoot/screenshots")
        & $Godot @arguments
        if ($LASTEXITCODE -ne 0) { throw "$scene failed ($LASTEXITCODE). Inspect $logRoot." }
        if (Select-String -LiteralPath (Join-Path $logRoot "$scene-$Resolution.log") -Pattern '^(SCRIPT ERROR:|ERROR:)' -Quiet) { throw "$scene reported a runtime error despite returning zero." }
    }
    if ($RecordEvidence) {
        $evidenceRoot = Join-Path $projectRoot 'docs/qa-results'
        New-Item -ItemType Directory -Path $evidenceRoot -Force | Out-Null
        foreach ($reportName in @('release_audit.json', 'frontend_campaign_audit.json', 'winning_replays.json')) {
            $reportPath = Join-Path $artifactRoot $reportName
            if (Test-Path -LiteralPath $reportPath -PathType Leaf) {
                Copy-Item -LiteralPath $reportPath -Destination (Join-Path $evidenceRoot $reportName) -Force
            }
        }
        foreach ($layoutReport in Get-ChildItem -LiteralPath $artifactRoot -Filter 'layout_audit-*.json' -File) {
            Copy-Item -LiteralPath $layoutReport.FullName -Destination (Join-Path $evidenceRoot $layoutReport.Name) -Force
        }
        $captureSummary = @()
        $screenshotsRoot = Join-Path $artifactRoot 'screenshots'
        if (Test-Path -LiteralPath $screenshotsRoot -PathType Container) {
            foreach ($manifestPath in Get-ChildItem -LiteralPath $screenshotsRoot -Filter 'manifest.json' -Recurse -File) {
                $manifest = Get-Content -LiteralPath $manifestPath.FullName -Raw | ConvertFrom-Json
                foreach ($frame in $manifest) {
                    $captureSummary += [PSCustomObject]@{
                        resolution = $manifestPath.Directory.Name
                        screen = $frame.screen
                        pixels = $frame.viewport
                        text_controls = $frame.controls.Count
                    }
                }
            }
            $captureSummary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $evidenceRoot 'visual_capture_summary.json') -Encoding utf8
        }
    }
} finally {
    $env:APPDATA = $priorAppData
    $env:USURPER_QA_USER_ROOT = $priorIsolation
}
