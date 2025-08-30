# ===================================================================
# PHONE NUMBER CONVERTER CLASS
# ===================================================================

# Define XAML file path
$xamlFile = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\.." | Join-Path -ChildPath "UI" | Join-Path -ChildPath "NetworkManagement.xaml"

# ===================================================================
# SITE VALIDATION FUNCTIONS
# ===================================================================
function Validate-SiteBasicInfo {
    param(
        [SiteEntry]$Site,
        [object]$StatusControl = $null,
        [int]$ExcludeSiteID = -1  # For edit mode - exclude current site from duplicate checks
    )
    
    try {
        # Validate required fields
        if ([string]::IsNullOrWhiteSpace($Site.SiteCode)) {
            $errorMsg = "Site Code is required and cannot be empty."
            [StatusManager]::SetError($StatusControl, $errorMsg)
            throw $errorMsg
        }

        if ([string]::IsNullOrWhiteSpace($Site.SiteSubnet)) {
            $errorMsg = "Site Subnet is required and cannot be empty."
            [StatusManager]::SetError($StatusControl, $errorMsg)
            throw $errorMsg
        }
        
        if ([string]::IsNullOrWhiteSpace($Site.SiteName)) {
            $errorMsg = "Site Name is required and cannot be empty."
            [StatusManager]::SetError($StatusControl, $errorMsg)
            throw $errorMsg
        }
        
        # Validate subnet format
        if ($Site.SiteSubnet -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
            $octets = $Site.SiteSubnet.Split('.')
            $validOctets = $true
            foreach ($octet in $octets) {
                if ([int]$octet -lt 0 -or [int]$octet -gt 255) {
                    $validOctets = $false
                    break
                }
            }
            
            if (-not $validOctets) {
                $errorMsg = "Invalid subnet format. Each octet must be between 0-255."
                if ($StatusControl) {
                    $StatusControl.Text = $errorMsg
                    $StatusControl.Foreground = [System.Windows.Media.Brushes]::Red
                }
                throw $errorMsg
            }
        } else {
            $errorMsg = "Invalid subnet format. Please use format like: XXX.XX.XXX.XXX"
            [StatusManager]::SetError($StatusControl, $errorMsg)
            throw $errorMsg
        }
        
        # Check for duplicates
        $allSites = $siteDataStore.GetAllEntries()
        
        # Check duplicate Site Code (exclude current site if editing)
        $duplicateSiteCode = $allSites | Where-Object { 
            $_.ID -ne $ExcludeSiteID -and $_.SiteCode -eq $Site.SiteCode 
        }
        if ($duplicateSiteCode) {
            $errorMsg = "Site code '$($Site.SiteCode)' already exists in another site."
            [StatusManager]::SetError($StatusControl, $errorMsg)
            throw $errorMsg
        }
        
        # Check duplicate Site Subnet (exclude current site if editing)
        $duplicateSubnet = $allSites | Where-Object { 
            $_.ID -ne $ExcludeSiteID -and $_.SiteSubnet -eq $Site.SiteSubnet 
        }
        if ($duplicateSubnet) {
            $errorMsg = "Site subnet '$($Site.SiteSubnet)' already exists in another site."
            [StatusManager]::SetError($StatusControl, $errorMsg)
            throw $errorMsg
        }
        
        # If we get here, validation passed
        return $true
        
    } catch {
        # Re-throw the error for the calling function to handle
        throw $_
    }
}

# ===================================================================
# CENTRALIZED Centralized ComboBox Function
# ===================================================================
# Centralized function to set ComboBox selection by value or content

# ===================================================================
# UI DIALOG FUNCTIONS
# ===================================================================

# Show custom centered dialog with various button types and icons
function Show-CustomDialog {
    param(
        [string]$Message,
        [string]$Title,
        [string]$ButtonType = "OK",  # OK, YesNo, YesNoCancel
        [string]$Icon = "Information"  # Information, Warning, Error, Question
    )
    
    # Create a new window
    $dialog = New-Object System.Windows.Window
    $dialog.Title = $Title
    $dialog.Width = 400
    $dialog.Height = 200
    $dialog.WindowStartupLocation = "CenterOwner"
    $dialog.Owner = $mainWin
    $dialog.ResizeMode = "NoResize"
    $dialog.WindowStyle = "SingleBorderWindow"
    
    # Create the content
    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = "20"
    
    # Add row definitions
    $row1 = New-Object System.Windows.Controls.RowDefinition
    $row1.Height = "*"
    $row2 = New-Object System.Windows.Controls.RowDefinition  
    $row2.Height = "Auto"
    $grid.RowDefinitions.Add($row1)
    $grid.RowDefinitions.Add($row2)
    
    # Message text
    $textBlock = New-Object System.Windows.Controls.TextBlock
    $textBlock.Text = $Message
    $textBlock.TextWrapping = "Wrap"
    $textBlock.VerticalAlignment = "Center"
    $textBlock.HorizontalAlignment = "Center"
    $textBlock.FontSize = 12
    [System.Windows.Controls.Grid]::SetRow($textBlock, 0)
    $grid.Children.Add($textBlock)
    
    # Button panel
    $buttonPanel = New-Object System.Windows.Controls.StackPanel
    $buttonPanel.Orientation = "Horizontal"
    $buttonPanel.HorizontalAlignment = "Center"
    $buttonPanel.Margin = "0,20,0,0"
    [System.Windows.Controls.Grid]::SetRow($buttonPanel, 1)
    
    $result = $null
    
    if ($ButtonType -eq "OK") {
        $okButton = New-Object System.Windows.Controls.Button
        $okButton.Content = "OK"
        $okButton.Width = 75
        $okButton.Height = 25
        $okButton.IsDefault = $true
        $okButton.Add_Click({
            $script:result = "OK"
            $dialog.DialogResult = $true
            $dialog.Close()
        })
        $buttonPanel.Children.Add($okButton)
    }
    elseif ($ButtonType -eq "YesNo") {
        $yesButton = New-Object System.Windows.Controls.Button
        $yesButton.Content = "Yes"
        $yesButton.Width = 75
        $yesButton.Height = 25
        $yesButton.Margin = "0,0,10,0"
        $yesButton.IsDefault = $true
        $yesButton.Add_Click({
            $script:result = "Yes"
            $dialog.DialogResult = $true
            $dialog.Close()
        })
        
        $noButton = New-Object System.Windows.Controls.Button
        $noButton.Content = "No"
        $noButton.Width = 75
        $noButton.Height = 25
        $noButton.IsCancel = $true
        $noButton.Add_Click({
            $script:result = "No"
            $dialog.DialogResult = $false
            $dialog.Close()
        })
        
        $buttonPanel.Children.Add($yesButton)
        $buttonPanel.Children.Add($noButton)
    }
    
    $grid.Children.Add($buttonPanel)
    $dialog.Content = $grid
    
    # Show dialog and return result
    $null = $dialog.ShowDialog()
    return $script:result
}

    # Show validation error message with status text update
    function Show-ValidationError {
        param(
            [string]$Message,
            [string]$Title = "Validation Error"
        )
        
        # Update status text safely
        try {
            if ($txtBlkSiteStatus) {
                $statusType = switch ($Title) {
                    "Success" { "Success" }
                    "Warning" { "Warning" }
                    default { "Error" }
                }
                [StatusManager]::SetStatus($txtBlkSiteStatus, $Message, $statusType)
            }
        } catch {
            # If status text update fails, just continue with dialog
        }
        
        # Show dialog
        Show-CustomDialog $Message $Title "OK" "Information"
    }

    # Create clickable text element for site details display
    function New-ClickableText {
        param(
            [string]$Value
        )
        
        $textBlock = New-Object System.Windows.Controls.TextBlock
        $textBlock.VerticalAlignment = 'Center'
        
        # Check for empty, null, or "(Not specified)" values
        if ([string]::IsNullOrWhiteSpace($Value) -or $Value -eq "(Not specified)") {
            $textBlock.Text = "(Not specified)"
            $textBlock.Foreground = [System.Windows.Media.Brushes]::Gray
            return $textBlock
        }
        
        # Make it clickable
        $textBlock.Text = $Value
        $textBlock.Cursor = [System.Windows.Input.Cursors]::Hand
        $textBlock.Foreground = [System.Windows.Media.Brushes]::Blue
        #$textBlock.TextDecorations = [System.Windows.TextDecorations]::Underline
        $textBlock.ToolTip = "Click to copy: $Value"
        
        # Store original value as a property to avoid closure issues
        $textBlock | Add-Member -MemberType NoteProperty -Name "OriginalText" -Value $Value
        
        # Add click event to copy
        $textBlock.Add_MouseLeftButtonDown({
            param($sender, $e)
            try {
                $valueToCopy = $sender.OriginalText
                [System.Windows.Clipboard]::SetText($valueToCopy)
                
                # Simple feedback - change text briefly
                $sender.Text = "Copied!"
                $sender.Foreground = [System.Windows.Media.Brushes]::Green
                
                # Use DispatcherTimer for proper UI thread handling
                $timer = New-Object System.Windows.Threading.DispatcherTimer
                $timer.Interval = [System.TimeSpan]::FromMilliseconds(800)
                
                # Store reference to the textblock in timer's tag
                $timer.Tag = $sender
                
                $timer.Add_Tick({
                    param($timerSender, $timerArgs)
                    $textBlock = $timerSender.Tag
                    $textBlock.Text = $textBlock.OriginalText
                    $textBlock.Foreground = [System.Windows.Media.Brushes]::Blue
                    $timerSender.Stop()
                })
                $timer.Start()
                
            } catch {
            }
        })
        return $textBlock
    }


# Import device management functions
try {
    $deviceManagerPath = Join-Path $scriptPath "DeviceManager.ps1"    
    if (Test-Path $deviceManagerPath) {
        . $deviceManagerPath
    }
    else {
        $errorMsg = "DeviceManager.ps1 not found at: $deviceManagerPath"
        [System.Windows.MessageBox]::Show($errorMsg, "Module Error", "OK", "Error")
        exit 1
    }
}
catch {
    $errorMsg = "Failed to load DeviceManager.ps1: $_"
    [System.Windows.MessageBox]::Show($errorMsg, "Module Error", "OK", "Error")
    exit 1
}


# ===================================================================
# FORM MANAGEMENT FUNCTIONS
# ===================================================================

# Clear all form fields and reset to default state
function Clear-SiteForm {
    # Clear all mapped fields using centralized field manager
    if ($script:FieldManager) {
        $script:FieldManager.ClearAllMappings()
    }
    
    # Reset devices using centralized manager
    if ($cmbSwitchCount) { $cmbSwitchCount.SelectedIndex = -1 }
    if ($script:DeviceManager) { $script:DeviceManager.UpdateDevicePanels('Switch', 0) }

    if ($cmbAPCount) { $cmbAPCount.SelectedIndex = -1 }
    if ($script:DeviceManager) { $script:DeviceManager.UpdateDevicePanels('AccessPoint', 0) }

    if ($cmbUPSCount) { $cmbUPSCount.SelectedIndex = -1 }
    if ($script:DeviceManager) { $script:DeviceManager.UpdateDevicePanels('UPS', 0) }

    if ($cmbCCTVCount) { $cmbCCTVCount.SelectedIndex = -1 }
    if ($script:DeviceManager) { $script:DeviceManager.UpdateDevicePanels('CCTV', 0) }
    
    # Reset main checkboxes
    if ($chkHasBackupCircuit) { $chkHasBackupCircuit.IsChecked = $false }
    if ($chkPrimaryHasModem) { $chkPrimaryHasModem.IsChecked = $false }
    if ($chkBackupHasModem) { $chkBackupHasModem.IsChecked = $false }
    
    # Hide conditional sections
    if ($grdBackupCircuit) { $grdBackupCircuit.Visibility = "Collapsed" }
    if ($stkPrimaryModem) { $stkPrimaryModem.Visibility = "Collapsed" }
    if ($stkBackupModem) { $stkBackupModem.Visibility = "Collapsed" }
}

# Collect all site data from form fields using centralized managers
function Get-SiteDataFromForm {
    $site = [SiteEntry]::new()
    
    # Get all mapped fields using centralized field manager
    $script:FieldManager.GetAllMappings($site)
    
    # Get device data using centralized device manager
    $site.SwitchCount = if ($cmbSwitchCount.SelectedItem) { [int]$cmbSwitchCount.SelectedItem.Content } else { 1 }
    $site.Switches = $script:DeviceManager.GetDeviceDataFromUI('Switch')

    $site.APCount = if ($cmbAPCount.SelectedItem) { [int]$cmbAPCount.SelectedItem.Content } else { 1 }
    $site.AccessPoints = $script:DeviceManager.GetDeviceDataFromUI('AccessPoint')

    $site.UPSCount = if ($cmbUPSCount.SelectedItem) { [int]$cmbUPSCount.SelectedItem.Content } else { 0 }
    $site.UPSDevices = $script:DeviceManager.GetDeviceDataFromUI('UPS')

    $site.CCTVCount = if ($cmbCCTVCount.SelectedItem) { [int]$cmbCCTVCount.SelectedItem.Content } else { 0 }
    $site.CCTVDevices = $script:DeviceManager.GetDeviceDataFromUI('CCTV')

    $site.PrinterCount = if ($cmbPrinterCount.SelectedItem) { [int]$cmbPrinterCount.SelectedItem.Content } else { 0 }
    $site.PrinterDevices = $script:DeviceManager.GetDeviceDataFromUI('Printer')
        
    # Get main checkboxes
    $site.HasBackupCircuit = $chkHasBackupCircuit.IsChecked
    
    return $site
}

# ===================================================================
# SITE MANAGEMENT FUNCTIONS
# ===================================================================

# Add new site with validation and duplicate checking
function Add-Site {
   try {
       # Get site data from form
       $site = Get-SiteDataFromForm

        # Use centralized validation
        try {
            Validate-SiteBasicInfo -Site $site -StatusControl $txtBlkSiteStatus
        } catch {
            Show-CustomDialog $_.Exception.Message "Validation Error" "OK" "Error"
            return $false
        }
       # Try to add the site
       try {
           $addResult = $siteDataStore.AddEntry($site)
           
           if ($addResult -eq $true) {
               Show-CustomDialog "Site '$($site.SiteCode)' added successfully!" "Success" "OK" "Information"
               Clear-SiteForm
               Update-DataGridWithSearch
               return $true
           }
       } catch {
           Show-CustomDialog "Error adding site: $($_.Exception.Message)" "Error" "OK" "Error"
           return $false
       }
   } catch {
       Show-CustomDialog "Error in Add-Site: $($_.Exception.Message)" "Error" "OK" "Error"
       return $false
   }
}

# ===================================================================
# DATA GRID MANAGEMENT FUNCTIONS
# ===================================================================

# Update DataGrid with search functionality and selection preservation
function Update-DataGridWithSearch {
    $searchTerm = $txtSearchSites.Text
    
    # Store current selection
    $selectedItems = @()
    if ($dgSites.SelectedItems.Count -gt 0) {
        foreach ($item in $dgSites.SelectedItems) {
            $selectedItems += $item.ID
        }
    }
    
    # Get all data from the data store
    $allData = $siteDataStore.GetAllEntries()
    
    # Filter data if search term exists
    if (-not [string]::IsNullOrWhiteSpace($searchTerm)) {
        $searchTerm = $searchTerm.Trim().ToLower()
        $allData = $allData | Where-Object {
            $_.SiteCode.ToLower().Contains($searchTerm) -or
            $_.SiteName.ToLower().Contains($searchTerm) -or
            $_.SiteSubnetCode.ToLower().Contains($searchTerm) -or
            $_.SiteAddress.ToLower().Contains($searchTerm) -or
            $_.MainContactName.ToLower().Contains($searchTerm) -or
            $_.Switch1IP.ToLower().Contains($searchTerm) -or
            $_.Switch1Name.ToLower().Contains($searchTerm) -or
            $_.FirewallIP.ToLower().Contains($searchTerm) -or
            $_.PrimaryVendor.ToLower().Contains($searchTerm)
        }
    }
    
    # Sort by ID numerically and update DataGrid
    $allData = $allData | Sort-Object -Property @{Expression={[int]$_.ID}; Ascending=$true}
    
    # Only update ItemsSource if data actually changed
    if ($dgSites.Items.Count -ne $allData.Count) {
        $dgSites.ItemsSource = @($allData)
        
        # Restore selection if items still exist
        if ($selectedItems.Count -gt 0) {
            $dgSites.SelectedItems.Clear()
            foreach ($item in $dgSites.Items) {
                if ($item.ID -in $selectedItems) {
                    $dgSites.SelectedItems.Add($item)
                }
            }
        }
    }
    
    # Update status bar
    $txtStatusBarSites.Text = "Total Sites: $($allData.Count)"
    $selectedCount = $dgSites.SelectedItems.Count
    if ($selectedCount -gt 0) {
        if ($selectedCount -eq 1) {
            $txtStatusBarSiteSelected.Text = "Selected: $($dgSites.SelectedItems[0].SiteCode) - $($dgSites.SelectedItems[0].SiteName)"
        } else {
            $txtStatusBarSiteSelected.Text = "Selected: $selectedCount sites"
        }
    } else {
        $txtStatusBarSiteSelected.Text = "Selected: None"
}}

# ===================================================================
# SITE LOOKUP AND DISPLAY FUNCTIONS
# ===================================================================

