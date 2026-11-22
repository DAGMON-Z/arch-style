# 16. My personal apps

These are the apps I use every day. They aren't part of the desktop setup, so
they have their own installer, `apps.sh`. One command installs all of them:

```bash
bash ~/neon-arch/apps.sh
```

It shows the list, asks once, then installs everything without more questions.

- `bash apps.sh --dry-run` shows what it would do and changes nothing.
- `bash apps.sh --yes` doesn't ask at all.

Running it again is safe: anything already installed is skipped.

## The apps

| App | Package | Comes from |
| --- | --- | --- |
| Git | `git` | Official repositories |
| Telegram | `telegram-desktop` | Official repositories |
| Discord | `discord` | Official repositories |
| VLC | `vlc`, `vlc-plugins-all` | Official repositories |
| LibreOffice | `libreoffice-fresh` | Official repositories |
| Spotify | `spotify-launcher` | Official repositories |
| Tor Browser | `torbrowser-launcher` | Official repositories |
| Proton VPN | `proton-vpn-gtk-app` | Official repositories |
| VirtualBox | `virtualbox`, `virtualbox-host-dkms`, `virtualbox-guest-iso` | Official repositories |
| VirtualBox Extension Pack | `virtualbox-ext-oracle` | AUR (free for personal use), installed right after VirtualBox |
| VS Code | `visual-studio-code-bin` | AUR (Microsoft's own build, with the extension marketplace) |
| KWallet | `kwallet` | Official repositories, keeps VS Code's sign-ins ([see below](#vs-code-sign-in-kwallet)) |
| Brave | `brave-bin` | AUR |
| Google Chrome | `google-chrome` | AUR |
| AnyDesk | `anydesk-bin` | AUR |
| Zoom | `zoom` | AUR |
| Microsoft Teams | `teams-for-linux` | AUR, unofficial app |
| Notion | `notion-app-electron` | AUR, unofficial app |
| WhatsApp | `zapzap` | AUR, unofficial app |
| Claude Desktop | `claude-desktop` | AUR, community package of Anthropic's Linux app |
| Claude Code | Anthropic's installer | `curl -fsSL https://claude.ai/install.sh \| bash` |
| Outlook | an "Outlook" app entry | Outlook on the web, opened by Brave in its own window |

The lists are in `apps/official.txt` and `apps/aur.txt`. Add or remove a line
to change what gets installed. The VirtualBox Extension Pack isn't in those
lists: `apps.sh` installs it in its VirtualBox step, after VirtualBox is set up.

### Apps without an official Linux version

- **Teams, Notion and WhatsApp:** Microsoft, Notion and Meta don't make Linux
  apps. The AUR packages are unofficial apps that wrap the web versions, so
  they work like the website in its own window.
- **Outlook classic** only exists for Windows. `apps.sh` adds an **Outlook**
  entry to your app list (`~/.local/share/applications/outlook-web.desktop`)
  that opens [Outlook on the web](https://outlook.office.com) in its own Brave
  window, without tabs or an address bar.

### VS Code replaces "code"

The list has **Microsoft's VS Code** (`visual-studio-code-bin`), which has the
full extension marketplace. It can't be installed next to `code`, the
open-source build from the official repositories. If you have `code`,
`apps.sh` removes it first and copies your settings and keyboard shortcuts to
where Microsoft's build looks for them (`~/.config/Code/User`).

AUR apps are installed **one at a time**, so if one fails, the others still
get installed. The summary at the end lists any that failed.

### AUR packages are installed without review

To make it one command, `apps.sh` tells `yay` not to show each build file
(`--answerdiff None`). These are popular, well-known packages, but AUR packages
are made by the community, so check them once with `yay -Si <package>` if you're
unsure. See [chapter 2](02-packages.md#aur-packages).

## VS Code sign-in (KWallet)

VS Code keeps sign-ins (GitHub, Copilot, Settings Sync) encrypted in a
**keyring**, the system's password store. It picks the keyring by the name of
your desktop. It knows GNOME and KDE but not Hyprland, so without help it shows:

> An OS keyring couldn't be identified for storing the encryption related data
> in your current desktop environment.

Don't choose **Use weaker encryption**: that stores secrets with a key that is
easy to find. Instead, `apps.sh` installs **KWallet** (KDE's keyring) and adds
this line to `~/.vscode/argv.json`, the file for VS Code's startup options:

```jsonc
"password-store": "kwallet6"
```

Close VS Code completely and open it again to apply.

### Creating the wallet (first time only)

The first time you sign in, a **KDE Wallet Service** window opens to create a
wallet: the encrypted safe your secrets go in. `hyprland.lua` floats it in the
middle of the screen (the `float-kde-wallet` rule).

1. When it asks for the encryption type, choose **Blowfish** (classic), not
   **GPG**. GPG needs a GPG key, which a new system doesn't have.
2. Choose a wallet password. Using your login password is easiest to
   remember.

The wallet is saved in `~/.local/share/kwalletd/`. After each login, the
first app that needs a secret asks for this password once, and the wallet
stays unlocked until you log out.

To set it by hand, open the Command Palette (`Ctrl + Shift + P`), run
**Preferences: Configure Runtime Arguments**, add the line above and restart.

## Tor Browser and Proton VPN

- **Tor Browser:** `torbrowser-launcher` downloads the official Tor Browser
  from the Tor Project and checks its signature, so you know it's genuine.
  Open **Tor Browser** from the app list. The first time, it downloads the
  browser (about 100 MB), then it starts. It updates itself.
- **Proton VPN:** open **Proton VPN** from the app list and log in with a
  Proton account. The free plan has no ads and no data limit. Your login is
  kept in KDE Wallet (`kwallet`, also in this list), so you don't have to log
  in every time.

## VirtualBox

VirtualBox needs a part that runs inside the Linux kernel. `apps.sh` installs:

- **`virtualbox-host-dkms`**, which builds that part for your kernel, and
- the matching **kernel headers** (`linux-headers` for the normal kernel), which
  the build needs. The script detects which kernels you have.

It also adds you to the **`vboxusers`** group, which lets virtual machines use
USB devices. Then, as the last VirtualBox step, it installs the **Extension
Pack** (`virtualbox-ext-oracle`), which adds USB 2 and 3, webcam and disk
encryption support.

**Restart after installing.** The kernel part loads at boot, and group
changes apply after you log in again.

Check that it works:

```bash
lsmod | grep vboxdrv
groups | grep vboxusers
```

- `lsmod` lists the kernel parts that are loaded. You should see `vboxdrv`.
- `groups` lists the groups you're in. You should see `vboxusers`.

The Extension Pack must have the same version as VirtualBox. Both update
together with `sudo pacman -Syu` and `yay`. If VirtualBox complains about the
Extension Pack after an update, run `yay -Syu` to update it too.
