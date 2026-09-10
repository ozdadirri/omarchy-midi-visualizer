# Changelog

## 0.1.0 — unreleased

- Initial scaffold.
- `bin/midiviz-bridge`: minimal SMF parser, sampled-piano mixer (numpy → pw-play),
  NDJSON stdio protocol, single-timeline playhead reporting, transport
  (play/pause/seek/speed/volume).
- QML overlay: `FallingNotes` and `Keyboard` canvases, `Transport` bar,
  `BridgeController` process wrapper, bundled sample-song picker, split-hands
  toggle, Space/Esc keys.
- `install.sh` / `uninstall.sh`: managed `SUPER + ALT + M` binding.
- Tests for the MIDI parser and seek-cursor logic.

## Unreleased fixes

- Plugin id renamed `dadirri.midiviz` → `ozdadirri.midiviz`; corrected the
  GitHub URL in the README.
- Mixer: replaced the per-block full-sample `np.interp` with O(frames) linear
  interpolation — fixes audio running slow / stuttering under polyphony.
- `Transport`: renamed `speedChanged`/`volumeChanged` signals (they collided
  with the auto-generated property-change signals and broke QML loading).
- Overlay: `WlrKeyboardFocus.Exclusive` → `OnDemand` and an always-on `Escape`
  shortcut plus a Close button, so the overlay can no longer trap the keyboard.
- Falling notes: binary-search to the on-screen slice.
- **Load MIDI…** button (also `Ctrl+O`) — a built-in directory browser
  (`components/FilePicker.qml`) that walks the filesystem via `ls`, with
  quick-links to Home/Downloads/Music/Desktop/Documents and a typed-path field.
  A native `QtQuick.Dialogs.FileDialog` aborts this Quickshell build inside a
  layer-shell surface, so it is not used. Added a **↻ Restart** button.
- App-launcher entry (`midi-visualizer.desktop`) installed to
  `~/.local/share/applications`, so it can be started from the menu like an app.
- Transport: replaced the cramped seek slider with a full-width draggable
  progress bar; click anywhere on it or drag the handle to scrub.
- Visual pass: glass header/transport bars, gradient backdrop with octave guide
  lines, glowing rounded note bars, polished gradient piano keys with a red
  impact line, and a taller keyboard (~28 % of height).
