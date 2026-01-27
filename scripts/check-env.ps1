# 环境检查脚本 - 验证构建环境是否正确配置

$ErrorActionPreference = "Stop"

Write-Host "FaceWinUnlock 环境检查工具" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

$allPassed = $true

# 检查 1: Rust
Write-Host ""
Write-Host "检查 Rust..." -ForegroundColor Yellow
try {
    $rustVersion = rustc --version 2>$null
    if ($rustVersion) {
        Write-Host "  ✓ Rust 已安装: $rustVersion" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Rust 未安装" -ForegroundColor Red
        Write-Host "    请访问: https://www.rust-lang.org/tools/install" -ForegroundColor Gray
        $allPassed = $false
    }
} catch {
    Write-Host "  ✗ Rust 未安装" -ForegroundColor Red
    $allPassed = $false
}

# 检查 2: Cargo
Write-Host ""
Write-Host "检查 Cargo..." -ForegroundColor Yellow
try {
    $cargoVersion = cargo --version 2>$null
    if ($cargoVersion) {
        Write-Host "  ✓ Cargo 已安装: $cargoVersion" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Cargo 未安装" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "  ✗ Cargo 未安装" -ForegroundColor Red
    $allPassed = $false
}

# 检查 3: Node.js
Write-Host ""
Write-Host "检查 Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "  ✓ Node.js 已安装: $nodeVersion" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Node.js 未安装" -ForegroundColor Red
        Write-Host "    请访问: https://nodejs.org/" -ForegroundColor Gray
        $allPassed = $false
    }
} catch {
    Write-Host "  ✗ Node.js 未安装" -ForegroundColor Red
    $allPassed = $false
}

# 检查 4: npm
Write-Host ""
Write-Host "检查 npm..." -ForegroundColor Yellow
try {
    $npmVersion = npm --version 2>$null
    if ($npmVersion) {
        Write-Host "  ✓ npm 已安装: $npmVersion" -ForegroundColor Green
    } else {
        Write-Host "  ✗ npm 未安装" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "  ✗ npm 未安装" -ForegroundColor Red
    $allPassed = $false
}

# 检查 5: vcpkg
Write-Host ""
Write-Host "检查 vcpkg..." -ForegroundColor Yellow
$vcpkgPath = "C:\vcpkg"
if (Test-Path $vcpkgPath) {
    Write-Host "  ✓ vcpkg 已安装: $vcpkgPath" -ForegroundColor Green

    # 检查 OpenCV 是否已安装
    $opencvPath = "$vcpkgPath\installed\x64-windows-static\bin\opencv_world*.dll"
    $opencvFiles = Get-ChildItem $opencvPath -ErrorAction SilentlyContinue
    if ($opencvFiles) {
        Write-Host "  ✓ OpenCV 已安装" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ OpenCV 未安装，需要运行:" -ForegroundColor Yellow
        Write-Host "    C:\vcpkg\vcpkg install opencv:x64-windows-static" -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠ vcpkg 未安装" -ForegroundColor Yellow
    Write-Host "    构建时会自动安装，或手动运行:" -ForegroundColor Gray
    Write-Host "    git clone https://github.com/Microsoft/vcpkg.git C:\vcpkg" -ForegroundColor Gray
    Write-Host "    C:\vcpkg\bootstrap-vcpkg.bat" -ForegroundColor Gray
}

# 检查 6: 项目文件
Write-Host ""
Write-Host "检查项目文件..." -ForegroundColor Yellow
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
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (缺失)" -ForegroundColor Red
        $allPassed = $false
    }
}

# 检查 7: 模型文件
Write-Host ""
Write-Host "检查模型文件..." -ForegroundColor Yellow
$ResourcesDir = Join-Path $ProjectRoot "UI\src-tauri\resources"

$modelFiles = @(
    "face_detection_yunet_2023mar.onnx",
    "face_recognition_sface_2021dec.onnx"
)

foreach ($file in $modelFiles) {
    $filePath = Join-Path $ResourcesDir $file
    if (Test-Path $filePath) {
        $fileSize = [math]::Round((Get-Item $filePath).Length / 1MB, 2)
        Write-Host "  ✓ $file ($fileSize MB)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ $file (未下载)" -ForegroundColor Yellow
        Write-Host "    运行 .\scripts\download-models.ps1 下载" -ForegroundColor Gray
    }
}

# 检查 8: 前端依赖
Write-Host ""
Write-Host "检查前端依赖..." -ForegroundColor Yellow
$packageJsonPath = Join-Path $ProjectRoot "UI\package.json"
$nodeModulesPath = Join-Path $ProjectRoot "UI\node_modules"

if (Test-Path $packageJsonPath) {
    if (Test-Path $nodeModulesPath) {
        $modulesCount = (Get-ChildItem $nodeModulesPath -Directory).Count
        Write-Host "  ✓ 前端依赖已安装 ($modulesCount 个包)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ 前端依赖未安装" -ForegroundColor Yellow
        Write-Host "    运行 cd UI && npm install" -ForegroundColor Gray
    }
} else {
    Write-Host "  ✗ package.json 不存在" -ForegroundColor Red
    $allPassed = $false
}

# 总结
Write-Host ""
Write-Host "=========================" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "✓ 环境检查通过！" -ForegroundColor Green
    Write-Host ""
    Write-Host "下一步操作:" -ForegroundColor Cyan
    Write-Host "  1. 如果模型文件未下载，运行: .\scripts\download-models.ps1" -ForegroundColor Gray
    Write-Host "  2. 如果前端依赖未安装，运行: cd UI && npm install" -ForegroundColor Gray
    Write-Host "  3. 启动开发服务器: cd UI && npm run tauri dev" -ForegroundColor Gray
    exit 0
} else {
    Write-Host "✗ 环境检查失败，请修复上述问题" -ForegroundColor Red
    exit 1
}