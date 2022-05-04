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

Knowing Issues
-   If a app in catalog is changed from published to expired the deletion of this folder be script does not work anymore. 
    The reason is the function made a preselection and ingnor all expired apps the $App_Folder will be empty for this version 
    and deletion need to do manual.
-   DellSDPCatalogPC.CAB has some wrong download links for older software versions like Dell Command Update 4.4. 
    Please check minimum Version of software from time to time

#>

<#
.Synopsis
   This PowerShell is checking the DellSDPCatalogPC.CAB form Https://Downloads.dell.com. This script will generated new folders and downloading Dell Tools in specific Versions direct from the Dell Support Webpage. Older Files will be ignored or if downloaded in the past the folder will be delete.
   IMPORTANT: This scipt need internet connection and https://downloads.dell.com need to be reachable.
   IMPORTANT: This script does not reboot the system to apply or query system.
.DESCRIPTION
   Powershell is generate a Dell App repository managed by App Name and Version. Software downloads could be enabled by Software.
   
#>


#Select Software for download Value Enabled/Disabled
$Command_Monitor = "Enabled"
$Command_Configure = "Enabled"
$Command_Update_Legacy = "Enabled"
$Command_Update_UWP = "Enabled"
$Digital_Delivery = "Enabled"
$Optimizer = "Enabled"
$Power_Manager = "Enabled"
$PremierColor = "Enabled"
$RuggedControl_Center = "Enabled"
$Trusted_Device = "Enabled"
$Display_Manager = "Enabled"


#Deleting outdated Apps Value Y/N
$Folder_Delete = "Y"

#define oldest version you want to Download e.g. 4.4.0 means all Version from 4.4.0 and newer will be downloaded.
[Version]$Command_Monitor_Version = "10.5.1.114"
[Version]$Command_Configure_Version = "4.5.0.205"
[Version]$Command_Update_Legacy_Version = "4.5.0"
[Version]$Command_Update_UWP_Version = "4.5.0"
[Version]$Power_Manager_Version = "3.9"
[Version]$Optimizer_Version = "2.0"
[Version]$PremierColor_Version = "6.1"
[Version]$Digital_Delivery_Version = "4.0.92.0"
[Version]$RuggedControl_Center_Version = "4.3.55.0"
[Version]$Trusted_Device_Version = "4.0"
[Version]$Display_Manager_Version = "1.50"

#Environment variables

#Search string for application look for best match codes to select your software
$Command_Monitor_Name = "*Command*Monitor*"
$Command_Configure_Name = "*Command*Configure*"
$Command_Update_Legacy_Name = "*Command*Update*"
$Command_Update_UWP_Name = "*Command*Update*Windows*"
$Power_Manager_Name = "*Power*Manager*"
$Optimizer_Name = "Dell Optimizer*"
$PremierColor_Name = "Dell PremierColor*"
$Digital_Delivery_Name = "Dell*Digital*Delivery*"
$RuggedControl_Center_Name = "Dell*Rugged*Control*"
$Trusted_Device_Name = "not relevant @ the moment*" #not part of Catalog
$Display_Manager_Name = "not relevant @ the moment*" #not part of Catalog

#Main folder name for application. In these folder includes later subfolders with version number
$Command_Monitor_FolderName = "Dell Command Monitor"
$Command_Configure_FolderName = "Dell Command Configure"
$Command_Update_Legacy_FolderName = "Dell Command Update W32"
$Command_Update_UWP_FolderName = "Dell Command Update UWP"
$Power_Manager_FolderName = "Dell Power Manager"
$Optimizer_FolderName = "Dell Optimizer"
$PremierColor_FolderName = "Dell PremierColor"
$Digital_Delivery_FolderName = "Dell Digital Deliver"
$RuggedControl_Center_FolderName = "Dell Rugged Control Center"
$Trusted_Device_FolderName = "Dell Trusted Device"
$Display_Manager_FolderName = "Dell Display Manager"

# Catalog CAB Name
$Catalog_Name = "DellSDPCatalogPC.cab"
$Catalog_XML = "DellSDPCatalogPC.xml"

# Source URL for Dell Update Catalog for SCCM
$url = "https://downloads.dell.com/catalog/$Catalog_Name"
$url_DDM = "https://www.delldisplaymanager.com/ddmsetup.exe"

# Destation file where all files will stored
$dest = "C:\Dell\SoftwareRepository"

#Temp Folder for Catalog files
$Temp_Folder = "C:\Temp"


##################################################################
# Download functions for Dell Applications

