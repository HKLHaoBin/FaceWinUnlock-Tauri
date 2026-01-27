# Model download script - Standalone model file download tool

$ErrorActionPreference = "Stop"

Write-Host "FaceWinUnlock Model Download Tool" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

# Set variables
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$UIDir = Join-Path $ProjectRoot "UI"
$ResourcesDir = Join-Path $UIDir "src-tauri\resources"

# Create resource directory
New-Item -ItemType Directory -Force -Path $ResourcesDir | Out-Null

Write-Host "Target directory: $ResourcesDir" -ForegroundColor Gray

# Model configuration
$Models = @(
    @{
        Name = "Face Detection Model (YuNet)"
        FileName = "face_detection_yunet_2023mar.onnx"
        Url = "https://github.com/opencv/opencv_zoo/releases/download/v20231218/face_detection_yunet_2023mar.onnx"
        Size = "~3MB"
    },
    @{
        Name = "Face Recognition Model (SFace)"
        FileName = "face_recognition_sface_2021dec.onnx"
        Url = "https://github.com/opencv/opencv_zoo/releases/download/v20231218/face_recognition_sface_2021dec.onnx"
        Size = "~9MB"
    }
)

# Download function
function Download-Model {
    param (
        [string]$Name,
        [string]$FileName,
        [string]$Url,
        [string]$Size
    )

    $FilePath = Join-Path $ResourcesDir $FileName

    if (Test-Path $FilePath) {
        Write-Host "OK $Name already exists" -ForegroundColor Green
        return $true
    }

    Write-Host "Downloading $Name..." -ForegroundColor Yellow
    Write-Host "  File: $FileName" -ForegroundColor Gray
    Write-Host "  Size: $Size" -ForegroundColor Gray
    Write-Host "  URL: $Url" -ForegroundColor Gray

    $MaxRetries = 5
    $RetryCount = 0
    $Success = $false

    while (-not $Success -and $RetryCount -lt $MaxRetries) {
        try {
            $RetryCount++
            Write-Host "  Attempt $RetryCount/$MaxRetries..." -ForegroundColor Cyan

            # Use curl instead of Invoke-WebRequest for better reliability with large files
            $process = Start-Process -FilePath "curl" -ArgumentList @(
                "-L",
                "-o", "`"$FilePath`"",
                "--connect-timeout", "30",
                "--max-time", "600",
                "--retry", "3",
                "--retry-delay", "10",
                "--retry-max-time", "600",
                "--show-error",
                "`"$Url`""
            ) -NoNewWindow -Wait -PassThru

            if ($process.ExitCode -eq 0) {
                if (Test-Path $FilePath) {
                    $fileSize = (Get-Item $FilePath).Length
                    Write-Host "  OK Download successful ($([math]::Round($fileSize / 1MB, 2)) MB)" -ForegroundColor Green
                    $Success = $true
                } else {
                    Write-Host "  ERROR File not created" -ForegroundColor Red
                }
            } else {
                Write-Host "  ERROR Download failed (exit code: $($process.ExitCode))" -ForegroundColor Red
                if (Test-Path $FilePath) {
                    Remove-Item $FilePath -Force
                }
            }
        } catch {
            Write-Host "  ERROR Download exception: $_" -ForegroundColor Red
            if (Test-Path $FilePath) {
                Remove-Item $FilePath -Force
            }
        }

        if (-not $Success -and $RetryCount -lt $MaxRetries) {
            $waitTime = [math]::Min(10 * $RetryCount, 30)
            Write-Host "  Waiting $waitTime seconds before retry..." -ForegroundColor Yellow
            Start-Sleep -Seconds $waitTime
        }
    }

    return $Success
}

# Download all models
$successCount = 0
$failedModels = @()

foreach ($model in $Models) {
    $result = Download-Model `
        -Name $model.Name `
        -FileName $model.FileName `
        -Url $model.Url `
        -Size $model.Size

    if ($result) {
        $successCount++
    } else {
        $failedModels += $model.Name
    }
}

# Display results
Write-Host ""
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "Download complete!" -ForegroundColor Cyan

if ($successCount -eq $Models.Count) {
    Write-Host "OK All models downloaded successfully" -ForegroundColor Green
} else {
    Write-Host "WARNING Some models failed to download" -ForegroundColor Yellow
    Write-Host "Success: $successCount/$($Models.Count)" -ForegroundColor Yellow
    Write-Host "Failed: $($failedModels.Count)" -ForegroundColor Yellow
    if ($failedModels.Count -gt 0) {
        Write-Host "Failed models:" -ForegroundColor Yellow
        foreach ($model in $failedModels) {
            Write-Host "  - $model" -ForegroundColor Red
        }
    }
    Write-Host ""
    Write-Host "Manual download guide:" -ForegroundColor Yellow
    Write-Host "1. Visit: https://github.com/opencv/opencv_zoo/releases" -ForegroundColor Gray
    Write-Host "2. Download the following files:" -ForegroundColor Gray
    foreach ($model in $Models) {
        Write-Host "   - $($model.FileName)" -ForegroundColor Gray
    }
    Write-Host "3. Copy files to: $ResourcesDir" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Resource directory contents:" -ForegroundColor Cyan
Get-ChildItem $ResourcesDir | ForEach-Object {
    $size = [math]::Round($_.Length / 1MB, 2)
    Write-Host "  $($_.Name.PadRight(50)) $size MB" -ForegroundColor Gray
}

exit $(if ($successCount -eq $Models.Count) { 0 } else { 1 })