# Search for site by code or name and display details
function Lookup-Site {
    param([string]$SearchTerm)
    
    # Hide results at start
    $grpSiteLookupResults.Visibility = "Collapsed"
    
    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {
        Show-CustomDialog "Please enter a site code or name to search" "Input Required" "OK" "Warning"
        return
    }
    
    $searchTerm = $SearchTerm.Trim().ToLower()
    $allSites = $siteDataStore.GetAllEntries()
    
    $foundSite = $allSites | Where-Object {
        $_.SiteCode.ToLower().Contains($searchTerm) -or
        $_.SiteName.ToLower().Contains($searchTerm)
    } | Select-Object -First 1
    
    if ($foundSite) {
            Write-Host "DEBUG: Found site: $($foundSite.SiteCode)"
        Show-SiteDetails -Site $foundSite
        $grpSiteLookupResults.Visibility = "Visible"
    } else {
            Write-Host "DEBUG: No site found for: $searchTerm"
        Show-CustomDialog "Site '$SearchTerm' not found in the database." "Not Found" "OK" "Information"
    }
}

# Display comprehensive site details in lookup tab with tabbed layout (like manage sites)
function Show-SiteDetails {
    param([SiteEntry]$Site)
    
    try {
        Write-Host "DEBUG: Show-SiteDetails called with site: $($Site.SiteCode)"
        
        # Clear previous content
        $stkSiteDetails.Children.Clear()
        
        # Create a Grid that fills the available space
        $mainGrid = New-Object System.Windows.Controls.Grid
        $mainGrid.Margin = "0"
        $mainGrid.HorizontalAlignment = "Stretch"
        $mainGrid.VerticalAlignment = "Stretch"
        
        # Create TabControl that fills the grid
        $tabControl = New-Object System.Windows.Controls.TabControl
        $tabControl.Margin = "0"
        $tabControl.HorizontalAlignment = "Stretch"
        $tabControl.VerticalAlignment = "Stretch"
        $tabControl.HorizontalContentAlignment = "Stretch"
        $tabControl.VerticalContentAlignment = "Stretch"
        
        # === TAB 1: BASIC INFO ===
        $basicTab = New-Object System.Windows.Controls.TabItem
        $basicTab.Header = "Basic Info"
        
        $basicScrollViewer = New-Object System.Windows.Controls.ScrollViewer
        $basicScrollViewer.VerticalScrollBarVisibility = "Auto"
        $basicScrollViewer.HorizontalAlignment = "Stretch"
        $basicScrollViewer.VerticalAlignment = "Stretch"
        
        $basicStackPanel = New-Object System.Windows.Controls.StackPanel
        $basicStackPanel.Margin = "15"
        $basicStackPanel.Orientation = "Vertical"
        
        $basicInfoFields = @(
            @("Site Code:", $Site.SiteCode),
            @("Site Subnet Code:", $Site.SiteSubnetCode),
            @("Site Subnet:", $Site.SiteSubnet),
            @("Site Name:", $Site.SiteName),
            @("Site Address:", $Site.SiteAddress),
            @("Main Contact:", $Site.MainContactName),
            @("Main Phone:", $Site.MainContactPhone),
            @("Second Contact:", $Site.SecondContactName),
            @("Second Phone:", $Site.SecondContactPhone)
        )
        
        foreach ($field in $basicInfoFields) {
            $fieldGrid = New-Object System.Windows.Controls.Grid
            $fieldGrid.Margin = "0,3,0,3"
            
            $labelCol = New-Object System.Windows.Controls.ColumnDefinition
            $labelCol.Width = "180"
            $valueCol = New-Object System.Windows.Controls.ColumnDefinition
            $valueCol.Width = "*"
            $fieldGrid.ColumnDefinitions.Add($labelCol)
            $fieldGrid.ColumnDefinitions.Add($valueCol)
            
            $label = New-Object System.Windows.Controls.TextBlock
            $label.Text = $field[0]
            $label.FontWeight = "Bold"
            $label.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($label, 0)
            $fieldGrid.Children.Add($label)
            
            $clickableText = New-ClickableText -Value $field[1]
            $clickableText.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($clickableText, 1)
            $fieldGrid.Children.Add($clickableText)
            
            $basicStackPanel.Children.Add($fieldGrid)
        }
        
        $basicScrollViewer.Content = $basicStackPanel
        $basicTab.Content = $basicScrollViewer
        $tabControl.Items.Add($basicTab)
        
        # === TAB 2: SWITCHES (RESPONSIVE) ===
        $switchTab = New-Object System.Windows.Controls.TabItem
        $switchTab.Header = "Switches"

        $switchScrollViewer = New-Object System.Windows.Controls.ScrollViewer
        $switchScrollViewer.VerticalScrollBarVisibility = "Auto"
        $switchScrollViewer.HorizontalAlignment = "Stretch"
        $switchScrollViewer.VerticalAlignment = "Stretch"

        # Create the main container that will hold our dynamic content
        $switchMainContainer = New-Object System.Windows.Controls.Grid
        $switchMainContainer.Margin = "15"
        $switchMainContainer.Name = "SwitchMainContainer"

        # Function to build switch layout based on window width
        $script:BuildSwitchLayout = {
            param($containerWidth)
            
            # Clear existing content
            $switchMainContainer.Children.Clear()
            $switchMainContainer.RowDefinitions.Clear()
            $switchMainContainer.ColumnDefinitions.Clear()
            
            # Determine column count based on width
            $columnCount = if ($containerWidth -ge 1200) { 4 } 
                        elseif ($containerWidth -ge 900) { 3 }
                        elseif ($containerWidth -ge 600) { 2 }
                        else { 1 }
            
            $devicesPerColumn = switch ($columnCount) {
                4 { 3 }
                3 { 4 }  
                2 { 6 }
                1 { 999 }  # All devices in single column
            }
            
            # Create row definitions
            $headerRow = New-Object System.Windows.Controls.RowDefinition
            $headerRow.Height = "Auto"
            $contentRow = New-Object System.Windows.Controls.RowDefinition
            $contentRow.Height = "*"
            $switchMainContainer.RowDefinitions.Add($headerRow)
            $switchMainContainer.RowDefinitions.Add($contentRow)
            
            # Create column definitions
            $columnWidth = [Math]::Floor(100 / $columnCount)
            for ($i = 0; $i -lt $columnCount; $i++) {
                $column = New-Object System.Windows.Controls.ColumnDefinition
                $column.Width = "${columnWidth}*"
                $switchMainContainer.ColumnDefinitions.Add($column)
            }
            
            $validSwitches = @()
            if ($Site.Switches) {
                $validSwitches = @($Site.Switches | Where-Object {
                    (-not [string]::IsNullOrWhiteSpace($_.ManagementIP)) -or 
                    (-not [string]::IsNullOrWhiteSpace($_.Name)) -or 
                    (-not [string]::IsNullOrWhiteSpace($_.AssetTag)) -or 
                    (-not [string]::IsNullOrWhiteSpace($_.Version)) -or 
                    (-not [string]::IsNullOrWhiteSpace($_.SerialNumber))
                })
            }
            
            # Count header spanning all columns
            $switchCountGrid = New-Object System.Windows.Controls.Grid
            $switchCountGrid.Margin = "0,0,0,15"
            $switchCountLabelCol = New-Object System.Windows.Controls.ColumnDefinition
            $switchCountLabelCol.Width = "180"
            $switchCountValueCol = New-Object System.Windows.Controls.ColumnDefinition
            $switchCountValueCol.Width = "*"
            $switchCountGrid.ColumnDefinitions.Add($switchCountLabelCol)
            $switchCountGrid.ColumnDefinitions.Add($switchCountValueCol)
            
            $switchCountLabel = New-Object System.Windows.Controls.TextBlock
            $switchCountLabel.Text = "Total Switches:"
            $switchCountLabel.FontWeight = "Bold"
            $switchCountLabel.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($switchCountLabel, 0)
            $switchCountGrid.Children.Add($switchCountLabel)
            
            $switchCountValue = New-Object System.Windows.Controls.TextBlock
            $switchCountValue.Text = "$($validSwitches.Count) (${columnCount} columns)"
            $switchCountValue.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($switchCountValue, 1)
            $switchCountGrid.Children.Add($switchCountValue)
            
            [System.Windows.Controls.Grid]::SetRow($switchCountGrid, 0)
            [System.Windows.Controls.Grid]::SetColumnSpan($switchCountGrid, $columnCount)
            $switchMainContainer.Children.Add($switchCountGrid)
            
            if ($validSwitches.Count -eq 0) {
                # No switches - status message spanning all columns
                $noSwitchGrid = New-Object System.Windows.Controls.Grid
                $noSwitchGrid.Margin = "0,3,0,3"
                $noSwitchLabelCol = New-Object System.Windows.Controls.ColumnDefinition
                $noSwitchLabelCol.Width = "180"
                $noSwitchValueCol = New-Object System.Windows.Controls.ColumnDefinition
                $noSwitchValueCol.Width = "*"
                $noSwitchGrid.ColumnDefinitions.Add($noSwitchLabelCol)
                $noSwitchGrid.ColumnDefinitions.Add($noSwitchValueCol)
                
                $noSwitchLabel = New-Object System.Windows.Controls.TextBlock
                $noSwitchLabel.Text = "Status:"
                $noSwitchLabel.FontWeight = "Bold"
                $noSwitchLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($noSwitchLabel, 0)
                $noSwitchGrid.Children.Add($noSwitchLabel)
                
                $noSwitchValue = New-Object System.Windows.Controls.TextBlock
                $noSwitchValue.Text = "No switches configured for this site"
                $noSwitchValue.FontStyle = "Italic"
                $noSwitchValue.Foreground = "Gray"
                $noSwitchValue.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($noSwitchValue, 1)
                $noSwitchGrid.Children.Add($noSwitchValue)
                
                [System.Windows.Controls.Grid]::SetRow($noSwitchGrid, 1)
                [System.Windows.Controls.Grid]::SetColumnSpan($noSwitchGrid, $columnCount)
                $switchMainContainer.Children.Add($noSwitchGrid)
            } else {
                # Create StackPanels for each column
                $columnStackPanels = @()
                for ($i = 0; $i -lt $columnCount; $i++) {
                    $stackPanel = New-Object System.Windows.Controls.StackPanel
                    $stackPanel.Margin = "5"
                    $stackPanel.Orientation = "Vertical"
                    $columnStackPanels += $stackPanel
                }
                
                # Distribute switches across columns
                for ($i = 0; $i -lt $validSwitches.Count; $i++) {
                    $device = $validSwitches[$i]
                    
                    # Determine target column
                    $targetColumnIndex = [Math]::Floor($i / $devicesPerColumn)
                    if ($targetColumnIndex -ge $columnCount) { $targetColumnIndex = $columnCount - 1 }
                    $targetStackPanel = $columnStackPanels[$targetColumnIndex]
                    
                    # Device header
                    $deviceHeaderGrid = New-Object System.Windows.Controls.Grid
                    $deviceHeaderGrid.Margin = "0,30,0,5"
                    $deviceHeaderLabelCol = New-Object System.Windows.Controls.ColumnDefinition
                    $labelWidth = if ($columnCount -eq 1) { "180" } else { "120" }
                    $deviceHeaderLabelCol.Width = $labelWidth
                    $deviceHeaderValueCol = New-Object System.Windows.Controls.ColumnDefinition
                    $deviceHeaderValueCol.Width = "*"
                    $deviceHeaderGrid.ColumnDefinitions.Add($deviceHeaderLabelCol)
                    $deviceHeaderGrid.ColumnDefinitions.Add($deviceHeaderValueCol)
                    
                    $deviceHeaderLabel = New-Object System.Windows.Controls.TextBlock
                    $deviceHeaderLabel.Text = "Switch $($i + 1):"
                    $deviceHeaderLabel.FontWeight = "Bold"
                    $deviceHeaderLabel.FontSize = 14
                    $deviceHeaderLabel.VerticalAlignment = "Center"
                    [System.Windows.Controls.Grid]::SetColumn($deviceHeaderLabel, 0)
                    $deviceHeaderGrid.Children.Add($deviceHeaderLabel)
                    
                    $targetStackPanel.Children.Add($deviceHeaderGrid)
                    
                    # Device fields
                    $deviceFields = @(
                        @("Name:", $(if ($device.Name) { $device.Name } else { '(Not specified)' })),                    
                        @("Management IP:", $(if ($device.ManagementIP) { $device.ManagementIP } else { '(Not specified)' })),
                        @("Asset Tag:", $(if ($device.AssetTag) { $device.AssetTag } else { '(Not specified)' })),
                        @("Version:", $(if ($device.Version) { $device.Version } else { '(Not specified)' })),
                        @("Serial Number:", $(if ($device.SerialNumber) { $device.SerialNumber } else { '(Not specified)' }))
                    )
                    
                    foreach ($field in $deviceFields) {
                        $fieldGrid = New-Object System.Windows.Controls.Grid
                        $fieldGrid.Margin = "0,3,0,3"
                        
                        $labelCol = New-Object System.Windows.Controls.ColumnDefinition
                        $labelCol.Width = $labelWidth
                        $valueCol = New-Object System.Windows.Controls.ColumnDefinition
                        $valueCol.Width = "*"
                        $fieldGrid.ColumnDefinitions.Add($labelCol)
                        $fieldGrid.ColumnDefinitions.Add($valueCol)
                        
                        $label = New-Object System.Windows.Controls.TextBlock
                        $label.Text = $field[0]
                        $label.FontWeight = "Bold"
                        $label.VerticalAlignment = "Center"
                        [System.Windows.Controls.Grid]::SetColumn($label, 0)
                        $fieldGrid.Children.Add($label)
                        
                        $clickableText = New-ClickableText -Value $field[1]
                        $clickableText.VerticalAlignment = "Center"
                        $clickableText.TextWrapping = "Wrap"
                        [System.Windows.Controls.Grid]::SetColumn($clickableText, 1)
                        $fieldGrid.Children.Add($clickableText)
                        
                        $targetStackPanel.Children.Add($fieldGrid)
                    }
                }
                
                # Add column StackPanels to main grid
                for ($i = 0; $i -lt $columnCount; $i++) {
                    [System.Windows.Controls.Grid]::SetRow($columnStackPanels[$i], 1)
                    [System.Windows.Controls.Grid]::SetColumn($columnStackPanels[$i], $i)
                    $switchMainContainer.Children.Add($columnStackPanels[$i])
                }
            }
        }

        # Initial layout build
        & $script:BuildSwitchLayout -containerWidth 1200

        # Set up resize handler - check if SizeChanged event exists
        if ($switchScrollViewer.SizeChanged) {
            $switchScrollViewer.SizeChanged.Add({
                $currentWidth = $switchScrollViewer.ActualWidth - 30  # Account for margins
                & $script:BuildSwitchLayout -containerWidth $currentWidth
            })
        }

        $switchScrollViewer.Content = $switchMainContainer
        $switchTab.Content = $switchScrollViewer
        $tabControl.Items.Add($switchTab)
        
        # === TAB 3: ACCESS POINTS ===
        $apTab = New-Object System.Windows.Controls.TabItem
        $apTab.Header = "Access Points"

        $apScrollViewer = New-Object System.Windows.Controls.ScrollViewer
        $apScrollViewer.VerticalScrollBarVisibility = "Auto"
        $apScrollViewer.HorizontalAlignment = "Stretch"
        $apScrollViewer.VerticalAlignment = "Stretch"

        $apMainContainer = New-Object System.Windows.Controls.Grid
        $apMainContainer.Margin = "15"
        $apMainContainer.Name = "APMainContainer"

        # Function to build AP layout based on window width
        $script:BuildAPLayout = {
            param($containerWidth)
            
            # Clear existing content
            $apMainContainer.Children.Clear()
            $apMainContainer.RowDefinitions.Clear()
            $apMainContainer.ColumnDefinitions.Clear()
            
            # Determine column count based on width
            $columnCount = if ($containerWidth -ge 1200) { 4 } 
                        elseif ($containerWidth -ge 900) { 3 }
                        elseif ($containerWidth -ge 600) { 2 }
                        else { 1 }
            
            $devicesPerColumn = switch ($columnCount) {
                4 { 3 }
                3 { 4 }  
                2 { 6 }
                1 { 999 }
            }
            
            # Create row definitions
            $headerRow = New-Object System.Windows.Controls.RowDefinition
            $headerRow.Height = "Auto"
            $contentRow = New-Object System.Windows.Controls.RowDefinition
            $contentRow.Height = "*"
            $apMainContainer.RowDefinitions.Add($headerRow)
            $apMainContainer.RowDefinitions.Add($contentRow)
            
            # Create column definitions
            $columnWidth = [Math]::Floor(100 / $columnCount)
            for ($i = 0; $i -lt $columnCount; $i++) {
                $column = New-Object System.Windows.Controls.ColumnDefinition
                $column.Width = "${columnWidth}*"
                $apMainContainer.ColumnDefinitions.Add($column)
            }
            
            $validAPs = @()
            if ($Site.AccessPoints) {
                $validAPs = @($Site.AccessPoints | Where-Object {
                    (-not [string]::IsNullOrWhiteSpace($_.ManagementIP)) -or 
                    (-not [string]::IsNullOrWhiteSpace($_.Name)) -or 
                    (-not [string]::IsNullOrWhiteSpace($_.AssetTag)) -or 
                    (-not [string]::IsNullOrWhiteSpace($_.Version)) -or 
                    (-not [string]::IsNullOrWhiteSpace($_.SerialNumber))
                })
            }
            
            # Count header spanning all columns
            $apCountGrid = New-Object System.Windows.Controls.Grid
            $apCountGrid.Margin = "0,0,0,15"
            $apCountLabelCol = New-Object System.Windows.Controls.ColumnDefinition
            $apCountLabelCol.Width = "180"
            $apCountValueCol = New-Object System.Windows.Controls.ColumnDefinition
            $apCountValueCol.Width = "*"
            $apCountGrid.ColumnDefinitions.Add($apCountLabelCol)
            $apCountGrid.ColumnDefinitions.Add($apCountValueCol)
            
            $apCountLabel = New-Object System.Windows.Controls.TextBlock
            $apCountLabel.Text = "Total Access Points:"
            $apCountLabel.FontWeight = "Bold"
            $apCountLabel.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($apCountLabel, 0)
            $apCountGrid.Children.Add($apCountLabel)
            
            $apCountValue = New-Object System.Windows.Controls.TextBlock
            $apCountValue.Text = "$($validAPs.Count) (${columnCount} columns)"
            $apCountValue.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($apCountValue, 1)
            $apCountGrid.Children.Add($apCountValue)
            
            [System.Windows.Controls.Grid]::SetRow($apCountGrid, 0)
            [System.Windows.Controls.Grid]::SetColumnSpan($apCountGrid, $columnCount)
            $apMainContainer.Children.Add($apCountGrid)
            
            if ($validAPs.Count -eq 0) {
                $noAPGrid = New-Object System.Windows.Controls.Grid
                $noAPGrid.Margin = "0,3,0,3"
                $noAPLabelCol = New-Object System.Windows.Controls.ColumnDefinition
                $noAPLabelCol.Width = "180"
                $noAPValueCol = New-Object System.Windows.Controls.ColumnDefinition
                $noAPValueCol.Width = "*"
                $noAPGrid.ColumnDefinitions.Add($noAPLabelCol)
                $noAPGrid.ColumnDefinitions.Add($noAPValueCol)
                
                $noAPLabel = New-Object System.Windows.Controls.TextBlock
                $noAPLabel.Text = "Status:"
                $noAPLabel.FontWeight = "Bold"
                $noAPLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($noAPLabel, 0)
                $noAPGrid.Children.Add($noAPLabel)
                
                $noAPValue = New-Object System.Windows.Controls.TextBlock
                $noAPValue.Text = "No access points configured for this site"
                $noAPValue.FontStyle = "Italic"
                $noAPValue.Foreground = "Gray"
                $noAPValue.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($noAPValue, 1)
                $noAPGrid.Children.Add($noAPValue)
                
                [System.Windows.Controls.Grid]::SetRow($noAPGrid, 1)
                [System.Windows.Controls.Grid]::SetColumnSpan($noAPGrid, $columnCount)
                $apMainContainer.Children.Add($noAPGrid)
            } else {
                $columnStackPanels = @()
                for ($i = 0; $i -lt $columnCount; $i++) {
                    $stackPanel = New-Object System.Windows.Controls.StackPanel
                    $stackPanel.Margin = "5"
                    $stackPanel.Orientation = "Vertical"
                    $columnStackPanels += $stackPanel
                }
                
                for ($i = 0; $i -lt $validAPs.Count; $i++) {
                    $device = $validAPs[$i]
                    
                    $targetColumnIndex = [Math]::Floor($i / $devicesPerColumn)
                    if ($targetColumnIndex -ge $columnCount) { $targetColumnIndex = $columnCount - 1 }
                    $targetStackPanel = $columnStackPanels[$targetColumnIndex]
                    
                    $deviceHeaderGrid = New-Object System.Windows.Controls.Grid
                    $deviceHeaderGrid.Margin = "0,30,0,5"
                    $deviceHeaderLabelCol = New-Object System.Windows.Controls.ColumnDefinition
                    $labelWidth = if ($columnCount -eq 1) { "180" } else { "100" }
                    $deviceHeaderLabelCol.Width = $labelWidth
                    $deviceHeaderValueCol = New-Object System.Windows.Controls.ColumnDefinition
                    $deviceHeaderValueCol.Width = "*"
                    $deviceHeaderGrid.ColumnDefinitions.Add($deviceHeaderLabelCol)
                    $deviceHeaderGrid.ColumnDefinitions.Add($deviceHeaderValueCol)
                    
                    $deviceHeaderLabel = New-Object System.Windows.Controls.TextBlock
                    $deviceHeaderLabel.Text = "Access Point $($i + 1):"
                    $deviceHeaderLabel.FontWeight = "Bold"
                    $deviceHeaderLabel.FontSize = 14
                    $deviceHeaderLabel.VerticalAlignment = "Center"
                    [System.Windows.Controls.Grid]::SetColumn($deviceHeaderLabel, 0)
                    $deviceHeaderGrid.Children.Add($deviceHeaderLabel)
                    
                    $targetStackPanel.Children.Add($deviceHeaderGrid)
                    
                    $deviceFields = @(
                        @("Name:", $(if ($device.Name) { $device.Name } else { '(Not specified)' })),                    
                        @("Management IP:", $(if ($device.ManagementIP) { $device.ManagementIP } else { '(Not specified)' })),
                        @("Asset Tag:", $(if ($device.AssetTag) { $device.AssetTag } else { '(Not specified)' })),
                        @("Version:", $(if ($device.Version) { $device.Version } else { '(Not specified)' })),
                        @("Serial Number:", $(if ($device.SerialNumber) { $device.SerialNumber } else { '(Not specified)' }))
                    )
                    
                    foreach ($field in $deviceFields) {
                        $fieldGrid = New-Object System.Windows.Controls.Grid
                        $fieldGrid.Margin = "0,3,0,3"
                        
                        $labelCol = New-Object System.Windows.Controls.ColumnDefinition
                        $labelCol.Width = $labelWidth
                        $valueCol = New-Object System.Windows.Controls.ColumnDefinition
                        $valueCol.Width = "*"
                        $fieldGrid.ColumnDefinitions.Add($labelCol)
                        $fieldGrid.ColumnDefinitions.Add($valueCol)
                        
                        $label = New-Object System.Windows.Controls.TextBlock
                        $label.Text = $field[0]
                        $label.FontWeight = "Bold"
                        $label.VerticalAlignment = "Center"
                        [System.Windows.Controls.Grid]::SetColumn($label, 0)
                        $fieldGrid.Children.Add($label)
                        
                        $clickableText = New-ClickableText -Value $field[1]
                        $clickableText.VerticalAlignment = "Center"
                        $clickableText.TextWrapping = "Wrap"
                        [System.Windows.Controls.Grid]::SetColumn($clickableText, 1)
                        $fieldGrid.Children.Add($clickableText)
                        
                        $targetStackPanel.Children.Add($fieldGrid)
                    }
                }
                
                for ($i = 0; $i -lt $columnCount; $i++) {
                    [System.Windows.Controls.Grid]::SetRow($columnStackPanels[$i], 1)
                    [System.Windows.Controls.Grid]::SetColumn($columnStackPanels[$i], $i)
                    $apMainContainer.Children.Add($columnStackPanels[$i])
                }
            }
        }

        & $script:BuildAPLayout -containerWidth 1200

        if ($apScrollViewer.SizeChanged) {
            $apScrollViewer.SizeChanged.Add({
                $currentWidth = $apScrollViewer.ActualWidth - 30
                & $script:BuildAPLayout -containerWidth $currentWidth
            })
        }

        $apScrollViewer.Content = $apMainContainer
        $apTab.Content = $apScrollViewer
        $tabControl.Items.Add($apTab)
        
        # === TAB 4: FIREWALL ===
        $firewallTab = New-Object System.Windows.Controls.TabItem
        $firewallTab.Header = "Firewall"
        
        $firewallScrollViewer = New-Object System.Windows.Controls.ScrollViewer
        $firewallScrollViewer.VerticalScrollBarVisibility = "Auto"
        $firewallScrollViewer.HorizontalAlignment = "Stretch"
        $firewallScrollViewer.VerticalAlignment = "Stretch"
        
        $firewallFields = @(
            @("Name:", $(if ($Site.FirewallName) { $Site.FirewallName } else { '(Not specified)' })),           
            @("Management IP:", $(if ($Site.FirewallIP) { $Site.FirewallIP } else { '(Not specified)' })),
            @("Version:", $(if ($Site.FirewallVersion) { $Site.FirewallVersion } else { '(Not specified)' })),
            @("Serial Number:", $(if ($Site.FirewallSN) { $Site.FirewallSN } else { '(Not specified)' }))
        )
        
        $hasFirewallData = $firewallFields | Where-Object { -not [string]::IsNullOrWhiteSpace($_[1]) -and $_[1] -ne '(Not specified)' }
        
        if (-not $hasFirewallData) {
            $emptyFirewallText = New-Object System.Windows.Controls.TextBlock
            $emptyFirewallText.Text = "No firewall information configured for this site."
            $emptyFirewallText.Margin = "15"
            $emptyFirewallText.FontStyle = "Italic"
            $emptyFirewallText.Foreground = "Gray"
            $firewallScrollViewer.Content = $emptyFirewallText
        } else {
            $firewallStackPanel = New-Object System.Windows.Controls.StackPanel
            $firewallStackPanel.Margin = "15"
            $firewallStackPanel.Orientation = "Vertical"
            
            foreach ($field in $firewallFields) {
                $fieldGrid = New-Object System.Windows.Controls.Grid
                $fieldGrid.Margin = "0,3,0,3"
                
                $labelCol = New-Object System.Windows.Controls.ColumnDefinition
                $labelCol.Width = "180"
                $valueCol = New-Object System.Windows.Controls.ColumnDefinition
                $valueCol.Width = "*"
                $fieldGrid.ColumnDefinitions.Add($labelCol)
                $fieldGrid.ColumnDefinitions.Add($valueCol)
                
                $label = New-Object System.Windows.Controls.TextBlock
                $label.Text = $field[0]
                $label.FontWeight = "Bold"
                $label.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($label, 0)
                $fieldGrid.Children.Add($label)
                
                $clickableText = New-ClickableText -Value $field[1]
                $clickableText.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($clickableText, 1)
                $fieldGrid.Children.Add($clickableText)
                
                $firewallStackPanel.Children.Add($fieldGrid)
            }
            
            $firewallScrollViewer.Content = $firewallStackPanel
        }
        
        $firewallTab.Content = $firewallScrollViewer
        $tabControl.Items.Add($firewallTab)
        
        # === TAB 5: PRIMARY CIRCUIT ===
        $primaryTabItem = New-Object System.Windows.Controls.TabItem
        $primaryTabItem.Header = "Primary Circuit"

        $primaryGrid = New-Object System.Windows.Controls.Grid

        # Add column headers
        $headerRow = New-Object System.Windows.Controls.RowDefinition
        $headerRow.Height = "Auto"
        $contentRow = New-Object System.Windows.Controls.RowDefinition
        $contentRow.Height = "*"
        $primaryGrid.RowDefinitions.Add($headerRow)
        $primaryGrid.RowDefinitions.Add($contentRow)

        # Add two columns
        $column1 = New-Object System.Windows.Controls.ColumnDefinition
        $column1.Width = "50*"
        $column2 = New-Object System.Windows.Controls.ColumnDefinition  
        $column2.Width = "50*"
        $primaryGrid.ColumnDefinitions.Add($column1)
        $primaryGrid.ColumnDefinitions.Add($column2)

        # Circuit header (left)
        $circuitHeader = New-Object System.Windows.Controls.TextBlock
        $circuitHeader.Text = "Circuit"
        $circuitHeader.FontSize = 16
        $circuitHeader.FontWeight = "Bold"
        $circuitHeader.Margin = "10,5,10,5"
        $circuitHeader.HorizontalAlignment = "Left"
        [System.Windows.Controls.Grid]::SetColumn($circuitHeader, 0)
        [System.Windows.Controls.Grid]::SetRow($circuitHeader, 0)
        $primaryGrid.Children.Add($circuitHeader)

        # Modem header (right)
        $modemHeader = New-Object System.Windows.Controls.TextBlock
        $modemHeader.Text = "Modem"
        $modemHeader.FontSize = 16
        $modemHeader.FontWeight = "Bold"
        $modemHeader.Margin = "10,5,10,5"
        $modemHeader.HorizontalAlignment = "Left"
        [System.Windows.Controls.Grid]::SetColumn($modemHeader, 1)
        [System.Windows.Controls.Grid]::SetRow($modemHeader, 0)
        $primaryGrid.Children.Add($modemHeader)

        # Create StackPanels for each column
        $circuitStackPanel = New-Object System.Windows.Controls.StackPanel
        $circuitStackPanel.Margin = "10"
        $modemStackPanel = New-Object System.Windows.Controls.StackPanel
        $modemStackPanel.Margin = "10"

        # Check if circuit is configured
        if ($Site.PrimaryCircuit.Vendor -or $Site.PrimaryCircuit.CircuitType -or $Site.PrimaryCircuit.IPAddress -or $Site.PrimaryCircuit.RouterName) {
            # Circuit fields (left column) - reordered as requested
            $primaryFields = @(
                @("Vendor:", $(if ($Site.PrimaryCircuit.Vendor) { $Site.PrimaryCircuit.Vendor } else { '(Not specified)' })),
                @("Circuit Type:", $(if ($Site.PrimaryCircuit.CircuitType) { $Site.PrimaryCircuit.CircuitType } else { '(Not specified)' }))
            )

            # Insert PPPoE fields after Circuit Type if it's GPON Fiber
            if ($Site.PrimaryCircuit.CircuitType -eq "GPON Fiber") {
                $primaryFields += @(
                    @("PPPoE Username:", $(if ($Site.PrimaryCircuit.PPPoEUsername) { $Site.PrimaryCircuit.PPPoEUsername } else { '(Not specified)' })),
                    @("PPPoE Password:", $(if ($Site.PrimaryCircuit.PPPoEPassword) { $Site.PrimaryCircuit.PPPoEPassword } else { '(Not specified)' }))
                )
            }
            
            # Add remaining fields in new order
            $primaryFields += @(
                @("IP Address:", $(if ($Site.PrimaryCircuit.IPAddress) { $Site.PrimaryCircuit.IPAddress } else { '(Not specified)' })),
                @("Subnet Mask:", $(if ($Site.PrimaryCircuit.SubnetMask) { $Site.PrimaryCircuit.SubnetMask } else { '(Not specified)' })),
                @("Default Gateway:", $(if ($Site.PrimaryCircuit.DefaultGateway) { $Site.PrimaryCircuit.DefaultGateway } else { '(Not specified)' })),
                @("DNS 1:", $(if ($Site.PrimaryCircuit.DNS1) { $Site.PrimaryCircuit.DNS1 } else { '(Not specified)' })),
                @("DNS 2:", $(if ($Site.PrimaryCircuit.DNS2) { $Site.PrimaryCircuit.DNS2 } else { '(Not specified)' })),
                @("Download Speed:", $(if ($Site.PrimaryCircuit.DownloadSpeed) { $Site.PrimaryCircuit.DownloadSpeed + " Mbps" } else { '(Not specified)' })),
                @("Upload Speed:", $(if ($Site.PrimaryCircuit.UploadSpeed) { $Site.PrimaryCircuit.UploadSpeed + " Mbps" } else { '(Not specified)' })),
                @("Router Name:", $(if ($Site.PrimaryCircuit.RouterName) { $Site.PrimaryCircuit.RouterName } else { '(Not specified)' })),
                @("Router Model:", $(if ($Site.PrimaryCircuit.RouterModel) { $Site.PrimaryCircuit.RouterModel } else { '(Not specified)' })),
                @("Router Serial:", $(if ($Site.PrimaryCircuit.RouterSN) { $Site.PrimaryCircuit.RouterSN } else { '(Not specified)' }))
            )

            # Add circuit fields to left column
            foreach ($field in $primaryFields) {
                $fieldGrid = New-Object System.Windows.Controls.Grid
                $fieldGrid.Margin = "5"
                
                $labelColumn = New-Object System.Windows.Controls.ColumnDefinition
                $labelColumn.Width = "150"
                $valueColumn = New-Object System.Windows.Controls.ColumnDefinition
                $valueColumn.Width = "*"
                
                $fieldGrid.ColumnDefinitions.Add($labelColumn)
                $fieldGrid.ColumnDefinitions.Add($valueColumn)
                
                $labelTextBlock = New-Object System.Windows.Controls.TextBlock
                $labelTextBlock.Text = $field[0]
                $labelTextBlock.VerticalAlignment = "Center"
                $labelTextBlock.FontWeight = "Bold"
                [System.Windows.Controls.Grid]::SetColumn($labelTextBlock, 0)
                
                $clickableText = New-ClickableText -Value $field[1]
                $clickableText.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($clickableText, 1)
                
                $fieldGrid.Children.Add($labelTextBlock)
                $fieldGrid.Children.Add($clickableText)
                
                $circuitStackPanel.Children.Add($fieldGrid)
            }
        } else {
            # No circuit configured - show status message
            $noCircuitGrid = New-Object System.Windows.Controls.Grid
            $noCircuitGrid.Margin = "5"
            $noCircuitLabelCol = New-Object System.Windows.Controls.ColumnDefinition
            $noCircuitLabelCol.Width = "150"
            $noCircuitValueCol = New-Object System.Windows.Controls.ColumnDefinition
            $noCircuitValueCol.Width = "*"
            $noCircuitGrid.ColumnDefinitions.Add($noCircuitLabelCol)
            $noCircuitGrid.ColumnDefinitions.Add($noCircuitValueCol)
            
            $noCircuitLabel = New-Object System.Windows.Controls.TextBlock
            $noCircuitLabel.Text = "Status:"
            $noCircuitLabel.FontWeight = "Bold"
            $noCircuitLabel.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($noCircuitLabel, 0)
            $noCircuitGrid.Children.Add($noCircuitLabel)
            
            $noCircuitValue = New-Object System.Windows.Controls.TextBlock
            $noCircuitValue.Text = "No circuit configured for this site"
            $noCircuitValue.FontStyle = "Italic"
            $noCircuitValue.Foreground = "Gray"
            $noCircuitValue.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($noCircuitValue, 1)
            $noCircuitGrid.Children.Add($noCircuitValue)
            
            $circuitStackPanel.Children.Add($noCircuitGrid)
        }

        # Check if modem is configured
        if ($Site.PrimaryCircuit.ModemName -or $Site.PrimaryCircuit.ModemModel -or $Site.PrimaryCircuit.ModemSN) {
            # Modem is configured - show individual fields in new order
            $modemFields = @(
                @("Modem Name:", $(if ($Site.PrimaryCircuit.ModemName) { $Site.PrimaryCircuit.ModemName } else { '(Not specified)' })),
                @("Modem Model:", $(if ($Site.PrimaryCircuit.ModemModel) { $Site.PrimaryCircuit.ModemModel } else { '(Not specified)' })),
                @("Modem Serial:", $(if ($Site.PrimaryCircuit.ModemSN) { $Site.PrimaryCircuit.ModemSN } else { '(Not specified)' }))
            )
            
            # Add modem fields to right column
            foreach ($field in $modemFields) {
                $fieldGrid = New-Object System.Windows.Controls.Grid
                $fieldGrid.Margin = "5"
                
                $labelColumn = New-Object System.Windows.Controls.ColumnDefinition
                $labelColumn.Width = "150"
                $valueColumn = New-Object System.Windows.Controls.ColumnDefinition
                $valueColumn.Width = "*"
                
                $fieldGrid.ColumnDefinitions.Add($labelColumn)
                $fieldGrid.ColumnDefinitions.Add($valueColumn)
                
                $labelTextBlock = New-Object System.Windows.Controls.TextBlock
                $labelTextBlock.Text = $field[0]
                $labelTextBlock.VerticalAlignment = "Center"
                $labelTextBlock.FontWeight = "Bold"
                [System.Windows.Controls.Grid]::SetColumn($labelTextBlock, 0)
                
                $clickableText = New-ClickableText -Value $field[1]
                $clickableText.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($clickableText, 1)
                
                $fieldGrid.Children.Add($labelTextBlock)
                $fieldGrid.Children.Add($clickableText)
                
                $modemStackPanel.Children.Add($fieldGrid)
            }
        } else {
            # No modem configured - show status message
            $noModemGrid = New-Object System.Windows.Controls.Grid
            $noModemGrid.Margin = "5"
            $noModemLabelCol = New-Object System.Windows.Controls.ColumnDefinition
            $noModemLabelCol.Width = "150"
            $noModemValueCol = New-Object System.Windows.Controls.ColumnDefinition
            $noModemValueCol.Width = "*"
            $noModemGrid.ColumnDefinitions.Add($noModemLabelCol)
            $noModemGrid.ColumnDefinitions.Add($noModemValueCol)
            
            $noModemLabel = New-Object System.Windows.Controls.TextBlock
            $noModemLabel.Text = "Status:"
            $noModemLabel.FontWeight = "Bold"
            $noModemLabel.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($noModemLabel, 0)
            $noModemGrid.Children.Add($noModemLabel)
            
            $noModemValue = New-Object System.Windows.Controls.TextBlock
            $noModemValue.Text = "No modem configured for this site"
            $noModemValue.FontStyle = "Italic"
            $noModemValue.Foreground = "Gray"
            $noModemValue.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($noModemValue, 1)
            $noModemGrid.Children.Add($noModemValue)
            
            $modemStackPanel.Children.Add($noModemGrid)
        }

        # Set Grid positions and add to main grid
        [System.Windows.Controls.Grid]::SetColumn($circuitStackPanel, 0)
        [System.Windows.Controls.Grid]::SetColumn($modemStackPanel, 1)
        [System.Windows.Controls.Grid]::SetRow($circuitStackPanel, 1)
        [System.Windows.Controls.Grid]::SetRow($modemStackPanel, 1)
        $primaryGrid.Children.Add($circuitStackPanel)
        $primaryGrid.Children.Add($modemStackPanel)

        $primaryTabItem.Content = $primaryGrid
        $tabControl.Items.Add($primaryTabItem)
                
        # === TAB 6: BACKUP CIRCUIT ===
        $backupTabItem = New-Object System.Windows.Controls.TabItem
        $backupTabItem.Header = "Backup Circuit"

        $backupGrid = New-Object System.Windows.Controls.Grid

        # Add column headers
        $headerRow = New-Object System.Windows.Controls.RowDefinition
        $headerRow.Height = "Auto"
        $contentRow = New-Object System.Windows.Controls.RowDefinition
        $contentRow.Height = "*"
        $backupGrid.RowDefinitions.Add($headerRow)
        $backupGrid.RowDefinitions.Add($contentRow)

        # Add two columns
        $column1 = New-Object System.Windows.Controls.ColumnDefinition
        $column1.Width = "50*"
        $column2 = New-Object System.Windows.Controls.ColumnDefinition  
        $column2.Width = "50*"
        $backupGrid.ColumnDefinitions.Add($column1)
        $backupGrid.ColumnDefinitions.Add($column2)

        # Circuit header (left)
        $circuitHeader = New-Object System.Windows.Controls.TextBlock
        $circuitHeader.Text = "Circuit"
        $circuitHeader.FontSize = 16
        $circuitHeader.FontWeight = "Bold"
        $circuitHeader.Margin = "10,5,10,5"
        $circuitHeader.HorizontalAlignment = "Left"
        [System.Windows.Controls.Grid]::SetColumn($circuitHeader, 0)
        [System.Windows.Controls.Grid]::SetRow($circuitHeader, 0)
        $backupGrid.Children.Add($circuitHeader)

        # Modem header (right)
        $modemHeader = New-Object System.Windows.Controls.TextBlock
        $modemHeader.Text = "Modem"
        $modemHeader.FontSize = 16
        $modemHeader.FontWeight = "Bold"
        $modemHeader.Margin = "10,5,10,5"
        $modemHeader.HorizontalAlignment = "Left"
        [System.Windows.Controls.Grid]::SetColumn($modemHeader, 1)
        [System.Windows.Controls.Grid]::SetRow($modemHeader, 0)
        $backupGrid.Children.Add($modemHeader)

        # Create StackPanels for each column
        $circuitStackPanel = New-Object System.Windows.Controls.StackPanel
        $circuitStackPanel.Margin = "10"
        $modemStackPanel = New-Object System.Windows.Controls.StackPanel
        $modemStackPanel.Margin = "10"

        # Check if circuit is configured
        if ($Site.BackupCircuit.Vendor -or $Site.BackupCircuit.CircuitType -or $Site.BackupCircuit.IPAddress -or $Site.BackupCircuit.RouterName) {
            # Circuit fields (left column) - reordered as requested
            $backupFields = @(
                @("Vendor:", $(if ($Site.BackupCircuit.Vendor) { $Site.BackupCircuit.Vendor } else { '(Not specified)' })),
                @("Circuit Type:", $(if ($Site.BackupCircuit.CircuitType) { $Site.BackupCircuit.CircuitType } else { '(Not specified)' }))
            )

            # Insert PPPoE fields after Circuit Type if it's GPON Fiber
            if ($Site.BackupCircuit.CircuitType -eq "GPON Fiber") {
                $backupFields += @(
                    @("PPPoE Username:", $(if ($Site.BackupCircuit.PPPoEUsername) { $Site.BackupCircuit.PPPoEUsername } else { '(Not specified)' })),
                    @("PPPoE Password:", $(if ($Site.BackupCircuit.PPPoEPassword) { $Site.BackupCircuit.PPPoEPassword } else { '(Not specified)' }))
                )
            }
            
            # Add remaining fields in new order
            $backupFields += @(
                @("IP Address:", $(if ($Site.BackupCircuit.IPAddress) { $Site.BackupCircuit.IPAddress } else { '(Not specified)' })),
                @("Subnet Mask:", $(if ($Site.BackupCircuit.SubnetMask) { $Site.BackupCircuit.SubnetMask } else { '(Not specified)' })),
                @("Default Gateway:", $(if ($Site.BackupCircuit.DefaultGateway) { $Site.BackupCircuit.DefaultGateway } else { '(Not specified)' })),
                @("DNS 1:", $(if ($Site.BackupCircuit.DNS1) { $Site.BackupCircuit.DNS1 } else { '(Not specified)' })),
                @("DNS 2:", $(if ($Site.BackupCircuit.DNS2) { $Site.BackupCircuit.DNS2 } else { '(Not specified)' })),
                @("Download Speed:", $(if ($Site.BackupCircuit.DownloadSpeed) { $Site.BackupCircuit.DownloadSpeed + " Mbps" } else { '(Not specified)' })),
                @("Upload Speed:", $(if ($Site.BackupCircuit.UploadSpeed) { $Site.BackupCircuit.UploadSpeed + " Mbps" } else { '(Not specified)' })),
                @("Router Name:", $(if ($Site.BackupCircuit.RouterName) { $Site.BackupCircuit.RouterName } else { '(Not specified)' })),
                @("Router Model:", $(if ($Site.BackupCircuit.RouterModel) { $Site.BackupCircuit.RouterModel } else { '(Not specified)' })),
                @("Router Serial:", $(if ($Site.BackupCircuit.RouterSN) { $Site.BackupCircuit.RouterSN } else { '(Not specified)' }))
            )

            # Add circuit fields to left column
            foreach ($field in $backupFields) {
                $fieldGrid = New-Object System.Windows.Controls.Grid
                $fieldGrid.Margin = "5"
                
                $labelColumn = New-Object System.Windows.Controls.ColumnDefinition
                $labelColumn.Width = "150"
                $valueColumn = New-Object System.Windows.Controls.ColumnDefinition
                $valueColumn.Width = "*"
                
                $fieldGrid.ColumnDefinitions.Add($labelColumn)
                $fieldGrid.ColumnDefinitions.Add($valueColumn)
                
                $labelTextBlock = New-Object System.Windows.Controls.TextBlock
                $labelTextBlock.Text = $field[0]
                $labelTextBlock.VerticalAlignment = "Center"
                $labelTextBlock.FontWeight = "Bold"
                [System.Windows.Controls.Grid]::SetColumn($labelTextBlock, 0)
                
                $clickableText = New-ClickableText -Value $field[1]
                $clickableText.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($clickableText, 1)
                
                $fieldGrid.Children.Add($labelTextBlock)
                $fieldGrid.Children.Add($clickableText)
                
                $backupStackPanel.Children.Add($fieldGrid)
            }
        } else {
            # No circuit configured - show status message
            $noCircuitGrid = New-Object System.Windows.Controls.Grid
            $noCircuitGrid.Margin = "5"
            $noCircuitLabelCol = New-Object System.Windows.Controls.ColumnDefinition
            $noCircuitLabelCol.Width = "150"
            $noCircuitValueCol = New-Object System.Windows.Controls.ColumnDefinition
            $noCircuitValueCol.Width = "*"
            $noCircuitGrid.ColumnDefinitions.Add($noCircuitLabelCol)
            $noCircuitGrid.ColumnDefinitions.Add($noCircuitValueCol)
            
            $noCircuitLabel = New-Object System.Windows.Controls.TextBlock
            $noCircuitLabel.Text = "Status:"
            $noCircuitLabel.FontWeight = "Bold"
            $noCircuitLabel.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($noCircuitLabel, 0)
            $noCircuitGrid.Children.Add($noCircuitLabel)
            
            $noCircuitValue = New-Object System.Windows.Controls.TextBlock
            $noCircuitValue.Text = "No circuit configured for this site"
            $noCircuitValue.FontStyle = "Italic"
            $noCircuitValue.Foreground = "Gray"
            $noCircuitValue.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($noCircuitValue, 1)
            $noCircuitGrid.Children.Add($noCircuitValue)
            
            $circuitStackPanel.Children.Add($noCircuitGrid)
        }

        # Check if modem is configured
        if ($Site.BackupCircuit.ModemName -or $Site.BackupCircuit.ModemModel -or $Site.BackupCircuit.ModemSN) {
            # Modem is configured - show individual fields in new order
            $modemFields = @(
                @("Modem Name:", $(if ($Site.BackupCircuit.ModemName) { $Site.BackupCircuit.ModemName } else { '(Not specified)' })),
                @("Modem Model:", $(if ($Site.BackupCircuit.ModemModel) { $Site.BackupCircuit.ModemModel } else { '(Not specified)' })),
                @("Modem Serial:", $(if ($Site.BackupCircuit.ModemSN) { $Site.BackupCircuit.ModemSN } else { '(Not specified)' }))
            )
            
            # Add modem fields to right column
            foreach ($field in $modemFields) {
                $fieldGrid = New-Object System.Windows.Controls.Grid
                $fieldGrid.Margin = "5"
                
                $labelColumn = New-Object System.Windows.Controls.ColumnDefinition
                $labelColumn.Width = "150"
                $valueColumn = New-Object System.Windows.Controls.ColumnDefinition
                $valueColumn.Width = "*"
                
                $fieldGrid.ColumnDefinitions.Add($labelColumn)
                $fieldGrid.ColumnDefinitions.Add($valueColumn)
                
                $labelTextBlock = New-Object System.Windows.Controls.TextBlock
                $labelTextBlock.Text = $field[0]
                $labelTextBlock.VerticalAlignment = "Center"
                $labelTextBlock.FontWeight = "Bold"
                [System.Windows.Controls.Grid]::SetColumn($labelTextBlock, 0)
                
                $clickableText = New-ClickableText -Value $field[1]
                $clickableText.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($clickableText, 1)
                
                $fieldGrid.Children.Add($labelTextBlock)
                $fieldGrid.Children.Add($clickableText)
                
                $modemStackPanel.Children.Add($fieldGrid)
            }
        } else {
            # No modem configured - show status message
            $noModemGrid = New-Object System.Windows.Controls.Grid
            $noModemGrid.Margin = "5"
            $noModemLabelCol = New-Object System.Windows.Controls.ColumnDefinition
            $noModemLabelCol.Width = "150"
            $noModemValueCol = New-Object System.Windows.Controls.ColumnDefinition
            $noModemValueCol.Width = "*"
            $noModemGrid.ColumnDefinitions.Add($noModemLabelCol)
            $noModemGrid.ColumnDefinitions.Add($noModemValueCol)
            
            $noModemLabel = New-Object System.Windows.Controls.TextBlock
            $noModemLabel.Text = "Status:"
            $noModemLabel.FontWeight = "Bold"
            $noModemLabel.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($noModemLabel, 0)
            $noModemGrid.Children.Add($noModemLabel)
            
            $noModemValue = New-Object System.Windows.Controls.TextBlock
            $noModemValue.Text = "No modem configured for this site"
            $noModemValue.FontStyle = "Italic"
            $noModemValue.Foreground = "Gray"
            $noModemValue.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($noModemValue, 1)
            $noModemGrid.Children.Add($noModemValue)
            
            $modemStackPanel.Children.Add($noModemGrid)
        }

        # Set Grid positions and add to main grid
        [System.Windows.Controls.Grid]::SetColumn($circuitStackPanel, 0)
        [System.Windows.Controls.Grid]::SetColumn($modemStackPanel, 1)
        [System.Windows.Controls.Grid]::SetRow($circuitStackPanel, 1)
        [System.Windows.Controls.Grid]::SetRow($modemStackPanel, 1)
        $backupGrid.Children.Add($circuitStackPanel)
        $backupGrid.Children.Add($modemStackPanel)

        $backupTabItem.Content = $backupGrid
        $tabControl.Items.Add($backupTabItem)
        
        # === TAB 7: VLANS ===
        $vlanTab = New-Object System.Windows.Controls.TabItem
        $vlanTab.Header = "VLANs"
        
        $vlanScrollViewer = New-Object System.Windows.Controls.ScrollViewer
        $vlanScrollViewer.VerticalScrollBarVisibility = "Auto"
        $vlanScrollViewer.HorizontalAlignment = "Stretch"
        $vlanScrollViewer.VerticalAlignment = "Stretch"
        
        $vlanFields = @(
            @("VLAN 100 - Servers:", $Site.VLANs.VLAN100_Servers),
            @("VLAN 101 - Network:", $Site.VLANs.VLAN101_NetworkDevices),
            @("VLAN 102 - User 1:", $Site.VLANs.VLAN102_UserDevices),
            @("VLAN 103 - User 2:", $Site.VLANs.VLAN103_UserDevices2),
            @("VLAN 104 - VOIP:", $Site.VLANs.VLAN104_VOIP),
            @("VLAN 105 - Wi-Fi Corp:", $Site.VLANs.VLAN105_WiFiCorp),
            @("VLAN 106 - Wi-Fi BYOD:", $Site.VLANs.VLAN106_WiFiBYOD),
            @("VLAN 107 - Wi-Fi Guest:", $Site.VLANs.VLAN107_WiFiGuest),
            @("VLAN 108 - Spare:", $Site.VLANs.VLAN108_Spare),
            @("VLAN 109 - DMZ:", $Site.VLANs.VLAN109_DMZ),
            @("VLAN 110 - CCTV:", $Site.VLANs.VLAN110_CCTV)
        )
        
        $hasVLANData = $vlanFields | Where-Object { -not [string]::IsNullOrWhiteSpace($_[1]) -and $_[1] -ne '(Not specified)' }
        
        if (-not $hasVLANData) {
            $emptyVLANText = New-Object System.Windows.Controls.TextBlock
            $emptyVLANText.Text = "No VLAN information configured for this site."
            $emptyVLANText.Margin = "15"
            $emptyVLANText.FontStyle = "Italic"
            $emptyVLANText.Foreground = "Gray"
            $vlanScrollViewer.Content = $emptyVLANText
        } else {
            $vlanStackPanel = New-Object System.Windows.Controls.StackPanel
            $vlanStackPanel.Margin = "15"
            $vlanStackPanel.Orientation = "Vertical"
            
            foreach ($field in $vlanFields) {
                $fieldGrid = New-Object System.Windows.Controls.Grid
                $fieldGrid.Margin = "0,3,0,3"
                
                $labelCol = New-Object System.Windows.Controls.ColumnDefinition
                $labelCol.Width = "180"
                $valueCol = New-Object System.Windows.Controls.ColumnDefinition
                $valueCol.Width = "*"
                $fieldGrid.ColumnDefinitions.Add($labelCol)
                $fieldGrid.ColumnDefinitions.Add($valueCol)
                
                $label = New-Object System.Windows.Controls.TextBlock
                $label.Text = $field[0]
                $label.FontWeight = "Bold"
                $label.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($label, 0)
                $fieldGrid.Children.Add($label)
                
                $clickableText = New-ClickableText -Value $field[1]
                $clickableText.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($clickableText, 1)
                $fieldGrid.Children.Add($clickableText)
                
                $vlanStackPanel.Children.Add($fieldGrid)
            }
            
            $vlanScrollViewer.Content = $vlanStackPanel
        }
        
        $vlanTab.Content = $vlanScrollViewer
        $tabControl.Items.Add($vlanTab)
        
        # === TAB 8: CCTV ===
        $cctvTab = New-Object System.Windows.Controls.TabItem
        $cctvTab.Header = "CCTV"

        $cctvScrollViewer = New-Object System.Windows.Controls.ScrollViewer
        $cctvScrollViewer.VerticalScrollBarVisibility = "Auto"
        $cctvScrollViewer.HorizontalAlignment = "Stretch"
        $cctvScrollViewer.VerticalAlignment = "Stretch"

        $cctvMainContainer = New-Object System.Windows.Controls.Grid
        $cctvMainContainer.Margin = "15"
        $cctvMainContainer.Name = "CCTVMainContainer"

        $script:BuildCCTVLayout = {
            param($containerWidth)
            
            $cctvMainContainer.Children.Clear()
            $cctvMainContainer.RowDefinitions.Clear()
            $cctvMainContainer.ColumnDefinitions.Clear()
            
            $columnCount = if ($containerWidth -ge 1200) { 4 } 
                        elseif ($containerWidth -ge 900) { 3 }
                        elseif ($containerWidth -ge 600) { 2 }
                        else { 1 }
            
            $devicesPerColumn = switch ($columnCount) {
                4 { 4 }
                3 { 4 }  
                2 { 6 }
                1 { 999 }
            }
            
            $headerRow = New-Object System.Windows.Controls.RowDefinition
            $headerRow.Height = "Auto"
            $contentRow = New-Object System.Windows.Controls.RowDefinition
            $contentRow.Height = "*"
            $cctvMainContainer.RowDefinitions.Add($headerRow)
            $cctvMainContainer.RowDefinitions.Add($contentRow)
            
            $columnWidth = [Math]::Floor(100 / $columnCount)
            for ($i = 0; $i -lt $columnCount; $i++) {
                $column = New-Object System.Windows.Controls.ColumnDefinition
                $column.Width = "${columnWidth}*"
                $cctvMainContainer.ColumnDefinitions.Add($column)
            }
            
            $validCCTV = @()
            if ($Site.CCTVDevices) {
                $validCCTV = @($Site.CCTVDevices | Where-Object {
                    (-not [string]::IsNullOrWhiteSpace($_.ManagementIP)) -or 
                    (-not [string]::IsNullOrWhiteSpace($_.Name)) -or 
                    (-not [string]::IsNullOrWhiteSpace($_.SerialNumber))
                })
            }
            
            $cctvCountGrid = New-Object System.Windows.Controls.Grid
            $cctvCountGrid.Margin = "0,0,0,15"
            $cctvCountLabelCol = New-Object System.Windows.Controls.ColumnDefinition
            $cctvCountLabelCol.Width = "180"
            $cctvCountValueCol = New-Object System.Windows.Controls.ColumnDefinition
            $cctvCountValueCol.Width = "*"
            $cctvCountGrid.ColumnDefinitions.Add($cctvCountLabelCol)
            $cctvCountGrid.ColumnDefinitions.Add($cctvCountValueCol)
            
            $cctvCountLabel = New-Object System.Windows.Controls.TextBlock
            $cctvCountLabel.Text = "Total CCTV Devices:"
            $cctvCountLabel.FontWeight = "Bold"
            $cctvCountLabel.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($cctvCountLabel, 0)
            $cctvCountGrid.Children.Add($cctvCountLabel)
            
            $cctvCountValue = New-Object System.Windows.Controls.TextBlock
            $cctvCountValue.Text = "$($validCCTV.Count) (${columnCount} columns)"
            $cctvCountValue.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($cctvCountValue, 1)
            $cctvCountGrid.Children.Add($cctvCountValue)
            
            [System.Windows.Controls.Grid]::SetRow($cctvCountGrid, 0)
            [System.Windows.Controls.Grid]::SetColumnSpan($cctvCountGrid, $columnCount)
            $cctvMainContainer.Children.Add($cctvCountGrid)
            
            if ($validCCTV.Count -eq 0) {
                $noCCTVGrid = New-Object System.Windows.Controls.Grid
                $noCCTVGrid.Margin = "0,3,0,3"
                $noCCTVLabelCol = New-Object System.Windows.Controls.ColumnDefinition
                $noCCTVLabelCol.Width = "180"
                $noCCTVValueCol = New-Object System.Windows.Controls.ColumnDefinition
                $noCCTVValueCol.Width = "*"
                $noCCTVGrid.ColumnDefinitions.Add($noCCTVLabelCol)
                $noCCTVGrid.ColumnDefinitions.Add($noCCTVValueCol)
                
                $noCCTVLabel = New-Object System.Windows.Controls.TextBlock
                $noCCTVLabel.Text = "Status:"
                $noCCTVLabel.FontWeight = "Bold"
                $noCCTVLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($noCCTVLabel, 0)
                $noCCTVGrid.Children.Add($noCCTVLabel)
                
                $noCCTVValue = New-Object System.Windows.Controls.TextBlock
                $noCCTVValue.Text = "No CCTV devices configured for this site"
                $noCCTVValue.FontStyle = "Italic"
                $noCCTVValue.Foreground = "Gray"
                $noCCTVValue.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($noCCTVValue, 1)
                $noCCTVGrid.Children.Add($noCCTVValue)
                
                [System.Windows.Controls.Grid]::SetRow($noCCTVGrid, 1)
                [System.Windows.Controls.Grid]::SetColumnSpan($noCCTVGrid, $columnCount)
                $cctvMainContainer.Children.Add($noCCTVGrid)
            } else {
                $columnStackPanels = @()
                for ($i = 0; $i -lt $columnCount; $i++) {
                    $stackPanel = New-Object System.Windows.Controls.StackPanel
                    $stackPanel.Margin = "5"
                    $stackPanel.Orientation = "Vertical"
                    $columnStackPanels += $stackPanel
                }
                
                for ($i = 0; $i -lt $validCCTV.Count; $i++) {
                    $device = $validCCTV[$i]
                    
                    $targetColumnIndex = [Math]::Floor($i / $devicesPerColumn)
                    if ($targetColumnIndex -ge $columnCount) { $targetColumnIndex = $columnCount - 1 }
                    $targetStackPanel = $columnStackPanels[$targetColumnIndex]
                    
                    $deviceHeaderGrid = New-Object System.Windows.Controls.Grid
                    $deviceHeaderGrid.Margin = "0,30,0,5"
                    $deviceHeaderLabelCol = New-Object System.Windows.Controls.ColumnDefinition
                    $labelWidth = if ($columnCount -eq 1) { "180" } else { "120" }
                    $deviceHeaderLabelCol.Width = $labelWidth
                    $deviceHeaderValueCol = New-Object System.Windows.Controls.ColumnDefinition
                    $deviceHeaderValueCol.Width = "*"
                    $deviceHeaderGrid.ColumnDefinitions.Add($deviceHeaderLabelCol)
                    $deviceHeaderGrid.ColumnDefinitions.Add($deviceHeaderValueCol)
                    
                    $deviceHeaderLabel = New-Object System.Windows.Controls.TextBlock
                    $deviceHeaderLabel.Text = "CCTV Device $($i + 1):"
                    $deviceHeaderLabel.FontWeight = "Bold"
                    $deviceHeaderLabel.FontSize = 14
                    $deviceHeaderLabel.VerticalAlignment = "Center"
                    [System.Windows.Controls.Grid]::SetColumn($deviceHeaderLabel, 0)
                    $deviceHeaderGrid.Children.Add($deviceHeaderLabel)
                    
                    $targetStackPanel.Children.Add($deviceHeaderGrid)
                    
                    $deviceFields = @(
                        @("Management IP:", $(if ($device.ManagementIP) { $device.ManagementIP } else { '(Not specified)' })),
                        @("Name:", $(if ($device.Name) { $device.Name } else { '(Not specified)' })),
                        @("Serial Number:", $(if ($device.SerialNumber) { $device.SerialNumber } else { '(Not specified)' }))
                    )
                    
                    foreach ($field in $deviceFields) {
                        $fieldGrid = New-Object System.Windows.Controls.Grid
                        $fieldGrid.Margin = "0,3,0,3"
                        
                        $labelCol = New-Object System.Windows.Controls.ColumnDefinition
                        $labelCol.Width = $labelWidth
                        $valueCol = New-Object System.Windows.Controls.ColumnDefinition
                        $valueCol.Width = "*"
                        $fieldGrid.ColumnDefinitions.Add($labelCol)
                        $fieldGrid.ColumnDefinitions.Add($valueCol)
                        
                        $label = New-Object System.Windows.Controls.TextBlock
                        $label.Text = $field[0]
                        $label.FontWeight = "Bold"
                        $label.VerticalAlignment = "Center"
                        [System.Windows.Controls.Grid]::SetColumn($label, 0)
                        $fieldGrid.Children.Add($label)
                        
                        $clickableText = New-ClickableText -Value $field[1]
                        $clickableText.VerticalAlignment = "Center"
                        $clickableText.TextWrapping = "Wrap"
                        [System.Windows.Controls.Grid]::SetColumn($clickableText, 1)
                        $fieldGrid.Children.Add($clickableText)
                        
                        $targetStackPanel.Children.Add($fieldGrid)
                    }
                }
                
                for ($i = 0; $i -lt $columnCount; $i++) {
                    [System.Windows.Controls.Grid]::SetRow($columnStackPanels[$i], 1)
                    [System.Windows.Controls.Grid]::SetColumn($columnStackPanels[$i], $i)
                    $cctvMainContainer.Children.Add($columnStackPanels[$i])
                }
            }
        }

        & $script:BuildCCTVLayout -containerWidth 1200

        if ($cctvScrollViewer.SizeChanged) {
            $cctvScrollViewer.SizeChanged.Add({
                $currentWidth = $cctvScrollViewer.ActualWidth - 30
                & $script:BuildCCTVLayout -containerWidth $currentWidth
            })
        }

        $cctvScrollViewer.Content = $cctvMainContainer
        $cctvTab.Content = $cctvScrollViewer
        $tabControl.Items.Add($cctvTab)

        # === TAB 9: UPS ===
        $upsTab = New-Object System.Windows.Controls.TabItem
        $upsTab.Header = "UPS"

        $upsScrollViewer = New-Object System.Windows.Controls.ScrollViewer
        $upsScrollViewer.VerticalScrollBarVisibility = "Auto"
        $upsScrollViewer.HorizontalAlignment = "Stretch"
        $upsScrollViewer.VerticalAlignment = "Stretch"

        $upsMainContainer = New-Object System.Windows.Controls.Grid
        $upsMainContainer.Margin = "15"
        $upsMainContainer.Name = "UPSMainContainer"

        $script:BuildUPSLayout = {
            param($containerWidth)
            
            $upsMainContainer.Children.Clear()
            $upsMainContainer.RowDefinitions.Clear()
            $upsMainContainer.ColumnDefinitions.Clear()
            
            $columnCount = 2
            
            $devicesPerColumn = 4
            
            $headerRow = New-Object System.Windows.Controls.RowDefinition
            $headerRow.Height = "Auto"
            $contentRow = New-Object System.Windows.Controls.RowDefinition
            $contentRow.Height = "*"
            $upsMainContainer.RowDefinitions.Add($headerRow)
            $upsMainContainer.RowDefinitions.Add($contentRow)
            
            $columnWidth = 50
            for ($i = 0; $i -lt $columnCount; $i++) {
                $column = New-Object System.Windows.Controls.ColumnDefinition
                $column.Width = "${columnWidth}*"
                $upsMainContainer.ColumnDefinitions.Add($column)
            }
            
            $validUPS = @()
            if ($Site.UPSDevices) {
                $validUPS = @($Site.UPSDevices | Where-Object {
                    (-not [string]::IsNullOrWhiteSpace($_.ManagementIP)) -or 
                    (-not [string]::IsNullOrWhiteSpace($_.Name))
                })
            }
            
            $upsCountGrid = New-Object System.Windows.Controls.Grid
            $upsCountGrid.Margin = "0,0,0,15"
            $upsCountLabelCol = New-Object System.Windows.Controls.ColumnDefinition
            $upsCountLabelCol.Width = "180"
            $upsCountValueCol = New-Object System.Windows.Controls.ColumnDefinition
            $upsCountValueCol.Width = "*"
            $upsCountGrid.ColumnDefinitions.Add($upsCountLabelCol)
            $upsCountGrid.ColumnDefinitions.Add($upsCountValueCol)
            
            $upsCountLabel = New-Object System.Windows.Controls.TextBlock
            $upsCountLabel.Text = "Total UPS Devices:"
            $upsCountLabel.FontWeight = "Bold"
            $upsCountLabel.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($upsCountLabel, 0)
            $upsCountGrid.Children.Add($upsCountLabel)
            
            $upsCountValue = New-Object System.Windows.Controls.TextBlock
            $upsCountValue.Text = "$($validUPS.Count) (2 columns)"
            $upsCountValue.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($upsCountValue, 1)
            $upsCountGrid.Children.Add($upsCountValue)
            
            [System.Windows.Controls.Grid]::SetRow($upsCountGrid, 0)
            [System.Windows.Controls.Grid]::SetColumnSpan($upsCountGrid, $columnCount)
            $upsMainContainer.Children.Add($upsCountGrid)
            
            if ($validUPS.Count -eq 0) {
                $noUPSGrid = New-Object System.Windows.Controls.Grid
                $noUPSGrid.Margin = "0,3,0,3"
                $noUPSLabelCol = New-Object System.Windows.Controls.ColumnDefinition
                $noUPSLabelCol.Width = "180"
                $noUPSValueCol = New-Object System.Windows.Controls.ColumnDefinition
                $noUPSValueCol.Width = "*"
                $noUPSGrid.ColumnDefinitions.Add($noUPSLabelCol)
                $noUPSGrid.ColumnDefinitions.Add($noUPSValueCol)
                
                $noUPSLabel = New-Object System.Windows.Controls.TextBlock
                $noUPSLabel.Text = "Status:"
                $noUPSLabel.FontWeight = "Bold"
                $noUPSLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($noUPSLabel, 0)
                $noUPSGrid.Children.Add($noUPSLabel)
                
                $noUPSValue = New-Object System.Windows.Controls.TextBlock
                $noUPSValue.Text = "No UPS devices configured for this site"
                $noUPSValue.FontStyle = "Italic"
                $noUPSValue.Foreground = "Gray"
                $noUPSValue.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($noUPSValue, 1)
                $noUPSGrid.Children.Add($noUPSValue)
                
                [System.Windows.Controls.Grid]::SetRow($noUPSGrid, 1)
                [System.Windows.Controls.Grid]::SetColumnSpan($noUPSGrid, $columnCount)
                $upsMainContainer.Children.Add($noUPSGrid)
            } else {
                $columnStackPanels = @()
                for ($i = 0; $i -lt $columnCount; $i++) {
                    $stackPanel = New-Object System.Windows.Controls.StackPanel
                    $stackPanel.Margin = "5"
                    $stackPanel.Orientation = "Vertical"
                    $columnStackPanels += $stackPanel
                }
                
                for ($i = 0; $i -lt $validUPS.Count; $i++) {
                    $device = $validUPS[$i]
                    
                    $targetColumnIndex = [Math]::Floor($i / $devicesPerColumn)
                    if ($targetColumnIndex -ge $columnCount) { $targetColumnIndex = $columnCount - 1 }
                    $targetStackPanel = $columnStackPanels[$targetColumnIndex]
                    
                    $deviceHeaderGrid = New-Object System.Windows.Controls.Grid
                    $deviceHeaderGrid.Margin = "0,30,0,5"
                    $deviceHeaderLabelCol = New-Object System.Windows.Controls.ColumnDefinition
                    $labelWidth = "140"
                    $deviceHeaderLabelCol.Width = $labelWidth
                    $deviceHeaderValueCol = New-Object System.Windows.Controls.ColumnDefinition
                    $deviceHeaderValueCol.Width = "*"
                    $deviceHeaderGrid.ColumnDefinitions.Add($deviceHeaderLabelCol)
                    $deviceHeaderGrid.ColumnDefinitions.Add($deviceHeaderValueCol)
                    
                    $deviceHeaderLabel = New-Object System.Windows.Controls.TextBlock
                    $deviceHeaderLabel.Text = "UPS Device $($i + 1):"
                    $deviceHeaderLabel.FontWeight = "Bold"
                    $deviceHeaderLabel.FontSize = 14
                    $deviceHeaderLabel.VerticalAlignment = "Center"
                    [System.Windows.Controls.Grid]::SetColumn($deviceHeaderLabel, 0)
                    $deviceHeaderGrid.Children.Add($deviceHeaderLabel)
                    
                    $targetStackPanel.Children.Add($deviceHeaderGrid)
                    
                    $deviceFields = @(
                        @("Management IP:", $(if ($device.ManagementIP) { $device.ManagementIP } else { '(Not specified)' })),
                        @("Name:", $(if ($device.Name) { $device.Name } else { '(Not specified)' }))
                    )
                    
                    foreach ($field in $deviceFields) {
                        $fieldGrid = New-Object System.Windows.Controls.Grid
                        $fieldGrid.Margin = "0,3,0,3"
                        
                        $labelCol = New-Object System.Windows.Controls.ColumnDefinition
                        $labelCol.Width = $labelWidth
                        $valueCol = New-Object System.Windows.Controls.ColumnDefinition
                        $valueCol.Width = "*"
                        $fieldGrid.ColumnDefinitions.Add($labelCol)
                        $fieldGrid.ColumnDefinitions.Add($valueCol)
                        
                        $label = New-Object System.Windows.Controls.TextBlock
                        $label.Text = $field[0]
                        $label.FontWeight = "Bold"
                        $label.VerticalAlignment = "Center"
                        [System.Windows.Controls.Grid]::SetColumn($label, 0)
                        $fieldGrid.Children.Add($label)
                        
                        $clickableText = New-ClickableText -Value $field[1]
                        $clickableText.VerticalAlignment = "Center"
                        $clickableText.TextWrapping = "Wrap"
                        [System.Windows.Controls.Grid]::SetColumn($clickableText, 1)
                        $fieldGrid.Children.Add($clickableText)
                        
                        $targetStackPanel.Children.Add($fieldGrid)
                    }
                }
                
                for ($i = 0; $i -lt $columnCount; $i++) {
                    [System.Windows.Controls.Grid]::SetRow($columnStackPanels[$i], 1)
                    [System.Windows.Controls.Grid]::SetColumn($columnStackPanels[$i], $i)
                    $upsMainContainer.Children.Add($columnStackPanels[$i])
                }
            }
        }

        & $script:BuildUPSLayout -containerWidth 1200

        if ($upsScrollViewer.SizeChanged) {
            $upsScrollViewer.SizeChanged.Add({
                $currentWidth = $upsScrollViewer.ActualWidth - 30
                & $script:BuildUPSLayout -containerWidth $currentWidth
            })
        }

        $upsScrollViewer.Content = $upsMainContainer
        $upsTab.Content = $upsScrollViewer
        $tabControl.Items.Add($upsTab)

        # === TAB 10: PRINTER ===
        $printerTab = New-Object System.Windows.Controls.TabItem
        $printerTab.Header = "Printer"

        $printerScrollViewer = New-Object System.Windows.Controls.ScrollViewer
        $printerScrollViewer.VerticalScrollBarVisibility = "Auto"
        $printerScrollViewer.HorizontalAlignment = "Stretch"
        $printerScrollViewer.VerticalAlignment = "Stretch"

        $printerMainContainer = New-Object System.Windows.Controls.Grid
        $printerMainContainer.Margin = "15"
        $printerMainContainer.Name = "PrinterMainContainer"

        $script:BuildPrinterLayout = {
            param($containerWidth)
            
            $printerMainContainer.Children.Clear()
            $printerMainContainer.RowDefinitions.Clear()
            $printerMainContainer.ColumnDefinitions.Clear()
            
            $columnCount = 2  # Fixed to 2 columns for Printers
            $devicesPerColumn = 3  # Fixed to 3 devices per column
            
            $headerRow = New-Object System.Windows.Controls.RowDefinition
            $headerRow.Height = "Auto"
            $contentRow = New-Object System.Windows.Controls.RowDefinition
            $contentRow.Height = "*"
            $printerMainContainer.RowDefinitions.Add($headerRow)
            $printerMainContainer.RowDefinitions.Add($contentRow)
            
            $columnWidth = 50  # 50% width for each of the 2 columns
            for ($i = 0; $i -lt $columnCount; $i++) {
                $column = New-Object System.Windows.Controls.ColumnDefinition
                $column.Width = "${columnWidth}*"
                $printerMainContainer.ColumnDefinitions.Add($column)
            }
            
            $validPrinters = @()
            if ($Site.PrinterDevices) {
                $validPrinters = @($Site.PrinterDevices | Where-Object {
                    (-not [string]::IsNullOrWhiteSpace($_.ManagementIP)) -or 
                    (-not [string]::IsNullOrWhiteSpace($_.Name)) -or 
                    (-not [string]::IsNullOrWhiteSpace($_.Model)) -or
                    (-not [string]::IsNullOrWhiteSpace($_.SerialNumber))
                })
            }
            
            $printerCountGrid = New-Object System.Windows.Controls.Grid
            $printerCountGrid.Margin = "0,0,0,15"
            $printerCountLabelCol = New-Object System.Windows.Controls.ColumnDefinition
            $printerCountLabelCol.Width = "180"
            $printerCountValueCol = New-Object System.Windows.Controls.ColumnDefinition
            $printerCountValueCol.Width = "*"
            $printerCountGrid.ColumnDefinitions.Add($printerCountLabelCol)
            $printerCountGrid.ColumnDefinitions.Add($printerCountValueCol)
            
            $printerCountLabel = New-Object System.Windows.Controls.TextBlock
            $printerCountLabel.Text = "Total Printers:"
            $printerCountLabel.FontWeight = "Bold"
            $printerCountLabel.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($printerCountLabel, 0)
            $printerCountGrid.Children.Add($printerCountLabel)
            
            $printerCountValue = New-Object System.Windows.Controls.TextBlock
            $printerCountValue.Text = "$($validPrinters.Count) (2 columns)"
            $printerCountValue.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($printerCountValue, 1)
            $printerCountGrid.Children.Add($printerCountValue)
            
            [System.Windows.Controls.Grid]::SetRow($printerCountGrid, 0)
            [System.Windows.Controls.Grid]::SetColumnSpan($printerCountGrid, $columnCount)
            $printerMainContainer.Children.Add($printerCountGrid)
            
            if ($validPrinters.Count -eq 0) {
                $noPrinterGrid = New-Object System.Windows.Controls.Grid
                $noPrinterGrid.Margin = "0,3,0,3"
                $noPrinterLabelCol = New-Object System.Windows.Controls.ColumnDefinition
                $noPrinterLabelCol.Width = "180"
                $noPrinterValueCol = New-Object System.Windows.Controls.ColumnDefinition
                $noPrinterValueCol.Width = "*"
                $noPrinterGrid.ColumnDefinitions.Add($noPrinterLabelCol)
                $noPrinterGrid.ColumnDefinitions.Add($noPrinterValueCol)
                
                $noPrinterLabel = New-Object System.Windows.Controls.TextBlock
                $noPrinterLabel.Text = "Status:"
                $noPrinterLabel.FontWeight = "Bold"
                $noPrinterLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($noPrinterLabel, 0)
                $noPrinterGrid.Children.Add($noPrinterLabel)
                
                $noPrinterValue = New-Object System.Windows.Controls.TextBlock
                $noPrinterValue.Text = "No printers configured for this site"
                $noPrinterValue.FontStyle = "Italic"
                $noPrinterValue.Foreground = "Gray"
                $noPrinterValue.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($noPrinterValue, 1)
                $noPrinterGrid.Children.Add($noPrinterValue)
                
                [System.Windows.Controls.Grid]::SetRow($noPrinterGrid, 1)
                [System.Windows.Controls.Grid]::SetColumnSpan($noPrinterGrid, $columnCount)
                $printerMainContainer.Children.Add($noPrinterGrid)
            } else {
                $columnStackPanels = @()
                for ($i = 0; $i -lt $columnCount; $i++) {
                    $stackPanel = New-Object System.Windows.Controls.StackPanel
                    $stackPanel.Margin = "5"
                    $stackPanel.Orientation = "Vertical"
                    $columnStackPanels += $stackPanel
                }
                
                for ($i = 0; $i -lt $validPrinters.Count; $i++) {
                    $device = $validPrinters[$i]
                    
                    $targetColumnIndex = [Math]::Floor($i / $devicesPerColumn)
                    if ($targetColumnIndex -ge $columnCount) { $targetColumnIndex = $columnCount - 1 }
                    $targetStackPanel = $columnStackPanels[$targetColumnIndex]
                    
                    $deviceHeaderGrid = New-Object System.Windows.Controls.Grid
                    $deviceHeaderGrid.Margin = "0,30,0,5"
                    $deviceHeaderLabelCol = New-Object System.Windows.Controls.ColumnDefinition
                    $labelWidth = "180"  # Wider labels for 2-column layout
                    $deviceHeaderLabelCol.Width = $labelWidth
                    $deviceHeaderValueCol = New-Object System.Windows.Controls.ColumnDefinition
                    $deviceHeaderValueCol.Width = "*"
                    $deviceHeaderGrid.ColumnDefinitions.Add($deviceHeaderLabelCol)
                    $deviceHeaderGrid.ColumnDefinitions.Add($deviceHeaderValueCol)
                    
                    $deviceHeaderLabel = New-Object System.Windows.Controls.TextBlock
                    $deviceHeaderLabel.Text = "Printer $($i + 1):"
                    $deviceHeaderLabel.FontWeight = "Bold"
                    $deviceHeaderLabel.FontSize = 14
                    $deviceHeaderLabel.VerticalAlignment = "Center"
                    [System.Windows.Controls.Grid]::SetColumn($deviceHeaderLabel, 0)
                    $deviceHeaderGrid.Children.Add($deviceHeaderLabel)
                    
                    $targetStackPanel.Children.Add($deviceHeaderGrid)
                    
                    $deviceFields = @(
                        @("Management IP:", $(if ($device.ManagementIP) { $device.ManagementIP } else { '(Not specified)' })),
                        @("Name:", $(if ($device.Name) { $device.Name } else { '(Not specified)' })),
                        @("Model:", $(if ($device.Model) { $device.Model } else { '(Not specified)' })),
                        @("Serial Number:", $(if ($device.SerialNumber) { $device.SerialNumber } else { '(Not specified)' }))
                    )
                    
                    foreach ($field in $deviceFields) {
                        $fieldGrid = New-Object System.Windows.Controls.Grid
                        $fieldGrid.Margin = "0,3,0,3"
                        
                        $labelCol = New-Object System.Windows.Controls.ColumnDefinition
                        $labelCol.Width = $labelWidth
                        $valueCol = New-Object System.Windows.Controls.ColumnDefinition
                        $valueCol.Width = "*"
                        $fieldGrid.ColumnDefinitions.Add($labelCol)
                        $fieldGrid.ColumnDefinitions.Add($valueCol)
                        
                        $label = New-Object System.Windows.Controls.TextBlock
                        $label.Text = $field[0]
                        $label.FontWeight = "Bold"
                        $label.VerticalAlignment = "Center"
                        [System.Windows.Controls.Grid]::SetColumn($label, 0)
                        $fieldGrid.Children.Add($label)
                        
                        $clickableText = New-ClickableText -Value $field[1]
                        $clickableText.VerticalAlignment = "Center"
                        $clickableText.TextWrapping = "Wrap"
                        [System.Windows.Controls.Grid]::SetColumn($clickableText, 1)
                        $fieldGrid.Children.Add($clickableText)
                        
                        $targetStackPanel.Children.Add($fieldGrid)
                    }
                }
                
                for ($i = 0; $i -lt $columnCount; $i++) {
                    [System.Windows.Controls.Grid]::SetRow($columnStackPanels[$i], 1)
                    [System.Windows.Controls.Grid]::SetColumn($columnStackPanels[$i], $i)
                    $printerMainContainer.Children.Add($columnStackPanels[$i])
                }
            }
        }

        & $script:BuildPrinterLayout -containerWidth 1200

        if ($printerScrollViewer.SizeChanged) {
            $printerScrollViewer.SizeChanged.Add({
                $currentWidth = $printerScrollViewer.ActualWidth - 30
                & $script:BuildPrinterLayout -containerWidth $currentWidth
            })
        }

        $printerScrollViewer.Content = $printerMainContainer
        $printerTab.Content = $printerScrollViewer
        $tabControl.Items.Add($printerTab)
        
        # Add the TabControl to the main grid
        $mainGrid.Children.Add($tabControl)
        
        # Add the main grid to the stack panel
        $stkSiteDetails.Children.Add($mainGrid)
        
        # Force the container to update its layout
        $stkSiteDetails.UpdateLayout()
        
        # Make sure the results group is visible and properly sized
        $grpSiteLookupResults.Visibility = "Visible"
        $grpSiteLookupResults.HorizontalAlignment = "Stretch"
        $grpSiteLookupResults.VerticalAlignment = "Stretch"
        
        # Force the group to update its layout
        $grpSiteLookupResults.UpdateLayout()
        
        Write-Host "DEBUG: TabControl created with $($tabControl.Items.Count) tabs"
        Write-Host "DEBUG: stkSiteDetails now has $($stkSiteDetails.Children.Count) children"
        
    } catch {
        Write-Host "ERROR in Show-SiteDetails: $_"
        Write-Host "ERROR StackTrace: $($_.Exception.StackTrace)"
        [System.Windows.MessageBox]::Show("Error displaying site details: $_", "Display Error", "OK", "Error")
    }
}

