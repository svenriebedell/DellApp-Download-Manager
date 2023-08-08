<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.3.3
_Dev_Status_ = Test
Copyright © 2023 Dell Inc. or its subsidiaries. All Rights Reserved.

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
1.2.0   Updating Download function Dell-Download
1.3.1   Move to selenius browser automation for download of Trusted Device / Display Manager 2.x
        migrate single Var´s to Arrays
        integrate Dell Display Manager 1.x download
1.3.2   Issue for DTD and DDM Download www.dell.com/support switch to dynamic xPath. Change query concept to cover this by element search.
1.3.3   add Dell Peripheral Manager

Knowing Issues
-   If a app in catalog is changed from published to expired the deletion of this folder be script does not work anymore. 
    The reason is the function made a preselection and ignore all expired apps the $App_Folder will be empty for this version 
    and deletion need to do manual.
-   If you using Version older than 1.0.3 you need to delete the Software Repository to generate Install.XML


#>

<#
.Synopsis
   This PowerShell is checking the DellSDPCatalogPC.CAB form Https://Downloads.dell.com and online dell.com/support. This script will generated new folders and downloading Dell Tools in specific Versions direct from the Dell Support Webpage. Older Files will be ignored or if downloaded in the past the folder will be delete.
   IMPORTANT: This scipt need internet connection and https://downloads.dell.com need to be reachable.
   IMPORTANT: This script does not reboot the system to apply or query system.
   IMPORTANT: Dell Display Manager / Dell Trusted Device using selenius browser automation to download informations from dell.com/support

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
    [PSCustomObject]@{Name = "Dell Command | Monitor"; UpdateStatus = $true; Version = "10.5.1.114"; Matchcode = "*Command*Monitor*"; Source = "SCCM"; Foldername = "Dell Command Monitor"}
    [PSCustomObject]@{Name = "Dell Command | Configure"; UpdateStatus = $true; Version = "4.5.0.205"; Matchcode = "*Command*Configure*"; Source = "SCCM"; Foldername = "Dell Command Configure"}
    [PSCustomObject]@{Name = "Dell Command | Update Legacy"; UpdateStatus = $true; Version = "4.3.0"; Matchcode = "*Command*Update*"; Source = "SCCM"; Foldername = "Dell Command Update W32"}
    [PSCustomObject]@{Name = "Dell Command | Update UWP"; UpdateStatus = $true; Version = "4.3.0"; Matchcode = "*Command*Update*Windows*"; Source = "SCCM"; Foldername = "Dell Command Update UWP"}
    [PSCustomObject]@{Name = "Dell Digital Delivery"; UpdateStatus = $true; Version = "5.0.49.0"; Matchcode = "Dell*Digital*Delivery*"; Source = "SCCM"; Foldername = "Dell Digital Deliver"}
    [PSCustomObject]@{Name = "Dell Optimizer"; UpdateStatus = $true; Version = "2.0.753.0"; Matchcode = "Dell Optimizer*"; Source = "SCCM"; Foldername = "Dell Optimizer"}
    [PSCustomObject]@{Name = "Dell Power Manager"; UpdateStatus = $true; Version = "3.9"; Matchcode = "*Power*Manager*"; Source = "SCCM"; Foldername = "Dell Power Manager"}
    [PSCustomObject]@{Name = "Dell PremierColor"; UpdateStatus = $true; Version = "6.0.152.0"; Matchcode = "Dell PremierColor*"; Source = "SCCM"; Foldername = "Dell PremierColor"}
    [PSCustomObject]@{Name = "Dell RuggedControl Center"; UpdateStatus = $true; Version = "4.3.55.0"; Matchcode = "Dell*Rugged*Control*"; Source = "SCCM"; Foldername = "Dell Rugged Control Center"}
    [PSCustomObject]@{Name = "Dell Trusted Device"; UpdateStatus = $true; Version = "3.7.89.0"; Matchcode = "*Trusted Device*"; Source = "Online"; Foldername = "Dell Trusted Device"}
    [PSCustomObject]@{Name = "Dell Display Manager Legacy"; UpdateStatus = $true; Version = "1.54.2068"; Matchcode = "*Display Manager*"; Source = "3rdlink"; Foldername = "Dell Display Manager Legacy"}
    [PSCustomObject]@{Name = "Dell Display Manager"; UpdateStatus = $true; Version = "2.0.0.135"; Matchcode = "*Display Manager*"; Source = "Online"; Foldername = "Dell Display Manager"}
    [PSCustomObject]@{Name = "Dell Peripheral Manager"; UpdateStatus = $true; Version = "1.6.4.0"; Matchcode = "*Peripheral Manager*"; Source = "Online"; Foldername = "Dell Peripheral Manager"}
    )

       
################################################
#### Automatically delete outdated programs ####
################################################

