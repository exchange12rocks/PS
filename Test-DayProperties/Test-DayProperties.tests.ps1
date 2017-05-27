. (Join-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Path) -ChildPath 'Test-DayProperties.ps1')

Describe -Name 'quarters' -Fixture {

    It -name "Months '<Months>' in a quarter '<Quarter>'" -TestCases @(
        @{Months = (1..3); Quarter = 1}
        @{Months = (4..6); Quarter = 2}
        @{Months = (7..9); Quarter = 3}
        @{Months = (10..12); Quarter = 4}
    ) -test {
        Param (
            [ValidateRange(1,12)]
            [int[]]$Months,
            [ValidateRange(1,4)]
            [int]$Quarter
        )

        foreach ($Month in $Months) {
            Test-DayProperties -Quarter $Quarter -Date (New-Object -TypeName DateTime -ArgumentList @((Get-Random -Minimum 1 -Maximum 9999), $Month, (Get-Random -Minimum 1 -Maximum 28))) |
            Should Be $true
        }
    }
}

Describe -Name 'edge cases' -Fixture {
    Context -Name 'The First Day' -Fixture {

        $TheFirstDay = New-Object -TypeName DateTime -ArgumentList @(1, 1, 1)

        It -name "The very first day is in the first quarter" -test {
            Test-DayProperties -Quarter 1 -Date $TheFirstDay |
            Should Be $true
        }

        It -name "The very first day is not in quarter #<Quarter>" -TestCases @(
            @{Quarter = 2}
            @{Quarter = 3}
            @{Quarter = 4}
        ) -test {
            Param (
                [ValidateRange(2,4)]
                [int]$Quarter
            )

            Test-DayProperties -Quarter $Quarter -Date $TheFirstDay |
            Should Be $false
        }

        It -name 'The very first day is the first Monday' -test { #http://www.academia.edu/1091577/What_day_of_the_week_was_01-01-0001 Gregorian calendar
            Test-DayProperties -Date $TheFirstDay -DayOfWeek 1 -NumberInMonth 1 |
            Should Be $true
        }

        It -name "The very first day is not the Monday # <Num>" -TestCases @(
            @{Num = 2},
            @{Num = 3},
            @{Num = 4},
            @{Num = 5}
        ) -test {
            param (
                [ValidateRange(2,5)]
                [int]$Num
            )

            Test-DayProperties -Date $TheFirstDay -DayOfWeek 1 -NumberInMonth $Num | Should Be $false
        }
    }

    Context -Name 'The Last Day' -Fixture {

        $TheLastDay = New-Object -TypeName DateTime -ArgumentList @(9999, 12, 31)

        It -name "The very last day is not in quarters '<Quarters>'" -TestCases @(
            @{Quarters = (1..3)}
        ) -test {
            Param (
                [ValidateRange(1,3)]
                [int[]]$Quarters
            )

            foreach ($Quarter in $Quarters) {
                Test-DayProperties -Quarter $Quarter -Date $TheLastDay |
                Should Be $false
            }
        }

        It -name "The very last day is in the quarter '<Quarter>'" -TestCases @(
            @{Quarter = 4}
        ) -test {
            Param (
                [ValidateSet(4)]
                [int]$Quarter
            )

            Test-DayProperties -Quarter $Quarter -Date $TheLastDay |
            Should Be $true
        }
    }

    Context -Name 'The First Week' -Fixture {
        It -name "Day #<Num> on the very first week is the first day of this type in the month" -TestCases @(
            @{Num = 1},
            @{Num = 2},
            @{Num = 3},
            @{Num = 4},
            @{Num = 5},
            @{Num = 6},
            @{Num = 7}
        ) -test {
            param (
                [ValidateRange(1,7)]
                [int]$Num
            )

            Test-DayProperties -Date (New-Object -TypeName DateTime -ArgumentList @(1, 1, $Num)) -DayOfWeek $Num -NumberInMonth 1 | Should Be $true
        }
    }

    Context -Name 'The Last Week' -Fixture {
        It -name "Day #<Num> on the very last week is the last day of this type in the month" -TestCases @(
            @{Num = 1; Date = 27},
            @{Num = 2; Date = 28},
            @{Num = 3; Date = 29},
            @{Num = 4; Date = 30},
            @{Num = 5; Date = 31},
            @{Num = 6; Date = 25},
            @{Num = 7; Date = 26}
        ) -test {
            param (
                [ValidateRange(1,7)]
                [int]$Num,
                [ValidateRange(25,31)]
                [int]$Date
            )

            Test-DayProperties -Date (New-Object -TypeName DateTime -ArgumentList @(9999, 12, $Date)) -DayOfWeek $Num -Last | Should Be $true
        }
    }
}