# ===================================================================
# EVENT HANDLER FUNCTIONS
# ===================================================================

# Generic device count change handler for all device types
function Handle-DeviceCountChanged {
    param(
        [string]$DeviceType,
        [System.Windows.Controls.ComboBox]$ComboBox
    )
    
    if ($ComboBox.SelectedItem) {
        $count = [int]$ComboBox.SelectedItem.Content
        $script:DeviceManager.UpdateDevicePanels($DeviceType, $count)
        Write-Host "DEBUG: About to update panels for DeviceType: '$DeviceType', count: $count"
        
        # Auto-populate names and IPs if site code/subnet exists
        if (-not [string]::IsNullOrWhiteSpace($txtSiteCode.Text)) {
            $script:DeviceManager.UpdateDeviceNamesFromSiteCode($DeviceType, $txtSiteCode.Text)
        }
        if (-not [string]::IsNullOrWhiteSpace($txtSiteSubnet.Text)) {
            if ($txtSiteSubnet.Text -match '^(\d+\.\d+)\.') {
                $script:DeviceManager.UpdateDeviceIPsFromSubnet($DeviceType, $matches[1])
            }
        }
    }
}

# ===================================================================
# XAML LOADING AND UI INITIALIZATION
# ===================================================================

# When dot-sourced from Main.ps1, we need to get the actual Site.ps1 directory
$scriptPath = $PSScriptRoot
if (-not $scriptPath) {
    # Fallback: assume we're in Site Network Identifier folder
    $scriptPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "Site Network Identifier"
}

