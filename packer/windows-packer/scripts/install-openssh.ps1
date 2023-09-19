# Installs OpenSSH Server on a new windows system

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

function Configure-OpenSSH {
    param(
        [string] $ConfigFilePath = "C:\Program Files\OpenSSH-Win64\sshd_config_default"
    )

    # Check if the specified file exists
    if (-not (Test-Path -Path $ConfigFilePath -PathType Leaf)) {
        Write-Host "Error: $ConfigFilePath does not exist."
        return
    }

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
    Write-Host "OpenSSH configuration updated."
}

function Set-OpenSSHServiceAutoStart {
    Set-Service -Name sshd -StartupType Automatic
    Write-Host "OpenSSH service set to start automatically."
}

function Start-SSHService {
    param (
        [string]$serviceName = 'sshd'
    )

    # Check if the SSH service is already running
    $service = Get-Service -Name $serviceName
    if ($service.Status -eq 'Running') {
        Write-Host "$serviceName is already running."
    }
    else {
        # Start the SSH service
        Start-Service -Name $serviceName
        Write-Host "Starting $serviceName..."
    }
}


function Open-FirewallPort {
    param (
        [string] $Port,
        [string] $Protocol
    )
    Write-Host "Opening Windows Firewall Port: $Port $Protocol"
    New-NetFirewallRule -DisplayName "Open Port $PortNumber - $Protocol" -Direction Inbound -LocalPort $PortNumber -Protocol $Protocol -Action Allow
}

try {
    Install-Choco

    choco install -y openssh

    #Run install script
    Set-ExecutionPolicy Bypass
    & "C:\Program Files\OpenSSH-Win64\install-sshd.ps1"

    #Configure the conf file
    Configure-OpenSSH

    #Set the service to start automatically
    Set-OpenSSHServiceAutoStart

    # Start the service
    Start-SSHService

    # Add firewall rules for SSH
    Open-FirewallPort -Port 22 -Protocol UDP
    Open-FirewallPort -Port 22 -Protocol TCP

}
catch {
    Write-Host "Error in script: "
    Write-Host $_
}
