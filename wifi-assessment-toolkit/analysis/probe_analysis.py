#!/usr/bin/env python3
"""Probe-request / client privacy analysis.

Client devices broadcast probe requests naming networks they've joined before.
Collected passively (esp32-monitor probe mode), this reveals which devices are
present and what prior networks they leak — a genuine privacy finding, and a way
to spot devices that shouldn't be on-site.

Input CSV (header required):
    timestamp,client_mac,ssid,rssi

Usage:
    python3 probe_analysis.py probe.csv
    python3 probe_analysis.py probe.csv --md probes.md
"""
import argparse
import csv
from collections import defaultdict


# Locally-administered bit set in the first octet => randomized/private MAC.
def is_randomized(mac: str) -> bool:
    try:
        first = int(mac.split(":")[0], 16)
        return bool(first & 0x02)
    except (ValueError, IndexError):
        return False


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("csvfile")
    ap.add_argument("--md")
    args = ap.parse_args()

    by_client = defaultdict(set)
    by_ssid = defaultdict(set)
    with open(args.csvfile) as fh:
        for r in csv.DictReader(fh):
            mac = (r.get("client_mac") or "").lower()
            ssid = (r.get("ssid") or "").strip()
            if not mac:
                continue
            if ssid:
                by_client[mac].add(ssid)
                by_ssid[ssid].add(mac)

    print(f"Probe analysis: {args.csvfile}")
    print(f"  {len(by_client)} client(s), {len(by_ssid)} named network(s) requested\n")

    print("Clients leaking prior networks:")
    for mac, ssids in sorted(by_client.items(), key=lambda x: -len(x[1])):
        rnd = " (randomized MAC)" if is_randomized(mac) else ""
        named = sorted(s for s in ssids if s)
        if named:
            print(f"  {mac}{rnd}: {', '.join(named)}")

    print("\nMost-requested networks (directed probes = a device looking for a "
          "specific SSID, spoofable for evil-twin):")
    for ssid, macs in sorted(by_ssid.items(), key=lambda x: -len(x[1]))[:20]:
        print(f"  {ssid!r}: {len(macs)} device(s)")

    if args.md:
        with open(args.md, "w") as fh:
            fh.write("### Probe-request findings\n\n")
            fh.write("| Client MAC | Randomized | Leaked SSIDs |\n|---|---|---|\n")
            for mac, ssids in sorted(by_client.items(), key=lambda x: -len(x[1])):
                named = ", ".join(sorted(s for s in ssids if s))
                fh.write(f"| {mac} | {'yes' if is_randomized(mac) else 'no'} | {named} |\n")
        print(f"\n[+] Markdown -> {args.md}")


if __name__ == "__main__":
    main()
