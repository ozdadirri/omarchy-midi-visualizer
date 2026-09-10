import QtQuick
import QtQuick.Controls
import Quickshell.Io
import qs.Commons

// A small directory-navigating file browser. A native FileDialog crashes this
// Quickshell build inside a layer-shell surface, so this walks the filesystem
// itself via `ls` and lets you click into folders. The path field also accepts
// a typed absolute path (Enter opens it / navigates to it).
Item {
    id: root
    anchors.fill: parent
    visible: false

    signal picked(string path)

    property string homeDir: "/home"
    property string currentDir: ""
    property var entries: []          // [{name, dir:bool}]

    function open() {
        visible = true;
        if (currentDir === "") currentDir = homeDir;
        pathField.text = currentDir;
        _list();
        pathField.forceActiveFocus();
    }
    function close() { visible = false; }

    function go(dir) {
        root.currentDir = dir.replace(/\/+$/, "") || "/";
        pathField.text = root.currentDir;
        _list();
    }

    function _resolve(p) {
        p = p.trim();
        if (p === "~") return root.homeDir;
        if (p.startsWith("~/")) return root.homeDir + p.slice(1);
        return p;
    }

    property var _acc: []
    function _list() {
        root._acc = [];
        lister.running = false;
        lister.running = true;
    }
    function _rebuild() {
        var dirs = [], files = [];
        for (var i = 0; i < root._acc.length; i++) {
            var ln = root._acc[i];
            if (ln.endsWith("/")) {
                var d = ln.slice(0, -1);
                if (d !== "" && d !== "." && d !== "..") dirs.push({ name: d, dir: true });
            } else if (/\.midi?$/i.test(ln)) {
                files.push({ name: ln, dir: false });
            }
        }
        var list = [];
        if (root.currentDir !== "/") list.push({ name: "..", dir: true });
        root.entries = list.concat(dirs).concat(files);
    }

    Process {
        id: homeProc
        running: true
        command: ["bash", "-lc", "echo \"$HOME\""]
        stdout: SplitParser { onRead: function (l) { if (l) { root.homeDir = l; if (root.currentDir === "") root.currentDir = l; } } }
    }

    Process {
        id: lister
        command: ["bash", "-lc", "ls -1Ap -- \"$1\" 2>/dev/null", "_", root.currentDir]
        stdout: SplitParser { onRead: function (l) { if (l) { var a = root._acc.slice(); a.push(l); root._acc = a; } } }
        onRunningChanged: if (!running) root._rebuild()
    }

    // dim backdrop
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(820, parent.width - 80)
        height: Math.min(600, parent.height - 120)
        radius: 14
        color: "#0e1220"
        border.color: Qt.rgba(0.42, 0.62, 1.0, 0.35)
        MouseArea { anchors.fill: parent }   // swallow clicks

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            Text {
                text: "Open a MIDI file"
                color: "#eaf2ff"
                font.family: Style.font.family
                font.pixelSize: Style.font.heading
                font.bold: true
            }

            // quick locations
            Row {
                spacing: 8
                Repeater {
                    model: [
                        { label: "Home",      sub: "" },
                        { label: "Downloads", sub: "/Downloads" },
                        { label: "Music",     sub: "/Music" },
                        { label: "Desktop",   sub: "/Desktop" },
                        { label: "Documents", sub: "/Documents" }
                    ]
                    delegate: Button {
                        text: modelData.label
                        onClicked: root.go(root.homeDir + modelData.sub)
                        contentItem: Text {
                            text: parent.text; color: parent.hovered ? "#fff" : "#c6d3ea"
                            font.family: Style.font.family; font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            radius: 7; implicitHeight: 28
                            color: parent.hovered ? Qt.rgba(1,1,1,0.13) : Qt.rgba(1,1,1,0.05)
                            border.color: Qt.rgba(1,1,1,0.10)
                        }
                    }
                }
            }

            // editable path / filter
            TextField {
                id: pathField
                width: parent.width
                color: "#eaf2ff"
                font.family: Style.font.family
                placeholderText: "/path/to/folder  or  /path/to/song.mid"
                onAccepted: {
                    var p = root._resolve(text);
                    if (/\.midi?$/i.test(p)) { root.picked(p); root.close(); }
                    else root.go(p);
                }
                background: Rectangle {
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.color: pathField.activeFocus ? "#4db6f0" : Qt.rgba(1, 1, 1, 0.12)
                }
            }

            // listing
            Rectangle {
                width: parent.width
                height: parent.height - y - 52
                radius: 8
                color: Qt.rgba(0, 0, 0, 0.25)
                clip: true

                ListView {
                    id: list
                    anchors.fill: parent
                    anchors.margins: 4
                    model: root.entries
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar {}

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 38
                        color: ma.containsMouse ? Qt.rgba(0.3, 0.5, 1, 0.16) : "transparent"
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            spacing: 10
                            Text {
                                text: modelData.dir ? "📁" : "🎵"
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: modelData.name
                                color: modelData.dir ? "#cfe0ff" : "#e6edfb"
                                font.family: Style.font.family
                                font.bold: modelData.dir
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (modelData.name === "..") {
                                    var c = root.currentDir;
                                    root.go(c.slice(0, c.lastIndexOf("/")) || "/");
                                } else if (modelData.dir) {
                                    root.go(root.currentDir.replace(/\/$/, "") + "/" + modelData.name);
                                } else {
                                    root.picked(root.currentDir.replace(/\/$/, "") + "/" + modelData.name);
                                    root.close();
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: list.count === 0
                        text: lister.running ? "…" : "No folders or .mid files here"
                        color: "#7f8fb0"
                        font.family: Style.font.family
                    }
                }
            }

            Button {
                anchors.right: parent.right
                text: "Cancel  (Esc)"
                onClicked: root.close()
                contentItem: Text {
                    text: parent.text; color: "#c6d3ea"
                    font.family: Style.font.family
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 8; implicitHeight: 34; implicitWidth: 130
                    color: parent.hovered ? Qt.rgba(1, 1, 1, 0.13) : Qt.rgba(1, 1, 1, 0.06)
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                }
            }
        }

        Keys.onEscapePressed: root.close()
    }
}
