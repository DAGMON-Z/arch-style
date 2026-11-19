#!/bin/bash
# Installs the Tokyo Night login theme for SDDM.
# Run with: sudo bash ~/.local/share/rice-boot-themes/install-sddm-theme.sh
# It does not restart SDDM, so your current session is not interrupted.
set -euo pipefail

ROOT="${RICE_TEST_ROOT:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$HERE/sddm/tokyo-night"
THEMES="$ROOT/usr/share/sddm/themes"
TARGET="$THEMES/tokyo-night"
CONF_DIR="$ROOT/etc/sddm.conf.d"
CONF="$CONF_DIR/10-tokyo-night.conf"

if [[ -z $ROOT && $EUID -ne 0 ]]; then
    echo "Please run this with sudo." >&2
    exit 1
fi

for file in Main.qml metadata.desktop theme.conf background.jpg; do
    [[ -s $SOURCE/$file ]] || { echo "Missing $SOURCE/$file" >&2; exit 1; }
done
[[ -d $THEMES ]] || { echo "SDDM theme folder not found: $THEMES" >&2; exit 1; }

# Keep a copy of an earlier version of our own files
[[ -e $CONF ]] && cp -n "$CONF" "$CONF.bak"
[[ -e $TARGET ]] && [[ ! -e $TARGET.bak ]] && cp -r "$TARGET" "$TARGET.bak"

# Copy to a temporary folder first, so a failed copy changes nothing
TEMP="$THEMES/.tokyo-night.new"
rm -rf "$TEMP"
mkdir -p "$TEMP"
cp "$SOURCE"/Main.qml "$SOURCE"/metadata.desktop "$SOURCE"/theme.conf "$SOURCE"/background.jpg "$TEMP"/
chmod 755 "$TEMP"
chmod 644 "$TEMP"/*
rm -rf "$TARGET"
mv "$TEMP" "$TARGET"

mkdir -p "$CONF_DIR"
cat > "$CONF" <<'EOF'
[Theme]
Current=tokyo-night
CursorTheme=capitaine-cursors
CursorSize=24
EOF
chmod 644 "$CONF"

echo "Done. The new login screen appears the next time SDDM starts."
echo "To undo: sudo rm $CONF"
