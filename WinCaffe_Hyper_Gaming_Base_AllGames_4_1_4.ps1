
# ==============================================================
#  WinCaffè Hyper Gaming Base - All Games Edition
#  Versione: 4.1.4 HF1
#  Autore: DarkPlayer84Tv Productions (Luigi Sestili Spurio)
#
#  Changelog v4.1.4 HF1:
#  - [SYNC] Allineato il preset con le lezioni pratiche emerse da OGD WinCaffe 8.0.13.
#  - [TUNE] Base gaming ripulita: WSearch ora resta Manual, Power Throttling lasciato nativo,
#           Game Bar/DVR puliti meglio e Fullscreen/Flip Model più coerenti.
#  - [COD] Profilo BO7 aggiornato con scheduler Win32, MMCSS Games, HAGS e DirectX settings
#          più vicini al ramo 8.0.13 senza introdurre tweak rete legacy.
#  - [WATCHER] GameWatcher reso più prudente: timer riportato a 0.5 ms e log aggiornati.
#
#  Changelog v4.1.4:
#  - [TARGET] Focus dichiarato: ottimizzazione Windows per gaming high-FPS,
#             con priorita specifica a Call of Duty: Black Ops 7.
#  - [TUNE] Base gaming confermata: Game Mode completo, DVR OFF,
#           DirectX Flip Model ON, profilo energia dedicato WinCaffe.
#  - [TUNE] Aggiunta funzione dedicata per applicare un assetto BO7 lato Windows
#           senza toccare file di gioco o anti-cheat.
#  - [CREDITS] Riferimenti: OGD_WinCaffe_8.0.9FinalTest2.ps1 e OGD_Timer_0.5ms.ps1.
#
#  Changelog v4.1.1 (precedente):
#  - [FIX] Get-NpuReport: rimossa doppia query, filtro null robusto,
#          ErrorAction SilentlyContinue su Win32_PnPEntity.
#  - [FIX] Get-FriendlyGpuReport: avviso esplicito limite CIM DWORD 32-bit (~4GB).
#  - [FIX] WSearch: avviato dopo Set-ServiceStartupIfDifferent se Stopped.
#
#  Changelog v4.1 (precedente):
#  - [FIX] Aggiunta Set-StringValueIfDifferent (idempotente per stringhe)
#  - [FIX] Apply-HyperGamingBase: Tasks\Games ora usa funzioni idempotenti
#  - [FIX] Apply-HyperGamingBase: servizi ora usano Set-ServiceStartupIfDifferent
#  - [FIX] Set-HAGS: usa Set-DwordValueIfDifferent invece di Set-DwordValue
#  - [FIX] Restore-Backups: usa Set-ServiceStartupIfDifferent
#  - [NEW] Get-NpuReport: rileva NPU (Neural Processing Unit) via CIM/PnP
#  - [NEW] New-QuickReport: sezione NPU aggiunta al report hardware
# ==============================================================

#Requires -RunAsAdministrator
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptVersion  = '4.1.4 HF1'
$ProjectName    = 'WinCaffè Hyper Gaming Base - All Games Edition'
$VendorName     = 'DarkPlayer84Tv Productions (Luigi Sestili Spurio) aka DarkPlayer84Tv'
$DocsRoot       = Join-Path $env:ProgramData 'WinCaffe\AllGames_HyperGamingBase'
$BackupRoot     = Join-Path $DocsRoot 'Backup'
$LogRoot        = Join-Path $DocsRoot 'Logs'
$StateFile          = Join-Path $BackupRoot 'state.json'
$RegistryBackupFile = Join-Path $BackupRoot 'registry-backup.json'
$ServiceBackupFile  = Join-Path $BackupRoot 'services-backup.json'
$PowerBackupFile    = Join-Path $BackupRoot 'power-backup.json'
$WatcherStateFile   = Join-Path $BackupRoot 'watcher-state.json'
$WatcherAgentPath   = Join-Path $DocsRoot 'WinCaffe_GameWatcher_Agent.ps1'
$WatcherTaskName    = 'WinCaffe Hyper Gaming GameWatcher'
$QuickReportFile    = Join-Path $LogRoot 'quick-report.txt'
$SummaryFile        = Join-Path $LogRoot 'summary.json'
$CurrentLog         = Join-Path $LogRoot ("session_{0}.log" -f (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))

New-Item -ItemType Directory -Force -Path $DocsRoot, $BackupRoot, $LogRoot | Out-Null

# ---------------------------------------------------------------
# FUNZIONI BASE
# ---------------------------------------------------------------

function Write-Log {
    param(
        [Parameter(Mandatory)] [string]$Message,
        [ValidateSet('INFO','OK','WARN','ERR')] [string]$Level = 'INFO'
    )
    $stamp = Get-Date -Format 'HH:mm:ss'
    $line  = "[$stamp] [$Level] $Message"
    Add-Content -Path $CurrentLog -Value $line -Encoding UTF8
    switch ($Level) {
        'OK'    { Write-Host $line -ForegroundColor Green }
        'WARN'  { Write-Host $line -ForegroundColor Yellow }
        'ERR'   { Write-Host $line -ForegroundColor Red }
        default { Write-Host $line -ForegroundColor Cyan }
    }
}

function Write-Banner {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor DarkCyan
    Write-Host '   WinCaffè Hyper Gaming Base - All Games Edition'           -ForegroundColor Magenta
    Write-Host ("   Versione: {0}" -f $ScriptVersion)                        -ForegroundColor White
    Write-Host '   Assetto permanente + watcher giochi automatico'            -ForegroundColor Gray
    Write-Host '============================================================' -ForegroundColor DarkCyan
    Write-Host ''
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Esegui questo script come Amministratore.'
    }
}

function Show-WinCaffeDisclaimer {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor DarkYellow
    Write-Host '   TERMINI D USO / RINGRAZIAMENTI' -ForegroundColor Yellow
    Write-Host '============================================================' -ForegroundColor DarkYellow
    Write-Host ''
    Write-Host 'Ringraziamenti' -ForegroundColor Cyan
    Write-Host 'Questo progetto utilizza anche idee, impostazioni e riferimenti derivati' -ForegroundColor White
    Write-Host 'da settaggi e profili condivisi nel tempo dalla scena OGD / WinCaffe.' -ForegroundColor White
    Write-Host 'Un ringraziamento va a chi ha contribuito a costruire, testare e diffondere' -ForegroundColor White
    Write-Host 'queste basi di tuning e ottimizzazione.' -ForegroundColor White
    Write-Host ''
    Write-Host 'Condizioni d uso' -ForegroundColor Cyan
    Write-Host 'Usando questo script confermi di farlo per tua libera scelta e sotto la tua' -ForegroundColor White
    Write-Host 'esclusiva responsabilita.' -ForegroundColor White
    Write-Host 'Ogni sistema Windows, gioco, driver, BIOS e combinazione hardware puo reagire' -ForegroundColor White
    Write-Host 'in modo diverso alle ottimizzazioni applicate.' -ForegroundColor White
    Write-Host ''
    Write-Host 'Esclusione di responsabilita' -ForegroundColor Cyan
    Write-Host 'L autore, chi distribuisce lo script e chi ha contribuito ai settaggi usati' -ForegroundColor White
    Write-Host 'come riferimento non si assumono responsabilita per cali di prestazioni,' -ForegroundColor White
    Write-Host 'instabilita, incompatibilita, perdita di configurazioni o altri effetti' -ForegroundColor White
    Write-Host 'derivanti dall uso dello script.' -ForegroundColor White
    Write-Host 'Se scegli di proseguire, accetti che ogni modifica venga eseguita su tua' -ForegroundColor White
    Write-Host 'richiesta e per tua iniziativa.' -ForegroundColor White
    Write-Host ''
    Write-Host 'Licenza opzionale' -ForegroundColor Cyan
    Write-Host 'Se il progetto verra distribuito come software libero, puo essere rilasciato' -ForegroundColor White
    Write-Host 'anche sotto GNU General Public License v3.0 (GPL-3.0), secondo la scelta' -ForegroundColor White
    Write-Host 'finale del maintainer del progetto.' -ForegroundColor White
    Write-Host 'Testo licenza: https://www.gnu.org/licenses/gpl-3.0.html' -ForegroundColor White
    Write-Host ''
    Write-Host 'Conferma' -ForegroundColor Cyan
    Write-Host 'Per continuare devi accettare esplicitamente questi termini.' -ForegroundColor White
    Write-Host ''
    $accept = Read-Host "Digita ACCETTO per continuare oppure premi INVIO per uscire"
    if ([string]::IsNullOrWhiteSpace($accept) -or $accept.Trim().ToUpperInvariant() -ne 'ACCETTO') {
        throw 'Esecuzione annullata: termini non accettati.'
    }
}

