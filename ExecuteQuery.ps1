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
	$reader = $SqlCmd.ExecuteReader()

	$dt = new-object System.Data.DataTable
	$dt.Load($reader)

	return $dt
}

function Run {
	param (
		[Parameter(Position = 0, ValueFromPipeline = $true)]
		$query = $Global:BuildQuery
	)

	$dt = get-result $query;
	if ( $dt.Table.Rows.Count -eq 0) {
		return Write-Host "`nnothing" -NoNewline;
	}
	$dt | Select-Object -Property * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | Format-Table * | Out-String | ForEach-Object {Write-Host $_}
}

function Get-Result {
	param (
		$query
	)

	$connection = get-connection

	Write-Host $query

	return Read-Query $query -server $connection.Server -database $connection.Database
}