# Validate XAML file exists and is readable
if (-not (Test-Path $xamlFile)) {
    [System.Windows.MessageBox]::Show("XAML file not found: $xamlFile", "File Error", "OK", "Error")
    exit
}

# Load and parse XAML
try {
    $xaml = Get-Content $xamlFile -Raw
    $xml = [xml]$xaml
}
catch {
    [System.Windows.MessageBox]::Show("Error loading XAML: $_", "XAML Error", "OK", "Error")
    exit
}

# Read XAML and create GUI elements
try {
    # Create the window first without loading XAML content
    $reader = New-Object System.Xml.XmlNodeReader $xml
    
    # Add the phone formatter resource BEFORE loading XAML
    $phoneConverter = [PhoneNumberConverter]::new()
    
    # Create a resource dictionary and add our converter
    $resourceDict = New-Object System.Windows.ResourceDictionary
    $resourceDict.Add("PhoneFormatter", $phoneConverter)
    
    # Load the window with resources
    $mainWin = [Windows.Markup.XamlReader]::Load($reader)
    $mainWin.Resources = $resourceDict
}
catch {
    [System.Windows.MessageBox]::Show("Error creating window: $_", "Window Creation Error", "OK", "Error")
    exit
}

# ===================================================================
# UI CONTROL REFERENCES
# ===================================================================

