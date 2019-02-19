function Read-Query
{
	param (
		[Parameter(Mandatory=$true, Position = 0)]
		[string]$Query,

		[Parameter(Mandatory=$true)]
		[string]$server,

		[Parameter(Mandatory=$true)]
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

	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.CommandText = $Query
	$SqlCmd.Connection = $Global:SqlConnection
	$reader = $SqlCmd.ExecuteReader()

	$dt = new-object System.Data.DataTable
	$dt.Load($reader)

	return $dt
}

function OpenConnection {

	if ($null -eq $Global:SqlConnection -or $null -eq $Global:SqlConnection.ConnectionString) {
		Write-Host "Create connection with string ${Server=$server;Database=$database;Integrated Security=True}"
		$Global:SqlConnection = New-Object System.Data.SqlClient.SqlConnection
		$Global:SqlConnection.ConnectionString = "Server=$server;Database=$database;Integrated Security=True"
	}


	if ($Global:SqlConnection.State.HasFlag([System.Data.ConnectionState]::Broken)) {
		Write-Host "Broken connection closed"
		$Global:SqlConnection.Close();
	}

	if (! $Global:SqlConnection.State.HasFlag([System.Data.ConnectionState]::Open)) {
		Write-Host "Reopen connection : ${$Global:SqlConnection.ConnectionString}"
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

function fr {
	[CmdletBinding()]
	param (
		[Parameter(Position = 1)]
		[ValidateSet('SELECT TOP 200 *', 'SELECT COUNT(1) AS ItemCount')]
		$sel = 'SELECT TOP 200 *'
	)

	DynamicParam
	{
		# Generate and set the ValidateSet
		$ParameterName = 'Table'

		$query = 'SELECT SCHEMA_NAME(schema_id) + ''.'' + name AS Name FROM sys.objects WHERE type = ''U'' ORDER BY SCHEMA_NAME(schema_id), name'
		$arrSet = get-result $query | Select-Object -ExpandProperty Name

		return Get-DinamicParam $ParameterName $arrSet 0;
	}

	begin
	{
		# Bind the parameter to a friendly variable
		$TableName = $PsBoundParameters[$ParameterName]
	}

	process
	{
		$Global:BuildQuery = "$sel FROM $TableName"
		$Global:BuildQuery
	}
}

function Get-DinamicParam {
	param (
		$ParameterName,
		$arrSet,
		$position = 0
	)
				# Create the dictionary
				$RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

				# Create the collection of attributes
				$AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

				# Create and set the parameters' attributes
				$ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
				$ParameterAttribute.Mandatory = $true
				$ParameterAttribute.Position = $position

				# Add the attributes to the attributes collection
				$AttributeCollection.Add($ParameterAttribute)

				$ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

				# Add the ValidateSet to the attributes collection
				$AttributeCollection.Add($ValidateSetAttribute)

				# Create and return the dynamic parameter
				$RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
				$RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
				return $RuntimeParameterDictionary
}

function run {
	param (
		[Parameter(Position = 0, ValueFromPipeline = $true)]
		$query = $Global:BuildQuery
	)

	$dt = get-result $query;
	if ( $dt.Table.Rows.Count -eq 0) {
		return Write-Host "`nnothing" -NoNewline;
	}
	$dt | Select-Object -Property * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | Format-Table * -Wrap | Out-String | ForEach-Object {Write-Host $_}
}

function get-result {
	param (
		$query
	)

	$connection = get-connection

	Write-Host $query

	return Read-Query $query -server $connection.Server -database $connection.Database
}

function get-connection {
	get-content '~\.sqlbuilder\connection' -Raw | ConvertFrom-Json
}

Set-PSReadlineKeyHandler -ScriptBlock { "`n" + $Global:BuildQuery | Write-Host -NoNewline } -Chord 'F4'
Set-PSReadlineKeyHandler -ScriptBlock {run} -Chord 'F5'

function fro
{
	[CmdletBinding()]
	param()
	DynamicParam
	{
		# Generate and set the ValidateSet
		$ParameterName = 'Table'

		$query = 'SELECT SCHEMA_NAME(schema_id) + ''.'' + name AS Name FROM sys.objects WHERE type = ''U'' ORDER BY SCHEMA_NAME(schema_id), name'
		$arrSet = get-result $query | Select-Object -ExpandProperty Name

		return Get-DinamicParam $ParameterName $arrSet 0;
	}

	begin
	{
		# Bind the parameter to a friendly variable
		$TableName = $PsBoundParameters[$ParameterName]
	}

	process
	{
		$Global:qbSelect = $null
		$Global:qbWhere = $null
		$Global:qbFrom = "FROM $TableName"

		BuildQuery | run
	}
}

function sel
{
	[CmdletBinding()]
	param()
	DynamicParam
	{
		# Generate and set the ValidateSet
		$ParameterName = 'Column'

		$query = "SELECT name FROM sys.dm_exec_describe_first_result_set (N'SELECT * $Global:qbFrom', null, 0) "
		$arrSet = get-result $query | Select-Object -ExpandProperty Name

		return Get-DinamicParam $ParameterName $arrSet 0;
	}

	begin
	{
		# Bind the parameter to a friendly variable
		$ColumnName = $PsBoundParameters[$ParameterName]
	}

	process
	{
		if ($null -eq $Global:qbSelect) {
			$Global:qbSelect = "SELECT $ColumnName"
		}else {
			$Global:qbSelect = $Global:qbSelect + ", $ColumnName"
		}

		BuildQuery | run
	}
}

function BuildQuery {
	if ($null -eq $Global:qbSelect)
	{
		$query = "SELECT TOP 100 *"
	}
	else
	{
		$query = $Global:qbSelect
	}

	$query = "$query $Global:qbFrom"

	if ($null -ne $Global:qbWhere)
	{
		$query = "$query $Global:qbWhere"
	}

	Write-Output $query;
}

function whe {
	[CmdletBinding()]
	param (
		[Parameter(Position = 0)]
		$expression
	)

	$Global:qbWhere = "WHERE $expression";

	BuildQuery | run
}

function join {
	[CmdletBinding()]
	param ()
	DynamicParam
	{
		# Generate and set the ValidateSet
		$ParameterName = 'Join'

		$query = @'
		SELECT
		'JOIN [' + KCU2.TABLE_SCHEMA + '].[' + KCU2.TABLE_NAME + N'] ON [' + KCU2.TABLE_SCHEMA + '].[' + KCU2.TABLE_NAME + N'].[' + KCU2.COLUMN_NAME + N'] = [' + KCU1.TABLE_SCHEMA + '].[' + KCU1.TABLE_NAME + N'].[' + KCU1.COLUMN_NAME + N']' AS Name
	FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS AS RC
	INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KCU1
		ON KCU1.CONSTRAINT_CATALOG = RC.CONSTRAINT_CATALOG
		AND KCU1.CONSTRAINT_SCHEMA = RC.CONSTRAINT_SCHEMA
		AND KCU1.CONSTRAINT_NAME = RC.CONSTRAINT_NAME
	INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KCU2
		ON KCU2.CONSTRAINT_CATALOG = RC.UNIQUE_CONSTRAINT_CATALOG
		AND KCU2.CONSTRAINT_SCHEMA = RC.UNIQUE_CONSTRAINT_SCHEMA
		AND KCU2.CONSTRAINT_NAME = RC.UNIQUE_CONSTRAINT_NAME
		AND KCU2.ORDINAL_POSITION = KCU1.ORDINAL_POSITION
	WHERE KCU1.TABLE_SCHEMA + '.' + KCU1.TABLE_NAME  = 'CaseMap.Projects'
'@
		$arrSet = get-result $query | Select-Object -ExpandProperty Name

		return Get-DinamicParam $ParameterName $arrSet 0;
	}

	begin
	{
		# Bind the parameter to a friendly variable
		$Join = $PsBoundParameters[$ParameterName]
	}

	process
	{
		# $Global:qbSelect = $null
		# $Global:qbWhere = $null
		$Global:qbFrom = "$Global:qbFrom $Join"

		BuildQuery | run
	}
}