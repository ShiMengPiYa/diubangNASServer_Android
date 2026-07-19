# Contributing

Thank you for your interest in contributing to **DiuBangFileS** Android (NASServer).

## Getting started

1. Fork the repository and clone your fork.
2. Install Flutter (Dart ^3.10.7 per `pubspec.yaml`) and the Android SDK.
3. Run `flutter pub get`.
4. Connect a device or start an emulator, then run:

   ```powershell
   flutter run
   ```

5. Run tests: `flutter test`
6. Run the analyzer: `flutter analyze lib`

## Build dependencies (media_kit)

Android builds need libmpv JARs from GitHub. Gradle downloads them during `assembleRelease`, but mirrors can return empty files (`zip file is empty` / `MD5 mismatch`).

**Recommended (same idea as Windows server `tool/bootstrap_windows.ps1`):**

```powershell
.\tool\bootstrap_media_kit_android.ps1
flutter build apk --release
```

Force re-download after a failed build:

```powershell
.\tool\bootstrap_media_kit_android.ps1 -Force
```

### Local HTTP proxy (one-line switch)

Java/Gradle does not use the OS system proxy by default. To route Gradle and the bootstrap script through Clash / V2RayN (or similar) on this machine, flip one flag in `android/gradle.properties`:

```properties
localProxyEnabled=true
localProxyHost=127.0.0.1
localProxyPort=7890
```

Set `localProxyEnabled=false` to turn it off. Set `localProxyPort` to your client's **HTTP or mixed** port (not SOCKS). When enabled, Gradle dependency resolution and libmpv JAR downloads both use that proxy to reach `github.com` directly (mirror prefix is ignored). A TUN-mode VPN can make this switch unnecessary.

### GitHub mirror prefix (no local proxy)

If downloads are slow or blocked and you are not using `localProxyEnabled`, set a mirror prefix in `android/gradle.properties`:

```properties
githubMirrorPrefix=https://ghproxy.net/
```

Other mirrors: `https://ghfast.top/` · `https://mirror.ghproxy.com/` · leave empty for direct GitHub.

Gradle itself may use a regional mirror in `gradle-wrapper.properties`; adjust for your network if needed.

## Pull requests

- Keep changes focused; one logical change per PR when possible.
- Add or update tests for behavior changes.
- Ensure `flutter analyze lib` and `flutter test` pass locally before opening a PR.
- Do not include secrets, keystores, debug log dumps, or personal network identifiers in commits.

## Code style

- Follow existing patterns under `lib/core` and `lib/features`.
- Use the established feature layout: `data/`, `domain/`, `application/`, `presentation/` where applicable.
- Prefer meaningful names over comments that restate the code.

## Security

See [SECURITY.md](SECURITY.md) before reporting or fixing security-sensitive areas (owner credentials, TLS, Relay data scope).

## Related repositories

- Windows desktop server: [DiuBangNASServer](https://github.com/DianDanHuaJuan/DiuBangNASServer)
- Companion client: [DiuBangNASClient](https://github.com/DianDanHuaJuan/DiuBangNASClient)

## Questions

Open a GitHub issue for bugs or feature discussions. For security issues, follow SECURITY.md instead of filing a public issue with exploit details.
