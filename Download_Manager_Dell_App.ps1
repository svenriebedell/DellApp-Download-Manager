<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.0.0
_Dev_Status_ = Test
Copyright © 2022 Dell Inc. or its subsidiaries. All Rights Reserved.

No implied support and test in test environment/device before using in any production environment.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

<#Version Changes

1.0.0   inital version

#>

<#
.Synopsis
   This PowerShell is checking the DellSDPCatalogPC.CAB form Https://Downloads.dell.com. This script will generated new folders and downloading Dell Tools in specific Versions direct from the Dell Support Webpage. Older Files will be ignored or if downloaded in the past the fold
   IMPORTANT: This scipt need a client installation of Dell Trusted Device Agent. https://www.dell.com/support/home/en-us/product-support/product/trusted-device/drivers
   IMPORTANT: This script does not reboot the system to apply or query system.
.DESCRIPTION
   Powershell using Microsoft eventlog to check the Security Score and option compliances of Dell Trusted Device Agent. This script need to be upload in Intune Compliance / Script and need a JSON file additional for reporting this value.
   
#>


#Select Software for download Value Enabled/Disabled
$Command_Monitor = "Enabled" #
$Command_Configure = "Enabled" #
$Command_Update_Legacy = "Enabled"
$Command_Update_UWP = "Enabled"
$Digital_Delivery = "Enabled" #
$Optimizer = "Enabled" #
$Power_Manager = "Enabled" #
$PremierColor = "Enabled" #
$RuggedControl_Center = "Enabled"
$Trusted_Device = "Enabled"
$Display_Manager = "Enabled"

#Deleting outdated Apps Value Y/N
$Folder_Delete = "Y"

#define oldest version for Download
[Version]$Command_Monitor_Version = "10.5.1.114"
[Version]$Command_Configure_Version = "4.5.0.205"
[Version]$Power_Manager_Version = "3.9"
[Version]$Optimizer_Version = "2.0"
[Version]$PremierColor_Version = "6.1"
[Version]$Digital_Delivery_Version = "4.0.92.0"
[Version]$RuggedControl_Center_Version = "4.3.55.0"

#Environment variables

#Search string for application
$Command_Monitor_Name = "*Command*Monitor*"
$Command_Configure_Name = "*Command*Configure*"
$Power_Manager_Name = "*Power*Manager*"
$Optimizer_Name = "Dell Optimizer*"
$PremierColor_Name = "Dell PremierColor*"
$Digital_Delivery_Name = "Dell*Digital*Delivery*"
$RuggedControl_Center_Name = "Dell*Rugged*Control*"

#Main folder name for application. In these folder later are subfolders with version number
$Command_Monitor_FolderName = "Dell Command Monitor"
$Command_Configure_FolderName = "Dell Command Configure"
$Power_Manager_FolderName = "Dell Power Manager"
$Optimizer_FolderName = "Dell Optimizer"
$PremierColor_FolderName = "Dell PremierColor"
$Digital_Delivery_FolderName = "Dell Digital Deliver"
$RuggedControl_Center_FolderName = "Dell Rugged Control Center"

# Catalog CAB Name
$Catalog_Name = "DellSDPCatalogPC.cab"
$Catalog_XML = "DellSDPCatalogPC.xml"

# Source URL for Dell Update Catalog for SCCM
$url = "https://downloads.dell.com/catalog/$Catalog_Name"
#https://www.delldisplaymanager.com/ddmsetup.exe

# Destation file where all files will stored
$dest = "C:\Users\sven_riebe\Downloads\"

#Temp Folder for Catalog files
$Temp_Folder = "C:\Temp"


# Function for downloading required software
function Download-Dell 
    {
    
    # Parameter
    param(
        [string]$Software_Name,
        [version]$Software_Version,
        [string]$App_Folder_Main
        
         )
    
    #Prepare Download struture
    cd $dest
    
    If ((Test-Path $App_Folder_Main) -ne "True")
        {
        # generate new main software folder
        New-Item $App_Folder_Main -ItemType Directory
        }

    cd $App_Folder_Main

    #Prepare Download details
    $Dell_App_Select = $Catalog_DATA.SystemsManagementCatalog.SoftwareDistributionPackage | Where-Object{$_.LocalizedProperties.Title -like "$Software_Name"}
    $Dell_App_Download = $Dell_App_Select | Where-Object {$_.Properties.PublicationState -ne "Expired"}
    
    
    foreach ($i in $Dell_App_Download)
        {
                     
            # Taking Version number form Title String
            [Version]$App_Folder = ($i.LocalizedProperties.title -split ",")[1]                    
            
            If ($Software_Version -le $App_Folder)
                {
                        
                # Checking how much files are stored in this folder. If 0 the file will reload again
                $File_Count = Get-ChildItem -Path $App_Folder -Recurse | Measure-Object | select -ExpandProperty Count

                if ($File_Count -lt 1)
                    {
            
                    New-Item $App_Folder -ItemType Directory
                    cd $App_Folder

                    # download files
                    Start-BitsTransfer -Source $i.InstallableItem.OriginFile.OriginUri -Destination .\ -DisplayName $i.localizedproperties.title
                    Write-Output $i.localizedproperties.title "was downloaded to machine"
                    cd ..
                    }
                Else
                    {
                    Write-Output $i.localizedproperties.title "is existing on the machine"
                    }
                }
            Else
                {
                
                # Checking how much files are stored in this folder. If 0 the file will reload again
                $File_Count = Get-ChildItem -Path $App_Folder -Recurse | Measure-Object | select -ExpandProperty Count

                if ($File_Count -ge 1)
                    {
                    
                    #Deleting old Data if $Folder_Delete = Y
                    If ($Folder_Delete -match "Y")
                        {

                        Remove-Item $App_Folder -Force -Recurse
                        Write-Output $i.localizedproperties.title "is outdated and is now deleted from this device"
                
                        }
                
                    Else
                        {
                    
                        Write-Output $i.localizedproperties.title "is outdated but file is stored on this machine"
                    
                        }
                    


                    }
                Else
                    {
                    Write-Output $i.localizedproperties.title "is outdated and is not downloaded"
                    }
                             
                  
                }

        }

    


    Return $Value
     
    }




