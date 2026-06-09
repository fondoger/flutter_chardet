# flutter_chardet

[![pub package](https://img.shields.io/pub/v/flutter_chardet.svg)](https://pub.dev/packages/flutter_chardet)

Detect the character encoding of text bytes in Flutter, then optionally convert
those bytes into a Dart `String`.

This is useful when your app opens files, subtitles, logs, crawled pages, or
other text that is not guaranteed to be UTF-8.

`flutter_chardet` uses the native `uchardet` detector through FFI. When you call
`autoDecode`, the byte-to-string conversion is handled by
[`charset_converter`](https://pub.dev/packages/charset_converter).

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

### Only Detect

Use `detect` when you only need the most likely charset name.

```dart
import 'dart:io';

import 'package:flutter_chardet/flutter_chardet.dart';

final bytes = await File('example.txt').readAsBytes();
final charset = await FlutterChardet.detect(bytes);

print(charset);
```

Possible output:

```txt
UTF-8
```

Other common outputs include `SHIFT_JIS`, `windows-1251`, `Big5`, `EUC-JP`, and
`ISO-8859-1`. Very short text can be ambiguous, so treat the result as a best
guess rather than a promise.

### Detect and Convert to String

Use `autoDecode` when you want a decoded Dart `String` and the detection details
that were used for conversion.

```dart
import 'dart:io';

import 'package:flutter_chardet/flutter_chardet.dart';

final bytes = await File('subtitle.srt').readAsBytes();
final result = await FlutterChardet.autoDecode(bytes);

print(result.text);
print(result.charset);
print(result.confidence);
print(result.language);
```

Possible output:

```txt
こんにちは
SHIFT_JIS
0.99
ja
```

The returned `DecodingResult` contains:

| Field | Meaning |
| --- | --- |
| `text` | Decoded Dart `String` |
| `charset` | Charset detected before conversion |
| `encoding` | Alias for `charset` |
| `confidence` | Detector confidence for the selected charset |
| `language` | Detected language code when available |

## Compared with flutter_charset_detector

[`flutter_charset_detector`](https://pub.dev/packages/flutter_charset_detector)
is another Flutter package that can detect and decode text encodings. The table
below uses the upstream `uchardet` fixtures in `test/upstream` as a reference
set. A decoded string only counts as correct when it matches an independent
UTF-8 conversion.

| Package | Supported platforms | Correct charset detection | Correct decoded text | Small text `autoDecode` | Large text `autoDecode` | Minimal Android APK | Minimal iOS app |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `flutter_chardet` | Android, iOS, macOS, Windows, Linux | 152 / 158 | 148 / 158 | 0.125 ms | 142.7 ms | 14.1 MB | 12.4 MB |
| `flutter_charset_detector` 6.0.0 | Android, iOS, macOS, Web | 146 / 158 | 145 / 158 | 0.117 ms | 278.7 ms | 13.9 MB | 19.9 MB |

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
