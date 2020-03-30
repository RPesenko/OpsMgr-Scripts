# SCOM MG Config
This script can be used to view or change management group configuration for a list of Operations Manager agents via the remote COM object. 

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

