import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../flutter_chardet_bindings_generated.dart' as bindings;

final class DetectionCandidate {
  const DetectionCandidate({
    required this.index,
    required this.charset,
    required this.confidence,
    this.language,
  });

  final int index;
  final String charset;
  final double confidence;
  final String? language;
}

abstract final class NativeDetector {
  static int get activeDetectors => bindings.flutter_chardet_active_detectors();

  static DetectionCandidate detect(Uint8List bytes) {
    final candidates = detectAll(bytes);
    if (candidates.isEmpty) {
      throw const FormatException('Unable to detect charset.');
    }
    return candidates.first;
  }

  static List<DetectionCandidate> detectAll(Uint8List bytes) {
    final detector = bindings.flutter_chardet_new();
    if (detector == ffi.nullptr) {
      throw StateError('uchardet_new returned a null detector.');
    }

    final data = bytes.isEmpty
        ? ffi.nullptr.cast<ffi.Uint8>()
        : malloc<ffi.Uint8>(bytes.length);
    try {
      if (bytes.isNotEmpty) {
        data.asTypedList(bytes.length).setAll(0, bytes);
      }
      final result = bindings.flutter_chardet_handle_data(
        detector,
        data,
        bytes.length,
      );
      if (result != 0) {
        throw StateError('uchardet_handle_data failed with code $result.');
      }

      bindings.flutter_chardet_data_end(detector);

      final count = bindings.flutter_chardet_get_n_candidates(detector);
      final candidates = <DetectionCandidate>[];
      for (var index = 0; index < count; index++) {
        final charset = _stringFromNative(
          bindings.flutter_chardet_get_encoding(detector, index),
        );
        if (charset == null || charset.isEmpty) {
          continue;
        }
        candidates.add(
          DetectionCandidate(
            index: index,
            charset: charset,
            confidence: bindings.flutter_chardet_get_confidence(
              detector,
              index,
            ),
            language: _stringFromNative(
              bindings.flutter_chardet_get_language(detector, index),
            ),
          ),
        );
      }
      return candidates;
    } finally {
      if (bytes.isNotEmpty) {
        malloc.free(data);
      }
      bindings.flutter_chardet_delete(detector);
    }
  }
}

String? _stringFromNative(ffi.Pointer<ffi.Char> pointer) {
  if (pointer == ffi.nullptr) {
    return null;
  }
  return pointer.cast<Utf8>().toDartString();
}
