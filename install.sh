#!/usr/bin/env bash
# Install the MIDI Visualizer in one or both forms:
#
#   ./install.sh                 # both (default)
#   ./install.sh overlay         # Omarchy shell overlay only  (SUPER + ALT + M)
#   ./install.sh app             # standalone window only      (app menu / `midiviz`)
#   ./install.sh both
#
# This script only edits your own config (bindings.lua, ~/.local). It never
# installs packages or uses sudo -- if a runtime dependency is missing it prints
# the `omarchy pkg add` command for you to run. Safe to re-run.
set -euo pipefail

mode="both"
for arg in "$@"; do
  case "$arg" in
    overlay|app|both) mode="$arg" ;;
    *) printf 'usage: %s [overlay|app|both]\n' "$0" >&2; exit 2 ;;
  esac
done
want_overlay=false; want_app=false
[[ "$mode" == overlay || "$mode" == both ]] && want_overlay=true || true
[[ "$mode" == app     || "$mode" == both ]] && want_app=true || true

plugin_id="ozdadirri.midiviz"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
plugin_dir="$config_home/omarchy/plugins/$plugin_id"
bindings_file="$config_home/hypr/bindings.lua"
apps_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
bin_dir="$HOME/.local/bin"
binding='o.bind("SUPER + ALT + M", "MIDI Visualizer", "omarchy-shell shell toggle ozdadirri.midiviz {}")'

if [[ ! -f "$plugin_dir/manifest.json" ]]; then
  printf 'MIDI Visualizer is not installed. Run:\n' >&2
  printf '  omarchy plugin add https://github.com/ozdadirri/omarchy-midi-visualizer.git --enable\n' >&2
  exit 1
fi

# ---- runtime dependency check (report only, never install) ---------------
# python3 / pw-play / quickshell ship with a standard Omarchy install; in
# practice only python-numpy is ever absent.
missing_pkgs=()
command -v ffmpeg   >/dev/null || missing_pkgs+=(ffmpeg)
command -v python3  >/dev/null || missing_pkgs+=(python)
command -v pw-play  >/dev/null || missing_pkgs+=(pipewire)
python3 -c 'import numpy' 2>/dev/null || missing_pkgs+=(python-numpy)
if $want_app && ! command -v quickshell >/dev/null; then missing_pkgs+=(quickshell); fi

if ((${#missing_pkgs[@]})); then
  printf 'Missing runtime dependency. Run:\n  omarchy pkg add %s\n' "${missing_pkgs[*]}" >&2
fi

mkdir -p "$apps_dir"

# ---- overlay form ---------------------------------------------------------
if $want_overlay; then
  if grep -Eq 'SUPER[[:space:]]*\+[[:space:]]*ALT[[:space:]]*\+[[:space:]]*M' "$bindings_file" \
    && ! grep -Fq 'shell toggle ozdadirri.midiviz' "$bindings_file"; then
    printf 'SUPER + ALT + M is already bound. Edit %s to choose another shortcut.\n' "$bindings_file" >&2
    exit 1
  fi
  if ! grep -Fq 'shell toggle ozdadirri.midiviz' "$bindings_file"; then
    cp -- "$bindings_file" "$bindings_file.bak.midiviz"
    printf '\n-- MIDI Visualizer: begin\n%s\n-- MIDI Visualizer: end\n' "$binding" >> "$bindings_file"
  fi
  cp -- "$plugin_dir/midi-visualizer-overlay.desktop" "$apps_dir/"
  omarchy plugin enable "$plugin_id"
  hyprctl reload
  hyprctl configerrors
fi

# ---- standalone app form ------------------------------------------------------
if $want_app; then
  cp -- "$plugin_dir/midi-visualizer.desktop" "$apps_dir/"
  mkdir -p "$bin_dir"
  cat > "$bin_dir/midiviz" <<EOF
#!/usr/bin/env bash
# Launch the standalone MIDI Visualizer window. Pass a .mid to open it.
[[ -n "\${1:-}" ]] && export MIDIVIZ_FILE="\$(realpath -- "\$1")"
exec quickshell -p "$plugin_dir/standalone.qml"
EOF
  chmod +x "$bin_dir/midiviz"
fi

command -v update-desktop-database >/dev/null && update-desktop-database "$apps_dir" 2>/dev/null || true

printf 'MIDI Visualizer installed (%s).\n' "$mode"
$want_overlay && printf '  overlay : SUPER + ALT + M, or the "MIDI Visualizer (Overlay)" menu entry\n' || true
$want_app     && printf '  app     : the "MIDI Visualizer" menu entry, or run  midiviz [file.mid]\n' || true
if $want_app; then
  case ":$PATH:" in
    *":$bin_dir:"*) ;;
    *) printf '  note    : add %s to your PATH to use the `midiviz` command\n' "$bin_dir" ;;
  esac
fi
