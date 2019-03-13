<#
.SYNOPSIS
    Converts ipaddress object to UInt32

.DESCRIPTION
    Converts ipaddress object to UInt32
    Helper function for Get-SubnetAddress

.PARAMETER IPAddress
    IP address object

.NOTES
    Website: https://powershell.org/forums/topic/ip-address-math/
    Copyright: (c) 2014 Dave Wyatt
    License: MIT https://opensource.org/licenses/MIT
    Used with permission: https://twitter.com/msh_dave/status/1037475306381094913
#>
function Get-UInt32FromIPAddress {
    [OutputType('System.UInt32')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ipaddress]
        $IPAddress
    )

    $bytes = $IPAddress.GetAddressBytes()

    if ([BitConverter]::IsLittleEndian) {
        [Array]::Reverse($bytes)
    }

    return [BitConverter]::ToUInt32($bytes, 0)
}