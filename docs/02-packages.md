# 2. Packages and what they do

## The package lists

This repository has two lists of exactly what this setup needs:

| File | What's in it | Installed with |
| --- | --- | --- |
| [`packages.txt`](../packages.txt) | Packages from the official Arch repositories | `pacman` |
| [`aur-packages.txt`](../aur-packages.txt) | Apps from the AUR (the community repository) | `yay` |

`install.sh` installs both, asking first. To do it by hand:

```bash
cd ~/arch-style
sudo pacman -S --needed - < packages.txt
```

- `-S` installs packages.
- `--needed` skips packages you already have.
- `-` means "read the package names from the input", and `< packages.txt`
  sends the file as that input.

### AUR packages

AUR packages are made by the community, not by Arch, so read their build files
before installing. You need an *AUR helper* such as `yay`. If you don't have it:

```bash
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay && makepkg -si
```

Then:

```bash
cd ~/arch-style
yay -S --needed - < aur-packages.txt
```

The AUR list has `brave-bin` (web browser) and `anydesk-bin` (remote desktop).
They're personal apps, so this setup works without them.

## Hyprland welcome app checklist

When you first log in to Hyprland, the **welcome app** (`hyprland-welcome`)
checks for the parts a working desktop needs. Items marked * are required.
Every item is covered by `packages.txt`:

| Welcome app item | Package in this setup | Other options the app accepts |
| --- | --- | --- |
| Authentication agent * | `hyprpolkitagent` | `polkit-kde-agent` |
| File manager * | `thunar` | dolphin, nautilus, nemo, pcmanfm, ranger, yazi |
| Terminal * | `kitty` | alacritty, foot, wezterm, konsole, gnome-terminal, xterm |
| Pipewire * | `pipewire` (plus `wireplumber`, `pipewire-pulse`) | |
| XDG Desktop Portal * | `xdg-desktop-portal-hyprland` | |
| Notification daemon * | `dunst` | mako |
| Clipboard * | `wl-clipboard` (provides `wl-copy`) | |
| Wallpaper | `awww` (this setup) and `hyprpaper` (kept as a backup) | swww |
| Status bar / shell | `waybar` | quickshell |
| Application launcher | `rofi` | hyprlauncher, fuzzel, wofi |

The app shows the first program it finds in each group. Green means installed,
blue means running. Hover over an item to see every option it accepts. It may
show `hyprpaper` instead of `awww`, or `wofi` instead of `rofi`, if those are
installed too. That's fine.

Run it again any time with `hyprland-welcome`.

## Services this setup needs

A **service** is a program that systemd starts for you. `install.sh` turns
these on:

| Service | Type | What it does |
| --- | --- | --- |
| `NetworkManager.service` | system | Wi-Fi and wired network |
| `bluetooth.service` | system | Bluetooth (managed with Blueman, by clicking the bar icon) |
| `sddm.service` | system | Login screen |
| `hyprpolkitagent.service` | user | Shows the password popup when an app needs admin rights |
| `hypridle.service` | user | Locks after 5 minutes and suspends after 15 |
| `pipewire.socket`, `pipewire-pulse.socket`, `wireplumber.service` | user | Sound (usually already on) |
| `power-profiles-daemon.service` | system | Power modes: power-saver, balanced, performance |
| `thermald.service` | system | Intel thermal control (Intel CPUs only) |
| `power-profile-auto.service` | system | Optional: picks the power mode at boot from the charger state ([chapter 12](12-power-management.md)) |

To turn on the user services by hand, from inside Hyprland:

```bash
systemctl --user enable --now hyprpolkitagent.service hypridle.service
```

*System* services run for the whole computer and need `sudo`. *User* services
run for your account (`systemctl --user`).

These don't need a service, because they start on demand or from
`hyprland.lua`:

- dunst starts when the first notification arrives.
- The portals start when an app asks for them.
- Waybar, the wallpaper and clipboard history start from `hyprland.lua`.

