$script:loggingCommandPrefix = '##vso['
$script:loggingCommandEscapeMappings = @( # TODO: WHAT ABOUT "="? WHAT ABOUT "%"?
    New-Object psobject -Property @{ Token = ';' ; Replacement = '%3B' }
    New-Object psobject -Property @{ Token = "`r" ; Replacement = '%0D' }
    New-Object psobject -Property @{ Token = "`n" ; Replacement = '%0A' }
)

function ConvertFrom-SerializedLoggingCommand {
    [CmdletBinding()]
    param([string]$Message)

    if (!$Message) {
        return
    }

    try {
        # Get the index of the prefix.
        $prefixIndex = $Message.IndexOf($script:loggingCommandPrefix)
        if ($prefixIndex -lt 0) {
            return
        }

        # Get the index of the separator between the command info and the data.
        $rbIndex = $Message.IndexOf(']'[0], $prefixIndex)
        if ($rbIndex -lt 0) {
            return
        }

        # Get the command info.
        $cmdIndex = $prefixIndex + $script:loggingCommandPrefix.Length
        $cmdInfo = $Message.Substring($cmdIndex, $rbIndex - $cmdIndex)
        $spaceIndex = $cmdInfo.IndexOf(' '[0])
        if ($spaceIndex -lt 0) {
            $command = $cmdInfo
        } else {
            $command = $cmdInfo.Substring(0, $spaceIndex)
        }

        # Get the area and event.
        [string[]]$areaEvent = $command.Split([char[]]@( '.'[0] ), [System.StringSplitOptions]::RemoveEmptyEntries)
        if ($areaEvent.Length -ne 2) {
            return
        }

        $areaName = $areaEvent[0]
        $eventName = $areaEvent[1]

        # Get the properties.
        $eventProperties = @{ }
        if ($spaceIndex -ge 0) {
            $propertiesStr = $cmdInfo.Substring($spaceIndex + 1)
            [string[]]$splitProperties = $propertiesStr.Split([char[]]@( ';'[0] ), [System.StringSplitOptions]::RemoveEmptyEntries)
            foreach ($propertyStr in $splitProperties) {
                [string[]]$pair = $propertyStr.Split([char[]]@( '='[0] ), 2, [System.StringSplitOptions]::RemoveEmptyEntries)
                if ($pair.Length -eq 2) {
                    $pair[1] = Format-LoggingCommandData -Value $pair[1] -Reverse
                    $eventProperties[$pair[0]] = $pair[1]
                }
            }
        }

        $eventData = Format-LoggingCommandData -Value $Message.Substring($rbIndex + 1) -Reverse
        New-Object -TypeName psobject -Property @{
            'Area' = $areaName
            'Event' = $eventName
            'Properties' = $eventProperties
            'Data' = $eventData
        }
    } catch { }
}

function Format-LoggingCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Area,
        [Parameter(Mandatory = $true)]
        [string]$Event,
        [string]$Data,
        [hashtable]$Properties)

    # Append the preamble.
    [System.Text.StringBuilder]$sb = New-Object -TypeName System.Text.StringBuilder
    $null = $sb.Append($script:loggingCommandPrefix).Append($Area).Append('.').Append($Event)

    # Append the properties.
    if ($Properties) {
        $first = $true
        foreach ($key in $Properties.Keys) {
            [string]$value = Format-LoggingCommandData $Properties[$key]
            if ($value) {
                if ($first) {
                    $null = $sb.Append(' ')
                    $first = $false
                } else {
                    $null = $sb.Append(';')
                }

                $null = $sb.Append("$key=$value")
            }
        }
    }

    # Append the tail and output the value.
    $Data = Format-LoggingCommandData $Data
    $sb.Append(']').Append($Data).ToString()
}

function Format-LoggingCommandData {
    [CmdletBinding()]
    param([string]$Value, [switch]$Reverse)

    if (!$Value) {
        return ''
    }

    if (!$Reverse) {
        foreach ($mapping in $script:loggingCommandEscapeMappings) {
            $Value = $Value.Replace($mapping.Token, $mapping.Replacement)
        }
    } else {
        for ($i = $script:loggingCommandEscapeMappings.Length - 1 ; $i -ge 0 ; $i--) {
            $mapping = $script:loggingCommandEscapeMappings[$i]
            $Value = $Value.Replace($mapping.Replacement, $mapping.Token)
        }
    }

    return $Value
}

function Write-LoggingCommand {
    [CmdletBinding(DefaultParameterSetName = 'Parameters')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Parameters')]
        [string]$Area,
        [Parameter(Mandatory = $true, ParameterSetName = 'Parameters')]
        [string]$Event,
        [Parameter(ParameterSetName = 'Parameters')]
        [string]$Data,
        [Parameter(ParameterSetName = 'Parameters')]
        [hashtable]$Properties,
        [Parameter(Mandatory = $true, ParameterSetName = 'Object')]
        $Command,
        [switch]$AsOutput)

    if ($PSCmdlet.ParameterSetName -eq 'Object') {
        Write-LoggingCommand -Area $Command.Area -Event $Command.Event -Data $Command.Data -Properties $Command.Properties -AsOutput:$AsOutput
        return
    }

    $command = Format-LoggingCommand -Area $Area -Event $Event -Data $Data -Properties $Properties
    if ($AsOutput) {
        $command
    } else {
        Write-Host $command
    }
}
