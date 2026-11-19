#!/bin/bash
# Installs the Tokyo Night theme for the GRUB boot menu.
# Run with: sudo bash ~/.local/share/rice-boot-themes/install-grub-theme.sh
#
# It never runs grub-install and never changes UEFI boot entries.
# The new menu is built and checked in a separate file. The working menu is
# replaced only after every check passes.
set -euo pipefail

ROOT="${RICE_TEST_ROOT:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$HERE/grub/tokyo-night"
DEFAULTS="$ROOT/etc/default/grub"
GRUB_DIR="$ROOT/boot/grub"
CFG="$GRUB_DIR/grub.cfg"
NEW_CFG="$GRUB_DIR/grub.cfg.new"
TARGET="$GRUB_DIR/themes/tokyo-night"
# GRUB reads this path at boot, so it never includes the test folder
THEME_PATH="/boot/grub/themes/tokyo-night/theme.txt"

if [[ -z $ROOT && $EUID -ne 0 ]]; then
    echo "Please run this with sudo." >&2
    exit 1
fi

[[ -s $DEFAULTS ]] || { echo "Not found: $DEFAULTS" >&2; exit 1; }
[[ -s $CFG ]] || { echo "Not found: $CFG" >&2; exit 1; }
[[ -s $SOURCE/theme.txt && -s $SOURCE/background.jpg ]] || { echo "Theme files missing in $SOURCE" >&2; exit 1; }
compgen -G "$SOURCE/*.pf2" >/dev/null || { echo "Theme fonts missing in $SOURCE" >&2; exit 1; }

needed_kb=$(( $(du -sk "$SOURCE" | cut -f1) + 2048 ))
free_kb=$(df --output=avail -k "$GRUB_DIR" | tail -1 | tr -d ' ')
if (( free_kb < needed_kb )); then
    echo "Not enough space on /boot: need ${needed_kb} KB, have ${free_kb} KB." >&2
    exit 1
fi

# Backups. An existing .bak is kept and a dated backup is made instead.
backup() {
    local file=$1 name="$1.bak"
    [[ -e $name ]] && name="$1.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$file" "$name"
    cmp -s "$file" "$name"
    echo "Backup: $name"
    LAST_BACKUP=$name
}
backup "$DEFAULTS"
DEFAULTS_BACKUP=$LAST_BACKUP
backup "$CFG"

# If anything fails from here on, put the settings file back.
# The working grub.cfg has not been touched at that point.
finished=no
on_exit() {
    if [[ $finished != yes ]]; then
        cp "$DEFAULTS_BACKUP" "$DEFAULTS"
        rm -f "$NEW_CFG"
        echo "Something failed. Your boot menu was not changed." >&2
    fi
}
trap on_exit EXIT

mkdir -p "$TARGET"
cp "$SOURCE"/* "$TARGET"/

set_option() { # name, value
    if grep -qE "^#?$1=" "$DEFAULTS"; then
        sed -i -E "0,/^#?$1=.*/s||$1=\"$2\"|" "$DEFAULTS"
    else
        printf '%s="%s"\n' "$1" "$2" >> "$DEFAULTS"
    fi
}
set_option GRUB_THEME "$THEME_PATH"
set_option GRUB_GFXMODE "1920x1080,auto"

grub-mkconfig -o "$NEW_CFG"

# Checks on the new menu before it is used
grub-script-check "$NEW_CFG"
grep -q "^menuentry " "$NEW_CFG" || { echo "New menu has no boot entries." >&2; exit 1; }
# /boot is its own partition, so GRUB writes this path without "/boot"
grep -qF "/grub/themes/tokyo-night/theme.txt" "$NEW_CFG" || { echo "New menu does not load the theme." >&2; exit 1; }

kernel_lines() { grep -E '^[[:space:]]*(linux|initrd)[[:space:]]' "$1" | sed -E 's/^[[:space:]]+//' | sort -u; }
[[ -n $(kernel_lines "$NEW_CFG") ]] || { echo "New menu has no kernel lines." >&2; exit 1; }
if ! diff <(kernel_lines "$CFG") <(kernel_lines "$NEW_CFG"); then
    echo "The kernel lines above differ from your working menu, so nothing was changed." >&2
    exit 1
fi

mv "$NEW_CFG" "$CFG"
sync
finished=yes

echo "Done. The Tokyo Night boot menu appears on the next restart."
echo "To undo: sudo cp $DEFAULTS_BACKUP $DEFAULTS && sudo grub-mkconfig -o /boot/grub/grub.cfg"
