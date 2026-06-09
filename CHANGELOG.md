## 1.0.2

- Simplified the supported platforms section in the README.

## 1.0.1

- Added a README link to the upstream `uchardet` project.

## 1.0.0

- Marked the initial stable release.
- Changed `FlutterChardet.detect` to return charset, confidence, language, and
  candidate index metadata.
- Added `FlutterChardet.detectAll` for top candidate inspection.
- Changed `FlutterChardet.autoDecode` to try detected candidates in order until
  one decodes successfully.

## 0.0.1

- Initial Flutter FFI package wrapping `uchardet`.
- Added `FlutterChardet.detect` and `FlutterChardet.autoDecode`.
- Added upstream fixture, memory lifecycle, and performance tests.