# ---------------------------------------------------------------
# FUNZIONI REGISTRO - LETTURA SICURA
# ---------------------------------------------------------------

function Get-RegistryValueSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Name
    )
    try {
        $item = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        return $item.$Name
    } catch {
        return $null
    }
}

# ---------------------------------------------------------------
# FUNZIONI REGISTRO - SCRITTURA IDEMPOTENTE
# ---------------------------------------------------------------

function Set-DwordValueIfDifferent {
    # [v4.0] Controlla il valore attuale prima di scrivere.
    # Scrive solo se mancante o diverso → log chiaro "già corretto" vs "modificato".
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][UInt32]$Value,
        [string]$Label
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    $current = Get-RegistryValueSafe -Path $Path -Name $Name
    $shown   = if ($Label) { $Label } else { "$Path -> $Name" }
    if ($null -ne $current) {
        try {
            if ([UInt64]$current -eq [UInt64]$Value) {
                Write-Log "Già impostato correttamente, salto: $shown=$current" 'INFO'
                return
            }
        } catch {
            if ([string]$current -eq [string]$Value) {
                Write-Log "Già impostato correttamente, salto: $shown=$current" 'INFO'
                return
            }
        }
    }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
    Write-Log "Registry impostato: $shown=$Value" 'OK'
}

function Set-StringValueIfDifferent {
    # [v4.1 NEW] Versione idempotente per valori di tipo String.
    # Stessa logica di Set-DwordValueIfDifferent: salta se già corretto.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Value,
        [string]$Label
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    $current = Get-RegistryValueSafe -Path $Path -Name $Name
    $shown   = if ($Label) { $Label } else { "$Path -> $Name" }
    if ($null -ne $current -and [string]$current -eq [string]$Value) {
        Write-Log "Già impostato correttamente, salto: $shown=$current" 'INFO'
        return
    }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType String -Force | Out-Null
    Write-Log "Registry impostato: $shown=$Value" 'OK'
}

# ---------------------------------------------------------------
# FUNZIONI REGISTRO - SCRITTURA DIRETTA (usate solo da Rollback)
# ---------------------------------------------------------------

function Set-DwordValue {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [UInt32]$Value
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
    Write-Log ("Registry impostato: {0} -> {1}={2}" -f $Path, $Name, $Value) 'OK'
}

function Set-StringValue {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [string]$Value
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    New-ItemProperty -Path $Path -Name $Name -PropertyType String -Value $Value -Force | Out-Null
    Write-Log ("Registry impostato: {0} -> {1}={2}" -f $Path, $Name, $Value) 'OK'
}

# ---------------------------------------------------------------
# FUNZIONI SERVIZI - IDEMPOTENTE
# ---------------------------------------------------------------

function Set-ServiceStartupIfDifferent {
    # [v4.0] Controlla lo StartMode attuale prima di modificare.
    # Salta se già nella configurazione desiderata.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][ValidateSet('Automatic','Manual','Disabled')][string]$StartupType,
        [switch]$TryStop
    )
    try {
        $svc     = Get-CimInstance Win32_Service -Filter ("Name='{0}'" -f $Name) -ErrorAction Stop
        $current = [string]$svc.StartMode
        $target  = switch ($StartupType) {
            'Automatic' { 'Auto' }
            'Manual'    { 'Manual' }
            'Disabled'  { 'Disabled' }
        }
        if ($current -eq $target) {
            Write-Log "Servizio già configurato, salto: $Name StartMode=$current" 'INFO'
        } else {
            Set-Service -Name $Name -StartupType $StartupType -ErrorAction Stop
            Write-Log "Servizio aggiornato: $Name StartMode=$StartupType" 'OK'
        }
        if ($TryStop) {
            Stop-ServiceIfRunningSafe -Name $Name
        }
    } catch {
        Write-Log ("Impossibile impostare il servizio {0}: {1}" -f $Name, $_.Exception.Message) 'WARN'
    }
}

function Stop-ServiceIfRunningSafe {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Name)
    try {
        $svc = Get-Service -Name $Name -ErrorAction Stop
        if ($svc.Status -eq 'Running') {
            Stop-Service -Name $Name -Force -ErrorAction Stop
            Write-Log "Servizio fermato: $Name" 'OK'
        } else {
            Write-Log "Servizio già fermo, salto: $Name" 'INFO'
        }
    } catch {
        Write-Log ("Impossibile fermare il servizio {0}: {1}" -f $Name, $_.Exception.Message) 'WARN'
    }
}

function Set-ServiceStartup {
    # Versione NON idempotente — usata solo internamente da Restore-Backups
    # quando si vuole forzare il ripristino del valore originale senza controlli.
    param(
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [ValidateSet('Automatic','Manual','Disabled')] [string]$StartupType,
        [switch]$TryStop
    )
    try {
        Set-Service -Name $Name -StartupType $StartupType -ErrorAction Stop
        Write-Log ("Servizio {0}: StartupType={1}" -f $Name, $StartupType) 'OK'
        if ($TryStop) {
            try {
                Stop-Service -Name $Name -Force -ErrorAction Stop
                Write-Log ("Servizio {0} arrestato." -f $Name) 'OK'
            } catch {
                Write-Log ("Servizio {0} non arrestato: {1}" -f $Name, $_.Exception.Message) 'WARN'
            }
        }
    } catch {
        Write-Log ("Impossibile modificare il servizio {0}: {1}" -f $Name, $_.Exception.Message) 'WARN'
    }
}

# ---------------------------------------------------------------
# FUNZIONE HARDWARE - GPU
# ---------------------------------------------------------------

