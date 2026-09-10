import QtQuick
import Quickshell.Io

// Owns the midiviz-bridge helper process and the single NDJSON write path.
// The bridge is the timeline authority: it plays the audio and reports the
// playhead, so the overlay never runs its own song clock.
QtObject {
    id: root

    required property string executable   // absolute path to bin/midiviz-bridge

    readonly property bool running: proc.running
    property bool ready: false

    // Populated from the "loaded" event.
    property var notes: []
    property real duration: 0
    property int trackCount: 0

    // Live transport state from the "time" event.
    property real playhead: 0
    property bool playing: false

    // Instrument list / selection, from the "ready" event.
    property var instruments: ["Grand Piano"]
    property string instrument: "Grand Piano"

    signal loaded()
    signal ended()
    signal failed(string message)

    function start() {
        if (proc.running) return;
        proc.command = [root.executable];
        proc.running = true;
    }

    function stop() {
        if (proc.running) proc.signal(15);
    }

    // Commands issued before the bridge finishes booting are queued and
    // flushed once it emits "ready".
    property var _queue: []

    function _send(obj) {
        if (proc.running && root.ready) {
            proc.write(JSON.stringify(obj) + "\n");
        } else {
            var q = root._queue.slice();
            q.push(obj);
            root._queue = q;
        }
    }

    function _flush() {
        var q = root._queue;
        root._queue = [];
        for (var i = 0; i < q.length; i++)
            proc.write(JSON.stringify(q[i]) + "\n");
    }

    function load(path)   { _send({ cmd: "load", path: path }); }
    function play()       { _send({ cmd: "play" }); }
    function pause()      { _send({ cmd: "pause" }); }
    function seek(t)      { _send({ cmd: "seek", t: t }); }
    function setSpeed(v)  { _send({ cmd: "speed", v: v }); }
    function setVolume(v) { _send({ cmd: "volume", v: v }); }
    function setInstrument(name) { root.instrument = name; _send({ cmd: "instrument", name: name }); }

    property Process proc: Process {
        command: [root.executable]
        stdinEnabled: true

        stdout: SplitParser {
            onRead: function (line) {
                var msg;
                try { msg = JSON.parse(line); } catch (e) { return; }
                switch (msg.ev) {
                case "ready":
                    if (msg.instruments) root.instruments = msg.instruments;
                    if (msg.instrument) root.instrument = msg.instrument;
                    root.ready = true;
                    root._flush();
                    break;
                case "loaded":
                    root.notes = msg.notes;
                    root.duration = msg.duration;
                    root.trackCount = msg.tracks;
                    root.loaded();
                    break;
                case "time":
                    root.playhead = msg.t;
                    root.playing = msg.playing;
                    break;
                case "end":
                    root.playing = false;
                    root.ended();
                    break;
                case "error":
                    root.failed(msg.msg);
                    break;
                }
            }
        }

        stderr: SplitParser { onRead: function (line) { console.log("[midiviz-bridge]", line); } }

        onExited: function (code) {
            root.ready = false;
            if (code !== 0) root.failed("bridge exited (" + code + ")");
        }
    }
}
