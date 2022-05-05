# DellApp-Download-Manager

##Descriptiong
This tool is for downloading **Dell Tools** and generate a Software Repository which could be later used for softare packaging or other installation processes.

#### Download Supporting following Applications

- Dell Command | Monitor
- Dell Command | Configure
- Dell Command | Update 32/64 Bit
- Dell Command | Update Universal Application
- Dell Digital Delivery
- Dell Optimizer
- Dell Power Manager
- Dell PremierColor
- Dell Rugged Control Center
- Dell Trusted Device (no in place yet)
- Dell Display Manager

**Legal disclaimer: THE INFORMATION IN THIS PUBLICATION IS PROVIDED 'AS-IS.' DELL MAKES NO REPRESENTATIONS OR WARRANTIES OF ANY KIND WITH RESPECT TO THE INFORMATION IN THIS PUBLICATION, AND SPECIFICALLY DISCLAIMS IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.** In no event shall Dell Technologies, its affiliates or suppliers, be liable for any damages whatsoever arising from or related to the information contained herein or actions that you decide to take based thereon, including any direct, indirect, incidental, consequential, loss of business profits or special damages, even if Dell Technologies, its affiliates or suppliers have been advised of the possibility of such damages.

This script will be used for testing modifications could be have impact of running without issues.

## Details

#### This script is using the following data points to get the relevant download links

- Dell SCCM Update Catalog (DellSDPCatalogPC.cab)
- Dell Display Manager Website (delldisplaymanager.com)

**Please beware the Dell SCCM Update Catalog will be maintained all 14 days so it could be newer versiond of applications are availible by dell.com/support**

## Instructions

#### Applications selections options are availible

- Select downlaod by App
- Oldes Version for download ( if you want to download older versions als well)
- automatic deletion of older Apps (if app version is older than wanted)

#### Output

This script is generate or maintaining a Software Repository. The folder structure is:

- Mainfolder (Repository Path)
- 1.Subfolder (Application Name)
- 2.Subfolder (Application Version)



each 2. Subfolder includes
- **DUP Package** (Dell Update Package)/ Installer .exe
- **Install.xml** with install parameters for later automations


#### Variables of configuration

**Enable or Disable applications for download** Line 50 - 60
![image](https://user-images.githubusercontent.com/99394991/166953021-851704f4-4ac3-4cfc-8294-e5852f361032.png)

**starting download version equal or newer** Line 67 - 77
![image](https://user-images.githubusercontent.com/99394991/166953135-01ba5929-3a78-4398-962d-4952bb4f1ceb.png)

**Temp and Repository Folder** Line 119 - 125
![image](https://user-images.githubusercontent.com/99394991/166953636-0471f339-56c6-4c92-a41b-9b0cc1ae85cf.png)


#### Logging

The scripts is logging to Temp Folder it shows you when the script has started and which applications are download, existing in Repository or to old for download.
The file named download_log_YYYYMMDD.XML

#### Archiving

For troubleshouting the old catalog file DellSDPCatalogPC.xml will be stored in a Archiving folder (in Software Repository Folder) if a new catalog will be downloaded.



