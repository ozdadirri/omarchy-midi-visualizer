import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.Commons
import "components" as C
import "lib/Notes.js" as Notes

// MIDI Visualizer overlay. Fullscreen layer surface: falling notes above an
// 88-key keyboard, with a real sampled grand piano played by bin/midiviz-bridge.
Item {
    id: root

    // Injected by the Omarchy shell.
    property var shell: null
    property var manifest: null

    property bool opened: false
    property string songPath: ""
    property bool splitHands: false

    readonly property string bridgePath:
        Qt.resolvedUrl("bin/midiviz-bridge").toString().replace("file://", "")
    readonly property string sampleDir:
        Qt.resolvedUrl("assets/samples").toString().replace("file://", "")

    // Bundled demo songs (mirrors the web app's samples.json).
    readonly property var sampleSongs: [
        { name: "Ascension", file: "ascension.mid" },
        { name: "Nichesong", file: "nichesong-Piano.mid" }
    ]

    // midi -> [r,g,b] for keys currently sounding; recomputed each frame.
    property var activeColors: ({})
    property var displayNotes: []

    function open(payloadJson) {
        opened = true;
        bridge.start();
        try {
            var p = JSON.parse(payloadJson || "{}");
            if (p.path) loadSong(p.path);
        } catch (e) {}
        Qt.callLater(function () { keyCatcher.forceActiveFocus(); });
    }

    function close() { opened = false; bridge.pause(); }

    function dismiss() {
        opened = false;
        bridge.pause();
        if (shell && typeof shell.hide === "function")
            shell.hide((manifest && manifest.id) || "dadirri.midiviz");
    }

    function toggle() { opened ? dismiss() : open("{}"); }

    function loadSong(path) {
        songPath = path;
        bridge.load(path);
    }

    function rebuildDisplayNotes() {
        displayNotes = Notes.applyHandSplit(bridge.notes, splitHands);
    }

    C.BridgeController {
        id: bridge
        executable: root.bridgePath
        onLoaded: root.rebuildDisplayNotes()
        onFailed: function (m) { console.warn("midiviz:", m); errorText.text = m; }
        onEnded: bridge.seek(0)
    }

    onSplitHandsChanged: rebuildDisplayNotes()

    // Impact / active-key tracking off the bridge playhead.
    FrameAnimation {
        running: root.opened
        onTriggered: {
            var t = bridge.playhead;
            var next = {};
            var ns = root.displayNotes;
            for (var i = 0; i < ns.length; i++) {
                var n = ns[i];
                if (n[1] > t) break;
                if (t < n[1] + n[2]) {
                    next[n[0]] = root.splitHands ? Notes.colorFor(n[4]) : Notes.colorFor(n[4]);
                }
            }
            root.activeColors = next;
        }
    }

    PanelWindow {
        id: panel
        visible: root.opened
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "dadirri-midiviz"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: "#0a0a0f"

            Item {
                id: keyCatcher
                anchors.fill: parent
                focus: true
                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Escape) { root.dismiss(); event.accepted = true; }
                    else if (event.key === Qt.Key_Space) { transport.togglePlay(); event.accepted = true; }
                }
            }

            // Falling notes fill everything above the keyboard.
            C.FallingNotes {
                id: falling
                anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: keyboard.top }
                notes: root.displayNotes
                playhead: bridge.playhead
            }

            C.Keyboard {
                id: keyboard
                anchors { left: parent.left; right: parent.right; bottom: transport.top }
                height: Math.max(70, Math.min(130, root.height * 0.13))
                activeColors: root.activeColors
            }

            C.Transport {
                id: transport
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                playing: bridge.playing
                playhead: bridge.playhead
                duration: bridge.duration
                onTogglePlay: bridge.playing ? bridge.pause() : bridge.play()
                onSeekRequested: function (t) { bridge.seek(t); }
                onSpeedChanged: function (v) { speed = v; bridge.setSpeed(v); }
                onVolumeChanged: function (v) { volume = v; bridge.setVolume(v); }
            }

            // Header: title, song picker, split-hands toggle.
            Row {
                id: header
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                height: 34
                spacing: 16

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "MIDI VISUALIZER"
                    color: Color.foreground
                    font.family: Style.font.family
                    font.pixelSize: Style.font.heading
                    font.bold: true
                }

                ComboBox {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 220
                    model: root.sampleSongs.map(function (s) { return s.name; })
                    onActivated: function (i) {
                        root.loadSong(root.sampleDir + "/" + root.sampleSongs[i].file);
                    }
                }

                CheckBox {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Split hands"
                    checked: root.splitHands
                    onToggled: root.splitHands = checked
                }

                Text {
                    id: errorText
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#ff6b6b"
                    font.family: Style.font.family
                    text: ""
                }
            }
        }
    }
}
