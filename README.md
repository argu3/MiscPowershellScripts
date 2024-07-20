# MiscPowershellScripts
Miscellaneous useful PowerShell scripts.
update-agwebdriver.ps1: Updates the Chrome and Edge webdrivers for use with Selenium.

get-aghardwareCompare.ps1: Compares the hardware on two computers. Requires PSSQlite module.

Get-AGExcelSearch.ps1: Finds a string within an excel file. Doesn't need office"

Get-AGFullPowerSetting.ps1: Enumerates all power settings found in the registry and allows you to navigate through them and make changes. 

uninstall-anyProgram.ps1: Finds all installed programs and gives an option for them to be uninstalled. Useful for when a program has multiple packages that need to be uninstalled separately, such as MModal Fluency).

get-AGlocalUserSIDs.ps1: Gets the SID of all users of a computer based on users folder

change-AGFolderDateModified.ps1: updates the "date modified" of a folder to reflect the latest update date of the files within

Get-AGWinEvent.ps1: a wrapper for Get-WinEvent which gives the EventData (as viewed in the Event Viewer) in a convenient format

Get-AGCommandletWrapper.ps1: generates a file which accepts the same parameters as a commandlet and returns the output of that commandlet. Basically a template for making a standardized modification of either param inputs or outputs
