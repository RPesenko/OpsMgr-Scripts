<#
  Script to extend maintenace mode
  Reference: https://docs.microsoft.com/en-us/powershell/module/operationsmanager/set-scommaintenancemode?view=systemcenter-ps-2016

  Note: Had to substitute the Set-SCOMMaintenanceMode with the UpdateMaintenanceMode method of SCOMMonitoringObject to get recursive update
  <method Parameters = (Monitoring instance, MMReason, comment, Recursive (0=no, 1=yes))
    MM Reason reference = https://docs.microsoft.com/en-us/dotnet/api/microsoft.enterprisemanagement.monitoring.maintenancemodereason?view=sc-om-dotnet-2019 >
#>
param
(
    [string]$MMList = "C:\Temp\Computers.txt",
    [string]$MMAction,
    [int]$time
)

function showhelp {
    Write-Host "ExtendMM.ps1 - script to modify maintenance mode for a group of computers" -ForegroundColor Cyan
    Write-Host "Parameters:"-ForegroundColor Cyan
    Write-Host "-MMList = Location of the list of computers. Defaults to C:\Temp\Computers.txt"-ForegroundColor Cyan
    Write-Host "    must be FQDN for domain joined agents"-ForegroundColor Cyan
    Write-Host "-MMAction = Action to perform."-ForegroundColor Cyan
    Write-Host "    > <blank> = display help"-ForegroundColor Cyan
    Write-Host "    > show = List MM state of computers in list"-ForegroundColor Cyan
    Write-Host "    > endnow = set MM to end for all computers in list five minutes from now"-ForegroundColor Cyan
    Write-Host "    > endat = end MM a given amount of time from now (use with the time parameter )"-ForegroundColor Cyan
    Write-Host "      If time is not specified, MM will be set to end one hour from now" -ForegroundColor Cyan
    Write-Host "    > extend = add additional time to end of scheduled end of MM (use with the time parameter)"-ForegroundColor Cyan
    Write-Host "      If time is not specified, scheduled end of MM will be extended by one week " -ForegroundColor Cyan
    Write-Host "-time = the amount of time (in minutes) used by 'endat' or 'extend' parameters"-ForegroundColor Cyan
}

function changeMM  {
    Try {
        $CompList = Get-Content $MMList -ErrorAction Stop
    }
    Catch {
        Write-Host "File not found, please specify valid list of computers" -ForegroundColor Red
        Break
    }
    foreach ($computer in $CompList) {
        $Instance = (Get-SCOMClassInstance -Name $computer | where-object {$_.FullName -like "*Microsoft.Windows.Computer*"})
        If ($Instance) {
            If ($Instance.InMaintenanceMode){
                $MMEntry = Get-SCOMMaintenanceMode -Instance $Instance
                $starttime = $MMEntry.StartTime.ToLocalTime()
                $endtime = $MMEntry.ScheduledEndTime.ToLocalTime()
                Switch ($MMAction.ToLower()) {
                    'endnow' { 
                        $NewEndTime = (Get-Date).addMinutes(5)
                        $NewEndTimeUTC = $NewEndTime.ToUniversalTime()
                        Write-Host " $computer current Maintenance Mode started at $starttime and ends at $endtime local time." -ForegroundColor Cyan
                        $Instance.UpdateMaintenanceMode($NewEndTimeUTC,0,"ending maintenance mode in 5 minutes.", 1)
                        Write-Host " $computer Maintenance Mode now ends at $NewEndTime local time." -ForegroundColor Cyan
                    }
                    'endat' { 
                        $NewEndTime = (Get-Date).addMinutes($time)
                        $NewEndTimeUTC = $NewEndTime.ToUniversalTime()
                        Write-Host " $computer current Maintenance Mode started at $starttime and ends at $endtime local time." -ForegroundColor Cyan
                        $Instance.UpdateMaintenanceMode($NewEndTimeUTC,0,"ending maintenance mode in $time minutes.", 1)
                        Write-Host " $computer Maintenance Mode now ends at $NewEndTime local time." -ForegroundColor Cyan
                    }
                    'extend' { 
                        $NewEndTime = ($endtime).addMinutes($time)
                        $NewEndTimeUTC = $NewEndTime.ToUniversalTime()
                        Write-Host " $computer current Maintenance Mode started at $starttime and ends at $endtime local time." -ForegroundColor Cyan
                        $Instance.UpdateMaintenanceMode($NewEndTimeUTC,0,"extending maintenance mode $time minutes.", 1)
                        Write-Host " $computer Maintenance Mode now ends at $NewEndTime local time." -ForegroundColor Cyan
                    }
                    'show' {
                        if ($endtime -lt ((Get-date).AddDays(1))) {
                            Write-Host "$computer current Maintenance Mode started at $starttime and ends at $endtime local time." -ForegroundColor Magenta
                            Write-Host "  WARNING:  This is less than 24 hours from now!" -ForegroundColor Magenta
                        }
                        Else {
                            Write-Host " $computer current Maintenance Mode started at $starttime and ends at $endtime local time." -ForegroundColor Cyan
                        }
                    }
                }
            }
            Else {
                Write-Host "$computer not in Maintenance Mode." -ForegroundColor Green
            }
        }
        Else {
            Write-Host "Agent $computer not found." -ForegroundColor Yellow
        }
    }
}

If (!$MMAction) {
    showhelp
}
else {
    switch ($MMAction.ToLower()) {
        'endnow' { 
            Write-Host "Ending all Maintenance Mode in five minutes" -ForegroundColor Magenta
            changeMM
        }
        'endat' {
            If ($time) {
                Write-Host "Ending all Maintenance Mode in $time minutes" -ForegroundColor Magenta
                changeMM
            }
            else {
                $time = 60
                Write-Host "MMAction is 'endat', but no time specified.  Ending all Maintenance Mode one hour from now." -ForegroundColor Magenta
                changeMM
            }
        }
        'extend' {
            If ($time) {
                Write-Host "Extending all Maintenance Mode by $time minutes" -ForegroundColor Magenta
                changeMM
            }
            else {
                $time = 10080
                Write-Host "MMAction is 'extend', but no time specified.  Adding 1 week to all Maintenance Mode." -ForegroundColor Magenta
                changeMM
            }
        }
        default {
            $MMAction = 'show'
            changeMM
        }
    }
}
