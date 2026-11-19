# 10. Boot menu and login screen themes

Source: `~/.local/share/rice-boot-themes/`

| Path | What it is |
| --- | --- |
| `sddm/tokyo-night/` | The login screen theme (QML) |
| `grub/tokyo-night/` | The boot menu theme |
| `install-sddm-theme.sh` | Installs the login theme (run with `sudo`) |
| `install-grub-theme.sh` | Installs the boot theme (run with `sudo`) |

Both themes come with the sci-fi city wallpaper as their background. Run
`set-wallpaper` with your own image to replace it (see [chapter 7](07-wallpaper.md)).

## Login screen (SDDM)

`Main.qml` describes the screen in **QML**, Qt's language for user interfaces:
clock, password box, session switcher, keyboard layout, and power buttons.

The installer copies the theme to `/usr/share/sddm/themes/tokyo-night` and
creates `/etc/sddm.conf.d/10-tokyo-night.conf`:

```ini
[Theme]
Current=tokyo-night
CursorTheme=capitaine-cursors
```

You can preview a theme in a window without logging out:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/tokyo-night
```

**If the login screen breaks:** press `Ctrl + Alt + F3`, log in, and run:

```bash
sudo rm /etc/sddm.conf.d/10-tokyo-night.conf && sudo systemctl restart sddm
```

## Boot menu (GRUB)

- `theme.txt` describes the layout: the menu box, the highlight color, the
  countdown and the help text.
- `*.pf2` are fonts made from JetBrains Mono with `grub-mkfont`. GRUB can't use
  normal font files.
- `menu_*.png` and `select_*.png` are small pieces that GRUB stretches into
  rounded boxes.

### What the installer does

1. Backs up `/etc/default/grub` and `/boot/grub/grub.cfg`.
2. Copies the theme to `/boot/grub/themes/tokyo-night`.
3. Sets `GRUB_THEME` and `GRUB_GFXMODE` in `/etc/default/grub`.
4. Runs `grub-mkconfig` into a **separate file** and checks it.
5. Replaces your menu only if every check passes.

It never runs `grub-install` and never changes UEFI boot entries, so the
bootloader program itself is untouched.

With Secure Boot on, GRUB can't load extra modules from disk. The theme then
needs its modules built into GRUB (see [chapter 13](13-secure-boot.md#step-4-reinstall-grub-with-its-modules-built-in)).

> It assumes `/boot` is its own partition, as archinstall sets it up. With that
> layout, GRUB writes theme paths without `/boot` at the start.

**Undo:**

```bash
sudo cp /etc/default/grub.bak /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### EFI BootNext entries

`grub-mkconfig` adds menu entries like `EFI BootNext: EFI USB Device`. Choosing
one makes the next boot start from that device. To boot normally, choose
**Arch Linux**.
