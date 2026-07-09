# Logs & evidence store

This is where an engagement's data lives while you work it and until you hand it
to the client. One folder per engagement, created from `_TEMPLATE/`.

## Important: this data stays local

Real captures, posture data, and any recovered credentials are **sensitive client
data**. The `.gitignore` is set so everything under `logs/` **except** the
template and this README is **never committed or pushed to GitHub**. That's
deliberate — you do not want a client's network data in a git remote. Keep it on
encrypted local storage and deliver it over the channel agreed in the engagement.

## Per-engagement layout

```
logs/<CLIENT>-<YYYY>-<NNN>/
  captures/    raw PCAPs from the capture firmware (SENSITIVE)
  scans/       posture.csv, probe.csv, alerts.log from the monitor firmware
  analysis/    triage_results.csv, hashcat outputs, wordlists used
  reports/     generated + final report(s)
  NOTES.md     free-form operator notes, timeline, decisions
  MANIFEST.csv SHA-256 of every file (produced by evidence_manifest.py)
```

## Workflow

1. **Start:** `./new_engagement.sh ACME-2026-001` — makes the folder from template.
2. **Collect:** drop PCAPs into `captures/`, and `posture.csv` / `probe.csv` /
   `alerts.log` (from the monitor) into `scans/`.
3. **Analyze:** run the `analysis/` tools; results land in `analysis/`.
4. **Report:** `generate_report.py ... -o reports/report.md`, then edit.
5. **Seal:** `evidence_manifest.py logs/ACME-2026-001` hashes everything.
6. **Deliver:** `package_deliverable.sh logs/ACME-2026-001` builds a client zip
   (reports + posture/analysis + manifest; raw captures excluded unless asked).

## Handing it to the client's engineers

The deliverable zip is what their engineers review to make corrections. It
contains the findings, the posture data, and the passphrase-strength results —
everything they need to prioritize fixes — plus the integrity manifest so they
can trust nothing was altered. Raw packet captures are excluded by default; share
those separately if the engagement calls for it.
