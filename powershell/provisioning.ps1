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
    New-NetFirewallRule -DisplayName "Open Port $Port - $Protocol" -Direction Inbound -LocalPort $Port -Protocol $Protocol -Action Allow
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

function Set-LondonTimeZone {
    # Get the time zone corresponding to GMT (Greenwich Mean Time)
    $targetTimeZone = Get-TimeZone -Id "GMT Standard Time"

    # Set the time zone to the desired time zone (GMT/London)
    Set-TimeZone -Id $targetTimeZone.Id

    # Synchronize the time with the time server
    Start-Process -FilePath "w32tm.exe" -ArgumentList "/resync" -NoNewWindow -Wait
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

function Configure-OpenSSH {
    param(
        [string] $ConfigFilePath = "C:\Program Files\OpenSSH-Win64\sshd_config_default"
    )

    # Check if the specified file exists
    if (-not (Test-Path -Path $ConfigFilePath -PathType Leaf)) {
        Write-Host "Error: $ConfigFilePath does not exist."
        return
    }

    #Run install script
    Set-ExecutionPolicy Bypass
    & "C:\Program Files\OpenSSH-Win64\install-sshd.ps1"

    # Enable root login and password authentication
    $configLines = Get-Content -Path $ConfigFilePath
    $newConfig = @()
    foreach ($line in $configLines) {
        if ($line -match "^#?PermitRootLogin") {
            $newConfig += "PermitRootLogin yes"
        } elseif ($line -match "^#?PasswordAuthentication") {
            $newConfig += "PasswordAuthentication yes"
        } else {
            $newConfig += $line
        }
    }

    # Write updated configuration back to file
    $newConfig | Set-Content -Path $ConfigFilePath -encoding UTF8
    Write-Host "OpenSSH configuration file updated."
}

function Set-OpenSSHServiceAutoStart {
    Set-Service -Name sshd -StartupType Automatic
    Write-Host "OpenSSH service set to start automatically."
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
Set-LondonTimeZone
# Set Windows Explorer to Show hidden files
Set-RegistryValue -KeyPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ValueName "Hidden" -ValueData "1" -ValueKind "DWORD"
# Set Windows Explorer to show known file types
Set-RegistryValue -KeyPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ValueName "HideFileExt" -ValueData "0" -ValueKind "DWORD"

choco install -y openssh
Configure-OpenSSH
Set-OpenSSHServiceAutoStart