import ".."
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs

Item {
    id: root

    property string buttonMode: "standard" // "standard", "action", "toggle"

    // --- Standard Properties ---
    property string text: ""
    property string icon: ""
    property color iconColor: {
        if ((root.gradient && root.selected) || (root.hoverGradient && root.containsMouse)) return Theme.colors.primary;
        return (root.pressed || root.containsMouse) ? Theme.colors.primary : Theme.colors.text;
    }
    property color textColor: {
        if ((root.gradient && root.selected) || (root.hoverGradient && root.containsMouse)) return Theme.colors.text;
        return (root.pressed || root.containsMouse) ? Theme.colors.primary : Theme.colors.text;
    }
    property int size: Theme.dimensions.iconBase
    property alias iconSize: root.size
    property real rotation: 0
    property alias iconRotation: root.rotation
    property int textSize: Theme.typography.size.base
    property alias textWeight: root.weight
    property int weight: (root.gradient && root.selected) || (root.hoverGradient && root.containsMouse) ? Theme.typography.weights.bold : Theme.typography.weights.normal
    property color normalColor: Theme.colors.transparent
    property color hoverColor: Theme.colors.transparent
    property color activeColor: Theme.colors.transparent
    property color borderColor: Theme.colors.transparent
    property int borderWidth: 0
    property real customRadius: -1
    property bool circular: false
    property bool gradient: false
    property bool selected: false
    property bool hoverGradient: false
    property bool hoverEnabled: true
    property bool hoverRotate: false
    property bool clickRotate: false
    property int paddingHorizontal: text !== "" ? Theme.geometry.spacing.dynamicPadding : Theme.geometry.spacing.medium
    property int paddingVertical: Theme.geometry.spacing.medium
    property int contentAlignment: Qt.AlignCenter
    property bool allowFallback: false

    // --- Action Properties ---
    property bool active: false
    property color actionColor: Theme.colors.primary
    property color inactiveColor: Theme.colors.text
    property color inactiveBackgroundColor: inactiveColor
    property real inactiveBackgroundOpacity: 0.1
    property bool interactive: true

    // --- Toggle Properties ---
    property string title: ""
    property string subtitle: ""
    property color subtitleColor: Theme.colors.muted
    property bool mirrored: false
    property bool actionInteractive: true
    property bool hasChevron: true

    // --- Hold Properties ---
    property int holdDuration: 1500
    property real holdProgress: 0.0
    property bool hoverBackgroundEnabled: true
    property bool holdRingEnabled: true

    // --- State Proxies ---
    property bool containsMouse: mainLoader.item && mainLoader.item.hasOwnProperty("containsMouse") ? mainLoader.item.containsMouse : false
    property bool pressed: mainLoader.item && mainLoader.item.hasOwnProperty("pressed") ? mainLoader.item.pressed : false
    property bool hovered: containsMouse

    // --- Signals ---
    signal clicked()
    signal rightClicked()
    signal pressedSignal()
    signal releasedSignal()
    signal entered()
    signal exited()
    signal actionClicked()
    signal holdTriggered()

    implicitWidth: mainLoader.implicitWidth
    implicitHeight: mainLoader.implicitHeight
    Layout.fillWidth: root.buttonMode === "toggle"

    Loader {
        id: mainLoader
        anchors.fill: parent
        sourceComponent: {
            if (root.buttonMode === "standard") return standardComponent;
            if (root.buttonMode === "action") return actionComponent;
            if (root.buttonMode === "toggle") return toggleComponent;
            if (root.buttonMode === "hold") return holdComponent;
            return standardComponent;
        }
    }

    // ==========================================
    // 1. Standard Button Mode
    // ==========================================
    Component {
        id: standardComponent
        Rectangle {
            id: stdRoot
            readonly property bool containsMouse: mouseArea.containsMouse
            readonly property bool pressed: mouseArea.pressed

            radius: {
                if (root.customRadius >= 0) return root.customRadius;
                return root.circular ? height / 2 : Theme.geometry.radius;
            }
            color: root.normalColor
            border.color: root.borderColor
            border.width: root.borderWidth
            
            implicitWidth: childrenLayout.implicitWidth + (root.paddingHorizontal * 2)
            implicitHeight: childrenLayout.implicitHeight + (root.paddingVertical * 2)
            scale: pressed ? 0.98 : 1.0

            Behavior on scale { BaseAnimation { duration: Theme.animations.fast } }

            BaseActiveBackground {
                id: stateLayer
                anchors.fill: parent
                radius: parent.radius
                baseColor: Theme.colors.surface
                hoverColor: root.hoverColor
                hovered: mouseArea.containsMouse
                hoverEnabled: root.hoverEnabled
                premiumActive: root.gradient && root.selected
                premiumHover: root.hoverGradient
            }

            BaseIcon {
                id: childrenLayout
                anchors.centerIn: root.contentAlignment === Qt.AlignCenter ? parent : undefined
                anchors.left: root.contentAlignment === Qt.AlignLeft ? parent.left : undefined
                anchors.right: root.contentAlignment === Qt.AlignRight ? parent.right : undefined
                anchors.leftMargin: root.contentAlignment === Qt.AlignLeft ? root.paddingHorizontal : 0
                anchors.rightMargin: root.contentAlignment === Qt.AlignRight ? root.paddingHorizontal : 0
                anchors.verticalCenter: parent.verticalCenter
                icon: root.icon
                text: root.text
                color: root.iconColor
                textColor: root.textColor
                size: root.size
                textSize: root.textSize
                textWeight: root.weight
                rotation: root.rotation
                allowFallback: root.allowFallback
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                enabled: root.enabled
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        root.rightClicked();
                    } else {
                        if (root.clickRotate) rotateAnim.restart();
                        root.clicked();
                    }
                }
                onPressed: root.pressedSignal()
                onReleased: root.releasedSignal()
                onEntered: root.entered()
                onExited: root.exited()
            }

            SequentialAnimation {
                id: rotateAnim
                NumberAnimation {
                    target: root
                    property: "rotation"
                    from: 0; to: 360
                    duration: Theme.animations.normal
                    easing.type: Easing.OutBack
                }
                PropertyAction { target: root; property: "rotation"; value: 0 }
            }

            onContainsMouseChanged: {
                if (containsMouse && root.hoverRotate) rotateAnim.restart();
            }
        }
    }

    // ==========================================
    // 2. Action Button Mode (Circular Canvas)
    // ==========================================
    Component {
        id: actionComponent
        Item {
            id: actRoot
            readonly property bool containsMouse: mouseArea.containsMouse
            readonly property bool pressed: mouseArea.pressed

            implicitWidth: 48
            implicitHeight: 48

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                enabled: root.interactive && root.actionInteractive
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.buttonMode === "toggle") {
                        root.actionClicked();
                    } else {
                        root.clicked();
                    }
                }
                hoverEnabled: true
            }

            readonly property bool isLit: root.active || root.hovered || mouseArea.containsMouse

            property real breathScale: 1.0
            SequentialAnimation {
                loops: Animation.Infinite
                running: actRoot.isLit
                onStopped: actRoot.breathScale = 1.0
                NumberAnimation { target: actRoot; property: "breathScale"; to: 1.08; duration: 1200; easing.type: Easing.InOutSine }
                NumberAnimation { target: actRoot; property: "breathScale"; to: 1.0;  duration: 1200; easing.type: Easing.InOutSine }
            }

            property real bubbleAlpha: root.active ? 0.15 : 0.1
            SequentialAnimation {
                id: bubbleAlphaAnim
                loops: Animation.Infinite
                running: root.hovered || mouseArea.containsMouse
                onStopped: actRoot.bubbleAlpha = root.active ? 0.15 : 0.1
                NumberAnimation { target: actRoot; property: "bubbleAlpha"; to: 0.38; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { target: actRoot; property: "bubbleAlpha"; to: 0.18; duration: 800; easing.type: Easing.InOutSine }
            }

            Canvas {
                id: ringCanvas
                anchors.centerIn: parent
                width: 48
                height: 48
                opacity: actRoot.isLit ? 1.0 : 0.0

                Behavior on opacity { NumberAnimation { duration: Theme.animations.fast } }

                property int cornerRadius: Theme.geometry.radius
                onCornerRadiusChanged: requestPaint()
                onOpacityChanged: { if (opacity > 0) requestPaint(); }

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    var lw = 1.5;
                    var bw = 36, bh = 36;
                    var bx = (width - bw) / 2;
                    var by = (height - bh) / 2;
                    var r = Math.min(Theme.geometry.radius, bw / 2, bh / 2);
                    ctx.beginPath();
                    ctx.moveTo(bx + r, by);
                    ctx.lineTo(bx + bw - r, by);
                    ctx.arcTo(bx + bw, by, bx + bw, by + r, r);
                    ctx.lineTo(bx + bw, by + bh - r);
                    ctx.arcTo(bx + bw, by + bh, bx + bw - r, by + bh, r);
                    ctx.lineTo(bx + r, by + bh);
                    ctx.arcTo(bx, by + bh, bx, by + bh - r, r);
                    ctx.lineTo(bx, by + r);
                    ctx.arcTo(bx, by, bx + r, by, r);
                    ctx.closePath();
                    var grad = ctx.createLinearGradient(0, 0, width, height);
                    grad.addColorStop(0.0, root.actionColor);
                    grad.addColorStop(1.0, Theme.colors.secondary);
                    ctx.strokeStyle = grad;
                    ctx.lineWidth = lw;
                    ctx.stroke();
                }
            }

            Rectangle {
                width: 36
                height: 36
                radius: Theme.geometry.radius
                anchors.centerIn: parent
                scale: actRoot.breathScale
                color: Theme.alpha(actRoot.isLit ? root.actionColor : root.inactiveBackgroundColor, actRoot.isLit ? actRoot.bubbleAlpha : root.inactiveBackgroundOpacity)

                Behavior on scale { NumberAnimation { duration: Theme.animations.fast } }

                BaseIcon {
                    anchors.centerIn: parent
                    icon: root.icon
                    size: Theme.dimensions.iconBase
                    color: actRoot.isLit ? root.actionColor : root.inactiveColor
                    rotation: root.iconRotation
                }
            }
        }
    }

    // ==========================================
    // 3. Toggle Button Mode
    // ==========================================
    Component {
        id: toggleComponent
        
        Rectangle {
            id: togRoot
            readonly property bool containsMouse: mouseArea.containsMouse
            readonly property bool pressed: mouseArea.pressed

            radius: Theme.geometry.radius * 1.5
            color: Theme.alpha(Theme.colors.surface, Theme.opacity.surface)
            border.color: root.borderColor
            border.width: root.borderWidth
            
            implicitWidth: toggleRow.implicitWidth + (Theme.geometry.spacing.large * 2)
            implicitHeight: 64
            scale: pressed ? 0.98 : 1.0

            Behavior on scale { BaseAnimation { duration: Theme.animations.fast } }

            BaseActiveBackground {
                id: stateLayer
                anchors.fill: parent
                radius: parent.radius
                baseColor: Theme.colors.surface
                hoverColor: root.hoverColor
                hovered: mouseArea.containsMouse
                hoverEnabled: root.hoverEnabled
                premiumActive: root.active // root.gradient && root.selected mapping for toggle
                premiumHover: root.hoverGradient
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                enabled: root.enabled
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        root.rightClicked();
                    } else {
                        root.clicked();
                    }
                }
                onPressed: root.pressedSignal()
                onReleased: root.releasedSignal()
                onEntered: root.entered()
                onExited: root.exited()
            }

            RowLayout {
                id: toggleRow
                anchors.fill: parent
                anchors.leftMargin: root.mirrored ? Theme.geometry.spacing.large : Theme.geometry.spacing.medium
                anchors.rightMargin: root.mirrored ? Theme.geometry.spacing.medium : Theme.geometry.spacing.large
                spacing: Theme.geometry.spacing.medium
                layoutDirection: root.mirrored ? Qt.RightToLeft : Qt.LeftToRight

                Loader {
                    sourceComponent: actionComponent
                    // `actionComponent` internally checks `root.buttonMode === "toggle"` 
                    // and correctly emits `root.actionClicked()` instead of `root.clicked()`
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    
                    BaseText {
                        text: root.title
                        pixelSize: Theme.typography.size.base
                        weight: Theme.typography.weights.medium
                        color: Theme.colors.text
                        horizontalAlignment: root.mirrored ? Text.AlignRight : Text.AlignLeft
                        Layout.fillWidth: true
                    }
                    BaseText {
                        text: root.subtitle
                        pixelSize: Theme.typography.size.small
                        color: root.subtitleColor
                        elide: root.mirrored ? Text.ElideLeft : Text.ElideRight
                        horizontalAlignment: root.mirrored ? Text.AlignRight : Text.AlignLeft
                        Layout.fillWidth: true
                    }
                }

                BaseIcon {
                    visible: root.hasChevron
                    icon: root.mirrored ? "chevron_left" : "chevron_right"
                    size: Theme.dimensions.iconMedium
                    color: Theme.alpha(Theme.colors.text, 0.3)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }

    // ==========================================
    // 4. Hold Button Mode
    // ==========================================
    Component {
        id: holdComponent
        Rectangle {
            id: holdRoot
            readonly property bool containsMouse: mouseArea.containsMouse
            readonly property bool pressed: mouseArea.pressed

            radius: {
                if (root.customRadius >= 0) return root.customRadius;
                return root.circular ? height / 2 : Theme.geometry.radius;
            }
            color: root.normalColor
            border.color: root.borderColor
            border.width: root.borderWidth
            
            implicitWidth: childrenLayout.implicitWidth + (root.paddingHorizontal * 2)
            implicitHeight: childrenLayout.implicitHeight + (root.paddingVertical * 2)
            scale: pressed ? 0.98 : 1.0

            Behavior on scale { BaseAnimation { duration: Theme.animations.fast } }

            BaseActiveBackground {
                id: stateLayer
                anchors.fill: parent
                radius: parent.radius
                baseColor: Theme.colors.surface
                hoverColor: root.hoverColor // in old Hold button, this was Theme.colors.transparent, users can set it
                hovered: mouseArea.containsMouse
                hoverEnabled: root.hoverEnabled
                premiumActive: root.gradient && root.selected
                premiumHover: root.hoverGradient
            }

            BaseIcon {
                id: childrenLayout
                anchors.centerIn: root.contentAlignment === Qt.AlignCenter ? parent : undefined
                anchors.left: root.contentAlignment === Qt.AlignLeft ? parent.left : undefined
                anchors.right: root.contentAlignment === Qt.AlignRight ? parent.right : undefined
                anchors.leftMargin: root.contentAlignment === Qt.AlignLeft ? root.paddingHorizontal : 0
                anchors.rightMargin: root.contentAlignment === Qt.AlignRight ? root.paddingHorizontal : 0
                anchors.verticalCenter: parent.verticalCenter
                icon: root.icon
                text: root.text
                color: root.iconColor
                textColor: root.textColor
                size: root.size
                textSize: root.textSize
                textWeight: root.weight
                rotation: root.rotation
                allowFallback: root.allowFallback
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                enabled: root.enabled
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        root.rightClicked();
                    } else {
                        if (root.clickRotate) rotateAnim.restart();
                        root.clicked();
                    }
                }
                onPressed: root.pressedSignal()
                onReleased: root.releasedSignal()
                onEntered: root.entered()
                onExited: root.exited()
            }

            SequentialAnimation {
                id: rotateAnim
                NumberAnimation {
                    target: root
                    property: "rotation"
                    from: 0; to: 360
                    duration: Theme.animations.normal
                    easing.type: Easing.OutBack
                }
                PropertyAction { target: root; property: "rotation"; value: 0 }
            }

            onContainsMouseChanged: {
                if (containsMouse && root.hoverRotate) rotateAnim.restart();
            }

            // --- HOLD SPECIFIC LOGIC ---
            NumberAnimation {
                id: holdAnim
                target: root
                property: "holdProgress"
                from: 0.0
                to: 1.0
                duration: root.holdDuration
                onFinished: {
                    if (root.holdProgress >= 1.0) {
                        root.holdProgress = 0.0
                        root.holdTriggered()
                    }
                }
            }

            Connections {
                target: root
                function onPressedSignal() { holdAnim.start(); }
                function onReleasedSignal() { holdAnim.stop(); root.holdProgress = 0.0; }
                function onExited() { holdAnim.stop(); root.holdProgress = 0.0; }
            }

            // Breathing Traffic Light Background
            Rectangle {
                anchors.fill: parent
                radius: holdRoot.radius
                color: root.iconColor
                visible: root.containsMouse && root.hoverBackgroundEnabled
                opacity: 0.1

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: root.containsMouse
                    NumberAnimation { to: 0.3; duration: 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.1; duration: 1000; easing.type: Easing.InOutSine }
                }
            }

            // Dynamic Gradient Border around the box
            Canvas {
                id: ringCanvas
                anchors.fill: parent
                visible: root.holdProgress > 0.0 && root.holdRingEnabled
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    
                    if (root.holdProgress <= 0.0) return;
                    
                    var lineWidth = 2.5;
                    var rawRadius = holdRoot.radius;
                    var r = Math.max(0, rawRadius - lineWidth / 2);
                    
                    var w = width - lineWidth;
                    var h = height - lineWidth;
                    var x = lineWidth / 2;
                    var y = lineWidth / 2;
                    
                    var segments = [
                        { len: (w - 2*r)/2, draw: function(ctx, p) { ctx.lineTo(x + w/2 + p, y); } },
                        { len: Math.PI/2 * r, draw: function(ctx, p) { 
                            var angle = -Math.PI/2 + (p / (Math.PI/2 * r)) * (Math.PI/2);
                            ctx.arc(x + w - r, y + r, r, -Math.PI/2, angle, false);
                        }},
                        { len: h - 2*r, draw: function(ctx, p) { ctx.lineTo(x + w, y + r + p); } },
                        { len: Math.PI/2 * r, draw: function(ctx, p) { 
                            var angle = 0 + (p / (Math.PI/2 * r)) * (Math.PI/2);
                            ctx.arc(x + w - r, y + h - r, r, 0, angle, false);
                        }},
                        { len: w - 2*r, draw: function(ctx, p) { ctx.lineTo(x + w - r - p, y + h); } },
                        { len: Math.PI/2 * r, draw: function(ctx, p) { 
                            var angle = Math.PI/2 + (p / (Math.PI/2 * r)) * (Math.PI/2);
                            ctx.arc(x + r, y + h - r, r, Math.PI/2, angle, false);
                        }},
                        { len: h - 2*r, draw: function(ctx, p) { ctx.lineTo(x, y + h - r - p); } },
                        { len: Math.PI/2 * r, draw: function(ctx, p) { 
                            var angle = Math.PI + (p / (Math.PI/2 * r)) * (Math.PI/2);
                            ctx.arc(x + r, y + r, r, Math.PI, angle, false);
                        }},
                        { len: (w - 2*r)/2, draw: function(ctx, p) { ctx.lineTo(x + r + p, y); } }
                    ];
                    
                    var totalLength = 2*(w - 2*r) + 2*(h - 2*r) + 2*Math.PI*r;
                    var d = totalLength * root.holdProgress;
                    
                    ctx.beginPath();
                    ctx.moveTo(x + w/2, y); // Start at top center
                    
                    for (var i = 0; i < segments.length; i++) {
                        if (d <= 0) break;
                        var seg = segments[i];
                        if (d >= seg.len) {
                            seg.draw(ctx, seg.len);
                            d -= seg.len;
                        } else {
                            seg.draw(ctx, d);
                            d = 0;
                        }
                    }
                    
                    var grad = ctx.createLinearGradient(0, 0, width, height);
                    grad.addColorStop(0.0, Theme.colors.primary);
                    grad.addColorStop(1.0, Theme.colors.secondary);
                    
                    ctx.strokeStyle = grad;
                    ctx.lineWidth = lineWidth;
                    ctx.lineCap = "round";
                    ctx.stroke();
                }
                
                Connections {
                    target: root
                    function onHoldProgressChanged() { ringCanvas.requestPaint(); }
                }
            }
        }
    }
}
