# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Android `applicationId` / `namespace` renamed to `com.diubang.nasserver` (breaking: cannot upgrade over previous package id)
- Dart package renamed from `nas_server` to `diubang_nasserver`
- Native MethodChannel prefixes updated to `com.diubang.nasserver/*`

## [1.0.0] - 2026-07-11

### Added

- Initial open-source release for Android
- HTTPS control-plane API, WebDAV (`/dav/fs`, `/dav/library`), Relay, and Realtime WebSocket
- NASPAIR3 HTTPS pairing QR code and credential-device enrollment API
- Settings page shared directory picker and path validation (aligned with Windows)
- `POST /api/v1/auth/credential-device-enroll` for owner-credential device enrollment
- Background settings apply progress banner (`SettingsApplyStatus`)

### Removed

- Legacy ENC1 `Encryption_key` asset loader (pairing uses NASPAIR3 + TLS only)

### Changed

- Pairing button label unified to「配对二维码」
- Settings save applies port/storage changes in background without blocking UI
