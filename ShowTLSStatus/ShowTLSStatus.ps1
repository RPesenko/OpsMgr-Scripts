<# 
    ShowTLSStatus.ps1
    
    Displays certain key registry settings required for TLS 1.2 only support 
    Note:  This is a quick check of key registry settings for OS
           Certain applications may require additional configurations
#>

# =============================================
Write-Host "Checking .Net Version from Registry" -ForegroundColor Cyan

$RegPath = "HKLM:\\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\"
[int]$ReleaseRegValue = (Get-ItemProperty $RegPath).Release
If ($ReleaseRegValue -ge 393295){
    Write-Host ".NET version is 4.6 or later" -ForegroundColor Green
}
Else {
    Write-Host ".NET Version is NOT 4.6 or later" -ForegroundColor Magenta
}

# =============================================
Write-Host "`nEvaluating SChannel Protocols" -ForegroundColor Cyan

$ProtocolList       = @("SSL 2.0","SSL 3.0","TLS 1.0", "TLS 1.1", "TLS 1.2")
$ProtocolSubKeyList = @("Client", "Server")
$DisabledByDefault = "DisabledByDefault"
$Enabled = "Enabled"
$registryPath = "HKLM:\\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\"

foreach($Protocol in $ProtocolList)
{
	foreach($key in $ProtocolSubKeyList)
	{		
		$currentRegPath = $registryPath + $Protocol + "\" + $key
		if(!(Test-Path $currentRegPath))
		{
            Write-Host $Protocol " : " $key
            Write-Host "  Registry path not found" -ForegroundColor Magenta
		}
		else
		{
            Write-Host $Protocol " : " $key
            Write-Host "  Registry path exists" -ForegroundColor Green

            $EnabledVal = $currentRegPath + "\" + $Enabled
            $DbyDVal = $currentRegPath + "\" + $DisabledByDefault
            If (Get-ItemProperty -Path $currentRegPath -Name Enabled -ErrorAction SilentlyContinue) {
                Write-Host "    Value of Enabled: " (Get-ItemProperty -Path $currentRegPath).Enabled -ForegroundColor Green
            }
            Else {
                Write-Host "    Enabled key not present" -ForegroundColor Magenta
            }

            If (Get-ItemProperty -Path $currentRegPath -Name DisabledByDefault -ErrorAction SilentlyContinue) {
                Write-Host "    Value of DisabledByDefault: " (Get-ItemProperty -Path $currentRegPath).DisabledByDefault -ForegroundColor Green
            }
            Else {
                Write-Host "    DisabledByDefault key not present" -ForegroundColor Magenta
            }
		}	
	}
}

# =============================================
Write-Host "`nEvaluating .NET Framework StrongCrypto settings" -ForegroundColor Cyan

$StrongCrypto35WoWkey = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727"
$StrongCrypto40WoWkey = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319"
$StrongCrypto35key = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727"
$StrongCrypto40key = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"

# Check 32-bit keys for .Net 3.5 and 4.0
If (Get-ItemProperty -Path $StrongCrypto35WoWkey -Name SchUseStrongCrypto -ErrorAction SilentlyContinue) {
    Write-Host "  Value of SchUseStrongCrypto: " (Get-ItemProperty -Path $StrongCrypto35WoWkey).SchUseStrongCrypto -ForegroundColor Green
}
Else {
    Write-Host "  SchUseStrongCrypto key not present at $StrongCrypto35WoWkey" -ForegroundColor Magenta
}

If (Get-ItemProperty -Path $StrongCrypto40WoWkey -Name SchUseStrongCrypto -ErrorAction SilentlyContinue) {
    Write-Host "  Value of SchUseStrongCrypto: " (Get-ItemProperty -Path $StrongCrypto40WoWkey).SchUseStrongCrypto -ForegroundColor Green
}
Else {
    Write-Host "  SchUseStrongCrypto key not present at $StrongCrypto40WoWkey" -ForegroundColor Magenta
}

# Check 64-bit keys for .Net 3.5 and 4.0
If (Get-ItemProperty -Path $StrongCrypto35key -Name SchUseStrongCrypto -ErrorAction SilentlyContinue) {
    Write-Host "  Value of SchUseStrongCrypto: " (Get-ItemProperty -Path $StrongCrypto35key).SchUseStrongCrypto -ForegroundColor Green
}
Else {
    Write-Host "  SchUseStrongCrypto key not present at $StrongCrypto35key" -ForegroundColor Magenta
}

If (Get-ItemProperty -Path $StrongCrypto40key -Name SchUseStrongCrypto -ErrorAction SilentlyContinue) {
    Write-Host "  Value of SchUseStrongCrypto: " (Get-ItemProperty -Path $StrongCrypto40key).SchUseStrongCrypto -ForegroundColor Green
}
Else {
    Write-Host "  SchUseStrongCrypto key not present at $StrongCrypto40key" -ForegroundColor Magenta
}
