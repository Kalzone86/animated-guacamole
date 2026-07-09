# C5 Max touchscreen UI

An LVGL front-end that drives the **same scope-enforced capture backend** as
`firmware/esp32-recon`, so the touchscreen can only act on in-scope BSSIDs.

> **Hardware assumption.** I've built this for an ESP32-S3 board with a
> capacitive-touch TFT (the common capture-unit form factor) using
> **TFT_eSPI + LVGL**. Set the display resolution (`SCR_W`/`SCR_H`), the
> `TFT_eSPI` `User_Setup`, and the `touch_read()` implementation to match your
> exact panel. If your C5 Max uses specific driver ICs (e.g. ST7789/ILI9341 for
> display, GT911/FT6236/XPT2046 for touch), tell me and I'll drop in the exact
> config.

## What's on screen

- **Target dropdown** — populated from the compiled-in scope allowlist only.
- **Scan** — passive recon; lists APs (in-scope ones flagged).
- **PMKID** — clientless capture (preferred; disconnects nobody).
- **Handshake** — 4-way capture; only sends deauth if `allow_deauth` was true in
  your scope.yaml, and then only a small bounded targeted burst.
- **Stop** — end capture and flush the PCAP to SD.
- **Status line** — live frames / M1..M4 / PMKID indicator.

## Building it

This sketch is the UI layer. It calls a backend implemented from the
`esp32-recon` capture logic. To assemble:

1. Generate `scope.h` (same as esp32-recon):
   ```
   cd ../../config && python3 scope_gen.py scope.yaml ../touchui/c5max/scope.h
   ```
2. Provide a `backend.cpp` next to this sketch that implements the `backend_*`
   functions declared at the top of `ui_wifi_assessment.ino`. The bodies are the
   scan / PMKID / handshake / stop routines from
   `../../firmware/esp32-recon/esp32-recon.ino` — lift them into these functions
   (they already enforce the scope allowlist). Keep the PCAP writer and the
   promiscuous RX callback unchanged.
3. Implement `touch_read(uint16_t* x, uint16_t* y)` for your touch controller.
4. Configure `TFT_eSPI` for your panel.
5. Libraries: `lvgl`, `TFT_eSPI`, `SD`. Flash to the ESP32-S3.

## Why split UI and backend

Keeping the capture backend identical between the headless Flipper unit and the
touchscreen unit means the **scope enforcement lives in one place** and behaves
the same everywhere. The screen is just a nicer way to drive it.
