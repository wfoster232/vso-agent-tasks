[CmdletBinding()]
param()
. $PSScriptRoot\Format-MSBuildArguments
. $PSScriptRoot\Get-SolutionFiles
. $PSScriptRoot\Invoke-BuildTools
. $PSScriptRoot\Select-MSBuildLocation