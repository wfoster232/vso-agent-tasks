[CmdletBinding()]
param()

# Arrange.
. $PSScriptRoot\..\..\lib\Initialize-Test.ps1
Microsoft.PowerShell.Core\Import-Module $PSScriptRoot\..\..\..\Tasks\MSBuild\MSBuildHelpers
$directory1 = 'Some drive:\Some directory 1'
$directory2 = 'Some drive:\Some directory 2'
$file1 = "$directory1\Some solution 1"
$file2 = "$directory2\Some solution 2"
$msBuildLocation = 'Some MSBuild location'
$msBuildArguments = 'Some MSBuild arguments'
Register-Mock Invoke-NuGetRestore { 'Some NuGet output 1' } -- -File $file1
Register-Mock Invoke-NuGetRestore { 'Some NuGet output 2' } -- -File $file2
Register-Mock Invoke-MSBuild { 'Some MSBuild clean output 1' } -- -ProjectFile $file1 -Targets Clean -LogFile "$file1-clean.log" -MSBuildPath $msBuildLocation -AdditionalArguments $msBuildArguments -NoTimelineLogger: $true
Register-Mock Invoke-MSBuild { 'Some MSBuild clean output 2' } -- -ProjectFile $file2 -Targets Clean -LogFile "$file2-clean.log" -MSBuildPath $msBuildLocation -AdditionalArguments $msBuildArguments -NoTimelineLogger: $true
Register-Mock Invoke-MSBuild { 'Some MSBuild output 1' } -- -ProjectFile $file1 -LogFile "$file1.log" -MSBuildPath $msBuildLocation -AdditionalArguments $msBuildArguments -NoTimelineLogger: $true
Register-Mock Invoke-MSBuild { 'Some MSBuild output 2' } -- -ProjectFile $file2 -LogFile "$file2.log" -MSBuildPath $msBuildLocation -AdditionalArguments $msBuildArguments -NoTimelineLogger: $true

# Act.
$actual = Invoke-BuildTools -NuGetRestore -SolutionFiles $file1, $file2 -MSBuildLocation 'Some MSBuild location' -MSBuildArguments 'Some MSBuild arguments' -Clean -NoTimelineLogger

# Assert.
Assert-AreEqual -Expected @(
        'Some NuGet output 1'
        'Some MSBuild clean output 1'
        'Some MSBuild output 1'
        'Some NuGet output 2'
        'Some MSBuild clean output 2'
        'Some MSBuild output 2'
    ) -Actual $actual
