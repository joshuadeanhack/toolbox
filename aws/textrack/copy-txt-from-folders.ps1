# Set the base folder to search through
$baseFolder = $(Get-Location).Path

# Create a new directory under the current working directory called 'ExtractedText'
$outputFolder = Join-Path -Path (Get-Location) -ChildPath "ExtractedText"

if (-not (Test-Path -Path $outputFolder)) {
    New-Item -Path $outputFolder -ItemType Directory | Out-Null
}

# Recursively get all rawtext.txt files in subdirectories
$files = Get-ChildItem -Path $baseFolder -Recurse -Filter "rawText.txt"

# Loop through each found rawtext.txt file
foreach ($file in $files) {

    # Get the directory name where rawtext.txt is located
    $directoryName = Split-Path -Path $file.DirectoryName -Leaf
    
    # Define the new file name and path in the ExtractedText directory
    $newFileName = "$directoryName.txt"
    $newFilePath = Join-Path -Path $outputFolder -ChildPath $newFileName
    
    # Copy and rename the rawtext.txt file to the ExtractedText directory
    Copy-Item -Path $file.FullName -Destination $newFilePath -Force

    Write-Host "Found in $($file.DirectoryName) copied to $newFilePath"
}

Write-Host "Files have been renamed and moved to the ExtractedText folder."