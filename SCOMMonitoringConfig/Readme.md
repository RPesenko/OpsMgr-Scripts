# SCOMMonitoringConfig.ps1
Version: 2.3    
Release 2020/12/17

This script runs Export-SCOMEffectiveMonitoringConfiguration  against an agent and formats output to HTML 5 compliant file.  It can optionally format a previously generated CSV file created by the             Export-SCOMEffectiveMonitoringConfiguration  cmdlet.

## Usage:
*****Format only option*****  
**SCOMMonitoringConfig.ps1** *-FormatFile Filepath*

[FormatFile] = Mandatory parameter.  The full path of the configuraton file to format.  

*****Generate and format option*****  
**SCOMMonitoringConfig.ps1** *-AgentFQDN FQDN* *[-MS FQDN][-FolderPath Path]*

[AgentFQDN] = Mandatory parameter.  The FQDN of the agent to generate the configuration file for.  
[MS] = Optional parameter.  Name of the Management Server to connect to.  If not specified, the script will use an existing MS connection.  If none exists, it will try to connect to the local machine and attempt to load the OpsMgr Command Shell.  
[FolderPath] = Optional parameter.  The folder to save the raw CSV output and formatted HTML files to.  Default value is _C:\SCOMFiles\SCOMConfig_.  
    
**Note:** Either the FormatFile or AgentFQDN parameter will need to be passed to the script.

## View Script    
_(Right click and select 'Save Link As' to download)_    
https://github.com/RPesenko/OpsMgr-Scripts/blob/master/SCOMMonitoringConfig/SCOMMonitoringConfig.ps1
 
## Change Log  
2.3: Provided option for format file only   
2.2: Updated script defaults    
2.1: Improved MG connection logic   
1.0: Initial release    