# 0. Start here: from a blank laptop to the finished desktop

This page walks you through the whole journey in order. Each part says how to
check that it worked before you move on. The other chapters explain the
details; this one tells you *when* to read them.

**Time needed:** about 1 to 2 hours the first time.
**You need:** a USB stick (2 GB or more), internet, and a computer you're happy
to erase.

> **Warning:** installing Arch erases the disk you choose. Back up anything
> important first.

## Part 1: Make the install USB

1. Download the Arch ISO from <https://archlinux.org/download/>.
2. Write it to the USB stick:
   - On Windows, use [Rufus](https://rufus.ie/) and choose **DD mode** if it asks.
   - On Linux, use `sudo dd if=archlinux.iso of=/dev/sdX bs=4M status=progress`,
     replacing `sdX` with your USB stick. Check it with `lsblk` first, because
     `dd` erases whatever you point it at.
3. Restart the laptop and open the boot menu. The key is often **F11**, **F12**
   or **Esc**. On MSI laptops it's usually **F11**. Choose the USB stick.

**Check:** you see a text screen ending in `root@archiso ~ #`.

## Part 2: Install Arch with archinstall

1. On Wi-Fi, connect first:

   ```bash
   iwctl
   station wlan0 scan
   station wlan0 get-networks
   station wlan0 connect "Your Network Name"
   exit
   ```

   Your device might not be called `wlan0`. Type `device list` inside `iwctl`
   to see its name.
2. Check the connection: `ping -c 3 archlinux.org`.
3. Start the installer: `archinstall`.
4. Go through the menus. The choices that matter for this setup are:

   | Menu | Choose |
   | --- | --- |
   | Bootloader | **GRUB**, and turn on **Install to removable location** |
   | Unified kernel images | **Off** |
   | Profile | **Desktop** → **Hyprland**, seat access **systemd-logind** |
   | Greeter | **sddm** |
   | Audio | **PipeWire** |
   | Network | **NetworkManager** |

   Also set your disk, user name and password, time zone and keyboard layout.
   [Chapter 1](01-install.md) explains every choice.
5. Choose **Install**, wait, then restart and remove the USB stick.

**Check:** a login screen appears. This is SDDM, still with its default look.

## Part 3: First login

1. On the login screen, pick **Hyprland (uwsm-managed)** as the session,
   usually at the bottom left, then log in.
2. The **Hyprland welcome app** may open. It shows which basic parts are
   installed. You can close it for now; the next part installs what it asks for
   ([chapter 2](02-packages.md#hyprland-welcome-app-checklist)).
3. Open a terminal with `SUPER + Q`. SUPER is the Windows key.
4. Connect to Wi-Fi with `nmtui`. Choose **Activate a connection**, pick your
   network and enter the password.
5. Update everything:

   ```bash
   sudo pacman -Syu
   ```

**Check:** `ping -c 3 archlinux.org` works, and the update finished without errors.

> Never force the power off while `pacman` is running. See
> [troubleshooting](11-troubleshooting.md#forced-shutdown-during-pacman) for
> why.

## Part 4: Install Arch Style

### The one command

This downloads the repository and runs the installer with every general step:

```bash
sudo pacman -S --needed git && git clone https://github.com/DAGMON-Z/arch-style.git ~/arch-style && bash ~/arch-style/install.sh --all
```

It's three commands joined with `&&`, which means "only continue if the
previous command worked":

1. `sudo pacman -S --needed git` installs git.
2. `git clone ... ~/arch-style` downloads this repository to `~/arch-style`.
3. `bash ~/arch-style/install.sh --all` runs the installer without questions.

To use your own wallpaper right away, add `--wallpaper` and an image path at
the end:

```bash
... install.sh --all --wallpaper ~/Pictures/my-image.jpg
```

`--all` does **not** install:

- the AUR apps (Brave, AnyDesk), because they're built by the community and you
  should review them, and
- the touchpad fix, because it's only for the MSI Modern 15 F13MG.

Run `bash ~/arch-style/install.sh` without `--all` to choose those.

### Or step by step (recommended for learning)

```bash
sudo pacman -S --needed git
git clone https://github.com/DAGMON-Z/arch-style.git ~/arch-style
cd ~/arch-style
less install.sh                  # read it first. Press q to quit
bash install.sh --dry-run        # shows what it would do, changes nothing
bash install.sh                  # asks before every step
```

These are the steps the installer goes through:

| Step | What it does | Read more |
| --- | --- | --- |
| 1 | Installs the packages in `packages.txt` | [Packages](02-packages.md) |
| 2 | Installs yay and the AUR apps (optional) | [Packages](02-packages.md#aur-packages) |
| 3 | Copies the config files into your home folder, backing up old ones | [Hyprland](03-hyprland.md) and the other chapters |
| 4 | Sets dark mode, icons, cursor and font | [GTK and Qt theming](08-gtk-qt-theming.md) |
| 5 | Turns on services, plus power-saver on battery | [Packages](02-packages.md#services-this-setup-needs), [Power](12-power-management.md) |
| 6 | MSI touchpad fix (only that laptop) | [Troubleshooting](11-troubleshooting.md#touchpad-error--110) |
| 7 | Login screen theme | [Boot and login themes](10-boot-and-login-themes.md) |
| 8 | Boot menu theme (GRUB only) | [Boot and login themes](10-boot-and-login-themes.md) |
| 9 | Wallpaper | [Wallpaper](07-wallpaper.md) |

If a step fails, the installer prints a warning, carries on, and lists the
problems at the end. You can run it again any time. Files that are already
up to date are skipped.

**Check:** the installer ends with `All done.`

## Part 5: Restart and look around

1. Restart: `systemctl reboot`.
2. You should see:
   - the **Tokyo Night boot menu** (GRUB), with a 5-second countdown,
   - the **Tokyo Night login screen**. Pick **Hyprland (uwsm-managed)**.
3. After logging in, check:

   | Try this | You should see |
   | --- | --- |
   | Look at the top | The Waybar pills: workspaces, clock, system info |
   | `SUPER + Q` | A see-through kitty terminal with the system summary |
   | `SUPER + R` | rofi's Run list: type a program name and press Enter |
   | Click the Arch logo on the bar | rofi's app list with icons |
   | Volume or brightness keys | A popup with a progress bar |
   | Power button on the bar → Lock | The lock screen. Unlock with your password |
   | Click the leaf or scale icon on the bar | The power mode changes |
   | `hyprland-welcome` in a terminal | Every item green or blue |

The full list of shortcuts is in the
[keybinds cheat sheet](../README.md#keybinds-cheat-sheet).

## Part 6: Make it yours

1. **Wallpaper:** put an image in `~/Pictures/Wallpapers`, then run:

   ```bash
   set-wallpaper ~/Pictures/Wallpapers/my-image.jpg
   ```

   It sets the desktop, lock screen, login screen and boot menu
   ([chapter 7](07-wallpaper.md)).
2. **Neovim:** run `nvim` once while online, so it downloads its plugins
   ([chapter 9](09-neovim.md)).
3. **Optional extras:**
   - AUR apps: `bash ~/arch-style/install.sh` and answer **y** at step 2.
   - On an MSI Modern 15 F13MG with touchpad trouble: answer **y** at step 6.

## Part 7: Learn how it works

Read the chapters in any order, and change one thing at a time:

- [Hyprland](03-hyprland.md): windows, gaps, animations, keybinds
- [Waybar](04-waybar.md): the bar and its pills
- [kitty, rofi and dunst](05-kitty-rofi-dunst.md): terminal, launcher, notifications
- [Lock screen and idle](06-lockscreen.md)
- [GTK and Qt theming](08-gtk-qt-theming.md)
- [Power management](12-power-management.md)

Before editing a config file, copy it to `<file>.bak`, so you can always go back.

## Part 8: If something goes wrong

- Every file the installer replaced has a `.bak` copy next to it. Copy it back
  to undo.
- [Troubleshooting](11-troubleshooting.md) covers the real problems I hit.
- If the desktop won't start, press `Ctrl + Alt + F3` to get a text login and
  fix things from there.
