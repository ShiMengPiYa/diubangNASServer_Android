/// Shared avatar size limits for editor preview, output, and storage.
abstract final class DeviceAvatarConstraints {
  static const int editorMaxEdge = 1080;
  static const int editorJpegQuality = 88;

  static const int outputEdge = 256;
  static const int targetMaxBytes = 30 * 1024;

  static const int maxStoredBytes = 64 * 1024;
  static const int maxSourceFileBytes = 15 * 1024 * 1024;
}
