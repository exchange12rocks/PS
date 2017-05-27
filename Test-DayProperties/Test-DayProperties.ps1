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
        [Parameter(ParameterSetName='Last')]
        [ValidateNotNullorEmpty()]
        [DateTime]$Date = (Get-Date),

        [Parameter(ParameterSetName='Default')]
        [Parameter(ParameterSetName='Last')]
        [ValidateRange(1,7)]
        [int]$DayOfWeek,

        [Parameter(ParameterSetName='Default')]
        [ValidateRange(1,5)] # It's impossible to have more that 5 weeks in a month (on Earth)
        [int]$NumberInMonth,

        [Parameter(ParameterSetName='Default')]
        [switch]$EndOfMonth,

        [Parameter(ParameterSetName='Last')]
        [switch]$Last,

        [Parameter(ParameterSetName='Quarter', Mandatory)]
        [Parameter(ParameterSetName='QuarterType')]
        [ValidateRange(1,4)]
        [int]$Quarter,

        [Parameter(ParameterSetName='QuarterType', Mandatory)]
        [ValidateSet('Start','End')]
        [string]$QuarterType

    )

    function GetLastDateOfCurrentMonth {

        Param (
            [ValidateNotNullorEmpty()]
            [DateTime]$Date = (Get-Date)
        )

        $result = $false

        if ($Date.Month -in @(1, 3, 5, 7, 8, 10, 12)) {
            $result = New-Object -TypeName DateTime -ArgumentList @($Date.Year, $Date.Month, 31)
        }
        elseif ($Date.Month -in @(4, 6, 9, 11)) {
            $result = New-Object -TypeName DateTime -ArgumentList @($Date.Year, $Date.Month, 30)
        }
        else { #February
            try {
                $result = New-Object -TypeName DateTime -ArgumentList @($Date.Year, $Date.Month, 29)
            }
            catch {
                if ($Error[0].Exception.InnerException.HResult -eq -2146233086) {
                    $result = New-Object -TypeName DateTime -ArgumentList @($Date.Year, $Date.Month, 28)
                }
            }
        }

        return $result
    }

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
                if (($Date.Month -in (3,6,9,12)) -and $Date.Day -eq ((GetLastDateOfCurrentMonth -Date $Date).Day)) {
                    $result = $true
                }
            }
        }
        'Quarter' {
            if ($Date.Month -in ((3*$Quarter-2)..(3*$Quarter))) {
                $result = $true
            }
        }
        'Last' {
            $LastDateOfCurrentMonth = GetLastDateOfCurrentMonth -Date $Date
            $StartOfLast7Days = $LastDateOfCurrentMonth.AddDays(-6)
            if ($DayOfWeek -eq 7) {
                if ($Date.DayOfWeek.value__ -eq 0 -and $Date -ge $StartOfLast7Days -and $Date -le $LastDateOfCurrentMonth) {
                    $result = $true
                }
            }
            elseif ($Date.DayOfWeek.value__ -eq $DayOfWeek -and $Date -ge $StartOfLast7Days -and $Date -le $LastDateOfCurrentMonth) {
                $result = $true
            }

        }
        'Default' {
            $DaysToSubstract = (7*($NumberInMonth-1))
            if ((New-TimeSpan -Days $DaysToSubstract).Ticks -le $Date.Ticks) {
                if ($DayOfWeek -eq 7) {
                    if ($Date.DayOfWeek.value__ -eq 0 -and $Date.AddDays(-$DaysToSubstract).Month -eq $Date.Month -and $Date.Day -le (7*$NumberInMonth)) {
                        $result = $true
                    }
                }
                elseif ($Date.DayOfWeek.value__ -eq $DayOfWeek -and $Date.AddDays(-$DaysToSubstract).Month -eq $Date.Month -and $Date.Day -le (7*$NumberInMonth)) {
                        $result = $true
                }
            }
        }
        Default {
            $result = $false
        }
    }
    return $result
}