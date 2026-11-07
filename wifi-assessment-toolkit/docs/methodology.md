# Assessment methodology

The method is deliberately boring and repeatable. Boring is what holds up in a
report and in front of a client.

## 1. Reconnaissance (passive)

Scan for access points in scope. Record for each in-scope AP:

- SSID, BSSID, channel
- Security (Open / WPA2-PSK / WPA3-SAE / WPA2-Enterprise)
- Signal strength (for locating and for choosing a capture position)
- Whether clients are associated

Passive scanning transmits nothing that disrupts anyone. This stage alone often
surfaces findings: open networks, WPS enabled, WPA2 where WPA3 was expected,
rogue/unexpected SSIDs, management frames leaking client info.

Tooling: `firmware/esp32-recon` scan mode, or Flipper + Marauder scan.

## 2. Targeted capture

Goal: obtain material that lets you test passphrase strength offline.

**Preferred — PMKID (clientless).** Many APs will hand over a PMKID in the first
message of the association without any client present and without disconnecting
anyone. This is the least disruptive method and the default in this toolkit.

**Fallback — 4-way handshake.** If PMKID is not available, capture a full WPA
handshake from a real client association. Forcing this quickly means sending a
brief, targeted deauthentication to a single in-scope client so it reconnects.
Only do this if the rules of engagement allow it (`allow_deauth: true` in scope).

Both save to a PCAP on the SD card. Both refuse any BSSID not in `scope.yaml`.

**Not in scope for this toolkit:** broadcast/continuous deauth ("jamming"),
beacon flooding, and evil-portal credential harvesting. Those are either purely
disruptive or move from *assessment* into *social-engineering / interception*,
which needs separate explicit authorization and separate tooling — keep them out
of a straightforward network-security assessment unless the SOW says otherwise.

## 3. Offline analysis

Move the PCAP to the analysis machine. Convert to a hashcat-compatible hash and
attempt recovery of the passphrase (see `analysis/`). This is a **password
strength test**:

- Recovered quickly with a common wordlist  -> weak passphrase finding (high)
- Recovered only with heavy rules / long run -> moderate finding
- Not recovered in the agreed time budget    -> passphrase resisted testing

Do the cracking against the client's authorized SSID or your own — never a
bystander capture.

## 4. Reporting

Turn observations into findings with severity, evidence, and remediation. Use
`analysis/report_template.md`. Typical remediation you will recommend:

- Long, random WPA2/WPA3 passphrases (defeats offline cracking)
- WPA3-SAE (PMKID/handshake offline attacks do not apply the same way)
- 802.1X / Enterprise auth for anything sensitive
- Disable WPS
- Management Frame Protection (802.11w) to blunt deauth
- Segmentation so a wireless foothold is contained
