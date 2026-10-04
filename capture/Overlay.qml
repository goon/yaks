import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// One per screen. Freezes the screen, lets a region be dragged out, and grabs
// the result back out.
//
// The exporter is the clip: `exportRoot` is sized to the selection and offsets
// its child back onto the stage origin, so a grab of that one item is already
// the cropped PNG — no second pass through ImageMagick.
PanelWindow {
    id: overlay

    property var modelData
    screen: modelData

    // The Capture scope, reached through the Loader-style creation context
    // Variants gives this file.
    readonly property var host: root

    property rect sel: Qt.rect(0, 0, 0, 0)
    readonly property bool hasSelection: sel.width > 1 && sel.height > 1
    // the select phase is dimmed even with nothing selected yet, so it
    // reads as entered before the pointer moves
    readonly property bool dimmed: outlined || host.phase === "select"
    // nothing is committed until the pointer clears the drag threshold or the
    // button comes back up, so until then the hovered window is the preview;
    // once sel is committed it stays the preview for the rest of the run
    readonly property rect preview: (drag._active || hasSelection) ? sel : drag._hover
    readonly property bool outlined: preview.width > 1 && preview.height > 1
    readonly property color dim: Globals.alpha(Globals.colors.bg, 0.55)

    // windowRectsFor hands back plain JS objects with w/h, which QML cannot
    // coerce into a rect; every assignment to sel goes through this
    function _rect(o) {
        return Qt.rect(o.x, o.y, o.w, o.h);
    }

    function _rectOf(x1, y1, x2, y2) {
        return Qt.rect(Math.min(x1, x2), Math.min(y1, y2),
            Math.abs(x2 - x1), Math.abs(y2 - y1));
    }

    property bool _grabbing: false
    property bool _counted: false

    WlrLayershell.namespace: "yaks:screenshot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: host.phase === "idle"
        ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: host.phase !== "idle"

    Item {
        id: stage
        anchors.fill: parent

        // ── export surface ──────────────────────────────────────────────
        Item {
            id: exportRoot
            z: 0
            // Whole screen until a selection is committed, then exactly that
            // selection. Keyed on hasSelection rather than on the phase because
            // the grab happens while the phase is still "select".
            readonly property rect frame: overlay.hasSelection
                ? overlay.sel : Qt.rect(0, 0, overlay.width, overlay.height)
            x: frame.x
            y: frame.y
            width: frame.width
            height: frame.height
            clip: true

            Loader {
                id: frozenLoader
                active: false
                x: -exportRoot.x
                y: -exportRoot.y
                width: overlay.width
                height: overlay.height
                sourceComponent: Component {
                    ScreencopyView {
                        anchors.fill: parent
                        captureSource: overlay.modelData
                        live: false
                        paintCursor: false
                    }
                }
            }

            Timer {
                id: capTimer
                interval: 25
                repeat: true
                property int tries: 0

                onTriggered: {
                    const view = frozenLoader.item;
                    if (!view) return;
                    if (view.hasContent) {
                        capTimer.running = false;
                        host.reportReady(overlay);
                    } else if (capTimer.tries > 120) {
                        // ~3 s. Degrade to a black crop rather than hanging.
                        capTimer.running = false;
                        console.warn("[Capture] " + overlay.modelData.name + ": capture timed out");
                        host.reportReady(overlay);
                    } else {
                        capTimer.tries += 1;
                        view.captureFrame();
                    }
                }
            }
        }

        // ── dimming, outside the exporter so it never lands in the file ──
        // The top rect doubles as the pre-selection scrim: with nothing
        // selected it covers the whole window, so the select phase reads
        // as entered even before the pointer moves.
        Rectangle {
            z: 1
            x: 0
            y: 0
            width: overlay.width
            height: overlay.outlined ? Math.max(0, overlay.preview.y) : overlay.height
            visible: overlay.dimmed
            color: overlay.dim
        }
        Rectangle {
            z: 1
            x: 0
            y: overlay.preview.y + overlay.preview.height
            width: overlay.width
            height: Math.max(0, overlay.height - overlay.preview.y - overlay.preview.height)
            visible: overlay.outlined
            color: overlay.dim
        }
        Rectangle {
            z: 1
            x: 0
            y: overlay.preview.y
            width: Math.max(0, overlay.preview.x)
            height: overlay.preview.height
            visible: overlay.outlined
            color: overlay.dim
        }
        Rectangle {
            z: 1
            x: overlay.preview.x + overlay.preview.width
            y: overlay.preview.y
            width: Math.max(0, overlay.width - overlay.preview.x - overlay.preview.width)
            height: overlay.preview.height
            visible: overlay.outlined
            color: overlay.dim
        }

        // ── selection chrome ─────────────────────────────────────────────
        Rectangle {
            z: 2
            x: overlay.preview.x
            y: overlay.preview.y
            width: overlay.preview.width
            height: overlay.preview.height
            visible: overlay.outlined
            color: "transparent"
            border.width: Globals.geometry.borderWidth.thick
            border.color: Globals.colors.accentTop
        }

        // ── input ────────────────────────────────────────────────────────
        FocusScope {
            id: keys
            z: 3
            focus: true

            Keys.onPressed: function (event) {
                if (host.phase === "idle") return;

                if (event.key === Qt.Key_Escape) {
                    host.close();
                    event.accepted = true;
                    return;
                }

                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    overlay.sel = Qt.rect(0, 0, overlay.width, overlay.height);
                    host.finish(overlay);
                    event.accepted = true;
                }
            }
        }

        MouseArea {
            id: drag
            z: 3
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.CrossCursor

            hoverEnabled: true

            property point _origin: Qt.point(0, 0)
            property bool _active: false
            property bool _pressed: false
            // the hovered window, previewed before any press; once the drag
            // threshold is cleared the committed sel is it
            property rect _hover: Qt.rect(0, 0, 0, 0)
            // the window under the press, snapshotted so release never has to
            // re-hit-test a pointer that drifted a pixel
            property rect _pressWindow: Qt.rect(0, 0, 0, 0)
            readonly property int _dragThreshold: Globals.geometry.spacing.md

            onPressed: function (mouse) {
                if (mouse.button === Qt.RightButton) {
                    host.close();
                    return;
                }

                _origin = Qt.point(mouse.x, mouse.y);
                _pressed = true;
                _active = false;
                _pressWindow = _pressWindowAt(mouse.x, mouse.y);
            }

            onPositionChanged: function (mouse) {
                if (host.phase !== "select") return;
                if (!_active) {
                    if (!_pressed) {
                        _hover = _pressWindowAt(mouse.x, mouse.y);
                        return;
                    }
                    const dx = mouse.x - _origin.x;
                    const dy = mouse.y - _origin.y;
                    if (dx * dx + dy * dy < _dragThreshold * _dragThreshold)
                        return;
                    _active = true;
                    _hover = Qt.rect(0, 0, 0, 0);
                }
                overlay.sel = overlay._rectOf(_origin.x, _origin.y, mouse.x, mouse.y);
            }

            onReleased: function (mouse) {
                if (!_pressed) return;
                _pressed = false;

                if (_active) {
                    _active = false;
                    if (overlay.hasSelection) host.finish(overlay);
                    else host.close();
                    return;
                }

                // a click, not a drag: the window under it, else nothing
                if (_pressWindow.width > 1) {
                    overlay.sel = _pressWindow;
                    host.finish(overlay);
                } else {
                    host.close();
                }
            }

            function _pressWindowAt(x, y) {
                const hit = _pick(x, y);
                return hit ? overlay._rect(hit) : Qt.rect(0, 0, 0, 0);
            }

            function _pick(x, y) {
                const rects = host.windowRectsFor(overlay.modelData.name);
                for (let i = rects.length - 1; i >= 0; i--) {
                    const r = rects[i];
                    if (x >= r.x && x <= r.x + r.w && y >= r.y && y <= r.y + r.h) return r;
                }
                return null;
            }
        }
    }

    Connections {
        target: host

        function onBroadcastBegin() {
            sel = Qt.rect(0, 0, 0, 0);
            drag._hover = Qt.rect(0, 0, 0, 0);
            drag._pressWindow = Qt.rect(0, 0, 0, 0);
            drag._pressed = false;
            drag._active = false;
            _counted = false;
            _grabbing = false;
            // The window is already visible (phase flipped before the signal),
            // which is what lets the ScreencopyView receive the buffer. The view
            // is torn down on abort so the next capture cannot report a stale
            // `hasContent` and grab the wrong screen.
            frozenLoader.active = true;
            capTimer.tries = 0;
            capTimer.restart();
        }

        function onBroadcastAbort() {
            capTimer.stop();
            frozenLoader.active = false;
            sel = Qt.rect(0, 0, 0, 0);
            drag._hover = Qt.rect(0, 0, 0, 0);
            drag._pressWindow = Qt.rect(0, 0, 0, 0);
            drag._pressed = false;
            drag._active = false;
        }

        function onBroadcastEnter() {
            keys.forceActiveFocus();
        }
    }

    Component.onCompleted: host.registerOverlay(this)
    Component.onDestruction: host.unregisterOverlay(this)

    function grabAndSave(path, cb) {
        if (_grabbing) return;
        _grabbing = true;
        exportRoot.grabToImage(function (result) {
            overlay._grabbing = false;
            cb(result ? result.saveToFile(path) : false);
        });
    }
}