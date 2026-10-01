pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking
import qs

QtObject {
    id: root

    // ── NATIVE NETWORKING SINGLETONS ──────────────────────────────────
    readonly property bool wifiEnabled: Networking.wifiEnabled

    // ── DEVICE DISCOVERY ──────────────────────────────────────────────
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

    // ── ETHERNET (WIRED) ──────────────────────────────────────────────
    readonly property bool ethernetConnected: wiredDevice ? wiredDevice.connected : false

    // ── WI-FI PROPERTIES ──────────────────────────────────────────────
    readonly property bool connected: wifiDevice ? wifiDevice.connected : false
    readonly property string ssid: {
        if (!wifiDevice || !wifiDevice.connected) return "Disconnected";
        return _getConnectedSsid();
    }
    readonly property int signalStrength: {
        if (!wifiDevice || !wifiDevice.connected) return 0;
        return _getConnectedSignal();
    }

    // ── SCANNING & NETWORKS ───────────────────────────────────────────
    property var availableNetworks: []
    readonly property bool scanning: wifiDevice ? wifiDevice.scannerEnabled : false

    // ── INTERNAL HELPERS ──────────────────────────────────────────────
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
        var nativeNets = wifiDevice.networks.values;
        
        var nets = [];
        var seenSsids = {};

        for (var i = 0; i < nativeNets.length; i++) {
            var net = nativeNets[i];
            if (net.name) seenSsids[net.name] = true;
            
            if (net.connected && pendingConnectSsid === net.name) {
                pendingConnectSsid = "";
            }
            if (!net.connected && pendingDisconnectSsid === net.name) {
                pendingDisconnectSsid = "";
            }
            if (!net.known && pendingForgetSsid === net.name) {
                pendingForgetSsid = "";
            }
            
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

        // If scanning is disabled, NetworkManager often drops unconnected networks.
        // We preserve them here so the UI doesn't suddenly empty out.
        if (!scanning) {
            for (var j = 0; j < root.availableNetworks.length; j++) {
                var oldNet = root.availableNetworks[j];
                if (oldNet.ssid && !seenSsids[oldNet.ssid]) {
                    oldNet.active = false; // It's definitely not connected if it was dropped
                    nets.push(oldNet);
                }
            }
        }

        nets.sort((a, b) => b.signal - a.signal);
        root.availableNetworks = nets;
    }

    // ── LINK DETAIL (the connected row's subtitle) ─────────────────────
    // "192.168.1.58 · 5 GHz 1170 Mbit/s". NetworkManager's QML binding exposes
    // neither the address nor the band/rate, so ask nmcli: one call for the
    // active network's BAND/RATE, one for the wifi device's address.
    property string linkDetail: ""
    readonly property int _linkPollMs: 5000

    property Timer _linkPoller: Timer {
        interval: root._linkPollMs
        repeat: true
        running: root.connected
        onTriggered: root._refreshLinkDetail()
    }

    function _refreshLinkDetail() {
        if (!connected) {
            linkDetail = "";
            return;
        }
        Runner.run(["nmcli", "-t", "-f", "IN-USE,BAND,RATE", "dev", "wifi", "list"], function (out) {
            var band = "", rate = "";
            var lines = (out || "").split("\n");
            for (var i = 0; i < lines.length; i++) {
                var f = lines[i].split(":");
                if (f[0] === "*") { band = f[1]; rate = f[2]; break; }
            }
            // -g prints just the value, scoped to the one device, so no
            // per-device parsing: "192.168.1.58/24" → "192.168.1.58".
            Runner.run(["nmcli", "-g", "IP4.ADDRESS", "device", "show", wifiDevice.name], function (addrOut) {
                var bits = [];
                var ip = (addrOut || "").trim().split("\n")[0].split("/")[0];
                if (ip) bits.push(ip);
                if (band) bits.push(rate ? band + " " + rate : band);
                root.linkDetail = bits.join(" · ");
            });
        });
    }

    // ── OPTIMISTIC UI STATE ───────────────────────────────────────────
    property string pendingConnectSsid: ""
    property string pendingDisconnectSsid: ""
    property string pendingForgetSsid: ""

    // ── PUBLIC API ────────────────────────────────────────────────────
    function toggleScan() {
        if (!wifiDevice) return;
        wifiDevice.scannerEnabled = !wifiDevice.scannerEnabled;
    }

    function connect(ssid, password) {
        if (!wifiDevice) return;
        pendingConnectSsid = ssid;
        pendingDisconnectSsid = "";
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

    function disconnect() {
        if (!wifiDevice) return;
        var nets = wifiDevice.networks.values;
        for (var i = 0; i < nets.length; i++) {
            var net = nets[i];
            if (net.connected) {
                pendingDisconnectSsid = net.name;
                pendingConnectSsid = "";
                // Disconnect logic varies, sometimes it's net.disconnect(), sometimes it's through the device.
                // Assuming Quickshell has disconnect() on WifiNetwork or WifiDevice.
                if (typeof net.disconnect === "function") {
                    net.disconnect();
                } else if (typeof wifiDevice.disconnect === "function") {
                    wifiDevice.disconnect();
                }
                return;
            }
        }
    }

    function forget(ssid) {
        if (!wifiDevice) return;
        pendingForgetSsid = ssid;
        var nets = wifiDevice.networks.values;
        for (var i = 0; i < nets.length; i++) {
            if (nets[i].name === ssid) {
                nets[i].forget();
                return;
            }
        }
    }



    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    // ── REACTIVE UPDATES ──────────────────────────────────────────────
    // QtObject has no default property, so Connections must be declared as a named property.
    property Connections _networksWatcher: Connections {
        target: root.wifiDevice ? root.wifiDevice.networks : null
        function onValuesChanged() { root._buildNetworksList(); }
    }

    Component.onCompleted: {
        _buildNetworksList();
        _refreshLinkDetail();
        if (wifiDevice) {
            wifiDevice.scannerEnabled = true;
        }
    }
}
