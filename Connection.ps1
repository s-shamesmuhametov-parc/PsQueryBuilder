function Open-Connection
{
	param
	(
		[Parameter(Mandatory=$true, Position=0)]
		[string]$server,

		[Parameter(Mandatory=$true, Position=1)]
		[string]$database
	)

	if ($null -eq $Global:SqlConnection -or $null -eq $Global:SqlConnection.ConnectionString) {
		$connectionString = "Server=$server;Database=$database;Integrated Security=True"
		$Global:SqlConnection = New-Object System.Data.SqlClient.SqlConnection
		$Global:SqlConnection.ConnectionString = $connectionString
		$Global:SqlConnection.Open()
	}


	if ($Global:SqlConnection.State.HasFlag([System.Data.ConnectionState]::Broken)) {
		$Global:SqlConnection.Close();
	}

	if (! $Global:SqlConnection.State.HasFlag([System.Data.ConnectionState]::Open)) {
		$Global:SqlConnection.Open()
	}
}

Register-ArgumentCompleter -CommandName Set-Connection -ParameterName Database -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)

	$Global:SqlConnection = $null

	Get-ArrayByQuery @"
		SELECT name from sys.databases
"@ | ForEach-Object {
			[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
		}

	$Global:SqlConnection = $null
}

function Set-Connection {
	[CmdletBinding()]
	param (
		[Parameter(Position=0)][string] $server,
		[Parameter(Position=1)][string] $database
	)

	$connection = @{
		Server=$server;
		Database=$database
	}

	if (!(Test-Path '~\.sqlbuilder'))
	{
		New-Item -ItemType Directory '~\.sqlbuilder'
	}

	$connection | ConvertTo-Json | Out-File '~\.sqlbuilder\connection'
}

function Get-Connection {
	Get-Content '~\.sqlbuilder\connection' -Raw | ConvertFrom-Json
}