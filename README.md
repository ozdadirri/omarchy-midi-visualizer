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

Installed via your package manager, not by the plugin:

```bash
omarchy pkg add python-numpy ffmpeg
```

`python3`, `pw-play` (PipeWire) and `ffmpeg` are expected on a standard Omarchy
install; `python-numpy` powers the real-time mixer.

## Install

```bash
omarchy plugin add https://github.com/dadirri/omarchy-midi-visualizer.git --enable
~/.config/omarchy/plugins/dadirri.midiviz/install.sh
```

`install.sh` adds a `SUPER + SHIFT + M` binding (with a `bindings.lua` backup and
a guard against clobbering an existing shortcut). You can also summon it directly:

```bash
omarchy-shell shell toggle dadirri.midiviz '{}'
```

Pass a file to open on launch: `omarchy-shell shell toggle dadirri.midiviz '{"path":"/abs/song.mid"}'`.

## Use

- `SUPER + SHIFT + M` — show / hide
- `Space` — play / pause
- `Esc` — dismiss
- Header combo box — load a bundled sample song
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

Video export, custom background image upload, arbitrary-file picker (only bundled
samples for now), per-track colour pickers, custom sample packs.

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
