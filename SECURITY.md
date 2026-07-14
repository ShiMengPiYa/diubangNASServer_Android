# Security Policy

## Reporting a Vulnerability

If you discover a security issue, please **do not** open a public GitHub issue with exploit details.

Report privately via GitHub Security Advisories for this repository, or contact the maintainer through the repository owner's profile.

We will acknowledge reports within a reasonable timeframe and coordinate a fix before public disclosure when appropriate.

## Supported Versions

Security fixes are applied to the default branch. There is no long-term support policy for older releases yet.

## Known Security Considerations

Review these before deploying in production or on untrusted networks.

### Default owner credentials

On first launch the server seeds a default owner account **`admin` / `admin`**. Remote clients cannot establish **owner** sessions via `POST /api/v1/auth/session` until the owner changes these credentials in the local management UI.

Credential-based **device enrollment** (`POST /api/v1/auth/credential-device-enroll`) intentionally allows the default credentials so headless clients can register as devices on a trusted LAN. This issues a device token (`role: device`), not an owner session. Treat any deployment that still uses the default password as compromised if exposed beyond a trusted network.

### TLS (self-signed CA)

The server generates a private root CA and leaf certificate on first HTTPS startup. Clients must pair and pin the CA before trusting connections. Pairing must occur on a trusted LAN; do not expose the HTTP pairing endpoint to the public Internet without additional hardening.

### Shared directory scope

WebDAV and preview APIs operate on the user-selected shared folder only. A compromised device token or bearer session can read, write, and delete files within that folder. Limit shared-folder contents and revoke untrusted devices promptly.

### Relay

Relay transfers store metadata and payloads under the server's data directory. Compromised owner or device credentials may access in-flight or completed relay payloads. Use Relay only among trusted devices on a trusted network.

### Android permissions

The app may request broad storage access (`MANAGE_EXTERNAL_STORAGE`) and run a foreground service to keep the HTTPS server alive. Only install on devices you control; review Android permission prompts before granting access.

### Release signing

Release builds fall back to the debug keystore when no local release keystore is configured. Do not distribute debug-signed APKs to end users. Configure your own signing key for production builds.

### Debug logging

Network debug logging may include request URLs and response bodies in debug builds. Do not enable verbose logging when handling sensitive data on shared machines.

### libmpv (Android bundle)

Android builds bundle libmpv native libraries via [media_kit_libs_android_video](https://github.com/media-kit/media-kit) (vendored under `third_party/` when applicable).

- Used in-process for local video preview through media_kit; not used for server-side HLS transcoding on Android.
- Redistribution requires LGPL compliance. See [THIRD_PARTY_NOTICES.txt](THIRD_PARTY_NOTICES.txt).

### Optional benchmark tool

A plain-HTTP benchmark endpoint exists behind the compile-time flag `NAS_ENABLE_BENCHMARK_TOOL` (default **off**). Do not enable it on untrusted networks.
