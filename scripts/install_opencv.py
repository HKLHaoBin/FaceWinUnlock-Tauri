#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
OpenCV 安装和验证脚本
用于 CI/CD 环境中安装 vcpkg OpenCV 并验证安装
"""

import os
import subprocess
import sys
import time
from pathlib import Path

# 设置 Windows 控制台编码为 UTF-8
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# 配置
VCPKG_ROOT = Path(r"C:\vcpkg")
VCPKG_TRIPLET = "x64-windows-static"
MAX_RETRIES = 3
RETRY_DELAY = 30

def run_command(cmd, description, check=True):
    """运行命令并处理输出"""
    print(f"\n{'='*60}")
    print(f"[INFO] {description}")
    print(f"[CMD] {' '.join(cmd)}")
    print(f"{'='*60}")

    try:
        result = subprocess.run(
            cmd,
            check=check,
            capture_output=True,
            text=True,
            encoding='utf-8',
            errors='ignore'
        )

        if result.stdout:
            print("[STDOUT]", result.stdout)

        if result.stderr:
            print("[STDERR]", result.stderr)

        if result.returncode != 0:
            print(f"[ERROR] Command failed, return code: {result.returncode}")
            return False

        print(f"[SUCCESS] {description} succeeded")
        return True

    except subprocess.CalledProcessError as e:
        print(f"[ERROR] {description} failed: {e}")
        return False
    except Exception as e:
        print(f"[ERROR] Exception occurred while executing command: {e}")
        return False

def verify_opencv_installation():
    """验证 OpenCV 安装"""
    print(f"\n{'='*60}")
    print("[INFO] Verifying OpenCV installation...")
    print(f"{'='*60}")

    installed_dir = VCPKG_ROOT / "installed" / VCPKG_TRIPLET

    # 检查是否为静态链接版本
    is_static = "static" in VCPKG_TRIPLET

    if is_static:
        # 静态链接版本：检查 .lib 文件
        lib_dir = installed_dir / "lib"

        # 首先尝试查找 opencv_world*.lib（合并版本）
        lib_files = list(lib_dir.glob("opencv_world*.lib"))

        # 如果没有找到 opencv_world*.lib，则检查模块化库文件（opencv_*.lib）
        if not lib_files:
            # 检查是否存在 OpenCV 模块化库文件
            opencv_libs = list(lib_dir.glob("opencv_*.lib"))
            # 排除一些非核心库（如 opencv_java4.lib 等）
            opencv_libs = [lib for lib in opencv_libs if lib.name.startswith(("opencv_core", "opencv_imgproc", "opencv_highgui", "opencv_imgcodecs", "opencv_video", "opencv_videoio", "opencv_dnn", "opencv_features2d", "opencv_calib3d", "opencv_objdetect", "opencv_ml", "opencv_photo", "opencv_flann", "opencv_stitching"))]

            if not opencv_libs:
                print(f"[ERROR] OpenCV static library not found in {lib_dir}")
                print(f"[INFO] Listing lib directory contents:")
                if lib_dir.exists():
                    for item in lib_dir.iterdir():
                        print(f"  - {item.name}")
                else:
                    print(f"  [Directory does not exist]")
                return False

            print(f"[SUCCESS] Found {len(opencv_libs)} OpenCV module libraries:")
            for lib in sorted(opencv_libs):
                size_mb = lib.stat().st_size / (1024 * 1024)
                print(f"  - {lib.name} ({size_mb:.2f} MB)")
        else:
            for lib in lib_files:
                size_mb = lib.stat().st_size / (1024 * 1024)
                print(f"[SUCCESS] Found OpenCV static library: {lib.name} ({size_mb:.2f} MB)")
    else:
        # 动态链接版本：检查 DLL 文件
        bin_dir = installed_dir / "bin"
        dll_files = list(bin_dir.glob("opencv_world*.dll"))

        if not dll_files:
            print(f"[ERROR] OpenCV DLL not found in {bin_dir}")
            print(f"[INFO] Listing bin directory contents:")
            if bin_dir.exists():
                for item in bin_dir.iterdir():
                    print(f"  - {item.name}")
            else:
                print(f"  [Directory does not exist]")
            return False

        for dll in dll_files:
            size_mb = dll.stat().st_size / (1024 * 1024)
            print(f"[SUCCESS] Found OpenCV DLL: {dll.name} ({size_mb:.2f} MB)")

    # 检查 OpenCVConfig.cmake
    share_dir = installed_dir / "share" / "opencv4"
    config_file = share_dir / "OpenCVConfig.cmake"

    if not config_file.exists():
        print(f"[ERROR] OpenCVConfig.cmake not found")
        print(f"[INFO] Expected location: {config_file}")
        print(f"[INFO] Listing share directory contents:")
        if share_dir.parent.exists():
            for item in share_dir.parent.iterdir():
                print(f"  - {item.name}")
        return False

    print(f"[SUCCESS] Found OpenCVConfig.cmake: {config_file}")

    # 设置环境变量
    env_file = os.environ.get("GITHUB_ENV")
    if env_file:
        with open(env_file, 'a', encoding='utf-8') as f:
            f.write(f"OpenCV_DIR={share_dir}\n")
        print(f"[SUCCESS] Set OpenCV_DIR environment variable: {share_dir}")

    return True

def install_opencv():
    """安装 OpenCV"""
    print(f"\n{'='*60}")
    print("[INFO] Starting OpenCV installation...")
    print(f"{'='*60}")

    for attempt in range(1, MAX_RETRIES + 1):
        print(f"\n[INFO] Attempt {attempt}/{MAX_RETRIES}")

        cmd = [
            str(VCPKG_ROOT / "vcpkg.exe"),
            "install",
            f"opencv:{VCPKG_TRIPLET}"
        ]

        if run_command(cmd, f"Installing OpenCV (attempt {attempt})", check=False):
            # Installation succeeded, verify it
            if verify_opencv_installation():
                print("\n[SUCCESS] OpenCV installation and verification succeeded")
                return True
            else:
                print(f"\n[WARNING] OpenCV installation completed but verification failed")
        else:
            print(f"\n[WARNING] OpenCV installation failed (attempt {attempt})")

        if attempt < MAX_RETRIES:
            print(f"[INFO] Waiting {RETRY_DELAY} seconds before retry...")
            time.sleep(RETRY_DELAY)

    print("\n[ERROR] OpenCV installation failed, maximum retries reached")
    return False

def integrate_vcpkg():
    """集成 vcpkg"""
    cmd = [str(VCPKG_ROOT / "vcpkg.exe"), "integrate", "install"]
    return run_command(cmd, "Integrating vcpkg")

def main():
    """主函数"""
    print(f"\n{'='*60}")
    print("[INFO] OpenCV Installation Script")
    print(f"[INFO] VCPKG_ROOT: {VCPKG_ROOT}")
    print(f"[INFO] VCPKG_TRIPLET: {VCPKG_TRIPLET}")
    print(f"{'='*60}")

    # Check if vcpkg exists
    if not VCPKG_ROOT.exists():
        print(f"[ERROR] vcpkg not found at: {VCPKG_ROOT}")
        sys.exit(1)

    # Check if vcpkg.exe exists
    vcpkg_exe = VCPKG_ROOT / "vcpkg.exe"
    if not vcpkg_exe.exists():
        print(f"[ERROR] vcpkg.exe not found at: {vcpkg_exe}")
        sys.exit(1)

    # Integrate vcpkg
    if not integrate_vcpkg():
        print("[ERROR] vcpkg integration failed")
        sys.exit(1)

    # Install OpenCV
    if not install_opencv():
        print("[ERROR] OpenCV installation failed")
        sys.exit(1)

    print("\n[SUCCESS] All steps completed")

if __name__ == "__main__":
    main()