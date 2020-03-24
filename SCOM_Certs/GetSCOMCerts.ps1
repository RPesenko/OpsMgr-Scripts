PARAM
(
	[Parameter(Mandatory=$true)][string] $HostName, 
    [Parameter(Mandatory=$true)][string] $FolderPath,
    [Parameter(Mandatory=$true)][string] $Template 
)

$INFPath = "$($FolderPath)\$($HostName)_.inf"
$REQPath = "$($FolderPath)\$($HostName)_.req"
$PFXPath = "$($FolderPath)\$($HostName)_cert.pfx"

$Signature = '$Windows NT$' #signature is operating system family, can execute without it, but better to specify
$INF =
@"
[Version]
Signature= "$Signature" 

[NewRequest]
Subject = "CN=$HostName"
KeySpec = 1
KeyLength = 2048
Exportable = TRUE
MachineKeySet = TRUE
KeyUsage = 0xf0

[EnhancedKeyUsageExtension]
OID=1.3.6.1.5.5.7.3.1
OID=1.3.6.1.5.5.7.3.2

[RequestAttributes]
CertificateTemplate = $Template
"@

Write-Host "Creating CertificateRequest(CSR) for $HostName in $FolderPath `r " -ForegroundColor Yellow
$INF | out-file -filepath $INFPath -force
certreq -new $INFPath $REQPath  

write-Host "Certificate Request is being submitted `r " -ForegroundColor Yellow
certreq -submit $REQPath $FolderPath\$HostName.cer 

write-Host "Certificate Request is being accepted and installed `r " -ForegroundColor Yellow
certreq -accept $FolderPath\$HostName.cer

write-Host "Exporting Certificate and cleaning up `r " -ForegroundColor Yellow
$thumb = (get-childitem Cert:\LocalMachine\my\ |where {$_.Subject -eq "CN=$($HostName)"}).Thumbprint

#Export PFX for server
$pwd  = "<password>"                    
$pwd = ConvertTo-SecureString -String $pwd -Force -AsPlainText
Export-PfxCertificate -cert "cert:\localmachine\my\$thumb" -FilePath $PFXPath -Password $pwd

#Clean up Temporary files
Remove-Item "cert:\localmachine\my\$thumb"
Remove-item $FolderPath\$HostName.cer
Remove-item $FolderPath\$HostName.rsp
Remove-item $REQPath
Remove-item $INFPath