# FaceWinUnlock-Tauri 项目上下文文档

## 项目概览

**FaceWinUnlock-Tauri** 是一款基于 Tauri 框架开发的 Windows 面容识别解锁增强软件。该项目通过自定义 Credential Provider (DLL) 注入 Windows 登录界面，结合前端 Vue 3 和后端 OpenCV 人脸识别算法，为用户提供类似 Windows Hello 的解锁体验。

### 核心功能

- **面容识别解锁**：使用 OpenCV 进行人脸检测和特征比对
- **多账户支持**：支持本地账户和微软联机账户 (MSA)
- **系统级集成**：通过 WinLogon Credential Provider 注入登录界面
- **活体检测**：使用 ONNX 模型实现活体检测（RGB）
- **面容库管理**：支持添加、编辑、删除面容数据
- **自动化解锁**：通过命名管道实现自动化凭据注入

### 架构说明

项目采用分层架构：

```
┌─────────────────────────────────────┐
│         前端 (Vue 3)                 │
│   - Element Plus UI                  │
│   - Pinia 状态管理                   │
│   - Vue Router                       │
└─────────────────────────────────────┘
              ↓ Tauri IPC
┌─────────────────────────────────────┐
│      后端 (Rust + Tauri)            │
│   - OpenCV 人脸识别                 │
│   - SQLite 数据库                   │
│   - Windows API 调用                │
│   - 命名管道通信                     │
└─────────────────────────────────────┘
              ↓ DLL 注入
┌─────────────────────────────────────┐
│   WinLogon Credential Provider      │
│   - 系统登录界面集成                │
│   - COM 接口实现                    │
└─────────────────────────────────────┘
```

## 技术栈

### 前端技术

- **框架**：Vue 3 (Composition API)
- **UI 库**：Element Plus 2.13.0
- **状态管理**：Pinia 3.0.4
- **路由**：Vue Router 4.6.4
- **构建工具**：Vite 6.0.3
- **图标库**：@element-plus/icons-vue
- **事件总线**：mitt 3.0.1

### 后端技术

- **框架**：Tauri 2.x
- **语言**：Rust 2021 edition
- **人脸识别**：OpenCV 0.98.0
- **数据库**：SQLite 3 (通过 tauri-plugin-sql 和 r2d2_sqlite)
- **Windows API**：windows crate 0.62.2
- **序列化**：serde + bincode
- **注册表操作**：winreg 0.55.0
- **编码**：base64 0.22.1
- **日志**：tauri-plugin-log

### 系统级组件

- **WinLogon DLL**：Rust 编写的 Credential Provider
- **通信机制**：命名管道 (Named Pipe)
- **COM 接口**：ICredentialProvider, ICredentialProviderCredential
- **线程管理**：独立后台线程监听管道

## 项目结构

```
FaceWinUnlock-Tauri/
├── UI/                          # 主应用程序
│   ├── src/                     # Vue 前端源码
│   │   ├── components/          # 可复用组件
│   │   │   └── AccountAuthForm.vue
│   │   ├── hook/                # 组合式函数
│   │   │   ├── useFile.js       # 文件操作 hook
│   │   │   └── useUnlockLog.js  # 解锁日志 hook
│   │   ├── layout/              # 布局组件
│   │   │   └── MainLayout.vue
│   │   ├── router/              # 路由配置
│   │   │   └── index.js
│   │   ├── stores/              # Pinia 状态管理
│   │   │   ├── faces.js         # 面容数据状态
│   │   │   └── options.js       # 配置选项状态
│   │   ├── utils/               # 工具函数
│   │   │   ├── function.js      # 通用工具
│   │   │   ├── mitt.js          # 事件总线
│   │   │   └── sqlite.js        # 数据库操作
│   │   ├── views/               # 页面组件
│   │   │   ├── Dashboard.vue    # 控制仪表盘
│   │   │   ├── Init.vue         # 系统初始化
│   │   │   ├── Logs.vue         # 日志查看
│   │   │   ├── Options.vue      # 首选项
│   │   │   └── Faces/           # 面容管理
│   │   │       ├── Add.vue      # 添加面容
│   │   │       └── List.vue     # 面容列表
│   │   ├── App.vue              # 根组件
│   │   └── main.js              # 应用入口
│   ├── src-tauri/               # Rust 后端源码
│   │   ├── src/
│   │   │   ├── main.rs          # 应用入口
│   │   │   ├── lib.rs           # Tauri 命令注册
│   │   │   ├── proc.rs          # Windows 消息处理
│   │   │   ├── tray.rs          # 系统托盘
│   │   │   ├── modules/         # 功能模块
│   │   │   │   ├── mod.rs       # 模块导出
│   │   │   │   ├── faces.rs     # 面容识别模块
│   │   │   │   ├── init.rs      # 初始化模块
│   │   │   │   └── options.rs   # 配置模块
│   │   │   └── utils/           # 工具模块
│   │   │       ├── mod.rs       # 工具导出
│   │   │       ├── api.rs       # API 命令
│   │   │       ├── pipe.rs      # 管道通信
│   │   │       └── custom_result.rs # 自定义结果类型
│   │   ├── Cargo.toml           # Rust 依赖配置
│   │   ├── tauri.conf.json      # Tauri 配置
│   │   ├── build.rs             # 构建脚本
│   │   └── icons/               # 应用图标
│   ├── package.json             # 前端依赖
│   ├── vite.config.js           # Vite 配置
│   └── public/                  # 静态资源
├── Server/                       # WinLogon DLL 组件
│   ├── src/
│   │   ├── lib.rs               # DLL 导出
│   │   ├── CSampleProvider.rs   # 凭据提供者
│   │   ├── CSampleCredential.rs # 凭据凭据
│   │   ├── CPipeListener.rs     # 管道监听器
│   │   ├── Pipe.rs              # 管道通信
│   │   └── test.rs              # 测试代码
│   ├── Cargo.toml               # Rust 依赖配置
│   ├── exports.def              # DLL 导出定义
│   └── build/                   # 编译输出
├── data/                         # 文档和截图
├── .github/                      # GitHub 配置
│   └── workflows/
│       └── build_windows_exe.yml # CI/CD 工作流
├── README.md                     # 项目说明
└── LICENSE                       # 开源协议
```

