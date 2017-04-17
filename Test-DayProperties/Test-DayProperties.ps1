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

function Test-DayProperties {

    [CmdletBinding(
        DefaultParametersetName='Default'
    )]
    [OutputType([boolean])]
    Param (
        [Parameter(ParameterSetName='Default', Position = 0)]
        [Parameter(ParameterSetName='Quarter', Position = 0)]
        [Parameter(ParameterSetName='QuarterType', Position = 0)]
        [ValidateNotNullorEmpty()]
        [DateTime]$Date = (Get-Date),

        [Parameter(ParameterSetName='Default')]
        [ValidateRange(1,7)]
        [int]$DayOfWeek,

        [Parameter(ParameterSetName='Default')]
        [ValidateRange(1,5)] # It's impossible to have more that 5 weeks in a month (on Earth)
        [int]$NumberInMonth,

        [Parameter(ParameterSetName='Default')]
        [switch]$EndOfMonth,

        [Parameter(ParameterSetName='Quarter', Mandatory)]
        [Parameter(ParameterSetName='QuarterType')]
        [ValidateRange(1,4)]
        [int]$Quarter,

        [Parameter(ParameterSetName='QuarterType', Mandatory)]
        [ValidateSet('Start','End')]
        [string]$QuarterType

    )

    $result = $false
       
    switch ($PSCmdlet.ParameterSetName) {
        'QuarterType' {
            if ($QuarterType -eq 'Start') {
                if ($Date.Day -eq 1 -and $Date.Month -in (1,4,7,10)) {
                    $result = $true
                    if ($Quarter) {
                        if ($Date.Month -ne (3*$Quarter-2)) {
                            $result = $false
                        }
                    }
                }
            }
            elseif ($QuarterType -eq 'End') {
                $LastDayOfCurrentMonth = (New-Object -TypeName DateTime -ArgumentList @($Date.Year, $Date.Month, 1)).AddMonths(1).AddTicks(-1).Day
                if (($Date.Month -in (3,6,9,12)) -and $Date.Day -eq $LastDayOfCurrentMonth) {
                    $result = $true
                }
            }
        }
        'Quarter' {
            if ($Date.Month -in ((3*$Quarter-2)..(3*$Quarter))) {
                $result = $true
            }
        }
        'Default' {
            if ($Date.DayOfWeek.value__ -eq $DayOfWeek -and $Date.AddDays(-(7*($NumberInMonth-1))).Month -eq $Date.Month -and $Date.Day -le (7*$NumberInMonth)) {
                $result = $true
            }
        }
        Default {
            $result = $false
        }
    }
    return $result
}