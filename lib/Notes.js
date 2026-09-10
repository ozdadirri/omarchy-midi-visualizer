.pragma library

// Shared, stateless helpers for the visualizer. Ported from the web app's
// layout maths so the falling notes line up with the 88-key keyboard.

var LOW = 21;   // A0
var HIGH = 108; // C8
var BLACK_PC = { 1: true, 3: true, 6: true, 8: true, 10: true };
var NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

function isBlack(midi) { return BLACK_PC[midi % 12] === true; }

function noteName(midi) { return NAMES[midi % 12]; }

function noteLabel(midi) { return NAMES[midi % 12] + (Math.floor(midi / 12) - 1); }

// midi -> { x, w, black } in pixels, for a keyboard `width` px wide.
function keyGeometry(width) {
    var geom = {};
    var whites = 0, m;
    for (m = LOW; m <= HIGH; m++) if (!isBlack(m)) whites++;
    var ww = width / whites;
    var x = 0;
    for (m = LOW; m <= HIGH; m++) {
        if (!isBlack(m)) { geom[m] = { x: x, w: ww, black: false }; x += ww; }
    }
    for (m = LOW; m <= HIGH; m++) {
        if (isBlack(m)) {
            var left = geom[m - 1];
            geom[m] = { x: left.x + left.w - ww * 0.32, w: ww * 0.64, black: true };
        }
    }
    return geom;
}

// Default per-track colours (RGB triplets), cycled. Tweak in the overlay UI.
var TRACK_COLORS = [
    [ 90, 200, 255], [255, 140,  90], [150, 255, 150], [255, 120, 200],
    [255, 220, 100], [170, 150, 255], [120, 255, 230], [255, 100, 100]
];

function colorFor(track) { return TRACK_COLORS[track % TRACK_COLORS.length]; }

function rgba(rgb, a) {
    return "rgba(" + rgb[0] + "," + rgb[1] + "," + rgb[2] + "," + a + ")";
}

// Split hands at middle C (60): returns a note array with the track field
// replaced by 0 (left) / 1 (right) when `enabled`, else the notes untouched.
// Each note is [midi, time, dur, vel, track].
function applyHandSplit(notes, enabled) {
    if (!enabled) return notes;
    var out = [];
    for (var i = 0; i < notes.length; i++) {
        var n = notes[i];
        out.push([n[0], n[1], n[2], n[3], n[0] < 60 ? 0 : 1]);
    }
    return out;
}

function fmtTime(s) {
    s = Math.max(0, Math.floor(s));
    return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2);
}
