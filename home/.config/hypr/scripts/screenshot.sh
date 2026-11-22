#!/bin/bash
# Takes a screenshot and shows a notification with the result.
# Usage: screenshot.sh full-copy | area-copy | full-save | area-save
#   full-copy  whole screen, only copied to the clipboard (not saved)
#   area-copy  drag to select an area, only copied (not saved)
#   full-save  whole screen, saved to ~/Pictures/Screenshots and copied
#   area-save  drag to select an area, saved and copied
# Paste a copied screenshot with Ctrl+V.

DIR="$HOME/Pictures/Screenshots"
FILE="$DIR/$(date +%Y%m%d_%H%M%S).png"
# For copy-only screenshots, the notification preview is kept in memory
# ($XDG_RUNTIME_DIR is in RAM and emptied at logout), never on the disk
PREVIEW="${XDG_RUNTIME_DIR:-/tmp}/screenshot-preview.png"

# Show a notification through dunst (same way as the volume popup)
notify() { # title, text, image (optional), urgency (0 low, 1 normal, 2 critical)
    busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications \
        org.freedesktop.Notifications Notify 'susssasa{sv}i' \
        screenshot 0 "${3:-}" "$1" "$2" 0 1 urgency y "${4:-1}" 4000 >/dev/null
}

failed() { notify "Screenshot failed" "$1" "" 2; exit 1; }

# Ask for an area (slurp lets you drag a box). Esc cancels, which isn't an error.
pick_area() { area=$(slurp -d) || exit 0; }

copy_only() { # grim options...
    grim "$@" "$PREVIEW" || failed "grim could not capture the screen"
    wl-copy --type image/png < "$PREVIEW" || failed "could not copy to the clipboard"
    notify "Screenshot copied" "Paste it with Ctrl+V (not saved)" "$PREVIEW"
}

save_and_copy() { # grim options...
    mkdir -p "$DIR"
    grim "$@" "$FILE" || failed "grim could not capture the screen"
    wl-copy --type image/png < "$FILE" || failed "saved, but could not copy to the clipboard"
    notify "Screenshot saved and copied" "${FILE/#$HOME/\~}  (paste with Ctrl+V)" "$FILE"
}

case "$1" in
    full-copy) copy_only ;;
    area-copy) pick_area; copy_only -g "$area" ;;
    full-save | full) save_and_copy ;;   # "full" is the old name
    area-save) pick_area; save_and_copy -g "$area" ;;
    *)
        echo "Usage: $0 full-copy | area-copy | full-save | area-save" >&2
        exit 1
        ;;
esac
