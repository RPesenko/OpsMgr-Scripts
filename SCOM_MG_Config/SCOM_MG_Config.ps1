<#  
    Add, Remove or List SCOM Management Groups for a remote computer
    Requires COM access to remote computer

    Parameter:  CSV list of computers to perform action on

    File Format: 
        ComputerName, <action>, <name of MG>, <fqdn of primary MS>

    Note:  One computer name (host or FQDN) per line, plus optional parameters
           Action is optional, accepted values are 'add' and 'remove', otherwise leave empty
           Name of MG is required for actions 'add' or 'remove', otherwise leave empty
           Name of MS is required for 'add', otherwise leave empty

   ** This script is provided 'as is' with no warranty, express or implied ** 
#>

Param (
    [String] $FilePath 
)

Function ListMG {
    Param (
        [String] $RemoteComputer
    )

    Try {
        # Connect to remote computer
        Write-Host "Listing Configuration for" $RemoteComputer -ForegroundColor Yellow
        $Ping = (Test-Connection $RemoteComputer -Count 1 -Quiet)
        If ($Ping) {
            Invoke-Command -ComputerName $RemoteComputer -ErrorAction Stop -ScriptBlock { 
                Try {
                    $objAgent = New-Object -ComObject AgentConfigManager.MgmtSvcCfg -ErrorAction Stop
                }
                Catch [System.Runtime.InteropServices.COMException]{
                    Write-Host "  Error: Agent not installed" -ForegroundColor Red
                    Continue
                }
                Catch {
                    Write-Host "  Enumeration Failure: " ($_.Exception).Message -ForegroundColor Red
                    Continue
                }

                # Get list of SCOM Management Groups (will be empty if only OMS agent)
                $MGList = @($objAgent.GetManagementGroups() )
                If ($MGList.Count -eq 0) {
                    Write-Host "  No SCOM Management Groups configured.  May be OMS agent." -ForegroundColor Cyan
                }
                Else {
                    Foreach ($MG in $MGList) {
                    Write-Host "  Management Group: " $MG.ManagementGroupName
                    Write-Host "    Management Server: " $MG.ManagementServer
                    }
                }
            }
        }
        Else {
            Write-Host " Network Error: $RemoteComputer not found or not accessible on network" -ForegroundColor Red
        }
    }
    Catch {
        Write-Host "  Connection Failure: " ($_.Exception).TransportMessage -ForegroundColor Red
    }
}

Function AddMG {
    Param (
        [String] $RemoteComputer,
        [String] $AddNewMG,
        [String] $AddNewMS
    )

# Connect to remote computer
    Try {
        Write-Host " Connecting to " $RemoteComputer -ForegroundColor Green
        Invoke-Command -ComputerName $RemoteComputer -ArgumentList $AddNewMG,$AddNewMS -ErrorAction Stop -ScriptBlock { 
            $NewMG = $args[0].ToString().Trim()
            $NewMS = $args[1].ToString().Trim()
            Try {
                Write-Host " Success. Finding existing SCOM Management Groups" -ForegroundColor Green
                $objAgent = New-Object -ComObject AgentConfigManager.MgmtSvcCfg -ErrorAction Stop
            }
            Catch {
                Write-Host "  Enumeration Failure: " ($_.Exception).Message -ForegroundColor Red
            }

        # Get list of SCOM Management Groups (will be empty if only OMS agent)
            $MGList = $objAgent.GetManagementGroups() 
            $MGFlag = 0

        # Check if MG is already configured for computer
            foreach($FoundMG in $MGList) {
                If ($FoundMG.managementGroupName -eq $NewMG) {
                    $MGFlag = 1
                }
            }
            If ($MGFlag -eq 1) {
                Write-Host "  Agent is already configured for" $NewMG -ForegroundColor Green
            }
        
        # Add new MG and MS to agent
            Else {
                Write-Host "  Adding" $NewMG "and" $NewMS "to agent configuration:" -ForegroundColor Yellow
                Try {
                    $objAgent.AddManagementGroup($NewMG, $NewMS, 5723)
                    Write-Host "  Success. " -ForegroundColor Green
                    #$objAgent.ReloadConfiguration()
                    $objAgent.GetManagementGroups() |Select ManagementGroupName, ManagementServer |FT
                }
                Catch {
                    Write-Host "  Configuration Failure: " ($_.Exception).Message -ForegroundColor Red
                }
            }
        }
    }
    Catch {
        Write-Host "  Connection Failure: " ($_.Exception).TransportMessage -ForegroundColor Red
    }

}

