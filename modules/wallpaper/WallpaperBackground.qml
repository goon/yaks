import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
    id: root

    // ── CONFIGURATION ──────────────────────────────────────────────────
    property string namespace: "yaks:wallpaper"
    property int exclusiveZone: -1

    readonly property var transitionModes: ["fade", "disc", "corner", "wave"]

    // ── MOTION ─────────────────────────────────────────────────────────
    readonly property int _parallaxFadeOutMs: 200
    readonly property int _parallaxFadeInMs: 450

    // ── STATE ──────────────────────────────────────────────────────────
    property string activePath: ""
    property string pendingPath: ""
    property string activeTransition: "fade"
    property real progress: 0
    property real cornerDir: 0
    property real discCenterX: 0.5
    property real discCenterY: 0.5
    property bool transitionPending: false

    readonly property int transitionDurationMs:
        Math.max(100, Math.round(Preferences.wallpaper.transitionDuration))

    readonly property bool transitioning: transitionAnim.running

    // ── LOGIC ──────────────────────────────────────────────────────────

    function resolveTransitionMode() {
        var configured = Preferences.wallpaper.transition;
        if (configured === "random") {
            return transitionModes[Math.floor(Math.random() * transitionModes.length)];
        }
        return transitionModes.includes(configured) ? configured : "fade";
    }

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

        activeTransition = resolveTransitionMode();
        cornerDir = Math.floor(Math.random() * 4);
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
        parallaxFadeOut.start();
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
    color: Globals.colors.background

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        top: (Preferences.bar.position === "top") ? -(Preferences.bar.height + Preferences.bar.marginTop) : 0
        bottom: (Preferences.bar.position === "bottom") ? -(Preferences.bar.height + Preferences.bar.marginTop) : 0
    }

    // ── PARALLAX + TEXTURE PROVIDERS ──────────────────────────────────

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    Item {
        id: parallaxContainer

        readonly property real strength: Preferences.wallpaper.parallaxStrength
        property real parallaxScale: 1.0

        x: -currentOffsetX
        y: -currentOffsetY
        width: root.width + (2 * strength)
        height: root.height + (2 * strength)

        readonly property real currentOffsetX: (mouseArea.containsMouse && strength > 0 && parallaxScale > 0.001)
            ? (mouseArea.mouseX / Math.max(1, root.width)) * 2 * strength * parallaxScale
            : strength * parallaxScale

        readonly property real currentOffsetY: (mouseArea.containsMouse && strength > 0 && parallaxScale > 0.001)
            ? (mouseArea.mouseY / Math.max(1, root.height)) * 2 * strength * parallaxScale
            : strength * parallaxScale

        NumberAnimation {
            id: parallaxFadeOut
            target: parallaxContainer
            property: "parallaxScale"
            to: 0
            duration: root._parallaxFadeOutMs
            easing.type: Globals.motion.easeStandard
        }

        NumberAnimation {
            id: parallaxFadeIn
            target: parallaxContainer
            property: "parallaxScale"
            to: 1
            duration: root._parallaxFadeInMs
            easing.type: Globals.motion.easeStandard
        }

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

        // ── TRANSITION CANVAS ─────────────────────────────────────────

        Canvas {
            id: transitionCanvas
            anchors.fill: parent
            visible: root.transitioning
            opacity: root.activeTransition === "fade" ? root.progress : 1.0
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

                if (root.activeTransition !== "fade") {
                    ctx.beginPath();

                    if (root.activeTransition === "disc") {
                        var r = Math.hypot(width, height) * root.progress;
                        ctx.arc(width * root.discCenterX, height * root.discCenterY, r, 0, 2 * Math.PI);
                    } else {
                        var corner;
                        if (root.cornerDir < 0.5) corner = [0, 0];
                        else if (root.cornerDir < 1.5) corner = [width, 0];
                        else if (root.cornerDir < 2.5) corner = [0, height];
                        else corner = [width, height];

                        var oppX = width - corner[0];
                        var oppY = height - corner[1];
                        var perpX = -oppY;
                        var perpY = oppX;
                        var L = Math.hypot(width, height) * 1.5;

                        ctx.moveTo(corner[0], corner[1]);
                        ctx.lineTo(corner[0] + perpX * L, corner[1] + perpY * L);

                        if (root.activeTransition === "wave") {
                            var steps = 80;
                            var diagLen = Math.hypot(oppX, oppY);
                            for (var i = 1; i <= steps; i++) {
                                var u = i / steps - 0.5;
                                var phase = Math.sin(u * 14) * 0.05 * diagLen;
                                var t = Math.max(0, Math.min(1, root.progress + phase / diagLen));
                                var fx = corner[0] + oppX * t;
                                var fy = corner[1] + oppY * t;
                                var px = fx + perpX * u * L;
                                var py = fy + perpY * u * L;
                                ctx.lineTo(px, py);
                            }
                        } else {
                            var tc = root.progress;
                            var fx = corner[0] + oppX * tc;
                            var fy = corner[1] + oppY * tc;
                            ctx.lineTo(fx + perpX * L, fy + perpY * L);
                            ctx.lineTo(fx - perpX * L, fy - perpY * L);
                        }

                        ctx.lineTo(corner[0] - perpX * L, corner[1] - perpY * L);
                        ctx.closePath();
                    }

                    ctx.clip();
                }

                ctx.drawImage(loaderB, drawX, drawY, drawW, drawH);
                ctx.restore();
            }

            // Repaint every time `progress` ticks, and on size changes.
            Connections {
                target: root
                function onProgressChanged() { transitionCanvas.requestPaint() }
                function onActiveTransitionChanged() { transitionCanvas.requestPaint() }
                function onCornerDirChanged() { transitionCanvas.requestPaint() }
                function onDiscCenterXChanged() { transitionCanvas.requestPaint() }
                function onDiscCenterYChanged() { transitionCanvas.requestPaint() }
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }
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
        onFinished: {
            root.commitSwap();
            parallaxFadeIn.start();
        }
    }
}
