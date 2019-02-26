# Set-StrictMode -Version Latest

. $PSScriptRoot\Common.ps1
. $PSScriptRoot\Connection.ps1
. $PSScriptRoot\ExecuteQuery.ps1

function BuildQuery {
	if ($null -eq $Global:qbSelect)
	{
		$query = "SELECT TOP 50 *"
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

	if ($null -ne $Global:qbOrder)
	{
		$query = "$query $Global:qbOrder"
	}

	Write-Output $query;
}

Register-ArgumentCompleter -CommandName Fro -ParameterName Table -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)

	Get-ArrayByQuery @"
		SELECT SCHEMA_NAME(schema_id) + '.' + name AS Name
		FROM sys.all_objects
		WHERE 1=1
			AND type not in (''TR'', ''UK'', ''C'', ''D'', ''F'', ''PK'', ''UQ'')
			AND (SCHEMA_NAME(schema_id) + '.' + name) LIKE N'%$cursorPosition%' ORDER BY SCHEMA_NAME(schema_id), name
		ORDER BY SCHEMA_NAME(schema_id)
"@ | ForEach-Object {
			[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
		}
}

function Fro
{
	[CmdletBinding()]

	param(
		[string]$Table
	)

	$Global:qbSelect = $null
	$Global:qbWhere = $null
	$Global:qbOrder = $null
	$Global:qbRoot = @($Table)
	$Global:qbFrom = "FROM $Table"

	BuildQuery | run
}

Register-ArgumentCompleter -CommandName Sel -ParameterName ColumnName -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)

	Get-ArrayByQuery @"
		SELECT ISNULL(source_table + '.', '') + name AS Name
		FROM sys.dm_exec_describe_first_result_set (N'SELECT * $Global:qbFrom', null, 1)
		WHERE (source_table + '.' + name) LIKE N'%$cursorPosition%'
"@ | ForEach-Object {
			[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
		}
}

function Sel
{
	[CmdletBinding()]
	param(
		[string]$ColumnName
	)

	if ($null -eq $Global:qbSelect) {
		$Global:qbSelect = "SELECT TOP 50 $ColumnName"
	}else {
		$Global:qbSelect = $Global:qbSelect + ", $ColumnName"
	}

	BuildQuery | run
}

function Wher {
	[CmdletBinding()]
	param (
		[Parameter(Position = 0)]
		$expression
	)

	$Global:qbWhere = "WHERE $expression";

	BuildQuery | Run
}

Register-ArgumentCompleter -CommandName OrderBy -ParameterName Column -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)

	Get-ArrayByQuery @"
		SELECT source_table + '.' + name AS Name
		FROM sys.dm_exec_describe_first_result_set (N'SELECT * $Global:qbFrom', null, 1)
		WHERE (source_table + '.' + name) LIKE N'%$cursorPosition%'
"@ | ForEach-Object {
			[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
		}
}

function OrderBy {
	[CmdletBinding()]
	param ()
	DynamicParam
	{
		$ParameterColumn = 'Column'
		$ParameterDesc = 'Desc'

		$arrSet = Get-ArrayByQuery "SELECT source_table + '.' + name AS Name FROM sys.dm_exec_describe_first_result_set (N'SELECT * $Global:qbFrom', null, 1) "

		$parameters = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
		$parameters.Add($ParameterColumn, (Get-StringAutocomletionParam $ParameterColumn $arrSet 0));
		$parameters.Add($ParameterDesc, (Get-SwitchParam $ParameterDesc 1));

		return $parameters;
	}

	process
	{
		$Global:qbOrder = "ORDER BY $($PsBoundParameters[$ParameterColumn])";

		if ($PsBoundParameters[$ParameterDesc]) {
			$Global:qbOrder += ' DESC'
		}

		BuildQuery | Run
	}
}

function Join {
	[CmdletBinding()]
	param ()
	DynamicParam
	{
		# Generate and set the ValidateSet
		$ParameterName = 'Join'

		$arrSet = Get-ArrayByQuery @"
	SELECT
		'[' + KCU2.TABLE_SCHEMA + '].[' + KCU2.TABLE_NAME + N'] ON [' + KCU2.TABLE_SCHEMA + '].[' + KCU2.TABLE_NAME + N'].[' + KCU2.COLUMN_NAME + N'] = [' + KCU1.TABLE_SCHEMA + '].[' + KCU1.TABLE_NAME + N'].[' + KCU1.COLUMN_NAME + N']' AS Name
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
		'[' + KCU1.TABLE_SCHEMA + '].[' + KCU1.TABLE_NAME + N'] ON [' + KCU1.TABLE_SCHEMA + '].[' + KCU1.TABLE_NAME + N'].[' + KCU1.COLUMN_NAME + N'] = [' + KCU2.TABLE_SCHEMA + '].[' + KCU2.TABLE_NAME + N'].[' + KCU2.COLUMN_NAME + N']' AS Name
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

		return Get-DinamicParam $ParameterName $arrSet 0;
	}

	begin
	{
		# Bind the parameter to a friendly variable
		$Join = $PsBoundParameters[$ParameterName]
	}

	process
	{
		$Join -match '\[(\w+)\].\[(\w+)\] ON'
		$Global:qbRoot += $Matches[1] + '.' + $Matches[2]
		$Global:qbFrom = "$Global:qbFrom LEFT JOIN $Join"

		BuildQuery | Run
	}
}