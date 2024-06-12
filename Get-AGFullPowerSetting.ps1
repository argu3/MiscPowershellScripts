param(
	$registryStart = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings",
    [switch]$help
)

function get-subSettings
{
	param(
	 $directory,
     $settings# = @{}
	)
    if($settings -eq $null){$settings = @{}}
    $directory = $directory.Replace("HKEY_LOCAL_MACHINE","HKLM:")
	cd $directory
	$powerSettings = Get-ChildItem
	$propertyList = @{
            Name=''
			ProvAcSettingIndex= ''
			Description= ''
			ProvDcSettingIndex= ''
			OverrideDCSettingIndex= ''
			OverrideACSettingIndex= ''
			ValueIncrement= ''
			SettingValue= ''
			ValueMax= ''
			Attributes= ''
			FriendlyName= ''
			IconResource= ''
			ValueMin= ''
			DCSettingIndex= ''
			ACSettingIndex= ''
			ValueUnits= ''
			CHILDREN = @{}
		}
	#$properties = new-object psobject -Property $propertyList
	foreach($setting in $powerSettings)
	{
        <#
        #make sure I have all settings
        foreach($p in $setting.property)
        {
            $allSettings[$p] = ""
        }
        #>
        #Write-Host $properties.Name
        $properties = new-object psobject -Property $propertyList
        foreach($property in $propertyList.keys)
        {
            #Write-Host $property
            $error.Clear()
            $e = $null
            try
            {
                $val = $setting.GetValue($property)
                if($val -ne "" -AND $val -ne $null -AND $property -ne "CHILDREN")
                {
                    if($property -eq "FriendlyName" -AND $val.indexof(",") -ne -1)
                    {
                        $tempName = $val.replace(";",",")
                        $tempName = $tempName.Split(",")
                        $properties.$property = $tempName[$tempName.length-1]

                    }
                    elseif($property -eq "Description" -AND $val.indexof(",-") -ne -1)
                    {
                        $tempName = $val.replace(";",",")
                        $tempName = $tempName.substring($tempName.indexof(",-")+1,$tempName.length - ($tempName.indexof(",-")+1))
                        $tempName = $tempName.substring($tempName.indexof(",")+1,$tempName.length - ($tempName.indexof(",")+1))
                        #Write-Host $tempName
                        $properties.$property = $tempName
                    }
                    else
                    {
                        $properties.$property = $val

                    }
                }
            }
            catch
            {
                $e = $error
            }
            finally
            {
                if($e -AND $property -ne "CHILDREN")
                {
                    $properties.$property = "n/a"
                }
            }

        }

        $guid = $setting.PSChildName
        #write-host $guid
        $properties.name = $guid
        $settings[$guid] = $properties
		$new = @{}
        $next = Get-ChildItem $guid
		if($next -ne $null)
		{	
            $nextDirectory = $directory + "\" + $guid
            #$new = $null
            $new = get-subSettings -directory $nextDirectory #-settings $settings
			#$desc[$properties] = $new
            #write-host $guid
			$settings[$guid].Children = $new
            <#
            if($guid -eq "0012ee47-9041-4b5d-9b77-535fba8b1442")
            {
				#used as a breakpoint
                $nothing
            }
            #>
	        cd $directory
		}
		else
		{ 
			$settings[$guid] = $properties
		}
	}
    return $settings
}

