import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:diubang_nasserver/core/profile/device_avatar_constraints.dart';
import 'package:diubang_nasserver/core/profile/device_avatar_processor.dart';

void main() {
  group('DeviceAvatarProcessor', () {
    test('downscaleForEditor scales large images to max edge', () {
      final source = img.Image(width: 2000, height: 1500);
      final sourceBytes = Uint8List.fromList(img.encodeJpg(source));

      final previewBytes = DeviceAvatarProcessor.downscaleForEditor(sourceBytes);
      final decoded = img.decodeImage(previewBytes);

      expect(decoded, isNotNull);
      expect(
        math.max(decoded!.width, decoded.height),
        lessThanOrEqualTo(DeviceAvatarConstraints.editorMaxEdge),
      );
    });

    test('encodeAvatarJpeg keeps output within target size', () {
      final source = img.Image(width: 800, height: 800);
      final output = DeviceAvatarProcessor.encodeAvatarJpeg(source);

      expect(
        output.length,
        lessThanOrEqualTo(DeviceAvatarConstraints.targetMaxBytes),
      );
      final decoded = img.decodeImage(output);
      expect(decoded, isNotNull);
      expect(
        math.max(decoded!.width, decoded.height),
        lessThanOrEqualTo(DeviceAvatarConstraints.outputEdge),
      );
    });
  });
}