# Get GUI elements by Name - Basic Info
$txtSiteCode = $mainWin.FindName("txtSiteCode")
$txtSiteSubnetCode = $mainWin.FindName("txtSiteSubnetCode")
$txtSiteSubnet = $mainWin.FindName("txtSiteSubnet")
$txtSiteName = $mainWin.FindName("txtSiteNameManage")
$txtSiteAddress = $mainWin.FindName("txtSiteAddress")
$txtMainContactName = $mainWin.FindName("txtMainContactName")
$txtMainContactPhone = $mainWin.FindName("txtMainContactPhone")
$txtSecondContactName = $mainWin.FindName("txtSecondContactName")
$txtSecondContactPhone = $mainWin.FindName("txtSecondContactPhone")

# Network Equipment
$cmbSwitchCount = $mainWin.FindName("cmbSwitchCount")
$stkSwitches = $mainWin.FindName("stkSwitches")
$txtFirewallIP = $mainWin.FindName("txtFirewallIP")
$txtFirewallName = $mainWin.FindName("txtFirewallName")
$txtFirewallVersion = $mainWin.FindName("txtFirewallVersion")
$txtFirewallSN = $mainWin.FindName("txtFirewallSN")

# Primary Circuit
$txtPrimaryVendor = $mainWin.FindName("txtPrimaryVendor")
$cmbPrimaryCircuitType = $mainWin.FindName("cmbPrimaryCircuitType")
$txtPrimaryCircuitID = $mainWin.FindName("txtPrimaryCircuitID")
$txtPrimaryDownloadSpeed = $mainWin.FindName("txtPrimaryDownloadSpeed")
$txtPrimaryUploadSpeed = $mainWin.FindName("txtPrimaryUploadSpeed")
$txtPrimaryIPAddress = $mainWin.FindName("txtPrimaryIPAddress")
$txtPrimarySubnetMask = $mainWin.FindName("txtPrimarySubnetMask")
$txtPrimaryDefaultGateway = $mainWin.FindName("txtPrimaryDefaultGateway")
$txtPrimaryDNS1 = $mainWin.FindName("txtPrimaryDNS1")
$txtPrimaryDNS2 = $mainWin.FindName("txtPrimaryDNS2")
$txtPrimaryRouterModel = $mainWin.FindName("txtPrimaryRouterModel")
$txtPrimaryRouterName = $mainWin.FindName("txtPrimaryRouterName")
$txtPrimaryRouterSN = $mainWin.FindName("txtPrimaryRouterSN")
$txtPrimaryPPPoEUsername = $mainWin.FindName("txtPrimaryPPPoEUsername")
$txtPrimaryPPPoEPassword = $mainWin.FindName("txtPrimaryPPPoEPassword")
$chkPrimaryHasModem = $mainWin.FindName("chkPrimaryHasModem")
$stkPrimaryModem = $mainWin.FindName("stkPrimaryModem")
$txtPrimaryModemModel = $mainWin.FindName("txtPrimaryModemModel")
$txtPrimaryModemName = $mainWin.FindName("txtPrimaryModemName")
$txtPrimaryModemSN = $mainWin.FindName("txtPrimaryModemSN")

