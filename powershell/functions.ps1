function Test-Path {
    param (
        [string] $Path
    )
    if (Test-Path $Path) {
        return $true
    } else {
        Write-Output "Path '$Path' does not exist."
        return $false
    }
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

function Compress-Folder {
    param (
        [Parameter(Mandatory=$true)]
        [string] $Path,
        
        [Parameter(Mandatory=$false)]
        [string] $DestinationPath
    )

    if ([string]::IsNullOrEmpty($DestinationPath)) {
        $DestinationPath = Join-Path (Split-Path -Path $Path -Parent) (Split-Path -Path $Path -Leaf + ".zip")
    }
    
    # Compress the folder
    Compress-Archive -Path $Path -DestinationPath $DestinationPath -Force

    Write-Output "Folder '$Path' has been compressed to '$DestinationPath'."
 
}

function Compress-FolderExcludeXVC($sourceDir, $destDir, $newName){
    # Compress-Archive -Path $sourceDir -DestinationPath "$destDir\$newName.zip" -CompressionLevel Optimal -Exclude *.xvc
    Get-ChildItem -Path $sourceDir -Exclude "*.xvc" | Compress-Archive -DestinationPath $destDir\$newName.zip -CompressionLevel Optimal -Update
    Write-Host "Compressing: $sourceDir"
    Write-Host "Destination: $destDir\$newName.zip"
}


# Test-Path -Path "C:\"
# Ensure-PathExists -Path "C:\"
# Compress-MyFolder -Path "C:\SomePath\SomeFolder" OR Compress-MyFolder -Path "C:\SomePath\SomeFolder" -DestinationPath "C:\SomePath\CompressedFolder.zip"
# 