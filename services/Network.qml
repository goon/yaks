pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking
import qs

QtObject {
    id: root

    // --- Native Networking singletons ---
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled

    // --- Device Discovery ---
    property WifiDevice wifiDevice: {
        var devs = Networking.devices.values;
        for (var i = 0; i < devs.length; i++) {
            if (devs[i] && devs[i].type === DeviceType.Wifi) return devs[i];
        }
        return null;
    }

    property WiredDevice wiredDevice: {
        var devs = Networking.devices.values;
        for (var i = 0; i < devs.length; i++) {
            if (devs[i] && devs[i].type === DeviceType.Wired) return devs[i];
        }
        return null;
    }

    // --- Ethernet (Wired) Properties ---
    readonly property bool ethernetEnabled: wiredDevice !== null
    readonly property bool ethernetConnected: wiredDevice ? wiredDevice.connected : false
    readonly property string ethernetName: wiredDevice ? wiredDevice.name : ""
    // address is the IP provided directly by the native API
    readonly property string ipv4: {
        if (wiredDevice && wiredDevice.connected && wiredDevice.address !== "")
            return wiredDevice.address;
        if (wifiDevice && wifiDevice.connected && wifiDevice.address !== "")
            return wifiDevice.address;
        return "";
    }

    // --- Wi-Fi Properties ---
    readonly property bool connected: wifiDevice ? wifiDevice.connected : false
    readonly property string ssid: {
        if (!wifiDevice || !wifiDevice.connected) return "Disconnected";
        return _getConnectedSsid();
    }
    readonly property int signalStrength: {
        if (!wifiDevice || !wifiDevice.connected) return 0;
        return _getConnectedSignal();
    }

    // --- Scanning & Networks ---
    property var availableNetworks: []
    readonly property bool scanning: wifiDevice ? wifiDevice.scannerEnabled : false
    readonly property bool loading: false

    // --- Internal Helpers ---
    function _getConnectedSsid() {
        if (!wifiDevice) return "Disconnected";
        var nets = wifiDevice.networks.values;
        for (var i = 0; i < nets.length; i++) {
            if (nets[i].connected) return nets[i].name;
        }
        return "Disconnected";
    }

    function _getConnectedSignal() {
        if (!wifiDevice) return 0;
        var nets = wifiDevice.networks.values;
        for (var i = 0; i < nets.length; i++) {
            if (nets[i].connected) return Math.round(nets[i].signalStrength * 100);
        }
        return 0;
    }

    function _buildNetworksList() {
        if (!wifiDevice) {
            root.availableNetworks = [];
            return;
        }
        var nets = [];
        var nativeNets = wifiDevice.networks.values;
        for (var i = 0; i < nativeNets.length; i++) {
            var net = nativeNets[i];
            nets.push({
                "ssid": net.name,
                "signal": Math.round(net.signalStrength * 100),
                "security": net.security,
                "active": net.connected,
                "secured": net.security !== WifiSecurityType.Open,
                "known": net.known,
                "native": net
            });
        }
        nets.sort((a, b) => b.signal - a.signal);
        root.availableNetworks = nets;
    }

    // --- Public API ---
    function refresh() {
        _buildNetworksList();
    }

    function scan() {
        if (!wifiDevice) return;
        // Toggle scanner to trigger a fresh scan
        wifiDevice.scannerEnabled = false;
        wifiDevice.scannerEnabled = true;
    }

    function connect(ssid, password) {
        if (!wifiDevice) return;
        var nets = wifiDevice.networks.values;
        for (var i = 0; i < nets.length; i++) {
            var net = nets[i];
            if (net.name === ssid) {
                if (password && password !== "") {
                    net.connectWithPsk(password);
                } else {
                    net.connect();
                }
                return;
            }
        }
    }

    function forget(ssid) {
        if (!wifiDevice) return;
        var nets = wifiDevice.networks.values;
        for (var i = 0; i < nets.length; i++) {
            if (nets[i].name === ssid) {
                nets[i].forget();
                return;
            }
        }
    }

    function disconnectWifi() {
        if (wifiDevice) wifiDevice.disconnect();
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function toggleEthernet() {
        if (!wiredDevice) return;
        if (wiredDevice.connected) {
            wiredDevice.disconnect();
        } else if (wiredDevice.network) {
            wiredDevice.network.connect();
        }
    }

    // --- Reactive Updates ---
    // QtObject has no default property, so Connections must be declared as a named property.
    property Connections _networksWatcher: Connections {
        target: root.wifiDevice ? root.wifiDevice.networks : null
        function onValuesChanged() { root._buildNetworksList(); }
    }

    Component.onCompleted: {
        _buildNetworksList();
        if (wifiDevice) {
            wifiDevice.scannerEnabled = true;
        }
    }
}
