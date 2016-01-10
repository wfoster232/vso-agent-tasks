########################################
# Public functions.
########################################
function Invoke-NuGetRestore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$File)

    Trace-VstsEnteringInvocation $MyInvocation
    $nugetPath = Assert-VstsPath -LiteralPath "$(Get-VstsTaskVariable -Name Agent.HomeDirectory -Require)\Agent\Worker\Tools\NuGet.exe" -PathType Leaf -PassThru
    if ($env:NUGET_EXTENSIONS_PATH) {
        Write-Host (Get-VstsLocString -Key NG_DetectedNuGetExtensionsLoaderPath0 -ArgumentList $env:NUGET_EXTENSIONS_PATH)
    }

    $directory = [System.IO.Path]::GetDirectoryName($file)
    Invoke-VstsTool -FileName $nugetPath -Arguments "restore `"$file`" -NonInteractive" -WorkingDirectory $directory
    Trace-VstsLeavingInvocation $MyInvocation
}