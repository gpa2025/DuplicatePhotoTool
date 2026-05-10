Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

$Version = Get-Content (Join-Path $PSScriptRoot "..\VERSION") -ErrorAction SilentlyContinue
if (-not $Version) { $Version = "1.0.0" }

# ============================
# Splash Screen
# ============================

[xml]$SplashXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        WindowStyle="None" AllowsTransparency="False" Background="#0f172a"
        Width="420" Height="220" WindowStartupLocation="CenterScreen" Topmost="True">
    <Border Background="#0f172a" BorderBrush="#00d9ff" BorderThickness="1.5">
        <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Margin="30">
            <TextBlock Text="GPA Solutions" FontSize="13" Foreground="#00d9ff"
                       HorizontalAlignment="Center" Margin="0,0,0,4" FontWeight="SemiBold"/>
            <TextBlock Text="Duplicate Photo Tool" FontSize="26" Foreground="White"
                       HorizontalAlignment="Center" FontWeight="Bold" Margin="0,0,0,6"/>
            <TextBlock Name="SplashVersion" FontSize="12" Foreground="#64748b"
                       HorizontalAlignment="Center" Margin="0,0,0,16"/>
            <ProgressBar Name="SplashProgress" Height="4" Width="300"
                         Foreground="#00d9ff" Background="#1e293b"
                         Minimum="0" Maximum="100" Value="0"/>
            <TextBlock Text="Loading..." FontSize="11" Foreground="#64748b"
                       HorizontalAlignment="Center" Margin="0,10,0,0"/>
        </StackPanel>
    </Border>
</Window>
"@

$SplashReader = New-Object System.Xml.XmlNodeReader $SplashXAML
$Splash = [Windows.Markup.XamlReader]::Load($SplashReader)
$Splash.FindName("SplashVersion").Text = "v$Version"
$SplashProgress = $Splash.FindName("SplashProgress")

# Use DispatcherTimer to animate splash without blocking
$splashTimer = New-Object System.Windows.Threading.DispatcherTimer
$splashTimer.Interval = [TimeSpan]::FromMilliseconds(30)
$script:splashValue = 0
$splashTimer.Add_Tick({
    $script:splashValue += 3
    $SplashProgress.Value = $script:splashValue
    if ($script:splashValue -ge 100) {
        $splashTimer.Stop()
        $Splash.Close()
        $Window.Show()
    }
})

$Splash.Show()
$splashTimer.Start()

# ============================
# Main Window XAML
# ============================

