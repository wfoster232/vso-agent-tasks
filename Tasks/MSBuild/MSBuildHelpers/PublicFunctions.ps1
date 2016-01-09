function Get-MSBuildPath {
    [CmdletBinding()]
    param(
        [string]$Version,
        [string]$Architecture)

    Trace-EnteringInvocation $MyInvocation
    $msbuildUtilitiesAssemblies = @(
        "Microsoft.Build.Utilities.Core, Version=14.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a, processorArchitecture=MSIL"
        "Microsoft.Build.Utilities.v12.0, Version=12.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a, processorArchitecture=MSIL"
        "Microsoft.Build.Utilities.v4.0, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a, processorArchitecture=MSIL"
    )

    # Attempt to load a Microsoft build utilities DLL.
    $index = 0
    [System.Reflection.Assembly]$msUtilities = $null
    while ($msUtilities -eq $null -and $index -lt $msbuildUtilitiesAssemblies.Length) {
        try {
            $msUtilities = [System.Reflection.Assembly]::Load((New-Object System.Reflection.AssemblyName($msbuildUtilitiesAssemblies[$index])))
        } catch [FileNotFoundException] { }

        $index++
    }

    [string]$msBuildPath = $null

    # Default to x86 architecture if not specified.
    if (!$Architecture) {
        $Architecture = "x86"
    }

    if ($msUtilities -ne $null) {
        [type]$t = $msUtilities.GetType('Microsoft.Build.Utilities.ToolLocationHelper')
        if ($t -ne $null) {
            # Attempt to load the method info for GetPathToBuildToolsFile. This method
            # is available in the 14.0 and 12.0 utilities DLL. It is not available in
            # the 4.0 utilities DLL.
            [System.Reflection.MethodInfo]$mi = $t.GetMethod(
                "GetPathToBuildToolsFile",
                [type[]]@( [string], [string], $msUtilities.GetType("Microsoft.Build.Utilities.DotNetFrameworkArchitecture") ))
            if ($mi -ne $null -and $mi.GetParameters().Length -eq 3) {
                $versions = "14.0", "12.0", "4.0"
                if ($Version) {
                    $versions = @( $Version )
                }

                # Translate the architecture parameter into the corresponding value of the
                # DotNetFrameworkArchitecture enum. Parameter three of the target method info
                # takes this enum. Leverage parameter three to get to the enum's type info.
                $param3 = $mi.GetParameters()[2]
                $archValues = [System.Enum]::GetValues($param3.ParameterType)
                [object]$archValue = $null
                if ($Architecture -eq 'x86') {
                    $archValue = $archValues.GetValue(1) # DotNetFrameworkArchitecture.Bitness32
                } elseif ($Architecture -eq 'x64') {
                    $archValue = $archValues.GetValue(2) # DotNetFrameworkArchitecture.Bitness64
                } else {
                    $archValue = $archValues.GetValue(1) # DotNetFrameworkArchitecture.Bitness32
                }

                # Attempt to resolve the path for each version.
                $versionIndex = 0
                while (!$msBuildPath -and $versionIndex -lt $versions.Length) {
                    $msBuildPath = $mi.Invoke(
                        $null,
                        @( 'msbuild.exe' # string fileName
                            $versions[$versionIndex] # string toolsVersion
                            $archValue ))
                    $versionIndex++
                }
            } elseif (!$Version -or $Version -eq "4.0") {
                # Attempt to load the method info GetPathToDotNetFrameworkFile. This method
                # is available in the 4.0 utilities DLL.
                $mi = $t.GetMethod(
                    "GetPathToDotNetFrameworkFile",
                    [type[]]@( [string], $msUtilities.GetType("Microsoft.Build.Utilities.TargetDotNetFrameworkVersion"), $msUtilities.GetType("Microsoft.Build.Utilities.DotNetFrameworkArchitecture") ))
                if ($mi -ne $null -and $mi.GetParameters().Length -eq 3) {
                    # Parameter two of the target method info takes the TargetDotNetFrameworkVersion
                    # enum. Leverage parameter two to get the enum's type info.
                    $param2 = $mi.GetParameters()[1];
                    $frameworkVersionValues = [System.Enum]::GetValues($param2.ParameterType);

                    # Translate the architecture parameter into the corresponding value of the
                    # DotNetFrameworkArchitecture enum. Parameter three of the target method info
                    # takes this enum. Leverage parameter three to get to the enum's type info.
                    $param3 = $mi.GetParameters()[2];
                    $archValues = [System.Enum]::GetValues($param3.ParameterType);
                    [object]$archValue = $null
                    if ($Architecture -eq "x86") {
                        $archValue = $archValues.GetValue(1) # DotNetFrameworkArchitecture.Bitness32
                    } elseif ($Architecture -eq "x64") {
                        $archValue = $archValues.GetValue(2) # DotNetFrameworkArchitecture.Bitness64
                    } else {
                        $archValue = $archValues.GetValue(1) # DotNetFrameworkArchitecture.Bitness32
                    }

                    # Attempt to resolve the path.
                    $msBuildPath = $mi.Invoke(
                        $null,
                        @( "msbuild.exe" # string fileName
                            $frameworkVersionValues.GetValue($frameworkVersionValues.Length - 1) # enum TargetDotNetFrameworkVersion.VersionLatest
                            $archValue ))
                }
            }
        }
    }

    if ($msBuildPath -and (Test-Path -LiteralPath $msBuildPath -PathType Leaf)) {
        Write-Verbose "MSBuild: $msBuildPath"
        $msBuildPath
    }

    Trace-LeavingInvocation $MyInvocation
}

