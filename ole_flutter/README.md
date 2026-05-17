# ole_flutter

OLE 影视的 Flutter 跨端客户端。支持 **Windows / Android / Android 平板 / macOS / Linux**。

爬虫逻辑直接在 Dart 内实现（端口自 `ole_web/server.js`），客户端独立运行，**不依赖 Node 后端**。

## 功能对齐 ole_web

- 首页四分类（动漫 / 电影 / 连续剧 / 综艺）+ "更多"
- 分类列表分页
- 搜索 + 分页
- 详情页：HLS 播放器、集数列表、续播、片头/片尾跳过（自动跳过 + 手动标记 + 手动输入）、上下集切换、键盘控制（空格 / ←→）、收藏、悬浮窗
- 全平台 localStorage 等价存储：收藏、进度、片头片尾设置
- 收藏的卡片自动排到列表前面

## 技术栈

| 用途 | 包 |
|------|----|
| HTTP | `dio` |
| HTML 解析 | `html` |
| 播放器 | `media_kit` + `media_kit_video` + `media_kit_libs_video` (基于 libmpv) |
| 状态 | `provider` |
| 路由 | `go_router` |
| 存储 | `shared_preferences` |
| 图片缓存 | `cached_network_image` |

## 运行

项目使用 [FVM](https://fvm.app/) 管理 Flutter 版本（当前 3.27.2）。

```bash
# 安装依赖
fvm flutter pub get

# Windows（首次需开启 Windows 开发者模式以支持插件 symlink）
fvm flutter run -d windows

# Android（先 adb devices 看设备）
fvm flutter run -d <device_id>

# macOS
fvm flutter run -d macos

# Linux
fvm flutter run -d linux
```

### Windows 首次运行

`flutter pub get` 末尾若报 `Building with plugins requires symlink support` —— 这是 media_kit 等含原生插件包要求 Windows 开启**开发者模式**：

1. 打开「设置 → 系统 → 开发者选项」，或运行 `start ms-settings:developers`
2. 启用"开发者模式"
3. 重新跑 `fvm flutter pub get`

### Android 注意

- 配置已设 `minSdk = 24`（media_kit 要求）
- 已声明 `INTERNET` / `WAKE_LOCK` 权限和 `usesCleartextTraffic="true"`（视频源可能是 http）
- 已开启 `android:supportsPictureInPicture="true"`（系统级画中画）

### macOS 注意

- 已在 entitlements 加上 `network.client`
- 已在 `Info.plist` 加上 `NSAllowsArbitraryLoads`

### Java 警告

若 `flutter create` 提示 Java 与 Gradle 不兼容，按提示配置 JDK 17：

```bash
fvm flutter config --jdk-dir=<path-to-jdk-17>
```

## 打包

```bash
# Windows
fvm flutter build windows --release
# 产物：build/windows/x64/runner/Release/

# Android APK
fvm flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk

# Android App Bundle（上架用）
fvm flutter build appbundle --release

# macOS
fvm flutter build macos --release

# Linux
fvm flutter build linux --release
```

## 发布 (GitHub Actions)

仓库根目录 `.github/workflows/release.yml` 配置好了三平台并行构建 + 自动发 Release。

**触发方式 1 — 打 tag**：

```bash
git tag v0.1.0
git push origin v0.1.0
```

**触发方式 2 — 手动**：到 GitHub 仓库 → Actions → "Build & Release" → Run workflow，自己填 tag 名。

构建大约 10–15 分钟（三平台并行），完成后产物自动挂到 [Releases 页面](../../releases)：

- `ole_flutter-windows-setup.exe` — Inno Setup 安装器，双击安装到 Program Files，自带桌面/开始菜单快捷方式和卸载入口
- `ole_flutter-macos.dmg` — 双击挂载后拖 `.app` 到 Applications；首次启动右键 → 打开（绕过 Gatekeeper，因为没正式签名）
- `ole_flutter-android.apk` — 用 debug keystore 签的，能 sideload 安装

> 注意：只要任何一个平台的 build 失败，整个 release job 会被跳过，Release 页面不会出现新版本。
> 想确认是哪个 job 失败，到 Actions → 对应 run 详情查看；产物 zip / dmg / apk 也能在那里直接下载到（保留 7 天）。

正式签名（Apple Developer 证书 / Android release keystore）按需后续再加。

CI 的 Flutter 版本跟 stable 通道走最新稳定版，不锁具体版本——这是为了跟得上 media_kit 等
平台插件的 Flutter Android engine 接口要求。本地用 FVM 时建议 `fvm install stable && fvm use stable` 保持同步。

## 目录结构

```
lib/
├── main.dart                       # 入口
├── app.dart                        # MaterialApp.router
├── app_router.dart                 # GoRouter 路由
├── core/
│   ├── constants.dart              # BASE / UA / 广告域名 / 分类映射
│   ├── theme.dart                  # 深色主题
│   ├── responsive.dart             # 断点 + 列数
│   └── format.dart                 # 时间/热度格式化
├── data/
│   ├── models/                     # VideoItem / VideoDetail / Episode / PagedResult
│   ├── scraper/
│   │   ├── http_client.dart        # dio 单例
│   │   ├── ad_filter.dart
│   │   └── ole_scraper.dart        # server.js 五个端点的 Dart 实现
│   └── storage/
│       ├── prefs.dart              # shared_preferences 包装
│       ├── favorites_store.dart    # ChangeNotifier
│       ├── progress_store.dart
│       └── skip_store.dart
├── features/
│   ├── home/home_page.dart
│   ├── category/category_page.dart
│   ├── search/search_page.dart
│   └── detail/
│       ├── detail_page.dart        # 播放器 + 集数 + 跳过 + 悬浮窗整合
│       └── widgets/
│           ├── player_view.dart
│           ├── episode_list.dart
│           └── skip_settings_panel.dart
└── widgets/                        # AppHeader / VideoCard / VideoGrid / Pagination / StatusView
```

## 兼容性说明

- m3u8/HLS 由 libmpv 原生解码，无需 hls.js
- 进度/收藏/跳过的 key 命名与 web 版完全一致，但 web 的 `localStorage` 与 Flutter 的 `shared_preferences` 是**不同存储**，互不可见。如需迁移历史数据另需写导入工具。
- "悬浮窗"目前实现为应用窗口内的可拖动浮动播放器（跨平台一致）；如需系统级跨窗 always-on-top（桌面）或系统画中画（Android 8.0+），可再接 `window_manager` / `floating` 等包扩展。
