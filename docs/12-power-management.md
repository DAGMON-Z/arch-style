# 12. Power management

Three pieces keep the laptop cool and the battery lasting:

| Piece | What it does |
| --- | --- |
| `power-profiles-daemon` | Switches between **power-saver**, **balanced** and **performance** |
| `thermald` | Intel's thermal daemon. Cools the CPU gently before it overheats |
| `power-profile-auto` | My script: power-saver on battery, balanced on the charger |

> **Don't install TLP alongside power-profiles-daemon.** Both try to control the
> same settings, so they fight each other. Pick one. This setup uses
> power-profiles-daemon because it's simple and works with the Waybar button.

## Installing

`install.sh` does this in its services step. By hand:

```bash
sudo pacman -S --needed power-profiles-daemon thermald python-gobject
sudo systemctl enable --now power-profiles-daemon.service thermald.service
```

`python-gobject` is needed by the `powerprofilesctl` command. pacman lists it as
optional, so it isn't installed automatically (see
[troubleshooting](11-troubleshooting.md#powerprofilesctl-no-module-named-girepository)).

`thermald` is made for Intel CPUs. On AMD, skip it.

## Checking and changing the mode

```bash
powerprofilesctl get                # the current mode, e.g. power-saver
powerprofilesctl list               # all modes, with * next to the active one
powerprofilesctl set performance    # switch by hand
```

## The Waybar button

The pill next to the battery shows the current mode:

| Icon color | Mode |
| --- | --- |
| Green leaf | power-saver |
| Blue scale | balanced |
| Orange rocket | performance |

Click it to cycle through the modes. Hover over it to see the mode name. It's
Waybar's built-in `power-profiles-daemon` module, set up in `config.jsonc`, and
the colors are in `style.css`.

## Automatic power-saver on battery

power-profiles-daemon doesn't change modes by itself when you unplug, so this
setup adds three small files:

| File | What it does |
| --- | --- |
| `/usr/local/bin/power-profile-auto` | Checks whether a charger is connected and sets the mode |
| `/etc/udev/rules.d/99-power-profile-auto.rules` | Runs the script when the charger is plugged in or removed |
| `/etc/systemd/system/power-profile-auto.service` | Runs the script once at boot |

**udev** is the part of Linux that reacts to hardware events, such as plugging
something in. The rule says: when a power supply of type "Mains" (a charger)
changes, run the script.

The script looks through `/sys/class/power_supply/` for a charger. If one is
connected, it picks `balanced`; otherwise `power-saver`. It then tells
power-profiles-daemon over D-Bus with `busctl`, which does the same as
`powerprofilesctl set` without needing Python.

The mode changes only when you plug in or unplug. If you pick a mode by hand, it
stays until the next plug event.

This works on most laptops, because it looks for any charger instead of one
specific model. Unlike the touchpad fix, it isn't hardware-specific.

### Installing it by hand

```bash
cd ~/arch-style/system
sudo install -m 755 usr/local/bin/power-profile-auto /usr/local/bin/power-profile-auto
sudo install -m 644 etc/udev/rules.d/99-power-profile-auto.rules /etc/udev/rules.d/99-power-profile-auto.rules
sudo install -m 644 etc/systemd/system/power-profile-auto.service /etc/systemd/system/power-profile-auto.service
sudo udevadm control --reload
sudo systemctl daemon-reload
sudo systemctl enable --now power-profile-auto.service
```

### Testing it

Unplug the charger and run `powerprofilesctl get`. It should say
`power-saver`. Plug it back in, and it should say `balanced`.

To see what the boot step did:

```bash
journalctl -b -u power-profile-auto.service
```

### Removing it

```bash
sudo systemctl disable power-profile-auto.service
sudo rm /usr/local/bin/power-profile-auto /etc/udev/rules.d/99-power-profile-auto.rules /etc/systemd/system/power-profile-auto.service
sudo udevadm control --reload
sudo systemctl daemon-reload
```
