[CmdletBinding()]
param(
    [switch]$Install,
    [switch]$Uninstall,
    [string]$Url,
    [ValidateSet('Server', 'Client', 'ServerAndClient')]
    [string]$Role
)

# --- i18n ---

$script:Messages = @{}
$script:FallbackMessages = @{
    'menu_select_action'               = 'Select an action and press Enter:'
    'menu_install'                     = 'Install'
    'menu_uninstall'                   = 'Uninstall'
    'menu_select_role'                 = 'Select a setup role and press Enter:'
    'menu_role_server'                 = 'Server (Sunshine, Tailscale)'
    'menu_role_client'                 = 'Client (Moonlight, Tailscale)'
    'menu_role_server_and_client'      = 'Server and Client (Sunshine, Moonlight, Tailscale)'
    'installing_chocolatey'            = 'Installing Chocolatey...'
    'chocolatey_installed'             = 'Chocolatey is already installed.'
    'prompt_sunshine_address'          = 'Enter the Sunshine server Tailscale address (e.g. 100.*.*.*):'
    'server_address_required'          = 'A server address is required.'
    'installing_server_packages'       = 'Installing Sunshine and Tailscale via Chocolatey in parallel...'
    'installing_client_packages'       = 'Installing Moonlight and Tailscale via Chocolatey in parallel...'
    'installing_server_client_packages' = 'Installing Sunshine, Moonlight, and Tailscale via Chocolatey in parallel...'
    'uninstalling_all_packages'        = 'Uninstalling Sunshine, Moonlight, and Tailscale via Chocolatey...'
    'install_completed'                = 'All installations completed.'
    'press_enter_continue'             = 'When Tailscale setup is complete, press Enter to continue.'
    'opening_local_sunshine_ui'        = 'Opening local Sunshine Web UI...'
    'opening_remote_sunshine_ui'       = 'Opening Sunshine Web UI...'
    'press_enter_launch_moonlight'     = 'Press Enter to launch Moonlight and complete setup.'
    'setup_completed'                  = 'Initial setup completed! You may close this terminal.'
    'uninstall_completed'              = 'Uninstallation completed! You may close this terminal.'
    'press_enter_exit'                 = 'Press Enter to exit'
    'error_install_and_uninstall'      = 'Use either -Install or -Uninstall, not both.'
    'error_url_without_install'        = '-Url can only be used with -Install.'
    'error_role_without_install'       = '-Role can only be used with -Install.'
}

function Get-Message {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Key,
        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [object[]]$Args
    )

    $msg = if ($script:Messages.ContainsKey($Key)) {
        $script:Messages[$Key]
    }
    elseif ($script:FallbackMessages.ContainsKey($Key)) {
        $script:FallbackMessages[$Key]
    }
    else {
        "[$Key]"
    }

    if ($Args) {
        return $msg -f $Args
    }
    return $msg
}

function Initialize-Locale {
    $culture = [System.Globalization.CultureInfo]::CurrentUICulture
    $locale = if ($culture.Name -like 'ko*') { 'ko' } else { 'en' }

    if ($locale -eq 'en') {
        return
    }

    if ($PSScriptRoot) {
        $localPath = Join-Path $PSScriptRoot 'i18n' "$locale.json"
        if (Test-Path $localPath) {
            try {
                $parsed = Get-Content $localPath -Raw -Encoding UTF8 | ConvertFrom-Json
                $parsed.PSObject.Properties | ForEach-Object { $script:Messages[$_.Name] = $_.Value }
                return
            }
            catch {
                # fall through to remote fetch
            }
        }
    }

    $repoBase = 'https://raw.githubusercontent.com/EasyDevv/set-sunshine-moonlight/main/scripts/windows/i18n'
    try {
        $parsed = Invoke-RestMethod "$repoBase/$locale.json"
        $parsed.PSObject.Properties | ForEach-Object { $script:Messages[$_.Name] = $_.Value }
    }
    catch {
        # use embedded fallback
    }
}

# --- UI ---

function Show-Menu {
    param(
        [hashtable[]]$Options,
        [string]$Title
    )

    $selectedIndex = 0

    while ($true) {
        Clear-Host
        if ($Title) {
            Write-Host $Title -ForegroundColor Cyan
            Write-Host ""
        }

        for ($i = 0; $i -lt $Options.Count; $i++) {
            if ($i -eq $selectedIndex) {
                Write-Host "> $($Options[$i].Label)" -ForegroundColor Green
            }
            else {
                Write-Host "  $($Options[$i].Label)"
            }
        }

        $key = [System.Console]::ReadKey($true)

        switch ($key.Key) {
            'UpArrow' {
                if ($selectedIndex -gt 0) {
                    $selectedIndex--
                }
            }
            'DownArrow' {
                if ($selectedIndex -lt ($Options.Count - 1)) {
                    $selectedIndex++
                }
            }
            'Enter' {
                return $Options[$selectedIndex].Value
            }
        }
    }
}

function Select-InstallRole {
    if ($Role) {
        return $Role
    }

    return Show-Menu -Options @(
        @{ Label = (Get-Message 'menu_role_server'); Value = 'Server' }
        @{ Label = (Get-Message 'menu_role_client'); Value = 'Client' }
        @{ Label = (Get-Message 'menu_role_server_and_client'); Value = 'ServerAndClient' }
    ) -Title (Get-Message 'menu_select_role')
}

# --- Package Manager ---

function Ensure-Chocolatey {
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host (Get-Message 'installing_chocolatey') -ForegroundColor Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    else {
        Write-Host (Get-Message 'chocolatey_installed') -ForegroundColor Green
    }
}

