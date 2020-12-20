<# 
ShowTLSStatus.ps1
    Version: 2.0    
    Release 2020/12/19
    
Displays certain key registry settings required for TLS 1.2 only support 
Will create 
Note:  This is a quick check of key registry settings for OS
        Certain applications may require additional configurations
#>

PARAM (
    [String] $action
)

function SetValues {
    param (
        [string]$Path,
        [String]$value,
        [int]$data
    )
    Try {
        Set-ItemProperty -Path $currentRegPath -Name $value -Value $data -Force -ErrorAction Stop| Out-Null
        Write-Host "    Setting Key value $value to $data" -ForegroundColor Green
    }
    Catch {
        Write-Host "  " $_.Exception.Message -ForegroundColor Red
    }
    Return
}

function CreateValues {
    param (
        [string]$Path,
        [String]$value,
        [int]$data
    )
    Try {
        New-ItemProperty -Path $currentRegPath -Name $value -Value $data -PropertyType DWORD -Force -ErrorAction Stop| Out-Null
        Write-Host "    Adding Key value $data to $value" -ForegroundColor Green
    }
    Catch {
        Write-Host "  " $_.Exception.Message -ForegroundColor Red
    }
    Return
}

function CreateKey {
    param (
        [String]$KeyPath,
        [bool]$Enabled
    )
    Try {
        New-Item -Path $KeyPath -Force -ErrorAction Stop| out-Null
        Write-Host "    Created subkey for $KeyPath" -ForegroundColor Green
    }
    Catch [UnauthorizedAccessException] {
        Write-Host " Permission Denied. Run script from elevated credentials." -ForegroundColor Red
    }
    Catch {
        Write-Host "  " $_.Exception.Message -ForegroundColor Red
    }
    If ($Enabled){
        CreateValues $KeyPath 'Enabled' 1
        CreateValues $KeyPath 'DisabledByDefault' 0
    }
    Else {
        CreateValues $KeyPath 'Enabled' 0
        CreateValues $KeyPath 'DisabledByDefault' 1
    }
    
    Return
}

# ===========================================================
# MAIN

# ============================================= 
Write-Host "Checking .Net Version from Registry" -ForegroundColor Cyan

$NetRegPath = "HKLM:\\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\"
[int]$ReleaseRegValue = (Get-ItemProperty $NetRegPath).Release
If ($ReleaseRegValue -ge 460798){
    Write-Host "   .NET version is 4.7 or later" -ForegroundColor Green
}
Else {
    Write-Host "   .NET Version is NOT 4.7 or later" -ForegroundColor Magenta
}

# =============================================
Write-Host "`nEvaluating SChannel Protocols" -ForegroundColor Cyan

# Specify Action to take
If (($action -eq "create") -or ($action -eq "TLS12only")){
    If ($action -eq "TLS12only"){
        Write-Host "Configuring protocol keys for TLS 1.2 only support" -ForegroundColor Yellow
    }
    Else {
        Write-Host "Configuring all protocol keys as enabled" -ForegroundColor Yellow
    }
}
Else {
    Write-Host "Dislplaying configured values only, no changes will be made." -ForegroundColor Yellow
}

$ProtocolList       = @("SSL 2.0","SSL 3.0","TLS 1.0", "TLS 1.1", "TLS 1.2")
$ProtocolSubKeyList = @("Client", "Server")
$SChanRegPath = "HKLM:\\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\"

