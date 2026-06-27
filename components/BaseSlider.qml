import qs
import ".."
import QtQuick

Item {
    id: root

    // Value properties
    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0

    property bool interactive: true
    property bool muted: false
    property alias pressed: mouseArea.pressed
    readonly property bool hovered: mouseArea.containsMouse

    // Visual customization

    property color trackColor: Globals.alpha(Globals.colors.surface, Globals.opacity.background)
    property color fillColor: Globals.colors.primary
    property int trackHeight: 38

    // Content properties
    property string icon: ""
    property string suffix: ""
    property color iconColor: Globals.colors.text
    property color suffixColor: Globals.colors.text

    // Internal computed values
    property real _animatedValue: value
    Behavior on _animatedValue {
        enabled: !mouseArea.pressed
        BaseAnimation { }
    }
    
    readonly property real normalizedValue: (_animatedValue - from) / (to - from)
    readonly property real fillSize: track.width * root.normalizedValue

    // Coolness Controls
    property real interactionScale: root.isActive ? 1.05 : 1.0
    property real breathOpacity: 1.0
    property bool isActive: root.hovered || root.pressed
    
    property real _baseOpacity: root.muted ? 0.6 : 1.0
    Behavior on _baseOpacity { BaseAnimation { } }

    SequentialAnimation on breathOpacity {
        id: breathAnim
        running: root.pressed
        loops: Animation.Infinite
        NumberAnimation { from: 1.0; to: 0.75; duration: 800; easing.type: Easing.InOutQuad }
        NumberAnimation { from: 0.75; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
        onStopped: root.breathOpacity = 1.0
    }

    // Signals
    signal valueChangedByUser()
    signal rightClicked()

    implicitHeight: trackHeight
    implicitWidth: 100

    // Background track
    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right

        height: root.trackHeight
        
        radius: Globals.geometry.innerRadius.medium
        color: trackColor
        clip: true

        // Gradient fill
        Rectangle {
            id: fill

            width: root.value > root.from ? (handle.x + handle.width + 4) : 0
            height: parent.height
            radius: parent.radius
            anchors.left: parent.left
            
            opacity: root._baseOpacity * (root.pressed ? root.breathOpacity : 1.0)
            
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Globals.colors.primary }
                GradientStop { position: 1.0; color: Globals.colors.secondary }
            }
        }

    }

    // Handle (only visible when interactive)
    Rectangle {
        id: handle

        visible: root.interactive
        width: root.trackHeight - 8
        height: root.trackHeight - 8
        radius: Globals.geometry.innerRadius.medium
        
        // Synchronize movement: knob and fill edge move together for big sliders
        x: 4 + (track.width - width - 8) * root.normalizedValue
        y: (root.height - height) / 2
        
        color: Globals.alpha(Globals.colors.surface, 0.95)
        border.color: Globals.alpha(Globals.colors.border, (root.isActive ? 0.3 : 0.15))
        border.width: 1
        z: 10

        scale: root.interactionScale
        Behavior on scale { BaseAnimation { duration: 250; easing.type: Easing.OutBack } }

        // Subtle glow effect when active
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: parent.radius + 4
            color: "transparent"
            border.width: 2
            border.color: Globals.alpha(root.fillColor, 0.3)
            visible: root.isActive
            z: -2
            
            SequentialAnimation on opacity {
                running: root.isActive
                loops: Animation.Infinite
                NumberAnimation { from: 0.2; to: 0.6; duration: 1000; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 0.6; to: 0.2; duration: 1000; easing.type: Easing.InOutQuad }
            }
        }

        // Subtle depth effect for big sliders
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: Globals.alpha(Globals.colors.background, 0.2)
            z: -1
        }

        // Handle Content (Icon/Suffix Switch with Fading)
        Item {
            anchors.fill: parent
            anchors.margins: 4

            BaseIcon {
                anchors.centerIn: parent
                icon: root.icon
                size: Math.min(parent.width, Globals.dimensions.iconMedium)
                color: root.iconColor
                opacity: !root.isActive ? 1 : 0
                Behavior on opacity { BaseAnimation { duration: 400; easing.type: Easing.InOutQuad } }
            }

            BaseText {
                anchors.fill: parent
                text: root.suffix
                color: root.suffixColor
                pixelSize: Math.min(parent.height - 4, 12)
                fontSizeMode: Text.Fit
                minimumPixelSize: 8
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.NoWrap
                font.weight: Globals.typography.weights.bold
                opacity: root.isActive ? 1 : 0
                Behavior on opacity { BaseAnimation { duration: 400; easing.type: Easing.InOutQuad } }
            }
        }

        // Tactile Shimmer Effect
        Rectangle {
            id: shimmer
            anchors.fill: parent
            radius: parent.radius
            color: Globals.colors.text
            opacity: 0
            clip: true

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Globals.colors.transparent }
                GradientStop { position: 0.5; color: Globals.alpha(Globals.colors.text, 0.4) }
                GradientStop { position: 1.0; color: Globals.colors.transparent }
            }

            BaseAnimation {
                id: shimmerAnim
                target: shimmer; property: "opacity"
                from: 0; to: 0.8; duration: 200; easing.type: Easing.OutCubic
                onStopped: fadeOut.start()
            }
            BaseAnimation {
                id: fadeOut
                target: shimmer; property: "opacity"
                to: 0; duration: 400; easing.type: Easing.InCubic
            }


        }
    }

    // Mouse area for interaction
    MouseArea {
        id: mouseArea

        function updateValue(mousePos) {
            var newValue = root.from + (mousePos / width) * (root.to - root.from);
            if (root.stepSize > 0)
                newValue = Math.round(newValue / root.stepSize) * root.stepSize;

            newValue = Math.max(root.from, Math.min(root.to, newValue));
            root.value = newValue;
            root.valueChangedByUser();
        }

        anchors.fill: track
        anchors.margins: -(root.trackHeight - 8) / 2
        enabled: root.interactive
        hoverEnabled: true
        preventStealing: pressed
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onPressed: (mouse) => {
            mouse.accepted = true;
            if (root.interactive) shimmerAnim.start();
            if (mouse.button === Qt.RightButton) {
                root.rightClicked();
                return;
            }
            updateValue(mouse.x);
        }
        onPositionChanged: (mouse) => {
            if (pressed && (mouse.buttons & Qt.LeftButton))
                updateValue(mouse.x);
        }
    }
}
