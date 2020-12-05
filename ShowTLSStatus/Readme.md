# ShowTLSStatus
Many enterprises have security requirements to disable certain SChannel protocols or harden the OS against attack.  This may affect the ability of some applications and workloads to communicate properly over the network.  This script can quickly show key registry settings related to these configuration settings without requiring administrators to leverage the Regististry Editor.

- The key **"HKLM:\\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\release"** is checked to verify the server is at .NET 4.6 or later

- If any of the following SChannel protocol keys are detected, the **Server** and **Client** subkeys are checked for the **"enabled"** and **"DisabledByDefault"** values.
    * SSL 2.0
    * SSL 3.0
    * TLS 1.0
    * TLS 1.1
    * TLS 1.2

- The value of **SchUseStrongCrypto** is checked (if it exists) for .NET 3.5 and .NET 4.0 in the 32-bit and 64-bit registry.

**Note 1:** This script must be run under elevated credentials to read the registry.

**Note 2:** Many applications and workloads may require additional settings and configurations to run properly in an environment where certain SChannel protocols are disabled and the OS has been hardened.  Please refer to your vendor's documentation for full compatibility requirements.