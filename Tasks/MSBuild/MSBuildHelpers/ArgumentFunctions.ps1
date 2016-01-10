function Format-MSBuildArguments {
    [CmdletBinding()]
    param(
        [string]$MSBuildArguments,
        [string]$Platform,
        [string]$Configuration,
        [string]$VSVersion)

    Trace-VstsEnteringInvocation $MyInvocation
    if ($Platform) {
        $MSBuildArguments = "$MSBuildArguments /p:platform=`"$Platform`""
    }

    if ($Configuration) {
        $MSBuildArguments = "$MSBuildArguments /p:configuration=`"$Configuration`""
    }

    if ($VSVersion) {
        $MSBuildArguments = "$MSBuildArguments /p:VisualStudioVersion=`"$VSVersion`""
    }

    $MSBuildArguments
    Trace-VstsLeavingInvocation $MyInvocation
}