function display-settingsOptions
{
    param(
        $settings,
        $loop = $true,
        $changeString = @(),
        $changeDescription = @(),
        $scheme = $powerScheme
    )
    do{
        $navigationProperties = 
        @{
            Index=''
            FriendlyName=''
            Name='' #guid
            Description=''
            ValueMax=''
            ValueMin=''
            ValueIncrement=''
            ACSettingIndex=''
            DCSettingIndex=''
        }
        $navigation = @()
        $i = 0
        foreach($key in $settings.keys)
        {
            $nav = new-object psobject -Property $navigationProperties
            foreach($property in $nav.psobject.Properties.Name)
            {
                $nav.$property = $settings[$key].$property
            }
            $nav.Index = $i
            if($betterNamesDict[$settings[$key].Name] -eq $null)
            {
                $nav.FriendlyName = $settings[$key].FriendlyName + "*"
            }
            else
            {
                $nav.FriendlyName = ($betterNamesDict[$settings[$key].Name].replace(")","")).replace("(","")
            }
            $navigation += $nav
            $i++
        }
        $navigation | Format-Table Index, @{n='Name';e={$_.FriendlyName}}, @{n='Max';e={$_.ValueMax}}, @{n='Min';e={$_.ValueMin}}, @{n='Increment';e={$_.ValueIncrement}}, ACSettingIndex, DCSettingIndex, @{n='GUID';e={$_.Name}}, Description -wrap | Out-Host
        [string]$selection = read-host "Enter a # from 'Index' to explore suboptions. 'b' to go back. 'q' to quit"
        if($selection -eq "b")
        {
            return "b"
        }
        else
        {
            if($settings[$navigation[$selection].Name].CHILDREN.count -eq 0)
            {
                write-host "No more suboptions. Showing properties:"
                $settings[$navigation[$selection].Name] | Format-Table Index, @{n='Name';e={$_.FriendlyName}}, @{n='Max';e={$_.ValueMax}}, @{n='Min';e={$_.ValueMin}}, @{n='Increment';e={$_.ValueIncrement}}, ACSettingIndex, DCSettingIndex, @{n='GUID';e={$_.Name}}, Description | out-host
                 
                $o = read-host "Press 'c' if you would like to continue changing this setting, or 'b' to pick a different option/go back"
                if($o -eq "c")
                {
                    $output = ""
                    Write-Host "This is the setting you are changing"
                    foreach($line in $changeDescription)
                    {
                       $output += $line + "->"
                    }
                    $output += $navigation[$selection].FriendlyName
                    Write-Host $output
                    $o = Read-Host "'c' to confirm or 'b' to go back."
                    if($o -eq "c")
                    {
                        $command = "powercfg.exe /setacvalueindex " + $scheme + " "
                        foreach($line in $changeString)
                        {
                            $command += $line + " "
                        }
                        $lastOption = $navigation[$selection].Name
                        $len = $lastOption.length
                        if($lastOption.length -lt 9)
                        {
                            for($i = 0; $i -lt (9 - $len); $i++)
                            {
                                $lastOption = "0" + $lastOption
                            }
                        }
                        $command += $lastOption
                        write-host $command
                        & $command
                        return "q"
                    }
                }
            }
            else
            {
                $back = display-settingsOptions -settings $settings[$navigation[$selection].Name].CHILDREN -changeString ($changeString += $navigation[$selection].Name) -changeDescription ($changeDescription += $navigation[$selection].FriendlyName) -Scheme $scheme
                if($back -eq "q")
                {
                    $loop = $false
                }
            }
        }
    }while($loop -eq $true)
    return "q"
}
if($help)
{
    write-host "
Recursively numerates all of the power settings from the registry (including ones not found in the GUIs) and allows you to explore them and edit them.
Once the bottom of the tree is reached, an option is given to set the selected option. 
"
break
}
$betterNames = powercfg.exe /query
$betterNamesDict = @{}
foreach($line in $betterNames)
{
    if($line.Contains("GUID:"))
    {
        $l = $line.Substring($line.IndexOf(":")+2,$line.Length-($line.IndexOf(":")+2))
        $guid = ($l.split(" "))[0]
        $betterNamesDict[$guid] = $l.Replace(($guid + "  "),"")
    }
}
$powerSchemes = powercfg.exe /list
foreach($scheme in $powerSchemes)
{
    if($scheme.contains("*"))
    {
        $powerScheme = $scheme.split(" ")
        $powerScheme = $powerScheme[3]
    }
}

set-location -Path HKLM:
cd HKLM:\

#$settings = $null
write-host "Reading options from registry (this will take a minute or 2)" -BackgroundColor Yellow -ForegroundColor Black
$settings = get-subSettings -directory $registryStart
write-host "Finsihed. Press 'enter' to continue." -BackgroundColor Yellow -ForegroundColor Black
$noOutput = Read-Host "  "
display-settingsOptions -settings $settings -scheme $powerScheme
