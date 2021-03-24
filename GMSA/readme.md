# Users and Roles.sql
Operations Manager 2019 UR1 supports group managed service accounts (gMSA). The service accounts need to have logins and users created in the OperationsManager database, the DataWarehouse and the SSRS database.   The link below describes the database changes required.
https://docs.microsoft.com/en-us/system-center/scom/database-changes?view=sc-om-2019

This script can be used to automate the required changes for your own environment.
   - Replace the string "Contoso" with your domain name
   - Replace the string 'CONTOSO_MG' with the name of the SCOM management group
   - Replace the string "OMMSAA_GMSA$" with your Management Server Action Account name.
   - Replace the string "OMSDK_GMSA$" with your Data Access Service/Config Service account name.
   - Replace the string "OMDW_GMSA$" with your DataWarehouse Data Writer account name.
   - Replace the string "OMRep_GMSA$" with your DataWarehouse Data Reader account name.

If your Database and Datawarehouse are hosted by the same SQL instance, you only need to create a login and user for each account once.  If your Report Server databases are hosted on the same SQL instance as the Datawarehouse, the command to create the login for the OMRep_GMSA$ does not have to be run a second time, but you will still create the user and add roles on each db.