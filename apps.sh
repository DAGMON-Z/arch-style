#!/bin/bash
# My personal apps: one command installs them all.
#
#   bash apps.sh            show the list, ask once, then install everything
#   bash apps.sh --yes      install without asking
#   bash apps.sh --dry-run  only show what would happen, change nothing
#
# It installs:
#   - apps/official.txt  from the official Arch repositories (pacman)
#   - apps/aur.txt       from the AUR, the community repository (yay)
#   - Claude Code        with Anthropic's own installer, if it's missing
#   - an "Outlook" app   Outlook on the web in its own window (Outlook classic
#                        is Windows-only)
# and sets up VirtualBox (kernel part for your kernel, USB access).
# Restart afterwards so VirtualBox can load its kernel part.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=no
YES=no
FAILED=()

for arg in "$@"; do
    case $arg in
        --yes) YES=yes ;;
        --dry-run) DRY=yes ;;
        -h|--help) sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

if [[ $EUID -eq 0 ]]; then
    echo "Please run this as your normal user, not with sudo." >&2
    exit 1
fi

# run a command, or only print it with --dry-run
run() {
    if [[ $DRY == yes ]]; then
        printf '  would run:'; printf ' %q' "$@"; echo
        return 0
    fi
    "$@"
}

# try "name" command...: a failure prints a warning and the script carries on
try() {
    local name=$1
    shift
    if ! run "$@"; then
        echo "  WARNING: \"$name\" failed. Continuing."
        FAILED+=("$name")
    fi
}

# VirtualBox needs "headers" for each installed kernel to build its kernel part
headers=()
for kernel in linux linux-lts linux-zen linux-hardened; do
    pacman -Q "$kernel" >/dev/null 2>&1 && headers+=("$kernel-headers")
done
mapfile -t official < <(grep -v '^\s*$' "$REPO/apps/official.txt")
mapfile -t aur < <(grep -v '^\s*$' "$REPO/apps/aur.txt")
official+=("${headers[@]}")

echo "Personal apps installer"
[[ $DRY == yes ]] && echo "DRY RUN: nothing will be changed."
echo
echo "From the official repositories:"
echo "  ${official[*]}" | fold -s -w 78
echo "From the AUR (made by the community, not by Arch):"
echo "  ${aur[*]}" | fold -s -w 78
echo "Plus: Claude Code (if missing), an Outlook web app, and VirtualBox setup."
if [[ $YES == no && $DRY == no ]]; then
    echo
    read -r -p "Install all of this? [y/N] " answer
    [[ $answer == [yY]* ]] || { echo "Nothing was installed."; exit 0; }
fi

if [[ $DRY == no ]]; then
    echo
    echo "Enter your password once. It's kept for the whole install."
    sudo -v
    while kill -0 $$ 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done &
    trap 'kill $! 2>/dev/null' EXIT
fi

# 1. Official packages
echo
echo "1. Official packages"
try "official packages" sudo pacman -S --needed --noconfirm "${official[@]}"

# 2. yay, then AUR packages
echo
echo "2. AUR packages"
if ! command -v yay >/dev/null 2>&1; then
    echo "  yay is not installed. Building it from the AUR:"
    try "build yay" sudo pacman -S --needed --noconfirm git base-devel
    build="$(mktemp -d)"
    try "build yay" git clone https://aur.archlinux.org/yay.git "$build/yay"
    if [[ $DRY == no && -d $build/yay ]]; then
        (cd "$build/yay" && makepkg -si --noconfirm) || FAILED+=("build yay")
    fi
    rm -rf "$build"
fi
try "AUR packages" yay -S --needed --noconfirm --answerclean None --answerdiff None --removemake "${aur[@]}"

# 3. Claude Code, with Anthropic's own installer
echo
echo "3. Claude Code"
if command -v claude >/dev/null 2>&1; then
    echo "  already installed"
elif [[ $DRY == yes ]]; then
    echo "  would run: curl -fsSL https://claude.ai/install.sh | bash"
else
    curl -fsSL https://claude.ai/install.sh | bash || FAILED+=("Claude Code")
fi

# 4. Outlook: classic Outlook is Windows-only, so add Outlook on the web as an app
echo
echo "4. Outlook (web app)"
desktop="$HOME/.local/share/applications/outlook-web.desktop"
if [[ $DRY == yes ]]; then
    echo "  would create: ${desktop/#$HOME/\~}"
else
    mkdir -p "$(dirname "$desktop")"
    cat > "$desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Outlook
Comment=Outlook on the web in its own window
Exec=brave --app=https://outlook.office.com/mail/
Icon=solstice-microsoft-outlook
Categories=Network;Email;
StartupWMClass=outlook.office.com__mail
EOF
    echo "  added \"Outlook\" to your app list"
fi

# 5. VirtualBox: load its kernel part and allow USB devices
echo
echo "5. VirtualBox setup"
if getent group vboxusers >/dev/null 2>&1 || [[ $DRY == yes ]]; then
    try "VirtualBox USB access" sudo usermod -aG vboxusers "$USER"
fi
run sudo modprobe vboxdrv 2>/dev/null ||
    echo "  The VirtualBox kernel part loads after you restart."

echo
if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo "Finished, but these had problems:"
    printf '  - %s\n' "${FAILED[@]}" | sort -u
    echo "Run the script again later; finished parts are skipped."
else
    echo "All done."
fi
[[ $DRY == yes ]] && echo "(That was a dry run. Nothing was changed.)"
echo "Restart your computer so VirtualBox and the new kernel part are ready."