## 构建和运行

### 前端开发

```bash
cd UI
npm install              # 安装依赖
npm run dev             # 启动开发服务器 (端口: 1420)
npm run build           # 构建生产版本
```

### Tauri 应用开发

```bash
cd UI
npm run tauri dev       # 启动 Tauri 开发模式
npm run tauri build     # 构建 Tauri 应用 (生成安装包)
```

### Windows DLL 构建

```bash
cd Server
cargo build             # 构建 Debug 版本
cargo build --release   # 构建 Release 版本
```

### CI/CD 构建

项目使用 GitHub Actions 自动构建 Windows 版本：

- **触发条件**：推送到 `main` 分支
- **运行环境**：windows-latest
- **依赖管理**：npm
- **OpenCV 安装**：通过 vcpkg 安装 (x64-windows-static)
- **构建输出**：自动创建 GitHub Release

## 开发约定

### 代码风格

- **前端**：使用 Vue 3 Composition API，遵循 Vue 风格指南
- **后端**：使用 Rust 2021 edition，遵循 Rust 官方风格指南
- **注释**：代码注释和日志主要使用中文
- **命名**：
  - 前端：使用 camelCase
  - 后端：使用 snake_case

### 前端开发规范

1. **组件组织**：
   - 可复用组件放在 `components/` 目录
   - 页面组件放在 `views/` 目录
   - 布局组件放在 `layout/` 目录

2. **状态管理**：
   - 使用 Pinia stores 管理全局状态
   - `stores/faces.js`：面容数据状态
   - `stores/options.js`：配置选项状态

3. **自定义指令**：
   - `v-face-img`：用于面容图片加载和内存管理
   - 自动释放 Blob URL，防止内存泄漏

4. **路由**：
   - 使用 Hash 模式 (`createWebHashHistory`)
   - 每个路由配置 `meta.title` 用于显示页面标题

### 后端开发规范

1. **模块组织**：
   - `modules/faces.rs`：面容识别相关命令
   - `modules/init.rs`：系统初始化相关命令
   - `modules/options.rs`：配置管理相关命令
   - `utils/api.rs`：通用 API 命令

2. **Tauri 命令注册**：
   - 所有命令在 `lib.rs` 中通过 `tauri::generate_handler!` 宏注册
   - 命令函数使用 `#[tauri::command]` 属性标注

3. **全局状态管理**：
   - 使用 `lazy_static` 定义全局变量
   - `APP_STATE`：OpenCV 资源状态
   - `DB_POOL`：数据库连接池
   - `GLOBAL_TRAY`：系统托盘实例

4. **线程安全**：
   - 使用 `Arc<Mutex<T>>` 保护共享状态
   - OpenCV 资源使用 `OpenCVResource<T>` 包装器实现 Send/Sync

5. **日志**：
   - 使用 `tauri-plugin-log` 插件
   - 日志输出到：Stdout、Webview、文件 (logs/app.log)
   - 使用本地时区

### 数据库规范

