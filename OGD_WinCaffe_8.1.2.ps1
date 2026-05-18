#Requires -Version 5.1
<#
═══════════════════════════════════════════════════════════════════════════════
OGD WinCaffe NEXT v8.1.2

 Sistema Definitivo di Ottimizzazione Windows 11 per Gaming

 ┌─────────────────────────────────────────────────────────────┐
 │ #DarkPlayer84Tv Productions                                 │
 │ by OldGamerDarthy Official                                  │
 │ OGD Team - Original Gaming Design                           │
 └─────────────────────────────────────────────────────────────┘

NOVITA v8.1.2:
   Bootstrap HF4 ricostruito: script di nuovo autosufficiente
   NPU rilevamento robusto - 3 metodi in cascata
   Fallback CPU-based Intel Core Ultra / AMD Ryzen AI / Snapdragon X
   Selezione PC Type robusta (Desktop / Laptop / Laptop Gaming)
Fix 8.1.2: pulizia totale dei moduli legacy rimossi e consolidamento del ramo NEXT
Nota versione: 8.1.2 consolida il ramo NEXT rimuovendo in modo definitivo tutto il perimetro rete dallo script.

 OGD PRESET:
   Questa variante personale è stata testata sul mio PC con RTX 5080,
   Intel Core Ultra 9 285K, 32 GB di RAM DDR5 e MSI PRO Z890-P.
   È aggiunta al mio script solo per avere una versione tutta mia,
   calibrata sul mio hardware e sulle mie preferenze.
   Se su altri PC crea problemi, instabilità o risultati diversi dal previsto,
   io non c'entro: non è un preset universale e non è pensato come profilo safe per tutti.

 OGD WINCAFFE NEXT:
   Dalla versione 8.1.1 in poi il progetto prende il nome OGD WinCaffe NEXT.
   Il target del ramo NEXT è migliorare tutto in modo progressivo:
   struttura, chiarezza, compatibilita, diagnostica, preset e qualita generale del progetto.

 MENU DISPONIBILI:
   [1] LIGHT  [2] NORMALE  [3] AGGRESSIVO
   [A] AGGRESSIVO GAMING (Light/Normale/Full)
   [4] LAPTOP  [5] LAPTOP GAMING (Light/Normale/Alto/Ultra)
   [6] FIX RETE  [7] EXPLORER  [8] INFO  [9] RESET
   [F] FILE I/O  [U] WINGET  [W] WINREVIVE  [N] NET TWEAKS
   [G] NVIDIA  [L] DPC FIX  [P] NPU  [E] UNREAL ENGINE  [Y] TARGET WINDOWS
   [C] CALL OF DUTY  [M] MOUSE  [D] DISCORD  [H] HOTFIX

 Autore: OldGamerDarthy | #DarkPlayer84Tv Productions
 Discord: discord.gg/5SJa2xp5
═══════════════════════════════════════════════════════════════════════════════
#>

param(
    [string]$WizardSetupChoice = '',
    [string]$WizardTargetFamily = '',
    [string]$WizardTargetRelease = '',
    [string]$WizardPcType = '',
    [string]$WizardMenuChoice = '',
    [switch]$WizardSkipDiscord,
    [switch]$WizardAcceptTerms,
    [switch]$WizardSkipOpenDyslexic
)

$script:OgdLaunchParameters = @{} + $PSBoundParameters
$script:OgdWizardMenuChoiceConsumed = $false

function Get-OgdSelfInvocationArgs {
    $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$PSCommandPath)
    foreach($entry in $script:OgdLaunchParameters.GetEnumerator()){
        if($entry.Value -is [switch]){
            if($entry.Value.IsPresent){
                $args += ('-' + $entry.Key)
            }
            continue
        }
        if($null -ne $entry.Value -and -not [string]::IsNullOrWhiteSpace([string]$entry.Value)){
            $args += ('-' + $entry.Key)
            $args += [string]$entry.Value
        }
    }
    return $args
}

# Admin check
if(-not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")){
    # Preferisci pwsh se disponibile
    $pwshExe=Get-Command pwsh -EA SilentlyContinue
    if($pwshExe){
        Start-Process -FilePath $pwshExe.Source -ArgumentList (Get-OgdSelfInvocationArgs) -Verb RunAs;exit
    }else{
        Start-Process -FilePath 'powershell' -ArgumentList (Get-OgdSelfInvocationArgs) -Verb RunAs;exit
    }
}

# Runtime info: il controllo effettivo viene fatto dopo l'accettazione utente
$script:OgdPreferredPwsh = Get-Command pwsh -EA SilentlyContinue
$script:OgdRunningOnPwsh = ($PSVersionTable.PSEdition -eq 'Core')

# Windows 11 check
$os=Get-CimInstance Win32_OperatingSystem;$build=[int]$os.BuildNumber
if($build -lt 22000){
    Write-Host "`n  [INFO] Build rilevata inferiore a Windows 11 (build 22000+) - Build: $build" -ForegroundColor Yellow
}

$script:OgdTargetWindowsFamily = ''
$script:OgdTargetWindowsRelease = ''
$script:OgdTargetIsWindows11 = $false
$script:OgdTargetIsWindows10 = $false
$script:OgdTargetIs24H2OrLater = $false
$script:OgdTargetIs25H2OrLater = $false

$script:OgdPcType = ''
$script:OgdIsLaptop = $false
$script:OgdIsLaptopGaming = $false
$script:OgdIsDesktop = $false

function Select-OgdWindowsProfileTarget {
    $detectedFamily = if($build -ge 22000){ '11' } else { '10' }
    $detectedRelease = if($detectedFamily -eq '11'){
        if($build -ge 26200){ '25H2+' }
        elseif($build -ge 26100){ '24H2' }
        else { 'Pre-24H2' }
    } else {
        if($build -ge 19045){ '22H2' } else { 'Pre-22H2' }
    }

    $script:OgdTargetWindowsFamily = if($WizardTargetFamily -in @('10','11')){ $WizardTargetFamily } else { $detectedFamily }
    if($script:OgdTargetWindowsFamily -eq '11'){
        $script:OgdTargetWindowsRelease = if($WizardTargetRelease -in @('25H2+','24H2','Pre-24H2')){ $WizardTargetRelease } else { $detectedRelease }
    } else {
        $script:OgdTargetWindowsRelease = if($WizardTargetRelease -in @('22H2','Pre-22H2')){ $WizardTargetRelease } else { $detectedRelease }
    }

    $script:OgdTargetIsWindows11 = ($script:OgdTargetWindowsFamily -eq '11')
    $script:OgdTargetIsWindows10 = ($script:OgdTargetWindowsFamily -eq '10')
    $script:OgdTargetIs24H2OrLater = ($script:OgdTargetWindowsFamily -eq '11' -and $script:OgdTargetWindowsRelease -in @('24H2','25H2+'))
    $script:OgdTargetIs25H2OrLater = ($script:OgdTargetWindowsFamily -eq '11' -and $script:OgdTargetWindowsRelease -eq '25H2+')
}

function Get-OgdTargetLabel {
    if($script:OgdTargetWindowsFamily){
        return "Windows $($script:OgdTargetWindowsFamily) - $($script:OgdTargetWindowsRelease)"
    }
    return "Windows target"
}

function Get-OgdAdaptiveWindowsMenuLabel {
    if($script:OgdTargetIsWindows10){
        return '[Y] WINDOWS 10'
    }
    return '[Y] WIN11 EXTRA'
}

function Get-OgdAdaptiveBannerPathLabel {
    if($script:OgdTargetIsWindows10){
        return '[Y] WIN10'
    }
    if($script:OgdTargetIs25H2OrLater){
        return '[Y] WIN11+'
    }
    if($script:OgdTargetIs24H2OrLater){
        return '[Y] WIN11 24H2'
    }
    return '[Y] WIN11'
}

function Get-OgdAdaptiveBetaLabel {
    if($script:OgdTargetIs25H2OrLater){
        return '[B] BETA 25H2+'
    }
    return '[B] BETA (solo 25H2+)'
}


function Select-OgdPcType {
    $selected = $false
    while(-not $selected){
        Clear-Host
        Write-Host ""
        Write-Host "  ╔═══════════════════════════════════════════════════════╗" -F Cyan
        Write-Host "  ║                 TIPO DI PC TARGET                    ║" -F Cyan
        Write-Host "  ╚═══════════════════════════════════════════════════════╝`n" -F Cyan
        Write-Host ("  Target Windows: {0}" -f (Get-OgdTargetLabel)) -F White
        Write-Host "  [1] Desktop" -F Green
        Write-Host "  [2] Laptop" -F Yellow
        Write-Host "  [3] Laptop Gaming`n" -F Magenta
        $pcChoice = switch($WizardPcType){
            '1' { '1' }
            '2' { '2' }
            '3' { '3' }
            default { Read-Host "  Quale tipo di PC vuoi ottimizzare? (1/2/3)" }
        }
        if($WizardPcType){
            Write-Host ("  > Wizard GUI: selezione automatica tipo PC {0}" -f $WizardPcType) -F DarkGray
        }
        switch($pcChoice){
            '1' {
                $script:OgdPcType = 'Desktop'
                $script:OgdIsDesktop = $true
                $script:OgdIsLaptop = $false
                $script:OgdIsLaptopGaming = $false
                $selected = $true
            }
            '2' {
                $script:OgdPcType = 'Laptop'
                $script:OgdIsDesktop = $false
                $script:OgdIsLaptop = $true
                $script:OgdIsLaptopGaming = $false
                $selected = $true
            }
            '3' {
                $script:OgdPcType = 'Laptop Gaming'
                $script:OgdIsDesktop = $false
                $script:OgdIsLaptop = $false
                $script:OgdIsLaptopGaming = $true
                $selected = $true
            }
            default {
                Write-Host "  Scelta non valida" -F Yellow
                Start-Sleep 1
            }
        }
    }
}

function Confirm-OgdTargetBeforeAction {
    param(
        [string]$ActionName = 'questa operazione',
        [ValidateSet('Any','Windows10','Windows11','Windows11_24H2Plus','Windows11_Pre24H2')]
        [string]$Requirement = 'Any'
    )

    if(-not $script:OgdTargetWindowsFamily){
        Select-OgdWindowsProfileTarget
    }

    $allowed = $true
    switch($Requirement){
        'Windows10'            { $allowed = $script:OgdTargetIsWindows10 }
        'Windows11'            { $allowed = $script:OgdTargetIsWindows11 }
        'Windows11_24H2Plus'   { $allowed = ($script:OgdTargetIsWindows11 -and $script:OgdTargetIs24H2OrLater) }
        'Windows11_Pre24H2'    { $allowed = ($script:OgdTargetIsWindows11 -and -not $script:OgdTargetIs24H2OrLater) }
        default                { $allowed = $true }
    }

    if(-not $allowed){
        Write-Host ""
        Write-Warning ("{0}: target attuale {1} non compatibile con questo ramo ({2})" -f $ActionName,(Get-OgdTargetLabel),$Requirement)
        $changeTarget = Read-Host "  Vuoi cambiare target Windows adesso? (S/N)"
        if($changeTarget -in @('S','s','Y','y')){
            Select-OgdWindowsProfileTarget
            if(-not $script:OgdPcType){ Select-OgdPcType }
            return (Confirm-OgdTargetBeforeAction -ActionName $ActionName -Requirement $Requirement)
        }
        return $false
    }

    return $true
}

Select-OgdWindowsProfileTarget
Select-OgdPcType

$script:OgdSoftWarnings = @{}

function Write-OgdSoftWarningOnce {
    param(
        [string]$Key,
        [string]$Message
    )
    if([string]::IsNullOrWhiteSpace($Key)){ return }
    if($script:OgdSoftWarnings.ContainsKey($Key)){ return }
    $script:OgdSoftWarnings[$Key] = $true
    Write-Host "  [WARN] $Message" -ForegroundColor Yellow
}

function Get-AppxProvisionedPackage {
    [CmdletBinding()]
    param(
        [switch]$Online,
        [string]$Path
    )
    try{
        if($Online){
            return @(Microsoft.Dism.Commands\Get-AppxProvisionedPackage -Online -EA Stop)
        }
        if(-not [string]::IsNullOrWhiteSpace($Path)){
            return @(Microsoft.Dism.Commands\Get-AppxProvisionedPackage -Path $Path -EA Stop)
        }
        return @(Microsoft.Dism.Commands\Get-AppxProvisionedPackage -Online -EA Stop)
    }catch{
        Write-OgdSoftWarningOnce 'Get-AppxProvisionedPackage' 'AppX ProvisionedPackage non disponibile su questo sistema: salto il debloat avanzato senza fermare il profilo.'
        return @()
    }
}

function Remove-AppxProvisionedPackage {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]$InputObject,
        [switch]$Online,
        [string]$Path
    )
    process{
        try{
            if($null -ne $InputObject){
                if($Online){
                    $InputObject | Microsoft.Dism.Commands\Remove-AppxProvisionedPackage -Online -EA Stop | Out-Null
                } elseif(-not [string]::IsNullOrWhiteSpace($Path)){
                    $InputObject | Microsoft.Dism.Commands\Remove-AppxProvisionedPackage -Path $Path -EA Stop | Out-Null
                } else {
                    $InputObject | Microsoft.Dism.Commands\Remove-AppxProvisionedPackage -Online -EA Stop | Out-Null
                }
            }
        }catch{
            Write-OgdSoftWarningOnce 'Remove-AppxProvisionedPackage' 'Rimozione ProvisionedPackage saltata: alcuni pacchetti risultano già assenti o non gestibili.'
        }
    }
}

function Get-AppxPackage {
    [CmdletBinding()]
    param(
        [string]$Name,
        [switch]$AllUsers
    )
    try{
        if($AllUsers -and -not [string]::IsNullOrWhiteSpace($Name)){
            return @(Appx\Get-AppxPackage -Name $Name -AllUsers -EA Stop)
        }
        if($AllUsers){
            return @(Appx\Get-AppxPackage -AllUsers -EA Stop)
        }
        if(-not [string]::IsNullOrWhiteSpace($Name)){
            return @(Appx\Get-AppxPackage -Name $Name -EA Stop)
        }
        return @(Appx\Get-AppxPackage -EA Stop)
    }catch{
        Write-OgdSoftWarningOnce 'Get-AppxPackage' 'Stack AppX non pienamente disponibile: salto le query app moderne senza interrompere il profilo.'
        return @()
    }
}

function Remove-AppxPackage {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]$InputObject,
        [switch]$AllUsers
    )
    process{
        try{
            if($null -ne $InputObject){
                if($AllUsers){
                    $InputObject | Appx\Remove-AppxPackage -AllUsers -EA Stop | Out-Null
                } else {
                    $InputObject | Appx\Remove-AppxPackage -EA Stop | Out-Null
                }
            }
        }catch{
            Write-OgdSoftWarningOnce 'Remove-AppxPackage' 'Una o più app moderne non sono removibili su questo sistema: continuo senza bloccare lo script.'
        }
    }
}

function Get-OgdProtectedDebloatPackages {
    return @(
        'SpotifyAB.SpotifyMusic',
        'Microsoft.XboxApp',
        'Microsoft.GamingApp',
        'Microsoft.XboxGamingOverlay',
        'Microsoft.XboxGameOverlay',
        'Microsoft.XboxSpeechToTextOverlay',
        'Microsoft.Xbox.TCUI',
        'Microsoft.XboxIdentityProvider',
        'Microsoft.XboxGameCallableUI',
        'Microsoft.GamingServices',
        'Microsoft.XboxGameBarPlugin'
    )
}

function Get-OgdProtectedXboxPackages {
    return @(
        'Microsoft.XboxApp',
        'Microsoft.GamingApp',
        'Microsoft.XboxGamingOverlay',
        'Microsoft.XboxGameOverlay',
        'Microsoft.XboxSpeechToTextOverlay',
        'Microsoft.Xbox.TCUI',
        'Microsoft.XboxIdentityProvider',
        'Microsoft.XboxGameCallableUI',
        'Microsoft.GamingServices',
        'Microsoft.XboxGameBarPlugin'
    )
}

function Get-OgdAlternativeDebloatPackageCatalog {
    return @(
        'Microsoft.3DBuilder',
        'Microsoft.BingNews',
        'Microsoft.BingWeather',
        'Microsoft.GetHelp',
        'Microsoft.Getstarted',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.MixedReality.Portal',
        'Microsoft.People',
        'Microsoft.SkypeApp',
        'Microsoft.Todos',
        'Microsoft.WindowsAlarms',
        'Microsoft.WindowsCamera',
        'Microsoft.WindowsCommunicationsApps',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.WindowsMaps',
        'Microsoft.YourPhone',
        'Microsoft.ZuneMusic',
        'Microsoft.ZuneVideo',
        'MicrosoftTeams',
        'Clipchamp.Clipchamp',
        'Microsoft.Windows.DevHome'
    )
}

function Get-OgdAlternativeDebloatBaseCatalog {
    return @(
        'Microsoft.BingNews',
        'Microsoft.BingWeather',
        'Microsoft.GetHelp',
        'Microsoft.Getstarted',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.MixedReality.Portal',
        'Microsoft.People',
        'Microsoft.SkypeApp',
        'Microsoft.Todos',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.WindowsMaps',
        'Microsoft.YourPhone',
        'MicrosoftTeams',
        'Clipchamp.Clipchamp',
        'Microsoft.Windows.DevHome'
    )
}

function Remove-OgdDebloatPackages {
    param(
        [string[]]$PackageNames = @(),
        [string]$ProgressLabel = 'Debloat app moderne'
    )

    $items = @($PackageNames | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    if($items.Count -eq 0){ return 0 }

    $removed = 0
    $index = 0
    foreach($name in $items){
        $index++
        $pct = [Math]::Min([int](($index / [Math]::Max($items.Count,1)) * 100),100)
        Write-Host ("  → {0} [{1}/{2}]" -f $name,$index,$items.Count) -ForegroundColor DarkGray
        Write-Progress -Activity $ProgressLabel -Status $name -PercentComplete $pct
        $beforeAppx = 0
        $beforeProv = 0
        try{
            $appxMatches = @(Get-AppxPackage -Name $name -AllUsers -EA SilentlyContinue)
            $beforeAppx = $appxMatches.Count
            if($appxMatches.Count -gt 0){
                $appxMatches | Remove-AppxPackage -AllUsers -EA SilentlyContinue
            }
        }catch{}
        try{
            $provMatches = @(Get-AppxProvisionedPackage -Online -EA SilentlyContinue | Where-Object { $_.DisplayName -eq $name })
            $beforeProv = $provMatches.Count
            if($provMatches.Count -gt 0){
                $provMatches | Remove-AppxProvisionedPackage -Online -EA SilentlyContinue | Out-Null
            }
        }catch{}
        $afterAppx = 0
        $afterProv = 0
        try{ $afterAppx = @(Get-AppxPackage -Name $name -AllUsers -EA SilentlyContinue).Count }catch{}
        try{ $afterProv = @(Get-AppxProvisionedPackage -Online -EA SilentlyContinue | Where-Object { $_.DisplayName -eq $name }).Count }catch{}
        if(($afterAppx + $afterProv) -lt ($beforeAppx + $beforeProv)){
            $removed++
        }
    }
    Write-Progress -Activity $ProgressLabel -Completed
    return $removed
}

function Invoke-OgdAlternativeDebloat {
    param(
        [ValidateSet('Base','Full')]
        [string]$Mode = 'Full',
        [switch]$IncludeRecall
    )

    $protected = @(Get-OgdProtectedDebloatPackages)
    $packages = switch($Mode){
        'Base' { @(Get-OgdAlternativeDebloatBaseCatalog) }
        default { @(Get-OgdAlternativeDebloatPackageCatalog) }
    }
    $packages = @($packages | Where-Object { $_ -notin $protected } | Select-Object -Unique)

    $removedCommon = Remove-OgdDebloatPackages -PackageNames $packages -ProgressLabel ("Debloat {0}" -f $Mode)

    $recallTouched = $false
    if($IncludeRecall){
        foreach($pkg in @('Microsoft.WindowsAiFoundation','Microsoft.Windows.Recall')){
            try{
                @(Get-AppxPackage -Name $pkg -AllUsers -EA SilentlyContinue) | Remove-AppxPackage -AllUsers -EA SilentlyContinue
            }catch{}
            try{
                @(Get-AppxProvisionedPackage -Online -EA SilentlyContinue | Where-Object { $_.DisplayName -eq $pkg }) | Remove-AppxProvisionedPackage -Online -EA SilentlyContinue | Out-Null
            }catch{}
        }
        try{ DISM /Online /Disable-Feature /NoRestart /FeatureName:Recall 2>$null | Out-Null }catch{}
        $recallTouched = $true
    }

    return [pscustomobject]@{
        RemovedCommonApps = $removedCommon
        RecallHandled     = $recallTouched
        ProtectedPackages = $protected.Count
    }
}

function Get-WindowsOptionalFeature {
    [CmdletBinding()]
    param(
        [switch]$Online,
        [string]$FeatureName
    )
    try{
        if($Online -and -not [string]::IsNullOrWhiteSpace($FeatureName)){
            return Microsoft.Dism.Commands\Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -EA Stop
        }
        if($Online){
            return @(Microsoft.Dism.Commands\Get-WindowsOptionalFeature -Online -EA Stop)
        }
        if(-not [string]::IsNullOrWhiteSpace($FeatureName)){
            return Microsoft.Dism.Commands\Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -EA Stop
        }
        return @(Microsoft.Dism.Commands\Get-WindowsOptionalFeature -Online -EA Stop)
    }catch{
        Write-OgdSoftWarningOnce 'Get-WindowsOptionalFeature' 'Feature Windows non interrogabile o già alterata: passo oltre in modo safe.'
        return @()
    }
}

function Disable-WindowsOptionalFeature {
    [CmdletBinding()]
    param(
        [switch]$Online,
        [string]$FeatureName,
        [switch]$NoRestart,
        [switch]$Remove
    )
    try{
        if($Online){
            if($Remove){
                Microsoft.Dism.Commands\Disable-WindowsOptionalFeature -Online -FeatureName $FeatureName -NoRestart:$NoRestart -Remove -EA Stop | Out-Null
            } else {
                Microsoft.Dism.Commands\Disable-WindowsOptionalFeature -Online -FeatureName $FeatureName -NoRestart:$NoRestart -EA Stop | Out-Null
            }
        }
    }catch{
        Write-OgdSoftWarningOnce "DisableFeature:$FeatureName" "Feature '$FeatureName' già assente o non modificabile: continuo senza fermarmi."
    }
}

function Get-WindowsCapability {
    [CmdletBinding()]
    param(
        [switch]$Online,
        [string]$Name
    )
    try{
        if($Online -and -not [string]::IsNullOrWhiteSpace($Name)){
            return @(Microsoft.Dism.Commands\Get-WindowsCapability -Online -Name $Name -EA Stop)
        }
        if($Online){
            return @(Microsoft.Dism.Commands\Get-WindowsCapability -Online -EA Stop)
        }
        return @()
    }catch{
        Write-OgdSoftWarningOnce 'Get-WindowsCapability' 'Capability Windows non interrogabile su questo sistema: salto il blocco relativo.'
        return @()
    }
}

function Remove-WindowsCapability {
    [CmdletBinding()]
    param(
        [switch]$Online,
        [string]$Name
    )
    try{
        if($Online -and -not [string]::IsNullOrWhiteSpace($Name)){
            Microsoft.Dism.Commands\Remove-WindowsCapability -Online -Name $Name -EA Stop | Out-Null
        }
    }catch{
        Write-OgdSoftWarningOnce "RemoveCapability:$Name" "Capability '$Name' non rimovibile o già assente: continuo senza bloccare il profilo."
    }
}

function Test-OgdProfileParse {
    param([string]$Content)
    if($null -eq $Content){ $Content = '' }
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseInput($Content,[ref]$tokens,[ref]$errors)
    return @($errors)
}

function Remove-OgdWinCaffeProfileBlock {
    param([string]$Content)
    if($null -eq $Content){ $Content = '' }
    $cleaned = [regex]::Replace($Content,'(?ms)^\s*# <<<OGD_WINCAFFE_START>>>.*?^# <<<OGD_WINCAFFE_END>>>\s*','')
    $cleaned = [regex]::Replace($cleaned,'(?ms)^\s*function\s+wincaffe\s*\{.*?^\}\s*','')
    $cleaned = [regex]::Replace($cleaned,'(?ms)^\s*function\s+global:wincaffe\s*\{.*?^\}\s*','')
    return $cleaned.Trim()
}

function Show-OgdStartupIntro {
    param([string]$Version)

    $supportsAnimation = $false
    try {
        if(-not [Console]::IsInputRedirected){
            $supportsAnimation = $true
        }
    } catch {
        $supportsAnimation = $false
    }

    if(-not $supportsAnimation){
        Clear-Host
        Write-Host ""
        Write-Host "  OGD WinCaffe NEXT" -ForegroundColor Green
        Write-Host "  Bootstrap Matrix Console" -ForegroundColor DarkGreen
        Write-Host "  Versione runtime: $Version" -ForegroundColor Cyan
        Write-Host "  Console pronta: profili, hotfix e strumenti caricati" -ForegroundColor White
        Start-Sleep -Milliseconds 1200
        return
    }

    $startedAt = Get-Date
    $durationSeconds = 8
    $spinnerFrames = @('|','/','-','\')
    $rainChars = '010101OGDNEXTWINCAFFE[]{}<>#'
    $title = 'OGD WinCaffe NEXT'
    $versionLine = 'MATRIX BOOTSTRAP CONSOLE'
    $versionSubLine = "Versione runtime: $Version"
    $tagline = 'Professional Gaming Optimization Suite'
    $phaseLines = @(
        'Boot console e controlli di sicurezza',
        'Caricamento moduli gaming, rete e sistema',
        'Inizializzazione profili, hotfix e diagnostica',
        'Finalizzazione interfaccia e controlli runtime'
    )
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("  +=================================================================+")
    $lines.Add("  |                      OGD MATRIX BOOTSTRAP                       |")
    $lines.Add("  +=================================================================+")
    $lines.Add("")
    $lines.Add("  Caricamento console Matrix... premi INVIO per saltare")
    $lines.Add("")
    $phaseStart = $lines.Count
    $lines.Add("  ")
    $progressStart = $lines.Count
    $lines.Add("  ")
    $tipStart = $lines.Count
    $lines.Add("  ")
    $titleStart = $lines.Count
    $lines.Add("  ")
    $versionStart = $lines.Count
    $lines.Add("  ")
    $versionSubStart = $lines.Count
    $lines.Add("  ")
    $taglineStart = $lines.Count
    $lines.Add("  ")
    $rainStart = $lines.Count
    $lines.Add("  ")
    $lines.Add("  ")
    $lines.Add("  ")
    $lines.Add("  ")
    $lines.Add("  ")

    Clear-Host
    foreach($line in $lines){ Write-Host $line }

    function local:Write-AtLine {
        param(
            [int]$LineIndex,
            [string]$Text,
            [ConsoleColor]$Color = [ConsoleColor]::Green
        )
        try {
            [Console]::SetCursorPosition(0, $LineIndex)
            $pad = [Math]::Max([Console]::WindowWidth - 1, 1)
            $out = $Text.PadRight($pad)
            Write-Host $out -NoNewline -ForegroundColor $Color
            [Console]::SetCursorPosition(0, $LineIndex + 1)
        } catch {
            Write-Host $Text -ForegroundColor $Color
        }
    }

    function local:Test-EnterPressed {
        try {
            if([Console]::KeyAvailable){
                $key = [Console]::ReadKey($true)
                if($key.Key -eq [ConsoleKey]::Enter){
                    return $true
                }
            }
        } catch {}
        return $false
    }

    $titleReveal = ''
    $versionReveal = ''
    $versionSubReveal = ''
    $taglineReveal = ''
    $tick = 0
    $skip = $false

    while(((Get-Date) - $startedAt).TotalSeconds -lt $durationSeconds){
        if(Test-EnterPressed){
            $skip = $true
            break
        }

        if($titleReveal.Length -lt $title.Length){
            $titleReveal += $title[$titleReveal.Length]
        }
        if($titleReveal.Length -ge $title.Length -and $versionReveal.Length -lt $versionLine.Length){
            $versionReveal += $versionLine[$versionReveal.Length]
        }
        if($versionReveal.Length -ge $versionLine.Length -and $versionSubReveal.Length -lt $versionSubLine.Length){
            $versionSubReveal += $versionSubLine[$versionSubReveal.Length]
        }
        if($versionSubReveal.Length -ge $versionSubLine.Length -and $taglineReveal.Length -lt $tagline.Length){
            $taglineReveal += $tagline[$taglineReveal.Length]
        }

        $rainLen = 56
        $chars = for($i=0;$i -lt $rainLen;$i++){
            $rainChars[(Get-Random -Minimum 0 -Maximum $rainChars.Length)]
        }
        $rain = -join $chars
        $spinner = $spinnerFrames[$tick % $spinnerFrames.Count]
        $progress = [Math]::Min([Math]::Max((((Get-Date) - $startedAt).TotalSeconds / $durationSeconds),0),1)
        $phaseIndex = [Math]::Min([int]($progress * $phaseLines.Count), $phaseLines.Count - 1)
        $filled = [Math]::Min([int]($progress * 32), 32)
        $bar = ('#' * $filled).PadRight(32,'-')
        $tip = switch($phaseIndex){
            0 { 'Suggerimento: [2] NORMALE e il profilo piu equilibrato per la maggior parte dei PC.' }
            1 { 'Suggerimento: [H] HOTFIX e utile per DX9 legacy, accessibilita e diagnostica NPU.' }
            2 { 'Suggerimento: [4] e [5] aprono livelli guidati dedicati ai laptop.' }
            default { 'Suggerimento: [8] INFO riepiloga cosa cambia davvero prima di applicare i tweak.' }
        }

        Write-AtLine 0 ("  +=================================================================+") DarkGreen
        Write-AtLine 1 ("  |  {0,-1}  {1,-57}|" -f $spinner, $rain.Substring(0,[Math]::Min($rain.Length,57))) Green
        Write-AtLine 2 ("  +=================================================================+") DarkGreen
        Write-AtLine $phaseStart ("  Stato operativo : " + $phaseLines[$phaseIndex]) DarkCyan
        Write-AtLine $progressStart ("  Caricamento     : [" + $bar + "] " + ([int]($progress * 100)).ToString().PadLeft(3) + "%") Yellow
        Write-AtLine $tipStart ("  " + $tip) DarkGray
        Write-AtLine $titleStart ("  $titleReveal") Cyan
        Write-AtLine $versionStart ("  $versionReveal") Green
        Write-AtLine $versionSubStart ("  $versionSubReveal") DarkGreen
        Write-AtLine $taglineStart ("  $taglineReveal") White
        for($i=0; $i -lt 5; $i++){
            $rowChars = for($j=0; $j -lt 56; $j++){
                $rainChars[(Get-Random -Minimum 0 -Maximum $rainChars.Length)]
            }
            Write-AtLine ($rainStart + $i) ("  " + (-join $rowChars)) DarkGreen
        }

        Start-Sleep -Milliseconds 120
        $tick++
    }

    Clear-Host
    Write-Host ""
    Write-Host "  +=================================================================+" -ForegroundColor DarkGreen
    Write-Host "  |                        OGD WinCaffe NEXT                        |" -ForegroundColor Green
    Write-Host "  |                    Matrix bootstrap completato                  |" -ForegroundColor Green
    Write-Host "  +=================================================================+" -ForegroundColor DarkGreen
    Write-Host ""
    Write-Host "  Versione: $Version" -ForegroundColor Cyan
    Write-Host '  Console pronta: profili guidati, hotfix e strumenti avanzati caricati.' -ForegroundColor White
    Write-Host ""
    if($skip){
        Write-Host "  Intro saltata su richiesta." -ForegroundColor DarkGray
    } else {
        Write-Host "  Bootstrap completato con successo." -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "  Scelta rapida: [2] desktop bilanciato | [4] laptop | [H] hotfix mirati | [T] micro tweaks" -ForegroundColor Yellow
    Start-Sleep -Milliseconds 900
}


# ═════════════════════════════════════════════════════════════════════════════
#  DISCLAIMER E CREDITI
# ═════════════════════════════════════════════════════════════════════════════

Show-OgdStartupIntro -Version '8.1.2'

Clear-Host
Write-Host "`n  ╔═══════════════════════════════════════════════════════╗" -F Cyan
Write-Host "  ║    OGD WinCaffe NEXT v8.1.2 - DISCLAIMER & CREDITI   ║" -F Cyan
Write-Host "  ╚═══════════════════════════════════════════════════════╝`n" -F Cyan

Write-Host "  INFORMAZIONI IMPORTANTI:`n" -F Yellow

Write-Host "  Questo script è un progetto NO-PROFIT creato per aiutare" -F White
Write-Host "  la comunità gaming ad ottimizzare Windows 11.`n" -F White

Write-Host "  AUTORE PRINCIPALE:" -F Cyan
Write-Host "     OldGamerDarthy (#DarkPlayer84Tv Productions)" -F White
Write-Host "     Sviluppo, integrazione, testing e manutenzione`n" -F DarkGray

Write-Host "  RINGRAZIAMENTI PERSONALI:" -F Cyan
Write-Host "     • AlexsTrexx (Alex) ⭐ - Test versione embrionale" -F White
Write-Host "       Primo a credere nel progetto e a provarlo sul campo" -F DarkGray
Write-Host "     • Diego - Supporto, consigli e amicizia durante lo sviluppo" -F White
Write-Host "     • Tutti gli amici del server Discord OGD" -F White
Write-Host "       Per consigli, idee e ispirazione continua" -F DarkGray
Write-Host "     • Claude AI (Anthropic) - Assistenza nello sviluppo`n" -F DarkGray

Write-Host "  FONTI E CREDITI TECNICI:" -F Cyan
Write-Host "     Questo script raccoglie e integra conoscenze pubbliche da:" -F White
Write-Host "     • Speedguide.net — TCP Optimizer" -F White
Write-Host "       Impostazioni TCP/IP gaming (RSC, CTCP, RTO, ACK, QoS)" -F DarkGray
Write-Host "       https://www.speedguide.net/tcpoptimizer.php" -F DarkGray
Write-Host "     • Resplendence Software — LatencyMon" -F White
Write-Host "       Strumento analisi DPC latency (menu [L])" -F DarkGray
Write-Host "       https://www.resplendence.com/latencymon" -F DarkGray
Write-Host "     • WinScript (flick9000 / Francesco) — Tweaks privacy/telemetry" -F White
Write-Host "       Base del debloat e di parte dei tweak privacy integrati nello script" -F DarkGray
Write-Host "       https://github.com/flick9000/winscript" -F DarkGray
Write-Host "     • Microsoft Docs / Microsoft Learn — Documentazione ufficiale" -F White
Write-Host "       Registry, PowerCfg, servizi, MMCSS, rete, DISM e compatibilita Windows" -F DarkGray
Write-Host "       https://learn.microsoft.com/windows/" -F DarkGray
Write-Host "     • GitHub / community open-source di tweaking e troubleshooting Windows" -F White
Write-Host "       Idee, confronti tecnici, fix e validazione pratica dei tweak safe" -F DarkGray
Write-Host "     • Community gaming (Reddit r/GlobalOffensive," -F White
Write-Host "       r/Warzone, r/pcgaming, XtremeSystems, HPET forums)" -F White
Write-Host "       Tweaks CoD, DPC fix, hidden registry keys" -F DarkGray
Write-Host "     • Autori driver e tool hardware (NVIDIA, AMD, Intel)" -F White
Write-Host "       Per driver, pannelli di controllo, documentazione e best practice ufficiali`n" -F DarkGray

Write-Host "  NOTA SUI CREDITI:" -F Yellow
Write-Host "     Questo script non ruba né copia nulla." -F White
Write-Host "     Raccoglie tweaks e ottimizzazioni pubblicamente" -F White
Write-Host "     disponibili e li rende accessibili a tutti." -F White
Write-Host "     I crediti restano ai rispettivi autori." -F White
Write-Host "     Grazie a chi pubblica documentazione, fix, test e strumenti" -F White
Write-Host "     che hanno reso possibile questo progetto community-driven." -F White
Write-Host "     L'obiettivo è diffondere la conoscenza,`n" -F White
Write-Host "     non appropriarsene.`n" -F DarkGray

Write-Host "  COMMUNITY DISCORD:" -F Cyan
Write-Host "     https://discord.gg/5SJa2xp5`n" -F Yellow

Write-Host "  RESPONSABILITA:" -F Yellow
Write-Host "     • Questo script modifica il registro di sistema" -F White
Write-Host "     • Viene creato un punto di ripristino automatico" -F White
Write-Host "     • L'autore non è responsabile per eventuali problemi" -F White
Write-Host "     • Usare a proprio rischio e responsabilità`n" -F White

Write-Host "  GARANZIE:" -F Green
Write-Host "     • Codice testato su Windows 11 (build 22000+)" -F White
Write-Host "     • Punto ripristino Windows creato prima di ogni modifica" -F White
Write-Host "     • Ripristinabile da Impostazioni → Ripristino sistema`n" -F White
Write-Host "  LICENZA:" -F Cyan
Write-Host "     GNU GPL v3.0 - vedere file LICENSE nel progetto/repo ufficiale`n" -F White

Write-Host "  ════════════════════════════════════════════════════════`n" -F Cyan

Write-Host "  COMMUNITY & SUPPORTO:" -F Cyan
Write-Host "     Discord OGD: https://discord.gg/5SJa2xp5" -F White
$discordChoice = if($WizardSkipDiscord){ 'N' } else { Read-Host "  Vuoi aprire il server Discord? (S/N)" }
if($discordChoice -in @("S","s")){
    Start-Process "https://discord.gg/5SJa2xp5"
    Write-Host "  ✓ Browser aperto — benvenuto nel server!`n" -F Green
}

$accept = if($WizardAcceptTerms){ 'S' } else { Read-Host "  Accetti i termini e vuoi proseguire? (S/N)" }

if($accept -notin @("S","s")){
    Write-Host "`n  Script terminato. Grazie!`n" -F Yellow
    Start-Sleep 2
    exit
}

function Invoke-OgdPowerShellRuntimeCheck {
    $psVersion = $PSVersionTable.PSVersion
    $pwshExe = if($script:OgdPreferredPwsh){ $script:OgdPreferredPwsh } else { Get-Command pwsh -EA SilentlyContinue }
    $runningOnPwsh = ($PSVersionTable.PSEdition -eq 'Core')

    if(-not $runningOnPwsh -and $pwshExe){
        Write-Host "`n  ℹ Runtime consigliato rilevato dopo l'accettazione: PowerShell 7.6.0+" -F Cyan
        Write-Host "  → Rilancio automatico in pwsh: $($pwshExe.Source)`n" -F DarkGray
        Start-Process -FilePath $pwshExe.Source -ArgumentList (Get-OgdSelfInvocationArgs) -Verb RunAs
        exit
    }

    if($psVersion.Major -lt 7){
        Clear-Host
        Write-Host "`n  ⚡ POWERSHELL 7.6.0 RICHIESTO`n" -F Yellow
        Write-Host "  Versione attuale: PowerShell $($psVersion.Major).$($psVersion.Minor)" -F White
        Write-Host "  Richiesta: PowerShell 7.6.0+ (release moderna e supportata)`n" -F Green
        if((Read-Host "  Installare PowerShell 7.6.0? (S/N)") -in @("S","s")){
            Write-Host "`n  Installazione via winget..." -F Cyan
            winget install Microsoft.PowerShell --silent --accept-source-agreements --accept-package-agreements
            if($LASTEXITCODE -eq 0){
                Write-Host "  ✓ PowerShell 7.6.0 installato!" -F Green
                Write-Host "`n  Riavvio script con PowerShell 7.6.0...`n" -F Yellow
                Start-Sleep 2
                Start-Process -FilePath 'pwsh' -ArgumentList (Get-OgdSelfInvocationArgs) -Verb RunAs
                exit
            }else{
                Write-Host "  ⚠ Installazione fallita. Continuo con PS $($psVersion.Major).$($psVersion.Minor) come fallback" -F Yellow
                Start-Sleep 2
            }
        }
        return
    }

    if($psVersion.Major -eq 7 -and $psVersion.Minor -lt 6){
        Clear-Host
        Write-Host "`n  🔄 AGGIORNAMENTO POWERSHELL`n" -F Yellow
        Write-Host "  Versione attuale: PowerShell $($psVersion.Major).$($psVersion.Minor)" -F White
        Write-Host "  Disponibile: PowerShell 7.6.0+ (richiesto per il runtime moderno)`n" -F Green
        if((Read-Host "  Aggiornare a PowerShell 7.6.0? (S/N)") -in @("S","s")){
            Write-Host "`n  Aggiornamento via winget..." -F Cyan
            winget upgrade Microsoft.PowerShell --silent --accept-source-agreements --accept-package-agreements
            if($LASTEXITCODE -eq 0){
                Write-Host "  ✓ PowerShell 7.6.0 aggiornato!" -F Green
                Write-Host "`n  Riavvio script con nuova versione...`n" -F Yellow
                Start-Sleep 2
                Start-Process -FilePath 'pwsh' -ArgumentList (Get-OgdSelfInvocationArgs) -Verb RunAs
                exit
            }else{
                Write-Host "  ⚠ Aggiornamento fallito. Continuo con PS $($psVersion.Major).$($psVersion.Minor)" -F Yellow
                Start-Sleep 2
            }
        }
    }
}

Invoke-OgdPowerShellRuntimeCheck


# Version helpers (spostati fuori dal bootstrap per non toccare l'avvio)
function Convert-OgdVersionObject {
    param([string]$VersionText)
    if([string]::IsNullOrWhiteSpace($VersionText)){
        return [pscustomobject]@{ Major=0; Minor=0; Patch=0; Hotfix=0; Original='' }
    }
    $normalized = $VersionText.Trim()
    if($normalized -match '^(?<maj>\d+)\.(?<min>\d+)\.(?<pat>\d+)(?:(?:HF|HotFix)(?<hf>\d+))?$'){
        return [pscustomobject]@{
            Major    = [int]$Matches['maj']
            Minor    = [int]$Matches['min']
            Patch    = [int]$Matches['pat']
            Hotfix   = if($Matches['hf']){ [int]$Matches['hf'] } else { 0 }
            Original = $normalized
        }
    }
    return [pscustomobject]@{ Major=0; Minor=0; Patch=0; Hotfix=0; Original=$normalized }
}

function Compare-OgdVersions {
    param(
        [string]$LeftVersion,
        [string]$RightVersion
    )
    $left  = Convert-OgdVersionObject $LeftVersion
    $right = Convert-OgdVersionObject $RightVersion
    foreach($part in 'Major','Minor','Patch','Hotfix'){
        if($left.$part -gt $right.$part){ return 1 }
        if($left.$part -lt $right.$part){ return -1 }
    }
    return 0
}

function Get-OgdOfficialRepoMetadata {
    [pscustomobject]@{
        Owner   = 'OldGamerDarthyTv'
        Repo    = 'WinCaffeNEXT'
        Branch  = 'main'
        ApiRoot = 'https://api.github.com/repos/OldGamerDarthyTv/WinCaffeNEXT'
        HtmlRoot= 'https://github.com/OldGamerDarthyTv/WinCaffeNEXT'
    }
}

function Get-OgdOfficialRepoScriptCandidates {
    $repo = Get-OgdOfficialRepoMetadata
    try{
        $headers = @{ 'User-Agent' = 'OGD-WinCaffe-Updater' }
        $items = Invoke-RestMethod -Uri "$($repo.ApiRoot)/contents" -Headers $headers -EA Stop
        $candidates = @()
        foreach($item in @($items)){
            if($item.type -ne 'file'){ continue }
            if($item.name -match '^OGD_WinCaffe_(?<ver>\d+\.\d+\.\d+(?:(?:HF|HotFix)\d+)?)\.ps1$'){
                $commitInfo = Get-OgdOfficialRepoFileCommitInfo -FileName $item.name
                $candidates += [pscustomobject]@{
                    Name            = $item.name
                    Version         = $Matches['ver']
                    Sha             = $item.sha
                    DownloadUrl     = $item.download_url
                    HtmlUrl         = $item.html_url
                    CommitSha       = $commitInfo.CommitSha
                    PublishedUtc    = $commitInfo.PublishedUtc
                    PublishedLabel  = $commitInfo.PublishedLabel
                    CommitMessage   = $commitInfo.CommitMessage
                }
            }
        }

        return @($candidates | Sort-Object {
            $v = Convert-OgdVersionObject $_.Version
            '{0:D6}{1:D6}{2:D6}{3:D6}' -f $v.Major,$v.Minor,$v.Patch,$v.Hotfix
        } -Descending)
    }catch{
        return @()
    }
}

function Get-OgdLatestOfficialScript {
    $candidates = @(Get-OgdOfficialRepoScriptCandidates)
    if($candidates.Count -gt 0){ return $candidates[0] }
    return $null
}

function Get-OgdCurrentScriptVersion {
    param([string]$FallbackVersion = '0.0.0')
    try{
        if($PSCommandPath){
            $leaf = Split-Path $PSCommandPath -Leaf
            if($leaf -match '^OGD_WinCaffe_(?<ver>\d+\.\d+\.\d+(?:TEST\d+)?(?:(?:HF|HotFix)\d+)?)(?:_[A-Za-z0-9_-]+)?\.ps1$'){
                $rawVersion = $Matches['ver']
                if($rawVersion -match '^(?<base>\d+\.\d+\.\d+)(?:TEST\d+)?(?<hf>(?:HF|HotFix)\d+)?$'){
                    return ($Matches['base'] + ($(if($Matches['hf']){$Matches['hf']}else{''})))
                }
                return $rawVersion
            }
        }
    }catch{}
    return $FallbackVersion
}

function Get-OgdOfficialRepoFileCommitInfo {
    param([string]$FileName)
    $repo = Get-OgdOfficialRepoMetadata
    $fallback = [pscustomobject]@{
        CommitSha      = ''
        PublishedUtc   = $null
        PublishedLabel = ''
        CommitMessage  = ''
    }
    try{
        if([string]::IsNullOrWhiteSpace($FileName)){ return $fallback }
        $headers = @{ 'User-Agent' = 'OGD-WinCaffe-Updater' }
        $uri = "$($repo.ApiRoot)/commits?sha=$($repo.Branch)&path=$([uri]::EscapeDataString($FileName))&per_page=1&page=1"
        $commits = Invoke-RestMethod -Uri $uri -Headers $headers -EA Stop
        $first = @($commits) | Select-Object -First 1
        if($null -eq $first){ return $fallback }
        $publishedUtc = $null
        try{
            $publishedUtc = ([datetime]$first.commit.committer.date).ToUniversalTime()
        }catch{}
        return [pscustomobject]@{
            CommitSha      = [string]$first.sha
            PublishedUtc   = $publishedUtc
            PublishedLabel = if($publishedUtc){ $publishedUtc.ToString('yyyy-MM-dd HH:mm:ss') + ' UTC' } else { '' }
            CommitMessage  = [string]$first.commit.message
        }
    }catch{
        return $fallback
    }
}

function Get-OgdGitBlobHash {
    param([string]$Path)
    try{
        if([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path $Path)){ return '' }
        $contentBytes = [System.IO.File]::ReadAllBytes($Path)
        $prefixBytes = [System.Text.Encoding]::UTF8.GetBytes(("blob {0}`0" -f $contentBytes.Length))
        $allBytes = New-Object byte[] ($prefixBytes.Length + $contentBytes.Length)
        [Array]::Copy($prefixBytes, 0, $allBytes, 0, $prefixBytes.Length)
        [Array]::Copy($contentBytes, 0, $allBytes, $prefixBytes.Length, $contentBytes.Length)
        $sha1 = [System.Security.Cryptography.SHA1]::Create()
        try{
            return ([System.BitConverter]::ToString($sha1.ComputeHash($allBytes))).Replace('-', '').ToLowerInvariant()
        } finally {
            $sha1.Dispose()
        }
    }catch{
        return ''
    }
}

function Get-OgdLocalFileInfo {
    param([string]$Path)
    $fallback = [pscustomobject]@{
        Exists          = $false
        LastWriteUtc    = $null
        LastWriteLabel  = ''
        BlobSha         = ''
    }
    try{
        if([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path $Path)){ return $fallback }
        $item = Get-Item -LiteralPath $Path -EA Stop
        $lastWriteUtc = $item.LastWriteTimeUtc
        return [pscustomobject]@{
            Exists          = $true
            LastWriteUtc    = $lastWriteUtc
            LastWriteLabel  = $lastWriteUtc.ToString('yyyy-MM-dd HH:mm:ss') + ' UTC'
            BlobSha         = Get-OgdGitBlobHash -Path $Path
        }
    }catch{
        return $fallback
    }
}

function Test-OgdOfficialRepoUpdateNeeded {
    param(
        [psobject]$Latest,
        [string]$CurrentVersion,
        [string]$CurrentScriptPath
    )
    if($null -eq $Latest){
        return [pscustomobject]@{ Needed = $false; Reason = ''; LocalSha = ''; RemoteSha = ''; LocalTime=''; RemoteTime=''; RepoIsNewer=$false; LocalIsNewer=$false }
    }

    $versionCompare = Compare-OgdVersions -LeftVersion $Latest.Version -RightVersion $CurrentVersion
    $localInfo = Get-OgdLocalFileInfo -Path $CurrentScriptPath
    $localSha = $localInfo.BlobSha
    $remoteSha = [string]$Latest.Sha
    $repoIsNewer = $false
    $localIsNewer = $false
    $timeSlackSeconds = 120
    if($localInfo.LastWriteUtc -and $Latest.PublishedUtc){
        $deltaSeconds = [math]::Round((New-TimeSpan -Start $Latest.PublishedUtc -End $localInfo.LastWriteUtc).TotalSeconds,0)
        if($deltaSeconds -gt $timeSlackSeconds){
            $localIsNewer = $true
        }elseif($deltaSeconds -lt (-1 * $timeSlackSeconds)){
            $repoIsNewer = $true
        }
    }

    if($versionCompare -lt 0){
        return [pscustomobject]@{
            Needed      = $false
            Reason      = 'local-newer-version'
            LocalSha    = $localSha
            RemoteSha   = $remoteSha
            LocalTime   = $localInfo.LastWriteLabel
            RemoteTime  = [string]$Latest.PublishedLabel
            RepoIsNewer = $repoIsNewer
            LocalIsNewer= $localIsNewer
        }
    }

    if($versionCompare -gt 0){
        return [pscustomobject]@{
            Needed      = $true
            Reason      = 'version'
            LocalSha    = $localSha
            RemoteSha   = $remoteSha
            LocalTime   = $localInfo.LastWriteLabel
            RemoteTime  = [string]$Latest.PublishedLabel
            RepoIsNewer = $repoIsNewer
            LocalIsNewer= $localIsNewer
        }
    }

    if($versionCompare -eq 0 -and -not [string]::IsNullOrWhiteSpace($localSha) -and -not [string]::IsNullOrWhiteSpace($remoteSha) -and $localSha -ne $remoteSha){
        if($localIsNewer -and -not $repoIsNewer){
            return [pscustomobject]@{
                Needed      = $false
                Reason      = 'local-newer-content'
                LocalSha    = $localSha
                RemoteSha   = $remoteSha
                LocalTime   = $localInfo.LastWriteLabel
                RemoteTime  = [string]$Latest.PublishedLabel
                RepoIsNewer = $repoIsNewer
                LocalIsNewer= $localIsNewer
            }
        }
        return [pscustomobject]@{
            Needed      = $true
            Reason      = if($repoIsNewer){ 'content-newer-repo' } else { 'content-different' }
            LocalSha    = $localSha
            RemoteSha   = $remoteSha
            LocalTime   = $localInfo.LastWriteLabel
            RemoteTime  = [string]$Latest.PublishedLabel
            RepoIsNewer = $repoIsNewer
            LocalIsNewer= $localIsNewer
        }
    }

    return [pscustomobject]@{
        Needed      = $false
        Reason      = ''
        LocalSha    = $localSha
        RemoteSha   = $remoteSha
        LocalTime   = $localInfo.LastWriteLabel
        RemoteTime  = [string]$Latest.PublishedLabel
        RepoIsNewer = $repoIsNewer
        LocalIsNewer= $localIsNewer
    }
}

function Invoke-OgdOfficialRepoUpdateCheck {
    param(
        [string]$CurrentVersion,
        [string]$InstalledScript
    )

    $latest = Get-OgdLatestOfficialScript
    if($null -eq $latest){ return }
    $updateState = Test-OgdOfficialRepoUpdateNeeded -Latest $latest -CurrentVersion $CurrentVersion -CurrentScriptPath $PSCommandPath
    if(-not $updateState.Needed){ return }

    Clear-Host
    Write-Host "`n  🔄 AGGIORNAMENTO UFFICIALE DISPONIBILE`n" -F Yellow
    Write-Host "  Installata: v$CurrentVersion" -F White
    Write-Host "  Disponibile: v$($latest.Version)" -F Green
    if($updateState.LocalTime){ Write-Host "  File locale: $($updateState.LocalTime)" -F DarkGray }
    if($updateState.RemoteTime){ Write-Host "  Repo file : $($updateState.RemoteTime)" -F DarkGray }
    if($updateState.Reason -in @('content-newer-repo','content-different')){
        Write-Host "  Rilevato reupload/rebuild: stesso numero versione ma contenuto aggiornato nel repo ufficiale." -F Cyan
    } elseif($updateState.Reason -eq 'version'){
        Write-Host "  Il repo ufficiale contiene una build piu recente della tua." -F Cyan
    }
    Write-Host "  Repo ufficiale: $((Get-OgdOfficialRepoMetadata).HtmlRoot)`n" -F DarkGray

    $prompt = if($updateState.Reason -in @('content-newer-repo','content-different')){
        "  Scaricare il reupload più recente anche se la versione è invariata? (S/N)"
    } else {
        "  Scaricare e aggiornare lo script dalla versione ufficiale disponibile? (S/N)"
    }
    if((Read-Host $prompt) -notin @('S','s')){
        return
    }

    try{
        $destinations = New-Object System.Collections.Generic.List[string]
        if($PSCommandPath -and (Test-Path $PSCommandPath)){ [void]$destinations.Add($PSCommandPath) }
        if(-not [string]::IsNullOrWhiteSpace($InstalledScript)){ [void]$destinations.Add($InstalledScript) }
        foreach($dest in @($destinations | Select-Object -Unique)){
            $parent = Split-Path $dest -Parent
            if($parent -and -not (Test-Path $parent)){
                New-Item -Path $parent -ItemType Directory -Force | Out-Null
            }
            Invoke-WebRequest -Uri $latest.DownloadUrl -OutFile $dest -UseBasicParsing -TimeoutSec 60 -EA Stop
            Write-Host "  ✓ Script aggiornato: $dest" -F Green
        }

        $repo = Get-OgdOfficialRepoMetadata
        $timerRaw = "https://raw.githubusercontent.com/$($repo.Owner)/$($repo.Repo)/$($repo.Branch)/OGD_Timer_0.5ms.ps1"
        $timerDestinations = New-Object System.Collections.Generic.List[string]
        [void]$timerDestinations.Add("C:\OGD\OGD_Timer_0.5ms.ps1")
        try{
            if($PSCommandPath){
                [void]$timerDestinations.Add((Join-Path (Split-Path $PSCommandPath -Parent) 'OGD_Timer_0.5ms.ps1'))
            }
        }catch{}
        foreach($timerDst in @($timerDestinations | Select-Object -Unique)){
            try{
                $parent = Split-Path $timerDst -Parent
                if($parent -and -not (Test-Path $parent)){
                    New-Item -Path $parent -ItemType Directory -Force | Out-Null
                }
                Invoke-WebRequest -Uri $timerRaw -OutFile $timerDst -UseBasicParsing -TimeoutSec 60 -EA Stop
                Write-Host "  ✓ Timer aggiornato: $timerDst" -F Green
            }catch{}
        }
        Write-Host "  ✓ Aggiornamento completato alla v$($latest.Version)" -F Green
        Start-Sleep 2
    }catch{
        Write-Host "  ⚠ Aggiornamento automatico fallito." -F Yellow
        Write-Host "  Scarica manualmente da: $($latest.HtmlUrl)" -F DarkGray
        Start-Sleep 3
    }
}

#  AUTO-UPDATE CHECK
# ═════════════════════════════════════════════════════════════════════════════

$currentVersion = Get-OgdCurrentScriptVersion -FallbackVersion '8.1.2'
# FIX: salta l'aggiornamento della versione installata dello script; controlla solo eventuale repo senza sovrascrivere il file installato
$installedScript=''
Invoke-OgdOfficialRepoUpdateCheck -CurrentVersion $currentVersion -InstalledScript $installedScript

if($false -and (Test-Path $installedScript)){
    $installedContent=Get-Content $installedScript -Raw
    if($installedContent -match 'OGD WinCaffe NEXT v(\d+\.\d+\.\d+(?:(?:HF|HotFix)\d+)?)'){
        $installedVersion=$Matches[1]

        if((Compare-OgdVersions -LeftVersion $currentVersion -RightVersion $installedVersion) -gt 0){
            Clear-Host
            Write-Host "`n  🔄 AGGIORNAMENTO DISPONIBILE`n" -F Yellow
            Write-Host "  Installata: v$installedVersion" -F White
            Write-Host "  Disponibile: v$currentVersion`n" -F Green

            # Controlla se stai già eseguendo dalla cartella di installazione
            $isSameFile = ($PSCommandPath -and (Resolve-Path $PSCommandPath -EA SilentlyContinue) -eq (Resolve-Path $installedScript -EA SilentlyContinue))

            if($isSameFile){
                # Stai lanciando wincaffe — il file installato è già questo
                Write-Host "  ℹ Stai eseguendo la versione installata ($installedVersion)." -F Cyan
                Write-Host "  Per aggiornare alla v${currentVersion}:" -F White
                Write-Host "   1. Scarica il nuovo ZIP da Discord o dal sito" -F DarkGray
                Write-Host "   2. Estrai e lancia il nuovo OGD_WinCaffe_ULTIMATE.ps1" -F DarkGray
                Write-Host "   3. Lo script si aggiornerà automaticamente`n" -F DarkGray
                Start-Sleep 3
            } else {
                if((Read-Host "  Aggiornare script installato? (S/N)") -in @("S","s")){
                    Copy-Item $PSCommandPath $installedScript -Force
                    Write-Host "  ✓ Script aggiornato a v$currentVersion!" -F Green
                    # Copia anche il timer se presente
                    $timerSrc = Join-Path (Split-Path $PSCommandPath) "OGD_Timer_0.5ms.ps1"
                    $timerDst = "C:\OGD\OGD_Timer_0.5ms.ps1"
                    if((Test-Path $timerSrc) -and ($timerSrc -ne $timerDst)){
                        Copy-Item $timerSrc $timerDst -Force
                        Write-Host "  ✓ Timer aggiornato!" -F Green
                    }
                    Start-Sleep 2
                }
            }
        }
    }
}

# ═════════════════════════════════════════════════════════════════════════════
#  POWERSHELL RUNTIME CHECK
# ═════════════════════════════════════════════════════════════════════════════
# Gestito subito dopo l'accettazione utente tramite Invoke-OgdPowerShellRuntimeCheck

# ═════════════════════════════════════════════════════════════════════════════
#  .NET RUNTIME/SDK CHECK & AUTO-INSTALL (versioni dinamiche - auto-discovery)
# ═════════════════════════════════════════════════════════════════════════════

Clear-Host
Write-Host "`n  CHECK DIPENDENZE .NET (rilevamento automatico versioni)`n" -F Cyan
Write-Host "  Ricerca versioni disponibili su winget..." -F DarkGray

# ── DISCOVERY DINAMICA ──────────────────────────────────────────────────────
# Una sola chiamata winget search per trovare le versioni stabili disponibili

$dotnetVersions = @()
try {
    $searchOut = winget search "Microsoft.DotNet.Runtime." --accept-source-agreements 2>$null
    foreach($line in $searchOut){
        if($line -match "Microsoft\.DotNet\.Runtime\.(\d+)\s"){
            $ver = $Matches[1]
            if([int]$ver -ge 6 -and [int]$ver -le 10 -and $ver -notin $dotnetVersions){
                $dotnetVersions += $ver
            }
        }
    }
    $dotnetVersions = $dotnetVersions | Sort-Object {[int]$_}
} catch {}

if($dotnetVersions.Count -eq 0){
    Write-Host "  ⚠ Discovery fallita, uso versioni base note" -F Yellow
    $dotnetVersions = @("6","7","8","9","10")
}

Write-Host "  ✓ Versioni stabili trovate: $($dotnetVersions -join ', ')" -F Green

# ── UNA SOLA CHIAMATA winget list — poi tutto in memoria ────────────────────
Write-Host "  Lettura pacchetti installati..." -F DarkGray

# winget list con timeout 90s per evitare freeze
$wgListJob = Start-Job { winget list --accept-source-agreements 2>$null | Out-String }
$wgListDone = Wait-Job $wgListJob -Timeout 90
$wingetListRaw = if($wgListDone){ Receive-Job $wgListJob }else{
    Stop-Job $wgListJob
    Write-Host "  ⚠ winget list timeout — lista programmi non disponibile" -ForegroundColor Yellow
    ""
}
Remove-Job $wgListJob -Force -EA SilentlyContinue

$previewTypes = @(
    @{Label="Runtime Preview"; ID="Microsoft.DotNet.Runtime.Preview"; Match='Microsoft\.DotNet\.Runtime\.Preview'},
    @{Label="Desktop Preview"; ID="Microsoft.DotNet.DesktopRuntime.Preview"; Match='Microsoft\.DotNet\.DesktopRuntime\.Preview'},
    @{Label="SDK Preview"; ID="Microsoft.DotNet.SDK.Preview"; Match='Microsoft\.DotNet\.SDK\.Preview'}
)

$vcRedistTypes = @(
    @{Label="Visual C++ 2015-2022 x64"; ID="Microsoft.VCRedist.2015+.x64"; Match='Microsoft\.VCRedist\.2015\+\.x64'},
    @{Label="Visual C++ 2015-2022 x86"; ID="Microsoft.VCRedist.2015+.x86"; Match='Microsoft\.VCRedist\.2015\+\.x86'},
    @{Label="Visual C++ 2013 x64"; ID="Microsoft.VCRedist.2013.x64"; Match='Microsoft\.VCRedist\.2013\.x64'},
    @{Label="Visual C++ 2013 x86"; ID="Microsoft.VCRedist.2013.x86"; Match='Microsoft\.VCRedist\.2013\.x86'},
    @{Label="Visual C++ 2012 x64"; ID="Microsoft.VCRedist.2012.x64"; Match='Microsoft\.VCRedist\.2012\.x64'},
    @{Label="Visual C++ 2012 x86"; ID="Microsoft.VCRedist.2012.x86"; Match='Microsoft\.VCRedist\.2012\.x86'},
    @{Label="Visual C++ 2010 x64"; ID="Microsoft.VCRedist.2010.x64"; Match='Microsoft\.VCRedist\.2010\.x64'},
    @{Label="Visual C++ 2010 x86"; ID="Microsoft.VCRedist.2010.x86"; Match='Microsoft\.VCRedist\.2010\.x86'}
)

$stableDotnetPackages = @()
foreach($ver in $dotnetVersions){
    $stableDotnetPackages += @(
        @{Label="Runtime $ver"; ID="Microsoft.DotNet.Runtime.$ver"; Match="Microsoft\.DotNet\.Runtime\.$ver\s"},
        @{Label="Desktop $ver"; ID="Microsoft.DotNet.DesktopRuntime.$ver"; Match="Microsoft\.DotNet\.DesktopRuntime\.$ver\s"},
        @{Label="SDK $ver"; ID="Microsoft.DotNet.SDK.$ver"; Match="Microsoft\.DotNet\.SDK\.$ver\s"}
    )
}

$dependencyCatalog = @($stableDotnetPackages + $previewTypes + $vcRedistTypes)
$missingDotnet  = @()
$installedDotnet = @()

foreach($pkg in $dependencyCatalog){
    if($wingetListRaw -match $pkg.Match){
        $installedDotnet += $pkg.Label
    } else {
        $missingDotnet += $pkg.Label
    }
}

Write-Host "  ✓ Check completato`n" -F Green

# ── RISULTATO ───────────────────────────────────────────────────────────────

if($missingDotnet.Count -gt 0){
    Write-Host "  ✓ Installati: $($installedDotnet.Count)" -F Green
    Write-Host "  ✗ Mancanti:  $($missingDotnet.Count)" -F Red
    Write-Host "`n  Componenti mancanti:" -F Yellow
    foreach($m in $missingDotnet){ Write-Host "   • $m" -F Red }

    Write-Host "`n  Consigliato: installare runtime, SDK, preview utili e Visual C++ mancanti`n" -F Cyan

    if((Read-Host "  Installare componenti mancanti? (S/N)") -in @("S","s")){
        Write-Host ""
        foreach($pkg in $dependencyCatalog){
            if($missingDotnet -contains $pkg.Label){
                Write-Host "  Installazione $($pkg.Label)..." -F Cyan
                winget install $pkg.ID --silent --accept-source-agreements --accept-package-agreements
                if($LASTEXITCODE -eq 0){ Write-Host "  ✓ $($pkg.Label) installato!" -F Green }
            }
        }
        Write-Host "`n  ✓ Installazione dipendenze completata!`n" -F Green
        Start-Sleep 2
    }
}else{
    Write-Host "  ✓ Tutte le dipendenze controllate risultano presenti! ($($installedDotnet.Count) componenti)`n" -F Green

    if((Read-Host "  Verificare aggiornamenti dipendenze? (S/N)") -in @("S","s")){
        Write-Host ""
        $upgCount = 0
        foreach($pkg in $dependencyCatalog){
            Write-Host "  Aggiornamento $($pkg.Label)..." -F Cyan
            $rp = winget upgrade $pkg.ID --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-String
            if($rp -notmatch "non sono stati trovati|no applicable|no newer|already installed|non sono disponibili"){
                Write-Host "  ✓ $($pkg.Label) aggiornato!" -F Green
                $upgCount++
            } else {
                Write-Host "  → $($pkg.Label) già aggiornato" -F DarkGray
            }
        }
        if($upgCount -eq 0){ Write-Host "`n  ✓ Tutto già aggiornato!`n" -F Green }
        else                { Write-Host "`n  ✓ $upgCount componenti aggiornati!`n" -F Green }
        Start-Sleep 2
    }
}

# ═════════════════════════════════════════════════════════════════════════════
#  ACCESSIBILITÀ OPZIONALE: OPENDYSLEXIC
# ═════════════════════════════════════════════════════════════════════════════

$odStatusStartup = Get-OgdOpenDyslexicStatus
Clear-Host
Write-Host "`n  ╔═══════════════════════════════════════════════════════╗" -F Cyan
Write-Host "  ║          ACCESSIBILITÀ OPZIONALE - OpenDyslexic      ║" -F Cyan
Write-Host "  ╚═══════════════════════════════════════════════════════╝`n" -F Cyan
Write-Host '  OpenDyslexic è consigliato solo a chi ha dislessia o' -F White
Write-Host '  difficoltà di lettura. Non viene più installato in automatico.`n' -F DarkGray

if($odStatusStartup.FullyInstalled -and $odStatusStartup.FullyRegistered){
    Write-Success "OpenDyslexic già pronto ($($odStatusStartup.InstalledCount)/4 file)"
} elseif($odStatusStartup.PartiallyInstalled){
    Write-Warning "OpenDyslexic presente solo in parte ($($odStatusStartup.InstalledCount)/4 file)"
    Write-Host "    Mancano: $($odStatusStartup.MissingFiles -join ', ')" -F DarkGray
} elseif($odStatusStartup.Installed){
    Write-Warning 'OpenDyslexic trovato ma non registrato bene'
} else {
    Write-Host '  • Stato: non installato' -F DarkGray
}

$script:OpenDyslexicManagerRequestedAtStartup = $false
$odChoice = if($WizardSkipOpenDyslexic){ 'N' } else { Read-Host '  Aprire il gestore OpenDyslexic adesso? (solo se ti serve accessibilità o vuoi rimuoverlo) (S/N)' }
if($odChoice -in @('S','s')){
    $script:OpenDyslexicManagerRequestedAtStartup = $true
}

# ═════════════════════════════════════════════════════════════════════════════
#  MENU INSTALLAZIONE/DISINSTALLAZIONE
# ═════════════════════════════════════════════════════════════════════════════

Clear-Host
Write-Host "`n  ╔═══════════════════════════════════════════════════════╗" -F Cyan
Write-Host "  ║         OGD WinCaffe NEXT v8.1.2 - Installazione     ║" -F Cyan
Write-Host "  ╚═══════════════════════════════════════════════════════╝`n" -F Cyan

Write-Host "  [1] INSTALLA - Aggiungi comando 'wincaffe' globale" -F Green
Write-Host "      Copia script in C:\OGD\ + comando PowerShell" -F DarkGray
Write-Host "`n  [2] DISINSTALLA - Rimuovi comando 'wincaffe'" -F Red
Write-Host "      Pulisce tutto (script + profilo PowerShell)" -F DarkGray
Write-Host "`n  [3] ESEGUI - Avvia normalmente (senza installare)`n" -F Yellow

$setupChoice = if($WizardSetupChoice -in @('1','2','3')){
    Write-Host ("  > Wizard GUI: selezione automatica setup {0}" -f $WizardSetupChoice) -F DarkGray
    $WizardSetupChoice
} else {
    Read-Host "  Scelta (1/2/3)"
}

if($setupChoice -eq "1"){
    # INSTALLAZIONE
    Clear-Host
    Write-Host "`n  INSTALLAZIONE OGD WINCAFFE NEXT`n" -F Green
    
    # Percorso installazione
    $installDir="C:\OGD"
    $scriptDest="$installDir\OGD_WinCaffe_ULTIMATE.ps1"
    
    # Crea cartella
    if(!(Test-Path $installDir)){New-Item $installDir -ItemType Directory -Force|Out-Null}
    
    # Copia script — confronto percorsi case-insensitive e normalizzato
    $srcResolved  = (Resolve-Path $PSCommandPath -EA SilentlyContinue).Path
    $destResolved = $scriptDest
    if($srcResolved -and ($srcResolved.ToLower() -ne $destResolved.ToLower())){
        Copy-Item $PSCommandPath $scriptDest -Force
        Write-Host "  ✓ Script copiato: $scriptDest" -F Green
    }else{
        Write-Host "  ✓ Script già nella posizione corretta" -F Green
    }

    # Copia anche il timer se presente nella stessa cartella
    $timerSrcInst = Join-Path (Split-Path $PSCommandPath) "OGD_Timer_0.5ms.ps1"
    $timerDstInst = "$installDir\OGD_Timer_0.5ms.ps1"
    if((Test-Path $timerSrcInst) -and ($timerSrcInst.ToLower() -ne $timerDstInst.ToLower())){
        Copy-Item $timerSrcInst $timerDstInst -Force
        Write-Host "  ✓ Timer copiato: $timerDstInst" -F Green
    }
    
    # Determina profilo PowerShell (5.1 vs 7+)
    $profilePath=$PROFILE.CurrentUserAllHosts
    if(!$profilePath){$profilePath="$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"}
    
    # Backup profilo esistente
    if(Test-Path $profilePath){
        $bkProfile="$profilePath.ogd_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $profilePath $bkProfile -Force
        Write-Host "  ✓ Backup profilo: $bkProfile" -F Green
    }
    
    # Crea/aggiorna profilo con function wincaffe
    $profileDir=Split-Path $profilePath
    if(!(Test-Path $profileDir)){New-Item $profileDir -ItemType Directory -Force|Out-Null}
    
    # ── Costruisci il codice wincaffe da scrivere nel profilo ─────────────────
    # Usiamo singoli apici per tutti i valori — nessun problema di escaping
    $wincaffeBlock = @'
# <<<OGD_WINCAFFE_START>>>
function wincaffe {
    $sp = 'SCRIPTPATH_PLACEHOLDER'
    if(-not (Test-Path $sp)){
        Write-Host ('OGD WinCaffe non trovato: ' + $sp) -ForegroundColor Red
        Write-Host 'Riesegui installer per reinstallare.' -ForegroundColor Yellow
        return
    }
    $adm = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $exe = if(Get-Command pwsh -EA SilentlyContinue){'pwsh'}else{'powershell'}
    if(-not $adm){
        Start-Process -FilePath $exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$sp) -Verb RunAs
    }else{
        & $exe -NoProfile -ExecutionPolicy Bypass -File $sp
    }
}
Write-Host 'OGD WinCaffe NEXT pronto - usa: wincaffe' -ForegroundColor Cyan
# <<<OGD_WINCAFFE_END>>>
'@
    # Sostituisci il placeholder con il percorso reale
    $wincaffeBlock = $wincaffeBlock.Replace('SCRIPTPATH_PLACEHOLDER', $scriptDest)

    # Aggiungi/sostituisci blocco nel profilo usando i marcatori
    if(Test-Path $profilePath){
        $existingContent = Get-Content -LiteralPath $profilePath -Raw -EA SilentlyContinue
        if(-not $existingContent){ $existingContent = "" }

        $preErrors = @(Test-OgdProfileParse -Content $existingContent)
        $cleaned = Remove-OgdWinCaffeProfileBlock -Content $existingContent

        if($preErrors.Count -gt 0){
            $brokenPath = "$profilePath.ogd_broken_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item -LiteralPath $profilePath -Destination $brokenPath -Force
            Set-Content -LiteralPath $profilePath -Value $wincaffeBlock -Encoding UTF8
            Write-Host "  ! Profilo PowerShell corrotto rilevato: creato profilo pulito" -F Yellow
            Write-Host "  ✓ Copia del profilo corrotto: $brokenPath" -F Green
        } elseif([string]::IsNullOrWhiteSpace($cleaned)){
            Set-Content -LiteralPath $profilePath -Value $wincaffeBlock -Encoding UTF8
        } else {
            Set-Content -LiteralPath $profilePath -Value ($cleaned + "`n`n" + $wincaffeBlock) -Encoding UTF8
        }

        if($existingContent -match 'function\s+wincaffe|<<<OGD_WINCAFFE_START>>>'){
            Write-Host "  ✓ Funzione wincaffe aggiornata" -F Green
        } else {
            Write-Host "  ✓ Funzione wincaffe aggiunta al profilo" -F Green
        }
    } else {
        Set-Content -LiteralPath $profilePath -Value $wincaffeBlock -Encoding UTF8
        Write-Host "  ✓ Profilo PowerShell creato" -F Green
    }
    Write-Host "`n  ════════════════════════════════════════════════════" -F Cyan
    Write-Host "   ⚡ INSTALLAZIONE COMPLETATA! ⚡" -F Yellow
    Write-Host "  ════════════════════════════════════════════════════`n" -F Cyan
    Write-Host "  PROSSIMI PASSI:" -F Cyan
    Write-Host "  1. Chiudi e riapri PowerShell" -F White
    Write-Host "  2. Digita: " -NoNewline -F White;Write-Host "wincaffe" -F Yellow
    Write-Host "  3. Lo script si aprirà ovunque tu sia!`n" -F White
    
    Read-Host "  INVIO per uscire"
    exit
}

if($setupChoice -eq "2"){
    # DISINSTALLAZIONE
    Clear-Host
    Write-Host "`n  DISINSTALLAZIONE OGD WINCAFFE NEXT`n" -F Red
    
    if((Read-Host "  Confermi disinstallazione? (S/N)") -notin @("S","s")){exit}
    
    $installDir="C:\OGD"
    $scriptDest="$installDir\OGD_WinCaffe_ULTIMATE.ps1"
    $timerDest="$installDir\OGD_Timer_0.5ms.ps1"

    # Rimuovi script principali
    foreach($fileToRemove in @($scriptDest,$timerDest)){
        if(Test-Path $fileToRemove){
            Remove-Item -LiteralPath $fileToRemove -Force
            Write-Host "  ✓ File rimosso: $fileToRemove" -F Green
        }
    }

    # Rimuovi function dal profilo
    $profilePath=$PROFILE.CurrentUserAllHosts
    if(!$profilePath){$profilePath="$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"}

    if(Test-Path $profilePath){
        $content=Get-Content -LiteralPath $profilePath -Raw -EA SilentlyContinue
        if($null -eq $content){ $content = "" }

        $content=[regex]::Replace($content,'(?ms)^\s*# <<<OGD_WINCAFFE_START>>>.*?^# <<<OGD_WINCAFFE_END>>>\s*','')
        $content=[regex]::Replace($content,'(?ms)^\s*function\s+wincaffe\s*\{.*?^\}\s*','')
        $content=$content.Trim()

        if([string]::IsNullOrWhiteSpace($content)){
            Set-Content -LiteralPath $profilePath -Value "" -Encoding UTF8
        } else {
            Set-Content -LiteralPath $profilePath -Value $content -Encoding UTF8
        }
        Write-Host "  ✓ Profilo PowerShell pulito" -F Green
    }

    # Rimuovi cartella se vuota
    if(Test-Path $installDir){
        $items=@(Get-ChildItem -Force $installDir -EA SilentlyContinue)
        if($items.Count -eq 0){
            Remove-Item -LiteralPath $installDir -Force
            Write-Host "  ✓ Cartella rimossa: $installDir" -F Green
        }
    }

    Write-Host "`n  ════════════════════════════════════════════════════" -F Cyan
    Write-Host "   ⚡ DISINSTALLAZIONE COMPLETATA! ⚡" -F Yellow
    Write-Host "  ════════════════════════════════════════════════════`n" -F Cyan
    Write-Host "  Il comando 'wincaffe' non è più disponibile.`n" -F White
    
    Read-Host "  INVIO per uscire"
    exit
}

# Se scelta 3 o altro, continua normalmente

# ═════════════════════════════════════════════════════════════════════════════
#  FUNZIONI UI
# ═════════════════════════════════════════════════════════════════════════════

function Show-Banner {
    Clear-Host
    Write-Host "`n  ╔═══════════════════════════════════════════════════════╗" -F Cyan
    Write-Host "  ║                                                       ║" -F Cyan
    Write-Host "  ║     ▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄  ▄▄▄▄▄▄                         ║" -F Yellow
    Write-Host "  ║    █       ██       ██      █                        ║" -F Yellow
    Write-Host "  ║    █   ▄   ██   ▄▄▄▄█  ▄    █  WinCaffe NEXT 8.1.2 ║" -F Yellow
    Write-Host "  ║    █  █ █  ██  █  ▄▄█ █ █   █  ULTIMATE              ║" -F Yellow
    Write-Host "  ║    █  █▄█  ██  █ █  █ █▄█   █                        ║" -F Yellow
    Write-Host "  ║    █       ██  █▄▄█ █       █                        ║" -F Yellow
    Write-Host "  ║    █▄▄▄▄▄▄▄██▄▄▄▄▄▄▄█▄▄▄▄▄▄█                         ║" -F Yellow
    Write-Host "  ║                                                       ║" -F Cyan
    Write-Host "  ║           #DarkPlayer84Tv Productions                ║" -F Green
    Write-Host "  ║         by OldGamerDarthy Official                   ║" -F Green
    Write-Host "  ║                                                       ║" -F Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════╝" -F Cyan
    Write-Host "`n                      ( (                                " -F DarkGray
    Write-Host "                       ) )                                 " -F Gray
    Write-Host "                    .........                              " -F Yellow
    Write-Host "                    |       |]                            " -F Yellow
    Write-Host "                    \       /                              " -F Yellow
    Write-Host "                 ~~~~~~~~~~~~~~`n                          " -F DarkYellow
    Write-Host "      Ottimizzazione Gaming Windows by OGD" -F Cyan
    Write-Host "        Original Gaming Design - DarkPlayer84Tv" -F DarkGray
    Write-Host "        Target attivo: $(Get-OgdTargetLabel)" -F White
    Write-Host "        Scelta rapida: [2] bilanciato  [4] laptop  [H] hotfix  [8] info`n" -F Yellow
}

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  +--------------------------------------------------------------------+" -F DarkGray
    Write-Host "  | OGD WINCAFFE NEXT 8.1.2                                           |" -F Black -BackgroundColor Gray
    Write-Host "  | Windows NT Professional Tuning Console                             |" -F Black -BackgroundColor Gray
    Write-Host "  +--------------------------------------------------------------------+" -F DarkGray
    Write-Host "  | PROFILES | GAMING | DEVICES | REPAIR | TOOLS   | SUPPORT          |" -F Black -BackgroundColor White
    Write-Host "  +--------------------------------------------------------------------+" -F DarkGray
    Write-Host "  | STATUS : READY                                                     |" -F Cyan
    $targetLabel = (Get-OgdTargetLabel).PadRight(58)
    Write-Host "  | TARGET : $targetLabel|" -F White
    $pathLine = ("  | PATH   : [2] NORMALE   [A] GAMING   {0,-12} [H] HOTFIX        |" -f (Get-OgdAdaptiveBannerPathLabel))
    Write-Host $pathLine -F Yellow
    Write-Host "  +--------------------------------------------------------------------+`n" -F DarkGray
}

function Show-Steam {
    Write-Host "  Sessione workstation inizializzata." -F DarkGray
}

function Write-Section([string]$T){
    Write-Host ""
    Write-Host "  +--------------------------------------------------------------------+" -F DarkGray
    Write-Host ("  | {0} |" -f $T.ToUpper().PadRight(66)) -F Black -BackgroundColor Gray
    Write-Host "  +--------------------------------------------------------------------+" -F DarkGray
}

function Show-OgdMainMenu801 {
    $pcTypeLabel = if($script:OgdPcType){ $script:OgdPcType } else { 'Desktop' }
    $isDesktopUi = ($script:OgdIsDesktop -or [string]::IsNullOrWhiteSpace($script:OgdPcType))
    $isLaptopUi = $script:OgdIsLaptop
    $isLaptopGamingUi = $script:OgdIsLaptopGaming
    $recommendedProfile = if($isLaptopGamingUi){ '[5] LAPTOP GAMING' } elseif($isLaptopUi){ '[4] LAPTOP' } else { '[2] NORMALE' }
    $secondaryProfile = if($isLaptopGamingUi){ '[A] AGGRESSIVO GAMING' } elseif($isLaptopUi){ '[5] LAPTOP GAMING' } else { '[A] AGGRESSIVO GAMING' }
    $panelTitle = if($isLaptopGamingUi){ 'MOBILE GAMING OPERATIONS PANEL' } elseif($isLaptopUi){ 'MOBILE WORKSTATION OPERATIONS PANEL' } else { 'DESKTOP OPERATIONS PANEL' }
    $hintOne = if($isLaptopGamingUi){
        '> [5] e il ramo principale per notebook gaming con livelli dedicati'
    } elseif($isLaptopUi){
        '> [4] e il ramo principale per notebook standard e ultrabook'
    } else {
        '> [2] resta il preset consigliato per la maggior parte dei desktop'
    }
    $hintTwo = if($isLaptopGamingUi){
        '> [A] e [C] servono come supporto gaming dedicato quando vuoi spingere di piu'
    } elseif($isLaptopUi){
        '> [5] va usato solo se il notebook e davvero una macchina gaming in carica'
    } else {
        '> [A] e [C] raccolgono i percorsi piu orientati al gaming desktop'
    }
    $hintThree = if($isLaptopGamingUi){
        '> [H] per fix mirati, [J] per ponte legacy e rollback rapido'
    } elseif($isLaptopUi){
        '> [H] per fix mirati, [J] per ponte legacy e rollback rapido'
    } else {
        '> [H] per fix mirati, [J] per ponte legacy e rollback rapido'
    }

    Write-Host "  +--------------------------------+  +--------------------------------+" -F DarkGray
    Write-Host "  | CORE PROFILES                  |  | TOOLS AND SPECIAL MODULES      |" -F Black -BackgroundColor Gray
    Write-Host "  +--------------------------------+  +--------------------------------+" -F DarkGray
    Write-Host "  | [1] LIGHT                      |  | [7] EXPLORER   [8] INFO       |" -F Green
    Write-Host "  | [2] NORMALE                    |  | [9] RESET      [F] FILE I/O   |" -F Yellow
    Write-Host "  | [3] AGGRESSIVO                 |  | [U] WINGET     [W] WINREVIVE  |" -F Red
    Write-Host "  | [A] AGGRESSIVO GAMING          |  | [O] PRESETS    [V] INTEL GPU  |" -F Cyan
    Write-Host "  | [4] LAPTOP                     |  | [G] NVIDIA     [R] AMD GPU    |" -F Green
    Write-Host "  | [5] LAPTOP GAMING              |  | [I] INTEL CPU  [X] AMD CPU    |" -F Yellow
    Write-Host "  +--------------------------------+  | [L] DPC FIX   [P] NPU        |" -F DarkGray
    Write-Host "                                        | [E] UNREAL    [C] COD        |" -F White
    Write-Host ("                                        | [M] MOUSE     {0,-15}|" -f (Get-OgdAdaptiveBetaLabel)) -F White
    Write-Host "                                        | [D] DISCORD                    |" -F White
    Write-Host "  +--------------------------------------------------------------------+" -F DarkGray
    Write-Host ("  | {0}" -f $panelTitle.PadRight(66)) -F Black -BackgroundColor Gray
    Write-Host "  +--------------------------------------------------------------------+" -F DarkGray
    Write-Host ("  | [Q] BENCHMARK   [T] MICRO TWEAKS   [K] SSD/NVME   {0,-18}|" -f (Get-OgdAdaptiveWindowsMenuLabel)) -F White
    Write-Host "  | [H] HOTFIX 8.1.2   [J] FIX PRE 8.1.1         [Z] CAMBIA PROFILO  |" -F Yellow
    Write-Host "  | [0] ESCI                                                           |" -F Yellow
    Write-Host ("  | PC TYPE : {0}" -f $pcTypeLabel.PadRight(56)) -F White
    Write-Host ("  | PATH    : principale {0,-18} secondario {1,-16}|" -f $recommendedProfile,$secondaryProfile) -F DarkCyan
    Write-Host ("  | {0}" -f $hintOne.PadRight(66)) -F DarkGray
    Write-Host ("  | {0}" -f $hintTwo.PadRight(66)) -F DarkGray
    Write-Host ("  | {0}" -f $hintThree.PadRight(66)) -F DarkGray
    Write-Host "  | > [Z] riapre subito la scelta Desktop / Laptop / Laptop Gaming    |" -F DarkGray
    Write-Host "  +--------------------------------------------------------------------+`n" -F DarkGray
    Write-Host ""
}

function Write-MenuHint {
    param(
        [string]$Title,
        [string[]]$Lines = @()
    )
    if(-not [string]::IsNullOrWhiteSpace($Title)){
        Write-Host "  [INFO] $Title" -F Cyan
    }
    foreach($line in @($Lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })){
        Write-Host "     > $line" -F DarkGray
    }
    Write-Host ""
}

function Write-Success([string]$M){Write-Host "  [OK] $M" -F Green}
function Write-Info([string]$M){Write-Host "  [INFO] $M" -F Cyan}
function Write-Warning([string]$M){Write-Host "  [WARN] $M" -F Yellow}

function Show-OgdWorkingAnimation {
    param(
        [string]$Text = 'Operazione in corso...',
        [int]$DurationMs = 900,
        [ConsoleColor]$Color = [ConsoleColor]::Cyan
    )
    $supports = $false
    try{
        if(-not [Console]::IsOutputRedirected){ $supports = $true }
    }catch{}
    if(-not $supports){
        Start-Sleep -Milliseconds ([Math]::Min([Math]::Max($DurationMs,150),1800))
        return
    }
    $frames = @('|','/','-','\')
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $i = 0
    while($sw.ElapsedMilliseconds -lt $DurationMs){
        $frame = $frames[$i % $frames.Count]
        Write-Host ("`r  {0} {1}" -f $frame, $Text.PadRight(62)) -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds 85
        $i++
    }
    Write-Host ("`r  ✓ {0}" -f $Text.PadRight(62)) -ForegroundColor Green
}

function Show-OgdWhatThisDoes {
    param(
        [string]$Title = 'Cosa è stato fatto',
        [string[]]$Lines = @()
    )
    if($Title){
        Write-Host "  [DONE] $Title" -F White
    }
    foreach($line in @($Lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })){
        Write-Host "     > $line" -F DarkGray
    }
    Write-Host ""
}

function Show-OgdAppliedSummary {
    param([string]$Profile)
    switch($Profile){
        'LIGHT' {
            Show-OgdWhatThisDoes 'Questo profilo ha applicato' @(
                'timer, rete ed Explorer in modalità safe per dare più prontezza senza cambiare troppo Windows',
                'menu, shell e cache leggere per uso quotidiano, login più rapido e minori tempi morti della UI',
                'tweak compatibili con quasi tutti i PC, senza toccare memoria profonda o shutdown aggressivo'
            )
        }
        'NORMALE' {
            Show-OgdWhatThisDoes 'Questo profilo ha applicato' @(
                'tutto il pacchetto Light, più priorità processi per Explorer, Edge, MMC, MSIExec e servizi da lavoro/gaming',
                'ottimizzazioni AI/NPU quando supportate, più tweaks moderati su login, logout, riavvio e avvio sessione',
                'profilo completo ma ancora equilibrato tra prestazioni, compatibilità e pulizia del sistema'
            )
        }
        'AGGRESSIVO' {
            Show-OgdWhatThisDoes 'Questo profilo ha applicato' @(
                'tweak piu spinti ma con approccio termico piu prudente su scheduler, storage, MMCSS, Game Mode e servizi secondari',
                'riduzione di overhead e latenze per gaming/carichi pesanti, evitando boost CPU troppo aggressivo o unparking totale continuo',
                'profilo forte ma non estremo: se in estate o nei giochi piu pesanti noti caldo anomalo, schermo nero o freeze, meglio scendere a NORMALE'
            )
        }
        'FILEIO' {
            Show-OgdWhatThisDoes 'Questo profilo ha applicato' @(
                'ottimizzazioni NTFS e cache per ridurre lavoro inutile su file system',
                'migliorie ai trasferimenti di rete e accesso ai file condivisi',
                'setup orientato a copie, installazioni, decompressioni e caricamenti più rapidi'
            )
        }
        'DPC' {
            Show-OgdWhatThisDoes 'Questo profilo ha applicato' @(
                'power plan, servizi e controlli prudenziali per ridurre alcune cause comuni di latenza DPC senza spingere tweak low-level gratuiti',
                'fix mirati a micro-freeze, crackle audio e stuttering periodico, senza presentare il timer come cura universale',
                'nei livelli avanzati interviene solo su aree ragionevoli di interrupt, driver e storage per migliorare la risposta con approccio conservativo'
            )
        }
        'NVIDIA' {
            Show-OgdWhatThisDoes 'NVIDIA: cosa è stato fatto davvero' @(
                'raccolte ottimizzazioni lato Windows e diagnostica utile per GPU NVIDIA moderne, senza forzare registry tweak legacy del driver',
                'messi in evidenza controlli reali che contano di più: driver aggiornato, refresh corretto, HAGS stabile e configurazione pulita',
                'profilo pensato per ridurre tweak placebo e lasciare i settaggi sensibili al pannello NVIDIA o alla NVIDIA App'
            )
        }
        'NPU' {
            Show-OgdWhatThisDoes 'NPU / AI: cosa è stato fatto davvero' @(
                'abilitato l offload AI verso hardware compatibile quando disponibile, distinguendo tra NPU presente e NPU davvero pronta',
                'alzata la priorità delle operazioni AI/gaming e ridotto il lavoro AI in background che non ti serve mentre giochi o lavori',
                'nei livelli avanzati impostati hint per DirectML, ONNX e power state della NPU, con diagnostica più leggibile'
            )
        }
        'UNREAL' {
            Show-OgdWhatThisDoes 'Unreal Engine: cosa è stato fatto davvero' @(
                'ottimizzati cache, shader e parametri utili a ridurre hitching e caricamenti lenti',
                'migliorata la risposta di CPU, I/O e scheduler per UE4/UE5',
                'profilo pensato per giochi e tool Unreal senza modificare i progetti'
            )
        }
        'WIN24H2' {
            Show-OgdWhatThisDoes 'Windows 11 24H2+: cosa è stato fatto davvero' @(
                'raccolti tweak separati e moderni solo per build 24H2 o successive, senza toccare sistemi Windows 11 più vecchi',
                'priorità a Recall, HAGS, finestra ottimizzata per i giochi e impostazioni gaming coerenti con il ramo moderno di Windows 11',
                'menu pensato per tenere fuori tweak legacy e lasciare in pace chiavi non documentate o troppo dipendenti dal driver'
            )
        }
        'COD' {
            Show-OgdWhatThisDoes 'Call of Duty: cosa è stato fatto davvero' @(
                'applicate ottimizzazioni safe lato Windows per input, scheduler e pulizia del sistema con target esports ad alto FPS',
                'pensato anche per un sotto-profilo RTX 5080 orientato a BO7 e frame rate estremi, ma senza promettere 700 FPS garantiti in ogni scenario',
                'niente tweak pensati per bypass, alterazioni anti-cheat o modifiche rischiose al driver'
            )
        }
        'HOTFIX' {
            Show-OgdWhatThisDoes 'Hotfix: cosa è stato fatto davvero' @(
                'raccolti fix per DX9 legacy, OpenDyslexic e diagnostica NPU in un menu dedicato',
                'aggiunti controlli per compatibilità giochi vecchi e accessibilità opzionale',
                'strumenti pensati per correggere problemi reali senza toccare tutto il resto'
            )
        }
        'FIXPRE778' {
Show-OgdWhatThisDoes 'Fix legacy: ramo storico bonificato prima di 8.1.1' @(
                'il vecchio fix per build 7.x non è più proposto nel menu principale',
                'la manutenzione corrente passa dai profili moderni, dagli hotfix attivi e dai fix rete recenti',
                'questo ramo resta solo come compatibilità storica e non come percorso consigliato'
            )
        }
    }
}


function Get-OgdWingetExecutable {
    $candidates = New-Object System.Collections.Generic.List[string]
    try{
        $cmd1 = Get-Command winget.exe -EA SilentlyContinue
        if($cmd1 -and $cmd1.Source){ [void]$candidates.Add($cmd1.Source) }
    }catch{}
    try{
        $cmd2 = Get-Command winget -EA SilentlyContinue
        if($cmd2 -and $cmd2.Source){ [void]$candidates.Add($cmd2.Source) }
    }catch{}
    try{
        $wa = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'
        if(Test-Path $wa){ [void]$candidates.Add($wa) }
    }catch{}
    return ($candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique | Select-Object -First 1)
}

function Invoke-OgdWinget {
    param(
        [string[]]$Arguments,
        [int]$TimeoutSec = 120
    )
    $exe = Get-OgdWingetExecutable
    if([string]::IsNullOrWhiteSpace($exe)){
        return [pscustomobject]@{ Available=$false; TimedOut=$false; ExitCode=-1; Output='winget.exe non trovato'; Path='' }
    }
    $job = Start-Job -ScriptBlock {
        param($wingetExe,$wingetArgs)
        try{
            $out = & $wingetExe @wingetArgs 2>&1 | Out-String
            $code = $LASTEXITCODE
            if($null -eq $code){ $code = 0 }
        }catch{
            $out = ($_ | Out-String)
            $code = 1
        }
        [pscustomobject]@{ Output=$out; ExitCode=$code }
    } -ArgumentList $exe,$Arguments
    $done = Wait-Job $job -Timeout $TimeoutSec
    if(-not $done){
        Stop-Job $job -EA SilentlyContinue | Out-Null
        Remove-Job $job -Force -EA SilentlyContinue
        return [pscustomobject]@{ Available=$true; TimedOut=$true; ExitCode=408; Output=("Timeout dopo {0} secondi" -f $TimeoutSec); Path=$exe }
    }
    $res = Receive-Job $job -EA SilentlyContinue
    Remove-Job $job -Force -EA SilentlyContinue
    return [pscustomobject]@{
        Available = $true
        TimedOut  = $false
        ExitCode  = if($res){ [int]$res.ExitCode } else { 0 }
        Output    = if($res){ [string]$res.Output } else { '' }
        Path      = $exe
    }
}

function Get-OgdWingetStatus {
    $exe = Get-OgdWingetExecutable
    $status = [ordered]@{
        Available = $false
        Path      = ''
        Version   = ''
        Notes     = @()
    }
    if([string]::IsNullOrWhiteSpace($exe)){
        $status.Notes += 'winget.exe non trovato: di solito serve App Installer aggiornato dal Microsoft Store'
        return [pscustomobject]$status
    }
    $status.Available = $true
    $status.Path      = $exe
    $ver = Invoke-OgdWinget -Arguments @('--version') -TimeoutSec 20
    if(-not $ver.TimedOut -and $ver.Output){
        $status.Version = ($ver.Output -split "`r?`n" | Where-Object { $_ -match '^v?\d' } | Select-Object -First 1).Trim()
    }
    if([string]::IsNullOrWhiteSpace($status.Version)){ $status.Notes += 'versione winget non letta al primo colpo' }
    if($exe -match 'WindowsApps'){ $status.Notes += 'winget sembra arrivare da App Installer (percorso WindowsApps)' }
    return [pscustomobject]$status
}

function Get-OgdSvcHostRecommendedThreshold {
    param(
        [ValidateSet('Default','Balanced','Grouped')]
        [string]$Mode = 'Balanced'
    )
    $defaultThreshold = 3670016
    try{
        $ramKB = [uint64]([math]::Round(((Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue | Select-Object -First 1).TotalPhysicalMemory / 1KB),0))
    }catch{
        $ramKB = [uint64]$defaultThreshold
    }
    switch($Mode){
        'Default' { return [uint32]$defaultThreshold }
        'Balanced' {
            $target = [math]::Max($defaultThreshold, ($ramKB + 262144))
            if($target -gt [uint32]::MaxValue){ $target = [uint32]::MaxValue }
            return [uint32]$target
        }
        'Grouped' { return [uint32]0xFFFFFFFF }
    }
}

function Set-OgdSvcHostSplitMode {
    param(
        [ValidateSet('Default','Balanced','Grouped')]
        [string]$Mode = 'Balanced'
    )
    $threshold = Get-OgdSvcHostRecommendedThreshold -Mode $Mode
    $ctrlPath = 'HKLM:\SYSTEM\CurrentControlSet\Control'
    Set-ItemProperty $ctrlPath -Name 'SvcHostSplitThresholdInKB' -Value $threshold -Type DWord -Force -EA SilentlyContinue
    try{
        $ramKB = [uint64]([math]::Round(((Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue | Select-Object -First 1).TotalPhysicalMemory / 1KB),0))
    }catch{
        $ramKB = 0
    }
    [pscustomobject]@{
        Mode        = $Mode
        ThresholdKB = [uint64]$threshold
        ThresholdMB = [math]::Round($threshold / 1024,0)
        RamMB       = if($ramKB -gt 0){ [math]::Round($ramKB / 1024,0) } else { 0 }
    }
}

function Set-OgdLifecycleTweaks {
    param(
        [ValidateSet('Normal','Aggressive')]
        [string]$Profile = 'Normal'
    )
    $desktopPath   = 'HKCU:\Control Panel\Desktop'
    $serializePath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize'
    if(!(Test-Path $serializePath)){ New-Item $serializePath -Force -EA SilentlyContinue | Out-Null }

    Set-ItemProperty $desktopPath -Name 'AutoEndTasks'         -Value '1' -Type String -Force -EA SilentlyContinue
    Set-ItemProperty $desktopPath -Name 'HungAppTimeout'       -Value '3000' -Type String -Force -EA SilentlyContinue
    $wtka = if($Profile -eq 'Aggressive'){'2500'}else{'4000'}
    Set-ItemProperty $desktopPath -Name 'WaitToKillAppTimeout' -Value $wtka -Type String -Force -EA SilentlyContinue
    Set-ItemProperty $serializePath -Name 'StartupDelayInMSec' -Value 0 -Type DWord -Force -EA SilentlyContinue
    reg add "HKLM\SOFTWARE\Microsoft\Dfrg\BootOptimizeFunction" /v "Enable" /t REG_SZ /d "Y" /f 2>$null | Out-Null

    if($Profile -eq 'Aggressive'){
        Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name 'WaitToKillServiceTimeout' -Value '5000' -Type String -Force -EA SilentlyContinue
    }

    return [pscustomobject]@{
        Profile = $Profile
        WaitToKillAppTimeout = [int]$wtka
        WaitToKillServiceTimeout = if($Profile -eq 'Aggressive'){5000}else{'default'}
    }
}

function Optimize-OgdEdgePolicy {
    $edgePolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    if(!(Test-Path $edgePolicy)){ New-Item $edgePolicy -Force -EA SilentlyContinue | Out-Null }
    Set-ItemProperty $edgePolicy -Name 'StartupBoostEnabled'             -Value 1 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $edgePolicy -Name 'HardwareAccelerationModeEnabled' -Value 1 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $edgePolicy -Name 'BackgroundModeEnabled'           -Value 0 -Type DWord -Force -EA SilentlyContinue
}

function Get-OgdDx9SafeMode {
    try{
        $k = "HKCU:\SOFTWARE\OGD\WinCaffe"
        if(Test-Path $k){
            return ((Get-ItemProperty $k -Name "Dx9LegacySafeMode" -EA SilentlyContinue).Dx9LegacySafeMode -eq 1)
        }
    }catch{}
    return $false
}

function Set-OgdDx9SafeMode {
    param([bool]$Enabled)
    try{
        $k = "HKCU:\SOFTWARE\OGD\WinCaffe"
        if(!(Test-Path $k)){ New-Item $k -Force -EA SilentlyContinue | Out-Null }
        Set-ItemProperty $k -Name "Dx9LegacySafeMode" -Value ([int]$Enabled) -Type DWord -Force -EA SilentlyContinue
    }catch{}
}

function Get-OgdDx9LegacyStatus {
    $dlls = @('d3dx9_43.dll','d3dx9_42.dll','d3dcompiler_43.dll','xinput1_3.dll','xaudio2_7.dll')
    $roots = @(
        [pscustomobject]@{ Label='System32'; Path=(Join-Path $env:SystemRoot 'System32') },
        [pscustomobject]@{ Label='SysWOW64'; Path=(Join-Path $env:SystemRoot 'SysWOW64') }
    )
    $missing = New-Object System.Collections.Generic.List[string]
    $present = New-Object System.Collections.Generic.List[string]
    foreach($root in $roots){
        foreach($dll in $dlls){
            $full = Join-Path $root.Path $dll
            if(Test-Path $full){
                $present.Add("$($root.Label):$dll") | Out-Null
            } else {
                $missing.Add("$($root.Label):$dll") | Out-Null
            }
        }
    }
    [pscustomobject]@{
        Present      = @($present)
        Missing      = @($missing)
        MissingCount = $missing.Count
        Healthy      = ($missing.Count -eq 0)
        Dx9SafeMode  = (Get-OgdDx9SafeMode)
    }
}

function Ensure-OgdFontInterop {
    if(-not ('OGDFontInterop802HF4' -as [type])){
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class OGDFontInterop802HF4 {
    [DllImport("gdi32.dll", CharSet=CharSet.Auto)]
    public static extern int AddFontResource(string lpFileName);
    [DllImport("gdi32.dll", CharSet=CharSet.Auto)]
    public static extern int AddFontResourceEx(string name, uint fl, IntPtr pdv);
    [DllImport("gdi32.dll", CharSet=CharSet.Auto)]
    public static extern bool RemoveFontResourceEx(string name, uint fl, IntPtr pdv);
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
    public const uint WM_FONTCHANGE = 0x001D;
    public const uint FR_PRIVATE = 0x10;
    public const uint FR_NOT_ENUM = 0x20;
    public static readonly IntPtr HWND_BROADCAST = new IntPtr(0xFFFF);
}
"@ -EA SilentlyContinue
    }
}

function Restart-OgdFontSubsystem {
    try{
        Stop-Service -Name 'FontCache' -Force -EA SilentlyContinue
        Start-Sleep -Milliseconds 500
        Start-Service -Name 'FontCache' -EA SilentlyContinue
    }catch{}
    try{
        taskkill /im explorer.exe /f 2>$null | Out-Null
        Start-Sleep -Milliseconds 900
        Start-Process explorer.exe
    }catch{}
}

function Send-OgdFontChangeBroadcast {
    try{
        Ensure-OgdFontInterop
        $r = [IntPtr]::Zero
        [OGDFontInterop802HF4]::SendMessageTimeout([OGDFontInterop802HF4]::HWND_BROADCAST,[OGDFontInterop802HF4]::WM_FONTCHANGE,[IntPtr]::Zero,[IntPtr]::Zero,2,1500,[ref]$r) | Out-Null
    }catch{}
}

function Ensure-OgdClearTypeEnabled {
    $fontDesktop = 'HKCU:\Control Panel\Desktop'
    if(!(Test-Path $fontDesktop)){ New-Item $fontDesktop -Force -EA SilentlyContinue | Out-Null }
    Set-ItemProperty $fontDesktop -Name 'FontSmoothing' -Value '2' -Type String -Force -EA SilentlyContinue
    Set-ItemProperty $fontDesktop -Name 'FontSmoothingType' -Value 2 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $fontDesktop -Name 'FontSmoothingGamma' -Value 1500 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $fontDesktop -Name 'FontSmoothingOrientation' -Value 1 -Type DWord -Force -EA SilentlyContinue
}

function Get-OgdOpenDyslexicCatalog {
    @(
        [pscustomobject]@{ File='OpenDyslexic-Regular.otf';    Face='OpenDyslexic';             RegName='OpenDyslexic Regular (OpenType)' },
        [pscustomobject]@{ File='OpenDyslexic-Bold.otf';       Face='OpenDyslexic Bold';        RegName='OpenDyslexic Bold (OpenType)' },
        [pscustomobject]@{ File='OpenDyslexic-Italic.otf';     Face='OpenDyslexic Italic';      RegName='OpenDyslexic Italic (OpenType)' },
        [pscustomobject]@{ File='OpenDyslexic-BoldItalic.otf'; Face='OpenDyslexic Bold Italic'; RegName='OpenDyslexic BoldItalic (OpenType)' }
    )
}

function Get-OgdOpenDyslexicStatus {
    $catalog   = Get-OgdOpenDyslexicCatalog
    $userFonts = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    $sysFonts  = Join-Path $env:SystemRoot 'Fonts'
    $fontRegU  = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    $fontRegS  = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    $substU    = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes'
    $substS    = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes'

    $items = foreach($font in $catalog){
        $userPath = Join-Path $userFonts $font.File
        $sysPath  = Join-Path $sysFonts  $font.File
        $inUser   = Test-Path $userPath
        $inSystem = Test-Path $sysPath
        $regU = $null; $regS = $null
        try{ $regU = (Get-ItemProperty $fontRegU -Name $font.RegName -EA SilentlyContinue).$($font.RegName) }catch{}
        try{ $regS = (Get-ItemProperty $fontRegS -Name $font.RegName -EA SilentlyContinue).$($font.RegName) }catch{}
        [pscustomobject]@{
            File        = $font.File
            Face        = $font.Face
            RegName     = $font.RegName
            UserPath    = $userPath
            SystemPath  = $sysPath
            InUser      = $inUser
            InSystem    = $inSystem
            Registered  = (-not [string]::IsNullOrWhiteSpace([string]$regU)) -or (-not [string]::IsNullOrWhiteSpace([string]$regS))
            SourcePath  = if($inUser){$userPath}elseif($inSystem){$sysPath}else{''}
        }
    }

    $asDefault = $false
    foreach($spath in @($substU,$substS)){
        try{
            $p = Get-ItemProperty $spath -EA SilentlyContinue
            if($p){
                if(($p.'Segoe UI' -match 'OpenDyslexic') -or ($p.'MS Shell Dlg' -match 'OpenDyslexic') -or ($p.'MS Shell Dlg 2' -match 'OpenDyslexic')){
                    $asDefault = $true
                }
            }
        }catch{}
    }

    $installedCount  = @($items | Where-Object { $_.InUser -or $_.InSystem }).Count
    $registeredCount = @($items | Where-Object { $_.Registered }).Count
    $missingFiles    = @($items | Where-Object { -not ($_.InUser -or $_.InSystem) } | ForEach-Object { $_.File })
    [pscustomobject]@{
        Items              = @($items)
        InstalledCount     = $installedCount
        RegisteredCount    = $registeredCount
        Installed          = ($installedCount -gt 0)
        FullyInstalled     = ($installedCount -eq $catalog.Count)
        FullyRegistered    = ($registeredCount -eq $catalog.Count)
        PartiallyInstalled = ($installedCount -gt 0 -and $installedCount -lt $catalog.Count)
        AsDefault          = $asDefault
        MissingFiles       = $missingFiles
        UserFontsPath      = $userFonts
        SystemFontsPath    = $sysFonts
    }
}

function New-OgdOpenDyslexicRestorePoint {
    $desc = "OGD WinCaffe v8.1.2 OpenDyslexic - $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
    Write-Info 'Creo un punto di ripristino prima della modifica OpenDyslexic...'
    if($script:OgdOpenDyslexicLastRestorePointAt){
        $elapsed = (New-TimeSpan -Start $script:OgdOpenDyslexicLastRestorePointAt -End (Get-Date)).TotalMinutes
        if($elapsed -lt 5){
            Write-Host '  → Punto di ripristino già creato pochi minuti fa per OpenDyslexic: evito duplicati inutili' -F DarkGray
            return
        }
    }
    if(Get-Command New-OgdRestorePoint -ErrorAction SilentlyContinue){
        try{
            New-OgdRestorePoint -Description $desc
            $script:OgdOpenDyslexicLastRestorePointAt = Get-Date
            return
        }catch{
            Write-Warning 'Punto di ripristino OGD non creato: provo il fallback Windows'
        }
    }
    $srKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
    $hadFreq = $false
    $oldFreq = $null
    try{
        if(Test-Path $srKey){
            $oldFreq = (Get-ItemProperty $srKey -Name 'SystemRestorePointCreationFrequency' -EA SilentlyContinue).SystemRestorePointCreationFrequency
            $hadFreq = ($null -ne $oldFreq)
        } else {
            New-Item $srKey -Force -EA SilentlyContinue | Out-Null
        }
        Set-ItemProperty $srKey -Name 'SystemRestorePointCreationFrequency' -Value 0 -Type DWord -Force -EA SilentlyContinue
    }catch{}
    if(Get-Command Checkpoint-Computer -ErrorAction SilentlyContinue){
        try{
            Checkpoint-Computer -Description $desc -RestorePointType 'MODIFY_SETTINGS' -EA Stop | Out-Null
            Write-Success 'Punto di ripristino Windows creato'
            $script:OgdOpenDyslexicLastRestorePointAt = Get-Date
            return
        }catch{
            Write-Warning 'Ripristino Windows non disponibile o limitato su questo sistema'
        }finally{
            try{
                if($hadFreq){
                    Set-ItemProperty $srKey -Name 'SystemRestorePointCreationFrequency' -Value $oldFreq -Type DWord -Force -EA SilentlyContinue
                } else {
                    Remove-ItemProperty $srKey -Name 'SystemRestorePointCreationFrequency' -EA SilentlyContinue
                }
            }catch{}
        }
    } else {
        Write-Warning 'Comando di ripristino non disponibile: continuo senza bloccare OpenDyslexic'
    }
}

function Repair-OgdOpenDyslexicRegistration {
    New-OgdOpenDyslexicRestorePoint
    Ensure-OgdFontInterop
    $catalog   = Get-OgdOpenDyslexicCatalog
    $status    = Get-OgdOpenDyslexicStatus
    $fontRegU  = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    $fontRegS  = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    if(-not (Test-Path $fontRegU)){ New-Item $fontRegU -Force -EA SilentlyContinue | Out-Null }
    if(-not (Test-Path $fontRegS)){ New-Item $fontRegS -Force -EA SilentlyContinue | Out-Null }

    foreach($font in $catalog){
        $item = $status.Items | Where-Object { $_.File -eq $font.File } | Select-Object -First 1
        if(-not $item){ continue }
        if($item.InUser -and (Test-Path $item.UserPath)){
            try{ Set-ItemProperty $fontRegU -Name $font.RegName -Value $item.UserPath -Force -EA SilentlyContinue }catch{}
            try{ [OGDFontInterop802HF4]::AddFontResourceEx($item.UserPath,0,[IntPtr]::Zero) | Out-Null }catch{}
        } elseif($item.InSystem -and (Test-Path $item.SystemPath)){
            try{ Set-ItemProperty $fontRegS -Name $font.RegName -Value $font.File -Force -EA SilentlyContinue }catch{}
            try{ [OGDFontInterop802HF4]::AddFontResourceEx($item.SystemPath,0,[IntPtr]::Zero) | Out-Null }catch{}
        }
    }

    Ensure-OgdClearTypeEnabled
    Send-OgdFontChangeBroadcast
    Restart-OgdFontSubsystem
    return (Get-OgdOpenDyslexicStatus)
}

function Enable-OgdOpenDyslexicAsDefault {
    New-OgdOpenDyslexicRestorePoint
    $substPaths = @(
        'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes',
        'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes'
    )
    foreach($spath in $substPaths){
        if(!(Test-Path $spath)){ New-Item $spath -Force -EA SilentlyContinue | Out-Null }
        Set-ItemProperty $spath -Name 'Segoe UI'             -Value 'OpenDyslexic'             -Type String -Force -EA SilentlyContinue
        Set-ItemProperty $spath -Name 'Segoe UI Variable'    -Value 'OpenDyslexic'             -Type String -Force -EA SilentlyContinue
        Set-ItemProperty $spath -Name 'Segoe UI Bold'        -Value 'OpenDyslexic Bold'        -Type String -Force -EA SilentlyContinue
        Set-ItemProperty $spath -Name 'Segoe UI Italic'      -Value 'OpenDyslexic Italic'      -Type String -Force -EA SilentlyContinue
        Set-ItemProperty $spath -Name 'Segoe UI Bold Italic' -Value 'OpenDyslexic Bold Italic' -Type String -Force -EA SilentlyContinue
        Set-ItemProperty $spath -Name 'MS Shell Dlg'         -Value 'OpenDyslexic'             -Type String -Force -EA SilentlyContinue
        Set-ItemProperty $spath -Name 'MS Shell Dlg 2'       -Value 'OpenDyslexic'             -Type String -Force -EA SilentlyContinue
    }
    Ensure-OgdClearTypeEnabled
    Send-OgdFontChangeBroadcast
    Restart-OgdFontSubsystem
    Write-Success 'OpenDyslexic applicato come font di sistema in modo piu visibile'
    Show-OgdWhatThisDoes 'OpenDyslexic sistema: applicazione estesa' @(
        'impostati i sostituti principali di Segoe UI sia lato utente sia lato sistema',
        'riattivati anche gli alias shell principali per far vedere davvero il cambio nelle finestre Windows',
        'se qualche app mostra problemi grafici, usa il ripristino font standard dal menu dedicato'
    )
}

function Disable-OgdOpenDyslexicAsDefault {
    New-OgdOpenDyslexicRestorePoint
    $substPaths = @(
        'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes',
        'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes'
    )
    foreach($spath in $substPaths){
        foreach($name in @('Segoe UI','Segoe UI Bold','MS Shell Dlg','MS Shell Dlg 2')){
            try{
                $current = (Get-ItemProperty $spath -Name $name -EA SilentlyContinue).$name
                if($current -match 'OpenDyslexic'){
                    Remove-ItemProperty $spath -Name $name -EA SilentlyContinue
                }
            }catch{}
        }
    }
    Ensure-OgdClearTypeEnabled
    Send-OgdFontChangeBroadcast
    Restart-OgdFontSubsystem
    Write-Success 'Sostituzione font OpenDyslexic rimossa mantenendo ClearType attivo'
}


function Install-OgdOpenDyslexic {
    param([switch]$Force,[switch]$SetAsDefault)

    New-OgdOpenDyslexicRestorePoint
    Ensure-OgdFontInterop
    Show-OgdWorkingAnimation -Text 'Preparazione OpenDyslexic...' -DurationMs 750
    $status    = Get-OgdOpenDyslexicStatus
    $catalog   = Get-OgdOpenDyslexicCatalog
    $userFonts = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    $fontRegU  = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    $fontRegS  = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    $tmp       = Join-Path $env:TEMP 'OGD_OpenDyslexic_779'
    $curlExe   = Join-Path $env:SystemRoot 'System32\curl.exe'
    $baseUrls  = @(
        'https://raw.githubusercontent.com/antijingoist/open-dyslexic/master/otf',
        'https://raw.githubusercontent.com/antijingoist/opendyslexic/main/otf',
        'https://raw.githubusercontent.com/antijingoist/opendyslexic/main/compiled'
    )

    if(-not (Test-Path $tmp)){ New-Item $tmp -ItemType Directory -Force | Out-Null }
    if(-not (Test-Path $userFonts)){ New-Item $userFonts -ItemType Directory -Force | Out-Null }
    if(-not (Test-Path $fontRegU)){ New-Item $fontRegU -Force -EA SilentlyContinue | Out-Null }

    if($status.FullyInstalled -and -not $Force){
        Write-Success 'OpenDyslexic già presente: verifico integrità e applicazione reale'
        $repairedStatus = Repair-OgdOpenDyslexicRegistration
        if($SetAsDefault){ Enable-OgdOpenDyslexicAsDefault }

        if($repairedStatus.FullyInstalled -and $repairedStatus.FullyRegistered){
            Show-OgdWhatThisDoes 'OpenDyslexic già presente: verifica completata' @(
                'i font risultano gia installati e sono stati ricontrollati/riregistrati',
                'se c era un problema di registrazione o cache font, e stata tentata la correzione automatica',
                'usa la forzatura solo se vuoi riscaricare i file e tentare un aggiornamento/riparazione completa'
            )
            return $true
        }
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    foreach($font in $catalog){
        $existing = $status.Items | Where-Object { $_.File -eq $font.File } | Select-Object -First 1
        $source = ''
        if($existing -and ($existing.InUser -or $existing.InSystem)){
            $source = $existing.SourcePath
        }

        foreach($candidate in @(
            (Join-Path $tmp $font.File),
            (Join-Path $userFonts $font.File),
            (Join-Path (Join-Path $env:SystemRoot 'Fonts') $font.File)
        )){
            try{
                if([string]::IsNullOrWhiteSpace($source) -and (Test-Path $candidate) -and ((Get-Item $candidate -EA SilentlyContinue).Length -gt 1000)){
                    $source = $candidate
                }
            }catch{}
        }

        if([string]::IsNullOrWhiteSpace($source) -or $Force){
            $dest = Join-Path $tmp $font.File
            $ok   = $false
            if((Test-Path $dest) -and ((Get-Item $dest -EA SilentlyContinue).Length -gt 1000)){ $ok = $true }

            foreach($url in @($baseUrls | ForEach-Object { "$_/$($font.File)" })){
                if($ok){ break }

                if(Test-Path $curlExe){
                    try{
                        & $curlExe -L -s --connect-timeout 10 --max-time 35 -o "$dest" "$url" 2>$null
                        if((Test-Path $dest) -and ((Get-Item $dest -EA SilentlyContinue).Length -gt 1000)){ $ok = $true; break }
                    }catch{}
                }

                try{
                    $wc = New-Object System.Net.WebClient
                    $wc.Headers.Add('User-Agent','Mozilla/5.0')
                    $wc.DownloadFile($url,$dest)
                    if((Test-Path $dest) -and ((Get-Item $dest -EA SilentlyContinue).Length -gt 1000)){ $ok = $true; break }
                }catch{}

                try{
                    Invoke-WebRequest $url -OutFile $dest -UseBasicParsing -TimeoutSec 35 -EA Stop
                    if((Test-Path $dest) -and ((Get-Item $dest -EA SilentlyContinue).Length -gt 1000)){ $ok = $true; break }
                }catch{}
            }

            if($ok){ $source = $dest }
        }

        if([string]::IsNullOrWhiteSpace($source) -or -not (Test-Path $source)){
            Write-Warning "OpenDyslexic: impossibile reperire $($font.File)"
            continue
        }

        Show-OgdWorkingAnimation -Text "Installazione font $($font.File)..." -DurationMs 550
        $installedOne = $false
        try{
            $destUser = Join-Path $userFonts $font.File
            Copy-Item $source $destUser -Force -EA Stop
            Set-ItemProperty $fontRegU -Name $font.RegName -Value $destUser -Force -EA SilentlyContinue
            try{ [OGDFontInterop802HF4]::AddFontResourceEx($destUser,0,[IntPtr]::Zero) | Out-Null }catch{}
            $installedOne = $true
        }catch{}

        try{
            $sysFonts = Join-Path $env:SystemRoot 'Fonts'
            $destSys  = Join-Path $sysFonts $font.File
            if(-not (Test-Path $fontRegS)){ New-Item $fontRegS -Force -EA SilentlyContinue | Out-Null }
            Copy-Item $source $destSys -Force -EA Stop
            Set-ItemProperty $fontRegS -Name $font.RegName -Value $font.File -Force -EA SilentlyContinue
            try{ [OGDFontInterop802HF4]::AddFontResourceEx($destSys,0,[IntPtr]::Zero) | Out-Null }catch{}
            $installedOne = $true
        }catch{}

        if(-not $installedOne){
            Write-Warning "OpenDyslexic non installato: $($font.File)"
        } else {
            Write-Success "OpenDyslexic pronto: $($font.File)"
        }
    }

    Ensure-OgdClearTypeEnabled
    Send-OgdFontChangeBroadcast
    Restart-OgdFontSubsystem
    if($SetAsDefault){ Enable-OgdOpenDyslexicAsDefault }

    $newStatus = Get-OgdOpenDyslexicStatus
    if($newStatus.FullyInstalled -and $newStatus.FullyRegistered){
        Write-Success 'OpenDyslexic installato/completato correttamente'
        Show-OgdWhatThisDoes 'OpenDyslexic: cosa è stato fatto davvero' @(
            'font copiati e registrati dove possibile senza forzarli come default',
            'se i file erano già presenti, la procedura prova a completarli invece di fallire subito',
            'puoi ancora scegliere separatamente se usarlo come font di sistema'
        )
        return $true
    }
    if($newStatus.Installed){
        Write-Warning 'OpenDyslexic presente ma non perfetto: provo a trattarlo come riparazione parziale'
        if($newStatus.MissingFiles){
            Write-Host ("    Mancano ancora: {0}" -f ($newStatus.MissingFiles -join ', ')) -F DarkGray
        }
        Show-OgdWhatThisDoes 'OpenDyslexic: stato parziale' @(
            'alcuni font risultano presenti, ma il pacchetto non e ancora completo',
            'usa la forzatura/riparazione per riscaricare i file mancanti o verificare una versione piu recente'
        )
        return $true
    }
    Write-Error2 'OpenDyslexic: installazione non riuscita'
    return $false
}

function Uninstall-OgdOpenDyslexic {
    New-OgdOpenDyslexicRestorePoint
    Show-OgdWorkingAnimation -Text 'Rimozione OpenDyslexic...' -DurationMs 700
    Ensure-OgdFontInterop
    Disable-OgdOpenDyslexicAsDefault
    $catalog   = Get-OgdOpenDyslexicCatalog
    $userFonts = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    $sysFonts  = Join-Path $env:SystemRoot 'Fonts'
    $fontRegU  = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    $fontRegS  = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'

    foreach($font in $catalog){
        try{ Remove-ItemProperty $fontRegU -Name $font.RegName -EA SilentlyContinue }catch{}
        try{ Remove-ItemProperty $fontRegS -Name $font.RegName -EA SilentlyContinue }catch{}
        foreach($path in @((Join-Path $userFonts $font.File),(Join-Path $sysFonts $font.File))){
            try{ if(Test-Path $path){ [OGDFontInterop802HF4]::RemoveFontResourceEx($path,0,[IntPtr]::Zero) | Out-Null } }catch{}
            try{ if(Test-Path $path){ Remove-Item $path -Force -EA SilentlyContinue } }catch{}
        }
    }

    Ensure-OgdClearTypeEnabled
    Send-OgdFontChangeBroadcast
    Restart-OgdFontSubsystem
    Write-Success 'OpenDyslexic disinstallato/rimosso dove possibile'
    Show-OgdWhatThisDoes 'OpenDyslexic: cosa è stato fatto davvero' @(
        'rimossi file e registrazioni trovate in area utente e, dove possibile, in area sistema',
        'ripristinati i font standard se OpenDyslexic era stato usato come sostituto'
    )
}

function Show-OgdOpenDyslexicManager {
    while($true){
        $status = Get-OgdOpenDyslexicStatus
        Clear-Host
        Write-Host "`n  ╔═══════════════════════════════════════════════════════╗" -F Cyan
        Write-Host "  ║           ACCESSIBILITÀ - OpenDyslexic               ║" -F Cyan
        Write-Host "  ╚═══════════════════════════════════════════════════════╝`n" -F Cyan
        Write-Host '  Questo font è consigliato solo a chi ha dislessia o' -F White
        Write-Host '  difficoltà di lettura. Non viene più forzato automaticamente.`n' -F DarkGray

        if($status.FullyInstalled -and $status.FullyRegistered){
            Write-Success "Stato font: completo ($($status.InstalledCount)/4 file)"
        } elseif($status.PartiallyInstalled){
            Write-Warning "Stato font: parziale ($($status.InstalledCount)/4 file)"
            Write-Host "    Mancano: $($status.MissingFiles -join ', ')" -F DarkGray
        } elseif($status.Installed){
            Write-Warning 'Stato font: presente ma non registrato bene'
        } else {
            Write-Host '  • Stato font: non installato' -F DarkGray
        }
        Write-Host ("  • Font di sistema sostituito: {0}`n" -f $(if($status.AsDefault){'SÌ'}else{'NO'})) -F White

        Write-Host '  [1] Verifica / installa / ripara OpenDyslexic' -F Green
        Write-Host '      Se il font e gia presente non da errore: controlla cache, registrazione e stato reale' -F DarkGray
        Write-Host '  [2] Forza reinstallazione / aggiornamento / riparazione' -F Yellow
        Write-Host '      Riscarica i file mancanti o corrotti e tenta una build piu aggiornata' -F DarkGray
        Write-Host '  [3] Applica OpenDyslexic a tutto il sistema (modalita compatibile)' -F Cyan
        Write-Host '  [4] Ripristina font standard Windows' -F White
        Write-Host '  [5] Disinstalla OpenDyslexic' -F Magenta
        Write-Host '      Explorer viene riavviato automaticamente per applicare meglio il cambio font' -F DarkGray
        Write-Host '  [0] Torna indietro`n' -F DarkGray

        $choice = Read-Host '  Scelta (1/2/3/4/5/0)'
        switch($choice){
            '1' { Install-OgdOpenDyslexic | Out-Null; Read-Host '  INVIO per continuare' }
            '2' { Install-OgdOpenDyslexic -Force | Out-Null; Read-Host '  INVIO per continuare' }
            '3' { if(Install-OgdOpenDyslexic){ Enable-OgdOpenDyslexicAsDefault }; Read-Host '  INVIO per continuare' }
            '4' { Disable-OgdOpenDyslexicAsDefault; Read-Host '  INVIO per continuare' }
            '5' { if((Read-Host '  Confermi la disinstallazione? (S/N)') -in @('S','s')){ Uninstall-OgdOpenDyslexic }; Read-Host '  INVIO per continuare' }
            '0' { return }
            default { Write-Warning 'Scelta non valida'; Start-Sleep 1 }
        }
    }
}

if($script:OpenDyslexicManagerRequestedAtStartup){
    $script:OpenDyslexicManagerRequestedAtStartup = $false
    Show-OgdOpenDyslexicManager
}

function Restore-OgdCopilotFully {
    Show-OgdWorkingAnimation -Text 'Ripristino Copilot...' -DurationMs 700

    foreach($path in @(
        'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot',
        'HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'
    )){
        try{ Remove-ItemProperty $path -Name 'TurnOffWindowsCopilot' -EA SilentlyContinue }catch{}
    }

    foreach($path in @(
        'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent',
        'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
    )){
        try{ Remove-ItemProperty $path -Name 'DisableWindowsCopilot' -EA SilentlyContinue }catch{}
    }

    $copilotPkgs = @(
        Get-AppxPackage -Name 'Microsoft.Copilot' -AllUsers -EA SilentlyContinue,
        Get-AppxPackage -Name 'Microsoft.Windows.Ai.Copilot.Provider' -AllUsers -EA SilentlyContinue
    ) | Where-Object { $_ }

    if($copilotPkgs.Count -gt 0){
        Write-Success 'Copilot riabilitato a livello policy'
        Show-OgdWhatThisDoes 'Copilot: ripristino completato' @(
            'rimosse le policy che lo disattivavano a livello sistema/utente',
            'i pacchetti Copilot risultano presenti, quindi Windows puo mostrarlo di nuovo',
            'se non compare subito, un riavvio di Explorer o del PC puo aiutare'
        )
    } else {
        Write-Warning 'Le policy sono state ripristinate, ma l''app Copilot non risulta installata'
        try{ Start-Process 'ms-windows-store://search/?query=Microsoft Copilot' }catch{}
        Show-OgdWhatThisDoes 'Copilot: cosa manca ancora' @(
            'la parte policy e stata riattivata correttamente',
            'l app Copilot non e presente: si apre la ricerca Microsoft Store per reinstallarla',
            'questa procedura non forza componenti non documentati e resta compatibile con 25H2'
        )
    }
}

function Show-OgdNpuDiagnostics {
    param([string]$CpuName='')
    $n = Get-OgdNpuInfo -CpuName $CpuName
    Write-Host ''
    Write-Host '  ┌─────────────────────────────────────────────────────────┐' -F Cyan
    Write-Host '  │                 DIAGNOSTICA NPU                         │' -F Cyan
    Write-Host '  └─────────────────────────────────────────────────────────┘' -F Cyan
    Write-Host "  CPU         : $CpuName" -F White
    Write-Host "  Trovata     : $(if($n.Found){'SÌ'}else{'NO'})" -F White
    Write-Host "  Driver ready: $(if($n.DriverReady){'SÌ'}else{'NO'})" -F White
    Write-Host "  Fonte       : $($n.Source)" -F White
    if($n.Name){ Write-Host "  Device      : $($n.Name)" -F White }
    if($n.PNPClass){ Write-Host "  Classe      : $($n.PNPClass)" -F White }
    if($n.PNPDeviceID){ Write-Host "  Device ID   : $($n.PNPDeviceID)" -F DarkGray }
    if($n.DriverVersion){ Write-Host "  Driver      : $($n.DriverVersion)" -F DarkGray }
    if($n.DriverDate){ Write-Host "  Driver date : $($n.DriverDate)" -F DarkGray }
    if($n.Advice){ Write-Host "`n  Suggerimento: $($n.Advice)" -F Yellow }
    if($n.Type -eq 'intel'){
        Write-Host "  • Verifica pratica: Device Manager > Neural processors > Intel AI Boost" -F DarkGray
        Write-Host "  • Se manca lì, molte app non vedranno la NPU anche se la CPU la integra" -F DarkGray
    }
    Write-Host ''
}

function Show-OgdGraphicsDiagnostics {
    param([string]$ExpectedGpuName = '')

    try{
        $gpu = Get-CimInstance Win32_VideoController -EA SilentlyContinue |
            Sort-Object @{Expression={ if($_.CurrentRefreshRate -gt 0){0}else{1} }}, Name |
            Select-Object -First 1
    }catch{
        $gpu = $null
    }

    if(-not $gpu){ return }

    $gpuName = [string]$gpu.Name
    if(-not [string]::IsNullOrWhiteSpace($ExpectedGpuName)){ $gpuName = $ExpectedGpuName }

    $refreshRate = 0
    try{ $refreshRate = [int]$gpu.CurrentRefreshRate }catch{}

    $hagsPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
    $hagsValue = $null
    try{ $hagsValue = (Get-ItemProperty $hagsPath -Name 'HwSchMode' -EA SilentlyContinue).HwSchMode }catch{}
    $hagsState = switch($hagsValue){
        2 { 'ON' }
        1 { 'OFF' }
        default { 'Default/driver managed' }
    }

    Write-Host ''
    Write-Host '  ┌─────────────────────────────────────────────────────────┐' -F Cyan
    Write-Host '  │              DIAGNOSTICA GRAFICA / DISPLAY             │' -F Cyan
    Write-Host '  └─────────────────────────────────────────────────────────┘' -F Cyan
    Write-Host "  GPU         : $gpuName" -F White
    if($gpu.DriverVersion){ Write-Host "  Driver      : $($gpu.DriverVersion)" -F White }
    if($refreshRate -gt 0){ Write-Host "  Refresh     : $refreshRate Hz" -F White }
    Write-Host "  HAGS        : $hagsState" -F White

    if($gpuName -match 'NVIDIA'){
        Write-Host '  • Verifica che il monitor sia davvero al refresh massimo in Impostazioni > Schermo > Schermo avanzato' -F DarkGray
        Write-Host '  • Per ReBAR usa NVIDIA App / Pannello NVIDIA o BIOS/UEFI: lo script non forza chiavi undocumented' -F DarkGray
        Write-Host '  • Per profili esports conta più una combo pulita: driver Game Ready, Reflex, HAGS stabile e settaggi in-game coerenti' -F DarkGray
    }
    Write-Host ''
}

function Test-OgdWindows24H2OrLater {
    if($script:OgdTargetWindowsFamily -eq '11'){
        return $script:OgdTargetIs24H2OrLater
    }
    try{
        $osBuild = [int](Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue).BuildNumber
    }catch{
        $osBuild = 0
    }
    return ($osBuild -ge 26100)
}

function Test-OgdWmicAllowed {
    if($script:OgdTargetWindowsFamily -eq '11' -and $script:OgdTargetIs24H2OrLater){
        return $false
    }
    return $true
}

function Test-OgdScriptContainsWmic {
    try{
        if($PSCommandPath -and (Test-Path $PSCommandPath)){
            $raw = Get-Content -LiteralPath $PSCommandPath -Raw -EA SilentlyContinue
            return ($raw -match '(?i)\bwmic\b')
        }
    }catch{}
    return $false
}

function Show-OgdSafetyStatus {
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────────────┐" -F Cyan
    Write-Host "  │                PROFILO SICUREZZA ATTIVO                │" -F Cyan
    Write-Host "  └─────────────────────────────────────────────────────────┘" -F Cyan
    Write-Host "  Target      : $(Get-OgdTargetLabel)" -F White
    Write-Host "  Rete        : profilo safe / ripristino tweak legacy" -F White
    Write-Host "  Driver/GPU  : niente registry tweak legacy aggressivi" -F White
    Write-Host "  Timer/DPC   : base low-level prudente" -F White
    if(-not (Test-OgdWmicAllowed)){
        $wmicFound = Test-OgdScriptContainsWmic
        Write-Host "  WMIC 24H2+  : $(if($wmicFound){'RILEVATO NEL FILE - DA BONIFICARE'}else{'ASSENTE / NON USATO'})" -F $(if($wmicFound){'Yellow'}else{'Green'})
    }
    Write-Host ""
}

function Invoke-OgdWin24H2Tweaks {
    param([switch]$CreateRestorePoint)

    if(-not (Confirm-OgdTargetBeforeAction -ActionName 'Tweaks Windows 11 24H2+' -Requirement 'Windows11_24H2Plus')){
        return
    }

    $osBuild = 0
    try{ $osBuild = [int](Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue).BuildNumber }catch{}

    Show-Banner
    Write-Section "WINDOWS 11 24H2+ TWEAKS"

    if($osBuild -lt 26100){
        Write-Warning "Build attuale: $osBuild. Questo menu richiede Windows 11 24H2 o superiore (build 26100+)."
        Read-Host "  INVIO per tornare"
        return
    }

    if($CreateRestorePoint){
        $desc24 = "OGD WinCaffe NEXT v8.1.2 WIN11 24H2+ - $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
        New-OgdRestorePoint -Description $desc24
        Write-Host ""
    }

    Write-Info "Build 24H2 rilevata: $osBuild"
    Write-Info "[1] Recall / AI consumer features..."
    DISM /Online /Disable-Feature /NoRestart /FeatureName:Recall 2>$null|Out-Null
    Get-AppxPackage -Name 'Microsoft.Windows.Recall' -AllUsers -EA SilentlyContinue | Remove-AppxPackage -AllUsers -EA SilentlyContinue
    Get-AppxProvisionedPackage -Online -EA SilentlyContinue | Where-Object DisplayName -like 'Microsoft.Windows.Recall' | Remove-AppxProvisionedPackage -Online -EA SilentlyContinue
    $cc24 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
    if(!(Test-Path $cc24)){New-Item $cc24 -Force -EA SilentlyContinue|Out-Null}
    Set-ItemProperty $cc24 -Name "DisableAIDataAnalysis" -Value 1 -Type DWord -Force -EA SilentlyContinue
    Write-Success "Recall/AI consumer features: disattivati in modo prudente"

    Write-Info "[2] Game Mode + cattura Xbox..."
    reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 1 /f 2>$null|Out-Null
    reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode"   /t REG_DWORD /d 1 /f 2>$null|Out-Null
    reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled"         /t REG_DWORD /d 0 /f 2>$null|Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f 2>$null|Out-Null
    Write-Success "Game Mode ON, DVR OFF"

    Write-Info "[3] Ottimizzazioni giochi in finestra + HAGS..."
    $dx24 = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
    if(!(Test-Path $dx24)){New-Item $dx24 -Force -EA SilentlyContinue|Out-Null}
    Set-ItemProperty $dx24 -Name "DirectXUserGlobalSettings" -Value "SwapEffectUpgradeEnable=1;" -Type String -Force -EA SilentlyContinue
    $gd24 = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    if(!(Test-Path $gd24)){New-Item $gd24 -Force -EA SilentlyContinue|Out-Null}
    Set-ItemProperty $gd24 -Name "HwSchMode" -Value 2 -Type DWord -Force -EA SilentlyContinue
    Write-Success "Windowed games optimization ON, HAGS ON"

    Write-Info "[4] Diagnostica grafica moderna..."
    Show-OgdGraphicsDiagnostics -ExpectedGpuName ((Get-CimInstance Win32_VideoController -EA SilentlyContinue | Select-Object -First 1).Name)
    Write-Host "  • Su Windows 11 24H2+ questo ramo evita WMIC: usa solo CIM / PowerShell moderno." -F DarkGray

    Write-Host ""
    Show-OgdAppliedSummary 'WIN24H2'
    Write-Host "  • Menu dedicato solo a 24H2+: niente tweak legacy di timer/TCP/driver." -F DarkGray
    Write-Host "  • Dopo l'applicazione conviene riavviare e verificare HAGS/refresh/VRR dalle Impostazioni." -F DarkGray
    Write-Host ""
    Read-Host "  INVIO per continuare"
}

function Show-OgdWin24H2Menu {
    while($true){
        Show-Banner
        Write-Section "WINDOWS 11 24H2+"
        Show-OgdAppliedSummary 'WIN24H2'
        Write-MenuHint 'Usa questo menu solo su Windows 11 24H2 o superiori.' @(
            'se la build è inferiore, il menu si ferma senza applicare nulla',
            'qui dentro restano solo tweak moderni, separati dal resto dello script e senza dipendenze da WMIC',
            'ottimo per rifinire gaming, Recall e grafica senza tirarsi dietro tweak forum-era'
        )
        Write-Host "  [1] Mostra cosa contiene il profilo 24H2+" -F White
        Write-Host "  [2] Applica i tweak 24H2+ adesso" -F Yellow
        Write-Host "  [3] Crea punto di ripristino e poi applica" -F Green
        Write-Host "  [0] Torna al menu`n" -F DarkGray
        $choice24 = Read-Host "  Scelta (1/2/3/0)"
        switch($choice24){
            '1' {
                Write-Host ""
                Write-Host "  Questo menu applica solo tweak coerenti con Windows 11 24H2+:" -F Cyan
                Write-Host "    • Recall / AI consumer features OFF in modo prudente" -F DarkGray
                Write-Host "    • Game Mode ON + DVR OFF" -F DarkGray
                Write-Host "    • Windowed games optimization ON + HAGS ON" -F DarkGray
                Write-Host "    • diagnostica GPU/driver/refresh per controlli reali" -F DarkGray
                Read-Host "  INVIO per continuare"
            }
            '2' { Invoke-OgdWin24H2Tweaks }
            '3' { Invoke-OgdWin24H2Tweaks -CreateRestorePoint }
            '0' { return }
            default { Write-Warning 'Scelta non valida'; Start-Sleep 1 }
        }
    }
}

function Show-OgdWin10AppliedSummary {
    Show-OgdWhatThisDoes 'Windows 10: cosa è stato fatto davvero' @(
        'raccolti tweak separati per Windows 10, lasciando fuori funzioni specifiche di Windows 11 come Recall o menu 24H2+',
        'profilo prudente orientato a Game Mode, DVR, grafica e pulizia del sistema senza trascinarsi tweak legacy inutili',
        'menu pensato per distinguere chiaramente il ramo Windows 10 da quello Windows 11'
    )
}

function Invoke-OgdWin10Tweaks {
    param([switch]$CreateRestorePoint)

    if(-not (Confirm-OgdTargetBeforeAction -ActionName 'Tweaks Windows 10' -Requirement 'Windows10')){
        return
    }

    Show-Banner
    Write-Section "WINDOWS 10 TWEAKS"

    if($CreateRestorePoint){
        $desc10 = "OGD WinCaffe NEXT v8.1.2 WIN10 - $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
        New-OgdRestorePoint -Description $desc10
        Write-Host ""
    }

    Write-Info "[1] Game Mode + cattura Xbox..."
    reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 1 /f 2>$null|Out-Null
    reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode"   /t REG_DWORD /d 1 /f 2>$null|Out-Null
    reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled"         /t REG_DWORD /d 0 /f 2>$null|Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f 2>$null|Out-Null
    Write-Success "Windows 10: Game Mode ON, DVR OFF"

    Write-Info "[2] Ottimizzazioni grafiche compatibili..."
    $gd10 = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    if(!(Test-Path $gd10)){New-Item $gd10 -Force -EA SilentlyContinue|Out-Null}
    Set-ItemProperty $gd10 -Name "HwSchMode" -Value 2 -Type DWord -Force -EA SilentlyContinue
    $dx10 = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
    if(!(Test-Path $dx10)){New-Item $dx10 -Force -EA SilentlyContinue|Out-Null}
    Set-ItemProperty $dx10 -Name "DirectXUserGlobalSettings" -Value "SwapEffectUpgradeEnable=1;" -Type String -Force -EA SilentlyContinue
    Write-Success "Windows 10: HAGS/Flip Model dove supportati"

    Write-Info "[3] Diagnostica grafica..."
    Show-OgdGraphicsDiagnostics -ExpectedGpuName ((Get-CimInstance Win32_VideoController -EA SilentlyContinue | Select-Object -First 1).Name)

    Write-Host ""
    Show-OgdWin10AppliedSummary
    Write-Host "  • Questo menu esclude tweak specifici di Windows 11 24H2/25H2." -F DarkGray
    Write-Host "  • Dopo l'applicazione conviene riavviare e verificare refresh/HAGS dalle Impostazioni." -F DarkGray
    Write-Host ""
    Read-Host "  INVIO per continuare"
}

function Show-OgdWin10Menu {
    while($true){
        Show-Banner
        Write-Section "WINDOWS 10"
        Show-OgdWin10AppliedSummary
        Write-MenuHint 'Usa questo menu quando hai selezionato Windows 10 come target.' @(
            'separi il ramo Windows 10 dai tweak specifici di Windows 11',
            'qui restano solo impostazioni moderne e prudenti compatibili con Windows 10',
            'utile per non mischiare menu 24H2+ con macchine o installazioni più vecchie'
        )
        Write-Host "  [1] Mostra cosa contiene il profilo Windows 10" -F White
        Write-Host "  [2] Applica i tweak Windows 10 adesso" -F Yellow
        Write-Host "  [3] Crea punto di ripristino e poi applica" -F Green
        Write-Host "  [0] Torna al menu`n" -F DarkGray
        $choice10 = Read-Host "  Scelta (1/2/3/0)"
        switch($choice10){
            '1' {
                Write-Host ""
                Write-Host "  Questo menu applica solo tweak coerenti con Windows 10:" -F Cyan
                Write-Host "    • Game Mode ON + DVR OFF" -F DarkGray
                Write-Host "    • HAGS / Flip Model dove supportati" -F DarkGray
                Write-Host "    • diagnostica GPU/driver/refresh" -F DarkGray
                Read-Host "  INVIO per continuare"
            }
            '2' { Invoke-OgdWin10Tweaks }
            '3' { Invoke-OgdWin10Tweaks -CreateRestorePoint }
            '0' { return }
            default { Write-Warning 'Scelta non valida'; Start-Sleep 1 }
        }
    }
}

function Set-OgdWindows11ClassicContextMenu {
    param([bool]$Enabled = $true)
    $ctxKey = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
    if($Enabled){
        if(-not (Test-Path $ctxKey)){ New-Item -Path $ctxKey -Force -EA SilentlyContinue | Out-Null }
        Set-Item -Path $ctxKey -Value '' -Force -EA SilentlyContinue
        Write-Success 'Menu contestuale classico di Windows 11 attivato'
    } else {
        try{ Remove-Item 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' -Recurse -Force -EA SilentlyContinue }catch{}
        Write-Success 'Menu contestuale moderno di Windows 11 ripristinato'
    }
    try{
        Stop-Process -Name explorer -Force -EA SilentlyContinue
        Start-Sleep -Milliseconds 700
        Start-Process explorer.exe
    }catch{}
}

function Set-OgdWindows11ExtraLiteUiPack {
    $advKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $cdmKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    $devKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\DeveloperSettings'
    if(-not (Test-Path $advKey)){ New-Item -Path $advKey -Force -EA SilentlyContinue | Out-Null }
    if(-not (Test-Path $cdmKey)){ New-Item -Path $cdmKey -Force -EA SilentlyContinue | Out-Null }
    if(-not (Test-Path $devKey)){ New-Item -Path $devKey -Force -EA SilentlyContinue | Out-Null }

    Set-ItemProperty $advKey -Name 'ShowSecondsInSystemClock' -Value 1 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $advKey -Name 'TaskbarDa' -Value 0 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $devKey -Name 'TaskbarEndTask' -Value 1 -Type DWord -Force -EA SilentlyContinue

    foreach($name in @(
        'SubscribedContent-338388Enabled',
        'SubscribedContent-338389Enabled',
        'SubscribedContent-353694Enabled',
        'SubscribedContent-353696Enabled',
        'SubscribedContent-353698Enabled',
        'SubscribedContent-310093Enabled',
        'SoftLandingEnabled',
        'SystemPaneSuggestionsEnabled',
        'RotatingLockScreenEnabled',
        'RotatingLockScreenOverlayEnabled'
    )){
        Set-ItemProperty $cdmKey -Name $name -Value 0 -Type DWord -Force -EA SilentlyContinue
    }

    Write-Success 'Pacchetto UI Extra Lite applicato: secondi clock, End Task, widget OFF, suggerimenti/spotlight OFF'
}

function Set-OgdWindows11ExplorerLitePack {
    $advKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    if(-not (Test-Path $advKey)){ New-Item -Path $advKey -Force -EA SilentlyContinue | Out-Null }
    Set-ItemProperty $advKey -Name 'Hidden' -Value 1 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $advKey -Name 'HideFileExt' -Value 0 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $advKey -Name 'LaunchTo' -Value 1 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $advKey -Name 'ShowCompColor' -Value 1 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $advKey -Name 'NavPaneExpandToCurrentFolder' -Value 1 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $advKey -Name 'SeparateProcess' -Value 1 -Type DWord -Force -EA SilentlyContinue
    Write-Success 'Explorer Lite pack applicato: estensioni visibili, file nascosti visibili, Questo PC, nav pane più completo'
}

function Set-OgdWindows11TaskbarLitePack {
    $advKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $searchKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
    if(-not (Test-Path $advKey)){ New-Item -Path $advKey -Force -EA SilentlyContinue | Out-Null }
    if(-not (Test-Path $searchKey)){ New-Item -Path $searchKey -Force -EA SilentlyContinue | Out-Null }
    Set-ItemProperty $advKey -Name 'TaskbarAl' -Value 0 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $advKey -Name 'TaskbarDa' -Value 0 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $advKey -Name 'TaskbarMn' -Value 0 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $advKey -Name 'ShowTaskViewButton' -Value 0 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $searchKey -Name 'SearchboxTaskbarMode' -Value 0 -Type DWord -Force -EA SilentlyContinue
    Write-Success 'Taskbar Lite pack applicato: allineamento sinistra, widget/task view/search ridotti'
}

function Set-OgdWindows11ContentLitePack {
    $cdmKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    $explorerKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $searchKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings'
    foreach($k in @($cdmKey,$explorerKey,$searchKey)){
        if(-not (Test-Path $k)){ New-Item -Path $k -Force -EA SilentlyContinue | Out-Null }
    }
    foreach($name in @(
        'SubscribedContent-338388Enabled',
        'SubscribedContent-338389Enabled',
        'SubscribedContent-338393Enabled',
        'SubscribedContent-353694Enabled',
        'SubscribedContent-353696Enabled',
        'SubscribedContent-353698Enabled',
        'SubscribedContent-310093Enabled',
        'SilentInstalledAppsEnabled',
        'SoftLandingEnabled',
        'SystemPaneSuggestionsEnabled',
        'RotatingLockScreenEnabled',
        'RotatingLockScreenOverlayEnabled'
    )){
        Set-ItemProperty $cdmKey -Name $name -Value 0 -Type DWord -Force -EA SilentlyContinue
    }
    Set-ItemProperty $explorerKey -Name 'Start_TrackDocs' -Value 0 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $searchKey -Name 'IsDynamicSearchBoxEnabled' -Value 0 -Type DWord -Force -EA SilentlyContinue
    Write-Success 'Content Lite pack applicato: spotlight, suggerimenti, offerte e search highlights ridotti'
}

function Set-OgdWindows11WindowingLitePack {
    $advKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    if(-not (Test-Path $advKey)){ New-Item -Path $advKey -Force -EA SilentlyContinue | Out-Null }
    Set-ItemProperty $advKey -Name 'SnapAssist' -Value 0 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $advKey -Name 'JointResize' -Value 0 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty $advKey -Name 'EnableSnapAssistFlyout' -Value 0 -Type DWord -Force -EA SilentlyContinue
    Write-Success 'Windowing Lite pack applicato: suggerimenti Snap e flyout ridotti'
}

function Show-OgdWindows11ExplorerLiteMenu {
    while($true){
        Show-Banner
        Write-Section 'WINDOWS 11 EXTRA LITE - EXPLORER'
        Write-MenuHint 'Menu modulare Explorer.' @(
            'qui non applichi tutto insieme per forza: scegli solo le voci che vuoi davvero',
            'questo ramo e pensato per sostituire i tweak Explorer duplicati nei preset generali'
        )
        Write-Host '  [1] Mostra file nascosti' -F White
        Write-Host '  [2] Mostra estensioni file' -F White
        Write-Host '  [3] Apri Esplora file su Questo PC' -F White
        Write-Host '  [4] Espandi il pannello al percorso corrente' -F White
        Write-Host '  [5] Explorer in processo separato' -F White
        Write-Host '  [6] Applica il pacchetto Explorer Lite completo' -F Yellow
        Write-Host '  [0] Torna indietro`n' -F DarkGray
        $c = Read-Host '  Scelta (1/2/3/4/5/6/0)'
        $advKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        if(-not (Test-Path $advKey)){ New-Item -Path $advKey -Force -EA SilentlyContinue | Out-Null }
        switch($c){
            '1' { Set-ItemProperty $advKey -Name 'Hidden' -Value 1 -Type DWord -Force -EA SilentlyContinue; Write-Success 'File nascosti visibili'; Read-Host '  INVIO per continuare' }
            '2' { Set-ItemProperty $advKey -Name 'HideFileExt' -Value 0 -Type DWord -Force -EA SilentlyContinue; Write-Success 'Estensioni file visibili'; Read-Host '  INVIO per continuare' }
            '3' { Set-ItemProperty $advKey -Name 'LaunchTo' -Value 1 -Type DWord -Force -EA SilentlyContinue; Write-Success 'Esplora file aprira su Questo PC'; Read-Host '  INVIO per continuare' }
            '4' { Set-ItemProperty $advKey -Name 'NavPaneExpandToCurrentFolder' -Value 1 -Type DWord -Force -EA SilentlyContinue; Write-Success 'Nav pane espanso sul percorso corrente'; Read-Host '  INVIO per continuare' }
            '5' { Set-ItemProperty $advKey -Name 'SeparateProcess' -Value 1 -Type DWord -Force -EA SilentlyContinue; Write-Success 'Explorer in processo separato'; Read-Host '  INVIO per continuare' }
            '6' { Set-OgdWindows11ExplorerLitePack; Read-Host '  INVIO per continuare' }
            '0' { return }
            default { Write-Warning 'Scelta non valida'; Start-Sleep 1 }
        }
    }
}

function Show-OgdWindows11TaskbarLiteMenu {
    while($true){
        Show-Banner
        Write-Section 'WINDOWS 11 EXTRA LITE - TASKBAR'
        Write-MenuHint 'Menu modulare Taskbar.' @(
            'scegli singolarmente layout, widget, task view, ricerca e shortcut utili',
            'tutto quello che sta qui non viene più dato per scontato nei preset performance'
        )
        Write-Host '  [1] Allinea la taskbar a sinistra' -F White
        Write-Host '  [2] Disattiva pulsante Widget' -F White
        Write-Host '  [3] Disattiva pulsante Task View' -F White
        Write-Host '  [4] Riduci/Nascondi ricerca sulla taskbar' -F White
        Write-Host '  [5] Mostra i secondi nell orologio' -F White
        Write-Host '  [6] Attiva End Task dalla taskbar' -F White
        Write-Host '  [7] Applica il pacchetto Taskbar Lite completo' -F Yellow
        Write-Host '  [0] Torna indietro`n' -F DarkGray
        $c = Read-Host '  Scelta (1/2/3/4/5/6/7/0)'
        $advKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        $searchKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
        $devKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\DeveloperSettings'
        foreach($k in @($advKey,$searchKey,$devKey)){ if(-not (Test-Path $k)){ New-Item -Path $k -Force -EA SilentlyContinue | Out-Null } }
        switch($c){
            '1' { Set-ItemProperty $advKey -Name 'TaskbarAl' -Value 0 -Type DWord -Force -EA SilentlyContinue; Write-Success 'Taskbar allineata a sinistra'; Read-Host '  INVIO per continuare' }
            '2' { Set-ItemProperty $advKey -Name 'TaskbarDa' -Value 0 -Type DWord -Force -EA SilentlyContinue; Write-Success 'Widget disattivato'; Read-Host '  INVIO per continuare' }
            '3' { Set-ItemProperty $advKey -Name 'ShowTaskViewButton' -Value 0 -Type DWord -Force -EA SilentlyContinue; Write-Success 'Task View disattivato'; Read-Host '  INVIO per continuare' }
            '4' { Set-ItemProperty $searchKey -Name 'SearchboxTaskbarMode' -Value 0 -Type DWord -Force -EA SilentlyContinue; Write-Success 'Ricerca taskbar ridotta'; Read-Host '  INVIO per continuare' }
            '5' { Set-ItemProperty $advKey -Name 'ShowSecondsInSystemClock' -Value 1 -Type DWord -Force -EA SilentlyContinue; Write-Success 'Secondi nell orologio attivati'; Read-Host '  INVIO per continuare' }
            '6' { Set-ItemProperty $devKey -Name 'TaskbarEndTask' -Value 1 -Type DWord -Force -EA SilentlyContinue; Write-Success 'End Task dalla taskbar attivato'; Read-Host '  INVIO per continuare' }
            '7' { Set-OgdWindows11TaskbarLitePack; Read-Host '  INVIO per continuare' }
            '0' { return }
            default { Write-Warning 'Scelta non valida'; Start-Sleep 1 }
        }
    }
}

function Show-OgdWindows11ContentLiteMenu {
    while($true){
        Show-Banner
        Write-Section 'WINDOWS 11 EXTRA LITE - CONTENT'
        Write-MenuHint 'Menu modulare contenuti e suggerimenti.' @(
            'qui raccogli widget promozionali, spotlight, suggerimenti, search highlights e contenuti consumer',
            'serve a rendere Windows 11 più sobrio senza mischiare queste scelte ai preset hardware'
        )
        Write-Host '  [1] Disattiva suggerimenti e offerte Windows' -F White
        Write-Host '  [2] Disattiva lock screen spotlight e overlay' -F White
        Write-Host '  [3] Disattiva Search Highlights' -F White
        Write-Host '  [4] Riduci documenti recenti e tracce Start' -F White
        Write-Host '  [5] Applica il pacchetto Content Lite completo' -F Yellow
        Write-Host '  [0] Torna indietro`n' -F DarkGray
        $c = Read-Host '  Scelta (1/2/3/4/5/0)'
        $cdmKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
        $explorerKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        $searchKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings'
        foreach($k in @($cdmKey,$explorerKey,$searchKey)){ if(-not (Test-Path $k)){ New-Item -Path $k -Force -EA SilentlyContinue | Out-Null } }
        switch($c){
            '1' {
                foreach($name in @('SubscribedContent-338388Enabled','SubscribedContent-338389Enabled','SubscribedContent-338393Enabled','SilentInstalledAppsEnabled','SoftLandingEnabled','SystemPaneSuggestionsEnabled')){
                    Set-ItemProperty $cdmKey -Name $name -Value 0 -Type DWord -Force -EA SilentlyContinue
                }
                Write-Success 'Suggerimenti e offerte ridotti'
                Read-Host '  INVIO per continuare'
            }
            '2' {
                foreach($name in @('RotatingLockScreenEnabled','RotatingLockScreenOverlayEnabled','SubscribedContent-353694Enabled','SubscribedContent-353696Enabled','SubscribedContent-353698Enabled')){
                    Set-ItemProperty $cdmKey -Name $name -Value 0 -Type DWord -Force -EA SilentlyContinue
                }
                Write-Success 'Lock screen spotlight e overlay ridotti'
                Read-Host '  INVIO per continuare'
            }
            '3' {
                Set-ItemProperty $searchKey -Name 'IsDynamicSearchBoxEnabled' -Value 0 -Type DWord -Force -EA SilentlyContinue
                Write-Success 'Search Highlights disattivati'
                Read-Host '  INVIO per continuare'
            }
            '4' {
                Set-ItemProperty $explorerKey -Name 'Start_TrackDocs' -Value 0 -Type DWord -Force -EA SilentlyContinue
                Write-Success 'Documenti recenti e tracce Start ridotti'
                Read-Host '  INVIO per continuare'
            }
            '5' { Set-OgdWindows11ContentLitePack; Read-Host '  INVIO per continuare' }
            '0' { return }
            default { Write-Warning 'Scelta non valida'; Start-Sleep 1 }
        }
    }
}

function Show-OgdWindows11WindowingLiteMenu {
    while($true){
        Show-Banner
        Write-Section 'WINDOWS 11 EXTRA LITE - WINDOWING'
        Write-MenuHint 'Menu modulare per Snap e comportamento finestre.' @(
            'questo ramo serve a chi vuole meno aiuti automatici e meno flyout nel window management',
            'non tocca la performance pura: tocca solo UX e comportamento finestre'
        )
        Write-Host '  [1] Disattiva Snap Assist' -F White
        Write-Host '  [2] Disattiva ridimensionamento congiunto finestre' -F White
        Write-Host '  [3] Disattiva flyout automatico di Snap' -F White
        Write-Host '  [4] Applica il pacchetto Windowing Lite completo' -F Yellow
        Write-Host '  [0] Torna indietro`n' -F DarkGray
        $c = Read-Host '  Scelta (1/2/3/4/0)'
        $advKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        if(-not (Test-Path $advKey)){ New-Item -Path $advKey -Force -EA SilentlyContinue | Out-Null }
        switch($c){
            '1' { Set-ItemProperty $advKey -Name 'SnapAssist' -Value 0 -Type DWord -Force -EA SilentlyContinue; Write-Success 'Snap Assist disattivato'; Read-Host '  INVIO per continuare' }
            '2' { Set-ItemProperty $advKey -Name 'JointResize' -Value 0 -Type DWord -Force -EA SilentlyContinue; Write-Success 'Ridimensionamento congiunto disattivato'; Read-Host '  INVIO per continuare' }
            '3' { Set-ItemProperty $advKey -Name 'EnableSnapAssistFlyout' -Value 0 -Type DWord -Force -EA SilentlyContinue; Write-Success 'Flyout Snap disattivato'; Read-Host '  INVIO per continuare' }
            '4' { Set-OgdWindows11WindowingLitePack; Read-Host '  INVIO per continuare' }
            '0' { return }
            default { Write-Warning 'Scelta non valida'; Start-Sleep 1 }
        }
    }
}

function Show-OgdWindows11ExtraLiteSummary {
    Show-OgdWhatThisDoes 'Windows 11 Extra Lite: cosa fa davvero' @(
        'raccoglie tweak di interfaccia, Explorer e taskbar in stile Winaero, ma dentro un menu OGD separato e più prudente',
        'punta a rendere Windows 11 più pulito, meno rumoroso e più rapido da usare senza spostarlo nel territorio overclock o tweak borderline',
        'copre shell, Explorer, taskbar, contenuti, windowing e il ponte verso gli extra moderni 24H2/25H2'
    )
}

function Invoke-OgdWindows11ExtraLiteCore {
    param([switch]$CreateRestorePoint)

    if(-not (Confirm-OgdTargetBeforeAction -ActionName 'Windows 11 Extra Lite' -Requirement 'Windows11')){
        return
    }

    Show-Banner
    Write-Section ("WINDOWS 11 EXTRA LITE  |  Target: {0}" -f (Get-OgdTargetLabel))

    if($CreateRestorePoint){
        $desc11xl = "OGD WinCaffe NEXT v8.1.2 WIN11 EXTRA LITE - $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
        New-OgdRestorePoint -Description $desc11xl
        Write-Host ""
    }

    Write-Info "[1] Interfaccia pulita e taskbar piu utile..."
    Set-OgdWindows11ExtraLiteUiPack

    Write-Info "[2] Menu contestuale completo..."
    Set-OgdWindows11ClassicContextMenu -Enabled $true

    Write-Info "[3] Explorer Lite..."
    Set-OgdWindows11ExplorerLitePack

    Write-Info "[4] Taskbar Lite..."
    Set-OgdWindows11TaskbarLitePack

    Write-Info "[5] Content Lite..."
    Set-OgdWindows11ContentLitePack

    Write-Info "[6] Windowing Lite..."
    Set-OgdWindows11WindowingLitePack

    Write-Host ""
    Show-OgdWindows11ExtraLiteSummary
    Write-Host "  • Ispirazione principale: Winaero Tweaker / Sergey Tkachenko, con adattamento al flusso OGD." -F DarkGray
    Write-Host "  • Per alcune voci Windows 11 moderne restano valide anche le impostazioni native Microsoft." -F DarkGray
    Write-Host ""
    Read-Host "  INVIO per continuare"
}

function Show-OgdWindows11ExtraLiteMenu {
    while($true){
        Show-Banner
        Write-Section ("WINDOWS 11 EXTRA LITE MENU  |  Target: {0}" -f (Get-OgdTargetLabel))
        Show-OgdWindows11ExtraLiteSummary
        Write-MenuHint 'Questo menu esiste solo per Windows 11 e si adatta alla build rilevata.' @(
            'qui trovi tweak di interfaccia e comportamento in stile Winaero, ma selezionati e separati dai preset di performance',
            'su 24H2 e 25H2+ puoi anche richiamare gli extra moderni già presenti nel ramo Windows 11',
            'l obiettivo e avere un Windows 11 più leggero e più pulito, non fare overclock o tuning termico'
        )
        Write-Host "  [1] Mostra cosa contiene Windows 11 Extra Lite" -F White
        Write-Host "  [2] Applica il pacchetto Extra Lite adesso" -F Yellow
        Write-Host "  [3] Crea punto di ripristino e poi applica" -F Green
        Write-Host "  [4] Attiva menu contestuale classico di Windows 11" -F Cyan
        Write-Host "  [5] Ripristina menu contestuale moderno di Windows 11" -F White
        Write-Host "  [6] Explorer Lite - sotto-menu modulare Explorer" -F White
        Write-Host "  [7] Taskbar Lite - sotto-menu modulare Taskbar" -F White
        Write-Host "  [8] Content Lite - sotto-menu modulare spotlight/suggerimenti" -F White
        Write-Host "  [9] Windowing Lite - sotto-menu modulare Snap/finestre" -F White
        Write-Host "  [A] Clock + End Task rapidi" -F Cyan
        Write-Host "  [B] Applica anche gli extra moderni per build Win11" -F Magenta
        Write-Host "  [0] Torna al menu`n" -F DarkGray
        $choice11xl = Read-Host "  Scelta (1/2/3/4/5/6/7/8/9/A/B/0)"
        switch($choice11xl){
            '1' {
                Write-Host ""
                Write-Host "  Questo menu include tweak Windows 11 in stile Extra Lite:" -F Cyan
                Write-Host "    • menu contestuale classico completo" -F DarkGray
                Write-Host "    • Explorer piu tecnico: estensioni, nascosti, Questo PC" -F DarkGray
                Write-Host "    • taskbar piu pulita: sinistra, meno widget/search/task view" -F DarkGray
                Write-Host "    • secondi clock ed End Task taskbar" -F DarkGray
                Write-Host "    • spotlight, suggerimenti, offerte e search highlights ridotti" -F DarkGray
                Write-Host "    • riduzione Snap Assist e flyout automatici" -F DarkGray
                Write-Host "    • ponte verso il ramo Win11 moderno gia presente nello script" -F DarkGray
                Read-Host "  INVIO per continuare"
            }
            '2' { Invoke-OgdWindows11ExtraLiteCore }
            '3' { Invoke-OgdWindows11ExtraLiteCore -CreateRestorePoint }
            '4' { Set-OgdWindows11ClassicContextMenu -Enabled $true; Read-Host '  INVIO per continuare' }
            '5' { Set-OgdWindows11ClassicContextMenu -Enabled $false; Read-Host '  INVIO per continuare' }
            '6' { Show-OgdWindows11ExplorerLiteMenu }
            '7' { Show-OgdWindows11TaskbarLiteMenu }
            '8' { Show-OgdWindows11ContentLiteMenu }
            '9' { Show-OgdWindows11WindowingLiteMenu }
            { $_ -in @('A','a') } {
                $advKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                $devKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\DeveloperSettings'
                foreach($k in @($advKey,$devKey)){ if(-not (Test-Path $k)){ New-Item -Path $k -Force -EA SilentlyContinue | Out-Null } }
                Set-ItemProperty $advKey -Name 'ShowSecondsInSystemClock' -Value 1 -Type DWord -Force -EA SilentlyContinue
                Set-ItemProperty $devKey -Name 'TaskbarEndTask' -Value 1 -Type DWord -Force -EA SilentlyContinue
                Write-Success 'Secondi orologio ed End Task taskbar attivati'
                Read-Host '  INVIO per continuare'
            }
            { $_ -in @('B','b') } {
                if($script:OgdTargetIs24H2OrLater){
                    Invoke-OgdWin24H2Tweaks
                } else {
                    Write-Warning 'Gli extra moderni del ramo Windows 11 sono pensati per 24H2 o superiori.'
                    Read-Host '  INVIO per continuare' | Out-Null
                }
            }
            '0' { return }
            default { Write-Warning 'Scelta non valida'; Start-Sleep 1 }
        }
    }
}

function Repair-OgdDpcDefaults {
    Write-Info "Ripristino base DPC/timer verso impostazioni native e prudenti..."
    bcdedit /deletevalue useplatformclock   2>$null | Out-Null
    bcdedit /deletevalue disabledynamictick 2>$null | Out-Null
    bcdedit /deletevalue tscsyncpolicy      2>$null | Out-Null

    try{
        $kernelPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"
        if(Test-Path $kernelPath){
            Remove-ItemProperty -Path $kernelPath -Name "GlobalTimerResolutionRequests" -Force -EA SilentlyContinue
        }
    }catch{}

    Write-Success "DPC/timer: base low-level riportata a gestione nativa"
}

function Get-OgdProvisionedPackageSafe {
    param([string]$LikePattern='*')

    try{
        return @(Get-AppxProvisionedPackage -Online -EA Stop | Where-Object { $_.DisplayName -like $LikePattern })
    }catch{
        try{
            $cmd = @"
$ErrorActionPreference = 'Stop'
Get-AppxProvisionedPackage -Online |
Where-Object { `$_.DisplayName -like '$LikePattern' } |
Select-Object DisplayName, PackageName |
ConvertTo-Json -Compress
"@
            $json = & powershell.exe -NoProfile -Command $cmd 2>$null
            if($json){
                $parsed = $json | ConvertFrom-Json
                return @($parsed)
            }
        }catch{}
    }

    return @()
}

function Remove-OgdProvisionedPackageSafe {
    param([string]$LikePattern)

    foreach($pkg in @(Get-OgdProvisionedPackageSafe -LikePattern $LikePattern)){
        $packageName = $pkg.PackageName
        if([string]::IsNullOrWhiteSpace($packageName)){ continue }

        try{
            Remove-AppxProvisionedPackage -Online -PackageName $packageName -EA SilentlyContinue | Out-Null
        }catch{
            try{
                DISM /Online /Remove-ProvisionedAppxPackage /PackageName:$packageName /NoRestart 2>$null | Out-Null
            }catch{}
        }
    }
}

function Show-OgdPre8012FixMenu {
    while($true){
        Show-Banner
        Write-Section "FIX PRE 8.1.1"
        Write-Host "  [1] Mostra cosa include il ponte pre-8.1.1" -F White
        Write-Host "  [2] ROLLBACK DEFAULT WINDOWS" -F Green
        Write-Host "  [0] Torna al menu`n" -F DarkGray
        $choice798 = Read-Host "  Scelta (1/2/0)"
        switch($choice798){
            '1' {
                Write-Host ""
                Write-Host "  Questo sotto-menu serve come ponte pulito verso la 8.1.1:" -F Cyan
                Write-Host "    • ti lascia una via rapida per il rollback completo ai default Windows" -F DarkGray
                Write-Host "    • mantiene una strada prudente per chi arriva da build precedenti" -F DarkGray
                Write-Host "    • e pensato per chi vuole arrivare alla 8.1.2 con sistema piu pulito e prevedibile" -F DarkGray
                Read-Host "  INVIO per continuare"
            }
            '2' { Invoke-OgdFullRollbackToDefault -ProfileLabel 'FIX PRE 8.1.1' | Out-Null; Read-Host "  INVIO per continuare" | Out-Null }
            '0' { return }
            default { Write-Warning 'Scelta non valida'; Start-Sleep 1 }
        }
    }
}

function Show-OgdPre8011AggressiveFixMenu {
    param([string]$PresetLabel = 'AGGRESSIVO')
    while($true){
        Show-Banner
        Write-Section ("FIX PRE 8.0.11 - {0}" -f $PresetLabel)
        Write-Host "  [1] Mostra cosa corregge questo fix" -F White
        Write-Host "  [2] Applica il fix di ripristino per vecchi preset aggressivi" -F Yellow
        Write-Host "  [0] Torna indietro`n" -F DarkGray
        $preAggChoice = Read-Host "  Scelta (1/2/0)"
        switch($preAggChoice){
            '1' {
                Write-Host ""
                Write-Host "  Questo fix e pensato per chi arriva da rami aggressivi vecchi:" -F Cyan
                Write-Host "    • riporta il sistema verso i default Windows invece di lasciare tweak spinti accumulati" -F DarkGray
                Write-Host "    • aiuta in casi di caldo eccessivo, schermo nero, freeze o comportamento instabile" -F DarkGray
                Write-Host "    • dopo il fix conviene riapplicare solo un preset moderno e piu prudente" -F DarkGray
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '2' {
                Invoke-OgdFullRollbackToDefault -ProfileLabel ("FIX PRE 8.0.11 / {0}" -f $PresetLabel) | Out-Null
                Write-Host ""
                Write-Host "  Consiglio: dopo questo fix, se vuoi ripartire, usa prima [2] NORMALE." -F DarkGray
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '0' { return }
            default { Write-Warning 'Scelta non valida'; Start-Sleep 1 }
        }
    }
}


function Restore-OgdSignInOptions {
    Show-Banner
    Write-Section "RIPRISTINO OPZIONI DI ACCESSO / ACCOUNT"
    Write-Info "Ripristino servizi e policy che possono bloccare Sign-in options..."
    $restored = 0

    $svcTargets = @(
        @{Name='WbioSrvc';   Startup='Manual'; AutoStart=$true;  Desc='Windows Biometric Service'},
        @{Name='VaultSvc';   Startup='Manual'; AutoStart=$true;  Desc='Credential Manager'},
        @{Name='NgcSvc';     Startup='Manual'; AutoStart=$false; Desc='Microsoft Passport'},
        @{Name='NgcCtnrSvc'; Startup='Manual'; AutoStart=$false; Desc='Microsoft Passport Container'},
        @{Name='wlidsvc';    Startup='Manual'; AutoStart=$false; Desc='Microsoft Account Sign-in Assistant'}
    )

    foreach($svc in $svcTargets){
        try{
            $s = Get-Service -Name $svc.Name -EA SilentlyContinue
            if($s){
                Set-Service -Name $svc.Name -StartupType $svc.Startup -EA SilentlyContinue
                if($svc.AutoStart -and $s.Status -ne 'Running'){
                    Start-Service -Name $svc.Name -EA SilentlyContinue
                }
                $restored++
                Write-Success ("{0}: ripristinato ({1})" -f $svc.Desc, $svc.Name)
            } else {
                Write-Host ("  → {0}: non presente su questo sistema" -f $svc.Desc) -F DarkGray
            }
        }catch{
            Write-Warning ("{0}: impossibile ripristinare" -f $svc.Desc)
        }
    }

    Write-Info "Pulizia policy che possono nascondere pagine di Settings..."
    try{
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "SettingsPageVisibility" /f 2>$null | Out-Null
        reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "SettingsPageVisibility" /f 2>$null | Out-Null
        reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /f 2>$null | Out-Null
        Write-Success "Policy SettingsPageVisibility ripulite"
    }catch{
        Write-Warning "Policy SettingsPageVisibility: nessuna modifica o accesso negato"
    }

    Write-Info "Ri-registrazione rapida dell'app Impostazioni..."
    try{
        $settingsPkg = Get-AppxPackage *windows.immersivecontrolpanel* -AllUsers -EA SilentlyContinue
        if($settingsPkg){
            foreach($pkg in $settingsPkg){
                $manifest = Join-Path $pkg.InstallLocation 'AppXManifest.xml'
                if(Test-Path $manifest){
                    Add-AppxPackage -DisableDevelopmentMode -Register $manifest -EA SilentlyContinue | Out-Null
                }
            }
            Write-Success "App Impostazioni ri-registrata"
        } else {
            Write-Host "  → Pacchetto Settings non trovato, salto la ri-registrazione" -F DarkGray
        }
    }catch{
        Write-Warning "Ri-registrazione Impostazioni non completata"
    }

    Write-Host ""
    Write-Success "Ripristino Sign-in options completato"
    Write-Host "  • WbioSrvc non viene più disabilitato nel profilo aggressivo" -F DarkGray
    Write-Host "  • Ora prova: Impostazioni > Account > Opzioni di accesso" -F DarkGray
    Write-Host "  • Se usi Windows Hello, un riavvio è consigliato" -F DarkGray
    Write-Host ""
    Read-Host "  INVIO per continuare"
}

function Restore-OgdAppRuntimeCompatibility {
    Show-Banner
    Write-Section "RIPRISTINO COMPATIBILITA APP / .NET / LAUNCHER"
    Write-Info "Ripristino servizi e componenti che possono bloccare launcher come Nexus Vortex..."

    $svcTargets = @(
        @{Name='BITS';            Startup='Manual'; AutoStart=$true;  Desc='Background Intelligent Transfer Service'},
        @{Name='AppXSvc';         Startup='Manual'; AutoStart=$false; Desc='AppX Deployment Service'},
        @{Name='ClipSVC';         Startup='Manual'; AutoStart=$false; Desc='Client License Service'},
        @{Name='InstallService';  Startup='Manual'; AutoStart=$false; Desc='Microsoft Store Install Service'},
        @{Name='msiserver';       Startup='Manual'; AutoStart=$false; Desc='Windows Installer'},
        @{Name='wuauserv';        Startup='Manual'; AutoStart=$false; Desc='Windows Update'},
        @{Name='CryptSvc';        Startup='Automatic'; AutoStart=$true; Desc='Cryptographic Services'},
        @{Name='TrustedInstaller';Startup='Manual'; AutoStart=$false; Desc='Windows Modules Installer'}
    )

    foreach($svc in $svcTargets){
        try{
            $s = Get-Service -Name $svc.Name -EA SilentlyContinue
            if($s){
                Set-Service -Name $svc.Name -StartupType $svc.Startup -EA SilentlyContinue
                if($svc.AutoStart -and $s.Status -ne 'Running'){
                    Start-Service -Name $svc.Name -EA SilentlyContinue
                }
                Write-Success ("{0}: ripristinato ({1})" -f $svc.Desc, $svc.Name)
            }
        }catch{
            Write-Warning ("{0}: impossibile ripristinare" -f $svc.Desc)
        }
    }

    Write-Info "Ripristino policy app reputation / SmartScreen prudenti..."
    try{
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /t REG_SZ /d "Warn" /f 2>$null | Out-Null
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 1 /f 2>$null | Out-Null
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "PreventOverride" /t REG_DWORD /d 0 /f 2>$null | Out-Null
        Write-Success "SmartScreen/App reputation riportati a profilo compatibile"
    }catch{
        Write-Warning "SmartScreen/App reputation: ripristino non completo"
    }

    Write-Info "Ri-registrazione rapida Store / App Installer / UI shell..."
    foreach($pkgMask in @('*WindowsStore*','*DesktopAppInstaller*','*StorePurchaseApp*')){
        try{
            $pkgs = @(Get-AppxPackage $pkgMask -AllUsers -EA SilentlyContinue)
            foreach($pkg in $pkgs){
                $manifest = Join-Path $pkg.InstallLocation 'AppXManifest.xml'
                if(Test-Path $manifest){
                    Add-AppxPackage -DisableDevelopmentMode -Register $manifest -EA SilentlyContinue | Out-Null
                }
            }
        }catch{}
    }
    Write-Success "Pacchetti Store/App Installer ri-registrati dove presenti"

    Write-Info "Verifica .NET Framework Windows..."
    try{
        DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart 2>$null | Out-Null
        Write-Success ".NET Framework 3.5 richiesto/riattivato dove disponibile"
    }catch{
        Write-Warning ".NET Framework 3.5: riattivazione non completata"
    }

    Show-OgdWhatThisDoes 'Compatibilita app: cosa e stato fatto davvero' @(
        'ripristinati servizi usati da installer, store, deployment app e download in background',
        'riportato SmartScreen a profilo compatibile invece di blocchi aggressivi',
        'tentata riattivazione di .NET Framework 3.5 e ri-registrazione Store/App Installer',
        'utile per launcher e app moderne che dopo tweak aggressivi non si aprono piu'
    )
    Write-Host ""
    Write-Host "  Consiglio pratico per Nexus Vortex:" -F Cyan
    Write-Host "  1. Applica questo fix" -F White
    Write-Host "  2. Riavvia Windows" -F White
    Write-Host "  3. Se ancora non parte, reinstalla il runtime richiesto dall'app" -F White
    Write-Host ""
    Read-Host "  INVIO per continuare"
}

function Invoke-OgdWindowsUpdateFixer {
    Show-Banner
    Write-Section "WINDOWS UPDATE FIXER"
    Write-Info "Reset completo componenti Windows Update..."

    $services = @(
        @{ Name='wuauserv'; Startup='Manual' },
        @{ Name='bits';     Startup='Manual' },
        @{ Name='cryptsvc'; Startup='Automatic' },
        @{ Name='msiserver';Startup='Manual' },
        @{ Name='usosvc';   Startup='Automatic' },
        @{ Name='dosvc';    Startup='Automatic' }
    )
    $startupRestored = New-Object System.Collections.Generic.List[string]
    $startupFailed = New-Object System.Collections.Generic.List[string]
    foreach($svc in $services){
        try{
            Stop-Service -Name $svc.Name -Force -EA SilentlyContinue
            Write-Success ("Servizio fermato: {0}" -f $svc.Name)
        }catch{
            Write-Warning ("Servizio non fermabile o assente: {0}" -f $svc.Name)
        }
    }

    foreach($path in @(
        'C:\Windows\SoftwareDistribution\Download',
        'C:\Windows\SoftwareDistribution\DataStore',
        'C:\Windows\System32\catroot2'
    )){
        try{
            if(Test-Path $path){
                Remove-Item (Join-Path $path '*') -Recurse -Force -EA SilentlyContinue
                Write-Success ("Pulita cache: {0}" -f $path)
            }
        }catch{
            Write-Warning ("Impossibile pulire completamente: {0}" -f $path)
        }
    }

    foreach($svc in $services){
        try{
            Set-Service -Name $svc.Name -StartupType $svc.Startup -EA SilentlyContinue
            Start-Service -Name $svc.Name -EA SilentlyContinue
            [void]$startupRestored.Add($svc.Name)
            Write-Success ("Servizio ripristinato: {0} ({1})" -f $svc.Name,$svc.Startup)
        }catch{
            [void]$startupFailed.Add($svc.Name)
            Write-Warning ("Servizio non avviabile o assente: {0}" -f $svc.Name)
        }
    }

    try{ & "$env:SystemRoot\System32\UsoClient.exe" RefreshSettings 2>$null | Out-Null }catch{}
    try{ & "$env:SystemRoot\System32\UsoClient.exe" StartScan 2>$null | Out-Null }catch{}

    $summaryLines = New-Object System.Collections.Generic.List[string]
    [void]$summaryLines.Add('fermati i servizi principali di Windows Update e Delivery Optimization')
    [void]$summaryLines.Add('svuotate le cache SoftwareDistribution e catroot2 per forzare una ricostruzione pulita')
    if($startupRestored.Count -gt 0){
        [void]$summaryLines.Add(("startup type e avvio ripristinati per: {0}" -f ($startupRestored -join ', ')))
    }
    if($startupFailed.Count -gt 0){
        [void]$summaryLines.Add(("servizi non riallineati completamente: {0}" -f ($startupFailed -join ', ')))
    }
    Show-OgdWhatThisDoes 'Windows Update Fixer: cosa e stato fatto davvero' $summaryLines
    Read-Host "  INVIO per continuare"
}

function Invoke-OgdXboxReinstaller {
    Show-Banner
    Write-Section "XBOX REINSTALLER"
    Write-Info "Ripristino servizi Store/AppX e preparazione reinstallazione Xbox..."

    foreach($svc in @('BITS','AppXSvc','ClipSVC','InstallService','LicenseManager','GamingServices','GamingServicesNet','wuauserv')){
        try{
            Set-Service -Name $svc -StartupType Manual -EA SilentlyContinue
            Start-Service -Name $svc -EA SilentlyContinue
            Write-Success ("Servizio pronto: {0}" -f $svc)
        }catch{
            Write-Warning ("Servizio assente o non avviabile: {0}" -f $svc)
        }
    }

    try{ wsreset.exe | Out-Null }catch{}
    Write-Success "Microsoft Store resettato"

    foreach($pkgName in @(Get-OgdProtectedXboxPackages)){
        try{
            foreach($pkg in @(Get-AppxPackage -Name $pkgName -AllUsers -EA SilentlyContinue)){
                $manifest = Join-Path $pkg.InstallLocation 'AppxManifest.xml'
                if(Test-Path $manifest){
                    Add-AppxPackage -DisableDevelopmentMode -Register $manifest -EA SilentlyContinue | Out-Null
                }
            }
        }catch{}
    }
    Write-Success "Tentata la ri-registrazione dei componenti Xbox ancora presenti"

    $storeLinks = @(
        @{ Name='Gaming Services'; Id='9MWPM2CQNLHN'; PackageNames=@('Microsoft.GamingServices') },
        @{ Name='Xbox'; Id='9MV0B5HZVK9Z'; PackageNames=@('Microsoft.GamingApp','Microsoft.XboxApp') },
        @{ Name='Xbox Identity Provider'; Id='9WZDNCRD1HKW'; PackageNames=@('Microsoft.XboxIdentityProvider') }
    )
    $installedItems = New-Object System.Collections.Generic.List[string]
    $manualItems = New-Object System.Collections.Generic.List[string]
    foreach($item in $storeLinks){
        $verifiedInstalled = $false
        try{
            $wg = Invoke-OgdWinget -Arguments @('install','--id',$item.Id,'--source','msstore','--accept-source-agreements','--accept-package-agreements','--silent','--disable-interactivity') -TimeoutSec 240
            if($wg.Available -and -not $wg.TimedOut -and $wg.ExitCode -eq 0){
                Start-Sleep -Seconds 3
                foreach($pkgName in @($item.PackageNames)){
                    try{
                        if(@(Get-AppxPackage -Name $pkgName -AllUsers -EA SilentlyContinue).Count -gt 0){
                            $verifiedInstalled = $true
                            break
                        }
                    }catch{}
                }
                if($verifiedInstalled){
                    [void]$installedItems.Add($item.Name)
                    Write-Success ("Installazione verificata: {0}" -f $item.Name)
                } else {
                    Start-Process ("ms-windows-store://pdp/?productid={0}" -f $item.Id)
                    [void]$manualItems.Add($item.Name)
                    Write-Warning ("Installazione non verificata automaticamente: aperta pagina Store per {0}" -f $item.Name)
                }
            } else {
                Start-Process ("ms-windows-store://pdp/?productid={0}" -f $item.Id)
                [void]$manualItems.Add($item.Name)
                Write-Warning ("Installazione automatica non riuscita: aperta pagina Store per {0}" -f $item.Name)
            }
        }catch{
            try{ Start-Process ("ms-windows-store://search/?query={0}" -f [uri]::EscapeDataString($item.Name)) }catch{}
            [void]$manualItems.Add($item.Name)
            Write-Warning ("Store fallback aperto per {0}" -f $item.Name)
        }
    }

    $xboxSummary = New-Object System.Collections.Generic.List[string]
    [void]$xboxSummary.Add('ripristinati i servizi Store/AppX e, se presenti, i servizi Gaming Services')
    [void]$xboxSummary.Add('resettato Microsoft Store e tentata la ri-registrazione dei componenti Xbox ancora presenti')
    if($installedItems.Count -gt 0){
        [void]$xboxSummary.Add(("installazione verificata automaticamente per: {0}" -f ($installedItems -join ', ')))
    }
    if($manualItems.Count -gt 0){
        [void]$xboxSummary.Add(("installazione da completare tramite Store per: {0}" -f (($manualItems | Select-Object -Unique) -join ', ')))
    }
    Show-OgdWhatThisDoes 'Xbox Reinstaller: cosa e stato fatto davvero' $xboxSummary
    Read-Host "  INVIO per continuare"
}


function Show-OgdAmdGpuMenu {
    Clear-Host
    Write-Host ""
    Write-Host "  +--------------------------------------------------------------------+" -F DarkRed
    Write-Host "  | AMD GPU TWEAKS // RADEON CONTROL PANEL                             |" -F Red
    Write-Host "  +--------------------------------------------------------------------+" -F DarkRed
    Write-Host "  | NOTA: non avendo ancora hardware AMD reale da testare, questo ramo |" -F Yellow
    Write-Host "  | e fornito cosi com'e, senza supporto ufficiale. Uso a rischio tuo. |" -F Yellow
    Write-Host "  +--------------------------------------------------------------------+" -F DarkRed
    Write-Host "  | [1] LIGHT  - profilo safe per driver e latenze stabili             |" -F White
    Write-Host "  | [2] NORMALE- gaming bilanciato per RDNA2/RDNA3/RDNA4              |" -F White
    Write-Host "  | [3] ULTRA  - preset piu spinto ma sempre prudente                  |" -F White
    Write-Host "  | [0] INDIETRO                                                       |" -F DarkGray
    Write-Host "  +--------------------------------------------------------------------+" -F DarkRed
    Show-OgdAddonAppsHint 'AMDGPU'
}

function Show-OgdAmdCpuMenu {
    Clear-Host
    Write-Host ""
    Write-Host "  +--------------------------------------------------------------------+" -F DarkMagenta
    Write-Host "  | AMD CPU TWEAKS // RYZEN PERFORMANCE DECK                           |" -F Magenta
    Write-Host "  +--------------------------------------------------------------------+" -F DarkMagenta
    Write-Host "  | NOTA: non avendo ancora CPU AMD reale da validare, questo ramo e   |" -F Yellow
    Write-Host "  | distribuito senza supporto ufficiale. Uso a rischio dell'utente.   |" -F Yellow
    Write-Host "  +--------------------------------------------------------------------+" -F DarkMagenta
    Write-Host "  | [1] LIGHT  - profilo safe per Ryzen desktop/laptop                 |" -F White
    Write-Host "  | [2] NORMALE- boost reattivo e scheduler pulito                     |" -F White
    Write-Host "  | [3] ALTO   - desktop potente / X3D in carico gaming               |" -F White
    Write-Host "  | [4] ULTRA  - enthusiast, desktop ben raffreddato                  |" -F White
    Write-Host "  | [0] INDIETRO                                                       |" -F DarkGray
    Write-Host "  +--------------------------------------------------------------------+" -F DarkMagenta
    Show-OgdAddonAppsHint 'AMDCPU'
}

function Set-OgdAmdGpuPreset {
    param(
        [ValidateSet('LIGHT','NORMALE','ULTRA')]
        [string]$Preset
    )

    $gpuName = ''
    try{
        $gpuName = (Get-CimInstance Win32_VideoController -EA SilentlyContinue | Where-Object { $_.Name -match 'AMD|Radeon' } | Select-Object -First 1 -ExpandProperty Name)
    }catch{}
    if([string]::IsNullOrWhiteSpace($gpuName)){
        Write-Warning 'GPU AMD/Radeon non rilevata con certezza: applico solo il profilo di supporto lato Windows'
    }

    $planMode = 'Current'
    $enableHags = $false
    switch($Preset){
        'LIGHT'   { $planMode = 'Current';  $enableHags = $false }
        'NORMALE' { $planMode = 'High';     $enableHags = $true  }
        'ULTRA'   { $planMode = 'Ultimate'; $enableHags = $true  }
    }

    $scheme = Set-OgdPreferredPowerPlan -Plan $planMode
    Show-OgdWorkingAnimation -Text ("Applicazione preset AMD GPU {0}..." -f $Preset) -DurationMs 950 -Color Magenta

    reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled"   /t REG_DWORD /d 1 /f 2>$null|Out-Null
    reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode"     /t REG_DWORD /d 1 /f 2>$null|Out-Null
    reg add "HKCU\System\GameConfigStore"     /v "GameDVR_Enabled"       /t REG_DWORD /d 0 /f 2>$null|Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f 2>$null|Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 0x26 /f 2>$null|Out-Null
    if($enableHags){
        try{ reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f 2>$null|Out-Null }catch{}
    }
    try{ powercfg /setactive $scheme 2>$null | Out-Null }catch{}

    Write-Success ("AMD GPU {0}: preset applicato." -f $Preset)
    Show-OgdWhatThisDoes 'Questo preset AMD GPU ha applicato' @(
        ("profilo energetico: {0}" -f $(if($planMode -eq 'Current'){'profilo attivo corrente'}elseif($planMode -eq 'High'){'Prestazioni elevate, se disponibili'}else{'Prestazioni ultimate, se disponibili'})),
        'abilitati Game Mode e scheduler Win32 reattivo con DVR disattivato per ridurre overlay e catture inutili',
        ("HAGS {0} come supporto lato Windows al rendering moderno" -f $(if($enableHags){'attivato'}else{'lasciato invariato'})),
        ("target GPU rilevato: {0}" -f $(if($gpuName){$gpuName}else{'non determinato con certezza'}))
    )
}

function Set-OgdAmdCpuPreset {
    param(
        [ValidateSet('LIGHT','NORMALE','ALTO','ULTRA')]
        [string]$Preset
    )

    $cpuName = ''
    try{
        $cpuName = (Get-CimInstance Win32_Processor -EA SilentlyContinue | Select-Object -First 1 -ExpandProperty Name)
    }catch{}
    if(($cpuName -notmatch 'AMD|Ryzen') -and -not [string]::IsNullOrWhiteSpace($cpuName)){
        Write-Warning ("CPU non AMD rilevata ({0}): applico solo il profilo Windows lato processore" -f $cpuName)
    }

    $planMode = 'Current'
    $minAc = 5
    $minDc = 5
    $incThreshold = 15
    $decThreshold = 12
    switch($Preset){
        'LIGHT' {
            $planMode = 'Current'
        }
        'NORMALE' {
            $planMode = 'High'
            $minAc = 8
            $incThreshold = 12
            $decThreshold = 10
        }
        'ALTO' {
            $planMode = 'High'
            $minAc = 12
            $minDc = 6
            $incThreshold = 10
            $decThreshold = 8
        }
        'ULTRA' {
            $planMode = 'High'
            $minAc = 15
            $minDc = 8
            $incThreshold = 8
            $decThreshold = 6
        }
    }

    $scheme = Set-OgdPreferredPowerPlan -Plan $planMode
    Show-OgdWorkingAnimation -Text ("Applicazione preset AMD CPU {0}..." -f $Preset) -DurationMs 1000 -Color Red

    try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PERFBOOSTMODE 1 2>$null | Out-Null }catch{}
    try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR PERFBOOSTMODE 1 2>$null | Out-Null }catch{}
    try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PROCTHROTTLEMIN $minAc 2>$null | Out-Null }catch{}
    try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR PROCTHROTTLEMIN $minDc 2>$null | Out-Null }catch{}
    try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PERFINCTHRESHOLD $incThreshold 2>$null | Out-Null }catch{}
    try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR PERFINCTHRESHOLD $incThreshold 2>$null | Out-Null }catch{}
    try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PERFDECTHRESHOLD $decThreshold 2>$null | Out-Null }catch{}
    try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR PERFDECTHRESHOLD $decThreshold 2>$null | Out-Null }catch{}
    try{ powercfg /setactive $scheme 2>$null | Out-Null }catch{}
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 0x26 /f 2>$null|Out-Null

    Write-Success ("AMD CPU {0}: preset applicato." -f $Preset)
    Show-OgdWhatThisDoes 'Questo preset AMD CPU ha applicato' @(
        ("profilo energetico: {0}" -f $(if($planMode -eq 'Current'){'profilo attivo corrente'}elseif($planMode -eq 'High'){'Prestazioni elevate, se disponibili'}else{'Prestazioni ultimate, se disponibili'})),
        ("soglia minima CPU {0}% in AC e {1}% in batteria con profilo reso piu termicamente prudente" -f $minAc,$minDc),
        ("scheduler Win32 reattivo senza overclock e senza chiavi AMD non documentate"),
        ("target CPU rilevato: {0}" -f $(if($cpuName){$cpuName}else{'non determinato con certezza'}))
    )
}

function Invoke-OgdAmdGpuMenu {
    while($true){
        Show-OgdAmdGpuMenu
        $amdGpuChoice = Read-Host "  Scelta AMD GPU (1-3/0)"
        switch($amdGpuChoice){
            '1' {
                Write-Host ""
                Write-Host "  → AMD GPU LIGHT: profilo safe Radeon." -F DarkGray
                Set-OgdAmdGpuPreset -Preset 'LIGHT'
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '2' {
                Write-Host ""
                Write-Host "  → AMD GPU NORMALE: profilo bilanciato per Radeon gaming." -F DarkGray
                Set-OgdAmdGpuPreset -Preset 'NORMALE'
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '3' {
                Write-Host ""
                Write-Host "  → AMD GPU ULTRA: profilo piu spinto ma ancora prudente." -F DarkGray
                Set-OgdAmdGpuPreset -Preset 'ULTRA'
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '0' { return }
            default {
                Write-Host "  ⚠ Scelta non valida." -F Yellow
                Start-Sleep -Milliseconds 900
            }
        }
    }
}

function Invoke-OgdAmdCpuMenu {
    while($true){
        Show-OgdAmdCpuMenu
        $amdCpuChoice = Read-Host "  Scelta AMD CPU (1-4/0)"
        switch($amdCpuChoice){
            '1' {
                Write-Host ""
                Write-Host "  → AMD CPU LIGHT: profilo safe per Ryzen." -F DarkGray
                Set-OgdAmdCpuPreset -Preset 'LIGHT'
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '2' {
                Write-Host ""
                Write-Host "  → AMD CPU NORMALE: profilo bilanciato per Ryzen / X3D." -F DarkGray
                Set-OgdAmdCpuPreset -Preset 'NORMALE'
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '3' {
                Write-Host ""
                Write-Host "  → AMD CPU ALTO: preset per desktop potente o X3D ben raffreddato." -F DarkGray
                Set-OgdAmdCpuPreset -Preset 'ALTO'
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '4' {
                Write-Host ""
                Write-Host "  → AMD CPU ULTRA: preset enthusiast controllato." -F DarkGray
                Set-OgdAmdCpuPreset -Preset 'ULTRA'
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '0' { return }
            default {
                Write-Host "  ⚠ Scelta non valida." -F Yellow
                Start-Sleep -Milliseconds 900
            }
        }
    }
}

function Show-OgdIntelCpuMenu {
    Clear-Host
    Write-Host ""
    Write-Host "  +--------------------------------------------------------------------+" -F DarkCyan
    Write-Host "  | INTEL CPU TWEAKS // CORE ULTRA PERFORMANCE LAB                     |" -F Cyan
    Write-Host "  +--------------------------------------------------------------------+" -F DarkCyan
    Write-Host "  | [1] LIGHT  - profilo safe per Intel Core / Core Ultra             |" -F White
    Write-Host "  | [2] NORMALE- P/E core policy prudente e profilo gaming/work       |" -F White
    Write-Host "  | [3] ALTO   - desktop o Ultra 9 ben raffreddato                    |" -F White
    Write-Host "  | [4] ULTRA  - enthusiast, massima reattivita pratica               |" -F White
    Write-Host "  | [5] OGD PRESET - Ultra 9 285K + RTX 5080 + DDR5 7200 tuned       |" -F Yellow
    Write-Host "  | [0] INDIETRO                                                       |" -F DarkGray
    Write-Host "  +--------------------------------------------------------------------+" -F DarkCyan
    Show-OgdAddonAppsHint 'INTELCPU'
}

function Get-OgdActivePowerSchemeGuid {
    try{
        $raw = powercfg /getactivescheme 2>$null
        if($raw -match 'GUID:\s+([a-f0-9\-]+)'){
            return $Matches[1]
        }
    }catch{}
    return 'SCHEME_CURRENT'
}

function Get-OgdPowerPlans {
    $plans = @()
    try{
        foreach($line in @(powercfg /list 2>$null)){
            if($line -match '(?<active>\*)?\s*Power Scheme GUID:\s*(?<guid>[a-f0-9\-]{36})\s*\((?<name>.+?)\)\s*$'){
                $plans += [pscustomobject]@{
                    Guid     = $Matches['guid']
                    Name     = $Matches['name'].Trim()
                    IsActive = ($Matches['active'] -eq '*')
                }
            }
        }
    }catch{}
    return @($plans)
}

function New-OgdWinCaffePowerPlan {
    param([string]$Name = 'OGD WinCaffe v8.1.2')

    $existing = Get-OgdPowerPlans | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    if($existing){
        try{ powercfg /setactive $existing.Guid 2>$null | Out-Null }catch{}
        return $existing.Guid
    }

    $baseScheme = $null
    try{
        $ultimate = Get-OgdPowerPlans | Where-Object { $_.Name -match 'Ultimate|Prestazioni ultimate' } | Select-Object -First 1
        if($ultimate){ $baseScheme = $ultimate.Guid }
    }catch{}

    if(-not $baseScheme){
        try{
            $dupUltimate = powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
            if($dupUltimate -match '([a-f0-9\-]{36})'){
                $newGuid = $Matches[1]
                try{ powercfg /changename $newGuid $Name 2>$null | Out-Null }catch{}
                try{ powercfg /setactive $newGuid 2>$null | Out-Null }catch{}
                try{ powercfg /setacvalueindex $newGuid SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null | Out-Null }catch{}
                try{ powercfg /setdcvalueindex $newGuid SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null | Out-Null }catch{}
                return $newGuid
            }
        }catch{}
    }

    if(-not $baseScheme){
        try{
            $high = Get-OgdPowerPlans | Where-Object { $_.Name -match 'High performance|Prestazioni elevate' } | Select-Object -First 1
            if($high){ $baseScheme = $high.Guid }
        }catch{}
    }

    if(-not $baseScheme){
        $baseScheme = '381b4222-f694-41f0-9685-ff5bb260df2e'
    }

    try{
        $dup = powercfg /duplicatescheme $baseScheme 2>$null
        if($dup -match '([a-f0-9\-]{36})'){
            $newGuid = $Matches[1]
            try{ powercfg /changename $newGuid $Name 2>$null | Out-Null }catch{}
            try{ powercfg /setactive $newGuid 2>$null | Out-Null }catch{}
                try{ powercfg /setacvalueindex $newGuid SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null | Out-Null }catch{}
                try{ powercfg /setdcvalueindex $newGuid SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null | Out-Null }catch{}
            return $newGuid
        }
    }catch{}

    try{ powercfg /setactive $baseScheme 2>$null | Out-Null }catch{}
    return $baseScheme
}

function Remove-OgdLegacyPowerPlans {
    param([string]$KeepGuid)
    foreach($plan in Get-OgdPowerPlans){
        if($plan.Guid -eq $KeepGuid){ continue }
        if($plan.Name -match '^Ultimate OGD\b' -or ($plan.Name -match '^OGD WinCaffe\b' -and $plan.Name -notmatch 'v8\.0\.2')){
            try{ powercfg /delete $plan.Guid 2>$null | Out-Null }catch{}
        }
    }
}

function Remove-OgdDesktopPowerSaverPlan {
    param([switch]$Enabled)
    if(-not $Enabled){ return $false }

    $removed = $false
    foreach($plan in Get-OgdPowerPlans){
        if($plan.Name -match 'Power saver|Risparmio energetico' -or $plan.Guid -eq 'a1841308-3541-4fab-bc81-f71556f20b4a'){
            try{
                powercfg /delete $plan.Guid 2>$null | Out-Null
                $removed = $true
            }catch{}
        }
    }
    return $removed
}

function Set-OgdWinCaffePowerProfile {
    param(
        [ValidateSet('LIGHT','NORMAL','AGGRESSIVE','LAPTOP','LAPTOP_GAMING')]
        [string]$Preset,
        [switch]$RemoveDesktopPowerSaver
    )

    $scheme = New-OgdWinCaffePowerPlan
    if(-not $scheme){ $scheme = Get-OgdActivePowerSchemeGuid }

    switch($Preset){
        'LIGHT' {
            try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR IDLEDISABLE 0 2>$null | Out-Null }catch{}
            try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR IDLEDISABLE 0 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR IDLESTATEMAX 1 2>$null | Out-Null }catch{}
            try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR IDLESTATEMAX 1 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null | Out-Null }catch{}
            try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null | Out-Null }catch{}
            try{ powercfg /setdcvalueindex $scheme 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null | Out-Null }catch{}
        }
        'NORMAL' {
            try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PERFBOOSTMODE 1 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PERFINCTHRESHOLD 10 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PERFDECTHRESHOLD 8 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PERFINCTIME 1 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PERFDECTIME 1 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null | Out-Null }catch{}
        }
        'AGGRESSIVE' {
            try{ powercfg /setacvalueindex $scheme 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 10 2>$null | Out-Null }catch{}
            try{ powercfg /setdcvalueindex $scheme 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 10 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PERFBOOSTMODE 1 2>$null | Out-Null }catch{}
            try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR PERFBOOSTMODE 1 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PROCTHROTTLEMIN 10 2>$null | Out-Null }catch{}
            try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR PROCTHROTTLEMIN 8 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null | Out-Null }catch{}
            try{ powercfg /setdcvalueindex $scheme 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null | Out-Null }catch{}
        }
        'LAPTOP' {
            try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PERFBOOSTMODE 1 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PROCTHROTTLEMIN 15 2>$null | Out-Null }catch{}
            try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR IDLESTATEMAX 1 2>$null | Out-Null }catch{}
        }
        'LAPTOP_GAMING' {
            try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PERFBOOSTMODE 1 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PROCTHROTTLEMIN 25 2>$null | Out-Null }catch{}
            try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR PROCTHROTTLEMIN 10 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null | Out-Null }catch{}
        }
    }

    try{ powercfg /setactive $scheme 2>$null | Out-Null }catch{}
    Remove-OgdLegacyPowerPlans -KeepGuid $scheme
    $removedPowerSaver = Remove-OgdDesktopPowerSaverPlan -Enabled:$RemoveDesktopPowerSaver

    return [pscustomobject]@{
        SchemeGuid        = $scheme
        Preset            = $Preset
        RemovedPowerSaver = [bool]$removedPowerSaver
        Name              = 'OGD WinCaffe v8.1.2'
    }
}

function Set-OgdPreferredPowerPlan {
    param(
        [ValidateSet('Current','High','Ultimate')]
        [string]$Plan = 'Current'
    )
    if($Plan -eq 'Current'){
        return (Get-OgdActivePowerSchemeGuid)
    }

    $target = $null
    if($Plan -eq 'Ultimate'){
        try{
            $ult = powercfg /list 2>$null | Select-String 'Ultimate|Prestazioni ultimate'
            if($ult -and $ult.ToString() -match '([a-f0-9-]{36})'){
                $target = $Matches[1]
            }
        }catch{}
    }

    if(-not $target -and $Plan -in @('High','Ultimate')){
        try{
            $hp = powercfg /list 2>$null | Select-String 'High performance|Prestazioni elevate'
            if($hp -and $hp.ToString() -match '([a-f0-9-]{36})'){
                $target = $Matches[1]
            }
        }catch{}
    }

    if($target){
        try{ powercfg /setactive $target 2>$null | Out-Null }catch{}
        return $target
    }
    return (Get-OgdActivePowerSchemeGuid)
}

function Invoke-OgdFullRollbackToDefault {
    param([string]$ProfileLabel = 'profilo corrente')

    Show-Banner
    Write-Section "ROLLBACK DEFAULT WINDOWS"
    Write-Host ("  Profilo richiesto: {0}" -f $ProfileLabel) -F White
    Write-Host "  Questo rollback prova a riportare il sistema ai default Windows, non a un preset OGD." -F Yellow
    if((Read-Host "  Confermi il rollback completo? (S/N)") -notin @('S','s')){
        Write-Host ""
        Write-Host "  Rollback annullato." -F DarkGray
        return $false
    }

    Write-Host ""
    $desc = "OGD WinCaffe NEXT Rollback Default - $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
    New-OgdRestorePoint -Description $desc

    Write-Info "Ripristino boot e timer nativi..."
    foreach($bcd in @('useplatformclock','disabledynamictick','tscsyncpolicy','x2apicpolicy','useplatformtick')){
        try{ bcdedit /deletevalue $bcd 2>$null | Out-Null }catch{}
    }

    Write-Info "Ripristino piani energetici Windows..."
    try{ powercfg -restoredefaultschemes 2>$null | Out-Null }catch{}
    try{ powercfg /setactive SCHEME_BALANCED 2>$null | Out-Null }catch{}

    Write-Info "Ripristino memory management e scheduler..."
    $mm = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
    try{ Set-ItemProperty $mm -Name 'DisablePagingExecutive' -Value 0 -Type DWord -Force -EA SilentlyContinue }catch{}
    try{ Set-ItemProperty $mm -Name 'LargeSystemCache' -Value 0 -Type DWord -Force -EA SilentlyContinue }catch{}
    foreach($name in @('NonPagedPoolSize','SessionViewSize','SessionPoolSize','SystemPages','IoPageLockLimit','SecondLevelDataCache')){
        try{ Remove-ItemProperty -Path $mm -Name $name -Force -EA SilentlyContinue }catch{}
    }
    $pp = "$mm\PrefetchParameters"
    try{ if(!(Test-Path $pp)){ New-Item $pp -Force -EA SilentlyContinue | Out-Null } }catch{}
    try{ Set-ItemProperty $pp -Name 'EnableSuperfetch' -Value 3 -Type DWord -Force -EA SilentlyContinue }catch{}
    try{ Set-ItemProperty $pp -Name 'EnablePrefetcher' -Value 3 -Type DWord -Force -EA SilentlyContinue }catch{}
    try{ reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 2 /f 2>$null|Out-Null }catch{}

    Write-Info "Ripristino impostazioni gaming e grafica lato Windows..."
    try{ reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /f 2>$null|Out-Null }catch{}
    foreach($pair in @(
        @{Path='HKCU:\Software\Microsoft\GameBar'; Name='AutoGameModeEnabled'},
        @{Path='HKCU:\Software\Microsoft\GameBar'; Name='AllowAutoGameMode'},
        @{Path='HKCU:\System\GameConfigStore'; Name='GameDVR_Enabled'},
        @{Path='HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'; Name='HwSchMode'}
    )){
        try{ Remove-ItemProperty -Path $pair.Path -Name $pair.Name -Force -EA SilentlyContinue }catch{}
    }

    Write-Info "Ripristino stack USB/HID e risparmio energetico input..."
    try{ Restore-OgdUsbInputDefaults | Out-Null }catch{}

    Write-Info "Ripristino accessibilita font..."
    try{ Disable-OgdOpenDyslexicAsDefault }catch{}

    Show-OgdWhatThisDoes 'Rollback default completato' @(
        'ripristinati i parametri boot/timer piu sensibili alla gestione nativa di Windows',
        'riportati power plan, memory management, scheduler Win32 e impostazioni gaming verso default piu vicini al sistema pulito',
        'eventuale sostituzione font OpenDyslexic disattivata per tornare ai font standard'
    )
    Write-Success 'Rollback verso default Windows completato. Riavvia il PC per consolidare il ripristino.'
    return $true
}

function Restore-OgdUsbInputDefaults {
    Write-Info 'Ripristino stack USB/HID a default Windows...'

    foreach($pair in @(
        @{ Path='HKLM:\SYSTEM\CurrentControlSet\Services\usbhub'; Name='DisableSelectiveSuspend' },
        @{ Path='HKLM:\SYSTEM\CurrentControlSet\Services\USB';    Name='DisableSelectiveSuspend' },
        @{ Path='HKLM:\SYSTEM\CurrentControlSet\Services\HidUsb'; Name='AssociatorsLimit' }
    )){
        try{ Remove-ItemProperty -Path $pair.Path -Name $pair.Name -Force -EA SilentlyContinue }catch{}
    }

    foreach($scheme in @('SCHEME_CURRENT','SCHEME_BALANCED')){
        try{ powercfg /setacvalueindex $scheme 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 2>$null | Out-Null }catch{}
        try{ powercfg /setdcvalueindex $scheme 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 2>$null | Out-Null }catch{}
    }
    try{ powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null }catch{}

    try{ Set-Service -Name 'hidserv' -StartupType Manual -EA SilentlyContinue }catch{}
    try{
        $hidSvc = Get-Service -Name 'hidserv' -EA SilentlyContinue
        if($hidSvc -and $hidSvc.Status -ne 'Running'){ Start-Service -Name 'hidserv' -EA SilentlyContinue }
    }catch{}

    try{ pnputil /scan-devices | Out-Null }catch{}
    Write-Success 'USB/HID: chiavi invasive rimosse, selective suspend riportata a default e rescan dispositivi richiesto'
    Show-OgdWhatThisDoes 'Ripristino USB/HID: cosa e stato fatto davvero' @(
        'rimosse le chiavi piu invasive sullo stack USB e HID che potevano lasciare mouse e tastiera in stato incoerente',
        'USB selective suspend riportata al default Windows nei piani correnti',
        'richiesto un rescan Plug and Play per ridare una chance immediata a mouse e tastiera senza cambiare porta'
    )
    return $true
}

function Get-OgdAntiCheatConflictProcesses {
    $patterns = @(
        'ida','ida64','ida32','idag','idaw',
        'x64dbg','x32dbg','ollydbg',
        'dnspy','dnspy-x86',
        'cheatengine','cheat engine',
        'processhacker','process hacker',
        'ghidra','ghidra64'
    )
    $results = @()
    try{
        foreach($p in @(Get-Process -EA SilentlyContinue)){
            $name = [string]$p.ProcessName
            $path = ''
            try{ $path = [string]$p.Path }catch{}
            $hay = ($name + ' ' + $path).ToLowerInvariant()
            if($patterns | Where-Object { $hay -like ('*' + $_ + '*') }){
                $results += [pscustomobject]@{
                    Name = $name
                    Id   = $p.Id
                    Path = $path
                }
            }
        }
    }catch{}
    return @($results | Sort-Object Name,Id -Unique)
}

function Invoke-OgdAntiCheatConflictFix {
    $conflicts = @(Get-OgdAntiCheatConflictProcesses)

    Show-Banner
    Write-Section 'FIX ANTI-CHEAT / PROCESSI INCOMPATIBILI'
    Write-Host ''
    Write-Host '  Questo fix cerca software di debug/reverse engineering che molti anti-cheat' -F White
    Write-Host '  non permettono insieme al gioco, incluso il caso reale di IDA.' -F DarkGray
    Write-Host ''

    if($conflicts.Count -eq 0){
        Write-Success 'Nessun processo incompatibile rilevato in questo momento'
        Write-Host '  Se l anti-cheat continua a bloccare l avvio, controlla anche processi avviati al boot' -F DarkGray
        Write-Host '  oppure riavvia Windows prima di ritestare il gioco.' -F DarkGray
        return $true
    }

    Write-Warning ("Trovati {0} processi potenzialmente incompatibili:" -f $conflicts.Count)
    foreach($proc in $conflicts){
        $suffix = if([string]::IsNullOrWhiteSpace($proc.Path)){ '' } else { " | $($proc.Path)" }
        Write-Host ("    • {0} (PID {1}){2}" -f $proc.Name,$proc.Id,$suffix) -F Yellow
    }

    Write-Host ''
    if((Read-Host '  Vuoi provare a chiuderli adesso? (S/N)') -notin @('S','s')){
        Write-Host '  Nessuna chiusura eseguita. Chiudili manualmente prima di rilanciare il gioco.' -F DarkGray
        return $false
    }

    $closed = 0
    foreach($proc in $conflicts){
        try{
            Stop-Process -Id $proc.Id -Force -EA Stop
            Write-Success ("Processo chiuso: {0} (PID {1})" -f $proc.Name,$proc.Id)
            $closed++
        }catch{
            Write-Warning ("Impossibile chiudere {0} (PID {1})" -f $proc.Name,$proc.Id)
        }
    }

    Write-Host ''
    if($closed -gt 0){
        Write-Success ("Chiusi {0}/{1} processi incompatibili" -f $closed,$conflicts.Count)
        Show-OgdWhatThisDoes 'Fix anti-cheat: cosa e stato fatto davvero' @(
            'cercati processi tipicamente bloccati dagli anti-cheat come debugger, reverse tools o memory scanner',
            'tentata la chiusura dei processi trovati per liberare subito l avvio del gioco',
            'se il blocco resta, conviene riavviare Windows per svuotare processi o driver rimasti agganciati'
        )
    } else {
        Write-Error2 'Nessun processo e stato chiuso automaticamente'
        Write-Host '  Prova a chiuderli manualmente o riavvia il PC prima di rilanciare il gioco.' -F DarkGray
    }
    return ($closed -gt 0)
}

function Set-OgdIntelCpuPreset {
    param(
        [ValidateSet('LIGHT','NORMALE','ALTO','ULTRA','OGD')]
        [string]$Preset
    )

    $planMode = 'Current'
    $minAc = 5
    $minDc = 5
    $boostMode = 1
    $incThreshold = 15
    $decThreshold = 12
    $incTime = 2
    $decTime = 2
    $label = $Preset
    $cpuName = ''
    $isUltra9Desktop = $false
    $gpuNames = @()
    $boardName = ''
    $totalRamGb = 0
    $maxRamSpeed = 0
    $looksLikeOgdRig = $false

    try{
        $cpuName = (Get-CimInstance Win32_Processor -EA SilentlyContinue | Select-Object -First 1 -ExpandProperty Name)
        $isUltra9Desktop = ($cpuName -match 'Intel\(R\) Core\(TM\) Ultra 9 285K|Core Ultra 9 285K')
    }catch{}
    try{
        $gpuNames = @(Get-CimInstance Win32_VideoController -EA SilentlyContinue | ForEach-Object { [string]$_.Name } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }catch{}
    try{
        $boardName = [string](Get-CimInstance Win32_BaseBoard -EA SilentlyContinue | Select-Object -First 1 -ExpandProperty Product)
    }catch{}
    try{
        $ramModules = @(Get-CimInstance Win32_PhysicalMemory -EA SilentlyContinue)
        if($ramModules.Count -gt 0){
            $totalRamGb = [math]::Round((($ramModules | Measure-Object -Property Capacity -Sum).Sum / 1GB),0)
            $speedCandidates = @()
            foreach($m in $ramModules){
                if([int]$m.ConfiguredClockSpeed -gt 0){ $speedCandidates += [int]$m.ConfiguredClockSpeed }
                elseif([int]$m.Speed -gt 0){ $speedCandidates += [int]$m.Speed }
            }
            if($speedCandidates.Count -gt 0){
                $maxRamSpeed = ($speedCandidates | Measure-Object -Maximum).Maximum
            }
        }
    }catch{}

    $has5080 = @($gpuNames | Where-Object { $_ -match 'RTX\s*5080|GeForce\s*RTX\s*5080' }).Count -gt 0
    $hasZ890 = $boardName -match 'Z890-P|PRO Z890-P|MSI.*Z890'
    $hasRamProfile = ($totalRamGb -ge 32 -and $maxRamSpeed -ge 7000)
    $looksLikeOgdRig = ($isUltra9Desktop -and $has5080 -and $hasZ890 -and $hasRamProfile)

    switch($Preset){
        'LIGHT' {
            $planMode = 'Current'
            $minAc = 5
            $minDc = 5
            $incThreshold = 15
            $decThreshold = 12
            $incTime = 2
            $decTime = 2
        }
        'NORMALE' {
            $planMode = 'High'
            $minAc = 8
            $minDc = 5
            $incThreshold = 12
            $decThreshold = 10
            $incTime = 1
            $decTime = 1
        }
        'ALTO' {
            $planMode = 'High'
            $minAc = 12
            $minDc = 6
            $incThreshold = 10
            $decThreshold = 8
            $incTime = 1
            $decTime = 1
        }
        'ULTRA' {
            $planMode = 'High'
            $minAc = 15
            $minDc = 8
            $incThreshold = 8
            $decThreshold = 6
            $incTime = 1
            $decTime = 1
        }
        'OGD' {
            $planMode = 'High'
            $minAc = 9
            $minDc = 6
            $incThreshold = 14
            $decThreshold = 12
            $incTime = 1
            $decTime = 1
            $label = 'OGD PRESET'
        }
    }

    if($isUltra9Desktop){
        switch($Preset){
            'NORMALE' {
                $minAc = 7
                $minDc = 5
                $incThreshold = 14
                $decThreshold = 12
                $label = 'NORMALE (Ultra 9 thermal-safe)'
            }
            'ALTO' {
                $planMode = 'High'
                $minAc = 10
                $minDc = 6
                $incThreshold = 12
                $decThreshold = 10
                $label = 'ALTO (Ultra 9 thermal-safe)'
            }
            'ULTRA' {
                $planMode = 'High'
                $minAc = 12
                $minDc = 8
                $incThreshold = 10
                $decThreshold = 8
                $label = 'ULTRA (Ultra 9 thermal-safe)'
            }
            'OGD' {
                $planMode = 'High'
                $minAc = 8
                $minDc = 5
                $incThreshold = 15
                $decThreshold = 13
                $label = 'OGD PRESET (Ultra 9 285K tuned)'
            }
        }
    }

    $scheme = Set-OgdPreferredPowerPlan -Plan $planMode
    Show-OgdWorkingAnimation -Text ("Applicazione preset Intel {0}..." -f $label) -DurationMs 1100 -Color Cyan

    try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PERFBOOSTMODE $boostMode 2>$null | Out-Null }catch{}
    try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR PERFBOOSTMODE $boostMode 2>$null | Out-Null }catch{}
    try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PROCTHROTTLEMIN $minAc 2>$null | Out-Null }catch{}
    try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR PROCTHROTTLEMIN $minDc 2>$null | Out-Null }catch{}
    try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PERFINCTHRESHOLD $incThreshold 2>$null | Out-Null }catch{}
    try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR PERFINCTHRESHOLD $incThreshold 2>$null | Out-Null }catch{}
    try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PERFDECTHRESHOLD $decThreshold 2>$null | Out-Null }catch{}
    try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR PERFDECTHRESHOLD $decThreshold 2>$null | Out-Null }catch{}
    try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PERFINCTIME $incTime 2>$null | Out-Null }catch{}
    try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR PERFINCTIME $incTime 2>$null | Out-Null }catch{}
    try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR PERFDECTIME $decTime 2>$null | Out-Null }catch{}
    try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR PERFDECTIME $decTime 2>$null | Out-Null }catch{}
    try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR IDLEDISABLE 0 2>$null | Out-Null }catch{}
    try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR IDLEDISABLE 0 2>$null | Out-Null }catch{}
    try{ powercfg /setacvalueindex $scheme SUB_PROCESSOR IDLESTATEMAX 1 2>$null | Out-Null }catch{}
    try{ powercfg /setdcvalueindex $scheme SUB_PROCESSOR IDLESTATEMAX 1 2>$null | Out-Null }catch{}
    try{ powercfg /setactive $scheme 2>$null | Out-Null }catch{}

    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 0x26 /f 2>$null|Out-Null

    Write-Success ("Intel CPU {0}: preset applicato." -f $label)
    Show-OgdWhatThisDoes 'Questo preset Intel ha applicato' @(
        ("piano energetico: {0}" -f $(if($planMode -eq 'Current'){'profilo attivo corrente'}elseif($planMode -eq 'High'){'Prestazioni elevate, se disponibile'}else{'Prestazioni ultimate, se disponibile; altrimenti Prestazioni elevate'})),
        ("processor boost moderato con soglia minima CPU {0}% in AC e {1}% in batteria" -f $minAc,$minDc),
        ($(if($isUltra9Desktop){'profilo termico specifico per Core Ultra 9 285K: meno permanenza ad alto clock sotto carico prolungato'}else{'scheduler Win32 impostato in modo reattivo ma prudente, senza overclock e senza tweak sperimentali'})),
        ($(if($Preset -eq 'OGD'){'preset pensato per Intel Ultra 9 285K, RTX 5080, 32 GB DDR5 7200 e piattaforma Z890 ad alte prestazioni'}else{'profilo Intel generico adatto a desktop moderni e Core Ultra'})),
        ($(if($Preset -eq 'OGD' -and $looksLikeOgdRig){'hardware rilevato molto vicino al tuo OGD PRESET: applicazione pienamente coerente con la macchina dichiarata'}elseif($Preset -eq 'OGD'){'hardware rilevato non identico al rig OGD atteso: applicato comunque come preset compatibile ma non cucito al 100%'}else{'preservati idle/C-state Windows per evitare calore inutile quando il carico scende'}))
    )
}

function Invoke-OgdIntelCpuMenu {
    while($true){
        Show-OgdIntelCpuMenu
        $intelChoice = Read-Host "  Scelta Intel CPU (1-5/0)"
        switch($intelChoice){
            '1' {
                Write-Host ""
                Write-Host "  → LIGHT: mantiene il piano corrente e rende la CPU più pronta senza spingerla inutilmente." -F DarkGray
                Set-OgdIntelCpuPreset -Preset 'LIGHT'
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '2' {
                Write-Host ""
                Write-Host "  → NORMALE: profilo bilanciato per gaming/lavoro su Core moderni e Core Ultra." -F DarkGray
                Set-OgdIntelCpuPreset -Preset 'NORMALE'
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '3' {
                Write-Host ""
                Write-Host "  → ALTO: per desktop o Ultra 9 ben raffreddato, senza entrare in tweak estremi." -F DarkGray
                Set-OgdIntelCpuPreset -Preset 'ALTO'
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '4' {
                Write-Host ""
                Write-Host "  → ULTRA: preset enthusiast ma ancora controllato, senza overclock né chiavi strane." -F DarkGray
                Set-OgdIntelCpuPreset -Preset 'ULTRA'
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '5' {
                Write-Host ""
                Write-Host "  → OGD PRESET: tarato sul tuo Ultra 9 285K + RTX 5080 + 32 GB DDR5 7200 con approccio high-end ma termicamente prudente." -F Yellow
                Set-OgdIntelCpuPreset -Preset 'OGD'
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '0' { return }
            default {
                Write-Host "  ⚠ Scelta non valida." -F Yellow
                Start-Sleep -Milliseconds 900
            }
        }
    }
}

function Set-OgdIntelGpuPreset {
    param(
        [ValidateSet('LIGHT','NORMALE','AGGRESSIVO')]
        [string]$Preset
    )

    $gpuName = ''
    try{
        $gpuName = (Get-CimInstance Win32_VideoController -EA SilentlyContinue | Where-Object {
            $_.Name -match 'Intel' -or $_.Name -match 'Arc'
        } | Select-Object -First 1 -ExpandProperty Name)
    }catch{}

    if([string]::IsNullOrWhiteSpace($gpuName)){
        Write-Warning 'GPU Intel non rilevata con certezza: applico solo il profilo Windows-side e lascio i toggle driver a Intel Graphics Software'
    }

    $planMode = 'Current'
    $enableHags = $false
    switch($Preset){
        'LIGHT'      { $planMode = 'Current';  $enableHags = $false }
        'NORMALE'    { $planMode = 'High';     $enableHags = $true  }
        'AGGRESSIVO' { $planMode = 'Ultimate'; $enableHags = $true  }
    }

    $scheme = Set-OgdPreferredPowerPlan -Plan $planMode
    Show-OgdWorkingAnimation -Text ("Applicazione preset Intel GPU {0}..." -f $Preset) -DurationMs 900 -Color Cyan

    reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled"   /t REG_DWORD /d 1 /f 2>$null|Out-Null
    reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode"     /t REG_DWORD /d 1 /f 2>$null|Out-Null
    reg add "HKCU\System\GameConfigStore"     /v "GameDVR_Enabled"       /t REG_DWORD /d 0 /f 2>$null|Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f 2>$null|Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 0x26 /f 2>$null|Out-Null
    if($enableHags){
        try{ reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f 2>$null|Out-Null }catch{}
    }
    try{ powercfg /setactive $scheme 2>$null | Out-Null }catch{}

    Write-Success ("Intel GPU {0}: preset applicato." -f $Preset)
    Show-OgdWhatThisDoes 'Questo preset Intel GPU ha applicato' @(
        ("profilo energetico: {0}" -f $(if($planMode -eq 'Current'){'profilo attivo corrente'}elseif($planMode -eq 'High'){'Prestazioni elevate, se disponibili'}else{'Prestazioni ultimate, se disponibili'})),
        'abilitati Game Mode e scheduler Win32 reattivo con DVR disattivato per ridurre catture e overlay inutili',
        ("HAGS {0} come supporto lato Windows al rendering moderno" -f $(if($enableHags){'attivato'}else{'lasciato invariato'})),
        'i toggle driver ufficiali Intel restano da rifinire in Intel Graphics Software: Low Latency Mode per DX9/DX11 e Power Mode su Maximum Performance o Balanced secondo il gioco',
        ("target GPU rilevato: {0}" -f $(if($gpuName){$gpuName}else{'non determinato con certezza'}))
    )
}

function Show-OgdIntelGpuMenu {
    Clear-Host
    Write-Host ""
    Write-Host "  +--------------------------------------------------------------------+" -F DarkBlue
    Write-Host "  | INTEL GPU TWEAKS // INTEL GRAPHICS AND ARC                         |" -F Blue
    Write-Host "  +--------------------------------------------------------------------+" -F DarkBlue
    Write-Host "  | [1] LIGHT  - profilo safe per Intel Graphics / Arc                 |" -F White
    Write-Host "  | [2] NORMALE- gaming bilanciato per Intel Graphics / Arc            |" -F White
    Write-Host "  | [3] AGGRESSIVO - profilo forte ma senza overclock                  |" -F White
    Write-Host "  | [0] INDIETRO                                                       |" -F DarkGray
    Write-Host "  +--------------------------------------------------------------------+" -F DarkBlue
    Show-OgdAddonAppsHint 'INTELGPU'
}

function Invoke-OgdIntelGpuMenu {
    while($true){
        Show-OgdIntelGpuMenu
        $intelGpuChoice = Read-Host "  Scelta Intel GPU (1-3/0)"
        switch($intelGpuChoice){
            '1' {
                Write-Host ""
                Write-Host "  → INTEL GPU LIGHT: profilo safe Intel Graphics / Arc." -F DarkGray
                Set-OgdIntelGpuPreset -Preset 'LIGHT'
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '2' {
                Write-Host ""
                Write-Host "  → INTEL GPU NORMALE: profilo bilanciato per gaming/work." -F DarkGray
                Set-OgdIntelGpuPreset -Preset 'NORMALE'
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '3' {
                Write-Host ""
                Write-Host "  → INTEL GPU AGGRESSIVO: profilo forte ma senza OC." -F DarkGray
                Set-OgdIntelGpuPreset -Preset 'AGGRESSIVO'
                Read-Host "  INVIO per continuare" | Out-Null
            }
            '0' { return }
            default {
                Write-Host "  ⚠ Scelta non valida." -F Yellow
                Start-Sleep -Milliseconds 900
            }
        }
    }
}

function Set-OgdNvidiaGpuPresetSafe {
    param(
        [ValidateSet('LIGHT','NORMALE','AGGRESSIVO')]
        [string]$Preset
    )

    $gpuName = ''
    try{
        $gpuName = (Get-CimInstance Win32_VideoController -EA SilentlyContinue | Where-Object {
            $_.Name -match 'NVIDIA'
        } | Select-Object -First 1 -ExpandProperty Name)
    }catch{}

    if([string]::IsNullOrWhiteSpace($gpuName)){
        Write-Warning 'GPU NVIDIA non rilevata con certezza: applico solo il profilo Windows-side e lascio i toggle driver a NVIDIA App / Pannello di controllo'
    }

    $planMode = 'Current'
    $enableHags = $false
    switch($Preset){
        'LIGHT'      { $planMode = 'Current';  $enableHags = $false }
        'NORMALE'    { $planMode = 'High';     $enableHags = $true  }
        'AGGRESSIVO' { $planMode = 'Ultimate'; $enableHags = $true  }
    }

    $scheme = Set-OgdPreferredPowerPlan -Plan $planMode
    Show-OgdWorkingAnimation -Text ("Applicazione preset NVIDIA GPU {0}..." -f $Preset) -DurationMs 900 -Color Green

    reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled"   /t REG_DWORD /d 1 /f 2>$null|Out-Null
    reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode"     /t REG_DWORD /d 1 /f 2>$null|Out-Null
    reg add "HKCU\System\GameConfigStore"     /v "GameDVR_Enabled"       /t REG_DWORD /d 0 /f 2>$null|Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f 2>$null|Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 0x26 /f 2>$null|Out-Null
    if($enableHags){
        try{ reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f 2>$null|Out-Null }catch{}
    }
    try{ powercfg /setactive $scheme 2>$null | Out-Null }catch{}

    Write-Success ("NVIDIA GPU {0}: preset applicato." -f $Preset)
    Show-OgdWhatThisDoes 'Questo preset NVIDIA GPU ha applicato' @(
        ("profilo energetico: {0}" -f $(if($planMode -eq 'Current'){'profilo attivo corrente'}elseif($planMode -eq 'High'){'Prestazioni elevate, se disponibili'}else{'Prestazioni ultimate, se disponibili'})),
        'abilitati Game Mode e scheduler Win32 reattivo con DVR disattivato per ridurre catture e overlay inutili',
        ("HAGS {0} come supporto lato Windows al rendering moderno" -f $(if($enableHags){'attivato'}else{'lasciato invariato'})),
        'i toggle driver ufficiali NVIDIA restano da rifinire in gioco o in NVIDIA App / Pannello: Reflex se supportato, Low Latency Mode per i titoli senza Reflex, ReBAR da BIOS/driver se la piattaforma lo supporta',
        ("target GPU rilevato: {0}" -f $(if($gpuName){$gpuName}else{'non determinato con certezza'}))
    )
}

function Show-OgdVendorComboMenu {
    Clear-Host
    Write-Host ""
    Write-Host "  +--------------------------------------------------------------------+" -F DarkGray
    Write-Host "  | COMBINED PLATFORM PRESETS // CPU + GPU                             |" -F Black -BackgroundColor Gray
    Write-Host "  +--------------------------------------------------------------------+" -F DarkGray
    Write-Host "  | [1] AMD CPU + AMD GPU      Ryzen + Radeon                          |" -F Magenta
    Write-Host "  | [2] INTEL CPU + INTEL GPU  Core/Core Ultra + Intel Graphics/Arc    |" -F Cyan
    Write-Host "  | [3] AMD CPU + NVIDIA GPU   Ryzen + GeForce                         |" -F Yellow
    Write-Host "  | [4] INTEL CPU + NVIDIA GPU Core/Core Ultra + GeForce               |" -F Green
    Write-Host "  | [0] INDIETRO                                                       |" -F DarkGray
    Write-Host "  +--------------------------------------------------------------------+" -F DarkGray
    Write-Host ""
    Write-Host "  Ogni famiglia offre tre livelli: LIGHT, NORMALE e AGGRESSIVO." -F White
    Write-Host "  I tweak lato driver restano affidati ai tool ufficiali del vendor." -F DarkGray
    Write-Host ""
}

function Show-OgdVendorComboLevelMenu {
    param(
        [string]$Title,
        [string[]]$Notes = @()
    )

    Clear-Host
    Write-Host ""
    Write-Host "  +--------------------------------------------------------------------+" -F DarkGray
    Write-Host ("  | {0}" -f $Title.PadRight(66)) -F Black -BackgroundColor Gray
    Write-Host "  +--------------------------------------------------------------------+" -F DarkGray
    Write-Host "  | [1] LIGHT      profilo safe e pulito                               |" -F White
    Write-Host "  | [2] NORMALE    profilo bilanciato gaming/work                      |" -F White
    Write-Host "  | [3] AGGRESSIVO profilo forte ma senza overclock forzato            |" -F White
    Write-Host "  | [0] INDIETRO                                                       |" -F DarkGray
    Write-Host "  +--------------------------------------------------------------------+" -F DarkGray
    foreach($note in @($Notes | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })){
        Write-Host ("  • {0}" -f $note) -F DarkGray
    }
    Write-Host ""
}

function Invoke-OgdVendorComboPreset {
    param(
        [ValidateSet('AMD_AMD','INTEL_INTEL','AMD_NVIDIA','INTEL_NVIDIA')]
        [string]$Family,
        [ValidateSet('LIGHT','NORMALE','AGGRESSIVO')]
        [string]$Level
    )

    $cpuVendor = if($Family -like 'AMD_*'){'AMD'}else{'Intel'}
    $gpuVendor = switch($Family){
        'AMD_AMD'       { 'AMD' }
        'INTEL_INTEL'   { 'Intel' }
        default         { 'NVIDIA' }
    }

    Write-Host ""
    Write-Section ("PRESET COMBINATO {0} / {1} - {2}" -f $cpuVendor,$gpuVendor,$Level)

    $cpuPreset = switch($cpuVendor){
        'AMD' {
            switch($Level){
                'LIGHT'      { 'LIGHT' }
                'NORMALE'    { 'NORMALE' }
                'AGGRESSIVO' { 'ALTO' }
            }
        }
        default {
            switch($Level){
                'LIGHT'      { 'LIGHT' }
                'NORMALE'    { 'NORMALE' }
                'AGGRESSIVO' { 'ALTO' }
            }
        }
    }

    $gpuPreset = switch($gpuVendor){
        'AMD' {
            switch($Level){
                'LIGHT'      { 'LIGHT' }
                'NORMALE'    { 'NORMALE' }
                'AGGRESSIVO' { 'ULTRA' }
            }
        }
        default { $Level }
    }

    if($cpuVendor -eq 'AMD'){
        Set-OgdAmdCpuPreset -Preset $cpuPreset
    } else {
        Set-OgdIntelCpuPreset -Preset $cpuPreset
    }

    if($gpuVendor -eq 'AMD'){
        Set-OgdAmdGpuPreset -Preset $gpuPreset
    } elseif($gpuVendor -eq 'Intel'){
        Set-OgdIntelGpuPreset -Preset $gpuPreset
    } else {
        Set-OgdNvidiaGpuPresetSafe -Preset $gpuPreset
    }

    switch($Family){
        'AMD_AMD' {
            Show-OgdWhatThisDoes 'Rifinitura ufficiale consigliata dopo il preset' @(
                'AMD Software: usa HYPR-RX o Anti-Lag per i giochi supportati invece di chiavi driver non documentate',
                'se la piattaforma lo supporta, valuta SmartAccess Memory da BIOS/driver invece di tweak manuali nel registro',
                'lato CPU il preset resta Windows-side: nessun overclock e nessun tuning forzato fuori specifica'
            )
        }
        'INTEL_INTEL' {
            Show-OgdWhatThisDoes 'Rifinitura ufficiale consigliata dopo il preset' @(
                'Intel Graphics Software: usa Low Latency Mode per DX9/DX11 e Power Mode su Maximum Performance o Balanced secondo il gioco',
                'Intel APO puo aiutare solo sulle piattaforme supportate con DTT/IPF e BIOS aggiornato',
                'lato CPU il preset resta Windows-side: nessun overclock e nessun tool di tuning richiesto'
            )
        }
        'AMD_NVIDIA' {
            Show-OgdWhatThisDoes 'Rifinitura ufficiale consigliata dopo il preset' @(
                'su Ryzen il preset resta Windows-side: nessun overclock e nessun tuning forzato fuori specifica',
                'su GeForce usa Reflex quando presente; in assenza di Reflex puoi valutare Low Latency Mode da NVIDIA App / Pannello',
                'Resizable BAR dipende da GPU, VBIOS, CPU, motherboard e BIOS: lo script non forza impostazioni undocumented'
            )
        }
        'INTEL_NVIDIA' {
            Show-OgdWhatThisDoes 'Rifinitura ufficiale consigliata dopo il preset' @(
                'Intel APO puo aiutare solo sulle piattaforme supportate con DTT/IPF e BIOS aggiornato',
                'su GeForce usa Reflex quando presente; in assenza di Reflex puoi valutare Low Latency Mode da NVIDIA App / Pannello',
                'lato CPU il preset resta Windows-side: questo profilo punta a stabilita e reattivita, non a overclock'
            )
        }
    }
}

function Invoke-OgdVendorComboMenu {
    while($true){
        Show-OgdVendorComboMenu
        $familyChoice = Read-Host "  Scelta famiglia (1/2/3/4/0)"
        $family = switch($familyChoice){
            '1' { 'AMD_AMD' }
            '2' { 'INTEL_INTEL' }
            '3' { 'AMD_NVIDIA' }
            '4' { 'INTEL_NVIDIA' }
            '0' { return }
            default { '' }
        }

        if([string]::IsNullOrWhiteSpace($family)){
            Write-Warning 'Scelta non valida'
            Start-Sleep -Milliseconds 900
            continue
        }

        $title = switch($family){
            'AMD_AMD'     { 'AMD CPU + AMD GPU // RYZEN + RADEON' }
            'INTEL_INTEL' { 'INTEL CPU + INTEL GPU // CORE/ARC' }
            'AMD_NVIDIA'  { 'AMD CPU + NVIDIA GPU // RYZEN + GEFORCE' }
            'INTEL_NVIDIA'{ 'INTEL CPU + NVIDIA GPU // CORE + GEFORCE' }
        }
        $notes = switch($family){
            'AMD_AMD' {
                @(
                    'riferimento ufficiale: HYPR-RX, Anti-Lag e SmartAccess Memory lato AMD Software/BIOS',
                    'profilo CPU volutamente prudente: nessun overclock forzato dallo script'
                )
            }
            'INTEL_INTEL' {
                @(
                    'riferimento ufficiale: Intel Graphics Software per Low Latency e Power Mode',
                    'APO resta opzionale e solo se la piattaforma lo supporta davvero'
                )
            }
            default {
                @(
                    'lato CPU il preset resta Windows-side e prudente',
                    'lato GeForce i toggle ufficiali restano da fare in gioco o NVIDIA App / Pannello'
                )
            }
        }

        while($true){
            Show-OgdVendorComboLevelMenu -Title $title -Notes $notes
            $levelChoice = Read-Host "  Livello (1/2/3/0)"
            $level = switch($levelChoice){
                '1' { 'LIGHT' }
                '2' { 'NORMALE' }
                '3' { 'AGGRESSIVO' }
                '0' { '' }
                default { $null }
            }

            if($null -eq $level){
                Write-Warning 'Scelta non valida'
                Start-Sleep -Milliseconds 900
                continue
            }
            if([string]::IsNullOrWhiteSpace($level)){ break }

            Invoke-OgdVendorComboPreset -Family $family -Level $level
            Read-Host "  INVIO per continuare" | Out-Null
        }
    }
}

function Show-OgdAddonAppsHint {
    param([string]$Module)

    Write-Host ""
    Write-Host "  +--------------------------------------------------------------------+" -F DarkYellow
    Write-Host "  | SOFTWARE AGGIUNTIVO // EXTRA OPZIONALE                             |" -F Yellow
    Write-Host "  +--------------------------------------------------------------------+" -F DarkYellow

    switch($Module){
        'AMDGPU' {
            Write-Host "  | AMD Software: Adrenalin Edition                                    |" -F White
            Write-Host "  | Driver + tuning + overlay + update. Consigliato: SI               |" -F DarkGray
            Write-Host "  | AMD Cleanup Utility                                                |" -F White
            Write-Host "  | Pulizia driver in caso di problemi. Consigliato: solo se serve     |" -F DarkGray
        }
        'AMDCPU' {
            Write-Host "  | AMD Auto-Detect and Install                                        |" -F White
            Write-Host "  | Driver e verifica piattaforma AMD. Consigliato: SI                 |" -F DarkGray
            Write-Host "  | HWiNFO64                                                           |" -F White
            Write-Host "  | Sensori, temperature e verifica stabilita. Consigliato: SI         |" -F DarkGray
        }
        'INTELCPU' {
            Write-Host "  | Intel Application Optimization                                    |" -F White
            Write-Host "  | Thread scheduling per giochi supportati. Consigliato: se supportato|" -F DarkGray
            Write-Host "  | Intel Driver & Support Assistant                                   |" -F White
            Write-Host "  | Driver Intel e check piattaforma. Consigliato: SI                  |" -F DarkGray
        }
        'INTELGPU' {
            Write-Host "  | Intel Graphics Software                                            |" -F White
            Write-Host "  | Low Latency Mode, Power Mode e profili grafici. Consigliato: SI    |" -F DarkGray
            Write-Host "  | Intel Driver & Support Assistant                                   |" -F White
            Write-Host "  | Driver Intel e check piattaforma. Consigliato: SI                  |" -F DarkGray
        }
        'NVIDIA' {
            Write-Host "  | NVIDIA App                                                         |" -F White
            Write-Host "  | Driver, overlay, DLSS/Reflex settings. Consigliato: SI             |" -F DarkGray
            Write-Host "  | DDU / Display Driver Uninstaller                                   |" -F White
            Write-Host "  | Pulizia driver quando c'e instabilita. Consigliato: solo se serve  |" -F DarkGray
        }
        default {
            Write-Host "  | Nessun software extra specifico per questo modulo                  |" -F DarkGray
        }
    }

    Write-Host "  +--------------------------------------------------------------------+" -F DarkYellow
    Write-Host "  | Nota: nella 8.1.2 l'installazione resta opzionale e contestuale.   |" -F DarkGray
    Write-Host "  +--------------------------------------------------------------------+" -F DarkYellow
}

function Show-OgdHotfixMenu {
    param([string]$CpuName='')
    while($true){
        $dx = Get-OgdDx9LegacyStatus
        Clear-Host
        Write-Host "`n  ╔═══════════════════════════════════════════════════════╗" -F Cyan
Write-Host "  ║              8.1.2 HOTFIX & ACCESSIBILITÀ             ║" -F Cyan
        Write-Host "  ╚═══════════════════════════════════════════════════════╝`n" -F Cyan
        Write-Host ("  • DX9 legacy: {0}" -f $(if($dx.Healthy){'OK'}else{"mancano $($dx.MissingCount) componenti"})) -F White
        Write-Host ("  • DX9 legacy safe mode: {0}" -f $(if($dx.Dx9SafeMode){'ATTIVO'}else{'DISATTIVO'})) -F White
        Write-Host ''
        Show-OgdAppliedSummary 'HOTFIX'
        Write-MenuHint 'Usa questo menu se hai problemi specifici, non per una ottimizzazione generale.' @(
            'DX9 legacy per giochi vecchi che non partono o mostrano errori DLL',
            'OpenDyslexic per accessibilita e lettura piu confortevole',
            'NPU diagnostica se vuoi capire davvero se AI hardware e pronta o solo rilevata'
        )
        Write-Host '  [1] Stato DX9 legacy' -F Green
        Write-Host '      Controlla subito se mancano componenti DirectX 9 in System32/SysWOW64' -F DarkGray
        Write-Host '  [2] Apri riparazione ufficiale DirectX legacy (Microsoft)' -F Yellow
        Write-Host '      Apre la pagina corretta del runtime legacy, utile se [1] segnala file mancanti' -F DarkGray
        Write-Host '  [3] Attiva modalità compatibilità DX9 legacy' -F Cyan
        Write-Host '      Applica il preset safe per giochi o tool DX9 piu capricciosi' -F DarkGray
        Write-Host '  [4] Disattiva modalità compatibilità DX9 legacy' -F Cyan
        Write-Host '      Riporta il profilo DX9 allo stato normale se non ti serve piu' -F DarkGray
        Write-Host '  [5] Gestisci OpenDyslexic (installa/completa/disinstalla)' -F Magenta
        Write-Host '      Menu accessibilita: installa il font, rendilo predefinito o rimuovilo' -F DarkGray
        Write-Host '  [6] Diagnostica NPU avanzata' -F White
        Write-Host '      Spiega se la NPU e presente, pronta, parziale o solo integrata nella CPU' -F DarkGray
        Write-Host '  [7] Ripristina Opzioni di accesso / cambio password' -F Yellow
        Write-Host '      Riattiva servizi account/Windows Hello e pulisce eventuali blocchi di Settings' -F DarkGray
        Write-Host '  [8] Ripristina compatibilità app / .NET / launcher' -F Green
        Write-Host '      Riporta servizi e componenti utili a Store, installer, .NET Framework e app moderne' -F DarkGray
        Write-Host '  [9] Riabilita completamente Copilot' -F Green
        Write-Host '      Rimuove i blocchi policy; se l app manca apre Microsoft Store per reinstallarla' -F DarkGray
        Write-Host '  [A] Ripristina stack USB / mouse / tastiera' -F Yellow
        Write-Host '      Rimuove i tweak USB/HID piu aggressivi e forza un rescan dispositivi' -F DarkGray
        Write-Host '  [B] Fix anti-cheat / processi incompatibili gioco' -F Yellow
        Write-Host '      Cerca e chiude tool come IDA, debugger e utility bloccate da anti-cheat' -F DarkGray
        Write-Host '  [C] Windows Update Fixer' -F Cyan
        Write-Host '      Reset completo componenti Windows Update e nuova scansione aggiornata' -F DarkGray
        Write-Host '  [D] Xbox Reinstaller' -F Cyan
        Write-Host '      Ripristina Store/AppX e apre le pagine corrette per reinstallare Xbox e dipendenze' -F DarkGray
        Write-Host '  [0] Torna al menu`n' -F DarkGray
        $h = Read-Host '  Scelta (1/2/3/4/5/6/7/8/9/A/B/C/D/0)'
        switch($h){
            '1' {
                if($dx.Healthy){ Write-Success 'DX9 legacy: librerie principali presenti in System32/SysWOW64' }
                else {
                    Write-Warning 'DX9 legacy incompleto'
                    foreach($m in $dx.Missing){ Write-Host "    - $m" -F DarkGray }
                }
                Read-Host '  INVIO per continuare'
            }
            '2' {
                try{ Start-Process 'https://www.microsoft.com/en-us/download/details.aspx?id=35' }catch{}
                Write-Info 'Aperta la pagina Microsoft del DirectX End-User Runtime Web Installer'
                Read-Host '  INVIO per continuare'
            }
            '3' { Set-OgdDx9SafeMode -Enabled $true; Write-Success 'Modalità compatibilità DX9 attivata'; Read-Host '  INVIO per continuare' }
            '4' { Set-OgdDx9SafeMode -Enabled $false; Write-Success 'Modalità compatibilità DX9 disattivata'; Read-Host '  INVIO per continuare' }
            '5' { Show-OgdOpenDyslexicManager }
            '6' { Show-OgdNpuDiagnostics -CpuName $CpuName; Read-Host '  INVIO per continuare' }
            '7' { Restore-OgdSignInOptions }
            '8' { Restore-OgdAppRuntimeCompatibility }
            '9' { Restore-OgdCopilotFully; Read-Host '  INVIO per continuare' }
            'A' { Restore-OgdUsbInputDefaults | Out-Null; Read-Host '  INVIO per continuare' }
            'a' { Restore-OgdUsbInputDefaults | Out-Null; Read-Host '  INVIO per continuare' }
            'B' { Invoke-OgdAntiCheatConflictFix | Out-Null; Read-Host '  INVIO per continuare' }
            'b' { Invoke-OgdAntiCheatConflictFix | Out-Null; Read-Host '  INVIO per continuare' }
            'C' { Invoke-OgdWindowsUpdateFixer }
            'c' { Invoke-OgdWindowsUpdateFixer }
            'D' { Invoke-OgdXboxReinstaller }
            'd' { Invoke-OgdXboxReinstaller }
            '0' { return }
            default { Write-Warning 'Scelta non valida'; Start-Sleep 1 }
        }
    }
}

# ── Crea punto ripristino con timeout job (non blocca lo script) ─────────────
function New-OgdRestorePoint {
    param([string]$Description)
    try {
        Enable-ComputerRestore -Drive "C:\" -EA SilentlyContinue
        $rpJob = Start-Job -ScriptBlock {
            param($d)
            Checkpoint-Computer -Description $d -RestorePointType MODIFY_SETTINGS -EA SilentlyContinue
        } -ArgumentList $Description
        $rpDone = Wait-Job $rpJob -Timeout 30
        if($rpDone){ Receive-Job $rpJob -EA SilentlyContinue; Write-Host "  ✓ Punto ripristino: $Description" -F Green }
        else        { Stop-Job $rpJob; Write-Host "  ⚠ Punto ripristino: timeout (operazione continua)" -F Yellow }
        Remove-Job $rpJob -Force -EA SilentlyContinue
    } catch { Write-Host "  ⚠ Punto ripristino non creato" -F Yellow }
}

# ═════════════════════════════════════════════════════════════════════════════
#  FUNZIONE RILEVAMENTO NPU — robusta, con fallback CPU-based
# ═════════════════════════════════════════════════════════════════════════════
function Get-OgdNpuInfo {
    <#
    Rileva la NPU con più metodi senza affidarsi a un solo enum:
    1. Get-PnpDevice filtrato (veloce, evita scansioni complete inutili)
    2. Win32_PnPEntity / Win32_PnPSignedDriver per vedere classe, ID e driver
    3. Fallback CPU-based per Intel Core Ultra / Ryzen AI / Snapdragon X
    #>
    param([string]$CpuName = '')

    $result = [ordered]@{
        Found         = $false
        Present       = $false
        DriverReady   = $false
        Type          = 'generic'
        Source        = 'none'
        Name          = ''
        PNPDeviceID   = ''
        PNPClass      = ''
        DriverVersion = ''
        DriverDate    = ''
        ProblemCode   = ''
        Advice        = ''
    }

    $npuPattern = 'Intel(\(R\))? AI Boost|Intel AI Boost|Ryzen AI|Hexagon|AI Accelerator|Neural Processor|VPU|IPU|XDNA|NPU'
    $npuStrictClassPattern = 'Neural'
    $npuInvalidPattern = 'Error Aggregation Handler|EAH\b|Aggregation Handler|Crash|Telemetry|Bridge|Controller'
    $cpuCheck = if([string]::IsNullOrWhiteSpace($CpuName)){ (Get-CimInstance Win32_Processor -EA SilentlyContinue | Select-Object -First 1).Name } else { $CpuName }

    try{
        $devFast = Get-PnpDevice -Class 'System','ComputerHardwareIds','Processor','SoftwareComponent','SoftwareDevice' -EA SilentlyContinue |
            Where-Object {
                (
                    $_.FriendlyName -match $npuPattern -or
                    $_.Class -match $npuStrictClassPattern
                ) -and
                $_.FriendlyName -notmatch $npuInvalidPattern
            } |
            Sort-Object @{Expression={ if($_.Status -eq 'OK'){0}else{1} }}, FriendlyName

        if($devFast){
            $d = $devFast | Select-Object -First 1
            $result.Found       = $true
            $result.Present     = $true
            $result.DriverReady = ($d.Status -eq 'OK')
            $result.Source      = if($d.Status -eq 'OK'){'PnP-OK'}else{'PnP-NotOK'}
            $result.Name        = $d.FriendlyName
            $result.PNPDeviceID = $d.InstanceId
            $result.PNPClass    = $d.Class
        }
    }catch{}

    if(-not $result.Present){
        try{
            $ent = Get-CimInstance Win32_PnPEntity -EA SilentlyContinue |
                Where-Object {
                    (
                        $_.Name -match $npuPattern -or
                        $_.PNPClass -match $npuStrictClassPattern
                    ) -and
                    $_.Name -notmatch $npuInvalidPattern
                } |
                Sort-Object @{Expression={ if($_.ConfigManagerErrorCode -eq 0){0}else{1} }}, Name
            if($ent){
                $e = $ent | Select-Object -First 1
                $result.Found       = $true
                $result.Present     = $true
                $result.DriverReady = ($e.ConfigManagerErrorCode -eq 0)
                $result.Source      = if($e.ConfigManagerErrorCode -eq 0){'CIM-OK'}else{'CIM-Problem'}
                $result.Name        = $e.Name
                $result.PNPDeviceID = $e.DeviceID
                $result.PNPClass    = $e.PNPClass
                $result.ProblemCode = [string]$e.ConfigManagerErrorCode
            }
        }catch{}
    }

    try{
        $driverHit = Get-CimInstance Win32_PnPSignedDriver -EA SilentlyContinue |
            Where-Object {
                (
                    $_.DeviceName -match $npuPattern -or
                    $_.DeviceClass -match $npuStrictClassPattern
                ) -and
                $_.DeviceName -notmatch $npuInvalidPattern
            } |
            Select-Object -First 1
        if($driverHit){
            if(-not $result.Name){ $result.Name = $driverHit.DeviceName }
            if(-not $result.PNPDeviceID){ $result.PNPDeviceID = $driverHit.DeviceID }
            if(-not $result.PNPClass){ $result.PNPClass = $driverHit.DeviceClass }
            $result.DriverVersion = [string]$driverHit.DriverVersion
            $result.DriverDate    = [string]$driverHit.DriverDate
            if(-not $result.Source -or $result.Source -eq 'none'){
                $result.Source = 'DriverOnly'
            }
            $result.Found = $true
            $result.Present = $true
            if(-not $result.DriverReady){ $result.DriverReady = $true }
        }
    }catch{}

    if(-not $result.Found -and $cpuCheck -match 'Core Ultra [579]|Ultra [579]'){
        $gen = if($cpuCheck -match '2\d{2}[A-Z]{0,3}'){ 'Series 2 / Arrow Lake o simile' }
               elseif($cpuCheck -match '1\d{2}[A-Z]{0,3}'){ 'Series 1 / Meteor Lake o simile' }
               else { 'serie Ultra' }
        $result.Found       = $true
        $result.DriverReady = $false
        $result.Type        = 'intel'
        $result.Source      = 'CPU-Intel'
        $result.Name        = "Intel AI Boost NPU (integrata nella CPU - $gen)"
        $result.Advice      = 'La CPU include una NPU, ma Windows non la sta enumerando come device pronto: controlla Device Manager > Neural processors e aggiorna/reinstalla il driver Intel NPU.'
    }
    elseif(-not $result.Found -and ($cpuCheck -match 'Ryzen AI' -or $cpuCheck -match 'Ryzen 8[0-9]{3}0[GHUX]' -or $cpuCheck -match 'Ryzen [579] 9[0-9]{3}')){
        $result.Found       = $true
        $result.DriverReady = $false
        $result.Type        = 'amd'
        $result.Source      = 'CPU-AMD'
        $result.Name        = 'AMD Ryzen AI / XDNA NPU (integrata nella CPU)'
        $result.Advice      = 'La CPU sembra includere una NPU, ma il driver/device non risulta pronto.'
    }
    elseif(-not $result.Found -and $cpuCheck -match 'Snapdragon X'){
        $result.Found       = $true
        $result.DriverReady = $false
        $result.Type        = 'qualcomm'
        $result.Source      = 'CPU-Qualcomm'
        $result.Name        = 'Qualcomm Hexagon NPU (integrata nella CPU)'
        $result.Advice      = 'La CPU sembra includere una NPU, ma il driver/device non risulta pronto.'
    }

    $explicitNpuName = ($result.Name -match 'Intel(\(R\))? AI Boost|Intel AI Boost|Ryzen AI|Hexagon|AI Accelerator|Neural Processor|XDNA|NPU')
    $explicitNpuClass = ($result.PNPClass -match $npuStrictClassPattern)
    if($result.Present -and (
        $result.Name -match $npuInvalidPattern -or
        (($result.PNPClass -match '^System$') -and -not $explicitNpuName -and -not $explicitNpuClass)
    )){
        $result.Found = $false
        $result.Present = $false
        $result.DriverReady = $false
        $result.Source = 'none'
        $result.Name = ''
        $result.PNPDeviceID = ''
        $result.PNPClass = ''
        $result.DriverVersion = ''
        $result.DriverDate = ''
        $result.ProblemCode = ''
    }

    if($result.Name -match 'Intel|AI Boost' -or $result.Source -match 'Intel'){ $result.Type = 'intel' }
    elseif($result.Name -match 'Ryzen|AMD|XDNA' -or $result.Source -match 'AMD'){ $result.Type = 'amd' }
    elseif($result.Name -match 'Qualcomm|Hexagon|Snapdragon' -or $result.Source -match 'Qualcomm'){ $result.Type = 'qualcomm' }

    if($result.Present -and -not $result.DriverReady -and -not $result.Advice){
        $result.Advice = 'Il device NPU è visibile ma il driver non risulta pronto: aggiorna o reinstalla il driver prima di aspettarti rilevamento corretto nelle app.'
    }

    return [pscustomobject]$result
}

function Write-Error2([string]$M){Write-Host "  [ERR] $M" -F Red}

# ═════════════════════════════════════════════════════════════════════════════
#  HARDWARE DETECTION
# ═════════════════════════════════════════════════════════════════════════════

Show-Banner; Show-Steam
Write-Section "RILEVAMENTO SISTEMA"

$cpu=Get-CimInstance Win32_Processor
$ram=[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1)
$isLaptop=(Get-CimInstance Win32_SystemEnclosure).ChassisTypes -in @(8,9,10,11,14)

Write-Info "CPU: $($cpu.Name)"
Write-Info "Core: $($cpu.NumberOfCores) fisici / $($cpu.NumberOfLogicalProcessors) logici"
Write-Info "RAM: $ram GB | Build: $build | Tipo: $(if($isLaptop){'💻 Laptop'}else{'🖥️ Desktop'})"
Write-Info "Target scelto: Windows $($script:OgdTargetWindowsFamily) - $($script:OgdTargetWindowsRelease)"

# P+E cores
$isPE=$false;$pC=0;$eC=0
if($cpu.Name -match "i[579]-1[2-5]\d{3}"){
    $isPE=$true;$tC=$cpu.NumberOfCores
    if($cpu.Name -match "HX|HK"){$pC=[math]::Floor($tC*0.4)}else{$pC=[math]::Floor($tC/2)}
    $eC=$tC-$pC
    Write-Info "Architettura: HYBRID ⚡ ($pC P-cores + $eC E-cores)"
}else{Write-Info "Architettura: TRADIZIONALE";$pC=$cpu.NumberOfCores}

# NPU — rilevamento robusto con fallback CPU-based
$npuInfo = Get-OgdNpuInfo -CpuName $cpu.Name
$hasNPU  = $npuInfo.Found
$npuType = $npuInfo.Type
if($hasNPU){
    $src = if($npuInfo.DriverReady){'device/driver pronto'}elseif($npuInfo.Source -match 'CPU'){ 'integrata nella CPU ma driver/device non pronto' }else{'device presente ma non pronto'}
    Write-Info "NPU: ✓ $($npuInfo.Name) 🧠 ($src)"
    if($npuInfo.Advice){ Write-Warning $npuInfo.Advice }
}else{
    Write-Warning 'NPU: non rilevata (nessuna NPU individuata da CPU o driver)'
}

Show-OgdGraphicsDiagnostics -ExpectedGpuName ((Get-CimInstance Win32_VideoController -EA SilentlyContinue | Select-Object -First 1).Name)
Show-OgdSafetyStatus

if($script:OgdTargetIsWindows11 -and (Test-OgdWindows24H2OrLater)){
    Write-Host "  • Windows 11 24H2+ selezionato: il menu principale resta attivo e il ramo 24H2+ può essere richiamato separatamente." -F Cyan
} elseif($script:OgdTargetIsWindows10){
    Write-Host "  • Target Windows 10 selezionato: il menu principale resta attivo e il ramo Windows 10 può essere richiamato separatamente." -F Cyan
}
Write-Host "  • Il menu [J] resta disponibile come ponte legacy e rollback rapido." -F DarkGray

Write-Host ""
if($ram -lt 12){Write-Warning "RAM < 12GB - Ottimizzazioni aggressive";if((Read-Host "  Continuare? (S/N)") -notin @("S","s")){exit}}

# ═════════════════════════════════════════════════════════════════════════════
#  BACKUP AUTOMATICO
# ═════════════════════════════════════════════════════════════════════════════

Show-Banner
Write-Section "BACKUP E SICUREZZA"

# Punto ripristino
$desc="OGD WinCaffe NEXT v8.1.2 - $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
New-OgdRestorePoint -Description $desc

Write-Host "";Start-Sleep 1

# ═════════════════════════════════════════════════════════════════════════════
#  WINREVIVE FUNCTIONS - Riparazione Windows Integrata
# ═════════════════════════════════════════════════════════════════════════════

function WinRevive-ResetWU {
    Write-Info "Reset Windows Update..."
    $services = @("wuauserv","bits","cryptsvc","msiserver")
    foreach($s in $services){
        try{ Stop-Service $s -Force -EA SilentlyContinue; Write-Success "Service ${s}: Stopped" }
        catch{ Write-Warning "Service ${s}: Skip" }
    }
    $paths = @("C:\Windows\SoftwareDistribution\Download","C:\Windows\System32\catroot2")
    foreach($p in $paths){
        if(Test-Path $p){ Remove-Item "$p\*" -Recurse -Force -EA SilentlyContinue; Write-Success "Cleaned: $p" }
    }
    foreach($s in $services){
        try{ Start-Service $s -EA SilentlyContinue; Write-Success "Service ${s}: Started" }
        catch{ Write-Warning "Service ${s}: Skip" }
    }
}

function WinRevive-RepairImage {
    Write-Info "DISM + SFC riparazione..."
    Write-Host "  ⚠️ Operazione può richiedere 10-30 minuti`n" -F Yellow
    dism.exe /Online /Cleanup-Image /RestoreHealth | Out-Null
    Write-Success "DISM: Completato"
    sfc /scannow | Out-Null
    Write-Success "SFC: Completato"
}

function WinRevive-StoreReset {
    Write-Info "Reset Microsoft Store..."
    wsreset.exe | Out-Null
    Write-Success "Store: Reset completato"
}

function WinRevive-CleanBasic {
    Write-Info "Pulizia base sistema..."
    # Temp
    $temp = @($env:TEMP, [IO.Path]::GetTempPath(), "C:\Windows\Temp")
    foreach($t in $temp){
        if(Test-Path $t){ Get-ChildItem $t -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue }
    }
    # Delivery Optimization
    $do = "C:\ProgramData\Microsoft\Windows\DeliveryOptimization\Cache"
    if(Test-Path $do){ Get-ChildItem $do -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue }
    # SoftwareDistribution
    $sd = "C:\Windows\SoftwareDistribution\Download"
    if(Test-Path $sd){ Get-ChildItem $sd -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue }
    # Recycle Bin
    try{ Clear-RecycleBin -Force -EA SilentlyContinue }catch{}
    Write-Success "Pulizia base: Completata"
}

function WinRevive-CleanAdvanced {
    WinRevive-CleanBasic
    Write-Info "DISM ComponentCleanup /ResetBase..."
    dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null
    # Browser cache
    $edge = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
    $chrome = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
    if(Test-Path $edge){ Get-ChildItem $edge -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue }
    if(Test-Path $chrome){ Get-ChildItem $chrome -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue }
    Write-Success "Pulizia avanzata: Completata"
}

function WinRevive-DisableRecall {
    Write-Info "Disabilita Recall (Windows 11)..."
    try{
        dism.exe /Online /Disable-Feature /Featurename:Recall /NoRestart | Out-Null
        Write-Success "Recall: Disabilitato"
    }catch{
        Write-Warning "Recall: Feature non trovata o già disabilitata"
    }
}



# ═════════════════════════════════════════════════════════════════════════════
#  MENU PRINCIPALE
# ═════════════════════════════════════════════════════════════════════════════

:MenuLoop
while($true){
Show-Banner
Write-Section (("MENU OTTIMIZZAZIONI  |  Target: {0}  |  PC: {1}" -f (Get-OgdTargetLabel), $(if($script:OgdPcType){$script:OgdPcType}else{"N/D"})))

$targetHintFour = if($script:OgdTargetIsWindows10){
    'Se sei su Windows 10: usa [Y] per il ramo dedicato, separato dai tweak moderni di Windows 11'
} elseif($script:OgdTargetIs25H2OrLater){
    'Se sei su Windows 11 25H2+: usa [B] per il preset compatibilita dedicato e [Y] per il ramo moderno'
} elseif($script:OgdTargetIs24H2OrLater){
    'Se sei su Windows 11 24H2: usa [Y] per il ramo moderno dedicato; [B] non e il percorso principale'
} else {
    'Se sei su Windows 11 pre-24H2: resta sui profili base e usa [Y] solo per i controlli mirati compatibili'
}
Write-MenuHint 'Come orientarti in 10 secondi' @(
    'Se vuoi il profilo consigliato per quasi tutti i desktop: scegli [2] NORMALE',
    'Se sei su laptop: usa [4] o [5] per i livelli guidati dedicati a termica e batteria',
    'Se vuoi solo capire cosa cambia prima di applicare tweak: apri [8] INFO',
    $targetHintFour,
    'Se hai un problema specifico e non vuoi toccare tutto: entra in [H] HOTFIX o negli strumenti dedicati'
)

Write-Host "  Legenda impatto: SAFE = modifiche leggere | MEDIO = profilo bilanciato | ALTO = piu prestazioni ma piu invasivo`n" -F DarkGray

Write-Host "`n  ┌─────────────────────────────────────────────────────────┐" -F Cyan
Write-Host "  │ ⚡ LIVELLI DI OTTIMIZZAZIONE GUIDATI                   │" -F Cyan
Write-Host "  └─────────────────────────────────────────────────────────┘`n" -F Cyan

Write-Host "  [1] LIGHT - Ottimizzazioni base (safe al 100%)" -F White
      Write-Host "      Shell/UI, rete, Explorer e login più snello senza toccare memoria profonda" -F DarkGray
Write-Host "      Consigliato: Tutti | Impatto: SAFE | Risultato: sistema piu reattivo e pulito`n" -F DarkGray

Write-Host "  [2] NORMALE - Completo per gaming/lavoro (raccomandato)" -F White
Write-Host "      Light + priorità processi/core apps + NPU + debloat + login/logout più pronti" -F DarkGray
Write-Host "      Consigliato: Gaming PC/Desktop generale | Impatto: MEDIO | Risultato: miglior equilibrio prestazioni/compatibilita`n" -F DarkGray

Write-Host "  [3] AGGRESSIVO - Massima performance (piu invasivo)" -F White
Write-Host "      Normale + memoria/storage + svchost split + boot/shutdown/reboot più rapidi" -F DarkGray
Write-Host "      Consigliato: Enthusiast/Desktop potente | Impatto: ALTO | Risultato: latenza e overhead ridotti, ma piu rischio side effect`n" -F DarkGray

Write-Host "  [A] AGGRESSIVO GAMING - Sub-menu livelli gaming (Light/Normale/Full)" -F Magenta
Write-Host "      Percorso gaming dedicato: utile se vuoi una scelta guidata solo per il gioco`n" -F DarkGray

Write-Host "  [4] LAPTOP - Ottimizzazione laptop (sub-menu livelli)" -F White
Write-Host "      Light/Normale/Alto/Ultra — bilanciato batteria/performance" -F DarkGray
      Write-Host "      Consigliato: Laptop | Sicuro per batteria e termica`n" -F DarkGray

Write-Host "  [5] LAPTOP GAMING - Laptop da gaming (sub-menu livelli)" -F White
Write-Host "      Light/Normale/Alto/Ultra — gaming laptop ottimizzato" -F DarkGray
Write-Host "      Consigliato: Gaming laptop | In carica per Ultra`n" -F DarkGray

Write-Host "  ┌─────────────────────────────────────────────────────────┐" -F Cyan
Write-Host "  │ 🔧 STRUMENTI AGGIUNTIVI                                │" -F Cyan
Write-Host "  └─────────────────────────────────────────────────────────┘`n" -F Cyan

Write-Host "  [7] EXPLORER - Solo cache folder views" -F White
Write-Host "  [8] INFO - Cosa fa ogni livello" -F White
Write-Host "  [9] RESET - Punto ripristino Windows`n" -F White
Write-Host "  [F] FILE I/O - Velocizza trasferimenti/installazioni`n" -F White
Write-Host "  [U] WINGET UPDATE - Aggiorna programmi installati`n" -F White

Write-Host "  [W] WINREVIVE - Riparazione Windows" -F Cyan
Write-Host "  [J] FIX PRE 8.1.1 - Ponte legacy e rollback rapido" -F Cyan
Write-Host "  [O] PLATFORM PRESETS - Preset combinati CPU + GPU per vendor" -F White
Write-Host "  [G] NVIDIA TWEAKS - Ottimizzazione GPU NVIDIA + extra software" -F Green
Write-Host "  [R] AMD GPU TWEAKS - Ottimizzazione GPU Radeon + extra software" -F Red
Write-Host "  [X] AMD CPU TWEAKS - Profili CPU Ryzen / X3D + tool utili" -F Magenta
Write-Host "  [I] INTEL CPU TWEAKS - Profili Intel Core / Core Ultra + tool utili" -F Cyan
Write-Host "  [V] INTEL GPU TWEAKS - Profili Intel Graphics / Arc + extra software" -F Blue
Write-Host "  [L] DPC LATENCY FIX - Risolvi lag/stuttering audio e sistema" -F Yellow
Write-Host "  [P] NPU TWEAKS - Ottimizzazione Neural Processing Unit" -F Cyan
Write-Host "  [E] UNREAL ENGINE - Ottimizzazioni UE4/UE5 (dev + gaming)" -F Yellow
Write-Host "  [C] CALL OF DUTY - Tweaks MW1->Black Ops 7 (safe, no ban)" -F Red
Write-Host "  [M] MOUSE - Accelerazione ON/OFF + precisione massima" -F White
Write-Host "  [D] DISCORD - Unisciti alla community OGD" -F Magenta
Write-Host ("  {0} - Preset compatibilita dedicato al target Insider/25H2" -f (Get-OgdAdaptiveBetaLabel)) -F Magenta
Write-Host "  [Q] BENCHMARK PC - Analisi hardware e personalizzazione tweaks" -F Yellow
Write-Host "  [T] MICRO TWEAKS - Svchost split + folder thumbs + core parking" -F Cyan
Write-Host "  [K] SSD & NVME SUPER TWEAKS - Safe storage boost per SSD e NVMe" -F Green
Write-Host ("  {0} - ramo Windows coerente con il target rilevato" -f (Get-OgdAdaptiveWindowsMenuLabel)) -F White
Write-Host ("  {0} - compatibilita dedicata per build Insider/25H2" -f (Get-OgdAdaptiveBetaLabel)) -F Magenta
Write-Host "  [H] HOTFIX 8.1.2 - DX9 legacy + OpenDyslexic + NPU diag" -F Cyan
Write-Host "  [0] ESCI - Chiudi script`n" -F Red

$mode = if(-not $script:OgdWizardMenuChoiceConsumed -and -not [string]::IsNullOrWhiteSpace($WizardMenuChoice)){
    $script:OgdWizardMenuChoiceConsumed = $true
    Write-Host ("  > Wizard GUI: avvio automatico menu [{0}]" -f $WizardMenuChoice.ToUpper()) -F DarkGray
    $WizardMenuChoice.ToUpper()
} else {
    Read-Host "  Scelta (1-9/A/B/F/U/W/O/G/R/X/I/V/L/P/E/C/M/D/H/J/Q/T/K/Y/Z/0)"
}


if($mode -in @('H','h')){
    Show-OgdHotfixMenu -CpuName $cpu.Name
    continue MenuLoop
}

if($mode -in @('Z','z')){
    Select-OgdPcType
    continue MenuLoop
}

if($mode -in @('Y','y')){
    if($script:OgdTargetIsWindows10){
        Show-OgdWin10Menu
    } else {
        Show-OgdWindows11ExtraLiteMenu
    }
    continue MenuLoop
}

if($mode -eq "I" -or $mode -eq "i"){
    Invoke-OgdIntelCpuMenu
    continue MenuLoop
}

if($mode -eq "V" -or $mode -eq "v"){
    Invoke-OgdIntelGpuMenu
    continue MenuLoop
}

if($mode -eq "O" -or $mode -eq "o"){
    Invoke-OgdVendorComboMenu
    continue MenuLoop
}

if($mode -in @('B','b') -and -not $script:OgdTargetIs25H2OrLater){
    Write-Host "" 
    if($script:OgdTargetIsWindows10){
        Write-Warning "Il preset BETA e pensato per Windows 11 25H2+ o Insider: sul tuo target usa [Y] WINDOWS 10."
    } elseif($script:OgdTargetIs24H2OrLater){
        Write-Warning "Il preset BETA e pensato per Windows 11 25H2+ o Insider: sul tuo target usa [Y] WIN11 24H2+."
    } else {
        Write-Warning "Il preset BETA e pensato per Windows 11 25H2+ o Insider: sul tuo target resta meglio sui profili normali o sugli hotfix."
    }
    Read-Host "  INVIO per continuare" | Out-Null
    continue MenuLoop
}

if($mode -eq "R" -or $mode -eq "r"){
    Invoke-OgdAmdGpuMenu
    continue MenuLoop
}

if($mode -eq "X" -or $mode -eq "x"){
    Invoke-OgdAmdCpuMenu
    continue MenuLoop
}

if($mode -in @('J','j')){
    Show-OgdPre8012FixMenu
    continue MenuLoop
}

# Gestione opzione 0 (Esci)
if($mode -eq "0"){
    Write-Host "`n  Uscita script..." -F Yellow
    exit
}

# ── SOTTO-MENU LIVELLO AGGRESSIVO (modalità 3) ───────────────────────────────
$aggrCpuType = ""
if($mode -eq "3"){
    Show-Banner
    Write-Section "AGGRESSIVO — SCEGLI PROFILO CPU"

    Write-Host "`n  Scegli la variante in base alla tua CPU:`n" -F Cyan

    Write-Host "  [I] INTEL / GENERALE - Profilo forte ma termicamente piu prudente" -F White
    Write-Host "      Scheduler e MMCSS piu spinti, senza unparking totale continuo o boost brutale." -F DarkGray
    Write-Host "      Consigliato: CPU Intel / desktop potenti, anche nei mesi caldi`n" -F DarkGray

    Write-Host "  [A] AMD - Variante specifica per Ryzen / X3D" -F Red
    Write-Host "      Disabilita l'unparking forzato e il boost estremo per prevenire" -F DarkGray
    Write-Host "      problemi di surriscaldamento estivo sui processori AMD." -F DarkGray
    Write-Host "      Consigliato: CPU AMD`n" -F DarkGray
    Write-Host "  [P] FIX PRE 8.0.11 - Ripristino per vecchio Aggressivo instabile`n" -F Yellow

    $act3 = Read-Host "  Scelta (I/A/P)"
    if($act3 -in @("P","p")){
        Show-OgdPre8011AggressiveFixMenu -PresetLabel 'AGGRESSIVO'
        continue MenuLoop
    }
    if($act3 -in @("A","a")){
        $aggrCpuType = "A"
    } else {
        $aggrCpuType = "I"
    }
}


# ── SOTTO-MENU LIVELLO AGGRESSIVO GAMING (modalità A) ────────────────────────
$aggrGamingLevel = ""
if($mode -in @("A","a")){
    Show-Banner
    Write-Section "AGGRESSIVO GAMING — SCEGLI LIVELLO"

    Write-Host "`n  Scegli il livello in base alla potenza del tuo PC:`n" -F Cyan

    Write-Host "  [L] LIGHT GAMING - Gaming base, safe su qualsiasi PC" -F Green
    Write-Host "      Game Mode ON, DVR OFF, Timer, Process priority gaming" -F DarkGray
    Write-Host "      Consigliato: tutti | PC entry-level e mid-range`n" -F DarkGray

    Write-Host "  [N] NORMALE GAMING - Gaming completo (raccomandato)" -F Yellow
    Write-Host "      Light + MMCSS gaming, Power max, CPU boost, Fullscreen ottimizzato" -F DarkGray
    Write-Host "      Consigliato: gaming PC | Da 8GB RAM in su`n" -F DarkGray

    Write-Host "  [F] FULL GAMING - Massimo assoluto (solo PC potenti)" -F Magenta
        Write-Host "      Normale + scheduler, MMCSS, storage e servizi secondari in modalita piu spinta" -F DarkGray
        Write-Host "      Nessun overclock, niente HPET tweak e niente RAM tuning sperimentale" -F DarkGray
        Write-Host "      Consigliato: PC alta potenza | 16GB+ RAM | Solo desktop ben stabile`n" -F DarkGray
    Write-Host "  [P] FIX PRE 8.0.11 - Ripristino per vecchi preset Full Gaming" -F Yellow
    Write-Host "  [R] ROLLBACK DEFAULT - Riporta il sistema ai default Windows`n" -F White

    $agl = Read-Host "  Livello (L/N/F/P/R)"
    if($agl -in @("P","p")){
        Show-OgdPre8011AggressiveFixMenu -PresetLabel 'AGGRESSIVO GAMING'
        continue MenuLoop
    }
    if($agl -in @("R","r")){
        Invoke-OgdFullRollbackToDefault -ProfileLabel 'AGGRESSIVO GAMING' | Out-Null
        Read-Host "  INVIO per continuare" | Out-Null
        continue MenuLoop
    }
    if($agl -notin @("L","l","N","n","F","f")){
        Write-Host "  Scelta non valida" -F Red; Start-Sleep 1; continue MenuLoop
    }
    $aggrGamingLevel = $agl.ToUpper()
}

# ── SOTTO-MENU LIVELLO LAPTOP (modalità 4 e 5) ───────────────────────────────
$laptopLevel = ""
$isGamingLaptop = ($mode -eq "5")

if($mode -in @("4","5")){
    $ltTitle = if($isGamingLaptop){"LAPTOP GAMING"}else{"LAPTOP"}
    Show-Banner
    Write-Section "LIVELLO OTTIMIZZAZIONE $ltTitle"

    Write-Host "`n  Scegli il livello di ottimizzazione:`n" -F Cyan

    Write-Host "  [L] LIGHT - Base sicuro, batteria preservata" -F Green
    Write-Host "      Timer + Privacy + GPU (rete lasciata invariata)" -F DarkGray
    Write-Host "      Impatto batteria: Minimo | Performance: +5%`n" -F DarkGray

    Write-Host "  [N] NORMALE - Bilanciato performance/batteria" -F Yellow
    Write-Host "      Light + Process priority + Debloat + Visual" -F DarkGray
    Write-Host "      Impatto batteria: Leggero | Performance: +10%`n" -F DarkGray

    Write-Host "  [A] ALTO - Performance elevata (consigliato in carica)" -F Red
        Write-Host "      Normale + High Perf plan + MMCSS + scheduler prudente per laptop" -F DarkGray
    Write-Host "      Impatto batteria: Medio | Performance: +15%`n" -F DarkGray

    Write-Host "  [U] ULTRA - Massima performance (solo in carica)" -F Magenta
    Write-Host "      Alto + CPU Boost + Memory + C-states ridotti" -F DarkGray
    if($isGamingLaptop){
        Write-Host "      + USB suspend OFF + Game Mode + priorita gaming in carica" -F DarkGray
    }
      Write-Host "      Riduce autonomia batteria - usa solo in carica`n" -F Yellow
    Write-Host "  [R] ROLLBACK DEFAULT - Riporta il sistema ai default Windows`n" -F White

    $ll = Read-Host "  Livello (L/N/A/U/R)"
    if($ll -in @("R","r")){
        Invoke-OgdFullRollbackToDefault -ProfileLabel $ltTitle | Out-Null
        Read-Host "  INVIO per continuare" | Out-Null
        continue MenuLoop
    }
    if($ll -notin @("L","l","N","n","A","a","U","u")){
        Write-Host "  Scelta non valida" -F Red; Start-Sleep 1; continue MenuLoop
    }
    $laptopLevel = $ll.ToUpper()
}

# Gestione opzione W (WinRevive)
if($mode -in @("W","w")){
    Show-Banner
    Write-Section "WINREVIVE - RIPARAZIONE WINDOWS"
    
    Write-Host "`n  ┌─────────────────────────────────────────────────────────┐" -F Cyan
    Write-Host "  │ 🔧 RIPARAZIONE E PULIZIA SISTEMA                       │" -F Cyan
    Write-Host "  └─────────────────────────────────────────────────────────┘`n" -F Cyan
    
    Write-Host "  [1] RESET WINDOWS UPDATE - Fix errori aggiornamenti" -F Green
    Write-Host "  [2] REPAIR IMAGE - DISM + SFC (10-30 min)" -F Yellow
    Write-Host "  [3] STORE RESET - Reset Microsoft Store" -F Cyan
    Write-Host "  [4] CLEAN BASIC - Pulizia temp/cache base" -F White
    Write-Host "  [5] CLEAN ADVANCED - Pulizia aggressiva DISM" -F Red
    Write-Host "  [6] DISABLE RECALL - Disabilita Recall (Win11)" -F Yellow
    Write-Host "  [A] ALL - Esegui tutto (1+2+3+4)" -F Green
    Write-Host "  [0] SALTA - Torna ai tweaks`n" -F White
    
    $revive=Read-Host "  Scelta"
    
    if($revive -ne "0"){
        Write-Host ""
        # Punto ripristino
        # Punto ripristino
        $desc="OGD WinRevive - $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
        New-OgdRestorePoint -Description $desc
        
        Write-Host ""
        
        switch($revive){
            "1"{ WinRevive-ResetWU }
            "2"{ WinRevive-RepairImage }
            "3"{ WinRevive-StoreReset }
            "4"{ WinRevive-CleanBasic }
            "5"{ WinRevive-CleanAdvanced }
            "6"{ WinRevive-DisableRecall }
            {$_ -in @("A","a")}{
                WinRevive-ResetWU
                WinRevive-RepairImage
                WinRevive-StoreReset
                WinRevive-CleanBasic
                Write-Host "`n  ════════════════════════════════════════════════════" -F Green
                Write-Host "   ✓ RIPARAZIONE COMPLETA!" -F Green
                Write-Host "  ════════════════════════════════════════════════════`n" -F Green
            }
        }
        
        if($revive -ne "A" -and $revive -ne "a"){
            Write-Host "`n  ════════════════════════════════════════════════════" -F Green
            Write-Host "   ✓ WINREVIVE COMPLETATO!" -F Green
            Write-Host "  ════════════════════════════════════════════════════`n" -F Green
        }
        
        if((Read-Host "  Riavvio consigliato. Riavviare ora? (S/N)") -in @("S","s")){
            Restart-Computer -Force
        }
    }
    
    continue MenuLoop
}

# ═════════════════════════════════════════════════════════════════════════════
#  MENU PROTEZIONE PRIVACY (4 livelli)
# ═════════════════════════════════════════════════════════════════════════════

$privacyLevel="0"
if($mode -in @("1","2","3","A","a","4","5","B","b")){
    Show-Banner
    Write-Section "PROTEZIONE PRIVACY"
    
    Write-Host "`n  🔒 Vuoi applicare protezioni privacy aggiuntive?`n" -F Cyan
    Write-Host "  [1] 🟢 LIGHT - Privacy base" -F Green
    Write-Host "      • Telemetry Microsoft OFF" -F DarkGray
    Write-Host "      • Cortana disabilitata" -F DarkGray
    Write-Host "      • Suggerimenti/pubblicità OFF`n" -F DarkGray
    
    Write-Host "  [2] 🟡 NORMALE - Privacy avanzata" -F Yellow
    Write-Host "      • Light +" -F DarkGray
    Write-Host "      • OneDrive disabilitato" -F DarkGray
    Write-Host "      • Servizi cloud/diagnostica OFF" -F DarkGray
    Write-Host "      • Location/camera/microfono OFF`n" -F DarkGray
    
    Write-Host "  [3] 🔴 AGGRESSIVO - Privacy massima" -F Red
    Write-Host "      • Normale +" -F DarkGray
    Write-Host "      • NVIDIA/Adobe/VS telemetry OFF" -F DarkGray
        Write-Host "      • Feedback/diagnostica completa OFF" -F DarkGray
        Write-Host "      • Task diagnostici non essenziali ridotti`n" -F DarkGray
    
    Write-Host "  [4] ⚫ PARANOICO - Privacy estrema" -F Magenta
    Write-Host "      • Aggressivo +" -F DarkGray
    Write-Host "      • Windows Update solo manuale" -F DarkGray
    Write-Host "      • Defender ridotto (solo scan manuale)" -F DarkGray
    Write-Host "      • Tutti i servizi telemetry disabled" -F DarkGray
    Write-Host "      • ⚠️ Può limitare funzionalità Windows`n" -F Yellow
    
    Write-Host "  [0] ⏭️  SALTA - Nessuna protezione extra`n" -F White
    
    $privacyLevel=Read-Host "  Scelta (0-4)"
}

# ═════════════════════════════════════════════════════════════════════════════
#  BENCHMARK & PERSONALIZZAZIONE TWEAKS
# ═════════════════════════════════════════════════════════════════════════════

function Get-OgdBenchmarkDataRoot {
    $root = Join-Path $env:ProgramData 'OGD\Benchmark'
    if(-not (Test-Path $root)){ New-Item -Path $root -ItemType Directory -Force -EA SilentlyContinue | Out-Null }
    return $root
}

function Get-OgdBenchmarkProfilePath {
    return (Join-Path (Get-OgdBenchmarkDataRoot) 'last-benchmark.json')
}

function Save-OgdBenchmarkProfile {
    param([psobject]$Profile)
    $Profile | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Get-OgdBenchmarkProfilePath) -Encoding UTF8
}

function Get-OgdBenchmarkProfile {
    $path = Get-OgdBenchmarkProfilePath
    if(Test-Path $path){
        try{ return (Get-Content -Raw $path | ConvertFrom-Json) }catch{}
    }
    return $null
}

function Get-OgdSystemTier {
    param([double]$CpuScore,[double]$DiskScore,[int]$RamGB,[int]$Threads)
    $mix = ($CpuScore * 0.4) + ($DiskScore * 0.35) + (($RamGB * 8) * 0.15) + ($Threads * 1.5 * 0.10)
    if($mix -ge 120){ return 'ENTHUSIAST' }
    if($mix -ge 80){ return 'HIGH' }
    if($mix -ge 45){ return 'MID' }
    return 'LOW'
}

function Invoke-OgdQuickCpuBenchmark {
    $count = 250000
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $sum = 0.0
    for($i=1; $i -le $count; $i++){
        $sum += [math]::Sqrt($i)
    }
    $sw.Stop()
    $score = [math]::Round(($count / [math]::Max(1,$sw.Elapsed.TotalMilliseconds)) * 10,2)
    return [pscustomobject]@{ ElapsedMs=[math]::Round($sw.Elapsed.TotalMilliseconds,2); Score=$score; Guard=$sum }
}

function Invoke-OgdQuickDiskBenchmark {
    $tmp = Join-Path $env:TEMP 'ogd_bench_disk.tmp'
    $sizeMb = 96
    $buffer = New-Object byte[] (1MB)
    [System.Random]::new().NextBytes($buffer)
    try{
        $write = [System.Diagnostics.Stopwatch]::StartNew()
        $fs = [System.IO.File]::Open($tmp,[System.IO.FileMode]::Create,[System.IO.FileAccess]::Write,[System.IO.FileShare]::None)
        for($i=0;$i -lt $sizeMb;$i++){ $fs.Write($buffer,0,$buffer.Length) }
        $fs.Flush()
        $fs.Dispose()
        $write.Stop()

        $read = [System.Diagnostics.Stopwatch]::StartNew()
        $fsr = [System.IO.File]::OpenRead($tmp)
        $readBuffer = New-Object byte[] (1MB)
        while(($bytes = $fsr.Read($readBuffer,0,$readBuffer.Length)) -gt 0){ $null = $bytes }
        $fsr.Dispose()
        $read.Stop()
    } finally {
        try{ Remove-Item $tmp -Force -EA SilentlyContinue }catch{}
    }

    $writeMb = [math]::Round(($sizeMb / [math]::Max(0.01,$write.Elapsed.TotalSeconds)),2)
    $readMb  = [math]::Round(($sizeMb / [math]::Max(0.01,$read.Elapsed.TotalSeconds)),2)
    $score   = [math]::Round((($writeMb * 0.45) + ($readMb * 0.55)) / 10,2)
    return [pscustomobject]@{ WriteMBs=$writeMb; ReadMBs=$readMb; Score=$score }
}

function Invoke-OgdQuickMemoryBenchmark {
    $sizeMb = 128
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $a = New-Object byte[] ($sizeMb * 1MB)
    $b = New-Object byte[] ($sizeMb * 1MB)
    [System.Buffer]::BlockCopy($a,0,$b,0,$a.Length)
    $sw.Stop()
    $mbs = [math]::Round(($sizeMb / [math]::Max(0.01,$sw.Elapsed.TotalSeconds)),2)
    return [pscustomobject]@{ CopyMBs=$mbs; Score=[math]::Round(($mbs / 250),2) }
}

function Invoke-OgdSystemBenchmark {
    Write-Info 'Benchmark sistema in corso (CPU / RAM / Disco)...'
    $cpuInfo = Get-CimInstance Win32_Processor -EA SilentlyContinue | Select-Object -First 1
    $sysInfo = Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue
    $ramGB = [math]::Max(4,[math]::Round(($sysInfo.TotalPhysicalMemory / 1GB)))
    $threads = [int]$cpuInfo.NumberOfLogicalProcessors
    $cpu = Invoke-OgdQuickCpuBenchmark
    $disk = Invoke-OgdQuickDiskBenchmark
    $mem = Invoke-OgdQuickMemoryBenchmark
    $tier = Get-OgdSystemTier -CpuScore $cpu.Score -DiskScore $disk.Score -RamGB $ramGB -Threads $threads
    $profile = [pscustomobject]@{
        Timestamp   = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Computer    = $env:COMPUTERNAME
        CpuName     = $cpuInfo.Name
        Threads     = $threads
        RamGB       = $ramGB
        CpuScore    = $cpu.Score
        DiskScore   = $disk.Score
        MemoryScore = $mem.Score
        DiskReadMBs = $disk.ReadMBs
        DiskWriteMBs= $disk.WriteMBs
        MemoryCopyMBs = $mem.CopyMBs
        Tier        = $tier
    }
    Save-OgdBenchmarkProfile -Profile $profile
    return $profile
}

function Show-OgdBenchmarkResult {
    param([psobject]$Bench)
    Write-Host ''
    Write-Host '  ┌─────────────────────────────────────────────────────────┐' -F Cyan
    Write-Host '  │         BENCHMARK PC / PERSONALIZZAZIONE TWEAKS        │' -F Cyan
    Write-Host '  └─────────────────────────────────────────────────────────┘' -F Cyan
    Write-Host ("  CPU       : {0}" -f $Bench.CpuName) -F White
    Write-Host ("  Threads   : {0}" -f $Bench.Threads) -F White
    Write-Host ("  RAM       : {0} GB" -f $Bench.RamGB) -F White
    Write-Host ("  CPU score : {0}" -f $Bench.CpuScore) -F White
    Write-Host ("  Disk      : R {0} MB/s | W {1} MB/s | score {2}" -f $Bench.DiskReadMBs,$Bench.DiskWriteMBs,$Bench.DiskScore) -F White
    Write-Host ("  Memory    : {0} MB/s | score {1}" -f $Bench.MemoryCopyMBs,$Bench.MemoryScore) -F White
    Write-Success ("  Tier rilevato: {0}" -f $Bench.Tier)
    Write-Host ''
    switch($Bench.Tier){
        'LOW'       { Write-Host '  Suggerimento: privilegia Light / Laptop Light e tweak visuali/storage prudenti.' -F Yellow }
        'MID'       { Write-Host '  Suggerimento: il PC regge bene Normale e gaming light/normal.' -F Yellow }
        'HIGH'      { Write-Host '  Suggerimento: ottimo per Normale/Aggressivo e storage tuning completo.' -F Yellow }
        'ENTHUSIAST'{ Write-Host '  Suggerimento: macchina molto forte, puo sfruttare quasi tutto il ramo high-end.' -F Yellow }
    }
}

function Invoke-OgdBenchmarkAdaptiveTweaks {
    param([psobject]$Benchmark,[int]$RamGB)
    if(-not $Benchmark){ return }
    Write-Info ("[P] Personalizzazione benchmark-based: tier {0}..." -f $Benchmark.Tier)
    switch($Benchmark.Tier){
        'LOW' {
            Set-OgdFolderThumbnailMode
            Set-OgdSvcHostSplitThreshold -RamGB ([math]::Min($RamGB,16))
            try{
                $pp='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'
                if(!(Test-Path $pp)){ New-Item $pp -Force -EA SilentlyContinue | Out-Null }
                Set-ItemProperty $pp -Name 'EnableSuperfetch' -Value 3 -Type DWord -Force -EA SilentlyContinue
                Set-ItemProperty $pp -Name 'EnablePrefetcher' -Value 3 -Type DWord -Force -EA SilentlyContinue
            }catch{}
            Write-Success 'Personalizzazione LOW applicata: priorita a fluidita UI e caching prudente'
        }
        'MID' {
            Set-OgdSvcHostSplitThreshold -RamGB $RamGB
            Set-OgdFolderThumbnailMode
            Write-Success 'Personalizzazione MID applicata: profilo bilanciato'
        }
        default {
            Set-OgdSvcHostSplitThreshold -RamGB $RamGB
            Set-OgdFolderThumbnailMode
            Set-OgdCoreParkingMode
            Write-Success 'Personalizzazione HIGH applicata: reattivita massima in modo safe'
        }
    }
    $global:opts++
}

function Show-OgdBenchmarkMenu {
    while($true){
        Clear-Host
        Write-Host "`n  ╔═══════════════════════════════════════════════════════╗" -F Cyan
        Write-Host "  ║         BENCHMARK PC & PERSONALIZZAZIONE 8.1.2       ║" -F Cyan
        Write-Host "  ╚═══════════════════════════════════════════════════════╝`n" -F Cyan
        Write-Host '  [1] Esegui benchmark completo del PC' -F Green
        Write-Host '  [2] Mostra ultimo benchmark salvato' -F Yellow
        Write-Host '  [3] Spiega come il benchmark personalizza i tweaks' -F Cyan
        Write-Host '  [0] Torna indietro`n' -F DarkGray
        $choice = Read-Host '  Scelta (1/2/3/0)'
        switch($choice){
            '1' {
                $bench = Invoke-OgdSystemBenchmark
                Show-OgdBenchmarkResult -Bench $bench
                Read-Host '  INVIO per continuare'
            }
            '2' {
                $bench = Get-OgdBenchmarkProfile
                if($bench){ Show-OgdBenchmarkResult -Bench $bench } else { Write-Warning 'Nessun benchmark salvato' }
                Read-Host '  INVIO per continuare'
            }
            '3' {
                Show-OgdWhatThisDoes 'Benchmark: cosa influenza davvero' @(
                    'rileva il tier della macchina in base a CPU, RAM e disco con un benchmark rapido locale',
                    'usa il tier per regolare alcuni tweak safe come cache, micro tweaks e profilo di reattivita',
                    'non sostituisce la tua scelta del preset, ma la rende piu coerente con il PC reale'
                )
                Read-Host '  INVIO per continuare'
            }
            '0' { return }
            default { Write-Warning 'Scelta non valida'; Start-Sleep 1 }
        }
    }
}

# ═════════════════════════════════════════════════════════════════════════════
#  MICRO TWEAKS: SVCHOST + FOLDER THUMBS
# ═════════════════════════════════════════════════════════════════════════════

function Get-OgdSvcHostSplitThresholdForRam {
    param([int]$RamGB)
    $extraMb = switch($RamGB){
        {$_ -le 8}  {128}
        {$_ -le 16} {256}
        {$_ -le 32} {512}
        default     {1024}
    }
    return [int64](($RamGB * 1048576) + ($extraMb * 1024))
}

function Set-OgdSvcHostSplitThreshold {
    param([int]$RamGB,[switch]$RestoreDefault)
    $key = 'HKLM:\SYSTEM\CurrentControlSet\Control'
    if(-not (Test-Path $key)){ New-Item $key -Force -EA SilentlyContinue | Out-Null }
    if($RestoreDefault){
        Set-ItemProperty $key -Name 'SvcHostSplitThresholdInKB' -Value 3670016 -Type DWord -Force -EA SilentlyContinue
        Write-Success 'SvcHost Split Threshold ripristinato al comportamento Windows standard'
        return
    }
    $value = Get-OgdSvcHostSplitThresholdForRam -RamGB $RamGB
    Set-ItemProperty $key -Name 'SvcHostSplitThresholdInKB' -Value $value -Type DWord -Force -EA SilentlyContinue
    Write-Success ("SvcHost Split Threshold adattivo applicato: {0} KB (RAM {1} GB)" -f $value,$RamGB)
}

function Set-OgdFolderThumbnailMode {
    param([switch]$RestoreDefault)
    $key = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell'
    if(-not (Test-Path $key)){ New-Item $key -Force -EA SilentlyContinue | Out-Null }
    if($RestoreDefault){
        try{ Remove-ItemProperty $key -Name 'Logo' -EA SilentlyContinue }catch{}
        Write-Success 'Anteprime cartelle ripristinate al comportamento Windows standard'
    } else {
        Set-ItemProperty $key -Name 'Logo' -Value 'C:\__OGD_NO_FOLDER_THUMB__.png' -Type String -Force -EA SilentlyContinue
        Write-Success 'Anteprime cartelle disattivate mantenendo quelle dei file'
    }
    try{ Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache*" -Force -EA SilentlyContinue }catch{}
    try{ Stop-Process -Name explorer -Force -EA SilentlyContinue }catch{}
    Start-Sleep -Milliseconds 900
    try{ Start-Process explorer.exe }catch{}
}

function Get-OgdPowerSettingSnapshotPath {
    $root = Join-Path $env:ProgramData 'OGD'
    if(-not (Test-Path $root)){ New-Item -Path $root -ItemType Directory -Force -EA SilentlyContinue | Out-Null }
    return (Join-Path $root 'power-setting-snapshots.json')
}

function Get-OgdCurrentPowerSchemeGuid {
    try{
        $raw = powercfg /getactivescheme 2>$null | Out-String
        if($raw -match '([a-f0-9-]{36})'){
            return $Matches[1]
        }
    }catch{}
    return 'SCHEME_CURRENT'
}

function Get-OgdPowerSettingIndexValue {
    param(
        [string]$Scheme = 'SCHEME_CURRENT',
        [string]$SubGroup = 'SUB_PROCESSOR',
        [string]$SettingAlias,
        [ValidateSet('AC','DC')]
        [string]$PowerMode = 'AC'
    )
    if([string]::IsNullOrWhiteSpace($SettingAlias)){ return $null }
    try{
        $raw = powercfg /query $Scheme $SubGroup $SettingAlias 2>$null | Out-String
        $pattern = if($PowerMode -eq 'AC'){
            'Current AC Power Setting Index:\s+0x([0-9a-fA-F]+)'
        } else {
            'Current DC Power Setting Index:\s+0x([0-9a-fA-F]+)'
        }
        if($raw -match $pattern){
            return [Convert]::ToInt32($Matches[1],16)
        }
    }catch{}
    return $null
}

function Save-OgdPowerSettingSnapshot {
    param(
        [string]$Key,
        [hashtable]$Values
    )
    if([string]::IsNullOrWhiteSpace($Key) -or $null -eq $Values){ return }
    $path = Get-OgdPowerSettingSnapshotPath
    $data = @{}
    try{
        if(Test-Path $path){
            $raw = Get-Content $path -Raw -EA SilentlyContinue
            if(-not [string]::IsNullOrWhiteSpace($raw)){
                $parsed = ConvertFrom-Json $raw -EA SilentlyContinue
                if($parsed){
                    foreach($prop in $parsed.PSObject.Properties){
                        $data[$prop.Name] = @{}
                        foreach($subProp in $prop.Value.PSObject.Properties){
                            $data[$prop.Name][$subProp.Name] = $subProp.Value
                        }
                    }
                }
            }
        }
    }catch{}
    $data[$Key] = @{} + $Values
    try{
        $data | ConvertTo-Json -Depth 5 | Set-Content -Path $path -Encoding UTF8
    }catch{}
}

function Get-OgdPowerSettingSnapshot {
    param([string]$Key)
    if([string]::IsNullOrWhiteSpace($Key)){ return $null }
    $path = Get-OgdPowerSettingSnapshotPath
    try{
        if(-not (Test-Path $path)){ return $null }
        $raw = Get-Content $path -Raw -EA SilentlyContinue
        if([string]::IsNullOrWhiteSpace($raw)){ return $null }
        $parsed = ConvertFrom-Json $raw -EA SilentlyContinue
        if($null -eq $parsed){ return $null }
        $node = $parsed.PSObject.Properties[$Key]
        if($null -eq $node){ return $null }
        return $node.Value
    }catch{}
    return $null
}

function Get-OgdSupportedCoreParkingTargets {
    param([string]$Scheme)
    $targets = New-Object System.Collections.Generic.List[object]
    foreach($entry in @(
        @{ Name='Main'; MinAlias='CPMINCORES';  MaxAlias='CPMAXCORES'  },
        @{ Name='Class1'; MinAlias='CPMINCORES1'; MaxAlias='CPMAXCORES1' }
    )){
        $probe = Get-OgdPowerSettingIndexValue -Scheme $Scheme -SubGroup 'SUB_PROCESSOR' -SettingAlias $entry.MinAlias -PowerMode AC
        if($null -ne $probe){
            [void]$targets.Add([pscustomobject]$entry)
        }
    }
    return @($targets)
}

function Get-OgdSupportedLatencyHintTargets {
    param([string]$Scheme)
    $targets = New-Object System.Collections.Generic.List[object]
    foreach($entry in @(
        @{ Name='Main'; Alias='LATENCYHINTUNPARK'  },
        @{ Name='Class1'; Alias='LATENCYHINTUNPARK1' }
    )){
        $probe = Get-OgdPowerSettingIndexValue -Scheme $Scheme -SubGroup 'SUB_PROCESSOR' -SettingAlias $entry.Alias -PowerMode AC
        if($null -ne $probe){
            [void]$targets.Add([pscustomobject]$entry)
        }
    }
    return @($targets)
}

function Set-OgdCoreParkingMode {
    param([switch]$RestoreDefault)
    $scheme = Get-OgdCurrentPowerSchemeGuid
    $subProc = 'SUB_PROCESSOR'
    $targets = @(Get-OgdSupportedCoreParkingTargets -Scheme $scheme)
    if($targets.Count -eq 0){
        Write-Warning 'Core parking non esposto dal piano energetico attivo: nessuna modifica applicata.'
        return
    }

    if($RestoreDefault){
        $snapshot = Get-OgdPowerSettingSnapshot -Key 'CoreParking'
        $allVerified = $true
        if($null -eq $snapshot){
            Write-Warning 'Nessuno snapshot precedente trovato: uso fallback prudente 10/100.'
        }
        foreach($target in $targets){
            $targetAcMin = 10
            $targetDcMin = 10
            $targetAcMax = 100
            $targetDcMax = 100
            $node = if($snapshot){ $snapshot.PSObject.Properties[$target.Name] } else { $null }
            if($node){
                $value = $node.Value
                if($null -ne $value.ACMin){ $targetAcMin = [int]$value.ACMin }
                if($null -ne $value.DCMin){ $targetDcMin = [int]$value.DCMin }
                if($null -ne $value.ACMax){ $targetAcMax = [int]$value.ACMax }
                if($null -ne $value.DCMax){ $targetDcMax = [int]$value.DCMax }
            }
            try{ powercfg /setacvalueindex $scheme $subProc $target.MinAlias $targetAcMin 2>$null | Out-Null }catch{}
            try{ powercfg /setdcvalueindex $scheme $subProc $target.MinAlias $targetDcMin 2>$null | Out-Null }catch{}
            try{ powercfg /setacvalueindex $scheme $subProc $target.MaxAlias $targetAcMax 2>$null | Out-Null }catch{}
            try{ powercfg /setdcvalueindex $scheme $subProc $target.MaxAlias $targetDcMax 2>$null | Out-Null }catch{}
        }
        try{ powercfg /setactive $scheme 2>$null | Out-Null }catch{}
        $parts = New-Object System.Collections.Generic.List[string]
        foreach($target in $targets){
            $node = if($snapshot){ $snapshot.PSObject.Properties[$target.Name] } else { $null }
            $expectedAcMin = if($node -and $null -ne $node.Value.ACMin){ [int]$node.Value.ACMin } else { 10 }
            $expectedDcMin = if($node -and $null -ne $node.Value.DCMin){ [int]$node.Value.DCMin } else { 10 }
            $expectedAcMax = if($node -and $null -ne $node.Value.ACMax){ [int]$node.Value.ACMax } else { 100 }
            $expectedDcMax = if($node -and $null -ne $node.Value.DCMax){ [int]$node.Value.DCMax } else { 100 }
            $checkAcMin = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.MinAlias -PowerMode AC
            $checkDcMin = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.MinAlias -PowerMode DC
            $checkAcMax = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.MaxAlias -PowerMode AC
            $checkDcMax = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.MaxAlias -PowerMode DC
            if(($checkAcMin -ne $expectedAcMin) -or ($checkDcMin -ne $expectedDcMin) -or ($checkAcMax -ne $expectedAcMax) -or ($checkDcMax -ne $expectedDcMax)){
                $allVerified = $false
            }
            [void]$parts.Add(("{0} AC {1}/{2} DC {3}/{4}" -f $target.Name,$checkAcMin,$checkAcMax,$checkDcMin,$checkDcMax))
        }
        if($allVerified){
            Write-Success ("Core parking ripristinato: {0}" -f ($parts -join ' | '))
        } else {
            Write-Warning ("Core parking ripristinato solo in parte: {0}" -f ($parts -join ' | '))
        }
        return
    }

    $snapshotValues = @{}
    foreach($target in $targets){
        $snapshotValues[$target.Name] = @{
            ACMin = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.MinAlias -PowerMode AC
            DCMin = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.MinAlias -PowerMode DC
            ACMax = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.MaxAlias -PowerMode AC
            DCMax = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.MaxAlias -PowerMode DC
        }
        try{ powercfg /setacvalueindex $scheme $subProc $target.MinAlias 100 2>$null | Out-Null }catch{}
        try{ powercfg /setdcvalueindex $scheme $subProc $target.MinAlias 100 2>$null | Out-Null }catch{}
        try{ powercfg /setacvalueindex $scheme $subProc $target.MaxAlias 100 2>$null | Out-Null }catch{}
        try{ powercfg /setdcvalueindex $scheme $subProc $target.MaxAlias 100 2>$null | Out-Null }catch{}
    }
    Save-OgdPowerSettingSnapshot -Key 'CoreParking' -Values $snapshotValues
    try{ powercfg /setactive $scheme 2>$null | Out-Null }catch{}
    $allVerified = $true
    $parts = New-Object System.Collections.Generic.List[string]
    foreach($target in $targets){
        $checkAcMin = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.MinAlias -PowerMode AC
        $checkDcMin = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.MinAlias -PowerMode DC
        $checkAcMax = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.MaxAlias -PowerMode AC
        $checkDcMax = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.MaxAlias -PowerMode DC
        if(($checkAcMin -ne 100) -or ($checkDcMin -ne 100) -or ($checkAcMax -ne 100) -or ($checkDcMax -ne 100)){
            $allVerified = $false
        }
        [void]$parts.Add(("{0} AC {1}/{2} DC {3}/{4}" -f $target.Name,$checkAcMin,$checkAcMax,$checkDcMin,$checkDcMax))
    }
    if($allVerified){
        Write-Success ("Core parking disattivato correttamente: {0}" -f ($parts -join ' | '))
    } else {
        Write-Warning ("Core parking non verificato pienamente: {0}" -f ($parts -join ' | '))
    }
}

function Set-OgdLatencyHintUnparkMode {
    param([switch]$RestoreDefault)
    $scheme = Get-OgdCurrentPowerSchemeGuid
    $subProc = 'SUB_PROCESSOR'
    $targets = @(Get-OgdSupportedLatencyHintTargets -Scheme $scheme)
    if($targets.Count -eq 0){
        Write-Warning 'LATENCYHINTUNPARK non esposto dal piano energetico attivo: nessuna modifica applicata.'
        return
    }

    if($RestoreDefault){
        $snapshot = Get-OgdPowerSettingSnapshot -Key 'LatencyHintUnpark'
        if($null -eq $snapshot){
            Write-Warning 'Nessuno snapshot precedente per LATENCYHINTUNPARK: nessun ripristino automatico effettuato.'
            return
        }
        $allVerified = $true
        $parts = New-Object System.Collections.Generic.List[string]
        foreach($target in $targets){
            $node = $snapshot.PSObject.Properties[$target.Name]
            if($null -eq $node){ continue }
            $targetAc = if($null -ne $node.Value.AC){ [int]$node.Value.AC } else { continue }
            $targetDc = if($null -ne $node.Value.DC){ [int]$node.Value.DC } else { continue }
            try{ powercfg /setacvalueindex $scheme $subProc $target.Alias $targetAc 2>$null | Out-Null }catch{}
            try{ powercfg /setdcvalueindex $scheme $subProc $target.Alias $targetDc 2>$null | Out-Null }catch{}
        }
        try{ powercfg /setactive $scheme 2>$null | Out-Null }catch{}
        foreach($target in $targets){
            $node = $snapshot.PSObject.Properties[$target.Name]
            if($null -eq $node){ continue }
            $targetAc = if($null -ne $node.Value.AC){ [int]$node.Value.AC } else { continue }
            $targetDc = if($null -ne $node.Value.DC){ [int]$node.Value.DC } else { continue }
            $checkAc = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.Alias -PowerMode AC
            $checkDc = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.Alias -PowerMode DC
            if(($checkAc -ne $targetAc) -or ($checkDc -ne $targetDc)){
                $allVerified = $false
            }
            [void]$parts.Add(("{0} AC {1} DC {2}" -f $target.Name,$checkAc,$checkDc))
        }
        if($allVerified){
            Write-Success ("LATENCYHINTUNPARK ripristinato: {0}" -f ($parts -join ' | '))
        } else {
            Write-Warning ("Ripristino LATENCYHINTUNPARK non verificato completamente: {0}" -f ($parts -join ' | '))
        }
        return
    }

    $snapshotValues = @{}
    foreach($target in $targets){
        $snapshotValues[$target.Name] = @{
            AC = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.Alias -PowerMode AC
            DC = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.Alias -PowerMode DC
        }
        try{ powercfg /setacvalueindex $scheme $subProc $target.Alias 100 2>$null | Out-Null }catch{}
        try{ powercfg /setdcvalueindex $scheme $subProc $target.Alias 50 2>$null | Out-Null }catch{}
    }
    Save-OgdPowerSettingSnapshot -Key 'LatencyHintUnpark' -Values $snapshotValues
    try{ powercfg /setactive $scheme 2>$null | Out-Null }catch{}
    $allVerified = $true
    $parts = New-Object System.Collections.Generic.List[string]
    foreach($target in $targets){
        $checkAc = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.Alias -PowerMode AC
        $checkDc = Get-OgdPowerSettingIndexValue -Scheme $scheme -SubGroup $subProc -SettingAlias $target.Alias -PowerMode DC
        if(($checkAc -ne 100) -or ($checkDc -ne 50)){
            $allVerified = $false
        }
        [void]$parts.Add(("{0} AC {1} DC {2}" -f $target.Name,$checkAc,$checkDc))
    }
    if($allVerified){
        Write-Success ("LATENCYHINTUNPARK attivato: {0}" -f ($parts -join ' | '))
    } else {
        Write-Warning ("LATENCYHINTUNPARK non verificato pienamente: {0}" -f ($parts -join ' | '))
    }
}

function Invoke-OgdUniversalMicroTweaks {
    param([int]$RamGB)
    Write-Info "[U] Micro tweaks adattivi (SvcHost + Folder thumbs + Core parking multi-core)..."
    Set-OgdSvcHostSplitThreshold -RamGB $RamGB
    Set-OgdFolderThumbnailMode
    Set-OgdCoreParkingMode
    $global:opts++
}

function Show-OgdUniversalMicroTweaksMenu {
    $ramTotalBytes = 0
    try{ $ramTotalBytes = (Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue).TotalPhysicalMemory }catch{}
    $ramDetected = [math]::Max(4,[math]::Round($ramTotalBytes / 1GB))
    $adaptiveKb = Get-OgdSvcHostSplitThresholdForRam -RamGB $ramDetected
    while($true){
        Clear-Host
        $logicalProcs = [Environment]::ProcessorCount
        Write-Host "`n  ╔═══════════════════════════════════════════════════════╗" -F Cyan
        Write-Host "  ║ MICRO TWEAKS - SVCHOST / THUMBS / CORE / LATENCY    ║" -F Cyan
        Write-Host "  ╚═══════════════════════════════════════════════════════╝`n" -F Cyan
        Write-Host ("  RAM rilevata: {0} GB | Threshold adattivo: {1} KB`n" -f $ramDetected,$adaptiveKb) -F White
        Write-Host ("  CPU logiche rilevate: {0} | Core parking basato su percentuali Windows, compatibile anche con CPU 16/24/32+ core e classi ibride`n" -f $logicalProcs) -F DarkGray
        Write-Host '  [1] Applica tutti i micro tweaks in modo adattivo' -F Green
        Write-Host '  [2] Applica solo SvcHost Split Threshold adattivo' -F Yellow
        Write-Host '  [3] Ripristina SvcHost Split Threshold default' -F White
        Write-Host '  [4] Disattiva anteprime cartelle ma tieni quelle file' -F Cyan
        Write-Host '  [5] Ripristina anteprime cartelle standard' -F White
        Write-Host '  [6] Disattiva core parking (100% core disponibili)' -F Magenta
        Write-Host '  [7] Ripristina core parking precedente / prudente' -F White
        Write-Host '  [8] Low-latency unpark hint (safe)' -F Cyan
        Write-Host '  [9] Ripristina low-latency unpark hint' -F White
        Write-Host '  [0] Torna indietro`n' -F DarkGray
        $choice = Read-Host '  Scelta (1/2/3/4/5/6/7/8/9/0)'
        switch($choice){
            '1' { Set-OgdSvcHostSplitThreshold -RamGB $ramDetected; Set-OgdFolderThumbnailMode; Set-OgdCoreParkingMode; Read-Host '  INVIO per continuare' }
            '2' { Set-OgdSvcHostSplitThreshold -RamGB $ramDetected; Read-Host '  INVIO per continuare' }
            '3' { Set-OgdSvcHostSplitThreshold -RestoreDefault; Read-Host '  INVIO per continuare' }
            '4' { Set-OgdFolderThumbnailMode; Read-Host '  INVIO per continuare' }
            '5' { Set-OgdFolderThumbnailMode -RestoreDefault; Read-Host '  INVIO per continuare' }
            '6' { Set-OgdCoreParkingMode; Read-Host '  INVIO per continuare' }
            '7' { Set-OgdCoreParkingMode -RestoreDefault; Read-Host '  INVIO per continuare' }
            '8' { Set-OgdLatencyHintUnparkMode; Read-Host '  INVIO per continuare' }
            '9' { Set-OgdLatencyHintUnparkMode -RestoreDefault; Read-Host '  INVIO per continuare' }
            '0' { return }
            default { Write-Warning 'Scelta non valida'; Start-Sleep 1 }
        }
    }
}

# ═════════════════════════════════════════════════════════════════════════════
#  SSD & NVME SUPER TWEAKS
# ═════════════════════════════════════════════════════════════════════════════

function Get-OgdStorageTargets {
    $targets = @()
    try{
        $disks = @(Get-Disk -EA SilentlyContinue)
        $phys  = @(Get-PhysicalDisk -EA SilentlyContinue)
        foreach($disk in $disks){
            $pd = $phys | Where-Object { $_.DeviceId -eq $disk.Number -or $_.FriendlyName -eq $disk.FriendlyName } | Select-Object -First 1
            $bus = if($pd -and $pd.BusType){ [string]$pd.BusType } else { [string]$disk.BusType }
            $media = if($pd -and $pd.MediaType){ [string]$pd.MediaType } else { if($bus -match 'NVMe|SATA'){ 'SSD' } else { '' } }
            $parts = @(Get-Partition -DiskNumber $disk.Number -EA SilentlyContinue | Where-Object DriveLetter)
            $letters = @($parts | ForEach-Object { $_.DriveLetter })
            $targets += [pscustomobject]@{
                DiskNumber   = $disk.Number
                FriendlyName = $disk.FriendlyName
                BusType      = $bus
                MediaType    = $media
                DriveLetters = @($letters)
            }
        }
    }catch{}
    return @($targets)
}

function New-OgdStorageRestorePoint {
    $desc = "OGD WinCaffe v8.1.2 STORAGE - $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
    Write-Info 'Creo un punto di ripristino prima dei tweak storage...'
    if(Get-Command New-OgdRestorePoint -EA SilentlyContinue){
        try{ New-OgdRestorePoint -Description $desc; return }catch{}
    }
    if(Get-Command Checkpoint-Computer -EA SilentlyContinue){
        $cpJ2 = Start-Job { param($d) Checkpoint-Computer -Description $d -RestorePointType MODIFY_SETTINGS -EA SilentlyContinue } -ArgumentList $desc
        $cpDone2 = Wait-Job $cpJ2 -Timeout 30
        if(-not $cpDone2){ Stop-Job $cpJ2; Write-Host "  ⚠ Punto ripristino: timeout (continua)" -ForegroundColor Yellow }
        Remove-Job $cpJ2 -Force -EA SilentlyContinue
        $stub2 = 'placeholder' # sostituto try{ Checkpoint-Computer -Description $desc -RestorePointType 'MODIFY_SETTINGS' -EA SilentlyContinue | Out-Null }catch{}
    }
}

function Show-OgdStorageAnalysis {
    $targets = Get-OgdStorageTargets
    Write-Host ''
    Write-Host '  Unità rilevate:' -F Cyan
    foreach($t in $targets){
        Write-Host ("   Disco {0}: {1} | Bus: {2} | Tipo: {3} | Lettere: {4}" -f $t.DiskNumber,$t.FriendlyName,$t.BusType,$t.MediaType,($(if($t.DriveLetters){$t.DriveLetters -join ', '}else{'-' }))) -F White
    }
    if($targets.Count -eq 0){
        Write-Warning 'Nessuna unità storage rilevata'
    }
}

function Invoke-OgdStorageTweaks {
    param([ValidateSet('SSD','NVME','BOTH')] [string]$Mode)
    New-OgdStorageRestorePoint
    $targets = Get-OgdStorageTargets
    switch($Mode){
        'SSD'  { $selected = @($targets | Where-Object { $_.MediaType -eq 'SSD' -and $_.BusType -notmatch 'NVMe' }) }
        'NVME' { $selected = @($targets | Where-Object { $_.BusType -match 'NVMe' }) }
        'BOTH' { $selected = @($targets | Where-Object { $_.MediaType -eq 'SSD' -or $_.BusType -match 'NVMe' }) }
    }

    if($selected.Count -eq 0){
        Write-Warning "Nessuna unità compatibile trovata per il profilo $Mode"
        return
    }

    Write-Info "Applico SSD & NVME Super Tweaks ($Mode) in modalita safe..."
    try{ fsutil behavior set DisableDeleteNotify 0 | Out-Null }catch{}
    try{ fsutil behavior set disablelastaccess 1 | Out-Null }catch{}
    try{ Enable-ScheduledTask -TaskPath '\Microsoft\Windows\Defrag\' -TaskName 'ScheduledDefrag' -EA SilentlyContinue | Out-Null }catch{}
    try{ Set-Service -Name 'defragsvc' -StartupType Manual -EA SilentlyContinue }catch{}

    foreach($disk in $selected){
        foreach($letter in $disk.DriveLetters){
            try{ Optimize-Volume -DriveLetter $letter -Analyze -EA SilentlyContinue | Out-Null }catch{}
            try{ Optimize-Volume -DriveLetter $letter -ReTrim -EA SilentlyContinue | Out-Null }catch{}
            Write-Success ("Storage ottimizzato: disco {0} volume {1}:" -f $disk.DiskNumber,$letter)
        }
    }

    if($Mode -in @('SSD','BOTH')){
        try{ powercfg /setacvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 0 2>$null | Out-Null }catch{}
    }

    Show-OgdWhatThisDoes 'SSD & NVME Super Tweaks: cosa e stato fatto davvero' @(
        'TRIM abilitato e ReTrim lanciato sui volumi selezionati',
        'scheduled defrag lasciato attivo perche Windows gestisce SSD/NVMe correttamente e in modo safe',
        'last access NTFS ridotto e timeout disco in AC orientato alla massima reattivita',
        'nessun tweak unsafe su buffer flushing, queue depth o registry NVMe non documentato'
    )
}

function Restore-OgdStorageDefaults {
    New-OgdStorageRestorePoint
    Write-Info 'Ripristino impostazioni storage prudenti...'
    try{ fsutil behavior set DisableDeleteNotify 0 | Out-Null }catch{}
    try{ fsutil behavior set disablelastaccess 2 | Out-Null }catch{}
    try{ powercfg /setacvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 20 2>$null | Out-Null }catch{}
    try{ Enable-ScheduledTask -TaskPath '\Microsoft\Windows\Defrag\' -TaskName 'ScheduledDefrag' -EA SilentlyContinue | Out-Null }catch{}
    Write-Success 'Impostazioni storage ripristinate a profilo Windows-safe'
}

function Show-OgdStorageSuperTweaksMenu {
    while($true){
        Clear-Host
        Write-Host "`n  ╔═══════════════════════════════════════════════════════╗" -F Cyan
        Write-Host "  ║             SSD & NVME SUPER TWEAKS 8.1.2            ║" -F Cyan
        Write-Host "  ╚═══════════════════════════════════════════════════════╝`n" -F Cyan
        Write-Host '  [1] Analizza SSD / NVMe presenti' -F Green
        Write-Host '  [2] Applica tweak safe solo SSD' -F Yellow
        Write-Host '  [3] Applica tweak safe solo NVMe' -F Cyan
        Write-Host '  [4] Applica tweak safe SSD + NVMe' -F Magenta
        Write-Host '  [5] Ripristina impostazioni storage prudenti' -F White
        Write-Host '  [0] Torna indietro`n' -F DarkGray
        $choice = Read-Host '  Scelta (1/2/3/4/5/0)'
        switch($choice){
            '1' { Show-OgdStorageAnalysis; Read-Host '  INVIO per continuare' }
            '2' { Invoke-OgdStorageTweaks -Mode 'SSD'; Read-Host '  INVIO per continuare' }
            '3' { Invoke-OgdStorageTweaks -Mode 'NVME'; Read-Host '  INVIO per continuare' }
            '4' { Invoke-OgdStorageTweaks -Mode 'BOTH'; Read-Host '  INVIO per continuare' }
            '5' { Restore-OgdStorageDefaults; Read-Host '  INVIO per continuare' }
            '0' { return }
            default { Write-Warning 'Scelta non valida'; Start-Sleep 1 }
        }
    }
}

# ═════════════════════════════════════════════════════════════════════════════
#  MENU PROGRAMMI OPZIONALI (solo se livello 1/2/3)
# ═════════════════════════════════════════════════════════════════════════════

$installPrograms=$false
$selectedApps=@()
$upgradeApps=@()

if($mode -in @("1","2","3","A","a","4","5","B","b")){
    Show-Banner
    Write-Section "PROGRAMMI OPZIONALI CONSIGLIATI"

    # ── CATALOGO PROGRAMMI ───────────────────────────────────────────────────
    # Ogni voce: Num, Name, ID winget, Cat(egoria), Status (popolato dopo check)
    $appCatalog = @(
        # 🌐 BROWSER
        [PSCustomObject]@{Num="01";Name="Google Chrome";             ID="Google.Chrome";                        Cat="🌐 Browser";      Status=""}
        [PSCustomObject]@{Num="02";Name="Mozilla Firefox";           ID="Mozilla.Firefox";                      Cat="🌐 Browser";      Status=""}
        [PSCustomObject]@{Num="03";Name="Brave Browser";             ID="Brave.Brave";                          Cat="🌐 Browser";      Status=""}
        # 📊 MONITORING
        [PSCustomObject]@{Num="04";Name="GPU-Z";                     ID="TechPowerUp.GPU-Z";                    Cat="📊 Monitoring";   Status=""}
        [PSCustomObject]@{Num="05";Name="CPU-Z";                     ID="CPUID.CPU-Z";                          Cat="📊 Monitoring";   Status=""}
        [PSCustomObject]@{Num="06";Name="HWiNFO";                    ID="REALiX.HWiNFO";                        Cat="📊 Monitoring";   Status=""}
        [PSCustomObject]@{Num="07";Name="HWMonitor";                 ID="CPUID.HWMonitor";                      Cat="📊 Monitoring";   Status=""}
        [PSCustomObject]@{Num="08";Name="Core Temp";                 ID="ALCPU.CoreTemp";                       Cat="📊 Monitoring";   Status=""}
        [PSCustomObject]@{Num="09";Name="CrystalDiskInfo";           ID="CrystalDewWorld.CrystalDiskInfo";      Cat="📊 Monitoring";   Status=""}
        [PSCustomObject]@{Num="10";Name="CrystalDiskMark";           ID="CrystalDewWorld.CrystalDiskMark";      Cat="📊 Monitoring";   Status=""}
        [PSCustomObject]@{Num="11";Name="Speccy";                    ID="Piriform.Speccy";                      Cat="📊 Monitoring";   Status=""}
        [PSCustomObject]@{Num="12";Name="OCCT (stress test)";        ID="OCBase.OCCT";                          Cat="📊 Monitoring";   Status=""}
        # ⚡ OVERCLOCK / TUNING
        [PSCustomObject]@{Num="13";Name="CapFrameX";                 ID="CxSoftware.CapFrameX";                 Cat="📊 Benchmark";    Status=""}
        [PSCustomObject]@{Num="14";Name="Process Explorer";          ID="Microsoft.Sysinternals.ProcessExplorer"; Cat="🛠️  Utilità";   Status=""}
        # 🔧 DRIVER
        [PSCustomObject]@{Num="15";Name="DDU - Display Driver Uninstaller"; ID="Wagnardsoft.DDU";              Cat="🔧 Driver";       Status=""}
        [PSCustomObject]@{Num="16";Name="Snappy Driver Installer";   ID="SamLab.SnappyDriverInstaller";         Cat="🔧 Driver";       Status=""}
        [PSCustomObject]@{Num="17";Name="NVCleanstall (NVIDIA)";     ID="TechPowerUp.NVCleanstall";             Cat="🔧 Driver";       Status=""}
        # 🛠️ UTILITÀ
        [PSCustomObject]@{Num="18";Name="7-Zip";                     ID="7zip.7zip";                            Cat="🛠️  Utilità";     Status=""}
        [PSCustomObject]@{Num="19";Name="Notepad++";                 ID="Notepad++.Notepad++";                  Cat="🛠️  Utilità";     Status=""}
        [PSCustomObject]@{Num="20";Name="Everything (ricerca file)"; ID="voidtools.Everything";                 Cat="🛠️  Utilità";     Status=""}
        [PSCustomObject]@{Num="21";Name="TreeSize Free";             ID="JAMSoftware.TreeSize.Free";            Cat="🛠️  Utilità";     Status=""}
        [PSCustomObject]@{Num="22";Name="Revo Uninstaller";          ID="VS.Revo.Group.RevoUninstaller";        Cat="🛠️  Utilità";     Status=""}
        [PSCustomObject]@{Num="23";Name="BCUninstaller";             ID="Klocman.BulkCrapUninstaller";          Cat="🛠️  Utilità";     Status=""}
        [PSCustomObject]@{Num="24";Name="UniGetUI (WingetUI)";       ID="MartiCliment.UniGetUI";                Cat="🛠️  Utilità";     Status=""}
        [PSCustomObject]@{Num="25";Name="WinMerge";                  ID="WinMerge.WinMerge";                    Cat="🛠️  Utilità";     Status=""}
        [PSCustomObject]@{Num="26";Name="Bulk Rename Utility";       ID="TGRMN.BulkRenameUtility";              Cat="🛠️  Utilità";     Status=""}
        [PSCustomObject]@{Num="27";Name="PowerToys";                 ID="Microsoft.PowerToys";                  Cat="🛠️  Utilità";     Status=""}
        [PSCustomObject]@{Num="28";Name="ShareX (screenshot)";       ID="ShareX.ShareX";                        Cat="🛠️  Utilità";     Status=""}
        # 🎮 GAMING
        [PSCustomObject]@{Num="29";Name="Steam";                     ID="Valve.Steam";                          Cat="🎮 Gaming";       Status=""}
        [PSCustomObject]@{Num="30";Name="Discord";                   ID="Discord.Discord";                      Cat="🎮 Gaming";       Status=""}
        [PSCustomObject]@{Num="31";Name="Playnite (launcher)";       ID="Playnite.Playnite";                    Cat="🎮 Gaming";       Status=""}
        [PSCustomObject]@{Num="32";Name="Parsec (remote gaming)";    ID="Parsec.Parsec";                        Cat="🎮 Gaming";       Status=""}
        # 🌐 RETE
        [PSCustomObject]@{Num="33";Name="qBittorrent";               ID="qBittorrent.qBittorrent";              Cat="🌐 Rete";         Status=""}
        [PSCustomObject]@{Num="34";Name="Wireshark";                 ID="WiresharkFoundation.Wireshark";        Cat="🌐 Rete";         Status=""}
    )

    # ── CHECK STATO (1 chiamata winget list + 1 winget upgrade) ─────────────
    Write-Host "`n  🔍 Controllo stato programmi installati..." -F DarkGray

    # Scarica lista installati e lista aggiornamenti in una volta sola
    Write-Info "Controllo programmi installati (attendere)..."
    $wlJob = Start-Job { winget list --accept-source-agreements 2>$null | Out-String }
    $wlDone = Wait-Job $wlJob -Timeout 60
    $installedList = if($wlDone){ Receive-Job $wlJob }else{ Stop-Job $wlJob; "" }
    Remove-Job $wlJob -Force -EA SilentlyContinue
    $upgradeList   = winget upgrade --accept-source-agreements 2>$null | Out-String

    foreach($app in $appCatalog){
        if($installedList -match [regex]::Escape($app.ID)){
            if($upgradeList -match [regex]::Escape($app.ID)){
                $app.Status = "UPD"   # installato, aggiornamento disponibile
            } else {
                $app.Status = "OK"    # installato e aggiornato
            }
        } else {
            $app.Status = "NEW"       # non installato
        }
    }

    # ── MOSTRA MENU CON STATO ────────────────────────────────────────────────
    Write-Host ""
    $currentCat = ""
    foreach($app in $appCatalog){
        # Intestazione categoria
        if($app.Cat -ne $currentCat){
            $currentCat = $app.Cat
            Write-Host "`n  $currentCat" -F Cyan
        }
        # Colore e icona in base allo stato
        $icon  = switch($app.Status){"OK"{"✓ "};"UPD"{"🔄"};"NEW"{"  "}}
        $color = switch($app.Status){"OK"{"DarkGray"};"UPD"{"Yellow"};"NEW"{"White"}}
        $tag   = switch($app.Status){"OK"{"[già installato]"};"UPD"{"[aggiornamento disponibile]"};"NEW"{""}}
        Write-Host ("  [{0}] {1} {2,-30} {3}" -f $app.Num, $icon, $app.Name, $tag) -F $color
    }

    Write-Host "`n  ────────────────────────────────────────────────────" -F DarkGray
    Write-Host "  Legenda:  ✓ installato  🔄 da aggiornare  (vuoto) non installato" -F DarkGray
    Write-Host "`n  Selezione:" -F Cyan
    Write-Host "  • Numeri separati da virgola  es: 04,06,13" -F White
    Write-Host "  • [A] Installa TUTTI i non installati" -F Green
    Write-Host "  • [U] Aggiorna TUTTI quelli con aggiornamento disponibile" -F Yellow
    Write-Host "  • [AU] Installa nuovi + aggiorna esistenti" -F Cyan
    Write-Host "  • [0] Salta`n" -F DarkGray

    $progChoice = Read-Host "  Scelta"

    if($progChoice -ne "0"){
        $installPrograms = $true
        $toInstall = @()   # ID da installare (nuovi)
        $toUpgrade = @()   # ID da aggiornare (già installati)

        switch -Regex ($progChoice){
            "^[Aa][Uu]$" {
                # Tutti nuovi + tutti aggiornamenti
                $toInstall = $appCatalog | Where-Object {$_.Status -eq "NEW"} | Select-Object -Exp ID
                $toUpgrade = $appCatalog | Where-Object {$_.Status -eq "UPD"} | Select-Object -Exp ID
            }
            "^[Aa]$" {
                $toInstall = $appCatalog | Where-Object {$_.Status -eq "NEW"} | Select-Object -Exp ID
            }
            "^[Uu]$" {
                $toUpgrade = $appCatalog | Where-Object {$_.Status -eq "UPD"} | Select-Object -Exp ID
            }
            default {
                # Numeri selezionati manualmente
                $choices = $progChoice -split ','
                foreach($c in $choices){
                    $c = $c.Trim().TrimStart('0')
                    if($c -eq ""){ $c = "0" }
                    $found = $appCatalog | Where-Object {[int]$_.Num -eq [int]$c}
                    if($found){
                        if($found.Status -eq "UPD"){ $toUpgrade += $found.ID }
                        else                        { $toInstall += $found.ID }
                    }
                }
            }
        }

        # Rimuovi duplicati
        $toInstall = $toInstall | Select-Object -Unique
        $toUpgrade = $toUpgrade | Select-Object -Unique

        # Mantieni $selectedApps per compatibilità con il blocco installazione a fine script
        # Il blocco finale gestirà install e upgrade separatamente
        $selectedApps  = $toInstall
        $upgradeApps   = $toUpgrade
    }
}

# ═════════════════════════════════════════════════════════════════════════════
#  MODALITÀ 6: INFO
# ═════════════════════════════════════════════════════════════════════════════

if($mode -eq "8"){
    Show-Banner;Write-Section "INFO LIVELLI"
    Write-Host "`n  🟢 LIGHT:" -F Green
    Write-Host "   1. C-States BALANCED (zero freeze)" -F White
    Write-Host "   2. Timer 0.5ms + Piano Ultimate" -F White
    Write-Host "   3. Privacy base (rete lasciata invariata)" -F White
    Write-Host "   4. Explorer Boost + cache visualizzazioni" -F White
    Write-Host "   5. GPU Hardware Scheduling`n" -F White
    Write-Host "  🟣 BETA 25H2 / 26220.8148:" -F Magenta
    Write-Host "   Preset compatibile con Windows 11 25H2 stabile e Insider Beta 26220.8148" -F White
    Write-Host "   Niente debloat Appx, niente forcing low-level, solo tweak compatibili e prudente reattivita`n" -F White
    Write-Host "  🟡 NORMALE (include Light +):" -F Yellow
    Write-Host "   6. Process Priority 35+ processi (Explorer/Edge/MMC/MSIExec inclusi)" -F White
    Write-Host "   7. NPU Optimization" -F White
    Write-Host "   8. Privacy completo (6 step)" -F White
    Write-Host "   9. Debloat (10 app bloatware)" -F White
    Write-Host "  10. Visual optimization (4 step)`n" -F White
    Write-Host "  🔴 AGGRESSIVO (include Normale +):" -F Red
    Write-Host "  11. Core Affinity P+E cores" -F White
    Write-Host "  12. Memory intelligente (11 parametri)" -F White
    Write-Host "  13. System Responsiveness 3 (97% foreground)" -F White
    Write-Host "  13b. Boot/Login/Logout/Reboot/Shutdown più rapidi" -F White
    Write-Host "  14. CPU Unparking (tutti i core attivi)" -F White
    Write-Host "  15. Processor Boost = Aggressive (no OC)" -F White
    Write-Host "  16. MMCSS Games + Pro Audio priority 6" -F White
    Write-Host "  17. Xbox Game Bar + DVR OFF" -F White
    Write-Host "  18. Windows Game Mode ON" -F White
    Write-Host "  19. USB Selective Suspend OFF" -F White
    Write-Host "  20. NTFS metadata ottimizzati in modo prudente" -F White
    Write-Host "  21. NVMe/SSD: TRIM ON, Idle PM OFF" -F White
    Write-Host "  22. Servizi non gaming disabilitati (8)" -F White
    Write-Host "  23. Fullscreen Optimizations OFF" -F White
    Write-Host "  24. GPU IRQ + driver tweaks (NVIDIA/AMD)" -F White
    Write-Host "  25. Windows Error Reporting lasciato attivo per diagnosi" -F White
    Write-Host "  26. Power Throttling gestito in modo prudente" -F White
    Write-Host "  27. Manutenzione automatica lasciata attiva" -F White
    Write-Host "  28. Search Indexing lasciato manuale/invariato" -F White
    Write-Host "  29. GPU scheduler undocumented lasciato invariato" -F White
    Write-Host "  30. MSI Interrupts GPU" -F White
    Write-Host "  31. Windows Update: Active Hours 8-23, P2P OFF" -F White
    Write-Host "  32. DirectX Flip Model ON" -F White
    Write-Host "  33. Accessibilità font solo su richiesta (no auto OpenDyslexic)`n" -F White
    Write-Host "  RISULTATI ATTESI:" -F Cyan
    Write-Host "   Light: Boot -10%, FPS +5-10%" -F Green
    Write-Host "   Normale: Boot -20%, FPS +10-15% ⭐" -F Yellow
    Write-Host "   Aggressivo: Boot -30%, FPS +15-20%`n" -F Red
    Read-Host "  INVIO";continue MenuLoop
}

# ═════════════════════════════════════════════════════════════════════════════
#  MODALITÀ 7: RESET
# ═════════════════════════════════════════════════════════════════════════════

if($mode -eq "9"){
    Show-Banner;Write-Section "RESET SISTEMA"
    Write-Host "`n  RIPRISTINO:" -F Cyan
    Write-Host "  1. F8 al boot → Ripristino sistema" -F White
Write-Host "  2. Seleziona: 'OGD WinCaffe NEXT v8.1.2'`n" -F White
    Read-Host "  INVIO";continue MenuLoop
}

# ═════════════════════════════════════════════════════════════════════════════

# ═════════════════════════════════════════════════════════════════════════════
#  MODALITÀ 8: FILE I/O TWEAKS
# ═════════════════════════════════════════════════════════════════════════════

if($mode -in @("F","f")){
    Show-Banner
    Write-Section "FILE I/O OPTIMIZATION"
    Show-OgdWorkingAnimation -Text 'Preparazione menu File I/O...' -DurationMs 550

    function local:Get-OgdHddVolumes {
        $items = New-Object System.Collections.Generic.List[object]
        foreach($vol in @(Get-Volume -EA SilentlyContinue | Where-Object {
            $_.DriveLetter -and $_.DriveType -eq 'Fixed' -and $_.FileSystemType -in @('NTFS','ReFS')
        })){
            try{
                $part = Get-Partition -DriveLetter $vol.DriveLetter -EA Stop
                $disk = Get-Disk -Number $part.DiskNumber -EA Stop
                $mediaType = [string]$disk.MediaType
                if([string]::IsNullOrWhiteSpace($mediaType)){ $mediaType = 'Unspecified' }
                if($mediaType -in @('HDD','Unspecified')){
                    [void]$items.Add([pscustomobject]@{
                        DriveLetter = $vol.DriveLetter
                        FileSystem  = $vol.FileSystemType
                        DiskNumber  = $disk.Number
                        FriendlyName= $disk.FriendlyName
                        MediaType   = $mediaType
                        SizeGB      = [Math]::Round($vol.Size / 1GB, 0)
                    })
                }
            }catch{}
        }
        return @($items)
    }

    function local:Invoke-OgdHddOptimization {
        param(
            [switch]$AnalyzeOnly
        )
        $hddVolumes = @(Get-OgdHddVolumes)
        if($hddVolumes.Count -eq 0){
            Write-Warning 'Nessun volume HDD fisso rilevato automaticamente'
            return $false
        }

        Write-Info ("Volumi HDD rilevati: " + (($hddVolumes | ForEach-Object { "$($_.DriveLetter): $($_.FriendlyName) [$($_.MediaType)]" }) -join ' | '))
        $done = New-Object System.Collections.Generic.List[string]
        foreach($vol in $hddVolumes){
            try{
                if($AnalyzeOnly){
                    Optimize-Volume -DriveLetter $vol.DriveLetter -Analyze -EA Stop | Out-Null
                    [void]$done.Add("$($vol.DriveLetter): Analyze")
                } else {
                    Optimize-Volume -DriveLetter $vol.DriveLetter -Defrag -EA Stop | Out-Null
                    [void]$done.Add("$($vol.DriveLetter): Defrag")
                }
            }catch{
                Write-Warning ("{0}: ottimizzazione non riuscita" -f $vol.DriveLetter)
            }
        }
        if($done.Count -gt 0){
            Write-Success ("HDD: " + ($done -join ' | '))
            return $true
        }
        return $false
    }
    
    Write-Host "`n  📂 Ottimizzazioni velocità file I/O`n" -F Cyan
    Write-Host "  Migliora prestazioni:" -F White
    Write-Host "  • Trasferimenti file (copia/sposta)" -F DarkGray
    Write-Host "  • Caricamento giochi" -F DarkGray
    Write-Host "  • Installazioni programmi" -F DarkGray
    Write-Host "  • Decompressione archivi`n" -F DarkGray
    Write-Host "  [1] Preset FILE I/O generale" -F Green
    Write-Host "      Mantiene il profilo che ti sta gia funzionando bene" -F DarkGray
    Write-Host "  [2] HDD submenu" -F Yellow
    Write-Host "      Analisi e ottimizzazione dedicate ai dischi meccanici" -F DarkGray
    Write-Host "  [0] Torna al menu`n" -F White

    $fileIoChoice = Read-Host "  Scelta (1/2/0)"
    if($fileIoChoice -eq '0'){ continue MenuLoop }
    if($fileIoChoice -eq '2'){
        while($true){
            Show-Banner
            Write-Section "FILE I/O HDD SUBMENU"
            Write-Host "`n  Menu HDD dedicato ai dischi meccanici.`n" -F Cyan

            $hddDetected = @(Get-OgdHddVolumes)
            if($hddDetected.Count -gt 0){
                foreach($h in $hddDetected){
                    Write-Host ("  • {0}: {1} | {2} GB | {3}" -f $h.DriveLetter, $h.FriendlyName, $h.SizeGB, $h.MediaType) -F White
                }
            } else {
                Write-Host "  • Nessun HDD fisso rilevato automaticamente" -F DarkGray
            }
            Write-Host ""
            Write-Host "  [1] Stato HDD rilevati" -F White
            Write-Host "  [2] Analizza volumi HDD" -F Green
            Write-Host "  [3] Deframmenta / ottimizza volumi HDD" -F Yellow
            Write-Host "  [4] Preset HDD SAFE" -F Cyan
            Write-Host "      Analisi + defrag HDD + trim SSD/NVMe resta gestito dal preset generale" -F DarkGray
            Write-Host "  [0] Torna a FILE I/O`n" -F White

            $hddChoice = Read-Host "  Scelta (1/2/3/4/0)"
            switch($hddChoice){
                '1' {
                    if($hddDetected.Count -gt 0){
                        Write-Success ("HDD rilevati: " + ($hddDetected.Count))
                    } else {
                        Write-Warning 'Nessun HDD rilevato'
                    }
                    Read-Host '  INVIO per continuare'
                }
                '2' {
                    Invoke-OgdHddOptimization -AnalyzeOnly | Out-Null
                    Read-Host '  INVIO per continuare'
                }
                '3' {
                    if((Read-Host '  Confermi deframmentazione/ottimizzazione HDD? (S/N)') -in @('S','s')){
                        Invoke-OgdHddOptimization | Out-Null
                    }
                    Read-Host '  INVIO per continuare'
                }
                '4' {
                    $didAnalyze = Invoke-OgdHddOptimization -AnalyzeOnly
                    $didDefrag = $false
                    if($didAnalyze){
                        $didDefrag = Invoke-OgdHddOptimization
                    }
                    if($didAnalyze -or $didDefrag){
                        Show-OgdWhatThisDoes 'Preset HDD SAFE: cosa e stato fatto davvero' @(
                            'analizzati i volumi HDD rilevati automaticamente',
                            'eseguita la deframmentazione solo sui volumi meccanici compatibili',
                            'nessuna modifica invasiva ai controller storage o al file system fuori dal perimetro del menu'
                        )
                    }
                    Read-Host '  INVIO per continuare'
                }
                '0' { break }
                default {
                    Write-Warning 'Scelta non valida'
                    Start-Sleep 1
                }
            }
        }
        continue MenuLoop
    }
    if($fileIoChoice -notin @('1')){
        Write-Warning 'Scelta non valida'
        Start-Sleep 1
        continue MenuLoop
    }
    
    if((Read-Host "  Applicare tweaks? (S/N)") -notin @("S","s")){continue MenuLoop}
    
    Write-Host ""
    # Punto ripristino (opzionale)
    $createRestore = Read-Host "  Creare punto ripristino Windows? (S/N)"
    if($createRestore -in @("S","s")){
        # Punto ripristino
$desc="OGD WinCaffe NEXT v8.1.2 FILE I/O - $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
        New-OgdRestorePoint -Description $desc
    }
    
    
    Write-Info "Applicazione tweaks File I/O..."
    Show-OgdWorkingAnimation -Text 'Applicazione tweaks File I/O...' -DurationMs 850
    
    # NTFS Last Access Time OFF (performance boost)
    try{ fsutil behavior set disablelastaccess 1 2>$null|Out-Null }catch{}
    $lastAccessState = ''
    try{ $lastAccessState = (fsutil behavior query disablelastaccess 2>$null | Out-String).Trim() }catch{}
    if($lastAccessState -match '1'){
        Write-Success "NTFS Last Access Time: OFF"
    } else {
        Write-Warning "NTFS Last Access Time: verifica non conclusiva"
    }
    
    # File System Cache tweaks
    $mp="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    Set-ItemProperty $mp -Name "LargeSystemCache" -Value 0 -Type DWord -Force -EA SilentlyContinue
    Write-Success "File System Cache: ottimizzato per desktop/gaming (LargeSystemCache 0)"
    
    # NTFS cache interna piu ampia solo se la RAM lo consente davvero
    $totalRamGB = 0
    try{
        $totalRamGB = [Math]::Round((Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue).TotalPhysicalMemory / 1GB)
    }catch{}
    if($totalRamGB -ge 24){
        try{ fsutil behavior set memoryusage 2 2>$null|Out-Null }catch{}
        $memoryUsageState = ''
        try{ $memoryUsageState = (fsutil behavior query memoryusage 2>$null | Out-String).Trim() }catch{}
        if($memoryUsageState -match '2'){
            Write-Success "NTFS MemoryUsage: HIGH (RAM rilevata: ${totalRamGB} GB)"
        } else {
            Write-Warning "NTFS MemoryUsage: verifica non conclusiva"
        }
    } else {
        Write-Info "NTFS MemoryUsage: lasciato default (RAM rilevata: ${totalRamGB} GB)"
    }
    
    # Disable 8.3 filename creation (performance)
    try{ fsutil behavior set disable8dot3 1 2>$null|Out-Null }catch{}
    $name83State = ''
    try{ $name83State = (fsutil behavior query disable8dot3 2>$null | Out-String).Trim() }catch{}
    if($name83State -match '1'){
        Write-Success "8.3 Filename creation: OFF"
    } else {
        Write-Warning "8.3 Filename creation: verifica non conclusiva"
    }

    # TRIM sempre attivo per SSD/NVMe moderni
    try{ fsutil behavior set DisableDeleteNotify 0 2>$null|Out-Null }catch{}
    $trimState = ''
    try{ $trimState = (fsutil behavior query DisableDeleteNotify 2>$null | Out-String).Trim() }catch{}
    if($trimState -match '0'){
        Write-Success "TRIM / DeleteNotify: ON"
    } else {
        Write-Warning "TRIM / DeleteNotify: verifica non conclusiva"
    }

    # ReTrim/ottimizzazione reale dei volumi fissi supportati
    $optimizedVolumes = New-Object System.Collections.Generic.List[string]
    foreach($vol in @(Get-Volume -EA SilentlyContinue | Where-Object {
        $_.DriveLetter -and $_.DriveType -eq 'Fixed' -and $_.FileSystemType -in @('NTFS','ReFS')
    })){
        try{
            Optimize-Volume -DriveLetter $vol.DriveLetter -ReTrim -EA Stop | Out-Null
            [void]$optimizedVolumes.Add("$($vol.DriveLetter): ReTrim")
            continue
        }catch{}
        try{
            Optimize-Volume -DriveLetter $vol.DriveLetter -Analyze -EA Stop | Out-Null
            [void]$optimizedVolumes.Add("$($vol.DriveLetter): Analyze")
        }catch{}
    }
    if($optimizedVolumes.Count -gt 0){
        Write-Success ("Ottimizzazione volumi: " + ($optimizedVolumes -join ' | '))
    } else {
        Write-Info "Ottimizzazione volumi: nessun volume fisso NTFS/ReFS gestito automaticamente"
    }

    Write-Info "FILE I/O: il menu resta concentrato solo su storage, volumi e file system"

    Write-Host "`n  ════════════════════════════════════════════════════" -F Green
    Write-Host "   ✓ FILE I/O TWEAKS APPLICATI!" -F Green
    Show-OgdAppliedSummary 'FILEIO'
    Write-Host "  ════════════════════════════════════════════════════`n" -F Green
    
    if((Read-Host "  Riavvio consigliato. Riavviare ora? (S/N)") -in @("S","s")){
        Restart-Computer -Force
    }
    continue MenuLoop
}

# ═════════════════════════════════════════════════════════════════════════════
#  MODALITÀ 9: WINGET UPDATE
# ═════════════════════════════════════════════════════════════════════════════

if($mode -in @("U","u")){
    Show-Banner
    Write-Section "WINGET UPDATE"
    Show-OgdWorkingAnimation -Text 'Analisi Winget...' -DurationMs 700

    $wg = Get-OgdWingetStatus
    if(-not $wg.Available){
        Write-Host "`n  ❌ Winget non trovato!" -F Red
        Write-Host "  Installa o aggiorna App Installer dal Microsoft Store, poi riprova." -F Yellow
        Read-Host "  INVIO"
        continue MenuLoop
    }

    Write-Host "`n  🔄 Gestione aggiornamenti con Winget`n" -F Cyan
    Write-Host "  • Percorso: $($wg.Path)" -F DarkGray
    if($wg.Version){ Write-Host "  • Versione: $($wg.Version)" -F DarkGray }
    foreach($note in @($wg.Notes)){ Write-Host "  • Nota: $note" -F DarkGray }

    Write-Host "`n  [1] Controlla aggiornamenti disponibili" -F Green
    Write-Host "      Usa winget list --upgrade-available per un'anteprima chiara" -F DarkGray
    Write-Host "  [2] Aggiorna tutto in modo silenzioso" -F Yellow
    Write-Host "      Usa winget upgrade --all --include-unknown con sorgenti già aggiornate" -F DarkGray
    Write-Host "  [3] Ripara sorgenti Winget" -F Cyan
    Write-Host "      Esegue source reset --force + source update" -F DarkGray
    Write-Host "  [4] Diagnostica Winget" -F White
    Write-Host "      Mostra sorgenti, aggiornamenti disponibili e stato App Installer" -F DarkGray
    Write-Host "  [0] Torna al menu`n" -F DarkGray

    $wgChoice = Read-Host "  Scelta (1/2/3/4/0)"
    if($wgChoice -eq '0'){ continue MenuLoop }

    switch($wgChoice){
        '1' {
            Write-Info 'Aggiornamento indice sorgenti Winget...'
            $su = Invoke-OgdWinget -Arguments @('source','update') -TimeoutSec 90
            if($su.TimedOut){ Write-Warning 'source update in timeout; continuo comunque con il controllo elenco' }

            Show-OgdWorkingAnimation -Text 'Lettura aggiornamenti disponibili...' -DurationMs 900
            $preview = Invoke-OgdWinget -Arguments @('list','--upgrade-available','--accept-source-agreements') -TimeoutSec 180
            if($preview.TimedOut){
                Write-Warning 'Winget: timeout durante il controllo aggiornamenti'
            }else{
                $preview.Output.TrimEnd() -split "`r?`n" | ForEach-Object {
                    if($_.Trim()){ Write-Host "  $_" -F White }
                }
            }
            Read-Host "  INVIO per tornare al menu"
            continue MenuLoop
        }
        '2' {
            Write-Info 'Aggiorno prima le sorgenti Winget...'
            $su = Invoke-OgdWinget -Arguments @('source','update') -TimeoutSec 90
            if($su.TimedOut){ Write-Warning 'source update in timeout; provo comunque l upgrade completo' }

            if((Read-Host "  Confermi l'aggiornamento completo dei pacchetti? (S/N)") -notin @('S','s')){
                Write-Info 'Aggiornamento annullato'
                Read-Host "  INVIO per tornare al menu"
                continue MenuLoop
            }

            Show-OgdWorkingAnimation -Text 'Winget upgrade completo in corso...' -DurationMs 1200
            $up = Invoke-OgdWinget -Arguments @('upgrade','--all','--include-unknown','--accept-source-agreements','--accept-package-agreements','--disable-interactivity','--silent') -TimeoutSec 3600
            if($up.TimedOut){
                Write-Warning 'Winget upgrade: timeout'
            }else{
                $up.Output.TrimEnd() -split "`r?`n" | ForEach-Object {
                    if($_.Trim()){ Write-Host "  $_" -F White }
                }
                if($up.ExitCode -eq 0){ Write-Success 'Winget: aggiornamento completato' }
                else { Write-Warning "Winget: uscita con codice $($up.ExitCode)" }
            }
            Read-Host "  INVIO per tornare al menu"
            continue MenuLoop
        }
        '3' {
            Write-Info 'Riparazione sorgenti Winget...'
            Show-OgdWorkingAnimation -Text 'Reset sorgenti Winget...' -DurationMs 850
            $r1 = Invoke-OgdWinget -Arguments @('source','reset','--force') -TimeoutSec 120
            $r2 = Invoke-OgdWinget -Arguments @('source','update') -TimeoutSec 120
            if($r1.TimedOut -or $r2.TimedOut){
                Write-Warning 'Riparazione Winget: timeout su una delle operazioni'
            }else{
                Write-Success 'Winget: sorgenti riparate/aggiornate'
            }
            Read-Host "  INVIO per tornare al menu"
            continue MenuLoop
        }
        '4' {
            Write-Info 'Diagnostica Winget...'
            $src = Invoke-OgdWinget -Arguments @('source','list') -TimeoutSec 60
            $lst = Invoke-OgdWinget -Arguments @('list','--upgrade-available','--accept-source-agreements') -TimeoutSec 180
            Write-Host "`n  --- Sorgenti ---" -F Cyan
            ($src.Output.TrimEnd() -split "`r?`n") | ForEach-Object { if($_.Trim()){ Write-Host "  $_" -F White } }
            Write-Host "`n  --- Upgrade disponibili ---" -F Cyan
            ($lst.Output.TrimEnd() -split "`r?`n") | ForEach-Object { if($_.Trim()){ Write-Host "  $_" -F White } }
            Read-Host "  INVIO per tornare al menu"
            continue MenuLoop
        }
        default {
            continue MenuLoop
        }
    }
}


if($mode -in @("L","l")){
    Show-Banner
    Write-Section "DPC LATENCY FIX"
    Show-OgdWorkingAnimation -Text 'Preparazione menu DPC Latency...' -DurationMs 550

    Write-Host "`n  ⚡ Cos'è la DPC Latency?`n" -F Cyan
    Write-Host "  DPC (Deferred Procedure Call) = chiamate differite del kernel." -F White
    Write-Host "  Latenza alta causa: stuttering audio, lag nei giochi, micro-freeze," -F White
    Write-Host "  input lag, video a scatti — anche su PC potenti.`n" -F White

    Write-Host "  Sintomi tipici:" -F Yellow
    Write-Host "   • Audio che crackla o si interrompe" -F DarkGray
    Write-Host "   • Giochi fluidi ma con micro-freeze periodici" -F DarkGray
    Write-Host "   • Mouse che si 'impalla' per un istante" -F DarkGray
    Write-Host "   • Video stuttering anche con GPU scarica`n" -F DarkGray

    Write-Host "  ┌─────────────────────────────────────────────────────────┐" -F Cyan
    Write-Host "  │ OPZIONI                                                 │" -F Cyan
    Write-Host "  └─────────────────────────────────────────────────────────┘`n" -F Cyan

    Write-Host "  [1] 🔍 ANALISI - Misura la DPC latency attuale" -F White
    Write-Host "      Apre LatencyMon (download se assente) per diagnosi`n" -F DarkGray

    Write-Host "  [2] ⚡ FIX RAPIDO - Tweaks immediati anti-latency" -F Green
    Write-Host "      Timer, C-States, USB polling, servizi — senza riavvio`n" -F DarkGray

    Write-Host "  [3] 🔧 FIX AVANZATO - Fix rapido + ottimizzazioni driver" -F Yellow
    Write-Host "      MSI Interrupts sistema, AHCI, IRQ priority`n" -F DarkGray

    Write-Host "  [4] 🔄 RESET - Ripristina impostazioni default" -F DarkGray
    Write-Host "      Riporta piano energetico, bcdedit e servizi al default`n" -F DarkGray

    Write-Host "  [0] ↩️  Torna al menu`n" -F DarkGray

    $dpcChoice = Read-Host "  Scelta (1/2/3/4/0)"
    if($dpcChoice -eq "0"){ continue MenuLoop }

    Write-Host ""

    # ── ANALISI: apre LatencyMon ──────────────────────────────────────────────
    if($dpcChoice -eq "1"){
        Write-Info "Verifica LatencyMon..."
        $latmon = @(
            "$env:ProgramFiles\Resplendence\LatencyMon\LatMon.exe",
            "${env:ProgramFiles(x86)}\Resplendence\LatencyMon\LatMon.exe"
        )
        $found = $latmon | Where-Object { Test-Path $_ } | Select-Object -First 1

        if($found){
            Write-Success "LatencyMon trovato: avvio..."
            Start-Process $found
        } else {
            Write-Warning "LatencyMon non trovato"
            Write-Host "  Download gratuito da: https://www.resplendence.com/latencymon`n" -F Cyan

            if((Read-Host "  Aprire la pagina di download? (S/N)") -in @("S","s")){
                Start-Process "https://www.resplendence.com/latencymon"
                Write-Host "  ✓ Pagina aperta nel browser`n" -F Green
            }
        }

        Write-Host "  📋 Come usare LatencyMon:" -F Cyan
        Write-Host "   1. Avvia LatencyMon come Amministratore" -F White
        Write-Host "   2. Premi START (▶)" -F White
        Write-Host "   3. Usa il PC normalmente per 1-2 minuti" -F White
        Write-Host "   4. Premi STOP (■)" -F White
        Write-Host "   5. Guarda quali driver hanno DPC latency > 100µs" -F White
        Write-Host "   6. Torna qui e usa [2] o [3] per applicare i fix`n" -F DarkGray

        Read-Host "  INVIO per tornare al menu"
        continue MenuLoop
    }

    # Punto ripristino per fix 2, 3, 4
    # Punto ripristino
    $desc="OGD DPC Latency Fix - $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
    New-OgdRestorePoint -Description $desc
    Write-Host ""

    # ── RESET: ripristina default (codice fornito dall'utente) ────────────────
    if($dpcChoice -eq "4"){
        Write-Info "Reset DPC: ripristino impostazioni default..."

        # Ripristina piano energetico bilanciato
        powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null
        Write-Success "Piano energetico: Bilanciato ripristinato"

        # Ripristina bcdedit
        bcdedit /deletevalue useplatformclock    2>$null|Out-Null
        bcdedit /deletevalue disabledynamictick  2>$null|Out-Null
        bcdedit /deletevalue tscsyncpolicy       2>$null|Out-Null
        Write-Success "bcdedit: Valori rimossi (default)"

        # Riabilita servizi
        try{
            Set-Service -Name "SysMain" -StartupType Automatic -EA SilentlyContinue
            Start-Service SysMain -EA SilentlyContinue
            Write-Success "SysMain: Riabilitato"
        }catch{ Write-Warning "SysMain: Impossibile riabilitare" }

        try{
            Set-Service -Name "WSearch" -StartupType Automatic -EA SilentlyContinue
            Start-Service WSearch -EA SilentlyContinue
            Write-Success "WSearch: Riabilitato"
        }catch{ Write-Warning "WSearch: Impossibile riabilitare" }

        # Ripristina stack USB/HID
        Restore-OgdUsbInputDefaults | Out-Null

        Write-Host ""
        Write-Host "  ════════════════════════════════════════════════════" -F Green
        Write-Host "   ✓ RESET COMPLETATO — Impostazioni default ripristinate" -F Green
        Show-OgdWhatThisDoes 'Reset DPC: cosa è stato fatto davvero' @(
            'ripristinati piano energetico, bcdedit e servizi principali al comportamento standard',
            'rimossi i tweak USB/timer piu invasivi per tornare a una base pulita'
        )
        Write-Host "  ════════════════════════════════════════════════════`n" -F Green
        Write-Host "  [WARN] Riavvia il PC per applicare il reset completamente`n" -F Yellow

        if((Read-Host "  Riavviare ora? (S/N)") -in @("S","s")){ Restart-Computer -Force }
        Read-Host "  INVIO per tornare al menu"
        continue MenuLoop
    }

    # ── FIX RAPIDO ────────────────────────────────────────────────────────────
    if($dpcChoice -in @("2","3")){
        Write-Info "[1] Timer ad alta risoluzione..."
        # Forza timer 0.5ms — riduce jitter kernel
        bcdedit /set useplatformclock No          2>$null|Out-Null
        bcdedit /set disabledynamictick Yes        2>$null|Out-Null
        bcdedit /set tscsyncpolicy Enhanced        2>$null|Out-Null
        Write-Success "Timer: 0.5ms, dynamic tick OFF, TSC Enhanced"

        Write-Info "[2] Piano energetico: High Performance..."
        # High Performance riduce C-States profondi che causano DPC spike
        $hpGuid = (powercfg /list 2>$null | Select-String "High performance|Prestazioni elevate")
        if($hpGuid -and $hpGuid.ToString() -match '([a-f0-9-]{36})'){
            powercfg /setactive $Matches[1] 2>$null
                powercfg /setacvalueindex $Matches[1] SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null
                powercfg /setdcvalueindex $Matches[1] SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null
            Write-Success "Piano: High Performance attivato"
        } else {
            powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            Write-Success "Piano: High Performance (GUID default)"
        }

        Write-Info "[3] C-States ridotti..."
        $pg=(powercfg /getactivescheme) -match 'GUID:\s+([a-f0-9\-]+)'
        if($pg){$pg=$Matches[1]}else{$pg="SCHEME_CURRENT"}
        powercfg /setacvalueindex $pg SUB_PROCESSOR IDLESTATEMAX 1 2>$null  # Max C1
        powercfg /setacvalueindex $pg SUB_PROCESSOR IDLEDISABLE  0 2>$null
        powercfg /setactive $pg 2>$null
        Write-Success "C-States: Max C1 (elimina spike da C2/C3/C6)"

        Write-Info "[4] USB selective suspend OFF..."
        powercfg /setacvalueindex $pg 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
        powercfg /setdcvalueindex $pg 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
        powercfg /setactive $pg 2>$null
        Write-Success "USB Suspend: OFF lato power plan (senza override aggressivi sullo stack USB)"

        Write-Info "[5] Servizi background DPC-pesanti: priorità minima..."
        # SysMain e WSearch causano DPC spike quando scansionano
        $svcDPC = @("SysMain","WSearch","DiagTrack","WMPNetworkSvc","TabletInputService")
        foreach($svc in $svcDPC){
            try{
                $s = Get-Service $svc -EA SilentlyContinue
                if($s){
                    $rp="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$svc.exe\PerfOptions"
                    if(!(Test-Path $rp)){New-Item $rp -Force -EA SilentlyContinue|Out-Null}
                    Set-ItemProperty $rp -Name "CpuPriorityClass" -Value 1 -Type DWord -Force -EA SilentlyContinue
                    Set-ItemProperty $rp -Name "IoPriority"       -Value 0 -Type DWord -Force -EA SilentlyContinue
                }
            }catch{}
        }
        Write-Success "Servizi background: I/O priority minima"

        Write-Info "[6] MMCSS: priorità audio massima..."
        $mmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Set-ItemProperty $mmPath -Name "SystemResponsiveness"   -Value 0    -Type DWord -Force -EA SilentlyContinue
        # Tasks Audio
        $mmAudio = "$mmPath\Tasks\Audio"
        if(!(Test-Path $mmAudio)){New-Item $mmAudio -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $mmAudio -Name "Affinity"            -Value 0  -Type DWord  -Force -EA SilentlyContinue
        Set-ItemProperty $mmAudio -Name "Background Only"     -Value "False" -Force  -EA SilentlyContinue
        Set-ItemProperty $mmAudio -Name "Clock Rate"          -Value 10000 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $mmAudio -Name "GPU Priority"        -Value 8  -Type DWord  -Force -EA SilentlyContinue
        Set-ItemProperty $mmAudio -Name "Priority"            -Value 6  -Type DWord  -Force -EA SilentlyContinue
        Set-ItemProperty $mmAudio -Name "Scheduling Category" -Value "High" -Force   -EA SilentlyContinue
        Set-ItemProperty $mmAudio -Name "SFIO Priority"       -Value "High" -Force   -EA SilentlyContinue
        Write-Success "MMCSS Audio: SystemResponsiveness 0, Priority 6, Clock 10000"

        Write-Info "[7] Nessun tweak rete applicato nel fix DPC"
        Write-Success "Rete: lasciata invariata per scelta progettuale"
    }

    # ── FIX AVANZATO (aggiuntivo) ─────────────────────────────────────────────
    if($dpcChoice -eq "3"){
        Write-Host ""
        Write-Info "[8] MSI Interrupts: AHCI controller..."
        # MSI su controller storage riduce DPC spike da I/O
        $ahciPath = "HKLM:\SYSTEM\CurrentControlSet\Services\storahci"
        Get-ChildItem "$ahciPath\Parameters\Device" -EA SilentlyContinue | ForEach-Object {
            try{ Set-ItemProperty $_.PSPath -Name "EnableMSI" -Value 1 -Type DWord -Force -EA SilentlyContinue }catch{}
        }
        # Abilita MSI su tutti i device PCI che lo supportano
        $pciDevices = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum" -Recurse -EA SilentlyContinue |
            Where-Object { $_.PSPath -match "PCI" } |
            Select-Object -First 20  # limita per non essere lento
        foreach($dev in $pciDevices){
            try{
                $intMgmt = "$($dev.PSPath)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
                if(Test-Path $intMgmt){
                    Set-ItemProperty $intMgmt -Name "MSISupported" -Value 1 -Type DWord -Force -EA SilentlyContinue
                }
            }catch{}
        }
        Write-Success "MSI Interrupts: Abilitati su storage e PCI"

        Write-Info "[9] IRQ priority: elevata per GPU e audio..."
        # Imposta priorità IRQ più alta per schede audio
        $audioDevs = Get-CimInstance Win32_SoundDevice -EA SilentlyContinue
        foreach($aDev in $audioDevs){
            try{
                $devPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($aDev.PNPDeviceID)\Device Parameters\Interrupt Management"
                if(!(Test-Path $devPath)){New-Item $devPath -Force -EA SilentlyContinue|Out-Null}
                $msiPath = "$devPath\MessageSignaledInterruptProperties"
                if(!(Test-Path $msiPath)){New-Item $msiPath -Force -EA SilentlyContinue|Out-Null}
                Set-ItemProperty $msiPath -Name "MSISupported" -Value 1 -Type DWord -Force -EA SilentlyContinue
            }catch{}
        }
        Write-Success "IRQ Audio: MSI abilitato su dispositivi audio"

        Write-Info "[10] Clock source: nessuna modifica forzata..."
        Write-Host "  → HPET e bcdedit low-level lasciati invariati: su Windows 11 moderno conviene evitare tweak teorici." -F DarkGray
        Write-Success "Clock source: lasciata alla gestione nativa di Windows/firmware"

        Write-Info "[11] Kernel split lock: ottimizzato..."
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "GlobalTimerResolutionRequests" /t REG_DWORD /d 1 /f 2>$null|Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableLowQosTimerResolution" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        Write-Success "Kernel timer: Global timer resolution abilitato"
    }

    # ── Riepilogo ─────────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "  ════════════════════════════════════════════════════" -F Green
    $fixName = if($dpcChoice -eq "3"){"FIX AVANZATO"}else{"FIX RAPIDO"}
    Write-Host "   ✓ DPC LATENCY $fixName COMPLETATO!" -F Green
    Show-OgdAppliedSummary 'DPC'
    Write-Host "  ════════════════════════════════════════════════════`n" -F Green

    Write-Host "  📋 PROSSIMI PASSI:" -F Cyan
    Write-Host "   1. Riavvia il PC per applicare tutti i tweaks" -F White
    Write-Host "   2. Usa [1] ANALISI con LatencyMon per verificare" -F White
    Write-Host "   3. DPC < 100µs = ottimo | < 500µs = buono | > 1ms = problema" -F DarkGray
    Write-Host "   4. Se peggiora: usa [4] RESET per tornare al default`n" -F DarkGray

    if((Read-Host "  Riavviare ora? (S/N)") -in @("S","s")){ Restart-Computer -Force }
    Read-Host "  INVIO per tornare al menu"
    continue MenuLoop
}

# ═════════════════════════════════════════════════════════════════════════════
#  MODALITÀ G: NVIDIA TWEAKS
# ═════════════════════════════════════════════════════════════════════════════

if($mode -in @("G","g")){
    Show-Banner
    Write-Section "NVIDIA TWEAKS — Ottimizzazione GPU"
    Show-OgdWorkingAnimation -Text 'Analisi GPU NVIDIA...' -DurationMs 600

    # ── Rileva GPU NVIDIA ─────────────────────────────────────────────────────
    $nvGPU = Get-CimInstance Win32_VideoController | Where-Object {$_.Name -match "NVIDIA"}
    if(-not $nvGPU){
        Write-Host "`n  ⚠️  Nessuna GPU NVIDIA rilevata nel sistema`n" -F Yellow
        Write-Host "  Questi tweaks sono specifici per schede NVIDIA.`n" -F DarkGray
        Read-Host "  INVIO per tornare al menu"
        continue MenuLoop
    }

    Write-Host "`n  🟢 GPU rilevata: $($nvGPU.Name)" -F Green
    Write-Host "     Driver: $($nvGPU.DriverVersion)`n" -F DarkGray

    Write-Host "  Seleziona profilo tweaks:`n" -F Cyan
    Write-Host "  [1] ⚡ BASE - Tweaks registry safe (consigliato tutti)" -F Green
    Write-Host "      Shader cache/HAGS e pulizia base, senza forzare filtri globali o chiavi oscure`n" -F DarkGray
    Write-Host "  [2] 🎮 GAMING - Base + ottimizzazioni gaming avanzate" -F Yellow
    Write-Host "      Base + power management in AC e assetto piu coerente per il gaming`n" -F DarkGray
    Write-Host "  [3] 🔴 FULL - Gaming + opzioni nascoste registro NVIDIA" -F Red
    Write-Host "      Solo extra ancora pratici: MSI/HAGS/cleanup, senza tweak driver oscuri`n" -F DarkGray
    Write-Host "  [A] 🚀 ALL - Applica tutto (1+3)" -F Magenta
    Write-Host "      Applica il pacchetto completo e poi ti spiega in chiaro cosa ha cambiato" -F DarkGray
    Write-Host "  [R] 🔄 RESET - Ripristina valori default NVIDIA" -F DarkGray
    Write-Host "  [0] ↩️  Torna al menu`n" -F DarkGray

    $nvChoice = Read-Host "  Scelta (1/2/3/A/R/0)"
    if($nvChoice -eq "0"){ continue MenuLoop }

    $doNVBase   = ($nvChoice -in @("1","2","3","A","a"))
    $doNVGaming = ($nvChoice -in @("2","3","A","a"))
    $doNVFull   = ($nvChoice -in @("3","A","a"))
    $doNVReset  = ($nvChoice -in @("R","r"))

    # Punto ripristino
    Write-Host ""
    # Punto ripristino
    $desc="OGD NVIDIA Tweaks - $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
    New-OgdRestorePoint -Description $desc
    Write-Host ""

    # ── PERCORSI REGISTRY NVIDIA ──────────────────────────────────────────────
    $nvBase    = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}\0000"
    $nvCP      = "HKCU:\Software\NVIDIA Corporation\Global\NVTweak"
    $nvDrv     = "HKLM:\SOFTWARE\NVIDIA Corporation\Global"
    $nvProfile = "HKLM:\SOFTWARE\NVIDIA Corporation\Global\NVTweak"

    # Trova il path corretto del device NVIDIA nel registro
    $nvDevPath = $null
    $classPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}"
    Get-ChildItem $classPath -EA SilentlyContinue | ForEach-Object {
        $dDesc = (Get-ItemProperty $_.PSPath -Name "DriverDesc" -EA SilentlyContinue).DriverDesc
        if($dDesc -match "NVIDIA"){ $nvDevPath = $_.PSPath }
    }

    # ── RESET ─────────────────────────────────────────────────────────────────
    if($doNVReset){
        Write-Info "Reset valori NVIDIA al default..."
        $resetKeys = @(
            "EnableMSI","PerfLevelSrc","PowerMizerEnable","PowerMizerLevel","PowerMizerLevelAC","RMHdcpKeygroupId"
        )
        if($nvDevPath){
            foreach($k in $resetKeys){
                Remove-ItemProperty $nvDevPath -Name $k -Force -EA SilentlyContinue
            }
        }
        reg delete "HKCU\Software\NVIDIA Corporation\Global\NVTweak" /f 2>$null|Out-Null
        Write-Success "NVIDIA: Valori ripristinati al default"
        Write-Host "`n  ℹ Riavvia il PC per applicare il reset`n" -F DarkGray
        Read-Host "  INVIO per tornare al menu"
        continue MenuLoop
    }

    # ── BASE ──────────────────────────────────────────────────────────────────
    if($doNVBase){
        Write-Info "[1] NVIDIA Base tweaks..."
        Show-OgdWorkingAnimation -Text 'Applicazione tweaks NVIDIA Base...' -DurationMs 850

        # Shader Cache/HAGS: pratici e in genere innocui
        $shCache = "HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS"
        if(!(Test-Path $shCache)){New-Item $shCache -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $shCache -Name "EnableRID61684" -Value 1 -Type DWord -Force -EA SilentlyContinue
        Write-Success "Shader Cache: Ottimizzato"

        # Telemetria NVIDIA OFF (già in privacy ma lo ripeto specifico)
        if(!(Test-Path $nvDrv)){New-Item $nvDrv -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $shCache -Name "EnableRID44231" -Value 0 -Type DWord -Force -EA SilentlyContinue
        reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        Write-Success "Telemetria NVIDIA: OFF"

        $gdNv = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        Set-ItemProperty $gdNv -Name "HwSchMode" -Value 2 -Type DWord -Force -EA SilentlyContinue
        Write-Success "HAGS: ON se supportato dal driver"
        Write-Success "Filtri globali NVIDIA: lasciati controllare ai giochi/app"
    }

    # ── GAMING ────────────────────────────────────────────────────────────────
    if($doNVGaming){
        Write-Info "[2] NVIDIA Gaming tweaks..."
        Show-OgdWorkingAnimation -Text 'Applicazione tweaks NVIDIA Gaming...' -DurationMs 900

        # Power Management Mode: Prefer Maximum Performance
        if($nvDevPath){
            Set-ItemProperty $nvDevPath -Name "PerfLevelSrc"    -Value 0x2222 -Type DWord -Force -EA SilentlyContinue
            Set-ItemProperty $nvDevPath -Name "PowerMizerEnable" -Value 1     -Type DWord -Force -EA SilentlyContinue
            Set-ItemProperty $nvDevPath -Name "PowerMizerLevel"  -Value 1     -Type DWord -Force -EA SilentlyContinue
            Set-ItemProperty $nvDevPath -Name "PowerMizerLevelAC"-Value 1     -Type DWord -Force -EA SilentlyContinue
        }
        Write-Success "Power Management: massimo rendimento in AC"

        # Shader Cache/HAGS: mantieni assetto gaming coerente
        $sc2 = "HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS"
        Set-ItemProperty $sc2 -Name "EnableRID61684" -Value 1 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type DWord -Force -EA SilentlyContinue
        Write-Success "Shader Cache/HAGS: assetto gaming applicato"
    }

    # ── FULL (opzioni nascoste registro) ──────────────────────────────────────
    if($doNVFull){
        Write-Info "[3] NVIDIA Full tweaks (opzioni nascoste)..."
        Show-OgdWorkingAnimation -Text 'Applicazione tweaks NVIDIA Full...' -DurationMs 950

        if($nvDevPath){
            # MSI (Message Signaled Interrupts): abilita per GPU — riduce latenza IRQ
            Set-ItemProperty $nvDevPath -Name "EnableMSI" -Value 1 -Type DWord -Force -EA SilentlyContinue
            Write-Success "MSI Interrupts GPU: Abilitato se supportato"
        }
        # Disabilita solo la notifica tray, non il comportamento 3D globale
        reg add "HKCU\Software\NVIDIA Corporation\Global\NVTweak" /v "NvCplDisableNotificationTrayCommunications" /t REG_DWORD /d 1 /f 2>$null|Out-Null
        Write-Success "NVCP tray notifications: ridotte"
    }

    Write-Host ""
    Write-Host "  ════════════════════════════════════════════════════" -F Green
    Write-Host "   ✓ NVIDIA TWEAKS APPLICATI!" -F Green
    Show-OgdAppliedSummary 'NVIDIA'
    Write-Host "  ════════════════════════════════════════════════════`n" -F Green

    Write-Host "  📋 PROSSIMI PASSI:" -F Cyan
    Write-Host "   1. Riavvia il PC per applicare tutti i tweaks" -F White
    Write-Host "   2. Apri NVIDIA Control Panel e verifica impostazioni" -F White
    Write-Host "   3. In caso di problemi usa [G] → [R] per fare reset`n" -F DarkGray

    if((Read-Host "  Riavviare ora? (S/N)") -in @("S","s")){
        Restart-Computer -Force
    }

    Read-Host "  INVIO per tornare al menu"
    continue MenuLoop
}

# ═════════════════════════════════════════════════════════════════════════════
#  MODALITÀ P: NPU TWEAKS
# ═════════════════════════════════════════════════════════════════════════════

if($mode -in @("P","p")){
    Show-Banner
    Write-Section "NPU TWEAKS — Neural Processing Unit"
    Show-OgdWorkingAnimation -Text 'Analisi NPU / AI Boost...' -DurationMs 600

    # ── Rilevamento NPU ───────────────────────────────────────────────────────
    Write-Host ""
    Write-Info "Rilevamento NPU nel sistema..."

    $npuScan = Get-OgdNpuInfo -CpuName $cpu.Name
    $npuType = $npuScan.Type

    if($npuScan.Found){
        $srcLabel = switch -Regex ($npuScan.Source){
            "PnP-OK"       { "device fisico attivo" }
            "PnP-NotOK"    { "⚠ device presente ma driver non pronto — aggiorna il driver NPU" }
            "CPU-Intel"    { "rilevata da modello CPU (Intel Core Ultra)" }
            "CPU-AMD"      { "rilevata da modello CPU (AMD Ryzen AI)" }
            "CPU-Qualcomm" { "rilevata da modello CPU (Snapdragon X)" }
            default        { $npuScan.Source }
        }
        Write-Host "  ✅ NPU: $($npuScan.Name)" -F Green
        Write-Host "     Fonte rilevamento: $srcLabel" -F DarkGray
        Write-Host ""
        if(-not $npuScan.DriverReady){
            Write-Host '  ℹ La NPU risulta integrata/presente ma non pronta per le app.' -F Yellow
            if($npuScan.Advice){ Write-Host "    $($npuScan.Advice)`n" -F DarkGray }
        }
    } else {
        Write-Host ""
        Write-Host "  ┌─────────────────────────────────────────────────────────┐" -F Yellow
        Write-Host "  │ ⚠️  ATTENZIONE — Nessuna NPU rilevata                   │" -F Yellow
        Write-Host "  └─────────────────────────────────────────────────────────┘`n" -F Yellow
        Write-Host "  Nessuna NPU trovata. Se hai uno di questi processori" -F White
        Write-Host "  installa/aggiorna il driver NPU dal sito ufficiale:`n" -F White
        Write-Host "   • Intel Core Ultra 5/7/9 → Intel AI Boost driver" -F DarkGray
        Write-Host "   • AMD Ryzen AI 7040/8040/9000 → AMD NPU driver" -F DarkGray
        Write-Host "   • Qualcomm Snapdragon X → Qualcomm AI driver`n" -F DarkGray
        Write-Host "  Consigliato: installa il driver e riapri questo menu.`n" -F Yellow

        $npuAccept = Read-Host "  Procedere comunque con i tweaks AI generici? (S/N)"
        if($npuAccept -notin @("S","s")){
            Write-Host "`n  ↩️  Torna al menu`n" -F DarkGray
            continue MenuLoop
        }
        Write-Host ""
        Write-Host "  ℹ Verranno applicati tweaks AI generici (GPU/CPU offload)`n" -F DarkGray
    }

    Write-Host "  Seleziona ottimizzazione:`n" -F Cyan
    Write-Host "  [1] ⚡ BASE - Abilita offload AI su NPU/GPU (tutti i PC)" -F Green
    Write-Host "      Disattiva solo funzioni AI invasive/non necessarie e mantiene diagnostica pulita`n" -F DarkGray
    Write-Host "  [2] 🎮 GAMING - Base + ottimizzazioni specifiche gaming" -F Yellow
    Write-Host "      Base + alleggerimento task AI in background, senza forzare chiavi vendor incerte`n" -F DarkGray
    Write-Host "  [3] 🔬 FULL - Gaming + tutte le ottimizzazioni NPU avanzate" -F Magenta
    Write-Host "      Base + Gaming + pulizia prudente di task AI, senza registry non documentato`n" -F DarkGray
    Write-Host "  [4] 🔎 DIAGNOSTICA - Stato driver/device NPU dettagliato" -F White
    Write-Host "      Utile se hai Intel Core Ultra e le app non vedono la NPU" -F DarkGray
    Write-Host "      Ti spiega anche se la NPU è nella CPU ma non ancora pronta per le app`n" -F DarkGray
    Write-Host "  [5] 🌐 DRIVER/GUIDA - Apri pagina driver ufficiale consigliata" -F Cyan
    Write-Host "      Ti porta alla pagina corretta del driver NPU/AI del vendor`n" -F DarkGray
    Write-Host "  [R] 🔄 RESET - Ripristina impostazioni AI/NPU al default`n" -F DarkGray
    Write-Host "  [0] ↩️  Torna al menu`n" -F DarkGray

    $npuChoice = Read-Host "  Scelta (1/2/3/4/5/R/0)"
    if($npuChoice -eq "0"){ continue MenuLoop }
    if($npuChoice -eq "4"){ Show-OgdNpuDiagnostics -CpuName $cpu.Name; Read-Host '  INVIO per tornare al menu'; continue MenuLoop }
    if($npuChoice -eq "5"){
        try{
            switch($npuScan.Type){
                'intel'     { Start-Process 'https://www.intel.com/content/www/us/en/download/794734/intel-npu-driver-windows.html' }
                'amd'       { Start-Process 'https://www.amd.com/en/support' }
                'qualcomm'  { Start-Process 'https://www.qualcomm.com/support' }
                default     { Start-Process 'https://learn.microsoft.com/en-us/windows/ai/npu-devices/' }
            }
        }catch{}
        Write-Info 'Aperta la pagina guida/driver consigliata per la tua piattaforma'
        Read-Host '  INVIO per tornare al menu'
        continue MenuLoop
    }

    $doNPUBase   = ($npuChoice -in @("1","2","3"))
    $doNPUGaming = ($npuChoice -in @("2","3"))
    $doNPUFull   = ($npuChoice -eq "3")
    $doNPUReset  = ($npuChoice -in @("R","r"))

    # Punto ripristino
    Write-Host ""
    # Punto ripristino
    $desc="OGD NPU Tweaks - $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
    New-OgdRestorePoint -Description $desc
    Write-Host ""

    # ── RESET ─────────────────────────────────────────────────────────────────
    if($doNPUReset){
        Write-Info "Reset NPU/AI impostazioni..."
        $aiPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AIOptimization"
        if(Test-Path $aiPath){ Remove-Item $aiPath -Recurse -Force -EA SilentlyContinue }
        $aiUser = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
        if(Test-Path $aiUser){ Remove-Item $aiUser -Recurse -Force -EA SilentlyContinue }
        reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AI" /f 2>$null|Out-Null
        reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\AI" /f 2>$null|Out-Null
        Write-Success "NPU/AI: Valori ripristinati al default"
        Read-Host "  INVIO per tornare al menu"
        continue MenuLoop
    }

    # ── BASE ──────────────────────────────────────────────────────────────────
    if($doNPUBase){
        Write-Info "[NPU1] Pulizia AI di base..."
        Show-OgdWorkingAnimation -Text 'Applicazione NPU Base...' -DurationMs 850

        # Disabilita Recall e Windows AI data collection (privacy + performance)
        $winAI = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
        if(!(Test-Path $winAI)){New-Item $winAI -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $winAI -Name "DisableAIDataAnalysis"         -Value 1 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $winAI -Name "TurnOffSavingSnapshots"        -Value 1 -Type DWord -Force -EA SilentlyContinue
        Write-Success "Windows AI invasive features: OFF"
        Write-Success "NPU/Base: nessun forcing registry non documentato"
    }

    # ── GAMING ────────────────────────────────────────────────────────────────
    if($doNPUGaming){
        Write-Info "[NPU2] NPU ottimizzato per gaming..."
        Show-OgdWorkingAnimation -Text 'Applicazione NPU Gaming...' -DurationMs 900

Write-Host "  → Il ramo 8.1.2 evita chiavi NPU vendor-specific non documentate." -F DarkGray
        Disable-ScheduledTask -TaskName "Microsoft\Windows\AI\AISettingsSync" -EA SilentlyContinue | Out-Null
        Write-Success "Task AI non essenziali: alleggeriti dove disponibili"
        Write-Success "NPU/Gaming: mantenuta solo la parte realmente prudente"
    }

    # ── FULL ──────────────────────────────────────────────────────────────────
    if($doNPUFull){
        Write-Info "[NPU3] NPU avanzato — consolidamento prudente..."
        Show-OgdWorkingAnimation -Text 'Applicazione NPU Full...' -DurationMs 950
        Write-Host "  → Le prestazioni NPU reali dipendono soprattutto da driver, firmware e app compatibili." -F DarkGray
        Write-Info "[NPU4] Scheduled Tasks AI: disabilita idle tasks..."
        $aiTasks = @(
            "Microsoft\Windows\ApplicationModel\CortanaCore",
            "Microsoft\Windows\WS\WSTask",
            "Microsoft\Windows\AI\AISettingsSync"
        )
        foreach($t in $aiTasks){
            Disable-ScheduledTask -TaskName $t -EA SilentlyContinue | Out-Null
        }
        Write-Success "AI Scheduled Tasks: alleggeriti dove presenti"
    }

    Write-Host ""
    Write-Host "  ════════════════════════════════════════════════════" -F Green
    Write-Host "   ✓ NPU TWEAKS COMPLETATI!" -F Green
    Show-OgdAppliedSummary 'NPU'
    Write-Host "  ════════════════════════════════════════════════════`n" -F Green
    Write-Host "  ℹ Riavvia il PC per applicare completamente" -F DarkGray
    Write-Host "  ℹ Usa [R] RESET per tornare al default se necessario`n" -F DarkGray

    if((Read-Host "  Riavviare ora? (S/N)") -in @("S","s")){ Restart-Computer -Force }
    Read-Host "  INVIO per tornare al menu"
    continue MenuLoop
}

# ═════════════════════════════════════════════════════════════════════════════
#  MODALITÀ E: UNREAL ENGINE TWEAKS (UE4 / UE5)
# ═════════════════════════════════════════════════════════════════════════════

if($mode -in @("E","e")){
    Show-Banner
    Write-Section "UNREAL ENGINE TWEAKS — UE4 / UE5.x"

    Write-Host "`n  🎮 Ottimizzazioni per sviluppo e gaming con Unreal Engine`n" -F Cyan
    Write-Host "  Copre:" -F White
    Write-Host "   • Compilazione shader (riduce tempi drasticamente)" -F DarkGray
    Write-Host "   • Streaming assets UE5 (Nanite, Lumen, VSM)" -F DarkGray
    Write-Host "   • Memoria virtuale e cache prudente per progetti grandi" -F DarkGray
    Write-Host "   • CPU/GPU scheduler senza tweak undocumented" -F DarkGray
    Write-Host "   • I/O asincrono e cache disco" -F DarkGray
    Write-Host "   • DirectX 12 / Vulkan ottimizzazioni`n" -F DarkGray

    Write-Host "  [1] 🔧 DEVELOPER - Ottimizzazioni per chi sviluppa in UE4/UE5" -F Green
    Write-Host "      Shader compile, iterazione veloce, memoria editor`n" -F DarkGray
    Write-Host "  [2] 🎮 GAMING - Ottimizzazioni per giocare a giochi UE4/UE5" -F Yellow
    Write-Host "      Streaming, stuttering fix, DX12, shader cache`n" -F DarkGray
    Write-Host "  [3] 🚀 FULL - Developer + Gaming (tutto)" -F Magenta
    Write-Host "      Consigliato per dev che testano anche i propri giochi`n" -F DarkGray
    Write-Host "  [R] 🔄 RESET - Ripristina valori default`n" -F DarkGray
    Write-Host "  [0] ↩️  Torna al menu`n" -F DarkGray

    $ueChoice = Read-Host "  Scelta (1/2/3/R/0)"
    if($ueChoice -eq "0"){ continue MenuLoop }

    $doUEDev   = ($ueChoice -in @("1","3"))
    $doUEGame  = ($ueChoice -in @("2","3"))
    $doUEReset = ($ueChoice -in @("R","r"))

    Write-Host ""

    # Punto ripristino
    # Punto ripristino
    $desc="OGD Unreal Engine Tweaks - $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
    New-OgdRestorePoint -Description $desc
    Write-Host ""

    # ── RESET ─────────────────────────────────────────────────────────────────
    if($doUEReset){
        Write-Info "Reset Unreal Engine tweaks..."
        # Rimuove chiavi UE dal registro
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched"   /v "NonBestEffortLimit" /f 2>$null|Out-Null
        reg delete "HKCU\Software\Epic Games\Unreal Engine\Identifiers" /f 2>$null|Out-Null
        # Ripristina process priority UE
        $ueExes = @("UnrealEditor.exe","UE4Editor.exe","ShaderCompileWorker.exe","UnrealBuildTool.exe","UE4Game.exe","UnrealGame.exe")
        foreach($ex in $ueExes){
            $rp = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$ex\PerfOptions"
            if(Test-Path $rp){ Remove-Item $rp -Recurse -Force -EA SilentlyContinue }
        }
        Write-Success "Unreal Engine tweaks: ripristinati al default"
        Read-Host "  INVIO per tornare al menu"
        continue MenuLoop
    }

    # ── DEVELOPER ─────────────────────────────────────────────────────────────
    if($doUEDev){
        Write-Info "[UE-DEV1] Shader Compile Workers — priorità CPU massima..."
        # ShaderCompileWorker usa tutti i core — dargli priorità alta riduce i tempi
        # di compilazione shader da 30+ min a meno di 10 min su CPU moderna
        $scwPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ShaderCompileWorker.exe\PerfOptions"
        if(!(Test-Path $scwPath)){New-Item $scwPath -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $scwPath -Name "CpuPriorityClass" -Value 3 -Type DWord -Force -EA SilentlyContinue  # High
        Set-ItemProperty $scwPath -Name "IoPriority"       -Value 3 -Type DWord -Force -EA SilentlyContinue  # High

        # UnrealBuildTool — compilazione C++ a priorità alta
        $ubtPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\UnrealBuildTool.exe\PerfOptions"
        if(!(Test-Path $ubtPath)){New-Item $ubtPath -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $ubtPath -Name "CpuPriorityClass" -Value 3 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $ubtPath -Name "IoPriority"       -Value 3 -Type DWord -Force -EA SilentlyContinue

        # UnrealEditor stesso — priorità AboveNormal
        $uePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\UnrealEditor.exe\PerfOptions"
        if(!(Test-Path $uePath)){New-Item $uePath -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $uePath -Name "CpuPriorityClass" -Value 6 -Type DWord -Force -EA SilentlyContinue  # AboveNormal
        Set-ItemProperty $uePath -Name "IoPriority"       -Value 3 -Type DWord -Force -EA SilentlyContinue

        # UE4Editor legacy
        $ue4Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\UE4Editor.exe\PerfOptions"
        if(!(Test-Path $ue4Path)){New-Item $ue4Path -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $ue4Path -Name "CpuPriorityClass" -Value 6 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $ue4Path -Name "IoPriority"       -Value 3 -Type DWord -Force -EA SilentlyContinue

        Write-Success "Process priority: Editor AboveNormal, ShaderCompile/UBT High"

        Write-Info "[UE-DEV2] Memoria per progetti grandi (UE5 richiede molto)..."
        $mp="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

Write-Host "  → Il ramo 8.1.2 non forza pagefile o heap tweaks: meglio lasciare gestione automatica salvo casi speciali." -F DarkGray
        Write-Success "Memoria virtuale: nessun forcing globale applicato"

        Write-Info "[UE-DEV3] I/O asincrono e cache disco per asset streaming..."
        # NTFS: ottimizzazioni per accesso rapido ai file .uasset/.umap
        fsutil behavior set disablelastaccess  1 2>$null|Out-Null
        fsutil behavior set disable8dot3       1 2>$null|Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "LongPathsEnabled" /t REG_DWORD /d 1 /f 2>$null|Out-Null

        Write-Success "I/O: NTFS piu snello, long paths ON"
    }

    # ── GAMING ────────────────────────────────────────────────────────────────
    if($doUEGame){
        Write-Info "[UE-GAME1] Shader cache massimizzata (fix stuttering UE)..."
        # Lo stuttering più comune nei giochi UE è dovuto alla compilazione
        # shader a runtime — una cache grande riduce o elimina questo problema

        # DirectX Shader Cache: massimizza dimensione
        $dxCache = "HKCU:\SOFTWARE\Microsoft\Direct3D"
        if(!(Test-Path $dxCache)){New-Item $dxCache -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $dxCache -Name "ShaderCacheSize"    -Value 4096 -Type DWord -Force -EA SilentlyContinue  # 4GB cache
        Set-ItemProperty $dxCache -Name "D3D12ShaderCacheSize" -Value 4096 -Type DWord -Force -EA SilentlyContinue

        # NVIDIA shader cache (se presente)
        $nvFTS = "HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS"
        if(!(Test-Path $nvFTS)){New-Item $nvFTS -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $nvFTS -Name "EnableRID61684" -Value 1 -Type DWord -Force -EA SilentlyContinue  # Unlimited shader cache

        # GPU: lascia TDR prudente
        $gd2="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        Set-ItemProperty $gd2 -Name "HwSchMode"   -Value 2  -Type DWord -Force -EA SilentlyContinue

        Write-Success "Shader cache: DX12 4GB, NVIDIA cache, HAGS ON se supportato"

        Write-Info "[UE-GAME2] Memory streaming ottimizzato (Nanite + Lumen UE5)..."
        # UE5 con Nanite e Lumen fa streaming massiccio di asset — I/O critico
        $mp2="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        Set-ItemProperty $mp2 -Name "LargeSystemCache"       -Value 0 -Type DWord -Force -EA SilentlyContinue
        # I/O priority alta per processi UE in-game
        foreach($ueExe in @("UnrealGame.exe","UE4Game.exe","UnrealEditor.exe")){
            $rp3="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$ueExe\PerfOptions"
            if(!(Test-Path $rp3)){New-Item $rp3 -Force -EA SilentlyContinue|Out-Null}
            Set-ItemProperty $rp3 -Name "CpuPriorityClass" -Value 3 -Type DWord -Force -EA SilentlyContinue  # High
            Set-ItemProperty $rp3 -Name "IoPriority"       -Value 3 -Type DWord -Force -EA SilentlyContinue  # High
        }
        Write-Success "Memory/I-O: cache prudente, priorita alta per executable UE"

        Write-Info "[UE-GAME3] DirectX 12 + Vulkan ottimizzazioni UE5..."
        # Flip Model ottimizzato per UE5 (riduce latency presentazione frame)
        reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "SwapEffectUpgradeEnable=1;VRROptimizeEnable=0;" /f 2>$null|Out-Null

        Write-Success "DX12: Flip Model ON, niente tweak heap/preemption undocumented"

        Write-Info "[UE-GAME4] CPU boost per microstutter UE (WorldPartition / HLOD)..."
        # UE5 WorldPartition carica/scarica livelli dinamicamente — CPU spikes
        # Boost mode moderato riduce i tempi di risposta durante loading asincrono
        $pgUE=(powercfg /getactivescheme) -match 'GUID:\s+([a-f0-9\-]+)'
        if($pgUE){$pgUE=$Matches[1]}else{$pgUE="SCHEME_CURRENT"}
        powercfg /setacvalueindex $pgUE SUB_PROCESSOR PERFBOOSTMODE    1  2>$null
        powercfg /setacvalueindex $pgUE SUB_PROCESSOR PROCTHROTTLEMIN  5  2>$null
        powercfg /setacvalueindex $pgUE SUB_PROCESSOR PERFINCTIME      1  2>$null
        powercfg /setacvalueindex $pgUE SUB_PROCESSOR PERFDECTIME      1  2>$null
        powercfg /setactive $pgUE 2>$null
        Write-Success "CPU: boost moderato e reattivo per streaming UE"

        Write-Info "[UE-GAME5] MMCSS gaming + audio priorità per UE..."
        $mmUE = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Set-ItemProperty $mmUE -Name "SystemResponsiveness"   -Value 0          -Type DWord -Force -EA SilentlyContinue
        $mmTasksUE = "$mmUE\Tasks\Games"
        Set-ItemProperty $mmTasksUE -Name "Priority"            -Value 6     -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $mmTasksUE -Name "GPU Priority"        -Value 8     -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $mmTasksUE -Name "Scheduling Category" -Value "High"            -Force -EA SilentlyContinue
        Set-ItemProperty $mmTasksUE -Name "Clock Rate"          -Value 10000 -Type DWord -Force -EA SilentlyContinue
        Write-Success "MMCSS: Games Priority 6, GPU 8, SystemResponsiveness 0"

        Write-Info "[UE-GAME6] Game Mode + DVR OFF per UE games..."
        reg add "HKCU\Software\Microsoft\GameBar"               /v "AutoGameModeEnabled" /t REG_DWORD /d 1 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore"                   /v "GameDVR_Enabled"     /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR"    /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode"          /t REG_DWORD /d 2 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 1 /f 2>$null|Out-Null
        Write-Success "Game Mode ON, DVR OFF, FSE ottimizzato"
    }

    Write-Host ""
    Write-Host "  ════════════════════════════════════════════════════" -F Green
    $ueName = switch($ueChoice){"1"{"DEVELOPER"}"2"{"GAMING"}default{"FULL"}}
    Write-Host "   ✓ UNREAL ENGINE TWEAKS ($ueName) COMPLETATI!" -F Green
    Show-OgdAppliedSummary 'UNREAL'
    Write-Host "  ════════════════════════════════════════════════════`n" -F Green

    Write-Host "  📋 CONSIGLI AGGIUNTIVI:" -F Cyan
    Write-Host "   • Aggiungi le cartelle UE all'esclusione di Windows Defender" -F White
    Write-Host "     (Impostazioni → Virus e minacce → Esclusioni → Aggiungi)" -F DarkGray
    Write-Host "   • UE5: abilita DX12 nel progetto (Project Settings → Rendering)" -F White
    Write-Host "   • UE5: Virtual Shadow Maps + Lumen richiedono GPU DX12 tier2+" -F White
    Write-Host "   • Usa SSD NVMe per la cartella Intermediate (shader compile)" -F DarkGray
    Write-Host "   • UE5 Nanite: abilita 'r.Nanite 1' nella console di gioco`n" -F DarkGray

    if((Read-Host "  Riavviare ora? (S/N)") -in @("S","s")){ Restart-Computer -Force }
    Read-Host "  INVIO per tornare al menu"
    continue MenuLoop
}

# ═════════════════════════════════════════════════════════════════════════════
#  MODALITÀ C: CALL OF DUTY TWEAKS (MW1 → Black Ops 7)
# ═════════════════════════════════════════════════════════════════════════════

if($mode -in @("C","c")){
    Show-Banner
    Write-Section "CALL OF DUTY TWEAKS — MW1 → Black Ops 7"

    Write-Host "`n  🔫 Ottimizzazioni Windows per Call of Duty`n" -F Red
    Write-Host "  ⚠️  IMPORTANTE — COSA NON FA QUESTO MENU:" -F Yellow
    Write-Host "   • Nessuna modifica ai file di gioco" -F DarkGray
    Write-Host "   • Nessuna modifica alla memoria del processo" -F DarkGray
    Write-Host "   • Nessun bypass anti-cheat (RICOCHET)" -F DarkGray
    Write-Host "   • Nessun config editing che dia vantaggi gameplay" -F DarkGray
    Write-Host "   Tutto ciò che fa questo menu è a livello Windows — 100% safe`n" -F DarkGray

    Write-Host "  Titoli supportati:" -F Cyan
    Write-Host "   MW (2019) | MW2 | MW3 | Warzone | Vanguard" -F DarkGray
    Write-Host "   Cold War | Black Ops 6 | Black Ops 7`n" -F DarkGray

    Write-Host "  [1] ⚡ BASE - Priorità processo + overlays OFF (tutti i CoD)" -F Green
    Write-Host "      Safe su qualsiasi titolo CoD`n" -F DarkGray
    Write-Host "  [2] 🌐 NETWORK - Latenza e packet loss (tutti i CoD)" -F Yellow
    Write-Host "      Nessun tweak rete: la configurazione rete resta manuale`n" -F DarkGray
    Write-Host "  [3] 🔴 BLACK OPS 7 - Tweaks specifici BO7 (priorità)" -F Red
    Write-Host "      Ottimizzazioni specifiche per BO7 senza tweak nascosti o anti-cheat-risky`n" -F DarkGray
    Write-Host "  [A] 🚀 ALL - Applica tutto (1+2+3)" -F Magenta
    Write-Host "  [R] 🔄 RESET - Ripristina valori default`n" -F DarkGray
    Write-Host "  [0] ↩️  Torna al menu`n" -F DarkGray

    $codChoice = Read-Host "  Scelta (1/2/3/A/R/0)"
    if($codChoice -eq "0"){ continue MenuLoop }

    $doCODBase    = ($codChoice -in @("1","A","a"))
    $doCODNet     = ($codChoice -in @("2","A","a"))
    $doCODBO7     = ($codChoice -in @("3","A","a"))
    $doCODReset   = ($codChoice -in @("R","r"))

    Write-Host ""
    # Punto ripristino
    $desc="OGD CoD Tweaks - $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
    New-OgdRestorePoint -Description $desc
    Write-Host ""

    # ── RESET ─────────────────────────────────────────────────────────────────
    if($doCODReset){
        Write-Info "Reset CoD tweaks..."
        $codExes = @(
            "cod.exe","cod_launcher.exe","BlackOps7.exe","BlackOps7_Launcher.exe",
            "ModernWarfare.exe","ModernWarfare2.exe","ModernWarfare3.exe",
            "Warzone.exe","cod-cold-war.exe","Vanguard.exe","BlackOps6.exe",
            "bg3.exe"  # non CoD ma per sicurezza non tocchiamo altri giochi
        )
        foreach($ex in $codExes){
            $rp="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$ex\PerfOptions"
            if(Test-Path $rp){ Remove-Item $rp -Recurse -Force -EA SilentlyContinue }
        }
        # Rimuovi QoS policy CoD
        $qosCod = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\CoD Gaming"
        if(Test-Path $qosCod){ Remove-Item $qosCod -Recurse -Force -EA SilentlyContinue }
        Write-Success "CoD tweaks: ripristinati al default"
        Read-Host "  INVIO per tornare al menu"
        continue MenuLoop
    }

    # ── BASE: Process priority + Overlays OFF ─────────────────────────────────
    if($doCODBase){
        Write-Info "[COD1] Process priority coerente per executables CoD..."

        # Lista completa executables CoD da MW2019 a BO7
        $codProcs = @{
            # Black Ops 7 (priorità massima)
            "BlackOps7.exe"           = @{P=3;I=3}   # High CPU, High I/O
            "BlackOps7_Launcher.exe"  = @{P=6;I=2}   # AboveNormal
            # Black Ops 6
            "BlackOps6.exe"           = @{P=3;I=3}
            # Cold War
            "cod-cold-war.exe"        = @{P=3;I=3}
            # Modern Warfare (2019/2022/2023)
            "ModernWarfare.exe"       = @{P=3;I=3}
            "ModernWarfare2.exe"      = @{P=3;I=3}
            "ModernWarfare3.exe"      = @{P=3;I=3}
            # Warzone
            "Warzone.exe"             = @{P=3;I=3}
            # Vanguard
            "Vanguard.exe"            = @{P=3;I=3}
            # Launcher Battle.net
            "Battle.net.exe"          = @{P=6;I=2}   # AboveNormal
            "Agent.exe"               = @{P=2;I=1}   # Normal, Low I/O
            # Shader compile CoD (IW engine)
            "cod.exe"                 = @{P=3;I=3}
        }
        foreach($ex in $codProcs.Keys){
            $pi = $codProcs[$ex]
            $rp = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$ex\PerfOptions"
            if(!(Test-Path $rp)){New-Item $rp -Force -EA SilentlyContinue|Out-Null}
            Set-ItemProperty $rp -Name "CpuPriorityClass" -Value $pi.P -Type DWord -Force -EA SilentlyContinue
            Set-ItemProperty $rp -Name "IoPriority"       -Value $pi.I -Type DWord -Force -EA SilentlyContinue
        }
        Write-Success "Process priority: CoD executables High, launcher AboveNormal"

        Write-Info "[COD2] Xbox Game Bar/DVR OFF (causa stuttering in CoD)..."
        # Xbox Game Bar e DVR — principali cause di stutter in CoD
        # Discord e NVIDIA overlay lasciati attivi (utili per comunicazione e stats)
        reg add "HKCU\Software\Microsoft\GameBar"               /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore"                   /v "GameDVR_Enabled"            /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR"           /t REG_DWORD /d 0 /f 2>$null|Out-Null
        Write-Success "Xbox DVR: OFF | Discord overlay: ✓ lasciato attivo | NVIDIA overlay: ✓ lasciato attivo"

        Write-Info "[COD3] Game Mode + Fullscreen Exclusive ottimizzato..."
        reg add "HKCU\Software\Microsoft\GameBar"     /v "AutoGameModeEnabled"          /t REG_DWORD /d 1 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore"         /v "GameDVR_FSEBehaviorMode"       /t REG_DWORD /d 2 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore"         /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 1 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore"         /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d 1 /f 2>$null|Out-Null
        Write-Success "Game Mode ON, FSE ottimizzato"

        Write-Info "[COD4] Fix crash Discord screen share + minimize/restore..."
        # Il crash avviene perché CoD usa Fullscreen Exclusive — quando Discord
        # cattura lo schermo o quando minimizzi, Windows resetta il contesto DX12
        # La soluzione è forzare DXGI Flip Model (Borderless Windowed-like behavior)
        # mantenendo le performance del fullscreen ma senza perdere il contesto DX

        # Forza DirectX Flip Presentation — evita il reset contesto DX su focus loss
        reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "SwapEffectUpgradeEnable=1;VRROptimizeEnable=0;" /f 2>$null|Out-Null

        # TDR aumentato — evita crash GPU quando Discord cattura (causa spike breve)
        $gdCOD="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        Set-ItemProperty $gdCOD -Name "TdrDelay"         -Value 10 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $gdCOD -Name "TdrDdiDelay"      -Value 10 -Type DWord -Force -EA SilentlyContinue

        # Hardware Accelerated GPU Scheduling ON — Discord usa HAGS per la cattura
        # con HAGS attivo Discord può catturare senza interrompere il render di CoD
        Set-ItemProperty $gdCOD -Name "HwSchMode" -Value 2 -Type DWord -Force -EA SilentlyContinue

        # Disabilita fullscreen optimization forzata che causa conflitto con Discord
        reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode"                   /t REG_DWORD /d 2 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible"     /t REG_DWORD /d 1 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEBehaviorMode"                  /t REG_DWORD /d 0 /f 2>$null|Out-Null

        Write-Success "Crash fix: Flip Model ON, TDR prudente, HAGS ON"
        Write-Host "  ℹ In-game: imposta Display Mode su 'Borderless Windowed' per fix definitivo" -F Yellow
        Write-Host "  ℹ In Discord: Impostazioni → Avanzate → usa 'H264 hardware' per cattura`n" -F DarkGray

        Write-Info "[COD4] MMCSS priorità massima per CoD..."
        $mmCoD = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Set-ItemProperty $mmCoD -Name "SystemResponsiveness"   -Value 0          -Type DWord -Force -EA SilentlyContinue
        $mmGames = "$mmCoD\Tasks\Games"
        Set-ItemProperty $mmGames -Name "Priority"            -Value 6     -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $mmGames -Name "GPU Priority"        -Value 8     -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $mmGames -Name "Scheduling Category" -Value "High"            -Force -EA SilentlyContinue
        Set-ItemProperty $mmGames -Name "Clock Rate"          -Value 10000 -Type DWord -Force -EA SilentlyContinue
        Write-Success "MMCSS: Games Priority 6, GPU 8, SystemResponsiveness 0"

        Write-Info "[COD5] USB Suspend OFF (no spike input durante le partite)..."
        $pgCoD=(powercfg /getactivescheme) -match 'GUID:\s+([a-f0-9\-]+)'
        if($pgCoD){$pgCoD=$Matches[1]}else{$pgCoD="SCHEME_CURRENT"}
        powercfg /setacvalueindex $pgCoD 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
        powercfg /setactive $pgCoD 2>$null
        Write-Success "USB Selective Suspend: OFF"
    }

    # ── NETWORK: sezione ritirata ─────────────────────────────────────────────
    if($doCODNet){
        Write-Info "[COD-NET] Sezione rete ritirata: nessun tweak TCP/IP o QoS applicato"
        Write-Success "Rete CoD: lasciata interamente a gestione manuale utente"
    }

    # ── BLACK OPS 7 — Tweaks specifici ───────────────────────────────────────
    if($doCODBO7){
        Write-Host ""
        Write-Section "BLACK OPS 7 — TWEAKS SPECIFICI"
        Write-Host ""

        Write-Info "[BO7-1] Process priority BO7 — profilo coerente..."
        # BO7 usa IW engine evoluto — stessi exe pattern di BO6 ma aggiornati
        $bo7Exes = @("BlackOps7.exe","BlackOps7_Launcher.exe","cod.exe","cod_launcher.exe")
        foreach($ex in $bo7Exes){
            $rp7 = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$ex\PerfOptions"
            if(!(Test-Path $rp7)){New-Item $rp7 -Force -EA SilentlyContinue|Out-Null}
            Set-ItemProperty $rp7 -Name "CpuPriorityClass" -Value 3 -Type DWord -Force -EA SilentlyContinue  # High
            Set-ItemProperty $rp7 -Name "IoPriority"       -Value 3 -Type DWord -Force -EA SilentlyContinue  # High
        }
        Write-Success "BO7: Process priority High per tutti gli executables"

        Write-Info "[BO7-2] GPU ottimizzato per BO7 (IW engine DX12)..."
        # BO7 usa DX12 natively — ottimizza per DX12
        $gd7="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        Set-ItemProperty $gd7 -Name "HwSchMode"       -Value 2  -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $gd7 -Name "TdrDelay"         -Value 10 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $gd7 -Name "TdrDdiDelay"      -Value 10 -Type DWord -Force -EA SilentlyContinue
        # DirectX Flip Model — riduce latenza presentazione frame in BO7
        reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "SwapEffectUpgradeEnable=1;VRROptimizeEnable=0;" /f 2>$null|Out-Null
        # Shader cache BO7 — riduce shader stutter
        $dxC7 = "HKCU:\SOFTWARE\Microsoft\Direct3D"
        if(!(Test-Path $dxC7)){New-Item $dxC7 -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $dxC7 -Name "ShaderCacheSize"      -Value 4096 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $dxC7 -Name "D3D12ShaderCacheSize" -Value 4096 -Type DWord -Force -EA SilentlyContinue
        Write-Success "GPU BO7: HAGS ON, Flip Model, Shader Cache 4GB"

        Write-Info "[BO7-3] CPU scheduling ottimizzato per BO7..."
        # BO7 è multithread-heavy — usa profilo scheduler conservativo
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 0x26 /f 2>$null|Out-Null
        # Power Throttling: meglio lasciare gestione nativa
        $ptpBO7 = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
        if(!(Test-Path $ptpBO7)){New-Item $ptpBO7 -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $ptpBO7 -Name "PowerThrottlingOff" -Value 0 -Type DWord -Force -EA SilentlyContinue
        # CPU Boost: bilanciato per risposta rapida senza tenere il processore inchiodato in alto
        $pgBO7=(powercfg /getactivescheme) -match 'GUID:\s+([a-f0-9\-]+)'
        if($pgBO7){$pgBO7=$Matches[1]}else{$pgBO7="SCHEME_CURRENT"}
        powercfg /setacvalueindex $pgBO7 SUB_PROCESSOR PERFBOOSTMODE    1  2>$null
        powercfg /setacvalueindex $pgBO7 SUB_PROCESSOR PROCTHROTTLEMIN  5  2>$null
        powercfg /setacvalueindex $pgBO7 SUB_PROCESSOR PERFINCTIME      1  2>$null
        powercfg /setacvalueindex $pgBO7 SUB_PROCESSOR PERFDECTIME      1  2>$null
        powercfg /setactive $pgBO7 2>$null
        Write-Success "CPU BO7: quantum gaming, throttle nativo, boost bilanciato"

        Write-Info "[BO7-4] Consolidamento compatibilita BO7..."
        $mp7 = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        Set-ItemProperty $mp7 -Name "DisablePagingExecutive" -Value 0 -Type DWord -Force -EA SilentlyContinue
        Write-Success "BO7: compatibilita renderer e memory management prudente"

        Write-Info "[BO7-5] Disabilita servizi che interferiscono con RICOCHET..."
        # Servizi che possono causare falsi positivi o interferire con anti-cheat
        # (non li disabilitiamo — solo abbassamo priorità I/O)
        $antiInterfer = @("DiagTrack","WSearch","SysMain","dmwappushservice")
        foreach($svc in $antiInterfer){
            try{
                $rp8 = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$svc.exe\PerfOptions"
                if(!(Test-Path $rp8)){New-Item $rp8 -Force -EA SilentlyContinue|Out-Null}
                Set-ItemProperty $rp8 -Name "IoPriority" -Value 0 -Type DWord -Force -EA SilentlyContinue
            }catch{}
        }
        Write-Success "Servizi background: I/O priority minima (meno interferenze con RICOCHET)"

        Write-Info "[BO7-6] Ottimizzazione audio per footstep audio accuracy..."
        # BO7 ha audio basato su posizione — latenza audio bassa è critica
        $mmAu7 = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio"
        if(!(Test-Path $mmAu7)){New-Item $mmAu7 -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $mmAu7 -Name "Affinity"            -Value 0     -Type DWord  -Force -EA SilentlyContinue
        Set-ItemProperty $mmAu7 -Name "Background Only"     -Value "False"            -Force  -EA SilentlyContinue
        Set-ItemProperty $mmAu7 -Name "Clock Rate"          -Value 10000 -Type DWord  -Force -EA SilentlyContinue
        Set-ItemProperty $mmAu7 -Name "GPU Priority"        -Value 8     -Type DWord  -Force -EA SilentlyContinue
        Set-ItemProperty $mmAu7 -Name "Priority"            -Value 6     -Type DWord  -Force -EA SilentlyContinue
        Set-ItemProperty $mmAu7 -Name "Scheduling Category" -Value "High"             -Force  -EA SilentlyContinue
        Set-ItemProperty $mmAu7 -Name "SFIO Priority"       -Value "High"             -Force  -EA SilentlyContinue
        # Disabilita audio enhancements (causano latenza audio)
        reg add "HKCU\Software\Microsoft\Multimedia\Audio" /v "UserDuckingPreference" /t REG_DWORD /d 3 /f 2>$null|Out-Null
        Write-Success "Audio BO7: MMCSS Clock 10000, Priority 6, enhancements OFF (footstep accuracy)"
    }

    # ── Riepilogo ─────────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "  ════════════════════════════════════════════════════" -F Red
    Write-Host "   🔫 CALL OF DUTY TWEAKS COMPLETATI!" -F Red
    Show-OgdAppliedSummary 'COD'
    Write-Host "  ════════════════════════════════════════════════════`n" -F Green

    Write-Host "  📋 CONSIGLI IN-GAME (da fare manualmente):" -F Cyan
    Write-Host "   • BO7: Texture Quality → Bassa/Media (meno VRAM spike)" -F White
    Write-Host "   • BO7: Rendering Mode → Performance o Balanced" -F White
    Write-Host "   • BO7: V-Sync → OFF | Frame Rate Limit → quello del tuo monitor" -F White
    Write-Host "   • BO7: Shader Pre-loading → ON (esegui prima di giocare)" -F White
    Write-Host "   • Tutti i CoD: NVIDIA Reflex → ON + Boost (se disponibile)" -F White
    Write-Host "   • Warzone/BO7: Cache Spot → SSD (non HDD)`n" -F DarkGray
    Write-Host "  ⚠️  RICORDA: quando uscirà il prossimo CoD aggiorna via OGD!" -F Yellow
    Write-Host "     (Segnala su Discord quando è disponibile)`n" -F DarkGray

    if((Read-Host "  Riavviare ora? (S/N)") -in @("S","s")){ Restart-Computer -Force }
    Read-Host "  INVIO per tornare al menu"
    continue MenuLoop
}

# ═════════════════════════════════════════════════════════════════════════════
#  MODALITÀ M: MOUSE — Accelerazione e precisione
# ═════════════════════════════════════════════════════════════════════════════

if($mode -in @("M","m")){
    Show-Banner
    Write-Section "MOUSE — Accelerazione e precisione"

    # ── Legge stato attuale ───────────────────────────────────────────────────
    $mSpeed = (Get-ItemProperty "HKCU:\Control Panel\Mouse" -Name "MouseSpeed"      -EA SilentlyContinue).MouseSpeed
    $mThr1  = (Get-ItemProperty "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -EA SilentlyContinue).MouseThreshold1
    $mThr2  = (Get-ItemProperty "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -EA SilentlyContinue).MouseThreshold2
    $mTrails= (Get-ItemProperty "HKCU:\Control Panel\Mouse" -Name "MouseTrails"     -EA SilentlyContinue).MouseTrails

    # Curva accelerazione Enhanced Pointer Precision (EPP)
    $eppPath  = "HKCU:\Control Panel\Mouse"
    $eppVal   = (Get-ItemProperty $eppPath -Name "MouseSensitivity" -EA SilentlyContinue).MouseSensitivity
    $smoothX  = (Get-ItemProperty $eppPath -Name "SmoothMouseXCurve" -EA SilentlyContinue).SmoothMouseXCurve
    $smoothY  = (Get-ItemProperty $eppPath -Name "SmoothMouseYCurve" -EA SilentlyContinue).SmoothMouseYCurve

    $accActive = ($mSpeed -ne "0" -or $mThr1 -ne "0" -or $mThr2 -ne "0")
    $eppActive = ($null -ne $smoothX)

    Write-Host ""
    Write-Host "  📊 STATO ATTUALE:" -F Cyan
    Write-Host "     Accelerazione (MouseSpeed):  $(if($mSpeed -eq '0'){'🟢 OFF (lineare)'}else{'🔴 ON'})" -F White
    Write-Host "     MouseThreshold1:             $mThr1  (0 = disattiva primo scalino)" -F DarkGray
    Write-Host "     MouseThreshold2:             $mThr2  (0 = disattiva secondo scalino)" -F DarkGray
    Write-Host "     Enhanced Pointer Precision:  $(if($eppActive){'⚠️  Curva personalizzata'}else{'Standard'})" -F White
    Write-Host "     Mouse Trails:                $(if($mTrails -gt 0){'ON'}else{'OFF'})`n" -F White

    Write-Host "  ┌─────────────────────────────────────────────────────────┐" -F Cyan
    Write-Host "  │ ⚠️  COSA SIGNIFICA ACCELERAZIONE MOUSE?                │" -F Cyan
    Write-Host "  └─────────────────────────────────────────────────────────┘" -F Cyan
    Write-Host "  Con accelerazione ON: muovere il mouse veloce sposta" -F White
    Write-Host "  il cursore PIÙ di quanto ti aspetti — il movimento" -F White
    Write-Host "  dipende dalla velocità, non solo dalla distanza fisica." -F White
    Write-Host "  Per gaming FPS e CS/CoD → OFF dà precisione assoluta." -F White
    Write-Host "  Per uso desktop normale → ON può essere comodo.`n" -F DarkGray

    Write-Host "  [1] 🎯 OFF - Precisione massima (gaming FPS, raccomandato)" -F Green
    Write-Host "      MouseSpeed=0, Threshold=0, EPP disabilitata" -F DarkGray
    Write-Host "      Ogni centimetro fisico = stesso spostamento sempre`n" -F DarkGray
    Write-Host "  [2] 🖥️  ON - Comportamento Windows default" -F Yellow
    Write-Host "      MouseSpeed=1, Threshold 6/10, EPP standard`n" -F DarkGray
    Write-Host "  [3] ⚙️  AVANZATO - Configura manualmente ogni parametro`n" -F Magenta
    Write-Host "  [0] ↩️  Torna al menu`n" -F DarkGray

    $mChoice = Read-Host "  Scelta (1/2/3/0)"
    if($mChoice -eq "0"){ continue MenuLoop }

    Write-Host ""

    if($mChoice -eq "1"){
        # ── ACCELERAZIONE OFF — precisione massima ────────────────────────
        Write-Info "Disabilitazione accelerazione mouse..."

        # MouseSpeed 0 = disabilita accelerazione
        # Threshold 1 e 2 a 0 = disabilita entrambi gli scalini di accelerazione
        reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed"      /t REG_SZ /d "0" /f 2>$null|Out-Null
        reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f 2>$null|Out-Null
        reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f 2>$null|Out-Null
        Write-Success "Accelerazione: OFF (MouseSpeed=0, Threshold=0/0)"

        # Disabilita Enhanced Pointer Precision (la curva di accelerazione Windows)
        # EPP usa una curva Bezier che altera il movimento — va disabilitata per
        # avere 1:1 tra movimento fisico e cursore
        reg add "HKCU\Control Panel\Mouse" /v "MouseSensitivity" /t REG_SZ /d "10" /f 2>$null|Out-Null

        # Rimuovi curve custom SmoothMouseXCurve / SmoothMouseYCurve
        # Queste sovrascrivono il comportamento EPP — se presenti le rimuoviamo
        Remove-ItemProperty "HKCU:\Control Panel\Mouse" -Name "SmoothMouseXCurve" -Force -EA SilentlyContinue
        Remove-ItemProperty "HKCU:\Control Panel\Mouse" -Name "SmoothMouseYCurve" -Force -EA SilentlyContinue
        Write-Success "Enhanced Pointer Precision: curve rimosse (movimento 1:1)"

        # Mouse Trails OFF — aggiunge latenza visiva percepita
        reg add "HKCU\Control Panel\Mouse" /v "MouseTrails" /t REG_SZ /d "0" /f 2>$null|Out-Null
        Write-Success "Mouse Trails: OFF"

        # LowLevelHooksTimeout ridotto — meno latenza input hook
        reg add "HKCU\Control Panel\Desktop" /v "LowLevelHooksTimeout" /t REG_DWORD /d 1000 /f 2>$null|Out-Null
        Write-Success "Input hooks timeout: 1000ms (ridotto)"

        # MouseHoverTime ridotto — feedback visivo più rapido
        reg add "HKCU\Control Panel\Mouse" /v "MouseHoverTime" /t REG_SZ /d "10" /f 2>$null|Out-Null
        Write-Success "Mouse HoverTime: 10ms"

        Write-Host ""
        Write-Host "  ════════════════════════════════════════════════════" -F Green
        Write-Host "   🎯 MOUSE ACCELERAZIONE OFF — Precisione massima!" -F Green
        Write-Host "  ════════════════════════════════════════════════════`n" -F Green
        Write-Host "  📋 IMPORTANTE — fai anche questo in Windows:" -F Cyan
        Write-Host "   Impostazioni → Bluetooth e dispositivi → Mouse →" -F White
        Write-Host "   Impostazioni mouse aggiuntive → Opzioni puntatore →" -F White
        Write-Host "   DESELEZIONA 'Aumenta precisione puntatore'`n" -F Yellow

    } elseif($mChoice -eq "2"){
        # ── ACCELERAZIONE ON — default Windows ───────────────────────────
        Write-Info "Ripristino accelerazione mouse Windows default..."

        reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed"      /t REG_SZ /d "1"  /f 2>$null|Out-Null
        reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "6"  /f 2>$null|Out-Null
        reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "10" /f 2>$null|Out-Null
        reg add "HKCU\Control Panel\Mouse" /v "MouseSensitivity" /t REG_SZ /d "10" /f 2>$null|Out-Null
        reg add "HKCU\Control Panel\Desktop" /v "LowLevelHooksTimeout" /t REG_DWORD /d 5000 /f 2>$null|Out-Null

        Write-Success "Accelerazione: ON (MouseSpeed=1, Threshold=6/10) — default Windows"
        Write-Host ""
        Write-Host "  ════════════════════════════════════════════════════" -F Yellow
        Write-Host "   🖥️  MOUSE DEFAULT RIPRISTINATO" -F Yellow
        Write-Host "  ════════════════════════════════════════════════════`n" -F Yellow

    } elseif($mChoice -eq "3"){
        # ── AVANZATO — configurazione manuale ────────────────────────────
        Write-Host ""
        Write-Host "  ⚙️  CONFIGURAZIONE AVANZATA MOUSE`n" -F Magenta

        Write-Host "  MouseSpeed (0=OFF, 1=ON con doppia velocità, 2=ON con quadrupla):" -F White
        $newSpeed = Read-Host "  MouseSpeed [$mSpeed]"
        if($newSpeed -eq ""){ $newSpeed = $mSpeed }

        Write-Host "  MouseThreshold1 (0=OFF, default=6 — primo scalino accelerazione):" -F White
        $newThr1 = Read-Host "  Threshold1 [$mThr1]"
        if($newThr1 -eq ""){ $newThr1 = $mThr1 }

        Write-Host "  MouseThreshold2 (0=OFF, default=10 — secondo scalino accelerazione):" -F White
        $newThr2 = Read-Host "  Threshold2 [$mThr2]"
        if($newThr2 -eq ""){ $newThr2 = $mThr2 }

        Write-Host "  MouseSensitivity (1-20, default=10 — sensibilità cursore Windows):" -F White
        $newSens = Read-Host "  Sensitivity [$eppVal]"
        if($newSens -eq ""){ $newSens = if($eppVal){$eppVal}else{"10"} }

        reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed"       /t REG_SZ /d "$newSpeed" /f 2>$null|Out-Null
        reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1"  /t REG_SZ /d "$newThr1"  /f 2>$null|Out-Null
        reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2"  /t REG_SZ /d "$newThr2"  /f 2>$null|Out-Null
        reg add "HKCU\Control Panel\Mouse" /v "MouseSensitivity" /t REG_SZ /d "$newSens"  /f 2>$null|Out-Null

        Write-Host ""
        Write-Success "Mouse: Speed=$newSpeed, Thr1=$newThr1, Thr2=$newThr2, Sens=$newSens"
        Write-Host ""
        Write-Host "  ════════════════════════════════════════════════════" -F Magenta
        Write-Host "   ⚙️  MOUSE CONFIGURATO!" -F Magenta
        Write-Host "  ════════════════════════════════════════════════════`n" -F Magenta
    }

    Write-Host "  ℹ Le modifiche sono immediate — nessun riavvio necessario`n" -F DarkGray
    Read-Host "  INVIO per tornare al menu"
    continue MenuLoop
}

# ═════════════════════════════════════════════════════════════════════════════
#  MODALITÀ D: DISCORD
# ═════════════════════════════════════════════════════════════════════════════

if($mode -in @("D","d")){
    Show-Banner
    Write-Section "COMMUNITY OGD — DISCORD"

    Write-Host "`n  💬 Unisciti al server Discord di OGD!`n" -F Cyan
    Write-Host "  Trovi:" -F White
    Write-Host "   • Supporto per lo script" -F DarkGray
    Write-Host "   • Consigli e ottimizzazioni dalla community" -F DarkGray
    Write-Host "   • Aggiornamenti e novità in anteprima" -F DarkGray
    Write-Host "   • Amici con cui condividere la passione per il gaming`n" -F DarkGray
    Write-Host "  🔗 https://discord.gg/5SJa2xp5`n" -F Yellow

    if((Read-Host "  Aprire Discord nel browser? (S/N)") -in @("S","s")){
        try{
            Start-Process "https://discord.gg/5SJa2xp5"
            Write-Host "`n  ✓ Discord aperto nel browser!`n" -F Green
        }catch{
            Write-Host "`n  ⚠ Apri manualmente: https://discord.gg/5SJa2xp5`n" -F Yellow
        }
    }

    Read-Host "  INVIO per tornare al menu"
    continue MenuLoop
}

# ═════════════════════════════════════════════════════════════════════════════
# ═════════════════════════════════════════════════════════════════════════════

# ═════════════════════════════════════════════════════════════════════════════
#  MODALITÀ 1-5: OTTIMIZZAZIONI

if($mode -in @('K','k','S','s')){
    Show-OgdStorageSuperTweaksMenu
    continue MenuLoop
}

if($mode -in @('T','t')){
    Show-OgdUniversalMicroTweaksMenu
    continue MenuLoop
}

if($mode -in @('Q','q')){
    Show-OgdBenchmarkMenu
    continue MenuLoop
}

if($mode -in @("1","2","3","B","b")){
    $profileLabel = switch($mode){
        "1" { "LIGHT" }
        "2" { "NORMALE" }
        "3" { "AGGRESSIVO" }
        {$_ -in @("B","b")} { "BETA 25H2 / 26220.8148" }
    }
    Show-Banner
    Write-Section ("AZIONE PROFILO {0}" -f $profileLabel)
    Write-Host "  [A] APPLICA - Esegue il profilo selezionato" -F Green
    Write-Host "  [R] ROLLBACK DEFAULT - Riporta il sistema ai default Windows" -F Yellow
    Write-Host "  [0] TORNA INDIETRO`n" -F DarkGray
    $profileAction = Read-Host "  Scelta (A/R/0)"
    if($profileAction -in @('R','r')){
        Invoke-OgdFullRollbackToDefault -ProfileLabel $profileLabel | Out-Null
        Read-Host "  INVIO per continuare" | Out-Null
        continue MenuLoop
    }
    if($profileAction -in @('0')){
        continue MenuLoop
    }
    if($profileAction -notin @('A','a')){
        Write-Warning 'Scelta non valida'
        Start-Sleep 1
        continue MenuLoop
    }
}

if($mode -in @("1","2","3","A","a","4","5","B","b")){

    # ── Flag livelli desktop ─────────────────────────────────────────────────
    $isLaptop        = ($mode -in @("4","5"))
    $isGamingLaptop  = ($mode -eq "5")
    $isAggrGaming    = ($mode -in @("A","a"))

    # Flag livelli gaming
    $doAggrGL = ($isAggrGaming -and $aggrGamingLevel -in @("L","N","F"))  # Light Gaming
    $doAggrGN = ($isAggrGaming -and $aggrGamingLevel -in @("N","F"))      # Normale Gaming
    $doAggrGF = ($isAggrGaming -and $aggrGamingLevel -eq "F")             # Full Gaming

    # Livelli desktop (1-3) + Aggressivo Gaming eredita in base al livello scelto
    $doBeta   = ($mode -in @("B","b"))
    $doLight  = ($mode -in @("1","2","3") -or $doAggrGL)
    $doNormal = ($mode -in @("2","3")     -or $doAggrGN)
    $doAggr   = ($mode -eq "3"            -or $doAggrGF)
    $doAggrG  = $doAggrGF  # Blocco tweaks estremi solo in Full

    # Livelli laptop (4-5) — derivati da $laptopLevel
    $doLL  = ($isLaptop -and $laptopLevel -in @("L","N","A","U"))  # Light
    $doLN  = ($isLaptop -and $laptopLevel -in @("N","A","U"))      # Normale
    $doLA  = ($isLaptop -and $laptopLevel -in @("A","U"))           # Alto
    $doLU  = ($isLaptop -and $laptopLevel -eq "U")                  # Ultra

    $lvl = switch($mode){
        "1"{"LIGHT"}
        "2"{"NORMALE"}
        "3"{
            if($aggrCpuType -eq "A"){ "AGGRESSIVO (AMD Ryzen)" }
            else { "AGGRESSIVO (Intel/Generale)" }
        }
        {$_ -in @("B","b")}{"BETA 25H2 / 26220.8148"}
        {$_ -in @("A","a")}{"AGGRESSIVO GAMING $aggrGamingLevel"}
        "4"{"LAPTOP $laptopLevel"}
        "5"{"LAPTOP GAMING $laptopLevel"}
    }

    Show-Banner;Write-Section "OTTIMIZZAZIONE $lvl"

    Write-Host "`n  INCLUDE:" -F Cyan
    if($doBeta){
        Write-Host "   ✓ Compatibilita 25H2 stabile + Insider Beta, senza debloat app e senza forcing low-level" -F Magenta
    }
    if($doLight){
        Write-Host "   ✓ C-States + Timer + Piano + GPU (rete invariata)" -F White
    }
    if($doNormal){
        Write-Host "   ✓ Process 30+ + NPU + Debloat + Visual + Rete avanzata" -F White
    }
    if($doAggr){
        Write-Host "   ✓ Core Affinity + Memory + Responsiveness" -F White
    }
    if($doAggrGL -and -not $doAggrGN){
        Write-Host "   ✓ Game Mode ON + DVR OFF + Process gaming priority" -F Green
        Write-Host "   ✓ Safe su qualsiasi PC gaming`n" -F DarkGray
    }
    if($doAggrGN -and -not $doAggrGF){
        Write-Host "   ✓ Light Gaming + MMCSS + Power max + CPU boost + FSE" -F Yellow
        Write-Host "   ✓ Raccomandato per gaming PC 8GB+`n" -F DarkGray
    }
    if($doAggrGF){
   Write-Host "   ✓ Normale Gaming + scheduler avanzato + servizi alleggeriti + storage ottimizzato" -F Magenta
        Write-Host "   ⚠️  Solo desktop di alta potenza`n" -F Yellow
    }
    if($isLaptop){
        $ltInc = switch($laptopLevel){
            "L"{"Timer + Privacy + GPU + AHCI (rete invariata)"}
            "N"{"Light + Process + Debloat + Visual + Rete avanzata"}
                "A"{"Normale + Piano Ultimate + MMCSS + tuning prudente"}
            "U"{"Alto + CPU Boost + Memory" + $(if($isGamingLaptop){" + GPU max + Game Mode"}else{""})}
        }
        Write-Host "   ✓ $ltInc`n" -F White
    }
    
    if((Read-Host "  Procedere? (S/N)") -notin @("S","s")){continue MenuLoop}
    
    # ═════════════════════════════════════════════════════════════════════
    #  CONFIGURAZIONE RAM INTELLIGENTE
    # ═════════════════════════════════════════════════════════════════════
    
    Show-Banner;Write-Section "CONFIGURAZIONE RAM"
    
    Write-Host "`n  TIPO RAM:" -F Cyan
    Write-Host "  [1] DDR4 (latenza più alta, ottimizzazioni conservative)" -F White
    Write-Host "  [2] DDR5 (bandwidth maggiore, ottimizzazioni aggressive)`n" -F White
    $ramType=Read-Host "  Tipo RAM (1/2)"
    $isDDR5=($ramType -eq "2")
    
    Write-Host "`n  QUANTITÀ RAM:" -F Cyan
    if($mode -eq "1"){
        Write-Host "  [1] 8 GB  - Minimo (ottimizzazioni molto conservative)" -F White
        Write-Host "  [2] 12 GB - Consigliato Light" -F White
        Write-Host "  [3] 16 GB+ - Abbondante`n" -F White
        $ramSize=Read-Host "  RAM (1/2/3)"
        $ramGB=switch($ramSize){"1"{8}"2"{12}default{16}}
    }elseif($mode -eq "2"){
        Write-Host "  [1] 12 GB - Minimo Normale" -F White
        Write-Host "  [2] 16 GB - Standard gaming" -F White
        Write-Host "  [3] 32 GB+ - Enthusiast`n" -F White
        $ramSize=Read-Host "  RAM (1/2/3)"
        $ramGB=switch($ramSize){"1"{12}"2"{16}default{32}}
    }elseif($mode -eq "3" -or $isAggrGaming){
        Write-Host "  [1] 16 GB - Minimo Aggressivo" -F White
        Write-Host "  [2] 32 GB - Standard enthusiast" -F White
        Write-Host "  [3] 64 GB - Workstation" -F White
        Write-Host "  [4] 128 GB+ - Extreme`n" -F White
        $ramSize=Read-Host "  RAM (1/2/3/4)"
        $ramGB=switch($ramSize){"1"{16}"2"{32}"3"{64}default{128}}
    }elseif($mode -in @("B","b")){
        Write-Host "  [1] 12 GB - Minimo Beta 25H2" -F White
        Write-Host "  [2] 16 GB - Standard 25H2" -F White
        Write-Host "  [3] 32 GB+ - Avanzato / Insider`n" -F White
        $ramSize=Read-Host "  RAM (1/2/3)"
        $ramGB=switch($ramSize){"1"{12}"2"{16}default{32}}
    }else{
        # Laptop (4/5)
        Write-Host "  [1] 8 GB  - Minimo laptop" -F White
        Write-Host "  [2] 16 GB - Standard laptop" -F White
        Write-Host "  [3] 32 GB - Gaming laptop`n" -F White
        $ramSize=Read-Host "  RAM (1/2/3)"
        $ramGB=switch($ramSize){"1"{8}"2"{16}default{32}}
    }
    
    Write-Host "`n  📊 CONFIGURAZIONE:" -F Cyan
    Write-Host "     Tipo: $(if($isDDR5){'DDR5'}else{'DDR4'})" -F Yellow
    Write-Host "     RAM: $ramGB GB" -F Yellow
    Write-Host "     Livello: $lvl`n" -F Yellow
    
    if((Read-Host "  Confermi? (S/N)") -notin @("S","s")){continue MenuLoop}
    
    $global:opts=0
    $lastBench = Get-OgdBenchmarkProfile
    if($lastBench){
        Invoke-OgdBenchmarkAdaptiveTweaks -Benchmark $lastBench -RamGB $ramGB
    }
    Invoke-OgdUniversalMicroTweaks -RamGB $ramGB

    Show-Banner;Write-Section "APPLICAZIONE OTTIMIZZAZIONI $lvl"
    Write-Host "`n  RAM: $ramGB GB $(if($isDDR5){'DDR5'}else{'DDR4'})" -F Yellow
    Write-Host ""

    if($doBeta){
        Write-Info "[B1] Compatibilità 25H2 / Insider Beta..."
        $gm='HKCU:\Software\Microsoft\GameBar'
        if(!(Test-Path $gm)){ New-Item $gm -Force -EA SilentlyContinue | Out-Null }
        Set-ItemProperty $gm -Name 'AllowAutoGameMode' -Value 1 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $gm -Name 'AutoGameModeEnabled' -Value 1 -Type DWord -Force -EA SilentlyContinue
        $global:opts++; Write-Success "Compatibilità: Game Mode coerente con 25H2"

        Write-Info "[B2] Visual leggero e reattivo..."
        Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Type String -Force -EA SilentlyContinue
        reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f 2>$null|Out-Null
        reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f 2>$null|Out-Null
        reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f 2>$null|Out-Null
        $global:opts++; Write-Success "Visual: menu rapidi, mouse lineare, niente effetti pesanti"

        Write-Info "[B3] Rete e stack sicuri..."
        netsh winsock reset | Out-Null
        $global:opts++; Write-Success "Rete: stack riallineato senza toccare i DNS utente"

        Write-Info "[B4] Nessun debloat app, nessuna rimozione Copilot, nessun tweak low-level"
        Write-Success "Preset Beta: compatibile con Windows 11 25H2 stabile e Insider 26220.8148"
    }
    
    # ═══════════════════════════════════════════════════════════════════════
    #  LIGHT (BASE)
    # ═══════════════════════════════════════════════════════════════════════
    
    if($doLight){
        # C-States BALANCED
        Write-Info "[1] C-States fix freeze..."
        $pg=(powercfg /getactivescheme) -match 'GUID:\s+([a-f0-9\-]+)'
        if($pg){$pg=$Matches[1]}else{$pg="SCHEME_CURRENT"}
        powercfg /setacvalueindex $pg SUB_PROCESSOR IDLEDISABLE 0 2>$null
        powercfg /setdcvalueindex $pg SUB_PROCESSOR IDLEDISABLE 0 2>$null
        powercfg /setacvalueindex $pg SUB_PROCESSOR IDLESTATEMAX 1 2>$null
        powercfg /setdcvalueindex $pg SUB_PROCESSOR IDLESTATEMAX 1 2>$null
        powercfg /setacvalueindex $pg SUB_PROCESSOR IDLETHRESHOLD 5 2>$null
        powercfg /setdcvalueindex $pg SUB_PROCESSOR IDLETHRESHOLD 5 2>$null
        powercfg /setacvalueindex $pg 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
        powercfg /setacvalueindex $pg 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 2>$null
        powercfg /setactive $pg 2>$null
        $global:opts++;Write-Success "C-States: Solo C1 (zero freeze)"
        
        # Timer + Piano
        Write-Info "[2] Timer 0.5ms + Piano..."
        bcdedit /set useplatformclock No 2>$null|Out-Null
        bcdedit /set disabledynamictick Yes 2>$null|Out-Null
        bcdedit /set tscsyncpolicy Enhanced 2>$null|Out-Null
        
        $ult=powercfg /list 2>$null|Select-String "Ultimate|Prestazioni ultimate"
        if($ult -and $ult.ToString() -match '([a-f0-9-]{36})'){powercfg /setactive $Matches[1] 2>$null
                powercfg /setacvalueindex $Matches[1] SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null
                powercfg /setdcvalueindex $Matches[1] SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null}
        else{
            $ng=powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
            if($ng -match '([a-f0-9-]{36})'){
                powercfg /changename $Matches[1] "Ultimate OGD v8.1.2" 2>$null
                powercfg /setactive $Matches[1] 2>$null
                powercfg /setacvalueindex $Matches[1] SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null
                powercfg /setdcvalueindex $Matches[1] SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null
            }
        }
        
        # Timer script v2.2 — copia sul Desktop
        $timerDest = Join-Path ([Environment]::GetFolderPath("Desktop")) "OGD_Timer_0.5ms.ps1"
        # Cerca il timer v2.0 nella stessa cartella dello script
        $timerSrc = Join-Path (Split-Path $PSCommandPath) "OGD_Timer_0.5ms.ps1"
        if((Test-Path $timerSrc) -and ($timerSrc -ne $timerDest)){
            Copy-Item $timerSrc $timerDest -Force
        } else {
            # Fallback: scrivi versione base migliorata
            @'
#Requires -Version 5.1
#Requires -RunAsAdministrator
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class OGDTimer22 {
    [DllImport("ntdll.dll")] public static extern int NtSetTimerResolution(uint desired, bool set, out uint current);
    [DllImport("ntdll.dll")] public static extern int NtQueryTimerResolution(out uint minimum, out uint maximum, out uint current);
}
"@
function Convert-OgdTimerToMs {
    param([uint32]$Value100ns)
    [math]::Round(($Value100ns / 10000.0), 3)
}
function Get-OgdTimerInfo {
    $min=0u; $max=0u; $cur=0u
    [void][OGDTimer22]::NtQueryTimerResolution([ref]$min,[ref]$max,[ref]$cur)
    [pscustomobject]@{ Minimum100ns=$min; Maximum100ns=$max; Current100ns=$cur; CurrentMs=(Convert-OgdTimerToMs $cur) }
}
$Host.UI.RawUI.WindowTitle='Windows Timer Session'
$requested=5000u
$before=Get-OgdTimerInfo
$target=if($requested -lt $before.Maximum100ns){ $before.Maximum100ns } else { $requested }
$released=$false
$c=0u; $r=[OGDTimer22]::NtSetTimerResolution($target,$true,[ref]$c)
if($r -ne 0){ Write-Host "Errore impostazione timer (codice $r)" -ForegroundColor Red; Read-Host; exit 1 }
Register-EngineEvent PowerShell.Exiting -Action { if(-not $script:released){ $tmp=0u; [void][OGDTimer22]::NtSetTimerResolution($script:target,$false,[ref]$tmp); $script:released=$true } } | Out-Null
Write-Host 'Windows Timer Session attiva (uso opzionale di test)' -ForegroundColor Green
Write-Host ("Risoluzione attuale: {0} ms" -f ((Get-OgdTimerInfo).CurrentMs)) -ForegroundColor White
Write-Host 'Usalo solo per confronto pratico: lascia la finestra aperta o minimizzata e chiudila a fine sessione.' -ForegroundColor DarkGray
while($true){
    Start-Sleep -Seconds 20
    $now=Get-OgdTimerInfo
    if($now.Current100ns -gt $target){ $tmp=0u; [void][OGDTimer22]::NtSetTimerResolution($target,$true,[ref]$tmp) }
}
'@|Out-File $timerDest -Encoding UTF8 -Force
        }
        
        $global:opts++;Write-Success "Timer: FPS mode v2.2 + Piano + Script Desktop"
        
        # Privacy
        Write-Info "[3] Privacy..."
        $tp="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        if(!(Test-Path $tp)){New-Item $tp -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $tp -Name "AllowTelemetry" -Value 0 -Type DWord -Force -EA SilentlyContinue
        $global:opts++;Write-Success "Privacy: telemetria base ridotta senza toccare la rete"
        
        # Explorer
        Write-Info "[4] Explorer Boost..."
        reg delete "HKCU\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU" /f 2>$null|Out-Null
        reg delete "HKCU\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags" /f 2>$null|Out-Null
        reg add "HKCU\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU" 2>$null|Out-Null
        reg add "HKCU\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" /v "FolderType" /d "NotSpecified" /f 2>$null|Out-Null
        $global:opts++;Write-Success "Explorer Boost OK"
        
        # GPU
        Write-Info "[5] GPU optimization..."
        $gp="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        Set-ItemProperty $gp -Name "HwSchMode" -Value 2 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $gp -Name "TdrDelay" -Value 10 -Type DWord -Force -EA SilentlyContinue
        $global:opts++;Write-Success "GPU: HwScheduling ON + TDR 10s"

        # ── TWEAKS RETE E RISPARMIO ENERGETICO (tutti i PC) ──────────────────
        Write-Host ""
        Write-Info "[L] Rete + risparmio energetico ottimizzati..."

        # SSD: AHCI link power management OFF (no freeze su resume)
        $ap="HKLM:\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device"
        if(!(Test-Path $ap)){New-Item $ap -Force -EA SilentlyContinue|Out-Null}
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v "StartIo" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        Write-Success "SSD AHCI link power: OFF (no freeze)"

        # Wake timers OFF
        $pg2=(powercfg /getactivescheme) -match 'GUID:\s+([a-f0-9\-]+)'
        if($pg2){$pg2=$Matches[1]}else{$pg2="SCHEME_CURRENT"}
        powercfg /setdcvalueindex $pg2 SUB_SLEEP RTCWAKE 0 2>$null
        powercfg /setacvalueindex $pg2 SUB_SLEEP RTCWAKE 0 2>$null
        powercfg /setactive $pg2 2>$null
        Write-Success "Wake timers: OFF"

    }
    
    # ═══════════════════════════════════════════════════════════════════════
    #  NORMALE (include Light)
    # ═══════════════════════════════════════════════════════════════════════
    
    if($doNormal){
        # Process Priority 30+
        Write-Info "[6] Process Priority (33)..."
        
        $procs=@{
            "csrss.exe"=@{P="High";A="P";I="High"}
            "smss.exe"=@{P="High";A="P";I="High"}
            "wininit.exe"=@{P="High";A="P";I="High"}
            "services.exe"=@{P="High";A="P";I="High"}
            "lsass.exe"=@{P="High";A="P";I="High"}
            "explorer.exe"=@{P="AboveNormal";A="P";I="Normal"}
            "dwm.exe"=@{P="High";A="P";I="High"}
            "mmc.exe"=@{P="High";A="P";I="High"}
            "msiexec.exe"=@{P="High";A="P";I="High"}
            "TrustedInstaller.exe"=@{P="High";A="P";I="High"}
            "TiWorker.exe"=@{P="AboveNormal";A="P";I="Normal"}
            "taskmgr.exe"=@{P="High";A="P";I="High"}
            "ShellExperienceHost.exe"=@{P="AboveNormal";A="P";I="Normal"}
            "StartMenuExperienceHost.exe"=@{P="AboveNormal";A="P";I="Normal"}
            "TextInputHost.exe"=@{P="AboveNormal";A="P";I="Normal"}
            "SearchHost.exe"=@{P="AboveNormal";A="P";I="Normal"}
            "msedge.exe"=@{P="AboveNormal";A="P";I="Normal"}
            "msedgewebview2.exe"=@{P="AboveNormal";A="P";I="Normal"}
            "RuntimeBroker.exe"=@{P="Normal";A="E";I="Low"}
            "svchost.exe"=@{P="Normal";A="All";I="Normal"}
            "dllhost.exe"=@{P="Normal";A="All";I="Normal"}
            "conhost.exe"=@{P="AboveNormal";A="P";I="Normal"}
            "SearchIndexer.exe"=@{P="BelowNormal";A="E";I="Low"}
            "SearchProtocolHost.exe"=@{P="BelowNormal";A="E";I="Low"}
            "SearchFilterHost.exe"=@{P="BelowNormal";A="E";I="Low"}
            "spoolsv.exe"=@{P="AboveNormal";A="P";I="Normal"}
            "fontdrvhost.exe"=@{P="Normal";A="All";I="Normal"}
            "WUDFHost.exe"=@{P="Normal";A="All";I="Normal"}
            "sihost.exe"=@{P="AboveNormal";A="P";I="Normal"}
            "ctfmon.exe"=@{P="AboveNormal";A="P";I="Normal"}
            "SecurityHealthSystray.exe"=@{P="Normal";A="E";I="Low"}
            "audiodg.exe"=@{P="High";A="P";I="High"}
            "WmiPrvSE.exe"=@{P="AboveNormal";A="P";I="Normal"}
            "perfmon.exe"=@{P="AboveNormal";A="P";I="Normal"}
            "CompPkgSrv.exe"=@{P="Normal";A="E";I="Low"}
        }
        
        $pmap=@{"Realtime"=4;"High"=3;"AboveNormal"=6;"Normal"=2;"BelowNormal"=5;"Low"=1}
        $imap=@{"High"=3;"Normal"=2;"Low"=1}
        
        foreach($pn in $procs.Keys){
            $pi=$procs[$pn]
            $rp="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$pn\PerfOptions"
            if(!(Test-Path $rp)){New-Item $rp -Force -EA SilentlyContinue|Out-Null}
            Set-ItemProperty $rp -Name "CpuPriorityClass" -Value $pmap[$pi.P] -Type DWord -Force -EA SilentlyContinue
            Set-ItemProperty $rp -Name "IoPriority" -Value $imap[$pi.I] -Type DWord -Force -EA SilentlyContinue
        }
        
        $global:opts++;Write-Success "Process: $($procs.Count) processi"
        Optimize-OgdEdgePolicy
        Write-Success "Core apps: Explorer/MMC/MSIExec/Edge con priorità e policy più reattive"
        
        Write-Info "[6+] Login / Logout / Riavvio / Shutdown (moderato)..."
        Show-OgdWorkingAnimation -Text 'Ottimizzazione accesso e uscita sessione...' -DurationMs 700
        $lifeNormal = Set-OgdLifecycleTweaks -Profile 'Normal'
        $global:opts++;Write-Success "Lifecycle: StartupDelay 0 | AutoEndTasks ON | WaitToKillApp $($lifeNormal.WaitToKillAppTimeout) ms"
        
        # NPU — usa rilevamento robusto (aggiorna $hasNPU e $npuType se serve)
        if(-not $hasNPU){
            $npuRecheck = Get-OgdNpuInfo -CpuName $cpu.Name
            if($npuRecheck.Found){ $hasNPU=$true; $npuType=$npuRecheck.Type }
        }
        if($hasNPU){
            Write-Info "[7] NPU ($npuType)..."
            Write-Host "  → NPU rilevata: il preset generale non forza chiavi AI non documentate." -F DarkGray
            Write-Host "  → Per diagnostica o interventi mirati usa il menu [P] NPU." -F DarkGray
            $global:opts++;Write-Success "NPU: nessun forcing registry, solo rilevamento coerente"
        }else{
            Write-Info "[7] NPU: non presente su questo sistema — skip"
        }
        
        # Privacy completo
        Write-Info "[8] Privacy completo..."
        $rp="HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
        if(!(Test-Path $rp)){New-Item $rp -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $rp -Name "DisableAIDataAnalysis" -Value 1 -Type DWord -Force -EA SilentlyContinue
        $cp="HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        if(!(Test-Path $cp)){New-Item $cp -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $cp -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force -EA SilentlyContinue
        
        # Telemetry OFF (NVIDIA, VS, PowerShell, Adobe, etc)
        reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v "EnableRID44231" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKLM\Software\Policies\Microsoft\VisualStudio\SQM" /v "OptIn" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKCU\Software\Microsoft\VisualStudio\Telemetry" /v "TurnOffSwitch" /t REG_DWORD /d 1 /f 2>$null|Out-Null
        [Environment]::SetEnvironmentVariable("POWERSHELL_TELEMETRY_OPTOUT","1","Machine")
        reg add "HKCU\SOFTWARE\Microsoft\MediaPlayer\Preferences" /v "UsageTracking" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKCU\Software\Piriform\CCleaner" /v "Monitoring" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        
        $global:opts++;Write-Success "Privacy: Recall OFF + Telemetry OFF (NVIDIA/VS/PS/Adobe)"
        
        # Protezione Privacy Aggiuntiva (se richiesta)
        if($privacyLevel -ne "0"){
            Write-Info "[8+] Protezione Privacy $(switch($privacyLevel){"1"{"LIGHT"}"2"{"NORMALE"}"3"{"AGGRESSIVO"}"4"{"PARANOICO"}})..."
            
            # LIGHT (1): Base telemetry
            if($privacyLevel -ge "1"){
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f 2>$null|Out-Null
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f 2>$null|Out-Null
            }
            
            # NORMALE (2): Cloud + Location
            if($privacyLevel -ge "2"){
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableCloudOptimizedContent" /t REG_DWORD /d 1 /f 2>$null|Out-Null
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocation" /t REG_DWORD /d 1 /f 2>$null|Out-Null
                reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" /v "Value" /t REG_SZ /d "Deny" /f 2>$null|Out-Null
                reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" /v "Value" /t REG_SZ /d "Deny" /f 2>$null|Out-Null
            }
            
            # AGGRESSIVO (3): Feedback e telemetria approfonditi
            if($privacyLevel -ge "3"){
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d 1 /f 2>$null|Out-Null
                reg add "HKCU\Software\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d 0 /f 2>$null|Out-Null
                Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" -EA SilentlyContinue
                Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" -EA SilentlyContinue
            }
            
            # PARANOICO (4): Update manuale + Defender ridotto
            if($privacyLevel -eq "4"){
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f 2>$null|Out-Null
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 0 /f 2>$null|Out-Null
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 0 /f 2>$null|Out-Null
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SpynetReporting" /t REG_DWORD /d 0 /f 2>$null|Out-Null
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SubmitSamplesConsent" /t REG_DWORD /d 2 /f 2>$null|Out-Null
            }
            
            $privacyName=switch($privacyLevel){"1"{"LIGHT"}"2"{"NORMALE"}"3"{"AGGRESSIVO"}"4"{"PARANOICO"}}
            Write-Success "Protezione Privacy $privacyName applicata"
        }
        
        # Debloat
        Write-Info "[9] Debloat..."
        $debloatResult = Invoke-OgdAlternativeDebloat -Mode Full -IncludeRecall
        $global:opts++;Write-Success ("Debloat: motore AWin11DebloatAlternative | app rimosse {0} | Spotify/Xbox preservati" -f $debloatResult.RemovedCommonApps)
        
        # Visual
        Write-Info "[10] Visual..."
        Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -Force -EA SilentlyContinue
        
        # MenuShowDelay - menu istantanei
        $cpd="HKCU:\Control Panel\Desktop"
        Set-ItemProperty $cpd -Name "MenuShowDelay" -Value "0" -Type String -Force -EA SilentlyContinue
        
        # Mouse acceleration OFF
        reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f 2>$null|Out-Null
        reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f 2>$null|Out-Null
        reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f 2>$null|Out-Null
        
        # Dark mode
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        Write-Host "  → Tweak Explorer/Taskbar in stile Winaero spostati nel menu [Y] Windows 11 Extra Lite." -F DarkGray
        
        # Sticky keys OFF
        reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "58" /f 2>$null|Out-Null
        
        # Hibernation OFF
        powercfg /h off 2>$null|Out-Null
        
        $global:opts++;Write-Success "Visual: UI completo (Menu/Mouse/Taskbar/Dark/Hibernation)"
        
        # Memory NORMALE - ottimizzazioni base RAM
        if($mode -eq "2"){
            Write-Info "[11] Memory base ($ramGB GB $(if($isDDR5){'DDR5'}else{'DDR4'}))..."
            $mp="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
            
            # NORMALE: Paging sempre ON (più safe)
            Set-ItemProperty $mp -Name "DisablePagingExecutive" -Value 0 -Type DWord -Force -EA SilentlyContinue
            
            # LargeSystemCache sempre OFF per gaming
            Set-ItemProperty $mp -Name "LargeSystemCache" -Value 0 -Type DWord -Force -EA SilentlyContinue
            
            # Superfetch intelligente
            $pp="$mp\PrefetchParameters"
            if($ramGB -le 16){
                Set-ItemProperty $pp -Name "EnableSuperfetch" -Value 3 -Type DWord -Force -EA SilentlyContinue
                Write-Success "  → Superfetch: ON (RAM $ramGB GB)"
            }else{
                Set-ItemProperty $pp -Name "EnableSuperfetch" -Value 2 -Type DWord -Force -EA SilentlyContinue
                Write-Success "  → Superfetch: BOOT only (RAM $ramGB GB)"
            }
            
            # Prefetch basato su DDR
            if($isDDR5){
                Set-ItemProperty $pp -Name "EnablePrefetcher" -Value 3 -Type DWord -Force -EA SilentlyContinue
            }else{
                Set-ItemProperty $pp -Name "EnablePrefetcher" -Value 2 -Type DWord -Force -EA SilentlyContinue
            }
            
            $global:opts++;Write-Success "Memory: Base per $ramGB GB $(if($isDDR5){'DDR5'}else{'DDR4'})"
        }

        # ── TWEAKS RETE AVANZATI (tutti i PC) ───────────────────────────────
        Write-Host ""
        Write-Info "[LN] Rete avanzata + servizi ottimizzati..."

        # Power Throttling gestito da Windows (non forzato OFF)
        $ptp="HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
        if(!(Test-Path $ptp)){New-Item $ptp -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $ptp -Name "PowerThrottlingOff" -Value 0 -Type DWord -Force -EA SilentlyContinue
        Write-Success "Power Throttling: gestito da Windows (ottimale)"

        # Servizi background: priorità I/O bassa
        $svcList = @("SysMain","WSearch","DiagTrack","dmwappushservice")
        foreach($svc in $svcList){
            try{
                $rp2="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$svc.exe\PerfOptions"
                if(!(Test-Path $rp2)){New-Item $rp2 -Force -EA SilentlyContinue|Out-Null}
                Set-ItemProperty $rp2 -Name "CpuPriorityClass" -Value 1 -Type DWord -Force -EA SilentlyContinue
                Set-ItemProperty $rp2 -Name "IoPriority"       -Value 0 -Type DWord -Force -EA SilentlyContinue
            }catch{}
        }
        Write-Success "Servizi background: priorità I/O minima (SysMain, WSearch, DiagTrack)"

    }
    
    # ═══════════════════════════════════════════════════════════════════════
    #  AGGRESSIVO (include Normale)
    # ═══════════════════════════════════════════════════════════════════════
    
    if($doAggr){
        # Salta step [11] se è stato fatto in NORMALE
        $aggStep=if($mode -eq "2"){12}else{11}
        # Core Affinity
        if($isPE){
            Write-Info "[$aggStep] Core Affinity..."
            foreach($pn in $procs.Keys){
                $pi=$procs[$pn]
                $rp="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$pn\PerfOptions"
                $am=0
                switch($pi.A){
                    "P"{for($i=0;$i -lt $pC;$i++){$am+=[math]::Pow(2,$i)}}
                    "E"{for($i=$pC;$i -lt ($pC+$eC);$i++){$am+=[math]::Pow(2,$i)}}
                    default{for($i=0;$i -lt ($pC+$eC);$i++){$am+=[math]::Pow(2,$i)}}
                }
                if($am -gt 0){Set-ItemProperty $rp -Name "CpuAffinityMask" -Value $am -Type DWord -Force -EA SilentlyContinue}
            }
            $global:opts++;Write-Success "Core Affinity: P-cores foreground"
            $aggStep++
        }else{Write-Info "[$aggStep] Core Affinity: Skip";$aggStep++}
        
        # Memory (APPROCCIO PIU PRUDENTE)
        Write-Info "[$aggStep] Memory intelligente ($ramGB GB $(if($isDDR5){'DDR5'}else{'DDR4'}))..."
        $mp="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        Set-ItemProperty $mp -Name "DisablePagingExecutive" -Value 0 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $mp -Name "LargeSystemCache" -Value 0 -Type DWord -Force -EA SilentlyContinue
        foreach($memName in @('IoPageLockLimit','SystemPages','NonPagedPoolSize','PagedPoolSize','SessionViewSize','SessionPoolSize','SecondLevelDataCache')){
            try{ Remove-ItemProperty -Path $mp -Name $memName -Force -EA SilentlyContinue }catch{}
        }
        Write-Success "  → Memory Manager: paging executive e cache su default sicuri"
        Write-Success "  → Rimossi override statici di pool/session/system pages per evitare freeze termici o driver-sensitive"
        
        # Superfetch - RAM bassa sempre ON, RAM alta può essere OFF
        $pp="$mp\PrefetchParameters"
        if($ramGB -le 16){
            # RAM bassa: Superfetch ON per performance
            Set-ItemProperty $pp -Name "EnableSuperfetch" -Value 3 -Type DWord -Force -EA SilentlyContinue
            Write-Success "  → Superfetch: ON (RAM $ramGB GB, necessario)"
        }elseif($ramGB -le 32){
            # RAM media: Superfetch ON ma Boot only
            Set-ItemProperty $pp -Name "EnableSuperfetch" -Value 2 -Type DWord -Force -EA SilentlyContinue
            Write-Success "  → Superfetch: BOOT only (RAM $ramGB GB)"
        }else{
            # RAM alta: Superfetch OFF (non necessario)
            Set-ItemProperty $pp -Name "EnableSuperfetch" -Value 0 -Type DWord -Force -EA SilentlyContinue
            Write-Success "  → Superfetch: OFF (RAM $ramGB GB, non necessario)"
        }
        
        # Prefetch - leggermente diverso tra DDR4 e DDR5, senza forzare pool statici
        if($isDDR5){
            Set-ItemProperty $pp -Name "EnablePrefetcher" -Value 3 -Type DWord -Force -EA SilentlyContinue
            Write-Success "  → Prefetcher: FULL (DDR5 bandwidth)"
        }else{
            Set-ItemProperty $pp -Name "EnablePrefetcher" -Value 2 -Type DWord -Force -EA SilentlyContinue
            Write-Success "  → Prefetcher: BOOT (DDR4)"
        }
        
        # SvcHostSplitThresholdInKB - threshold per split processi svchost
        $svcPlan = Set-OgdSvcHostSplitMode -Mode 'Balanced'
        Write-Success "  → SvcHost Split: $($svcPlan.Mode) | soglia $($svcPlan.ThresholdMB) MB (RAM $($svcPlan.RamMB) MB)"

        $global:opts++;Write-Success "Memory: profilo prudente per $ramGB GB $(if($isDDR5){'DDR5'}else{'DDR4'})"
        $aggStep++
        
        # Responsiveness 3 (FIXED no freeze)
        Write-Info "[$aggStep] Responsiveness 3..."
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 3 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 0x26 -Type DWord -Force -EA SilentlyContinue
        $global:opts++;Write-Success "Responsiveness: 3 (97% foreground, no freeze)"
        $aggStep++

        Write-Info "[$aggStep] Boot / Login / Logout / Reboot / Shutdown..."
        Show-OgdWorkingAnimation -Text 'Ottimizzazione ciclo vita Windows...' -DurationMs 850
        $lifeAgg = Set-OgdLifecycleTweaks -Profile 'Aggressive'
        $global:opts++;Write-Success "Lifecycle: StartupDelay 0 | AutoEndTasks ON | WaitToKillApp $($lifeAgg.WaitToKillAppTimeout) ms | WaitToKillService $($lifeAgg.WaitToKillServiceTimeout) ms"
        $aggStep++

        # ── CPU UNPARKING E PROCESSOR BOOST ──────────────────────────────────
        if($aggrCpuType -eq "A"){
            Write-Info "[$aggStep] CPU Unparking & Boost (Variante AMD)..."
            Write-Host "  → Variante AMD selezionata: Unparking forzato e Processor Boost estremo" -F DarkGray
            Write-Host "    vengono saltati per prevenire surriscaldamento estivo su Ryzen/X3D." -F DarkGray
            $global:opts++;Write-Success "CPU Unparking / Boost: Saltati (Ottimizzato per temperature AMD)"
            $aggStep++
        } else {
            # Approccio termico piu prudente: evitiamo unparking totale costante
            Write-Info "[$aggStep] CPU parking prudente..."
            $cpuParkPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
            if(Test-Path $cpuParkPath){
                Set-ItemProperty $cpuParkPath -Name "ValueMin" -Value 10 -Type DWord -Force -EA SilentlyContinue
                Set-ItemProperty $cpuParkPath -Name "ValueMax" -Value 100 -Type DWord -Force -EA SilentlyContinue
            }
            # Applica al piano corrente
            $pg2=(powercfg /getactivescheme) -match 'GUID:\s+([a-f0-9\-]+)'
            if($pg2){$pg2=$Matches[1]}else{$pg2="SCHEME_CURRENT"}
            powercfg /setacvalueindex $pg2 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 10 2>$null
            powercfg /setdcvalueindex $pg2 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 10 2>$null
            powercfg /setactive $pg2 2>$null
            $global:opts++;Write-Success "CPU parking: minimo 10% (evitato unparking totale continuo)"
            $aggStep++

            # ── PROCESSOR BOOST MODE = PRUDENTE ────────────────────────────────
            Write-Info "[$aggStep] Processor Boost Mode prudente..."
            powercfg /setacvalueindex $pg2 54533251-82be-4824-96c1-47b60b740d00 be337238-0d82-4146-a960-4f3749d470c7 1 2>$null
            powercfg /setdcvalueindex $pg2 54533251-82be-4824-96c1-47b60b740d00 be337238-0d82-4146-a960-4f3749d470c7 1 2>$null
            powercfg /setactive $pg2 2>$null
            $global:opts++;Write-Success "Boost Mode: nativo/prudente (meno picchi termici continui)"
            $aggStep++
        }

        # ── MMCSS TWEAKS ─────────────────────────────────────────────────────
        # Multimedia Class Scheduler Service — gestisce priorità CPU per audio/giochi
        # Games profile: priorità alta, latenza minima
        Write-Info "[$aggStep] MMCSS Gaming profile..."
        $mmBase = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks"
        # Games
        $mmGames = "$mmBase\Games"
        if(!(Test-Path $mmGames)){New-Item $mmGames -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $mmGames -Name "Affinity"              -Value 0          -Type DWord  -Force -EA SilentlyContinue
        Set-ItemProperty $mmGames -Name "Background Only"       -Value "False"    -Type String -Force -EA SilentlyContinue
        Set-ItemProperty $mmGames -Name "Clock Rate"            -Value 2710        -Type DWord  -Force -EA SilentlyContinue
        Set-ItemProperty $mmGames -Name "GPU Priority"          -Value 8          -Type DWord  -Force -EA SilentlyContinue
        Set-ItemProperty $mmGames -Name "Priority"              -Value 6          -Type DWord  -Force -EA SilentlyContinue
        Set-ItemProperty $mmGames -Name "Scheduling Category"   -Value "High"     -Type String -Force -EA SilentlyContinue
        Set-ItemProperty $mmGames -Name "SFIO Priority"         -Value "High"     -Type String -Force -EA SilentlyContinue
        # Pro Audio (usato anche da game engines con audio HW)
        $mmAudio = "$mmBase\Pro Audio"
        if(!(Test-Path $mmAudio)){New-Item $mmAudio -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $mmAudio -Name "Affinity"              -Value 0          -Type DWord  -Force -EA SilentlyContinue
        Set-ItemProperty $mmAudio -Name "Background Only"       -Value "False"    -Type String -Force -EA SilentlyContinue
        Set-ItemProperty $mmAudio -Name "Clock Rate"            -Value 10000       -Type DWord  -Force -EA SilentlyContinue
        Set-ItemProperty $mmAudio -Name "GPU Priority"          -Value 8          -Type DWord  -Force -EA SilentlyContinue
        Set-ItemProperty $mmAudio -Name "Priority"              -Value 6          -Type DWord  -Force -EA SilentlyContinue
        Set-ItemProperty $mmAudio -Name "Scheduling Category"   -Value "High"     -Type String -Force -EA SilentlyContinue
        Set-ItemProperty $mmAudio -Name "SFIO Priority"         -Value "High"     -Type String -Force -EA SilentlyContinue
        $global:opts++;Write-Success "MMCSS: Games + Pro Audio → Priority 6, GPU Priority 8, High"
        $aggStep++

        # ── XBOX GAME BAR / DVR OFF ──────────────────────────────────────────
        # Disabilita la registrazione in background e Game Bar
        # Libera CPU/GPU/RAM usati per cattura video in background
        Write-Info "[$aggStep] Xbox Game Bar + DVR OFF..."
        reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AudioCaptureEnabled" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "CursorCaptureEnabled" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "GamePanelStartupTipIndex" /t REG_DWORD /d 3 /f 2>$null|Out-Null
        $global:opts++;Write-Success "Xbox Game Bar: OFF | DVR cattura: OFF"
        $aggStep++

        # ── GAME MODE ON ─────────────────────────────────────────────────────
        # Windows Game Mode: priorità risorse al processo in foreground gaming
        Write-Info "[$aggStep] Windows Game Mode ON..."
        reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 1 /f 2>$null|Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 1 /f 2>$null|Out-Null
        $global:opts++;Write-Success "Game Mode: ON (priorità risorse al gioco)"
        $aggStep++

        # ── USB SELECTIVE SUSPEND OFF ────────────────────────────────────────
        # Impedisce a Windows di sospendere USB — no micro-freeze su input da mouse/tastiera
        Write-Info "[$aggStep] USB Selective Suspend OFF..."
        powercfg /setacvalueindex $pg2 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
        powercfg /setdcvalueindex $pg2 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
        powercfg /setactive $pg2 2>$null
        $global:opts++;Write-Success "USB Selective Suspend: OFF lato power plan (senza toccare direttamente lo stack USB)"
        $aggStep++

        # ── STORAGE: NVMe/SSD TWEAKS ─────────────────────────────────────────
        # Rileva se c'è un NVMe e applica ottimizzazioni I/O
        Write-Info "[$aggStep] Storage optimization..."
        $nvmeFound = Get-PhysicalDisk -EA SilentlyContinue | Where-Object { $_.MediaType -eq "SSD" -or $_.BusType -eq "NVMe" }
        if($nvmeFound){
            # Write cache abilitata sui dischi SSD/NVMe
            foreach($disk in $nvmeFound){
                try{
                    Set-Disk -Number $disk.DeviceId -IsReadOnly $false -EA SilentlyContinue
                } catch{}
            }
            # StorNVMe - coda profonda (QD32)
            $storPath = "HKLM:\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device"
            if(!(Test-Path $storPath)){New-Item $storPath -Force -EA SilentlyContinue|Out-Null}
            Set-ItemProperty $storPath -Name "TreatAsInternalPort" -Value @(0,1,2,3,4,5) -Type MultiString -Force -EA SilentlyContinue
            # Disabilita idle power management NVMe
            $nvmePath = "HKLM:\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device"
            if(!(Test-Path $nvmePath)){New-Item $nvmePath -Force -EA SilentlyContinue|Out-Null}
            Set-ItemProperty $nvmePath -Name "IdlePowerManagement" -Value 0 -Type DWord -Force -EA SilentlyContinue
            # TRIM abilitato
            fsutil behavior set disableDeleteNotify 0 2>$null|Out-Null
            $global:opts++;Write-Success "Storage: NVMe/SSD rilevato — TRIM ON, Idle PM OFF, QD32"
        } else {
            Write-Host "  → Storage: nessun NVMe/SSD rilevato, skip" -F DarkGray
        }
        $aggStep++

        # ── SERVIZI NON NECESSARI PER GAMING ────────────────────────────────
        # Solo servizi sicuri da disabilitare su PC gaming dedicato
        Write-Info "[$aggStep] Servizi secondari non essenziali..."
        $svcsToDisable = @(
            @{Name="Fax";             Desc="Servizio Fax"}
            @{Name="MapsBroker";      Desc="Download mappe offline"}
            @{Name="RetailDemo";      Desc="Modalità demo negozio"}
            @{Name="RemoteRegistry";  Desc="Registro remoto"}
            @{Name="dmwappushservice";Desc="WAP Push Message Routing"}
        )
        $svcOff = 0
        foreach($svc in $svcsToDisable){
            try{
                $s = Get-Service -Name $svc.Name -EA SilentlyContinue
                if($s -and $s.StartType -ne "Disabled"){
                    Stop-Service -Name $svc.Name -Force -EA SilentlyContinue
                    Set-Service  -Name $svc.Name -StartupType Disabled -EA SilentlyContinue
                    $svcOff++
                }
            }catch{}
        }
        $global:opts++;Write-Success "Servizi disabilitati: $svcOff (Fax/Mappe/Demo/RemoteRegistry/WAP Push)"
        $aggStep++

        # ── FULLSCREEN OPTIMIZATIONS DISABLE ────────────────────────────────
        # Le FSO di Windows possono causare stuttering in alcuni giochi
        # Disabilitarle globalmente ripristina il comportamento exclusive fullscreen
        Write-Info "[$aggStep] Fullscreen Optimizations OFF..."
        reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d 2 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 1 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d 1 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEBehaviorMode" /t REG_DWORD /d 2 /f 2>$null|Out-Null
        $global:opts++;Write-Success "Fullscreen Optimizations: OFF (exclusive FS nativo)"
        $aggStep++

        # ── GPU IRQ PRIORITY ─────────────────────────────────────────────────
        # Rileva GPU NVIDIA o AMD e imposta priorità interrupt hardware
        Write-Info "[$aggStep] GPU IRQ / Driver tweaks..."
        $gpuName = (Get-CimInstance Win32_VideoController -EA SilentlyContinue | Select-Object -First 1).Name
        if($gpuName -match "NVIDIA"){
            Write-Host "  → GPU NVIDIA rilevata: evitati tweak legacy PowerMizer/PerfLevelSrc nel registry driver." -F DarkGray
            Write-Host "  → Su RTX moderne conta di più usare driver Game Ready aggiornato, profilo NVIDIA App/Pannello e HAGS quando stabile." -F DarkGray
            $global:opts++;Write-Success "GPU NVIDIA rilevata: nessun registry tweak legacy al driver"
        } elseif($gpuName -match "AMD|Radeon"){
            # AMD - disabilita PowerPlay throttling
            reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "PP_SclkDeepSleepDisable"  /t REG_DWORD /d 1 /f 2>$null|Out-Null
            reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "PP_ThermalAutoThrottlingEnable" /t REG_DWORD /d 0 /f 2>$null|Out-Null
            $global:opts++;Write-Success "GPU AMD rilevata: PowerPlay deep sleep OFF, throttling OFF"
        } else {
            Write-Host "  → GPU: $gpuName — tweaks specifici non applicati" -F DarkGray
        }
        $aggStep++

        # ── WINDOWS ERROR REPORTING: LASCIA ATTIVO ──────────────────────────
        Write-Info "[$aggStep] Windows Error Reporting lasciato attivo..."
        Write-Host "  → WER resta disponibile: utile per diagnosi crash, dump e compatibilita driver." -F DarkGray
        $global:opts++;Write-Success "Windows Error Reporting: invariato"
        $aggStep++

        # ── POWER THROTTLING: APPROCCIO PRUDENTE ─────────────────────────────
        Write-Info "[$aggStep] Power Throttling prudente..."
        $ptPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
        if(!(Test-Path $ptPath)){New-Item $ptPath -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $ptPath -Name "PowerThrottlingOff" -Value 0 -Type DWord -Force -EA SilentlyContinue
        $global:opts++;Write-Success "Power Throttling: gestione nativa Windows"
        $aggStep++

        # ── MANUTENZIONE AUTOMATICA: LASCIA ATTIVA ──────────────────────────
        Write-Info "[$aggStep] Manutenzione automatica lasciata attiva..."
        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v "MaintenanceDisabled" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        Enable-ScheduledTask -TaskName "\Microsoft\Windows\TaskScheduler\Regular Maintenance"      -EA SilentlyContinue|Out-Null
        Enable-ScheduledTask -TaskName "\Microsoft\Windows\TaskScheduler\Maintenance Configurator" -EA SilentlyContinue|Out-Null
        $global:opts++;Write-Success "Manutenzione automatica: invariata"
        $aggStep++

        # ── WINDOWS SEARCH INDEXING: APPROCCIO PRUDENTE ─────────────────────
        Write-Info "[$aggStep] Windows Search lasciato su avvio manuale..."
        try{
            Set-Service  "WSearch" -StartupType Manual -EA SilentlyContinue
            $global:opts++;Write-Success "Search Indexing: manuale su richiesta, non disabilitato"
        }catch{ Write-Host "  → Search Indexing: skip" -F DarkGray }
        $aggStep++

        # ── GPU PREEMPTION GRANULARITY ───────────────────────────────────────
        # Controlla quanto spesso il GPU scheduler può interrompere un task grafico.
        # "Batch" = interrompe meno spesso → frame più fluidi, meno overhead scheduling.
        Write-Info "[$aggStep] GPU scheduler: nessuna modifica undocumented..."
        Write-Host "  → Evitato il tweak manuale della preemption GPU: meglio driver WHQL e pannello vendor." -F DarkGray
        $global:opts++;Write-Success "GPU scheduler: invariato"
        $aggStep++

        # ── INTERRUPT AFFINITY POLICY ────────────────────────────────────────
        # Sposta gli interrupt di GPU lontano dal core 0 (di solito saturato
        # dal sistema operativo). Assegna a core 1 → meno contesa su interrupt.
        Write-Info "[$aggStep] Interrupt Affinity Policy..."
        $iapBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Class"
        # GPU - classe display adapter
        $gpuClass = "$iapBase\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
        if(Test-Path $gpuClass){
            Set-ItemProperty $gpuClass -Name "MSISupported" -Value 1 -Type DWord -Force -EA SilentlyContinue
        }
        $global:opts++;Write-Success "MSI Interrupts: abilitati sulla GPU (meno latenza interrupt)"
        $aggStep++

        # ── DISABILITA AGGIORNAMENTI AUTOMATICI DURANTE GAMING ───────────────
        # Active Hours impostato 8:00-23:00 — Windows non riavvia/aggiorna di giorno.
        Write-Info "[$aggStep] Windows Update gaming-friendly..."
        $wuPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
        if(!(Test-Path $wuPath)){New-Item $wuPath -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $wuPath -Name "ActiveHoursStart"               -Value 8  -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $wuPath -Name "ActiveHoursEnd"                 -Value 23 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $wuPath -Name "IsActiveHoursEnabled"           -Value 1  -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $wuPath -Name "SmartActiveHoursState"          -Value 1  -Type DWord -Force -EA SilentlyContinue
        # Delivery Optimization: disabilita condivisione P2P su internet
        $doPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
        if(!(Test-Path $doPath)){New-Item $doPath -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $doPath -Name "DODownloadMode" -Value 1 -Type DWord -Force -EA SilentlyContinue
        $global:opts++;Write-Success "Windows Update: Active Hours 8-23, P2P OFF (banda non condivisa)"
        $aggStep++

        # ── VISUAL LATENCY: DWM FLUSH + FLIP MODEL ──────────────────────────
        # DirectX Flip Model: riduce la latenza di visualizzazione del frame finale.
        # DXGI_SWAP_EFFECT_FLIP_DISCARD già preferito dai giochi moderni —
        # questi valori assicurano che Windows non forzi comportamenti legacy.
        Write-Info "[$aggStep] DirectX Flip Model / latenza display..."
        if(Get-OgdDx9SafeMode){
            Write-Warning 'Modalità DX9 legacy attiva: tweak DirectX moderni saltati per compatibilità'
        } else {
            reg add "HKCU\SOFTWARE\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "SwapEffectUpgradeEnable=1;" /f 2>$null|Out-Null
            $dwmPath = "HKCU:\Software\Microsoft\Windows\DWM"
            if(!(Test-Path $dwmPath)){New-Item $dwmPath -Force -EA SilentlyContinue|Out-Null}
            Set-ItemProperty $dwmPath -Name "OverlayTestMode" -Value 5 -Type DWord -Force -EA SilentlyContinue
            $global:opts++;Write-Success 'DirectX Flip Model: ON (latenza display ridotta)'
        }
        $aggStep++

        # ── ACCESSIBILITÀ FONT (SOLO SU RICHIESTA) ───────────────────────────
        Write-Info "[$aggStep] Accessibilità font..."
        Write-Host '  → OpenDyslexic non viene più installato in automatico.' -F DarkGray
        Write-Host '  → Usa il menu [H] HOTFIX se hai dislessia, installazione parziale' -F DarkGray
        Write-Host '    oppure se vuoi disinstallarlo/ripristinare i font standard.' -F DarkGray
        Write-Success 'Accessibilità rispettata: nessuna sostituzione font automatica'
        $aggStep++

        # ── PRIVACY AGGIUNTIVA (se scelta) ─────────────────────────────────
        if($privacyLevel -ne "0"){
            Write-Info "[LP] Protezione Privacy $(switch($privacyLevel){"1"{"LIGHT"}"2"{"NORMALE"}"3"{"AGGRESSIVO"}"4"{"PARANOICO"}})..."
            if($privacyLevel -ge "1"){
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f 2>$null|Out-Null
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f 2>$null|Out-Null
            }
            if($privacyLevel -ge "2"){
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocation" /t REG_DWORD /d 1 /f 2>$null|Out-Null
                reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" /v "Value" /t REG_SZ /d "Deny" /f 2>$null|Out-Null
                reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" /v "Value" /t REG_SZ /d "Deny" /f 2>$null|Out-Null
            }
            if($privacyLevel -ge "3"){
                reg add "HKCU\Software\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d 0 /f 2>$null|Out-Null
            }
            if($privacyLevel -eq "4"){
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f 2>$null|Out-Null
            }
            Write-Success "Privacy: Livello $privacyLevel applicato"
        }

    }  # End if($isLaptop)

    # ── AGGRESSIVO GAMING LIGHT ───────────────────────────────────────────────
    if($doAggrGL){
        Write-Host ""
        Write-Section "AGGRESSIVO GAMING — LIGHT"

        Write-Info "[GL1] Game Mode + DVR OFF..."
        reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled"   /t REG_DWORD /d 1 /f 2>$null|Out-Null
        reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode"     /t REG_DWORD /d 1 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore"     /v "GameDVR_Enabled"       /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        Write-Success "Game Mode: ON | DVR: OFF"

        Write-Info "[GL2] Process priority launcher gaming..."
        $gpGames = @("gameoverlayui.exe","steam.exe","EpicGamesLauncher.exe","Battle.net.exe","Origin.exe","discord.exe")
        foreach($gp in $gpGames){
            $rg="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$gp\PerfOptions"
            if(!(Test-Path $rg)){New-Item $rg -Force -EA SilentlyContinue|Out-Null}
            Set-ItemProperty $rg -Name "CpuPriorityClass" -Value 3 -Type DWord -Force -EA SilentlyContinue
            Set-ItemProperty $rg -Name "IoPriority"       -Value 3 -Type DWord -Force -EA SilentlyContinue
        }
        Write-Success "Launcher gaming (Steam/Epic/Discord): priorità High"

        Write-Info "[GL3] Fullscreen Optimizations OFF..."
        reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode"          /t REG_DWORD /d 2 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 1 /f 2>$null|Out-Null
        Write-Success "Fullscreen: ottimizzato"

        Write-Info "[GL4] Mouse acceleration OFF + input latency ridotta..."
        reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed"      /t REG_SZ /d "0" /f 2>$null|Out-Null
        reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f 2>$null|Out-Null
        reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f 2>$null|Out-Null
        reg add "HKCU\Control Panel\Desktop" /v "LowLevelHooksTimeout" /t REG_DWORD /d 1000 /f 2>$null|Out-Null
        Write-Success "Input: mouse lineare, hook timeout ridotto"

        $global:opts++
    }

    # ── AGGRESSIVO GAMING NORMALE ─────────────────────────────────────────────
    if($doAggrGN){
        Write-Host ""
        Write-Section "AGGRESSIVO GAMING — NORMALE"

        Write-Info "[GN1] MMCSS Games + Pro Audio priorità massima..."
        $mm="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks"
        Set-ItemProperty "$mm\Games"     -Name "Priority"            -Value 6     -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty "$mm\Games"     -Name "Scheduling Category" -Value "High"            -Force -EA SilentlyContinue
        Set-ItemProperty "$mm\Games"     -Name "SFIO Priority"       -Value "High"            -Force -EA SilentlyContinue
        Set-ItemProperty "$mm\Games"     -Name "GPU Priority"        -Value 8     -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty "$mm\Games"     -Name "Clock Rate"          -Value 10000 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty "$mm\Pro Audio" -Name "Priority"            -Value 1     -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty "$mm\Pro Audio" -Name "Scheduling Category" -Value "High"            -Force -EA SilentlyContinue
        Write-Success "MMCSS: Games Priority 6 GPU 8, Pro Audio High"

        Write-Info "[GN2] CPU Boost gaming piu prudente..."
        $pgGN=(powercfg /getactivescheme) -match 'GUID:\s+([a-f0-9\-]+)'
        if($pgGN){$pgGN=$Matches[1]}else{$pgGN="SCHEME_CURRENT"}
        powercfg /setacvalueindex $pgGN SUB_PROCESSOR PERFBOOSTMODE    1  2>$null
        powercfg /setdcvalueindex $pgGN SUB_PROCESSOR PERFBOOSTMODE    1  2>$null
        powercfg /setacvalueindex $pgGN SUB_PROCESSOR PROCTHROTTLEMIN  15 2>$null
        powercfg /setdcvalueindex $pgGN SUB_PROCESSOR PROCTHROTTLEMIN  8  2>$null
        powercfg /setacvalueindex $pgGN SUB_PROCESSOR PERFINCTHRESHOLD 12 2>$null
        powercfg /setdcvalueindex $pgGN SUB_PROCESSOR PERFINCTHRESHOLD 12 2>$null
        powercfg /setacvalueindex $pgGN SUB_PROCESSOR PERFDECTHRESHOLD 10 2>$null
        powercfg /setdcvalueindex $pgGN SUB_PROCESSOR PERFDECTHRESHOLD 10 2>$null
        powercfg /setactive $pgGN 2>$null
        Write-Success "CPU: boost gaming prudente, min 15% in AC / 8% in DC"

        Write-Info "[GN3] Power Throttling prudente..."
        $ptpGN="HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
        if(!(Test-Path $ptpGN)){New-Item $ptpGN -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $ptpGN -Name "PowerThrottlingOff" -Value 0 -Type DWord -Force -EA SilentlyContinue
        Write-Success "Power Throttling: gestione nativa"

        Write-Info "[GN4] Responsiveness gaming..."
        $mmspGN="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Set-ItemProperty $mmspGN -Name "SystemResponsiveness"   -Value 0          -Type DWord -Force -EA SilentlyContinue
        Write-Success "SystemResponsiveness 0"

        Write-Info "[GN5] GPU HwScheduling + DirectX Flip Model..."
        $gdGN="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        Set-ItemProperty $gdGN -Name "HwSchMode" -Value 2  -Type DWord -Force -EA SilentlyContinue
        reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "SwapEffectUpgradeEnable=1;VRROptimizeEnable=0;" /f 2>$null|Out-Null
        Write-Success "GPU: HwSch ON, Flip Model ON"

        Write-Info "[GN6] USB Suspend OFF..."
        powercfg /setacvalueindex $pgGN 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
        powercfg /setactive $pgGN 2>$null
        Write-Success "USB Selective Suspend: OFF"

        $global:opts++
    }

    # ═══════════════════════════════════════════════════════════════════════
    #  AGGRESSIVO GAMING FULL — Win11 tweaks nascosti + estremi per PC potenti
    # ═══════════════════════════════════════════════════════════════════════

    if($doAggrG){
        Write-Host ""
        Write-Section "AGGRESSIVO GAMING — TWEAKS ESTREMI"
        Write-Host ""

        # ── WIN11 TWEAKS NASCOSTI ──────────────────────────────────────────
        Write-Info "[AG1] Win11 hidden tweaks — registro non documentato..."

        # Disabilita Activity History e Timeline
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed"    /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities"  /t REG_DWORD /d 0 /f 2>$null|Out-Null

        # Disabilita Consumer Features (app suggerite, ads in Start)
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f 2>$null|Out-Null
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338393Enabled" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353694Enabled" /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353696Enabled" /t REG_DWORD /d 0 /f 2>$null|Out-Null

        # Fast Startup OFF (può causare problemi con hardware gaming)
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d 0 /f 2>$null|Out-Null

        # Disabilita Automatic Maintenance durante gaming
        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v "MaintenanceDisabled" /t REG_DWORD /d 1 /f 2>$null|Out-Null

        # Storage Sense OFF (non pulisce automaticamente durante il gaming)
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "01" /t REG_DWORD /d 0 /f 2>$null|Out-Null

        # Disabilita Reserved Storage Windows Update (libera GB di spazio)
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v "ShippedWithReserves" /t REG_DWORD /d 0 /f 2>$null|Out-Null

        # Large Address Aware per app 32bit (usa più di 2GB RAM)
        # [FIX EAC]: Rimosso. Inserire questo valore nel root di IFEO causa flag di tampering e blocca Easy Anti-Cheat.
        # reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options" /v "LargeAddressAware" /t REG_DWORD /d 1 /f 2>$null|Out-Null

        # Disabilita pointer compression RAM (riduce overhead su RAM abbondante)
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePageCombining" /t REG_DWORD /d 1 /f 2>$null|Out-Null

        Write-Success "Win11 hidden tweaks: 14 ottimizzazioni applicate"

        # ── CPU ESTREMO ────────────────────────────────────────────────────
        Write-Info "[AG2] CPU avanzato — scheduler e boost..."

        # Disabilita CPU throttling per processi foreground
        $ptp2="HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
        if(!(Test-Path $ptp2)){New-Item $ptp2 -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $ptp2 -Name "PowerThrottlingOff" -Value 0 -Type DWord -Force -EA SilentlyContinue

        # Processor boost: impostazione pratica, senza tenere la CPU sempre al massimo
        $pg=(powercfg /getactivescheme) -match 'GUID:\s+([a-f0-9\-]+)'
        if($pg){$pg=$Matches[1]}else{$pg="SCHEME_CURRENT"}
        powercfg /setacvalueindex $pg SUB_PROCESSOR PERFBOOSTMODE   1 2>$null
        powercfg /setacvalueindex $pg SUB_PROCESSOR PROCTHROTTLEMIN 5   2>$null
        powercfg /setacvalueindex $pg SUB_PROCESSOR PERFINCTHRESHOLD 10 2>$null
        powercfg /setacvalueindex $pg SUB_PROCESSOR PERFDECTHRESHOLD 8  2>$null
        powercfg /setacvalueindex $pg SUB_PROCESSOR PERFINCTIME      1  2>$null
        powercfg /setacvalueindex $pg SUB_PROCESSOR PERFDECTIME      1  2>$null
        powercfg /setactive $pg 2>$null

        # Core Parking: lasciato gestire a Windows per evitare consumi e temperature inutili

        # CPU heterogeneous policy: performance core first
        $cpuSched = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"
        if(!(Test-Path $cpuSched)){New-Item $cpuSched -Force -EA SilentlyContinue|Out-Null}
        Set-ItemProperty $cpuSched -Name "GlobalTimerResolutionRequests" -Value 1 -Type DWord -Force -EA SilentlyContinue

        # Quantum: valore conservativo e compatibile
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 0x26 /f 2>$null|Out-Null

        Write-Success "CPU avanzato: boost bilanciato, throttle nativo, quantum conservativo"

        # ── GPU ESTREMO ────────────────────────────────────────────────────
        Write-Info "[AG3] GPU estremo — latenza e scheduling..."

        # Hardware GPU Scheduling + Flip Model
        $gp="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        Set-ItemProperty $gp -Name "HwSchMode"          -Value 2  -Type DWord -Force -EA SilentlyContinue
        Write-Success "GPU avanzato: HwSch ON, nessun TDR tweak placebo, nessun tweak Hyper-V o scheduler sperimentale"

        # ── RAM ESTREMA ────────────────────────────────────────────────────
        Write-Info "[AG4] RAM pratica — cache e gestione sicura..."

        $mp="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

        # Working Set: niente tweak aggressivi del kernel paging
        Set-ItemProperty $mp -Name "DisablePagingExecutive"   -Value 0 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $mp -Name "LargeSystemCache"         -Value 0 -Type DWord -Force -EA SilentlyContinue

        # Evita pool tuning manuale: meglio lasciare che sia Windows a dimensionare dinamicamente
        Remove-ItemProperty -Path $mp -Name "NonPagedPoolSize" -Force -EA SilentlyContinue
        Remove-ItemProperty -Path $mp -Name "SessionViewSize" -Force -EA SilentlyContinue

        # Prefetch/SysMain: approccio prudente
        $pp="$mp\PrefetchParameters"
        Set-ItemProperty $pp -Name "EnableSuperfetch"  -Value 3 -Type DWord -Force -EA SilentlyContinue
        Set-ItemProperty $pp -Name "EnablePrefetcher"  -Value 3 -Type DWord -Force -EA SilentlyContinue

        Write-Success "RAM pratica: paging kernel nativo, cache prudente, niente pool tuning manuale"

        # ── SISTEMA OPERATIVO OTTIMIZZAZIONI NASCOSTE ──────────────────────
        Write-Info "[AG5] OS ottimizzazioni nascoste Win11..."

        # NTFS: disabilita update dei timestamp (già in FileIO ma lo forzo)
        fsutil behavior set disablelastaccess 1 2>$null|Out-Null
        fsutil behavior set disable8dot3      1 2>$null|Out-Null

        # IRQ8: riduce priorità real time clock (meno interrupt inutili)
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "IRQ8Priority" /t REG_DWORD /d 1 /f 2>$null|Out-Null

        # Disabilita prefetch SSD (non necessario su NVMe)
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableBootTrace" /t REG_DWORD /d 0 /f 2>$null|Out-Null

        # Network: evita tweak TCP legacy globali
        Write-Host "  → Saltati i vecchi tweak TCP globali (TcpAckFrequency/TCPNoDelay/TcpDelAckTicks): su Windows 11 moderno e giochi recenti sono spesso placebo o situazionali." -F DarkGray

        # Win32 priority boost: massimo per thread gaming
        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f 2>$null|Out-Null

        # Disabilita crash dump (risparmia I/O e RAM su crash)
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "CrashDumpEnabled"     /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "AutoReboot"           /t REG_DWORD /d 1 /f 2>$null|Out-Null

        # Disabilita error reporting automatico
        reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f 2>$null|Out-Null
        Disable-ScheduledTask -TaskName "Microsoft\Windows\Windows Error Reporting\QueueReporting" -EA SilentlyContinue | Out-Null

        Write-Success "OS nascosti: NTFS, IRQ8, LLMNR OFF, Win32 boost max, CrashDump OFF"

        # ── SERVIZI NON NECESSARI SU PC GAMING ────────────────────────────
        Write-Info "[AG6] Servizi inutili su PC gaming puro..."

        $aggrSvcs = @(
            "DiagTrack",         # Telemetria connessa
            "dmwappushservice",  # Push messaggi WAP
            "MapsBroker",        # Download mappe offline
            "lfsvc",             # Geolocalizzazione
            "SharedAccess",      # Internet Connection Sharing
            "WMPNetworkSvc",     # Windows Media Player sharing
            "icssvc",            # Mobile hotspot
            "PcaSvc",            # Compatibility Assistant
            "RemoteRegistry"     # Registro remoto
        )
        $disabled = 0
        foreach($svc in $aggrSvcs){
            try{
                $s = Get-Service $svc -EA SilentlyContinue
                if($s -and $s.StartType -ne "Disabled"){
                    Stop-Service $svc -Force -EA SilentlyContinue
                    Set-Service  $svc -StartupType Disabled -EA SilentlyContinue
                    $disabled++
                }
            }catch{}
        }
        Write-Success "Servizi disabilitati: $disabled su $($aggrSvcs.Count)"

        # ── GAME MODE + FULLSCREEN OTTIMIZZATO ────────────────────────────
        Write-Info "[AG7] Game Mode + Fullscreen estremo..."

        reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled"  /t REG_DWORD /d 1 /f 2>$null|Out-Null
        reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode"    /t REG_DWORD /d 1 /f 2>$null|Out-Null
        reg add "HKCU\Software\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 0 /f 2>$null|Out-Null

        # Fullscreen Optimizations: OFF (più controllo diretto al gioco)
        reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled"               /t REG_DWORD /d 0 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior"            /t REG_DWORD /d 2 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode"        /t REG_DWORD /d 2 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 1 /f 2>$null|Out-Null
        reg add "HKCU\System\GameConfigStore" /v "Win32_AutoGameModeDefaultProfile" /t REG_BINARY /d "02000000000000000000000000000000" /f 2>$null|Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f 2>$null|Out-Null

        Write-Success "Game Mode ON, DVR OFF, FSE ottimizzato"

        $global:opts++
        Write-Host ""
        Write-Success "⚡ AGGRESSIVO GAMING: 7 blocchi tweaks applicati"
    }

    # ═══════════════════════════════════════════════════════════════════════
    #  MODALITÀ 4-5: LAPTOP / LAPTOP GAMING
    # ═══════════════════════════════════════════════════════════════════════

    if($isLaptop){
        Write-Host ""
        Write-Section "APPLICAZIONE TWEAKS LAPTOP"
        Write-Host ""

        # ── LIGHT: tweaks base sicuri per laptop ────────────────────────────
        if($doLL){
            Write-Info "[L1] Timer tool opzionale + Privacy base..."
            Write-Host "  → Saltati i tweak bcdedit del clock/timer come preset base: meglio lasciare la gestione low-level a Windows salvo test mirati." -F DarkGray
            # Timer script v2.2 Desktop
            $timerDest2 = Join-Path ([Environment]::GetFolderPath("Desktop")) "OGD_Timer_0.5ms.ps1"
            $timerSrc2  = Join-Path (Split-Path $PSCommandPath) "OGD_Timer_0.5ms.ps1"
            if((Test-Path $timerSrc2) -and ($timerSrc2 -ne $timerDest2)){
                Copy-Item $timerSrc2 $timerDest2 -Force
            } else {
                @'
#Requires -Version 5.1
#Requires -RunAsAdministrator
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class OGDTimer22 {
    [DllImport("ntdll.dll")] public static extern int NtSetTimerResolution(uint desired, bool set, out uint current);
    [DllImport("ntdll.dll")] public static extern int NtQueryTimerResolution(out uint minimum, out uint maximum, out uint current);
}
"@
function Convert-OgdTimerToMs {
    param([uint32]$Value100ns)
    [math]::Round(($Value100ns / 10000.0), 3)
}
function Get-OgdTimerInfo {
    $min=0u; $max=0u; $cur=0u
    [void][OGDTimer22]::NtQueryTimerResolution([ref]$min,[ref]$max,[ref]$cur)
    [pscustomobject]@{ Minimum100ns=$min; Maximum100ns=$max; Current100ns=$cur; CurrentMs=(Convert-OgdTimerToMs $cur) }
}
$Host.UI.RawUI.WindowTitle='Windows Timer Session'
$requested=5000u
$before=Get-OgdTimerInfo
$target=if($requested -lt $before.Maximum100ns){ $before.Maximum100ns } else { $requested }
$released=$false
$c=0u; $r=[OGDTimer22]::NtSetTimerResolution($target,$true,[ref]$c)
if($r -ne 0){ Write-Host "Errore impostazione timer (codice $r)" -ForegroundColor Red; Read-Host; exit 1 }
Register-EngineEvent PowerShell.Exiting -Action { if(-not $script:released){ $tmp=0u; [void][OGDTimer22]::NtSetTimerResolution($script:target,$false,[ref]$tmp); $script:released=$true } } | Out-Null
Write-Host 'Windows Timer Session attiva' -ForegroundColor Green
Write-Host ("Risoluzione attuale: {0} ms" -f ((Get-OgdTimerInfo).CurrentMs)) -ForegroundColor White
Write-Host 'Lascia la finestra aperta o minimizzata e chiudila a fine sessione.' -ForegroundColor DarkGray
while($true){
    Start-Sleep -Seconds 20
    $now=Get-OgdTimerInfo
    if($now.Current100ns -gt $target){ $tmp=0u; [void][OGDTimer22]::NtSetTimerResolution($target,$true,[ref]$tmp) }
}
'@|Out-File $timerDest2 -Encoding UTF8 -Force
            }
            Write-Success "Timer: tool opzionale v2.2 copiato sul Desktop per test comparativi"

            Write-Info "[L2] Privacy base..."
            $tp="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
            if(!(Test-Path $tp)){New-Item $tp -Force -EA SilentlyContinue|Out-Null}
            Set-ItemProperty $tp -Name "AllowTelemetry" -Value 0 -Type DWord -Force -EA SilentlyContinue
            Write-Success "Privacy: Telemetry OFF"

            Write-Info "[L3] Winsock reset prudente..."
            netsh winsock reset|Out-Null
            Write-Success "Winsock: reset completato"

            Write-Info "[L4] GPU HwScheduling..."
            $gp="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
            Set-ItemProperty $gp -Name "HwSchMode" -Value 2 -Type DWord -Force -EA SilentlyContinue
            Write-Success "GPU: HwScheduling ON (senza TDR tweak)"

            # C-States laptop: solo C1 (niente C0 package — preserva batteria)
            Write-Info "[L5] C-States laptop (C1 balanced)..."
            $pg=(powercfg /getactivescheme) -match 'GUID:\s+([a-f0-9\-]+)'
            if($pg){$pg=$Matches[1]}else{$pg="SCHEME_CURRENT"}
            powercfg /setacvalueindex $pg SUB_PROCESSOR IDLESTATEMAX 1 2>$null
            powercfg /setactive $pg 2>$null
            Write-Success "C-States: C1 balanced (batteria preservata)"

            $global:opts++
        }

        # ── NORMALE: process priority + debloat + visual ────────────────────
        if($doLN){
            Write-Info "[N1] Process Priority (laptop-safe)..."
            $pmap=@{"High"=3;"AboveNormal"=6;"Normal"=2;"BelowNormal"=5;"Low"=1}
            $imap=@{"High"=3;"Normal"=2;"Low"=1}
            $lprocs=@{
                "explorer.exe"=@{P="AboveNormal";I="Normal"}
                "msedge.exe"=@{P="AboveNormal";I="Normal"}
                "msedgewebview2.exe"=@{P="AboveNormal";I="Normal"}
                "dwm.exe"=@{P="High";I="High"}
                "audiodg.exe"=@{P="High";I="High"}
                "csrss.exe"=@{P="High";I="High"}
                "SearchIndexer.exe"=@{P="BelowNormal";I="Low"}
                "SysMain"=@{P="BelowNormal";I="Low"}
            }
            foreach($pn in $lprocs.Keys){
                $pi=$lprocs[$pn]
                $rp="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$pn\PerfOptions"
                if(!(Test-Path $rp)){New-Item $rp -Force -EA SilentlyContinue|Out-Null}
                Set-ItemProperty $rp -Name "CpuPriorityClass" -Value $pmap[$pi.P] -Type DWord -Force -EA SilentlyContinue
                Set-ItemProperty $rp -Name "IoPriority" -Value $imap[$pi.I] -Type DWord -Force -EA SilentlyContinue
            }
            Write-Success "Process: Priorità ottimizzate (laptop-safe)"

            Write-Info "[N2] Debloat base..."
            $debloatLaptop = Invoke-OgdAlternativeDebloat -Mode Base -IncludeRecall
            Write-Success ("Debloat base: motore AWin11DebloatAlternative | app rimosse {0} | Spotify/Xbox preservati" -f $debloatLaptop.RemovedCommonApps)

            Write-Info "[N3] Visual ottimizzato..."
            Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type DWord -Force -EA SilentlyContinue
            Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Type String -Force -EA SilentlyContinue
            reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f 2>$null|Out-Null
            reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f 2>$null|Out-Null
            reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f 2>$null|Out-Null
            Write-Success "Visual: Trasparenza OFF, menu istantanei, mouse lineare"

            $global:opts++
        }

        # ── ALTO: piano prestazioni + throttling OFF (in carica) ────────────
        if($doLA){
            Write-Info "[A1] Piano Ultimate (in carica)..."
            $ult=powercfg /list 2>$null|Select-String "Ultimate|Prestazioni ultimate"
            if($ult -and $ult.ToString() -match '([a-f0-9-]{36})'){
                powercfg /setactive $Matches[1] 2>$null
                powercfg /setacvalueindex $Matches[1] SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null
                powercfg /setdcvalueindex $Matches[1] SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null
            }else{
                $ng=powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
                if($ng -match '([a-f0-9-]{36})'){
                    powercfg /changename $Matches[1] "Ultimate OGD Laptop" 2>$null
                    powercfg /setactive $Matches[1] 2>$null
                powercfg /setacvalueindex $Matches[1] SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null
                powercfg /setdcvalueindex $Matches[1] SUB_PROCESSOR PROCTHROTTLEMIN 5 2>$null
                }
            }
            Write-Success "Piano: Ultimate attivato"

            Write-Info "[A2] Power Throttling prudente (in carica)..."
            $ptp="HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
            if(!(Test-Path $ptp)){New-Item $ptp -Force -EA SilentlyContinue|Out-Null}
            Set-ItemProperty $ptp -Name "PowerThrottlingOff" -Value 0 -Type DWord -Force -EA SilentlyContinue
            Write-Success "Power Throttling: gestione nativa"

            Write-Info "[A3] MMCSS Games + Pro Audio..."
            $mm="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks"
            Set-ItemProperty "$mm\Games" -Name "Priority"         -Value 6  -Type DWord -Force -EA SilentlyContinue
            Set-ItemProperty "$mm\Games" -Name "Scheduling Category" -Value "High" -Force -EA SilentlyContinue
            Set-ItemProperty "$mm\Pro Audio" -Name "Priority"     -Value 1  -Type DWord -Force -EA SilentlyContinue
            Write-Success "MMCSS: Games High, Pro Audio ottimizzato"

            Write-Info "[A4] Responsiveness gaming..."
            Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness"   -Value 3        -Type DWord -Force -EA SilentlyContinue
            Write-Success "SystemResponsiveness 3"

            $global:opts++
        }

        # ── ULTRA: massima performance (solo in carica!) ─────────────────────
        if($doLU){
            Write-Host "`n  ⚠️  ULTRA: ottimizza per massima performance" -F Yellow
            Write-Host "     Usa solo con laptop in carica!`n" -F Yellow

            Write-Info "[U1] CPU Boost reattivo..."
            $pg=(powercfg /getactivescheme) -match 'GUID:\s+([a-f0-9\-]+)'
            if($pg){$pg=$Matches[1]}else{$pg="SCHEME_CURRENT"}
            powercfg /setacvalueindex $pg SUB_PROCESSOR PERFBOOSTMODE 1 2>$null
            powercfg /setacvalueindex $pg SUB_PROCESSOR PROCTHROTTLEMIN 15 2>$null
            powercfg /setactive $pg 2>$null
            Write-Success "CPU: boost reattivo, min 15% in carica"

            Write-Info "[U2] Memory ottimizzata ($ramGB GB)..."
            $mp="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
            if($ramGB -ge 16){Set-ItemProperty $mp -Name "DisablePagingExecutive" -Value 0 -Type DWord -Force -EA SilentlyContinue}
            Set-ItemProperty $mp -Name "LargeSystemCache" -Value 0 -Type DWord -Force -EA SilentlyContinue
            $pp="$mp\PrefetchParameters"
            Set-ItemProperty $pp -Name "EnableSuperfetch"  -Value 3 -Type DWord -Force -EA SilentlyContinue
            Set-ItemProperty $pp -Name "EnablePrefetcher"  -Value 3 -Type DWord -Force -EA SilentlyContinue
            Write-Success "Memory: gestione nativa, cache prudente"

            if($isGamingLaptop){
                Write-Info "[U3] Gaming Laptop: GPU max + Game Mode..."
                # GPU High Performance
                $gp2="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
                Set-ItemProperty $gp2 -Name "HwSchMode" -Value 2 -Type DWord -Force -EA SilentlyContinue
                # Game Mode ON
                reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 1 /f 2>$null|Out-Null
                reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode"   /t REG_DWORD /d 1 /f 2>$null|Out-Null
                # Xbox DVR OFF
                reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f 2>$null|Out-Null
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f 2>$null|Out-Null
                # USB Suspend OFF
                $pg3=(powercfg /getactivescheme) -match 'GUID:\s+([a-f0-9\-]+)'
                if($pg3){$pg3=$Matches[1]}else{$pg3="SCHEME_CURRENT"}
                powercfg /setacvalueindex $pg3 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
                powercfg /setactive $pg3 2>$null
                Write-Success "Gaming Laptop: GPU max, Game Mode ON, DVR OFF, USB Suspend OFF"
            }

            $global:opts++
        }
    }

    # RIEPILOGO
    Write-Host "`n  ════════════════════════════════════════════════════" -F Cyan
    Write-Host "   ⚡ OTTIMIZZAZIONE $lvl COMPLETATA - OGD ⚡" -F Yellow
    Show-OgdAppliedSummary $lvl
    Write-Host "  ════════════════════════════════════════════════════`n" -F Cyan
    Write-Success "Ottimizzazioni applicate: $global:opts"
    Write-Host "`n  📊 CONFIGURAZIONE RAM:" -F Cyan
    Write-Host "     Tipo: $(if($isDDR5){'DDR5 ⚡'}else{'DDR4'})" -F White
    Write-Host "     Quantità: $ramGB GB" -F White
    if($mode -eq "3"){
        Write-Host "`n  💾 PARAMETRI MEMORY MANAGEMENT:" -F Cyan
        Write-Host "     Paging Executive: $(if($ramGB -ge 32){'OFF'}else{'ON'})" -F White
        Write-Host "     Large Cache: $(if($isDDR5 -and $ramGB -ge 64){'ON'}else{'OFF'})" -F White
        Write-Host "     Superfetch: $(if($ramGB -le 16){'ON'}elseif($ramGB -le 32){'BOOT'}else{'OFF'})" -F White
        Write-Host "     Prefetcher: $(if($isDDR5){'FULL'}else{'BOOT'})" -F White
        $ioLockValue=if($ramGB -eq 8){512000}elseif($ramGB -eq 12){768000}elseif($ramGB -eq 16){1024000}elseif($ramGB -eq 32){2048000}elseif($ramGB -eq 64){4096000}elseif($ramGB -eq 128){8192000}elseif($ramGB -lt 8){256000}elseif($ramGB -lt 12){640000}elseif($ramGB -lt 16){896000}elseif($ramGB -lt 32){1536000}elseif($ramGB -lt 64){3072000}else{16384000}
        Write-Host "     IO Page Lock: $([math]::Round($ioLockValue/1024,0)) MB" -F White
        $cacheSize=if($ramGB -le 16){512}elseif($ramGB -le 32){1024}elseif($ramGB -le 64){2048}else{4096}
        Write-Host "     L2 Cache: $cacheSize KB" -F White
    }elseif($mode -eq "2"){
        Write-Host "`n  💾 MEMORY (base):" -F Cyan
        Write-Host "     Paging: ON | Superfetch: $(if($ramGB -le 16){'ON'}else{'BOOT'})" -F White
    }
    Write-Host "`n  ⚡ PROSSIMI PASSI:" -F Cyan
    Write-Host "  1. RIAVVIA il PC (obbligatorio)" -F White
    Write-Host "  2. Controlla driver GPU, refresh monitor e impostazioni in-game prima di testare gli FPS" -F White
    Write-Host "  3. OGD_Timer_0.5ms.ps1 resta opzionale: usalo solo per confronto pratico, non come boost garantito`n" -F White
    Write-Info "Punto ripristino disponibile in: Impostazioni → Ripristino sistema"
    Write-Host "`n  ════════════════════════════════════════════════════" -F Cyan
Write-Host "   OGD WinCaffe NEXT v8.1.2" -F Yellow
    Write-Host "   #DarkPlayer84Tv Productions" -F Green
    Write-Host "   by OldGamerDarthy Official" -F Green
    Write-Host "  ════════════════════════════════════════════════════`n" -F Cyan
    
    # ═════════════════════════════════════════════════════════════════════════════
    
    
    if((Read-Host "  Riavviare ORA? (S/N)") -in @("S","s")){
        taskkill /im explorer.exe /f 2>$null|Out-Null;Start-Sleep 1
        Restart-Computer -Force
    }
    continue MenuLoop
}  # End while MenuLoop
}


