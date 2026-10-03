import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
    id: root

    // ── CONFIGURATION ──────────────────────────────────────────────────
    property string namespace: "yaks:wallpaper"
    property int exclusiveZone: -1

    // ── STATE ──────────────────────────────────────────────────────────
    property string activePath: ""

    // ── LOGIC ──────────────────────────────────────────────────────────
    //
    // This window is only the backdrop. One texture, pointed at whatever the
    // wallpaper is *now* — the visible change happens in WallpaperTransition.qml,
    // which freezes the whole desktop and wipes to the new image. Nothing here
    // animates: by the time the wipe finishes this is already showing the
    // wallpaper being revealed.

    function updateWallpaper(newPath) {
        if (!newPath || newPath === activePath) return;
        activePath = newPath;
        loader.source = "file://" + newPath;
    }

    // ── CONNECTIONS ────────────────────────────────────────────────────

    Connections {
        target: Wallpaper
        function onCurrentWallpaperChanged() {
            // Hold the source swap during a transition: WallpaperTransition
            // commits it via pendingCommitted at wipe start, fully hidden under
            // the overlay's progress=0 fully-opaque frame.
            if (!Wallpaper._transitionPending) {
                root.updateWallpaper(Wallpaper.currentWallpaper);
            }
        }
        function onPendingCommitted(path) {
            root.updateWallpaper(path);
        }
    }

    Component.onCompleted: {
        if (Wallpaper.currentWallpaper !== "") {
            loader.source = "file://" + Wallpaper.currentWallpaper;
            activePath = Wallpaper.currentWallpaper;
        }
    }

    // ── LAYOUT SHELL CONFIG ────────────────────────────────────────────
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: root.namespace
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: root.exclusiveZone
    visible: true
    color: Globals.colors.bg

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        top: (Preferences.bar.position === "top") ? -Preferences.bar.reservedZone : 0
        bottom: (Preferences.bar.position === "bottom") ? -Preferences.bar.reservedZone : 0
    }

    // ── TEXTURE ────────────────────────────────────────────────────────

    Image {
        id: loader
        anchors.fill: parent
        visible: true
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }
}
