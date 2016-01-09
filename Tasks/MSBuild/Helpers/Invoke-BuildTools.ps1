function Invoke-BuildTools {
    [CmdletBinding()]
    param(
        [switch]$NuGetRestore,
        [string[]]$SolutionFiles,
        [string]$MSBuildLocation,
        [string]$MSBuildArguments,
        [switch]$Clean,
        [switch]$NoTimelineLogger)

    Trace-VstsEnteringInvocation $MyInvocation
    $nugetPath = Assert-VstsPath -LiteralPath "$(Get-VstsTaskVariable -Name Agent.HomeDirectory -Require)\Agent\Worker\Tools\NuGet.exe" -PathType Leaf -PassThru
    if (-not $nugetPath -and $NuGetRestore) {
        Write-Warning (Get-VstsLocString -Key "UnableToLocateNugetExeRestoreNotPerformed" -ArgumentList 'nuget.exe')
    }

    foreach ($file in $SolutionFiles) {
        if ($nugetPath -and $NuGetRestore) {
            if ($env:NUGET_EXTENSIONS_PATH) {
                Write-Host (Get-VstsLocString -Key "DetectedNuGetExtensionsLoaderPath0" -ArgumentList $env:NUGET_EXTENSIONS_PATH)
            }

            $slnDirectory = [System.IO.Path]::GetDirectoryName($file)
            Invoke-VstsTool -FileName $nugetPath -Arguments "restore `"$file`" -NonInteractive" -WorkingDirectory $slnDirectory
        }

        if ($Clean) {
            Invoke-VstsMSBuild -ProjectFile $file -Targets Clean -LogFile "$file-clean.log" -MSBuildPath $MSBuildLocation -AdditionalArguments $MSBuildArguments -NoTimelineLogger:$NoTimelineLogger
        }

        Invoke-VstsMSBuild -ProjectFile $file -LogFile "$file.log" -MSBuildPath $MSBuildLocation -AdditionalArguments $MSBuildArguments -NoTimelineLogger:$NoTimelineLogger
    }

    Trace-VstsLeavingInvocation $MyInvocation
}
