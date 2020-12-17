<#
ExportMPs.ps1
    Version: 2.0    
    Release 2020/12/17

Script to export all Management Packs
 -Sealed = Export sealed and unsealed MP (default to unsealed only)
 -Servername = MS to use (default to localhost)
 -Folder = Folder to export MP to (default to C:\SCOMFiles\ManagementPacks)
#>
param 
(
    [String]$Sealed = $false,
    [String]$MSConnection,
    [String]$Folder = "C:\SCOMFiles\ManagementPacks"
)

# ===============================================================================================
# functions
function GetSCOMModule ($MgmtServer){

    $Server = $MgmtServer

    Try {
        $SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
        $SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory "OperationsManager"
        Import-module $SCOMModulePath -ErrorAction Stop
        New-DefaultManagementGroupConnection $Server -ErrorAction Stop
    }
    Catch {
        Write-Host "SCOM Console not installed or OperationsManager module not found" -ForegroundColor Red
        Write-Host "Try running script as local administrator or from OperationsManager shell session." -ForegroundColor Red
        Exit
    }
}

function ConnectToSDK ($MS) {

    $MgmtServer = $MS

    Try {
        New-DefaultManagementGroupConnection $MgmtServer -EA stop
    }    
    Catch {
        GetSCOMModule $MgmtServer
    }
}

function CheckMSConnect {
    # Check connection to Management Group
    $isConnected = Get-SCManagementGroupConnection
    If (!$isConnected){
        #  If not connected, connect to the required MS, or default to localhost
        If (!$MSConnection){
            ConnectToSDK "Localhost"
        }
        Else {
            ConnectToSDK $MSConnection
        }
    }
    Else {
        #  If already connected, use existing connection or change connection to the required MS
        If ((!$MSConnection) -or ($isConnected.ManagementServerName -eq $MSConnection)){
            $connected = $isConnected |? {$_.IsActive}
            # Check if the existing connection is active, if not, set it active.
            If ($connected.ManagementServerName -eq $MSConnection){
                Write-host "Connected to" $Connected.ManagementGroupName "on" $Connected.ManagementServerName -ForegroundColor Magenta
            }
            Else {
                $isConnected |? {$_.ManagementServerName -eq $MSConnection} |Set-SCManagementGroupConnection
                $connected = $isConnected |? {$_.IsActive}
                Write-host "Connected to" $Connected.ManagementGroupName "on" $Connected.ManagementServerName -ForegroundColor Magenta
            }
        }
        Else {
            ConnectToSDK $MSConnection
        }
    }
}
#---------------------------------------------------------------------
# MAIN

# CHeck for established connection to Management Server  
CheckMSConnect

# Default to only unsealed MP unless option to export Sealed MP is specified
if($Sealed.ToLower() -eq "true") {
    $GetAll = $True
}

# Specify location to store the exported MP in
$Date = Get-Date -Format “yyyy-MM-dd”
$TodaysFolder = $Folder + "\" + $Date

# Connect to Data Access Service to export MP
TRY {
    if($GetAll){
        $mps = get-SCOMmanagementpack 
        Write-Host "Exporting all management packs." -ForegroundColor Magenta
    }
    Else {
        $mps = get-SCOMmanagementpack | where-object {$_.Sealed -eq $false}
        Write-Host "Exporting only unsealed management packs." -ForegroundColor Magenta
    }
}
Catch {
    Write-Host "Cannot connect to Data Access Service on $ServerName." -ForegroundColor Red
}

# Clean up folder if it already exists
If(Test-Path $TodaysFolder) {
    Remove-item $TodaysFolder -Recurse -Force
}
New-Item $TodaysFolder -type directory -force |out-null

# Save each management pack to target folder
foreach ($mp in $mps) {
    export-SCOMManagementpack -managementpack $mp -path $TodaysFolder
}

Write-Host "Export complete." -ForegroundColor Green