########################################## 
#### possible Value: Y/N              ####
##########################################
$Folder_Delete = "Y"

########################################## 
#### prefered Browser                 ####
##########################################
$SelectBrowser = "Edge"  # Chrome, Edge or Firefox

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
$downloadpages = @(
    [PSCustomObject]@{Name = "CatalogFile"; WebPath = "https://downloads.dell.com/catalog/$Catalog_Name"}
    [PSCustomObject]@{Name = "Dell Trusted Device"; WebPath = "https://www.dell.com/support/home/de-de/product-support/product/trusted-device/drivers"}
    [PSCustomObject]@{Name = "Dell Display Manager"; WebPath = "https://www.dell.com/support/home/de-de/product-support/product/dell-display-peripheral-manager/drivers"}
    [PSCustomObject]@{Name = "Dell Peripheral Manager"; WebPath = "https://www.dell.com/support/home/de-de/product-support/product/dell-display-peripheral-manager/drivers"}
    [PSCustomObject]@{Name = "Dell Display Manager Legacy"; WebPath = "https://www.delldisplaymanager.com/ddmsetup.exe"}
    )

################################################
#### local Folders                          ####
################################################
$ENVFolder = @(
    [PSCustomObject]@{Name = "Software Repository"; FSPath = "C:\Dell\SoftwareRepository"}              # Software folder
    [PSCustomObject]@{Name = "Temporary Folder"; FSPath = "C:\Temp"}                                    # Logging folder
    [PSCustomObject]@{Name = "Archive Folder"; FSPath = "C:\Dell\SoftwareRepository\Catalog_Archive"}   # Archive folder for older catalogs
    )

#########################################################################################################
####                                    Function Section                                              ####
#########################################################################################################

#####################################################
#### Function preparation for Browser automation ####
#### SOURCE:                                     ####
#### https://administrator.de/tutorial/powershell-einfuehrung-in-die-webbrowser-automation-mit-selenium-webdriver-1197173647.html ####
#####################################################

function Create-Browser 
    {
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
                $chrome = Get-Package -Name 'Google Chrome' -EA SilentlyContinue | select-object -F 1
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
                $edge = Get-Package -Name 'Microsoft Edge' -EA SilentlyContinue | Select-Object -F 1
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
                $ff = Get-Package -Name "Mozilla Firefox*" -EA SilentlyContinue | Select-Object -F 1
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


#####################################################
#### Function check environment folder exit      ####
#####################################################
function get-Folderstatus {
    param(
        [Parameter(mandatory=$true)][string]$FolderName,
        [Parameter(mandatory=$false)][string]$FolderPath

    )

    #Check if Folder is availible, if not it will generate a new folder
    If((Test-Path $FolderPath) -ne $true)
        {

        Write-Output "Folder is not availble will now generate $FolderName"
        New-Item -Path $FolderPath -itemType Directory

        }
        Else
        {

        Write-Output "$FolderName is available"

        }


}


#####################################################
#### Function download Dell Catalog file         ####
#####################################################

function get-DellCatalog {
    param(
        [Parameter(mandatory=$true)][string]$url

    )

    ##############################################################
    #Checking if the newest version of catalogs was stored locally

    # Checking Header of webpage when last-modified of CAB-File
    $result = Invoke-WebRequest -Method HEAD -Uri $url -UseBasicParsing
    [datetime]$Catalog_DateOnline = $result.Headers.'Last-Modified'

    #Checking date of modified of local stored catalog files
    Set-Location ($ENVFolder | Where-Object Name -eq "Temporary Folder").FSPath
    
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
        Start-BitsTransfer -Source $url -Destination ($ENVFolder | Where-Object Name -eq "Temporary Folder").FSPath -displayname "Download Dell SCCM Catalog"

        
        #checking if XML file exist in ($ENVFolder | Where-Object Name -eq "Temporary Folder").FSPath
        $FileCheck = ($ENVFolder | Where-Object Name -eq "Temporary Folder").FSPath+"\"+$Catalog_XML
        $Catalog_XML_Check = Test-Path -Path $FileCheck

        If ($Catalog_XML_Check -eq "True")
            {
            

            #Archiving old Catalog XML to Software Repository Archiving folder
            #Source and destination string prepare
            $Archive_Source = ($ENVFolder | Where-Object Name -eq "Temporary Folder").FSPath+"\"+$Catalog_XML
            $Archive_Destination = ($ENVFolder | Where-Object Name -eq "Archive Folder").FSPath+"\"+$date+$Catalog_XML

            #move file to repository
            write-host "Older $Catalog_XML is existing and will be archived now to $Archive_Destination"  
            Move-Item $Archive_Source -Destination $Archive_Destination -Force

            # Extract Catalog XML-File form existing CAB-File
            # Change directory
            Set-Location ($ENVFolder | Where-Object Name -eq "Temporary Folder").FSPath
            
            Write-Output "Catalog XML will be extracted to Temporary Folder" 
            # Extract DellSDPCatalogPC.xml from CAB-File
            expand $Catalog_Name . -f:$Catalog_XML

                    
            }
        Else
            {

            Write-Output "Temporary Folder do not include an old file $Catalog_XML for archiving" 
            
            # Extract Catalog XML-File form existing CAB-File
            # Change directory
            Set-Location ($ENVFolder | Where-Object Name -eq "Temporary Folder").FSPath
            
            Write-Output "Catalog XML will be extracted to Temporary Folder" 
            # Extract DellSDPCatalogPC.xml from CAB-File
            expand $Catalog_Name . -f:$Catalog_XML

            }
                
            
        }
    Else
        {

        Write-Output "No newer Catalog is availible"

        Write-Output "Checking if XML is stored in Temporary Folder"

        #checking if XML file exist in ($ENVFolder | Where-Object Name -eq "Temporary Folder").FSPath
        $FileCheck = ($ENVFolder | Where-Object Name -eq "Temporary Folder").FSPath+"\"+$Catalog_XML
        $Catalog_XML_Check = Test-Path -Path $FileCheck

        If ($Catalog_XML_Check -eq "True")
            {           

            Write-Output "Catalog XML is existing in Temporary Folder" 
                    
            }
        Else
            {

            Write-Output "Temporary Folder do not include an $Catalog_XML" 
            
            # Extract Catalog XML-File form existing CAB-File
            # Change directory
            Set-Location ($ENVFolder | Where-Object Name -eq "Temporary Folder").FSPath
            
            Write-Output "Catalog XML will be extracted to Temporary Folder" 
            # Extract DellSDPCatalogPC.xml from CAB-File
            expand $Catalog_Name . -f:$Catalog_XML

            }

        }

}


