<#
BulkOveride.ps1
    Version: 1.0  
    Release 2020/12/27
Runs Get-SCOMEffectiveMonitoringConfiguration against an agent, or takes a previously generated CSV file, and presents all the currently enabled rules and monitors
 in a PowerShell Gridview object.  Enabled rules and monitors can be selected from the gridview and a single override MP can be generated to disable the selected workflows. 
#>

[CmdletBinding(DefaultParameterSetName = 'GetConfig')]
Param (
    [Parameter(Mandatory=$true,ParameterSetName='UseExisting',HelpMessage='Enter a configuration file to use.')][string] $ConfigFile,
    [Parameter(Mandatory=$true,ParameterSetName='GetConfig',HelpMessage='Enter an agent FQDN to use.')][string] $AgentFQDN,
    [Parameter(Mandatory=$true,ParameterSetName='UseExisting')]
    [Parameter(Mandatory=$true,ParameterSetName='GetConfig',HelpMessage='Enter the Override MP Display Name')][string] $MP,
    [Parameter(Mandatory=$true,ParameterSetName='UseExisting')]
    [Parameter(ParameterSetName='GetConfig',HelpMessage='Enter the FQDN of the MS to connect to.')][string] $MS,
    [Parameter(ParameterSetName='GetConfig')][string] $FolderPath = "C:\SCOMFiles\BulkOverride\"
)

# ===============================================================================================
# functions
function GetParentMP {
    param (
        [string] $type,
        [string] $ID
    )
    If ($type -eq 'rule'){
        $MPID = (Get-SCOMRule -Name $ID).ManagementPackName
        $parentMP = $MPHash.$MPID
    }
    Else {
        $parentMP = ((Get-SCOMMonitor -Name $ID).GetManagementPack()).DisplayName
    }
    Return $parentMP
}

function GetMPHash {
    # Make one call to the SDK for MP display names
    $MPTable = @{}
    $MPList = Get-SCOMManagementPack 
    Foreach ($MPitem in $MPList) {
        $MPTable.Add($MPitem.Name, $MPitem.DisplayName)
    }

    Return $MPTable
}

function GetWorkflowType {
    Param (
        [string] $type,
        [string] $alerts,
        [string] $ID,
        [string] $description
    )
    If ($type -eq 'rule'){
        If ($alerts -eq "true") {
            Return "Alert Rule"
        }
        Else {
            If (($description -like "*collect*")-or ($ID -like "*collect*")) {
                Return "Collection Rule"
            }
            Else {
                Return "Rule"
            }
        }
    } 
    # Must be monitor, specify type
    Else {
        Switch -Regex ($ID) {
            "AvailabilityState$" {Return "Rollup Monitor"}
            "ConfigurationState$" {Return "Rollup Monitor"}
            "PerformanceState$" {Return "Rollup Monitor"}
            "SecurityState$" {Return "Rollup Monitor"}
            "EntityState$" {Return "Rollup Monitor"}
            "Rollup$" {Return "Rollup Monitor"}
            "Aggregate" {Return "Aggregate Monitor"}
            "DependencyMonitor$" {Return "Dependency Monitor"}
            default {Return "Unit Monitor"}
        } 
    }
}

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