function Invoke-MSBuild {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$ProjectFile,
        [string]$Targets,
        [string]$LogFile,
        [switch]$NoTimelineLogger,
        [string]$MSBuildPath,
        [string]$AdditionalArguments)

    Trace-EnteringInvocation $MyInvocation

    # Get the MSBuild path.
    if (!$MSBuildPath) {
        $MSBuildPath = Get-MSBuildPath
    } else {
        $MSBuildPath = [System.Environment]::ExpandEnvironmentVariables($MSBuildPath)
        if (!$MSBuildPath -like '*msbuild.exe') {
            $MSBuildPath = [System.IO.Path]::Combine($MSBuildPath, 'msbuild.exe')
        }
    }

    # Validate the path exists.
    $null = Assert-VstsPath -LiteralPath $MSBuildPath -PathType Leaf

    # Don't show the logo and do not allow node reuse so all child nodes are shut down once the master
    # node has completed build orchestration.
    $arguments = "`"$ProjectFile`" /nologo /m /nr:false"

    # Add the targets if specified.
    if ($Targets) {
        $arguments = "$arguments /t:`"$Targets`""
    }

    # If a log file was specified then hook up the default file logger.
    if ($LogFile) {
        $arguments = "$arguments /fl /flp:`"logfile=$LogFile`""
    }

    # Always hook up the timeline logger. If project events are not requested then we will simply drop those
    # messages on the floor.
    $loggerAssembly = "$(Get-TaskVariable -Name Agent.HomeDirectory -Require)\Agent\Worker\Microsoft.TeamFoundation.DistributedTask.MSBuild.Logger.dll"
    $null = Assert-VstsPath -LiteralPath $loggerAssembly -PathType Leaf
    $arguments = "$arguments /dl:CentralLogger,`"$loggerAssembly`"*ForwardingLogger,`"$loggerAssembly`""

    if ($AdditionalArguments) {
        $arguments = "$arguments $AdditionalArguments"
    }

    # Store the solution folder so we can provide solution-relative paths (for now).
    $solutionDirectory = [System.IO.Path]::GetDirectoryName($ProjectFile)

    # Start the detail timeline.
    if (!$NoTimelineLogger) {
        $detailId = [guid]::NewGuid()
        $detailName = Get-LocString -Key 'Build0' -ArgumentList ([System.IO.Path]::GetFileName($ProjectFile))
        $detailStartTime = [datetime]::UtcNow.ToString('O')
        Write-LogDetail -Id $detailId -Type Process -Name $detailName -Progress 0 -StartTime $detailStartTime -State Initialized -AsOutput
    }

    $detailResult = 'Succeeded'
    try {
        if ($NoTimelineLogger) {
            Invoke-Tool -FileName $MSBuildPath -Arguments $arguments
        } else {
            Invoke-Tool -FileName $MSBuildPath -Arguments $arguments |
                ForEach-Object {
                    # TODO: THIS COULD PROBABLY BE SPED UP BY CHECKING FOR "##vso" BEFORE CALLING THE FUNCTION. THE CALLING FUNCTION ALSO CHECKS FOR ##vso, SO
                    # IT WOULD BE A REDUNDANT CHECK. HOWEVER, THE ##vso COMMANDS APPEAR VERY INFREQUENTLY IN THE OUTPUT RELATIVE TO THE TOTAL OUTPUT.
                    if ($command = ConvertFrom-SerializedLoggingCommand -Message $_) {
                        if ($command.Area -eq 'task' -and
                            $command.Event -eq 'logissue' -and
                            $command.Properties['type'] -eq 'error') {

                            # An error issue was detected. Set the result to Failed for the logdetail completed event.
                            $detailResult = 'Failed'
                        } elseif ($command.Area -eq 'task' -and
                            $command.Event -eq 'logdetail' -and
                            !$NoTimelineLogger) {

                            if (!($parentProjectId = $command.Properties['parentid']) -or
                                [guid]$parentProjectId -eq [guid]::Empty) {

                                # Default the parent ID to the root ID.
                                $command.Properties['parentid'] = $detailId.ToString('D')
                            }

                            if ($projFile = $command.Properties['name']) {
                                # Make the project file relative.
                                if ($projFile.StartsWith("$solutionDirectory\", [System.StringComparison]::OrdinalIgnoreCase)) {
                                    $projFile = $projFile.Substring($solutionDirectory.Length).TrimStart('\'[0])
                                } else {
                                    $projFile = [System.IO.Path]::GetFileName($projFile)
                                }

                                # If available, add the targets to the name.
                                if ($targetNames = $command.Properties['targetnames']) {
                                    $projFile = "$projFile ($targetNames)"
                                }

                                $command.Properties['name'] = $projFile
                            }
                        }

                        Write-LoggingCommand -Command $command -AsOutput
                    } else {
                        $_
                    }
                }
        }

        if ($LASTEXITCODE -ne 0) {
            throw (Get-LocString -Key 'UnexpectedExitCodeReceivedFromMSBuild0' -ArgumentList $LASTEXITCODE)
        }
    } finally {
        # Complete the detail timeline.
        if (!$NoTimelineLogger) {
            $detailFinishTime = [datetime]::UtcNow.ToString('O')
            Write-LogDetail -Id $detailId -FinishTime $detailFinishTime -Progress 100 -State Completed -Result $detailResult -AsOutput
        }
    }

    Trace-LeavingInvocation $MyInvocation
}
