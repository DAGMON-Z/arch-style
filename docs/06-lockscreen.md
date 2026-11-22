# 6. Lock screen and idle

## hyprlock (lock screen)

Config: `~/.config/hypr/hyprlock.conf`

It shows the wallpaper with a little blur, a big clock, the date, a password
box and the keyboard layout. The password box border changes color:

| Color | Meaning |
| --- | --- |
| Blue to purple | Waiting for your password |
| Yellow | Checking |
| Red | Wrong password |
| Orange | Caps Lock is on |

> **Check the layout before typing your password.** If you switched to Arabic
> with Alt+Shift, your password is typed in Arabic letters and fails. The label
> under the password box shows `us` or `ar`, and you can click it to switch.

Lock now: press `SUPER + L`, use power menu → **Lock**, or run `hyprlock`.

The clock is 12-hour (`text = $TIME12` in `hyprlock.conf`). For 24-hour, change
it to `text = $TIME`.

## hypridle (what happens when you're away)

Config: `~/.config/hypr/hypridle.conf`

| When | What happens |
| --- | --- |
| You leave it unused | **Nothing**: no automatic lock, no automatic suspend |
| Before any suspend (closing the lid, or Suspend in the power menu) | Locks first |

Both automatic actions are turned off on purpose: the screen never locks or
sleeps while you're reading, thinking or waiting for something. When you
leave, lock it yourself with **`SUPER + L`**, or **Lock** in Waybar's power
menu.

> **On battery**, nothing saves power while you're away now. Close the lid, or
> choose Suspend in the power menu, when you leave the laptop for a while.

To bring either back (lock after 5 minutes, suspend after 15), uncomment its
`listener` block in `hypridle.conf` and run `systemctl --user restart hypridle`.

hypridle runs as a user service:

```bash
systemctl --user enable --now hypridle    # turn on
systemctl --user disable --now hypridle   # turn off
systemctl --user restart hypridle         # after editing the config
```

## How the password is checked (PAM)

hyprlock asks **PAM**, Linux's login system, to check your password, using the
rules in `/etc/pam.d/hyprlock`. If that file is broken or empty, no password
works. I hit exactly this problem; see
[troubleshooting](11-troubleshooting.md#hyprlock-pam-pacnew).

## If the lock screen gets stuck

`hyprland.lua` sets `allow_session_lock_restore = true`. That means if hyprlock
crashes, you can start it again and unlock normally:

1. Press `Ctrl + Alt + F3` and log in on the text screen.
2. Run:

   ```bash
   export XDG_RUNTIME_DIR=/run/user/$(id -u) WAYLAND_DISPLAY=wayland-1
   hyprlock &
   ```

3. Press `Ctrl + Alt + F1` or `F2` to go back, and unlock.
