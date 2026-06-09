import 'dart:convert';
import 'dart:io';

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

  test('detect returns the most likely charset result', () async {
    final bytes = Uint8List.fromList(utf8.encode('Hello, charset 世界'));

    final result = await FlutterChardet.detect(bytes);

    expect(result.index, 0);
    expect(result.charset.toLowerCase(), 'utf-8');
    expect(result.encoding, result.charset);
    expect(result.confidence, greaterThan(0));
  });

  test(
    'detectAll returns top candidates by default and all candidates',
    () async {
      final bytes = Uint8List.fromList(
        File('test/upstream/ru/windows-1251.txt').readAsBytesSync(),
      );

      final defaultCandidates = await FlutterChardet.detectAll(bytes);
      final allCandidates = await FlutterChardet.detectAll(bytes, top: 0);

      expect(defaultCandidates, isNotEmpty);
      expect(defaultCandidates.length, lessThanOrEqualTo(5));
      expect(
        allCandidates.length,
        greaterThanOrEqualTo(defaultCandidates.length),
      );
      expect(defaultCandidates.first.charset, allCandidates.first.charset);
      expect(defaultCandidates.first.index, 0);
    },
  );

  test('detectAll rejects negative top values', () {
    final bytes = Uint8List.fromList(utf8.encode('Hello, charset 世界'));

    expect(
      FlutterChardet.detectAll(bytes, top: -1),
      throwsA(isA<ArgumentError>()),
    );
  });

  test(
    'autoDecode detects charset and decodes with charset_converter',
    () async {
      final bytes = Uint8List.fromList(utf8.encode('Hello, charset 世界'));

      final result = await FlutterChardet.autoDecode(bytes);

      expect(result.text, 'Hello, charset 世界');
      expect(result.index, 0);
      expect(result.charset.toLowerCase(), 'utf-8');
      expect(result.encoding, result.charset);
      expect(result.confidence, greaterThan(0));
    },
  );

  test('autoDecode tries the next candidate when decoding fails', () async {
    final bytes = Uint8List.fromList(
      File('test/upstream/ru/windows-1251.txt').readAsBytesSync(),
    );
    final candidates = await FlutterChardet.detectAll(bytes, top: 2);
    expect(candidates.length, greaterThanOrEqualTo(2));

    var attempts = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method != 'decode') {
            throw PlatformException(
              code: 'unsupported_method',
              message: 'Unexpected method ${call.method}',
            );
          }
          attempts++;
          if (attempts == 1) {
            throw PlatformException(code: 'decode_failed');
          }
          final arguments = call.arguments as Map<Object?, Object?>;
          return 'decoded with ${arguments['charset']}';
        });

    final result = await FlutterChardet.autoDecode(bytes, top: 2);

    expect(attempts, 2);
    expect(result.index, candidates[1].index);
    expect(result.charset, candidates[1].charset);
    expect(result.text, 'decoded with ${candidates[1].charset}');
  });
}
