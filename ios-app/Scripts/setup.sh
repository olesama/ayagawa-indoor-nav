#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ICON_DIR="$ROOT/Resources/Assets.xcassets/AppIcon.appiconset"
if [ ! -f "$ICON_DIR/AppIcon-1024.png" ]; then
  SOURCE="$ICON_DIR/AppIcon-source.png"
  base64 --decode "$ICON_DIR/AppIcon-source.png.base64" > "$SOURCE" 2>/dev/null || \
  base64 -D "$ICON_DIR/AppIcon-source.png.base64" > "$SOURCE"
  sips -z 1024 1024 "$SOURCE" --out "$ICON_DIR/AppIcon-1024.png" >/dev/null
  rm -f "$SOURCE"
fi
echo "iOS assets are ready."
