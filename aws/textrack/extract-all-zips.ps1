# Define the path to the folder containing the ZIP files
$sourceFolder = $(Get-Location).Path

# Get all .zip files in the specified folder
$zipFiles = Get-ChildItem -Path $sourceFolder -Filter *.zip


# Loop through each ZIP file and extract it
foreach ($zipFile in $zipFiles) {

    Write-Host ""
    Write-Host "Extracting: $zipFile to $destinationFolder"

    # Define the destination folder for the extracted files
    $destinationFolder = Join-Path -Path $zipFile.DirectoryName -ChildPath $zipFile.BaseName

    # Create the destination folder if it doesn't exist
    if (-not (Test-Path -Path $destinationFolder)) {
        New-Item -Path $destinationFolder -ItemType Directory | Out-Null
    }

    # Extract the ZIP file to the destination folder
    Expand-Archive -Path $zipFile.FullName -DestinationPath $destinationFolder -Force
}

Write-Host "Extraction complete."