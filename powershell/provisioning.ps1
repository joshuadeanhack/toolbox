function Remove-PasswordComplexityPolicy {
    # Export current security policy
    secedit /export /cfg c:\secpol.cfg

    # Replace the value in the file
    (Get-Content C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg

    # Import new security policy file
    secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY

    # Cleanup Secpol cfg file
    Remove-Item -force c:\secpol.cfg -confirm:$false
}

function Set-UserPassword {
	param (
        [string]$Username,
        [string]$Password
    )
    # Set Adminstrator Default Password
    net user $Username $Password

    # Set the password to never expire
    wmic useraccount where "name='$Username'" set PasswordExpires=FALSE
}

function Set-WindowsFirewallExclusion {
    param (
        [string] $Path
    )
    Add-MpPreference -ExclusionPath $Path
    Write-Host "Added windows firewall exclusion for $Path"
}

function Open-FirewallPort {
    param (
        [int] $Port,
        [string] $Protocol
    )
    Write-Host "Opening Windows Firewall Port: $Port $Protocol"
    New-NetFirewallRule -DisplayName "Open Port $PortNumber - $Protocol" -Direction Inbound -LocalPort $PortNumber -Protocol $Protocol -Action Allow
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


function Install-WSL2 {
    # Install WSL2
    wsl --install

    # Set default version 2
    wsl --set-default-version 2
}

function Install-UbuntuWSL {
    param (
        [string] $DistroName,
        [string] $DownloadURL
    )

    # Download linux distro appx package
    Write-Host "Downloading Ubuntu WSL package"
    Download-File -url $DownloadURL -output "C:\Ubuntu.appx"

    # Install Ubuntu from the downloaded package
    Add-AppxPackage C:\Ubuntu.appx

    # Set default linux install - ubuntu
    $distributionExists = wsl --list | Select-String -Pattern "$DistroName"

    if ($distributionExists) {
        # Set the specified distribution as the default
        wslconfig /setdefault $DistroName
        Write-Host "Default WSL distribution set to '$DistroName'."
    } else {
        Write-Host "Error: WSL distribution '$DistroName' not found."
    }

}

function Install-Choco {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
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

function Download-File {
    param (
        [string]$url,
        [string]$output
    )

    # Download the file
    Write-Output "Downloading from: $url "
    Write-Output "Storing to: $output"

    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($url, $output)
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

Remove-PasswordComplexityPolicy
Set-UserPassword "Administrator" "Default-Password"
Set-WindowsFirewallExclusion -Path "C:\MyPrograms"
Open-FirewallPort -Port 3389 -Protocol UDP
Disable-UAC
Disable-Telemetry
Install-WSL2
Install-UbuntuWSL -DistroName "Ubuntu" -DownloadURL "https://aka.ms/wslubuntu2204"
Install-Choco
DownloadAndInstall "https://cdn.unrealengine.com/CrossToolchain_Linux/v21_clang-15.0.1-centos7.exe" "C:\temp\v21_clang-15.0.1-centos7.exe"