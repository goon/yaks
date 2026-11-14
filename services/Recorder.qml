import QtQuick
import Quickshell
import Quickshell.Io
import qs
pragma Singleton

// Recording state for the bar's timer. Watches the same IPC socket
// Capture.qml hands to gpu-screen-recorder; the socket is the recorder's
// state (GSR creates it at start, removes it at exit), so this asks instead
// of remembering — a shell reload or an out-of-band gsr-cli stop stays
// correct. The start stamp is persisted beside it so a running timer
// survives a reload without resetting to zero.
QtObject {
    id: root

    readonly property string recordSock: Quickshell.env("XDG_RUNTIME_DIR")
        + "/yaks-record.sock"

    readonly property string startFile: Globals.cacheDir + "/recording.start"

    property bool recording: false
    property int elapsedSeconds: 0
    property real _startMs: 0

    readonly property string elapsedText: {
        // ponytail: minute cells cap the display at 99:59; go H:MM:SS if a
        // recording of that length ever matters
        const m = Math.min(99, Math.floor(elapsedSeconds / 60));
        const s = elapsedSeconds % 60;
        return ("0" + m).slice(-2) + ":" + ("0" + s).slice(-2);
    }

    function tick() {
        Runner.run(["gsr-cli", "-ipc", recordSock, "status"], function (out, code) {
            const running = code === 0 && out.trim() === "running";
            if (running === root.recording) {
                if (running)
                    root.elapsedSeconds = Math.floor((Date.now() - root._startMs) / 1000);
                return;
            }
            if (running) {
                let ms = 0;
                try { ms = parseInt(startView.text()); } catch (e) { ms = 0; }
                if (!(ms > 0)) {
                    ms = Date.now();
                    startWriter.setText(String(ms));
                }
                root._startMs = ms;
                root.recording = true;
                root.elapsedSeconds = Math.max(0, Math.floor((Date.now() - ms) / 1000));
            } else {
                root._startMs = 0;
                root.elapsedSeconds = 0;
                root.recording = false;
                Runner.run(["rm", "-f", startFile]);
            }
        });
    }

    property Timer pollTimer: Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.tick()
    }

    property FileView startView: FileView {
        path: root.startFile
        watchChanges: false
    }

    // Atomic writer for the start stamp (atomicWrites defaults to true);
    // the read side stays on startView.
    property FileView startWriter: FileView {
        path: root.startFile
        watchChanges: false
    }
}
