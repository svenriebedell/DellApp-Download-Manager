<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.2.0
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
1.0.1   Install.XML with Command Line Informations will now saved in Installer directory
1.0.2   download_log_date(yyyymmdd).xml loging details
1.0.3   Archiving old catalog XML to a Archiving folder if a new catalog will be downloaded
1.1.0   Add Application download for Dell Trusted Device and change Dell Display Manager download for Version 1.x to 2.x
1.1.1   Correction Function function Download-Dell unplaned delete of folders if delete older folders is enabled.
1.1.2   Correction failure if no Temp folder is exist
1.2.0   Move to selenius browser automation for download of Trusted Device / Display Manager 2.x

Knowing Issues
-   If a app in catalog is changed from published to expired the deletion of this folder be script does not work anymore. 
    The reason is the function made a preselection and ingnor all expired apps the $App_Folder will be empty for this version 
    and deletion need to do manual.
-   If you using Version older than 1.0.3 you need to delete the Software Repository to generate Install.XML
-   IE does not load dell.com correctly so download for display manager and trusted device need to disable

#>

<#
.Synopsis
   This PowerShell is checking the DellSDPCatalogPC.CAB form Https://Downloads.dell.com. This script will generated new folders and downloading Dell Tools in specific Versions direct from the Dell Support Webpage. Older Files will be ignored or if downloaded in the past the folder will be delete.
   IMPORTANT: This scipt need internet connection and https://downloads.dell.com need to be reachable.
   IMPORTANT: This script does not reboot the system to apply or query system.
   IMPORTANT: Dell Display Manager / Dell Trusted Device using temporary InternetExplorer to download informations from dell.com/support (if IE not more availible it will be change to opensource solution)
   IMPORTANT: Dell Display Manager only supported by Version 2.x and newer for Version 1.x please use version V1.0.3 of this Downloader.
.DESCRIPTION
   Powershell is generate a Dell App repository managed by App Name and Version. Software downloads could be enabled by Software.
   
#>

#########################################################################################################
####                                    Variable Section                                             ####
#########################################################################################################

################################################
#### Download selected Applications         ####
################################################

########################################## 
#### possible Value: Enabled/Disabled ####
##########################################
$DownloadSoftware = @(
    [PSCustomObject]@{Name = "Dell Command | Monitor"; UpdateStatus = $true; Version = "10.5.1.114"}
    [PSCustomObject]@{Name = "Dell Command | Configure"; UpdateStatus = $true; Version = "4.5.0.205"}
    [PSCustomObject]@{Name = "Dell Command | Update Legacy"; UpdateStatus = $true; Version = "4.5"}
    [PSCustomObject]@{Name = "Dell Command | Update UWP"; UpdateStatus = $true; Version = "4.5"}
    [PSCustomObject]@{Name = "Dell Digital Delivery"; UpdateStatus = $true; Version = "4.0.92.0"}
    [PSCustomObject]@{Name = "Dell Optimizer"; UpdateStatus = $true; Version = "4.5"}
    [PSCustomObject]@{Name = "Dell Power Manager"; UpdateStatus = $true; Version = "4.5"}
    [PSCustomObject]@{Name = "Dell PremierColor"; UpdateStatus = $true; Version = "4.3.55.0"}
    [PSCustomObject]@{Name = "Dell RuggedControl Center"; UpdateStatus = $true; Version = "4.3.55.0"}
    [PSCustomObject]@{Name = "Dell Trusted Device"; UpdateStatus = $true; Version = "4.5"}
    [PSCustomObject]@{Name = "Dell Dell Display Manager Legacy"; UpdateStatus = $true; Version = "1.5"}
    [PSCustomObject]@{Name = "Dell Dell Display Manager"; UpdateStatus = $true; Version = "2.0"}
    )

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

################################################
#### Automatically delete outdated programs ####
################################################

########################################## 
#### possible Value: Y/N              ####
##########################################
$Folder_Delete = "Y"

########################################## 
#### Specify the oldest version you   #### 
#### want to download, e.g. 4.4.0     ####
#### means that all versions from     ####
#### 4.4.0 and newer will be          ####
#### downloaded                       ####
##########################################
#### possible Value: "x.x.x.x"        ####
##########################################
[Version]$Command_Monitor_Version = "10.5.1.114"
[Version]$Command_Configure_Version = "4.5.0.205"
[Version]$Command_Update_Legacy_Version = "4.5.0"
[Version]$Command_Update_UWP_Version = "4.5.0"
[Version]$Power_Manager_Version = "3.9"
[Version]$Optimizer_Version = "2.0"
[Version]$PremierColor_Version = "6.1"
[Version]$Digital_Delivery_Version = "4.0.92.0"
[Version]$RuggedControl_Center_Version = "4.3.55.0"
[Version]$Trusted_Device_Version = "4.7"
[Version]$Display_Manager_Version = "1.54"

################################################
#### Search variables with wildcards        ####
################################################

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
$Trusted_Device_Name = "Trusted-Device" #Part of FileName to identifiy right app on Dell.com/support
$Display_Manager_Name = "ddmsetup.exe" # Filename

