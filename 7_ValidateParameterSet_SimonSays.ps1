[CmdletBinding(SupportsShouldProcess = $True)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("PowerShell rocks","Community rocks","Hamburg loves PowerShell")]
    [String]$Output
)

Write-Output "Simon says: $Output"

<#
Possible parameter validations:
 * ValidateCount (Number of items for this parameter)
 * ValidateLength (Length of the string)
 * ValidatePattern (Regular Expression)
 * ValidateRange (Number between to values)
 * ValidateScript (Every script that either returns $false or throws if not valid. Use $_ for the value)
 * ValidateSet (Define valid values, they will be available for tab completion)
 * ValidateNotNull 
 * ValidateNotNullOrEmpty 
 * ValidateDrive (Check if the file is on a specific drive e.g. C or HKLM see Get-PSDrive for available drives, the file itself is not checked)
 * ValidateUserDrive (Check if the Drive is the UserDrive defined in Just Enough Administration session configuration)
 
See https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters?view=powershell-5.1 for more information

#>