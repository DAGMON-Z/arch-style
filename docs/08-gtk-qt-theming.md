# 8. GTK and Qt theming

Linux apps are built with different toolkits, and each one is themed
differently. To get every app dark, you theme each toolkit.

| Toolkit | Example apps | Themed with |
| --- | --- | --- |
| GTK 3 | Thunar, Waybar, nwg-look | `~/.config/gtk-3.0/` and the `adw-gtk3-dark` theme |
| GTK 4 | pavucontrol, GNOME apps | `~/.config/gtk-4.0/` |
| Qt 6 | qt6ct, Persepolis | `~/.config/qt6ct/` |
| KDE (Qt) | Dolphin | `~/.config/kdeglobals` and a color scheme |

## GTK

- `settings.ini` picks the theme, icons (Papirus-Dark), cursor and font.
- `gtk.css` overrides the theme's colors with Tokyo Night colors, such as
  `@define-color window_bg_color #1a1b26;`.

## Desktop settings (gsettings)

Some settings are stored in a small settings database, not in files.
`install.sh` sets them, or you can run:

```bash
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
gsettings set org.gnome.desktop.interface cursor-theme capitaine-cursors
```

`color-scheme prefer-dark` tells apps that follow the system preference to use
dark mode.

## Qt

`hyprland.lua` sets `QT_QPA_PLATFORMTHEME=qt6ct`, which tells Qt apps to ask
**qt6ct** how to look. qt6ct uses the Fusion style with the Tokyo Night colors
in `qt6ct/colors/tokyo-night.conf`.

Run `qt6ct` to change these settings with a window. qt6ct rewrites its own
config file when you save, so I didn't add comments to it.

## KDE apps (Dolphin, optional)

This setup now uses Thunar as its file manager. These files only matter if you
install Dolphin or other KDE apps.


KDE apps choose their own colors, so qt6ct alone leaves Dolphin white. Three
files fix that:

- `~/.local/share/color-schemes/TokyoNight.colors`: the color scheme
- `~/.config/kdeglobals`: KDE colors and the Papirus icon theme
- `~/.config/dolphinrc`: the `[UiSettings] ColorScheme=TokyoNight` line picks
  the scheme for Dolphin

Dolphin rewrites `dolphinrc` itself, so it has no comments. If another KDE app
looks light, choose **Tokyo Night** in its color scheme menu.

## Cursor

The cursor is **Capitaine**. It is set in four places, so every kind of app
agrees:

- `hyprland.lua` sets `XCURSOR_THEME`.
- `gsettings` sets `cursor-theme`.
- The GTK `settings.ini` files set it.
- `~/.icons/default/index.theme` covers older apps.

## Browsers

Brave and Chrome have their own theme setting: Settings → Appearance → choose
**GTK** or **Dark**.

Most changes appear after you reopen an app. Log out and back in to be sure.
