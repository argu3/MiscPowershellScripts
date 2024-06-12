param (
	$pathsFile,
	$path,
	[switch]$help
)

function get-AGEarliestDate
{
	param(
		$dir
	)
	$items = Get-ChildItem $dir -recurse
	forEach($item in $items)
	{
		if($newest -lt $item.LastWriteTime){$newest = $item.LastWriteTime}
	}
	$newest
}

if($help)
{
	write-host "Manually updates the folder's modified date to the most recent date any file within the folder was updated"
	write-host "parameters:"
	write-host "`$pathsFile: takes the path for a text file with a list of paths"
	write-host "`$path: takes a path whos folder you want updated. mutually exclusive with '$pathsFile"
	break
}

if($pathsFile)
{
	$path = Get-Content $pathsFile
	forEach($p in $path)
	{
		Get-ChildItem
	}
}
elseif($path)
{
	#for all files and subdirectories
	$dir = Get-ChildItem $path -Directory -recurse
	for($i = $dir.length-1; $i -ge 0; $i--)
	{
		write-host $dir[$i].FullName
		$newest = get-AGEarliestDate -dir $dir[$i]
		if($newest -ne $null)
		{
			Set-ItemProperty -path [string]($dir[$i].FullName) -Name LastWriteTime -Value $newest
		}
		$newest = $null
	}
	
	#for the actual specified directory
	$newest = get-AGEarliestDate -dir $path
	if($newest -ne $null)
	{
		Set-ItemProperty -path $path -Name LastWriteTime -Value $newest
	}
}