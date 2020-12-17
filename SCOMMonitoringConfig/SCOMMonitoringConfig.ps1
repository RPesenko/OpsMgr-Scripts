<#
SCOMMonitoringConfig
    Version: 2.3    
    Release 2020/12/17
Runs Get-SCOMEffectiveMonitoringConfiguration and formats output to HTML 5 compliant file.
#>

  Param (
    [Parameter(ParameterSetName='FormatOnly')][string] $FormatFile,
    [Parameter(Mandatory=$true,ParameterSetName='GetConfig')][string] $AgentFQDN,
    [Parameter(ParameterSetName='GetConfig')][string] $MS,
    [Parameter(ParameterSetName='GetConfig')][string] $FolderPath = "C:\SCOMFiles\ScomConfig\"
)

# ===============================================================================================
# Global Variables
$body = $null
$previnst=$null

# CSS Header format (HTML 5 compliant)
$CSSHead = "<style> `
    BODY{background-color:#EEEEEE;font-family:Calibri,sans-serif;}`
    TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;font-size: medium;width: 85%}`
    TH{border-width: 1px;border-style: solid;border-color: black;background-color:#5070C8;color:white;padding: 5px; font-weight: bold;text-align:left;}`
    TD{border-width: 1px;border-style: solid;border-color: black;background-color:#F8F8F8; padding: 2px;text-align:left;vertical-align:top;}`
    TD.grey{background-color:rgba(210,210,210,0.7);}`
    TD.green{background-color:rgba(200, 250, 200,0.7);}`
    TD.yellow{background-color:rgba(255,255,0,0.7);}`
    .collapsible{background-color: #5070C8;color: #eeeeee;cursor: pointer;padding: 10px;width: 85%;border: 3px;text-align: left;border-color: #222222;font-size: 15px;}`
    .active, .collapsible:hover {background-color: #6080e8;}`
    .content {padding: 0 18px;background-color: white;max-height: 0;overflow: hidden;transition: max-height 0.2s ease-out;}`
    .collapsible:after {content: '\02795';font-size: 13px;color: white;float: right;margin-left: 5px;}`
    .active:after {content: '\2796';}`
    UL{padding: 2px;margin: 2px;}`
    UL li{margin-left:20px;}
    li.value{list-style-type: none;}
</style>" 

# Script to collapse buttons
$collapseScript ="<script>`
var coll = document.getElementsByClassName('collapsible');`
var i;`
for (i = 0; i < coll.length; i++) {`
  coll[i].addEventListener('click', function() {`
    this.classList.toggle('active');`
    var content = this.nextElementSibling;`
    if (content.style.maxHeight){`
      content.style.maxHeight = null;`
    } else {`
      content.style.maxHeight = content.scrollHeight + 'px';`
    }`
  });`
}`
</script>"

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

function GetAlertStatus {
    If ($values[4] -eq 'True'){
        $AlertStatus = "<td><b>Raises Alert</b><br>Severity: " + $values[5] + "<br>Priority: " +  $values[6] + "</td></tr>"
    }
    Else {
        $AlertStatus = "<td class='grey'><b>Alerting:</b> Does not alert</td></tr>"
    }

    return $AlertStatus
}

function GetEnabled {

    Switch ($values[3]){
        'false' {$enabled = "<td class='grey'><b>Enabled:</b> " + $values[3]  + "</td>"}
        'true' {$enabled = "<td class='green'><b>Enabled:</b> " + $values[3]  + "</td>"}
        default {$enabled = "<td class='green'><b>Enabled:</b> true (" + $values[3]  + ")</td>"}
    }

    return $enabled    
}

function GetOverrides {
    If ($values[9] -eq 'True'){
        $AllOverrides = $null
        $AllOverrides += "<td><b>Overrides Configured</b><ul>"
        $i=10
        $flag = $false
        While ($i -le 39) {
            if ($values[$i] -and ($values[$i+1] -ne $values[$i+2])){
                $flag = $true
                $AllOverrides += "<li><b>Parameter: " + $values[$i] + "</b></li>"
                $AllOverrides += "<li class='value'>Default Value: " + $values[$i+1] + "</li>"
                $AllOverrides += "<li class='value'>Effective Value: " + $values[$i+2] + "</li>"
            }
            $i+=3
        }
        If (!$flag) {$AllOverrides += "<span style='color:grey;'>None configured for this instance</span>"}
        $AllOverrides += "</ul><b> Additional exposed overrides</b><ul>"
        $i=10
        While ($i -le 39) {
            if ($values[$i] -and ($values[$i+1] -eq $values[$i+2])){
                $AllOverrides += "<li><b>Parameter: " + $values[$i] + "</b></li>"
                $AllOverrides += "<li class='value'>Default Value: " + $values[$i+1] + "</li>"
            }
            $i+=3
        }
        $AllOverrides += "</ul></td></tr>"
    }
    Else {
        If ($null -eq $values[9]){
            $AllOverrides += "<td class='grey'><span style='color:red;'>Error: not able to read override information.</span></td></tr>"
        }
        Else {
            $AllOverrides += "<td class='grey'>No overrides configured. <br> Exposed overrides:<ul>"
            $i=10
            $flag = $false
            While ($i -le 39) {
                if ($values[$i]){
                    $AllOverrides += "<li><b>Parameter: " + $values[$i] + "</b></li>"
                    $AllOverrides += "<li class='value'>Default Value: " + $values[$i+1] + "</li>"
                }
                $i+=3
            }
            If (!$flag) {$AllOverrides += "None"}
            $AllOverrides += "</ul></td></tr>"
        }
    }

    return $AllOverrides
}

function GetDisplayName {
    $DisplayName = $null
    $ID = $values[2]
    $alerts = $values[4]
    $type = $values[7]
    $description = $values[8]
    If ($type -eq 'rule'){
        $DisplayName = (get-scomrule -name "$ID").displayname
        If ($alerts -eq "true") {
            $Workflow = "Alert Rule"
        }
        Else {
            If (($description -like "*collect*")-or ($ID -like "*collect*")) {
                $Workflow = "Collection Rule"
            }
            Else {
                $Workflow = "Rule"
            }
        }
    } 
    Else {
        $DisplayName = (get-scommonitor -name "$ID").displayname
        Switch -Regex ($ID) {
            "AvailabilityState$" {$Workflow = "Rollup Monitor"}
            "ConfigurationState$" {$Workflow = "Rollup Monitor"}
            "PerformanceState$" {$Workflow = "Rollup Monitor"}
            "SecurityState$" {$Workflow = "Rollup Monitor"}
            "EntityState$" {$Workflow = "Rollup Monitor"}
            "Rollup$" {$Workflow = "Rollup Monitor"}
            "Aggregate" {$Workflow = "Aggregate Monitor"}
            "DependencyMonitor$" {$Workflow = "Dependency Monitor"}
            default {$Workflow = "Unit Monitor"}
        } 
    }
    If ($null -eq $DisplayName) {$DisplayName = $ID}
    
    $display = "<td width=75%><b>Display Name: <span style='color:blue;'>" + $DisplayName + "</span></b><br>"
    $display += "<b>ID:</b> " + $ID + "<br>"
    $display += "<b>Type:</b> " + $Workflow + "<br>"
    $display += "<b>Description:</b> " + $description + "</td>"

    return $display
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
# Don't connect to MS if just formatting an existing file
If ($FormatFile) {
    $Hostname = (($FormatFile.Split('.')[0]).Split('\'))[-1]
    $output = $FormatFile

    # Build Header information for output file
    $body += "<h1>Monitoring Configuration for Server : $Hostname </h1>"
    $body += "<span class=bold>    Report Generated :</span> $(get-date -format g)</br>"
}
Else {
    # CHeck for established connection to Management Server  
    CheckMSConnect
    
    #Generate Effective Configuration CSV
    $Hostname = ($AgentFQDN.Split('.'))[0]
    $output = GetConfig $FolderPath $AgentFQDN

    # Build Header information for output file
    $body += "<h1>Monitoring Configuration for Server : $AgentFQDN </h1>"
    $body += "<span class=bold>    Report Generated :</span> $(get-date -format g)</br>"
}

# Get output of configuration CSV
Write-Host "Formatting Configuration Information for $Hostname " -ForegroundColor Cyan
$lines = GetRawCSV $output
$total = $lines.Count
$i = 0

# Build table of workflows and settings
$body += "Total workflows: " + $lines.Count + "<hr><p>"
$body += "<div class='content'><table>"

$lines | foreach {
    # Progress bar
    $i += 1
    $progress = ($i/$total)*100
    Write-Progress -Activity "Loading Workflows" -PercentComplete $progress

    $values = $null
    $values = ($_).Split('|')  

    # Skip lines that wrapped from previous monitor description
    If ($values[0] -match '\w\.\w') {

    # Display Class and Instance information 
        $currinst = $values[0] + $values[1]
        If ($currinst -ne $previnst) {
            $body += "</table></div>`
                <button class='collapsible'>Class: <b>" + $values[0] + "</b> --- Instance: <b>" + $values[1] + "</b></button> `
                <div class='content'><table>"
        }
        Else {
            $body += "<tr><td class='yellow';></td><td class='yellow';></td></tr>"
        }
        $previnst = $currinst

        # Assemble formatted cells for each rule/monitor
        $body += GetDisplayName 
        $body += GetOverrides
        $body += GetEnabled
        $body += GetAlertStatus
    }
}

# Finish body of report
$body += "</table>"
$body += $collapseScript

# Create output file
$Reportfile = $FolderPath + $Hostname + ".html"
ConvertTo-Html -Head $CSSHead -Body $body |Out-File $Reportfile
Invoke-Item $Reportfile