function Read-SunshineAddress {
    while ($true) {
        $serverAddress = Read-Host (Get-Message 'prompt_sunshine_address')
        if (![string]::IsNullOrWhiteSpace($serverAddress)) {
            return $serverAddress.Trim()
        }

        Write-Host (Get-Message 'server_address_required') -ForegroundColor Yellow
    }
}

function Get-InstallPlan {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Server', 'Client', 'ServerAndClient')]
        [string]$Role
    )

    switch ($Role) {
        'Server' {
            return @{
                Packages          = @('sunshine', 'tailscale')
                InstallMessageKey = 'installing_server_packages'
                OpenLocalSunshine = $true
                NeedsServerAddress = $false
                LaunchMoonlight   = $false
            }
        }
        'Client' {
            return @{
                Packages          = @('moonlight-qt.install', 'tailscale')
                InstallMessageKey = 'installing_client_packages'
                OpenLocalSunshine = $false
                NeedsServerAddress = $true
                LaunchMoonlight   = $true
            }
        }
        'ServerAndClient' {
            return @{
                Packages          = @('sunshine', 'moonlight-qt.install', 'tailscale')
                InstallMessageKey = 'installing_server_client_packages'
                OpenLocalSunshine = $true
                NeedsServerAddress = $false
                LaunchMoonlight   = $true
            }
        }
    }
}

function Invoke-ChocolateyPackages {
    param(
        [Parameter(Mandatory)]
        [string[]]$Packages,
        [Parameter(Mandatory)]
        [ValidateSet('Install', 'Uninstall')]
        [string]$Action,
        [Parameter(Mandatory)]
        [string]$MessageKey
    )

    Write-Host (Get-Message $MessageKey) -ForegroundColor Cyan

    if ($Action -eq 'Install') {
        $jobs = foreach ($package in $Packages) {
            Start-Job -ScriptBlock {
                param($PackageName)
                choco install $PackageName -y
            } -ArgumentList $package
        }

        try {
            Wait-Job $jobs | Out-Null
            Receive-Job $jobs
        }
        finally {
            $jobs | Remove-Job -Force -ErrorAction SilentlyContinue
        }

        return
    }

    foreach ($package in $Packages) {
        choco uninstall $package -y
    }
}

function Open-LocalSunshineUi {
    Write-Host (Get-Message 'opening_local_sunshine_ui') -ForegroundColor Cyan
    Start-Process 'https://localhost:47990'
}

function Open-RemoteSunshineUi {
    param(
        [Parameter(Mandatory)]
        [string]$ServerAddress
    )

    Write-Host (Get-Message 'opening_remote_sunshine_ui') -ForegroundColor Cyan
    Start-Process "https://${ServerAddress}:47990/pin"
}

function Start-Moonlight {
    $moonlightPath = "${env:ProgramFiles}\Moonlight Game Streaming\Moonlight.exe"
    if (Test-Path $moonlightPath) {
        Start-Process $moonlightPath
    }
}

# --- Install ---

function Start-Install {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Server', 'Client', 'ServerAndClient')]
        [string]$Role,
        [string]$Url
    )

    $plan = Get-InstallPlan -Role $Role

    Ensure-Chocolatey
    Invoke-ChocolateyPackages -Packages $plan.Packages -Action Install -MessageKey $plan.InstallMessageKey

    Write-Host (Get-Message 'install_completed') -ForegroundColor Green
    Read-Host (Get-Message 'press_enter_continue')

    if ($plan.OpenLocalSunshine) {
        Open-LocalSunshineUi
    }

    if ($plan.NeedsServerAddress) {
        $serverAddress = $Url
        if ([string]::IsNullOrWhiteSpace($serverAddress)) {
            $serverAddress = Read-SunshineAddress
        }

        Open-RemoteSunshineUi -ServerAddress $serverAddress
    }

    if ($plan.LaunchMoonlight) {
        Read-Host (Get-Message 'press_enter_launch_moonlight')
        Start-Moonlight
    }

    Write-Host (Get-Message 'setup_completed') -ForegroundColor Green
    Read-Host (Get-Message 'press_enter_exit')
}

# --- Uninstall ---

function Start-Uninstall {

    Ensure-Chocolatey
    Invoke-ChocolateyPackages -Packages @('sunshine', 'moonlight-qt.install', 'tailscale') -Action Uninstall -MessageKey 'uninstalling_all_packages'

    Write-Host (Get-Message 'uninstall_completed') -ForegroundColor Green
    Read-Host (Get-Message 'press_enter_exit')
}

# --- Main ---

Initialize-Locale

if ($Install -and $Uninstall) {
    throw (Get-Message 'error_install_and_uninstall')
}

if ($Url -and -not $Install) {
    throw (Get-Message 'error_url_without_install')
}

if ($Role -and -not $Install) {
    throw (Get-Message 'error_role_without_install')
}

if (-not $Install -and -not $Uninstall) {
    $selection = Show-Menu -Options @(
        @{ Label = (Get-Message 'menu_install'); Value = 'Install' }
        @{ Label = (Get-Message 'menu_uninstall'); Value = 'Uninstall' }
    ) -Title (Get-Message 'menu_select_action')
    switch ($selection) {
        'Install' { $Install = $true }
        'Uninstall' { $Uninstall = $true }
    }
}

if ($Install) {
    Start-Install -Role (Select-InstallRole) -Url $Url
}
elseif ($Uninstall) {
    Start-Uninstall
}
