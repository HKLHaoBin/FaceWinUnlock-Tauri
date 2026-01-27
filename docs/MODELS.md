# 模型文件下载指南

如果自动下载失败，您可以按照以下步骤手动下载模型文件。

## 所需模型文件

1. **人脸检测模型** (YuNet)
   - 文件名: `face_detection_yunet_2023mar.onnx`
   - 大小: ~3 MB
   - 用途: 检测图像中的人脸位置和关键点

2. **人脸识别模型** (SFace)
   - 文件名: `face_recognition_sface_2021dec.onnx`
   - 大小: ~9 MB
   - 用途: 提取人脸特征向量，用于人脸比对

## 下载方法

### 方法 1: 从 GitHub Releases 下载（推荐）

1. 访问 [OpenCV Zoo Releases](https://github.com/opencv/opencv_zoo/releases)
2. 下载最新版本 (v20231218 或更高版本)
3. 在发布文件中找到以下文件：
   - `face_detection_yunet_2023mar.onnx`
   - `face_recognition_sface_2021dec.onnx`

### 方法 2: 使用 curl 命令

```bash
# 下载人脸检测模型
curl -L -o face_detection_yunet_2023mar.onnx \
  https://github.com/opencv/opencv_zoo/releases/download/v20231218/face_detection_yunet_2023mar.onnx

# 下载人脸识别模型
curl -L -o face_recognition_sface_2021dec.onnx \
  https://github.com/opencv/opencv_zoo/releases/download/v20231218/face_recognition_sface_2021dec.onnx
```

### 方法 3: 使用 PowerShell

```powershell
# 下载人脸检测模型
Invoke-WebRequest -Uri `
  "https://github.com/opencv/opencv_zoo/releases/download/v20231218/face_detection_yunet_2023mar.onnx" `
  -OutFile "face_detection_yunet_2023mar.onnx"

# 下载人脸识别模型
Invoke-WebRequest -Uri `
  "https://github.com/opencv/opencv_zoo/releases/download/v20231218/face_recognition_sface_2021dec.onnx" `
  -OutFile "face_recognition_sface_2021dec.onnx"
```

## 安装位置

下载完成后，将模型文件复制到以下位置：

**Windows:**
```
[软件安装目录]\resources\
```

**开发环境:**
```
FaceWinUnlock-Tauri\UI\src-tauri\resources\
```

## 验证安装

检查以下文件是否存在于 resources 目录：

```
resources/
├── face_detection_yunet_2023mar.onnx      # 人脸检测模型
├── face_recognition_sface_2021dec.onnx    # 人脸识别模型
└── FaceWinUnlock-Tauri.dll                # WinLogon DLL
```

## 使用自动下载脚本

项目提供了自动下载脚本，您可以在以下位置找到：

- **Windows:** `scripts\download-models.ps1`
- **Linux/Mac:** `scripts\download-models.sh` (需要创建)

运行自动下载脚本：

**Windows PowerShell:**
```powershell
.\scripts\download-models.ps1
```

## 故障排除

### 下载速度慢

如果从 GitHub 下载速度较慢，可以尝试：

1. 使用 GitHub 代理镜像
2. 使用 VPN 加速
3. 从其他可靠的源下载模型文件

### 验证文件完整性

下载完成后，可以检查文件大小：

```bash
# Windows PowerShell
Get-ChildItem face_detection_yunet_2023mar.onnx | Select-Object Length
Get-ChildItem face_recognition_sface_2021dec.onnx | Select-Object Length

# Linux/Mac
ls -lh face_detection_yunet_2023mar.onnx
ls -lh face_recognition_sface_2021dec.onnx
```

预期大小：
- `face_detection_yunet_2023mar.onnx`: ~3 MB
- `face_recognition_sface_2021dec.onnx`: ~9 MB

### 模型格式错误

确保下载的是 `.onnx` 格式的文件，不是压缩包或其他格式。如果下载的文件是 `.zip`，需要先解压。

## 技术支持

如果仍然遇到问题，可以：

1. 查看 GitHub Issues：https://github.com/HKLHaoBin/FaceWinUnlock-Tauri/issues
2. 检查软件日志文件
3. 联系开发者获取帮助

## 模型来源

- **项目**: [OpenCV Zoo](https://github.com/opencv/opencv_zoo)
- **许可证**: Apache 2.0
- **官方文档**: https://docs.opencv.org/4.x/d1/d89/tutorial_face.html

---

**注意**: 模型文件仅在本地使用，不会上传到任何服务器。