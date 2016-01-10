function Format-MSBuildArguments {
    [CmdletBinding()]
    param(
        [string]$MSBuildArguments,
        [string]$Platform,
        [string]$Configuration,
        [string]$VSVersion)

    Trace-VstsEnteringInvocation $MyInvocation
    if ($Platform) {
        Write-Verbose "Adding platform: $Platform"
        $MSBuildArguments = "$MSBuildArguments /p:platform=`"$Platform`""
    }

    if ($Configuration) {
        Write-Verbose "Adding configuration: $Configuration"
        $MSBuildArguments = "$MSBuildArguments /p:configuration=`"$Configuration`""
    }

    if ($VSVersion) {
        Write-Verbose ('Adding VisualStudioVersion: {0}' -f $VSVersion)
        $MSBuildArguments = "$MSBuildArguments /p:VisualStudioVersion=`"$VSVersion`""
    }

    Write-Verbose "MSBuildArguments = $MSBuildArguments"
    $MSBuildArguments
    Trace-VstsLeavingInvocation $MyInvocation
}
