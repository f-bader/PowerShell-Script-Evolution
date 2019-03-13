<#
.SYNOPSIS
    Converts an IPv4 subnet address in CIDR notation (ie, 192.168.0.0/24) into a collection of [ipaddress] objects.

.DESCRIPTION
    Converts an IPv4 subnet address in CIDR notation (ie, 192.168.0.0/24) into a collection of [ipaddress] objects.

.PARAMETER Subnet
    IPv4 subnet address in CIDR notation (ie, 192.168.0.0/24)

.EXAMPLE
    Get-SubnetAddress "192.168.0.0/24"

.NOTES
    Website: https://powershell.org/forums/topic/ip-address-math/
    Copyright: (c) 2014 Dave Wyatt
    License: MIT https://opensource.org/licenses/MIT
    Used with permission: https://twitter.com/msh_dave/status/1037475306381094913
#>
function Get-SubnetAddress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Subnet
    )

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
