# OMv3CertCheck.ps1
#
# Original Publish Date 1/2009
#    (Lincoln Atkinson?, https://blogs.technet.microsoft.com/momteam/author/latkin/ )
#
# Update 2017.11.17 (Tyson Paul, https://blogs.msdn.microsoft.com/tysonpaul/ )
#    Fixed certificate SerialNumber parsing error. 
#
# Update 2/2009
#    Fixes for subjectname validation
#    Typos
#    Modification for CA chain validation
#    Adds needed check for MachineKeyStore property on the private key
#
# Update 7/2009
#    Fix for workgroup machine subjectname validation
#

# Consider all certificates in the Local Machine "Personal" store
$certs = [Array] (dir cert:\LocalMachine\my\)

write-host "Checking that there are certs in the Local Machine Personal store..."
if ($certs -eq $null)
{
    Write-Host "There are no certs in the Local Machine `"Personal`" store."
    Write-Host "This is where the client authentication certificate should be imported."
    Write-Host "Check if certificates were mistakenly imported to the Current User"
    Write-Host "`"Personal`" store or the `"Operations Manager`" store."
    exit
}

write-host "Verifying each cert..."
foreach ($cert in $certs)
{
    write-host "`nExamining cert - Serial number $($cert.SerialNumber)"
    write-host "---------------------------------------------------"

    $pass = $true
      
    # Check subjectname
          
    $pass = &{
        $fqdn = $env:ComputerName
        $fqdn += "." + [DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name
        trap [DirectoryServices.ActiveDirectory.ActiveDirectoryObjectNotFoundException]
        {
            # Not part of a domain
            continue;
        }
            
        $fqdnRegexPattern = "CN=" + $fqdn.Replace(".","\.") + '(,.*)?$'
            
        if (!( $cert.SubjectName.Name -match $fqdnRegexPattern ))
        {
            Write-Host "Cert subjectname" -BackgroundColor Red -ForegroundColor Black
            Write-Host "`tThe SubjectName of this cert does not match the FQDN of this machine."
            Write-Host "`tActual - $($cert.SubjectName.Name)"
            Write-Host "`tExpected (case insensitive)- CN=$fqdn"
            $false
        } else { $true; Write-Host "Cert subjectname" -BackgroundColor Green -ForegroundColor Black }
    }
      
    # Verify private key
            
    if (!( $cert.HasPrivateKey ))
    {
        Write-Host "Private key" -BackgroundColor Red -ForegroundColor Black
        Write-Host "`tThis certificate does not have a private key."
        Write-Host "`tVerify that proper steps were taken when installing this cert."
        $pass = $false
    } elseif (!($cert.PrivateKey.CspKeyContainerInfo.MachineKeyStore))
    {
        Write-Host "Private key" -BackgroundColor Red -ForegroundColor Black
        Write-Host "`tThis certificate's private key is not issued to a machine account."
        Write-Host "`tOne possible cause of this is that the certificate"
        Write-Host "`twas issued to a user account rather than the machine,"
        Write-Host "`tthen copy/pasted from the Current User store to the Local"
        Write-Host "`tMachine store.  A full export/import is required to switch"
        Write-Host "`tbetween these stores."
        $pass = $false
    }
    else { Write-Host "Private key" -BackgroundColor Green -ForegroundColor Black }

    # Check expiration dates
            
    if (($cert.NotBefore -gt [DateTime]::Now) -or ($cert.NotAfter -lt [DateTime]::Now))
    {
        Write-Host "Expiration" -BackgroundColor Red -ForegroundColor Black
        Write-Host "`tThis certificate is not currently valid."
        Write-Host "`tIt will be valid between $($cert.NotBefore) and $($cert.NotAfter)"
        $pass = $false
    } else { Write-Host "Expiration" -BackgroundColor Green -ForegroundColor Black }
      
      
    # Enhanced key usage extension
            
    $enhancedKeyUsageExtension = $cert.Extensions |? {$_.ToString() -match "X509EnhancedKeyUsageExtension"}
    if ($enhancedKeyUsageExtension -eq $null)
    {
        Write-Host "Enhanced Key Usage Extension" -BackgroundColor Red -ForegroundColor Black
        Write-Host "`tNo enhanced key usage extension found.`n"
        $pass = $false
    }
    else
    {
        $usages = $enhancedKeyUsageExtension.EnhancedKeyUsages
        if ($usages -eq $null)
        {
            Write-Host "Enhanced Key Usage Extension" -BackgroundColor Red -ForegroundColor Black
            Write-Host "`tNo enhanced key usages found.`n"
            $pass = $false
        }
        else
        {
            $srvAuth = $cliAuth = $false
            foreach ($usage in $usages)
            {
                if ($usage.Value -eq "1.3.6.1.5.5.7.3.1") { $srvAuth = $true}
                if ($usage.Value -eq "1.3.6.1.5.5.7.3.2") { $cliAuth = $true}
            }
            if ((!$srvAuth) -or (!$cliAuth))
            {
                Write-Host "Enhanced Key Usage Extension" -BackgroundColor Red -ForegroundColor Black
                Write-Host "`tEnhanced key usage extension does not meet requirements."
                Write-Host "`tRequired EKUs are 1.3.6.1.5.5.7.3.1 and 1.3.6.1.5.5.7.3.2"
                Write-Host "`tEKUs found on this cert are:"
                $usages |%{ Write-Host "`t$($_.Value)" }
                $pass = $false
            }
            else { Write-Host "Enhanced Key Usage Extension" -BackgroundColor Green -ForegroundColor Black }
        }
    }
      
    # KeyUsage extension
      
    $keyUsageExtension = $cert.Extensions |? {$_.ToString() -match "X509KeyUsageExtension"}
    if ($keyUsageExtension -eq $null)
    {
        Write-Host "Key Usage Extensions" -BackgroundColor Red -ForegroundColor Black
        Write-Host "`tNo key usage extension found."
        Write-Host "`tA KeyUsage extension matching 0xA0 (Digital Signature, Key Encipherment)"
        Write-Host "`tor better is required."
        $pass = $false
    }
    else
    {
        $usages = $keyUsageExtension.KeyUsages
        if ($usages -eq $null)
        {
            Write-Host "Key Usage Extensions" -BackgroundColor Red -ForegroundColor Black
            Write-Host "`tNo key usages found."
            Write-Host "`tA KeyUsage extension matching 0xA0 (DigitalSignature, KeyEncipherment)"
            Write-Host "`tor better is required."
            $pass = $false
        }
        else
        {
            if (($usages.value__ -band 0xA0) -ne 0xA0)
            {
                Write-Host "Key Usage Extensions" -BackgroundColor Red -ForegroundColor Black
                Write-Host "`tKey usage extension exists but does not meet requirements."
                Write-Host "`tA KeyUsage extension matching 0xA0 (Digital Signature, Key Encipherment)"
                Write-Host "`tor better is required."
                Write-Host "`tKeyUsage found on this cert matches:"
                Write-Host "`t$usages"
                $pass = $false
            } else { Write-Host "Key Usage Extensions" -BackgroundColor Green -ForegroundColor Black }
        }
    }
      
    # KeySpec
            
    $keySpec = $cert.PrivateKey.CspKeyContainerInfo.KeyNumber
    if ($keySpec -eq $null)
    {
        Write-Host "KeySpec" -BackgroundColor Red -ForegroundColor Black
        Write-Host "`tKeyspec not found.  A KeySpec of 1 is required"
        $pass = $false
    }
    elseif ($keySpec.value__ -ne 1)
    {
        Write-Host "KeySpec" -BackgroundColor Red -ForegroundColor Black
        Write-Host "`tKeyspec exists but does not meet requirements."
        Write-Host "`tA KeySpec of 1 is required."
        Write-Host "`tKeySpec for this cert: $($keySpec.value__)"
        $pass = $false
    } else {Write-Host "KeySpec" -BackgroundColor Green -ForegroundColor Black}
      
      
    # Check that serial is written to proper reg
            
    $certSerial = $cert.SerialNumber
    $certSerialReversed = ""
    -1..-19 |% {$certSerialReversed += $certSerial[2*$_] + $certSerial[2*$_ + 1]}
  
    if (! (Test-Path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings"))
    {
        Write-Host "Serial number written to registry" -BackgroundColor Red -ForegroundColor Black
        Write-Host "`tThe cert serial number is not written to registry."
        Write-Host "`tNeed to run MomCertImport.exe"
        $pass = $false
    }
    else
    {
        $regKeys = get-itemproperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings"
        if ($regKeys.ChannelCertificateSerialNumber -eq $null)
        {
            Write-Host "Serial number written to registry" -BackgroundColor Red -ForegroundColor Black
            Write-Host "`tThe cert serial number is not written to registry."
            Write-Host "`tNeed to run MomCertImport.exe"
            $pass = $false
        }
        else
        {
            $regSerial = ""
            $regKeys.ChannelCertificateSerialNumber |% {$regSerial += $_.ToString("X2")}
                  
            if ($regSerial -ne $certSerialReversed)
            {
                Write-Host "Serial number written to registry" -BackgroundColor Red -ForegroundColor Black
                Write-Host "`tThe serial number written to the registry does not match this certificate"
                Write-Host "`tExpected registry entry: $certSerialReversed"
                Write-Host "`tActual registry entry:   $regSerial"
                $pass = $false
            } else { Write-Host "Serial number written to registry" -BackgroundColor Green -ForegroundColor Black }
        }
    }


    # Check that the cert's issuing CA is trusted (This is not technically required
    # as it is the remote machine cert's CA that must be trusted.  Most users leverage
    # the same CA for all machines, though, so it's worth checking

    $chain = new-object Security.Cryptography.X509Certificates.X509Chain
    $chain.ChainPolicy.RevocationMode = 0
    if ($chain.Build($cert) -eq $false )
    {
        Write-Host "Certification chain" -BackgroundColor Yellow -ForegroundColor Black
        Write-Host "`tThe following error occurred building a certification chain with this cert:"
        Write-Host "`t$($chain.ChainStatus[0].StatusInformation)"
        write-host "`tThis is an error if the certificates on the remote machines are issued"
        write-host "`tfrom this same CA - $($cert.Issuer)"
        write-host "`tPlease ensure the certificates for the CAs which issued the certificates configured"
        write-host "`ton the remote machines is installed to the Local Machine Trusted Root Authorities"
        write-host "`tstore on this machine."
    }
    else
    {
        $rootCaCert = $chain.ChainElements | select -property Certificate -last 1
        $localMachineRootCert = dir cert:\LocalMachine\Root |? {$_ -eq $rootCaCert.Certificate}
        if ($localMachineRootCert -eq $null)
        {
            Write-Host "Certification chain" -BackgroundColor Yellow -ForegroundColor Black
            Write-Host "`tThis certificate has a valid certification chain installed, but"
            Write-Host "`ta root CA certificate verifying the issuer $($cert.Issuer)"
            Write-Host "`twas not found in the Local Machine Trusted Root Authorities store."
            Write-Host "`tMake sure the proper root CA certificate is installed there, and not in"
            Write-Host "`tthe Current User Trusted Root Authorities store."
        }
        else
        {
            Write-Host "Certification chain" -BackgroundColor Green -ForegroundColor Black
            Write-Host "`tThere is a valid certification chain installed for this cert,"
            Write-Host "`tbut the remote machines' certificates could potentially be issued from"
            Write-Host "`tdifferent CAs.  Make sure the proper CA certificates are installed"
            Write-Host "`tfor these CAs."
        }

    }


    if ($pass) { Write-Host "`n***This certificate is properly configured and imported for Ops Manager use.***" }
}