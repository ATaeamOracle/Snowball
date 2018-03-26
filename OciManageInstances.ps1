    #     ___  ____     _    ____ _     _____
    #    / _ \|  _ \   / \  / ___| |   | ____|
    #   | | | | |_) | / _ \| |   | |   |  _|
    #   | |_| |  _ < / ___ | |___| |___| |___
    #    \___/|_| \_/_/   \_\____|_____|_____|   OCI Powershell Script
	#
	# OCI Powershell Script to list/start/stop OCI instances
	# Author Michel Benoliel
	# 
	# Configuration: 
	#   you must define the your tenancy root compartment ocid in the ~/.oci/config file. i.e. 
	# root_compartment_id=<your root_compartment_ocid>
	#
	# Usage:
	# Multiple instances can be selected for  start stop



[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

Function Form_Resized(){
	$hdiff = $form.Size.Height - $form.MinimumSize.Height
	$wdiff = $form.Size.Width - $form.MinimumSize.Width
	$newHeight = $dataGridView.MinimumSize.Height + $hdiff
	$newWidth = $dataGridView.MinimumSize.Width + $wdiff
	$dataGridView.size = New-Object System.Drawing.Size($newWidth,$newHeight)
}



Function PopulateCompartments()
{
	$cpobj = oci iam compartment list -c $rootCompartmentId | ConvertFrom-Json
	foreach ($cp in $cpobj.data) {
		$CompartmentComboBox.items.add($cp)

	}
	$CompartmentComboBox.SelectedIndex = 0
}

Function PopulateADs()
{
	$cpobj = oci iam availability-domain list -c $rootCompartmentId | ConvertFrom-Json
	foreach ($cp in $cpobj.data) {
		$ADComboBox.items.add($cp)

	}
}
Function PopulateGrid()
{

	$form.Cursor=[System.Windows.Forms.Cursors]::WaitCursor
#	$instancesObj = oci compute instance list -c ocid1.compartment.oc1..aaaaaaaaowoexmvnos6b7e6csjshxkim4nu2fhte3cyttyp6cg5alwmf4csq | ConvertFrom-Json
	$icmd = "oci compute instance list -c " + $CompartmentComboBox.SelectedItem.'id' + " | ConvertFrom-Json"
	$instancesObj = iex $icmd
	$gdata = $instancesObj.data
	if ( $NameTextBox.Text -ne "")
	{
		$gdata = $instancesObj.data |  Where-Object {$_.'display-name' -Like $NameTextBox.Text}

	}
	
	
	$datagridView.Rows.Clear()
	foreach ($inst in $gdata) {
#		Write-Host $inst
		$instName = $inst.'display-name'
		$state = $inst.'lifecycle-state'
		$ad = $inst.'availability-domain'

		$id1 = $inst.id
		$row = @($instName,$state,$ad, $id1)
		$dataGridView.Rows.Add($row)
	}
	$form.Cursor=[System.Windows.Forms.Cursors]::Default

}


Function CompartmentComboBox_SelectedChanged()
{
	if ($populate -eq $true){
		PopulateGrid
	}

}
Function StartButton_Click()
{
	$form.Cursor=[System.Windows.Forms.Cursors]::WaitCursor
 	$dataGridView.SelectedRows| ForEach-Object{
      $Name = $dataGridView.Rows[$_.Index].Cells[0].Value
      $InstanceState = $dataGridView.Rows[$_.Index].Cells[1].Value
      $InstanceId = $dataGridView.Rows[$_.Index].Cells[3].Value
	  if ($InstanceState -eq "STOPPED"){
		Write-Host "Starting instance" + $Name 
		$command = "oci compute instance action --action START --instance-id " + $InstanceId  + " --wait-for-state STARTING --max-wait-seconds 1"
		iex $command
	  } else {
		Write-Host "Instance" + $Name + ":" + $InstanceState + " - Cannot start"
	  }
	}
	PopulateGrid
	$form.Cursor=[System.Windows.Forms.Cursors]::Default
	
}

Function StopButton_Click()
{
	$form.Cursor=[System.Windows.Forms.Cursors]::WaitCursor

 	$dataGridView.SelectedRows| ForEach-Object{
      $Name = $dataGridView.Rows[$_.Index].Cells[0].Value
      $InstanceState = $dataGridView.Rows[$_.Index].Cells[1].Value
      $InstanceId = $dataGridView.Rows[$_.Index].Cells[3].Value

	  if ($InstanceState -eq "RUNNING"){
		Write-Host "Stopping instance" + $Name 
		$command = "oci compute instance action --action STOP --instance-id " + $InstanceId + " --wait-for-state STOPPING --max-wait-seconds 1"
		iex $command
	  } else {
		Write-Host "Instance" + $Name + ":" + $InstanceState + " - Cannot Stop"
	  }
	}
	PopulateGrid
	$form.Cursor=[System.Windows.Forms.Cursors]::Default
	
}
Function RefreshButton_Click()
{
 PopulateGrid
}
$rootCompartmentId = ""
foreach($line in Get-Content "~\.oci\config") {
    if($line -match "root_compartment_id"){
        $rootCompartmentId = $line -replace "root_compartment_id=" , ""
    }
}
if ($rootCompartmentId -match  "ocid1.tenancy.oc1") {

} else {
	Write-Error "Error: the property root_compartment_id is not defined in the ~\.oci\config file"
	Exit
}

	
$form = New-Object System.Windows.Forms.Form
$form.MinimumSize  = New-Object System.Drawing.Size(900,600)
$form.Size = New-Object System.Drawing.Size(900,600)
$form.Text = "Manage OCI Instances"
$form.AutoSizeMode = "GrowAndShrink"








$FilterGroupBox = New-Object System.Windows.Forms.GroupBox
$FilterGroupBox.Text = "Filter"
$FilterGroupBox.Location = New-Object System.Drawing.Point(10,50) 
$FilterGroupBox.Size = New-Object System.Drawing.Size(500,60) 
$FilterGroupBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left

$form.Controls.Add($FilterGroupBox) 


$CompartmentLabel = New-Object System.Windows.Forms.Label 
$CompartmentLabel.Text = "Compartment"
$CompartmentLabel.Location = New-Object System.Drawing.Point(10,15) 
$CompartmentLabel.Size = New-Object System.Drawing.Size(100,20) 
$FilterGroupBox.Controls.Add($CompartmentLabel) 



$CompartmentComboBox = New-Object System.Windows.Forms.ComboBox 
$CompartmentComboBox.Location = New-Object System.Drawing.Point(10,35) 
$CompartmentComboBox.Size = New-Object System.Drawing.Size(100,20) 
$FilterGroupBox.Controls.Add($CompartmentComboBox) 
$CompartmentComboBox.DisplayMember = "name"
$CompartmentComboBox.ValueMember = "id"


$NameLabel = New-Object System.Windows.Forms.Label 
$NameLabel.Text = "Instance Name"
$NameLabel.Location = New-Object System.Drawing.Point(120,15) 
$NameLabel.Size = New-Object System.Drawing.Size(100,20) 
$FilterGroupBox.Controls.Add($NameLabel) 

$NameTextBox = New-Object System.Windows.Forms.TextBox 
$NameTextBox.Location = New-Object System.Drawing.Point(120,35) 
$NameTextBox.Size = New-Object System.Drawing.Size(100,20) 
$FilterGroupBox.Controls.Add($NameTextBox) 

$ADLabel = New-Object System.Windows.Forms.Label 
$ADLabel.Text = "Availability Domain"
$ADLabel.Location = New-Object System.Drawing.Point(230,15) 
$ADLabel.Size = New-Object System.Drawing.Size(100,20) 
$FilterGroupBox.Controls.Add($ADLabel) 

$ADComboBox = New-Object System.Windows.Forms.ComboBox 
$ADComboBox.Location = New-Object System.Drawing.Point(230,35) 
$ADComboBox.Size = New-Object System.Drawing.Size(250,20) 
$FilterGroupBox.Controls.Add($ADComboBox) 
$ADComboBox.DisplayMember = "name"
$ADComboBox.ValueMember = "name"
$FilterGroupBox.Controls.Add($ADComboBox) 



$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.Location = New-Object System.Drawing.Point(10,150) 
$dataGridView.MinimumSize = New-Object System.Drawing.Size(800,300)
$dataGridView.Size=New-Object System.Drawing.Size(800,300)
# $dataGridView.Dock = [System.Windows.Forms.DockStyle]::Top
$form.Controls.Add($dataGridView)

#Create an unbound DataGridView by declaring a column count.
$dataGridView.ColumnCount = 4
$dataGridView.ColumnHeadersVisible = $true
#Set the column header names.
$dataGridView.Columns[0].Name = "Instance Name"
$dataGridView.Columns[1].Name = "State"
$dataGridView.Columns[2].Name = "Availability Domain"
$dataGridView.Columns[3].Name = "Id"
$dataGridView.Columns[2].Visible = "False"
$dataGridView.Columns[0].wIDTH = 300
$dataGridView.Columns[2].wIDTH = 200
$dataGridView.Columns[3].wIDTH = 700
$dataGridView.SelectionMode = 'FullRowSelect'
$dataGridView.MultiSelect = $true	

$dataGridView.ScrollBars = [System.Windows.Forms.ScrollBars]::Both

# create the buttons
$ButtonsPanel = $NameLabel = New-Object System.Windows.Forms.Panel
$ButtonsPanel.Location = New-Object System.Drawing.Point(1,500)
$ButtonsPanel.Size = New-Object System.Drawing.Size(800,500)
$ButtonsPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($ButtonsPanel)

$StartButton = New-Object System.Windows.Forms.Button
$StartButton.Location = New-Object System.Drawing.Point(75,10)
$StartButton.Size = New-Object System.Drawing.Size(75,23)
$StartButton.Text = "Start"
$ButtonsPanel.Controls.Add($StartButton)

$StopButton = New-Object System.Windows.Forms.Button
$StopButton.Location = New-Object System.Drawing.Point(160,10)
$StopButton.Size = New-Object System.Drawing.Size(75,23)
$StopButton.Text = "Stop"
$ButtonsPanel.Controls.Add($StopButton)

$RefreshButton = New-Object System.Windows.Forms.Button
$RefreshButton.Location = New-Object System.Drawing.Point(250,10)
$RefreshButton.Size = New-Object System.Drawing.Size(75,23)
$RefreshButton.Text = "Refresh"
$ButtonsPanel.Controls.Add($RefreshButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(400,10)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$ButtonsPanel.Controls.Add($CancelButton)


# add event functions to button
$StartButton.Add_Click({StartButton_Click})
$StopButton.Add_Click({StopButton_Click})	
$RefreshButton.Add_Click({RefreshButton_Click})
$CompartmentComboBox.Add_SelectedIndexChanged({CompartmentComboBox_SelectedChanged})

$form.Add_Resize({Form_Resized})    

#Populate the rows.

$compid = ""

$form.Cursor=[System.Windows.Forms.Cursors]::WaitCursor

$populate=$false
PopulateADs
PopulateCompartments
$form.Cursor=[System.Windows.Forms.Cursors]::Default

$populate = $true
PopulateGrid

$form.ShowDialog()