# Backup Circuit
$chkHasBackupCircuit = $mainWin.FindName("chkHasBackupCircuit")
$grdBackupCircuit = $mainWin.FindName("grdBackupCircuit")
$txtBackupVendor = $mainWin.FindName("txtBackupVendor")
$cmbBackupCircuitType = $mainWin.FindName("cmbBackupCircuitType")
$txtBackupCircuitID = $mainWin.FindName("txtBackupCircuitID")
$txtBackupDownloadSpeed = $mainWin.FindName("txtBackupDownloadSpeed")
$txtBackupUploadSpeed = $mainWin.FindName("txtBackupUploadSpeed")
$txtBackupIPAddress = $mainWin.FindName("txtBackupIPAddress")
$txtBackupSubnetMask = $mainWin.FindName("txtBackupSubnetMask")
$txtBackupDefaultGateway = $mainWin.FindName("txtBackupDefaultGateway")
$txtBackupDNS1 = $mainWin.FindName("txtBackupDNS1")
$txtBackupDNS2 = $mainWin.FindName("txtBackupDNS2")
$txtBackupRouterModel = $mainWin.FindName("txtBackupRouterModel")
$txtBackupRouterName = $mainWin.FindName("txtBackupRouterName")
$txtBackupRouterSN = $mainWin.FindName("txtBackupRouterSN")
$txtBackupPPPoEUsername = $mainWin.FindName("txtBackupPPPoEUsername")
$txtBackupPPPoEPassword = $mainWin.FindName("txtBackupPPPoEPassword")
$chkBackupHasModem = $mainWin.FindName("chkBackupHasModem")
$stkBackupModem = $mainWin.FindName("stkBackupModem")
$txtBackupModemModel = $mainWin.FindName("txtBackupModemModel")
$txtBackupModemName = $mainWin.FindName("txtBackupModemName")
$txtBackupModemSN = $mainWin.FindName("txtBackupModemSN")

