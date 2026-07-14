import 'package:flutter_test/flutter_test.dart';
import 'package:diubang_nasserver/core/device_registry/device_label_constraints.dart';

void main() {
  group('DeviceLabelConstraints', () {
    test('allows empty alias to clear display name', () {
      expect(DeviceLabelConstraints.validate('   '), isNull);
    });

    test('allows Chinese and common punctuation', () {
      expect(DeviceLabelConstraints.validate('客厅 NAS-01'), isNull);
      expect(DeviceLabelConstraints.validate('书房_主机'), isNull);
    });

    test('rejects labels longer than max length', () {
      final longLabel = '中' * (DeviceLabelConstraints.maxLength + 1);
      expect(
        DeviceLabelConstraints.validate(longLabel),
        '名称不能超过 ${DeviceLabelConstraints.maxLength} 个字符',
      );
    });

    test('rejects unsafe path characters', () {
      expect(
        DeviceLabelConstraints.validate('客厅/NAS'),
        '名称不能包含 / \\ : * ? " < > | 等字符',
      );
    });

    test('normalize collapses whitespace', () {
      expect(
        DeviceLabelConstraints.normalize('  客厅   NAS  '),
        '客厅 NAS',
      );
    });
  });
}
