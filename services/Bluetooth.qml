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
    property int connectedCount: {
        var count = 0;
        for (var i = 0; i < devices.length; i++) {
            if (devices[i].connected) count++;
        }
        return count;
    }

    function togglePower() {
        if (adapter)
            adapter.enabled = !adapter.enabled;

    }

    function toggleScan() {
        if (adapter)
            adapter.discovering = !adapter.discovering;

    }

    function connectDevice(address) {
        // Quickshell's BlueZ wrapper lacks a proper DBus Agent for PipeWire A2DP authorization.
        // Shelled out to bluetoothctl which properly spawns an agent and handles pairing/connecting.
        ProcessService.runDetached(["bluetoothctl", "connect", address]);
    }

    function disconnectDevice(address) {
        ProcessService.runDetached(["bluetoothctl", "disconnect", address]);
    }

    function removeDevice(address) {
        ProcessService.runDetached(["bluetoothctl", "remove", address]);
    }

    function findDevice(address) {
        if (!adapter)
            return null;

        var list = adapter.devices.values;
        for (var i = 0; i < list.length; i++) {
            if (list[i].address === address)
                return list[i];

        }
        return null;
    }

    function refresh() {
    }

}
