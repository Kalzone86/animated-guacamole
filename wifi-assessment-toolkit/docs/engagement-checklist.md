# Pre-engagement checklist

Complete this before the first capture and keep it with the engagement file.
Do not skip items — each one is here because skipping it has burned someone.

## Authorization

- [ ] Signed authorization letter on file, from someone empowered to grant it
- [ ] Scope defines exact SSIDs / BSSIDs / locations / time windows
- [ ] Rules of engagement reviewed and understood
- [ ] Client deauthentication explicitly **allowed** / **not allowed** (circle one)
- [ ] Emergency contact (name + phone) recorded and carried on-site
- [ ] Data-retention and handling terms agreed

## Scope file

- [ ] `config/scope.yaml` created from `scope.example.yaml`
- [ ] Every BSSID in `scope.yaml` traces back to the authorization letter
- [ ] No out-of-scope BSSIDs present
- [ ] `allow_deauth` in scope file matches the rules of engagement

## Hardware

- [ ] Flipper Zero on Momentum, ESP32 devboard flashed and detected
- [ ] C5 Max unit flashed, SD card inserted and writable
- [ ] Clock set on capture devices (for accurate log timestamps)
- [ ] Spare power / battery for on-site duration

## Analysis machine

- [ ] `hashcat` and `hcxtools` / `aircrack-ng` installed and working
- [ ] Wordlists / rules staged
- [ ] Encrypted storage ready for captures and results

## On-site conduct

- [ ] Working within authorized time window
- [ ] Staying within authorized physical area
- [ ] PMKID-first; deauth only if permitted and only against in-scope targets
- [ ] Capture log being written to SD

## Wrap-up

- [ ] Captures and results moved to encrypted storage
- [ ] Report drafted from `analysis/report_template.md`
- [ ] Client debrief scheduled
- [ ] Data destroyed / retained per agreement
