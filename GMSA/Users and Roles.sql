/*
Script to create Logins, Users and Roles required for GMSA support
 in System Center Operations Manager 2019. 
   - Replace the string "Contoso" with your domain name
   - Replace the string "OMMSAA_GMSA$" with your Management Server Action Account name.
   - Replace the string "OMSDK_GMSA$" with your Data Access Service/Config Service account name.
   - Replace the string "OMDW_GMSA$" with your DataWarehouse Data Writer account name.
   - Replace the string "OMRep_GMSA$" with your DataWarehouse Data Reader account name.
*/

/*
  These commands need to be run on the SQL instance hosting the OperationsManager database
*/
CREATE LOGIN [CONTOSO\OMMSAA_GMSA$] FROM WINDOWS;
CREATE LOGIN [CONTOSO\OMSDK_GMSA$] FROM WINDOWS;
CREATE LOGIN [CONTOSO\OMDW_GMSA$] FROM WINDOWS;

/*--------------------------------------------------------*/
USE MSDB
CREATE USER [CONTOSO\OMMSAA_GMSA$]
CREATE USER [CONTOSO\OMSDK_GMSA$]

ALTER ROLE SQLAgentOperatorRole ADD MEMBER [CONTOSO\OMMSAA_GMSA$]
ALTER ROLE SQLAgentReaderRole ADD MEMBER [CONTOSO\OMMSAA_GMSA$]
ALTER ROLE SQLAgentUserRole ADD MEMBER [CONTOSO\OMMSAA_GMSA$]

ALTER ROLE SQLAgentOperatorRole ADD MEMBER [CONTOSO\OMSDK_GMSA$]
ALTER ROLE SQLAgentReaderRole ADD MEMBER [CONTOSO\OMSDK_GMSA$]
ALTER ROLE SQLAgentUserRole ADD MEMBER [CONTOSO\OMSDK_GMSA$]

/*--------------------------------------------------------*/
USE OperationsManager
CREATE USER [CONTOSO\OMMSAA_GMSA$]
CREATE USER [CONTOSO\OMSDK_GMSA$]
CREATE USER [CONTOSO\OMDW_GMSA$]

ALTER ROLE db_datareader ADD MEMBER [CONTOSO\OMMSAA_GMSA$]
ALTER ROLE db_datawriter ADD MEMBER [CONTOSO\OMMSAA_GMSA$]
ALTER ROLE db_ddladmin ADD MEMBER [CONTOSO\OMMSAA_GMSA$]
ALTER ROLE dbmodule_users ADD MEMBER [CONTOSO\OMMSAA_GMSA$]

ALTER ROLE ConfigService ADD MEMBER [CONTOSO\OMSDK_GMSA$]
ALTER ROLE db_accessadmin ADD MEMBER [CONTOSO\OMSDK_GMSA$]
ALTER ROLE db_datareader ADD MEMBER [CONTOSO\OMSDK_GMSA$]
ALTER ROLE db_datawriter ADD MEMBER [CONTOSO\OMSDK_GMSA$]
ALTER ROLE db_ddladmin ADD MEMBER [CONTOSO\OMSDK_GMSA$]
ALTER ROLE db_securityadmin ADD MEMBER [CONTOSO\OMSDK_GMSA$]
ALTER ROLE dbmodule_users ADD MEMBER [CONTOSO\OMSDK_GMSA$]
ALTER ROLE sdk_users ADD MEMBER [CONTOSO\OMSDK_GMSA$]
ALTER ROLE sql_dependency_subscriber ADD MEMBER [CONTOSO\OMSDK_GMSA$]

ALTER ROLE apm_datareader ADD MEMBER [CONTOSO\OMDW_GMSA$]
ALTER ROLE apm_datawriter ADD MEMBER [CONTOSO\OMDW_GMSA$]
ALTER ROLE db_datareader ADD MEMBER [CONTOSO\OMDW_GMSA$]
ALTER ROLE dwsynch_users ADD MEMBER [CONTOSO\OMDW_GMSA$]
/*--------------------------------------------------------*/
/*--------------------------------------------------------*/


/*
  These commands need to be run on the SQL instance hosting the OperationsManager DataWarehouse
*/
CREATE LOGIN [CONTOSO\OMSDK_GMSA$] FROM WINDOWS;
CREATE LOGIN [CONTOSO\OMDW_GMSA$] FROM WINDOWS;
CREATE LOGIN [CONTOSO\OMRep_GMSA$] FROM WINDOWS;

/*--------------------------------------------------------*/
USE OperationsManagerDW
CREATE USER [CONTOSO\OMSDK_GMSA$]
CREATE USER [CONTOSO\OMDW_GMSA$]
CREATE USER [CONTOSO\OMRep_GMSA$]

ALTER ROLE apm_datareader ADD MEMBER [CONTOSO\OMSDK_GMSA$]
ALTER ROLE db_datareader ADD MEMBER [CONTOSO\OMSDK_GMSA$]
ALTER ROLE OpsMgrReader ADD MEMBER [CONTOSO\OMSDK_GMSA$]

ALTER ROLE apm_datareader ADD MEMBER [CONTOSO\OMDW_GMSA$]
ALTER ROLE db_datareader ADD MEMBER [CONTOSO\OMDW_GMSA$]
ALTER ROLE db_owner ADD MEMBER [CONTOSO\OMDW_GMSA$]
ALTER ROLE OpsMgrWriter ADD MEMBER [CONTOSO\OMDW_GMSA$]

ALTER ROLE apm_datareader ADD MEMBER [CONTOSO\OMRep_GMSA$]
ALTER ROLE db_datareader ADD MEMBER [CONTOSO\OMRep_GMSA$]
ALTER ROLE OpsMgrReader ADD MEMBER [CONTOSO\OMRep_GMSA$]
/*--------------------------------------------------------*/
/*--------------------------------------------------------*/


/*
  These commands need to be run on the SQL instance hosting the Report Server DB and TempDB
*/
CREATE LOGIN [CONTOSO\OMRep_GMSA$] FROM WINDOWS;

/*--------------------------------------------------------*/
USE Master
CREATE USER [CONTOSO\OMRep_GMSA$]
ALTER ROLE RSExecRole ADD MEMBER [CONTOSO\OMRep_GMSA$]

/*--------------------------------------------------------*/
USE MSDB
CREATE USER [CONTOSO\OMRep_GMSA$]

ALTER ROLE RSExecRole ADD MEMBER [CONTOSO\OMRep_GMSA$]
ALTER ROLE SQLAgentOperatorRole ADD MEMBER [CONTOSO\OMRep_GMSA$]
ALTER ROLE SQLAgentReaderRole ADD MEMBER [CONTOSO\OMRep_GMSA$]
ALTER ROLE SQLAgentUserRole ADD MEMBER [CONTOSO\OMRep_GMSA$]

/*--------------------------------------------------------*/
USE ReportServer
CREATE USER [CONTOSO\OMRep_GMSA$]
ALTER ROLE RSExecRole ADD MEMBER [CONTOSO\OMRep_GMSA$]
ALTER ROLE db_owner ADD MEMBER [CONTOSO\OMRep_GMSA$]

/*--------------------------------------------------------*/
USE ReportServerTempDB
CREATE USER [CONTOSO\OMRep_GMSA$]
ALTER ROLE RSExecRole ADD MEMBER [CONTOSO\OMRep_GMSA$]
ALTER ROLE db_owner ADD MEMBER [CONTOSO\OMRep_GMSA$]

/*--------------------------------------------------------*/
/*--------------------------------------------------------*/