################################################
#### Repository Application Folder Names    ####
################################################
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

################################################
#### Names of SCCM Update Catalog Files     ####
################################################
$Catalog_Name = "DellSDPCatalogPC.cab"
$Catalog_XML = "DellSDPCatalogPC.xml"

################################################
#### Time variables                         ####
################################################
$date = Get-Date -Format yyyyMMdd

################################################
#### Webpages used for download             ####
################################################
$url = "https://downloads.dell.com/catalog/$Catalog_Name"
$url_DDM = "https://www.dell.com/support/home/de-de/product-support/product/dell-display-peripheral-manager/drivers"
$url_DTD = "https://www.dell.com/support/home/de-de/product-support/product/trusted-device/drivers"

################################################
#### local Folders                          ####
################################################
$dest = "C:\Dell\SoftwareRepository"           # Software folder
$Temp_Folder = "C:\Temp"                       # Logging folder
$Catalog_Archive = $dest+"\Catalog_Archive"    # Archive folder for older catalogs


#########################################################################################################
####                                    Function Section                                              ####
#########################################################################################################

#####################################################
#### Function preparation for Browser automation ####
#### SOURCE:                                     ####
#### https://administrator.de/tutorial/powershell-einfuehrung-in-die-webbrowser-automation-mit-selenium-webdriver-1197173647.html ####
#####################################################

function Create-Browser {
    param(
        [Parameter(mandatory=$true)][ValidateSet('Chrome','Edge','Firefox')][string]$browser,
        [Parameter(mandatory=$false)][bool]$HideCommandPrompt = $true,
        [Parameter(mandatory=$false)][string]$driverversion = ''
    )
    $driver = $null
    
    function Load-NugetAssembly {
        [CmdletBinding()]
        param(
            [string]$url,
            [string]$name,
            [string]$zipinternalpath,
            [switch]$downloadonly
        )
        if($psscriptroot -ne ''){
            $localpath = join-path $psscriptroot $name
        }else{
            $localpath = join-path $env:TEMP $name
        }
        $tmp = "$env:TEMP\$([IO.Path]::GetRandomFileName())"
        $zip = $null
        try{
            if(!(Test-Path $localpath)){
                Add-Type -A System.IO.Compression.FileSystem
                write-host "Downloading and extracting required library '$name' ... " -F Green -NoNewline
                (New-Object System.Net.WebClient).DownloadFile($url, $tmp)
                $zip = [System.IO.Compression.ZipFile]::OpenRead($tmp)
                $zip.Entries | ?{$_.Fullname -eq $zipinternalpath} | %{
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_,$localpath)
                }
	            Unblock-File -Path $localpath
                write-host "OK" -F Green
            }
            if(!$downloadonly.IsPresent){
                Add-Type -LiteralPath $localpath -EA Stop
            }
        
        }catch{
            throw "Error: $($_.Exception.Message)"
        }finally{
            if ($zip){$zip.Dispose()}
            if(Test-Path $tmp){del $tmp -Force -EA 0}
        }  
    }

    # Load Selenium Webdriver .NET Assembly
    Load-NugetAssembly 'https://www.nuget.org/api/v2/package/Selenium.WebDriver' -name 'WebDriver.dll' -zipinternalpath 'lib/net45/WebDriver.dll' -EA Stop

    if($psscriptroot -ne ''){
        $driverpath = $psscriptroot
    }else{
        $driverpath = $env:TEMP
    }
    switch($browser){
        'Chrome' {
            $chrome = Get-Package -Name 'Google Chrome' -EA SilentlyContinue | select -F 1
            if (!$chrome){
                throw "Google Chrome Browser not installed."
                return
            }
            Load-NugetAssembly "https://www.nuget.org/api/v2/package/Selenium.WebDriver.ChromeDriver/$driverversion" -name 'chromedriver.exe' -zipinternalpath 'driver/win32/chromedriver.exe' -downloadonly -EA Stop
            # create driver service
            $dService = [OpenQA.Selenium.Chrome.ChromeDriverService]::CreateDefaultService($driverpath)
            # hide command prompt window
            $dService.HideCommandPromptWindow = $HideCommandPrompt
            # create driver object
            $driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver $dService
        }
        'Edge' {
            $edge = Get-Package -Name 'Microsoft Edge' -EA SilentlyContinue | select -F 1
            if (!$edge){
                throw "Microsoft Edge Browser not installed."
                return
            }
            Load-NugetAssembly "https://www.nuget.org/api/v2/package/Selenium.WebDriver.MSEdgeDriver/$driverversion" -name 'msedgedriver.exe' -zipinternalpath 'driver/win64/msedgedriver.exe' -downloadonly -EA Stop
            # create driver service
            $dService = [OpenQA.Selenium.Edge.EdgeDriverService]::CreateDefaultService($driverpath)
            # hide command prompt window
            $dService.HideCommandPromptWindow = $HideCommandPrompt
            # create driver object
            $driver = New-Object OpenQA.Selenium.Edge.EdgeDriver $dService
        }
        'Firefox' {
            $ff = Get-Package -Name "Mozilla Firefox*" -EA SilentlyContinue | select -F 1
            if (!$ff){
                throw "Mozilla Firefox Browser not installed."
                return
            }
            Load-NugetAssembly "https://www.nuget.org/api/v2/package/Selenium.WebDriver.GeckoDriver/$driverversion" -name 'geckodriver.exe' -zipinternalpath 'driver/win64/geckodriver.exe' -downloadonly -EA Stop
            # create driver service
            $dService = [OpenQA.Selenium.Firefox.FirefoxDriverService]::CreateDefaultService($driverpath)
            # hide command prompt window
            $dService.HideCommandPromptWindow = $HideCommandPrompt
            # create driver object
            $driver = New-Object OpenQA.Selenium.Firefox.FirefoxDriver $dService
        }
    }
    return $driver
}


