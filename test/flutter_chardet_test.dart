import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_chardet/flutter_chardet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('charset_converter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method != 'decode') {
            throw PlatformException(
              code: 'unsupported_method',
              message: 'Unexpected method ${call.method}',
            );
          }
          final arguments = call.arguments as Map<Object?, Object?>;
          final data = arguments['data']! as Uint8List;
          return utf8.decode(data);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('detect returns the most likely charset', () async {
    final bytes = Uint8List.fromList(utf8.encode('Hello, charset 世界'));

    final charset = await FlutterChardet.detect(bytes);

    expect(charset.toLowerCase(), 'utf-8');
  });

  test(
    'autoDecode detects charset and decodes with charset_converter',
    () async {
      final bytes = Uint8List.fromList(utf8.encode('Hello, charset 世界'));

      final result = await FlutterChardet.autoDecode(bytes);

      expect(result.text, 'Hello, charset 世界');
      expect(result.charset.toLowerCase(), 'utf-8');
      expect(result.encoding, result.charset);
      expect(result.confidence, greaterThan(0));
    },
  );
}
