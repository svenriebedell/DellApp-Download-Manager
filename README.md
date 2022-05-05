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
- Dell Trusted Device (no yet in place)
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
- DUP Package (Dell Update Package)/ Installer .exe
- Install.xml with install parameters for later automations



