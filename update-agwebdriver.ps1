param(
    $executablePath, #path to folder with web drivers
    [switch]$chromeDriver,
    [switch]$edgeDriver,
    [switch]$both,
    [switch]$noRename,
	[switch]$help
)

if($help)
{
	write-host "Used for updating the browser web driver for use with Selenium."
	write-host "*Only tested on 64 bit Windows*"
	write-host "Arguments: "
	write-host '-executablePath "pathToWebDriver(s)"'
	Write-host "	*this defaults to the path of the powershell Selenium module"
	Write-host "-chromeDriver	: check if Chrome driver needs updating"
	Write-host "-edgeDriver		: check if Edge driver needs updating"
	Write-host "-both			: check if Chrome and Edge drivers needs updating"
	write-host "-noRename		: powershell selenium module expects the Edge driver to be named MicrosoftWebDriver, not msedgedriver, so it gets renamed by default"
	write-host "-help			: shows command line arguments"
	break
}
#get OS type
if($env:OS -eq "Windows_NT")
{
    $osType = "win"
}
elseif($env:OS.Contains("Linux"))
{
    $osType = "linux"
}
elseif($env:OS.Contains("mac"))
{
    $osType = "mac"
}
else
{
    Write-Host "unknown host type"
    break
}
#get if 32 or 64 bit
if([Environment]::Is64BitOperatingSystem)
{
    $bits = 64
}
else
{
    $bits = 32
}

$chromeStrings = @{
    process="chromeDriver"
    executable="chromedriver.exe"
    browser="\Program Files (x86)\Google\Chrome\Application\chrome.exe"
}
if($noRename)
{
		$edgeStrings = @{
	process= "msedgedriver"
	executable="msedgedriver.exe"
	browser="\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
	}
}
else
{

$edgeStrings = @{
		process= "MicrosoftWebDriver"
		executable="MicrosoftWebDriver.exe"
		browser="\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
	}
}

$drivers = @()
if($both)
{
    $drivers += $chromeStrings
    $drivers += $edgeStrings
}
elseif($chromeDriver)
{
    $drivers += $chromeStrings
}
elseif($edgeDriver)
{
    $drivers += $edgeStrings
}
else
{
    $selection = read-host "0 to update both`n1 to update Chrome`n2 to update Edge"
    if($selection -eq 0){$drivers += $chromeStrings
    $drivers += $edgeStrings}
    elseif($selection -eq 1){$drivers += $chromeStrings}
    elseif($selection -eq 2){$drivers += $edgeStrings}
}

foreach($driver in $drivers)
{
    #frees exe
    #$read = Read-Host "*ONLY works on Windows x64`n*Only works if you have office installed`n*This script needs to be run as admin.`n*This script will stop all" $driver.process "processes. Enter to proceed"

    if($executablePath -eq $null)
    {
        #default is Selenium module path
        $executableDir = (Get-Module -ListAvailable Selenium).path
        $executableDir = $executableDir.Substring(0,$executableDir.LastIndexOf("\")) + "\assemblies"
        $executablePath = $executableDir + "\" + $driver.executable
    }
    else
    {
        $executableDir = $executablePath.Substring(0,$executablePath.LastIndexOf("\"))
    }

    if((Test-Path $executablePath) -OR (Test-Path $executableDir))
    {
        #webDriver version
        if(Test-Path $executablePath)
        {
            $driverExe = Get-Item $executablePath
            $driverVersion = $driverExe.VersionInfo.ProductVersion
            if($driverVersion -ne $null)
            {
                $driverVersionImportant = $driverVersion.Substring(0, $driverVersion.LastIndexOf("."))
            }
        }
        #edge version
        $browserPath = $env:HOMEDRIVE + $driver.browser
        $browser = Get-Item $browserPath
        $browserVersion = $browser.VersionInfo.ProductVersion
        $browserVersionImportant = $browserVersion.Substring(0, $browserVersion.LastIndexOf("."))

        $update = $true
        if($driverVersionImportant -eq $browserVersionImportant -AND (Test-Path $executablePath))
        {
            #$read = read-host "No need to update. The driver version is $driverVersionImportant and the browser version is $browserVersionImportant. Press e to update anyway."
            #$update = $false
        }
        if($read -eq "e" -OR $update -eq $true)
        {
            $read = Read-Host "*This script needs to be run as admin.`n*This script will stop all" $driver.process "processes. Enter to proceed"
            try
            {
                $webDriverProcess = Get-Process -name $driver.process -ErrorAction Stop
                $webDriverProcess | Stop-Process -Force
            }
            catch
            {
                $errorr = $Error
            }
            $error.Clear()
            if($driver.process -eq "MicrosoftWebDriver")
            {
                #find correct link
                $page = Invoke-WebRequest -UseBasicParsing -uri "https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/"
                foreach($link in $page.links)
                {
                    if($link.href -ne $null)
                    {
                        if($link.href.contains($browserVersionImportant) -AND $link.href.contains("win64"))
                        {
                            $newDriver = $link.href
                            break
                        }
                    }
                }
            }
            elseif($driver.process -eq "chromeDriver")
            {
                $chromeUpdate = Invoke-WebRequest -Uri "https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json" -UseBasicParsing
                $chromeUpdateJson = $chromeUpdate.content | ConvertFrom-Json
                $break = $false
                foreach($update in $chromeUpdateJson.versions)
                {
                    if($update.version.contains($browserVersionImportant))
                    {
                        foreach($option in $update.downloads.chromedriver)
                        {
                            if($option.platform.contains($osType) -AND $option.platform.contains($bits))
                            {
                               $newDriver = $option.url
                               $break = $true
                               break
                            }
                            if($break){break}
                        }
                    }
                    if($break){break}
                }
            }
            cd $executableDir
            New-Item -Path .\tempDirForRenaming -ItemType Directory
            #download and unpack
            for($i = 0; $i -lt 5; $i++)
            {
                Invoke-WebRequest $newDriver -OutFile ($executableDir + ".\tempDirForRenaming\driver.zip") -UseBasicParsing
                if(Test-Path ".\tempDirForRenaming\driver.zip"){break}
            }
            Expand-Archive -Path .\tempDirForRenaming\driver.zip -DestinationPath .\tempDirForRenaming
            if(!$noRename -AND $driver.Process -eq "MicrosoftWebDriver")
            {
                #powershell selenium module is looking for the name "MicrosoftWebDriver.exe"
                Rename-item -path ".\tempDirForRenaming\msedgedriver.exe" -newName "MicrosoftWebDriver.exe"
            }
            cd ".\tempDirForRenaming"
            $newDriver = (Get-ChildItem -Filter $driver.executable -Recurse).FullName
            cd..
            Copy-Item $newDriver -Destination ".\" -Force
            Remove-Item tempDirForRenaming -Recurse
            if($error.Count -ne 0)
            {
                Read-Host "There were errors: `n" $error
            }
            else
            {
                write-host "Completed succesfully"
            }
        }
    }
    else
    {
        Read-Host "Path to webdriver not found. Rerun with the -executablePath argument and the path to the webdriver."
    }
}
