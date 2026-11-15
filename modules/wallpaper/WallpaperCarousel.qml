import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs

FocusScope {
    id: root

    property var model: Wallpaper.wallpapers
    readonly property int currentIndex: model.length > 0
        ? ((focusIndex % model.length) + model.length) % model.length
        : 0
    property real s: 1.3
    signal closeRequested()

    property int focusIndex: 0
    property real pos: 0

    readonly property int preloadRadius: 5

    readonly property var slotW:      [196, 126, 104, 88, 74]
    readonly property var slotH:      [110, 71, 59, 50, 42]
    readonly property var slotCX:     [0, 143, 244, 326, 393]
    readonly property var slotBright: [1.00, 0.56, 0.42, 0.30, 0.22]
    readonly property var slotSat:    [1.00, 0.65, 0.55, 0.45, 0.40]

    readonly property int contentPadding: 11
    readonly property int edgeFadeWidth: contentPadding

    readonly property int footerH: 34 * Globals.shellScale

    readonly property bool editingDirectory: dirInput.activeFocus
    property bool directoryOpen: false

    // Directory is edited through the field itself, not a live binding: every change
    // to Preferences.wallpaper.directory kicks off a full rescan (find +
    // thumbnailer.sh), so it only fires on editingFinished (Return or focus loss).
    function commitDirectory() {
        // Assigning rescan kicks off refreshWallpapers(). Empty is a valid value
        // (the settings page shows a warning and disables the gallery), and a
        // same-value assign is a no-op, so Return's double-commit is harmless.
        // An empty field never commits: the field can be empty while it is still
        // being seeded from a not-yet-loaded Preferences, and writing that would
        // wipe a directory the user never touched.
        if (dirInput.text.trim().length > 0)
            Preferences.wallpaper.directory = dirInput.text;
        root.directoryOpen = false;
    }

    // Field is visible on its own while the gallery is empty; with wallpapers it
    // only appears when the counter is clicked.
    function editDirectory() {
        syncDirectory();
        root.directoryOpen = true;
        Qt.callLater(function() {
            dirInput.forceActiveFocus();
            dirInput.selectAll();
        });
    }

    readonly property real naturalWidth: 2 * (slotCX[2] + slotW[2] / 2) * s + 2 * contentPadding
    readonly property real naturalHeight: slotH[0] * s + 2 * contentPadding + footerH

    function slotLerp(arr, ao) {
        if (ao >= arr.length - 1)
            return arr[arr.length - 1];
        var i = Math.floor(ao);
        var f = ao - i;
        return arr[i] + (arr[i + 1] - arr[i]) * f;
    }

    function offsetX(off) {
        var ao = Math.abs(off);
        var last = slotCX.length - 1;
        var cx = ao <= last
            ? slotLerp(slotCX, ao)
            : slotCX[last] + (ao - last) * 60;
        return (off < 0 ? -cx : cx) * s;
    }

    function move(delta) {
        var n = model.length;
        if (n === 0)
            return;
        focusIndex += delta;
        var shift = Math.floor(focusIndex / n) * n;
        if (shift !== 0) {
            focusIndex -= shift;
            pos -= shift;
        }
    }

    function focusFirst() {
        if (!model || model.length === 0)
            return;
        focusIndex = 0;
        pos = 0;
    }

    // Called by the module on Opening; also the one place the directory field is
    // seeded, so it picks up changes made elsewhere (settings page) between opens.
    function syncDirectory() {
        dirInput.text = Preferences.wallpaper.directory;
    }

    onModelChanged: focusFirst()

    focus: true
    clip: true

    FrameAnimation {
        running: root.pos !== root.focusIndex
        onTriggered: {
            var k = 1 - Math.exp(-frameTime / 0.07);
            var next = root.pos + (root.focusIndex - root.pos) * k;
            root.pos = Math.abs(next - root.focusIndex) < 0.001 ? root.focusIndex : next;
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        z: -1
    }

    Repeater {
        model: root.model

        delegate: Item {
            id: tile
            required property int index
            required property var modelData

            readonly property real off: {
                var raw = index - root.pos;
                return raw - root.model.length * Math.round(raw / root.model.length);
            }
            readonly property real ao: Math.abs(off)
            readonly property bool focused: index === root.currentIndex
            readonly property real bright: root.slotLerp(root.slotBright, ao)
            readonly property real sat:    root.slotLerp(root.slotSat, ao)
            readonly property real corner:  (8 + 2 * Math.max(0, 1 - ao)) * root.s
            readonly property real edgeFade: {
                var gap = Math.min(x, root.width - (x + width));
                return Math.max(0, Math.min(1, gap / root.edgeFadeWidth));
            }

            readonly property string thumbSource: "file://" + modelData.thumb + "?v=" + Math.round(modelData.mtime)

            function apply() {
                if (root.model && root.currentIndex >= 0 && root.currentIndex < root.model.length) {
                    Wallpaper.setWallpaper(root.model[root.currentIndex].path);
                }
            }

            width:  root.slotLerp(root.slotW, ao) * root.s
            height: root.slotLerp(root.slotH, ao) * root.s
            x: root.width / 2 + root.offsetX(off) - width / 2
            y: (root.height - root.footerH - height) / 2
            z: 10 - ao

            visible: ao <= 3
            opacity: edgeFade * (ao <= 2 ? 1 : Math.max(0, 3 - ao))

            // Focus moving away mid-hold drains instead of trashing a tile the
            // pointer is no longer on.
            onFocusedChanged: if (!focused) hold.cancel()

            ClippingRectangle {
                anchors.fill: parent
                radius: tile.corner
                color: Globals.colors.surface

                layer.enabled: true
                layer.effect: MultiEffect {
                    saturation: tile.sat - 1
                    shadowEnabled: tile.focused
                    shadowColor: Qt.rgba(0, 0, 0, 0.45)
                    shadowBlur: 0.7
                    shadowVerticalOffset: 4 * root.s
                }

                Image {
                    anchors.fill: parent
                    source: tile.ao <= root.preloadRadius ? tile.thumbSource : ""
                    sourceSize.width: 384
                    sourceSize.height: 216
                    fillMode: Image.PreserveAspectCrop
                    cache: true
                    asynchronous: true
                }

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: 1 - tile.bright
                }

                // Rising hold fill. Destructive, so it uses the accent pair
                // rather than inventing a colour the role layer does not have
                // — but translucent, because it covers the wallpaper it is
                // about to remove, and an opaque slab would hide the thing
                // being deleted.
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: parent.height * hold.hold
                    visible: hold.holding
                    opacity: 0.55
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Globals.colors.accentTop }
                        GradientStop { position: 1.0; color: Globals.colors.accentBottom }
                    }

                    // The bright line on the fill's leading edge — the
                    // wavefront, so the eye can tell how far the hold has got
                    // at a glance. Fading to the fill's own top colour rather
                    // than to transparent gets the soft-ended read without
                    // colour maths at the call site.
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: Globals.geometry.borderWidth.thick
                        opacity: Math.min(1, hold.hold * 3)
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Globals.colors.accentTop }
                            GradientStop { position: 0.5; color: Globals.colors.text }
                            GradientStop { position: 1.0; color: Globals.colors.accentTop }
                        }
                    }
                }
            }

            // Hairline outline on every tile, as on Ukishima's: the strip reads
            // as a set of cards rather than a photo smear. A sibling of the
            // ClippingRectangle, not a child — the clip would shave the
            // hairline off at the corners.
            Rectangle {
                anchors.fill: parent
                radius: tile.corner
                color: "transparent"
                border.width: Globals.geometry.borderWidth.hair
                border.color: hold.holding ? Globals.colors.accentTop : Globals.colors.border
                Behavior on border.color { BaseMotion { duration: Globals.motion.hover } }
            }

            BaseHold {
                id: hold
                // A quarter of the fill. Long enough that a deliberate hold is
                // never mistaken for a click, short enough that a click still
                // feels instant.
                tapThreshold: 0.25
                onTapped: tile.apply()

                onConfirmed: {
                    if (!tile.focused)
                        return;
                    var slot = tile.index;
                    Wallpaper.trash(tile.modelData.path);
                    // trash() replaces the model, which trips focusFirst() and
                    // zeroes both pos and focusIndex. Restore the slot the
                    // trashed tile left behind — pos too, or the strip slides
                    // in from the far end instead of staying put.
                    var next = Math.min(slot, Math.max(0, root.model.length - 1));
                    root.pos = next;
                    root.focusIndex = next;
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onExited: hold.cancel()
                onPressed: if (tile.focused) hold.press()
                onReleased: if (tile.focused) hold.release()

                // Focus only. Applying lives on hold's `tapped`, so a press held
                // past the tap threshold and then abandoned drains without
                // applying, and a completed hold cannot apply what it trashed.
                onClicked: if (!tile.focused) root.focusIndex = tile.index
            }
        }
    }

    Row {
        id: emptyState
        readonly property bool shown: Wallpaper.hasScanned && !root.model.length

        anchors.centerIn: parent
        spacing: Globals.geometry.spacing.md
        visible: shown

        // Masked tinting (MultiEffect) resamples the mask and turns the trace's
        // hairline strokes to mush, so the art is drawn as-is.
        Image {
            width: 104 * Globals.shellScale
            height: 104 * Globals.shellScale
            anchors.verticalCenter: parent.verticalCenter
            rotation: -15
            source: Qt.resolvedUrl("../../assets/yak.png")
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            opacity: 0.3
        }

        Column {
            id: emptyPrompt
            anchors.verticalCenter: parent.verticalCenter
            spacing: Globals.geometry.spacing.xs

            BaseText {
                text: "NO WALLPAPERS"
                font.pixelSize: Globals.typography.size.lg
                font.weight: Globals.typography.weight.bold
                font.letterSpacing: 2 * Globals.shellScale
            }

            // The prompt keeps its slot while editing so the field can sit
            // exactly on top of it.
            BaseHeader {
                id: emptyLabel
                text: "CLICK HERE TO SET A DIRECTORY"
                opacity: root.directoryOpen ? 0 : 1
                muted: !emptyLabelArea.containsMouse

                MouseArea {
                    id: emptyLabelArea
                    anchors.fill: parent
                    anchors.margins: -Globals.geometry.spacing.xs
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.editDirectory()
                }
            }
        }
    }

    WheelHandler {
        onWheel: (event) => Binds.handleWheel(event)
    }

    Keys.onPressed: (event) => Binds.handleKey(event)

    // ── DIRECTORY ─────────────────────────────────────────────────────
    // One field, two homes: inline under the empty-state mark, or in the
    // counter's place once there are wallpapers to browse.
    BaseInput {
        id: dirInput
        visible: root.directoryOpen
        // In the empty state the field sits exactly on the prompt's slot and
        // starts where the prompt starts, so typing begins under the label
        // rather than in the middle of the capsule.
        x: emptyState.shown ? emptyState.x + emptyPrompt.x : root.contentPadding
        width: emptyState.shown
            ? parent.width - root.contentPadding - x
            : parent.width - 2 * root.contentPadding
        y: emptyState.shown
            ? emptyState.y + emptyPrompt.y + emptyLabel.y
                + (emptyLabel.height - height) / 2
            : parent.height - root.contentPadding - height
        font.pixelSize: Globals.typography.size.sm
        placeholderText: "/home/user/wallpapers"
        color: Globals.colors.muted
        placeholderTextColor: Globals.colors.muted
        horizontalAlignment: emptyState.shown
            ? TextInput.AlignLeft
            : TextInput.AlignHCenter
        activeFocusOnTab: false
        onEditingFinished: root.commitDirectory()
        Keys.onReturnPressed: {
            root.commitDirectory();
            // Clear the field first, then hand focus to the carousel root.
            // Setting `focus` on the input synchronously and only moving focus
            // afterwards avoids TextInput reclaiming it mid-dispatch.
            dirInput.focus = false;
            Qt.callLater(root.forceActiveFocus);
        }
    }

    // ── COUNTER ──────────────────────────────────────────────────────
    BaseText {
        id: counter
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: root.contentPadding
        text: root.model.length > 0 ? (root.currentIndex + 1) + " / " + root.model.length : ""
        visible: root.model.length > 0 && !root.directoryOpen
        font.pixelSize: Globals.typography.size.sm
        muted: !counterArea.containsMouse

        MouseArea {
            id: counterArea
            anchors.fill: parent
            anchors.margins: -Globals.geometry.spacing.sm
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.editDirectory()
        }
    }
}
