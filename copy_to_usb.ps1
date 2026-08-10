# PowerShell script to copy Expenso APK to a USB-connected Android phone (MTP mode)
$shell = New-Object -ComObject Shell.Application
$thisPC = $shell.NameSpace(17) # 17 is the ShellFolder ID for "This PC"

# Find any portable devices / phones
$phone = $null
foreach ($item in $thisPC.Items()) {
    if ($item.Name -like "*realme*" -or $item.Type -like "*Portable Device*" -or $item.Name -like "*Phone*" -or $item.Name -like "*Android*") {
        $phone = $item
        break
    }
}

if ($phone) {
    Write-Host "Detected connected device: $($phone.Name)" -ForegroundColor Green
    
    # Locate Internal Storage / Internal shared storage
    $storage = $phone.GetFolder.Items() | Where-Object { 
        $_.Name -like "*Internal*" -or 
        $_.Name -like "*shared*" -or 
        $_.Name -like "*storage*" -or 
        $_.Name -like "*Phone*" 
    }
    
    if ($storage) {
        # Find Download / Downloads folder
        $downloads = $storage.GetFolder.Items() | Where-Object { 
            $_.Name -eq "Download" -or 
            $_.Name -eq "Downloads" 
        }
        
        if ($downloads) {
            $apkPath = "c:\Users\jinum\Expenso\app\build\app\outputs\flutter-apk\app-release.apk"
            if (Test-Path $apkPath) {
                Write-Host "Copying APK to $($phone.Name)\Internal storage\Download ..." -ForegroundColor Cyan
                
                # Copy the file using Windows Shell
                $downloads.GetFolder.CopyHere($apkPath, 16) # 16 = Respond "Yes to All" to prompts
                
                Write-Host "Success! The APK has been copied to your phone's Download folder." -ForegroundColor Green
                Write-Host "Now open the Files app on your phone, go to 'Downloads', and tap the APK to install it." -ForegroundColor Yellow
            } else {
                Write-Host "Error: Could not find build APK at $apkPath. Please build the release APK first." -ForegroundColor Red
            }
        } else {
            Write-Host "Error: Could not find the 'Download' folder in internal storage. Please create a folder named 'Download' on your phone." -ForegroundColor Red
        }
    } else {
        Write-Host "Error: Could not access Internal Storage. Make sure your phone's USB mode is set to 'File Transfer' or 'MTP'." -ForegroundColor Red
    }
} else {
    Write-Host "Error: No Android phone detected." -ForegroundColor Red
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "1. Your phone is connected to this PC via USB." -ForegroundColor Yellow
    Write-Host "2. You have changed the phone's USB mode from 'Charging only' to 'File Transfer' / 'MTP'." -ForegroundColor Yellow
}
