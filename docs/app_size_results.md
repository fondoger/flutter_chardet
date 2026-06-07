# App Size Results

Generated on:

- Platform: macOS Version 26.4.1 (Build 25E253), darwin-arm64
- Flutter: 3.44.1 stable
- Dart: 3.12.1

The comparison apps are under `comparison_apps/`. Their generated
platform-specific folders are intentionally ignored.

## Android

Command:

```sh
flutter build apk --release --target-platform android-arm64
```

| App | Detector package | Release APK | Difference |
| --- | --- | ---: | ---: |
| `flutter_chardet_size` | `flutter_chardet` | 14,061,814 bytes | +158,852 bytes |
| `flutter_charset_detector_size` | `flutter_charset_detector` 6.0.0 | 13,902,962 bytes | baseline |

Largest native libraries:

| App | Native library | Size |
| --- | --- | ---: |
| `flutter_chardet_size` | `libflutter.so` | 163,761,776 bytes |
| `flutter_chardet_size` | `libapp.so` | 2,350,008 bytes |
| `flutter_chardet_size` | `libflutter_chardet.so` | 424,120 bytes |
| `flutter_charset_detector_size` | `libflutter.so` | 163,761,776 bytes |
| `flutter_charset_detector_size` | `libapp.so` | 2,348,928 bytes |

## iOS

Command:

```sh
flutter build ios --release --no-codesign
```

| App | Detector package | `Runner.app` directory | Difference |
| --- | --- | ---: | ---: |
| `flutter_chardet_size` | `flutter_chardet` | 12,648 KiB | baseline |
| `flutter_charset_detector_size` | `flutter_charset_detector` 6.0.0 with `flutter_charset_detector_darwin` git override | 20,404 KiB | +7,756 KiB |

Largest iOS files:

| App | File | Size |
| --- | --- | ---: |
| `flutter_chardet_size` | `Flutter.framework/Flutter` | 9,202,128 bytes |
| `flutter_chardet_size` | `App.framework/App` | 1,889,888 bytes |
| `flutter_chardet_size` | `Flutter.framework/icudtl.dat` | 862,304 bytes |
| `flutter_chardet_size` | `flutter_chardet.framework/flutter_chardet` | 390,144 bytes |
| `flutter_charset_detector_size` | `Flutter.framework/Flutter` | 9,202,128 bytes |
| `flutter_charset_detector_size` | `libswift_Concurrency.dylib` | 7,741,808 bytes |
| `flutter_charset_detector_size` | `App.framework/App` | 1,889,888 bytes |
| `flutter_charset_detector_size` | `Flutter.framework/icudtl.dat` | 862,304 bytes |
