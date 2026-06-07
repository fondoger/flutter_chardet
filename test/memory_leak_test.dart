import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_chardet/src/native_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native detector handles are released after repeated calls', () {
    final bytes = Uint8List.fromList(
      File('test/upstream/ru/windows-1251.txt').readAsBytesSync(),
    );
    final before = NativeDetector.activeDetectors;

    for (var i = 0; i < 1000; i++) {
      NativeDetector.detect(bytes);
    }

    expect(NativeDetector.activeDetectors, before);
  });
}
