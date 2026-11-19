# 4. Waybar (the top bar)

**Waybar** draws the bar at the top of the screen.

Config: `~/.config/waybar/`

| File | What it does |
| --- | --- |
| `config.jsonc` | Which modules appear, and what clicking them does |
| `style.css` | Colors, fonts and the rounded "pill" shapes |
| `power_menu.xml` | The menu that opens from the power button |

## Layout

- **Left:** Arch logo (opens rofi), workspaces 1 to 5
- **Center:** clock and date (hover for a calendar)
- **Right:** CPU, memory, temperature, keyboard layout, volume, brightness,
  network, Bluetooth, power mode, battery, power menu

## The clock

The clock uses the 12-hour format, like `05:46 PM`. It's set by the `format`
line of the `clock` module in `config.jsonc`:

- `%I:%M %p` is 12-hour: `%I` is the hour 01 to 12, `%M` the minutes, and `%p`
  is AM or PM.
- For 24-hour, like `17:46`, change it to `%H:%M`.

Hover over the clock to see a calendar.

## How the pills work

The bar's background is transparent. Each module gets its own dark rounded
background in `style.css`, so they look like separate floating pills:

```css
window#waybar { background: transparent; }

#cpu, #memory, #clock /* ...and the rest */ {
    background: @bg;
    border-radius: 14px;
    padding: 0 8px;
}
```

Colors are defined once at the top with `@define-color`, so you can change the
whole palette in one place.

## Icons

The icons come from **JetBrainsMono Nerd Font**. In `config.jsonc` they are
written as codes like `""` (the Arch logo), because those characters
often don't display in editors. You can browse them at
<https://www.nerdfonts.com/cheat-sheet>.

## Useful clicks

| Module | Click | Other |
| --- | --- | --- |
| Volume | Opens the mixer (`pavucontrol`) | Right-click mutes, scroll changes volume |
| Brightness | | Scroll changes brightness |
| Network | Opens `nmtui` in a terminal | Hover shows the details |
| Bluetooth | Opens `bluetoothctl` in a terminal | |
| Keyboard | Shows `us` or `ar` | Press Alt+Shift to switch |
| Power mode | Cycles power-saver, balanced and performance | Hover shows the mode ([chapter 12](12-power-management.md)) |
| Power | Lock, log out, reboot, shut down | |

## The power menu

`custom/power` in `config.jsonc` opens `power_menu.xml`. Each item's `id`
matches a command in `menu-actions`:

```jsonc
"menu-actions": {
    "lock": "hyprlock",
    "logout": "uwsm stop",
    "reboot": "systemctl reboot",
    "shutdown": "systemctl poweroff"
}
```

`uwsm stop` logs out because this setup starts Hyprland through **uwsm**. If you
start Hyprland without uwsm, use `hyprctl dispatch 'hl.dsp.exit()'` instead.

## Small screens

My laptop's screen is effectively 1280 px wide at 150% scaling, so space is
tight. The network and Bluetooth modules show only an icon, and the padding is
small. If the keyboard pill shows `…`, the bar ran out of space.

## Reloading

```bash
pkill -SIGUSR2 -x waybar
```

To test a new config without replacing yours:

```bash
waybar -c test-config.jsonc -s test-style.css
```
