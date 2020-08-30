# MMAlert.PS1
Create an event for SCOM agents with long Maintenance Mode windows ending within 24 hours.  

## Purpose
This script will detect any Windows Computer objects currently in Maintenance Mode in SCOM and log an event for any when their MM started more than 3 days prior and will be ending within 24 hours.

## Use case
If any agent had been put in MM prior to decomissioning, but the MM window will end before decommisioning is completed, this script can log an event to notify the administrator that the MM window needs to be extended.  

The script can be used in a scheduled Windows task.  A custom alert generating rule in SCOM can be configured to alert on the Windows event.

## usage ##
Run the script on any server with the SCOM console installed under the context of a SCOM administrator.
Script will log an event 8585, with the source "health service script", if any agents are ending MM in less than 24 hours (but only if the MM window started more than 3 days ago).  The body of the event will list what agents are ending MM soon, when the MM window started and is scheduled to end, and who scheduled MM.

If no agents meet the criteria, the event logged will have an id of 8580.  
