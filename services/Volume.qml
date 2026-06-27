import QtQuick
import Quickshell
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
    property var sinks: Pipewire.nodes.values.filter((node) => {
        return node.isSink && !node.isStream && node.audio;
    }).sort((a, b) => root.getNodeName(a).localeCompare(root.getNodeName(b)))
    property var sources: Pipewire.nodes.values.filter((node) => {
        return !node.isSink && !node.isStream && node.audio;
    }).sort((a, b) => root.getNodeName(a).localeCompare(root.getNodeName(b)))

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

    // ── CORE PIPEWIRE TRACKER ───────────────────────────────────────
    // Ensures we subscribe to changes for nodes/meta/etc.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSource, Pipewire.defaultAudioSink, Pipewire.nodes, Pipewire.links]
    }

}
