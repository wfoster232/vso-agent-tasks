param (
    [string]$codeCoverageTool,
    [string]$summaryFileLocation,
    [string]$reportDirectory,
    [string]$additionalCodeCoverageFiles
)

Write-Verbose 'Entering PublishCodeCoverage.ps1' -Verbose
Write-Verbose "publishCodeCoverageResults = $publishCodeCoverageResults" -Verbose
Write-Verbose "codeCoverageTool = $codeCoverageTool" -Verbose
Write-Verbose "summaryFileLocation = $summaryFileLocation" -Verbose
Write-Verbose "reportDirectory = $reportDirectory" -Verbose
Write-Verbose "additionalCodeCoverageFiles = $additionalCodeCoverageFiles" -Verbose

# Import the Task.CodeCoverage dll that has all the cmdlets we need for Build
import-module "Microsoft.TeamFoundation.DistributedTask.Task.CodeCoverage"

# Publish Code Coverage Files
$CodeCoverageFiles = Find-Files -SearchPattern $additionalCodeCoverageFiles
Publish-CodeCoverage -CodeCoverageTool $codeCoverageTool -SummaryFileLocation $summaryFileLocation -ReportDirectory $reportDirectory -AdditionalCodeCoverageFiles $CodeCoverageFiles -Context $distributedTaskContext    

Write-Verbose "Leaving script PublishCodeCoverage.ps1"