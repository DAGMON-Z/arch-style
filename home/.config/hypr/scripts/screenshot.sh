#!/bin/bash
# Takes a screenshot and shows a notification with the result.
# Usage: screenshot.sh full | area-copy | area-save
#   full       whole screen, saved to ~/Pictures/Screenshots
#   area-copy  drag to select an area, copied to the clipboard
#   area-save  drag to select an area, saved to ~/Pictures/Screenshots

DIR="$HOME/Pictures/Screenshots"
FILE="$DIR/$(date +%Y%m%d_%H%M%S).png"
mkdir -p "$DIR"

# Show a notification through dunst (same way as the volume popup)
notify() { # title, text, image (optional), urgency (0 low, 1 normal, 2 critical)
    busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications \
        org.freedesktop.Notifications Notify 'susssasa{sv}i' \
        screenshot 0 "${3:-}" "$1" "$2" 0 1 urgency y "${4:-1}" 4000 >/dev/null
}

failed() { notify "Screenshot failed" "$1" "" 2; exit 1; }

case "$1" in
    full)
        grim "$FILE" || failed "grim could not capture the screen"
        notify "Screenshot saved" "${FILE/#$HOME/\~}" "$FILE"
        ;;
    area-copy)
        # slurp lets you drag a box. Pressing Esc cancels, which is not an error.
        area=$(slurp -d) || exit 0
        grim -g "$area" - | wl-copy --type image/png || failed "could not copy to the clipboard"
        notify "Screenshot copied" "Paste it with Ctrl+V"
        ;;
    area-save)
        area=$(slurp -d) || exit 0
        grim -g "$area" "$FILE" || failed "grim could not capture the area"
        notify "Screenshot saved" "${FILE/#$HOME/\~}" "$FILE"
        ;;
    *)
        echo "Usage: $0 full | area-copy | area-save" >&2
        exit 1
        ;;
esac
