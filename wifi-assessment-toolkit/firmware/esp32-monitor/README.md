# esp32-monitor firmware (passive / blue-team)

A **receive-only** monitor. It transmits nothing — it channel-hops and listens,
which makes it safe to leave running on an environment you're authorized to
observe (your own network, or a client site under contract). It's the defensive
counterpart to the capture firmware and gives you findings and monitoring you can
sell as a service.

## What it produces (on the SD card)

| File | Feeds | Contents |
|------|-------|----------|
| `posture.csv`  | `analysis/posture_report.py` | per-AP encryption / WPS / PMF |
| `probe.csv`    | `analysis/probe_analysis.py` | client probe requests (privacy) |
| `alerts.log`   | your review                  | deauth-flood + evil-twin alerts |
| `wardrive.csv` | mapping tools                | AP + GPS location (if `WARDRIVE_GPS`) |

## Built-in detections

- **Encryption / WPS / PMF posture** — parses each beacon's RSN and vendor IEs.
- **Deauth-flood detection** — alerts when deauth/disassoc frames spike (someone
  running a deauth attack nearby, including against you).
- **Rogue-AP / evil-twin detection** — uses `scope.h` as the known-good list: if
  one of *your* SSIDs shows up on a BSSID that isn't yours, it alerts. That's the
  classic evil-twin setup.
- **Probe-request logging** — which client devices are present and what prior
  networks they leak.

## Build

1. Generate `scope.h` (same allowlist as the capture firmware) into this folder:
   ```
   cd ../../config && python3 scope_gen.py scope.yaml ../firmware/esp32-monitor/scope.h
   ```
   Here the scope list is used as "known good" for evil-twin detection.
2. Set `SD_CS_PIN` for your board.
3. (Optional) Set `WARDRIVE_GPS 1` and wire a UART NMEA GPS to log locations;
   adjust the GPS RX/TX pins in `setup()`.
4. Flash. Drive over serial (115200): `help | status | posture | alerts | clear`.

## Notes

- 2.4 GHz only (ESP32 radio limitation). 5 GHz APs won't appear.
- Leave it running for a while — posture fills in as beacons are seen across the
  channel hop; alerts fire in real time.
- Move `posture.csv` / `probe.csv` to the analysis machine to turn them into
  report-ready findings.
