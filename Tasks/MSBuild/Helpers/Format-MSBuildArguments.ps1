function Format-MSBuildArguments {
    [CmdletBinding()]
    param(
        [string]$MSBuildArguments,
        [string]$Platform,
        [string]$Configuration)

    Trace-VstsEnteringInvocation $MyInvocation
    if ($Platform) {
        $MSBuildArguments = "$MSBuildArguments /p:platform=`"$Platform`""
    }

    if ($Configuration) {
        $MSBuildArguments = "$MSBuildArguments /p:configuration=`"$Configuration`""
    }

    $MSBuildArguments
    Trace-VstsLeavingInvocation $MyInvocation
}
