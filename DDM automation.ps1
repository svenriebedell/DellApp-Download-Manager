function download-delltool
    {
    
    param
        (
        
        [string]$Webpage,
        [string]$FileName     
        
        )
    
    ### Start InternetExplore for download Webpage informations
    $IEAuto = New-Object -ComObject InternetExplorer.Application
    $IEAuto.Visible = $true
    $IEAuto.Navigate($Webpage)

    while($IEAuto.Busy -eq $true)
        {

        Start-Sleep -Seconds 10

        }

    ### select Download-Path inforamtion
    $downloadTemp = $ieauto.Document.IHTMLDocument3_getElementsByTagName('a') | select href -Unique | Select-String $FileName | Select-String "dl.dell.com"
    
    ### Cuting data to Download-Path
    $downloadTemp = $downloadTemp.ToString()
    $downloadTemp = $downloadTemp.TrimEnd('}')
    $downloadTemp = $downloadTemp.Split("=")
    $downloadPath = $downloadTemp[1]


    ### download file
    start-BitsTransfer -Source $downloadPath -Destination 'C:\Temp' -DisplayName $FileName

    $IEAuto.Quit()
    
    }


### DDM
download-delltool -Webpage "https://www.dell.com/support/home/de-de/product-support/product/dell-display-peripheral-manager/drivers" -FileName "ddmsetup.exe"

### DTD
download-delltool -Webpage "https://www.dell.com/support/home/de-de/product-support/product/trusted-device/drivers" -FileName "Trusted-Device"



#findet datei namen
$ieauto.Document.IHTMLDocument3_getElementsByTagName('a') | select nameprop -Unique | Select-String "Trusted-Device"
