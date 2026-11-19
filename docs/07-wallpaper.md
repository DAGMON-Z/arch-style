# 7. Wallpaper and `set-wallpaper`

**No wallpaper images are included in this repository.** Use your own: put it
in `~/Pictures/Wallpapers` and run:

```bash
set-wallpaper ~/Pictures/Wallpapers/your-image.jpg
```

That one command sets it in four places: desktop, lock screen, login screen and
boot menu. Until you do, the installer uses a **Tokyo Night gradient**, made with
`ffmpeg`, as the default. It's the one in the screenshots.

Script: `~/.local/bin/set-wallpaper`

## Ways to run it

| Command | What it changes | Password? |
| --- | --- | --- |
| `set-wallpaper <image>` | Desktop, lock, login and boot menu | Yes, once |
| `set-wallpaper --no-system <image>` | Desktop and lock screen only | No |
| `set-wallpaper --restore` | Shows the current wallpaper again | No |

Hyprland runs `set-wallpaper --restore` at login.

## How it works

### 1. Prepare the image

It reads your screen size from Hyprland, for example 1920x1080, then uses
`ffmpeg` to make two copies at exactly that size. The edges are cropped, not
stretched:

- `~/.local/share/wallpaper/current.jpg`: for the desktop, lock and login screens
- `~/.local/share/wallpaper/current.png`: for GRUB, which loads PNG reliably

```bash
ffmpeg -i input.jpg \
  -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080" \
  current.jpg
```

`force_original_aspect_ratio=increase` scales the image until it covers the
whole screen. `crop` then cuts off what sticks out.

### 2. Desktop

It shows the image with **awww**, using a *grow* transition, which expands
from the center. If awww's background program (`awww-daemon`) isn't running, it
starts it.

> awww used to be called **swww**. Older guides use `swww img`; the command is
> now `awww img`.

### 3. Lock screen

It makes sure `hyprlock.conf` points at `current.jpg`. It edits the file only
once, and keeps a `.bak` copy.

### 4. Login screen and boot menu

These files belong to the system, so the script runs itself again with `sudo`
(`set-wallpaper --system ...`) to:

- copy the JPG into the SDDM theme as `background.jpg`,
- copy the PNG into the GRUB theme as `background.png`,
- run `grub-mkconfig` into a separate file and check it. It replaces your boot
  menu only if the theme loads and the kernel lines match the old menu.

Each changed file gets a `.bak` copy the first time.

## Why a separate folder?

The script never changes your original image. It works on copies in
`~/.local/share/wallpaper/`, so the desktop still works at login even if you
move or delete the original.

## hyprpaper

This setup used **hyprpaper** before switching to awww. Its config,
`hyprpaper.conf`, is kept as a reference, but Hyprland no longer starts it.
