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
    foreach ($file in $SolutionFiles) {
        if ($NuGetRestore) {
            Invoke-NuGetRestore -File $file
        }

        if ($Clean) {
            Invoke-VstsMSBuild -ProjectFile $file -Targets Clean -LogFile "$file-clean.log" -MSBuildPath $MSBuildLocation -AdditionalArguments $MSBuildArguments -NoTimelineLogger:$NoTimelineLogger
        }

        Invoke-VstsMSBuild -ProjectFile $file -LogFile "$file.log" -MSBuildPath $MSBuildLocation -AdditionalArguments $MSBuildArguments -NoTimelineLogger:$NoTimelineLogger
    }

    Trace-VstsLeavingInvocation $MyInvocation
}