function Get-FriendlyGpuReport {
    [CmdletBinding()]
    param()
    # Nota tecnica: Win32_VideoController.AdapterRAM e' un campo DWORD a 32-bit.
    # Il valore massimo rappresentabile e' 2^32 - 1 byte (~4GB).
    # Schede con VRAM > 4GB (es. RTX 5080 16GB, RTX 4090 24GB)
    # vengono segnalate da Windows/CIM come ~4GB: viene mostrato un avviso esplicito.
    $CIM_DWORD_MAX_BYTES = [UInt64]4294967295   # 0xFFFFFFFF
    $items = @()
    try {
        $videoControllers = Get-CimInstance Win32_VideoController -ErrorAction Stop
        foreach ($gpu in $videoControllers) {
            $name            = [string]$gpu.Name
            $adapterRamBytes = [UInt64]0
            try { $adapterRamBytes = [UInt64]$gpu.AdapterRAM } catch { $adapterRamBytes = 0 }
            $approxGB = 0
            if ($adapterRamBytes -gt 0) { $approxGB = [Math]::Round($adapterRamBytes / 1GB) }

            $note = if ($adapterRamBytes -ge $CIM_DWORD_MAX_BYTES -or $approxGB -ge 4) {
                'ATTENZIONE: CIM/WMI riporta max ~4GB (limite DWORD 32-bit). VRAM reale probabilmente superiore. Usa GPU-Z per il valore esatto.'
            } else {
                'VRAM reported by Windows/CIM (approximated)'
            }

            $items += [PSCustomObject]@{
                Name     = $name
                ApproxGB = $approxGB
                Note     = $note
            }
        }
    } catch {
        $items += [PSCustomObject]@{
            Name     = 'Unknown GPU'
            ApproxGB = 0
            Note     = 'GPU query failed'
        }
    }
    return $items
}

# ---------------------------------------------------------------
# [v4.1 NEW] FUNZIONE HARDWARE - NPU
# ---------------------------------------------------------------

function Get-NpuReport {
    # [v4.1.1 FIX] Riscritto da zero rispetto alla v4.1.
    #
    # Problema v4.1: la funzione eseguiva due query separate, la prima con
    # codice sintatticamente scorretto (Where-Object annidato con $_ ambiguo),
    # e usava -ErrorAction Stop sul Get-CimInstance principale, che in presenza
    # di dispositivi con nome $null causava eccezioni immediate.
    #
    # Soluzione v4.1.1:
    # - Una sola query con -ErrorAction SilentlyContinue (non blocca su errori parziali)
    # - Filtro esplicito su null/whitespace prima del match per keyword
    # - Keyword aggiornate per Intel Core Ultra (Arrow Lake): "AI Boost", "VPU"
    # - Intel Core Ultra 285K rilevato come "Intel(R) AI Boost" in Device Manager
    [CmdletBinding()]
    param()
    $npuKeywords = @('NPU','Neural','AI Boost','IPU','Hexagon','VPU','GNA','Myriad')
    $found = @()
    try {
        $found = Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue |
            Where-Object {
                # Scarta device senza nome (frequenti in Win32_PnPEntity)
                if ([string]::IsNullOrWhiteSpace($_.Name)) { return $false }
                $devName = [string]$_.Name
                foreach ($kw in $npuKeywords) {
                    if ($devName -match [regex]::Escape($kw)) { return $true }
                }
                return $false
            } | ForEach-Object {
                [PSCustomObject]@{
                    Name     = $_.Name
                    Status   = if ($_.Status) { $_.Status } else { 'Unknown' }
                    DeviceID = if ($_.DeviceID) { $_.DeviceID } else { '' }
                }
            }
    } catch {
        $found = @([PSCustomObject]@{
            Name     = ("Errore query NPU: {0}" -f $_.Exception.Message)
            Status   = 'Error'
            DeviceID = ''
        })
    }
    return $found
}

# ---------------------------------------------------------------
# BACKUP
# ---------------------------------------------------------------

function Save-RegistryValue {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Name
    )
    $exists  = Test-Path $Path
    $item    = $null
    $present = $false
    if ($exists) {
        try {
            $item    = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
            $present = $true
        } catch {
            $present = $false
        }
    }
    [pscustomobject]@{
        Path         = $Path
        Name         = $Name
        PathExists   = $exists
        ValuePresent = $present
        Value        = if ($present) { $item.$Name } else { $null }
    }
}

