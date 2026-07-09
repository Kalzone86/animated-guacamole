#!/usr/bin/env bash
# Create a new engagement log folder from the template.
# Usage: ./new_engagement.sh <CLIENT>-<YYYY>-<NNN>
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <engagement-name>   e.g. ACME-2026-001" >&2
  exit 1
fi
NAME="$1"
DEST="$HERE/$NAME"

if [[ -e "$DEST" ]]; then
  echo "Already exists: $DEST" >&2
  exit 1
fi

cp -r "$HERE/_TEMPLATE" "$DEST"
# Drop the .gitkeep placeholders in the live copy.
find "$DEST" -name .gitkeep -delete
sed -i "s/<CLIENT>-<YYYY>-<NNN>/$NAME/g" "$DEST/NOTES.md" 2>/dev/null || true

echo "[+] Created $DEST"
echo "    Fill in NOTES.md, then collect into captures/ and scans/."
echo "    Note: contents here are gitignored — they stay local (sensitive)."
