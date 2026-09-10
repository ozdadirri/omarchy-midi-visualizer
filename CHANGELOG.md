# Changelog

## 0.2.0

### Added

- **Standalone window app** (`standalone.qml`) alongside the shell overlay — the
  same visualizer in a normal `FloatingWindow` (move / resize / tile / alt-tab,
  closed with the compositor's usual keybind). Shared UI lives in
  `components/VisualizerStage.qml`; `Overlay.qml` and `standalone.qml` are thin
  wrappers. `Commons/` stubs `qs.Commons.Style` for the app build.
- **Instruments** — additive-synth voices in the bridge (Electric Piano, Music
  Box, Pipe Organ, Synth Pad, Pluck, Sine) plus the sampled Grand Piano,
  selectable from a header dropdown. Protocol: `{"cmd":"instrument","name":…}`;
  the list ships in the `ready` event.
- **Load MIDI…** (also `Ctrl+O`) — a built-in directory browser
  (`components/FilePicker.qml`): folder navigation, quick-links, typed-path
  field. A native `QtQuick.Dialogs.FileDialog` aborts this Quickshell build in a
  layer-shell surface, so it is not used.
- **↻ Restart** button; full-width draggable progress bar in the transport.
- `install.sh [overlay|app|both]`, `uninstall.sh` symmetry, `~/.local/bin/midiviz`
  launcher, and `MIDI Visualizer` / `MIDI Visualizer (Overlay)` menu entries.
- Visual pass: glass header/transport bars, gradient backdrop with octave
  guides, glowing rounded note bars, gradient piano keys with a red impact line,
  taller keyboard.

### Changed

- Plugin id `dadirri.midiviz` → `ozdadirri.midiviz`; fixed the GitHub URL.
- The bridge starts only when a song is loaded and is fully stopped (with its
  `pw-play`) when the overlay closes or the window quits — nothing runs idle.
- `install.sh` never installs software or uses sudo; it only names a missing
  dependency package.

### Fixed

- Mixer: O(frames) linear interpolation instead of a per-block full-sample
  `np.interp` — fixes slow / stuttering playback under polyphony (~8 % of one
  core with heavy chords).
- `Transport` `speedChanged`/`volumeChanged` signals collided with the
  auto-generated property-change signals and broke QML loading — renamed.
- Overlay `WlrKeyboardFocus.Exclusive` → `OnDemand`, plus an always-on `Escape`
  shortcut and a Close button, so it can no longer trap the keyboard.
- `Canvas.arcTo` radius guards in the keyboard/notes renderers.
- `BridgeController` queues only persistent commands until `ready`.

## 0.1.0

- Initial release: minimal SMF parser, sampled-piano mixer (numpy → pw-play),
  NDJSON stdio protocol, single-timeline playhead.
- QML overlay: `FallingNotes` / `Keyboard` canvases, `Transport` bar,
  `BridgeController`, bundled sample-song picker, split-hands toggle.
- `install.sh` / `uninstall.sh` managed `SUPER + ALT + M` binding.
- Tests for the MIDI parser and seek-cursor logic.