> The touchpad fix (`touchpad-i2c-reset.service`) is **not** turned on with
> these. It's only for the MSI Modern 15 F13MG, and `install.sh` asks about it
> separately (see [troubleshooting](11-troubleshooting.md#touchpad-error--110)).

## Everything installed on my laptop

For reference, these are all the packages I installed on purpose
(`pacman -Qqe`), including ones that came with archinstall. Packages pulled in
automatically as dependencies aren't listed. You don't need all of these.
`packages.txt` is the list for this setup.

### Desktop core

Hyprland itself, the session manager that starts it (uwsm), screen sharing and file dialogs (portals), and the password popup for admin actions (polkit agents).

| Package | What it is |
| --- | --- |
| `hyprland` | a highly customizable dynamic tiling Wayland compositor |
| `uwsm` | A standalone Wayland session manager |
| `xdg-desktop-portal-hyprland` | xdg-desktop-portal backend for hyprland |
| `xdg-desktop-portal-gtk` | A backend implementation for xdg-desktop-portal using GTK |
| `hyprpolkitagent` | Simple polkit authentication agent for Hyprland, written in QT/QML |
| `polkit-kde-agent` | Daemon providing a polkit authentication UI for KDE |
| `qt5-wayland` | Provides APIs for Wayland |
| `qt6-wayland` | Provides APIs for Wayland |

### Bar, launcher, notifications, lock, wallpaper

The parts you see and use every day. wofi is a second launcher that came with the Hyprland profile; rofi is the one this setup uses. hyprpaper was replaced by awww.

| Package | What it is |
| --- | --- |
| `waybar` | Highly customizable Wayland bar for Sway and Wlroots based compositors |
| `rofi` | A window switcher, application launcher and dmenu replacement |
| `wofi` | launcher for wlroots-based wayland compositors |
| `dunst` | Customizable and lightweight notification-daemon |
| `hyprlock` | hyprland’s GPU-accelerated screen locking utility |
| `hypridle` | hyprland’s idle daemon |
| `hyprpaper` | a blazing fast wayland wallpaper utility with IPC controls |
| `awww` | An Answer to your Wayland Wallpaper Woes |

### Screenshots, clipboard, keys

grim takes screenshots and slurp lets you select an area. wl-clipboard and cliphist handle copy, paste and history. brightnessctl changes screen brightness.

| Package | What it is |
| --- | --- |
| `grim` | Screenshot utility for Wayland |
| `slurp` | Select a region in a Wayland compositor |
| `wl-clipboard` | Command-line copy/paste utilities for Wayland |
| `cliphist` | wayland clipboard manager |
| `brightnessctl` | Lightweight brightness control tool |

### Terminal, shell and tools

kitty is the terminal, starship the prompt, fastfetch the system summary. btop and htop show running programs.

| Package | What it is |
| --- | --- |
| `kitty` | A modern, hackable, featureful, OpenGL-based terminal emulator |
| `starship` | The cross-shell prompt for astronauts |
| `fastfetch` | A feature-rich and performance oriented neofetch like system information tool |
| `btop` | A monitor of system resources, bpytop ported to C++ |
| `htop` | Interactive process viewer |
| `less` | A terminal based program for viewing text files |
| `nano` | Pico editor clone with enhancements |
| `vim` | Vi Improved, a highly configurable, improved version of the vi text editor |
| `wget` | Network utility to retrieve files from the web |
| `which` | A utility to show the full path of commands |
| `man-db` | A utility for reading man pages |
| `texinfo` | GNU documentation system for on-line information and printed output |
| `groff` | GNU troff text-formatting system |
| `unzip` | For extracting and viewing files in .zip archives |
| `github-cli` | The GitHub CLI |
| `git` | the fast distributed version control system |

### Sound

PipeWire is the sound system, WirePlumber manages devices, and pavucontrol is the mixer window. sof-firmware is needed by the sound chip on many recent Intel laptops.

| Package | What it is |
| --- | --- |
| `pipewire` | Low-latency audio/video router and processor |
| `pipewire-alsa` | Low-latency audio/video router and processor - ALSA configuration |
| `pipewire-jack` | Low-latency audio/video router and processor - JACK replacement |
| `pipewire-pulse` | Low-latency audio/video router and processor - PulseAudio replacement |
| `wireplumber` | Session / policy manager implementation for PipeWire |
| `pavucontrol` | PulseAudio Volume Control |
| `libpulse` | A featureful, general-purpose sound server (client library) |
| `gst-plugin-pipewire` | Multimedia graph framework - pipewire plugin |
| `sof-firmware` | Sound Open Firmware |

### Network and Bluetooth

NetworkManager connects to Wi-Fi (use nmtui). bluez is the Bluetooth system and bluetoothctl comes with bluez-utils.

| Package | What it is |
| --- | --- |
| `networkmanager` | Network connection manager and user applications |
| `network-manager-applet` | Applet for managing network connections |
| `wpa_supplicant` | A utility providing key negotiation for WPA wireless networks |
| `bluez` | Daemons for the bluetooth protocol stack |
| `bluez-utils` | Development and debugging utilities for the bluetooth protocol stack |

### Looks: themes, icons, fonts

Dark GTK theme, icons, cursor and fonts. Noto fonts cover many languages, including Arabic. nwg-look is a window for GTK settings.

| Package | What it is |
| --- | --- |
| `adw-gtk-theme` | Unofficial GTK 3 port of the libadwaita theme |
| `papirus-icon-theme` | Papirus icon theme |
| `capitaine-cursors` | An x-cursor theme inspired by macOS and based on KDE Breeze |
| `ttf-jetbrains-mono-nerd` | Patched font JetBrains Mono from nerd fonts library |
| `noto-fonts` | Google Noto TTF fonts |
| `noto-fonts-emoji` | Google Noto Color Emoji font |
| `qt6ct` | Qt 6 Configuration Utility |
| `nwg-look` | GTK settings editor adapted to work on wlroots-based compositors |
| `xcur2png` | Convert X cursors to PNG images |

### Files

Dolphin is the file manager (SUPER + E).

| Package | What it is |
| --- | --- |
| `dolphin` | KDE File Manager |

### Editor and programming

Neovim is the editor. gcc and clang compile C and C++; clang also provides clangd. base-devel is needed to build AUR packages.

| Package | What it is |
| --- | --- |
| `neovim` | Fork of Vim aiming to improve user experience, plugins, and GUIs |
| `gcc` | The GNU Compiler Collection - C and C++ frontends |
| `clang` | C language family frontend for LLVM |
| `clang-libs` | Clang runtime libraries |
| `llvm` | Compiler infrastructure |
| `llvm-lit` | An LLVM testing tool |
| `compiler-rt` | Compiler runtime libraries for clang |
| `gdb` | The GNU Debugger |
| `make` | GNU make utility to maintain groups of programs |
| `patch` | A utility to apply patch files to original sources |
| `pkgconf` | Package compiler and linker metadata toolkit |
| `base-devel` | Basic tools to build Arch Linux packages |
| `tree-sitter-cli` | CLI tool for developing, testing, and using Tree-sitter parsers |
| `fd` | Simple, fast and user-friendly alternative to find |
| `fzf` | Command-line fuzzy finder |

### Login and boot

sddm is the login screen and grub the boot menu. intel-ucode updates the Intel CPU's built-in code at boot. linux is the kernel.

| Package | What it is |
| --- | --- |
| `sddm` | QML based X11 and Wayland display manager |
| `grub` | GNU GRand Unified Bootloader (2) |
| `efibootmgr` | Linux user-space application to modify the EFI Boot Manager |
| `intel-ucode` | Microcode update files for Intel CPUs |
| `mkinitcpio` | Modular initramfs image creation utility |
| `linux` | The Linux kernel and modules |
| `linux-firmware` | Firmware files for Linux - Default set |
| `zram-generator` | Systemd unit generator for zram devices |

### Graphics drivers

The Hyprland profile installs drivers for Intel, AMD and NVIDIA (nouveau) so it works on most machines. On an Intel-only laptop, the intel ones are the ones in use.

| Package | What it is |
| --- | --- |
| `intel-media-driver` | Intel Media Driver for VAAPI — Broadwell+ iGPUs |
| `libva-intel-driver` | VA-API implementation for Intel G45 and HD Graphics family |
| `vulkan-intel` | Open-source Vulkan driver for Intel GPUs |
| `vpl-gpu-rt` | Intel VPL runtime implementation for Intel GPUs (Tiger Lake and newer) |
| `vulkan-nouveau` | Open-source Vulkan driver for Nvidia GPUs |
| `vulkan-radeon` | Open-source Vulkan driver for AMD GPUs |
| `xf86-video-amdgpu` | X.org amdgpu video driver |
| `xf86-video-ati` | X.org ati video driver |
| `xf86-video-nouveau` | Open Source 3D acceleration driver for nVidia cards |

### Everything else

Libraries, base system packages and extras. The descriptions come from pacman itself.

| Package | What it is |
| --- | --- |
| `anydesk-bin` **(AUR)** | The Fast Remote Desktop Application |
| `base` | Minimal package set to define a basic Arch Linux installation |
| `brave-bin` **(AUR)** | Web browser that blocks ads and trackers by default (binary release) |
| `cairomm-1.16` | C++ bindings for Cairo |
| `glibmm-2.68` | C++ bindings for GLib |
| `gssdp` | GObject-based API for handling resource discovery and announcement over SSDP |
| `gst-plugins-bad-libs` | Multimedia graph framework - bad |
| `gtk4` | GObject-based multi-platform GUI toolkit |
| `gtkmm-4.0` | C++ bindings for GTK 4 |
| `gupnp` | GObject-based UPNP framework |
| `gupnp-igd` | Library to handle UPnP IGD port mapping |
| `libluv` | Bare libuv bindings for lua |
| `libnice` | Nice |
| `libpipeline` | a C library for manipulating pipelines of subprocesses in a flexible and convenient way |
| `libsigc++-3.0` | Callback Framework for C++ |
| `libutf8proc` | C library for processing UTF-8 encoded Unicode strings |
| `libuv` | Multi-platform support library with a focus on asynchronous I/O |
| `libvpl` | Intel Video Processing Library |
| `libvterm` | Abstract library implementation of a VT220/xterm/ECMA-48 terminal emulator |
| `lua51-lpeg` | Parsing Expression Grammars For Lua for Lua 5.1 |
| `luajit` | Just-in-time compiler and drop-in replacement for Lua 5.1 |
| `msgpack-c` | An efficient object serialization library |
| `pangomm-2.48` | C++ bindings for Pango |
| `smartmontools` | Control and monitor S.M.A.R.T. enabled ATA and SCSI Hard Drives |
| `startup-notification` | Libary to monitor and display application startup |
| `sudo` | Give certain users the ability to run some commands as root |
| `tree-sitter` | Incremental parsing library |
| `tree-sitter-c` | C grammar for tree-sitter |
| `tree-sitter-lua` | Lua grammar for tree-sitter |
| `tree-sitter-markdown` | Markdown grammar for tree-sitter |
| `tree-sitter-query` | TS query grammar for tree-sitter |
| `tree-sitter-vim` | Vimscript grammar for tree-sitter |
| `tree-sitter-vimdoc` | Vim help file grammar for tree-sitter |
| `unibilium` | A terminfo parsing library |
| `xcb-imdkit` | Input method development support for xcb |
| `xdg-utils` | Command line tools that assist applications with a variety of desktop integration tasks |
| `yay` **(AUR)** | Yet another yogurt. Pacman wrapper and AUR helper written in go. |
| `yay-debug` **(AUR)** | Detached debugging symbols for yay |
| `yyjson` | A high performance JSON library written in ANSI C |

> `anydesk-bin` (remote desktop) and `brave-bin` (web browser) are personal extras.
> They aren't needed for this setup. `yay` is the AUR helper used to install them.
