#!/bin/bash
# 模型下载脚本 - 独立的模型文件下载工具 (Linux/Mac)

set -e

echo "FaceWinUnlock 模型下载工具"
echo "========================="

# 设置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
UI_DIR="$PROJECT_ROOT/UI"
RESOURCES_DIR="$UI_DIR/src-tauri/resources"

# 创建资源目录
mkdir -p "$RESOURCES_DIR"

echo "目标目录: $RESOURCES_DIR"

# 下载函数
download_model() {
    local name="$1"
    local filename="$2"
    local url="$3"
    local size="$4"

    local filepath="$RESOURCES_DIR/$filename"

    if [ -f "$filepath" ]; then
        echo "✓ $name 已存在"
        return 0
    fi

    echo "↓ 正在下载 $name..."
    echo "  文件: $filename"
    echo "  大小: $size"
    echo "  URL: $url"

    local max_retries=5
    local retry_count=0
    local success=false

    while [ "$success" = false ] && [ $retry_count -lt $max_retries ]; do
        retry_count=$((retry_count + 1))
        echo "  尝试 $retry_count/$max_retries..."

        if curl -L -f -o "$filepath" \
            --connect-timeout 30 \
            --max-time 600 \
            --retry 3 \
            --retry-delay 10 \
            --retry-max-time 600 \
            --show-error \
            "$url"; then

            if [ -f "$filepath" ]; then
                local file_size=$(du -h "$filepath" | cut -f1)
                echo "  ✓ 下载成功 ($file_size)"
                success=true
            else
                echo "  ✗ 文件未创建"
                rm -f "$filepath"
            fi
        else
            echo "  ✗ 下载失败"
            rm -f "$filepath"
        fi

        if [ "$success" = false ] && [ $retry_count -lt $max_retries ]; then
            local wait_time=$((retry_count * 10))
            if [ $wait_time -gt 30 ]; then
                wait_time=30
            fi
            echo "  等待 $wait_time 秒后重试..."
            sleep $wait_time
        fi
    done

    if [ "$success" = true ]; then
        return 0
    else
        return 1
    fi
}

# 下载所有模型
success_count=0
failed_models=()

# 人脸检测模型 (YuNet)
if download_model \
    "人脸检测模型" \
    "face_detection_yunet_2023mar.onnx" \
    "https://github.com/opencv/opencv_zoo/releases/download/v20231218/face_detection_yunet_2023mar.onnx" \
    "~3MB"; then
    success_count=$((success_count + 1))
else
    failed_models+=("人脸检测模型")
fi

# 人脸识别模型 (SFace)
if download_model \
    "人脸识别模型 (SFace)" \
    "face_recognition_sface_2021dec.onnx" \
    "https://github.com/opencv/opencv_zoo/releases/download/v20231218/face_recognition_sface_2021dec.onnx" \
    "~9MB"; then
    success_count=$((success_count + 1))
else
    failed_models+=("人脸识别模型 (SFace)")
fi

# 显示结果
echo ""
echo "========================="
echo "下载完成!"

total_models=2

if [ $success_count -eq $total_models ]; then
    echo "✓ 所有模型下载成功"
else
    echo "✗ 部分模型下载失败"
    echo "成功: $success_count/$total_models"
    echo "失败: ${#failed_models[@]}"

    if [ ${#failed_models[@]} -gt 0 ]; then
        echo "失败的模型:"
        for model in "${failed_models[@]}"; do
            echo "  - $model"
        done
    fi

    echo ""
    echo "手动下载指南:"
    echo "1. 访问: https://github.com/opencv/opencv_zoo/releases"
    echo "2. 下载以下文件:"
    echo "   - face_detection_yunet_2023mar.onnx"
    echo "   - face_recognition_sface_2021dec.onnx"
    echo "3. 将文件复制到: $RESOURCES_DIR"
fi

echo ""
echo "资源目录内容:"
ls -lh "$RESOURCES_DIR" | grep -E "\.onnx|\.dll" | awk '{print "  " $9 " (" $5 ")"}'

if [ $success_count -eq $total_models ]; then
    exit 0
else
    exit 1
fi
