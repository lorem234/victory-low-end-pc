# run.ps1 -Exe <victory.exe> -Game <game.exe> [-Console series-s] [-MipDrop 3]
#         [-DisplayMode 1280x720] [-CardBuffersMB 512] [-KeepEnv]
# Starts the title with the fork's low-memory Windows settings.
# NOT TESTED ON WINDOWS BY US: every measurement of this repository was made under Linux/Wine.
# Every VICTORY_* variable already in your environment is cleared first (except the path variables
# VICTORY_CONFIG, VICTORY_GAME_DIR, VICTORY_CACHE_DIR, VICTORY_DATA_DIR), so that a value left over
# from another fork's guide cannot replace a default. -KeepEnv keeps them (they then win over
# the values below) and lists every override.
# Run it from a normal PowerShell window, not as administrator, or through run.cmd beside it.
param(
    [Parameter(Mandatory)][string]$Exe,
    [Parameter(Mandatory)][string]$Game,
    [ValidateSet('series-s', 'series-x')][string]$Console = 'series-s',
    [ValidateRange(0, 3)][int]$MipDrop = 3,
    [ValidateSet('1280x720', '1600x900', '1920x1080')][string]$DisplayMode = '1280x720',
    [ValidateRange(0, 2048)][int]$CardBuffersMB = 512,
    [string]$Log = 'info',
    [switch]$KeepEnv
)
$settings = [ordered]@{
    # Keep the hot copies on the GPU where the adapter budget permits.
    VICTORY_CARD_BUFFERS_MB     = "$CardBuffersMB"
    VICTORY_CARD_WINDOWS_MB     = '256'
    VICTORY_TEXTURE_MIP_DROP    = "$MipDrop"
    VICTORY_LEVELS_ON_DEMAND    = '1'
    VICTORY_CARD_BUFFERS_MIN_KB = '64'
    # Commit-pressure guards for Windows: keep idle staging blocks and preludes low
    # so commit headroom isn't exhausted before the scene runs.
    VICTORY_STAGING_KEPT        = '2'
    VICTORY_MAX_PRELUDES        = '16'
    VICTORY_DISPLAY_MODE        = $DisplayMode
    # Wave-wide lowering has caused device resets on this backend.
    VICTORY_WAVE_WIDE           = '0'
    # Keep command breadcrumbs and page faults for GPU resets.
    VICTORY_D3D12_DRED          = 'light'
    # Keep DRED breadcrumbs without the per-allocation ledger.
    VICTORY_BOOK                = '0'
    VICTORY_AMBIENT             = '0.8'
    VICTORY_AMBIENT_AIR         = '1.5'
    # Avoid stalling texture refreshes on the streaming thread's mapping lock.
    VICTORY_TEXTURE_NO_WAIT     = '1'
    # The fork's launcher settings (speed).
    VICTORY_RELAY               = '2'
    VICTORY_RELAY_COPY          = '1'
    VICTORY_WIDE_BACK           = '1'
    VICTORY_CARD_REHASH_RUNS    = '1'
    VICTORY_JOIN_COPIES         = '1'
    VICTORY_INDIRECT_WINDOW     = '1'
    VICTORY_INDIRECT_BATCH      = '2'
    VICTORY_CARD_STEPS          = '2'
    VICTORY_MAP_THREADS         = '1'
    VICTORY_CARD_AWAKE          = '1'
    VICTORY_SHOW_AFTER          = '1'
    VICTORY_UPLOAD_AHEAD        = '1'
    VICTORY_THIN                = '1'
    VICTORY_JOIN_PARTS          = '8'
    # "info" prints the frame statistics line ("... fps, ... ms/frame (... preparing ...)") that RESULTS.md
    # quotes; it exists only in a build made with --features diagnostics (README, Windows, step 3).
    VICTORY_LOG                 = $Log
}
if (-not (Test-Path $Exe))  { Write-Host "No $Exe. Build it first (README.md, Windows)."; exit 2 }
if (-not (Test-Path $Game)) { Write-Host "No $Game. Pass the executable of your own copy of the title."; exit 2 }
$paths = 'VICTORY_CONFIG', 'VICTORY_GAME_DIR', 'VICTORY_CACHE_DIR', 'VICTORY_DATA_DIR'
if (-not $KeepEnv) {
    Get-ChildItem Env:VICTORY_* | Where-Object { $_.Name -notin $paths } | ForEach-Object { Remove-Item "Env:$($_.Name)" }
}
foreach ($k in $settings.Keys) {
    if (-not (Test-Path "Env:$k")) { Set-Item "Env:$k" $settings[$k] }
}
# What the title will run with: every VICTORY_* variable, and a warning for each one that differs from
# the default (possible only with -KeepEnv).
$differ = @()
foreach ($k in $settings.Keys) {
    $now = (Get-Item "Env:$k").Value
    if ($now -ne $settings[$k]) { $differ += "$k=$now (default: $($settings[$k]))" }
}
Write-Host "victory-gtx1660: settings in effect:"
Get-ChildItem Env:VICTORY_* | Sort-Object Name | ForEach-Object { Write-Host "  $($_.Name)=$($_.Value)" }
if ($differ.Count -gt 0) {
    Write-Host "victory-gtx1660: overrides to the Windows defaults:" -ForegroundColor Yellow
    $differ | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
}
$Exe = (Resolve-Path $Exe).Path
$Game = (Resolve-Path $Game).Path
Push-Location (Split-Path $Exe)
try { & $Exe run $Game --execute --console $Console } finally { Pop-Location }
exit $LASTEXITCODE
