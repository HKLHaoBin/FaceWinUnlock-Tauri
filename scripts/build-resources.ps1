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

# 3. Copy all OpenCV DLLs to resources directory
Write-Host "Copying all OpenCV DLLs to resources directory..." -ForegroundColor Yellow
$OpenCVBinDir = "C:\vcpkg\installed\x64-windows\bin"

if (Test-Path $OpenCVBinDir) {
    # 复制所有 opencv_*.dll
    $opencvDlls = Get-ChildItem -Path $OpenCVBinDir -Filter "opencv_*.dll" -ErrorAction SilentlyContinue
    foreach ($dll in $opencvDlls) {
        Copy-Item -Path $dll.FullName -Destination $ResourcesDir -Force
        Write-Host "  - $($dll.Name) (OpenCV 核心库)" -ForegroundColor Green
    }

    # 复制所有依赖 DLL（包括 libwebp, jpeg, zlib, libpng, libtiff, tbb 等）
    $allDlls = Get-ChildItem -Path $OpenCVBinDir -Filter "*.dll" -ErrorAction SilentlyContinue

    # 排除 OpenCV DLL（已经复制过了）和 vcpkg 自己的 DLL
    $depDlls = $allDlls | Where-Object {
        $_.Name -notmatch "^opencv_" -and
        $_.Name -notmatch "^vcpkg" -and
        $_.Name -notmatch "^msvcp" -and
        $_.Name -notmatch "^vcruntime" -and
        $_.Name -notmatch "^api-ms-win"
    }

    foreach ($dll in $depDlls) {
        Copy-Item -Path $dll.FullName -Destination $ResourcesDir -Force
        Write-Host "  - $($dll.Name) (依赖库)" -ForegroundColor Green
    }

    Write-Host "总共复制了 $($opencvDlls.Count + $depDlls.Count) 个 DLL 文件" -ForegroundColor Cyan
} else {
    Write-Host "WARNING: OpenCV bin directory not found at $OpenCVBinDir" -ForegroundColor Yellow
}

Write-Host "All resources prepared!" -ForegroundColor Green
Get-ChildItem $ResourcesDir | Format-Table Name, Length, LastWriteTime