[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="GPA Duplicate Photo Tool v$Version" Height="420" Width="620"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#0f172a">
    <Window.Resources>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#cbd5e1"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#1e293b"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#334155"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="6,4"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#1e293b"/>
            <Setter Property="Foreground" Value="#00d9ff"/>
            <Setter Property="BorderBrush" Value="#334155"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8,4"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#cbd5e1"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#0f172a" BorderBrush="#00d9ff" BorderThickness="0,0,0,1" Padding="16,12">
            <StackPanel>
                <TextBlock Text="GPA Solutions" FontSize="11" Foreground="#00d9ff" FontWeight="SemiBold"/>
                <TextBlock Text="Duplicate Photo Tool" FontSize="20" Foreground="White" FontWeight="Bold"/>
            </StackPanel>
        </Border>

        <!-- Main Content -->
        <Grid Grid.Row="1" Margin="16,16,16,8">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <!-- Source Folder -->
            <TextBlock Grid.Row="0" Text="Source Folder" Margin="0,0,0,5"/>
            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,14">
                <TextBox Name="SourceBox" Width="460" Margin="0,0,8,0"/>
                <Button Name="BrowseSource" Width="80" Content="Browse"/>
            </StackPanel>

            <!-- Duplicate Output Folder -->
            <TextBlock Grid.Row="2" Text="Duplicate Output Folder" Margin="0,0,0,5"/>
            <StackPanel Grid.Row="3" Orientation="Horizontal" Margin="0,0,0,14">
                <TextBox Name="DuplicateBox" Width="460" Margin="0,0,8,0"/>
                <Button Name="BrowseDuplicate" Width="80" Content="Browse"/>
            </StackPanel>

            <!-- Dry Run + Cores -->
            <Grid Grid.Row="4" Margin="0,0,0,14">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <CheckBox Name="DryRun" Grid.Column="0" VerticalAlignment="Center"
                          Content="Dry Run — preview only, no files will be moved"/>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="Cores:" Foreground="#94a3b8" FontSize="12" VerticalAlignment="Center" Margin="0,0,8,0"/>
                    <Slider Name="CoresSlider" Minimum="1" Maximum="16" Value="4"
                            Width="120" VerticalAlignment="Center" IsSnapToTickEnabled="True" TickFrequency="1"/>
                    <TextBlock Name="CoresLabel" Text="4" Foreground="#00d9ff" FontSize="13" FontWeight="Bold"
                               FontFamily="Consolas" VerticalAlignment="Center" Margin="8,0,0,0" MinWidth="24"/>
                </StackPanel>
            </Grid>

            <!-- Run Button + Timer -->
            <Grid Grid.Row="5" VerticalAlignment="Top">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Button Name="RunButton" Grid.Column="0" Content="▶  Run Scan"
                        Height="44" Background="#0078D7" Foreground="White"
                        BorderThickness="0" FontSize="15" FontWeight="SemiBold"/>
                <Button Name="ViewLogButton" Grid.Column="1" Content="📋  View Log"
                        Height="44" Margin="10,0,0,0" Padding="12,0"/>
                <Border Grid.Column="2" Background="#1e293b" BorderBrush="#334155"
                        BorderThickness="1" CornerRadius="4" Margin="10,0,0,0" Padding="12,0">
                    <TextBlock Name="TimerLabel" Text="00:00" Foreground="#00d9ff"
                               FontSize="20" FontFamily="Consolas" FontWeight="Bold"
                               VerticalAlignment="Center" HorizontalAlignment="Center"
                               MinWidth="70" TextAlignment="Center"/>
                </Border>
            </Grid>
        </Grid>

        <!-- Status Bar -->
        <Border Grid.Row="2" Background="#1e293b" BorderBrush="#334155" BorderThickness="0,1,0,0" Padding="16,8">
            <TextBlock Name="StatusBar" Text="Ready. Select a source folder to begin."
                       Foreground="#94a3b8" FontSize="12" TextWrapping="Wrap"/>
        </Border>

        <!-- Footer -->
        <Border Grid.Row="3" Background="#0f172a" Padding="16,6">
            <TextBlock Text="GPA Solutions © 2026 — SHA256 exact duplicate detection"
                       Foreground="#334155" FontSize="11" HorizontalAlignment="Center"/>
        </Border>
    </Grid>
</Window>
"@

$Reader = New-Object System.Xml.XmlNodeReader $XAML
$Window = [Windows.Markup.XamlReader]::Load($Reader)

$SourceBox       = $Window.FindName("SourceBox")
$DuplicateBox    = $Window.FindName("DuplicateBox")
$BrowseSource    = $Window.FindName("BrowseSource")
$BrowseDuplicate = $Window.FindName("BrowseDuplicate")
$DryRunCheck     = $Window.FindName("DryRun")
$CoresSlider     = $Window.FindName("CoresSlider")
$CoresLabel      = $Window.FindName("CoresLabel")
$ViewLogButton   = $Window.FindName("ViewLogButton")
$RunButton       = $Window.FindName("RunButton")
$TimerLabel      = $Window.FindName("TimerLabel")
$StatusBar       = $Window.FindName("StatusBar")
$script:RunButton   = $RunButton
$script:TimerLabel  = $TimerLabel
$script:StatusBar   = $StatusBar
$script:Window      = $Window

# Update cores label as slider moves
$CoresSlider.Add_ValueChanged({
    $CoresLabel.Text = [int]$CoresSlider.Value
})

# ============================
# Folder Browser
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
# Context Help
# ============================

$SourceBox.Add_GotFocus({
    $StatusBar.Text = "Source Folder: The folder to scan for duplicate photos. All subfolders will be included."
})
$SourceBox.Add_LostFocus({
    $StatusBar.Text = "Ready."
})

$BrowseSource.Add_MouseEnter({
    $StatusBar.Text = "Browse for the folder containing your photos."
})
$BrowseSource.Add_MouseLeave({
    $StatusBar.Text = "Ready."
})

$DuplicateBox.Add_GotFocus({
    $StatusBar.Text = "Output Folder: Duplicate files will be moved here, preserving the original folder structure."
})
$DuplicateBox.Add_LostFocus({
    $StatusBar.Text = "Ready."
})

$BrowseDuplicate.Add_MouseEnter({
    $StatusBar.Text = "Browse for the folder where duplicates will be moved. It will be created if it doesn't exist."
})
$BrowseDuplicate.Add_MouseLeave({
    $StatusBar.Text = "Ready."
})

$DryRunCheck.Add_MouseEnter({
    $StatusBar.Text = "Dry Run: Simulates the scan and shows what would be moved — no files are actually touched."
})
$DryRunCheck.Add_MouseLeave({
    $StatusBar.Text = "Ready."
})

$CoresSlider.Add_MouseEnter({
    $StatusBar.Text = "Cores: Number of CPU cores for hashing. Use 2-4 for HDD, up to 16 for SSD. Changes take effect on the next scan."
})
$CoresSlider.Add_MouseLeave({
    $StatusBar.Text = "Ready."
})

$ViewLogButton.Add_MouseEnter({
    $StatusBar.Text = "View Log: Opens the scan log for the selected output folder."
})
$ViewLogButton.Add_MouseLeave({
    $StatusBar.Text = "Ready."
})

$RunButton.Add_MouseEnter({
    $StatusBar.Text = "Start scanning for duplicate photos using SHA256 hashing."
})
$RunButton.Add_MouseLeave({
    $StatusBar.Text = "Ready."
})

# ============================
# Button Events
# ============================

$ViewLogButton.Add_Click({
    $dup = $DuplicateBox.Text.Trim()
    $logPath = if ($dup) {
        Get-ChildItem -Path $dup -Filter "scan_log_*.txt" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
    } else { $null }

    if (-not $logPath -or -not (Test-Path $logPath)) {
        $StatusBar.Text = "⚠ No log found. Run a scan first."
        [System.Windows.MessageBox]::Show("No log file found. Run a scan first.", "No Log")
        return
    }

    $logContent = Get-Content $logPath -Raw

    [xml]$LogXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Scan Log" Height="600" Width="900"
        WindowStartupLocation="CenterScreen" Background="#0f172a">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <TextBox Name="LogBox" Grid.Row="0" Margin="10" Padding="8"
                 Background="#0f172a" Foreground="#94a3b8" FontFamily="Consolas"
                 FontSize="12" IsReadOnly="True" VerticalScrollBarVisibility="Auto"
                 HorizontalScrollBarVisibility="Auto" TextWrapping="NoWrap"
                 BorderThickness="0"/>
        <Button Name="CloseBtn" Grid.Row="1" Content="Close" Margin="10"
                Height="36" Background="#1e293b" Foreground="#00d9ff"
                BorderBrush="#334155" BorderThickness="1" FontSize="13"/>
    </Grid>
</Window>
"@
    $logReader = New-Object System.Xml.XmlNodeReader $LogXAML
    $logWindow = [Windows.Markup.XamlReader]::Load($logReader)
    $logWindow.FindName("LogBox").Text = $logContent
    $logWindow.FindName("CloseBtn").Add_Click({ $logWindow.Close() })
    $logWindow.ShowDialog() | Out-Null
    $StatusBar.Text = "Ready."
})

$BrowseSource.Add_Click({
    $path = Select-Folder
    if ($path) {
        $SourceBox.Text = $path
        $StatusBar.Text = "Source folder set: $path"
    }
})

$BrowseDuplicate.Add_Click({
    $path = Select-Folder
    if ($path) {
        $DuplicateBox.Text = $path
        $StatusBar.Text = "Output folder set: $path"
    }
})

$RunButton.Add_Click({
    $src = $SourceBox.Text.Trim()
    $dup = $DuplicateBox.Text.Trim()

    if (-not $src) {
        $StatusBar.Text = "⚠ Please enter a source folder."
        [System.Windows.MessageBox]::Show("Please select a source folder.", "Missing Input")
        return
    }

    if (-not (Test-Path $src)) {
        $StatusBar.Text = "⚠ Source folder does not exist: $src"
        [System.Windows.MessageBox]::Show("Source folder does not exist.", "Invalid Path")
        return
    }

    if (-not $dup) {
        $StatusBar.Text = "⚠ Please enter an output folder."
        [System.Windows.MessageBox]::Show("Please select an output folder.", "Missing Input")
        return
    }

    if (-not (Test-Path $dup)) {
        New-Item -ItemType Directory -Path $dup -Force | Out-Null
    }

    $script = Join-Path $PSScriptRoot "Find-DuplicatePhotos.ps1"
    $dryRunArg = if ($DryRunCheck.IsChecked) { '"-DryRun"' } else { "" }

    $cores = [int]$CoresSlider.Value
    $args = @("-NoLogo", "-File `"$script`"", "-Source `"$src`"", "-DuplicateRoot `"$dup`"", "-ThrottleLimit $cores")
    if ($DryRunCheck.IsChecked) { $args += "-DryRun" }

    $script:stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $process = Start-Process pwsh -ArgumentList $args -PassThru

    $script:RunButton.IsEnabled = $false
    $CoresSlider.IsEnabled = $false
    $script:TimerLabel.Foreground = "#00d9ff"
    $script:StatusBar.Text = "⏱ Scan running..."

    # DispatcherTimer ticks every second to update the MM:SS label
    $script:dispatcherTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:dispatcherTimer.Interval = [TimeSpan]::FromSeconds(1)
    $script:dispatcherTimer.Add_Tick({
        $e = $script:stopwatch.Elapsed
        $script:TimerLabel.Text = "{0:D2}:{1:D2}" -f [int]$e.TotalMinutes, $e.Seconds
    })
    $script:dispatcherTimer.Start()

    # Watch for process exit async
    $null = Register-ObjectEvent -InputObject $process -EventName Exited -Action {
        $script:dispatcherTimer.Stop()
        $elapsed = $script:stopwatch.Elapsed
        $elapsedStr = if ($elapsed.TotalMinutes -ge 1) {
            "{0}m {1}s" -f [int]$elapsed.TotalMinutes, $elapsed.Seconds
        } else {
            "{0:N1}s" -f $elapsed.TotalSeconds
        }
        $script:Window.Dispatcher.Invoke([action]{
            $script:TimerLabel.Foreground = "#10b981"
            $script:RunButton.IsEnabled = $true
            $CoresSlider.IsEnabled = $true
            $script:StatusBar.Text = "✔ Scan completed in $elapsedStr. Check the output folder and CSV report."
        })
    }
})

# ============================
# Show Splash then Main Window
# ============================

$script:splashValue = 0
$splashTimer = New-Object System.Windows.Threading.DispatcherTimer
$splashTimer.Interval = [TimeSpan]::FromMilliseconds(30)
$splashTimer.Add_Tick({
    $script:splashValue += 3
    $SplashProgress.Value = $script:splashValue
    if ($script:splashValue -ge 100) {
        $splashTimer.Stop()
        $Splash.Close()
        $Window.ShowDialog() | Out-Null
    }
})

$Splash.Show()
$splashTimer.Start()

# Run the dispatcher loop to process splash timer ticks
[System.Windows.Threading.Dispatcher]::Run()