# Loop through each protocol and subkey
foreach($Protocol in $ProtocolList){
	foreach($key in $ProtocolSubKeyList){		
		$currentRegPath = $SChanRegPath + $Protocol + "\" + $key
        # Check if the key and subkey exists
        if(!(Test-Path $currentRegPath)){
            Write-Host $Protocol " : " $key -ForegroundColor Cyan
            Write-Host "  Registry path not found" -ForegroundColor Magenta
            # Create the key if it does not exist and a configuration action was specified
            if (($action -eq "create") -or ($action -eq "TLS12only")){
                # Set defaults for TLS 1.2 only support
                If ($action -eq "TLS12only"){
                    # Set all keys to disabled other than TLS 1.2
                    If ($Protocol -eq "TLS 1.2"){
                        CreateKey $currentRegPath $true
                    }
                    Else {
                        CreateKey $currentRegPath $false
                    }
                }
                # Set all protocols to enabled if action is specified as create
                else {
                    CreateKey $currentRegPath $true
                }
            }
		}
        # If key and subkey exist, display values
        else {
            Write-Host $Protocol " : " $key -ForegroundColor Cyan
            Write-Host "  Registry path exists" -ForegroundColor Green
            # Check Enabled value for each subkey
            $EnabledValue = (Get-ItemProperty -Path $currentRegPath -ErrorAction SilentlyContinue).Enabled
            If ($null -ne $EnabledValue) {
                Write-Host "    Value of Enabled: " $EnabledValue -ForegroundColor Green
                # If value exists and configuration option was selected, verify value is set correctly
                If (($action -eq "create") -or ($action -eq "TLS12only")){
                    # Set values for TLS 1.2 only configuration
                    If ($action -eq "TLS12only"){
                        If ($Protocol -eq "TLS 1.2"){
                            If ($EnabledValue -ne 1){
                                SetValues $currentRegPath "Enabled" 1
                            }
                        }
                        Else {
                            If ($EnabledValue -ne 0){
                                SetValues $currentRegPath "Enabled" 0
                            }
                        }
                    }
                    # Set default values for all keys in non-TLS 1.2 only mode if not already configured
                    Else {
                        If ($EnabledValue -ne 1){
                            SetValues $currentRegPath "Enabled" 1
                        }
                    } 
                }
            }
            Else {
                # If enabled value does not exist, create it
                Write-Host "    Enabled key not present" -ForegroundColor Magenta
                if (($action -eq "create") -or ($action -eq "TLS12only")){
                    # Set defaults for TLS 1.2 only support
                    If ($action -eq "TLS12only"){
                        # Set all values to disabled other than TLS 1.2
                        If ($Protocol -eq "TLS 1.2"){
                            CreateValues $currentRegPath 'Enabled' 1
                        }
                        Else {
                            CreateValues $currentRegPath 'Enabled' 0
                        }
                    }
                    # Set all protocols to enabled if action is specified as create
                    else {
                        CreateValues $currentRegPath 'Enabled' 1
                    }
                }
            }
            # Check DisbledByDefault value for each subkey
            $DbDValue = (Get-ItemProperty -Path $currentRegPath -ErrorAction SilentlyContinue).DisabledByDefault
            If ($null -ne $DbDValue) {
                Write-Host "    Value of DisabledByDefault: " $DbDValue -ForegroundColor Green
                # If value exists and configuration option was selected, verify value is set correctly
                If (($action -eq "create") -or ($action -eq "TLS12only")){
                    # Set values for TLS 1.2 only configuration
                    If ($action -eq "TLS12only"){
                        If ($Protocol -eq "TLS 1.2"){
                            If ($DbDValue -ne 0){
                                SetValues $currentRegPath "DisabledByDefault" 0
                            }
                        }
                        Else {
                            If ($DbDValue -ne 1){
                                SetValues $currentRegPath "DisabledByDefault" 1
                            }
                        }
                    }
                    # Set default values for all keys in non-TLS 1.2 only mode if not already configured
                    Else {
                        If ($DbDValue -ne 0){
                            SetValues $currentRegPath "DisabledByDefault" 0
                        }
                    } 
                }
            }
            Else {
                # If DisabledByDefault value does not exist, create it
                Write-Host "    DisabledByDefault key not present" -ForegroundColor Magenta
                if (($action -eq "create") -or ($action -eq "TLS12only")){
                    # Set defaults for TLS 1.2 only support
                    If ($action -eq "TLS12only"){
                        # Set all values to disabled other than TLS 1.2
                        If ($Protocol -eq "TLS 1.2"){
                            CreateValues $currentRegPath 'DisabledByDefault' 0
                        }
                        Else {
                            CreateValues $currentRegPath 'DisabledByDefault' 1
                        }
                    }
                    # Set all protocols to enabled if action is specified as create
                    else {
                        CreateValues $currentRegPath 'DisabledByDefault' 0
                    }
                }
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
$CryptoKeyList = @($StrongCrypto35WoWkey,$StrongCrypto40WoWkey,$StrongCrypto35key,$StrongCrypto40key)

Foreach ($Key in $CryptoKeyList){
    If (Get-ItemProperty -Path $Key -Name SchUseStrongCrypto -ErrorAction SilentlyContinue) {
        Write-Host "  Value of SchUseStrongCrypto: " (Get-ItemProperty -Path $Key).SchUseStrongCrypto -ForegroundColor Green
    }
    Else {
        Write-Host "  SchUseStrongCrypto key not present at $Key" -ForegroundColor Magenta
    }
}
