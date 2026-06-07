import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
