# DellApp-Download-Manager 

### Changelog:
- 1.0.3  First public version
- 1.1.0 Supporting now Trusted Device Agent and new Dell Display Manager for download by dell.com/support
- 1.1.1   Correction Function function Download-Dell unplaned delete of folders if delete older folders is enabled.

## Description 

This tool is for downloading **Dell Tools** and generating a Software Repository which could be later used for software packaging or other installation processes. I have written this script to maintaining my Testlab´s for VMware Workspace One and Microsoft Endpoint Manager. My further ideas is to using API´s of Workspace One and Microsoft Endpoint Manager to upload these Applications directly to theses console´s. 


![DCE211D3-C1E2-4604-8900-46D2BC2692EE](https://user-images.githubusercontent.com/99394991/196415769-6c3bb70b-1612-478b-8147-69affc89d59d.GIF)


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
- Dell Trusted Device
- Dell Display Manager (V1_0_3 supporting Display Manager V1.x / V1_1_1 supporting Display Manager V2.x)


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

#### **Enable or Disable applications for download** Line 53 - 70

![image](https://user-images.githubusercontent.com/99394991/196470153-7456e23e-93eb-4f15-9791-4c9c83bfc52e.png)

 
#### **starting download version equal or newer** Line 90 - 100 

![image](https://user-images.githubusercontent.com/99394991/196470464-7e2ece5a-f113-4c28-a8f9-7f897fa0c7ec.png)


#### **Delete old downloaded Folders** Line 79

![image](https://user-images.githubusercontent.com/99394991/196470405-fdb2eeae-552b-4450-9688-b2f502ec1228.png)


**Note** works only if Application is NOT .PublicationsState "Expired" in the catalog

![image](https://user-images.githubusercontent.com/99394991/167109524-ef6b66a3-1da3-4619-91d6-0082f8320e81.png)
 
#### **Temp and Repository Folder** Line 155 - 157 

![image](https://user-images.githubusercontent.com/99394991/196470768-ad04e6cf-58f9-4f91-addf-94c9a7fa1ae1.png)

#### **Website for Download Trusted Device and Display Manager 2.x** line 148 - 150

![image](https://user-images.githubusercontent.com/99394991/196471174-89a22c75-5519-479e-936a-cb27f6c005aa.png)


 
### Logging 

The script is logging to Temp Folder. The logging file will show the following informations:

- Start Time
- Catalog download (false or true)
- Environment (Path (exist/create, Filename)
- Applications available (download, exist, outdate/no download, outdate/exist, deleted)

![image](https://user-images.githubusercontent.com/99394991/167110860-3c732b22-60f0-4158-ab59-dfe159277de2.png)


The file named **download_log_YYYYMMDD.XML**

![image](https://user-images.githubusercontent.com/99394991/167092062-b2ebe782-7cce-4288-b41e-bc49f3bef51b.png)


### Archiving 
For troubleshooting the old catalog file DellSDPCatalogPC.xml will be stored in a Archiving folder (in Software Repository Folder) if a new catalog is downloaded.

The file named **YYYYMMDDDellSdpCatalogPC.XML**
![image](https://user-images.githubusercontent.com/99394991/167093085-77973550-3313-49ff-8c0b-ad91f488ff78.png)

If you find issues please let me know. Thx :-)
