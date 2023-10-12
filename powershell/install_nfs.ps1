#
# Only Avaliable in Windows  10 Pro
#

function mountNFS {
    param (
        [string] $DrivePath,
        [string] $SharePath,
        [string] $Username
    )

    cmd.exe mount -o nolock -o casesensitive=yes -u:$Username $SharePath $DrivePath 

}

try {
    
    Write-Host "Installing NFS Feature..."

    Enable-WindowsOptionalFeature -FeatureName ServicesForNFS-ClientOnly, ClientForNFS-Infrastructure -Online -NoRestart

    Write-Host "Displaying Mount Status..."

    cmd.exe mount

    Write-Host "Attempting to mount"

    mountNFS -SharePath "\\storage.light.fire\mnt\NVMePool\ShareName" -DrivePath "S:" -Username "nfsuser"

}
catch {
    Write-Host "There was an error during installation:"
    Write-Host $_
}