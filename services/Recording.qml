import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

pragma Singleton

Singleton {
    id: root

    property bool isRecording: false
    property string currentFilename: ""

    Process {
        id: gsrProcess
        running: false
        
        onExited: {
            // State is now managed by the poller
        }
    }

    Process {
        id: monitorProcess
        command: ["sh", "-c", "pgrep -f '[g]pu-screen-recorder -w screen' >/dev/null"]
        onExited: (code) => {
            var active = (code === 0);
            if (active !== root.isRecording) {
                root.isRecording = active;
            }
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: true
        onTriggered: {
            if (!monitorProcess.running) {
                monitorProcess.running = true;
            }
        }
    }

    function start() {
        if (isRecording) return;

        // Ensure directory exists
        var checkDir = Qt.createQmlObject('import Quickshell.Io; Process { command: ["mkdir", "-p", "' + Config.homeDir + '/Videos"] }', root);
        checkDir.running = true;

        var d = new Date();
        var timestamp = d.getFullYear() + "-" + 
                        String(d.getMonth() + 1).padStart(2, '0') + "-" + 
                        String(d.getDate()).padStart(2, '0') + "_" + 
                        String(d.getHours()).padStart(2, '0') + "-" + 
                        String(d.getMinutes()).padStart(2, '0') + "-" + 
                        String(d.getSeconds()).padStart(2, '0');
        
        root.currentFilename = timestamp + ".mp4";
        var filepath = Config.homeDir + "/Videos/" + root.currentFilename;

        gsrProcess.command = ["gpu-screen-recorder", "-w", "screen", "-f", "144", "-a", "default_output", "-o", filepath];
        gsrProcess.running = true;
        isRecording = true;

        var notifyProcess = Qt.createQmlObject('import Quickshell.Io; Process { command: ["notify-send", "-a", "Quickshell", "-i", "symbol:stop_circle", "Screen Recording", "Screen recording has been started"] }', root);
        notifyProcess.running = true;
    }

    function stop() {
        if (!isRecording) return;
        
        // Use pkill to send SIGINT so gpu-screen-recorder cleanly closes the mp4
        var killer = Qt.createQmlObject('import Quickshell.Io; Process { command: ["pkill", "-SIGINT", "-f", "[g]pu-screen-recorder -w screen"] }', root);
        killer.running = true;
        
        isRecording = false;

        var desc = "Screen recording stopped and saved as \\\"<b>" + root.currentFilename + "</b>\\\"";
        var notifyProcess = Qt.createQmlObject('import Quickshell.Io; Process { command: ["notify-send", "-a", "Quickshell", "-i", "symbol:stop_circle", "Screen Recording", "' + desc + '"] }', root);
        notifyProcess.running = true;
    }

    function toggle() {
        if (isRecording) {
            stop();
        } else {
            start();
        }
    }
}
