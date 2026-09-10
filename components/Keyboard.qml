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
            var m, k, col;

            // red impact glow just above the keys
            var glow = ctx.createLinearGradient(0, -26, 0, 0);
            glow.addColorStop(0, "rgba(255,30,30,0)");
            glow.addColorStop(1, "rgba(255,50,40,0.85)");
            ctx.fillStyle = glow;
            ctx.fillRect(0, -26, W, 26);
            ctx.fillStyle = "rgba(255,70,50,0.9)";
            ctx.fillRect(0, -2, W, 3);

            for (m = Notes.LOW; m <= Notes.HIGH; m++) {
                k = geom[m];
                if (k.black) continue;
                col = root.activeColors[m];
                var g = ctx.createLinearGradient(0, 0, 0, H);
                if (col) {
                    g.addColorStop(0, "rgb(" + col[0] + "," + col[1] + "," + col[2] + ")");
                    g.addColorStop(1, "#cfe8ff");
                } else {
                    g.addColorStop(0, "#dddddd");
                    g.addColorStop(0.1, "#ffffff");
                    g.addColorStop(1, "#d8d8d8");
                }
                ctx.fillStyle = g;
                ctx.fillRect(k.x + 0.5, 0, k.w - 1, H);
                ctx.strokeStyle = "rgba(0,0,0,0.4)";
                ctx.strokeRect(k.x + 0.5, 0, k.w - 1, H);
            }

            for (m = Notes.LOW; m <= Notes.HIGH; m++) {
                k = geom[m];
                if (!k.black) continue;
                col = root.activeColors[m];
                var bh = H * 0.62;
                ctx.fillStyle = col ? "rgb(" + col[0] + "," + col[1] + "," + col[2] + ")" : "#111111";
                ctx.fillRect(k.x, 0, k.w, bh);
                ctx.strokeStyle = "#000000";
                ctx.strokeRect(k.x, 0, k.w, bh);
            }
        }
    }

    // Repaint whenever the sounding set changes.
    onActiveColorsChanged: cv.requestPaint()
    onWidthChanged: cv.requestPaint()
    onHeightChanged: cv.requestPaint()
}
