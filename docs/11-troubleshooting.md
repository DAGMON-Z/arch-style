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

- `touchpad-i2c-reset` checks whether the touchpad started. If it works, the
  script does nothing. If the kernel already reported the `-110` error, it
  restarts the controller right away (up to 3 times). Otherwise it waits up to
  10 seconds for the touchpad first.
- `touchpad-i2c-reset.service` runs the script at boot.
- `sddm.service.d/wait-for-touchpad.conf` makes the login screen start only
  after the fix has finished (see the next section).

Check whether it ran:

```bash
journalctl -b -u touchpad-i2c-reset
```

## The touchpad doesn't work on the login screen

**What happened:** with the touchpad fix above, the touchpad worked in Hyprland
but not on the login screen. It only started working there after a USB mouse
was plugged in and moved.

**Why:** a timing problem. The login screen started about 6 seconds after power
on, but the fix only brought the touchpad back at about 16 seconds. The login
screen started with no pointer at all, and it ignored the touchpad that appeared
later until a mouse moved. Hyprland was fine because you log in later.

**Check the timing** (`-o short-monotonic` shows seconds since power on):

```bash
journalctl -b -o short-monotonic -u touchpad-i2c-reset -u sddm | grep -E 'Started|Finished'
```

The touchpad fix should finish *before* the login screen starts.

**Fix:** two changes, both part of the touchpad fix:

1. A systemd **drop-in** makes the login screen wait for the fix. A drop-in is
   a small file in a `<service>.d/` folder that adds settings to a service
   without editing its original file:

   ```ini
   # /etc/systemd/system/sddm.service.d/wait-for-touchpad.conf
   [Unit]
   After=touchpad-i2c-reset.service
   ```

   `After=` means "start only after that service has finished".

2. The script no longer waits 10 seconds when the kernel has already reported
   the `-110` error, so the login screen appears after about 9 seconds instead
   of 16.

Also, the login screen runs on **Xorg**, not Hyprland, and Xorg leaves **tap to
click** off by default. `/etc/X11/xorg.conf.d/30-touchpad.conf` (installed with
the login screen theme) turns it on.

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

## The SUPER (Windows) key does nothing

**What happened:** on a desktop PC with a gaming keyboard, no `SUPER` shortcut
worked. Hyprland was fine: `hyprctl binds` listed all the `SUPER` shortcuts,
and there were no config errors.

**Why:** many gaming keyboards have a **Windows key lock**, a "game mode" that
switches the Windows key off so you don't leave a game by accident. While it's
on, the key never reaches Linux.

**Fix:** turn the lock off on the keyboard itself. Common ways:

- `Fn` + the Windows key (the most common)
- a key with a lock or joystick icon, often near `Fn` or at the top right
- `Fn` + `F12`, or a key labeled "Game" or "Win Lock"

A small light on the keyboard sometimes shows when the lock is on. Then test
with `SUPER + Q`, which should open a terminal.

To check whether Hyprland loaded the shortcuts at all:

```bash
hyprctl binds | grep -c 'modmask: 64'
```

`modmask: 64` means "uses SUPER". A number above 0 means the shortcuts are
loaded, so the problem is the keyboard.

## Colors look different on another screen

**What happened:** the same setup looked different on a desktop PC with a
Samsung monitor than on the laptop.

**Why:** the computer sent exactly the same colors. The config files were
identical, and both used Hyprland's standard color mode. Screens simply show
colors differently, and monitors have their own picture settings on top.

**Check what Hyprland sends:**

```bash
hyprctl monitors | grep -E 'Monitor|colorManagementPreset|sdrBrightness|sdrSaturation'
```

`colorManagementPreset: srgb`, `sdrBrightness: 1` and `sdrSaturation: 1` mean
standard, unchanged colors.

**Fix:** use the monitor's own menu (the buttons on the monitor):

- Turn off **Eye Saver**, blue-light or reading modes. They make everything yellowish.
- Use the **Standard** or **Custom** picture mode, not Dynamic or Cinema.
- Over HDMI, if dark colors look grey and washed out, or too dark with detail
  lost, switch **HDMI Black Level** (sometimes called RGB range) between its
  two settings and keep the one that looks better.

## No performance mode on a desktop PC

