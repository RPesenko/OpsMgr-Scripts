<# 
.SYNOPSIS
This is a library of common functions for use in SCOM scripts
Version: 1.1 (2023/03/08)

.DESCRIPTION
Functions included in this script. Use get-help <functionName> for detailed information on usage and syntax.
    - Invoke-SQL : Run a SQL query against a database
    - Write-to-File: Write output to specified file (append. Create if needed.)
    - New-OutputFile: Create a new output file or overwrite an existing one.
    - Set-OutputFolder: Create destination folder for SCOM Reports
    - Set-OutputFile: Set the name for the output file
#>


function Invoke-SQL {
    param(
        # SQL instance to query (FQDN or Named Instance). Default valure is "Contoso.com"
        [string] $dataSource = "contoso.com", 
        # SQL database to query. Default value is "OperationsManager"
        [string] $database = "OperationsManager",
        # TSQL query to execute (required). Note: only t-sql query commands are permitted.
        [string] $sqlCommand = $(throw "Please specify a query.")
      )

    <#
    .SYNOPSIS
    Query a SQL database

    .DESCRIPTION
    Executes a T-SQL query against a database and returns a data table as a result set. 
    Initial connection to the SQL database is performed with SSPI security.

    .INPUTS
    A valid T-SQL query

    .OUTPUTS
    A .net data table with the results of the T-SQL query
    #>

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

Function Write-to-File {
    Param (
        # A string to append to a text file
        [String] $msg,
        # The text file to write to
        [String] $outfile
    )

    <#
    .SYNOPSIS
    Write output to a specified file.

    .DESCRIPTION
    This function takes a string and appends it to an existing text file.
    If the file does not exist, it will be created.
    #>
    add-Content -Value $msg -Path $outfile
}

Function New-Outputfile {
    param (
        # The text file to create.
        [String] $outfile
    )

    <#
    .SYNOPSIS
    Create new report file. Overwrite existing file if it already exists.

    .DESCRIPTION
    Create new report file. Overwrite existing file if it already exists.
    #>
    
    New-Item -ItemType File -Path $outfile -Force|Out-Null

}

Function Set-OutputFolder {
    param (
        # The top level folder where SCOM reports are stored. The default value is "C:\SCOMFiles"
        [String] $ReportRoot = "C:\SCOMFiles",
        # The subfolder for specific categories of SCOM reports. The default value is "Reports"
        [String] $FolderRoot = "Reports"
    )

    <#
    .SYNOPSIS
    This function creates the folder structure for SCOM reports.

    .DESCRIPTION
    This function validates the existence of the report folder structure used by SCOM reporting scripts. 
    If the destination folder for the SCOM report does not exist, or the root folder structure that destination folder resides in, 
    this function will create the folders.
    #>
    $ReportPath = "$ReportRoot\$FolderRoot"
    #Check for Report Root folder existence, if not, create it
    If (!(Test-Path $ReportRoot)){
        New-Item -ItemType directory -Path $ReportRoot |Out-Null
    }
    #Check for Folder Root existence, if not, create it
    If (!(Test-Path $ReportPath)){
        New-Item -ItemType directory -Path $ReportPath |Out-Null
    }
}

function Set-OutputFile {
    param (
        # This is the main root folder for all SCOM reports. Default valure is "C:\SCOMFiles".
        [String] $ReportRoot = "C:\SCOMFiles",
        # This is the subfolder for a specific category of SCOM reports. Default value is "Reports".
        [String] $FolderRoot = "Reports",
        # This is the base name for the report. Today's date will be appended to the base name.
        # The full report name will have the format: "$ReportRoot\$FolderRoot\$Reportfile-yyyy-MM-dd.Txt"
        [String] $Reportfile
    )
    
    <#
    .SYNOPSIS
    Specify the full path for the SCOM report file.

    .DESCRIPTION
    This function designates the full name for the report file, appended with today's date.
    The full report name will have the format: "$ReportRoot\$FolderRoot\$Reportfile-yyyy-MM-dd.Txt"

    .OUTPUTS
    The fully qualified path to the report file.
    #>

    $ReportDate = Get-Date -Format yyyy-MM-dd
    $ReportName = "$ReportRoot\$FolderRoot\$Reportfile-$ReportDate.Txt"

    Set-OutputFolder -ReportRoot $ReportRoot -FolderRoot $FolderRoot
    Return $ReportName
}
