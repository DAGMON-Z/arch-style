# 11. Troubleshooting: problems I hit

These are real problems from setting up this laptop, and how they were fixed.

## Forced shutdown during pacman

**What happened:** the laptop was forced off while `pacman` was installing
packages. After restarting, some programs failed in strange ways, and some
config files were empty.

**Why:** pacman writes many files during an install. If the power goes off
halfway, some files are left empty or half-written, while pacman's records say
the package is fine.

**Fix:**

1. If pacman says the database is locked, and **no pacman is running**, remove
   the leftover lock:

   ```bash
   sudo rm /var/lib/pacman/db.lck
   ```

2. Check every installed file against what pacman expects. `-Qkk` compares sizes
   and checksums:

   ```bash
   sudo pacman -Qkk 2>/dev/null | grep -i mismatch
   ```

3. Reinstall the official packages. `--overwrite '*'` lets pacman replace the
   broken files:

   ```bash
   sudo pacman -S --overwrite '*' $(pacman -Qqn)
   ```

   `pacman -Qqn` lists all installed packages from the official repositories.

4. Look for `.pacnew` files. See the next section.

> `--overwrite '*'` is a strong option. It's right for repairing a crashed
> install, but don't use it routinely.

## hyprlock PAM `.pacnew`

**What happened:** after the crash above, `/etc/pam.d/hyprlock` was **empty**.
hyprlock uses that file to check your password, so no password unlocked the
screen.

**Why:** pacman never overwrites a config file you might have edited. When it
reinstalled hyprlock, it saved the correct file as
`/etc/pam.d/hyprlock.pacnew` next to the broken one.

**Fix:** keep the broken file as a backup and move the new one into place:

```bash
sudo cp -a /etc/pam.d/hyprlock /etc/pam.d/hyprlock.bak
sudo mv /etc/pam.d/hyprlock.pacnew /etc/pam.d/hyprlock
```

To find other `.pacnew` files:

```bash
sudo find /etc -name '*.pacnew'
```

## Touchpad error -110

> **Hardware-specific:** this fix is for the **MSI Modern 15 F13MG**. Don't
> install it on other computers.

**What happened:** the touchpad didn't work after some boots. The kernel log
showed:

```text
i2c_designware i2c_designware.0: controller timed out
i2c_hid_acpi i2c-LITE0650:00: can't add hid device: -110
```

`-110` means *timed out*. The touchpad sits on an I2C bus, and that bus's
controller (an **Intel LPSS** device) stopped responding at boot.

**Fix:** restart the controller by unbinding and rebinding its driver:

```bash
sudo sh -c 'echo 0000:00:15.0 > /sys/bus/pci/drivers/intel-lpss/unbind'
sudo sh -c 'echo 0000:00:15.0 > /sys/bus/pci/drivers/intel-lpss/bind'
```

`0000:00:15.0` is the controller's address **on my laptop**. Yours may differ.

To fix it at every boot, `system/` has a script and a service:

- `touchpad-i2c-reset` waits 10 seconds. If the touchpad works by then, it does
  nothing. Otherwise it restarts the controller, up to 3 times.
- `touchpad-i2c-reset.service` runs the script at boot.

Check whether it ran:

```bash
journalctl -b -u touchpad-i2c-reset
```

## Waybar's missing power menu

**What happened:** the power button on Waybar did nothing useful.

**Why:** the first Waybar config was copied from Waybar's example
(`/etc/xdg/waybar/`). That example targets another window manager, Sway, so most
modules didn't apply. Its power menu actions were set up for a different system.

**Fix:** a new `config.jsonc` with Hyprland modules, and `menu-actions` that
match this setup (see [chapter 4](04-waybar.md#the-power-menu)):

```jsonc
"lock": "hyprlock",
"logout": "uwsm stop",
"reboot": "systemctl reboot",
"shutdown": "systemctl poweroff"
```

## powerprofilesctl: No module named 'gi.repository'

**What happened:** after installing `power-profiles-daemon`, the
`powerprofilesctl` command, and a service that used it, failed with:

```text
ModuleNotFoundError: No module named 'gi.repository'
```

**Why:** `powerprofilesctl` is a Python program that needs `python-gobject`.
pacman lists that package as *optional* for power-profiles-daemon, so it isn't
installed automatically. The daemon itself was fine.

**Fix:**

```bash
sudo pacman -S --needed python-gobject
```

The automatic power-saver script now talks to the daemon with `busctl`, so it
doesn't depend on Python at all (see [chapter 12](12-power-management.md)).

> **Lesson:** when a command fails, read the last line of the error first. It
> usually names exactly what's missing.

## General tips

- Read error messages, and search for the exact text.
- `journalctl -b -p err` shows errors from the current boot.
- Before editing a config file, copy it to `<file>.bak`.
- The [Arch Wiki](https://wiki.archlinux.org/) is excellent, and it's written
  for people learning.