#Check if $Temp_Folder is availible, if not it will generate a new folder
If((Test-Path $Temp_Folder) -ne "True")
    {

    Write-Output "Folder is not availble will now generate $Temp_Folder"
    New-Item -Path $Temp_Folder -itemType Directory

    }

#Checking if the newest version of catalogs was stored locally

# Checking Header of webpage when last-modified of CAB-File
$result = Invoke-WebRequest -Method HEAD -Uri $url -UseBasicParsing
[datetime]$Catalog_DateOnline = $result.Headers.'Last-Modified'

#Checking date of modified of local stored catalog files
cd $Temp_Folder
If ((Test-Path $Catalog_Name) -ne "True")
    {
    
    [datetime]$Catalog_DateLocal = $Catalog_DateOnline.AddDays(-1)

    }
else
    {

[datetime]$Catalog_DateLocal = Get-ItemProperty $Catalog_Name | select -ExpandProperty LastWriteTime

    }

# New Catalog will only download and extract the Catalog if Online version is newer than local version

If ($Catalog_DateOnline -gt $Catalog_DateLocal)
    {

    # Download the catalog File newest version
    Start-BitsTransfer -Source $url -Destination $Temp_Folder -displayname "Download Dell SCCM Catalog"
        
    }
Else
    {

    Write-Output "No newer Catalog is availible"
    
    }

# Extract Catalog XML-File form existing CAB-File
# Change directory
CD $Temp_Folder

# Extract DellSDPCatalogPC.xml from CAB-File
expand $Catalog_Name . -f:$Catalog_XML

# Transfer XML data to VAR
[XML]$Catalog_DATA = Get-Content $Catalog_XML

# Section Application Download
If ($Command_Configure -eq "Enabled")
    {

    Download-Dell -Software_Name $Command_Configure_Name -Software_Version $Command_Configure_Version -App_Folder_Main $Command_Configure_FolderName

    }
Else
    {

    Write-Output "no Dell Command | Configure selected"
    
    }
    
If ($Command_Monitor -eq "Enabled")
    {

    Download-Dell -Software_Name $Command_Monitor_Name -Software_Version $Command_Monitor_Version -App_Folder_Main $Command_Monitor_FolderName

    }
    Else
    {

    Write-Output "no Dell Command | Monitor selected"
    
    }

If ($Power_Manager -eq "Enabled")
    {

    Download-Dell -Software_Name $Power_Manager_Name -Software_Version $Power_Manager_Version -App_Folder_Main $Power_Manager_FolderName

    }
    Else
    {

    Write-Output "no Dell Power Manager selected"
    
    }

If ($Optimizer -eq "Enabled")
    {

    Download-Dell -Software_Name $Optimizer_Name -Software_Version $Optimizer_Version -App_Folder_Main $Optimizer_FolderName

    }
    Else
    {

    Write-Output "no Dell Optimizer selected"
    
    }

If ($PremierColor -eq "Enabled")
    {

    Download-Dell -Software_Name $PremierColor_Name -Software_Version $PremierColor_Version -App_Folder_Main $PremierColor_FolderName

    }
    Else
    {

    Write-Output "no Dell PremierColor selected"
    
    }

If ($Digital_Delivery -eq "Enabled")
    {

    Download-Dell -Software_Name $Digital_Delivery_Name -Software_Version $Digital_Delivery_Version -App_Folder_Main $Digital_Delivery_FolderName

    }
    Else
    {

    Write-Output "no Dell Digital Delivery selected"
    
    }

If ($RuggedControl_Center -eq "Enabled")
    {

    Download-Dell -Software_Name $RuggedControl_Center_Name -Software_Version $RuggedControl_Center_Version -App_Folder_Main $RuggedControl_Center_FolderName

    }
    Else
    {

    Write-Output "no Dell Digital Delivery selected"
    
    }