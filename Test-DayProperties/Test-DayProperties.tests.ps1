$FunctionName = ($MyInvocation.MyCommand.Name).Substring(0,($MyInvocation.MyCommand.Name).Length-10)
. (Join-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Path) -ChildPath "$FunctionName.ps1")

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
            &($FunctionName) -Quarter $Quarter -Date (New-Object -TypeName DateTime -ArgumentList @((Get-Random -Minimum 1 -Maximum 9999), $Month, (Get-Random -Minimum 1 -Maximum 28))) |
            Should -Be $true
        }
    }
}

Describe -Name 'edge cases' -Fixture {
    Context -Name 'The First Day' -Fixture {

        $TheFirstDay = New-Object -TypeName DateTime -ArgumentList @(1, 1, 1)

        It -name "The very first day is in the first quarter" -test {
            &($FunctionName) -Quarter 1 -Date $TheFirstDay |
            Should -Be $true
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

            &($FunctionName) -Quarter $Quarter -Date $TheFirstDay |
            Should -Be $false
        }

        It -name 'The very first day is the first Monday' -test { #http://www.academia.edu/1091577/What_day_of_the_week_was_01-01-0001 Gregorian calendar
            &($FunctionName) -Date $TheFirstDay -DayOfWeek 1 -NumberInMonth 1 |
            Should -Be $true
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

            &($FunctionName) -Date $TheFirstDay -DayOfWeek 1 -NumberInMonth $Num | Should -Be $false
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
                &($FunctionName) -Quarter $Quarter -Date $TheLastDay |
                Should -Be $false
            }
        }

        It -name "The very last day is in the quarter '<Quarter>'" -TestCases @(
            @{Quarter = 4}
        ) -test {
            Param (
                [ValidateSet(4)]
                [int]$Quarter
            )

            &($FunctionName) -Quarter $Quarter -Date $TheLastDay |
            Should -Be $true
        }
        
        It -name 'The very last day is the end of month' -test {
            &($FunctionName) -Date $TheLastDay -EndOfMonth |
            Should -Be $true
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

            &($FunctionName) -Date (New-Object -TypeName DateTime -ArgumentList @(1, 1, $Num)) -DayOfWeek $Num -NumberInMonth 1 | Should -Be $true
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

            &($FunctionName) -Date (New-Object -TypeName DateTime -ArgumentList @(9999, 12, $Date)) -DayOfWeek $Num -Last | Should Be $true
        }
    }

    Context -Name 'Last of February' -Fixture {

        It -name '28th of February is the last of its kind in the month' -test {
            $Date = New-Object -TypeName DateTime -ArgumentList @((Get-Date).Year, 2, 28)
            if ($Date.DayOfWeek.value__ -eq 0) {
                $DayOfWeek = 7
            }
            else {
                $DayOfWeek = $Date.DayOfWeek.value__
            }
            &($FunctionName) -Date $Date -DayOfWeek $DayOfWeek -Last | Should -Be $true
        }

        It -name '29th of February is the last of its kind in the month' -test {
            &($FunctionName) -Date (New-Object -TypeName DateTime -ArgumentList @(2016, 2, 29)) -DayOfWeek 1 -Last | Should -Be $true
        }
        It -name '28th as the last day of February is the last of its kind in the month' -test {
            &($FunctionName) -Date (New-Object -TypeName DateTime -ArgumentList @(2017, 2, 28)) -DayOfWeek 2 -Last | Should -Be $true
        }

        It -name '29th of February is the last day of the month' -test {
            &($FunctionName) -Date (New-Object -TypeName DateTime -ArgumentList @(2016, 2, 29)) -EndOfMonth | Should -Be $true
        }
        It -name '28th as the last day of February is the last day of the month' -test {
            &($FunctionName) -Date (New-Object -TypeName DateTime -ArgumentList @(2017, 2, 28)) -EndOfMonth | Should -Be $true
        }

    }
}

Describe -Name 'Comment-based help' -Fixture { # http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-comment-based.html
    $Help = Get-Help -Name $FunctionName -Full
    $Notes = ($Help.alertSet.alert.text -split '\n')

    Context -Name ('{0} - Help' -f $FunctionName) -Fixture {
            
        It -name 'Synopsis' -test {
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
        It -name 'Description' -test {
            $help.Description | Should -Not -BeNullOrEmpty
        }
        It -name 'Notes - Author' -test {
            $Notes[0].trim() | Should -Be 'Author: Kirill Nikolaev'
        }
        It -name 'Notes - Twitter' -test {
            $Notes[1].trim() | Should -Be 'Twitter: @exchange12rocks'
        }
        It -name 'Notes - Web-site' -test {
            $Notes[2].trim() | Should -Be 'Web-site: https://exchange12rocks.org'
        }
        It -name 'Notes - GitHub' -test {
            $Notes[3].trim() | Should -Be 'GitHub: https://github.com/exchange12rocks'
        }

        # Get the parameters declared in the Comment Based Help
        $RiskMitigationParameters = 'Whatif', 'Confirm'
        $HelpParameters = $help.parameters.parameter | Where-Object name -NotIn $RiskMitigationParameters

        # Parse the function using AST
        $AST = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content function:$FunctionName), [ref]$null, [ref]$null)

        # Get the parameters declared in the AST PARAM() Block
        $ASTParameters = $AST.ParamBlock.Parameters.Name.variablepath.userpath

        It -name 'Parameter - Compare Count Help/AST' -test {
            $HelpParameters.name.count | Should -Be $ASTParameters.count
        }
            
        # Parameter Description
        If (-not [String]::IsNullOrEmpty($ASTParameters)) {
            # IF ASTParameters are found
            $HelpParameters | ForEach-Object {
                It -name ('Parameter {0} - Should contains description' -f $_.Name) -test {
                    $_.description | Should -Not -BeNullOrEmpty
                }
            }
        }
            
        # Examples
        It -name 'Example - Count should be greater than 0' -test {
            $Help.examples.example.count | Should -BeGreaterThan 0
        }
        
        # Every parameter set should be covered by at least one example, but since I do not see a better way to test it, let's just count the number of examples and compare it to the number of parameter sets.
        It -name 'Examples - At least one example per ParameterSet' -test {
            $Help.examples.example.count | Should -BeGreaterThan ($Help.syntax.syntaxItem.Count-1)
        }
        
        # Examples - Code ("code" is the first line of an example)
        foreach ($Example in $Help.examples.example) {
            It -name ('Example - Code on {0}' -f $Example.Title) {
                $Example.code | Should -Not -Be '' # There is no reason to leave the first row of an example blank
            }
        }

        # Examples - Remarks (small description that comes with the example)
        foreach ($Example in $Help.examples.example) {
            It -name ('Example - Remarks on {0}' -f $Example.Title) {
                if ($Example.remarks -is 'System.Array') {
                        $Example.remarks[0] | Should -Not -Be '' # Strangely, remarks section is usually an array of 5 elements where only the first one contains text
                }
                else {
                    $Example.remarks | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}