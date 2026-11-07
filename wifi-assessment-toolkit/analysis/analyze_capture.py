#!/usr/bin/env python3
"""Summarize a WiFi capture before cracking.

Reports the BSSIDs seen, whether a PMKID and/or a full 4-way handshake is
present, and which SSIDs the beacons advertise — so you know a capture is
usable (and in-scope) before spending time on hashcat.

Usage:
    python3 analyze_capture.py capture.pcap
    python3 analyze_capture.py capture.pcap --scope ../config/scope.yaml

Prefers tshark if available; falls back to scapy.
"""
import argparse
import shutil
import subprocess
import sys
from collections import defaultdict


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


def analyze_with_tshark(pcap):
    """Return dict bssid -> {'ssids', 'pmkid', 'eapol_msgs'}."""
    info = defaultdict(lambda: {"ssids": set(), "pmkid": False, "eapol": 0})
    # Beacons -> SSID/BSSID
    out = subprocess.run(
        ["tshark", "-r", pcap, "-Y", "wlan.fc.type_subtype==0x08",
         "-T", "fields", "-e", "wlan.bssid", "-e", "wlan.ssid"],
        capture_output=True, text=True).stdout
    for line in out.splitlines():
        parts = line.split("\t")
        if parts and parts[0]:
            bssid = parts[0].lower()
            if len(parts) > 1 and parts[1]:
                try:
                    info[bssid]["ssids"].add(bytes.fromhex(parts[1]).decode("utf-8", "replace"))
                except ValueError:
                    info[bssid]["ssids"].add(parts[1])
    # EAPOL frames
    out = subprocess.run(
        ["tshark", "-r", pcap, "-Y", "eapol",
         "-T", "fields", "-e", "wlan.bssid", "-e", "wlan.rsn.ie.pmkid"],
        capture_output=True, text=True).stdout
    for line in out.splitlines():
        parts = line.split("\t")
        if parts and parts[0]:
            bssid = parts[0].lower()
            info[bssid]["eapol"] += 1
            if len(parts) > 1 and parts[1]:
                info[bssid]["pmkid"] = True
    return info


def analyze_with_scapy(pcap):
    from scapy.all import rdpcap, Dot11, Dot11Beacon, Dot11Elt, EAPOL
    info = defaultdict(lambda: {"ssids": set(), "pmkid": False, "eapol": 0})
    for pkt in rdpcap(pcap):
        if pkt.haslayer(Dot11Beacon):
            bssid = (pkt[Dot11].addr3 or "").lower()
            elt = pkt.getlayer(Dot11Elt)
            while isinstance(elt, Dot11Elt):
                if elt.ID == 0:
                    info[bssid]["ssids"].add(elt.info.decode("utf-8", "replace"))
                    break
                elt = elt.payload.getlayer(Dot11Elt)
        if pkt.haslayer(EAPOL):
            bssid = (pkt[Dot11].addr3 or "").lower()
            info[bssid]["eapol"] += 1
            raw = bytes(pkt[EAPOL].payload)
            # RSN PMKID KDE marker inside EAPOL key data
            if b"\x00\x0f\xac\x04" in raw:
                info[bssid]["pmkid"] = True
    return info


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pcap")
    ap.add_argument("--scope", help="scope.yaml to flag out-of-scope BSSIDs")
    args = ap.parse_args()

    scope = load_scope(args.scope)

    if shutil.which("tshark"):
        info = analyze_with_tshark(args.pcap)
    else:
        try:
            info = analyze_with_scapy(args.pcap)
        except ImportError:
            sys.exit("Need tshark or scapy. See requirements.txt.")

    if not info:
        print("No BSSIDs / EAPOL found in capture.")
        return

    print(f"Capture summary: {args.pcap}\n")
    for bssid, d in sorted(info.items()):
        ssids = ", ".join(sorted(s for s in d["ssids"] if s)) or "(hidden/none)"
        flags = []
        if d["pmkid"]:
            flags.append("PMKID")
        if d["eapol"] >= 4:
            flags.append("handshake-likely")
        elif d["eapol"] > 0:
            flags.append(f"eapol={d['eapol']}")
        crackable = "YES" if (d["pmkid"] or d["eapol"] >= 4) else "no"
        scope_note = ""
        if scope is not None:
            scope_note = "  [IN SCOPE]" if bssid in scope else "  [OUT OF SCOPE!]"
        print(f"  {bssid}{scope_note}")
        print(f"    ssid: {ssids}")
        print(f"    material: {', '.join(flags) or 'none'}   crackable: {crackable}")

    if scope is not None:
        oos = [b for b in info if b not in scope]
        if oos:
            print("\n[!] Out-of-scope BSSIDs present in this capture:")
            for b in oos:
                print(f"      {b}")
            print("    Do NOT crack these. Re-scope your capture position/filter.")


if __name__ == "__main__":
    main()
