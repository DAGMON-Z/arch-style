# 3. Hyprland

**Hyprland** is a *tiling* window manager. Instead of you dragging windows
around, it places them side by side automatically. It also handles animations,
blur, rounded corners and keybinds.

Config: `~/.config/hypr/hyprland.lua`

## Hyprland now uses Lua

Since version 0.55, Hyprland's config is written in **Lua**, a small
programming language. Older guides online use `hyprland.conf` with lines like
`bind = SUPER, Q, exec, kitty`. In Lua, the same bind looks like this:

```lua
hl.bind("SUPER + Q", hl.dsp.exec_cmd("kitty"))
```

Most settings live inside `hl.config({ ... })` blocks:

```lua
hl.config({
    general = {
        gaps_in  = 4,   -- space between windows
        gaps_out = 10,  -- space between windows and the screen edge
    },
})
```

`--` starts a comment in Lua. The config file is full of comments explaining
each part.

## Sections of the config

| Section | What it does |
| --- | --- |
| MONITORS | Screen resolution and scaling (`auto` works for most laptops) |
| MY PROGRAMS | Which terminal (kitty), file manager (Thunar) and launcher (rofi) the keybinds open |
| AUTOSTART | Programs started at login: Waybar, the wallpaper, clipboard history |
| ENVIRONMENT VARIABLES | Cursor size and theme, and telling Qt apps to use `qt6ct` |
| LOOK AND FEEL | Gaps, the gradient border, rounding, opacity, blur, shadows, animations |
| INPUT | Keyboard layouts (`us,ara`, switched with Alt+Shift) and touchpad |
| KEYBINDINGS | All shortcuts. See the [cheat sheet](../README.md#keybinds-cheat-sheet) |
| WINDOWS AND WORKSPACES | Window rules, and blur behind Waybar |

## What I changed from the default

- **Gaps:** 4 px between windows and 10 px at the edges, to suit a small screen.
- **Border:** a blue → purple → cyan gradient on the focused window.
- **Inactive windows:** 92% opacity, so the focused window stands out.
- **Blur:** 2 passes. More passes look smoother but use more battery.
- **Workspaces:** slide sideways, matching the three-finger swipe.
- **Keybinds:** `SUPER+F` maximizes, and `SUPER+SHIFT+F` makes a window fullscreen.
- **Launcher:** `SUPER+R` opens rofi in Run mode (`local menu = "rofi -show run"`).
  See [chapter 5](05-kitty-rofi-dunst.md).
- **Volume and brightness keys:** run `~/.config/hypr/scripts/osd.sh`, which
  changes the level and shows a popup (see [chapter 5](05-kitty-rofi-dunst.md)).
- **Autostart:** `set-wallpaper --restore` shows the wallpaper (see [chapter 7](07-wallpaper.md)).
- **Safety:** `allow_session_lock_restore` lets you restart the lock screen if
  it crashes (see [chapter 6](06-lockscreen.md)).

## Testing changes safely

Hyprland reloads the config every time you save it. A mistake shows a red error
bar at the top of the screen. To check a file before using it:

```bash
cp ~/.config/hypr/hyprland.lua /tmp/test.lua
nvim /tmp/test.lua                     # make your change
Hyprland --verify-config -c /tmp/test.lua
```

If it says `config ok`, copy it back. You can also reload by hand:

```bash
hyprctl reload
hyprctl configerrors   # empty output means no errors
```

## Running commands from scripts

With the Lua config, `hyprctl dispatch` also takes Lua:

```bash
hyprctl dispatch 'hl.dsp.focus({ workspace = 2 })'
```

The old style, `hyprctl dispatch workspace 2`, gives an error. Waybar 0.16 and
newer detect the Lua style by themselves.
