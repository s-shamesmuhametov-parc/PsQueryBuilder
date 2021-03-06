function Read-Query
{
	param
	(
		[Parameter(Mandatory=$true, Position = 0)]
		[string]$Query,

		[Parameter(Mandatory=$true)]
		[string]$server,

		[Parameter(Mandatory=$true)]
		[string]$database
	)

	Open-Connection $server $database

	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.CommandText = $Query
	$SqlCmd.Connection = $Global:SqlConnection
	try {
		$reader = $SqlCmd.ExecuteReader()
	}
	catch {
		Write-Error "$($_.Exception.Message). Query $Query"
	}

	$dt = new-object System.Data.DataTable
	$dt.Load($reader)

	return $dt
}

function Run {
	param (
		[Parameter(Position = 0, ValueFromPipeline = $true)]
		$query
	)

	$dt = get-result $query;
	if ( @($dt).Count -eq 0) {
		return Write-Host "`nnothing" -NoNewline;
	}
	$dt `
		| Select-Object -Property * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors `
		| Format-Table * `
		| Out-String `
		| ForEach-Object {Write-Host $_}
}

function Get-Result {
	param (
		$query
	)

	$connection = Get-Connection

	return Read-Query $query -server $connection.Server -database $connection.Database
}

function Get-ArrayByQuery{
	param (
		$query
	)
	Get-Result $query | Select-Object -ExpandProperty Name
}
