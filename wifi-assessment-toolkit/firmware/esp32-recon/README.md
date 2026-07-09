# esp32-recon firmware

Scoped WiFi assessment capture for an ESP32 (devboard on the Flipper, or the
standalone C5 Max unit). It scans, and captures PMKID / 4-way handshakes **only**
for BSSIDs in your compiled-in scope, writing PCAPs to SD.

## Build

1. Arduino IDE / PlatformIO with the **ESP32 board package**.
2. Generate the scope header from your signed scope:
   ```
   cd ../../config
   cp scope.example.yaml scope.yaml     # then edit for your engagement
   python3 scope_gen.py scope.yaml ../firmware/esp32-recon/scope.h
   ```
3. Set `SD_CS_PIN` (top of the sketch) to your board's SD chip-select.
4. Flash `esp32-recon.ino`.

## Use (USB serial, 115200)

```
help                 list commands
scan                 passive recon; marks in-scope APs
list                 show compiled-in scope targets
target <n>           select an in-scope target
pmkid                clientless PMKID capture (no deauth)  <-- default, preferred
handshake            4-way handshake capture; brief targeted deauth only if
                     allow_deauth was true in scope.yaml
stop                 end capture, flush PCAP
status               show progress (frames, M1..M4, PMKID)
```

PCAPs land on the SD card as `cap_<xxxx>_<ms>.pcap`, plus a `capture.log`.
Move them to the analysis machine (`../../analysis/`) to test passphrase
strength offline.

## Safeguards built in

- **Allowlist enforced in code.** `frame_matches_target()` and `start_capture()`
  operate only on `SCOPE_TARGETS`. A BSSID you were not authorized to test is
  simply not selectable.
- **PMKID-first, clientless.** No frames that disconnect anyone by default.
- **Deauth is compile-gated** by `SCOPE_ALLOW_DEAUTH` (from `allow_deauth` in
  scope.yaml) and, even when enabled, is a small bounded burst against a single
  target BSSID — not a continuous jammer. Leave it off unless the rules of
  engagement grant it in writing.

## Notes

- This is real, iterate-on-hardware firmware; tune SD pins, channel dwell, and
  EAPOL parsing to your board and RF environment.
- Prefer prebuilt **ESP32 Marauder** if you want a broad general-purpose UI;
  use this when you want the scope-enforced, engagement-clean capture path.
