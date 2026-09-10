#!/usr/bin/env bash
# Removes only the MIDI Visualizer keybinding block, keeps a backup, validates
# the Hyprland config, and hands plugin removal back to Omarchy.
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
bindings_file="$config_home/hypr/bindings.lua"

if [[ -f "$bindings_file" ]] && grep -Fq 'shell toggle ozdadirri.midiviz' "$bindings_file"; then
  cp -- "$bindings_file" "$bindings_file.bak.midiviz"
  sed -i '/-- MIDI Visualizer: begin/,/-- MIDI Visualizer: end/d' "$bindings_file"
  hyprctl reload
  hyprctl configerrors
  printf 'Removed the SUPER + ALT + M binding (backup: %s.bak.midiviz).\n' "$bindings_file"
fi

apps_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
rm -f "$apps_dir/midi-visualizer.desktop" "$apps_dir/midi-visualizer-overlay.desktop"
rm -f "$HOME/.local/bin/midiviz"
command -v update-desktop-database >/dev/null && update-desktop-database "$apps_dir" 2>/dev/null || true

printf 'Now run:  omarchy plugin remove ozdadirri.midiviz\n'
