#!/usr/bin/env bash
# Package an engagement's logs into a client deliverable the customer's engineers
# can review and act on.
#
# By default it bundles the REVIEW artifacts (reports, posture CSVs, probe/analysis
# output, and the integrity manifest) but NOT the raw packet captures or recovered
# credentials — those are sensitive and usually shared separately over an agreed
# channel. Pass --include-captures to add raw PCAPs when the client explicitly
# wants them.
#
# Usage:
#   ./package_deliverable.sh <engagement_dir> [--include-captures]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <engagement_dir> [--include-captures]" >&2
  exit 1
fi
DIR="$1"; INCLUDE_CAPS="${2:-}"
[[ -d "$DIR" ]] || { echo "No such engagement dir: $DIR" >&2; exit 1; }

name="$(basename "$DIR")"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
out="${DIR%/}_deliverable_${stamp}.zip"

# Always refresh the integrity manifest before packaging.
if [[ -f "$HERE/evidence_manifest.py" ]]; then
  python3 "$HERE/evidence_manifest.py" "$DIR" || true
fi

# Build the include list.
tmp="$(mktemp -d)"
stage="$tmp/$name"
mkdir -p "$stage"

# Review artifacts.
for sub in reports scans analysis; do
  [[ -d "$DIR/$sub" ]] && cp -r "$DIR/$sub" "$stage/" 2>/dev/null || true
done
[[ -f "$DIR/MANIFEST.csv" ]] && cp "$DIR/MANIFEST.csv" "$stage/"

if [[ "$INCLUDE_CAPS" == "--include-captures" ]]; then
  echo "[*] Including raw captures (client requested)."
  [[ -d "$DIR/captures" ]] && cp -r "$DIR/captures" "$stage/"
else
  echo "[*] Excluding raw captures & credentials (share separately if agreed)."
  cat > "$stage/README-captures.txt" <<'EOF'
Raw packet captures and any recovered credentials are intentionally NOT in this
package. They are sensitive and are shared separately over the channel agreed in
the engagement. Ask your assessor if you need them for verification.
EOF
fi

( cd "$tmp" && zip -qr "$out" "$name" )
rm -rf "$tmp"

echo "[+] Deliverable -> $out"
echo "    Contents: reports + posture/analysis CSVs + integrity manifest"
echo "    Hand this to the client engineers for review and remediation."
