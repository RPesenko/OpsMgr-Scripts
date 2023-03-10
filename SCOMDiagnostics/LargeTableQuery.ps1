<# Query DB of all MG for Large Tables 
   v 2.0 Last Update 01/24/2023
#>

$FileRoot = "C:\SCOMFiles\LargeTables"

# Define Connection Strings to SCOM DB
$SCOMDBList = [Ordered]@{
    "MG" = "Contoso.com"
}

# Function to query SQL DB 
function Invoke-SQL {
    param(
        [string] $dataSource, 
        [string] $database = "OperationsManager",
        [string] $sqlCommand = $(throw "Please specify a query.")
      )

    $connectionString = "Data Source=$dataSource; " +
            "Integrated Security=SSPI; " +
            "Initial Catalog=$database"

    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $connection.Open()
    
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null
    
    $connection.Close()
    $dataSet.Tables
}

# Define Windows Computer Query
$TableQuery = @"
SELECT OBJ.Name AS TABLES, IDX.Rows AS ROWS_COUNT
FROM sys.sysobjects AS OBJ
INNER JOIN sys.sysindexes AS IDX
ON OBJ.id = IDX.id
WHERE type = 'U'
AND IDX.IndId < 2 
AND IDX.rows > 1000
ORDER BY IDX.Rows DESC
"@

## Main ##
# Create output folder
$Repdate = Get-Date -Format yyyy_MM_dd
$RepFolder = "LgTable_$Repdate"
Set-Location $FileRoot
If (!(Test-Path $FileRoot\$RepFolder)){
    New-Item -ItemType directory -Path $FileRoot\$RepFolder
    Write-Host "Creating output folder $RepFolder in path $FileRoot" -ForegroundColor Yellow
}
Else {
    Write-host "Using Existing folder $RepFolder in path $FileRoot" -ForegroundColor Yellow
}

# Initialize Summary Page
$Summary = $null

# Loop through each MG and run query
foreach ($MG in $SCOMDBList.GetEnumerator()){
    Write-Host "Evaluating Management Group $($MG.name)" -ForegroundColor Cyan
    $LgTableQuery = $null
    $LgTableQuery = Invoke-SQL -dataSource $($MG.value) -sqlCommand $TableQuery 

    # Get total size
    $DBSize = $null
    foreach ($LgTableSize in $LgTableQuery) { $DBSize += $LgTableSize.ROWS_COUNT}

    # Create table query for 
    $LgTables = @()
    Foreach ($LgTable in $LgTableQuery) {
        $Table = New-Object PSObject -Property @{
            MG = $MG.Name
            Name = $LgTable.TABLES
            Rows = "{0:N0}" -f $($LgTable.ROWS_COUNT)
            Percent = "{0:P}" -f $($LgTable.ROWS_COUNT/$DBSize)
        }
        $LgTables += $Table
    }

    #Output raw data for each MG to file
    $LgTables|Select MG, Name, Rows, Percent |Export-Csv -NoTypeInformation -Path ".\$RepFolder\$($MG.Name)_TableSize.csv"

    # Add top ten results to Summary
    $Summary += $LgTables |Select MG, Name, Rows, Percent -First 10 |FT

}

$Summary |Out-File -FilePath ".\$RepFolder\TableSizeSummary_$($repdate).txt"
