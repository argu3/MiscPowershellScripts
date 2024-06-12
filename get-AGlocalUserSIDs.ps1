param(
	[Parameter(Mandatory)]
	$computerNames
)


ForEach($computerName in $computerNames)
{
	$path = "\\" + $computerName + "\c$\Users\"
	$cmdcmd = "dir " + '"' + $path + '"' + "/b"
	$profiles = cmd.exe /c $cmdcmd
	$SIDs = @{}
	foreach($profile in $profiles)
	{
		$SID= get-wmiobject -class Win32_UserAccount  -filter "name=`"$profile`"" | select -ExpandProperty SID
		$SID2 += $SID
		$SIDs[$SID] = $profile
	}
	#registry method:
	<#
	$profiles = HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\
	#write-host "Getting SIDs..."
	foreach($profile in $profiles)
	{
		if($profile.length -gt 86) #otherwise it doesn't have a user SID
		{
			$SID = $profile.substring(76,$profile.length-76)
			$name = reg query "\\$computerName\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$SID" /v ProfileImagePath
			$name = $name[2].substring(50,$name[2].length-50) #assuming that the returned item is always the same except the username
			if($SID.substring($SID.length - 4,4) -eq '.bak'){$SID = $SID.substring(0, $SID.length - 4)}
			$SIDs[$SID]=$name
		}
	}
	#>
}
$output = $SID2
#$output | Format-Table -AutoSize | Out-File -Append ".\output\$me.txt"
$SIDs