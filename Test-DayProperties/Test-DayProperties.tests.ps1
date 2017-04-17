Describe -Name 'Test Quarter' -Fixture {

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

Describe -Name 'Edge Cases' -Fixture {
    Context -Name 'The First Day' -Fixture {

        $TheFirstDay = New-Object -TypeName DateTime -ArgumentList @(1, 1, 1)

        It -name "The very first day is in the quarter '<Quarter>'" -TestCases @(
            @{Quarter = 1}
        ) -test {
            Param (
                [ValidateSet(1)]
                [int]$Quarter
            )

            Test-DayProperties -Quarter $Quarter -Date $TheFirstDay |
            Should Be $true
        }

        It -name "The very first day is not in quarters '<Quarters>'" -TestCases @(
            @{Quarters = (2..4)}
        ) -test {
            Param (
                [ValidateRange(2,4)]
                [int[]]$Quarters
            )

            foreach ($Quarter in $Quarters) {
                Test-DayProperties -Quarter $Quarter -Date $TheFirstDay |
                Should Be $false
            }
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
}