################################################
#### Function for SCCM Catalog Applications ####
################################################

### Function is for all Applications excl. Dell Trusted Device and Dell Display Manager 2.x and newer

function Download-Dell 
    {
    
    # Parameter
    param(
        [string]$Software_Name,
        [version]$Software_Version,
        [string]$App_Folder_Main
        
         )
    
    #Prepare Download struture
    Set-Location $dest
    
    If ((Test-Path $App_Folder_Main) -ne "True")
        {
        # generate new main software folder
        New-Item $App_Folder_Main -ItemType Directory
        }

    Set-Location $App_Folder_Main

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
                $File_Count = Get-ChildItem -Path $App_Folder -Recurse | Measure-Object | Select-Object -ExpandProperty Count

                if ($File_Count -lt 1)
                    {
            
                    New-Item $App_Folder -ItemType Directory
                    Set-Location $App_Folder

                    # download files
                    Start-BitsTransfer -Source $i.InstallableItem.OriginFile.OriginUri -Destination .\ -DisplayName $i.localizedproperties.title
                    Write-Output $i.localizedproperties.title "was downloaded to machine"

                    #generate a XML with install instructions selected of Dell SCCM catalog file
                    $xmlInstComm = New-Object System.Xml.XmlTextWriter("$dest\$App_Folder_Main\$App_Folder\Install.xml",$null)
                    #Formating XML File
                    $xmlInstComm.Formatting = "Indented"
                    $xmlInstComm.Indentation = "1"
                    $xmlInstComm.IndentChar = "`t"

                    #writing datas
                    $xmlInstComm.WriteStartDocument()
                    $xmlInstComm.WriteStartElement("InstallInformations")
                    $xmlInstComm.WriteStartElement("Application")
                    $xmlInstComm.WriteStartElement("CommandLineData")
                    $xmlInstComm.WriteAttributeString("Name",$i.Localizedproperties.title)
                    $xmlInstComm.WriteAttributeString("Arguments",$i.InstallableItem.CommandLineInstallerData.Arguments)
                    $xmlInstComm.WriteAttributeString("DefaultResult",$i.InstallableItem.CommandLineInstallerData.DefaultResult)
                    $xmlInstComm.WriteAttributeString("RebootByDefault",$i.InstallableItem.CommandLineInstallerData.RebootByDefault)
                    $xmlInstComm.WriteAttributeString("Program",$i.InstallableItem.CommandLineInstallerData.Program)
                    $xmlInstComm.WriteEndElement()
                    $xmlInstComm.WriteStartElement("PackageData")
                    $xmlInstComm.WriteAttributeString("VendorName",$i.Properties.VendorName)
                    $xmlInstComm.WriteAttributeString("CreationDate",$i.Properties.CreationDate)
                    $xmlInstComm.WriteAttributeString("PackageID",$i.Properties.PackageID)
                    $xmlInstComm.WriteAttributeString("InfoURL",$i.Properties.MoreInfoUrl)
                    $xmlInstComm.WriteEndElement()
                    $xmlInstComm.WriteStartElement("UpdateData")
                    $xmlInstComm.WriteAttributeString("Severity",$i.UpdateSpecificData.MsrcSeverity)
                    $xmlInstComm.WriteAttributeString("DriverID",$i.UpdateSpecificData.KBArticleID)
                    $xmlInstComm.WriteAttributeString("DownloadLink",$i.InstallableItem.OriginFile.OriginUri)
                    $xmlInstComm.WriteAttributeString("Modified",$i.InstallableItem.OriginFile.Modified)
                    $xmlInstComm.WriteEndElement()
                    $xmlInstComm.WriteEndElement()

                    #Close Document and delete buffer
                    $xmlInstComm.WriteEndDocument()
                    $xmlInstComm.Flush()
                    $xmlInstComm.Close()
                    
                    Set-Location ..
                    
                    #loging informations
                    $xmlloging.WriteStartElement("Applications")
                    $xmlloging.WriteAttributeString("Name",$i.Localizedproperties.title)
                    $xmlloging.WriteAttributeString("Version",$App_Folder)
                    $xmlloging.WriteAttributeString("Status","download")
                    $xmlloging.WriteEndElement()
                                        
                    }
                             
                Else
                    {
                    Write-Output $i.localizedproperties.title "is existing on the machine"
                    
                    #loging informations
                    $xmlloging.WriteStartElement("Applications")
                    $xmlloging.WriteAttributeString("Name",$i.Localizedproperties.title)
                    $xmlloging.WriteAttributeString("Version",$App_Folder)
                    $xmlloging.WriteAttributeString("Status","exist")
                    $xmlloging.WriteEndElement()
                    
                    }
                }
            Else
                {
                
                # Checking how much files are stored in this folder. If 0 the file will reload again
                $File_Count = Get-ChildItem -Path $App_Folder -Recurse | Measure-Object | Select-Object -ExpandProperty Count

                if ($File_Count -ge 1)
                    {
                    
                    #Deleting old Data if $Folder_Delete = Y
                    If ($Folder_Delete -match "Y")
                        {

                        Remove-Item $App_Folder -Force -Recurse
                        Write-Output $i.localizedproperties.title "is outdated and is now deleted from this device"
                        
                        #loging informations
                        $xmlloging.WriteStartElement("Applications")
                        $xmlloging.WriteAttributeString("Name",$i.Localizedproperties.title)
                        $xmlloging.WriteAttributeString("Version",$App_Folder)
                        $xmlloging.WriteAttributeString("Status","delete")
                        $xmlloging.WriteEndElement()
                                        
                        }
                
                    Else
                        {
                    
                        Write-Output $i.localizedproperties.title "is outdated but file is stored on this machine"
                        
                        #loging informations
                        $xmlloging.WriteStartElement("Applications")
                        $xmlloging.WriteAttributeString("Name",$i.Localizedproperties.title)
                        $xmlloging.WriteAttributeString("Version",$App_Folder)
                        $xmlloging.WriteAttributeString("Status","outdated/exist")
                        $xmlloging.WriteEndElement()                    

                        }
                    


                    }
                Else
                    {
                    Write-Output $i.localizedproperties.title "is outdated and is not downloaded"

                    #loging informations
                    $xmlloging.WriteStartElement("Applications")
                    $xmlloging.WriteAttributeString("Name",$i.Localizedproperties.title)
                    $xmlloging.WriteAttributeString("Version",$App_Folder)
                    $xmlloging.WriteAttributeString("Status","outdated/no download")
                    $xmlloging.WriteEndElement()                    

                    }
                             
                
                }

                          
        }

    


    Return $Value
     
    }


