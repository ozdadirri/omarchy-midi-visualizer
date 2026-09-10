# Changelog

## 0.1.0 — unreleased

- Initial scaffold.
- `bin/midiviz-bridge`: minimal SMF parser, sampled-piano mixer (numpy → pw-play),
  NDJSON stdio protocol, single-timeline playhead reporting, transport
  (play/pause/seek/speed/volume).
- QML overlay: `FallingNotes` and `Keyboard` canvases, `Transport` bar,
  `BridgeController` process wrapper, bundled sample-song picker, split-hands
  toggle, Space/Esc keys.
- `install.sh` / `uninstall.sh`: managed `SUPER + SHIFT + M` binding.
- Tests for the MIDI parser and seek-cursor logic.
