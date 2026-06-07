#include "flutter_chardet.h"

#include "../third_party/uchardet/src/uchardet.h"

#include <atomic>

namespace {
std::atomic<intptr_t> active_detectors{0};
}

flutter_chardet_t flutter_chardet_new(void) {
  uchardet_t detector = uchardet_new();
  if (detector != nullptr) {
    active_detectors.fetch_add(1);
  }
  return reinterpret_cast<flutter_chardet_t>(detector);
}

void flutter_chardet_delete(flutter_chardet_t detector) {
  if (detector == nullptr) {
    return;
  }
  uchardet_delete(reinterpret_cast<uchardet_t>(detector));
  active_detectors.fetch_sub(1);
}

intptr_t flutter_chardet_active_detectors(void) {
  return active_detectors.load();
}

int32_t flutter_chardet_handle_data(
    flutter_chardet_t detector,
    const uint8_t* data,
    size_t length) {
  if (detector == nullptr) {
    return 1;
  }
  return uchardet_handle_data(
      reinterpret_cast<uchardet_t>(detector),
      reinterpret_cast<const char*>(data),
      length);
}

void flutter_chardet_data_end(flutter_chardet_t detector) {
  if (detector == nullptr) {
    return;
  }
  uchardet_data_end(reinterpret_cast<uchardet_t>(detector));
}

void flutter_chardet_reset(flutter_chardet_t detector) {
  if (detector == nullptr) {
    return;
  }
  uchardet_reset(reinterpret_cast<uchardet_t>(detector));
}

size_t flutter_chardet_get_n_candidates(flutter_chardet_t detector) {
  if (detector == nullptr) {
    return 0;
  }
  return uchardet_get_n_candidates(reinterpret_cast<uchardet_t>(detector));
}

float flutter_chardet_get_confidence(
    flutter_chardet_t detector,
    size_t candidate) {
  if (detector == nullptr) {
    return 0.0f;
  }
  return uchardet_get_confidence(
      reinterpret_cast<uchardet_t>(detector),
      candidate);
}

const char* flutter_chardet_get_encoding(
    flutter_chardet_t detector,
    size_t candidate) {
  if (detector == nullptr) {
    return "";
  }
  return uchardet_get_encoding(
      reinterpret_cast<uchardet_t>(detector),
      candidate);
}

const char* flutter_chardet_get_language(
    flutter_chardet_t detector,
    size_t candidate) {
  if (detector == nullptr) {
    return nullptr;
  }
  return uchardet_get_language(
      reinterpret_cast<uchardet_t>(detector),
      candidate);
}
