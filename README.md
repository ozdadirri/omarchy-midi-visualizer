# MIDI Visualizer — Omarchy plugin

A Synthesia-style piano visualizer as a native Omarchy (Quattro) overlay. Load a
`.mid` file and watch glowing note bars fall onto an 88-key keyboard, played
through a real sampled grand piano (the Salamander Grand Piano recordings from
the [web version](https://midi.dadirri.org/)).

> Status: **early scaffold (v0.1.0)**. The audio bridge parses MIDI, mixes the
> sampled piano and reports the playhead; the QML overlay is wired but still
> needs on-device iteration against a running Omarchy shell.

## Kind

`overlay` — a fullscreen Wayland layer surface, toggled with a keybinding.

## Requirements

`python3`, `pw-play` (PipeWire), `ffmpeg` and `quickshell` all ship with a
standard Omarchy install. The only extra is **`python-numpy`** (the real-time
mixer). `install.sh` checks for anything missing and offers to install it, so
you normally don't need to do this by hand — but if you prefer:

```bash
omarchy pkg add python-numpy
```

## Install

```bash
omarchy plugin add https://github.com/ozdadirri/omarchy-midi-visualizer.git --enable
~/.config/omarchy/plugins/ozdadirri.midiviz/install.sh both
```

`install.sh [overlay|app|both] [--with-deps]` — `both` (default) installs the
Omarchy overlay *and* the standalone window app. It adds a `SUPER + ALT + M`
binding (with a `bindings.lua` backup and a guard against clobbering an existing
shortcut), drops app-menu entries, and (with `--with-deps`, or by prompting in a
terminal) installs any missing packages. You can also summon the overlay
directly:

```bash
omarchy-shell shell toggle ozdadirri.midiviz '{}'
```

Pass a file to open on launch: `omarchy-shell shell toggle ozdadirri.midiviz '{"path":"/abs/song.mid"}'`.

## Use

- Launch **“MIDI Visualizer”** from the app menu, or `SUPER + ALT + M` — show / hide
- `Space` — play / pause
- `Esc` — dismiss (or the header **✕ Close** button)
- **Load MIDI…** (or `Ctrl+O`) — browse the filesystem for any `.mid` / `.midi`
  file (folder navigation, quick-links, or type an absolute path)
- Header combo box — load a bundled sample song
- **↻ Restart** — jump back to the start
- "Split hands" — colour notes by hand (split at middle C)
- Transport bar — seek, playback speed, volume

## Architecture

```
Overlay.qml ──stdio(NDJSON)──► bin/midiviz-bridge (python3 + numpy)
  FallingNotes.qml   (Canvas)        ├─ minimal SMF parser  → note list
  Keyboard.qml       (Canvas)        ├─ sampled-piano mixer → pw-play
  Transport.qml                      └─ owns the timeline, reports the playhead
```

The bridge is the single clock: audio and the falling notes are driven off one
timeline, so they never drift. See the header of `bin/midiviz-bridge` for the
full protocol.

## Not yet ported from the web app

Video export, custom background image upload, per-track colour pickers, custom
sample packs.

## Develop

```bash
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" ./*.qml components/*.qml
python3 -m unittest discover -s tests -v
```

## Licensing

Plugin code: MIT (see `LICENSE`). The piano samples in `assets/samples/piano/`
are from the Salamander Grand Piano V3 by Alexander Holm, CC-BY 3.0 — see
`THIRD_PARTY_NOTICES.md`.
