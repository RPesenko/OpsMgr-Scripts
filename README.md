# OpsMgr-Scripts
A collection of useful PowerShell scripts for Operations Manager administrators

**BulkOverride** : Run the _Get-SCOMEffectiveMonitoringConfiguration_ cmelet against an agent, or use a previously generated CSV output file, and generate a single override MP to disable whatever enabled rules and monitors are selected.

**ExportMPs** : Export Sealed and Unsealed Management Packs

**ExtendMM** : Script to display, end or modify existing SCOM Maintenance Mode windows.  

**MMAlert** : Script to alert when a long Maintenance Mode window is ending in less than 24 hours.

**MPUpdate** : Scripts to identify Management Pack updates for offline SCOM Management Groups

**SCOM_Certs** : Scripts and instructions to help install agents in workgroups, non-trusted domains and perimeter networks

**SCOM_MG_Config** : Add, Remove or Display SCOM MG for CSV list of computers

**SCOMMonitoringConfig** : Run the _Get-SCOMEffectiveMonitoringConfiguration_ cmelet against an agent and format output to HTML 5 compliant file. It can optionally format a previously generated CSV file created by the Get-SCOMEffectiveMonitoringConfiguration cmdlet.

**ShowTLSStatus** : List or modify SChannel protocol settings on the local server. Quickly displays key registry values related to TLS 1.2 only configuration
