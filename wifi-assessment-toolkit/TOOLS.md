# Tool catalog

Read the card for a tool before you run it. Each card says **what it does**,
**when to use it**, what it **needs**, what it **produces**, and any **safety**
note. Tools are grouped by where they fall in the workflow:

```
  RECON ──▶ CAPTURE ──▶ MONITOR (passive/defensive) ──▶ ANALYZE ──▶ REPORT & DELIVER
```

Legend:  🟢 passive/safe · 🟡 active (transmits) · 🔵 analysis (off-device) · 🔴 needs extra authorization

> **Before anything:** complete `docs/engagement-checklist.md` and fill
> `config/scope.yaml`. Most tools read the scope and refuse out-of-scope targets.

---

## Setup

### 🟢 `config/scope_gen.py` — Scope compiler
- **What:** turns your `scope.yaml` allowlist into `scope.h`, which the firmware
  compiles in. Targets not in scope literally can't be selected on the device.
- **When:** once per engagement, and again any time you edit `scope.yaml`.
- **Needs:** `scope.yaml` (from `scope.example.yaml`), PyYAML.
- **Produces:** `firmware/*/scope.h`.
- **Run:** `python3 scope_gen.py scope.yaml ../firmware/esp32-recon/scope.h`

### 🔵 `analysis/preflight_selftest.py` — Safety self-test
- **What:** proves the rails work before you start — scope parses, `scope.h` isn't
  stale, deauth switch is what you intend, crackers installed.
- **When:** right before an engagement (good to run in front of the client).
- **Produces:** pass/fail report.
- **Run:** `python3 preflight_selftest.py --scope ../config/scope.yaml --scope-h ../firmware/esp32-recon/scope.h`

---

## Recon

### 🟢 `firmware/esp32-recon` → `scan` — AP reconnaissance
- **What:** passive scan listing nearby APs with channel, signal, **encryption
  type**, and an in-scope flag. Transmits nothing disruptive.
- **When:** first thing on-site — pick targets and a capture position.
- **Needs:** ESP32 devboard flashed with esp32-recon.
- **Produces:** serial listing + `capture.log`.
- **Run:** serial command `scan`.

---

## Capture (leads to the "can I decrypt it?" test)

### 🟡 `firmware/esp32-recon` → `pmkid` — Clientless PMKID capture
- **What:** asks an in-scope AP for a PMKID and saves it to a PCAP. **Disconnects
  nobody** — the preferred, least-disruptive way to get crackable material.
- **When:** default capture method for WPA2-PSK targets.
- **Produces:** `cap_*.pcap` on SD.
- **Safety:** in-scope only; no deauth. Start here.
- **Run:** `target <n>` then `pmkid`.

### 🟡 `firmware/esp32-recon` → `handshake` — 4-way handshake capture
- **What:** captures a full WPA handshake. Sends a **brief, bounded, single-target
  deauth** to nudge a reconnect — but only if `allow_deauth: true` in scope.
- **When:** only when PMKID isn't available **and** the rules of engagement permit
  client deauthentication.
- **Produces:** `cap_*.pcap` on SD.
- **Safety:** deauth is a momentary denial of service to a client; needs written
  permission. Not a jammer — capped bursts against one BSSID.
- **Run:** `target <n>` then `handshake`.

### 🟢 `firmware/flipper-momentum` — Flipper driving path
- **What:** notes for running capture from the Flipper Zero + Momentum + ESP32
  devboard (esp32-recon, or ESP32 Marauder).
- **When:** you want the Flipper as controller/screen instead of a laptop.

---

## Monitor (passive / blue-team — transmits nothing)

### 🟢 `firmware/esp32-monitor` — Passive environment monitor
Receive-only. Leave it running on an authorized environment. Four detections in one:
- **Posture:** per-AP encryption / WPS / PMF → `posture.csv`.
- **Deauth-flood detector:** alerts when someone floods deauth frames (an attack,
  possibly against you) → `alerts.log`.
- **Rogue-AP / evil-twin detector:** alerts when one of *your* scope SSIDs appears
  on a BSSID that isn't yours → `alerts.log`.
- **Probe-request logger:** which client devices are present and what prior
  networks they leak → `probe.csv`.
- **Optional wardrive:** with a GPS module, logs AP + location → `wardrive.csv`.
- **Safety:** passive, but still meant for environments you're authorized to
  observe. **Run:** flash, then serial `help | status | posture | alerts`.

