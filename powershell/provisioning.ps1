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
    Write-Output "Added windows firewall exclusion for $Path"
}

function Open-FirewallPort {
    param (
        [int] $Port,
        [string] $Protocol
    )
    New-NetFirewallRule -DisplayName "Open Port $PortNumber - $Protocol" -Direction Inbound -LocalPort $PortNumber -Protocol $Protocol -Action Allow
}

Remove-PasswordComplexityPolicy
Set-UserPassword "Administrator" "Default-Password"
Set-WindowsFirewallExclusion -Path "C:\MyPrograms"
Open-FirewallPort -Port 3389 -Protocol UDP