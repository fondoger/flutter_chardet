# flutter_chardet

Flutter FFI charset detection using vendored `uchardet`, with decoding delegated
to the platform converters exposed by `charset_converter`.

## API

```dart
final charset = await FlutterChardet.detect(bytes);
final result = await FlutterChardet.autoDecode(bytes);

print(charset);
print(result.text);
print(result.confidence);
```

`detect(Uint8List bytes)` returns the most likely charset reported by
`uchardet`.

`autoDecode(Uint8List bytes)` detects the charset and calls
`CharsetConverter.decode` with that charset. The returned `DecodingResult`
contains `text`, `charset`, `encoding`, `confidence`, and `language`.

## Native Sources

The package vendors `uchardet` under `third_party/uchardet` from upstream commit
`06029ec3340cdf6bf9a6a537dafb3f39eda0560e`.

Bindings are generated with `ffigen` from the requested `dart-lang/native`
commit:

```sh
dart run tool/ffigen.dart
```

Native assets are built by `hook/build.dart` with `native_toolchain_c`.

## Tests

```sh
flutter test
```

The test suite includes:

- public API tests with a mocked `charset_converter` MethodChannel
- Dart ports of the upstream `uchardet` fixture tests
- a comparison test against stored `flutter_charset_detector` fixture results
- a native handle lifecycle leak test
- unit-test performance checks

Performance results are stored in `docs/performance_results.md`. Regenerate
them with:

```sh
UPDATE_PERFORMANCE_RESULTS=1 flutter test test/performance_test.dart
```

## Comparison

`flutter_charset_detector` is included as a dev dependency for comparison. Its
Darwin plugin is overridden to
`github.com/fondoger/flutter_charset_detector`, ref `fix-swift6-result-race`,
so the comparison builds with Swift 6.

Accuracy was measured with the upstream `uchardet` fixtures in `test/upstream`.
The comparison used the real macOS implementation of `flutter_charset_detector`
6.0.0 and writes detailed per-fixture results to
`docs/detector_comparison_results.json`.

| Package | Native detector used in comparison | Detect: all fixtures | Detect: comparable fixtures | `autoDecode` successes | Result |
| --- | --- | ---: | ---: | ---: | --- |
| `flutter_chardet` | Vendored `uchardet` through Flutter native assets / FFI | 152 / 158 | 152 / 152 | 150 / 158 | Better detection accuracy on this fixture set |
| `flutter_charset_detector` 6.0.0 | Darwin plugin using `UniversalDetector2` | 146 / 158 | 145 / 152 | 148 / 158 | Missed 7 comparable detect fixtures |

The comparable count excludes 6 fixtures that are known-broken in upstream
`uchardet` tests or reproduce the same upstream failure at the vendored commit.

`autoDecode` output was compared by hashing the decoded strings. The full JSON
stores each decoded text length, SHA-256 hash, charset, and error.

| `autoDecode` pairwise metric | Result |
| --- | ---: |
| Both implementations returned decoded text | 147 / 158 |
| Decoded text identical when both returned text | 145 / 147 |
| Decoded text differed when both returned text | 2 / 147 |

The two decoded-text differences were `test/upstream/en/utf-8.txt`
(`flutter_charset_detector` detected `ISO-8859-13`) and
`test/upstream/zh/gb18030.txt` (`flutter_chardet` detected `WINDOWS-1251`, the
same upstream-known problematic fixture noted by the tests).

Minimal app size was measured with the generated apps under `comparison_apps/`.
Detailed commands and binary breakdowns are in `docs/app_size_results.md`.

| Platform build | `flutter_chardet` app | `flutter_charset_detector` app | Smaller app |
| --- | ---: | ---: | --- |
| Android arm64 release APK | 14,061,814 bytes | 13,902,962 bytes | `flutter_charset_detector` by 158,852 bytes |
| iOS release `Runner.app` (`--no-codesign`) | 12,648 KiB | 20,404 KiB | `flutter_chardet` by 7,756 KiB |

## Example

The example Dart app is in `example/`. Platform folders are intentionally not
committed; generate them locally when needed:

```sh
cd example
flutter create .
flutter run
```
