# Diff two directories and compare SHA256 checksums

# Diff-Directories.ps1 -Dir1 C:/path1 -Dir2 C:/path2

# Command Line Args
param (
    [string] $Dir1,
    [string] $Dir2
)

# Get the hashes of all files in a directory - return as dict
function Get-DirectoryHashes {
    param (
        [string] $DirectoryPath
    )
    $fileHashes = @{}
    $files = Get-ChildItem -Path $DirectoryPath -File -Recurse

    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($DirectoryPath.Length).TrimStart('\')
        $fileHashes[$relativePath] = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
        
        # Debug
        # Write-Host "$relativePath = $($fileHashes.$relativePath))"
    }
    return $fileHashes
}

# Function to compare hashes from two directories
function Compare-DirectoryHashes {
    param (
        [hashtable] $HashDict1,
        [hashtable] $HashDict2
    )
    $differences = @()

    foreach ($key in $HashDict1.Keys) {
        if ($HashDict2.ContainsKey($key)) {
            if ($HashDict1[$key] -ne $HashDict2[$key]) {
                # File Hashes Don't Match
                $differences += $key
            }
            # Debug
            # else {
            #     # File hashes match
            #     # Write-Host "File is the same: $($HashDict1[$key]) = $($HashDict2[$key])"
            # }
        } else {
            # Add any Dict1 files that aren't in Dict2
            $differences += $key
        }
    }

    # Add any Dict2 files that aren't in Dict1
    foreach ($key in $HashDict2.Keys) {
        if (-not $HashDict1.ContainsKey($key)) {
            $differences += $key
        }
    }

    return $differences
}

# Function to convert relative path to absolute path
function Convert-ToAbsolutePath {
    param (
        [string] $Path
    )
    
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }
    
    Write-Host "Path: $Path is relative, converting to absolute path..."

    return [System.IO.Path]::GetFullPath($Path)
}

# Main script execution

$Dir1 = Convert-ToAbsolutePath -Path $Dir1
$Dir2 = Convert-ToAbsolutePath -Path $Dir2


Write-Host "Hashing: $Dir1"
$hashesDir1 = Get-DirectoryHashes -DirectoryPath $Dir1

Write-Host "Hashing: $Dir2"
$hashesDir2 = Get-DirectoryHashes -DirectoryPath $Dir2

$differences = Compare-DirectoryHashes -HashDict1 $hashesDir1 -HashDict2 $hashesDir2

Write-Host "Files that are different:"
foreach ($file in $differences) {
    Write-Host $file
}
