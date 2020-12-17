# MPCatalogGet.PS1
Version: 1.2    
Release 2020/12/17  

This script is used to connect to the Management Pack Catalog web service and pull down a listing of all currently published Management Packs.  This is useful for any Management Group that is disconnected from the Internet and cannot use the native functionality in the SCOM console to detect updated MPs.

## Usage:
**MPCatalogGet.ps1** *[-Folder Foldername]*

[Foldername] = Optional parameter.  Folder to save the 'MPCatalog.xml' file.  By default, this file is saved to "C:\SCOMFiles".  


# CheckMPUdates.ps1
Version: 2.2    
Release 2020/12/17 

This script reads the MP Catalog information from 'MPCatalog.xml' and compares the version of each installed Managment Pack in the Management Group to the latest version published in the catalog.  If the installed version has the same version number as that in the catalog, the MP is indicated as being 'current', otherwise, the most recent version and release date of the MP is given.  

**Note 1:** Many Management Packs are only updated through Update Rollups or are not otherwise published to the catalog.  If the 'ShowAll' value is passed to the View parameter, then these MP will be listed as 'No Updates Published', for completeness.

**Note 2:** For best results, run this script on the Operations Manager Console.

## Usage:
**CheckMPUpdates.ps1** *[-MSConnection ManagementServer][-InputFile FileName][-View Option]*

[ManagementServer] = Optional parameter.  The Management Server to connect to when obtaining the list of Management Packs.  If no MS is specified, the script will use the existing connection or try to connect to localhost.

[FileName] = Optional parameter.  The full path to the xml file where the Management Pack catalog was saved.  Default catalog file is "C:\SCOMFiles\MPCatalog.xml".

[View] = Optional parameter. Only management packs with published updates are displayed.   
- _ShowPublished_ : Display all management packs published in the catalog, regardless if they have an update available or not.
- _ShowAll_ : Display all installed management packs, including ones not published in the catalog.

To redirect output to a text file, use this context:

`.\CheckMPUpdates.ps1 MSServer *> .\MG01.Log`

## View Scripts    
_(Right click and select 'Save Link As' to download)_    
https://github.com/RPesenko/OpsMgr-Scripts/blob/master/MPUPdate/MPCatalogGet.ps1
https://github.com/RPesenko/OpsMgr-Scripts/blob/master/MPUPdate/CheckMPUpdates.ps1

## Change Log  
2.2: Added "View" parameter to display all MP or only updated MP. Defaults to updates available only. Changed default folder for catalog file to "C:\SCOMFiles"  
2.1: Improvements to Version comparison. Improved MG connection logic   
1.0: Initial release   