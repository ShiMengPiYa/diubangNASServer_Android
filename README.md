# DiuBangFileS (NASServer)

面向 **Android** 的 NAS 服务端（Flutter）：围绕用户选定的共享目录提供 HTTPS 控制面 API、WebDAV、Relay、设备配对，以及共享目录内图片/视频的预览与缩略图能力。

**许可证：** [MIT](LICENSE) · **版本：** 1.0.0

**配套客户端：** [DiuBangNASClient](https://github.com/DianDanHuaJuan/DiuBangNASClient)

## 功能特性

- 用户选定共享目录；额外提供 MediaStore 只读视图 `/dav/library`
- WebDAV 文件访问（`/dav/fs`）
- 控制面 REST API 与 WebSocket 实时通道
- 共享目录内图片/视频预览与缩略图（无服务端 HLS 转码）
- Relay：以 NAS 服务端为中转的设备间文件互传
- HTTPS 配对二维码（NASPAIR3）与设备凭据登记
- 前台服务保持后台运行；省电优化引导

## 环境要求

- Flutter SDK，兼容 **Dart ^3.10.7**（见 `pubspec.yaml`）
- **Android** 设备或模拟器（`targetSdk` 见 `android/app/build.gradle.kts`）
- **Windows 桌面版：** [DiuBangNASServer](https://github.com/DianDanHuaJuan/DiuBangNASServer)
- 配套 [DiuBangNASClient](https://github.com/DianDanHuaJuan/DiuBangNASClient)

## 快速开始

1. 从 GitHub 克隆仓库：

   ```powershell
   git clone https://github.com/DianDanHuaJuan/diubangNASServer_Android.git
   cd diubangNASServer_Android
   ```

2. 安装依赖：

   ```powershell
   flutter pub get
   ```

3. **首次构建说明：** Android 构建会通过 Gradle 拉取 [media_kit](https://github.com/media-kit/media-kit) 所需的 libmpv 原生库（见 `third_party/media_kit_libs_android_video`）。建议先运行 `.\tool\bootstrap_media_kit_android.ps1` 预下载并校验；若 GitHub 下载较慢或失败，可在 `android/gradle.properties` 将 `localProxyEnabled=true`（走本机 Clash 等），或调整 `githubMirrorPrefix`（详见 [CONTRIBUTING.md](CONTRIBUTING.md)）。

4. 连接设备并运行：

   ```powershell
   flutter run
   ```

   首次启动会生成自签 TLS 证书，并创建默认管理员账户 **`admin` / `admin`**。请在可信局域网内尽快于应用内修改密码。

5. 开发检查：

   ```powershell
   flutter analyze lib
   flutter test
   ```

## Android Release APK

```powershell
flutter build apk --release 
```

未配置 release 签名时，构建可能使用 debug keystore。请勿将 debug 签名的 APK 分发给最终用户。详见 [SECURITY.md](SECURITY.md)。

## Android 构建故障排除

| 现象 | 处理 |
|------|------|
| media_kit / libmpv 下载失败、MD5 mismatch、`zip file is empty` | 先运行 `.\tool\bootstrap_media_kit_android.ps1 -Force`；或在 `android/gradle.properties` 设 `localProxyEnabled=true`（本机 Clash 等 HTTP 端口，默认 `127.0.0.1:7890`）后重试；也可调整 `githubMirrorPrefix`（或留空直连 GitHub）；`flutter clean` 后重试 |
| Gradle / GitHub 下载需走本机代理 | 将 `android/gradle.properties` 中 `localProxyEnabled` 改为 `true`，`localProxyPort` 填 Clash 等的 **HTTP/mixed** 端口（勿填 SOCKS）；构建日志出现 `[localProxy] enabled …` / `downloading via …` 即表示生效。若本机已用 TUN，可不依赖此开关 |
| Gradle 分发包下载慢 | `gradle-wrapper.properties` 使用镜像；或开启上述 `localProxyEnabled` |
| `flutter pub get` 失败 | 检查 Flutter/Dart 版本与 `pubspec.yaml` 中 `^3.10.7` 一致 |
| Release APK 无法安装 | 确认未混用 debug 签名；自行配置 `key.properties` 与 release keystore |

## 平台差异（相对 Windows 版）

| 能力 | Android 本仓库 |
|------|----------------|
| HLS 转码 | 不支持（`capabilities.hls: false`） |
| MediaStore `/dav/library` | 支持 |
| 前台服务 / 省电引导 | 支持 |
| 托盘 / 开机自启 | 不适用（见 Windows 仓库） |

## 贡献

详见 [CONTRIBUTING.md](CONTRIBUTING.md)。提交 Pull Request 前请确保 `flutter analyze lib` 和 `flutter test` 通过。

## 更新日志

详见 [CHANGELOG.md](CHANGELOG.md)。

## 第三方组件

本仓库源码为 [MIT](LICENSE)。Release 构建另含以下组件（详见 [THIRD_PARTY_NOTICES.txt](THIRD_PARTY_NOTICES.txt)）：

- [libmpv](https://github.com/media-kit/media-kit) — 本地视频预览（Android media_kit 原生库，LGPL v2.1+）

## 安全

详见 [SECURITY.md](SECURITY.md)。切勿提交生产凭据、keystore 或私有调试日志。
