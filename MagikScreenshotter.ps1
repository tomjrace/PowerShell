# Ensure ImageMagick is installed and its path is added to the system PATH or provide the full path to magick.exe

# Get the current user's Pictures directory
$picturesPath = [System.Environment]::GetFolderPath('MyPictures')
$saveLocation = Join-Path $picturesPath "magickScreenshot"

# Ensure the directory exists
if (-not (Test-Path $saveLocation)) {
    New-Item -ItemType Directory -Path $saveLocation
    Write-Host "Created new directory for screenshots: $saveLocation" -ForegroundColor Green
}

# Prompt for screenshot interval in seconds
$interval = Read-Host "Enter the interval between screenshots in seconds"

# Convert interval to integer
$interval = [int]$interval

# Counter for screenshot names
$counter = 0

# Function to log messages with color (console only)
function Write-Log {
    param (
        [string]$Message,
        [System.ConsoleColor]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Log start of script
Write-Log "Screenshot capture script started" -Color Cyan

# Register the Ctrl+C handler
[System.Console]::TreatControlCAsInput = $true

# Main loop
:MainLoop while ($true) {
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $counter++
        
        # Capture screenshots from both monitors
        $screens = [System.Windows.Forms.Screen]::AllScreens
        $tempFiles = @()
        
        foreach ($index in 0..($screens.Length - 1)) {
            $filename = "Screenshot_$timestamp`_Monitor$index`_$counter.png"
            $fullPath = Join-Path $saveLocation $filename
            magick.exe screenshot:[$index] $fullPath
            $tempFiles += $fullPath
            Write-Log "Captured screenshot from $($screens[$index].DeviceName) - Saved as: $filename" -Color Magenta
        }

        # Combine screenshots into one image
        $combinedFilename = "Combined_Screenshot_$timestamp`_$(++$counter).png"
        $combinedPath = Join-Path $saveLocation $combinedFilename

        # Join the first two images horizontally, assuming there are only two monitors
        magick.exe montage -mode concatenate -tile 2x1 $tempFiles[0] $tempFiles[1] -geometry +0+0 $combinedPath

        Write-Log "Combined screenshots into: $combinedFilename" -Color Yellow

        # Optionally, remove temporary files if you don't need them
        foreach ($file in $tempFiles) {
            Remove-Item $file
            Write-Log "Removed temporary file: $file" -Color DarkGray
        }

        # Check for user interruption every cycle
        if ([System.Console]::KeyAvailable) {
            $key = [System.Console]::ReadKey($true)
            if ($key.Key -eq [System.ConsoleKey]::C -and ($key.Modifiers -band [System.ConsoleModifiers]::Control) -ne 0) {
                Write-Log "Script stopped. Opening screenshot folder..." -Color Yellow
                Start-Process "explorer.exe" -ArgumentList "$saveLocation"
                break MainLoop  # Exit the main loop
            }
        }

    } catch {
        Write-Log "Error capturing or combining screenshots: $_" -Color Red
    }

    # Wait for the specified interval before next screenshot
    Write-Log "Waiting for $interval seconds..." -Color Blue
    Start-Sleep -Seconds $interval
}

# Reset Ctrl+C behavior
[System.Console]::TreatControlCAsInput = $false