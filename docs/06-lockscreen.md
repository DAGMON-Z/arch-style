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

Lock now: power menu → **Lock**, or run `hyprlock`.

The clock is 12-hour (`text = $TIME12` in `hyprlock.conf`). For 24-hour, change
it to `text = $TIME`.

## hypridle (what happens when you're away)

Config: `~/.config/hypr/hypridle.conf`

| After | What happens |
| --- | --- |
| 15 minutes idle | Suspends the laptop |
| Before any suspend | Locks first |

There's **no lock after a few idle minutes**: that was turned off on purpose,
so the screen doesn't lock while you're reading or thinking. When you leave,
lock it yourself with **Lock** in Waybar's power menu. To bring the automatic lock
back, uncomment the `listener` block for it in `hypridle.conf` and run
`systemctl --user restart hypridle`.

Apps playing video can ask the system to stay awake, and hypridle respects that.

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
