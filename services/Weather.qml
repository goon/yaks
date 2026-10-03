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
    property int code: 0
    property bool isDay: true
    property bool ready: false

    property real lat: 0
    property real lon: 0
    property bool located: false

    readonly property int _refreshMs: 20 * 60 * 1000

    function iconFor(code, day) {
        function cloudBase(c) {
            if (c === 45 || c === 48) return "fog";
            if (c >= 95) return "thunderstorms";
            if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "snow";
            if (c === 66 || c === 67 || c === 84) return "sleet";
            if (c >= 51 && c <= 57) return "drizzle";
            if ((c >= 61 && c <= 65) || (c >= 80 && c <= 82)) return "rain";
            if (c === 3) return "overcast";
            if (c >= 1) return "partly-cloudy";
            return "clear";
        }
        var base = cloudBase(code);
        var dayVariant = base === "clear" || base === "partly-cloudy" || base === "fog" || base === "thunderstorms";
        return dayVariant ? base + (day ? "-day" : "-night") : base;
    }

    function fetch() {
        if (!root.located) {
            locate();
            return;
        }
        Runner.run(["curl", "-s", "--max-time", "10",
            "https://api.open-meteo.com/v1/forecast?latitude=" + root.lat
            + "&longitude=" + root.lon
            + "&current=temperature_2m,weather_code,is_day"], function (out) {
            try {
                var cur = JSON.parse(out).current;
                if (!cur) return;
                root.temp = Math.round(cur.temperature_2m);
                root.code = cur.weather_code;
                root.isDay = cur.is_day === 1;
                root.ready = true;
                weatherCacheFile.setText(JSON.stringify({
                    temp: root.temp, code: root.code,
                    isDay: root.isDay, ts: Date.now()
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
            if (typeof w.code === "number") {
                root.temp = w.temp || 0;
                root.code = w.code;
                root.isDay = w.isDay !== false;
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
