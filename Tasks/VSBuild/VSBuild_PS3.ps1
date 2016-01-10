[CmdletBinding()]
param([switch]$OmitDotSource)

Trace-VstsEnteringInvocation $MyInvocation
[string]$VSVersion = Get-VstsInput -Name VSVersion
[string]$MSBuildArchitecture = Get-VstsInput -Name MSBuildArchitecture
[string]$MSBuildArgs = Get-VstsInput -Name MSBuildArgs
[string]$Solution = Get-VstsInput -Name Solution -Require
[string]$Platform = Get-VstsInput -Name Platform
[string]$Configuration = Get-VstsInput -Name Configuration
[bool]$Clean = Get-VstsInput -Name Clean -AsBool
[bool]$RestoreNugetPackages = Get-VstsInput -Name RestoreNugetPackages -AsBool
[bool]$LogProjectEvents = Get-VstsInput -Name LogProjectEvents -AsBool
if ([string]$VSLocation = Get-VstsInput -Name VSLocation) {
    Write-Warning (Get-LocString -Key VSLocationDeprecated0 -ArgumentList $VSLocation)
    $VSLocation = $null
}

if ([string]$MSBuildLocation = Get-VstsInput -Name MSBuildLocation) {
    Write-Warning (Get-LocString -Key MSBuildLocationDeprecated0 -ArgumentList $MSBuildLocation)
    $MSBuildLocation = $null
}

if ([string]$MSBuildVersion = Get-VstsInput -Name MSBuildVersion) {
    Write-Warning (Get-LocString -Key MSBuildVersionDeprecated0 -ArgumentList $MSBuildVersion)
    $MSBuildVersion = $null
}

Import-Module -Name $PSScriptRoot\Helpers\Helpers.psm1
Import-Module -Name $PSScriptRoot\MSBuildHelpers\MSBuildHelpers.psm1
$solutionFiles = Get-SolutionFiles -Solution $Solution
$VSVersion = Select-VSVersion -PreferredVersion $VSVersion
$MSBuildLocation = Select-MSBuildLocation -VSVersion $VSVersion -Architecture $MSBuildArchitecture
$MSBuildArgs = Format-MSBuildArguments -MSBuildArguments $MSBuildArgs -Platform $Platform -Configuration $Configuration -VSVersion $VSVersion
Invoke-BuildTools -NuGetRestore:$RestoreNuGetPackages -SolutionFiles $solutionFiles -MSBuildLocation $MSBuildLocation -MSBuildArguments $MSBuildArgs -Clean:$Clean -NoTimelineLogger:(!$LogProjectEvents)
Trace-VstsLeavingInvocation $MyInvocation
