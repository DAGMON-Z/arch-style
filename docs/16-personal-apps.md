# 16. My personal apps

These are the apps I use every day. They aren't part of the desktop setup, so
they have their own installer, `apps.sh`. One command installs all of them:

```bash
bash ~/arch-style/apps.sh
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
| VirtualBox | `virtualbox`, `virtualbox-host-dkms`, `virtualbox-guest-iso` | Official repositories |
| VS Code | `visual-studio-code-bin` | AUR (Microsoft's own build, with the extension marketplace) |
| Brave | `brave-bin` | AUR |
| Google Chrome | `google-chrome` | AUR |
| AnyDesk | `anydesk-bin` | AUR |
| Zoom | `zoom` | AUR |
| VirtualBox Extension Pack | `virtualbox-ext-oracle` | AUR (free for personal use) |
| Microsoft Teams | `teams-for-linux` | AUR, unofficial app |
| Notion | `notion-app-electron` | AUR, unofficial app |
| WhatsApp | `zapzap` | AUR, unofficial app |
| Claude Desktop | `claude-desktop` | AUR, community package of Anthropic's Linux app |
| Claude Code | Anthropic's installer | `curl -fsSL https://claude.ai/install.sh \| bash` |
| Outlook | an "Outlook" app entry | Outlook on the web, opened by Brave in its own window |

The lists are in `apps/official.txt` and `apps/aur.txt`. Add or remove a line
to change what gets installed.

### Apps without an official Linux version

- **Teams, Notion and WhatsApp:** Microsoft, Notion and Meta don't make Linux
  apps. The AUR packages are unofficial apps that wrap the web versions, so
  they work like the website in its own window.
- **Outlook classic** only exists for Windows. `apps.sh` adds an **Outlook**
  entry to your app list (`~/.local/share/applications/outlook-web.desktop`)
  that opens [Outlook on the web](https://outlook.office.com) in its own Brave
  window, without tabs or an address bar.

### AUR packages are installed without review

To make it one command, `apps.sh` tells `yay` not to show each build file
(`--answerdiff None`). These are popular, well-known packages, but AUR packages
are made by the community, so check them once with `yay -Si <package>` if you're
unsure. See [chapter 2](02-packages.md#aur-packages).

## VirtualBox

VirtualBox needs a part that runs inside the Linux kernel. `apps.sh` installs:

- **`virtualbox-host-dkms`**, which builds that part for your kernel, and
- the matching **kernel headers** (`linux-headers` for the normal kernel), which
  the build needs. The script detects which kernels you have.

It also adds you to the **`vboxusers`** group, which lets virtual machines use
USB devices through the **Extension Pack**.

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
