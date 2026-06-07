import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart'
    as flutter_charset_detector;
import 'package:flutter_chardet/flutter_chardet.dart' as flutter_chardet;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('compares detector results on upstream fixtures', (tester) async {
    final fixtures = await _loadFixtures();
    final rows = <Map<String, Object?>>[];

    for (final fixture in fixtures) {
      final bytes = Uint8List.fromList(fixture.file.readAsBytesSync());

      final flutterChardetResult = await _detectWithFlutterChardet(bytes);
      final flutterCharsetDetectorResult =
          await _detectWithFlutterCharsetDetector(bytes);
      final flutterChardetDecodeResult = await _autoDecodeWithFlutterChardet(
        bytes,
      );
      final flutterCharsetDetectorDecodeResult =
          await _autoDecodeWithFlutterCharsetDetector(bytes);
      final decodedTextMatches =
          flutterChardetDecodeResult.text != null &&
          flutterChardetDecodeResult.text ==
              flutterCharsetDetectorDecodeResult.text;

      rows.add({
        'fixture': fixture.relativePath,
        'expectedLanguage': fixture.expectedLanguage,
        'expectedCharset': fixture.expectedCharset,
        'knownBrokenUpstream': _knownBrokenKeys.contains(fixture.key),
        'flutterChardetCharset': flutterChardetResult.charset,
        'flutterChardetError': flutterChardetResult.error,
        'flutterChardetMatches': _sameCharset(
          flutterChardetResult.charset,
          fixture.expectedCharset,
        ),
        'flutterCharsetDetectorCharset': flutterCharsetDetectorResult.charset,
        'flutterCharsetDetectorError': flutterCharsetDetectorResult.error,
        'flutterCharsetDetectorMatches': _sameCharset(
          flutterCharsetDetectorResult.charset,
          fixture.expectedCharset,
        ),
        'flutterChardetAutoDecodeCharset': flutterChardetDecodeResult.charset,
        'flutterChardetAutoDecodeError': flutterChardetDecodeResult.error,
        'flutterChardetDecodedLength': flutterChardetDecodeResult.text?.length,
        'flutterChardetDecodedSha256': _sha256String(
          flutterChardetDecodeResult.text,
        ),
        'flutterCharsetDetectorAutoDecodeCharset':
            flutterCharsetDetectorDecodeResult.charset,
        'flutterCharsetDetectorAutoDecodeError':
            flutterCharsetDetectorDecodeResult.error,
        'flutterCharsetDetectorDecodedLength':
            flutterCharsetDetectorDecodeResult.text?.length,
        'flutterCharsetDetectorDecodedSha256': _sha256String(
          flutterCharsetDetectorDecodeResult.text,
        ),
        'decodedTextMatches': decodedTextMatches,
      });
    }

    final knownBrokenRows = rows
        .where((row) => row['knownBrokenUpstream'] as bool)
        .length;
    final comparableRows = rows.length - knownBrokenRows;
    final comparableFlutterChardetMatches = rows
        .where(
          (row) =>
              row['knownBrokenUpstream'] == false &&
              row['flutterChardetMatches'] == true,
        )
        .length;
    final comparableFlutterCharsetDetectorMatches = rows
        .where(
          (row) =>
              row['knownBrokenUpstream'] == false &&
              row['flutterCharsetDetectorMatches'] == true,
        )
        .length;
    final flutterChardetAutoDecodeSuccesses = rows
        .where((row) => row['flutterChardetAutoDecodeError'] == null)
        .length;
    final flutterCharsetDetectorAutoDecodeSuccesses = rows
        .where((row) => row['flutterCharsetDetectorAutoDecodeError'] == null)
        .length;
    final autoDecodeComparableRows = rows
        .where(
          (row) =>
              row['flutterChardetAutoDecodeError'] == null &&
              row['flutterCharsetDetectorAutoDecodeError'] == null,
        )
        .length;
    final autoDecodeTextMatches = rows
        .where(
          (row) =>
              row['flutterChardetAutoDecodeError'] == null &&
              row['flutterCharsetDetectorAutoDecodeError'] == null &&
              row['decodedTextMatches'] == true,
        )
        .length;

    final document = {
      'generatedBy':
          'flutter test integration_test/detector_comparison_test.dart '
          '-d macos --dart-define=FIXTURE_ROOT=/absolute/path/to/test/upstream '
          '--dart-define=OUTPUT_PATH=/absolute/path/to/docs/detector_comparison_results.json',
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'platform':
          '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      'dart': Platform.version,
      'flutterCharsetDetectorVersion': '6.0.0',
      'flutterCharsetDetectorImplementation':
          'Darwin plugin using UniversalDetector2 on macOS/iOS.',
      'summary': {
        'fixtureCount': rows.length,
        'knownBrokenFixtureCount': knownBrokenRows,
        'flutterChardetMatches': rows
            .where((row) => row['flutterChardetMatches'] == true)
            .length,
        'flutterCharsetDetectorMatches': rows
            .where((row) => row['flutterCharsetDetectorMatches'] == true)
            .length,
        'comparableFixtureCount': comparableRows,
        'comparableFlutterChardetMatches': comparableFlutterChardetMatches,
        'comparableFlutterCharsetDetectorMatches':
            comparableFlutterCharsetDetectorMatches,
        'flutterChardetAutoDecodeSuccesses': flutterChardetAutoDecodeSuccesses,
        'flutterCharsetDetectorAutoDecodeSuccesses':
            flutterCharsetDetectorAutoDecodeSuccesses,
        'autoDecodeComparableCount': autoDecodeComparableRows,
        'autoDecodeTextMatches': autoDecodeTextMatches,
      },
      'results': rows,
    };

    const outputPath = String.fromEnvironment('OUTPUT_PATH');
    if (outputPath.isNotEmpty) {
      File(
        outputPath,
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(document));
    }

    expect(fixtures, isNotEmpty);
  });
}

