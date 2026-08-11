/// 文件输入：FileSystemService
/// 文件职责：负责文件系统资源读取
/// 文件对外接口：FileSystemContentReader
/// 文件包含：FileSystemContentReader
import 'dart:io';
import '../resources/dav_resource.dart';
import 'dav_content_reader.dart';

class FileSystemContentReader implements DavContentReader {
  /// 读取块大小：256KB，减少高码率视频传输时的频繁读取开销，提升吞吐。
  static const int _chunkSize = 256 * 1024;

  @override
  Stream<List<int>> openRead(
    DavResource resource, {
    int? rangeStart,
    int? rangeEnd,
  }) async* {
    if (resource.sourceRef == null) {
      return;
    }

    final file = File(resource.sourceRef!);
    final endExclusive = rangeEnd == null ? null : rangeEnd + 1;

    final raf = await file.open();
    try {
      final fileSize = await raf.length();
      final start = rangeStart ?? 0;
      final end = endExclusive ?? fileSize;
      if (start >= end) {
        return;
      }
      await raf.setPosition(start);

      var remaining = end - start;
      while (remaining > 0) {
        final readSize = remaining < _chunkSize ? remaining : _chunkSize;
        final data = await raf.read(readSize);
        if (data.isEmpty) {
          break;
        }
        yield data;
        remaining -= data.length;
      }
    } finally {
      await raf.close();
    }
  }

  @override
  Future<int> getFileSize(DavResource resource) async {
    if (resource.sourceRef == null) return 0;
    final file = File(resource.sourceRef!);
    return file.length();
  }
}
