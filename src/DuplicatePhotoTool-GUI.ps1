Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# ============================
# Window XAML
# ============================

[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Duplicate Photo Tool" Height="380" Width="600"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Source Folder -->
        <TextBlock Text="Source Folder:" Grid.Row="0" Margin="0,0,0,5"/>
        <StackPanel Grid.Row="1" Orientation="Horizontal">
            <TextBox Name="SourceBox" Width="450" Margin="0,0,10,0"/>
            <Button Name="BrowseSource" Width="80" Content="Browse"/>
        </StackPanel>

        <!-- Duplicate Folder -->
        <TextBlock Text="Duplicate Output Folder:" Grid.Row="2" Margin="0,10,0,5"/>
        <StackPanel Grid.Row="3" Orientation="Horizontal">
            <TextBox Name="DuplicateBox" Width="450" Margin="0,0,10,0"/>
            <Button Name="BrowseDuplicate" Width="80" Content="Browse"/>
        </StackPanel>

        <!-- Selection Mode -->
        <StackPanel Grid.Row="4" Margin="0,10,0,10">
            <TextBlock Text="Selection Mode:"/>
            <ComboBox Name="SelectionMode" Width="200">
                <ComboBoxItem Content="First" IsSelected="True"/>
                <ComboBoxItem Content="Newest"/>
                <ComboBoxItem Content="Largest"/>
            </ComboBox>
        </StackPanel>

        <!-- Run Button -->
        <Button Name="RunButton" Grid.Row="5" Content="Run Scan"
                Height="40" Background="#0078D7" Foreground="White"/>
    </Grid>
</Window>
"@

# ============================
# Load XAML
# ============================

$Reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

$SourceBox      = $Window.FindName("SourceBox")
$DuplicateBox   = $Window.FindName("DuplicateBox")
$BrowseSource   = $Window.FindName("BrowseSource")
$BrowseDuplicate= $Window.FindName("BrowseDuplicate")
$SelectionMode  = $Window.FindName("SelectionMode")
$RunButton      = $Window.FindName("RunButton")

# ============================
# Folder Browser Dialog
# ============================

function Select-Folder {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.ShowNewFolderButton = $true
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }
    return $null
}

# ============================
# Button Events
# ============================

$BrowseSource.Add_Click({
    $path = Select-Folder
    if ($path) { $SourceBox.Text = $path }
})

$BrowseDuplicate.Add_Click({
    $path = Select-Folder
    if ($path) { $DuplicateBox.Text = $path }
})

$RunButton.Add_Click({

    $src = $SourceBox.Text
    $dup = $DuplicateBox.Text
    $mode = $SelectionMode.SelectedItem.Content

    if (-not (Test-Path $src)) {
        [System.Windows.MessageBox]::Show("Source folder does not exist.")
        return
    }

    if (-not (Test-Path $dup)) {
        New-Item -ItemType Directory -Path $dup -Force | Out-Null
    }

    $script = Join-Path $PSScriptRoot "Find-DuplicatePhotos.ps1"

    Start-Process pwsh -ArgumentList @(
        "-NoLogo",
        "-File `"$script`"",
        "-Source `"$src`"",
        "-DuplicateRoot `"$dup`"",
        "-SelectionMode $mode"
    )

    [System.Windows.MessageBox]::Show("Scan started in a new PowerShell window.")
})

# ============================
# Show Window
# ============================

$Window.ShowDialog() | Out-Null