#####################################################
#### Function download with SCCM Catalog         ####
#####################################################

### Function is for all Applications excl. Dell Trusted Device and Dell Display Manager 2.x and newer

function get-SCCMSoftware 
    {
    
    # Parameter
    param(
        [Parameter(mandatory=$true)][string]$Software_Name,
        [Parameter(mandatory=$true)][version]$Software_Version,
        [Parameter(mandatory=$true)][string]$App_Folder_Main
        
         )
    
    

    #Prepare Download struture
    Set-Location ($ENVFolder | Where-Object Name -eq "Software Repository").FSPath
    
    Write-Host "Checking if Application folder exist"
    If ((Test-Path $App_Folder_Main) -ne "True")
        {
        # generate new main software folder
        Write-Host "New $App_Folder_Main will generate"
        New-Item $App_Folder_Main -ItemType Directory

        }
    else 
        {
        
        Write-Host "$App_Folder_Main is availible"

        }

    Set-Location $App_Folder_Main

    #Prepare Download details
    $Dell_App_Select = $Catalog_DATA.SystemsManagementCatalog.SoftwareDistributionPackage | Where-Object{$_.LocalizedProperties.Title -like "$Software_Name"}
    $Dell_App_Download = $Dell_App_Select | Where-Object {$_.Properties.PublicationState -ne "Expired"}
    

    #Checking Dell Command Update Win32 or UWP App - Deselect not relevant Software first before prepare download

    If ($Software_Name -eq ($DownloadSoftware | Where-Object Name -eq "Dell Command | Update Legacy").Matchcode)
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
                    $XMLInstallFile = ($ENVFolder | Where-Object Name -eq "Software Repository").FSPath+"\"+$App_Folder_Main+"\"+$App_Folder+"\Install.xml"
                    $xmlInstComm = New-Object System.Xml.XmlTextWriter($XMLInstallFile,$null)
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

                                        
                    }
                             
                Else
                    {
                    
                    Write-Output $i.localizedproperties.title "is existing on the machine"
                                        
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



############################################################
#### Function download with Browser on Dell.com/support ####
############################################################

### Function is for Dell Trusted Device and Dell Display Manager 2.x and newer

function get-OnlineSoftware
    {
    
    param
        (
        
        [Parameter(mandatory=$true)][string]$Webpage,
        [Parameter(mandatory=$true)][string]$Software_Name,
        [Parameter(mandatory=$true)][string]$App_Folder_Main,
        [Parameter(mandatory=$true)][version]$Software_Version,
        [Parameter(mandatory=$true)][string]$Browser
       
        )


    #Prepare Download struture
    Set-Location ($ENVFolder | Where-Object Name -eq "Software Repository").FSPath
    
    Write-Host "Checking if Application folder exist"
    If ((Test-Path $App_Folder_Main) -ne "True")
        {
        # generate new main software folder
        Write-Host "New $App_Folder_Main will generate"
        New-Item $App_Folder_Main -ItemType Directory

        }
    else 
        {
        
        Write-Host "$App_Folder_Main is availible"

        }
    

    Set-Location $App_Folder_Main
        
    ### Start install selenium for download Webpage informations and files
    $EdgeAuto = Create-Browser -browser Edge #$Browser
    $EdgeAuto.Manage().Window.Minimize()
    $EdgeAuto.Url = $Webpage
   
    # wait stepp to be secure website is full loaded
    Start-Sleep -Seconds 5

    #expand driver informations in browser
    if ($App_Folder_Main -like "*Trusted*")
        {
            # open drop down menue on webpage
            ($EdgeAuto.FindElements([OpenQA.Selenium.By]::TagName("button")) | where-Object ComputedAccessibleLabel -Like "*Trusted*Agent*" | Where-Object ComputedAccessibleLabel -notlike "*S*ripte*").click()
                    
            # get version of app from dell.com/support for Trusted Device Agent
            Write-Host "Search online for newest software version"
            $AppVersionOnlineTemp = ($EdgeAuto.FindElements([OpenQA.Selenium.By]::Classname("mb-0")) | where-object text -Clike "*.*,*" | Where-Object Text -notlike "*Agent*").Text.Split(",")
             #exclude Revision and store Version in format version
            [Version]$AppVersionOnline = $AppVersionOnlineTemp[0]
        
        }
    if ($App_Folder_Main -like "*Peripheral*") 
        {
            # used for Dell Peripheral Manager
                        
            # open drop down menue on webpage
            ($EdgeAuto.FindElements([OpenQA.Selenium.By]::TagName("button")) | where-Object ComputedAccessibleLabel -Like "*Dell*Peripheral*Manager*" | Where-Object ComputedAccessibleLabel -Notlike "*Dell*Display*Manager*").click()
            
            # get version of app from dell.com/support for Dell Peripheral Manager 
            Write-Host "Search online for newest software version"
            $AppVersionOnlineTemp = ($EdgeAuto.FindElements([OpenQA.Selenium.By]::Classname("mb-0")) | where-object text -like "*|*").Text.Split(",")
             #exclude Revision and store Version in format version
            [Version]$AppVersionOnline = $AppVersionOnlineTemp[0]
        }
    if ($App_Folder_Main -like "*Display Manager*") 
        {
            # used for Dell Display Manager 2.x and newer
                        
            # open drop down menue on webpage
            ($EdgeAuto.FindElements([OpenQA.Selenium.By]::TagName("button")) | where-Object ComputedAccessibleLabel -Like "*Dell*Display*Manager*" | Where-Object ComputedAccessibleLabel -Notlike "*Peripheral*").click()
            
            # get version of app from dell.com/support for Trusted Device Agent
            Write-Host "Search online for newest software version"
            $AppVersionOnlineTemp = ($EdgeAuto.FindElements([OpenQA.Selenium.By]::Classname("mb-0")) | where-object text -like "*|*").Text.Split(",")
             #exclude Revision and store Version in format version
            [Version]$AppVersionOnline = $AppVersionOnlineTemp[0]

        }
    

    ### Check if folder with same Version is still existing
    Write-Host "Checking if Subfolder is availible"
    If ((Test-Path $AppVersionOnline) -ne $true)
        {
            
            Write-Host "New Subfolder $AppVersionOnline will generate"
            # generate new Version folder
            New-Item $AppVersionOnline -ItemType Directory
             
        }
    else 
        {
        
            Write-Host "Subfolder $AppVersionOnline is available"

        }

    Set-Location $AppVersionOnline

    # Checking how much files are stored in this folder. If 0 the file will reload again
    $File_Count = Get-ChildItem -Path $App_Folder -Recurse | Measure-Object | Select-Object -ExpandProperty Count
    
    if($File_Count -gt 0)
        {

        Write-Output "$App_Folder_Main $AppVersionOnline" "is existing on the to machine" 
       
        # Close Browser
        $EdgeAuto.Close()

        }
    Else
        {
        
            Write-Output "$App_Folder_Main $AppVersionOnline is downloading to machine"                  
            
            # get download path of app from dell.com/support
            if ($App_Folder_Main -like "*Trusted*")
                {
                    # Download Dell Trusted Device Agent
                    ($EdgeAuto.FindElements([OpenQA.Selenium.By]::Classname("btn-download-lg"))| Where-Object ComputedAccessibleLabel -like "*Trusted*" | Where-Object ComputedAccessibleLabel -notlike "*S*ripte*").click()
                
                }
            if ($App_Folder_Main -like "*Peripheral*")
                {
                        
                    # Download Dell Peripheral Manager
                    ($EdgeAuto.FindElements([OpenQA.Selenium.By]::Classname("btn-download-lg"))| Where-Object ComputedAccessibleLabel -like "*Peripheral*" ).click()
                }
            
            if ($App_Folder_Main -like "*Display Manager*")
                {
                    
                    # Download Dell Display Manager 2.x
                    ($EdgeAuto.FindElements([OpenQA.Selenium.By]::Classname("btn-download-lg"))| Where-Object ComputedAccessibleLabel -like "*Display*" ).click()
                
                }
        
            Write-Host "File Download is startet, please do not close the Browser"
            # wait of finializing download
            Start-Sleep -Seconds 15  
        
            ### handling file copy different between DTD and DDM
            If ($Software_Name -like "*Trusted Device*")
                {
                    
                    Set-Location $env:USERPROFILE\Downloads
                    
                    #checking if download is final if not add 10 sec download time
                    $checkDownload = Test-Path -Path .\Trusted-Device-$AppversionOnline.zip

                    If ($checkDownload -eq $true)
                        {

                            Write-Host ".\Trusted-Device-$AppversionOnline.zip is finished to download"

                        }
                    else 
                        {
                        
                            # download is not finished yet extand time before closing browser
                            Write-Host "Download is not finished yet, please wait"
                            Start-Sleep -Seconds 15
                        
                        }

                    $checkDownload = Test-Path -Path .\Trusted-Device-$AppversionOnline.zip

                    If ($checkDownload -eq $true)
                        {

                            ### unzip Installer
                            Write-Host "unzip Dell Trusted Device File"
                            Expand-Archive .\Trusted-Device-$AppversionOnline.zip -Force
                            Start-Sleep -Seconds 5

                            ### delete zip from folder
                            Write-Host "delete Zip file .\Trusted-Device-$AppversionOnline.zip"
                            Remove-Item .\Trusted-Device-$AppversionOnline.zip -Force

                            ### get installer file name for 64-Bit Version and move it to top of version folder
                            $DirectoryMain = Get-ChildItem -Directory | Where-Object Name -EQ "Trusted-Device-$AppversionOnline" | Select-Object -ExpandProperty Name
                            Set-Location $DirectoryMain
                            $Directory64Bit = Get-ChildItem -Directory | Select-Object -ExpandProperty Name | Select-String "Win64R"
                            Set-Location $Directory64Bit
                            $fileName64Bit = Get-ChildItem | Select-Object -ExpandProperty PSChildName
      
                            $TargetFS = ($ENVFolder | Where-Object Name -eq "Software Repository").FSPath+"\"+$App_Folder_Main+"\"+$AppVersionOnline
                            Write-Host "move 64-Installer File to $TargetFS"
                            Move-Item $fileName64Bit -Destination $TargetFS -Force

                            Set-Location $env:USERPROFILE\Downloads

                            ### delete folder and 32-bit Version
                            Write-Host "delete folder and 32-Bit installtion from Download directory"
                            Remove-Item $DirectoryMain -Force -Recurse

                            # xml parameter for this application install.xml
                            $Argument = "/qn REBOOT=R"
                            $RebootbyDefault = $true

                            # Close Browser
                            $EdgeAuto.close()

                        }
                    else 
                        {
                                
                            # download takes to long or automation does not working correctly
                            Write-Host ".\Trusted-Device-$AppversionOnline.zip is not downloaded, please check if you have a problem with internet connection or browser automation works correctly"
                            # Close Browser
                            $EdgeAuto.close()

                        }
                }
                
                                
            If ($Software_Name -like "*Display Manager*")
                {
                    
                    Set-Location $env:USERPROFILE\Downloads

                    # Name of file to download
                    $fileName64Bit = "ddmsetup.exe"
                            
                    #checking if download is final if not add 10 sec download time
                    $checkDownload = Test-Path -Path .\$fileName64Bit
            
                    If ($checkDownload -eq $true)
                        {
                    
                            Write-Host ".\ddmsetup.exe is finished to download"
                    
                        }
                    else 
                        {
                                    
                            # download is not finished yet extand time before closing browser
                            Write-Host "Download is not finished yet, please wait"
                            Start-Sleep -Seconds 15

                        }
                    
                    $checkDownload = Test-Path -Path .\$fileName64Bit
            
                    If ($checkDownload -eq $true)
                        {
                                                
                            $TargetFS = ($ENVFolder | Where-Object Name -eq "Software Repository").FSPath+"\"+$App_Folder_Main+"\"+$AppVersionOnline
                            Write-Host "move File ddmsetup.exe to $TargetFS"
                            Move-Item $fileName64Bit -Destination $TargetFS -Force

                            # xml parameter for this application install.xml
                            $Argument = '/verysilent Silent /TelemetryConsent="false" /noupdate'
                            $RebootbyDefault = $false
                
                            # Close Browser
                            $EdgeAuto.close()
                
                        }
                    else 
                        {
                            
                            # download takes to long or automation does not working correctly
                            Write-Host ".\ddmsetup.exe is not downloaded, please check if you have a problem with internet connection or browser automation works correctly"
                            # Close Browser
                            $EdgeAuto.close()
            
                        }
                }
        
            If ($Software_Name -like "*Peripheral*")
                {
                    
                        Set-Location $env:USERPROFILE\Downloads

                        # Name of file to download
                        $fileName64Bit = "DPeM*.exe"
                    
                        #checking if download is final if not add 15 sec download time
                        $checkDownload = Test-Path -Path .\$fileName64Bit
            
                        If ($checkDownload -eq $true)
                            {
                            
                                $fileName64Bit = get-Item -Path '.\DPeM*.exe' | Select-Object -ExpandProperty Name
                                Write-Host "$fileName64Bit is finished to download" -BackgroundColor Green
            
                            }
                        else 
                            {
                            
                                # download is not finished yet extand time before closing browser
                                Write-Host "Download is not finished yet, please wait" -BackgroundColor Yellow
                                Start-Sleep -Seconds 15

                            }              
                        
                        $checkDownload = Test-Path -Path .\$fileName64Bit
            
                        If ($checkDownload -eq $true)
                            {
                            
                                $fileName64Bit = get-Item -Path '.\DPeM*.exe' | Select-Object -ExpandProperty Name
                                $TargetFS = ($ENVFolder | Where-Object Name -eq "Software Repository").FSPath+"\"+$App_Folder_Main+"\"+$AppVersionOnline
                                Write-Host "move File $fileName64Bit to $TargetFS"
                                Move-Item $fileName64Bit -Destination $TargetFS -Force

                                # xml parameter for this application install.xml
                                $Argument = '/S'
                                $RebootbyDefault = $false
                
                                # Close Browser
                                $EdgeAuto.close()
            
                            }
                        else 
                            {
                            
                                # download takes to long or automation does not working correctly
                                Write-Host "Dell Peripheral Manager  is not downloaded, please check if you have a problem with internet connection or browser automation works correctly"
                                # Close Browser
                                $EdgeAuto.close()
            
                            }
                
          
                }
        

        
        #generate a XML with install instructions
        $XMLInstallFile = ($ENVFolder | Where-Object Name -eq "Software Repository").FSPath+"\"+$App_Folder_Main+"\"+$AppVersionOnline+"\Install.xml"
        $xmlInstComm = New-Object System.Xml.XmlTextWriter($XMLInstallFile,$null)
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
        $xmlInstComm.WriteAttributeString("Arguments",$Argument)
        $xmlInstComm.WriteAttributeString("DefaultResult","")
        $xmlInstComm.WriteAttributeString("RebootByDefault",$RebootbyDefault)
        $xmlInstComm.WriteAttributeString("Program",$fileName64Bit)
        $xmlInstComm.WriteEndElement()
        $xmlInstComm.WriteStartElement("PackageData")
        $xmlInstComm.WriteAttributeString("VendorName","Dell Inc.")
        $xmlInstComm.WriteAttributeString("CreationDate","")
        $xmlInstComm.WriteAttributeString("PackageID","")
        $xmlInstComm.WriteAttributeString("InfoURL",$Webpage)
        $xmlInstComm.WriteEndElement()
        $xmlInstComm.WriteStartElement("UpdateData")
        $xmlInstComm.WriteAttributeString("Severity","")
        $xmlInstComm.WriteAttributeString("DriverID","")
        $xmlInstComm.WriteAttributeString("DownloadLink","")
        $xmlInstComm.WriteAttributeString("Modified","")
        $xmlInstComm.WriteEndElement()
                                   
        $xmlInstComm.WriteEndElement()
        
        #Close Document and delete buffer
        $xmlInstComm.WriteEndDocument()
        $xmlInstComm.Flush()
        $xmlInstComm.Close()
        }
                 
       
    If ($Folder_Delete -match "Y")
        {
        
        Set-Location ($ENVFolder | Where-Object Name -eq "Software Repository").FSPath
        Set-Location $App_Folder_Main
        
        ### Delete older folder if deletion is selected
        $FolderNameOld = Get-ChildItem | Select-Object -ExpandProperty Name

        foreach ($Name in $FolderNameOld)
            {

            [Version]$Name = $Name

            if($Name -ge $Software_Version)
                {

                Write-Output "$App_Folder_Main $Name" "is outdated/UptoDate and not deleted from this device"

                }
            Else
                {
                
                Write-Output "$App_Folder_Main $Name" "is outdated and is now deleted from this device"
                Remove-Item $Name -Recurse -Force

                }
            }


        }


    
    }

############################################################
#### Function download delldisplaymanager.com           ####
############################################################

### Function is for Dell Display Manager 1.x

function get-ddmlegacy
    {

    # Parameter
    param(
        [Parameter(mandatory=$true)][string]$Software_Name,
        [Parameter(mandatory=$true)][version]$Software_Version,
        [Parameter(mandatory=$true)][string]$App_Folder_Main
         )
    
    #Prepare Download Display Manager
    
    #Get folder with newest version
    Set-Location ($ENVFolder | Where-Object Name -eq "Software Repository").FSPath
    
    If((Test-Path $App_Folder_Main) -ne "True")
        {
    
        # generate new main App Folder
        Write-Host "$App_Folder_Main will be generate"
        New-Item $App_Folder_Main -ItemType Directory

        }
    else 
        {
            "$App_Folder_Main is availible"
        }
        
    Set-Location $App_Folder_Main
    
    #checking Online Page date
    Write-Host "Checking File status on Webpage"
    $url_DDM = ($downloadpages | Where-Object name -EQ "Dell Display Manager Legacy").WebPath
    $DDMPageCheck = Invoke-WebRequest -Method HEAD -Uri $url_DDM -UseBasicParsing
    [datetime]$DDMPageDate = $DDMPageCheck.Headers.'Last-Modified'
        
    #Checking Subfolder looking for the newest Software version folder and select folder name
    $App_Folder = @(Get-ChildItem -Directory | Sort-Object -Descending name | Select-Object -ExpandProperty Name)

    # Checking how much files are stored in this folder. If 0 the file will reload again
    $File_Count = Get-ChildItem -Path $App_Folder[0] -Recurse | Measure-Object | Select-Object -ExpandProperty Count

    If ($File_Count -lt 1)
        {
        Write-Host "No old files availible"
        # fill var $DDMFileCheck with a date to surpres any script warning. Using webpage date -1 day to secure it will run trought download part.
        [datetime]$DDMFileCheck = $DDMPageDate.AddDays(-1)

        }
    
    Else
        {
        
        #checking file date       
        [datetime]$DDMFileCheck = (Get-ChildItem -Path $App_Folder[0] -File | Select-Object -ExpandProperty LastWriteTime)[0]
        
        }
    
    

    If ($DDMPageDate -gt $DDMFileCheck)
        {
        Write-Host "Newer ddmsetup.exe is availible starting download"
        #Download installer from delldisplaymanager.com
        Start-BitsTransfer -Source $url_DDM -Destination ($ENVfolder | Where-Object Name -eq "Temporary Folder").FSPath -DisplayName $Software_Name

        $DDM_Temp_Version = $($ENVfolder | Where-Object Name -eq "Temporary Folder").FSPath+"\ddmsetup.exe"
        $DDM_Temp_Version = ((Get-Item $DDM_Temp_Version | Select-Object -ExpandProperty Versioninfo).ProductVersion -split" ")[0]
        [Version]$DDM_Version = $DDM_Temp_Version
            
        #Prepare Download struture
        Set-Location ($ENVFolder | Where-Object Name -eq "Software Repository").FSPath
    
        If((Test-Path $App_Folder_Main) -ne "True")
            {
        
            # generate new main App Folder
            Write-Host "$App_Folder_Main will be generate"
            New-Item $App_Folder_Main -ItemType Directory

            }
        else 
            {
                "$App_Folder_Main is availible"
            }

        Set-Location $App_Folder_Main
  

        #Make subfolder structure and move file
        If ((Test-Path $DDM_Version) -ne "True")
            {
            # generate new main software folder
            Write-Host "$DDM_Version will be generate"
            New-Item $DDM_Version -ItemType Directory
            }
        else 
            {
                "Folder $DDM_Version is availible"
            }
    
        #Source and destiontion string prepare
        $DDM_Source = ($ENVfolder | Where-Object Name -eq "Temporary Folder").FSPath+"\ddmsetup.exe"
        $DDM_Destination = ($ENVFolder | Where-Object Name -eq "Software Repository").FSPath+"\"+$App_Folder_Main+"\"+$DDM_Version+"\ddmsetup.exe"
    
        #move file to repository
        Write-Host "Move file ddmsetup.exe from $DDM_Source to $DDM_Destination"  
        Move-Item $DDM_Source -Destination $DDM_Destination -Force

        
        #generate a XML with install instructions selected of Dell SCCM catalog file
        $XMLInstallFile = ($ENVFolder | Where-Object Name -eq "Software Repository").FSPath+"\"+$App_Folder_Main+"\"+$DDM_Version+"\Install.xml"
        $xmlInstComm = New-Object System.Xml.XmlTextWriter($XMLInstallFile,$null)
        #Formating XML File
        $xmlInstComm.Formatting = "Indented"
        $xmlInstComm.Indentation = "1"
        $xmlInstComm.IndentChar = "`t"

        #writing datas
        $xmlInstComm.WriteStartDocument()
        $xmlInstComm.WriteStartElement("InstallInformations")
        $xmlInstComm.WriteStartElement("Application")
        $xmlInstComm.WriteStartElement("CommandLineData")
        $xmlInstComm.WriteAttributeString("Name",$DDM_Name_New)
        $xmlInstComm.WriteAttributeString("Arguments","/verysilent /noupdate")
        $xmlInstComm.WriteAttributeString("DefaultResult","")
        $xmlInstComm.WriteAttributeString("RebootByDefault","false")
        $xmlInstComm.WriteAttributeString("Program",$DDM_Name_New)
        $xmlInstComm.WriteEndElement()
        $xmlInstComm.WriteStartElement("PackageData")
        $xmlInstComm.WriteAttributeString("VendorName","Dell Inc.")
        $xmlInstComm.WriteAttributeString("CreationDate",$DDMFileCheck)
        $xmlInstComm.WriteAttributeString("PackageID","")
        $xmlInstComm.WriteAttributeString("InfoURL","https://www.dell.com/support/kbdoc/en-us/000060112/what-is-dell-display-manager?lwp=rt")
        $xmlInstComm.WriteEndElement()
        $xmlInstComm.WriteStartElement("UpdateData")
        $xmlInstComm.WriteAttributeString("Severity","")
        $xmlInstComm.WriteAttributeString("DriverID","")
        $xmlInstComm.WriteAttributeString("DownloadLink",$url_DDM)
        $xmlInstComm.WriteAttributeString("Modified",$DDMFileCheck)
        $xmlInstComm.WriteEndElement()
                               
        $xmlInstComm.WriteEndElement()
        
        #Close Document and delete buffer
        $xmlInstComm.WriteEndDocument()
        $xmlInstComm.Flush()
        $xmlInstComm.Close()

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

                #loging informations
                $xmlloging.WriteStartElement("Applications")
                $xmlloging.WriteAttributeString("Name","Dell Display Manager")
                $xmlloging.WriteAttributeString("Version",$App_Folder)
                $xmlloging.WriteAttributeString("Status","delete")
                $xmlloging.WriteEndElement()

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

                  
    Set-Location ($ENVFolder | Where-Object Name -eq "Software Repository").FSPath
    

    }


 

#########################################################################################################
####                                    Program Section                                              ####
#########################################################################################################
Write-Host ""############### Update process starts #################""
####################################################
#### prepare Environment folder                 ####
####################################################

Write-Host "############### Folder Check #################"
foreach ($folder in $ENVFolder)
    {

        get-Folderstatus -FolderName $folder.name -FolderPath $folder.FSPath

    }
Write-Host "#############################################"

#####################################################
#### Get Dell DCCM Catalog and Archive old Files ####
#####################################################

Write-Host "############## Catalog Check ################"
get-DellCatalog -url ($downloadpages | Where-Object Name -eq "CatalogFile" | Select-Object -ExpandProperty WebPath)
Write-Host "#############################################"

#####################################################
#### Get newest files                            ####
#####################################################

Write-Host "############## Download Applications ################"

$CatalogFile = ($ENVFolder | Where-Object Name -eq "Temporary Folder").FSPath+"\"+$Catalog_XML
Write-Host "start reading $CatalogFile"
[xml]$Catalog_DATA = Get-Content -Path $CatalogFile

foreach ($App in $DownloadSoftware)
    {

        if ($App.UpdateStatus -eq $true)
            {

            if ($app.Source -eq "SCCM")
                {
                Write-Host "#####################################################"
                Write-Host "############### starting update by SCCM catalog process for $App.Name ##################"
                get-SCCMSoftware -Software_Name $App.Matchcode -Software_Version $App.Version -App_Folder_Main $App.Foldername
    
                }
            
            if ($app.Source -eq "Online")
                {
                # for Trusted Device, New Dell Display Manager 2.x and Dell Peripheral Manager
                Write-Host "#####################################################"
                Write-Host "################## starting update by dell.com/support process for $App.Name #####################"
                Write-Host "## Please do not close the Browser he will be closed after download automatically ##"
                $WebLink = ($downloadpages | Where-Object Name -Like $App.Name).WebPath
                get-OnlineSoftware -Software_Name $App.Matchcode -Browser $SelectBrowser -App_Folder_Main $App.Foldername -Software_Version $App.Version -Webpage $WebLink

                }

            if ($app.Source -eq "3rdlink")
                {
                # for legacy Display manager
                Write-Host "#####################################################"
                Write-Host "############### starting update by https://delldisplaymanager.com process for $App.Name ##################"
                get-ddmlegacy -Software_Name $App.name -Software_Version $App.Version -App_Folder_Main $App.Foldername

                }

            }
        else 
            {
            
            Write-Host "#####################################################"
            Write-Host "################## Update deactivate for $App.Name #####################"
            Write-Host "App is disabled to get Updates"
            Write-Host "#####################################################"
            
            }



    }

Write-Host "##########         Finish        ############"