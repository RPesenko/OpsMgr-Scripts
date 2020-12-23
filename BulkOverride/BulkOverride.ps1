<#
BulkOveride.ps1
    Version: 1.0    
    Release 2020/12/23
Runs Get-SCOMEffectiveMonitoringConfiguration against an agent, or takes a previously generated CSV file, and presents all the currently enabled rules and monitors
 in a PowerShell Gridview object.  Enabled rules and monitors can be selected from the gridview and a single override MP can be generated to disable the selected workflows. 
#>

Param (
    [Parameter(ParameterSetName='UseExisting')][string] $ConfigFile,
    [Parameter(Mandatory=$true,ParameterSetName='GetConfig')][string] $AgentFQDN,
    [Parameter(ParameterSetName='GetConfig')][string] $MS,
    [Parameter(ParameterSetName='GetConfig')][string] $FolderPath = "C:\SCOMFiles\BulkOverride\"
)

# ===============================================================================================
# functions
function GetRawCSV {
    param (
        $FileName 
    )
    
    Try {
        $RawCSV = Get-Content $FileName -ErrorAction stop|sort |select -Skip 1 
    }
    Catch {
        Write-Host "Error getting configuration output" -ForegroundColor Red
        Write-host $_.Exception.Message -ForegroundColor Red
        Exit
    }

    return $RawCSV
}

function GetConfig ($FolderPath, $AgentFQDN) {

    If ($null -ne $AgentFQDN){
        $Hostname = ($AgentFQDN.Split('.'))[0]
        $outfile = $FolderPath + $Hostname + ".csv"
        
        # Create output folder
        If (!(Test-Path -Path $FolderPath)) {
            New-Item $FolderPath -Type Directory
            Write-host "Creating folder $FolderPath for output" -ForegroundColor cyan  
        }
    
        # Get config
        Write-Host "Generating Configuration Information for $Hostname " -ForegroundColor Cyan
        Write-Host "  (this may take a few minutes...) " -ForegroundColor Cyan
        $SCOMclass = Get-SCOMClass -Name "System.Computer"
        $agent = Get-SCOMClassInstance -Class $SCOMclass | Where-Object {$_.DisplayName -eq $AgentFQDN}
        if ($agent){
            Export-SCOMEffectiveMonitoringConfiguration -Instance $agent -Path $outfile -RecurseContainedObjects 
        }
    }
    return $outfile
}

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
        If (!$MS){
            ConnectToSDK "Localhost"
        }
        Else {
            ConnectToSDK $MS
        }
    }
    Else {
        #  If already connected, use existing connection or change connection to the required MS
        If ((!$MS) -or ($isConnected.ManagementServerName -eq $MS)){
            $connected = $isConnected |? {$_.IsActive}
            # Check if the existing connection is active, if not, set it active.
            If ($connected.ManagementServerName -eq $MS){
                Write-host "Connected to" $Connected.ManagementGroupName "on" $Connected.ManagementServerName -ForegroundColor Magenta
            }
            Else {
                $isConnected |? {$_.ManagementServerName -eq $MS} |Set-SCManagementGroupConnection
                $connected = $isConnected |? {$_.IsActive}
                Write-host "Connected to" $Connected.ManagementGroupName "on" $Connected.ManagementServerName -ForegroundColor Magenta
            }
        }
        Else {
            ConnectToSDK $MS
        }
    }
}

#---------------------------------------------------------------------
# MAIN
# Check for established connection to Management Server  
    CheckMSConnect
    
# Don't connect to MS if just formatting an existing file
If ($ConfigFile) {
    $Hostname = (($ConfigFile.Split('.')[0]).Split('\'))[-1]
    $output = $ConfigFile
}
Else {
    #Generate Effective Configuration CSV
    $Hostname = ($AgentFQDN.Split('.'))[0]
    $output = GetConfig $FolderPath $AgentFQDN
}

# Get output of configuration CSV
Write-Host "Formatting Configuration Information for $Hostname " -ForegroundColor Cyan
$lines = GetRawCSV $output
$total = $lines.Count