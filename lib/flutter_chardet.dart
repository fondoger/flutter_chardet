import 'dart:typed_data';

import 'package:charset_converter/charset_converter.dart';

import 'src/native_detector.dart';

/// Result returned by [FlutterChardet.autoDecode].
final class DecodingResult {
  const DecodingResult({
    required this.text,
    required this.charset,
    required this.confidence,
    this.language,
  });

  /// Decoded text.
  final String text;

  /// Charset detected by uchardet.
  final String charset;

  /// Detection confidence reported by uchardet for the selected candidate.
  final double confidence;

  /// Language reported by uchardet, when available.
  final String? language;

  /// Alias for [charset].
  String get encoding => charset;
}

/// Charset detection and decoding through uchardet and platform converters.
abstract final class FlutterChardet {
  /// Detects and returns the most likely charset for [bytes].
  static Future<String> detect(Uint8List bytes) async {
    return NativeDetector.detect(bytes).charset;
  }

  /// Detects [bytes] and decodes them using `charset_converter`.
  static Future<DecodingResult> autoDecode(Uint8List bytes) async {
    final detection = NativeDetector.detect(bytes);
    final text = await CharsetConverter.decode(
      _charsetConverterName(detection.charset),
      bytes,
    );
    return DecodingResult(
      text: text,
      charset: detection.charset,
      confidence: detection.confidence,
      language: detection.language,
    );
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
