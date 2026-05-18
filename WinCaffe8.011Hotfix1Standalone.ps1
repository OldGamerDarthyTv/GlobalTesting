[CmdletBinding()]
param()

$ErrorActionPreference = 'SilentlyContinue'

function Write-Info([string]$M){ Write-Host "  [INFO] $M" -ForegroundColor Cyan }
function Write-Success([string]$M){ Write-Host "  [OK] $M" -ForegroundColor Green }
function Write-Warning2([string]$M){ Write-Host "  [WARN] $M" -ForegroundColor Yellow }
function Write-Error2([string]$M){ Write-Host "  [ERR] $M" -ForegroundColor Red }

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  +--------------------------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host "  | WINCAFFE 8.0.11 HOTFIX 1 STANDALONE                                |" -ForegroundColor Black -BackgroundColor Gray
    Write-Host "  | EA JAVELIN / ANTI-CHEAT PROCESS CONFLICT FIX                       |" -ForegroundColor Black -BackgroundColor Gray
    Write-Host "  +--------------------------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host ""
}

function Get-AntiCheatConflictProcesses {
    $patterns = @(
        'ida','ida64','ida32','idag','idaw',
        'x64dbg','x32dbg','ollydbg',
        'dnspy','dnspy-x86',
        'cheatengine','cheat engine',
        'processhacker','process hacker',
        'ghidra','ghidra64'
    )

    $results = @()
    foreach($p in @(Get-Process -ErrorAction SilentlyContinue)){
        $name = [string]$p.ProcessName
        $path = ''
        try{ $path = [string]$p.Path }catch{}
        $haystack = ($name + ' ' + $path).ToLowerInvariant()
        if($patterns | Where-Object { $haystack -like ('*' + $_ + '*') }){
            $results += [pscustomobject]@{
                Name = $name
                Id   = $p.Id
                Path = $path
            }
        }
    }

    return @($results | Sort-Object Name,Id -Unique)
}

function Ensure-AdminRelaunch {
    $isAdmin = $false
    try{
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $pr = New-Object Security.Principal.WindowsPrincipal($id)
        $isAdmin = $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }catch{}

    if($isAdmin){ return }

    Write-Warning2 'Questo fix prova a rilanciarsi come amministratore per poter chiudere piu processi possibile.'
    Start-Sleep -Milliseconds 1200
    try{
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
            '-NoProfile',
            '-ExecutionPolicy','Bypass',
            '-File',"`"$PSCommandPath`""
        )
        exit
    }catch{
        Write-Warning2 'Rilancio come amministratore non riuscito: continuo con i permessi attuali.'
        Start-Sleep -Milliseconds 1200
    }
}

function Invoke-AntiCheatHotfix {
    Show-Banner
    Write-Host "  Questo fix cerca software di debug / reverse engineering spesso bloccato" -ForegroundColor White
    Write-Host "  dagli anti-cheat. E utile in casi come EA Javelin con errore su IDA." -ForegroundColor DarkGray
    Write-Host ""

    $conflicts = @(Get-AntiCheatConflictProcesses)
    if($conflicts.Count -eq 0){
        Write-Success 'Nessun processo incompatibile rilevato in questo momento'
        Write-Host "  Se il gioco continua a non partire, controlla processi avviati al boot" -ForegroundColor DarkGray
        Write-Host "  oppure riavvia Windows prima di ritestare." -ForegroundColor DarkGray
        return
    }

    Write-Warning2 ("Trovati {0} processi potenzialmente incompatibili:" -f $conflicts.Count)
    foreach($proc in $conflicts){
        $suffix = if([string]::IsNullOrWhiteSpace($proc.Path)){ '' } else { " | $($proc.Path)" }
        Write-Host ("    - {0} (PID {1}){2}" -f $proc.Name,$proc.Id,$suffix) -ForegroundColor Yellow
    }

    Write-Host ""
    if((Read-Host "  Vuoi chiuderli adesso? (S/N)") -notin @('S','s')){
        Write-Host "  Nessuna chiusura eseguita. Chiudili manualmente prima di rilanciare il gioco." -ForegroundColor DarkGray
        return
    }

    $closed = 0
    foreach($proc in $conflicts){
        try{
            Stop-Process -Id $proc.Id -Force -ErrorAction Stop
            Write-Success ("Processo chiuso: {0} (PID {1})" -f $proc.Name,$proc.Id)
            $closed++
        }catch{
            Write-Warning2 ("Impossibile chiudere {0} (PID {1})" -f $proc.Name,$proc.Id)
        }
    }

    Write-Host ""
    if($closed -gt 0){
        Write-Success ("Chiusi {0}/{1} processi incompatibili" -f $closed,$conflicts.Count)
        Write-Host "  Ora rilancia il gioco." -ForegroundColor White
        Write-Host "  Se l anti-cheat continua a bloccare l avvio, fai un riavvio completo di Windows." -ForegroundColor DarkGray
    } else {
        Write-Error2 'Nessun processo e stato chiuso automaticamente'
        Write-Host "  Prova a chiuderli manualmente o riavvia il PC prima di rilanciare il gioco." -ForegroundColor DarkGray
    }
}

Ensure-AdminRelaunch
Invoke-AntiCheatHotfix
Write-Host ""
Read-Host "  INVIO per chiudere"
