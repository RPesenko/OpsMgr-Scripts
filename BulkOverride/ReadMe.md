# BulkOverride.ps1
    Version: 1.0
    Release 2020/12/23
  
This script runs Get-SCOMEffectiveMonitoringConfiguration against an agent, or takes a previously generated CSV file, and presents all the currently enabled rules and monitors in a PowerShell Gridview object.  Enabled rules and monitors can be selected from the gridview and a single override MP can be generated to disable the selected workflows.

## Usage:
*****Use existing file option*****  
**BulkOverride.ps1** *-ConfigFile Filepath*

[ConfigFile] = Mandatory parameter.  The full path of the configuraton file to use when generating overrides.  

*****Generate configuration file option*****  
**BulkOverride.ps1** *-AgentFQDN FQDN* *[-MS FQDN][-FolderPath Path]*

[AgentFQDN] = Mandatory parameter.  The FQDN of the agent to generate the configuration file for.  
[MS] = Optional parameter.  Name of the Management Server to connect to.  If not specified, the script will connect to the local machine and attempt to load the OpsMgr Command Shell.  
[FolderPath] = Optional parameter.  The folder to save the raw CSV output to and use for generating overrides.  Default value is _C:\SCOMFiles\BulkOverride_.  

## View Script    
_(Right click and select 'Save Link As' to download)_    
https://github.com/RPesenko/OpsMgr-Scripts/blob/master/BulkOverride/Bulkoverride.ps1
 
## Change Log  
1.0: Initial release  