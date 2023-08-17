# This script is run by all windows packer provisioners, elevated to Administrator
# It sets a default password for the machine and sets up basic windows configuration
#
# Dependancies:
#    $env:SetAdminPassword environment variable needs to be set
#

# Fumction to test an environment variable exists at runtime
function Test-EnvironmentVariable($varName){
    $envVar = [System.Environment]::GetEnvironmentVariable($varName)
    if ([string]::IsNullOrEmpty($envVar)){
        Write-Output "Couldn't find environment variable '$varName' // env.$varName "
        Exit 1
    }
}

# Function to remove password complexity requirements of users
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
    Write-Host "Setting Password for: $Username"
    net user $Username $Password

    # Set the password to never expire
    Write-Host "Setting password to never expire"
    wmic useraccount where "name='$Username'" set PasswordExpires=FALSE
}

# Function to open an inbound port on windows firewall
function Open-FirewallPort {
    param (
        [string] $Port,
        [string] $Protocol
    )
    Write-Host "Opening Windows Firewall Port: $Port $Protocol"
    New-NetFirewallRule -DisplayName "Open Port $PortNumber - $Protocol" -Direction Inbound -LocalPort $PortNumber -Protocol $Protocol -Action Allow
}

function Set-TimeZone {
    # Get the time zone corresponding to GMT (Greenwich Mean Time)
    $targetTimeZone = Get-TimeZone -Id "GMT Standard Time"

    # Set the time zone to the desired time zone (GMT/London)
    Set-TimeZone -Id $targetTimeZone.Id

    # Synchronize the time with the time server
    Start-Process -FilePath "w32tm.exe" -ArgumentList "/resync" -NoNewWindow -Wait
}

# Function to modify registry values
function Set-RegistryValue {
    param (
        [string]$KeyPath,
        [string]$ValueName,
        [string]$ValueData,
        [string]$ValueKind
    )
    $key = Get-Item -LiteralPath $KeyPath -ErrorAction SilentlyContinue
    if ($null -eq $key) {
        $key = New-Item -Path $KeyPath -Force
    }
    Set-ItemProperty -Path $KeyPath -Name $ValueName -Value $ValueData -Type $ValueKind
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

function Install-Choco {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

try {
    # Make sure the admin password is set
    Test-EnvironmentVariable "SetAdminPassword"

    Write-Host "Removing password complexity policy"
    Remove-PasswordComplexityPolicy

    # Set Adminstrator Default Password
    Write-Host "Setting admin password"
    Set-UserPassword -Username Administrator -Password $env:SetAdminPassword

    # Open Management Ports - RDP
    Open-FirewallPort -Port 3389 -Protocol TCP
    Open-FirewallPort -Port 3389 -Protocol UDP 

    # Set Time to London
    Set-TimeZone

    # Set Windows Explorer to Show hidden files
    Set-RegistryValue -KeyPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ValueName "Hidden" -ValueData "1" -ValueKind "DWORD"

    # Set Windows Explorer to show known file types
    Set-RegistryValue -KeyPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ValueName "HideFileExt" -ValueData "0" -ValueKind "DWORD"

    Disable-UAC

    Disable-Telemetry

    Install-Choco

    choco install qbittorrent

}
catch {
    Write-Host "Provisioning Error: "
    Write-Host $_
}


