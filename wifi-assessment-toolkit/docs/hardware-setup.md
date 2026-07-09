# Hardware setup

## Flipper Zero + Momentum + ESP32 WiFi devboard

The Flipper Zero has no native WiFi radio. WiFi assessment on the Flipper is done
through an **ESP32 devboard** attached to the GPIO header, running WiFi firmware
(the well-known ESP32 "Marauder" being the usual choice). Momentum ships the
companion Flipper-side app that drives it.

Setup:

1. Flash Momentum to the Flipper (via the Momentum web updater or qFlipper).
2. Flash the ESP32 devboard with WiFi assessment firmware. You have two options:
   - Use prebuilt **ESP32 Marauder** for the general scan/capture UI, or
   - Use `firmware/esp32-recon` from this repo for the scoped, allowlist-gated
     capture workflow.
3. Seat the devboard on the Flipper GPIO, or power it standalone over USB.
4. On the Flipper, open the ESP32 WiFi companion app (Apps -> GPIO) to drive the
   board, or drive `esp32-recon` over USB serial from a laptop.

Notes:

- The devboard needs an SD card (or the Flipper's storage via the app) to save
  PCAPs.
- Keep the board's antenna clear; capture range is line-of-sight sensitive.
- The Flipper is a convenient controller and logger; the actual 802.11 work
  happens on the ESP32.

## C5 Max touchscreen ESP32 unit

> Assumption: the "C5 Max" is an ESP32-S3 board with an attached capacitive
> touch TFT (the common hobby capture-unit form factor). The UI in
> `touchui/c5max` is built on **LVGL + TFT_eSPI**, which covers the popular
> ESP32-S3 touch panels. You will need to set the correct `TFT_eSPI` `User_Setup`
> and touch controller for your exact panel — see `touchui/c5max/README.md`.
> If your board differs, tell me the exact model/driver ICs and I'll adjust the
> display/touch config.

This unit runs standalone: it does recon + scoped capture itself and shows the
results on its screen, with an SD card for PCAPs. It shares the same
`scope`-allowlist and capture logic as `esp32-recon`; the touch UI is a front-end
on top of it.

Setup:

1. Identify your panel's display driver (e.g. ST7789 / ILI9341) and touch
   controller (e.g. GT911 / FT6236 / XPT2046).
2. Configure `TFT_eSPI` `User_Setup.h` (or select a `User_Setup_Select`
   profile) and the LVGL touch read callback to match.
3. Put `scope.yaml` (or the generated `scope.h`) on the device.
4. Flash `touchui/c5max`.
5. Insert a writable SD/microSD card.

## Common requirements

- Arduino IDE or PlatformIO with the ESP32 board support package.
- Libraries: `TFT_eSPI`, `lvgl` (for the touch unit); SD library.
- A microSD card formatted FAT32.
- USB cable for flashing and serial control.