####################################################
#### Function for dell.com/support Applications ####
####################################################

### Function is for Dell Trusted Device and Dell Display Manager 2.x and newer

function download-delltool
    {
    
    param
        (
        
        [string]$Webpage,
        [string]$FileName,
        [string]$App_Folder_Main,
        [version]$File_Version     
        
        )


    ### Prepare Download struture
    Set-Location $dest
    
    
    If ((Test-Path $App_Folder_Main) -ne $true)
        {
        
        # generate new main software folder
        New-Item $App_Folder_Main -ItemType Directory
                
        }


    Set-Location $App_Folder_Main
        
    ### Start InternetExplore for download Webpage informations
    $EdgeAuto = Create-Browser -browser Edge
    $EdgeAuto.Manage().Window.Minimize()
    $EdgeAuto.Url = "https://www.dell.com/support/home/de-de/product-support/product/trusted-device/drivers"             #$Webpage
   
    # wait loading website
    Start-Sleep -Seconds 5
    # Find download element
    $downloadTemp = $EdgeAuto.FindElements([OpenQA.Selenium.By]::TagName("a")) | Where-Object ComputedAccessibleLabel -Like "Trusted Device Agent*"
    # Download file
    $downloadTemp.Click()
    # Timer for download file
    Start-Sleep -Seconds 20
    # Close Browser
    $EdgeAuto.Close()
    $EdgeAuto.Quit

    # move file to software repository

    $EdgeAuto.FindElements([OpenQA.Selenium.By]::ClassName("mb-0")) | Where-Object Text -Like "Trusted-Device*.zip" | Select-Object -ExpandProperty Text

    $EdgeAuto.FindElements([OpenQA.Selenium.By]::ClassName("dl-mobi-view")) | Where-Object Text -Like "*Display*" | Select-Object -ExpandProperty Text   

   
    ### check if version is still exist

    ### Get Version of Download File Dell Trusted Device
    If($FileName -eq $Trusted_Device_Name)
        {
        
        $versionTemp = $downloadPath.TrimEnd(".zip}")
        $versionTemp = $versionTemp.Split("-")
        $AppVersionDownload = $versionTemp[-1]

            ### Check if folder with same Version is still existing
        If ((Test-Path $AppVersionDownload) -ne $true)
            {
        
            # generate new Version folder
            New-Item $AppVersionDownload -ItemType Directory
                
            }

        Set-Location $AppVersionDownload

        # Checking how much files are stored in this folder. If 0 the file will reload again
        $File_Count = Get-ChildItem -Path $App_Folder -Recurse | Measure-Object | Select-Object -ExpandProperty Count
        if($File_Count -gt 0)
            {

            Write-Output "$App_Folder_Main $AppVersionDownload" "is existing on the to machine"  
            #loging informations
            $xmlloging.WriteStartElement("Applications")
            $xmlloging.WriteAttributeString("Name",$App_Folder_Main)
            $xmlloging.WriteAttributeString("Version",$AppVersionDownload)
            $xmlloging.WriteAttributeString("Status","exist")
            $xmlloging.WriteEndElement()

            }
        Else
            {
        
            Write-Output "$App_Folder_Main $AppVersionDownload" "was downloaded to machine"                  
        
            ### download file
            $BitTransName = $FileName + " - " + $AppVersionDownload
            start-BitsTransfer -Source $downloadPath -Destination '.\' -DisplayName $BitTransName
            
            ### unzip Installer
            Expand-Archive .\*.zip -Force
            Start-Sleep -Seconds 5

            ### delete zip from folder
            Remove-Item .\*.zip -Force

            ### get installer file name for 64-Bit Version and move it to top of version folder
            $DirectoryMain = Get-ChildItem -Directory | Select-Object -ExpandProperty Name
            Set-Location $DirectoryMain
            $Directory64Bit = Get-ChildItem -Directory | Select-Object -ExpandProperty Name | Select-String "Win64R"
            Set-Location $Directory64Bit
            $fileName64Bit = Get-ChildItem | Select-Object -ExpandProperty PSChildName

            Move-Item $fileName64Bit -Destination $dest\$App_Folder_Main\$AppVersionDownload -Force

            Set-Location $dest\$App_Folder_Main\$AppVersionDownload

            ### delete folder and 32-bit Version
            Remove-Item $DirectoryMain -Force -Recurse

            #loging informations
            $xmlloging.WriteStartElement("Applications")
            $xmlloging.WriteAttributeString("Name",$App_Folder_Main)
            $xmlloging.WriteAttributeString("Version",$AppVersionDownload)
            $xmlloging.WriteAttributeString("Status","download")
            $xmlloging.WriteEndElement()

            #generate a XML with install instructions
            $xmlInstComm = New-Object System.Xml.XmlTextWriter("$dest\$App_Folder_Main\$AppVersionDownload\Install.xml",$null)
            #Formating XML File
            $xmlInstComm.Formatting = "Indented"
            $xmlInstComm.Indentation = "1"
            $xmlInstComm.IndentChar = "`t"

            #writing datas
            $xmlInstComm.WriteStartDocument()
            $xmlInstComm.WriteStartElement("InstallInformations")
            $xmlInstComm.WriteStartElement("Application")
            $xmlInstComm.WriteStartElement("CommandLineData")
            $xmlInstComm.WriteAttributeString("Name",$App_Folder_Main)
            $xmlInstComm.WriteAttributeString("Arguments","/qn")
            $xmlInstComm.WriteAttributeString("DefaultResult","")
            $xmlInstComm.WriteAttributeString("RebootByDefault","true")
            $xmlInstComm.WriteAttributeString("Program",$fileName64Bit)
            $xmlInstComm.WriteEndElement()
            $xmlInstComm.WriteStartElement("PackageData")
            $xmlInstComm.WriteAttributeString("VendorName","Dell Inc.")
            $xmlInstComm.WriteAttributeString("CreationDate","")
            $xmlInstComm.WriteAttributeString("PackageID","")
            $xmlInstComm.WriteAttributeString("InfoURL","")
            $xmlInstComm.WriteEndElement()
            $xmlInstComm.WriteStartElement("UpdateData")
            $xmlInstComm.WriteAttributeString("Severity","")
            $xmlInstComm.WriteAttributeString("DriverID","")
            $xmlInstComm.WriteAttributeString("DownloadLink",$downloadPath)
            $xmlInstComm.WriteAttributeString("Modified","")
            $xmlInstComm.WriteEndElement()
                                   
            $xmlInstComm.WriteEndElement()
        
            #Close Document and delete buffer
            $xmlInstComm.WriteEndDocument()
            $xmlInstComm.Flush()
            $xmlInstComm.Close()
                    
            }

        }

    ### Get Version of Download File Dell Display Manager 2.0
    If($FileName -eq $Display_Manager_Name)
        {
        
        start-BitsTransfer -Source $downloadPath -Destination $dest -DisplayName "Display Manager 2.x"
        
        $FileData = Get-ItemProperty $dest\ddmsetup.exe
        $AppVersionDownload = $FileData.VersionInfo | Select-Object -ExpandProperty ProductVersion

           

        ### Check if folder with same Version is still existing
        If ((Test-Path $AppVersionDownload) -ne $true)
            {
        
            # generate new Version folder
            New-Item $AppVersionDownload -ItemType Directory
                
            }

        Set-Location $AppVersionDownload

        # Checking how much files are stored in this folder. If 0 the file will reload again
        $File_Count = Get-ChildItem -Path $App_Folder -Recurse | Measure-Object | Select-Object -ExpandProperty Count
        if($File_Count -gt 0)
            {

            Write-Output "$App_Folder_Main $AppVersionDownload" "is existing on the to machine"  
            #loging informations
            $xmlloging.WriteStartElement("Applications")
            $xmlloging.WriteAttributeString("Name",$App_Folder_Main)
            $xmlloging.WriteAttributeString("Version",$AppVersionDownload)
            $xmlloging.WriteAttributeString("Status","exist")
            $xmlloging.WriteEndElement()

            Remove-Item $dest\ddmsetup.exe -Force

            }
        Else
            {
        
            Write-Output $App_Folder_Main $AppVersionDownload "was downloaded to machine"                  
        
            ### move temp download to AppVersion folder
            $TargetFolder = $dest+"\"+$App_Folder_Main+"\"+$AppVersionDownload
            Move-Item -Path $dest\ddmsetup.exe -Destination $TargetFolder
            

            #loging informations
            $xmlloging.WriteStartElement("Applications")
            $xmlloging.WriteAttributeString("Name",$App_Folder_Main)
            $xmlloging.WriteAttributeString("Version",$AppVersionDownload)
            $xmlloging.WriteAttributeString("Status","download")
            $xmlloging.WriteEndElement()

            #generate a XML with install instructions
            $xmlInstComm = New-Object System.Xml.XmlTextWriter("$dest\$App_Folder_Main\$AppVersionDownload\Install.xml",$null)
            #Formating XML File
            $xmlInstComm.Formatting = "Indented"
            $xmlInstComm.Indentation = "1"
            $xmlInstComm.IndentChar = "`t"

            #writing datas
            $xmlInstComm.WriteStartDocument()
            $xmlInstComm.WriteStartElement("InstallInformations")
            $xmlInstComm.WriteStartElement("Application")
            $xmlInstComm.WriteStartElement("CommandLineData")
            $xmlInstComm.WriteAttributeString("Name",$App_Folder_Main)
            $xmlInstComm.WriteAttributeString("Arguments","/VerySilent /NoUpdate")
            $xmlInstComm.WriteAttributeString("DefaultResult","")
            $xmlInstComm.WriteAttributeString("RebootByDefault","false")
            $xmlInstComm.WriteAttributeString("Program",$FileName)
            $xmlInstComm.WriteEndElement()
            $xmlInstComm.WriteStartElement("PackageData")
            $xmlInstComm.WriteAttributeString("VendorName","Dell Inc.")
            $xmlInstComm.WriteAttributeString("CreationDate","")
            $xmlInstComm.WriteAttributeString("PackageID","")
            $xmlInstComm.WriteAttributeString("InfoURL","")
            $xmlInstComm.WriteEndElement()
            $xmlInstComm.WriteStartElement("UpdateData")
            $xmlInstComm.WriteAttributeString("Severity","")
            $xmlInstComm.WriteAttributeString("DriverID","")
            $xmlInstComm.WriteAttributeString("DownloadLink",$downloadPath)
            $xmlInstComm.WriteAttributeString("Modified","")
            $xmlInstComm.WriteEndElement()
                                   
            $xmlInstComm.WriteEndElement()
        
            #Close Document and delete buffer
            $xmlInstComm.WriteEndDocument()
            $xmlInstComm.Flush()
            $xmlInstComm.Close()

        
            }
        }
    
    If ($Folder_Delete -match "Y")
        {
        
        Set-Location $dest
        Set-Location $App_Folder_Main
        
        ### Delete older folder if deletion is selected
        $FolderNameOld = Get-ChildItem | Select-Object -ExpandProperty Name

        foreach ($Name in $FolderNameOld)
            {

            [Version]$Name = $Name

            if($Name -ge $File_Version)
                {

                Write-Output "$App_Folder_Main $Name" "is outdated/UptoDate and not deleted from this device"
                #loging informations
                $xmlloging.WriteStartElement("Applications")
                $xmlloging.WriteAttributeString("Name",$App_Folder_Main)
                $xmlloging.WriteAttributeString("Version",$Name)
                $xmlloging.WriteAttributeString("Status","outdated/uptodate and still exist")
                $xmlloging.WriteEndElement()

                }
            Else
                {
                
                Write-Output "$App_Folder_Main $Name" "is outdated and is now deleted from this device"
                Remove-Item $Name -Recurse -Force

                #loging informations
                $xmlloging.WriteStartElement("Applications")
                $xmlloging.WriteAttributeString("Name",$App_Folder_Main)
                $xmlloging.WriteAttributeString("Version",$Name)
                $xmlloging.WriteAttributeString("Status","delete")
                $xmlloging.WriteEndElement()
                

                }
            }


        }

    $IEAuto.Quit()

    Set-Location \
    
    }




