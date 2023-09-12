
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

try {
    # Make sure the admin password is set
    Test-EnvironmentVariable "SetAdminPassword"

    Write-Host "Removing password complexity policy"
    Remove-PasswordComplexityPolicy

    # Set Adminstrator Default Password
    Write-Host "Setting admin password"
    Set-UserPassword -Username Administrator -Password $env:SetAdminPassword

}
catch {
    Write-Host "Provisioning Error Setting Windows Password: "
    Write-Host $_
}