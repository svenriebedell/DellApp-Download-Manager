# DellApp-Download-Manager 

## Description 

This tool is for downloading **Dell Tools** and generating a Software Repository which could be later used for software packaging or other installation processes. I have written this script to maintaining my Testlab´s for VMware Workspace One and Microsoft Endpoint Manager. My further ideas is to using API´s of Workspace One and Microsoft Endpoint Manager to upload these Applications directly to theses console´s. 

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
- Dell Trusted Device (not in place yet) 
- Dell Display Manager 


**Legal disclaimer: THE INFORMATION IN THIS PUBLICATION IS PROVIDED 'AS-IS.' DELL MAKES NO REPRESENTATIONS OR WARRANTIES OF ANY KIND WITH RESPECT TO THE INFORMATION IN THIS PUBLICATION, AND SPECIFICALLY DISCLAIMS IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.** In no event shall Dell Technologies, its affiliates or suppliers, be liable for any damages whatsoever arising from or related to the information contained herein or actions that you decide to take based thereon, including any direct, indirect, incidental, consequential, loss of business profits or special damages, even if Dell Technologies, its affiliates or suppliers have been advised of the possibility of such damages. 

This script will be used for testing modifications that could have impact of running without issues. 

## Details 

#### This script uses the following data points to get the relevant download links 

- Dell SCCM (System Center Configuration Mgr) Update Catalog (DellSDPCatalogPC.cab) 
- Dell Display Manager Website (delldisplaymanager.com) 

**Please refer to https://www.dell.com/support/kbdoc/en-us/000197092/dell-drivers-and-downloads-update-release-schedule?lang=en for more details about update cadence of the catalog used.**

## Instructions 

### Application selection options: 

- Select download by App 
- Oldest Version for download (if you want to download older versions as well) 
- Automatic deletion of older Apps (if app version is older than wanted) 

### Output 
This script generates and maintains a Software Repository. The folder structure is: 

- Main folder (Repository Path) 
- 1st Subfolder (Application Name) 
- 2nd Subfolder (Application Version) 

![image](https://user-images.githubusercontent.com/99394991/167096958-5ab43d4a-35ff-4fc5-84b9-aa0cb47f02ea.png)

Each 2nd Subfolder includes 

![image](https://user-images.githubusercontent.com/99394991/167092419-74566301-127b-459a-806a-555d69357734.png)

- **DUP Package** (Dell Update Package), Installer .exe or MSI 
- **Install.xml** with install parameters for later automations 

![image](https://user-images.githubusercontent.com/99394991/167092334-32ec0c83-8b2e-47e6-a848-dfea7854f1b1.png)


### Variables of configuration 

#### **Enable or Disable applications for download** Line 51 - 61

![image](https://user-images.githubusercontent.com/99394991/167098249-7e5005f4-8668-403d-a714-ac3eaeefc5af.png)

 
#### **starting download version equal or newer** Line 70 - 80 

![image](https://user-images.githubusercontent.com/99394991/167102379-c06b727f-660a-49d0-ba1a-6b2788b18fec.png)

#### **Delete old downloaded Folders** Line 64

![image](https://user-images.githubusercontent.com/99394991/167101838-38a4e8f9-8289-46ad-9eab-1210f8fda383.png)

**Note** works only if Application is NOT .PublicationsState "Expired" in the catalog

![image](https://user-images.githubusercontent.com/99394991/167109524-ef6b66a3-1da3-4619-91d6-0082f8320e81.png)
 
#### **Temp and Repository Folder** Line 122 - 128 

![image](https://user-images.githubusercontent.com/99394991/167102887-c14eaf50-bb64-438e-a25f-be40af893283.png)
 

 
### Logging 

The script is logging to Temp Folder. The logging file will show the following informations:

- Start Time
- Catalog download (yes or no)
- Environment (Path (exist/create, Filename)
- Applications available (download, exist, outdate/no download, outdate/exist, deleted)

![image](https://user-images.githubusercontent.com/99394991/167110860-3c732b22-60f0-4158-ab59-dfe159277de2.png)


The file named **download_log_YYYYMMDD.XML**

![image](https://user-images.githubusercontent.com/99394991/167092062-b2ebe782-7cce-4288-b41e-bc49f3bef51b.png)


### Archiving 
For troubleshooting the old catalog file DellSDPCatalogPC.xml will be stored in a Archiving folder (in Software Repository Folder) if a new catalog is downloaded.

The file named **YYYYMMDDDellSdpCatalogPC.XML**
![image](https://user-images.githubusercontent.com/99394991/167093085-77973550-3313-49ff-8c0b-ad91f488ff78.png)