function verifymp ($MP){
    $OMP = Get-SCOMManagementPack -Displayname $MP
    If ($OMP){
        Write-Host "Writing overrides to" $OMP.DisplayName -ForegroundColor Cyan
        Return $OMP
    }
    Else {
        Write-Host "Cannot retrieve override management pack" -ForegroundColor Red
        Exit
    }
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
                Write-host "Connected to" $Connected.ManagementGroupName "on" $Connected.ManagementServerName -ForegroundColor Cyan
            }
            Else {
                $isConnected |? {$_.ManagementServerName -eq $MS} |Set-SCManagementGroupConnection
                $connected = $isConnected |? {$_.IsActive}
                Write-host "Connected to" $Connected.ManagementGroupName "on" $Connected.ManagementServerName -ForegroundColor Cyan
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

# Get the override MP
$overrideMp = verifymp $MP

# Populate has table of MP display names for efficiency
$MPHash = GetMPHash

# Don't connect to MS if just formatting an existing file
If ($ConfigFile) {
    $Hostname = (($ConfigFile.Split('.')[0]).Split('\'))[-1]
    $output = $ConfigFile
}
Else {
    # Generate Effective Configuration CSV
    # Wait 5 seconds for cmdlet to clean up before continuing.
    $Hostname = ($AgentFQDN.Split('.'))[0]
    $output = GetConfig $FolderPath $AgentFQDN
    Start-Sleep 5
}

# Get output of configuration CSV
Write-Host "Reading Configuration Information for $Hostname " -ForegroundColor Cyan
$lines = GetRawCSV $output

# Needed for Progress bar
$total = $lines.Count 
$i = 0

$Workflows = @()
$lines | foreach {
    # Progress bar
    $i += 1
    $progress = ($i/$total)*100
    Write-Progress -Activity "Loading Workflows" -PercentComplete $progress 

    $values = $null
    $values = ($_).Split('|')  

    # Skip lines that wrapped from previous monitor description and workflows that are disabled
    # Otherwise, get workflow configuration
    If (($values[0] -match '\w\.\w') -and ($values[3] -ne $false)) {
        $workflow = [PSCustomObject]@{
            Class = $values[0]
            Instance = $values[1]
            WorkflowID = $values[2]
            Enabled = $values[3]
            MakesAlert =  $values[4]
            AlertSev = $values[5]
            AlertPri = $values[6]
            Type = $values[7]
            WorkflowType = (GetWorkflowType $values[7] $values[4] $values[2] $values[8] )
            ParentMP = (GetParentMP $values[7] $values[2])
            Description = $values[8]
            Overridden = $values[9]
        }
        $Workflows += $workflow
    }
}
# CLose progress bar
Write-Progress -Activity "Loading Workflows" -Completed

# Present Enabled workflow information and select workflows to disable
$selected = $Workflows | ? {$_.WorkflowType -ne "Rollup Monitor"} |Select Class, Instance, WorkflowID, WorkflowType, MakesAlert, parentMP |Out-GridView -OutputMode Multiple

# Override the rules
$colRules = $Workflows | ? {$_.WorkflowID -in $selected.WorkflowID} | ? {$_.Type -eq "Rule"}
$ovRules = $colRules.Count
If ($ovRules -gt 0){
    Write-Host "Creating overrides for $ovRules rules...." -ForegroundColor Cyan
    foreach ($ruleitem in $colRules){
        $rule = Get-SCOMRule -Name $ruleitem.WorkflowID
        Write-Host "Creating rule override for " $rule.DisplayName -ForegroundColor Yellow
        $Target= Get-SCOMClass -id $rule.Target.id
        $overridename=$rule.Name + ".Override"
        $override = New-Object Microsoft.EnterpriseManagement.Configuration.Management`PackRulePropertyOverride($overrideMp,$overridename)
        $override.Rule = $rule
        $Override.Property = 'Enabled'
        $override.Value = 'false'
        $override.Context = $Target
        $override.DisplayName = $overridename   
    }
    Write-Host "Rule overrides complete" -ForegroundColor Green
}

# Override the Monitors
$colMonitors = $Workflows | ? {$_.WorkflowID -in $selected.WorkflowID} | ? {$_.Type -eq "Monitor"} 
$ovMon = $colMonitors.Count
If ($ovMon -gt 0){
    Write-Host "Creating overrides for $ovMon monitors...." -ForegroundColor Cyan
    foreach ($monitoritem in $colMonitors){
        $monitor = Get-SCOMMonitor -Name $monitoritem.WorkflowID
        Write-Host "Creating monitor override for" $monitor.DisplayName -ForegroundColor Yellow
        $Target= Get-SCOMClass -id $Monitor.Target.id
        $overridename=$monitor.Name + ".Override"
        $override = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorPropertyOverride($overrideMp,$overridename)
        $override.Monitor = $Monitor
        $Override.Property = 'Enabled'
        $override.Value = 'false'
        $override.Context = $Target
        $override.DisplayName = $overridename 
    }
    Write-Host "Monitor overrides complete" -ForegroundColor Green
}

# Save overrides to MP
Try {
    $overrideMp.Verify()
    $overrideMp.AcceptChanges()
    Write-Host "Override Management Pack imported" -ForegroundColor Green
}
Catch {
    Write-Host "Management Pack Import error" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
