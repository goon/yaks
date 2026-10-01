import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs
pragma Singleton

Singleton {
    // No-op for compatibility, as native bindings update automatically

    id: root

    property var adapter: Bluetooth.defaultAdapter
    property bool powered: adapter ? adapter.enabled : false
    property bool scanning: adapter ? adapter.discovering : false
    property var devices: adapter ? adapter.devices.values : []
    property int connectedCount: 0

    function recount() {
        var n = 0;
        var devs = adapter ? adapter.devices.values : [];
        for (var i = 0; i < devs.length; i++)
            if (devs[i] && devs[i].connected) n++;
        connectedCount = n;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.recount()
    }

    function togglePower() {
        if (adapter)
            adapter.enabled = !adapter.enabled;

    }

    // Force a fresh scan by stopping then starting after a short delay.
    // BlueZ rejects `discovering = true` while already discovering with
    // "Operation already in progress", so we need the stop to settle first.
    function scan() {
        if (!adapter) return;
        adapter.discovering = false;
        restartTimer.restart();
    }

    property Timer restartTimer: Timer {
        interval: 500
        onTriggered: if (adapter) adapter.discovering = true;
    }

    function connectDevice(address) {
        // Quickshell's BlueZ wrapper lacks a proper DBus Agent for PipeWire A2DP authorization.
        // Shelled out to bluetoothctl which properly spawns an agent and handles pairing/connecting.
        Runner.runDetached(["bluetoothctl", "connect", address]);
    }

    function disconnectDevice(address) {
        Runner.runDetached(["bluetoothctl", "disconnect", address]);
    }

    function removeDevice(address) {
        Runner.runDetached(["bluetoothctl", "remove", address]);
    }
}
