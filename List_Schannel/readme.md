# List_SChan.ps1
Version: 1.1    
Release 2020/12/16

Display SChannel protocol settings for a Windows computer

## Purpose
This script allows a logged on user to display the registry values for SChannel protocols.   If the user is a local administrator, the keys can be created (if they don't exist), and default values assigned to them.

## Use Case
Most organizations have security requirements to enable or disable certain SChannel protocols on the network (SSL 2.0, TLS 1.0, TLS 1.1).  This is a quick and easy method to determine the protocols allowed  without opening the registry editor and reviewing the settings for each protocol.

The protocol keys do not exist by default in most cases, so the additinoal functionality to create and pre-populate the keys is also useful.  The actual setting requirements may be different, but this is a quick way to establish a baseline set of values.

## Usage
Run the script with no parameters to view the protocol settings only

**Example:**  List_Schan.ps1

Run the script with the *create* parameter to create any missing registry keys.  Set all *enabled* values to true and all *DisabledByDefault* values to false

**Example:**  List_Schan.ps1 create

Run the script with the *onlyTLS12* parameter to create any missing registry keys.  Set all *enabled* values to false and all *DisabledByDefault* values to true for all protocols except for TLS 1.2.  The values for this protocol will be set to *enabled* = true and *DisabledByDefault* = false.

**Example:**  List_Schan.ps1 onlyTLS12

### Download Script Here:
https://github.com/RPesenko/OpsMgr-Scripts/blob/master/List_Schannel/List_Schan.ps1

Change Log  
1.1: Updates to documentation   
1.0: Initial release 