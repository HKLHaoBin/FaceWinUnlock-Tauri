#!/bin/bash
# 资源准备脚本 - 用于 CI/CD 环境

set -e

echo "开始准备构建资源..."

# 设置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SERVER_DIR="$PROJECT_ROOT/Server"
UI_DIR="$PROJECT_ROOT/UI"
RESOURCES_DIR="$UI_DIR/src-tauri/resources"

# 创建资源目录
mkdir -p "$RESOURCES_DIR"

# 1. 构建 Server DLL
echo "正在构建 Server DLL..."
cd "$SERVER_DIR"
cargo build --release --target x86_64-pc-windows-msvc
cp target/x86_64-pc-windows-msvc/release/winlogon.dll "$RESOURCES_DIR/FaceWinUnlock-Tauri.dll"
echo "Server DLL 构建完成"

# 2. 下载 ONNX 模型文件
echo "正在下载 ONNX 模型文件..."
cd "$RESOURCES_DIR"

# 人脸检测模型
if [ ! -f "face_detection_yunet_2023mar.onnx" ]; then
    curl -L -o face_detection_yunet_2023mar.onnx \
        "https://modelscope.cn/api/v1/models/iic/cv_manual_face-liveness_flrgb/repo?path=face_detection_yunet_2023mar.onnx"
    echo "人脸检测模型下载完成"
else
    echo "人脸检测模型已存在，跳过下载"
fi

# 人脸识别模型
if [ ! -f "face_recognition_sface_2021dec.onnx" ]; then
    curl -L -o face_recognition_sface_2021dec.onnx \
        "https://github.com/opencv/opencv_zoo/raw/master/models/face_recognition_sface/face_recognition_sface_2021dec.onnx"
    echo "人脸识别模型下载完成"
else
    echo "人脸识别模型已存在，跳过下载"
fi

# 3. OpenCV DLL 会在构建时从 vcpkg 自动复制
echo "OpenCV DLL 将在构建时从 vcpkg 自动复制"

echo "所有资源准备完成！"
ls -lh "$RESOURCES_DIR"