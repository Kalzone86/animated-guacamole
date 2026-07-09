#!/usr/bin/env python3
"""Generate firmware/esp32-recon/scope.h from config/scope.yaml.

The firmware compiles the authorized-target allowlist in, so a target that is
not in your signed scope literally cannot be selected on the device.

Usage:
    python3 scope_gen.py scope.yaml ../firmware/esp32-recon/scope.h
"""
import sys
import re

try:
    import yaml
except ImportError:
    sys.exit("PyYAML required: pip install pyyaml")

BSSID_RE = re.compile(r"^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$")


def bssid_to_c_array(bssid: str) -> str:
    parts = bssid.split(":")
    return "{" + ", ".join("0x" + p.upper() for p in parts) + "}"


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    src, dst = sys.argv[1], sys.argv[2]

    with open(src) as fh:
        cfg = yaml.safe_load(fh)

    targets = cfg.get("targets") or []
    allow_deauth = bool(cfg.get("allow_deauth", False))
    eng = cfg.get("engagement", {})

    for t in targets:
        b = str(t.get("bssid", "")).strip()
        if not BSSID_RE.match(b):
            sys.exit(f"Invalid BSSID in scope: {b!r}")

    lines = [
        "// AUTO-GENERATED from scope.yaml by scope_gen.py. Do not edit by hand.",
        f"// Engagement: {eng.get('client', '?')}  ref: {eng.get('authorization_ref', '?')}",
        "#pragma once",
        "#include <stdint.h>",
        "",
        f"#define SCOPE_ALLOW_DEAUTH {1 if allow_deauth else 0}",
        f"#define SCOPE_TARGET_COUNT {len(targets)}",
        "",
        "typedef struct {",
        "  uint8_t bssid[6];",
        "  uint8_t channel;",
        "  const char* ssid;",
        "} scope_target_t;",
        "",
        "static const scope_target_t SCOPE_TARGETS[SCOPE_TARGET_COUNT] = {",
    ]
    for t in targets:
        ssid = str(t.get("ssid", "")).replace('"', '\\"')
        ch = int(t.get("channel", 0))
        lines.append(
            f'  {{ {bssid_to_c_array(t["bssid"])}, {ch}, "{ssid}" }},'
        )
    lines.append("};")
    lines.append("")

    with open(dst, "w") as fh:
        fh.write("\n".join(lines))
    print(f"Wrote {dst}: {len(targets)} target(s), allow_deauth={allow_deauth}")


if __name__ == "__main__":
    main()
