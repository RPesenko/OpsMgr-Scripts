<#  
MPCatalogGet.ps1
    Version: 1.1    
    Release 2020/12/16

Script to get offline copy of MP Catalog for comparison to installed MP
Designed for use when MS is not online and native Updates and Recommendation feature can't be used.
SCOM 2012/2016/2019 version update :  Rich Pesenko 12/8/2020
Based on Check-MPUpdates.ps1 by Daniele Muscetta 8/12/2009 (https://www.muscetta.com/2008/11/29/programmatically-check-for-management-pack-updates-in-opsmgr-2007-r2/)
#>

Param (
    [string] $Folder = "C:\temp"
)

If (!(Test-path $folder)){
	New-item -Path $folder -itemtype Directory
}

$Filename = "MPCatalog.XML"
$OutFile = $Folder + "\" + $Filename

$url = "https://www.microsoft.com/mpdownload/ManagementPackCatalogWebService.asmx"

$message = @"
<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
    <soap12:Body>
        <FindManagementPacks xmlns="http://microsoft.com/webservices/">
            <criteria>
                <ManagementPackNamePattern>%</ManagementPackNamePattern>
                <VendorNamePattern>%</VendorNamePattern>
                <ReleasedOnOrAfter>2000-01-01T00:00:00</ReleasedOnOrAfter>
            </criteria>
            <productInfo>
                <ProductName>Operations Manager</ProductName>
                <ProductVersion>10.19.10407.0</ProductVersion>
            </productInfo>
            <threeLetterLanguageCode>ENU</threeLetterLanguageCode>
        </FindManagementPacks>
    </soap12:Body>
</soap12:Envelope>
"@

$Wcl = new-object System.Net.WebClient
$Wcl.Headers.Add(“user-agent”, “PowerShell Script”)
$Wcl.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

$req = [system.Net.HttpWebRequest]::Create($url)
$req.Headers.Add("SOAPAction", "http://microsoft.com/webservices/FindManagementPacks")
$req.ContentType = "text/xml; charset=utf-8"
$req.Accept = "text/xml"
$req.Method = "POST"

$s = $req.GetRequestStream()
$s.Write([System.Text.Encoding]::ASCII.GetBytes($message), 0, $message.Length)
$s.Close()

$resp = $req.GetResponse()

$sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
$XMLResult = $sr.ReadToEnd()
$xml = [xml]$XMLResult

$CatalogItems = $XML.Envelope.Body.FindManagementPacksResponse.FindManagementPacksResult.CatalogItem
$CatalogMP = $CatalogItems | ? { $_.isManagementpack -eq "True" }
$PublishedList = @()
foreach ($mp in $CatalogMP) {
    $PublishedMP = [PSCustomObject]@{
        MPName    = $mp.SystemName
        MPVersion = $mp.Identity.Version
        MPDate    = $mp.ReleaseDate
        Display   = $mp.DisplayName
    }
    $PublishedList += $PublishedMP
}

#  Export list to CliXML file for comparison with installed MP
$PublishedList | Export-Clixml -Path $OutFile


#  Display Name and version of every MP in an interactive GridView
#   $PublishedList |sort MPName, MPVersion|Out-GridView


