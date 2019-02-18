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
		$query = $Global:BuildQuery
	)

	$dt = get-result $query;
	if ( $dt.Table.Rows.Count -eq 0) {
		return Write-Host "`nnothing" -NoNewline;
	}
	$dt | Format-Table | Out-String | ForEach-Object {Write-Host $_}
}

function get-result {
	param (
		$query
	)

	$connection = get-connection

	return Read-Query $query -server $connection.Server -database $connection.Database
}

function get-connection {
	get-content '~\.sqlbuilder\connection' -Raw | ConvertFrom-Json
}

Set-PSReadlineKeyHandler -ScriptBlock { "`n" + $Global:BuildQuery | Write-Host -NoNewline } -Chord 'F4'
Set-PSReadlineKeyHandler -ScriptBlock {run} -Chord 'F5'
