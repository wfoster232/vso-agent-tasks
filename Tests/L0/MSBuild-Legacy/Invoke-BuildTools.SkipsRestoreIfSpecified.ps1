[cmdletbinding()]
param()

# Arrange.
. $PSScriptRoot\..\..\lib\Initialize-Test.ps1
. $PSScriptRoot\..\..\..\Tasks\MSBuild\Helpers.ps1
$env:NUGET_EXTENSIONS_PATH = $null
$directory = 'Some drive:\Some directory'
$file = "$directory1\Some solution"
$nuGetPath = 'Some path to NuGet.exe'
$msBuildLocation = 'Some MSBuild location'
$msBuildArguments = 'Some MSBuild arguments'
Register-Mock Get-ToolPath { $nuGetPath } -- -Name 'NuGet.exe'
Register-Mock Invoke-Tool
Register-Mock Invoke-MSBuild
Register-Mock Write-Warning

# Act.
Invoke-BuildTools -SolutionFiles $file -MSBuildLocation 'Some MSBuild location' -MSBuildArguments 'Some MSBuild arguments' -Clean -NoTimelineLogger

# Assert.
Assert-WasCalled Write-Warning -Times 0
Assert-WasCalled Invoke-Tool -Times 0
Assert-WasCalled Invoke-MSBuild -Times 2
