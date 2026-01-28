fn main() {
    // 请求管理员权限
    // 代码来自：https://github.com/tauri-apps/tauri/issues/7173
    let mut windows = tauri_build::WindowsAttributes::new();
    windows = windows.app_manifest(
        r#"
    <assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
    <dependency>
        <dependentAssembly>
        <assemblyIdentity
            type="win32"
            name="Microsoft.Windows.Common-Controls"
            version="6.0.0.0"
            processorArchitecture="*"
            publicKeyToken="6595b64144ccf1df"
            language="*"
        />
        </dependentAssembly>
    </dependency>
    <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
        <security>
            <requestedPrivileges>
                <requestedExecutionLevel level="requireAdministrator" uiAccess="false" />
            </requestedPrivileges>
        </security>
    </trustInfo>
    </assembly>
    "#,
    );
    tauri_build::try_build(tauri_build::Attributes::new().windows_attributes(windows))
        .expect("failed to run build script");

    // 配置 OpenCV 使用动态链接
    // 确保 opencv crate 使用 vcpkg 安装的动态链接版本
    if std::env::var("OPENCV_LINK_LIBS").is_err() {
        std::env::set_var("OPENCV_LINK_LIBS", "dylib");
    }

    // 设置 OpenCV_DIR 指向 vcpkg 安装路径
    if let Ok(opencv_dir) = std::env::var("OpenCV_DIR") {
        println!("cargo:rustc-env=OpenCV_DIR={}", opencv_dir);
    }
}
