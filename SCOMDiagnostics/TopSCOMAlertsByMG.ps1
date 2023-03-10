<# TopSCOMAlertsbyMG.ps1
   
   For each MG, gets the top ten SCOM alerts from the last two days, 
    then breaks out each alert by top ten instances of that alert

   V 2.1
   Rich Pesenko, [MSFT]
   Change Log: (v:2.1) 11/11/2022 -Filter out health check alerts before getting all alert; Add Clean-Alert function

   V 3.0 -> Call SCOMFunctions instead of local functions
            Combine output from all MG to one outfile (MG file and Summary file)
            Add MGConnection functions to library file and invoke (including Try/Catch)
            Add Output folder to library function and invoke (including create subfolders)
              - Output folder = Folder root, File root (Folder defaults to C:\SCOMFiles, Fileroot defaults to whatever)
            Try to calculate percentages of top alerts

#>

# Output folder (Adapt for function: Folder root, File root)
$FileRoot = "C:\SCOMFiles\TopAlerts"
# Collection of all SDK endpoints
$AllMG = ("OM19MS1")

# Write output to specified file
Function Write-to-File {
    Param (
        $msg,
        [String] $outfile
    )
    add-Content -Value $msg -Path $outfile
}

Function Clean-Alert {
    param ($AlertOutput, $ACount)

    $Aname = "Alert target class: " + (($AlertOutput[0].Name).Split(':'))[0] + "`r`n"
    $Aname += "------------------------------------------------------------------------------`r`n"

    Foreach ($alert in $AlertOutput){
        $pct = "{0:P2}" -f $($alert.count/$ACount)
        $Astring = ($Alert.name).split(':')
        $AstringName = ($Astring[1]).replace(";"," / ")
        $AName += "`t" + $AstringName + "`t`t Count:" + $alert.Count + "`t`t(" + $pct + ")`r`n"
    }
    Return $AName
}

### MAIN ###

# Test if running from SCOM Shell
Try {
    Get-SCOMManagementGroupConnection |Out-Null
}
Catch [System.Management.Automation.CommandNotFoundException] {
    Write-Host "`n Error: Load OperationsManager module or run script from Operations Manager Shell`n" -ForegroundColor Red
    Break
}

# Create output folder
$RepMonth = Get-Date -Format yyyy-MM-dd
$RepFolder = "TopAlerts_$RepMonth"
Set-Location $FileRoot
If (!(Test-Path $FileRoot\$RepFolder)){
    New-Item -ItemType directory -Path $FileRoot\$RepFolder
    Write-Host "Creating output folder $RepFolder in path $FileRoot" -ForegroundColor Yellow
}
Else {
    Write-host "Using Existing folder $RepFolder in path $FileRoot" -ForegroundColor Yellow
}

# Loop through each MG to generate report
Foreach ($MG in $AllMG) {

    # Initialize Loop Variables
    $Backdate = $null
    $AllAlertHash = $null 
    $TopAlertname = $null 
    $TopAlertCol = $null
    $TopAlert = $null

    # designate output file (### Add as a function ###)
    $Filename = "$RepFolder\SCOMAlerts_$MG.txt"
    If (!(Test-Path $Filename )) {
        New-Item -ItemType file -Name $Filename 
    }
    Else {
        Remove-Item -Path $Filename 
        New-Item -ItemType file -Name $Filename 
    }

    # Connect to management Group to query (### Add as a function ###)
    Try {
        New-SCManagementGroupConnection -ComputerName $MG -EA Stop
    }
    Catch [System.Net.Sockets.SocketException] {
        Write-Host " Error: Unknown Management Group [$MG]" -ForegroundColor Red
        Break
    }
    Catch [Microsoft.EnterpriseManagement.Common.UnknownDatabaseException] {
        Start-sleep 5
        Write-Host "Connection to $MG unsuccessful, retrying in 5 seconds" -ForegroundColor Yellow
        New-SCManagementGroupConnection -ComputerName $MG
    }

    # Write Header to Screen/File
    $header = "SCOM Alert analysis for Management Group " + $MG
    Write-to-File $header $Filename 
    Write-to-File "===========================================" $Filename
    Write-Host $header -ForegroundColor Green   

    # Get all alerts in last two days, grouped by name, sorted by number of occurrences. Select top 10 most frequent instances
    # If too many alerts for 48 hours, try 36 hours
    # Filter out health check alerts before getting all 
    $HealthAlerts = "custom HealthCheck Alert"
    Try{
        $Backdate = "'" + (Get-date).AddHours(-48).ToString("g") + "'"
        $AllAlertHash = @(Get-SCOMAlert -Criteria "(TimeRaised >= $Backdate) AND (Name != '$HealthAlerts')"  |Group Name |Sort Count -Descending |Select -First 10 Name, Count )
    }
    Catch{
        Write-Host " Too many alerts - reducing poll period to 36 hours" -ForegroundColor Yellow
        $Backdate = "'" + (Get-date).AddHours(-36).ToString("g") + "'"
        $AllAlertHash = @(Get-SCOMAlert -Criteria "(TimeRaised >= $Backdate) AND (Name != '$HealthAlerts')"  |Group Name |Sort Count -Descending |Select -First 10 Name, Count )
    }

    # Write alert output to Screen/File
    Foreach ($Topalert in $AllAlertHash) {
        $TopAlertname = "'" + $Topalert.Name + "'"
        $Backdate = "'" + (Get-date).AddDays(-2).ToString("g") + "'"
        $TopAlertCol = Get-SCOMAlert -Criteria "(TimeRaised >= $Backdate) AND (Name = $TopAlertname)" -ErrorAction SilentlyContinue |Group MonitoringObjectFullName |Sort Count -Descending |Select -First 10 Count, Name 
    
        $AlertHeader = "Top instances of alert [" + $TopAlert.Name + "]"
        $AlertCount = "Total alerts found in last two days: " + $Topalert.Count
        $AlertOutput = @($TopAlertCol | Select Name, Count )
        Write-to-File $AlertHeader $Filename
        Write-Host $AlertHeader -ForegroundColor cyan
        Write-to-File $AlertCount $Filename
        $cleaned = Clean-alert $AlertOutput $Topalert.Count
        Write-to-File $cleaned $Filename
        Write-to-File " " $Filename
    }
}
