pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

QtObject {
    id: root

    // --- CPU Statistics ---
    property real currentCpu: 0
    property real currentTemp: 0
    property string cpuTempPath: ""
    property var _lastCpu: null
    
    // --- RAM Statistics ---
    property real currentRam: 0
    property real memTotalSize: 0
    property string totalRam: formatBytes(memTotalSize * 1024)
    property real memUsedSize: 0

    // --- GPU Statistics ---
    property real currentGpu: 0
    property real currentGpuTemp: 0
    property string gpuTempPath: ""
    property string gpuLoadPath: ""

    // --- Network Statistics ---
    property real currentNetworkRx: 0
    property real currentNetworkTx: 0
    property var networkRxHistory: Array(31).fill(0)
    property var networkTxHistory: Array(31).fill(0)
    property var _lastNet: null

    // --- File Readers ---
    property FileView cpuFile: FileView { path: "/proc/stat" }
    property FileView memFile: FileView { path: "/proc/meminfo" }
    property FileView netFile: FileView { path: "/proc/net/dev" }
    property FileView cpuTempFile: FileView { path: root.cpuTempPath || "/sys/class/thermal/thermal_zone0/temp" }
    property FileView gpuTempFile: FileView { path: root.gpuTempPath }
    property FileView gpuLoadFile: FileView { path: root.gpuLoadPath }

    Component.onCompleted: {
        ProcessService.run(["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do if [ -f \"$h/name\" ] && grep -q \"amdgpu\" \"$h/name\"; then echo \"$h/temp1_input\"; break; fi; done"], function(path) {
            if (path && path.trim()) {
                gpuTempPath = path.trim();
                ProcessService.run(["sh", "-c", "if [ -f \"" + gpuTempPath.replace("temp1_input", "device/gpu_busy_percent") + "\" ]; then echo \"" + gpuTempPath.replace("temp1_input", "device/gpu_busy_percent") + "\"; elif [ -f \"" + gpuTempPath.replace("temp1_input", "gpu_busy_percent") + "\" ]; then echo \"" + gpuTempPath.replace("temp1_input", "gpu_busy_percent") + "\"; fi"], function(loadPath) {
                    if (loadPath && loadPath.trim()) gpuLoadPath = loadPath.trim();
                });
            }
        });

        ProcessService.run(["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do if [ -f \"$h/name\" ]; then name=$(cat \"$h/name\"); if [ \"$name\" = \"coretemp\" ] || [ \"$name\" = \"k10temp\" ]; then for t in \"$h\"/temp*_input; do if [ -f \"$t\" ]; then label_file=\"${t%_input}_label\"; if [ ! -f \"$label_file\" ] || grep -qiE \"package|die|tctl\" \"$label_file\"; then echo \"$t\"; exit 0; fi; fi; done; fi; fi; done; for t in /sys/class/thermal/thermal_zone*; do if [ -f \"$t/type\" ] && grep -qiE \"x86_pkg_temp|cpu|pkg\" \"$t/type\"; then echo \"$t/temp\"; exit 0; fi; done; echo \"/sys/class/thermal/thermal_zone0/temp\""], function(path) {
            if (path && path.trim()) {
                cpuTempPath = path.trim();
            }
        });
    }

    function parseCpu(data) {
        if (!data) return;
        var lines = data.split("\n");
        if (lines.length === 0) return;
        
        var firstLine = lines[0].trim();
        if (!firstLine.startsWith("cpu ")) return;
        
        var parts = firstLine.split(/\s+/);
        if (parts.length < 5) return;
        
        var idle = parseInt(parts[4]);
        var total = 0;
        for (var i = 1; i < parts.length; i++) {
            total += parseInt(parts[i] || 0);
        }

        if (_lastCpu) {
            var diffIdle = idle - _lastCpu.idle;
            var diffTotal = total - _lastCpu.total;
            var usage = diffTotal > 0 ? (1 - (diffIdle / diffTotal)) : 0;
            currentCpu = usage;
        }

        _lastCpu = { idle: idle, total: total };
    }

    function parseMem(data) {
        if (!data) return;
        var lines = data.split("\n");
        var total = 0, free = 0, cached = 0, buffers = 0, sReclaimable = 0;
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];
            var parts = line.split(/\s+/);
            if (parts.length < 2) continue;
            if (line.startsWith("MemTotal:")) total = parseInt(parts[1]);
            else if (line.startsWith("MemFree:")) free = parseInt(parts[1]);
            else if (line.startsWith("Cached:")) cached = parseInt(parts[1]);
            else if (line.startsWith("Buffers:")) buffers = parseInt(parts[1]);
            else if (line.startsWith("SReclaimable:")) sReclaimable = parseInt(parts[1]);
        }
        memTotalSize = total;
        memUsedSize = total - free - cached - buffers - sReclaimable;
        currentRam = total > 0 ? (memUsedSize / total) : 0;
    }

    function parseTemp(data) {
        if (!data) return;
        currentTemp = Math.round(parseInt(data.trim()) / 1000);
    }

    function parseNet(data) {
        if (!data) return;
        var lines = data.split("\n");
        var down = 0, up = 0;
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            var colonIndex = line.indexOf(":");
            if (colonIndex === -1) continue;
            
            var interfaceName = line.substring(0, colonIndex).trim();
            if (interfaceName === "lo" || interfaceName.startsWith("vbox") || interfaceName.startsWith("virbr") || interfaceName.startsWith("docker")) continue;
            
            var statsPart = line.substring(colonIndex + 1).trim();
            var parts = statsPart.split(/\s+/);
            if (parts.length >= 9) {
                down += parseInt(parts[0]) || 0;
                up += parseInt(parts[8]) || 0;
            }
        }

        if (_lastNet) {
            var interval = Math.max(0.1, pollTimer.interval / 1000);
            currentNetworkRx = (down - _lastNet.down) / interval;
            currentNetworkTx = (up - _lastNet.up) / interval;
            
            var newRxHistory = networkRxHistory.concat([currentNetworkRx]);
            if (newRxHistory.length > 30) newRxHistory.shift();
            networkRxHistory = newRxHistory;

            var newTxHistory = networkTxHistory.concat([currentNetworkTx]);
            if (newTxHistory.length > 30) newTxHistory.shift();
            networkTxHistory = newTxHistory;
        }
        _lastNet = { down: down, up: up };
    }

    function formatBytes(bytes) {
        if (isNaN(bytes) || bytes === 0) return "0 B";
        var k = 1024;
        var sizes = ["B", "KB", "MB", "GB", "TB", "PB"];
        var i = Math.floor(Math.log(Math.abs(bytes)) / Math.log(k));
        if (i < 0) i = 0;
        if (i >= sizes.length) i = sizes.length - 1;
        
        var val = bytes / Math.pow(k, i);
        if (sizes[i] === "TB" || sizes[i] === "PB") {
            return val.toFixed(1) + " " + sizes[i];
        } else {
            return Math.ceil(val) + " " + sizes[i];
        }
    }

    function parseAmdTemp(data) {
        if (!data) return;
        currentGpuTemp = Math.round(parseInt(data.trim()) / 1000);
    }

    function parseAmdLoad(data) {
        if (!data) return;
        currentGpu = (parseInt(data.trim()) || 0) / 100;
    }

    function updateFast() {
        cpuFile.reload();
        memFile.reload();
        cpuTempFile.reload();
        netFile.reload();
        
        parseCpu(cpuFile.text());
        parseMem(memFile.text());
        parseTemp(cpuTempFile.text());
        parseNet(netFile.text());
        
        if (root.gpuTempPath) {
            gpuTempFile.reload();
            parseAmdTemp(gpuTempFile.text());
        }
        
        if (root.gpuLoadPath) {
            gpuLoadFile.reload();
            parseAmdLoad(gpuLoadFile.text());
        }
    }

    property Timer pollTimer: Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateFast()
    }
}