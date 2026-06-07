#ifndef FLUTTER_CHARDET_H_
#define FLUTTER_CHARDET_H_

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default")))
#endif

#include <stddef.h>
#include <stdint.h>

#if defined(__cplusplus)
extern "C" {
#endif

typedef void* flutter_chardet_t;

FFI_PLUGIN_EXPORT flutter_chardet_t flutter_chardet_new(void);

FFI_PLUGIN_EXPORT void flutter_chardet_delete(flutter_chardet_t detector);

FFI_PLUGIN_EXPORT intptr_t flutter_chardet_active_detectors(void);

FFI_PLUGIN_EXPORT int32_t flutter_chardet_handle_data(
    flutter_chardet_t detector,
    const uint8_t* data,
    size_t length);

FFI_PLUGIN_EXPORT void flutter_chardet_data_end(flutter_chardet_t detector);

FFI_PLUGIN_EXPORT void flutter_chardet_reset(flutter_chardet_t detector);

FFI_PLUGIN_EXPORT size_t flutter_chardet_get_n_candidates(
    flutter_chardet_t detector);

FFI_PLUGIN_EXPORT float flutter_chardet_get_confidence(
    flutter_chardet_t detector,
    size_t candidate);

FFI_PLUGIN_EXPORT const char* flutter_chardet_get_encoding(
    flutter_chardet_t detector,
    size_t candidate);

FFI_PLUGIN_EXPORT const char* flutter_chardet_get_language(
    flutter_chardet_t detector,
    size_t candidate);

#if defined(__cplusplus)
}
#endif

#endif  // FLUTTER_CHARDET_H_
