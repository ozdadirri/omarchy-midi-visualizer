import QtQuick
import "../lib/Notes.js" as Notes

// Falling note bars, Synthesia style: glowing rounded bars that scroll down and
// land on the impact line (bottom edge) exactly at their start time. Driven by
// `playhead` from the bridge.
Item {
    id: root

    property var notes: []          // [[midi, time, dur, vel, track], ...] sorted by time
    property real playhead: 0       // seconds
    property real pxPerSec: 190     // fall speed
    property var trackColors: ({})  // track (int) -> [r,g,b] override; else Notes.colorFor

    // Continuous repaint while visible; cheap because we cull to the window.
    FrameAnimation {
        running: root.visible
        onTriggered: cv.requestPaint()
    }

    Canvas {
        id: cv
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d");
            var W = width, H = height;
            ctx.clearRect(0, 0, W, H);

            var geom = Notes.keyGeometry(W);

            // --- faint octave guide lines (at every C) --------------------
            ctx.strokeStyle = "rgba(255,255,255,0.05)";
            ctx.lineWidth = 1;
            for (var m = Notes.LOW; m <= Notes.HIGH; m++) {
                if (m % 12 !== 0) continue;          // C
                var g0 = geom[m];
                if (!g0) continue;
                var gx = Math.round(g0.x) + 0.5;
                ctx.beginPath();
                ctx.moveTo(gx, 0);
                ctx.lineTo(gx, H);
                ctx.stroke();
            }

            if (!root.notes || root.notes.length === 0) return;

            var t = root.playhead;
            var pps = root.pxPerSec;
            var winTop = t - (H / pps);   // earliest time still on screen
            var future = H / pps;         // how far ahead a note can be and still show

            // Jump to the on-screen slice. Back off 8 s so a long note that
            // started before the window but still sustains into it isn't missed.
            var start = Notes.lowerBoundByStart(root.notes, winTop - 8.0);

            // Count what's actually visible; skip the pretty (per-note gradient)
            // path when a dense passage would make it too costly.
            var pretty = true, seen = 0;

            for (var pass = 0; pass < 2; pass++) {
                // pass 0: soft glow halos.  pass 1: solid bars + highlight.
                for (var i = start; i < root.notes.length; i++) {
                    var n = root.notes[i];
                    var s = n[1], dur = n[2], track = n[4];
                    if (s - t > future) break;
                    if (s + dur < winTop) continue;

                    var k = geom[n[0]];
                    if (!k) continue;

                    var yBottom = H - (s - t) * pps;
                    var yTop = H - (s + dur - t) * pps;
                    if (yTop > H || yBottom < 0) continue;

                    var col = root.trackColors[track] || Notes.colorFor(track);
                    var x = k.x + (k.black ? 1.5 : 2.5);
                    var w = k.w - (k.black ? 3 : 5);
                    var y = yTop;
                    var h = Math.max(3, yBottom - yTop);

                    if (pass === 0) {
                        if (++seen > 90) pretty = false;
                        ctx.fillStyle = Notes.rgba(col, 0.16);
                        _roundRect(ctx, x - 5, y - 5, w + 10, h + 10, 8);
                        ctx.fill();
                    } else {
                        if (pretty) {
                            var grad = ctx.createLinearGradient(x, 0, x + w, 0);
                            grad.addColorStop(0.0, Notes.rgba([col[0] * 0.55 | 0, col[1] * 0.6 | 0, col[2] * 0.8 | 0], 0.98));
                            grad.addColorStop(0.35, Notes.rgba([Math.min(col[0] + 90, 255), Math.min(col[1] + 90, 255), 255], 0.98));
                            grad.addColorStop(1.0, Notes.rgba([col[0] * 0.5 | 0, col[1] * 0.55 | 0, col[2] * 0.75 | 0], 0.98));
                            ctx.fillStyle = grad;
                        } else {
                            ctx.fillStyle = Notes.rgba([Math.min(col[0] + 55, 255), Math.min(col[1] + 55, 255), Math.min(col[2] + 55, 255)], 0.98);
                        }
                        _roundRect(ctx, x, y, w, h, 6);
                        ctx.fill();

                        // bright leading edge (bottom) + top sheen
                        ctx.fillStyle = "rgba(255,255,255,0.85)";
                        _roundRect(ctx, x, yBottom - 3, w, 3, 2);
                        ctx.fill();
                        ctx.strokeStyle = Notes.rgba([Math.min(col[0] + 130, 255), Math.min(col[1] + 130, 255), 255], 0.6);
                        ctx.lineWidth = 1;
                        _roundRect(ctx, x + 0.5, y + 0.5, w - 1, h - 1, 6);
                        ctx.stroke();
                    }
                }
            }
        }

        function _roundRect(ctx, x, y, w, h, r) {
            r = Math.max(0.5, Math.min(r, w / 2, h / 2));
            ctx.beginPath();
            ctx.moveTo(x + r, y);
            ctx.arcTo(x + w, y, x + w, y + h, r);
            ctx.arcTo(x + w, y + h, x, y + h, r);
            ctx.arcTo(x, y + h, x, y, r);
            ctx.arcTo(x, y, x + w, y, r);
            ctx.closePath();
        }
    }
}
