// Example scope.h — normally AUTO-GENERATED from config/scope.yaml.
// Replace this with your generated file:  python3 config/scope_gen.py scope.yaml scope.h
#pragma once
#include <stdint.h>

// Mirrors rules of engagement. 0 = clientless PMKID only, never transmit a
// deauth. Set to 1 (via scope.yaml -> allow_deauth: true) ONLY with written
// permission to deauthenticate clients.
#define SCOPE_ALLOW_DEAUTH 0
#define SCOPE_TARGET_COUNT 1

typedef struct {
  uint8_t bssid[6];
  uint8_t channel;
  const char* ssid;
} scope_target_t;

// Example placeholder target — your own network. Regenerate for real use.
static const scope_target_t SCOPE_TARGETS[SCOPE_TARGET_COUNT] = {
  { {0x11, 0x22, 0x33, 0x44, 0x55, 0x66}, 11, "MyHomeNetwork" },
};
