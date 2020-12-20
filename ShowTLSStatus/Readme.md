# ShowTLSStatus.ps1
Version: 2.0    
Release 2020/12/19

Many enterprises have security requirements to disable certain SChannel protocols or harden the OS against attack.  This may affect the ability of some applications and workloads to communicate properly over the network.  This script can quickly show key registry settings related to these configuration settings without requiring administrators to leverage the Regististry Editor.

- The key **"HKLM:\\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\release"** is checked to verify the server is at .NET 4.7 or later.  By default, .NET Framework 4.7 and later versions is configured to use TLS 1.2 but will allow connections using TLS 1.1 or TLS 1.0.  WCF if configured to allow the OS to decide the best security protocol.

- If any of the following SChannel protocol keys are detected, the **Server** and **Client** subkeys are checked for the **"enabled"** and **"DisabledByDefault"** values.
    * SSL 2.0
    * SSL 3.0
    * TLS 1.0
    * TLS 1.1
    * TLS 1.2

**NOTE:** If the _create_ or _TLS12only_ switches are used, these keys will be created.  See **"Usage"** section for additional details.

- The value of **SchUseStrongCrypto** is checked (if it exists) for .NET 3.5 and .NET 4.0 in the 32-bit and 64-bit registry.

## Usage:
**ShowTLSStatus.ps1**   
Only display .NET Framework level, values of protocol registry keys (if they exist) and values of Strong Cryptography keys (if they exist)

**ShowTLSStatus.ps1 create**    
Only display .NET Framework level and values of Strong Cryptography keys (if they exist).   
Will create any SChannel protocol keys, set the "Enabled" value to 1 and the "DisabledByDefault" value to 0 for all keys.   
If any value is missing, it will be created with default values.    
If the values already exist, but with different values, the _create_ switch will set them all to default.

**ShowTLSStatus.ps1 TLS12only**     
Only display .NET Framework level and values of Strong Cryptography keys (if they exist).   
Will create any SChannel protocol keys, set the "Enabled" value to 1 and the "DisabledByDefault" value to 0 for TLS 1.2 protocols.  All other keys will be configured with "Enabled" at 0 and "DisabledByDefault" at 1.   
If any value is missing, it will be created with the above values.    
If the values already exist, but are not configured as above, the _TLS12only_ switch will set the values to the above settings.

The script can be run multiple times with the _create_ and _TLS12only_ switches to toggle the "Enabled" and "DisabledByDefault" values for the protocol keys.

**Note 1:** This script must be run under elevated credentials to read the registry.

**Note 2:** Many applications and workloads may require additional settings and configurations to run properly in an environment where certain SChannel protocols are disabled and the OS has been hardened.  Please refer to your vendor's documentation for full compatibility requirements.

## View Script    
_(Right click and select 'Save Link As' to download)_    
https://github.com/RPesenko/OpsMgr-Scripts/blob/master/ShowTLSStatus/ShowTLSStatus.ps1

## Change Log  
2.0: Provided _create_ and _TLS12only_ switches to create and configure protocol key values.   
1.1: Updates to documentation   
1.0: Initial release   