# VLANs
$txtVlan100 = $mainWin.FindName("txtVlan100")
$txtVlan101 = $mainWin.FindName("txtVlan101")
$txtVlan102 = $mainWin.FindName("txtVlan102")
$txtVlan103 = $mainWin.FindName("txtVlan103")
$txtVlan104 = $mainWin.FindName("txtVlan104")
$txtVlan105 = $mainWin.FindName("txtVlan105")
$txtVlan106 = $mainWin.FindName("txtVlan106")
$txtVlan107 = $mainWin.FindName("txtVlan107")
$txtVlan108 = $mainWin.FindName("txtVlan108")
$txtVlan109 = $mainWin.FindName("txtVlan109")
$txtVlan110 = $mainWin.FindName("txtVlan110")

# Access Points
$cmbAPCount = $mainWin.FindName("cmbAPCount")
$stkAccessPoints = $mainWin.FindName("stkAccessPoints")

# UPS
$cmbUPSCount = $mainWin.FindName("cmbUPSCount")
$stkUPS = $mainWin.FindName("stkUPS")

# CCTV
$cmbCCTVCount = $mainWin.FindName("cmbCCTVCount")
$stkCCTV = $mainWin.FindName("stkCCTV")

# Printer
$cmbPrinterCount = $mainWin.FindName("cmbPrinterCount")
$stkPrinter = $mainWin.FindName("stkPrinter")

# Buttons and Controls
$btnAddSite = $mainWin.FindName("btnAddSite")
$btnClearForm = $mainWin.FindName("btnClearForm")
$btnEditSite = $mainWin.FindName("btnEditSite")
$btnDeleteSite = $mainWin.FindName("btnDeleteSite")
$dgSites = $mainWin.FindName("dgSites")
$txtSearchSites = $mainWin.FindName("txtSearchSites")
$btnClearSearchSites = $mainWin.FindName("btnClearSearchSites")
$txtBlkSiteStatus = $mainWin.FindName("txtBlkSiteStatus")

# Lookup Controls
$txtSiteLookup = $mainWin.FindName("txtSiteLookup")
$btnLookupSite = $mainWin.FindName("btnLookupSite")
$grpSiteLookupResults = $mainWin.FindName("grpSiteLookupResults")
$stkSiteDetails = $mainWin.FindName("stkSiteDetails")

# Import/Export Controls
$txtSiteCsvFilePath = $mainWin.FindName("txtSiteCsvFilePath")
$btnBrowseSiteCsv = $mainWin.FindName("btnBrowseSiteCsv")
$btnImportSiteCsv = $mainWin.FindName("btnImportSiteCsv")
$btnExportSiteCsv = $mainWin.FindName("btnExportSiteCsv")
$txtBlkSiteImportStatus = $mainWin.FindName("txtBlkSiteImportStatus")
$pnlSiteImportProgress = $mainWin.FindName("pnlSiteImportProgress")
$pbSiteImportProgress = $mainWin.FindName("pbSiteImportProgress")
$txtSiteProgressStatus = $mainWin.FindName("txtSiteProgressStatus")
$txtSiteProgressDetails = $mainWin.FindName("txtSiteProgressDetails")

# Tab Controls
$MainTabControl = $mainWin.FindName("MainTabControl")
$SiteNavTabControl = $mainWin.FindName("SiteNavTabControl")

# Status Bar
$SiteStatusBar = $mainWin.FindName("SiteStatusBar")
$txtStatusBarSites = $mainWin.FindName("txtStatusBarSites")
$txtStatusBarSiteSelected = $mainWin.FindName("txtStatusBarSiteSelected")

# Search debouncing timer
$script:SearchTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:SearchTimer.Interval = [TimeSpan]::FromMilliseconds(300)
$script:SearchTimer.Add_Tick({
    Update-DataGridWithSearch
    $script:SearchTimer.Stop()
})

# ===================================================================
# IP NETWORK IDENTIFIER CONTROL REFERENCES
# ===================================================================

# IP Network Identifier Controls - with null checks
$txtIpSubnet = $mainWin.FindName("txtIpSubnet")
$txtVlanId = $mainWin.FindName("txtVlanId")
$txtVlanName = $mainWin.FindName("txtVlanName")
$txtSiteName = $mainWin.FindName("txtSiteName")
$btnAddEntry = $mainWin.FindName("btnAddEntry")
$txtIpLookup = $mainWin.FindName("txtIpLookup")
$btnLookup = $mainWin.FindName("btnLookup")
$txtBlkMatchedSubnet = $mainWin.FindName("txtBlkMatchedSubnet")
$txtBlkVlanId = $mainWin.FindName("txtBlkVlanId")
$txtBlkVlanName = $mainWin.FindName("txtBlkVlanName")
$txtBlkSiteName = $mainWin.FindName("txtBlkSiteName")
$grpLookupResults = $mainWin.FindName("grpLookupResults")
$IPNavTabControl = $mainWin.FindName("IPNavTabControl")
$dgSubnets = $mainWin.FindName("dgSubnets")
$btnDeleteEntry = $mainWin.FindName("btnDeleteEntry")
$txtCsvFilePath = $mainWin.FindName("txtCsvFilePath")
$btnBrowseCsv = $mainWin.FindName("btnBrowseCsv")
$btnImportCsv = $mainWin.FindName("btnImportCsv")
$btnExportCsv = $mainWin.FindName("btnExportCsv")
$txtBlkImportStatus = $mainWin.FindName("txtBlkImportStatus")
$txtBlkSearchedIp = $mainWin.FindName("txtBlkSearchedIp")
$txtSearch = $mainWin.FindName("txtSearch")
$btnClearSearch = $mainWin.FindName("btnClearSearch")
$txtStatusBarSubnets = $mainWin.FindName("txtStatusBarSubnets")
$txtStatusBarSelected = $mainWin.FindName("txtStatusBarSelected")
$pbImportProgress = $mainWin.FindName("pbImportProgress")
$txtProgressStatus = $mainWin.FindName("txtProgressStatus")
$txtProgressDetails = $mainWin.FindName("txtProgressDetails")
$pnlImportProgress = $mainWin.FindName("pnlImportProgress")
$MainStatusBar = $mainWin.FindName("MainStatusBar")

# Initialize the global device panel manager (will be created after UI loads)
$script:DeviceManager = $null

# Initialize the global field mapping manager (will be created after UI loads)
$script:FieldManager = $null

# ===================================================================
# EVENT HANDLERS SETUP
# ===================================================================

# Switch count selection changed - using centralized manager
$cmbSwitchCount.Add_SelectionChanged({ Handle-DeviceCountChanged 'Switch' $cmbSwitchCount })
$cmbAPCount.Add_SelectionChanged({ Handle-DeviceCountChanged 'AccessPoint' $cmbAPCount })
$cmbUPSCount.Add_SelectionChanged({ Handle-DeviceCountChanged 'UPS' $cmbUPSCount })
$cmbCCTVCount.Add_SelectionChanged({ Handle-DeviceCountChanged 'CCTV' $cmbCCTVCount })
$cmbPrinterCount.Add_SelectionChanged({ Handle-DeviceCountChanged 'Printer' $cmbPrinterCount })

# Backup circuit checkbox
$chkHasBackupCircuit.Add_Checked({
    if ($grdBackupCircuit) {
        $grdBackupCircuit.Visibility = "Visible"
    }
})

$chkHasBackupCircuit.Add_Unchecked({
    if ($grdBackupCircuit) {
        $grdBackupCircuit.Visibility = "Collapsed"
    }
})

# Primary modem checkbox
$chkPrimaryHasModem.Add_Checked({
    if ($stkPrimaryModem) {
        $stkPrimaryModem.Visibility = "Visible"
    }
})

$chkPrimaryHasModem.Add_Unchecked({
    if ($stkPrimaryModem) {
        $stkPrimaryModem.Visibility = "Collapsed"
    }
})

# Backup modem checkbox
$chkBackupHasModem.Add_Checked({
    if ($stkBackupModem) {
        $stkBackupModem.Visibility = "Visible"
    }
})

$chkBackupHasModem.Add_Unchecked({
    if ($stkBackupModem) {
        $stkBackupModem.Visibility = "Collapsed"
    }
})

# Site Subnet auto-population using centralized function
$txtSiteSubnet.Add_TextChanged({
    $vlanControls = @{
        VLAN100 = $txtVlan100
        VLAN101 = $txtVlan101
        VLAN102 = $txtVlan102
        VLAN103 = $txtVlan103
        VLAN104 = $txtVlan104
        VLAN105 = $txtVlan105
        VLAN106 = $txtVlan106
        VLAN107 = $txtVlan107
        VLAN108 = $txtVlan108
        VLAN109 = $txtVlan109
        VLAN110 = $txtVlan110
    }
    Update-VLANsAndIPsFromSubnet -SubnetInput $txtSiteSubnet.Text -VLANControls $vlanControls -DeviceManager $script:DeviceManager -FirewallIPControl $txtFirewallIP -SiteSubnetCodeControl $txtSiteSubnetCode
})

# Site Code auto-population using centralized function
$txtSiteCode.Add_TextChanged({
    Update-DeviceNamesFromSiteCode -SiteCode $txtSiteCode.Text -DeviceManager $script:DeviceManager -FirewallNameControl $txtFirewallName
})

# Primary circuit type selection changed
$cmbPrimaryCircuitType.Add_SelectionChanged({
    $stkPrimaryGPONElement = $mainWin.FindName("stkPrimaryGPON")
    if ($stkPrimaryGPONElement) {
        if ($cmbPrimaryCircuitType.SelectedItem -and $cmbPrimaryCircuitType.SelectedItem.Content -eq "GPON Fiber") {
            $stkPrimaryGPONElement.Visibility = "Visible"
        } else {
            $stkPrimaryGPONElement.Visibility = "Collapsed"
        }
    }
})

# Backup circuit type selection changed
$cmbBackupCircuitType.Add_SelectionChanged({
    $stkBackupGPONElement = $mainWin.FindName("stkBackupGPON")
    if ($stkBackupGPONElement) {
        if ($cmbBackupCircuitType.SelectedItem -and $cmbBackupCircuitType.SelectedItem.Content -eq "GPON Fiber") {
            $stkBackupGPONElement.Visibility = "Visible"
        } else {
            $stkBackupGPONElement.Visibility = "Collapsed"
        }
    }
})

$btnAddSite.Add_Click({
    $null = Add-Site
})

# Clear form button
$btnClearForm.Add_Click({
    Clear-SiteForm
    $txtBlkSiteStatus.Text = "Form cleared"
    $txtBlkSiteStatus.Foreground = [System.Windows.Media.Brushes]::Blue
})

# Edit site button - Now fully functional with popup window
$btnEditSite.Add_Click({
    $selectedItems = @($dgSites.SelectedItems)
    if ($selectedItems.Count -eq 1) {
        # Get the selected site data
        $selectedSite = $selectedItems[0]
        
        # Find the full site entry from the data store
        $allSites = $siteDataStore.GetAllEntries()
        $siteToEdit = $allSites | Where-Object { $_.ID -eq $selectedSite.ID }
        
        if ($siteToEdit) {
            # Show the edit window
            $editResult = Show-EditSiteWindow -SiteToEdit $siteToEdit
            
            if ($editResult) {
                # Refresh the data grid to show changes
                Update-DataGridWithSearch
            }
        } else {
            Show-ValidationError "Selected site not found in database." "Site Not Found"
        }
    } elseif ($selectedItems.Count -eq 0) {
        Show-ValidationError "Please select a site to edit." "Selection Required"
    } else {
        Show-ValidationError "Please select only one site to edit at a time." "Multiple Selection"
    }
})

# Delete site button
$btnDeleteSite.Add_Click({
    $selectedItems = @($dgSites.SelectedItems)
    if ($selectedItems.Count -gt 0) {
        $confirm = Show-CustomDialog "Are you sure you want to delete $($selectedItems.Count) selected sites?" "Confirm Deletion" "YesNo" "Warning"
       
        if ($confirm -eq "Yes") {
            $idsToDelete = @()
            foreach ($item in $selectedItems) {
                $idsToDelete += $item.ID
            }
            if ($siteDataStore.DeleteEntries($idsToDelete)) {
                Update-DataGridWithSearch
                Show-ValidationError "Successfully deleted $($selectedItems.Count) sites." "Success"
            } else {
                Show-ValidationError "Error deleting sites." "Delete Error"
            }
        }
    } else {
        Show-ValidationError "Please select one or more sites to delete." "Selection Required"
    }
})

# Enable Delete key to remove selected sites
$dgSites.Add_PreviewKeyDown({
    param($sender, $e)
   
    # Check if Delete key was pressed
    if ($e.Key -eq [System.Windows.Input.Key]::Delete) {
        $selectedItems = @($dgSites.SelectedItems)
       
        if ($selectedItems.Count -gt 0) {
            # Trigger delete functionality directly
            $confirm = Show-CustomDialog "Are you sure you want to delete $($selectedItems.Count) selected sites?" "Confirm Deletion" "YesNo" "Warning"
           
            if ($confirm -eq "Yes") {
                $idsToDelete = @()
                foreach ($item in $selectedItems) {
                    $idsToDelete += $item.ID
                }
                if ($siteDataStore.DeleteEntries($idsToDelete)) {
                    Update-DataGridWithSearch
                    Show-ValidationError "Successfully deleted $($selectedItems.Count) sites." "Success"
                } else {
                    Show-ValidationError "Error deleting sites." "Delete Error"
                }
            }
           
            # Mark the event as handled to prevent default behavior
            $e.Handled = $true
        }
    }
})

# Lookup site button
$btnLookupSite.Add_Click({
    $searchTerm = $txtSiteLookup.Text.Trim()
    Lookup-Site -SearchTerm $searchTerm
})

# Search functionality
$txtSearchSites.Add_TextChanged({
    $script:SearchTimer.Stop()
    $script:SearchTimer.Start()
})

$btnClearSearchSites.Add_Click({
    $txtSearchSites.Text = ""
    Update-DataGridWithSearch
})

# DataGrid selection changed
$dgSites.Add_SelectionChanged({
    $selectedItems = @($dgSites.SelectedItems)
    if ($selectedItems.Count -gt 0) {
        if ($selectedItems.Count -eq 1) {
            $txtStatusBarSiteSelected.Text = "Selected: $($selectedItems[0].SiteCode) - $($selectedItems[0].SiteName)"
        } else {
            $txtStatusBarSiteSelected.Text = "Selected: $($selectedItems.Count) sites"
        }
    } else {
        $txtStatusBarSiteSelected.Text = "Selected: None"
    }
})

