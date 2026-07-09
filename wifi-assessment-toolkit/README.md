# WiFi Assessment Toolkit

A scoped, authorization-gated toolkit for **authorized** wireless security
assessments — engagements where you hold written permission (an NDA / rules of
engagement / signed authorization letter) or you are testing infrastructure you
own.

It targets the hardware you described:

- **Flipper Zero** running Momentum firmware, driving an **ESP32 WiFi devboard**
  (Marauder-style capability).
- A **C5 Max touchscreen** ESP32 device used as a standalone capture unit with
  an on-screen UI.

The workflow is the standard, defensible one used on real engagements:

```
  reconnaissance  ->  targeted capture  ->  offline analysis  ->  reporting
   (scan APs)         (PMKID / handshake)    (hashcat/aircrack)    (findings)
```

## Read this first

This toolkit is deliberately built so it will **not** operate against arbitrary
networks. The capture firmware refuses any BSSID that is not listed in your
signed-off scope file (`config/scope.example.yaml`). That is not a limitation to
work around — on a paid engagement it is what keeps you inside the rules of
engagement, and for home use it keeps you on your own gear.

Before you touch a single frame, complete `docs/engagement-checklist.md`.

## Layout

| Path | What it is |
|------|------------|
| `docs/legal-and-scope.md` | Authorization requirements, what "in scope" means, record-keeping |
| `docs/engagement-checklist.md` | Pre-engagement checklist to complete and keep with the engagement file |
| `docs/methodology.md` | The assessment method: recon → capture → analysis → report |
| `docs/hardware-setup.md` | Flipper + Momentum + ESP32 devboard, and the C5 Max touch unit |
| `config/scope.example.yaml` | The authorized-target allowlist. Copy to `scope.yaml` and fill in |
| `firmware/esp32-recon/` | ESP32 Arduino firmware: scan + scoped PMKID/handshake capture to SD |
| `firmware/flipper-momentum/` | Using the Flipper + Momentum + Marauder path |
| `touchui/c5max/` | LVGL touchscreen UI for the C5 Max ESP32 unit |
| `analysis/` | Convert captures and crack **your own** network; report template |

## The decryption question

"Can I decrypt the network?" for WPA2-PSK / WPA3-SAE-transition really means:
*can I recover the passphrase offline from a captured PMKID or 4-way handshake?*
That is a **password-strength test**. A network with a long, random passphrase
will not fall; one with a weak/guessable passphrase will. The value you deliver
to a client is exactly that finding — and you demonstrate it against **their**
authorized SSID (or your own), never a bystander's.

The capture happens on the ESP32/Flipper. The cracking happens off-device in
`analysis/` on a real machine with `hashcat`/`aircrack-ng`.
