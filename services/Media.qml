import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs
pragma Singleton

QtObject {
    // Optional: Resync if drift is too large, but Mpris position assumes static unless updated. This seems fine actually?
    // We rely on signal handlers for resync.

    id: root

    // Active player (filtered to exclude browsers)
    property var activePlayer: null
    property var metadata: activePlayer && activePlayer.metadata ? activePlayer.metadata : null
    property string trackTitle: metadata ? (metadata["xesam:title"] || "Unknown Track") : "Unknown Track"
    property var artistArray: metadata ? metadata["xesam:artist"] : null
    property string trackArtist: artistArray && artistArray.length > 0 ? artistArray[0] : "Unknown Artist"
    property string albumArtUrl: metadata ? (metadata["mpris:artUrl"] || "") : ""
    property real trackLength: metadata ? (metadata["mpris:length"] || 0) : 0
    property real currentPosition: activePlayer ? activePlayer.position : 0
    property int playbackState: activePlayer ? activePlayer.playbackState : MprisPlaybackState.Stopped
    property bool canPlay: activePlayer ? activePlayer.canPlay : false
    property bool canPause: activePlayer ? activePlayer.canPause : false
    property bool canGoNext: activePlayer ? activePlayer.canGoNext : false
    property bool canGoPrevious: activePlayer ? activePlayer.canGoPrevious : false
    property bool canSeek: activePlayer ? activePlayer.canSeek : false
    property bool isSeeking: false
    property real localSeekRatio: -1
    property real lastSentSeekRatio: -1
    property real seekEpsilon: 0.01
    property real progressRatio: {
        if (!activePlayer || trackLength <= 0)
            return 0;

        var r = (currentPosition * 1e+06) / trackLength;
        if (isNaN(r) || !isFinite(r))
            return 0;

        return Math.max(0, Math.min(1, r));
    }
    readonly property var browserIdentities: ["firefox", "chrome", "chromium", "brave", "edge", "opera", "vivaldi", "safari"]
    property Timer positionTimer
    property Timer seekDebounceTimer
    property Connections playerConnections

    playerConnections: Connections {
        function onPositionChanged() {
            if (!root.isSeeking && root.activePlayer)
                root.currentPosition = root.activePlayer.position;

        }

        target: root.activePlayer
    }

    function updateActivePlayer() {
        for (var i = 0; i < Mpris.players.values.length; i++) {
            var p = Mpris.players.values[i];
            var identity = (p.identity || "").toLowerCase();
            var isBrowser = false;
            for (var j = 0; j < browserIdentities.length; j++) {
                if (identity.includes(browserIdentities[j])) {
                    isBrowser = true;
                    break;
                }
            }
            if (!isBrowser) {
                activePlayer = p;
                return ;
            }
        }
        activePlayer = null;
    }

    function play() {
        if (activePlayer && canPlay)
            activePlayer.play();

    }

    function pause() {
        if (activePlayer && canPause)
            activePlayer.pause();

    }

    function togglePlayPause() {
        if (!activePlayer)
            return ;

        if (playbackState === MprisPlaybackState.Playing)
            pause();
        else
            play();
    }

    function next() {
        if (activePlayer && canGoNext)
            activePlayer.next();

    }

    function previous() {
        if (activePlayer && canGoPrevious)
            activePlayer.previous();

    }

    function seek(microseconds) {
        if (activePlayer && canSeek)
            activePlayer.position = microseconds / 1e+06;

    }



    function resetPosition() {
        currentPosition = 0;
        isSeeking = false;
        localSeekRatio = -1;
        lastSentSeekRatio = -1;
        if (activePlayer)
            currentPosition = activePlayer.position;

    }

    onTrackTitleChanged: resetPosition()
    onTrackArtistChanged: resetPosition()
    onTrackLengthChanged: resetPosition()
    onActivePlayerChanged: {
        if (activePlayer)
            currentPosition = activePlayer.position;

    }
    Component.onCompleted: {
        updateActivePlayer();
        Mpris.players.valuesChanged.connect(updateActivePlayer);
    }
    Component.onDestruction: {
        if (positionTimer)
            positionTimer.stop();

        if (seekDebounceTimer)
            seekDebounceTimer.stop();

    }


    property var _lastUpdateTime: 0
    positionTimer: Timer {
        interval: 16 // ~60fps for perfectly smooth progress
        running: root.activePlayer && root.playbackState === MprisPlaybackState.Playing && !root.isSeeking
        repeat: true
        onTriggered: {
            var now = new Date().getTime();
            if (root._lastUpdateTime > 0) {
                var delta = (now - root._lastUpdateTime) / 1000;
                root.currentPosition += delta;
            }
            root._lastUpdateTime = now;
        }
        onRunningChanged: {
            if (running) root._lastUpdateTime = new Date().getTime();
            else root._lastUpdateTime = 0;
        }
    }

    seekDebounceTimer: Timer {
        interval: 75
        repeat: false
        onTriggered: {
            if (root.isSeeking && root.localSeekRatio >= 0 && root.activePlayer) {
                var next = Math.max(0, Math.min(1, root.localSeekRatio));
                if (root.lastSentSeekRatio < 0 || Math.abs(next - root.lastSentSeekRatio) >= root.seekEpsilon) {
                    var microseconds = next * root.trackLength;
                    root.activePlayer.position = microseconds / 1e+06;
                    root.lastSentSeekRatio = next;
                }
            }
        }
    }

}
