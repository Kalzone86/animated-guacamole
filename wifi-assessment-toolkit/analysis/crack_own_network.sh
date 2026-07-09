#!/usr/bin/env bash
# Offline passphrase-strength test against a captured hash (hashcat mode 22000).
#
# This is the "can I decrypt the network?" step: it tests whether the captured
# WPA2/WPA3-transition passphrase is weak enough to recover offline. Run it ONLY
# against a capture from a network you are authorized to test (your own, or an
# in-scope client SSID under your engagement).
#
# Usage: ./crack_own_network.sh <hashfile.hc22000> <wordlist> [hashcat-rules]
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <hashfile.hc22000> <wordlist> [rules-file]" >&2
  exit 1
fi

HASH="$1"; WORDLIST="$2"; RULES="${3:-}"

if ! command -v hashcat >/dev/null 2>&1; then
  echo "hashcat not found. Install hashcat." >&2
  exit 1
fi
[[ -f "$HASH" ]]     || { echo "No such hashfile: $HASH" >&2; exit 1; }
[[ -f "$WORDLIST" ]] || { echo "No such wordlist: $WORDLIST" >&2; exit 1; }

cat <<'EOF'
--------------------------------------------------------------------------
 AUTHORIZATION CHECK
 This recovers a WiFi passphrase from a captured hash. Only proceed if this
 capture is from YOUR OWN network or an SSID inside your signed engagement
 scope. Recovering a passphrase for a network you are not authorized to test
 is a criminal offense in most jurisdictions.
--------------------------------------------------------------------------
EOF
read -r -p "Type 'I AM AUTHORIZED' to continue: " ack
if [[ "$ack" != "I AM AUTHORIZED" ]]; then
  echo "Aborted."
  exit 3
fi

ARGS=(-m 22000 "$HASH" "$WORDLIST")
[[ -n "$RULES" ]] && ARGS+=(-r "$RULES")

echo "[*] hashcat ${ARGS[*]}"
set +e
hashcat "${ARGS[@]}"
rc=$?
set -e

echo
echo "[*] Showing any recovered result:"
hashcat -m 22000 "$HASH" --show || true

echo
if [[ $rc -eq 0 ]]; then
  echo "[+] hashcat finished. A recovered passphrase = WEAK-PASSPHRASE finding."
  echo "    Record time-to-crack and wordlist used for the report."
else
  echo "[*] Not recovered with this wordlist/rules within this run."
  echo "    A passphrase that resists a reasonable budget is a good result to report."
fi
