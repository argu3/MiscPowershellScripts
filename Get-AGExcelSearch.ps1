param(
    $caseInsensitive = $true,
    $searchDir,
    $searchItemsPath,
	[switch]$noOutput, #no print statements
	[switch]$lowOutput, #only when a string is found,
	[switch]$recursiveSearch,
	[switch]$help
)
if($help)
{
    write-host "Used to find a string within an excel file. Doesn't need office"
	write-host "Options:"
	write-host "-caseInsensitive $true/$false 	: changes strings to all lowercase prior to search. $true by default"
	write-host "-searchDir $path 				: Directory to get excel workbooks from"
	write-host "-recursiveSearch 				: searches all subdirectories as well"
    write-host "-searchItemsPath $path 			: Path to a file with a list of search strings"
	write-host "-noOutput 						: stops all print statements"
	write-host "-lowOutput 						: only prints to host when a string is found"
	write-host "-help 							: shows this screen"
	break
}
if(!$searchDir)
{
    $searchDir = ($MyInvocation.mycommand.path.replace($MyInvocation.MyCommand,""))
}

if(Test-path $searchDir)
{
    cd $searchDir 
}
else
{
    write-host "Search path doesn't exist"
    break
}
if(!$searchItemsPath)
{
    $searchItemsPath = ".\searchItems.txt"
}

$searchItems = Get-Content $searchItemsPath

if($recursiveSearch)
{
	$excelWorkbooks = Get-ChildItem -Filter "*.xlsx" -recurse
}
else
{
	$excelWorkbooks = Get-ChildItem -Filter "*.xlsx"
}

$results = @{}
foreach($workbook in $excelWorkbooks)
{
    $results[$workbook.name] += @()
    #get contents of excel doc
    $noprint = [Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
    $entries = [IO.Compression.ZipFile]::OpenRead($workbook.FullName).Entries
    $files = @()
    foreach($entry in $entries)
    {
        if(!$noOutput -AND !$lowOutput){Write-Host "Extracting " $entry.Name " from " $workbook.name}
        #unzip in memory and read the contents
        $opened = $entry.Open()
        $length = $entry.Length
        $array = [System.Array]::CreateInstance("byte",$length)
        $noprint = $opened.Read($array,0,$length)
        #stitch together byte array into searchable string
        $fileText = ""
        foreach($letter in $array)
        {
            $fileText += [char]$letter
        }
        if($caseInsensitive)
        {
            $fileText = $fileText.toLower()
        }
        $files+= $fileText
    }
    #search 
    $fileNum = 0
    $fileTotal = $files.Count
    foreach($file in $files)
    {
        $fileNum++
        if(!$noOutput -AND !$lowOutput){write-host "Searching $fileNum of $fileTotal in $workbook"}
        foreach($item in $searchItems)
        {
			if($caseInsensitive)
			{
				$item = $item.Tolower()
			}
            if($file.Contains($item))
            {
                if(!$noOutput){write-host "Found $item"}
                $results[$workbook.name] += $item
            }
        }
    }
}
$results