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

