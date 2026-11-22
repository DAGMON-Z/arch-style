#!/bin/bash
# Copies the current config files into this repository.
# Run this before committing: ./sync.sh
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Paths inside your home folder
HOME_ITEMS=(
    .config/hypr
    .config/waybar
    .config/kitty
    .config/rofi
    .config/dunst
    .config/nvim
    .config/starship.toml
    .bashrc
    .zshrc
    .local/share/rice-boot-themes
    # GTK, Qt and KDE theme
    .config/gtk-3.0
    .config/gtk-4.0
    .config/qt6ct
    .config/kdeglobals
    .config/dolphinrc
    .local/share/color-schemes/TokyoNight.colors
    .icons/default/index.theme
    # Other tools
    .config/fastfetch
    .config/Thunar/uca.xml
    .config/persepolis_download_manager/persepolis.conf
    .config/spotify-launcher.conf
    .config/fontconfig/fonts.conf
    .config/clangd
    .clang-format
    .local/share/applications/pc2.desktop
)

# Paths outside your home folder
SYSTEM_ITEMS=(
    /usr/local/bin/touchpad-i2c-reset
    /etc/systemd/system/touchpad-i2c-reset.service
    /usr/local/bin/power-profile-auto
    /etc/udev/rules.d/99-power-profile-auto.rules
    /etc/systemd/system/power-profile-auto.service
)

# Start clean, so files you deleted also disappear from the backup.
# system/ is not cleaned: the repository is the source for those files.
rm -rf "$REPO/home"
mkdir -p "$REPO/home" "$REPO/system"

# monitors.lua holds settings for one computer only, so it is never copied
tar -C "$HOME" --exclude='*.bak' --exclude='*.bak.*' --exclude='.git' --exclude='monitors.lua' \
    -cf - "${HOME_ITEMS[@]}" | tar -C "$REPO/home" -xf -

# ~/.local/bin: real files only. Links to installed programs are skipped.
if [[ -d $HOME/.local/bin ]]; then
    while IFS= read -r -d '' file; do
        mkdir -p "$REPO/home/.local/bin"
        cp -p "$file" "$REPO/home/.local/bin/"
    done < <(find "$HOME/.local/bin" -maxdepth 1 -type f -print0)
fi

# System files are installed FROM this repository, so they are never copied
# back (that could undo a newer fix). New ones are added once; after that,
# a difference only prints a warning.
for file in "${SYSTEM_ITEMS[@]}"; do
    if [[ ! -e $REPO/system$file ]]; then
        [[ -e $file ]] || continue
        mkdir -p "$REPO/system$(dirname "$file")"
        cp -p "$file" "$REPO/system$file"
        echo "Added new system file: $file"
    elif [[ -e $file ]] && ! cmp -s "$file" "$REPO/system$file"; then
        echo "Note: $file differs from the repository's version."
        echo "      To install the repository's version: bash $REPO/install.sh --update"
        echo "      To keep your change instead, edit $REPO/system$file"
    fi
done

# Replace your home folder path with @HOME@, so the repository does not
# contain your username. install.sh puts the reader's own path back.
grep -rlIF "$HOME" "$REPO/home" | while IFS= read -r file; do
    sed -i "s#$HOME#@HOME@#g" "$file"
done

# Stop if anything looks like a password, token or private key
pattern='(pass(word|wd)|api[_-]?key|secret|auth[_-]?token|access[_-]?token)[[:space:]]*[=:][[:space:]]*[^[:space:]]'
pattern+='|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_|sk-[A-Za-z0-9-]{20,}|AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY'
if matches=$(grep -rIlEi "$pattern" "$REPO/home" "$REPO/system"); then
    echo "Possible secrets found. Check these files before committing:" >&2
    echo "$matches" >&2
    exit 1
fi

echo "Sync complete. Next: git status"
