import QtQuick
import "../lib/Notes.js" as Notes

// Falling note bars. Notes scroll down and land on the impact line (bottom
// edge) exactly at their start time. Driven by `playhead` from the bridge.
Item {
    id: root

    property var notes: []          // [[midi, time, dur, vel, track], ...] sorted by time
    property real playhead: 0       // seconds
    property real pxPerSec: 180     // fall speed
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
            if (!root.notes || root.notes.length === 0) return;

            var geom = Notes.keyGeometry(W);
            var t = root.playhead;
            var pps = root.pxPerSec;
            var winTop = t - (H / pps);   // earliest time still on screen

            for (var i = 0; i < root.notes.length; i++) {
                var n = root.notes[i];
                var start = n[1], dur = n[2], track = n[4];
                if (start + dur < winTop) continue;
                if (start > t + 0.05) {
                    // notes are time-sorted; once we're past the window we can stop
                    if (start - t > H / pps) break;
                }
                var k = geom[n[0]];
                if (!k) continue;

                var yBottom = H - (start - t) * pps;
                var yTop = H - (start + dur - t) * pps;
                if (yTop > H || yBottom < 0) continue;

                var col = root.trackColors[track] || Notes.colorFor(track);
                var x = k.x + (k.black ? 1 : 2);
                var w = k.w - (k.black ? 2 : 4);

                var grad = ctx.createLinearGradient(x, 0, x + w, 0);
                grad.addColorStop(0, Notes.rgba([col[0] * 0.35 | 0, col[1] * 0.5 | 0, col[2] * 0.7 | 0], 0.95));
                grad.addColorStop(0.5, Notes.rgba([Math.min(col[0] + 70, 255), Math.min(col[1] + 70, 255), Math.min(col[2] + 40, 255)], 0.95));
                grad.addColorStop(1, Notes.rgba([col[0] * 0.35 | 0, col[1] * 0.5 | 0, col[2] * 0.7 | 0], 0.95));
                ctx.fillStyle = grad;
                _roundRect(ctx, x, yTop, w, Math.max(2, yBottom - yTop), 5);
                ctx.fill();
                ctx.strokeStyle = Notes.rgba([Math.min(col[0] + 120, 255), Math.min(col[1] + 120, 255), 255], 0.7);
                ctx.lineWidth = 1;
                ctx.stroke();
            }
        }

        function _roundRect(ctx, x, y, w, h, r) {
            r = Math.min(r, w / 2, h / 2);
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
