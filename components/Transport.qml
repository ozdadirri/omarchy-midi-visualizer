import QtQuick
import QtQuick.Controls
import qs.Commons

// Play/pause, seek, speed and volume. Emits intents; the overlay forwards
// them to the bridge.
Rectangle {
    id: root

    property bool playing: false
    property real playhead: 0
    property real duration: 0
    property real speed: 1.0
    property real volume: 0.7

    signal togglePlay()
    signal seekRequested(real t)
    signal speedChanged(real v)
    signal volumeChanged(real v)

    implicitHeight: 56
    color: Qt.rgba(0, 0, 0, 0.55)

    Row {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 16

        Button {
            anchors.verticalCenter: parent.verticalCenter
            width: 84
            text: root.playing ? "Pause" : "Play"
            onClicked: root.togglePlay()
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: Color.foreground
            font.family: Style.font.family
            text: _fmt(root.playhead) + " / " + _fmt(root.duration)
            function _fmt(s) {
                s = Math.max(0, Math.floor(s));
                return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2);
            }
        }

        Slider {
            id: seek
            anchors.verticalCenter: parent.verticalCenter
            width: root.width - 480
            from: 0
            to: Math.max(root.duration, 0.001)
            value: root.playhead
            onPressedChanged: if (!pressed) root.seekRequested(value)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: Color.foreground
            font.family: Style.font.family
            text: "Speed " + root.speed.toFixed(2) + "x"
        }
        Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: 110
            from: 0.5; to: 2.0; value: root.speed
            onMoved: root.speedChanged(value)
        }

        Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: 110
            from: 0.0; to: 1.0; value: root.volume
            onMoved: root.volumeChanged(value)
        }
    }
}
