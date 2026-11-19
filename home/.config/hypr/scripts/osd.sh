#!/bin/bash
# Changes volume, mic or brightness, then shows the new level as a notification.
# Usage: osd.sh volume-up | volume-down | volume-mute | mic-mute |
#               brightness-up | brightness-down

# Needed so the \U icon codes below turn into real characters
export LC_ALL=C.UTF-8

SINK="@DEFAULT_AUDIO_SINK@"
SOURCE="@DEFAULT_AUDIO_SOURCE@"

# JetBrainsMono Nerd Font icons
ICON_VOLUME_LOW=$'\U000F057F'
ICON_VOLUME_MEDIUM=$'\U000F0580'
ICON_VOLUME_HIGH=$'\U000F057E'
ICON_VOLUME_MUTED=$'\U000F0581'
ICON_MIC=$'\U000F036C'
ICON_MIC_MUTED=$'\U000F036D'
ICON_BRIGHTNESS=$'\U000F00E0'

# Sends the notification directly to Dunst over D-Bus.
# The stack tag makes each notification replace the previous one.
# "value" is what draws the progress bar.
notify() { # title, percent, icon
    # Dunst only allows color markup in the body, so the label goes there too
    local body="<span foreground='#7dcfff'>$3</span>  <b>$1</b>  $2%"
    busctl --user call \
        org.freedesktop.Notifications \
        /org/freedesktop/Notifications \
        org.freedesktop.Notifications \
        Notify 'susssasa{sv}i' \
        osd 0 "" "$1" "$body" 0 \
        4 x-dunst-stack-tag s osd transient b true value i "$2" urgency y 0 \
        1500 >/dev/null
}

# wpctl prints something like: Volume: 0.40 [MUTED]
read_level() { # device. Sets percent and muted.
    local label value state
    read -r label value state < <(wpctl get-volume "$1")
    percent=$(awk -v v="$value" 'BEGIN { printf "%d", v * 100 + 0.5 }')
    muted=$state
}

show_volume() {
    read_level "$SINK"
    if [[ -n $muted ]]; then
        notify "Volume muted" "$percent" "$ICON_VOLUME_MUTED"
    elif ((percent < 34)); then
        notify "Volume" "$percent" "$ICON_VOLUME_LOW"
    elif ((percent < 67)); then
        notify "Volume" "$percent" "$ICON_VOLUME_MEDIUM"
    else
        notify "Volume" "$percent" "$ICON_VOLUME_HIGH"
    fi
}

show_mic() {
    read_level "$SOURCE"
    if [[ -n $muted ]]; then
        notify "Microphone muted" "$percent" "$ICON_MIC_MUTED"
    else
        notify "Microphone" "$percent" "$ICON_MIC"
    fi
}

show_brightness() {
    # brightnessctl -m prints: device,class,current,percent%,max
    local percent
    percent=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
    notify "Brightness" "$percent" "$ICON_BRIGHTNESS"
}

case "$1" in
    volume-up)       wpctl set-volume -l 1 "$SINK" 5%+; show_volume ;;
    volume-down)     wpctl set-volume "$SINK" 5%-; show_volume ;;
    volume-mute)     wpctl set-mute "$SINK" toggle; show_volume ;;
    mic-mute)        wpctl set-mute "$SOURCE" toggle; show_mic ;;
    brightness-up)   brightnessctl -q -e4 -n2 set 5%+; show_brightness ;;
    brightness-down) brightnessctl -q -e4 -n2 set 5%-; show_brightness ;;
    *) echo "Unknown action: $1" >&2; exit 1 ;;
esac
