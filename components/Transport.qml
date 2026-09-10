import QtQuick
import QtQuick.Controls
import qs.Commons

// Transport: a full-width draggable progress/scrubber strip along the top edge,
// with compact play / speed / volume controls beneath it.
Rectangle {
    id: root

    property bool playing: false
    property real playhead: 0
    property real duration: 0
    property real speed: 1.0
    property real volume: 0.7

    signal togglePlay()
    signal seekRequested(real t)
    signal speedRequested(real v)
    signal volumeRequested(real v)

    implicitHeight: 96
    color: Qt.rgba(0.03, 0.04, 0.08, 0.94)

    function _fmt(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2);
    }

    // ---- full-width scrubber -------------------------------------------------
    Item {
        id: scrub
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 6 }
        height: 22
        enabled: root.duration > 0
        opacity: enabled ? 1 : 0.4
        property real frac: root.duration > 0 ? Math.min(1, root.playhead / root.duration) : 0
        property bool dragging: false
        property real activeFrac: dragging ? seekArea.previewFrac : frac

        Rectangle {                              // groove
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 20; rightMargin: 20 }
            height: 8; radius: 4
            color: Qt.rgba(1, 1, 1, 0.16)

            Rectangle {                          // progress fill
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: parent.width * scrub.activeFrac
                radius: 4
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#3aa0e0" }
                    GradientStop { position: 1; color: "#8fe0ff" }
                }
            }
            Rectangle {                          // handle
                width: 20; height: 20; radius: 10
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width * scrub.activeFrac - width / 2
                color: seekArea.pressed ? "#ffffff" : "#e6f4ff"
                border.color: "#4db6f0"; border.width: 2
                scale: seekArea.containsMouse || seekArea.pressed ? 1.2 : 1
                Behavior on scale { NumberAnimation { duration: 90 } }
            }
        }

        MouseArea {
            id: seekArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            property real previewFrac: 0
            function fracAt(mx) { return Math.max(0, Math.min(1, (mx - 20) / (scrub.width - 40))); }
            onPressed: function (m) { scrub.dragging = true; previewFrac = fracAt(m.x); }
            onPositionChanged: function (m) { if (scrub.dragging) previewFrac = fracAt(m.x); }
            onReleased: {
                scrub.dragging = false;
                if (root.duration > 0) root.seekRequested(previewFrac * root.duration);
            }
        }
    }

    // ---- compact controls row --------------------------------------------------
    Item {
        anchors { left: parent.left; right: parent.right; top: scrub.bottom; bottom: parent.bottom }

        Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 20 }
            spacing: 16

            Button {
                id: playBtn
                anchors.verticalCenter: parent.verticalCenter
                width: 100; height: 36
                text: root.playing ? "❚❚  Pause" : "▶  Play"
                onClicked: root.togglePlay()
                contentItem: Text {
                    text: playBtn.text; color: "#08111f"
                    font.family: Style.font.family; font.bold: true
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 9
                    gradient: Gradient {
                        GradientStop { position: 0; color: playBtn.down ? "#6fd0ff" : "#8fe0ff" }
                        GradientStop { position: 1; color: playBtn.down ? "#3aa0e0" : "#4db6f0" }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: "#cfe0ff"
                font.family: Style.font.family
                font.pixelSize: 13
                text: root._fmt(scrub.dragging ? seekArea.previewFrac * root.duration : root.playhead)
                      + "  /  " + root._fmt(root.duration)
            }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 20 }
            spacing: 22

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: "Speed  " + root.speed.toFixed(2) + "×"
                    color: "#9fb2d4"; font.family: Style.font.family; font.pixelSize: 11
                }
                Slider {
                    width: 130
                    from: 0.5; to: 2.0; value: root.speed
                    onMoved: root.speedRequested(value)
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: "Volume  " + Math.round(root.volume * 100) + "%"
                    color: "#9fb2d4"; font.family: Style.font.family; font.pixelSize: 11
                }
                Slider {
                    width: 130
                    from: 0.0; to: 1.0; value: root.volume
                    onMoved: root.volumeRequested(value)
                }
            }
        }
    }

    // hairline accent along the very top
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 1
        color: Qt.rgba(0.42, 0.62, 1.0, 0.4)
    }
}