function check-folder
    {

    param
        (

        [string]$FolderName,
        [string]$FolderPath


        )

    #Check if Folder is availible, if not it will generate a new folder
    If((Test-Path $FolderPath) -ne $true)
        {

        Write-Output "Folder is not availble will now generate $FolderName"
        New-Item -Path $FolderPath -itemType Directory

        #Logging informations
        $xmlloging.WriteStartElement($FolderName)
        $xmlloging.WriteAttributeString("Path",$FolderPath)
        $xmlloging.WriteAttributeString("FolderCreated",$true)
        $xmlloging.WriteEndElement()
    
        }
    Else
        {

        #Logging informations
        $xmlloging.WriteStartElement($FolderName)
        $xmlloging.WriteAttributeString("Path",$FolderPath)
        $xmlloging.WriteAttributeString("FolderCreated",$false)
        $xmlloging.WriteEndElement()

        }


    }





#########################################################################################################
####                                    Program Section                                              ####
#########################################################################################################
        
#Prepare Temp folder
$TestTempfolder = Test-Path -Path $Temp_Folder

If ($TestTempfolder -eq $false)
    {
        Write-Host "no Temp folder exist. Folder will generate"
        New-Item -Path $Temp_Folder -ItemType Directory

    }


#Prepare XML file for loging
$logingfilename = $Temp_Folder+"\download_log"+$date+".xml"
$xmlloging = New-Object System.Xml.XmlTextWriter("$Temp_Folder\download_log_$date.xml",$null) 

