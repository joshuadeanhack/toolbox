# Function to create registry keys and set DWORD values
function Set-TLSRegistry {
    param (
        [string]$protocol
    )
    
    $basePath = "HKLM:\System\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$protocol"
    
    # Create Protocol Key
    if (-not (Test-Path $basePath)) { New-Item -Path $basePath -Force }

    # Create Server and Client Keys
    foreach ($subKey in @('Server', 'Client')) {
        $subKeyPath = "$basePath\$subKey"
        if (-not (Test-Path $subKeyPath)) { New-Item -Path $subKeyPath -Force }
        
        # Add DWORD values DisabledByDefault and Enabled
	Write-Host "Setting Keys in: $subKeyPath" 
        Set-ItemProperty -Path $subKeyPath -Name "DisabledByDefault" -Value 1 -Type DWord
        Set-ItemProperty -Path $subKeyPath -Name "Enabled" -Value 0 -Type DWord
    }
}

# Apply to TLS 1.0 and TLS 1.1
Set-TLSRegistry -protocol "TLS 1.0"
Set-TLSRegistry -protocol "TLS 1.1"