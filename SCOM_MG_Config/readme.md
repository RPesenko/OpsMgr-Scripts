# SCOM MG Config
This script can be used to view or change management group configuration for a list of Operations Manager agents via the remote COM object. 

## Use Cases
Ideally, a SCOM administrator should view, change, add or remove management group configuration on the agent using the Operations Manager Console.  If the agent was manually installed, or network configuration prevents agent push from succeeding (remotely manageable = $false), the only available option would be to logon locally to each agent and view, change, add or remove management group information from control panel.

This script leverages the agent's COM API to display the current configuration for each management group, or make changes to the existing configuration.  Rather than logon to a large number of servers individually to make changes, the script allows a SCOM administrator to make changes in a few seconds what would normally take and hour or longer to do.

The script still requires the same level of network access and permissions as making the changes manually, but using the script makes the configuration change far more efficient.

## Requirements
- The script accepts the path to a CSV file as the only parameter. 
- The script can be run from any workstation, but needs to have RPC connectivity to the remote agents listed in the CSV.
- The script needs to be run under credentials that have local admin permission on the remote agents listed in the CSV.

## CSV format
**List MG configuration**  
Displays all Management Groups and Management Servers currently configured for the agent. The agent's FQDN is the only entry on each line.  
> **Example:**  
_[FQDN]_ 

**Add New Management Group**  
Adds a new Management Group to the agent, reporting to the specified Management Server. Each line has the agent's FQDN, the action "add", the name of the Management Group to add the agent to, the FQDN for the agent to report to in the MG.  
> **Example:**  
_[FQDN]_,add,_[Management Group Name],[Management Server Name]_

**Remove Management Group**  
Remove an existing Management group from the agent configuration.  Each line has the agent's FQDN, the action "remove" and the name of the Management Group to remove from the configuration.  
> **Example:**  
_[FQDN]_,remove,_[Management Group Name]_

## Additional Notes
The same agent can be removed from one Management Group on one line and added to another Management Group on another line in the same CSV file.  This is useful in situations where a number of manually installed agents are being migrated from one Management Group to another.
> **Example:**  
_`Agent1234.Contoso.com`_,add,_`NewContosoMG`,`MS01.Contoso.com`_
_`Agent1234.Contoso.com`_,remove,_`OldContosoMG`_

### Download Script Here:
https://github.com/RPesenko/OpsMgr-Scripts/blob/master/SCOM_MG_Config/SCOM_MG_Config.ps1
