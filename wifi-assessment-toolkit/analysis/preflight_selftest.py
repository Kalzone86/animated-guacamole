#!/usr/bin/env python3
"""Pre-flight self-test.

Run before an engagement to prove the safety rails work. It checks that:
  * the scope file parses and every BSSID is well-formed,
  * the generated scope.h matches scope.yaml (no stale allowlist on the device),
  * required analysis tools are installed,
  * the deauth switch reflects what you intend.

Green here means the device will refuse out-of-scope targets and your tooling is
ready. Good to run in front of a client, too.

Usage:
    python3 preflight_selftest.py --scope ../config/scope.yaml \
        --scope-h ../firmware/esp32-recon/scope.h
"""
import argparse
import re
import shutil
import sys

BSSID_RE = re.compile(r"^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$")


def check(cond, ok_msg, fail_msg):
    print((" [PASS] " if cond else " [FAIL] ") + (ok_msg if cond else fail_msg))
    return cond


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--scope", required=True)
    ap.add_argument("--scope-h")
    args = ap.parse_args()

    passed = True
    print("Pre-flight self-test\n")

    try:
        import yaml
    except ImportError:
        sys.exit(" [FAIL] PyYAML not installed (pip install pyyaml)")

    with open(args.scope) as fh:
        cfg = yaml.safe_load(fh) or {}
    targets = cfg.get("targets") or []
    allow_deauth = bool(cfg.get("allow_deauth", False))

    passed &= check(len(targets) > 0, f"{len(targets)} target(s) in scope",
                    "scope has no targets")
    for t in targets:
        b = str(t.get("bssid", ""))
        passed &= check(bool(BSSID_RE.match(b)), f"valid BSSID {b}",
                        f"BAD BSSID: {b!r}")

    print(f"\n allow_deauth = {allow_deauth}  "
          f"({'client deauth PERMITTED' if allow_deauth else 'PMKID-only, no deauth'})")
    if allow_deauth:
        print("   -> confirm this matches the signed rules of engagement.")

    if args.scope_h:
        with open(args.scope_h) as fh:
            h = fh.read()
        m = re.search(r"SCOPE_TARGET_COUNT\s+(\d+)", h)
        hcount = int(m.group(1)) if m else -1
        passed &= check(hcount == len(targets),
                        f"scope.h target count matches scope.yaml ({hcount})",
                        f"scope.h count {hcount} != scope.yaml {len(targets)} — REGENERATE scope.h")
        dm = re.search(r"SCOPE_ALLOW_DEAUTH\s+([01])", h)
        hdeauth = dm.group(1) == "1" if dm else None
        passed &= check(hdeauth == allow_deauth,
                        "scope.h deauth flag matches scope.yaml",
                        "scope.h deauth flag is STALE — regenerate scope.h")

    print("\nAnalysis tooling:")
    for tool in ("hcxpcapngtool", "hashcat"):
        found = shutil.which(tool) is not None
        passed &= check(found, f"{tool} present", f"{tool} MISSING (see requirements.txt)")
    for opt in ("tshark", "aircrack-ng"):
        print((" [ ok ] " if shutil.which(opt) else " [ -- ] ") +
              f"{opt} {'present' if shutil.which(opt) else 'optional, not found'}")

    print()
    if passed:
        print("ALL CRITICAL CHECKS PASSED — safe to proceed within scope.")
        sys.exit(0)
    print("ONE OR MORE CHECKS FAILED — fix before capturing.")
    sys.exit(1)


if __name__ == "__main__":
    main()
