# flutter_chardet

[![pub package](https://img.shields.io/pub/v/flutter_chardet.svg)](https://pub.dev/packages/flutter_chardet)

Detect the character encoding of text bytes in Flutter, then optionally convert
those bytes into a Dart `String`.

This is useful when your app opens files, subtitles, logs, crawled pages, or
other text that is not guaranteed to be UTF-8.

`flutter_chardet` uses the native
[`uchardet`](https://www.freedesktop.org/wiki/Software/uchardet/) detector
through FFI. When you call `autoDecode`, the byte-to-string conversion is
handled by [`charset_converter`](https://pub.dev/packages/charset_converter).

## Install

```sh
flutter pub add flutter_chardet
```

## Supported Platforms

| Platform | Detect charset | Detect and convert to `String` |
| --- | --- | --- |
| Android | Yes | Yes |
| iOS | Yes | Yes |
| macOS | Yes | Yes |
| Windows | Yes | Yes |
| Linux | Yes | Yes |
| Web | No | No |

Web is not supported because detection uses native code. Conversion support is
provided by `charset_converter`, which supports Android, iOS, macOS, Windows,
and Linux.

## Usage

```dart
import 'dart:io';

import 'package:flutter_chardet/flutter_chardet.dart';

final bytes = await File('subtitle.srt').readAsBytes();

// Only detect the most likely charset.
final detection = await FlutterChardet.detect(bytes);
print(detection.charset); // Possible output: SHIFT_JIS
print(detection.confidence); // Possible output: 0.99
print(detection.language); // Possible output: ja

// Inspect candidate charsets. By default this returns the top 5 candidates.
final candidates = await FlutterChardet.detectAll(bytes);
print(candidates.map((candidate) => candidate.charset).toList());
// Possible output: [SHIFT_JIS, EUC-JP, ISO-2022-JP]

// Use top: 0 when you want every candidate reported by uchardet.
final allCandidates = await FlutterChardet.detectAll(bytes, top: 0);
print(allCandidates.length); // Possible output: 8

// Detect and convert to a Dart String. By default this tries the top 5
// candidates in order until charset_converter decodes one successfully.
final decoded = await FlutterChardet.autoDecode(bytes);
print(decoded.text); // Possible output: こんにちは
print(decoded.charset); // Possible output: SHIFT_JIS
print(decoded.confidence); // Possible output: 0.99
print(decoded.language); // Possible output: ja
```

Other common charset outputs include `UTF-8`, `windows-1251`, `Big5`, `EUC-JP`,
and `ISO-8859-1`. Very short text can be ambiguous, so treat the result as a
best guess rather than a promise.

## Compared with flutter_charset_detector

[`flutter_charset_detector`](https://pub.dev/packages/flutter_charset_detector)
is another Flutter package that can detect and decode text encodings. The table
below uses the upstream `uchardet` fixtures in `test/upstream` as a reference
set. A decoded string only counts as correct when it matches an independent
UTF-8 conversion.

| Package | Supported platforms | Correct charset detection | Correct decoded text | Small text `autoDecode` | Large text `autoDecode` | Minimal Android APK | Minimal iOS app |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `flutter_chardet` | Android, iOS, macOS, Windows, Linux | 152 / 158 | 148 / 158 | 0.118 ms | 135.5 ms | 14.1 MB | 12.4 MB |
| `flutter_charset_detector` 6.0.0 | Android, iOS, macOS, Web | 146 / 158 | 145 / 158 | 0.107 ms | 276.1 ms | 13.9 MB | 19.9 MB |

On this fixture set, `flutter_chardet` detects and decodes more cases correctly.
For very small text the two packages are similar. For the large Shift_JIS sample,
`flutter_chardet` was faster in the local benchmark.

Detailed result files are kept in the GitHub repository:

- [detector_comparison_results.json](https://github.com/fondoger/flutter_chardet/blob/main/docs/detector_comparison_results.json)
- [app_size_results.md](https://github.com/fondoger/flutter_chardet/blob/main/docs/app_size_results.md)
- [performance_results.md](https://github.com/fondoger/flutter_chardet/blob/main/docs/performance_results.md)

## Notes

Detection is only a guess. If your format already declares an encoding, prefer
that explicit value. Use charset detection when the input does not tell you what
it is.
