# Environment check script - Verify build environment is correctly configured

$ErrorActionPreference = "Stop"

Write-Host "FaceWinUnlock Environment Check Tool" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

$allPassed = $true

# Check 1: Rust
Write-Host ""
Write-Host "Checking Rust..." -ForegroundColor Yellow
try {
    $rustVersion = rustc --version 2>$null
    if ($rustVersion) {
        Write-Host "  OK Rust installed: $rustVersion" -ForegroundColor Green
    } else {
        Write-Host "  ERROR Rust not installed" -ForegroundColor Red
        Write-Host "    Please visit: https://www.rust-lang.org/tools/install" -ForegroundColor Gray
        $allPassed = $false
    }
} catch {
    Write-Host "  ERROR Rust not installed" -ForegroundColor Red
    $allPassed = $false
}

# Check 2: Cargo
Write-Host ""
Write-Host "Checking Cargo..." -ForegroundColor Yellow
try {
    $cargoVersion = cargo --version 2>$null
    if ($cargoVersion) {
        Write-Host "  OK Cargo installed: $cargoVersion" -ForegroundColor Green
    } else {
        Write-Host "  ERROR Cargo not installed" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "  ERROR Cargo not installed" -ForegroundColor Red
    $allPassed = $false
}

# Check 3: Node.js
Write-Host ""
Write-Host "Checking Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "  OK Node.js installed: $nodeVersion" -ForegroundColor Green
    } else {
        Write-Host "  ERROR Node.js not installed" -ForegroundColor Red
        Write-Host "    Please visit: https://nodejs.org/" -ForegroundColor Gray
        $allPassed = $false
    }
} catch {
    Write-Host "  ERROR Node.js not installed" -ForegroundColor Red
    $allPassed = $false
}

# Check 4: npm
Write-Host ""
Write-Host "Checking npm..." -ForegroundColor Yellow
try {
    $npmVersion = npm --version 2>$null
    if ($npmVersion) {
        Write-Host "  OK npm installed: $npmVersion" -ForegroundColor Green
    } else {
        Write-Host "  ERROR npm not installed" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "  ERROR npm not installed" -ForegroundColor Red
    $allPassed = $false
}

# Check 5: vcpkg
Write-Host ""
Write-Host "Checking vcpkg..." -ForegroundColor Yellow
$vcpkgPath = "C:\vcpkg"
if (Test-Path $vcpkgPath) {
    Write-Host "  OK vcpkg installed: $vcpkgPath" -ForegroundColor Green

    # Check if OpenCV is installed
    $opencvPath = "$vcpkgPath\installed\x64-windows-static\bin\opencv_world*.dll"
    $opencvFiles = Get-ChildItem $opencvPath -ErrorAction SilentlyContinue
    if ($opencvFiles) {
        Write-Host "  OK OpenCV installed" -ForegroundColor Green
    } else {
        Write-Host "  WARNING OpenCV not installed, need to run:" -ForegroundColor Yellow
        Write-Host "    C:\vcpkg\vcpkg install opencv:x64-windows-static" -ForegroundColor Gray
    }
} else {
    Write-Host "  WARNING vcpkg not installed" -ForegroundColor Yellow
    Write-Host "    It will be installed automatically during build, or run manually:" -ForegroundColor Gray
    Write-Host "    git clone https://github.com/Microsoft/vcpkg.git C:\vcpkg" -ForegroundColor Gray
    Write-Host "    C:\vcpkg\bootstrap-vcpkg.bat" -ForegroundColor Gray
}

# Check 6: Project files
Write-Host ""
Write-Host "Checking project files..." -ForegroundColor Yellow
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

$requiredFiles = @(
    "Server\Cargo.toml",
    "UI\package.json",
    "UI\src-tauri\Cargo.toml",
    "UI\src-tauri\tauri.conf.json"
)

foreach ($file in $requiredFiles) {
    $filePath = Join-Path $ProjectRoot $file
    if (Test-Path $filePath) {
        Write-Host "  OK $file" -ForegroundColor Green
    } else {
        Write-Host "  ERROR $file (missing)" -ForegroundColor Red
        $allPassed = $false
    }
}

# Check 7: Model files
Write-Host ""
Write-Host "Checking model files..." -ForegroundColor Yellow
$ResourcesDir = Join-Path $ProjectRoot "UI\src-tauri\resources"

$modelFiles = @(
    "face_detection_yunet_2023mar.onnx",
    "face_recognition_sface_2021dec.onnx"
)

foreach ($file in $modelFiles) {
    $filePath = Join-Path $ResourcesDir $file
    if (Test-Path $filePath) {
        $fileSize = [math]::Round((Get-Item $filePath).Length / 1MB, 2)
        Write-Host "  OK $file ($fileSize MB)" -ForegroundColor Green
    } else {
        Write-Host "  WARNING $file (not downloaded)" -ForegroundColor Yellow
        Write-Host "    Run .\scripts\download-models.ps1 to download" -ForegroundColor Gray
    }
}

# Check 8: Frontend dependencies
Write-Host ""
Write-Host "Checking frontend dependencies..." -ForegroundColor Yellow
$packageJsonPath = Join-Path $ProjectRoot "UI\package.json"
$nodeModulesPath = Join-Path $ProjectRoot "UI\node_modules"

if (Test-Path $packageJsonPath) {
    if (Test-Path $nodeModulesPath) {
        $modulesCount = (Get-ChildItem $nodeModulesPath -Directory).Count
        Write-Host "  OK Frontend dependencies installed ($modulesCount packages)" -ForegroundColor Green
    } else {
        Write-Host "  WARNING Frontend dependencies not installed" -ForegroundColor Yellow
        Write-Host "    Run cd UI && npm install" -ForegroundColor Gray
    }
} else {
    Write-Host "  ERROR package.json does not exist" -ForegroundColor Red
    $allPassed = $false
}

# Summary
Write-Host ""
Write-Host "=========================" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "OK Environment check passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. If model files are not downloaded, run: .\scripts\download-models.ps1" -ForegroundColor Gray
    Write-Host "  2. If frontend dependencies are not installed, run: cd UI && npm install" -ForegroundColor Gray
    Write-Host "  3. Start development server: cd UI && npm run tauri dev" -ForegroundColor Gray
    exit 0
} else {
    Write-Host "ERROR Environment check failed, please fix the issues above" -ForegroundColor Red
    exit 1
}