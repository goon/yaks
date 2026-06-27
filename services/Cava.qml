import QtQuick
import Quickshell
import Quickshell.Io
import qs
pragma Singleton

Singleton {
    id: root

    property var spectrum: []
    readonly property int barsCount: 48

    Component.onCompleted: {
        var initial = [];
        for (var i = 0; i < barsCount; i++) {
            initial.push(0.0);
        }
        spectrum = initial;
    }

    Process {
        id: cavaProcess
        command: ["stdbuf", "-oL", "cava", "-p", Globals.rootDir + "/config/cava.conf"]
        running: true

        stdout: SplitParser {
            onRead: (line) => {
                var cleanLine = line.trim();
                if (!cleanLine) return;
                var parts = cleanLine.split(/\s+/);
                
                if (parts.length >= root.barsCount) {
                    var newSpectrum = [];
                    for (var i = 0; i < root.barsCount; i++) {
                        var val = parseInt(parts[i]) || 0;
                        var rawNorm = val / 700.0;
                        var normalized = 0.0;
                        if (rawNorm >= 0.08) {
                            normalized = Math.max(0.0, Math.min(1.0, (rawNorm - 0.08) / 0.92));
                        }
                        newSpectrum.push(normalized);
                    }
                    root.spectrum = newSpectrum;
                }
            }
        }

        onExited: (code) => {
            console.warn("Cava process exited with code:", code);
            restartTimer.start();
        }
    }

    Timer {
        id: restartTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (!cavaProcess.running) {
                cavaProcess.running = true;
            }
        }
    }
}
