# Wireless Security Assessment — Report

**Client:** ________________  **Engagement / SOW:** ________________
**Operator:** ________________  **Dates:** ________________
**Authorization on file:** ☐ yes (ref: __________)

## Scope

Networks authorized for testing (from the signed scope):

| SSID | BSSID | Location | In scope |
|------|-------|----------|----------|
|      |       |          | ☑        |

Rules of engagement notes (deauth permitted? blackout windows?): ____________

## Method summary

Reconnaissance (passive scan) → targeted capture (PMKID preferred; handshake
where permitted) → offline passphrase-strength testing (hashcat -m 22000) →
findings. Tooling: Flipper Zero + ESP32 devboard / C5 Max unit; hcxtools +
hashcat on the analysis host.

## Findings

### Finding 1 — <title>
- **Severity:** Critical / High / Medium / Low / Info
- **Affected:** SSID / BSSID
- **Observation:** what was found (e.g. WPA2-PSK passphrase recovered offline)
- **Evidence:** capture file, hash id, time-to-crack, wordlist/rules used
- **Impact:** what an attacker gains
- **Remediation:**
  - e.g. set a long (16+ char) random passphrase; move to WPA3-SAE
  - enable 802.11w (management frame protection)
  - disable WPS; segment the wireless network

### Finding 2 — <title>
...

## Passphrase test results

| SSID | Material captured | Recovered? | Time budget | Notes |
|------|-------------------|------------|-------------|-------|
|      | PMKID / handshake | yes/no     |             |       |

A passphrase **not** recovered within the agreed budget is a positive result —
record it as evidence the passphrase resisted offline attack.

## Recommendations (prioritized)

1.
2.
3.

## Appendix — evidence handling

Capture files and any recovered credentials are sensitive. Stored encrypted at
__________; shared with client via __________; destroyed / retained per
agreement on __________.