# Enhanced double-click handler with better user feedback

$dgSites.Add_MouseDoubleClick({
    param($sender, $e)
    
    try {
        # Check if we actually clicked on a row (not empty space)
        $clickedItem = $dgSites.SelectedItem
        
        if ($clickedItem) {
            # Update status to show we're opening edit window
            $txtBlkSiteStatus.Text = "Opening edit window for site: $($clickedItem.SiteCode)..."
            $txtBlkSiteStatus.Foreground = [System.Windows.Media.Brushes]::Blue
            
            # Find the full site entry from the data store
            $allSites = $siteDataStore.GetAllEntries()
            $siteToEdit = $allSites | Where-Object { $_.ID -eq $clickedItem.ID }
            
            if ($siteToEdit) {
                # Show the edit window
                $editResult = Show-EditSiteWindow -SiteToEdit $siteToEdit
                
                if ($editResult) {
                    # Refresh the data grid to show changes
                    Update-DataGridWithSearch
                    $txtBlkSiteStatus.Text = "Site '$($siteToEdit.SiteCode)' updated successfully!"
                    $txtBlkSiteStatus.Foreground = [System.Windows.Media.Brushes]::Green
                } else {
                    $txtBlkSiteStatus.Text = "Edit cancelled for site: $($siteToEdit.SiteCode)"
                    $txtBlkSiteStatus.Foreground = [System.Windows.Media.Brushes]::Orange
                }
            } else {
                $txtBlkSiteStatus.Text = "Error: Selected site not found in database"
                $txtBlkSiteStatus.Foreground = [System.Windows.Media.Brushes]::Red
            }
        } else {
            # Double-clicked on empty space - provide helpful message
            $txtBlkSiteStatus.Text = "Double-click on a site row to edit it"
            $txtBlkSiteStatus.Foreground = [System.Windows.Media.Brushes]::Gray
        }
        
    } catch {
        $txtBlkSiteStatus.Text = "Error opening edit window: $_"
        $txtBlkSiteStatus.Foreground = [System.Windows.Media.Brushes]::Red
    }
})

# Main Tab control selection changed
$MainTabControl.Add_SelectionChanged({
    $selectedTab = $MainTabControl.SelectedItem
    
    if ($selectedTab -ne $null) {
        $currentTabHeader = $selectedTab.Header
        
        # Always clear status messages when switching main tabs
        if ($txtBlkSiteStatus) { $txtBlkSiteStatus.Text = "" }
        if ($txtBlkSiteImportStatus) { $txtBlkSiteImportStatus.Text = "" }
        if ($txtBlkImportStatus) { $txtBlkImportStatus.Text = "" }
        
        if ($currentTabHeader -eq "Site Network Identifier") {
            Update-DataGridWithSearch
        } else {
            if ($SiteStatusBar) { $SiteStatusBar.Visibility = [System.Windows.Visibility]::Collapsed }
        }
        
        # Handle IP Network Identifier status bar - IDENTICAL to Site pattern
        if ($currentTabHeader -eq "IP Network Identifier") {
            # Only show if we're on Manage Subnets sub-tab
            if ($IPNavTabControl -ne $null -and $IPNavTabControl.SelectedItem -ne $null) {
                $currentIPSubTab = $IPNavTabControl.SelectedItem.Header
                if ($currentIPSubTab -eq "Manage Subnets") {
                    $MainStatusBar.Visibility = "Visible"
                    Update-SubnetDataGridWithSearch
                } else {
                    $MainStatusBar.Visibility = "Collapsed"
                }
            }
        } else {
            if ($MainStatusBar) { $MainStatusBar.Visibility = [System.Windows.Visibility]::Collapsed }
        }
        
        # Clear site-related results when NOT on Site Network Identifier
        if ($currentTabHeader -ne "Site Network Identifier") {
            if ($txtSiteLookup) { $txtSiteLookup.Text = "" }
            if ($grpSiteLookupResults) { $grpSiteLookupResults.Visibility = "Collapsed" }
            if ($txtSiteCsvFilePath) { $txtSiteCsvFilePath.Text = "" }
        }
        
        # Clear IP network results when NOT on IP Network Identifier
        if ($currentTabHeader -ne "IP Network Identifier") {
            if ($txtIpLookup) { $txtIpLookup.Text = "" }
            if ($grpLookupResults) { $grpLookupResults.Visibility = "Collapsed" }
            if ($txtCsvFilePath) { $txtCsvFilePath.Text = "" }
        }
    }
})

# Site Management Sub-Tab control selection changed
$SiteNavTabControl.Add_SelectionChanged({
    $selectedSubTab = $SiteNavTabControl.SelectedItem
    
    if ($selectedSubTab -ne $null) {
        $currentSubTabHeader = $selectedSubTab.Header
        
        if ($currentSubTabHeader -eq "Manage Sites") {
            $SiteStatusBar.Visibility = "Visible"
        } else {
            $SiteStatusBar.Visibility = "Collapsed"
        }
    }
})

# IP Network Sub-Tab control selection changed - IDENTICAL to Site pattern
$IPNavTabControl.Add_SelectionChanged({
    $selectedSubTab = $IPNavTabControl.SelectedItem
    
    if ($selectedSubTab -ne $null) {
        $currentSubTabHeader = $selectedSubTab.Header
        
        if ($currentSubTabHeader -eq "Manage Subnets") {
            $MainStatusBar.Visibility = "Visible"
        } else {
            $MainStatusBar.Visibility = "Collapsed"
        }
    }
})

# Enter key support for lookup
$txtSiteLookup.Add_KeyDown({
    param($sender, $e)
    if ($e.Key -eq [System.Windows.Input.Key]::Enter) {
        $searchTerm = $txtSiteLookup.Text.Trim()
        Lookup-Site -SearchTerm $searchTerm
    }
})

# Browse for Excel file
$btnBrowseSiteCsv.Add_Click({
    try {
        $openDialog = New-Object Microsoft.Win32.OpenFileDialog
        $openDialog.Filter = "Excel files (*.xlsx;*.xls)|*.xlsx;*.xls|All files (*.*)|*.*"
        $openDialog.DefaultExt = "xlsx"
        
        if ($openDialog.ShowDialog() -eq $true) {
            $txtSiteCsvFilePath.Text = $openDialog.FileName
            $txtBlkSiteImportStatus.Text = "File selected: $($openDialog.FileName)"
            $txtBlkSiteImportStatus.Foreground = [System.Windows.Media.Brushes]::Blue
        }
    } catch {
        $txtBlkSiteImportStatus.Text = "Error selecting file: $_"
        $txtBlkSiteImportStatus.Foreground = [System.Windows.Media.Brushes]::Red
    }
})

# Import from Excel
# Import from Excel - FIXED VERSION
$btnImportSiteCsv.Add_Click({
    try {
        $filePath = $txtSiteCsvFilePath.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($filePath)) {
            Show-CustomDialog "Please select an Excel file first." "No File Selected" "OK" "Warning"
            return
        }
        
        # IMMEDIATE FEEDBACK - Show progress panel right away
        $pnlSiteImportProgress.Visibility = [System.Windows.Visibility]::Visible
        $pbSiteImportProgress.Value = 0
        $txtSiteProgressStatus.Text = "Initializing Excel application..."
        $txtSiteProgressDetails.Text = "Please wait while Excel is starting up..."
        [System.Windows.Forms.Application]::DoEvents()
        
        $result = Import-SitesFromExcel -ExcelFilePath $filePath
        
        # Show DETAILED results in main window status area
        $txtBlkSiteImportStatus.Text = $result
        $txtBlkSiteImportStatus.Foreground = [System.Windows.Media.Brushes]::Green
        
        # Extract counts from the main window result text to ensure consistency
        $importLines = $result -split "`n"
        
        # Parse using the correct patterns from debug output
        $totalLine = $importLines | Where-Object { $_ -like "Total sites processed: *" } | Select-Object -First 1
        $updatedLine = $importLines | Where-Object { $_ -like " Updated existing: * sites" -or $_ -like " Updated: * sites" } | Select-Object -First 1  
        $noChangesLine = $importLines | Where-Object { $_ -like " No changes needed: * sites" -or $_ -like " No changes: * sites" } | Select-Object -First 1
        $newLine = $importLines | Where-Object { $_ -like " Successfully imported: * sites" } | Select-Object -First 1
        $subnetWarningsLine = $importLines | Where-Object { $_ -like " Subnet warnings: * sites" } | Select-Object -First 1
        
        # Build popup using the same text as main window
        $popupBody = ""
        if ($totalLine) { $popupBody += $totalLine.Trim() }
        if ($newLine) { $popupBody += "`n" + $newLine.Trim() }
        if ($updatedLine) { $popupBody += "`n" + $updatedLine.Trim() }
        if ($noChangesLine) { $popupBody += "`n" + $noChangesLine.Trim() }
        if ($subnetWarningsLine) { $popupBody += "`n" + $subnetWarningsLine.Trim() }
        
        # ADD VALIDATION ERROR COUNT TO EXISTING POPUP
        $errorLines = $importLines | Where-Object { $_ -like "❌*" }
        if ($errorLines.Count -gt 0) {
            $popupBody += "`nValidation errors: $($errorLines.Count) sites"
        }
        
        # Show popup with summary statistics
        Show-CustomDialog $popupBody "Import completed successfully!" "OK" "Information"
        
        # FORCE REFRESH THE DATA GRID - Multiple approaches to ensure it works
        try {
            # Method 1: Force reload data store (in case it wasn't updated properly)
            $siteDataStore.LoadData()
            
            # Method 2: Clear and reset ItemsSource
            $dgSites.ItemsSource = $null
            [System.Windows.Forms.Application]::DoEvents()  # Allow UI to process
            
            # Method 3: Use the existing update function which handles search/filter
            Update-DataGridWithSearch
            
            # Method 4: If still not working, force a complete refresh
            $allData = $siteDataStore.GetAllEntries()
            $dgSites.ItemsSource = @($allData | Sort-Object -Property @{Expression={[int]$_.ID}; Ascending=$true})
            
            # Method 5: Force UI update
            $dgSites.Items.Refresh()
            [System.Windows.Forms.Application]::DoEvents()
                        
        } catch {
            # Fallback: try a simple refresh
            $dgSites.Items.Refresh()
        }
        
    } catch {
        $errorMsg = "Import failed: $_"
        $txtBlkSiteImportStatus.Text = $errorMsg
        $txtBlkSiteImportStatus.Foreground = [System.Windows.Media.Brushes]::Red
        Show-CustomDialog $errorMsg "Import Error" "OK" "Error"
    } finally {
        # Hide progress panel
        if ($pnlSiteImportProgress) {
            $pnlSiteImportProgress.Visibility = [System.Windows.Visibility]::Collapsed
        }
    }
})

# Export to CSV
$btnExportSiteCsv.Add_Click({
    try {
        # Show save dialog
        $saveDialog = New-Object Microsoft.Win32.SaveFileDialog
        $saveDialog.Filter = "Excel files (*.xlsx)|*.xlsx|All files (*.*)|*.*"
        $saveDialog.DefaultExt = "xlsx"
        $saveDialog.FileName = "sites_export_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').xlsx"
        
        if ($saveDialog.ShowDialog() -eq $true) {
            $result = Export-SitesToExcel -FilePath $saveDialog.FileName
            
            # Get file info with smart size formatting
            $fileInfo = Get-Item $saveDialog.FileName
            $fileSizeBytes = $fileInfo.Length
            
            # Smart file size formatting
            if ($fileSizeBytes -lt 1KB) {
                $fileSize = "$fileSizeBytes bytes"
            } elseif ($fileSizeBytes -lt 1MB) {
                $fileSizeKB = [math]::Round($fileSizeBytes / 1KB, 1)
                $fileSize = "$fileSizeKB KB"
            } else {
                $fileSizeMB = [math]::Round($fileSizeBytes / 1MB, 1)
                $fileSize = "$fileSizeMB MB"
            }
            
            # Get all sites and their codes
            $allSites = $siteDataStore.GetAllEntries()
            $totalSites = $allSites.Count
            $siteCodesList = ($allSites.SiteCode | Sort-Object) -join ", "
            
            # Build main window result - EXACT format you want
            $mainResult = @"
Excel export completed successfully!
==========================================

Total sites exported: $totalSites

Site Exported :
$siteCodesList

EXPORT DETAILS:
File size: $fileSize
Location: $($saveDialog.FileName)
"@

            # Build popup result - EXACT format you want  
            $popupResult = @"
Total sites exported: $totalSites
File size: $fileSize
Location: $([System.IO.Path]::GetFileName($saveDialog.FileName))
"@

            # Show results
            $txtBlkSiteImportStatus.Text = $mainResult
            $txtBlkSiteImportStatus.Foreground = [System.Windows.Media.Brushes]::Green
            
            Show-CustomDialog $popupResult "Export completed successfully!" "OK" "Information"
            
        } else {
            $txtBlkSiteImportStatus.Text = "Export cancelled"
            $txtBlkSiteImportStatus.Foreground = [System.Windows.Media.Brushes]::Orange
        }
        
    } catch {
        $errorMsg = "Export failed: $_"
        $txtBlkSiteImportStatus.Text = $errorMsg
        $txtBlkSiteImportStatus.Foreground = [System.Windows.Media.Brushes]::Red
        Show-CustomDialog $errorMsg "Export Error" "OK" "Error"
    }
})


# Import edit window functions
try {
    $editWindowPath = Join-Path $scriptPath "EditSiteWindow.ps1"    
    if (Test-Path $editWindowPath) {
        . $editWindowPath
    }
    else {
        $errorMsg = "EditSiteWindow.ps1 not found at: $editWindowPath"
        [System.Windows.MessageBox]::Show($errorMsg, "Module Error", "OK", "Error")
        exit 1
    }
}
catch {
    $errorMsg = "Failed to load EditSiteWindow.ps1: $_"
    [System.Windows.MessageBox]::Show($errorMsg, "Module Error", "OK", "Error")
    exit 1
}

# ===================================================================
# APPLICATION INITIALIZATION
# ===================================================================

# Initialize the data store first
$siteDataStore = [SiteDataStore]::new()

# Initialize the IP subnet data store
$subnetDataStore = [SubnetDataStore]::new()

# Initialize managers to null first
$script:DeviceManager = $null
$script:FieldManager = $null

# Add window loaded event to initialize managers after UI is ready
$mainWin.Add_Loaded({
    try {
        # Initialize managers after window is fully loaded
        $script:DeviceManager = [DevicePanelManager]::new($mainWin)
        $script:FieldManager = [FieldMappingManager]::new($mainWin)

                Write-Host "Main TabControl: $($MainTabControl.Name) - Items: $($MainTabControl.Items.Count)"
        Write-Host "Site Management TabControl: $($SiteManagementTabControl.Name) - Items: $($SiteManagementTabControl.Items.Count)"
        foreach ($item in $SiteManagementTabControl.Items) {
            Write-Host "  - $($item.Header)"
        }

        # Add this after your existing debug code:
Write-Host "=== SEARCHING FOR ALL TABCONTROLS ==="
$allTabControls = @()

# Method 1: Direct search by type
try {
    $grid = $mainWin.Content
    $allTabControls += $grid.FindName("MainTabControl")
    $allTabControls += $grid.FindName("SiteManagementTabControl")
    
    # Try common names for the missing TabControl
    $possibleNames = @("SiteTabControl", "SiteNavTabControl", "SubTabControl", "NestedTabControl")
    foreach ($name in $possibleNames) {
        $control = $mainWin.FindName($name)
        if ($control) {
            $allTabControls += $control
        }
    }
} catch {
    Write-Host "Error in TabControl search: $_"
}

# Show what we found
foreach ($tc in $allTabControls) {
    if ($tc) {
        Write-Host "TabControl Name: $($tc.Name)"
        foreach ($item in $tc.Items) {
            Write-Host "  - $($item.Header)"
        }
        Write-Host ""
    }
}
        
        # Set initial visibility states
        if ($grpSiteLookupResults) { $grpSiteLookupResults.Visibility = "Collapsed" }
        if ($grdBackupCircuit) { $grdBackupCircuit.Visibility = "Collapsed" }
        if ($stkPrimaryModem) { $stkPrimaryModem.Visibility = "Collapsed" }
        if ($stkBackupModem) { $stkBackupModem.Visibility = "Collapsed" }
        if ($pnlSiteImportProgress) { $pnlSiteImportProgress.Visibility = "Collapsed" }
        if ($SiteStatusBar) { $SiteStatusBar.Visibility = "Collapsed" }
        
        # Initialize IP Network components
        if ($grpLookupResults) { $grpLookupResults.Visibility = "Collapsed" }
        if ($pnlImportProgress) { $pnlImportProgress.Visibility = "Collapsed" }
        if ($MainStatusBar) { $MainStatusBar.Visibility = "Collapsed" }
        
        # Initialize the data grids
        Update-DataGridWithSearch
        
        # Initialize IP subnet data grid ONLY if controls exist
        if ($dgSubnets -ne $null) {
            Update-SubnetDataGridWithSearch
        }
        
        # Initialize IP Network event handlers ONLY if controls exist
        if ($btnAddEntry -ne $null) {
            Initialize-IPNetworkEventHandlers
        } else {
        }
        
        # Initialize phone formatting
        $txtMainContactPhone.Add_LostFocus({ $this.Text = Format-PhoneNumber $this.Text })
        $txtSecondContactPhone.Add_LostFocus({ $this.Text = Format-PhoneNumber $this.Text })
        
    } catch {
        [System.Windows.MessageBox]::Show("Error initializing application: $_", "Initialization Error", "OK", "Error")
    }
})

# Show the window
    try {
        $mainWin.ShowDialog() | Out-Null
    } catch {
}