#Formating XML File
$xmlloging.Formatting = "Indented"
$xmlloging.Indentation = "1"
$xmlloging.IndentChar = "`t"

#writing datas header
$xmlloging.WriteStartDocument()
$xmlloging.WriteStartElement("LoggingInformations")
$xmlloging.WriteStartElement("ScriptRuntime")
$xmlloging.WriteAttributeString("StartTime",(Get-Date).ToString())
$xmlloging.WriteEndElement()
$xmlloging.WriteStartElement("Environment")
$xmlloging.WriteAttributeString("Repository",$dest)
$xmlloging.WriteAttributeString("TempFolder",$Temp_Folder)
$xmlloging.WriteAttributeString("CatalogName",$Catalog_XML)
$xmlloging.WriteEndElement()



##################################################
#### Checking if all folders are availible    ####
##################################################   

#Logging informations start section for Folder tests
$xmlloging.WriteStartElement("FolderCheck")

############################
#### Check $Temp_Folder ####
############################

#### Check if $Temp_Folder is availible, if not it will generate a new folder
check-folder -FolderName "Logging" -FolderPath $Temp_Folder


#### Check if $dest is availible, if not it will generate a new folder
check-folder -FolderName "Repository" -FolderPath $dest


#### Check if $Catalog_Archive Folder is availible, if not it will generate a new folder
check-folder -FolderName "Archive" -FolderPath $Catalog_Archive

