# 模型下载脚本 - 独立的模型文件下载工具

$ErrorActionPreference = "Stop"

Write-Host "FaceWinUnlock 模型下载工具" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

# 设置变量
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$UIDir = Join-Path $ProjectRoot "UI"
$ResourcesDir = Join-Path $UIDir "src-tauri\resources"

# 创建资源目录
New-Item -ItemType Directory -Force -Path $ResourcesDir | Out-Null

Write-Host "目标目录: $ResourcesDir" -ForegroundColor Gray

# 模型配置
$Models = @(
    @{
        Name = "人脸检测模型"
        FileName = "face_detection_yunet_2023mar.onnx"
        Url = "https://github.com/opencv/opencv_zoo/releases/download/v20231218/face_detection_yunet_2023mar.onnx"
        Size = ~3MB
    },
    @{
        Name = "人脸识别模型"
        FileName = "face_recognition_sface_2021dec.onnx"
        Url = "https://github.com/opencv/opencv_zoo/releases/download/v20231218/face_recognition_sface_2021dec.onnx"
        Size = ~9MB
    }
)

# 下载函数
function Download-Model {
    param (
        [string]$Name,
        [string]$FileName,
        [string]$Url,
        [string]$Size
    )

    $FilePath = Join-Path $ResourcesDir $FileName

    if (Test-Path $FilePath) {
        Write-Host "✓ $Name 已存在" -ForegroundColor Green
        return $true
    }

    Write-Host "↓ 正在下载 $Name..." -ForegroundColor Yellow
    Write-Host "  文件: $FileName" -ForegroundColor Gray
    Write-Host "  大小: $Size" -ForegroundColor Gray
    Write-Host "  URL: $Url" -ForegroundColor Gray

    $MaxRetries = 5
    $RetryCount = 0
    $Success = $false

    while (-not $Success -and $RetryCount -lt $MaxRetries) {
        try {
            $RetryCount++
            Write-Host "  尝试 $RetryCount/$MaxRetries..." -ForegroundColor Cyan

            # 使用 curl 而不是 Invoke-WebRequest，因为它对大文件更可靠
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
                    Write-Host "  ✓ 下载成功 ($([math]::Round($fileSize / 1MB, 2)) MB)" -ForegroundColor Green
                    $Success = $true
                } else {
                    Write-Host "  ✗ 文件未创建" -ForegroundColor Red
                }
            } else {
                Write-Host "  ✗ 下载失败 (退出码: $($process.ExitCode))" -ForegroundColor Red
                if (Test-Path $FilePath) {
                    Remove-Item $FilePath -Force
                }
            }
        } catch {
            Write-Host "  ✗ 下载异常: $_" -ForegroundColor Red
            if (Test-Path $FilePath) {
                Remove-Item $FilePath -Force
            }
        }

        if (-not $Success -and $RetryCount -lt $MaxRetries) {
            $waitTime = [math]::Min(10 * $RetryCount, 30)
            Write-Host "  等待 $waitTime 秒后重试..." -ForegroundColor Yellow
            Start-Sleep -Seconds $waitTime
        }
    }

    return $Success
}

# 下载所有模型
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

# 显示结果
Write-Host ""
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "下载完成!" -ForegroundColor Cyan

if ($successCount -eq $Models.Count) {
    Write-Host "✓ 所有模型下载成功" -ForegroundColor Green
} else {
    Write-Host "✗ 部分模型下载失败" -ForegroundColor Yellow
    Write-Host "成功: $successCount/$($Models.Count)" -ForegroundColor Yellow
    Write-Host "失败: $($failedModels.Count)" -ForegroundColor Yellow
    if ($failedModels.Count -gt 0) {
        Write-Host "失败的模型:" -ForegroundColor Yellow
        foreach ($model in $failedModels) {
            Write-Host "  - $model" -ForegroundColor Red
        }
    }
    Write-Host ""
    Write-Host "手动下载指南:" -ForegroundColor Yellow
    Write-Host "1. 访问: https://github.com/opencv/opencv_zoo/releases" -ForegroundColor Gray
    Write-Host "2. 下载以下文件:" -ForegroundColor Gray
    foreach ($model in $Models) {
        Write-Host "   - $($model.FileName)" -ForegroundColor Gray
    }
    Write-Host "3. 将文件复制到: $ResourcesDir" -ForegroundColor Gray
}

Write-Host ""
Write-Host "资源目录内容:" -ForegroundColor Cyan
Get-ChildItem $ResourcesDir | ForEach-Object {
    $size = [math]::Round($_.Length / 1MB, 2)
    Write-Host "  $($_.Name.PadRight(50)) $size MB" -ForegroundColor Gray
}

exit $(if ($successCount -eq $Models.Count) { 0 } else { 1 })