/// Device display alias constraints shared by API handlers and DeviceStore.
abstract final class DeviceLabelConstraints {
  static const int maxLength = 32;

  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');
  static final RegExp _unsafeChars = RegExp(r'[/\\:*?"<>|]');

  static String normalize(String raw) {
    return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Returns a user-facing error message, or `null` when valid.
  /// Empty normalized label means "clear alias" and is always allowed.
  static String? validate(String? raw) {
    final normalized = normalize(raw ?? '');
    if (normalized.isEmpty) {
      return null;
    }
    if (_controlChars.hasMatch(normalized)) {
      return '名称不能包含不可见控制字符';
    }
    if (_unsafeChars.hasMatch(normalized)) {
      return '名称不能包含 / \\ : * ? " < > | 等字符';
    }
    final runeCount = normalized.runes.length;
    if (runeCount > maxLength) {
      return '名称不能超过 $maxLength 个字符';
    }
    return null;
  }
}
