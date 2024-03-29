
function Install-ServerRoles {
    Write-Host "Installing DNS Feature..."
    Install-WindowsFeature -Name DNS -IncludeManagementTools
    Write-Host "Installing DHCP Feature..."
    Install-WindowsFeature -Name DHCP -IncludeManagementTools
}

function Add-DNSZone {
    param (
        [string] $ZoneName
    )
    Add-DnsServerPrimaryZone -Name $ZoneName -ZoneFile "$ZoneName.dns" -DynamicUpdate NonsecureAndSecure
}

function Add-DNSRecord {
    param (
        [string] $Hostname,
        [string] $ZoneName,
        [string] $IPAddress
    )
    Write-Host "Adding Record: $IPAddress as $Hostname.$ZoneName"
    Add-DnsServerResourceRecordA -Name $Hostname -ZoneName $ZoneName -IPv4Address $IPAddress
}

function Add-CName {
    param (
        [string] $Hostname,
        [string] $ZoneName,
        [string] $FQDNRecord
    )
    Write-Host "Adding CNAME: $Hostname.$ZoneName forwards to $FQDNRecord"
    Add-DnsServerResourceRecordCName -Name $Hostname -ZoneName $ZoneName -HostNameAlias $FQDNRecord 
}

function Get-DNSRecords {
    param (
        [string] $ZoneName
    )
    Get-DnsServerResourceRecord -ZoneName $ZoneName
}

function Add-DHCPScope {
    param (
        [string] $ScopeName,
        [ipaddress] $StartIP, 
        [ipaddress] $EndIP,
        [ipaddress] $SubnetMask,
        [timespan] $Duration
    )
    Write-Host "Adding DHCP Scope: $ScopeName from $StartIP to $EndIP"
    Add-DhcpServerv4Scope -Name $ScopeName -StartRange $StartIP -EndRange $EndIP -SubnetMask $SubnetMask -LeaseDuration $Duration
    # Set-DhcpServerv4DnsSetting -ScopeId 10.10.10.0 -DynamicUpdates "Always" -NameProtection $True -DeleteDnsRRonLeaseExpiry $True
}

function Set-DHCPOption {
    param (
        [ipaddress] $ScopeIP,
        [ipaddress] $DNSServer,
        [ipaddress] $RouterIP,
        [string] $DomainToAddRecord
    )
    Write-Host "Setting DHCP Options: Router=$ScopeIP DNS Server=$DNSServer Domain=$DomainToAddRecord"
    Set-DhcpServerv4OptionValue -ScopeId $ScopeIP -DnsServer $DNSServer -DnsDomain $DomainToAddRecord -Router $RouterIP -Force # Use -Force to skip validation
}

function Get-ScopeOptions {
    param (
        [ipaddress] $ScopeIP #Scope IP will end in .0 not .1
    )
    Get-DhcpServerv4OptionValue -ScopeId $ScopeIP
}

function Get-MachineIP {
    $IPObject = Get-NetIPAddress -AddressFamily IPv4 -PrefixLength 24 | Select-Object IPAddress
    $env:MachineIP = $IPObject.IPAddress
}




Install-ServerRoles

# DNS Server - https://learn.microsoft.com/en-us/powershell/module/dnsserver/?view=windowsserver2022-ps
Add-DNSZone -ZoneName "lightfire.studio"
Add-DNSZone -ZoneName "light.fire"

# Add A Record - test.light.fire 10.10.10.10
Add-DNSRecord -Hostname "test" -ZoneName "light.fire" -IPAddress 10.10.10.10

# Add CNAME - lol.light.fire -> staticpage.lightfire.studio
Add-CName -Hostname "lol" -ZoneName "light.fire" -FQDNRecord "staticpage.lightfire.studio"

# Print Records
Get-DNSRecords -ZoneName "light.fire"


# DHCP Server - https://learn.microsoft.com/en-us/powershell/module/dhcpserver/?view=windowsserver2022-ps
Add-DHCPScope -ScopeName "Servers" -StartIP 10.42.50.1 -EndIP 10.42.50.254 -SubnetMask 255.255.255.0 -Duration 2.00:00:00  # Duration is days.hours:minutes.seconds defined here:  https://learn.microsoft.com/en-us/powershell/module/dhcpserver/add-dhcpserverv4scope?view=windowsserver2022-ps#-leaseduration

#Inject Server IP (the machine's destined static IP)
if ([string]::IsNullOrEmpty($env:DNSServerIP)){
    $MachineIP = Get-MachineIP
}
else {
    $MachineIP = [ipaddress]$env:DNSServerIP.Trim()
}

#Set Options
Set-DHCPOption -ScopeIP 10.42.50.0 -DNSServer $MachineIP -RouterIP 10.42.0.1 -DomainToAddRecord "light.fire" 

# Print DHCP Options
Get-ScopeOptions -ScopeIP 10.42.50.0 # Must end in .0 of the subnet