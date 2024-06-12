param(
    $computerNameA,
	$computerNameB,
	$dbPath = ".\Drivers.sqlite", 
	$tablename = "Drivers", 
	$primaryKey = "DeviceID",
	[switch]$help
)
if($help)
{
	write-host
	"compares 2 computers' hardware. requires the module PSSQLite to function.
	This gets all of the information returned from 'Get-WmiObject Win32_PnPSignedDriver' and puts it in the SQLite database, and gets the comparison via a SQLite query.
arguments:
	-computerNameA: first computer for comparison
	-computerNameB: second computer for comparison
If nothing is specified for these 3, they use the default values. If the SQLite file doesn't exist with the specified table name, it's created
	-dbPath '.\drivers.sqlite'
	-tablename 'Drivers'
	-primaryKey 'DeviceID'
	"
	break
}

function get-AGHashFromObject
{
    param($object)
    $hash = @()
    foreach($key in $object.Keys)
    {  
        $props = @{}
        foreach($name in $results[$key].psobject.Properties.name)
        {
            $props[$name] = $results[$key].$name
        }
        $line = new-object psobject -Property $props
        $hash += $line
    }
    return $hash
}

function Get-AGMissingDevices
{
    param($driversA, $driversB, $key)
    $missingDeviceA = @()
    foreach($driverA in $driversA)
    {
        $deviceID = $driverA.$key
        #write-host $deviceID
        $broke = $false
        foreach($driverB in $driversB)
        {
            if($driverB.$key -eq $deviceID)
            {
                $broke = $true
                if($driverB.DriverVersion -ne $driverA.DriverVersion)
                {
                    write-host $driverB.pscomputername " " $driverA.pscomputername
                    write-host $driverB.deviceID
                    Write-Host $driverA.Description
                    write-host $driverB.DriverVersion " " $driverA.DriverVersion
                    Write-Host ""
                    $differentVersion += $driverB.deviceID
                }
                break
            }
        }
        if(!$broke)
        {
            $missingDeviceA += $driverA
        }
    }
    return $missingDeviceA
}

function create-AGInsertStatement
{
    param(
	    $sql,
	    $sqlPSVAR,
	    $dbName
    )
        $insertSQL = "INSERT INTO $dbName ("
        foreach($col in $sql)
        {
	        $insertSQL += $col + ", "
        }
        $insertSQL = $insertSQL.remove($insertSQL.length-2,2)
        $insertSQL += ") VALUES ("
        foreach($var in $sqlPSVAR)
        {
	        if($var.contains("NULL"))#-OR $var -eq "TRUE" -OR $var -EQ "FALSE") #interpreter can't handle negatives as string like it can positives
	        {
		        $insertSQL += $var + ", "
	        }
	        else
	        {
		        $insertSQL += "'" + $var + "', "
	        }
        }
    $insertSQL = $insertSQL.remove($insertSQL.length-2,2)
    $insertSQL += ")"
    #write-host $insertSQL
    return $insertSQL
}

