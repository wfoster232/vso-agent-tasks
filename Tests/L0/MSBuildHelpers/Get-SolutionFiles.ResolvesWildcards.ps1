[CmdletBinding()]
param()

# Arrange.
. $PSScriptRoot\..\..\lib\Initialize-Test.ps1
Register-Mock Find-VstsFiles { $expected } -- -LegacyPattern $solution
Microsoft.PowerShell.Core\Import-Module $PSScriptRoot\..\..\..\Tasks\MSBuild\MSBuildHelpers
$expected = 'Some solution 1', 'Some solution 2'
$solutions = 'Some * solution', 'Some ? solution'
foreach ($solution in $solutions) {
    Register-Mock Find-VstsFiles { $expected } -- -LegacyPattern $solution

    # Act.
    $actual = Get-SolutionFiles -Solution $solution

    # Assert.
    Assert-AreEqual $expected $actual
}