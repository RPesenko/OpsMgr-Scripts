# ExtendMM.ps1
Script to display, extend, modify or end maintenance mode for a group of computers in a SCOM management group

## Purpose
If a list of agent-managed computers is provided in a text file, this script can show which of them are in SCOM Maintenance Mode, when the Maintenance period started, and is scheduled to end.   The maintenance window for all computers in the list can be extended by a certain amount of time, set to end for all computers at a given time, or set to end in five minutes.

## Parameters:
- MMList = Location of the list of computers. Defaults to **C:\Temp\Computers.txt** 
    - must be FQDN for domain joined agents
- MMAction = Action to perform.
    - (parameter omitted) = display script help
    - show = List MM state of computers in list
    - endnow = set MM to end for all computers in list five minutes from now
    - endat = end MM a given amount of time from now (use with the time parameter )
        - If time is not specified, MM will be set to end one hour from now
    - extend = add additional time to end of scheduled end of MM (use with the time parameter)
        - If time is not specified, scheduled end of MM will be extended by one week 
- time = the amount of time (in minutes) used by 'endat' or 'extend' parameters

## Usage
**ExtendMM.ps1**    
 Shows script help

**ExtendMM.ps1 -show**  
List all computers in the default text file location (if file exists) and indicate if they are in SCOM maintainence mode.  If so, when MM started and is scheduled to end.

**ExtendMM.ps1 -MMList [file] -show**  
List all computers in the file specified by [file] and indicate if they are in SCOM maintainence mode.  If so, when MM started and is scheduled to end.

**ExtendMM.ps1 -MMList [file] -endnow**  
List all computers in the file specified by [file] and indicate if they are in SCOM maintainence mode.  If so, when MM started and was originally scheduled to end.  The new end time will be set for five minutes from now.

**ExtendMM.ps1 -MMList [file] -endat**  
List all computers in the file specified by [file] and indicate if they are in SCOM maintainence mode.  If so, when MM started and was originally scheduled to end.  The new end time will be set for five minutes from now.

**ExtendMM.ps1 -MMList [file] -endat -time 90**  
List all computers in the file specified by [file] and indicate if they are in SCOM maintainence mode.  If so, when MM started and was originally scheduled to end.  The new end time will be set for 90 minutes from now for all computers in the list.

**ExtendMM.ps1 -MMList [file] -extend**  
List all computers in the file specified by [file] and indicate if they are in SCOM maintainence mode.  If so, when MM started and was originally scheduled to end.  The new end time will be extended by one week from the scheduled end time for all computers in the list.

**ExtendMM.ps1 -MMList [file] -extend -time 180**  
List all computers in the file specified by [file] and indicate if they are in SCOM maintainence mode.  If so, when MM started and was originally scheduled to end.  The new end time will be extended by 180 minutes from the scheduled end time for all computers in the list.

### Download Script Here:
https://github.com/RPesenko/OpsMgr-Scripts/blob/master/ExtendMM/ExtendMM.ps1