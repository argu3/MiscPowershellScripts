param(
    $cmdletName,
    [switch]$toFile,
    [switch]$filterNullParams,
    $cmdletNameModifierString = "Custom"
)
$helpInfo = get-help $cmdletName -Detailed
if($helpInfo.count -gt 1)
{
    write-host "Multiple results returned" -BackgroundColor Red
    break
}
#else
$paramNames = $helpInfo.parameters.parameter.name
$paramBlock = @("param(")
$paramBlock += $paramNames.ForEach({"`t$" + $_ + ","})
$paramBlock[$paramBlock.Count - 1] = $paramBlock[$paramBlock.Count - 1].Replace(",","")
$paramBlock += ")"
if($filterNullParams)
{
    $paramBlock += "`$params = @{}
foreach(`$key in `$PSBoundParameters.keys)
{
    if(`$PSBoundParameters[`$key] -ne `$null)
    {
        `$params[`$key] = `$PSBoundParameters[`$key]
    }
}
if(`$params.count -eq 0)
{
    `$output = $cmdletName @params
}
else
{
    `$output = $cmdletName
}
"
}
else
{
    $paramBlock += "`$output=@PSBoundParameters"
}
if($toFile)
{
    $cmdletNameModifierString = "-" + $cmdletNameModifierString
    $fileName = $cmdletName.Replace("-",$cmdletNameModifierString) + ".ps1"
    $paramBlock | Out-File $fileName
}
else
{
    $paramBlock
}