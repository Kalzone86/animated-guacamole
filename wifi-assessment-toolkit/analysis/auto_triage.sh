#!/usr/bin/env bash
# Batch capture triage: for every PCAP in a folder, convert -> in-scope check ->
# tiered hashcat run, logging time-to-crack per network to a results CSV.
#
# "Tiered" means: try a fast wordlist first, then a rules pass, then stop. That
# mirrors a real engagement's time budget instead of running forever.
#
# Usage:
#   ./auto_triage.sh <pcap_dir> <fast_wordlist> [rules_file] [big_wordlist]
#
# Requires: hcxpcapngtool, hashcat. Optional: analyze_capture.py + scope.yaml
# for the in-scope guard.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <pcap_dir> <fast_wordlist> [rules_file] [big_wordlist]" >&2
  exit 1
fi
PCAP_DIR="$1"; FAST="$2"; RULES="${3:-}"; BIG="${4:-}"
SCOPE="$HERE/../config/scope.yaml"
OUT="$PCAP_DIR/triage_results.csv"

command -v hcxpcapngtool >/dev/null || { echo "install hcxtools" >&2; exit 1; }
command -v hashcat        >/dev/null || { echo "install hashcat"  >&2; exit 1; }

echo "bssid_hint,pcap,material,recovered,seconds,tier" > "$OUT"
shopt -s nullglob
for pcap in "$PCAP_DIR"/*.pcap "$PCAP_DIR"/*.pcapng; do
  [[ -e "$pcap" ]] || continue
  echo "=== $pcap ==="

  if [[ -f "$SCOPE" && -f "$HERE/analyze_capture.py" ]]; then
    if python3 "$HERE/analyze_capture.py" "$pcap" --scope "$SCOPE" | grep -q "OUT OF SCOPE"; then
      echo "[!] Out-of-scope BSSID in $pcap — skipping. Fix capture position."
      continue
    fi
  fi

  hash="${pcap%.*}.hc22000"
  if ! hcxpcapngtool -o "$hash" "$pcap" >/dev/null 2>&1 || [[ ! -s "$hash" ]]; then
    echo "[*] no usable PMKID/handshake in $pcap"
    echo ",$pcap,none,no,0,none" >> "$OUT"
    continue
  fi

  run_tier() { # name, extra-args...
    local name="$1"; shift
    local start=$SECONDS
    hashcat -m 22000 "$hash" "$@" --potfile-disable -o "${hash}.cracked" >/dev/null 2>&1 || true
    local dur=$((SECONDS - start))
    if [[ -s "${hash}.cracked" ]]; then
      echo ",$pcap,hash,yes,$dur,$name" >> "$OUT"
      echo "[+] RECOVERED in tier '$name' ($dur s): $(cut -d: -f5- "${hash}.cracked" | head -1)"
      return 0
    fi
    return 1
  }

  if run_tier "fast" "$FAST"; then continue; fi
  if [[ -n "$RULES" ]] && run_tier "fast+rules" "$FAST" -r "$RULES"; then continue; fi
  if [[ -n "$BIG" ]]   && run_tier "big" "$BIG"; then continue; fi
  echo ",$pcap,hash,no,0,exhausted" >> "$OUT"
  echo "[*] not recovered within budget (good result to report)"
done

echo
echo "[+] Results -> $OUT"