**What happened:** on a desktop with an AMD Ryzen 5 3400G, the power pill only
had power-saver and balanced, and at boot it was always set to power-saver.

**Why:** two separate reasons.

1. That CPU uses the older `acpi-cpufreq` driver, so power-profiles-daemon only
   offers two "placeholder" modes, which don't change anything (see
   [chapter 12](12-power-management.md#only-two-modes-and-no-performance)).
2. The automatic power-saver script treated "no charger found" as "on battery".
   A desktop has no charger, so it picked power-saver at every boot.

**Fix:** the script now sets balanced on computers without a battery. That also
resets desktops that power-profiles-daemon remembered as power-saver. Get it
with the [update command](00-start-here.md#part-8-getting-updates), then restart. The missing
performance mode is a limit of the CPU, and the CPU still runs at full speed
when needed.

## The Print key does nothing

**What happened:** pressing `Print` seemed to do nothing.

**Why:** the first version saved the screenshot silently, so there was no sign
it worked. It also failed silently if `~/Pictures/Screenshots` didn't exist.

**Fix:** the `Print` keys now run `screenshot.sh`, which creates the folder and
shows a notification with a preview. If you still see no notification:

- Check the key works at all. On some keyboards, especially gaming and laptop
  keyboards, `Print` (or `PrtSc`) only works together with `Fn`.
- Run the script by hand to see any error:

  ```bash
  ~/.config/hypr/scripts/screenshot.sh full-copy
  ```

## Blurry or pixelated apps (Spotify, Discord)

**What happened:** with the screen at 150%, Spotify looked pixelated, while
other apps were sharp.

**Why:** Spotify was running through **XWayland**, the compatibility layer for
apps that don't speak Wayland yet. XWayland apps are drawn at 100% and then
stretched to 150%, which makes them blurry. Native Wayland apps are drawn at
the real size, so they're sharp.

**Check which apps use XWayland:**

```bash
hyprctl clients | grep -E 'class:|xwayland:'
```

`xwayland: 1` means that app uses XWayland, and `xwayland: 0` means it's native.

**Fix:** tell the app to run natively on Wayland.

- **Spotify:** `~/.config/spotify-launcher.conf` (included in this setup):

  ```ini
  [spotify]
  extra_arguments = ["--enable-features=UseOzonePlatform", "--ozone-platform=wayland"]
  ```

- **Electron apps** (Discord, VS Code, Teams for Linux, Obsidian and many more):
  `hyprland.lua` sets `ELECTRON_OZONE_PLATFORM_HINT=auto`, which tells them to
  use Wayland when they can.

Close the app completely and open it again to apply. Spotify may keep running
in the background after you close its window, so run `pkill spotify` first.

### Java apps (PC2) can't run on Wayland

Java's window toolkit only speaks X11, so Java apps such as PC2 always use
XWayland. Hyprland is set to **not stretch** XWayland apps:

```lua
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})
```

Now they're drawn sharp at 100%. The trade-off: on a 125% or 133% screen they
look a bit smaller than other apps. Java can only scale by whole numbers (1×,
2×), so it can't match 133% exactly: `-Dsun.java2d.uiScale=1.33` is rounded
down to 1. The `pc2` command passes the screen's scale rounded down (1 at 133%,
2 at 200%), and turns on smooth text (`-Dawt.useSystemAAFontSettings=on`).

To check which scale Java really uses, look at the window size, or ask Java:
`GraphicsEnvironment...getDefaultTransform().getScaleX()` in a small test
program prints it.

If you'd rather have XWayland apps at the normal size but blurry, set
`force_zero_scaling = false` and run `hyprctl reload`.

## Arabic letters don't join (Discord)

**What happened:** in Discord, Arabic text showed every letter separately,
spaced out like a typewriter, instead of joined words.

**Why:** Discord asks for fonts such as "Helvetica Neue". There's no such font,
so for Arabic letters the system picked **FreeMono**, an old monospace font that
has Arabic letters but can't join them properly.

**Check which font an app gets for Arabic:**

```bash
fc-match "Helvetica Neue:charset=0627" family
```

- `fc-match` asks fontconfig (the system that picks fonts) which font it would use.
- `charset=0627` means "a font that has the Arabic letter alef".

It should print `Noto Sans Arabic UI`, not `FreeMono`.

**Fix:** `~/.config/fontconfig/fonts.conf` (included in this setup) prefers the
Noto Arabic fonts and never uses FreeMono or FreeSerif:

- normal text, Helvetica and Arial use **Noto Sans Arabic UI** for Arabic. It's
  the compact interface version of Noto Sans Arabic, so Arabic lines up evenly
  with English text, close to how Windows shows it with Segoe UI (which is a
  Microsoft font and can't be installed here),
- serif text uses **Noto Naskh Arabic**.

Restart the app afterwards. Discord keeps running in the background after you
close its window, so stop it completely first with `pkill -i discord`.

## Alt + Shift switches to Arabic but not back

**What happened:** `Alt + Shift` switched from English to Arabic, but not back
to English.

**Why:** the Arabic keyboard layout turns the **Right Alt** key into an extra
key for typing more Arabic characters (called `ISO_Level3_Shift`). Then it isn't
an Alt key anymore, so `Right Alt + Shift` can't switch back. The left Alt key
always worked.

**Fix:** `hyprland.lua` adds the keyboard option `lv3:ralt_alt`, which keeps
Right Alt a normal Alt key in every layout:

```lua
kb_options = "grp:alt_shift_toggle,lv3:ralt_alt",
```

Now `Alt + Shift` switches both ways with either Alt key. The only exception is
pressing Right Shift *first* and then Right Alt, so press Alt first. The left
Alt key works in any order.

## VS Code: "An OS keyring couldn't be identified"

**What happened:** signing in to GitHub in VS Code showed "An OS keyring
couldn't be identified for storing the encryption related data in your current
desktop environment", with a button to use weaker encryption.

**Why:** VS Code chooses a keyring (password store) from the desktop's name.
It recognises GNOME and KDE, but not Hyprland, so it finds none.

**Fix:** don't pick weaker encryption. Tell VS Code to use KWallet by adding
this to `~/.vscode/argv.json`, then close VS Code completely and reopen it:

```jsonc
"password-store": "kwallet6"
```

`apps.sh` installs `kwallet` and adds this line for you. See
[chapter 16](16-personal-apps.md#vs-code-sign-in-kwallet).

### Then: "the OS keyring is not available for encryption"

**What happened:** after the fix, VS Code said "You're running in a KDE
environment but the OS keyring is not available for encryption. Ensure you
have kwallet running."

**Why:** KWallet was running but had **no wallet yet**. It had opened a
"KDE Wallet Service" window to create one, but Hyprland tiled it like a normal
app, so it was easy to miss behind other windows.

**Check whether a wallet exists:**

```bash
ls ~/.local/share/kwalletd/
```

An empty folder means no wallet yet.

**Fix:** find the **KDE Wallet Service** window, choose **Blowfish** (not GPG)
and set a password, then restart VS Code. `hyprland.lua` now has a
`float-kde-wallet` rule, so the window floats in the middle of the screen.

## Apps say "No system keyring is available"

**What happened:** Claude Desktop showed "No system keyring is available. Your
sign-in ... can't be saved on this computer ... Install and unlock GNOME
Keyring". Other apps (Discord, Element, Chrome-based apps) can have the same
problem, sometimes silently.

**Why:** apps keep sign-ins in the system **keyring**, which they find on D-Bus
under the standard name `org.freedesktop.secrets` (the "Secret Service").
KWallet provides it with its `ksecretd` program, but only KDE's own desktop
starts that at login. On Hyprland nothing did, so apps found no keyring. (The
VS Code fix above only helped VS Code, because it names KWallet directly.)

**Check:**

```bash
busctl --user list | grep org.freedesktop.secrets
```

A line with `ksecretd` means the keyring is there.

**Fix** (included in this setup):

1. `~/.local/share/dbus-1/services/org.freedesktop.secrets.service` tells
   D-Bus to start `/usr/bin/ksecretd` the first time any app asks for the
   keyring. No autostart entry needed.
2. `kwallet-pam` unlocks the wallet when you log in, if the wallet's password
   is your login password. The login screen's PAM file (`/etc/pam.d/sddm`)
   already has the `pam_kwallet5.so` lines; they only need this package.
3. The first time an app saves a secret, a **KDE Wallet Service** window
   creates the wallet: choose **Blowfish** and **your login password**, so it
   unlocks by itself from then on.

Restart the app afterwards.

## The keyring asks for its password after every restart

**What happened:** after a restart, a window said *"KDE has requested to open
the wallet 'Default Keyring'. Please enter the password"*, even though the
wallet's password is the login password.

**Why:** three things:

1. `kwallet-pam`, which unlocks the wallet when you log in, wasn't installed
   yet (it was added to `packages.txt` later).
2. The wallet was named **"Default Keyring"**. `kwallet-pam` only unlocks the
   wallet named **"kdewallet"**, KWallet's standard name.
3. At login, `kwallet-pam` starts an unlocked keyring (`ksecretd --pam-login`)
   that waits for a helper, `pam_kwallet_init`, to connect it to the desktop.
   KDE Plasma runs that helper by itself, but its autostart entry says
   `X-systemd-skip=true`, so on Hyprland it never ran. The first app that
   asked for the keyring then started a **second, locked** keyring, and that
   one asked for the password.

**Check:**

```bash
pacman -Q kwallet-pam
ls ~/.local/share/kwalletd/
```

- `pacman -Q` prints the version if the package is installed.
- The folder should hold `kdewallet.kwl`, not `Default Keyring.kwl`.

**Fix:** run the [update](../README.md#getting-updates). It installs
`kwallet-pam`, renames the wallet to `kdewallet` (keeping a backup in
`~/.local/share/kwalletd.bak.<date>`), and sets `Default Wallet=kdewallet` in
`~/.config/kwalletrc`. It also adds `~/.local/bin/keyring-start`, which runs
`pam_kwallet_init` when Hyprland starts (`hyprland.lua`), and also when an app
asks for the keyring first (the D-Bus file
`~/.local/share/dbus-1/services/org.freedesktop.secrets.service`). Then
restart. If it still asks, the wallet's password
isn't your login password: the login can only unlock a wallet with the same
password.

## Bluetooth headphones sound bad

**What happened:** with Bluetooth headphones (an oraimo BoomPop Pro), music
and videos sounded muffled and tinny, like a phone call.

**Why:** Bluetooth headphones have two modes:

- **A2DP** ("High Fidelity Playback"): good stereo sound, no microphone.
- **HSP/HFP** ("Headset Head Unit"): phone-call quality, with the microphone.

The headphones were in headset mode, and the good mode wasn't offered at all.
The Bluetooth log showed why:

```text
a2dp-sink profile connect failed for AA:BB:CC:DD:EE:FF: Input/output error
```

The headphones weren't **trusted**. They start the A2DP connection
themselves, and for an untrusted device that connection can be refused, so
only the phone-call part connected.

**Check the mode:**

```bash
pactl list cards | grep -E 'device.description|Active Profile'
```

`Active Profile: a2dp-sink...` is good. `headset-head-unit...` is phone-call
quality.

**Fix:** trust the headphones, then reconnect them:

```bash
bluetoothctl trust AA:BB:CC:DD:EE:FF
bluetoothctl disconnect AA:BB:CC:DD:EE:FF
bluetoothctl connect AA:BB:CC:DD:EE:FF
```

Use your own headphones' address: `bluetoothctl devices` lists it. In Blueman,
right-click the device and choose **Trust**, then disconnect and connect again.

> Apps that use the microphone (Discord calls, for example) switch the
> headphones to headset mode on purpose, because only that mode has a
> microphone. They switch back when the call ends.

## The minimize button does nothing

**What happened:** clicking an app's minimize button (the `–` at the top right)
did nothing.

**Why:** Hyprland has no "minimized" windows: a window is either on a
workspace or on a hidden special workspace. Hyprland receives the app's request
but ignores it, and doesn't report it anywhere, so it can't be redirected with
the config either (checked in Hyprland 0.57's source).

**Instead:** use the scratchpad, a hidden workspace:

- `SUPER + SHIFT + S` hides the window (moves it to the scratchpad).
- `SUPER + S` shows or hides the scratchpad, to get it back.

## General tips

- Read error messages, and search for the exact text.
- `journalctl -b -p err` shows errors from the current boot.
- Before editing a config file, copy it to `<file>.bak`.
- The [Arch Wiki](https://wiki.archlinux.org/) is excellent, and it's written
  for people learning.
