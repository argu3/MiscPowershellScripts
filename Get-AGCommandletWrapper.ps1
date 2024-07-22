param(
    [switch]$toFile,
    [switch]$filterParams,
    $filteredParameters = @(),
    $filePath,
    $cmdletNameModifierString = "Custom",
    [Parameter(Mandatory)]    
    $cmdletName
)
$helpInfo = get-help $cmdletName -Detailed
if($helpInfo.count -gt 1)
{
    write-host "Multiple results returned" -BackgroundColor Red
    return
}
#else
$paramNames = $helpInfo.parameters.parameter.name
$script = @("param(")
$script += $paramNames.ForEach({"`t$" + $_ + ","})
$script[$script.Count - 1] = $script[$script.Count - 1].Replace(",","")
$script += ")"
if($filterParams)
{
    $script += "`$filteredParameters = @("
    $script += $filteredParameters.ForEach({"`t'" + $_ + "',"})
    $script[$script.Count - 1] = $script[$script.Count - 1].Replace(",","")
    $script += ")"
    $script += "`$params = @{}
foreach(`$key in `$PSBoundParameters.keys)
{
    if(!`$filteredParameters.Contains(`$key))
    {
        `$params[`$key] = `$PSBoundParameters[`$key]
    }
}
`$output = $cmdletName @params
"
}
else
{
    $script += "`$output= $cmdletName @PSBoundParameters"
}
if($toFile)
{
    $cmdletNameModifierString = "-" + $cmdletNameModifierString
    $fileName = $filePath + $cmdletName.Replace("-",$cmdletNameModifierString) + ".ps1"
    $script | Out-File $fileName
}
else
{
    $script
}
