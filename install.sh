#!/bin/bash
# Arch Style installer
#
# Please read this file before running it. It:
#   1. installs the packages in packages.txt with pacman
#   2. installs yay (if needed) and the AUR packages in aur-packages.txt
#   3. copies the config files from home/ into your home folder
#   4. sets dark mode, icons, cursor and font
#   5. turns on the services this setup needs, and optionally switches to
#      power-saver automatically on battery
#   6. optionally installs the MSI Modern 15 touchpad fix (hardware-specific!)
#   7. installs the login screen theme (SDDM)
#   8. installs the boot menu theme (GRUB)
#   9. sets your wallpaper
#
# Any file it would replace is backed up first, to <file>.bak, or
# <file>.bak.<date-time> if a .bak already exists.
#
# Usage (as your normal user, not with sudo):
#   bash install.sh                  ask before each step
#   bash install.sh --dry-run        only show what would happen, change nothing
#   bash install.sh --all            do every general step without asking
#   bash install.sh --all --wallpaper ~/Pictures/my-image.jpg
#
# --all never installs the AUR apps (community-made) or the MSI touchpad fix
# (one laptop model only). Run without --all to choose those yourself.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
ALL=no
DRY=no
WALLPAPER=""
FAILED=()

usage() {
    sed -n '/^# Usage/,/^# (one laptop/p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --all) ALL=yes ;;
        --dry-run) DRY=yes ;;
        --wallpaper)
            [[ $# -ge 2 ]] || usage 1
            WALLPAPER="${2/#\~/$HOME}"
            shift
            ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1" >&2; usage 1 ;;
    esac
    shift
done

if [[ $EUID -eq 0 ]]; then
    echo "Please run this as your normal user, not with sudo." >&2
    exit 1
fi
if [[ -n $WALLPAPER && ! -f $WALLPAPER ]]; then
    echo "Wallpaper not found: $WALLPAPER" >&2
    exit 1
fi

# ask "question": yes or no. With --all, the answer is always yes.
ask() {
    local answer
    echo
    if [[ $ALL == yes ]]; then
        echo "$1 yes (--all)"
        return 0
    fi
    read -r -p "$1 [y/N] " answer
    [[ $answer == [yY]* ]]
}

# ask_yourself "question": like ask, but --all always skips it
ask_yourself() {
    echo
    if [[ $ALL == yes ]]; then
        echo "$1 skipped (--all never does this; run without --all to choose)"
        return 1
    fi
    ask "$1"
}

# run a command, or only print it with --dry-run
run() {
    if [[ $DRY == yes ]]; then
        printf '  would run:'
        printf ' %q' "$@"
        echo
        return 0
    fi
    "$@"
}

# try "step name" command...: like run, but a failure doesn't stop the installer
try() {
    local name=$1
    shift
    if ! run "$@"; then
        echo "  WARNING: \"$name\" failed. Continuing with the next step."
        FAILED+=("$name")
    fi
}

# Install from a package list file (pacman and yay read names from input)
install_list() { # tool, list file
    local tool=$1 list=$2 extra=()
    [[ $ALL == yes ]] && extra=(--noconfirm)
    if [[ $DRY == yes ]]; then
        echo "  would run: $tool -S --needed ${extra[*]} - < $(basename "$list")"
        return 0
    fi
    if [[ $tool == pacman ]]; then
        sudo pacman -S --needed "${extra[@]}" - < "$list"
    else
        yay -S --needed - < "$list"
    fi
}

# Copy one file into place, backing up anything different that is already there
place() {
    local source=$1 target=$2 backup ready
    ready="$(mktemp)"
    cp -p "$source" "$ready"
    # Put the real home folder where the repository has @HOME@
    if grep -qF '@HOME@' "$ready"; then
        sed -i "s#@HOME@#$HOME#g" "$ready"
    fi
    if [[ -e $target || -L $target ]] && cmp -s "$ready" "$target"; then
        rm -f "$ready"
        return 0
    fi
    if [[ $DRY == yes ]]; then
        [[ -e $target ]] && echo "  would back up and replace: ${target/#$HOME/\~}" ||
            echo "  would copy: ${target/#$HOME/\~}"
        rm -f "$ready"
        return 0
    fi
    mkdir -p "$(dirname "$target")"
    if [[ -e $target || -L $target ]]; then
        backup="$target.bak"
        [[ -e $backup ]] && backup="$target.bak.$STAMP"
        cp -a "$target" "$backup"
        echo "  backup: $backup"
    fi
    mv "$ready" "$target"
}

echo "Arch Style installer"
[[ $DRY == yes ]] && echo "DRY RUN: nothing will be changed."
if [[ $ALL == yes ]]; then
    echo "--all: every general step runs without questions."
    if [[ $DRY == no ]]; then
        echo "Enter your password once. It is kept for the whole install."
        sudo -v
        # Keep sudo's password memory fresh while the installer runs
        while kill -0 $$ 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done &
        KEEPALIVE=$!
        trap 'kill $KEEPALIVE 2>/dev/null' EXIT
    fi
else
    echo "Answer y to run a step, or press Enter to skip it."
fi

# 1. Official packages
echo
echo "Step 1 installs these packages from the official repositories (packages.txt):"
tr '\n' ' ' < "$REPO/packages.txt" | fold -s -w 76 | sed 's/^/  /'
echo
if ask "Install official packages?"; then
    if ! install_list pacman "$REPO/packages.txt"; then
        echo "Installing packages failed. The other steps need them, so stopping here." >&2
        exit 1
    fi
fi

# 2. AUR packages
echo
echo "Step 2 installs these AUR packages (aur-packages.txt) with yay:"
sed 's/^/  /' "$REPO/aur-packages.txt"
echo "AUR packages are made by the community, not by Arch. yay shows each build"
echo "file (PKGBUILD) before installing, so you can check it."
if ask_yourself "Install AUR packages?"; then
    if ! command -v yay >/dev/null 2>&1; then
        echo "  yay is not installed. Building it from the AUR:"
        try "build yay" sudo pacman -S --needed git base-devel
        build="$(mktemp -d)"
        try "build yay" git clone https://aur.archlinux.org/yay.git "$build/yay"
        if [[ $DRY == no && -d $build/yay ]]; then
            (cd "$build/yay" && makepkg -si) || FAILED+=("build yay")
        fi
        rm -rf "$build"
    fi
    install_list yay "$REPO/aur-packages.txt" || FAILED+=("AUR packages")
fi

# 3. Config files
echo
echo "Step 3 copies these config files into $HOME:"
(cd "$REPO/home" && find . -type f | sed 's#^\./#  ~/#' | sort)
if ask "Copy config files?"; then
    while IFS= read -r -d '' file; do
        rel=${file#"$REPO/home/"}
        place "$file" "$HOME/$rel"
    done < <(find "$REPO/home" -type f -print0)
    run mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots"
    echo "  done"
fi

# 4. Desktop settings (these are stored by gsettings, not in files)
if ask "Step 4: set dark mode, Papirus icons, cursor and monospace font?"; then
    try "desktop settings" gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    try "desktop settings" gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
    try "desktop settings" gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
    try "desktop settings" gsettings set org.gnome.desktop.interface cursor-theme capitaine-cursors
    try "desktop settings" gsettings set org.gnome.desktop.interface cursor-size 24
    try "desktop settings" gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'
fi

# 5. Services
echo
echo "Step 5 turns on:"
echo "  system: NetworkManager (network), bluetooth, sddm (login screen),"
echo "          power-profiles-daemon (power modes), thermald (Intel cooling)"
echo "  user:   hyprpolkitagent (password popups), hypridle (lock and suspend),"
echo "          pipewire, pipewire-pulse and wireplumber (sound)"
if ask "Turn on services?"; then
    try "system services" sudo systemctl enable --now NetworkManager.service bluetooth.service \
        power-profiles-daemon.service thermald.service
    # sddm is only enabled, not started, so it can't interrupt a running session
    try "login screen service" sudo systemctl enable sddm.service
    if ! run systemctl --user enable --now hyprpolkitagent.service hypridle.service \
            pipewire.socket pipewire-pulse.socket wireplumber.service; then
        echo "  Could not start your user services now (normal outside Hyprland)."
        echo "  Run this after logging in to Hyprland:"
        echo "  systemctl --user enable --now hyprpolkitagent.service hypridle.service"
    fi
fi

echo
echo "Optional: switch to power-saver on battery and balanced on the charger."
echo "Works on most laptops. See docs/12-power-management.md."
if ask "Install automatic power-saver on battery?"; then
    try "power-saver on battery" sudo install -m 755 "$REPO/system/usr/local/bin/power-profile-auto" /usr/local/bin/power-profile-auto
    try "power-saver on battery" sudo install -m 644 "$REPO/system/etc/udev/rules.d/99-power-profile-auto.rules" /etc/udev/rules.d/99-power-profile-auto.rules
    try "power-saver on battery" sudo install -m 644 "$REPO/system/etc/systemd/system/power-profile-auto.service" /etc/systemd/system/power-profile-auto.service
    try "power-saver on battery" sudo udevadm control --reload
    try "power-saver on battery" sudo systemctl daemon-reload
    try "power-saver on battery" sudo systemctl enable --now power-profile-auto.service
fi

# 6. Touchpad fix: only for one laptop model
MODEL="$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo unknown)"
echo
echo "Step 6 is a touchpad fix for the MSI Modern 15 F13MG ONLY."
echo "Your computer reports its model as: $MODEL"
echo "Skip this unless you have that laptop and its touchpad fails with error -110."
if ask_yourself "Install the MSI Modern 15 touchpad fix?"; then
    try "touchpad fix" sudo install -m 755 "$REPO/system/usr/local/bin/touchpad-i2c-reset" /usr/local/bin/touchpad-i2c-reset
    try "touchpad fix" sudo install -m 644 "$REPO/system/etc/systemd/system/touchpad-i2c-reset.service" /etc/systemd/system/touchpad-i2c-reset.service
    try "touchpad fix" sudo systemctl daemon-reload
    try "touchpad fix" sudo systemctl enable touchpad-i2c-reset
fi

# 7. Login screen theme
if ask "Step 7: install the Tokyo Night login screen theme (SDDM)?"; then
    try "login screen theme" sudo bash "$REPO/home/.local/share/rice-boot-themes/install-sddm-theme.sh"
fi

# 8. Boot menu theme
echo
echo "Step 8 changes your GRUB boot menu. It only works if GRUB is your"
echo "bootloader and /boot is its own partition. It keeps backups and checks"
echo "the new menu before using it. See docs/10-boot-and-login-themes.md."
if ask "Install the Tokyo Night boot menu theme (GRUB)?"; then
    try "boot menu theme" sudo bash "$REPO/home/.local/share/rice-boot-themes/install-grub-theme.sh"
fi

# 9. Wallpaper
echo
echo "Step 9 sets one image as the wallpaper everywhere."
if [[ -z $WALLPAPER && $ALL == yes ]]; then
    # No image given: use the wallpaper that comes with the themes
    WALLPAPER="$REPO/home/.local/share/rice-boot-themes/sddm/tokyo-night/background.jpg"
    echo "No --wallpaper given, so using the included sci-fi city wallpaper."
    echo "Later, run: set-wallpaper ~/Pictures/Wallpapers/your-image.jpg"
elif [[ -z $WALLPAPER ]]; then
    read -r -p "Path to your own image (or press Enter for the included wallpaper): " WALLPAPER
    WALLPAPER="${WALLPAPER/#\~/$HOME}"
    if [[ -z $WALLPAPER ]]; then
        WALLPAPER="$REPO/home/.local/share/rice-boot-themes/sddm/tokyo-night/background.jpg"
    fi
fi
if [[ -n $WALLPAPER ]]; then
    try "wallpaper" "$HOME/.local/bin/set-wallpaper" "$WALLPAPER"
fi

echo
if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo "Finished, but these steps had problems:"
    printf '  - %s\n' "${FAILED[@]}" | sort -u
    echo "See docs/11-troubleshooting.md, or run the installer again later."
else
    echo "All done."
fi
[[ $DRY == yes ]] && echo "(That was a dry run. Nothing was changed.)"
echo "Restart and log in. The session pill at the bottom left of the login screen"
echo "should say \"Hyprland (uwsm-managed)\". Click it to switch if it doesn't."
echo "Then run hyprland-welcome to check that every item is green or blue."
