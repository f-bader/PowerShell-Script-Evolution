[CmdletBinding()]
param (
    [Alias('Name')]
    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
    [String]$Planet
)

# Usage: .\8_Pipeline_Simple.ps1 -Planet "Endor"
# Usage:  @("Mercury","Venus","Earth","Mars","Jupiter","Saturn","Uranus","Neptune") | .\8_Pipeline_Simple.ps1

Begin {
    # Will be executed once at the beginning
    Write-Output "I will now tell you which planets you send"
}

Process {
    # Executes for every item
    Start-Sleep -Milliseconds ( Get-Random -Minimum 100 -Maximum 1000 )
    Write-Output $Planet
}

End {
    # Will be executed once at the end
    Write-Output "That's all I got"
}

# More information: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_methods?view=powershell-5.1