Future<List<_Fixture>> _loadFixtures() async {
  const fixtureRoot = String.fromEnvironment('FIXTURE_ROOT');
  final root = Directory(
    fixtureRoot.isEmpty ? '../../test/upstream' : fixtureRoot,
  );
  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => !file.path.endsWith('uchardet-tests.c'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  return files.map((file) => _Fixture.fromFile(root, file)).toList();
}

Future<_DetectionResult> _detectWithFlutterChardet(Uint8List bytes) async {
  try {
    return _DetectionResult(
      charset: await flutter_chardet.FlutterChardet.detect(bytes),
    );
  } catch (error) {
    return _DetectionResult(error: '$error');
  }
}

Future<_DetectionResult> _detectWithFlutterCharsetDetector(
  Uint8List bytes,
) async {
  try {
    return _DetectionResult(
      charset: await flutter_charset_detector.CharsetDetector.detect(bytes),
    );
  } catch (error) {
    return _DetectionResult(error: '$error');
  }
}

Future<_AutoDecodeResult> _autoDecodeWithFlutterChardet(Uint8List bytes) async {
  try {
    final result = await flutter_chardet.FlutterChardet.autoDecode(bytes);
    return _AutoDecodeResult(charset: result.charset, text: result.text);
  } catch (error) {
    return _AutoDecodeResult(error: '$error');
  }
}

Future<_AutoDecodeResult> _autoDecodeWithFlutterCharsetDetector(
  Uint8List bytes,
) async {
  try {
    final result = await flutter_charset_detector.CharsetDetector.autoDecode(
      bytes,
    );
    return _AutoDecodeResult(charset: result.charset, text: result.string);
  } catch (error) {
    return _AutoDecodeResult(error: '$error');
  }
}

bool _sameCharset(String? actual, String expected) {
  if (actual == null || actual.isEmpty) {
    return false;
  }
  return actual.toLowerCase() == expected.toLowerCase();
}

String? _sha256String(String? text) {
  if (text == null) {
    return null;
  }
  return sha256.convert(utf8.encode(text)).toString();
}

const _knownBrokenKeys = {
  'ja:utf-16le',
  'ja:utf-16be',
  'es:iso-8859-15',
  'da:iso-8859-1',
  'he:iso-8859-8',
  'zh:gb18030',
};

final class _Fixture {
  const _Fixture({
    required this.file,
    required this.relativePath,
    required this.expectedLanguage,
    required this.expectedCharset,
  });

  factory _Fixture.fromFile(Directory root, File file) {
    final normalizedRoot = root.absolute.path.replaceAll('\\', '/');
    final normalizedPath = file.absolute.path.replaceAll('\\', '/');
    final relativeToRoot = normalizedPath
        .substring(normalizedRoot.length)
        .replaceFirst(RegExp('^/'), '');
    final relativePath = 'test/upstream/$relativeToRoot';
    final segments = relativePath.split('/');
    final fileName = segments.last;

    return _Fixture(
      file: file,
      relativePath: relativePath,
      expectedLanguage: segments[segments.length - 2],
      expectedCharset: fileName.split('.').first.toLowerCase(),
    );
  }

  final File file;
  final String relativePath;
  final String expectedLanguage;
  final String expectedCharset;

  String get key => '$expectedLanguage:$expectedCharset';
}

final class _DetectionResult {
  const _DetectionResult({this.charset, this.error});

  final String? charset;
  final String? error;
}

final class _AutoDecodeResult {
  const _AutoDecodeResult({this.charset, this.text, this.error});

  final String? charset;
  final String? text;
  final String? error;
}