# logging end the folder check section
$xmlloging.WriteEndElement()


##############################################################
#Checking if the newest version of catalogs was stored locally

# Checking Header of webpage when last-modified of CAB-File
$result = Invoke-WebRequest -Method HEAD -Uri $url -UseBasicParsing
[datetime]$Catalog_DateOnline = $result.Headers.'Last-Modified'

#Checking date of modified of local stored catalog files
Set-Location $Temp_Folder
If ((Test-Path $Catalog_Name) -ne "True")
    {
    
    [datetime]$Catalog_DateLocal = $Catalog_DateOnline.AddDays(-1)

    
    }
else
    {

    [datetime]$Catalog_DateLocal = Get-ItemProperty $Catalog_Name | Select-Object -ExpandProperty LastWriteTime

    }

# New Catalog will only download and extract the Catalog if Online version is newer than local version
If ($Catalog_DateOnline -gt $Catalog_DateLocal)
    {

    # Download the catalog File newest version
    Start-BitsTransfer -Source $url -Destination $Temp_Folder -displayname "Download Dell SCCM Catalog"

    # Logging Informations
    $xmlloging.WriteStartElement("DellUpdateCatalog")
    $xmlloging.WriteAttributeString("Downloaded","true")
    $xmlloging.WriteAttributeString("DateCatalog",$Catalog_DateLocal)
    $xmlloging.WriteEndElement()

    
    #checking if XML file exist in $Temp_Folder
    $Catalog_XML_Check = Test-Path -Path $Temp_Folder\$Catalog_XML

    If ($Catalog_XML_Check -eq "True")
        {

        #Archiving old Catalog XML to Software Repository Archiving folder
        #Source and destination string prepare
        $Archive_Source = $Temp_Folder+"\"+$Catalog_XML
        $Archive_Destination = $Catalog_Archive+"\"+$date+$Catalog_XML

        #move file to repository   
        Move-Item $Archive_Source -Destination $Archive_Destination -Force

        # Logging Informations
        $xmlloging.WriteStartElement("XMLArchive")
        $xmlloging.WriteAttributeString("Archived","true")
        $xmlloging.WriteAttributeString("FileName",$Archive_Destination)
        $xmlloging.WriteAttributeString("Date",$date)
        $xmlloging.WriteEndElement()
          
          
        }
    Else
        {

        Write-Output "$Temp_Folder does not have a file $Catalog_XML" 
        
        # Logging Informations
        $xmlloging.WriteStartElement("XMLArchive")
        $xmlloging.WriteAttributeString("Archived","false")
        $xmlloging.WriteAttributeString("FileName","no File")
        $xmlloging.WriteAttributeString("Date",$date)
        $xmlloging.WriteEndElement()


        }
            
        
    }
