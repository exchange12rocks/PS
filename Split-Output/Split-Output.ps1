function Split-Output {

    <# MIT License

        Copyright (c) 2017 Kirill Nikolaev

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    #>

    #Requires -Version 3.0

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [System.Object[]]$InputObject,
        [Parameter(Mandatory, Position = 1)]
        [ScriptBlock]$ScriptBlock,
        [Parameter(Position = 2)]
        [ValidateSet('Debug', 'Error', 'Warning', 'Default', 'Custom')]
        [string]$Mode
    )
    DynamicParam {
        if ($Mode -eq 'Custom') {
            $FilterAttribute = New-Object -TypeName 'System.Management.Automation.ParameterAttribute'
            $FilterAttribute.Mandatory = $true
            $FilterAttribute.Position = 3
            $FilterAttributeCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection[System.Attribute]'
            $FilterAttributeCollection.Add($FilterAttribute)
            $FilterParameter = New-Object -TypeName 'System.Management.Automation.RuntimeDefinedParameter' -ArgumentList ('Filter', [ScriptBlock], $FilterAttribute)
            $FilterDictionary = New-Object -TypeName 'System.Management.Automation.RuntimeDefinedParameterDictionary'
            $FilterDictionary.Add('Filter', $FilterParameter)
            $FilterDictionary
        }
    }

    BEGIN {
        $ScriptBlock = [ScriptBlock]::Create('PROCESS {{$_ | {0}}}' -f $ScriptBlock.ToString())
        if ($PSBoundParameters.Filter) {
            $Filter = [ScriptBlock]::Create('PROCESS {{{0}}}' -f $PSBoundParameters.Filter.ToString())
        }
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
                        $Item | & $ScriptBlock
                    }
                    else {
                        Write-Output -InputObject $Item
                    }
                }
                'Warning' {
                    if ($Item -is [System.Management.Automation.WarningRecord]) {
                        $Item | & $ScriptBlock
                    }
                    else {
                        Write-Output -InputObject $Item
                    }
                }
                'Custom' {
                    if ($Item | & $Filter) {
                        $Item | & $ScriptBlock
                    }
                    else {
                        Write-Output -InputObject $Item
                    }
                }
                Default {
                    if ($Item -isnot [System.Management.Automation.DebugRecord] -and $Item -isnot [System.Management.Automation.ErrorRecord] -and $Item -isnot [System.Management.Automation.WarningRecord]) {
                        $Item | & $ScriptBlock
                    }
                    else {
                        Write-Output -InputObject $Item
                    }
                }
            }
        }
    }
}