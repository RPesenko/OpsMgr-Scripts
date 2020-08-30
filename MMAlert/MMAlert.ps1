<#
MMAlert.ps1
Trigger an event 8585 if any agents are ending MM in less than 24 hours (but only if started more than 3 days ago)
Log event 8580 if no agents ending MM soon
#>

$MMList = ''
$CompList = Get-SCOMAgent|select Name
foreach ($computer in $CompList.name) {
    $Instance = (Get-SCOMClassInstance -Name $computer | where-object {$_.FullName -like "*Microsoft.Windows.Computer*"})
    If ($Instance) {
        If ($Instance.InMaintenanceMode){
            $MMEntry = Get-SCOMMaintenanceMode -Instance $Instance
            $starttime = $MMEntry.StartTime.ToLocalTime()
            $endtime = $MMEntry.ScheduledEndTime.ToLocalTime()
            $MMUser = $MMEntry.User
                if ($endtime -lt ((Get-date).AddDays(1)) -and $starttime -lt ((Get-date).AddDays(-3))) {
                    $MMString = "Maintenance Mode for $computer started at $starttime by $MMUser and ends at $endtime local time.`n"
                    $MMList += $MMString
                }
            }
        }
    }
If ($MMList.Length -gt 0) {
    Write-EventLog -LogName 'Operations Manager' -Source "Health Service Script" -EntryType Warning -EventId 8585 -Message $MMList 
}
Else {
    Write-EventLog -LogName 'Operations Manager' -Source "Health Service Script" -EntryType Information -EventId 8580 -Message "No MM ending soon"
}



