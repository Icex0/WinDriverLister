#List all drivers
$drivers = Get-WmiObject Win32_SystemDriver
$CheckDriver = @()

    foreach ($d in $drivers) {
 
        Write-Host "Name:" $d.Name
        Write-Host "Description:" $d.Description
        Write-Host "Type:" $d.ServiceType
        Write-Host "Mode:" $d.StartMode

        if ($null -ne $d.PathName) {
            #Remove any char left of path: "<drive letter>:\"
            $ModifiedPath = $d.PathName -replace "\\", "\\" -replace "^.*?(.:\\)", '$1'
            Write-Host "Path: $ModifiedPath"

            #Get SHA256 for Virustotal lookup
            $FileHash = Get-FileHash $ModifiedPath
            $VirusTotal = "https://virustotal.com/gui/file/" + $FileHash.Hash
            Write-Host "Virustotal: $VirusTotal"

            #Get the install date for the driver
            $Query = "select * from CIM_DataFile where Name='$ModifiedPath'"
            $InstallDate = Get-WmiObject -Namespace "ROOT\CIMV2" -Query $Query
            $ReadableDate = $InstallDate.ConvertToDateTime($InstallDate.InstallDate)
            Write-Host "Created: $ReadableDate"    
        }
        else {
            Write-Host "Driver path not found. Driver deleted or moved?" -ForegroundColor Red
            $CheckDriver += "Name: " + $d.Name + "Path: No path found!" + "`n"
        }

        #If driver path starts with \??\ warn and add to drivers of interest array.
        $WarnPath = $d.PathName -Match "^\\\?\?\\"

        if ($WarnPath) {
            Write-Host "Driver of interest:" $d.PathName -ForegroundColor Red
            $CheckDriver += "Name: " + $d.Name + "`nDescription: " + $d.Description + "`nPath: " + $ModifiedPath + "`nVirusTotal: " + $VirusTotal + "`nCreated: " + $ReadableDate + "`n`n"
        }
      
        Write-Host "----------------`n"
    }

Write-Host "Results:`n----------------" -ForegroundColor Yellow
Write-Host $CheckDriver -ForegroundColor Red