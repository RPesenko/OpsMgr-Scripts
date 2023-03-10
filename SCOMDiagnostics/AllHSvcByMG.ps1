<# 
.SYNOPSIS
Gets count of all HealthService instances from OperationsManager DB for each MG
Version 2.1

.Description
The script connects to the OperationsManager database and queries for count of all instances of HealthService and writes the output
to a file in the format: "$ReportRoot\$FolderRoot\$Reportfile-yyyy-MM-dd.Txt"
Hash table of Management Group to DB instance is hard coded in this version.
The script leverages the SCOM functions library v: 1.1
#>

Param(
    # Root folder for all reports
    # Default value [C:\SCOMFiles1]
    [string] $ReportRoot = "C:\SCOMFiles1", 
    # Folder for all reports from this script
    # Default value [AllReports]
    [string] $FolderRoot = "AllReports", 
    # Name for this report file (today's date will be automatically appended to the report name)
    # Default value [HealthService_Count] 
    [string] $Reportfile = "HealthService_Count" 
)
<# Script leverages SCOM functions library file 1.0 #>
. .\SCOMFunctions.ps1

# Create hash table of [MG name = SQL instance hosting OM DB]
$SCOMDBList = [Ordered]@{
"OM19MG" = "OM19SQL1.OM19.local"
}

# Create a new output file or overwrite existing one from today.
$outputfile = (Set-outputfile -ReportRoot $ReportRoot -FolderRoot $FolderRoot -Reportfile $Reportfile)
Write-Host "Writing output to $outputfile" -Foregroundcolor Yellow 
New-Outputfile $outputfile

# Calculate HealthServices for each MG and write to Host/File
foreach ($MG in $SCOMDBList.GetEnumerator()){
    $query = Invoke-SQL -dataSource $($MG.value) -sqlCommand "SELECT * FROM BaseManagedEntity where Fullname like '%healthservice:%'" 
    $output = "Management Group $($MG.name) has a count of {0:N0} healthservices" -f ($query |Measure-Object).count
    Write-Host $output -Foregroundcolor Yellow 
    Write-to-File $output $outputfile
}
