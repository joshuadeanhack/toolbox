# Function to disable a specific cipher
function Disable-Cipher {
    param (
        [string] $cipher
    )

    $cipherPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\$cipher"

    # Check if the cipher key exists, create it if not
    if (-not (Test-Path $cipherPath)) { New-Item -Path $cipherPath -Force }

    # Set DWORD value 'Enabled' to 0
    Write-Host "Setting Registry Key: $cipherPath"
    Set-ItemProperty -Path $cipherPath -Name "Enabled" -Value 0 -Type DWord
}

# Disable Triple DES 168
Disable-Cipher -cipher "Triple DES 168"
