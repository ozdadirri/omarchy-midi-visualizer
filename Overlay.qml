import Quickshell
import Quickshell.Wayland
import QtQuick
import "components" as C

// Omarchy shell overlay entry point. Wraps the shared VisualizerStage in a
// fullscreen wlr-layer-shell surface toggled by the shell / a keybinding.
Item {
    id: root

    // Injected by the Omarchy shell.
    property var shell: null
    property var manifest: null

    property bool opened: false
    readonly property string pluginId: (manifest && manifest.id) || "ozdadirri.midiviz"

    function open(payloadJson) {
        opened = true;
        var p = "";
        try { var o = JSON.parse(payloadJson || "{}"); p = o.path || ""; } catch (e) {}
        if (p) stage.loadSong(p);
        Qt.callLater(function () { stage.focusStage(); });
    }

    function close() { opened = false; stage.pauseBridge(); }

    function dismiss() {
        opened = false;                       // drops the layer surface
        stage.pauseBridge();
        if (shell && typeof shell.hide === "function") {
            try { shell.hide(root.pluginId); } catch (e) {}
        }
    }

    function toggle() { opened ? dismiss() : open("{}"); }

    PanelWindow {
        id: panel
        visible: root.opened
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "ozdadirri-midiviz"
        WlrLayershell.layer: WlrLayer.Overlay
        // OnDemand (not Exclusive): the compositor keeps processing global
        // keybinds, so the overlay can never wedge the keyboard.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        onVisibleChanged: if (visible) Qt.callLater(function () { stage.focusStage(); })

        C.VisualizerStage {
            id: stage
            anchors.fill: parent
            running: root.opened
            onCloseRequested: root.dismiss()
        }
    }
}
