#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Jurassic Park Soundboard — Sound Downloader
#
# Run this script on your Mac once to download all the sound clips from
# myinstants.com and a few other free sources.
#
# Usage:
#   chmod +x download-sounds.sh
#   ./download-sounds.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SOUNDS_DIR="$(dirname "$0")/sounds"
mkdir -p "$SOUNDS_DIR"

BASE="https://www.myinstants.com/media/sounds"

# Helper: download if not already present
dl() {
  local name="$1"
  local url="$2"
  local dest="$SOUNDS_DIR/$name"
  if [[ -f "$dest" ]]; then
    echo "  ✓ $name (already downloaded)"
    return
  fi
  echo "  ↓ $name"
  curl -sSL \
    -H "Referer: https://www.myinstants.com/" \
    -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
    -o "$dest" "$url" || echo "    ✗ Failed — skipping (manually add $name to sounds/)"
}

echo ""
echo "🦖  Jurassic Soundboard — Downloading sounds..."
echo ""

# ── Dinosaur sounds ──────────────────────────────────────────────────────────
dl "trex-roar.mp3"          "$BASE/jurassic-park-t-rex-roar.mp3"
dl "trex-scream.mp3"        "$BASE/jurassic-park-t-rex-roar-2.mp3"
dl "raptor-screech.mp3"     "$BASE/velociraptor-screech-3.mp3"
dl "raptor-bark.mp3"        "$BASE/raptor-sound-effect.mp3"
dl "raptor-call.mp3"        "$BASE/velociraptor.mp3"
dl "brachiosaurus.mp3"      "$BASE/brachiosaurus-call-jurassic-park.mp3"
dl "dilophosaurus-spit.mp3" "$BASE/dilophosaurus-spit.mp3"
dl "dilophosaurus-call.mp3" "$BASE/dilophosaurus.mp3"
dl "triceratops.mp3"        "$BASE/triceratops-sound.mp3"
dl "trex-footsteps.mp3"     "$BASE/trex-footsteps.mp3"
dl "trex-vs-raptors.mp3"    "$BASE/jurassic-park-t-rex-saves-the-day.mp3"

# ── Famous quotes ────────────────────────────────────────────────────────────
dl "welcome-to-jurassic-park.mp3" "$BASE/welcome-to-jurassic-park.mp3"
dl "life-finds-a-way.mp3"         "$BASE/life-finds-a-way.mp3"
dl "hold-onto-your-butts.mp3"     "$BASE/hold-onto-your-butts.mp3"
dl "spared-no-expense.mp3"        "$BASE/spared-no-expense.mp3"
dl "clever-girl.mp3"              "$BASE/clever-girl-jurassic-park.mp3"
dl "unix-system.mp3"              "$BASE/its-a-unix-system-i-know-this.mp3"
dl "must-go-faster.mp3"           "$BASE/must-go-faster-jurassic-park.mp3"

# ── Music ────────────────────────────────────────────────────────────────────
dl "jurassic-park-theme.mp3" "$BASE/jurassic-park-theme-song.mp3"
dl "danger-theme.mp3"        "$BASE/jurassic-park-danger-theme.mp3"

# ── Ambient ──────────────────────────────────────────────────────────────────
dl "jungle-ambience.mp3" "$BASE/jungle-ambience.mp3"
dl "electric-fence.mp3"  "$BASE/electric-fence.mp3"

echo ""
echo "─────────────────────────────────────────────────────────────"
echo "Done! Files saved to: $SOUNDS_DIR"
echo ""

# Report any that failed (file exists but is 0 bytes or HTML error page)
FAILED=()
for f in "$SOUNDS_DIR"/*.mp3; do
  size=$(wc -c < "$f")
  if [[ "$size" -lt 1000 ]]; then
    FAILED+=("$(basename "$f")")
  fi
done

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "⚠️  The following files may have failed to download (too small):"
  for f in "${FAILED[@]}"; do echo "   • $f"; done
  echo ""
  echo "For missing files, try searching https://www.myinstants.com/en/search/?name=jurassic+park"
  echo "and downloading manually, then rename and place in the sounds/ folder."
fi

echo "🦕  Open index.html in your browser to test, or push to GitHub Pages!"
echo ""
