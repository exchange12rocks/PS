function Split-Output {
    #Requires -Version 3.0

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [System.Object[]]$InputObject,
        [Parameter(Mandatory, Position = 1)]
        [ScriptBlock]$ScriptBlock,
        [Parameter(Position = 2)]
        [ValidateSet('Debug','Error','Warning','Output')]
        [string]$Mode
    )

    BEGIN {
        $ScriptBlock = [ScriptBlock]::Create('PROCESS {{$_ | {0}}}' -f $ScriptBlock.ToString())
    }
    PROCESS {
        foreach ($Item in $InputObject) {
            switch ($Mode) {
                'Debug' {
                    if ($Item -is [System.Management.Automation.DebugRecord]) {
                        $Item | & $ScriptBlock
                    }
                    else {
                        Write-Output -InputObject $Item
                    }
                }
                'Error' {
                    if ($Item -is [System.Management.Automation.ErrorRecord]) {
                        $Item | & ($ScriptBlock)
                    }
                    else {
                        Write-Output -InputObject $Item
                    }
                }
                'Warning' {
                    if ($Item -is [System.Management.Automation.WarningRecord]) {
                        $Item | & ($ScriptBlock)
                    }
                    else {
                        Write-Output -InputObject $Item
                    }
                }
                'Output' {
                    if ($Item -isnot [System.Management.Automation.DebugRecord] -and $Item -isnot [System.Management.Automation.ErrorRecord] -and $Item -isnot [System.Management.Automation.WarningRecord]) {
                        $Item | & ($ScriptBlock)
                    }
                    else {
                        Write-Output -InputObject $Item
                    }
                }
            }
        }
    }
}