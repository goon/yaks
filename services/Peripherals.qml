import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs

pragma Singleton

Singleton {
    id: root

    readonly property int lowAt: 20

    property var devices: []
    property var byMac: ({})
    property var unmatched: []
    property string _sig: ""
    property var _notified: ({})

    readonly property var _macRe: /([0-9a-f]{2}[:_]){5}[0-9a-f]{2}/i

    // UPower's D-Bus scale is 0..100 but Quickshell's PowerPercentage transform
    // divides it out, so `percentage` arrives as 0..1.
    function pct(d) { return Math.round(d.percentage * 100); }

    function charging(d) {
        return d.state === UPowerDeviceState.Charging
            || d.state === UPowerDeviceState.FullyCharged;
    }

    function refresh() {
        var out = [], all = UPower.devices.values;
        for (var i = 0; i < all.length; i++) {
            var d = all[i];
            if (!d || !d.ready || !d.isPresent) continue;
            if (d.type === UPowerDeviceType.Battery || d.type === UPowerDeviceType.LinePower
                || d.type === UPowerDeviceType.Unknown) continue;
            out.push(d);
        }

        var sig = "", macs = {}, rest = [];
        for (var j = 0; j < out.length; j++) {
            var m = _macRe.exec(out[j].nativePath);
            if (m) macs[m[0].toUpperCase().replace(/[:_]/g, "")] = out[j];
            else rest.push(out[j]);
            sig += out[j].nativePath + ";";
        }

        if (sig !== root._sig) {
            root._sig = sig;
            root.devices = out;
            root.byMac = macs;
            root.unmatched = rest;
        }

        root._checkLow();
    }

    function _checkLow() {
        for (var i = 0; i < devices.length; i++) {
            var d = devices[i];
            if (root.pct(d) <= root.lowAt && !root.charging(d)) {
                if (_notified[d.nativePath]) continue;
                _notified[d.nativePath] = true;
                Runner.runDetached(["notify-send", "-a", "Peripherals", "-i", d.iconName,
                    "Battery low", d.model + " at " + root.pct(d) + "%"]);
            } else if (root.charging(d) || root.pct(d) > root.lowAt) {
                delete _notified[d.nativePath];
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
