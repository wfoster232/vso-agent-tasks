function Get-VisualStudioPath {
    [CmdletBinding()]
    param([string]$Version)

    Trace-EnteringInvocation $MyInvocation

    # Default to all versions if not specified.
    if ($Version) {
        $versionsToTry = ,$Version
    } else {
        # Upstream callers depend on the sort order.
        $versionsToTry = "14.0", "12.0", "11.0", "10.0"
    }

    foreach ($Version in $versionsToTry) {
        if ($path = (Get-ItemProperty -LiteralPath "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\$Version" -Name 'ShellFolder' -ErrorAction Ignore).ShellFolder) {
            return $path.TrimEnd('\'[0])
        }
    }

    Trace-LeavingInvocation $MyInvocation
}
