import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs
pragma Singleton

Singleton {
    id: root

    property PwNode audioSink: Pipewire.defaultAudioSink
    property PwNode audioSource: Pipewire.defaultAudioSource
    property real volume: (audioSink && audioSink.audio) ? audioSink.audio.volume : 0
    property bool muted: (audioSink && audioSink.audio) ? audioSink.audio.muted : false
    property real inputVolume: (audioSource && audioSource.audio) ? audioSource.audio.volume : 0
    property bool inputMuted: (audioSource && audioSource.audio) ? audioSource.audio.muted : false
    readonly property string volumeIcon: {
        if (muted)
            return "volume_off";

        if (volume <= 0)
            return "volume_mute";

        if (volume < 0.6)
            return "volume_down";

        return "volume_up";
    }
    readonly property int volumePercent: Math.round(volume * 100)
    readonly property string inputVolumeIcon: inputMuted ? "mic_off" : "mic"
    readonly property int inputVolumePercent: Math.round(inputVolume * 100)
    property var unavailableNodes: []
    property var sinks: Pipewire.nodes.values.filter((node) => {
        return node.isSink && !node.isStream && node.audio && !unavailableNodes.includes(node.name);
    }).sort((a, b) => root.getNodeName(a).localeCompare(root.getNodeName(b)))
    property var sources: Pipewire.nodes.values.filter((node) => {
        return !node.isSink && !node.isStream && node.audio && !unavailableNodes.includes(node.name);
    }).sort((a, b) => root.getNodeName(a).localeCompare(root.getNodeName(b)))
    signal externalVolumeChanged()
    signal externalMuteChanged()

    function updateAvailability() {
        if (!availabilityProcess.running)
            availabilityProcess.running = true;
    }
    function getNodeName(node) {
        if (!node)
            return "Unknown";

        return node.nickname || node.properties["node.nick"] || node.description || node.properties["node.description"] || node.name || "Unknown";
    }

    function toggleMute() {
        if (audioSink && audioSink.audio)
            audioSink.audio.muted = !audioSink.audio.muted;

    }

    function setVolume(val) {
        if (audioSink && audioSink.audio) {
            audioSink.audio.muted = false;
            audioSink.audio.volume = val;
        }
    }

    function toggleInputMute() {
        if (audioSource && audioSource.audio)
            audioSource.audio.muted = !audioSource.audio.muted;

    }

    function setInputVolume(val) {
        if (audioSource && audioSource.audio) {
            audioSource.audio.muted = false;
            audioSource.audio.volume = val;
        }
    }

    function selectSink(id) {
        var node = Pipewire.nodes.values.find((n) => {
            return n.id === id;
        });
        if (node)
            Pipewire.preferredDefaultAudioSink = node;

    }

    function selectSource(id) {
        var node = Pipewire.nodes.values.find((n) => {
            return n.id === id;
        });
        if (node)
            Pipewire.preferredDefaultAudioSource = node;

    }

    Component.onCompleted: updateAvailability()

    // --- Process Management ---
    // Rule 1: NO persistent background subshells (leaks on reload)
    // Rule 2: Use transient processes triggered by native signals

    Process {
        // Rule 2: "Unknown" phantoms (S/PDIF, etc) on cards that have real "Available" ports
        // Rule 3: Contradictory roles (Monitor sinks on Microphones)

        id: availabilityProcess

        command: ["sh", "-c", "command -v pactl >/dev/null && pactl --format=json list || true"]
        running: false

        stdout: StdioCollector {
            onDataChanged: {
                if (!text)
                    return ;

                try {
                    var data = JSON.parse(text);
                    var cardsWithAvailableSinks = {
                    };
                    var cardsWithAvailableSources = {
                    };
                    // First pass: Identify "Available" hardware
                    if (data.sinks)
                        data.sinks.forEach((sink) => {
                        var props = sink.properties || {
                        };
                        var card = props["device.name"] || props["api.alsa.card"] || "unknown";
                        var activePort = sink.ports.find((p) => {
                            return p.name === sink.active_port;
                        });
                        if (activePort && activePort.availability === "available")
                            cardsWithAvailableSinks[card] = true;

                    });

                    if (data.sources)
                        data.sources.forEach((source) => {
                        var props = source.properties || {
                        };
                        var card = props["device.name"] || props["api.alsa.card"] || "unknown";
                        var activePort = source.ports.find((p) => {
                            return p.name === source.active_port;
                        });
                        if (activePort && activePort.availability === "available")
                            cardsWithAvailableSources[card] = true;

                    });

                    // Second pass: Filter phantoms
                    var unavailable = [];
                    if (data.sinks)
                        data.sinks.forEach((sink) => {
                        var props = sink.properties || {
                        };
                        var card = props["device.name"] || props["api.alsa.card"] || "unknown";
                        var formFactor = props["device.form_factor"] || "";
                        var activePort = sink.ports.find((p) => {
                            return p.name === sink.active_port;
                        });
                        var avail = activePort ? activePort.availability : "unknown";
                        // Rule 1: Explicitly not available
                        if (avail === "not available")
                            unavailable.push(sink.name);
                        else if (avail === "availability unknown" && cardsWithAvailableSinks[card])
                            unavailable.push(sink.name);
                        else if (avail === "availability unknown" && formFactor === "microphone")
                            unavailable.push(sink.name);
                    });

                    if (data.sources)
                        data.sources.forEach((source) => {
                        var props = source.properties || {
                        };
                        var card = props["device.name"] || props["api.alsa.card"] || "unknown";
                        var activePort = source.ports.find((p) => {
                            return p.name === source.active_port;
                        });
                        var avail = activePort ? activePort.availability : "unknown";
                        if (avail === "not available")
                            unavailable.push(source.name);
                        else if (avail === "availability unknown" && cardsWithAvailableSources[card])
                            unavailable.push(source.name);
                    });

                    root.unavailableNodes = unavailable;
                } catch (e) {
                    console.error("Failed to parse pactl output:", e);
                }
            }
        }

    }

    // --- Dynamic Triggers ---
    // Instead of a persistent subshell, we trigger updates based on 
    // native Pipewire signals or an occasional safety poll.
    
    property Timer availabilityDebounce: Timer {
        interval: 500
        repeat: false
        onTriggered: updateAvailability()
    }

    Connections {
        target: Pipewire.nodes
        function onValuesChanged() { availabilityDebounce.restart(); }
    }

    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() { availabilityDebounce.restart(); }
        function onDefaultAudioSourceChanged() { availabilityDebounce.restart(); }
    }

    // Safety poll (e.g. for card profile changes that don't trigger PW node values)
    property Timer safetyPoll: Timer {
        interval: 30000 // 30s is plenty for a safety net
        running: true
        repeat: true
        onTriggered: updateAvailability()
    }

    // --- Core Pipewire Tracker ---
    // Ensures we subscribe to changes for nodes/meta/etc.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSource, Pipewire.defaultAudioSink, Pipewire.nodes, Pipewire.links]
    }

}
