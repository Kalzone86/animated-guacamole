#!/usr/bin/env python3
"""Evidence integrity / chain-of-custody manifest.

Hashes every file in an engagement's log folder (SHA-256), with size and
timestamp, into a manifest. If a finding is ever disputed, the manifest proves a
capture wasn't altered after collection. Cheap to produce; disproportionately
valuable when a report is challenged.

Usage:
    python3 evidence_manifest.py ../logs/EXAMPLE-2026-001
    python3 evidence_manifest.py <engagement_dir> --verify   # re-check vs manifest
"""
import argparse
import csv
import datetime as dt
import hashlib
import os
import sys

MANIFEST = "MANIFEST.csv"


def sha256(path, chunk=1 << 20):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for b in iter(lambda: fh.read(chunk), b""):
            h.update(b)
    return h.hexdigest()


def walk_files(root):
    for dirpath, _, names in os.walk(root):
        for n in names:
            if n == MANIFEST:
                continue
            full = os.path.join(dirpath, n)
            yield full, os.path.relpath(full, root)


def build(root):
    rows = []
    for full, rel in sorted(walk_files(root), key=lambda x: x[1]):
        st = os.stat(full)
        rows.append({
            "path": rel,
            "sha256": sha256(full),
            "bytes": st.st_size,
            "mtime_utc": dt.datetime.utcfromtimestamp(st.st_mtime).isoformat() + "Z",
        })
    out = os.path.join(root, MANIFEST)
    with open(out, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=["path", "sha256", "bytes", "mtime_utc"])
        w.writeheader()
        w.writerows(rows)
    print(f"[+] Manifest -> {out}  ({len(rows)} file(s))")
    print(f"    Generated {dt.datetime.utcnow().isoformat()}Z")


def verify(root):
    man = os.path.join(root, MANIFEST)
    if not os.path.exists(man):
        sys.exit(f"No {MANIFEST} in {root}; build one first.")
    recorded = {}
    with open(man) as fh:
        for r in csv.DictReader(fh):
            recorded[r["path"]] = r["sha256"]
    current = {rel: sha256(full) for full, rel in walk_files(root)}

    ok = True
    for path, h in recorded.items():
        if path not in current:
            print(f"[MISSING]  {path}"); ok = False
        elif current[path] != h:
            print(f"[CHANGED]  {path}"); ok = False
    for path in current:
        if path not in recorded:
            print(f"[NEW]      {path}"); ok = False
    print("[+] Verify OK — nothing altered." if ok else "[!] Integrity mismatch (see above).")
    sys.exit(0 if ok else 2)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("engagement_dir")
    ap.add_argument("--verify", action="store_true")
    args = ap.parse_args()
    if not os.path.isdir(args.engagement_dir):
        sys.exit(f"Not a directory: {args.engagement_dir}")
    verify(args.engagement_dir) if args.verify else build(args.engagement_dir)


if __name__ == "__main__":
    main()
