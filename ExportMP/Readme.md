# ExportMPs.ps1
    Version: 2.0
    Release 2020/12/16
  
This is a script that will export all the Management Packs in a SCOM Managment Group.
The script uses the folowing parameters:

 - _MSConnection_ = Name of the Management Server to connect to.  If not is specified, the script will connect to the local machine and attempt to load the OpsMgr Command Shell.  
 - _Sealed_ = Set value to "True" if you want to export both sealed and unsealed Management Packs.  The script will default to only export unsealed MP.
 - _Folder_ = Specify the folder you want to export Management Packs to.  If no folder is specified, the script will create a new export root folder at "C:\SCOMFIles\ManagementPacks".  

 A child folder with the day's date (in YYYY-MM-DD format) will be created at the parent folder specfied above.  If a child folder for today's date already exists, it will be overwritten.

 ### Download Script Here 
 https://github.com/RPesenko/OpsMgr-Scripts/blob/master/ExportMP/ExportMPs.ps1
 
Change Log  
2.0: Improvements to MG connection  
1.1: Updates to documentation   
1.0: Initial release  