function get-AGColumnsAndValues
{
    param($object)
    $i++
    $Error.clear()
    foreach($item in $object)
	{
        if($item.$primaryKey -ne "") #if primary key isnt blank
        {
		    $sql = @() #sql column name
		    $sqlPSVAR = @() #powershell data being plugged into it
		    foreach($v in $item.psobject.Properties)
		    {
				$sql += $v.Name
                $val = $item.($v.Name)
                if($val -ne $null)
                {
                    $type = $item.($v.Name).gettype().name
                    $newVal = ""
                    write-host $type
                    if($type -ne "String")
                    {
                        if($type.contains("[]"))
                        {
                            foreach($itm in $item.($v.Name))
                            {
                                $newVal += [string]$itm + "|"
                            }
                        }
                        else
                        {
                            $val = $item.($v.Name)
                            $newVal = [string]$val
                        }
                    }
                    else
                    {
                        $newVal = $newVal = $item.($v.Name)
                    }
				    $value = $value.replace("'", "''")
                }
                else
                {
                    $val = ""
                }
				$sqlPSVAR += $value
		    }
            $Error.clear()
		    $insertSQL = create-AGInsertStatement -sql $sql -sqlPSVAR $sqlPSVAR -dbName $tablename
		    Invoke-SqliteQuery -Database $dbPath -Query $insertSQL
            if($Error.Count -eq 0)
            {
                write-Host "Row $i"
            }
            else
            {
                Write-Host ""
            }
        }
    }
}
Import-Module SQLQueryConstructor -Force
if(!(Get-AGSqliteTableConnection -databasePath $dbPath -tableName $databaseTable))
{
	$noOut = Invoke-SqliteQuery -DataSource $dbPath -Query "CREATE TABLE Drivers (PSComputerName TEXT,__GENUS TEXT,__CLASS TEXT,__SUPERCLASS TEXT,__DYNASTY TEXT,__RELPATH TEXT,__PROPERTY_COUNT TEXT,__DERIVATION TEXT,__SERVER TEXT,__NAMESPACE TEXT,__PATH TEXT,Caption TEXT,ClassGuid TEXT,CompatID TEXT,CreationClassName TEXT,Description TEXT,DeviceClass TEXT,DeviceID TEXT,DeviceName TEXT,DevLoader TEXT,DriverDate TEXT,DriverName TEXT,DriverProviderName TEXT,DriverVersion TEXT,FriendlyName TEXT,HardWareID TEXT,InfName TEXT,InstallDate TEXT,IsSigned TEXT,Location TEXT,Manufacturer TEXT,Name TEXT,PDO TEXT,Signer TEXT,Started TEXT,StartMode TEXT,Status TEXT,SystemCreationClassName TEXT,SystemName TEXT,Scope TEXT,Path TEXT,Options TEXT,ClassPath TEXT,Properties TEXT,SystemProperties TEXT,Qualifiers TEXT,Site TEXT,Container TEXT, PRIMARY KEY(DeviceID, PSComputerName))"
}
$drivers = Get-WmiObject Win32_PnPSignedDriver -ComputerName $computerNameA
$noOut = get-AGColumnsAndValues -object $drivers
$drivers = Get-WmiObject Win32_PnPSignedDriver -ComputerName $computerNameB
$noOut = get-AGColumnsAndValues -object $drivers

Invoke-SqliteQuery -DataSource $dbPath -Query ("WITH DA AS (SELECT PSComputername, DeviceID FROM Drivers WHERE PSComputername='{0}'),
DB AS (SELECT PSComputername, DeviceID FROM Drivers WHERE PSComputername='{1}')
SELECT DA.PSComputername, DA.DeviceID, DB.PSComputerName, DB.DeviceID FROM DB LEFT JOIN DA ON DA.DeviceID = DB.DeviceID WHERE (DA.PSComputername='{0}' OR DA.PSComputerName IS NULL OR DA.PSComputerName = '') AND (DB.PSComputername='{1}' OR DB.PSComputerName IS NULL OR DB.PSComputerName = '') 
UNION 
SELECT DA.PSComputername, DA.DeviceID, DB.PSComputerName, DB.DeviceID FROM DA LEFT JOIN DB ON DA.DeviceID = DB.DeviceID WHERE DB.DeviceID IS NULL OR DB.DeviceID = ''" -f $computerNameA, $computerNameB) | Out-GridView

#original below this line
############################
<#
$differentVersion = @()
#$driversAHash = get-AGHashFromObject -object $driversA
#$driversAHash = get-AGHashFromObject -object $driversB

#compare by device ID A->B
$missingDeviceAID = Get-AGMissingDevices -driversA $driversA -driversB $driversB -key "DeviceID"
$missingDeviceBID = Get-AGMissingDevices -driversA $driversB -driversB $driversA -key "DeviceID"
$missingDeviceADescription = Get-AGMissingDevices -driversA $driversA -driversB $driversB -key "Description"
$missingDeviceBDescription = Get-AGMissingDevices -driversA $driversB -driversB $driversA -key "Description"
#compare versions
Read-Host "done"
Read-Host "done"

$missingDeviceAID
$missingDeviceBID
$missingDeviceADescription
$missingDeviceBDescription
$differentVersion
#>