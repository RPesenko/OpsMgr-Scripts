<# script to export all MPs
 -Servername = MS to use (default to localhost)
 -Sealed = Export sealed and unsealed MP (default to unsealed only)
 -Folder = Folder to export MP to (default to C:\ManagementPacks)

 Version: 2020/03/23
#>
param 
(
    $ServerName,
    [String]$Sealed = $false,
    [String]$Folder = "C:\ManagementPacks"
)

# Default to Localhost if Management Server is not specified
if(!$ServerName) {
    $localserver = Get-Childitem env:computername |Select-Object value
    $ServerName = $localserver.value
}

# Default to only unsealed MP unless option to export Sealed MP is specified
if($Sealed.ToLower() -eq "true") {
    $GetAll = $True
}

# Specify location to store the exported MP in
$Date = Get-Date -Format “yyyy-MM-dd”
$TodaysFolder = $Folder + "\" + $Date

# Connect to Data Access Service to export MP
TRY {
    add-pssnapin “Microsoft.EnterpriseManagement.OperationsManager.Client”
    set-location “OperationsManagerMonitoring::” 
    new-managementGroupConnection -ConnectionString:$ServerName |out-null
    set-location $ServerName

    if($GetAll){
        $mps = get-SCOMmanagementpack 
    }
    Else {
        $mps = get-SCOMmanagementpack | where-object {$_.Sealed -eq $false}
    }

    # Clean up folder if it already exists
    If(Test-Path $TodaysFolder) {
        Remove-item $TodaysFolder -Recurse -Force
    }
    New-Item $TodaysFolder -type directory -force |out-null
    
    foreach ($mp in $mps) {
        export-SCOMManagementpack -managementpack $mp -path $TodaysFolder
    }
    Write-Host "Export complete." -ForegroundColor Green
}
Catch {
    Write-Host "Cannot connect to Data Access Service on $ServerName." -ForegroundColor Red
}
Set-location C:\