function Ensure-Backup {
    if (Test-Path $StateFile) {
        Write-Log 'Backup già presente. Verrà riutilizzato per il rollback.' 'INFO'
        return
    }

    Write-Log 'Creo i backup iniziali prima di modificare il sistema...' 'INFO'

    $regTargets = @(
        @{ Path='HKCU:\Software\Microsoft\GameBar';                                                              Name='AllowAutoGameMode' },
        @{ Path='HKCU:\System\GameConfigStore';                                                                  Name='GameDVR_Enabled' },
        @{ Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects';                        Name='VisualFXSetting' },
        @{ Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize';                            Name='EnableTransparency' },
        @{ Path='HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR';             Name='value' },
        @{ Path='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile';                   Name='NetworkThrottlingIndex' },
        @{ Path='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile';                   Name='SystemResponsiveness' },
        @{ Path='HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers';                                        Name='HwSchMode' },
        @{ Path='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games';       Name='GPU Priority' },
        @{ Path='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games';       Name='Priority' },
        @{ Path='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games';       Name='Scheduling Category' },
        @{ Path='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games';       Name='SFIO Priority' }
    ) | ForEach-Object { Save-RegistryValue -Path $_.Path -Name $_.Name }

    $svcTargets = @('SysMain','DiagTrack','WSearch') | ForEach-Object {
        try {
            $svc = Get-CimInstance Win32_Service -Filter ("Name='{0}'" -f $_)
            [pscustomobject]@{ Name=$svc.Name; StartMode=$svc.StartMode; State=$svc.State }
        } catch {
            [pscustomobject]@{ Name=$_; StartMode='Unknown'; State='Unknown' }
        }
    }

    $activeScheme = (& powercfg /getactivescheme) 2>&1 | Out-String
    $powerInfo    = [pscustomobject]@{ ActiveSchemeRaw = $activeScheme.Trim() }

    $watcherExists = $false
    try {
        $null          = Get-ScheduledTask -TaskName $WatcherTaskName -ErrorAction Stop
        $watcherExists = $true
    } catch {
        $watcherExists = $false
    }
    [pscustomobject]@{
        TaskExistsBefore = $watcherExists
        TaskName         = $WatcherTaskName
        AgentPath        = $WatcherAgentPath
    } | ConvertTo-Json -Depth 5 | Set-Content -Path $WatcherStateFile -Encoding UTF8

    $regTargets  | ConvertTo-Json -Depth 5 | Set-Content -Path $RegistryBackupFile -Encoding UTF8
    $svcTargets  | ConvertTo-Json -Depth 5 | Set-Content -Path $ServiceBackupFile  -Encoding UTF8
    $powerInfo   | ConvertTo-Json -Depth 5 | Set-Content -Path $PowerBackupFile    -Encoding UTF8

    [pscustomobject]@{
        Created = (Get-Date).ToString('s')
        Version = $ScriptVersion
        Project = $ProjectName
    } | ConvertTo-Json -Depth 5 | Set-Content -Path $StateFile -Encoding UTF8

    Write-Log 'Backup iniziale creato con successo.' 'OK'
}

# ---------------------------------------------------------------
# PIANO ENERGETICO
# ---------------------------------------------------------------

function Get-UltimatePerformanceGuid {
    $out = (& powercfg /list) 2>&1 | Out-String
    foreach ($line in ($out -split "`r?`n")) {
        if ($line -match '([A-Fa-f0-9\-]{36})' -and
            ($line -match 'Prestazioni eccellenti' -or $line -match 'Ultimate Performance')) {
            return $Matches[1]
        }
    }
    return $null
}

function Enable-UltimatePerformance {
    $guid = Get-UltimatePerformanceGuid
    if (-not $guid) {
        try {
            & powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
            Start-Sleep -Milliseconds 400
            $guid = Get-UltimatePerformanceGuid
        } catch {
            Write-Log 'Impossibile duplicare il piano Prestazioni eccellenti.' 'WARN'
        }
    }
    if ($guid) {
        & powercfg /setactive $guid | Out-Null
        Write-Log ("Piano energetico attivo: Prestazioni eccellenti ({0})" -f $guid) 'OK'
    } else {
        Write-Log 'Non sono riuscito ad attivare Prestazioni eccellenti.' 'WARN'
    }
}

# ---------------------------------------------------------------
# AVVIO: SEGNALAZIONE VOCI SOSPETTE (NON RIMUOVE NULLA)
# ---------------------------------------------------------------

function Disable-ConsumerStartupNoise {
    $runKeys = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'
    )
    foreach ($rk in $runKeys) {
        if (Test-Path $rk) {
            try {
                $item = Get-ItemProperty -Path $rk
                foreach ($prop in $item.PSObject.Properties) {
                    if ($prop.Name -in 'PSPath','PSParentPath','PSChildName','PSDrive','PSProvider') { continue }
                    if ($prop.Value -is [string] -and
                        $prop.Value -match 'OneDrive|Teams|Discord|EdgeUpdate|Adobe|SteamWebHelper|Xbox|Spotify') {
                        Write-Log ("Voce startup rilevata (non rimossa): {0} -> {1}" -f $prop.Name, $prop.Value) 'INFO'
                    }
                }
            } catch {
                Write-Log ("Impossibile leggere {0}: {1}" -f $rk, $_.Exception.Message) 'WARN'
            }
        }
    }
}

# ---------------------------------------------------------------
# [v4.1 FIX] APPLY HYPER GAMING BASE
# Tutte le scritture su registro ora usano funzioni idempotenti.
# I servizi ora usano Set-ServiceStartupIfDifferent.
# ---------------------------------------------------------------
# ---------------------------------------------------------------
# [v4.1 FIX] HAGS
# Era Set-DwordValue (non idempotente). Ora usa Set-DwordValueIfDifferent.
# ---------------------------------------------------------------

function Set-HAGS {
    param([Parameter(Mandatory)] [ValidateSet('On','Off')] [string]$Mode)
    Ensure-Backup
    $value = if ($Mode -eq 'On') { [UInt32]2 } else { [UInt32]1 }
    Set-DwordValueIfDifferent `
        -Path  'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' `
        -Name  'HwSchMode' `
        -Value $value `
        -Label ("GraphicsDrivers -> HwSchMode (HAGS {0})" -f $Mode)
    Write-Log ("HAGS impostato su {0}. Riavvio richiesto." -f $Mode) 'OK'
}

# ---------------------------------------------------------------
# GAMEWATCHER AGENT
# ---------------------------------------------------------------

function Get-AgentTemplate {
@'
param(
    [string]$LogRoot = "$env:ProgramData\WinCaffe\AllGames_HyperGamingBase\Logs"
)

# ==============================================================
#  WinCaffe GameWatcher Agent - v4.1.4 HF1
#
#  Modifiche v4.1.2:
#  - Priorita' abbassata da High ad AboveNormal.
#    High puo' affamare thread driver/audio/input causando calo FPS.
#    Fonte: https://learn.microsoft.com/en-us/windows/win32/procthread/scheduling-priorities
#  - Timer resolution 0.5ms attivato al primo gioco rilevato e
#    rilasciato automaticamente quando tutti i giochi si chiudono.
#    Basato su OGD_Timer_0.5ms.ps1 (crediti: OGD/DarkPlayer84Tv).
#    NtSetTimerResolution e' una funzione interna NT (ntdll), non
#    documentata ufficialmente da Microsoft: usarla e' comune ma non
#    supportata formalmente.
#    0.5ms = 5000 unita' da 100 nanosecondi.
# ==============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'
New-Item -ItemType Directory -Force -Path $LogRoot | Out-Null
$AgentLog = Join-Path $LogRoot 'gamewatcher-agent.log'

function Write-AgentLog {
    param([string]$Message)
    $line = "[{0}] [AGENT] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -Path $AgentLog -Value $line -Encoding UTF8
}

# -- P/Invoke: foreground window + timer resolution --
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class WinCaffeNative {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    // NtSetTimerResolution: funzione interna NT (ntdll), non documentata ufficialmente.
    // DesiredResolution: in unita' da 100 nanosecondi. 0.5ms = 5000.
    // SetResolution: true per attivare, false per rilasciare.
    // CurrentResolution: valore effettivo dopo la chiamata.
    [DllImport("ntdll.dll")]
    public static extern int NtSetTimerResolution(uint DesiredResolution, bool SetResolution, out uint CurrentResolution);

    [DllImport("ntdll.dll")]
    public static extern int NtQueryTimerResolution(out uint MinimumResolution, out uint MaximumResolution, out uint CurrentResolution);
}
"@

# Timer 0.5ms = 5000 unita' da 100ns
$TIMER_TARGET_100NS = [uint32]5000
$timerActive = $false

function Enable-TimerResolution {
    if ($script:timerActive) { return }
    try {
        $current = [uint32]0
        $ret = [WinCaffeNative]::NtSetTimerResolution($script:TIMER_TARGET_100NS, $true, [ref]$current)
        if ($ret -eq 0) {
            $script:timerActive = $true
            $actualMs = [math]::Round($current / 10000.0, 3)
            Write-AgentLog ("Timer resolution attivata: {0} ms (richiesto 0.500 ms, codice ret={1})" -f $actualMs, $ret)
        } else {
            Write-AgentLog ("NtSetTimerResolution fallita: codice ret={0}" -f $ret)
        }
    } catch {
        Write-AgentLog ("Eccezione Enable-TimerResolution: {0}" -f $_.Exception.Message)
    }
}

function Disable-TimerResolution {
    if (-not $script:timerActive) { return }
    try {
        $current = [uint32]0
        $ret = [WinCaffeNative]::NtSetTimerResolution($script:TIMER_TARGET_100NS, $false, [ref]$current)
        $script:timerActive = $false
        Write-AgentLog ("Timer resolution rilasciata (codice ret={0})" -f $ret)
    } catch {
        Write-AgentLog ("Eccezione Disable-TimerResolution: {0}" -f $_.Exception.Message)
    }
}

$ExcludedNames = @(
    'explorer','dwm','shellexperiencehost','searchhost','searchapp','startmenuexperiencehost','taskmgr',
    'powershell','pwsh','cmd','conhost','msedge','chrome','firefox','opera','discord','steam','steamwebhelper',
    'epicgameslauncher','eadesktop','battle.net','battle.net launcher','ubisoftconnect','goggalaxy','riotclientservices',
    'systemsettings','applicationframehost','lockapp','textinputhost','nvidia app','nvcontainer','rtss','obs64'
)

$KnownGamePathHints = @(
    '\steamapps\common\','\epic games\','\gog galaxy\games\','\battle.net\','\ubisoft\','\ea games\',
    '\xboxgames\','\games\','\riot games\','\playnite\'
)

$Boosted = @{}
Write-AgentLog ('Agent avviato. Priorita target: AboveNormal | Timer: 0.500ms via NtSetTimerResolution.')

while ($true) {
    try {
        $hWnd = [WinCaffeNative]::GetForegroundWindow()
        if ($hWnd -eq [IntPtr]::Zero) { Start-Sleep -Seconds 3; continue }

        [uint32]$pid = 0
        [WinCaffeNative]::GetWindowThreadProcessId($hWnd, [ref]$pid) | Out-Null
        if ($pid -eq 0) { Start-Sleep -Seconds 3; continue }

        $proc  = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if (-not $proc) { Start-Sleep -Seconds 3; continue }

        $pname = $proc.ProcessName.ToLowerInvariant()
        if ($ExcludedNames -contains $pname) { Start-Sleep -Seconds 3; continue }

        $path      = ''
        try { $path = $proc.MainModule.FileName } catch { $path = '' }
        $pathLower = $path.ToLowerInvariant()

        $isCandidate = $false
        foreach ($hint in $KnownGamePathHints) {
            if ($pathLower.Contains($hint)) { $isCandidate = $true; break }
        }
        if (-not $isCandidate) {
            if ($proc.MainWindowTitle -and
                $proc.MainWindowTitle.Trim().Length -ge 2 -and
                $proc.CPU -ge 0.1 -and
                $proc.WorkingSet64 -ge 300MB) {
                $isCandidate = $true
            }
        }

        if ($isCandidate -and -not $Boosted.ContainsKey($pid)) {
            try {
                # AboveNormal invece di High: meno aggressivo, non affama driver/audio/input.
                # Fonte: https://learn.microsoft.com/en-us/windows/win32/procthread/scheduling-priorities
                $proc.PriorityClass = 'AboveNormal'
                $Boosted[$pid] = [pscustomobject]@{
                    Name  = $proc.ProcessName
                    Path  = $path
                    Since = (Get-Date)
                }
                Write-AgentLog ("Boost AboveNormal applicato a PID={0} Name={1}" -f $pid, $proc.ProcessName)

                # Attiva il timer 0.25ms al primo gioco rilevato
                Enable-TimerResolution
            } catch {
                Write-AgentLog ("Impossibile boostare PID={0} Name={1}: {2}" -f $pid, $proc.ProcessName, $_.Exception.Message)
            }
        }

        # Pulizia processi terminati
        foreach ($knownPid in @($Boosted.Keys)) {
            if (-not (Get-Process -Id $knownPid -ErrorAction SilentlyContinue)) {
                $info = $Boosted[$knownPid]
                Write-AgentLog ("Processo terminato PID={0} Name={1}" -f $knownPid, $info.Name)
                $Boosted.Remove($knownPid)
            }
        }

        # Se non ci sono piu' giochi tracciati, rilascia il timer
        if ($Boosted.Count -eq 0 -and $script:timerActive) {
            Disable-TimerResolution
        }

    } catch {}

    Start-Sleep -Seconds 3
}
'@
}

function Apply-BlackOps7WindowsProfile {
    [CmdletBinding()]
    param()

    Write-Log 'Applicazione profilo Windows ad alto FPS per Black Ops 7...' 'INFO'
    Set-DwordValueIfDifferent -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'UseNexusForGameBarEnabled' -Value 0 -Label 'HKCU:\Software\Microsoft\GameBar -> UseNexusForGameBarEnabled'
    Set-DwordValueIfDifferent -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AllowAutoGameMode' -Value 1 -Label 'HKCU:\Software\Microsoft\GameBar -> AllowAutoGameMode'
    Set-DwordValueIfDifferent -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Value 1 -Label 'HKCU:\Software\Microsoft\GameBar -> AutoGameModeEnabled'
    Set-DwordValueIfDifferent -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_FSEBehaviorMode' -Value 2 -Label 'HKCU:\System\GameConfigStore -> GameDVR_FSEBehaviorMode'
    Set-DwordValueIfDifferent -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_HonorUserFSEBehaviorMode' -Value 1 -Label 'HKCU:\System\GameConfigStore -> GameDVR_HonorUserFSEBehaviorMode'
    Set-DwordValueIfDifferent -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_DXGIHonorFSEWindowsCompatible' -Value 1 -Label 'HKCU:\System\GameConfigStore -> GameDVR_DXGIHonorFSEWindowsCompatible'
    Set-DwordValueIfDifferent -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_EFSEBehaviorMode' -Value 0 -Label 'HKCU:\System\GameConfigStore -> GameDVR_EFSEBehaviorMode'
    Set-DwordValueIfDifferent -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Value 0 -Label 'HKCU:\System\GameConfigStore -> GameDVR_Enabled'
    Set-DwordValueIfDifferent -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Name 'AllowGameDVR' -Value 0 -Label 'HKLM:\...\GameDVR -> AllowGameDVR'
    Set-StringValueIfDifferent -Path 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -Name 'DirectXUserGlobalSettings' -Value 'SwapEffectUpgradeEnable=1;VRROptimizeEnable=0;' -Label 'HKCU:\...\UserGpuPreferences -> DirectXUserGlobalSettings (BO7)'
    Set-DwordValueIfDifferent -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode' -Value 2 -Label 'HKLM:\...\GraphicsDrivers -> HwSchMode'
    Set-DwordValueIfDifferent -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'TdrDelay' -Value 10 -Label 'HKLM:\...\GraphicsDrivers -> TdrDelay'
    Set-DwordValueIfDifferent -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'TdrDdiDelay' -Value 10 -Label 'HKLM:\...\GraphicsDrivers -> TdrDdiDelay'
    Set-DwordValueIfDifferent -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' -Name 'Win32PrioritySeparation' -Value 0x26 -Label 'HKLM:\...\PriorityControl -> Win32PrioritySeparation'
    Set-DwordValueIfDifferent -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'SystemResponsiveness' -Value 0 -Label 'HKLM:\...\SystemProfile -> SystemResponsiveness (BO7)'
    Set-DwordValueIfDifferent -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'GPU Priority' -Value 8 -Label 'HKLM:\...\Tasks\Games -> GPU Priority'
    Set-DwordValueIfDifferent -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'Priority' -Value 6 -Label 'HKLM:\...\Tasks\Games -> Priority'
    Set-DwordValueIfDifferent -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'Clock Rate' -Value 10000 -Label 'HKLM:\...\Tasks\Games -> Clock Rate'
    Set-StringValueIfDifferent -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'Scheduling Category' -Value 'High' -Label 'HKLM:\...\Tasks\Games -> Scheduling Category'
    Set-StringValueIfDifferent -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'SFIO Priority' -Value 'High' -Label 'HKLM:\...\Tasks\Games -> SFIO Priority'
    Set-DwordValueIfDifferent -Path 'HKCU:\Software\Microsoft\Multimedia\Audio' -Name 'UserDuckingPreference' -Value 3 -Label 'HKCU:\...\Audio -> UserDuckingPreference'
    Write-Log 'Profilo Windows per Black Ops 7 applicato. Riavvio consigliato.' 'OK'
}

function Apply-HyperGamingBase {
    Ensure-Backup
    Write-Log 'Applicazione assetto permanente Hyper Gaming Base per tutti i giochi...' 'INFO'

    $powerPlan = Ensure-WinCaffePowerPlan
    if ($powerPlan -and $powerPlan.Guid) {
        Write-Log ("Profilo energetico gaming pronto: {0} ({1})" -f $powerPlan.Name, $powerPlan.Guid) 'OK'
    }

    Set-DwordValueIfDifferent -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AllowAutoGameMode' -Value 1 -Label 'HKCU:\Software\Microsoft\GameBar -> AllowAutoGameMode'
    Set-DwordValueIfDifferent -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Value 1 -Label 'HKCU:\Software\Microsoft\GameBar -> AutoGameModeEnabled'
    Set-DwordValueIfDifferent -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'UseNexusForGameBarEnabled' -Value 0 -Label 'HKCU:\Software\Microsoft\GameBar -> UseNexusForGameBarEnabled'
    Set-DwordValueIfDifferent -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Value 0 -Label 'HKCU:\System\GameConfigStore -> GameDVR_Enabled'
    Set-DwordValueIfDifferent -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Value 0 -Label 'HKCU:\...\GameDVR -> AppCaptureEnabled'
    Set-DwordValueIfDifferent -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AudioCaptureEnabled' -Value 0 -Label 'HKCU:\...\GameDVR -> AudioCaptureEnabled'
    Set-DwordValueIfDifferent -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'CursorCaptureEnabled' -Value 0 -Label 'HKCU:\...\GameDVR -> CursorCaptureEnabled'
    Set-DwordValueIfDifferent -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_FSEBehaviorMode' -Value 2 -Label 'HKCU:\System\GameConfigStore -> GameDVR_FSEBehaviorMode'
    Set-DwordValueIfDifferent -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_HonorUserFSEBehaviorMode' -Value 1 -Label 'HKCU:\System\GameConfigStore -> GameDVR_HonorUserFSEBehaviorMode'
    Set-DwordValueIfDifferent -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR' -Name 'value' -Value 0 -Label 'HKLM:\...\AllowGameDVR -> value'
    Set-DwordValueIfDifferent -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Name 'AllowGameDVR' -Value 0 -Label 'HKLM:\...\GameDVR -> AllowGameDVR'
    Set-DwordValueIfDifferent -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 2 -Label 'HKCU:\...\VisualEffects -> VisualFXSetting'
    Set-DwordValueIfDifferent -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Value 0 -Label 'HKCU:\...\Personalize -> EnableTransparency'
    Set-DwordValueIfDifferent -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'NetworkThrottlingIndex' -Value ([UInt32]::MaxValue) -Label 'HKLM:\...\SystemProfile -> NetworkThrottlingIndex'
    Set-DwordValueIfDifferent -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'SystemResponsiveness' -Value 3 -Label 'HKLM:\...\SystemProfile -> SystemResponsiveness'
    Set-DwordValueIfDifferent -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' -Name 'Win32PrioritySeparation' -Value 0x26 -Label 'HKLM:\...\PriorityControl -> Win32PrioritySeparation'
    Set-DwordValueIfDifferent -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' -Name 'PowerThrottlingOff' -Value 0 -Label 'HKLM:\...\PowerThrottling -> PowerThrottlingOff'
    Set-StringValueIfDifferent -Path 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -Name 'DirectXUserGlobalSettings' -Value 'SwapEffectUpgradeEnable=1;' -Label 'HKCU:\...\UserGpuPreferences -> DirectXUserGlobalSettings'

    Set-DwordValueIfDifferent -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'GPU Priority' -Value 8 -Label 'HKLM:\...\Tasks\Games -> GPU Priority'
    Set-DwordValueIfDifferent -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'Priority' -Value 6 -Label 'HKLM:\...\Tasks\Games -> Priority'
    Set-DwordValueIfDifferent -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'Clock Rate' -Value 10000 -Label 'HKLM:\...\Tasks\Games -> Clock Rate'
    Set-StringValueIfDifferent -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'Scheduling Category' -Value 'High' -Label 'HKLM:\...\Tasks\Games -> Scheduling Category'
    Set-StringValueIfDifferent -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'SFIO Priority' -Value 'High' -Label 'HKLM:\...\Tasks\Games -> SFIO Priority'
    Set-StringValueIfDifferent -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'Background Only' -Value 'False' -Label 'HKLM:\...\Tasks\Games -> Background Only'

    Set-ServiceStartupIfDifferent -Name 'SysMain' -StartupType Manual -TryStop
    Set-ServiceStartupIfDifferent -Name 'DiagTrack' -StartupType Manual -TryStop
    Set-ServiceStartupIfDifferent -Name 'WSearch' -StartupType Manual
    Write-Log 'WSearch lasciato su Manual: approccio più pulito e coerente con WinCaffe 8.0.13.' 'INFO'

    try {
        $hib = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -ErrorAction Stop
        Write-Log ("Fast Startup attuale: HiberbootEnabled={0}" -f $hib.HiberbootEnabled) 'INFO'
    } catch {
        Write-Log 'Valore Fast Startup non letto.' 'WARN'
    }

    Apply-BlackOps7WindowsProfile
    Disable-ConsumerStartupNoise
    Write-Log 'Applicazione base completata. Riavvio consigliato.' 'OK'
}

function Install-GameWatcher {
    Ensure-Backup
    $agent = Get-AgentTemplate
    Set-Content -Path $WatcherAgentPath -Value $agent -Encoding UTF8
    Write-Log ("Agent copiato in: {0}" -f $WatcherAgentPath) 'OK'

    try {
        $existing = Get-ScheduledTask -TaskName $WatcherTaskName -ErrorAction SilentlyContinue
        if ($existing) {
            Unregister-ScheduledTask -TaskName $WatcherTaskName -Confirm:$false -ErrorAction SilentlyContinue
            Write-Log 'Task precedente GameWatcher rimosso prima del reinstall.' 'INFO'
        }
    } catch {}

    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name
        $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ("-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"{0}`"" -f $WatcherAgentPath)
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        $principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 0)

        Register-ScheduledTask -TaskName $WatcherTaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'WinCaffe automatic game watcher and booster.' -ErrorAction Stop | Out-Null

        $registeredTask = Get-ScheduledTask -TaskName $WatcherTaskName -ErrorAction Stop
        if ($registeredTask) {
            Start-ScheduledTask -TaskName $WatcherTaskName -ErrorAction SilentlyContinue
            Write-Log ("GameWatcher permanente installato ed avviato per l'utente {0}." -f $currentUser) 'OK'
        } else {
            Write-Log 'Registrazione GameWatcher non verificabile dopo il register.' 'WARN'
        }
    } catch {
        Write-Log ("Installazione GameWatcher fallita: {0}" -f $_.Exception.Message) 'ERR'
    }
}

function Remove-GameWatcher {
    try {
        Stop-ScheduledTask -TaskName $WatcherTaskName -ErrorAction SilentlyContinue
        Write-Log 'Richiesto stop del task GameWatcher.' 'INFO'
    } catch {
        Write-Log ("Impossibile fermare il task GameWatcher prima della rimozione: {0}" -f $_.Exception.Message) 'WARN'
    }

    try {
        Unregister-ScheduledTask -TaskName $WatcherTaskName -Confirm:$false -ErrorAction Stop
        Write-Log 'Task GameWatcher rimosso.' 'OK'
    } catch {
        if ($_.Exception.Message -match 'No MSFT_ScheduledTask objects found') {
            Write-Log 'GameWatcher già non installato, salto la rimozione del task.' 'INFO'
        } else {
            Write-Log ("Task GameWatcher non rimosso: {0}" -f $_.Exception.Message) 'WARN'
        }
    }

    try {
        $escapedAgentPath = [Regex]::Escape($WatcherAgentPath)
        $watcherProcesses = Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" -ErrorAction SilentlyContinue | Where-Object {
            $_.CommandLine -and $_.CommandLine -match $escapedAgentPath
        }
        foreach ($proc in $watcherProcesses) {
            try {
                Stop-Process -Id $proc.ProcessId -Force -ErrorAction Stop
                Write-Log ("Processo GameWatcher terminato: PID={0}" -f $proc.ProcessId) 'OK'
            } catch {
                Write-Log ("Impossibile terminare il processo GameWatcher PID={0}: {1}" -f $proc.ProcessId, $_.Exception.Message) 'WARN'
            }
        }
    } catch {}

    if (Test-Path $WatcherAgentPath) {
        Remove-Item -Path $WatcherAgentPath -Force -ErrorAction SilentlyContinue
        Write-Log 'File agent GameWatcher rimosso.' 'OK'
    }
}

# ---------------------------------------------------------------
# QUICK REPORT (con sezione NPU aggiunta in v4.1)
# ---------------------------------------------------------------

function New-QuickReport {
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("$ProjectName v$ScriptVersion - Quick Report")
    $lines.Add(("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')))
    $lines.Add('')

    # -- Hardware base --
    try {
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1 Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
        $ram = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
        $os  = Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber

        $lines.Add(("OS:  {0} | Version {1} | Build {2}" -f $os.Caption, $os.Version, $os.BuildNumber))
        $lines.Add(("CPU: {0} | Cores {1} | Logical {2} | MaxClock {3} MHz" -f `
            $cpu.Name, $cpu.NumberOfCores, $cpu.NumberOfLogicalProcessors, $cpu.MaxClockSpeed))
        $ramGb = [math]::Round(($ram.Sum / 1GB), 2)
        $lines.Add(("RAM totale: {0} GB" -f $ramGb))
    } catch {
        $lines.Add(("Errore lettura CPU/RAM/OS: {0}" -f $_.Exception.Message))
    }

    # -- GPU --
    $lines.Add('')
    $lines.Add('GPU:')
    $gpuList = Get-FriendlyGpuReport
    foreach ($g in $gpuList) {
        $lines.Add(("  {0} | VRAM approx {1} GB  ({2})" -f $g.Name, $g.ApproxGB, $g.Note))
    }

    # -- [v4.1 NEW] NPU --
    $lines.Add('')
    $lines.Add('NPU (Neural Processing Unit):')
    $npuList = Get-NpuReport
    if ($npuList.Count -eq 0) {
        $lines.Add('  Nessuna NPU rilevata (o non supportata da questo sistema).')
    } else {
        foreach ($n in $npuList) {
            $lines.Add(("  {0} | Status: {1}" -f $n.Name, $n.Status))
            if ($n.DeviceID) {
                $lines.Add(("    DeviceID: {0}" -f $n.DeviceID))
            }
        }
    }

    # -- Registro: valori chiave --
    $checks = @(
        @{ Label='GameMode';               Path='HKCU:\Software\Microsoft\GameBar';                                            Name='AllowAutoGameMode' },
        @{ Label='GameDVR_Enabled';        Path='HKCU:\System\GameConfigStore';                                               Name='GameDVR_Enabled' },
        @{ Label='VisualFXSetting';        Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects';     Name='VisualFXSetting' },
        @{ Label='EnableTransparency';     Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize';         Name='EnableTransparency' },
        @{ Label='NetworkThrottlingIndex'; Path='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name='NetworkThrottlingIndex' },
        @{ Label='SystemResponsiveness';   Path='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name='SystemResponsiveness' },
        @{ Label='HwSchMode (HAGS)';       Path='HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers';                     Name='HwSchMode' },
        @{ Label='GPU Priority';           Path='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name='GPU Priority' },
        @{ Label='Scheduling Category';    Path='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name='Scheduling Category' }
    )

    $lines.Add('')
    $lines.Add('Registry checks:')
    foreach ($c in $checks) {
        try {
            $item = Get-ItemProperty -Path $c.Path -Name $c.Name -ErrorAction Stop
            $lines.Add(("  - {0}: {1}" -f $c.Label, $item.$($c.Name)))
        } catch {
            $lines.Add(("  - {0}: not set" -f $c.Label))
        }
    }

    # -- Servizi --
    $lines.Add('')
    $lines.Add('Services:')
    foreach ($svcName in 'SysMain','DiagTrack','WSearch') {
        try {
            $svc = Get-CimInstance Win32_Service -Filter ("Name='{0}'" -f $svcName)
            $lines.Add(("  - {0}: StartMode={1}, State={2}" -f $svc.Name, $svc.StartMode, $svc.State))
        } catch {
            $lines.Add(("  - {0}: unavailable" -f $svcName))
        }
    }

    # -- GameWatcher --
    $taskState = 'Not installed'
    try {
        $task      = Get-ScheduledTask -TaskName $WatcherTaskName -ErrorAction Stop
        $taskState = $task.State
    } catch {}
    $lines.Add('')
    $lines.Add(("GameWatcher task: {0}" -f $taskState))
    $lines.Add(("GameWatcher path: {0}" -f $WatcherAgentPath))

    Set-Content -Path $QuickReportFile -Value $lines -Encoding UTF8
    [pscustomobject]@{
        Generated  = (Get-Date).ToString('s')
        ReportFile = $QuickReportFile
        LogFile    = $CurrentLog
    } | ConvertTo-Json -Depth 5 | Set-Content -Path $SummaryFile -Encoding UTF8

    Write-Log ("Quick report creato: {0}" -f $QuickReportFile) 'OK'
    Get-Content -Path $QuickReportFile | ForEach-Object { Write-Host $_ }
}

# ---------------------------------------------------------------
# ROLLBACK
# ---------------------------------------------------------------

function Restore-RegistryValue {
    param([Parameter(Mandatory)] $Entry)
    if (-not $Entry.PathExists) {
        if (Test-Path $Entry.Path) {
            Write-Log ("Il path {0} esiste ora ma prima no. Nessuna rimozione automatica del path." -f $Entry.Path) 'WARN'
        }
        return
    }
    if (-not (Test-Path $Entry.Path)) {
        New-Item -Path $Entry.Path -Force | Out-Null
    }
    if ($Entry.ValuePresent) {
        if ($Entry.Value -is [int] -or $Entry.Value -is [long] -or $Entry.Value -is [uint32]) {
            New-ItemProperty -Path $Entry.Path -Name $Entry.Name -PropertyType DWord -Value ([UInt32]$Entry.Value) -Force | Out-Null
        } else {
            New-ItemProperty -Path $Entry.Path -Name $Entry.Name -PropertyType String -Value ([string]$Entry.Value) -Force | Out-Null
        }
        Write-Log ("Ripristinato {0} -> {1}" -f $Entry.Path, $Entry.Name) 'OK'
    } else {
        try {
            Remove-ItemProperty -Path $Entry.Path -Name $Entry.Name -ErrorAction Stop
            Write-Log ("Valore rimosso: {0} -> {1}" -f $Entry.Path, $Entry.Name) 'OK'
        } catch {
            Write-Log ("Valore {0} -> {1} già assente o non rimovibile." -f $Entry.Path, $Entry.Name) 'WARN'
        }
    }
}

function Restore-Backups {
    if (-not (Test-Path $StateFile)) {
        Write-Log 'Nessun backup trovato: rollback non disponibile.' 'WARN'
        return
    }

    Write-Log 'Avvio rollback completo...' 'INFO'
    Remove-GameWatcher

    if (Test-Path $RegistryBackupFile) {
        $regEntries = Get-Content -Path $RegistryBackupFile -Raw | ConvertFrom-Json
        foreach ($e in $regEntries) {
            Restore-RegistryValue -Entry $e
        }
    }

    if (Test-Path $ServiceBackupFile) {
        $svcEntries = Get-Content -Path $ServiceBackupFile -Raw | ConvertFrom-Json
        foreach ($svc in $svcEntries) {
            # [v4.1 FIX] Usa Set-ServiceStartupIfDifferent invece di Set-ServiceStartup.
            # Salta il servizio se è già nella modalità che era prima dello script.
            if ($svc.StartMode -in 'Auto','Automatic') {
                Set-ServiceStartupIfDifferent -Name $svc.Name -StartupType Automatic
            } elseif ($svc.StartMode -eq 'Manual') {
                Set-ServiceStartupIfDifferent -Name $svc.Name -StartupType Manual
            } elseif ($svc.StartMode -eq 'Disabled') {
                Set-ServiceStartupIfDifferent -Name $svc.Name -StartupType Disabled
            }
        }
    }

    if (Test-Path $PowerBackupFile) {
        $power = Get-Content -Path $PowerBackupFile -Raw | ConvertFrom-Json
        $match = [regex]::Match($power.ActiveSchemeRaw, '([A-Fa-f0-9\-]{36})')
        if ($match.Success) {
            try {
                & powercfg /setactive $match.Groups[1].Value | Out-Null
                Write-Log ("Piano energetico ripristinato: {0}" -f $match.Groups[1].Value) 'OK'
            } catch {
                Write-Log ("Impossibile ripristinare il piano energetico originale: {0}" -f $_.Exception.Message) 'WARN'
            }
        }
    }

    Write-Log 'Rollback completato. Riavvio consigliato.' 'OK'
}

# ---------------------------------------------------------------
# MENU PRINCIPALE
# ---------------------------------------------------------------

function Show-Menu {
    Write-Host ''
    Write-Host '  [1] Applica Hyper Gaming Base permanente'          -ForegroundColor Green
    Write-Host '  [2] Installa GameWatcher permanente'               -ForegroundColor Green
    Write-Host '  [3] Rimuovi GameWatcher permanente'                -ForegroundColor Yellow
    Write-Host '  [4] Imposta HAGS su ON'                           -ForegroundColor Yellow
    Write-Host '  [5] Imposta HAGS su OFF'                          -ForegroundColor Yellow
    Write-Host '  [6] Genera Quick Report (con rilevamento NPU)'     -ForegroundColor Cyan
    Write-Host '  [7] Rollback completo dai backup'                  -ForegroundColor Red
    Write-Host '  [0] Esci'                                         -ForegroundColor White
    Write-Host ''
}

# ---------------------------------------------------------------
# ENTRY POINT
# ---------------------------------------------------------------

function Get-WinCaffePowerPlan {
    [CmdletBinding()]
    param([string]$Name = 'WinCaffe Hyper Gaming Base')
    try {
        $plans = (& powercfg /list) 2>&1 | Out-String
        foreach ($line in ($plans -split "`r?`n")) {
            if ($line -match '([A-Fa-f0-9\-]{36})' -and $line -match [regex]::Escape($Name)) {
                return [PSCustomObject]@{
                    Guid = $Matches[1]
                    Name = $Name
                }
            }
        }
    } catch {}
    return $null
}

function Set-WinCaffePowerPlanValues {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Guid
    )

    try { & powercfg /setacvalueindex $Guid SUB_PROCESSOR PERFBOOSTMODE 1 | Out-Null } catch {}
    try { & powercfg /setdcvalueindex $Guid SUB_PROCESSOR PERFBOOSTMODE 1 | Out-Null } catch {}
    try { & powercfg /setacvalueindex $Guid SUB_PROCESSOR PROCTHROTTLEMIN 5 | Out-Null } catch {}
    try { & powercfg /setdcvalueindex $Guid SUB_PROCESSOR PROCTHROTTLEMIN 5 | Out-Null } catch {}
    try { & powercfg /setacvalueindex $Guid SUB_PROCESSOR PERFINCTHRESHOLD 10 | Out-Null } catch {}
    try { & powercfg /setacvalueindex $Guid SUB_PROCESSOR PERFDECTHRESHOLD 8 | Out-Null } catch {}
    try { & powercfg /setacvalueindex $Guid SUB_PROCESSOR PERFINCTIME 1 | Out-Null } catch {}
    try { & powercfg /setacvalueindex $Guid SUB_PROCESSOR PERFDECTIME 1 | Out-Null } catch {}
    try { & powercfg /setacvalueindex $Guid SUB_DISK DISKIDLE 0 | Out-Null } catch {}
    try { & powercfg /setdcvalueindex $Guid SUB_DISK DISKIDLE 10 | Out-Null } catch {}
    try { & powercfg /setacvalueindex $Guid SUB_SLEEP STANDBYIDLE 0 | Out-Null } catch {}
    try { & powercfg /setacvalueindex $Guid SUB_SLEEP HIBERNATEIDLE 0 | Out-Null } catch {}
    try { & powercfg /setacvalueindex $Guid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 | Out-Null } catch {}
    try { & powercfg /setdcvalueindex $Guid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 | Out-Null } catch {}
    try { & powercfg /setactive $Guid | Out-Null } catch {}
}

function Ensure-WinCaffePowerPlan {
    [CmdletBinding()]
    param()

    $targetName = 'WinCaffe Hyper Gaming Base'
    $existing = Get-WinCaffePowerPlan -Name $targetName
    if ($existing) {
        Set-WinCaffePowerPlanValues -Guid $existing.Guid
        return $existing
    }

    $sourceGuid = $null
    try {
        $ultimate = Get-UltimatePerformanceGuid
        if ($ultimate) {
            $sourceGuid = $ultimate
        } else {
            $dup = (& powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61) 2>&1 | Out-String
            if ($dup -match '([A-Fa-f0-9\-]{36})') {
                $sourceGuid = $Matches[1]
            }
        }
    } catch {}

    if (-not $sourceGuid) {
        try {
            $list = (& powercfg /list) 2>&1 | Out-String
            foreach ($line in ($list -split "`r?`n")) {
                if ($line -match '([A-Fa-f0-9\-]{36})' -and ($line -match 'High performance' -or $line -match 'Prestazioni elevate')) {
                    $sourceGuid = $Matches[1]
                    break
                }
            }
        } catch {}
    }

    if (-not $sourceGuid) {
        $sourceGuid = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
    }

    $newGuid = $null
    try {
        $dupOut = (& powercfg /duplicatescheme $sourceGuid) 2>&1 | Out-String
        if ($dupOut -match '([A-Fa-f0-9\-]{36})') {
            $newGuid = $Matches[1]
        }
    } catch {}

    if (-not $newGuid) {
        $fallback = Get-WinCaffePowerPlan -Name $targetName
        if ($fallback) {
            Set-WinCaffePowerPlanValues -Guid $fallback.Guid
            return $fallback
        }
        if ($sourceGuid) {
            Set-WinCaffePowerPlanValues -Guid $sourceGuid
            return [PSCustomObject]@{
                Guid = $sourceGuid
                Name = 'Fallback High/Ultimate Performance'
            }
        }
        return $null
    }

    try { & powercfg /changename $newGuid $targetName | Out-Null } catch {}
    Set-WinCaffePowerPlanValues -Guid $newGuid

    return [PSCustomObject]@{
        Guid = $newGuid
        Name = $targetName
    }
}


# ---------------------------------------------------------------
# ENTRY POINT E MENU PRINCIPALE
# ---------------------------------------------------------------
try {
    Test-Admin
    Show-WinCaffeDisclaimer
    do {
        Write-Banner
        Write-Host ("Log corrente: {0}" -f $CurrentLog) -ForegroundColor DarkGray
        Show-Menu
        $choice = Read-Host "Seleziona un'opzione"
        switch ($choice) {
            '1' { Apply-HyperGamingBase; Pause }
            '2' { Install-GameWatcher;   Pause }
            '3' { Remove-GameWatcher;    Pause }
            '4' { Set-HAGS -Mode 'On';   Pause }
            '5' { Set-HAGS -Mode 'Off';  Pause }
            '6' { New-QuickReport;       Pause }
            '7' { Restore-Backups;       Pause }
            '0' { Write-Log "Uscita richiesta dall'utente." 'INFO' }
            default { Write-Log 'Scelta non valida.' 'WARN'; Pause }
        }
    } while ($choice -ne '0')
} catch {
    Write-Log $_.Exception.Message 'ERR'
    throw
}