### 🟢 `touchui/c5max` — Touchscreen front-end
- **What:** an LVGL UI over the same scope-enforced capture backend (scan / PMKID /
  handshake / stop, live status), for the C5 Max touch device.
- **When:** you want to drive capture from the screen instead of serial.

---

## Analyze (off-device, on your computer)

### 🔵 `analysis/analyze_capture.py` — Capture inspector
- **What:** summarizes a PCAP — which BSSIDs, whether a PMKID / handshake is
  present, and (with `--scope`) flags any **out-of-scope** BSSID.
- **When:** before spending time cracking — confirm the capture is usable and in
  scope.
- **Run:** `python3 analyze_capture.py cap.pcap --scope ../config/scope.yaml`

### 🔵 `analysis/capture_to_hashcat.sh` — PCAP → hash
- **What:** converts a PMKID/handshake PCAP into a hashcat `22000` hash file.
- **Needs:** `hcxpcapngtool` (hcxtools).
- **Run:** `./capture_to_hashcat.sh cap.pcap out.hc22000`

### 🔵 `analysis/wordlist_gen.py` — Client-targeted wordlist
- **What:** builds a focused candidate list from client facts (name, town, year,
  mutations) — what actually cracks real-world passphrases.
- **When:** before cracking, to test likely-weak passwords rather than a generic dump.
- **Run:** `python3 wordlist_gen.py --profile client.yaml -o client_wordlist.txt`

### 🔵🔴 `analysis/crack_own_network.sh` — Passphrase-strength test
- **What:** the "**can I decrypt the network?**" step — recovers the passphrase
  offline from the captured hash (hashcat `-m 22000`).
- **When:** against **your own** network or an in-scope client SSID only.
- **Safety:** requires typing `I AM AUTHORIZED`. Recovering a passphrase you're
  not authorized to test is a crime.
- **Run:** `./crack_own_network.sh hash.hc22000 wordlist.txt [rules]`

### 🔵 `analysis/auto_triage.sh` — Batch cracking
- **What:** for a folder of PCAPs: convert → in-scope check → tiered hashcat (fast
  → rules → big), logging time-to-crack per network.
- **When:** you have several captures and want one pass with a time budget.
- **Produces:** `triage_results.csv`.
- **Run:** `./auto_triage.sh <pcap_dir> fast.txt [rules] [big.txt]`

### 🔵 `analysis/posture_report.py` — Posture → findings
- **What:** turns the monitor's `posture.csv` into severity-ranked findings
  (open/WEP/WPS-on/PMF-off, etc.). No cracking needed.
- **Run:** `python3 posture_report.py posture.csv --scope ../config/scope.yaml --md posture.md`

### 🔵 `analysis/probe_analysis.py` — Probe privacy analysis
- **What:** turns `probe.csv` into a per-client view of leaked prior networks and
  flags directed probes (spoofable for evil-twin).
- **Run:** `python3 probe_analysis.py probe.csv --md probes.md`

---

## Report & deliver

### 🔵 `analysis/generate_report.py` — Report auto-generator
- **What:** assembles scope + posture findings + crack results + manifest into a
  filled Markdown report (scope table, findings, passphrase results, recommendations).
- **When:** after analysis; edit the draft before sending.
- **Run:** `python3 generate_report.py --scope ../config/scope.yaml --posture scans/posture.csv --triage analysis/triage_results.csv -o reports/report.md`

### 🔵 `analysis/evidence_manifest.py` — Chain-of-custody manifest
- **What:** SHA-256 hashes every evidence file → `MANIFEST.csv`; `--verify`
  re-checks nothing was altered. Makes findings defensible.
- **Run:** `python3 evidence_manifest.py ../logs/ACME-2026-001` (add `--verify` to check)

### 🔵 `analysis/package_deliverable.sh` — Client handoff package
- **What:** zips an engagement's reports + posture/analysis + manifest for the
  client's engineers to review and fix. Raw captures excluded unless `--include-captures`.
- **Run:** `./package_deliverable.sh ../logs/ACME-2026-001`

### `logs/new_engagement.sh` — New engagement folder
- **What:** creates `logs/<name>/` from the template (captures/scans/analysis/reports).
- **Run:** `./new_engagement.sh ACME-2026-001`

---

## Kept out of the default kit (🔴 separate authorization)

Captive-portal / evil-twin **credential harvesting** and WPS **Pixie-Dust**
brute-forcing are legitimate on some engagements but move from *assessment* into
*interception / active exploitation*. They need their own explicit written
authorization and are **not** included here. Ask and I'll add them as a clearly
labeled, scope-gated module only if a specific SOW calls for it.
