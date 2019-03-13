[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]$NetworkName,
    [Parameter(Mandatory = $true)]
    [String]$ResourceGroupName,
    [Parameter(Mandatory = $false)]
    [String]$SubnetName
)

# Usage: $FreeIPs = .\3_VerboseOutput_Get-FreeIpAddresses.ps1 -NetworkName GlobalAzureBootcamp2019-vnet -ResourceGroupName GlobalAzureBootcamp2019
# Usage: $FreeIPs = .\3_VerboseOutput_Get-FreeIpAddresses.ps1 -NetworkName GlobalAzureBootcamp2019-vnet -ResourceGroupName GlobalAzureBootcamp2019 -Verbose
# Usage: $FreeIPs = .\3_VerboseOutput_Get-FreeIpAddresses.ps1 -NetworkName GlobalAzureBootcamp2019-vnet -ResourceGroupName GlobalAzureBootcamp2019 -Verbose -Debug

#region Helper functions
function Get-SubnetAddress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Subnet
    )
    # Website: https://powershell.org/forums/topic/ip-address-math/
    # Copyright: (c) 2014 Dave Wyatt

    $ipaddress = $null

    # Validating the string format here instead of in a ValidateScript block allows us to use the
    # $ipaddress and $matches variables without having to perform the parsing twice.

    if ($Subnet -notmatch '^(?<address>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(?<mask>\d{1,2})$') {
        throw "Subnet address '$Subnet' does not match the expected CIDR format (example:  192.168.0.0/24)"
    }

    if (-not [ipaddress]::TryParse($matches['address'], [ref]$ipaddress)) {
        throw "Subnet address '$Subnet' contains an invalid IPv4 address."
    }

    $maskDecimal = [int]$matches['mask']

    if ($maskDecimal -gt 30) {
        throw "Subnet address '$Subnet' contains an invalid subnet mask (must be less than or equal to 30)."
    }

    $hostBitCount = 32 - $maskDecimal

    $netMask = [UInt32]0xFFFFFFFFL -shl $hostBitCount
    $hostMask = -bnot $netMask

    $networkAddress = (Get-UInt32FromIPAddress -IPAddress $ipaddress) -band $netMask
    $broadcastAddress = $networkAddress -bor $hostMask

    for ($address = $networkAddress + 1; $address -lt $broadcastAddress; $address++) {
        Get-IPAddressFromUInt32 -UInt32 $address
    }
}

function Get-IPAddressFromUInt32 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [UInt32]
        $UInt32
    )
    # Website: https://powershell.org/forums/topic/ip-address-math/
    # Copyright: (c) 2014 Dave Wyatt

    $bytes = [BitConverter]::GetBytes($UInt32)

    if ([BitConverter]::IsLittleEndian) {
        [Array]::Reverse($bytes)
    }

    return New-Object ipaddress(, $bytes)
}

function Get-UInt32FromIPAddress {
    [OutputType('System.UInt32')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ipaddress]
        $IPAddress
    )
    # Website: https://powershell.org/forums/topic/ip-address-math/
    # Copyright: (c) 2014 Dave Wyatt

    $bytes = $IPAddress.GetAddressBytes()

    if ([BitConverter]::IsLittleEndian) {
        [Array]::Reverse($bytes)
    }

    return [BitConverter]::ToUInt32($bytes, 0)
}
#endregion

if ($SubnetName) {
    Write-Debug "`$SubnetName is set to `"$SubnetName`". Filter output based on subnet"
    $SubnetConfiguration = Get-AzureRmVirtualNetwork -ExpandResource "subnets/ipConfigurations" -Name $NetworkName -ResourceGroupName $ResourceGroupName | Select-Object -ExpandProperty Subnets | Where-Object { $_.Name -eq $SubnetName}
}
else {
    Write-Debug "`$SubnetName is not set. All subnets will be used."
    $SubnetConfiguration = Get-AzureRmVirtualNetwork -ExpandResource "subnets/ipConfigurations" -Name $NetworkName -ResourceGroupName $ResourceGroupName | Select-Object -ExpandProperty Subnets
}
foreach ($Subnet in $SubnetConfiguration) {
    Write-Verbose "Check for free IP address in subnet:`t$($Subnet.Name)"
    Write-Verbose "Subnet address prefix:`t`t`t$($Subnet.AddressPrefix)"
    $PossibleIpAddresses = Get-SubnetAddress -Subnet "$($Subnet.AddressPrefix)" | Select-Object -ExpandProperty IPAddressToString
    $UsedIpAddresses = $Subnet.ipConfigurations.privateIPAddress
    if ([string]::IsNullOrEmpty($UsedIpAddresses)) {
        Write-Verbose "No IP addresses used"
        Write-Debug "All possible IP addresses are free"
        $FreeIPAddresses = $PossibleIpAddresses
    }
    else {
        Write-Debug "Compare used and possible IP addresses"
        $FreeIPAddresses = Compare-Object -ReferenceObject $PossibleIpAddresses -DifferenceObject $UsedIpAddresses | Where-Object { $_.SideIndicator -eq "<="} | Select-Object -ExpandProperty InputObject
    }
    Write-Verbose "Found $($FreeIPAddresses.Count) free IP addresses"
    foreach ($IPAddress in $FreeIPAddresses) {
        # First three address are reserved addresses in each subnet according to MSFT
        # https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-faq#are-there-any-restrictions-on-using-ip-addresses-within-these-subnets
        if ($IPAddress -notin ( $PossibleIpAddresses | Select-Object -First 3 ) ) {
            Write-Verbose "$IPAddress is free"
            New-Object psobject -Property @{
                "IPAddress"          = $IPAddress
                "Subnet"             = $Subnet.Name
                "VirtualNetworkName" = $NetworkName
                "ResourceGroupName"  = $ResourceGroupName
            }
        }
        else {
            Write-Verbose "$IPAddress is reserved"
        }
    }
}
