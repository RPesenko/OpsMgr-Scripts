<#
EmptyClassMPs - Script to identify Management Packs that define classes with no class instances.
    Version: 2.0    
    Release 2020/12/17

  Note: Derived from Kevin Holman script to count all classes and instances in all non-included MPs.
  https://kevinholman.com/2020/07/14/how-to-find-unused-management-packs-in-scom/

TODO:  Split instances with 'seed' in name for

#>
param
(
  [Parameter(Mandatory)][string]$MSConnection,
  [String]$OutputFolder = "C:\SCOMFiles\EmptyMP"
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

# Check for established connection to Management Server  
CheckMSConnect

$AllMPs = Get-SCOMManagementPack | Sort-Object

# Add filtered MP's here that you dont want examined such as default SCOM MP's override MP's etc.
$FilteredMPs = $AllMPs | where {($_.name -notlike "System.*") `
    -and ($_.name -ne "Microsoft.SystemCenter.2007") `
    -and ($_.name -ne "Microsoft.SystemCenter.ACS.Internal") `
    -and ($_.name -notlike "Microsoft.SystemCenter.Advisor*") `
    -and ($_.name -notlike "Microsoft.SystemCenter.Apm.*") `
    -and ($_.name -notlike "Microsoft.SystemCenter.ApplicationMonitoring.*") `
    -and ($_.name -notlike "Microsoft.SystemCenter.ClientMonitoring.*") `
    -and ($_.name -notlike "Microsoft.SystemCenter.Data*") `
    -and ($_.name -ne "Microsoft.SystemCenter.GTM.Summary.Dashboard.Template") `
    -and ($_.name -ne "Microsoft.SystemCenter.Image.Library") `
    -and ($_.name -ne "Microsoft.SystemCenter.InstanceGroup.Library") `
    -and ($_.name -notlike "Microsoft.SystemCenter.Internal*") `
    -and ($_.name -ne "Microsoft.SystemCenter.Library") `
    -and ($_.name -notlike "Microsoft.SystemCenter.Network*") `
    -and ($_.name -notlike "Microsoft.SystemCenter.Notifications*") `
    -and ($_.name -ne "Microsoft.SystemCenter.NTService.Library") `
    -and ($_.name -notlike "Microsoft.SystemCenter.O365*") `
    -and ($_.name -notlike "Microsoft.SystemCenter.OperationsManager.*") `
    -and ($_.name -ne "Microsoft.SystemCenter.ProcessMonitoring.Library") `
    -and ($_.name -ne "Microsoft.SystemCenter.Reports.Deployment") `
    -and ($_.name -ne "Microsoft.SystemCenter.RuleTemplates") `
    -and ($_.name -ne "Microsoft.SystemCenter.SecureReferenceOverride") `
    -and ($_.name -ne "Microsoft.SystemCenter.ServiceDesigner.Library") `
    -and ($_.name -ne "Microsoft.SystemCenter.SyntheticTransactions.Library") `
    -and ($_.name -ne "Microsoft.SystemCenter.TaskTemplates") `
    -and ($_.name -notlike "Microsoft.SystemCenter.Visualization.*") `
    -and ($_.name -notlike "Microsoft.SystemCenter.WebApplication*") `
    -and ($_.name -ne "Microsoft.SystemCenter.WorkflowFoundation.Library") `
    -and ($_.name -ne "Microsoft.SystemCenter.WSManagement.Library") `
    -and ($_.name -notlike "Microsoft.Unix.*") `
    -and ($_.name -ne "Microsoft.Windows.Image.Library") `
    -and ($_.name -ne "Microsoft.Windows.Library") `
    -and ($_.name -ne "Microsoft.Windows.Server.Library") `
    -and ($_.name -ne "Microsoft.Windows.Server.NetworkDiscovery") `
    -and ($_.name -ne "Microsoft.Windows.Server.Reports") `
    -and ($_.name -ne "ODR") `
    }

IF (!(Test-Path $OutputFolder)){
  New-Item -ItemType Directory -Path $OutputFolder
}

$MG = Get-SCOMManagementGroup
[string]$MGName = $MG.Name

$MPArr = @()
$MPClassSum = @()
$MPSum = @()

FOREACH ($mp in $FilteredMPs)
{
  [string]$MPName = $mp.Name 
  Write-Host "Examining MP:"$MPName
  $MParr = @()
  [int]$MPInstancesCount = 0
  #Get all non-singleton Classes
  $Classes = $mp | Get-SCOMClass | Where {($_.Singleton -eq $false) -and ($_.Abstract -eq $false)}

  [int]$ClassCount = $Classes.Count
  IF ($ClassCount -ge 1)
  {
    Write-Host "Found Class count:"$ClassCount
    #This MP has class definitions
    FOREACH ($Class in $Classes)
    {
      $ClassArr = @()
      [string]$ClassName = $Class.Name
      Write-Host "Examining Class:"$ClassName
      #This MP has a class that is not a singleton and will be included in the output
      $MPObj = ""
      $Instances = $Class | Get-SCOMClassInstance
      [int]$InstancesCount = $Instances.Count
      Write-Host "Found Instance count:"$InstancesCount
      #Create a PowerShell Object to assign properties
      $MPObj = New-Object PSObject
      $MPObj | Add-Member -type NoteProperty -Name 'MPName' -Value $MPName
      $MPObj | Add-Member -type NoteProperty -Name 'ClassName' -Value $ClassName
      $MPObj | Add-Member -type NoteProperty -Name 'Instances' -Value $InstancesCount
      $ClassArr += $MPObj
      $MPArr += $ClassArr
      $MPInstancesCount = ($MPArr.Instances | Measure-Object -Sum).Sum
    }
    Write-Host "Found MP Total Instance count:"$MPInstancesCount
    #Create a PowerShell Object to assign properties
    $MPSumObj = New-Object PSObject
    $MPSumObj | Add-Member -type NoteProperty -Name 'MPName' -Value $MPName
    $MPSumObj | Add-Member -type NoteProperty -Name 'Instances' -Value $MPInstancesCount
    $MPSum += $MPSumObj 
  }
  ELSE
  {
    Write-Host "No classes found"
  }
  $MPClassSum += $MPArr
}

#Sort 
$MPClassSum = $MPClassSum | Sort-Object -Property @{Expression = "MPName"; Descending = $False}, @{Expression = "Instances"; Descending = $True}
$MPSum = $MPSum | Sort-Object -Property @{Expression = "Instances"; Descending = $True},@{Expression = "MPName"; Descending = $False} 

Write-Host "Exporting to CSV....."
$MPSum | Export-Csv $OutputFolder\MPInstanceCount_$MGName.csv -NoTypeInformation
$MPClassSum | Export-Csv $OutputFolder\MPClassInstanceCount_$MGName.csv -NoTypeInformation