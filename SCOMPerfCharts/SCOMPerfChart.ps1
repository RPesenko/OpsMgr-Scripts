<#  SCOM Perf Chart - draft 1
   Queries SCOM Operational DB for raw perf data on % Memory used
   Creates one chart per agent in MG
   Uses .Net Chart controls to format chart
   Output saved as .PNG file
#>

[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
$SQLServer = "SQL1"  
$SQLDBName = "OperationsManager"  
$scriptpath = "C:\SCOMFiles\Charting"  

$SqlQuery = @"  
select Path,
 TimeSampled as DateTime,
 ObjectName,
 CounterName,
 InstanceName,
 SampleValue,
 100.00 as ComparisonValue 
from PerformanceDataAllView pdv with (NOLOCK) 
inner join PerformanceCounterView pcv on pdv.performancesourceinternalid = pcv.performancesourceinternalid 
inner join BaseManagedEntity bme on pcv.ManagedEntityId = bme.BaseManagedEntityId 
where ObjectName = 'Memory' and CounterName = 'PercentMemoryUsed'
 AND DATEDIFF(HOUR, pdv.TimeAdded, GETDATE()) < 8
order by timesampled ASC
"@ 
   
  
# Create connection to SCOMDW Database   
$connString = "Data Source=$SQLServer;Initial Catalog=$SQLDBName;Integrated Security = True"  
$connection = New-Object System.Data.SqlClient.SqlConnection($connString)  
$connection.Open()  
$sqlcmd = $connection.CreateCommand()  
$sqlcmd.CommandText = $SqlQuery  
$results = $sqlcmd.ExecuteReader()  
$table = new-object "System.Data.DataTable" 
$table.Load($results)  
   
# Export table data for testing only  
# $table | Export-Csv -Path "$scriptpath\Table.csv" -NoTypeInformation

$Servers = ($table | Select -Unique Path).Path  
# Create one chart for each server   
Foreach ( $Server in $Servers ) {  
    $Server = ($Server -split '\.')[0]  
    $GraphName = $Server  
    # Create CHART   
    $GraphName = New-object System.Windows.Forms.DataVisualization.Charting.Chart  
    $GraphName.Width = 800  
    $GraphName.Height = 500  
    $GraphName.BackColor = [System.Drawing.Color]::White  
    # CHART Title  
    [void]$GraphName.Titles.Add("$Server - Performance Data")  
    $GraphName.Titles[0].Font = "Arial,10pt"  
    $GraphName.Titles[0].Alignment = "MiddleCenter"  
    # CHART Area and X/Y sizes   
    $chartarea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea  
    $chartarea.Name = "ChartArea"  
    $chartarea.AxisY.Title = "$CounterName"  
    $chartarea.AxisX.Title = "Time"  
    $chartarea.AxisY.Maximum = 100  
    $chartarea.AxisY.Interval = 10  
    $chartarea.AxisX.Interval = 2 
    #$chartarea.AxisX.LabelStyle.Angle = 45
    $GraphName.ChartAreas.Add($chartarea)  
    # CHART Legend  
    $legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend  
    $legend.name = "Legend"  
    $legend.Docking = 2
    $legend.Alignment = 1
    $GraphName.Legends.Add($legend)  
    # Line Colors  
    $num = 0  
    $LineColors = ('DarkBlue','Brown','DarkMagenta')  
    $CounterName = ($table |Select -Unique countername).countername
    # Create 'n' SERIES (lines) for each COUNTER  
    Foreach ($Counter in $CounterName) {  
        $LineColor = $LineColors[$num]  
        [void]$GraphName.Series.Add("$Counter")  
        $GraphName.Series["$Counter"].ChartType = "Line"  
        $GraphName.Series["$Counter"].BorderWidth = 2  
        $GraphName.Series["$Counter"].IsVisibleInLegend = $true  
        $GraphName.Series["$Counter"].chartarea = "ChartArea"  
        $GraphName.Series["$Counter"].Legend = "Legend"  
        $GraphName.Series["$Counter"].color = "$LineColor"  
        $GraphName.Series["$Counter"].MarkerStyle = 2
        ForEach ($i in ($table | ? { $_.CounterName -eq $Counter -and $_.Path -like "$Server*" }) ) {   
            $GraphName.Series["$Counter"].Points.addxy($i.DateTime.ToString(), $i.SampleValue) |Out-Null  
        }  
        $num++ 
    }  
    $GraphName.SaveImage("$scriptpath\$Server.png","png") # Save the GRAPH as PNG  
}  
