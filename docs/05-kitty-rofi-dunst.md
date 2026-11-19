# 5. kitty, rofi and dunst

## kitty (terminal)

Config: `~/.config/kitty/kitty.conf` and `tokyo-night.conf`

- `kitty.conf` holds font, padding, tabs, cursor and transparency. It loads the
  colors with `include tokyo-night.conf`.
- `tokyo-night.conf` holds only colors, so changing the theme means changing one line.
- `background_opacity 0.85` makes the background see-through. Hyprland blurs
  what is behind it.

Reload with `Ctrl + Shift + F5`. An already open window may not pick up a
transparency change, so open a new window to check.

### The "Are you sure you want to close this window?" dialog

When you close a kitty window that's still running something, such as Neovim,
kitty asks first. It only accepts the letters `y` and `n`, so on the Arabic
keyboard layout those keys don't work, because they type Arabic letters. Use
these instead, which work on any layout:

- **Enter:** yes, close it (Enter picks the default answer, which is yes).
- **Esc:** no, keep it open.
- Or click **Yes** or **No** with the mouse.

## rofi (command runner and app launcher)

Config: `~/.config/rofi/config.rasi` and `tokyo-night.rasi`

rofi opens in two ways:

| How | Mode | What you see |
| --- | --- | --- |
| `SUPER + R` | **Run** (`rofi -show run`) | Program names. Type one, such as `firefox` or `pavucontrol`, and press Enter |
| Click the Arch logo on the bar | **Apps** (`rofi -show drun`) | Installed apps with their icons |

`SUPER + R` is set by the `menu` line near the top of `hyprland.lua`:

```lua
local menu = "rofi -show run"
```

Change it to `"rofi -show drun"` if you'd rather have the app list on `SUPER + R`.

- `config.rasi` holds behavior: Papirus icons, fuzzy search (typing `brv` finds
  Brave), and single-click to open.
- `tokyo-night.rasi` holds the look. Rofi themes use a CSS-like language.

`Ctrl + Tab` switches between the **Apps** and **Run** tabs.

## dunst (notifications)

Config: `~/.config/dunst/dunstrc`

- `[urgency_low]`, `[urgency_normal]` and `[urgency_critical]` set colors and how
  long each kind stays. Critical notifications stay until you click them.
- Left-click closes one, middle-click runs its action, right-click closes all.
- The `[osd]` rule styles the volume and brightness popup and keeps it out of
  the notification history.

Apply changes with `dunstctl reload`.

## The volume and brightness popup

Script: `~/.config/hypr/scripts/osd.sh`

Hyprland runs this script when you press a volume, mute or brightness key. It:

1. changes the level with `wpctl` (sound) or `brightnessctl` (screen),
2. reads the new level, and
3. sends a notification with a progress bar to dunst.

Each new popup replaces the last because they share a *stack tag*.

The script talks to dunst directly over D-Bus with `busctl`. The usual tools,
`notify-send` and `dunstify`, need the `libnotify` package, which isn't
installed by default. If you install `libnotify`, either tool works too.
