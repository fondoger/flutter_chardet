import 'dart:typed_data';

import 'package:charset_converter/charset_converter.dart';

import 'src/native_detector.dart';

/// Result returned by [FlutterChardet.detect] and [FlutterChardet.detectAll].
final class DetectionResult {
  const DetectionResult({
    required this.index,
    required this.charset,
    required this.confidence,
    this.language,
  });

  /// Candidate index reported by uchardet.
  final int index;

  /// Charset detected by uchardet.
  final String charset;

  /// Detection confidence reported by uchardet for the selected candidate.
  final double confidence;

  /// Language reported by uchardet, when available.
  final String? language;

  /// Alias for [charset].
  String get encoding => charset;
}

/// Result returned by [FlutterChardet.autoDecode].
final class DecodingResult extends DetectionResult {
  const DecodingResult({
    required this.text,
    required super.index,
    required super.charset,
    required super.confidence,
    super.language,
  });

  /// Decoded text.
  final String text;
}

/// Charset detection and decoding through uchardet and platform converters.
abstract final class FlutterChardet {
  /// Detects and returns the most likely charset candidate for [bytes].
  static Future<DetectionResult> detect(Uint8List bytes) async {
    final candidates = await detectAll(bytes, top: 1);
    if (candidates.isEmpty) {
      throw const FormatException('Unable to detect charset.');
    }
    return candidates.first;
  }

  /// Detects charset candidates for [bytes].
  ///
  /// By default, returns the top 5 candidates. Set [top] to 0 to return all
  /// candidates reported by uchardet.
  static Future<List<DetectionResult>> detectAll(
    Uint8List bytes, {
    int top = 5,
  }) async {
    if (top < 0) {
      throw ArgumentError.value(
        top,
        'top',
        'Must be greater than or equal to 0',
      );
    }

    final candidates = NativeDetector.detectAll(bytes);
    final limitedCandidates = top == 0 ? candidates : candidates.take(top);
    return [
      for (final candidate in limitedCandidates)
        DetectionResult(
          index: candidate.index,
          charset: candidate.charset,
          confidence: candidate.confidence,
          language: candidate.language,
        ),
    ];
  }

  /// Detects [bytes] and decodes them using `charset_converter`.
  ///
  /// Candidates are tried in order until one decodes successfully. By default,
  /// this tries the top 5 candidates. Set [top] to 0 to try all candidates.
  static Future<DecodingResult> autoDecode(
    Uint8List bytes, {
    int top = 5,
  }) async {
    final candidates = await detectAll(bytes, top: top);
    if (candidates.isEmpty) {
      throw const FormatException('Unable to detect charset.');
    }

    Object? lastError;
    StackTrace? lastStackTrace;
    for (final detection in candidates) {
      try {
        final text = await CharsetConverter.decode(
          _charsetConverterName(detection.charset),
          bytes,
        );
        return DecodingResult(
          text: text,
          index: detection.index,
          charset: detection.charset,
          confidence: detection.confidence,
          language: detection.language,
        );
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
      }
    }

    Error.throwWithStackTrace(lastError!, lastStackTrace!);
  }
}

String _charsetConverterName(String charset) {
  return switch (charset.toLowerCase()) {
    'ascii' => 'US-ASCII',
    'shift_jis' || 'shift-jis' => 'Shift_JIS',
    'utf-8' => 'UTF-8',
    'utf-16' => 'UTF-16',
    'utf-16be' => 'UTF-16BE',
    'utf-16le' => 'UTF-16LE',
    'utf-32' => 'UTF-32',
    'utf-32be' => 'UTF-32BE',
    'utf-32le' => 'UTF-32LE',
    _ => charset,
  };
}
