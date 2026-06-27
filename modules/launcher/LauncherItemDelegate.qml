import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

Item {
    id: root

    // ── API ───────────────────────────────────────────────────────────
    property string text: ""
    property string subText: ""
    property string iconSource: "" // Glyph/Icon name
    property string imageSource: "" // Image path/url (takes precedence if valid)
    property bool selected: false
    property color iconColor: Theme.colors.text // Default icon color

    property bool showFallbackIcon: false
    property string fallbackText: ""
    property bool boxedIcon: false

    signal clicked()

    property int itemIndex: -1 // To be set by ListView
    
    width: ListView.view ? ListView.view.width : parent.width
    height: Theme.dimensions.launcherItemHeight
    
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
        radius: Theme.geometry.innerRadius.medium
        color: Theme.colors.transparent
        
        BaseActiveBackground {
            anchors.fill: parent
            radius: parent.radius
            hovered: mouseArea.containsMouse
            premiumActive: root.selected
            hoverEnabled: false // Hover logic in Launcher is handled externally via 'selected'
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.geometry.spacing.large * 2
            anchors.rightMargin: Theme.geometry.spacing.large * 2
            spacing: Theme.geometry.spacing.large
            
            scale: mouseArea.pressed ? 0.98 : 1.0
            Behavior on scale { BaseAnimation { } }

            // Icon Container
            Item {
                Layout.preferredWidth: Theme.dimensions.iconLarge
                Layout.preferredHeight: Theme.dimensions.iconLarge
                Layout.alignment: Qt.AlignVCenter

                BaseIcon {
                    anchors.fill: parent
                    icon: root.iconSource
                    color: root.selected ? Theme.colors.primary : root.iconColor
                    size: root.boxedIcon ? Theme.dimensions.iconLarge : Theme.dimensions.iconMedium
                    visible: !root.imageSource && !root.showFallbackIcon
                }

                // 2. Image (e.g. App Icon)
                Image {
                    anchors.fill: parent
                    source: root.imageSource
                    asynchronous: false // Keeping consistent with previous LauncherApps behavior
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: Theme.dimensions.iconLarge
                    sourceSize.height: Theme.dimensions.iconLarge
                    mipmap: true
                    visible: !!root.imageSource && status === Image.Ready
                }

                // 3. Fallback (Text char)
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.geometry.innerRadius.small
                    color: Theme.colors.background
                    visible: root.showFallbackIcon

                    BaseText {
                        anchors.centerIn: parent
                        text: root.fallbackText ? root.fallbackText.charAt(0).toUpperCase() : "?"
                        color: root.iconColor
                        pixelSize: Theme.dimensions.iconLarge * 0.6
                        weight: Theme.typography.weights.bold
                    }
                }
            }

            // Text Container
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                BaseText {
                    Layout.fillWidth: true
                    text: root.text
                    color: root.selected ? Theme.colors.text : Theme.colors.muted
                    weight: root.selected ? Theme.typography.weights.bold : Theme.typography.weights.normal
                    elide: Text.ElideRight
                }

                BaseText {
                    Layout.fillWidth: true
                    text: root.subText
                    visible: !!root.subText
                    font.pixelSize: Theme.typography.size.small
                    color: root.selected ? Theme.alpha(Theme.colors.text, 0.7) : Theme.colors.muted
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
             // Find the LauncherTab (parent of the ListView)
             var tab = root.ListView.view ? root.ListView.view.parent : null;
             if (tab && tab.isActive && typeof tab.mouseMoveRequested === "function") {
                 tab.mouseMoveRequested(root.itemIndex, mouse);
             }
        }
        
        onClicked: root.clicked()
    }
}

