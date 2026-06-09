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

      final expectedDecodeResult = _decodeFixtureWithIconv(fixture);
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
      final flutterChardetDecodeCorrect = _decodedTextCorrect(
        expectedDecodeResult,
        flutterChardetDecodeResult,
      );
      final flutterCharsetDetectorDecodeCorrect = _decodedTextCorrect(
        expectedDecodeResult,
        flutterCharsetDetectorDecodeResult,
      );

      rows.add({
        'fixture': fixture.relativePath,
        'expectedLanguage': fixture.expectedLanguage,
        'expectedCharset': fixture.expectedCharset,
        'knownBrokenUpstream': _knownBrokenKeys.contains(fixture.key),
        'expectedDecodeCharset': expectedDecodeResult.charset,
        'expectedDecodeError': expectedDecodeResult.error,
        'expectedDecodedLength': expectedDecodeResult.textLength,
        'expectedDecodedSha256': expectedDecodeResult.utf8Sha256,
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
        'flutterChardetAutoDecodeCorrect': flutterChardetDecodeCorrect,
        'flutterCharsetDetectorAutoDecodeCharset':
            flutterCharsetDetectorDecodeResult.charset,
        'flutterCharsetDetectorAutoDecodeError':
            flutterCharsetDetectorDecodeResult.error,
        'flutterCharsetDetectorDecodedLength':
            flutterCharsetDetectorDecodeResult.text?.length,
        'flutterCharsetDetectorDecodedSha256': _sha256String(
          flutterCharsetDetectorDecodeResult.text,
        ),
        'flutterCharsetDetectorAutoDecodeCorrect':
            flutterCharsetDetectorDecodeCorrect,
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
    final expectedDecodeComparableRows = rows
        .where((row) => row['expectedDecodeError'] == null)
        .length;
    final flutterChardetAutoDecodeCorrect = rows
        .where((row) => row['flutterChardetAutoDecodeCorrect'] == true)
        .length;
    final flutterCharsetDetectorAutoDecodeCorrect = rows
        .where((row) => row['flutterCharsetDetectorAutoDecodeCorrect'] == true)
        .length;
    final autoDecodePerformance = await _runAutoDecodePerformanceBenchmarks(
      fixtures,
    );

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
        'autoDecodeExpectedComparableCount': expectedDecodeComparableRows,
        'flutterChardetAutoDecodeCorrect': flutterChardetAutoDecodeCorrect,
        'flutterCharsetDetectorAutoDecodeCorrect':
            flutterCharsetDetectorAutoDecodeCorrect,
      },
      'results': rows,
      'autoDecodePerformance': autoDecodePerformance,
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
    final result = await flutter_chardet.FlutterChardet.detect(bytes);
    return _DetectionResult(charset: result.charset);
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

Future<List<Map<String, Object?>>> _runAutoDecodePerformanceBenchmarks(
  List<_Fixture> fixtures,
) async {
  final fixture = fixtures.singleWhere(
    (fixture) => fixture.relativePath == 'test/upstream/ja/shift_jis.txt',
  );
  final baseBytes = Uint8List.fromList(fixture.file.readAsBytesSync());
  final expected = _decodeFixtureWithIconv(fixture);
  if (expected.text == null) {
    throw StateError('Expected UTF-8 text was unavailable: ${expected.error}');
  }

  final benchmarks = [
    _AutoDecodeBenchmark(
      caseName: 'Small Shift_JIS',
      fixture: fixture.relativePath,
      repeatCount: 1,
      bytes: baseBytes,
      expectedText: expected.text!,
      warmupIterations: 10,
      iterations: 100,
    ),
    _AutoDecodeBenchmark(
      caseName: 'Large Shift_JIS x10000',
      fixture: fixture.relativePath,
      repeatCount: 10000,
      bytes: _repeatBytes(baseBytes, 10000),
      expectedText: expected.text! * 10000,
      warmupIterations: 3,
      iterations: 20,
    ),
  ];

  final rows = <Map<String, Object?>>[];
  for (final benchmark in benchmarks) {
    final expectedSha256 = _sha256String(benchmark.expectedText);
    final flutterChardetResult = await _measureAutoDecodePerformance(
      bytes: benchmark.bytes,
      expectedLength: benchmark.expectedText.length,
      expectedSha256: expectedSha256!,
      iterations: benchmark.iterations,
      warmupIterations: benchmark.warmupIterations,
      decode: _autoDecodeWithFlutterChardet,
    );
    final flutterCharsetDetectorResult = await _measureAutoDecodePerformance(
      bytes: benchmark.bytes,
      expectedLength: benchmark.expectedText.length,
      expectedSha256: expectedSha256,
      iterations: benchmark.iterations,
      warmupIterations: benchmark.warmupIterations,
      decode: _autoDecodeWithFlutterCharsetDetector,
    );

    rows.add({
      'case': benchmark.caseName,
      'fixture': benchmark.fixture,
      'encoding': 'shift_jis',
      'repeatCount': benchmark.repeatCount,
      'inputBytes': benchmark.bytes.length,
      'decodedCharacters': benchmark.expectedText.length,
      'warmupIterations': benchmark.warmupIterations,
      'iterations': benchmark.iterations,
      'flutterChardet': flutterChardetResult.toJson(),
      'flutterCharsetDetector': flutterCharsetDetectorResult.toJson(),
    });
  }
  return rows;
}

Future<_AutoDecodePerformanceResult> _measureAutoDecodePerformance({
  required Uint8List bytes,
  required int expectedLength,
  required String expectedSha256,
  required int iterations,
  required int warmupIterations,
  required Future<_AutoDecodeResult> Function(Uint8List bytes) decode,
}) async {
  for (var i = 0; i < warmupIterations; i++) {
    final result = await decode(bytes);
    _expectCorrectDecode(result, expectedLength, expectedSha256);
  }

  final samples = <int>[];
  for (var i = 0; i < iterations; i++) {
    final stopwatch = Stopwatch()..start();
    final result = await decode(bytes);
    stopwatch.stop();
    _expectCorrectDecode(result, expectedLength, expectedSha256);
    samples.add(stopwatch.elapsedMicroseconds);
  }
  samples.sort();

  return _AutoDecodePerformanceResult(
    averageMicros: samples.reduce((a, b) => a + b) / samples.length,
    medianMicros: samples[samples.length ~/ 2],
    minMicros: samples.first,
    maxMicros: samples.last,
  );
}

void _expectCorrectDecode(
  _AutoDecodeResult result,
  int expectedLength,
  String expectedSha256,
) {
  expect(result.error, isNull);
  expect(result.text?.length, expectedLength);
  expect(_sha256String(result.text), expectedSha256);
}

Uint8List _repeatBytes(Uint8List bytes, int repeatCount) {
  final repeated = Uint8List(bytes.length * repeatCount);
  for (var i = 0; i < repeatCount; i++) {
    repeated.setRange(i * bytes.length, (i + 1) * bytes.length, bytes);
  }
  return repeated;
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

bool _decodedTextCorrect(
  _ExpectedDecodeResult expected,
  _AutoDecodeResult actual,
) {
  if (expected.error != null || actual.text == null) {
    return false;
  }
  return actual.text!.length == expected.textLength &&
      _sha256String(actual.text) == expected.utf8Sha256;
}

_ExpectedDecodeResult _decodeFixtureWithIconv(_Fixture fixture) {
  final charset = _iconvCharsetFor(fixture);
  try {
    final result = Process.runSync(
      '/usr/bin/iconv',
      ['-f', charset, '-t', 'UTF-8', fixture.file.path],
      stdoutEncoding: null,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      return _ExpectedDecodeResult(
        charset: charset,
        error: _processError(result),
      );
    }

    final bytes = Uint8List.fromList((result.stdout as List<int>));
    final text = utf8.decode(bytes);
    return _ExpectedDecodeResult(
      charset: charset,
      text: text,
      textLength: text.length,
      utf8Sha256: sha256.convert(bytes).toString(),
    );
  } catch (error) {
    return _ExpectedDecodeResult(charset: charset, error: '$error');
  }
}

String _processError(ProcessResult result) {
  final stderr = result.stderr as String? ?? '';
  if (stderr.trim().isEmpty) {
    return 'iconv exited with ${result.exitCode}';
  }
  return stderr.trim();
}

String _iconvCharsetFor(_Fixture fixture) {
  final fileName = fixture.file.path
      .split(Platform.pathSeparator)
      .last
      .toLowerCase();
  if (fileName.startsWith('utf-16be')) {
    return 'UTF-16BE';
  }
  if (fileName.startsWith('utf-16le')) {
    return 'UTF-16LE';
  }
  if (fileName.startsWith('utf-32be')) {
    return 'UTF-32BE';
  }
  if (fileName.startsWith('utf-32le')) {
    return 'UTF-32LE';
  }

  return _iconvCharsetAliases[fixture.expectedCharset] ??
      fixture.expectedCharset.toUpperCase();
}

const _iconvCharsetAliases = {
  'mac-centraleurope': 'MACCENTRALEUROPE',
  'mac-cyrillic': 'MACCYRILLIC',
  'shift_jis': 'SHIFT_JIS',
};

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

final class _AutoDecodeBenchmark {
  const _AutoDecodeBenchmark({
    required this.caseName,
    required this.fixture,
    required this.repeatCount,
    required this.bytes,
    required this.expectedText,
    required this.warmupIterations,
    required this.iterations,
  });

  final String caseName;
  final String fixture;
  final int repeatCount;
  final Uint8List bytes;
  final String expectedText;
  final int warmupIterations;
  final int iterations;
}

final class _AutoDecodePerformanceResult {
  const _AutoDecodePerformanceResult({
    required this.averageMicros,
    required this.medianMicros,
    required this.minMicros,
    required this.maxMicros,
  });

  final double averageMicros;
  final int medianMicros;
  final int minMicros;
  final int maxMicros;

  Map<String, Object?> toJson() {
    return {
      'averageMicros': averageMicros,
      'medianMicros': medianMicros,
      'minMicros': minMicros,
      'maxMicros': maxMicros,
    };
  }
}

final class _ExpectedDecodeResult {
  const _ExpectedDecodeResult({
    required this.charset,
    this.text,
    this.textLength,
    this.utf8Sha256,
    this.error,
  });

  final String charset;
  final String? text;
  final int? textLength;
  final String? utf8Sha256;
  final String? error;
}
