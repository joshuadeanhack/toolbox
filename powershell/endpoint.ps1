#
# Generic Upgrade Keys:
# Windows 10/11 Home - YTMG3-N6DKC-DKB77-7M9GH-8HVX7
# Windows 10/11 Pro -  VK7JG-NPHTM-C97JM-9MPGT-3V66T 
# Windows 10/11 Enterprise - XGVPP-NMH47-7TTHJ-W3FW7-8HV2C
# Windows 10/11 Education - YNMGQ-8RYV3-4PGQ3-C8XTP-7CFBY	
#
# Generic Product Keys:
# Win 10 Pro:
# 1. NF6HC-QH89W-F8WYV-WWXV4-WFG6P
# 2. RHGJR-N7FVY-Q3B8F-KBQ6V-46YP4

# ----------------------------------------------------
# Set these options to what you want to have installed
# ----------------------------------------------------


$INSTALL_CREATIVE_TOOLS = $true
$INSTALL_WSL = $false
$INSTALL_DEV_TOOLS = $false


function Install-Choco {
    try{ 
        choco --version
    }
    catch {
        Write-Host "Choco Not Found, Installing...."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
}

function Disable-UAC {
    New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force
    Write-Host "UAC Disabled"
}

function Disable-Telemetry {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowDeviceNameInTelemetry" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
    
    Get-Service -Name "DiagTrack" | Stop-Service -NoWait -Force
    Get-Service -Name "DiagTrack" | set-service -StartupType Disabled
}

function Set-RegistryValue {
    param (
        [string]$KeyPath,
        [string]$ValueName,
        [string]$ValueData,
        [string]$ValueKind
    )
    $key = Get-Item -LiteralPath $KeyPath -ErrorAction SilentlyContinue
    if ($key -eq $null) {
        $key = New-Item -Path $KeyPath -Force
    }
    Set-ItemProperty -Path $KeyPath -Name $ValueName -Value $ValueData -Type $ValueKind
}

function Install-WSL2 {
    # Install WSL2
    wsl --install -d Ubuntu-22.04

    # Set default version 2
    wsl --set-default-version 2
}

function Ensure-PathExists {
    param (
        [string] $Path
    )

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force
        Write-Output "Path '$Path' created."
    }
}

function EnsureDirectoryExists {
    param (
        [string]$filePath
    )

    $directoryPath = Split-Path $filePath -Parent

    if (-not (Test-Path $directoryPath)) {
        # Recursivly create the directory
        Write-Output "Creating Directory: $directoryPath"
        New-Item -ItemType Directory -Force -Path $directoryPath
    }
}

function DownloadAndInstall {
    param (
        [string]$url,
        [string]$output
    )

    # Ensure the output directory exists
    EnsureDirectoryExists -filePath $output

    # Download the file
    Write-Output "Downloading from: $url "
    Write-Output "Storing to: $output"

    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($url, $output)

    # Run the downloaded .exe file
    Write-Output "Running Installer - Manual Install - Please Configure"
    Start-Process -FilePath $output -Wait -Passthru
}


# ====
# Main
# ====

try {

    Disable-UAC
    Disable-Telemetry

    # Set Windows Explorer to Show hidden files
    Set-RegistryValue -KeyPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ValueName "Hidden" -ValueData "1" -ValueKind "DWORD"
    # Set Windows Explorer to show known file types
    Set-RegistryValue -KeyPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ValueName "HideFileExt" -ValueData "0" -ValueKind "DWORD"

    if ($INSTALL_WSL) {
        Install-WSL2
    }

}
catch {
    Write-Host "Error Configuring Windows: "
    Write-Host $_
}

try {
    Write-Host "Installing Web Browsers"
    Install-Choco
    choco feature enable -n allowGlobalConfirmation
    choco install brave
    choco install googlechrome
    choco install bitwarden
}
catch {
    Write-Host "Error Installing Web Browsers: "
    Write-Host $_
}

try {
    Write-Host "Installing Tools"
    $env:ChocoToolsLocation = "C:\tools"
    choco install rdm
    choco install awscli
    choco install yt-dlp 

    # Get-iplayer
    Ensure-PathExists -Path "C:\tools\get-iplayer"
    DownloadAndInstall -url https://github.com/get-iplayer/get_iplayer_win32/releases/download/3.34.0/get_iplayer-3.34.0-windows-x64-setup.exe -output "C:/tools/get-iplayer/get_iplayer-3.34.0-windows-x64-setup.exe"
    
}
catch {
    Write-Host "Error Installing Tools: "
    Write-Host $_
}

try {
    if ($INSTALL_CREATIVE_TOOLS) {
        Write-Host "Installing Creative Tools:"
        choco install blender
        choco install krita
        choco install vlc

        # Add: Behringer UMC Drivers Packge from GoogleDrive:Software/
        # Add: Reaper and Audio Plugins
    }
    
}
catch {
    Write-Host "Error Installing Creative: "
    Write-Host $_
}

try {
    if ($INSTALL_DEV_TOOLS) {
        Write-Host "Installing Dev Tools:"
        choco install cmder
        choco install docker-desktop
        choco install dive
        choco install vscode
        choco install github-desktop
        choco install notepadplusplus
        choco install iperf3
        choco install ventoy
    }
}
catch {
    Write-Host "Error Installing Dev Tools: "
    Write-Host $_
}


Write-Host "Ensuring Stability..."

sfc /scannow
dism /Online /Cleanup-Image /RestoreHealth

# Run $>chkdsk C: /r
# if needed
