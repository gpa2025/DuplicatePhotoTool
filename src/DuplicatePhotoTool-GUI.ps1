Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

$Version = Get-Content (Join-Path $PSScriptRoot "..\VERSION") -ErrorAction SilentlyContinue
if (-not $Version) { $Version = "1.0.0" }

# ============================
# Splash Screen
# ============================

[xml]$SplashXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        Width="420" Height="220" WindowStartupLocation="CenterScreen" Topmost="True">
    <Border CornerRadius="16" Background="#0f172a" BorderBrush="#00d9ff" BorderThickness="1.5">
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

$Splash.Show()

# Animate progress bar over 1.8 seconds
for ($i = 0; $i -le 100; $i += 5) {
    $SplashProgress.Value = $i
    $Splash.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
    Start-Sleep -Milliseconds 90
}

$Splash.Close()

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

            <!-- Dry Run -->
            <CheckBox Name="DryRun" Grid.Row="4" Margin="0,0,0,14"
                      Content="Dry Run — preview only, no files will be moved"/>

            <!-- Run Button + Timer -->
            <Grid Grid.Row="5" VerticalAlignment="Top">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Button Name="RunButton" Grid.Column="0" Content="▶  Run Scan"
                        Height="44" Background="#0078D7" Foreground="White"
                        BorderThickness="0" FontSize="15" FontWeight="SemiBold"/>
                <Border Grid.Column="1" Background="#1e293b" BorderBrush="#334155"
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
$RunButton       = $Window.FindName("RunButton")
$TimerLabel      = $Window.FindName("TimerLabel")
$StatusBar       = $Window.FindName("StatusBar")

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

$RunButton.Add_MouseEnter({
    $StatusBar.Text = "Start scanning for duplicate photos using SHA256 hashing."
})
$RunButton.Add_MouseLeave({
    $StatusBar.Text = "Ready."
})

# ============================
# Button Events
# ============================

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

    $args = @("-NoLogo", "-File `"$script`"", "-Source `"$src`"", "-DuplicateRoot `"$dup`"")
    if ($DryRunCheck.IsChecked) { $args += "-DryRun" }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $process = Start-Process pwsh -ArgumentList $args -PassThru

    $RunButton.IsEnabled = $false
    $TimerLabel.Foreground = "#00d9ff"
    $StatusBar.Text = "⏱ Scan running..."

    # DispatcherTimer ticks every second to update the MM:SS label
    $dispatcherTimer = New-Object System.Windows.Threading.DispatcherTimer
    $dispatcherTimer.Interval = [TimeSpan]::FromSeconds(1)
    $dispatcherTimer.Add_Tick({
        $e = $stopwatch.Elapsed
        $TimerLabel.Text = "{0:D2}:{1:D2}" -f [int]$e.TotalMinutes, $e.Seconds
    })
    $dispatcherTimer.Start()

    # Watch for process exit async
    $null = Register-ObjectEvent -InputObject $process -EventName Exited -Action {
        $dispatcherTimer.Stop()
        $elapsed = $stopwatch.Elapsed
        $elapsedStr = if ($elapsed.TotalMinutes -ge 1) {
            "{0}m {1}s" -f [int]$elapsed.TotalMinutes, $elapsed.Seconds
        } else {
            "{0:N1}s" -f $elapsed.TotalSeconds
        }
        $Window.Dispatcher.Invoke([action]{
            $TimerLabel.Foreground = "#10b981"
            $RunButton.IsEnabled = $true
            $StatusBar.Text = "✔ Scan completed in $elapsedStr. Check the output folder and CSV report."
        })
    } -MessageData @{ Timer = $dispatcherTimer; Stopwatch = $stopwatch; Window = $Window; StatusBar = $StatusBar; RunButton = $RunButton; TimerLabel = $TimerLabel }
})

# ============================
# Show Window
# ============================

$Window.ShowDialog() | Out-Null