Else
    {

    Write-Output "No newer Catalog is availible"

    # Logging Informations
    $xmlloging.WriteStartElement("DellUpdateCatalog")
    $xmlloging.WriteAttributeString("Downloaded","false")
    $xmlloging.WriteAttributeString("DateCatalog",$Catalog_DateLocal)
    $xmlloging.WriteEndElement()
        
    }

#checking if XML file exist in $Temp_Folder
$Catalog_XML_Check = Test-Path -Path $Temp_Folder\$Catalog_XML

If ($Catalog_XML_Check -eq "True")
    {

    Write-Output "$Temp_Folder have a file $Catalog_XML"

    }
Else
    {

    # Extract Catalog XML-File form existing CAB-File
    # Change directory
    Set-Location $Temp_Folder

    # Extract DellSDPCatalogPC.xml from CAB-File
    expand $Catalog_Name . -f:$Catalog_XML

    }

# Transfer XML data to VAR
[XML]$Catalog_DATA = Get-Content $Temp_Folder\$Catalog_XML


##############################################
#         Section Application Download    ####
##############################################

#### starting logging sessing for downloads
$xmlloging.WriteStartElement("DownloadInformations")

###################################
#### Dell Command Configure    ####
###################################

If ($Command_Configure -eq "Enabled")
    {

    Download-Dell -Software_Name $Command_Configure_Name -Software_Version $Command_Configure_Version -App_Folder_Main $Command_Configure_FolderName

    }
Else
    {

    Write-Output "no Dell Command | Configure selected"
    
    }

###################################
#### Dell Command Monitor      ####
###################################
    
If ($Command_Monitor -eq "Enabled")
    {

    Download-Dell -Software_Name $Command_Monitor_Name -Software_Version $Command_Monitor_Version -App_Folder_Main $Command_Monitor_FolderName

    }
Else
    {

    Write-Output "no Dell Command | Monitor selected"
    
    }

###################################
#### Dell Power Manager        ####
###################################

If ($Power_Manager -eq "Enabled")
    {

    Download-Dell -Software_Name $Power_Manager_Name -Software_Version $Power_Manager_Version -App_Folder_Main $Power_Manager_FolderName

    }
Else
    {

    Write-Output "no Dell Power Manager selected"
    
    }

###################################
#### Dell Optimizer            ####
###################################

If ($Optimizer -eq "Enabled")
    {

    Download-Dell -Software_Name $Optimizer_Name -Software_Version $Optimizer_Version -App_Folder_Main $Optimizer_FolderName

    }
Else
    {

    Write-Output "no Dell Optimizer selected"
    
    }

###################################
#### Dell PremierColor         ####
###################################

If ($PremierColor -eq "Enabled")
    {

    Download-Dell -Software_Name $PremierColor_Name -Software_Version $PremierColor_Version -App_Folder_Main $PremierColor_FolderName

    }
Else
    {

    Write-Output "no Dell PremierColor selected"
    
    }

###################################
#### Dell Digital Delivery     ####
###################################

If ($Digital_Delivery -eq "Enabled")
    {

    Download-Dell -Software_Name $Digital_Delivery_Name -Software_Version $Digital_Delivery_Version -App_Folder_Main $Digital_Delivery_FolderName

    }
Else
    {

    Write-Output "no Dell Digital Delivery selected"
    
    }

####################################
#### Dell Rugged Control Center ####
####################################

If ($RuggedControl_Center -eq "Enabled")
    {

    Download-Dell -Software_Name $RuggedControl_Center_Name -Software_Version $RuggedControl_Center_Version -App_Folder_Main $RuggedControl_Center_FolderName

    }
Else
    {

    Write-Output "no Dell Rugged Control Center selected"
    
    }


###################################
#### Dell Command Update       ####
###################################

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

<#
###################################
#### Dell Trusted Device       ####
###################################

If ($Trusted_Device -eq "Enabled")
    {

    download-delltool -Webpage $url_DTD -FileName $Trusted_Device_Name -App_Folder_Main $Trusted_Device_FolderName -File_Version $Trusted_Device_Version

    }
Else
    {

    Write-Output "no Dell Trusted Device selected"
    
    }


###################################
#### Dell Display Manager      ####
###################################

If ($Display_Manager -eq "Enabled")
    {

    download-delltool -Webpage $url_DDM -FileName $Display_Manager_Name -App_Folder_Main $Display_Manager_FolderName -File_Version $Display_Manager_Version

    }
Else
    {

    Write-Output "no Dell Display Manager selected"
    
    }

    #>
##################################################
#### Program ending and cleaning              ####
##################################################

#Close Document and delete buffer
$xmlloging.WriteEndDocument()
$xmlloging.Flush()
$xmlloging.Close()