[CmdletBinding()]
param()
. $PSScriptRoot\Format-MSBuildArguments
. $PSScriptRoot\Get-SolutionFiles
. $PSScriptRoot\Get-VisualStudioPath
. $PSScriptRoot\Invoke-BuildTools
. $PSScriptRoot\Select-MSBuildLocation
. $PSScriptRoot\Select-VSVersion