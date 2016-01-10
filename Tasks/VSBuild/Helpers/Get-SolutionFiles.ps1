function Get-SolutionFiles {
    [CmdletBinding()]
    param([string]$Solution)

    Trace-VstsEnteringInvocation $MyInvocation
    if ($Solution.Contains("*") -or $Solution.Contains("?")) {
        $solutionFiles = Find-VstsFiles -LegacyPattern $Solution
        if (!$solutionFiles.Count) {
            throw (Get-LocString -Key "SolutionNotFoundUsingSearchPattern0" -ArgumentList $Solution)
        }
    } else {
        $solutionFiles = ,$Solution
    }

    $solutionFiles
    Trace-VstsLeavingInvocation $MyInvocation
}
