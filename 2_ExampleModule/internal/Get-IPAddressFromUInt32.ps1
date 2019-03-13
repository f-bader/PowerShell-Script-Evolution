<#
.SYNOPSIS
    Converts UInt32 object to ipaddress object

.DESCRIPTION
    Converts UInt32 object to ipaddress object
    Helper function for Get-SubnetAddress

.PARAMETER UInt32
    UInt32 object

.NOTES
    Website: https://powershell.org/forums/topic/ip-address-math/
    Copyright: (c) 2014 Dave Wyatt
    License: MIT https://opensource.org/licenses/MIT
    Used with permission: https://twitter.com/msh_dave/status/1037475306381094913
#>
function Get-IPAddressFromUInt32 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [UInt32]
        $UInt32
    )

    $bytes = [BitConverter]::GetBytes($UInt32)

    if ([BitConverter]::IsLittleEndian) {
        [Array]::Reverse($bytes)
    }

    return New-Object ipaddress(, $bytes)
}
