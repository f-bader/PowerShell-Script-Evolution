[CmdletBinding(SupportsShouldProcess = $True)]
param (
    [Parameter(Mandatory = $true)]
    [String]$File
)

if (Test-Path -Path $File) {
    Write-Output "File `"$File`" exists."

    # Do not check if there is a Parameter named but use $PSCmdlet.ShouldProcess
    If ($PSCmdlet.ShouldProcess("Delete file `"$File`"")) {
        Remove-Item -Path $File -Force
    }

    if (Test-Path -Path $File) {
        Write-Output "File `"$File`" still exists."
    }
    else {
        Write-Output "File `"$File`" was deleted."
    }
} else {
    Throw "File `"$File`" does not exists."
}