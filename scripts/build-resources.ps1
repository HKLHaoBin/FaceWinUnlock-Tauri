# Resource preparation script for CI/CD environment (Windows)

$ErrorActionPreference = "Stop"

Write-Host "Starting resource preparation..." -ForegroundColor Green

# Set variables
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ServerDir = Join-Path $ProjectRoot "Server"
$UIDir = Join-Path $ProjectRoot "UI"
$ResourcesDir = Join-Path $UIDir "src-tauri\resources"

# Create resource directory
New-Item -ItemType Directory -Force -Path $ResourcesDir | Out-Null

# 1. Build Server DLL
Write-Host "Building Server DLL..." -ForegroundColor Yellow
Push-Location $ServerDir
cargo build --release --target x86_64-pc-windows-msvc
Copy-Item "target\x86_64-pc-windows-msvc\release\winlogon.dll" `
    -Destination "$ResourcesDir\FaceWinUnlock-Tauri.dll"
Write-Host "Server DLL build completed" -ForegroundColor Green
Pop-Location

# 2. Download ONNX model files
Write-Host "Downloading ONNX model files..." -ForegroundColor Yellow
$DownloadScript = Join-Path $ScriptDir "download-models.ps1"
if (Test-Path $DownloadScript) {
    & $DownloadScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARNING: Model download failed, but will continue building" -ForegroundColor Yellow
    }
} else {
    Write-Host "WARNING: Model download script does not exist, skipping this step" -ForegroundColor Yellow
}

# 3. OpenCV DLL will be copied automatically from vcpkg during build
Write-Host "OpenCV DLL will be copied from vcpkg during build" -ForegroundColor Cyan

Write-Host "All resources prepared!" -ForegroundColor Green
Get-ChildItem $ResourcesDir | Format-Table Name, Length, LastWriteTime