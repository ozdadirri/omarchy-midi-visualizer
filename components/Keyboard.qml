import QtQuick
import "../lib/Notes.js" as Notes

// 88-key keyboard with per-note highlighting. `activeColors` maps midi -> [r,g,b]
// for keys currently sounding; the overlay fills it from note impacts.
Item {
    id: root

    property var activeColors: ({})   // midi (int) -> [r,g,b]
    readonly property real hitY: 0     // top edge == impact line (this item's y)

    Canvas {
        id: cv
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d");
            var W = width, H = height;
            ctx.clearRect(0, 0, W, H);
            var geom = Notes.keyGeometry(W);
            var m, k, col, x, w;

            var topPad = 10;                 // space for the impact line + glow
            var kbTop = topPad;
            var kbH = H - topPad;
            var whiteBottomR = Math.min(6, kbH * 0.06);

            // ---- white keys ------------------------------------------------
            for (m = Notes.LOW; m <= Notes.HIGH; m++) {
                k = geom[m];
                if (k.black) continue;
                col = root.activeColors[m];
                x = k.x + 0.5;
                w = k.w - 1;

                var g = ctx.createLinearGradient(0, kbTop, 0, kbTop + kbH);
                if (col) {
                    g.addColorStop(0.0, "rgb(" + col[0] + "," + col[1] + "," + col[2] + ")");
                    g.addColorStop(0.35, Notes.rgba([Math.min(col[0] + 60, 255), Math.min(col[1] + 60, 255), Math.min(col[2] + 60, 255)], 1));
                    g.addColorStop(1.0, "#eef4ff");
                } else {
                    g.addColorStop(0.0, "#e9edf2");
                    g.addColorStop(0.06, "#ffffff");
                    g.addColorStop(0.92, "#f2f4f7");
                    g.addColorStop(1.0, "#d5dae1");
                }
                ctx.fillStyle = g;
                _rr(ctx, x, kbTop - 4, w, kbH + 4, 0, whiteBottomR);
                ctx.fill();

                // seam + soft right shadow
                ctx.strokeStyle = "rgba(20,24,33,0.35)";
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.moveTo(x + w + 0.5, kbTop);
                ctx.lineTo(x + w + 0.5, kbTop + kbH - whiteBottomR);
                ctx.stroke();

                if (col) {
                    // colored bloom near the strike point
                    var bloom = ctx.createLinearGradient(0, kbTop, 0, kbTop + kbH * 0.5);
                    bloom.addColorStop(0, Notes.rgba(col, 0.55));
                    bloom.addColorStop(1, Notes.rgba(col, 0));
                    ctx.fillStyle = bloom;
                    ctx.fillRect(x, kbTop, w, kbH * 0.5);
                }
            }

            // ---- black keys ---------------------------------------------------
            var bH = kbH * 0.62;
            for (m = Notes.LOW; m <= Notes.HIGH; m++) {
                k = geom[m];
                if (!k.black) continue;
                col = root.activeColors[m];
                x = k.x;
                w = k.w;

                var bg = ctx.createLinearGradient(0, kbTop, 0, kbTop + bH);
                if (col) {
                    bg.addColorStop(0, Notes.rgba([Math.min(col[0] + 40, 255), Math.min(col[1] + 40, 255), Math.min(col[2] + 40, 255)], 1));
                    bg.addColorStop(1, "rgb(" + (col[0] * 0.55 | 0) + "," + (col[1] * 0.55 | 0) + "," + (col[2] * 0.55 | 0) + ")");
                } else {
                    bg.addColorStop(0.0, "#3a3d44");
                    bg.addColorStop(0.12, "#26282e");
                    bg.addColorStop(1.0, "#0a0b0d");
                }
                ctx.fillStyle = bg;
                _rr(ctx, x, kbTop - 4, w, bH + 4, 0, Math.min(4, w * 0.35));
                ctx.fill();

                // glossy top edge
                ctx.fillStyle = col ? "rgba(255,255,255,0.5)" : "rgba(255,255,255,0.16)";
                ctx.fillRect(x + 1, kbTop + bH * 0.10, w - 2, 2);
            }

            // ---- impact line + glow (drawn last, on top) --------------------
            var glow = ctx.createLinearGradient(0, 0, 0, kbTop + 20);
            glow.addColorStop(0.0, "rgba(255,40,30,0.0)");
            glow.addColorStop(0.6, "rgba(255,55,40,0.55)");
            glow.addColorStop(1.0, "rgba(255,90,60,0.0)");
            ctx.fillStyle = glow;
            ctx.fillRect(0, 0, W, kbTop + 20);

            ctx.fillStyle = "rgba(255,120,90,0.95)";
            ctx.fillRect(0, kbTop - 3, W, 3);
            ctx.fillStyle = "rgba(255,220,200,0.9)";
            ctx.fillRect(0, kbTop - 3, W, 1);
        }

        // rounded rect with independent top / bottom corner radius.
        // Canvas.arcTo rejects a radius of 0, so fall back to square corners.
        function _rr(ctx, x, y, w, h, rt, rb) {
            rt = Math.max(0, Math.min(rt, w / 2, h / 2));
            rb = Math.max(0, Math.min(rb, w / 2, h / 2));
            ctx.beginPath();
            ctx.moveTo(x + rt, y);
            ctx.lineTo(x + w - rt, y);
            if (rt > 0) ctx.arcTo(x + w, y, x + w, y + rt, rt); else ctx.lineTo(x + w, y);
            ctx.lineTo(x + w, y + h - rb);
            if (rb > 0) ctx.arcTo(x + w, y + h, x + w - rb, y + h, rb); else ctx.lineTo(x + w, y + h);
            ctx.lineTo(x + rb, y + h);
            if (rb > 0) ctx.arcTo(x, y + h, x, y + h - rb, rb); else ctx.lineTo(x, y + h);
            ctx.lineTo(x, y + rt);
            if (rt > 0) ctx.arcTo(x, y, x + rt, y, rt); else ctx.lineTo(x, y);
            ctx.closePath();
        }
    }

    // Repaint whenever the sounding set changes.
    onActiveColorsChanged: cv.requestPaint()
    onWidthChanged: cv.requestPaint()
    onHeightChanged: cv.requestPaint()
}
