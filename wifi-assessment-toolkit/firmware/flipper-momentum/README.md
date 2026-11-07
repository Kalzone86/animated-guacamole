# Flipper Zero + Momentum + ESP32 WiFi

The Flipper has no WiFi radio; it drives an **ESP32 WiFi devboard** that does the
802.11 work. Momentum ships the Flipper-side companion app.

## Two supported paths

**A. ESP32 Marauder (general purpose).**
Flash the prebuilt ESP32 Marauder to your WiFi devboard, then drive it from the
Flipper (Momentum: `Apps -> GPIO -> ESP32 WiFi / Marauder`) or over USB serial.
Marauder covers scanning, PCAP sniffing, PMKID/handshake capture, and more. It
is the community-standard tool and a fine choice for a broad kit.

*Engagement discipline is on you here:* Marauder will happily point at anything.
Only operate against BSSIDs in your authorization, and prefer its PMKID/sniff
functions over anything that deauthenticates clients unless your rules of
engagement allow it.

**B. esp32-recon (scope-enforced).**
Flash `../esp32-recon` instead when you want the allowlist enforced in firmware —
it will not capture from a BSSID that is not in your signed scope. Good for
demonstrating to a client (or yourself) that collection stayed inside scope.
Drive it over USB serial; the Flipper can supply power/GPIO.

## Practical flow on-site

1. Momentum on the Flipper, devboard seated and detected.
2. `scan` to enumerate in-scope APs and pick a capture position by RSSI.
3. `pmkid` against the in-scope target (clientless).
4. If PMKID is unavailable and deauth is permitted, `handshake`.
5. Pull the PCAP off SD; analyze off-device.

## SD / storage

Marauder writes PCAPs to the devboard's SD (or the app can pull them). Keep the
`capture.log` with the engagement records.
