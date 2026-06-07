import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_chardet/src/native_detector.dart';
import 'package:flutter_test/flutter_test.dart';

import 'src/upstream_fixtures.dart';

void main() {
  test('comparison results match upstream fixtures and current detector', () {
    final file = File('docs/detector_comparison_results.json');
    expect(file.existsSync(), isTrue);

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    expect(document['flutterCharsetDetectorVersion'], '6.0.0');

    final rows = (document['results'] as List<Object?>)
        .cast<Map<String, Object?>>();
    final rowsByPath = {for (final row in rows) row['fixture'] as String: row};
    final fixtures = upstreamFixtures();

    expect(rowsByPath.length, fixtures.length);

    var flutterChardetMatches = 0;
    var flutterCharsetDetectorMatches = 0;
    var comparableFixtureCount = 0;
    var comparableFlutterChardetMatches = 0;
    var comparableFlutterCharsetDetectorMatches = 0;
    var flutterChardetAutoDecodeSuccesses = 0;
    var flutterCharsetDetectorAutoDecodeSuccesses = 0;
    var autoDecodeComparableCount = 0;
    var autoDecodeTextMatches = 0;
    var autoDecodeExpectedComparableCount = 0;
    var flutterChardetAutoDecodeCorrect = 0;
    var flutterCharsetDetectorAutoDecodeCorrect = 0;

    for (final fixture in fixtures) {
      final row = rowsByPath[fixture.relativePath];
      expect(row, isNotNull, reason: fixture.relativePath);

      final bytes = Uint8List.fromList(fixture.file.readAsBytesSync());
      final detected = NativeDetector.detect(bytes).charset;
      final flutterChardetMatchesFixture = _sameCharset(
        detected,
        fixture.expectedCharset,
      );
      final flutterCharsetDetectorMatchesFixture =
          row!['flutterCharsetDetectorMatches'] as bool;

      expect(row['expectedCharset'], fixture.expectedCharset);
      expect(row['expectedLanguage'], fixture.expectedLanguage);
      expect(row['flutterChardetCharset'], detected);
      expect(row['flutterChardetMatches'], flutterChardetMatchesFixture);

      final expectedDecodeError = row['expectedDecodeError'] as String?;
      final expectedDecodedLength = row['expectedDecodedLength'] as int?;
      final expectedDecodedSha256 = row['expectedDecodedSha256'] as String?;
      final hostExpectedDecode = _decodeFixtureWithIconv(fixture);
      if (hostExpectedDecode != null && hostExpectedDecode.error == null) {
        expect(
          row['expectedDecodeCharset'],
          hostExpectedDecode.charset,
          reason: fixture.relativePath,
        );
        expect(
          expectedDecodedLength,
          hostExpectedDecode.textLength,
          reason: fixture.relativePath,
        );
        expect(
          expectedDecodedSha256,
          hostExpectedDecode.utf8Sha256,
          reason: fixture.relativePath,
        );
      }

      final flutterChardetAutoDecodeError =
          row['flutterChardetAutoDecodeError'] as String?;
      final flutterCharsetDetectorAutoDecodeError =
          row['flutterCharsetDetectorAutoDecodeError'] as String?;
      final flutterChardetDecodedLength =
          row['flutterChardetDecodedLength'] as int?;
      final flutterCharsetDetectorDecodedLength =
          row['flutterCharsetDetectorDecodedLength'] as int?;
      final flutterChardetDecodedSha256 =
          row['flutterChardetDecodedSha256'] as String?;
      final flutterCharsetDetectorDecodedSha256 =
          row['flutterCharsetDetectorDecodedSha256'] as String?;
      final decodedTextMatches = row['decodedTextMatches'] as bool;
      final flutterChardetAutoDecodeCorrectFixture =
          row['flutterChardetAutoDecodeCorrect'] as bool;
      final flutterCharsetDetectorAutoDecodeCorrectFixture =
          row['flutterCharsetDetectorAutoDecodeCorrect'] as bool;

      final expectedDecodeSucceeded = expectedDecodeError == null;
      if (expectedDecodeSucceeded) {
        autoDecodeExpectedComparableCount++;
        expect(row['expectedDecodeCharset'], isA<String>());
        expect(expectedDecodedLength, isNotNull);
        expect(expectedDecodedSha256, isNotNull);
      } else {
        expect(expectedDecodedLength, isNull);
        expect(expectedDecodedSha256, isNull);
      }

      final expectedFlutterChardetAutoDecodeCorrect =
          expectedDecodeSucceeded &&
          flutterChardetDecodedLength == expectedDecodedLength &&
          flutterChardetDecodedSha256 == expectedDecodedSha256;
      final expectedFlutterCharsetDetectorAutoDecodeCorrect =
          expectedDecodeSucceeded &&
          flutterCharsetDetectorDecodedLength == expectedDecodedLength &&
          flutterCharsetDetectorDecodedSha256 == expectedDecodedSha256;
      expect(
        flutterChardetAutoDecodeCorrectFixture,
        expectedFlutterChardetAutoDecodeCorrect,
        reason: fixture.relativePath,
      );
      expect(
        flutterCharsetDetectorAutoDecodeCorrectFixture,
        expectedFlutterCharsetDetectorAutoDecodeCorrect,
        reason: fixture.relativePath,
      );

      if (flutterChardetAutoDecodeError == null) {
        flutterChardetAutoDecodeSuccesses++;
        expect(row['flutterChardetAutoDecodeCharset'], isA<String>());
        expect(flutterChardetDecodedLength, isNotNull);
        expect(flutterChardetDecodedSha256, isNotNull);
      }
      if (flutterCharsetDetectorAutoDecodeError == null) {
        flutterCharsetDetectorAutoDecodeSuccesses++;
        expect(row['flutterCharsetDetectorAutoDecodeCharset'], isA<String>());
        expect(flutterCharsetDetectorDecodedLength, isNotNull);
        expect(flutterCharsetDetectorDecodedSha256, isNotNull);
      }
      if (flutterChardetAutoDecodeError == null &&
          flutterCharsetDetectorAutoDecodeError == null) {
        autoDecodeComparableCount++;
        final hashesMatch =
            flutterChardetDecodedSha256 == flutterCharsetDetectorDecodedSha256;
        final lengthsMatch =
            flutterChardetDecodedLength == flutterCharsetDetectorDecodedLength;
        expect(decodedTextMatches, hashesMatch && lengthsMatch);
        if (decodedTextMatches) {
          autoDecodeTextMatches++;
        }
      } else {
        expect(decodedTextMatches, isFalse);
      }
      if (flutterChardetAutoDecodeCorrectFixture) {
        flutterChardetAutoDecodeCorrect++;
      }
      if (flutterCharsetDetectorAutoDecodeCorrectFixture) {
        flutterCharsetDetectorAutoDecodeCorrect++;
      }

      if (flutterChardetMatchesFixture) {
        flutterChardetMatches++;
      }
      if (flutterCharsetDetectorMatchesFixture) {
        flutterCharsetDetectorMatches++;
      }

      if (!knownBrokenUpstreamFixtures.containsKey(fixtureKey(fixture))) {
        comparableFixtureCount++;
        if (flutterChardetMatchesFixture) {
          comparableFlutterChardetMatches++;
        }
        if (flutterCharsetDetectorMatchesFixture) {
          comparableFlutterCharsetDetectorMatches++;
        }
      }
    }

    final summary = document['summary'] as Map<String, Object?>;
    expect(summary['fixtureCount'], fixtures.length);
    expect(
      summary['knownBrokenFixtureCount'],
      knownBrokenUpstreamFixtures.length,
    );
    expect(summary['flutterChardetMatches'], flutterChardetMatches);
    expect(
      summary['flutterCharsetDetectorMatches'],
      flutterCharsetDetectorMatches,
    );
    expect(summary['comparableFixtureCount'], comparableFixtureCount);
    expect(
      summary['comparableFlutterChardetMatches'],
      comparableFlutterChardetMatches,
    );
    expect(
      summary['comparableFlutterCharsetDetectorMatches'],
      comparableFlutterCharsetDetectorMatches,
    );
    expect(
      summary['flutterChardetAutoDecodeSuccesses'],
      flutterChardetAutoDecodeSuccesses,
    );
    expect(
      summary['flutterCharsetDetectorAutoDecodeSuccesses'],
      flutterCharsetDetectorAutoDecodeSuccesses,
    );
    expect(summary['autoDecodeComparableCount'], autoDecodeComparableCount);
    expect(summary['autoDecodeTextMatches'], autoDecodeTextMatches);
    expect(
      summary['autoDecodeExpectedComparableCount'],
      autoDecodeExpectedComparableCount,
    );
    expect(
      summary['flutterChardetAutoDecodeCorrect'],
      flutterChardetAutoDecodeCorrect,
    );
    expect(
      summary['flutterCharsetDetectorAutoDecodeCorrect'],
      flutterCharsetDetectorAutoDecodeCorrect,
    );

    final performanceRows = (document['autoDecodePerformance'] as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(performanceRows.length, 2);
    for (final row in performanceRows) {
      expect(row['case'], isA<String>());
      expect(row['fixture'], 'test/upstream/ja/shift_jis.txt');
      expect(row['encoding'], 'shift_jis');
      expect(row['inputBytes'], greaterThan(0));
      expect(row['decodedCharacters'], greaterThan(0));
      expect(row['warmupIterations'], greaterThan(0));
      expect(row['iterations'], greaterThan(0));
      _expectPerformanceResult(row['flutterChardet'] as Map<String, Object?>);
      _expectPerformanceResult(
        row['flutterCharsetDetector'] as Map<String, Object?>,
      );
    }
  });
}

bool _sameCharset(String? actual, String expected) {
  if (actual == null || actual.isEmpty) {
    return false;
  }
  return _normalizeCharset(actual) == _normalizeCharset(expected);
}

String _normalizeCharset(String charset) {
  return charset.toLowerCase();
}

void _expectPerformanceResult(Map<String, Object?> result) {
  expect(result['averageMicros'], isA<num>());
  expect(result['medianMicros'], isA<int>());
  expect(result['minMicros'], isA<int>());
  expect(result['maxMicros'], isA<int>());
  expect(result['averageMicros'] as num, greaterThan(0));
  expect(result['medianMicros'] as int, greaterThan(0));
  expect(result['minMicros'] as int, greaterThan(0));
  expect(result['maxMicros'] as int, greaterThan(0));
}

_ExpectedDecodeResult? _decodeFixtureWithIconv(UpstreamFixture fixture) {
  const iconvPath = '/usr/bin/iconv';
  if (!File(iconvPath).existsSync()) {
    return null;
  }

  final charset = _iconvCharsetFor(fixture);
  try {
    final result = Process.runSync(
      iconvPath,
      ['-f', charset, '-t', 'UTF-8', fixture.file.path],
      stdoutEncoding: null,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      return _ExpectedDecodeResult(charset: charset, error: '$result');
    }

    final bytes = Uint8List.fromList(result.stdout as List<int>);
    final text = utf8.decode(bytes);
    return _ExpectedDecodeResult(
      charset: charset,
      textLength: text.length,
      utf8Sha256: sha256.convert(bytes).toString(),
    );
  } catch (error) {
    return _ExpectedDecodeResult(charset: charset, error: '$error');
  }
}

String _iconvCharsetFor(UpstreamFixture fixture) {
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

final class _ExpectedDecodeResult {
  const _ExpectedDecodeResult({
    required this.charset,
    this.textLength,
    this.utf8Sha256,
    this.error,
  });

  final String charset;
  final int? textLength;
  final String? utf8Sha256;
  final String? error;
}
