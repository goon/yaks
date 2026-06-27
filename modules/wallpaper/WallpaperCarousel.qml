import QtQuick
import QtQuick.Effects
import qs

PathView {
    id: root

    property int borderRadius: Theme.geometry.radius
    property int centerWidth: 500
    property int sideWidth: 250
    property int gap: Theme.geometry.spacing.large
    readonly property real centerX: root.width / 2
    readonly property real leftX: centerX - (centerWidth / 2) - gap - (sideWidth / 2)
    readonly property real rightX: centerX + (centerWidth / 2) + gap + (sideWidth / 2)
    
    // Far positions can just be off-screen
    readonly property real farLeftX: leftX - sideWidth - gap
    readonly property real farRightX: rightX + sideWidth + gap

    property bool canNavigate: true
    signal closeRequested()

    // ── LOGIC ───────────────────────────────────────────────────────────

    function safeDecrement() {
        if (canNavigate) {
            decrementCurrentIndex();
            canNavigate = false;
            navTimer.start();
        }
    }

    function safeIncrement() {
        if (canNavigate) {
            incrementCurrentIndex();
            canNavigate = false;
            navTimer.start();
        }
    }

    function setRandomIndex() {
        if (model && model.length > 0) {
            var newIndex = Math.floor(Math.random() * model.length);
            positionViewAtIndex(newIndex, PathView.Center);
            currentIndex = newIndex;
        }
    }

    function positionViewAtBeginning() {
        currentIndex = 0;
        positionViewAtIndex(0, PathView.Center);
    }

    // ── CONFIGURATION ───────────────────────────────────────────────────

    clip: false
    model: Wallpaper.wallpapers
    
    pathItemCount: Math.min(5, model.length)

    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange
    snapMode: PathView.SnapToItem
    
    focus: true
    
    // ── INPUT HANDLING ──────────────────────────────────────────────────
    
    Keys.onLeftPressed: safeDecrement()
    Keys.onRightPressed: safeIncrement()
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_H) {
            safeDecrement();
            event.accepted = true;
        } else if (event.key === Qt.Key_L) {
            safeIncrement();
            event.accepted = true;
        }
    }
    Keys.onEscapePressed: root.closeRequested()
    Keys.onReturnPressed: {
        if (currentIndex >= 0 && model && model.length > currentIndex) {
            Wallpaper.setWallpaper(model[currentIndex]);
            root.closeRequested();
        }
    }

    Timer {
        id: navTimer
        interval: 150
        repeat: false
        onTriggered: root.canNavigate = true
    }

    // ── PATHS ─────────────────────────────────────────────────────────

    path: standardPath

    Path {
        id: standardPath
        startX: -500
        startY: root.height / 2

        // Start Attributes
        PathAttribute { name: "itemWidth"; value: root.sideWidth }
        PathAttribute { name: "itemZ"; value: 0 }
        PathAttribute { name: "itemOpacity"; value: 0 }
        PathAttribute { name: "dimOpacity"; value: 0.5 }
        PathAttribute { name: "leftRadius"; value: root.borderRadius }
        PathAttribute { name: "rightRadius"; value: 0 }

        // 1. Far Left (Preload)
        PathLine { x: root.farLeftX; y: root.height / 2 }
        PathAttribute { name: "itemWidth"; value: root.sideWidth }
        PathAttribute { name: "itemZ"; value: 0 }
        PathAttribute { name: "itemOpacity"; value: 0 }
        PathAttribute { name: "dimOpacity"; value: 0.5 }
        PathAttribute { name: "leftRadius"; value: root.borderRadius }
        PathAttribute { name: "rightRadius"; value: 0 }
        PathPercent { value: 0.1 }

        // 2. Left Side (Visible)
        PathLine { x: root.leftX; y: root.height / 2 }
        PathAttribute { name: "itemWidth"; value: root.sideWidth }
        PathAttribute { name: "itemZ"; value: 1 }
        PathAttribute { name: "itemOpacity"; value: 1 }
        PathAttribute { name: "dimOpacity"; value: 0.4 }
        PathAttribute { name: "leftRadius"; value: root.borderRadius }
        PathAttribute { name: "rightRadius"; value: 0 }
        PathPercent { value: 0.3 }

        // 2b. Pre-Center (Hold Radius)
        PathLine { x: root.leftX + (root.centerX - root.leftX) * 0.9; y: root.height / 2 }
        PathAttribute { name: "itemWidth"; value: root.sideWidth + (root.centerWidth - root.sideWidth) * 0.9 }
        PathAttribute { name: "itemZ"; value: 99 }
        PathAttribute { name: "itemOpacity"; value: 1 }
        PathAttribute { name: "dimOpacity"; value: 0.1 }
        PathAttribute { name: "leftRadius"; value: root.borderRadius } // Hold radius
        PathAttribute { name: "rightRadius"; value: 0 }
        PathPercent { value: 0.49 }

        // 3. Center (Hero)
        PathLine { x: root.centerX; y: root.height / 2 }
        PathAttribute { name: "itemWidth"; value: root.centerWidth }
        PathAttribute { name: "itemZ"; value: 100 }
        PathAttribute { name: "itemOpacity"; value: 1 }
        PathAttribute { name: "dimOpacity"; value: 0 }
        PathAttribute { name: "leftRadius"; value: 0 }
        PathAttribute { name: "rightRadius" ; value: 0 }
        PathPercent { value: 0.5 }

        // 3b. Post-Center (Restore Radius)
        PathLine { x: root.centerX + (root.rightX - root.centerX) * 0.1; y: root.height / 2 }
        PathAttribute { name: "itemWidth"; value: root.centerWidth - (root.centerWidth - root.sideWidth) * 0.1 }
        PathAttribute { name: "itemZ"; value: 99 }
        PathAttribute { name: "itemOpacity"; value: 1 }
        PathAttribute { name: "dimOpacity"; value: 0.1 }
        PathAttribute { name: "leftRadius"; value: 0 }
        PathAttribute { name: "rightRadius"; value: root.borderRadius } // Restore radius
        PathPercent { value: 0.51 }

        // 4. Right Side (Visible)
        PathLine { x: root.rightX; y: root.height / 2 }
        PathAttribute { name: "itemWidth"; value: root.sideWidth }
        PathAttribute { name: "itemZ"; value: 1 }
        PathAttribute { name: "itemOpacity"; value: 1 }
        PathAttribute { name: "dimOpacity"; value: 0.4 }
        PathAttribute { name: "leftRadius"; value: 0 }
        PathAttribute { name: "rightRadius"; value: root.borderRadius }
        PathPercent { value: 0.7 }

        // 5. Far Right (Preload)
        PathLine { x: root.farRightX; y: root.height / 2 }
        PathAttribute { name: "itemWidth"; value: root.sideWidth }
        PathAttribute { name: "itemZ"; value: 0 }
        PathAttribute { name: "itemOpacity"; value: 0 }
        PathAttribute { name: "dimOpacity"; value: 0.5 }
        PathAttribute { name: "leftRadius"; value: 0 }
        PathAttribute { name: "rightRadius"; value: root.borderRadius }
        PathPercent { value: 0.9 }

        // End Point
        PathLine { x: root.width + 500; y: root.height / 2 }
        PathAttribute { name: "itemWidth"; value: root.sideWidth }
        PathAttribute { name: "itemZ"; value: 0 }
        PathAttribute { name: "itemOpacity"; value: 0 }
        PathAttribute { name: "dimOpacity"; value: 0.5 }
        PathAttribute { name: "leftRadius"; value: 0 }
        PathAttribute { name: "rightRadius"; value: Theme.geometry.radius * 1.5 }
    }

    delegate: Item {
        id: delegateRoot

        property real dimLevel: (typeof PathView.dimOpacity !== 'undefined') ? PathView.dimOpacity : 0
        property real leftRadius: (typeof PathView.leftRadius !== 'undefined') ? PathView.leftRadius : Theme.geometry.radius
        property real rightRadius: (typeof PathView.rightRadius !== 'undefined') ? PathView.rightRadius : Theme.geometry.radius
        // Model data (file path)
        property string imageSource: modelData || ""

        // PathView injected properties
        width: (typeof PathView.itemWidth !== 'undefined') ? PathView.itemWidth : 150
        height: root.height // Full height in horizontal carousel
        
        anchors.verticalCenter: parent.verticalCenter
        
        z: (typeof PathView.itemZ !== 'undefined') ? PathView.itemZ : 0
        opacity: (typeof PathView.itemOpacity !== 'undefined') ? PathView.itemOpacity : 0

        // 1. THE STENCIL: Mask Rectangle (Layered)
        Rectangle {
            id: maskRect

            anchors.fill: effectContainer
            visible: false // Hidden, used as texture source
            color: Theme.colors.text // Mask source
            topLeftRadius: delegateRoot.leftRadius
            topRightRadius: delegateRoot.rightRadius
            bottomLeftRadius: delegateRoot.leftRadius
            bottomRightRadius: delegateRoot.rightRadius
            
            // Render to texture for MultiEffect
            layer.enabled: true
            layer.smooth: true
            layer.samples: 8
        }

        // 2. THE CANVAS: Layered Item
        Item {
            id: effectContainer

            anchors.fill: parent
            layer.enabled: true

            // Placeholder / Loading State
            Rectangle {
                anchors.fill: parent
                color: Theme.colors.background
                opacity: 0.1
                visible: imgSource.status !== Image.Ready
            }

            Image {
                id: imgSource

                anchors.fill: parent
                source: "file://" + delegateRoot.imageSource
                fillMode: Image.PreserveAspectCrop
                smooth: true
                cache: true
                asynchronous: true // Prevent blocking
            }

            // Dimming overlay
            Rectangle {
                anchors.fill: parent
                color: Theme.colors.base
                opacity: delegateRoot.dimLevel
            }

            // Highlight border for current item
            Rectangle {
                anchors.fill: parent
                color: Theme.colors.transparent
                border.color: Theme.colors.primary
                border.width: PathView.isCurrentItem ? 2 : 0
                radius: delegateRoot.leftRadius 
                visible: PathView.isCurrentItem
                opacity: PathView.isCurrentItem ? 0.3 : 0
            }

            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: maskRect
            }
        }
    }
}
