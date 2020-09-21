<#
    List_Schan.PS1  
    Purpose: Display or modify the SChannel registry settings on a Windows Server

    Parameter:
        $create     :  Create registry settings if missing, all set to enabled
        $onlyTLS12  :  Create registry settings if missing, only set TLS 1.2 enabled
        <none>/default : only display the values of the keys, or if they exist
#>

PARAM (
    $action = ""
)

# Deternine action, otherwise, just list values
$create = $false       # Create registry settings if missing, all set to enabled
$onlyTLS12 = $false     # Create registry settings if missing, only set TLS 1.2 enabled

If ($action.tolower() -eq 'create') {
    $create = $true
}

If ($action.tolower() -eq 'onlytls12') {
    $onlyTLS12 = $true
}

# Define protocols and registry keys
$ProtocolList       = @("SSL 2.0","SSL 3.0","TLS 1.0", "TLS 1.1", "TLS 1.2")  
$ProtocolSubKeyList = @("Client", "Server")  
$ProtoRegistryPath = "HKLM:\\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\"  
$DisabledByDefault = "DisabledByDefault"  
$Enabled = "Enabled"  
$NetRegistryPath1 = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"
$NetRegistryPath2 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319"


Write-Host "Reviewing Protocol settings"  
# Loop through each SChannel protocol
foreach($Protocol in $ProtocolList) {  

    #Loop through each subkey for the protocol
    foreach($key in $ProtocolSubKeyList)     {  
        $currentRegPath = $ProtoRegistryPath + $Protocol + "\" + $key  
        $currentsubkey = $Protocol + "\" + $key
        
        # Display status of registry key for the protocol
        if(!(Test-Path $currentRegPath)) {  
            Write-Host $currentsubkey "registry key does not exist"   -ForegroundColor Magenta 
            If($create){
                Write-Host "    Creating the registry entry for this protocol"  -ForegroundColor Yellow
                Try {
                    New-Item -Path $currentRegPath -Force -ErrorAction Stop| out-Null
                    Write-Host "    Created subkey for $currentsubkey" -ForegroundColor Green
                }
                Catch [UnauthorizedAccessException] {
                    Write-Host " Permission Denied. Run script from elevated credentials." -ForegroundColor Red
                }
                Catch {
                    Write-Host "  " $_.Exception.Message -ForegroundColor Red
                }
            }
        }  
        Else {
            Write-Host $currentsubkey "registry key exists" -ForegroundColor Green
        }

        # Display values for registry subkey
        if(Test-Path $currentRegPath) {  
            $dd = (Get-ItemProperty -Path $currentRegPath).$DisabledByDefault
            If ($dd -eq 0 -or $dd -eq 1) {
                Write-Host "  Key Value for $DisabledByDefault is $dd"
            }
            # Populate value for Disabled by Default if it does not already exist, don't disable any protocols
            else {
               Write-Host "  Key value for $DisabledByDefault is missing" -ForegroundColor Magenta
               If ($create) {
                    Write-Host "    Adding Key value 0 to $DisabledByDefault" -ForegroundColor Yellow
                    Try {
                       New-ItemProperty -Path $currentRegPath -Name $DisabledByDefault -Value "0" -PropertyType DWORD -Force -ErrorAction Stop| Out-Null
                       Write-Host "    Added Key value 0 to $DisabledByDefault" -ForegroundColor Green
                    }
                    Catch {
                        Write-Host "  " $_.Exception.Message -ForegroundColor Red
                    }
               }
               # Populate value for Disabled by Default if it does not already exist, disable all protocols except TLS 1.2
               If ($onlyTLS12) {
                    if($Protocol -eq "TLS 1.2") {
                        Write-Host "    Adding Key value 0 to $DisabledByDefault" -ForegroundColor Yellow
                        Try {
                            New-ItemProperty -Path $currentRegPath -Name $DisabledByDefault -Value "0" -PropertyType DWORD -Force -ErrorAction Stop| Out-Null
                            Write-Host "    Added Key value 0 to $DisabledByDefault" -ForegroundColor Green
                        }
                        Catch {
                            Write-Host "  " $_.Exception.Message -ForegroundColor Red
                        }
                    }
                    Else {
                        Write-Host "    Adding Key value 1 to $DisabledByDefault" -ForegroundColor Yellow
                        Try {
                            New-ItemProperty -Path $currentRegPath -Name $DisabledByDefault -Value "1" -PropertyType DWORD -Force -ErrorAction Stop| Out-Null
                            Write-Host "    Added Key value 1 to $DisabledByDefault" -ForegroundColor Green
                        }
                        Catch {
                            Write-Host "  " $_.Exception.Message -ForegroundColor Red
                        }
                    }
               }
            }
            $en = (Get-ItemProperty -Path $currentRegPath).$Enabled
            If ($en -eq 0 -or $en -eq 1) {
                Write-Host "  Key Value for $Enabled is $en"
            }
            # Populate value for Enabled if it does not already exist, don't disable any protocols
            else {
                Write-Host "  Key value for $Enabled is missing" -ForegroundColor Magenta
                If ($create) {
                    Write-Host "    Adding Key value 1 to $Enabled" -ForegroundColor Yellow
                    Try {
                        New-ItemProperty -Path $currentRegPath -Name $Enabled -Value "1" -PropertyType DWORD -Force -ErrorAction Stop| Out-Null
                        Write-Host "    Adding Key value 1 to $Enabled" -ForegroundColor Green
                    }
                    Catch {
                        Write-Host "  " $_.Exception.Message -ForegroundColor Red
                    }
                }
                # Populate value for enabled if it does not already exist, disable all protocols except TLS 1.2
                If ($onlyTLS12) {
                    if($Protocol -eq "TLS 1.2") {
                        Write-Host "    Adding Key value 1 to $Enabled" -ForegroundColor Yellow
                        Try {
                            New-ItemProperty -Path $currentRegPath -Name $Enabled -Value "1" -PropertyType DWORD -Force -ErrorAction Stop| Out-Null
                            Write-Host "    Adding Key value 1 to $Enabled" -ForegroundColor Green
                        }
                        Catch {
                            Write-Host "  " $_.Exception.Message -ForegroundColor Red
                        }
                    }
                    Else {
                        Write-Host "    Adding Key value 0 to $Enabled" -ForegroundColor Yellow
                        Try {
                            New-ItemProperty -Path $currentRegPath -Name $Enabled -Value "0" -PropertyType DWORD -Force -ErrorAction Stop| Out-Null
                            Write-Host "    Adding Key value 0 to $Enabled" -ForegroundColor Green
                        }
                        Catch {
                            Write-Host "  " $_.Exception.Message -ForegroundColor Red
                        }
                    }
                }
            }
        }
    }  
}  