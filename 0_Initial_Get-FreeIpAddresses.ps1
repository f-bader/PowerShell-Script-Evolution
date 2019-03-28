$NetworkName = "GlobalAzureBootcamp2019-vnet"
$ResourceGroupName = "GlobalAzureBootcamp2019"


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

$SubnetConfiguration = Get-AzureRmVirtualNetwork -ExpandResource "subnets/ipConfigurations" -Name $NetworkName -ResourceGroupName $ResourceGroupName | Select-Object -ExpandProperty Subnets

foreach ($Subnet in $SubnetConfiguration) {
    $PossibleIpAddresses = Get-SubnetAddress -Subnet "$($Subnet.AddressPrefix)" | Select-Object -ExpandProperty IPAddressToString
    $UsedIpAddresses = $Subnet.ipConfigurations.privateIPAddress
    if ([string]::IsNullOrEmpty($UsedIpAddresses)) {
        $FreeIPAddresses = $PossibleIpAddresses
    }
    else {
        $FreeIPAddresses = Compare-Object -ReferenceObject $PossibleIpAddresses -DifferenceObject $UsedIpAddresses | Where-Object { $_.SideIndicator -eq "<="} | Select-Object -ExpandProperty InputObject
    }
    foreach ($IPAddress in $FreeIPAddresses) {
        # First three address are reserved addresses in each subnet according to MSFT
        # https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-faq#are-there-any-restrictions-on-using-ip-addresses-within-these-subnets
        if ($IPAddress -notin ( $PossibleIpAddresses | Select-Object -First 3 ) ) {
            New-Object psobject -Property @{
                "IPAddress"          = $IPAddress
                "Subnet"             = $Subnet.Name
                "VirtualNetworkName" = $NetworkName
                "ResourceGroupName"  = $ResourceGroupName
            }
        }
    }
}
