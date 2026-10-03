pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Live weather from Open-Meteo, located once via ip-api, cached to disk.
// A user-typed city overrides the ip-api location until it is cleared again.
Singleton {
    id: root

    readonly property string weatherDir: Globals.cacheDir + "/weather"

    property int temp: 0
    property int code: -1
    property bool ready: false

    // [{ date: "YYYY-MM-DD", code, tMax, tMin }]
    property var daily: []

    property real lat: 0
    property real lon: 0
    property string city: ""
    // Non-empty when the user picked a city; empty means ip-api owns the location.
    property string place: ""
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
            + "&current=temperature_2m,weather_code"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
            + "&timezone=auto&forecast_days=5"], function (out) {
            try {
                var d = JSON.parse(out);
                if (!d.current) return;
                root.temp = Math.round(d.current.temperature_2m);
                root.code = d.current.weather_code;
                root.daily = _parseDaily(d.daily);
                root.ready = true;
                weatherCacheFile.setText(JSON.stringify({
                    temp: root.temp, code: root.code, daily: root.daily, ts: Date.now()
                }));
            } catch (e) {}
        });
    }

    function _parseDaily(d) {
        if (!d || !d.time) return [];
        var out = [];
        for (var i = 0; i < d.time.length; i++) {
            out.push({
                date: d.time[i],
                code: d.weather_code[i],
                tMax: Math.round(d.temperature_2m_max[i]),
                tMin: Math.round(d.temperature_2m_min[i])
            });
        }
        return out;
    }

    function locate() {
        Runner.run(["curl", "-s", "--max-time", "8",
            "http://ip-api.com/json?fields=lat,lon,city"], function (out) {
            try {
                var d = JSON.parse(out);
                if (typeof d.lat !== "number" || typeof d.lon !== "number") return;
                root.lat = d.lat;
                root.lon = d.lon;
                root.city = d.city || "";
                root.place = "";
                root.located = true;
                locCacheFile.setText(JSON.stringify({
                    lat: root.lat, lon: root.lon, city: root.city, place: ""
                }));
                root.fetch();
            } catch (e) {}
        });
    }

    // Empty hands the location back to ip-api; anything else geocodes.
    function setLocation(name) {
        var q = (name || "").trim();
        if (q === "") {
            root.place = "";
            root.located = false;
            locate();
            return;
        }
        Runner.run(["curl", "-s", "--max-time", "8",
            "https://geocoding-api.open-meteo.com/v1/search?count=1&name="
            + encodeURIComponent(q)], function (out) {
            try {
                var r = (JSON.parse(out).results || [])[0];
                if (!r) {
                    Runner.runDetached(["notify-send", "Weather",
                        "No place named '" + q + "'"]);
                    return;
                }
                root.lat = r.latitude;
                root.lon = r.longitude;
                root.city = r.name;
                root.place = q;
                root.located = true;
                root.daily = [];
                locCacheFile.setText(JSON.stringify({
                    lat: root.lat, lon: root.lon, city: root.city, place: q
                }));
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
                root.city = c.city || "";
                root.place = c.place || "";
                root.located = true;
            }
        } catch (e) {}
        try {
            var w = JSON.parse(weatherCacheFile.text());
            if (typeof w.temp === "number") {
                root.temp = w.temp;
                root.ready = true;
                root.code = typeof w.code === "number" ? w.code : -1;
                if (w.daily) root.daily = w.daily;
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