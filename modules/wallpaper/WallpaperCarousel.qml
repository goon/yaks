import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs

/**
 * Horizontal wallpaper carousel driven by a single real-valued `pos` that
 * chases `focusIndex` per frame. Every tile derives width, height, x, dim,
 * saturation, shadow and edge fade from `ao = |index - pos|` via five-stop
 * slot tables. The chase uses a frame-rate-independent exponential settle
 * (`1 - exp(-frameTime / τ)`), so wheel bursts and 40Hz key autorepeat stay
 * coherent: lag is bounded by the time constant, not piled up across
 * per-tile retargeting animations. Tiles fade out at the strip edges so
 * the carousel ends soften instead of being hard-cut by the parent mask.
 *
 * The strip is circular: tile offsets are measured modulo the model length,
 * so scrolling past either end wraps seamlessly with no duplicated model.
 */
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

    /**
     * Tiles start decoding a couple of slots before they become visible
     * (`visible` begins at `ao <= 3`), so the thumbnail is ready by the time
     * it slides on stage. Thumbnails are small JPEGs and the preload window
     * is tiny, so no further residency bookkeeping is needed.
     */
    readonly property int preloadRadius: 5

    /**
     * Pixel-valued slot tables (Ukishima-faithful). The wrapper sizes the
     * panel to fit the natural tile dimensions; `s` scales all geometry.
     */
    readonly property var slotW:      [196, 126, 104, 88, 74]
    readonly property var slotH:      [110, 71, 59, 50, 42]
    readonly property var slotCX:     [0, 143, 244, 326, 393]
    readonly property var slotBright: [1.00, 0.56, 0.42, 0.30, 0.22]
    readonly property var slotSat:    [1.00, 0.65, 0.55, 0.45, 0.40]

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

    /**
     * Snap focus to the first wallpaper. Called by the wrapper when the
     * panel opens; skips the chase so the strip always opens on index 0
     * rather than animating to it. Because the strip is circular, index 0's
     * left neighbour is the last wallpaper, so both directions are populated.
     */
    function focusFirst() {
        if (!model || model.length === 0)
            return;
        focusIndex = 0;
        pos = 0;
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
                var soft = 50;
                var gap = Math.min(x, root.width - (x + width));
                return Math.max(0, Math.min(1, gap / soft));
            }

            /**
             * `?v=<mtime>` is a cache-buster for QPixmapCache. Image caches by
             * URL, so a regenerated thumb with the same path keeps showing the
             * stale frame unless the URL changes. Bumping on mtime (which
             * changes only when the source file is replaced) means thumbs are
             * re-fetched exactly when the underlying wallpaper changes.
             */
            readonly property string thumbSource: "file://" + modelData.thumb + "?v=" + Math.round(modelData.mtime)

            width:  root.slotLerp(root.slotW, ao) * root.s
            height: root.slotLerp(root.slotH, ao) * root.s
            x: root.width / 2 + root.offsetX(off) - width / 2
            y: (root.height - height) / 2
            z: 10 - ao
            /**
             * A tile is on stage out to `ao = 3` so an incoming tile is already
             * present while it slides in, fading via the opacity ramp below.
             * Gating at `ao <= 2` hid it until the exponential settle had
             * practically finished, so a slow single step looked like the new
             * wallpaper was delayed; continuous scrolling masked the pop.
             */
            visible: ao <= 3
            opacity: edgeFade * (ao <= 2 ? 1 : Math.max(0, 3 - ao))

            ClippingRectangle {
                id: card
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
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (tile.focused) {
                        if (root.model && root.currentIndex >= 0 && root.currentIndex < root.model.length) {
                            Wallpaper.setWallpaper(root.model[root.currentIndex].path);
                            root.closeRequested();
                        }
                    } else {
                        root.focusIndex = tile.index;
                    }
                }
            }
        }
    }

    WheelHandler {
        onWheel: (event) => Binds.handleWheel(event)
    }

    Keys.onPressed: (event) => Binds.handleKey(event)
}
