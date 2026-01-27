# 资源准备脚本 - 用于 CI/CD 环境 (Windows)

$ErrorActionPreference = "Stop"

Write-Host "开始准备构建资源..." -ForegroundColor Green

# 设置变量
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ServerDir = Join-Path $ProjectRoot "Server"
$UIDir = Join-Path $ProjectRoot "UI"
$ResourcesDir = Join-Path $UIDir "src-tauri\resources"

# 创建资源目录
New-Item -ItemType Directory -Force -Path $ResourcesDir | Out-Null

# 1. 构建 Server DLL
Write-Host "正在构建 Server DLL..." -ForegroundColor Yellow
Push-Location $ServerDir
cargo build --release --target x86_64-pc-windows-msvc
Copy-Item "target\x86_64-pc-windows-msvc\release\winlogon.dll" `
    -Destination "$ResourcesDir\FaceWinUnlock-Tauri.dll"
Write-Host "Server DLL 构建完成" -ForegroundColor Green
Pop-Location

# 2. 下载 ONNX 模型文件
Write-Host "正在下载 ONNX 模型文件..." -ForegroundColor Yellow
Push-Location $ResourcesDir

# 人脸检测模型
$FaceDetectionModel = "face_detection_yunet_2023mar.onnx"
if (-not (Test-Path $FaceDetectionModel)) {
    $Url = "https://modelscope.cn/api/v1/models/iic/cv_manual_face-liveness_flrgb/repo?path=face_detection_yunet_2023mar.onnx"
    Invoke-WebRequest -Uri $Url -OutFile $FaceDetectionModel -UseBasicParsing
    Write-Host "人脸检测模型下载完成" -ForegroundColor Green
} else {
    Write-Host "人脸检测模型已存在，跳过下载" -ForegroundColor Cyan
}

# 人脸识别模型
$FaceRecognitionModel = "face_recognition_sface_2021dec.onnx"
if (-not (Test-Path $FaceRecognitionModel)) {
    $Url = "https://github.com/opencv/opencv_zoo/raw/master/models/face_recognition_sface/face_recognition_sface_2021dec.onnx"
    Invoke-WebRequest -Uri $Url -OutFile $FaceRecognitionModel -UseBasicParsing
    Write-Host "人脸识别模型下载完成" -ForegroundColor Green
} else {
    Write-Host "人脸识别模型已存在，跳过下载" -ForegroundColor Cyan
}

Pop-Location

# 3. OpenCV DLL 会在构建时从 vcpkg 自动复制
Write-Host "OpenCV DLL 将在构建时从 vcpkg 自动复制" -ForegroundColor Cyan

Write-Host "所有资源准备完成！" -ForegroundColor Green
Get-ChildItem $ResourcesDir | Format-Table Name, Length, LastWriteTime