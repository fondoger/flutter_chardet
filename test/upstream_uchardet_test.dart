import 'dart:typed_data';

import 'package:flutter_chardet/src/native_detector.dart';
import 'package:flutter_test/flutter_test.dart';

import 'src/upstream_fixtures.dart';

void main() {
  final fixtures = upstreamFixtures();

  group('uchardet upstream fixtures', () {
    for (final fixture in fixtures) {
      final skipReason = knownBrokenUpstreamFixtures[fixtureKey(fixture)];
      test(fixture.relativePath, () {
        final bytes = Uint8List.fromList(fixture.file.readAsBytesSync());

        final candidates = NativeDetector.detectAll(bytes);

        expect(candidates, isNotEmpty);
        final detected = candidates.first;
        expect(
          detected.charset.toLowerCase(),
          fixture.expectedCharset,
          reason: _candidateSummary(candidates),
        );
        if (!{'ascii', 'utf-16', 'utf-32'}.contains(fixture.expectedCharset)) {
          expect(
            detected.language,
            fixture.expectedLanguage,
            reason: _candidateSummary(candidates),
          );
        }
      }, skip: skipReason);
    }
  });
}

String _candidateSummary(List<DetectionCandidate> candidates) {
  return candidates
      .take(5)
      .map(
        (candidate) =>
            '#${candidate.index} ${candidate.language ?? 'n/a'}/'
            '${candidate.charset} (${candidate.confidence})',
      )
      .join(', ');
}
