function Test-DayProperties {

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

<#
.SYNOPSIS
    Tests the given date against different conditions.

.DESCRIPTION
    The function helps you to detect if today is the third Tuesday in a month, if the date belongs to some quarter, if today is the last day of a month etc.

.PARAMETER Date
    The date object which you are testing. By default, the current date/time.

.PARAMETER DayOfWeek
    Use to test if the day is the defined day in a week (Mon - 1, Tue - 2, Wed - 3 etc).

.PARAMETER NumberInMonth
    Use to detect if the day is the specified number of the day type defined in the DayOfWeek parameter.

.PARAMETER EndOfMonth
    Use to detect if the given day is the last day of the month.

.PARAMETER Quarter
    Use to detect if the given day is belongs to the specified quarter.

.PARAMETER QuarterType
    Use to detect if the given day is the start or the end of the specified quarter.

.PARAMETER Last
    Use to detect if the given day is the last day of some kind in the given month. If the DayOfWeek parameter is omitted, the kind of day is extracted from the Date parameter, otherwise — DayOfWeek is used.

.EXAMPLE
    Test-DayProperties -DayOfWeek 2 -NumberInMonth 2
    Tests if the current day is the second Tuesday in this month.

.EXAMPLE
    Test-DayProperties -Date $Date -DayOfWeek 7 -Last
    Tests if the date in the $Date object is the last Sunday in the month.

.EXAMPLE
    Test-DayProperties -Last
    Tests if today is the last day of its kind in the month.

.EXAMPLE
    Test-DayProperties -EndOfMonth
    Tests if today is the last day of the month.

.EXAMPLE
    Test-DayProperties -Date $Date -Quarter 3 -QuarterType End
    Tests if the date in the $Date object is the end (the last day) of the 3rd quarter.

.EXAMPLE
    Test-DayProperties -QuarterType Start
    Tests if today is the beginning of a quarter.

.EXAMPLE
    Test-DayProperties $Date -Quarter 1
    Tests if the date in the $Date object belonngs to the 1st quarter.

.INPUTS
    [DateTime]

.OUTPUTS
    [boolean]

.NOTES
   Author: Kirill Nikolaev
   Twitter: @exchange12rocks

.LINK
    https://exchange12rocks.org/2017/05/29/function-to-test-a-date-against-different-conditions

.LINK
    https://github.com/exchange12rocks/PS/tree/master/Test-DayProperties

#>

#Requires -Version 3.0

    [CmdletBinding(
        DefaultParametersetName='Default'
    )]
    [OutputType([boolean])]
    Param (
        [Parameter(ParameterSetName='Default', Position = 0)]
        [Parameter(ParameterSetName='Quarter', Position = 0)]
        [Parameter(ParameterSetName='QuarterType', Position = 0)]
        [Parameter(ParameterSetName='EndOfMonth', Position = 0)]
        [Parameter(ParameterSetName='Last', Position = 0)]
        [ValidateNotNullorEmpty()]
        [DateTime]$Date = (Get-Date),

        [Parameter(ParameterSetName='Default', Mandatory)]
        [Parameter(ParameterSetName='Last')]
        [ValidateRange(1,7)]
        [int]$DayOfWeek,

        [Parameter(ParameterSetName='Default', Mandatory)]
        [ValidateRange(1,5)] # It's impossible to have more that 5 weeks in a month (on Earth)
        [int]$NumberInMonth,

        [Parameter(ParameterSetName='EndOfMonth')]
        [switch]$EndOfMonth,

        [Parameter(ParameterSetName='Quarter', Mandatory)]
        [Parameter(ParameterSetName='QuarterType')]
        [ValidateRange(1,4)]
        [int]$Quarter,

        [Parameter(ParameterSetName='QuarterType', Mandatory)]
        [ValidateSet('Start','End')]
        [string]$QuarterType,

        [Parameter(ParameterSetName='Last', Mandatory)]
        [switch]$Last

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

    function GetDotNETDayOfWeek {
        Param (
            [ValidateRange(1,7)]
            [int]$DayOfWeek
        )

        if ($DayOfWeek -eq 7) {
            return 0
        }
        else {
            return $DayOfWeek
        }
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
        'EndOfMonth' {
            if ($Date -eq (GetLastDateOfCurrentMonth -Date $Date)) {
                 $result = $true
            }
        }
        'Last' {
            $LastDateOfCurrentMonth = GetLastDateOfCurrentMonth -Date $Date
            $StartOfLast7Days = $LastDateOfCurrentMonth.AddDays(-6)
            if (!$DayOfWeek) {
                if ($Date -ge $StartOfLast7Days -and $Date -le $LastDateOfCurrentMonth) {
                    $result = $true
                }
            }
            elseif ($Date.DayOfWeek.value__ -eq (GetDotNETDayOfWeek -DayOfWeek $DayOfWeek) -and $Date -ge $StartOfLast7Days -and $Date -le $LastDateOfCurrentMonth) {
                $result = $true
            }
        }
        'Default' {
            $DaysToSubstract = (7*($NumberInMonth-1))
            if ((New-TimeSpan -Days $DaysToSubstract).Ticks -le $Date.Ticks) {
                if ($Date.DayOfWeek.value__ -eq (GetDotNETDayOfWeek -DayOfWeek $DayOfWeek) -and $Date.AddDays(-$DaysToSubstract).Month -eq $Date.Month -and $Date.Day -le (7*$NumberInMonth)) {
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