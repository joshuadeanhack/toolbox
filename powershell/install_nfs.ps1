#
# Only Avaliable in Windows  10 Pro
#

function mountNFS {
    param (
        [string] $DrivePath,
        [string] $SharePath,
        [string] $Username
    )

    cmd.exe mount -o nolock -o casesensitive=yes $SharePath $DrivePath   #-u:$Username 

}

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


try {
    
    Write-Host "Installing NFS Feature..."

    Enable-WindowsOptionalFeature -FeatureName ServicesForNFS-ClientOnly, ClientForNFS-Infrastructure -Online -NoRestart

    Write-Host "Setting registy keys for UID and GID for anonymous user as the root UID [0]."
    
    Set-RegistryValue -KeyPath "HKLM:\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default" -ValueName "AnonymousUid" -ValueData "0" -ValueKind "DWORD"
    Set-RegistryValue -KeyPath "HKLM:\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default" -ValueName "AnonymousGid" -ValueData "0" -ValueKind "DWORD"

    Write-Host "Displaying Mount Status..."

    cmd.exe mount

    Write-Host ""
    Write-Host "Attempting to mount"
    Write-Host ""

    mountNFS -SharePath "\\storage.light.fire\mnt\NVMePool\ShareName" -DrivePath "S:"
    
    Write-Host ""
    Write-Host "Displaying Mount Status..."
    Write-Host ""
    cmd.exe mount

    # Again for another share with a different user

    # Write-Host "Setting UID and GID for NFS User: otheruser"
    # Set-RegistryValue -KeyPath "HKLM:\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default" -ValueName "otherUserUid" -ValueData 1001 -ValueKind "DWORD"
    # Set-RegistryValue -KeyPath "HKLM:\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default" -ValueName "otherUserGid" -ValueData 1001 -ValueKind "DWORD"
    # mountNFS -SharePath "\\storage.light.fire\mnt\NVMePool\ShareName2" -DrivePath "H:" -Username "otheruser" 

}
catch {
    Write-Host "There was an error during installation:"
    Write-Host $_
}