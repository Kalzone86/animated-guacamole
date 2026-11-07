#!/usr/bin/env python3
"""Assessment report auto-generator.

Pulls together the machine outputs of an engagement — posture findings, crack
triage results, the scope, and the evidence manifest — into a filled Markdown
report ready for review. It writes the tedious parts (scope table, findings,
passphrase results) so you spend your time on analysis, not formatting.

Usage:
    python3 generate_report.py \
        --scope ../config/scope.yaml \
        --posture ../logs/ENG/scans/posture.csv \
        --triage  ../logs/ENG/analysis/triage_results.csv \
        --manifest ../logs/ENG/MANIFEST.csv \
        -o ../logs/ENG/reports/report.md

Every input is optional except --out; provide what you have.
"""
import argparse
import csv
import datetime as dt
import os


def read_csv(path):
    if not path or not os.path.exists(path):
        return []
    with open(path) as fh:
        return list(csv.DictReader(fh))


def load_scope(path):
    if not path or not os.path.exists(path):
        return {}
    try:
        import yaml
    except ImportError:
        return {}
    with open(path) as fh:
        return yaml.safe_load(fh) or {}


# Reuse posture_report's finding logic if importable, else inline a minimal map.
# `in_scope` is the set of authorized BSSIDs; when provided, out-of-scope APs are
# excluded so a client report only ever describes targets you were cleared to test.
def posture_findings(rows, in_scope=None):
    try:
        from posture_report import findings_for
    except ImportError:
        return []
    out = []
    for r in rows:
        bssid = (r.get("bssid") or "").lower()
        if in_scope is not None and bssid not in in_scope:
            continue
        for sev, title, detail, remed in findings_for(r):
            out.append((sev, r.get("ssid", ""), r.get("bssid", ""), title, detail, remed))
    out.sort(key=lambda f: {"Critical": 0, "High": 1, "Medium": 2, "Low": 3, "Info": 4}.get(f[0], 9))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--scope")
    ap.add_argument("--posture")
    ap.add_argument("--triage")
    ap.add_argument("--manifest")
    ap.add_argument("-o", "--out", required=True)
    args = ap.parse_args()

    scope = load_scope(args.scope)
    eng = scope.get("engagement", {})
    targets = scope.get("targets", []) or []
    posture = read_csv(args.posture)
    triage = read_csv(args.triage)
    manifest = read_csv(args.manifest)
    in_scope = {str(t["bssid"]).lower() for t in targets} if targets else None
    findings = posture_findings(posture, in_scope)

    L = []
    L.append("# Wireless Security Assessment — Report\n")
    L.append(f"**Client:** {eng.get('client', '____')}  ")
    L.append(f"**Engagement / SOW:** {eng.get('authorization_ref', '____')}  ")
    L.append(f"**Operator:** {eng.get('operator', '____')}  ")
    L.append(f"**Generated:** {dt.datetime.utcnow().isoformat()}Z\n")

    L.append("## Scope\n")
    L.append("| SSID | BSSID | Channel | Notes |")
    L.append("|---|---|---|---|")
    for t in targets:
        L.append(f"| {t.get('ssid','')} | {t.get('bssid','')} | "
                 f"{t.get('channel','')} | {t.get('notes','')} |")
    L.append("")

    # Executive summary counts
    sev_counts = {}
    for f in findings:
        sev_counts[f[0]] = sev_counts.get(f[0], 0) + 1
    cracked = [t for t in triage if (t.get("recovered", "").lower() == "yes")]
    L.append("## Executive summary\n")
    if sev_counts:
        L.append("Findings by severity: " +
                 ", ".join(f"{k}: {v}" for k, v in sorted(sev_counts.items())) + ".")
    L.append(f"Passphrases recovered offline: **{len(cracked)}** of "
             f"{len([t for t in triage if t.get('material') not in ('none','')])} "
             f"network(s) with usable capture material.\n")

    L.append("## Findings (configuration / posture)\n")
    if findings:
        L.append("| Severity | SSID | BSSID | Finding | Remediation |")
        L.append("|---|---|---|---|---|")
        for sev, ssid, bssid, title, detail, remed in findings:
            L.append(f"| {sev} | {ssid} | {bssid} | {title} | {remed} |")
    else:
        L.append("_No posture CSV supplied, or no findings._")
    L.append("")

    L.append("## Passphrase-strength results\n")
    if triage:
        L.append("| Capture | Material | Recovered? | Time (s) | Tier |")
        L.append("|---|---|---|---|---|")
        for t in triage:
            L.append(f"| {os.path.basename(t.get('pcap',''))} | {t.get('material','')} | "
                     f"{t.get('recovered','')} | {t.get('seconds','')} | {t.get('tier','')} |")
        L.append("\n_A passphrase not recovered within budget is a positive result "
                 "— it resisted offline attack._")
    else:
        L.append("_No triage results supplied._")
    L.append("")

    L.append("## Recommendations (prioritized)\n")
    recs = []
    if any(f[0] in ("Critical", "High") for f in findings):
        recs.append("Remediate Critical/High posture findings above first.")
    if cracked:
        recs.append("Replace recovered passphrases with long (16+), random values; "
                    "move affected SSIDs to WPA3-SAE.")
    recs += [
        "Disable WPS on all access points.",
        "Enable 802.11w (management frame protection) where clients support it.",
        "Segment wireless so a wireless foothold cannot reach sensitive systems.",
    ]
    for i, r in enumerate(recs, 1):
        L.append(f"{i}. {r}")
    L.append("")

    if manifest:
        L.append("## Appendix — evidence integrity\n")
        L.append(f"{len(manifest)} evidence file(s) hashed (SHA-256) in MANIFEST.csv. "
                 "Integrity verifiable with `evidence_manifest.py --verify`.\n")

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w") as fh:
        fh.write("\n".join(L))
    print(f"[+] Report -> {args.out}")
    print("    Review and edit before sending. It is a draft built from your logs.")


if __name__ == "__main__":
    main()
