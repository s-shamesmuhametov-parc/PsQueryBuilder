# PsQueryBuilder
Install
--
1. Download to profile folder PsQueryBuilder
2. Add to profile
```Powershell
. $PSScriptRoot\PsQueryBuilder\QueryBuilder.ps1
```

Examples
--
```Powershell
# 1. Connection to database
Set-Connection '(localdb)\MSSQLLocalDB' TestDatabase <# parameter with tab autocompletion #>

# 2. Select all columns from table
Fro dbo.TestTable <# parameter with tab autocompletion #>

# 3. Set first column to select expression
Sel TestTable.TestColumn <# parameter with tab autocompletion #>

# 4. Join table to current table
join '[dbo].[TestTable2] ON [dbo].[TestTable2].[Id] = [dbo].[TestTable].[TestTable2Id]' <# parameter with tab autocompletion #>

# 5. Add column to select expression from joined table
Sel TestTable2.TestColumn <# parameter with tab autocompletion #>

# 6. Add sorting by column
OrderBy dbo.TestTable -Desc <# parameter with tab autocompletion #>

# 7. Run custom query
run 'SELECT COUNT(1) FROM dbo.TestTable'
```
