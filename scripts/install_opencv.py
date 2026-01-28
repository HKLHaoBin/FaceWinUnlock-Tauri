#!/usr/bin/env python3
"""
OpenCV 安装和验证脚本
用于 CI/CD 环境中安装 vcpkg OpenCV 并验证安装
"""

import os
import subprocess
import sys
import time
from pathlib import Path

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
            print(f"[ERROR] 命令失败，返回码: {result.returncode}")
            return False

        print(f"[SUCCESS] {description} 成功")
        return True

    except subprocess.CalledProcessError as e:
        print(f"[ERROR] {description} 失败: {e}")
        return False
    except Exception as e:
        print(f"[ERROR] 执行命令时发生异常: {e}")
        return False

def verify_opencv_installation():
    """验证 OpenCV 安装"""
    print(f"\n{'='*60}")
    print("[INFO] 验证 OpenCV 安装...")
    print(f"{'='*60}")

    installed_dir = VCPKG_ROOT / "installed" / VCPKG_TRIPLET

    # 检查 DLL 文件
    bin_dir = installed_dir / "bin"
    dll_files = list(bin_dir.glob("opencv_world*.dll"))

    if not dll_files:
        print(f"[ERROR] 在 {bin_dir} 中未找到 OpenCV DLL")
        print(f"[INFO] 列出 bin 目录内容:")
        if bin_dir.exists():
            for item in bin_dir.iterdir():
                print(f"  - {item.name}")
        else:
            print(f"  [目录不存在]")
        return False

    for dll in dll_files:
        size_mb = dll.stat().st_size / (1024 * 1024)
        print(f"[SUCCESS] 找到 OpenCV DLL: {dll.name} ({size_mb:.2f} MB)")

    # 检查 OpenCVConfig.cmake
    share_dir = installed_dir / "share" / "opencv4"
    config_file = share_dir / "OpenCVConfig.cmake"

    if not config_file.exists():
        print(f"[ERROR] 未找到 OpenCVConfig.cmake")
        print(f"[INFO] 预期位置: {config_file}")
        print(f"[INFO] 列出 share 目录内容:")
        if share_dir.parent.exists():
            for item in share_dir.parent.iterdir():
                print(f"  - {item.name}")
        return False

    print(f"[SUCCESS] 找到 OpenCVConfig.cmake: {config_file}")

    # 设置环境变量
    env_file = os.environ.get("GITHUB_ENV")
    if env_file:
        with open(env_file, 'a', encoding='utf-8') as f:
            f.write(f"OpenCV_DIR={share_dir}\n")
        print(f"[SUCCESS] 已设置 OpenCV_DIR 环境变量: {share_dir}")

    return True

def install_opencv():
    """安装 OpenCV"""
    print(f"\n{'='*60}")
    print("[INFO] 开始安装 OpenCV...")
    print(f"{'='*60}")

    for attempt in range(1, MAX_RETRIES + 1):
        print(f"\n[INFO] 尝试 {attempt}/{MAX_RETRIES}")

        cmd = [
            str(VCPKG_ROOT / "vcpkg.exe"),
            "install",
            f"opencv:{VCPKG_TRIPLET}"
        ]

        if run_command(cmd, f"安装 OpenCV (尝试 {attempt})", check=False):
            # 安装成功，进行验证
            if verify_opencv_installation():
                print("\n[SUCCESS] OpenCV 安装和验证成功")
                return True
            else:
                print(f"\n[WARNING] OpenCV 安装完成但验证失败")
        else:
            print(f"\n[WARNING] OpenCV 安装失败 (尝试 {attempt})")

        if attempt < MAX_RETRIES:
            print(f"[INFO] 等待 {RETRY_DELAY} 秒后重试...")
            time.sleep(RETRY_DELAY)

    print("\n[ERROR] OpenCV 安装失败，已达到最大重试次数")
    return False

def integrate_vcpkg():
    """集成 vcpkg"""
    cmd = [str(VCPKG_ROOT / "vcpkg.exe"), "integrate", "install"]
    return run_command(cmd, "集成 vcpkg")

def main():
    """主函数"""
    print(f"\n{'='*60}")
    print("[INFO] OpenCV 安装脚本")
    print(f"[INFO] VCPKG_ROOT: {VCPKG_ROOT}")
    print(f"[INFO] VCPKG_TRIPLET: {VCPKG_TRIPLET}")
    print(f"{'='*60}")

    # 检查 vcpkg 是否存在
    if not VCPKG_ROOT.exists():
        print(f"[ERROR] vcpkg 不存在于: {VCPKG_ROOT}")
        sys.exit(1)

    # 检查 vcpkg.exe 是否存在
    vcpkg_exe = VCPKG_ROOT / "vcpkg.exe"
    if not vcpkg_exe.exists():
        print(f"[ERROR] vcpkg.exe 不存在于: {vcpkg_exe}")
        sys.exit(1)

    # 集成 vcpkg
    if not integrate_vcpkg():
        print("[ERROR] vcpkg 集成失败")
        sys.exit(1)

    # 安装 OpenCV
    if not install_opencv():
        print("[ERROR] OpenCV 安装失败")
        sys.exit(1)

    print("\n[SUCCESS] 所有步骤完成")

if __name__ == "__main__":
    main()