- **数据库类型**：SQLite
- **连接池**：使用 r2d2 管理连接
- **表结构**：
  - `faces`：面容数据表
  - `options`：配置选项表
- **文件存储**：
  - 面容图片：`faces/{face_token}.faceimg`
  - 数据库文件：SQLite 文件

### 资源文件管理

- **OpenCV 模型**：
  - `face_detection_yunet_2023mar.onnx`：人脸检测模型
  - `face_recognition_sface_2021dec.onnx`：人脸识别模型
- **DLL 文件**：`FaceWinUnlock-Tauri.dll` - WinLogon 组件
- **OpenCV 库**：`opencv_world4120.dll` - OpenCV 运行时库

### 安全注意事项

⚠️ **重要风险提示**：

1. **系统级操作**：
   - 项目涉及 Windows 注册表修改
   - 操作 WinLogon 进程
   - 错误可能导致系统无法登录

2. **明文传输**：
   - 命名管道通信未加密
   - 凭据在内存中短暂持有明文

3. **开发建议**：
   - 在虚拟机环境中进行开发和测试
   - 不要在生产环境或高安全要求的系统上使用
   - 部署前拍照留档以便恢复

4. **适用场景**：
   - 仅适用于个人家用电脑或开发机
   - 严禁用于存储高机密数据的环境

### 测试规范

- **单元测试**：使用 Rust 的 `#[cfg(test)]` 属性
- **集成测试**：在 `tests/` 目录中编写
- **手动测试流程**：
  1. 系统初始化
  2. 摄像头选择
  3. 面容录入
  4. 账户关联
  5. 锁屏测试
  6. 卸载流程

### 版本管理

- **版本号格式**：v0.2.1
- **发布流程**：
  1. 更新 `UI/src-tauri/tauri.conf.json` 中的版本号
  2. 更新 `README.md` 中的更新记录
  3. 提交代码到 `main` 分支
  4. GitHub Actions 自动构建并创建 Release

### 依赖管理

- **前端依赖**：通过 `npm` 管理，使用 `package-lock.json` 锁定版本
- **后端依赖**：通过 `Cargo` 管理，使用 `Cargo.lock` 锁定版本
- **OpenCV**：通过 vcpkg 安装，配置 `VCPKG_ROOT` 环境变量
- **Windows SDK**：需要安装 Visual Studio C++ 桌面开发组件

### 常见开发任务

#### 添加新的 Tauri 命令

1. 在 `UI/src-tauri/src/modules/` 中创建或编辑模块文件
2. 定义命令函数并添加 `#[tauri::command]` 属性
3. 在 `UI/src-tauri/src/lib.rs` 的 `invoke_handler!` 宏中注册命令
4. 在前端通过 `invoke()` 调用

#### 添加新的前端页面

1. 在 `UI/src/views/` 中创建 Vue 组件
2. 在 `UI/src/router/index.js` 中添加路由配置
3. 在 `UI/src/layout/MainLayout.vue` 中添加导航（如需要）

#### 修改 OpenCV 模型

1. 替换 `UI/src-tauri/tauri.conf.json` 中 `bundle.resources` 配置的模型文件路径
2. 更新 `UI/src-tauri/src/modules/faces.rs` 中的模型加载逻辑
3. 重新构建应用

#### 调试技巧

- **前端调试**：打开 DevTools（F12）
- **后端调试**：查看日志文件 `logs/app.log`
- **DLL 调试**：使用 Visual Studio 附加到 winlogon.exe 进程
- **管道调试**：使用 `PipeList` 或 `PipeViewer` 工具查看命名管道

## 已知问题和限制

1. **多账户兼容性**：Win11 非 Administrator 多账户下可能无法正常运行
2. **活体检测**：当前为 2D 识别，存在被照片/视频绕过的风险
3. **卸载流程**：需要手动执行卸载步骤，缺乏自动化脚本
4. **锁屏 UI**：受限于 Windows 机制，无法实现原生动画效果

## 相关资源

- **Tauri 文档**：https://tauri.app/
- **OpenCV Rust**：https://github.com/twistedfall/opencv-rust
- **Windows Credential Provider**：https://docs.microsoft.com/en-us/windows/win32/api/credentialprovider/
- **Vue 3 文档**：https://vuejs.org/
- **Element Plus**：https://element-plus.org/

## 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

**注意**：
- 提交前请确保代码通过编译
- 遵循项目的代码风格规范
- 添加必要的注释和文档
- 测试关键功能

## 许可证

本项目采用 MIT License 开源。详见 [LICENSE](LICENSE) 文件。

---

**生成时间**：2026-01-27
**项目版本**：v0.2.1
**维护者**：FaceWinUnlock-Tauri Team