import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root

    // ── API ───────────────────────────────────────────────────────────
    property string text: ""
    property string subText: ""
    property string imageSource: "" // Image path/url
    property bool selected: false
    property color iconColor: Globals.colors.text // Default icon color

    property bool showFallbackIcon: false
    property string fallbackText: ""

    signal clicked()

    property int itemIndex: -1 // To be set by ListView
    
    width: ListView.view ? ListView.view.width : parent.width
    height: Globals.dimensions.launcherItemHeight
    
    // Entry animation properties
    opacity: 0
    transform: Translate { id: entryTranslate; y: 20 }
    
    Component.onCompleted: {
        entryAnim.start();
    }
    
    ParallelAnimation {
        id: entryAnim
        BaseAnimation { target: root; property: "opacity"; to: 1; delay: Math.max(0, Math.min(root.itemIndex * 30, 300)) }
        BaseAnimation { target: entryTranslate; property: "y"; to: 0; delay: Math.max(0, Math.min(root.itemIndex * 30, 300)); easing.type: Easing.OutBack }
    }

    Rectangle {
        id: mainBackground
        anchors.fill: parent
        radius: Globals.geometry.innerRadius.medium
        color: Globals.colors.transparent
        
        BaseActiveBackground {
            anchors.fill: parent
            radius: parent.radius
            hovered: mouseArea.containsMouse
            premiumActive: root.selected
            hoverEnabled: false
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Globals.geometry.spacing.large * 2
            anchors.rightMargin: Globals.geometry.spacing.large * 2
            spacing: Globals.geometry.spacing.large
            
            scale: mouseArea.pressed ? 0.98 : 1.0
            Behavior on scale { BaseAnimation { } }

            // Icon Container
            Item {
                Layout.preferredWidth: Globals.dimensions.iconLarge
                Layout.preferredHeight: Globals.dimensions.iconLarge
                Layout.alignment: Qt.AlignVCenter

                // 1. Image (e.g. App Icon)
                Image {
                    anchors.fill: parent
                    source: root.imageSource
                    asynchronous: false
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: Globals.dimensions.iconLarge
                    sourceSize.height: Globals.dimensions.iconLarge
                    mipmap: true
                    visible: !!root.imageSource && status === Image.Ready
                }

                // 2. Fallback (Text char)
                Rectangle {
                    anchors.fill: parent
                    radius: Globals.geometry.innerRadius.small
                    color: Globals.colors.background
                    visible: root.showFallbackIcon

                    BaseText {
                        anchors.centerIn: parent
                        text: root.fallbackText ? root.fallbackText.charAt(0).toUpperCase() : "?"
                        color: root.iconColor
                        pixelSize: Globals.dimensions.iconLarge * 0.6
                        weight: Globals.typography.weights.bold
                    }
                }
            }

            // Text Container
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                BaseText {
                    Layout.fillWidth: true
                    text: root.text
                    color: root.selected ? Globals.colors.text : Globals.colors.muted
                    weight: root.selected ? Globals.typography.weights.bold : Globals.typography.weights.normal
                    elide: Text.ElideRight
                }

                BaseText {
                    Layout.fillWidth: true
                    text: root.subText
                    visible: !!root.subText
                    font.pixelSize: Globals.typography.size.small
                    color: root.selected ? Globals.alpha(Globals.colors.text, 0.7) : Globals.colors.muted
                    elide: Text.ElideMiddle
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        
        onPositionChanged: (mouse) => {
             var container = root.ListView.view ? root.ListView.view.parent : null;
             if (container && container.isActive && typeof container.mouseMoveRequested === "function") {
                 container.mouseMoveRequested(root.itemIndex, mouse);
             }
        }
        
        onClicked: root.clicked()
    }
}

