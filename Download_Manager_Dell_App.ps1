#Select Software for download activate or deactived
$Command_Monitor = "Enabled"
$Command_Monitor_Name = "Dell Command | Monitor"
$Command_Monitor_Version = "10.2.1.80"
$Command_Configure = "Enabled"
$Command_Configure_Name = "Dell Command | Configure"
$Command_Configure_Version = "4.2.0.553"
$Command_Update_Legacy = "Enabled"
$Command_Update_UWP = "Enabled"
$Digital_Delivery = "Enabled"
$Optimizer = "Enabled"
$Power_Manager = "Enabled"
$PremierColor = "Enabled"
$RuggedControl_Center = "Enabled"
$Trusted_Device = "Enabled"
$Display_Manager = "Enabled"

#Environment variables

# Source URL for Dell Update Catalog for SCCM
$url = "https://dl.dell.com/catalog/DellSDPCatalogPC.cab"

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
        [string]$Software_Version
        
         )

    $Dell_App_Select = $Catalog_DATA.SystemsManagementCatalog.SoftwareDistributionPackage | Where-Object{$_.LocalizedProperties.Title -like "$Software_Name"}
    $Dell_App_Download = $Dell_App_Select | Where-Object {$_.Properties.PublicationState -ne "Expired"}
    
    
    foreach ($i in $Dell_App_Download)
        {

        
        Start-BitsTransfer -Source $Dell_App_Download.InstallableItem.OriginFile.OriginUri[5] -Destination $dest

        }

    


    Return $ScoreValue
     
    }




# Download the catalog File
Start-BitsTransfer -Source $url -Destination $dest

# Change directory
CD $dest

# Extract DellSDPCatalogPC.xml from CAB-File
expand "DellSDPCatalogPC.cab" . -f:DellSDPCatalogPC.xml

# Transfer XML data to VAR
[XML]$Catalog_DATA = Get-Content C:\Users\sven_riebe\Downloads\DellSDPCatalogPC.xml

If ($Command_Configure -eq "Enabled")
    {

    Download-Dell -Software_Name "Dell Command | Configure" -Software_Version "4.2.0.553"

    }
Else
    {

    Write-Output "no Dell Command | Configure selected"
    
    }     