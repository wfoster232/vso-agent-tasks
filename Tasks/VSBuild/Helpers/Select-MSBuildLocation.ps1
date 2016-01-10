function Select-MSBuildLocation {
    [CmdletBinding()]
    param([string]$VSVersion, [string]$Architecture)

    Trace-VstsEnteringInvocation $MyInvocation

    # Determine which MSBuild version to use.
    $msBuildVersion = $null;
    switch ("$VSVersion") {
        '' { break }
        '14.0' { $msBuildVersion = '14.0' ; break }
        '12.0' { $msBuildVersion = '12.0' ; break }
        '11.0' { $msBuildVersion = '4.0' ; break }
        '10.0' { $msBuildVersion = '4.0' ; break }
        default { throw (Get-LocString -Key UnexpectedVSVersion0 -ArgumentList $VSVersion) }
    }

    # Find the MSBuild location.
    if (!($msBuildLocation = Get-VstsMSBuildPath -Version $msBuildVersion -Architecture $Architecture)) {
        throw (Get-LocString -Key MSBuildNotFoundVersion0Architecture1 -ArgumentList $msBuildVersion, $Architecture)
    }

    $msBuildLocation
    Trace-VstsLeavingInvocation $MyInvocation
}
