# SCOMMonitoringConfig.ps1
Version: 2.1    
Release 2020/12/16

This script runs Get-SCOMEffectiveMonitoringConfiguration against an agent and formats output to HTML 5 compliant file.

The script uses the folowing parameters:
    - _MS_ = [optional] Name of the Management Server to connect to.  If not is specified, the script will connect to the local machine and attempt to load the OpsMgr Command Shell.  
    - _FolderPath_ = [optional] The folder to save the raw CSV output and formatted HTML files to.  Default value is _C:\SCOMConfig_
    - _AgentFQDN_ = [Mandatory] The FQDN of the agent to generate the configuration file for.  

### Download Script Here 
https://github.com/RPesenko/OpsMgr-Scripts/blob/master/SCOMMonitoringConfig/SCOMMonitoringConfig.ps1
 
Change Log  
2.1: Improved MG connection logic   
1.0: Initial release    