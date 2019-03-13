# Simple Module Manifest
New-ModuleManifest -Path .\ExampleModule\ExampleModule.psd1 -RootModule "ExampleModule.psm1"

# Better explicitly define which Functions, Aliases and Cmdlets to export
# https://docs.microsoft.com/en-us/windows-server/administration/performance-tuning/powershell/module-authoring-considerations
$FunctionsToExport = Get-ChildItem -Path .\ExampleModule\functions\*.ps1 -ErrorAction SilentlyContinue
New-ModuleManifest -Path .\ExampleModule\ExampleModule.psd1 -FunctionsToExport @(($FunctionsToExport.BaseName)) -AliasesToExport @() -CmdletsToExport @() -RootModule "ExampleModule.psm1"