# Function for downloading required software based on Catalog File
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
    

    #Checking Dell Command Update Win32 or UWP App - Deselect not relevant Software first before prepare download

    If ($Software_Name -eq $Command_Update_Legacy_Name)
        {

        $Dell_App_Download = $Dell_App_Download | Where-Object {$_.LocalizedProperties.Description -notlike "*Universal*"}

        }

    
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

                    #generate a XML with install instructions selected of Dell SCCM catalog file
                    $xmlInstComm = New-Object System.Xml.XmlTextWriter("Install.xml",$null)
                    $xmlInstComm.BaseStream = "System.io.filestream"
                    $xmlInstComm.Formatting = "Indented"
                    $xmlInstComm.Indentation = "1"
                    $xmlInstComm.IndentChar = "`t"

                    $xmlInstComm.WriteStartDocument()
                    $xmlInstComm.WriteStartElement("$i.localizedproperties.title")

                    $xmlInstComm.WriteEndDocument()
                    $xmlInstComm.Flush()
                    $xmlInstComm.Close()


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

# Function for downloading Dell Display Manager from delldisplaymanager.com
function Download-Weblinks
    {

    # Parameter
    param(
        [string]$Software_Name,
        [version]$Software_Version,
        [string]$App_Folder_Main
        
         )
    
    #Prepare Download Display Manager
    
    #Get folder with newest version
    cd $dest
    
    If((Test-Path $App_Folder_Main) -ne "True")
        {
    
        # generate new main App Folder
        New-Item $App_Folder_Main -ItemType Directory

        }
        
    cd $App_Folder_Main
    
    #checking Online Page date
    $DDMPageCheck = Invoke-WebRequest -Method HEAD -Uri $url_DDM -UseBasicParsing
    [datetime]$DDMPageDate = $DDMPageCheck.Headers.'Last-Modified'
        
    #Checking Subfolder looking for the newest Software version folder and select folder name
    $App_Folder = @(Get-ChildItem -Directory | sort -Descending name | select -ExpandProperty Name)

    # Checking how much files are stored in this folder. If 0 the file will reload again
    $File_Count = Get-ChildItem -Path $App_Folder[0] -Recurse | Measure-Object | select -ExpandProperty Count

    If ($File_Count -lt 1)
        {

        # fill var $DDMFileCheck with a date to surpres any script warning. Using webpage date -1 day to secure it will run trought download part.
        [datetime]$DDMFileCheck = $DDMPageDate.AddDays(-1)

        }
    
    Else
        {
        
        #checking file date       
        [datetime]$DDMFileCheck = Get-ChildItem -Path $App_Folder[0] -File | sort -Descending name | select -ExpandProperty LastWriteTime
        
        }
    
    

    If ($DDMPageDate -gt $DDMFileCheck)
        {
        
        #Download installer from delldisplaymanager.com
        Start-BitsTransfer -Source $url_DDM -Destination $Temp_Folder -DisplayName $Display_Manager_FolderName
    
        #Prepare Download struture
        cd $dest
    
        If ((Test-Path $App_Folder_Main) -ne "True")
            {
            # generate new main software folder
            New-Item $App_Folder_Main -ItemType Directory
            }

        cd $App_Folder_Main

    
        #Rename File and transfer to dell app repository
        $DDM_Version = ((Get-Item $Temp_Folder\ddmsetup.exe | select -ExpandProperty Versioninfo).ProductVersion -split" ")[0]
        $DDM_Name_New = "Dell Display Manager "+$DDM_Version+".exe"
        $DDM_Name_Old = (Get-Item $Temp_Folder\ddmsetup.exe | select -ExpandProperty Versioninfo).FileName
        Rename-Item -Path $DDM_Name_Old -NewName $DDM_Name_New -Force
        #Get renamed file details
        $DDM_Name = ((Get-Item $Temp_Folder).GetFiles('Dell*Display*')).Name

        #Make subfolder structure and move file
        If ((Test-Path $DDM_Version) -ne "True")
            {
            # generate new main software folder
            New-Item $DDM_Version -ItemType Directory
            }
    
        #Source and destiontion string prepare
        $DDM_Source = $Temp_Folder+"\"+$DDM_Name
        $DDM_Destination = $dest+"\"+$App_Folder_Main+"\"+$DDM_Version+"\"+$DDM_Name 
    
        #move file to repository   
        Move-Item $DDM_Source -Destination $DDM_Destination -Force

        }
    Else
        {

        Write-Output "Dell Display Manager no newer version is online"

        }
    
    #Delete older Version of DDM

    If ($Folder_Delete -match "Y")
        {

        foreach ($i in $App_Folder)
            {

            If ($i -lt $DDM_Version)

                {

                Remove-Item $i -Recurse -Force
                Write-Output "Folder $i is delete now because is outdate Version"

                }

            Else
                {

                Write-Output "Folder $i is keep alive and still exist"

                }



            }
            
        }
    Else
        {

        Write-Output "Value $Folder_Delete is N, no folders will be delete"

        }

                  
    cd $dest
    
    Return $Value

    }

