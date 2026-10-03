pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Live weather from Open-Meteo, located once via ip-api, cached to disk.
Singleton {
    id: root

    readonly property string weatherDir: Globals.cacheDir + "/weather"

    property int temp: 0
    property bool ready: false

    property real lat: 0
    property real lon: 0
    property bool located: false

    readonly property int _refreshMs: 20 * 60 * 1000

    function fetch() {
        if (!root.located) {
            locate();
            return;
        }
        Runner.run(["curl", "-s", "--max-time", "10",
            "https://api.open-meteo.com/v1/forecast?latitude=" + root.lat
            + "&longitude=" + root.lon
            + "&current=temperature_2m"], function (out) {
            try {
                var cur = JSON.parse(out).current;
                if (!cur) return;
                root.temp = Math.round(cur.temperature_2m);
                root.ready = true;
                weatherCacheFile.setText(JSON.stringify({
                    temp: root.temp, ts: Date.now()
                }));
            } catch (e) {}
        });
    }

    function locate() {
        Runner.run(["curl", "-s", "--max-time", "8",
            "http://ip-api.com/json?fields=lat,lon"], function (out) {
            try {
                var d = JSON.parse(out);
                if (typeof d.lat !== "number" || typeof d.lon !== "number") return;
                root.lat = d.lat;
                root.lon = d.lon;
                root.located = true;
                locCacheFile.setText(JSON.stringify({ lat: root.lat, lon: root.lon }));
                root.fetch();
            } catch (e) {}
        });
    }

    function init() {
        Runner.run(["mkdir", "-p", root.weatherDir], null);
        try {
            var c = JSON.parse(locCacheFile.text());
            if (typeof c.lat === "number" && typeof c.lon === "number") {
                root.lat = c.lat;
                root.lon = c.lon;
                root.located = true;
            }
        } catch (e) {}
        try {
            var w = JSON.parse(weatherCacheFile.text());
            if (typeof w.temp === "number") {
                root.temp = w.temp;
                root.ready = true;
            }
        } catch (e) {}
        root.fetch();
    }

    Timer {
        interval: 0
        running: true
        repeat: false
        onTriggered: root.init()
    }

    Timer {
        interval: root._refreshMs
        running: true
        repeat: true
        onTriggered: root.fetch()
    }

    FileView {
        id: locCacheFile
        path: root.weatherDir + "/loc.json"
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: weatherCacheFile
        path: root.weatherDir + "/current.json"
        blockLoading: true
        printErrors: false
    }
}
