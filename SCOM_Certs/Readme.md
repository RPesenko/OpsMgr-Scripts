# Installation of the Operations Manager agent outside the trust boundary
The Operations Manager agent can be installed on a Windows server in a workgroup, a non-trusted domain, or in a perimeter network that does not permit kerberos authentication.   Mutual authentication between the agent and the Management Server or Gateway is achieved by means of certificate authentication. 

The scripts and documents below are helpful to set up certificate authentication in your environment.

## Installing the Certificate Authority and creating the SCOM certificate template
My colleague, Irfan Rabbani, wrote a very good blog post for installing Active Directory Certificate Services and configuring the certificate template needed to request SCOM certificates.  The orginal link is here:
https://techcommunity.microsoft.com/t5/system-center-blog/monitoring-opsmgr-workgroup-clients-part-1-installing-and/ba-p/350772
##### (This blog is saved as the file _Cert01.pdf_ in this repository)

#### Additional notes
- When creating the certificate template, the location of _Certificate Revocation Lists (CRL)_ will be hard-coded into the certificate properties.  All servers (MS, GW, Agents) using certificate authentication will need to periodically access one of the CRLs in the certificate to confirm that it is still valid.  If the server cannot reach any of the CRLs after a period of time, the certificate can no longer be considered valid. Once a certificate is generated, the CRL for that certificate cannot be change, the certificate must be reissued with the updated list.

- The instructions above assume that certificate requests from authenticated users will be approved automatically, without requiring manual approval.  If that is not permitted in your environment, make the required changes on the template properties.

## Requesting the certificate for Management Servers, Gateways and Agents using GetSCOMCerts.ps1
After the CA has been installed and the template published, a seperate certificate will need to be requested for each Workgroup Agent and each Management Server they report to.  If you will be using Gateway Servers, and their agents are in the same trust boundary as the Gateway Servers, then each Gateway Server and Management Server they report to will need a certificate. The agents will be able to authenticate to the Gateway Server, so they should not require their own certificates.

The script _**GetSCOMCerts.ps1**_ in this repository can request the certificate and certificate chain for the specified server (MS, GW or Agent).  The script can be run from any server or workstation in the same trust boundary as the CA.

#### Required parameters
- **HostName** : This will be the name of the server you are requesting a certificate for.  If the server is a member of a domain (even if untrusted), you will need to use the FQDN of the server as the parameter.  If the server is a member of a workgroup, you will need to use only the HOST name.  The Management Server and Agent should have name resolution to each other.

- **FolderPath** : This is the location where the exported certificate will be saved.  The exported certificate and certificate chain will be saved as a PFX file.  All the temporary files and certifcates on the workstation being used to run the script will be cleaned up after the export completes.

- **Template** : This is the name of the template used when requesting the certificate and is a required parameter.  In the previous section, the sample name used was _OpsMgrCertificate_

#### Additional notes
- The script must be run with elevated credentials on the server or workstation requesting the certificates from the CA.  The domain credentials only need to have permission to request certificates.

- If the server has a DNS name that is different from the FQDN, you will need to add the _Subject Alternative Name (SAN)_ attribute to the certificate.  The first entry in the list of SAN names must be the FQDN, every subsequent entry in the list can be any DNS alias required.

- The PFX file is generated with the password "`<password>`".  You can modify the script to use any alternative password, or make it a configurable parameter.

## Installing the Certificate on the server
1) Copy the PFX file generated above to the target server matching the HostName.
1) Right-click on the PFX file and choose "Install PFX"
1) At the Certificate Installation Wizard, chose to install the certificate to the "Local Machine". Click Next.
1) Confirm the PFX file location. Click Next.
1) Enter the password for the PFX file.  Check the box _**Mark Key as Exportable**_.  Confirm the box is checked for _**Include all extended properties**_ . Click Next.
1) Select _**Automatically select the certificate store**_ option and click Next. Click Finish.

Once the certificate has been installed, you should verify that it meets all the requirements and has been installed properly.

My colleague, Tyson Paul, has written a very useful script to verify if any of the certificates installed in the local machine store meet all the requirements for certificate authentication in SCOM.  The script is included in this respository as _**OMCertCheck.ps1**_ 

_(The original link for this script and additional documentation can be found at https://gallery.technet.microsoft.com/scriptcenter/Troubleshooting-OpsMgr-27be19d3 )_

## Manual installation of Workgroup Agents
There is a PDF file in this repository named _**Workgroup Agent Deployment Process.PDF**_ 

The first part of this file explains how to install the agent manually from the command line, if it cannot be installed interactively by clicking on the MOMAgent.msi file.  

The second half of the PDF explains how to use the **MOMCertImport** utility to configure the Microsoft Monitoring Agent to use the installed certificate for communication.  The instructions in this section should be followed regardless of how the agent was installed.