#!/usr/bin/env bash

base="$1"
theme="$2"
cp "$HOME/.config/waybar/themes/$base/${base}_$theme-style.css" "$HOME/.config/waybar/style.css" &
cp "$HOME/.config/rofi/themes/$base/${base}_$theme-simple.rasi" "$HOME/.config/rofi/simple.rasi" &
cp "$HOME/.config/rofi/powermenu/themes/$base/${base}_$theme-powermenu.rasi" "$HOME/.config/rofi/powermenu/powermenu.rasi" &
cp "$HOME/.config/deadd/themes/$base/${base}_$theme-deadd.css" "$HOME/.config/deadd/deadd.css" &

# Wait for all copy operations to finish
wait

# Send notifications
notify-send.py a --hint boolean:deadd-notification-center:true string:type:reloadStyle &&
  notify-send.py "Reloaded $theme" --hint string:image-path:file://home/jason/Pictures/icons/"${theme}_theme-icon.png"
