#!/usr/bin/env python3
"""Encryption / WPS / PMF posture report.

Reads a posture CSV (written by the esp32-monitor firmware, or hand-built from a
scan) and turns each in-scope access point into findings with a severity — no
cracking required. This is where a lot of assessment value comes from: it surfaces
weak encryption, WPS left on, and missing management-frame protection at a glance.

Input CSV columns (header required):
    timestamp,bssid,ssid,channel,rssi,encryption,wps,pmf,band
      encryption : OPEN | WEP | WPA | WPA2 | WPA2/WPA (mixed) | WPA3 | WPA3-TRANS | ENTERPRISE
      wps        : on | off | unknown
      pmf        : required | capable | off | unknown

Usage:
    python3 posture_report.py posture.csv
    python3 posture_report.py posture.csv --scope ../config/scope.yaml --md out.md
"""
import argparse
import csv
import sys


def load_scope(path):
    if not path:
        return None
    try:
        import yaml
    except ImportError:
        print("(scope check skipped: PyYAML not installed)", file=sys.stderr)
        return None
    with open(path) as fh:
        cfg = yaml.safe_load(fh)
    return {str(t["bssid"]).lower() for t in (cfg.get("targets") or [])}


def findings_for(row):
    """Return list of (severity, title, detail, remediation)."""
    out = []
    enc = (row.get("encryption") or "").upper()
    wps = (row.get("wps") or "unknown").lower()
    pmf = (row.get("pmf") or "unknown").lower()
    ssid = row.get("ssid") or "(hidden)"

    if enc in ("OPEN", ""):
        out.append(("Critical", "Open network (no encryption)",
                    f"{ssid} transmits unencrypted.",
                    "Require WPA2/WPA3. If a guest network, isolate + captive-portal."))
    elif enc == "WEP":
        out.append(("Critical", "WEP encryption",
                    f"{ssid} uses WEP, broken since the 2000s.",
                    "Replace with WPA2-AES minimum; prefer WPA3."))
    elif enc == "WPA":
        out.append(("High", "Legacy WPA (TKIP)",
                    f"{ssid} uses original WPA/TKIP.",
                    "Move to WPA2-AES or WPA3."))
    elif enc in ("WPA2/WPA", "WPA2/WPA (MIXED)", "MIXED"):
        out.append(("Medium", "WPA2/WPA mixed mode",
                    f"{ssid} allows legacy TKIP fallback.",
                    "Set WPA2-AES only, or WPA3."))
    elif enc in ("WPA2",):
        out.append(("Info", "WPA2-PSK",
                    f"{ssid} on WPA2-PSK — offline-crackable if passphrase weak.",
                    "Long random passphrase; consider WPA3-SAE."))
    elif enc == "WPA3-TRANS":
        out.append(("Low", "WPA3 transition mode",
                    f"{ssid} runs WPA3/WPA2 transition (downgrade-attackable).",
                    "Move to WPA3-only once client fleet supports it."))

    if wps == "on":
        out.append(("High", "WPS enabled",
                    f"{ssid} has WPS on (PIN/Pixie-Dust exposure).",
                    "Disable WPS entirely."))

    if pmf in ("off", "unknown") and enc not in ("OPEN", "WEP", ""):
        sev = "Medium" if pmf == "off" else "Info"
        out.append((sev, "Management Frame Protection not enforced",
                    f"{ssid} PMF={pmf}; deauth-based attacks are easier.",
                    "Enable 802.11w (PMF required) where clients support it."))
    return out


SEV_ORDER = {"Critical": 0, "High": 1, "Medium": 2, "Low": 3, "Info": 4}


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("csvfile")
    ap.add_argument("--scope")
    ap.add_argument("--md", help="also write a markdown findings table")
    args = ap.parse_args()

    scope = load_scope(args.scope)

    rows = []
    with open(args.csvfile) as fh:
        for r in csv.DictReader(fh):
            if r.get("bssid"):
                rows.append(r)

    all_findings = []
    for r in rows:
        bssid = (r.get("bssid") or "").lower()
        if scope is not None and bssid not in scope:
            continue  # only report on authorized targets
        for sev, title, detail, remed in findings_for(r):
            all_findings.append((sev, bssid, r.get("ssid", ""), title, detail, remed))

    all_findings.sort(key=lambda f: SEV_ORDER.get(f[0], 9))

    print(f"Posture report: {args.csvfile}  ({len(all_findings)} finding(s))\n")
    for sev, bssid, ssid, title, detail, remed in all_findings:
        print(f"[{sev:8}] {title}  ({ssid} {bssid})")
        print(f"           {detail}")
        print(f"           fix: {remed}")

    if args.md:
        with open(args.md, "w") as fh:
            fh.write("| Severity | SSID | BSSID | Finding | Remediation |\n")
            fh.write("|---|---|---|---|---|\n")
            for sev, bssid, ssid, title, detail, remed in all_findings:
                fh.write(f"| {sev} | {ssid} | {bssid} | {title} | {remed} |\n")
        print(f"\n[+] Markdown table -> {args.md}")


if __name__ == "__main__":
    main()
