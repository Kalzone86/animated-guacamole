#!/usr/bin/env bash
# Convert a captured PCAP (PMKID and/or 4-way handshake) into a hashcat 22000
# hash file for offline passphrase-strength testing.
#
# Usage: ./capture_to_hashcat.sh <capture.pcap> [out.hc22000]
#
# Requires: hcxpcapngtool (from hcxtools).
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <capture.pcap> [out.hc22000]" >&2
  exit 1
fi

IN="$1"
OUT="${2:-${IN%.*}.hc22000}"

if ! command -v hcxpcapngtool >/dev/null 2>&1; then
  echo "hcxpcapngtool not found. Install hcxtools (apt install hcxtools)." >&2
  exit 1
fi

if [[ ! -f "$IN" ]]; then
  echo "No such capture: $IN" >&2
  exit 1
fi

echo "[*] Converting $IN -> $OUT"
hcxpcapngtool -o "$OUT" "$IN"

if [[ -s "$OUT" ]]; then
  n=$(wc -l < "$OUT")
  echo "[+] Wrote $OUT ($n hash line(s))."
  echo "    PMKID lines start 'WPA*01*', handshake lines start 'WPA*02*'."
  echo "    Next: ./crack_own_network.sh $OUT <wordlist>"
else
  echo "[!] No usable PMKID/handshake found in $IN."
  echo "    Recapture: ensure you got a PMKID (M1) or a full M1..M4 handshake."
  rm -f "$OUT"
  exit 2
fi
