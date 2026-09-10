#!/usr/bin/env bash
# Adds a "Super + Shift + M" binding that toggles the MIDI Visualizer overlay.
# Safe to re-run: it backs up bindings.lua, refuses to replace a binding that is
# already using that shortcut for something else, and only appends its own block.
set -euo pipefail

plugin_id="dadirri.midiviz"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
plugin_dir="$config_home/omarchy/plugins/$plugin_id"
bindings_file="$config_home/hypr/bindings.lua"
binding='o.bind("SUPER + SHIFT + M", "MIDI Visualizer", "omarchy-shell shell toggle dadirri.midiviz {}")'

if [[ ! -f "$plugin_dir/manifest.json" ]]; then
  printf 'MIDI Visualizer is not installed. Run:\n' >&2
  printf '  omarchy plugin add https://github.com/dadirri/omarchy-midi-visualizer.git --enable\n' >&2
  exit 1
fi

for dep in python3 ffmpeg pw-play; do
  command -v "$dep" >/dev/null || printf 'warning: "%s" not found on PATH\n' "$dep" >&2
done
python3 -c 'import numpy' 2>/dev/null || \
  printf 'warning: python-numpy missing. Run: omarchy pkg add python-numpy\n' >&2

if grep -Eq 'SUPER[[:space:]]*\+[[:space:]]*SHIFT[[:space:]]*\+[[:space:]]*M' "$bindings_file" \
  && ! grep -Fq 'shell toggle dadirri.midiviz' "$bindings_file"; then
  printf 'SUPER + SHIFT + M is already bound. Edit %s to choose another shortcut.\n' "$bindings_file" >&2
  exit 1
fi

if ! grep -Fq 'shell toggle dadirri.midiviz' "$bindings_file"; then
  cp -- "$bindings_file" "$bindings_file.bak.midiviz"
  printf '\n-- MIDI Visualizer: begin\n%s\n-- MIDI Visualizer: end\n' "$binding" >> "$bindings_file"
fi

omarchy plugin enable "$plugin_id"
hyprctl reload
hyprctl configerrors

printf 'MIDI Visualizer installed. Press SUPER + SHIFT + M to toggle it.\n'
