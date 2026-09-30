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
    property string pendingPath: ""
    property real progress: 0
    property real discCenterX: 0.5
    property real discCenterY: 0.5
    property bool transitionPending: false

    readonly property int transitionDurationMs:
        Math.max(100, Math.round(Preferences.wallpaper.transitionDuration))

    readonly property bool transitioning: transitionAnim.running

    // ── LOGIC ──────────────────────────────────────────────────────────

    function updateWallpaper(newPath) {
        if (!newPath || newPath === "" || newPath === activePath || newPath === pendingPath) return;

        if (activePath === "" && String(loaderA.source).length === 0) {
            activePath = newPath;
            loaderA.source = "file://" + newPath;
            return;
        }

        pendingPath = newPath;
        transitionPending = true;
        loaderB.source = "file://" + newPath;

        if (loaderB.status === Image.Ready) {
            startTransition();
        }
    }

    function startTransition() {
        if (!transitionPending || pendingPath === "") return;
        if (loaderA.status !== Image.Ready || loaderB.status !== Image.Ready) return;

        discCenterX = 0.2 + Math.random() * 0.6;
        discCenterY = 0.2 + Math.random() * 0.6;
        progress = 0;

        if (transitionAnim.running) {
            transitionAnim.stop();
            commitSwap();
            loaderB.source = "file://" + pendingPath;
            if (loaderB.status !== Image.Ready) return;
        }

        transitionPending = false;
        transitionAnim.start();
    }

    function commitSwap() {
        loaderA.source = loaderB.source;
        loaderB.source = "";
        activePath = pendingPath;
        pendingPath = "";
        progress = 0;
    }

    // ── CONNECTIONS ────────────────────────────────────────────────────

    Connections {
        target: Wallpaper
        function onDisplayWallpaperChanged() {
            root.updateWallpaper(Wallpaper.displayWallpaper);
        }
    }

    Component.onCompleted: {
        if (Wallpaper.displayWallpaper !== "") {
            loaderA.source = "file://" + Wallpaper.displayWallpaper;
            activePath = Wallpaper.displayWallpaper;
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

    // ── TEXTURE PROVIDERS ──────────────────────────────────────────────

    Image {
        id: loaderA
        anchors.fill: parent
        visible: true
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }

    Image {
        id: loaderB
        anchors.fill: parent
        visible: true
        opacity: 0
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true

        onStatusChanged: if (status === Image.Ready) root.startTransition()
    }

    // ── TRANSITION CANVAS ──────────────────────────────────────────────

    Canvas {
        id: transitionCanvas
        anchors.fill: parent
        visible: root.transitioning
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            var ctx = getContext("2d");
            ctx.save();
            ctx.clearRect(0, 0, width, height);

            // Bail if loaderB isn't ready yet (canvas paints can fire
            // before the new image finishes decoding).
            if (loaderB.status !== Image.Ready) {
                ctx.restore();
                return;
            }

            var imgW = loaderB.sourceSize.width;
            var imgH = loaderB.sourceSize.height;
            if (imgW <= 0 || imgH <= 0) {
                ctx.restore();
                return;
            }
            var scale = Math.max(width / imgW, height / imgH);
            var drawW = imgW * scale;
            var drawH = imgH * scale;
            var drawX = (width - drawW) * 0.5;
            var drawY = (height - drawH) * 0.5;

            // Expanding disc centred on a random point in the screen.
            var r = Math.hypot(width, height) * root.progress;
            ctx.beginPath();
            ctx.arc(width * root.discCenterX, height * root.discCenterY, r, 0, 2 * Math.PI);
            ctx.clip();

            ctx.drawImage(loaderB, drawX, drawY, drawW, drawH);
            ctx.restore();
        }

        // Repaint every time `progress` ticks, and on size changes.
        Connections {
            target: root
            function onProgressChanged() { transitionCanvas.requestPaint() }
            function onDiscCenterXChanged() { transitionCanvas.requestPaint() }
            function onDiscCenterYChanged() { transitionCanvas.requestPaint() }
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    // ── TRANSITION ANIMATION ──────────────────────────────────────────
    NumberAnimation {
        id: transitionAnim
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: root.transitionDurationMs
        easing.type: Easing.InOutCubic
        onStarted: transitionCanvas.requestPaint()
        onFinished: root.commitSwap()
    }
}
