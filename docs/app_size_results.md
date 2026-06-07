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
| `flutter_chardet_size` | `flutter_chardet` | 14.1 MB | +0.16 MB |
| `flutter_charset_detector_size` | `flutter_charset_detector` 6.0.0 | 13.9 MB | baseline |

Largest native libraries:

| App | Native library | Size |
| --- | --- | ---: |
| `flutter_chardet_size` | `libflutter.so` | 163.8 MB |
| `flutter_chardet_size` | `libapp.so` | 2.4 MB |
| `flutter_chardet_size` | `libflutter_chardet.so` | 0.4 MB |
| `flutter_charset_detector_size` | `libflutter.so` | 163.8 MB |
| `flutter_charset_detector_size` | `libapp.so` | 2.3 MB |

## iOS

Command:

```sh
flutter build ios --release --no-codesign
```

| App | Detector package | `Runner.app` directory | Difference |
| --- | --- | ---: | ---: |
| `flutter_chardet_size` | `flutter_chardet` | 12.4 MB | baseline |
| `flutter_charset_detector_size` | `flutter_charset_detector` 6.0.0 | 19.9 MB | +7.6 MB |

Largest iOS files:

| App | File | Size |
| --- | --- | ---: |
| `flutter_chardet_size` | `Flutter.framework/Flutter` | 9.2 MB |
| `flutter_chardet_size` | `App.framework/App` | 1.9 MB |
| `flutter_chardet_size` | `Flutter.framework/icudtl.dat` | 0.9 MB |
| `flutter_chardet_size` | `flutter_chardet.framework/flutter_chardet` | 0.4 MB |
| `flutter_charset_detector_size` | `Flutter.framework/Flutter` | 9.2 MB |
| `flutter_charset_detector_size` | `libswift_Concurrency.dylib` | 7.7 MB |
| `flutter_charset_detector_size` | `App.framework/App` | 1.9 MB |
| `flutter_charset_detector_size` | `Flutter.framework/icudtl.dat` | 0.9 MB |
