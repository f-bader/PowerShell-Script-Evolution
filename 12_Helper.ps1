# Dot source the function
. .\10_Final_Get-AzSRFreeIpAddress.ps1
# Show function as command
Get-Command Get-AzSRFreeIpAddress
# 
Get-AzSRFreeIpAddress -NetworkName GlobalAzureBootcamp2019-vnet -ResourceGroupName GlobalAzureBootcamp2019 -First 5