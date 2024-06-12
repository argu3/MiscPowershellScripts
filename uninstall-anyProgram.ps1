param(
	$prog = "",
	$hostName = $Env:COMPUTERNAME
)
read-host -prompt "This needs to be run as admin. Enter to continue"
do
{
	if($prog -eq "")
	{
		$prog = read-host -prompt "Enter a program"
	}
	write-host "Finding programs. This takes a couple of minutes..."
	#$uninstall = Get-WmiObject -Class Win32_Product -Filter "Name LIKE '%$prog%'"
    $uninstall = Get-WmiObject -Class Win32_Product -computername $hostName -Filter "Name LIKE '%$prog%'"
	write-host "Please confirm that you want to uninstall all (y) or some of (m) the following programs:`n****************************************************************************************"

	foreach($program in $uninstall)
	{
		$name = $program.name
		echo $name
	}
    Write-Host "****************************************************************************************"
	echo "y to uninstall all"
	echo "n to quit"
	echo "m to answer for each program"

	$confirm = Read-Host -Prompt "y/n/m"
	$prog = ""
}while($confirm -eq "n")

if($confirm -eq "y")
{
	foreach($program in $uninstall)
	{
		$program.Uninstall()
	}
}
elseif($confirm -eq "m")
{
	foreach($program in $uninstall)
	{
		$confirm = Read-Host -Prompt "y/n"
		if($confirm -eq "y")
		{
			$program.Uninstall()
		}
	}
}