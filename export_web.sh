#!/usr/bin/env bash
# Export the "Web" preset and pack it as a zip ready for itch.io upload.
# Usage: ./export_web.sh            -> build/alienshift-web.zip
set -euo pipefail
cd "$(dirname "$0")"

rm -rf build/web
mkdir -p build/web
# Keep Godot from importing the build output as project assets.
touch build/.gdignore

godot --headless --export-release "Web" build/web/index.html

# itch.io needs index.html at the root of the zip (not inside a folder).
rm -f build/alienshift-web.zip
(cd build/web && zip -qr ../alienshift-web.zip .)

echo "Done: build/alienshift-web.zip"
