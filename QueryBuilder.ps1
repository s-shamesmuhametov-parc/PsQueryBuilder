. $PSScriptRoot\Common.ps1
. $PSScriptRoot\Connection.ps1
. $PSScriptRoot\ExecuteQuery.ps1

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

function Fro
{
	[CmdletBinding()]
	param()
	DynamicParam
	{
		# Generate and set the ValidateSet
		$ParameterName = 'Table'

		$query = 'SELECT SCHEMA_NAME(schema_id) + ''.'' + name AS Name FROM sys.objects WHERE type = ''U'' ORDER BY SCHEMA_NAME(schema_id), name'
		$arrSet = Get-Result $query | Select-Object -ExpandProperty Name

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
		$Global:qbRoot = @($TableName)
		$Global:qbFrom = "FROM $TableName"

		BuildQuery | run
	}
}

function Sel
{
	[CmdletBinding()]
	param()
	DynamicParam
	{
		# Generate and set the ValidateSet
		$ParameterName = 'Column'
		$query = "SELECT source_table + '.' + name AS Name FROM sys.dm_exec_describe_first_result_set (N'SELECT * $Global:qbFrom', null, 1) "
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

function Where {
	[CmdletBinding()]
	param (
		[Parameter(Position = 0)]
		$expression
	)

	$Global:qbWhere = "WHERE $expression";

	BuildQuery | Run
}

function Join {
	[CmdletBinding()]
	param ()
	DynamicParam
	{
		# Generate and set the ValidateSet
		$ParameterName = 'Join'

		$query = @"
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
	WHERE
		KCU1.TABLE_SCHEMA + '.' + KCU1.TABLE_NAME IN('$([string]::Join(''', ''', $Global:qbRoot))')
	UNION ALL
	SELECT
		'JOIN [' + KCU1.TABLE_SCHEMA + '].[' + KCU1.TABLE_NAME + N'] ON [' + KCU1.TABLE_SCHEMA + '].[' + KCU1.TABLE_NAME + N'].[' + KCU1.COLUMN_NAME + N'] = [' + KCU2.TABLE_SCHEMA + '].[' + KCU2.TABLE_NAME + N'].[' + KCU2.COLUMN_NAME + N']' AS Name
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
	WHERE
		KCU2.TABLE_SCHEMA + '.' + KCU2.TABLE_NAME IN('$([string]::Join(''', ''', $Global:qbRoot))')

"@
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
		$Join -match 'JOIN \[(\w+)\].\[(\w+)\] ON'
		$Global:qbRoot += $Matches[1] + '.' + $Matches[2]
		$Global:qbFrom = "$Global:qbFrom $Join"

		BuildQuery | Run
	}
}