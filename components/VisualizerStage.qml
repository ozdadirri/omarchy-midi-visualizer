import QtQuick
import QtQuick.Controls
import qs.Commons
import "../lib/Notes.js" as Notes

// The visualizer itself: header + falling notes + keyboard + transport, plus the
// bridge process and all playback state. Host-agnostic — the Omarchy overlay
// wraps this in a layer-shell PanelWindow, the standalone app wraps it in a
// FloatingWindow.
Rectangle {
    id: root

    // ---- host interface --------------------------------------------------
    property bool running: true          // drive the per-frame work only while shown
    property string initialPath: ""      // optional song to load on first show
    signal closeRequested()

    function loadSong(path) {
        var p = ("" + path).replace(/^file:\/\//, "");
        songPath = p;
        songLabel = _basename(p);
        bridge.start();          // spawns the helper only when there's a song
        bridge.load(p);
    }
    function pauseBridge() { bridge.pause(); }
    function stopBridge()  { bridge.stop(); }   // kill the helper + its audio
    function focusStage()  { keyCatcher.forceActiveFocus(); }

    // ---- state ---------------------------------------------------------------
    property string songPath: ""
    property string songLabel: ""
    property bool splitHands: false
    property real speed: 1.0
    property real volume: 0.7
    property var activeColors: ({})
    property var displayNotes: []

    readonly property string bridgePath:
        Qt.resolvedUrl("../bin/midiviz-bridge").toString().replace("file://", "")
    readonly property string sampleDir:
        Qt.resolvedUrl("../assets/samples").toString().replace("file://", "")

    readonly property var sampleSongs: [
        { name: "Ascension", file: "ascension.mid" },
        { name: "Nichesong", file: "nichesong-Piano.mid" }
    ]

    function _basename(p) {
        var s = ("" + p).replace(/\/+$/, "");
        var i = s.lastIndexOf("/");
        return decodeURIComponent(i >= 0 ? s.slice(i + 1) : s);
    }
    function rebuildDisplayNotes() {
        displayNotes = Notes.applyHandSplit(bridge.notes, splitHands);
    }
    onSplitHandsChanged: rebuildDisplayNotes()

    Component.onCompleted: {
        if (initialPath !== "") loadSong(initialPath);   // starts the bridge itself
        Qt.callLater(focusStage);
    }
    Component.onDestruction: bridge.stop()

    // ---- backdrop ----------------------------------------------------------
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#080a12" }
        GradientStop { position: 0.72; color: "#0a0e1c" }
        GradientStop { position: 1.0; color: "#111a33" }
    }
    Rectangle {
        anchors.fill: parent
        opacity: 0.5
        gradient: Gradient {
            GradientStop { position: 0.55; color: "transparent" }
            GradientStop { position: 1.0; color: "#1e3a8a" }
        }
    }

    BridgeController {
        id: bridge
        executable: root.bridgePath
        onLoaded: root.rebuildDisplayNotes()
        onFailed: function (m) { console.warn("midiviz:", m); errorText.text = m; }
        onEnded: bridge.seek(0)
    }

    FrameAnimation {
        running: root.running
        onTriggered: {
            var t = bridge.playhead;
            var next = {};
            var ns = root.displayNotes;
            for (var i = Notes.lowerBoundByStart(ns, t - 8.0); i < ns.length; i++) {
                var n = ns[i];
                if (n[1] > t) break;
                if (t < n[1] + n[2]) next[n[0]] = Notes.colorFor(n[4]);
            }
            root.activeColors = next;
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: filePicker.visible ? filePicker.close() : root.closeRequested()
    }
    Shortcut { sequence: "Space"; context: Qt.WindowShortcut; onActivated: transport.togglePlay() }
    Shortcut { sequence: "Ctrl+O"; context: Qt.WindowShortcut; onActivated: filePicker.open() }

    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Escape) { root.closeRequested(); event.accepted = true; }
            else if (event.key === Qt.Key_Space) { transport.togglePlay(); event.accepted = true; }
        }
    }

    // ---- shared header button style --------------------------------------
    component Pill: Button {
        id: pill
        horizontalPadding: 14
        verticalPadding: 7
        opacity: enabled ? 1 : 0.4
        contentItem: Text {
            text: pill.text
            color: pill.hovered ? "#ffffff" : "#c6d3ea"
            font.family: Style.font.family
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 8
            color: pill.down ? Qt.rgba(0.35, 0.55, 1, 0.28)
                 : pill.hovered ? Qt.rgba(1, 1, 1, 0.13) : Qt.rgba(1, 1, 1, 0.06)
            border.color: Qt.rgba(0.5, 0.65, 1, 0.25)
        }
    }

    FallingNotes {
        id: falling
        anchors { left: parent.left; right: parent.right; top: headerBar.bottom; bottom: keyboard.top }
        notes: root.displayNotes
        playhead: bridge.playhead
    }

    Keyboard {
        id: keyboard
        anchors { left: parent.left; right: parent.right; bottom: transport.top }
        height: Math.max(190, Math.min(340, root.height * 0.28))
        activeColors: root.activeColors
    }

    Transport {
        id: transport
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        playing: bridge.playing
        playhead: bridge.playhead
        duration: bridge.duration
        onTogglePlay: bridge.playing ? bridge.pause() : bridge.play()
        onSeekRequested: function (t) { bridge.seek(t); }
        onSpeedRequested: function (v) { root.speed = v; bridge.setSpeed(v); }
        onVolumeRequested: function (v) { root.volume = v; bridge.setVolume(v); }
    }

    // ---- header ----------------------------------------------------------
    Rectangle {
        id: headerBar
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 56
        color: Qt.rgba(0.04, 0.05, 0.09, 0.82)

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: Qt.rgba(0.42, 0.62, 1.0, 0.35)
        }

        Flickable {
            anchors {
                left: parent.left; leftMargin: 20
                right: parent.right; rightMargin: 200
                verticalCenter: parent.verticalCenter
            }
            height: parent.height
            contentWidth: controlsRow.width
            contentHeight: height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

          Row {
            id: controlsRow
            height: parent.height
            spacing: 12

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                visible: root.width > 900
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10; height: 10; radius: 5
                    color: "#5ac8ff"
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "MIDI  VISUALIZER"
                    color: "#eaf2ff"
                    font.family: Style.font.family
                    font.pixelSize: Style.font.heading
                    font.bold: true
                    font.letterSpacing: 2
                }
            }

            Pill {
                anchors.verticalCenter: parent.verticalCenter
                text: "Load MIDI…"
                onClicked: filePicker.open()
            }

            ComboBox {
                anchors.verticalCenter: parent.verticalCenter
                width: 180
                model: root.sampleSongs.map(function (s) { return s.name; })
                onActivated: function (i) {
                    root.loadSong(root.sampleDir + "/" + root.sampleSongs[i].file);
                }
            }

            ComboBox {
                id: instrumentBox
                anchors.verticalCenter: parent.verticalCenter
                width: 170
                model: bridge.instruments
                currentIndex: Math.max(0, bridge.instruments.indexOf(bridge.instrument))
                onActivated: function (i) { bridge.setInstrument(bridge.instruments[i]); }
            }

            Pill {
                anchors.verticalCenter: parent.verticalCenter
                text: "↻ Restart"
                enabled: bridge.duration > 0
                onClicked: bridge.seek(0)
            }

            CheckBox {
                anchors.verticalCenter: parent.verticalCenter
                text: "Split hands"
                checked: root.splitHands
                onToggled: root.splitHands = checked
                contentItem: Text {
                    text: parent.text
                    color: "#cdd9ee"
                    font.family: Style.font.family
                    leftPadding: parent.indicator.width + 6
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.songLabel !== "" && errorText.text === ""
                text: "♪ " + root.songLabel
                color: "#8fb4ff"
                font.family: Style.font.family
                elide: Text.ElideRight
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

        Pill {
            id: closeBtn
            anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 18 }
            text: root.width > 720 ? "✕   Close   (Esc)" : "✕"
            onClicked: root.closeRequested()
        }
    }

    FilePicker {
        id: filePicker
        onPicked: function (p) { root.loadSong(p); }
    }
}
