function Get-SolutionFiles {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)]
        [string]$Solution)

    Trace-VstsEnteringInvocation $MyInvocation
    if ($Solution.Contains("*") -or $Solution.Contains("?")) {
        $solutionFiles = Find-VstsFiles -LegacyPattern $Solution
        if (!$solutionFiles.Count) {
            throw (Get-VstsLocString -Key "SolutionNotFoundUsingSearchPattern0" -ArgumentList $Solution)
        }
    } else {
        $solutionFiles = ,$Solution
    }

    $solutionFiles
    Trace-VstsLeavingInvocation $MyInvocation
}
