#!/usr/bin/env bash
# Removes only the MIDI Visualizer keybinding block, keeps a backup, validates
# the Hyprland config, and hands plugin removal back to Omarchy.
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
bindings_file="$config_home/hypr/bindings.lua"

if [[ -f "$bindings_file" ]] && grep -Fq 'shell toggle dadirri.midiviz' "$bindings_file"; then
  cp -- "$bindings_file" "$bindings_file.bak.midiviz"
  sed -i '/-- MIDI Visualizer: begin/,/-- MIDI Visualizer: end/d' "$bindings_file"
  hyprctl reload
  hyprctl configerrors
  printf 'Removed the SUPER + SHIFT + M binding (backup: %s.bak.midiviz).\n' "$bindings_file"
fi

printf 'Now run:  omarchy plugin remove dadirri.midiviz\n'
