<#
.SYNOPSIS
    Find free IP addresses in a Azure Virtual Network

.DESCRIPTION
    Returns a specified number or all free IP addresses from a specified Azure Virtual Network
    This allows easy IP address management if a static IP address should be used

    This function is differnt to Test-AzureRmPrivateIPAddressAvailability since it returns all free IP addresses or a specified number.
    There is also no need to provide a IP address

.PARAMETER NetworkName
    Name of the Virtual Network

.PARAMETER ResourceGroupName
    Name of the Resource Group

.PARAMETER SubnetName
    Name of the subnet

.PARAMETER First
    Gets only the specified number of objects. Enter the number of objects to get.

.EXAMPLE
    Find all free IP addresses in a specifiec Virtual Network
    Get-AzSRFreeIpAddress -NetworkName "MyVirtualNetwork" -ResourceGroupName "Subnet01"

.EXAMPLE
    Find one free IP address in one of the available virtual networks
    Get-AzVirtualNetwork | Get-AzSRFreeIpAddress -First 1

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRFreeIpAddress {
    [CmdletBinding()]
    param (
        [Alias('Name')]
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [String]$NetworkName,
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [String]$ResourceGroupName,
        [Parameter(Mandatory = $false)]
        [String]$SubnetName,
        [Int32]$First
    )

    Begin {
        #region Check if logged in
        try {
            Get-AzureRmContext | Out-Null
        }
        catch {
            throw $($_.Exception.Message)
        }
        #endregion
    }

    Process {
        $FoundIPAddress = 0

        # Check for Az Module
        if ( ( Get-Module Az.Network -ListAvailable -ErrorAction SilentlyContinue ) ) {
            $AzModule = $true
        } else {
            $AzModule = $false
        }


        if ($SubnetName) {
            if ($AzModule) {
                $SubnetConfiguration = Get-AzVirtualNetwork -ExpandResource "subnets/ipConfigurations" -Name $NetworkName -ResourceGroupName $ResourceGroupName | Select-Object -ExpandProperty Subnets | Where-Object { $_.Name -eq $SubnetName}
            } else {
                $SubnetConfiguration = Get-AzureRmVirtualNetwork -ExpandResource "subnets/ipConfigurations" -Name $NetworkName -ResourceGroupName $ResourceGroupName | Select-Object -ExpandProperty Subnets | Where-Object { $_.Name -eq $SubnetName}
            }
        } else {
            if ($AzModule) {
                $SubnetConfiguration = Get-AzVirtualNetwork -ExpandResource "subnets/ipConfigurations" -Name $NetworkName -ResourceGroupName $ResourceGroupName | Select-Object -ExpandProperty Subnets
            } else {
                $SubnetConfiguration = Get-AzureRmVirtualNetwork -ExpandResource "subnets/ipConfigurations" -Name $NetworkName -ResourceGroupName $ResourceGroupName | Select-Object -ExpandProperty Subnets
            }
        }
        foreach ($Subnet in $SubnetConfiguration) {
            Write-Verbose "Check for free IP address in subnet:`t$($Subnet.Name)"
            if ( ( $PSBoundParameters.ContainsKey('First') ) -and ($FoundIPAddress -ge $First)) {
                # We have enough IP addresses
                break
            }
            Write-Verbose "Subnet address prefix:`t`t`t$($Subnet.AddressPrefix)"
            $PossibleIpAddresses = Get-SubnetAddress -Subnet "$($Subnet.AddressPrefix)" | Select-Object -ExpandProperty IPAddressToString
            $UsedIpAddresses = $Subnet.ipConfigurations.privateIPAddress
            if ([string]::IsNullOrEmpty($UsedIpAddresses)) {
                Write-Verbose "No IP addresses used"
                $FreeIPAddresses = $PossibleIpAddresses
            } else {
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
                    $FoundIPAddress++
                    if ( ( $PSBoundParameters.ContainsKey('First') ) -and ($FoundIPAddress -ge $First)) {
                        # We have enough IP addresses
                        break
                    }
                } else {
                    Write-Verbose "$IPAddress is reserved"
                }
            }
        }
    }
}
