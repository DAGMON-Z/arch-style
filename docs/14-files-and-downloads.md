# 14. Files and downloads: Thunar and Persepolis

## Thunar (file manager)

Open it with `SUPER + E`. Folders opened from other apps also open in Thunar.

**Why Thunar:** it's a GTK app, so it automatically uses this setup's dark
theme, Tokyo Night colors and Papirus icons
([chapter 8](08-gtk-qt-theming.md)), with no extra theming files. It's also
light and simple to use.

### The packages

| Package | What it does |
| --- | --- |
| `thunar` | The file manager |
| `thunar-archive-plugin` + `xarchiver` | "Extract here" and "Create archive" in the right-click menu |
| `thunar-volman` | Opens USB sticks and drives when you plug them in |
| `gvfs` | Trash, mounting drives from the sidebar, network locations |
| `gvfs-mtp` | Browse Android phones over USB |
| `tumbler` + `ffmpegthumbnailer` | Picture and video thumbnails |

### Making it the default for folders

`install.sh` runs this:

```bash
xdg-mime default thunar.desktop inode/directory
```

- `xdg-mime` sets which app opens which type of file.
- `default thunar.desktop` picks Thunar. `.desktop` files describe installed apps.
- `inode/directory` is the type name for folders.

Check it with `xdg-mime query default inode/directory`.

### "Open Terminal Here"

Right-click inside a folder and choose **Open Terminal Here** to open kitty in
that folder. It's a *custom action* saved in `~/.config/Thunar/uca.xml`:

```xml
<command>kitty --directory %f</command>
```

`%f` is replaced by the folder you clicked. You can add your own actions in
Thunar under **Edit → Configure custom actions**.

### Useful keys

| Keys | Action |
| --- | --- |
| `Ctrl + H` | Show or hide hidden files, such as `.config` |
| `Ctrl + T` | New tab |
| `Ctrl + L` | Type a path |
| `F2` | Rename |
| `Ctrl + Shift + N` | New folder |

> **Dolphin** (KDE's file manager) was used before Thunar. Its theming files are
> still in the repository, in case you prefer it. Install it with
> `sudo pacman -S dolphin` and change `local fileManager = "thunar"` in
> `hyprland.lua` to `"dolphin"`.

## Persepolis (download manager)

**Persepolis** downloads files faster by using several connections at once. It
can pause and resume, keep a queue, and schedule downloads for later. Start it
from rofi (click the Arch logo on the bar), or type `persepolis`.

Downloads are saved to `~/Downloads/Persepolis` by default.

### Matching the theme

Persepolis has its own color schemes. This setup sets it to **System**, so it
uses the Tokyo Night colors from qt6ct ([chapter 8](08-gtk-qt-theming.md)).
The setting is in `~/.config/persepolis_download_manager/persepolis.conf`:

```ini
color-scheme=System
```

You can also change it in Persepolis under **Preferences → Style → Color
scheme**.

### Downloading from the browser

Persepolis can take over downloads from your browser with an extension. See
<https://persepolisdm.github.io> for the browser integration and instructions.

Without the extension, copy a download link, then click **+** in Persepolis.
It fills in the link from the clipboard.
