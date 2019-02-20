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
		Write-Host "Create connection: $connectionString"
		$Global:SqlConnection = New-Object System.Data.SqlClient.SqlConnection
		$Global:SqlConnection.ConnectionString = $connectionString
		$Global:SqlConnection.Open()
	}


	if ($Global:SqlConnection.State.HasFlag([System.Data.ConnectionState]::Broken)) {
		Write-Host "Broken connection closed"
		$Global:SqlConnection.Close();
	}

	if (! $Global:SqlConnection.State.HasFlag([System.Data.ConnectionState]::Open)) {
		Write-Host "Reopen connection : $($Global:SqlConnection.ConnectionString)"
		$Global:SqlConnection.Open()
	}
}

function Set-Connection {
	[CmdletBinding()]
	param (
		[parameter(Position=0)] $server
	)

	DynamicParam
	{
		$Global:SqlConnection = $null

		# Generate and set the ValidateSet
		$ParameterName = 'database'

		$query = 'SELECT name from sys.databases'
		$arrSet = Read-Query $query -server $server -database 'master' | Select-Object -ExpandProperty Name

		$Global:SqlConnection = $null

		return Get-DinamicParam $ParameterName $arrSet 1;
	}

	begin
	{
		# Bind the parameter to a friendly variable
		$database = $PsBoundParameters[$ParameterName]
	}

	process
	{
		$connection = @{
			Server=$server;
			Database=$database
		}

		if (!(test-path '~\.sqlbuilder'))
		{
			New-Item -ItemType Directory '~\.sqlbuilder'
		}

		$connection | ConvertTo-Json | out-file '~\.sqlbuilder\connection'
	}
}

function Get-connection {
	get-content '~\.sqlbuilder\connection' -Raw | ConvertFrom-Json
}