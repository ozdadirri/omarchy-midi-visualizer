import Quickshell
import QtQuick
import "components" as C

// Standalone window build of the MIDI Visualizer. Run with:
//   quickshell -p standalone.qml
// A normal xdg-toplevel window: move / resize / tile / float, closable with
// your compositor's usual keybind, and it shows in alt-tab. Set MIDIVIZ_FILE
// to open a .mid on launch.
ShellRoot {
    FloatingWindow {
        id: win
        title: "MIDI Visualizer"
        implicitWidth: 1360
        implicitHeight: 780
        minimumSize: Qt.size(880, 520)
        color: "#080a12"
        visible: true

        // Window closed by the compositor (SUPER+W, titlebar ✕, etc.) -> quit
        // the process so the audio bridge stops too.
        onClosed: Qt.quit()

        C.VisualizerStage {
            anchors.fill: parent
            running: win.visible
            initialPath: Quickshell.env("MIDIVIZ_FILE") || ""
            onCloseRequested: Qt.quit()
        }
    }
}
