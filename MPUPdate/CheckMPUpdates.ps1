<#
  CheckMPUpdates : v1.0
  Checks for updates to installed sealed MP from previously downloaded catalog file
#>

Param (
    [string] $MSConnection,
    [string] $Inputfile = "C:\temp\MPCatalog.xml"
)

function GetSCOMModule ($MgmtServer){

    $Server = $MgmtServer

    Try {
        $SCOMPowerShellKey = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
        $SCOMModulePath = Join-Path (Get-ItemProperty $SCOMPowerShellKey).InstallDirectory "OperationsManager"
        Import-module $SCOMModulePath -ErrorAction Stop
        New-SCManagementGroupConnection $Server -ErrorAction Stop
    }
    Catch {
        Write-Host "SCOM Console not installed or OperationsManager module not found" -ForegroundColor Red
        Write-Host "Try running script as local administrator or from OperationsManager shell session." -ForegroundColor Red
        Exit
    }
}

function ConnectToSDK ($MSConnection) {

    $MgmtServer = $MSConnection

    Try {
        New-SCManagementGroupConnection $MgmtServer -EA stop
    }    
    # SCOM Modules not installed
    Catch [System.Management.Automation.CommandNotFoundException]{
        GetSCOMModule $MgmtServer
    }
    # Can't connect to Management Server
    Catch {
        Write-host "Connection unavailable to" $MSConnection -ForegroundColor Red
        Exit
    }
}

function CompareVersions {
    param (
        [String] $IntalledVer,
        [String] $CurrentVer
    )

    If ([Version]$CurrentVer -gt [Version]$IntalledVer) {
        Return $True 
    }
    Else {
        Return $false
    }
}

function GetCatalogFile {
    param (
        [string] $XMLfile
    )
    Try {
        $Content = Import-Clixml -Path $XMLfile
        Write-Host "Imported Management Pack Catalog file" $XMLfile -ForegroundColor Magenta
    }
    Catch {
        Write-Host "Error: Can't import Management Pack Catalog file" -ForegroundColor Red
        Write-Host "   Error Message:  " $_.Exception.Message -ForegroundColor Red
        Exit
    }
    Return $Content
}

function GetInstalledMPList {
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
    
    Try {
        $InstalledMPs = get-SCOMmanagementpack | where-object {$_.Sealed -eq $true} -ErrorAction Stop
        Write-Host "Identified" $InstalledMPs.count "sealed Management Packs installed in Management Group" -ForegroundColor Magenta
    }
    Catch {
        Write-Host "Error: Can't get installed Management Packs" -ForegroundColor Red
        Write-Host "   Error Message:  " $_.Exception.Message -ForegroundColor Red
        Exit
    }
    
    # Get version info for installed MP
    $InstalledList = @()
    foreach ($mp in $InstalledMPs) {
        $InstalledMP = [PSCustomObject]@{
            MPName = $mp.Name
            MPVersion = $mp.Version
            MPDate = $mp.TimeCreated
            Display = $mp.DisplayName
        }
        $InstalledList += $InstalledMP
    }

    $List = $InstalledList |Sort MPName

    Return $List 
}

# ======================================================================================
# Main

$InstalledMPList = GetInstalledMPList

$CatalogList = GetCatalogFile $Inputfile

Write-host "========================="

foreach ($MPitem in $InstalledMPList) {
    # Match on System Name, take newest version if multiple versions are published
    $CatItems = $CatalogList | ? {$_.MPName -eq $MPitem.MPName} | Sort MPVersion -Descending
    If ($Catitems) {
        $CatItem = $catItems[0]
    }
    Else {
        $CatItem = $null
    }

    # MP Display name is sometimes blank, use system name
    If (!$MPitem.Display){
        $MgmtPackName = $MPitem.MPName 
    }
    else {
        $MgmtPackName = $MPitem.Display
    }

    IF (!$Catitem){
        Write-Host "- " $MgmtPackName " Version: " $MPitem.MPVersion " [No Published Updates]" -ForegroundColor Cyan
    }
    Else {
        # These are strings so we need a function to compare them
        $UpdateAvail = CompareVersions $MPitem.MPVersion $CatItem.MPVersion
        If ($UpdateAvail) {
            $MPReleaseDate = ([Datetime]::Parse($CatItem.MPDate)).tostring('d')
            Write-Host "- " $MgmtPackName " Version: " $MPitem.MPVersion " [Update Available: " $CatItem.MPVersion "(" $MPReleaseDate ")  ]" -ForegroundColor Yellow
        }
        Else {
            Write-Host "- " $MgmtPackName " Version: " $MPitem.MPVersion " [Current]" -ForegroundColor Green
        }
    }
}