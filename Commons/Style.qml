pragma Singleton
import QtQuick

// Minimal stand-in for the Omarchy shell's qs.Commons.Style, so the shared
// visualizer components render when run as a standalone Quickshell app.
QtObject {
    readonly property QtObject font: QtObject {
        readonly property string family: "Inter, Roboto, 'DejaVu Sans', sans-serif"
        readonly property int heading: 16
    }
}
