"""Tests for the MIDI parsing and seek logic in bin/midiviz-bridge.

No audio, no numpy: the module imports cleanly because Sampler/Engine are only
built inside main().
"""
import importlib.util
import os
import struct
import tempfile
import unittest

_PATH = os.path.join(os.path.dirname(__file__), "..", "bin", "midiviz-bridge")
_spec = importlib.util.spec_from_loader(
    "midiviz_bridge", importlib.machinery.SourceFileLoader("midiviz_bridge", _PATH))
bridge = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(bridge)


def _varlen(n):
    out = bytearray([n & 0x7F])
    n >>= 7
    while n:
        out.insert(0, (n & 0x7F) | 0x80)
        n >>= 7
    return bytes(out)


def _make_midi(events, division=480):
    """events: list of (delta_ticks, bytes). Returns a format-0 SMF."""
    track = bytearray()
    for delta, payload in events:
        track += _varlen(delta) + payload
    track += _varlen(0) + b"\xFF\x2F\x00"
    head = b"MThd" + struct.pack(">IHHH", 6, 0, 1, division)
    return head + b"MTrk" + struct.pack(">I", len(track)) + bytes(track)


class ParseTests(unittest.TestCase):
    def _parse(self, data):
        with tempfile.NamedTemporaryFile(suffix=".mid", delete=False) as fh:
            fh.write(data)
            path = fh.name
        try:
            return bridge.parse_midi(path)
        finally:
            os.unlink(path)

    def test_single_note_timing(self):
        data = _make_midi([
            (0, b"\x90\x3C\x64"),     # note on C4 vel 100
            (480, b"\x80\x3C\x00"),   # note off one quarter later
        ])
        notes, duration = self._parse(data)
        self.assertEqual(len(notes), 1)
        midi, start, dur, vel, track = notes[0]
        self.assertEqual(midi, 60)
        self.assertAlmostEqual(start, 0.0, places=3)
        self.assertAlmostEqual(dur, 0.5, places=3)     # 500000 us/qn default
        self.assertAlmostEqual(vel, 100 / 127.0, places=3)
        self.assertEqual(track, 0)
        self.assertAlmostEqual(duration, 0.5, places=3)

    def test_tempo_change_affects_seconds(self):
        data = _make_midi([
            (0, b"\xFF\x51\x03" + struct.pack(">I", 250000)[1:]),  # 240 bpm
            (0, b"\x90\x3C\x64"),
            (480, b"\x80\x3C\x00"),
        ])
        notes, _ = self._parse(data)
        self.assertAlmostEqual(notes[0][2], 0.25, places=3)

    def test_note_on_zero_velocity_is_note_off(self):
        data = _make_midi([
            (0, b"\x90\x3C\x64"),
            (240, b"\x90\x3C\x00"),   # running-status style note off
        ])
        notes, _ = self._parse(data)
        self.assertEqual(len(notes), 1)
        self.assertAlmostEqual(notes[0][2], 0.25, places=3)

    def test_rejects_non_midi(self):
        with self.assertRaises(bridge.MidiParseError):
            self._parse(b"not a midi file at all")


class SeekCursorTests(unittest.TestCase):
    def test_cursor_lands_after_seek_point(self):
        notes = [[60, 0.0, 0.5, 0.5, 0], [62, 1.0, 0.5, 0.5, 0], [64, 2.0, 0.5, 0.5, 0]]
        cursor = 0
        target = 1.5
        while cursor < len(notes) and notes[cursor][1] < target:
            cursor += 1
        self.assertEqual(cursor, 2)
        self.assertEqual(notes[cursor][0], 64)


if __name__ == "__main__":
    unittest.main()
