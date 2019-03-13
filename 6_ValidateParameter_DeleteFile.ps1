[CmdletBinding(SupportsShouldProcess = $True)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateScript(
        { Test-Path -Path $_ }
    )]
    [String]$File
)

# Replaced the outer if condition with a ValidateScript
Write-Output "File `"$File`" exists."

If ($PSCmdlet.ShouldProcess("Delete file `"$File`"")) {
    Remove-Item -Path $File -Force
}

if (Test-Path -Path $File) {
    Write-Output "File `"$File`" still exists."
}
else {
    Write-Output "File `"$File`" was deleted."
}