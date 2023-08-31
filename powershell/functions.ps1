
# Files and Compression
# =====================

function TestPathExists {
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

function Move-RenameFiles($sourceDir, $filePattern, $destDir, $newName, $ext){
    $files = Get-ChildItem -Path $sourceDir -Filter $filePattern
    foreach($file in $files){
        $destinationFile = Join-Path -Path $destDir -ChildPath "$newName.$ext"
        Move-Item -Path $file.FullName -Destination $destinationFile
        Write-Host "Moving file: $($file.FullName) to $($destinationFile)"
    }
}

function Test-EnvironmentVariable($varName){
    $envVar = [System.Environment]::GetEnvironmentVariable($varName)
    if ([string]::IsNullOrEmpty($envVar)){
        Write-Output "Couldn't find environment variable '$varName' // env.$varName "
        Exit 1
    }
}

# Create a .backup of a given file
function PreserveFile {
    param (
        [string] $FilePath
    )

    Write-Host "Attempting to backup file as: $backupFileName"

    $backupFileName = "$FilePath.backup"
    Copy-Item -Path $FilePath -Destination $backupFileName -Force
}

# Restore a .backup file
function RestoreFile {
    param (
        [string] $BackupFilePath
    )

    if (-not $BackupFilePath.EndsWith(".backup")) {
        Write-Error "Provided file is not a backup. Ensure it has a .backup extension."
        return
    }

    $originalFileName = $BackupFilePath.TrimEnd('.backup')

    # Override the current config.vdf
    Write-Host "Attempting to restore file..."
    Write-Host "Copying $BackupFilePath to: $originalFileName"

    Copy-Item -Path $BackupFilePath -Destination $originalFileName -Force
}

# Look for entries in a JSON file
function LookForJSON {
    param (
        [string] $FilePath,
        [string] $Block1,
        [string] $Block2
    )

    # Read the file and parse the JSON
    $json = Get-Content -Path $JsonFilePath | ConvertFrom-Json -AsHashTable

    # Example of nested levels:
    # Check for the "Authentication" block and "RememberedMachineID" block
    # if ($json.InstallConfigStore.Authentication -and $json.InstallConfigStore.Authentication.RememberedMachineID)
    
    if ($json.$($Block1)-and $json.$($Block2)) {
        Write-Output "Both '$Block1' and '$Block2' blocks exist in the JSON file: $FilePath"
        return $true
    }
    else {
        Write-Output "The required blocks do not exist in the JSON file: $FilePath"
        return $false
    }

}


# ====
# AWS
# ====

function Get-AWSDebugInfo(){
    Write-Output "Debug Info..."
    Write-Output "Windows User: $(whoami)"
    
    $AWSUser = aws sts get-caller-identity
    Write-Output "AWS User: $AWSUser"
}

function Upload-FileToS3($FilePath, $BucketName, $S3KeyName) {
    Write-Host "Attempting to upload: $path to S3"
    
    # Create the AWS CLI command
    aws s3 cp $FilePath s3://$BucketName/$S3KeyName

}

function Copy-S3BucketItem {
    param (
        [string]$SourceFile,
        [string]$DestinationFile
    )
    Show-FileSize $SourceFile
    Write-Host "Coping to $DestinationFile"
    aws s3 cp $SourceFile $DestinationFile --no-progress
}

function Sync-FromS3() {
    param (
        [string] $S3Folder,
        [string] $DestinationFolder,
        [string] $FileName
    )

    Write-Host "Copying $S3Location to $DestinationPath"
    aws s3 sync $S3Folder $DestinationFolder --exclude "*" --include $FileName

}

# ---------------
# Commands in use
# ---------------

# Filesystem

# TestPathExists -Path "C:\"
# Ensure-PathExists -Path "C:\"
# Compress-Folder -Path "C:\SomePath\SomeFolder" OR Compress-MyFolder -Path "C:\SomePath\SomeFolder" -DestinationPath "C:\SomePath\CompressedFolder.zip"
# Move-RenameFiles $sourceDir "*filename*.jpg" $destDir $newName "jpg"
# Test-EnvironmentVariable "VariableName"
# PreserveFile -FilePath "C:\myfile.config"
# RestoreFile -BackupFilePath "C:\myfile.config.backup"
# LookForJSON -FilePath "C:\myfile.json" -Block1 "Configuration" -Block2 "SomeOtherTopLevelBLockName"  <-- modify this function based on what you want to find

# AWS

# Get-AWSDebugInfo
# Upload-FileToS3 -FilePath C:\AWS\file.zip -BucketName my-bucket -S3KeyName Music/file.zip
# Copy-S3BucketItem -SourceFile $FilePath -DestinationFile $S3DestinationPath <- (in format s3://bucket/file)
# Sync-FromS3 -FileName "*.iso" -S3Folder "s3:/bucket/images"  -DestinationFolder "C:\"