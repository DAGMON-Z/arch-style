# 1. Installing Arch with archinstall

`archinstall` is a guided installer that comes with the Arch Linux USB. You
answer questions in a menu, and it installs Arch for you. This page explains the
choices I made. You can make different choices, but these are the ones this
setup was built and tested on.

Official guide: <https://wiki.archlinux.org/title/Archinstall>

## Before you start

1. Download the Arch ISO from <https://archlinux.org/download/> and write it to
   a USB stick.
2. Boot from the USB. You get a text prompt.
3. Connect to the internet. On Wi-Fi, type `iwctl` and follow the
   [iwctl guide](https://wiki.archlinux.org/title/Iwd#iwctl).
4. Type `archinstall` and press Enter.

## My menu choices

### Bootloader: GRUB, installed to the removable location

The **bootloader** is the first program that runs when you turn the computer on.
It shows a menu and starts Linux. I chose **GRUB** because it is common, well
documented, and can be themed (see [chapter 10](10-boot-and-login-themes.md)).
GRUB can also work with Secure Boot (see [chapter 13](13-secure-boot.md)).

**Install to removable location** puts a copy of GRUB at the fallback path
`EFI/BOOT/BOOTX64.EFI`. Every UEFI computer checks that path, even if it forgets
its list of boot entries. Some laptops do forget it, so this makes booting more
reliable.

### Unified kernel image (UKI): off

A **UKI** bundles the Linux kernel, its startup files and its settings into one
file. It is useful for some advanced setups, such as Secure Boot. I left it
**off**. GRUB then loads the kernel (`vmlinuz-linux`) and its startup image
(`initramfs-linux.img`) as normal separate files, which is simpler to follow.

### Network: NetworkManager

**NetworkManager** handles Wi-Fi and wired connections. After installing, type
`nmtui` for a simple menu to join a Wi-Fi network. Clicking the network icon on
the bar also opens `nmtui`.

### Audio: PipeWire

**PipeWire** is the modern Linux sound system. It also handles screen sharing.
Apps that expect the older PulseAudio still work, through `pipewire-pulse`.

### Profile: Desktop, then Hyprland

The **profile** decides which desktop gets installed. I chose **Desktop**, then
**Hyprland**. That installs Hyprland and a few basic programs such as kitty.

### Greeter: sddm

The **greeter** is the login screen you see after booting. I chose **sddm**.
It can be themed with QML (see [chapter 10](10-boot-and-login-themes.md)).

### Seat access: systemd-logind

Hyprland needs permission to use your screen, keyboard and mouse. A **seat
manager** gives that permission to the logged-in user. **systemd-logind** is
already part of Arch, so nothing extra is needed. The other choice, `polkit`
with `seatd`, is mostly for systems without systemd.

## What I ended up with

These came from archinstall's defaults or my other answers, so check your own
menus:

- `/boot`: a 1 GB FAT32 partition. UEFI computers boot from this type of partition.
- `/`: the rest of the disk, formatted as ext4.
- Swap in compressed memory through `zram-generator`, not a swap partition.

## First steps after installing

```bash
nmtui                 # connect to Wi-Fi
sudo pacman -Syu      # update everything
```

Then continue with [Part 3 of the step-by-step guide](00-start-here.md#part-3-first-login).

> **Tip:** never force the power off while `pacman` is installing or updating.
> I did, and it caused the problems described in
> [troubleshooting](11-troubleshooting.md#forced-shutdown-during-pacman).
