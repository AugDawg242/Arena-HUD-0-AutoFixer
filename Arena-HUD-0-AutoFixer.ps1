$ErrorActionPreference = 'Stop'
$dir = 'C:\Riot Games\League of Legends\Config'
$log = Join-Path $PSScriptRoot 'Arena-HUD-0-AutoFixer.log'
$intervalSeconds = 15
$heartbeatSeconds = 60
$maxBackupsPerFile = 5
$sessionBackups = @{}
$checks = 0
$corrections = 0
$correctionsByFile = @{'game.cfg'=0; 'PersistedSettings.json'=0}
$lastStatus = @{'game.cfg'='Unknown'; 'PersistedSettings.json'='Unknown'}
$lastHeartbeat = Get-Date

function Write-Log([string]$message, [ConsoleColor]$color = [ConsoleColor]::Gray) {
    $line = '{0} | {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $message
    Write-Host $line -ForegroundColor $color
    try { Add-Content -LiteralPath $log -Value $line -Encoding UTF8 -ErrorAction Stop }
    catch { Write-Host "LOG WARNING: $($_.Exception.Message)" -ForegroundColor Yellow }
}

function Trim-Backups([string]$name) {
    $path = Join-Path $dir $name
    $backups = @(Get-ChildItem -LiteralPath $dir -File -ErrorAction Stop |
        Where-Object { $_.Name.StartsWith("$name.backup-", [StringComparison]::OrdinalIgnoreCase) } |
        Sort-Object -Property Name -Descending)
    foreach ($old in @($backups | Select-Object -Skip $maxBackupsPerFile)) {
        try {
            Remove-Item -LiteralPath $old.FullName -ErrorAction Stop
            Write-Log "BACKUP PRUNED $($old.Name)" DarkGray
        } catch {
            Write-Log "BACKUP WARNING: Could not remove $($old.Name): $($_.Exception.Message)" Yellow
        }
    }
}

function Check-And-Fix([string]$name) {
    $path = Join-Path $dir $name
    if (-not (Test-Path -LiteralPath $path)) {
        $lastStatus[$name] = 'Missing'
        Write-Log "WARNING: $name missing" Yellow
        return
    }
    $content = [System.IO.File]::ReadAllText($path)
    $pattern = if ($name -eq 'game.cfg') {
        '(?m)^(\s*ShowPlayerPerks\s*=\s*)([01])(?=\s*$)'
    } else {
        '("name"\s*:\s*"ShowPlayerPerks"\s*,\s*"value"\s*:\s*")([01])(")'
    }
    $match = [regex]::Match($content, $pattern)
    if (-not $match.Success) {
        $lastStatus[$name] = 'Setting not found'
        Write-Log "WARNING: ShowPlayerPerks not found in $name" Yellow
        return
    }
    if ($match.Groups[2].Value -eq '0') {
        $lastStatus[$name] = '0'
        return
    }

    if (-not $sessionBackups.ContainsKey($name)) {
        $backup = "$path.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')"
        Copy-Item -LiteralPath $path -Destination $backup -ErrorAction Stop
        $sessionBackups[$name] = $backup
        Write-Log "BACKUP CREATED $name : $backup" DarkGray
        Trim-Backups $name
    }
    $backup = $sessionBackups[$name]
    $updated = $content.Substring(0, $match.Groups[2].Index) + '0' + $content.Substring($match.Groups[2].Index + 1)
    [System.IO.File]::WriteAllText($path, $updated, (New-Object System.Text.UTF8Encoding($false)))
    $verify = [regex]::Match([System.IO.File]::ReadAllText($path), $pattern)
    if ($verify.Success -and $verify.Groups[2].Value -eq '0') {
        $script:corrections++
        $correctionsByFile[$name]++
        $lastStatus[$name] = '0'
        Write-Log "FIXED $name : 1 -> 0 | Total corrections: $corrections | Backup: $backup" Green
    } else {
        $lastStatus[$name] = 'Verification failed'
        Write-Log "ERROR: Could not verify correction in $name" Red
    }
}

Write-Log "STARTED | Checking every ${intervalSeconds}s | Status every ${heartbeatSeconds}s | One backup per file/session | Retain $maxBackupsPerFile per file | Q = quit" Cyan
foreach ($name in @('game.cfg', 'PersistedSettings.json')) {
    if (Test-Path -LiteralPath $dir) {
        try { Trim-Backups $name }
        catch { Write-Log "BACKUP WARNING: Cleanup failed for $name : $($_.Exception.Message)" Yellow }
    }
}
Write-Log 'This edits files on disk only; the running game may not reload HUD settings.' Yellow

while ($true) {
    $checks++
    foreach ($name in @('game.cfg', 'PersistedSettings.json')) {
        try { Check-And-Fix $name }
        catch {
            $lastStatus[$name] = 'Error'
            Write-Log "ERROR checking $name : $($_.Exception.Message)" Red
        }
    }
    $now = Get-Date
    if (($now - $lastHeartbeat).TotalSeconds -ge $heartbeatSeconds -or $checks -eq 1) {
        $state = 'game.cfg={0}; PersistedSettings.json={1}' -f $lastStatus['game.cfg'], $lastStatus['PersistedSettings.json']
        Write-Log "HEARTBEAT | $state | Checks: $checks | Corrections: $corrections (cfg=$($correctionsByFile['game.cfg']), json=$($correctionsByFile['PersistedSettings.json']))" Cyan
        $lastHeartbeat = $now
    }
    for ($i = 0; $i -lt ($intervalSeconds * 10); $i++) {
        try {
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                if ($key.Key -eq 'Q') {
                    Write-Log "STOPPED | Checks: $checks | Corrections: $corrections" Cyan
                    exit
                }
            }
        } catch { }
        Start-Sleep -Milliseconds 100
    }
}