Function RemoveMG {
    Param (
        [String] $RemoteComputer,
        [String] $deleteMG
    )

# Connect to remote computer
    Try {
        Write-Host " Connecting to" $RemoteComputer -ForegroundColor Green
        Invoke-Command -ComputerName $RemoteComputer -ArgumentList $deleteMG -ErrorAction Stop -ScriptBlock { 
            $DelMG = $args[0].ToString().Trim()
            Try {
                Write-Host " Success. Finding existing SCOM Management Groups" -ForegroundColor Green
                $objAgent = New-Object -ComObject AgentConfigManager.MgmtSvcCfg -ErrorAction Stop
            }
            Catch {
                Write-Host "  Enumeration Failure: " ($_.Exception).Message -ForegroundColor Red
            }

        # Get list of SCOM Management Groups (will be empty if only OMS agent)
            $MGList = $objAgent.GetManagementGroups() 
            $MGFlag = 0

            foreach($FoundMG in $MGList) {
                If ($FoundMG.managementGroupName -eq $DelMG) {
                    $MGFlag = 1
                }
            }

            If ($MGFlag -eq 0) {
                Write-Host "  Agent is not configured for" $DelMG -ForegroundColor Green
            }
            Else {
                Write-Host "  Deleting MG from agent configuration:" -ForegroundColor Yellow
                Try {
                    $objAgent.RemoveManagementGroup($DelMG)
                    Write-Host "  Success. " -ForegroundColor Green
                    #$objAgent.ReloadConfiguration()
                    $objAgent.GetManagementGroups() |Select ManagementGroupName, ManagementServer |FT
                }
                Catch {
                    Write-Host "  Configuration Failure: " ($_.Exception).Message -ForegroundColor Red
                }
            }
        }
    }
    Catch {
        Write-Host "  Connection Failure: " ($_.Exception).TransportMessage -ForegroundColor Red
    }
}

<#  
    MAIN 
#>

# Get list of computers and actions
Try {
    $content = Get-Content $FilePath
}
Catch {
    Write-Host "Path to server list is required." -ForegroundColor Red
    Exit
}

foreach ($line in $content) {
    $computer = $line.split(',')[0]
    $action = $line.split(',')[1]
    $MG = $line.Split(',')[2]
    $MS = $line.Split(',')[3]

    If ($computer -eq "") {
        Continue
    }
    
    If ($action -like "*add*") {
        If (($MG -ne $null) -and ($MS -ne $null)){
            Write-Host "Performing action:" $action "for computer:" $computer "with MG:" $MG "and MS:" $MS -ForegroundColor Yellow
            AddMG $computer $MG $MS
        }
        Else{
            Write-Host "Performing action:" $action "for computer:" $computer -ForegroundColor Yellow
            Write-Host "  MG and MS information required to perform action 'add' for" $computer -ForegroundColor Red
        }
    }
    ElseIf ($action -like "*remove*") {
        If ($MG -ne $null) {
            Write-Host "Performing action:" $action "for computer:" $computer "from MG:" $MG -ForegroundColor Yellow
            RemoveMG $computer $MG
        }
        Else {
            Write-Host "Performing action:" $action "for computer:" $computer -ForegroundColor Yellow
            Write-Host "  MG information required to perform action 'remove' for" $computer  -ForegroundColor Red
        }
    }
    Else {
        ListMG $computer
    }
}

