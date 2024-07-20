param(
    #Get-Winevent parameters
    $ComputerName,
    $Credential,
    $FilterHashtable,
    $FilterXml,
    $FilterXPath,
    $Force,
    $ListLog,
    $ListProvider,
    $LogName,
    $MaxEvents,
    $Oldest,
    $Path,
    $ProviderName,

    #Other parameter
    [switch]$asPair
    <#
    if enabled:
        returns a list of hash tables where the Event = the event object as Get-WinEvent returns it and the EventData = the event data
    if disabled:
        returns a pscustomobject with all of the event properties as well as an "EventData" property with the EventData
    #>
    #EventData is a hashtable where the key is the name and the value is the text value
)

#check for valid parameters
$filteredParameters = @(
	'asPair'
)
$params = @{}
foreach($key in $PSBoundParameters.keys)
{
    if(!$filteredParameters.Contains($key))
    {
        $params[$key] = $PSBoundParameters[$key]
    }
}
$eventList = Get-WinEvent @params

#process EventData
$newEventList = @()
foreach($e in $eventList)
{
    if($asPair)
    {
        $pair = @{
            EventData = ''
            Event = ''
        }
        $eventData = @{}
        ([xml]$e.ToXml()).Event.EventData.Data.ForEach{$eventData[$_.Name] = $_.'#text'}
        $pair.EventData = New-Object pscustomobject -Property $eventData
        $pair.Event = $e
        $newEventList += $pair
        }
    else
    {
        #event properties to custom object
        $extendedProperties = @{}
        $e.psobject.Properties.Foreach{$extendedProperties[$_.Name] = $_.Value}
        #event data properties to custom object
        $eventData = @{}
        ([xml]$e.ToXml()).Event.EventData.Data.ForEach{$eventData[$_.Name] = $_.'#text'}
        $extendedProperties.EventData = New-Object pscustomobject -Property $eventData

        $newEvent = New-Object pscustomobject -Property $extendedProperties
        $newEventList += $newEvent
    }
}
return $newEventList
