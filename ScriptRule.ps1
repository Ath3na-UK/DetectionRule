#Software test-list arrays
[string[]]$SoftwareNameTestList = @(
    "Google Chrome"
)
[string[]]$SoftwareVersionTestList = @(
    "124.0.6367.61"
)

##### DO NOT EDIT BELOW ####
$ErrorActionPreference = 'SilentlyContinue'
$Script:DetectionSuccessful = $Null
$Script:SoftwareVersionTable = $Null

#All possible registry paths containing un-install info
[string[]]$RegistryUninstallPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)

#If test-list array element counts don't match, fail
if (($SoftwareNameTestList.Count) -eq ($SoftwareVersionTestList.Count)) {

    #With each registry path build a table of installed software
    foreach ($RegistryPath in $RegistryUninstallPaths) {
        $RegistryFolders = (Get-ChildItem $RegistryPath -Name)
        $SoftwareVersionTable += $(foreach ($Folder in $RegistryFolders) { (Get-ItemProperty -Path "$RegistryPath\$Folder") | Select-Object DisplayName, DisplayVersion })
    }

    #Step through each test-list element reformat version data
    for ($G = 0; $G -lt ($SoftwareNameTestList.Count); $G++) {
        $SoftwareNameTestItem = $SoftwareNameTestList[$G]
        $SoftwareVersionTestItem = $SoftwareVersionTestList[$G]
        $SoftwareVersionTestItem = [System.Version]$SoftwareVersionTestItem
        $SoftwareNameTestItemExists = $False

        #Step through each software installed element reformat version data
        foreach ($Record in $SoftwareVersionTable) {
            $SoftwareNameInstalled = ($Record.DisplayName)
            $SoftwareVersionInstalled = ($Record.DisplayVersion)
            $SoftwareVersionInstalled = [System.Version]$SoftwareVersionInstalled

            #Compare test-list software name and version number against installed software
            #Installed software version must be >= the test-list version, this prevents detection method failure if the installed software is newer than that being installed.
            #At first failure break out of loop, detection has failed
            if ($SoftwareNameInstalled -eq $SoftwareNameTestItem) {
                $SoftwareNameTestItemExists = $True
                if (($SoftwareVersionInstalled -ge $SoftwareVersionTestItem) -and (!($DetectionSuccessful -eq $False))) {
                    $DetectionSuccessful = $True
                }
                else {
                    $DetectionSuccessful = $False
                }
                break
            }
        }

        if ($SoftwareNameTestItemExists -eq $False) {
            $DetectionSuccessful = $False
            break
        }
    }
}
else {
    $DetectionSuccessful = $False
}

if ($DetectionSuccessful) {
    Write-Output "Installed"
}
exit 0
