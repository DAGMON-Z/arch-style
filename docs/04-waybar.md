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
- **Right:** BEMO's face and today's focus time ([chapter 18](18-bemo.md)), CPU, memory, temperature, keyboard layout, volume, brightness,
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
| BEMO | Have a coffee together | Right-click: BEMO says hi. Hover shows today's work and study time |
| Volume | Opens the mixer (`pavucontrol`) | Right-click mutes, scroll changes volume |
| Brightness | | Scroll changes brightness |
| Network | Opens `nmtui` in a terminal | Hover shows the details |
| Bluetooth | Opens Blueman, the Bluetooth window | Right-click opens `bluetoothctl` in a terminal |
| Keyboard | Shows `us` or `ar` | Press Alt+Shift to switch |
| Power mode | Cycles power-saver, balanced and performance | Hover shows the mode ([chapter 12](12-power-management.md)) |
| Power | Lock, log out, reboot, shut down | |

## Connecting a Bluetooth device

Click the **Bluetooth icon** on the bar to open **Blueman**.

1. Make sure the switch at the top right is **on** (blue).
2. Put your device in pairing mode. For headphones, that's usually holding the
   power button until a light flashes. For a mouse or keyboard, it's often a
   small button underneath.
3. Click **Search**. Your device appears in the list.
4. Right-click it and choose **Pair**. If a code appears, check that it matches
   the one on the device, then confirm.
5. Right-click it again and choose **Trust**, so it reconnects by itself next
   time. **Don't skip this for headphones:** without it, the good-quality
   connection can fail and they sound bad (see
   [troubleshooting](11-troubleshooting.md#bluetooth-headphones-sound-bad)).
6. Right-click it and choose **Connect**.

For headphones or speakers, sound should switch to them. If not, click the
volume pill and choose them under **Output Devices**.

**Without Blueman:** right-click the Bluetooth icon to open `bluetoothctl`, the
text version. Type `power on`, `scan on`, wait for your device, `scan off`,
`pair <address>`, `trust <address>`, then `connect <address>`. Press `Tab`
after the first characters of an address to complete it.

**`No default controller available`** means the computer has no Bluetooth
hardware. Many desktop PCs need a small USB Bluetooth adapter.

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
