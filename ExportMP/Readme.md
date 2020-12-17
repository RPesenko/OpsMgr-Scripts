# ExportMPs.ps1
    Version: 2.0
    Release 2020/12/16
  
This is a script that will export all the Management Packs in a SCOM Managment Group.
The script uses the folowing parameters:

 - [Sealed] = Optional parameter. Set value to "True" if you want to export both sealed and unsealed Management Packs.  The script will default to only export unsealed MP.
 - [MSConnection] = Optional parameter. The Management Server to connect to when obtaining the list of Management Packs.  If no MS is specified, the script will use the existing connection or try to connect to localhost. 
 - [Folder] = Optional parameter. Specify the folder you want to export Management Packs to.  If no folder is specified, the script will create a new export root folder at "C:\SCOMFIles\ManagementPacks".  

 A child folder with the day's date (in YYYY-MM-DD format) will be created at the parent folder specfied above.  If a child folder for today's date already exists, it will be overwritten.

### View Script Here
#### (Right click and select 'Save Link As' to download)
https://github.com/RPesenko/OpsMgr-Scripts/blob/master/ExportMP/ExportMPs.ps1
 
Change Log  
2.0: Improvements to MG connection  
1.1: Updates to documentation   
1.0: Initial release  