#Prepare XML file for loging
#$xmlloging = New-Object System.Xml.XmlTextWriter("download_log.xml",$null)


#Check if $Temp_Folder is availible, if not it will generate a new folder
If((Test-Path $Temp_Folder) -ne "True")
    {

    Write-Output "Folder is not availble will now generate $Temp_Folder"
    New-Item -Path $Temp_Folder -itemType Directory

    }

#Check if $dest is availible, if not it will generate a new folder
If((Test-Path $dest) -ne "True")
    {

    Write-Output "Folder is not availble will now generate $dest"
    New-Item -Path $dest -itemType Directory

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


######################################
# Section Application Download
# Section for Dell Command Configure
If ($Command_Configure -eq "Enabled")
    {

    Download-Dell -Software_Name $Command_Configure_Name -Software_Version $Command_Configure_Version -App_Folder_Main $Command_Configure_FolderName

    }
Else
    {

    Write-Output "no Dell Command | Configure selected"
    
    }

# Section for Dell Command Monitor    
If ($Command_Monitor -eq "Enabled")
    {

    Download-Dell -Software_Name $Command_Monitor_Name -Software_Version $Command_Monitor_Version -App_Folder_Main $Command_Monitor_FolderName

    }
Else
    {

    Write-Output "no Dell Command | Monitor selected"
    
    }

# Section for Dell Power Manager
If ($Power_Manager -eq "Enabled")
    {

    Download-Dell -Software_Name $Power_Manager_Name -Software_Version $Power_Manager_Version -App_Folder_Main $Power_Manager_FolderName

    }
Else
    {

    Write-Output "no Dell Power Manager selected"
    
    }

# Section for Dell Optimizer
If ($Optimizer -eq "Enabled")
    {

    Download-Dell -Software_Name $Optimizer_Name -Software_Version $Optimizer_Version -App_Folder_Main $Optimizer_FolderName

    }
Else
    {

    Write-Output "no Dell Optimizer selected"
    
    }

# Section for Dell PremierColor
If ($PremierColor -eq "Enabled")
    {

    Download-Dell -Software_Name $PremierColor_Name -Software_Version $PremierColor_Version -App_Folder_Main $PremierColor_FolderName

    }
Else
    {

    Write-Output "no Dell PremierColor selected"
    
    }

# Section for Dell Digital Delivery
If ($Digital_Delivery -eq "Enabled")
    {

    Download-Dell -Software_Name $Digital_Delivery_Name -Software_Version $Digital_Delivery_Version -App_Folder_Main $Digital_Delivery_FolderName

    }
Else
    {

    Write-Output "no Dell Digital Delivery selected"
    
    }


# Section for Dell Rugged Control Center
If ($RuggedControl_Center -eq "Enabled")
    {

    Download-Dell -Software_Name $RuggedControl_Center_Name -Software_Version $RuggedControl_Center_Version -App_Folder_Main $RuggedControl_Center_FolderName

    }
Else
    {

    Write-Output "no Dell Rugged Control Center selected"
    
    }


# Section for Dell Command Update W32 and UWP
If ($Command_Update_Legacy -eq "Enabled")
    {

    Download-Dell -Software_Name $Command_Update_Legacy_Name -Software_Version $Command_Update_Legacy_Version -App_Folder_Main $Command_Update_Legacy_FolderName

    }
Else
    {

    Write-Output "no Dell Command | Update Win32 selected"
    
    }

If ($Command_Update_UWP -eq "Enabled")
    {

    Download-Dell -Software_Name $Command_Update_UWP_Name -Software_Version $Command_Update_UWP_Version -App_Folder_Main $Command_Update_UWP_FolderName

    }
Else
    {

    Write-Output "no Dell Command | Update UWP selected"
    
    }

<#Section for Dell Trusted Device
If ($Trusted_Device -eq "Enabled")
    {

    Download-Dell -Software_Name $Trusted_Device_Name -Software_Version $Trusted_Device_Version -App_Folder_Main $Trusted_Device_FolderName

    }
Else
    {

    Write-Output "no Dell Trusted Device selected"
    
    }#>


#Section for Dell Display Manager
If ($Display_Manager -eq "Enabled")
    {

    Download-Weblinks -Software_Name $Display_Manager_Name -Software_Version $Display_Manager_Version -App_Folder_Main $Display_Manager_FolderName

    }
Else
    {

    Write-Output "no Dell Display Manager selected"
    
    }