import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root

    property int rowHeight: Theme.dimensions.listItemHeight
    property int itemSpacing: Theme.geometry.spacing.medium

    implicitHeight: Math.max(rowHeight, layout.implicitHeight)
    Behavior on implicitHeight { BaseAnimation { easing.type: Easing.OutQuart } }
    implicitWidth: layout.implicitWidth

    property string title: ""
    property int titleSize: Theme.typography.size.medium
    property string titleFamily: Theme.typography.family
    property string subtitle: ""
    property int subtitleSize: Theme.typography.size.base
    property bool showSubtitleOnHover: false
    
    property string leftIcon: ""
    property int leftIconSize: Theme.dimensions.iconMedium
    property bool leftIconInteractive: true
    property bool leftIconActive: false
    property real leftIconScale: 1.0
    
    // Separator
    property bool showVerticalSeparator: false
    property bool showBottomSeparator: false
    
    // Right Icon Properties
    property string rightIcon: "chevron_right"
    property bool rightIconVisible: true
    
    // Selection state
    property bool selected: false

    // Internal indicator (the gradient bar on the left edge).
    // Set to false when an external BaseIndicatorLine is used instead (e.g. for hover-driven indicators).
    property bool showInternalIndicator: true

    // State
    readonly property bool containsMouse: mainMouseArea.containsMouse
    readonly property bool hovered: containsMouse

    // Signals
    signal clicked()
    signal leftIconClicked()

    // Main row hover/click area
    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: root.itemSpacing

        // Active / Hover Notch
        Rectangle {
            visible: root.showInternalIndicator && root.selected
            opacity: 1.0
            Layout.preferredWidth: 3
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
            radius: 1.5
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Theme.colors.primary }
                GradientStop { position: 1.0; color: Theme.colors.secondary }
            }
        }

        // Left Icon Slot
        Item {
            visible: root.leftIcon !== ""
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignVCenter
            scale: root.leftIconScale

            // Left Icon (Interactive Toggle)
            BaseButton {
                visible: root.leftIconInteractive
                anchors.centerIn: parent
                icon: root.leftIcon
                size: root.leftIconSize
                iconColor: root.leftIconActive ? Theme.colors.primary : Theme.colors.text
                onClicked: root.leftIconClicked()
                z: 2 // Sit above the main MouseArea
            }
            
            BaseIcon {
                visible: !root.leftIconInteractive
                anchors.centerIn: parent
                icon: root.leftIcon
                size: root.leftIconSize
                color: root.selected ? Theme.colors.primary : (root.containsMouse ? Theme.colors.primary : Theme.colors.text)
                Behavior on color { BaseAnimation { } }
            }
        }

        BaseSeparator {
            visible: root.showVerticalSeparator
            orientation: BaseSeparator.Vertical
            Layout.fillHeight: true
            Layout.topMargin: Theme.geometry.spacing.medium
            Layout.bottomMargin: Theme.geometry.spacing.medium
            opacity: 0.3
        }

        // Text Labels
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: root.showVerticalSeparator ? 8 : 0
            spacing: 0

            BaseText {
                visible: root.title !== ""
                text: root.title
                pixelSize: root.titleSize
                family: root.titleFamily
                weight: root.selected ? Theme.typography.weights.bold : Theme.typography.weights.medium
                color: root.selected ? Theme.colors.primary : (root.containsMouse ? Theme.colors.primary : Theme.colors.text)
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                maximumLineCount: 1
                Behavior on color { BaseAnimation { } }
            }

            Item {
                Layout.fillWidth: true
                visible: root.subtitle !== ""
                Layout.preferredHeight: (root.showSubtitleOnHover && !root.hovered) ? 0 : subtitleText.implicitHeight
                Behavior on Layout.preferredHeight { BaseAnimation { easing.type: Easing.OutQuart } }
                clip: true
                opacity: (root.showSubtitleOnHover && !root.hovered) ? 0.0 : 1.0
                Behavior on opacity { BaseAnimation { } }

                BaseText {
                    id: subtitleText
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: root.subtitle
                    pixelSize: root.subtitleSize
                    muted: true
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        BaseIcon {
            visible: root.rightIconVisible && root.rightIcon !== ""
            icon: root.rightIcon
            color: root.containsMouse ? Theme.colors.text : Theme.colors.muted
            Behavior on color { BaseAnimation { } }
            Layout.alignment: Qt.AlignVCenter
        }
    }

    BaseSeparator {
        visible: root.showBottomSeparator
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.leftIcon !== "" ? (Theme.geometry.spacing.medium + Theme.dimensions.iconMedium + Theme.geometry.spacing.medium) : Theme.geometry.spacing.medium
    }
}
